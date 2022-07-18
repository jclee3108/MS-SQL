
IF OBJECT_ID('KPX_SQCCOAPrintCustInfo') IS NOT NULL 
    DROP PROC KPX_SQCCOAPrintCustInfo
GO 

-- v2014.12.18    
    
-- ���輺��������(COA)-�ŷ�ó ���� by ����õ     
CREATE PROC KPX_SQCCOAPrintCustInfo    
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
            @CustSeq    INT,   
            @ItemSeq    INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
      
    SELECT @CustSeq   = ISNULL( CustSeq, 0 ), 
           @ItemSeq   = ISNULL( ItemSeq, 0 ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )         
      WITH (
            CustSeq    INT, 
            ItemSeq    INT 
           )    
    
    SELECT A.CustItemName
      FROM _TSLCustItem AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.CustSeq = @CustSeq 
       AND A.ItemSeq = @ItemSeq 
    
    RETURN 