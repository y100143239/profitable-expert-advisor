# 📊 MT5 回测增强分析报告 — iter4 window 2023

**生成时间:** 2026-06-18 00:59:56

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
| Total Net Profit | -358.39 |
| Gross Profit | 377.19 |
| Gross Loss | -735.58 |
| Profit Factor | 0.51 |
| Expected Payoff | -1.82 |
| Recovery Factor | -0.63 |
| Sharpe Ratio | -4.36 |
| Balance Drawdown Maximal | 541.55 (17.24%) |
| Equity Drawdown Maximal | 565.03 (17.98%) |
| Balance Drawdown Relative | 17.24% (541.55) |
| Equity Drawdown Relative | 17.98% (565.03) |
| Total Trades | 197 |
| Short Trades (won %) | 66 (80.30%) |
| Long Trades (won %) | 131 (81.68%) |
| Profit Trades (% of total) | 160 (81.22%) |
| Loss Trades (% of total) | 37 (18.78%) |
| Largest profit trade | 36.69 |
| Largest loss trade | -509.43 |
| Average profit trade | 2.36 |
| Average loss trade | -19.17 |
| Maximum consecutive wins ($) | 24 (36.29) |
| Maximum consecutive losses ($) | 3 (-51.99) |
| Average position holding time | 1:38:18 |
| Maximal position holding time | 47:32:36 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 5 | -687.53 | -137.51 |
| Stop-Loss (sl) | 192 | 355.25 | 1.85 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2023 | -358.39 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2023.01 | 26.26 | 26.26 |
| 2023.02 | -25.28 | 0.98 |
| 2023.03 | 80.00 | 80.98 |
| 2023.04 | 7.31 | 88.29 |
| 2023.05 | -73.01 | 15.28 |
| 2023.09 | 26.49 | 41.77 |
| 2023.10 | 36.52 | 78.29 |
| 2023.11 | 19.26 | 97.55 |
| 2023.12 | -455.94 | -358.39 |

## 🔎 关键观察
- 最佳月份: **2023.03** (80.00 USD)
- 最差月份: **2023.12** (-455.94 USD)  ← 重点优化时间窗口
- 亏损月份数: 3 / 9
- 余额最大回撤: 541.55 (17.24%) | 净值最大回撤: 565.03 (17.98%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码