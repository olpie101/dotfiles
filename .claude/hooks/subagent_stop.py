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
from datetime import datetime

try:
    from dotenv import load_dotenv

    # Load dotenv from custom path if specified
    env_file = os.getenv("CCAOS_ENV_FILE")
    if env_file:
        load_dotenv(dotenv_path=env_file)
    else:
        load_dotenv()
except ImportError:
    pass  # dotenv is optional

from utils.logging import append_log


def main():
    sys.exit(0)
    try:
        # Parse command line arguments
        parser = argparse.ArgumentParser()
        parser.add_argument(
            "--chat", action="store_true", help="Copy transcript to chat.json"
        )
        args = parser.parse_args()

        # Read JSON input from stdin
        input_data = json.load(sys.stdin)

        append_log('subagent_stop', input_data)

        # Handle --chat switch (same as stop.py)
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
                    log_dir = os.path.join(os.getcwd(), "logs")
                    os.makedirs(log_dir, exist_ok=True)
                    chat_file = os.path.join(log_dir, "chat.json")
                    with open(chat_file, "w") as f:
                        json.dump(chat_data, f, indent=2)
                except Exception:
                    pass  # Fail silently

        sys.exit(0)

    except json.JSONDecodeError:
        # Handle JSON decode errors gracefully
        sys.exit(0)
    except Exception:
        # Handle any other errors gracefully
        sys.exit(0)


if __name__ == "__main__":
    main()

