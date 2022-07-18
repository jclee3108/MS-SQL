  
IF OBJECT_ID('KPX_SARBizTripCostSlipCheck') IS NOT NULL   
    DROP PROC KPX_SARBizTripCostSlipCheck  
GO  
  
-- v2015.01.08 

-- ���������ǰ�Ǽ�-Slipüũ by ����õ
CREATE PROC KPX_SARBizTripCostSlipCheck  
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
    
    CREATE TABLE #TACSlip_Sub( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TACSlip_Sub'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT * FROM #TACSlip_Sub 
    
    RETURN  