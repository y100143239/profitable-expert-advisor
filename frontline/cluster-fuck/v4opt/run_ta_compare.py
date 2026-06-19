"""Test the regime-adaptive directional filter (GRM_TrendAlign) vs the current default.

GRM_TrendAlign blocks counter-trend entries per-symbol (strong uptrend -> block
shorts; strong downtrend -> block longs) = the user's 强市偏多 / 弱市偏空 bias.
"""
import subprocess, sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
RUN_V4 = os.path.join(HERE, "run_v4.py")
EA = os.path.join(HERE, "ea", "main.mq5")
BASE_INI = os.path.join(HERE, "ea", "backtest_config.ini")
PY = sys.executable

CONFIGS = {
    "base": [],
    "taon": ["GRM_TrendAlignEnable=true"],
}
WINDOWS = [
    ("full", "2023.01.01", "2026.06.18"),
    ("y2023", "2023.01.01", "2023.12.31"),
    ("h1_2026", "2026.01.01", "2026.06.18"),
]

def main():
    res = []
    for win, frm, to in WINDOWS:
        for cfg, sets in CONFIGS.items():
            tag = f"ta_{cfg}_{win}"
            print(f"\n===== {tag}  {frm}->{to}  sets={sets} =====", flush=True)
            cmd = [PY, RUN_V4, "--tag", tag, "--from", frm, "--to", to,
                   "--ea", EA, "--base-ini", BASE_INI,
                   "--label", f"trendalign {cfg} {win}", "--max-poll", "300"]
            for s in sets:
                cmd += ["--set", s]
            r = subprocess.run(cmd)
            res.append((tag, r.returncode))
    print("\n==== TREND-ALIGN COMPARE DONE ====")
    for tag, rc in res:
        print(f"  {tag:16s} rc={rc}")

if __name__ == "__main__":
    main()
