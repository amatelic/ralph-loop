#!/usr/bin/env python3
"""
Ralph Loop Agent - Multi-Provider Entry Point

Usage:
    python glm47_agent.py "your prompt here"
    echo "your prompt" | python glm47_agent.py

Environment Variables:
    PROVIDER: Provider to use (glm47, claude, codex, kimmy_k2) - default: glm47
    OPENCODE_API_KEY: API key for GLM-4.7
    ANTHROPIC_API_KEY: API key for Claude
    OPENAI_API_KEY: API key for OpenAI/Codex
    KIMMY_K2_API_KEY: API key for Kimmy K2
"""

import os
import sys

from libs.config import get_provider, Config, list_providers
from libs.agent.base import BaseAgent
from libs.providers.base import ProviderError


def main():
    """Run agent with configured provider."""
    
    config = Config()
    
    if not config.validate():
        missing = config.get_missing_config()
        print(f"ERROR: {missing}", file=sys.stderr)
        print("", file=sys.stderr)
        print("Available providers:", file=sys.stderr)
        for name, desc in list_providers().items():
            marker = " (selected)" if name == config.provider else ""
            print(f"  - {name}: {desc}{marker}", file=sys.stderr)
        print("", file=sys.stderr)
        print("Set PROVIDER and corresponding API key environment variable.", file=sys.stderr)
        sys.exit(1)
    
    if len(sys.argv) > 1:
        if sys.argv[1] in ("--help", "-h", "help"):
            print("Ralph Loop Agent - Multi-Provider AI Agent")
            print("")
            print("Usage:")
            print("  python glm47_agent.py \"your prompt\"")
            print("  echo \"prompt\" | python glm47_agent.py")
            print("")
            print("Environment Variables:")
            print("  PROVIDER          Provider to use (default: glm47)")
            print("  OPENCODE_API_KEY  API key for GLM-4.7")
            print("  ANTHROPIC_API_KEY API key for Claude")
            print("  OPENAI_API_KEY    API key for OpenAI/Codex")
            print("  KIMMY_K2_API_KEY  API key for Kimmy K2")
            print("")
            print("Available Providers:")
            for name, desc in list_providers().items():
                print(f"  {name}: {desc}")
            sys.exit(0)
        
        prompt = " ".join(sys.argv[1:])
    else:
        prompt = sys.stdin.read().strip()
    
    if not prompt:
        print("ERROR: No prompt provided", file=sys.stderr)
        print("Usage: python glm47_agent.py \"your prompt\"", file=sys.stderr)
        sys.exit(1)
    
    try:
        provider = get_provider()
    except ValueError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
    
    agent = BaseAgent(provider=provider, max_iterations=50)
    
    enhanced_prompt = f"{prompt}\n\n{agent.get_tool_instructions()}"
    
    print(f"[Agent] Running with {provider.name} ({provider.get_model_name()})", file=sys.stderr)
    print(f"[Agent] Prompt length: {len(prompt)} chars", file=sys.stderr)
    
    try:
        response = agent.run(enhanced_prompt, temperature=0.7, max_tokens=8192)
    except ProviderError as e:
        print(f"\nERROR: {e}", file=sys.stderr)
        sys.exit(1)
    
    if response.get("error"):
        print(f"\nERROR: {response.get('message')}", file=sys.stderr)
        sys.exit(1)
    
    print("\n" + "="*80)
    print("FINAL RESPONSE:")
    print("="*80)
    print(response.get("content", ""))


if __name__ == "__main__":
    main()
