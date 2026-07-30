#!/usr/bin/env python3
"""
run_iter.py — One-shot iteration runner for the XAUUSD EA.

Pipeline:
  1. Compile <ea>.mq5 locally (MetaEditor, short-path main repo) -> <ea>.ex5
  2. Upload ex5 + ini into mt5-dev container
  3. Launch terminal64 backtest (real ticks, random delay)
  4. Poll until done
  5. Download HTML report + chart PNGs into the result folder
  6. Run analyze_report.py to emit deals.csv/summary.csv/analysis_report.md

Usage:
    python run_iter.py --ea <path-to-mq5> --out <result_dir> --report-name <stem>
    python run_iter.py --stage tick --ea <path-to-mq5> --out <result_dir> --report-name <stem>

The default quick stage uses H1 chart execution with Model=1 (1-minute OHLC).
Use --stage tick only after a quick result materially improves over its baseline.
"""
import argparse, hashlib, json, os, re, shutil, subprocess, sys, time
import getpass
from datetime import datetime

SSH = ['ssh', '-n', 'rits-student@192.168.1.83']
HOST = 'rits-student@192.168.1.83'
CBASE = '/data/mt5/wine/drive_c/Program Files/MetaTrader 5'
METAEDITOR = r'C:\Users\82204\AppData\Roaming\MetaTrader 5\metaeditor64.exe'
CONTAINER = 'mt5-dev'

def run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)

def ssh(remote):
    return run(SSH + [remote])

def compile_ea(mq5):
    ex5 = os.path.splitext(mq5)[0] + '.ex5'
    if os.path.exists(ex5):
        os.remove(ex5)
    log = os.path.splitext(mq5)[0] + '_compile.log'
    subprocess.run([METAEDITOR, f'/compile:{mq5}', f'/log:{log}'])
    for _ in range(30):
        if os.path.exists(ex5):
            break
        time.sleep(2)
    if not os.path.exists(ex5):
        print('COMPILE FAILED — no ex5'); sys.exit(1)
    # show result line
    if os.path.exists(log):
        data = open(log, 'rb').read().decode('utf-16-le', 'replace')
        for ln in data.splitlines():
            if 'Result' in ln or 'error' in ln.lower():
                print('  ', ln.strip())
    print(f'compiled: {ex5} ({os.path.getsize(ex5)} bytes)')
    return ex5

def scp_to(local, remote_tmp):
    run(['scp', local, f'{HOST}:{remote_tmp}'])

def podman_cp_in(tmp, dest):
    ssh(f'podman cp {tmp} "{CONTAINER}:{CBASE}/{dest}"')

def sha256(path):
    digest = hashlib.sha256()
    with open(path, 'rb') as fh:
        for block in iter(lambda: fh.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()

def safe_name(value):
    return re.sub(r'[^A-Za-z0-9_.-]+', '_', value).strip('_') or 'run'

def patch_expert(ini_path, expert_path, output_path):
    data = open(ini_path, 'r', encoding='utf-8-sig').read()
    patched, count = re.subn(r'(?m)^Expert=.*$', lambda _: f'Expert={expert_path}', data, count=1)
    if count != 1:
        raise RuntimeError(f'cannot locate [Tester] Expert= in {ini_path}')
    open(output_path, 'w', encoding='utf-8', newline='').write(patched)

def start_playwright_monitor(output_dir, stop_file, done_file, interval, url, interactive_auth=False):
    script = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'playwright_monitor.py')
    candidates = [os.environ.get('PLAYWRIGHT_PYTHON'), sys.executable,
                  os.path.join(os.path.expanduser('~'), '.conda', 'envs', 'mt5', 'python.exe')]
    python = None
    for candidate in candidates:
        if candidate and os.path.isfile(candidate):
            probe = subprocess.run([candidate, '-c', 'import playwright'], capture_output=True)
            if probe.returncode == 0:
                python = candidate
                break
    if not python:
        raise RuntimeError('no Python interpreter found for Playwright monitor')
    command = [python, script, '--url', url, '--out', output_dir,
               '--interval', str(interval), '--stop-file', stop_file,
               '--done-file', done_file]
    if interactive_auth:
        command.append('--interactive-auth')
    return subprocess.Popen(command)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--ea', required=True)
    ap.add_argument('--ini', help='explicit tester INI; overrides --stage')
    ap.add_argument('--stage', choices=['quick', 'tick'], default='quick',
                    help='quick = H1 chart with minute OHLC; tick = H1 real ticks')
    ap.add_argument('--out', required=True)
    ap.add_argument('--report-name', required=True)
    ap.add_argument('--label', default='')
    ap.add_argument('--max-poll', type=int, default=160)
    ap.add_argument('--monitor-interval', type=int, default=1,
                    help='capture a Playwright screenshot every N polls; 0 disables monitoring')
    ap.add_argument('--monitor-url', default='https://192.168.1.83:3088')
    ap.add_argument('--monitor-interactive-auth', action='store_true',
                    help='show Playwright Chromium and fill the native noVNC login prompt manually')
    ap.add_argument('--stop-file', help='create this file to stop the active backtest early')
    ap.add_argument('--skip-compile', action='store_true',
                    help='use the existing <ea>.ex5 instead of recompiling (for archive binaries)')
    args = ap.parse_args()

    config_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'v4opt', 'ea')
    default_ini = 'quick_validation_config.ini' if args.stage == 'quick' else 'validation_config.ini'
    ini_path = os.path.abspath(args.ini) if args.ini else os.path.join(config_dir, default_ini)
    if not os.path.isfile(ini_path):
        print(f'CONFIG NOT FOUND: {ini_path}')
        sys.exit(1)

    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    rn = f'{args.report_name}_{timestamp}'
    run_out = os.path.join(args.out, rn)
    os.makedirs(run_out, exist_ok=False)

    # Preserve the exact inputs before compilation and remote execution, even
    # when a tester failure prevents report generation.
    shutil.copy2(args.ea, os.path.join(run_out, 'baseline.mq5'))
    shutil.copy2(ini_path, os.path.join(run_out, 'config.ini'))
    with open(os.path.join(run_out, 'validation_stage.txt'), 'w', encoding='ascii') as stage_file:
        stage_file.write(f'stage={args.stage}\nmodel={"1-minute OHLC" if args.stage == "quick" else "real ticks"}\n')
    if args.skip_compile:
        ex5 = os.path.splitext(args.ea)[0] + '.ex5'
        if not os.path.exists(ex5):
            print(f'SKIP-COMPILE: ex5 not found: {ex5}'); sys.exit(1)
        print(f'skip-compile: using existing {ex5} ({os.path.getsize(ex5)} bytes)')
    else:
        ex5 = compile_ea(args.ea)
    shutil.copy2(ex5, os.path.join(run_out, 'main.ex5'))

    run_id = f'{safe_name(rn)}_{sha256(ex5)[:12]}'
    remote_dir = f'MQL5/Experts/_runs/{run_id}'
    remote_expert = f'_runs/{run_id}/main.ex5'
    remote_expert_win = f'_runs\\{run_id}\\main.ex5'
    remote_ini = f'_runs/{run_id}/config.ini'
    remote_ini_win = f'_runs\\{run_id}\\config.ini'
    deployed_ini = os.path.join(run_out, 'deployed_config.ini')
    patch_expert(ini_path, remote_expert_win, deployed_ini)

    # Upload into a unique per-run directory so MT5 cannot load another run's EA.
    ex5_tmp = f'/tmp/{run_id}.ex5'
    ini_tmp = f'/tmp/{run_id}.ini'
    scp_to(ex5, ex5_tmp)
    scp_to(deployed_ini, ini_tmp)
    ssh(f'podman exec {CONTAINER} mkdir -p "{CBASE}/{remote_dir}" "{CBASE}/MQL5/_runs/{run_id}"')
    podman_cp_in(ex5_tmp, f'{remote_dir}/main.ex5')
    podman_cp_in(ini_tmp, f'MQL5/{remote_ini}')

    remote_hash = ssh(
        f'podman exec {CONTAINER} sha256sum "{CBASE}/{remote_dir}/main.ex5" "{CBASE}/MQL5/{remote_ini}"'
    ).stdout.strip()
    expected_hashes = {'ea_ex5': sha256(ex5), 'config_ini': sha256(deployed_ini)}
    if expected_hashes['ea_ex5'] not in remote_hash or expected_hashes['config_ini'] not in remote_hash:
        raise RuntimeError(f'remote artifact hash verification failed: {remote_hash}')
    manifest = {
        'run_id': run_id,
        'source_mq5': os.path.abspath(args.ea),
        'source_mq5_sha256': sha256(args.ea),
        'compiled_ex5_sha256': expected_hashes['ea_ex5'],
        'config_ini': os.path.abspath(ini_path),
        'deployed_config_sha256': expected_hashes['config_ini'],
        'remote_expert': remote_expert,
        'remote_config': remote_ini,
        'remote_hash_output': remote_hash,
    }
    with open(os.path.join(run_out, 'deployment_manifest.json'), 'w', encoding='utf-8') as fh:
        json.dump(manifest, fh, indent=2)
    print(f'remote artifacts verified: Experts/{remote_expert}, MQL5/{remote_ini}')
    stop_file = os.path.abspath(args.stop_file) if args.stop_file else os.path.join(run_out, 'STOP')
    done_file = os.path.join(run_out, 'DONE')
    monitor_process = None
    print(f'monitor URL: {args.monitor_url} | early stop: {stop_file}')
    if (args.monitor_interval and args.monitor_interactive_auth and
            not (os.environ.get('NOVNC_USERNAME') and os.environ.get('NOVNC_PASSWORD'))):
        os.environ['NOVNC_USERNAME'] = input('noVNC username: ')
        os.environ['NOVNC_PASSWORD'] = getpass.getpass('noVNC password: ')

    # clear old report
    ssh(f'podman exec {CONTAINER} sh -c \'rm -f "{CBASE}/ReportTester".* "{CBASE}/{rn}"_ReportTester.* 2>/dev/null\'')
    ssh(f'podman exec {CONTAINER} pkill -f terminal64.exe 2>/dev/null')
    time.sleep(3)

    launch = (f'podman exec -d -e DISPLAY=:1 {CONTAINER} wine '
              f'"C:\\Program Files\\MetaTrader 5\\terminal64.exe" '
              f'"/config:C:\\Program Files\\MetaTrader 5\\MQL5\\{remote_ini_win}"')
    ssh(launch)
    time.sleep(12)
    if args.monitor_interval:
        monitor_process = start_playwright_monitor(
            run_out, stop_file, done_file, args.monitor_interval * 30, args.monitor_url,
            args.monitor_interactive_auth)
    print('launched, polling...')

    early_stop = False
    for i in range(args.max_poll):
        if os.path.exists(stop_file):
            early_stop = True
            print(f'  STOP file detected at poll {i}; terminating backtest')
            ssh(f'podman exec {CONTAINER} pkill -f terminal64.exe 2>/dev/null')
            with open(os.path.join(run_out, 'stopped_early.txt'), 'w', encoding='ascii') as fh:
                fh.write(f'poll={i}\nstop_file={stop_file}\n')
            break
        if monitor_process and monitor_process.poll() is not None:
            early_stop = True
            print('  Playwright monitor exited unexpectedly; terminating backtest')
            ssh(f'podman exec {CONTAINER} pkill -f terminal64.exe 2>/dev/null')
            with open(os.path.join(run_out, 'monitor_error.txt'), 'w', encoding='ascii') as fh:
                fh.write('Playwright monitor exited before the backtest completed\n')
            break
        r = ssh(f'podman exec {CONTAINER} sh -c "ps aux | grep terminal64 | grep -v grep | wc -l"')
        n = r.stdout.strip()
        if n == '0':
            print(f'  backtest finished (poll {i})')
            break
        time.sleep(30)
    else:
        print('  WARNING: poll limit reached')

    open(done_file, 'w', encoding='ascii').close()
    if monitor_process:
        try:
            monitor_process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            monitor_process.terminate()
            monitor_process.wait(timeout=5)

    if early_stop:
        print('EARLY STOP: report analysis skipped because the backtest was intentionally aborted')
        return

    # Rename MT5's fixed ReportTester.* to our timestamped report name
    ssh(f'podman exec {CONTAINER} sh -lc \'cd "{CBASE}" && for f in ReportTester*; do [ -e "$f" ] && mv "$f" "{rn}_$f"; done\'')

    # download report + charts
    variants = ['_ReportTester', '_ReportTester-holding', '_ReportTester-hst', '_ReportTester-mfemae']
    for v in variants:
        extensions = ['html', 'htm'] if v == '_ReportTester' else ['png']
        for ext in extensions:
            remote = f'{CBASE}/{rn}{v}.{ext}'
            tmp = f'/tmp/{rn}{v}.{ext}'
            result = run(SSH + [f'podman cp "{CONTAINER}:{remote}" "{tmp}"'])
            if result.returncode != 0:
                continue
            run(['scp', f'{HOST}:{tmp}', os.path.join(run_out, f'{rn}{v}.{ext}')])

    html = next((os.path.join(run_out, f'{rn}_ReportTester.{ext}')
                 for ext in ('html', 'htm')
                 if os.path.exists(os.path.join(run_out, f'{rn}_ReportTester.{ext}'))), None)
    if html is None or os.path.getsize(html) < 1000:
        print('REPORT DOWNLOAD FAILED'); sys.exit(2)

    here = os.path.dirname(os.path.abspath(__file__))
    subprocess.run([sys.executable, os.path.join(here, 'analyze_report.py'),
                    html, run_out, '--label', args.label])
    print('DONE:', run_out)

if __name__ == '__main__':
    main()
