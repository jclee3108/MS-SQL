  
IF OBJECT_ID('KPX_SPDSFCProdPackOrderCheck') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackOrderCheck  
GO  
  
-- v2014.11.25  
  
-- �����۾������Է�-üũ by ����õ   
CREATE PROC KPX_SPDSFCProdPackOrderCheck  
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
    
    CREATE TABLE #KPX_TPDSFCProdPackOrder( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPDSFCProdPackOrder'   
    IF @@ERROR <> 0 RETURN     
    
    UPDATE A
       SET WorkingTag = 'U' 
      FROM #KPX_TPDSFCProdPackOrder AS A 
     WHERE WorkingTag = 'A' 
       AND ISNULL(PackOrderSeq,0) <> 0
    
    -- ����������üũ: UPDATE, DELETE�� ������ �������� ������ ����ó��  
    IF NOT EXISTS ( SELECT 1   
                      FROM #KPX_TPDSFCProdPackOrder AS A   
                      JOIN KPX_TPDSFCProdPackOrder AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.PackOrderSeq = B.PackOrderSeq )  
                     WHERE A.WorkingTag IN ( 'U', 'D' )  
                       AND Status = 0   
                  )  
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              7                  , -- �ڷᰡ��ϵǾ������ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                              @LanguageSeq               
          
        UPDATE #KPX_TPDSFCProdPackOrder  
           SET Result       = @Results,  
               MessageType  = @MessageType,  
               Status       = @Status  
         WHERE WorkingTag IN ( 'U', 'D' )  
           AND Status = 0   
    END   
    

    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TPDSFCProdPackOrder WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
          DECLARE @BaseDate           NVARCHAR(8),   
                  @SMFirstInitialUnit INT,  
                  @MaxNo              NVARCHAR(50)  
          
        SELECT @BaseDate    = ISNULL( MAX(PackDate), CONVERT( NVARCHAR(8), GETDATE(), 112 ) )  
          FROM #KPX_TPDSFCProdPackOrder   
         WHERE WorkingTag = 'A'   
           AND Status = 0     
        
          
        EXEC dbo._SCOMCreateNo 'SL', 'KPX_TPDSFCProdPackOrder', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT      
          
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TPDSFCProdPackOrder', 'PackOrderSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPX_TPDSFCProdPackOrder  
           SET PackOrderSeq = @Seq + DataSeq, 
               OrderNo = @MaxNo      
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE A   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TPDSFCProdPackOrder AS A 
     WHERE Status = 0  
       AND ( PackOrderSeq = 0 OR PackOrderSeq IS NULL )  
      
    SELECT * FROM #KPX_TPDSFCProdPackOrder   
      
    RETURN  
GO 
begin tran 

exec KPX_SPDSFCProdPackOrderCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <FactUnit>1</FactUnit>
    <PackDate>20141125</PackDate>
    <OrderNo>141125008</OrderNo>
    <OutWHSeq>2</OutWHSeq>
    <InWHSeq>3</InWHSeq>
    <Remark>test</Remark>
    <UMProgType>1010345001</UMProgType>
    <PackOrderSeq>11</PackOrderSeq>
    <SubOutWHSeq>4</SubOutWHSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026147,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021349
rollback 