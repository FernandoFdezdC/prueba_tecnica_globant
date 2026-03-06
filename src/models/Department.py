from sqlalchemy import Column, Integer, String
from services.database import Base


class Department(Base):
    __tablename__ = "departments"
    __table_args__ = {"schema": "db_migration_ddbb"}

    department_id = Column(
        Integer,
        primary_key=True,
        autoincrement=True,
        comment="Unique identifier of the department",
    )

    department_name = Column(
        String(255),
        nullable=False,
        comment="Name of the department",
    )