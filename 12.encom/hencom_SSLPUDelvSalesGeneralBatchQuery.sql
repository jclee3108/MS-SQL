IF OBJECT_ID('hencom_SSLPUDelvSalesGeneralBatchQuery') IS NOT NULL 
    DROP PROC hencom_SSLPUDelvSalesGeneralBatchQuery
GO 

-- v2017.05.02 
/************************************************************
 ��  �� - ������-���Ը����ڷ��ϰ�����(�Ϲ�)_HNCOM : ��ȸ
 ���ѻ������ ���.
 �ۼ��� - 20170314
 �ۼ��� - �ڼ���free
************************************************************/
CREATE PROC dbo.hencom_SSLPUDelvSalesGeneralBatchQuery 
	@xmlDocument    NVARCHAR(MAX) ,            
	@xmlFlags	    INT 	= 0,            
	@ServiceSeq	    INT 	= 0,            
	@WorkingTag	    NVARCHAR(10)= '',                  
	@CompanySeq	    INT 	= 1,            
	@LanguageSeq	INT 	= 1,            
	@UserSeq	    INT 	= 0,            
	@PgmSeq	        INT 	= 0         
    
AS        
	
	DECLARE @docHandle      INT,
		    @EmpSeq         INT ,
            @DeptSeq        INT ,
			@BizUnit		INT ,
            @DateTo         NCHAR(8) ,
            @DateFr         NCHAR(8) , 
            @SalesCustSeq   INT, 
            @DelvCustSeq    INT

 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
	SELECT  @EmpSeq           = ISNULL(EmpSeq   ,0), 
            @DeptSeq          = ISNULL(DeptSeq  ,0), 
			@BizUnit		  = ISNULL(BizUnit	,0), 
			@DateFr           = ISNULL(DateFr	,''), 
            @DateTo           = ISNULL(DateTo   ,''), 
            @SalesCustSeq     = ISNULL(SalesCustSeq, 0), 
            @DelvCustSeq      = ISNULL(DelvCustSeq, 0) 
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (
            EmpSeq          INT ,
            DeptSeq         INT ,
            BizUnit			INT ,
            DateFr          NCHAR(8),
            DateTo          NCHAR(8),
            SalesCustSeq    INT,
            DelvCustSeq     INT
           )
	
	SELECT  A.CompanySeq ,A.RegSeq ,A.BizUnit ,A.DeptSeq ,A.EmpSeq ,A.SalesDate ,A.UMOutType ,
			(SELECT DeptName FROM _TDADept WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq ) AS DeptName,
			(SELECT EmpName FROM _TDAEmp WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq ) AS EmpName ,
			B.CustName AS SalesCustName,
			C.ItemName AS ItemName ,
			(SELECT CustName FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = A.DelvCustSeq ) AS DelvCustName,
			(SELECT ProdDistirct FROM hencom_TPUPurchaseArea WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND ProdDistrictSeq = A.ProdDistrictSeq ) AS ProdDistrictName,
			(SELECT CustName FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = A.DeliCustSeq ) AS DeliCustName,
			A.SalesCustSeq ,A.DelvCustSeq ,A.ProdDistrictSeq ,A.ItemSeq ,A.Qty ,A.PuPrice ,
			A.PuIsVat ,A.PuAmt ,A.PuVat ,A.DeliCustSeq ,A.DeliChargePrice ,A.DeliIsVAT ,
			A.DeliChargeAmt ,A.DeliChargeVat ,A.SalesPrice ,A.SalesIsVat ,A.SalesAmt,A.SalesVat ,
			A.DelvSeq ,A.DelvSerl ,A.IsDelv ,A.InvoiceSeq ,A.InvoiceSerl ,A.IsInvoice ,A.Remark ,
			A.LastUserSeq ,A.LastDateTime ,
			10 AS DeliVATRate ,
			10 AS SalesVATRate,
			10 AS PuVATRate,
			ISNULL(A.DeliChargeAmt,0) + ISNULL(A.DeliChargeVat,0)	AS TotDeliChargeAmt,--��۱ݾװ�
			ISNULL(A.SalesAmt,0) + ISNULL(A.SalesVat,0)				AS TotSalesAmt,		--����ݾװ�
			ISNULL(PuAmt,0)+ ISNULL(PuVat,0)						AS TotPuAmt,		--����ݾװ�
			ISNULL(A.SalesPrice,0) - ISNULL(A.PuPrice,0) - ISNULL(A.DeliChargePrice,0)			AS ProfitPrice,		--����������: ����ܰ� - ���Դܰ� - ��۴ܰ�
			(SELECT DelvNo FROM _TPUDelv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND DelvSeq = A.DelvSeq ) AS DelvNo , --��ǰ��ȣ
			(SELECT InvoiceNo FROM _TSLInvoice WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND InvoiceSeq = A.InvoiceSeq ) AS InvoiceNo, --�ŷ�������ȣ
			A.LastUserSeq ,
			(SELECT UserName FROM _TCAUser WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND UserSeq = A.LastUserSeq ) AS LastUserName , --����������
			A.LastDateTime
      FROM  hencom_TSLDelvSalesGenItem AS A WITH (NOLOCK) 
	  LEFT OUTER JOIN _TDACust AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.CustSeq = A.SalesCustSeq
	  LEFT OUTER JOIN _TDAItem AS C WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq
	 WHERE  A.CompanySeq = @CompanySeq
		AND (@BizUnit = 0 OR A.BizUnit = @BizUnit)
	 	AND A.SalesDate BETWEEN CASE WHEN @DateFr = '' THEN A.SalesDate ELSE @DateFr END  
							AND CASE WHEN @DateTo = '' THEN A.SalesDate ELSE @DateTo END     
		AND (@DeptSeq = 0 OR A.DeptSeq  = @DeptSeq )   
        AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq  )         
        AND (@SalesCustSeq = 0 OR A.SalesCustSeq = @SalesCustSeq)
        AND (@DelvCustSeq = 0 OR A.DelvCustSeq = @DelvCustSeq)
      
RETURN
