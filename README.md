# Ralph Loop - Multi-Provider AI Development Loop

Autonomous AI-driven development using Ralph Wiggum technique with multi-provider support.

**Features:**
- Multi-provider support: GLM-4.7, Claude, Codex, Kimmy K2
- Three independent commands: `planning`, `building`, `qa`
- Docker isolation for safe autonomous execution
- Auto-updates `improvements.md` with progress
- Auto-generates implementation plans
- Git integration with automatic tagging

## Quick Start

```bash
# 1. Configure environment
cp .env.example .env
# Edit .env with your API key and provider

# 2. Initialize Git
git init && git add . && git commit -m "Initial commit"

# 3. Build and Start (Docker)
docker-compose build && docker-compose up -d

# 4. Run Ralph Loop
docker-compose exec ralph bash
./loop.sh planning     # Generate implementation plan
./loop.sh building      # Build the application
./loop.sh qa            # Quality assurance
```

## Providers

| Provider | Env Variable | Description |
|----------|-------------|-------------|
| `glm47` | `OPENCODE_API_KEY` | GLM-4.7 via Z.AI (default) |
| `claude` | `ANTHROPIC_API_KEY` | Anthropic Claude |
| `codex` | `OPENAI_API_KEY` | OpenAI GPT-4 |
| `kimmy_k2` | `KIMMY_K2_API_KEY` | Kimmy K2 (placeholder) |

Set provider with `PROVIDER=claude` in `.env` or environment.

## Commands

### Planning Mode
Generates/updates implementation plan from specs vs code.
```bash
./loop.sh planning [max_iterations]
```

### Building Mode
Implements tasks from plan, commits changes.
```bash
./loop.sh building [max_iterations]
```

### QA Mode
Full quality gate: tests, code review, security, performance.
```bash
./loop.sh qa [max_iterations]
```

### Test Setup
Validates configuration without running loop.
```bash
./loop.sh test
```

## Project Structure

```
├── loop.sh              # Main loop script
├── glm47_agent.py       # Agent entry point
├── libs/                # Core libraries
│   ├── config.py        # Provider factory & config
│   ├── agent/           # Agent framework
│   ├── providers/       # AI provider implementations
│   └── tools/           # File/command tools
├── prompts/             # Mode-specific instructions
├── specs/               # Application specifications
│   └── deployment.md    # Deployment documentation
├── agents.md            # Build/test commands
├── improvements.md      # State tracking log
└── IMPLEMENTATION_PLAN.md # Generated task list
```

## Workflow

1. Write specs in `specs/*.md`
2. Run `./loop.sh planning` to generate plan
3. Run `./loop.sh building` to implement
4. Run `./loop.sh qa` to validate
5. Repeat 2-4 as needed

## Detailed Documentation

- **Architecture**: See `ARCHITECTURE.md` for system diagrams and component details
- **Deployment**: See `specs/deployment.md` for Docker setup, environment variables, and troubleshooting
- **Writing Specs**: See `specs/README.md`
- **Getting Started**: See `prompts/GETTING_STARTED.md`

## Philosophy

- **Let Ralph Ralph**: Trust the AI to self-correct
- **Fresh Context**: Each iteration starts fresh
- **Plan is Disposable**: Regenerate if wrong
- **Backpressure**: Tests guardrail the implementation
- **Observe and Adjust**: Watch the loop, add guardrails as needed

## License

MIT License
