@echo off

REM Call the mirror_backend.bat script
echo Deploying Backend...
call mirror_backend.bat
IF %ERRORLEVEL% NEQ 0 (
    echo Backend deployment failed. Exiting.
    exit /b 1
)

REM Call the mirror_nextjs.bat script
echo Deploying Next.js...
call mirror_nextjs.bat
IF %ERRORLEVEL% NEQ 0 (
    echo Next.js deployment failed. Exiting.
    exit /b 1
)

REM Call the mirror_react.bat script
echo Deploying React...
call mirror_react.bat
IF %ERRORLEVEL% NEQ 0 (
    echo React deployment failed. Exiting.
    exit /b 1
)

echo All deployments completed successfully.
