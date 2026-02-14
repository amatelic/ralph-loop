"""
Base Provider Interface

All AI providers must implement this interface.
"""

from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional


class BaseProvider(ABC):
    """Abstract base class for AI providers."""
    
    name: str = "base"
    default_model: str = ""
    
    def __init__(
        self,
        api_key: str,
        model: Optional[str] = None,
        base_url: Optional[str] = None,
        **kwargs
    ):
        self.api_key = api_key
        self.model = model or self.default_model
        self.base_url = base_url
        self.extra_kwargs = kwargs
    
    @abstractmethod
    def chat(
        self,
        messages: List[Dict[str, Any]],
        temperature: float = 0.7,
        max_tokens: int = 8192,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Send a chat completion request.
        
        Args:
            messages: List of message dicts with 'role' and 'content'
            temperature: Sampling temperature
            max_tokens: Maximum tokens to generate
            **kwargs: Provider-specific options
        
        Returns:
            Response dict with at minimum:
            - 'content': The generated text
            - 'raw': The raw API response (optional)
        
        Raises:
            ProviderError: On API errors
        """
        pass
    
    @abstractmethod
    def get_model_name(self) -> str:
        """Return the model name being used."""
        pass
    
    def validate_api_key(self) -> bool:
        """Check if API key appears valid (non-empty, not placeholder)."""
        if not self.api_key:
            return False
        if self.api_key == "your_api_key_here":
            return False
        return True
    
    def __repr__(self) -> str:
        return f"{self.__class__.__name__}(model={self.model})"


class ProviderError(Exception):
    """Exception raised for provider-related errors."""
    
    def __init__(self, message: str, provider: str = "", raw_error: Any = None):
        self.provider = provider
        self.raw_error = raw_error
        super().__init__(message)
