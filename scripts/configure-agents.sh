#!/bin/bash
# ============================================================
# Bootstrap — configura los coding agents en el contenedor
# ============================================================
# Ejecutar UNA vez despues del primer deploy:
#   docker exec dani_hermes /opt/data/scripts/configure-agents.sh
#
# O Hermes puede ejecutarlo via terminal tool.
# Es idempotente: si ya esta configurado, no hace nada.
# ============================================================
set -e

echo "=== Configurando coding agents ==="

# --- OpenCode ---
if command -v opencode &>/dev/null; then
    echo "[opencode] Verificando providers..."

    # OpenRouter (para cmd/hermes)
    if [ -n "${OPENROUTER_API_KEY}" ]; then
        if opencode auth list 2>/dev/null | grep -q openrouter; then
            echo "[opencode] openrouter ya configurado"
        else
            echo "[opencode] Registrando openrouter..."
            opencode auth add openrouter --api-key "${OPENROUTER_API_KEY}"
        fi
    fi

    # Anthropic (para Claude)
    if [ -n "${ANTHROPIC_API_KEY}" ]; then
        if opencode auth list 2>/dev/null | grep -q anthropic; then
            echo "[opencode] anthropic ya configurado"
        else
            echo "[opencode] Registrando anthropic..."
            opencode auth add anthropic --api-key "${ANTHROPIC_API_KEY}"
        fi
    fi

    # DeepSeek
    if [ -n "${DEEPSEEK_API_KEY}" ]; then
        if opencode auth list 2>/dev/null | grep -q deepseek; then
            echo "[opencode] deepseek ya configurado"
        else
            echo "[opencode] Registrando deepseek..."
            opencode auth add deepseek --api-key "${DEEPSEEK_API_KEY}"
        fi
    fi

    # OpenCode Go (el provider que usas actualmente)
    if [ -n "${OPENCODE_GO_API_KEY}" ]; then
        if opencode auth list 2>/dev/null | grep -q opencode-go; then
            echo "[opencode] opencode-go ya configurado"
        else
            echo "[opencode] Registrando opencode-go..."
            opencode auth add opencode-go --api-key "${OPENCODE_GO_API_KEY}"
        fi
    fi
else
    echo "[opencode] No instalado, saltando..."
fi

# --- Claude Code ---
if command -v claude &>/dev/null; then
    echo "[claude] Instalado — usa ANTHROPIC_API_KEY del entorno"
fi

# --- Command Code ---
if command -v cmd &>/dev/null; then
    echo "[cmd] Instalado — usa OPENROUTER_API_KEY del entorno"
fi

# --- Engram ---
if command -v engram &>/dev/null; then
    echo "[engram] Instalado y listo"
fi

# --- GitHub CLI ---
if command -v gh &>/dev/null && [ -n "${GH_TOKEN}" ]; then
    if gh auth status &>/dev/null 2>&1; then
        echo "[gh] Ya autenticado"
    else
        echo "[gh] Configurando auth con GH_TOKEN..."
        echo "${GH_TOKEN}" | gh auth login --with-token
    fi
fi

# --- Git config ---
git config --global user.name "${GIT_AUTHOR_NAME:-fxckcode}" 2>/dev/null || true
git config --global user.email "${GIT_AUTHOR_EMAIL:-diego@duran.co}" 2>/dev/null || true
echo "[git] user.name=$(git config --global user.name)"
echo "[git] user.email=$(git config --global user.email)"

echo "=== Configuracion completa ==="
