
IF OBJECT_ID('KPX_SDAItemFileSave') IS NOT NULL 
    DROP PROC KPX_SDAItemFileSave
GO 

-- v2014.11.04 

-- ǰ��÷������ ���� by����õ
/*************************************************************************************************    
 ��  �� - ǰ��÷������ ����    
 �ۼ��� - 2008.10. : CREATED BY ���ظ�       
*************************************************************************************************/    
CREATE PROCEDURE KPX_SDAItemFileSave  
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS    
    DECLARE @docHandle          INT,    
            @MaxSeq             INT,    
            @ItemSeq            INT  
  
    -- ����Ÿ ��� ����    
    CREATE TABLE #KPX_TDAItemFile (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItemFile'    
  
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)    
    EXEC _SCOMLog  @CompanySeq   ,    
                   @UserSeq      ,    
                   'KPX_TDAItemFile', -- �����̺��    
                   '#KPX_TDAItemFile', -- �������̺��    
                   'ItemSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.     
                   'CompanySeq,ItemSeq,FileSeq,LastUserSeq,LastDateTime'        
  
  
    -- DELETE      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemFile WHERE WorkingTag = 'D' AND Status = 0  )    
    BEGIN    
        DELETE KPX_TDAItemFile  
          FROM #KPX_TDAItemFile AS A    
               JOIN KPX_TDAItemFile AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq    
                                                   AND B.ItemSeq     = A.ItemSeq  
         WHERE A.WorkingTag = 'D' AND Status = 0  
      
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
    END  
  
    -- Update      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemFile WHERE WorkingTag = 'U' AND Status = 0  )    
    BEGIN     
        UPDATE KPX_TDAItemFile  
           SET FileSeq      = A.FileSeq,  
               LastUserSeq  = @UserSeq,  
               LastDateTime = GETDATE()  
          FROM #KPX_TDAItemFile AS A  
               JOIN KPX_TDAItemFile AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                   AND A.ItemSeq    = B.ItemSeq  
         WHERE A.WorkingTag = 'U' AND A.Status = 0   
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
  
        INSERT INTO KPX_TDAItemFile(    
             CompanySeq,  
             ItemSeq,  
             FileSeq,  
             LastUserSeq,  
             LastDateTime )  
        SELECT  
             @CompanySeq,  
             A.ItemSeq,  
             A.FileSeq,  
             @UserSeq,    
             GETDATE()  
          FROM #KPX_TDAItemFile AS A    
               LEFT OUTER JOIN KPX_TDAItemFile AS B WITH (NOLOCK)  ON B.CompanySeq  = @CompanySeq    
                                                               AND A.ItemSeq     = B.ItemSeq  
         WHERE A.WorkingTag = 'U' AND A.Status = 0  
           AND B.ItemSeq IS NULL  
    
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
    END    
       
    -- INSERT      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemFile WHERE WorkingTag = 'A' AND Status = 0  )    
    BEGIN    
  
        INSERT INTO KPX_TDAItemFile(    
             CompanySeq,  
             ItemSeq,  
             FileSeq,  
             LastUserSeq,  
             LastDateTime )  
        SELECT  
             @CompanySeq,    
             ItemSeq,  
             FileSeq,  
             @UserSeq,  
             GETDATE()  
          FROM #KPX_TDAItemFile     
         WHERE WorkingTag = 'A' AND Status = 0   
    
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
    END        
      
    SELECT * FROM #KPX_TDAItemFile    
    
RETURN    
/**************************************************************************************************/    
  