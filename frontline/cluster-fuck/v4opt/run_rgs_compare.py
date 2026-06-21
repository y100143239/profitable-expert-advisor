"""Validate (a) the market-closed modify guard is behavior-neutral and (b) the
Regime-Scaled Sizing (RGS) de-risks adverse/choppy regimes.

Champion baseline (stability matrix sm_*): full $120,168/PF1.58/30.1%,
y2023 $2,817/38.3%, q3_2023 -$471/PF0.20, q4_2024 -$533/PF0.26.
- control_full (no overrides): market-closed fix should leave full ~unchanged.
- rgs_*: RGS_Enable=true should cut adverse-window DD/loss without crushing full."""
import subprocess, sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
RUN_V4 = os.path.join(HERE, "run_v4.py"); EA = os.path.join(HERE, "ea", "main.mq5")
BASE_INI = os.path.join(HERE, "ea", "backtest_config.ini"); PY = sys.executable
JOBS = [
    ("control_full", "2023.01.01", "2026.06.19", []),
    ("rgs_full",     "2023.01.01", "2026.06.19", ["RGS_Enable=true"]),
    ("rgs_y2023",    "2023.01.01", "2023.12.31", ["RGS_Enable=true"]),
    ("rgs_q3_2023",  "2023.07.01", "2023.09.30", ["RGS_Enable=true"]),
    ("rgs_q4_2024",  "2024.10.01", "2024.12.31", ["RGS_Enable=true"]),
]
def main():
    for tag, frm, to, sets in JOBS:
        print(f"\n===== {tag} {frm}->{to} =====", flush=True)
        cmd = [PY, RUN_V4, "--tag", tag, "--from", frm, "--to", to, "--ea", EA,
               "--base-ini", BASE_INI, "--label", f"rgs {tag}", "--max-poll", "400"]
        for s in sets: cmd += ["--set", s]
        subprocess.run(cmd)
    print("\n==== RGS COMPARE DONE ====")
if __name__ == "__main__": main()
