# 📊 MT5 回测增强分析报告 — iter3 window 2024

**生成时间:** 2026-06-18 00:27:57

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
| Total Net Profit | 274.25 |
| Gross Profit | 1 230.74 |
| Gross Loss | -956.49 |
| Profit Factor | 1.29 |
| Expected Payoff | 0.48 |
| Recovery Factor | 0.43 |
| Sharpe Ratio | 0.93 |
| Balance Drawdown Maximal | 350.25 (10.48%) |
| Equity Drawdown Maximal | 634.45 (18.48%) |
| Balance Drawdown Relative | 10.48% (350.25) |
| Equity Drawdown Relative | 18.48% (634.45) |
| Total Trades | 566 |
| Short Trades (won %) | 233 (76.82%) |
| Long Trades (won %) | 333 (81.68%) |
| Profit Trades (% of total) | 451 (79.68%) |
| Loss Trades (% of total) | 115 (20.32%) |
| Largest profit trade | 219.50 |
| Largest loss trade | -350.18 |
| Average profit trade | 2.73 |
| Average loss trade | -7.70 |
| Maximum consecutive wins ($) | 24 (31.44) |
| Maximum consecutive losses ($) | 4 (-0.22) |
| Average position holding time | 1:04:47 |
| Maximal position holding time | 44:33:46 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 12 | -605.21 | -50.43 |
| Stop-Loss (sl) | 554 | 950.38 | 1.72 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2024 | 274.25 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2024.01 | -18.20 | -18.20 |
| 2024.02 | 7.88 | -10.32 |
| 2024.03 | 70.66 | 60.34 |
| 2024.04 | -27.07 | 33.27 |
| 2024.05 | 6.88 | 40.15 |
| 2024.06 | 40.58 | 80.73 |
| 2024.07 | 112.08 | 192.81 |
| 2024.08 | 35.27 | 228.08 |
| 2024.09 | 37.39 | 265.47 |
| 2024.10 | -44.29 | 221.18 |
| 2024.11 | 38.42 | 259.60 |
| 2024.12 | 14.65 | 274.25 |

## 🔎 关键观察
- 最佳月份: **2024.07** (112.08 USD)
- 最差月份: **2024.10** (-44.29 USD)  ← 重点优化时间窗口
- 亏损月份数: 3 / 12
- 余额最大回撤: 350.25 (10.48%) | 净值最大回撤: 634.45 (18.48%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码