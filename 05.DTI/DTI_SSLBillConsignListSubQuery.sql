
IF OBJECT_ID('DTI_SSLBillConsignListSubQuery') IS NOT NULL 
    DROP PROC DTI_SSLBillConsignListSubQuery
GO 

-- v2014.05.20 

-- ����Ź���ݰ�꼭��ȸ_DTI (�Ա���ȸ) by����õ
CREATE PROC DTI_SSLBillConsignListSubQuery 
    @xmlDocument    NVARCHAR(MAX) , 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS        
    
    DECLARE @docHandle      INT, 
            @InDateFr       NCHAR(8), 
            @InDateTo       NCHAR(8), 
            @IsRemain       INT, 
            
            @AccSeq         INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @InDateFr = ISNULL(InDateFr, ''), 
           @InDateTo = ISNULL(InDateTo, ''), 
           @IsRemain = ISNULL(IsRemain, 0) 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)
      WITH (
            InDateFr    NCHAR(8), 
            InDateTo    NCHAR(8), 
            IsRemain    INT
           )
    
    IF @InDateTo = '' SELECT @InDateTo = '99991231'
    
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
    
    -- ������ȸ
    SELECT A.ACCT_TXDAY AS InDate, -- �Ա��� 
           D.BankName AS BankName, -- ������� 
           D.BankSeq AS BankSeq, 
           C.BankAccNo AS BankAccNo, -- �Աݰ��� 
           E.CustName AS CustName,  
           E.CustSeq AS CustSeq, 
           (K.DrAmt - K.CrAmt) * L.SMDrOrCr AS Amt, -- ��ǥ�ݾ�
           ((K.DrAmt - K.CrAmt) * L.SMDrOrCr) - ISNULL(J.OffAmt,0) AS RemainAmt, -- ��ǥ�ݾ� - �����ݾ�
           ISNULL(I.SlipID,A.ERPKey) AS SlipID, -- ��ǥ��ȣ    
           I.AccSeq, 
           L.AccName, 
           A.SlipSeq 
      INTO #Result 
      FROM _TSIAFebIO                   AS A  
                 JOIN #BankAccNo_Tmp    AS C WITH(NOLOCK) ON ( REPLACE(A.ACCT_NO,'-','') = REPLACE(C.BankAccNo, '-', '') )
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
     WHERE A.CompanySeq = @CompanySeq    
       AND (A.ACCT_TXDAY >= @InDateFr  OR @InDateFr = '')    
       AND (A.ACCT_TXDAY <= @InDateTo  OR @InDateTo = '')    
       AND (ISNULL(A.SlipSeq, 0) <> 0 OR  ISNULL(A.ERPKey,'') <> '') 
       AND I.AccSeq = 632 
    ORDER BY A.Acct_No, A.AccT_TXDay, A.ACCT_TXDAY_SEQ  
    
    IF @IsRemain = 4032001 -- �ܾ����� (�ܾ׾��°� ����)
    BEGIN
        DELETE FROM #Result WHERE RemainAmt = 0 
    END 
    ELSE IF @IsRemain = 4032002 -- �۾׾��� (�۾��ִ°� ����)
    BEGIN
        DELETE FROM #Result WHERE RemainAmt <> 0 
    END
    
    SELECT * FROM #Result 
    
    RETURN
GO
exec DTI_SSLBillConsignListSubQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <InDateFr></InDateFr>
    <InDateTo></InDateTo>
    <IsRemain />
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1022831,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1019192

