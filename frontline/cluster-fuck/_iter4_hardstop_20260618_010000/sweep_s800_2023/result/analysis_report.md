# 📊 MT5 回测增强分析报告 — sweep 800 2023

**生成时间:** 2026-06-18 01:04:54

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
| Total Net Profit | -628.47 |
| Gross Profit | 378.95 |
| Gross Loss | -1 007.42 |
| Profit Factor | 0.38 |
| Expected Payoff | -3.38 |
| Recovery Factor | -0.68 |
| Sharpe Ratio | -5.00 |
| Balance Drawdown Maximal | 896.79 (27.73%) |
| Equity Drawdown Maximal | 920.06 (28.45%) |
| Balance Drawdown Relative | 27.73% (896.79) |
| Equity Drawdown Relative | 28.45% (920.06) |
| Total Trades | 186 |
| Short Trades (won %) | 69 (81.16%) |
| Long Trades (won %) | 117 (82.91%) |
| Profit Trades (% of total) | 153 (82.26%) |
| Loss Trades (% of total) | 33 (17.74%) |
| Largest profit trade | 35.73 |
| Largest loss trade | -815.79 |
| Average profit trade | 2.48 |
| Average loss trade | -29.73 |
| Maximum consecutive wins ($) | 27 (108.48) |
| Maximum consecutive losses ($) | 2 (-816.02) |
| Average position holding time | 1:35:54 |
| Maximal position holding time | 38:27:54 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 4 | -974.71 | -243.68 |
| Stop-Loss (sl) | 182 | 372.70 | 2.05 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2023 | -628.47 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2023.01 | 20.76 | 20.76 |
| 2023.02 | 29.77 | 50.53 |
| 2023.03 | 108.14 | 158.67 |
| 2023.04 | 64.15 | 222.82 |
| 2023.05 | -122.40 | 100.42 |
| 2023.09 | 24.93 | 125.35 |
| 2023.10 | 8.58 | 133.93 |
| 2023.11 | 16.66 | 150.59 |
| 2023.12 | -779.06 | -628.47 |

## 🔎 关键观察
- 最佳月份: **2023.03** (108.14 USD)
- 最差月份: **2023.12** (-779.06 USD)  ← 重点优化时间窗口
- 亏损月份数: 2 / 9
- 余额最大回撤: 896.79 (27.73%) | 净值最大回撤: 920.06 (28.45%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码