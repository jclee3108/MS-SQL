  
IF OBJECT_ID('KPX_SPDMPSProdPlanAutoSortSave') IS NOT NULL   
    DROP PROC KPX_SPDMPSProdPlanAutoSortSave  
GO  
  
-- v2014.10.15 
  
-- �ڵ�����-���� by ����õ   
CREATE PROC KPX_SPDMPSProdPlanAutoSortSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250), 
            @CfmMaxDate     NCHAR(12) 
    
    CREATE TABLE #TPDMPSDailyProdPlan( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDMPSDailyProdPlan'   
    IF @@ERROR <> 0 RETURN     
    
    -----------------------------------
    -- �ش� ������ �����ȹ 
    -----------------------------------
    CREATE TABLE #TEMP 
    (   
        IDX_NO      INT IDENTITY, 
        ProdPlanSeq INT, 
        WorkCond4   INT, 
        ProdPlanNo  NCHAR(200), 
        SrtDate     NCHAR(12), 
        EndDate     NCHAR(12),
        ProdMinute  INT 
    ) 
    INSERT INTO #TEMP (ProdPlanSeq, WorkCond4, ProdPlanNo, SrtDate, EndDate, ProdMinute)
    SELECT B.ProdPlanSeq, B.WorkCond4, B.ProdPlanNo, B.SrtDate + B.WorkCond1 AS SrtDate, B.EndDate + B.WorkCond2 AS EndDate, 
           DATEDIFF(Minute, 
                    CONVERT(DATETIME,STUFF(STUFF(STUFF(STUFF(B.SrtDate + B.WorkCond1,5,0,'-'),8,0,'-'),11,0,' '),14,0,':') + ':00.000'), 
                    CONVERT(DATETIME,STUFF(STUFF(STUFF(STUFF(B.EndDate + B.WorkCond2,5,0,'-'),8,0,'-'),11,0,' '),14,0,':') + ':00.000')
                   ) AS ProdMinute
      FROM #TPDMPSDailyProdPlan AS A 
      JOIN _TPDMPSDailyProdPlan AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkCenterSeq = A.WorkCenterSeq ) 
      LEFT OUTER JOIN _TPDMPSDailyProdPlan_Confirm AS C ON ( C.CompanySeq = @CompanySeq AND C.CfmSeq = B.ProdPlanSeq ) 
     WHERE ISNULL(C.CfmCode,'0') = '0' 
       AND B.SrtDate >= CASE WHEN A.IsAll = '1' THEN A.FrDate ELSE A.FrDate END -- ��ü �ϰ�� FrDate, ����,������ ���� ���� 
     ORDER BY SrtDate 
    
    SELECT @CfmMaxDate = MAX(B.EndDate + B.WorkCond2)
      FROM #TPDMPSDailyProdPlan AS A 
      JOIN _TPDMPSDailyProdPlan AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkCenterSeq = A.WorkCenterSeq ) 
      JOIN _TPDMPSDailyProdPlan_Confirm AS C ON ( C.CompanySeq = @CompanySeq AND C.CfmSeq = B.ProdPlanSeq AND C.CfmCode = '1' ) 
     WHERE B.SrtDate >= CASE WHEN A.IsAll = '1' THEN A.FrDate ELSE A.FrDate END -- ��ü �ϰ�� FrDate, ����,������ ���� ���� 
    
    CREATE TABLE #Result
    (
        IDX_NO          INT, 
        ProdPlanSeq     INT,
        WorkCond4       INT, 
        SrtDate         NCHAR(12), 
        EndDate         NCHAR(12), 
        AddTime         INT, 
        SumAProdMinute  INT,
        SumBProdMinute  INT, 
        NewSrtDate      DATETIME, 
        NewEndDate      DATETIME
    )
    
    DECLARE @SrtDate NCHAR(12) 
    
    IF (SELECT TOP 1 IsAutoSort FROM #TPDMPSDailyProdPlan) = '1' -- �ڵ����� 
    BEGIN  
    
    ----------------------------------------------------------
    -- ���� ���ù�ġ �� �� �����ϱ� ���� SrtDate Update 
    ----------------------------------------------------------
    CREATE TABLE #TEMP_SUB
    (
        WorkCond4       INT, 
        SrtDate         NCHAR(12)
    )
    INSERT INTO #TEMP_SUB
    SELECT WorkCond4, MIN(SrtDate) AS SrtDate
      From #TEMP 
     GROUP BY WorkCond4
     ORDER BY SrtDate
    
    UPDATE #TEMP 
        SET SrtDate = A.SrtDate 
      FROM #TEMP_SUB AS A 
      JOIN #TEMP     AS B ON ( B.WorkCond4 = A.WorkCond4 ) 
    
    
    ----------------------------------------
    -- ��� ���� ���ϱ� ���� ���� 
    ----------------------------------------
    CREATE TABLE #Result_Sub
    (
        IDX_NO      INT IDENTITY, 
        ProdPlanSeq INT, 
        WorkCond4   INT, 
        ProdPlanNo  NCHAR(200), 
        SrtDate     NCHAR(12), 
        EndDate     NCHAR(12), 
        ProdMinute  INT
    ) 
    
    INSERT INTO #Result_Sub(ProdPlanSeq, WorkCond4, ProdPlanNo, SrtDate, EndDate,ProdMinute)
    SELECT ProdPlanSeq, WorkCond4, ProdPlanNo, SrtDate, EndDate, ProdMinute
      FROM #TEMP 
     ORDER BY SrtDate, EndDate 
    
    
    SELECT @SrtDate = CASE WHEN ISNULL(@CfmMaxDate,0) > (SELECT SrtDate FROM #Result_Sub WHERE IDX_NO = 1) THEN @CfmMaxDate ELSE (SELECT SrtDate FROM #Result_Sub WHERE IDX_NO = 1) END 
    
    INSERT INTO #Result 
    SELECT A.IDX_NO, 
           A.ProdPlanSeq, 
           A.WorkCond4, -- ���� ������ ���� ���� �ڵ�
           @SrtDate AS SrtDate, -- ������ ���� �ñ� 
           A.EndDate, 
           CASE WHEN ISNULL(DATEDIFF(Minute,
                                     CONVERT(DATETIME,STUFF(STUFF(STUFF(STUFF(B.EndDate,5,0,'-'),8,0,'-'),11,0,' '),14,0,':') + ':00.000'),  
                                     CONVERT(DATETIME,STUFF(STUFF(STUFF(STUFF(A.SrtDate,5,0,'-'),8,0,'-'),11,0,' '),14,0,':') + ':00.000')
                                    ),0) < 0 
                THEN 0 
                ELSE ISNULL(DATEDIFF(Minute,
                                     CONVERT(DATETIME,STUFF(STUFF(STUFF(STUFF(B.EndDate,5,0,'-'),8,0,'-'),11,0,' '),14,0,':') + ':00.000'),
                                     CONVERT(DATETIME,STUFF(STUFF(STUFF(STUFF(A.SrtDate,5,0,'-'),8,0,'-'),11,0,' '),14,0,':') + ':00.000')
                                    ),0)
                END AS AddTime, -- ����ð� 
            C.SumAProdMinute, -- ���� �ñ� ���� �۾��ð� �հ�(End)
            C.SumBProdMinute, -- ���� �ñ� ���� �۾��ð� �հ�(Srt)
            
            DATEADD(Minute,C.SumBprodMinute,CONVERT(DATETIME,STUFF(STUFF(STUFF(STUFF(@SrtDate,5,0,'-'),8,0,'-'),11,0,' '),14,0,':') + ':00.000')) AS NewSrtDate, -- ���ؽð� + �۾��ð�
                   
            DATEADD(Minute,C.SumAprodMinute,CONVERT(DATETIME,STUFF(STUFF(STUFF(STUFF(@SrtDate,5,0,'-'),8,0,'-'),11,0,' '),14,0,':') + ':00.000')) AS NewEndDate -- ���ؽð� + �۾��ð�
      FROM #Result_Sub AS A 
      LEFT OUTER JOIN #Result_Sub AS B ON ( A.IDX_NO - 1 = B.IDX_NO ) 
      OUTER APPLY (SELECT SUM(ISNULL(Z.ProdMinute,0)) AS SumAProdMinute, SUM(ISNULL(Y.ProdMinute,0)) AS SumBProdMinute 
                     FROM #Result_Sub AS Z 
                     LEFT OUTER JOIN #Result_Sub AS Y ON ( Z.IDX_NO - 1 = Y.IDX_NO ) 
                    WHERE Z.IDX_NO <= A.IDX_NO
                  )  AS C 
    
    
    -- ���� �ð� �����ֱ� (�������� ���ؾ� ����)
    UPDATE A
       SET NewSrtDate = DATEADD(Minute,B.AddTime,A.NewSrtDate), 
           NewEndDate = DATEADD(Minute,B.AddTime,A.NewEndDate)
      FROM #Result AS A 
      OUTER APPLY (SELECT SUM(AddTime) AS AddTime 
                     FROM #Result AS Z 
                    WHERE Z.IDX_NO <= A.IDX_NO
                  ) AS B 
    
    END 
    ELSE 
    BEGIN -- �������� 
        
        IF EXISTS (SELECT 1 
                     FROM #TEMP AS A 
                     LEFT OUTER JOIN #TEMP AS B ON ( 1 = 1 )
                    WHERE (B.SrtDate BETWEEN A.SrtDate AND A.EndDate  
                      OR B.EndDate BETWEEN A.SrtDate AND A.EndDate ) 
                     AND A.SrtDate <> B.EndDate 
                     AND A.EndDate <> B.SrtDate 
                     AND A.IDX_NO <> B.IDX_NO 
                    ) 
        BEGIN 
            UPDATE A
               SET Result = '�۾����� �ߺ��Ǵ� �����Ͱ� �����Ͽ� �������Ÿ� �Ҽ� �����ϴ�.', 
                   MessageType = 1234, 
                   Status = 1234 
            FROM #TPDMPSDailyProdPlan AS A 
            
            SELECT * FROM #TPDMPSDailyProdPlan 
            RETURN 
        END 
        ELSE 
        BEGIN
            
            SELECT @SrtDate = ISNULL(@CfmMaxDate, (SELECT SrtDate FROM #TEMP WHERE IDX_NO = 1))
            
            INSERT INTO #Result ( IDX_NO, ProdPlanSeq, WorkCond4, SrtDate, EndDate, SumAProdMinute, SumBProdMinute, NewSrtDate, NewEndDate)
            SELECT A.IDX_NO, 
                   A.ProdPlanSeq, 
                   A.WorkCond4, 
                   A.SrtDate, 
                   A.EndDate, 
                   B.SumAProdMinute, 
                   B.SumBProdMinute, 
                   DATEADD(Minute,
                           B.SumBProdMinute, 
                           CONVERT(DATETIME,STUFF(STUFF(STUFF(STUFF(@SrtDate,5,0,'-'),8,0,'-'),11,0,' '),14,0,':') + ':00.000')  
                          ) AS NewSrtDate, 
                   DATEADD(Minute,
                           B.SumAProdMinute, 
                           CONVERT(DATETIME,STUFF(STUFF(STUFF(STUFF(@SrtDate,5,0,'-'),8,0,'-'),11,0,' '),14,0,':') + ':00.000')  
                          ) AS NewEndDate 
              FROM #TEMP AS A 
              OUTER APPLY (SELECT SUM(ISNULL(Z.ProdMinute,0)) AS SumAProdMinute, SUM(ISNULL(Y.ProdMinute,0)) AS SumBProdMinute 
                         FROM #TEMP AS Z 
                         LEFT OUTER JOIN #TEMP AS Y ON ( Z.IDX_NO - 1 = Y.IDX_NO ) 
                        WHERE Z.IDX_NO <= A.IDX_NO
                          ) AS B 
        END 
    END 
    
    ------------------
    -- ���� ���� 
    ------------------
    UPDATE B 
       SET SrtDate = CONVERT(NCHAR(8),A.NewSrtDate,112),
           EndDate = CONVERT(NCHAR(8),A.NewEndDate,112),
           WorkCond1 = REPLACE(CONVERT(NVARCHAR(5),A.NewSrtDate,108),':',''), 
           WorkCond2 = REPLACE(CONVERT(NVARCHAR(5),A.NewEndDate,108),':','')
      FROM #Result AS A 
      LEFT OUTER JOIN _TPDMPSDailyProdPlan AS B ON ( B.CompanySeq = @CompanySeq AND B.ProdPlanSeq = A.ProdPlanSeq ) 
    
    SELECT * FROM #TPDMPSDailyProdPlan 
    
    
    RETURN  
GO 
BEGIN TRAN 
--select SrtDate, WorkCond1, EndDate, WorkCond2, * from _TPDMPSDailyProdPlan where companyseq = 1 and WorkCenterSeq = 100201
exec KPX_SPDMPSProdPlanAutoSortSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <FrDate>20141014</FrDate>
    <IsAll>1</IsAll>
    <IsAutoSort>1</IsAutoSort>
    <IsGapDel>0</IsGapDel>
    <IsSelect>0</IsSelect>
    <IsStd>0</IsStd>
    <ToDate>20141021</ToDate>
    <WorkCenterSeq>100201</WorkCenterSeq>
    <WorkCneterName>Ȱ�������׽�Ʈ</WorkCneterName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025047,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021046

--select SrtDate, WorkCond1, EndDate, WorkCond2, * from _TPDMPSDailyProdPlan where companyseq = 1 and WorkCenterSeq = 100201

ROLLBACK