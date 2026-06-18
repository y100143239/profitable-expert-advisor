# 📊 MT5 回测增强分析报告 — iter5a nomart 2023

**生成时间:** 2026-06-18 01:45:50

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
| Total Net Profit | 113.01 |
| Gross Profit | 228.35 |
| Gross Loss | -115.34 |
| Profit Factor | 1.98 |
| Expected Payoff | 0.57 |
| Recovery Factor | 0.60 |
| Sharpe Ratio | 3.97 |
| Balance Drawdown Maximal | 93.37 (3.00%) |
| Equity Drawdown Maximal | 188.69 (6.05%) |
| Balance Drawdown Relative | 3.00% (93.37) |
| Equity Drawdown Relative | 6.05% (188.69) |
| Total Trades | 197 |
| Short Trades (won %) | 69 (86.96%) |
| Long Trades (won %) | 128 (85.94%) |
| Profit Trades (% of total) | 170 (86.29%) |
| Loss Trades (% of total) | 27 (13.71%) |
| Largest profit trade | 8.57 |
| Largest loss trade | -92.91 |
| Average profit trade | 1.34 |
| Average loss trade | -3.76 |
| Maximum consecutive wins ($) | 18 (18.86) |
| Maximum consecutive losses ($) | 3 (-93.09) |
| Average position holding time | 1:23:44 |
| Maximal position holding time | 38:28:01 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 1 | -92.91 | -92.91 |
| Stop-Loss (sl) | 196 | 219.71 | 1.12 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2023 | 113.01 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2023.01 | 21.77 | 21.77 |
| 2023.02 | 15.25 | 37.02 |
| 2023.03 | 37.44 | 74.46 |
| 2023.04 | 31.08 | 105.54 |
| 2023.05 | -78.53 | 27.01 |
| 2023.09 | 15.51 | 42.52 |
| 2023.10 | 20.43 | 62.95 |
| 2023.11 | 10.29 | 73.24 |
| 2023.12 | 39.77 | 113.01 |

## 🔎 关键观察
- 最佳月份: **2023.12** (39.77 USD)
- 最差月份: **2023.05** (-78.53 USD)  ← 重点优化时间窗口
- 亏损月份数: 1 / 9
- 余额最大回撤: 93.37 (3.00%) | 净值最大回撤: 188.69 (6.05%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码