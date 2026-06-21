"""Return/drawdown frontier: characterize Aggressive (URF off) and Conservative
(scale6) variants of the champion across entry-time windows, for parallel demo
selection. Balanced (champion default) already has the full sm_* 26-window matrix.

Aggressive  = champion + URF_Enable=false      (max return, highest cold-start DD)
Conservative= champion + ORCH_MaxBalanceScale=6 (lower return, lower DD)
"""
import subprocess, sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
RUN_V4 = os.path.join(HERE, "run_v4.py"); EA = os.path.join(HERE, "ea", "main.mq5")
BASE_INI = os.path.join(HERE, "ea", "backtest_config.ini"); PY = sys.executable
END = "2026.06.19"
VERSIONS = [
    ("agg", ["URF_Enable=false"]),
    ("con", ["ORCH_MaxBalanceScale=6.0"]),
]
WINDOWS = [
    ("full",    "2023.01.01", END),
    ("y2023",   "2023.01.01", "2023.12.31"),
    ("y2024",   "2024.01.01", "2024.12.31"),
    ("y2025",   "2025.01.01", "2025.12.31"),
    ("y2026h",  "2026.01.01", END),
    ("q3_2023", "2023.07.01", "2023.09.30"),
    ("q4_2024", "2024.10.01", "2024.12.31"),
]
def main():
    for ver, sets in VERSIONS:
        for win, frm, to in WINDOWS:
            tag = f"fr_{ver}_{win}"
            print(f"\n===== {tag} {frm}->{to} =====", flush=True)
            cmd = [PY, RUN_V4, "--tag", tag, "--from", frm, "--to", to, "--ea", EA,
                   "--base-ini", BASE_INI, "--label", f"frontier {tag}", "--max-poll", "400"]
            for s in sets: cmd += ["--set", s]
            subprocess.run(cmd)
    print("\n==== FRONTIER DONE ====")
if __name__ == "__main__": main()
