# Champion Final 交付版（2026-07-31）

分支：`feature/v2-daveteaches-iter` ｜ 基线：V2 Champion（真源码 `eefb181`）

## 两个一键预设（任选其一加载）

| 预设 | 适用 | 全周期真实 Tick（2023–2026, Model=4, 复利, Deposit 3000 / Leverage 1000） |
|---|---|---|
| **`champion.set`** | 最大收益 | NP +102,032 / 净值回撤 30.70% / PF 1.44；单笔亏损**无上限** |
| **`champion_livesafe.set`**（推荐实盘） | 带单笔巨额亏损硬风控 | NP **+109,877** / 净值回撤 **29.54%** / PF 1.43；每笔亏损**锁定 ≤ 净值 8%** |

> 两者共用同一 `main.ex5`。livesafe 只多开了两个已有风控开关（下详），在全周期真实 Tick 上收益略高、
> 回撤略低，**且把任何单笔亏损硬性锁定在净值的 8%** —— 直接解决“单笔巨额亏损无风控”。

## 单笔巨额亏损风控（livesafe 预设已启用）

| 开关 | 默认（livesafe） | 说明 |
|---|---|---|
| `PM_Enable` | true | 开启逐仓硬性止损 |
| `PM_MaxPositionLossPct` | 8.0 | 任一持仓浮亏达到净值的 8% 立即平仓（随账户缩放） |
| `PM_MaxPositionLossUSD` | 0 | 可改为绝对金额封顶，如 50 = “单笔最多亏 50 美元” |
| `PG_Enable` | true | 本金保护：净值低于本金时逐步降仓 |

调紧（如 PM 5%）会更安全但短窗口易频繁止损（churn）；PM 8% 是全周期最优点。小账户/保守可用
`PM_MaxPositionLossUSD` 设硬封顶。

## 关键证据：全周期真实 Tick（Model=4，复利）

| 配置 | 净利润 | 余额回撤 | 净值回撤 | 盈利因子 | 交易数 |
|---|---|---|---|---|---|
| **champion.set** | +102,032 | 16.28% | 30.70% | 1.44 | 3469 |
| **champion_livesafe.set** | **+109,877** | 16.22% | **29.54%** | 1.43 | 3912 |
| 试验版 V3（去MU+EAS+VRP） | +20,633 | 69.41% | 79.12% | 1.13 | 4298 |

> 教训：**分年度回测（每年重置本金）会掩盖复利放大后的风险**，必须用全周期复利真实 Tick 验证。
> 试验版 V3 失败原因：VRP 在复利账户不断在亏损月尝试恢复 + 余额放大仓位 → 回撤放大到 ~79%；
> 移除 MU.NAS 触发手数再平衡把风险集中到其他品种。

### 关于 MU.NAS 的“Model=1 幻觉”
- Model=1（1 分钟 OHLC）全周期里 MU.NAS 贡献 +59,404（占总利润 34%），但这是**假象**：MU.NAS 是超短线
  剥头皮，Model=1 无法体现每笔成交的点差/滑点。真实 Tick / 实盘里 MU.NAS 表现差得多（实盘 MU 亏 -$2,429）。
- 但全周期真实 Tick 里，保留 MU.NAS 的原冠军整体仍优于移除它的版本 => 不单独动 MU.NAS。

## 关于回撤的诚实说明

- 已系统测试 ~12 种回撤/灾难风控（逐仓封顶、连败冷却、开仓止损、时间止损、VRP、去 MU、入场 SL、
  DD 降仓、杠杆/净值门控…）：除 PM 外，均在**全周期真实 Tick**上使结果变差。
- 根因：子策略是**均值回归**——回撤后跟着反弹；在回撤中降仓/止损会错过反弹，这正是其盈利来源。
- 因此 ~30% 净值回撤、以及 2023 类震荡期入场的本金回撤，是**结构性**的，无法在不摧毁优势的前提下消除。
- 真正能降低你**体感回撤**的只有：（a）降低 `URF_BaseScale`（整体缩小）；（b）定期提取利润、不复利。

## 目录内容

```
champion_final_20260730/
├── main.ex5                # 已编译（0 errors；1 个既有 Williams 类型转换 warning）；两个预设共用
├── champion.set            # 一键：最大收益（= 原 V2 Champion）
├── champion_livesafe.set   # 一键：带单笔硬风控（PM 8% + 本金保护，推荐实盘）
├── README.md
└── src/                    # 全部源码（含 Williams D1 EMA live-safety 修复）
    ├── main.mq5
    ├── BrokerSymbolMapper.mqh
    ├── MagicNumberHelpers.mqh
    └── Strategies/*.mqh
```

## 相对原始冠军源码保留的改进

- **WilliamsPassivation D1 EMA 稳定性修复（模型无关，已默认生效）**：原代码在 `CopyBuffer D1 EMA failed`
  时直接 `return` 使策略失效；现改为重建句柄 + forming-bar 回退，避免运行一段时间后策略“卡死”。
  回测中性（不改变回测结果），但显著提升实盘稳健性。

## 如何运行（一键）

1. 将 `main.ex5` 放入 MT5 `MQL5\Experts\`（或用 `src\main.mq5` 重新编译）。
2. EA 挂到 EURUSD 图表；参数窗 **Load** 选择一个预设：
   - 追求收益 → `champion.set`
   - 实盘推荐（带单笔硬风控）→ `champion_livesafe.set`
3. 环境：Deposit 3000、Leverage 1000、Model=4（真实 Tick）。EA 内部自管多品种多子策略，无需为每个品种单独挂载。

重新编译（本地 Win11）：
```
"C:\Program Files\MetaTrader 5 IC Markets EU\MetaEditor64.exe" /portable /compile:"src\main.mq5" /log:build.log
```
