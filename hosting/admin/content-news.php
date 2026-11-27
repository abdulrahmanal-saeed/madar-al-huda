<?php
declare(strict_types=1);

function contentNewsTable(PDO $db): void
{
    $db->exec("CREATE TABLE IF NOT EXISTS content_news (
        id INTEGER PRIMARY KEY, digest TEXT NOT NULL UNIQUE, channel TEXT NOT NULL,
        title TEXT NOT NULL, body TEXT NOT NULL, route TEXT NOT NULL,
        created_at INTEGER NOT NULL, state TEXT NOT NULL DEFAULT 'queued', attempt_at INTEGER NOT NULL DEFAULT 0
    )");
}

/** Only stable routes to features and published content can become destinations. */
function contentNewsTargets(array $content): array
{
    $targets = [
        '/home' => 'اليوم',
        '/quran' => 'المصحف',
        '/worship/adhkar' => 'الأذكار',
        '/worship/adhkar/listen' => 'أدعية مسموعة',
        '/worship/prayer-times' => 'مواقيت الصلاة',
        '/worship/ramadan' => 'رمضان',
        '/library' => 'المكتبة',
        '/library/hadith' => 'الحديث',
        '/library/articles' => 'المقالات',
        '/library/fiqh' => 'الفقه',
        '/learning/lessons' => 'الدروس',
        '/learning/prophet-stories' => 'قصص الأنبياء',
        '/settings/reminders' => 'التذكيرات',
        '/settings/downloads' => 'مركز التحميل',
    ];
    foreach ($content['appearance']['sections'] ?? [] as $section) {
        if (($section['kind'] ?? '') !== 'links' || ($section['visible'] ?? true) === false) continue;
        $id = $section['id'] ?? '';
        if (!is_string($id) || !preg_match('/\A[a-z0-9][a-z0-9-]{0,63}\z/', $id)) continue;
        $path = '/library/s/' . $id;
        $name = $section['title']['ar'] ?? $id;
        $targets[$path] = $name;
        foreach ($section['seasons'] ?? [] as $season) {
            $seasonId = $season['id'] ?? '';
            if (!is_string($seasonId) || !preg_match('/\A[a-z0-9][a-z0-9-]{0,63}\z/', $seasonId)) continue;
            $seasonPath = $path . '?' . http_build_query(['season' => $seasonId]);
            $seasonName = $name . ' · ' . ($season['title']['ar'] ?? $seasonId);
            $targets[$seasonPath] = $seasonName;
            foreach ($season['episodes'] ?? [] as $episode) {
                $number = $episode['number'] ?? null;
                if (!is_int($number) || $number < 1 || empty($episode['media'])) continue;
                $targets[$seasonPath . '&episode=' . $number] =
                    $seasonName . ' · ' . ($episode['title']['ar'] ?? 'الحلقة ' . $number);
            }
        }
    }
    return $targets;
}

function enqueueContentNews(PDO $db, array $published, int $revision): int
{
    contentNewsTable($db);
    $title = field('news_title');
    $body = field('news_body');
    $route = field('news_route');
    $channel = field('news_channel');
    if ($title === '' || mb_strlen($title) > 80 || $body === '' ||
        mb_strlen($body) > 220 || !isset(contentNewsTargets($published)[$route]) ||
        !in_array($channel, ['dev', 'live'], true)) {
        throw new InvalidArgumentException('اكتب عنوانًا ونصًا قصيرين واختر وجهة متاحة للإشعار.');
    }
    if ($channel === 'live' && getenv('MADAR_NEWS_LIVE') !== '1') {
        throw new InvalidArgumentException('إشعارات جميع المستخدمين غير مفعّلة في الاستضافة.');
    }
    $digest = hash('sha256', encode([$revision, $channel, $route, $title, $body]));
    $db->prepare('INSERT OR IGNORE INTO content_news (digest, channel, title, body, route, created_at)
        VALUES (?, ?, ?, ?, ?, ?)')->execute([$digest, $channel, $title, $body, $route, time()]);
    $row = $db->prepare('SELECT id FROM content_news WHERE digest = ?');
    $row->execute([$digest]);
    return (int) $row->fetchColumn();
}

function contentNewsRequest(string $url, string $body, array $headers): array
{
    $curl = curl_init($url);
    curl_setopt_array($curl, [
        CURLOPT_RETURNTRANSFER => true, CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => $body, CURLOPT_HTTPHEADER => $headers,
        CURLOPT_CONNECTTIMEOUT => 3, CURLOPT_TIMEOUT => 7,
        CURLOPT_FOLLOWLOCATION => false,
    ]);
    $result = curl_exec($curl);
    $status = (int) curl_getinfo($curl, CURLINFO_RESPONSE_CODE);
    return [$status, is_string($result) ? json_decode($result, true) : null];
}

function contentNewsToken(array $account): string
{
    $b64 = fn (string $value) => rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    $now = time();
    $signature = '';
    $claim = $b64('{"alg":"RS256","typ":"JWT"}') . '.' . $b64(encode([
        'iss' => $account['client_email'],
        'aud' => 'https://oauth2.googleapis.com/token',
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'iat' => $now, 'exp' => $now + 600,
    ]));
    if (!openssl_sign($claim, $signature, $account['private_key'], OPENSSL_ALGO_SHA256)) {
        throw new RuntimeException('FCM signing failed');
    }
    [$status, $response] = contentNewsRequest('https://oauth2.googleapis.com/token', http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $claim . '.' . $b64($signature),
    ]), ['Content-Type: application/x-www-form-urlencoded']);
    if ($status !== 200 || !is_string($response['access_token'] ?? null)) {
        throw new RuntimeException('FCM token unavailable');
    }
    return $response['access_token'];
}

function deliverContentNews(PDO $db, int $id): bool
{
    contentNewsTable($db);
    $path = storage() . '/firebase-messaging.json';
    if (!is_file($path) || is_link($path)) return false;
    $claim = $db->prepare("UPDATE content_news SET state = 'sending', attempt_at = ?
        WHERE id = ? AND (channel != 'live' OR ? = 1) AND (state IN ('queued', 'failed') OR (state = 'sending' AND attempt_at < ?))");
    $claim->execute([time(), $id, getenv('MADAR_NEWS_LIVE') === '1' ? 1 : 0, time() - 60]);
    if ($claim->rowCount() !== 1) return false;
    $ok = false;
    try {
        $select = $db->prepare('SELECT * FROM content_news WHERE id = ?');
        $select->execute([$id]);
        $news = $select->fetch();
        $account = json_decode(file_get_contents($path), true, 19, JSON_THROW_ON_ERROR);
        $project = $account['project_id'] ?? '';
        if (!is_string($project) || !preg_match('/\A[a-z0-9][a-z0-9-]{3,63}\z/', $project)) {
            throw new RuntimeException('FCM project unavailable');
        }
        $token = contentNewsToken($account);
        [$status] = contentNewsRequest("https://fcm.googleapis.com/v1/projects/$project/messages:send",
            encode(['message' => [
                'topic' => 'madar-content-' . $news['channel'],
                'data' => [
                    'id' => (string) $news['id'],
                    'title' => $news['title'],
                    'body' => $news['body'],
                    'route' => $news['route'],
                    'created_at' => (string) $news['created_at'],
                    'channel' => $news['channel'],
                ],
                'android' => ['priority' => 'high', 'ttl' => '604800s'],
            ]]),
            ["Authorization: Bearer $token", 'Content-Type: application/json']);
        $ok = $status >= 200 && $status < 300;
    } catch (Throwable) {
        // Leave the request inspectable and retryable without exposing credentials.
    }
    $db->prepare('UPDATE content_news SET state = ? WHERE id = ?')
        ->execute([$ok ? 'sent' : 'failed', $id]);
    return $ok;
}

function serveContentNews(PDO $db): never
{
    $channel = $_GET['channel'] ?? 'dev';
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'GET' || !in_array($channel, ['dev', 'live'], true)) {
        http_response_code(400);
        exit;
    }
    contentNewsTable($db);
    $rows = $db->prepare('SELECT id, title, body, route, created_at, channel
        FROM content_news WHERE channel = ? AND created_at >= ? ORDER BY id DESC LIMIT 24');
    $rows->execute([$channel, time() - 7 * 86400]);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-cache');
    echo encode(['items' => $rows->fetchAll()]);
    exit;
}
