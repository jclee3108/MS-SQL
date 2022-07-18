
IF OBJECT_ID('KPX_fnSLReceiptPlanDom') IS NOT NULL
    DROP FUNCTION KPX_fnSLReceiptPlanDom
GO

-- v2014.12.19 

-- �ŷ�ó�����ݿ�����ȹ_KPX �����Լ� by����õ 
CREATE FUNCTION KPX_fnSLReceiptPlanDom  
(  
    @CompanySeq INT,  
    @CustSeq    INT,  
    @SMLocalExp INT  -- 8918001 : ����, 8918002 : ���� (select * from _TDASMinor where MajorSeq = 8918)  
)  
RETURNS @SalesReceiptPlan TABLE  
(  
    --BillSeq         INT,  
    --EmpSeq          INT,  
    BizUnit         INT,  
    CustName        NVARCHAR(100),  
    CustNo          NVARCHAR(100),  
    CustSeq         INT,  
    SMCustStatus    INT,  
    BillDate        NCHAR(8),  
    ReceiptDate     NCHAR(8),  
    SMCondStd       INT,  
    SMReceiptKind   INT,  
    CurrSeq         INT,  
    CurAmt          DECIMAL(19,5),  
    DomAmt          DECIMAL(19,5),  
    RemCurAmt       DECIMAL(19,5),  
    RemDomAmt       DECIMAL(19,5)  
)  
  
AS  
BEGIN  
  
    INSERT @SalesReceiptPlan  
    SELECT 
    --MAX(ISNULL(ISNULL(G.EmpSeq, H.EmpSeq), 0))   AS EmpSeq,  -- ����������ڵ�  
           --MAX(ISNULL(ISNULL(G.DeptSeq, H.DeptSeq), 0)) AS DeptSeq, -- �������μ��ڵ� 
           A.BizUnit AS BizUnit, 
           MAX(F.CustName)           AS CustName,     -- �ŷ�ó�� 
           MAX(F.CustNo)             AS CustNo, -- �ŷ�ó��ȣ 
           A.CustSeq                 AS CustSeq,      -- �ŷ�ó�ڵ�  
           MAX(F.SMCustStatus)       AS SMCustStatus, -- �ŷ�ó����  
           A.BillDate                AS BillDate,     -- ���ݰ�꼭����  
           (CASE WHEN I.SMReceiptPoint = 8122001  
                 THEN (CASE WHEN I.ReceiptDate1 > I.ReceiptDate2   
                            THEN I.ReceiptDate2  
                            ELSE I.ReceiptDate1   
                       END)  
                 ELSE ReceiptDate3  
           END)                      AS ReceiptDate,  -- ���ݿ�����  
           MAX(I.SMCondStd)          AS SMCondStd,    -- ȸ������  
           MAX(I.SMReceiptKind)      AS SMReceiptKind,-- �Աݱ���  
           A.CurrSeq                 AS CurrSeq,      -- ��ȭ  
           ISNULL(SUM(C.CurAmt), 0)  AS CurAmt,       -- �Ǹűݾ�  
           ISNULL(SUM(C.DomAmt), 0)  AS DomAmt,       -- ��ȭ�Ǹűݾ�   
           ISNULL(SUM(C.CurAmt), 0) - (ISNULL(SUM(D.CurAmt), 0) + ISNULL(SUM(E.CurAmt), 0)) AS RemCurAmt, -- �̼��ܾ�  
           ISNULL(SUM(C.DomAmt), 0) - (ISNULL(SUM(D.DomAmt), 0) + ISNULL(SUM(E.DomAmt), 0)) AS RemDomAmt  -- ��ȭ�̼��ܾ�  
      FROM _TSLBill AS A WITH(NOLOCK)  
           CROSS APPLY (-- ���ݰ�꼭 ����ݾװ�  
                        SELECT X.BillSeq, SUM(Y.CurAmt + Y.CurVAT) AS CurAmt, SUM(Y.DomAmt + Y.DomVAT) AS DomAmt  
                          FROM _TSLSalesBillRelation AS X WITH(NOLOCK)  
                               JOIN _TSLSalesItem    AS Y WITH(NOLOCK) ON X.CompanySeq = Y.CompanySeq  
                                                                      AND X.SalesSeq   = Y.SalesSeq  
                                                                      AND X.SalesSerl  = Y.SalesSerl  
                         WHERE X.CompanySeq = @CompanySeq  
                           AND X.BillSeq    = A.BillSeq  
                         GROUP BY X.BillSeq  
                       ) AS C  
           OUTER APPLY (-- ���ݰ�꼭 �Աݾװ�  
                        SELECT X.BillSeq, SUM(X.CurAmt) AS CurAmt, SUM(X.DomAmt) AS DomAmt  
                          FROM _TSLReceiptBill AS X WITH(NOLOCK)  
                         WHERE X.CompanySeq = @CompanySeq  
                           AND X.BillSeq    = A.BillSeq  
                         GROUP BY X.BillSeq  
                       ) AS D  
           OUTER APPLY (-- ���ݰ�꼭 �����ݴ�ü�ݾװ�  
                        SELECT X.BillSeq, SUM(X.CurAmt) AS CurAmt, SUM(X.DomAmt) AS DomAmt  
                          FROM _TSLPreReceiptBill AS X WITH(NOLOCK)  
                         WHERE X.CompanySeq = @CompanySeq  
                           AND X.BillSeq    = A.BillSeq  
                         GROUP BY X.BillSeq  
                       ) AS E  
           OUTER APPLY (-- û��ó����ȸ�����ǿ� ���� �ڱݿ����� ���  
                        SELECT TOP 1   
                               I1.CustSeq,  
                               I1.SMCondStd,  
                               I1.SMReceiptPoint,  
                               I2.SMReceiptKind,  
                               (CONVERT(NVARCHAR(8), DATEADD(DAY, -1, DATEADD(MONTH, 1, CONVERT(NVARCHAR(6), DATEADD(MONTH, I2.ReceiptMonth, A.BillDate), 112) + '01')), 112) ) AS ReceiptDate1, -- ȸ������ ���� ���� ��� (ȸ������ ���� ���� �����ϱ� ���� �۾�)  
                               (CONVERT(NVARCHAR(6), DATEADD(MONTH, I2.ReceiptMonth, A.BillDate), 112)  
                                  + (CASE WHEN I2.ReceiptDate < 10 THEN '0'+ CONVERT(NVARCHAR(2), I2.ReceiptDate)  
                                          ELSE CONVERT(NVARCHAR(2), I2.ReceiptDate)  
                                          END  
                                    )  
                               ) AS ReceiptDate2, -- ȸ���� + ȸ���Ϸ� ���  
                               CONVERT(NVARCHAR(8),DATEADD(DAY, I1.Term, A.BillDate), 112) AS ReceiptDate3 -- ȸ���Ⱓ�� ���� ����  
                          FROM _TDACustSalesReceiptCond AS I1 WITH(NOLOCK)  
                               JOIN _TDACustSalesReceiptStd  AS I2 WITH(NOLOCK) ON ( I1.CompanySeq = I2.CompanySeq AND I1.CondSeq = I2.CondSeq )  
                         WHERE I1.CompanySeq = @CompanySeq  
                           AND I1.CustSeq    = A.CustSeq  
                         ORDER BY I2.CondSerl  
                       ) AS I  
                      JOIN _TDACust              AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = A.CustSeq )  
           --LEFT OUTER JOIN _TSLCustSalesEmp      AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.CustSeq = A.CustSeq AND G.SDate <= A.BillDate )  
           --LEFT OUTER JOIN _TSLCustSalesEmpHist  AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.CustSeq = A.CustSeq AND A.BillDate BETWEEN H.SDate AND H.EDate )  
     WHERE A.CompanySeq = @CompanySeq  
       AND ISNULL(C.DomAmt, 0) > (ISNULL(D.DomAmt, 0) + ISNULL(E.DomAmt, 0))  
       AND (@SMLocalExp = 0 OR (@SMLocalExp = 8918001 AND EXISTS (SELECT TOP 1 1   
                                                                    FROM _TDASMinorValue   
                                                                   WHERE CompanySeq = @CompanySeq   
                                                                     AND MinorSeq   = A.SMExpKind   
                                                                     AND Serl       = 1001 -- ����  
                                                                     AND ValueText  = '1'))  
                            OR (@SMLocalExp = 8918002 AND EXISTS (SELECT TOP 1 1   
                                                                    FROM _TDASMinorValue   
                                                                   WHERE CompanySeq = @CompanySeq   
                                                                     AND MinorSeq   = A.SMExpKind   
                                                                     AND Serl       = 1002 -- ����  
                                                                     AND ValueText  = '1')) )  
     GROUP BY A.CustSeq,   
              A.BillDate, 
              A.BizUnit,  
              (CASE WHEN I.SMReceiptPoint = 8122001  
                    THEN (CASE WHEN I.ReceiptDate1 > I.ReceiptDate2   
                               THEN I.ReceiptDate2  
                               ELSE I.ReceiptDate1   
                          END)  
                    ELSE ReceiptDate3  
              END),   
              A.CurrSeq  
  
    RETURN  
END  