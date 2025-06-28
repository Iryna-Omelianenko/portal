@echo off
setlocal enabledelayedexpansion

REM === Configuration ===
set OUTPUT_DIR=publish
set FINAL_DIR=docs
set BASE_HREF=/portal/

REM === Generate version timestamp ===
for /f "tokens=1-3 delims=/- " %%a in ("%date%") do (
    set DD=%%a
    set MM=%%b
    set YYYY=%%c
)
set HH=%time:~0,2%
set MN=%time:~3,2%
set SS=%time:~6,2%
set HH=!HH: =0!
set VERSION_TAG=%YYYY%%MM%%DD%-%HH%%MN%%SS%
set COMMIT_MESSAGE=Publish to GitHub Pages on %VERSION_TAG%

echo --- Step 1: Building project in Release mode ---
dotnet build -c Release
if errorlevel 1 (
    echo ❌ Build failed. Script aborted.
    exit /b 1
)

echo --- Step 2: Publishing project ---
dotnet publish -c Release -o %OUTPUT_DIR% /p:BlazorEnableCompression=false /p:BaseHref=%BASE_HREF%
if errorlevel 1 (
    echo ❌ Publish failed. Script aborted.
    exit /b 1
)

echo --- Step 3: Cleaning previous %FINAL_DIR% folder ---
rd /s /q %FINAL_DIR%
mkdir %FINAL_DIR%

echo --- Step 4: Copying published files to %FINAL_DIR% ---
xcopy /E /I /Y %OUTPUT_DIR%\wwwroot\* %FINAL_DIR%\

echo --- Step 5: Updating  <base href="/"> in index.html ---
powershell -Command "(Get-Content %FINAL_DIR%\index.html) -replace '<base href=\"/\" />', '<base href=\"%BASE_HREF%\" />' | Set-Content %FINAL_DIR%\index.html"

echo --- Step 6: Appending ?v=%VERSION_TAG% to CSS and JS references ---
powershell -Command "(Get-Content %FINAL_DIR%\index.html) -replace 'css/bootstrap/bootstrap.min.css', 'css/bootstrap/bootstrap.min.css?v=%VERSION_TAG%' -replace 'css/app.css', 'css/app.css?v=%VERSION_TAG%' -replace 'Irisha.styles.css', 'Irisha.styles.css?v=%VERSION_TAG%' -replace '_framework/blazor.webassembly.js', '_framework/blazor.webassembly.js?v=%VERSION_TAG%' | Set-Content %FINAL_DIR%\index.html"


echo --- Step 7: Creating .nojekyll ---
type nul > %FINAL_DIR%\.nojekyll

echo --- Step 8: Git commit and push ---
git add %FINAL_DIR%
git commit -m "%COMMIT_MESSAGE%"
git push

echo --- ✅ Done: Site published to GitHub Pages ---
endlocal
pause
