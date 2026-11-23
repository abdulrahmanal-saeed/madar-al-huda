<?php
declare(strict_types=1);

// Run: php hosting/tests/apk_signature_test.php
require __DIR__ . '/../admin/apk-signature.php';

function lengthPrefixed(string $value): string
{
    return pack('V', strlen($value)) . $value;
}

function signerBlockValue(string $certificate): string
{
    $signedData = lengthPrefixed('') . lengthPrefixed(lengthPrefixed($certificate)) . lengthPrefixed('');
    $signer = lengthPrefixed($signedData) . lengthPrefixed('') . lengthPrefixed('public-key');
    return lengthPrefixed(lengthPrefixed($signer));
}

/** Builds a minimal file laid out like a signed APK: entries, signing block, directory, end record. */
function fakeApk(array $schemes, bool $withBlock = true): string
{
    $entries = "PK\x03\x04" . str_repeat("\0", 60);
    $block = '';
    if ($withBlock) {
        $pairs = '';
        foreach ($schemes as $id => $value) {
            $pairs .= pack('P', 4 + strlen($value)) . pack('V', $id) . $value;
        }
        $size = strlen($pairs) + 24;
        $block = pack('P', $size) . $pairs . pack('P', $size) . 'APK Sig Block 42';
    }
    $directory = "PK\x01\x02" . str_repeat("\0", 42);
    $end = "PK\x05\x06" . pack('vvvvVVv', 0, 0, 1, 1, strlen($directory), strlen($entries) + strlen($block), 0);
    $path = tempnam(sys_get_temp_dir(), 'apk');
    file_put_contents($path, $entries . $block . $directory . $end);
    return $path;
}

$failures = 0;
function check(string $name, bool $condition): void
{
    global $failures;
    echo ($condition ? 'ok   ' : 'FAIL ') . $name . PHP_EOL;
    if (!$condition) {
        $failures++;
    }
}

$v2Cert = 'v2-certificate-der';
$v3Cert = 'v3-certificate-der';

$v2 = fakeApk([APK_SIG_V2 => signerBlockValue($v2Cert)]);
check('reads the v2 signer certificate', apkSignerDigests($v2) === [hash('sha256', $v2Cert)]);

$both = fakeApk([APK_SIG_V2 => signerBlockValue($v2Cert), APK_SIG_V3 => signerBlockValue($v3Cert)]);
check('prefers the v3 signer certificate', apkSignerDigests($both) === [hash('sha256', $v3Cert)]);

$unsigned = fakeApk([], false);
check('returns nothing without a signing block', apkSignerDigests($unsigned) === []);

$broken = fakeApk([APK_SIG_V2 => substr(signerBlockValue($v2Cert), 0, 10)]);
check('returns nothing for a truncated signer', apkSignerDigests($broken) === []);

check('an unpinned channel accepts any signer', apkMatchesChannelSigner($v2, 'preview'));
check('a pinned channel refuses another key', !apkMatchesChannelSigner($v2, 'dev'));

foreach ([$v2, $both, $unsigned, $broken] as $file) {
    unlink($file);
}

if ($failures > 0) {
    fwrite(STDERR, "$failures check(s) failed" . PHP_EOL);
    exit(1);
}
echo 'All APK signature checks passed.' . PHP_EOL;
