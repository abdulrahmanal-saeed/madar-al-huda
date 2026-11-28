<?php
declare(strict_types=1);
require_once __DIR__.'/fiqh-review.php';

/** Explicit operator activation after staging, migration and legacy content review.
 * A missing setting never makes staging content public.
 */
function fiqhPublicEnabled(PDO $db): bool
{
    if (!$db->query("SELECT 1 FROM sqlite_master WHERE type='table' AND name='fiqh_migrations'")->fetchColumn()
        || !fiqhReviewReady($db)) return false;
    $q=$db->prepare("SELECT body FROM fiqh_settings WHERE key='public_enabled'");
    $q->execute();
    return $q->fetchColumn()==='true';
}

function fiqhPublicBi(mixed $value): array
{
    if (!is_array($value)) return ['ar'=>'','en'=>''];
    return ['ar'=>is_string($value['ar'] ?? null)?$value['ar']:'',
        'en'=>is_string($value['en'] ?? null)?$value['en']:''];
}

function fiqhPublicBiList(mixed $value): array
{
    if (!is_array($value)||!array_is_list($value)) return [];
    return array_map('fiqhPublicBi',array_values(array_filter($value,'is_array')));
}

function fiqhPublicIds(mixed $value): array
{
    return is_array($value)?array_values(array_filter($value,'fiqhStableId')):[];
}

function fiqhPublicBlock(mixed $value): array
{
    return ['applicable'=>($value['applicable'] ?? null)===true,
        'entries'=>fiqhPublicBiList($value['entries'] ?? []),
        'justification'=>fiqhPublicBi($value['justification'] ?? null)];
}

function fiqhPublicSource(array $source): array
{
    $result=['id'=>$source['id'],'title'=>fiqhPublicBi($source['title'] ?? null),
        'author'=>fiqhPublicBi($source['author'] ?? null)];
    foreach (['madhhab','sourceType','publisher','edition','publicationYear','volume','pages','chapter','section','license'] as $key) {
        if (is_string($source[$key] ?? null)||($key==='publicationYear'&&is_int($source[$key] ?? null))) $result[$key]=$source[$key];
    }
    $url=$source['url'] ?? null;
    if (is_string($url)&&filter_var($url,FILTER_VALIDATE_URL)&&parse_url($url,PHP_URL_SCHEME)==='https') $result['url']=$url;
    return $result;
}

/** Explicit nested allowlists: never copy arbitrary editorial JSON into public output. */
function fiqhPublicIssue(array $row): array
{
    $body=json_decode($row['body'],true,64,JSON_THROW_ON_ERROR);
    $snapshot=json_decode($row['source_snapshot'],true,64,JSON_THROW_ON_ERROR);
    $out=['id'=>$body['id'],'number'=>$body['number'],'slug'=>$body['slug'],
        'categoryId'=>$body['categoryId'],'revision'=>(int)$row['revision'],'status'=>'published',
        'publishedAt'=>(int)$row['published_at'],'displayOrder'=>is_int($body['displayOrder'] ?? null)?$body['displayOrder']:0];
    if (fiqhStableId($body['subcategoryId'] ?? null)) $out['subcategoryId']=$body['subcategoryId'];
    if (in_array($body['difficulty'] ?? null,['beginner','intermediate','advanced'],true)) $out['difficulty']=$body['difficulty'];
    foreach (['title','summary','introduction','scope','scholarlySummary'] as $key) $out[$key]=fiqhPublicBi($body[$key] ?? null);
    foreach (['relatedCategoryIds','relatedIssueIds'] as $key) $out[$key]=fiqhPublicIds($body[$key] ?? []);
    $out['keywords']=[];
    if (is_array($body['keywords'] ?? null)) {
        foreach ($body['keywords'] as $keyword) {
            if (is_string($keyword)) $out['keywords'][]=$keyword;
            elseif (is_array($keyword)) $out['keywords'][]=fiqhPublicBi($keyword);
        }
    }
    $out['positions']=[];
    foreach (FIQH_SCHOOLS as $school) {
        $p=$body['positions'][$school];
        $position=[];
        foreach (['ruling','explanation','reasoning','classification'] as $key) $position[$key]=fiqhPublicBi($p[$key] ?? null);
        foreach (['conditions','exceptions','alternativeOpinions'] as $key) $position[$key]=fiqhPublicBiList($p[$key] ?? []);
        $position['evidenceIds']=fiqhPublicIds($p['evidenceIds'] ?? []);
        $position['sourceReferences']=[];
        foreach ($p['sourceReferences'] as $ref) {
            $position['sourceReferences'][]=['sourceId'=>$ref['sourceId'],'locator'=>fiqhPublicBi($ref['locator'])];
        }
        $out['positions'][$school]=$position;
    }
    $out['evidence']=[];
    foreach ($body['evidence'] as $evidence) {
        $entry=['id'=>$evidence['id'],'type'=>$evidence['type'],'sourceIds'=>fiqhPublicIds($evidence['sourceIds'])];
        foreach (['text','reference','explanation','grading','gradingAttribution'] as $key) $entry[$key]=fiqhPublicBi($evidence[$key] ?? null);
        $entry['madhhabs']=array_values(array_intersect(FIQH_SCHOOLS,fiqhPublicIds($evidence['madhhabs'] ?? [])));
        if (fiqhQuranLocatorValid($evidence['quranLocator'] ?? null)) {
            $q=$evidence['quranLocator'];
            $entry['quranLocator']=['surah'=>$q['surah'],'firstAyah'=>$q['firstAyah'],'lastAyah'=>$q['lastAyah']];
        }
        if (fiqhHadithLocatorValid($evidence['hadithLocator'] ?? null)) {
            $h=$evidence['hadithLocator'];
            $entry['hadithLocator']=['collectionSourceId'=>$h['collectionSourceId']];
            foreach (['number','book','chapter','editionLocator'] as $key)
                $entry['hadithLocator'][$key]=fiqhPublicBi($h[$key] ?? null);
        }
        if (fiqhEvidenceUrlValid($evidence['url'] ?? null)) $entry['url']=$evidence['url'];
        $out['evidence'][]=$entry;
    }
    foreach (['agreements','disagreements','reasonsForDifferences'] as $key) $out[$key]=fiqhPublicBlock($body[$key]);
    foreach (['practicalExamples','importantNotes','terminology'] as $key) $out[$key]=fiqhPublicBiList($body[$key] ?? []);
    $sources=[];
    foreach (fiqhCollectSources($body) as $id) {
        if (isset($snapshot[$id])&&is_array($snapshot[$id])) $sources[$id]=fiqhPublicSource($snapshot[$id]);
    }
    $out['sources']=(object)$sources;
    return $out;
}

/** Read a single consistent database snapshot, never the latest draft. */
function fiqhPublicCatalog(PDO $db): array
{
    $db->exec('BEGIN');
    try {
        if (!fiqhPublicEnabled($db)) throw new RuntimeException('Public fiqh is disabled');
        $all=[];
        foreach ($db->query('SELECT body FROM fiqh_categories')->fetchAll(PDO::FETCH_COLUMN) as $raw) {
            $category=json_decode($raw,true,64,JSON_THROW_ON_ERROR);
            $all[$category['id']]=$category;
        }
        $visible=[];
        foreach ($all as $id=>$category) {
            $seen=[]; $cursor=$id;
            while ($cursor!==null&&isset($all[$cursor])&&!isset($seen[$cursor])&&($all[$cursor]['visible'] ?? false)===true) {
                $seen[$cursor]=true; $cursor=$all[$cursor]['parentId'] ?? null;
            }
            if ($cursor!==null) continue;
            $visible[$id]=['id'=>$id,'title'=>fiqhPublicBi($category['title']),
                'description'=>fiqhPublicBi($category['description'] ?? null),'parentId'=>$category['parentId'] ?? null,
                'icon'=>$category['icon'] ?? 'book','order'=>$category['order'] ?? 0];
        }
        $categories=array_values($visible);
        usort($categories,fn($a,$b)=>[$a['order'],$a['id']]<=>[$b['order'],$b['id']]);
        $issues=[];
        // Historical approved pointers and direct editorial publication pointers
        // must both match the actual immutable publication event and body hash.
        $sql="SELECT r.*,p.published_at FROM fiqh_published p
            JOIN fiqh_revisions r ON r.issue_id=p.issue_id AND r.revision=p.revision
            JOIN fiqh_review_events a ON a.id=p.approval_id AND a.issue_id=r.issue_id AND a.revision=r.revision
              AND a.content_hash=r.content_hash
            JOIN fiqh_review_events e ON e.id=(SELECT MAX(id) FROM fiqh_review_events
                WHERE issue_id=r.issue_id AND revision=r.revision)
              AND e.state='published' AND e.content_hash=r.content_hash AND e.actor_id=p.publisher_id
              AND ((a.state='approved' AND e.id>a.id) OR (a.state='published' AND e.id=a.id))";
        foreach ($db->query($sql)->fetchAll(PDO::FETCH_ASSOC) as $row) {
            if (!isset($visible[$row['category_id']])||($row['subcategory_id']!==null&&!isset($visible[$row['subcategory_id']]))) continue;
            if (fiqhReviewErrors($row)!==[]) continue;
            $issues[]=fiqhPublicIssue($row);
        }
        $issueIds=array_column($issues,'id');
        foreach ($issues as &$issue) {
            $issue['relatedIssueIds']=array_values(array_intersect($issue['relatedIssueIds'],$issueIds));
            $issue['relatedCategoryIds']=array_values(array_intersect($issue['relatedCategoryIds'],array_keys($visible)));
        }
        unset($issue);
        usort($issues,fn($a,$b)=>[$a['displayOrder'],$a['number']]<=>[$b['displayOrder'],$b['number']]);
        $raw=$db->query("SELECT body FROM fiqh_settings WHERE key='disclaimer'")->fetchColumn();
        $disclaimer=is_string($raw)?json_decode($raw,true,64,JSON_THROW_ON_ERROR):null;
        if (!fiqhBilingual($disclaimer)) throw new RuntimeException('Missing public disclaimer');
        $result=['schemaVersion'=>1,'kind'=>'published_fiqh','categories'=>$categories,'issues'=>$issues,'disclaimer'=>fiqhPublicBi($disclaimer)];
        $db->exec('COMMIT');
        return $result;
    } catch (Throwable $error) {
        $db->exec('ROLLBACK'); throw $error;
    }
}

function serveFiqhFeed(PDO $db): never
{
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-cache');
    header('X-Robots-Tag: noindex');
    $method=$_SERVER['REQUEST_METHOD'] ?? 'GET';
    if (!in_array($method,['GET','HEAD'],true)) {
        header('Allow: GET, HEAD'); http_response_code(405); exit;
    }
    if (!fiqhPublicEnabled($db)) {
        http_response_code(404); if ($method==='GET') echo '{"error":"fiqh_unavailable"}'; exit;
    }
    $body=fiqhJson(fiqhPublicCatalog($db));
    if (strlen($body)>4*1024*1024) {
        http_response_code(503); if ($method==='GET') echo '{"error":"fiqh_feed_too_large"}'; exit;
    }
    $etag='"'.hash('sha256',$body).'"';
    header('ETag: '.$etag);
    if (trim($_SERVER['HTTP_IF_NONE_MATCH'] ?? '')===$etag) { http_response_code(304); exit; }
    if ($method==='GET') echo $body;
    exit;
}
