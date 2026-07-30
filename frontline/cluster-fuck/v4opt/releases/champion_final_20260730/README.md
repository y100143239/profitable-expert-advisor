# Champion Final 交付版（2026-07-30）

分支：`feature/v2-daveteaches-iter` ｜ 基线：V2 Champion（真源码 `eefb181`）

## 结论先行

经过完整的多窗口 + **全周期真实 Tick（Model=4，2023.01.01–2026.07.29，复利）** 验证，
**最终交付 = 原 V2 Champion 配置**（`champion.set`）。这是在最贴近实盘的测试下表现最好的配置。

本轮尝试的若干“改动”（移除 MU.NAS、Early Adverse Stop、Virtual Recovery Probe）在**分年度**的
真实 Tick 测试里看似更好，但在**全周期复利**的真实 Tick 测试里**显著变差**，因此**未纳入默认配置**，
仅作为可选开关保留在源码中（默认关闭）。

## 关键证据：全周期真实 Tick（Model=4，复利，Deposit 3000 / Leverage 1000）

| 配置 | 净利润 | 余额回撤 | 净值回撤 | 盈利因子 | 交易数 |
|---|---|---|---|---|---|
| **V2 Champion（本交付）** | **+102,032** | **16.28%** | **30.70%** | **1.44** | 3469 |
| 试验版 V3（去MU+EAS+VRP） | +20,633 | 69.41% | 79.12% | 1.13 | 4298 |
| V2 + EAS | +102,032 | 16.28% | 30.70% | 1.44 | 3469（EAS 全周期不触发，无影响） |

> 教训：**分年度回测（每年重置 3000 本金）会掩盖复利放大后的风险**。必须用全周期复利的真实 Tick 验证。
> 试验版 V3 的问题：VRP 在复利账户上不断在亏损月尝试恢复 + 余额放大仓位 → 回撤被放大到 ~79%；
> 移除 MU.NAS 触发手数再平衡把风险集中到其他品种。二者叠加使全周期表现远逊于原冠军。

### 关于 MU.NAS 的“Model=1 幻觉”
- 在 **Model=1（1 分钟 OHLC）** 全周期回测里，MU.NAS 贡献 **+59,404（占总利润 34%）**——但这是**假象**：
  MU.NAS 是**超短线剥头皮**策略，Model=1 无法体现每笔成交的点差/滑点。
- 在**真实 Tick / 实盘**里 MU.NAS 表现差得多（你的实盘 MU 亏损 -\$2,429 即为此）。
- 但在**全周期复利**的真实 Tick 里，保留 MU.NAS 的原冠军整体仍显著优于移除它的版本（手数再平衡副作用更伤）。
  => 结论：**不单独动 MU.NAS**，保留原冠军的整体平衡。

## 目录内容

```
champion_final_20260730/
├── main.ex5          # 已编译（0 errors；1 个既有 Williams 类型转换 warning）；默认即原冠军配置
├── champion.set      # 一键最优参数（= 原 V2 Champion）
├── README.md
└── src/              # 全部最新源码（含下列 live-safety 修复与可选工具）
    ├── main.mq5
    ├── BrokerSymbolMapper.mqh
    ├── MagicNumberHelpers.mqh
    └── Strategies/*.mqh
```

## 相对原始冠军源码保留的改进

1. **WilliamsPassivation D1 EMA 稳定性修复（模型无关的 live-safety 修复，已默认生效）**
   原代码在 `CopyBuffer D1 EMA failed` 时直接 `return` 使策略失效；现改为重建句柄 + forming-bar 回退，
   避免运行一段时间后策略“卡死”。回测中性（不改变回测结果），但显著提升实盘稳健性。

## 可选工具（源码内置，**默认全部关闭**；经验证不改善全周期真实 Tick，谨慎使用）

| 开关 | 说明 | 全周期真实 Tick 结论 |
|---|---|---|
| `EAS_Enable` | 开仓即错实时止损（首 N 分钟逆行 ≥1×日线ATR 即平仓） | 全周期几乎不触发，无改善；作为极端行情“保险”可选开 |
| `VRP_Enable` | 月度亏损锁的智能恢复（影子交易达标才恢复） | 复利下**放大回撤**，不建议默认开 |
| `SPTE_Enable` | 时间型套牢止损 | 易造成过度平仓，不建议 |
| `URF_LeverageAwareEnable` | 按品种实时保证金归一化仓位 | 压低收益，仅在极度保守时考虑 |
| `URF_EquityGateEnable` | 仅净值≥余额放大仓位 | 纯安全档，收益下降 |

## 如何运行（一键）

1. 将 `main.ex5` 放入 MT5 `MQL5\Experts\`（或用 `src\main.mq5` 重新编译）。
2. EA 挂到 EURUSD 图表；参数窗 **Load** `champion.set`（确保参数正确）。
3. 环境：Deposit 3000、Leverage 1000、Model=4（真实 Tick）。EA 内部自管多品种多子策略。

重新编译：
```
"C:\Program Files\MetaTrader 5 IC Markets EU\MetaEditor64.exe" /portable /compile:"src\main.mq5" /log:build.log
```
