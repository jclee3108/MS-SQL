  
IF OBJECT_ID('costel_SSLDelvContractCheck') IS NOT NULL   
    DROP PROC costel_SSLDelvContractCheck  
GO  
  
-- v2013.09.04  
  
-- ��ǰ�����_costel(üũ) by����õ   
CREATE PROC costel_SSLDelvContractCheck  
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
      
    CREATE TABLE #costel_TSLDelvContract( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#costel_TSLDelvContract'   
    IF @@ERROR <> 0 RETURN     
      --select * from #costel_TSLDelvContract
    
    -- üũ1, �ߴ�ó���� �Ǿ� ����,����,���� �� �� �����ϴ�.
    
    UPDATE A
       SET Result = N'�ߴ�ó���� �Ǿ� ����,����,���� �� �� �����ϴ�.',
           Status = 123412
      FROM #costel_TSLDelvContract AS A 
      JOIN costel_TSLDelvContract AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
      
    WHERE A.Status = 0
      AND B.IsStop = 1 
    
    -- üũ1, END 
    
    -- üũ2, �̹� Ȯ��ó���� �Ǿ� ����,����,���� �� �� �����ϴ�.
    
    UPDATE A
       SET Result = N'�̹� Ȯ��ó���� �Ǿ� ���� �� �� �����ϴ�.',
           Status = 123412
      FROM #costel_TSLDelvContract AS A 
      JOIN costel_TSLDelvContract AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
    WHERE A.WorkingTag = 'D'
      AND A.Status = 0
      AND B.IsCfm = 1 
    
    -- üũ2, END 
    
    -- üũ3, ���������� ��� �� ����, ���� �� �� �ֽ��ϴ�. 
    
    UPDATE A
       SET Result = N'���������� ��� �� ����, ���� �� �� �ֽ��ϴ�.', 
           Status = 21312
      FROM #costel_TSLDelvContract AS A
     WHERE ContractRev <> (SELECT ContractRev 
                             FROM costel_TSLDelvContract AS B 
                            WHERE B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq
                          ) 
        AND A.Status = 0
    
    -- üũ3, END
    
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #costel_TSLDelvContract WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN      
    
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'costel_TSLDelvContract', 'ContractSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #costel_TSLDelvContract  
           SET ContractSeq = @Seq + DataSeq 
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #costel_TSLDelvContract   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #costel_TSLDelvContract  
     WHERE Status = 0  
       AND ( ContractSeq = 0 OR ContractSeq IS NULL )  
      
    SELECT * FROM #costel_TSLDelvContract   
      
    RETURN  
    GO
exec costel_SSLDelvContractCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ContractRev>3</ContractRev>
    <ContractSeq>45</ContractSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017531,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014985