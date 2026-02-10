#!/bin/bash
# Ralph Loop Script - Docker-based with GLM-4.7
# Usage: ./loop.sh [planning|building|qa] [max_iterations]
#
# Examples:
#   ./loop.sh planning          # Planning mode, unlimited iterations
#   ./loop.sh building 20       # Building mode, max 20 iterations
#   ./loop.sh qa 5              # QA mode, max 5 iterations
#   ./loop.sh                   # Default: building mode, unlimited

set -e

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
if [ -z "$1" ]; then
    MODE="building"
    PROMPT_FILE="PROMPT_building.md"
    MAX_ITERATIONS=${2:-0}
elif [ "$1" = "planning" ] || [ "$1" = "building" ] || [ "$1" = "qa" ]; then
    MODE="$1"
    PROMPT_FILE="PROMPT_${MODE}.md"
    MAX_ITERATIONS=${2:-0}
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    MODE="building"
    PROMPT_FILE="PROMPT_building.md"
    MAX_ITERATIONS=$1
else
    echo "Unknown mode: $1"
    echo "Usage: $0 [planning|building|qa] [max_iterations]"
    exit 1
fi

# Environment configuration
GLM_MODE=${GLM_MODE:-api}
GLM_MODEL=${GLM_MODEL:-glm-4.7}

# Determine CLI command based on mode
if [ "$GLM_MODE" = "local" ]; then
    CLI_CMD="glm-cli --local --model-path $GLM_LOCAL_PATH"
else
    CLI_CMD="glm-cli --api"
fi

ITERATION=0
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Ralph Loop Started${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Mode:           ${YELLOW}$MODE${NC}"
echo -e "Prompt File:    $PROMPT_FILE"
echo -e "Branch:         $CURRENT_BRANCH"
echo -e "GLM Model:      $GLM_MODEL"
echo -e "GLM Mode:       $GLM_MODE"
[ $MAX_ITERATIONS -gt 0 ] && echo -e "Max Iterations: $MAX_ITERATIONS"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Verify prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo -e "${YELLOW}Warning: $PROMPT_FILE not found, creating from template...${NC}"
    create_prompt_template "$MODE" > "$PROMPT_FILE"
fi

# Verify required directories exist
mkdir -p specs src

# Main loop
while true; do
    # Check max iterations
    if [ $MAX_ITERATIONS -gt 0 ] && [ $ITERATION -ge $MAX_ITERATIONS ]; then
        echo -e "${GREEN}✓ Reached max iterations: $MAX_ITERATIONS${NC}"
        break
    fi

    ITERATION=$((ITERATION + 1))
    echo -e "\n${BLUE}======================== ITERATION $ITERATION ========================${NC}"
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} Starting iteration..."
    
    # Run Ralph iteration with GLM-4.7
    # Flags:
    #   -p: Headless mode (non-interactive, reads from stdin)
    #   --dangerously-skip-permissions: Auto-approve all tool calls
    #   --model: Use GLM-4.7
    #   --verbose: Detailed execution logging
    if cat "$PROMPT_FILE" | $CLI_CMD \
        --dangerously-skip-permissions \
        --model "$GLM_MODEL" \
        --verbose; then
        
        echo -e "${GREEN}✓ Iteration $ITERATION completed successfully${NC}"
    else
        echo -e "${YELLOW}⚠ Iteration $ITERATION failed with exit code $?${NC}"
        echo -e "${YELLOW}Loop will continue to next iteration${NC}"
    fi
    
    # Git push after each iteration (for building mode)
    if [ "$MODE" = "building" ] && git remote get-url origin &>/dev/null; then
        git push origin "$CURRENT_BRANCH" 2>/dev/null || {
            echo -e "${YELLOW}Creating remote branch...${NC}"
            git push -u origin "$CURRENT_BRANCH" 2>/dev/null || true
        }
    fi
    
    # Update improvements.md with iteration summary
    if [ "$MODE" = "building" ] && [ -f "improvements.md" ]; then
        echo "" >> improvements.md
        echo "### Iteration $ITERATION - $(date '+%Y-%m-%d %H:%M:%S')" >> improvements.md
        echo "- Mode: $MODE" >> improvements.md
        echo "- Status: Completed" >> improvements.md
        echo "" >> improvements.md
    fi
    
    echo -e "${BLUE}======================== END ITERATION $ITERATION ========================${NC}\n"
done

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Ralph Loop Completed - $ITERATION iterations${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Function to create prompt templates
create_prompt_template() {
    local mode=$1
    case $mode in
        planning)
            cat << 'EOF'
0a. Study `specs/*` with up to 500 parallel GLM-4.7 subagents to learn the application specifications.
0b. Study @IMPLEMENTATION_PLAN.md (if present) to understand the plan so far.
0c. Study `src/lib/*` with up to 500 parallel GLM-4.7 subagents to understand shared utilities & components.
0d. For reference, the application source code is in `src/*`.

1. Study @IMPLEMENTATION_PLAN.md (if present; it may be incorrect) and use up to 1000 GLM-4.7 subagents to study existing source code in `src/*` and compare it against `specs/*`. Use a GLM-4.7 subagent to analyze findings, prioritize tasks, and create/update @IMPLEMENTATION_PLAN.md as a bullet point list sorted in priority of items yet to be implemented. Think extra hard. Consider searching for TODO, minimal implementations, placeholders, skipped/flaky tests, and inconsistent patterns. Study @IMPLEMENTATION_PLAN.md to determine starting point for research and keep it up to date with items considered complete/incomplete using subagents.

IMPORTANT: Plan only. Do NOT implement anything. Do NOT assume functionality is missing; confirm with code search first. Treat `src/lib` as the project's standard library for shared utilities and components. Prefer consolidated, idiomatic implementations there over ad-hoc copies.

ULTIMATE GOAL: Build the application according to specifications in `specs/*`. Consider missing elements and plan accordingly. If an element is missing, search first to confirm it doesn't exist, then if needed author the specification at specs/FILENAME.md. If you create a new element then document the plan to implement it in @IMPLEMENTATION_PLAN.md using a subagent.

9999999. Keep @IMPLEMENTATION_PLAN.md current with learnings using a subagent — future work depends on this to avoid duplicating efforts.
99999999. If you find inconsistencies in the specs/* then use a GLM-4.7 subagent with 'think extra hard' requested to update the specs.
EOF
            ;;
        building)
            cat << 'EOF'
0a. Study `specs/*` with up to 1000 parallel GLM-4.7 subagents to learn the application specifications.
0b. Study @IMPLEMENTATION_PLAN.md.
0c. For reference, the application source code is in `src/*`.

1. Your task is to implement functionality per the specifications using parallel subagents. Follow @IMPLEMENTATION_PLAN.md and choose the most important item to address. Before making changes, search the codebase (don't assume not implemented) using GLM-4.7 subagents. You may use up to 1000 parallel GLM-4.7 subagents for searches/reads and only 1 GLM-4.7 subagent for build/tests. Use GLM-4.7 subagents when complex reasoning is needed (debugging, architectural decisions).
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
999999999999. If you find inconsistencies in the specs/* then use a GLM-4.7 subagent with 'think extra hard' requested to update the specs.
9999999999999. IMPORTANT: Keep @agents.md operational only — status updates and progress notes belong in @IMPLEMENTATION_PLAN.md. A bloated AGENTS.md pollutes every future loop's context.
99999999999999. Update @improvements.md after each commit with what was built, state of app, and important information discovered.
EOF
            ;;
        qa)
            cat << 'EOF'
0a. Study `specs/*` with up to 500 parallel GLM-4.7 subagents to learn the application specifications.
0b. Study @IMPLEMENTATION_PLAN.md.
0c. Study @agents.md to understand build/test commands.
0d. Study @improvements.md to understand current state.

1. Your task is to perform comprehensive quality assurance on the application. Use up to 1000 parallel GLM-4.7 subagents to:
   a. Run all tests (unit, integration, e2e) as specified in @agents.md
   b. Run typecheck and lint commands
   c. Build the application to ensure no build errors
   d. Review code quality, architecture, and patterns
   e. Perform security analysis
   f. Analyze performance characteristics
   g. Check for edge cases and error handling

2. Use 1 GLM-4.7 subagent for running test suites (to maintain backpressure).
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
