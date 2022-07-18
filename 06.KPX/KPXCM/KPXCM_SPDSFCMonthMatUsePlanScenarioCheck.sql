  
IF OBJECT_ID('KPXCM_SPDSFCMonthMatUsePlanScenarioCheck') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCMonthMatUsePlanScenarioCheck  
GO  
  
-- v2016.05.26 
  
-- ���ο��� ����ȹ��(�����ȹ�ó�����)-üũ by ����õ   
CREATE PROC KPXCM_SPDSFCMonthMatUsePlanScenarioCheck  
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
      
    CREATE TABLE #KPXCM_TPDSFCMonthMatUsePlanScenario( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TPDSFCMonthMatUsePlanScenario'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT * FROM #KPXCM_TPDSFCMonthMatUsePlanScenario   
      
    RETURN  