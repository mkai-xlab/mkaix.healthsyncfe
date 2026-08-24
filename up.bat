@echo off
cd /d "%~dp0"

set ENVFILE=..\env\fe.env
if not exist "%ENVFILE%" (
    echo [ERROR] Missing %ENVFILE%
    echo         It must sit beside this repo, i.e. ^<parent^>\env\fe.env
    pause
    exit /b 1
)

git checkout dev
git pull

docker compose --env-file %ENVFILE% up -d --build

echo.
echo Done. Open http://localhost:8080
pause
