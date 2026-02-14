"""
Claude Provider

Implements the Anthropic Claude API.
"""

import json
import urllib.request
import urllib.error
from typing import Dict, Any, List, Optional

from libs.providers.base import BaseProvider, ProviderError


class ClaudeProvider(BaseProvider):
    """Claude provider via Anthropic API."""
    
    name = "claude"
    default_model = "claude-sonnet-4-20250514"
    default_base_url = "https://api.anthropic.com/v1"
    
    def __init__(
        self,
        api_key: str,
        model: Optional[str] = None,
        base_url: Optional[str] = None,
        **kwargs
    ):
        super().__init__(api_key, model, base_url, **kwargs)
        self.base_url = (base_url or self.default_base_url).rstrip('/')
    
    def _convert_messages_to_claude_format(
        self,
        messages: List[Dict[str, Any]]
    ) -> tuple[str, List[Dict[str, Any]]]:
        """
        Convert OpenAI-style messages to Claude format.
        
        Claude expects a separate 'system' message and messages without 'system' role.
        """
        system_prompt = ""
        claude_messages = []
        
        for msg in messages:
            role = msg.get("role", "")
            content = msg.get("content", "")
            
            if role == "system":
                system_prompt = content
            elif role in ("user", "assistant"):
                claude_messages.append({
                    "role": role,
                    "content": content
                })
        
        return system_prompt, claude_messages
    
    def chat(
        self,
        messages: List[Dict[str, Any]],
        temperature: float = 0.7,
        max_tokens: int = 8192,
        **kwargs
    ) -> Dict[str, Any]:
        """Send chat completion request to Claude API."""
        
        url = f"{self.base_url}/messages"
        
        system_prompt, claude_messages = self._convert_messages_to_claude_format(messages)
        
        payload = {
            "model": self.model,
            "messages": claude_messages,
            "max_tokens": max_tokens,
        }
        
        if system_prompt:
            payload["system"] = system_prompt
        
        if temperature is not None:
            payload["temperature"] = temperature
        
        if kwargs:
            for key, value in kwargs.items():
                if key not in payload:
                    payload[key] = value
        
        data = json.dumps(payload).encode('utf-8')
        
        req = urllib.request.Request(
            url,
            data=data,
            method='POST',
            headers={
                'x-api-key': self.api_key,
                'anthropic-version': '2023-06-01',
                'Content-Type': 'application/json'
            }
        )
        
        try:
            with urllib.request.urlopen(req, timeout=120) as response:
                response_data = response.read().decode('utf-8')
                result = json.loads(response_data)
                
                if "content" in result and len(result["content"]) > 0:
                    content = result["content"][0].get("text", "")
                    return {
                        "content": content,
                        "raw": result,
                        "model": self.model
                    }
                else:
                    raise ProviderError(
                        "No response from Claude",
                        provider=self.name,
                        raw_error=result
                    )
                    
        except urllib.error.HTTPError as e:
            error_body = e.read().decode('utf-8') if e.fp else 'No body'
            raise ProviderError(
                f"Claude API error: {e.code} - {error_body}",
                provider=self.name,
                raw_error=e
            )
        except json.JSONDecodeError as e:
            raise ProviderError(
                f"Invalid JSON response from Claude: {e}",
                provider=self.name,
                raw_error=e
            )
        except Exception as e:
            raise ProviderError(
                f"Claude request failed: {e}",
                provider=self.name,
                raw_error=e
            )
    
    def get_model_name(self) -> str:
        return self.model
