@echo off

REM Save the current directory to return to it later
SET ORIGINAL_DIR=%CD%

REM Set the source and destination repositories
SET SOURCE_REPO=REPLACE_WITH_ACTUAL_SOURCE_REPO
SET DESTINATION_REPO=REPLACE_WITH_ACTUAL_REPO

REM Call the generic copy script (clone_copy_repo.bat in the same directory)
echo Calling clone_copy_repo.bat to clone copy %SOURCE_REPO% to %DESTINATION_REPO%
call clone_copy_repo.bat "%SOURCE_REPO%" "%DESTINATION_REPO%"

REM Return to the original directory
cd /d %ORIGINAL_DIR%

IF %ERRORLEVEL% NEQ 0 (
    echo Error: clone_copy_repo.bat failed. Exiting.
    exit /b 1
)

echo Deployed Backend successfully
