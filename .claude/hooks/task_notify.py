#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# ///

import argparse
import json
import sys
from pathlib import Path

# Import our notification utility
sys.path.insert(0, str(Path(__file__).parent / "utils"))
from notify import log_notification_event, send_notification

# requires ITerm2 installed and used as default terminal
# optional: terminal-notifier installed
# https://github.com/julienXX/terminal-notifier

"""
Handle main agent stop event.
"""
def handle_stop_event(input_data: dict):
    session_id = input_data.get('session_id', 'unknown')
    
    # Check if we have session data to get agent name
    session_name = get_session_agent_name(session_id)
    
    if session_name:
        message = f"{session_name} has completed the task!"
    else:
        message = "Task completed successfully!"
    
    send_notification(message, "Claude Code")
    log_notification_event("stop", input_data)


"""
Handle subagent stop event.
"""
def handle_subagent_event(input_data: dict):
    log_notification_event("subagent", input_data)

"""
Handle TodoWrite tool completion event.
"""
def handle_todo_event(input_data: dict):
    try:
        output = input_data.get('output', {})
        todos = output.get('todos', [])
        
        if not todos:
            return
        
        completed_todos = [t for t in todos if t.get('status') == 'completed']
        pending_todos = [t for t in todos if t.get('status') == 'pending']
        in_progress_todos = [t for t in todos if t.get('status') == 'in_progress']
        
        total_todos = len(todos)
        completed_count = len(completed_todos)
        
        # Only notify on interesting state changes
        if completed_count == total_todos and total_todos > 0:
            # All tasks completed
            message = f"All {total_todos} tasks completed! 🎉"
            send_notification(message, "Tasks Done")
            
        elif completed_count > 0 and len(pending_todos) == 0 and len(in_progress_todos) == 1:
            # Last task in progress
            last_task = in_progress_todos[0].get('content', 'Task')[:60]
            message = f"Working on final task: {last_task}..."
            send_notification(message, "Final Task", sound=False)
            
        elif completed_count > 0 and completed_count % 2 == 0 and len(pending_todos) > 0:
            # Every 2 completed tasks (reduced from 3 for better feedback)
            # Show the most recent completed task
            if completed_todos:
                recent_task = completed_todos[-1].get('content', 'Task')[:50]
                message = f"✓ {recent_task}\n({completed_count}/{total_todos} done)"
            else:
                message = f"Progress: {completed_count}/{total_todos} tasks completed"
            send_notification(message, "Task Progress", sound=False)
        
        elif completed_count == 1 and total_todos > 1:
            # First task completed - show which one
            first_completed = completed_todos[0].get('content', 'Task')[:50]
            message = f"✓ {first_completed}\n({total_todos - 1} remaining)"
            send_notification(message, "Task Completed", sound=False)
        
        log_notification_event("todo", input_data)
        
    except Exception:
        # Don't fail the hook on errors
        pass


"""
Handle waiting for input event (e.g., plan created, permission needed).
"""
def handle_waiting_event(input_data: dict):
    try:
        tool_name = input_data.get('tool_name', '')
        tool_input = input_data.get('tool_input', {})
        tool_response = input_data.get('tool_response', {})
        
        if tool_name == 'ExitPlanMode':
            # Plan was created and Claude is waiting for approval
            plan_content = tool_input.get('plan', '')
            
            # Extract first line or create a summary
            if plan_content:
                # Get the first meaningful line from the plan
                lines = plan_content.split('\n')
                summary = ''
                for line in lines:
                    line = line.strip()
                    if line and not line.startswith('#') and len(line) > 10:
                        # Clean up the line and truncate if too long
                        summary = line.replace('**', '').replace('*', '').strip()[:60]
                        break
                
                if summary:
                    message = f"📋 Plan ready: {summary}..."
                else:
                    message = "📋 Plan ready for review"
            else:
                message = "📋 Plan ready for review"
                
            send_notification(message, "Waiting for Input")
            
        else:
            # Generic waiting message for other cases
            message = "⏳ Waiting for your input..."
            send_notification(message, "Input Required")
        
        log_notification_event("waiting", input_data)
        
    except Exception:
        # Don't fail the hook on errors
        pass

"""
Get agent name from session data if available.
"""
def get_session_agent_name(session_id: str) -> str:
    try:
        sessions_dir = Path(".claude/data/sessions")
        session_file = sessions_dir / f"{session_id}.json"
        
        if session_file.exists():
            with open(session_file, 'r') as f:
                session_data = json.load(f)
                return session_data.get('agent_name', '')
    except Exception:
        pass
    
    return ''


"""
Main function to handle command line arguments and events.
"""
def main():
    try:
        # Parse command line arguments
        parser = argparse.ArgumentParser(description='Send task completion notifications')
        parser.add_argument('--event', required=True, 
                            choices=['stop', 'subagent', 'todo', 'waiting'],
                            help='Type of event to handle')
        parser.add_argument('--quiet', action='store_true',
                            help='Suppress notifications (log only)')
        args = parser.parse_args()
        
        # Read JSON input from stdin
        input_data = json.load(sys.stdin)
        
        # Skip notifications if in quiet mode
        if args.quiet:
            log_notification_event(args.event, input_data)
            sys.exit(0)
        
        # Handle different event types
        if args.event == 'stop':
            handle_stop_event(input_data)
        elif args.event == 'subagent':
            handle_subagent_event(input_data)
        elif args.event == 'todo':
            handle_todo_event(input_data)
        elif args.event == 'waiting':
            handle_waiting_event(input_data)
        
        # Always exit successfully to not interrupt Claude's workflow
        sys.exit(0)
        
    except json.JSONDecodeError:
        # Handle JSON decode errors gracefully
        sys.exit(0)
    except Exception:
        # Handle any other errors gracefully
        sys.exit(0)


if __name__ == '__main__':
    main()