"""
====================================================================================
🚀 工业级量化策略全自动回测管家 (Win11 -> Linux Podman) - 终极扁平化版
====================================================================================

[🛠️ 必做前置准备：配置 Win11 至 Linux 服务器的 SSH 免密登录]
为了让本脚本全自动无缝运行（上传、执行、下载），而不会卡在“请输入密码”的提示上，
请务必在运行此脚本前，在 Win11 本机完成以下 4 步：

1. 打开 Win11 的 PowerShell 终端。
2. 生成本地 SSH 密钥对（如果以前生成过可跳过此步，遇到提示一路回车即可）：
    > ssh-keygen -t rsa -b 4096

3. 将本机公钥一键注入服务器的授权列表（请复制整行运行，期间需要输入最后一次服务器密码）：
    > type $env:USERPROFILE\.ssh\id_rsa.pub | ssh rits-student@192.168.1.83 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
4. 测试免密登录（运行下方命令，如果直接连上终端而无需密码，则大功告成！）：
    > ssh rits-student@192.168.1.83

====================================================================================
"""
import subprocess
import sys
import time
import os
import shutil
import pandas as pd
from datetime import datetime
from pathlib import Path
import re
from io import StringIO  # 修复 Pandas 警告

# ================= 1. 核心网络与容器配置 =================
SERVER = "rits-student@192.168.1.83"
CONTAINER_NAME = os.environ.get("MT5_CONTAINER_NAME", "mt5-dev")
# 增加 SSH 心跳参数，防止大文件传输或长时间回测时连接超时
SSH_OPTS = "-o ServerAliveInterval=30 -o ServerAliveCountMax=5 -o ConnectTimeout=10"

# ================= 2. 本机 Win11 路径配置 =================
PROJECT_ROOT = r"C:\Users\82204\AppData\Roaming\MetaQuotes\Terminal\D3027A7456F1BED80051EF2A0D0DD331\MQL5\Experts\Advisors\y100143239\profitable-expert-advisor\frontline\cluster-fuck"
REPO_ROOT = os.path.dirname(os.path.dirname(PROJECT_ROOT))

LOCAL_SOURCE_DIR = os.environ.get("MT5_V4_LOCAL_SOURCE_DIR", os.path.join(PROJECT_ROOT, "_united-V4"))
HISTORY_BASE_DIR = os.path.join(PROJECT_ROOT, "report_history")
LOCAL_INI_PATH = os.environ.get("MT5_V4_LOCAL_INI_PATH", os.path.join(LOCAL_SOURCE_DIR, "auto_tester_config.ini"))
LOCAL_METAEDITOR = r"C:\Users\82204\AppData\Roaming\MetaTrader 5\metaeditor64.exe"

# ================= 3. 动态配置解析 (从本地 INI 提取回测区间) =================
def get_backtest_config(ini_path):
    """从本地 INI 文件中动态提取回测起止日期"""
    conf = {"from": "unknown", "to": "unknown"}
    if not os.path.exists(ini_path): return conf
    try:
        with open(ini_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            f_match = re.search(r"FromDate=([\d.]+)", content)
            t_match = re.search(r"ToDate=([\d.]+)", content)
            if f_match: conf["from"] = f_match.group(1).replace('.', '')
            if t_match: conf["to"] = t_match.group(1).replace('.', '')
    except: pass
    return conf

config = get_backtest_config(LOCAL_INI_PATH)
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
# 动态生成文件夹名称：例如 20260511_1330_20240101to20250101
report_prefix = os.environ.get("MT5_REPORT_PREFIX", "").strip()
if report_prefix:
    report_prefix = re.sub(r"[^A-Za-z0-9_.-]+", "_", report_prefix).strip("._-")
folder_name = f"{timestamp}_{config['from']}to{config['to']}"
if report_prefix:
    folder_name = f"{report_prefix}_{folder_name}"
TARGET_DIR = os.path.join(HISTORY_BASE_DIR, folder_name)

os.makedirs(TARGET_DIR, exist_ok=True)

# ================= 4. 服务器 Linux 路径配置 =================
# 🌟 在路径中使用反斜杠转义空格，这是 Linux 识别带空格路径的最稳手段
# 这里我们不再在变量里写反斜杠，回归正常路径，但在命令中用单引号包死
REMOTE_BASE_DIR = os.environ.get("MT5_REMOTE_BASE_DIR", "/home/rits-student/podman/data/mt5/wine/drive_c/Program Files/MetaTrader 5")
CONTAINER_BASE_DIR = os.environ.get("MT5_CONTAINER_BASE_DIR", "/data/mt5/wine/drive_c/Program Files/MetaTrader 5")
REMOTE_EXPERTS_DIR = f"{REMOTE_BASE_DIR}/MQL5/Experts"
REMOTE_INI_PATH = f"{REMOTE_BASE_DIR}/MQL5/auto_tester_config.ini"
REMOTE_FILES_DIR = f"{REMOTE_BASE_DIR}/MQL5/Files"
CONTAINER_FILES_DIR = f"{CONTAINER_BASE_DIR}/MQL5/Files"
CONTAINER_COMMON_FILES_DIR = "/data/mt5/wine/drive_c/users/kasm-user/AppData/Roaming/MetaQuotes/Terminal/Common/Files"
# 报告放在根目录最稳
REMOTE_REPORT_PATH = f"{REMOTE_BASE_DIR}/ReportTester.html"
REMOTE_REPORT_FILES = f"{REMOTE_BASE_DIR}/ReportTester.files"
REMOTE_LOGS_DIR = f"{REMOTE_BASE_DIR}/Tester/logs"
# 🌟 不再写死 3000，而是定义父目录，后面用通配符寻找
REMOTE_TESTER_DIR = f"{REMOTE_BASE_DIR}/Tester"
CONTAINER_TESTER_DIR = f"{CONTAINER_BASE_DIR}/Tester"



# --- 传给 Wine 的虚拟 Windows C盘路径 ---
WINE_COMPILER = r"C:\Program Files\MetaTrader 5\metaeditor64.exe"
WINE_TERMINAL = r"C:\Program Files\MetaTrader 5\terminal64.exe"
WINE_MQ5 = r"C:\Program Files\MetaTrader 5\MQL5\Experts\_united-V4\main.mq5"
WINE_INI = r"C:\Program Files\MetaTrader 5\MQL5\auto_tester_config.ini"

# 档案库产出物定义
ARCHIVE_ZIP_PATH = os.path.join(TARGET_DIR, "source_code_snapshot.zip") 
ARCHIVE_INI = os.path.join(TARGET_DIR, "backtest_config.ini") 
LOCAL_HTML = os.path.join(TARGET_DIR, "Report.html")
LOCAL_EXCEL = os.path.join(TARGET_DIR, "Report_Data.xlsx")
LOCAL_CSV_DEALS = os.path.join(TARGET_DIR, "deals.csv")
LOCAL_LOG = os.path.join(TARGET_DIR, "Terminal.log")
# 本地详细回测日志文件名
LOCAL_AGENT_LOG = os.path.join(TARGET_DIR, "Agent_Detail.log")

# ================= 5. 核心工具函数 =================
def _harden_ssh(cmd: str) -> str:
    """给 ssh 命令注入 -n (close stdin) 防止 wineserver 继承 stdio 导致 ssh 挂起.
    只匹配独立的 'ssh ' 前缀, 不影响 scp."""
    # 只在 cmd 起始处或空格后是 'ssh ' 时插入 -n; 已经有 -n 就跳过
    if re.search(r"(^|\s)ssh\s+-n\s", cmd):
        return cmd
    return re.sub(r"(^|\s)ssh\s", r"\1ssh -n ", cmd, count=1)

def run(cmd, timeout=300):
    """执行 Shell 命令; ssh 自动注入 -n + 默认 5 分钟硬超时, 防止永远挂起."""
    cmd = _harden_ssh(cmd)
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, shell=True, timeout=timeout)
    except subprocess.TimeoutExpired as e:
        print(f"\n⏱️ [硬超时 {timeout}s] 命令未在限定时间内返回, 已强杀:\n   {cmd}")
        out = (e.stdout or b"").decode("utf-8", "replace") if isinstance(e.stdout, (bytes, bytearray)) else (e.stdout or "")
        err = (e.stderr or b"").decode("utf-8", "replace") if isinstance(e.stderr, (bytes, bytearray)) else (e.stderr or "")
        if err: print(f"   stderr: {err.strip()}")
        # 返回一个伪成功结果, 让流水线继续往下走 (后续轮询/校验会兜底)
        class _R:
            returncode = 0
            stdout = out
            stderr = err
        return _R()
    if result.returncode != 0:
        print(f"\n❌ [致命拦截] 执行该步骤时服务器底层报错！")
        print(f"👉 崩溃指令: {cmd}")
        print(f"🔴 错误详情 (stderr): \n{result.stderr.strip()}")
        print(f"🟡 标准输出 (stdout): \n{result.stdout.strip()}")
        print(f"\n🚫 脚本已强制终止，请先修复上述错误！")
        exit(1)
    return result

def compile_local_expert():
    source = os.path.join(LOCAL_SOURCE_DIR, "main.mq5")
    ex5 = os.path.join(LOCAL_SOURCE_DIR, "main.ex5")
    log = os.path.join(LOCAL_SOURCE_DIR, "main.log")
    if os.environ.get("MT5_SKIP_LOCAL_COMPILE", "0") == "1":
        if not os.path.exists(ex5):
            print(f"\n🚫 MT5_SKIP_LOCAL_COMPILE=1 but EX5 is missing: {ex5}")
            exit(1)
        print(f"   --> 跳过本地编译，使用已有 EX5: {ex5}")
        return
    if not os.path.exists(LOCAL_METAEDITOR):
        print(f"\n🚫 本地 MetaEditor 不存在: {LOCAL_METAEDITOR}")
        exit(1)
    started = time.time()
    result = subprocess.run([LOCAL_METAEDITOR, f"/compile:{source}", "/log"], capture_output=True, text=True, timeout=240)
    deadline = time.time() + 15
    while time.time() < deadline:
        if os.path.exists(ex5) and os.path.getmtime(ex5) >= started:
            break
        time.sleep(0.5)
    log_text = ""
    if os.path.exists(log):
        try:
            with open(log, "r", encoding="utf-16", errors="ignore") as f:
                log_text = f.read()
        except Exception:
            log_text = ""
    log_ok = "Result: 0 errors" in log_text
    if not log_ok or not os.path.exists(ex5) or os.path.getmtime(ex5) < started - 2:
        print("\n🚫 本地 EA 编译失败或 EX5 未刷新，停止部署以避免远端跑旧二进制。")
        if log_text:
            print("".join(log_text.splitlines(keepends=True)[-80:]))
        print(result.stderr)
        exit(1)
    print(f"   --> 本地 EA 编译完成: {ex5}")
# ================= 5. 核心工具函数 (🌟 修复编码问题) =================
def run2(cmd):
    """执行 Shell 命令，强制使用 utf-8 编码，防止 Windows GBK 报错"""
    try:
        # 🌟 关键：增加 encoding='utf-8' 和 errors='replace'
        result = subprocess.run(cmd, capture_output=True, text=True, shell=True, encoding='utf-8', errors='replace')
        if result.returncode != 0:
            print(f"\n❌ [致命拦截] 服务器底层报错！")
            print(f"👉 指令: {cmd}")
            print(f"🔴 错误详情: \n{result.stderr if result.stderr else 'None'}")
            exit(1)
        return result
    except Exception as e:
        print(f"\n❌ [Python 内部崩溃] 可能是编码或进程中断: {e}")
        exit(1)

def adapt_ini_for_server(local_ini, temp_ini):
    print(f"🔧 正在适配本地 INI 配置文件以供服务器使用...")
    tester_login = os.environ.get("MT5_TESTER_LOGIN", "").strip()
    tester_server = os.environ.get("MT5_TESTER_SERVER", "").strip()
    tester_password = os.environ.get("MT5_TESTER_PASSWORD", "")
    with open(local_ini, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    with open(temp_ini, 'w', encoding='utf-8') as f:
        account_keys_written = False
        for line in lines:
            normalized_line = line.strip().lstrip("\ufeff")
            if normalized_line == "[Tester]" and not account_keys_written:
                f.write(line)
                if tester_login:
                    f.write(f"Login={tester_login}\n")
                if tester_server:
                    f.write(f"Server={tester_server}\n")
                if tester_password:
                    f.write(f"Password={tester_password}\n")
                account_keys_written = True
                if tester_login or tester_server or tester_password:
                    print(
                        "   --> 注入 MT5 tester 账号字段: "
                        f"Login={'yes' if tester_login else 'no'}, "
                        f"Server={'yes' if tester_server else 'no'}, "
                        f"Password={'yes' if tester_password else 'no'}"
                    )
                continue
            if (tester_login and line.startswith("Login=")) or (tester_server and line.startswith("Server=")) or (tester_password and line.startswith("Password=")):
                continue
            if line.startswith("Report="):
                # 🌟 关键：直接写文件名，MT5 会默认放在根目录，方便扁平化回收
                f.write(f"Report=ReportTester.html\n")
            elif line.startswith("ReplaceReport="):
                f.write(f"ReplaceReport=1\n")
            elif line.startswith("Expert="):
                # 适配服务器上的 Experts 路径
                f.write(f"Expert=_united-V4\\main.ex5\n")
            # elif line.startswith("ShutdownTerminal="):
            #     # 强制开启自动关闭，防止 SSH 挂起
            #     f.write(f"ShutdownTerminal=1\n")
            else:
                f.write(line)

def _ini_value(path, key, default=""):
    try:
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                if line.startswith(f"{key}="):
                    value = line.split("=", 1)[1].strip()
                    return value.split("||", 1)[0].strip()
    except OSError:
        pass
    return default

def _terminal_mql5_root():
    path = Path(PROJECT_ROOT)
    for parent in [path] + list(path.parents):
        if parent.name.lower() == "mql5":
            return parent
    return None

def find_calendar_csv():
    env_path = os.environ.get("MT5_CALENDAR_CSV", "").strip()
    candidates = []
    if env_path:
        candidates.append(Path(env_path))
    candidates.extend([
        Path(REPO_ROOT) / "frontline" / "calendar_probe" / "economic_calendar.csv",
        Path(REPO_ROOT) / "economic_calendar.csv",
    ])
    mql5_root = _terminal_mql5_root()
    if mql5_root is not None:
        candidates.append(mql5_root / "Files" / "economic_calendar.csv")

    for candidate in candidates:
        if candidate.is_file():
            return candidate
    return None

def remote_agent_dirs():
    result = run(f'ssh {SSH_OPTS} {SERVER} "find \'{REMOTE_TESTER_DIR}\' -maxdepth 1 -type d -name \'Agent-*\'"')
    agents = {line.strip() for line in result.stdout.splitlines() if line.strip()}
    for port in range(3000, 3025):
        agents.add(f"{REMOTE_TESTER_DIR}/Agent-127.0.0.1-{port}")
    return sorted(agents)

def container_path(remote_path):
    return remote_path.replace(REMOTE_BASE_DIR, CONTAINER_BASE_DIR, 1)

def deploy_calendar_csv(archive_ini):
    csv_name = _ini_value(archive_ini, "GRM_CalendarRiskCsvFile", "economic_calendar.csv") or "economic_calendar.csv"
    csv_name = csv_name.replace("\\", "/").lstrip("/")
    temp_csv_name = os.path.basename(csv_name)
    local_csv = find_calendar_csv()
    remote_csv = f"{REMOTE_FILES_DIR}/{csv_name}"
    container_csv = f"{CONTAINER_FILES_DIR}/{csv_name}"
    container_common_csv = f"{CONTAINER_COMMON_FILES_DIR}/{csv_name}"

    run(f'ssh {SSH_OPTS} {SERVER} "podman exec {CONTAINER_NAME} mkdir -p \'{os.path.dirname(container_csv)}\'"')
    run(f'ssh {SSH_OPTS} {SERVER} "podman exec {CONTAINER_NAME} mkdir -p \'{os.path.dirname(container_common_csv)}\'"')
    if local_csv is None:
        print(f"   --> Calendar CSV not found locally; removing remote stale file: {csv_name}")
        run(f'ssh {SSH_OPTS} {SERVER} "podman exec {CONTAINER_NAME} rm -f \'{container_csv}\'"')
        run(f'ssh {SSH_OPTS} {SERVER} "podman exec {CONTAINER_NAME} rm -f \'{container_common_csv}\'"')
        for remote_agent in remote_agent_dirs():
            agent_csv = f"{container_path(remote_agent)}/MQL5/Files/{csv_name}"
            run(f'ssh {SSH_OPTS} {SERVER} "podman exec {CONTAINER_NAME} rm -f \'{agent_csv}\'"')
        return

    archive_csv = os.path.join(TARGET_DIR, os.path.basename(csv_name))
    shutil.copyfile(local_csv, archive_csv)
    remote_tmp_csv = f"/tmp/mt5_calendar_{temp_csv_name}"
    run(f'scp {SSH_OPTS} "{local_csv}" {SERVER}:{remote_tmp_csv}')
    run(f'ssh {SSH_OPTS} {SERVER} "podman cp {remote_tmp_csv} \'{CONTAINER_NAME}:{container_csv}\'"')
    run(f'ssh {SSH_OPTS} {SERVER} "podman cp {remote_tmp_csv} \'{CONTAINER_NAME}:{container_common_csv}\'"')
    for remote_agent in remote_agent_dirs():
        agent_csv = f"{container_path(remote_agent)}/MQL5/Files/{csv_name}"
        run(f'ssh {SSH_OPTS} {SERVER} "podman exec {CONTAINER_NAME} mkdir -p \'{os.path.dirname(agent_csv)}\'"')
        run(f'ssh {SSH_OPTS} {SERVER} "podman cp {remote_tmp_csv} \'{CONTAINER_NAME}:{agent_csv}\'"')
    run(f'ssh {SSH_OPTS} {SERVER} "rm -f {remote_tmp_csv}"')
    print(f"   --> Calendar CSV deployed: {local_csv} -> MQL5/Files/{csv_name} + Common/Files/{csv_name}")

def process_data(html_path, target_dir, csv_path):
    print(f"📊 正在使用 v2 增强模块解析并分析回测数据...")
    script_html_to_xlsx = os.path.join(LOCAL_SOURCE_DIR, "html_to_xlsx_v2.py")
    script_analyze = os.path.join(LOCAL_SOURCE_DIR, "analyze_mt5_report_v2.py")
    
    try:
        print(f"   --> 提取 HTML 表格: {script_html_to_xlsx}")
        subprocess.run(["python", script_html_to_xlsx, html_path, target_dir], check=True)
        
        print(f"   --> 执行增强版数据分析: {script_analyze}")
        subprocess.run(["python", script_analyze, csv_path], check=True)
    except subprocess.CalledProcessError as e:
        print(f"⚠️ 数据处理子进程发生错误: {e}")
    except Exception as e:
        print(f"⚠️ 数据处理发生异常: {e}")

# ================= 6. 流水线主进程 =================
if __name__ == "__main__":
    start_all = time.time()
    print(f"🚀 [INIT] 启动大型策略集群全自动回测流水线: {folder_name}")
    print(f"   --> Remote target: container={CONTAINER_NAME}, base={REMOTE_BASE_DIR}")

    # --- A. 本地源码快照归档 ---
    print("\n📦 [STEP 1] 正在建立本地项目级 ZIP 快照 (绝对防丢失)...")
    compile_local_expert()
    shutil.make_archive(ARCHIVE_ZIP_PATH.replace('.zip', ''), 'zip', LOCAL_SOURCE_DIR) 
    
    # 适配并备份 INI
    adapt_ini_for_server(LOCAL_INI_PATH, ARCHIVE_INI)

    # --- B. 源码 ZIP 传输与远程解压 ---
    print("\n📤 [STEP 2] 传输 ZIP 包至服务器并解压...")
    
    # 1. 强力清理旧目录
    run(f'ssh {SSH_OPTS} {SERVER} "rm -rf \'{REMOTE_EXPERTS_DIR}/_united-V4\' && mkdir -p \'{REMOTE_EXPERTS_DIR}/_united-V4\'"')
    
    # 2. 传 ZIP 包
    remote_zip_path = f"{REMOTE_EXPERTS_DIR}/upload.zip"
    print(f"   --> 正在推送压缩包...")
    run(f'scp {SSH_OPTS} "{ARCHIVE_ZIP_PATH}" {SERVER}:"{remote_zip_path}"')
    
    # 3. 传适配后的 INI
    run(f'scp {SSH_OPTS} "{ARCHIVE_INI}" {SERVER}:"{REMOTE_INI_PATH}"')
    
    # 4. 远程解压 (使用 -o 强制覆盖)
    print("   --> 正在服务器端强制解压项目文件...")
    unzip_cmd = f"unzip -o -q '{remote_zip_path}' -d '{REMOTE_EXPERTS_DIR}/_united-V4' && rm '{remote_zip_path}'"
    run(f'ssh {SSH_OPTS} {SERVER} "{unzip_cmd}"')
    print("   --> 项目文件部署完毕。")

    # --- C. 容器清理与编译 ---
    print("\n🧹 [CLEAN] 正在清理旧的 MT5 进程...")
    subprocess.run(f'ssh -n {SSH_OPTS} {SERVER} "podman exec {CONTAINER_NAME} pkill -f terminal64.exe || true"', shell=True, timeout=60)

    if os.environ.get("MT5_SKIP_REMOTE_COMPILE", "0") == "1":
        print("\n🛠️ [STEP 3] 跳过容器内 MetaEditor 编译，使用已部署 EX5。")
    else:
        print("\n🛠️ [STEP 3] 唤醒容器内 MetaEditor 进行全局编译...")
        # 改用柔性执行，防止编译器警告导致脚本中断
        compile_cmd = f"podman exec {CONTAINER_NAME} wine '{WINE_COMPILER}' /compile:'{WINE_MQ5}' /log"
        try:
            subprocess.run(f'ssh -n {SSH_OPTS} {SERVER} "{compile_cmd}"', shell=True, timeout=600)
        except subprocess.TimeoutExpired:
            print("   --> ⏱️ 编译超时 10min, 强杀容器内 wine/metaeditor 后继续")
            subprocess.run(f'ssh -n {SSH_OPTS} {SERVER} "podman exec {CONTAINER_NAME} pkill -9 -f \'wine|metaeditor\' 2>/dev/null; true"', shell=True, timeout=30)

    # 🌟 STEP 3.5 强制清理上一次回测的陈旧产物（防止 ssh+wine 提前返回时拉到昨日报告）
    # 旧版直接 ssh rm 会因为文件归属容器内 kasm-user (host uid 428679) 而 Permission denied
    # -> 旧 ReportTester.html mtime 不更新 -> STEP 4.5 轮询 45min 卡死。
    # 修复: 用 podman exec 在容器内以 kasm-user 身份 rm。容器内 wine drive_c 路径为
    #   /data/mt5/wine/drive_c/Program Files/MetaTrader 5
    # 注意: shell=True 在 Win11 走 cmd.exe，cmd 不识别 \" 转义；故避免嵌套双引号，
    # 改用反斜杠转义路径中的空格 + 多次单条 podman exec 调用。
    print("\n🧽 [STEP 3.5] 清理远端陈旧 ReportTester.* 产物...")
    container_mt5_esc = "/data/mt5/wine/drive_c/Program\\ Files/MetaTrader\\ 5"
    if os.environ.get("MT5_RESET_LOCAL_TESTER_AGENTS", "0") == "1":
        print("   --> 正在重建本地 Tester Agent 授权缓存...")
        reset_agents_cmd = f"sh -lc 'rm -rf {container_mt5_esc}/Tester/Agent-127.0.0.1-*'"
        try:
            subprocess.run(
                f'ssh -n {SSH_OPTS} {SERVER} "podman exec {CONTAINER_NAME} {reset_agents_cmd} || true"',
                shell=True,
                timeout=60,
            )
        except subprocess.TimeoutExpired:
            print("   --> ⏱️ Tester Agent 缓存重建超时, 继续尝试回测")
    cleanup_targets = [
        f"rm -f {container_mt5_esc}/ReportTester.html",
        f"rm -rf {container_mt5_esc}/ReportTester.files",
        f"rm -f {container_mt5_esc}/ReportTester-holding.png",
        f"rm -f {container_mt5_esc}/ReportTester-hst.png",
        f"rm -f {container_mt5_esc}/ReportTester-mfemae.png",
        f"rm -f {container_mt5_esc}/ReportTester.png",
    ]
    for cmd in cleanup_targets:
        ssh_cmd = f'ssh -n {SSH_OPTS} {SERVER} "podman exec {CONTAINER_NAME} {cmd} || true"'
        try:
            subprocess.run(ssh_cmd, shell=True, timeout=30)
        except subprocess.TimeoutExpired:
            print(f"   --> ⏱️ 清理超时 30s: {cmd}")

    if os.environ.get("MT5_SKIP_CALENDAR_DEPLOY", "0") == "1":
        print("   --> 跳过经济日历 CSV replay 数据同步。")
    else:
        print("   --> 正在同步经济日历 CSV replay 数据...")
        deploy_calendar_csv(ARCHIVE_INI)

    print("⏳ [STEP 4] 引擎轰鸣中：服务器开始执行真实分时高精度回测...")
    test_start = time.time()
    remote_tester_log = f"{REMOTE_LOGS_DIR}/{datetime.now():%Y%m%d}.log"
    log_size_cmd = _harden_ssh(
        f"ssh {SSH_OPTS} {SERVER} \"wc -c < '{remote_tester_log}' 2>/dev/null || echo 0\""
    )
    log_start_offset = 0
    try:
        log_size_result = subprocess.run(log_size_cmd, capture_output=True, text=True, shell=True, timeout=20)
        log_start_offset = int((log_size_result.stdout or "0").strip().splitlines()[-1])
    except (subprocess.TimeoutExpired, ValueError, IndexError):
        log_start_offset = 0
    test_cmd = f"podman exec {CONTAINER_NAME} wine '{WINE_TERMINAL}' /config:'{WINE_INI}'"
    # 🌟 用 Popen 后台启动 + ssh -n 关闭 stdin, 避免 wineserver 滞留导致 ssh 阻塞
    wine_proc = subprocess.Popen(
        f'ssh -n {SSH_OPTS} {SERVER} "{test_cmd}"',
        shell=True, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )

    # 🌟 STEP 4.5: 轮询新 ReportTester.html 落盘 (mtime>start AND size 稳定)
    print("   --> ⏰ 等待 ReportTester.html 落盘 (轮询，最长 45 分钟)...")
    poll_cmd = (
        f"ssh {SSH_OPTS} {SERVER} "
        f"\"if [ -f '{REMOTE_REPORT_PATH}' ]; then "
        f"stat -c '%Y %s' '{REMOTE_REPORT_PATH}'; "
        f"fi\""
    )
    account_error_cmd = (
        f"ssh {SSH_OPTS} {SERVER} "
        f"\"tail -c +{max(log_start_offset + 1, 1)} '{remote_tester_log}' 2>/dev/null "
        f"| iconv -f UTF-16LE -t UTF-8 2>/dev/null "
        f"| grep -q 'tester not started because the account is not specified'\""
    )
    deadline = test_start + 45 * 60
    poll_cmd = _harden_ssh(poll_cmd)
    account_error_cmd = _harden_ssh(account_error_cmd)
    last_size = -1
    stable_since = 0
    detected = False
    while time.time() < deadline:
        time.sleep(8)
        account_error = subprocess.run(account_error_cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=20)
        if account_error.returncode == 0:
            print("   --> 🚫 MT5 tester 未启动: account is not specified. 请先恢复/注入 tester 登录凭据。")
            sys.exit(3)
        try:
            r = subprocess.run(poll_cmd, capture_output=True, text=True, shell=True, timeout=20)
        except subprocess.TimeoutExpired:
            continue
        out = (r.stdout or "").strip()
        if not out:
            continue
        try:
            mtime, size = out.split()
            mtime, size = int(mtime), int(size)
        except ValueError:
            continue
        if mtime < int(test_start) - 5 or size < 1024:
            continue  # 还是旧文件 / 空文件
        if size == last_size:
            if time.time() - stable_since >= 12:
                print(f"   --> ✅ Report 已稳定: {size} bytes")
                detected = True
                break
        else:
            last_size = size
            stable_since = time.time()
    if not detected:
        print("   --> ⚠️ 超时未检测到新报告; 继续推进 (后续会拉取已存在文件)")

    # 🌟 强杀 wineserver, 让 Popen 立即返回 (terminal64 已退出但 wineserver 滞留会卡住 ssh)
    print("   --> 🔪 清理容器内残留 wineserver/wine 进程 (避免 ssh 阻塞)...")
    try:
        subprocess.run(
            f'ssh -n {SSH_OPTS} {SERVER} "podman exec {CONTAINER_NAME} pkill -9 -f wine 2>/dev/null; true"',
            shell=True, timeout=60,
        )
    except subprocess.TimeoutExpired:
        print("   --> ⏱️ pkill ssh 超时, 跳过")
    try:
        wine_proc.wait(timeout=30)
    except subprocess.TimeoutExpired:
        wine_proc.kill()
        print("   --> ⚠️ Popen ssh 卡死, 已强杀")

    t_mt5_done = time.time()
    print(f"   ⏱️ MT5 容器返回，进入产物回收阶段 (累计 {t_mt5_done - start_all:.1f}s)")

    # --- D. 提取战利品 (智能 Agent 日志回收 - 终极修复版) ---   
    print("\n📥 [STEP 5] 正在回收全维度日志与报告...")
    
    import shlex  # 必须导入，用于处理 Linux 路径转义
    from io import StringIO

    # 1. 终端日志 (Terminal)
    t_log_cmd = f"ssh -n {SSH_OPTS} {SERVER} \"ls -t '{REMOTE_LOGS_DIR}'/*.log | head -1\""
    try:
        t_path = subprocess.run(t_log_cmd, capture_output=True, text=True, shell=True, timeout=30).stdout.strip()
    except subprocess.TimeoutExpired:
        print("   --> ⏱️ Terminal log 探测超时, 跳过")
        t_path = ""
    if t_path:
        # 使用 shlex.quote 自动处理路径中的空格
        safe_t_path = shlex.quote(t_path)
        try:
            subprocess.run(f"ssh -n {SSH_OPTS} {SERVER} \"tail -n 500 {safe_t_path}\" > \"{LOCAL_LOG}\"", shell=True, timeout=60)
        except subprocess.TimeoutExpired:
            print("   --> ⏱️ Terminal log tail 超时, 跳过")

   # 2. 智能 Agent 日志 (探测最新活跃 Agent)
    print("   --> 🛡️ 正在探测活跃 Agent 日志...")
    # 🌟 降维打击逻辑：
    # 1. cd 进 Tester 目录（单引号包裹变量，100% 安全）
    # 2. find .（在当前目录下找，路径前缀不再有 Program Files，只有相对路径 ./Agent-xxx）
    # 3. 找到后直接用 xargs 喂给 tail
    a_cmd = (
        f"ssh -n {SSH_OPTS} {SERVER} \""
        f"cd '{REMOTE_TESTER_DIR}' && "
        f"find . -name '*.log' -path '*/Agent-*/logs/*' -printf '%T@ %p\\n' "
        f"| sort -n | tail -1 | awk '{{print $2}}' "
        f"| xargs -I {{}} tail -n 1000 '{{}}'\""
        f" > \"{LOCAL_AGENT_LOG}\""
    )
    try:
        subprocess.run(a_cmd, shell=True, timeout=60)
        print("   --> ✅ 日志摘要同步成功。")
    except subprocess.TimeoutExpired:
        print("   --> ⏱️ Agent 日志同步超时, 跳过")

    # 3. 拉取 HTML 报告
    print("   --> 📥 正在同步 HTML 回测报告...")
    run(f'scp {SSH_OPTS} {SERVER}:"{REMOTE_REPORT_PATH}" "{LOCAL_HTML}"')

    # 4. 抓取图片 (采用先打包后拉取的策略，完美规避空格和通配符问题)
    print("   --> 📸 正在远程打包并同步回测图片...")
    # 在服务器执行：进入目录 -> 把所有 ReportTester*.png 打成 imgs.tar
    remote_tar = "/tmp/bt_imgs.tar"
    pack_cmd = f"ssh {SSH_OPTS} {SERVER} \"cd '{REMOTE_BASE_DIR}' && tar -cf {remote_tar} ReportTester*.png\""
    
    # 执行打包 (如果没图片，tar 会报错，我们加个 check)
    try:
        run(pack_cmd)
        # 拉取 tar 包
        run(f'scp {SSH_OPTS} {SERVER}:{remote_tar} "{TARGET_DIR}/imgs.tar"')
        # 本地解压 (Win11 自带 tar 命令)
        subprocess.run(f'tar -xf "{TARGET_DIR}/imgs.tar" -C "{TARGET_DIR}/"', shell=True)
        # 清理垃圾
        os.remove(f"{TARGET_DIR}/imgs.tar")
        run(f'ssh {SSH_OPTS} {SERVER} "rm {remote_tar}"')
        print("   --> ✅ 图片资源同步成功。")
    except Exception as e:
        print(f"   --> ⚠️ 图片同步跳过或失败 (可能本次回测未产生图片): {e}")


    # --- E. 数据分析切片 ---
    print(f"\n🔬 [STEP 6] 数据后处理... (回收阶段累计 {time.time() - t_mt5_done:.1f}s)")
    t_step6 = time.time()
    process_data(LOCAL_HTML, TARGET_DIR, LOCAL_CSV_DEALS)
    print(f"   ⏱️ 后处理耗时 {time.time() - t_step6:.1f}s")

    print(f"\n✨ [SUCCESS] 回测任务圆满完成！")
    print(f"📂 档案专属保险箱: {TARGET_DIR}")
    print(f"⏱️ 机器打工总耗时: {time.time() - start_all:.2f} 秒")

    # 🌟 Agent/CI 模式下跳过 Explorer 弹窗，避免子进程注册延迟
    if os.environ.get("MT5_NO_EXPLORER", "0") != "1":
        os.startfile(TARGET_DIR)

    # 🌟 显式 flush + 退出，绕过 conda run / Tee-Object 的 finalization 滞留
    sys.stdout.flush()
    sys.stderr.flush()
    sys.exit(0)