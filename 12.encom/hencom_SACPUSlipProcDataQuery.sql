IF OBJECT_ID('hencom_SACPUSlipProcDataQuery') IS NOT NULL 
    DROP PROC hencom_SACPUSlipProcDataQuery
GO 

/************************************************************            
  ��  �� - ������-���ڰ���_������ǥ��ȸ_hencom : ��ȸ            
  �ۼ��� - 20160727            
  �ۼ��� - �ڼ���            
 ************************************************************/            
CREATE PROC hencom_SACPUSlipProcDataQuery
  @xmlDocument    NVARCHAR(MAX) ,                        
  @xmlFlags     INT  = 0,                        
  @ServiceSeq     INT  = 0,                        
  @WorkingTag     NVARCHAR(10)= '',                              
  @CompanySeq     INT  = 1,                        
  @LanguageSeq INT  = 1,                        
  @UserSeq     INT  = 0,                        
  @PgmSeq         INT  = 0                     
                 
 AS                    
              
    DECLARE @docHandle  INT,            
            @SlipUnit   INT ,            
            @DateTo     NCHAR(8) ,            
            @DateFr     NCHAR(8)              
        
  EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                         
   SELECT  @SlipUnit   = SlipUnit    ,            
             @DateTo     = DateTo      ,            
             @DateFr     = DateFr                  
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)            
    WITH (SlipUnit    INT ,            
             DateTo      NCHAR(8) ,            
             DateFr      NCHAR(8) )            
            
     CREATE TABLE #TMPResultData            
     (            
	    SortSeq         INT,            -- ����
        OppAccSeq       INT,            -- �������ڵ�              
        OppAccName      NVARCHAR(1000),  -- ������              
        CustSeq         INT,            -- �ŷ�ó                
        CustName        NVARCHAR(1000),    -- �ŷ�ó��              
        Remark          NVARCHAR(1000),      -- ���                                               
        SupplyAmt       DECIMAL(19,5),   -- ���ް���                        
        VatAmt          DECIMAL(19,5),      -- �ΰ���                          
        Amt             DECIMAL(19,5),      -- �ݾ�                
        AccSeq          INT,    -- ���������ڵ�                        
        VatAccSeq       INT,    -- �ΰ��������ڵ�                   
        AccName         NVARCHAR(1000),     -- ��������             
        SlipSeq INT  ,        
        SlipUnit INT  ,        
        SlipUnitName    NVARCHAR(1000)         
    )            
       
      
    SELECT   SM.SlipMstSeq ,    
        CASE  WHEN SR.AccSeq IN (761,762) THEN SR.AccSeq ELSE 0 END   AS AccSeq ,--���޺�(��)_���Կ��,���޺�(��)_�������      
        SR.DrAmt ,      
        CASE  WHEN SR.AccSeq IN (580) THEN SR.AccSeq ELSE 0 END   AS OppAccSeq ,      
        (SELECT RemValSeq FROM _TACSlipRem WHERE CompanySeq = 1 AND SlipSeq = SR.SlipSeq AND RemSeq = 1017) AS CustSeq ,  --�����׸�_�ŷ�ó      
        CASE  WHEN SR.AccSeq IN (32) THEN SR.AccSeq ELSE 0 END   AS VatAccSeq ,      
        SR.SlipUnit,      
        SR.Summary,      
        SR.SlipSeq      
    INTO #TMPSlip      
    FROM _TACSlipRow AS SR WITH(NOLOCK)       
     JOIN _TACSlip AS SM WITH(NOLOCK) ON SM.CompanySeq = SR.CompanySeq       
                                        AND SM.SlipMstSeq = SR.SlipMstSeq           
      WHERE SR.CompanySeq = @CompanySeq       
        AND (SM.AccDate BETWEEN CASE WHEN @DateFr = '' THEN SM.AccDate ELSE @DateFr END        
                   AND CASE WHEN @DateTo = '' THEN SM.AccDate ELSE @DateTo END )      
    AND (@SlipUnit = '' OR SR.SlipUnit = @SlipUnit)        
    AND SM.SlipKind = 1000004 --���޿�ݺ�������Ȳ_hencom     
   
 --SELECT * FROM #TMPSlip   
      
--��������      
    SELECT 2 as sort_seq,
	       B.OppAccSeq,      
           F.AccName AS OppAccName,      
           A.CustSeq,      
           (SELECT CustName FROM _TDACust AS B WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq =A.CustSeq ) AS CustName ,      
           A.Summary AS Remark,        
           A.DrAmt AS SupplyAmt,      
           C.DrAmt AS VatAmt, --�ΰ����ݾ�      
           ISNULL(A.DrAmt,0) + ISNULL(C.DrAmt,0)  AS Amt,       
           A.AccSeq,      
           C.VatAccSeq ,      
           D.AccName,      
           A.SlipSeq ,      
           A.SlipUnit,      
           (SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipUnit = A.SlipUnit )AS SlipUnitName      
    INTO #TMP_PUSubContrCalc      
    FROM (      
        SELECT *       
        FROM #TMPSlip      
        WHERE ISNULL(AccSeq,0) <> 0       
        ) AS A      
    LEFT OUTER JOIN     --������      
        (SELECT *       
        FROM #TMPSlip      
        WHERE ISNULL(OppAccSeq,0) <> 0      
        ) AS B ON B.CustSeq = A.CustSeq  AND B.SlipMstSeq = A.SlipMstSeq    
    LEFT OUTER JOIN     --�ΰ�������      
        (SELECT *       
        FROM #TMPSlip      
        WHERE ISNULL(VatAccSeq,0) <> 0      
        ) AS C ON C.CustSeq = A.CustSeq  AND C.SlipMstSeq = A.SlipMstSeq    
    LEFT OUTER JOIN _TDAAccount AS F WITH(NOLOCK) ON F.CompanySeq = @CompanySeq AND F.AccSeq = B.OppAccSeq      
    LEFT OUTER JOIN _TDAAccount AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq AND D.AccSeq = A.AccSeq        
          
  
    CREATE TABLE #TMP_ACC_DATA            
    (            
        IDX_NO         INT IDENTITY,              
        SourceSeq      INT,              
        SourceSerl     INT,              
        SourceType     NCHAR(1)          
    )    
      
    INSERT INTO #TMP_ACC_DATA   
    SELECT  DISTINCT              
            A.SourceSeq         AS SourceSeq   , -- ��õ����              
            A.SourceSerl        AS SourceSerl  ,              
            A.SourceType        AS SourceType               
  
    FROM _TPUBuyingAcc AS A WITH(NOLOCK)           
    LEFT OUTER JOIN _TDAAccount AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.AntiAccSeq = F.AccSeq              
    JOIN _TACSlipRow AS SR WITH(NOLOCK) ON SR.CompanySeq = A.CompanySeq AND SR.SlipSeq = A.SlipSeq             
    LEFT OUTER JOIN _TDACust AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.CustSeq = A.CustSeq              
    LEFT OUTER JOIN _TDAAccount AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq AND D.AccSeq = A.AccSeq     
             
    WHERE A.CompanySeq = @CompanySeq            
    AND (@SlipUnit = '' OR SR.SlipUnit = @SlipUnit)        
    AND ( A.BuyingAccDate BETWEEN CASE WHEN @DateFr = '' THEN A.BuyingAccDate ELSE @DateFr END              
    AND CASE WHEN @DateTo = '' THEN A.BuyingAccDate ELSE @DateTo END  )      
--and A.BuyingAccSeq = 37974  
--  
--select * from #TMP_ACC_DATA  
--return  
   -- Payment ��õ���      
     -- PaymentNo�� �������� ���� ���� �߰�               
    CREATE TABLE #Tmp_Payment              
    (              
        IDX_NO         INT ,              
        SourceSeq      INT,              
        SourceSerl     INT,              
        SourceType     NCHAR(1),              
          PaymentNo      NVARCHAR(100),               
        PaymentSeq     INT              
    )              
    CREATE TABLE #TMP_SOURCETABLE             
    (            
        IDOrder INT,             
        TABLENAME   NVARCHAR(100)            
    )       
   -- ��õ ������ ���̺�                  
    CREATE TABLE #TCOMSourceTracking             
    (            
        IDX_NO INT,                         
          IDOrder INT,                         
      Seq  INT,                        
        Serl  INT,                    
        SubSerl     INT,                          
        Qty    DECIMAL(19, 5),              
        STDQty  DECIMAL(19, 5),             
        Amt  DECIMAL(19, 5),             
        VAT   DECIMAL(19, 5)            
    )  
      
    INSERT INTO #Tmp_Payment            
    SELECT IDX_NO    ,       
            SourceSeq ,             
   SourceSerl ,            
            SourceType ,            
            '', 0            
    FROM #TMP_ACC_DATA            
    WHERE SourceType = '1'    
     
--   select * from #Tmp_Payment  
   -------��ǰ ��õ ���---------------          
            
  INSERT #TMP_SOURCETABLE                 
  SELECT 1, '_TPUDelvItem'                    
                     
  EXEC _SCOMSourceTracking  @CompanySeq, '_TPUDelvInItem', '#Tmp_Payment','SourceSeq', 'SourceSerl',''                
           
    SELECT A.IDX_NO ,                 
           I.DelvSeq,          
           I.DelvSerl,          
           I.MakerSeq          
      INTO #TMP_DelvItem          
      FROM #TCOMSourceTracking AS A                 
            JOIN _TPUDelv      AS C WITH(NOLOCK) ON C.CompanySeq  =@CompanySeq AND A.Seq  = C.DelvSeq                 
           JOIN _TPUDelvItem  AS I WITH(NOLOCK) ON I.CompanySeq  =@CompanySeq AND A.Seq = I.DelvSeq AND A.Serl = I.DelvSerl            
     WHERE ISNULL(C.IsReturn, '') <> '1' -- 2011. 3. 3 hkim �߰� ; ��ǰ���� �ߺ��ؼ� ��ǰ �ڵ带 �����ü� �ִ�.           
  
--select * from #TMP_DelvItem  
--return  
    --select * from #TMP_PUSubContrCalc      
    --return      

    INSERT #TMPResultData (SortSeq, OppAccSeq , OppAccName, CustSeq ,CustName ,Remark ,SupplyAmt ,VatAmt,Amt, AccSeq ,VatAccSeq , AccName,SlipSeq ,SlipUnit,SlipUnitName)            
     SELECT     
	     A.OppAccSeq        As SortSeq,            
         A.OppAccSeq        AS OppAccSeq,   -- �������ڵ�              
         F.AccName          AS OppAccName,  -- ������              
         A.CustSeq          AS CustSeq,     -- �ŷ�ó                
         CASE WHEN ISNULL(A.CustSeq,0) = 0 THEN A.CustText ELSE B.CustName  END  AS CustName,    -- �ŷ�ó��                      
         SR.Summary ,                                           
         A.SupplyAmt        AS SupplyAmt,   -- ���ް���                        
         A.VatAmt           AS VatAmt,      -- �ΰ���                          
        ISNULL(A.SupplyAmt,0) + ISNULL(A.VatAmt,0)  AS Amt,         -- �ݾ�                
         A.AccSeq           AS AccSeq,      -- ���������ڵ�                        
         A.VatAccSeq        AS VatAccSeq,   -- �ΰ��������ڵ�                   
         D.AccName          AS AccName,     -- ��������              
         AA.SlipSeq    ,        
         SR.SlipUnit,        
           (SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipUnit = SR.SlipUnit )AS SlipUnitName --��ǥ��������             
    FROM _TARUsualCostAmt         AS A WITH(NOLOCK)               
    LEFT OUTER JOIN _TARUsualCost AS AA WITH(NOLOCK) ON A.CompanySeq = AA.CompanySeq         
                                    AND A.UsualCostSeq = AA.UsualCostSeq         
                                    AND AA.SlipSeq IS NOT NULL            
    JOIN _TACSlipRow AS SR WITH(NOLOCK) ON AA.SlipSeq = SR.SlipSeq         
                        AND AA.CompanySeq = SR.CompanySeq            
    LEFT OUTER JOIN _TDACust    AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.CustSeq = B.CustSeq              
      LEFT OUTER JOIN _TDAEvid    AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.EvidSeq = C.EvidSeq              
    LEFT OUTER JOIN _TDAAccount AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.AccSeq = D.AccSeq              
      LEFT OUTER JOIN _TDAAccount AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq AND A.VatAccSeq = E.AccSeq              
    LEFT OUTER JOIN _TDAAccount AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.OppAccSeq = F.AccSeq              
        LEFT  OUTER JOIN _TARCostAcc AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq  AND A.CostSeq = G.CostSeq              
    LEFT OUTER JOIN _TDAAccountRemValue AS H WITH(NOLOCK) ON G.CompanySeq = H.CompanySeq AND G.RemSeq = H.RemSeq AND A.RemValSeq = H.RemValueSerl            
    LEFT OUTER JOIN _TDAEmp AS I WITH(NOLOCK) ON A.CompanySeq =  I.CompanySeq AND A.EmpSeq = I.EmpSeq            
	LEFT OUTER JOIN _TDADept AS J WITH(NOLOCK) ON A.CompanySeq = J.CompanySeq AND A.DeptSeq = J.DeptSeq            
    LEFT OUTER JOIN _TDACCtr AS K WITH(NOLOCK) ON A.CompanySeq = K.CompanySeq AND A.CCtrSeq = K.CCtrSeq            
    WHERE  (@SlipUnit = '' OR SR.SlipUnit = @SlipUnit)            
    AND ( AA.RegDate BETWEEN CASE WHEN @DateFr = '' THEN AA.RegDate ELSE @DateFr END              
    AND CASE WHEN @DateTo = '' THEN AA.RegDate ELSE @DateTo END  )       
        
	UNION ALL    

	SELECT	1 as SortSeq
	,       A.OppAccSeq
	,		A.OppAccName
	,		A.CustSeq
	,		A.CustName
	,		A.Summary
	,		sum(a.PuAmt) as PuAmt
	,		sum(a.PuVat) as PuVat
	,		sum(a.TotPuAmt) as TotPuAmt
	,		a.accseq
	,		a.vataccseq
	,		a.accname
	,		a.SlipSeq
	,		A.SlipUnit
	,		A.SlipUnitName
	FROM	(
		SELECT	A.AntiAccSeq       AS OppAccSeq    -- �������ڵ�
		,		F.AccName          AS OppAccName   -- ������
		,		A.CustSeq          AS CustSeq      -- �ŷ�ó
		,		BC.CustName        AS CustName     -- �ŷ�ó��
		,		PDS.ProdDistirct   AS Summary
		,		DVA.PuAmt as PuAmt
		,		DVA.PuVat as PuVat
		,		DVA.PuAmt + DVA.PuVat As TotPuAmt,
				A.AccSeq           AS AccSeq,    -- ���������ڵ�                        
				A.VatAccSeq        AS VatAccSeq  -- �ΰ��������ڵ�                   
		,       CASE WHEN ISNULL(L.ValueSeq,0) = 0 THEN '' 
					ELSE ( SELECT ISNULL(MinorName,'') 
							 FROM _TDAUMinor WITH(NOLOCK)   
							WHERE CompanySeq = L.CompanySeq AND MinorSeq = L.ValueSeq ) END + '(' +   -- ǰ���з�  
		--        CASE WHEN ISNULL(K.ValueSeq,0) = 0 THEN '' 
					--ELSE ( SELECT ISNULL(MinorName,'')   
		--                     FROM _TDAUMinor WITH(NOLOCK)   
		--                    WHERE CompanySeq = K.CompanySeq AND MinorSeq = K.ValueSeq ) END AS ItemClassMName,  -- ǰ���ߺз�
			   ISNULL(H.MinorName,'') + ')'      AS AccName, -- ǰ��Һз�
				A.SlipSeq   ,        
				SR.SlipUnit,        
			 (SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipUnit = SR.SlipUnit )AS SlipUnitName --��ǥ��������       
		FROM	_TPUBuyingAcc AS A WITH(NOLOCK)           
		LEFT OUTER JOIN _TDAAccount AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.AntiAccSeq = F.AccSeq              
		JOIN _TACSlipRow AS SR WITH(NOLOCK) ON SR.CompanySeq = A.CompanySeq AND SR.SlipSeq = A.SlipSeq             
		LEFT OUTER JOIN _TDACust AS BC WITH(NOLOCK) ON BC.CompanySeq = A.CompanySeq AND BC.CustSeq = A.CustSeq              
		LEFT OUTER JOIN _TDAAccount AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq AND D.AccSeq = A.AccSeq    
		JOIN #TMP_ACC_DATA AS IT ON IT.SourceSeq = A.SourceSeq            
								AND IT.SourceSerl      = A.SourceSerl            
								AND IT.SourceType      = A.SourceType   
		LEFT OUTER JOIN #TMP_DelvItem   AS DV ON IT.IDX_NO = DV.IDX_NO    
		JOIN hencom_TPUDelvItemAdd AS DVA WITH(NOLOCK) ON DVA.CompanySeq  = @CompanySeq      
																 AND DVA.DelvSeq    = DV.DelvSeq    
																 AND DVA.DelvSerl   = DV.DelvSerl
		LEFT OUTER JOIN hencom_TPUPurchaseArea AS PDS WITH(NOLOCK) ON DVA.ProdDistrictSeq = PDS.ProdDistrictSeq
		  LEFT OUTER JOIN _TDAItemClass		AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq AND  B.UMajorItemClass IN (2001,2004) ) 
		  LEFT OUTER JOIN _TDAUMinor	    AS H WITH(NOLOCK) ON ( B.CompanySeq = H.CompanySeq AND H.MajorSeq = LEFT( B.UMItemClass, 4 ) AND B.UMItemClass = H.MinorSeq )
		  LEFT OUTER JOIN _TDAUMinorValue	AS K WITH(NOLOCK) ON ( H.CompanySeq = K.CompanySeq AND K.MajorSeq IN (2001,2004) AND H.MinorSeq = K.MinorSeq AND K.Serl IN (1001,2001) ) 
		  LEFT OUTER JOIN _TDAUMinorValue	AS L WITH(NOLOCK) ON ( K.CompanySeq = L.CompanySeq AND L.MajorSeq IN (2002,2005) AND K.ValueSeq = L.MinorSeq AND L.Serl = 2001 )
		WHERE A.CompanySeq = @CompanySeq
		AND (@SlipUnit = '' OR SR.SlipUnit = @SlipUnit)        
		AND ( A.BuyingAccDate BETWEEN CASE WHEN @DateFr = '' THEN A.BuyingAccDate ELSE @DateFr END              
		  AND CASE WHEN @DateTo = '' THEN A.BuyingAccDate ELSE @DateTo END  )

		  UNION ALL

		SELECT	A.AntiAccSeq       AS OppAccSeq    -- �������ڵ�
		,		F.AccName          AS OppAccName   -- ������
		,		A.CustSeq          AS CustSeq      -- �ŷ�ó
		,		BC.CustName        AS CustName     -- �ŷ�ó��
		,		PDS.ProdDistirct   AS Summary
		,		DVA.DeliChargeAmt as PuAmt
		,		DVA.DeliChargeVat as PuVat
		,		DVA.DeliChargeAmt + DVA.DeliChargeVat As TotPuAmt,
				A.AccSeq           AS AccSeq,    -- ���������ڵ�                        
				A.VatAccSeq        AS VatAccSeq  -- �ΰ��������ڵ�                   
		,       CASE WHEN ISNULL(L.ValueSeq,0) = 0 THEN '' 
					ELSE ( SELECT ISNULL(MinorName,'') 
							 FROM _TDAUMinor WITH(NOLOCK)   
							WHERE CompanySeq = L.CompanySeq AND MinorSeq = L.ValueSeq ) END + '(' +   -- ǰ���з�  
		--        CASE WHEN ISNULL(K.ValueSeq,0) = 0 THEN '' 
					--ELSE ( SELECT ISNULL(MinorName,'')   
		--                     FROM _TDAUMinor WITH(NOLOCK)   
		--                    WHERE CompanySeq = K.CompanySeq AND MinorSeq = K.ValueSeq ) END AS ItemClassMName,  -- ǰ���ߺз�
			   ISNULL(H.MinorName,'') + ')'      AS AccName, -- ǰ��Һз�
				A.SlipSeq   ,        
				SR.SlipUnit,        
			 (SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipUnit = SR.SlipUnit )AS SlipUnitName --��ǥ��������       
		FROM	_TPUBuyingAcc AS A WITH(NOLOCK)           
		LEFT OUTER JOIN _TDAAccount AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.AntiAccSeq = F.AccSeq              
		JOIN _TACSlipRow AS SR WITH(NOLOCK) ON SR.CompanySeq = A.CompanySeq AND SR.SlipSeq = A.SlipSeq             
		LEFT OUTER JOIN _TDACust AS BC WITH(NOLOCK) ON BC.CompanySeq = A.CompanySeq AND BC.CustSeq = A.CustSeq              
		LEFT OUTER JOIN _TDAAccount AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq AND D.AccSeq = A.AccSeq    
		JOIN #TMP_ACC_DATA AS IT ON IT.SourceSeq = A.SourceSeq            
								AND IT.SourceSerl      = A.SourceSerl            
								AND IT.SourceType      = A.SourceType   
		LEFT OUTER JOIN #TMP_DelvItem   AS DV ON IT.IDX_NO = DV.IDX_NO    
		JOIN hencom_TPUDelvItemAdd AS DVA WITH(NOLOCK) ON DVA.CompanySeq  = @CompanySeq      
																 AND DVA.DelvSeq    = DV.DelvSeq    
																 AND DVA.DelvSerl   = DV.DelvSerl
		LEFT OUTER JOIN hencom_TPUPurchaseArea AS PDS WITH(NOLOCK) ON DVA.ProdDistrictSeq = PDS.ProdDistrictSeq
		  LEFT OUTER JOIN _TDAItemClass		AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq AND  B.UMajorItemClass IN (2001,2004) ) 
		  LEFT OUTER JOIN _TDAUMinor	    AS H WITH(NOLOCK) ON ( B.CompanySeq = H.CompanySeq AND H.MajorSeq = LEFT( B.UMItemClass, 4 ) AND B.UMItemClass = H.MinorSeq )
		  LEFT OUTER JOIN _TDAUMinorValue	AS K WITH(NOLOCK) ON ( H.CompanySeq = K.CompanySeq AND K.MajorSeq IN (2001,2004) AND H.MinorSeq = K.MinorSeq AND K.Serl IN (1001,2001) ) 
		  LEFT OUTER JOIN _TDAUMinorValue	AS L WITH(NOLOCK) ON ( K.CompanySeq = L.CompanySeq AND L.MajorSeq IN (2002,2005) AND K.ValueSeq = L.MinorSeq AND L.Serl = 2001 )
		WHERE A.CompanySeq = @CompanySeq
		AND (@SlipUnit = '' OR SR.SlipUnit = @SlipUnit)        
		AND ( A.BuyingAccDate BETWEEN CASE WHEN @DateFr = '' THEN A.BuyingAccDate ELSE @DateFr END              
		  AND CASE WHEN @DateTo = '' THEN A.BuyingAccDate ELSE @DateTo END  )
		  AND DVA.DeliCustSeq <> 0

		UNION ALL

		SELECT  A.AntiAccSeq       AS OppAccSeq,  -- �������ڵ�              
				F.AccName          AS OppAccName,  -- ������              
				A.CustSeq          AS CustSeq,   -- �ŷ�ó                
				B.CustName         AS CustName,  -- �ŷ�ó��     
				SR.Summary ,        
				-- 1.���ſ����԰�����ó�� ǥ�س�ǰ���μ��� --> ��ǰ�� ��ǥó��   
				-- 2.���ſ����԰�����ó��_HNCOM ����Ʈ��ǰ���μ���-- ��ǰ�̿� ��ǥó��   
				-- ���ڰ��翡���� ��� ��ȸ�Ǿ�� �ϱ� ������ ����Ʈ���̺�(hencom_TPUDelvItemAdd) ������ ���������� �ݾ��� �����ؼ� ��ȸ�Ѵ�.                       
				case  when a.qty = 0 OR ISNULL(DVA.DelvSerl,0) = 0 then a.CurAmt else ISNULL(DVA.PuAmt,0) end  AS PuAmt,        -- ���Աݾ�                          
				case  when a.qty = 0 OR ISNULL(DVA.DelvSerl,0) = 0 then a.CurVAT else ISNULL(DVA.PuVat,0) end AS PuVat,        -- ���Ժΰ���     
				ISNULL(case  when a.qty = 0 OR ISNULL(DVA.DelvSerl,0) = 0 then a.CurAmt else ISNULL(DVA.PuAmt,0) end,0)  + ISNULL(case when a.qty = 0 OR ISNULL(DVA.DelvSerl,0) = 0 then a.CurVAT else ISNULL(DVA.PuVat,0) end ,0)  AS TotPuAmt,                
				A.AccSeq           AS AccSeq,   -- ���������ڵ�                        
				A.VatAccSeq        AS VatAccSeq,  -- �ΰ��������ڵ�                   
				'����'          AS AccName,   -- ��������(D.AccName)
				A.SlipSeq   ,        
				SR.SlipUnit,        
			 (SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipUnit = SR.SlipUnit )AS SlipUnitName --��ǥ��������         
		FROM _TPUBuyingAcc AS A WITH(NOLOCK)           
		LEFT OUTER JOIN _TDAAccount AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.AntiAccSeq = F.AccSeq              
		JOIN _TACSlipRow AS SR WITH(NOLOCK) ON SR.CompanySeq = A.CompanySeq AND SR.SlipSeq = A.SlipSeq             
		LEFT OUTER JOIN _TDACust AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.CustSeq = A.CustSeq              
		LEFT OUTER JOIN _TDAAccount AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq AND D.AccSeq = A.AccSeq    
		JOIN #TMP_ACC_DATA AS IT ON IT.SourceSeq = A.SourceSeq            
								AND IT.SourceSerl      = A.SourceSerl            
								AND IT.SourceType      = A.SourceType   
		LEFT OUTER JOIN #TMP_DelvItem   AS DV ON IT.IDX_NO = DV.IDX_NO    
		LEFT OUTER JOIN hencom_TPUDelvItemAdd AS DVA WITH(NOLOCK) ON DVA.CompanySeq  = @CompanySeq      
																 AND DVA.DelvSeq    = DV.DelvSeq    
																 AND DVA.DelvSerl   = DV.DelvSerl              
		WHERE A.CompanySeq = @CompanySeq            
		AND (@SlipUnit = '' OR SR.SlipUnit = @SlipUnit)        
		AND ( A.BuyingAccDate BETWEEN CASE WHEN @DateFr = '' THEN A.BuyingAccDate ELSE @DateFr END              
		  AND CASE WHEN @DateTo = '' THEN A.BuyingAccDate ELSE @DateTo END  )
		  AND DVA.DelvSeq is Null AND A.AccSeq = 47
	) as a
	GROUP BY A.OppAccSeq
	,		A.OppAccName
	,		A.CustSeq
	,		A.CustName
	,		A.Summary
	,		a.accseq
	,		a.vataccseq
	,		a.accname
	,		a.slipseq
	,		A.SlipUnit
	,		A.SlipUnitName
  
	UNION ALL --WL�����(����ó��)    

		SELECT  2 as SortSeq,
		        A.OppAccSeq     AS OppAccSeq,   -- �������ڵ�              
				F.AccName       AS OppAccName,  -- ������              
				CAR.CustSeq,      
				CAR.CustName,                
				  SR.Summary ,                                             
				ISNULL(M.ContrAmt,0) + ISNULL(M.OTAmt,0) + ISNULL(M.AddPayAmt,0) - ISNULL(M.DeductionAmt,0)    AS SupplyAmt, -- ���ް���                        
				M.CurVAT              AS VatAmt,      -- �ΰ���                          
				ISNULL(M.ContrAmt,0) + ISNULL(M.OTAmt,0) + ISNULL(M.AddPayAmt,0) - ISNULL(M.DeductionAmt,0) + ISNULL(M.CurVAT ,0)  AS Amt,-- �ݾ�                
				A.AccSeq           AS AccSeq,      -- ���������ڵ�                        
				11090501        AS VatAccSeq,   -- �ΰ��������ڵ�                   
				B.AccName          AS AccName,     -- ��������              
				M.SlipSeq    ,        
				SR.SlipUnit,        
				(SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = SR.CompanySeq AND SlipUnit = SR.SlipUnit ) AS SlipUnitName --��ǥ��������      
		   FROM hencom_TPUSubContrWL  AS M WITH (NOLOCK)       
		JOIN _TACSlipRow AS SR WITH(NOLOCK) ON SR.CompanySeq = M.CompanySeq       
											AND SR.SlipSeq = M.SlipSeq       
		LEFT OUTER JOIN _TARCostAcc AS A WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq       
										 AND A.CostSeq = M.CostSeq      
		LEFT OUTER JOIN _TDAAccount AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq       
									 AND A.AccSeq = B.AccSeq        
		  LEFT OUTER JOIN _TDAAccountRem AS C WITH (NOLOCK) ON A.CompanySeq = C.CompanySeq       
										 AND A.RemSeq =  C.RemSeq          
		LEFT OUTER JOIN _TDAAccountRemValue AS D WITH (NOLOCK) ON A.CompanySeq = D.CompanySeq       
											 AND A.RemSeq = D.RemSeq        
											 AND A.RemValSeq = D.RemValueSerl        
		LEFT OUTER JOIN _TDASMinor AS E WITH (NOLOCK) ON A.CompanySeq = E.CompanySEq       
									 AND A.SMKindSeq = E.MinorSeq        
		LEFT OUTER JOIN _TDAAccount AS F WITH (NOLOCK) ON A.CompanySeq = F.CompanySeq       
										 AND A.OppAccSeq = F.AccSeq        
		LEFT OUTER JOIN hencom_VPUContrCarInfo AS CAR WITH (NOLOCK) ON CAR.CompanySeq = M.CompanySeq      
													AND CAR.SubContrCarSeq = M.SubContrCarSeq       
													AND M.WLDate BETWEEN CAR.StartDate AND CAR.EndDate      
      
		WHERE M.CompanySeq= @CompanySeq      
		AND (M.WLDate BETWEEN CASE WHEN @DateFr = '' THEN M.WLDate ELSE @DateFr END        
					 AND CASE WHEN @DateTo = '' THEN M.WLDate ELSE @DateTo END )      
		AND (@SlipUnit = '' OR SR.SlipUnit = @SlipUnit)
      
	UNION ALL --���޿�ݺ�������Ȳ_hencom      

    SELECT  2 as SortSeq,
	        A.OppAccSeq,      
            A.OppAccName,      
            A.Accseq AS CustSeq,      
            (case when A.Accseq = 761 then '����' when A.Accseq = 762 Then '����' End) as CustName ,      
            (case when A.Accseq = 761 then '�ͼ�������ۺ�(����)' when A.Accseq = 762 Then '�ͼ�������ۺ�(����)' End) as Remark,      
            sum(A.SupplyAmt) as SupplyAmt,      
            sum(A.VatAmt) as VatAmt, --�ΰ����ݾ�      
            sum(A.Amt) as Amt,       
            A.AccSeq,      
            A.VatAccSeq ,      
            A.AccName,      
            A.Accseq as SlipSeq ,      
            A.SlipUnit,      
            A.SlipUnitName      
    FROM	#TMP_PUSubContrCalc AS A
	Group by A.OppAccSeq,      
            A.OppAccName,      
            A.Accseq,
			A.VatAccSeq,
			A.AccName,
            A.SlipUnit,
            A.SlipUnitName
    
    /*
	UNION ALL

	--SELECT	a.OppAccSeq as SortSeq
	--,		a.OppAccSeq
	--,		a.OppAccName
	SELECT	107 as SortSeq
	,		107 as OppAccSeq
	,		'�����ޱ�_��ü' as OppAccName
	,		0 as CustSeq
	,		(CASE a.IsOwn WHEN '0' THEN '�ڰ�������' ELSE '' END) as CustName
	,		a.UmCarClassName as Remark
	,		sum(a.TotalOutAmt) as SupplyAmt
	,		sum(a.TotalOutVat) as VatAmt
	,		sum(a.TotalOutSumAmt) as Amt
	,		a.CalAccSeq as AccSeq
	,		0 as VatAccSeq
	,		a.CalAccName as AccName
	,		a.SlipSeq
	,		a.SlipUnit as SlipUnit
	,		(SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipUnit = A.SlipUnit ) AS SlipUnitName
	FROM	(
		  SELECT   A.FuelCalcYM
				  ,A.DeptSeq
				  ,B.DeptName
				  ,A.SubContrCarSeq   
				  ,ISNULL(A.IsOwn, '0') AS IsOwn          
				  ,E.MinorName AS UMCarClassName
				  ,D.CarNo
				  ,CASE WHEN ISNULL(A.SlipSeq, 0) = 0 THEN '0' ELSE '1' END AS IsSlip    --��ǥó������ 
				  ,A.TotalRealDistance
				  ,A.TotalOutQty
				  ,A.TotalOutAmt
				  ,A.ApplyPrice AS RealPrice                  -- �Ǵܰ�(��)
				  ,A.ApplyPrice                               -- ����ܰ�(����)
				  ,A.RealMileage                              -- ��������
				  ,A.StdMileage                               -- ���ؿ���
				  ,A.RefStdMileage
				  ,A.CurAmt
				  ,I.AccName         AS OppAccName   -- ������              
				  ,H.AccName         AS VatAccName
				  ,G.AccName         AS CalAccName
				  ,F.EvidName        AS EvidName
				  ,A.OppAccSeq
				  ,A.VatAccSeq
				  ,A.CalAccSeq
				  ,A.EvidSeq
				  ,A.SlipSeq
				  ,S.SlipID               AS SlipID    -- ��ǥ��ȣ
				   -- 2016.02.03   �߰�
				  ,A.TotalOutAmt * 0.1 AS TotalOutVat                         -- �����ΰ���
				  ,A.TotalOutAmt + (A.TotalOutAmt * 0.1) AS TotalOutSumAmt    -- �����հ�ݾ�
				  --------------�߰��÷�by�ڼ���2016.04.29
				 ,A.STDTotOutQty
				 ,A.SubStdMileage
				 ,A.SubOilAmt
				 ,A.DiffQty
				 ,A.RefTotAmt
				 ,A.RefOppAccSeq
				 ,A.RefVatAccSeq
				 ,A.RefCalAccSeq
				 ,A.RefEvidSeq
				 ,A.Remark
				 ,A.RefStdPrice
				 ,(SELECT AccName FROM _TDAAccount WHERE CompanySeq = @CompanySeq AND AccSeq = A.RefOppAccSeq) AS RefOppAccName
				 ,(SELECT AccName FROM _TDAAccount WHERE CompanySeq = @CompanySeq AND AccSeq = A.RefVatAccSeq) AS RefVatAccName
				 ,(SELECT AccName FROM _TDAAccount WHERE CompanySeq = @CompanySeq AND AccSeq = A.RefCalAccSeq) AS RefCalAccName
				 ,(SELECT EvidName FROM _TDAEvid   WHERE CompanySeq = @CompanySeq AND EvidSeq = A.RefEvidSeq) AS RefEvidName
				 ,A.RetroAmt AS RetroAmt -- �ұ�����(����)
				 ,S.SlipUnit
			 FROM hencom_TPUFuelCalc AS A WITH (NOLOCK) 
			LEFT OUTER JOIN _TDADept AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq 
													  AND B.DeptSeq = A.DeptSeq
			LEFT OUTER JOIN hencom_TPUSubContrCar AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq 
																   AND D.SubContrCarSeq = A.SubContrCarSeq
			LEFT OUTER JOIN _TDAUMinor AS E WITH(NOLOCK) ON E.CompanySeq = D.CompanySeq 
									  AND E.MinorSeq = D.UMCarClass
			   AND E.MajorSeq = 8030   
			JOIN _TACSlipRow AS S WITH(NOLOCK) ON A.CompanySeq = S.CompanySeq AND A.SlipSeq = S.SlipSeq AND S.SlipUnit = @SlipUnit
			 LEFT OUTER JOIN _TDAEvid    AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.EvidSeq = F.EvidSeq    
			LEFT OUTER JOIN _TDAAccount AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq AND A.CalAccSeq = G.AccSeq    
			LEFT OUTER JOIN _TDAAccount AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq AND A.VatAccSeq = H.AccSeq    
			LEFT OUTER JOIN _TDAAccount AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq AND A.OppAccSeq = I.AccSeq   
			WHERE A.CompanySeq   = @CompanySeq
			 --AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq) 
			AND (A.FuelCalcYM = SUBSTRING(@DateFr, 1, 6)) 
			AND ISNULL(A.SlipSeq,0) <> 0
	) A
	Group by (CASE a.IsOwn WHEN '0' THEN 3 ELSE a.OppAccSeq END)
	,		a.OppAccSeq
	,		a.OppAccName
	,		(CASE a.IsOwn WHEN '0' THEN '�ڰ�������' ELSE '' END)
	,		a.UmCarClassName
	,		a.CalAccSeq
	,		a.CalAccName
	,		a.SlipSeq
	,		a.SlipUnit
    */
	UNION ALL

	SELECT	a.RefOppAccSeq SortSeq
	,		a.RefOppAccSeq
	,		a.RefOppAccName
	,		0 as CustSeq
	,		(CASE SIGN(sum(a.RefTotAmt)) WHEN 1 THEN '����ȯ��' WHEN -1 THEN '��������' END) as CustName
	,		A.FuelCalcYM + (CASE SIGN(sum(a.RefTotAmt)) WHEN 1 THEN ' ����ȯ��' WHEN -1 THEN ' ��������' END) as Remark
	,		sum(a.RefTotAmt) as SupplyAmt
	,		sum(0) as VatAmt
	,		sum(a.RefTotAmt) as Amt
	,		a.RefCalAccSeq as AccSeq
	,		0 as VatAccSeq
	,		a.RefCalAccName as AccName
	,		a.SlipSeq
	,		a.SlipUnit as SlipUnit
	,		(SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipUnit = A.SlipUnit ) AS SlipUnitName
	FROM	(
		  SELECT   A.FuelCalcYM
				  ,A.DeptSeq
				  ,B.DeptName
				  ,A.SubContrCarSeq   
				  ,ISNULL(A.IsOwn, '0') AS IsOwn          
				  ,E.MinorName AS UMCarClassName
				  ,D.CarNo
				  ,CASE WHEN ISNULL(A.SlipSeq, 0) = 0 THEN '0' ELSE '1' END AS IsSlip    --��ǥó������ 
				  ,A.TotalRealDistance
				  ,A.TotalOutQty
				  ,A.TotalOutAmt
				  ,A.ApplyPrice AS RealPrice                  -- �Ǵܰ�(��)
				  ,A.ApplyPrice                               -- ����ܰ�(����)
				  ,A.RealMileage                              -- ��������
				  ,A.StdMileage                               -- ���ؿ���
				  ,A.RefStdMileage
				  ,A.CurAmt
				  ,I.AccName         AS OppAccName   -- ������              
				  ,H.AccName         AS VatAccName
				  ,G.AccName         AS CalAccName
				  ,F.EvidName        AS EvidName
				  ,A.OppAccSeq
				  ,A.VatAccSeq
				  ,A.CalAccSeq
				  ,A.EvidSeq
				  ,A.SlipSeq
				  ,S.SlipID               AS SlipID    -- ��ǥ��ȣ
				   -- 2016.02.03   �߰�
				  ,A.TotalOutAmt * 0.1 AS TotalOutVat                         -- �����ΰ���
				  ,A.TotalOutAmt + (A.TotalOutAmt * 0.1) AS TotalOutSumAmt    -- �����հ�ݾ�
				  --------------�߰��÷�by�ڼ���2016.04.29
				 ,A.STDTotOutQty
				 ,A.SubStdMileage
				 ,A.SubOilAmt
				 ,A.DiffQty
				 ,A.RefTotAmt
				 ,A.RefOppAccSeq
				 ,A.RefVatAccSeq
				 ,A.RefCalAccSeq
				 ,A.RefEvidSeq
				 ,A.Remark
				 ,A.RefStdPrice
				 ,(SELECT AccName FROM _TDAAccount WHERE CompanySeq = @CompanySeq AND  AccSeq = A.RefOppAccSeq) AS RefOppAccName
				 ,(SELECT AccName FROM _TDAAccount WHERE CompanySeq = @CompanySeq AND AccSeq = A.RefVatAccSeq) AS RefVatAccName
				 ,(SELECT AccName FROM _TDAAccount WHERE CompanySeq = @CompanySeq AND AccSeq = A.RefCalAccSeq) AS RefCalAccName
				 ,(SELECT EvidName FROM _TDAEvid   WHERE CompanySeq = @CompanySeq AND EvidSeq = A.RefEvidSeq) AS RefEvidName
				 ,A.RetroAmt AS RetroAmt -- �ұ�����(����)
				 ,S.SlipUnit
			 FROM hencom_TPUFuelCalc AS A WITH (NOLOCK) 
			LEFT OUTER JOIN _TDADept AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq 
													  AND B.DeptSeq = A.DeptSeq
			LEFT OUTER JOIN hencom_TPUSubContrCar AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq 
																   AND D.SubContrCarSeq = A.SubContrCarSeq
			LEFT OUTER JOIN _TDAUMinor AS E WITH(NOLOCK) ON E.CompanySeq = D.CompanySeq 
									  AND E.MinorSeq = D.UMCarClass
			   AND E.MajorSeq = 8030   
			JOIN _TACSlipRow AS S WITH(NOLOCK) ON A.CompanySeq = S.CompanySeq AND A.SlipSeq = S.SlipSeq AND S.SlipUnit = @SlipUnit
			 LEFT OUTER JOIN _TDAEvid    AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.EvidSeq = F.EvidSeq    
			LEFT OUTER JOIN _TDAAccount AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq AND A.CalAccSeq = G.AccSeq    
			LEFT OUTER JOIN _TDAAccount AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq AND A.VatAccSeq = H.AccSeq    
			LEFT OUTER JOIN _TDAAccount AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq AND A.OppAccSeq = I.AccSeq   
			WHERE A.CompanySeq   = @CompanySeq
			 --AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq) 
			AND (A.FuelCalcYM = SUBSTRING(@DateFr, 1, 6)) 
			AND ISNULL(A.RefCalAccSeq,0) <> 0
	) A
	Group by (CASE a.IsOwn WHEN '0' THEN 2 ELSE 9 END)
	,		a.RefOppAccSeq
	,		a.RefOppAccName
	,		(CASE a.IsOwn WHEN '0' THEN '' ELSE '' END)
	,		A.FuelCalcYM
	,		a.RefCalAccSeq
	,		a.RefCalAccName
	,		a.SlipSeq
	,		a.SlipUnit

	UPDATE #TMPResultData SET SortSeq = 2 WHERE OppAccSeq = 580 -- �����ޱ�_���޺� ���� ����

    --select * from #TMPResultData return  
--��ü��ǥ�ϰ�ó��_hncom ȭ�� ��ȸ����� ���� �ӽ����̺� ����.
    CREATE TABLE #TMPBSSlipData 
    (        
        SlipKind INT  --��ǥ�а����������ڵ�        
        ,SlipKindName NVARCHAR(200)  --��ǥ�а�����(������)        
        ,SlipMstID NVARCHAR(200) --��ǥ��ȣ(��ǥ�����͹�ȣ)        
        ,SetSlipNo NVARCHAR(200)--��ǥ��ȣ(������ �����Ϸù�ȣ)        
        ,RegEmpName NVARCHAR(200)--��ǥ��(������)        
        ,RegAccDate NVARCHAR(8) --��ǥ��(������)        
        ,SlipUnitName NVARCHAR(200)--��ǥ��������        
        ,SlipMstSeq INT--��ǥ�����ͳ����ڵ�        
        ,SlipUnit INT--��ǥ���������ڵ�        
        ,RowNo NVARCHAR(200) --���ȣ        
        ,SlipID NVARCHAR(200)--��ǥ��ǥ��ȣ        
        ,AccName NVARCHAR(200)--��������        
        ,AccSeq INT       
        ,DrAmt DECIMAL(19,5) --�����ݾ�        
        ,SlipSeq INT --��ǥ�����ڵ�        
        ,CrAccName NVARCHAR(200)        
        ,CrAmt    DECIMAL(19,5)    
        ---------------------1        
 ,RemSeq1   INT           
        ,IsDrEss1   NCHAR(1)      
        ,IsCrEss1        NCHAR(1)
        ,RemName1    NVARCHAR(100)    
        ,CellType1      NVARCHAR(100)  
        ,CodeHelpSeq1       INT
        ,CodeHelpParams1   NVARCHAR(100)   
        ,RemValue1     NVARCHAR(200) 
        ,RemValSeq1  INT
        ---------------------2         
        ,RemSeq2  INT           
        ,IsDrEss2 NCHAR(1)        
        ,IsCrEss2   NCHAR(1)     
        ,RemName2 NVARCHAR(100)       
        ,CellType2  NVARCHAR(100)      
        ,CodeHelpSeq2   INT     
        ,CodeHelpParams2 NVARCHAR(100)     
        ,RemValue2 NVARCHAR(200)     
        ,RemValSeq2  INT
        ---------------------3        
        ,RemSeq3  INT            
        ,IsDrEss3  NCHAR(1)      
        ,IsCrEss3     NCHAR(1)   
        ,RemName3    NVARCHAR(100)       
        ,CellType3 NVARCHAR(100)       
        ,CodeHelpSeq3  INT
        ,CodeHelpParams3    NVARCHAR(100)  
        ,RemValue3    NVARCHAR(200)   
    ,RemValSeq3  INT
        ---------------------4        
 ,RemSeq4   INT            
        ,IsDrEss4 NCHAR(1)       
        ,IsCrEss4  NCHAR(1)      
        ,RemName4 NVARCHAR(100)        
        ,CellType4 NVARCHAR(100)       
        ,CodeHelpSeq4  INT      
        ,CodeHelpParams4  NVARCHAR(100)    
        ,RemValue4   NVARCHAR(200)  
        ,RemValSeq4  INT
        ---------------------5        
        ,RemSeq5 INT            
        ,IsDrEss5  NCHAR(1)      
        ,IsCrEss5  NCHAR(1)      
        ,RemName5  NVARCHAR(100)      
        ,CellType5   NVARCHAR(100)     
        ,CodeHelpSeq5  INT      
        ,CodeHelpParams5 NVARCHAR(100)     
        ,RemValue5    NVARCHAR(100)
        ,RemValSeq5 INT 
        ---------------------6        
        ,RemSeq6  INT             
        ,IsDrEss6 NCHAR(1)       
        ,IsCrEss6    NCHAR(1)    
        ,RemName6  NVARCHAR(100)      
        ,CellType6 NVARCHAR(100)        
        ,CodeHelpSeq6 INT       
        ,CodeHelpParams6 NVARCHAR(100)      
        ,RemValue6    NVARCHAR(200)  
        ,RemValSeq6  INT
        ---------------------7        
        ,RemSeq7   INT           
        ,IsDrEss7   NCHAR(1)     
        ,IsCrEss7     NCHAR(1)   
        ,RemName7 NVARCHAR(100)       
        ,CellType7  NVARCHAR(100)      
        ,CodeHelpSeq7 INT       
        ,CodeHelpParams7   NVARCHAR(100)  
        ,RemValue7  NVARCHAR(200)    
        ,RemValSeq7  INT
        ---------------------8        
        ,RemSeq8  INT          
        ,IsDrEss8 NCHAR(1)       
        ,IsCrEss8 NCHAR(1)       
        ,RemName8 NVARCHAR(100)       
        ,CellType8  NVARCHAR(100)      
        ,CodeHelpSeq8 INT       
        ,CodeHelpParams8   NVARCHAR(100)   
        ,RemValue8   NVARCHAR(200)   
        ,RemValSeq8  INT
        ---------------------9      
        ,RemSeq9 INT           
        ,IsDrEss9 NCHAR(1)        
        ,IsCrEss9 NCHAR(1)       
        ,RemName9  NVARCHAR(100)      
        ,CellType9  NVARCHAR(100)      
        ,CodeHelpSeq9 INT        
        ,CodeHelpParams9  NVARCHAR(100)    
        ,RemValue9 NVARCHAR(200)     
        ,RemValSeq9 INT  
        ---------------------10        
        ,RemSeq10 INT              
        ,IsDrEss10  NCHAR(1)      
        ,IsCrEss10 NCHAR(1)       
        ,RemName10 NVARCHAR(100)       
        ,CellType10 NVARCHAR(100)       
        ,CodeHelpSeq10  INT      
        ,CodeHelpParams10 NVARCHAR(100)   
        ,RemValue10  NVARCHAR(200)    
        ,RemValSeq10 INT 
        ------------------------------------        
        ,DrRemValue INT--����������(����)�����׸��ڵ� : ������ ��ǥ�� ���������� ����.     
        ,DrRemName NVARCHAR(200) --����������(����)�����׸�      
        ,CrRemValue INT  --����������(�뺯)�����׸� : ������ ��ǥ�� �뺯������ ����.     
        ,CrRemName NVARCHAR(200)--����������(�뺯)�����׸�      
        ,ProcSlipSeq INT--������ ��ǥ�����ڵ�    
        ,Sort1Remseq INT -- ������������ �����׸�1��  
        ,Sort2Remseq INT -- ������������ �����׸�2��  
        ,Sort3Remseq INT -- ������������ �����׸�3��  
        ,AccDate NCHAR(8) --ȸ����  
        ,Summary  NVARCHAR(1000)
        ,CostDeptSeq INT--�ͼӺμ�         
        ,CostCCtrSeq INT--Ȱ������         
        ,CostDeptName  NVARCHAR(200)
        ,CostCCtrName  NVARCHAR(200) 
        ,AccUnit    INT--ȸ�����  
        ,CrtSlipUnit INT --��ǥ����  
        ,CrtBgtDeptSeq INT--����μ�  
        ,DrUMCostType INT --����������(����)�����׸� ������ ��뱸��    
        ,CrUMCostType INT --����������(�뺯)�����׸� : ������ ��ǥ�� �뺯������ ��뱸��  
    )
    --BS��ü��ǥ�ϰ�ó�������� ��ȸ   
    INSERT #TMPBSSlipData         
    EXEC hencom_SACBalanceSubProcQuery @CompanySeq,@DateFr,@DateTo,@SlipUnit            
    

    INSERT #TMPResultData (SortSeq, OppAccSeq, OppAccName, CustSeq ,CustName ,Remark  ,SupplyAmt ,VatAmt,Amt, AccSeq ,VatAccSeq , AccName, SlipSeq )            
    SELECT
	CrRemValue      AS SortSeq  ,   -- �������ڵ�              
    CrRemValue      AS OppAccSeq,   -- �������ڵ�                
    CrRemName       AS OppAccName,  -- ������
	0               AS CustSeq,     -- �ŷ�ó                
    ''              AS CustName,    -- �ŷ�ó��
    Summary         AS Remark,      -- ���                                               
    DrAmt           AS SupplyAmt,   -- ���ް���
    0               AS VatAmt,      -- �ΰ���                   
    DrAmt           AS Amt,         -- �ݾ�                       
    DrRemValue      AS AccSeq,      -- ���������ڵ�                        
    0               AS VatAccSeq,   -- �ΰ��������ڵ�                   
    DrRemName       AS AccName,      -- ��������                
    ProcSlipSeq     AS SlipSeq            
    FROM #TMPBSSlipData            
    WHERE ISNULL(ProcSlipSeq,0) <> 0            

  
  SELECT 1 AS Gubun, SortSeq, OppAccSeq , OppAccName, CustSeq ,CustName ,Remark ,SupplyAmt ,VatAmt,Amt, AccSeq ,VatAccSeq , AccName,SlipSeq            
  INTO #TMPQuery            
  FROM #TMPResultData            
UNION ALL            
  SELECT  2 AS Gubun,           
          ISNULL(SortSeq,0) AS SortSeq ,  
          ISNULL(OppAccSeq,0) AS OppAccSeq ,             
          ' �Ұ�' AS OppAccName,             
          0 CustSeq ,            
          '' CustName ,            
          ISNULL(OppAccName,'')+  ' �Ұ�' Remark ,            
          SUM(ISNULL(SupplyAmt,0)) AS  SupplyAmt ,            
          SUM(ISNULL(VatAmt,0)) AS VatAmt,            
          SUM(ISNULL(Amt,0)) AS Amt,              
          0 AccSeq ,            
          0 VatAccSeq ,             
          '' AccName ,            
          0 SlipSeq            
  FROM #TMPResultData            
    GROUP BY ISNULL(SortSeq,0), ISNULL(OppAccSeq,0),ISNULL(OppAccName,'')            
  UNION ALL            
  SELECT  3 AS Gubun,     
          9999 as SortSeq,
          MAX(OppAccSeq) +1  AS OppAccSeq ,             
          ' �Ѱ�' AS OppAccName,             
          0 CustSeq ,            
          '' CustName ,            
          ' �Ѱ�' Remark ,            
          SUM(ISNULL(SupplyAmt,0)) AS  SupplyAmt ,            
          SUM(ISNULL(VatAmt,0)) AS VatAmt,            
          SUM(ISNULL(Amt,0)) AS Amt,             
          0 AS AccSeq ,            
            0 AS VatAccSeq ,             
          '' AS AccName ,            
          0  AS SlipSeq            
  FROM #TMPResultData            
    
  
  --SELECT * FROM #TMPQuery RETURN  
  
  SELECT *  ,          
        ----------------���ڰ����          
        LEFT(@DateFr,4)+'-'+SUBSTRING(@DateFr,5,2)+'-'+SUBSTRING(@DateFr,7,2) AS DateFr_GW,          
        LEFT(@DateTo,4)+'-'+SUBSTRING(@DateTo,5,2)+'-'+SUBSTRING(@DateTo,7,2) AS DateTo_GW,          
         (SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipUnit = @SlipUnit) AS SlipUnitName  
  FROM #TMPQuery  
  ORDER by SortSeq, OppAccSeq, Gubun ,CustName

  RETURN  
  go
begin tran 
EXEC hencom_SACPUSlipProcDataQuery @xmlDocument = N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <DateFr>20170501</DateFr>
    <DateTo>20170531</DateTo>
    <SlipUnit>20</SlipUnit>
  </DataBlock1>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 1038078, @WorkingTag = N'', @CompanySeq = 1, @LanguageSeq = 1, @UserSeq = 1, @PgmSeq = 1031103

rollback 