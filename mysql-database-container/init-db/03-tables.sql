CREATE TABLE db_migration_ddbb.departments (
    department_id INT UNSIGNED AUTO_INCREMENT
        PRIMARY KEY
        COMMENT 'Unique identifier of the department. Surrogate key and not natural key',

    department_name VARCHAR(255)
        CHARACTER SET utf8mb4
        COLLATE utf8mb4_unicode_ci
        NOT NULL
        COMMENT 'Name of the department'
)
-- InnoDB is ACID compliant and more efficient
ENGINE=InnoDB;

CREATE TABLE db_migration_ddbb.jobs (
    job_id INT UNSIGNED AUTO_INCREMENT
        PRIMARY KEY
        COMMENT 'Unique identifier of the job',

    job_name VARCHAR(255)
        CHARACTER SET utf8mb4
        COLLATE utf8mb4_unicode_ci
        NOT NULL
        COMMENT 'Name of the job position'
)
-- InnoDB is ACID compliant and more efficient
ENGINE=InnoDB;

CREATE TABLE db_migration_ddbb.hired_employees (
    employee_id INT UNSIGNED
        PRIMARY KEY
        COMMENT 'Unique identifier of the employee (provided in CSV)',

    employee_name VARCHAR(255)
        CHARACTER SET utf8mb4
        COLLATE utf8mb4_unicode_ci
        DEFAULT NULL
        COMMENT 'Full name of the employee',

    hire_datetime DATETIME
        DEFAULT NULL
        COMMENT 'Hire datetime in ISO 8601 format',

    department_id INT UNSIGNED
        DEFAULT NULL
        COMMENT 'Reference to the department where the employee was hired',

    job_id INT UNSIGNED
        DEFAULT NULL
        COMMENT 'Reference to the job position assigned to the employee',

    CONSTRAINT fk_hired_department
        FOREIGN KEY (department_id)
        REFERENCES db_migration_ddbb.departments(department_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_hired_job
        FOREIGN KEY (job_id)
        REFERENCES db_migration_ddbb.jobs(job_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
)
-- InnoDB is ACID compliant and more efficient
ENGINE=InnoDB;