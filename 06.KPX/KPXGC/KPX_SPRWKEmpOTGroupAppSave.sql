  
IF OBJECT_ID('KPX_SPRWKEmpOTGroupAppSave') IS NOT NULL   
    DROP PROC KPX_SPRWKEmpOTGroupAppSave  
GO  
  
-- v2014.12.17  
  
-- OT�ϰ���û-���� by ����õ   
CREATE PROC KPX_SPRWKEmpOTGroupAppSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPX_TPRWKEmpOTGroupApp (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPRWKEmpOTGroupApp'   
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPRWKEmpOTGroupApp')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPRWKEmpOTGroupApp'    , -- ���̺��        
                  '#KPX_TPRWKEmpOTGroupApp'    , -- �ӽ� ���̺��        
                  'GroupAppSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRWKEmpOTGroupApp WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        DELETE B   
          FROM #KPX_TPRWKEmpOTGroupApp AS A   
          JOIN KPX_TPRWKEmpOTGroupApp AS B ON ( B.CompanySeq = @CompanySeq AND B.GroupAppSeq = A.GroupAppSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE       
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRWKEmpOTGroupApp WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN    
        UPDATE B
           SET BaseDate = A.BaseDate, 
               LastUserSeq = @UserSeq, 
               LastDateTime = GETDATE()
          FROM #KPX_TPRWKEmpOTGroupApp AS A   
          JOIN KPX_TPRWKEmpOTGroupApp AS B ON ( B.CompanySeq = @CompanySeq AND B.GroupAppSeq = A.GroupAppSeq )   
    END 
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRWKEmpOTGroupApp WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TPRWKEmpOTGroupApp  
        (   
            CompanySeq,GroupAppSeq,BaseDate,GroupAppNo,LastUserSeq,  
            LastDateTime   
        )   
        SELECT @CompanySeq,A.GroupAppSeq,A.BaseDate,A.GroupAppNo,@UserSeq,  
               GETDATE()   
          FROM #KPX_TPRWKEmpOTGroupApp AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    SELECT * FROM #KPX_TPRWKEmpOTGroupApp   
      
    RETURN  