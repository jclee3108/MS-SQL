IF OBJECT_ID('hencom_SSIAFebCollectQuery') IS NOT NULL 
    DROP PROC hencom_SSIAFebCollectQuery 
GO 

-- v2017.04.14 
/*************************************************************************************************
  ��  �� - ���ݳ����ݿ� (��ȸ)
  �ۼ��� - 2008.7.9
  �ۼ��� - ������
  
  ����Ʈ�� ����by�ڼ���2016.01.22
  hencom_TDABankAccAdd ���̺� �÷��� ���ݳ���ȸ����ǥǥ�ÿ���(IsCollectMoneyDis) üũ�� ��ݰ��¸� ��ȸ�ǵ��� ��.
 *************************************************************************************************/
 CREATE PROCEDURE hencom_SSIAFebCollectQuery
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT = 0,
     @ServiceSeq     INT = 0,
     @WorkingTag     NVARCHAR(10)= '',
      @CompanySeq     INT = 1,
     @LanguageSeq    INT = 1,
     @UserSeq        INT = 0,
     @PgmSeq         INT = 0
 AS
    DECLARE @docHandle      INT,
            @DateFr         NCHAR(8),
            @DateTo         NCHAR(8),
            @ProcType       NCHAR(8),
            @FeeAccName     NVARCHAR(100),
            @FeeAccSeq      INT,
            @Remark         NVARCHAR(100), 
            @UMBankAccKind  INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
    SELECT @DateFr          = ISNULL(DateFr,''),
           @DateTo          = ISNULL(DateTo,''),
           @ProcType        = ISNULL(ProcType,''), 
           @UMBankAccKind   = ISNULL(UMBankAccKind, 0)
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1',@xmlFlags)
       WITH (
                DateFr          NCHAR(8),
                DateTo          NCHAR(8),
                ProcType        NCHAR(8), 
                UMBankAccKind   INT 
            )
      IF @DateFr = ''
         SELECT @DateFr = '20000101'
     
     IF @DateTo = ''
         SELECT @DateTo = '99991231'
         
/* �ּ�ó��by�ڼ���2016.01.22
      SELECT  CompanySeq     , SITE_NO        , SEQ            , REMIT_DAY      , REMIT_TIME     ,
             OUT_BANK       , OUT_ACCTNO     , IN_BANK        , IN_ACCTNO      , REMIT_AMT      ,
             FEE            , REMIT_CURBAL   , REMITSTS       , ERR_CD         , REMITTYPE2     ,
             REMIT_USER_ID  , REMIT_DATETIME , REMIT_CLIENT_NO, BUKRS          , Worksta1       ,
             Worksta2       , Worksta3       , Remark         , ERPKey         , SlipSeq        ,
             LastUserSeq    , LastDateTime   , MST_SEQ
       INTO #TEMP_TSIAFebCollect
       FROM _TSIAFebCollect WITH(NOLOCK)
      WHERE REMIT_DAY BETWEEN @DateFr AND @DateTo
 --        AND (@ProcType   = '' OR (ISNULL(ERPKey, '') <> '' AND @ProcType = '0')  
 --                              OR (ISNULL(ERPKey, '')  = '' AND @ProcType = '1'))  
        AND (@ProcType   = '' OR ((ISNULL(SlipSeq, 0) <> 0 OR ISNULL(ERPKey, '') <> '') AND @ProcType = '0')  
                              OR ((ISNULL(SlipSeq, 0) = 0 AND ISNULL(ERPKey, '') = '') AND @ProcType = '1'))  
        AND CompanySeq = @CompanySeq
*/
--  hencom_TDABankAccAdd ���̺� �÷��� ���ݳ���ȸ����ǥǥ�ÿ���(IsCollectMoneyDis) üũ�� ��ݰ��¸� ��ȸ�ǵ��� ��.
      SELECT A.CompanySeq     , A.SITE_NO        , A.SEQ            , A.REMIT_DAY      , A.REMIT_TIME     ,
             A.OUT_BANK       , A.OUT_ACCTNO     , A.IN_BANK        , A.IN_ACCTNO      , A.REMIT_AMT      ,
             A.FEE            , A.REMIT_CURBAL   , A.REMITSTS       , A.ERR_CD         , A.REMITTYPE2     ,
             A.REMIT_USER_ID  , A.REMIT_DATETIME , A.REMIT_CLIENT_NO, A.BUKRS          , A.Worksta1       ,
             A.Worksta2       , A.Worksta3       , A.Remark         , A.ERPKey         , A.SlipSeq        ,
             A.LastUserSeq    , A.LastDateTime   , A.MST_SEQ
       INTO #TEMP_TSIAFebCollect
       FROM _TSIAFebCollect AS A WITH(NOLOCK) 
       JOIN _TDABankAcc   AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                           AND A.OUT_ACCTNO = REPLACE(B.BankAccNo, '-', '')
        LEFT OUTER JOIN hencom_TDABankAccAdd AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq 
                                                              AND C.BankAccSeq = B.BankAccSeq
      WHERE A.REMIT_DAY BETWEEN @DateFr AND @DateTo
        AND (@ProcType   = '' OR ((ISNULL(A.SlipSeq, 0) <> 0 OR ISNULL(A.ERPKey, '') <> '') AND @ProcType = '0')  
                              OR ((ISNULL(A.SlipSeq, 0) = 0 AND ISNULL(A.ERPKey, '') = '') AND @ProcType = '1'))  
        AND A.CompanySeq = @CompanySeq
        AND C.IsCollectMoneyDis = '1' --���ݳ���ȸ����ǥǥ�ÿ���
        

      -- ���������, �ڵ�
     SELECT @FeeAccName = C.AccName, @FeeAccSeq = B.AccSeq
       FROM _TCOMEnvAcc AS A WITH(NOLOCK)
         JOIN _TCOMEnvAccKind AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                               AND A.AccKindSeq = B.AccKindSeq
         JOIN _TDAAccount  AS C WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq
                                            AND B.AccSeq     = C.AccSeq
      WHERE  A.CompanySeq = @CompanySeq
         AND A.AccKindSeq = 8906
         
      -- ����ó�� ����    8907
     SELECT @Remark = A.EnvValue
       FROM _TCOMEnv AS A WITH(NOLOCK)
      WHERE  A.CompanySeq = @CompanySeq
         AND A.EnvSeq     = 8907
  
      -- ������ ���� ����� ���¿� �������� ������ ��ϵ� ��� �����ڵ尡 ���� ���� ������ ����.
     SELECT DISTINCT B.CompanySeq, B.BankAccSeq AS OUTBankAccSeq, B.BankAccNo AS OUTBankAccNo, B.BankAccName AS OUTBankAccName, B.BankSeq AS OUTBankSeq, B.AccSeq AS OUTAccSeq
       INTO #TEMP_OUT_BANKACC
       FROM #TEMP_TSIAFebCollect AS A
         JOIN _TDABankAcc   AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                             AND A.OUT_ACCTNO = REPLACE(B.BankAccNo, '-', '')
         JOIN _TDABankAcc   AS B1 WITH(NOLOCK) ON A.CompanySeq = B1.CompanySeq
                                              AND A.IN_ACCTNO  = REPLACE(B1.BankAccNo, '-', '')
         JOIN (
               SELECT CompanySeq, MIN(AccSeq) AS AccSeq, BankAccNo
                 FROM _TDABankAcc WITH(NOLOCK)
                WHERE CompanySeq = @CompanySeq
                GROUP BY CompanySeq, BankAccNo
              ) AS C ON B.CompanySeq = C.CompanySeq
                    AND B.BankAccNo = C.BankAccNo
                    AND B.AccSeq = C.AccSeq
              
      -- ������ ���� ����� ���¿� �������� ������ ��ϵ� ��� �����ڵ尡 ���� ���� ������ ����.
     SELECT DISTINCT B1.CompanySeq, B1.BankAccSeq AS INBankAccSeq, B1.BankAccNo AS INBankAccNo, B1.BankAccName AS INBankAccName, B1.BankSeq AS INBankSeq, B1.AccSeq AS INAccSeq
       INTO #TEMP_IN_BANKACC
       FROM #TEMP_TSIAFebCollect AS A
         JOIN _TDABankAcc   AS B1 WITH(NOLOCK) ON A.CompanySeq = B1.CompanySeq
                                              AND A.IN_ACCTNO  = REPLACE(B1.BankAccNo, '-', '')
         JOIN (
               SELECT CompanySeq, MIN(AccSeq) AS AccSeq, BankAccNo
                 FROM _TDABankAcc WITH(NOLOCK)
                WHERE CompanySeq = @CompanySeq
                GROUP BY CompanySeq, BankAccNo
              ) AS C ON B1.CompanySeq = C.CompanySeq
                    AND B1.BankAccNo = C.BankAccNo
                    AND B1.AccSeq = C.AccSeq
      -- ���� ����Ÿ
     SELECT  --CASE ISNULL(A.ERPKey, '') WHEN '' THEN '��ó��' ELSE 'ó��' END AS ProcType,   -- ó����Ȳ
             CASE WHEN ISNULL(A.SlipSeq, 0) <> 0 OR ISNULL(A.ERPKey, '') <> '' THEN 'ó��' ELSE '��ó��' END AS ProcType,   -- ó����Ȳ
             A.REMIT_DAY    AS RemitDate ,        -- ������
             A.OUT_ACCTNO   AS OutBankAccNo,      -- ��ݰ��¹�ȣ    -- �뺯
             B.OUTBankAccName  AS OutBankAccName,    -- ��ݰ��°�����
             C.BankName    AS OutBankName,       -- �������
              A.IN_ACCTNO    AS InBankAccNo,       -- �Աݰ��¹�ȣ    -- ����
             D.INBankAccName         AS InBankAccName,     -- �Աݰ��°�����ȣ
             E.BankName    AS InBankName,        -- �Ա�����
             A.REMIT_AMT + A.FEE     AS OutAmt,            -- ��ݾ�  -- REMIT_AMT �� �����Ḧ ������ ��ü�ݾ��Դϴ�. (2013.12.03 mypark)
             A.FEE     AS FeeAmt,            -- ������
              A.REMIT_AMT    AS InAmt,             -- �Աݾ�
             CASE WHEN ISNULL(A.ERPKey, '') = '' THEN H.SlipID ELSE A.ERPKey END AS ERPKey,            -- ��ǥ��ȣ
             A.Remit_Day + '_' + CONVERT(VARCHAR(19),A.Seq) AS RemitSeq,           -- �����Ϸù�ȣ
             A.SEQ     AS SEQ,               -- ����
             A.SITE_NO    AS SITE_NO,           -- �Ϸù�ȣ
             @FeeAccName    AS FeeAccName,        -- ���������
             @FeeAccSeq    AS FeeAccSeq ,        -- ����������ڵ�
             G.AccName    AS DrAccName ,     -- ��������    
             F.AccName    AS CrAccName ,     -- �뺯����    
             D.INAccSeq    AS DrAccSeq  ,     -- ���������ڵ�
              B.OUTAccSeq    AS CrAccSeq  ,     -- �뺯�����ڵ�
             CASE WHEN ISNULL(A.Remark, '') = '' THEN @Remark ELSE A.Remark END AS Remark,            -- ����ó�� ���
             B.OUTBankAccSeq   AS OutBankAccSeq,     -- ��ݰ����ڵ�
             C.BankSeq    AS OutBankSeq,        -- ��������ڵ�
             D.INBankAccSeq   AS InBankAccSeq,      -- �Աݰ����ڵ�
              E.BankSeq    AS InBankSeq,         -- �Ա������ڵ�
             A.SlipSeq    AS SlipSeq  ,         -- ��ǥ��ȣ�ڵ�
             A.REMIT_AMT + A.FEE  AS SumRemFeeAmt,      -- ���ݾ׼������� (�Աݱݾױ������� �����Ḧ + �� (���ݾ� + ������))
             A.MST_SEQ    AS MST_SEQ,
			 ba.MainAccSeq,
			 (select accname from _TDAAccount where companyseq = @CompanySeq and accseq = ba.MainAccSeq ) as MainAccName, 
             CONVERT(INT,ba.Memo1) AS UMBankAccKind, 
             I.MinorName AS UMBankAccKindName 
       FROM #TEMP_TSIAFebCollect AS A WITH(NOLOCK)
             LEFT OUTER JOIN _TACSlipRow AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq
                                                          AND A.SlipSeq    = H.SlipSeq
             LEFT OUTER JOIN #TEMP_OUT_BANKACC AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                            AND A.OUT_ACCTNO = REPLACE(B.OUTBankAccNo, '-', '')
             LEFT OUTER JOIN #TEMP_IN_BANKACC AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq
                                                            AND A.IN_ACCTNO  = REPLACE(D.INBankAccNo, '-', '')
             LEFT OUTER JOIN _TDABank      AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq
                                                            AND C.BankSeq    = B.OUTBankSeq 
             LEFT OUTER JOIN _TDABank      AS E WITH(NOLOCK) ON E.CompanySeq = D.CompanySeq
                                                            AND E.BankSeq    = D.INBankSeq
             LEFT OUTER JOIN _TDAAccount   AS F WITH(NOLOCK) ON B.CompanySeq = F.CompanySeq
                                                            AND B.OUTAccSeq     = F.AccSeq
             LEFT OUTER JOIN _TDAAccount   AS G WITH(NOLOCK) ON D.CompanySeq = G.CompanySeq
                                                            AND D.INAccSeq     = G.AccSeq
			 LEFT OUTER JOIN hencom_TDABankAccAdd AS ba WITH(NOLOCK) ON ba.CompanySeq = @CompanySeq 
                                                                    AND ba.BankAccSeq = B.OUTBankAccSeq
             LEFT OUTER JOIN _TDAUMinor AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = CONVERT(INT,ba.Memo1) ) 
      WHERE ( @UMBankAccKind = 0 OR CONVERT(INT,ba.Memo1) = @UMBankAccKind ) 
      ORDER BY A.REMIT_DAY, A.SEQ
RETURN
