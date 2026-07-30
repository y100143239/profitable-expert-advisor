# Champion V3 — no-MU + EAS + VRP （最终交付版）

发布日期：2026-07-30
分支：`feature/v2-daveteaches-iter`
基线：V2 Champion（真源码 `eefb181`）

本版本在 V2 Champion 基础上做了三项经实盘问题驱动、并在 **Model=4 真实 Tick** 上验证的改动，
显著提升收益并把回撤减半。所有改动均为“开关式”（默认与冠军一致），本发布的 `.set` 已把最优组合设为一键默认。

---

## 一、相对原冠军的改动（一键默认已启用）

| 改动 | 参数 | 作用 |
|---|---|---|
| 移除有毒子策略 MU.NAS | `EnableRSIScalpingMU=false` | MU.NAS 在真实 Tick 上是净亏损（实盘对应你的 -\$2,429 亏损） |
| 开仓即错·实时止损 (EAS) | `EAS_Enable=true` `EAS_WindowMinutes=30` `EAS_AdverseATRMult=1.0` | 开仓后 30 分钟内若逆向浮亏达到 1×日线 ATR，判定为“开仓即错”，立即平仓，不再扛单 |
| 智能月度恢复 (VRP) | `VRP_Enable=true` | 触发月度亏损锁后，用影子交易探测市场；仅当模拟胜率≥55%（8 笔）确认恢复才恢复真实交易 |

说明：
- **EAS（Early Adverse Stop）** 是一个“灾难熔断”：阈值为 1×日线 ATR，只在真正剧烈的错误进场时触发。
  在剧烈行情年份（2026）大量触发、显著止损；在平静年份（2025）零触发、零副作用。
- **VRP（Virtual Recovery Probe）** 是对“达到亏损阈值后强制停整月过于严苛”的正确解法：
  硬锁仍保留（`GRM_MonthlyLossCooldownHours=0`），但 VRP 在锁定期用影子交易判断市场是否恢复，
  只有确认恢复才恢复真实下单——既利用了恢复时间，又避免了盲目恢复导致的连续亏损。
  - 对比：盲目冷却恢复（`GRM_MonthlyLossCooldownHours=72`）在真实 Tick 上是灾难（NP 由 +2407 变 -553，回撤翻倍），**不要使用**。

---

## 二、多时间窗口稳定性回测（Model=4 真实 Tick，EURUSD 图表挂载，Deposit 3000 / Leverage 1000）

| 窗口 | 净利润 | 余额回撤 | 净值回撤 | 盈利因子 | 交易数 |
|---|---|---|---|---|---|
| 2023 全年 | +489 | 36.39% | 38.92% | 1.08 | 1253 |
| 2024 全年 | +3,778 | 9.94% | 14.38% | 1.48 | 1117 |
| 2025 全年 | +8,268 | 30.95% | 34.46% | 1.28 | 1249 |
| 2026 (1/1–7/29) | +3,123 | 19.27% | 26.02% | 1.32 | 692 |

- 四个年度窗口 **全部盈利**，盈利因子 1.08–1.48；2023 为最弱窗口（边际优势较薄、回撤较高）。
- 相对原冠军（2026 真实 Tick）：净利润 **845 → 3,123（+270%）**，净值回撤 **50.9% → 26.0%（减半）**，盈利因子 **1.06 → 1.32**。

---

## 三、目录内容

```
champion_v3_eas_vrp_20260730/
├── main.ex5              # 已编译（0 errors；含 1 个既有 Williams 类型转换 warning，无影响）
├── champion_v3.set       # 一键最优参数（no-MU + EAS + VRP），直接在策略测试器/图表加载即可
├── README.md             # 本说明
└── src/                  # 全部最新源码
    ├── main.mq5
    ├── BrokerSymbolMapper.mqh
    ├── MagicNumberHelpers.mqh
    └── Strategies/*.mqh
```

---

## 四、如何运行（一键）

1. 将 `main.ex5` 放入 MT5 的 `MQL5\Experts\` 目录（或用 `src\main.mq5` 在 MetaEditor 中重新编译）。
2. 在策略测试器或图表中挂载 EA，加载 `champion_v3.set`（Load）。
3. 建议测试/运行环境：EURUSD 图表挂载、Deposit 3000、Leverage 1000、Model=4（真实 Tick）。
   EA 内部自行管理多品种的多子策略，无需为每个品种单独挂载。

重新编译命令（本地 Win11）：
```
"C:\Program Files\MetaTrader 5 IC Markets EU\MetaEditor64.exe" /portable /compile:"src\main.mq5" /log:build.log
```

---

## 五、可选调参（默认已是最优，如需微调）

| 参数 | 默认 | 说明 |
|---|---|---|
| `EAS_AdverseATRMult` | 1.0 | 调低（如 0.5）会更早止损但会“误杀”可回归仓位（实测 0.5 比 1.0 差），建议保持 1.0 |
| `EAS_WindowMinutes` | 30 | 判定“开仓即错”的时间窗 |
| `VRP_ResumeWinRate` | 0.55 | 恢复真实交易所需的影子胜率门槛，越高越保守 |
| `VRP_ProbeTrades` | 8 | 判定恢复所需的影子交易样本数 |
| `URF_LeverageAwareEnable` | false | 按品种实时保证金归一化仓位（防爆仓）。实测大幅降回撤但也压低收益，默认关闭，可按需开启 |
| `URF_EquityGateEnable` | false | 仅在净值≥余额时放大仓位、净值<余额时收缩。默认关闭的纯安全档 |

---

## 六、未采纳项（已验证，供参考）

- **新增 USDJPY**（挂入 Williams 品种篮子）：真实 Tick 上 USDJPY 为净亏损（-71.50，10 笔仅 1 胜），
  拖累整体表现，故未纳入。若需要，可考虑为 USDJPY 单独接入亚洲时段反转子策略（需新增输入并重新验证）。
- **盲目月度冷却恢复**（`GRM_MonthlyLossCooldownHours>0`）：真实 Tick 上灾难性（-553 / 回撤翻倍），已用 VRP 替代。
