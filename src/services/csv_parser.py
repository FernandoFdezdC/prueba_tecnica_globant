# src/services/csv_parser.py
from datetime import datetime
import csv
import io
from typing import List, Dict, Optional


def parse_datetime(value: str) -> Optional[datetime]:
    """Parse ISO-ish datetime (e.g. 2021-07-27T16:02:08Z) -> datetime or None."""
    if value is None:
        return None
    value = value.strip()
    if value == "":
        return None
    # remove trailing Z and whitespace
    value = value.replace("Z", "").strip()
    try:
        return datetime.fromisoformat(value)
    except ValueError as e:
        raise ValueError(f"Invalid datetime format: {value}") from e


def parse_departments_csv(content: str, min_rows=1, max_rows=1000) -> List[Dict]:
    reader = csv.reader(io.StringIO(content))
    rows = []
    for row in reader:
        if not row or len(row) < 2:
            continue
        try:
            rows.append({
                "department_id": int(row[0].strip()),
                "department_name": row[1].strip(),
            })
        except Exception as e:
            raise ValueError(f"Invalid department row: {row}") from e

    if not min_rows <= len(rows) <= max_rows:
        raise ValueError(f"Rows must be between {min_rows} and {max_rows}")
    return rows


def parse_jobs_csv(content: str, min_rows=1, max_rows=1000) -> List[Dict]:
    reader = csv.reader(io.StringIO(content))
    rows = []
    for row in reader:
        if not row or len(row) < 2:
            continue
        try:
            rows.append({
                "job_id": int(row[0].strip()),
                "job_name": row[1].strip(),
            })
        except Exception as e:
            raise ValueError(f"Invalid job row: {row}") from e

    if not min_rows <= len(rows) <= max_rows:
        raise ValueError(f"Rows must be between {min_rows} and {max_rows}")
    return rows


def parse_employees_csv(content: str, min_rows=1, max_rows=10000) -> List[Dict]:
    reader = csv.reader(io.StringIO(content))
    rows = []

    for row in reader:
        # skip empty rows
        if not row or len(row) < 5:
            continue

        def to_int_or_none(v: str):
            if v is None:
                return None
            s = v.strip()
            return int(s) if s != "" else None

        try:
            rows.append({
                "employee_id": to_int_or_none(row[0]),
                "employee_name": row[1].strip() if row[1] else None,
                "hire_datetime": parse_datetime(row[2]) if row[2] else None,
                "department_id": to_int_or_none(row[3]),
                "job_id": to_int_or_none(row[4]),
            })
        except ValueError as e:
            raise
        except Exception as e:
            raise ValueError(f"Invalid employee row: {row}") from e

    if not min_rows <= len(rows) <= max_rows:
        raise ValueError(f"Rows must be between {min_rows} and {max_rows}")
    return rows