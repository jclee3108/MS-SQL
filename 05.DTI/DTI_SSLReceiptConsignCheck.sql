
IF OBJECT_ID('DTI_SSLReceiptConsignCheck') IS NOT NULL 
    DROP PROC DTI_SSLReceiptConsignCheck
GO 

-- v2014.05.21 

-- ����Ź�Ա��Է�_DTI(����Ź�Ա�üũ) by����õ
CREATE PROCEDURE DTI_SSLReceiptConsignCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0
AS 
    
    DECLARE @Count       INT,
            @DataSeq     INT,
            @ReceiptSeq  INT, 
            @ReceiptNo   NVARCHAR(20),
            @BaseDate    NVARCHAR(8),
            @MaxNo       NVARCHAR(12),
            @BizUnit     INT, 
            @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250), 
            @MaxDataSeq  INT,
            @CustEmpUse  NVARCHAR(50)
    
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #DTI_TSLReceiptConsign (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TSLReceiptConsign' 
    
    -------------------------------------------
    -- ��ǥ����üũ                            
    -------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          15                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 15)    
                          @LanguageSeq       
    UPDATE #DTI_TSLReceiptConsign    
       SET Result        = @Results,    
           MessageType   = @MessageType,    
           Status        = @Status    
      FROM #DTI_TSLReceiptConsign AS A 
      JOIN DTI_TSLReceiptConsign AS A1 ON ( A1.CompanySeq = @CompanySeq AND A.ReceiptSeq = A1.ReceiptSeq ) 
     WHERE A.WorkingTag IN ('U','D')
       AND A.Status = 0
       AND ISNULL(A1.SlipSeq, 0) <> 0
    --------------------------------------------------------------------------------------
    -- ������ ���� üũ : UPDATE, DELETE �� ������ �������� ������ ����ó��
    --------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 
                     FROM #DTI_TSLReceiptConsign AS A 
                     JOIN DTI_TSLReceiptConsign AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ReceiptSeq = B.ReceiptSeq ) 
                    WHERE A.WorkingTag IN ('U', 'D')
                  )
    BEGIN
        EXEC dbo._SCOMMessage @MessageType OUTPUT,
                              @Status      OUTPUT,
                              @Results     OUTPUT,
                              7                  , -- �ڷᰡ ��ϵǾ� ���� �ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)
                              @LanguageSeq       , 
                              '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
        UPDATE #DTI_TSLReceiptConsign
           SET Result        = @Results,
               MessageType   = @MessageType,
               Status        = @Status
         WHERE WorkingTag IN ('U','D')
    END    
    --------------------------------------------------------------------------------------  
    -- �ʼ� ������ (�ŷ�ó) üũ
    --------------------------------------------------------------------------------------  
    IF EXISTS (SELECT 1 FROM #DTI_TSLReceiptConsign WHERE WorkingTag IN ('A', 'U') AND ISNULL(CustSeq,0) = 0)
    BEGIN   
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1                  , -- �ڷᰡ ��ϵǾ� ���� �ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                              @LanguageSeq       ,   
                              6,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'          
        UPDATE #DTI_TSLReceiptConsign  
           SET Result        = @Results,  
               MessageType   = @MessageType,  
               Status        = @Status  
         WHERE WorkingTag IN ('A','U')  
    END  
    
    /*
    -------------------------------------------
    -- ��ǥ����üũ                            
    -------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          8                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 15)    
                          @LanguageSeq       ,
                          1562, '', 0, ' '
    UPDATE #DTI_TSLReceiptConsign    
       SET Result        = REPLACE(@Results,'@3',A2.PreOffNo),    
           MessageType   = @MessageType,    
           Status        = @Status    
      FROM #DTI_TSLReceiptConsign          AS A 
      JOIN _TSLPreReceiptItem   AS A1 ON ( A1.CompanySeq = @CompanySeq AND A.ReceiptSeq = A1.ReceiptSeq ) 
      JOIN _TSLPreReceipt       AS A2 ON ( A2.CompanySeq = @CompanySeq AND A1.PreOffSeq = A2.PreOffSeq ) 
      WHERE A.WorkingTag IN ('A','U','D')
        AND A.Status = 0
    -------------------------------------------  
    -- ���࿩��üũ  
    -------------------------------------------  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          1044                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1044)  
                          @LanguageSeq       ,   
                          0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%�̼�%'  
    UPDATE #DTI_TSLReceiptConsign  
       SET Result        = @Results,  
           MessageType   = @MessageType,  
           Status        = @Status  
      FROM #DTI_TSLReceiptConsign AS A 
      JOIN _TSLExpDA AS B WITH (NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ReceiptSeq = B.ReceiptSeq ) 
     WHERE A.WorkingTag IN ('U','D')
       AND A.Status = 0
    -------------------------------------------
    -- �Աݹ̼�����üũ                            
    -------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          8                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 8)    
                          @LanguageSeq       ,  
                          2529, '', 11365, ''       -- SELECT * FROM _TCADictionary WHERE Word like '%��%'  
    UPDATE #DTI_TSLReceiptConsign    
       SET Result        = REPLACE(@Results,'@3',A2.ReceiptNo),    
           MessageType   = @MessageType,    
           Status        = @Status    
      FROM #DTI_TSLReceiptConsign          AS A 
      JOIN _TSLReceiptCreditDiv AS A1 ON A1.CompanySeq = @CompanySeq AND A.ReceiptSeq  = A1.ReceiptSeq
      JOIN _TSLReceipt          AS A2 ON A2.CompanySeq = @CompanySeq AND A.ReceiptSeq  = A2.ReceiptSeq
     WHERE A.WorkingTag IN ('A','U','D')
       AND A.Status = 0
    
     -- �����üũ
     EXEC dbo._SCOMEnv @CompanySeq, 8001, @UserSeq, @@PROCID, @CustEmpUse OUTPUT  
   
     IF @CustEmpUse = '1'   
     BEGIN  
         EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                               @Status      OUTPUT,    
                               @Results     OUTPUT,    
                               1102               , -- �ߴܵǾ� ó���� �� �����ϴ�...(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 1102)    
                               @LanguageSeq        ,     
                               462,''   -- SELECT * FROM _TCADictionary WHERE WordSeq = 462 like '%�ŷ�ó%'    
         UPDATE #DTI_TSLReceiptConsign  
            SET Result        = @Results    ,    
                MessageType   = @MessageType,    
                Status        = @Status    
           FROM #DTI_TSLReceiptConsign  AS A    
                 JOIN _TSLCustChargeEmp AS B ON B.CompanySeq = @CompanySeq
                                            AND A.CustSeq    = B.CustSeq
                                            AND B.UMChargeKind = 8013001
                                            AND A.ReceiptDate BETWEEN SDate AND EDate
          WHERE B.CompanySeq = @CompanySeq  
            AND A.EmpSeq <> B.EmpSeq 
            AND A.WorkingTag IN ('A', 'U') 
          UPDATE #DTI_TSLReceiptConsign  
            SET Result        = @Results    ,    
                MessageType   = @MessageType,    
                Status        = @Status    
           FROM #DTI_TSLReceiptConsign  AS A    
                 JOIN _TSLCustSalesEmp AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                        AND A.CustSeq    = B.CustSeq  
                                                        AND A.ReceiptDate >= B.SDate
                 LEFT OUTER JOIN _TSLCustChargeEmp AS C ON C.CompanySeq = @CompanySeq
                                                       AND A.CustSeq    = C.CustSeq
                                                       AND C.UMChargeKind = 8013001
                                                       AND A.ReceiptDate BETWEEN C.SDate AND C.EDate
          WHERE A.Status = 0
            AND A.EmpSeq <> B.EmpSeq  
            AND C.CustSeq IS NULL
            AND A.WorkingTag IN ('A', 'U') 
     END  
    */
    IF EXISTS ( SELECT 1 FROM #DTI_TSLReceiptConsign WHERE WorkingTag = 'A' AND Status = 0 ) 
    BEGIN 
        -- Create ReceiptSeq, ReceiptNo 20140211 by sdlee
        SELECT @DataSeq = 1
        SELECT @Count = COUNT(1) FROM #DTI_TSLReceiptConsign
        WHILE (@DataSeq <= @Count)
        BEGIN
            -- ReceiptSeq
            EXEC @ReceiptSeq = _SCOMCreateSeq @CompanySeq, 'DTI_TSLReceiptConsign', 'ReceiptSeq', 1, 'A'
            -- ReceiptNo
            SELECT @BaseDate = ReceiptDate FROM #DTI_TSLReceiptConsign WHERE DataSeq = @DataSeq
            EXEC _SCOMCreateNo 'SL', 'DTI_TSLReceiptConsign', @CompanySeq, '', @BaseDate, @ReceiptNo OUTPUT
            -- Update ReceiptSeq, ReceiptNo
            UPDATE #DTI_TSLReceiptConsign
               SET ReceiptSeq = @ReceiptSeq + 1,
                   ReceiptNo = @ReceiptNo
              FROM #DTI_TSLReceiptConsign
             WHERE DataSeq = @DataSeq
               AND WorkingTag = 'A'
               AND Status = 0
             -- @DataSeq ++
            SELECT @DataSeq = @DataSeq + 1
        END --::WHILE (@DataSeq <= @Count)
    END
  
  /*
    -------------------------------------------  
    -- ������¸� ����/���� �� �� ������ üũ
    -------------------------------------------  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          18               , --@1��(��) ����/���� �Ҽ� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and Message LIKE '%����%����%')      
                          @LanguageSeq,
                          2676                 -- SELECT * FROM _TCADictionary WHERE Word like '%�������%'         
    
    UPDATE A 
       SET Result        = @Results     ,      
           MessageType   = @MessageType ,      
           Status        = @Status      
      FROM #DTI_TSLReceiptConsign AS A 
      JOIN DTI_TSLReceiptConsign AS B ON ( B.CompanySeq = @CompanySeq AND A.ReceiptSeq = B.ReceiptSeq AND B.IsAuto = 1 ) 
     WHERE A.WorkingTag IN ('U', 'D')
       AND A.Status = 0  
       */
    -------------------------------------------  
    -- �����ڵ� 0���Ͻ� ���� �߻�
    -------------------------------------------      
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          1055               , -- ó���۾��� ������ �߻��߽��ϴ�. �ٽ� ó���Ͻʽÿ�!(SELECT  * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 1055)    
                          @LanguageSeq       
    UPDATE #DTI_TSLReceiptConsign                               
       SET Result        = @Results     ,    
           MessageType   = @MessageType ,    
           Status        = @Status    
      FROM #DTI_TSLReceiptConsign
     WHERE Status = 0
       AND (ReceiptSeq = 0 OR ReceiptSeq IS NULL)        
    
    SELECT * FROM #DTI_TSLReceiptConsign
    
    RETURN
GO
exec DTI_SSLReceiptConsignCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ReceiptNo />
    <SMExpKind>8009001</SMExpKind>
    <SMExpKindName>����</SMExpKindName>
    <SlipID />
    <ReceiptSeq>0</ReceiptSeq>
    <SlipSeq>0</SlipSeq>
    <ReceiptDate>20140521</ReceiptDate>
    <CustSeq>37606</CustSeq>
    <CustName>(��)���Ѱ����򰡹���</CustName>
    <CurrSeq>1</CurrSeq>
    <CurrName>KRW</CurrName>
    <ExRate>1</ExRate>
    <EmpSeq>1834</EmpSeq>
    <EmpName>AB2</EmpName>
    <DeptSeq>1511</DeptSeq>
    <DeptName>�μ��̷�</DeptName>
    <OppAccSeq>22</OppAccSeq>
    <OppAccName>�ܻ�����</OppAccName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1022863,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1019203