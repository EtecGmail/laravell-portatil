@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

:: ───────── CONFIGURAÇÃO E ESTILO ─────────
color 0a
title LARAVEL PROJECT CREATOR (PREVIEW) [YUZLKK]

:: Define a raiz do pendrive (local do script)
set "BASE=%~dp0"
set "PROJETOS_DIR=%BASE%projetos"
set "PORTABLE_PHP=%BASE%php\php.exe"
set "PORTABLE_COMPOSER_PHAR=%BASE%composer\composer.phar"
set "PORTABLE_COMPOSER_BAT=%BASE%composer\composer.bat"
set "COMPOSER_HOME=%BASE%composer\home"
set "COMPOSER_CACHE_DIR=%BASE%composer\cache"

if not exist "%PROJETOS_DIR%" (
    echo [YUZLKK] Pasta "projetos" nao encontrada. Criando...
    mkdir "%PROJETOS_DIR%"
    if errorlevel 1 (
        echo [YUZLKK] ERRO: Nao foi possivel criar a pasta "projetos".
        pause
        exit /b 1
    )
)

for %%D in ("%COMPOSER_HOME%" "%COMPOSER_CACHE_DIR%") do (
    if not exist "%%~fD" (
        mkdir "%%~fD" >nul 2>&1
    )
)

set "PHP_CMD=%PORTABLE_PHP%"
if exist "%PHP_CMD%" (
    echo [YUZLKK] PHP portatil encontrado em "%PHP_CMD%".
) else (
    echo [YUZLKK] Executavel PHP portatil nao encontrado. Tentando usar PHP do sistema...
    set "PHP_CMD=php"
)

if "%PHP_CMD%"=="php" (
    where php >nul 2>&1
    if errorlevel 1 (
        echo [YUZLKK] ERRO: Nenhum PHP disponivel no PATH.
        pause
        exit /b 1
    )
) else if not exist "%PHP_CMD%" (
    echo [YUZLKK] ERRO: O executavel PHP esperado nao foi encontrado em "%PHP_CMD%".
    pause
    exit /b 1
)


set "COMPOSER_MODE="
if exist "%PORTABLE_COMPOSER_BAT%" (
    set "COMPOSER_MODE=bat"
    echo [YUZLKK] Composer BAT portatil encontrado em "%PORTABLE_COMPOSER_BAT%".
) else if exist "%PORTABLE_COMPOSER_PHAR%" (
    set "COMPOSER_MODE=phar"
    echo [YUZLKK] Composer PHAR portatil encontrado em "%PORTABLE_COMPOSER_PHAR%".
) else (
    where composer >nul 2>&1
    if errorlevel 1 (
        echo [YUZLKK] ERRO: Composer nao foi encontrado. Copie composer.phar para "%BASE%composer" ou instale-o no PATH.
        pause
        exit /b 1
    )
    set "COMPOSER_MODE=system"
    echo [YUZLKK] Usando Composer presente no PATH do sistema.
)

echo.
echo =======================================================
echo             [YUZLKK] LARAVEL PROJECT CREATOR
echo =======================================================
echo.
echo Este utilitario cria um novo projeto Laravel 12 na pasta "projetos".
echo As dependencias sao baixadas do cache local do Composer (se disponivel).

echo.
set /P "PROJETO_NOME=Digite o nome do novo projeto: "
if "%PROJETO_NOME%"=="" (
    echo [YUZLKK] ERRO: Nome do projeto nao pode ser vazio.
    pause
    exit /b 1
)

for /f "tokens=* delims= " %%A in ("%PROJETO_NOME%") do set "PROJETO_NOME=%%A"
if "%PROJETO_NOME%"=="" (
    echo [YUZLKK] ERRO: Nome do projeto invalido.
    pause
    exit /b 1
)

set "DESTINO=%PROJETOS_DIR%\%PROJETO_NOME%"
if exist "%DESTINO%" (
    echo [YUZLKK] ERRO: Um projeto com o nome "%PROJETO_NOME%" ja existe na pasta "projetos".
    pause
    exit /b 1
)

echo.
echo [YUZLKK] Criando o projeto Laravel 12 "%PROJETO_NOME%"...
set "COMPOSER_PROCESS_TIMEOUT=0"
set "NO_INTERACTION=--no-interaction"
if "%COMPOSER_MODE%"=="bat" (
    call "%PORTABLE_COMPOSER_BAT%" create-project --prefer-dist --ansi %NO_INTERACTION% laravel/laravel "%DESTINO%" "12.*"
) else if "%COMPOSER_MODE%"=="phar" (
    if /I "%PHP_CMD%"=="php" (
        call php "%PORTABLE_COMPOSER_PHAR%" create-project --prefer-dist --ansi %NO_INTERACTION% laravel/laravel "%DESTINO%" "12.*"
    ) else (
        call "%PHP_CMD%" "%PORTABLE_COMPOSER_PHAR%" create-project --prefer-dist --ansi %NO_INTERACTION% laravel/laravel "%DESTINO%" "12.*"
    )
) else (
    call composer create-project --prefer-dist --ansi %NO_INTERACTION% laravel/laravel "%DESTINO%" "12.*"
)
if errorlevel 1 (
    echo [YUZLKK] ERRO: Nao foi possivel criar o projeto. Verifique o cache do Composer e tente novamente.
    pause
    exit /b 1
)

echo.
echo [YUZLKK] Projeto criado com sucesso em:
echo     %DESTINO%
echo.
echo Sugestao: execute "start.bat" para configurar portas, banco de dados e iniciar o servidor local.

echo.
pause
endlocal
