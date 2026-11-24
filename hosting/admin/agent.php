<?php
declare(strict_types=1);

/*
 * The ChatGPT connector: an MCP server (Streamable HTTP, plain JSON-RPC over
 * POST) reached at /admin/mcp/<64-hex secret>.
 *
 * ChatGPT's custom-connector dialog offers OAuth or "no authentication", so
 * the secret lives in the address. That is a known cost: the address lands in
 * the web server's log. What keeps it tolerable: only the secret's hash is
 * stored, a key is revoked in one click on the «ChatGPT» page, every call is
 * logged, and a key can do only what is listed below. It edits the DRAFT,
 * through the same functions and checks as the dashboard; it can never
 * publish. Publishing is a request the owner approves on the «ChatGPT» page.
 */

/** Sections the connector may read and edit, and what each holds. */
const AGENT_SECTIONS = [
    'daily' => 'أذكار اليوم (adhkar entries; each belongs to one or more groups such as morning, evening)',
    'merits' => 'فضائل الذكر (merits of remembrance)',
    'hisn' => 'حصن المسلم (Fortress of the Muslim topics, with their own adhkar)',
    'duas' => 'الأدعية القرآنية (Quranic supplications by topic: verse ranges)',
    'names' => 'أسماء الله الحسنى (the Beautiful Names of Allah)',
    'articles' => 'المقالات (articles)',
    'lessons' => 'الدروس والاختبارات (lessons with optional quizzes)',
    'fiqh' => 'الفقه المقارن (comparative fiqh; needs scholarly approval before it can be published)',
];

/** The form fields each section's save takes, for the model to read. */
const AGENT_FIELDS = [
    'daily' => [
        'id' => 'New items only: an English id, lowercase letters, digits and dashes, e.g. "my-dua-1".',
        'ar' => 'Arabic title (required).',
        'en' => 'English title (required).',
        'wording' => 'The dhikr text in Arabic. Required unless hadith is given.',
        'meaning' => 'English meaning (optional).',
        'source_ar' => 'Arabic source line shown under the text, e.g. «رواه مسلم» (optional).',
        'source_en' => 'English source line (optional).',
        'hadith' => 'HadeethEnc hadith number to take the text from instead of wording (optional; leave empty when you write the text).',
        'groups' => 'Array of group ids the dhikr appears in, at least one: see list_items daily (groups).',
        'repeat' => 'Optional JSON list of repetition steps, e.g. [{"unit":"tasbih","count":33}].',
        'quran' => 'Optional JSON list of verse ranges [[surah, first, last]].',
    ],
    'merits' => [
        'id' => 'New items only: English id (lowercase, digits, dashes).',
        'ar' => 'Arabic title.', 'en' => 'English title.',
        'wording' => 'Arabic text (required unless hadith).', 'meaning' => 'English meaning (optional).',
        'source_ar' => 'Arabic source line (optional).', 'source_en' => 'English source line (optional).',
        'hadith' => 'HadeethEnc number instead of wording (optional).',
    ],
    'hisn' => [
        'ar' => 'Arabic topic title.', 'en' => 'English topic title.',
        'own_items' => "The topic's own adhkar as text: blocks separated by a line ---; inside a block optional lines «العنوان: …», «المصدر: …», «Title: …», «Source: …», «English: …», every other line is the Arabic text.",
        'chapters' => 'Optional comma-separated Hisn al-Muslim chapter numbers.',
        'hadiths' => 'Optional comma-separated HadeethEnc numbers.',
    ],
    'duas' => [
        'surah' => 'Surah number 1–114.', 'first' => 'First verse.', 'last' => 'Last verse.',
    ],
    'names' => [
        'number' => 'Order number 1–999.',
        'ar' => 'The name without vowel marks.', 'en' => 'English transliteration.',
        'vocalized' => 'The name with vowel marks (optional).',
        'body_ar' => 'Short meaning in Arabic (required).', 'body_en' => 'Short meaning in English (optional).',
        'description_ar' => 'Detailed explanation, Arabic.', 'description_en' => 'Detailed explanation, English.',
        'evidence_ar' => 'Evidence from Quran or Sunnah, Arabic.', 'evidence_en' => 'Evidence, English.',
        'impact_ar' => 'Effect of believing in the name, Arabic.', 'impact_en' => 'Effect, English.',
        'dua_ar' => 'Supplication, Arabic.', 'dua_en' => 'Supplication, English.',
        'source' => 'Optional https source link.',
    ],
    'articles' => [
        'ar' => 'Arabic title.', 'en' => 'English title.',
        'body_ar' => 'Arabic text.', 'body_en' => 'English text.', 'source' => 'https source link (required).',
    ],
    'lessons' => [
        'ar' => 'Arabic title.', 'en' => 'English title.',
        'body_ar' => 'Arabic text.', 'body_en' => 'English text.', 'source' => 'https source link (required).',
    ],
    'fiqh' => [
        'ar' => 'Arabic title.', 'en' => 'English title.',
        'ar_hanafi' => 'Hanafi position, Arabic (each school optional, at least one).', 'en_hanafi' => 'Hanafi, English.', 'source_hanafi' => 'Hanafi https source.',
        'ar_maliki' => 'Maliki, Arabic.', 'en_maliki' => 'Maliki, English.', 'source_maliki' => 'Maliki source.',
        'ar_shafii' => "Shafi'i, Arabic.", 'en_shafii' => "Shafi'i, English.", 'source_shafii' => "Shafi'i source.",
        'ar_hanbali' => 'Hanbali, Arabic.', 'en_hanbali' => 'Hanbali, English.', 'source_hanbali' => 'Hanbali source.',
    ],
];

class AgentError extends RuntimeException
{
}

/**
 * How ChatGPT publishes: 'chat' - a publish tool that ChatGPT confirms with
 * the owner every time (Always ask); 'dashboard' - only a request the owner
 * approves on the «ChatGPT» page.
 */
function agentPublishMode(PDO $db): string
{
    return adminSetting($db, 'agent_publish_mode') === 'dashboard' ? 'dashboard' : 'chat';
}

function agentTables(PDO $db): void
{
    $db->exec('CREATE TABLE IF NOT EXISTS agent_keys (
        id INTEGER PRIMARY KEY, label TEXT NOT NULL, key_hash TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL, last_used_at INTEGER, use_count INTEGER NOT NULL DEFAULT 0,
        revoked_at INTEGER
    )');
    $db->exec('CREATE TABLE IF NOT EXISTS agent_log (
        id INTEGER PRIMARY KEY, key_id INTEGER NOT NULL, at INTEGER NOT NULL,
        tool TEXT NOT NULL, ok INTEGER NOT NULL, detail TEXT NOT NULL DEFAULT \'\'
    )');
    $db->exec('CREATE TABLE IF NOT EXISTS admin_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    $db->exec('CREATE TABLE IF NOT EXISTS publish_requests (
        id INTEGER PRIMARY KEY, at INTEGER NOT NULL, key_id INTEGER NOT NULL, label TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT \'\', revision INTEGER NOT NULL, status TEXT NOT NULL DEFAULT \'pending\',
        decided_at INTEGER, decided_by TEXT
    )');
}

/** A new key; the raw secret exists only in this return value. */
function agentKeyCreate(PDO $db, string $label): string
{
    agentTables($db);
    $raw = bin2hex(random_bytes(32));
    $db->prepare('INSERT INTO agent_keys (label, key_hash, created_at) VALUES (?, ?, ?)')
        ->execute([mb_substr(trim($label) ?: 'ChatGPT', 0, 60), hash('sha256', $raw), time()]);
    return $raw;
}

function agentKeyVerify(PDO $db, string $raw): ?array
{
    if (strlen($raw) !== 64 || !ctype_xdigit($raw)) {
        return null;
    }
    agentTables($db);
    $query = $db->prepare('SELECT * FROM agent_keys WHERE key_hash = ? AND revoked_at IS NULL');
    $query->execute([hash('sha256', strtolower($raw))]);
    $key = $query->fetch();
    if ($key === false || !hash_equals((string) $key['key_hash'], hash('sha256', strtolower($raw)))) {
        return null;
    }
    $db->prepare('UPDATE agent_keys SET last_used_at = ?, use_count = use_count + 1 WHERE id = ?')
        ->execute([time(), $key['id']]);
    return $key;
}

function agentLog(PDO $db, array $key, string $tool, bool $ok, string $detail = ''): void
{
    try {
        $db->prepare('INSERT INTO agent_log (key_id, at, tool, ok, detail) VALUES (?, ?, ?, ?, ?)')
            ->execute([$key['id'], time(), $tool, $ok ? 1 : 0, mb_substr($detail, 0, 300)]);
    } catch (Throwable) {
        // Bookkeeping never costs the caller the request.
    }
}

/** Who a change by this key is recorded as in the audit log. */
function agentActor(array $key): string
{
    return 'ChatGPT · ' . $key['label'];
}

function agentSection(array $args): string
{
    $section = (string) ($args['section'] ?? '');
    if (!isset(AGENT_SECTIONS[$section])) {
        throw new AgentError('Unknown section "' . $section . '". Use one of: ' . implode(', ', array_keys(AGENT_SECTIONS)) . '.');
    }
    return $section;
}

function agentTopic(array $args): string
{
    $topic = (string) ($args['topic'] ?? '');
    if (!isset(topics()[$topic])) {
        throw new AgentError('The duas section needs topic, one of: ' . implode(', ', array_keys(topics())) . '.');
    }
    return $topic;
}

/** The draft's rows of a section, keyed the way the editor keys them. */
function agentRows(array $draft, string $section, string $topic): array
{
    $rows = in_array($section, BOOK_SECTIONS, true)
        ? ($draft['library'][$section] ?? [])
        : contentRows($draft, $section, $topic);
    $keyed = [];
    foreach ($rows as $index => $row) {
        $id = in_array($section, ['daily', 'merits'], true) || in_array($section, BOOK_SECTIONS, true)
            ? (string) ($row['id'] ?? $index)
            : (string) ($row['id'] ?? $index);
        $keyed[$id] = $row;
    }
    return $keyed;
}

function agentSummary(string $section, mixed $row): string
{
    if ($section === 'duas' && is_array($row)) {
        return verseRangeLabel($row);
    }
    $title = is_array($row) ? ($row['title'] ?? []) : [];
    return trim(($title['ar'] ?? '') . ' · ' . ($title['en'] ?? ''), ' ·');
}

/** Runs the dashboard's own save/delete with the given form fields. */
function agentChange(PDO $db, array $key, string $action, string $section, string $topic, array $fields): void
{
    $state = library($db);
    $_POST = array_map(static fn ($value) => is_array($value) ? array_map('strval', $value) : (string) $value, $fields);
    $_POST['revision'] = (string) $state['revision'];
    try {
        updateLibrary($db, $action, require __DIR__ . '/seed.php', $section, $topic,
            ['id' => 0, 'username' => agentActor($key), 'role' => 'editor']);
    } catch (InvalidArgumentException $failure) {
        throw new AgentError($failure->getMessage());
    } catch (JsonException) {
        throw new AgentError('A JSON field (repeat, quran or variants) is not valid JSON.');
    } finally {
        $_POST = [];
    }
    audit($db, agentActor($key), $action, $section, (string) ($fields['original'] ?? $fields['id'] ?? $fields['ar'] ?? ''));
}

function agentTools(string $mode = 'chat'): array
{
    $sectionProp = ['type' => 'string', 'enum' => array_keys(AGENT_SECTIONS)];
    $topicProp = ['type' => 'string', 'enum' => array_keys(topics()), 'description' => 'duas only.'];
    return [
        [
            'name' => 'list_sections',
            'description' => 'The content sections you can edit, with the fields each one takes. Call this first.',
            'inputSchema' => ['type' => 'object', 'properties' => new stdClass(), 'required' => []],
            'annotations' => ['readOnlyHint' => true],
        ],
        [
            'name' => 'list_items',
            'description' => "The items in a section of the DRAFT, with the id to pass to get_item, save_item and delete_item. For duas pass topic. For daily it also lists the groups.",
            'inputSchema' => ['type' => 'object', 'properties' => ['section' => $sectionProp, 'topic' => $topicProp], 'required' => ['section']],
            'annotations' => ['readOnlyHint' => true],
        ],
        [
            'name' => 'get_item',
            'description' => 'One item of the draft, in full.',
            'inputSchema' => ['type' => 'object', 'properties' => ['section' => $sectionProp, 'topic' => $topicProp, 'id' => ['type' => 'string']], 'required' => ['section', 'id']],
            'annotations' => ['readOnlyHint' => true],
        ],
        [
            'name' => 'save_item',
            'description' => "Add a new item, or change one (pass id), in the DRAFT. Nothing reaches the app until the owner approves a publish. Show the owner the content and get a yes before calling. fields are the section's form fields from list_sections; when changing an item, send every field you want kept (read it with get_item first). For names, fields.bulk may instead hold lines «name | transliteration | meaning_ar | meaning_en | vocalized | description_ar | description_en | evidence_ar | evidence_en | impact_ar | impact_en | dua_ar | dua_en».",
            'inputSchema' => [
                'type' => 'object',
                'properties' => [
                    'section' => $sectionProp, 'topic' => $topicProp,
                    'id' => ['type' => 'string', 'description' => 'The item to change; leave out to add a new one.'],
                    'fields' => ['type' => 'object', 'description' => 'Form fields for the section (see list_sections).'],
                ],
                'required' => ['section', 'fields'],
            ],
            'annotations' => ['readOnlyHint' => false, 'destructiveHint' => false],
        ],
        [
            'name' => 'delete_item',
            'description' => 'Remove an item from the DRAFT (any item, bundled or added). Confirm with the owner first.',
            'inputSchema' => ['type' => 'object', 'properties' => ['section' => $sectionProp, 'topic' => $topicProp, 'id' => ['type' => 'string']], 'required' => ['section', 'id']],
            'annotations' => ['readOnlyHint' => false, 'destructiveHint' => true],
        ],
        [
            'name' => 'draft_changes',
            'description' => 'What the draft changes compared with what the app has now.',
            'inputSchema' => ['type' => 'object', 'properties' => new stdClass(), 'required' => []],
            'annotations' => ['readOnlyHint' => true],
        ],
        $mode === 'chat' ? [
            'name' => 'publish',
            'description' => "Publish the draft to the app, for every user. Right before calling: call draft_changes, show the owner the list of changes in the chat, and get an explicit yes for publishing. Never publish as part of another request, and never without that yes. The owner keeps this tool on Always ask.",
            'inputSchema' => ['type' => 'object', 'properties' => [
                'summary' => ['type' => 'string', 'description' => 'One or two lines on what is being published, for the audit log.'],
            ], 'required' => ['summary']],
            'annotations' => ['readOnlyHint' => false, 'destructiveHint' => true, 'openWorldHint' => true, 'title' => 'Publish to the app'],
        ] : [
            'name' => 'request_publish',
            'description' => "Ask the owner to publish the draft to the app. This does NOT publish: it creates a request the owner approves or rejects on the ChatGPT page of the dashboard, every time. Tell the owner to open the link that comes back.",
            'inputSchema' => ['type' => 'object', 'properties' => ['note' => ['type' => 'string', 'description' => 'A short summary of what changed, for the owner.']], 'required' => []],
            'annotations' => ['readOnlyHint' => false, 'destructiveHint' => false],
        ],
    ];
}

function agentCall(PDO $db, array $key, string $tool, array $args): array
{
    $state = library($db);
    $draft = json_decode($state['draft'], true, 64, JSON_THROW_ON_ERROR);
    switch ($tool) {
        case 'list_sections':
            return ['sections' => array_map(
                static fn (string $about, string $section) => ['section' => $section, 'about' => $about, 'fields' => AGENT_FIELDS[$section]],
                AGENT_SECTIONS, array_keys(AGENT_SECTIONS),
            ), 'duas_topics' => topics()];
        case 'list_items':
            $section = agentSection($args);
            $topic = $section === 'duas' ? agentTopic($args) : '';
            $items = [];
            foreach (agentRows($draft, $section, $topic) as $id => $row) {
                $items[] = ['id' => (string) $id, 'title' => agentSummary($section, $row)];
            }
            $out = ['section' => $section, 'count' => count($items), 'items' => $items];
            if ($section === 'daily') {
                $out['groups'] = array_map(static fn (array $g) => ['id' => $g['id'], 'title' => $g['title']['ar'] ?? $g['id']], $draft['adhkar']['daily']['groups'] ?? []);
            }
            return $out;
        case 'get_item':
            $section = agentSection($args);
            $topic = $section === 'duas' ? agentTopic($args) : '';
            $rows = agentRows($draft, $section, $topic);
            $id = (string) ($args['id'] ?? '');
            if (!array_key_exists($id, $rows)) {
                throw new AgentError('No item "' . $id . '" in ' . $section . '. Use list_items.');
            }
            $item = ['id' => $id, 'item' => $rows[$id]];
            if ($section === 'daily') {
                $item['groups'] = array_values(array_map(static fn (array $g) => $g['id'], array_filter(
                    $draft['adhkar']['daily']['groups'] ?? [], static fn (array $g) => in_array($id, $g['entries'] ?? [], true),
                )));
            }
            return $item;
        case 'save_item':
            $section = agentSection($args);
            $topic = $section === 'duas' ? agentTopic($args) : '';
            $fields = is_array($args['fields'] ?? null) ? $args['fields'] : [];
            $id = (string) ($args['id'] ?? '');
            if ($id !== '' && !array_key_exists($id, agentRows($draft, $section, $topic))) {
                throw new AgentError('No item "' . $id . '" to change in ' . $section . '. Leave id out to add a new one.');
            }
            unset($fields['original'], $fields['revision'], $fields['action'], $fields['csrf']);
            agentChange($db, $key, 'save', $section, $topic, ['original' => $id] + $fields);
            return ['saved' => true, 'section' => $section, 'note' => 'Saved in the draft. Call request_publish when the owner wants it in the app.'];
        case 'delete_item':
            $section = agentSection($args);
            $topic = $section === 'duas' ? agentTopic($args) : '';
            $id = (string) ($args['id'] ?? '');
            if (!array_key_exists($id, agentRows($draft, $section, $topic))) {
                throw new AgentError('No item "' . $id . '" in ' . $section . '.');
            }
            agentChange($db, $key, 'delete', $section, $topic, ['original' => $id]);
            return ['deleted' => true, 'note' => 'Removed from the draft.'];
        case 'draft_changes':
            $changes = libraryDiff(json_decode($state['published'] ?? 'null', true), $draft);
            return ['changes' => count($changes), 'lines' => array_slice($changes, 0, 80)];
        case 'publish':
            if (agentPublishMode($db) !== 'chat') {
                throw new AgentError('Publishing from ChatGPT is turned off. Use request_publish; the owner approves it in the dashboard.');
            }
            if ($state['published'] === $state['draft']) {
                throw new AgentError('The draft has no changes to publish.');
            }
            $count = count(libraryDiff(json_decode($state['published'] ?? 'null', true), $draft));
            $_POST = ['revision' => (string) $state['revision']];
            try {
                updateLibrary($db, 'publish', require __DIR__ . '/seed.php', 'daily', 'forgiveness',
                    ['id' => 0, 'username' => agentActor($key), 'role' => 'editor']);
            } catch (InvalidArgumentException $failure) {
                throw new AgentError($failure->getMessage());
            } finally {
                $_POST = [];
            }
            audit($db, agentActor($key), 'publish', 'chatgpt', mb_substr(trim((string) ($args['summary'] ?? '')), 0, 200));
            $db->prepare("UPDATE publish_requests SET status = 'superseded' WHERE status = 'pending'")->execute();
            return ['published' => true, 'changes' => $count, 'note' => 'Published. The app picks it up on its next refresh.'];
        case 'request_publish':
            if ($state['published'] === $state['draft']) {
                throw new AgentError('The draft has no changes to publish.');
            }
            $db->prepare('UPDATE publish_requests SET status = ? WHERE status = ?')->execute(['superseded', 'pending']);
            $db->prepare('INSERT INTO publish_requests (at, key_id, label, note, revision) VALUES (?, ?, ?, ?, ?)')
                ->execute([time(), $key['id'], $key['label'], mb_substr(trim((string) ($args['note'] ?? '')), 0, 1000), $state['revision']]);
            $host = preg_replace('/[^a-z0-9.-]/i', '', (string) ($_SERVER['HTTP_HOST'] ?? '')) ?: 'quran.abdulrahmanalsaeed.com';
            return ['requested' => true, 'published' => false,
                'approve_at' => 'https://' . $host . '/admin/?section=chatgpt',
                'note' => 'Waiting for the owner to approve on the ChatGPT page of the dashboard. Nothing is published until then.'];
    }
    throw new AgentError('No tool named "' . $tool . '".');
}

/** POST /admin/mcp/<secret>: JSON-RPC 2.0 for ChatGPT's connector. */
function serveMcp(PDO $db, string $secret): never
{
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    $reply = static function (mixed $id, array $body, int $status = 200): never {
        http_response_code($status);
        if ($id === null && !isset($body['error'])) {
            http_response_code(202);
            exit;
        }
        echo json_encode(['jsonrpc' => '2.0', 'id' => $id] + $body, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    };
    agentTables($db);
    auditTable($db);
    $key = agentKeyVerify($db, $secret);
    if ($key === null) {
        // 404, not 401: a wrong address does not confirm it is the right shape.
        http_response_code(404);
        echo '{"error":"Not found"}';
        exit;
    }
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
        http_response_code(405);
        header('Allow: POST');
        echo '{"error":"This MCP server uses Streamable HTTP. POST JSON-RPC to this URL."}';
        exit;
    }
    $recent = $db->prepare('SELECT COUNT(*) FROM agent_log WHERE key_id = ? AND at > ?');
    $recent->execute([$key['id'], time() - 3600]);
    if ((int) $recent->fetchColumn() >= 300) {
        $reply(null, ['error' => ['code' => -32000, 'message' => 'Too many requests on this connector. Try again later.']], 429);
    }
    $request = json_decode((string) file_get_contents('php://input', false, null, 0, 262144), true);
    if (!is_array($request)) {
        $reply(null, ['error' => ['code' => -32700, 'message' => 'Parse error']]);
    }
    $id = $request['id'] ?? null;
    $method = (string) ($request['method'] ?? '');
    $params = is_array($request['params'] ?? null) ? $request['params'] : [];
    switch ($method) {
        case 'initialize':
            $reply($id, ['result' => [
                'protocolVersion' => (string) ($params['protocolVersion'] ?? '2025-06-18'),
                'capabilities' => ['tools' => ['listChanged' => false]],
                'serverInfo' => ['name' => 'Madar Al-Huda dashboard', 'version' => '1.0.0'],
                'instructions' => 'Edit the content of the Madar Al-Huda app (adhkar, duas, Hisn al-Muslim, Names of Allah, articles, lessons, fiqh). '
                    . 'Call list_sections first. Every change goes to the DRAFT only. Before save_item or delete_item, show the owner exactly what you will write and wait for approval. '
                    . (agentPublishMode($db) === 'chat'
                        ? 'To put changes in the app, call draft_changes, show the owner the changes, ask whether to publish, and call publish only after an explicit yes. Every publish needs its own yes. '
                        : 'To put changes in the app, call request_publish: the owner approves it in the dashboard; you cannot publish yourself. ')
                    . 'Speak Egyptian Arabic unless the owner writes in English.',
            ]]);
        case 'notifications/initialized':
        case 'notifications/cancelled':
            http_response_code(202);
            exit;
        case 'ping':
            $reply($id, ['result' => new stdClass()]);
        case 'tools/list':
            $reply($id, ['result' => ['tools' => agentTools(agentPublishMode($db))]]);
        case 'tools/call':
            $tool = (string) ($params['name'] ?? '');
            $args = is_array($params['arguments'] ?? null) ? $params['arguments'] : [];
            try {
                $out = agentCall($db, $key, $tool, $args);
                agentLog($db, $key, $tool, true, (string) ($args['section'] ?? '') . ' ' . (string) ($args['id'] ?? ''));
            } catch (AgentError $failure) {
                agentLog($db, $key, $tool, false, $failure->getMessage());
                $reply($id, ['result' => ['content' => [['type' => 'text', 'text' => $failure->getMessage()]], 'isError' => true]]);
            } catch (Throwable $failure) {
                error_log('Madar MCP ' . $tool . ': ' . $failure->getMessage());
                agentLog($db, $key, $tool, false, 'server error');
                $reply($id, ['result' => ['content' => [['type' => 'text', 'text' => 'Something went wrong on the server.']], 'isError' => true]]);
            }
            $reply($id, ['result' => [
                'content' => [['type' => 'text', 'text' => json_encode($out, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT)]],
                'structuredContent' => $out,
                'isError' => false,
            ]]);
        default:
            $reply($id, ['error' => ['code' => -32601, 'message' => 'Method not found: ' . $method]]);
    }
}

function agentPendingCount(PDO $db): int
{
    try {
        agentTables($db);
        return (int) $db->query("SELECT COUNT(*) FROM publish_requests WHERE status = 'pending'")->fetchColumn();
    } catch (Throwable) {
        return 0;
    }
}

/** Owner actions on the «ChatGPT» page. */
function changeAgent(PDO $db, array $user, string $action): string
{
    agentTables($db);
    if ($action === 'agent_key_create') {
        $raw = agentKeyCreate($db, field('label'));
        $host = preg_replace('/[^a-z0-9.-]/i', '', (string) ($_SERVER['HTTP_HOST'] ?? '')) ?: 'quran.abdulrahmanalsaeed.com';
        // Shown once, on the next page load only.
        $_SESSION['agent_url'] = 'https://' . $host . '/admin/mcp/' . $raw;
        return 'أُنشئ رابط جديد. انسخه الآن، فلن يظهر مرة أخرى.';
    }
    if ($action === 'agent_publish_mode') {
        $mode = field('mode') === 'dashboard' ? 'dashboard' : 'chat';
        setAdminSetting($db, 'agent_publish_mode', $mode);
        return $mode === 'chat'
            ? 'ChatGPT ينشر بعد تأكيدك في المحادثة كل مرة.'
            : 'النشر من ChatGPT يحتاج موافقتك من هذه الصفحة.';
    }
    if ($action === 'agent_key_revoke') {
        $db->prepare('UPDATE agent_keys SET revoked_at = ? WHERE id = ? AND revoked_at IS NULL')
            ->execute([time(), (int) field('key')]);
        return 'أُلغي الرابط ولن يعمل بعد الآن.';
    }
    $request = (int) field('request');
    $row = $db->prepare('SELECT * FROM publish_requests WHERE id = ? AND status = ?');
    $row->execute([$request, 'pending']);
    if ($row->fetch() === false) {
        throw new InvalidArgumentException('الطلب غير موجود أو انتهى.');
    }
    if ($action === 'agent_publish_approve') {
        // Publishes the draft as it is now, which the page showed in full.
        $_POST['revision'] = (string) library($db)['revision'];
        updateLibrary($db, 'publish', require __DIR__ . '/seed.php', 'daily', 'forgiveness', $user);
        $status = 'approved';
        $notice = 'نُشرت المسودة للتطبيق.';
    } else {
        $status = 'rejected';
        $notice = 'رُفض طلب النشر، والمسودة كما هي.';
    }
    $db->prepare('UPDATE publish_requests SET status = ?, decided_at = ?, decided_by = ? WHERE id = ?')
        ->execute([$status, time(), $user['username'], $request]);
    return $notice;
}
