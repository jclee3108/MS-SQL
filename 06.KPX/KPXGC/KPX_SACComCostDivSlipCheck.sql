  
IF OBJECT_ID('KPX_SACComCostDivSlipCheck') IS NOT NULL   
    DROP PROC KPX_SACComCostDivSlipCheck  
GO  
  
-- v2014.11.10  
  
-- ����Ȱ������ ����� ��ü��ǥó��-üũ by ����õ   
CREATE PROC KPX_SACComCostDivSlipCheck  
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
      
    CREATE TABLE #KPX_TACComCostDivSlip( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TACComCostDivSlip'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT * FROM #KPX_TACComCostDivSlip   
      
    RETURN  