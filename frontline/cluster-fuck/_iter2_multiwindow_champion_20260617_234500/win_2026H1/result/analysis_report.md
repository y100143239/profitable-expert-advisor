# 📊 MT5 回测增强分析报告 — Champion rl9 window 2026H1

**生成时间:** 2026-06-18 00:05:43

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | ea |
| Symbol | XAUUSD |
| Period | H1 (2026.01.01 - 2026.06.17) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | -2 979.49 |
| Gross Profit | 4 372.06 |
| Gross Loss | -7 351.55 |
| Profit Factor | 0.59 |
| Expected Payoff | -2.32 |
| Recovery Factor | -0.75 |
| Sharpe Ratio | -5.00 |
| Balance Drawdown Maximal | 4 115.40 (99.50%) |
| Equity Drawdown Maximal | 3 978.19 (99.49%) |
| Balance Drawdown Relative | 99.50% (4 115.40) |
| Equity Drawdown Relative | 99.49% (3 978.19) |
| Total Trades | 1283 |
| Short Trades (won %) | 674 (73.29%) |
| Long Trades (won %) | 609 (75.86%) |
| Profit Trades (% of total) | 956 (74.51%) |
| Loss Trades (% of total) | 327 (25.49%) |
| Largest profit trade | 347.48 |
| Largest loss trade | -4 115.40 |
| Average profit trade | 4.57 |
| Average loss trade | -22.03 |
| Maximum consecutive wins ($) | 21 (44.09) |
| Maximum consecutive losses ($) | 4 (-3.82) |
| Average position holding time | 0:19:31 |
| Maximal position holding time | 27:35:43 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Stop-Out (so) | 1 | -4,115.40 | -4,115.40 |
| Signal/Trailing/Time exit | 39 | -2,269.96 | -58.20 |
| Stop-Loss (sl) | 1243 | 3,553.20 | 2.86 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2026 | -2,979.49 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2026.01 | 613.68 | 613.68 |
| 2026.02 | 276.44 | 890.12 |
| 2026.03 | -153.29 | 736.83 |
| 2026.04 | -221.97 | 514.86 |
| 2026.05 | 126.94 | 641.80 |
| 2026.06 | -3,621.29 | -2,979.49 |

## 🔎 关键观察
- 最佳月份: **2026.01** (613.68 USD)
- 最差月份: **2026.06** (-3,621.29 USD)  ← 重点优化时间窗口
- 亏损月份数: 3 / 6
- 余额最大回撤: 4 115.40 (99.50%) | 净值最大回撤: 3 978.19 (99.49%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码