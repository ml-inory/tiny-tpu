#!/usr/bin/env python3
"""Build and run the PE self-checking testbench."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
RTL = REPO_ROOT / "rtl" / "pe.sv"
TB = REPO_ROOT / "tb" / "pe_tb.sv"
BUILD_DIR = REPO_ROOT / "tb" / "build"


def run(cmd: list[str]) -> None:
    print("+ " + " ".join(cmd))
    result = subprocess.run(cmd, cwd=REPO_ROOT, text=True, capture_output=True)
    if result.stdout:
        print(result.stdout, end="")
    if result.stderr:
        print(result.stderr, end="", file=sys.stderr)
    if result.returncode != 0:
        raise SystemExit(result.returncode)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--waves",
        action="store_true",
        help="enable VCD dump at tb/build/pe_tb.vcd",
    )
    args = parser.parse_args()

    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    out = BUILD_DIR / "pe_tb.vvp"
    cmd = [
        "iverilog",
        "-g2012",
        "-Wall",
        "-s",
        "pe_tb",
        "-o",
        str(out),
        str(RTL),
        str(TB),
    ]
    if args.waves:
        cmd.insert(1, "-DPE_TB_WAVES")

    run(cmd)
    run(["vvp", str(out)])


if __name__ == "__main__":
    main()
