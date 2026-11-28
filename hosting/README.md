# Hosted admin (`hosting/`)

The dashboard at `https://quran.abdulrahmanalsaeed.com/admin/` manages the
content and appearance the app downloads. It is plain PHP 8 with SQLite, so
it runs on shared hosting without a build step.

## Layout on the server

```
domains/quran.abdulrahmanalsaeed.com/
├── public_html/
│   ├── index.html             ← public landing page
│   ├── madar-web/             ← site style, app brand artwork and web fonts
│   ├── admin/                 ← hosting/admin/*.php, dashboard.css, .htaccess
│   │   └── seed.php           ← generated once at setup, kept on updates
│   └── Prophet Stories/       ← story recordings + catalog.php
└── .madar-admin/              ← private, outside the web root
    ├── library.sqlite3        ← draft, published library, history, releases
    ├── sessions/              ← admin sessions (8 h, 2 h idle)
    ├── apk/                   ← uploaded release APKs
    ├── stories-archive/
    └── backups/               ← admin-<stamp>.tar.gz, library-<stamp>.sqlite3
```

Only `admin/index.php` is reachable: `.htaccess` denies every other PHP
file and the view partials return 404 when opened directly.

## What the app reads

| URL | Contents |
|---|---|
| `admin/?feed=library` | The published library (JSON, ETag). It holds the adhkar, duas, reciters, fiqh, articles, lessons, `appearance.theme` (colours, radius, text size, Ramadan switch) and `appearance.sections` (Library order, visibility, added link sections). |
| `admin/?feed=updates&channel=dev` | The latest published APK for in-app update notices. |
| `Prophet Stories/catalog.php` | The story series and their episode files. |

The app caps the library feed at 4 MB. The dashboard shows the draft size, warns above 1 MB (older builds stop there) and refuses to publish above 4 MB. A theme that fails the 4.5:1 readability checks cannot be published, and the app ignores one anyway.

## Publishing flow

1. Edit any section. Changes go to the **draft**.
2. **«نشر المسودة للتطبيق»** shows a confirmation, then publishes the draft. Every publish is kept in history with its date and can be restored into the draft.
3. Apps pick up the change on their next refresh: when opened, when brought back to the foreground, or every 15 minutes.

Delete, restore, story archive, release publish and update notifications all ask for confirmation first.

## Deploying an update

The Hostinger workflow deploys the public landing page and admin together.
To stage a local copy, run `python hosting/prepare_site.py /tmp/madar-web`
and place the prepared `admin` directory alongside `index.html`.
The public page reuses the app’s brand assets and links to the current dev
download, so publishing an APK does not require an edit to the page.

From a checkout of `main`:

```bash
python hosting/prepare_admin.py /tmp/admin-update --update   # copies code only
# back up on the server first
ssh -p 65002 <user>@<host> 'cd domains/quran.abdulrahmanalsaeed.com && \
  tar czf .madar-admin/backups/admin-$(date -u +%Y%m%d-%H%M%S).tar.gz -C public_html admin && \
  cp .madar-admin/library.sqlite3 .madar-admin/backups/library-$(date -u +%Y%m%d-%H%M%S).sqlite3'
tar cf - -C /tmp/admin-update admin | ssh -p 65002 <user>@<host> \
  'cd domains/quran.abdulrahmanalsaeed.com/public_html && tar xf -'
```

Then check:
- the login page, `?feed=library` and `?feed=updates&channel=dev` return 200;
- `admin/release-view.php` returns 403.

`--update` never touches `seed.php`, the database or uploaded files. Updating the code signs everyone out once only when the session format changes.

## Tests

CI lints every PHP file and runs `hosting/tests/apk_signature_test.php`, which checks the APK signer pin against synthetic signing blocks.

## Automatic dev releases

After each dev build, `.github/workflows/dev-release.yml` posts the signed APK
to `admin/?ci=release` with the `MADAR_ADMIN_RELEASE_TOKEN` secret. The server
keeps only that token's SHA-256 in `.madar-admin/ci-release-token.sha256`;
without the file the endpoint answers 404. The APK must pass the same checks
as a manual upload (signed APK, the dev channel's key, `x.y.z-dev.N` matching
build N, N above the published build) and is then published with an update
notice. To rotate the token, set a new secret and replace the hash file.


## Content news and devotional recordings

Upload MP3 recordings under Daily Duas, Daily Adhkar, Merits or Hisn. Save new
variants before attaching their individual recordings. Saving keeps the media
private until the next successful library publication.

The publication confirmation can queue a content announcement. Use the History
page for an announcement about existing content or to retry a failed delivery.
The default target is the dev audience. Production announcements are enabled
with MADAR_NEWS_LIVE=1 after confirming a dev notification opens the selected
content. The APK or AAB build reads the public Firebase Android configuration
from MADAR_FIREBASE_APP_ID, MADAR_FIREBASE_API_KEY, MADAR_FIREBASE_SENDER_ID and
MADAR_FIREBASE_PROJECT_ID. Set the corresponding MADAR_DEV_FIREBASE_* repository
variables for the separate dev Android registration. Place the FCM sender service account only in the
private admin storage as firebase-messaging.json. Give it permission to send
FCM messages for the configured project. Devices without an FCM subscription
check the public content-news feed on Android's periodic schedule.
