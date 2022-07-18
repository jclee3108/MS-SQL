
IF OBJECT_ID('KPX_SDAItemRemarkSave') IS NOT NULL 
    DROP PROC KPX_SDAItemRemarkSave
GO 

-- v2014.11.04 

-- ������� by����õ 
/*********************************************************************************************************************  
    ȭ��� : ǰ����_�������  
    SP Name: KPX_SDAItemRemarkSave  
    �ۼ��� : 2010.4.14 : CREATEd by ������      
    ������ :   
********************************************************************************************************************/  
  
CREATE PROCEDURE KPX_SDAItemRemarkSave    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS         
    DECLARE @docHandle  INT  
  
  
    -- ���� ����Ÿ ��� ����    
    CREATE TABLE #KPX_TDAItemRemark (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItemRemark'    
  
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
    EXEC _SCOMLog  @CompanySeq   ,  
                   @UserSeq      ,  
                   'KPX_TDAItemRemark', -- �����̺��  
                   '#KPX_TDAItemRemark', -- �������̺��  
                   'ItemSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                   'CompanySeq, ItemSeq, ItemRemark, LastUserSeq, LastDateTime'   
         
    -- DELETE                                                                                                  
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemRemark WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE KPX_TDAItemRemark    
          FROM KPX_TDAItemRemark AS A  
                JOIN #KPX_TDAItemRemark AS B ON A.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq  
         WHERE B.WorkingTag = 'D'   
           AND B.Status = 0    
           
        IF @@ERROR <> 0 RETURN  
    END    
    
    -- Update                                                                                                   
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemRemark WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN     
        UPDATE KPX_TDAItemRemark    
           SET ItemRemark   = B.ItemRemark,   
               LastUserSeq  = @UserSeq,     
               LastDateTime = GETDATE()    
          FROM KPX_TDAItemRemark AS A   
                 JOIN #KPX_TDAItemRemark AS B ON A.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq  
         WHERE B.WorkingTag = 'U'   
           AND B.Status = 0  
           
        IF @@ERROR <> 0 RETURN    
    END     
    -- INSERT                                                                                                   
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemRemark WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
  
        -- ���� INSERT    
        INSERT INTO KPX_TDAItemRemark (CompanySeq, ItemSeq, ItemRemark, LastUserSeq, LastDateTime)  
            SELECT @CompanySeq, ItemSeq, ItemRemark, @UserSeq, GETDATE()     
              FROM #KPX_TDAItemRemark    
             WHERE WorkingTag = 'A'   
               AND Status = 0    
           
        IF @@ERROR <> 0 RETURN  
    END  
      
    SELECT * FROM #KPX_TDAItemRemark   
    
    RETURN    
  