"""
Base Agent Class

Provides the core agent functionality with tool execution.
"""

import json
import re
import time
from typing import List, Dict, Any, Optional, Callable

from libs.providers.base import BaseProvider, ProviderError
from libs.tools.tools import ToolRegistry


class BaseAgent:
    """
    Base agent with conversation history, tool execution, and provider integration.
    """
    
    def __init__(
        self,
        provider: BaseProvider,
        max_iterations: int = 100,
        tools: Optional[ToolRegistry] = None,
        retry_on_error: int = 2
    ):
        self.provider = provider
        self.max_iterations = max_iterations
        self.conversation_history: List[Dict[str, Any]] = []
        self.tools = tools or ToolRegistry()
        self.retry_on_error = retry_on_error
    
    def _parse_tool_calls(self, content: str) -> List[Dict[str, Any]]:
        """Parse tool calls from model response."""
        tool_calls = []
        
        md_pattern = r'```(?:tool|bash|command)\s*\n(.*?)\n```'
        for match in re.finditer(md_pattern, content, re.DOTALL):
            try:
                tool_data = json.loads(match.group(1))
                if isinstance(tool_data, dict) and 'tool' in tool_data:
                    tool_calls.append({
                        "tool": tool_data['tool'],
                        "args": tool_data.get('args', tool_data.get('arguments', {}))
                    })
            except json.JSONDecodeError:
                tool_calls.append({"tool": "bash", "args": {"command": match.group(1).strip()}})
        
        bracket_pattern = r'\[TOOL:\s*(\w+)\s*\]\s*\[ARGS:\s*({.*?})\s*\]'
        for match in re.finditer(bracket_pattern, content, re.DOTALL):
            try:
                tool_name = match.group(1)
                args = json.loads(match.group(2))
                tool_calls.append({"tool": tool_name, "args": args})
            except (json.JSONDecodeError, KeyError, TypeError):
                pass
        
        return tool_calls
    
    def _execute_tool(self, tool_name: str, args: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a tool and return result."""
        tool_func = self.tools.get(tool_name)
        
        if tool_func is None:
            return {"success": False, "error": f"Unknown tool: {tool_name}"}
        
        try:
            result = tool_func(**args)
            return result
        except Exception as e:
            return {"success": False, "error": f"Tool execution error: {str(e)}"}
    
    def run(
        self,
        prompt: str,
        temperature: float = 0.7,
        max_tokens: int = 8192,
        system_prompt: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Run agent with prompt, executing tools as needed.
        
        Args:
            prompt: The user prompt
            temperature: Sampling temperature
            max_tokens: Maximum tokens to generate
            system_prompt: Optional system prompt to prepend
        
        Returns:
            Final response from the provider
        """
        messages = []
        
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        
        messages.append({"role": "user", "content": prompt})
        self.conversation_history = list(messages)
        
        iteration = 0
        final_response = None
        last_content = ""
        consecutive_errors = 0
        
        while iteration < self.max_iterations:
            iteration += 1
            
            try:
                response = self.provider.chat(
                    messages=self.conversation_history,
                    temperature=temperature,
                    max_tokens=max_tokens
                )
                consecutive_errors = 0
            except ProviderError as e:
                consecutive_errors += 1
                error_msg = str(e)
                print(f"\n[Error] Provider error (attempt {consecutive_errors}): {error_msg[:200]}")
                
                if consecutive_errors > self.retry_on_error:
                    return {
                        "error": True,
                        "message": f"Provider failed after {consecutive_errors} attempts: {error_msg}",
                        "provider": self.provider.name,
                        "partial_content": last_content
                    }
                
                time.sleep(2 * consecutive_errors)
                continue
            
            content = response.get("content", "")
            last_content = content
            final_response = response
            
            assistant_message = {"role": "assistant", "content": content}
            self.conversation_history.append(assistant_message)
            
            tool_calls = self._parse_tool_calls(content)
            
            if not tool_calls:
                break
            
            tool_results = []
            for tool_call in tool_calls:
                tool_name = tool_call.get("tool")
                tool_args = tool_call.get("args", {})
                
                print(f"[Tool] {tool_name}({json.dumps(tool_args, indent=2) if isinstance(tool_args, dict) else tool_args})")
                
                result = self._execute_tool(tool_name, tool_args)
                tool_results.append({
                    "tool": tool_name,
                    "args": tool_args,
                    "result": result
                })
                
                result_str = json.dumps(result, indent=2)
                if len(result_str) > 500:
                    result_str = result_str[:500] + "..."
                print(f"[Result] {result_str}")
            
            result_message = {
                "role": "user",
                "content": f"Tool execution results:\n{json.dumps(tool_results, indent=2)}"
            }
            self.conversation_history.append(result_message)
        
        if final_response is None:
            return {"error": True, "message": "No response from provider"}
        
        if iteration >= self.max_iterations:
            print(f"\n[Warning] Reached max iterations ({self.max_iterations}), returning last response")
        
        return final_response
    
    def reset(self):
        """Reset conversation history."""
        self.conversation_history = []
    
    def get_tool_instructions(self) -> str:
        """Get formatted tool instructions to include in prompts."""
        return f"""
IMPORTANT: You have access to the following tools. Use them by writing tool calls in this format:
```tool
{{"tool": "tool_name", "args": {{...}}}}
```

{self.tools.get_tool_descriptions()}

Use these tools to complete the task. After using tools, analyze the results and continue.
"""
