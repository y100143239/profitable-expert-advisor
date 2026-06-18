# 📊 MT5 回测增强分析报告 — champion defaults cold-start w_h2_2024

**生成时间:** 2026-06-18 16:57:51

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | main |
| Symbol | EURUSD |
| Period | H1 (2024.07.01 - 2024.12.31) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 1 828.80 |
| Gross Profit | 8 782.45 |
| Gross Loss | -6 953.65 |
| Profit Factor | 1.26 |
| Expected Payoff | 3.62 |
| Recovery Factor | 0.67 |
| Sharpe Ratio | 2.42 |
| Balance Drawdown Maximal | 2 693.92 (35.81%) |
| Equity Drawdown Maximal | 2 744.97 (36.29%) |
| Balance Drawdown Relative | 35.81% (2 693.92) |
| Equity Drawdown Relative | 36.29% (2 744.97) |
| Total Trades | 505 |
| Short Trades (won %) | 176 (36.93%) |
| Long Trades (won %) | 329 (42.86%) |
| Profit Trades (% of total) | 206 (40.79%) |
| Loss Trades (% of total) | 299 (59.21%) |
| Largest profit trade | 861.44 |
| Largest loss trade | -564.97 |
| Average profit trade | 42.63 |
| Average loss trade | -22.77 |
| Maximum consecutive wins ($) | 6 (713.58) |
| Maximum consecutive losses ($) | 10 (-189.85) |
| Average position holding time | 5:01:35 |
| Maximal position holding time | 172:00:00 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 311 | -1,226.22 | -3.94 |
| Stop-Loss (sl) | 188 | 738.10 | 3.93 |
| Take-Profit (tp) | 6 | 2,461.54 | 410.26 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2024 | 1,828.80 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2024.07 | 1,901.95 | 1,901.95 |
| 2024.08 | 1,048.15 | 2,950.10 |
| 2024.09 | -174.21 | 2,775.89 |
| 2024.10 | -282.89 | 2,493.00 |
| 2024.11 | -517.41 | 1,975.59 |
| 2024.12 | -146.79 | 1,828.80 |

## 🔎 关键观察
- 最佳月份: **2024.07** (1,901.95 USD)
- 最差月份: **2024.11** (-517.41 USD)  ← 重点优化时间窗口
- 亏损月份数: 4 / 6
- 余额最大回撤: 2 693.92 (35.81%) | 净值最大回撤: 2 744.97 (36.29%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码