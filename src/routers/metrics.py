from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

router = APIRouter(
    prefix="/metrics",  # add common prefix
    tags=["metrics"],
)

'''------------------------------------------
----------### DB METRICS ROUTERS ###---------
------------------------------------------'''


from models.Department import Department
from models.HiredEmployee import HiredEmployee
from models.Job import Job

from services.database import get_db
from sqlalchemy import text

# ============================================================
# 1. Hires by quarter
# ============================================================

@router.get("/hires-by-quarter")
def hires_by_quarter(db: Session = Depends(get_db)):

    sql = text("""
        SELECT 
            d.department_name AS department,
            j.job_name AS job,
            SUM(CASE WHEN QUARTER(e.hire_datetime) = 1 THEN 1 ELSE 0 END) AS Q1,
            SUM(CASE WHEN QUARTER(e.hire_datetime) = 2 THEN 1 ELSE 0 END) AS Q2,
            SUM(CASE WHEN QUARTER(e.hire_datetime) = 3 THEN 1 ELSE 0 END) AS Q3,
            SUM(CASE WHEN QUARTER(e.hire_datetime) = 4 THEN 1 ELSE 0 END) AS Q4
        FROM hired_employees e
        JOIN departments d ON e.department_id = d.department_id
        JOIN jobs j ON e.job_id = j.job_id
        WHERE YEAR(e.hire_datetime) = 2021
        GROUP BY d.department_name, j.job_name
        ORDER BY d.department_name ASC, j.job_name ASC
    """)

    result = db.execute(sql).mappings().all()

    return result

# ============================================================
# 2. Departments above mean
# ============================================================

@router.get("/departments-above-mean")
def departments_above_mean(db: Session = Depends(get_db)):

    sql = text("""
        WITH department_totals AS (
            SELECT 
                d.department_id,
                d.department_name,
                COUNT(e.employee_id) AS hired
            FROM hired_employees e
            JOIN departments d ON e.department_id = d.department_id
            WHERE YEAR(e.hire_datetime) = 2021
            GROUP BY d.department_id, d.department_name
        ),
        mean_value AS (
            SELECT AVG(hired) AS avg_hired FROM department_totals
        )

        SELECT 
            dt.department_id,
            dt.department_name,
            dt.hired
        FROM department_totals dt
        CROSS JOIN mean_value mv
        WHERE dt.hired > mv.avg_hired
        ORDER BY dt.hired DESC;
    """)

    result = db.execute(sql).mappings().all()

    return result