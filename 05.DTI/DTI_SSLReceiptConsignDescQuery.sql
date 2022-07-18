
IF OBJECT_ID('DTI_SSLReceiptConsignDescQuery') IS NOT NULL 
    DROP PROC DTI_SSLReceiptConsignDescQuery
GO 

-- v2014.05.21 

-- ����Ź�Ա��Է�_DTI(����Ź������ȸ) by����õ
 CREATE PROCEDURE DTI_SSLReceiptConsignDescQuery    
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
            @ReceiptNo    NCHAR(12)  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @ReceiptSeq = ReceiptSeq,   
           @ReceiptNo  = ReceiptNo  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)       
      WITH (ReceiptSeq INT, ReceiptNo NCHAR(12))    
    
    SELECT B.ReceiptSerl            AS ReceiptSerl,         --�Աݼ���  
           C.MinorName              AS ReceiptKindName,     --�Աݱ���  
           B.UMReceiptKind          AS UMReceiptKind,       --�Աݱ����ڵ�  
           D.MinorName              AS DrOrCrName,          --���뱸��  
           B.SMDrOrCr               AS SMDrOrCr,            --���뱸���ڵ�  
           ISNULL(B.CurAmt, 0)      AS CurAmt,              --�Աݾ�  
           ISNULL(B.DomAmt, 0)      AS DomAmt,              --��ȭ�Աݾ�  
           E.BankName               AS BankName,            --�Ա�����  
           B.BankSeq                AS BankSeq,             --�Ա������ڵ�  
           F.BankAccName            AS BankAccName,         --����  
           F.BankAccNo              AS BankAccNo,           --���¹�ȣ  
           B.BankAccSeq             AS BankAccSeq,          --�����ڵ�  
           B.Remark                 AS Remark,              --���  
           B.CustSeq                AS CustSeq, 
           I.CustName               AS CustName, 
           CASE WHEN ISNULL(H.ValueSeq,'1') = '1' THEN ISNULL(G.ValueSeq,0) ELSE 0 END AS AccSeqDr,  
           CASE WHEN ISNULL(H.ValueSeq,'1') = '1' THEN 0 ELSE ISNULL(G.ValueSeq,0) END AS AccSeqCr,  
           CASE WHEN ISNULL(H.ValueSeq,'1') = '1' THEN (SELECT AccName FROM _TDAAccount WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = ISNULL(G.ValueSeq,0)) ELSE '' END AS AccNameDr,  
           CASE WHEN ISNULL(H.ValueSeq,'1') = '1' THEN '' ELSE (SELECT AccName FROM _TDAAccount WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = ISNULL(G.ValueSeq,0)) END AS AccNameCr
   
      FROM DTI_TSLReceiptConsign                   AS A WITH(NOLOCK)  
                 JOIN DTI_TSLReceiptConsignDesc    AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ReceiptSeq = B.ReceiptSeq ) 
                 JOIN _TDAUMinor                   AS C WITH(NOLOCK) ON ( B.CompanySeq = C.CompanySeq AND B.UMReceiptKind = C.MinorSeq ) 
      LEFT OUTER JOIN _TDASMinor                   AS D WITH(NOLOCK) ON ( B.CompanySeq = D.CompanySeq AND D.MajorSeq = 4001 AND B.SMDrOrCr = D.MinorValue ) 
      LEFT OUTER JOIN _TDABank                     AS E WITH(NOLOCK) ON ( B.CompanySeq = E.CompanySeq AND B.BankSeq = E.BankSeq ) 
      LEFT OUTER JOIN _TDABankAcc                  AS F WITH(NOLOCK) ON ( B.CompanySeq = F.CompanySeq AND B.BankAccSeq = F.BankAccSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue              AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND B.UMReceiptKind = G.MinorSeq AND G.Serl = 1001 ) 
      LEFT OUTER JOIN _TDAUMinorValue              AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND B.UMReceiptKind = H.MinorSeq AND H.Serl = 1002 ) 
      LEFT OUTER JOIN _TDACust                     AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.CustSeq = B.CustSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND (A.ReceiptNo = @ReceiptNo OR A.ReceiptSeq = @ReceiptSeq)  
    
    RETURN
GO
exec DTI_SSLReceiptConsignDescQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ReceiptSeq>7</ReceiptSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1022863,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1019203