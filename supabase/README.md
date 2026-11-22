# Madar Al-Huda Quran service

The Android preview uses the `quran` Edge Function. Offline reading uses the separately licensed Tanzil source bundled with Flutter. The function's three GET operations under `/functions/v1/quran/v1` return display data for the app.

| Operation | Parameters | Purpose |
| --- | --- | --- |
| `catalog` | `lang` (`ar` or `en`) | Chapter IDs, verse counts, tafsir and chapter-reciter choices |
| `tafsir` | `surah`, `ayah`, `resource` | Source-identified tafsir for the requested verse, rendered as text |
| `recitation` | `surah`, `resource` | Source-identified HTTPS stream URL |

## Configuration

- Apply the Quran rate-limit migration before deploying the function. Guests use the project's public legacy anon JWT in the Authorization header. Only the function's service role may call the rate-limit RPC. The database stores one request counter and no visitor identifiers.
- Set `QF_CLIENT_ID`, `QF_CLIENT_SECRET` and `QF_ENV` in Edge Function Secrets. Use `prelive` or `production` with the matching Quran Foundation credentials. Granular read scopes are used by default. Set `QF_SCOPE_MODE=legacy` only when the client is issued the older `content` scope.
- Set `QF_TAFSIR_IDS` and `QF_RECITER_IDS` to comma-separated Quran Foundation resource IDs after recording the edition or recording, usage permission, and attribution in the source register. Prelive is limited to chapters 1 and 2 and can use the available named test resources from its catalog. Production requires explicit resource IDs. Chapter reciter IDs differ from ayah recitation IDs.
- Supply `MADAR_QURAN_API_URL` (ending in `/functions/v1/quran`) and `MADAR_SUPABASE_ANON_KEY` as Flutter dart-defines. These are client settings. Quran Foundation credentials and the Supabase service key belong only in Supabase. For a signed test build use `MADAR_FEATURE_PREVIEW=true` as an explicit dart-define only for a reviewed test distribution.
- To verify locally, run `deno test --allow-env supabase/functions/quran/handler_test.ts` from the repository root. Test live with the public anon key and check that chapters 1 and 2 match Tanzil at 7 and 286 verses. Check the individual tafsir and audio operations against the resources actually returned by the catalog. Use a production credential and verify all 114 chapter counts before store release.

See [Quran Foundation authentication](https://api-docs.quran.com/docs/quickstart/), [Developer Terms](https://api-docs.quran.com/legal/developer-terms/) and [Supabase Edge secrets](https://supabase.com/docs/guides/functions/secrets).
