  
IF OBJECT_ID('KPX_SPUTransImpOrderCheck') IS NOT NULL   
    DROP PROC KPX_SPUTransImpOrderCheck  
GO  
  
-- v2014.11.28  
  
-- ���Կ������-üũ by ����õ   
CREATE PROC KPX_SPUTransImpOrderCheck  
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
    
    CREATE TABLE #KPX_TPUTransImpOrder( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPUTransImpOrder'   
    IF @@ERROR <> 0 RETURN     
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TPUTransImpOrder WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
    
    
        DECLARE @MaxNo      NVARCHAR(50), 
                @BaseDate   NCHAR(8)
          
        SELECT @BaseDate = ISNULL( MAX(TransDate), CONVERT( NVARCHAR(8), GETDATE(), 112 ) )  
          FROM #KPX_TPUTransImpOrder   
         WHERE WorkingTag = 'A'   
           AND Status = 0     
        
        EXEC dbo._SCOMCreateNo 'SL', 'KPX_TPUTransImpOrder', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT      
        
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TPUTransImpOrder', 'TransImpSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPX_TPUTransImpOrder  
           SET TransImpSeq = @Seq + DataSeq, 
               TransImpNo = @MaxNo
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
      

    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_TPUTransImpOrder   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TPUTransImpOrder  
     WHERE Status = 0  
       AND ( TransImpSeq = 0 OR TransImpSeq IS NULL )  
      
    SELECT * FROM #KPX_TPUTransImpOrder   
      
    RETURN  
GO 
BEGIN TRAN 
exec KPX_SPUTransImpOrderCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <BLNo />
    <TransImpSeq>0</TransImpSeq>
    <TransImpNo />
    <UMCont>1010302001</UMCont>
    <UMPayGet>8050001</UMPayGet>
    <UMCountry>20182002</UMCountry>
    <UMPort>8207033</UMPort>
    <BizUnit>2</BizUnit>
    <OrderDate>20141128</OrderDate>
    <SMImpKind>8008004</SMImpKind>
    <UMPriceTerms>8201003</UMPriceTerms>
    <UMPayment1>8202001</UMPayment1>
    <DeptSeq>135</DeptSeq>
    <ExRate>1</ExRate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026300,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021338

rollback 