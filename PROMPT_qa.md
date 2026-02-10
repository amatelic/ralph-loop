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
