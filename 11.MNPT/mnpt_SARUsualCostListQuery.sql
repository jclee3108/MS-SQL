IF OBJECT_ID('mnpt_SARUsualCostListQuery') IS NOT NULL 
    DROP PROC mnpt_SARUsualCostListQuery
GO 

-- v2018.01.08
/*********************************************************************************************************************    
    ȭ��� : �Ϲݺ���û����Ȳ - ��ȸ
    SP Name: _SARUsualCostListQuery    
    �ۼ��� : 2010.04.22 : CREATEd by �۰��        
    ������ : 
********************************************************************************************************************/    
CREATE PROCEDURE mnpt_SARUsualCostListQuery      
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,-- ���񽺵���Ѱ� Seq�� �Ѿ�´�.    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS           
    DECLARE @docHandle      INT    
          , @RegDateFr      NCHAR(8)    -- �ۼ��� Fr
          , @RegDateTo      NCHAR(8)    -- �ۼ��� To
          , @RegEmpSeq      INT         -- �ۼ���
          , @RegDeptSeq     INT         -- �ۼ��μ�
          , @UsualCostNo    NVARCHAR(50)-- ��û��No
          , @ApprDateFr     NCHAR(8)    -- ��û��Fr
          , @ApprDateTo     NCHAR(8)    -- ��û��To
          , @EmpSeq         INT         -- ��û��
          , @DeptSeq        INT         -- ��û�μ�
          , @CCtrSeq        INT         -- Ȱ������
          , @IsProg         NVARCHAR(1) -- ���࿩��
          , @IsEnd          NVARCHAR(1) -- �ϷῩ��
          , @IsAttachFile   NVARCHAR(1) -- ÷�����Ͽ���
          , @SetIsUse       NCHAR(1)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
    
    SELECT @RegDateFr   = ISNULL(RegDateFr, '')  -- �ۼ��� Fr
        , @RegDateTo  	= ISNULL(RegDateTo  , '')
        , @RegEmpSeq  	= ISNULL(RegEmpSeq  , 0)
        , @RegDeptSeq 	= ISNULL(RegDeptSeq , 0)
        , @UsualCostNo	= ISNULL(UsualCostNo, '')
        , @ApprDateFr 	= ISNULL(ApprDateFr , '')
        , @ApprDateTo 	= ISNULL(ApprDateTo , '')
        , @EmpSeq     	= ISNULL(EmpSeq     , 0)
        , @DeptSeq    	= ISNULL(DeptSeq    , 0)
        , @CCtrSeq    	= ISNULL(CCtrSeq    , 0)
        , @IsProg       = ISNULL(IsProg         , '0')
        , @IsEnd        = ISNULL(IsEnd          , '0')
        , @IsAttachFile = ISNULL(IsAttachFile   , '0')
           
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)         
    WITH (RegDateFr      NCHAR(8)    -- �ۼ��� Fr
        , RegDateTo      NCHAR(8)    -- �ۼ��� To
        , RegEmpSeq      INT         -- �ۼ���
        , RegDeptSeq     INT         -- �ۼ��μ�
        , UsualCostNo    NVARCHAR(50)-- ��û��No
        , ApprDateFr     NCHAR(8)    -- ��û��Fr
        , ApprDateTo     NCHAR(8)    -- ��û��To
        , EmpSeq         INT         -- ��û��
        , DeptSeq        INT         -- ��û�μ�
        , CCtrSeq        INT         -- Ȱ������
        , IsProg         NCHAR(1)    -- ���࿩��
        , IsEnd          NCHAR(1)    -- �ϷῩ��
        , IsAttachFile   NCHAR(1)    -- ÷�����Ͽ���
         )      
    
    SELECT @RegDateFr   = ISNULL(@RegDateFr, '') 
        , @RegDateTo  	= ISNULL(@RegDateTo  , '')
        , @RegEmpSeq  	= ISNULL(@RegEmpSeq  , 0)
        , @RegDeptSeq 	= ISNULL(@RegDeptSeq , 0)
        , @UsualCostNo	= ISNULL(@UsualCostNo, '')
        , @ApprDateFr 	= ISNULL(@ApprDateFr , '')
        , @ApprDateTo 	= ISNULL(@ApprDateTo , '')
        , @EmpSeq     	= ISNULL(@EmpSeq     , 0)
        , @DeptSeq    	= ISNULL(@DeptSeq    , 0)
        , @CCtrSeq    	= ISNULL(@CCtrSeq    , 0)
        , @IsProg       = ISNULL(@IsProg        , '0')
        , @IsEnd        = ISNULL(@IsEnd         , '0')
        , @IsAttachFile = ISNULL(@IsAttachFile  , '0')
    --=================================================================================================================================
    -- ���ڰ��縦 ���������� üũ�ϸ� [���࿩��], [�ϷῩ��], [÷�����Ͽ���] ��Ʈ���� ������
    SELECT @SetIsUse = ISNULL(IsUse, '') FROM _TCOMEnvGroupWare WHERE CompanySeq = @CompanySeq AND WorkKind = 'mnpt_UsualCost'
    IF @@ROWCOUNT = 0 OR ISNULL(@SetIsUse, '') = '' SELECT @SetIsUse = '0'
    IF @SetIsUse = '0'
    BEGIN
        SELECT  @IsProg         = '0',
                @IsEnd          = '0',
                @IsAttachFile   = '0'
    END
    --=================================================================================================================================
    
    IF @RegDateFr = '' SET @RegDateFr = '00000000'
    IF @RegDateTo = '' SET @RegDateTo = '99999999'
    IF @ApprDateFr = '' SET @ApprDateFr = '00000000'
    IF @ApprDateTo = '' SET @ApprDateTo = '99999999'
/***********************************************************************************************************************************************/  
    SELECT	B.UsualCostSeq, SUM(B.Amt) AS AmtSum, SUM(B.SupplyAmt) AS SupplyAmtSum , SUM(B.VatAmt) AS VatAmtSum, 
			MIN(B.UsualCostSerl) AS UsualCostSerl	-- �������� ���� �ּҰ��� ������� �Ʒ����� ��ȸ�ϱ� ���� �߰� 2015.07.29. by shpark [�Ϲݺ����ȸ(ESS)] ���� �����
      INTO #TARUsualCostAmt
      FROM _TARUsualCostAmt AS B
        JOIN _TARUsualCost AS A ON B.CompanySeq = A.CompanySeq AND B.UsualCostSeq = A.UsualCostSeq
    WHERE B.CompanySeq = @CompanySeq
        AND (A.RegDate BETWEEN @RegDateFr AND @RegDateTo)
        AND (@RegEmpSeq = 0 OR A.RegEmpSeq = @RegEmpSeq)
        AND (@RegDeptSeq = 0 OR A.RegDeptSeq = @RegDeptSeq)
        AND (@UsualCostNo = '' OR A.UsualCostNo LIKE @UsualCostNo + '%')
        AND (A.ApprDate BETWEEN @ApprDateFr AND @ApprDateTo)
        AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)
        AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
        AND (@CCtrSeq = 0 OR A.CCtrSeq = @CCtrSeq)
    GROUP BY B.UsualCostSeq
  
    SELECT A.UsualCostSeq	AS UsualCostSeq		-- �����ڵ�				      		
        , A.UsualCostNo		AS UsualCostNo		-- �Ϲݺ���û��No				    
        , A.RegDate			AS RegDate			-- �ۼ���				          
        , A.RegEmpSeq		AS RegEmpSeq		-- �ۼ����ڵ�				          
        , A.RegDeptSeq		AS RegDeptSeq		-- �ۼ��μ��ڵ�
        , A.ApprDate        AS ApprDate         -- ��û��
        , A.EmpSeq          AS EmpSeq           -- ��û���ڵ�
        , A.DeptSeq         AS DeptSeq          -- ��û�μ��ڵ�
        , A.CCtrSeq		    AS CCtrSeq		    -- Ȱ�������ڵ�			      		
        , A.Contents        AS Contents         -- ���⳻��
        , A.SlipSeq         AS SlipSeq          -- ��ǥ�����ڵ�
        , B.EmpName         AS RegEmpName       -- �ۼ���
        , C.DeptName        AS RegDeptName      -- �ۼ��μ�
        , D.EmpName         AS EmpName          -- ��û��
        , E.DeptName        AS DeptName         -- ��û�μ�
        , F.CCtrName        AS CCtrName         -- Ȱ������
        , H.SlipID          AS SlipID           -- ��ǥ��ȣ
        , A.UsualCostSeq	AS UsualCostSeq2		-- �����ڵ�2		
        , ISNULL(I.IsProg       , '')   AS IsProg       -- ���࿩��
        , ISNULL(I.IsEnd        , '')   AS IsEnd        -- �ϷῩ��
        , CASE ISNULL(I.IsAttachFile, 0) WHEN 0 THEN '0' 
												ELSE '1' END  AS IsAttachFile	-- ÷�����Ͽ���
        , ISNULL(I.IsAttachFile,0)		AS AttachFileCnt	 -- ÷�����ϰ���
        , G.AmtSum          AS AmtSum           -- �ݾ�
        , G.SupplyAmtSum    AS SupplyAmtSum     -- ���ް���
        , G.VatAmtSum       AS VatAmtSum,        -- �ΰ���
		-- ȭ�鿡 �÷��� �߰� �Ǿ� �ְ� ��ȸ���� �ʴ� �׸� ���� �߰��� : 2015.07.29. by shpark
		-- �ش� ������-������ ������ �������� ���� ���� ��� �� ���� ������� ��ȸ�ǵ��� �� [�Ϲݺ����ȸ(ESS)] ȭ�鿡�� ���
		cost.CostName					AS CostName,		-- ����׸�
		cost.CostSeq					AS CostSeq,			-- ����׸񳻺��ڵ�
		cserl.RemValueName				AS RemValName,	-- ���������׸�
		cserl.RemValueSerl				AS RemValSeq,	-- ���������׸񳻺��ڵ�
		CASE WHEN G1.CustSeq = 0 THEN G1.CustText ELSE ISNULL(cust.CustName, '') END AS CustName,	-- �ŷ�ó
		G1.CustSeq 						AS CustSeq,			-- �ŷ�ó�����ڵ�
		G1.Remark						AS Remark,			-- ����
		G1.CostCashDate					AS CostCashDate		-- �ⳳ������
		----------------------------------------------------------
      FROM _TARUsualCost AS A WITH(NOLOCK)
        LEFT OUTER JOIN _TDAEmp     AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.RegEmpSeq = B.EmpSeq
        LEFT OUTER JOIN _TDADept    AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.RegDeptSeq = C.DeptSeq
        LEFT OUTER JOIN _TDAEmp     AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.EmpSeq = D.EmpSeq
        LEFT OUTER JOIN _TDADept    AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq AND A.DeptSeq = E.DeptSeq
        LEFT OUTER JOIN _TDACCtr    AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.CCtrSeq = F.CCtrSeq
        LEFT OUTER JOIN #TARUsualCostAmt    AS G ON A.UsualCostSeq = G.UsualCostSeq
        LEFT OUTER JOIN _TACSlipRow    AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq AND A.SlipSeq = H.SlipSeq
        LEFT OUTER JOIN _TCOMGroupWare AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq AND A.UsualCostSeq = I.TblKey AND I.WorkKind = 'mnpt_UsualCost'
		-- �����׸� �߰� 2015.07.29 by shpark
		LEFT OUTER JOIN _TARUsualCostAmt AS G1 WITH(NOLOCK) ON A.CompanySeq = G1.CompanySeq AND A.UsualCostSeq = G1.UsualCostSeq AND G1.UsualCostSerl = G.UsualCostSerl
        LEFT OUTER JOIN _TARCostAcc		 AS cost WITH(NOLOCK) ON A.CompanySeq = cost.CompanySeq AND G1.CostSeq = cost.CostSeq  
        LEFT OUTER JOIN _TDAAccountRemValue AS cserl WITH(NOLOCK) ON A.CompanySeq = cserl.CompanySeq AND cost.RemSeq = cserl.RemSeq AND G1.RemValSeq = cserl.RemValueSerl  
		LEFT OUTER JOIN _TDACust		AS cust WITH(NOLOCK) ON A.CompanySeq = cust.CompanySeq AND G1.CustSeq = cust.CustSeq
     WHERE A.CompanySeq = @CompanySeq
        AND (A.RegDate BETWEEN @RegDateFr AND @RegDateTo)
        AND (@RegEmpSeq = 0 OR A.RegEmpSeq = @RegEmpSeq)
        AND (@RegDeptSeq = 0 OR A.RegDeptSeq = @RegDeptSeq)
        AND (@UsualCostNo = '' OR A.UsualCostNo LIKE @UsualCostNo + '%')
        AND (A.ApprDate BETWEEN @ApprDateFr AND @ApprDateTo)
        AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)
        AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
        AND (@CCtrSeq = 0 OR A.CCtrSeq = @CCtrSeq)
        AND (@IsProg        = '0' OR I.IsProg       = @IsProg       )
        AND (@IsEnd         = '0' OR I.IsEnd        = @IsEnd        )
--        AND (@IsAttachFile  = '0' OR I.IsAttachFile = @IsAttachFile )
      AND (@IsAttachFile = '0' OR I.IsAttachFile > 0)

    RETURN
go
exec mnpt_SARUsualCostListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <RegDateFr>20180101</RegDateFr>
    <RegDateTo />
    <ApprDateFr>20180101</ApprDateFr>
    <ApprDateTo />
    <UsualCostNo />
    <RegEmpSeq />
    <EmpSeq />
    <CCtrSeq />
    <RegDeptSeq />
    <DeptSeq />
    <SlipProc />
    <IsProg>0</IsProg>
    <IsEnd>0</IsEnd>
    <IsAttachFile>0</IsAttachFile>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=13820118,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=13820110