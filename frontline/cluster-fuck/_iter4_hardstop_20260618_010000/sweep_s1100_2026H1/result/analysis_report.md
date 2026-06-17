# 📊 MT5 回测增强分析报告 — sweep 1100 2026H1

**生成时间:** 2026-06-18 01:12:56

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
| Total Net Profit | 127.35 |
| Gross Profit | 4 165.32 |
| Gross Loss | -4 037.97 |
| Profit Factor | 1.03 |
| Expected Payoff | 0.09 |
| Recovery Factor | 0.08 |
| Sharpe Ratio | 0.41 |
| Balance Drawdown Maximal | 1 419.95 (36.61%) |
| Equity Drawdown Maximal | 1 504.69 (38.75%) |
| Balance Drawdown Relative | 36.61% (1 419.95) |
| Equity Drawdown Relative | 38.75% (1 504.69) |
| Total Trades | 1358 |
| Short Trades (won %) | 748 (74.87%) |
| Long Trades (won %) | 610 (75.74%) |
| Profit Trades (% of total) | 1022 (75.26%) |
| Loss Trades (% of total) | 336 (24.74%) |
| Largest profit trade | 352.34 |
| Largest loss trade | -1 107.93 |
| Average profit trade | 4.08 |
| Average loss trade | -11.64 |
| Maximum consecutive wins ($) | 20 (69.14) |
| Maximum consecutive losses ($) | 5 (-1.83) |
| Average position holding time | 0:17:51 |
| Maximal position holding time | 45:32:52 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 37 | -3,727.55 | -100.74 |
| Stop-Loss (sl) | 1321 | 3,983.09 | 3.02 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2026 | 127.35 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2026.01 | 732.76 | 732.76 |
| 2026.02 | -1,011.86 | -279.10 |
| 2026.03 | 73.25 | -205.85 |
| 2026.04 | -128.65 | -334.50 |
| 2026.05 | 136.17 | -198.33 |
| 2026.06 | 325.68 | 127.35 |

## 🔎 关键观察
- 最佳月份: **2026.01** (732.76 USD)
- 最差月份: **2026.02** (-1,011.86 USD)  ← 重点优化时间窗口
- 亏损月份数: 2 / 6
- 余额最大回撤: 1 419.95 (36.61%) | 净值最大回撤: 1 504.69 (38.75%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码