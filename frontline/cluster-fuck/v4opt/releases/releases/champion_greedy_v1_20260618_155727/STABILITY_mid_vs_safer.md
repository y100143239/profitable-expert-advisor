# Stability comparison: MID-scale6 (mv_) vs SAFER-scale3 (sv_)

Cold-start windows, fresh $3000. Net = net profit; DD = max equity DD %.

| Window | MID-scale6 Net | MID-scale6 DD% | MID-scale6 PF | SAFER-scale3 Net | SAFER-scale3 DD% | SAFER-scale3 PF |
|---|---|---|---|---|---|---|
| full_2023_2026 | 157,369 | 22.57 | 1.45 | 47,323 | 20.51 | 1.38 |
| year_2023 | 337 | 45.65 | 1.04 | -93 | 39.57 | 0.98 |
| year_2024 | 6,290 | 35.46 | 1.25 | 5,050 | 27.48 | 1.36 |
| year_2025 | 17,540 | 33.51 | 1.47 | 11,382 | 29.26 | 1.62 |
| year_2026h | 2,184 | 69.59 | 1.09 | 4,137 | 31.75 | 1.20 |
| h1_2023 | 464 | 32.31 | 1.08 | 193 | 22.69 | 1.05 |
| h2_2023 | -181 | 25.19 | 0.93 | -260 | 23.38 | 0.88 |
| h1_2024 | 2,769 | 43.87 | 1.23 | 3,326 | 28.43 | 1.52 |
| h2_2024 | 1,829 | 36.29 | 1.26 | 743 | 29.84 | 1.19 |
| h1_2025 | 409 | 41.34 | 1.04 | 240 | 27.36 | 1.04 |
| h2_2025 | 15,273 | 34.23 | 1.61 | 9,922 | 30.06 | 1.85 |
| h1_2026 | 2,184 | 69.59 | 1.09 | 4,137 | 31.75 | 1.20 |

## MID-scale6 stability across 11 cold-start windows
- profitable windows: 10/11
- net profit: mean 4,463, median 2,184, std 5,896, CV 1.32, min -181, max 17,540
- max equity DD%: mean 42.5, median 36.3, WORST 69.6, best 25.2
- worst-PF window: 0.93

## SAFER-scale3 stability across 11 cold-start windows
- profitable windows: 9/11
- net profit: mean 3,525, median 3,326, std 3,847, CV 1.09, min -260, max 11,382
- max equity DD%: mean 29.2, median 29.3, WORST 39.6, best 22.7
- worst-PF window: 0.88
