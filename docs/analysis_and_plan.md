# Relatório de Análise — Fase 1

## 1. Resumo executivo
- **Objetivo**: validar o pacote "Laravel Portátil" focando em portabilidade, uso offline e segurança para demos em sala.
- **Ambiente analisado**: Linux 6.12.13 (container) — equivalente a cenários sem privilégios de administrador. `uname -a` executado em 06/10/2025 17:35 UTC.
- **Commit avaliado**: `1a55b0bd71b0ebae6a45c60061f76bd80b7e26e5`.
- **Modo de execução**: indisponível — faltam binários reais de PHP/MariaDB/Composer (somente ponteiros Git LFS), impossibilitando subir serviços a partir do pendrive.

## 2. Pontos fortes
- O `setup.bat` adiciona PHP/Composer portáteis ao `PATH` e valida a presença dos executáveis antes de liberar o ambiente, reduzindo erros de configuração manual.【F:setup.bat†L1-L40】
- O `start.bat` cria `.env` automaticamente quando ausente, gera `APP_KEY` e sincroniza as credenciais do banco do projeto, evitando passos manuais repetitivos para cada demo.【F:start.bat†L158-L199】
- Há detecção automática de PHP portátil, com fallback para o PHP instalado na máquina caso o binário local não exista, o que dá resiliência em laboratórios heterogêneos.【F:start.bat†L56-L62】

## 3. Problemas identificados

| ID | Arquivo / Script | Descrição | Impacto | Reprodução | Evidência | Sugestão |
| --- | --- | --- | --- | --- | --- | --- |
| **P0-1** | `php/php.exe`, `mariadb/bin/mysqld.exe` | Binários essenciais estão versionados apenas como ponteiros Git LFS, impedindo execução offline real no pendrive. | Projeto não inicia (bloqueio total). | Clonar o repositório e tentar rodar `start.bat`; binários ausentes. | 【F:php/php.exe†L1-L3】【F:mariadb/bin/mysqld.exe†L1-L3】 | Empacotar executáveis reais ou fornecer script de sincronização offline no bundle. |
| **P0-2** | `start.bat` | Launcher depende de comandos exclusivos do Windows (`netstat -ano`, `start cmd`, variáveis `%~dp0`); não há scripts equivalentes para Linux/macOS. | Usuários Ubuntu/macOS ficam sem ambiente portátil. | Tentar executar em Linux/macOS → inexistência de `.sh`/`.ps1`. | 【F:start.bat†L34-L320】【99229e†L1-L1】 | Entregar variantes PowerShell e Bash com mesma lógica (detecção de portas, APP_URL, DB). |
| **P0-3** | `create_project.bat` | Criação de projetos exige Composer online (`create-project laravel/laravel 12.*`), contrariando o requisito de operação offline. | Sem Internet não é possível criar novos projetos durante a demo. | Executar `create_project.bat` sem rede → falha relatada pelo próprio script. | 【F:create_project.bat†L92-L99】 | Distribuir skeleton Laravel pré-instalado (vendor cache) + script de cópia local. |
| **P1-1** | `start.bat` | `.env` é sempre regravado com usuário `root` sem senha, ampliando superfície de risco em ambientes compartilhados. | Exposição de banco em demos públicas; invasor conecta sem autenticação. | Rodar `start.bat` e inspecionar `.env`. | 【F:start.bat†L180-L186】 | Criar usuário dedicado com senha randomizada guardada no pendrive. |
| **P1-2** | `start.bat` | Fluxo exige múltiplas respostas interativas (`set /P`), inviabilizando automação e execução “one-click”. | Dificulta demos rápidas e integrações futuras com UI gráfica. | Rodar `start.bat`; observar prompts. | 【F:start.bat†L141-L217】【F:start.bat†L248-L279】 | Introduzir argumentos (`start.bat --auto`) ou menu com tempo limite + defaults seguros. |
| **P1-3** | `start.bat` | Servidor Laravel sobe via `artisan serve` (PHP embutido), pouco robusto para cenários `demo/hard`. | Risco de travar sob carga e ausência de HTTPS; não suporta compressão. | Rodar `start.bat` e observar comando final. | 【F:start.bat†L282-L285】 | Empacotar servidor web leve (Caddy/NGINX) com config estática e fallback para `artisan serve` apenas em `dev`. |
| **P2-1** | Raiz do repositório | Ausência de README/guias por SO; única orientação é o arquivo `LEIA ESTA MERDA.txt` com linguagem ofensiva. | Experiência ruim para turmas novas e onboarding confuso. | Abrir repositório → não há documentação formal. | 【F:'LEIA ESTA MERDA.txt'†L1-L48】 | Criar documentação clara por plataforma e remover linguagem imprópria. |
| **P2-2** | Estrutura | Não existe diretório `projetos` pré-criado; `start.bat` aborta caso esteja ausente. | Primeiro uso falha até que usuário crie pasta manualmente. | Clonar repo → `start.bat` sai por falta de pasta. | 【F:start.bat†L82-L87】【261916†L1-L2】 | Provisionar pasta vazia ou criar automaticamente com readme explicativo. |

## 4. Métricas
- **Tamanho do bundle**: 125 MB (sem os binários reais por causa do LFS, o tamanho final será maior).【1ee77a†L1-L2】
- **Diretórios de projetos**: inexistentes no repositório (`ls projetos` falha).【261916†L1-L2】
- **Portas configuráveis**: após correção inicial, MariaDB escolhe a primeira porta livre (3306/3307/3310/3320-3399) e o app mapeia 8000/8080/8888/8000-8999.【F:start.bat†L14-L50】【F:start.bat†L210-L220】【F:start.bat†L211-L240】
- **Tempo de boot**: não mensurável — binários ausentes impedem execução real; permanece como lacuna.

## 5. Perguntas & lacunas
- Existe pacote oficial (zip) com os binários fora do Git? Necessário para validar desempenho/boot real.
- Há requisito de criptografia para dados de demonstração no pendrive? Não identificado.
- Qual política desejada para logs (rotação / retenção) considerando desgaste do pendrive?
- Precisamos suportar múltiplos projetos simultâneos? Não há evidência de isolamento de dados.

### Matriz de compatibilidade

| Plataforma | Status atual | Observações |
| --- | --- | --- |
| Windows 10/11 | ⚠️ Parcial | Scripts `.bat` presentes, porém dependem de binários faltantes e configuram banco sem senha.【F:start.bat†L18-L320】 |
| Ubuntu LTS | ❌ Não suportado | Não existem scripts `.sh` e comandos usados são específicos do Windows.【F:start.bat†L34-L320】【99229e†L1-L1】 |
| macOS Intel/ARM | ❌ Não suportado | Mesmo problema do Ubuntu; ausência total de automação para macOS. |

---

# Plano de Ação — Fase 2

## 1. Backlog priorizado (P0 → P2)

| Prioridade | Título | Evidência | Proposta | Riscos | Esforço | DoD | Teste de aceitação |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P0 | Empacotar runtimes portáteis (PHP, Composer, MariaDB) | 【F:php/php.exe†L1-L3】【F:mariadb/bin/mysqld.exe†L1-L3】 | Publicar pacote com binários reais + verificação de integridade (hash) no launcher. | Tamanho do bundle e licenças. | Alto | `start` roda sem erros offline; hashes validados. | Executar `start` em máquina limpa sem Internet → serviços sobem com portas exibidas. |
| P0 | Launchers multiplataforma | 【F:start.bat†L34-L320】【99229e†L1-L1】 | Criar `start.ps1` e `start.sh` reutilizando lógica de portas, `.env` e MariaDB. | Divergência entre implementações. | Alto | Scripts novos executam checklist completo (DB, app) em Win/Linux/mac. | Rodar cada launcher em seu SO e validar URL final exibida. |
| P0 | Scaffold offline de projetos Laravel | 【F:create_project.bat†L92-L99】 | Incluir skeleton Laravel 12 pré-instalado (vendor, node_modules opcional) + script de cópia. | Manter skeleton atualizado. | Médio | Novo projeto criado sem Internet em <30s. | Executar `create_project_offline` → abrir app com migrations rodando. |
| P1 | Credenciais seguras para MariaDB | 【F:start.bat†L180-L186】 | Criar usuário `demo_{hash}` com senha forte gerada uma vez e armazenada no pendrive. | Perda de senha → exigir regeneração guiada. | Médio | `.env` usa usuário dedicado; root fica desabilitado para acesso remoto. | Conectar com credenciais geradas; root falha. |
| P1 | Execução não interativa | 【F:start.bat†L141-L217】【F:start.bat†L248-L279】 | Adicionar parâmetros `--auto`, `--project=<nome>` e defaults seguros (migrations automáticas). | Manter UX em modo interativo. | Médio | Script conclui bootstrap sem prompts quando chamado com `--auto`. | Executar `start.bat --auto` → URL impressa sem perguntas. |
| P1 | Servidor HTTP robusto | 【F:start.bat†L282-L285】 | Empacotar Caddy/NGINX configurado para 127.0.0.1 + HTTPS opcional. | Mais consumo de RAM/disco. | Médio | App responde via servidor dedicado; `artisan serve` fica restrito a `dev`. | Rodar smoke test via `curl https://127.0.0.1:<porta>` com certificado local. |
| P2 | Documentação por SO + guia de aula | 【F:'LEIA ESTA MERDA.txt'†L1-L48】 | Substituir texto ofensivo por README estruturado (Win/Linux/mac) + troubleshooting. | Manter docs sincronizados com scripts. | Médio | README publicado com passos ilustrados e tabelas de portas. | Abrir README → contém instruções claras; estudantes reproduzem sem suporte extra. |
| P2 | Provisionamento da pasta `projetos` | 【F:start.bat†L82-L87】 | Criar diretório vazio com README e lógica de autocorreção no launcher. | Pouco. | Baixo | `start` cria pasta automaticamente se ausente. | Excluir pasta `projetos` e executar `start` → pasta recriada sem erro. |

## 2. Sugestões de refatoração (exemplos)

### a) Scaffold offline (`create_project.bat`)
- **Atual**
  ```bat
  "%PHP_EXE%" "%COMPOSER_PHAR%" create-project --prefer-dist laravel/laravel "%DESTINO%" "12.*"
  ```
  【F:create_project.bat†L92-L94】
- **Proposto**
  ```bat
  robocopy "%BASE%skeleton-laravel12" "%DESTINO%" /MIR
  call "%DESTINO%\vendor\bin\composer.bat" dump-autoload --optimize
  ```
  - Copia skeleton pré-bundle e recompila autoload localmente.

### b) Execução não interativa (`start.bat`)
- **Atual**
  ```bat
  set /P "RUNMIG=Deseja CRIAR o banco '%NOME_PROJETO%' e rodar migrations? [S/n] "
  ```
  【F:start.bat†L248-L273】
- **Proposto**
  ```bat
  if /I "%AUTO_MODE%"=="1" (
      set "RUNMIG=s"
  ) else (
      set /P "RUNMIG=..."
  )
  ```
  - Permite modo automático sem prompts.

### c) Credenciais de banco
- **Atual**
  ```bat
  echo DB_USERNAME=root >> ".env.temp"
  echo DB_PASSWORD= >> ".env.temp"
  ```
  【F:start.bat†L185-L186】
- **Proposto**
  ```bat
  echo DB_USERNAME=!DB_USER! >> ".env.temp"
  echo DB_PASSWORD=!DB_PASS! >> ".env.temp"
  ```
  - `!DB_USER!` e `!DB_PASS!` gerados uma única vez e persistidos em `config\portable.ini`.

## 3. Quality gates offline-friendly
- **Formatação**: `vendor/bin/pint` (pré-empacotado) para PSR-12.
- **Análise estática**: `vendor/bin/phpstan analyse --memory-limit=512M` (nível 5), usando dependências embarcadas.
- **Testes**: `php artisan test` ou `vendor/bin/pest` em modo demo/dev (dados seed).
- **Composer**: `composer validate` e `composer dump-autoload --optimize` executados localmente a partir do bundle.
- **Cache**: `php artisan config:clear && php artisan config:cache` após atualizar `.env`; scripts devem chamar `config:clear` automaticamente (já ajustado para APP_URL/DB_PORT).【F:start.bat†L240-L241】

## 4. PRs / patches iniciais (executados agora)
- Implementada seleção automática de portas livres para MariaDB e servidor Laravel com fallback em faixas configuráveis, bloqueando execução quando nenhuma porta é encontrada.【F:start.bat†L14-L50】【F:start.bat†L210-L220】
- Atualização dinâmica de `.env` com `DB_PORT`, `DB_DATABASE` e `APP_URL` alinhados ao ambiente escolhido, incluindo limpeza de cache de configuração após a troca.【F:start.bat†L176-L205】【F:start.bat†L230-L242】
- Novo fluxo de erro centralizado (`:fatal`) com mensagens claras quando binários ou portas estão indisponíveis, preparando terreno para um checklist de pré-execução.【F:start.bat†L18-L80】【F:start.bat†L286-L323】

## 5. Guia rápido — "Uso em Aula"
1. Executar `setup.bat` uma vez para validar PHP/Composer portáteis.【F:setup.bat†L1-L40】
2. Rodar `start.bat`; o script agora verifica binários, escolhe portas livres e atualiza o `.env` do projeto automaticamente.【F:start.bat†L18-L242】
3. Selecionar o projeto desejado na lista; confirmar se migrations devem rodar e, se necessário, abrir console MariaDB em outra janela.【F:start.bat†L124-L279】
4. Aguardar a exibição da URL final (`http://127.0.0.1:<porta>`). Copiar para o navegador do laboratório e iniciar a aula.【F:start.bat†L210-L285】
5. Ao encerrar a demo, fechar a janela do servidor (`Ctrl+C`) e parar o MariaDB manualmente (todo). Futuro sprint cuidará de `stop.bat` com encerramento seguro.

