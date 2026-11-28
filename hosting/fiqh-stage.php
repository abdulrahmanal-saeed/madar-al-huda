<?php
declare(strict_types=1);

require_once __DIR__.'/admin/fiqh-review.php';

/** CLI-only staging rehearsal. Never migrates the source database. */
function fiqhStageConnection(string $path): PDO
{
    $db=new PDO('sqlite:'.$path,null,null,[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
    $db->exec('PRAGMA busy_timeout=5000');
    return $db;
}

function fiqhStageIntegrity(PDO $db):void
{
    if ($db->query('PRAGMA integrity_check')->fetchAll(PDO::FETCH_COLUMN)!==['ok']
        || $db->query('PRAGMA foreign_key_check')->fetchAll()!==[]) {
        throw new RuntimeException('Database integrity verification failed');
    }
}

/** Hash critical existing tables without exporting records or credentials. */
function fiqhStageLegacyDigest(PDO $db):string
{
    $hash=hash_init('sha256');
    foreach (['library'=>'id','publications'=>'revision','users'=>'id'] as $table=>$key) {
        $q=$db->query("SELECT * FROM $table ORDER BY $key");
        hash_update($hash,$table."\0");
        while (($row=$q->fetch(PDO::FETCH_ASSOC))!==false) hash_update($hash,serialize($row)."\0");
    }
    return hash_final($hash);
}

function fiqhStageMigrate(PDO $db,array $seed):void
{
    fiqhMigration($db,$seed);
    fiqhMetadataMigration($db);
    fiqhReviewMigration($db);
    fiqhPermissionMigration($db);
}

function fiqhStageCounts(PDO $db):array
{
    $counts=[];
    foreach (['categories','sources','introductions','issues','revisions','review_profiles','publish_grants','review_events','published'] as $table)
        $counts[$table]=(int)$db->query('SELECT COUNT(*) FROM fiqh_'.$table)->fetchColumn();
    return $counts;
}

function fiqhStageRehearsal(string $source,string $destination,array $seed):array
{
    if (!class_exists(SQLite3::class)||!method_exists(SQLite3::class,'backup'))
        throw new RuntimeException('PHP SQLite3 online backup support required');
    $original=realpath($source);
    $parent=realpath(dirname($destination));
    $name=basename($destination);
    if ($original===false||!is_file($original)||is_link($source)||$parent===false||!is_dir($parent)
        ||!preg_match('/^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,79}$/D',$name)
        ||preg_match('~/(public_html|htdocs|wwwroot|www)(/|$)~i',$parent))
        throw new InvalidArgumentException('Choose an existing database and a private, new staging directory');
    $target=$parent.DIRECTORY_SEPARATOR.$name;
    if (file_exists($target)||is_link($target)) throw new InvalidArgumentException('Staging destination already exists');
    $mask=umask(0077);
    try {
        if (!mkdir($target,0700)) throw new RuntimeException('Could not create private staging directory');
        $backup=$target.'/before.sqlite3';
        $staging=$target.'/staging.sqlite3';
        // SQLite online backup, source handle opened READONLY. Never copy an active WAL file.
        $from=new SQLite3($original,SQLITE3_OPEN_READONLY);
        $from->enableExceptions(true);
        $from->busyTimeout(5000);
        try {
            $to=new SQLite3($backup,SQLITE3_OPEN_READWRITE|SQLITE3_OPEN_CREATE);
            $to->enableExceptions(true);
            try {
                if (!$from->backup($to)) throw new RuntimeException('Online backup failed');
            } finally { $to->close(); }
        } finally { $from->close(); }
        if (!chmod($backup,0600)) throw new RuntimeException('Backup permissions failed');
        $before=fiqhStageConnection($backup);
        fiqhStageIntegrity($before);
        $legacy=fiqhStageLegacyDigest($before);
        if ($before->query("SELECT 1 FROM sqlite_master WHERE name LIKE 'fiqh_%' LIMIT 1")->fetchColumn())
            throw new RuntimeException('This first-release rehearsal requires an unmigrated source');
        $before=null;
        // The snapshot is closed and immutable; copy only that offline snapshot.
        if (!copy($backup,$staging)||!chmod($staging,0600)) throw new RuntimeException('Staging copy failed');
        $db=fiqhStageConnection($staging);
        fiqhStageMigrate($db,$seed);
        fiqhStageIntegrity($db);
        $counts=fiqhStageCounts($db);
        $expected=['categories'=>11,'sources'=>17,'introductions'=>8,'issues'=>0,'revisions'=>0,
            'review_profiles'=>0,'publish_grants'=>0,'review_events'=>0,'published'=>0];
        if ($counts!==$expected||!hash_equals($legacy,fiqhStageLegacyDigest($db)))
            throw new RuntimeException('Unexpected initial data or changed legacy records');
        $versions=array_map('intval',$db->query('SELECT version FROM fiqh_migrations ORDER BY version')->fetchAll(PDO::FETCH_COLUMN));
        if ($versions!==[1,2,3,4]||$db->query("SELECT 1 FROM fiqh_settings WHERE key='public_enabled'")->fetchColumn())
            throw new RuntimeException('Unexpected migration state or public activation');
        // Repeat on staging to verify idempotence.
        fiqhStageMigrate($db,$seed);
        fiqhStageIntegrity($db);
        if (fiqhStageCounts($db)!==$counts||!hash_equals($legacy,fiqhStageLegacyDigest($db)))
            throw new RuntimeException('Repeated migration changed data');
        $db=null;
        $report=['status'=>'passed','mode'=>'staging_only','schemaVersions'=>$versions,'counts'=>$counts,
            'legacyPreserved'=>true,'integrityVerified'=>true,'idempotent'=>true,'publicEnabled'=>false,
            'sourceMigrated'=>false,'backupSha256'=>hash_file('sha256',$backup),
            'stagingSha256'=>hash_file('sha256',$staging)];
        $reportPath=$target.'/report.json';
        if (file_put_contents($reportPath,json_encode($report,JSON_THROW_ON_ERROR|JSON_PRETTY_PRINT)."\n",LOCK_EX)===false
            ||!chmod($reportPath,0600)) throw new RuntimeException('Could not write private report');
        return $report;
    } finally { umask($mask); }
}

if (PHP_SAPI==='cli'&&realpath($_SERVER['SCRIPT_FILENAME'] ?? '')===__FILE__) {
    try {
        if ($argc!==3) throw new InvalidArgumentException('Usage: php hosting/fiqh-stage.php SOURCE_SQLITE NEW_PRIVATE_DIRECTORY');
        $seed=json_decode(file_get_contents(__DIR__.'/../docs/content/fiqh/seed.json'),true,64,JSON_THROW_ON_ERROR);
        echo json_encode(fiqhStageRehearsal($argv[1],$argv[2],$seed),JSON_THROW_ON_ERROR|JSON_PRETTY_PRINT)."\n";
    } catch (Throwable $error) {
        // No database records, SQL or paths printed to shared logs.
        fwrite(STDERR,"Fiqh staging rehearsal failed. Inspect private files locally; never upload database copies.\n");
        exit(1);
    }
}
