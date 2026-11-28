<?php
declare(strict_types=1);
require_once __DIR__.'/fiqh-metadata.php';
require_once __DIR__.'/fiqh-import.php';

/** These are the only structured fiqh MCP tools. Review and publication are intentionally absent. */
function fiqhAgentTools(): array
{
    $schema=static fn(array $props,array $required):array=>[
        'type'=>'object','properties'=>$props ?: new stdClass(),'required'=>$required,'additionalProperties'=>false];
    $read=['readOnlyHint'=>true];
    $write=['readOnlyHint'=>false,'destructiveHint'=>false,'idempotentHint'=>false];
    $id=['type'=>'string','pattern'=>'^[a-z0-9][a-z0-9_-]{0,95}$'];
    $paging=['limit'=>['type'=>'integer','minimum'=>1,'maximum'=>50],
        'offset'=>['type'=>'integer','minimum'=>0]];
    $payload=['type'=>'object','required'=>['schemaVersion','issues'],'additionalProperties'=>false,'properties'=>[
        'schemaVersion'=>['type'=>'integer','enum'=>[1]],
        'issues'=>['type'=>'array','minItems'=>1,'maxItems'=>50,'items'=>[
            'type'=>'object','required'=>['operation','expectedRevision','issue'],'additionalProperties'=>false,'properties'=>[
                'operation'=>['type'=>'string','enum'=>['create','update']],
                'expectedRevision'=>['type'=>'integer','minimum'=>0],
                'issue'=>['type'=>'object','description'=>'Canonical bilingual draft issue. Read fiqh_import_contract. No review or publication fields.'],
            ],
        ]],
    ]];
    return [
        ['name'=>'fiqh_import_contract','description'=>'Read the structured fiqh draft contract and staging availability.',
            'inputSchema'=>$schema([],[]),'annotations'=>$read],
        ['name'=>'fiqh_list_categories','description'=>'List existing comparative fiqh category IDs and draft metadata.',
            'inputSchema'=>$schema([],[]),'annotations'=>$read],
        ['name'=>'fiqh_list_sources','description'=>'List source IDs and bibliographic metadata; placeholders are not verified sources.',
            'inputSchema'=>$schema([],[]),'annotations'=>$read],
        ['name'=>'fiqh_get_source','description'=>'Read a source, missing fields and current edit token.','inputSchema'=>$schema(['id'=>$id],['id']),'annotations'=>$read],
        ['name'=>'fiqh_create_source','description'=>'Create a draft bibliographic source after explicit owner approval. Never publishes.','inputSchema'=>$schema(['record'=>['type'=>'object'],'ownerConfirmed'=>['type'=>'boolean','enum'=>[true]]],['record','ownerConfirmed']),'annotations'=>$write],
        ['name'=>'fiqh_update_source','description'=>'Replace a draft source using its exact edit token after owner approval; refresh related drafts.','inputSchema'=>$schema(['record'=>['type'=>'object'],'expectedToken'=>['type'=>'string','pattern'=>'^[a-f0-9]{64}'description'=>'List up to 50 latest draft issues, optionally filtered by category. Never a public feed.',
            'inputSchema'=>$schema($paging+['categoryId'=>$id],[]),'annotations'=>$read],
        ['name'=>'fiqh_get_draft','description'=>'Get a single latest draft body and its revision lease, without private review notes.',
            'inputSchema'=>$schema(['id'=>$id],['id']),'annotations'=>$read],
        ['name'=>'fiqh_preview_import','description'=>'Validate and preview a canonical batch. Writes are rolled back. Show the owner the actual proposed content and results before asking for approval.',
            'inputSchema'=>$schema(['payload'=>$payload],['payload']),'annotations'=>$read],
        ['name'=>'fiqh_commit_import','description'=>'Save exactly the previewed batch into DRAFT only. Obtain explicit owner approval for this batch first. No approval, review, or publication capability.',
            'inputSchema'=>$schema(['payload'=>$payload,'confirmation'=>['type'=>'string','pattern'=>'^[a-f0-9]{64}$'],
                'ownerConfirmed'=>['type'=>'boolean','enum'=>[true]]],['payload','confirmation','ownerConfirmed']),'annotations'=>$write],
        ['name'=>'fiqh_export_drafts','description'=>'Export up to 50 canonical draft records including revision leases; never exports approvals.',
            'inputSchema'=>$schema($paging,[]),'annotations'=>$read],
    ];
}
function fiqhAgentAvailable(PDO $db): bool
{
    return (bool)$db->query("SELECT 1 FROM sqlite_master WHERE type='table' AND name='fiqh_migrations'")->fetchColumn()
        && (bool)$db->query('SELECT 1 FROM fiqh_migrations WHERE version=2')->fetchColumn();
}
function fiqhAgentContract(PDO $db): array
{
    return ['available'=>fiqhAgentAvailable($db),'schemaVersion'=>1,'maxIssues'=>50,
        'schools'=>FIQH_SCHOOLS,'evidenceTypes'=>FIQH_EVIDENCE_TYPES,
        'bilingualShape'=>['ar'=>'Arabic text','en'=>'English text'],
        'requiredDraftFields'=>['id','number','slug','categoryId','title'],
        'optionalDraftFields'=>['subcategoryId','relatedCategoryIds','relatedIssueIds','summary','introduction','scope',
            'keywords','displayOrder','difficulty','positions','evidence','agreements','disagreements','reasonsForDifferences',
            'scholarlySummary','practicalExamples','importantNotes','terminology'],
        'positionFields'=>['ruling','explanation','reasoning','conditions','exceptions','alternativeOpinions',
            'classification','evidenceIds','sourceReferences'],
        'citationShape'=>['sourceId'=>'Existing source ID','locator'=>['ar'=>'Verified Arabic locator','en'=>'Verified English locator']],
        'evidenceFields'=>['id','type','text','reference','explanation','grading','gradingAttribution','sourceIds','madhhabs','quranLocator','hadithLocator','url'],
        'quranLocator'=>['surah'=>'Integer 1–114','firstAyah'=>'Positive integer','lastAyah'=>'Inclusive final ayah within surah'],
        'hadithLocator'=>['collectionSourceId'=>'Existing ID also in evidence sourceIds','number'=>'Bilingual edition-specific identifier','book'=>'Bilingual book','chapter'=>'Bilingual chapter','editionLocator'=>'Bilingual verified edition and location'],
        'evidenceLocatorRules'=>'Quran and hadith locators required for publication, not draft creation. Hadith needs editionLocator and number or chapter; no guessed numbers. Optional URL must be HTTPS. Verify text accuracy and grading before publication.',
        'sourceTypes'=>['book','institution','article','collection','other','quran','hadith_collection'],
        'sourceFields'=>['id','title','author','editor','madhhab','sourceType','publisher','edition','publicationYear','volume','pages','chapter','section','url','license','editorialNotes','status','documentationStatus'],
        'sourceRules'=>'Full records; title/author/editor are AR/EN objects. status placeholder or draft; documentationStatus pending or documented (bibliographic only). Quran has no human author or madhhab and no required edition/license. Book and hadith collection require author, publisher, edition and license. Do not invent metadata. Update requires get_source editToken. Bulk rows use expectedToken null for create, exact token for update. Related latest drafts refresh without changing issue IDs or published revisions.',
        'reviewBlocks'=>'Use applicable boolean plus bilingual entries or bilingual justification.',
        'restrictions'=>'Drafts only. Do not invent evidence, locators or source editions. No approval, publication or ranking. Create revision=0; update uses exact latest revision. Preview and owner approval required.'];
}
function fiqhAgentCall(PDO $db,array $key,string $tool,array $args): array
{
    $keyId=filter_var($key['id'] ?? null,FILTER_VALIDATE_INT,['options'=>['min_range'=>1]]);
    if ($keyId===false) throw new AgentError('Authenticated MCP key required');
    $allowed=array_column(fiqhAgentTools(),'name');
    if (!in_array($tool,$allowed,true)) throw new AgentError('Unknown structured fiqh tool');
    $schema=fiqhAgentTools()[array_search($tool,$allowed,true)]['inputSchema'];
    if (array_diff(array_keys($args),array_keys((array)$schema['properties']))!==[]
        || array_diff($schema['required'],array_keys($args))!==[]) {
        throw new AgentError('Unexpected or missing arguments');
    }
    if ($tool==='fiqh_import_contract') return fiqhAgentContract($db);
    if (!fiqhAgentAvailable($db)) throw new AgentError('Fiqh staging migration required; no changes made');
    $actor='mcp-key:'.$keyId;
    try {
        $limit=$args['limit'] ?? 50; $offset=$args['offset'] ?? 0;
        if (!is_int($limit)||$limit<1||$limit>50||!is_int($offset)||$offset<0)
            throw new InvalidArgumentException('Invalid pagination');
        switch($tool) {
            case 'fiqh_list_categories':
            case 'fiqh_list_sources':
                $kind=$tool==='fiqh_list_categories'?'category':'source';
                return ['records'=>array_column(fiqhListMetadata($db,$kind),'record')];
            case 'fiqh_get_source':
                if (!is_string($args['id'])) throw new InvalidArgumentException('Invalid ID');
                return fiqhGetSource($db,$args['id']);
            case 'fiqh_create_source':
            case 'fiqh_update_source':
                if ($args['ownerConfirmed']!==true||!is_array($args['record'])) throw new InvalidArgumentException('Owner confirmation and source object required');
                $token=$tool==='fiqh_update_source'?$args['expectedToken']:null;
                if ($tool==='fiqh_update_source'&&!is_string($token)) throw new InvalidArgumentException('Edit token required');
                return fiqhBulkSources($db,[['record'=>$args['record'],'expectedToken'=>$token]],$actor);
            case 'fiqh_bulk_upsert_sources':
                if (!is_array($args['rows'])||!is_bool($args['preview'])||!is_bool($args['ownerConfirmed'])||(!$args['preview']&&!$args['ownerConfirmed']))
                    throw new InvalidArgumentException('Preview flag and explicit owner confirmation required');
                return fiqhBulkSources($db,$args['rows'],$actor,$args['preview']);
            case 'fiqh_list_drafts':
                $category=$args['categoryId'] ?? null;
                if ($category!==null&&!fiqhStableId($category)) throw new InvalidArgumentException('Invalid category');
                return ['drafts'=>fiqhListDrafts($db,$category,$limit,$offset)];
            case 'fiqh_get_draft':
                if (!fiqhStableId($args['id'])) throw new InvalidArgumentException('Invalid ID');
                $row=fiqhLatestRevision($db,$args['id']);
                if (!$row) throw new InvalidArgumentException('Draft not found');
                $body=json_decode($row['body'],true,64,JSON_THROW_ON_ERROR);
                return ['issue'=>$body,'revision'=>(int)$row['revision'],'completenessErrors'=>fiqhDraftValidationErrors($row)];
            case 'fiqh_preview_import':
            case 'fiqh_commit_import':
                if (!is_array($args['payload'])) throw new InvalidArgumentException('Payload object required');
                $confirmation=null;
                if ($tool==='fiqh_commit_import') {
                    if ($args['ownerConfirmed']!==true||!is_string($args['confirmation'])||$args['confirmation']==='')
                        throw new InvalidArgumentException('Explicit owner confirmation and preview token required');
                    $confirmation=$args['confirmation'];
                }
                return fiqhImportRun($db,$args['payload'],$actor,$confirmation)+['published'=>false];
            case 'fiqh_export_drafts':
                return fiqhExportDrafts($db,$limit,$offset);
        }
    } catch (InvalidArgumentException|RuntimeException $error) {
        throw new AgentError($error->getMessage());
    }
    throw new AgentError('Unknown structured fiqh tool');
}
],'ownerConfirmed'=>['type'=>'boolean','enum'=>[true]]],['record','expectedToken','ownerConfirmed']),'annotations'=>$write],
        ['name'=>'fiqh_bulk_upsert_sources','description'=>'Preview or save 1–50 full draft source records with explicit create/update tokens. No publication.','inputSchema'=>$schema(['rows'=>['type'=>'array','minItems'=>1,'maxItems'=>50,'items'=>['type'=>'object','required'=>['record','expectedToken'],'additionalProperties'=>false,'properties'=>['record'=>['type'=>'object'],'expectedToken'=>['type'=>['string','null']]]]],'preview'=>['type'=>'boolean'],'ownerConfirmed'=>['type'=>'boolean']],['rows','preview','ownerConfirmed']),'annotations'=>$write],
        ['name'=>'fiqh_list_drafts','description'=>'List up to 50 latest draft issues, optionally filtered by category. Never a public feed.',
            'inputSchema'=>$schema($paging+['categoryId'=>$id],[]),'annotations'=>$read],
        ['name'=>'fiqh_get_draft','description'=>'Get a single latest draft body and its revision lease, without private review notes.',
            'inputSchema'=>$schema(['id'=>$id],['id']),'annotations'=>$read],
        ['name'=>'fiqh_preview_import','description'=>'Validate and preview a canonical batch. Writes are rolled back. Show the owner the actual proposed content and results before asking for approval.',
            'inputSchema'=>$schema(['payload'=>$payload],['payload']),'annotations'=>$read],
        ['name'=>'fiqh_commit_import','description'=>'Save exactly the previewed batch into DRAFT only. Obtain explicit owner approval for this batch first. No approval, review, or publication capability.',
            'inputSchema'=>$schema(['payload'=>$payload,'confirmation'=>['type'=>'string','pattern'=>'^[a-f0-9]{64}$'],
                'ownerConfirmed'=>['type'=>'boolean','enum'=>[true]]],['payload','confirmation','ownerConfirmed']),'annotations'=>$write],
        ['name'=>'fiqh_export_drafts','description'=>'Export up to 50 canonical draft records including revision leases; never exports approvals.',
            'inputSchema'=>$schema($paging,[]),'annotations'=>$read],
    ];
}
function fiqhAgentAvailable(PDO $db): bool
{
    return (bool)$db->query("SELECT 1 FROM sqlite_master WHERE type='table' AND name='fiqh_migrations'")->fetchColumn()
        && (bool)$db->query('SELECT 1 FROM fiqh_migrations WHERE version=2')->fetchColumn();
}
function fiqhAgentContract(PDO $db): array
{
    return ['available'=>fiqhAgentAvailable($db),'schemaVersion'=>1,'maxIssues'=>50,
        'schools'=>FIQH_SCHOOLS,'evidenceTypes'=>FIQH_EVIDENCE_TYPES,
        'bilingualShape'=>['ar'=>'Arabic text','en'=>'English text'],
        'requiredDraftFields'=>['id','number','slug','categoryId','title'],
        'optionalDraftFields'=>['subcategoryId','relatedCategoryIds','relatedIssueIds','summary','introduction','scope',
            'keywords','displayOrder','difficulty','positions','evidence','agreements','disagreements','reasonsForDifferences',
            'scholarlySummary','practicalExamples','importantNotes','terminology'],
        'positionFields'=>['ruling','explanation','reasoning','conditions','exceptions','alternativeOpinions',
            'classification','evidenceIds','sourceReferences'],
        'citationShape'=>['sourceId'=>'Existing source ID','locator'=>['ar'=>'Verified Arabic locator','en'=>'Verified English locator']],
        'evidenceFields'=>['id','type','text','reference','explanation','grading','gradingAttribution','sourceIds','madhhabs','quranLocator','hadithLocator','url'],
        'quranLocator'=>['surah'=>'Integer 1–114','firstAyah'=>'Positive integer','lastAyah'=>'Inclusive final ayah within surah'],
        'hadithLocator'=>['collectionSourceId'=>'Existing ID also in evidence sourceIds','number'=>'Bilingual edition-specific identifier','book'=>'Bilingual book','chapter'=>'Bilingual chapter','editionLocator'=>'Bilingual verified edition and location'],
        'evidenceLocatorRules'=>'Quran and hadith locators required for publication, not draft creation. Hadith needs editionLocator and number or chapter; no guessed numbers. Optional URL must be HTTPS. Verify text accuracy and grading before publication.',
        'reviewBlocks'=>'Use applicable boolean plus bilingual entries or bilingual justification.',
        'restrictions'=>'Drafts only. Do not invent evidence, locators or source editions. No approval, publication or ranking. Create revision=0; update uses exact latest revision. Preview and owner approval required.'];
}
function fiqhAgentCall(PDO $db,array $key,string $tool,array $args): array
{
    $keyId=filter_var($key['id'] ?? null,FILTER_VALIDATE_INT,['options'=>['min_range'=>1]]);
    if ($keyId===false) throw new AgentError('Authenticated MCP key required');
    $allowed=array_column(fiqhAgentTools(),'name');
    if (!in_array($tool,$allowed,true)) throw new AgentError('Unknown structured fiqh tool');
    $schema=fiqhAgentTools()[array_search($tool,$allowed,true)]['inputSchema'];
    if (array_diff(array_keys($args),array_keys((array)$schema['properties']))!==[]
        || array_diff($schema['required'],array_keys($args))!==[]) {
        throw new AgentError('Unexpected or missing arguments');
    }
    if ($tool==='fiqh_import_contract') return fiqhAgentContract($db);
    if (!fiqhAgentAvailable($db)) throw new AgentError('Fiqh staging migration required; no changes made');
    $actor='mcp-key:'.$keyId;
    try {
        $limit=$args['limit'] ?? 50; $offset=$args['offset'] ?? 0;
        if (!is_int($limit)||$limit<1||$limit>50||!is_int($offset)||$offset<0)
            throw new InvalidArgumentException('Invalid pagination');
        switch($tool) {
            case 'fiqh_list_categories':
            case 'fiqh_list_sources':
                $kind=$tool==='fiqh_list_categories'?'category':'source';
                return ['records'=>array_column(fiqhListMetadata($db,$kind),'record')];
            case 'fiqh_list_drafts':
                $category=$args['categoryId'] ?? null;
                if ($category!==null&&!fiqhStableId($category)) throw new InvalidArgumentException('Invalid category');
                return ['drafts'=>fiqhListDrafts($db,$category,$limit,$offset)];
            case 'fiqh_get_draft':
                if (!fiqhStableId($args['id'])) throw new InvalidArgumentException('Invalid ID');
                $row=fiqhLatestRevision($db,$args['id']);
                if (!$row) throw new InvalidArgumentException('Draft not found');
                $body=json_decode($row['body'],true,64,JSON_THROW_ON_ERROR);
                return ['issue'=>$body,'revision'=>(int)$row['revision'],'completenessErrors'=>fiqhCompletenessErrors($body)];
            case 'fiqh_preview_import':
            case 'fiqh_commit_import':
                if (!is_array($args['payload'])) throw new InvalidArgumentException('Payload object required');
                $confirmation=null;
                if ($tool==='fiqh_commit_import') {
                    if ($args['ownerConfirmed']!==true||!is_string($args['confirmation'])||$args['confirmation']==='')
                        throw new InvalidArgumentException('Explicit owner confirmation and preview token required');
                    $confirmation=$args['confirmation'];
                }
                return fiqhImportRun($db,$args['payload'],$actor,$confirmation)+['published'=>false];
            case 'fiqh_export_drafts':
                return fiqhExportDrafts($db,$limit,$offset);
        }
    } catch (InvalidArgumentException $error) {
        throw new AgentError($error->getMessage());
    }
    throw new AgentError('Unknown structured fiqh tool');
}
