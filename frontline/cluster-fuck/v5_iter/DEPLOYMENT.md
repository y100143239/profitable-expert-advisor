# UnitedEA v4.11 部署运行指南（推荐版：champion_lowsize025_are.set）

> 最优版本：**0.25 仓位缩放 + 反追单(Anti-Reentry 1.0×ATR) + 熔断保持开启**
> 回测（IC Markets Global / ICMarketsSC-MT5-6，真实 Tick Model=4，$3000）：
> - 2026（震荡/实盘同期）：净利 **+1,475** / 净值回撤 **12.1%** / Sharpe 2.12
> - 2024（趋势年）：净利 +1,053 / 净值回撤 7.9% / Sharpe 2.34
> - 对比原冠军(1.5 仓位)：+438 / 回撤 52.1% / Sharpe 0.35 —— **净利 3.4 倍，回撤 52%→12%**

代码仓库：`github.com/y100143239/profitable-expert-advisor`（分支 master）
本地路径：`...\profitable-expert-advisor\frontline\cluster-fuck\v5_iter\`

---

## 1. 获取代码
```powershell
cd "C:\Users\82204\AppData\Roaming\MetaQuotes\Terminal\D3027A7456F1BED80051EF2A0D0DD331\MQL5\Experts\Advisors\y100143239\profitable-expert-advisor"
git pull origin master
```

## 2. 编译 EA（v4.11）
`.ex5` 未入库（属编译产物），需本地编译源码：
```powershell
& "C:\Program Files\MetaTrader 5 IC Markets EU\MetaEditor64.exe" /compile:"frontline\cluster-fuck\v5_iter\ea\main.mq5" /log:"compile.log"
```
预期：`0 errors, 1 warnings`，生成 `v5_iter\ea\main.ex5`。
（或在 MetaEditor 打开 `main.mq5` 按 F7。）

## 3. 终端准备（登录 IC Markets Global 实盘）
- 确认「市场报价」含以下品种（EA 通过 BrokerSymbolMapper 自动映射名称）：
  `EURUSD, AUDUSD, XAUUSD, BTCUSD, AAPL.NAS, NVDA.NAS, TSLA.NAS, DE40, SOXX.NAS, XTIUSD, XBRUSD, XNGUSD`
- 导航器 → 智能交易 → `Advisors\…\v5_iter\ea\main` → 拖到 **EURUSD H1** 图表
  （EA 内部自管全部品种，只需挂 1 个图表）。

## 4. 加载推荐参数
- EA 弹窗 →「输入参数」标签 →「加载」→ 选择：
  `frontline\cluster-fuck\v5_iter\champion_lowsize025_are.set`
- 关键参数（该 set 已设定）：
  - `URF_BaseScale = 0.25`（关键：解决过度杠杆，切勿调高）
  - `GRM_LossHaltEnable = true`（熔断保持开启——实测关闭会更差）
  - `ARE_Enable = true` / `ARE_MinAdverseATRMult = 1.0` / `ARE_LookbackBars = 24`（反追单）
- 「常用」标签 → 勾选「允许算法交易」。

## 5. 启动与核验
- 打开终端顶部「算法交易」按钮。
- 「智能交易/日志」应出现：`[UnitedEA] BUILD 4.11-dev | version 4.11`（确认版本正确）。

---

## 可选预设
| 预设 | 说明 | 2026 净利 / 净值回撤 |
|---|---|---|
| **champion_lowsize025_are.set** | 推荐（缩放+反追单） | +1,475 / 12.1% |
| champion_lowsize025.set | 仅缩放（最简单） | +1,243 / 16.1% |
| champion_lowsize025_ptp.set | 缩放+分批止盈(opt-in) | +1,227 / 14.3% |

## 注意事项
- 验证条件：$3000 入金、Model=4 真实 Tick、杠杆 1:1000。
- `URF_BaseScale=0.25` 是降回撤的核心，请勿调回 1.5。
- 分批止盈(PTP)可用但**不要开启移动到保本(MoveToBreakeven)**——实测会把净利腰斩。
- 上实盘前建议先在模拟盘或小额实盘跑一段，确认实盘行为与回测一致。
