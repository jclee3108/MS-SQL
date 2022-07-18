/************************************************************      
 ��  �� - ������-�ν�ä��ó��_DTI : ��Ȳ-��ȸ
 �ۼ��� - 20100519 : CREATEd by
 �ۼ��� - ������
 ************************************************************/      
 CREATE PROC dbo.DTI_SSLBillBadListQuery
     @xmlDocument    NVARCHAR(MAX) ,
     @xmlFlags       INT  = 0,
     @ServiceSeq     INT  = 0,
     @WorkingTag     NVARCHAR(10)= '',
     @CompanySeq     INT  = 1,
     @LanguageSeq    INT  = 1,
     @UserSeq        INT  = 0,
     @PgmSeq         INT  = 0
  AS
      DECLARE @docHandle      INT,
             @BillNo         NVARCHAR(50),
             @BadDeptSeq     INT,
             @BadEmpSeq      INT,
             @CustSeq        INT,
             @BadBegDate     NCHAR(8),
             @BadEndDate     NCHAR(8)
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
      SELECT  @BillNo         = ISNULL(BillNo, ''),
             @BadDeptSeq     = ISNULL(BadDeptSeq, 0),
             @BadEmpSeq      = ISNULL(BadEmpSeq, 0),
             @CustSeq        = ISNULL(CustSeq, 0),
             @BadBegDate     = ISNULL(BadBegDate, ''),
             @BadEndDate     = ISNULL(BadEndDate, '')
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)      
       WITH ( 
             BillNo         NVARCHAR(50),
             BadDeptSeq     INT,
             BadEmpSeq      INT,
             CustSeq        INT,
             BadBegDate     NCHAR(8),
             BadEndDate     NCHAR(8)     
           )      
      SELECT
         A.*,
         (A.BadAmt - A.ReceiptAmt) AS NoReceiptAmt       -- ��ȸ���ݾ�
     FROM 
     (
         SELECT  A.BillSeq       AS BillSeq,      -- ���ݰ�꼭�ڵ�
                 B.BillNo        AS BillNo,       -- ���ݰ�꼭��ȣ
                 B.BillDate      AS BillDate,     -- ���ݰ�꼭����
                 A.BadDate       AS BadDate,      -- �ν�ä�ǹ߻���
                 A.RegEmpSeq     AS RegEmpSeq,    -- �۾����ڵ�
                 A.BadDeptSeq    AS BadDeptSeq,   -- �ν�ä�ǰ����μ��ڵ�
                 A.BadEmpSeq     AS BadEmpSeq,    -- �ν�ä�ǰ���������ڵ�   
                 A.Note          AS Note,         -- �߻�����
                 B.CustSeq       AS CustSeq,      -- û��ó
                 ISNULL(A.BadAmt, 0)        AS BadAmt,       -- �߻��ݾ�
                 (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.BadDeptSeq) AS BadDeptName,  -- �ν�ä�ǰ��������
                 (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.RegEmpSeq) AS RegEmpName,       -- �۾���
                 (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.BadEmpSeq) AS BadEmpName,       -- �ν�ä�ǰ��������
                 (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = B.CustSeq) AS CustName,        -- û��ó
                 ISNULL((SELECT SUM(ReceiptAmt) FROM DTI_TSLBillBadReceipt WHERE CompanySeq = @CompanySeq AND BillSeq = A.BillSeq), 0) AS ReceiptAmt   -- ȸ���ݾ�
           FROM DTI_TSLBillBad AS A WITH (NOLOCK)    
             INNER JOIN _TSLBill AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.BillSeq = A.BillSeq
          WHERE A.CompanySeq = @CompanySeq  
            AND (@BillNo = '' OR B.BillNo like '%' + @BillNo + '%')    
            AND (@BadDeptSeq = 0 OR A.BadDeptSeq = @BadDeptSeq)
            AND (@BadEmpSeq = 0 OR A.BadEmpSeq = @BadEmpSeq)
            AND (@CustSeq = 0 OR B.CustSeq = @CustSeq)
            AND (@BadBegDate = '' OR A.BadDate >= @BadBegDate)
            AND (@BadEndDate = '' OR A.BadDate <= @BadEndDate)
     ) AS A
  
 RETURN