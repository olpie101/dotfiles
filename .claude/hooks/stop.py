#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "python-dotenv",
# ]
# ///

import argparse
import json
import os
import sys
import random
import subprocess
from pathlib import Path
from utils.logging import append_log

try:
    from dotenv import load_dotenv
    env_file = os.getenv("CCAOS_ENV_FILE")
    if env_file:
        load_dotenv(dotenv_path=env_file)
    else:
        load_dotenv()
except ImportError:
    pass


def get_completion_messages():
    """Return list of friendly completion messages."""
    return [
        "Work complete!",
        "All done!",
        "Task finished!",
        "Job complete!",
        "Ready for next task!",
    ]



def get_llm_script_path():
    """
    Determine which LLM script to use based on available API keys.
    Priority order: Gemini > OpenAI > Anthropic
    """
    # Get current script directory and construct utils/llm path
    script_dir = Path(__file__).parent
    llm_dir = script_dir / "utils" / "llm"

    # Check for Gemini API keys (highest priority)
    if os.getenv("GOOGLE_API_KEY") or os.getenv("GEMINI_API_KEY"):
        gemini_script = llm_dir / "gemini.py"
        if gemini_script.exists():
            return str(gemini_script)

    # Check for OpenAI API key (second priority)
    if os.getenv("OPENAI_API_KEY"):
        openai_script = llm_dir / "oai.py"
        if openai_script.exists():
            return str(openai_script)

    # Check for Anthropic API key (third priority)
    if os.getenv("ANTHROPIC_API_KEY"):
        anth_script = llm_dir / "anth.py"
        if anth_script.exists():
            return str(anth_script)

    return None


def get_llm_completion_message():
    """
    Generate completion message using available LLM services.
    Priority order: Gemini > OpenAI > Anthropic > fallback to random message

    Returns:
        str: Generated or fallback completion message
    """
    llm_script = get_llm_script_path()

    if llm_script:
        try:
            result = subprocess.run(
                ["uv", "run", llm_script, "--completion"],
                capture_output=True,
                text=True,
                timeout=10,
            )
            if result.returncode == 0 and result.stdout.strip():
                return result.stdout.strip()
        except (subprocess.TimeoutExpired, subprocess.SubprocessError):
            pass

    # Fallback to random predefined message
    messages = get_completion_messages()
    return random.choice(messages)



def main():
    sys.exit(0)
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--chat", action="store_true", help="Copy transcript to chat.json"
    )
    args = parser.parse_args()

    try:
        # Read JSON input from stdin
        input_data = json.loads(sys.stdin.read())

        # Extract session_id
        session_id = input_data.get("session_id", "unknown")
        stop_hook_active = input_data.get("stop_hook_active", False)

        append_log('stop', input_data)

        # Handle --chat switch
        if args.chat and "transcript_path" in input_data:
            transcript_path = input_data["transcript_path"]
            if os.path.exists(transcript_path):
                # Read .jsonl file and convert to JSON array
                chat_data = []
                try:
                    with open(transcript_path, "r") as f:
                        for line in f:
                            line = line.strip()
                            if line:
                                try:
                                    chat_data.append(json.loads(line))
                                except json.JSONDecodeError:
                                    pass  # Skip invalid lines

                    # Write to logs/chat.json
                    log_dir = Path("logs")
                    log_dir.mkdir(parents=True, exist_ok=True)
                    chat_file = log_dir / "chat.json"
                    with open(chat_file, "w") as f:
                        json.dump(chat_data, f, indent=2)
                except Exception:
                    pass  # Fail silently

        # Exit successfully
        sys.exit(0)

    except json.JSONDecodeError:
        # Handle JSON decode errors gracefully
        sys.exit(0)
    except Exception:
        # Handle any other errors gracefully
        sys.exit(0)


if __name__ == "__main__":
    main()

