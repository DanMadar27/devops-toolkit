@echo off

REM Save the current directory to return to it later
SET ORIGINAL_DIR=%CD%

REM Check if both source and destination repository URLs are provided
IF "%~2"=="" (
    echo Usage: %0 ^<source_repo_url^> ^<destination_repo_url^>
    exit /b 1
)

REM Get source and destination repository URLs
SET SOURCE_REPO=%~1
SET DESTINATION_REPO=%~2

REM Extract the repository name by removing everything before the last "/"
REM This assumes the repo URL is in the form of "https://github.com/user/repo.git"
FOR /F "tokens=*" %%A IN ("%SOURCE_REPO%") DO SET REPO_NAME=%%~nxA
REM Remove the ".git" extension from the repository name
SET REPO_NAME=%REPO_NAME:.git=%

REM Remove the existing repository directory if it exists
echo Repository name is: %REPO_NAME%
IF EXIST "%REPO_NAME%.git" (
    echo Removing existing directory: %REPO_NAME%.git
    rmdir /s /q "%REPO_NAME%.git" REM Delete the directory and its contents
)

REM Clone the source repository as a mirror (with token for private repos)
echo Cloning source repository: %SOURCE_REPO%
git clone --bare %SOURCE_REPO%
IF %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to clone the source repository. Exiting.
    exit /b 1
)

REM Change to the repository directory (this will be the cloned repository)
cd "%REPO_NAME%.git" || (
    echo Error: Failed to change directory to %REPO_NAME%.git. Exiting.
    exit /b 1
)

REM Setting up the destination repository remote (make sure it exists in the destination organization)
echo Setting up destination repository: %DESTINATION_REPO%
git remote set-url --push origin %DESTINATION_REPO%
IF %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to set destination repository URL. Exiting.
    exit /b 1
)

REM Push the mirrored repository to the destination org (with token for private repos)
echo Pushing mirror to destination repository
git push --mirror %DESTINATION_REPO%
IF %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to push the mirrored repository. Exiting.
    exit /b 1
)

REM Optionally, verify the remote repository after pushing
git remote -v
IF %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to verify the remote repository. Exiting.
    exit /b 1
)

REM Return to the original directory
cd /d %ORIGINAL_DIR%

echo Repository mirror completed successfully.
