  
IF OBJECT_ID('KPX_SSLMonthSalesPlanDlgSave') IS NOT NULL   
    DROP PROC KPX_SSLMonthSalesPlanDlgSave  
GO  
  
-- v2014.11.14  
  
-- �����ǸŰ�ȹ�Է�Dlg-���� by ����õ   
CREATE PROC KPX_SSLMonthSalesPlanDlgSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TSLMonthSalesPlanRev (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TSLMonthSalesPlanRev'   
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TSLMonthSalesPlanRev')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TSLMonthSalesPlanRev'    , -- ���̺��        
                  '#KPX_TSLMonthSalesPlanRev'    , -- �ӽ� ���̺��        
                  'BizUnit,PlanYM,PlanRev'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TSLMonthSalesPlanRev WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TSLMonthSalesPlanRev  
        (   
            CompanySeq,BizUnit,PlanYM,PlanRev,LastUserSeq,  
            LastDateTime   
        )   
        SELECT @CompanySeq,A.BizUnit,A.PlanYM,A.PlanRev,@UserSeq,  
               GETDATE()   
          FROM #KPX_TSLMonthSalesPlanRev AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    IF EXISTS (SELECT 1 
                 FROM #KPX_TSLMonthSalesPlanRev AS A 
                 JOIN KPX_TSLMonthSalesPlanRev  AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit AND B.PlanYM = A.PlanYM AND B.PlanRev = A.PlanRev ) 
              ) 
    BEGIN 
        UPDATE A
           SET IsApply = '1' 
          FROM #KPX_TSLMonthSalesPlanRev AS A 
    END 
    
    SELECT * FROM #KPX_TSLMonthSalesPlanRev   
      
    RETURN  