<?php
declare(strict_types=1);
require_once __DIR__.'/fiqh-storage.php';

/** Canonical draft-only import: no user-supplied lifecycle, review, or publish state.
 * Preview uses the same transaction and write path as commit, then rolls back.
 * Updates require an explicit operation and exact expected revision.
 */
function fiqhImportRows(array $payload): array
{
    if (array_diff(array_keys($payload),['schemaVersion','issues']) !== [] ||
        ($payload['schemaVersion'] ?? null) !== 1 || !is_array($payload['issues'] ?? null)
        || !array_is_list($payload['issues']) || count($payload['issues']) < 1 || count($payload['issues']) > 50
        || strlen(fiqhJson($payload)) > 2*1024*1024) {
        throw new InvalidArgumentException('Invalid import envelope (schemaVersion 1, 1–50 issues, max 2 MiB)');
    }
    $seen = [];
    foreach ($payload['issues'] as $i=>$row) {
        if (!is_array($row) || array_diff(array_keys($row),['operation','expectedRevision','issue']) !== []
            || !is_array($row['issue'] ?? null) || !fiqhStableId($row['issue']['id'] ?? null)
            || !is_int($row['expectedRevision'] ?? null)
            || !in_array($row['operation'] ?? '',['create','update'],true)
            || ($row['operation']==='create' ? $row['expectedRevision']!==0 : $row['expectedRevision']<1)) {
            throw new InvalidArgumentException('Invalid import row '.($i+1));
        }
        foreach (['id','number','slug'] as $key) {
            $value=$row['issue'][$key] ?? null;
            if (!is_string($value) || isset($seen[$key][$value])) {
                throw new InvalidArgumentException('Missing or duplicate '.$key.' at row '.($i+1));
            }
            $seen[$key][$value]=true;
        }
    }
    return $payload['issues'];
}

function fiqhImportRun(PDO $db,array $payload,string $actor,?string $confirmation=null): array
{
    $rows=fiqhImportRows($payload);
    if (trim($actor)==='' || ($confirmation!==null && !preg_match('/^[a-f0-9]{64}$/D',$confirmation))) {
        throw new InvalidArgumentException('Invalid import actor or confirmation');
    }
    return fiqhTransaction($db,function() use($db,$rows,$payload,$actor,$confirmation): array {
        // The transaction serializes preview/commit, and binds confirmation to resulting content hashes.
        $db->exec('SAVEPOINT fiqh_import');
        $results=[];
        foreach ($rows as $i=>$row) {
            try {
                $body=$row['issue'];
                $saved=fiqhSaveDraftLocked($db,$body,$row['expectedRevision'],$actor);
                $latest=fiqhLatestRevision($db,$body['id']);
                $results[]=$saved+['contentHash'=>$latest['content_hash'],'completenessErrors'=>fiqhCompletenessErrors($body)];
            } catch (Exception $error) {
                throw new InvalidArgumentException('Import row '.($i+1).' rejected: '.$error->getMessage(),0,$error);
            }
        }
        $token=hash('sha256',fiqhJson(fiqhCanonical(['actor'=>$actor,'payload'=>$payload,'results'=>$results])));
        if ($confirmation===null) {
            $db->exec('ROLLBACK TO fiqh_import');
            $db->exec('RELEASE fiqh_import');
            return ['preview'=>true,'saved'=>false,'confirmation'=>$token,'results'=>$results];
        }
        if (!hash_equals($token,$confirmation)) throw new InvalidArgumentException('Import preview is stale or differs; preview again');
        $db->exec('RELEASE fiqh_import');
        return ['preview'=>false,'saved'=>true,'results'=>$results];
    });
}

/** Editor export only, containing canonical latest bodies and optimistic revision leases.
 * No private review records, approval status, or publish grants are included.
 */
function fiqhExportDrafts(PDO $db,int $limit=50,int $offset=0): array
{
    if ($limit<1 || $limit>50 || $offset<0) throw new InvalidArgumentException('Invalid export page');
    $q=$db->prepare('SELECT r.body,r.revision FROM fiqh_revisions r WHERE revision=(
        SELECT MAX(rr.revision) FROM fiqh_revisions rr WHERE rr.issue_id=r.issue_id)
        ORDER BY r.issue_id LIMIT :lim OFFSET :off');
    $q->bindValue(':lim',$limit,PDO::PARAM_INT);
    $q->bindValue(':off',$offset,PDO::PARAM_INT);
    $q->execute();
    return ['schemaVersion'=>1,'issues'=>array_map(fn($row)=>[
        'operation'=>'update','expectedRevision'=>(int)$row['revision'],
        'issue'=>json_decode($row['body'],true,64,JSON_THROW_ON_ERROR)],$q->fetchAll(PDO::FETCH_ASSOC))];
}
