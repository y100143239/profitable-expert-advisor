# 📊 MT5 回测增强分析报告 — iter4 window 2024

**生成时间:** 2026-06-18 00:57:36

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | ea |
| Symbol | XAUUSD |
| Period | H1 (2024.01.01 - 2025.01.01) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 1 345.50 |
| Gross Profit | 2 254.85 |
| Gross Loss | -909.35 |
| Profit Factor | 2.48 |
| Expected Payoff | 2.42 |
| Recovery Factor | 2.15 |
| Sharpe Ratio | 5.19 |
| Balance Drawdown Maximal | 103.51 (2.41%) |
| Equity Drawdown Maximal | 627.21 (14.39%) |
| Balance Drawdown Relative | 2.41% (103.51) |
| Equity Drawdown Relative | 14.39% (627.21) |
| Total Trades | 556 |
| Short Trades (won %) | 237 (85.65%) |
| Long Trades (won %) | 319 (81.82%) |
| Profit Trades (% of total) | 464 (83.45%) |
| Loss Trades (% of total) | 92 (16.55%) |
| Largest profit trade | 438.72 |
| Largest loss trade | -103.25 |
| Average profit trade | 4.86 |
| Average loss trade | -8.88 |
| Maximum consecutive wins ($) | 29 (79.06) |
| Maximum consecutive losses ($) | 4 (-0.32) |
| Average position holding time | 1:10:00 |
| Maximal position holding time | 43:35:47 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 12 | -270.46 | -22.54 |
| Stop-Loss (sl) | 544 | 1,708.21 | 3.14 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2024 | 1,345.50 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2024.01 | -11.64 | -11.64 |
| 2024.02 | -0.74 | -12.38 |
| 2024.03 | 79.18 | 66.80 |
| 2024.04 | 924.81 | 991.61 |
| 2024.05 | 38.83 | 1,030.44 |
| 2024.06 | 52.03 | 1,082.47 |
| 2024.07 | 80.51 | 1,162.98 |
| 2024.08 | 57.53 | 1,220.51 |
| 2024.09 | -10.08 | 1,210.43 |
| 2024.10 | 151.42 | 1,361.85 |
| 2024.11 | 27.46 | 1,389.31 |
| 2024.12 | -43.81 | 1,345.50 |

## 🔎 关键观察
- 最佳月份: **2024.04** (924.81 USD)
- 最差月份: **2024.12** (-43.81 USD)  ← 重点优化时间窗口
- 亏损月份数: 4 / 12
- 余额最大回撤: 103.51 (2.41%) | 净值最大回撤: 627.21 (14.39%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码