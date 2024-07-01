---- Create a Full-Text Catalog
--CREATE FULLTEXT CATALOG ftCatalog AS DEFAULT;

---- Create Full-Text Index on the table
--CREATE FULLTEXT INDEX ON booksummaries(Description) 
--    KEY INDEX PK_booksummaries 
--    WITH STOPLIST = SYSTEM;

---- Create table for vectors
--CREATE TABLE BookVectors (
--    document_id INT,
--    keyword NVARCHAR(255),
--    rank INT
--);

--delete from BookVectors
---- Populate the vectors table
INSERT INTO BookVectors (document_id, keyword, rank)
SELECT 
    document_id,
    keyword,
    occurrence_count as  rank
FROM 
    sys.dm_fts_index_keywords_by_document(DB_ID(), OBJECT_ID('booksummaries'))
	where document_id =1

	SELECT 
    document_id,
    keyword,
    display_term,
    occurrence_count AS rank
FROM 
    sys.dm_fts_index_keywords_by_document(DB_ID(), OBJECT_ID('booksummaries')) where document_id=620;
-- Compute cosine similarity
DECLARE @DocumentID1 INT = 1; -- Replace with your first document ID
DECLARE @DocumentID2 INT = 620; -- Replace with your second document ID

WITH VectorA AS (
    SELECT document_id, keyword, rank
    FROM BookVectors
    WHERE document_id = @DocumentID1
),
VectorB AS (
    SELECT document_id, keyword, rank
    FROM BookVectors
    WHERE document_id = @DocumentID2
),
DotProduct AS (
    SELECT SUM(A.rank * B.rank) AS dot_product
    FROM VectorA AS A
    INNER JOIN VectorB AS B ON A.keyword = B.keyword
),
MagnitudeA AS (
    SELECT SQRT(SUM(rank * rank)) AS magnitude
    FROM VectorA
),
MagnitudeB AS (
    SELECT SQRT(SUM(rank * rank)) AS magnitude
    FROM VectorB
)
SELECT 
    dot_product / (MagnitudeA.magnitude * MagnitudeB.magnitude) AS cosine_similarity
FROM 
    DotProduct, MagnitudeA, MagnitudeB;


-- Compute cosine similarity
create or alter function get_cosine_similarity
( 
 @DocumentID1 INT = 3251094, -- Replace with your first document ID
 @DocumentID2 INT = 6564761 -- Replace with your second document ID
)
returns float
as
begin
declare @similarity float
;WITH VectorA AS (
    SELECT document_id, keyword, rank
    FROM BookVectors
    WHERE document_id = @DocumentID1
),
VectorB AS (
    SELECT document_id, keyword, rank
    FROM BookVectors
    WHERE document_id = @DocumentID2
),
DotProduct AS (
    SELECT SUM(A.rank * B.rank) AS dot_product
    FROM VectorA AS A
    INNER JOIN VectorB AS B ON A.keyword = B.keyword
),
MagnitudeA AS (
    SELECT SQRT(SUM(rank * rank)) AS magnitude
    FROM VectorA
),
MagnitudeB AS (
    SELECT SQRT(SUM(rank * rank)) AS magnitude
    FROM VectorB
)
SELECT 
   @similarity = (dot_product / (MagnitudeA.magnitude * MagnitudeB.magnitude) )
FROM 
    DotProduct, MagnitudeA, MagnitudeB;

	return @similarity
end


select dbo.get_cosine_similarity(620,986)
	



create view vw_booksummaries as
select distinct top 1000  id,NEWID() as randomize from booksummaries order by randomize


create table SimilarityValue
(
firstdocument  int,
seconddocument  int
 
)

alter table dbo.SimilarityValue add similarity as  dbo.get_cosine_similarity(firstdocument,seconddocument)   

insert into SimilarityValue(firstdocument,seconddocument)
select bs.id firstdocument, bs1.id as seconddocument from vw_booksummaries bs cross  join
vw_booksummaries bs1 



select top 100 * from SimilarityValue order by firstdocument desc
