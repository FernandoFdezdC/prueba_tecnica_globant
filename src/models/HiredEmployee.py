from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from services.database import Base


class HiredEmployee(Base):
    __tablename__ = "hired_employees"
    __table_args__ = {"schema": "db_migration_ddbb"}

    employee_id = Column(
        Integer,
        primary_key=True,
        index=True,
        comment="Employee ID",
    )

    employee_name = Column(
        String(255),
        nullable=False,
    )

    hire_datetime = Column(
        DateTime,
        nullable=False,
        comment="Hire datetime (ISO format)",
    )

    department_id = Column(
        Integer,
        ForeignKey("db_migration_ddbb.departments.department_id", ondelete="RESTRICT"),
        nullable=False,
    )

    job_id = Column(
        Integer,
        ForeignKey("db_migration_ddbb.jobs.job_id", ondelete="RESTRICT"),
        nullable=False,
    )

    department = relationship("Department")
    job = relationship("Job")