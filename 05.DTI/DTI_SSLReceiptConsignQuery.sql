
IF OBJECT_ID('DTI_SSLReceiptConsignQuery') IS NOT NULL 
    DROP PROC DTI_SSLReceiptConsignQuery
GO 

-- v2014.05.21 

-- ����Ź�Ա��Է�_DTI(����Ź��ȸ) by����õ
CREATE PROC DTI_SSLReceiptConsignQuery    
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,-- ���񽺵���Ѱ� Seq�� �Ѿ�´�.  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS 
    
    DECLARE @docHandle    INT,    
            @ReceiptSeq   INT,   
            @ReceiptNo    NCHAR(12),  
            @TotCurAmt    DECIMAL(19,5),  
            @TotDomAmt    DECIMAL(19,5)  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    -- Temp�� INSERT      
    
    SELECT @ReceiptSeq = ReceiptSeq,   
           @ReceiptNo  = ReceiptNo  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)       
      WITH (
            ReceiptSeq INT, 
            ReceiptNo NCHAR(12)
           )    
    
    SELECT @TotCurAmt = SUM(CurAmt * SMDrOrCr),  
           @TotDomAmt = SUM(DomAmt * SMDrOrCr)  
      FROM DTI_TSLReceiptConsignDesc  
     WHERE CompanySeq = @CompanySeq   
       AND ReceiptSeq = @ReceiptSeq  
  
    SELECT A.ReceiptSeq         AS ReceiptSeq,  
           E.CustName           AS CustName,        --�ŷ�ó  
           A.CustSeq            AS CustSeq,         --�ŷ�ó�ڵ�  
           A.ReceiptDate        AS ReceiptDate,     --�Ա���  
           A.ReceiptNo          AS ReceiptNo,       --�Աݹ�ȣ  
           D.EmpName            AS EmpName,         --�����  
           A.EmpSeq             AS EmpSeq,          --������ڵ�  
           C.DeptName           AS DeptName,        --�μ�  
           A.DeptSeq            AS DeptSeq,         --�μ��ڵ�  
           A.ExRate             AS ExRate,          --ȯ��  
           F.CurrName           AS CurrName,        --��ȭ  
           A.CurrSeq            AS CurrSeq,         --��ȭ�ڵ�  
           A.OppAccSeq          AS OppAccSeq   ,--��������׸�  
           ISNULL((SELECT AccName FROM _TDAAccount WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = A.OppAccSeq),'') AS OppAccName,--��������׸��ڵ�  
           ISNULL((SELECT SlipID FROM _TACSlipRow WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipSeq = A.SlipSeq), '') AS SlipID,          --��ǥ��ȣ  
           A.SlipSeq            AS SlipSeq,         --��ǥ�ڵ�  
           @TotCurAmt           AS TotCurAmt,--�Աݾװ�  
           @TotDomAmt           AS TotDomAmt,--�Աݾװ�(��ȭ)  
           0,--ó���װ�  
           0 --ó���װ�(��ȭ) 
      FROM DTI_TSLReceiptConsign    AS A WITH(NOLOCK)  
      LEFT OUTER JOIN _TDADept      AS C WITH(NOLOCK) ON ( A.CompanySeq = C.CompanySeq AND A.DeptSeq = C.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp       AS D WITH(NOLOCK) ON ( A.CompanySeq = D.CompanySeq AND A.EmpSeq = D.EmpSeq ) 
      LEFT OUTER JOIN _TDACust      AS E WITH(NOLOCK) ON ( A.CompanySeq = E.CompanySeq AND A.CustSeq = E.CustSeq ) 
      LEFT OUTER JOIN _TDACurr      AS F WITH(NOLOCK) ON ( A.CompanySeq = F.CompanySeq AND A.CurrSeq = F.CurrSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND (A.ReceiptSeq = @ReceiptSeq) 
    RETURN  