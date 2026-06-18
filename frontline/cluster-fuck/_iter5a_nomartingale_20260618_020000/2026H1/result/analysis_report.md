# 📊 MT5 回测增强分析报告 — iter5a nomart 2026H1

**生成时间:** 2026-06-18 01:44:51

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | ea |
| Symbol | XAUUSD |
| Period | H1 (2026.01.01 - 2026.06.17) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 121.03 |
| Gross Profit | 2 984.58 |
| Gross Loss | -2 863.55 |
| Profit Factor | 1.04 |
| Expected Payoff | 0.09 |
| Recovery Factor | 0.18 |
| Sharpe Ratio | 0.68 |
| Balance Drawdown Maximal | 650.47 (19.63%) |
| Equity Drawdown Maximal | 673.41 (20.31%) |
| Balance Drawdown Relative | 19.63% (650.47) |
| Equity Drawdown Relative | 20.31% (673.41) |
| Total Trades | 1282 |
| Short Trades (won %) | 656 (71.65%) |
| Long Trades (won %) | 626 (77.48%) |
| Profit Trades (% of total) | 955 (74.49%) |
| Loss Trades (% of total) | 327 (25.51%) |
| Largest profit trade | 98.67 |
| Largest loss trade | -261.73 |
| Average profit trade | 3.13 |
| Average loss trade | -8.48 |
| Maximum consecutive wins ($) | 14 (30.10) |
| Maximum consecutive losses ($) | 5 (-1.93) |
| Average position holding time | 0:18:40 |
| Maximal position holding time | 23:37:10 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 39 | -2,467.68 | -63.27 |
| Stop-Loss (sl) | 1243 | 2,678.45 | 2.15 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2026 | 121.03 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2026.01 | 110.17 | 110.17 |
| 2026.02 | 15.19 | 125.36 |
| 2026.03 | 29.74 | 155.10 |
| 2026.04 | -298.29 | -143.19 |
| 2026.05 | 4.16 | -139.03 |
| 2026.06 | 260.06 | 121.03 |

## 🔎 关键观察
- 最佳月份: **2026.06** (260.06 USD)
- 最差月份: **2026.04** (-298.29 USD)  ← 重点优化时间窗口
- 亏损月份数: 1 / 6
- 余额最大回撤: 650.47 (19.63%) | 净值最大回撤: 673.41 (20.31%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码