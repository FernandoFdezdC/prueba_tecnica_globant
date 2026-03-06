# tests/test_csv_parsers.py
import pytest
from datetime import datetime
from app.services.csv_parser import (
    parse_departments_csv,
    parse_jobs_csv,
    parse_employees_csv,
    parse_datetime,
)


def test_parse_datetime_ok():
    dt = parse_datetime("2021-11-07T02:48:42Z")
    assert isinstance(dt, datetime)
    assert dt.year == 2021 and dt.month == 11


def test_parse_datetime_empty():
    assert parse_datetime("") is None
    assert parse_datetime("   ") is None


def test_parse_departments_ok():
    content = "1,Product Management\n2,Sales\n"
    rows = parse_departments_csv(content)
    assert len(rows) == 2
    assert rows[0]["department_id"] == 1
    assert rows[1]["department_name"] == "Sales"


def test_parse_departments_invalid_empty():
    with pytest.raises(ValueError):
        parse_departments_csv("")  # no rows => ValueError


def test_parse_jobs_ok():
    content = "1,Recruiter\n2,Manager\n"
    rows = parse_jobs_csv(content)
    assert rows[0]["job_id"] == 1
    assert rows[1]["job_name"] == "Manager"


def test_parse_employees_ok_and_nulls():
    content = "1,Marcelo,2021-07-27T16:02:08Z,1,2\n" \
              "2,Lidia,2021-07-27T19:04:09Z,1,\n"  # job_id empty -> None
    rows = parse_employees_csv(content)
    assert rows[0]["employee_id"] == 1
    assert rows[0]["job_id"] == 2
    assert rows[1]["job_id"] is None
    assert rows[1]["hire_datetime"].year == 2021


def test_parse_employees_bad_datetime():
    bad = "1,John,NOT_A_DATE,1,1\n"
    with pytest.raises(ValueError):
        parse_employees_csv(bad)