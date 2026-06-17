# 📊 MT5 回测增强分析报告 — Champion revLot9 2025 THIRD run variance check

**生成时间:** 2026-06-17 07:45:32

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | EMACrossOver_V4 |
| Symbol | XAUUSD |
| Period | H1 (2025.01.01 - 2025.12.31) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 418.32 |
| Gross Profit | 3 024.04 |
| Gross Loss | -2 605.72 |
| Profit Factor | 1.16 |
| Expected Payoff | 0.29 |
| Recovery Factor | 0.57 |
| Sharpe Ratio | 1.35 |
| Balance Drawdown Maximal | 543.12 (15.15%) |
| Equity Drawdown Maximal | 735.55 (21.03%) |
| Balance Drawdown Relative | 15.15% (543.12) |
| Equity Drawdown Relative | 21.03% (735.55) |
| Total Trades | 1441 |
| Short Trades (won %) | 612 (76.14%) |
| Long Trades (won %) | 829 (80.34%) |
| Profit Trades (% of total) | 1132 (78.56%) |
| Loss Trades (% of total) | 309 (21.44%) |
| Largest profit trade | 78.21 |
| Largest loss trade | -161.87 |
| Average profit trade | 2.67 |
| Average loss trade | -7.94 |
| Maximum consecutive wins ($) | 25 (49.51) |
| Maximum consecutive losses ($) | 4 (-162.44) |
| Average position holding time | 0:28:12 |
| Maximal position holding time | 26:16:55 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 38 | -2,251.31 | -59.24 |
| Stop-Loss (sl) | 1403 | 2,822.58 | 2.01 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2025 | 418.32 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2025.01 | -23.14 | -23.14 |
| 2025.02 | 118.86 | 95.72 |
| 2025.03 | 59.43 | 155.15 |
| 2025.04 | -39.05 | 116.10 |
| 2025.05 | 121.60 | 237.70 |
| 2025.06 | 18.36 | 256.06 |
| 2025.07 | 8.76 | 264.82 |
| 2025.08 | 41.38 | 306.20 |
| 2025.09 | 95.53 | 401.73 |
| 2025.10 | -111.33 | 290.40 |
| 2025.11 | -145.82 | 144.58 |
| 2025.12 | 273.74 | 418.32 |

## 🔎 关键观察
- 最佳月份: **2025.12** (273.74 USD)
- 最差月份: **2025.11** (-145.82 USD)  ← 重点优化时间窗口
- 亏损月份数: 4 / 12
- 余额最大回撤: 543.12 (15.15%) | 净值最大回撤: 735.55 (21.03%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码