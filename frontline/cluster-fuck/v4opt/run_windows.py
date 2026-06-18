"""Run the champion EA (compiled defaults) over multiple cold-start windows.

Each window starts fresh with the configured deposit (cold start), which directly
tests live-start robustness ("what if I switch the EA on at the start of this
window?"). Monthly/quarterly performance is derived separately from the full
run's deal-by-deal data (see analyze_windows.py).

Sequential only (one MT5 container) to avoid report-file races.
"""
import subprocess, sys, os, argparse

HERE = os.path.dirname(os.path.abspath(__file__))
RUN_V4 = os.path.join(HERE, "run_v4.py")
EA = os.path.join(HERE, "ea", "main.mq5")
# Use the full winning ini (authoritative champion config = compiled EA defaults).
# NB: a [TesterInputs]-stripped ini is unreliable -- MT5 then uses cached tester
# inputs, not compiled defaults. The compiled defaults match this ini (verified by
# diff_defaults.py), so this ini is exactly what live one-click defaults produce.
BASE_INI = os.path.join(HERE, "ea", "backtest_config.ini")
PY = sys.executable

# (base_tag, from, to)  -- full + yearly + half-year cold starts
WINDOWS = [
    ("full_2023_2026",   "2023.01.01", "2026.06.18"),
    ("year_2023",        "2023.01.01", "2023.12.31"),
    ("year_2024",        "2024.01.01", "2024.12.31"),
    ("year_2025",        "2025.01.01", "2025.12.31"),
    ("year_2026h",       "2026.01.01", "2026.06.18"),
    ("h1_2023",          "2023.01.01", "2023.06.30"),
    ("h2_2023",          "2023.07.01", "2023.12.31"),
    ("h1_2024",          "2024.01.01", "2024.06.30"),
    ("h2_2024",          "2024.07.01", "2024.12.31"),
    ("h1_2025",          "2025.01.01", "2025.06.30"),
    ("h2_2025",          "2025.07.01", "2025.12.31"),
    ("h1_2026",          "2026.01.01", "2026.06.18"),
]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--prefix", default="w_", help="run-tag prefix (e.g. w_ for greedy, sv_ for safer variant)")
    ap.add_argument("--set", action="append", default=[], help="extra [TesterInputs] override KEY=VALUE (repeatable)")
    ap.add_argument("--label", default="cold-start")
    a = ap.parse_args()

    results = []
    for base, frm, to in WINDOWS:
        tag = a.prefix + base
        print(f"\n========== WINDOW {tag}  {frm} -> {to} ==========", flush=True)
        cmd = [PY, RUN_V4, "--tag", tag, "--from", frm, "--to", to,
               "--ea", EA, "--base-ini", BASE_INI,
               "--label", f"{a.label} {tag}", "--max-poll", "400"]
        for s in a.set:
            cmd += ["--set", s]
        r = subprocess.run(cmd)
        results.append((tag, r.returncode))
        if r.returncode != 0:
            print(f"!! window {tag} returned {r.returncode}", flush=True)
    print("\n==== ALL WINDOWS DONE ====")
    for tag, rc in results:
        print(f"  {tag:22s} rc={rc}")

if __name__ == "__main__":
    main()
