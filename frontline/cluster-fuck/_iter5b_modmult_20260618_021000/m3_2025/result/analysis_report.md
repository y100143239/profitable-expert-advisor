# 📊 MT5 回测增强分析报告 — i5b m3 2025

**生成时间:** 2026-06-18 02:14:57

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
| Total Net Profit | -522.36 |
| Gross Profit | 2 173.40 |
| Gross Loss | -2 695.76 |
| Profit Factor | 0.81 |
| Expected Payoff | -0.36 |
| Recovery Factor | -0.67 |
| Sharpe Ratio | -3.15 |
| Balance Drawdown Maximal | 732.33 (23.83%) |
| Equity Drawdown Maximal | 782.23 (25.57%) |
| Balance Drawdown Relative | 23.83% (732.33) |
| Equity Drawdown Relative | 25.57% (782.23) |
| Total Trades | 1433 |
| Short Trades (won %) | 636 (74.21%) |
| Long Trades (won %) | 797 (80.55%) |
| Profit Trades (% of total) | 1114 (77.74%) |
| Loss Trades (% of total) | 319 (22.26%) |
| Largest profit trade | 35.55 |
| Largest loss trade | -172.55 |
| Average profit trade | 1.95 |
| Average loss trade | -8.10 |
| Maximum consecutive wins ($) | 21 (50.11) |
| Maximum consecutive losses ($) | 7 (-49.03) |
| Average position holding time | 0:29:43 |
| Maximal position holding time | 29:07:28 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 38 | -2,397.06 | -63.08 |
| Stop-Loss (sl) | 1395 | 1,987.19 | 1.42 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2025 | -522.36 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2025.01 | -33.58 | -33.58 |
| 2025.02 | -21.42 | -55.00 |
| 2025.03 | -31.10 | -86.10 |
| 2025.04 | -221.36 | -307.46 |
| 2025.05 | 121.43 | -186.03 |
| 2025.06 | -73.56 | -259.59 |
| 2025.07 | 31.89 | -227.70 |
| 2025.08 | 35.70 | -192.00 |
| 2025.09 | 135.60 | -56.40 |
| 2025.10 | -369.50 | -425.90 |
| 2025.11 | -163.14 | -589.04 |
| 2025.12 | 66.68 | -522.36 |

## 🔎 关键观察
- 最佳月份: **2025.09** (135.60 USD)
- 最差月份: **2025.10** (-369.50 USD)  ← 重点优化时间窗口
- 亏损月份数: 7 / 12
- 余额最大回撤: 732.33 (23.83%) | 净值最大回撤: 782.23 (25.57%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码