IF OBJECT_ID('mnpt_SARUsualCostAmtQuery') IS NOT NULL 
    DROP PROC mnpt_SARUsualCostAmtQuery
GO 

-- v2018.01.08 

/*********************************************************************************************************************    
    ȭ��� : �Ϲݺ���û���ݾ� - ��ȸ
    SP Name: _SARUsualCostAmtQuery    
    �ۼ��� : 2010.04.20 : CREATEd by �۰��        
    ������ : 
********************************************************************************************************************/    
CREATE PROCEDURE mnpt_SARUsualCostAmtQuery      
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,-- ���񽺵���Ѱ� Seq�� �Ѿ�´�.    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS           
    DECLARE @docHandle			INT    
          , @UsualCostSeq		INT         -- �Ϲݺ���û�� �����ڵ�
		  , @EnvValue4008		INT			-- ���������� ('����μ�' �÷� �߰��� ����, ��ȸ �� ���������ؿ� ���� �μ� �Ǵ� Ȱ�����ͷ� ��ȸ�ϱ� ����. 2017.10.30. by sryoun.)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
    
    SELECT @UsualCostSeq   = ISNULL(UsualCostSeq, 0)  -- �Ϲݺ���û�� �����ڵ�
           
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)         
    WITH (UsualCostSeq     INT
         )      
    
    SELECT @UsualCostSeq   = ISNULL(@UsualCostSeq, 0)
	-- ����������
	SELECT @EnvValue4008 = ISNULL(EnvValue, 0)
	  FROM _TCOMEnv WITH(NOLOCK)
	 WHERE CompanySeq	= @CompanySeq
	   AND EnvSeq		= 4008
    

    -- ����׸� ���߼� �з� 
    SELECT C.MinorSeq AS CostSClassSeq, C.MinorName AS CostSClassName, -- 'ǰ��Һз�'   
           E.MinorSeq AS CostMClassSeq, E.MinorName AS CostMClassName, -- 'ǰ���ߺз�'   
           G.MinorSeq AS CostLClassSeq, G.MinorName AS CostLClassName  -- 'ǰ���з�'  
      INTO #CostClass
      FROM _TDAUMinor                 AS C WITH(NOLOCK)   
      LEFT OUTER JOIN _TDAUMinorValue AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND C.MinorSeq = D.MinorSeq AND D.Serl = 1000001 ) 
      -- �ߺз�   
      LEFT OUTER JOIN _TDAUMinor  AS E WITH(NOLOCK) ON ( D.ValueSeq = E.MinorSeq AND D.CompanySeq = E.CompanySeq )--AND E.IsUse = '1' )  
      LEFT OUTER JOIN _TDAUMinorValue AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND E.MinorSeq = F.MinorSeq AND F.Serl = 1000001 ) 
      -- ��з�   
      LEFT OUTER JOIN _TDAUMinor  AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND F.ValueSeq = G.MinorSeq ) 
     WHERE C.CompanySeq = @CompanySeq
       AND C.MajorSeq = 1016729

/***********************************************************************************************************************************************/    
    SELECT A.UsualCostSerl  AS UsualCostSerl	-- �Ϲݺ�����			
        , A.CostSeq         AS CostSeq			-- ����׸��ڵ�
        , G.RemSeq          AS RemSeq			-- �����׸��ڵ�	  
        , A.RemValSeq       AS RemValSeq		-- �������ڵ�
        , A.Amt             AS Amt				-- �ݾ�				          
        , A.IsVat           AS IsVat			-- �ΰ�������				    
        , A.SupplyAmt       AS SupplyAmt		-- ���ް���				      
        , A.VatAmt          AS VatAmt			-- �ΰ��� 				      
        , A.CustSeq         AS CustSeq			-- �ŷ�ó				        
        , A.CustText        AS CustText			-- ī���ڵ� 
        , M.CardNo                              -- ī���ȣ			  
        , A.EvidSeq         AS EvidSeq			-- ����				          
        , A.Remark          AS Remark			-- ���				          
        , A.AccSeq          AS AccSeq			-- ���������ڵ�				      
        , A.VatAccSeq       AS VatAccSeq		-- �ΰ��������ڵ�				
        , A.OppAccSeq       AS OppAccSeq		-- �������ڵ�	
        , G.CostName        AS CostName			-- ����׸�
        , H.RemValueName    AS RemValName		-- ������
        , B.CustName        AS CustName			-- �ŷ�ó��
        , C.EvidName        AS EvidName			-- ������
        , D.AccName         AS AccName			-- ��������
        , E.AccName         AS VatAccName		-- �ΰ�������
        , F.AccName         AS OppAccName		-- ������		
        , A.OppAccSeq       AS OppAccSeq		-- �������ڵ�
        , A.CostCashDate    AS CostCashDate		-- �ⳳ������
        , A.CustDate        AS CustDate			-- �ŷ���
		, A.BgtDeptCCtrSeq	AS BgtDeptCCtrSeq	-- ����μ������ڵ�
		, (CASE @EnvValue4008 WHEN 4013001 THEN I.DeptName WHEN 4013002 THEN J.CCtrName ELSE '' END) AS BgtDeptCCtrName -- '����������' ȯ�漳���� ���� �μ�/Ȱ������ ��Ī���� ��ȸ
        , L.CostSClassSeq
        , L.CostMClassSeq
        , L.CostLClassSeq
        , L.CostSClassName
        , L.CostMClassName
        , L.CostLClassName
        
      FROM _TARUsualCostAmt         AS A WITH(NOLOCK) 
        LEFT OUTER JOIN _TDACust    AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.CustSeq = B.CustSeq
        LEFT OUTER JOIN _TDAEvid    AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.EvidSeq = C.EvidSeq
        LEFT OUTER JOIN _TDAAccount AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.AccSeq = D.AccSeq
        LEFT OUTER JOIN _TDAAccount AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq AND A.VatAccSeq = E.AccSeq
        LEFT OUTER JOIN _TDAAccount AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.OppAccSeq = F.AccSeq
        LEFT OUTER JOIN _TARCostAcc AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq AND A.CostSeq = G.CostSeq
        LEFT OUTER JOIN _TDAAccountRemValue AS H WITH(NOLOCK) ON G.CompanySeq = H.CompanySeq AND G.RemSeq = H.RemSeq AND A.RemValSeq = H.RemValueSerl
		LEFT OUTER JOIN _TDADept	AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq AND A.BgtDeptCCtrSeq = I.DeptSeq
		LEFT OUTER JOIN _TDACCtr	AS J WITH(NOLOCK) ON A.CompanySeq = J.CompanySeq AND A.BgtDeptCCtrSeq = J.CCtrSeq
        LEFT OUTER JOIN mnpt_TARCostAccSub  AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.CostSeq = A.CostSeq AND K.SMKindSeq = 4503004 ) 
        LEFT OUTER JOIN #CostClass          AS L              ON ( L.CostSClassSeq = K.CostSClassSeq ) 
        LEFT OUTER JOIN _TDACard        AS M WITH(NOLOCK) ON ( M.CompanySeq = @CompanySeq AND M.CardSeq = CONVERT(INT,A.CustText) ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.UsualCostSeq = @UsualCostSeq
    RETURN


    go
    begin tran 
    exec mnpt_SARUsualCostAmtQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <UsualCostSeq>7</UsualCostSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=13820117,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=167,@PgmSeq=13820108
rollback 

