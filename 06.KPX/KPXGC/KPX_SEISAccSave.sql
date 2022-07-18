  
IF OBJECT_ID('KPX_SEISAccSave') IS NOT NULL   
    DROP PROC KPX_SEISAccSave  
GO  
  
-- v2015.02.11  
  
-- (�濵����)�������-���� by ����õ   
CREATE PROC KPX_SEISAccSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TEISAcc (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEISAcc'   
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TEISAcc')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TEISAcc'    , -- ���̺��        
                  '#KPX_TEISAcc'    , -- �ӽ� ���̺��        
                  'Seq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEISAcc WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_TEISAcc AS A   
          JOIN KPX_TEISAcc AS B ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEISAcc WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.KindSeq = A.KindSeq,  
               B.AccSeq = A.AccSeq,  
               B.TextCode = A.TextCode,  
               B.TextName = A.TextName,  
               B.AccSeqSub = A.AccSeqSub,  
               B.TextCodeSub = A.TextCodeSub,  
               B.TextNameSub = A.TextNameSub,  
                 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()  
        
          FROM #KPX_TEISAcc AS A   
          JOIN KPX_TEISAcc AS B ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEISAcc WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TEISAcc  
        (   
            CompanySeq,Seq,KindSeq,AccSeq,TextCode,  
            TextName,AccSeqSub,TextCodeSub,TextNameSub,LastUserSeq,  
            LastDateTime   
        )   
        SELECT @CompanySeq,A.Seq,A.KindSeq,A.AccSeq,A.TextCode,  
               A.TextName,A.AccSeqSub,A.TextCodeSub,A.TextNameSub,@UserSeq,  
               GETDATE()   
          FROM #KPX_TEISAcc AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_TEISAcc   
      
    RETURN  