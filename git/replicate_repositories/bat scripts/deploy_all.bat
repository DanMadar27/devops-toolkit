@echo off

REM Call the deploy_backend.bat script
echo Deploying Backend...
call deploy_backend.bat
IF %ERRORLEVEL% NEQ 0 (
    echo Backend deployment failed. Exiting.
    exit /b 1
)

REM Call the deploy_nextjs.bat script
echo Deploying Next.js...
call deploy_nextjs.bat
IF %ERRORLEVEL% NEQ 0 (
    echo Next.js deployment failed. Exiting.
    exit /b 1
)

REM Call the deploy_react.bat script
echo Deploying React...
call deploy_react.bat
IF %ERRORLEVEL% NEQ 0 (
    echo React deployment failed. Exiting.
    exit /b 1
)

echo All deployments completed successfully.
