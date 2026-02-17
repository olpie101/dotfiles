#!/usr/bin/env python3
"""GasTown-aware TEE logging utility for Claude Code hooks."""

import json
import os
from pathlib import Path


def get_central_log_path(hook_name: str) -> Path | None:
    """
    Get the central log path for GasTown.
    
    Returns None if GT_ROLE is not set.
    Otherwise returns $GT_ROOT/logs/sessions/{GT_ROLE}/{hook_name}.jsonl
    Falls back to ~/dev/gastown_olpie101/logs/sessions/{GT_ROLE}/{hook_name}.jsonl
    if GT_ROOT is not set.
    """
    gt_role = os.getenv("GT_ROLE")
    if not gt_role:
        return None
    
    gt_root = os.getenv("GT_ROOT")
    if gt_root:
        base_path = Path(gt_root)
    else:
        base_path = Path(os.path.expanduser("~/dev/gastown_olpie101"))
    
    return base_path / "logs" / "sessions" / gt_role / f"{hook_name}.jsonl"


def get_local_log_path(hook_name: str) -> Path:
    """
    Get the local log path (always relative to current directory).
    
    Returns ./logs/{hook_name}.json
    """
    return Path("logs") / f"{hook_name}.json"


def append_log(hook_name: str, data: dict) -> None:
    """
    Append log data using TEE pattern (write to both local and central if available).
    
    - ALWAYS writes to local path using JSON array append pattern
    - IF GT_ROLE is set: ALSO writes to central path using JSONL format
    
    Args:
        hook_name: Name of the hook (used for log file naming)
        data: Dictionary to append to logs
    """
    # Always write to local path
    local_path = get_local_log_path(hook_name)
    local_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Read existing log data or initialize empty list
    if local_path.exists():
        with open(local_path, 'r') as f:
            try:
                log_data = json.load(f)
            except (json.JSONDecodeError, ValueError):
                log_data = []
    else:
        log_data = []
    
    # Append the new data
    log_data.append(data)
    
    # Write back to file with formatting
    with open(local_path, 'w') as f:
        json.dump(log_data, f, indent=2)
    
    # Write to central path if GT_ROLE is set
    central_path = get_central_log_path(hook_name)
    if central_path:
        central_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Append as JSONL (one JSON object per line)
        with open(central_path, 'a') as f:
            json.dump(data, f)
            f.write('\n')
