@echo off

echo Cloning and copying backend repository...
python clone_copy_repo.py ^<source_repo_url^> ^<destination_repo_url^>

if %ERRORLEVEL% EQU 0 (
    echo Backend repository cloned and copied successfully.
) else (
    echo Error: Failed to clone and copy backend repository.
    exit /b %ERRORLEVEL%
)