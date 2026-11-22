import { parseFragment } from "npm:parse5@7.3.0";

type Json = Record<string, unknown>;
type Scope = "quran" | "tafsirs" | "audio";
type Route = "catalog" | "tafsir" | "recitation";
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
    return typeof name === "string" && name.length > 0 ? [{ id, name }] : [];
  });
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
  ): Promise<Json> {
    if (!enabled) return {};
    try {
      return await provider(path, type, query);
    } catch (error) {
      console.warn(
        "Quran resource catalog unavailable",
        type,
        error instanceof ApiError ? error.code : "request_failed",
      );
      return {};
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
  const tafsirs = objects(tafsirList.tafsirs);
  const reciters = objects(reciterList.reciters);
  // The provider's prelive catalog is for testing the owner-selected sources.
  // Production uses only resource IDs approved for this application.
  const previewTafsirIds = ["ar-tafsir-ibn-kathir", "ar-tafsir-al-tabari"]
    .flatMap(
      (slug) =>
        tafsirs.flatMap((row) =>
          row.slug === slug && typeof row.id === "number" ? [row.id] : []
        ),
    );
  return {
    chapters: objects(chapters.chapters).flatMap((chapter) =>
      Number.isInteger(chapter.id) && Number.isInteger(chapter.verses_count) &&
        (!preview || chapter.id === 1 || chapter.id === 2)
        ? [{ id: chapter.id, verses: chapter.verses_count }]
        : []
    ),
    tafsirs: listed(
      tafsirs,
      preview && !tafsirIds.length ? previewTafsirIds : tafsirIds,
    ),
    reciters: listed(
      reciters,
      preview && !reciterIds.length ? [159] : reciterIds,
    ),
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

async function displayData(
  route: Route,
  query: URLSearchParams,
): Promise<Json> {
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
    route === "tafsir" ? ["surah", "ayah", "resource"] : ["surah", "resource"],
  );
  const surah = integer(query, "surah", 114);
  const resource = integer(query, "resource", 9_999_999);
  const requestedAyah = route === "tafsir" ? integer(query, "ayah", 286) : null;
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
  if (requestedAyah !== null) {
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
  return { surah, resource, url: url.href };
}

export async function handleRequest(request: Request): Promise<Response> {
  try {
    if (request.method !== "GET") throw new ApiError(405, "method_not_allowed");
    const url = new URL(request.url);
    const match =
      /^(?:\/functions\/v1)?\/quran\/v1\/(catalog|tafsir|recitation)$/.exec(
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
