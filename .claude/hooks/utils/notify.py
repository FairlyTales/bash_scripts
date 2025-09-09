#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# ///

import platform
import subprocess
import sys
from datetime import datetime
from pathlib import Path


"""
Get iTerm2 session name if available.

Returns:
    str: iTerm2 session name or empty string if unavailable
"""
def get_iterm_session_name() -> str:
    try:
        if platform.system() == "Darwin":  # macOS only
            # Try to get tab name first (more user-friendly)
            applescript = 'tell application "iTerm2" to tell current window to tell current tab to get name'
            result = subprocess.run(
                ["osascript", "-e", applescript],
                capture_output=True,
                text=True,
                check=False,
                timeout=2  # Quick timeout to avoid hanging
            )
            if result.returncode == 0 and result.stdout.strip():
                tab_name = result.stdout.strip()
                # Filter out generic names that aren't helpful
                if tab_name and tab_name not in ['-zsh', 'zsh', 'bash', '-bash', 'fish', '-fish']:
                    return tab_name
            
            # Fallback to session name
            applescript = 'tell application "iTerm2" to tell current session of current window to get name'
            result = subprocess.run(
                ["osascript", "-e", applescript],
                capture_output=True,
                text=True,
                check=False,
                timeout=2
            )
            if result.returncode == 0 and result.stdout.strip():
                session_name = result.stdout.strip()
                # Filter out generic names
                if session_name and session_name not in ['-zsh', 'zsh', 'bash', '-bash', 'fish', '-fish']:
                    return session_name
    except Exception:
        pass
    return ""


"""
Send a cross-platform desktop notification using the new structure.

Args:
    message: The notification message content
    notification_type: Type of notification (e.g., "Task Completed", "Session Done")
    sound: Whether to play notification sound (default: False) - DEPRECATED, always silent
"""
def send_notification(message: str, notification_type: str = "Claude Code", sound: bool = False):
    system = platform.system()
    
    # Get iTerm2 session name and project directory
    iterm_name = get_iterm_session_name()
    project_name = Path.cwd().name
    
    # Determine title and message format based on iTerm2 availability
    if iterm_name:
        # Title: iTerm2 session name, Message: project + notification content
        title = iterm_name
        subtitle = project_name
        formatted_message = message
    else:
        # Title: Project directory, Message: notification content only
        title = project_name
        subtitle = ""
        formatted_message = message
    
    # Log to visual notification file for monitoring
    _log_notification(title, formatted_message, notification_type)
    
    try:
        if system == "Darwin":  # macOS
            # Primary: Use terminal-notifier if available (more reliable)
            if _has_terminal_notifier():
                success = _send_terminal_notifier(title, subtitle, formatted_message)
                if success:
                    return
            
            # Secondary: Use osascript with Script Editor bundle to bypass permissions
            _send_osascript_notification(title, formatted_message)
            
        elif system == "Linux":
            # Use notify-send without sound
            cmd = ["notify-send", title, formatted_message, "--hint=string:sound-name:"]
            subprocess.run(cmd, check=False, capture_output=True)
            
        elif system == "Windows":
            # Use PowerShell for Windows toast notifications (silent)
            _send_windows_notification(title, formatted_message)
            
    except Exception:
        # Fallback to console logging if notification fails
        _log_to_console(title, formatted_message)

"""
Check if terminal-notifier is available. It is a notification tool of choice for macOS.
https://github.com/julienXX/terminal-notifier
"""
def _has_terminal_notifier() -> bool:
    try:
        result = subprocess.run(
            ["which", "terminal-notifier"],
            capture_output=True,
            text=True,
            check=False
        )
        return result.returncode == 0
    except Exception:
        return False


"""
Send notification using terminal-notifier (most reliable on macOS).
"""
def _send_terminal_notifier(title: str, subtitle: str, message: str) -> bool:
    try:
        cmd = [
            "terminal-notifier",
            "-title", title,
            "-subtitle", subtitle,
            "-message", message,
            "-sender", "com.googlecode.iterm2"  # Use iTerm2 bundle ID
        ]
        result = subprocess.run(cmd, check=False, capture_output=True)
        return result.returncode == 0
    except Exception:
        return False


"""
Send notification using osascript with proper bundle ID.
"""
def _send_osascript_notification(title: str, message: str):
    try:
        # Escape quotes in message and title
        safe_message = message.replace('"', '\\"')
        safe_title = title.replace('"', '\\"')
        
        # Use Script Editor bundle to bypass permission issues
        applescript = f'display notification "{safe_message}" with title "{safe_title}"'
        cmd = ["osascript", "-e", applescript]
        subprocess.run(cmd, check=False, capture_output=True)
        
    except Exception:
        pass

"""
Send Windows PowerShell notification (silent).
"""
def _send_windows_notification(title: str, message: str):
    try:
        ps_script = f'''
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

        $template = @"
        <toast>
            <visual>
                <binding template="ToastText02">
                    <text id="1">{title}</text>
                    <text id="2">{message}</text>
                </binding>
            </visual>
        </toast>
        "@

        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($template)
        $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Code").Show($toast)
        '''
        
        subprocess.run(
            ["powershell", "-Command", ps_script],
            check=False,
            capture_output=True
        )
        
    except Exception:
        pass

"""
Fallback logging to console if notifications fail.
"""
def _log_to_console(title: str, message: str):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {title}: {message}", file=sys.stderr)

"""
Log notification events to file for debugging.

Args:
    event_type: Type of event (stop, todo, subagent)
    data: Event data from Claude Code
    log_dir: Log directory (defaults to ./logs)
"""
def log_notification_event(event_type: str, data: dict, log_dir: Path = None):
    if log_dir is None:
        log_dir = Path.cwd() / "logs"
    
    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / "task_notifications.json"
    
    import json
    
    # Read existing log data
    if log_file.exists():
        try:
            with open(log_file, 'r') as f:
                log_data = json.load(f)
        except (json.JSONDecodeError, ValueError):
            log_data = []
    else:
        log_data = []
    
    # Add new entry
    entry = {
        "timestamp": datetime.now().isoformat(),
        "event_type": event_type,
        "data": data
    }
    log_data.append(entry)
    
    # Write back with formatting
    try:
        with open(log_file, 'w') as f:
            json.dump(log_data, f, indent=2)
    except Exception:
        # Silently fail if we can't write the log
        pass

"""
Log notification to a visual file that can be monitored.
"""
def _log_notification(title: str, message: str, notification_type: str):
    try:
        log_dir = Path.cwd() / "logs"
        log_dir.mkdir(parents=True, exist_ok=True)
        log_file = log_dir / "notifications.log"
        
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # Choose emoji based on notification type
        emoji = "📋" if "Plan" in message or "waiting" in notification_type.lower() else "✅"
        if "Task" in notification_type:
            emoji = "📝"
        elif "Complete" in notification_type or "Done" in notification_type:
            emoji = "🎉"
        
        log_entry = f"[{timestamp}] {emoji} {title}: {message}\n"
        
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(log_entry)
            
    except Exception:
        # If visual logging fails, fall back to console
        _log_to_console(title, message)

if __name__ == "__main__":
    # Test the notification system
    send_notification("Test notification from Claude Code!", "Test")