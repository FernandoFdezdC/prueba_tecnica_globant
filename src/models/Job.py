from sqlalchemy import Column, Integer, String
from services.database import Base

class Job(Base):
    __tablename__ = "jobs"
    __table_args__ = {"schema": "db_migration_ddbb"}

    job_id = Column(
        Integer,
        primary_key=True,
        autoincrement=True,
        comment="Unique identifier of the job",
    )

    job_name = Column(
        String(255),
        nullable=False,
        comment="Name of the job position",
    )