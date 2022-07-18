IF OBJECT_ID('DTI_SSLBillBadListQuery') IS NOT NULL   
    DROP PROC DTI_SSLBillBadListQuery  
GO  
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
            @BadEndDate     NCHAR(8),  
            @BizUnit        INT,  
            @BizNo          NVARCHAR(100),  
            @CustSeqTemp    INT,  
            @FullName       NVARCHAR(100),  
            @BillDateFr     NVARCHAR(10),  
            @BillDateTo     NVARCHAR(10),  
            @DeptSeqTemp    INT,  
            @EmpSeqTemp     INT             
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
    
    SELECT  @BillNo         = ISNULL(BillNo, ''),  
            @BadDeptSeq     = ISNULL(BadDeptSeq, 0),  
            @BadEmpSeq      = ISNULL(BadEmpSeq, 0),  
            @CustSeq        = ISNULL(CustSeq, 0),  
            @BadBegDate     = ISNULL(BadBegDate, ''),  
            @BadEndDate     = ISNULL(BadEndDate, ''),  
            @BizUnit        = ISNULL(BizUnit, 0),  
            @BizNo          = ISNULL(BizNo, ''),  
            @CustSeqTemp    = ISNULL(CustSeqTemp , 0),  
            @FullName       = ISNULL(FullName, ''),  
            @BillDateFr     = ISNULL(BillDateFr, ''),  
            @BillDateTo     = ISNULL(BillDateTo, ''),  
            @DeptSeqTemp    = ISNULL(DeptSeqTemp, 0),  
            @EmpSeqTemp     = ISNULL(EmpSeqTemp, 0)  
           
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)        
      WITH (   
            BillNo         NVARCHAR(50),  
            BadDeptSeq     INT,  
            BadEmpSeq      INT,  
            CustSeq        INT,  
            BadBegDate     NCHAR(8),  
            BadEndDate     NCHAR(8),  
            BizUnit        INT,  
            BizNo          NVARCHAR(100),  
            CustSeqTemp    INT,  
            FullName       NVARCHAR(100),  
            BillDateFr     NVARCHAR(10),  
            BillDateTo     NVARCHAR(10),  
            DeptSeqTemp    INT,  
            EmpSeqTemp     INT             
            
           )        
    
    SELECT @BillDateTo = CASE WHEN ISNULL(@BillDateTo,'') = '' THEN '99991231' ELSE @BillDateTo END 
    
  SELECT  
        A.*,  
        (A.BadAmt - A.ReceiptAmt) AS NoReceiptAmt       -- ��ȸ���ݾ�  
    FROM   
    (  
        SELECT F.BizNo, -- ����ڹ�ȣ(û��ó) 
               D.DeptName      AS DeptNameTemp, -- ���ݰ�꼭 ���μ�  
               E.EmpName       AS EmpNameTemp,  -- ���ݰ�꼭 �����   
               A.BillSeq       AS BillSeq,      -- ���ݰ�꼭�ڵ�  
               B.BillNo        AS BillNo,       -- ���ݰ�꼭��ȣ  
               B.BillDate      AS BillDate,     -- ���ݰ�꼭����  
               A.BadDate       AS BadDate,      -- �ν�ä�ǹ߻���  
               A.RegEmpSeq     AS RegEmpSeq,    -- �۾����ڵ�  
               A.BadDeptSeq    AS BadDeptSeq,   -- �ν�ä�ǰ����μ��ڵ�  
               A.BadEmpSeq     AS BadEmpSeq,    -- �ν�ä�ǰ���������ڵ�     
               A.Note          AS Note,         -- �߻�����  
               B.CustSeq       AS CustSeq,      -- û��ó  
               ISNULL(A.BadAmt, 0) AS BadAmt,       -- �߻��ݾ�  
               (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.BadDeptSeq) AS BadDeptName,  -- �ν�ä�ǰ��������  
               (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.RegEmpSeq) AS RegEmpName,       -- �۾���  
               (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.BadEmpSeq) AS BadEmpName,       -- �ν�ä�ǰ��������  
               F.CustName, -- û��ó
               ISNULL((SELECT SUM(ReceiptAmt) FROM DTI_TSLBillBadReceipt WHERE CompanySeq = @CompanySeq AND BillSeq = A.BillSeq), 0) AS ReceiptAmt   -- ȸ���ݾ�  
               
          FROM DTI_TSLBillBad           AS A WITH(NOLOCK)      
          JOIN _TSLBill                 AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.BillSeq = A.BillSeq )  
          LEFT OUTER JOIN _TDABizUnit   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.BizUnit = B.BizUnit ) -- ����ι�  
          LEFT OUTER JOIN _TDADept      AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = B.DeptSeq ) -- ���ݰ�꼭 ���μ�  
          LEFT OUTER JOIN _TDAEmp       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = B.EmpSeq ) -- ���ݰ�꼭 �����  
          LEFT OUTER JOIN _TDACust      AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = B.CustSeq ) -- û��ó 
          
         WHERE A.CompanySeq = @CompanySeq    
           AND ( @BillNo = '' OR B.BillNo LIKE '%'+@BillNo+'%' )      
           AND ( @BadDeptSeq = 0 OR A.BadDeptSeq = @BadDeptSeq )  
           AND ( @BadEmpSeq = 0 OR A.BadEmpSeq = @BadEmpSeq )  
           AND ( @CustSeq = 0 OR B.CustSeq = @CustSeq )  
           AND ( @BadBegDate = '' OR A.BadDate >= @BadBegDate )  
           AND ( @BadEndDate = '' OR A.BadDate <= @BadEndDate )  
           AND B.BizUnit = @BizUnit 
           AND ( @BizNo = '' OR B.TaxUnit LIKE @BizNo+'%' ) 
           --AND ( @CustSeqTemp = 0 OR F.CustSeq = @CustSeqTemp) -- �ŷ�ó(��Ȯ��) 
           AND ( @FullName = '' OR F.FullName LIKE @FullName +'%' )  
           AND B.BillDate BETWEEN @BillDateFr AND @BillDateTo
           AND ( @DeptSeqTemp = 0 OR B.DeptSeq = @DeptSeqTemp )  
           AND ( @EmpSeqTemp = 0 OR B.EmpSeq = @EmpSeqTemp )  
        
    ) AS A  
    
    RETURN  
GO
