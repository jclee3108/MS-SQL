

IF OBJECT_ID('KPX_SARBizTripCostJumpOut') IS NOT NULL 
    DROP PROC KPX_SARBizTripCostJumpOut
GO 

-- v2015.01.08 

-- ����ī���볻��ȸ����ǥ���� -> ���������ǰ�Ǽ� �����ƿ� by ����õ
 CREATE PROC KPX_SARBizTripCostJumpOut  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS  
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    
    CREATE TABLE #TSIAFebCardCfm (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TSIAFebCardCfm'   
    IF @@ERROR <> 0 RETURN    
    
    
    
    DECLARE @JuridCardAcc       NVARCHAR(100),  
            @IndivCardAcc       NVARCHAR(100),  
            @CardAddAcc         NVARCHAR(100),   
            @JuridCardAccSeq    INT,  
            @IndivCardAccSeq    INT,  
            @CardAddAccSeq      INT,  
            @pEmpSeq            INT,  
            @ISAppr             NCHAR(1),
            @PgmID              NVARCHAR(100),
            @IsEmpQry           NCHAR(1),
            @IniEmpQry          INT,                --�ʱ� �Ѿ���� ������ ȭ��� ����ڰ� �Է��� �� �ִ� ��
            @EnvValue8927       DECIMAL(19,5),      --�ش� �ݾ� ���ϴ� ���� ��ȸ�� �ΰ���üũ�� ���� �Ѵ�.
            @EnvValue8929       INT                -- �ش� üũ�� �����Ǹ� Ȱ�����Ͱ� �������� ��ȸ�ȴ�. 
    
 
    SELECT @EnvValue8927 = 0
    SELECT @EnvValue8927 = EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 8927   -- <����ī��>      K-Branch SI_����ī���볻��ȸ����ǥ���� �ΰ���üũ ���� �����ݾ�
    SELECT @EnvValue8929 = EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 8929   -- <����ī��>      K-Branch ����ī���볻�� Ȱ�����͵���Ʈ����   SELECT * FROM _TCOMEnv WHERE EnvSeq = 8918
    SELECT @ISAppr       = EnvValue FROM _TCOMEnv where CompanySeq = @CompanySeq AND EnvSeq = 8923   -- <��ȭ�ݾ�>      K-Branch ��ȭ�ݾ� �������� �������� ��ȸ ����
    
    
    ---- Ȯ������ : Ȯ�����μ��� �̻�� �Ǵ� ���������� ��� ''
    --IF @IsDefine IS NULL  
    --BEGIN  
    --    SELECT @IsDefine = CASE EnvValue WHEN '0' THEN '' ELSE '0' END  FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 8918  -- <����ī��>      K-Branch����ī��Ȯ�����μ�����뿩��
    --    IF EXISTS (SELECT 1 FROM _TCOMEnvSlipSuper WHERE CompanySeq = @CompanySeq AND EmpSeq = @EmpSeq)  
    --    BEGIN  
    --        SELECT @IsDefine = ''  
    --    END  
    --END 
    
    --����������������������������������������������������������
    --------------------------------------------------------------------------------------------------------------------
    -- 2011.07.05 ����ī���볻��ȸ����ǥ����(����)ȭ�鿡�� �Ѿ���� QryEmpSeq ����
    -- @QryEmpSeq�� (����)ȭ�鿡�� �Ѿ���� ��쿡�� ����ī�����̺� ����ڰ� ����� ���¿����� ��ȸ�Ǿ,
    -- ��ȸ�� �ڵ����� �������� ����� �������δ� �ɸ��� �ʴ´�.
    -- ������, @QryEmpSeq�� Parameter�� �Ѿ���� ��� @QryEmpSeq�� 0���� ����� ���ǿ� �ɸ��� �ʵ��� �����ϰ�,
    -- @EmpSeq�� @QryEmpSeq�� �־��ְ� �⺻ ������ Ż �� �ֵ��� �����Ѵ�.
    -- ��, ����ȭ���� �ƴѰ����� ����ڸ� �����ϴ� �����, QryEmpSeq ==> EmpSeq�� �ٲ��ָ� �ȵ�
    --------------------------------------------------------------------------------------------------------------------
    --����������������������������������������������������������
    
  --  SELECT @PgmID = PgmID FROM _TCAPgm WHERE PgmSeq = @PgmSeq
    
  --  SELECT @IsEmpQry = '0'
    
  --  SELECT @IniEmpQry = @QryEmpSeq
  --   -- (����)�� ȭ�鿡���� @QryEmpSeq�� ������ �Ѿ�´�..
  --  IF @QryEmpSeq <> 0 AND @PgmID = 'FrmSIAFebCardCfm_Per'
  --  BEGIN
  --      SELECT @EmpSeq = @QryEmpSeq
  --      SELECT @QryEmpSeq = 0
  --      SELECT @IniEmpQry = 0               --���ο� ȭ�鿡���� ���ʿ�
  --  END
  --  -- �Ϲ� ȭ�鿡���� @QryEmpSeq�� ���� ���� �� �ִµ�, �Ʒ��ʿ��� SuperUser�� ���� �ٽ� @Empseq = 0���� �ٲ��ְ� ����.
  --  ELSE
  --  BEGIN
  --      --SELECT @EmpSeq = @EmpSeq
  --       IF @QryEmpSeq <> 0   
  --      --    SELECT @QryEmpSeq = @EmpSeq
  --      --ELSE
  --      -- @QryEmpSeq �� 0�� �ƴ϶�� �̾߱�� ������ �Է��� �Ǿ��ٴ� �̾߱��, �̷����, superuser�� @QryEmpSeq�� 0���� �ٲ��� �ʵ��� �Ѵ�.                
  --      BEGIN
  --          SELECT @QryEmpSeq = @QryEmpSeq
  --          SELECT @IsEmpQry = '1'
  --      END
  --  END
 
  --  -- FBSī�����ڵ�ϵ��ִ����� ��� Table  
  --  CREATE TABLE #TFBSCardUser  
  --  (  
  --      CardSeq INT,  
  --      EmpSeq  INT  
  --  )  
  --   -- ������������  
  --  IF EXISTS (SELECT 1 FROM _TCOMEnvSlipSuper WHERE CompanySeq = @CompanySeq AND EmpSeq = @EmpSeq) -- �α��λ���ڰ�  SuperUser�ϰ�� EmpSeq = 0   
  --  BEGIN 
  --IF @PgmID <> 'FrmSIAFebCardCfm_Per' 
  --BEGIN
  -- SELECT @EmpSeq = 0  
  --END
        
  --      --���������̸鼭 ����ȭ���� �ƴϸ� @QryEmpSeq = 0 ���� �Ѵ�.
  --      IF @PgmID <> 'FrmSIAFebCardCfm_Per' AND @IsEmpQry <> '1'
  --      BEGIN
  --          SELECT @QryEmpSeq = 0
  --      END
  --  END  
  
    --IF EXISTS (SELECT 1 FROM _TSIAFebCardUserInfo WHERE EmpSeq = @EmpSeq) -- �α��λ���ڰ�  SuperUser�ϰ�� EmpSeq = 0   
    --BEGIN  
    -- INSERT INTO #TFBSCardUser  
    -- SELECT A.CardSeq,  
    --        CASE WHEN @EmpSeq = 0 THEN 0  
    --             ELSE ISNULL(C.EmpSeq,0) END AS EmpSeq  
    --   FROM _TDACard AS A   
    --        JOIN _TSIAFebCardUserInfo AS C ON A.CompanySeq = C.CompanySeq AND A.CardSeq = C.CardSeq  
    --  WHERE A.CompanySeq = @CompanySeq  
    --    AND (@EmpSeq = 0 OR C.EmpSeq = @EmpSeq)  
    --    AND (@CardSeq = 0 OR A.CardSeq = @CardSeq)  
  
    --    SELECT @IsDefine = ''  
  
    --END  
  
    
    
    -- ����ī�������, �ڵ�  
    SELECT @JuridCardAcc = C.AccName, @JuridCardAccSeq = B.AccSeq  
      FROM _TCOMEnvAcc AS A  
        JOIN _TCOMEnvAccKind AS B ON A.CompanySeq = B.CompanySeq  
                                 AND A.AccKindSeq = B.AccKindSeq  
        JOIN _TDAAccount  AS C ON B.CompanySeq = C.CompanySeq  
                              AND B.AccSeq     = C.AccSeq  
     WHERE  A.CompanySeq = @CompanySeq  
        AND A.AccKindSeq = 8901  
  
  
    -- ����ī�������, �ڵ�  
    SELECT @IndivCardAcc = C.AccName, @IndivCardAccSeq = B.AccSeq  
      FROM _TCOMEnvAcc AS A  
        JOIN _TCOMEnvAccKind AS B ON A.CompanySeq = B.CompanySeq  
                                 AND A.AccKindSeq = B.AccKindSeq  
        JOIN _TDAAccount  AS C ON B.CompanySeq = C.CompanySeq  
                              AND B.AccSeq     = C.AccSeq  
     WHERE  A.CompanySeq = @CompanySeq  
        AND A.AccKindSeq = 8902  
  
  
    -- ī��ΰ�������, �ڵ�  
    SELECT @CardAddAcc = C.AccName, @CardAddAccSeq = B.AccSeq  
      FROM _TCOMEnvAcc AS A  
        JOIN _TCOMEnvAccKind AS B ON A.CompanySeq = B.CompanySeq  
                                 AND A.AccKindSeq = B.AccKindSeq  
        JOIN _TDAAccount  AS C ON B.CompanySeq = C.CompanySeq  
                              AND B.AccSeq     = C.AccSeq  
     WHERE  A.CompanySeq = @CompanySeq  
        AND A.AccKindSeq = 8903  
    
    --select * from #TSIAFebCardCfm 
    --return 
    -- �ŷ�ó����  
    SELECT REPLACE(B.BizNo, '-', '') AS BizNo, Min(B.CustSeq) AS CustSeq  
      into #TCustInfo  
      FROM #TSIAFebCardCfm AS AA 
      LEFT OUTER JOIN _TSIAFebCardCfm   AS A ON ( A.CompanySeq = @CompanySeq 
                                              AND REPLACE(AA.CardNo,'-','') = A.CARD_CD 
                                              AND AA.ApprDate = A.APPR_DATE 
                                              AND AA.ApprSeq = A.APPR_SEQ 
                                              AND AA.ApprNo = A.APPR_No 
                                              AND AA.CANCEL_YN = A.CANCEL_YN
                                                )  
                 JOIN _TDACust AS B ON A.CompanySeq = B.CompanySeq  
                                      AND REPLACE(A.CHAIN_ID, '-', '') = REPLACE(B.BizNo, '-', '')
                                      AND A.CHAIN_ID <> ''  
      GROUP BY REPLACE(B.BizNo, '-', '')
    
    --return 
    -- ī������  
     SELECT A.CardSeq,  
            ISNULL(B.EmpSeq,A.EmpSeq) AS EmpSeq,  
            CASE WHEN ISNULL(B.DistribDate,'') = '' THEN A.IssueDate ELSE B.DistribDate END AS StartDate,   
            CASE WHEN ISNULL(B.ReturnDate,'') = '' THEN (  
                                                         CASE WHEN ISNULL(A.ExpireYm,'') = '' THEN '99991231' ELSE A.ExpireYm END  
                                                        )  
                 ELSE B.ReturnDate END AS EndDate  
       INTO #TCardUser  
       FROM _TDACard AS A   
            LEFT OUTER JOIN _TDACardUser AS B ON A.CompanySeq = B.CompanySeq AND A.CardSeq = B.CardSeq  
      WHERE A.CompanySeq = @CompanySeq  
        --AND (@EmpSeq = 0 OR (A.EmpSeq = @EmpSeq OR B.EmpSeq = @EmpSeq))  
        --AND (@CardSeq = 0 OR A.CardSeq = @CardSeq)  
    -- ���� ����Ÿ  
    -- A.Chain_Type = 2 �϶� (���̰���) �� ���αݾ��� �� ���ް���, �հ�ݾ��̰� �ΰ�������/�Ұ������� üũ���� �ʴ´�.
     /*
     --=============================================================================================================================
    -- ��ȸ �� �����׸�(RemSeq)�� ���°�� Update�Ѵ�. (���� : ���αⰣ���ش��ϴ� �͸�.)
    --=============================================================================================================================
    --UPDATE _TSIAFebCardCfm
    --   SET RemSeq = D.RemSeq
    --  FROM _TSIAFebCardCfm AS A
    --  JOIN _TDAAccountSub  AS B ON A.AccSeq = B.AccSeq AND A.CompanySeq = B.CompanySeq
    --  JOIN _TDAAccountRem  AS C ON B.RemSeq = C.RemSeq AND A.CompanySeq = C.CompanySeq
    --  LEFT OUTER JOIN (
    --        SELECT A.AccSeq, A.RemSeq, MIN(A.Sort) AS SortNum
    --          FROM _TDAAccountSub AS A WITH (NOLOCK)  
    --               LEFT JOIN _TDAAccountRem AS B WITH (NOLOCK)  
    --                      ON B.CompanySeq   = A.CompanySeq  
    --                     AND B.RemSeq       = A.RemSeq  
    --         WHERE A.CompanySeq = @CompanySeq 
    --           AND B.SMInputType = 4016002  -- ���� codehelp
    --           AND B.CodeHelpSeq = 40031
    --         GROUP BY A.AccSeq, A.RemSeq, A.Sort
    --        ) AS D ON A.AccSeq = D.AccSeq AND B.Sort = D.SortNum
    -- WHERE A.CompanySeq = @CompanySeq 
    --   AND ISNULL(A.AccSeq, 0) <> 0 
    --   AND ISNULL(A.RemSeq, 0) = 0
    --   AND C.SMInputType = 4016002  -- ���� codehelp
    --   AND C.CodeHelpSeq = 40031
    --   AND (A.APPR_DATE >= @DateFr  OR @DateFr = '')  
    --   AND (A.APPR_DATE <= @DateTo  OR @DateTo = '') 
    --=============================================================================================================================
    */
    
    --IF @DateFr = '' SELECT @DateFr = '19000101'
    --IF @DateTo = '' SELECT @DateTo = '99991231'
    --SELECT DISTINCT APPR_NO
    --  INTO #CancelSource
    --  FROM _TSIAFebCardCfm 
    -- WHERE CompanySeq = @CompanySeq
    --   AND CANCEL_YN = 'Y'
    --   AND APPR_DATE BETWEEN @DateFr AND @DateTo
    
     -- _TDACard ���̺��� CardNo�� ��ȣȭ �ʵ�� ������ ��쿡�� where������ ��ȣȭ ������ �ɸ��� �Ǹ� index�� Ÿ�� ���Ͽ� �ӽ����̺� ��Ƽ� ��ȸ�ϵ��� ����
    SELECT CompanySeq, BizUnit, CardSeq, dbo._FCOMDecrypt(CardNo, '_TDACard', 'CardNo', @CompanySeq) AS CardNo, CardName,  
           SMComOrPriv, UMCardKind, EmpSeq, IssueDate, ExpireYm,  
           SttlDay, SttlLimitDay, SttlAccNo, CardStatus, StopDate,  
           Remark, LastUserSeq, LastDateTime, SttlBankSeq, SttlOwner,  
           ManageDeptSeq, RemarkNum  
      INTO #TDACardTemp
      FROM _TDACard  
    
    
    SELECT CompanySeq, BizUnit, CardSeq, LEFT(REPLACE(CardNo, '-', ''),16) AS CardNo, CardName,  
           SMComOrPriv, UMCardKind, EmpSeq, IssueDate, ExpireYm,  
           SttlDay, SttlLimitDay, SttlAccNo, CardStatus, StopDate,  
           Remark, LastUserSeq, LastDateTime, SttlBankSeq, SttlOwner,  
           ManageDeptSeq, RemarkNum  
      INTO #TDACard
      FROM #TDACardTemp  
    
    ALTER TABLE #TDACard ADD CONSTRAINT TPK_TDACard PRIMARY KEY CLUSTERED (CompanySeq, BizUnit, CardSeq) 
    CREATE UNIQUE INDEX IDXTemp_TDACard ON #TDACard(CompanySeq, BizUnit, CardSeq)
    
    DROP TABLE #TDACardTemp
    
    --select * from #TSIAFebCardCfm 
    
    --return 
    
    SELECT  CASE WHEN ISNULL(A.SlipSeq, 0) <> 0 OR ISNULL(A.ERPKey, '') <> '' THEN 'ó��' ELSE '��ó��' END AS ProcType,   -- ó����Ȳ  
            --dbo._FCOMDecrypt(B.CardNo, '_TDACard', 'CardNo', @CompanySeq)                AS CARD_CD,              -- ī���ȣ  
            B.CardNo                 AS CardNo,             -- ī���ȣ
            B.CardName               AS CardName,            -- ī���
            A.APPR_DATE              AS ApprDate,            -- ��������  
            A.APPR_NO                AS ApprNo,              -- ���ι�ȣ  
            A.CHAIN_NM               AS ChainName,           -- ��������  
            A.CHAIN_ID               AS ChainBizNo,          -- ������ ����ڹ�ȣ  
            ISNULL(CT.MinorName, '��Ȯ��')            AS ChainType,
   ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                              WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)     AS ApprAmt,             -- ���αݾ�  
            ISNULL(ABS(A.APPR_TAX),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)     AS ApprTax,             -- ���αݾ׺ΰ���ġ��  
            CASE WHEN A.Chain_Type IN (2,3) AND SupplyAmt IS NULL THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)
                --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)            
                 WHEN (ISNULL(A.SupplyAmt, 0) = 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) - ABS(ISNULL(A.APPR_TAX,0))) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
        WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1) -- ���ް�����(+)�� ���࿡�� �Ѿ�� ���
                 WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1) 
                 ELSE A.SupplyAmt  
            END  AS SupplyAmt,           -- ���ް���  
            CASE WHEN A.Chain_Type IN (2,3) THEN 0
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN 0
                 WHEN ISNULL(A.NotVatSel,'') <> '1' THEN   
                 CASE WHEN ISNULL(A.SupplyAmt, 0) = 0 THEN ABS(ISNULL(A.APPR_TAX,0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
          WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) * (-1) - A.SupplyAmt * (-1)) -- ���ް�����(+)�� ���࿡�� �Ѿ�� ��� 
                      WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) * (-1) - A.SupplyAmt * (-1))    
                      ELSE (ABS(ISNULL(A.APPR_AMT, 0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                               WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)) - ISNULL(A.SupplyAmt,ABS(ISNULL(A.APPR_AMT, 0) - ISNULL(A.APPR_TAX,0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                                                                                                                                                  WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END))  
                 END - ISNULL(A.DisSupplyAmt,0) - ISNULL(A.Tip_Amt,0)   
            ELSE 0 END   AS UpdateVat ,          -- �����ΰ���  
            CASE WHEN A.Chain_Type IN (2,3) AND SupplyAmt IS NULL THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END) 
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)                 
                ELSE
                CASE WHEN (ISNULL(A.SupplyAmt, 0) = 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) - ABS(ISNULL(A.APPR_TAX,0))) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
            WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1) -- ���ް�����(+)�� ���࿡�� �Ѿ�� ��� 
                     WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1)
                     ELSE A.SupplyAmt  
                END  +         -- ���ް���  
                CASE WHEN A.Chain_Type IN (2,3) THEN 0
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN 0
                 WHEN ISNULL(A.NotVatSel,'') <> '1' THEN   
                     CASE WHEN ISNULL(A.SupplyAmt, 0) = 0 THEN ABS(ISNULL(A.APPR_TAX,0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
              WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) * (-1) - A.SupplyAmt * (-1)) -- ���ް�����(+)�� ���࿡�� �Ѿ�� ���   
                          WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) * (-1) - A.SupplyAmt * (-1))
                          ELSE (ABS(ISNULL(A.APPR_AMT, 0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                                   WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)) - ISNULL(A.SupplyAmt,(ABS(ISNULL(A.APPR_AMT, 0)) - ABS(ISNULL(A.APPR_TAX,0))) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                                                                                                                                                                     WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END))  
                     END    
                ELSE 0 END
            END AS TotalAmt ,          -- �հ�ݾ�  
             A.AccSeq                 AS AccSeq,              -- �����ڵ�  
            A.AccSeq                 AS AccSeqOld,           -- �����ڵ�   
            A.HALBU                  AS HALBU,               -- �ҺαⰣ  
            A.RemSeq                 AS RemSeq,              -- �����׸�
            AR.RemName               AS RemName,             -- �����׸��
            CASE WHEN ARV1.RemValueName IS NULL THEN ARV2.RemValueName 
                 ELSE ARV1.RemValueName
            END                      AS RemValue,            -- �����׸�
            A.RemValueSeq            AS RemValueSeq,         -- �����׸��ڵ�
            A.CANCEL_YN              AS CANCEL_YN,           -- ������ҿ��� Ű  
            CASE A.CANCEL_YN WHEN '3' THEN (CASE WHEN A.BUYING_DIST IN ('02', '04') THEN '���'
                                                 WHEN A.BUYING_DIST = '06' THEN 'ȯ��' END)     --��ȯ���� �߰�
                             WHEN 'Y' THEN '���'  
                             ELSE '����'  
            END                      AS CancelYN,  -- ������ҿ���  
            E.AccName                AS AccName,             -- �߻�����  
            A.Remark                 AS Remark,              -- ���1  
            C.EmpName                AS EmpName,             -- ���  
     CASE WHEN ISNULL(D.CustName,'') = '' THEN D2.CustName ELSE D.CustName END AS CustName,      -- �ŷ�ó  
            CASE WHEN ISNULL(A.CustSeq, 0) = 0   THEN D1.CustSeq  ELSE A.CustSeq  END AS CustSeq,       -- �ŷ�ó�ڵ�  
            CASE WHEN ISNULL(A.ERPKey,'') = ''   THEN H.SlipID    ELSE A.ERPKey   END AS ERPKey,    -- ��ǥ��ȣ  
            A.SlipSeq               AS SlipSeq  ,                                   -- �߻���ǥ�ڵ�  
            C.EmpSeq                AS EmpSeq     ,        -- ���  
            A.APPR_SEQ              AS APPR_SEQ,            -- ���μ���  
            B.CardSeq               AS CardSeq,             -- ī���ڵ�  
            G.CCtrName              AS CCtrName,            -- Ȱ�����͸�
            G.CCtrSeq               AS CCtrSeq,             -- Ȱ�������ڵ�
            F.DeptName              AS DeptName,            -- �μ���
            F.Deptseq               AS DeptSeq,             -- �μ��ڵ�
            CASE B.SMComOrPriv  
                WHEN 4019001 THEN @JuridCardAcc  
                WHEN 4019002 THEN @IndivCardAcc  
            END         AS CrAccName, --' ������ -�����ޱ�(ī��)' AS OutAccNm,  
            CASE B.SMComOrPriv  
                WHEN 4019001 THEN @JuridCardAccSeq  
                WHEN 4019002 THEN @IndivCardAccSeq  
            END         AS CrAccSeq,     -- �������ڵ�  
            CASE WHEN A.Chain_Type IN (2,3) THEN '0'
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN '0'            
                 WHEN ((A.VatSel IS NULL OR A.VatSel = '') AND (A.VatYN = 'Y' OR ISNULL(A.APPR_TAX,0) <> 0)) THEN '1' ELSE A.VatSel END AS VatSel, -- �ΰ�������  
            CASE WHEN A.Chain_Type IN (2,3) THEN '0'
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN '0'             
                 WHEN A.VatYN = 'Y' THEN '1'  
                 WHEN A.VatYN = 'N' THEN '0'  
            END AS VATYN,        --�ΰ���ȯ�޴�󿩺�   
            CASE WHEN A.Chain_Type IN (2,3) THEN ''
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ''             
                 WHEN (A.VatSel = '1' OR ((A.VatSel IS NULL OR A.VatSel = '') AND (A.VatYN = 'Y' OR ISNULL(A.APPR_TAX,0) <> 0)))  THEN @CardAddAcc 
                 WHEN A.IsNonVat = '1' THEN @CardAddAcc 
      ELSE '' END AS VatSttlItem, -- �ΰ�������  ,
            CASE WHEN A.Chain_Type IN (2,3) THEN 0
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN 0             
                 WHEN (A.VatSel = '1' OR ((A.VatSel IS NULL OR A.VatSel = '') AND (A.VatYN = 'Y' OR ISNULL(A.APPR_TAX,0) <> 0)))  THEN @CardAddAccSeq ELSE '' END AS AddTaxAccSeq, -- �ΰ��������ڵ�  
            A.IsDefine,  
            A.EvidSeq,  
            Q.EvidName,  
            CASE WHEN ISNULL(A.ModDate,'') = '' THEN A.APPR_DATE ELSE A.ModDate END AS ModDate,  
            A.EvidSeq AS EvidSeq2,  
            Q.EvidName AS EvidName2,  
            A.MASTER,  
            ISNULL((CASE WHEN CHARINDEX('-',A.MERCHZIPCODE) <> 0 THEN A.MERCHZIPCODE ELSE LEFT(A.MERCHZIPCODE,3) + '-' + RIGHT(A.MERCHZIPCODE,3) END ),'')   AS MERCHZIPCODE,  
            A.MERCHADDR1,  
            A.MERCHADDR2,  
             A.APPRTOT * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END) AS APPRTOT,  
            A.MCCNAME,  
            A.MCCCODE,  
            A.TAXTYPE,  
            A.MERCHCESSDATE,  
            @CardAddAcc  AS AddTaxAccNameOld, -- �ΰ�������Old  
            @CardAddAccSeq AS AddTaxAccSeqOld,-- �ΰ��������ڵ�Old  
            B.UMCardKind AS UMCardKind,  
            B1.ValueSeq AS CardCustSeq,  
            B2.CustName AS CardCustName,   
   R.MinorName AS UMCardKindName,  
            A.PURDATE,  -- �������� (��ö�������ҿ����� �������ڷ� ����)  
            A.TIP_AMT,  -- ��  
         T.MinorSeq AS UMCostType,  
            T.MinorName AS UMCostTypeName,  
            CASE WHEN ISNULL(A.TaxUnit,0) = 0 THEN S.TaxUnit ELSE A.TaxUnit END AS TaxUnit,  
            CASE WHEN ISNULL(A.EmpSeq,0) = 0 THEN 0 ELSE 1 END IsEmpSave,  
            CASE WHEN A.CustSeq IS NULL THEN 0 ELSE 1 END IsCustSave,  
            --�Ұ��������߰� 3�� �׸�  
            CASE WHEN A.Chain_Type IN (2,3) AND A.CostAmtDr IS NULL THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                                                                                             WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)        
                 WHEN ISNULL(A.CostAmtDr,0) = 0 THEN 
                 CASE WHEN ISNULL(A.SupplyAmt, 0) = 0 THEN (ABS(ISNULL(A.APPR_AMT, 0)) - ABS(ISNULL(A.APPR_TAX,0))) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                                                                                            WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
           WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1) + ISNULL(A.Tip_Amt,0)*(-1)    -- ���ް�����(+)�� ���࿡�� �Ѿ�� ��� 
                      WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1) + ISNULL(A.Tip_Amt,0)*(-1) 
                      ELSE A.SupplyAmt + ISNULL(A.Tip_Amt,0)  END -- CostAmtDr �ݾ��� ������ ���ް����� �������� �Ͱ� �����ϰ� ������.  
            ELSE A.CostAmtDr END AS CostAmtDr,  
            CASE WHEN A.Chain_Type IN (2,3)  THEN 0 
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN 0                  
            ELSE ISNULL(A.NotVatAmt,0) END AS NotVatAmt,  
            CASE WHEN A.Chain_Type IN (2,3)  THEN '' 
                 WHEN A.Chain_Type IN (2,3)  THEN 0 
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ''              
            ELSE ISNULL(A.NotVatSel,'') END AS NotVatSel,
            ISNULL(A.APPR_TIME,'') AS APPR_TIME,
            ISNULL(A.CURAMT ,0)  * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END) AS CURAMT  ,
            --ISNULL(A.STTL_DATE,'')         AS STTL_DATE,
            CASE WHEN ISNULL(A.STTL_DATE,'') <> '' 
                    THEN ISNULL(A.STTL_DATE,'')
                 WHEN ISNULL(A.STTL_DATE,'') = '' 
                    THEN 
                        CASE WHEN ISNULL(RIGHT(B.SttlLimitDay,2),'') = '' AND ISNULL(B.SttlDay,'') <> '' 
                                  THEN CASE WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) > CONVERT(INT,CONVERT(NCHAR(2), B.SttlDay))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 1, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay)
                                            ELSE LEFT(A.APPR_DATE,6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                       END
                             --�������� �����ѵ��Ϻ��� �����ΰ��
                             WHEN ISNULL(RIGHT(B.SttlLimitDay,2),'') <> '' AND ISNULL(B.SttlDay,'') <> '' 
                                  AND CONVERT(INT,CONVERT(NCHAR(2), B.SttlDay)) >= CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                  --�����ѵ��� ���� �����ΰ�� �ش���+������
                                  THEN CASE WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) <= CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                                THEN LEFT(A.APPR_DATE,6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                  --�����ѵ����� ������, ������ ������ ��� �ش���+1���� ������
                                            WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) > CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                                AND CONVERT(INT,RIGHT(A.APPR_DATE,2)) <= CONVERT(INT,CONVERT(NCHAR(2), B.SttlDay))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 1, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                  --������ ���Ŀ� ���ε� ��� �ش���+2���� ������
                                            WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) > CONVERT(INT,CONVERT(NCHAR(2), B.SttlDay))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 2, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                       END
                             --�������� �����ѵ��Ϻ��� ������ ���(�� ������ ����)
                             WHEN ISNULL(RIGHT(B.SttlLimitDay,2),'') <> '' AND ISNULL(B.SttlDay,'') <> '' 
                                  AND CONVERT(INT,CONVERT(NCHAR(2), B.SttlDay)) < CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                  --�����ѵ����� ������ ��� �ش���+1�� ������
                                  THEN CASE WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) <= CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 1, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                  --�����ѵ����� ������ ��� �ش���+2�� ������
                                            WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) > CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 2, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                       END
                         END   
            END  
            AS STTL_DATE,            
            CASE WHEN ISNULL(A.CHAIN_TYPE, '0') IN('0', '', '1', '4', '99') THEN '0'
                 ELSE '1'
            END                             AS IsDisVatYN ,
            ISNULL(AR.CodeHelpSeq   , 0)    AS MCodeHelpSeq    ,
            ISNULL(AR.CodeHelpParams, '')   AS MCodeHelpParams,
            ISNULL(A.DisSupplyAmt,0) AS DisSupplyAmt,
            B.SMComOrPriv           AS ComOrPriv,
            CP.MinorName            AS ComOrPrivName,
            CASE DW.SWeek0 WHEN '0' THEN '�Ͽ���'
                           WHEN '1' THEN '������'
                           WHEN '2' THEN 'ȭ����'
                           WHEN '3' THEN '������'
                           WHEN '4' THEN '�����'
                           WHEN '5' THEN '�ݿ���'
                           WHEN '6' THEN '�����'
            ELSE '' END AS DayOfTheWeek,
            IsNonVat,
            B.BizUnit,
            W.BizUnitName,
            X.PjtSeq AS PJTSeq,
            X.PjtName AS PJTName,
            ISNULL(A.LastDateTime,'') AS LastDateTime,
            ISNULL(A.LastUserSeq,0) AS LastUserSeq ,A.SERVTYPEYN,
            Z.MinorSeq AS ChannelSeq,
            ISNULL(Z.MinorName, '') AS ChannelName,
            --ISNULL(usr.UserName,'') AS LastUserName
            A.APPR_BUY_SEQ          AS APPR_BUY_SEQ,
            A.CHAIN_TYPE            AS CHAIN_TYPE,
           A.Dummy1,A.Dummy2,A.Dummy3,A.Dummy4,A.Dummy5,
           A.Dummy6,A.Dummy7,A.Dummy8,A.Dummy9,A.Dummy10, 
           --REPLACE(AA.CardNo,'-',''),
           --AA.ApprDate, 
           AA.ApprSeq 
           --AA.ApprNo
           INTO #TempResult
      FROM #TSIAFebCardCfm AS AA 
      LEFT OUTER JOIN _TSIAFebCardCfm   AS A ON ( A.CompanySeq = @CompanySeq 
                                              AND REPLACE(AA.CardNo,'-','') = A.CARD_CD 
                                              AND AA.ApprDate = A.APPR_DATE 
                                              AND AA.ApprSeq = A.APPR_SEQ 
                                              AND AA.ApprNo = A.APPR_No 
                                              AND AA.CANCEL_YN = A.CANCEL_YN
                                                ) 
                   JOIN #TDACard      AS B  ON B.CompanySeq = A.CompanySeq  
                                                       AND B.CardNo = A.CARD_CD
        LEFT OUTER JOIN _TDAUMinorValue  AS B1  ON B.CompanySeq = B1.CompanySeq    
                                                           AND B1.MinorSeq = B.UMCardKind  
                                                           AND B1.Serl = 1001  
                                                           AND B1.MajorSeq = 4004  
        LEFT OUTER JOIN _TDACust         AS B2  ON B1.CompanySeq = B2.CompanySeq    
                                                           AND B1.ValueSeq   = B2.CustSeq  
        LEFT OUTER JOIN #TCardUser       AS U               ON B.CardSeq    = U.CardSeq  
                                                           AND A.APPR_DATE BETWEEN U.StartDate AND U.EndDate  
        LEFT OUTER JOIN _TDAEmp     AS C  ON C.CompanySeq = A.CompanySeq  
                                                     AND C.EmpSeq     = CASE ISNULL(A.EmpSeq,0) WHEN 0 THEN U.EmpSeq ELSE A.EmpSeq END  
        LEFT OUTER JOIN (  
                            SELECT A.EmpSeq,   
                             A.DeptSeq,   
                                   A.OrdDate      AS DeptDateFr,   
                                   A.OrdEndDate   AS DeptDateTo,   
                                   CASE WHEN @EnvValue8929 = '1' THEN B.CCtrSeq ELSE '' END AS CCtrSeq,   
                                   ISNULL(B.BegYM, '190001') + '01' AS CCtrDateFr,   
                                   ISNULL(B.EndYM, '299912') + '31' AS CCtrDateTo  
                              FROM _THRADMOrdEmp AS A   
                                   LEFT OUTER JOIN _THROrgDeptCCtr AS B  ON A.CompanySeq = B.CompanySeq   
                                                                                    AND A.DeptSeq = B.DeptSeq  
                                                                                    AND (  A.OrdDate    BETWEEN B.BegYM + '01' AND B.EndYM + '31'   
                                                                                        OR A.OrdEndDate BETWEEN B.BegYM + '01' AND B.EndYM + '31')  
                             WHERE A.CompanySeq = @CompanySeq  
                               AND A.IsOrdDateLast = '1' AND ISNULL(B.IsLast, '1') = '1'
                         ) AS C1 ON C.EmpSeq = C1.EmpSeq   
                                AND A.APPR_DATE BETWEEN C1.DeptDateFr AND C1.DeptDateTo    
                                AND A.APPR_DATE BETWEEN C1.CCtrDateFr AND C1.CCtrDateTo 
        --left outer join _THRADMOrdEmp   AS C1 ON C.CompanySeq  = C1.CompanySeq and C.EmpSeq = C1.EmpSeq AND A.APPR_DATE BETWEEN C1.OrdDate AND C1.OrdEndDate AND C1.IsOrdDateLast = '1'  
        --left outer join _THROrgDeptCCtr AS C2 ON C1.CompanySeq = C2.CompanySeq and C1.DeptSeq = C2.DeptSeq AND A.APPR_DATE BETWEEN C2.BegYM + '01' AND C2.EndYM + '31'  
  
        LEFT OUTER JOIN _TDACust    AS D   ON D.CompanySeq  = A.CompanySeq  
                                                      AND D.CustSeq     = A.CustSeq  
        LEFT OUTER JOIN #TCustInfo  AS D1              ON REPLACE(A.CHAIN_ID, '-', '') = REPLACE(D1.BizNo, '-', '')
        LEFT OUTER JOIN _TDACust    AS D2  ON D2.CompanySeq = @CompanySeq  
                                                      AND D1.CustSeq    = D2.CustSeq  
        LEFT OUTER JOIN _TDAAccount AS E   ON E.CompanySeq  = A.CompanySeq  
                                                      AND E.AccSeq      = A.AccSeq  
        LEFT OUTER JOIN _TDADept    AS F   ON F.CompanySeq  = A.CompanySeq  
                                                      AND F.DeptSeq     = CASE ISNULL(A.DeptSeq,0) WHEN 0 THEN C1.DeptSeq ELSE A.DeptSeq END  
        LEFT OUTER JOIN _TDACCtr    AS G   ON G.CompanySeq  = A.CompanySeq  
               AND G.CCtrSeq     = CASE ISNULL(A.CCtrSeq,0) WHEN 0 THEN C1.CCtrSeq ELSE A.CCtrSeq END  
        LEFT OUTER JOIN _TACSlipRow AS H   ON A.CompanySeq  = H.CompanySeq  
                                                      AND A.SlipSeq     = H.SlipSeq  
        LEFT OUTER JOIN _TACSlip    AS P   ON H.CompanySeq  = P.CompanySeq  
                                                      AND H.SlipMstSeq  = P.SlipMstSeq  
        LEFT OUTER JOIN _TDAEvid    AS Q   ON A.CompanySeq  = Q.CompanySeq  
                                                      AND A.EvidSeq     = Q.EvidSeq  
        LEFT OUTER JOIN _TDAUMinor  AS R   ON A.CompanySeq  = R.CompanySeq  
                                                      AND R.MinorSeq    = B.UMCardKind  
                                                      AND R.MajorSeq    = 4004  
        -- ����ڹ�ȣ ��Ÿ������ ���� 2009.12.?? ������  
        LEFT OUTER JOIN _TDATaxUnit AS S WITH (NOLOCK) ON (S.CompanySeq = F.CompanySeq AND F.TaxUnit    = S.TaxUnit )  
        LEFT OUTER JOIN _TDAUMinor  AS T  ON A.CompanySeq = T.CompanySeq  
                                                     AND T.MinorSeq = CASE ISNULL(A.UMCostType,0) WHEN 0 THEN F.UMCostType ELSE A.UMCostType END   
        LEFT OUTER JOIN _TDAAccount AS V   ON A.CompanySeq = V.CompanySeq     AND A.VatAccSeq  = V.AccSeq 
        LEFT OUTER JOIN _TDASminor  AS CT  ON A.CompanySeq = CT.CompanySeq AND CT.MajorSeq = 8920 AND A.CHAIN_TYPE = RTRIM(LTRIM(CT.MinorValue))
        LEFT OUTER JOIN _TDAAccountRem AS AR  ON A.CompanySeq = AR.CompanySeq AND A.RemSeq = AR.RemSeq
        LEFT OUTER JOIN ( SELECT A.SlipSeq, B.RemSeq, B.RemValSeq
                            FROM _TACSlipRow AS A 
                            JOIN _TACSlipRem AS B  ON A.CompanySeq = B.CompanySeq
                                          AND A.SlipSeq = B.SlipSeq
                           WHERE A.CompanySeq = @CompanySeq   
                        ) AS Slip ON A.SlipSeq = Slip.SlipSeq
                                 AND A.RemSeq = Slip.RemSeq
                                 AND A.RemSeq <> 0
        LEFT OUTER JOIN _TDAAccountRemValue AS ARV1  ON A.CompanySeq = ARV1.CompanySeq AND Slip.RemSeq = ARV1.RemSeq AND Slip.RemValSeq = ARV1.RemValueSerl
        LEFT OUTER JOIN _TDAAccountRemValue AS ARV2  ON A.CompanySeq = ARV2.CompanySeq AND A.RemSeq = ARV2.RemSeq AND A.RemValueSeq = ARV2.RemValueSerl
        LEFT OUTER JOIN _TDASMinor AS CP  ON A.CompanySeq   = CP.CompanySeq AND B.SMComOrPriv   = CP.MinorSeq AND CP.MajorSeq = 4019
        LEFT OUTER JOIN _TCOMCalendar AS DW  ON DW.Solar = A.APPR_DATE
        LEFT OUTER JOIN _TDABizUnit AS W  ON B.CompanySeq = W.CompanySeq AND B.BizUnit = W.BizUnit
        LEFT OUTER JOIN _TPjtProject AS X  ON A.CompanySeq = X.CompanySeq AND A.PJTSeq = X.PJTSeq
        LEFT OUTER JOIN _TDACustClass AS Y  ON A.CompanySeq = Y.CompanySeq AND D2.CustSeq = Y.CustSeq AND Y.UMajorCustClass = 8004
        LEFT OUTER JOIN _TDAUMinor AS Z  ON A.CompanySeq = Z.CompanySeq AND Y.UMCustClass = Z.MinorSeq
    
    UNION   
    
    -- ī���ȣ�� ��ϵǾ� �ִµ� ����ڰ� ��ϵǾ� ���� �ʰų�, ������� ��볯¥ ������ �͵� ������ ������ ����ڸ� �� �������� ��   
    SELECT  CASE WHEN ISNULL(A.SlipSeq, 0) <> 0 OR ISNULL(A.ERPKey, '') <> '' THEN 'ó��' ELSE '��ó��' END AS ProcType,   -- ó����Ȳ  
            --dbo._FCOMDecrypt(B.CardNo, '_TDACard', 'CardNo', @CompanySeq)                 AS CARD_CD,              -- ī���ȣ  
            B.CardNo                 AS CARD_CD,             -- ī���ȣ
            B.CardName               AS CardName,            -- ī���
            A.APPR_DATE              AS APPR_DATE,            -- ��������  
            A.APPR_NO                AS ApprNo,              -- ���ι�ȣ  
            A.CHAIN_NM               AS ChainName,           -- ��������  
            A.CHAIN_ID               AS ChainBizNo,          -- ������ ����ڹ�ȣ  
   ISNULL(CT.MinorName, '��Ȯ��')    AS ChainType,
            ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)     AS ApprAmt,             -- ���αݾ�  
            ISNULL(ABS(A.APPR_TAX),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)     AS ApprTax,             -- ���αݾ׺ΰ���ġ��  
            CASE WHEN A.Chain_Type IN (2,3) AND SupplyAmt IS NULL THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)
                --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)            
                 WHEN (ISNULL(A.SupplyAmt, 0) = 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) - ABS(ISNULL(A.APPR_TAX,0))) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
        WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1) -- ���ް�����(+)�� ���࿡�� �Ѿ�� ��� 
                 WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1)
                 ELSE A.SupplyAmt  
            END  AS SupplyAmt,           -- ���ް���  
            CASE WHEN A.Chain_Type IN (2,3) THEN 0
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN 0
                 WHEN ISNULL(A.NotVatSel,'') <> '1' THEN   
                 CASE WHEN ISNULL(A.SupplyAmt, 0) = 0 THEN ABS(ISNULL(A.APPR_TAX,0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
          WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) * (-1) - A.SupplyAmt * (-1)) -- ���ް�����(+)�� ���࿡�� �Ѿ�� ���   
                      WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) * (-1) - A.SupplyAmt * (-1))
                      ELSE (ABS(ISNULL(A.APPR_AMT, 0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                               WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)) - ISNULL(A.SupplyAmt,ABS(ISNULL(A.APPR_AMT, 0) - ISNULL(A.APPR_TAX,0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                     WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END))  
                 END - ISNULL(A.DisSupplyAmt,0) - ISNULL(A.Tip_Amt,0)   
            ELSE 0 END   AS UpdateVat ,          -- �����ΰ���  
            CASE WHEN A.Chain_Type IN (2,3) AND SupplyAmt IS NULL THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END) 
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)                 
                ELSE
                CASE WHEN (ISNULL(A.SupplyAmt, 0) = 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) - ABS(ISNULL(A.APPR_TAX,0))) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
            WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1) -- ���ް�����(+)�� ���࿡�� �Ѿ�� ��� 
                     WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1)
                     ELSE A.SupplyAmt  
                END  +         -- ���ް���  
                CASE WHEN A.Chain_Type IN (2,3) THEN 0
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN 0
                 WHEN ISNULL(A.NotVatSel,'') <> '1' THEN   
                     CASE WHEN ISNULL(A.SupplyAmt, 0) = 0 THEN ABS(ISNULL(A.APPR_TAX,0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
              WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) * (-1) - A.SupplyAmt * (-1)) -- ���ް�����(+)�� ���࿡�� �Ѿ�� ���   
                          WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) * (-1) - A.SupplyAmt * (-1))
                          ELSE (ABS(ISNULL(A.APPR_AMT, 0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                                   WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)) - ISNULL(A.SupplyAmt,(ABS(ISNULL(A.APPR_AMT, 0)) - ABS(ISNULL(A.APPR_TAX,0))) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                                                                                                                                                                     WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END))  
                     END    
                ELSE 0 END
            END AS TotalAmt ,          -- �հ�ݾ�  
 
            A.AccSeq                 AS AccSeq,              -- �����ڵ�  
            A.AccSeq                 AS AccSeqOld,           -- �����ڵ�
            A.HALBU                  AS HALBU,               -- �ҺαⰣ
            A.RemSeq                 AS RemSeq,              -- �����׸�
            AR.RemName               AS RemName,             -- �����׸��
            CASE WHEN ARV1.RemValueName IS NULL THEN ARV2.RemValueName ELSE ARV1.RemValueName END       AS RemValue,            -- �����׸�
            A.RemValueSeq            AS RemValueSeq,         -- �����׸��ڵ�
            A.CANCEL_YN,    -- ������ҿ��� Ű  
            CASE A.CANCEL_YN WHEN '3' THEN (CASE WHEN A.BUYING_DIST IN ('02', '04') THEN '���'
                                                 WHEN A.BUYING_DIST = '06' THEN 'ȯ��' END)     --��ȯ���� �߰�
                             WHEN 'Y' THEN '���'  
                             ELSE '����'  
            END  AS CancelYN,  -- ������ҿ���  
            E.AccName                AS AccName,             -- �߻�����  
            A.Remark                 AS Remark,              -- ���1  
            C.EmpName                AS EmpName,             -- ���  
            CASE WHEN ISNULL(D.CustName,'') = '' THEN D2.CustName ELSE D.CustName END AS CustName,      -- �ŷ�ó  
            CASE WHEN ISNULL(A.CustSeq, 0) = 0   THEN D1.CustSeq  ELSE A.CustSeq  END AS CustSeq,       -- �ŷ�ó�ڵ�  
            CASE WHEN ISNULL(A.ERPKey,'') = ''   THEN H.SlipID    ELSE A.ERPKey   END AS ERPKey,        -- ��ǥ��ȣ  
            A.SlipSeq    ,                                   -- �߻���ǥ�ڵ�  
            C.EmpSeq    AS EmpSeq     ,        -- ���  
            A.APPR_SEQ  AS APPR_SEQ,            -- ���μ���  
            B.CardSeq,  
            G.CCtrName,  
            G.CCtrSeq AS CCtrSeq,  
            F.DeptName,  
            F.Deptseq AS DeptSeq,  
            CASE B.SMComOrPriv  
                WHEN 4019001 THEN @JuridCardAcc  
                WHEN 4019002 THEN @IndivCardAcc  
            END         AS CrAccName, --' ������ -�����ޱ�(ī��)' AS OutAccNm,  
            CASE B.SMComOrPriv  
                WHEN 4019001 THEN @JuridCardAccSeq  
                WHEN 4019002 THEN @IndivCardAccSeq  
            END         AS CrAccSeq,     -- �������ڵ�  
            CASE WHEN A.Chain_Type IN (2,3) THEN '0'
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN '0'            
                 WHEN ((A.VatSel IS NULL OR A.VatSel = '') AND (A.VatYN = 'Y' OR ISNULL(A.APPR_TAX,0) <> 0)) THEN '1' ELSE A.VatSel END AS VatSel, -- �ΰ�������  
            CASE WHEN A.Chain_Type IN (2,3) THEN '0'
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN '0'             
                 WHEN A.VatYN = 'Y' THEN '1'  
                 WHEN A.VatYN = 'N' THEN '0'  
            END AS VATYN,        --�ΰ���ȯ�޴�󿩺�   
            CASE WHEN A.Chain_Type IN (2,3) THEN ''
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ''             
                 WHEN (A.VatSel = '1' OR ((A.VatSel IS NULL OR A.VatSel = '') AND (A.VatYN = 'Y' OR ISNULL(A.APPR_TAX,0) <> 0)))  THEN @CardAddAcc 
                 WHEN A.IsNonVat = '1' THEN @CardAddAcc 
      ELSE '' END AS VatSttlItem, -- �ΰ�������  ,
            CASE WHEN A.Chain_Type IN (2,3) THEN 0
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN 0             
                 WHEN (A.VatSel = '1' OR ((A.VatSel IS NULL OR A.VatSel = '') AND (A.VatYN = 'Y' OR ISNULL(A.APPR_TAX,0) <> 0)))  THEN @CardAddAccSeq ELSE '' END AS AddTaxAccSeq, -- �ΰ��������ڵ�  
            A.IsDefine,  
            A.EvidSeq,  
            Q.EvidName,  
            CASE WHEN ISNULL(A.ModDate,'') = '' THEN A.APPR_DATE ELSE A.ModDate END AS ModDate,  
            A.EvidSeq,  
            Q.EvidName,  
            A.MASTER,  
            ISNULL((CASE WHEN CHARINDEX('-',A.MERCHZIPCODE) <> 0 THEN A.MERCHZIPCODE ELSE LEFT(A.MERCHZIPCODE,3) + '-' + RIGHT(A.MERCHZIPCODE,3) END ),'')   AS MERCHZIPCODE,  
            A.MERCHADDR1,  
            A.MERCHADDR2,  
             A.APPRTOT * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END),  
            A.MCCNAME,  
            A.MCCCODE,  
            A.TAXTYPE,  
            A.MERCHCESSDATE,  
            @CardAddAcc  AS AddTaxAccNameOld, -- �ΰ�������Old  
            @CardAddAccSeq AS AddTaxAccSeqOld,-- �ΰ��������ڵ�Old  
            B.UMCardKind AS UMCardKind,  
            B1.ValueSeq AS CardCustSeq,  
            B2.CustName AS CardCustName,  
            R.MinorName AS UMCardKindName,  
            A.PURDATE,  -- �������� (��ö�������ҿ����� �������ڷ� ����)  
            A.TIP_AMT,  -- ��  
            T.MinorSeq AS UMCostType,  
            T.MinorName AS UMCostTypeName,  
            CASE WHEN ISNULL(A.TaxUnit,0) = 0 THEN S.TaxUnit ELSE A.TaxUnit END AS TaxUnit,  
            --A.TaxNo  
            CASE WHEN A.EmpSeq IS NULL THEN 0 ELSE 1 END IsEmpSave,  
            CASE WHEN A.CustSeq IS NULL THEN 0 ELSE 1 END IsCustSave,  
            --�Ұ��������߰� 3�� �׸�  
            CASE WHEN A.Chain_Type IN (2,3) AND A.CostAmtDr IS NULL THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                                                                                             WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)        
                 WHEN ISNULL(A.CostAmtDr,0) = 0 THEN 
                 CASE WHEN ISNULL(A.SupplyAmt, 0) = 0 THEN (ABS(ISNULL(A.APPR_AMT, 0)) - ABS(ISNULL(A.APPR_TAX,0))) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                                                                                            WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
           WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1) + ISNULL(A.Tip_Amt,0)*(-1)    -- ���ް�����(+)�� ���࿡�� �Ѿ�� ��� 
           WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1) + ISNULL(A.Tip_Amt,0)*(-1) 
                      ELSE A.SupplyAmt + ISNULL(A.Tip_Amt,0)  END -- CostAmtDr �ݾ��� ������ ���ް����� �������� �Ͱ� �����ϰ� ������.  
            ELSE A.CostAmtDr END AS CostAmtDr,  
            CASE WHEN A.Chain_Type IN (2,3) THEN 0 
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN 0                  
            ELSE ISNULL(A.NotVatAmt,0) END AS NotVatAmt,  
            CASE WHEN A.Chain_Type IN (2,3)  THEN '' 
                 WHEN A.Chain_Type IN (2,3)  THEN 0 
                 --ȯ�漳�� �ݾ� ���ϰ� ���� ��ȸ�� �ΰ���üũ ���� ó��
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ''              
            ELSE ISNULL(A.NotVatSel,'') END AS NotVatSel,
            ISNULL(A.APPR_TIME,'') AS APPR_TIME,
            ISNULL(A.CURAMT ,0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END) AS CURAMT, 
            --ISNULL(A.STTL_DATE,'')         AS STTL_DATE,
            CASE WHEN ISNULL(A.STTL_DATE,'') <> '' 
                    THEN ISNULL(A.STTL_DATE,'')
                 WHEN ISNULL(A.STTL_DATE,'') = '' 
                    THEN 
                        CASE WHEN ISNULL(RIGHT(B.SttlLimitDay,2),'') = '' AND ISNULL(B.SttlDay,'') <> '' 
                                  THEN CASE WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) > CONVERT(INT,CONVERT(NCHAR(2), B.SttlDay))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 1, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay)
                                            ELSE LEFT(A.APPR_DATE,6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                       END
                             --�������� �����ѵ��Ϻ��� �����ΰ��
                             WHEN ISNULL(RIGHT(B.SttlLimitDay,2),'') <> '' AND ISNULL(B.SttlDay,'') <> '' 
                                  AND CONVERT(INT,CONVERT(NCHAR(2), B.SttlDay)) >= CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                  --�����ѵ��� ���� �����ΰ�� �ش���+������
            THEN CASE WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) <= CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                                THEN LEFT(A.APPR_DATE,6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                  --�����ѵ����� ������, ������ ������ ��� �ش���+1���� ������
                                            WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) > CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                                AND CONVERT(INT,RIGHT(A.APPR_DATE,2)) <= CONVERT(INT,CONVERT(NCHAR(2), B.SttlDay))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 1, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                  --������ ���Ŀ� ���ε� ��� �ش���+2���� ������
                                            WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) > CONVERT(INT,CONVERT(NCHAR(2),  B.SttlDay))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 2, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                       END
                             --�������� �����ѵ��Ϻ��� ������ ���(�� ������ ����)
                             WHEN ISNULL(RIGHT(B.SttlLimitDay,2),'') <> '' AND ISNULL(B.SttlDay,'') <> '' 
                                  AND CONVERT(INT,CONVERT(NCHAR(2), B.SttlDay)) < CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                  --�����ѵ����� ������ ��� �ش���+1�� ������
                                  THEN CASE WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) <= CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 1, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                  --�����ѵ����� ������ ��� �ش���+2�� ������
                                            WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) > CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 2, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                       END
                         END   
            END  
            AS STTL_DATE,  
            CASE WHEN ISNULL(A.CHAIN_TYPE, '0') IN('0', '', '1', '4', '99') THEN '0'
            ELSE '1' END AS IsDisVatYN,
            ISNULL(AR.CodeHelpSeq   , 0) AS MCodeHelpSeq    ,
            ISNULL(AR.CodeHelpParams, '') AS MCodeHelpParams,
            ISNULL(A.DisSupplyAmt,0) AS DisSupplyAmt  ,
            B.SMComOrPriv           AS ComOrPriv,
            CP.MinorName            AS ComOrPrivName,
            CASE DW.SWeek0 WHEN '0' THEN '�Ͽ���'
                           WHEN '1' THEN '������'
                           WHEN '2' THEN 'ȭ����'
                           WHEN '3' THEN '������'
                           WHEN '4' THEN '�����'
                           WHEN '5' THEN '�ݿ���'
                           WHEN '6' THEN '�����'
            ELSE '' END AS DayOfTheWeek,
            A.IsNonVat,
            B.BizUnit,
            W.BizUnitName,
            X.PjtSeq AS PJTSeq,
            X.PjtName AS PJTName,
            ISNULL(A.LastDateTime,'') AS LastDateTime,
            ISNULL(A.LastUserSeq,0) AS LastUserSeq, A.SERVTYPEYN,
            Z.MinorSeq AS ChannelSeq,
            ISNULL(Z.MinorName, '') AS ChannelName,
            --ISNULL(usr.UserName,'') AS LastUserName                   
            A.APPR_BUY_SEQ          AS APPR_BUY_SEQ,
            A.CHAIN_TYPE            AS CHAIN_TYPE,
           A.Dummy1,A.Dummy2,A.Dummy3,A.Dummy4,A.Dummy5,
           A.Dummy6,A.Dummy7,A.Dummy8,A.Dummy9,A.Dummy10, 
           --REPLACE(AA.CardNo,'-',''),
           --AA.ApprDate, 
           AA.ApprSeq 
           --AA.ApprNo
           
      FROM #TSIAFebCardCfm AS AA 
      LEFT OUTER JOIN _TSIAFebCardCfm   AS A ON ( A.CompanySeq = @CompanySeq 
                                              AND REPLACE(AA.CardNo,'-','') = A.CARD_CD 
                                              AND AA.ApprDate = A.APPR_DATE 
                                              AND AA.ApprSeq = A.APPR_SEQ 
                                              AND AA.ApprNo = A.APPR_No 
                                              AND AA.CANCEL_YN = A.CANCEL_YN
                                                ) 
                 JOIN #TDACard          AS B  ON ( B.CompanySeq = A.CompanySeq AND B.CardNo = A.CARD_CD ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS B1 ON B.CompanySeq = B1.CompanySeq    
                                                           AND B1.MinorSeq = B.UMCardKind  
                                                           AND B1.Serl = 1001  
                                                           AND B1.MajorSeq = 4004  
      LEFT OUTER JOIN _TDACust          AS B2 ON B1.CompanySeq = B2.CompanySeq AND B1.ValueSeq = B2.CustSeq  
                 JOIN _TDAEmp           AS C  ON C.CompanySeq = A.CompanySeq AND C.EmpSeq = A.EmpSeq  
      LEFT OUTER JOIN (  
                            SELECT A.EmpSeq,   
                             A.DeptSeq,   
                                   A.OrdDate      AS DeptDateFr,   
                                   A.OrdEndDate   AS DeptDateTo,   
                                   CASE WHEN @EnvValue8929 = '1' THEN B.CCtrSeq ELSE '' END AS CCtrSeq,   
                                   ISNULL(B.BegYM, '190001') + '01' AS CCtrDateFr,   
                                   ISNULL(B.EndYM, '299912') + '31' AS CCtrDateTo  
                              FROM _THRADMOrdEmp AS A   
                                   LEFT OUTER JOIN _THROrgDeptCCtr AS B  ON A.CompanySeq = B.CompanySeq   
                                                                                    AND A.DeptSeq = B.DeptSeq  
                                                                                    AND (  A.OrdDate    BETWEEN B.BegYM + '01' AND B.EndYM + '31'   
                                                                                        OR A.OrdEndDate BETWEEN B.BegYM + '01' AND B.EndYM + '31')  
                             WHERE A.CompanySeq = @CompanySeq  
                               AND A.IsOrdDateLast = '1' AND ISNULL(B.IsLast, '1') = '1'  
                         ) AS C1 ON C.EmpSeq = C1.EmpSeq   
                                AND A.APPR_DATE BETWEEN C1.DeptDateFr AND C1.DeptDateTo  
                                AND A.APPR_DATE BETWEEN C1.CCtrDateFr AND C1.CCtrDateTo                                 
        LEFT OUTER JOIN _TDACust    AS D   ON D.CompanySeq = A.CompanySeq  
                                                      AND D.CustSeq    = A.CustSeq  
        LEFT OUTER JOIN #TCustInfo  AS D1              ON REPLACE(A.CHAIN_ID, '-', '') = REPLACE(D1.BizNo, '-', '')
        LEFT OUTER JOIN _TDACust    AS D2  ON D2.CompanySeq = @CompanySeq  
                                                      AND D1.CustSeq    = D2.CustSeq  
        LEFT OUTER JOIN _TDAAccount AS E  ON E.CompanySeq = A.CompanySeq  
                                                     AND E.AccSeq     = A.AccSeq  
        LEFT OUTER JOIN _TDADept    AS F  ON F.CompanySeq = A.CompanySeq  
                                                     AND F.DeptSeq    = CASE ISNULL(A.DeptSeq,0) WHEN 0 THEN C1.DeptSeq ELSE A.DeptSeq END  
        LEFT OUTER JOIN _TDACCtr    AS G  ON G.CompanySeq = A.CompanySeq  
                                                     AND G.CCtrSeq    = CASE ISNULL(A.CCtrSeq,0) WHEN 0 THEN C1.CCtrSeq ELSE A.CCtrSeq END  
        LEFT OUTER JOIN _TACSlipRow AS H  ON A.CompanySeq = H.CompanySeq  
                                                     AND A.SlipSeq    = H.SlipSeq  
        LEFT OUTER JOIN _TACSlip    AS P  ON H.CompanySeq = P.CompanySeq  
                                                     AND H.SlipMstSeq = P.SlipMstSeq  
        LEFT OUTER JOIN _TDAEvid    AS Q  ON A.CompanySeq = Q.CompanySeq  
                                                     AND A.EvidSeq    = Q.EvidSeq  
        left outer join _TDAUMinor  AS R  ON A.CompanySeq = R.CompanySeq  
                                                     AND R.MinorSeq = B.UMCardKind  
                                                     AND R.MajorSeq = 4004  
        -- ����ڹ�ȣ ��Ÿ������ ���� 2009.12.?? ������  
        LEFT OUTER JOIN _TDATaxUnit AS S WITH (NOLOCK) ON (S.CompanySeq = F.CompanySeq AND F.TaxUnit    = S.TaxUnit )  
        left outer join _TDAUMinor  AS T  ON A.CompanySeq = T.CompanySeq  
                                                     AND T.MinorSeq = CASE ISNULL(A.UMCostType,0) WHEN 0 THEN F.UMCostType ELSE A.UMCostType END   
        LEFT OUTER JOIN _TDAAccount AS V  ON A.CompanySeq = V.CompanySeq  
                                                     AND A.VatAccSeq  = V.AccSeq  
        LEFT OUTER JOIN _TDASminor AS CT  ON A.CompanySeq = CT.CompanySeq AND CT.MajorSeq = 8920 AND ISNULL(A.CHAIN_TYPE, '0') = RTRIM(LTRIM(CT.MinorValue))
        LEFT OUTER JOIN _TDAAccountRem AS AR  ON A.CompanySeq = AR.CompanySeq AND A.RemSeq = AR.RemSeq
        LEFT OUTER JOIN ( SELECT A.SlipSeq, B.RemSeq, B.RemValSeq
                            FROM _TACSlipRow AS A 
                            JOIN _TACSlipRem AS B  ON A.CompanySeq = B.CompanySeq
                                          AND A.SlipSeq = B.SlipSeq
                           WHERE A.CompanySeq = @CompanySeq   
                        ) AS Slip ON A.SlipSeq = Slip.SlipSeq
                                 AND A.RemSeq = Slip.RemSeq
                                 AND A.RemSeq <> 0
        LEFT OUTER JOIN _TDAAccountRemValue AS ARV1  ON A.CompanySeq = ARV1.CompanySeq AND Slip.RemSeq = ARV1.RemSeq AND Slip.RemValSeq = ARV1.RemValueSerl
        LEFT OUTER JOIN _TDAAccountRemValue AS ARV2  ON A.CompanySeq = ARV2.CompanySeq AND A.RemSeq = ARV2.RemSeq AND A.RemValueSeq = ARV2.RemValueSerl
        LEFT OUTER JOIN _TDASMinor AS CP  ON A.CompanySeq   = CP.CompanySeq AND B.SMComOrPriv   = CP.MinorSeq AND CP.MajorSeq = 4019    
        LEFT OUTER JOIN _TCOMCalendar AS DW  ON DW.Solar = A.APPR_DATE
        LEFT OUTER JOIN _TDABizUnit AS W  ON A.CompanySeq = W.CompanySeq AND B.BizUnit = W.BizUnit
        LEFT OUTER JOIN _TPjtProject AS X  ON A.CompanySeq = X.CompanySeq AND A.PJTSeq = X.PJTSeq
        LEFT OUTER JOIN _TDACustClass AS Y  ON A.CompanySeq = Y.CompanySeq AND D2.CustSeq = Y.CustSeq AND Y.UMajorCustClass = 8004
        LEFT OUTER JOIN _TDAUMinor AS Z  ON A.CompanySeq = Z.CompanySeq AND Y.UMCustClass = Z.MinorSeq
     ORDER BY ApprDate, CardNo, ApprNo  
    
    SELECT * FROM #TempResult
    
RETURN
GO 
begin tran 
exec KPX_SARBizTripCostJumpOut @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>7</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <CardNo>4336927028349406</CardNo>
    <ApprDate>20080805</ApprDate>
    <ApprNo>36949294</ApprNo>
    <ApprSeq>1</ApprSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <CardNo>4336927028349406</CardNo>
    <ApprDate>20080805</ApprDate>
    <ApprNo>75868955</ApprNo>
    <ApprSeq>3</ApprSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027319,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=857
rollback 