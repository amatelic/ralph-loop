# Architecture

This document describes the architecture of Ralph Loop and how components interact.

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              RALPH LOOP SYSTEM                              │
└─────────────────────────────────────────────────────────────────────────────┘

                                 ┌──────────────┐
                                 │   loop.sh    │
                                 │  (Orchestrator) │
                                 └──────┬───────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
                    ▼                   ▼                   ▼
            ┌───────────────┐   ┌───────────────┐   ┌───────────────┐
            │   planning    │   │   building    │   │      qa       │
            │ PROMPT_planning│   │PROMPT_building│   │   PROMPT_qa   │
            └───────┬───────┘   └───────┬───────┘   └───────┬───────┘
                    │                   │                   │
                    └───────────────────┼───────────────────┘
                                        │
                                        ▼
                            ┌───────────────────────┐
                            │      agent.py         │
                            │   (Entry Point)       │
                            └───────────┬───────────┘
                                        │
            ┌───────────────────────────┼───────────────────────────┐
            │                           │                           │
            ▼                           ▼                           ▼
    ┌───────────────┐          ┌───────────────┐          ┌───────────────┐
    │  libs/config  │          │  libs/agent   │          │  libs/tools   │
    │               │          │               │          │               │
    │ • Config      │          │ • BaseAgent   │          │ • ToolRegistry│
    │ • get_provider│          │               │          │ • read_file   │
    │ • list_providers│        │               │          │ • write_file  │
    └───────┬───────┘          └───────┬───────┘          │ • edit_file   │
            │                          │                  │ • glob_search │
            │                          │                  │ • grep_search │
            │                          │                  │ • bash_command│
            │                          │                  └───────────────┘
            │                          │
            ▼                          │
    ┌───────────────┐                  │
    │libs/providers │◄─────────────────┘
    │               │
    │ ┌───────────┐ │
    │ │ BaseProvider│ │
    │ └─────┬─────┘ │
    │       │       │
    │ ┌─────┴─────┐ │
    │ │Providers  │ │
    │ │           │ │
    │ │ • glm     │ │──────► Z.AI API (glm-4.7, glm-5)
    │ │ • claude  │ │──────► Anthropic API
    │ │ • codex   │ │──────► OpenAI API
    │ │ • kimmy_k2│ │──────► (TBD)
    │ └───────────┘ │
    └───────────────┘
```

## Request Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            REQUEST FLOW                                     │
└─────────────────────────────────────────────────────────────────────────────┘

  User Input                Environment               Provider Selection
      │                          │                          │
      ▼                          ▼                          ▼
┌──────────┐              ┌──────────┐              ┌──────────────┐
│ ./loop.sh│              │  .env    │              │PROVIDER=xxx  │
│ building │              │ file     │              │OPENCODE_MODEL│
└────┬─────┘              └────┬─────┘              └──────┬───────┘
     │                         │                           │
     └─────────────────────────┼───────────────────────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │   Load PROMPT_file  │
                    │   (prompts/*.md)    │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │      agent.py       │
                    │                     │
                    │  1. Load Config     │
                    │  2. Select Provider │
                    │  3. Create Agent    │
                    └──────────┬──────────┘
                               │
     ┌─────────────────────────┼─────────────────────────┐
     │                         │                         │
     ▼                         ▼                         ▼
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   Config    │         │   Provider  │         │   Agent     │
│             │         │             │         │             │
│ Validate    │         │ GLMProvider │         │ BaseAgent   │
│ API Keys    │         │ ClaudeProvider│       │             │
│             │         │ CodexProvider│        │ • run()     │
└─────────────┘         │ KimmyK2Provider│      │ • tools     │
                        └─────────────┘         └─────────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │   API Request       │
                    │                     │
                    │  POST /chat/completions
                    │  or /messages       │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │   AI Provider       │
                    │   (Remote)          │
                    │                     │
                    │  Returns:           │
                    │  • Text response    │
                    │  • Tool calls       │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │   Parse Response    │
                    │                     │
                    │  Tool calls?        │
                    │  ┌───────┐ ┌───────┐│
                    │  │  Yes  │ │  No   ││
                    │  └───┬───┘ └───┬───┘│
                    │      │         │    │
                    │      ▼         │    │
                    │┌─────────────┐ │    │
                    ││Execute Tools│ │    │
                    ││             │ │    │
                    ││• read       │ │    │
                    ││• write      │ │    │
                    ││• edit       │ │    │
                    ││• bash       │ │    │
                    │└──────┬──────┘ │    │
                    │       │        │    │
                    │       ▼        │    │
                    │┌─────────────┐ │    │
                    ││Add result   │ │    │
                    ││to messages  │ │    │
                    │└──────┬──────┘ │    │
                    │       │        │    │
                    │       └────►───┘    │
                    │              │      │
                    │              ▼      │
                    │    ┌──────────────┐ │
                    │    │ Final Response│ │
                    │    └──────────────┘ │
                    └─────────────────────┘
```

## Component Details

### loop.sh (Orchestrator)

The main bash script that orchestrates the Ralph Loop:

```
┌─────────────────────────────────────────────────────────────────┐
│                         loop.sh                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │ Parse Args  │───►│ Load .env   │───►│ Validate    │         │
│  │             │    │             │    │ API Key     │         │
│  └─────────────┘    └─────────────┘    └──────┬──────┘         │
│                                                │                │
│                                                ▼                │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    MAIN LOOP                             │   │
│  │                                                          │   │
│  │   while iteration < max_iterations:                      │   │
│  │       │                                                  │   │
│  │       ├── Load PROMPT_file content                       │   │
│  │       │                                                  │   │
│  │       ├── Run: python3 agent.py "$prompt"                │   │
│  │       │                                                  │   │
│  │       ├── Check exit code                                │   │
│  │       │                                                  │   │
│  │       ├── [if building] git push                         │   │
│  │       │                                                  │   │
│  │       └── Update improvements.md                         │   │
│  │                                                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### libs/ Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                          libs/                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  config.py                 Provider Factory & Configuration     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ PROVIDER_REGISTRY = {                                    │   │
│  │   "glm": GLMProvider,      # glm-4.7, glm-5              │   │
│  │   "claude": ClaudeProvider,                              │   │
│  │   "codex": CodexProvider,                                │   │
│  │   "kimmy_k2": KimmyK2Provider,                           │   │
│  │ }                                                        │   │
│  │                                                          │   │
│  │ get_provider(name, api_key, model) → BaseProvider        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  agent/base.py             Core Agent Logic                    │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ BaseAgent                                                │   │
│  │   ├── provider: BaseProvider                             │   │
│  │   ├── tools: ToolRegistry                                │   │
│  │   ├── conversation_history: List                         │   │
│  │   │                                                      │   │
│  │   └── run(prompt) → Response                             │   │
│  │        ├── provider.chat(messages)                       │   │
│  │        ├── _parse_tool_calls(content)                    │   │
│  │        └── _execute_tool(name, args)                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  providers/                AI Provider Implementations          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ base.py ─── BaseProvider (abstract)                      │   │
│  │              ├── chat(messages) → Dict                   │   │
│  │              ├── get_model_name() → str                  │   │
│  │              └── get_max_tokens() → int                  │   │
│  │                                                          │   │
│  │ glm.py ──── GLMProvider                                  │   │
│  │              API: api.z.ai/api/coding/paas/v4            │   │
│  │              Models: glm-4.7, glm-5                      │   │
│  │              Max tokens: 32768                           │   │
│  │                                                          │   │
│  │ claude.py ─ ClaudeProvider                               │   │
│  │              API: api.anthropic.com/v1                   │   │
│  │              Max tokens: 16384                           │   │
│  │                                                          │   │
│  │ codex.py ── CodexProvider                                │   │
│  │              API: api.openai.com/v1                      │   │
│  │              Max tokens: 16384                           │   │
│  │                                                          │   │
│  │ kimmy_k2.py ─ KimmyK2Provider (placeholder)              │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  tools/tools.py            File & Command Tools                │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ ToolRegistry                                             │   │
│  │   └── _tools: Dict[str, Callable]                        │   │
│  │                                                          │   │
│  │ Functions:                                               │   │
│  │   read_file(path) → Dict                                 │   │
│  │   write_file(path, content) → Dict                       │   │
│  │   edit_file(path, old, new) → Dict                       │   │
│  │   glob_search(pattern, path) → Dict                      │   │
│  │   grep_search(pattern, path) → Dict                      │   │
│  │   bash_command(command, timeout) → Dict                  │   │
│  │   list_files(path) → Dict                                │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Mode Workflows

### Planning Mode

```
┌──────────────────────────────────────────────────────────────────┐
│                     PLANNING MODE FLOW                           │
└──────────────────────────────────────────────────────────────────┘

     ┌──────────────┐
     │   Start      │
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐      ┌─────────────────┐
     │ Read specs/* │─────►│ Learn app specs │
     └──────┬───────┘      └─────────────────┘
            │
            ▼
     ┌──────────────┐      ┌─────────────────┐
     │ Read src/*   │─────►│ Analyze code    │
     └──────┬───────┘      └─────────────────┘
            │
            ▼
     ┌──────────────┐      ┌─────────────────┐
     │ Gap Analysis │─────►│ Compare specs   │
     └──────┬───────┘      │ vs code         │
            │              └─────────────────┘
            ▼
     ┌──────────────┐
     │ Prioritize   │
     │ Tasks        │
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │ Update       │
     │IMPLEMENTATION│
     │  _PLAN.md    │
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │    End       │
     │  (No code    │
     │   written)   │
     └──────────────┘
```

### Building Mode

```
┌──────────────────────────────────────────────────────────────────┐
│                     BUILDING MODE FLOW                           │
└──────────────────────────────────────────────────────────────────┘

     ┌──────────────┐
     │   Start      │
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │ Read         │
     │IMPLEMENTATION│
     │  _PLAN.md    │
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │ Pick highest │
     │ priority task│
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐      ┌─────────────────┐
     │ Search code  │─────►│ Don't assume    │
     │ first        │      │ not implemented │
     └──────┬───────┘      └─────────────────┘
            │
            ▼
     ┌──────────────┐
     │ Implement    │
     │ feature      │
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐      ┌─────────────────┐
     │ Run tests    │─────►│ Follow agents.md│
     └──────┬───────┘      └─────────────────┘
            │
      ┌─────┴─────┐
      │ Tests OK? │
      └─────┬─────┘
       No   │   Yes
       ┌────┘   └────┐
       │             │
       ▼             ▼
┌────────────┐ ┌────────────┐
│ Fix issues │ │ git add -A │
└─────┬──────┘ │ git commit │
      │        └─────┬──────┘
      │              │
      └─────►────────┘
              │
              ▼
       ┌────────────┐
       │ Update     │
       │improvements│
       │    .md     │
       └─────┬──────┘
             │
             ▼
       ┌────────────┐
       │ Create git │
       │   tag      │
       └────────────┘
```

### QA Mode

```
┌──────────────────────────────────────────────────────────────────┐
│                        QA MODE FLOW                              │
└──────────────────────────────────────────────────────────────────┘

     ┌──────────────┐
     │   Start      │
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │ Run all      │
     │ test suites  │
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │ Run lint &   │
     │ typecheck    │
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │ Build app    │
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │ Code review  │
     │ & security   │
     │ analysis     │
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │ Categorize   │
     │ issues:      │
     │ • Critical   │
     │ • High       │
     │ • Medium     │
     │ • Low        │
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │ Generate     │
     │ QA report in │
     │improvements.md│
     └──────────────┘
```

## File Structure

```
ralph-loop/
│
├── loop.sh                    # Main orchestrator script
├── agent.py                   # Agent entry point
├── docker-compose.yml         # Docker configuration
├── Dockerfile                 # Container build
├── .env.example               # Environment template
├── README.md                  # Project documentation
├── ARCHITECTURE.md            # This file
├── DEPLOYMENT.md              # Deployment guide
│
├── libs/                      # Core libraries
│   ├── __init__.py
│   ├── config.py              # Provider factory & config
│   │
│   ├── agent/
│   │   ├── __init__.py
│   │   └── base.py            # BaseAgent class
│   │
│   ├── providers/
│   │   ├── __init__.py
│   │   ├── base.py            # BaseProvider interface
│   │   ├── glm.py             # Z.AI GLM (glm-4.7, glm-5)
│   │   ├── claude.py          # Anthropic Claude
│   │   ├── codex.py           # OpenAI Codex
│   │   └── kimmy_k2.py        # Kimmy K2 (placeholder)
│   │
│   └── tools/
│       ├── __init__.py
│       └── tools.py           # File & command tools
│
└── projects/                  # User projects (created by Ralph)
    └── <project_name>/        # Each project has its own directory
        ├── specs/             # Project specifications
        ├── src/               # Project source code
        ├── agents.md          # Build/test commands
        ├── improvements.md    # State tracking
        ├── IMPLEMENTATION_PLAN.md  # Generated task list
        └── .git/              # Git repository
```
