import pandas as pd

# 1. 读取你的 CSV 文件 (请确认文件名正确)
file_name = 'ReportTester-106832906-4-Deals.csv' 
df = pd.read_csv(file_name)

# 清理表头空格
df.columns = df.columns.str.strip()

# 2. 【核心修复】破解 MT5 的特殊减号骗局
# 把特殊的 '−' 替换为标准的 '-'，然后再转为数字
df['Profit'] = df['Profit'].astype(str).str.replace('−', '-') 
df['Profit'] = pd.to_numeric(df['Profit'], errors='coerce').fillna(0)

# 3. 【核心修复】通过 Order(订单号) 找回丢失的策略名
# 找出所有进场单 (Direction 为 in)
df_in = df[df['Direction'].astype(str).str.lower().str.contains('in', na=False)]
# 创建一本字典：订单号 -> 真实的策略名
strategy_map = dict(zip(df_in['Order'], df_in['Comment']))

# 把真实的策略名映射给所有的交易记录
df['Real_Strategy'] = df['Order'].map(strategy_map)

# 4. 按真实的策略名进行利润汇总
summary = df.groupby('Real_Strategy')['Profit'].sum().reset_index()

# 剔除掉利润刚好为 0 的干扰项，并从小到大排序
summary = summary[summary['Profit'] != 0]
summary = summary.sort_values(by='Profit', ascending=True)

print("\n🚨 5周回测亏损排行榜 (真凶彻底显形)：")
print("-" * 55)
print(summary.to_string(index=False))
print("-" * 55)
print("💡 排在最上面、带有负数的，就是吞噬利润的毒瘤！")