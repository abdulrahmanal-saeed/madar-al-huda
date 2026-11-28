<?php
declare(strict_types=1);

/** FIQH-DEV-02 foundation: pure draft helpers; not a publishing endpoint. */
const FIQH_SCHOOLS = ['hanafi', 'maliki', 'shafii', 'hanbali'];
const FIQH_EVIDENCE_TYPES = ['quran', 'hadith', 'consensus', 'companion', 'analogy', 'principle', 'other'];
const FIQH_LIFECYCLE = ['draft', 'ready_for_review', 'under_review', 'changes_requested', 'approved', 'published', 'archived'];

function fiqhBilingual(mixed $value): bool
{
    return is_array($value) && is_string($value['ar'] ?? null)
        && is_string($value['en'] ?? null)
        && trim($value['ar']) !== '' && trim($value['en']) !== '';
}

function fiqhStableId(mixed $id): bool
{
    return is_string($id) && preg_match('/^[a-z0-9][a-z0-9_-]{0,95}$/D', $id) === 1;
}

/** Returns field paths; callers must reject errors before committing. */
function fiqhCategoryErrors(array $categories): array
{
    $errors = [];
    $parents = [];
    foreach ($categories as $i => $category) {
        if (!is_array($category) || !fiqhStableId($category['id'] ?? null)) {
            $errors[] = "categories.$i.id";
            continue;
        }
        $id = $category['id'];
        if (array_key_exists($id, $parents)) {
            $errors[] = "categories.$i.duplicate";
        }
        $parents[$id] = $category['parentId'] ?? null;
        if (!fiqhBilingual($category['title'] ?? null)) {
            $errors[] = "categories.$i.title";
        }
        if (!is_int($category['plannedIssueCount'] ?? null) || $category['plannedIssueCount'] < 0) {
            $errors[] = "categories.$i.plannedIssueCount";
        }
    }
    foreach ($parents as $id => $parent) {
        $seen = [$id => true];
        while ($parent !== null) {
            if (!is_string($parent) || !array_key_exists($parent, $parents) || isset($seen[$parent])) {
                $errors[] = "categories.$id.parentId";
                break;
            }
            $seen[$parent] = true;
            $parent = $parents[$parent];
        }
    }
    return $errors;
}

/** Completeness only. Never equate this with approval or permission to publish. */
function fiqhCompletenessErrors(array $issue): array
{
    $errors = [];
    foreach (['title', 'summary', 'introduction', 'scope', 'scholarlySummary'] as $field) {
        if (!fiqhBilingual($issue[$field] ?? null)) {
            $errors[] = $field;
        }
    }
    foreach (['id', 'slug', 'categoryId'] as $field) {
        if (!fiqhStableId($issue[$field] ?? null)) {
            $errors[] = $field;
        }
    }
    if (!is_string($issue['number'] ?? null) || preg_match('/^FIQH-[0-9]{3,}$/D', $issue['number']) !== 1) {
        $errors[] = 'number';
    }
    $evidence = $issue['evidence'] ?? null;
    $evidenceIds = [];
    if (!is_array($evidence) || $evidence === []) {
        $errors[] = 'evidence';
    } else {
        foreach ($evidence as $i => $entry) {
            if (!is_array($entry) || !fiqhStableId($entry['id'] ?? null)) {
                $errors[] = "evidence.$i.id";
                continue;
            }
            if (isset($evidenceIds[$entry['id']])) {
                $errors[] = "evidence.$i.duplicate";
            }
            $evidenceIds[$entry['id']] = true;
            if (!in_array($entry['type'] ?? null, FIQH_EVIDENCE_TYPES, true)
                || !fiqhBilingual($entry['text'] ?? null)
                || !fiqhBilingual($entry['explanation'] ?? null)
                || !fiqhBilingual($entry['reference'] ?? null)) {
                $errors[] = "evidence.$i.content";
            }
            if (!is_array($entry['sourceIds'] ?? null) || $entry['sourceIds'] === []) {
                $errors[] = "evidence.$i.sourceIds";
            }
            if (($entry['type'] ?? null) === 'hadith'
                && (!fiqhBilingual($entry['grading'] ?? null) || !fiqhBilingual($entry['gradingAttribution'] ?? null))) {
                $errors[] = "evidence.$i.grading";
            }
        }
    }
    $positions = $issue['positions'] ?? null;
    if (!is_array($positions)) {
        $positions = [];
    }
    if (array_diff(array_keys($positions), FIQH_SCHOOLS) !== []) {
        $errors[] = 'positions.unknownSchool';
    }
    foreach (FIQH_SCHOOLS as $school) {
        $position = $positions[$school] ?? null;
        if (!is_array($position)) {
            $errors[] = "positions.$school";
            continue;
        }
        foreach (['ruling', 'explanation', 'reasoning'] as $field) {
            if (!fiqhBilingual($position[$field] ?? null)) {
                $errors[] = "positions.$school.$field";
            }
        }
        $refs = $position['sourceReferences'] ?? null;
        if (!is_array($refs) || $refs === []) {
            $errors[] = "positions.$school.sourceReferences";
        } else {
            foreach ($refs as $i => $ref) {
                if (!is_array($ref) || !fiqhStableId($ref['sourceId'] ?? null)
                    || !fiqhBilingual($ref['locator'] ?? null)) {
                    $errors[] = "positions.$school.sourceReferences.$i";
                }
            }
        }
        $refs = $position['evidenceIds'] ?? null;
        if (!is_array($refs) || $refs === []) {
            $errors[] = "positions.$school.evidenceIds";
        } else {
            foreach ($refs as $ref) {
                if (!is_string($ref) || !isset($evidenceIds[$ref])) {
                    $errors[] = "positions.$school.evidenceIds";
                    break;
                }
            }
        }
    }
    foreach (['agreements', 'disagreements', 'reasonsForDifferences'] as $field) {
        $block = $issue[$field] ?? null;
        if (!is_array($block)) {
            $errors[] = $field;
            continue;
        }
        if (($block['applicable'] ?? null) === false) {
            if (!fiqhBilingual($block['justification'] ?? null)) {
                $errors[] = "$field.justification";
            }
        } elseif (($block['applicable'] ?? null) !== true
            || !is_array($block['entries'] ?? null) || $block['entries'] === []
            || array_filter($block['entries'], fn ($entry) => !fiqhBilingual($entry)) !== []) {
            $errors[] = "$field.entries";
        }
    }
    return array_values(array_unique($errors));
}


/** Structural validation is independent of completeness: blank optional draft
 * fields are allowed, but unknown keys, wrong types and nested approval data
 * are rejected at every write boundary. */
function fiqhShapeErrors(array $issue): array
{
    $errors=[];
    $object=static function(mixed $value,array $allowed,string $path) use (&$errors): bool {
        if (!is_array($value)||array_diff(array_keys($value),$allowed)!==[]) {
            $errors[]=$path.'.shape'; return false;
        }
        return true;
    };
    $text=static function(mixed $value,string $path) use (&$errors,$object): void {
        if (!$object($value,['ar','en'],$path)) return;
        foreach (['ar','en'] as $lang) {
            if (!is_string($value[$lang] ?? null)||strlen($value[$lang])>65536
                || preg_match('//u',$value[$lang])!==1) $errors[]=$path.'.'.$lang;
        }
    };
    $list=static function(mixed $value,string $path) use (&$errors): bool {
        if (!is_array($value)||!array_is_list($value)||count($value)>200) {
            $errors[]=$path.'.list'; return false;
        }
        return true;
    };
    $ids=static function(mixed $value,string $path) use (&$errors,$list): void {
        if (!$list($value,$path)) return;
        $seen=[];
        foreach ($value as $i=>$id) {
            if (!fiqhStableId($id)||isset($seen[$id])) $errors[]=$path.'.'.$i;
            else $seen[$id]=true;
        }
    };
    $texts=static function(mixed $value,string $path) use ($list,$text): void {
        if ($list($value,$path)) foreach ($value as $i=>$item) $text($item,$path.'.'.$i);
    };
    $allowed=['id','number','slug','categoryId','subcategoryId','relatedCategoryIds','relatedIssueIds',
        'title','summary','introduction','scope','keywords','displayOrder','difficulty','positions','evidence',
        'agreements','disagreements','reasonsForDifferences','scholarlySummary','practicalExamples','importantNotes','terminology'];
    $object($issue,$allowed,'issue');
    foreach (['title','summary','introduction','scope','scholarlySummary'] as $key)
        if (array_key_exists($key,$issue)) $text($issue[$key],$key);
    foreach (['relatedCategoryIds','relatedIssueIds'] as $key)
        if (array_key_exists($key,$issue)) $ids($issue[$key],$key);
    if (array_key_exists('subcategoryId',$issue)&&$issue['subcategoryId']!==null&&!fiqhStableId($issue['subcategoryId'])) $errors[]='subcategoryId';
    if (array_key_exists('displayOrder',$issue)&&(!is_int($issue['displayOrder'])||$issue['displayOrder']<0)) $errors[]='displayOrder';
    if (array_key_exists('difficulty',$issue)&&!in_array($issue['difficulty'],['','beginner','intermediate','advanced'],true)) $errors[]='difficulty';
    if (array_key_exists('keywords',$issue)&&$list($issue['keywords'],'keywords')) {
        foreach ($issue['keywords'] as $i=>$word) {
            if (is_string($word)) {
                if (strlen($word)>512||preg_match('//u',$word)!==1) $errors[]='keywords.'.$i;
            } else $text($word,'keywords.'.$i);
        }
    }
    if (array_key_exists('positions',$issue)&&$object($issue['positions'],FIQH_SCHOOLS,'positions')) {
        foreach ($issue['positions'] as $school=>$position) {
            $path='positions.'.$school;
            if (!$object($position,['ruling','explanation','reasoning','classification','conditions','exceptions','alternativeOpinions','evidenceIds','sourceReferences'],$path)) continue;
            foreach (['ruling','explanation','reasoning','classification'] as $key)
                if (array_key_exists($key,$position)) $text($position[$key],$path.'.'.$key);
            foreach (['conditions','exceptions','alternativeOpinions'] as $key)
                if (array_key_exists($key,$position)) $texts($position[$key],$path.'.'.$key);
            if (array_key_exists('evidenceIds',$position)) $ids($position['evidenceIds'],$path.'.evidenceIds');
            if (array_key_exists('sourceReferences',$position)&&$list($position['sourceReferences'],$path.'.sourceReferences')) {
                foreach ($position['sourceReferences'] as $i=>$ref) {
                    $rp=$path.'.sourceReferences.'.$i;
                    if (!$object($ref,['sourceId','locator'],$rp)) continue;
                    if (!fiqhStableId($ref['sourceId'] ?? null)) $errors[]=$rp.'.sourceId';
                    if (array_key_exists('locator',$ref)) $text($ref['locator'],$rp.'.locator');
                }
            }
        }
    }
    if (array_key_exists('evidence',$issue)&&$list($issue['evidence'],'evidence')) {
        $seen=[];
        foreach ($issue['evidence'] as $i=>$entry) {
            $path='evidence.'.$i;
            if (!$object($entry,['id','type','text','reference','explanation','grading','gradingAttribution','sourceIds','madhhabs'],$path)) continue;
            if (!fiqhStableId($entry['id'] ?? null)||isset($seen[$entry['id']])) $errors[]=$path.'.id';
            else $seen[$entry['id']]=true;
            if (array_key_exists('type',$entry)&&!in_array($entry['type'],FIQH_EVIDENCE_TYPES,true)) $errors[]=$path.'.type';
            foreach (['text','reference','explanation','grading','gradingAttribution'] as $key)
                if (array_key_exists($key,$entry)) $text($entry[$key],$path.'.'.$key);
            if (array_key_exists('sourceIds',$entry)) $ids($entry['sourceIds'],$path.'.sourceIds');
            if (array_key_exists('madhhabs',$entry)) {
                $ids($entry['madhhabs'],$path.'.madhhabs');
                if (is_array($entry['madhhabs'])) foreach ($entry['madhhabs'] as $school)
                    if (!in_array($school,FIQH_SCHOOLS,true)) $errors[]=$path.'.madhhabs';
            }
        }
    }
    foreach (['agreements','disagreements','reasonsForDifferences'] as $key) {
        if (!array_key_exists($key,$issue)||!$object($issue[$key],['applicable','entries','justification'],$key)) continue;
        $block=$issue[$key];
        if (array_key_exists('applicable',$block)&&!is_bool($block['applicable'])) $errors[]=$key.'.applicable';
        if (array_key_exists('entries',$block)) $texts($block['entries'],$key.'.entries');
        if (array_key_exists('justification',$block)) $text($block['justification'],$key.'.justification');
    }
    foreach (['practicalExamples','importantNotes','terminology'] as $key)
        if (array_key_exists($key,$issue)) $texts($issue[$key],$key);
    return array_values(array_unique($errors));
}
