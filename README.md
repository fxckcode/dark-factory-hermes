# Dark Factory — Hermes Agent en Dokploy

Configuracion para una dark factory de codigo autonoma.
Hermes corre 24/7 como gateway (Telegram) + API server,
y los coding agents (Claude Code, Command Code, OpenCode)
estan horneados en la imagen para implementar features
directamente a repos desde el contenedor.

## Filosofia: Hermes es el cerebro — los coding agents son las manos

| Tool | Rol | Auth |
|------|-----|------|
| **Hermes Agent** | 🧠 Orquestador — SDD, memoria, delegacion | OpenRouter |
| **Claude Code** | 🖐 Ejecutor | ANTHROPIC_API_KEY |
| **Command Code (cmd)** | 🖐 Ejecutor | OPENROUTER_API_KEY |
| **OpenCode** | 🖐 Ejecutor multi-provider | Env vars |
| **Engram** | 🧠 Memoria MCP para Hermes | N/A (SQLite local) |
| **GitHub CLI (gh)** | 🔧 Clonar, PRs, issues | GH_TOKEN |
| **pnpm** | 🔧 Package manager | N/A |

## Puertos expuestos

| Puerto | Servicio | Proposito |
|--------|----------|-----------|
| 8642 | API Server | Webhooks, MCP, conexiones externas |
| 9120 | Dashboard | Panel web de Hermes |

## Variables de entorno requeridas

| Variable | Para | Como obtenerla |
|----------|------|----------------|
| `OPENROUTER_API_KEY` | Hermes + cmd | https://openrouter.ai/keys |
| `TELEGRAM_BOT_TOKEN` | Recibir ordenes via Telegram | @BotFather en Telegram |
| `TELEGRAM_ALLOWED_USER_IDS` | Restringir acceso a tu user ID | @userinfobot en Telegram |
| `ANTHROPIC_API_KEY` | Claude Code | https://console.anthropic.com/ |
| `GH_TOKEN` | GitHub CLI (opcional) | GitHub Settings > Developer settings > Tokens |
| `GIT_AUTHOR_NAME` | Commits desde el container | Tu nombre (ej: "fxckcode") |
| `GIT_AUTHOR_EMAIL` | Commits desde el container | Tu email de GitHub |
| `GIT_COMMITTER_NAME` | Commits (fallback) | "fxckcode" |
| `GIT_COMMITTER_EMAIL` | Commits (fallback) | Tu email |

## Setup en Dokploy

1. Crea un proyecto nuevo en Dokploy apuntando a este repo
2. Dokploy detecta el `Dockerfile` y hace build automatico
3. Configura las env vars en el panel de "Environment" de Dokploy
4. Expone los puertos 8642 y 9120 en el panel de "Ports"
5. Deploy

## Workspaces (codigo)

Los coding agents necesitan acceso a tus repos para trabajar.
Dos opciones:

### Opcion A: Clonar en runtime (recomendado)

Con `GH_TOKEN` configurado, el agente puede clonar repos
directamente dentro del contenedor:

```
gh repo clone fxckcode/gymbro /opt/workspaces/gymbro
```

El codigo vive en el sistema de archivos del contenedor.
Si el contenedor se recrea, se pierde. Vuelve a clonar.

### Opcion B: Bind mount (persistente)

En Dokploy, crea un bind mount en el panel de "Volumes":

```
Host: /ruta/a/tus/proyectos
Container: /opt/workspaces
```

Esto persiste el codigo aunque el contenedor se recree.
Ideal si trabajas en los mismos repos frecuentemente.

## Persistencia

El volumen `dani_hermes_data:/opt/data` guarda:
- `config.yaml` y `.env` de Hermes
- Sesiones (SQLite en `state.db`)
- Skills instalados
- Memoria cross-session
- Logs del gateway

Los coding agents estan bakeados en la imagen por el Dockerfile.
Al hacer rebuild (ej: nueva version de Hermes), los agents se
reinstalan automaticamente desde la ultima version.

NO persisten en el volumen:
- Node.js, pnpm, npm global packages
- Coding agents (claude, cmd, opencode)
- System packages (git, curl, gh)

Todo eso se reinstala en cada build del Dockerfile.

## Recursos recomendados

| Uso | RAM | CPU |
|-----|-----|-----|
| Solo Hermes (gateway) | 2 GB | 1 core |
| Hermes + 1 coding agent | 4 GB | 2 cores |
| Hermes + 2-3 agents paralelo | 8 GB | 4 cores |

Configuracion actual: 4 GB / 2 cores.



## Post-deploy (una sola vez)

Despues del primer deploy, ejecuta esto para configurar los agents:

```bash
docker exec dani_hermes configure-agents
```

Esto registra los providers en OpenCode, autentica GitHub CLI,
y configura git con tu nombre/email. Es idempotente — podés
correrlo todas las veces que quieras.

Si preferis que Hermes mismo lo haga cuando necesite usar un agent,
simplemente decile: "ejecuta configure-agents".

## Como usarlo

Mandas una orden por Telegram o via API:

```
"Hermes, crea un CLI en Node.js para trackear habitos.
 Usa cmd -p para implementarlo. Repo: fxckcode/habit-tracker"
```

Hermes recibe, evalua que agent usar, delega la implementacion,
y reporta el resultado con link al PR o branch.

## Mantenimiento

```bash
# Ver logs
docker logs dani_hermes --tail 100

# Entrar al contenedor
docker exec -it dani_hermes bash

# Verificar coding agents
docker exec dani_hermes claude --version
docker exec dani_hermes cmd --version
docker exec dani_hermes opencode --version
```
