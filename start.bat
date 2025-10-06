@echo off
setlocal enabledelayedexpansion

:: ───────── CONFIGURAÇÃO E ESTILO ─────────
color 0a
title LARAVEL PROJECT MANAGER v2.0[YUZLKK]

:: Caminhos principais
set "BASE=%~dp0"
set "PROJETOS_DIR=%BASE%projetos"
set "MARIADB_BIN=%BASE%mariadb\bin\mysqld.exe"
set "MARIADB_MYSQL=%BASE%mariadb\bin\mysql.exe"
set "MARIADB_INI=%BASE%mariadb\my.ini"
set "MARIADB_PORT=3307"


:: ----------------------------------------------------------------
:: VERIFICA SE EXISTE PHP LOCAL; SE NÃO, USA O PHP DO SISTEMA
:: ----------------------------------------------------------------
set "PHPEXE=%BASE%php\php.exe"
if exist "%PHPEXE%" (
    echo [INFO] PHP Local encontrado em "%PHPEXE%"
) else (
    echo [ALERTA] Nao encontrei PHP local. Tentando usar PHP do sistema...
    set "PHPEXE=php"
)

:: ───────── INICIA MARIADB SE NÃO ESTIVER RODANDO ─────────
netstat -ano | findstr /R ":%MARIADB_PORT%.*LISTENING" >nul || (
    echo Iniciando MariaDB na porta %MARIADB_PORT%...
    start "" /b /D "%BASE%mariadb" "%BASE%mariadb\bin\mysqld.exe" --defaults-file="%BASE%mariadb\my.ini"
    
    :: Aguarda até o MariaDB abrir a porta
    set "tentativas=0"
    :aguarda_mariadb
    timeout /t 1 >nul
    set /a tentativas+=1
    netstat -ano | findstr /R ":%MARIADB_PORT%.*LISTENING" >nul
    if errorlevel 1 (
        if !tentativas! LSS 10 goto aguarda_mariadb
        echo ERRO: MariaDB nao respondeu na porta %MARIADB_PORT% apos 10 segundos.
        pause
        exit /b
    )
)

:: ───────── VERIFICA PASTA DE PROJETOS ─────────
if not exist "%PROJETOS_DIR%" (
    echo A pasta "projetos" nao foi encontrada no caminho: %PROJETOS_DIR%
    pause
    exit /b
)

:: Limpa a tela
cls

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

echo.
echo ***************************************
echo *       SELECIONADOR DE PROJETOS      *
echo ***************************************
echo.

:: ───────── LISTA OS DIRETÓRIOS DENTRO DE "projetos" ─────────
set /A index=0
for /D %%D in ("%PROJETOS_DIR%\*") do (
    set /A index+=1
    set "projeto[!index!]=%%D"
    set "nome_projeto[!index!]=%%~nxD"
    echo [!index!] - %%~nxD
)

if %index%==0 (
    echo Nenhum projeto encontrado na pasta "projetos".
    pause
    exit /b
)

:escolha_projeto
echo.
set /P "escolha=Digite o numero do projeto que deseja iniciar: "

:: Remove todos os caracteres nao numericos
set "escolha=%escolha:"=%"
for /f "delims=0123456789" %%i in ("%escolha%") do set "escolha="

if not defined escolha goto escolha_projeto
if %escolha% LSS 1 goto escolha_projeto
if %escolha% GTR %index% goto escolha_projeto

set "PROJETO_SELECIONADO=!projeto[%escolha%]!"
set "NOME_PROJETO=!nome_projeto[%escolha%]!"

:: ----------------------------------------------------
:: [BLOCO] ATUALIZAR .ENV DO PROJETO COM DB DO MARIA DB
:: ----------------------------------------------------

:: 1) Navega até a pasta do projeto
cd /D "%PROJETO_SELECIONADO%"

:: 2) Se nao existe .env, cria a partir de .env.example (caso exista)
if not exist ".env" (
    if exist ".env.example" (
        echo Criando .env a partir de .env.example...
        copy ".env.example" ".env" >nul
    ) else (
        echo Criando .env vazio...
        echo # Gerado dinamicamente> .env
    )
)

:: 3) Remove as linhas antigas de DB_* e recria
if exist ".env" (
    echo Ajustando variaveis de banco no .env...

    :: a) Remove as linhas que começam com DB_ (DB_CONNECTION, DB_HOST, etc)
    findstr /V "^DB_CONNECTION= ^DB_HOST= ^DB_PORT= ^DB_DATABASE= ^DB_USERNAME= ^DB_PASSWORD=" ".env" > ".env.temp"

    :: b) Adiciona as linhas atualizadas
    echo DB_CONNECTION=mysql >> ".env.temp"
    echo DB_HOST=127.0.0.1 >> ".env.temp"
    echo DB_PORT=3307 >> ".env.temp"
    :: define o nome do banco igual ao nome da pasta (pode mudar se quiser)
    echo DB_DATABASE=%NOME_PROJETO% >> ".env.temp"
    echo DB_USERNAME=root >> ".env.temp"
    echo DB_PASSWORD= >> ".env.temp"

    :: c) Substitui o .env
    move /Y ".env.temp" ".env" >nul

    :: d) [Opcional] Gera key se nao houver
    findstr /I "^APP_KEY=" ".env" >nul || (
        echo Gerando APP_KEY no .env...
        "%PHPEXE%" artisan key:generate
    )

    :: e) Limpa o cache de config do Laravel para garantir
    "%PHPEXE%" artisan config:clear
)

:: VOLTA para a raiz do pendrive caso precise
cd /D "%~dp0"

echo.
echo ---------------------------------------
echo PROJETO SELECIONADO: !NOME_PROJETO!
echo ---------------------------------------
echo.

:: ───────── VERIFICA SE A PORTA 8000 ESTÁ LIVRE ─────────
set "PORTA=8000"
netstat -ano | findstr /R ":8000.*LISTENING" >nul && (
    echo A porta 8000 esta em uso.
    :solicita_porta
    set /P "PORTA=Digite uma porta alternativa (ou deixe em branco para 8001): "
    if not defined PORTA set "PORTA=8001"
    
    :: Valida a porta
    echo %PORTA% | findstr "^[0123456789][0123456789]*$" >nul || (
        echo Porta invalida! Digite apenas numeros.
        goto solicita_porta
    )

    :: Verifica se a porta alternativa esta em uso
    netstat -ano | findstr /R ":%PORTA%.*LISTENING" >nul && (
        echo A porta %PORTA% tambem esta em uso.
        goto solicita_porta
    )
)

echo.
echo Iniciando servidor Laravel na porta %PORTA%...
echo.

:: ───────── OPÇÕES EXTRAS: CRIAR DB + RODAR MIGRATIONS, E/OU ABRIR CONSOLE ─────────

:: 1) Criar DB e rodar migrations
set /P "RUNMIG=Deseja CRIAR o banco '%NOME_PROJETO%' e rodar migrations? [S/n] "
if /I "!RUNMIG!"=="s" (
    echo.
    echo Criando banco se nao existir...

    echo CREATE DATABASE IF NOT EXISTS `^%NOME_PROJETO%^`;> temp.sql
    "%MARIADB_MYSQL%" -u root -h 127.0.0.1 -P %MARIADB_PORT% < temp.sql
    del /Q temp.sql

    echo Rodando migrations...
    cd /D "%PROJETO_SELECIONADO%"
    "%PHPEXE%" artisan migrate 2> migrate_error.txt

    if %ERRORLEVEL% NEQ 0 (
        findstr /C:"already exists" migrate_error.txt >nul && (
            set /P "CHOICE=Erro: tabela ja existe. Deseja rodar migrate:fresh? [S/n] "
            if /I "!CHOICE!"=="s" (
                "%PHPEXE%" artisan migrate:fresh
            )
        )
    )
    del /Q migrate_error.txt
    cd /D "%~dp0"
    echo Migrations concluidas.
    echo.
)

:: 2) Abrir console de depuracao do MariaDB
set /P "DEBUGDB=Deseja abrir um console MariaDB para depuracao? [S/n] "
if /I "!DEBUGDB!"=="s" (
    :: Abre outro CMD ja conectado ao banco do projeto
    start cmd /k "%MARIADB_MYSQL%" -u root -h 127.0.0.1 -P %MARIADB_PORT% %NOME_PROJETO%
)

:: ───────── INICIA LARAVEL NA PORTA ESCOLHIDA ─────────
cd /D "%PROJETO_SELECIONADO%"
"%PHPEXE%" artisan serve --host=127.0.0.1 --port=%PORTA%

pause
