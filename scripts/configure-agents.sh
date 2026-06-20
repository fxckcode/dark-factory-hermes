#!/bin/bash
# ============================================================
# Bootstrap — configura Hermes + coding agents en el contenedor
# ============================================================
# Ejecutar UNA vez despues del primer deploy:
#   docker exec dani_hermes configure-agents
#
# Idempotente: si ya esta configurado, no hace nada.
# ============================================================
set -e

echo "=== Configurando Dark Factory ==="

# ============================================================
# 1. Engram MCP en Hermes
# ============================================================
if command -v engram &>/dev/null && command -v hermes &>/dev/null; then
    if hermes mcp list 2>/dev/null | grep -q engram; then
        echo "[engram] MCP server ya registrado en Hermes"
    else
        echo "[engram] Registrando engram como MCP server en Hermes..."
        hermes mcp add engram --command engram
        echo "[engram] Listo — Hermes ahora tiene memoria persistente via engram"
    fi
else
    echo "[engram] engram o hermes no encontrados, saltando..."
fi

# ============================================================
# 2. OpenCode — verifica env vars
# ============================================================
if command -v opencode &>/dev/null; then
    echo "[opencode] Verificando API keys..."
    [ -n "${OPENROUTER_API_KEY}" ] && echo "  OPENROUTER_API_KEY: OK" || echo "  OPENROUTER_API_KEY: FALTA"
    [ -n "${ANTHROPIC_API_KEY}" ]   && echo "  ANTHROPIC_API_KEY:   OK" || echo "  ANTHROPIC_API_KEY:   FALTA"
    [ -n "${DEEPSEEK_API_KEY}" ]    && echo "  DEEPSEEK_API_KEY:    OK" || echo "  DEEPSEEK_API_KEY:    FALTA"
    [ -n "${OPENCODE_GO_API_KEY}" ] && echo "  OPENCODE_GO_API_KEY: OK" || echo "  OPENCODE_GO_API_KEY: FALTA"
fi

# ============================================================
# 3. Claude Code + cmd
# ============================================================
command -v claude &>/dev/null && echo "[claude] Instalado — usa ANTHROPIC_API_KEY" || echo "[claude] No instalado"
command -v cmd    &>/dev/null && echo "[cmd]    Instalado — usa OPENROUTER_API_KEY" || echo "[cmd]    No instalado"

# ============================================================
# 4. GitHub CLI
# ============================================================
if command -v gh &>/dev/null && [ -n "${GH_TOKEN}" ]; then
    if gh auth status &>/dev/null 2>&1; then
        echo "[gh] Ya autenticado"
    else
        echo "[gh] Configurando auth..."
        echo "${GH_TOKEN}" | gh auth login --with-token 2>/dev/null && echo "[gh] Autenticado" || echo "[gh] Fallo la autenticacion"
    fi
fi

# ============================================================
# 5. Git config
# ============================================================
git config --global user.name "${GIT_AUTHOR_NAME:-fxckcode}" 2>/dev/null || true
git config --global user.email "${GIT_AUTHOR_EMAIL:-diego@duran.co}" 2>/dev/null || true
echo "[git] user.name=$(git config --global user.name)"
echo "[git] user.email=$(git config --global user.email)"

echo ""
echo "=== Dark Factory lista ==="
echo "Hermes:  orquestador (SDD + memoria engram + delegacion)"
echo "Claude:  ejecutor via ANTHROPIC_API_KEY"
echo "cmd:     ejecutor via OPENROUTER_API_KEY"
echo "OpenCode: ejecutor multi-provider"
