"""
Extract the 'Deals' (成交) section from an MT5 Strategy Tester HTML report
and write it as deals.csv for use by analyze_mt5_report.py.

MT5 writes HTML in UTF-16 LE encoding.  The report's second <table> contains
both the Orders section and the Deals section, separated by a row whose sole
cell reads "成交" (Chinese for "Deals").

Usage: python html_to_xlsx.py <report.html> <output_dir>
"""
import sys
import csv
import warnings
warnings.filterwarnings("ignore")

from html.parser import HTMLParser
from pathlib import Path


# Column name mapping:  Chinese (MT5 HTML) -> English (analyze_mt5_report.py)
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
    """Collect every <table> as a list-of-rows (list of list-of-strings)."""

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

    table = parser.tables[1]          # Orders + Deals are in the 2nd table

    # --- Locate the Deals section by finding the "成交" separator row ------
    deals_start = None
    for i, row in enumerate(table):
        non_empty = [c for c in row if c.strip()]
        if len(non_empty) == 1 and non_empty[0] == "成交":
            deals_start = i + 1      # next row is the header
            break

    # Fallback: search for "Deals" in English (in case of English locale)
    if deals_start is None:
        for i, row in enumerate(table):
            non_empty = [c for c in row if c.strip()]
            if len(non_empty) == 1 and non_empty[0] == "Deals":
                deals_start = i + 1
                break

    if deals_start is None:
        print("ERROR: Cannot find the Deals/成交 section in the HTML report.")
        return False

    # --- Read header and translate to English ------------------------------
    zh_header = table[deals_start]
    en_header = [_ZH_TO_EN.get(h, h) for h in zh_header]

    # Trim trailing empty columns
    while en_header and en_header[-1] == "":
        en_header.pop()
    col_count = len(en_header)

    # --- Write CSV ---------------------------------------------------------
    csv_path = Path(output_dir) / "deals.csv"
    data_rows = 0
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(en_header)
        for row in table[deals_start + 1:]:
            # Stop at the next section or end-of-table filler rows
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
