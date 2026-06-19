"""Monthly-loss breaker mode comparison: replace the wasteful month-lock.

User feedback: the month-lock (GRM_MonthlyLossCooldownHours=0) halts ALL trading
for the rest of the calendar month once monthly loss hits the limit, wasting good
trading time. With RQE now capping large losses, test recoverable cooldowns and
breaker-off. Champion (month-lock, e08c1cf): full $119,574/PF1.57/30.28%,
y2023 $2,807/PF1.51/38.31%."""
import subprocess, sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
RUN_V4 = os.path.join(HERE, "run_v4.py"); EA = os.path.join(HERE, "ea", "main.mq5")
BASE_INI = os.path.join(HERE, "ea", "backtest_config.ini"); PY = sys.executable
CONFIGS = [
    ("cd24",  ["GRM_MonthlyLossCooldownHours=24.0"]),
    ("cd72",  ["GRM_MonthlyLossCooldownHours=72.0"]),
    ("mlboff", ["GRM_MonthlyLossLimitFreeMarginPct=0.0"]),
]
WINDOWS = [("full","2023.01.01","2026.06.18"),("y2023","2023.01.01","2023.12.31")]
def main():
    for cfg, sets in CONFIGS:
        for win, frm, to in WINDOWS:
            tag = f"mlb_{cfg}_{win}"
            print(f"\n===== {tag} {frm}->{to} =====", flush=True)
            cmd = [PY, RUN_V4, "--tag", tag, "--from", frm, "--to", to, "--ea", EA,
                   "--base-ini", BASE_INI, "--label", f"mlb {cfg} {win}", "--max-poll", "300"]
            for s in sets: cmd += ["--set", s]
            subprocess.run(cmd)
    print("\n==== MLB COMPARE DONE ====")
if __name__ == "__main__": main()
