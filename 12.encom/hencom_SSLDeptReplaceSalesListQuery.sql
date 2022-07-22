 
IF OBJECT_ID('hencom_SSLDeptReplaceSalesListQuery') IS NOT NULL   
    DROP PROC hencom_SSLDeptReplaceSalesListQuery  
GO  

-- v2017.06.20 
  
-- ����������Ȳ-��ȸ by ����õ   
CREATE PROC hencom_SSLDeptReplaceSalesListQuery  
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

    DECLARE @docHandle      INT,  
            -- ��ȸ����   
            @InvoiceDateFr  NCHAR(8),  
            @InvoiceDateTo  NCHAR(8),  
            @OutDeptSeq     INT, 
            @InDeptSeq      INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @InvoiceDateFr   = ISNULL( InvoiceDateFr, '' ),  
           @InvoiceDateTo   = ISNULL( InvoiceDateTo, '' ),  
           @OutDeptSeq      = ISNULL( OutDeptSeq   , 0 ),  
           @InDeptSeq       = ISNULL( InDeptSeq    , 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            InvoiceDateFr  NCHAR(8), 
            InvoiceDateTo  NCHAR(8), 
            OutDeptSeq     INT, 
            InDeptSeq      INT            
           )    
          
    SELECT A.WorkDate AS InvoiceDate,       -- �������� 
           A.PDDeptSeq AS OutDeptSeq,       -- ���������ڵ�
           A.PDDeptName AS OutDeptName,     -- ��������
           A.DeptSeq AS InDeptSeq,          -- ���Ի�����ڵ�
           A.DeptName AS InDeptName,        -- ���Ի���� 
           A.CustSeq, 
           A.CustName, 
           A.BizNo, 
           A.PJTSeq, 
           A.PJTName, 
           A.ItemSeq AS GoodItemSeq, 
           A.GoodItemName AS GoodItemName, 
           A.Qty, 
           A.Price, 
           A.IsInclusedVAT, 
           A.CurAmt, 
           A.CurVAT, 
           A.TotAmt, 
           A.UMCustClass, 
           A.UMCustClassName, 
           A.InvoiceSeq, 
           A.InvoiceSerl, 
           B.UMOutKind, 
           C.MinorName AS UMOutKindName 
      FROM hencom_VInvoiceReplaceItem   AS A 
      LEFT OUTER JOIN _TSLInvoice       AS B ON ( B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.InvoiceSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.UMOutKind ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.UMOutKind IN ( 8020096, 8020097 ) -- ����� ����,����
       AND A.WorkDate BETWEEN @InvoiceDateFr AND @InvoiceDateTo 
       AND ( @InDeptSeq = 0 OR A.DeptSeq = @InDeptSeq )
       AND ( @OutDeptSeq = 0 OR A.PDDeptSeq = @OutDeptSeq ) 
     ORDER BY A.WorkDate, A.PDDeptName, A.DeptName
    
    RETURN  
GO 
EXEC hencom_SSLDeptReplaceSalesListQuery @xmlDocument = N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <InvoiceDateFr>20170101</InvoiceDateFr>
    <InvoiceDateTo>20171220</InvoiceDateTo>
    <OutDeptSeq />
    <InDeptSeq />
  </DataBlock1>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 1512489, @WorkingTag = N'', @CompanySeq = 1, @LanguageSeq = 1, @UserSeq = 1, @PgmSeq = 1033821
