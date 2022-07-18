  
IF OBJECT_ID('KPXCM_SPMDevPgmSave') IS NOT NULL   
    DROP PROC KPXCM_SPMDevPgmSave  
GO  
  
-- v2015.09.17  
  
-- (����)���α׷�������Ȳ_KPXCM-���� by ����õ   
CREATE PROC KPXCM_SPMDevPgmSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TPMDevPgm (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPMDevPgm'   
    IF @@ERROR <> 0 RETURN    
      
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPMDevPgm')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPMDevPgm'    , -- ���̺��        
                  '#KPX_TPMDevPgm'    , -- �ӽ� ���̺��        
                  'DevSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- �۾����� : DELETE -> UPDATE -> INSERT  
      
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPMDevPgm WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_TPMDevPgm AS A   
          JOIN KPX_TPMDevPgm AS B ON ( B.CompanySeq = @CompanySeq AND B.DevSeq = A.DevSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPMDevPgm WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.DevOrder = A.DevOrder,  
               B.Module = A.Module,  
               B.PgmName = A.PgmName,  
               B.PgmClass = A.PgmClass,  
               B.Consultant = A.Consultant,  
               B.DevName = A.DevName,  
               B.PlanDate = A.PlanDate,  
               B.FinDate = A.FinDate,  
               B.SMIsFinSeq = A.SMIsFinSeq,  
               B.Remark1 = A.Remark1,  
               B.Remark2 = A.Remark2,  
               B.Remark3 = A.Remark3,  
               B.Remark4 = A.Remark4,  
               B.Remark5 = A.Remark5,  
                 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
                 
          FROM #KPX_TPMDevPgm AS A   
          JOIN KPX_TPMDevPgm AS B ON ( B.CompanySeq = @CompanySeq AND B.DevSeq = A.DevSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPMDevPgm WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TPMDevPgm  
        (   
            CompanySeq,DevSeq,DevOrder,Module,PgmName,  
            PgmClass,Consultant,DevName,PlanDate,FinDate,  
            SMIsFinSeq,Remark1,Remark2,Remark3,Remark4,  
            Remark5,LastUserSeq,LastDateTime   
        )   
          SELECT @CompanySeq,A.DevSeq,A.DevOrder,A.Module,A.PgmName,  
               A.PgmClass,A.Consultant,A.DevName,A.PlanDate,A.FinDate,  
               A.SMIsFinSeq,A.Remark1,A.Remark2,A.Remark3,A.Remark4,  
               A.Remark5,@UserSeq,GETDATE()   
          FROM #KPX_TPMDevPgm AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_TPMDevPgm   
      
    RETURN  