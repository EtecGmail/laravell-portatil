@echo off
chcp 65001 >nul

setlocal

:: Adiciona php e composer do diretório atual ao PATH
set "PATH=%~dp0php;%~dp0composer;%PATH%"
echo [INFO] PATH configurado para usar PHP e Composer portátil.

:: Verifica se php está acessível
where php >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Nao foi possivel localizar o executavel "php".
    echo Verifique se existe php.exe em "%~dp0php".
    echo.
    pause
    exit /b 1
) else (
    echo [OK] PHP localizado em:
    where php
)

echo.

:: Verifica se composer está acessível
where composer >nul 2>&1
if errorlevel 1 (
    echo [ALERTA] Nao foi possivel localizar o executavel "composer".
    echo Se voce deseja usar Composer, verifique se existe composer.exe em:
    echo "%~dp0composer"
    echo (Esta mensagem nao impede o uso do PHP nem do start.bat.)
) else (
    echo [OK] COMPOSER localizado em:
    where composer
)

echo.
echo [SUCESSO] Ambiente configurado! Feche esta janela e abra o "start.bat"
echo para iniciar o seu Laravel Project Manager by Yurizin do Grau.
pause
