
IF OBJECT_ID('yw_SPDSFCWorkStartListCheck') IS NOT NULL 
    DROP PROC yw_SPDSFCWorkStartListCheck
GO 

-- v2014.02.14 

-- ����������Ȳ_YW(üũ) by����õ
CREATE PROC dbo.yw_SPDSFCWorkStartListCheck
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS   
    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250)
    
    CREATE TABLE #YW_TPDSFCWorkStart (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TPDSFCWorkStart'
    
    UPDATE A
       SET Result = N'�������ᰡ �� �����ʹ� ������ �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234
      FROM #YW_TPDSFCWorkStart AS A 
      JOIN YW_TPDSFCWorkStart  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkOrderSeq = A.WorkOrderSeq AND B.WorkOrderSerl = A.WorkOrderSerl AND B.Serl = A.Serl AND B.EmpSeq = A.EmpSeq ) 
     WHERE B.EndTime <> '' 
    
    SELECT * FROM #YW_TPDSFCWorkStart 
    
    RETURN    
GO
exec yw_SPDSFCWorkStartListCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <WorkCenterName>��ũ����1_������</WorkCenterName>
    <WorkOrderNo>2013083000060001</WorkOrderNo>
    <WorkDate>20130811</WorkDate>
    <EmpName>������         </EmpName>
    <WorkStartTime>20130811 124401</WorkStartTime>
    <WorkEndTime>20130811 124701</WorkEndTime>
    <WorkCenterSeq>100374</WorkCenterSeq>
    <EmpSeq>138</EmpSeq>
    <WorkOrderSeq>1000245</WorkOrderSeq>
    <WorkOrderSerl>1000245</WorkOrderSerl>
    <Serl>5</Serl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1021108,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1017737
    