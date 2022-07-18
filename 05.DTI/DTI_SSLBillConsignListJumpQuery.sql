
IF OBJECT_ID('DTI_SSLBillConsignListJumpQuery') IS NOT NULL 
    DROP PROC DTI_SSLBillConsignListJumpQuery
GO 

-- V2014.05.21 

-- ����Ź���ݰ�꼭��ȸ_DTI(������ȸ) by����õ
CREATE PROC DTI_SSLBillConsignListJumpQuery                
    @xmlDocument   NVARCHAR(MAX) ,            
    @xmlFlags      INT = 0,            
    @ServiceSeq    INT = 0,            
    @WorkingTag    NVARCHAR(10)= '',                  
    @CompanySeq    INT = 1,            
    @LanguageSeq   INT = 1,            
    @UserSeq       INT = 0,            
    @PgmSeq        INT = 0       
AS 
    
    CREATE TABLE #DTI_TSLBillConsign (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TSLBillConsign'     
    IF @@ERROR <> 0 RETURN  

    CREATE TABLE #TSIAFebIO (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TSIAFebIO'     
    IF @@ERROR <> 0 RETURN  
    
    DECLARE @UMReceiptKind      INT, 
            @ReceiptKindName    NVARCHAR(100), 
            @SMDrOrCr           INT, 
            @AccSeq             INT, 
            @AccName            NVARCHAR(100) 
            
    -- ������ȸ            
    SELECT A.BillSeq        AS BillSeq,--��꼭���ι�ȣ  
           A.BillNo         AS BillNo,--��꼭��ȣ  
           A.BillDate       AS BillDate,--��꼭����  
           B.CurAmt         AS BillCurAmt,--���ݰ�꼭�ݾ�  
           B.DomAmt         AS BillDomAmt,--���ݰ�꼭��ȭ�ݾ�  
           ISNULL(F.ReceiptCurAmt,0) AS PreBillCurAmt,
           ISNULL(F.ReceiptDomAmt,0) AS PreBillDomAmt,
           B.CurAmt - ISNULL(F.ReceiptCurAmt,0) AS CurAmt,--��ȸ�Աݾ�  
           B.DomAmt - ISNULL(F.ReceiptDomAmt,0) AS DomAmt, --��ȸ��ȭ�Աݾ�  
           A.RemSeq, -- ��ȭ���ڵ� 
           C.RemValueName, -- ��ȭ�� 
           A.MyCustSeq, 
           A.CustSeq, 
           D.CustName AS MyCustName, 
           E.CustName AS CustName, 
           1 AS ExRate, 
           
           G.DeptName, 
           A.DeptSeq, 
           H.EmpName, 
           A.EmpSeq 
           
       FROM #DTI_TSLBillConsign AS Z
       JOIN DTI_TSLBillConsign  AS A WITH(NOLOCK) ON  ( A.CompanySeq = @CompanySeq AND A.BillSeq = Z.BillSeq ) 
       JOIN (SELECT A.BillSeq, SUM(A.Amt + A.VAT) AS CurAmt, SUM(A.Amt + A.VAT) AS DomAmt  
               FROM DTI_TSLBillConsign AS A WITH(NOLOCK)   
               JOIN #DTI_TSLBillConsign AS B ON A.BillSeq = B.BillSeq  
              WHERE A.CompanySeq = @CompanySeq  
              GROUP BY A.BillSeq
            ) AS B ON A.BillSeq = B.BillSeq  
      LEFT OUTER JOIN (SELECT A.BillSeq, SUM(A.CurAmt) AS ReceiptCurAmt, SUM(A.DomAmt) AS ReceiptDomAmt  
                         FROM DTI_TSLReceiptConsignBill AS A WITH(NOLOCK)   
                         JOIN #DTI_TSLBillConsign AS B ON A.BillSeq = B.BillSeq  
                        WHERE A.CompanySeq = @CompanySeq  
                        GROUP BY A.BillSeq
                      ) AS F ON A.BillSeq = F.BillSeq  
      LEFT OUTER JOIN _TDAAccountRemValue AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.RemValueSerl = A.RemSeq )   
      LEFT OUTER JOIN _TDACust            AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.MyCustSeq ) 
      LEFT OUTER JOIN _TDACust            AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDADept            AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp             AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.EmpSeq = A.EmpSeq ) 
     WHERE A.CompanySeq = @CompanySeq      
    
    SELECT @AccSeq = ISNULL(EnvValue, 0)
      FROM _TCOMEnv WITH(NOLOCK)
     WHERE CompanySeq = @CompanySeq
       AND EnvSeq = 8921
    
    --  �������� ���ؼ� ���°� �ߺ��Ǵ� ��� �߻�
    --  �����ڵ尡 ���� �����ɷ� SELECT�Ѵ�. 
    
    CREATE Table #BankAccNo_Tmp    
    (    
            CompanySeq   INT,    
            BankAccSeq   INT,    
            BankAccNo    NVARCHAR(100),    
            BankSeq      INT,    
            AccSeq       INT,    
            FBankAccSeq  INT    
    ) 
    INSERT INTO #BankAccNo_Tmp( CompanySeq, BankAccSeq, BankAccNo , BankSeq   , AccSeq    , FBankAccSeq )    
    SELECT A.CompanySeq,  -- �����ڵ�    
           A.BankAccSeq,  -- �����ڵ�    
           A.BankAccNo,   -- ���¹�ȣ    
           A.BankSeq,     -- �������(424%)    
           A.AccSeq ,     -- �����ڵ�    
           0              -- �����ݰ����ڵ�    
      FROM _TDABankAcc AS a WITH(NOLOCK)    
      JOIN ( SELECT CompanySeq, BankAccSeq, MIN(AccSeq) AS AccSeq    
               FROM _TDABankAcc WITH(NOLOCK)    
              GROUP BY CompanySeq, BankAccSeq    
           ) AS b  ON A.CompanySeq = B.CompanySeq    
                  AND A.BankAccSeq = B.BankAccSeq    
                  AND A.AccSeq = B.AccSeq    
     WHERE A.CompanySeq = @CompanySeq    
       AND A.SMBankAccKind = 4028001 -- ����    
    
    UPDATE #BankAccNo_Tmp    
       SET FBankAccSeq = B.BankAccSeq    
      FROM #BankAccNo_Tmp AS A    
            JOIN _TDABankAcc AS B ON A.CompanySeq = B.CompanySeq    
                                 AND A.BankAccSeq = B.BankAccSeq    
     WHERE A.CompanySeq = @CompanySeq    
        AND B.AccSeq = @AccSeq 
    
    --------------------------------------------------------------------------------
    -- ����,�뺯����
    -------------------------------------------------------------------------------- 
    
    DECLARE @UMReceipt TABLE
    (  
        UMReceiptKind   INT,
        ReceiptKindName NVARCHAR(200),
        ExpKind         INT
    )
    
    -- �Ա��뺸���� ��ȭ������ �����ؾ� �Ա����� �����ϹǷ� �뺸���� �ϳ��� ��ȭ�ڵ常 ������ �־ �ȴ�.
    INSERT INTO @UMReceipt
    SELECT ISNULL(A.MinorSeq,0), ISNULL(A.MinorName,''), CASE WHEN C.ValueText = '1'  AND D.ValueText <> '1' THEN 1    
                                                              WHEN C.ValueText <> '1' AND D.ValueText = '1'  THEN 2
                                                              WHEN C.ValueText = '1'  AND D.ValueText = '1'  THEN 3 
                                                              END  -- 1: ����, 2: ����, 3: ���û��
        FROM _TDAUMinor AS A WITH(NOLOCK)  
        LEFT OUTER JOIN  _TDAUMinorValue AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                           AND A.MinorSeq   = B.MinorSeq
                                                           AND B.Serl       = 1003
        LEFT OUTER JOIN  _TDAUMinorValue AS C WITH (NOLOCK) ON B.CompanySeq = C.CompanySeq
                                                           AND B.MinorSeq   = C.MinorSeq
                                                           AND C.Serl       = 1005       -- ����
        LEFT OUTER JOIN  _TDAUMinorValue AS D WITH (NOLOCK) ON B.CompanySeq = D.CompanySeq
                                                           AND B.MinorSeq   = D.MinorSeq
                                                           AND D.Serl       = 1006       -- ����                                                                                                                            
       WHERE A.MajorSeq = 8017                                                               
         AND A.CompanySeq = @CompanySeq
         AND B.ValueText = '1' -- ������
      -- ���û���ϰ�� �켱����
     IF EXISTS (SELECT 1 FROM @UMReceipt WHERE ExpKind = 3)
     BEGIN
         SELECT TOP 1 @UMReceiptKind = UMReceiptKind ,
                      @ReceiptKindName = ReceiptKindName
           FROM @UMReceipt WHERE ExpKind = 3
     END 
     ELSE
     BEGIN
        -- �Ա��뺸���� ������ ��Ʈ�ѿ� �����͸� ���������θ� �������ֱ⿡ ������ �þ�� �� ��� ���Ƿ� ù��°���� ���ϵ����Ѵ�.
        SELECT TOP 1 @UMReceiptKind     = UMReceiptKind ,
                     @ReceiptKindName   = ReceiptKindName
          FROM @UMReceipt WHERE ExpKind = 1
    END
    
    SELECT @SMDrOrCr = ValueSeq 
      FROM _TDAUMinorValue 
     WHERE CompanySeq = @CompanySeq  
       AND MinorSeq   = @UMReceiptKind 
       AND Serl       = 1002
    SELECT @AccSeq = ValueSeq 
      FROM _TDAUMinorValue 
     WHERE CompanySeq = @CompanySeq  
       AND MinorSeq   = @UMReceiptKind 
       AND Serl       = 1001
    SELECT @AccName = ISNULL(AccName,'')
      FROM _TDAAccount WITH (NOLOCK)
     WHERE CompanySeq = @CompanySeq  
       AND AccSeq     = @AccSeq 
    
    -- ������ȸ
    SELECT A.ACCT_TXDAY AS NotifyDate, -- �Ա��� 
           D.BankName AS BankName, -- ������� 
           C.BankSeq, 
           C.BankAccNo AS BankAccNo, -- �Աݰ��� 
           C.BankAccSeq, 
           E.CustName AS CustName,  
           E.CustSeq AS CustSeq, 
           ((K.DrAmt - K.CrAmt) * L.SMDrOrCr) - ISNULL(J.OffAmt,0) AS CurAmt, 
           ((K.DrAmt - K.CrAmt) * L.SMDrOrCr) - ISNULL(J.OffAmt,0) AS DomAmt, 
           @SMDrOrCr AS SMDrOrCr, 
           ISNULL((SELECT MinorName FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MajorSeq = 4001 AND MinorValue = ISNULL(@SMDrOrCr, 0)),'') AS DrOrCrName,
           
           ISNULL(I.SlipID,A.ERPKey) AS SlipID, -- ��ǥ��ȣ    
           B.MinorSeq AS UMReceiptKind, 
           B.MinorName AS ReceiptKindName, 
           A.SlipSeq, 
           
           CASE WHEN ISNULL(@SMDrOrCr, 0) = 1 THEN @AccSeq ELSE 0 END AS AccSeqDr,
           CASE WHEN ISNULL(@SMDrOrCr, 0) = 1 THEN 0 ELSE @AccSeq END AS AccSeqCr,
           CASE WHEN ISNULL(@SMDrOrCr, 0) = 1 THEN @AccName ELSE '' END AS AccNameDr,
           CASE WHEN ISNULL(@SMDrOrCr, 0) = 1 THEN '' ELSE @AccName END AS AccNameCr
    
      FROM #TSIAFebIO AS Z 
                 JOIN _TSIAFebIO        AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.SlipSeq = Z.SlipSeq ) 
                 JOIN #BankAccNo_Tmp    AS C              ON ( REPLACE(A.ACCT_NO,'-','') = REPLACE(C.BankAccNo, '-', '') )
                 JOIN _TACSlipRow       AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.SlipSeq = A.SlipSeq ) 
                 JOIN _TACSlipCost      AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.SlipSeq = I.SlipSeq ) 
                 JOIN _TDAAccount       AS L WITH(NOLOCK) ON ( L.CompanySeq = @CompanySeq AND L.AccSeq = I.AccSeq ) 
      LEFT OUTER JOIN _TDACust          AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDABank          AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.BankSeq = C.BankSeq ) 
      OUTER APPLY (SELECT SUM(ISNULL(J1.OffAmt,0)) AS OffAmt
                      FROM _TACSlipOff AS J1 
                     WHERE J1.CompanySeq = @CompanySeq 
                       AND J1.OnSlipSeq = I.SlipSeq 
                     GROUP BY J1.OnSlipSeq
                   ) AS J 
      OUTER APPLY (SELECT TOP 1 Y.MinorSeq, Y.MinorName 
                     FROM _TDAUMinorValue AS X
                     JOIN _TDAUMinor      AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = X.MinorSeq ) 
                    WHERE X.CompanySeq = @CompanySeq 
                     AND X.MajorSeq= 8017 
                     AND X.Serl = 1001 
                     AND X.ValueSeq = I.AccSeq 
                  ) AS B 
      
     WHERE A.CompanySeq = @CompanySeq    
       AND I.AccSeq = 632 
       AND ((K.DrAmt - K.CrAmt) * L.SMDrOrCr) - ISNULL(J.OffAmt,0) <> 0
    ORDER BY A.Acct_No, A.AccT_TXDay, A.ACCT_TXDAY_SEQ  
    
    RETURN
GO
exec DTI_SSLBillConsignListJumpQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>5</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BillSeq>11</BillSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1022831,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1019192



--select * from _TDAUMinor where companyseq =1 and majorseq = 8017
--select * from _TDAUMinorValue where companyseq = 1 and majorseq = 8017 

