  
IF OBJECT_ID('yw_SPJTToolTestResultCheck') IS NOT NULL   
    DROP PROC yw_SPJTToolTestResultCheck  
GO  
  
-- v2014.07.02  
  
-- �����׽�Ʈ�̷µ��_YW(üũ) by ����õ   
CREATE PROC yw_SPJTToolTestResultCheck  
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
    
    CREATE TABLE #yw_TPJTToolResult( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#yw_TPJTToolResult'   
    IF @@ERROR <> 0 RETURN     
    
    -- �����Ͱ� ���� ���� ���� 
    DELETE A
      FROM #yw_TPJTToolResult AS A 
     WHERE ISNULL(Results,'') = '' 
       AND ISNULL(RevDate,'') = '' 
       AND ISNULL(RevEndDate,'') = '' 
       AND ISNULL(RevResults,'') = '' 
       AND ISNULL(TestRegDate,'') = '' 
    
    
    -- ����������üũ: UPDATE, DELETE�� ������ �������� ������ ����ó��  
    IF NOT EXISTS ( SELECT 1   
                      FROM #yw_TPJTToolResult   AS A   
                      JOIN yw_TPJTToolResult    AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.ToolSeq = A.ToolSeq AND B.Serl = A.Serl ) 
                     WHERE A.WorkingTag IN ( 'U', 'D' )  
                       AND Status = 0   
                  )  
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              7                  , -- �ڷᰡ��ϵǾ������ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                              @LanguageSeq               
          
        UPDATE #yw_TPJTToolResult  
           SET Result       = @Results,  
               MessageType  = @MessageType,  
               Status       = @Status  
         WHERE WorkingTag IN ( 'U', 'D' )  
           AND Status = 0   
    END   

    -- Serl ä�� 
    DECLARE @MAXSerl INT 
    
    SELECT @MAXSerl = MAX(ISNULL(B.Serl,0))  
      FROM #yw_TPJTToolResult AS A 
      LEFT OUTER JOIN yw_TPJTToolResult AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.ToolSeq = A.ToolSeq ) 
    
    UPDATE #yw_TPJTToolResult  
       SET Serl = @MAXSerl + DataSeq
     WHERE WorkingTag = 'A'  
       AND Status = 0  
    
    SELECT * FROM #yw_TPJTToolResult   
    
    RETURN  
GO
exec yw_SPJTToolTestResultCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>0</Serl>
    <Results>1111</Results>
    <RevResults>22222</RevResults>
    <RevDate>20140701</RevDate>
    <RevEndDate>20140702</RevEndDate>
    <TestRegDate>20140703</TestRegDate>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <PJTSeq>2</PJTSeq>
    <ToolSeq>1</ToolSeq>
    <EmpSeq>2028</EmpSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>0</Serl>
    <Results>3333</Results>
    <RevResults>4444</RevResults>
    <RevDate>20140702</RevDate>
    <RevEndDate>20140703</RevEndDate>
    <TestRegDate>20140704</TestRegDate>
    <PJTSeq>2</PJTSeq>
    <ToolSeq>1</ToolSeq>
    <EmpSeq>2028</EmpSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>0</Serl>
    <Results />
    <RevResults />
    <RevDate />
    <RevEndDate />
    <TestRegDate />
    <PJTSeq>2</PJTSeq>
    <ToolSeq>1</ToolSeq>
    <EmpSeq>2028</EmpSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>0</Serl>
    <Results />
    <RevResults />
    <RevDate />
    <RevEndDate />
    <TestRegDate />
    <PJTSeq>2</PJTSeq>
    <ToolSeq>1</ToolSeq>
    <EmpSeq>2028</EmpSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>0</Serl>
    <Results />
    <RevResults />
    <RevDate />
    <RevEndDate />
    <TestRegDate />
    <PJTSeq>2</PJTSeq>
    <ToolSeq>1</ToolSeq>
    <EmpSeq>2028</EmpSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>0</Serl>
    <Results />
    <RevResults />
    <RevDate />
    <RevEndDate />
    <TestRegDate />
    <PJTSeq>2</PJTSeq>
    <ToolSeq>1</ToolSeq>
    <EmpSeq>2028</EmpSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1023444,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1019676