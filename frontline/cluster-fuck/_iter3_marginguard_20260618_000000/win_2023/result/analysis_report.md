# 📊 MT5 回测增强分析报告 — iter3 window 2023

**生成时间:** 2026-06-18 00:25:34

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | ea |
| Symbol | XAUUSD |
| Period | H1 (2023.01.01 - 2024.01.01) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 194.00 |
| Gross Profit | 368.37 |
| Gross Loss | -174.37 |
| Profit Factor | 2.11 |
| Expected Payoff | 1.05 |
| Recovery Factor | 0.14 |
| Sharpe Ratio | 0.83 |
| Balance Drawdown Maximal | 135.05 (4.19%) |
| Equity Drawdown Maximal | 1 402.36 (43.52%) |
| Balance Drawdown Relative | 4.19% (135.05) |
| Equity Drawdown Relative | 43.52% (1 402.36) |
| Total Trades | 184 |
| Short Trades (won %) | 69 (81.16%) |
| Long Trades (won %) | 115 (80.87%) |
| Profit Trades (% of total) | 149 (80.98%) |
| Loss Trades (% of total) | 35 (19.02%) |
| Largest profit trade | 37.53 |
| Largest loss trade | -92.91 |
| Average profit trade | 2.47 |
| Average loss trade | -4.26 |
| Maximum consecutive wins ($) | 33 (71.40) |
| Maximum consecutive losses ($) | 3 (-93.97) |
| Average position holding time | 1:39:29 |
| Maximal position holding time | 38:28:03 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 2 | -141.64 | -70.82 |
| Stop-Loss (sl) | 182 | 360.84 | 1.98 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2023 | 194.00 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2023.01 | 29.28 | 29.28 |
| 2023.02 | 33.51 | 62.79 |
| 2023.03 | 100.82 | 163.61 |
| 2023.04 | 8.09 | 171.70 |
| 2023.05 | -78.25 | 93.45 |
| 2023.09 | 24.41 | 117.86 |
| 2023.10 | 8.24 | 126.10 |
| 2023.11 | 21.20 | 147.30 |
| 2023.12 | 46.70 | 194.00 |

## 🔎 关键观察
- 最佳月份: **2023.03** (100.82 USD)
- 最差月份: **2023.05** (-78.25 USD)  ← 重点优化时间窗口
- 亏损月份数: 1 / 9
- 余额最大回撤: 135.05 (4.19%) | 净值最大回撤: 1 402.36 (43.52%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码