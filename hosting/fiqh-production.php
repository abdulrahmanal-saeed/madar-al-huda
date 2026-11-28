<?php
declare(strict_types=1);
require_once __DIR__.'/fiqh-stage.php';

/** The trusted main deployment is the only production caller. No HTTP route.
 * The supplied backup must be a verified private SQLite online snapshot.
 * No real issue, review grant, approval, or publication is created. */
function fiqhProductionMigrate(string $source,string $backup,array $seed):array
{
    $src=realpath($source); $bak=realpath($backup);
    if ($src===false||$bak===false||$src===$bak||!is_file($src)||!is_file($bak)
        ||is_link($source)||is_link($backup)
        ||!str_starts_with($bak,dirname($src).DIRECTORY_SEPARATOR.'backups'.DIRECTORY_SEPARATOR))
        throw new InvalidArgumentException('Private deployment backup required');
    $before=fiqhStageConnection($bak);
    fiqhStageIntegrity($before);
    $before=null;
    $db=fiqhStageConnection($src);
    return fiqhTransaction($db,function() use($db,$seed):array {
        fiqhStageIntegrity($db);
        $exists=(bool)$db->query("SELECT 1 FROM sqlite_master WHERE name='fiqh_migrations'")->fetchColumn();
        $versions=$exists?array_map('intval',$db->query('SELECT version FROM fiqh_migrations ORDER BY version')->fetchAll(PDO::FETCH_COLUMN)):[];
        if ($versions===[1,2,3,4]||$versions===[1,2,3,4,5]) {
            $upgraded=$versions===[1,2,3,4];
            if ($upgraded) {
                $legacy=fiqhStageLegacyDigest($db);
                fiqhDirectMigration($db,true);
                if (!hash_equals($legacy,fiqhStageLegacyDigest($db))) throw new RuntimeException('Legacy data changed');
                fiqhStageIntegrity($db);
            }
            $versions=[1,2,3,4,5];
            $enabled=$db->query("SELECT body FROM fiqh_settings WHERE key='public_enabled'")->fetchColumn()==='true';
            return ['status'=>$upgraded?'upgraded':'already_migrated','schemaVersions'=>$versions,'counts'=>fiqhStageCounts($db),'publicEnabled'=>$enabled];
        }
        if ($exists||$db->query("SELECT 1 FROM sqlite_master WHERE substr(name,1,5)='fiqh_' LIMIT 1")->fetchColumn())
            throw new RuntimeException('Unexpected existing fiqh schema; manual reconciliation required');
        $legacy=fiqhStageLegacyDigest($db);
        fiqhMigration($db,$seed,true);
        fiqhMetadataMigration($db,true);
        fiqhReviewMigration($db,true);
        fiqhPermissionMigration($db,true);
        fiqhDirectMigration($db,true);
        $counts=fiqhStageCounts($db);
        if ($counts!==['categories'=>11,'sources'=>17,'introductions'=>8,'issues'=>0,'revisions'=>0,
            'review_profiles'=>0,'publish_grants'=>0,'review_events'=>0,'published'=>0]
            ||!hash_equals($legacy,fiqhStageLegacyDigest($db)))
            throw new RuntimeException('Unexpected seed counts or legacy data changed');
        // The new empty feed may be authoritative only when there are no
        // existing published legacy issues. Never hide previously published material.
        $raw=$db->query('SELECT published FROM library WHERE id=1')->fetchColumn();
        $published=is_string($raw)?json_decode($raw,true,64,JSON_THROW_ON_ERROR):null;
        $legacyFiqh=$published['library']['fiqh'] ?? [];
        $enable=is_array($legacyFiqh)&&$legacyFiqh===[];
        $db->prepare('INSERT INTO fiqh_settings(key,body) VALUES (?,?)')->execute(['public_enabled',$enable?'true':'false']);
        fiqhStageIntegrity($db);
        return ['status'=>'migrated','schemaVersions'=>[1,2,3,4,5],'counts'=>$counts,
            'legacyPreserved'=>true,'publicEnabled'=>$enable,'legacyPublicationRetained'=>!$enable];
    });
}

if (PHP_SAPI==='cli'&&realpath($_SERVER['SCRIPT_FILENAME'] ?? '')===__FILE__) {
    try {
        if ($argc!==3) throw new InvalidArgumentException('Source and private backup required');
        $seed=json_decode(file_get_contents(__DIR__.'/../docs/content/fiqh/seed.json'),true,64,JSON_THROW_ON_ERROR);
        echo json_encode(fiqhProductionMigrate($argv[1],$argv[2],$seed),JSON_THROW_ON_ERROR|JSON_PRETTY_PRINT)."\n";
    } catch (Throwable $error) {
        fwrite(STDERR,"Fiqh production migration failed; no automatic database restore. Check private backup and logs.\n");
        exit(1);
    }
}
