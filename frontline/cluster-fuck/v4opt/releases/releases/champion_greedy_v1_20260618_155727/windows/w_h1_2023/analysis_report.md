# 📊 MT5 回测增强分析报告 — champion defaults cold-start w_h1_2023

**生成时间:** 2026-06-18 16:48:23

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | main |
| Symbol | EURUSD |
| Period | H1 (2023.01.01 - 2023.06.30) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 464.20 |
| Gross Profit | 5 981.73 |
| Gross Loss | -5 517.53 |
| Profit Factor | 1.08 |
| Expected Payoff | 1.09 |
| Recovery Factor | 0.29 |
| Sharpe Ratio | 0.76 |
| Balance Drawdown Maximal | 888.83 (25.78%) |
| Equity Drawdown Maximal | 1 584.53 (32.31%) |
| Balance Drawdown Relative | 25.78% (888.83) |
| Equity Drawdown Relative | 32.31% (1 584.53) |
| Total Trades | 427 |
| Short Trades (won %) | 173 (38.73%) |
| Long Trades (won %) | 254 (48.03%) |
| Profit Trades (% of total) | 189 (44.26%) |
| Loss Trades (% of total) | 238 (55.74%) |
| Largest profit trade | 471.16 |
| Largest loss trade | -456.98 |
| Average profit trade | 31.65 |
| Average loss trade | -22.65 |
| Maximum consecutive wins ($) | 7 (204.10) |
| Maximum consecutive losses ($) | 10 (-100.01) |
| Average position holding time | 9:09:46 |
| Maximal position holding time | 174:00:00 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 277 | -1,476.89 | -5.33 |
| Stop-Loss (sl) | 145 | 788.43 | 5.44 |
| Take-Profit (tp) | 5 | 1,279.21 | 255.84 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2023 | 464.20 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2023.01 | -96.56 | -96.56 |
| 2023.02 | -296.70 | -393.26 |
| 2023.03 | 1,484.62 | 1,091.36 |
| 2023.04 | -309.53 | 781.83 |
| 2023.05 | -118.14 | 663.69 |
| 2023.06 | -199.49 | 464.20 |

## 🔎 关键观察
- 最佳月份: **2023.03** (1,484.62 USD)
- 最差月份: **2023.04** (-309.53 USD)  ← 重点优化时间窗口
- 亏损月份数: 5 / 6
- 余额最大回撤: 888.83 (25.78%) | 净值最大回撤: 1 584.53 (32.31%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码