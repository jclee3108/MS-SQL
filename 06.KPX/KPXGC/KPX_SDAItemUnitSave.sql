
IF OBJECT_ID('KPX_SDAItemUnitSave') IS NOT NULL 
    DROP PROC KPX_SDAItemUnitSave
GO 

-- v2014.11.04 

-- ǰ�����ȯ������ by����õ
/*************************************************************************************************    
 ��  �� - ǰ�����ȯ�� ����    
 �ۼ��� - 2008.7. : CREATED BY ���ظ�           
*************************************************************************************************/    
CREATE PROCEDURE KPX_SDAItemUnitSave  
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
    CREATE TABLE #KPX_TDAItemUnit (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPX_TDAItemUnit'    
  
      
  
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)    
    EXEC _SCOMLog  @CompanySeq   ,    
                   @UserSeq      ,    
                   'KPX_TDAItemUnit', -- �����̺��    
                   '#KPX_TDAItemUnit', -- �������̺��    
                   'ItemSeq,UnitSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.     
                   'CompanySeq,ItemSeq,UnitSeq,BarCode,ConvNum,ConvDen,TransConvQty,LastUserSeq,LastDateTime'    
  
  
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)    
    EXEC _SCOMLog  @CompanySeq   ,    
                   @UserSeq      ,    
                   'KPX_TDAItemUnitModule', -- �����̺��    
                   '#KPX_TDAItemUnit', -- �������̺��    
                   'ItemSeq,UnitSeq,UMModuleSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.     
                   'CompanySeq,ItemSeq,UnitSeq,UMModuleSeq,IsUsed,LastUserSeq,LastDateTime'    
  
  
    -- DELETE      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemUnit WHERE WorkingTag = 'D' AND Status = 0  )    
    BEGIN    
        DELETE KPX_TDAItemUnit  
          FROM #KPX_TDAItemUnit AS A    
                JOIN KPX_TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                    AND B.ItemSeq    = A.ItemSeq  
                                                    AND B.UnitSeq    = A.UnitSeqOld  
         WHERE A.WorkingTag = 'D' AND Status = 0  
       
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
  
        DELETE KPX_TDAItemUnitModule  
          FROM #KPX_TDAItemUnit AS A    
               JOIN KPX_TDAItemUnitModule AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                         AND B.ItemSeq    = A.ItemSeq  
                                                         AND B.UnitSeq    = A.UnitSeqOld  
         WHERE A.WorkingTag = 'D' AND Status = 0  
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
  
        DELETE KPX_TDAItemUnitSpec  
          FROM #KPX_TDAItemUnit AS A    
               JOIN KPX_TDAItemUnitSpec AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                       AND B.ItemSeq    = A.ItemSeq  
                                                       AND B.UnitSeq    = A.UnitSeqOld  
         WHERE A.WorkingTag = 'D' AND Status = 0  
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
    END  
  
    -- Update      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemUnit WHERE WorkingTag = 'U' AND Status = 0  )    
    BEGIN     
        UPDATE KPX_TDAItemUnit    
           SET  UnitSeq = ISNULL(A.UnitSeq,0),  
                BarCode = ISNULL(A.BarCode,''),  
                ConvNum = ISNULL(A.ConvNum,0),  
                ConvDen = ISNULL(A.ConvDen,0),  
                TransConvQty = ISNULL(A.TransConvQty,0),  
                LastUserSeq  = @UserSeq,  
                LastDateTime = GETDATE()  
          FROM #KPX_TDAItemUnit AS A    
               JOIN KPX_TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                   AND B.ItemSeq    = A.ItemSeq  
                                                     AND B.UnitSeq    = A.UnitSeqOld  
         WHERE A.WorkingTag = 'U' AND A.Status = 0  
     
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
  
        -- ���� ����ȯ�� �Է�  
        INSERT INTO KPX_TDAItemUnit(    
             CompanySeq,  
             ItemSeq,  
             UnitSeq,  
             BarCode,  
             ConvNum,  
             ConvDen,  
             TransConvQty,  
             LastUserSeq,  
             LastDateTime )  
        SELECT  
             @CompanySeq,    
             ISNULL(A.ItemSeq,0),  
             ISNULL(A.UnitSeq,0),  
             ISNULL(A.BarCode,''),  
             ISNULL(A.ConvNum,0),  
             ISNULL(A.ConvDen,0),  
             ISNULL(A.TransConvQty,0),  
             @UserSeq,    
             GETDATE()  
          FROM #KPX_TDAItemUnit AS A   
               LEFT OUTER JOIN KPX_TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq    
                                                              AND A.ItemSeq     = B.ItemSeq  
                                                              AND A.UnitSeq     = B.UnitSeq  
         WHERE A.WorkingTag = 'U' AND A.Status = 0   
           AND B.UnitSeq IS NULL  
         GROUP BY A.ItemSeq, A.UnitSeq, A.BarCode, A.ConvNum, A.ConvDen, A.TransConvQty  
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
  
        -- ���� ������� ����  
        UPDATE KPX_TDAItemUnitModule    
           SET  UnitSeq        = ISNULL(A.UnitSeq,0),  
                IsUsed         = ISNULL(A.IsUsed,'0'),  
                LastUserSeq    = @UserSeq,  
                LastDateTime   = GETDATE()  
          FROM #KPX_TDAItemUnit AS A    
               JOIN KPX_TDAItemUnitModule AS B ON B.CompanySeq  = @CompanySeq    
                                           AND B.ItemSeq     = A.ItemSeq  
                                           AND B.UnitSeq     = A.UnitSeqOld  
                                           AND B.UMModuleSeq = A.UMModuleSeq  
         WHERE A.WorkingTag = 'U' AND A.Status = 0  
  
        IF @@ERROR <> 0      
        BEGIN  
            RETURN      
        END    
  
        -- ���� ����������� �Է�  
        INSERT INTO KPX_TDAItemUnitModule  
        (    
            CompanySeq,  
            ItemSeq,  
            UnitSeq,  
            UMModuleSeq,  
            IsUsed,  
            LastUserSeq,  
            LastDateTime   
        )  
        SELECT  @CompanySeq ,  
                ISNULL(A.ItemSeq,0),  
                ISNULL(A.UnitSeq,0),  
                ISNULL(A.UMModuleSeq,0),  
                ISNULL(A.IsUsed,'0'),  
                @UserSeq,    
                GETDATE()  
          FROM #KPX_TDAItemUnit AS A  
               LEFT OUTER JOIN KPX_TDAItemUnitModule AS B ON B.CompanySeq  = @CompanySeq    
                                                      AND B.ItemSeq     = A.ItemSeq  
                                                      AND B.UnitSeq     = A.UnitSeq  
                                                      AND B.UMModuleSeq = A.UMModuleSeq  
         WHERE WorkingTag = 'U' AND Status = 0   
           AND B.UMModuleSeq IS NULL  
           AND A.UMModuleSeq <> 0  
         GROUP BY A.ItemSeq,A.UnitSeq,A.UMModuleSeq,A.IsUsed  
  
        -- Ű�� ����� �����Ӽ� ���̺����  
        DELETE KPX_TDAItemUnitSpec  
          FROM #KPX_TDAItemUnit AS A    
               JOIN KPX_TDAItemUnitSpec AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                       AND B.ItemSeq    = A.ItemSeq  
                                                       AND B.UnitSeq    = A.UnitSeqOld  
         WHERE A.WorkingTag = 'U' AND Status = 0  
           AND A.UnitSeq <> A.UnitSeqOld  
           AND ISNULL(A.UnitSeqOld,0) <> 0  
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
  
        -- Old �� ����  
        UPDATE #KPX_TDAItemUnit  
           SET UnitSeqOld = ISNULL(UnitSeq,0)  
         WHERE WorkingTag = 'U' AND Status = 0   
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
    END    
       
  -- INSERT      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemUnit WHERE WorkingTag = 'A' AND Status = 0  )    
    BEGIN    
  
        -- ���� ����ȯ�� �Է�  
        INSERT INTO KPX_TDAItemUnit(    
             CompanySeq,  
             ItemSeq,  
             UnitSeq,  
             BarCode,  
             ConvNum,  
             ConvDen,  
             TransConvQty,  
             LastUserSeq,  
             LastDateTime )  
        SELECT  
             @CompanySeq,    
             ISNULL(A.ItemSeq,0),  
             ISNULL(A.UnitSeq,0),  
             ISNULL(A.BarCode,''),  
             ISNULL(A.ConvNum,0),  
             ISNULL(A.ConvDen,0),  
             ISNULL(A.TransConvQty,0),  
             @UserSeq,    
             GETDATE()  
          FROM #KPX_TDAItemUnit AS A   
               LEFT OUTER JOIN KPX_TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq    
                                                              AND A.ItemSeq     = B.ItemSeq  
                                                              AND A.UnitSeq     = B.UnitSeq  
         WHERE WorkingTag = 'A' AND Status = 0   
           AND B.UnitSeq IS NULL  
         GROUP BY A.ItemSeq, A.UnitSeq, A.BarCode, A.ConvNum, A.ConvDen, A.TransConvQty  
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
  
        -- ���� ����������� �Է�  
        INSERT INTO KPX_TDAItemUnitModule  
        (    
            CompanySeq,  
            ItemSeq,  
            UnitSeq,  
            UMModuleSeq,  
            IsUsed,  
            LastUserSeq,  
            LastDateTime   
        )  
        SELECT  @CompanySeq ,  
                ISNULL(A.ItemSeq,0),  
                ISNULL(A.UnitSeq,0),  
                ISNULL(A.UMModuleSeq,0),  
                ISNULL(A.IsUsed,'0'),  
                @UserSeq,    
                GETDATE()  
          FROM #KPX_TDAItemUnit AS A  
               LEFT OUTER JOIN KPX_TDAItemUnitModule AS B ON B.CompanySeq  = @CompanySeq    
                                                      AND A.ItemSeq     = B.ItemSeq  
                                                      AND A.UnitSeq     = B.UnitSeq  
                                                      AND A.UMModuleSeq = B.UMModuleSeq  
         WHERE WorkingTag = 'A' AND Status = 0   
           AND B.UMModuleSeq IS NULL  
           AND A.UMModuleSeq <> 0  
         GROUP BY A.ItemSeq,A.UnitSeq,A.UMModuleSeq,A.IsUsed  
  
        UPDATE #KPX_TDAItemUnit  
           SET UnitSeqOld = ISNULL(UnitSeq,0)  
         WHERE WorkingTag = 'A' AND Status = 0   
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
    END        
  
    SELECT *    
      FROM #KPX_TDAItemUnit    
  
RETURN    
/**************************************************************************************************/    
  