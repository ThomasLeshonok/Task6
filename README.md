# TASK 6

Fake user contact generator. All data is produced by MySQL stored procedures (a "Faker" in SQL); the Python
Streamlit app only calls them and renders the result.

Stored procedure reference, arguments and algorithms: [docs/stored_procedures.md](docs/stored_procedures.md).

## Run locally (Windows PowerShell, XAMPP)

Start MySQL in the XAMPP Control Panel, then run these commands from the project folder:

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
C:\xampp\mysql\bin\mysql.exe -u root -e "CREATE DATABASE IF NOT EXISTS faker CHARACTER SET utf8mb4"
python src/setup_db.py
streamlit run streamlit_app.py
```

`.env.example` already points at XAMPP (`DATABASE_URL=mysql://root@localhost:3306/faker`); change it for another
server. `python src/setup_db.py` runs every file under `sql/` (schema first, then each locale); run it again after
changing anything there. It drops and recreates only `faker_` objects. The files can also be imported by hand, in
order, with phpMyAdmin or the `mysql` client (they use `DELIMITER $$`). Every other setting has a default in
`src/fakerdb/config.py` and can be overridden in `.env` (see `.env.example`).

## Tests

```powershell
python -m pytest tests
```

`tests/test_procedures.py` runs against the database from `DATABASE_URL` (skipped when it is unreachable):
reproducibility, independence from batch size, uniform distribution on the sphere, normal distribution,
weighted choice frequencies, lookup table sizes, Markov text, the border tiles against the whole border, and the
procedures that inline a draw for speed against the ones they copy. `tests/test_app_logic.py` needs no database.

## Benchmark

```powershell
python src/benchmark.py --users 10000 100000 --locales en_US de_DE --workers 6
```

The benchmark does not use `DATABASE_URL`. It starts a new, empty server on a free local port, from `mariadbd` or
`mysqld` on `PATH` or else XAMPP's `C:\xampp\mysql\bin\mysqld.exe` (`--mysqld` picks another binary). It installs
the schema there, runs every locale with every user count, then shuts the server down and deletes its files. The
XAMPP server on port 3306 and the hosted database are not touched, and every run starts from the same clean state
with the server's default settings.

Each run is split into calls of `--chunk` users (1,000) on `--workers` parallel connections, so a run needs at
least chunk x workers users to keep every connection busy. `faker_benchmark_users` generates the users inside the
database without sending them back; `--fetch` downloads them instead, end to end. At the end it prints a table per
run, the average users per second of each locale (all its users over all its seconds) and the total time. For
example, `--users 10000 --workers 6` on XAMPP's MariaDB 10.4 (PC with 12 logical CPUs):

```
Average generated users per second:
  English (United States) (en_US): 281
  Deutsch (Deutschland) (de_DE): 265
  All locales: 272
Total time: 1 min 25 s, of which generating users 1 min 13 s
```

The same run gave 165, 196 and 179 users per second before the pick query was forced to a range seek, the border
test moved to precomputed tiles and the Markov loop stopped calling down for every word. More workers do not help
much there: with 12 the server tops out at about 300 users per second, while each user takes twice as long.

`--csv results.csv` also appends the rows to a CSV file. `--use-database-url` benchmarks the database in
`DATABASE_URL` instead (schema already installed; a non-local one also needs `--allow-remote`).

## Layout

| Path | Role |
|------|------|
| `sql/schema/01_tables.sql` | Tables: `faker_locales`, generic `faker_lookup_lists` / `faker_lookup_values` (every word list, template and Markov transition, keyed by locale), `faker_distributions`, `faker_markov_corpus`, `faker_markov_models`, `faker_geo_regions` with their precomputed border tiles `faker_geo_tiles` |
| `sql/schema/02_random.sql` | Counter-based RNG: keys, uniform, integer, Box-Muller normal, uniform point on the sphere |
| `sql/schema/03_lookup.sql` | List loaders and weighted choice (inverse CDF on running weights) |
| `sql/schema/04_text.sql` | Templates (`{placeholder}`, `#`/`%` digit masks), ASCII folding, decimals |
| `sql/schema/05_person.sql` … `07_physical.sql` | Name, e-mail, phone, address, location inside the border (with its tiles), body attributes |
| `sql/schema/08_markov.sql` | Markov chain training and text generation |
| `sql/schema/09_api.sql` | Public procedures: `faker_list_locales`, `faker_generate_user(s)`, `faker_generate_text` |
| `sql/schema/10_sampling.sql` | Many draws of one primitive, for checking distributions and the border tiles; `faker_benchmark_users` |
| `sql/schema/11_profiling.sql` | `faker_profile_users` (time per step of a user), `faker_profile_primitives` (time per call of each building block) |
| `sql/locales/<locale>/` | Data of one locale: names, addresses, phones, e-mails, body measures, corpus, border polygons (`05_geo.sql`) |
| `tools/build_regions.py` | Writes `05_geo.sql` from Natural Earth admin-0 countries (one-off data preparation) |
| `src/fakerdb/config.py` | All settings and their defaults, read from the environment |
| `src/fakerdb/models.py` | `Locale`, `BatchRequest`, `TextRequest`, `FakeUser` |
| `src/fakerdb/ports.py` | Interfaces: `QueryRunner`, `ScriptRunner`, `LocaleSource`, `UserSource`, `TextSource` |
| `src/fakerdb/connection.py` | `DATABASE_URL` and TLS settings to PyMySQL connection arguments |
| `src/fakerdb/database.py` | Small thread-safe connection pool; runs procedure calls and scripts |
| `src/fakerdb/repository.py` | `StoredProcedureFaker`: calls the stored procedures, maps rows to models |
| `src/fakerdb/sql_script.py` | Splits SQL files into statements, honouring `DELIMITER` |
| `src/fakerdb/installer.py` | Finds the SQL files in order and applies them |
| `src/setup_db.py` | CLI entry: installs the schema and locales |
| `src/fakerdb/benchmark.py` | Splits a run into position ranges, runs them on parallel connections, adds up the times |
| `src/fakerdb/local_server.py` | Throwaway MySQL / MariaDB server for the benchmark: new data directory, free port, deleted afterwards |
| `src/benchmark.py` | CLI entry: users-per-second benchmark on a throwaway server, Markdown table, averages per locale, optional CSV |
| `src/fakerdb/profiler.py` | Runs the profiling procedures in parallel, `cProfile` of the fetch path in worker processes, per-layer totals |
| `src/bottlenecks.py` | CLI entry: slowest procedures, steps and Python functions as Markdown tables |
| `src/webapp/state.py` | Locale / seed / batch navigation on session state (plain functions, unit tested) |
| `src/webapp/controls.py`, `views.py` | Streamlit sidebar, users table and card, map, text tab |
| `streamlit_app.py` | Entry point: settings, caching, wiring |

## Deploy for free: Streamlit Community Cloud + Aiven MySQL

Streamlit Community Cloud runs only the Python app; the database lives at Aiven (free MySQL plan: 1 CPU, 1 GB RAM,
1 GB storage, no credit card, no expiry). The faker data takes a few MB.

1. **Database.** Sign up at aiven.io > Create service > MySQL > Free plan > pick a region close to the US (where
   Streamlit Community Cloud runs) > Create. When it is *Running*, open the service *Overview* and copy the
   *Service URI* (`mysql://avnadmin:<password>@<host>:<port>/defaultdb?ssl-mode=REQUIRED`). Optionally download
   the *CA certificate* (`ca.pem`) to also verify the server certificate.
2. **Install the schema once, from your computer.** Put the URI in `.env`:
   ```
   DATABASE_URL=mysql://avnadmin:<password>@<host>:<port>/defaultdb?ssl-mode=REQUIRED
   # optional, stricter TLS:
   DB_SSL_MODE=VERIFY_CA
   DB_SSL_CA=ca.pem
   ```
   then run `python src/setup_db.py` (about a minute over the internet). `python -m pytest tests` now tests the
   hosted database.
3. **App.** share.streamlit.io > Create app > pick the repository and branch, main file `streamlit_app.py`.
   Advanced settings: Python 3.13, and paste the secrets:
   ```toml
   DATABASE_URL = "mysql://avnadmin:<password>@<host>:<port>/defaultdb?ssl-mode=REQUIRED"
   DB_SSL_MODE = "VERIFY_CA"
   DB_SSL_CA = """-----BEGIN CERTIFICATE-----
   ...contents of ca.pem...
   -----END CERTIFICATE-----"""
   ```
   (`DB_SSL_MODE` and `DB_SSL_CA` can be left out; `ssl-mode=REQUIRED` in the URI still encrypts the connection.)


