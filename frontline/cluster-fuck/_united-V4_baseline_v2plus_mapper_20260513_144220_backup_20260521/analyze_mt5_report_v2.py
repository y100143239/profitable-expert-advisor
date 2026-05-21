import pandas as pd
from collections import defaultdict
import os
import datetime
import re
import pandas as pd

_MAGIC_SUFFIX_RE = re.compile(r"\s*#M\s*=?\s*\d+\s*$")

def _strip_magic(comment: str) -> str:
    return _MAGIC_SUFFIX_RE.sub("", comment).strip()

def analyze_mt5_deals(file_path):
    print(f"🔄 正在读取并解析文件: {file_path}")
    
    try:
        df = pd.read_csv(file_path)
        df.columns = df.columns.str.strip()
        if 'Time' not in df.columns:
            df = pd.read_csv(file_path, skiprows=1)
            df.columns = df.columns.str.strip()
        if 'Time' not in df.columns:
            print(f"❌ 找不到 'Time' 表头，请检查 CSV 格式。")
            return
    except Exception as e:
        print(f"❌ 读取错误: {e}")
        return
        
    print(f"✅ 数据读取成功！正在执行基因匹配与全成本核算...")
    
    df = df.dropna(subset=['Time'])
    df = df[~df['Type'].astype(str).str.contains('balance', na=False, case=False)]
    
    cols_to_num = ['Profit', 'Swap', 'Commission']
    for col in cols_to_num:
        if col in df.columns:
            df[col] = df[col].astype(str).str.replace('−', '-').str.replace(' ', '')
            df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0.0)
        else:
            df[col] = 0.0
            
    df['Net_Profit'] = df['Profit'] + df['Swap'] + df['Commission']
    
    open_positions = []
    strategy_profits = defaultdict(float)
    
    for idx, row in df.iterrows():
        direction = str(row.get('Direction', '')).strip().lower()
        if direction == 'in':
            open_positions.append(row.to_dict())
        elif direction == 'out':
            out_type = str(row.get('Type', '')).strip().lower()
            match_type = 'buy' if out_type == 'sell' else 'sell'
            
            matched_idx = -1
            for i, pos in enumerate(open_positions):
                if pos['Symbol'] == row['Symbol'] and str(pos['Type']).strip().lower() == match_type:
                    matched_idx = i
                    break
            
            if matched_idx != -1:
                match_in = open_positions.pop(matched_idx)
                strategy_name = str(match_in.get('Comment', '未知策略')).strip()
                strategy_profits[strategy_name] += row['Net_Profit']
            else:
                strategy_profits['强制平仓/未匹配单'] += row['Net_Profit']
                
    mt5_mapping = {
        'SimpleTrendline BUY': 'EnableSimpleTrendline (包含 BTCUSD/XAUUSD/GER40)',
        'SimpleTrendline SELL': 'EnableSimpleTrendline (包含 BTCUSD/XAUUSD/GER40)',
        'United SuperEMA long': 'EnableSuperEMA',
        'United SuperEMA short': 'EnableSuperEMA',
        'RSI Follow': 'EnableRSIMidPointHijack',
        'RSI Reverse': 'EnableRSIMidPointHijack (或 Asian EUR/AUD)',
        'EMA Cross Distance': 'EnableRSIMidPointHijack',
        'RSI Overbought Crossover Sell': 'EnableRSICrossOverReversal',
        'RSI Oversold Crossover Buy': 'EnableRSICrossOverReversal',
        'RSI Scalping Buy': 'EnableRSIScalping (包含 APPL/NVDA/TSLA/XAU/BTC)',
        'RSI Scalping Sell': 'EnableRSIScalping (包含 APPL/NVDA/TSLA/XAU/BTC)',
        'Darvas Box Breakout': 'EnableDarvasBox',
        'EMA Crossover Trade': 'EnableEMASlopeDistance',
        'RSIConsolidation BUY': 'EnableRSIConsolidation',
        'RSIConsolidation SELL': 'EnableRSIConsolidation'
    }

    print("\n🚨 策略真实净盈亏排行榜 & MT5 操作指南 🚨")
    print("=" * 90)
    print(f"{'评级':<4} | {'底层策略订单名 (Comment)':<30} | {'净利润($)':<10} | {'MT5 面板对应开关'}")
    print("-" * 90)
    
    md_lines = []
    md_lines.append(f"# 🚨 MT5 回测增强分析报告 v2.0 🚨\n")
    md_lines.append(f"**全自动诊断生成时间:** {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

    # --- Loading Result Summary (split into Setup/Inputs/Results) ---
    summary_path = os.path.join(os.path.dirname(file_path), "summary.csv")
    if os.path.exists(summary_path):
        try:
            with open(summary_path, "r", encoding="utf-8") as fs:
                raw_lines = [ln.rstrip("\r\n") for ln in fs if ln.strip()]
        except Exception as e:
            raw_lines = []
            md_lines.append(f"_Error loading summary: {e}_\n")

        # Locate section boundaries
        inputs_start = next((i for i, ln in enumerate(raw_lines) if ln.startswith("Inputs:")), None)
        results_start = next((i for i, ln in enumerate(raw_lines) if ln.strip().rstrip(",") == "Results"), None)

        setup_lines = raw_lines[:inputs_start] if inputs_start is not None else raw_lines
        # Account block (Company/Currency/Deposit/Leverage) sits between end-of-inputs and Results
        if inputs_start is not None and results_start is not None:
            inputs_block = raw_lines[inputs_start:results_start]
            # Split trailing account lines out of inputs_block
            account_lines = []
            while inputs_block and inputs_block[-1].split(",", 1)[0].strip() in (
                "Company:", "Currency:", "Initial Deposit:", "Leverage:"):
                account_lines.insert(0, inputs_block.pop())
            results_lines = raw_lines[results_start + 1:]
        else:
            inputs_block, account_lines, results_lines = [], [], []

        def _clean(lines):
            return [ln.replace(",,", ",") for ln in lines]

        # Section 1: Setup overview
        md_lines.append("## 🧾 回测环境与账户设置 (Setup)")
        md_lines.append("```csv")
        md_lines.extend(_clean(setup_lines))
        if account_lines:
            md_lines.extend(_clean(account_lines))
        md_lines.append("```\n")

        # Section 2: EA Inputs (collapsible, long)
        if inputs_block:
            md_lines.append("## ⚙️ EA 默认输入参数 (Inputs)")
            md_lines.append("<details><summary>点击展开完整 Inputs 列表</summary>\n")
            md_lines.append("```ini")
            # Strip leading "Inputs:," prefix line for cleanliness
            cleaned = _clean(inputs_block)
            if cleaned and cleaned[0].startswith("Inputs:"):
                first = cleaned[0].split(",", 1)[1] if "," in cleaned[0] else ""
                cleaned = ([first] if first.strip() else []) + cleaned[1:]
            md_lines.extend(cleaned)
            md_lines.append("```")
            md_lines.append("</details>\n")

        # Section 3: Results summary
        if results_lines:
            md_lines.append("## 📈 核心回测指标总览 (Results)")
            md_lines.append("```csv")
            md_lines.extend(_clean(results_lines))
            md_lines.append("```\n")

    md_lines.append("## 🕵️‍♂️ 独立子策略基因测序表 (策略层净利贡献)")
    md_lines.append("| 评级 | 底层策略订单名 (Comment) | 净利润($) | MT5 面板对应开关 |")
    md_lines.append("|---|---|---|---|")
    
    sorted_profits = sorted(strategy_profits.items(), key=lambda item: item[1])
    action_list = set()
    
    for strategy, profit in sorted_profits:
        lookup_key = _strip_magic(strategy)
        mt5_param = mt5_mapping.get(lookup_key, '未知开关 (需查源码)')
        
        if profit < -50:
            status = "💥斩首"
            action_list.add(mt5_param)
        elif profit < 0:
            status = "⚠️失血"
        elif profit < 50:
            status = "🟢盈利"
        else:
            status = "🏆大腿"
            
        print(f"{status:<4} | {strategy:<30} | {profit:>10.2f} | ⚙️ {mt5_param}")
        md_lines.append(f"| {status} | {strategy} | {profit:.2f} | ⚙️ {mt5_param} |")
        
    print("=" * 90)
    print(f"💰 所有策略总净利润核对: {sum(strategy_profits.values()):.2f} USD\n")
    md_lines.append(f"\n**💰 所有策略总净利润核对:** `{sum(strategy_profits.values()):.2f} USD`\n")
    
    print("🛠️ 【仅手动优化时建议：MT5 傻瓜式斩首执行清单】")
    md_lines.append("## 🛠️ 【仅手动优化时建议：MT5 傻瓜式斩首执行清单】")
    md_lines.append("请回到 MT5 的 'Inputs (输入)' 面板，双击以下开关将其设为 false：\n")
    for action in action_list:
        if "未知" not in action:
            print(f"   ❌ {action} = false")
            md_lines.append(f"- ❌ `{action} = false`")
                
    md_lines.append("\n✅ 关掉这几个碎钞机后，点击 'Start' 重新回测，去见证你的印钞曲线吧！")
    
    dir_name = os.path.dirname(file_path)
    if not dir_name: dir_name = "."
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    md_file = os.path.join(dir_name, f"analysis_report_v2_{timestamp}.md")
    
    with open(md_file, "w", encoding="utf-8") as f:
        f.write("\n".join(md_lines))
    print(f"\n📄 v2 Markdown 分析报告已保存至: {md_file}")

if __name__ == "__main__":
    import sys
    FILE_NAME = sys.argv[1] if len(sys.argv) > 1 else 'deals.csv'
    analyze_mt5_deals(FILE_NAME)