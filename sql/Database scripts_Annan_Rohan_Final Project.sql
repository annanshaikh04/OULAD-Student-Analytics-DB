-- SET GLOBAL TIMEOUTS FOR LARGE IMPORTS
SET GLOBAL net_read_timeout = 6000;
SET GLOBAL net_write_timeout = 6000;
SET GLOBAL wait_timeout = 6000;

-- STEP 1: CREATE DATABASE
DROP DATABASE IF EXISTS oulad_project;
CREATE DATABASE oulad_project;
USE oulad_project;

-- STEP 2: CREATE TABLES (NORMALIZED STRUCTURE)

-- 📌 StudentPersonal: Contains static student demographic info
CREATE TABLE StudentPersonal (
    id_student INT PRIMARY KEY,
    gender VARCHAR(10),
    region VARCHAR(50),
    highest_education VARCHAR(50),
    disability VARCHAR(10),
    age_band VARCHAR(20)
);

-- 📌 StudentAcademics: Course-specific academic profile of students
CREATE TABLE StudentAcademics(
    enrollment_id INT PRIMARY KEY,
    code_module VARCHAR(10),
    code_presentation VARCHAR(10),
    imd_band VARCHAR(10),
    num_of_prev_attempts INT,
    studied_credits INT
);

-- 📌 Course: All course offerings
CREATE TABLE Course (
    code_module VARCHAR(10),
    code_presentation VARCHAR(10),
    module_presentation_length INT,
    PRIMARY KEY (code_module, code_presentation)
);

-- 📌 Assessment: All assessments given in each course
CREATE TABLE Assessment (
    id_assessment INT PRIMARY KEY,
    code_module VARCHAR(10),
    code_presentation VARCHAR(10),
    assessment_type VARCHAR(50),
    date INT,
    weight INT
);

-- 📌 StudentAssessment: Student submissions and scores
CREATE TABLE StudentAssessment (
    id_assessment INT,
    id_student INT,
    date_submitted INT,
    is_banked VARCHAR(10) DEFAULT 'No',
    score DECIMAL(5,2)
);

-- 📌 StudentRegistration: Course enrollment data
CREATE TABLE StudentRegistration (
    Registration_id INT PRIMARY KEY,
    code_module VARCHAR(10),
    code_presentation VARCHAR(10),
    id_student INT,
    date_registration INT,
    date_unregistration INT DEFAULT NULL
);

-- 📌 VLE: All online activities by module
CREATE TABLE Vle (
    id_site INT PRIMARY KEY,
    code_module VARCHAR(10),
    code_presentation VARCHAR(10),
    activity_type VARCHAR(50),
    week_from INT,
    week_to INT
);

-- 📌 StudentVle: Student interaction with VLE activities
CREATE TABLE StudentVle (
    code_module VARCHAR(10),
    code_presentation VARCHAR(10),
    id_student INT,
    id_site INT,
    date INT,
    sum_click INT
);

-- STEP 3: DATA VALIDATION QUERIES (OPTIONAL LOGGING)
SELECT COUNT(*) AS row_count FROM StudentVle;
SELECT * FROM StudentAssessment WHERE id_student IS NULL;
SELECT DISTINCT id_student FROM StudentAssessment WHERE id_student NOT IN (SELECT id_student FROM StudentPersonal);
SELECT DISTINCT id_student FROM StudentRegistration WHERE id_student NOT IN (SELECT id_student FROM StudentPersonal);

-- STEP 4: ADD MISSING STUDENT RECORDS FOR FK CONSTRAINTS (Placeholder values)
-- Use bulk INSERT INTO StudentPersonal for missing students
-- (...values inserted here as provided...)

-- STEP 5: ADD FOREIGN KEY CONSTRAINTS
ALTER TABLE StudentAcademics
ADD CONSTRAINT fk_studentacademics_course FOREIGN KEY (code_module, code_presentation) REFERENCES Course(code_module, code_presentation);

ALTER TABLE Assessment
ADD CONSTRAINT fk_assessment_course FOREIGN KEY (code_module, code_presentation) REFERENCES Course(code_module, code_presentation);

ALTER TABLE StudentAssessment
ADD CONSTRAINT fk_studentassessment_student FOREIGN KEY (id_student) REFERENCES StudentPersonal(id_student);

ALTER TABLE StudentAssessment
ADD CONSTRAINT fk_studentassessment_assessment FOREIGN KEY (id_assessment) REFERENCES Assessment(id_assessment);

ALTER TABLE StudentRegistration
ADD CONSTRAINT fk_registration_course FOREIGN KEY (code_module, code_presentation) REFERENCES Course(code_module, code_presentation);

ALTER TABLE StudentRegistration
ADD CONSTRAINT fk_registration_student FOREIGN KEY (id_student) REFERENCES StudentPersonal(id_student);

ALTER TABLE Vle
ADD CONSTRAINT fk_vle_course FOREIGN KEY (code_module, code_presentation) REFERENCES Course(code_module, code_presentation);

-- StudentVle → Vle & StudentPersonal (Large tables require safe mode)
SET FOREIGN_KEY_CHECKS = 0;
ALTER TABLE StudentVle
ADD CONSTRAINT fk_studentvle_site FOREIGN KEY (id_site) REFERENCES Vle(id_site);
ALTER TABLE StudentVle
ADD CONSTRAINT fk_studentvle_student FOREIGN KEY (id_student) REFERENCES StudentPersonal(id_student);
SET FOREIGN_KEY_CHECKS = 1;

-- STEP 6: ADD CHECK CONSTRAINTS
ALTER TABLE StudentPersonal
ADD CONSTRAINT chk_gender CHECK (gender IN ('M', 'F'));

UPDATE StudentPersonal SET disability = 'Yes' WHERE disability = 'Y';
UPDATE StudentPersonal SET disability = 'No' WHERE disability = 'N';

ALTER TABLE StudentPersonal
ADD CONSTRAINT chk_disability CHECK (disability IN ('Yes', 'No'));

ALTER TABLE Assessment
ADD CONSTRAINT chk_weight CHECK (weight >= 0 AND weight <= 100);

ALTER TABLE StudentAssessment
ADD CONSTRAINT chk_score CHECK (score >= 0);

-- STEP 7: INDEXING FOR QUERY OPTIMIZATION
CREATE INDEX idx_region ON StudentPersonal(region);
CREATE INDEX idx_course ON StudentAcademics(code_module, code_presentation);
CREATE INDEX idx_assessments_module ON Assessment(code_module);
CREATE INDEX idx_student ON StudentAssessment(id_student);
CREATE INDEX idx_registration ON StudentRegistration(code_module, code_presentation);
CREATE INDEX idx_vle_activity ON Vle(activity_type);
CREATE INDEX idx_studentvle ON StudentVle(id_student);

-- STEP 8: CREATE RESTRICTED VIEWS
CREATE OR REPLACE VIEW view_basic_student_info AS
SELECT id_student, gender, region, highest_education, age_band FROM StudentPersonal;

CREATE OR REPLACE VIEW view_high_scorers AS
SELECT id_student, AVG(score) AS avg_score FROM StudentAssessment GROUP BY id_student HAVING avg_score >= 80;

CREATE OR REPLACE VIEW view_low_scorers AS
SELECT id_student, AVG(score) AS avg_score FROM StudentAssessment GROUP BY id_student HAVING avg_score < 40;

CREATE OR REPLACE VIEW view_vle_usage AS
SELECT id_student, SUM(sum_click) AS total_clicks FROM StudentVle GROUP BY id_student;

-- STEP 9: ANALYTICAL QUERIES
-- Total students by region
SELECT region, COUNT(*) AS total_students FROM StudentPersonal GROUP BY region ORDER BY total_students DESC;

-- Avg. score by course
SELECT A.code_module, A.code_presentation, ROUND(AVG(SA.score), 2) AS average_score FROM StudentAssessment SA JOIN Assessment A ON SA.id_assessment = A.id_assessment GROUP BY A.code_module, A.code_presentation ORDER BY average_score DESC;

-- Top 5 VLE activity types
SELECT V.activity_type, COUNT(SV.id_site) AS total_usage FROM StudentVle SV JOIN Vle V ON SV.id_site = V.id_site GROUP BY V.activity_type ORDER BY total_usage DESC LIMIT 5;

-- Withdrawal rate per course
SELECT code_module, code_presentation, COUNT(CASE WHEN date_unregistration IS NOT NULL THEN 1 END) AS withdrawals, COUNT(*) AS total_students, ROUND((COUNT(CASE WHEN date_unregistration IS NOT NULL THEN 1 END) / COUNT(*)) * 100, 2) AS withdrawal_rate FROM StudentRegistration GROUP BY code_module, code_presentation;

-- Assessments per course
SELECT code_module, code_presentation, COUNT(*) AS total_assessments FROM Assessment GROUP BY code_module, code_presentation;

-- Pass vs Fail distribution
SELECT CASE WHEN avg_score >= 40 THEN 'Pass' ELSE 'Fail' END AS result, COUNT(*) AS student_count FROM (SELECT id_student, AVG(score) AS avg_score FROM StudentAssessment GROUP BY id_student) AS student_avg GROUP BY result;

-- Total clicks per student
SELECT id_student, SUM(sum_click) AS total_clicks FROM StudentVle GROUP BY id_student ORDER BY total_clicks DESC;

-- Weekly click trend
SELECT date, SUM(sum_click) AS total_clicks FROM StudentVle GROUP BY date ORDER BY date;

-- Avg. previous attempts by course
SELECT code_module, ROUND(AVG(num_of_prev_attempts), 2) AS avg_attempts FROM StudentAcademics GROUP BY code_module;

-- Courses with most dropouts
SELECT code_module, COUNT(*) AS dropout_count FROM StudentRegistration WHERE date_unregistration IS NOT NULL GROUP BY code_module ORDER BY dropout_count DESC;

-- STEP 10: USER ROLES
CREATE USER 'readonly_user'@'localhost' IDENTIFIED BY 'Readonly@123';
GRANT SELECT ON oulad_project.* TO 'readonly_user'@'localhost';

CREATE USER 'admin_user'@'localhost' IDENTIFIED BY 'Admin@123';
GRANT ALL PRIVILEGES ON oulad_project.* TO 'admin_user'@'localhost';

FLUSH PRIVILEGES;

-- STEP 11: FINAL CLEANUP
SET FOREIGN_KEY_CHECKS=1;
COMMIT;

-- USE DATABASE
USE oulad_project;

-- STORED PROCEDURE: InsertNewStudent
-- Safely inserts a new student into StudentPersonal table
-- Performs validations on gender, disability, and duplicate id
DELIMITER $$
CREATE PROCEDURE InsertNewStudent(
    IN p_id_student INT,
    IN p_gender VARCHAR(10),
    IN p_region VARCHAR(50),
    IN p_highest_education VARCHAR(50),
    IN p_disability VARCHAR(10),
    IN p_age_band VARCHAR(20)
)
BEGIN
    IF EXISTS (SELECT 1 FROM StudentPersonal WHERE id_student = p_id_student) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student already exists';
    ELSEIF p_gender NOT IN ('M', 'F') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid gender';
    ELSEIF p_disability NOT IN ('Yes', 'No') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid disability';
    ELSE
        INSERT INTO StudentPersonal(id_student, gender, region, highest_education, disability, age_band)
        VALUES (p_id_student, p_gender, p_region, p_highest_education, p_disability, p_age_band);
    END IF;
END$$
DELIMITER ;

-- TEST PROCEDURE EXECUTION
CALL InsertNewStudent(888888, 'M', 'Scotland', 'HE Qualification', 'No', '35-55');

-- AUDIT TABLE: WithdrawalLog
-- Stores audit log when a student withdraws from a course
CREATE TABLE WithdrawalLog (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    id_student INT,
    code_module VARCHAR(10),
    code_presentation VARCHAR(10),
    date_unregistration INT,
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TRIGGER: trg_log_withdrawals
-- Logs new unregistration dates into WithdrawalLog automatically
DELIMITER $$
CREATE TRIGGER trg_log_withdrawals
AFTER UPDATE ON StudentRegistration
FOR EACH ROW
BEGIN
    IF NEW.date_unregistration IS NOT NULL AND OLD.date_unregistration IS NULL THEN
        INSERT INTO WithdrawalLog (id_student, code_module, code_presentation, date_unregistration)
        VALUES (NEW.id_student, NEW.code_module, NEW.code_presentation, NEW.date_unregistration);
    END IF;
END$$
DELIMITER ;

-- AUDIT TABLE: ScoreAuditLog
-- Tracks score updates in StudentAssessment
CREATE TABLE ScoreAuditLog (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    id_student INT,
    id_assessment INT,
    old_score DECIMAL(5,2),
    new_score DECIMAL(5,2),
    date_submitted INT,
    audit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TRIGGER: trg_audit_score_update
-- Audits any change in StudentAssessment score values
DELIMITER $$
CREATE TRIGGER trg_audit_score_update
AFTER UPDATE ON StudentAssessment
FOR EACH ROW
BEGIN
    IF OLD.score <> NEW.score THEN
        INSERT INTO ScoreAuditLog (
            id_student, id_assessment,
            old_score, new_score,
            date_submitted
        )
        VALUES (
            NEW.id_student, NEW.id_assessment,
            OLD.score, NEW.score,
            NEW.date_submitted
        );
    END IF;
END$$
DELIMITER ;

-- SAMPLE UPDATE TO TRIGGER SCORE AUDIT
UPDATE StudentAssessment
SET score = 85.00
WHERE id_student = 2298895 AND id_assessment = 54663;