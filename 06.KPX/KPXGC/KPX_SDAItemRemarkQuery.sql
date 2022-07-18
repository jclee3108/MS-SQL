
IF OBJECT_ID('KPX_SDAItemRemarkQuery') IS NOT NULL
    DROP PROC KPX_SDAItemRemarkQuery
GO 

-- v2014.11.04 

-- �����ȸ by����õ
/*********************************************************************************************************************  
    ȭ��� : ǰ����_�����ȸ  
    SP Name: _SDAItemRemarkQuery  
    �ۼ��� : 2010.04.14 : CREATEd by ������      
    ������ :   
********************************************************************************************************************/  
CREATE PROCEDURE KPX_SDAItemRemarkQuery    
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS         
    DECLARE @docHandle    INT,   
            @ItemSeq      INT  
  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
  
    SELECT  @ItemSeq = ItemSeq   
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)       
    WITH (ItemSeq INT)    
  
  
/***********************************************************************************************************************************************/  
    SELECT ItemRemark    AS ItemRemark  
      FROM KPX_TDAItemRemark WITH(NOLOCK)  
     WHERE CompanySeq  = @CompanySeq   
       AND ItemSeq     = @ItemSeq  
       
    RETURN    
  
  