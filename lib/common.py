#!/usr/bin/env python3
"""
common.py: Utility functions for cluster management scripts
Usage: from lib.common import log, command_exists, run_command, etc.
"""

import os
import sys
import subprocess
import socket
from datetime import datetime
from pathlib import Path
from typing import Optional, Tuple, List
import re


class Colors:
    """ANSI color codes for terminal output"""
    GREEN = "\033[1;32m"
    RED = "\033[1;31m"
    YELLOW = "\033[1;33m"
    RESET = "\033[0m"


def get_wsl_ip() -> str:
    """
    Get the IP address of the WSL2 instance.
    Returns the first non-loopback IP address.
    """
    try:
        result = subprocess.run(
            ["hostname", "-I"],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip().split()[0]
    except (subprocess.CalledProcessError, IndexError):
        return "127.0.0.1"


def log(level: str, message: str, progress: bool = False) -> None:
    """
    Log messages with color coding and timestamps.
    
    Args:
        level: Log level (INFO, ERROR, WARN, PROGRESS)
        message: Message to display
        progress: If True, don't add newline (for progress indicators)
    """
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    color_map = {
        "INFO": Colors.GREEN,
        "ERROR": Colors.RED,
        "WARN": Colors.YELLOW,
        "PROGRESS": Colors.YELLOW
    }
    
    color = color_map.get(level, Colors.RESET)
    
    if level == "PROGRESS" or progress:
        print(f"{color}>>>>> {message}{Colors.RESET}", end="", flush=True, file=sys.stderr)
    else:
        print(f"{color}{timestamp} [{level}] {message}{Colors.RESET}", file=sys.stderr)


def command_exists(command: str) -> bool:
    """
    Check if a command exists in the system PATH.
    
    Args:
        command: Command name to check
        
    Returns:
        True if command exists, False otherwise
    """
    if not command:
        log("ERROR", "No command provided to command_exists.")
        return False
    
    from shutil import which
    return which(command) is not None


def run_command(
    command: str | List[str],
    check: bool = True,
    shell: bool = False,
    capture_output: bool = False,
    env: Optional[dict] = None,
    cwd: Optional[str] = None
) -> Tuple[int, str, str]:
    """
    Run a shell command with proper error handling.
    
    Args:
        command: Command to run (string or list of arguments)
        check: If True, raise exception on non-zero exit code
        shell: If True, run command through shell
        capture_output: If True, capture stdout and stderr
        env: Environment variables to pass to command
        cwd: Working directory for command
        
    Returns:
        Tuple of (return_code, stdout, stderr)
    """
    try:
        if isinstance(command, str) and not shell:
            command = command.split()
        
        result = subprocess.run(
            command,
            shell=shell,
            capture_output=capture_output,
            text=True,
            check=check,
            env=env,
            cwd=cwd
        )
        
        return (
            result.returncode,
            result.stdout if capture_output else "",
            result.stderr if capture_output else ""
        )
    except subprocess.CalledProcessError as e:
        return (e.returncode, e.stdout if capture_output else "", e.stderr if capture_output else "")


def sudo_command(
    command: str | List[str],
    check: bool = True,
    capture_output: bool = False
) -> Tuple[int, str, str]:
    """
    Run a command with sudo privileges.
    
    Args:
        command: Command to run
        check: If True, raise exception on non-zero exit code
        capture_output: If True, capture stdout and stderr
        
    Returns:
        Tuple of (return_code, stdout, stderr)
    """
    if isinstance(command, str):
        command = f"sudo {command}"
    else:
        command = ["sudo"] + command
    
    return run_command(command, check=check, capture_output=capture_output, shell=isinstance(command, str))


def replace_in_file(filepath: str, search: str, replace: str, use_regex: bool = False) -> bool:
    """
    Replace a string in a file.
    
    Args:
        filepath: Path to the file
        search: String or regex pattern to search for
        replace: Replacement string
        use_regex: If True, treat search as regex pattern
        
    Returns:
        True if replacement was successful, False otherwise
    """
    try:
        file_path = Path(filepath)
        
        if not file_path.exists():
            log("ERROR", f"File {filepath} does not exist.")
            return False
        
        content = file_path.read_text()
        
        if use_regex:
            new_content = re.sub(search, replace, content)
        else:
            new_content = content.replace(search, replace)
        
        file_path.write_text(new_content)
        log("INFO", f"Replaced '{search}' with '{replace}' in {filepath}.")
        return True
        
    except Exception as e:
        log("ERROR", f"Failed to replace in file: {e}")
        return False


def detect_os() -> str:
    """
    Detect the operating system.
    
    Returns:
        OS identifier: debian, rhel, centos, rocky, fedora, alpine, darwin, or UNKNOWN
    """
    if sys.platform == "darwin":
        os_type = "darwin"
    else:
        try:
            with open("/etc/os-release") as f:
                content = f.read().lower()
                
            if "debian" in content or "ubuntu" in content:
                os_type = "debian"
            elif "rhel" in content:
                os_type = "rhel"
            elif "centos" in content:
                os_type = "centos"
            elif "rocky" in content:
                os_type = "rocky"
            elif "fedora" in content:
                os_type = "fedora"
            elif "alpine" in content:
                os_type = "alpine"
            else:
                os_type = "UNKNOWN"
        except FileNotFoundError:
            os_type = "UNKNOWN"
    
    log("INFO", f"Detected operating system: {os_type}")
    return os_type


def ask_binary_question(question: str, quiet: bool = False) -> str:
    """
    Prompt for a yes/no answer.
    
    Args:
        question: Question to display
        quiet: If True, automatically return 'Y' without prompting
        
    Returns:
        'Y' or 'N'
    """
    if quiet:
        return "Y"
    
    while True:
        answer = input(f"{question} ").strip().lower()
        if answer in ['y', 'yes']:
            log("INFO", f"User answered 'Y' to question: {question}")
            return "Y"
        elif answer in ['n', 'no']:
            log("INFO", f"User answered 'N' to question: {question}")
            return "N"
        else:
            log("WARN", "Please answer yes (y) or no (n).")


def highlight_message(message: str) -> None:
    """Print a highlighted message box."""
    print()
    print(f"{Colors.YELLOW}{'*' * 44}{Colors.RESET}")
    print(f"{Colors.YELLOW}**{Colors.RESET} {message}")
    print(f"{Colors.YELLOW}{'*' * 44}{Colors.RESET}")


def info_message(message: str) -> None:
    """Print an info message."""
    print()
    print(f"{Colors.YELLOW}>>>>>{Colors.RESET} {message}")


def error_message(message: str) -> None:
    """Print an error message."""
    print()
    print(f"{Colors.YELLOW}>>>>>{Colors.RESET} {Colors.RED} Error: {message}{Colors.RESET}")


def info_progress_header(message: str) -> None:
    """Print a progress header without newline."""
    print()
    print(f"{Colors.YELLOW}>>>>>{Colors.RESET} {message}", end="", flush=True)


def info_progress(message: str) -> None:
    """Print progress text without newline."""
    print(message, end="", flush=True)


def ensure_directory(directory: str) -> None:
    """
    Ensure a directory exists, create it if it doesn't.
    
    Args:
        directory: Path to directory
    """
    Path(directory).mkdir(parents=True, exist_ok=True)


def file_exists(filepath: str) -> bool:
    """Check if a file exists."""
    return Path(filepath).is_file()


def is_service_active(service_name: str) -> bool:
    """
    Check if a systemd service is active.
    
    Args:
        service_name: Name of the service
        
    Returns:
        True if service is active, False otherwise
    """
    returncode, _, _ = run_command(
        ["sudo", "systemctl", "is-active", "--quiet", service_name],
        check=False,
        capture_output=True
    )
    return returncode == 0


def restart_service(service_name: str) -> bool:
    """
    Restart a systemd service.
    
    Args:
        service_name: Name of the service
        
    Returns:
        True if restart was successful, False otherwise
    """
    returncode, _, _ = sudo_command(["systemctl", "restart", service_name], check=False)
    return returncode == 0


def enable_service(service_name: str) -> bool:
    """
    Enable a systemd service.
    
    Args:
        service_name: Name of the service
        
    Returns:
        True if enable was successful, False otherwise
    """
    returncode, _, _ = sudo_command(["systemctl", "enable", service_name], check=False)
    return returncode == 0


def get_current_user() -> str:
    """Get the current username."""
    return os.getenv("USER", os.getenv("USERNAME", "unknown"))


def create_symlink(source: str, target: str) -> bool:
    """
    Create a symbolic link.
    
    Args:
        source: Source file/directory
        target: Target link path
        
    Returns:
        True if successful, False otherwise
    """
    try:
        target_path = Path(target)
        if target_path.exists():
            target_path.unlink()
        
        sudo_command(f"ln -s {source} {target}", check=True)
        return True
    except Exception as e:
        log("ERROR", f"Failed to create symlink: {e}")
        return False
