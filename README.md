# Ralph Loop - Multi-Provider AI Development Loop

Autonomous AI-driven development using Ralph Wiggum technique with multi-provider support.

**Features:**
- Project-based workflow: Each project gets its own directory
- Multi-provider support: GLM (glm-4.7, glm-5), Claude, Codex, Kimmy K2
- Three independent commands: `planning`, `building`, `qa`
- Docker isolation for secure execution
- Auto-generates specs from project description
- Auto-updates `improvements.md` with progress
- Git integration with automatic tagging

## Quick Start

```bash
# 1. Configure environment
cp .env.example .env
# Edit .env with PROJECT_NAME and your API key

# 2. Build and Start (Docker)
docker-compose build && docker-compose up -d

# 3. Run Ralph Loop
docker-compose exec ralph bash
./loop.sh planning     # Generate implementation plan
./loop.sh building      # Build the application
./loop.sh qa            # Quality assurance
```

## Project Structure

Ralph Loop creates and manages projects in the `projects/` directory:

```
ralph-loop/
├── loop.sh              # Main loop script
├── agent.py             # Agent entry point
├── libs/                # Core libraries
├── projects/            # YOUR PROJECTS LIVE HERE
│   └── my-app/          # Example project
│       ├── specs/       # Project specifications
│       ├── src/         # Project source code
│       ├── agents.md    # Build/test commands
│       ├── improvements.md
│       └── IMPLEMENTATION_PLAN.md
└── .env                 # Configuration
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PROJECT_NAME` | Project to work on (required) | - |
| `PROVIDER` | AI provider (glm, claude, codex, kimmy_k2) | `glm` |
| `OPENCODE_MODEL` | Model override (glm-4.7, glm-5) | `glm-4.7` |
| `OPENCODE_API_KEY` | API key for GLM | - |
| `ANTHROPIC_API_KEY` | API key for Claude | - |
| `OPENAI_API_KEY` | API key for OpenAI | - |

### Example .env

```bash
PROJECT_NAME=my-app
PROVIDER=glm
OPENCODE_MODEL=glm-4.7
OPENCODE_API_KEY=your_key_here
```

## Providers

| Provider | Env Variable | Models | Description |
|----------|-------------|--------|-------------|
| `glm` | `OPENCODE_API_KEY` | glm-4.7, glm-5 | GLM via Z.AI (default) |
| `claude` | `ANTHROPIC_API_KEY` | claude-sonnet-4 | Anthropic Claude |
| `codex` | `OPENAI_API_KEY` | gpt-4 | OpenAI GPT-4 |
| `kimmy_k2` | `KIMMY_K2_API_KEY` | TBD | Kimmy K2 (placeholder) |

## Commands

### Planning Mode
Generates implementation plan. If no specs exist, prompts for project description.
```bash
PROJECT_NAME=my-app ./loop.sh planning [max_iterations]
```

### Building Mode
Implements tasks from plan, commits changes.
```bash
PROJECT_NAME=my-app ./loop.sh building [max_iterations]
```

### QA Mode
Full quality gate: tests, code review, security, performance.
```bash
PROJECT_NAME=my-app ./loop.sh qa [max_iterations]
```

### Test Setup
Validates configuration and project setup.
```bash
PROJECT_NAME=my-app ./loop.sh test
```

## Workflow

```
┌──────────────────────────────────────────────────────────────────┐
│                      WORKFLOW                                     │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. Set PROJECT_NAME in .env                                    │
│          │                                                       │
│          ▼                                                       │
│  2. ./loop.sh planning                                          │
│          │                                                       │
│          ├── If no specs: Prompt for project description        │
│          │                                                       │
│          └── Generate IMPLEMENTATION_PLAN.md                    │
│          │                                                       │
│          ▼                                                       │
│  3. ./loop.sh building                                          │
│          │                                                       │
│          └── Build project in projects/<NAME>/src/              │
│          │                                                       │
│          ▼                                                       │
│  4. ./loop.sh qa                                                │
│          │                                                       │
│          └── Validate and report                                │
│          │                                                       │
│          ▼                                                       │
│  5. Repeat 2-4 as needed                                        │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## Detailed Documentation

- **Architecture**: See `ARCHITECTURE.md` for system diagrams and component details
- **Deployment**: See `specs/deployment.md` for Docker setup and troubleshooting

## Philosophy

- **Let Ralph Ralph**: Trust the AI to self-correct
- **Fresh Context**: Each iteration starts fresh
- **Plan is Disposable**: Regenerate if wrong
- **Backpressure**: Tests guardrail the implementation
- **Observe and Adjust**: Watch the loop, add guardrails as needed

## License

MIT License
