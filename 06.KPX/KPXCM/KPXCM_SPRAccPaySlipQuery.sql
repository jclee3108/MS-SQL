IF OBJECT_ID('KPXCM_SPRAccPaySlipQuery') IS NOT NULL 
    DROP PROC KPXCM_SPRAccPaySlipQuery
GO 

-- v2015.11.12 

/************************************************************************************************
  ��    �� - ȸ��ó���޻󿩳��� ��ȸ
  �� �� �� - 2008.12.00 :
  �� �� �� - CREATEd by
  �������� - �޿������� �߰�(2012.05.21)
 *************************************************************************************************/
  -- SP�Ķ���͵�
 CREATE PROCEDURE KPXCM_SPRAccPaySlipQuery
     @xmlDocument NVARCHAR(MAX)    ,    -- : ȭ���� ������ XML�� ����
     @xmlFlags    INT = 0          ,    -- : �ش� XML�� Type
     @ServiceSeq  INT = 0          ,    -- : ���� ��ȣ
     @WorkingTag  NVARCHAR(10) = '',    -- : WorkingTag
     @CompanySeq  INT = 1          ,    -- : ȸ�� ��ȣ
     @LanguageSeq INT = 1          ,    -- : ��� ��ȣ
     @UserSeq     INT = 0          ,    -- : ����� ��ȣ
     @PgmSeq      INT = 0               -- : ���α׷� ��ȣ
  AS
      -- ����� ������ �����Ѵ�.
     DECLARE @docHandle INT     ,
             @EnvValue  INT     ,
             @AccUnit   INT     ,
             @PuSeq     INT     ,
             @PbYM      NCHAR(6),
             @SerialNo  INT     ,
             @Sql       NVARCHAR(4000)
  
      -- XML�Ľ�
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    -- @xmlDocument�� XML�� @docHandle�� �ڵ��Ѵ�.
      SELECT @EnvValue = ISNULL(EnvValue,  0),    -- ��������
            @AccUnit  = ISNULL(AccUnit ,  0),    -- ȸ�����
            @PuSeq    = ISNULL(PuSeq   ,  0),    -- �޿��۾���
            @PbYM     = ISNULL(PbYM    , ''),    -- ���뿬��
            @SerialNo = ISNULL(SerialNo,  0)     -- �Ϸù�ȣ
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    -- XML�� DataBlock1���κ���
       WITH (EnvValue INT     ,
             AccUnit  INT     ,
             PuSeq    INT     ,
             PbYM     NCHAR(6),
             SerialNo INT
            )
  
      -- ��Ʈ��ȸ
     SELECT A.Seq               AS Seq,             -- ���ȣ
            A.PbYM              AS PbYM,            -- ������
            A.PuSeq             AS PuSeq,           -- �޿��۾���
            (SELECT PUName FROM _TPRBasPu WHERE  CompanySeq = A.CompanySeq AND PuSeq = A.PuSeq) AS PuName,
            A.SerialNo          AS SerialNo,        -- �Ϸù�ȣ
            C.AccUnit           AS AccUnit,         -- ȸ�����
            (SELECT AccUnitName FROM _TDAAccUnit WITH(NOLOCK) WHERE CompanySeq = A.CompanySeq AND AccUnit = C.AccUnit) AS AccUnitName,          -- ȸ�������
            A.SlipUnit          AS SlipUnit,        -- ��ǥ���������ڵ�
            (SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = A.CompanySeq AND SlipUnit = A.SlipUnit) AS SlipUnitName,     -- ��ǥ��������
            A.RowSlipUnit       AS RowSlipUnit,     -- �ະ��ǥ��������
            (SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = A.CompanySeq AND SlipUnit = A.RowSlipUnit) AS RowSlipUnitName, -- �ະ��ǥ��������
            A.AccSeq            AS AccSeq,          -- ���������ڵ�
            B.AccName           AS AccName,         -- ��������
            A.UMCostType        AS UMCostType,      -- ��뱸��
            (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.UMCostType) AS UMCostTypeName,                   -- ��뱸��
            A.SMDrOrCr          AS SMDrOrCr,        -- ���뱸��
            (SELECT MinorName FROM _TDASMinor WHERE CompanySeq = A.CompanySeq AND MinorValue = A.SMDrOrCr AND MajorSeq = 4001) AS SMDrOrCrName, -- ���뱸��
            A.DrAmt             AS DrAmt,           -- �����ݾ�
            A.CrAmt             AS CrAmt,           -- �뺯�ݾ�
            A.DrForAmt          AS DrForAmt,        -- ��ȭ�����ݾ�
            A.CrForAmt          AS CrForAmt,        -- ��ȭ�뺯�ݾ�
            A.SlipDeptSeq       AS SlipDeptSeq,     -- ����μ��ڵ�
             CASE WHEN @EnvValue = 5518003 THEN
                      (SELECT DetlDeptName FROM _TPEACDetlBizSubDept WHERE CompanySeq = A.CompanySeq AND Seq = A.SlipDeptSeq )
                 ELSE
                      (SELECT DeptName FROM _TDADept WHERE CompanySeq = A.CompanySeq AND DeptSeq = A.SlipDeptSeq) 
            END AS SlipDeptName,    -- ����μ�
            A.CostDeptSeq       AS CostDeptSeq,     -- �ͼӺμ��ڵ�
            (SELECT DeptName FROM _TDADept WHERE CompanySeq  = A.CompanySeq AND DeptSeq = A.CostDeptSeq) AS CostDeptName,    -- �ͼӺμ�
            A.SlipCCtrSeq       AS SlipCCtrSeq,     -- ����Ȱ�������ڵ�
            CASE WHEN @EnvValue = 5518003 THEN
                      (SELECT DetlDeptName FROM _TPEACDetlBizSubDept WHERE CompanySeq = A.CompanySeq AND Seq = A.SlipCCtrSeq )
                 ELSE
                      (SELECT CCtrName FROM _TDACCtr WHERE CompanySeq = A.CompanySeq AND CCtrSeq = A.SlipCCtrSeq)
            END AS SlipCCtrName,    -- ����Ȱ������
            A.CostCCtrSeq       AS CostCCtrSeq,     -- �ͼ�Ȱ�������ڵ�
            (SELECT CCtrName FROM _TDACCtr WHERE CompanySeq = A.CompanySeq AND CCtrSeq = A.CostCCtrSeq) AS CostCCtrName,    -- �ͼ�Ȱ������
            A.DeptSeq           AS DeptSeq,         -- �߻��μ��ڵ�
            (SELECT DeptName FROM _TDADept WHERE CompanySeq = A.CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,            -- �߻��μ�
            A.DtlSeq            AS DtlSeq,          -- �߻���õ�ڵ�
            CASE WHEN A.EnvValue = 5518002 THEN 
                      (SELECT CCtrName FROM _TDACCtr WHERE CompanySeq = A.CompanySeq AND CCtrSeq = A.DtlSeq)
                 ELSE
                      (SELECT DeptName FROM _TDADept WHERE CompanySeq = A.CompanySeq AND DeptSeq = A.DtlSeq)
             END                 AS DtlName,        -- �߻���õ
            A.BgtSeq            AS BgtSeq,          -- ������񳻺��ڵ�
            (SELECT BgtName FROM _TACBgtItem WHERE CompanySeq = A.CompanySeq AND BgtSeq = A.BgtSeq) AS BgtName,         -- �������
            A.CurrSeq           AS CurrSeq,         -- ��ȭ�����ڵ�
            (SELECT CurrName FROM _TDACurr WHERE CompanySeq = A.CompanySeq AND CurrSeq = A.CurrSeq) AS CurrName,        -- ��ȭ
            A.ExRate            AS ExRate,          -- ȯ��
            A.RemSeq1           AS RemSeq1,         -- �����׸񳻺��ڵ�1
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq1) AS RemName1,    -- �����׸�1
            A.RemValSeq1        AS RemValSeq1,      -- �����׸񳻺��ڵ尪1
            SPACE(200)          AS RemValName1,     -- �����׸�1
            A.RemValText1       AS RemValText1,     -- �����׸��ؽ�Ʈ��1
            A.RemSeq2           AS RemSeq2,         -- �����׸񳻺��ڵ�2
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq2) AS RemName2,    -- �����׸�2
            A.RemValSeq2        AS RemValSeq2,      -- �����׸񳻺��ڵ尪2
            SPACE(200)          AS RemValName2,     -- �����׸�2
            A.RemValText2       AS RemValText2,     -- �����׸��ؽ�Ʈ��2
            A.RemSeq3           AS RemSeq3,         -- �����׸񳻺��ڵ�3
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq3) AS RemName3,    -- �����׸�3
            A.RemValSeq3        AS RemValSeq3,      -- �����׸񳻺��ڵ尪3
            SPACE(200)          AS RemValName3,     -- �����׸�3
            A.RemValText3       AS RemValText3,     -- �����׸��ؽ�Ʈ��3
            A.RemSeq4           AS RemSeq4,         -- �����׸񳻺��ڵ�4
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq4) AS RemName4,    -- �����׸�4
            A.RemValSeq4        AS RemValSeq4,      -- �����׸񳻺��ڵ尪4
            SPACE(200)          AS RemValName4,     -- �����׸�4
            A.RemValText4       AS RemValText4,     -- �����׸��ؽ�Ʈ��4
            A.RemSeq5           AS RemSeq5,         -- �����׸񳻺��ڵ�5
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq5) AS RemName5,    -- �����׸�5
            A.RemValSeq5        AS RemValSeq5,      -- �����׸񳻺��ڵ尪5
            SPACE(200)          AS RemValName5,     -- �����׸�5
            A.RemValText5       AS RemValText5,     -- �����׸��ؽ�Ʈ��5
            A.RemSeq6           AS RemSeq6,         -- �����׸񳻺��ڵ�6
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq6) AS RemName6,    -- �����׸�6
            A.RemValSeq6        AS RemValSeq6,      -- �����׸񳻺��ڵ尪6
            SPACE(200)          AS RemValName6,     -- �����׸�6
            A.RemValText6       AS RemValText6,     -- �����׸��ؽ�Ʈ��6
            A.RemSeq7           AS RemSeq7,         -- �����׸񳻺��ڵ�7
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq7) AS RemName7,    -- �����׸�7
            A.RemValSeq7        AS RemValSeq7,      -- �����׸񳻺��ڵ尪7
            SPACE(200)          AS RemValName7,     -- �����׸�7
            A.RemValText7       AS RemValText7,     -- �����׸��ؽ�Ʈ��7
            A.RemSeq8           AS RemSeq8,         -- �����׸񳻺��ڵ�8
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq8) AS RemName8,    -- �����׸�8
            A.RemValSeq8        AS RemValSeq8,      -- �����׸񳻺��ڵ尪8
            SPACE(200)          AS RemValName8,     -- �����׸�8
            A.RemValText8       AS RemValText8,     -- �����׸��ؽ�Ʈ��8
            A.RemSeq9           AS RemSeq9,         -- �����׸񳻺��ڵ�9
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq9) AS RemName9,    -- �����׸�9
            A.RemValSeq9        AS RemValSeq9,      -- �����׸񳻺��ڵ尪9
            SPACE(200)          AS RemValName9,     -- �����׸�9
            A.RemValText9       AS RemValText9,     -- �����׸��ؽ�Ʈ��9
            A.RemSeq10          AS RemSeq10,        -- �����׸񳻺��ڵ�10
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq10) AS RemName10,  -- �����׸�10
            A.RemValSeq10       AS RemValSeq10,     -- �����׸񳻺��ڵ尪10
            SPACE(200)          AS RemValName10,    -- �����׸�10
            A.RemValText10      AS RemValText10,    -- �����׸��ؽ�Ʈ��10
            SPACE(200)          AS RemValText,      -- �����ؽ�Ʈ
            A.AccDate           AS AccDate,         -- ȸ����
            A.Remark            AS Remark,          -- ����
            A.SlipSeq           AS SlipSeq,         -- ��ǥ�Ϸù�ȣ
            A.IsSet             AS IsSet,           -- ���ο���
            ISNULL((SELECT SlipID FROM _TACSlipRow WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipSeq = A.SlipSeq), '') AS SlipID,
            A.PayEndDate        AS PayEndDate       -- �޿�������(2012.05.21)
        INTO #TPRAccPaySlip
        FROM _TPRAccPaySlip AS A LEFT OUTER JOIN _TDAAccount AS B ON A.CompanySeq = B.CompanySeq
                                                                AND A.AccSeq     = B.AccSeq
        LEFT OUTER JOIN _TDACCtr    AS C ON ( C.CompanySeq = @CompanySeq AND C.CCtrSeq = A.DtlSeq ) 
       WHERE A.CompanySeq = @CompanySeq
        AND A.EnvValue   = @EnvValue
        AND C.AccUnit    = @AccUnit
        AND A.PuSeq      = @PuSeq
        AND A.PbYM       = @PbYM
        AND A.SerialNo   = @SerialNo
    ORDER BY A.Seq
  
      SET @Sql = ''
     SET @Sql = @Sql + 'ALTER TABLE #TPRAccPaySlip ADD CodeHelpSeq    INT '
     SET @Sql = @Sql + 'ALTER TABLE #TPRAccPaySlip ADD CodeHelpParams NVARCHAR(50) '  
     SET @Sql = @Sql + 'ALTER TABLE #TPRAccPaySlip ADD RemName        NVARCHAR(100) '  
     SET @Sql = @Sql + 'ALTER TABLE #TPRAccPaySlip ADD RemRefValue    NVARCHAR(400) '  
  
      EXEC SP_EXECUTESQL @Sql
  
      IF @@ERROR <> 0
     BEGIN
         RETURN
     END
      -- ������� �ӽ����̺��� �÷��� �����ϱ� ��.
  
      -- ��Ī�� �����´�.    
     -- ���� �Ŀ��� ValueName �÷��� �ڵ������Ǿ� ����.
     IF EXISTS (SELECT RemValSeq1 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq1, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq1', 'RemValName1'  
     END
      IF EXISTS (SELECT RemValSeq2 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq2, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq2', 'RemValName2'  
     END
      IF EXISTS (SELECT RemValSeq3 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq3, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq3', 'RemValName3'  
     END
      IF EXISTS (SELECT RemValSeq4 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq4, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq4', 'RemValName4'  
     END
      IF EXISTS (SELECT RemValSeq5 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq5, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq5', 'RemValName5'  
     END
      IF EXISTS (SELECT RemValSeq6 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq6, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq6', 'RemValName6'  
     END
      IF EXISTS (SELECT RemValSeq7 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq7, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq7', 'RemValName7'  
     END
      IF EXISTS (SELECT RemValSeq8 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq8, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq8', 'RemValName8'  
     END
      IF EXISTS (SELECT RemValSeq9 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq9, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq9', 'RemValName9'  
     END
      IF EXISTS (SELECT RemValSeq10 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq10, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq10', 'RemValName10'  
     END
  
      SELECT * FROM #TPRAccPaySlip ORDER BY SMDrOrCr DESC, AccSeq, Seq
  RETURN
GO 
