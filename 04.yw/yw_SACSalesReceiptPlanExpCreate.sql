
IF OBJECT_ID('yw_SACSalesReceiptPlanExpCreate') IS NOT NULL 
    DROP PROC yw_SACSalesReceiptPlanExpCreate
GO 

-- v2013.12.16 
      
-- ä�Ǽ��ݰ�ȹ(����)_yw(���ݰ�ȹ����) by����õ    
CREATE PROC yw_SACSalesReceiptPlanExpCreate      
    @xmlDocument    NVARCHAR(MAX),      
    @xmlFlags       INT = 0,      
    @ServiceSeq     INT = 0,       
    @WorkingTag     NVARCHAR(10)= '',      
    @CompanySeq     INT = 1,      
    @LanguageSeq    INT = 1,      
    @UserSeq        INT = 0,      
    @PgmSeq         INT = 0      
AS 
    
    DECLARE @docHandle  INT,      
            -- ��ȸ����       
            @PlanYM     NVARCHAR(6)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument       
          
    SELECT @PlanYM = ISNULL( PlanYM, '' ) 
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )           
      
      WITH (PlanYM NVARCHAR(6))        

      
    --select * from _TACSlip where SlipMstId = 'A0-S1-20131216-0019'  
    --select * from _TACSlipRow where SlipMstSeq = 1000404  
    --select * from _TACSlipOn where SlipSeq in (1001447,1001448)
    --select * from _TACSlipOff where OnSlipSeq in (1001447,1001448)
    --select * from _TACSlipRem where SlipSeq in (1001432) and RemSeq = 1017   
    --select * from _TDAAccountRem where RemSeq = 1017   
    --select * from _TDASMinor where MinorSeq = 4017002  
    --select * from _TDASMinor where MinorSeq = 4016002  
    --select * from _TDACust where CustNo = 'cust1-test'  
    --select * from _TSLCustSalesEmp where CustSeq = 42201  
    --select * from _TSLCustSalesEmpHist where CustSeq = 42201  
    --select * from _TDAAccount where CompanySeq = 1 and AccName like '�ܻ�����%'  
    
    SELECT A.EmpSeq, 
           A.CustSeq,  
           A.CurrSeq,   
           MAX(A.CustName) AS CustName, 
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM = LEFT(A.ReceiptDate,6) THEN A.OnAmt ELSE 0 END,0)) AS ReceiptAmt, 
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,1,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.OnAmt ELSE 0 END,0)) AS ReceiptAmt1, 
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,2,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.OnAmt ELSE 0 END,0)) AS ReceiptAmt2, 
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,3,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.OnAmt ELSE 0 END,0)) AS ReceiptAmt3, 
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,4,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.OnAmt ELSE 0 END,0)) AS ReceiptAmt4, 
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,5,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.OnAmt ELSE 0 END,0)) AS ReceiptAmt5, 
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,6,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.OnAmt ELSE 0 END,0)) AS ReceiptAmt6,
           
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM = LEFT(A.ReceiptDate,6) THEN A.OnForAmt ELSE 0 END,0)) AS ReceiptDomAmt, 
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,1,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.OnForAmt ELSE 0 END,0)) AS ReceiptDomAmt1, 
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,2,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.OnForAmt ELSE 0 END,0)) AS ReceiptDomAmt2, 
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,3,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.OnForAmt ELSE 0 END,0)) AS ReceiptDomAmt3, 
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,4,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.OnForAmt ELSE 0 END,0)) AS ReceiptDomAmt4, 
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,5,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.OnForAmt ELSE 0 END,0)) AS ReceiptDomAmt5, 
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,6,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.OnForAmt ELSE 0 END,0)) AS ReceiptDomAmt6, 
           
           SUM(ISNULL(CASE WHEN A.SMCustStatus <> 2004001 THEN A.OnAmt ELSE 0 END,0)) AS BadBondAmt, -- �ҷ�ä��
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM > LEFT(A.ReceiptDate,6) THEN A.OnAmt ELSE 0 END,0)) AS LongBondAmt, -- ���ä��
           SUM(ISNULL(CASE WHEN A.SMCustStatus <> 2004001 THEN A.OnForAmt ELSE 0 END,0)) AS BadBondDomAmt, -- �ҷ�ä��(��ȭ)
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM > LEFT(A.ReceiptDate,6) THEN A.OnForAmt ELSE 0 END,0)) AS LongBondDomAmt -- ���ä��(��ȭ)
    
      INTO #TEMP   
      FROM (SELECT ISNULL(ISNULL(D.EmpSeq,E.EmpSeq),0) AS EmpSeq, -- ����������ڵ�  
                   C.CustName,   
                   A.RemValSeq AS CustSeq, -- �ŷ�ó�ڵ�  
                   C.SMCustStatus, -- �ŷ�ó����, select * from _TDASMinor where MajorSeq = 2004  
                   B.AccDate, -- ��������   
                   I.ReceiptDate, -- ���ݿ����� 
                   I.SMCondStd, -- ȸ������   
                   A.CurrSeq, -- ��ȭ   
                   A.OnAmt - ISNULL(J.OffAmt,0) AS OnAmt,  
                   A.OnForAmt - ISNULL(J.OffForAmt,0) AS OnForAmt, 
                   I.SMReceiptKind
                     
              FROM _TACSlipOn             AS A WITH(NOLOCK)   
              OUTER APPLY (SELECT SUM(ISNULL(J1.OffAmt,0)) AS OffAmt,   
                                  SUM(ISNULL(J1.OffForAmt,0)) AS OffForAmt   
                                   
                            FROM _TACSlipOff AS J1 WITH(NOLOCK)  
                           WHERE J1.CompanySeq = @CompanySeq   
                             AND J1.OnSlipSeq = A.SlipSeq   
                           GROUP BY J1.OnSlipSeq   
                         ) AS J   
              JOIN _TACSlipRow            AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq 
                                                             AND B.SlipSeq = A.SlipSeq 
                                                             AND B.AccSeq IN (SELECT A.ValueSeq 
                                                                                FROM _TDAUMinorValue AS A 
                                                                               WHERE A.CompanySeq = @CompanySeq 
                                                                                 AND A.MinorSeq = 1008968003 AND A.Serl = 1000001
                                                                             ) 
                                                               ) -- ��ȭ�ܻ����� 
              JOIN _TDACust               AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.RemValSeq )  
              LEFT OUTER JOIN _TSLCustSalesEmp      AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.RemValSeq AND D.SDate <= B.AccDate )  
              LEFT OUTER JOIN _TSLCustSalesEmpHist  AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = A.RemValSeq AND B.AccDate BETWEEN E.SDate AND E.EDate )  
              OUTER APPLY (SELECT TOP 1 --I2.ReceiptMonth, I2.ReceiptDate,  
                                  I1.SMCondStd, 
                                  I2.SMReceiptKind, 
                                  (CASE WHEN I2.SMReceiptKind = 4010002 THEN LEFT(CONVERT(NVARCHAR(8),DATEADD(DAY,I2.NotExpDays,B.AccDate),112),6)
                                        ELSE CONVERT(NVARCHAR(6),DATEADD(MONTH,I2.ReceiptMonth,B.AccDate),112) 
                                        END   
                                  ) AS ReceiptDate  
                             FROM _TDACustSalesReceiptCond AS I1 WITH(NOLOCK) -- select * from _TDASMinor where MinorSeq in (8018002,8016001)  
                             JOIN _TDACustSalesReceiptStd  AS I2 WITH(NOLOCK) ON ( I2.CompanySeq = @CompanySeq AND I2.CondSeq = I1.CondSeq )  
                            WHERE I1.CompanySeq = @CompanySeq   
                              AND I1.CustSeq = C.CustSeq  
                            ORDER BY I2.CondSerl   
                          ) AS I   
                
             WHERE A.CompanySeq = @CompanySeq   
               AND A.RemSeq = 1017 -- �����׸�(�ŷ�ó)   
               AND A.OnAmt <> ISNULL(J.OffAmt,0)   
           ) AS A   
     GROUP BY A.EmpSeq, A.CustSeq, A.CurrSeq 
    HAVING SUM(ISNULL(CASE WHEN A.SMCustStatus <> 2004001 THEN A.OnAmt ELSE 0 END,0)) <> 0   
        OR SUM(ISNULL(CASE WHEN A.SMCustStatus <> 2004001 THEN A.OnForAmt ELSE 0 END,0)) <> 0   
        OR SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM > LEFT(A.ReceiptDate,6) THEN A.OnAmt ELSE 0 END,0)) <> 0   
        OR SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM > LEFT(A.ReceiptDate,6) THEN A.OnForAmt ELSE 0 END,0)) <> 0  
        OR SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM <= LEFT(A.ReceiptDate,6) THEN A.OnAmt ELSE 0 END,0)) <> 0   
        OR SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM <= LEFT(A.ReceiptDate,6) THEN A.OnForAmt ELSE 0 END,0)) <> 0   
        
    
    SELECT G.WkDeptName AS DeptName, -- �μ�  
           G.WkDeptSeq AS DeptSeq, 
           A.CustName, -- �ŷ�ó  
           A.CustSeq, -- �ŷ�ó�ڵ� 
           A.CurrSeq, -- ��ȭ�ڵ� 
           C.CurrName, -- ��ȭ
           
           --��ȭ
           A.ReceiptAmt,
           A.ReceiptAmt1,
           A.ReceiptAmt2,
           A.ReceiptAmt3,
           A.ReceiptAmt4,
           A.ReceiptAmt5,
           A.ReceiptAmt6, 
           A.BadBondAmt, 
           A.LongBondAmt, 
           A.ReceiptAmt + A.ReceiptAmt1 + A.ReceiptAmt2 + A.ReceiptAmt3 + A.ReceiptAmt4 + 
           A.ReceiptAmt5 + A.ReceiptAmt6 + A.BadBondAmt + A.LongBondAmt AS SumAmt,  
           
           -- ��ȭ
           A.ReceiptDomAmt,
           A.ReceiptDomAmt1,
           A.ReceiptDomAmt2,
           A.ReceiptDomAmt3,
           A.ReceiptDomAmt4,
           A.ReceiptDomAmt5,
           A.ReceiptDomAmt6, 
           A.BadBondDomAmt, 
           A.LongBondDomAmt, 
           A.ReceiptDomAmt + A.ReceiptDomAmt1 + A.ReceiptDomAmt2 + A.ReceiptDomAmt3 + A.ReceiptDomAmt4 + 
           A.ReceiptDomAmt5 + A.ReceiptDomAmt6 + A.BadBondDomAmt + A.LongBondDomAmt AS SumDomAmt
    
      FROM #TEMP AS A   
      LEFT OUTER JOIN dbo._fnAdmEmpOrd(@CompanySeq,'')  AS G              ON ( G.EmpSeq = A.EmpSeq ) -- dbo._fnAdmEmpOrd(1,'')  
      LEFT OUTER JOIN _TDACurr                          AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CurrSeq = A.CurrSeq ) 
     ORDER BY DeptName, CustName, CurrSeq 
    RETURN   
GO
exec yw_SACSalesReceiptPlanExpCreate @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PlanYM>201312</PlanYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019921,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016812