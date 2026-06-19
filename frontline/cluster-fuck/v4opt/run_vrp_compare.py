"""Validate the Virtual Recovery Probe (VRP) shadow-trading breaker.

User: a fixed timed freeze is too crude; when monthly loss is hit, switch REAL
trading to SHADOW (virtual) trading, monitor simulated win rate, and resume real
trading only once the market recovers. 2023 principal fell to ~$1777 under the
month-lock. Champion month-lock baseline (e08c1cf): full $119,574/PF1.57/30.28%,
y2023 $2,807/PF1.51/38.31%. Goal: protect 2023 principal (less DD, higher equity
floor) without crushing full-period profit."""
import subprocess, sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
RUN_V4 = os.path.join(HERE, "run_v4.py"); EA = os.path.join(HERE, "ea", "main.mq5")
BASE_INI = os.path.join(HERE, "ea", "backtest_config.ini"); PY = sys.executable
VRP = ["VRP_Enable=true"]
WINDOWS = [("full","2023.01.01","2026.06.18"),("y2023","2023.01.01","2023.12.31")]
def main():
    for win, frm, to in WINDOWS:
        tag = f"vrp_{win}"
        print(f"\n===== {tag} {frm}->{to} =====", flush=True)
        cmd = [PY, RUN_V4, "--tag", tag, "--from", frm, "--to", to, "--ea", EA,
               "--base-ini", BASE_INI, "--label", f"vrp shadow {win}", "--max-poll", "300"]
        for s in VRP: cmd += ["--set", s]
        subprocess.run(cmd)
    print("\n==== VRP COMPARE DONE ====")
if __name__ == "__main__": main()
