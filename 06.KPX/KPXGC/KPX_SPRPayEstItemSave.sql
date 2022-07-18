  
IF OBJECT_ID('KPX_SPRPayEstItemSave') IS NOT NULL   
    DROP PROC KPX_SPRPayEstItemSave  
GO  
  
-- v2014.12.15  
  
-- �޿������׸���-���� by ����õ   
CREATE PROC KPX_SPRPayEstItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TPRPayEstItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPRPayEstItem'   
    IF @@ERROR <> 0 RETURN    
      
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPRPayEstItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPRPayEstItem'    , -- ���̺��        
                  '#KPX_TPRPayEstItem'    , -- �ӽ� ���̺��        
                  'ItemSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , 'ItemSeqOld', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRPayEstItem WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_TPRPayEstItem AS A   
          JOIN KPX_TPRPayEstItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeqOld )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN   
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRPayEstItem WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.ItemSeq = A.ItemSeq, 
               B.IsBase = A.IsBase,  
               B.ISFix = A.ISFix,  
               B.IsWkLink = A.IsWkLink,  
               B.IsEst = A.IsEst,  
            
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
                 
          FROM #KPX_TPRPayEstItem AS A   
          JOIN KPX_TPRPayEstItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeqOld )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRPayEstItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TPRPayEstItem  
        (   
            CompanySeq,ItemSeq,IsBase,ISFix,IsWkLink,  
            IsEst,LastUserSeq,LastDateTime   
        )   
        SELECT @CompanySeq,A.ItemSeq,A.IsBase,A.ISFix,A.IsWkLink,  
               A.IsEst,@UserSeq,GETDATE()   
          FROM #KPX_TPRPayEstItem AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    UPDATE A 
       SET ItemSeqOld = ItemSeq 
      FROM #KPX_TPRPayEstItem AS A 
    
    SELECT * FROM #KPX_TPRPayEstItem   
      
    RETURN  