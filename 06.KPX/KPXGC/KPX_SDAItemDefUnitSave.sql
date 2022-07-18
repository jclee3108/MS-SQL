
IF OBJECT_ID('KPX_SDAItemDefUnitSave') IS NOT NULL 
    DROP PROC KPX_SDAItemDefUnitSave
GO 

-- v2014.11.04 

-- ǰ��⺻���� ���� by����õ
/*************************************************************************************************    
 ��  �� - ǰ��⺻���� ����    
 �ۼ��� - 2008.6. : CREATED BY ���ظ�       
*************************************************************************************************/    
CREATE PROCEDURE KPX_SDAItemDefUnitSave  
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
    CREATE TABLE #KPX_TDAItemDefUnit (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItemDefUnit'    
  
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)    
    EXEC _SCOMLog  @CompanySeq   ,    
                   @UserSeq      ,    
                   'KPX_TDAItemDefUnit', -- �����̺��    
                   '#KPX_TDAItemDefUnit', -- �������̺��    
                   'ItemSeq,UMModuleSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.     
                   'CompanySeq,ItemSeq,UMModuleSeq,STDUnitSeq,LastUserSeq,LastDateTime'        
  
    
    -- DELETE      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemDefUnit WHERE WorkingTag = 'D' AND Status = 0  )    
    BEGIN    
        DELETE KPX_TDAItemDefUnit  
        FROM #KPX_TDAItemDefUnit AS A    
             JOIN KPX_TDAItemDefUnit AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq    
                                                    AND B.ItemSeq     = A.ItemSeq  
                                                    AND B.UMModuleSeq  = A.UMModuleSeq  
        WHERE A.WorkingTag = 'D' AND Status = 0  
      
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
    END  
  
    -- Update      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemDefUnit WHERE WorkingTag = 'U' AND Status = 0  )    
    BEGIN     
        UPDATE KPX_TDAItemDefUnit    
           SET  STDUnitSeq   = ISNULL(A.STDUnitSeq,0),  
                LastUserSeq  = @UserSeq,  
                LastDateTime = GETDATE()  
          FROM #KPX_TDAItemDefUnit AS A    
               JOIN KPX_TDAItemDefUnit AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq    
                                                      AND B.ItemSeq     = A.ItemSeq  
                                                      AND B.UMModuleSeq   = A.UMModuleSeq  
         WHERE A.WorkingTag = 'U' AND A.Status = 0  
     
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
  
        INSERT INTO KPX_TDAItemDefUnit(    
             CompanySeq,  
             ItemSeq,  
             UMModuleSeq,  
             StdUnitSeq,  
             LastUserSeq,  
             LastDateTime )  
        SELECT  
             @CompanySeq,    
             ISNULL(A.ItemSeq,0),  
             ISNULL(A.UMModuleSeq,0),  
             ISNULL(A.STDUnitSeq,0),  
             @UserSeq,  
             GETDATE()  
         FROM #KPX_TDAItemDefUnit AS A    
              LEFT OUTER JOIN KPX_TDAItemDefUnit AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq    
                                                                AND B.ItemSeq     = A.ItemSeq  
                                                                AND B.UMModuleSeq   = A.UMModuleSeq  
         WHERE A.WorkingTag = 'U' AND A.Status = 0  
           AND ISNULL(B.UMModuleSeq,'') = ''  
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
  
--         IF NOT EXISTS (SELECT 1 FROM #KPX_TDAItemDefUnit A   
--                                      JOIN _TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
--                                                                          AND A.ItemSeq    = B.ItemSeq  
--                                                                          AND A.STDUnitSeq = B.UnitSeq)  
--         BEGIN  
  --             INSERT INTO _TDAItemUnit(  
--                 CompanySeq,  
--                 ItemSeq,  
--                 UnitSeq,  
--                 BarCode,  
--                 ConvNum,  
--                 ConvDen,  
--                 LastUserSeq,  
--                 LastDateTime)  
--             SELECT   
--                 @CompanySeq,  
--                 ItemSeq,  
--                 STDUnitSeq,  
--                 '',  
--                 1,  
--                 1,  
--                 @UserSeq,    
--                 GETDATE()  
--               FROM #KPX_TDAItemDefUnit     
--              WHERE WorkingTag = 'U' AND Status = 0   
--              GROUP BY ItemSeq, STDUnitSeq  
--   
--             IF @@ERROR <> 0      
--             BEGIN      
--                 RETURN      
--             END       
--         END  
    END    
       
    -- INSERT      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemDefUnit WHERE WorkingTag = 'A' AND Status = 0  )    
    BEGIN    
  
        INSERT INTO KPX_TDAItemDefUnit(    
             CompanySeq,  
             ItemSeq,  
             UMModuleSeq,  
             StdUnitSeq,  
             LastUserSeq,  
             LastDateTime )  
        SELECT  
             @CompanySeq,    
             ISNULL(ItemSeq,0),  
             ISNULL(UMModuleSeq,0),  
             ISNULL(STDUnitSeq,0),  
             @UserSeq,    
             GETDATE()  
          FROM #KPX_TDAItemDefUnit     
         WHERE WorkingTag = 'A' AND Status = 0   
    
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
  
--         IF NOT EXISTS (SELECT 1 FROM #KPX_TDAItemDefUnit A   
--                                      JOIN _TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
--                                                                          AND A.ItemSeq    = B.ItemSeq  
--                                                                          AND A.STDUnitSeq = B.UnitSeq)  
--         BEGIN  
--             INSERT INTO _TDAItemUnit(  
--                 CompanySeq,  
--                 ItemSeq,  
--                 UnitSeq,  
--                 BarCode,  
--                 ConvNum,  
--                 ConvDen,  
--                 LastUserSeq,  
--                 LastDateTime)  
--             SELECT   
--                 @CompanySeq,  
--                 ItemSeq,  
--                 STDUnitSeq,  
--                 '',  
--                 1,  
--                 1,  
--                 @UserSeq,    
--                 GETDATE()  
--               FROM #KPX_TDAItemDefUnit     
--              WHERE WorkingTag = 'A' AND Status = 0   
--              GROUP BY ItemSeq, UnitSeq  
--   
--             IF @@ERROR <> 0      
--             BEGIN      
--                 RETURN      
--             END       
--         END  
    END        
  
    SELECT *    
      FROM #KPX_TDAItemDefUnit    
    
RETURN    
/**************************************************************************************************/    
  