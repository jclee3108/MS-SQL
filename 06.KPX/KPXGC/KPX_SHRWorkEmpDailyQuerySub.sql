  
IF OBJECT_ID('KPX_SHRWorkEmpDailyQuerySub') IS NOT NULL   
    DROP PROC KPX_SHRWorkEmpDailyQuerySub  
GO  
  
-- v2014.12.23  
  
-- �������ٹ��ο����-���� ���� by ����õ   
CREATE PROC KPX_SHRWorkEmpDailyQuerySub  
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
    
    DECLARE @docHandle          INT,  
            -- ��ȸ����   
            @WorkDate           NCHAR(8), 
            @UMWorkCenterSeq    INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @WorkDate        = ISNULL( WorkDate, '' ),  
           @UMWorkCenterSeq = ISNULL ( UMWorkCenterSeq, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            WorkDate           NCHAR(8), 
            UMWorkCenterSeq    INT
           )     
    
    CREATE TABLE #LogTable 
    (
        IDX_NO      INT, 
        WorkingTag  NVARCHAR(2), 
        WorkDate    NCHAR(8), 
        UMWorkCenterSeq INT, 
        Status      INT 
    ) 
    
    INSERT INTO #LogTable
    SELECT 1, 'D', @WorkDate, @UMWorkCenterSeq, 0 
    

    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_THRWorkEmpDaily')    

    EXEC _SCOMLog @CompanySeq   ,        
          @UserSeq      ,        
          'KPX_THRWorkEmpDaily'    , -- ���̺��        
          '#LogTable'    , -- �ӽ� ���̺��        
          'WorkDate,UMWorkCenterSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
          @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    DELETE B   
      FROM #LogTable AS A   
      JOIN KPX_THRWorkEmpDaily AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkDate = A.WorkDate AND B.UMWorkCenterSeq = A.UMWorkCenterSeq )   
     WHERE A.WorkingTag = 'D'   
       AND A.Status = 0   
    
    
    
    DECLARE @MaxDate NCHAR(8) 
    SELECT @MaxDate = MAX(WorkDate) 
      FROM KPX_THRWorkEmpDaily 
     WHERE CompanySeq = @CompanySeq 
       AND WorkDate < @WorkDate 
       AND UMWorkCenterSeq = @UMWorkCenterSeq
    
    -- ������ȸ   
    SELECT A.Serl, 
           A.EmpSeq, 
           B.EmpName, 
           B.WkDeptName 
      FROM KPX_THRWorkEmpDaily AS A 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS B ON ( B.EmpSeq = A.EmpSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.WorkDate = @MaxDate 
       AND A.UMWorkCenterSeq =@UMWorkCenterSeq
      
    RETURN  
GO 
begin tran 


exec KPX_SHRWorkEmpDailyQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <WorkDate>20141224</WorkDate>
    <UMWorkCenterSeq>1010550001</UMWorkCenterSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027065,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022596

--select * from KPX_THRWorkEmpDailyLog
rollback 