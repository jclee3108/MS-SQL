
IF OBJECT_ID('KPX_SDAItemSalesQuery') IS NOT NULL 
    DROP PROC KPX_SDAItemSalesQuery
GO 

-- v2014.11.04 

-- ǰ�񿵾����� ��ȸ by����õ
/*************************************************************************************************        
 ��  �� - ǰ�񿵾����� ��ȸ    
 �ۼ��� - 2008.6.  : CREATED BY JMKIM    
*************************************************************************************************/        
CREATE PROCEDURE KPX_SDAItemSalesQuery      
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS           
    DECLARE   @docHandle      INT,      
              @ItemSeq        INT  
      
    -- ����Ÿ ��� ����    
    CREATE TABLE #KPX_TDAItemSales (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItemSales'    
  
    SELECT  A.ItemSeq   AS ItemSeq,  
            A.IsVat     AS IsVat, -- �ΰ������Կ���  
            A.SMVatKind AS SMVatKind, -- �ΰ�������  
            A.SMVatType AS SMVatType, -- �ΰ�������  
            A.IsOption  AS IsOption, -- �ɼǿ���  
            A.IsSet     AS IsSet, -- Setǰ�񿩺�  
            ISNULL(A.Guaranty,0) AS Guaranty,  
            ISNULL((SELECT MinorName FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMVatKind),'') AS VatKindName,  
            ISNULL((SELECT MinorName FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMVatType),'') AS VatTypeName,  
            ISNULL(A.HSCode, '') AS HSCode,  
            B.IDX_NO AS IDX_NO  
    FROM KPX_TDAItemSales A WITH(NOLOCK)  
         JOIN #KPX_TDAItemSales AS B ON A.CompanySeq = @CompanySeq  
                                AND A.ItemSeq = B.ItemSeq  
    WHERE 1=1    
      AND (A.CompanySeq  = @CompanySeq)  
  
RETURN      
  