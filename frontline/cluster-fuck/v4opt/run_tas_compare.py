"""Test scoped regime trend-align (trend-followers only; scalpers exempt)."""
import subprocess, sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
RUN_V4 = os.path.join(HERE, "run_v4.py")
EA = os.path.join(HERE, "ea", "main.mq5")
BASE_INI = os.path.join(HERE, "ea", "backtest_config.ini")
PY = sys.executable
# Trend-following magics (asymmetric counter-trend bleeders + trend strategies).
# Exempts RSI Scalping (129102315) + other mean-reversion (keep quick counter-trend).
TF_MAGICS = "940001,26042503,135790,1002,1001,12350,1003"
WINDOWS = [("full","2023.01.01","2026.06.18"),("y2023","2023.01.01","2023.12.31"),("h1_2026","2026.01.01","2026.06.18")]
def main():
    for win, frm, to in WINDOWS:
        tag = f"tas_{win}"
        print(f"\n===== {tag} {frm}->{to} =====", flush=True)
        cmd = [PY, RUN_V4, "--tag", tag, "--from", frm, "--to", to, "--ea", EA, "--base-ini", BASE_INI,
               "--label", f"trendalign scoped {win}", "--max-poll", "300",
               "--set", "GRM_TrendAlignEnable=true", "--set", f"GRM_TrendAlignMagics={TF_MAGICS}"]
        subprocess.run(cmd)
    print("\n==== SCOPED TREND-ALIGN DONE ====")
if __name__ == "__main__":
    main()
