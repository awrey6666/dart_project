$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $root

$flutterBat = $null
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterCmd) {
  $flutterBat = $flutterCmd.Source
} elseif (Test-Path 'C:\tools\flutter\bin\flutter.bat') {
  $flutterBat = 'C:\tools\flutter\bin\flutter.bat'
}
if (-not $flutterBat) {
  Write-Host 'Flutter was not found. Install it and add it to PATH:'
  Write-Host 'https://docs.flutter.dev/get-started/install'
  exit 1
}
$flutterRoot = (Resolve-Path (Join-Path (Split-Path -Parent $flutterBat) '..')).Path

$devkit = 'C:\tools\w64devkit'
$gpp = Join-Path $devkit 'bin\g++.exe'
function Test-CompilerReady {
  if (-not (Test-Path -LiteralPath $gpp)) { return $false }
  $version = (& $gpp -dumpversion).Trim()
  return $version -eq '14.2.0'
}
if (-not (Test-CompilerReady)) {
  $archive = Join-Path $env:TEMP 'w64devkit-x64-2.1.0.exe'
  if (-not (Test-Path -LiteralPath $archive) -or (Get-Item -LiteralPath $archive).Length -lt 50MB) {
    Write-Host 'Downloading the compiler...'
    & curl.exe -L --fail --retry 3 -o $archive 'https://github.com/skeeto/w64devkit/releases/download/v2.1.0/w64devkit-x64-2.1.0.exe'
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  }
  if (Test-Path -LiteralPath $devkit) {
    Remove-Item -LiteralPath $devkit -Recurse -Force
  }
  New-Item -ItemType Directory -Force -Path 'C:\tools' | Out-Null
  Write-Host 'Unpacking the compiler...'
  & $archive '-y' '-oC:\tools'
  $deadline = (Get-Date).AddMinutes(2)
  while (-not (Test-CompilerReady) -and (Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 2
  }
  if (-not (Test-CompilerReady)) {
    Write-Host 'Could not unpack the compiler to C:\tools\w64devkit'
    exit 1
  }
}

$env:PATH = (Join-Path $devkit 'bin') + ';' + $env:PATH
$cmakeCmd = Get-Command cmake -ErrorAction SilentlyContinue
if (-not $cmakeCmd) {
  Write-Host 'CMake was not found.'
  exit 1
}
$cmake = $cmakeCmd.Source

& $flutterBat pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$work = $root
if ($root.Contains(' ')) {
  $work = 'C:\tools\usoum-src'
  $readyLink = $false
  if (Test-Path -LiteralPath $work) {
    $link = Get-Item -LiteralPath $work -Force
    $targets = @($link.Target | ForEach-Object { "$_".TrimEnd('\') })
    if (($link.Attributes -band [IO.FileAttributes]::ReparsePoint) -and ($targets -contains $root)) {
      $readyLink = $true
    } else {
      Write-Host 'C:\tools\usoum-src already exists and is not the project link.'
      exit 1
    }
  }
  if (-not $readyLink) {
    & cmd.exe /c "mklink /J `"$work`" `"$root`""
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  }
}

$ephemeral = Join-Path $work 'windows\flutter\ephemeral'
New-Item -ItemType Directory -Force -Path $ephemeral | Out-Null
$flutterCmake = $flutterRoot.Replace('\', '/')
$projectCmake = $work.Replace('\', '/')
$packageConfig = (Join-Path $work '.dart_tool\package_config.json').Replace('\', '/')
$lines = @(
  '# Generated for the MinGW build. Do not commit.',
  ('file(TO_CMAKE_PATH "' + $flutterCmake + '" FLUTTER_ROOT)'),
  ('file(TO_CMAKE_PATH "' + $projectCmake + '" PROJECT_DIR)'),
  '',
  'set(FLUTTER_VERSION "1.0.0" PARENT_SCOPE)',
  'set(FLUTTER_VERSION_MAJOR 1 PARENT_SCOPE)',
  'set(FLUTTER_VERSION_MINOR 0 PARENT_SCOPE)',
  'set(FLUTTER_VERSION_PATCH 0 PARENT_SCOPE)',
  'set(FLUTTER_VERSION_BUILD 1 PARENT_SCOPE)',
  '',
  'list(APPEND FLUTTER_TOOL_ENVIRONMENT',
  ('  "FLUTTER_ROOT=' + $flutterCmake + '"'),
  ('  "PROJECT_DIR=' + $projectCmake + '"'),
  '  "DART_OBFUSCATION=false"',
  '  "TRACK_WIDGET_CREATION=true"',
  '  "TREE_SHAKE_ICONS=false"',
  ('  "PACKAGE_CONFIG=' + $packageConfig + '"'),
  ')'
)
$utf8 = New-Object System.Text.UTF8Encoding $false
$configPath = Join-Path $ephemeral 'generated_config.cmake'
[System.IO.File]::WriteAllText($configPath, ($lines -join "`r`n") + "`r`n", $utf8)

$env:CMAKE_SH = 'CMAKE_SH-NOTFOUND'
$build = Join-Path $work 'build\mingw'
$precache = Join-Path $work 'windows\mingw-precache.cmake'
& $cmake -C $precache -S (Join-Path $work 'windows') -B $build -G 'MinGW Makefiles' -DCMAKE_BUILD_TYPE=Debug -DFLUTTER_TARGET_PLATFORM=windows-x64
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $cmake --build $build
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $cmake --build $build --target install
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$exe = Join-Path $build 'runner\dart_project.exe'
if (-not (Test-Path -LiteralPath $exe)) {
  Write-Host 'The program file was not built.'
  exit 1
}
Write-Host "EXE=$exe"
