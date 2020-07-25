
/****** Script for using COLLEGE DB  ******/

use COLLEGE
go

/**** question 2a - number  of students at each department ******/

SELECT c.Departmentname, count(DISTINCT a.studentID) as [# of Students]  
FROM Classrooms AS a
LEFT OUTER JOIN Courses AS b
	ON a.CourseId = b.CourseId

	LEFT OUTER JOIN Departments AS c
	ON b.DepartmentID = c.DepartmentId

	GROUP BY c.DepartmentName


/**** question 2b (part1)- number of english students in each course ******/

SELECT b.CourseName, count(DISTINCT a.studentID) as [# of English Students]   
FROM Classrooms AS a
LEFT OUTER JOIN Courses AS b
	ON a.CourseId = b.CourseId

	LEFT OUTER JOIN Departments AS c
	ON b.DepartmentID = c.DepartmentId

	WHERE c.DepartmentName = 'English'
	GROUP BY b.CourseName


/**** question 2b (part2)- number  of english students in total ******/

SELECT count(DISTINCT a.studentID) as [# of English Students]  
FROM Classrooms AS a
LEFT OUTER JOIN Courses AS b
	ON a.CourseId = b.CourseId

	LEFT OUTER JOIN Departments AS c
	ON b.DepartmentID = c.DepartmentId

	WHERE c.DepartmentName = 'English'

/**** question 2c - number of Classes size for science department (small - under 22 students / big - 22 and more students) ******/

DROP TABLE dbo.Sciencetable
SELECT b.CourseName, count(DISTINCT a.studentID) as [# of Science classes] 
into dbo.Sciencetable
FROM Classrooms AS a
LEFT OUTER JOIN Courses AS b
	ON a.CourseId = b.CourseId

	LEFT OUTER JOIN Departments AS c
	ON b.DepartmentID = c.DepartmentId

	WHERE c.DepartmentName = 'Science'
	GROUP BY b.CourseName
	ORDER BY [# of Science classes]


ALTER TABLE dbo.Sciencetable ADD [Category] nvarchar(50)

UPDATE dbo.Sciencetable
SET [Category] = 'Small Class';
UPDATE dbo.Sciencetable 
SET [Category] = 'Big Class'
WHERE [# of Science classes]>=22 ;

select [Category] ,count([coursename]) as [# of Classes Needed]
from dbo.Sciencetable
group by [Category]



/**** question 2d - Whether there's a Gender Discrimination ******/

select gender, count(distinct studentid) as [# of Students]  
from dbo.Students
group by Gender

/**** question 2e - Gender mix by course ******/

drop table dbo.courses_gender_mix
SELECT b.CourseName, count(DISTINCT c.studentID) as [# of Students], c.Gender 
into dbo.courses_gender_mix
FROM Classrooms AS a
LEFT OUTER JOIN Courses AS b
	ON a.CourseId = b.CourseId

	LEFT OUTER JOIN Students AS c
	ON a.StudentId = c.StudentId
GROUP BY c.Gender, b.CourseName 

DROP TABLE dbo.gender_pvt
CREATE TABLE dbo.gender_pvt (CourseName nvarchar(50), F float , M float , Fmix DECIMAL(5,2))


INSERT INTO dbo.gender_pvt
SELECT *
FROM dbo.courses_gender_mix
PIVOT  
(  
SUM ([# of Students])  
FOR Gender IN  
( F,M , Fmix)  
) AS PVT
ORDER BY CourseName;


UPDATE dbo.gender_pvt
SET Fmix = F/(F+M)*100;

SELECT * FROM dbo.gender_pvt
WHERE Fmix>70.00 or Fmix<30.00 


/**** question 2F - number of students (value & Percentage) with grade over 80 at each department ******/

/** create temporary table for total students by departmant****/
DROP TABLE #students
CREATE TABLE  #students (DepartmentName nvarchar(255), [# of students] float)
INSERT INTO  #students

SELECT c.Departmentname, count(DISTINCT a.studentID) as [# of Students]
FROM Classrooms AS a
LEFT OUTER JOIN Courses AS b
	ON a.CourseId = b.CourseId

	LEFT OUTER JOIN Departments AS c
	ON b.DepartmentID = c.DepartmentId
		gROUP BY c.DepartmentName
--select * from #students

/** create temporary table for students with grade over 80 by departmant****/
DROP TABLE #Degree80
CREATE TABLE #Degree80 (DepartmentName nvarchar(255), [# of Students Grade>80] float)
INSERT INTO #Degree80

SELECT c.Departmentname, count(DISTINCT a.studentID) as [# of Students]
FROM Classrooms AS a
LEFT OUTER JOIN Courses AS b
	ON a.CourseId = b.CourseId

	LEFT OUTER JOIN Departments AS c
	ON b.DepartmentID = c.DepartmentId
	where a.degree>80
	gROUP BY c.DepartmentName

--select * from #Degree80

/** create temporary table to have percentage column by departmant****/
DROP TABLE #PERCENT

CREATE TABLE #PERCENT (DepartmentName nvarchar(255),[# of Students] float, [# of Students Grade>80] float,[Percent Grade>80] DECIMAL(5,2))
INSERT INTO #PERCENT
select a.DepartmentName, a.[# of Students], b.[# of Students Grade>80], b.[# of Students Grade>80] as [Percent Grade>80]
from #students as a
inner join #Degree80 as b
on a.departmentname=b.departmentname
UPDATE #PERCENT
SET  [Percent Grade>80] = [# of Students Grade>80]/[# of students]*100;
select * from #PERCENT



/**** question 2G - number of students (value & Percentage) with grade less than 60 at each department ******/

/** create temporary table for total students by departmant****/

DROP TABLE #students
CREATE TABLE  #students (DepartmentName nvarchar(255), [# of students] float)
INSERT INTO  #students

SELECT c.Departmentname, count(DISTINCT a.studentID) as [# of Students]
FROM Classrooms AS a
LEFT OUTER JOIN Courses AS b
	ON a.CourseId = b.CourseId

	LEFT OUTER JOIN Departments AS c
	ON b.DepartmentID = c.DepartmentId
		gROUP BY c.DepartmentName


/** create temporary table for students with grade less 60 by departmant****/
DROP TABLE #Degree60
CREATE TABLE #Degree60 (DepartmentName nvarchar(255), [# of Students Grade<60] float)
INSERT INTO #Degree60

SELECT c.Departmentname, count(DISTINCT a.studentID) as [# of Students]
FROM Classrooms AS a
LEFT OUTER JOIN Courses AS b
	ON a.CourseId = b.CourseId

	LEFT OUTER JOIN Departments AS c
	ON b.DepartmentID = c.DepartmentId
	where a.degree<60
	gROUP BY c.DepartmentName

/** create temporary table to have percentage column by departmant****/

DROP TABLE #PERCENT60
CREATE TABLE #PERCENT60 (DepartmentName nvarchar(255),[# of students] float, [# of Students Grade<60] float,[Percent Grade<60] DECIMAL(5,2))
INSERT INTO #PERCENT60
select a.DepartmentName, a.[# of Students], b.[# of Students Grade<60],b.[# of Students Grade<60] as [Percent Grade<60]
from #students as a
inner join #Degree60 as b
on a.departmentname=b.departmentname
UPDATE #PERCENT60
SET  [Percent Grade<60] = [# of Students Grade<60]/[# of students]*100;
select * from #PERCENT60






/**** question 2H - Descnding order of teachers by avarage degree   ****/

/** create temporary table for total students by departmant****/


SELECT a.TeacherID, a.FirstName, a.Lastname, CAST(AVG(c.degree *1.0) AS DECIMAL(5,1)) AS AverageDEG

FROM Teachers AS a
LEFT OUTER JOIN Courses AS b
	ON a.TeacherID = b.TeacherID

	LEFT OUTER JOIN Classrooms AS c
	ON b.CourseID = c.CourseID
	
GROUP BY a.TeacherId, a.FirstName, a.Lastname
ORDER BY  AverageDEG DESC


/**** question 3a - View of departments-coursews-techers-#students ******/

drop view dataview
CREATE VIEW dataview AS
 SELECT c.Departmentname,b.coursename,d.teacherid, d.FirstName,d.lastname, count(DISTINCT a.studentID) as [# of Students]  
 FROM Classrooms AS a
 full OUTER JOIN Courses AS b
	 ON a.CourseId = b.CourseId
 full OUTER JOIN Departments AS c
	 ON b.DepartmentID = c.DepartmentId
 full OUTER JOIN teachers AS d
	 ON b.TeacherId = d.TeacherId
 GROUP BY c.Departmentname,b.coursename,d.teacherid, d.FirstName,d.lastname
-- ORDER BY  c.DepartmentName, d.teacherid



/**** question 3b - View Students by # of Courses, average degree according to departments and overall average degree  ******/

create table studentavg (studentid int, avgdegree decimal(5,2))
insert into studentavg
select StudentId,CAST(AVG(degree *1.0) AS DECIMAL(5,2)) as overallavg 
from classrooms group by StudentId
order by StudentId

select * from  studentavg
order by StudentId

DROP VIEW dataview1
CREATE VIEW dataview1 AS
SELECT a.StudentId, a.FirstName, a.LastName, d.DepartmentName,count(distinct c.CourseID) AS [# of Courses] , CAST(AVG(b.degree *1.0) AS DECIMAL(5,2)) AS CourseAVG, e.avgdegree AS OverallAVG 
FROM Students AS a
LEFT OUTER JOIN Classrooms AS b
	ON a.StudentId = b.StudentId

	LEFT OUTER JOIN Courses AS c
	ON b.CourseId = c.CourseId

	LEFT OUTER JOIN Departments AS d
	ON c.DepartmentID = d.DepartmentId

	LEFT OUTER JOIN studentavg AS e
	ON a.StudentId = e.studentid
GROUP BY a.StudentId, a.FirstName, a.LastName, d.DepartmentName, e.avgdegree

