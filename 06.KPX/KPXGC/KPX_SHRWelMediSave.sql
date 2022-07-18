  
IF OBJECT_ID('KPX_SHRWelMediSave') IS NOT NULL   
    DROP PROC KPX_SHRWelMediSave  
GO  
  
-- v2014.12.02  
  
-- �Ƿ���û-���� by ����õ   
CREATE PROC KPX_SHRWelMediSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    CREATE TABLE #KPX_THRWelMedi (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THRWelMedi'   
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_THRWelMedi')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_THRWelMedi'    , -- ���̺��        
                  '#KPX_THRWelMedi'    , -- �ӽ� ���̺��        
                  'WelMediSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWelMedi WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN 
        
        DELETE B   
          FROM #KPX_THRWelMedi AS A   
          JOIN KPX_THRWelMedi AS B ON ( B.CompanySeq = @CompanySeq AND A.WelMediSeq = B.WelMediSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
        
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_THRWelMediItem')  
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_THRWelMediItem'    , -- ���̺��        
                      '#KPX_THRWelMedi'    , -- �ӽ� ���̺��        
                      'WelMediSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                      @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
        
        DELETE B   
          FROM #KPX_THRWelMedi AS A   
          JOIN KPX_THRWelMediItem AS B ON ( B.CompanySeq = @CompanySeq AND A.WelMediSeq = B.WelMediSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
        
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWelMedi WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN 
    
        UPDATE B   
           SET B.YY   = A.YY,  
               B.RegSeq  = A.RegSeq,   
               B.BaseDate = A.BaseDate, 
               B.EmpSeq = A.EmpSeq, 
               B.ComAmt = A.ComAmt, 
               B.LastUserSeq = @UserSeq, 
               B.LastDateTime = GETDATE() 
          FROM #KPX_THRWelMedi AS A   
          JOIN KPX_THRWelMedi AS B ON ( B.CompanySeq = @CompanySeq AND A.WelMediSeq = B.WelMediSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWelMedi WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_THRWelMedi  
        (   
            CompanySeq,WelMediSeq,YY,RegSeq,BaseDate,
            EmpSeq,ComAmt,LastUserSeq,LastDateTime
        )   
        SELECT @CompanySeq, A.WelMediSeq, A.YY, A.RegSeq, A.BaseDate,
               A.EmpSeq, A.ComAmt, @UserSeq, GETDATE() 
          FROM #KPX_THRWelMedi AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_THRWelMedi   
      
    RETURN  