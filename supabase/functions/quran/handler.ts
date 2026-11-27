import { parseFragment } from "npm:parse5@7.3.0";

type Json = Record<string, unknown>;
type Scope = "quran" | "tafsirs" | "audio";
type Route = "catalog" | "tafsir" | "recitation" | "mushaf";
type Token = { value: string; refreshAt: number };

const tokens = new Map<string, Promise<Token>>();
const catalogs = new Map<string, { value: Promise<Json>; expires: number }>();
const audioHosts = new Set([
  "audio.qurancdn.com",
  "quranicaudio.com",
  "download.quranicaudio.com",
  "verses.quran.com",
  "verses.quran.foundation",
]);

class ApiError extends Error {
  constructor(public status: number, public code: string) {
    super(code);
  }
}

function setting(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new ApiError(503, "service_unconfigured");
  return value;
}

function environment() {
  const env = setting("QF_ENV");
  if (env === "prelive") {
    return {
      env,
      oauth: "https://prelive-oauth2.quran.foundation",
      content: "https://apis-prelive.quran.foundation",
    };
  }
  if (env === "production") {
    return {
      env,
      oauth: "https://oauth2.quran.foundation",
      content: "https://apis.quran.foundation",
    };
  }
  throw new ApiError(503, "service_unconfigured");
}

function resourceIds(name: string): number[] {
  const value = Deno.env.get(name);
  if (!value) return [];
  if (!/^[1-9]\d{0,6}(,[1-9]\d{0,6})*$/.test(value)) {
    throw new ApiError(503, "service_unconfigured");
  }
  return [...new Set(value.split(",").map(Number))];
}

async function jsonResponse(
  request: string,
  init?: RequestInit,
): Promise<Json> {
  const result = await fetch(request, {
    ...init,
    signal: AbortSignal.timeout(6500),
    redirect: "error",
  });
  if (result.status === 404) throw new ApiError(404, "resource_unavailable");
  if (result.status === 401) throw new ApiError(401, "upstream_authentication");
  if (result.status === 429) throw new ApiError(429, "rate_limited");
  if (result.status === 403) {
    throw new ApiError(503, "provider_scope_unavailable");
  }
  if (!result.ok) throw new ApiError(503, "provider_unavailable");
  return await result.json();
}

async function fetchToken(scope: string, oauth: string): Promise<Token> {
  const basic = btoa(
    `${setting("QF_CLIENT_ID")}:${setting("QF_CLIENT_SECRET")}`,
  );
  const data = await jsonResponse(`${oauth}/oauth2/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${basic}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({ grant_type: "client_credentials", scope }),
  });
  if (
    typeof data.access_token !== "string" ||
    typeof data.expires_in !== "number" || data.expires_in <= 0
  ) {
    throw new ApiError(503, "provider_unavailable");
  }
  return {
    value: data.access_token,
    refreshAt: Date.now() + (data.expires_in - 45) * 1000,
  };
}

async function tokenFor(scope: string, oauth: string): Promise<Token> {
  const active = tokens.get(scope);
  if (active) {
    const value = await active;
    if (value.refreshAt > Date.now()) return value;
    if (tokens.get(scope) !== active) return tokenFor(scope, oauth);
  }
  const next = fetchToken(scope, oauth);
  tokens.set(scope, next);
  try {
    return await next;
  } catch (error) {
    if (tokens.get(scope) === next) tokens.delete(scope);
    throw error;
  }
}

async function provider(
  path: string,
  type: Scope,
  params?: URLSearchParams,
): Promise<Json> {
  const { oauth, content } = environment();
  const scope = Deno.env.get("QF_SCOPE_MODE") === "legacy"
    ? "content"
    : `content.${type}.read`;
  const url = new URL(`/content/api/v4${path}`, content);
  if (params) url.search = params.toString();
  const get = (token: Token) =>
    jsonResponse(url.href, {
      headers: {
        "x-auth-token": token.value,
        "x-client-id": setting("QF_CLIENT_ID"),
      },
    });
  const current = await tokenFor(scope, oauth);
  try {
    return await get(current);
  } catch (error) {
    if (!(error instanceof ApiError) || error.status !== 401) throw error;
    const candidate = tokens.get(scope);
    if (
      candidate && await candidate === current &&
      tokens.get(scope) === candidate
    ) {
      tokens.delete(scope);
    }
    return await get(await tokenFor(scope, oauth));
  }
}

function objects(value: unknown): Json[] {
  return Array.isArray(value)
    ? value.filter((item): item is Json => !!item && typeof item === "object")
    : [];
}

function listed(rows: Json[], ids: number[]) {
  return ids.flatMap((id) => {
    const row = rows.find((entry) => entry.id === id);
    const translated = row?.translated_name as Json | undefined;
    const name = translated?.name ?? row?.name;
    if (typeof name !== "string" || !name.trim()) return [];
    const language = row?.language_name;
    return [{
      id,
      name,
      ...(typeof language === "string" ? { language } : {}),
    }];
  });
}

// The documented Ibn Kathir resource may be the only edition in prelive.
export function previewTafsirIds(rows: Json[]): number[] {
  const arabicIds = ["ar-tafsir-ibn-kathir", "ar-tafsir-al-tabari"].flatMap(
    (slug) =>
      rows.flatMap((row) =>
        row.slug === slug && typeof row.id === "number" ? [row.id] : []
      ),
  );
  return arabicIds.length > 0 ? arabicIds : [169];
}

async function fetchCatalog(lang: string): Promise<Json> {
  const { env } = environment();
  const tafsirIds = resourceIds("QF_TAFSIR_IDS");
  const reciterIds = resourceIds("QF_RECITER_IDS");
  const preview = env === "prelive";
  const query = new URLSearchParams({ language: lang });

  // Optional scopes can be granted independently of the Quran catalog.
  async function optional(
    path: string,
    type: Scope,
    enabled: boolean,
  ): Promise<{ data: Json; state: string }> {
    if (!enabled) return { data: {}, state: "not_configured" };
    try {
      return { data: await provider(path, type, query), state: "available" };
    } catch (error) {
      const state = error instanceof ApiError ? error.code : "request_failed";
      console.warn("Quran resource catalog unavailable", type, state);
      return { data: {}, state };
    }
  }

  const [chapters, tafsirList, reciterList] = await Promise.all([
    provider("/chapters", "quran", query),
    optional("/resources/tafsirs", "tafsirs", preview || tafsirIds.length > 0),
    optional(
      "/resources/chapter_reciters",
      "audio",
      preview || reciterIds.length > 0,
    ),
  ]);
  const tafsirs = objects(tafsirList.data.tafsirs);
  const reciters = objects(reciterList.data.reciters);
  const tafsirOptions = listed(
    tafsirs,
    tafsirIds.length > 0 || !preview ? tafsirIds : previewTafsirIds(tafsirs),
  );
  const enabledReciters = preview && !reciterIds.length
    ? reciters.some((reciter) => reciter.id === 159) ? [159] : [7]
    : reciterIds;
  const reciterOptions = listed(reciters, enabledReciters);

  function availability(state: string, count: number, enabled: number) {
    if (state !== "available") return state;
    if (enabled > 0) return "ready";
    return count === 0 ? "empty_catalog" : "approved_resources_absent";
  }

  return {
    chapters: objects(chapters.chapters).flatMap((chapter) =>
      Number.isInteger(chapter.id) && Number.isInteger(chapter.verses_count) &&
        (!preview || chapter.id === 1 || chapter.id === 2)
        ? [{ id: chapter.id, verses: chapter.verses_count }]
        : []
    ),
    tafsirs: tafsirOptions,
    reciters: reciterOptions,
    availability: {
      environment: env,
      tafsir: availability(
        tafsirList.state,
        tafsirs.length,
        tafsirOptions.length,
      ),
      recitation: availability(
        reciterList.state,
        reciters.length,
        reciterOptions.length,
      ),
    },
  };
}

async function catalog(lang: string): Promise<Json> {
  const active = catalogs.get(lang);
  if (active && active.expires > Date.now()) return active.value;
  const value = fetchCatalog(lang);
  catalogs.set(lang, { value, expires: Date.now() + 60_000 });
  try {
    return await value;
  } catch (error) {
    if (catalogs.get(lang)?.value === value) catalogs.delete(lang);
    throw error;
  }
}

type Markup = { nodeName: string; childNodes?: Markup[]; value?: string };

export function plainText(html: string): string {
  const blocks = new Set([
    "p",
    "div",
    "li",
    "br",
    "h1",
    "h2",
    "h3",
    "blockquote",
  ]);
  function read(node: Markup): string {
    if (node.nodeName === "#text") return node.value ?? "";
    if (["script", "style", "iframe"].includes(node.nodeName)) return "";
    const body = node.childNodes?.map(read).join("") ?? "";
    return blocks.has(node.nodeName) ? `\n${body}\n` : body;
  }
  return read(parseFragment(html) as Markup).replace(/\n{3,}/g, "\n\n").trim();
}

function integer(query: URLSearchParams, key: string, max: number): number {
  const value = query.get(key);
  if (!value || !/^[1-9]\d{0,6}$/.test(value) || Number(value) > max) {
    throw new ApiError(400, "invalid_parameters");
  }
  return Number(value);
}

function checkParams(query: URLSearchParams, allowed: string[]) {
  for (const name of query.keys()) {
    if (!allowed.includes(name) || query.getAll(name).length !== 1) {
      throw new ApiError(400, "invalid_parameters");
    }
  }
}

async function takeRequest() {
  const key = setting("SUPABASE_SERVICE_ROLE_KEY");
  const result = await fetch(
    `${setting("SUPABASE_URL")}/rest/v1/rpc/take_quran_request`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${key}`,
        apikey: key,
        "Content-Type": "application/json",
      },
      body: "{}",
      signal: AbortSignal.timeout(2500),
    },
  );
  if (!result.ok) throw new ApiError(503, "service_unavailable");
  if (await result.json() !== true) throw new ApiError(429, "rate_limited");
}

async function mushafPage(query: URLSearchParams): Promise<Json> {
  checkParams(query, ["edition", "page"]);
  const edition = integer(query, "edition", 19);
  const page = integer(query, "page", 604);
  if (edition !== 1 && edition !== 19) {
    throw new ApiError(400, "invalid_parameters");
  }
  await takeRequest();
  const verses: Json[] = [];
  for (let batch = 1; batch <= 6; batch++) {
    const data = await provider(
      "/verses/by_page/" + page,
      "quran",
      new URLSearchParams({
        mushaf: String(edition),
        words: "true",
        word_fields: "code_v2,page_number,line_number",
        page: String(batch),
        per_page: "50",
      }),
    );
    for (const verse of objects(data.verses)) {
      if (
        typeof verse.verse_key !== "string" ||
        !/^[0-9]{1,3}:[0-9]{1,3}$/.test(verse.verse_key)
      ) {
        throw new ApiError(503, "provider_unavailable");
      }
      const words = objects(verse.words).filter((word) =>
        word.page_number === page
      );
      if (words.length === 0) continue;
      if (
        !words.every((word) =>
          typeof word.code_v2 === "string" && word.code_v2.length > 0 &&
          word.code_v2.length <= 16 && Number.isInteger(word.line_number)
        )
      ) {
        throw new ApiError(503, "provider_unavailable");
      }
      verses.push({
        key: verse.verse_key,
        words: words.map((word) => [word.line_number, word.code_v2]),
      });
    }
    const next = (data.pagination as Json | undefined)?.next_page;
    if (next == null) {
      if (verses.length === 0) throw new ApiError(404, "resource_unavailable");
      return { edition, page, verses };
    }
    if (next !== batch + 1) throw new ApiError(503, "provider_unavailable");
  }
  throw new ApiError(503, "provider_unavailable");
}

async function displayData(
  route: Route,
  query: URLSearchParams,
): Promise<Json> {
  if (route === "mushaf") return mushafPage(query);
  if (route === "catalog") {
    checkParams(query, ["lang"]);
    const lang = query.get("lang") ?? "ar";
    if (lang !== "ar" && lang !== "en") {
      throw new ApiError(400, "invalid_parameters");
    }
    await takeRequest();
    return catalog(lang);
  }
  checkParams(
    query,
    route === "recitation"
      ? ["surah", "ayah", "resource", "timings"]
      : ["surah", "ayah", "resource"],
  );
  const timings = query.get("timings") === "1";
  if (query.has("timings") && (!timings || query.has("ayah"))) {
    throw new ApiError(400, "invalid_parameters");
  }
  const surah = integer(query, "surah", 114);
  const resource = integer(query, "resource", 9_999_999);
  const requestedAyah = route === "tafsir" || query.has("ayah")
    ? integer(query, "ayah", 286)
    : null;
  await takeRequest();
  const active = await catalog("ar");
  const resources = objects(
    route === "tafsir" ? active.tafsirs : active.reciters,
  );
  if (!resources.some((item) => item.id === resource)) {
    throw new ApiError(404, "resource_unavailable");
  }
  const chapter = objects(active.chapters).find((row) => row.id === surah);
  if (
    !chapter || typeof chapter.verses !== "number" ||
    (requestedAyah !== null && requestedAyah > chapter.verses)
  ) {
    throw new ApiError(404, "resource_unavailable");
  }
  if (route === "tafsir") {
    const verse = `${surah}:${requestedAyah}`;
    const data = await provider(
      `/tafsirs/${resource}/by_ayah/${verse}`,
      "tafsirs",
    );
    const tafsir = data.tafsir as Json | undefined;
    const verses = tafsir?.verses as Json | undefined;
    if (
      !verses || !Object.hasOwn(verses, verse) ||
      tafsir?.resource_id !== resource ||
      typeof tafsir.text !== "string" || !tafsir.text.trim()
    ) {
      throw new ApiError(404, "resource_unavailable");
    }
    const text = plainText(tafsir.text);
    if (!text) throw new ApiError(404, "resource_unavailable");
    return { verse, resource, text };
  }
  const data = await provider(
    `/chapter_recitations/${resource}/${surah}`,
    "audio",
    requestedAyah === null && !timings
      ? undefined
      : new URLSearchParams({ segments: "true" }),
  );
  const audio = data.audio_file as Json | undefined;
  if (typeof audio?.audio_url !== "string" || audio.chapter_id !== surah) {
    throw new ApiError(404, "resource_unavailable");
  }
  const url = new URL(audio.audio_url);
  if (
    url.protocol !== "https:" || url.username || url.password || url.port ||
    !audioHosts.has(url.hostname)
  ) {
    throw new ApiError(503, "provider_unavailable");
  }
  const chapterAudio = { surah, resource, url: url.href };
  if (timings) {
    const starts = objects(audio.timestamps).flatMap((row) => {
      if (
        typeof row.verse_key !== "string" ||
        typeof row.timestamp_from !== "number" ||
        !Number.isSafeInteger(row.timestamp_from) || row.timestamp_from < 0 ||
        (typeof audio.duration === "number" && audio.duration > 0 &&
          row.timestamp_from >= audio.duration)
      ) return [];
      return [[row.verse_key, row.timestamp_from]];
    });
    if (starts.length === 0) {
      throw new ApiError(404, "verse_timing_unavailable");
    }
    return { ...chapterAudio, starts };
  }
  if (requestedAyah === null) return chapterAudio;
  const verse = `${surah}:${requestedAyah}`;
  const timestamp = objects(audio.timestamps ?? []).find((row) =>
    row.verse_key === verse
  );
  const startMs = timestamp?.timestamp_from;
  if (
    typeof startMs !== "number" || !Number.isSafeInteger(startMs) ||
    startMs < 0 || (typeof audio.duration === "number" && audio.duration > 0 &&
      startMs >= audio.duration)
  ) {
    throw new ApiError(404, "verse_timing_unavailable");
  }
  return { ...chapterAudio, verse, start_ms: startMs };
}

export async function handleRequest(request: Request): Promise<Response> {
  try {
    if (request.method !== "GET") throw new ApiError(405, "method_not_allowed");
    const url = new URL(request.url);
    const match =
      /^(?:\/functions\/v1)?\/quran\/v1\/(catalog|tafsir|recitation|mushaf)$/
        .exec(
          url.pathname,
        );
    if (!match) throw new ApiError(404, "route_not_found");
    return Response.json(
      await displayData(match[1] as Route, url.searchParams),
      {
        headers: { "Cache-Control": "private, no-store" },
      },
    );
  } catch (error) {
    const safe = error instanceof ApiError && error.status !== 401
      ? error
      : new ApiError(503, "service_unavailable");
    const headers: Record<string, string> = { "Cache-Control": "no-store" };
    if (safe.status === 429) headers["Retry-After"] = "60";
    return Response.json({ error: safe.code }, {
      status: safe.status,
      headers,
    });
  }
}
