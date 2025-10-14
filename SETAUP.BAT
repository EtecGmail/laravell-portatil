@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

color 0a
title LARAVEL PORTATIL :: CONSTRUTOR DE ESTRUTURA

set "BASE=%~dp0"
set "CREATED_COUNT=0"
set "FAILED=0"

call :printHeader

call :ensureDirectory "%BASE%projetos" "Projetos Laravel"
call :ensureDirectory "%BASE%projetos\_exemplos" "Projetos de exemplo"
call :ensureDirectory "%BASE%backups" "Backups gerais"
call :ensureDirectory "%BASE%temp" "Arquivos temporarios"
call :ensureDirectory "%BASE%logs" "Logs gerais"

call :ensureDirectory "%BASE%composer" "Ferramentas do Composer"
call :ensureDirectory "%BASE%composer\cache" "Cache do Composer"
call :ensureDirectory "%BASE%composer\home" "Home do Composer"

call :ensureDirectory "%BASE%php" "Runtime PHP portatil"

call :ensureDirectory "%BASE%mariadb" "MariaDB portatil"
call :ensureDirectory "%BASE%mariadb\data" "Base de dados do MariaDB"
call :ensureDirectory "%BASE%mariadb\tmp" "Temp do MariaDB"
call :ensureDirectory "%BASE%mariadb\backup" "Backups do MariaDB"

call :writeProjectsReadme "%BASE%projetos"
call :ensureMariaDbSkeleton
call :checkPortableBinaries

if defined FAILED (
    echo.
    echo [FALHA] Ocorreram erros ao criar a estrutura base. Corrija-os e execute novamente o SETAUP.
    pause
    exit /b 1
)

echo.
echo ===============================================
echo [RESUMO]
echo     Pastas criadas nesta execucao : !CREATED_COUNT!
echo     Local base do pendrive        : %BASE%
echo ===============================================
echo.

echo [INFO] Estrutura valida detectada.
if exist "%BASE%setup.bat" (
    echo.
    set /P "RUN_SETUP=Deseja executar o setup.bat para validar os binarios? [S/n] "
    if /I "!RUN_SETUP!"=="" set "RUN_SETUP=S"
    if /I "!RUN_SETUP!"=="S" (
        echo.
        echo [INFO] Executando setup.bat...
        call "%BASE%setup.bat"
        set "ERR=%ERRORLEVEL%"
        if not "!ERR!"=="0" (
            echo [ALERTA] O setup retornou codigo !ERR!. Verifique as mensagens acima.
        )
    ) else (
        echo [INFO] Execucao do setup.bat ignorada pelo usuario.
    )
) else (
    echo [ALERTA] Arquivo "setup.bat" nao encontrado. Copie o script para esta pasta antes de continuar.
)

echo.
echo [SUCESSO] Estrutura portatil revisada. Utilize "start.bat" para iniciar um projeto apos o setup.
pause
exit /b 0

:printHeader
cls
echo ===============================================
echo      LARAVEL PORTATIL — CRIADOR DE ESTRUTURA
echo ===============================================
echo.
echo Este assistente garante que as pastas essenciais

do pacote portatil existam antes do primeiro uso.
echo Nenhum arquivo sera sobrescrito.
echo.
exit /b 0

:ensureDirectory
set "TARGET=%~1"
set "LABEL=%~2"
if exist "%TARGET%" (
    echo [OK] %LABEL% ja existe em "%TARGET%".
    exit /b 0
)
mkdir "%TARGET%" >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Falha ao criar "%TARGET%" (%LABEL%). Verifique permissoes do pendrive.
    set "FAILED=1"
    exit /b 1
)
set /a CREATED_COUNT+=1 >nul
if exist "%TARGET%" (
    echo [NOVO] Pasta criada: %LABEL% -> "%TARGET%"
) else (
    echo [ERRO] Criacao de "%TARGET%" nao confirmada.
    set "FAILED=1"
)
exit /b 0

:writeProjectsReadme
set "PROJECTS_DIR=%~1"
set "GUIDE=%PROJECTS_DIR%\LEIAME.txt"
if exist "%GUIDE%" exit /b 0
(
    echo ###############################################
    echo # Pasta de Projetos Laravel Portatil          #
    echo ###############################################
    echo.
    echo 1. Cada subpasta dentro de "projetos" e um
    echo    projeto Laravel independente.
    echo 2. Copie aqui um projeto existente ou
    echo    use "create_project.bat" para gerar um novo.
    echo 3. Rode "start.bat" para escolher o projeto e
    echo    iniciar os servicos automaticamente.
    echo 4. Backups e dumps podem ser guardados na
    echo    pasta "backups" na raiz do pacote.
) > "%GUIDE%"
if errorlevel 1 (
    echo [ALERTA] Nao foi possivel criar "%GUIDE%". Crie o arquivo manualmente, se necessario.
)
exit /b 0

:ensureMariaDbSkeleton
set "MARIADB_BASE=%BASE%mariadb"
set "INI=%MARIADB_BASE%\my.ini"
set "LOG=%MARIADB_BASE%\mariadb_error.log"
if exist "%INI%" (
    echo [OK] Configuracao do MariaDB localizada em "%INI%".
) else (
    call :normalizeToPosix "%BASE%" BASE_POSIX
    set "MARIADB_POSIX=!BASE_POSIX!/mariadb"
    (
        echo [mysqld]
        echo basedir=!MARIADB_POSIX!
        echo datadir=!MARIADB_POSIX!/data
        echo tmpdir=!MARIADB_POSIX!/tmp
        echo log-error=!MARIADB_POSIX!/mariadb_error.log
        echo bind-address=127.0.0.1
        echo port=3306
        echo character-set-server=utf8mb4
        echo collation-server=utf8mb4_unicode_ci
        echo skip-external-locking
        echo.
        echo [client]
        echo port=3306
        echo user=root
        echo password=
        echo socket=!MARIADB_POSIX!/tmp/mysql.sock
    )> "%INI%"
    if errorlevel 1 (
        echo [ERRO] Nao foi possivel gerar "%INI%". Copie um my.ini valido para a pasta do MariaDB.
        set "FAILED=1"
    ) else (
        echo [NOVO] Arquivo my.ini basico criado em "%INI%". Ajuste portas manualmente se necessario.
    )
)
if not exist "%LOG%" (
    type nul > "%LOG%" 2>nul
    if errorlevel 1 (
        echo [ALERTA] Falha ao criar o arquivo de log do MariaDB em "%LOG%".
    ) else (
        echo [NOVO] Arquivo de log do MariaDB inicializado em "%LOG%".
    )
) else (
    echo [OK] Arquivo de log do MariaDB encontrado em "%LOG%".
)
exit /b 0

:checkPortableBinaries
set "PHP_EXE=%BASE%php\php.exe"
set "COMPOSER_PHAR=%BASE%composer\composer.phar"
set "COMPOSER_BAT=%BASE%composer\composer.bat"
set "MYSQLD=%BASE%mariadb\bin\mysqld.exe"

if exist "%PHP_EXE%" (
    echo [OK] PHP portatil detectado em "%PHP_EXE%".
) else (
    echo [ALERTA] PHP portatil nao encontrado. Copie sua pasta PHP para "%BASE%php".
)

if exist "%COMPOSER_BAT%" (
    echo [OK] Composer BAT detectado em "%COMPOSER_BAT%".
) else if exist "%COMPOSER_PHAR%" (
    echo [OK] Composer PHAR detectado em "%COMPOSER_PHAR%".
) else (
    echo [ALERTA] Nenhum Composer portatil encontrado. Copie composer.phar ou composer.bat para "%BASE%composer".
)

if exist "%MYSQLD%" (
    echo [OK] mysqld.exe encontrado em "%MYSQLD%".
) else (
    echo [ALERTA] Binarios do MariaDB ausentes. Copie o conteudo extraido do MariaDB para "%BASE%mariadb".
)
exit /b 0

:normalizeToPosix
setlocal
set "RAW=%~1"
set "RAW=%RAW:\=/%"
if "%RAW:~-1%"=="/" set "RAW=%RAW:~0,-1%"
endlocal & set "%~2=%RAW%"
exit /b 0
