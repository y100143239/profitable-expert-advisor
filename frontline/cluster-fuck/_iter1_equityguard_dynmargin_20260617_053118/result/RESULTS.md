# Iter1 回测结果：Equity Guard + Dynamic Margin（两特性同时开启）

**结论：回归（REGRESSION）— 放弃此组合，进入消融测试**

## 核心指标 vs 基准
| 指标 | 基准 | Iter1 | 变化 |
|---|---|---|---|
| 净利润 | +8,273.80 | **-1,167.83** | ❌ -9,441 |
| 利润因子 | 1.73 | **0.81** | ❌ -0.92 |
| 胜率 | 77.85% | 77.53% | ≈ -0.32pp |
| 余额回撤 | 10.41% | **68.02%** | ❌ +57.6pp |
| 净值回撤 | 45.79% | **69.01%** | ❌ +23.2pp |
| 总交易 | ~5566 | 3529 | -2037 |

## 根因分析（资金曲线图）
资金曲线显示多个**垂直悬崖式下跌**——这些是 equity protection 电路断路器在浮亏达 -18% 时
强制平掉所有头寸的瞬间。但该 martingale 策略的盈利**依赖于扛过浮亏**，由反向加仓
(reverseLotSizeMultiplier) 在回调时盈利退出。强制平仓把**可恢复的浮亏锁定成已实现亏损**，
彻底破坏了策略的恢复机制。

此外 dynamic margin 在 equity>balance 时放大手数，进一步加剧波动幅度。

## 离场分布
- Signal/Trailing/Time exit: 102 笔，**-5,668.96**（平均 -55.58）← 电路断路器强平产生的巨亏
- Stop-Loss: 3427 笔，+4,758.02（平均 +1.39）← 正常止损仍健康

## 决策
1. ❌ 放弃"close-all 电路断路器"——对此策略有害
2. → 消融测试：iter1.1 仅 equity protection、iter1.2 仅 dynamic margin，隔离各自影响
3. → iter2 改用**软保护**：高浮亏时仅暂停新开仓（不强平），让反向加仓自然恢复

## 附件
- iter1_ReportTester.html / .png（资金曲线）/ -holding.png / -hst.png / -mfemae.png
- deals.csv (7059 行) / summary.csv / analysis_report.md
- baseline.mq5（本次源码）/ config.ini（本次参数）
