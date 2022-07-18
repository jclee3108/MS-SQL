  
IF OBJECT_ID('KPX_SEis_FINANCING_STATUSSave') IS NOT NULL   
    DROP PROC KPX_SEis_FINANCING_STATUSSave  
GO  
  
-- v2014.11.26  
  
-- (�濵����)�ڱ� ���� ��Ȳ-���� by ����õ   
CREATE PROC KPX_SEis_FINANCING_STATUSSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPX_TEIS_FINANCING_STATUS (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEIS_FINANCING_STATUS'   
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TEIS_FINANCING_STATUS')    

    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEIS_FINANCING_STATUS WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TEIS_FINANCING_STATUS'    , -- ���̺��        
                      '#KPX_TEIS_FINANCING_STATUS'    , -- �ӽ� ���̺��        
                      'PlanYM'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                      @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
        
        DELETE B   
          FROM #KPX_TEIS_FINANCING_STATUS AS A   
          JOIN KPX_TEIS_FINANCING_STATUS AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanYM = A.PlanYM )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  

          
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEIS_FINANCING_STATUS WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TEIS_FINANCING_STATUS'    , -- ���̺��        
                      '#KPX_TEIS_FINANCING_STATUS'    , -- �ӽ� ���̺��        
                      'BizUnit,PlanYM,UMSupply'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                      @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
        
        UPDATE B   
           SET B.ResultUpAmt = A.ResultUpAmt,  
               B.ResultDownAmt = A.ResultDownAmt,  
               B.PlanUpAmt = A.PlanUpAmt,  
               B.PlanDownAmt = A.PlanDownAmt,  
               B.AmtRate = A.AmtRate,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE() 
        
          FROM #KPX_TEIS_FINANCING_STATUS AS A   
          JOIN KPX_TEIS_FINANCING_STATUS AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit AND B.PlanYM = A.PlanYM AND B.UMSupply = A.UMSupply )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEIS_FINANCING_STATUS WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TEIS_FINANCING_STATUS  
        (   
            CompanySeq,BizUnit,PlanYM,UMSupply,ResultUpAmt,  
            ResultDownAmt,PlanUpAmt,PlanDownAmt,AmtRate,LastUserSeq,  
            LastDateTime   
        )   
          SELECT @CompanySeq,A.BizUnit,A.PlanYM,A.UMSupply,A.ResultUpAmt,  
               A.ResultDownAmt,A.PlanUpAmt,A.PlanDownAmt,A.AmtRate,@UserSeq,  
               GETDATE()   
          FROM #KPX_TEIS_FINANCING_STATUS AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_TEIS_FINANCING_STATUS   
      
    RETURN  