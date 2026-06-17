# 📊 MT5 回测增强分析报告 — sweep 800 2026H1

**生成时间:** 2026-06-18 01:08:26

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
| Total Net Profit | 1 302.01 |
| Gross Profit | 4 358.67 |
| Gross Loss | -3 056.66 |
| Profit Factor | 1.43 |
| Expected Payoff | 0.92 |
| Recovery Factor | 1.70 |
| Sharpe Ratio | 4.40 |
| Balance Drawdown Maximal | 688.23 (17.92%) |
| Equity Drawdown Maximal | 764.86 (19.91%) |
| Balance Drawdown Relative | 17.92% (688.23) |
| Equity Drawdown Relative | 19.91% (764.86) |
| Total Trades | 1420 |
| Short Trades (won %) | 769 (71.26%) |
| Long Trades (won %) | 651 (76.65%) |
| Profit Trades (% of total) | 1047 (73.73%) |
| Loss Trades (% of total) | 373 (26.27%) |
| Largest profit trade | 349.28 |
| Largest loss trade | -383.38 |
| Average profit trade | 4.16 |
| Average loss trade | -7.85 |
| Maximum consecutive wins ($) | 27 (28.81) |
| Maximum consecutive losses ($) | 5 (-166.53) |
| Average position holding time | 0:15:44 |
| Maximal position holding time | 35:14:54 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 38 | -2,533.13 | -66.66 |
| Stop-Loss (sl) | 1382 | 3,964.74 | 2.87 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2026 | 1,302.01 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2026.01 | 531.06 | 531.06 |
| 2026.02 | 185.03 | 716.09 |
| 2026.03 | -512.72 | 203.37 |
| 2026.04 | 160.13 | 363.50 |
| 2026.05 | 342.64 | 706.14 |
| 2026.06 | 595.87 | 1,302.01 |

## 🔎 关键观察
- 最佳月份: **2026.06** (595.87 USD)
- 最差月份: **2026.03** (-512.72 USD)  ← 重点优化时间窗口
- 亏损月份数: 1 / 6
- 余额最大回撤: 688.23 (17.92%) | 净值最大回撤: 764.86 (19.91%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码