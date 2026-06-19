"""Comprehensive cold-start stability matrix for the CURRENT champion defaults.

Each window starts fresh at $3000 (cold start) = "what if I switch the EA on at
the start of this window?". Tests entry-time robustness across many start dates
and durations (quarter / half / year / full). Monthly P/L stability comes free
from the full run's monthly breakdown (analysis_report.md). Sequential only
(single MT5 container) to avoid report-file races.

Run from the MAIN repo (not the worktree).
"""
import subprocess, sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
RUN_V4 = os.path.join(HERE, "run_v4.py")
EA = os.path.join(HERE, "ea", "main.mq5")
BASE_INI = os.path.join(HERE, "ea", "backtest_config.ini")
PY = sys.executable
END = "2026.06.19"   # "current time"

# (base_tag, from, to)
WINDOWS = [
    ("full",     "2023.01.01", END),
    # yearly cold starts
    ("y2023",    "2023.01.01", "2023.12.31"),
    ("y2024",    "2024.01.01", "2024.12.31"),
    ("y2025",    "2025.01.01", "2025.12.31"),
    ("y2026h",   "2026.01.01", END),
    # half-year cold starts
    ("h1_2023",  "2023.01.01", "2023.06.30"),
    ("h2_2023",  "2023.07.01", "2023.12.31"),
    ("h1_2024",  "2024.01.01", "2024.06.30"),
    ("h2_2024",  "2024.07.01", "2024.12.31"),
    ("h1_2025",  "2025.01.01", "2025.06.30"),
    ("h2_2025",  "2025.07.01", "2025.12.31"),
    ("h1_2026",  "2026.01.01", END),
    # quarterly cold starts
    ("q1_2023",  "2023.01.01", "2023.03.31"),
    ("q2_2023",  "2023.04.01", "2023.06.30"),
    ("q3_2023",  "2023.07.01", "2023.09.30"),
    ("q4_2023",  "2023.10.01", "2023.12.31"),
    ("q1_2024",  "2024.01.01", "2024.03.31"),
    ("q2_2024",  "2024.04.01", "2024.06.30"),
    ("q3_2024",  "2024.07.01", "2024.09.30"),
    ("q4_2024",  "2024.10.01", "2024.12.31"),
    ("q1_2025",  "2025.01.01", "2025.03.31"),
    ("q2_2025",  "2025.04.01", "2025.06.30"),
    ("q3_2025",  "2025.07.01", "2025.09.30"),
    ("q4_2025",  "2025.10.01", "2025.12.31"),
    ("q1_2026",  "2026.01.01", "2026.03.31"),
    ("q2_2026",  "2026.04.01", END),
]

def main():
    results = []
    for base, frm, to in WINDOWS:
        tag = "sm_" + base
        print(f"\n========== WINDOW {tag}  {frm} -> {to} ==========", flush=True)
        cmd = [PY, RUN_V4, "--tag", tag, "--from", frm, "--to", to,
               "--ea", EA, "--base-ini", BASE_INI,
               "--label", f"stability {tag}", "--max-poll", "400"]
        r = subprocess.run(cmd)
        results.append((tag, r.returncode))
        if r.returncode != 0:
            print(f"!! window {tag} returned {r.returncode}", flush=True)
    print("\n==== STABILITY MATRIX DONE ====")
    for tag, rc in results:
        print(f"  {tag:14s} rc={rc}")

if __name__ == "__main__":
    main()
