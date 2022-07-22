IF OBJECT_ID('hencom_SSLCustSalesChgEmpMonthStdQuery ') IS NOT NULL 
    DROP PROC hencom_SSLCustSalesChgEmpMonthStdQuery 
GO 

-- v2017.06.29 

/************************************************************  
    Ver.20140925
 ��  �� - �����ذŷ�ó��������ں��� : ��ȸ  
 �ۼ��� - 20100303  
 �ۼ��� - �ֿ���  
************************************************************/  
CREATE PROC dbo.hencom_SSLCustSalesChgEmpMonthStdQuery 
    @xmlDocument    NVARCHAR(MAX) ,              
    @xmlFlags       INT  = 0,              
    @ServiceSeq     INT  = 0,              
    @WorkingTag     NVARCHAR(10)= '',                    
    @CompanySeq     INT  = 1,              
    @LanguageSeq    INT  = 1,              
    @UserSeq        INT  = 0,              
    @PgmSeq         INT  = 0           
      
AS          
   
	DECLARE @docHandle		INT,  
            @DateFr         NCHAR(8), 
            @DateTo         NCHAR(8), 
			@SalesBizSeq	INT,			--��������
			@SalesBiz        NVARCHAR(50),
            @BizUnit        INT, 
            @CustSeq        INT, 
            @QDeptSeq       INT
   
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
  
    SELECT @DateFr	    = ISNULL(DateFr,''),  
           @DateTo	    = ISNULL(DateTo,''),  
           @SalesBizSeq	= ISNULL(SalesBizSeq,0),
           @SalesBiz    = ISNULL(SalesBiz,''),
           @BizUnit     = ISNULL(BizUnit,0    ),  
           @CustSeq     = ISNULL(CustSeq,0    ), 
           @QDeptSeq    = ISNULL(QDeptSeq,0 )
           
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (
            DateFr         NCHAR(8), 
            DateTo         NCHAR(8), 
            SalesBizSeq		INT,
            SalesBiz        NVARCHAR(50),
            BizUnit         INT, 
            CustSeq         INT, 
            QDeptSeq        INT
           )
    
    IF ISNULL(@SalesBizSeq,0) = 0 -- ����seq���� 1�� �ƴѰ�� �ڵ嵵�� �ڵ尪�� �������� ���ϴ� ������ ���� ������ �κ� 
    BEGIN
        SELECT TOP 1 @SalesBizSeq = MinorSeq FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MajorSeq = 8062 AND MinorName = @SalesBiz
    END
    
    /*
	IF @SalesBizSeq = 8062001	-- ����
	BEGIN     
		SELECT DISTINCT		   
			   A.OrderNo AS StdNo,																										--��ȣ
			   A.OrderDate AS StdDate,																									--����
			   A.CustSeq	AS CustSeq,	--�ŷ�ó�ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--�ŷ�ó
			   (SELECT CustNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--�ŷ�ó��ȣ
			   ISNULL((	SELECT sum(ISNULL(DomAmt,0) + ISNULL(DomVAT,0)) FROM _TSLOrderItem												--�ݾ�
						WHERE CompanySeq = @CompanySeq AND OrderSeq = A.OrderSeq), 0) AS StdAmt,		   
			   A.EmpSeq	  AS EmpSeq,				--������ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--���������
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--���������
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,						--���μ�
			   A.OrderSeq AS StdSeq,																									--���ι�ȣ
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = ISNULL(C.EmpSeq, B.EmpSeq)) AS NowSalesEmpName,	--�����������
			   (SELECT EmpId FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = ISNULL(C.EmpSeq, B.EmpSeq)) AS NowSalesEmpNo,		--�����������
			   (SELECT DeptName From _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = ISNULL(C.DeptSeq, B.DeptSeq)) AS NowDeptName,--�����μ�
			   (SELECT EmpSeq FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = ISNULL(C.EmpSeq, B.EmpSeq)) AS NowSalesEmpSeq,	--����������ڼ���
			   (SELECT DeptSeq From _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = ISNULL(C.DeptSeq, B.DeptSeq)) AS NowDeptSeq,	--�����μ�����
			   @SalesBizSeq AS SalesBizSeq,																								--���������ڵ�
			   A.BizUnit AS BizUnit,	--����ι� 2015.02.09 ��ҷ� �߰�
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName	--����ι��̸� 2015.02.09 ��ҷ� �߰�
		  FROM _TSLOrder AS A
			LEFT OUTER JOIN _TSLCustSalesEmp AS B ON A.CompanySeq = B.CompanySeq
												 AND A.CustSeq = B.CustSeq								 					  
			LEFT OUTER JOIN _TSLCustSalesEmpHist AS C ON A.CompanySeq = C.CompanySeq
													 AND A.CustSeq = C.CustSeq
													 AND (A.OrderDate BETWEEN C.SDate AND C.Edate)			
		 WHERE A.CompanySeq = @CompanySeq
		   AND A.OrderDate LIKE @StdMonth + '%'
		   AND (A.DeptSeq <> ISNULL(C.DeptSeq, B.DeptSeq)
			OR A.EmpSeq <> ISNULL(C.EmpSeq, B.EmpSeq))
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit  )    --����ι� ��ȸ ���� �߰� 20150128 Ȳ����
           AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq  )    --���μ���ȸ ���� �߰� 20150128 Ȳ����
           AND (@EmpSeq  = 0 OR A.EmpSeq  = @EmpSeq   )    --��������� ��ȸ ���� �߰� 20150128 Ȳ����
            
		 ORDER BY A.OrderSeq
	END
	
	IF @SalesBizSeq = 8062002	-- �����Ƿ�
	BEGIN     
		SELECT DISTINCT		   
			   A.DVReqNo AS StdNo,																										--��ȣ
			   A.DVReqDate AS StdDate,																									--����
			   A.CustSeq	AS CustSeq,	--�ŷ�ó�ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--�ŷ�ó
			   (SELECT CustNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--�ŷ�ó��ȣ
			   ISNULL((	SELECT sum(ISNULL(DomAmt,0) + ISNULL(DomVAT,0)) FROM _TSLDVReqItem												--�ݾ�
						WHERE CompanySeq = @CompanySeq AND DVReqSeq = A.DVReqSeq), 0) AS StdAmt,		   
			   A.EmpSeq	  AS EmpSeq,				--������ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--���������
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--���������
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,						--���μ�
			   A.DVReqSeq AS StdSeq,																									--���ι�ȣ
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = ISNULL(C.EmpSeq, B.EmpSeq)) AS NowSalesEmpName,	--�����������
			   (SELECT EmpId FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = ISNULL(C.EmpSeq, B.EmpSeq)) AS NowSalesEmpNo,		--�����������
			   (SELECT DeptName From _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = ISNULL(C.DeptSeq, B.DeptSeq)) AS NowDeptName,--�����μ�
			   (SELECT EmpSeq FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = ISNULL(C.EmpSeq, B.EmpSeq)) AS NowSalesEmpSeq,	--����������ڼ���
			   (SELECT DeptSeq From _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = ISNULL(C.DeptSeq, B.DeptSeq)) AS NowDeptSeq,	--�����μ�����
			   @SalesBizSeq AS SalesBizSeq,																								--���������ڵ�
			   A.BizUnit AS BizUnit,	--����ι� 2015.02.09 ��ҷ� �߰�
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName	--����ι��̸� 2015.02.09 ��ҷ� �߰�
		  FROM _TSLDVReq AS A
			LEFT OUTER JOIN _TSLCustSalesEmp AS B ON A.CompanySeq = B.CompanySeq
												 AND A.CustSeq = B.CustSeq								 					  
			LEFT OUTER JOIN _TSLCustSalesEmpHist AS C ON A.CompanySeq = C.CompanySeq
													 AND A.CustSeq = C.CustSeq
													 AND (A.DVReqDate BETWEEN C.SDate AND C.Edate)			
		 WHERE A.CompanySeq = @CompanySeq
		   AND A.DVReqDate LIKE @StdMonth + '%'
		   AND (A.DeptSeq <> ISNULL(C.DeptSeq, B.DeptSeq)
			OR A.EmpSeq <> ISNULL(C.EmpSeq, B.EmpSeq))
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit  )    --����ι� ��ȸ ���� �߰� 20150128 Ȳ����
           AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq  )    --���μ���ȸ ���� �߰� 20150128 Ȳ����
           AND (@EmpSeq  = 0 OR A.EmpSeq  = @EmpSeq   )    --��������� ��ȸ ���� �߰� 20150128 Ȳ����
            
		 ORDER BY A.DVReqSeq
	END	
	*/
	IF @SalesBizSeq = 8062003	--�ŷ�����
	BEGIN     
		SELECT DISTINCT		   
			   A.InvoiceNo AS StdNo,																									--��ȣ
			   A.InvoiceDate AS StdDate,																								--����
			   A.CustSeq	AS CustSeq,	--�ŷ�ó�ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--�ŷ�ó
			   (SELECT CustNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--�ŷ�ó��ȣ
			   ISNULL((	SELECT sum(ISNULL(DomAmt,0) + ISNULL(DomVAT,0)) FROM _TSLInvoiceItem											--�ݾ�
						WHERE CompanySeq = @CompanySeq AND InvoiceSeq = A.InvoiceSeq), 0) AS StdAmt,		   
			   A.EmpSeq	  AS EmpSeq,				--������ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--���������
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--���������
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,						--���μ�
               A.DeptSeq, 
			   A.InvoiceSeq AS StdSeq,																									--���ι�ȣ
			   @SalesBizSeq AS SalesBizSeq,																								--���������ڵ�
			   A.BizUnit AS BizUnit,	--����ι� 2015.02.09 ��ҷ� �߰�
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName	--����ι��̸� 2015.02.09 ��ҷ� �߰�
		  FROM _TSLInvoice AS A
			LEFT OUTER JOIN _TSLCustSalesEmp AS B ON A.CompanySeq = B.CompanySeq
												 AND A.CustSeq = B.CustSeq								 					  
			LEFT OUTER JOIN _TSLCustSalesEmpHist AS C ON A.CompanySeq = C.CompanySeq
													 AND A.CustSeq = C.CustSeq
													 AND (A.InvoiceDate BETWEEN C.SDate AND C.Edate)			
		 WHERE A.CompanySeq = @CompanySeq
		   AND (A.InvoiceDate BETWEEN @DateFr AND @DateTo)
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit  )    
           AND (@CustSeq = 0 OR A.CustSeq = @CustSeq ) 
           AND (@QDeptSeq = 0 OR A.DeptSeq = @QDeptSeq)
            
		 ORDER BY A.InvoiceSeq
	END
	
	IF @SalesBizSeq = 8062004	--����
	BEGIN     
		SELECT DISTINCT		   
			   A.SalesNo	AS StdNo,																										--��ȣ
			   A.SalesDate	AS StdDate,																									--����
			   A.CustSeq	AS CustSeq,	--�ŷ�ó�ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--�ŷ�ó
			   (SELECT CustNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--�ŷ�ó��ȣ
			   ISNULL((	SELECT sum(ISNULL(DomAmt,0) + ISNULL(DomVAT,0)) FROM _TSLSalesItem												--�ݾ�
						WHERE CompanySeq = @CompanySeq AND SalesSeq = A.SalesSeq), 0) AS StdAmt,		   
			   A.EmpSeq	  AS EmpSeq,				--������ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--���������
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--���������
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,						--���μ�
               A.DeptSeq, 
			   A.SalesSeq AS StdSeq,																									--���ι�ȣ
			   @SalesBizSeq AS SalesBizSeq,																								--���������ڵ�
			   A.BizUnit AS BizUnit,	--����ι� 2015.02.09 ��ҷ� �߰�
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName	--����ι��̸� 2015.02.09 ��ҷ� �߰�
		  FROM _TSLSales AS A
			LEFT OUTER JOIN _TSLCustSalesEmp AS B ON A.CompanySeq = B.CompanySeq
												 AND A.CustSeq = B.CustSeq								 					  
			LEFT OUTER JOIN _TSLCustSalesEmpHist AS C ON A.CompanySeq = C.CompanySeq
													 AND A.CustSeq = C.CustSeq
													 AND (A.SalesDate BETWEEN C.SDate AND C.Edate)			
		 WHERE A.CompanySeq = @CompanySeq
		   AND (A.SalesDate BETWEEN @DateFr AND @DateTo)
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit)
           AND (@CustSeq = 0 OR A.CustSeq = @CustSeq ) 
           AND (@QDeptSeq = 0 OR A.DeptSeq = @QDeptSeq)
            
		 ORDER BY A.SalesSeq
	END
	
	IF @SalesBizSeq = 8062005	--���ݰ�꼭
	BEGIN     
		SELECT DISTINCT		   
			   A.BillNo		AS StdNo,																										--��ȣ
			   A.BillDate	AS StdDate,																									--����
			   A.CustSeq	AS CustSeq,	--�ŷ�ó�ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--�ŷ�ó
			   (SELECT CustNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--�ŷ�ó��ȣ
			   ISNULL((	SELECT sum(ISNULL(DomAmt,0) + ISNULL(DomVAT,0)) FROM _TSLBillItem												--�ݾ�
						WHERE CompanySeq = @CompanySeq AND BillSeq = A.BillSeq), 0) AS StdAmt,		   
			   A.EmpSeq	  AS EmpSeq,				--������ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--���������
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--���������
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,						--���μ�
               A.DeptSeq, 
			   A.BillSeq AS StdSeq,																										--���ι�ȣ
			   @SalesBizSeq AS SalesBizSeq,																								--���������ڵ�
			   A.BizUnit AS BizUnit,	--����ι� 2015.02.09 ��ҷ� �߰�
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName	--����ι��̸� 2015.02.09 ��ҷ� �߰�
		  FROM _TSLBill AS A
			LEFT OUTER JOIN _TSLCustSalesEmp AS B ON A.CompanySeq = B.CompanySeq
												 AND A.CustSeq = B.CustSeq								 					  
			LEFT OUTER JOIN _TSLCustSalesEmpHist AS C ON A.CompanySeq = C.CompanySeq
													 AND A.CustSeq = C.CustSeq
													 AND (A.BillDate BETWEEN C.SDate AND C.Edate)			
		 WHERE A.CompanySeq = @CompanySeq
           AND (A.BillDate BETWEEN @DateFr AND @DateTo)
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit) 
           AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)
           AND (@QDeptSeq = 0 OR A.DeptSeq = @QDeptSeq)
            
		 ORDER BY A.BillSeq
	END
	
	IF @SalesBizSeq = 8062006	--�Ա�
	BEGIN     
		SELECT DISTINCT		   
			   A.ReceiptNo		AS StdNo,																									--��ȣ
			   A.ReceiptDate	AS StdDate,																								--����
			  A.CustSeq			AS CustSeq,	--�ŷ�ó�ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT CustName FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--�ŷ�ó
			   (SELECT CustNo FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--�ŷ�ó��ȣ
			   ISNULL((	SELECT sum(ISNULL(DomAmt,0)) FROM _TSLReceiptDESC WITH(NOLOCK)																--�ݾ�
						WHERE CompanySeq = @CompanySeq AND ReceiptSeq = A.ReceiptSeq), 0) AS StdAmt,		   
			   A.EmpSeq	  AS EmpSeq,				--������ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--���������
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--���������
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,						--���μ�
               A.DeptSeq, 
			   A.ReceiptSeq AS StdSeq,																									--���ι�ȣ
			   @SalesBizSeq AS SalesBizSeq,																			--���������ڵ�
			   A.BizUnit AS BizUnit,	--����ι� 2015.02.09 ��ҷ� �߰�
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName	--����ι��̸� 2015.02.09 ��ҷ� �߰�
		  FROM _TSLReceipt AS A
			LEFT OUTER JOIN _TSLCustSalesEmp AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
												 AND A.CustSeq = B.CustSeq								 					  
			LEFT OUTER JOIN _TSLCustSalesEmpHist AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq
													 AND A.CustSeq = C.CustSeq
													 AND (A.ReceiptDate BETWEEN C.SDate AND C.Edate)			
		 WHERE A.CompanySeq = @CompanySeq
           AND (A.ReceiptDate BETWEEN @DateFr AND @DateTo)
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit) 
           AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)
           AND (@QDeptSeq = 0 OR A.DeptSeq = @QDeptSeq)
            
		 ORDER BY A.ReceiptSeq
	END

    /*

    IF @SalesBizSeq = 8062007   -- ����BL
    BEGIN
        SELECT DISTINCT
               @SalesBizSeq AS SalesBizSeq,
               A.BLRefNo	AS StdNo,
               A.BLSeq		AS StdSeq,
               A.BLDate		AS StdDate,
			   A.CustSeq	AS CustSeq,	--�ŷ�ó�ڵ� 2015.02.09 ��ҷ� �߰�
               (SELECT CustName FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,--�ŷ�ó
               (SELECT CustNo FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,--�ŷ�ó��ȣ
               ISNULL(( SELECT SUM(ISNULL(DomAmt,0) + ISNULL(DomVAT,0)) FROM _TSLExpBLItem WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BLSeq = A.BLSeq), 0) AS StdAmt,
			   A.EmpSeq	  AS EmpSeq,				--������ڵ� 2015.02.09 ��ҷ� �߰�
               (SELECT EmpName FROM _TDAEmp WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,--���������
               (SELECT EmpID FROM _TDAEmp WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,--���������
               (SELECT DeptName FROM _TDADept WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,--���μ�
               (SELECT EmpName FROM _TDAEmp WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EmpSeq = ISNULL(C.EmpSeq, B.EmpSeq)) AS NowSalesEmpName, --�����������
               (SELECT EmpId FROM _TDAEmp WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EmpSeq = ISNULL(C.EmpSeq, B.EmpSeq)) AS NowSalesEmpNo,--�����������  
               (SELECT DeptName From _TDADept WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND DeptSeq = ISNULL(C.DeptSeq, B.DeptSeq)) AS NowDeptName,--�����μ�
               (SELECT EmpSeq FROM _TDAEmp WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EmpSeq = ISNULL(C.EmpSeq, B.EmpSeq)) AS NowSalesEmpSeq, --����������ڼ���
               (SELECT DeptSeq From _TDADept WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND DeptSeq = ISNULL(C.DeptSeq, B.DeptSeq)) AS NowDeptSeq, --�����μ�����
               A.BizUnit AS BizUnit,	--����ι� 2015.02.09 ��ҷ� �߰�
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName	--����ι��̸� 2015.02.09 ��ҷ� �߰�
          FROM _TSLExpBL AS A WITH(NOLOCK)
               LEFT OUTER JOIN _TSLCustSalesEmp AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.CustSeq = B.CustSeq                  
               LEFT OUTER JOIN _TSLCustSalesEmpHist AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.CustSeq = C.CustSeq AND (A.BLDate BETWEEN C.SDate AND C.Edate)     
         WHERE A.CompanySeq = @CompanySeq  
           AND A.BLDate LIKE @StdMonth + '%'  
           AND (A.DeptSeq <> ISNULL(C.DeptSeq, B.DeptSeq)  
            OR  A.EmpSeq <> ISNULL(C.EmpSeq, B.EmpSeq))
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit  )    --����ι� ��ȸ ���� �߰� 20150128 Ȳ����
           AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq  )    --���μ���ȸ ���� �߰� 20150128 Ȳ����
           AND (@EmpSeq  = 0 OR A.EmpSeq  = @EmpSeq   )    --��������� ��ȸ ���� �߰� 20150128 Ȳ����
            
      ORDER BY A.BLSeq  
    END --::IF @SalesBizSeq = 8062007   -- ����BL
	IF @SalesBizSeq = 8062008   -- �ǸŸ�ǥ 2015.02.06 ��ҷ� �߰�
    BEGIN
       SELECT @SalesBizSeq						AS SalesBizSeq,
               ''								AS StdNo,
               A.PlanYM							AS StdSeq,				-- ��ȹ����� ���ι�ȣ�� ����
               A.PlanYM							AS StdDate,
			   A.CustSeq						AS CustSeq,				--�ŷ�ó�ڵ�
               D.CustName						AS CustName,			--�ŷ�ó
               D.CustNo							AS CustNo,				--�ŷ�ó��ȣ
               SUM(ISNULL(A.PlanAmt,0))			AS StdAmt,
			   A.EmpSeq							AS EmpSeq,				--������ڵ�	
               E.EmpName						AS EmpName,				--���������
               E.EmpID							AS EmpNo,				--���������
               F.DeptName						AS DeptName,			--���μ�
			   ISNULL(E2.EmpName, E1.EmpName)	AS NowSalesEmpName,		--�����������
			   ISNULL(E2.EmpId, E1.EmpId)		AS NowSalesEmpNo,		--�����������  
			   ISNULL(F2.DeptName, F1.DeptName) AS NowDeptName,			--�����μ�
			   ISNULL(E2.EmpSeq, E1.EmpSeq)		AS NowSalesEmpSeq,		--����������ڼ���
			   ISNULL(F2.DeptSeq, F1.DeptSeq)	AS NowDeptSeq,			--�����μ�����
			   A.BizUnit						AS BizUnit,				--����ι�
			   G.BizUnitName					AS BizUnitName			--����ι�
          FROM _TSLPlanMonthSales						AS A WITH(NOLOCK)
               LEFT OUTER JOIN _TSLCustSalesEmp			AS B WITH(NOLOCK)  ON A.CompanySeq	= B.CompanySeq 
																		  AND A.CustSeq		= B.CustSeq                  
               LEFT OUTER JOIN _TSLCustSalesEmpHist		AS C WITH(NOLOCK)  ON A.CompanySeq	= C.CompanySeq 
																		  AND A.CustSeq		= C.CustSeq 
																		  AND A.PlanYM		= LEFT(C.Edate,6)
			   LEFT OUTER JOIN _TDACust					AS D WITH(NOLOCK)  ON A.CompanySeq	= D.CompanySeq  
																		  AND A.CustSeq		= D.CustSeq
			   LEFT OUTER JOIN _TDAEmp					AS E WITH(NOLOCK)  ON A.CompanySeq	= D.CompanySeq  
																		  AND A.EmpSeq		= E.EmpSeq
			   LEFT OUTER JOIN _TDAEmp					AS E1 WITH(NOLOCK) ON B.CompanySeq	= E1.CompanySeq 
																		  AND B.EmpSeq		= E1.EmpSeq	
			   LEFT OUTER JOIN _TDAEmp					AS E2 WITH(NOLOCK) ON C.CompanySeq	= E2.CompanySeq 
																		  AND C.EmpSeq		= E2.EmpSeq	
			   LEFT OUTER JOIN _TDADept					AS F WITH(NOLOCK)  ON A.CompanySeq	= D.CompanySeq  
																		  AND A.DeptSeq		= F.DeptSeq		
			   LEFT OUTER JOIN _TDADept					AS F1 WITH(NOLOCK) ON B.CompanySeq	= F1.CompanySeq 
																		  AND B.DeptSeq		= F1.DeptSeq	
			   LEFT OUTER JOIN _TDADept					AS F2 WITH(NOLOCK) ON C.CompanySeq	= F2.CompanySeq 
																		  AND C.DeptSeq		= F2.DeptSeq
			   LEFT OUTER JOIN _TDABizUnit				AS G WITH(NOLOCK) ON  A.CompanySeq	= G.CompanySeq
																		  AND A.BizUnit		= G.BizUnit													   
										  	
         WHERE A.CompanySeq = @CompanySeq  
           AND A.PlanYM LIKE @StdMonth + '%'   
           AND (A.DeptSeq <> ISNULL(C.DeptSeq, B.DeptSeq)  
            OR  A.EmpSeq <> ISNULL(C.EmpSeq, B.EmpSeq))
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit  )    --����ι� ��ȸ ���� �߰� 20150128 Ȳ����
           AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq  )    --���μ���ȸ ���� �߰� 20150128 Ȳ����
           AND (@EmpSeq  = 0 OR A.EmpSeq  = @EmpSeq   )    --��������� ��ȸ ���� �߰� 20150128 Ȳ����
	  GROUP BY A.BizUnit,	A.DeptSeq,	A.EmpSeq,	 A.PlanYM,		D.CustName,		D.CustNo ,
			   E.EmpName,	E.EmpID ,	F.DeptName,	 E2.EmpName,	E1.EmpName,		E2.EmpId, E1.EmpId,
			   E2.EmpSeq,	E1.EmpSeq,	F2.DeptSeq,	 F1.DeptSeq,	F2.DeptName,	F1.DeptName,
			   A.CustSeq,	A.BizUnit,	G.BizUnitName
      ORDER BY A.PlanYM   
    END --::IF @SalesBizSeq = 8062008   -- �ǸŸ�ǥ
    
    */

RETURN
