# 📊 MT5 回测增强分析报告 — iter4 window 2025

**生成时间:** 2026-06-18 00:42:17

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | ea |
| Symbol | XAUUSD |
| Period | H1 (2025.01.01 - 2026.01.01) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 458.82 |
| Gross Profit | 3 127.92 |
| Gross Loss | -2 669.10 |
| Profit Factor | 1.17 |
| Expected Payoff | 0.30 |
| Recovery Factor | 0.55 |
| Sharpe Ratio | 1.12 |
| Balance Drawdown Maximal | 535.84 (14.40%) |
| Equity Drawdown Maximal | 830.57 (22.32%) |
| Balance Drawdown Relative | 14.40% (535.84) |
| Equity Drawdown Relative | 22.32% (830.57) |
| Total Trades | 1550 |
| Short Trades (won %) | 703 (76.81%) |
| Long Trades (won %) | 847 (78.04%) |
| Profit Trades (% of total) | 1201 (77.48%) |
| Loss Trades (% of total) | 349 (22.52%) |
| Largest profit trade | 66.69 |
| Largest loss trade | -120.18 |
| Average profit trade | 2.60 |
| Average loss trade | -7.17 |
| Maximum consecutive wins ($) | 29 (48.03) |
| Maximum consecutive losses ($) | 4 (-64.46) |
| Average position holding time | 0:32:16 |
| Maximal position holding time | 40:43:36 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 44 | -2,337.01 | -53.11 |
| Stop-Loss (sl) | 1506 | 2,964.19 | 1.97 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2025 | 458.82 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2025.01 | -7.76 | -7.76 |
| 2025.02 | 117.88 | 110.12 |
| 2025.03 | 10.76 | 120.88 |
| 2025.04 | -159.07 | -38.19 |
| 2025.05 | 261.89 | 223.70 |
| 2025.06 | -78.35 | 145.35 |
| 2025.07 | 158.40 | 303.75 |
| 2025.08 | 12.79 | 316.54 |
| 2025.09 | 108.58 | 425.12 |
| 2025.10 | 86.69 | 511.81 |
| 2025.11 | -210.37 | 301.44 |
| 2025.12 | 157.38 | 458.82 |

## 🔎 关键观察
- 最佳月份: **2025.05** (261.89 USD)
- 最差月份: **2025.11** (-210.37 USD)  ← 重点优化时间窗口
- 亏损月份数: 4 / 12
- 余额最大回撤: 535.84 (14.40%) | 净值最大回撤: 830.57 (22.32%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码