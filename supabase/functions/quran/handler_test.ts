import { handleRequest, plainText, previewTafsirIds } from "./handler.ts";

function equal(actual: unknown, expected: unknown) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

Deno.test("tafsir markup is rendered as inert text in the client", () => {
  equal(
    plainText("<p>One &amp; two</p><script>omit()</script><p>Three</p>"),
    "One & two\n\nThree",
  );
});

Deno.test("prelive prefers the selected Arabic editions and falls back to documented Ibn Kathir", () => {
  equal(previewTafsirIds([{ id: 169 }]), [169]);
  equal(
    previewTafsirIds([
      { id: 15, slug: "ar-tafsir-al-tabari" },
      { id: 14, slug: "ar-tafsir-ibn-kathir" },
      { id: 169, slug: "en-tafsir-ibn-kathir" },
    ]),
    [14, 15],
  );
});

Deno.test("route and input validation precede upstream calls", async () => {
  const base = "https://example.test/functions/v1/quran/v1/";
  for (
    const [path, method, status] of [
      ["unexpected", "GET", 404],
      ["catalog", "POST", 405],
      ["catalog?lang=ar&lang=en", "GET", 400],
      ["tafsir?surah=2&ayah=287&resource=1", "GET", 400],
      ["recitation?surah=115&resource=1", "GET", 400],
    ] as const
  ) {
    const response = await handleRequest(new Request(base + path, { method }));
    equal(response.status, status);
  }
});

Deno.test("guest reader gets only approved resources, matched tafsir and audio", async () => {
  const values = {
    QF_ENV: "prelive",
    QF_CLIENT_ID: "test",
    QF_CLIENT_SECRET: "test",
    QF_TAFSIR_IDS: "100",
    QF_RECITER_IDS: "200",
    SUPABASE_URL: "https://database.test",
    SUPABASE_SERVICE_ROLE_KEY: "test",
  };
  const previous = Object.keys(values).map((key) =>
    [key, Deno.env.get(key)] as const
  );
  for (const [key, value] of Object.entries(values)) Deno.env.set(key, value);
  const fetchOriginal = globalThis.fetch;
  let tokenRequests = 0;
  let allowRequest = true;
  globalThis.fetch = (input) => {
    const url = new URL(String(input));
    const path = url.pathname;
    if (path.endsWith("/take_quran_request")) {
      return Promise.resolve(Response.json(allowRequest));
    }
    if (path.endsWith("/oauth2/token")) {
      tokenRequests++;
      return Promise.resolve(
        Response.json({ access_token: "test", expires_in: 3600 }),
      );
    }
    if (path.endsWith("/chapters")) {
      return Promise.resolve(Response.json({
        chapters: [{ id: 1, verses_count: 7 }, { id: 2, verses_count: 286 }, {
          id: 114,
          verses_count: 6,
        }],
      }));
    }
    if (path.endsWith("/chapter_reciters")) {
      return Promise.resolve(Response.json({
        reciters: [{ id: 200, name: "Approved reader" }, {
          id: 201,
          name: "Other",
        }],
      }));
    }
    if (path.endsWith("/resources/tafsirs")) {
      return Promise.resolve(Response.json({
        tafsirs: [{ id: 100, name: "Approved author" }, {
          id: 101,
          name: "Other",
        }],
      }));
    }
    if (path.endsWith("/100/by_ayah/2:4")) {
      return Promise.resolve(Response.json({
        tafsir: {
          resource_id: 100,
          verses: { "2:3": { id: 1 }, "2:4": { id: 2 } },
          text: "<p>Example &amp; context</p>",
        },
      }));
    }
    if (path.endsWith("/200/2")) {
      return Promise.resolve(Response.json({
        audio_file: {
          chapter_id: 2,
          audio_url: "https://audio.qurancdn.com/sample.mp3",
        },
      }));
    }
    throw new Error("Unexpected upstream request");
  };
  try {
    const request = (path: string) =>
      handleRequest(new Request("https://example.test/quran/v1/" + path));
    const catalog = await request("catalog?lang=ar");
    equal(catalog.status, 200);
    equal(await catalog.json(), {
      chapters: [{ id: 1, verses: 7 }, { id: 2, verses: 286 }],
      tafsirs: [{ id: 100, name: "Approved author" }],
      reciters: [{ id: 200, name: "Approved reader" }],
      availability: {
        environment: "prelive",
        tafsir: "ready",
        recitation: "ready",
      },
    });
    equal((await request("catalog?lang=ar")).status, 200);
    equal(await (await request("tafsir?surah=2&ayah=4&resource=100")).json(), {
      verse: "2:4",
      resource: 100,
      text: "Example & context",
    });
    equal(await (await request("recitation?surah=2&resource=200")).json(), {
      surah: 2,
      resource: 200,
      url: "https://audio.qurancdn.com/sample.mp3",
    });
    equal((await request("tafsir?surah=1&ayah=4&resource=101")).status, 404);
    equal((await request("recitation?surah=114&resource=200")).status, 404);
    equal(tokenRequests, 3);
    allowRequest = false;
    const limited = await request("catalog");
    equal(limited.status, 429);
    equal(limited.headers.get("Retry-After"), "60");
  } finally {
    globalThis.fetch = fetchOriginal;
    for (const [key, value] of previous) {
      if (value === undefined) Deno.env.delete(key);
      else Deno.env.set(key, value);
    }
  }
});
