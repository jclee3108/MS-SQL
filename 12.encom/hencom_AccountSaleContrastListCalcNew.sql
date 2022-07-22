IF OBJECT_ID('hencom_AccountSaleContrastListCalcNew') IS NOT NULL 
    DROP PROC hencom_AccountSaleContrastListCalcNew
GO 

-- v2017.03.29 

/************************************************************
 ��  �� - ������-ȸ��/���� �ܾ׺�_hencom : �μ�,�ŷ�ó�� ����ȸ
 �ۼ��� - 20161120
 �ۼ��� - ������
************************************************************/
CREATE PROC dbo.hencom_AccountSaleContrastListCalcNew
	@CompanySeq	    INT 	= 1,            
	@CustSeq         INT ,
    @SlipUnit        INT ,
    @BasicYM         NCHAR(6)
AS        
	
	DECLARE @docHandle      INT,
		    @BasicYMD         NCHAR(8),
            @SQL              NVARCHAR(MAX)
	SET	@BasicYMD = @BasicYM + '31'

	-- ��ǥ���������� ����Ҹ� Select
	SELECT	M.DeptSeq,M.DeptName ,A.DispSeq, M.SlipUnit, C.SlipUnitName
	INTO	#TMPMst
	FROM	_TDADept AS M                        
		LEFT OUTER JOIN hencom_TDADeptAdd  AS A WITH (NOLOCK) ON A.CompanySeq = @CompanySeq                     
															 AND A.DeptSeq = M.DeptSeq
		JOIN _TACSlipUnit AS C WITH(NOLOCK) ON M.SlipUnit = C.SlipUnit
	Where	(@SlipUnit = 0 or M.SlipUnit = @SlipUnit)
	AND		IsNull(A.UMTotalDiv,0) <> 0

	-- �ܻ�����(������) ���� : �̿��ܾ�
	SELECT	a.deptseq
	,		a.custseq
	,		sum(a.CurAmt) AS TempSLRemainAmt
	INTO	#TempSLRemainAmt
	FROM	hencom_VInvoiceReplaceItem AS a WITH(NOLOCK)
		LEFT OUTER JOIN _TSLBill AS BL WITH(NOLOCK) ON BL.CompanySeq = @CompanySeq AND BL.BillSeq = A.BillSeq
		JOIN #TMPMst AS Dept ON a.DeptSeq = Dept.DeptSeq
		LEFT OUTER JOIN hencom_TSLPreSalesMapping AS PSM WITH(NOLOCK) ON PSM.ToTableSeq = A.SourceTableSeq
																		AND PSM.ToSeq =     
																		(CASE A.SourceTableSeq WHEN 1268 THEN A.InvoiceSeq     
																			WHEN 1000057 THEN A.SumMesKey    
																			WHEN 1000075 THEN A.ReplaceRegSeq    
																			END  )    
																		AND PSM.ToSerl =     
																	(CASE A.SourceTableSeq WHEN 1268 THEN A.InvoiceSerl     
																			WHEN 1000057 THEN 0    
																			WHEN 1000075 THEN A.ReplaceRegSerl    
																			END  )
         LEFT OUTER JOIN hencom_ViewPreSalesSource AS VPS ON VPS.FromTableSeq = PSM.FromTableSeq     
                                                         AND VPS.FromSeq = PSM.FromSeq     
                                                         AND VPS.FromSerl = PSM.FromSerl  
	WHERE	a.WorkDate <= @BasicYMD
	AND		(a.BillSeq = 0 or BL.BillDate > @BasicYMD)
	AND		VPS.FromSeq is Null
	Group by a.deptseq
	,		a.custseq

	 --select * from #TempSLRemainAmt

	-- �ܻ�����(������) ���� : �԰ݴ�ü ��ó�� �ܾ�
 	---------------------------
     -- TEMP TABLE ����
	---------------------------
	 -- ����
     CREATE TABLE #TempResult2(DeptSeq INT, CustSeq INT, PJTSeq INT, WorkDate NCHAR(8), SumMesKey NVARCHAR(30), SumMesKeyNo INT,  
                               GoodItemSeq INT, CurAmt DECIMAL(19,5), ReplaceRegSeq INT, ReplaceRegSerl INT,  ReplaceRegNo int, 
                               RepCustSeq INT, RepPJTSeq INT, RepItemSeq INT, RepCurAmt DECIMAL(19,5), 
                               ATARegSeq INT, GapAmt DECIMAL(19,5), AdjAmt DECIMAL(19,5), SlipSeq INT, IsAllReplace NCHAR(1), SortOrd int,
                               DataType INT)      
                                 
     -- ����                         
     CREATE TABLE #result ( SumMesKey int , ReplaceRegSeq int , RepCustSeq INT, Gubun nvarchar(200), GubunSeq INT )   
     
     -- ����                                  
     CREATE TABLE #TempResult(DeptSeq INT, CustSeq INT, PJTSeq INT, WorkDate NCHAR(8), SumMesKey NVARCHAR(30), SumMesKeyNo INT,  
                               GoodItemSeq INT, CurAmt DECIMAL(19,5), ReplaceRegSeq INT, ReplaceRegSerl INT,   
                               RepCustSeq INT, RepPJTSeq INT, RepItemSeq INT, RepCurAmt DECIMAL(19,5), 
                               ATARegSeq INT, GapAmt DECIMAL(19,5), AdjAmt DECIMAL(19,5), SlipSeq INT, IsAllReplace NCHAR(1), 
                               Gubun NVARCHAR(200), GubunSeq INT, IDX INT,
                               CrAmt DECIMAL(19,5), CrAccSeq INT, CrCustSeq INT, DrAmt DECIMAL(19,5), DrAccSeq INT, DrCustSeq INT, DataType INT)

     INSERT INTO #TempResult2(DeptSeq, CustSeq, PJTSeq, WorkDate, SumMesKey, SumMesKeyNo, GoodItemSeq, CurAmt,   
                              ReplaceRegSeq, ReplaceRegSerl,ReplaceRegNo, RepCustSeq, RepPJTSeq, RepItemSeq, RepCurAmt, 
                              ATARegSeq, GapAmt, AdjAmt, SlipSeq, IsAllReplace, SortOrd, DataType)  
     SELECT CASE WHEN A.UMOutType = 8020097 THEN A.PurDeptSeq ELSE A.DeptSeq END AS DeptSeq,    
            A.CustSeq,    
            A.PJTSeq,    
            A.WorkDate,     
            A.SumMesKey,     
            ROW_NUMBER() OVER (PARTITION BY A.SumMesKey ORDER BY a.SumMesKey) AS SumMesKeyNo,    
            A.GoodItemSeq,    
            A.CurAmt,    
            M.ReplaceRegSeq,    
            M.ReplaceRegSerl,  
			ROW_NUMBER() OVER (PARTITION BY M.ReplaceRegSeq,M.ReplaceRegSerl ORDER BY M.ReplaceRegSeq,M.ReplaceRegSerl) AS ReplaceRegNo,      
            RI.CustSeq as RepCustSeq,        
            RI.PJTSeq as RepPJTSeq,    
            RI.ItemSeq as RepItemSeq,    
            M.CurAmt as RepCurAmt,    
            0 as ATARegSeq,
            ISNULL(A.CurAmt,0) - ISNULL(M.CurAmt,0),
            --ISNULL(B.AdjAmt,0),
			0 as AdjAmt,
            0 as SlipSeq,
            '0',
			case when a.CustSeq = ri.CustSeq then 1 else 100 end, 
            1 AS Datatype -- ���
       FROM hencom_TIFProdWorkReportCloseSum AS A WITH(NOLOCK)     
       LEFT OUTER JOIN hencom_TSLCloseSumReplaceMapping AS M WITH(NOLOCK) ON M.CompanySeq = A.CompanySeq    
                                                                         AND M.SumMesKey = A.SumMesKey    
       LEFT OUTER JOIN hencom_TSLInvoiceReplaceItem AS RI WITH(NOLOCK) ON RI.CompanySeq = A.CompanySeq    
                                                                      AND RI.ReplaceRegSeq = M.ReplaceRegSeq    
                                                                      AND RI.ReplaceRegSerl = M.ReplaceRegSerl         
       --LEFT OUTER JOIN hencom_TAcAdjTempAccount AS B WITH(NOLOCK) ON B.CompanySeq = M.CompanySeq
       --                                                          AND B.ReplaceRegSeq = M.ReplaceRegSeq
       --LEFT OUTER JOIN _TACSlipRow AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq
       --                                             AND C.SlipSeq = B.SlipSeq
      WHERE A.CompanySeq = @CompanySeq    
        AND A.WorkDate BETWEEN LEFT(@BasicYMD,4) + '0101' AND @BasicYMD
        AND (CASE WHEN A.UMOutType = 8020097 THEN A.PurDeptSeq ELSE A.DeptSeq END) in (
			select DeptSeq from #TMPMst
		)
        AND ISNULL(a.SalesSeq,0) <> 0    
        AND ISNULL(ri.IsPreSales,'0') <> '1'  
		and m.IsReplace = '1'
		--and	m.ReplaceRegSeq in (405, 406, 802)


     INSERT INTO #TempResult2(DeptSeq, CustSeq, PJTSeq, WorkDate, SumMesKey, SumMesKeyNo, GoodItemSeq, CurAmt,   
                              ReplaceRegSeq, ReplaceRegSerl,ReplaceRegNo, RepCustSeq, RepPJTSeq, RepItemSeq, RepCurAmt, 
                              ATARegSeq, GapAmt, AdjAmt, SlipSeq, IsAllReplace, SortOrd, DataType)  
     SELECT CASE WHEN A.UMOutType = 8020097 THEN A.PurDeptSeq ELSE A.DeptSeq END AS DeptSeq,    
            A.CustSeq,    
            A.PJTSeq,    
            A.WorkDate,     
            A.SumMesKey,     
            ROW_NUMBER() OVER (PARTITION BY A.SumMesKey ORDER BY a.SumMesKey) AS SumMesKeyNo,    
            A.GoodItemSeq,    
            A.CurAmt,    
            M.ReplaceRegSeq,    
            M.ReplaceRegSerl,  
			ROW_NUMBER() OVER (PARTITION BY M.ReplaceRegSeq,M.ReplaceRegSerl ORDER BY M.ReplaceRegSeq,M.ReplaceRegSerl) AS ReplaceRegNo,      
            RI.CustSeq as RepCustSeq,        
            RI.PJTSeq as RepPJTSeq,    
            RI.ItemSeq as RepItemSeq,    
            M.CurAmt as RepCurAmt,    
            0 as ATARegSeq,
            ISNULL(A.CurAmt,0) - ISNULL(M.CurAmt,0),
            --ISNULL(B.AdjAmt,0),
			0 as AdjAmt,
            0 as SlipSeq,
            '0',
			case when a.CustSeq = ri.CustSeq then 1 else 100 end, 
            2 AS Datatype -- �����⵵
       FROM hencom_TIFProdWorkReportCloseSum AS A WITH(NOLOCK)     
       LEFT OUTER JOIN hencom_TSLCloseSumReplaceMapping AS M WITH(NOLOCK) ON M.CompanySeq = A.CompanySeq    
                                                                         AND M.SumMesKey = A.SumMesKey    
       LEFT OUTER JOIN hencom_TSLInvoiceReplaceItem AS RI WITH(NOLOCK) ON RI.CompanySeq = A.CompanySeq    
                                                                      AND RI.ReplaceRegSeq = M.ReplaceRegSeq    
                                                                      AND RI.ReplaceRegSerl = M.ReplaceRegSerl         
       --LEFT OUTER JOIN hencom_TAcAdjTempAccount AS B WITH(NOLOCK) ON B.CompanySeq = M.CompanySeq
       --                                                          AND B.ReplaceRegSeq = M.ReplaceRegSeq
       --LEFT OUTER JOIN _TACSlipRow AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq
       --                                             AND C.SlipSeq = B.SlipSeq
      WHERE A.CompanySeq = @CompanySeq    
        AND A.WorkDate <= CONVERT(NCHAR(8),DATEADD(DAY,-1,LEFT(@BasicYMD,4) + '0101'),112)
        AND (CASE WHEN A.UMOutType = 8020097 THEN A.PurDeptSeq ELSE A.DeptSeq END) in (
			select DeptSeq from #TMPMst
		)
        AND ISNULL(a.SalesSeq,0) <> 0    
        AND ISNULL(ri.IsPreSales,'0') <> '1'  
		and m.IsReplace = '1'
		--and	m.ReplaceRegSeq in (405, 406, 802)
    


	---------------------------
     -- ������ �����ϴ� �� ������Ʈ
	---------------------------
    UPDATE #TempResult2
       SET IsAllReplace = '1'
      FROM #TempResult2 AS A
      JOIN (SELECT ReplaceRegSeq, COUNT(distinct RepCustSeq) AS CustIDX
              FROM #TempResult2
             GROUP BY ReplaceRegSeq) AS B ON B.ReplaceRegSeq = A.ReplaceRegSeq
     WHERE CustIDX > 1

	update #TempResult2
	   set SortOrd = 0
     from #TempResult2 as a
	 join (
			select SumMesKey , min(summeskeyno) as SumMesKeyNo
			  from #TempResult2
			 where SortOrd = 1
			group by SumMesKey
			having count(*) > 1
		  ) as b on b.SumMesKey = a.SumMesKey
		        and b.SumMesKeyNo <> a.SumMesKeyNo
	where a.SumMesKey in (  select  summeskey from #TempResult2 where SumMesKeyNo > 1)
	  and a.SortOrd = 1
		  
	 update #TempResult2
	    set SumMesKeyNo = case when SortOrd = 1 then 1 else SortOrd + SumMesKeyNo end
      where SumMesKey in (  select  summeskey from #TempResult2 where SumMesKeyNo > 1)

    UPDATE #TempResult2    
       SET CurAmt = 0
     WHERE SumMesKeyNo > 1   
     
    UPDATE #TempResult2    
       SET GapAmt = ISNULL(CurAmt,0) - ISNULL(RepCurAmt,0) -- ���̱ݾ�����
     WHERE SumMesKeyNo > 1       

    update a
	   set ATARegSeq = b.ATARegSeq,
	       SlipSeq = b.SlipSeq,
		   AdjAmt = b.AdjAmt
 	  from #TempResult2 as a 
	  join hencom_TAcAdjTempAccount as b on b.CompanySeq = @CompanySeq
	                                    and b.ReplaceRegSeq = a.ReplaceRegSeq
										and b.AdjAmt = GapAmt
										and b.slipseq <> 0

    update a
	   set ATARegSeq = b.ATARegSeq,
	       SlipSeq = b.SlipSeq,
		   AdjAmt = b.AdjAmt
 	  from #TempResult2 as a 
	  join hencom_TAcAdjTempAccount as b on b.CompanySeq = @CompanySeq
	                                    and b.ReplaceRegSeq = a.ReplaceRegSeq
										and b.slipseq <> 0
     where isnull(a.ATARegSeq,0) = 0

	---------------------------
     -- ����(1:�ŷ�ó����/���״�ü, 2: �ݾ׺���, 3:�ݾװŷ�ó����, 4:�ŷ�ó����/�Ϻδ�ü)
	---------------------------
    INSERT #result (SumMesKey, ReplaceRegSeq, RepCustSeq, Gubun, GubunSeq)    
    SELECT cu.SumMesKey,    
           at.ReplaceRegSeq,    
           AT.RepCustSeq,
           '�ݾװŷ�ó����' AS gubun,
           3 AS GubunSeq    
      FROM (SELECT ReplaceRegSeq,
           RepCustSeq,    
                   '�ݾ׺���' AS gubun,
                   2 AS GubunSeq    
             FROM #TempResult2    
            GROUP BY ReplaceRegSeq, RepCustSeq      
           HAVING SUM(curamt) <> SUM(repcuramt)) AS AT  
      JOIN (SELECT DISTINCT SumMesKey,    
                   ReplaceRegSeq,  
                   RepCustSeq,  
                   '�ŷ�ó����/���״�ü' AS gubun  ,
                   1 AS GubunSeq      
              FROM #TempResult2    
               WHERE custseq <> repcustseq) AS cu on at.ReplaceRegSeq = cu.ReplaceRegSeq   
                                                 AND AT.RepCustSeq = CU.RepCustSeq
                 
    INSERT #result ( ReplaceRegSeq, RepCustSeq, Gubun, GubunSeq )    
    SELECT a.ReplaceRegSeq,    
           a.RepCustSeq,
           '�ݾ׺���'    ,
           2 AS GubunSeq      
      FROM (SELECT ReplaceRegSeq, RepCustSeq    
              FROM #TempResult2    
             GROUP BY ReplaceRegSeq, RepCustSeq      
            HAVING SUM(curamt) <> SUM(repcuramt)) AS a    
     WHERE NOT EXISTS (SELECT ReplaceRegSeq FROM #result WHERE ReplaceRegSeq = A.ReplaceRegSeq AND RepCustSeq = A.RepCustSeq)     
    
    INSERT #result         
    SELECT SumMesKey,    
           ReplaceRegSeq,    
           RepCustSeq,
           '�ŷ�ó����/���״�ü',
           1 AS GubunSeq     
      FROM (SELECT DISTINCT SumMesKey,    
                   ReplaceRegSeq,
                   RepCustSeq  
              FROM #tempresult2    
             WHERE custseq <> repcustseq             
            except    
            SELECT SumMesKey, ReplaceRegSeq, RepCustSeq    
              FROM #result   
             WHERE --Gubun = '�ݾװŷ�ó����'
                   GubunSeq = 3) AS A    
     WHERE NOT EXISTS (SELECT ReplaceRegSeq FROM #result WHERE ReplaceRegSeq = A.ReplaceRegSeq AND RepCustSeq = A.RepCustSeq)     
                   

	--select 2222,* from #result where ReplaceRegSeq = 3093

    --SELECT '#tempresult2', R.Gubun, A.* FROM #tempresult2 AS A    
    --  JOIN (SELECT DISTINCT ReplaceRegSeq, gubun, GubunSeq  
    --          FROM #result) AS R on R.ReplaceRegSeq = A.ReplaceRegSeq    
    -- ORDER BY A.ReplaceRegSeq
    
	---------------------------
     -- �����������������̺�
	---------------------------
     INSERT INTO #TempResult(DeptSeq, CustSeq, PJTSeq, WorkDate, SumMesKey, SumMesKeyNo, GoodItemSeq, CurAmt,   
                             ReplaceRegSeq, ReplaceRegSerl, RepCustSeq, RepPJTSeq, RepItemSeq, RepCurAmt, 
                             ATARegSeq, GapAmt, AdjAmt, SlipSeq, IsAllReplace, Gubun, GubunSeq, IDX, DataType)  
     SELECT A.DeptSeq, A.CustSeq, A.PJTSeq, A.WorkDate, A.SumMesKey, A.SumMesKeyNo, A.GoodItemSeq, A.CurAmt,   
            A.ReplaceRegSeq, A.ReplaceRegSerl, A.RepCustSeq, A.RepPJTSeq, A.RepItemSeq, A.RepCurAmt, 
            A.ATARegSeq, A.GapAmt, A.AdjAmt, A.SlipSeq, A.IsAllReplace, R.Gubun, R.GubunSeq, 1, A.DataType
       FROM #tempresult2 AS A    
       JOIN (SELECT DISTINCT ReplaceRegSeq, RepCustSeq, gubun, GubunSeq  
               FROM #result) AS R on R.ReplaceRegSeq = A.ReplaceRegSeq   
                                 AND R.RepCustSeq = A.RepCustSeq 
               
     INSERT INTO #TempResult(DeptSeq, CustSeq, PJTSeq, WorkDate, SumMesKey, SumMesKeyNo, GoodItemSeq, CurAmt,   
                             ReplaceRegSeq, ReplaceRegSerl, RepCustSeq, RepPJTSeq, RepItemSeq, RepCurAmt, 
                             ATARegSeq, GapAmt, AdjAmt, SlipSeq, IsAllReplace, Gubun, GubunSeq, IDX, DataType)  
     SELECT A.DeptSeq, A.CustSeq, A.PJTSeq, A.WorkDate, A.SumMesKey, A.SumMesKeyNo, A.GoodItemSeq, A.CurAmt,   
       A.ReplaceRegSeq, A.ReplaceRegSerl, A.RepCustSeq, A.RepPJTSeq, A.RepItemSeq, A.RepCurAmt, 
            A.ATARegSeq, A.GapAmt, A.AdjAmt, A.SlipSeq, A.IsAllReplace, R.Gubun, R.GubunSeq, 2, A.DataType
       FROM #tempresult2 AS A    
       JOIN (SELECT DISTINCT ReplaceRegSeq, RepCustSeq, gubun, GubunSeq  
               FROM #result) AS R on R.ReplaceRegSeq = A.ReplaceRegSeq    
                                 AND R.RepCustSeq = A.RepCustSeq 
      WHERE R.GubunSeq <> 2 AND (R.GubunSeq <> 3 OR IsAllReplace <> '1')
    
    
     UPDATE #TempResult
        SET CrAmt = CASE GubunSeq WHEN 1 THEN (CASE IDX WHEN 1 THEN RepCurAmt * -1 
                                                        WHEN 2 THEN RepCurAmt ELSE 0 END) 
                                  WHEN 2 THEN GapAmt * -1
                                  WHEN 3 THEN (CASE WHEN IsAllReplace = '1' THEN GapAmt * -1
                                                    ELSE (CASE IDX WHEN 1 THEN CurAmt * -1
                                                                   WHEN 2 THEN RepCurAmt ELSE 0 END) END)
                                  ELSE 0 END,
            DrAmt = CASE GubunSeq WHEN 1 THEN (CASE IDX WHEN 1 THEN CurAmt * -1 
                                                        WHEN  2 THEN CurAmt ELSE 0 END) 
                                  WHEN 2 THEN GapAmt * -1     
                                  WHEN 3 THEN (CASE WHEN IsAllReplace = '1' THEN GapAmt * -1
                                                    ELSE (CASE IDX WHEN 1 THEN CurAmt * -1
                                                                   WHEN 2 THEN RepCurAmt ELSE 0 END) END)                  
                                  ELSE 0 END,
             CrCustSeq = CASE GubunSeq WHEN 1 THEN (CASE IDX WHEN 1 THEN CustSeq
		                                                     WHEN 2 THEN RepCustSeq ELSE '' END) 
		                               WHEN 2 THEN CustSeq
		                               WHEN 3 THEN (CASE WHEN IsAllReplace = '1' THEN RepCustSeq
                                                         ELSE (CASE IDX WHEN 1 THEN CustSeq
                                                                        WHEN 2 THEN RepCustSeq ELSE 0 END) END)
		                               ELSE '' END,
		     DrCustSeq = CASE GubunSeq WHEN 1 THEN (CASE IDX WHEN 1 THEN CustSeq
		                                                     WHEN 2 THEN RepCustSeq ELSE '' END) 
		                               WHEN 2 THEN CustSeq
		                               WHEN 3 THEN (CASE WHEN IsAllReplace = '1' THEN RepCustSeq
                                                         ELSE (CASE IDX WHEN 1 THEN CustSeq
                                                                        WHEN 2 THEN RepCustSeq ELSE 0 END) END)
		                               ELSE '' END

	-- ��ǥ���ǵ��� ���� �ݾ׸� ����
	delete from #TempResult where isNull(slipseq, 0) <> 0
	--select * from #TempResult as a ORDER BY A.WorkDate, ReplaceRegSeq, A.GubunSeq, IDX

	 --�ܻ�����(������) ���� : ������ �ܾ�
 --   SELECT  A.FromTableSeq ,            
 --           A.FromSeq ,            
 --           A.FromSerl ,       
	--		A.FromCustSeq,              
	--		A.FromDeptSeq,
 --           A.FromDate AS FromDate ,          
 --           A.FromAmt  AS Amt,   --������ݾ�
 --           isNull(B.CurAmt, 0)    AS InvAmt,    -- ����ݾ�,
	--		A.FromAmt - isNull(B.CurAmt, 0) AS TempSLPreSaleAmt
	--INTO	#TempSLPreSaleAmt
 --   FROM	hencom_ViewPreSalesSource AS A
	--	LEFT OUTER JOIN (
	--		SELECT	VI.FromTableSeq, VI.FromSeq, VI.FromSerl, SUM(VI.CurAmt) as CurAmt
	--		FROM	hencom_VIEWPreSalesResult AS VI
	--			JOIN #TMPMst AS Dept ON VI.DeptSeq = Dept.DeptSeq
	--		WHERE	InvoiceDate <= @BasicYMD
	--		Group by FromTableSeq, FromSeq, FromSerl
	--	) AS B ON B.FromTableSeq = A.FromTableSeq AND B.FromSeq = A.FromSeq AND B.FromSerl = A.FromSerl
	--	JOIN #TMPMst AS Dept ON a.fromdeptseq = Dept.DeptSeq
 --   WHERE	ISNULL(A.FromSeq,0) <> 0 --��������ε� �͸�.   
	--AND		a.FromDate <= @BasicYMD
	--AND	   A.FromAmt - isNull(B.CurAmt, 0) <> 0

	SET @SQL = '<ROOT>
		  <DataBlock1>
			<WorkingTag>A</WorkingTag>
			<IDX_NO>1</IDX_NO>
			<Status>0</Status>
			<DataSeq>1</DataSeq>
			<Selected>1</Selected>
			<TABLE_NAME>DataBlock1</TABLE_NAME>
			<IsChangedMst>1</IsChangedMst>
			<StdYM>' + @BasicYM + '</StdYM>
			<DeptSeq />
			<CustSeq />
			<PJTSeq />
		  </DataBlock1>
		</ROOT>'
    CREATE TABLE #TempSLPreSaleAmt2(DeptSeq INT, ItemSeq INT, CustSeq INT, PJTSeq INT,
	                                PrevQty DECIMAL(19,5), PrevAmt DECIMAL(19,5), ForwardQty  DECIMAL(19,5), ForwardAmt  DECIMAL(19,5), 
									Qty DECIMAL(19,5), Amt DECIMAL(19,5), NotQty DECIMAL(19,5), NotAmt DECIMAL(19,5), AssetSeq NVARCHAR(50), ItemName NVARCHAR(50),
									AssetName NVARCHAR(50), DeptName NVARCHAR(100), CustName NVARCHAR(100), PJTName NVARCHAR(100))

	insert #TempSLPreSaleAmt2
	exec hencom_SSLPreSalesSumarryList @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1035681,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029373

	Select  b.SlipUnit, a.CustSeq as FromCustSeq, sum(a.NotAmt) as TempSLPreSaleAmt
	Into	#TempSLPreSaleAmt
	From    #TempSLPreSaleAmt2 as a
	    JOIN #TMPMst as b on a.DeptSeq = b.DeptSeq
	Group by b.SlipUnit, a.CustSeq

--exec hencom_SSLPreSalesSumarryList @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <Status>0</Status>
--    <DataSeq>1</DataSeq>
--    <Selected>1</Selected>
--    <TABLE_NAME>DataBlock1</TABLE_NAME>
--    <IsChangedMst>1</IsChangedMst>
--    <StdYM>201612</StdYM>
--    <DeptSeq>40</DeptSeq>
--    <CustSeq>3522</CustSeq>
--    <PJTSeq />
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1035681,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029373


	--select * from #TempSLPreSaleAmt

	-- �ܻ����� ������ �ŷ�ó�� �ܾ�
    CREATE TABLE #TempACAmt(SlipUnitName NVARCHAR(50), SlipUnit INT, RemValue NVARCHAR(200), RemRefValue NVARCHAR(20), 
							ForwardDrAmt DECIMAL(19,5), DrAmt DECIMAL(19,5), CrAmt DECIMAL(19,5), RemainAmt DECIMAL(19,5),
							RemSeq INT, RemValSeq INT, RemName NVARCHAR(50))
	SET @SQL = '<ROOT>
	  <DataBlock1>
		<WorkingTag>A</WorkingTag>
		<IDX_NO>1</IDX_NO>
		<Status>0</Status>
		<DataSeq>1</DataSeq>
		<Selected>1</Selected>
		<TABLE_NAME>DataBlock1</TABLE_NAME>
		<IsChangedMst>0</IsChangedMst>
		<FSDomainSeq />
		<AccUnit>1</AccUnit>
		<AccDate>' + @BasicYM + '01' + '</AccDate>
		<AccDateTo>' + @BasicYMD + '</AccDateTo>' + 
		'<SlipUnit>' + CONVERT(NCHAR, @SlipUnit) + '</SlipUnit>' +
		'<AccSeq>1078</AccSeq>
		<RemSeq>1017</RemSeq>
		<UMCostType />
		<LinkCreateID />
		<SMAccStd>1</SMAccStd>
	  </DataBlock1>
	</ROOT>'

	insert #TempACAmt
	exec hencom_SACLedgerQueryAccRemBalance @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1035830,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=39,@PgmSeq=1029517

	delete from #TempACAmt where remainamt = 0

	--select * from #TempSLRemainAmt
	--select * from #TempResult
	--select * from #TempSLPreSaleAmt
	--select * from #TempACAmt

	-- ������ ���� Table Insert
    CREATE TABLE #TempAmt(SlipUnit INT, CustSeq INT, 
						  TempSLRemainAmt DECIMAL(19,5), TempSLChangeAmt DECIMAL(19,5), TempPastSLChangeAmt DECIMAL(19,5), TempSLPreSaleAmt DECIMAL(19,5), TempACAmt DECIMAL(19,5))
	INSERT INTO #TempAmt
	SELECT	b.SlipUnit, A.CustSeq, A.TempSlRemainAmt as TempSLRemainAmt
	,		0 as TempSLChangeAmt
    ,       0 as TempPastSLChangeAmt
	,		0 as TempSLPreSaleAmt
	,		0 as TempSLAmt
	FROM	#TempSLRemainAmt as a
		JOIN #TMPMst as b on a.DeptSeq = b.DeptSeq
	UNION ALL -- �԰ݴ�ü ��ó�� �ܾ� (���)
	SELECT	b.SlipUnit, A.CrCustSeq, 0
	,		CrAmt as TempSLChangeAmt
    ,       0 as TempPastSLChangeAmt
	,		0, 0
	FROM	#TempResult as a
		JOIN #TMPMst as b on a.DeptSeq = b.DeptSeq
    WHERE A.DataType = 1 
	UNION ALL -- �԰ݴ�ü ��ó�� �ܾ� (������)
	SELECT	b.SlipUnit, A.CrCustSeq, 0
	,		0 as TempSLChangeAmt
    ,       CrAmt as TempPastSLChangeAmt
	,		0, 0
	FROM	#TempResult as a
		JOIN #TMPMst as b on a.DeptSeq = b.DeptSeq
    WHERE A.DataType = 2 
	UNION ALL -- ������ �ܾ�
	SELECT	a.SlipUnit, a.fromCustSeq, 0, 0, 0
	,		a.TempSLPreSaleAmt
	,		0
	FROM	#TempSLPreSaleAmt as a
	UNION ALL -- ȸ�� �ŷ�ó�� �ܾ�
	SELECT	a.SlipUnit, RemValSeq, 0, 0, 0, 0
	,		a.RemainAmt
	FROM	#TempACAmt as a

	INSERT INTO #TempMAINResult
	SELECT	a.SlipUnit
	,		'' as SlipUnitName
	,		a.CustSeq
	,		c.CustName
	,		sum(a.TempSLRemainAmt) as TempSLRemainAmt
	,		sum(a.TempSLChangeAmt) as TempSLChangeAmt
    ,       sum(a.TempPastSLChangeAmt) as TempPastSLChangeAmt
	,		sum(a.TempSLPreSaleAmt) as TempSLPreSaleAmt
	,		sum(a.TempSLRemainAmt) - sum(a.TempSLChangeAmt) - sum(a.TempPastSLChangeAmt) - sum(a.TempSLPreSaleAmt) as TempSLAmt
	,		sum(a.TempACAmt) as TempACAmt
	,		sum(a.TempSLRemainAmt) - sum(a.TempSLChangeAmt) - sum(a.TempPastSLChangeAmt) - sum(a.TempSLPreSaleAmt) - sum(a.TempACAmt) as TempDiffAmt
	FROM	#TempAmt AS A
--		JOIN #TMPMst as b on a.SlipUnit = b.SlipUnit
		LEFT OUTER JOIN _TDACust c on a.CustSeq = c.CustSeq
	Group by a.SlipUnit
--	,		b.SlipUnitName
	,		a.CustSeq
	,		c.CustName
	Having sum(a.TempSLRemainAmt) <> 0 or sum(a.TempSLChangeAmt) <> 0 or sum(a.TempPastSLChangeAmt) <> 0 or sum(a.TempSLPreSaleAmt) <> 0 or sum(a.TempACAmt) <> 0

	update	#TempMAINResult 
	set		SlipUnitName = b.SlipUnitName
	From	#TempMAINResult as a, #TMPMst as b
	Where   a.slipUnit = b.SlipUnit
RETURN

--go
--begin tran 
--exec test_hencom_AccountSaleContrastList @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <Status>0</Status>
--    <DataSeq>1</DataSeq>
--    <Selected>1</Selected>
--    <TABLE_NAME>DataBlock1</TABLE_NAME>
--    <IsChangedMst>1</IsChangedMst>
--    <BasicYM>201701</BasicYM>
--    <SlipUnit />
--    <CustSeq />
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1510308,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1032119
--rollback 