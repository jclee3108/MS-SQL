  
IF OBJECT_ID('KPXHD_SFAFundChargeClaimCheck') IS NOT NULL   
    DROP PROC KPXHD_SFAFundChargeClaimCheck  
GO  
  
-- v2016.02.03  
  
-- �ڱݿ����������û�������Է�-üũ by ����õ   
CREATE PROC KPXHD_SFAFundChargeClaimCheck  
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
      
    CREATE TABLE #KPXHD_TFAFundChargeClaim( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXHD_TFAFundChargeClaim'   
    IF @@ERROR <> 0 RETURN     
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPXHD_TFAFundChargeClaim WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXHD_TFAFundChargeClaim', 'FundChargeSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPXHD_TFAFundChargeClaim  
           SET FundChargeSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPXHD_TFAFundChargeClaim   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPXHD_TFAFundChargeClaim  
     WHERE Status = 0  
       AND ( FundChargeSeq = 0 OR FundChargeSeq IS NULL )  
       
    
    SELECT * FROM #KPXHD_TFAFundChargeClaim   
    
    RETURN  
    go
    begin tran
exec KPXHD_SFAFundChargeClaimCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <FromTo>2016-01-26 ~ 2016-02-25</FromTo>
    <StdYM>201602</StdYM>
    <TotExcessProfitAmt>51351</TotExcessProfitAmt>
    <TotAdviceAmt>5135</TotAdviceAmt>
    <LastYMClaimAmt>0</LastYMClaimAmt>
    <StdYMClaimAmt>5135</StdYMClaimAmt>
    <FundChargeSeq>0</FundChargeSeq>
    <UMHelpCom>1010494001</UMHelpCom>
    <UMHelpComName>KPXHD</UMHelpComName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034645,@WorkingTag=N'',@CompanySeq=4,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1028674

rollback 