# Madar Al-Huda Quran service

The Android preview uses the `quran` Edge Function. Offline reading uses the separately licensed Tanzil source bundled with Flutter. The function's three GET operations under `/functions/v1/quran/v1` return display data for the app.

| Operation | Parameters | Purpose |
| --- | --- | --- |
| `catalog` | `lang` (`ar` or `en`) | Chapter IDs, verse counts, tafsir and chapter-reciter choices |
| `tafsir` | `surah`, `ayah`, `resource` | Source-identified tafsir for the requested verse, rendered as text |
| `recitation` | `surah`, `resource`, optional `ayah` | Source-identified HTTPS stream URL and, when requested and available, the verified verse start in milliseconds |

## Configuration

- Apply the Quran rate-limit migration before deploying the function. Guests use the project's public legacy anon JWT in the Authorization header. Only the function's service role may call the rate-limit RPC. The database stores one request counter and no visitor identifiers.
- Set `QF_CLIENT_ID`, `QF_CLIENT_SECRET` and `QF_ENV` in Edge Function Secrets. Use `prelive` or `production` with the matching Quran Foundation credentials. Granular read scopes are used by default. Set `QF_SCOPE_MODE=legacy` only when the client is issued the older `content` scope.
- Set `QF_TAFSIR_IDS` and `QF_RECITER_IDS` to comma-separated Quran Foundation resource IDs after recording the edition or recording, usage permission, and attribution in the source register. Prelive is limited to chapters 1 and 2. With empty allow-lists, the reader uses the named Arabic candidates and Maher Al-Muaiqly when present. The documented prelive alternatives are English Ibn Kathir 169 and Mishari Alafasy 7. Production requires explicit resource IDs. Chapter reciter IDs differ from ayah recitation IDs.
- Supply `MADAR_QURAN_API_URL` (ending in `/functions/v1/quran`) and `MADAR_SUPABASE_ANON_KEY` as Flutter dart-defines. These are client settings. Quran Foundation credentials and the Supabase service key belong only in Supabase. For a signed test build use `MADAR_FEATURE_PREVIEW=true` as an explicit dart-define only for a reviewed test distribution.
- To verify locally, run `deno test --allow-env supabase/functions/quran/handler_test.ts` from the repository root. Test live with the public anon key and check that chapters 1 and 2 match Tanzil at 7 and 286 verses. Check the individual tafsir and audio operations against the resources actually returned by the catalog. Use a production credential and verify all 114 chapter counts before store release.

See [Quran Foundation authentication](https://api-docs.quran.com/docs/quickstart/), [Developer Terms](https://api-docs.quran.com/legal/developer-terms/) and [Supabase Edge secrets](https://supabase.com/docs/guides/functions/secrets).

## Live preview verification on 2026-11-23

The connected prelive project returned Ibn Kathir (Abridged) in English and Mishari Alafasy. Requests for tafsir on 1:1 and 2:255 returned the requested verse, and both chapter files returned an HTTP 206 byte-range response with type `audio/mpeg` from the provider CDN. The catalog includes the environment and resource availability for the installed test build.

Use `MADAR_CHANNEL=preview` for a side-by-side Android test package. Pass the public Supabase client settings described above when building this APK. The package uses the same Edge URL when an approved production account is later configured on the server.

The Mobile CI debug job reads the two public Android settings from GitHub Actions repository variables of the same names. When configured, it builds the side-by-side preview as its APK artifact. Keep provider credentials and service-role keys in Supabase Secrets.

Production function version 8 returned the 114 chapters, Tafsir Ibn Kathir for 112:1, and Maher Al-Muaiqly's chapter recording for Al-Ikhlas. The ayah operation returned the same recording with verse 112:2 at 12,310 ms. A recording without timings still supports chapter playback. [Chapter audio and timestamps](https://api-docs.quran.com/docs/content_apis_versioned/4.0.0/chapter-reciter-audio-file/)
