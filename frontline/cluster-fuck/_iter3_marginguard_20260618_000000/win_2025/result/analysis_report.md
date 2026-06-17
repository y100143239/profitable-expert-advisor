# 📊 MT5 回测增强分析报告 — iter3 window 2025

**生成时间:** 2026-06-18 00:29:39

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
| Total Net Profit | -2 993.65 |
| Gross Profit | 795.60 |
| Gross Loss | -3 789.25 |
| Profit Factor | 0.21 |
| Expected Payoff | -7.82 |
| Recovery Factor | -0.96 |
| Sharpe Ratio | -5.00 |
| Balance Drawdown Maximal | 3 129.26 (99.80%) |
| Equity Drawdown Maximal | 3 128.96 (99.80%) |
| Balance Drawdown Relative | 99.80% (3 129.26) |
| Equity Drawdown Relative | 99.80% (3 128.96) |
| Total Trades | 383 |
| Short Trades (won %) | 181 (80.11%) |
| Long Trades (won %) | 202 (77.72%) |
| Profit Trades (% of total) | 302 (78.85%) |
| Loss Trades (% of total) | 81 (21.15%) |
| Largest profit trade | 52.65 |
| Largest loss trade | -2 977.35 |
| Average profit trade | 2.63 |
| Average loss trade | -46.24 |
| Maximum consecutive wins ($) | 21 (49.62) |
| Maximum consecutive losses ($) | 4 (-0.48) |
| Average position holding time | 0:49:26 |
| Maximal position holding time | 74:32:00 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Stop-Out (so) | 1 | -2,977.35 | -2,977.35 |
| Signal/Trailing/Time exit | 13 | -753.26 | -57.94 |
| Stop-Loss (sl) | 369 | 780.57 | 2.12 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2025 | -2,993.65 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2025.01 | -15.90 | -15.90 |
| 2025.02 | 83.84 | 67.94 |
| 2025.03 | 14.12 | 82.06 |
| 2025.04 | -201.54 | -119.48 |
| 2025.05 | -2,874.17 | -2,993.65 |

## 🔎 关键观察
- 最佳月份: **2025.02** (83.84 USD)
- 最差月份: **2025.05** (-2,874.17 USD)  ← 重点优化时间窗口
- 亏损月份数: 3 / 5
- 余额最大回撤: 3 129.26 (99.80%) | 净值最大回撤: 3 128.96 (99.80%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码