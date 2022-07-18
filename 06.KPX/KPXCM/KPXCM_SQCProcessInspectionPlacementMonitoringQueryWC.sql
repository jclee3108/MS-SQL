IF OBJECT_ID('KPXCM_SQCProcessInspectionPlacementMonitoringQueryWC') IS NOT NULL 
    DROP PROC KPXCM_SQCProcessInspectionPlacementMonitoringQueryWC
GO 

-- v2016.05.03  

-- ������-�˻�������͸�(��ġ��) : ��ũ������ȸ

/************************************************************
 ��  �� - ������-�˻�������͸�(��zġ��) : ��ũ������ȸ
 �ۼ��� - 20141224
 �ۼ��� - ����ȯ
 ������ - 
************************************************************/
CREATE PROC KPXCM_SQCProcessInspectionPlacementMonitoringQueryWC
    @xmlDocument   NVARCHAR(MAX) ,            
    @xmlFlags      INT = 0,            
    @ServiceSeq    INT = 0,            
    @WorkingTag    NVARCHAR(10)= '',                  
    @CompanySeq    INT = 1,            
    @LanguageSeq   INT = 1,            
    @UserSeq       INT = 0,            
    @PgmSeq        INT = 0       

AS        
    
    DECLARE @docHandle      INT,  
            -- ��ȸ����   
            @TestDateQ      NCHAR(8),
            @BizUnit        INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @TestDateQ   = ISNULL(TestDateQ, ''),  
           @BizUnit     = ISNULL(BizUnit  ,  0)
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
                TestDateQ      NCHAR(8),
                BizUnit        INT
           )    
    
    CREATE TABLE #WorkCenterValue 
    (
        WorkCenterSeq   INT 
    )
    IF @PgmSeq = 1030165 -- ����/ó�� �����
    BEGIN 
        INSERT INTO #WorkCenterValue ( WorkCenterSeq ) 
        -- ������ ��� �Ǿ� �ִ� ��ũ ���͸� ��ȸ  
        SELECT C.ValueSeq as WorkCenterSeq --,D.ValueSeq,E.ValueSeq,F.ValueSeq  
          FROM _TDAUMinorValue  AS C WITH(NOLOCK)       
          JOIN _TDAUMinorValue  AS D WITH(NOLOCK)ON C.CompanySeq = D.CompanySeq And C.MajorSeq = D.MajorSeq And C.MinorSeq = D.MinorSeq and D.Serl = 1000002      
          JOIN _TDAUMinorValue  AS E WITH(NOLOCK)ON D.CompanySeq = E.CompanySeq And E.MajorSeq = 1011265    And E.MinorSeq = D.ValueSeq and E.Serl = 1000001      
          JOIN _TDAUMinorValue  AS F WITH(NOLOCK)ON E.CompanySeq = F.CompanySeq And F.MajorSeq = 1011266    And F.MinorSeq = E.ValueSeq and F.Serl = 1000001      
         WHERE C.CompanySeq = @CompanySeq 
           AND C.MajorSeq = 1011346  
           AND C.Serl = 1000001 
           AND (D.ValueSeq = 1011267001 or E.ValueSeq= 1011267001 Or F.ValueSeq = 1011267001)  
    END 
    ELSE
    BEGIN
        INSERT INTO #WorkCenterValue ( WorkCenterSeq ) 
        -- ������ ��� �Ǿ� �ִ� ��ũ ���͸� ��ȸ  
        SELECT C.ValueSeq as WorkCenterSeq --,D.ValueSeq,E.ValueSeq,F.ValueSeq  
          FROM _TDAUMinorValue  AS C WITH(NOLOCK)       
          JOIN _TDAUMinorValue  AS D WITH(NOLOCK)ON C.CompanySeq = D.CompanySeq And C.MajorSeq = D.MajorSeq And C.MinorSeq = D.MinorSeq and D.Serl = 1000002      
          JOIN _TDAUMinorValue  AS E WITH(NOLOCK)ON D.CompanySeq = E.CompanySeq And E.MajorSeq = 1011265    And E.MinorSeq = D.ValueSeq and E.Serl = 1000001      
          JOIN _TDAUMinorValue  AS F WITH(NOLOCK)ON E.CompanySeq = F.CompanySeq And F.MajorSeq = 1011266    And F.MinorSeq = E.ValueSeq and F.Serl = 1000001      
         WHERE C.CompanySeq = @CompanySeq 
           AND C.MajorSeq = 1011346  
           AND C.Serl = 1000001 
           AND (D.ValueSeq <> 1011267001 AND E.ValueSeq <> 1011267001 AND F.ValueSeq <> 1011267001)  
    END 
    
    
    CREATE TABLE #WorkCenter
    (
        IDX                 INT IDENTITY(1,1),
        WorkCenterName      NVARCHAR(100),
        WorkCenterSeq       INT
    )
    INSERT INTO #WorkCenter
    SELECT A.WorkCenterName,
           A.WorkCenterSeq
      FROM _TPDBaseWorkCenter AS A WITH (NOLOCK) JOIN _TDAFactUnit      B ON A.CompanySeq   = B.CompanySeq
                                                                         AND A.FactUnit     = B.FactUnit
                                                 JOIN _TDABizUnit       C ON B.CompanySeq   = C.CompanySeq
                                                                         AND B.BizUnit      = C.BizUnit
     WHERE 1=1
       AND A.CompanySeq = @CompanySeq
       AND ISNULL(A.CapaRate ,0) > 0
       AND ISNULL(A.OutMatLeadTime, '0') = '0'
       AND C.BizUnit    = @BizUnit 
       AND A.WorkCenterSeq <> 70 
       AND A.WorkCenterSeq IN ( SELECT WorkCenterSeq FROM #WorkCenterValue ) 
  GROUP BY A.WorkCenterName, A.WorkCenterSeq
    
    
    /*
    -- ����˻�
    INSERT INTO #WorkCenter
    SELECT WorkCenterName,
           WorkCenterSeq
      FROM _TPDBaseWorkCenter AS A WITH (NOLOCK) 
           JOIN (SELECT TOP 1 EnvValue
                   FROM KPX_TCOMEnvItem 
                  WHERE CompanySeq = @CompanySeq
                    AND EnvSeq = 12) AS E ON E.EnvValue = A.WorkCenterSeq
     WHERE 1=1
       AND A.CompanySeq = @CompanySeq
    
    -- ���ϰ˻�
    INSERT INTO #WorkCenter
    SELECT WorkCenterName,
           WorkCenterSeq
      FROM _TPDBaseWorkCenter AS A WITH (NOLOCK) 
           JOIN (SELECT TOP 1 EnvValue
                   FROM KPX_TCOMEnvItem 
                  WHERE CompanySeq = @CompanySeq
                    AND EnvSeq = 14) AS E ON E.EnvValue = A.WorkCenterSeq      
     WHERE 1=1
       AND A.CompanySeq = @CompanySeq
    */
    -- ������ Ȯ��(IsChecked)�� �ȵ� �����˻���(��ġ��)���� ����ġ�� ��ϵ� ����(��ũ����)
    CREATE TABLE #WorkCenterIsUse
    (
        WorkCenterSeq       INT,
        ReqDate             NCHAR(8)
    )

    INSERT #WorkCenterIsUse
    SELECT A.WorkCenterSeq,
           D.ReqDate
      FROM #WorkCenter              AS A 
      JOIN KPX_TQCTestResult        AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkCenterSeq = B.WorkCenterSeq ) 
      JOIN KPX_TQCTestResultItem    AS C ON ( B.CompanySeq = C.CompanySeq AND B.QCSeq = C.QCSeq ) 
      JOIN KPX_TQCTestRequest       AS D ON ( B.CompanySeq = D.CompanySeq AND B.ReqSeq = D.ReqSeq ) 
     WHERE 1=1
       AND ISNULL(TestValue, '') <> ''
       --AND ISNULL(IsChecked, '') = '' -- �ּ� by����õ 
       AND (@TestDateQ = '' OR D.ReqDate   = @TestDateQ)
       AND D.ReqDate >= '20160502' -- ���̺� �߰��� �������� ���� 
       AND ISNULL(B.IsEnd, '') <> '1'
       AND NOT EXISTS (SELECT 1 FROM KPXCM_TQCTestResultMonitoring WHERE CompanySeq = @CompanySeq AND QCSeq = B.QCSeq AND UserSeq = @UserSeq) -- �߰� by����õ 
  GROUP BY A.WorkCenterSeq, D.ReqDate
    
    -- ���� SELECT
    SELECT A.*,
    CASE WHEN ISNULL(B.WorkCenterSeq, '') <> '' THEN '1'
                ELSE '0'
            END AS IsUse,
           B.ReqDate
           
      FROM #WorkCenter A 
      LEFT OUTER JOIN #WorkCenterIsUse B ON A.WorkCenterSeq = B.WorkCenterSeq
      CROSS APPLY ( SELECT TOP 1 Sort  
                      FROM KPX_TPDWorkCenterRate  
                     WHERE WorkCenterSeq = A.WorkCenterSeq  
                       AND CompanySeq = @CompanySeq 
                  ) AS C
     ORDER BY C.Sort --IsUse DESC, IDX 

RETURN



GO

begin tran 
exec KPXCM_SQCProcessInspectionPlacementMonitoringQueryWC @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <TestDateQ>20160504</TestDateQ>
    <BizUnit>1</BizUnit>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1036841,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1030165
rollback 