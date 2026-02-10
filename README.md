# Ralph Loop - GLM-4.7 Docker Implementation

Autonomous AI-driven development using the Ralph Wiggum technique with GLM-4.7 and Docker.

**🚀 Quick Summary:** Write specs in `specs/*.md` → Run `./loop.sh planning` to generate plan → Run `./loop.sh building` to implement → Run `./loop.sh qa` to validate. Repeat as needed.

**✨ Features:**
- Three independent commands: `planning`, `building`, `qa`
- GLM-4.7 integration (API or local mode)
- Docker isolation for safe autonomous execution
- Auto-updates `improvements.md` with progress
- Auto-generates implementation plans
- Git integration with automatic tagging

## Quick Start

1. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your GLM_API_KEY
   ```

2. **Initialize Git Repository**
   ```bash
   git init
   git add .
   git commit -m "Initial commit: Ralph Loop setup"
   ```

3. **Build and Start Docker**
   ```bash
   docker-compose build
   docker-compose up -d
   ```

4. **Run Ralph Loop**
   ```bash
   # Option 1: Run inside Docker container
   docker-compose exec ralph bash
   ./loop.sh planning     # Generate implementation plan
   ./loop.sh building      # Build the application
   ./loop.sh qa            # Quality assurance

   # Option 2: Run directly via docker-compose
   MODE=planning docker-compose up ralph
   MODE=building MAX_ITERATIONS=20 docker-compose up ralph
   MODE=qa docker-compose up ralph
   ```

## Detailed Usage

### Step 1: Write Your Specifications

Create specification files in the `specs/` directory:

```bash
# Example: Create a spec for user authentication
cat > specs/user-authentication.md << 'EOF'
# User Authentication System

## Overview
The user authentication system allows users to register, login, and manage their sessions.

## Requirements

### User Registration
- Users can sign up with email and password
- Password must be at least 8 characters
- Email validation required

### User Login
- Users can login with email and password
- Session tokens generated upon successful login
- Session expires after 24 hours

### Technical Requirements
- Use JWT for session management
- Store hashed passwords using bcrypt
- Implement rate limiting for login attempts

## Acceptance Criteria
- [ ] Users can register successfully
- [ ] Login works with correct credentials
- [ ] Login fails with incorrect credentials
- [ ] Session tokens expire after 24 hours
EOF
```

**Spec Guidelines:**
- One spec per topic of concern
- Topic should be describable in one sentence without "and"
- Include requirements, acceptance criteria, and technical constraints

### Step 2: Generate Implementation Plan

Run planning mode to analyze specs vs code:

```bash
./loop.sh planning
```

This will:
- Study all specs in `specs/`
- Analyze existing code in `src/`
- Perform gap analysis
- Generate/update `IMPLEMENTATION_PLAN.md` with prioritized tasks

**Output:**
- Creates/updates `IMPLEMENTATION_PLAN.md`
- Lists tasks in priority order
- Identifies missing functionality
- No code is written in planning mode

### Step 3: Build the Application

Run building mode to implement from the plan:

```bash
# Unlimited iterations (run until plan complete)
./loop.sh building

# Or limit iterations (e.g., 10 tasks)
./loop.sh building 10
```

Each iteration will:
1. Choose the most important task from the plan
2. Search the codebase (doesn't assume not implemented)
3. Implement the functionality using subagents
4. Run tests specified in `agents.md`
5. Update `IMPLEMENTATION_PLAN.md`
6. Commit changes with a descriptive message
7. Create git tag (0.0.1, 0.0.2, etc.)
8. Update `improvements.md` with progress
9. Clear context and start fresh for next iteration

### Step 4: Quality Assurance

Run QA mode for comprehensive validation:

```bash
./loop.sh qa
```

This will:
- Run all test suites (unit, integration, e2e)
- Execute typecheck and lint commands
- Build the application
- Review code quality and architecture
- Perform security analysis
- Analyze performance
- Categorize issues (Critical/High/Medium/Low)
- Generate QA report in `improvements.md`

### Step 5: Iterate as Needed

Repeat the cycle:
- Update specs if requirements change
- Regenerate plan if needed (`rm IMPLEMENTATION_PLAN.md && ./loop.sh planning`)
- Continue building
- Run QA to validate

## Running Locally (Without Docker)

If you have GLM-4.7 CLI installed locally:

```bash
# Install GLM-4.7 CLI
npm install -g @zhipuai/glm-cli

# Set environment variables
export GLM_API_KEY=your_key_here
export GLM_MODEL=glm-4.7

# Run the loop
./loop.sh planning
./loop.sh building 20
./loop.sh qa
```

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

## Project Structure

- `loop.sh` - Main loop script
- `PROMPT_*.md` - Mode-specific instructions
- `agents.md` - Operational guide (build/test commands)
- `improvements.md` - State tracking log
- `specs/*.md` - Application specifications
- `IMPLEMENTATION_PLAN.md` - Generated task list
- `src/` - Application code

## Workflow

1. Write specs in `specs/*.md`
2. Run `./loop.sh planning` to generate plan
3. Run `./loop.sh building` to implement
4. Run `./loop.sh qa` to validate
5. Repeat 2-4 as needed

## GLM-4.7 Configuration

- **Default**: API mode (requires GLM_API_KEY)
- **Local mode**: Set `GLM_MODE=local` and provide `GLM_LOCAL_PATH`
- **Model**: Configure `GLM_MODEL` (default: glm-4.7)

Environment variables in `.env`:
```bash
GLM_API_KEY=your_api_key_here
GLM_API_BASE=https://open.bigmodel.cn/api/paas/v4/
GLM_MODEL=glm-4.7
GLM_MODE=api  # 'api' or 'local'
GLM_LOCAL_PATH=/path/to/local/model  # Only if mode is 'local'
```

## Key Files

### `agents.md` - Operational Guide
Keep this **brief (~60 lines)**. It should contain:
- Build commands
- Test commands
- Typecheck and lint commands
- How to run the application
- Environment setup notes
- Codebase patterns

**Example:**
```markdown
## Build & Run
- Build command: `npm run build`
- Run command: `npm run dev`

## Validation
- Tests: `npm test`
- Typecheck: `npm run typecheck`
- Lint: `npm run lint`
```

### `improvements.md` - State Tracking
Updated automatically by Ralph after each iteration:
- What was built
- State of the application
- Important information discovered
- Architecture decisions
- Bug fixes and issues resolved

### `IMPLEMENTATION_PLAN.md` - Generated Task List
Created by planning mode, updated by building mode:
- Prioritized task list
- Tracks completed/pending items
- Auto-cleans completed tasks
- **Do not edit manually**

### `specs/*.md` - Application Specifications
All workings of your application:
- Requirements and specifications
- User stories
- Technical details
- Acceptance criteria

## Troubleshooting

### Docker Issues

**Q: Docker container won't start**
```bash
# Check logs
docker-compose logs ralph

# Rebuild image
docker-compose build --no-cache
```

**Q: Volume permissions issues**
```bash
# Fix permissions on macOS/Linux
sudo chown -R $USER:$USER .
```

### GLM-4.7 Issues

**Q: API key errors**
- Verify `GLM_API_KEY` in `.env` is correct
- Check API key is valid and has credits
- Verify `GLM_API_BASE` endpoint is correct

**Q: GLM-4.7 CLI not found**
```bash
# Rebuild Docker image
docker-compose build

# Or install locally
npm install -g @zhipuai/glm-cli
```

### Loop Issues

**Q: Loop goes in circles or makes wrong decisions**
```bash
# Regenerate the plan
rm IMPLEMENTATION_PLAN.md
./loop.sh planning
```

**Q: Tests keep failing**
- Check `agents.md` has correct test commands
- Review test logs in Docker output
- Consider updating specs if tests are incorrect

**Q: Git push fails**
- Ensure remote repository is configured: `git remote -v`
- Check authentication: `git config --global user.name` and `user.email`
- Verify you have push permissions

## Tips & Best Practices

### Writing Good Specs
1. **One topic per spec**: Don't combine unrelated features
2. **Be specific**: Include acceptance criteria
3. **Think about edge cases**: Document constraints and edge cases
4. **Include technical details**: Performance requirements, security considerations

### Managing the Loop
1. **Start with planning**: Always generate a plan first
2. **Limit iterations**: Use `./loop.sh building N` to limit tasks
3. **Watch the logs**: Monitor progress in real-time
4. **Let Ralph Ralph**: Trust the AI to self-correct, intervene only when stuck

### When to Regenerate the Plan
- Ralph is implementing wrong things
- Duplicating work already done
- Plan feels stale or outdated
- Too much clutter from completed items
- Requirements changed significantly

### Backpressure is Critical
- Ensure `agents.md` has correct build/test commands
- Tests must fail for invalid work
- Lint and typecheck catch errors early
- Security scans catch vulnerabilities

## Example Workflow

Here's a complete example of building a simple to-do list application:

```bash
# 1. Initialize project
git init
git add .
git commit -m "Initial commit"

# 2. Write specs
cat > specs/todo-app.md << 'EOF'
# To-Do List Application

## Features
- Create, read, update, delete tasks
- Mark tasks as complete
- Store tasks in a database

## Requirements
- Use SQLite for persistence
- RESTful API endpoints
- JSON request/response format
EOF

# 3. Update agents.md with project-specific commands
cat > agents.md << 'EOF'
## Build & Run
- Build command: `python -m venv venv && source venv/bin/activate && pip install -r requirements.txt`
- Run command: `python app.py`

## Validation
- Tests: `pytest`
- Typecheck: `mypy .`
- Lint: `ruff check .`
EOF

# 4. Generate plan
./loop.sh planning

# 5. Build (limit to 10 iterations for testing)
./loop.sh building 10

# 6. Quality assurance
./loop.sh qa

# 7. Check progress
cat improvements.md
cat IMPLEMENTATION_PLAN.md
```

## Philosophy

- **Let Ralph Ralph**: Trust the AI to self-correct
- **Fresh Context**: Each iteration starts fresh
- **Plan is Disposable**: Regenerate if wrong
- **Backpressure**: Tests guardrail the implementation
- **Observe and Adjust**: Watch the loop, add guardrails as needed

## Additional Resources

- [Ralph Wiggum Technique](https://ghuntley.com/ralph/)
- [Docker Documentation](https://docs.docker.com/)
- [GLM-4.7 API Documentation](https://open.bigmodel.cn/dev/api)

## License

MIT License - Feel free to use and modify for your projects.
