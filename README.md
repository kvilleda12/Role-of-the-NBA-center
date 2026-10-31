# Role of the NBA center

Investigating how the role of NBA big men has changed.

## Environment

Python 3.14.5 with DuckDB, pandas, and an IPython notebook kernel is installed in `.venv`.

```sh
source .venv/bin/activate
```

Open `Dataset_built.ipynb` and select the project's `.venv/bin/python` interpreter
or the **Python (NBA Center)** kernel. To recreate the environment:

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements.lock.txt
.venv/bin/python -m ipykernel install --sys-prefix --name nba-center --display-name 'Python (NBA Center)'
```

`requirements.txt` pins direct dependencies; `requirements.lock.txt` records the
complete installed environment. The lock reflects macOS ARM64 / Python 3.14.

## Source verification and current blocker

`Data/nba.duckdb` is byte-for-byte identical to the file downloaded from
[Wyatt Walsh's NBA Database on Kaggle](https://www.kaggle.com/datasets/wyattowalsh/basketball)
on October 31, 2026. Both are 12,288 bytes and contain **zero tables**.

SHA-256: `e507ee3e10ae6f57180779e68b3a94db0575566b063bb6d997fa83815507a5e6`.

The published `run_summary.json` also reports zero extracted rows. The same
release includes older CSV files and a SQLite file, but its listed CSV inventory
has no player-season statistics or player box-score table. A check of
`csv/common_player_info.csv` found only generic positions such as `Forward`,
`Center`, and `Forward-Center`; it does not distinguish power forwards from small
forwards. These files cannot establish the requested strict big-man cohort.

See `reports/source_verification.json` for evidence and saved published metadata
in `reports/kaggle_*`. Recheck any replacement database read-only with:

```sh
.venv/bin/python scripts/inspect_database.py Data/nba.duckdb --output reports/database_inspection.json
```

## Requested condensed dataset

The intended window is **1980–81 through 2024–25**, exactly 45 seasons, using
season start years 1980 through 2024. It is a season filter, not a calendar-date
filter. No condensed database has been created because the source is empty.

Once a populated source with player statistics and specific positions is
available, retain only `C`, `PF`, `C/PF`, and `PF/C` (including equivalent spelled-out
labels and separators). Exclude `SF/PF`, `PF/SF`, every other position mixture,
missing positions, and ambiguous generic `Forward` / `Forward-Center` labels.
Check whether positions are recorded per season or only once per player before
using them for historical analysis. Audit all 45 seasons for missing coverage.

Keep regular season and playoff statistics distinguishable if both are present;
never sum career totals or duplicate team stints into season totals. The actual
schema and coverage must be inspected before implementing that transformation.
