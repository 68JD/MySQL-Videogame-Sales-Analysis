CREATE DATABASE video_game_project;

USE video_game_project;

CREATE TABLE video_game_sales(
id INT PRIMARY KEY,
Ranks INT,
GameTitle VARCHAR(200),
Platform VARCHAR(100),
Years VARCHAR(10),  
Genre VARCHAR(100),
Publisher VARCHAR(100),
NorthAmerica DOUBLE,
Europe DOUBLE,
Japan DOUBLE,
Rest_of_World DOUBLE,
Global_sale DOUBLE,
Review DOUBLE
);
# null values in Year 
# Error Code: 1366. Incorrect integer value: '' for column 'Year' at row 144

LOAD DATA INFILE "Video Games Sales.csv"
INTO TABLE video_game_sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"' 
IGNORE 1 LINES 
;
# Error Code: 1265. Data truncated for column 'NorthAmerica' at row 750
# without ENCLOSED BY 

SELECT * FROM video_game_sales;

DESCRIBE video_game_sales;

SELECT COUNT(*) AS Total_Records FROM video_game_sales;
# Total_Records = '1907'

# Finding Blank values in Year Column:
SELECT * 
FROM 
	video_game_sales
WHERE 
	Years = ''
;

# Replacing Blank Values:
SET SQL_SAFE_UPDATES = 0;
UPDATE video_game_sales 
SET Years = NULL WHERE Years = '';

# Modifying the Data-type of Years Column:
ALTER TABLE video_game_sales MODIFY Years YEAR;

# Checking the Data-types:
DESCRIBE video_game_sales;

# Checking Duplicates:
SELECT * 
FROM 
	video_game_sales
GROUP BY 
	id
HAVING 
	COUNT(id) <> 1;

# Total number of Unique Games/Platforms/Genre/Publisher/:
SELECT 
	COUNT(DISTINCT GameTitle) AS unique_games,
    COUNT(DISTINCT Platform) AS unique_platforms,
    COUNT(DISTINCT Genre) AS unique_genre,
    COUNT(DISTINCT Publisher) AS unique_publisher
FROM
	video_game_sales; 
# unique_games = 1519; unique_platforms = 22; unique_genre = 12; 
# unique_publisher = 95

# QUE : Total number of games launched by different platforms 
SELECT 
	DISTINCT Platform,
    COUNT(id) AS Total_games_launched
FROM 
	video_game_sales
GROUP BY 1
ORDER BY 2 DESC
;

# QUE: Which Publisher Launched Maximum Number of Games?
SELECT 
	DISTINCT Publisher,
    COUNT(id) AS Total_games_launched
FROM 
	video_game_sales
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1
;
# 'Electronic Arts' = 341 

# QUE: Year-wise distribution of games 
SELECT 
	Years,
    COUNT(id) AS Total_games
FROM
	video_game_sales
GROUP BY 1
ORDER BY 1
;

# QUE : Genre-wise Total games, Regionwise_Total_Sales, Avg_Reviews 
SELECT
	DISTINCT Genre,
    COUNT(id) AS Total_Games,
    ROUND(SUM(NorthAmerica),2) AS NorthAmerica_Total_Sales,
    ROUND(SUM(Europe),2) AS Europe_Total_Sales,
    ROUND(SUM(Japan),2) AS Japan_Total_Sales,
    ROUND(SUM(Rest_of_World),2) AS Rest_of_World_Total_Sales,
    ROUND(SUM(Global_sale),2) AS Total_Global_sales,
    ROUND(AVG(Review),2) AS Avg_Reviews 
FROM
	video_game_sales
GROUP BY 1
ORDER BY 2 DESC
;

# QUE : Which Game have maximum Global Sale 
SELECT
    id,
    GameTitle,
    Publisher,
    Years,
    Global_sale
FROM
	video_game_sales
WHERE 
	Global_sale = (SELECT MAX(Global_sale) FROM video_game_sales)
;

# QUE : Popular games having ratings more than average rating 
SELECT 
	id,
    GameTitle,
    Publisher,
    Review
FROM 
	video_game_sales
WHERE 
	Review >= (SELECT AVG(Review) FROM video_game_sales)
ORDER BY 4 DESC
;

# Genres Wise Avg_Reviews and Total_Sales:
SELECT 
	Genre,
    ROUND(AVG(Review),2) AS Avg_Review,
    ROUND(SUM(Global_sale),2) AS Total_Sales
FROM 
	video_game_sales
GROUP BY 1
ORDER BY 2 DESC
;

# Fetching each Game Info by id : 
DELIMITER //
CREATE PROCEDURE GameInfo(IN insert_id INT)
BEGIN
	SELECT 
		*
	FROM 
		video_game_sales
	WHERE 
		id = insert_id;
END //

CALL GameInfo(1300);
CALL GameInfo(1760);


# Fetch the Data of games with their names(partial match)
DELIMITER //
CREATE PROCEDURE GameName(IN Input_Name VARCHAR(200))
BEGIN
	SELECT
		* 
	FROM 
		video_game_sales
	WHERE 
		GameTitle LIKE CONCAT('%',Input_Name'%');
END //

CALL GameName('Call of Duty');
CALL GameName('mario');
CALL GameName('evil');

# Creating View for YOY % Growth of Publishers 

CREATE VIEW publisher_yoy_sales AS
	SELECT 
		Publisher,
        Years,
		CONCAT(
			ROUND(
					(
						(SUM(Global_sale)-
							LAG(SUM(Global_sale),1) 
							OVER(PARTITION BY Publisher ORDER BY Years))/
						LAG(SUM(Global_sale),1)
						OVER(PARTITION BY Publisher ORDER BY Years)
					)*100
				,2)
            ,"%")
		AS YOY_Growth
    FROM 
		video_game_sales
	GROUP BY 
		1,2
	ORDER BY 
		1,2
;
SELECT * FROM publisher_yoy_sales;


# Max Global Sales of a each platform
SELECT 
	Platform,
    MAX(Global_sale) AS Maximum_Sales
FROM 
	video_game_sales
GROUP BY 
	1
ORDER BY 
	2 DESC
;

# Top 10 publishers in north america by sales 
SELECT 
	Publisher,
    CONCAT(ROUND(SUM(NorthAmerica),3)," M") AS Total_NorthAmerica_Sales
FROM
	video_game_sales
GROUP BY 
	1
ORDER BY 
	2 DESC
LIMIT 
	10
;

# Top 5 and Bottom 5 reviewed games 
SELECT 
	id,
    GameTitle,
    Review
FROM 
	video_game_sales
ORDER BY 
	3
LIMIT 
	5
;
SELECT 
	id,
    GameTitle,
    Review
FROM 
	video_game_sales
ORDER BY 
	3 DESC
LIMIT 
	5
;

# Top 10 games by ranking 
SELECT 
	GameTitle,
    Ranks
FROM 
	video_game_sales
ORDER BY 
	2 DESC
LIMIT
	10
;

# Top 10 games by Global_Sales
SELECT 
	GameTitle,
    Global_sale
FROM 
	video_game_sales
ORDER BY 
	2 DESC
LIMIT 
	10
;

# Find the top 3 genres by average global sales, 
# but only consider games with average review scores above 75.
SELECT 
	Genre,
    ROUND(AVG(Global_sale),2) AS Avg_Sales,
    ROUND(AVG(Review),2)
FROM 
	video_game_sales
GROUP BY 
	1
HAVING 
	AVG(Review) > 75
ORDER BY 
	2 DESC
LIMIT 
	3
;


# Calculate the percentage of total sales that each region 
# (North America, Europe, Japan, Rest of World) contributes 
# for each publisher.
WITH CTE AS
(
	SELECT 
		Publisher,
		SUM(NorthAmerica) AS NA_Sales,
		SUM(Europe) AS Europe_Sales,
		SUM(Japan) AS Japan_Sales,
		SUM(Rest_of_World) AS Rest_Sales,
		SUM(Global_sale) AS Global_Sales
	FROM
		video_game_sales
	GROUP BY 
		1
)
SELECT 
	Publisher,
	CONCAT(ROUND((NA_Sales / Global_Sales)* 100,2),'%') AS '%NA_Sales',
    CONCAT(ROUND((Europe_Sales / Global_Sales)*100,2),'%') AS '%Europe_Sales',
    CONCAT(ROUND((Japan_Sales / Global_Sales)* 100,2),'%') AS '%Japan_Sales',
    CONCAT(ROUND((Rest_Sales / Global_Sales)* 100,2),'%') AS '%Rest_Sales'
FROM 
	CTE
;

# Find games that have sold more in Europe than in North America, 
# and rank them by the difference.
SELECT 
	id,
    GameTitle,
    Publisher,
    NorthAmerica,
    Europe,
    ROUND(Europe - NorthAmerica,4) AS Sales_Diff
FROM
	video_game_sales
WHERE 
	Europe > NorthAmerica
ORDER BY 
	6 DESC
;

# Identify publishers who have released games in all genres.

SELECT 
	DISTINCT Publisher,
    COUNT(DISTINCT Genre) AS Total_Genre
FROM 
	video_game_sales
GROUP BY 
	1
HAVING 
	Total_Genre = (SELECT COUNT(DISTINCT Genre) FROM video_game_sales)
;

# For each year, find the game that had the highest ratio of North America 
# sales to Global sales.

WITH CTE AS
(
	SELECT
		Years,
        GameTitle,
		ROUND(NorthAmerica/Global_Sale,2) AS Sales_ratio,
        DENSE_RANK() OVER(PARTITION BY Years 
			ORDER BY NorthAmerica/Global_Sale DESC) AS Ranks
	FROM 
		video_game_sales
	WHERE Years IS NOT NULL
	ORDER BY 
		1
)
SELECT
	Years,
    GameTitle,
    Sales_ratio
FROM
	CTE
WHERE 
	Ranks = 1
;


# Create a ranking of platforms based on their total global sales, 
# but only for games released in the last 5 years of your dataset.

SELECT 
	Years,
	Platform,
    ROUND(SUM(Global_sale)) AS Total_Sales
FROM
	video_game_sales 
GROUP BY
	2,1
ORDER BY 
	1 DESC , 3 DESC
;


# Find the genre that has the most consistent sales across all regions 
# (i.e., the smallest variance in percentage of sales across regions).


# Identify games that have significantly outperformed (more than 2 standard 
# deviations above) the average sales for their genre.


# For each publisher, find the genre in which they have the highest 
# average review score.



 
