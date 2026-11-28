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
