 
IF OBJECT_ID('hencom_SPNCostOfTransportVarSubContQueryNew') IS NOT NULL   
    DROP PROC hencom_SPNCostOfTransportVarSubContQueryNew  
GO  
  
-- v2017.04.18 
  
-- �����ȹ��ۺ񺯼����_hencom-���޺���ȸ by ����õ
CREATE PROC hencom_SPNCostOfTransportVarSubContQueryNew  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @docHandle  INT, 
            @PlanSeq    INT, 
            @DeptSeq    INT          
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                     
    
    SELECT @PlanSeq = ISNULL(PlanSeq,0), 
           @DeptSeq = ISNULL(DeptSeq,0) 
    
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags) 
    WITH ( 
            PlanSeq    INT,
            DeptSeq    INT 
         )
    
    CREATE TABLE #Value1
    (    
        Gubun       INT, 
        ColumnA     NVARCHAR(100), 
        ColumnB     NVARCHAR(100), 
        ColumnC     NVARCHAR(100), 
        PrevPlan    DECIMAL(19,5),
        PrevSales   DECIMAL(19,5),
        PrevRate    DECIMAL(19,5),
        Sales       DECIMAL(19,5),
        Mth1        DECIMAL(19,5),
        Mth2        DECIMAL(19,5),
        Mth3        DECIMAL(19,5),
        Mth4        DECIMAL(19,5),
        Mth5        DECIMAL(19,5),
        Mth6        DECIMAL(19,5),
        Mth7        DECIMAL(19,5),
        Mth8        DECIMAL(19,5),
        Mth9        DECIMAL(19,5),
        Mth10       DECIMAL(19,5),
        Mth11       DECIMAL(19,5),
        Mth12       DECIMAL(19,5),
        Total       DECIMAL(19,5)
    )  
    
    CREATE TABLE #Value2
    (    
        Gubun       INT, 
        ColumnA     NVARCHAR(100), 
        ColumnB     NVARCHAR(100), 
        ColumnC     NVARCHAR(100), 
        Sales       DECIMAL(19,5),
        Mth1        DECIMAL(19,5),
        Mth2        DECIMAL(19,5),
        Mth3        DECIMAL(19,5),
        Mth4        DECIMAL(19,5),
        Mth5        DECIMAL(19,5),
        Mth6        DECIMAL(19,5),
        Mth7        DECIMAL(19,5),
        Mth8        DECIMAL(19,5),
        Mth9        DECIMAL(19,5),
        Mth10       DECIMAL(19,5),
        Mth11       DECIMAL(19,5),
        Mth12       DECIMAL(19,5),
        Total       DECIMAL(19,5)
    )        

    CREATE TABLE #Result        
    (    
        Gubun       INT, 
        ColumnA     NVARCHAR(100), 
        ColumnB     NVARCHAR(100), 
        ColumnC     NVARCHAR(100), 
        Sales       DECIMAL(19,5),
        Mth1        DECIMAL(19,5),
        Mth2        DECIMAL(19,5),
        Mth3        DECIMAL(19,5),
        Mth4        DECIMAL(19,5),
        Mth5        DECIMAL(19,5),
        Mth6        DECIMAL(19,5),
        Mth7        DECIMAL(19,5),
        Mth8        DECIMAL(19,5),
        Mth9        DECIMAL(19,5),
        Mth10       DECIMAL(19,5),
        Mth11       DECIMAL(19,5),
        Mth12       DECIMAL(19,5),
        Total       DECIMAL(19,5)
    )

    --���⵵ �����߿� Ȯ������   
    DECLARE @Year NCHAR(4), 
            @PrevCfmPlanSeq INT, 
            @PrevYear NCHAR(4)  
        
    SELECT @Year = PlanYear 
      FROM hencom_TPNPlan    
     WHERE CompanySeq = @CompanySeq    
       AND PlanSeq = @PlanSeq    
  
    SELECT @PrevYear = CONVERT(INT,@Year)-1    
      
  --���⵵ �����߿� Ȯ������    
     SELECT @PrevCfmPlanSeq = PlanSeq     
     FROM hencom_TPNPlan WITH(NOLOCK)     
     WHERE CompanySeq = @CompanySeq     
     AND PlanYear = @PrevYear     
     AND IsCfm = '1'     

    EXEC hencom_SPNCostOfTransportVarSubContNew_SubQuery @CompanySeq, @DeptSeq, @PlanSeq 
    
    INSERT INTO #Value1 -- �̹��⵵ �����ȹ
    (
        Gubun     , ColumnA   , ColumnB   , ColumnC   , Sales , 
        Mth1      , Mth2      , Mth3      , Mth4      , Mth5      , 
        Mth6      , Mth7      , Mth8      , Mth9      , Mth10     , 
        Mth11     , Mth12     , Total     
    )
    SELECT * FROM #Result 

    TRUNCATE TABLE #Result 

    EXEC hencom_SPNCostOfTransportVarSubContNew_SubQuery @CompanySeq, @DeptSeq, @PrevCfmPlanSeq 

    INSERT INTO #Value2 -- �����⵵ �����ȹ
    (
        Gubun     , ColumnA   , ColumnB   , ColumnC   , Sales , 
        Mth1      , Mth2      , Mth3      , Mth4      , Mth5      , 
        Mth6      , Mth7      , Mth8      , Mth9      , Mth10     , 
        Mth11     , Mth12     , Total     
    )
    SELECT * FROM #Result 
    
    UPDATE A 
       SET PrevPlan = ISNULL(B.Total,0)
          ,PrevSales = ISNULL(B.Sales,0)
          ,PrevRate = (ISNULL(B.Sales,0) / NULLIF(B.Total,0)) * 100 
      FROM #Value1 AS A 
      JOIN #Value2 AS B ON ( B.Gubun = A.Gubun ) 

    SELECT * FROM #Value1 
    


    RETURN 

go 
begin tran 
exec hencom_SPNCostOfTransportVarSubContQueryNew @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <DeptSeq>44</DeptSeq>
    <PlanSeq>3</PlanSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1510143,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1031995
rollback 