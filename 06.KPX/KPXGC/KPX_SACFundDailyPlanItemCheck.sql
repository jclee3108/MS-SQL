  
IF OBJECT_ID('KPX_SACFundDailyPlanItemCheck') IS NOT NULL   
    DROP PROC KPX_SACFundDailyPlanItemCheck  
GO  
  
-- v2014.12.23  
  
-- ���ڱݰ�ȹ�Է�(�ڱ��Ϻ�)-SS2üũ by ����õ   
CREATE PROC KPX_SACFundDailyPlanItemCheck  
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
    
    CREATE TABLE #KPX_TACFundDailyPlanIn( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TACFundDailyPlanIn'   
    IF @@ERROR <> 0 RETURN     
    /*
    -- �ߺ����� üũ :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
                          @LanguageSeq       ,  
                          3542, '��1'--,  -- SELECT * FROM _TCADictionary WHERE Word like '%��%'  
                          --3543, '��2'  
      
    UPDATE #TSample  
       SET Result       = REPLACE( @Results, '@2', B.SampleName ), -- Ȥ�� @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #TSample AS A   
      JOIN (SELECT S.SampleName  
              FROM (SELECT A1.SampleName  
                      FROM #TSample AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.SampleName  
                      FROM _TSample AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #TSample   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND SampleSeq = A1.SampleSeq  
                                      )  
                   ) AS S  
             GROUP BY S.SampleName  
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.SampleName = B.SampleName )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    */
    
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TACFundDailyPlanIn WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TACFundDailyPlanIn', 'PlanInSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPX_TACFundDailyPlanIn  
           SET PlanInSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
      
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_TACFundDailyPlanIn   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TACFundDailyPlanIn  
     WHERE Status = 0  
       AND ( PlanInSeq = 0 OR PlanInSeq IS NULL )  
       AND WorkingTag <> 'D'
      
    SELECT * FROM #KPX_TACFundDailyPlanIn   
      
    RETURN  
GO 
exec KPX_SACFundDailyPlanItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Sort>1</Sort>
    <Summary>test</Summary>
    <BankAccName>012-041441-04-019</BankAccName>
    <BankName>������� ��â��</BankName>
    <BankSeq>0</BankSeq>
    <BankAccNo>012-041441-04-019</BankAccNo>
    <CurrName>USD</CurrName>
    <CurrSeq>2</CurrSeq>
    <ExRate>1</ExRate>
    <CurAmt>10000</CurAmt>
    <DomAmt>10000</DomAmt>
    <Remark1>setaset</Remark1>
    <Remark2>set</Remark2>
    <IsReplace>1</IsReplace>
    <AccName>��ȭ����</AccName>
    <AccSeq>1000022</AccSeq>
    <SlipMstID>A0-S1-20141223-0001</SlipMstID>
    <AccDate>20141223</AccDate>
    <SlipSummary>test</SlipSummary>
    <SlipMstSeq>0</SlipMstSeq>
    <PlanInSeq>0</PlanInSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <FundDate>20141223</FundDate>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027052,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021333