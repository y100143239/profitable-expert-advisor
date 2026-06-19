"""Validate the Regime Quick-Exit (RQE): counter-trend runaway loss-cap, opt-in.

Champion baseline (scale10+TA, b218789): full $116,983 / PF 1.56 / EqDD 30.7%,
y2023 +$2,812, h1_2026 $1,894. RQE_Enable=true should cut counter-trend losers
without disabling any strategy (surgical exit-side discipline)."""
import subprocess, sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
RUN_V4 = os.path.join(HERE, "run_v4.py"); EA = os.path.join(HERE, "ea", "main.mq5")
BASE_INI = os.path.join(HERE, "ea", "backtest_config.ini"); PY = sys.executable
RQE = ["RQE_Enable=true", "RQE_AdverseATRMult=1.5"]
WINDOWS = [("full","2023.01.01","2026.06.18"),("y2023","2023.01.01","2023.12.31"),("h1_2026","2026.01.01","2026.06.18")]
def main():
    for win, frm, to in WINDOWS:
        tag = f"rqe_{win}"
        print(f"\n===== {tag} {frm}->{to} =====", flush=True)
        cmd = [PY, RUN_V4, "--tag", tag, "--from", frm, "--to", to, "--ea", EA,
               "--base-ini", BASE_INI, "--label", f"rqe-quickexit {win}", "--max-poll", "300"]
        for s in RQE: cmd += ["--set", s]
        subprocess.run(cmd)
    print("\n==== RQE DONE ====")
if __name__ == "__main__": main()
