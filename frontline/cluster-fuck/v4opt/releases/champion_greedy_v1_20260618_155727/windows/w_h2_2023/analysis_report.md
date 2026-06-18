# 📊 MT5 回测增强分析报告 — champion defaults cold-start w_h2_2023

**生成时间:** 2026-06-18 16:50:31

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | main |
| Symbol | EURUSD |
| Period | H1 (2023.07.01 - 2023.12.31) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | -180.99 |
| Gross Profit | 2 331.35 |
| Gross Loss | -2 512.34 |
| Profit Factor | 0.93 |
| Expected Payoff | -0.61 |
| Recovery Factor | -0.23 |
| Sharpe Ratio | -0.50 |
| Balance Drawdown Maximal | 763.11 (25.08%) |
| Equity Drawdown Maximal | 773.50 (25.19%) |
| Balance Drawdown Relative | 25.08% (763.11) |
| Equity Drawdown Relative | 25.19% (773.50) |
| Total Trades | 298 |
| Short Trades (won %) | 126 (41.27%) |
| Long Trades (won %) | 172 (37.21%) |
| Profit Trades (% of total) | 116 (38.93%) |
| Loss Trades (% of total) | 182 (61.07%) |
| Largest profit trade | 373.15 |
| Largest loss trade | -219.26 |
| Average profit trade | 20.10 |
| Average loss trade | -13.51 |
| Maximum consecutive wins ($) | 5 (368.91) |
| Maximum consecutive losses ($) | 9 (-55.17) |
| Average position holding time | 10:57:10 |
| Maximal position holding time | 304:58:58 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 196 | -715.89 | -3.65 |
| end | 6 | 76.65 | 12.77 |
| Stop-Loss (sl) | 94 | 183.48 | 1.95 |
| Take-Profit (tp) | 2 | 328.48 | 164.24 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2023 | -180.99 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2023.07 | -188.61 | -188.61 |
| 2023.08 | -150.23 | -338.84 |
| 2023.09 | -94.21 | -433.05 |
| 2023.10 | -114.53 | -547.58 |
| 2023.11 | -96.02 | -643.60 |
| 2023.12 | 462.61 | -180.99 |

## 🔎 关键观察
- 最佳月份: **2023.12** (462.61 USD)
- 最差月份: **2023.07** (-188.61 USD)  ← 重点优化时间窗口
- 亏损月份数: 5 / 6
- 余额最大回撤: 763.11 (25.08%) | 净值最大回撤: 773.50 (25.19%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码