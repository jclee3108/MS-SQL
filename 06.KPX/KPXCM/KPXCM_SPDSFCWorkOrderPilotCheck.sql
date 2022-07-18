  
IF OBJECT_ID('KPXCM_SPDSFCWorkOrderPilotCheck') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCWorkOrderPilotCheck  
GO  
  
-- v2016.03.02  
  
-- ����۾������Է�-üũ by ����õ   
CREATE PROC KPXCM_SPDSFCWorkOrderPilotCheck  
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
      
    CREATE TABLE #KPXCM_TPDSFCWorkOrderPilot( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TPDSFCWorkOrderPilot'   
    IF @@ERROR <> 0 RETURN     
    
    -----------------------------------------------------------------
    -- üũ1, Ȯ�� �� �����ʹ� ����/���� �� �� �����ϴ�. 
    -----------------------------------------------------------------
    UPDATE A 
       SET Result = 'Ȯ�� �� �����ʹ� ����/���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPXCM_TPDSFCWorkOrderPilot AS A 
      JOIN KPXCM_TPDSFCWorkOrderPilot  AS B ON ( B.CompanySeq = @CompanySeq AND B.PilotSeq = A.PilotSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
       AND B.IsCfm = '1' 
    -----------------------------------------------------------------
    -- üũ1, Ȯ�� �� �����ʹ� ����/���� �� �� �����ϴ�. 
    -----------------------------------------------------------------
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPXCM_TPDSFCWorkOrderPilot WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TPDSFCWorkOrderPilot', 'PilotSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPXCM_TPDSFCWorkOrderPilot  
           SET PilotSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  

    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPXCM_TPDSFCWorkOrderPilot   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPXCM_TPDSFCWorkOrderPilot  
     WHERE Status = 0  
       AND ( PilotSeq = 0 OR PilotSeq IS NULL )  
      
    SELECT * FROM #KPXCM_TPDSFCWorkOrderPilot   
      
    RETURN  
    
    go
    begin tran
exec KPXCM_SPDSFCWorkOrderPilotCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <WorkCond6Old>04</WorkCond6Old>
    <LotNOSeq />
    <ProdPlanSeq>15946</ProdPlanSeq>
    <WorkOrderSeq>142227</WorkOrderSeq>
    <WorkOrderNo>201612010004        </WorkOrderNo>
    <ProdPlanNo>201612010010</ProdPlanNo>
    <IsCfm>1</IsCfm>
    <PilotSeq>1</PilotSeq>
    <WorkCenterSeq>8</WorkCenterSeq>
    <WorkCenterName>8R-1</WorkCenterName>
    <ItemSeq>763</ItemSeq>
    <ItemName>G-BE-2</ItemName>
    <LotNo>15110004</LotNo>
    <OriDuration>0</OriDuration>
    <SrtDate>20161201</SrtDate>
    <OriDurHour />
    <SrtHour>09:00</SrtHour>
    <EndDate>20161201</EndDate>
    <EndHour>15:00</EndHour>
    <Duration>360</Duration>
    <DurHour>06:00</DurHour>
    <ProdQty>10</ProdQty>
    <WorkCond6>04</WorkCond6>
    <WorkCond6Name>04[14227}</WorkCond6Name>
    <Remark>test</Remark>
    <SubItemSeq>0</SubItemSeq>
    <SubItemName />
    <AfterWorkSeq />
    <AfterWorkName />
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1035544,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1029271
rollback 