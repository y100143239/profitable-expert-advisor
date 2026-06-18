# 📊 MT5 回测增强分析报告 — i5b m2 2025

**生成时间:** 2026-06-18 01:59:45

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
| Total Net Profit | -212.04 |
| Gross Profit | 2 080.63 |
| Gross Loss | -2 292.67 |
| Profit Factor | 0.91 |
| Expected Payoff | -0.14 |
| Recovery Factor | -0.35 |
| Sharpe Ratio | -1.28 |
| Balance Drawdown Maximal | 610.48 (19.27%) |
| Equity Drawdown Maximal | 607.72 (19.24%) |
| Balance Drawdown Relative | 19.27% (610.48) |
| Equity Drawdown Relative | 19.24% (607.72) |
| Total Trades | 1474 |
| Short Trades (won %) | 582 (72.85%) |
| Long Trades (won %) | 892 (77.80%) |
| Profit Trades (% of total) | 1118 (75.85%) |
| Loss Trades (% of total) | 356 (24.15%) |
| Largest profit trade | 17.65 |
| Largest loss trade | -171.43 |
| Average profit trade | 1.86 |
| Average loss trade | -6.13 |
| Maximum consecutive wins ($) | 22 (33.26) |
| Maximum consecutive losses ($) | 5 (-64.60) |
| Average position holding time | 0:30:46 |
| Maximal position holding time | 33:31:27 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 34 | -2,096.09 | -61.65 |
| Stop-Loss (sl) | 1440 | 1,993.39 | 1.38 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2025 | -212.04 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2025.01 | -42.45 | -42.45 |
| 2025.02 | 33.24 | -9.21 |
| 2025.03 | -2.72 | -11.93 |
| 2025.04 | -252.59 | -264.52 |
| 2025.05 | 58.90 | -205.62 |
| 2025.06 | -88.18 | -293.80 |
| 2025.07 | 103.00 | -190.80 |
| 2025.08 | 22.67 | -168.13 |
| 2025.09 | 165.84 | -2.29 |
| 2025.10 | -242.17 | -244.46 |
| 2025.11 | -138.48 | -382.94 |
| 2025.12 | 170.90 | -212.04 |

## 🔎 关键观察
- 最佳月份: **2025.12** (170.90 USD)
- 最差月份: **2025.04** (-252.59 USD)  ← 重点优化时间窗口
- 亏损月份数: 6 / 12
- 余额最大回撤: 610.48 (19.27%) | 净值最大回撤: 607.72 (19.24%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码