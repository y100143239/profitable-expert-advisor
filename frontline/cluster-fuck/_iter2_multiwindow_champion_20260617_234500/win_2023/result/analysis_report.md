# 📊 MT5 回测增强分析报告 — Champion rl9 window 2023

**生成时间:** 2026-06-17 23:55:28

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | ea |
| Symbol | XAUUSD |
| Period | H1 (2023.01.01 - 2024.01.01) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 217.47 |
| Gross Profit | 393.15 |
| Gross Loss | -175.68 |
| Profit Factor | 2.24 |
| Expected Payoff | 1.29 |
| Recovery Factor | 0.16 |
| Sharpe Ratio | 0.89 |
| Balance Drawdown Maximal | 137.61 (4.26%) |
| Equity Drawdown Maximal | 1 393.76 (43.29%) |
| Balance Drawdown Relative | 4.26% (137.61) |
| Equity Drawdown Relative | 43.29% (1 393.76) |
| Total Trades | 168 |
| Short Trades (won %) | 68 (88.24%) |
| Long Trades (won %) | 100 (82.00%) |
| Profit Trades (% of total) | 142 (84.52%) |
| Loss Trades (% of total) | 26 (15.48%) |
| Largest profit trade | 51.09 |
| Largest loss trade | -97.55 |
| Average profit trade | 2.77 |
| Average loss trade | -5.83 |
| Maximum consecutive wins ($) | 37 (96.43) |
| Maximum consecutive losses ($) | 3 (-99.33) |
| Average position holding time | 1:54:36 |
| Maximal position holding time | 38:28:06 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 2 | -145.88 | -72.94 |
| Stop-Loss (sl) | 166 | 387.43 | 2.33 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2023 | 217.47 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2023.01 | 23.92 | 23.92 |
| 2023.02 | 17.51 | 41.43 |
| 2023.03 | 77.06 | 118.49 |
| 2023.04 | 60.65 | 179.14 |
| 2023.05 | -82.85 | 96.29 |
| 2023.09 | 24.79 | 121.08 |
| 2023.10 | 8.74 | 129.82 |
| 2023.11 | 16.36 | 146.18 |
| 2023.12 | 71.29 | 217.47 |

## 🔎 关键观察
- 最佳月份: **2023.03** (77.06 USD)
- 最差月份: **2023.05** (-82.85 USD)  ← 重点优化时间窗口
- 亏损月份数: 1 / 9
- 余额最大回撤: 137.61 (4.26%) | 净值最大回撤: 1 393.76 (43.29%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码