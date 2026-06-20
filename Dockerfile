# ============================================================
# Dark Factory — Hermes Agent + Stack de coding agents
# ============================================================
# Extiende nousresearch/hermes-agent:latest
# Debian 13, Node 22, Python 3.13, s6-overlay
# ============================================================

FROM nousresearch/hermes-agent:latest

# 1. System deps
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git curl ca-certificates gnupg \
    && rm -rf /var/lib/apt/lists/*

# 2. Claude Code (Anthropic)
RUN npm install -g @anthropic-ai/claude-code@latest

# 3. Command Code (OpenRouter)
RUN npm install -g command-code@latest

# 4. OpenCode
RUN curl -fsSL https://raw.githubusercontent.com/anomalyco/opencode/refs/heads/dev/install | bash

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

# 7. Engram — memoria MCP para agents
RUN curl -fsSL "https://github.com/Gentleman-Programming/engram/releases/download/v1.17.0/engram_1.17.0_linux_amd64.tar.gz" \
      -o /tmp/engram.tar.gz && \
    tar -xzf /tmp/engram.tar.gz -C /tmp && \
    mv /tmp/engram /usr/local/bin/engram && \
    chmod +x /usr/local/bin/engram && \
    rm /tmp/engram.tar.gz && \
    engram version

# 7b. Gentle-AI — ecosystem configurator (SDD, skills, engram MCP)
# Inyecta SDD sub-agents, skills, persona, y cablea engram MCP
# en Claude Code, OpenCode, y otros agents.
RUN curl -fsSL "https://github.com/Gentleman-Programming/gentle-ai/releases/download/v1.41.0/gentle-ai_1.41.0_linux_amd64.tar.gz" \
      -o /tmp/gentle-ai.tar.gz && \
    tar -xzf /tmp/gentle-ai.tar.gz -C /tmp && \
    mv /tmp/gentle-ai /usr/local/bin/gentle-ai && \
    chmod +x /usr/local/bin/gentle-ai && \
    rm /tmp/gentle-ai.tar.gz && \
    gentle-ai version 2>/dev/null || echo "gentle-ai v1.41.0 installed"




# 8. Gentle-AI assets — SDD agents, skills, persona, engram MCP
# Descargamos el repo como tarball (mas rapido que git clone)
# y copiamos los assets a /opt/data para que persistan.
RUN mkdir -p /opt/data/.claude/agents \
             /opt/data/.claude/commands \
             /opt/data/.claude/mcp \
             /opt/data/.claude/output-styles \
             /opt/data/.claude/skills && \
    mkdir -p /opt/data/.config/opencode/commands \
             /opt/data/.config/opencode/plugins && \
    curl -fsSL https://github.com/Gentleman-Programming/gentle-ai/archive/refs/heads/main.tar.gz | \
      tar -xz -C /tmp && \
    SRC=/tmp/gentle-ai-main/internal/assets && \
    cp $SRC/claude/agents/*.md /opt/data/.claude/agents/ && \
    cp $SRC/claude/commands/*.md /opt/data/.claude/commands/ && \
    cp $SRC/claude/persona-gentleman.md /opt/data/.claude/CLAUDE.md && \
    cp $SRC/claude/sdd-orchestrator.md /opt/data/.claude/ && \
    cp $SRC/claude/engram-protocol.md /opt/data/.claude/ && \
    cp $SRC/claude/output-style-*.md /opt/data/.claude/output-styles/ && \
    cp $SRC/opencode/persona-gentleman.md /opt/data/.config/opencode/ && \
    cp $SRC/opencode/sdd-orchestrator.md /opt/data/.config/opencode/ && \
    cp $SRC/opencode/sdd-overlay-*.json /opt/data/.config/opencode/ && \
    cp $SRC/opencode/commands/*.md /opt/data/.config/opencode/commands/ && \
    cp -r $SRC/opencode/plugins/* /opt/data/.config/opencode/plugins/ && \
    echo '{"mcpServers":{"engram":{"command":"engram","args":["mcp"]}}}' \
      > /opt/data/.claude/mcp/engram.json && \
    rm -rf /tmp/gentle-ai-main && \
    chown -R hermes:hermes /opt/data/.claude /opt/data/.config && \
    echo "Gentle-AI assets baked: $(ls /opt/data/.claude/agents/ | wc -l) agents"


# 9. Bootstrap script — configura agents en runtime
COPY scripts/configure-agents.sh /usr/local/bin/configure-agents
RUN chmod +x /usr/local/bin/configure-agents

# 10. Workspace directory
RUN mkdir -p /opt/workspaces && chown hermes:hermes /opt/workspaces

# 11. Cleanup
RUN npm cache clean --force
