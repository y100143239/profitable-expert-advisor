# 📊 MT5 回测增强分析报告 — i5b m2 2024

**生成时间:** 2026-06-18 02:21:16

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
| Total Net Profit | 270.92 |
| Gross Profit | 712.76 |
| Gross Loss | -441.84 |
| Profit Factor | 1.61 |
| Expected Payoff | 0.50 |
| Recovery Factor | 2.83 |
| Sharpe Ratio | 4.90 |
| Balance Drawdown Maximal | 69.70 (2.21%) |
| Equity Drawdown Maximal | 95.84 (3.04%) |
| Balance Drawdown Relative | 2.21% (69.70) |
| Equity Drawdown Relative | 3.04% (95.84) |
| Total Trades | 547 |
| Short Trades (won %) | 264 (82.95%) |
| Long Trades (won %) | 283 (80.57%) |
| Profit Trades (% of total) | 447 (81.72%) |
| Loss Trades (% of total) | 100 (18.28%) |
| Largest profit trade | 47.78 |
| Largest loss trade | -69.63 |
| Average profit trade | 1.59 |
| Average loss trade | -4.01 |
| Maximum consecutive wins ($) | 26 (41.82) |
| Maximum consecutive losses ($) | 4 (-51.41) |
| Average position holding time | 1:01:16 |
| Maximal position holding time | 39:54:17 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 9 | -319.74 | -35.53 |
| Stop-Loss (sl) | 538 | 631.40 | 1.17 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2024 | 270.92 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2024.01 | -22.48 | -22.48 |
| 2024.02 | 8.28 | -14.20 |
| 2024.03 | 53.78 | 39.58 |
| 2024.04 | 68.21 | 107.79 |
| 2024.05 | 5.30 | 113.09 |
| 2024.06 | 51.24 | 164.33 |
| 2024.07 | 33.89 | 198.22 |
| 2024.08 | -46.99 | 151.23 |
| 2024.09 | 19.40 | 170.63 |
| 2024.10 | 43.74 | 214.37 |
| 2024.11 | 38.30 | 252.67 |
| 2024.12 | 18.25 | 270.92 |

## 🔎 关键观察
- 最佳月份: **2024.04** (68.21 USD)
- 最差月份: **2024.08** (-46.99 USD)  ← 重点优化时间窗口
- 亏损月份数: 2 / 12
- 余额最大回撤: 69.70 (2.21%) | 净值最大回撤: 95.84 (3.04%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码