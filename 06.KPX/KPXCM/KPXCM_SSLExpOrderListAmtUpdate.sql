  
IF OBJECT_ID('KPXCM_SSLExpOrderListAmtUpdate') IS NOT NULL   
    DROP PROC KPXCM_SSLExpOrderListAmtUpdate  
GO  
  
-- v2016.03.28 
  
-- ����Orderǰ����ȸ-Amt������Ʈ by ����õ 
CREATE PROC KPXCM_SSLExpOrderListAmtUpdate  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TSLOrderItemAdd (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TSLOrderItemAdd'   
    IF @@ERROR <> 0 RETURN    
      
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TSLOrderItemAdd')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TSLOrderItemAdd'    , -- ���̺��        
                  '#KPX_TSLOrderItemAdd'    , -- �ӽ� ���̺��        
                  'OrderSeq,OrderSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TSLOrderItemAdd WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
    
        UPDATE A   
           SET FOBPrice     = B.FOBPrice,  
               TransPrice   = B.TransPrice,  
               FOBAmtUSD    = B.FOBAmtUSD,  
               FOBAmtKRW    = B.FOBAmtKRW,  
               ExpAmtUSD    = B.ExpAmtUSD,  
               ExpAmtKRW    = B.ExpAmtKRW,  
               LastUserSeq  = @UserSeq,  
               LastDateTime = GETDATE()
                 
          FROM KPX_TSLOrderItemAdd  AS A 
          JOIN #KPX_TSLOrderItemAdd AS B ON ( B.OrderSeq = A.OrderSeq AND B.OrderSerl = A.OrderSerl ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND B.WorkingTag = 'U'   
           AND B.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    SELECT * FROM #KPX_TSLOrderItemAdd   
      
    RETURN  
    
    
    
go
--begin tran
--exec KPXCM_SSLExpOrderListAmtUpdate @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>U</WorkingTag>
--    <IDX_NO>2</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <OrderSeq>1002929</OrderSeq>
--    <OrderSerl>1</OrderSerl>
--    <FOBPrice>200</FOBPrice>
--    <FOBAmtUSD>200</FOBAmtUSD>
--    <FOBAmtKRW>231640</FOBAmtKRW>
--    <TransPrice>-100</TransPrice>
--    <ExpAmtUSD>-100</ExpAmtUSD>
--    <ExpAmtKRW>-115820</ExpAmtKRW>
--    <TABLE_NAME>DataBlock1</TABLE_NAME>
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1030593,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025040
--rollback 
