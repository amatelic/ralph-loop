#!/bin/bash
# Ralph Loop Script - Multi-Provider AI Agent
# Usage: ./loop.sh [planning|building|qa|test] [max_iterations]
#
# Examples:
#   ./loop.sh planning          # Planning mode, unlimited iterations
#   ./loop.sh building 20       # Building mode, max 20 iterations
#   ./loop.sh qa 5              # QA mode, max 5 iterations
#   ./loop.sh                   # Default: building mode, unlimited
#   ./loop.sh test              # Test setup (no iteration)
#
# Environment:
#   PROVIDER=glm47|claude|codex|kimmy_k2

set -e

: "${PROVIDER:=glm47}"

# Load .env file if it exists
if [ -f .env ]; then
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
            continue
        fi
        if [[ "$line" =~ ^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]+= ]]; then
            export "$line"
        fi
    done < .env
fi

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

get_api_key_name() {
    case "$PROVIDER" in
        glm47)    echo "OPENCODE_API_KEY" ;;
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
    
    echo -e "${YELLOW}Test 2: Checking agent script...${NC}"
    if [ -f "glm47_agent.py" ]; then
        echo -e "${GREEN}✓ glm47_agent.py found${NC}"
    else
        echo -e "${RED}✗ glm47_agent.py not found${NC}"
        return 1
    fi
    
    if [ -d "libs" ]; then
        echo -e "${GREEN}✓ libs/ directory found${NC}"
    else
        echo -e "${RED}✗ libs/ directory not found${NC}"
        return 1
    fi
    echo ""
    
    echo -e "${YELLOW}Test 3: Checking provider configuration...${NC}"
    echo -e "  Provider: ${PROVIDER}"
    
    local key_name=$(get_api_key_name)
    local api_key=$(get_api_key)
    
    if [ -z "$api_key" ] || [ "$api_key" = "your_api_key_here" ] || [[ "$api_key" == your_* ]]; then
        echo -e "${RED}✗ ${key_name} is not set${NC}"
        echo -e "  Set ${key_NAME} in .env or as environment variable"
        return 1
    else
        echo -e "${GREEN}✓ ${key_name} is set${NC}"
        echo -e "  Key: ${api_key:0:15}... (first 15 chars)"
    fi
    echo ""
    
    echo -e "${YELLOW}Test 4: Checking prompt file...${NC}"
    if [ -f "$PROMPT_FILE" ]; then
        echo -e "${GREEN}✓ Prompt file exists: $PROMPT_FILE${NC}"
        CONTENT=$(cat "$PROMPT_FILE")
        if [ -n "$CONTENT" ]; then
            echo -e "${GREEN}✓ Prompt file has content (${#CONTENT} chars)${NC}"
        else
            echo -e "${RED}✗ Prompt file is empty${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠ Prompt file not found: $PROMPT_FILE${NC}"
        echo -e "  It will be auto-generated"
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
    
    if [ ! -f "glm47_agent.py" ]; then
        echo -e "${RED}ERROR: glm47_agent.py not found${NC}"
        return 1
    fi
    
    if [ ! -d "libs" ]; then
        echo -e "${RED}ERROR: libs/ directory not found${NC}"
        return 1
    fi
    
    if python3 glm47_agent.py "$prompt" 2>&1; then
        echo -e "${GREEN}✓ Agent completed successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Agent failed with exit code $?${NC}"
        return 1
    fi
}

if [ -z "$1" ]; then
    MODE="building"
    PROMPT_FILE="prompts/PROMPT_building.md"
    MAX_ITERATIONS=${2:-0}
elif [ "$1" = "planning" ] || [ "$1" = "building" ] || [ "$1" = "qa" ] || [ "$1" = "test" ]; then
    MODE="$1"
    PROMPT_FILE="prompts/PROMPT_${MODE}.md"
    MAX_ITERATIONS=${2:-0}
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    MODE="building"
    PROMPT_FILE="prompts/PROMPT_building.md"
    MAX_ITERATIONS=$1
else
    echo "Unknown mode: $1"
    echo "Usage: $0 [planning|building|qa|test] [max_iterations]"
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
    echo -e "  glm47    - GLM-4.7 (requires OPENCODE_API_KEY)"
    echo -e "  claude   - Anthropic Claude (requires ANTHROPIC_API_KEY)"
    echo -e "  codex    - OpenAI GPT-4 (requires OPENAI_API_KEY)"
    echo -e "  kimmy_k2 - Kimmy K2 (requires KIMMY_K2_API_KEY)"
    echo ""
    echo -e "${BLUE}Current env:${NC}"
    echo -e "  PROVIDER: ${PROVIDER}"
    echo -e "  ${API_KEY_NAME}: ${API_KEY:-(not set)}"
    exit 1
fi

if ! command -v python3 &>/dev/null 2>&1; then
    echo -e "${RED}ERROR: Python3 is not installed!${NC}"
    exit 1
fi

if [ ! -f "glm47_agent.py" ]; then
    echo -e "${RED}ERROR: glm47_agent.py not found!${NC}"
    exit 1
fi

if [ "$1" = "test" ]; then
    test_setup
    exit $?
fi

ITERATION=0
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Ralph Loop Started${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Provider:       ${YELLOW}$PROVIDER${NC}"
echo -e "Mode:           ${YELLOW}$MODE${NC}"
echo -e "Prompt File:    $PROMPT_FILE"
echo -e "Branch:         $CURRENT_BRANCH"
[ $MAX_ITERATIONS -gt 0 ] && echo -e "Max Iterations: $MAX_ITERATIONS"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}System Diagnostics${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Working Directory: $(pwd)"
echo -e "Agent Script: $([ -f glm47_agent.py ] && echo 'Found' || echo 'Not found')"
echo -e "Libs Directory: $([ -d libs ] && echo 'Found' || echo 'Not found')"
echo -e "Python Version: $(python3 --version 2>&1 || echo 'Not found')"
echo -e "Git Version: $(git --version 2>&1 || echo 'Not found')"
echo ""

if [ ! -f "$PROMPT_FILE" ]; then
    echo -e "${YELLOW}Warning: $PROMPT_FILE not found, creating from template...${NC}"
    create_prompt_template "$MODE" > "$PROMPT_FILE"
fi

mkdir -p specs src

while true; do
    if [ $MAX_ITERATIONS -gt 0 ] && [ $ITERATION -ge $MAX_ITERATIONS ]; then
        echo -e "${GREEN}✓ Reached max iterations: $MAX_ITERATIONS${NC}"
        break
    fi

    ITERATION=$((ITERATION + 1))
    echo -e "\n${BLUE}======================== ITERATION $ITERATION ========================${NC}"
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} Starting iteration..."
    
    PROMPT_CONTENT=$(cat "$PROMPT_FILE")
    
    run_agent "$PROMPT_CONTENT"
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}✓ Iteration $ITERATION completed successfully${NC}"
    else
        echo -e "${RED}✗ Iteration $ITERATION failed with exit code $EXIT_CODE${NC}"
        echo -e "${YELLOW}Loop will continue to next iteration${NC}"
    fi
    
    if [ "$MODE" = "building" ] && git remote get-url origin &>/dev/null; then
        git push origin "$CURRENT_BRANCH" 2>/dev/null || {
            echo -e "${YELLOW}Creating remote branch...${NC}"
            git push -u origin "$CURRENT_BRANCH" 2>/dev/null || true
        }
    fi
    
    if [ "$MODE" = "building" ] && [ -f "improvements.md" ]; then
        echo "" >> improvements.md
        echo "### Iteration $ITERATION - $(date '+%Y-%m-%d %H:%M:%S')" >> improvements.md
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

create_prompt_template() {
    local mode=$1
    case $mode in
        planning)
            cat << 'EOF'
0a. Study `specs/*` with up to 500 parallel subagents to learn the application specifications.
0b. Study @IMPLEMENTATION_PLAN.md (if present) to understand the plan so far.
0c. Study `libs/*` with up to 500 parallel subagents to understand shared utilities & components.
0d. For reference, the application source code is in `src/*`.

1. Study @IMPLEMENTATION_PLAN.md (if present; it may be incorrect) and use up to 1000 subagents to study existing source code in `src/*` and compare it against `specs/*`. Use a subagent to analyze findings, prioritize tasks, and create/update @IMPLEMENTATION_PLAN.md as a bullet point list sorted in priority of items yet to be implemented. Think extra hard. Consider searching for TODO, minimal implementations, placeholders, skipped/flaky tests, and inconsistent patterns. Study @IMPLEMENTATION_PLAN.md to determine starting point for research and keep it up to date with items considered complete/incomplete using subagents.

IMPORTANT: Plan only. Do NOT implement anything. Do NOT assume functionality is missing; confirm with code search first. Treat `libs` as the project's standard library for shared utilities and components. Prefer consolidated, idiomatic implementations there over ad-hoc copies.

ULTIMATE GOAL: Build the application according to specifications in `specs/*`. Consider missing elements and plan accordingly. If an element is missing, search first to confirm it doesn't exist, then if needed author the specification at specs/FILENAME.md. If you create a new element then document the plan to implement it in @IMPLEMENTATION_PLAN.md using a subagent.

9999999. Keep @IMPLEMENTATION_PLAN.md current with learnings using a subagent — future work depends on this to avoid duplicating efforts.
99999999. If you find inconsistencies in the specs/* then use a subagent with 'think extra hard' requested to update the specs.
EOF
            ;;
        building)
            cat << 'EOF'
0a. Study `specs/*` with up to 1000 parallel subagents to learn the application specifications.
0b. Study @IMPLEMENTATION_PLAN.md.
0c. For reference, the application source code is in `src/*`.

1. Your task is to implement functionality per the specifications using parallel subagents. Follow @IMPLEMENTATION_PLAN.md and choose the most important item to address. Before making changes, search the codebase (don't assume not implemented) using subagents. You may use up to 1000 parallel subagents for searches/reads and only 1 subagent for build/tests. Use subagents when complex reasoning is needed (debugging, architectural decisions).
2. After implementing functionality or resolving problems, run the tests for that unit of code that was improved. Follow the commands specified in @agents.md for validation. If functionality is missing then it's your job to add it as per the application specifications. Think extra hard.
3. When you discover issues, immediately update @IMPLEMENTATION_PLAN.md with your findings using a subagent. When resolved, update and remove the item.
4. When the tests pass, update @IMPLEMENTATION_PLAN.md, then `git add -A` then `git commit` with a message describing the changes. After the commit, update @improvements.md with what was built, state changes, and important information discovered.

999. Important: When authoring documentation, capture the why — tests and implementation importance.
9999. Single sources of truth, no migrations/adapters. If tests unrelated to your work fail, resolve them as part of the increment.
99999. As soon as there are no build or test errors create a git tag. If there are no git tags start at 0.0.0 and increment patch by 1 for example 0.0.1 if 0.0.0 does not exist.
999999. You may add extra logging if required to debug issues.
9999999. Keep @IMPLEMENTATION_PLAN.md current with learnings using a subagent — future work depends on this to avoid duplicating efforts. Update especially after finishing your turn.
99999999. When you learn something new about how to run the application, update @agents.md using a subagent but keep it brief. For example if you run commands multiple times before learning the correct command then that file should be updated.
999999999. For any bugs you notice, resolve them or document them in @IMPLEMENTATION_PLAN.md using a subagent even if it is unrelated to the current piece of work.
9999999999. Implement functionality completely. Placeholders and stubs waste efforts and time redoing the same work.
99999999999. When @IMPLEMENTATION_PLAN.md becomes large periodically clean out the items that are completed from the file using a subagent.
999999999999. If you find inconsistencies in the specs/* then use a subagent with 'think extra hard' requested to update the specs.
9999999999999. IMPORTANT: Keep @agents.md operational only — status updates and progress notes belong in @IMPLEMENTATION_PLAN.md. A bloated AGENTS.md pollutes every future loop's context.
99999999999999. Update @improvements.md after each commit with what was built, state of app, and important information discovered.
EOF
            ;;
        qa)
            cat << 'EOF'
0a. Study `specs/*` with up to 500 parallel subagents to learn the application specifications.
0b. Study @IMPLEMENTATION_PLAN.md.
0c. Study @agents.md to understand build/test commands.
0d. Study @improvements.md to understand current state.

1. Your task is to perform comprehensive quality assurance on the application. Use up to 1000 parallel subagents to:
   a. Run all tests (unit, integration, e2e) as specified in @agents.md
   b. Run typecheck and lint commands
   c. Build the application to ensure no build errors
   d. Review code quality, architecture, and patterns
   e. Perform security analysis
   f. Analyze performance characteristics
   g. Check for edge cases and error handling

2. Use 1 subagent for running test suites (to maintain backpressure).
3. When issues are found, categorize them as:
   - Critical: Blocks release, must fix immediately
   - High: Important but can defer
   - Medium: Nice to have, low priority
   - Low: Minor issues, suggestions

4. Update @IMPLEMENTATION_PLAN.md with discovered issues using a subagent.
5. Generate a QA report in @improvements.md with:
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
