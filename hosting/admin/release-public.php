<?php
if (!defined('MADAR_ADMIN')) {
    http_response_code(404);
    exit;
}
releasesRequest();
try {
    $channel = releaseChannel($_GET['updates']);
} catch (InvalidArgumentException) {
    http_response_code(404);
    exit;
}
$released = currentRelease($db, $channel);
header('Content-Type: text/html; charset=utf-8');
header('Cache-Control: no-cache');
if ($_SERVER['REQUEST_METHOD'] === 'HEAD') {
    exit;
}
?><!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>تنزيل مدار الهدى</title>
  <link rel="icon" href="/madar-web/mark.png" type="image/png">
  <link rel="stylesheet" href="/madar-web/brand.css">
  <link rel="stylesheet" href="dashboard.css?v=<?= e((string) @filemtime(__DIR__ . '/dashboard.css')) ?>">
</head>
<body>
<main class="auth-wrap">
  <section class="panel auth download-card">
    <a class="brand" href="/"><img src="/madar-web/mark.png" width="44" height="44" alt="">مدار الهدى</a>
    <h1>تنزيل مدار الهدى</h1>
    <?php if ($released === null): ?>
      <p>لا يوجد إصدار منشور لهذه القناة.</p>
    <?php else: ?>
      <?php $notes = json_decode($released['notes'], true, 8, JSON_THROW_ON_ERROR); ?>
      <h2 class="download-version"><bdi><?= e($released['name']) ?></bdi></h2>
      <?php if ($notes['ar'] !== ''): ?><p><?= e($notes['ar']) ?></p><?php endif; ?>
      <?php if ($notes['en'] !== ''): ?><p lang="en" dir="ltr"><?= e($notes['en']) ?></p><?php endif; ?>
      <a class="button primary" href="./?apk=<?= e($channel . '-' . $released['code']) ?>">تنزيل APK لأندرويد</a>
    <?php endif; ?>
  </section>
</main>
</body>
</html>
<?php exit;
