"""
Extract the 'Deals' (成交) section and the 'Result Summary' from an MT5 Strategy Tester HTML report.
"""
import sys
import csv
import warnings
warnings.filterwarnings("ignore")

from html.parser import HTMLParser
from pathlib import Path

_ZH_TO_EN = {
    "时间":     "Time",
    "成交":     "Deal",
    "交易品种": "Symbol",
    "类型":     "Type",
    "趋势":     "Direction",
    "交易量":   "Volume",
    "价位":     "Price",
    "订单":     "Order",
    "手续费":   "Commission",
    "库存费":   "Swap",
    "盈利":     "Profit",
    "结余":     "Balance",
    "注释":     "Comment",
}

class _TableParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.tables: list[list[list[str]]] = []
        self._in_table = self._in_row = self._in_cell = False
        self._table: list[list[str]] = []
        self._row: list[str] = []
        self._cell = ""

    def handle_starttag(self, tag, attrs):
        t = tag.lower()
        if t == "table":
            self._in_table = True; self._table = []
        elif t == "tr" and self._in_table:
            self._in_row = True; self._row = []
        elif t in ("td", "th") and self._in_row:
            self._in_cell = True; self._cell = ""

    def handle_endtag(self, tag):
        t = tag.lower()
        if t == "table" and self._in_table:
            self._in_table = False; self.tables.append(self._table)
        elif t == "tr" and self._in_row:
            self._in_row = False; self._table.append(self._row)
        elif t in ("td", "th") and self._in_cell:
            self._in_cell = False; self._row.append(self._cell.strip())

    def handle_data(self, data):
        if self._in_cell:
            self._cell += data

def _read_html(path: Path) -> str:
    raw = path.read_bytes()
    for enc in ("utf-16", "utf-8", "latin-1"):
        try:
            return raw.decode(enc)
        except (UnicodeDecodeError, UnicodeError):
            continue
    raise RuntimeError(f"Cannot decode {path}")

def extract_deals_csv(html_path: str, output_dir: str) -> bool:
    html_file = Path(html_path)
    if not html_file.exists():
        print(f"ERROR: file not found: {html_path}")
        return False

    parser = _TableParser()
    parser.feed(_read_html(html_file))

    if len(parser.tables) < 2:
        print("ERROR: expected at least 2 tables in the MT5 HTML report.")
        return False

    # Extract Summary Table (Table 0)
    try:
        summary_path = Path(output_dir) / "summary.csv"
        summary_table = parser.tables[0]
        with open(summary_path, "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            for row in summary_table:
                cleaned_row = [c.replace("\\n", " ").strip() for c in row if c.replace("\\n", " ").strip()]
                if cleaned_row:
                    # Form pairs
                    if len(cleaned_row) >= 2:
                        for i in range(0, len(cleaned_row), 2):
                            if i+1 < len(cleaned_row):
                                w.writerow([cleaned_row[i], cleaned_row[i+1]])
                            else:
                                w.writerow([cleaned_row[i], ""])
                    else:
                        w.writerow(cleaned_row)
        print(f"OK: summary.csv -> {summary_path}")
    except Exception as e:
        print(f"Warning: Cannot write summary.csv: {e}")

    table = parser.tables[1] 

    deals_start = None
    for i, row in enumerate(table):
        non_empty = [c for c in row if c.strip()]
        if len(non_empty) == 1 and non_empty[0] == "成交":
            deals_start = i + 1 
            break

    if deals_start is None:
        for i, row in enumerate(table):
            non_empty = [c for c in row if c.strip()]
            if len(non_empty) == 1 and non_empty[0] == "Deals":
                deals_start = i + 1
                break

    if deals_start is None:
        print("ERROR: Cannot find the Deals/成交 section in the HTML report.")
        return False

    zh_header = table[deals_start]
    en_header = [_ZH_TO_EN.get(h, h) for h in zh_header]

    while en_header and en_header[-1] == "":
        en_header.pop()
    col_count = len(en_header)

    csv_path = Path(output_dir) / "deals.csv"
    data_rows = 0
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(en_header)
        for row in table[deals_start + 1:]:
            first = row[0].strip() if row else ""
            if first == "" and all(c.strip() == "" for c in row[:col_count]):
                break
            writer.writerow([c for c in row[:col_count]])
            data_rows += 1

    size_kb = csv_path.stat().st_size / 1024
    print(f"OK: deals.csv -> {csv_path}  ({data_rows} deals, {size_kb:.1f} KB)")
    return True

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: python {sys.argv[0]} <report.html> <output_dir>")
        sys.exit(1)
    ok = extract_deals_csv(sys.argv[1], sys.argv[2])
    sys.exit(0 if ok else 1)