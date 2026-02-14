"""
Kimmy K2 Provider

Placeholder for Kimmy K2 integration.
API details are pending - this provider will be implemented
once the API specification is available.
"""

from typing import Dict, Any, List, Optional

from libs.providers.base import BaseProvider, ProviderError


class KimmyK2Provider(BaseProvider):
    """Kimmy K2 provider - placeholder implementation."""
    
    name = "kimmy_k2"
    default_model = "kimmy-k2"
    default_base_url = "https://api.kimmy.ai/v1"
    
    def __init__(
        self,
        api_key: str,
        model: Optional[str] = None,
        base_url: Optional[str] = None,
        **kwargs
    ):
        super().__init__(api_key, model, base_url, **kwargs)
        self.base_url = (base_url or self.default_base_url).rstrip('/')
    
    def chat(
        self,
        messages: List[Dict[str, Any]],
        temperature: float = 0.7,
        max_tokens: int = 8192,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Send chat completion request to Kimmy K2 API.
        
        NOTE: This is a placeholder. The Kimmy K2 API details are not yet available.
        This method will raise NotImplementedError until the API is documented.
        """
        raise NotImplementedError(
            "Kimmy K2 provider is not yet implemented. "
            "API details are pending. "
            "Please use a different provider (glm47, claude, or codex)."
        )
    
    def get_model_name(self) -> str:
        return self.model
