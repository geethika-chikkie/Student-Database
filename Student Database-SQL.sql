-- ============================================================
-- 1. SCHEMA CREATION
-- ------------------------------------------------------------
-- We start by creating a separate schema to keep all student 
-- management tables organized in one place. 
-- If an old schema exists, we remove it first.
-- ============================================================
DROP SCHEMA IF EXISTS student_management CASCADE;
CREATE SCHEMA IF NOT EXISTS student_management;

-- ============================================================
-- 2. USER LOGIN TABLE
-- ------------------------------------------------------------
-- Stores login credentials and basic information for users 
-- (like students, teachers, or administrators).
-- ============================================================
DROP TABLE IF EXISTS student_management.user_login;
CREATE TABLE IF NOT EXISTS student_management.user_login (
    user_id TEXT PRIMARY KEY,      -- Unique username or ID
    user_password TEXT,            -- Password (should ideally be hashed)
    first_name TEXT,               -- First name of the user
    last_name TEXT,                -- Last name of the user
    sign_up_on DATE,               -- Date when the user signed up
    email_id TEXT UNIQUE           -- Unique email address
);

-- ============================================================
-- 3. PARENT DETAILS TABLE
-- ------------------------------------------------------------
-- Stores details about students' parents or guardians.
-- ============================================================
DROP TABLE IF EXISTS student_management.parent_details;
CREATE TABLE IF NOT EXISTS student_management.parent_details (
    parent_id TEXT PRIMARY KEY,       -- Unique parent identifier
    father_first_name TEXT,
    father_last_name TEXT,
    father_email_id TEXT UNIQUE,
    father_mobile TEXT,
    father_occupation TEXT,
    mother_first_name TEXT,
    mother_last_name TEXT,
    mother_email_id TEXT UNIQUE,
    mother_mobile TEXT,
    mother_occupation TEXT
);

-- ============================================================
-- 4. TEACHERS TABLE
-- ------------------------------------------------------------
-- Stores information about teachers.
-- ============================================================
DROP TABLE IF EXISTS student_management.teachers;
CREATE TABLE IF NOT EXISTS student_management.teachers (
    teacher_id TEXT PRIMARY KEY,      -- Unique teacher identifier
    first_name TEXT,
    last_name TEXT,
    date_of_birth DATE,
    email_id TEXT UNIQUE,
    contact TEXT,
    registration_date DATE,
    registration_id TEXT UNIQUE       -- Government or school registration number
);

-- ============================================================
-- 5. CLASS DETAILS TABLE
-- ------------------------------------------------------------
-- Stores classes information like which teacher is in charge.
-- ============================================================
DROP TABLE IF EXISTS student_management.class_details;
CREATE TABLE IF NOT EXISTS student_management.class_details (
    class_id TEXT PRIMARY KEY,        -- Unique class identifier
    class_teacher TEXT REFERENCES student_management.teachers (teacher_id), -- Class teacher
    class_year TEXT                   -- Year of the class (e.g., 2025)
);

-- ============================================================
-- 6. STUDENT DETAILS TABLE
-- ------------------------------------------------------------
-- Stores information about all students.
-- ============================================================
DROP TABLE IF EXISTS student_management.student_details;
CREATE TABLE IF NOT EXISTS student_management.student_details (
    student_id TEXT PRIMARY KEY,       -- Unique student identifier
    first_name TEXT,
    last_name TEXT,
    date_of_birth DATE,
    class_id TEXT REFERENCES student_management.class_details (class_id) ON DELETE CASCADE,
    roll_no TEXT,                      -- Roll number within class
    email_id TEXT UNIQUE,              -- Student email
    parent_id TEXT REFERENCES student_management.parent_details (parent_id) ON DELETE CASCADE,
    registration_date DATE,
    registration_id TEXT UNIQUE,       -- Unique admission registration number
    UNIQUE(roll_no, class_id)          -- Prevents duplicate roll numbers in the same class
);

-- ============================================================
-- 7. SUBJECT TABLE
-- ------------------------------------------------------------
-- Stores subjects like Math, Science, etc., with a teacher in charge.
-- ============================================================
DROP TABLE IF EXISTS student_management.subject;
CREATE TABLE IF NOT EXISTS student_management.subject (
    subject_id TEXT PRIMARY KEY,        -- Unique subject code
    subject_name TEXT,                  -- Subject name (e.g., Mathematics)
    class_year TEXT,                    -- Year applicable
    subject_head TEXT REFERENCES student_management.teachers (teacher_id) -- Subject head teacher
);

-- ============================================================
-- 8. SUBJECT TUTORS TABLE
-- ------------------------------------------------------------
-- Maps subjects to teachers and classes (a subject can have 
-- multiple teachers for different classes).
-- ============================================================
DROP TABLE IF EXISTS student_management.subject_tutors;
CREATE TABLE IF NOT EXISTS student_management.subject_tutors (
    row_id SERIAL PRIMARY KEY,
    subject_id TEXT REFERENCES student_management.subject (subject_id) ON DELETE CASCADE,
    teacher_id TEXT REFERENCES student_management.teachers (teacher_id),
    class_id TEXT REFERENCES student_management.class_details (class_id) ON DELETE CASCADE
);

-- ============================================================
-- 9. EXAM RESULTS TABLE (NEW FEATURE)
-- ------------------------------------------------------------
-- Stores exam results for students, linking students to 
-- subjects and calculating grades automatically.
-- ============================================================
DROP TABLE IF EXISTS student_management.exam_results;
CREATE TABLE IF NOT EXISTS student_management.exam_results (
    result_id SERIAL PRIMARY KEY,   -- Unique result identifier
    student_id TEXT REFERENCES student_management.student_details(student_id) ON DELETE CASCADE,
    subject_id TEXT REFERENCES student_management.subject(subject_id) ON DELETE CASCADE,
    exam_date DATE NOT NULL,        -- Date of the exam
    marks_obtained NUMERIC(5,2) CHECK (marks_obtained >= 0),
    max_marks NUMERIC(5,2) CHECK (max_marks > 0),
    grade TEXT GENERATED ALWAYS AS ( -- Automatically computed grade
        CASE 
            WHEN marks_obtained >= 90 THEN 'A+'
            WHEN marks_obtained >= 80 THEN 'A'
            WHEN marks_obtained >= 70 THEN 'B'
            WHEN marks_obtained >= 60 THEN 'C'
            WHEN marks_obtained >= 50 THEN 'D'
            ELSE 'F'
        END
    ) STORED
);

-- ============================================================
-- 10. INDEXES FOR PERFORMANCE
-- ------------------------------------------------------------
-- Adding indexes to speed up search queries for common lookups.
-- ============================================================
CREATE INDEX idx_student_class ON student_management.student_details(class_id);
CREATE INDEX idx_subject_class ON student_management.subject_tutors(class_id);
CREATE INDEX idx_exam_results_student ON student_management.exam_results(student_id);
CREATE INDEX idx_exam_results_subject ON student_management.exam_results(subject_id);

-- ============================================================
-- 11. VIEW FOR EASY REPORTING
-- ------------------------------------------------------------
-- Combines student details, subject names, and exam results 
-- into one view for simplified queries.
-- ============================================================
DROP VIEW IF EXISTS student_management.student_grades_view;
CREATE VIEW student_management.student_grades_view AS
SELECT 
    s.student_id,
    s.first_name AS student_first_name,
    s.last_name AS student_last_name,
    sub.subject_name,
    e.exam_date,
    e.marks_obtained,
    e.max_marks,
    e.grade
FROM student_management.exam_results e
JOIN student_management.student_details s ON e.student_id = s.student_id
JOIN student_management.subject sub ON e.subject_id = sub.subject_id;
