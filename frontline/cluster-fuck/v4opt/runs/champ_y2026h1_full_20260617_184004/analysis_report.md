# 📊 MT5 回测增强分析报告 — Champion#1 window 2026H1 (base1.5+cap3+MU)

**生成时间:** 2026-06-17 18:44:40

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | main |
| Symbol | EURUSD |
| Period | H1 (2026.01.01 - 2026.06.17) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 11 186.54 |
| Gross Profit | 41 421.22 |
| Gross Loss | -30 234.68 |
| Profit Factor | 1.37 |
| Expected Payoff | 9.33 |
| Recovery Factor | 3.52 |
| Sharpe Ratio | 3.10 |
| Balance Drawdown Maximal | 3 418.99 (44.41%) |
| Equity Drawdown Maximal | 3 179.22 (39.76%) |
| Balance Drawdown Relative | 44.41% (3 418.99) |
| Equity Drawdown Relative | 39.76% (3 179.22) |
| Total Trades | 1199 |
| Short Trades (won %) | 506 (42.69%) |
| Long Trades (won %) | 693 (45.31%) |
| Profit Trades (% of total) | 530 (44.20%) |
| Loss Trades (% of total) | 669 (55.80%) |
| Largest profit trade | 2 797.18 |
| Largest loss trade | -1 128.17 |
| Average profit trade | 78.15 |
| Average loss trade | -44.66 |
| Maximum consecutive wins ($) | 8 (472.93) |
| Maximum consecutive losses ($) | 9 (-1 166.95) |
| Average position holding time | 4:42:15 |
| Maximal position holding time | 243:00:00 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| end | 4 | -92.93 | -23.23 |
| Signal/Trailing/Time exit | 554 | 1,507.52 | 2.72 |
| Take-Profit (tp) | 21 | 1,862.90 | 88.71 |
| Stop-Loss (sl) | 620 | 8,266.59 | 13.33 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2026 | 11,186.54 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2026.01 | 677.13 | 677.13 |
| 2026.02 | -174.99 | 502.14 |
| 2026.03 | 2,169.62 | 2,671.76 |
| 2026.04 | 3,010.91 | 5,682.67 |
| 2026.05 | 2,425.31 | 8,107.98 |
| 2026.06 | 3,078.56 | 11,186.54 |

## 🔎 关键观察
- 最佳月份: **2026.06** (3,078.56 USD)
- 最差月份: **2026.02** (-174.99 USD)  ← 重点优化时间窗口
- 亏损月份数: 1 / 6
- 余额最大回撤: 3 418.99 (44.41%) | 净值最大回撤: 3 179.22 (39.76%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码