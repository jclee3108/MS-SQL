
IF OBJECT_ID('DTI_SSLInterTransferServiceCheck ') IS NOT NULL
    DROP PROC DTI_SSLInterTransferServiceCheck 
    
GO

-- v2013.06.20

-- �系��ü���(����)üũ_DTI By ����õ
CREATE PROC DTI_SSLInterTransferServiceCheck
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0  
AS 
    DECLARE @MessageType    INT,
            @Status         INT,
            @Results        NVARCHAR(250)
  					
    CREATE TABLE #DTI_TSLInterTransferService (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TSLInterTransferService'
    
    ---------------------------
    -- �ʼ��Է� üũ
    ---------------------------
    
    -- �ʼ��Է� Message �޾ƿ���
    EXEC dbo._SCOMMessage @MessageType OUTPUT,
                          @Status      OUTPUT,
                          @Results     OUTPUT,
                          1038               , -- �ʼ��Է� �׸��� �Է����� �ʾҽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ʼ�%')
                          @LanguageSeq       , 
                          0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'
	
    -- ������ ���� üũ : UPDATE, DELETE �� ������ �������� ������ ����ó��  
    
    IF  EXISTS (SELECT 1   
                  FROM #DTI_TSLInterTransferService AS A   
                  LEFT OUTER JOIN DTI_TSLInterTransferService AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.TransSeq = B.TransSeq ) 
                 WHERE A.WorkingTag IN ('U', 'D')
                   AND B.TransSeq IS NULL )  
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              7                  , -- �ڷᰡ ��ϵǾ� ���� �ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                              @LanguageSeq       ,   
                              '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'          
        
        UPDATE #DTI_TSLInterTransferService  
           SET Result        = @Results,  
               MessageType   = @MessageType,  
               Status        = @Status  
          FROM #DTI_TSLInterTransferService AS A   
          LEFT OUTER  JOIN DTI_TSLInterTransferService AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.TransSeq = B.TransSeq ) 
            
         WHERE A.WorkingTag IN ('U', 'D')
           AND B.TransSeq IS NULL 
    END   
        
    ---------------------------
    -- �����ڵ�  üũ:������ �� ���̺��� ��� ������ ��� ���̺� üũ sp�Դϴ�.
    ---------------------------        
    -- EXEC dbo._SCOMCodeDeleteCheck  @CompanySeq,@UserSeq,@LanguageSeq,'DTI_TSLInterTransferService', '#DTI_TSLInterTransferService','Ű��'  
    
    ---------------------------
    -- �ߺ����� üũ
    ---------------------------  
    -- �ߺ�üũ Message �޾ƿ���    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)    
                          @LanguageSeq       ,     
                          0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%����ī���ȣ%'    

    --guide : '������ Ű ����' --------------------------
    DECLARE @MaxSeq INT,
            @Count  INT 
    SELECT @Count = Count(1) FROM #DTI_TSLInterTransferService WHERE WorkingTag = 'A' AND Status = 0
    IF @Count >0 
    BEGIN
        EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'DTI_TSLInterTransferService','TransSeq',@Count --rowcount  
        UPDATE #DTI_TSLInterTransferService             
           SET TransSeq  = @MaxSeq + DataSeq   
         WHERE WorkingTag = 'A'            
           AND Status = 0 
    END  
                       
    SELECT * FROM #DTI_TSLInterTransferService 
    
    RETURN 
    
GO
exec DTI_SSLInterTransferServiceCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <TransYM>201303</TransYM>
    <TransAmt>12</TransAmt>
    <Remark>23</Remark>
    <ItemSeq>14526</ItemSeq>
    <TransSeq>0</TransSeq>
    <SndDeptSeq>1621</SndDeptSeq>
    <RcvDeptSeq>1606</RcvDeptSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016156,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1013904