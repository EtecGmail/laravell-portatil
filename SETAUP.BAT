@echo off
:: Criando diretórios
mkdir projetos

:: Criando arquivos
echo @echo off > setup.bat
echo echo Configuração inicial... >> setup.bat
echo pause >> setup.bat

echo @echo off > start.bat
echo echo Iniciando projeto... >> start.bat
echo pause >> start.bat

echo Estrutura criada com sucesso!
pause
