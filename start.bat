@echo off
setlocal enabledelayedexpansion

:: ───────── CONFIGURAÇÃO E ESTILO ─────────
color 0a
title LARAVEL PROJECT MANAGER v2.1[YUZLKK]

:: Caminhos principais
set "BASE=%~dp0"
set "PROJETOS_DIR=%BASE%projetos"
set "MARIADB_DIR=%BASE%mariadb"
set "MARIADB_BIN=%MARIADB_DIR%\bin\mysqld.exe"
set "MARIADB_MYSQL=%MARIADB_DIR%\bin\mysql.exe"
set "MARIADB_INI=%MARIADB_DIR%\my.ini"
set "MARIADB_LOG=%MARIADB_DIR%\mariadb_error.log"
set "MARIADB_DATA=%MARIADB_DIR%\data"
set "MARIADB_PORT="
set "MARIADB_PORT_CANDIDATES=3306 3307 3308 3310"
set "LARAVEL_PORT_CANDIDATES=8000 8080 8888"
set "LARAVEL_HOST=127.0.0.1"
set "TEMP_SQL=%BASE%temp.sql"
set "ARTISAN_AVAILABLE=0"

if not exist "%MARIADB_DIR%" (
    echo [ERRO] Pasta do MariaDB nao encontrada em "%MARIADB_DIR%".
    echo        Rode SETAUP.BAT para recriar a estrutura e depois execute setup.bat.
    goto fatal
)

if not exist "%MARIADB_BIN%" (
    echo [ERRO] Binario do MariaDB nao encontrado em "%MARIADB_BIN%".
    echo         Reconstrua a estrutura com SETAUP.BAT e reextraia os binarios, se necessario.
    goto fatal
)

if not exist "%MARIADB_MYSQL%" (
    echo [ERRO] Cliente mysql.exe nao encontrado em "%MARIADB_MYSQL%".
    echo         Utilize SETAUP.BAT para garantir a estrutura basica do MariaDB.
    goto fatal
)

if not exist "%MARIADB_INI%" (
    echo [ERRO] Arquivo de configuracao do MariaDB (my.ini) ausente em "%MARIADB_INI%".
    echo         Rode SETAUP.BAT para gerar um esqueleto de configuracao.
    goto fatal
)

if not exist "%MARIADB_DATA%" (
    echo [ERRO] Pasta de dados do MariaDB nao encontrada em "%MARIADB_DATA%".
    echo        Execute SETAUP.BAT para recriar a estrutura necessaria e depois rode setup.bat.
    goto fatal
)

if not exist "%MARIADB_LOG%" (
    echo [INFO] Criando arquivo de log do MariaDB em "%MARIADB_LOG%"...
    type nul > "%MARIADB_LOG%"
)

set "PHPEXE=%BASE%php\php.exe"
if exist "%PHPEXE%" (
    echo [INFO] PHP Local encontrado em "%PHPEXE%"
) else (
    echo [ALERTA] Nao encontrei PHP local. Tentando usar PHP do sistema...
    set "PHPEXE=php"
)

if "%PHPEXE%"=="php" (
    where php >nul 2>&1
    if errorlevel 1 (
        echo [ERRO] Nenhuma instalacao de PHP encontrada no PATH.
        goto fatal
    )
) else if not exist "%PHPEXE%" (
    echo [ERRO] O executavel PHP esperado nao foi encontrado em "%PHPEXE%".
    goto fatal
)

for %%P in (%MARIADB_PORT_CANDIDATES%) do (
    if not defined MARIADB_PORT (
        call :CheckPortFree %%P port_free
        if "!port_free!"=="1" (
            set "MARIADB_PORT=%%P"
        )
    )
)

if not defined MARIADB_PORT (
    call :FindFreePortInRange 3320 3399 MARIADB_PORT
)

if not defined MARIADB_PORT (
    echo [ERRO] Nenhuma porta livre encontrada para o MariaDB nas faixas testadas.
    goto fatal
)

netstat -ano | findstr /R ":!MARIADB_PORT!.*LISTENING" >nul || (
    echo Iniciando MariaDB na porta !MARIADB_PORT!...
    start "" /b /D "%MARIADB_DIR%" "%MARIADB_BIN%" --defaults-file="%MARIADB_INI%" --port=!MARIADB_PORT! --bind-address=%LARAVEL_HOST%
    set "tentativas=0"
    :aguarda_mariadb
    timeout /t 1 >nul
    set /a tentativas+=1
    netstat -ano | findstr /R ":!MARIADB_PORT!.*LISTENING" >nul
    if errorlevel 1 (
        if !tentativas! LSS 10 goto aguarda_mariadb
        echo ERRO: MariaDB nao respondeu na porta !MARIADB_PORT! apos 10 segundos.
        goto fatal
    )
)

if not exist "%PROJETOS_DIR%" (
    echo A pasta "projetos" nao foi encontrada no caminho: %PROJETOS_DIR%
    pause
    exit /b
)

cls

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
set "escolha=%escolha:"=%"
for /f "delims=0123456789" %%i in ("%escolha%") do set "escolha="
if not defined escolha goto escolha_projeto
if %escolha% LSS 1 goto escolha_projeto
if %escolha% GTR %index% goto escolha_projeto

set "PROJETO_SELECIONADO=!projeto[%escolha%]!"
set "NOME_PROJETO=!nome_projeto[%escolha%]!"
set "PORTA="
for %%P in (%LARAVEL_PORT_CANDIDATES%) do (
    if not defined PORTA (
        call :CheckPortFree %%P port_free
        if "!port_free!"=="1" (
            set "PORTA=%%P"
        )
    )
)

if not defined PORTA (
    call :FindFreePortInRange 8000 8999 PORTA
)

if not defined PORTA (
    echo [ERRO] Nenhuma porta HTTP livre encontrada entre 8000 e 8999.
    goto fatal
)

echo.
echo PROJETO SELECIONADO: !NOME_PROJETO!
echo Porta HTTP: !PORTA!
echo Porta MariaDB: !MARIADB_PORT!
echo.

echo ***************************************
set "DB_DATABASE=%NOME_PROJETO%"
set "DB_DATABASE=%DB_DATABASE: =_%"
set "DB_DATABASE=%DB_DATABASE:-=_%"
set "DB_DATABASE=%DB_DATABASE:.=_%"
if not defined DB_DATABASE set "DB_DATABASE=laravel_app"

pushd "%PROJETO_SELECIONADO%"
if exist "artisan" (
    set "ARTISAN_AVAILABLE=1"
) else (
    set "ARTISAN_AVAILABLE=0"
    echo [ALERTA] O arquivo "artisan" nao foi encontrado neste projeto.
)

if not exist ".env" (
    if exist ".env.example" (
        echo Criando .env a partir de .env.example...
        copy ".env.example" ".env" >nul
    ) else (
        echo Criando .env vazio...
        echo # Gerado dinamicamente> .env
    )
)

if exist ".env" (
    echo Ajustando variaveis de banco e URL no .env...
    findstr /V "^DB_CONNECTION= ^DB_HOST= ^DB_PORT= ^DB_DATABASE= ^DB_USERNAME= ^DB_PASSWORD= ^APP_URL=" ".env" > ".env.temp"
    echo DB_CONNECTION=mysql >> ".env.temp"
    echo DB_HOST=127.0.0.1 >> ".env.temp"
    echo DB_PORT=!MARIADB_PORT! >> ".env.temp"
    echo DB_DATABASE=!DB_DATABASE! >> ".env.temp"
    echo DB_USERNAME=root >> ".env.temp"
    echo DB_PASSWORD= >> ".env.temp"
    echo APP_URL=http://%LARAVEL_HOST%:!PORTA! >> ".env.temp"
    move /Y ".env.temp" ".env" >nul

    findstr /I "^APP_KEY=" ".env" >nul || (
        if "!ARTISAN_AVAILABLE!"=="1" (
            echo Gerando APP_KEY no .env...
            call :RunArtisan key:generate --force --ansi >nul
        ) else (
            echo [ALERTA] APP_KEY ausente, mas o arquivo "artisan" nao foi encontrado.
        )
    )

    if "!ARTISAN_AVAILABLE!"=="1" (
        call :RunArtisan config:clear >nul
    )
)

set /P "RUNMIG=Deseja CRIAR o banco '!DB_DATABASE!' e rodar migrations? [S/n] "
if /I "!RUNMIG!"=="s" (
    echo.
    echo Criando banco se nao existir...
    echo CREATE DATABASE IF NOT EXISTS `!DB_DATABASE!`;>"%TEMP_SQL%"
    "%MARIADB_MYSQL%" -u root -h %LARAVEL_HOST% -P !MARIADB_PORT! < "%TEMP_SQL%"
    del /Q "%TEMP_SQL%" >nul 2>&1

    if "!ARTISAN_AVAILABLE!"=="1" (
        echo Rodando migrations...
        call :RunArtisan migrate --force --ansi 2> migrate_error.txt
        if errorlevel 1 (
            findstr /C:"already exists" migrate_error.txt >nul && (
                set /P "CHOICE=Erro: tabela ja existe. Deseja rodar migrate:fresh? [S/n] "
                if /I "!CHOICE!"=="s" (
                    call :RunArtisan migrate:fresh --force --ansi
                )
            )
        )
        del /Q migrate_error.txt >nul 2>&1
    ) else (
        echo [ALERTA] Comando artisan indisponivel; migrations nao puderam ser executadas.
    )
    echo.
)

set /P "DEBUGDB=Deseja abrir um console MariaDB para depuracao? [S/n] "
if /I "!DEBUGDB!"=="s" (
    start cmd /k "%MARIADB_MYSQL%" -u root -h %LARAVEL_HOST% -P !MARIADB_PORT! !DB_DATABASE!
)

echo.
echo Iniciando servidor Laravel na porta !PORTA!...
echo.
if "!ARTISAN_AVAILABLE!"=="1" (
    call :RunArtisan serve --host=%LARAVEL_HOST% --port=!PORTA!
) else (
    echo [ALERTA] Nao foi possivel localizar o artisan. Inicie manualmente com:
    echo     %PHPEXE% -S %LARAVEL_HOST%:!PORTA! -t public
)

popd

pause
goto :EOF

:fatal
echo.
echo [ERRO] Execucao interrompida. Verifique as mensagens acima, ajuste o ambiente e tente novamente.
pause
exit /b 1

:CheckPortFree
setlocal
set "_check_port=%~1"
netstat -ano | findstr /R ":%_check_port% .*LISTENING" >nul 2>&1
if errorlevel 1 (
    endlocal & set "%~2=1" & exit /b 0
) else (
    endlocal & set "%~2=0" & exit /b 0
)

:FindFreePortInRange
setlocal
set "_range_start=%~1"
set "_range_end=%~2"
set "_range_result="
for /L %%p in (%_range_start%,1,%_range_end%) do (
    netstat -ano | findstr /R ":%%p .*LISTENING" >nul 2>&1
    if errorlevel 1 (
        set "_range_result=%%p"
        goto found_free_port
    )
)

:found_free_port
if defined _range_result (
    endlocal & set "%~3=%_range_result%" & exit /b 0
)

endlocal & set "%~3=" & exit /b 1

:RunArtisan
setlocal
set "COMMAND=%~1"
shift
"%PHPEXE%" artisan %COMMAND% %*
set "CODE=%ERRORLEVEL%"
endlocal & exit /b %CODE%
