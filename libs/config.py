"""
Configuration and Provider Factory

Handles environment variables and provider instantiation.
"""

import os
from typing import Dict, Optional, Type
from libs.providers.base import BaseProvider
from libs.providers.glm47 import GLM47Provider
from libs.providers.claude import ClaudeProvider
from libs.providers.codex import CodexProvider
from libs.providers.kimmy_k2 import KimmyK2Provider


PROVIDER_REGISTRY: Dict[str, Type[BaseProvider]] = {
    "glm47": GLM47Provider,
    "claude": ClaudeProvider,
    "codex": CodexProvider,
    "kimmy_k2": KimmyK2Provider,
}

DEFAULT_PROVIDER = "glm47"


class Config:
    """Configuration loaded from environment variables."""
    
    def __init__(self):
        self.opencode_api_key = os.getenv("OPENCODE_API_KEY", "")
        self.anthropic_api_key = os.getenv("ANTHROPIC_API_KEY", "")
        self.openai_api_key = os.getenv("OPENAI_API_KEY", "")
        self.kimmy_k2_api_key = os.getenv("KIMMY_K2_API_KEY", "")
        self.provider = os.getenv("PROVIDER", DEFAULT_PROVIDER)
        self.max_iterations = int(os.getenv("MAX_ITERATIONS", "0"))
        self.model = os.getenv("OPENCODE_MODEL", "")
    
    def get_api_key(self, provider: str) -> Optional[str]:
        """Get API key for a specific provider."""
        key_map = {
            "glm47": self.opencode_api_key,
            "claude": self.anthropic_api_key,
            "codex": self.openai_api_key,
            "kimmy_k2": self.kimmy_k2_api_key,
        }
        return key_map.get(provider)
    
    def validate(self) -> bool:
        """Validate that required configuration is present."""
        if self.provider not in PROVIDER_REGISTRY:
            return False
        
        api_key = self.get_api_key(self.provider)
        if not api_key or api_key == "your_api_key_here":
            return False
        
        return True
    
    def get_missing_config(self) -> str:
        """Return description of missing configuration."""
        if self.provider not in PROVIDER_REGISTRY:
            return f"Unknown provider: {self.provider}. Available: {list(PROVIDER_REGISTRY.keys())}"
        
        api_key = self.get_api_key(self.provider)
        if not api_key or api_key == "your_api_key_here":
            key_names = {
                "glm47": "OPENCODE_API_KEY",
                "claude": "ANTHROPIC_API_KEY",
                "codex": "OPENAI_API_KEY",
                "kimmy_k2": "KIMMY_K2_API_KEY",
            }
            return f"API key not set for provider {self.provider}. Set {key_names[self.provider]}"
        
        return ""


def get_provider(
    provider_name: Optional[str] = None,
    api_key: Optional[str] = None,
    model: Optional[str] = None,
    **kwargs
) -> BaseProvider:
    """
    Factory function to create a provider instance.
    
    Args:
        provider_name: Provider name (glm47, claude, codex, kimmy_k2)
        api_key: API key for the provider
        model: Model override
        **kwargs: Additional provider-specific options
    
    Returns:
        Configured provider instance
    
    Raises:
        ValueError: If provider is unknown or API key is missing
    """
    config = Config()
    
    provider_name = provider_name or config.provider
    
    if provider_name not in PROVIDER_REGISTRY:
        raise ValueError(
            f"Unknown provider: {provider_name}. "
            f"Available providers: {list(PROVIDER_REGISTRY.keys())}"
        )
    
    if not api_key:
        api_key = config.get_api_key(provider_name)
    
    if not api_key or api_key == "your_api_key_here":
        key_names = {
            "glm47": "OPENCODE_API_KEY",
            "claude": "ANTHROPIC_API_KEY",
            "codex": "OPENAI_API_KEY",
            "kimmy_k2": "KIMMY_K2_API_KEY",
        }
        raise ValueError(
            f"API key not provided for provider {provider_name}. "
            f"Set {key_names[provider_name]} environment variable or pass api_key parameter."
        )
    
    provider_class = PROVIDER_REGISTRY[provider_name]
    return provider_class(api_key=api_key, model=model, **kwargs)


def list_providers() -> Dict[str, str]:
    """Return available providers and their descriptions."""
    return {
        "glm47": "GLM-4.7 via Z.AI API (default)",
        "claude": "Anthropic Claude via Anthropic API",
        "codex": "OpenAI GPT-4/Codex via OpenAI API",
        "kimmy_k2": "Kimmy K2 (placeholder - API details TBD)",
    }
