
IF OBJECT_ID('KPX_SDAItemSalesSave') IS NOT NULL 
    DROP PROC KPX_SDAItemSalesSave
GO 

-- v2014.11.04 

-- ǰ�񿵾����� ����  by ����õ
/*************************************************************************************************    
 ��  �� - ǰ�񿵾����� ����    
 �ۼ��� - 2008.6. : CREATED BY ���ظ�       
*************************************************************************************************/    
CREATE PROCEDURE KPX_SDAItemSalesSave  
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
    CREATE TABLE #KPX_TDAItemSales (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItemSales'    
  
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)    
    EXEC _SCOMLog  @CompanySeq   ,    
                   @UserSeq      ,    
                   'KPX_TDAItemSales', -- �����̺��    
                   '#KPX_TDAItemSales', -- �������̺��    
                   'ItemSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.     
                   'CompanySeq,ItemSeq,IsVat,SMVatKind,SMVatType,IsOption,IsSet,Guaranty,HSCode,LastUserSeq,LastDateTime'        
      
  
    -- DELETE      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemSales WHERE WorkingTag = 'D' AND Status = 0  )    
    BEGIN    
        DELETE KPX_TDAItemSales  
          FROM #KPX_TDAItemSales AS A    
               JOIN KPX_TDAItemSales AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq    
                                                    AND B.ItemSeq = A.ItemSeq  
        WHERE A.WorkingTag = 'D' AND Status = 0  
      
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
    END  
  
    -- Update      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemSales WHERE WorkingTag = 'U' AND Status = 0  )    
    BEGIN     
        UPDATE KPX_TDAItemSales    
           SET   IsVat  =    ISNULL(A.IsVat,'0'),  -- �ΰ������Կ���  
                 SMVatKind = ISNULL(A.SMVatKind,0), -- �ΰ�������  
                 SMVatType = ISNULL(A.SMVatType,0), -- �ΰ�������  
                 IsOption = ISNULL(A.IsOption,'0'), -- �ɼǿ���  
                 IsSet = ISNULL(A.IsSet,'0'),  -- Setǰ�񿩺�  
                 Guaranty = CASE WHEN ISNULL(D.IsVessel,'') = '1' THEN ISNULL(A.Guaranty,0) ELSE ISNULL(B.Guaranty,0) END,  
                 HSCode = ISNULL(A.HSCode, ''),  
                 LastUserSeq  = @UserSeq,  
                 LastDateTime = GETDATE()  
          FROM #KPX_TDAItemSales AS A    
               JOIN KPX_TDAItemSales AS B ON B.CompanySeq  = @CompanySeq    
                                      AND B.ItemSeq = A.ItemSeq  
               JOIN KPX_TDAItem AS C WITH (NOLOCK) ON B.CompanySeq = C.CompanySeq  
                                               AND B.ItemSeq    = C.ItemSeq  
               JOIN _TDAItemAsset AS D WITH (NOLOCK) ON D.CompanySeq = @CompanySeq  
                                                    AND C.AssetSeq   = D.AssetSeq  
  
  
  
  
         WHERE A.WorkingTag = 'U' AND A.Status = 0  
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
  
  
        INSERT INTO KPX_TDAItemSales(    
             CompanySeq,  
             ItemSeq,  
             IsVat,  
             SMVatKind,  
             SMVatType,  
             IsOption,  
             IsSet,  
             Guaranty,  
             HSCode,  
             LastUserSeq,  
             LastDateTime )  
        SELECT  
             @CompanySeq,  
             A.ItemSeq,  
             ISNULL(A.IsVat,'0'),  
             ISNULL(A.SMVatKind,2003001),  
             ISNULL(A.SMVatType,8028001),  
  
             ISNULL(A.IsOption,'0'),  
             ISNULL(A.IsSet,'0'),  
             ISNULL(A.Guaranty,0),  
             ISNULL(A.HSCode,''),  
             @UserSeq,  
             GETDATE()  
          FROM #KPX_TDAItemSales AS A   
                 LEFT OUTER JOIN KPX_TDAItemSales AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq    
                                                               AND B.ItemSeq = A.ItemSeq  
  
  
  
  
         WHERE A.WorkingTag = 'U' AND A.Status = 0   
           AND ISNULL(B.ItemSeq, 0) = 0  
    
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
    END    
       
    -- INSERT      
    IF EXISTS (SELECT 1 FROM #KPX_TDAItemSales WHERE WorkingTag = 'A' AND Status = 0  )    
    BEGIN    
  
        INSERT INTO KPX_TDAItemSales(    
             CompanySeq,  
             ItemSeq,  
             IsVat,  
             SMVatKind,  
             SMVatType,  
             IsOption,  
             IsSet,  
             Guaranty,  
             HSCode,  
             LastUserSeq,  
             LastDateTime, 
             PgmSeq )  
        SELECT  
             @CompanySeq,    
             ItemSeq,  
             ISNULL(IsVat,'0'),  
             ISNULL(SMVatKind,2003001),  
             ISNULL(SMVatType,8028001),  
             ISNULL(IsOption,'0'),  
             ISNULL(IsSet,'0'),  
             ISNULL(Guaranty,0),  
             ISNULL(HSCode,''),  
             @UserSeq,  
             GETDATE(), 
             @PgmSeq 
          FROM #KPX_TDAItemSales     
  
  
  
  
         WHERE WorkingTag = 'A' AND Status = 0   
    
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
    END        
      
    SELECT *    
      FROM #KPX_TDAItemSales    
    
RETURN    
/**************************************************************************************************/    
  