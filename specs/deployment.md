# Deployment Specification

This document covers all deployment-related configuration for Ralph Loop.

## Docker Setup

### Building and Running

```bash
# Build Docker image
docker-compose build

# Start container in detached mode
docker-compose up -d

# Run inside Docker container
docker-compose exec ralph bash
./loop.sh planning     # Generate implementation plan
./loop.sh building      # Build the application
./loop.sh qa            # Quality assurance

# Or run directly via docker-compose
MODE=planning docker-compose up ralph
MODE=building MAX_ITERATIONS=20 docker-compose up ralph
MODE=qa docker-compose up ralph
```

### Dockerfile Configuration

The Dockerfile uses a multi-runtime base image with both Node.js and Python:
- Base: `node:20-bookworm-slim`
- Python 3.12 installed from source
- Build dependencies included

### Volume Mounts

```yaml
volumes:
  - ./:/workspace              # Project files
  - ~/.ssh:/root/.ssh:ro       # Git SSH keys (read-only)
```

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `OPENCODE_API_KEY` | Z.AI API key for GLM-4.7 | `your_zai_key` |

### Provider-Specific

| Variable | Description | Provider |
|----------|-------------|----------|
| `ANTHROPIC_API_KEY` | Anthropic API key | Claude |
| `OPENAI_API_KEY` | OpenAI API key | Codex |
| `KIMMY_K2_API_KEY` | Kimmy K2 API key | Kimmy K2 |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `PROVIDER` | AI provider to use | `glm47` |
| `MAX_ITERATIONS` | Max loop iterations (0 = unlimited) | `0` |
| `OPENCODE_MODEL` | Model override | `zai/glm-4.7` |
| `OPENCODE_PERMISSION` | Permission mode | `allow` |

### Configuration File

Create `.env` from example:
```bash
cp .env.example .env
# Edit .env with your API keys
```

Example `.env`:
```bash
# Required - GLM-4.7 provider
OPENCODE_API_KEY=your_zai_api_key_here

# Optional - Other providers
ANTHROPIC_API_KEY=your_anthropic_key_here
OPENAI_API_KEY=your_openai_key_here
KIMMY_K2_API_KEY=your_kimmy_key_here

# Provider selection (glm47, claude, codex, kimmy_k2)
PROVIDER=glm47

# Loop settings
MAX_ITERATIONS=0
```

## Running Locally (Without Docker)

```bash
# Set environment variables
export OPENCODE_API_KEY=your_key_here

# Or load from .env
source .env  # if using direnv or similar

# Run the loop
./loop.sh planning
./loop.sh building 20
./loop.sh qa
```

## Provider Configuration

### GLM-4.7 (Default)

- **API Key**: `OPENCODE_API_KEY`
- **Endpoint**: `https://api.z.ai/api/coding/paas/v4/chat/completions`
- **Model**: `glm-4.7`

### Claude

- **API Key**: `ANTHROPIC_API_KEY`
- **Endpoint**: `https://api.anthropic.com/v1/messages`
- **Model**: `claude-sonnet-4-20250514`

### Codex (OpenAI)

- **API Key**: `OPENAI_API_KEY`
- **Endpoint**: `https://api.openai.com/v1/chat/completions`
- **Model**: `gpt-4`

### Kimmy K2

- **API Key**: `KIMMY_K2_API_KEY`
- **Endpoint**: TBD
- **Model**: TBD

## Troubleshooting

### Docker Issues

**Container won't start:**
```bash
# Check logs
docker-compose logs ralph

# Rebuild image
docker-compose build --no-cache
```

**Volume permissions issues:**
```bash
# Fix permissions on macOS/Linux
sudo chown -R $USER:$USER .
```

**Python not found in container:**
```bash
# Rebuild with no cache
docker-compose build --no-cache
```

### API Issues

**API key errors:**
- Verify API key in `.env` is correct
- Check API key is valid and has credits
- Ensure correct key for selected provider

**GLM-4.7 agent not found:**
```bash
# Check agent files exist
ls -la glm47_agent.py libs/
```

### Loop Issues

**Loop goes in circles or makes wrong decisions:**
```bash
# Regenerate the plan
rm IMPLEMENTATION_PLAN.md
./loop.sh planning
```

**Tests keep failing:**
- Check `agents.md` has correct test commands
- Review test logs in Docker output
- Update specs if tests are incorrect

**Git push fails:**
- Ensure remote repository is configured: `git remote -v`
- Check authentication: `git config --global user.name` and `user.email`
- Verify you have push permissions

### Provider Issues

**Unknown provider error:**
- Check `PROVIDER` env var is one of: `glm47`, `claude`, `codex`, `kimmy_k2`
- Verify API key for selected provider is set

**Claude API errors:**
- Ensure `ANTHROPIC_API_KEY` is set
- Verify key has access to Claude models

## Git Configuration

For automatic git operations (commits, tags, pushes):

```bash
# Configure git user
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Initialize repository
git init
git add .
git commit -m "Initial commit"

# Add remote (optional)
git remote add origin git@github.com:user/repo.git
```
