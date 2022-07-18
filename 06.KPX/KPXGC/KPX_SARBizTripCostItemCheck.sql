  
IF OBJECT_ID('KPX_SARBizTripCostItemCheck') IS NOT NULL   
    DROP PROC KPX_SARBizTripCostItemCheck  
GO  
  
-- v2015.01.08  
  
-- ���������ǰ�Ǽ�-SS1üũ by ����õ   
CREATE PROC KPX_SARBizTripCostItemCheck  
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
    
    CREATE TABLE #KPX_TARBizTripCostCardCfm( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TARBizTripCostCardCfm'   
    IF @@ERROR <> 0 RETURN     
    
    -- üũ1, ��ǥ�� ���� �� �����ʹ� ����, ���� �� �� �����ϴ�. 
    UPDATE A
       SET Result = '��ǥ�� ���� �� �����ʹ� ����, ���� �� �� �����ϴ�. ', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPX_TARBizTripCostCardCfm AS A 
      JOIN KPX_TARBizTripCost  AS B ON ( B.CompanySeq = @CompanySeq AND B.BizTripSeq = A.BizTripSeq AND B.SlipMstSeq <> 0 ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
    -- üũ1, END
    
    SELECT * FROM #KPX_TARBizTripCostCardCfm   
    
    RETURN  