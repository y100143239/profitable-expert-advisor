"""Focused A/B for the feedback fixes on the balanced default (URF on + scale6).

Configs:
  base  : current balanced default (monthly breaker = month-lock, PM off)
  cd48  : recoverable monthly breaker (GRM_MonthlyLossCooldownHours=48)
  pm4   : timely per-position stop (PM_Enable, 4% of equity floating-loss cap)
  both  : cd48 + pm4
Windows: full period + the worst-DD cold-start window (h1_2026).
Sequential (one container).
"""
import subprocess, sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
RUN_V4 = os.path.join(HERE, "run_v4.py")
EA = os.path.join(HERE, "ea", "main.mq5")
BASE_INI = os.path.join(HERE, "ea", "backtest_config.ini")
PY = sys.executable

CONFIGS = {
    "base": [],
    "cd48": ["GRM_MonthlyLossCooldownHours=48"],
    "pm4":  ["PM_Enable=true", "PM_MaxPositionLossPct=4.0"],
    "both": ["GRM_MonthlyLossCooldownHours=48", "PM_Enable=true", "PM_MaxPositionLossPct=4.0"],
}
WINDOWS = [
    ("full", "2023.01.01", "2026.06.18"),
    ("h1_2026", "2026.01.01", "2026.06.18"),
]

def main():
    res = []
    for win, frm, to in WINDOWS:
        for cfg, sets in CONFIGS.items():
            tag = f"fb_{cfg}_{win}"
            print(f"\n===== {tag}  {frm}->{to}  sets={sets} =====", flush=True)
            cmd = [PY, RUN_V4, "--tag", tag, "--from", frm, "--to", to,
                   "--ea", EA, "--base-ini", BASE_INI,
                   "--label", f"feedback {cfg} {win}", "--max-poll", "400"]
            for s in sets:
                cmd += ["--set", s]
            r = subprocess.run(cmd)
            res.append((tag, r.returncode))
    print("\n==== FEEDBACK COMPARE DONE ====")
    for tag, rc in res:
        print(f"  {tag:18s} rc={rc}")

if __name__ == "__main__":
    main()
