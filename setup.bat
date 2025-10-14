@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

color 0a
title LARAVEL PORTATIL :: CONFIGURACAO INICIAL

set "BASE=%~dp0"
set "PHP_PORTABLE=%BASE%php\php.exe"
set "COMPOSER_PORTABLE_PHAR=%BASE%composer\composer.phar"
set "COMPOSER_PORTABLE_BAT=%BASE%composer\composer.bat"
set "MARIADB_DIR=%BASE%mariadb"
set "MARIADB_INI=%MARIADB_DIR%\my.ini"
set "MARIADB_DATA=%MARIADB_DIR%\data"
set "MARIADB_LOG=%MARIADB_DIR%\mariadb_error.log"
set "MARIADB_TMP=%MARIADB_DIR%\tmp"

echo ===============================================
echo   CONFIGURACAO DO PACOTE LARAVEL PORTATIL
echo ===============================================
echo.

call :EnsureDirectoryExists "%MARIADB_DIR%" "mariadb"
call :EnsureDirectoryExists "%MARIADB_DATA%" "mariadb\\data"
call :EnsureDirectoryExists "%MARIADB_TMP%" "mariadb\\tmp"

if not exist "%MARIADB_LOG%" (
    echo [INFO] Criando arquivo de log padrao do MariaDB em "%MARIADB_LOG%"...
    type nul > "%MARIADB_LOG%"
)

if exist "%MARIADB_INI%" (
    call :UpdateMariaDBIni "%MARIADB_INI%"
) else (
    echo [ERRO] Arquivo "my.ini" nao encontrado em "%MARIADB_INI%".
    echo        Copie o arquivo original do pacote ou reextraia o bundle.
    set "SETUP_FAILED=1"
)

call :PreparePortablePath
call :ProbeExecutable "php" "%PHP_PORTABLE%"
call :ProbeComposer

if defined SETUP_FAILED (
    echo.
    echo [FALHA] Ocorreram problemas durante a configuracao.
    echo         Resolva as mensagens acima e execute novamente o setup.
    pause
    exit /b 1
)

echo.
echo [SUCESSO] Ambiente configurado! Agora execute "start.bat" para iniciar os projetos.
pause
exit /b 0

:PreparePortablePath
for %%P in ("%BASE%php" "%BASE%composer") do (
    if exist "%%~fP" (
        set "PATH=%%~fP;!PATH!"
    )
)
echo [INFO] PATH configurado para priorizar executaveis portateis.
goto :EOF

:ProbeExecutable
set "CMD_NAME=%~1"
set "EXPECTED=%~2"
where %CMD_NAME% >nul 2>&1
if errorlevel 1 (
    if exist "%EXPECTED%" (
        echo [INFO] Usando executavel portatil "%EXPECTED%" para %CMD_NAME%.
    ) else (
        echo [ERRO] Nao foi possivel localizar "%CMD_NAME%" no PATH ou em "%EXPECTED%".
        set "SETUP_FAILED=1"
    )
) else (
    echo [OK] %CMD_NAME% localizado em:
    where %CMD_NAME%
)
goto :EOF

:ProbeComposer
if exist "%COMPOSER_PORTABLE_BAT%" (
    echo [INFO] Composer BAT portatil detectado em "%COMPOSER_PORTABLE_BAT%".
) else if exist "%COMPOSER_PORTABLE_PHAR%" (
    echo [INFO] Composer PHAR portatil detectado em "%COMPOSER_PORTABLE_PHAR%".
) else (
    where composer >nul 2>&1
    if errorlevel 1 (
        echo [ALERTA] Composer nao foi encontrado. Recursos que dependem dele ficarao indisponiveis.
    ) else (
        echo [OK] Composer encontrado no PATH do sistema:
        where composer
    )
)
goto :EOF

:EnsureDirectoryExists
set "TARGET=%~1"
set "LABEL=%~2"
if exist "%TARGET%" (
    goto :EOF
)
echo [INFO] Criando pasta "%LABEL%" em "%TARGET%"...
mkdir "%TARGET%" >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Nao foi possivel criar a pasta "%TARGET%". Verifique permissoes do pendrive.
    set "SETUP_FAILED=1"
)
goto :EOF

:UpdateMariaDBIni
setlocal enabledelayedexpansion
set "INI_FILE=%~1"
call :NormalizeToPosix "%BASE%" BASE_POSIX
set "MARIADB_BASE=!BASE_POSIX!/mariadb"
set "MARIADB_DATA=!MARIADB_BASE!/data"
set "MARIADB_LOG=!MARIADB_BASE!/mariadb_error.log"
set "MARIADB_TMP=!MARIADB_BASE!/tmp"

set "FOUND_BASEDIR=0"
set "FOUND_DATADIR=0"
set "FOUND_LOG=0"
set "FOUND_TMP=0"

(for /f "usebackq delims=" %%L in ("!INI_FILE!") do (
    set "LINE=%%L"
    set "OUT=!LINE!"
    if /I "!LINE:~0,8!"=="basedir=" (
        set "OUT=basedir=!MARIADB_BASE!"
        set "FOUND_BASEDIR=1"
    ) else if /I "!LINE:~0,8!"=="datadir=" (
        set "OUT=datadir=!MARIADB_DATA!"
        set "FOUND_DATADIR=1"
    ) else if /I "!LINE:~0,9!"=="log-error" (
        set "OUT=log-error=!MARIADB_LOG!"
        set "FOUND_LOG=1"
    ) else if /I "!LINE:~0,7!"=="tmpdir=" (
        set "OUT=tmpdir=!MARIADB_TMP!"
        set "FOUND_TMP=1"
    )
    echo !OUT!
)
if !FOUND_BASEDIR!==0 echo basedir=!MARIADB_BASE!
if !FOUND_DATADIR!==0 echo datadir=!MARIADB_DATA!
if !FOUND_LOG!==0 echo log-error=!MARIADB_LOG!
if !FOUND_TMP!==0 echo tmpdir=!MARIADB_TMP!
) > "!INI_FILE!.tmp"

move /Y "!INI_FILE!.tmp" "!INI_FILE!" >nul
if errorlevel 1 (
    echo [ERRO] Falha ao atualizar "!INI_FILE!" com os caminhos portateis.
    endlocal & set "SETUP_FAILED=1" & goto :EOF
)

echo [OK] "my.ini" atualizado para o caminho atual do pendrive.
endlocal
goto :EOF

:NormalizeToPosix
setlocal
set "RAW=%~1"
set "RAW=%RAW:\=/%"
if "%RAW:~-1%"=="/" set "RAW=%RAW:~0,-1%"
endlocal & set "%~2=%RAW%"
goto :EOF
