from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text, insert
from sqlalchemy.exc import SQLAlchemyError

router = APIRouter(
    tags=["db_migration"],
)

'''------------------------------------------
----------### DB MIGRATION ROUTERS ###---------
------------------------------------------'''


from models.Department import Department
from models.HiredEmployee import HiredEmployee
from models.Job import Job

from services.database import get_db

from fastapi import UploadFile, File
from datetime import datetime
import csv
import io
from services.csv_parser import parse_departments_csv, parse_jobs_csv, parse_employees_csv

# ============================================================
# 1. Upload Departments CSV
# ============================================================

@router.post("/departments")
def overwrite_departments(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    content = file.file.read().decode("utf-8")
    try:
        rows = parse_departments_csv(content)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    if not 1 <= len(rows) <= 1000:
        raise HTTPException(
            status_code=400,
            detail="Rows must be between 1 and 1000",
        )

    try:
        # Start transaction
        db.execute(text("SET FOREIGN_KEY_CHECKS=0"))
        db.execute(text("TRUNCATE TABLE db_migration_ddbb.departments"))

        # Insert new data
        db.execute(insert(Department), rows)

        db.commit()

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail=f"Overwrite failed: {str(e)}",
        )

    finally:
        db.execute(text("SET FOREIGN_KEY_CHECKS=1"))

    return {"message": "Departments table overwritten successfully"}


# ============================================================
# 2. Upload Jobs CSV
# ============================================================

@router.post("/jobs")
def overwrite_jobs(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    content = file.file.read().decode("utf-8")
    try:
        rows = parse_jobs_csv(content)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    if not 1 <= len(rows) <= 1000:
        raise HTTPException(
            status_code=400,
            detail="Rows must be between 1 and 1000",
        )

    try:
        # Transaction start
        db.execute(text("SET FOREIGN_KEY_CHECKS=0"))
        db.execute(text("TRUNCATE TABLE db_migration_ddbb.jobs"))

        # Fast bulk insert (InnoDB optimized)
        db.execute(insert(Job), rows)

        db.commit()

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail=f"Jobs overwrite failed: {str(e)}",
        )

    finally:
        db.execute(text("SET FOREIGN_KEY_CHECKS=1"))

    return {"message": f"{len(rows)} jobs overwritten successfully"}


# ============================================================
# 3. Upload Employees Data
# ============================================================

    
@router.post("/employees")
def overwrite_employees(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    content = file.file.read().decode("utf-8")
    try:
        rows = parse_employees_csv(content)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    if not 1 <= len(rows) <= 10000:
        raise HTTPException(
            status_code=400,
            detail="Rows must be between 1 and 1000",
        )

    try:
        # Disable FK checks for truncate
        db.execute(text("SET FOREIGN_KEY_CHECKS=0"))

        db.execute(text("TRUNCATE TABLE db_migration_ddbb.hired_employees"))

        db.execute(insert(HiredEmployee), rows)

        db.commit()

    except SQLAlchemyError as e:
        print("ERROR:", e)
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail=f"Employees overwrite failed: {str(e)}",
        )

    finally:
        db.execute(text("SET FOREIGN_KEY_CHECKS=1"))

    return {"message": f"{len(rows)} employees overwritten successfully"}