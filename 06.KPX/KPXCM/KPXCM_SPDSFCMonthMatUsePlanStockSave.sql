  
IF OBJECT_ID('KPXCM_SPDSFCMonthMatUsePlanStockSave') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCMonthMatUsePlanStockSave  
GO  
  
-- v2015.11.03  
  
-- ���ο��� ����ȹ��-���� by ����õ   
CREATE PROC KPXCM_SPDSFCMonthMatUsePlanStockSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPXCM_TPDSFCMonthMatUsePlanStock (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TPDSFCMonthMatUsePlanStock'   
    IF @@ERROR <> 0 RETURN    
      
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TPDSFCMonthMatUsePlanStock')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TPDSFCMonthMatUsePlanStock'    , -- ���̺��        
                  '#KPXCM_TPDSFCMonthMatUsePlanStock'    , -- �ӽ� ���̺��        
                  'FactUnit,PlanYM,ItemSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDSFCMonthMatUsePlanStock WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.RepalceQtyM = A.RepalceQtyM,  
               B.RepalceQtyM1 = A.RepalceQtyM1,  
               B.RepalceQtyM2 = A.RepalceQtyM2,  
                 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
                 
          FROM #KPXCM_TPDSFCMonthMatUsePlanStock AS A   
          JOIN KPXCM_TPDSFCMonthMatUsePlanStock AS B ON ( B.CompanySeq = @CompanySeq AND B.FactUnit = A.FactUnit AND B.PlanYM = A.PlanYM AND B.ItemSeq = A.ItemSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    SELECT * FROM #KPXCM_TPDSFCMonthMatUsePlanStock   
      
    RETURN  