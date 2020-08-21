#######################################
###R Intro - Final Exercise
#######################################

library(DBI)
library(dplyr)

conn <- dbConnect(odbc::odbc(), "COLLEGE", timeout = 10)

### Get the all 5 original COLLEGE DataBase tables

Classrooms <- dbGetQuery(conn, 'SELECT * FROM "COLLEGE"."dbo"."Classrooms"')
Courses <- dbGetQuery(conn, 'SELECT * FROM "COLLEGE"."dbo"."Courses"')
Departments <- dbGetQuery(conn, 'SELECT * FROM "COLLEGE"."dbo"."Departments"')
Students <- dbGetQuery(conn, 'SELECT * FROM "COLLEGE"."dbo"."Students"')
Teachers <- dbGetQuery(conn, 'SELECT * FROM "COLLEGE"."dbo"."Teachers"')


dbDisconnect(conn)

 
### Questions
### Q1. Count the number of students on each department

class_student <- inner_join(Classrooms, Students, by="StudentId")
class_course <- left_join(class_student, Courses, by="CourseId")
course_department <- left_join(class_course, Departments, by = c("DepartmentID" ="DepartmentId"))

result1 <- course_department %>%                   
           group_by(DepartmentName) %>%         
           summarise('Number of Students' = n_distinct(StudentId))

result1

### Q2. How many students have each course of the English department and the total number of students in the department?

# Create table with the English department courses data only
result2 <- course_department %>%
           filter(DepartmentName=='English') %>%
           group_by(CourseName) %>%
           summarise('Number of Students' = n_distinct(StudentId))
result2 

# Find the total number of students in the English department

Total_students <- course_department %>%
  filter(DepartmentName=='English') %>%
  summarise(n_distinct(StudentId)) %>%
  as.numeric()

sprintf("The total number of English students is %i", Total_students)


### Q3. How many small (<22 students) and large (22+ students) classrooms are needed for the Science department?

# Create table with science department courses (DepartmentID=2)
Science_courses <- class_course %>%
                   filter(DepartmentID==2) %>%
                   group_by(CourseName) %>%
                   summarise('Number of Students' = n_distinct(StudentId))

Science_courses <- Science_courses %>%
                   mutate(Classroom_size= if_else(`Number of Students`< 22,"Small classroom","Big classroom"))


result3 <- Science_courses %>%
           group_by(Classroom_size) %>%
           summarise('Number of classrooms' = n())

result3


### Q4. A feminist student claims that there are more male than female in the College. Justify if the argument is correct

result4 = Students %>%
          group_by(Gender) %>%
          summarise('Number of Students' = n_distinct(StudentId))

result4

### Q5. For which courses the percentage of male/female students is over 70%?

result5 <- class_course %>% 
           mutate(Female_student= if_else(Gender== "F",1,0)) %>%
           group_by(CourseName) %>%
           summarise('Student_percent' = mean(Female_student)*100)

result5 <- result5 %>% 
           filter(Student_percent > 70 | Student_percent < 30) %>%
           mutate(Gender= if_else(Student_percent> 70,"F","M"))

### Q6. For each department, how many students passed with a grades over 80?

result6 <- course_department %>%
           filter(degree > 80) %>%
           group_by(DepartmentName) %>%
           summarise('Number of Students' = n_distinct(StudentId))         

result6

### Q7. For each department, how many students passed with a grades under 60?

result7 <- course_department %>%
           filter(degree < 60) %>%
           group_by(DepartmentName) %>%
           summarise('Number of Students' = n_distinct(StudentId))         

result7

### Q8. Rate the teachers by their average student's grades (in descending order).

teacher_course <- left_join(class_course, Teachers, by="TeacherId")

teacher_course <- teacher_course %>% 
                  mutate(Teacher=paste0(FirstName.y, " ", LastName.y))
 

result8 <- teacher_course %>%
                 group_by(Teacher) %>%
                 summarise('Avg_degrees' = mean(degree)) %>%
                 arrange(desc(Avg_degrees))

result8

### Q9. Create a dataframe showing the courses, departments they are associated with, the teacher in each course, and the number of students enrolled in the course (for each course, department and teacher show the names).

course_students <- left_join(teacher_course, Departments, by = c("DepartmentID" ="DepartmentId"))

result9 <- course_students %>%
           select(CourseId, CourseName, DepartmentName, Teacher, StudentId)


result9 <- result9 %>%
           group_by(CourseId, CourseName) %>%
           summarise(DepartmentName = min(DepartmentName),
                     Teacher = min(Teacher),
                     'Number of Students' = n_distinct(StudentId))
result9

### Q10. Create a dataframe showing the students, the number of courses they take, the average of the grades per class, and their overall average (for each student show the student name).

result10 <- course_department %>% 
            mutate(English_grade=NA, Arts_grade=NA, Science_grade=NA, Sports_grade=NA)


result10$English_grade <- ifelse(result10$DepartmentName=='English', result10$degree, NA)
result10$Arts_grade <- ifelse(result10$DepartmentName=='Arts', result10$degree, NA)
result10$Science_grade <- ifelse(result10$DepartmentName=='Science', result10$degree, NA)
result10$Sports_grade <- ifelse(result10$DepartmentName=='Sport', result10$degree, NA)

result10 <- result10 %>%
            select(StudentId, FirstName, LastName, CourseId, English_grade, Arts_grade, Science_grade, Sports_grade) %>%
            rename(Courses = CourseId)

result10 <- result10 %>%
            group_by(StudentId) %>%
            summarise(FirstName = min(FirstName),
                      LastName = min(LastName),
                      Courses = n_distinct(Courses),
                      English_grade = mean(English_grade, na.rm = TRUE),
                      Arts_grade = mean(Arts_grade, na.rm = TRUE),
                      Science_grade = mean(Science_grade, na.rm = TRUE),
                      Sports_grade = mean(Sports_grade, na.rm = TRUE))

result10 <- result10 %>%
            mutate(result10, Avarage_grade = rowMeans(select(result10, ends_with("grade")), na.rm = TRUE))

result10
