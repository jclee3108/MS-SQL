  
IF OBJECT_ID('costel_SSLDelvContractItemCheck') IS NOT NULL   
    DROP PROC costel_SSLDelvContractItemCheck  
GO  
  
-- v2013.09.04 
  
-- ��ǰ�����_costel(ǰ��üũ) by����õ   
CREATE PROC costel_SSLDelvContractItemCheck  
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
      
    CREATE TABLE #costel_TSLDelvContractItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#costel_TSLDelvContractItem'   
    IF @@ERROR <> 0 RETURN     
    
    --select * from #costel_TSLDelvContractItem
    
    ---- ����������üũ: UPDATE, DELETE�� ������ �������� ������ ����ó��  
    --IF NOT EXISTS ( SELECT 1   
    --                  FROM #TSample AS A   
    --                  JOIN _TSample AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.SampleSeq = B.SampleSeq )  
    --                 WHERE A.WorkingTag IN ( 'U', 'D' )  
    --                   AND Status = 0   
    --              )  
    --BEGIN  
    --    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                          @Status      OUTPUT,  
    --                          @Results     OUTPUT,  
    --                          7                  , -- �ڷᰡ��ϵǾ������ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
    --                          @LanguageSeq               
          
    --    UPDATE #TSample  
    --       SET Result       = @Results,  
    --           MessageType  = @MessageType,  
    --           Status       = @Status  
    --     WHERE WorkingTag IN ( 'U', 'D' )  
    --       AND Status = 0   
    --END   
      
    ---- �ߺ����� üũ :   
    --EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                      @Status      OUTPUT,  
    --                      @Results     OUTPUT,  
    --                      6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
    --                      @LanguageSeq       ,  
    --                      3542, '��1'--,  -- SELECT * FROM _TCADictionary WHERE Word like '%��%'  
    --                      --3543, '��2'  
      
    --UPDATE #TSample  
    --   SET Result       = REPLACE( @Results, '@2', B.SampleName ), -- Ȥ�� @Results,  
    --       MessageType  = @MessageType,  
    --       Status       = @Status  
    --  FROM #TSample AS A   
    --  JOIN (SELECT S.SampleName  
    --          FROM (SELECT A1.SampleName  
    --                  FROM #TSample AS A1  
    --                 WHERE A1.WorkingTag IN ('A', 'U')  
    --                   AND A1.Status = 0  
                                              
    --                UNION ALL  
                                             
    --                SELECT A1.SampleName  
    --                  FROM _TSample AS A1  
    --                 WHERE A1.CompanySeq = @CompanySeq   
    --                   AND NOT EXISTS (SELECT 1 FROM #TSample   
    --                                           WHERE WorkingTag IN ('U','D')   
    --                                             AND Status = 0   
    --                                             AND SampleSeq = A1.SampleSeq  
    --                                  )  
    --               ) AS S  
    --         GROUP BY S.SampleName  
    --        HAVING COUNT(1) > 1  
    --       ) AS B ON ( A.SampleName = B.SampleName )  
    -- WHERE A.WorkingTag IN ('A', 'U')  
    --   AND A.Status = 0  
      
    ---- ��뿩��üũ : K-Studio -> �������� -> �����ڵ� -> �ڵ������ ��뿩��üũ ȭ�鿡�� ����� �ؾ� üũ��    
    ----IF EXISTS ( SELECT 1 FROM #TSample WHERE WorkingTag = 'D' )    
    ----BEGIN    
    ----    EXEC _SCOMCodeDeleteCheck @CompanySeq, @UserSeq, @LanguageSeq, '_TSample', '#TSample', 'SampleSeq'    
    ----END    

    -- üũ1, ���� �� �����ʹ�
    
    UPDATE A
       SET Result = N'�̹� Ȯ��ó���� �Ǿ� ���� �� �� �����ϴ�.',
           Status = 123412
      FROM #costel_TSLDelvContractItem AS A
      LEFT OUTER JOIN costel_TSLDelvContract AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
      
    WHERE A.WorkingTag = 'D' 
      AND A.Status = 0
      AND B.IsCfm = 1 
    
    -- üũ1, END 
    
    DECLARE @MaxSeq INT ,
            @Count INT


    SELECT @Count = Count(1) FROM #costel_TSLDelvContractItem WHERE WorkingTag = 'A' AND Status = 0
    IF @Count >0 
    BEGIN
        SELECT @MaxSeq = ISNULL( Max(A.ContractSerl),0)
          FROM costel_TSLDelvContractItem AS A
          JOIN #costel_TSLDelvContractItem AS B ON A.ContractSeq = B.ContractSeq
         WHERE A.CompanySeq  = @CompanySeq 
           AND B.WorkingTag = 'A'            
           AND B.Status = 0 
        
        UPDATE #costel_TSLDelvContractItem                
           SET ContractSerl = @MaxSeq + DataSeq   
         WHERE WorkingTag = 'A'            
           AND Status = 0 
    END             
            
    SELECT * FROM #costel_TSLDelvContractItem   
      
    RETURN  
    GO
exec costel_SSLDelvContractItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Sel>0</Sel>
    <ContractSerl>1</ContractSerl>
    <ContractSeq>25</ContractSeq>
    <DelvExpectDate>20130912</DelvExpectDate>
    <ChangeDeliveyDate>20130913</ChangeDeliveyDate>
    <ItemName>@��������������</ItemName>
    <ItemNo>@������������</ItemNo>
    <Spec />
    <UnitName>EA</UnitName>
    <DelvQty>12</DelvQty>
    <DelvPrice>13</DelvPrice>
    <DelvAmt>156</DelvAmt>
    <DelvVatAmt>16</DelvVatAmt>
    <SumDelvAmt>172</SumDelvAmt>
    <SalesExpectDate />
    <Remark />
    <ChangeReason />
    <ExpReceiptDate />
    <ItemSeq>14531</ItemSeq>
    <UnitSeq>2</UnitSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017531,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014985