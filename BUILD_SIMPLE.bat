@echo off
setlocal EnableExtensions
cd /d "%~dp0"
set "ROOT=%CD%"
set "WEB=%ROOT%\vbms-web-ui"
set "LOG=%ROOT%\BUILD_SIMPLE.log"
echo Building original-style Virtual BMS (5 BLE, series totals)
if not exist "%WEB%\package.json" goto :missing_web
where npm.cmd >nul 2>&1
if errorlevel 1 goto :missing_npm
cd /d "%WEB%"
call npm.cmd ci > "%LOG%" 2>&1
if errorlevel 1 goto :failed
call npm.cmd run build >> "%LOG%" 2>&1
if errorlevel 1 goto :failed
for %%F in (index.html runtime.js main.js app.js.gz vendor.js.gz app.css.gz vendor.css.gz) do (
  if not exist "%WEB%\dist\%%F" (
    echo Missing dist\%%F >> "%LOG%"
    goto :failed
  )
)
cd /d "%ROOT%"
if not exist "fs" mkdir "fs"
if exist "fs\dist" rmdir /s /q "fs\dist"
for %%F in (index.html runtime.js main.js app.js app.js.gz vendor.js vendor.js.gz app.css app.css.gz vendor.css vendor.css.gz) do (
  if exist "fs\%%F" del /q "fs\%%F"
)
xcopy "%WEB%\dist\*" "fs\" /E /I /Y >> "%LOG%" 2>&1
if errorlevel 1 goto :failed
echo WEB OK: files copied to fs root.
echo Now run: C:\mos\mos.exe build --platform esp32
echo Inspect build\fw.zip before flashing. Existing device settings should be backed up.
pause
exit /b 0
:missing_web
echo ERROR: vbms-web-ui not found
goto :failed
:missing_npm
echo ERROR: npm.cmd not found; install Node.js first
goto :failed
:failed
echo Build failed. See "%LOG%"
if exist "%LOG%" powershell -NoProfile -Command "Get-Content -LiteralPath '%LOG%' -Tail 30"
pause
exit /b 1
