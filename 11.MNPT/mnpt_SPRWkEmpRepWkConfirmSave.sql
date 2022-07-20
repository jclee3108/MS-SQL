  
IF OBJECT_ID('mnpt_SPRWkEmpRepWkConfirmSave') IS NOT NULL   
    DROP PROC mnpt_SPRWkEmpRepWkConfirmSave  
GO  
    
-- v2018.01.23
  
-- ���ϱٹ���ûȮ��-���� by ����õ
CREATE PROC mnpt_SPRWkEmpRepWkConfirmSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #mnpt_TPREEWkEmpRepWk (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#mnpt_TPREEWkEmpRepWk'   
    IF @@ERROR <> 0 RETURN    
      
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPREEWkEmpRepWk')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPREEWkEmpRepWk'    , -- ���̺��        
                  '#mnpt_TPREEWkEmpRepWk'    , -- �ӽ� ���̺��        
                  'EmpSeq, RepWkSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #mnpt_TPREEWkEmpRepWk WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.WkMoney        = A.WkMoney,  
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE(),  
               B.PgmSeq         = @PgmSeq    
                 
          FROM #mnpt_TPREEWkEmpRepWk AS A   
          JOIN mnpt_TPREEWkEmpRepWk AS B ON ( B.CompanySeq = @CompanySeq AND A.EmpSeq = B.EmpSeq AND A.RepWkSeq = B.RepWkSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    SELECT * FROM #mnpt_TPREEWkEmpRepWk   
      
    RETURN  
