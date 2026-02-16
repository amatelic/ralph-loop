"""
Tools for file operations, command execution, and search.

These tools are used by the agent to interact with the filesystem
and execute commands.
"""

import os
import re
import json
import subprocess
import glob as glob_module
from typing import Dict, Any, List, Optional, Callable


def get_project_root() -> str:
    """Get the project root directory."""
    return os.environ.get('PROJECT_ROOT', os.getcwd())


def is_within_project(file_path: str) -> bool:
    """Check if a file path is within the project directory."""
    project_root = get_project_root()
    abs_file_path = os.path.abspath(file_path)
    abs_project_root = os.path.abspath(project_root)
    
    try:
        os.path.relpath(abs_file_path, abs_project_root)
        return True
    except ValueError:
        return False


class ToolRegistry:
    """Registry for available tools."""
    
    def __init__(self):
        self._tools: Dict[str, Callable] = {}
        self._register_defaults()
    
    def _register_defaults(self):
        """Register default tools."""
        self._tools = {
            "read": read_file,
            "write": write_file,
            "edit": edit_file,
            "glob": glob_search,
            "grep": grep_search,
            "bash": bash_command,
            "list_files": list_files,
        }
    
    def register(self, name: str, func: Callable):
        """Register a new tool."""
        self._tools[name] = func
    
    def get(self, name: str) -> Optional[Callable]:
        """Get a tool by name."""
        return self._tools.get(name)
    
    def list_tools(self) -> List[str]:
        """List available tool names."""
        return list(self._tools.keys())
    
    def get_tool_descriptions(self) -> str:
        """Get formatted descriptions of all tools."""
        return """
Available tools:
- read(file_path): Read file contents
- write(file_path, content): Write content to file (restricted to project directory)
- edit(file_path, old_string, new_string, replace_all=False): Edit file (restricted to project directory)
- glob(pattern, path="."): Find files matching pattern
- grep(pattern, path=".", include="*"): Search in files
- bash(command, timeout=120000): Execute bash command
- list_files(path="."): List directory contents

NOTE: write_file and edit_file can only modify files within the project directory."""


def read_file(file_path: str) -> Dict[str, Any]:
    """Read file contents."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        return {"success": True, "content": content, "file": file_path}
    except Exception as e:
        return {"success": False, "error": str(e)}


def write_file(file_path: str, content: str) -> Dict[str, Any]:
    """Write content to file."""
    try:
        # Validate file is within project directory
        if not is_within_project(file_path):
            project_root = get_project_root()
            return {
                "success": False,
                "error": f"Cannot write file outside project directory. File: {file_path}, Project root: {project_root}"
            }
        
        dir_path = os.path.dirname(file_path)
        if dir_path:
            os.makedirs(dir_path, exist_ok=True)
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return {"success": True, "message": f"Written to {file_path}", "bytes": len(content)}
    except Exception as e:
        return {"success": False, "error": str(e)}


def edit_file(
    file_path: str,
    old_string: str,
    new_string: str,
    replace_all: bool = False
) -> Dict[str, Any]:
    """Edit file by replacing text."""
    try:
        # Validate file is within project directory
        if not is_within_project(file_path):
            project_root = get_project_root()
            return {
                "success": False,
                "error": f"Cannot edit file outside project directory. File: {file_path}, Project root: {project_root}"
            }
        
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


def glob_search(pattern: str, path: str = ".") -> Dict[str, Any]:
    """Find files matching pattern."""
    try:
        matches = glob_module.glob(os.path.join(path, pattern), recursive=True)
        return {"success": True, "files": matches, "count": len(matches)}
    except Exception as e:
        return {"success": False, "error": str(e)}


def grep_search(
    pattern: str,
    path: str = ".",
    include: str = "*"
) -> Dict[str, Any]:
    """Search for pattern in files."""
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
                    except (IOError, OSError, PermissionError):
                        pass
        
        return {"success": True, "results": results, "count": len(results)}
    except Exception as e:
        return {"success": False, "error": str(e)}


def bash_command(command: str, timeout: int = 120000) -> Dict[str, Any]:
    """Execute bash command."""
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


def list_files(path: str = ".") -> Dict[str, Any]:
    """List files in directory."""
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
