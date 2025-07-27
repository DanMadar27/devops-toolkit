@echo off
setlocal enabledelayedexpansion

:: Enable fail-fast (exit immediately if any command fails)
set "ERRORLEVEL=0"

:: Check if both source and destination repository URLs are provided
if "%~2"=="" (
    echo Usage: %0 ^<source_repo_url^> ^<destination_repo_url^>
    exit /b 1
)

:: Get source and destination repository URLs
set "SOURCE_REPO=%~1"
set "DESTINATION_REPO=%~2"

:: Extract repository names
for %%i in (%SOURCE_REPO%) do set "SOURCE_REPO_NAME=%%~ni"
for %%i in (%DESTINATION_REPO%) do set "DESTINATION_REPO_NAME=%%~ni"

echo Source repository name: %SOURCE_REPO_NAME%
echo Destination repository name: %DESTINATION_REPO_NAME%

:: Remove existing directories if they exist
if exist "%SOURCE_REPO_NAME%" (
    echo Removing existing source directory: %SOURCE_REPO_NAME%
    rmdir /s /q "%SOURCE_REPO_NAME%"
)

if exist "%DESTINATION_REPO_NAME%" (
    echo Removing existing destination directory: %DESTINATION_REPO_NAME%
    rmdir /s /q "%DESTINATION_REPO_NAME%"
)

:: Clone the source repository
echo Cloning source repository: %SOURCE_REPO%
git clone %SOURCE_REPO%

:: Check if the clone was successful
if !ERRORLEVEL! NEQ 0 (
    echo ERROR: Failed to clone source repository
    exit /b !ERRORLEVEL!
)

:: Clone the destination repository
echo Cloning destination repository: %DESTINATION_REPO%
git clone %DESTINATION_REPO%

:: Check if the clone was successful
if !ERRORLEVEL! NEQ 0 (
    echo ERROR: Failed to clone destination repository
    exit /b !ERRORLEVEL!
)

:: Copy content from source to destination (excluding .git directory)
echo Copying content from source to destination repository
for /r "%SOURCE_REPO_NAME%" %%f in (*) do (
    set "file=%%f"
    if /i not "!file!"=="!file:.git=!" (
        echo Skipping file: !file!
    ) else (
        set "dest_dir=%DESTINATION_REPO_NAME%\!file:~len(%SOURCE_REPO_NAME%)!\"
        if not exist "!dest_dir!" (
            echo Creating directory: !dest_dir!
            mkdir "!dest_dir!"
        )
        echo Copying file: !file!
        copy "%%f" "!dest_dir!"
    )
)

:: Get the last commit message from source repository
cd "%SOURCE_REPO_NAME%"
for /f "delims=" %%m in ('git log -1 --pretty^=format:"%%s"') do set "LAST_COMMIT_MESSAGE=%%m"
echo Last commit message from source repository: %LAST_COMMIT_MESSAGE%

:: Change to destination repository and commit changes
cd ..\%DESTINATION_REPO_NAME%

:: Add all changes
git add .

:: Check if there are any changes to commit
git diff --staged --quiet
if !ERRORLEVEL! EQU 0 (
    echo No changes to commit. Repositories might already be in sync.
) else (
    :: Commit the changes
    echo Committing changes to destination repository
    git commit -m "%LAST_COMMIT_MESSAGE%"
    
    :: Push changes to destination repository
    echo Pushing changes to destination repository
    git push origin
)

echo Repository copy completed successfully.
