  
IF OBJECT_ID('KPX_SEQTaskOrderCHESave') IS NOT NULL   
    DROP PROC KPX_SEQTaskOrderCHESave  
GO  
  
-- v2014.12.08  
  
-- ������������-���� by ����õ   
CREATE PROC KPX_SEQTaskOrderCHESave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TEQTaskOrderCHE (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEQTaskOrderCHE'   
    IF @@ERROR <> 0 RETURN    
      
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TEQTaskOrderCHE')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TEQTaskOrderCHE'    , -- ���̺��        
                  '#KPX_TEQTaskOrderCHE'    , -- �ӽ� ���̺��        
                  'TaskOrderSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEQTaskOrderCHE WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_TEQTaskOrderCHE AS A   
          JOIN KPX_TEQTaskOrderCHE AS B ON ( B.CompanySeq = @CompanySeq AND B.TaskOrderSeq = A.TaskOrderSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
        
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEQTaskOrderCHE WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.TaskOrderDate = A.TaskOrderDate,  
               B.ISPID = A.ISPID,  
               B.IsInstrument = A.IsInstrument,  
               B.IsField = A.IsField,  
               B.IsPlot = A.IsPlot,  
               B.IsDange = A.IsDange,  
               B.IsConce = A.IsConce,  
               B.IsISO = A.IsISO,  
               B.IsEquip = A.IsEquip,  
               B.Etc = A.Etc,  
               B.IsTaskOrder = A.IsTaskOrder,  
               B.ChangePlan = A.ChangePlan,  
               B.TaskOrder = A.TaskOrder,  
               B.FileSeq = A.FileSeq, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
        
          FROM #KPX_TEQTaskOrderCHE AS A   
          JOIN KPX_TEQTaskOrderCHE AS B ON ( B.CompanySeq = @CompanySeq AND B.TaskOrderSeq = A.TaskOrderSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEQTaskOrderCHE WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TEQTaskOrderCHE  
        (   
            CompanySeq,TaskOrderSeq,TaskOrderDate,ISPID,IsInstrument,  
            IsField,IsPlot,IsDange,IsConce,IsISO,  
            IsEquip,Etc,IsTaskOrder,ChangePlan,TaskOrder,  
            FileSeq,ChangeRequestSeq,LastUserSeq,LastDateTime   
        )   
        SELECT @CompanySeq,A.TaskOrderSeq,A.TaskOrderDate,A.ISPID,A.IsInstrument,  
               A.IsField,A.IsPlot,A.IsDange,A.IsConce,A.IsISO,  
               A.IsEquip,A.Etc,A.IsTaskOrder,A.ChangePlan,A.TaskOrder,  
               A.FileSeq,A.ChangeRequestSeq,@UserSeq,GETDATE()   
          FROM #KPX_TEQTaskOrderCHE AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    SELECT * FROM #KPX_TEQTaskOrderCHE   
    
    RETURN  