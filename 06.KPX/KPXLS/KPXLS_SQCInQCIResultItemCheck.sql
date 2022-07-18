  
IF OBJECT_ID('KPXLS_SQCInQCIResultItemCheck') IS NOT NULL   
    DROP PROC KPXLS_SQCInQCIResultItemCheck  
GO  
  
-- v2015.12.15  
  
-- (�˻�ǰ)���԰˻���-������üũ by ����õ   
CREATE PROC KPXLS_SQCInQCIResultItemCheck 
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
            @Results        NVARCHAR(250)   
    
    CREATE TABLE #KPX_TQCTestResultItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TQCTestResultItem'   
    IF @@ERROR <> 0 RETURN     
    --return 
    
    --select * from #KPX_TQCTestResultItem 
    --return 
    ------------------------------------------------------------------------
    -- üũ1, �˻���� �� �����ʹ� ����, ���� �� �� �����ϴ�. 
    ------------------------------------------------------------------------
    
    UPDATE A 
       SET Result = '�˻���� �� �����ʹ� ����, ���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPX_TQCTestResultItem AS A 
      JOIN KPXLS_TQCTestResultAdd AS B ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.QCSeq ) 
     WHERE B.IsCfm = '1' 
       AND A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
    
    ------------------------------------------------------------------------
    -- üũ1, END 
    ------------------------------------------------------------------------
    
    DECLARE @QCSeq  INT, 
            @QCSerl INT 
    
    SELECT @QCSeq = (SELECT MAX(QCSeq) FROM #KPX_TQCTestResultItem)
    
    SELECT @QCSerl = (SELECT MAX(QCSerl) FROM KPX_TQCTestResultItem WHERE CompanySeq = @CompanySeq AND QCSeq = ISNULL(@QCSeq,0))
    
    UPDATE A 
       SET QCSerl = ISNULL(@QCSerl,0) + A.DataSeq 
      FROM #KPX_TQCTestResultItem AS A 
     WHERE A.WorkingTag = 'A' 
       AND A.Status = 0 
    
    SELECT * FROM #KPX_TQCTestResultItem   
    
    RETURN 
    GO 
    begin tran
exec KPXLS_SQCInQCIResultItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <QCSeq>20</QCSeq>
    <QCSerl>0</QCSerl>
    <TestItemSeq>31</TestItemSeq>
    <InTestItemName>�׽�Ʈ-�系</InTestItemName>
    <OutTestItemName>�׽�Ʈ-���</OutTestItemName>
    <QAAnalysisType>1</QAAnalysisType>
    <QAAnalysisName>�м�-�׽�Ʈ</QAAnalysisName>
    <SMInputType>1018001</SMInputType>
    <SMInputTypeName>����</SMInputTypeName>
    <LowerLimit>1</LowerLimit>
    <UpperLimit />
    <QCUnit>8</QCUnit>
    <QCUnitName>�׽�Ʈ</QCUnitName>
    <TestValue>1</TestValue>
    <SMTestResult>6035003</SMTestResult>
    <SMTestResultName>�հ�</SMTestResultName>
    <IsSpecial>0</IsSpecial>
    <Remark>test1</Remark>
    <RegEmpSeq>0</RegEmpSeq>
    <RegEmpName />
    <RegDate />
    <RegTime />
    <UpdateDate />
    <UpdateEmpName />
    <UpdateTime />
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <QCDate>20151217</QCDate>
    <ReqSeq>16</ReqSeq>
    <ReqSerl>1</ReqSerl>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <QCSeq>20</QCSeq>
    <QCSerl>0</QCSerl>
    <TestItemSeq>32</TestItemSeq>
    <InTestItemName>�ܰ�</InTestItemName>
    <OutTestItemName>Appearance</OutTestItemName>
    <QAAnalysisType>2</QAAnalysisType>
    <QAAnalysisName>WS-QA-01-01</QAAnalysisName>
    <SMInputType>1018001</SMInputType>
    <SMInputTypeName>����</SMInputTypeName>
    <LowerLimit>1</LowerLimit>
    <UpperLimit />
    <QCUnit>9</QCUnit>
    <QCUnitName>-</QCUnitName>
    <TestValue>1</TestValue>
    <SMTestResult>6035003</SMTestResult>
    <SMTestResultName>�հ�</SMTestResultName>
    <IsSpecial>0</IsSpecial>
    <Remark>test2</Remark>
    <RegEmpSeq>0</RegEmpSeq>
    <RegEmpName />
    <RegDate />
    <RegTime />
    <UpdateDate />
    <UpdateEmpName />
    <UpdateTime />
    <QCDate>20151217</QCDate>
    <ReqSeq>16</ReqSeq>
    <ReqSerl>1</ReqSerl>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <QCSeq>20</QCSeq>
    <QCSerl>0</QCSerl>
    <TestItemSeq>33</TestItemSeq>
    <InTestItemName>��� �ܰ�</InTestItemName>
    <OutTestItemName>Appearance of solution</OutTestItemName>
    <QAAnalysisType>3</QAAnalysisType>
    <QAAnalysisName>WS-QA-01-02</QAAnalysisName>
    <SMInputType>1018001</SMInputType>
    <SMInputTypeName>����</SMInputTypeName>
    <LowerLimit>1</LowerLimit>
    <UpperLimit />
    <QCUnit>10</QCUnit>
    <QCUnitName>Area %</QCUnitName>
    <TestValue>1</TestValue>
    <SMTestResult>6035003</SMTestResult>
    <SMTestResultName>�հ�</SMTestResultName>
    <IsSpecial>0</IsSpecial>
    <Remark>test3</Remark>
    <RegEmpSeq>0</RegEmpSeq>
    <RegEmpName />
    <RegDate />
    <RegTime />
    <UpdateDate />
    <UpdateEmpName />
    <UpdateTime />
    <QCDate>20151217</QCDate>
    <ReqSeq>16</ReqSeq>
    <ReqSerl>1</ReqSerl>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033819,@WorkingTag=N'',@CompanySeq=3,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027993
rollback 