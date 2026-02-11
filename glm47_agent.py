#!/usr/bin/env python3
"""
GLM-4.7 Native Agent
Full-featured agent with file operations, command execution, and tool use
"""

import json
import os
import sys
import subprocess
import glob as glob_module
import re
import urllib.request
import urllib.error
from typing import List, Dict, Any, Optional, Callable


class GLM47Agent:
    """Native GLM-4.7 agent with full tool capabilities"""
    
    def __init__(
        self,
        api_key: str,
        base_url: str = "https://api.z.ai/api/coding/paas/v4",
        model: str = "glm-4.7",
        max_iterations: int = 10
    ):
        self.api_key = api_key
        self.base_url = base_url.rstrip('/')
        self.model = model
        self.max_iterations = max_iterations
        self.conversation_history: List[Dict[str, Any]] = []
        self.tools = self._register_tools()
        
    def _register_tools(self) -> Dict[str, Callable]:
        """Register available tools"""
        return {
            "read": self._tool_read,
            "write": self._tool_write,
            "edit": self._tool_edit,
            "glob": self._tool_glob,
            "grep": self._tool_grep,
            "bash": self._tool_bash,
            "list_files": self._tool_list_files,
        }
    
    def _tool_read(self, file_path: str) -> Dict[str, Any]:
        """Read file contents"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            return {"success": True, "content": content, "file": file_path}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _tool_write(self, file_path: str, content: str) -> Dict[str, Any]:
        """Write content to file"""
        try:
            os.makedirs(os.path.dirname(file_path) if os.path.dirname(file_path) else '.', exist_ok=True)
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return {"success": True, "message": f"Written to {file_path}", "bytes": len(content)}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _tool_edit(self, file_path: str, old_string: str, new_string: str, replace_all: bool = False) -> Dict[str, Any]:
        """Edit file by replacing text"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            count = content.count(old_string)
            if count == 0:
                return {"success": False, "error": "old_string not found in file"}
            
            if count > 1 and not replace_all:
                return {"success": False, "error": f"old_string found {count} times, use replace_all=true"}
            
            if replace_all:
                new_content = content.replace(old_string, new_string)
            else:
                new_content = content.replace(old_string, new_string, 1)
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            
            return {"success": True, "message": f"Replaced {count} occurrence(s) in {file_path}"}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _tool_glob(self, pattern: str, path: str = ".") -> Dict[str, Any]:
        """Find files matching pattern"""
        try:
            matches = glob_module.glob(os.path.join(path, pattern), recursive=True)
            return {"success": True, "files": matches, "count": len(matches)}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _tool_grep(self, pattern: str, path: str = ".", include: str = "*") -> Dict[str, Any]:
        """Search for pattern in files"""
        try:
            results = []
            regex = re.compile(pattern)
            
            for root, dirs, files in os.walk(path):
                for file in files:
                    if glob_module.fnmatch.fnmatch(file, include):
                        file_path = os.path.join(root, file)
                        try:
                            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                                for line_num, line in enumerate(f, 1):
                                    if regex.search(line):
                                        results.append({
                                            "file": file_path,
                                            "line": line_num,
                                            "content": line.strip()
                                        })
                        except:
                            pass
            
            return {"success": True, "results": results, "count": len(results)}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _tool_bash(self, command: str, timeout: int = 120000) -> Dict[str, Any]:
        """Execute bash command"""
        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=timeout / 1000,
                cwd=os.getcwd()
            )
            return {
                "success": result.returncode == 0,
                "exit_code": result.returncode,
                "stdout": result.stdout,
                "stderr": result.stderr
            }
        except subprocess.TimeoutExpired:
            return {"success": False, "error": "Command timed out"}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _tool_list_files(self, path: str = ".") -> Dict[str, Any]:
        """List files in directory"""
        try:
            files = []
            for item in os.listdir(path):
                item_path = os.path.join(path, item)
                files.append({
                    "name": item,
                    "path": item_path,
                    "is_dir": os.path.isdir(item_path)
                })
            return {"success": True, "files": files}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _call_api(self, messages: List[Dict[str, Any]], temperature: float = 0.7, max_tokens: int = 8192) -> Dict[str, Any]:
        """Call GLM-4.7 API"""
        url = f"{self.base_url}/chat/completions"
        
        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens
        }
        
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
                return json.loads(response_data)
        except urllib.error.HTTPError as e:
            error_body = e.read().decode('utf-8') if e.fp else 'No body'
            return {"error": True, "message": f"API error: {e}", "body": error_body}
        except Exception as e:
            return {"error": True, "message": str(e)}
    
    def _parse_tool_calls(self, content: str) -> List[Dict[str, Any]]:
        """Parse tool calls from model response"""
        tool_calls = []
        
        # Match patterns like: [TOOL: tool_name]...[ARGS: {...}]
        # Or: tool_name(arg1=val1, arg2=val2)
        # Or: ```tool\n{"tool": "name", "args": {...}}\n```
        
        # Pattern 1: Markdown code blocks
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
                # Try to parse as bash command
                tool_calls.append({"tool": "bash", "args": {"command": match.group(1).strip()}})
        
        # Pattern 2: [TOOL: name][ARGS: {...}]
        bracket_pattern = r'\[TOOL:\s*(\w+)\s*\]\s*\[ARGS:\s*({.*?})\s*\]'
        for match in re.finditer(bracket_pattern, content, re.DOTALL):
            try:
                tool_name = match.group(1)
                args = json.loads(match.group(2))
                tool_calls.append({"tool": tool_name, "args": args})
            except:
                pass
        
        return tool_calls
    
    def _execute_tool(self, tool_name: str, args: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a tool and return result"""
        if tool_name not in self.tools:
            return {"success": False, "error": f"Unknown tool: {tool_name}"}
        
        try:
            result = self.tools[tool_name](**args)
            return result
        except Exception as e:
            return {"success": False, "error": f"Tool execution error: {str(e)}"}
    
    def run(self, prompt: str, temperature: float = 0.7, max_tokens: int = 8192) -> Dict[str, Any]:
        """Run agent with prompt, executing tools as needed"""
        
        # Initialize conversation
        self.conversation_history = [{"role": "user", "content": prompt}]
        
        iteration = 0
        final_response = None
        
        while iteration < self.max_iterations:
            iteration += 1
            
            # Call API
            response = self._call_api(
                self.conversation_history,
                temperature=temperature,
                max_tokens=max_tokens
            )
            
            if response.get("error"):
                return response
            
            # Extract assistant message
            if "choices" not in response or len(response["choices"]) == 0:
                return {"error": True, "message": "No response from model"}
            
            assistant_message = response["choices"][0].get("message", {})
            content = assistant_message.get("content", "")
            
            # Add to conversation history
            self.conversation_history.append(assistant_message)
            
            # Parse tool calls
            tool_calls = self._parse_tool_calls(content)
            
            if not tool_calls:
                # No tool calls, we're done
                final_response = response
                break
            
            # Execute tools
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
                
                print(f"[Result] {json.dumps(result, indent=2)[:500]}")
            
            # Add tool results to conversation
            result_message = {
                "role": "user",
                "content": f"Tool execution results:\n{json.dumps(tool_results, indent=2)}"
            }
            self.conversation_history.append(result_message)
        
        return final_response if final_response else {"error": True, "message": "Max iterations reached"}


def main():
    """Run GLM-4.7 agent"""
    api_key = os.getenv("OPENCODE_API_KEY") or os.getenv("GLM_API_KEY")
    if not api_key:
        print("ERROR: OPENCODE_API_KEY or GLM_API_KEY not set", file=sys.stderr)
        sys.exit(1)
    
    agent = GLM47Agent(api_key=api_key, model="glm-4.7", max_iterations=50)
    
    # Get prompt from args or stdin
    if len(sys.argv) > 1:
        prompt = " ".join(sys.argv[1:])
    else:
        prompt = sys.stdin.read().strip()
    
    if not prompt:
        print("ERROR: No prompt provided", file=sys.stderr)
        sys.exit(1)
    
    # Enhance prompt with tool instructions
    enhanced_prompt = f"""{prompt}

IMPORTANT: You have access to the following tools. Use them by writing tool calls in this format:
```tool
{{"tool": "tool_name", "args": {{...}}}}
```

Available tools:
- read(file_path): Read file contents
- write(file_path, content): Write content to file
- edit(file_path, old_string, new_string, replace_all=False): Edit file
- glob(pattern, path="."): Find files matching pattern
- grep(pattern, path=".", include="*"): Search in files
- bash(command): Execute bash command
- list_files(path="."): List directory contents

Use these tools to complete the task. After using tools, analyze the results and continue.
"""
    
    print(f"[Agent] Running with prompt ({len(prompt)} chars)...")
    response = agent.run(enhanced_prompt, temperature=0.7, max_tokens=8192)
    
    if response.get("error"):
        print(f"\nERROR: {response.get('message')}", file=sys.stderr)
        sys.exit(1)
    
    # Print final response
    if "choices" in response and len(response["choices"]) > 0:
        content = response["choices"][0].get("message", {}).get("content", "")
        print("\n" + "="*80)
        print("FINAL RESPONSE:")
        print("="*80)
        print(content)
    else:
        print(json.dumps(response, indent=2))


if __name__ == "__main__":
    main()
