<?php
declare(strict_types=1);
require_once __DIR__ . '/fiqh-metadata.php';

/** Explicit staging migration. Existing users do not receive review/publish grants automatically. */
function fiqhReviewMigration(PDO $db): void
{
    fiqhTransaction($db, function () use ($db): void {
        if (!$db->query('SELECT 1 FROM fiqh_migrations WHERE version = 2')->fetchColumn()) {
            throw new RuntimeException('Apply fiqh schema versions 1 and 2 first');
        }
        if ($db->query('SELECT 1 FROM fiqh_migrations WHERE version = 3')->fetchColumn()) return;
        $db->exec(<<<'SQL'
CREATE TABLE fiqh_review_profiles (
    user_id INTEGER PRIMARY KEY REFERENCES users(id),
    reviewer_name TEXT NOT NULL CHECK(length(trim(reviewer_name)) > 0),
    qualifications TEXT NOT NULL CHECK(length(trim(qualifications)) > 0),
    active INTEGER NOT NULL CHECK(active IN (0,1)),
    verified_by INTEGER NOT NULL REFERENCES users(id),
    verified_at INTEGER NOT NULL
);
CREATE TABLE fiqh_publish_grants (
    user_id INTEGER PRIMARY KEY REFERENCES users(id),
    granted_by INTEGER NOT NULL REFERENCES users(id),
    granted_at INTEGER NOT NULL
);
CREATE TABLE fiqh_review_events (
    id INTEGER PRIMARY KEY,
    issue_id TEXT NOT NULL, revision INTEGER NOT NULL,
    state TEXT NOT NULL CHECK(state IN ('ready_for_review','under_review','changes_requested','approved','published','archived')),
    actor_id INTEGER NOT NULL REFERENCES users(id),
    actor_name TEXT NOT NULL, qualifications TEXT,
    content_hash TEXT NOT NULL CHECK(length(content_hash) = 64),
    notes TEXT NOT NULL, corrections TEXT NOT NULL, at INTEGER NOT NULL,
    FOREIGN KEY(issue_id, revision) REFERENCES fiqh_revisions(issue_id, revision)
);
CREATE INDEX fiqh_review_history ON fiqh_review_events(issue_id, revision, id);
CREATE TRIGGER fiqh_review_no_update BEFORE UPDATE ON fiqh_review_events
BEGIN SELECT RAISE(ABORT, 'immutable review event'); END;
CREATE TRIGGER fiqh_review_no_delete BEFORE DELETE ON fiqh_review_events
BEGIN SELECT RAISE(ABORT, 'immutable review event'); END;
CREATE TABLE fiqh_published (
    issue_id TEXT PRIMARY KEY,
    revision INTEGER NOT NULL,
    approval_id INTEGER NOT NULL REFERENCES fiqh_review_events(id),
    publisher_id INTEGER NOT NULL REFERENCES users(id),
    published_at INTEGER NOT NULL,
    FOREIGN KEY(issue_id, revision) REFERENCES fiqh_revisions(issue_id, revision)
);
CREATE TRIGGER fiqh_publish_guard_insert BEFORE INSERT ON fiqh_published
WHEN NOT EXISTS (
    SELECT 1 FROM fiqh_review_events e JOIN fiqh_revisions r
    ON r.issue_id=e.issue_id AND r.revision=e.revision
    WHERE e.id=NEW.approval_id AND e.issue_id=NEW.issue_id AND e.revision=NEW.revision
      AND e.state='approved' AND e.content_hash=r.content_hash
      AND e.id=(SELECT MAX(id) FROM fiqh_review_events WHERE issue_id=e.issue_id AND revision=e.revision)
      AND r.revision=(SELECT MAX(revision) FROM fiqh_revisions WHERE issue_id=r.issue_id)
)
BEGIN SELECT RAISE(ABORT, 'current approved revision required'); END;
CREATE TRIGGER fiqh_publish_guard_update BEFORE UPDATE ON fiqh_published
WHEN NOT EXISTS (
    SELECT 1 FROM fiqh_review_events e JOIN fiqh_revisions r
    ON r.issue_id=e.issue_id AND r.revision=e.revision
    WHERE e.id=NEW.approval_id AND e.issue_id=NEW.issue_id AND e.revision=NEW.revision
      AND e.state='approved' AND e.content_hash=r.content_hash
      AND e.id=(SELECT MAX(id) FROM fiqh_review_events WHERE issue_id=e.issue_id AND revision=e.revision)
      AND r.revision=(SELECT MAX(revision) FROM fiqh_revisions WHERE issue_id=r.issue_id)
)
BEGIN SELECT RAISE(ABORT, 'current approved revision required'); END;
SQL);
        $db->prepare('INSERT INTO fiqh_migrations VALUES (3, ?)')->execute([time()]);
    });
}

/** Version 4 is required before enabling permission administration. */
function fiqhPermissionMigration(PDO $db): void
{
    fiqhTransaction($db, function () use ($db): void {
        if (!$db->query('SELECT 1 FROM fiqh_migrations WHERE version=3')->fetchColumn()) {
            throw new RuntimeException('Apply fiqh schema version 3 first');
        }
        if ($db->query('SELECT 1 FROM fiqh_migrations WHERE version=4')->fetchColumn()) return;
        $db->exec(<<<'SQL'
CREATE TABLE fiqh_permission_events (
    id INTEGER PRIMARY KEY, actor_id INTEGER NOT NULL REFERENCES users(id),
    subject_id INTEGER NOT NULL REFERENCES users(id), action TEXT NOT NULL,
    details TEXT NOT NULL CHECK(json_valid(details)), at INTEGER NOT NULL
);
CREATE TRIGGER fiqh_permission_no_update BEFORE UPDATE ON fiqh_permission_events
BEGIN SELECT RAISE(ABORT, 'immutable permission event'); END;
CREATE TRIGGER fiqh_permission_no_delete BEFORE DELETE ON fiqh_permission_events
BEGIN SELECT RAISE(ABORT, 'immutable permission event'); END;
SQL);
        $db->prepare('INSERT INTO fiqh_migrations VALUES (4,?)')->execute([time()]);
    });
}

function fiqhPermissionEvent(PDO $db, int $actor, int $subject, string $action, array $details): void
{
    $db->prepare('INSERT INTO fiqh_permission_events (actor_id,subject_id,action,details,at) VALUES (?,?,?,?,?)')
        ->execute([$actor,$subject,$action,fiqhJson($details),time()]);
}

function fiqhHumanUser(PDO $db, int $id): array
{
    $query = $db->prepare('SELECT id, username, role FROM users WHERE id = ? AND disabled = 0');
    $query->execute([$id]);
    $user = $query->fetch(PDO::FETCH_ASSOC);
    if (!$user || $id < 1) throw new InvalidArgumentException('Active human account required');
    return $user;
}

/** Explicit owner operation; must be exposed only through authenticated CSRF-protected owner UI. */
function fiqhSetReviewerProfile(PDO $db, int $ownerId, int $reviewerId, string $name, string $qualifications, bool $active): void
{
    fiqhTransaction($db, function () use ($db, $ownerId, $reviewerId, $name, $qualifications, $active): void {
        if (fiqhHumanUser($db, $ownerId)['role'] !== 'owner'
            || fiqhHumanUser($db, $reviewerId)['role'] !== 'reviewer'
            || $ownerId === $reviewerId || trim($name) === '' || trim($qualifications) === '') {
            throw new InvalidArgumentException('Owner-verified reviewer profile required');
        }
        $db->prepare('INSERT INTO fiqh_review_profiles VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(user_id) DO UPDATE SET reviewer_name=excluded.reviewer_name,
            qualifications=excluded.qualifications, active=excluded.active,
            verified_by=excluded.verified_by, verified_at=excluded.verified_at')
            ->execute([$reviewerId, trim($name), trim($qualifications), (int)$active, $ownerId, time()]);
        fiqhPermissionEvent($db,$ownerId,$reviewerId,'reviewer_profile',
            ['name'=>trim($name),'qualifications'=>trim($qualifications),'active'=>$active]);
    });
}

function fiqhSetPublisherGrant(PDO $db, int $ownerId, int $publisherId, bool $active): void
{
    fiqhTransaction($db, function () use ($db, $ownerId, $publisherId, $active): void {
        if (fiqhHumanUser($db, $ownerId)['role'] !== 'owner') {
            throw new InvalidArgumentException('Owner permission required');
        }
        fiqhHumanUser($db, $publisherId);
        if ($active) {
            $db->prepare('INSERT INTO fiqh_publish_grants VALUES (?, ?, ?) ON CONFLICT(user_id)
                DO UPDATE SET granted_by=excluded.granted_by, granted_at=excluded.granted_at')
                ->execute([$publisherId, $ownerId, time()]);
        } else {
            $db->prepare('DELETE FROM fiqh_publish_grants WHERE user_id=?')->execute([$publisherId]);
        }
        fiqhPermissionEvent($db,$ownerId,$publisherId,'publisher_grant',['active'=>$active]);
    });
}

function fiqhReviewerProfile(PDO $db, array $user): array
{
    if ($user['role'] !== 'reviewer') throw new InvalidArgumentException('Scholarly reviewer role required');
    $query = $db->prepare('SELECT * FROM fiqh_review_profiles WHERE user_id=? AND active=1');
    $query->execute([$user['id']]);
    $profile = $query->fetch(PDO::FETCH_ASSOC);
    if (!$profile) throw new InvalidArgumentException('Verified scholarly profile required');
    return $profile;
}

function fiqhAssertPublisher(PDO $db, array $user): void
{
    $q = $db->prepare('SELECT 1 FROM fiqh_publish_grants WHERE user_id=?');
    $q->execute([$user['id']]);
    if (!$q->fetchColumn()) throw new InvalidArgumentException('Explicit publisher grant required');
}

function fiqhReviewCurrent(PDO $db, string $id, int $revision): ?array
{
    $q = $db->prepare('SELECT * FROM fiqh_review_events WHERE issue_id=? AND revision=? ORDER BY id DESC LIMIT 1');
    $q->execute([$id, $revision]);
    $row = $q->fetch(PDO::FETCH_ASSOC);
    return $row ?: null;
}

/** Editorial completeness; reviewer still verifies attribution, editions and reasoning. */
function fiqhReviewErrors(array $revision): array
{
    $body = json_decode($revision['body'], true, 64, JSON_THROW_ON_ERROR);
    $sources = json_decode($revision['source_snapshot'], true, 64, JSON_THROW_ON_ERROR);
    if (!fiqhRevisionHashValid($revision)) return ['revision.hash'];
    $shape=fiqhShapeErrors($body);
    if ($shape!==[]) return $shape;
    $errors = fiqhCompletenessErrors($body);
    foreach (fiqhCollectSources($body) as $id) {
        $source = $sources[$id] ?? [];
        try { fiqhValidateSource($source); }
        catch (InvalidArgumentException) { $errors[]='sources.'.$id.'.shape'; continue; }
        if (($source['id'] ?? null)!==$id || ($source['status'] ?? null) !== 'draft' || !fiqhBilingual($source['title'] ?? null)
            || !is_string($source['license'] ?? null) || trim($source['license']) === '') {
            $errors[] = 'sources.' . $id . '.metadata';
        }
        if (($source['sourceType'] ?? null) === 'book'
            && (!fiqhBilingual($source['author'] ?? null) || !is_string($source['edition'] ?? null)
                || trim($source['edition']) === '' || !is_string($source['publisher'] ?? null)
                || trim($source['publisher']) === '')) {
            $errors[] = 'sources.' . $id . '.edition';
        }
    }
    return array_values(array_unique($errors));
}

function fiqhAppendReview(PDO $db, array $revision, string $state, array $user, ?array $profile, string $notes, string $corrections): int
{
    $db->prepare('INSERT INTO fiqh_review_events (issue_id,revision,state,actor_id,actor_name,qualifications,content_hash,notes,corrections,at)
        VALUES (?,?,?,?,?,?,?,?,?,?)')->execute([$revision['issue_id'], $revision['revision'], $state,
        $user['id'], $profile['reviewer_name'] ?? $user['username'], $profile['qualifications'] ?? null,
        $revision['content_hash'], $notes, $corrections, time()]);
    return (int)$db->lastInsertId();
}

/** Only call from authenticated human session. No MCP or import approval actions. */
function fiqhIndependentReviewer(PDO $db,string $id,int $userId):bool
{
    $q=$db->prepare('SELECT 1 FROM fiqh_revisions WHERE issue_id=? AND actor=? LIMIT 1');
    $q->execute([$id,'user:'.$userId]);
    return !$q->fetchColumn();
}

function fiqhReviewTransition(PDO $db, int $userId, string $id, int $expectedRevision, int $expectedEventId, string $action, string $notes = '', string $corrections = ''): array
{
    return fiqhTransaction($db, function () use ($db,$userId,$id,$expectedRevision,$expectedEventId,$action,$notes,$corrections): array {
        $user = fiqhHumanUser($db, $userId);
        $revision = fiqhLatestRevision($db, $id);
        if ($revision === null || (int)$revision['revision'] !== $expectedRevision) {
            throw new InvalidArgumentException('Current issue revision required');
        }
        $last = fiqhReviewCurrent($db, $id, $expectedRevision);
        if ($expectedEventId !== (int)($last['id'] ?? 0)) {
            throw new InvalidArgumentException('Review decision changed; reload the current review');
        }
        $state = $last['state'] ?? 'draft';
        $profile = null;
        $next = match ($action) {
            'submit' => 'ready_for_review',
            'start' => 'under_review',
            'request_changes' => 'changes_requested',
            'approve' => 'approved',
            'publish' => 'published',
            default => throw new InvalidArgumentException('Unknown review action'),
        };
        $expected = match ($action) {
            'submit' => ['draft','changes_requested'],
            'start' => ['ready_for_review'],
            'request_changes','approve' => ['under_review'],
            'publish' => ['approved'],
        };
        if (!in_array($state, $expected, true)) throw new InvalidArgumentException('Invalid review transition');
        if ($action === 'submit' && !in_array($user['role'], ['owner','editor','reviewer'], true)) {
            throw new InvalidArgumentException('Editor permission required');
        }
        if (in_array($action, ['start','request_changes','approve'], true)) {
            $profile = fiqhReviewerProfile($db, $user);
            if ($action !== 'start' && (int)$last['actor_id'] !== $userId) {
                throw new InvalidArgumentException('Assigned reviewer must make the decision');
            }
            if (in_array($action, ['request_changes','approve'], true) && trim($notes) === '') {
                throw new InvalidArgumentException('Review notes required');
            }
            if ($action === 'request_changes' && trim($corrections) === '') {
                throw new InvalidArgumentException('Required corrections must be recorded');
            }
            if ($action === 'approve' && !fiqhIndependentReviewer($db,$id,$userId)) {
                throw new InvalidArgumentException('Independent reviewer required');
            }
        }
        if (in_array($action, ['submit','approve','publish'], true)) {
            $errors = fiqhReviewErrors($revision);
            if ($errors !== []) throw new InvalidArgumentException('Incomplete revision: ' . implode(', ', $errors));
        }
        if ($action === 'publish') {
            fiqhAssertPublisher($db, $user);
            // Re-check active scholarly qualification and revision binding at publication time.
            $currentProfile=fiqhReviewerProfile($db, fiqhHumanUser($db, (int)$last['actor_id']));
            if ($currentProfile['reviewer_name']!==$last['actor_name']||$currentProfile['qualifications']!==$last['qualifications']) {
                throw new InvalidArgumentException('Reviewer identity or qualification changed; a fresh review is required');
            }
            if (!hash_equals($revision['content_hash'], $last['content_hash'])) {
                throw new InvalidArgumentException('Approval hash mismatch');
            }
            $db->prepare('INSERT INTO fiqh_published VALUES (?,?,?,?,?) ON CONFLICT(issue_id)
                DO UPDATE SET revision=excluded.revision,approval_id=excluded.approval_id,
                publisher_id=excluded.publisher_id,published_at=excluded.published_at')
                ->execute([$id,$expectedRevision,$last['id'],$userId,time()]);
        }
        $event = fiqhAppendReview($db,$revision,$next,$user,$profile,$notes,$corrections);
        return ['id'=>$id,'revision'=>$expectedRevision,'state'=>$next,'eventId'=>$event];
    });
}

/** Internal read projection only. Public route and safe field allowlist are a later milestone. */
function fiqhPublishedRevision(PDO $db, string $id): ?array
{
    $q = $db->prepare("SELECT r.*, p.approval_id, p.published_at FROM fiqh_published p
        JOIN fiqh_revisions r ON r.issue_id=p.issue_id AND r.revision=p.revision
        JOIN fiqh_review_events e ON e.id=p.approval_id AND e.issue_id=r.issue_id AND e.revision=r.revision
        AND e.state='approved' AND e.content_hash=r.content_hash WHERE p.issue_id=?");
    $q->execute([$id]);
    return $q->fetch(PDO::FETCH_ASSOC) ?: null;
}


/** Withdraw the exact published revision; newer drafts remain untouched. */
function fiqhArchivePublication(PDO $db, int $userId, string $id, int $expectedPublishedRevision, string $reason): array
{
    return fiqhTransaction($db, function () use ($db,$userId,$id,$expectedPublishedRevision,$reason): array {
        $user = fiqhHumanUser($db,$userId);
        fiqhAssertPublisher($db,$user);
        if (trim($reason) === '') throw new InvalidArgumentException('Archive reason required');
        $published = fiqhPublishedRevision($db,$id);
        if ($published === null || (int)$published['revision'] !== $expectedPublishedRevision) {
            throw new InvalidArgumentException('Published revision changed or absent');
        }
        $db->prepare('DELETE FROM fiqh_published WHERE issue_id=? AND revision=?')
            ->execute([$id,$expectedPublishedRevision]);
        $event = fiqhAppendReview($db,$published,'archived',$user,null,trim($reason),'');
        return ['id'=>$id,'revision'=>$expectedPublishedRevision,'state'=>'archived','eventId'=>$event];
    });
}

function fiqhReviewReady(PDO $db): bool
{
    return (bool)$db->query('SELECT 1 FROM fiqh_migrations WHERE version=4')->fetchColumn();
}

/** UI affordances only. All authorization is rechecked by the service. */
function fiqhAvailableReviewActions(PDO $db, int $userId, array $revision): array
{
    $user = fiqhHumanUser($db,$userId);
    $last = fiqhReviewCurrent($db,$revision['issue_id'],(int)$revision['revision']);
    $state = $last['state'] ?? 'draft';
    $actions = [];
    if (in_array($state,['draft','changes_requested'],true)) $actions[] = 'submit';
    try {
        fiqhReviewerProfile($db,$user);
        if ($state === 'ready_for_review') $actions[] = 'start';
        if ($state === 'under_review' && (int)$last['actor_id'] === $userId) {
            $actions[] = 'request_changes';
            if (fiqhIndependentReviewer($db,$revision['issue_id'],$userId)) $actions[] = 'approve';
        }
    } catch (InvalidArgumentException) { }
    try {
        fiqhAssertPublisher($db,$user);
        if ($state === 'approved') $actions[] = 'publish';
    } catch (InvalidArgumentException) { }
    return $actions;
}
