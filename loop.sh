#!/bin/bash
# Ralph Loop Script - Multi-Provider AI Agent
# Usage: ./loop.sh [planning|building|qa|test] [max_iterations]
#
# Examples:
#   PROJECT_NAME=my-app ./loop.sh planning
#   PROJECT_NAME=my-app ./loop.sh building 20
#   PROJECT_NAME=my-app ./loop.sh qa 5
#   PROJECT_NAME=my-app ./loop.sh test
#
# Environment:
#   PROJECT_NAME=my-app (required)
#   PROVIDER=glm|claude|codex|kimmy_k2
#   OPENCODE_MODEL=glm-4.7|glm-5 (for GLM provider)

set -e

RALPH_ROOT="$(cd "$(dirname "$0")" && pwd)"

: "${PROVIDER:=glm}"

if [ -f "$RALPH_ROOT/.env" ]; then
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
            continue
        fi
        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]+)= ]]; then
            var_name="${BASH_REMATCH[1]}"
            if [ -z "${!var_name}" ]; then
                export "$line"
            fi
        fi
    done < "$RALPH_ROOT/.env"
fi

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

get_api_key_name() {
    case "$PROVIDER" in
        glm)      echo "OPENCODE_API_KEY" ;;
        claude)   echo "ANTHROPIC_API_KEY" ;;
        codex)    echo "OPENAI_API_KEY" ;;
        kimmy_k2) echo "KIMMY_K2_API_KEY" ;;
        *)        echo "UNKNOWN" ;;
    esac
}

get_api_key() {
    local key_name=$(get_api_key_name)
    eval echo "\${$key_name}"
}

init_project() {
    local project_path="$1"
    
    mkdir -p "$project_path/specs"
    mkdir -p "$project_path/src"
    
    if [ ! -f "$project_path/agents.md" ]; then
        cat > "$project_path/agents.md" << 'EOF'
## Build & Run

Succinct rules for how to BUILD the project:
- Build command: [e.g., `npm run build` or `python -m build`]
- Run command: [e.g., `npm run dev` or `python app.py`]
- Database setup: [if applicable]

## Validation

Run these after implementing to get immediate feedback:
- Tests: [test command, e.g., `npm test` or `pytest`]
- Typecheck: [typecheck command, e.g., `npm run typecheck` or `mypy .`]
- Lint: [lint command, e.g., `npm run lint` or `ruff check .`]
- Format: [format command, e.g., `npm run format` or `black .`]

## Operational Notes

Succinct learnings about how to RUN the project:
- Development environment setup
- How to run tests for specific modules
- Common issues and workarounds

### Codebase Patterns

- Project structure conventions
- Design patterns used
EOF
    fi
    
    if [ ! -f "$project_path/improvements.md" ]; then
        cat > "$project_path/improvements.md" << EOF
# Improvements Log

This file tracks what was built, the state of the application, and important information discovered during the Ralph loop.

## Project Overview

- **Started**: $(date '+%Y-%m-%d')
- **Goal**: [Brief description of what the project should achieve]
- **Tech Stack**: [Languages, frameworks, tools]
- **Status**: Initial setup

## Major Milestones

### $(date '+%Y-%m-%d') - Project Initialization
- Created project structure
- Initialized by Ralph Loop
---

## Iterations

[Will be populated automatically by Ralph loop]
EOF
    fi
    
    if [ ! -d "$project_path/.git" ]; then
        cd "$project_path"
        git init
        git add .
        git commit -m "Initial commit: Project initialized by Ralph Loop"
        cd "$RALPH_ROOT"
    fi
}

test_setup() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Testing Ralph Loop Setup${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo -e "${YELLOW}Test 1: Checking Python...${NC}"
    if command -v python3 &>/dev/null 2>&1; then
        echo -e "${GREEN}✓ Python3 is installed${NC}"
        echo -e "  Version: $(python3 --version 2>&1)"
    else
        echo -e "${RED}✗ Python3 is not found${NC}"
        return 1
    fi
    echo ""
    
    echo -e "${YELLOW}Test 2: Checking Ralph files...${NC}"
    if [ -f "$RALPH_ROOT/agent.py" ]; then
        echo -e "${GREEN}✓ agent.py found${NC}"
    else
        echo -e "${RED}✗ agent.py not found${NC}"
        return 1
    fi
    
    if [ -d "$RALPH_ROOT/libs" ]; then
        echo -e "${GREEN}✓ libs/ directory found${NC}"
    else
        echo -e "${RED}✗ libs/ directory not found${NC}"
        return 1
    fi
    echo ""
    
    echo -e "${YELLOW}Test 3: Checking project...${NC}"
    if [ -z "$PROJECT_NAME" ]; then
        echo -e "${RED}✗ PROJECT_NAME is not set${NC}"
        echo -e "  Set PROJECT_NAME in .env or as environment variable"
        return 1
    fi
    echo -e "${GREEN}✓ PROJECT_NAME: ${PROJECT_NAME}${NC}"
    
    if [ -d "$RALPH_ROOT/projects/$PROJECT_NAME" ]; then
        echo -e "${GREEN}✓ Project directory exists${NC}"
    else
        echo -e "${YELLOW}⚠ Project directory will be created${NC}"
    fi
    echo ""
    
    echo -e "${YELLOW}Test 4: Checking provider configuration...${NC}"
    echo -e "  Provider: ${PROVIDER}"
    
    local key_name=$(get_api_key_name)
    local api_key=$(get_api_key)
    
    if [ -z "$api_key" ] || [ "$api_key" = "your_api_key_here" ] || [[ "$api_key" == your_* ]]; then
        echo -e "${RED}✗ ${key_name} is not set${NC}"
        echo -e "  Set ${key_name} in .env or as environment variable"
        return 1
    else
        echo -e "${GREEN}✓ ${key_name} is set${NC}"
        echo -e "  Key: ${api_key:0:15}... (first 15 chars)"
    fi
    echo ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}All tests passed! Setup looks good.${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    return 0
}

run_agent() {
    local prompt="$1"
    
    echo -e "${BLUE}→ Running Agent${NC}"
    echo -e "  Provider: ${PROVIDER}"
    echo -e "  Mode: ${MODE}"
    echo -e "  Project: ${PROJECT_NAME}"
    
    cd "$RALPH_ROOT"
    
    if [ ! -f "agent.py" ]; then
        echo -e "${RED}ERROR: agent.py not found${NC}"
        return 1
    fi
    
    if [ ! -d "libs" ]; then
        echo -e "${RED}ERROR: libs/ directory not found${NC}"
        return 1
    fi
    
    if python3 agent.py "$prompt" 2>&1; then
        echo -e "${GREEN}✓ Agent completed successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Agent failed with exit code $?${NC}"
        return 1
    fi
}

if [ -z "$1" ]; then
    MODE="building"
    MAX_ITERATIONS=${2:-0}
elif [ "$1" = "planning" ] || [ "$1" = "building" ] || [ "$1" = "qa" ] || [ "$1" = "test" ]; then
    MODE="$1"
    MAX_ITERATIONS=${2:-0}
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    MODE="building"
    MAX_ITERATIONS=$1
else
    echo "Unknown mode: $1"
    echo "Usage: PROJECT_NAME=my-app $0 [planning|building|qa|test] [max_iterations]"
    exit 1
fi

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}ERROR: PROJECT_NAME is not set!${NC}"
    echo ""
    echo "Usage: PROJECT_NAME=my-app ./loop.sh [planning|building|qa|test]"
    echo ""
    echo "Set PROJECT_NAME in .env or as environment variable."
    exit 1
fi

API_KEY_NAME=$(get_api_key_name)
API_KEY=$(get_api_key)

if [ -z "$API_KEY" ] || [ "$API_KEY" = "your_api_key_here" ] || [[ "$API_KEY" == your_* ]]; then
    echo -e "${RED}ERROR: ${API_KEY_NAME} is not set!${NC}"
    echo -e "${YELLOW}Provider: ${PROVIDER}${NC}"
    echo -e "${YELLOW}Please set ${API_KEY_NAME} in .env file or as environment variable${NC}"
    echo ""
    echo -e "${BLUE}Available providers:${NC}"
    echo -e "  glm      - GLM (glm-4.7, glm-5) via Z.AI (requires OPENCODE_API_KEY)"
    echo -e "  claude   - Anthropic Claude (requires ANTHROPIC_API_KEY)"
    echo -e "  codex    - OpenAI GPT-4 (requires OPENAI_API_KEY)"
    echo -e "  kimmy_k2 - Kimmy K2 (requires KIMMY_K2_API_KEY)"
    exit 1
fi

if ! command -v python3 &>/dev/null 2>&1; then
    echo -e "${RED}ERROR: Python3 is not installed!${NC}"
    exit 1
fi

if [ "$MODE" = "test" ]; then
    test_setup
    exit $?
fi

PROJECT_PATH="$RALPH_ROOT/projects/$PROJECT_NAME"

mkdir -p "$RALPH_ROOT/projects"

if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Creating new project: ${PROJECT_NAME}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    init_project "$PROJECT_PATH"
fi

cd "$PROJECT_PATH"

ITERATION=0
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Ralph Loop Started${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Project:        ${YELLOW}$PROJECT_NAME${NC}"
echo -e "Project Path:   $PROJECT_PATH"
echo -e "Provider:       ${YELLOW}$PROVIDER${NC}"
echo -e "Mode:           ${YELLOW}$MODE${NC}"
echo -e "Branch:         $CURRENT_BRANCH"
[ $MAX_ITERATIONS -gt 0 ] && echo -e "Max Iterations: $MAX_ITERATIONS"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}System Diagnostics${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Ralph Root:     $RALPH_ROOT"
echo -e "Working Dir:    $(pwd)"
echo -e "Python Version: $(python3 --version 2>&1 || echo 'Not found')"
echo -e "Git Version:    $(git --version 2>&1 || echo 'Not found')"
echo ""

PROMPT_CONTENT=$(create_prompt_content "$MODE")

while true; do
    if [ $MAX_ITERATIONS -gt 0 ] && [ $ITERATION -ge $MAX_ITERATIONS ]; then
        echo -e "${GREEN}✓ Reached max iterations: $MAX_ITERATIONS${NC}"
        break
    fi

    ITERATION=$((ITERATION + 1))
    echo -e "\n${BLUE}======================== ITERATION $ITERATION ========================${NC}"
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} Starting iteration..."
    
    run_agent "$PROMPT_CONTENT"
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}✓ Iteration $ITERATION completed successfully${NC}"
    else
        echo -e "${RED}✗ Iteration $ITERATION failed with exit code $EXIT_CODE${NC}"
        echo -e "${YELLOW}Loop will continue to next iteration${NC}"
    fi
    
    cd "$PROJECT_PATH"
    
    if [ "$MODE" = "building" ] && git remote get-url origin &>/dev/null; then
        git push origin "$CURRENT_BRANCH" 2>/dev/null || {
            echo -e "${YELLOW}Creating remote branch...${NC}"
            git push -u origin "$CURRENT_BRANCH" 2>/dev/null || true
        }
    fi
    
    if [ "$MODE" = "building" ] && [ -f "improvements.md" ]; then
        echo "" >> improvements.md
        echo "### Iteration $ITERATION - $(date '+%Y-%m-%d %H:%M:%S')" >> improvements.md
        echo "- Project: $PROJECT_NAME" >> improvements.md
        echo "- Provider: $PROVIDER" >> improvements.md
        echo "- Mode: $MODE" >> improvements.md
        echo "- Status: Completed" >> improvements.md
        echo "" >> improvements.md
    fi
    
    echo -e "${BLUE}======================== END ITERATION $ITERATION ========================${NC}\n"
done

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Ralph Loop Completed - $ITERATION iterations${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

create_prompt_content() {
    local mode=$1
    
    local project_context="You are working on project '${PROJECT_NAME}' located at: ${PROJECT_PATH}

All file operations (read, write, edit) must be performed relative to the project directory.
- Specs are in: specs/
- Source code goes in: src/
- Build/test commands are in: agents.md
- Progress is tracked in: improvements.md

"
    
    case $mode in
        planning)
            cat << EOF
${project_context}0a. Check if \`specs/*\` has any specification files. If the specs directory is empty or only has README.md, you MUST first ask the user: "What is the purpose of this project? Please describe what you want to build."

0b. If the user provides a description, generate appropriate specification files in specs/ based on their requirements. Each spec file should describe a distinct feature or concern.

0c. Study @IMPLEMENTATION_PLAN.md (if present) to understand the plan so far.

0d. For reference, the application source code is in \`src/*\`.

1. Study @IMPLEMENTATION_PLAN.md (if present; it may be incorrect) and study existing source code in \`src/*\` and compare it against \`specs/*\`. Analyze findings, prioritize tasks, and create/update @IMPLEMENTATION_PLAN.md as a bullet point list sorted in priority of items yet to be implemented. Think extra hard. Consider searching for TODO, minimal implementations, placeholders, skipped/flaky tests, and inconsistent patterns.

IMPORTANT: Plan only. Do NOT implement anything. Do NOT assume functionality is missing; confirm with code search first.

ULTIMATE GOAL: Build the application according to specifications in \`specs/*\`. Consider missing elements and plan accordingly. If an element is missing, search first to confirm it doesn't exist, then if needed author the specification at specs/FILENAME.md. If you create a new element then document the plan to implement it in @IMPLEMENTATION_PLAN.md.

9999999. Keep @IMPLEMENTATION_PLAN.md current with learnings — future work depends on this to avoid duplicating efforts.
99999999. If you find inconsistencies in the specs/* then update the specs.
EOF
            ;;
        building)
            cat << EOF
${project_context}0a. Study \`specs/*\` to learn the application specifications.
0b. Study @IMPLEMENTATION_PLAN.md.
0c. For reference, the application source code is in \`src/*\`.

1. Your task is to implement functionality per the specifications. Follow @IMPLEMENTATION_PLAN.md and choose the most important item to address. Before making changes, search the codebase (don't assume not implemented). Think extra hard about the best approach.

2. After implementing functionality or resolving problems, run the tests for that unit of code that was improved. Follow the commands specified in @agents.md for validation. If functionality is missing then it's your job to add it as per the application specifications.

3. When you discover issues, immediately update @IMPLEMENTATION_PLAN.md with your findings. When resolved, update and remove the item.

4. When the tests pass, update @IMPLEMENTATION_PLAN.md, then \`git add -A\` then \`git commit\` with a message describing the changes. After the commit, update @improvements.md with what was built, state changes, and important information discovered.

999. Important: When authoring documentation, capture the why — tests and implementation importance.
9999. Single sources of truth, no migrations/adapters. If tests unrelated to your work fail, resolve them as part of the increment.
99999. As soon as there are no build or test errors create a git tag. If there are no git tags start at 0.0.0 and increment patch by 1 for example 0.0.1 if 0.0.0 does not exist.
999999. You may add extra logging if required to debug issues.
9999999. Keep @IMPLEMENTATION_PLAN.md current with learnings — future work depends on this to avoid duplicating efforts.
99999999. When you learn something new about how to run the application, update @agents.md but keep it brief.
999999999. For any bugs you notice, resolve them or document them in @IMPLEMENTATION_PLAN.md even if it is unrelated to the current piece of work.
9999999999. Implement functionality completely. Placeholders and stubs waste efforts and time redoing the same work.
99999999999. When @IMPLEMENTATION_PLAN.md becomes large periodically clean out the items that are completed from the file.
999999999999. If you find inconsistencies in the specs/* then update the specs.
9999999999999. IMPORTANT: Keep @agents.md operational only — status updates and progress notes belong in @IMPLEMENTATION_PLAN.md.
99999999999999. Update @improvements.md after each commit with what was built, state of app, and important information discovered.
EOF
            ;;
        qa)
            cat << EOF
${project_context}0a. Study \`specs/*\` to learn the application specifications.
0b. Study @IMPLEMENTATION_PLAN.md.
0c. Study @agents.md to understand build/test commands.
0d. Study @improvements.md to understand current state.

1. Your task is to perform comprehensive quality assurance on the application:
   a. Run all tests (unit, integration, e2e) as specified in @agents.md
   b. Run typecheck and lint commands
   c. Build the application to ensure no build errors
   d. Review code quality, architecture, and patterns
   e. Perform security analysis
   f. Analyze performance characteristics
   g. Check for edge cases and error handling

2. When issues are found, categorize them as:
   - Critical: Blocks release, must fix immediately
   - High: Important but can defer
   - Medium: Nice to have, low priority
   - Low: Minor issues, suggestions

3. Update @IMPLEMENTATION_PLAN.md with discovered issues.

4. Generate a QA report in @improvements.md with:
   - Test results summary
   - Code quality metrics
   - Security findings
   - Performance observations
   - Recommendations
   - Overall quality assessment (Pass/Fail/Conditional)

999. Think extra hard about edge cases, security vulnerabilities, and performance bottlenecks.
9999. Document all findings with specific file references and line numbers.
99999. If critical issues are found, fail the QA gate and document why.
999999. Update @improvements.md with comprehensive QA findings.
9999999. Suggest test improvements to increase coverage.
99999999. Verify that all acceptance criteria from specs are met.
EOF
            ;;
    esac
}
