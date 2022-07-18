  
IF OBJECT_ID('KPX_SACDailyExpPlanItemSave') IS NOT NULL   
    DROP PROC KPX_SACDailyExpPlanItemSave  
GO  
  
-- v2014.12.09  
  
-- ���Ͽ�ȭ�Ű���ȹ��-�Ű� ���� by ����õ   
CREATE PROC KPX_SACDailyExpPlanItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    CREATE TABLE #KPX_TACDailyExpPlanItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TACDailyExpPlanItem'   
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TACDailyExpPlanItem')    
    
    IF @WorkingTag = 'Del' -- ���� 
    BEGIN 
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TACDailyExpPlanItem'    , -- ���̺��        
                      '#KPX_TACDailyExpPlanItem'    , -- �ӽ� ���̺��        
                      'BaseDate'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� ) 
                      @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    END 
    ELSE 
    BEGIN -- ����, ��Ʈ���� 
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TACDailyExpPlanItem'    , -- ���̺��        
                      '#KPX_TACDailyExpPlanItem'    , -- �ӽ� ���̺��        
                      'BaseDate,Serl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� ) 
                      @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    END 
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACDailyExpPlanItem WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN 
        
        IF @WorkingTag = 'Del' 
        BEGIN -- ���� 
            DELETE B   
              FROM #KPX_TACDailyExpPlanItem AS A   
              JOIN KPX_TACDailyExpPlanItem AS B ON ( B.CompanySeq = @CompanySeq AND A.BaseDate = B.BaseDate )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
              
            IF @@ERROR <> 0  RETURN  
        END 
        ELSE 
        BEGIN -- ��Ʈ ���� 
            DELETE B   
              FROM #KPX_TACDailyExpPlanItem AS A   
              JOIN KPX_TACDailyExpPlanItem AS B ON ( B.CompanySeq = @CompanySeq AND A.BaseDate = B.BaseDate AND B.Serl = A.Serl )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
              
            IF @@ERROR <> 0  RETURN  
        
        END 
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACDailyExpPlanItem WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.UMExpPlanSeq = A.UMExpPlanSeq, 
               B.UMBankSeq = A.UMBankSeq, 
               B.Amt = A.Amt, 
               B.ExRate = A.ExRate, 
               B.Remark = A.Remark, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
          FROM #KPX_TACDailyExpPlanItem AS A   
          JOIN KPX_TACDailyExpPlanItem AS B ON ( B.CompanySeq = @CompanySeq AND A.BaseDate = B.BaseDate AND A.Serl = B.Serl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACDailyExpPlanItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TACDailyExpPlanItem  
        (   
            CompanySeq, BaseDate, Serl, UMExpPlanSeq, UMBankSeq, 
            Amt, ExRate, Remark, LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.BaseDate, A.Serl, A.UMExpPlanSeq, A.UMBankSeq, 
               A.Amt, A.ExRate, A.Remark, @UserSeq, GETDATE()
          FROM #KPX_TACDailyExpPlanItem AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
        
    END     
    
    SELECT * FROM #KPX_TACDailyExpPlanItem   
    
    RETURN  