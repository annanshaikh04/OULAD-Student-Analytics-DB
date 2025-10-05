import mysql.connector
import pandas as pd
from tqdm import tqdm
from sql_password import sql_details

# Connect to MySQL
conn = mysql.connector.connect(
    host=sql_details['MYSQL_HOST'],
    user=sql_details['MYSQL_USER'],
    password=sql_details['MYSQL_PASSWORD'],
    database='oulad_project'
)

cursor = conn.cursor()
path = "D:/Data_Management/Normalized/"


def insert_data(csv_file, query, required_columns, table_name, batch_size=1000):
    df = pd.read_csv(csv_file)
    df = df[required_columns]  # Filter required columns
    df = df.where(pd.notnull(df), None)  # Replace NaN with None

    data = [tuple(row) for _, row in df.iterrows()]

    print(f"Inserting data into {table_name}...")
    for i in tqdm(range(0, len(data), batch_size), desc=f"{table_name}", unit="batch"):
        batch = data[i:i+batch_size]
        cursor.executemany(query, batch)
        conn.commit()

    print(f"✅ Data inserted from {csv_file} to {table_name}.\n")


# Insert data for each table
insert_data(path + 'STUDENT_PERSONAL.csv', """
    INSERT INTO StudentPersonal (id_student, gender, region, highest_education, disability, age_band)
    VALUES (%s, %s, %s, %s, %s, %s)
""", ['id_student', 'gender', 'region', 'highest_education', 'disability', 'age_band'], "StudentPersonal")

insert_data(path + 'STUDENT_ACADEMIC.csv', """
    INSERT INTO StudentAcademics (enrollment_id, code_module, code_presentation, imd_band, num_of_prev_attempts, studied_credits)
    VALUES (%s, %s, %s, %s, %s, %s)
""", ['enrollment_id', 'code_module', 'code_presentation', 'imd_band', 'num_of_prev_attempts', 'studied_credits'], "StudentAcademics")

insert_data(path + 'COURSES.csv', """
    INSERT INTO Course (code_module, code_presentation, module_presentation_length)
    VALUES (%s, %s, %s)
""", ['code_module', 'code_presentation', 'module_presentation_length'], "Course")

insert_data(path + 'ASSESSMENTS.csv', """
    INSERT INTO Assessment (id_assessment, code_module, code_presentation, assessment_type, date, weight)
    VALUES (%s, %s, %s, %s, %s, %s)
""", ['id_assessment', 'code_module', 'code_presentation', 'assessment_type', 'date', 'weight'], "Assessment")

insert_data(path + 'STUDENT_ASSESSMENT.csv', """
    INSERT INTO StudentAssessment (id_assessment, id_student, date_submitted, is_banked, score)
    VALUES (%s, %s, %s, %s, %s)
""", ['id_assessment', 'id_student', 'date_submitted', 'is_banked', 'score'], "StudentAssessment")

insert_data(path + 'STUDENT_REGISTRATION.csv', """
    INSERT INTO StudentRegistration (Registration_id, code_module, code_presentation, id_student, date_registration, date_unregistration)
    VALUES (%s, %s, %s, %s, %s, %s)
""", ['Registration_id', 'code_module', 'code_presentation', 'id_student', 'date_registration', 'date_unregistration'], "StudentRegistration")

insert_data(path + 'VLE.csv', """
    INSERT INTO Vle (id_site, code_module, code_presentation, activity_type, week_from, week_to)
    VALUES (%s, %s, %s, %s, %s, %s)
""", ['id_site', 'code_module', 'code_presentation', 'activity_type', 'week_from', 'week_to'], "Vle")

insert_data(path + 'STUDENT_VLE.csv', """
    INSERT INTO StudentVle (code_module, code_presentation, id_student, id_site, date, sum_click)
    VALUES (%s, %s, %s, %s, %s, %s)
""", ['code_module', 'code_presentation', 'id_student', 'id_site', 'date', 'sum_click'], "StudentVle")

# Close connection
cursor.close()
conn.close()

print("🎉 All Data Inserted Successfully!")
