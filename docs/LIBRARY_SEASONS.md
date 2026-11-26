# Managed library seasons

In the existing dashboard, go to Library sections, edit a custom section, and add a bilingual season. A season may hold up to 200 numbered episodes; a custom section supports up to 30 seasons.

- Single recording: create or edit an episode, then upload audio or video separately. Replace explicitly from that episode.
- Bulk: select up to 50 MP3/MP4 files per batch. Use e.g. Madar-Seerah-001.mp3 and Madar-Seerah-001.mp4; they are paired by the final numeric component in the selected season. Titles are initialized to Episode N and may be edited later. Existing titles/media are preserved; a duplicate or any other error stops the batch. Reload and select only remaining files.
- Drive: paste up to 50 individual public file links, one per line, with an optional filename after the link. Folder URLs and private Drive files are not supported. The server fetches and verifies each file, displaying progress. No files are published merely by uploading.
- Publish only after reviewing titles, content and rights. The media endpoint serves only recordings referenced by the current published visible sections, including byte ranges. Previous file versions are retained privately to support restoration; plan disk usage and backups. The application cap is 1.5 GiB per recording, but hosting/PHP limits can be smaller.
- Updated app: navigate Library > custom section > season, use Download entire season and choose audio, video or both. The shared download manager preserves complete files and skips them on subsequent runs. The Download Center library tab can manage season downloads as well. Older app versions continue to read existing links and ignore seasons. No store rollout is automatic.

Before publishing: test real MP3 and MP4 uploads, Drive imports, anonymous draft access denied, published range playback, both download formats and offline playback on a device.
