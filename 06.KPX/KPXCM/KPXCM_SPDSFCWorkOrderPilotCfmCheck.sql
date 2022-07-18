  
IF OBJECT_ID('KPXCM_SPDSFCWorkOrderPilotCfmCheck') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCWorkOrderPilotCfmCheck  
GO  
  
-- v2016.03.02 
  
-- ����۾������Է�-Ȯ�� üũ by ����õ   
CREATE PROC KPXCM_SPDSFCWorkOrderPilotCfmCheck  
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
    
    
    IF @WorkingTag = 'Cfm' 
    BEGIN 
        UPDATE #KPXCM_TPDSFCWorkOrderPilot
           SET WorkingTag = 'A'    
    END 
    ELSE
    BEGIN 
        UPDATE #KPXCM_TPDSFCWorkOrderPilot
           SET WorkingTag = 'D'
    END 
    
    ------------------------------------------------------------
    -- üũ1, �̹� Ȯ�� �� �������Դϴ�. 
    ------------------------------------------------------------
    UPDATE A 
       SET Result = '�̹� Ȯ�� �� �������Դϴ�.', 
           Status = 1234, 
           MessageType = 1234
      FROM #KPXCM_TPDSFCWorkOrderPilot  AS A 
      JOIN KPXCM_TPDSFCWorkOrderPilot   AS B ON ( B.CompanySeq = @CompanySeq AND B.PilotSeq = A.PilotSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
       AND B.IsCfm = '1' 
    ------------------------------------------------------------
    -- üũ1, END 
    ------------------------------------------------------------
    
    ------------------------------------------------------------
    -- üũ2, Ȯ�� ���� ���� �������Դϴ�. 
    ------------------------------------------------------------
    UPDATE A 
       SET Result = 'Ȯ�� ���� ���� �������Դϴ�.', 
           Status = 1234, 
           MessageType = 1234
      FROM #KPXCM_TPDSFCWorkOrderPilot  AS A 
      JOIN KPXCM_TPDSFCWorkOrderPilot   AS B ON ( B.CompanySeq = @CompanySeq AND B.PilotSeq = A.PilotSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'D' 
       AND B.IsCfm = '0'
    ------------------------------------------------------------
    -- üũ2, END 
    ------------------------------------------------------------
    
    ------------------------------------------------------------
    -- üũ3, ������� �����Ͱ� �����Ͽ� Ȯ����� �� �� �����ϴ�.
    ------------------------------------------------------------
    UPDATE A 
       SET Result = '������� �����Ͱ� �����Ͽ� Ȯ����� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234
      FROM #KPXCM_TPDSFCWorkOrderPilot  AS A 
      JOIN _TPDSFCWorkReport            AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkOrderSeq = A.WorkOrderSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'D' 
    ------------------------------------------------------------
    -- üũ3, END 
    ------------------------------------------------------------
    
    ------------------------------------------------------------
    -- üũ4, ������ ����Ǿ� Ȯ����� �� �� �����ϴ�.
    ------------------------------------------------------------
    UPDATE A 
       SET Result = '������ ����Ǿ� Ȯ����� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234
      FROM #KPXCM_TPDSFCWorkOrderPilot  AS A 
      JOIN KPX_TPDSFCWorkOrder_POP      AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkOrderSeq = A.WorkOrderSeq AND B.ProcYn <> '0' ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'D' 
    ------------------------------------------------------------
    -- üũ4, END 
    ------------------------------------------------------------
    
    
    SELECT * FROM #KPXCM_TPDSFCWorkOrderPilot 
    
        
    RETURN  
    go
    begin tran
exec KPXCM_SPDSFCWorkOrderPilotCfmCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ProdPlanSeq>15948</ProdPlanSeq>
    <WorkOrderSeq>142229</WorkOrderSeq>
    <WorkOrderNo>201612010006        </WorkOrderNo>
    <ProdPlanNo>201612010012</ProdPlanNo>
    <IsCfm>1</IsCfm>
    <PilotSeq>1</PilotSeq>
    <AfterWorkSeq />
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1035544,@WorkingTag=N'CfmCan',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1029271
rollback 