  
IF OBJECT_ID('KPXCM_SUIImpDelvItemListPrintJump_KPXCM') IS NOT NULL   
    DROP PROC KPXCM_SUIImpDelvItemListPrintJump_KPXCM  
GO  
  
-- v2015.07.08
  
-- �����԰��û��-������ȸ by ����õ 
CREATE PROC KPXCM_SUIImpDelvItemListPrintJump_KPXCM  
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
            @DelvSerl   INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @DelvSeq     = ISNULL( DelvSeq, 0 ), 
           @DelvSerl    = ISNULL( DelvSerl, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            DelvSeq     INT, 
            DelvSerl    INT
           )    
    
    -- ������ȸ   
    SELECT C.ItemName, 
           C.ItemNo, 
           B.STDQty AS STDUnitQty, 
           D.BizUnitName, 
           A.DelvSeq, 
           B.DelvSerl,
           E.CustName 
      FROM _TUIImpDelv                  AS A 
                 JOIN _TUIImpDelvItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
      LEFT OUTER JOIN _TDAItem          AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDABizUnit       AS D ON ( D.CompanySeq = @CompanySeq AND D.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN _TDACust          AS E ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = A.CustSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.DelvSeq = @DelvSeq 
       AND B.DelvSerl = @DelvSerl 
    
    RETURN  
GO 