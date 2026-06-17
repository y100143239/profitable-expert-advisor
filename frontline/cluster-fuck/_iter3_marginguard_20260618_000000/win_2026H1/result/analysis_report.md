# 📊 MT5 回测增强分析报告 — iter3 MarginGuard window 2026H1 (blowup test)

**生成时间:** 2026-06-18 00:23:59

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
| Total Net Profit | 579.29 |
| Gross Profit | 4 097.83 |
| Gross Loss | -3 518.54 |
| Profit Factor | 1.16 |
| Expected Payoff | 0.43 |
| Recovery Factor | 0.76 |
| Sharpe Ratio | 2.36 |
| Balance Drawdown Maximal | 735.17 (18.60%) |
| Equity Drawdown Maximal | 764.01 (19.30%) |
| Balance Drawdown Relative | 18.60% (735.17) |
| Equity Drawdown Relative | 19.30% (764.01) |
| Total Trades | 1336 |
| Short Trades (won %) | 717 (74.06%) |
| Long Trades (won %) | 619 (78.03%) |
| Profit Trades (% of total) | 1014 (75.90%) |
| Loss Trades (% of total) | 322 (24.10%) |
| Largest profit trade | 349.10 |
| Largest loss trade | -330.16 |
| Average profit trade | 4.04 |
| Average loss trade | -10.52 |
| Maximum consecutive wins ($) | 19 (98.99) |
| Maximum consecutive losses ($) | 4 (-2.68) |
| Average position holding time | 0:17:35 |
| Maximal position holding time | 25:19:33 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 39 | -3,054.57 | -78.32 |
| Stop-Loss (sl) | 1297 | 3,766.50 | 2.90 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2026 | 579.29 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2026.01 | 530.98 | 530.98 |
| 2026.02 | 230.80 | 761.78 |
| 2026.03 | -364.96 | 396.82 |
| 2026.04 | -44.42 | 352.40 |
| 2026.05 | 210.29 | 562.69 |
| 2026.06 | 16.60 | 579.29 |

## 🔎 关键观察
- 最佳月份: **2026.01** (530.98 USD)
- 最差月份: **2026.03** (-364.96 USD)  ← 重点优化时间窗口
- 亏损月份数: 2 / 6
- 余额最大回撤: 735.17 (18.60%) | 净值最大回撤: 764.01 (19.30%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码