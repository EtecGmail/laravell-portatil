@echo off
setlocal enabledelayedexpansion

:: ───────── CONFIGURAÇÃO E ESTILO ─────────
color 0a
title LARAVEL PROJECT CREATOR (PREVIEW) [YUZLKK]

:: Define a raiz do pendrive (local do script)
set "BASE=%~dp0"

:: Define a pasta de projetos (cria se não existir)
set "PROJETOS_DIR=%BASE%projetos"
if not exist "%PROJETOS_DIR%" (
    echo [YUZLKK] Pasta "projetos" nao encontrada. Criando...
    mkdir "%PROJETOS_DIR%"
    if errorlevel 1 (
        echo [YUZLKK] ERRO: Nao foi possivel criar a pasta "projetos".
        pause
        exit /b
    )
)

:: ───────── DEFINIÇÃO DOS EXECUTÁVEIS PORTÁTEIS ─────────
:: Caminho dos executáveis portáteis (atenção: use aspas se o caminho tiver espaços)
set "PORTABLE_PHP=%~dp0php\php.exe"
set "PORTABLE_COMPOSER=%~dp0composer\composer.phar"

:: Se os executáveis portáteis existirem, use-os; caso contrário, use os do sistema
if exist "%PORTABLE_PHP%" (
    set "PHP_EXE=%PORTABLE_PHP%"
) else (
    echo [YUZLKK] Executavel PHP portátil nao encontrado. Utilizando o PHP do sistema.
    set "PHP_EXE=php"
)
if exist "%PORTABLE_COMPOSER%" (
    set "COMPOSER_PHAR=%PORTABLE_COMPOSER%"
) else (
    echo [YUZLKK] Executavel Composer portátil nao encontrado. Utilizando o Composer do sistema.
    set "COMPOSER_PHAR=composer"
)

:: ───────── CABEÇALHO VISUAL ─────────
echo "      $$\     $$\ $$\   $$\ $$$$$$$$\ $$\       $$\   $$\ $$\   $$\              ";
echo "      \$$\   $$  |$$ |  $$ |\____$$  |$$ |      $$ | $$  |$$ | $$  |             ";
echo "       \$$\ $$  / $$ |  $$ |    $$  / $$ |      $$ |$$  / $$ |$$  /              ";
echo "        \$$$$  /  $$ |  $$ |   $$  /  $$ |      $$$$$  /  $$$$$  /               ";
echo "         \$$  /   $$ |  $$ |  $$  /   $$ |      $$  $$<   $$  $$<                ";
echo "          $$ |    $$ |  $$ | $$  /    $$ |      $$ |\$$\  $$ |\$$\               ";
echo "          $$ |    \$$$$$$  |$$$$$$$$\ $$$$$$$$\ $$ | \$$\ $$ | \$$\              ";
echo "          \__|     \______/ \________|\________|\__|  \__|\__|  \__|             ";
echo "                                                                                 ";
echo "                                                                                 ";
echo "                                                                                 ";
echo "$$\        $$$$$$\  $$$$$$$\   $$$$$$\  $$\    $$\ $$$$$$$$\ $$\       $$\       ";
echo "$$ |      $$  __$$\ $$  __$$\ $$  __$$\ $$ |   $$ |$$  _____|$$ |      $$ |      ";
echo "$$ |      $$ /  $$ |$$ |  $$ |$$ /  $$ |$$ |   $$ |$$ |      $$ |      $$ |      ";
echo "$$ |      $$$$$$$$ |$$$$$$$  |$$$$$$$$ |\$$\  $$  |$$$$$\    $$ |      $$ |      ";
echo "$$ |      $$  __$$ |$$  __$$< $$  __$$ | \$$\$$  / $$  __|   $$ |      $$ |      ";
echo "$$ |      $$ |  $$ |$$ |  $$ |$$ |  $$ |  \$$$  /  $$ |      $$ |      $$ |      ";
echo "$$$$$$$$\ $$ |  $$ |$$ |  $$ |$$ |  $$ |   \$  /   $$$$$$$$\ $$$$$$$$\ $$$$$$$$\ ";
echo "\________|\__|  \__|\__|  \__|\__|  \__|    \_/    \________|\________|\________|";
echo "                                                                                 ";
echo "                                                                                 ";
echo "                                                                                 ";
pause
cls
echo =======================================================
echo             [YUZLKK] LARAVEL PROJECT CREATOR
echo =======================================================
echo.
echo Este serve para criar um novo projeto Laravel 12 na pasta "projetos".
echo.

:: ───────── SOLICITA O NOME DO NOVO PROJETO ─────────
set /P "PROJETO_NOME=Digite o nome do novo projeto: "
if "%PROJETO_NOME%"=="" (
    echo [YUZLKK] ERRO: Nome do projeto nao pode ser vazio imbecilidade "humana".
    pause
    exit /b
)

:: Define o caminho completo para o novo projeto
set "DESTINO=%PROJETOS_DIR%\%PROJETO_NOME%"

:: Verifica se já existe um projeto com esse nome
if exist "%DESTINO%" (
    echo [YUZLKK] ERRO: Um projeto com o nome "%PROJETO_NOME%" ja existe na pasta "projetos".
    pause
    exit /b
)

:: ───────── CRIA O PROJETO LARAVEL 12 ─────────
echo [YUZLKK] Criando o projeto Laravel 12 "%PROJETO_NOME%"...
"%PHP_EXE%" "%COMPOSER_PHAR%" create-project --prefer-dist laravel/laravel "%DESTINO%" "12.*"
if errorlevel 1 (
    echo [YUZLKK] ERRO: Nao foi possivel criar o projeto. Verifique se os executaveis estao corretos e a conexao com a internet.
    pause
    exit /b
)


echo.
echo [YUZLKK] Projeto criado com sucesso em:
echo %DESTINO%
echo.
pause
endlocal
