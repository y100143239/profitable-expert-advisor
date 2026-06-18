# 📊 MT5 回测增强分析报告 — i5b m2 2026H1

**生成时间:** 2026-06-18 02:03:17

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
| Total Net Profit | 668.21 |
| Gross Profit | 3 135.80 |
| Gross Loss | -2 467.59 |
| Profit Factor | 1.27 |
| Expected Payoff | 0.48 |
| Recovery Factor | 0.91 |
| Sharpe Ratio | 3.75 |
| Balance Drawdown Maximal | 701.69 (18.65%) |
| Equity Drawdown Maximal | 733.38 (19.50%) |
| Balance Drawdown Relative | 18.65% (701.69) |
| Equity Drawdown Relative | 19.50% (733.38) |
| Total Trades | 1378 |
| Short Trades (won %) | 739 (76.59%) |
| Long Trades (won %) | 639 (77.62%) |
| Profit Trades (% of total) | 1062 (77.07%) |
| Loss Trades (% of total) | 316 (22.93%) |
| Largest profit trade | 99.89 |
| Largest loss trade | -205.28 |
| Average profit trade | 2.95 |
| Average loss trade | -7.49 |
| Maximum consecutive wins ($) | 25 (115.39) |
| Maximum consecutive losses ($) | 5 (-2.23) |
| Average position holding time | 0:16:58 |
| Maximal position holding time | 25:19:34 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 33 | -2,142.79 | -64.93 |
| Stop-Loss (sl) | 1345 | 2,911.63 | 2.16 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2026 | 668.21 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2026.01 | 278.21 | 278.21 |
| 2026.02 | 388.43 | 666.64 |
| 2026.03 | -250.03 | 416.61 |
| 2026.04 | -222.68 | 193.93 |
| 2026.05 | 124.02 | 317.95 |
| 2026.06 | 350.26 | 668.21 |

## 🔎 关键观察
- 最佳月份: **2026.02** (388.43 USD)
- 最差月份: **2026.03** (-250.03 USD)  ← 重点优化时间窗口
- 亏损月份数: 2 / 6
- 余额最大回撤: 701.69 (18.65%) | 净值最大回撤: 733.38 (19.50%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码