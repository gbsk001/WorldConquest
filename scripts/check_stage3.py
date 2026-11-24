"""Compile production code and run Stage 1/2/3 regressions, parity and authority tests."""
import runpy,sys
sys.argv.append("--stage3")
from pathlib import Path
runpy.run_path(str(Path(__file__).with_name("check_stage1.py")),run_name="__main__")
