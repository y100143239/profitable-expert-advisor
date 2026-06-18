# 📊 MT5 回测增强分析报告 — i5b m3 2026H1

**生成时间:** 2026-06-18 02:18:28

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
| Total Net Profit | -27.82 |
| Gross Profit | 3 371.77 |
| Gross Loss | -3 399.59 |
| Profit Factor | 0.99 |
| Expected Payoff | -0.02 |
| Recovery Factor | -0.03 |
| Sharpe Ratio | -0.13 |
| Balance Drawdown Maximal | 822.86 (24.93%) |
| Equity Drawdown Maximal | 908.16 (27.50%) |
| Balance Drawdown Relative | 24.93% (822.86) |
| Equity Drawdown Relative | 27.50% (908.16) |
| Total Trades | 1311 |
| Short Trades (won %) | 735 (74.15%) |
| Long Trades (won %) | 576 (75.52%) |
| Profit Trades (% of total) | 980 (74.75%) |
| Loss Trades (% of total) | 331 (25.25%) |
| Largest profit trade | 105.77 |
| Largest loss trade | -294.19 |
| Average profit trade | 3.44 |
| Average loss trade | -9.97 |
| Maximum consecutive wins ($) | 22 (57.56) |
| Maximum consecutive losses ($) | 4 (-0.66) |
| Average position holding time | 0:20:23 |
| Maximal position holding time | 37:57:43 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 45 | -2,684.21 | -59.65 |
| Stop-Loss (sl) | 1266 | 2,755.30 | 2.18 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2026 | -27.82 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2026.01 | -146.03 | -146.03 |
| 2026.02 | 314.15 | 168.12 |
| 2026.03 | -315.80 | -147.68 |
| 2026.04 | -258.90 | -406.58 |
| 2026.05 | 171.04 | -235.54 |
| 2026.06 | 207.72 | -27.82 |

## 🔎 关键观察
- 最佳月份: **2026.02** (314.15 USD)
- 最差月份: **2026.03** (-315.80 USD)  ← 重点优化时间窗口
- 亏损月份数: 3 / 6
- 余额最大回撤: 822.86 (24.93%) | 净值最大回撤: 908.16 (27.50%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码