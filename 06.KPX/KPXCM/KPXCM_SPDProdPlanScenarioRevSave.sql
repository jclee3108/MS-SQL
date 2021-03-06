  
IF OBJECT_ID('KPXCM_SPDProdPlanScenarioRevSave') IS NOT NULL   
    DROP PROC KPXCM_SPDProdPlanScenarioRevSave  
GO  
  
-- v2016.05.20  
  
-- 생산계획시나리오 차수관리-저장 by 이재천   
CREATE PROC KPXCM_SPDProdPlanScenarioRevSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPXCM_TPDMonthProdPlanRev (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TPDMonthProdPlanRev'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TPDMonthProdPlanRev')    
    
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TPDMonthProdPlanRev'    , -- 테이블명        
                  '#KPXCM_TPDMonthProdPlanRev'    , -- 임시 테이블명        
                  'FactUnit,PlanYM,PlanRev'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDMonthProdPlanRev WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPXCM_TPDMonthProdPlanRev AS A   
          JOIN KPXCM_TPDMonthProdPlanRev AS B ON ( B.CompanySeq = @CompanySeq AND B.FactUnit = A.FactUnit AND B.PlanYM = A.PlanYM AND B.PlanRev = A.PlanRev )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDMonthProdPlanRev WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.PlanRevName = A.PlanRevName,  
               B.Remark = A.Remark,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
          FROM #KPXCM_TPDMonthProdPlanRev AS A   
          JOIN KPXCM_TPDMonthProdPlanRev AS B ON ( B.CompanySeq = @CompanySeq AND B.FactUnit = A.FactUnit AND B.PlanYM = A.PlanYM AND B.PlanRev = A.PlanRev )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    SELECT * FROM #KPXCM_TPDMonthProdPlanRev   
      
    RETURN  