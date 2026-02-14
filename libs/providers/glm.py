"""
GLM Provider

Implements the Z.AI GLM API (supports glm-4.7, glm-5, etc).
"""

import json
import urllib.request
import urllib.error
from typing import Dict, Any, List, Optional

from libs.providers.base import BaseProvider, ProviderError


class GLMProvider(BaseProvider):
    """GLM provider via Z.AI API (supports glm-4.7, glm-5)."""
    
    name = "glm"
    default_model = "glm-4.7"
    default_base_url = "https://api.z.ai/api/coding/paas/v4"
    max_output_tokens = 32768
    
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
        max_tokens: int = None,
        **kwargs
    ) -> Dict[str, Any]:
        """Send chat completion request to GLM API."""
        
        if max_tokens is None:
            max_tokens = self.max_output_tokens
        
        url = f"{self.base_url}/chat/completions"
        
        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens
        }
        
        if kwargs:
            payload.update(kwargs)
        
        data = json.dumps(payload).encode('utf-8')
        
        req = urllib.request.Request(
            url,
            data=data,
            method='POST',
            headers={
                'Authorization': f'Bearer {self.api_key}',
                'Content-Type': 'application/json'
            }
        )
        
        try:
            with urllib.request.urlopen(req, timeout=120) as response:
                response_data = response.read().decode('utf-8')
                result = json.loads(response_data)
                
                if "choices" in result and len(result["choices"]) > 0:
                    message = result["choices"][0].get("message", {})
                    content = message.get("content", "")
                    reasoning = message.get("reasoning_content", "")
                    return {
                        "content": content,
                        "reasoning": reasoning,
                        "raw": result,
                        "model": self.model
                    }
                else:
                    raise ProviderError(
                        "No response from GLM",
                        provider=self.name,
                        raw_error=result
                    )
                    
        except urllib.error.HTTPError as e:
            error_body = e.read().decode('utf-8') if e.fp else 'No body'
            raise ProviderError(
                f"GLM API error: {e.code} - {error_body}",
                provider=self.name,
                raw_error=e
            )
        except json.JSONDecodeError as e:
            raise ProviderError(
                f"Invalid JSON response from GLM: {e}",
                provider=self.name,
                raw_error=e
            )
        except Exception as e:
            raise ProviderError(
                f"GLM request failed: {e}",
                provider=self.name,
                raw_error=e
            )
    
    def get_model_name(self) -> str:
        return self.model
