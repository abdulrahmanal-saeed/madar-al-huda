<?php
declare(strict_types=1);
require __DIR__.'/../fiqh-stage.php';
function fstCheck(bool $ok,string $message):void { if(!$ok) throw new RuntimeException($message); }
$root=sys_get_temp_dir().'/madar-fiqh-stage-'.bin2hex(random_bytes(8));
mkdir($root,0700);
try {
    $source=$root.'/source.sqlite3';
    $db=fiqhStageConnection($source);
    $db->exec('PRAGMA journal_mode=WAL');
    $db->exec('CREATE TABLE library(id INTEGER PRIMARY KEY,draft TEXT,revision INTEGER,published TEXT)');
    $db->exec('CREATE TABLE publications(revision INTEGER PRIMARY KEY,body TEXT)');
    $db->exec('CREATE TABLE users(id INTEGER PRIMARY KEY,username TEXT,role TEXT,disabled INTEGER)');
    $db->exec("INSERT INTO library VALUES(1,'synthetic draft',7,'synthetic published')");
    $db->exec("INSERT INTO publications VALUES(7,'synthetic published')");
    $db->exec("INSERT INTO users VALUES(1,'synthetic','owner',0)");
    $seed=json_decode(file_get_contents(__DIR__.'/../../docs/content/fiqh/seed.json'),true,64,JSON_THROW_ON_ERROR);
    $report=fiqhStageRehearsal($source,$root.'/rehearsal',$seed);
    fstCheck($report['status']==='passed'&&$report['schemaVersions']===[1,2,3,4],'rehearsal');
    fstCheck($report['counts']['issues']===0&&$report['counts']['publish_grants']===0&&!$report['publicEnabled'],'no content or grants');
    fstCheck(!$db->query("SELECT 1 FROM sqlite_master WHERE name='fiqh_migrations'")->fetchColumn(),'source unchanged');
    fstCheck($db->query('SELECT revision FROM library')->fetchColumn()===7,'original revision');
    $before=fiqhStageConnection($root.'/rehearsal/before.sqlite3');
    fstCheck(!$before->query("SELECT 1 FROM sqlite_master WHERE name='fiqh_migrations'")->fetchColumn(),'backup unmigrated');
    $before=null;
    $stage=fiqhStageConnection($root.'/rehearsal/staging.sqlite3');
    fstCheck(fiqhStageLegacyDigest($stage)===fiqhStageLegacyDigest($db),'legacy unchanged');
    $stage=null;
    try { fiqhStageRehearsal($source,$root.'/rehearsal',$seed); throw new LogicException('Overwrite accepted'); }
    catch (InvalidArgumentException) {}
    $db=null;
    echo "Fiqh staging rehearsal checks passed\n";
} finally {
    $iterator=new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root,FilesystemIterator::SKIP_DOTS),RecursiveIteratorIterator::CHILD_FIRST);
    foreach ($iterator as $file) { if ($file->isDir()) rmdir($file->getPathname()); else unlink($file->getPathname()); }
    rmdir($root);
}
