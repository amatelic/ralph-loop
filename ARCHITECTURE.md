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
                            │    glm47_agent.py     │
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
    │ │ • glm47   │ │──────► Z.AI API
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
│ building │              │ file     │              │              │
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
                    │   glm47_agent.py    │
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
│ Validate    │         │ GLM47Provider│        │ BaseAgent   │
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
│  │       ├── Run: python3 glm47_agent.py "$prompt"          │   │
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
│  │   "glm47": GLM47Provider,                                │   │
│  │   "claude": ClaudeProvider,                              │   │
│  │   "codex": CodexProvider,                                │   │
│  │   "kimmy_k2": KimmyK2Provider,                           │   │
│  │ }                                                        │   │
│  │                                                          │   │
│  │ get_provider(name, api_key) → BaseProvider               │   │
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
│  │              └── get_model_name() → str                  │   │
│  │                                                          │   │
│  │ glm47.py ── GLM47Provider                                │   │
│  │              API: api.z.ai/api/coding/paas/v4            │   │
│  │              Auth: Bearer token                          │   │
│  │                                                          │   │
│  │ claude.py ─ ClaudeProvider                               │   │
│  │              API: api.anthropic.com/v1                   │   │
│  │              Auth: x-api-key header                      │   │
│  │                                                          │   │
│  │ codex.py ── CodexProvider                                │   │
│  │              API: api.openai.com/v1                      │   │
│  │              Auth: Bearer token                          │   │
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
├── glm47_agent.py             # Agent entry point
├── docker-compose.yml         # Docker configuration
├── Dockerfile                 # Container build
├── .env.example               # Environment template
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
│   │   ├── glm47.py           # Z.AI GLM-4.7
│   │   ├── claude.py          # Anthropic Claude
│   │   ├── codex.py           # OpenAI Codex
│   │   └── kimmy_k2.py        # Kimmy K2 (placeholder)
│   │
│   └── tools/
│       ├── __init__.py
│       └── tools.py           # File & command tools
│
├── prompts/                   # Mode-specific prompts
│   ├── PROMPT_planning.md
│   ├── PROMPT_building.md
│   ├── PROMPT_qa.md
│   └── GETTING_STARTED.md
│
├── specs/                     # Application specifications
│   ├── README.md
│   ├── deployment.md          # Deployment docs
│   └── chrome-extension.md    # Example spec
│
├── agents.md                  # Build/test commands
├── improvements.md            # State tracking
└── IMPLEMENTATION_PLAN.md     # Generated task list
```
