
IF OBJECT_ID('DTI_SPNSalesPurchasePlanTitleQuery') IS NOT NULL 
    DROP PROC DTI_SPNSalesPurchasePlanTitleQuery
GO 

-- v2014.03.28 

-- [�濵��ȹ]�Ǹű��Ű�ȹ�Է�_DTI(Ÿ��Ʋ��ȸ) by����õ
CREATE PROC DTI_SPNSalesPurchasePlanTitleQuery
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
    DECLARE @docHandle  INT, 
            @PlanYear   NCHAR(4) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @PlanYear = ISNULL(PlanYear,'') 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
    
      WITH (PlanYear NCHAR(4) )
    
    CREATE TABLE #Title
    (
        ColIdx      INT IDENTITY (0,1), 
        Title       NVARCHAR(100), 
        TitleSeq    INT, 
        Title2      NVARCHAR(100), 
        TitleSeq2   INT
    
    )
    
    INSERT INTO #Title
    SELECT A.Title, A.TitleSeq, B.Title2, B.TitleSeq2 + A.TitleSeq
      FROM (SELECT @PlanYear + '-01' AS Title, 1 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-02' AS Title, 2 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-03' AS Title, 3 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-04' AS Title, 4 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-05' AS Title, 5 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-06' AS Title, 6 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-07' AS Title, 7 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-08' AS Title, 8 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-09' AS Title, 9 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-10' AS Title, 10 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-11' AS Title, 11 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-12' AS Title, 12 AS TitleSeq
          ) AS A 
      JOIN (SELECT '�ݾ�' AS Title2, 100 AS TitleSeq2) AS B ON ( 1 = 1 ) 
    
    SELECT * FROM #Title 
    
    RETURN
GO
exec DTI_SPNSalesPurchasePlanTitleQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PlanYear>2014</PlanYear>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1021944,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1018429

