# 📊 MT5 回测增强分析报告 — iter4 window 2026H1

**生成时间:** 2026-06-18 01:03:28

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
| Total Net Profit | 658.00 |
| Gross Profit | 4 140.49 |
| Gross Loss | -3 482.49 |
| Profit Factor | 1.19 |
| Expected Payoff | 0.50 |
| Recovery Factor | 0.71 |
| Sharpe Ratio | 2.82 |
| Balance Drawdown Maximal | 790.96 (19.82%) |
| Equity Drawdown Maximal | 931.01 (23.29%) |
| Balance Drawdown Relative | 19.82% (790.96) |
| Equity Drawdown Relative | 23.29% (931.01) |
| Total Trades | 1309 |
| Short Trades (won %) | 700 (75.00%) |
| Long Trades (won %) | 609 (78.49%) |
| Profit Trades (% of total) | 1003 (76.62%) |
| Loss Trades (% of total) | 306 (23.38%) |
| Largest profit trade | 358.82 |
| Largest loss trade | -583.34 |
| Average profit trade | 4.13 |
| Average loss trade | -10.97 |
| Maximum consecutive wins ($) | 19 (100.52) |
| Maximum consecutive losses ($) | 3 (-87.15) |
| Average position holding time | 0:18:39 |
| Maximal position holding time | 37:58:07 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 39 | -2,443.23 | -62.65 |
| Stop-Loss (sl) | 1270 | 3,227.82 | 2.54 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2026 | 658.00 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2026.01 | 466.72 | 466.72 |
| 2026.02 | 401.39 | 868.11 |
| 2026.03 | -532.27 | 335.84 |
| 2026.04 | -23.51 | 312.33 |
| 2026.05 | 108.45 | 420.78 |
| 2026.06 | 237.22 | 658.00 |

## 🔎 关键观察
- 最佳月份: **2026.01** (466.72 USD)
- 最差月份: **2026.03** (-532.27 USD)  ← 重点优化时间窗口
- 亏损月份数: 2 / 6
- 余额最大回撤: 790.96 (19.82%) | 净值最大回撤: 931.01 (23.29%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码