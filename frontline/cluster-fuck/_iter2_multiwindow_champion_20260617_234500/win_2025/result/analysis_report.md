# 📊 MT5 回测增强分析报告 — Champion rl9 window 2025

**生成时间:** 2026-06-18 00:01:43

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
| Total Net Profit | 681.33 |
| Gross Profit | 3 172.04 |
| Gross Loss | -2 490.71 |
| Profit Factor | 1.27 |
| Expected Payoff | 0.48 |
| Recovery Factor | 0.96 |
| Sharpe Ratio | 1.67 |
| Balance Drawdown Maximal | 418.00 (10.91%) |
| Equity Drawdown Maximal | 707.60 (18.82%) |
| Balance Drawdown Relative | 10.91% (418.00) |
| Equity Drawdown Relative | 18.82% (707.60) |
| Total Trades | 1434 |
| Short Trades (won %) | 617 (72.77%) |
| Long Trades (won %) | 817 (78.95%) |
| Profit Trades (% of total) | 1094 (76.29%) |
| Loss Trades (% of total) | 340 (23.71%) |
| Largest profit trade | 263.25 |
| Largest loss trade | -217.49 |
| Average profit trade | 2.90 |
| Average loss trade | -6.83 |
| Maximum consecutive wins ($) | 28 (36.36) |
| Maximum consecutive losses ($) | 6 (-50.78) |
| Average position holding time | 0:32:01 |
| Maximal position holding time | 39:50:40 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 34 | -2,151.64 | -63.28 |
| Stop-Loss (sl) | 1400 | 3,001.11 | 2.14 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2025 | 681.33 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2025.01 | -9.00 | -9.00 |
| 2025.02 | 64.32 | 55.32 |
| 2025.03 | 67.82 | 123.14 |
| 2025.04 | -179.37 | -56.23 |
| 2025.05 | 242.46 | 186.23 |
| 2025.06 | -32.14 | 154.09 |
| 2025.07 | 128.73 | 282.82 |
| 2025.08 | 279.46 | 562.28 |
| 2025.09 | 153.96 | 716.24 |
| 2025.10 | -178.87 | 537.37 |
| 2025.11 | -54.44 | 482.93 |
| 2025.12 | 198.40 | 681.33 |

## 🔎 关键观察
- 最佳月份: **2025.08** (279.46 USD)
- 最差月份: **2025.04** (-179.37 USD)  ← 重点优化时间窗口
- 亏损月份数: 5 / 12
- 余额最大回撤: 418.00 (10.91%) | 净值最大回撤: 707.60 (18.82%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码