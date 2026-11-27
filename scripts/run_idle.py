"""Run a CLI check below normal priority on one logical CPU; no graphical launch.

Usage: python scripts/run_idle.py scripts/check_strategy_ui.py
The child inherits affinity/priority. This limits interference, not its total memory.
Large load/memory benchmarks still require separate authorisation.
"""
import ctypes, os, subprocess, sys
if os.name == 'nt':
    k=ctypes.windll.kernel32
    k.GetCurrentProcess.restype=ctypes.c_void_p
    handle=k.GetCurrentProcess()
    k.SetPriorityClass.argtypes=[ctypes.c_void_p,ctypes.c_ulong]
    k.SetPriorityClass(handle,0x00004000)  # BELOW_NORMAL_PRIORITY_CLASS
    process_mask=ctypes.c_size_t();system_mask=ctypes.c_size_t()
    k.GetProcessAffinityMask.argtypes=[ctypes.c_void_p,ctypes.POINTER(ctypes.c_size_t),ctypes.POINTER(ctypes.c_size_t)]
    if k.GetProcessAffinityMask(handle,ctypes.byref(process_mask),ctypes.byref(system_mask)):
        mask=process_mask.value & -process_mask.value
        k.SetProcessAffinityMask.argtypes=[ctypes.c_void_p,ctypes.c_size_t]
        k.SetProcessAffinityMask(handle,mask)
raise SystemExit(subprocess.call([sys.executable,*sys.argv[1:]]))
