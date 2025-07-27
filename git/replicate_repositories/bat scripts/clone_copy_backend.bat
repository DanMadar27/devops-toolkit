@echo off
setlocal enabledelayedexpansion

:: Enable fail-fast (exit immediately if any command fails)
set "ERRORLEVEL=0"

::  Set the source and destination repositories
set "SOURCE_REPO=REPLACE_WITH_ACTUAL_SOURCE_REPO"
set "DESTINATION_REPO=REPLACE_WITH_ACTUAL_REPO"

:: Call the generic copy script (clone_copy_repo.bat in the same directory)
echo Calling clone_copy_repo.bat to clone copy %SOURCE_REPO% to %DESTINATION_REPO%
call clone_copy_repo.bat "%SOURCE_REPO%" "%DESTINATION_REPO%"

:: Check if any command failed
if !ERRORLEVEL! NEQ 0 (
    echo ERROR: Command failed with exit code !ERRORLEVEL!
    exit /b !ERRORLEVEL!
)

echo Deployed Backend successfully
