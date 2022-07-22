  
IF OBJECT_ID('hencom_SHRCompleteDateSS2Save') IS NOT NULL   
    DROP PROC hencom_SHRCompleteDateSS2Save  
GO  
    
-- v2017.07.27
  
-- �Ϸ��ϰ���-SS2���� by ����õ 
CREATE PROC hencom_SHRCompleteDateSS2Save 
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hencom_THRCompleteDateShare (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#hencom_THRCompleteDateShare'   
    IF @@ERROR <> 0 RETURN    
      
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_THRCompleteDateShare')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'hencom_THRCompleteDateShare'    , -- ���̺��        
                  '#hencom_THRCompleteDateShare'    , -- �ӽ� ���̺��        
                  'CompleteSeq,ShareSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_THRCompleteDateShare WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #hencom_THRCompleteDateShare AS A   
          JOIN hencom_THRCompleteDateShare AS B ON ( B.CompanySeq = @CompanySeq AND A.CompleteSeq = B.CompleteSeq AND A.ShareSerl = B.ShareSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_THRCompleteDateShare WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.EmpDeptSeq   = A.ShareEmpSeq, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
          FROM #hencom_THRCompleteDateShare AS A   
          JOIN hencom_THRCompleteDateShare AS B ON ( B.CompanySeq = @CompanySeq AND A.CompleteSeq = B.CompleteSeq AND A.ShareSerl = B.ShareSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_THRCompleteDateShare WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO hencom_THRCompleteDateShare  
        (   
            CompanySeq, CompleteSeq, ShareSerl, EmpDeptType, EmpDeptSeq, 
            LastUserSeq, LastDateTime, PgmSeq

        )   
        SELECT @CompanySeq, CompleteSeq, ShareSerl, 1, ShareEmpSeq, 
               @UserSeq, GETDATE(), @PgmSeq
          FROM #hencom_THRCompleteDateShare AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #hencom_THRCompleteDateShare   
      
    RETURN  
