import runpy,sys
from pathlib import Path
sys.argv.append("--stage4")
runpy.run_path(str(Path(__file__).with_name("check_stage1.py")),run_name="__main__")
