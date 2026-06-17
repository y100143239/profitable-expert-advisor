# 📊 MT5 回测增强分析报告 — Champion revLot9 2025 RERUN warm

**生成时间:** 2026-06-17 07:43:29

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | EMACrossOver_V4 |
| Symbol | XAUUSD |
| Period | H1 (2025.01.01 - 2025.12.31) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | -1 392.36 |
| Gross Profit | 1 919.26 |
| Gross Loss | -3 311.62 |
| Profit Factor | 0.58 |
| Expected Payoff | -0.94 |
| Recovery Factor | -0.68 |
| Sharpe Ratio | -2.49 |
| Balance Drawdown Maximal | 1 761.48 (55.66%) |
| Equity Drawdown Maximal | 2 053.92 (65.78%) |
| Balance Drawdown Relative | 55.66% (1 761.48) |
| Equity Drawdown Relative | 65.78% (2 053.92) |
| Total Trades | 1478 |
| Short Trades (won %) | 637 (76.14%) |
| Long Trades (won %) | 841 (77.05%) |
| Profit Trades (% of total) | 1133 (76.66%) |
| Loss Trades (% of total) | 345 (23.34%) |
| Largest profit trade | 51.57 |
| Largest loss trade | -1 571.99 |
| Average profit trade | 1.69 |
| Average loss trade | -9.29 |
| Maximum consecutive wins ($) | 25 (22.50) |
| Maximum consecutive losses ($) | 5 (-48.89) |
| Average position holding time | 0:34:39 |
| Maximal position holding time | 57:13:57 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 44 | -3,106.83 | -70.61 |
| Stop-Loss (sl) | 1434 | 1,822.63 | 1.27 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2025 | -1,392.36 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2025.01 | -11.06 | -11.06 |
| 2025.02 | 94.52 | 83.46 |
| 2025.03 | -25.26 | 58.20 |
| 2025.04 | -108.95 | -50.75 |
| 2025.05 | -1,408.24 | -1,458.99 |
| 2025.06 | -114.99 | -1,573.98 |
| 2025.07 | 83.80 | -1,490.18 |
| 2025.08 | 0.35 | -1,489.83 |
| 2025.09 | 62.39 | -1,427.44 |
| 2025.10 | -59.99 | -1,487.43 |
| 2025.11 | -11.23 | -1,498.66 |
| 2025.12 | 106.30 | -1,392.36 |

## 🔎 关键观察
- 最佳月份: **2025.12** (106.30 USD)
- 最差月份: **2025.05** (-1,408.24 USD)  ← 重点优化时间窗口
- 亏损月份数: 7 / 12
- 余额最大回撤: 1 761.48 (55.66%) | 净值最大回撤: 2 053.92 (65.78%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码