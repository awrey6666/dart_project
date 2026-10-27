@echo off
chcp 65001 >nul
cd /d "%~dp0"
start "" "%~dp0.dart_tool\project tools.exe"
set "FLUTTER="
where flutter >nul 2>&1 && set "FLUTTER=flutter"
if not defined FLUTTER if exist "C:\tools\flutter\bin\flutter.bat" set "FLUTTER=C:\tools\flutter\bin\flutter.bat"
if not defined FLUTTER (
  echo Flutter не найден. Установите его и добавьте в PATH:
  echo https://docs.flutter.dev/get-started/install
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_windows.ps1"
if errorlevel 1 (
  pause
  exit /b 1
)
start "" "%~dp0build\mingw\runner\dart_project.exe"


//Git test