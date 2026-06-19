# 📊 MT5 回测增强分析报告 — stability sm_q3_2023

**生成时间:** 2026-06-19 22:26:20

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | main |
| Symbol | EURUSD |
| Period | H1 (2023.07.01 - 2023.09.30) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | -470.81 |
| Gross Profit | 114.14 |
| Gross Loss | -584.95 |
| Profit Factor | 0.20 |
| Expected Payoff | -7.98 |
| Recovery Factor | -0.85 |
| Sharpe Ratio | -5.00 |
| Balance Drawdown Maximal | 531.98 (17.44%) |
| Equity Drawdown Maximal | 555.42 (18.13%) |
| Balance Drawdown Relative | 17.44% (531.98) |
| Equity Drawdown Relative | 18.13% (555.42) |
| Total Trades | 59 |
| Short Trades (won %) | 14 (57.14%) |
| Long Trades (won %) | 45 (26.67%) |
| Profit Trades (% of total) | 20 (33.90%) |
| Loss Trades (% of total) | 39 (66.10%) |
| Largest profit trade | 39.07 |
| Largest loss trade | -131.56 |
| Average profit trade | 5.71 |
| Average loss trade | -14.79 |
| Maximum consecutive wins ($) | 3 (19.69) |
| Maximum consecutive losses ($) | 9 (-107.65) |
| Average position holding time | 10:20:06 |
| Maximal position holding time | 167:44:59 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 41 | -366.50 | -8.94 |
| Stop-Loss (sl) | 18 | -96.15 | -5.34 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2023 | -470.81 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2023.07 | -147.86 | -147.86 |
| 2023.08 | -242.26 | -390.12 |
| 2023.09 | -80.69 | -470.81 |

## 🔎 关键观察
- 最佳月份: **2023.09** (-80.69 USD)
- 最差月份: **2023.08** (-242.26 USD)  ← 重点优化时间窗口
- 亏损月份数: 3 / 3
- 余额最大回撤: 531.98 (17.44%) | 净值最大回撤: 555.42 (18.13%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码