<?php
declare(strict_types=1);

/*
 * Reads the signer certificates from an APK Signature Scheme v2/v3 block, so
 * an upload signed with a different key is refused before it reaches users.
 * Format: https://source.android.com/docs/security/features/apksigning/v2
 */

const APK_SIG_V2 = 0x7109871a;
const APK_SIG_V3 = 0xf05368c0;

/** Signing certificate SHA-256 expected for each release channel. */
const APK_CHANNEL_SIGNERS = [
    // Same pin as .github/workflows/dev-release.yml.
    'dev' => '6c7046d0f47791452da955c39b1710addd2fa042373c29782e692a08042f3ee3',
    // Preview builds are signed by the CI debug key, which is not fixed yet.
    'preview' => null,
];

/** Offset of the ZIP central directory, or null when the file is not a ZIP. */
function apkCentralDirectory($handle, int $size): ?int
{
    $length = min($size, 65557);
    if (fseek($handle, $size - $length) !== 0) {
        return null;
    }
    $tail = fread($handle, $length);
    if ($tail === false) {
        return null;
    }
    for ($offset = strlen($tail) - 22; $offset >= 0; $offset--) {
        if (substr($tail, $offset, 4) !== "PK\x05\x06") {
            continue;
        }
        $end = unpack('Vdirectory/vcomment', substr($tail, $offset + 16, 6));
        $directory = $end['directory'];
        if ($offset + 22 + $end['comment'] === strlen($tail) &&
            $directory >= 24 && $directory < $size - $length + $offset) {
            return $directory;
        }
    }
    return null;
}

/** Reads a little-endian uint32 length-prefixed slice from $data at $offset. */
function apkSlice(string $data, int &$offset): string
{
    if ($offset + 4 > strlen($data)) {
        throw new UnexpectedValueException('Truncated APK signing block');
    }
    $length = unpack('V', substr($data, $offset, 4))[1];
    $offset += 4;
    if ($length > strlen($data) - $offset) {
        throw new UnexpectedValueException('Truncated APK signing block');
    }
    $slice = substr($data, $offset, $length);
    $offset += $length;
    return $slice;
}

/**
 * SHA-256 (lower-case hex) of each signer's first certificate. Uses the v3
 * block when present, otherwise v2. Returns [] when no supported block exists.
 *
 * @return list<string>
 */
function apkSignerDigests(string $file): array
{
    $size = filesize($file);
    $handle = fopen($file, 'rb');
    if ($size === false || $handle === false) {
        return [];
    }
    try {
        $directory = apkCentralDirectory($handle, $size);
        if ($directory === null || fseek($handle, $directory - 24) !== 0) {
            return [];
        }
        $footer = fread($handle, 24);
        if ($footer === false || strlen($footer) !== 24 ||
            substr($footer, 8) !== 'APK Sig Block 42') {
            return [];
        }
        $blockSize = unpack('P', substr($footer, 0, 8))[1];
        // The block, including both size fields, must fit before the directory.
        if ($blockSize < 24 || $blockSize > 64 * 1024 * 1024 || $blockSize + 8 > $directory) {
            return [];
        }
        $start = $directory - $blockSize - 8;
        if (fseek($handle, $start) !== 0) {
            return [];
        }
        $block = fread($handle, $blockSize + 8);
        if ($block === false || strlen($block) !== $blockSize + 8 ||
            unpack('P', substr($block, 0, 8))[1] !== $blockSize) {
            return [];
        }
    } finally {
        fclose($handle);
    }

    $pairs = [];
    $offset = 8;
    $end = strlen($block) - 24;
    while ($offset + 12 <= $end) {
        $length = unpack('P', substr($block, $offset, 8))[1];
        if ($length < 4 || $length > $end - $offset - 8) {
            return [];
        }
        $id = unpack('V', substr($block, $offset + 8, 4))[1];
        $pairs[$id] = substr($block, $offset + 12, $length - 4);
        $offset += 8 + $length;
    }
    $scheme = $pairs[APK_SIG_V3] ?? $pairs[APK_SIG_V2] ?? null;
    if ($scheme === null) {
        return [];
    }

    try {
        $digests = [];
        $position = 0;
        $signers = apkSlice($scheme, $position);
        $cursor = 0;
        while ($cursor < strlen($signers)) {
            $signer = apkSlice($signers, $cursor);
            $inner = 0;
            $signed = apkSlice($signer, $inner);
            $field = 0;
            apkSlice($signed, $field); // digests
            $certificates = apkSlice($signed, $field);
            $certOffset = 0;
            $first = apkSlice($certificates, $certOffset);
            if ($first === '') {
                return [];
            }
            $digests[] = hash('sha256', $first);
        }
        return $digests;
    } catch (UnexpectedValueException) {
        return [];
    }
}

/** Whether the APK is signed by the key pinned for $channel (or no pin). */
function apkMatchesChannelSigner(string $file, string $channel): bool
{
    $expected = APK_CHANNEL_SIGNERS[$channel] ?? null;
    if ($expected === null) {
        return true;
    }
    return in_array($expected, apkSignerDigests($file), true);
}
