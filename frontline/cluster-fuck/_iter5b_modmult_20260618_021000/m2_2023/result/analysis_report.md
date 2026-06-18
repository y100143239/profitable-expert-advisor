# 📊 MT5 回测增强分析报告 — i5b m2 2023

**生成时间:** 2026-06-18 02:19:47

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
| Total Net Profit | 63.11 |
| Gross Profit | 217.90 |
| Gross Loss | -154.79 |
| Profit Factor | 1.41 |
| Expected Payoff | 0.35 |
| Recovery Factor | 0.16 |
| Sharpe Ratio | 1.29 |
| Balance Drawdown Maximal | 129.16 (4.13%) |
| Equity Drawdown Maximal | 388.70 (12.42%) |
| Balance Drawdown Relative | 4.13% (129.16) |
| Equity Drawdown Relative | 12.42% (388.70) |
| Total Trades | 181 |
| Short Trades (won %) | 69 (78.26%) |
| Long Trades (won %) | 112 (86.61%) |
| Profit Trades (% of total) | 151 (83.43%) |
| Loss Trades (% of total) | 30 (16.57%) |
| Largest profit trade | 10.21 |
| Largest loss trade | -86.87 |
| Average profit trade | 1.44 |
| Average loss trade | -4.68 |
| Maximum consecutive wins ($) | 27 (46.48) |
| Maximum consecutive losses ($) | 2 (-87.13) |
| Average position holding time | 1:46:08 |
| Maximal position holding time | 38:27:58 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 3 | -132.57 | -44.19 |
| Stop-Loss (sl) | 178 | 210.03 | 1.18 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2023 | 63.11 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2023.01 | 17.12 | 17.12 |
| 2023.02 | 18.09 | 35.21 |
| 2023.03 | 50.58 | 85.79 |
| 2023.04 | 30.57 | 116.36 |
| 2023.05 | -114.92 | 1.44 |
| 2023.09 | 15.75 | 17.19 |
| 2023.10 | 5.78 | 22.97 |
| 2023.11 | 9.45 | 32.42 |
| 2023.12 | 30.69 | 63.11 |

## 🔎 关键观察
- 最佳月份: **2023.03** (50.58 USD)
- 最差月份: **2023.05** (-114.92 USD)  ← 重点优化时间窗口
- 亏损月份数: 1 / 9
- 余额最大回撤: 129.16 (4.13%) | 净值最大回撤: 388.70 (12.42%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码