  
IF OBJECT_ID('KPXCM_SPDSFCMonthMatUsePlanScenarioSave') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCMonthMatUsePlanScenarioSave  
GO  
  
-- v2016.05.26 
  
-- ���ο��� ����ȹ��(�����ȹ�ó�����)-���� by ����õ   
CREATE PROC KPXCM_SPDSFCMonthMatUsePlanScenarioSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPXCM_TPDSFCMonthMatUsePlanScenario (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TPDSFCMonthMatUsePlanScenario'   
    IF @@ERROR <> 0 RETURN    
      
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TPDSFCMonthMatUsePlanScenario')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TPDSFCMonthMatUsePlanScenario'    , -- ���̺��        
                  '#KPXCM_TPDSFCMonthMatUsePlanScenario'    , -- �ӽ� ���̺��        
                  'FactUnit,PlanYM,PlanRev,ItemSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDSFCMonthMatUsePlanScenario WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.RepalceQtyM = A.RepalceQtyM, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
                 
          FROM #KPXCM_TPDSFCMonthMatUsePlanScenario AS A   
          JOIN KPXCM_TPDSFCMonthMatUsePlanScenario  AS B ON ( B.CompanySeq = @CompanySeq 
                                                          AND B.FactUnit = A.FactUnit 
                                                          AND B.PlanYM = A.PlanYM 
                                                          AND B.ItemSeq = A.ItemSeq 
                                                          AND B.PlanRev = A.PlanRev
                                                            )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    SELECT * FROM #KPXCM_TPDSFCMonthMatUsePlanScenario   
      
    RETURN  