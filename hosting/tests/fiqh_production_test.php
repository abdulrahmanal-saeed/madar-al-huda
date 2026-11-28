<?php
declare(strict_types=1);
require __DIR__.'/../fiqh-production.php';
function fpCheck(bool $ok,string $message):void { if (!$ok) throw new RuntimeException($message); }
$root=sys_get_temp_dir().'/madar-fiqh-prod-'.bin2hex(random_bytes(8));
mkdir($root,0700);
mkdir($root.'/backups',0700);
try {
    $seed=json_decode(file_get_contents(__DIR__.'/../../docs/content/fiqh/seed.json'),true,64,JSON_THROW_ON_ERROR);
    foreach ([false,true] as $hasLegacy) {
        $name=$hasLegacy?'legacy':'empty';
        $source=$root.'/'.$name.'.sqlite3';
        $backup=$root.'/backups/'.$name.'.sqlite3';
        $db=fiqhStageConnection($source);
        $db->exec('CREATE TABLE library(id INTEGER PRIMARY KEY,draft TEXT,revision INTEGER,published TEXT)');
        $db->exec('CREATE TABLE publications(revision INTEGER PRIMARY KEY,body TEXT)');
        $db->exec('CREATE TABLE users(id INTEGER PRIMARY KEY,username TEXT,role TEXT,disabled INTEGER)');
        $published=fiqhJson(['library'=>['fiqh'=>$hasLegacy?[['id'=>'synthetic']]:[]]]);
        $db->prepare('INSERT INTO library VALUES (1,?,7,?)')->execute([$published,$published]);
        $db->prepare('INSERT INTO publications VALUES (7,?)')->execute([$published]);
        $db->exec("INSERT INTO users VALUES(1,'synthetic','owner',0)");
        $digest=fiqhStageLegacyDigest($db);
        $db->exec('VACUUM INTO '.$db->quote($backup));
        $db=null;
        $bad=$seed; $bad['introductions']=[];
        try { fiqhProductionMigrate($source,$backup,$bad); throw new LogicException('Bad counts accepted'); }
        catch (RuntimeException) {}
        $db=fiqhStageConnection($source);
        fpCheck(!$db->query("SELECT 1 FROM sqlite_master WHERE name='fiqh_migrations'")->fetchColumn(),'all versions rolled back');
        $db=null;
        $result=fiqhProductionMigrate($source,$backup,$seed);
        fpCheck($result['status']==='migrated'&&$result['schemaVersions']===[1,2,3,4,5],'migration');
        fpCheck($result['publicEnabled']===!$hasLegacy,'legacy display protection');
        fpCheck($result['counts']['issues']===0&&$result['counts']['publish_grants']===0,'no content or grants');
        $db=fiqhStageConnection($source);
        fpCheck(fiqhStageLegacyDigest($db)===$digest,'legacy preserved');
        $db=null;
        fpCheck(fiqhProductionMigrate($source,$backup,$seed)['status']==='already_migrated','repeat safe');
    }
    echo "Fiqh production migration checks passed\n";
} finally {
    $iterator=new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root,FilesystemIterator::SKIP_DOTS),RecursiveIteratorIterator::CHILD_FIRST);
    foreach ($iterator as $file) { if ($file->isDir()) rmdir($file->getPathname()); else unlink($file->getPathname()); }
    rmdir($root);
}
