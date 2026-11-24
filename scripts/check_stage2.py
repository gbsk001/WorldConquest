"""Compile all production Luau; run source parity, integration and Stage 2 performance tests."""
from pathlib import Path
import runpy,sys
sys.argv.append('--stage2-only')
runpy.run_path(str(Path(__file__).with_name('check_stage1.py')),run_name='__main__')
