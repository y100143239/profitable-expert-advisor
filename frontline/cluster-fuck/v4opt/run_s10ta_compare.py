"""Scale-10 vs scale-6 with the regime filter ON (now default). Tests outsized-profit upside."""
import subprocess, sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
RUN_V4 = os.path.join(HERE, "run_v4.py"); EA = os.path.join(HERE, "ea", "main.mq5")
BASE_INI = os.path.join(HERE, "ea", "backtest_config.ini"); PY = sys.executable
WINDOWS = [("full","2023.01.01","2026.06.18"),("y2023","2023.01.01","2023.12.31"),
           ("y2026h","2026.01.01","2026.06.18"),("h1_2025","2025.01.01","2025.06.30")]
def main():
    for win, frm, to in WINDOWS:
        tag = f"s10ta_{win}"
        print(f"\n===== {tag} {frm}->{to} =====", flush=True)
        subprocess.run([PY, RUN_V4, "--tag", tag, "--from", frm, "--to", to, "--ea", EA,
            "--base-ini", BASE_INI, "--label", f"scale10 trendalign {win}", "--max-poll", "300",
            "--set", "ORCH_MaxBalanceScale=10.0"])
    print("\n==== S10+TA DONE ====")
if __name__ == "__main__": main()
