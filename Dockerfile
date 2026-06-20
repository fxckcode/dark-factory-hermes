# ============================================================
# Dark Factory — Hermes Agent + Coding Agents
# ============================================================
# Extiende nousresearch/hermes-agent:latest
# Debian 13, Node 22, Python 3.13, s6-overlay
#
# Filosofia: Hermes es el cerebro (SDD + memoria + orquestacion).
# Claude Code, cmd, y OpenCode son las manos (solo ejecutan).
# ============================================================

FROM nousresearch/hermes-agent:latest

# 1. System deps
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git curl ca-certificates gnupg \
    && rm -rf /var/lib/apt/lists/*

# 2. Claude Code (Anthropic) — ejecutor
RUN npm install -g @anthropic-ai/claude-code@latest

# 3. Command Code (OpenRouter) — ejecutor
RUN npm install -g command-code@latest

# 4. OpenCode — ejecutor
RUN curl -fsSL https://raw.githubusercontent.com/anomalyco/opencode/refs/heads/dev/install | bash && \
    mv /root/.opencode/bin/opencode /usr/local/bin/opencode && \
    chmod +x /usr/local/bin/opencode && \
    rm -rf /root/.opencode && \
    opencode version

# 5. pnpm
RUN npm install -g pnpm@latest

# 6. GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
          https://cli.github.com/packages stable main" | \
        tee /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/*

# 7. Engram — memoria MCP (Hermes lo usa via MCP nativo)
RUN curl -fsSL "https://github.com/Gentleman-Programming/engram/releases/download/v1.17.0/engram_1.17.0_linux_amd64.tar.gz" \
      -o /tmp/engram.tar.gz && \
    tar -xzf /tmp/engram.tar.gz -C /tmp && \
    mv /tmp/engram /usr/local/bin/engram && \
    chmod +x /usr/local/bin/engram && \
    rm /tmp/engram.tar.gz && \
    engram version

# 8. Bootstrap script — registra engram MCP en Hermes, gh, git
COPY scripts/configure-agents.sh /usr/local/bin/configure-agents
RUN chmod +x /usr/local/bin/configure-agents

# 9. Workspace directory
RUN mkdir -p /opt/workspaces && chown hermes:hermes /opt/workspaces

# 10. Cleanup
RUN npm cache clean --force
