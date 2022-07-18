  
IF OBJECT_ID('KPXCM_SUIImpDelvItemListPrint_KPXCM') IS NOT NULL   
    DROP PROC KPXCM_SUIImpDelvItemListPrint_KPXCM  
GO  
  
-- v2015.07.08
  
-- �����԰��û��-��ȸ by ����õ 
CREATE PROC KPXCM_SUIImpDelvItemListPrint_KPXCM  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT,  
            -- ��ȸ����   
            @DelvSeq    INT,  
            @DelvSerl   INT, 
            @STDUnitQty DECIMAL(19,5) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @DelvSeq     = ISNULL( DelvSeq, 0 ), 
           @DelvSerl    = ISNULL( DelvSerl, 0 ), 
           @STDUnitQty  = ISNULL( STDUnitQty, 0 ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock2', @xmlFlags )       
      WITH (
            DelvSeq     INT, 
            DelvSerl    INT, 
            STDUnitQty  DECIMAL(19,5) 
           )    
    
    -- ������ȸ   
    SELECT C.ItemName, @STDUnitQty AS STDUnitQty 
      FROM _TUIImpDelv                  AS A 
                 JOIN _TUIImpDelvItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
      LEFT OUTER JOIN _TDAItem          AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.DelvSeq = @DelvSeq 
       AND B.DelvSerl = @DelvSerl 
    
    RETURN  
GO 