# 📊 MT5 回测增强分析报告 — stability sm_y2026h

**生成时间:** 2026-06-19 21:51:56

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | main |
| Symbol | EURUSD |
| Period | H1 (2026.01.01 - 2026.06.19) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 1 895.54 |
| Gross Profit | 10 955.58 |
| Gross Loss | -9 060.04 |
| Profit Factor | 1.21 |
| Expected Payoff | 4.69 |
| Recovery Factor | 0.90 |
| Sharpe Ratio | 2.08 |
| Balance Drawdown Maximal | 1 861.63 (34.21%) |
| Equity Drawdown Maximal | 2 105.93 (37.11%) |
| Balance Drawdown Relative | 34.21% (1 861.63) |
| Equity Drawdown Relative | 37.11% (2 105.93) |
| Total Trades | 404 |
| Short Trades (won %) | 31 (22.58%) |
| Long Trades (won %) | 373 (47.99%) |
| Profit Trades (% of total) | 186 (46.04%) |
| Loss Trades (% of total) | 218 (53.96%) |
| Largest profit trade | 924.00 |
| Largest loss trade | -760.11 |
| Average profit trade | 58.90 |
| Average loss trade | -41.14 |
| Maximum consecutive wins ($) | 7 (511.30) |
| Maximum consecutive losses ($) | 8 (-811.63) |
| Average position holding time | 6:01:39 |
| Maximal position holding time | 235:00:00 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 159 | -1,283.49 | -8.07 |
| Take-Profit (tp) | 8 | 994.43 | 124.30 |
| Stop-Loss (sl) | 237 | 2,275.76 | 9.60 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2026 | 1,895.54 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2026.01 | 1,237.00 | 1,237.00 |
| 2026.02 | -263.30 | 973.70 |
| 2026.03 | -306.54 | 667.16 |
| 2026.04 | 1,712.46 | 2,379.62 |
| 2026.05 | -219.87 | 2,159.75 |
| 2026.06 | -264.21 | 1,895.54 |

## 🔎 关键观察
- 最佳月份: **2026.04** (1,712.46 USD)
- 最差月份: **2026.03** (-306.54 USD)  ← 重点优化时间窗口
- 亏损月份数: 4 / 6
- 余额最大回撤: 1 861.63 (34.21%) | 净值最大回撤: 2 105.93 (37.11%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码