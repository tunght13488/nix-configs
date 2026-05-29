<?php

$zipFile = 'test.zip';
$password = 'testpassword';

$files = [
    'foo.txt' => 'foo',
    'bar.txt' => 'bar',
];

if (file_exists($zipFile)) {
    unlink($zipFile);
}

$zip = new ZipArchive();
if ($zip->open($zipFile, ZipArchive::CREATE) !== true) {
    die("Failed to create $zipFile\n");
}

$zip->setPassword($password);

foreach ($files as $name => $content) {
    $zip->addFromString($name, $content);
    $zip->setEncryptionName($name, ZipArchive::EM_AES_256);
}

$zip->close();

echo "Created $zipFile with password protection.\n";

// Test: open and read the zip file
echo "\nTesting zip read...\n";

$zip2 = new ZipArchive();
if ($zip2->open($zipFile) !== true) {
    die("Failed to open $zipFile\n");
}

$zip2->setPassword($password);

$pass = true;
foreach ($files as $name => $expected) {
    $content = $zip2->getFromName($name);
    if ($content === false) {
        echo "FAIL: could not read $name\n";
        $pass = false;
    } elseif ($content !== $expected) {
        echo "FAIL: $name => expected '$expected', got '$content'\n";
        $pass = false;
    } else {
        echo "OK: $name => '$content'\n";
    }
}

$zip2->close();

echo $pass ? "\nAll tests passed.\n" : "\nSome tests failed.\n";

// Test: verify unzip output for AES-256 incompatibility
echo "\nTesting unzip output...\n";

$unzipOutput = shell_exec("unzip -P " . escapeshellarg($password) . " " . escapeshellarg($zipFile) . " 2>&1");
echo $unzipOutput;

$pass2 = true;
foreach (array_keys($files) as $name) {
    if (!preg_match('/skipping:\s+' . preg_quote($name, '/') . '.*need PK compat/i', $unzipOutput)) {
        echo "FAIL: expected incompatibility message for $name\n";
        $pass2 = false;
    } else {
        echo "OK: $name reported as incompatible (AES-256 not supported by unzip)\n";
    }
}

echo $pass2 ? "\nUnzip tests passed.\n" : "\nUnzip tests failed.\n";
