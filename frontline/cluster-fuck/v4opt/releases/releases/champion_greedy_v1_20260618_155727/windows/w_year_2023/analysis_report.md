# 📊 MT5 回测增强分析报告 — champion defaults cold-start w_year_2023

**生成时间:** 2026-06-18 16:25:28

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | main |
| Symbol | EURUSD |
| Period | H1 (2023.01.01 - 2023.12.31) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 336.71 |
| Gross Profit | 8 727.05 |
| Gross Loss | -8 390.34 |
| Profit Factor | 1.04 |
| Expected Payoff | 0.46 |
| Recovery Factor | 0.15 |
| Sharpe Ratio | 0.33 |
| Balance Drawdown Maximal | 1 449.41 (35.02%) |
| Equity Drawdown Maximal | 2 238.47 (45.65%) |
| Balance Drawdown Relative | 35.02% (1 449.41) |
| Equity Drawdown Relative | 45.65% (2 238.47) |
| Total Trades | 725 |
| Short Trades (won %) | 299 (39.80%) |
| Long Trades (won %) | 426 (43.66%) |
| Profit Trades (% of total) | 305 (42.07%) |
| Loss Trades (% of total) | 420 (57.93%) |
| Largest profit trade | 471.16 |
| Largest loss trade | -456.98 |
| Average profit trade | 28.61 |
| Average loss trade | -19.53 |
| Maximum consecutive wins ($) | 7 (204.10) |
| Maximum consecutive losses ($) | 12 (-112.89) |
| Average position holding time | 9:53:55 |
| Maximal position holding time | 304:58:58 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 473 | -2,261.48 | -4.78 |
| end | 6 | 104.54 | 17.42 |
| Stop-Loss (sl) | 239 | 1,001.92 | 4.19 |
| Take-Profit (tp) | 7 | 1,680.56 | 240.08 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2023 | 336.71 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2023.01 | -96.56 | -96.56 |
| 2023.02 | -296.70 | -393.26 |
| 2023.03 | 1,484.62 | 1,091.36 |
| 2023.04 | -309.53 | 781.83 |
| 2023.05 | -118.14 | 663.69 |
| 2023.06 | -199.49 | 464.20 |
| 2023.07 | -208.01 | 256.19 |
| 2023.08 | -146.88 | 109.31 |
| 2023.09 | -111.49 | -2.18 |
| 2023.10 | -133.05 | -135.23 |
| 2023.11 | -114.30 | -249.53 |
| 2023.12 | 586.24 | 336.71 |

## 🔎 关键观察
- 最佳月份: **2023.03** (1,484.62 USD)
- 最差月份: **2023.04** (-309.53 USD)  ← 重点优化时间窗口
- 亏损月份数: 10 / 12
- 余额最大回撤: 1 449.41 (35.02%) | 净值最大回撤: 2 238.47 (45.65%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码