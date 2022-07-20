IF OBJECT_ID('mnpt_SAREEGWUsualCostQuery') IS NOT NULL 
    DROP PROC mnpt_SAREEGWUsualCostQuery
GO 

-- v2018.01.30 

CREATE PROC mnpt_SAREEGWUsualCostQuery
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10) = '',  
    @CompanySeq     INT = 0,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS
  
	DECLARE @docHandle      INT,  
            @UsualCostSeq   INT
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument        
  
    SELECT @UsualCostSeq      = UsualCostSeq 
		   --@ApproReqSerl     = ApproReqSerl                       
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
    WITH ( UsualCostSeq         INT)

	DECLARE	@StdYear	NCHAR(4),
		    @Deptseq	INT,
			@AccUnit	INT


	SELECT @StdYear	= LEFT(ApprDate, 4),
		   @DeptSeq	= ISNULL(A.DeptSeq, 0),
		   @AccUnit	= ISNULL(B.AccUnit, 0)
	  FROM _TARUsualCost AS A
		   LEFT  JOIN _TDADept AS B WITH(NOLOCK)
				   ON B.CompanySeq	= A.CompanySeq
				  AND B.DeptSeq		= A.DeptSeq
	 WHERE A.CompanySeq		= @CompanySeq
	   AND A.UsualCostSeq	= @UsualCostSeq


		SELECT IDENTITY(INT, 1, 1)					AS RowNo,
               ISNULL(B.UsualCostSeq        ,  0)   AS UsualCostSeq     , -- �Ϲݺ�볻���ڵ�  
               ISNULL(B.UsualCostNo         , '')   AS UsualCostNo      , -- ��û��No  
               ISNULL(B.RegDate             , '')   AS RegDate          , -- �ۼ���  
               ISNULL(REmp.EmpName          , '')   AS RegEmpName       , -- �ۼ���  
               ISNULL(REmp.DeptName         , '')   AS RegDeptName      , -- �ۼ��μ�  
               ISNULL(B.ApprDate            , '')   AS ApprDate         , -- ��û��  
               ISNULL(Emp.EmpName           , '')   AS EmpName          , -- ��û��  
               ISNULL(Dept.DeptName          , '')   AS DeptName         , -- ��û�μ�  
               ISNULL(CCtr.CCtrName         , '')   AS CCtrName         , -- Ȱ������  
               ISNULL(B.Contents            , '')   AS RemarkM          , -- ���⳻��  
               --ISNULL(@SumAmt               ,  0)   AS SumAmt           , -- �հ�ݾ�  
               --ISNULL(@SumSupplyAmt         ,  0)   AS SumSupplyAmt     , -- �հ���ް���  
               --ISNULL(@SumVatAmt            ,  0)   AS SumVatAmt        , -- �հ�ΰ��� 
               -- Detail
               ISNULL(A.UsualCostSerl       ,  0)   AS UsualCostSerl    , -- �Ϲݺ�����  
			   ISNULL(CM.CostName           , '')   AS CostName         , -- ����׸�  
               ISNULL(Rem.RemName           , '')   AS RemName          , -- �����׸�����  
               ISNULL(RemVal.RemValueName   , '')   AS RemValName       , -- �����׸� ��Ī  
               ISNULL(A.IsVat               , '')   AS IsVat            , -- �ΰ�������  
               ISNULL(A.Amt                 ,  0)   AS Amt              , -- �ݾ�  
               ISNULL(A.SupplyAmt           ,  0)   AS Price			, -- �ܰ�  
               ISNULL(A.SupplyAmt           ,  0)   AS CurAmt			, -- ���ް���  
               ISNULL(A.VatAmt              ,  0)   AS VatAmt           , -- �ΰ���  
               ISNULL(Cust.CustName         , '')   AS CustName         , -- �ŷ�ó  
               ISNULL(A.CustText            , '')   AS CustText         , -- �ŷ�ó(Text)  
               ISNULL(Evid.EvidName         , '')   AS EvidName         , -- ����  
               ISNULL(A.Remark              , '')   AS RemarkD           , -- ���  
               ISNULL(Acc1.AccName          , '')   AS AccName          , -- ��������  
               ISNULL(A.AccSeq              ,  0)   AS AccSeq,            -- �����ڵ�  
			   CONVERT(DECIMAL(19, 5), 0)			AS NotSlipAmt
		  INTO #tmpCost
          FROM _TARUsualCostAmt AS A WITH (NOLOCK) JOIN _TARUsualCost AS B WITH (NOLOCK)
                                                     ON A.CompanySeq    = B.CompanySeq
                                                    AND A.UsualCostSeq  = B.UsualCostSeq
                                                   LEFT OUTER JOIN _TARCostAcc AS CM WITH (NOLOCK)  
                                                     ON A.CompanySeq    = CM.CompanySeq  
                                                    AND A.CostSeq       = CM.CostSeq  
                                                   LEFT OUTER JOIN _TDAAccountRem AS Rem WITH (NOLOCK)  
                                                     ON A.CompanySeq    = Rem.CompanySeq  
                                                    AND CM.RemSeq       = Rem.RemSeq  
                                                   LEFT OUTER JOIN _TDAAccountRemValue AS RemVal WITH (NOLOCK)  
                                                     ON A.CompanySeq    = RemVal.CompanySeq  
                                                    AND A.RemValSeq     = RemVal.RemValueSerl  
                                                   LEFT OUTER JOIN _TDACust AS Cust WITH (NOLOCK)  
                                                     ON A.CompanySeq    = Cust.CompanySeq  
                                                    AND A.CustSeq       = Cust.CustSeq  
                                                   LEFT OUTER JOIN _TDAEvid AS Evid WITH (NOLOCK)  
                                                     ON A.CompanySeq    = Evid.CompanySeq  
                                                    AND A.EvidSeq       = Evid.EvidSeq  
                                                   LEFT OUTER JOIN _TDAAccount AS Acc1 WITH (NOLOCK)  
                                                     ON A.CompanySeq    = Acc1.CompanySeq  
                                                    AND A.AccSeq        = Acc1.AccSeq  
												   LEFT OUTER JOIN _TDAAccount AS Acc2 WITH (NOLOCK)  
                                                     ON A.CompanySeq    = Acc2.CompanySeq  
                                                    AND A.VatAccSeq     = Acc2.AccSeq  
                                                   LEFT OUTER JOIN _TDAAccount AS Acc3 WITH (NOLOCK)  
                                                     ON A.CompanySeq    = Acc3.CompanySeq  
                                                    AND A.OppAccSeq     = Acc3.AccSeq  
                                                   LEFT OUTER JOIN dbo._fnAdmEmpOrd(@CompanySeq,'') AS REmp 
                                                     ON B.RegEmpSeq  = REmp.EmpSeq  
                                                   LEFT OUTER JOIN _TDAEmp AS Emp  
                                                     ON B.EmpSeq	= Emp.EmpSeq  
													AND B.CompanySeq	= Emp.CompanySeq
												   LEFT OUTER JOIN _TDADept AS Dept
												     ON B.DeptSeq	= Dept.DeptSeq
													AND B.CompanySeq	= Dept.CompanySeq
                                                   LEFT OUTER JOIN _TDACCtr AS CCtr WITH (NOLOCK)  
                                                     ON B.CompanySeq   = CCtr.CompanySeq  
                                                    AND B.CCtrSeq      = CCtr.CCtrSeq  
                                                   LEFT OUTER JOIN _TACSlipRow AS Slip WITH (NOLOCK)  
                                                     ON B.CompanySeq   = Slip.CompanySeq  
                                                    AND B.SlipSeq      = Slip.SlipSeq  
                                                   LEFT OUTER JOIN _TCAUser AS U WITH (NOLOCK)  
                                                     ON B.CompanySeq   = U.CompanySeq  
                                                    AND B.LastUserSeq  = U.UserSeq  
         WHERE A.CompanySeq     = @CompanySeq  
           AND A.UsualCostSeq   = @UsualCostSeq  
         ORDER BY A.UsualCostSerl  
    

	--select * from _fnAdmEmpOrd(1,'') where EmpNAme ='�Ѷ�Ȧ����'

	--ylw_helptext3 _fnAdmEmpOrd


	--�����οϷ�, ��ǥó�� X
	SELECT SUM(A.SupplyAmt) AS NotSlipAmt,
		   A.AccSeq
	  INTO #TNotSlipAmt2
	  FROM _TARUsualCostAmt AS A WITH(NOLOCK)
		   INNER JOIN _TARUsualCost AS B WITH(NOLOCK)
				   ON B.CompanySeq		= A.CompanySeq
				  AND B.UsualCostSeq	= A.UsualCostSeq
		   LEFT  JOIN _TARUsualCost_Confirm AS C WITH(NOLOCK)
				   ON C.CompanySeq		= B.CompanySeq
				  AND C.CfmSeq			= B.UsualCostSeq
	 WHERE A.CompanySeq	= @CompanySeq
	   AND LEFT(B.ApprDate, 4)	= @StdYear
	   AND ISNULL(C.CfmCode, 0)			= 1	--�����οϷ�
	   AND ISNULL(B.SlipSeq, 0)			= 0 --��ǥó�� X
       AND B.DeptSeq = @DeptSeq 
	 GROUP BY A.AccSeq

	--DECLARE @CurAmt	DECIMAL(19, 5),
	--	    @CurVat	DECIMAL(19, 5),
	--		@TotAmt	DECIMAL(19, 5)

	--SELECT @CurAmt	= SUM(SupplyAmt),
	--	   @CurVat	= SUM(VatAmt),
	--	   @TotAmt	= SUM(Amt)
	--  FROM _TARUsualCostAmt AS A
 --    WHERE A.CompanySeq		= @CompanySeq
	--   AND A.UsualCostSeq	= @UsualCostSeq



------------------------------------------------------------------------------
------------------------���� - ������� ���� START----------------------------
------------------------------------------------------------------------------
    DECLARE @IsSave         NCHAR(1),  
            @AccSeq         INT,  
            @RemSeq         INT,  
            @BgtSeq         INT,
            @AccNo          NVARCHAR(50),
            @SMBgtType      INT,
			@txtAccName		NVARCHAR(100),			-- ��������� - ��ȸ���ǿ� ���������, �������� �߰� 2015.07.08 By sryoun.
			@BgtName		NVARCHAR(100),			-- ��������
			@RemName		NVARCHAR(100)			-- �����׸��
    SELECT @IsSave      = '0',  
           @AccSeq      = 0,  
           @RemSeq      = 0,  
           @BgtSeq      = 0,
           @AccNo       = '',
           @SMBgtType   = 0,
		   @txtAccName	= '',
		   @BgtName		= '',
		   @RemName		= ''

    CREATE TABLE #BgtItemList (      
        AccSeq          INT,      
        RemSeq          INT,      
        RemValSeq       INT,      
        BgtSeq          INT,      
        --IsSave          NCHAR(1),  
        RemValName      NVARCHAR(100))      
            -- 2-1. ����� �� �� �����ΰ� (SMBgtType = 4005001)
            INSERT INTO #BgtItemList (AccSeq, RemSeq, RemValSeq, BgtSeq) --, IsSave)
                SELECT a.AccSeq, 0, 0, bgt.BgtSeq --, '1'
                  FROM _TDAAccount AS a WITH (NOLOCK) JOIN _TACBgtAcc AS bgt WITH (NOLOCK)
                                                        ON a.CompanySeq     = bgt.CompanySeq
                                                       AND a.AccSeq         = bgt.AccSeq
                                                       AND bgt.RemSeq       = 0
                                                       AND bgt.RemValSeq    = 0
                 WHERE a.CompanySeq     = @CompanySeq
                   AND a.IsSlip         = '1'                                   -- ��ǥ
                   AND a.SMBgtType      = 4005001                               -- �������� : ��������
                   AND (@AccSeq         = 0  OR a.AccSeq     = @AccSeq       )  -- �����ڵ�
                   AND (@BgtSeq         = 0  OR bgt.BgtSeq   = @BgtSeq       )  -- �������
                   AND a.AccNo      LIKE @AccNo + '%'                           -- ������ȣ
            INSERT INTO #BgtItemList (AccSeq, RemSeq, RemValSeq, BgtSeq, RemValName) -- IsSave, 
                -- 1) ����ڼҺз� (19999)
                SELECT A.AccSeq, A.BgtRemSeq, D.RemValSeq, D.BgtSeq, C.MinorName  --'1', 
                  FROM _TDAAccount AS A WITH (NOLOCK) JOIN _TDAAccountRem AS B WITH (NOLOCK)
                                                        ON A.CompanySeq     = B.CompanySeq
                                                       AND A.BgtRemSeq      = B.RemSeq
                                                       AND B.SMInputType    = 4016002 --- �ڵ嵵���� �͸�.
                                                      JOIN _TDAUMinor AS C WITH (NOLOCK)
                                                        ON A.CompanySeq     = C.CompanySeq   AND C.MajorSeq       = CASE WHEN CHARINDEX('|',B.CodeHelpParams) > 0 THEN SUBSTRING(B.CodeHelpParams,1,CHARINDEX('|',B.CodeHelpParams) - 1) ELSE '0' END
                                                      LEFT OUTER JOIN _TACBgtAcc AS D WITH (NOLOCK)      
                                                        ON A.CompanySeq     = D.CompanySeq      
                                                       AND A.AccSeq         = D.AccSeq      
                                                       AND A.BgtRemSeq      = D.RemSeq      
                                                       AND C.MinorSeq       = D.RemValSeq   
                 WHERE A.CompanySeq     = @CompanySeq      
                   AND A.IsSlip         = '1'                                   -- ��ǥ      
                   AND A.SMBgtType      = 4005002                               -- �������� : �����׸�      
                   AND (@AccSeq         = 0  OR A.AccSeq     = @AccSeq       )  -- �����ڵ�      
                   AND (@BgtSeq         = 0  OR D.BgtSeq     = @BgtSeq       )  -- �������      
                   AND (@RemSeq         = 0  OR A.BgtRemSeq  = @RemSeq       )  -- �����׸�      
                   AND A.AccNo      LIKE @AccNo + '%'                           -- ������ȣ      
                   AND A.BgtRemSeq     <> 0                                     -- ��������׸��� �ڵ尡 �ִ°�.   
                   AND B.CodeHelpSeq    = 19999                                 -- ***����ڼҺз�
                UNION
                -- 2) �ý��ۼҺз� (19998)
                SELECT A.AccSeq, A.BgtRemSeq, D.RemValSeq, D.BgtSeq,C.MinorName -- '1', 
                  FROM _TDAAccount AS A WITH (NOLOCK) JOIN _TDAAccountRem AS B WITH (NOLOCK)
                                                        ON A.CompanySeq     = B.CompanySeq
                                                       AND A.BgtRemSeq      = B.RemSeq
                                                       AND B.SMInputType    = 4016002 --- �ڵ嵵���� �͸�.
                                                      JOIN _TDASMinor AS C WITH (NOLOCK)
                                                        ON A.CompanySeq     = C.CompanySeq
                                                       AND C.MajorSeq       = CASE WHEN CHARINDEX('|',B.CodeHelpParams) > 0 THEN SUBSTRING(B.CodeHelpParams,1,CHARINDEX('|',B.CodeHelpParams) - 1) ELSE '0' END
                                                      LEFT OUTER JOIN _TACBgtAcc AS D WITH (NOLOCK)      
                                                        ON A.CompanySeq     = D.CompanySeq      
                                                       AND A.AccSeq         = D.AccSeq      
                                                       AND A.BgtRemSeq      = D.RemSeq      
                                                       AND C.MinorSeq       = D.RemValSeq   
                 WHERE A.CompanySeq     = @CompanySeq      
                   AND A.IsSlip         = '1'                                   -- ��ǥ      
                   AND A.SMBgtType      = 4005002                               -- �������� : �����׸�      
                   AND (@AccSeq         = 0  OR A.AccSeq     = @AccSeq       )  -- �����ڵ�      
                   AND (@BgtSeq         = 0  OR D.BgtSeq     = @BgtSeq       )  -- �������      
                   AND (@RemSeq         = 0  OR A.BgtRemSeq  = @RemSeq       )  -- �����׸�      
                   AND A.AccNo      LIKE @AccNo + '%'                           -- ������ȣ      
                   AND A.BgtRemSeq     <> 0                                     -- ��������׸��� �ڵ尡 �ִ°�. 
                   AND B.CodeHelpSeq    = 19998                                 -- ***�ý��ۼҺз�
                UNION
                -- 3) ȸ������׸� (40031)
                SELECT A.AccSeq, A.BgtRemSeq,  C.RemValueSerl, D.BgtSeq, C.RemValueName  --'1',			-- ��ϵ� �κп� ���� �����׸��ڵ常 ��ȸ�Ǿ� ������ �Է� �� ���� �� ������� �ʾ� ������. 2015.09.24
                  FROM _TDAAccount AS A WITH (NOLOCK) JOIN _TDAAccountRem AS B WITH (NOLOCK)                                               ON A.CompanySeq     = B.CompanySeq
                                                       AND A.BgtRemSeq      = B.RemSeq
                                                       AND B.SMInputType    = 4016002 --- �ڵ嵵���� �͸�.
                                                      JOIN _TDAAccountRemValue AS C WITH (NOLOCK)
                                                        ON A.CompanySeq     = C.CompanySeq
                                                       AND C.RemSeq         = CASE WHEN CHARINDEX('|',B.CodeHelpParams) > 0 THEN SUBSTRING(B.CodeHelpParams,1,CHARINDEX('|',B.CodeHelpParams) - 1) ELSE '0' END
                                                      LEFT OUTER JOIN _TACBgtAcc AS D WITH (NOLOCK)      
                                                        ON A.CompanySeq     = D.CompanySeq      
                                                       AND A.AccSeq         = D.AccSeq      
                                                       AND A.BgtRemSeq      = D.RemSeq      
                                                       AND C.RemValueSerl   = D.RemValSeq   
                 WHERE A.CompanySeq     = @CompanySeq      
                   AND A.IsSlip         = '1'                                   -- ��ǥ      
                   AND A.SMBgtType      = 4005002                               -- �������� : �����׸�      
                   AND (@AccSeq         = 0  OR A.AccSeq     = @AccSeq       )  -- �����ڵ�      
                   AND (@BgtSeq         = 0  OR D.BgtSeq     = @BgtSeq       )  -- �������      
                   AND (@RemSeq         = 0  OR A.BgtRemSeq  = @RemSeq       )  -- �����׸�      
                   AND A.AccNo      LIKE @AccNo + '%'                           -- ������ȣ      
                   AND A.BgtRemSeq     <> 0                                     -- ��������׸��� �ڵ尡 �ִ°�. 
                   AND B.CodeHelpSeq    = 40031                                 -- ***ȸ������׸�
				   


    SELECT ISNULL(acc.AccName           , '')   AS AccName          ,       
           ISNULL(bgt.BgtName           , '')   AS BgtName          ,      
           ISNULL(A.AccSeq              , 0)    AS AccSeq           ,      
           A.BgtSeq								AS BgtSeq
	  INTO #BgtAcc
      FROM #BgtItemList AS A LEFT OUTER JOIN _TDAAccount AS acc WITH (NOLOCK)      
                               ON acc.CompanySeq    = @CompanySeq      

                              AND A.AccSeq          = acc.AccSeq      
                             LEFT OUTER JOIN _TDAAccountRem AS rem WITH (NOLOCK)      
                               ON rem.CompanySeq    = @CompanySeq      
                              AND A.RemSeq          = rem.RemSeq      
                             LEFT OUTER JOIN _TACBgtItem AS bgt WITH (NOLOCK)      
                               ON bgt.CompanySeq    = @CompanySeq      
                              AND A.BgtSeq          = bgt.BgtSeq
	 WHERE (@txtAccName	= ''	OR acc.AccName	LIKE @txtAccName + N'%')			-- ���������		-- ��ȸ���ǿ� �߰� 2015.07.08 by sryoun.
	   AND (@BgtName	= ''	OR bgt.BgtName	LIKE @BgtName + N'%')				-- ��������
	   AND (@RemName	= ''	OR rem.RemName	LIKE @RemName + N'%')				-- �����׸��
	  GROUP BY A.AccSeq,acc.AccName,bgt.BgtName,A.BgtSeq


----------------------------------------------------------------------------
------------------------���� - ������� ���� END----------------------------
----------------------------------------------------------------------------

	SELECT B.BgtName,
		   SUM(A.BgtAmt) AS BgtAmt,
		   A.CompanySeq,
		   LEFT(A.BgtYM,4) AS BgtYM,
		   A.AccUnit,
		   A.DeptSeq,
		   A.CCtrSeq,
		   A.BgtSeq
	  INTO #TACBgtAdjItem
	  FROM _TACBgt AS A
	  LEFT OUTER JOIN _TACBgtItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
												   AND A.BgtSeq = B.BgtSeq
	 GROUP BY A.CompanySeq,		LEFT(A.BgtYM,4),
			  A.AccUnit,		A.DeptSeq,
			  A.CCtrSeq,		A.BgtSeq,
			  B.BgtName,		A.IniOrAmd
	HAVING A.CompanySeq = @CompanySeq
	   AND LEFT(A.BgtYM,4) = @StdYear
	   AND A.AccUnit = @AccUnit
	   AND A.DeptSeq = @DeptSeq
	   AND A.IniOrAmd = 1




--��������� ���� ����+���� �ݾ�(����)
	 SELECT SUM((DrAmt - CrAmt)*SMDrOrCr) AS Sumtot,BgtSeq,BgtDeptSeq,AccUnit
	   INTO #TACSlipRow
	   FROM _TACSlipRow		
	  WHERE CompanySeq = @CompanySeq
	    AND LEFT(ISNULL(AccDate,''),4) = @StdYear
		AND AccUnit = @AccUnit
		AND BgtDeptSeq = @DeptSeq
	  GROUP BY BgtSeq,BgtDeptSeq,AccUnit


-- �������� �� ǰ�Ǳݾ�(�ݹ�)
    SELECT A.AccName, 
		   --SUM(CurAmt + CurVat) AS TotAmt,
		   SUM(A.CurAmt) AS TotAmt,
		   SUM(A.NotSlipAmt) AS NotSlipAmt,
		   A.AccSeq
	  INTO #TACBgtAdjAccCal
      FROM #tmpCost AS A
	  --LEFT OUTER JOIN #TNotSlipAmt2 AS B ON A.AccSeq = B.AccSeq2
     GROUP BY A.AccName,A.AccSeq

--����x���� ���� ǰ�Ǳݾ� ���� �ӽ����̺�(�����������)
	 SELECT A.*,B.TotAmt,C.NotSlipAmt
	   INTO #BgtAccTotAmt
	   FROM #BgtAcc AS A
	   LEFT OUTER JOIN #TACBgtAdjAccCal AS B ON A.AccSeq = B.AccSeq
	   LEFT OUTER JOIN #TNotSlipAmt2 AS C ON A.AccSeq = C.AccSeq

--����x���� ���� ǰ�Ǳݾ� ������ ���� ������񺰷� SUM
	SELECT SUM(TotAmt) AS TotAmt,
		   SUM(NotSlipAmt) AS NotSlipAmt,
	       BgtSeq
	  INTO #BgtAccTotAmt2
	  FROM #BgtAccTotAmt
	 GROUP BY BgtSeq


--�����ȹ���Կ��� @IsPlanName : ǰ��ǰ�� ������ ���������� �ϳ��� �������� ������������ "������" �ƴϸ� "����"
--#TACBgtAdjAccCal : ����ǰ��ǰ���� ��������
--#BgtAcc : �������� - ������� ����
--#TACBgtAdjItem : ������ �����ִ� �������
	DECLARE @IsPlanName NVARCHAR(100)

	IF EXISTS (SELECT A.AccSeq, B.AccSeq 
				 FROM #TACBgtAdjAccCal AS A
				 LEFT OUTER JOIN #BgtAcc AS B WITH(NOLOCK) ON A.AccSeq = B.AccSeq
				 LEFT OUTER JOIN #TACBgtAdjItem AS C WITH(NOLOCK) ON B.BgtSeq = C.BgtSeq
				WHERE C.BgtSeq IS NULL)

	BEGIN
		SELECT @IsPlanName = '������'
	END
	ELSE
	BEGIN
		SELECT @IsPlanName = '����'
	END

-------------
--���� ���--
-------------
	--������� ǰ�� �������� �ش��ϴ� �͸� ������
	SELECT TOP 5
		   A.BgtName,
		   A.BgtAmt AS BgtAmt, 
		   ISNULL(C.TotAmt,0) AS Thistot, 
		   ISNULL(B.Sumtot,0) + ISNULL(C.NotSlipAmt,0) AS Sumtot, 
		   ISNULL(A.BgtAmt,0)-ISNULL(B.Sumtot,0) - ISNULL(C.TotAmt,0) - ISNULL(C.NotSlipAmt,0) AS BgtRest
	  INTO #TACBgtAdjItem2
	  FROM #TACBgtAdjItem AS A
	  LEFT OUTER JOIN #TACSlipRow AS B WITH(NOLOCK) ON A.BgtSeq = B.BgtSeq
	  JOIN #BgtAccTotAmt2 AS C ON A.BgtSeq = C.BgtSeq
	 WHERE A.BgtSeq IN (SELECT BgtSeq FROM #BgtAccTotAmt2 WHERE ISNULL(TotAmt,0) <> 0)


--���ڰ��� ����κи� ���â���� ��ĭ���ζ� 5ĭ ����
	WHILE (SELECT COUNT (1) FROM #TACBgtAdjItem2) < 5
	BEGIN
		INSERT INTO #TACBgtAdjItem2 VALUES ('',0,0,0,0)
	END


	SELECT * FROM #TACBgtAdjItem2 ORDER BY BgtName DESC

	SELECT LEFT(ApprDate,4) + '-' + SUBSTRING(ApprDate,5,2) +'-' + RIGHT(ApprDate,2) AS ApproReqDate,
		   UsualCostNo								AS ApproReqNo,
		   DeptName									AS DeptName,
		   EmpName									AS EmpName,
		   @IsPlanName								AS IsPlanName,
		   RemarkM									AS RemarkM,
		   AccName									AS AccName,
		   ''										AS ItemNo,
		   CostName									AS ItemName,
		   CustName									AS CustName,
		   ISNULL(CurAmt, 0)						AS CurAmt,
		   ISNULL(VatAmt, 0)						AS CurVat,
		   ISNULL(CurAmt, 0) + ISNULL(VatAmt, 0)	AS TotAmt,
		   RemarkD									AS RemarkD,
		   RowNo									AS RowNo
	  FROM #tmpCost

