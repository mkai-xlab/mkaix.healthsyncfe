@echo off
cd /d "%~dp0"

git checkout dev
git pull

docker compose up -d --build

echo.
echo Done. Open http://localhost:8080
pause
