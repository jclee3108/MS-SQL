
IF OBJECT_ID('KPX_SDAItemUnitSpecSave') IS NOT NULL 
    DROP PROC KPX_SDAItemUnitSpecSave
GO 

-- v2014.11.04 

-- ǰ������Ӽ� ���� by����õ
/*************************************************************************************************    
 ��  �� - ǰ������Ӽ� ����    
 �ۼ��� - 2008.7. : CREATED BY ���ظ�       
*************************************************************************************************/    
CREATE PROCEDURE KPX_SDAItemUnitSpecSave  
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
            @ItemSeq            INT,  
            @UnitSeq            INT  
  
  
    -- ����Ÿ ��� ����    
    CREATE TABLE #KPX_TDAItemUnitSpec (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPX_TDAItemUnitSpec'    
    IF @@ERROR <> 0 RETURN   
  
      
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)    
    EXEC _SCOMLog  @CompanySeq   ,    
                   @UserSeq      ,    
                   'KPX_TDAItemUnitSpec', -- �����̺��    
                   '#KPX_TDAItemUnitSpec', -- �������̺��    
                   'ItemSeq, UnitSeq, UMSpecCode' , -- Ű�� �������� ���� , �� �����Ѵ�.    
                   'CompanySeq,ItemSeq,UnitSeq,UMSpecCode,SpecUnit,Value,LastUserSeq,LastDateTime'  
  
    -- DELETE      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemUnitSpec WHERE WorkingTag = 'D' AND Status = 0  )    
    BEGIN    
        DELETE KPX_TDAItemUnitSpec  
          FROM #KPX_TDAItemUnitSpec AS A  
               JOIN KPX_TDAItemUnitSpec AS B ON B.CompanySeq      = @CompanySeq    
                                         AND B.ItemSeq         = A.ItemSeq  
                                         AND B.UnitSeq         = A.UnitSeq  
                                         AND B.UMSpecCode      = A.UMSpecCode  
         WHERE A.WorkingTag = 'D' AND A.Status = 0  
      
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
    END  
  
    -- Update      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemUnitSpec WHERE WorkingTag = 'U' AND Status = 0  )    
    BEGIN     
        UPDATE KPX_TDAItemUnitSpec    
           SET  SpecUnit       = ISNULL(A.SpecUnit,''),  
                Value          = ISNULL(A.Value,0),  
                LastUserSeq    = @UserSeq,  
                LastDateTime   = GETDATE()  
          FROM #KPX_TDAItemUnitSpec AS A    
               JOIN KPX_TDAItemUnitSpec AS B ON B.CompanySeq = @CompanySeq    
                                         AND B.ItemSeq    = A.ItemSeq  
                                         AND B.UnitSeq    = A.UnitSeq  
                                         AND B.UMSpecCode = A.UMSpecCode  
         WHERE A.WorkingTag = 'U' AND A.Status = 0  
  
        IF @@ERROR <> 0      
        BEGIN  
            RETURN      
        END    
  
        INSERT INTO KPX_TDAItemUnitSpec  
        (    
            CompanySeq,  
            ItemSeq,  
            UnitSeq,  
            UMSpecCode,  
            SpecUnit,  
            Value,  
            LastUserSeq,  
            LastDateTime   
        )  
        SELECT  @CompanySeq ,  
                ISNULL(A.ItemSeq,0),  
                ISNULL(A.UnitSeq,0),  
                ISNULL(A.UMSpecCode,0),  
                ISNULL(A.SpecUnit,''),  
                ISNULL(A.Value,0),  
                @UserSeq,    
                GETDATE()  
          FROM #KPX_TDAItemUnitSpec AS A  
               LEFT OUTER JOIN KPX_TDAItemUnitSpec AS B ON B.CompanySeq = @CompanySeq    
                                                    AND B.ItemSeq    = A.ItemSeq  
                                                    AND B.UnitSeq    = A.UnitSeq  
                                                    AND B.UMSpecCode = A.UMSpecCode  
         WHERE WorkingTag = 'U' AND Status = 0   
           AND B.UnitSeq IS NULL  
    END    
       
    -- INSERT      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemUnitSpec WHERE WorkingTag = 'A' AND Status = 0  )    
    BEGIN    
  
    INSERT INTO KPX_TDAItemUnitSpec  
        (    
            CompanySeq,  
            ItemSeq,  
            UnitSeq,  
            UMSpecCode,  
            SpecUnit,  
            Value,  
            LastUserSeq,  
            LastDateTime   
        )  
        SELECT  @CompanySeq ,  
                ISNULL(ItemSeq,0),  
                ISNULL(UnitSeq,0),  
                ISNULL(UMSpecCode,0),  
                ISNULL(SpecUnit,''),  
                ISNULL(Value,0),  
                @UserSeq,    
                GETDATE()  
          FROM #KPX_TDAItemUnitSpec     
         WHERE WorkingTag = 'A' AND Status = 0   
    
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
    END        
      
    SELECT * FROM #KPX_TDAItemUnitSpec    
    
RETURN    
/**************************************************************************************************/    
  