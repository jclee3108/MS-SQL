IF OBJECT_ID('hencom_SSLSalesEmpChangeQuery') IS NOT NULL 
    DROP PROC hencom_SSLSalesEmpChangeQuery
GO 

-- v2017.04.17 

/************************************************************  
    Ver.20140925
 ��  �� - �����ذŷ�ó��������ں��� : ��ȸ  
 �ۼ��� - 20100303  
 �ۼ��� - �ֿ���  
************************************************************/  
CREATE PROC dbo.hencom_SSLSalesEmpChangeQuery
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
            @StdMonthFr     NCHAR(6),	--���ؿ�
            @StdMonthTo     NCHAR(6),	--���ؿ�
			@SalesBizSeq	INT,			--��������
			@SalesBiz        NVARCHAR(50),
            @DeptSeq        INT, 
            @BizUnit        INT, 
            @EmpSeq         INT,
			@CustSeq        int
   
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
  
    SELECT @StdMonthFr  = ISNULL(StdMonthFr,''),  
           @StdMonthTo  = ISNULL(StdMonthTo,''),  
           @SalesBizSeq	= ISNULL(SalesBizSeq,0),
           @SalesBiz    = ISNULL(SalesBiz,''),
           @DeptSeq     = ISNULL(DeptSeq,0    ),  --���μ���ȸ ���� �߰� 20150128 Ȳ���� 
           @BizUnit     = ISNULL(BizUnit,0    ),  --����ι� ��ȸ ���� �߰� 20150128 Ȳ����
           @EmpSeq      = ISNULL(EmpSeq ,0    ),   --��������� ��ȸ ���� �߰� 20150128 Ȳ����
           @CustSeq     = ISNULL(CustSeq ,0    )   --��������� ��ȸ ���� �߰� 20150128 Ȳ����
           
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (StdMonthFr      NCHAR(6),  
            StdMonthTo      NCHAR(6),   
            SalesBizSeq		INT,
            SalesBiz        NVARCHAR(50),
            DeptSeq         INT,
            BizUnit         INT,
            EmpSeq          INT,
			CustSeq         int)
    
    IF ISNULL(@SalesBizSeq,0) = 0 -- ����seq���� 1�� �ƴѰ�� �ڵ嵵�� �ڵ尪�� �������� ���ϴ� ������ ���� ������ �κ� 
    BEGIN
        SELECT TOP 1 @SalesBizSeq = MinorSeq FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MajorSeq = 8062 AND MinorName = @SalesBiz
    END
    
	
	IF @SalesBizSeq = 8062003	--�ŷ�����
	BEGIN     
		SELECT A.InvoiceNo AS StdNo,																									--��ȣ
			   A.InvoiceDate AS StdDate,																								--����
			   A.CustSeq	AS CustSeq,	--�ŷ�ó�ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--�ŷ�ó
			   (SELECT CustNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--�ŷ�ó��ȣ
			   A.EmpSeq	  AS EmpSeq,				--������ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--���������
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--���������
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptNameOri,						--���μ�
			   A.InvoiceSeq AS StdSeq,																									--���ι�ȣ
			   @SalesBizSeq AS SalesBizSeq,																								--���������ڵ�
			   A.BizUnit AS BizUnit,	--����ι� 2015.02.09 ��ҷ� �߰�
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName,	--����ι��̸� 2015.02.09 ��ҷ� �߰�

			   i.CurAmt + i.CurVAT AS StdAmt,		   
			   i.PJTSeq,
			   (select PJTName  from _TPJTProject where companyseq = a.CompanySeq and pjtseq = i.PJTSeq ) as PJTName,
			   i.ItemSeq,
			   ( select ItemNo  from _TDAItem where CompanySeq = a.CompanySeq and ItemSeq = i.ItemSeq ) as ItemName,
			   case isnull(c.bizno,'') when '' then '' else  substring(c.BizNo,1,3) + '-' + substring(c.BizNo,4,2) + '-' + substring(c.BizNo,6,5) end as BizNo,
		       ISNULL(dbo._fnResidMask(dbo._FCOMDecrypt(c.PersonId, '_TDACust', 'PersonId', @CompanySeq)),'') AS PersonId,
			   i.invoiceserl   AS StdSerl
			   
		  FROM _TSLInvoice AS A
		    join _TSLInvoiceItem as i on i.CompanySeq = a.CompanySeq
			                       and i.InvoiceSeq = a.InvoiceSeq
 left outer join _TDACust as c on c.CompanySeq = a.CompanySeq
               and c.CustSeq = a.CustSeq
		 WHERE A.CompanySeq = @CompanySeq
		   AND LEFT(A.InvoiceDate,6) BETWEEN @StdMonthFr AND @StdMonthTo 
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit  )    --����ι� ��ȸ ���� �߰� 20150128 Ȳ����
           AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq  )    --���μ���ȸ ���� �߰� 20150128 Ȳ����
           AND (@EmpSeq  = 0 OR A.EmpSeq  = @EmpSeq   )    --��������� ��ȸ ���� �߰� 20150128 Ȳ����
           AND (@CustSeq  = 0 OR A.CustSeq  = @CustSeq   )    --��������� ��ȸ ���� �߰� 20150128 Ȳ����
            
		 ORDER BY A.InvoiceSeq, i.InvoiceSerl
	END
	
	IF @SalesBizSeq = 8062004	--����
	BEGIN     
		SELECT DISTINCT		   
			   A.SalesNo	AS StdNo,																										--��ȣ
			   A.SalesDate	AS StdDate,																									--����
			   A.CustSeq	AS CustSeq,	--�ŷ�ó�ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--�ŷ�ó
			   (SELECT CustNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--�ŷ�ó��ȣ
			   A.EmpSeq	  AS EmpSeq,				--������ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--���������
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--���������
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,						--���μ�
			   A.SalesSeq AS StdSeq,																									--���ι�ȣ
			   @SalesBizSeq AS SalesBizSeq,																								--���������ڵ�
			   A.BizUnit AS BizUnit,	--����ι� 2015.02.09 ��ҷ� �߰�
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName,	--����ι��̸� 2015.02.09 ��ҷ� �߰�
			   i.CurAmt + i.CurVAT AS StdAmt,		   
			   i.PJTSeq,
			   (select PJTName  from _TPJTProject where companyseq = a.CompanySeq and pjtseq = i.PJTSeq ) as PJTName,
			   i.ItemSeq,
			   ( select ItemNo  from _TDAItem where CompanySeq = a.CompanySeq and ItemSeq = i.ItemSeq ) as ItemName,
			   case isnull(c.bizno,'') when '' then '' else  substring(c.BizNo,1,3) + '-' + substring(c.BizNo,4,2) + '-' + substring(c.BizNo,6,5) end as BizNo,
		       ISNULL(dbo._fnResidMask(dbo._FCOMDecrypt(c.PersonId, '_TDACust', 'PersonId', @CompanySeq)),'') AS PersonId,
			   i.salesserl   AS StdSerl

		  FROM _TSLSales AS A
		  join _TSLSalesitem as i on i.CompanySeq = a.CompanySeq
			                     and i.salesseq = a.salesseq
left outer join _TDACust as c on c.CompanySeq = a.CompanySeq
                              and c.CustSeq = a.CustSeq
		 WHERE A.CompanySeq = @CompanySeq
		   AND LEFT(A.SalesDate,6) BETWEEN @StdMonthFr AND @StdMonthTo 
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit  )    --����ι� ��ȸ ���� �߰� 20150128 Ȳ����
           AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq  )    --���μ���ȸ ���� �߰� 20150128 Ȳ����
           AND (@EmpSeq  = 0 OR A.EmpSeq  = @EmpSeq   )    --��������� ��ȸ ���� �߰� 20150128 Ȳ����
           AND (@CustSeq  = 0 OR A.CustSeq  = @CustSeq   )    --��������� ��ȸ ���� �߰� 20150128 Ȳ����
            
		 ORDER BY A.SalesSeq
	END
	
	IF @SalesBizSeq = 8062005	--���ݰ�꼭   û���� ���� ������Ʈ�� ������ ���� �����Ƿ� ���⿡ ������ �����ϴ��� ��ü�� ������ �����ؾ� �Ѵ�
	BEGIN     


		SELECT A.BillSeq,
		       A.BillNo		AS StdNo,																										--��ȣ
			   A.BillDate	AS StdDate,																									--����
			   A.CustSeq	AS CustSeq,	--�ŷ�ó�ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--�ŷ�ó
			   (SELECT CustNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--�ŷ�ó��ȣ
			   --ISNULL((	SELECT sum(ISNULL(DomAmt,0) + ISNULL(DomVAT,0)) FROM _TSLBillItem												--�ݾ�
						--WHERE CompanySeq = @CompanySeq AND BillSeq = A.BillSeq), 0) AS StdAmt,		   
			   A.EmpSeq	  AS EmpSeq,				--������ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--���������
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--���������
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptNameOri,						--���μ�
			   A.BillSeq AS StdSeq,																										--���ι�ȣ
			   @SalesBizSeq AS SalesBizSeq,																								--���������ڵ�
			   A.BizUnit AS BizUnit,	--����ι� 2015.02.09 ��ҷ� �߰�
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName,	--����ι��̸� 2015.02.09 ��ҷ� �߰�
			   case isnull(c.bizno,'') when '' then '' else  substring(c.BizNo,1,3) + '-' + substring(c.BizNo,4,2) + '-' + substring(c.BizNo,6,5) end as BizNo,
		       ISNULL(dbo._fnResidMask(dbo._FCOMDecrypt(c.PersonId, '_TDACust', 'PersonId', @CompanySeq)),'') AS PersonId
          into #result
		  FROM _TSLBill AS A
left outer join _TDACust as c on c.CompanySeq = a.CompanySeq
                              and c.CustSeq = a.CustSeq
		 WHERE A.CompanySeq = @CompanySeq
		   AND LEFT(A.BillDate,6) BETWEEN @StdMonthFr AND @StdMonthTo 
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit  )    --����ι� ��ȸ ���� �߰� 20150128 Ȳ����
           AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq  )    --���μ���ȸ ���� �߰� 20150128 Ȳ����
           AND (@EmpSeq  = 0 OR A.EmpSeq  = @EmpSeq   )    --��������� ��ȸ ���� �߰� 20150128 Ȳ����
           AND (@CustSeq  = 0 OR A.CustSeq  = @CustSeq   )    --��������� ��ȸ ���� �߰� 20150128 Ȳ����
            
		 ORDER BY A.BillSeq
		 select a.StdNo,
				a.StdDate,
				a.CustSeq,
				a.CustName,
				a.CustNo,
				a.EmpSeq,
				a.EmpName,
				a.EmpNo,
				a.DeptNameOri,
				a.StdSeq,
				a.SalesBizSeq,
				a.BizUnit,
				a.BizUnitName,
				i.CurAmt + i.CurVAT  as StdAmt,
				i.PJTSeq,
				(select PJTName  from _TPJTProject where companyseq = @CompanySeq and pjtseq = i.PJTSeq ) as PJTName,
				ItemSeq,
				( select ItemNo  from _TDAItem where CompanySeq = @CompanySeq and ItemSeq = i.ItemSeq ) as ItemName,
				a.BizNo,
				a.PersonId,
				(select ChargeEmpSeq from _TPJTProject where companyseq = @CompanySeq and PJTSeq = i.PJTSeq ) as PJTEmpSeq,
				(select  empname from _TDAEmp where companyseq = @CompanySeq and EmpSeq = (select ChargeEmpSeq from _TPJTProject where companyseq = @CompanySeq and PJTSeq = i.PJTSeq ) ) as PJTEmpName
		   from #result as a
left outer join (		       
			  select si.billseq,si.PJTBillSerl, si.PJTSeq, si.ItemSeq, si.CurAmt, si.CurVAT
			   FROM _TSLBill AS m WITH(NOLOCK)
	           JOIN _TPJTSLBillItem          AS si WITH(NOLOCK)  ON si.CompanySeq = m.CompanySeq
														   		AND si.BillSeq   = m.BillSeq
               join #result as a on a.BillSeq = m.BillSeq 
              where m.CompanySeq = @CompanySeq
			    and m.BillID     in (1) 
				union all
             select m.billseq, si.SalesSerl, si.PJTSeq, si.ItemSeq, si.CurAmt, si.CurVAT
			   FROM _TSLBill AS m WITH(NOLOCK)
               join #result as a on a.BillSeq = m.BillSeq 
	           JOIN _TSLSalesBillRelation  AS br WITH(NOLOCK)  ON br.CompanySeq  = m.CompanySeq
															  AND br.BillSeq     = m.BillSeq
			   join (  select companyseq, SalesSeq, billseq
					     from _TSLSalesBillRelation
					    where companyseq = @CompanySeq
					   except
					   select companyseq, salesseq, billseq 
					     from hencom_VSLInvReplace
					    where companyseq = @CompanySeq) as nr on nr.CompanySeq = m.CompanySeq
					                                         and nr.SalesSeq = br.SalesSeq
															 and nr.BillSeq = br.BillSeq
				JOIN _TSLSalesItem          AS si WITH(NOLOCK)  ON si.CompanySeq = br.CompanySeq
														   				  AND si.SalesSeq   = br.SalesSeq
																		  AND si.SalesSerl  = br.SalesSerl
              where m.CompanySeq = @CompanySeq
			    and m.BillID     in (2,3)  
			union all
             select m.billseq, i.ReplaceRegSerl, i.PJTSeq, i.ItemSeq, i.CurAmt, i.CurVAT
	           FROM _TSLBill AS  m WITH(NOLOCK)
               join #result as a on a.BillSeq = m.BillSeq 
			   join hemcom_TSLBillReplaceRelation as r on r.CompanySeq = m.CompanySeq
													  and r.BillSeq = m.BillSeq
			   join hencom_TSLInvoiceReplaceItem as i on i.CompanySeq = m.CompanySeq
													 and i.ReplaceRegSeq = r.ReplaceRegSeq
													 and i.ReplaceRegSerl = r.ReplaceRegSerl
              where m.CompanySeq = @CompanySeq
			    and m.BillID     in (2,3)  
				) as i on i.billseq = a.billseq
 

	END
	
	IF @SalesBizSeq = 8062006	--�Ա�
	BEGIN     
		SELECT DISTINCT		   
			   A.ReceiptNo		AS StdNo,																									--��ȣ
			   A.ReceiptDate	AS StdDate,																								--����
			  A.CustSeq			AS CustSeq,	--�ŷ�ó�ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT CustName FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--�ŷ�ó
			   (SELECT CustNo FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--�ŷ�ó��ȣ
			   i.curamt * i.SMDrOrCr AS StdAmt,		   
			   A.EmpSeq	  AS EmpSeq,				--������ڵ� 2015.02.09 ��ҷ� �߰�
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--���������
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--���������
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,						--���μ�
			   A.ReceiptSeq AS StdSeq,																									--���ι�ȣ
			   @SalesBizSeq AS SalesBizSeq,																			--���������ڵ�
			   A.BizUnit AS BizUnit,	--����ι� 2015.02.09 ��ҷ� �߰�
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName,	--����ι��̸� 2015.02.09 ��ҷ� �߰�
			   i.PJTSeq,
			   (select PJTName  from _TPJTProject where companyseq = a.CompanySeq and pjtseq = i.PJTSeq ) as PJTName,
			   i.UMReceiptKind as ItemSeq,
			   ( select minorname  from _TDAuminor where CompanySeq = a.CompanySeq and MinorSeq = i.UMReceiptKind ) as ItemName,
			   case isnull(c.bizno,'') when '' then '' else  substring(c.BizNo,1,3) + '-' + substring(c.BizNo,4,2) + '-' + substring(c.BizNo,6,5) end as BizNo,
		       ISNULL(dbo._fnResidMask(dbo._FCOMDecrypt(c.PersonId, '_TDACust', 'PersonId', @CompanySeq)),'') AS PersonId,
			   i.ReceiptSerl   AS StdSerl,
				(select ChargeEmpSeq from _TPJTProject where companyseq = @CompanySeq and PJTSeq = i.PJTSeq ) as PJTEmpSeq,
				(select  empname from _TDAEmp where companyseq = @CompanySeq and EmpSeq = (select ChargeEmpSeq from _TPJTProject where companyseq = @CompanySeq and PJTSeq = i.PJTSeq ) ) as PJTEmpName
			
		  FROM _TSLReceipt AS A
		  join _TSLReceiptDesc as i on i.companyseq = a.companyseq
		                           and    i.receiptseq = a.receiptseq
left outer join _TDACust as c on c.CompanySeq = a.CompanySeq
                              and c.CustSeq = a.CustSeq
		 WHERE A.CompanySeq = @CompanySeq
		   AND LEFT(A.ReceiptDate,6) BETWEEN @StdMonthFr AND @StdMonthTo 
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit  )    --����ι� ��ȸ ���� �߰� 20150128 Ȳ����
           AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq  )    --���μ���ȸ ���� �߰� 20150128 Ȳ����
           AND (@EmpSeq  = 0 OR A.EmpSeq  = @EmpSeq   )    --��������� ��ȸ ���� �߰� 20150128 Ȳ����
           AND (@CustSeq  = 0 OR A.CustSeq  = @CustSeq   )    --��������� ��ȸ ���� �߰� 20150128 Ȳ����
            
		 ORDER BY A.ReceiptSeq
	END

RETURN
