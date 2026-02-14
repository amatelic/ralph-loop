# Deployment Guide

Docker-based deployment for secure, isolated execution.

## Quick Start

```bash
# 1. Configure
cp .env.example .env
# Edit .env with PROJECT_NAME and API key

# 2. Build and run
docker-compose build && docker-compose up -d

# 3. Use
docker-compose exec ralph bash
./loop.sh planning
./loop.sh building
./loop.sh qa
```

## Docker Configuration

### docker-compose.yml

```yaml
version: '3.8'
services:
  ralph:
    build: .
    volumes:
      - ./:/workspace          # Entire ralph-loop directory
      - ~/.ssh:/root/.ssh:ro   # Git SSH keys (read-only)
    environment:
      - PROJECT_NAME=${PROJECT_NAME}
      - OPENCODE_API_KEY=${OPENCODE_API_KEY}
      - PROVIDER=${PROVIDER:-glm}
      - OPENCODE_MODEL=${OPENCODE_MODEL:-}
    working_dir: /workspace
    stdin_open: true
    tty: true
```

### Volume Mounts

| Mount | Purpose |
|-------|---------|
| `./:/workspace` | Project files, libs, configuration |
| `~/.ssh:/root/.ssh:ro` | Git authentication (read-only) |

## Environment Variables

### Required

| Variable | Description |
|----------|-------------|
| `PROJECT_NAME` | Project to work on |
| `OPENCODE_API_KEY` | API key for GLM provider |

### Provider Selection

| Variable | Values | Default |
|----------|--------|---------|
| `PROVIDER` | glm, claude, codex, kimmy_k2 | glm |
| `OPENCODE_MODEL` | glm-4.7, glm-5 | glm-4.7 |

### API Keys

| Variable | Provider |
|----------|----------|
| `OPENCODE_API_KEY` | GLM |
| `ANTHROPIC_API_KEY` | Claude |
| `OPENAI_API_KEY` | Codex |
| `KIMMY_K2_API_KEY` | Kimmy K2 |

### Example .env

```bash
PROJECT_NAME=my-app
PROVIDER=glm
OPENCODE_MODEL=glm-4.7
OPENCODE_API_KEY=your_key_here
```

## Running Commands

### Via docker-compose exec

```bash
docker-compose exec ralph bash
./loop.sh planning
./loop.sh building 10
./loop.sh qa
```

### Via docker-compose run

```bash
docker-compose run -e PROJECT_NAME=my-app ralph ./loop.sh planning
docker-compose run -e PROJECT_NAME=my-app -e MAX_ITERATIONS=10 ralph ./loop.sh building
```

## Project Persistence

Projects are stored in `projects/` directory:

```
projects/
├── my-app/
│   ├── specs/
│   ├── src/
│   ├── agents.md
│   ├── improvements.md
│   └── IMPLEMENTATION_PLAN.md
└── another-project/
    └── ...
```

Since `./:/workspace` is mounted, all project files persist on your host machine.

## Providers

### GLM (Default)

- **API Key**: `OPENCODE_API_KEY`
- **Endpoint**: `https://api.z.ai/api/coding/paas/v4/chat/completions`
- **Models**: `glm-4.7`, `glm-5`
- **Max Tokens**: 32768

### Claude

- **API Key**: `ANTHROPIC_API_KEY`
- **Endpoint**: `https://api.anthropic.com/v1/messages`
- **Model**: `claude-sonnet-4-20250514`
- **Max Tokens**: 16384

### Codex (OpenAI)

- **API Key**: `OPENAI_API_KEY`
- **Endpoint**: `https://api.openai.com/v1/chat/completions`
- **Model**: `gpt-4`
- **Max Tokens**: 16384

### Kimmy K2

- **API Key**: `KIMMY_K2_API_KEY`
- **Endpoint**: TBD

## Troubleshooting

### Container Issues

```bash
# Check logs
docker-compose logs ralph

# Rebuild
docker-compose build --no-cache

# Shell access
docker-compose exec ralph bash
```

### Permission Issues

```bash
# Fix permissions
sudo chown -R $USER:$USER .
```

### Project Not Found

```bash
# Verify PROJECT_NAME
echo $PROJECT_NAME

# List projects
ls -la projects/
```

### API Key Issues

```bash
# Verify key is set
docker-compose exec ralph env | grep API_KEY

# Check .env file
cat .env
```

### Loop Issues

```bash
# Regenerate plan (in project directory)
cd projects/my-app
rm IMPLEMENTATION_PLAN.md
cd ../..
./loop.sh planning
```

## Running Without Docker

```bash
# Set environment
export PROJECT_NAME=my-app
export OPENCODE_API_KEY=your_key

# Run directly
./loop.sh planning
./loop.sh building
./loop.sh qa
```

## Git Configuration

For automatic git operations:

```bash
# In container or host
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

Each project gets its own `.git` directory initialized automatically.
