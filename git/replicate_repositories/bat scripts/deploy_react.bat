@echo off

REM Save the current directory to return to it later
SET ORIGINAL_DIR=%CD%

REM Set the source and destination repositories from the command line arguments
SET SOURCE_REPO=REPLACE_WITH_ACTUAL_SOURCE_REPO
SET DESTINATION_REPO=REPLACE_WITH_ACTUAL_REPO

REM Call the generic mirror script (mirror_repo.bat in the same directory)
echo Calling mirror_repo.bat to mirror %SOURCE_REPO% to %DESTINATION_REPO%
call mirror_repo.bat "%SOURCE_REPO%" "%DESTINATION_REPO%"

REM Return to the original directory
cd /d %ORIGINAL_DIR%

IF %ERRORLEVEL% NEQ 0 (
    echo Error: mirror_repo.bat failed. Exiting.
    exit /b 1
)

echo Deployed React successfully
