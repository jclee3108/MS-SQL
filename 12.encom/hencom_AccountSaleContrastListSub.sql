IF OBJECT_ID('hencom_AccountSaleContrastListSub') IS NOT NULL 
    DROP PROC hencom_AccountSaleContrastListSub
GO 

-- v2017.03.29 

/************************************************************
 ��  �� - ������-ȸ��/���� �ܾ׺�_hencom : �μ�,�ŷ�ó�� ����ȸ
 �ۼ��� - 20161120
 �ۼ��� - ������
************************************************************/
CREATE PROC dbo.hencom_AccountSaleContrastListSub
	@xmlDocument    NVARCHAR(MAX) ,            
	@xmlFlags	    INT 	= 0,            
	@ServiceSeq	    INT 	= 0,            
	@WorkingTag	    NVARCHAR(10)= '',                  
	@CompanySeq	    INT 	= 1,            
	@LanguageSeq	INT 	= 1,            
	@UserSeq	    INT 	= 0,            
	@PgmSeq	        INT 	= 0         
    
AS        
	
	DECLARE @docHandle      INT,
		    @CustSeq        INT ,
            @SlipUnit       INT ,
            @BasicYM        NCHAR(6),
			@BasicYMD       NCHAR(8) ,  
			@DeptSeq        INT,
            @SQL            NVARCHAR(MAX), 
            @IsBalance      NCHAR(1) 
 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
	SELECT  @CustSeq    = ISNULL(CustSeq  ,0)         ,
            @SlipUnit   = ISNULL(SlipUnit ,0)         ,
            @BasicYM    = ISNULL(BasicYM  ,'')        , 
            @IsBalance  = ISNULL(IsBalance,'0')

	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)
	  WITH (
            CustSeq         INT ,
            SlipUnit        INT ,
            BasicYM         NCHAR(6),
            IsBalance       NCHAR(1) 
           )

	-- ��ǥ���������� ����Ҹ� Select
	SELECT	M.DeptSeq,M.DeptName ,A.DispSeq, M.SlipUnit, C.SlipUnitName
	INTO	#TMPMst
	FROM	_TDADept AS M                        
		LEFT OUTER JOIN hencom_TDADeptAdd  AS A WITH (NOLOCK) ON A.CompanySeq = @CompanySeq                     
															 AND A.DeptSeq = M.DeptSeq
		JOIN _TACSlipUnit AS C WITH(NOLOCK) ON M.SlipUnit = C.SlipUnit
	Where	(@SlipUnit = 0 or M.SlipUnit = @SlipUnit)
	AND		IsNull(A.UMTotalDiv,0) <> 0

	--select * from #TMPMst
    
	---- ���� ������
    CREATE TABLE #TempMAINResult(SlipUnit INT, SlipUnitName NVARCHAR(200), CustSeq INT, CustName NVARCHAR(200),
                                TempSLRemainAmt DECIMAL(19,5), TempSLChangeAmt DECIMAL(19,5), TempPastSLChangeAmt DECIMAL(19,5), TempSLPreSaleAmt DECIMAL(19,5),
						    	TempSLAmt DECIMAL(19,5), TempACAmt DECIMAL(19,5),TempDiffAmt DECIMAL(19,5) )

	-- ����ä�� �ܻ�����(��꼭����) - ��ä����Ȳ(FrmSLSaleBondTermTotal_hencom)
	CREATE TABLE #BondSLAmt(SlipUnit INT, SlipUnitName NVARCHAR(50), DeptSeq INT, DeptName NVARCHAR(40), CustSeq INT, CustName NVARCHAR(200), BizNo NVARCHAR(20),
	                        ReceiptAmt DECIMAL(19,5), NoReceiptAmt DECIMAL(19,5), MiNoteAmt DECIMAL(19,5), PrevCreditAmt DECIMAL(19,5), 
							SalesAmt DECIMAL(19,5), PrevBillAmt DECIMAL(19,5), PrevNotBillAmt DECIMAL(19,5),
							TotSalesAmt DECIMAL(19,5), TotBillAmt DECIMAL(19,5), TotBillAmtMiNote DECIMAL(19,5) )

	-- �ܻ�����(ȸ��) ������ �ܾ���ȸ_K-GAAP_hencom(FrmACAccBalanceList_GAAP_hencom)
	CREATE TABLE #BondACReceive(SlipUnitName NVARCHAR(100), SlipUnit INT, RemValue NVARCHAR(100), RemRefValue NVARCHAR(20),
	                            ForwardDrAmt DECIMAL(19,5), DrAmt DECIMAL(19,5), CrAmt DECIMAL(19,5), RemainAmt DECIMAL(19,5), 
								RemSeq INT, RemValSeq INT, RemName NVARCHAR(100))
	-- ����ä�Ǽ�����(ȸ��) ������ �����׸� �ܾ� ��ȸ_hencom(FrmACAccRemBalanceList_GAAP_hencom)
	CREATE TABLE #BondACPre(SlipUnitName NVARCHAR(100), SlipUnit INT, RemValue NVARCHAR(100), RemRefValue NVARCHAR(20),
	                            ForwardDrAmt DECIMAL(19,5), DrAmt DECIMAL(19,5), CrAmt DECIMAL(19,5), RemainAmt DECIMAL(19,5), 
								RemSeq INT, RemValSeq INT, RemName NVARCHAR(100))
	-- ������_�����(ȸ��) ������ �����׸� �ܾ� ��ȸ_hencom(FrmACAccRemBalanceList_GAAP_hencom)
	CREATE TABLE #SaleACAmt(SlipUnitName NVARCHAR(100), SlipUnit INT, RemValue NVARCHAR(100), RemRefValue NVARCHAR(20),
	                            ForwardDrAmt DECIMAL(19,5), DrAmt DECIMAL(19,5), CrAmt DECIMAL(19,5), RemainAmt DECIMAL(19,5), 
								RemSeq INT, RemValSeq INT, RemName NVARCHAR(100))
	-- ���� �����
	CREATE TABLE #SaleSLAmt(SlipUnit INT, SlipUnitName NVARCHAR(50), DeptSeq INT, CustSeq INT, CustName NVARCHAR(200), SaleAmt DECIMAL(19,5))


    -- 2017.03.29 SP �űԻ��� ( ���, ������ �����ϱ����� SP ) 
	-- insert #TempResult
	exec hencom_AccountSaleContrastListCalcNew @CompanySeq=1,@CustSeq = @CustSeq, @SlipUnit = @SlipUnit, @BasicYM = @BasicYM
    
    

	-- ���� �ܻ�����
	SELECT @DeptSeq = MIN(DeptSeq) FROM #TMPMst

	SET @SQL = '<ROOT>
		  <DataBlock1>
			<WorkingTag />
			<IDX_NO>2</IDX_NO>
			<DataSeq>1</DataSeq>
			<Status>0</Status>
			<Selected>1</Selected>
			<DeptSeq>' + CONVERT(NCHAR, @DeptSeq) + '</DeptSeq>
			<TABLE_NAME>DataBlock1</TABLE_NAME>
			<StdYM>' + @BasicYM + '</StdYM>
			<StdSaleType>1011915002</StdSaleType>
			<CustSeq />
			<BizUnit>1</BizUnit>
		  </DataBlock1>
		</ROOT>'
	INSERT INTO #BondSLAmt(DeptSeq, DeptName, BizNo, CustSeq, CustName, 
	                        ReceiptAmt, NoReceiptAmt, MiNoteAmt, PrevCreditAmt, 
							SalesAmt, PrevBillAmt, PrevNotBillAmt,
							TotSalesAmt, TotBillAmt, TotBillAmtMiNote)
	exec hencom_SSLSaleBondTermTotalQuery @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1036570,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029972
	
	If @DeptSeq = 35 -- �۾��Ͻ� �ƽ��� �ڷ� ����
	BEGIN
		SET @SQL = '<ROOT>
			  <DataBlock1>
				<WorkingTag />
				<IDX_NO>2</IDX_NO>
				<DataSeq>1</DataSeq>
				<Status>0</Status>
				<Selected>1</Selected>
				<DeptSeq>' + CONVERT(NCHAR, 53) + '</DeptSeq>
				<TABLE_NAME>DataBlock1</TABLE_NAME>
				<StdYM>' + @BasicYM + '</StdYM>
				<StdSaleType>1011915002</StdSaleType>
				<CustSeq />
				<BizUnit>1</BizUnit>
			  </DataBlock1>
			</ROOT>'
		INSERT INTO #BondSLAmt(DeptSeq, DeptName, BizNo, CustSeq, CustName, 
									ReceiptAmt, NoReceiptAmt, MiNoteAmt, PrevCreditAmt, 
									SalesAmt, PrevBillAmt, PrevNotBillAmt,
									TotSalesAmt, TotBillAmt, TotBillAmtMiNote)
		exec hencom_SSLSaleBondTermTotalQuery @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1036570,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029972

	END

	UPDATE  a
	SET     a.SlipUnit = b.SlipUnit
	,		a.SlipUnitName = b.SlipUnitName
	FROM    #BondSLAmt as a
	    JOIN #TMPMst as b on a.deptseq = b.deptseq

    --select * from #BondSLAmt Return

	-- SELECT * FROM #TempMAINResult
	-- SELECT * from #BondSLAmt
	-- �ܻ�����
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
		<AccDateTo>' + @BasicYM + '31' + '</AccDateTo>
		<SlipUnit>' + CONVERT(NCHAR, @SlipUnit) + '</SlipUnit>
		<AccSeq>18</AccSeq>
		<RemSeq>1017</RemSeq>
		<UMCostType />
		<LinkCreateID />
		<SMAccStd>1</SMAccStd>
	  </DataBlock1>
	</ROOT>'

	INSERT INTO #BondACReceive(SlipUnitName, SlipUnit, RemValue, RemRefValue,
	                           ForwardDrAmt, DrAmt, CrAmt, RemainAmt, RemSeq, RemValSeq, RemName)
	exec hencom_SACLedgerQueryAccRemBalance @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1036570,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029972

	-- ����ä�Ǽ�����
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
		<AccDateTo>' + @BasicYM + '31' + '</AccDateTo>
		<SlipUnit>' + CONVERT(NCHAR, @SlipUnit) + '</SlipUnit>
		<AccSeq>113</AccSeq>
		<RemSeq>1017</RemSeq>
		<UMCostType />
		<LinkCreateID />
		<SMAccStd>1</SMAccStd>
	  </DataBlock1>
	</ROOT>'

	INSERT INTO #BondACPre(SlipUnitName, SlipUnit, RemValue, RemRefValue,
	                       ForwardDrAmt, DrAmt, CrAmt, RemainAmt, RemSeq, RemValSeq, RemName)
	EXEC hencom_SACLedgerQueryAccRemBalance @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1036570,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029972


	INSERT INTO #SaleSLAmt ( SlipUnit, SlipUnitName, DeptSeq, CustSeq, CustName, SaleAmt )
	SELECT	b.SlipUnit, b.SlipUnitName, a.DeptSeq, a.CustSeq, a.CustName, sum(a.CurAmt)
	FROM	hencom_VInvoiceReplaceItem as a
		JOIN #TMPMst as b on a.DeptSeq = b.DeptSeq
	WHERE	a.WorkDate <> '20160101'
	AND		a.WorkDate BETWEEN LEFT(@BasicYM, 4) + '0101' AND @BasicYM + '31'
	AND		a.IsPreSales = 0
	GROUP BY b.SlipUnit, b.SlipUnitName, a.DeptSeq, CustSeq, CustName

    
    -- �������� ȸ��ݿ�(�����⵵)
    SELECT A.WorkDate, D.SlipUnit, D.SlipUnitName, A.DeptSeq, A.CustSeq, A.CustName, A.ReplaceRegSeq, A.InvoiceSeq, A.InvoiceSerl, SUM(A.CurAmt) AS CurAmt 
      INTO #hencom_VInvoiceReplaceItem 
      FROM hencom_VInvoiceReplaceItem  AS A 
      JOIN #TMPMst                     AS D ON ( D.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.WorkDate <> '20160101' 
       AND A.IsPreSales = 0
       AND A.ReplaceRegSeq IS NOT NULL
     GROUP BY A.WorkDate, D.SlipUnit, D.SlipUnitName, A.DeptSeq, A.CustSeq, A.CustName, A.ReplaceRegSeq, A.InvoiceSeq, A.InvoiceSerl

    SELECT A.ReplaceRegSeq, A.SlipSeq, SUM(A.AdjAmt) AS AdjAmt
      INTO #hencom_TAcAdjTempAccount
      FROM hencom_TAcAdjTempAccount AS A 
     GROUP BY A.ReplaceRegSeq, A.SlipSeq

	CREATE TABLE #SaleSLPastAmt(SlipUnit INT, SlipUnitName NVARCHAR(50), DeptSeq INT, CustSeq INT, CustName NVARCHAR(200), SalesSLPastAmt DECIMAL(19,5))
    INSERT INTO #SaleSLPastAmt ( SlipUnit, SlipUnitName, DeptSeq, CustSeq, CustName, SalesSLPastAmt )
    SELECT A.SlipUnit, A.SlipUnitName, A.DeptSeq, A.CustSeq, A.CustName, B.AdjAmt
      FROM #hencom_VInvoiceReplaceItem   AS A 
      JOIN #hencom_TAcAdjTempAccount    AS B ON ( B.ReplaceRegSeq = A.ReplaceRegSeq ) 
      JOIN _TACSlipRow                  AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipSeq = B.SlipSeq ) 
      JOIN _TSLInvoiceItem              AS E ON ( E.CompanySeq = @CompanySeq and E.InvoiceSeq = A.InvoiceSeq AND E.InvoiceSerl = A.InvoiceSerl ) 
     WHERE C.AccDate BETWEEN LEFT(@BasicYM,4) + '0101' AND CONVERT(NCHAR(8),DATEADD(DAY,-1,DATEADD(MONTH,1,LEFT(@BasicYM,6) + '01')),112)
       AND LEFT(A.WorkDate,4) < LEFT(C.AccDate,4) 


     --return 
 --   select * from hencom_VInvoiceReplaceItem 
	--select * from #SaleSLAmt return

	--UNION ALL

	--SELECT	b.SlipUnit, b.SlipUnitName, a.DeptSeq, a.CustSeq, c.CustName, sum(a.CurAmt)
	--FROM	hencom_TSLSalesCreditBasicData as a
	--	JOIN #TMPMst as b on a.DeptSeq = b.DeptSeq
	--	JOIN _TDACust as c on a.CustSeq = c.CustSeq
	--WHERE	a.WorkDate <> '20160101'
	--AND		a.WorkDate BETWEEN LEFT(@BasicYM, 4) + '0101' AND @BasicYM + '31'
	--GROUP BY b.SlipUnit, b.SlipUnitName, a.DeptSeq, a.CustSeq, c.CustName

	-- ȸ�� �����(������_��ǰ����)
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
		<AccDateTo>' + @BasicYM + '31' + '</AccDateTo>
		<SlipUnit>' + CONVERT(NCHAR, @SlipUnit) + '</SlipUnit>
		<AccSeq>182</AccSeq>
		<RemSeq>1017</RemSeq>
		<UMCostType />
		<LinkCreateID />
		<SMAccStd>1</SMAccStd>
	  </DataBlock1>
	</ROOT>'

	INSERT INTO #SaleACAmt(SlipUnitName, SlipUnit, RemValue, RemRefValue,
	                       ForwardDrAmt, DrAmt, CrAmt, RemainAmt, RemSeq, RemValSeq, RemName)
	exec hencom_SACLedgerQueryAccRemBalance @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1036570,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029972

	-- ȸ�� �����(������_��ǰ����)
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
		<AccDateTo>' + @BasicYM + '31' + '</AccDateTo>
		<SlipUnit>' + CONVERT(NCHAR, @SlipUnit) + '</SlipUnit>
		<AccSeq>187</AccSeq>
		<RemSeq>1017</RemSeq>
		<UMCostType />
		<LinkCreateID />
		<SMAccStd>1</SMAccStd>
	  </DataBlock1>
	</ROOT>'

	INSERT INTO #SaleACAmt(SlipUnitName, SlipUnit, RemValue, RemRefValue,
	                       ForwardDrAmt, DrAmt, CrAmt, RemainAmt, RemSeq, RemValSeq, RemName)
	exec hencom_SACLedgerQueryAccRemBalance @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1036570,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029972

	-- ȸ�� �����(�����_��Ÿ����)
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
		<AccDateTo>' + @BasicYM + '31' + '</AccDateTo>
		<SlipUnit>' + CONVERT(NCHAR, @SlipUnit) + '</SlipUnit>
		<AccSeq>191</AccSeq>
		<RemSeq>1017</RemSeq>
		<UMCostType />
		<LinkCreateID />
		<SMAccStd>1</SMAccStd>
	  </DataBlock1>
	</ROOT>'

	INSERT INTO #SaleACAmt(SlipUnitName, SlipUnit, RemValue, RemRefValue,
	                       ForwardDrAmt, DrAmt, CrAmt, RemainAmt, RemSeq, RemValSeq, RemName)
	exec hencom_SACLedgerQueryAccRemBalance @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1036570,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029972

	-- ȸ�� �����(�ƽ���_��ǰ����)
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
		<AccDateTo>' + @BasicYM + '31' + '</AccDateTo>
		<SlipUnit>' + CONVERT(NCHAR, @SlipUnit) + '</SlipUnit>
		<AccSeq>184</AccSeq>
		<RemSeq>1017</RemSeq>
		<UMCostType />
		<LinkCreateID />
		<SMAccStd>1</SMAccStd>
	  </DataBlock1>
	</ROOT>'

	INSERT INTO #SaleACAmt(SlipUnitName, SlipUnit, RemValue, RemRefValue,
	                       ForwardDrAmt, DrAmt, CrAmt, RemainAmt, RemSeq, RemValSeq, RemName)
	exec hencom_SACLedgerQueryAccRemBalance @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1036570,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029972

	-- ȸ�� �����(��Ÿ��ǰ����)
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
		<AccDateTo>' + @BasicYM + '31' + '</AccDateTo>
		<SlipUnit>' + CONVERT(NCHAR, @SlipUnit) + '</SlipUnit>
		<AccSeq>1144</AccSeq>
		<RemSeq>1017</RemSeq>
		<UMCostType />
		<LinkCreateID />
		<SMAccStd>1</SMAccStd>
	  </DataBlock1>
	</ROOT>'

	INSERT INTO #SaleACAmt(SlipUnitName, SlipUnit, RemValue, RemRefValue,
	                       ForwardDrAmt, DrAmt, CrAmt, RemainAmt, RemSeq, RemValSeq, RemName)
	exec hencom_SACLedgerQueryAccRemBalance @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1036570,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029972

	-- ȸ�� �����(�ƽ���_��ǰ����)
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
		<AccDateTo>' + @BasicYM + '31' + '</AccDateTo>
		<SlipUnit>' + CONVERT(NCHAR, @SlipUnit) + '</SlipUnit>
		<AccSeq>1074</AccSeq>
		<RemSeq>1017</RemSeq>
		<UMCostType />
		<LinkCreateID />
		<SMAccStd>1</SMAccStd>
	  </DataBlock1>
	</ROOT>'

	INSERT INTO #SaleACAmt(SlipUnitName, SlipUnit, RemValue, RemRefValue,
	                       ForwardDrAmt, DrAmt, CrAmt, RemainAmt, RemSeq, RemValSeq, RemName)
	exec hencom_SACLedgerQueryAccRemBalance @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1036570,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029972

	-- ȸ�� �����(��Ÿ_��Ÿ����)
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
		<AccDateTo>' + @BasicYM + '31' + '</AccDateTo>
		<SlipUnit>' + CONVERT(NCHAR, @SlipUnit) + '</SlipUnit>
		<AccSeq>738</AccSeq>
		<RemSeq>1017</RemSeq>
		<UMCostType />
		<LinkCreateID />
		<SMAccStd>1</SMAccStd>
	  </DataBlock1>
	</ROOT>'

	INSERT INTO #SaleACAmt(SlipUnitName, SlipUnit, RemValue, RemRefValue,
	                       ForwardDrAmt, DrAmt, CrAmt, RemainAmt, RemSeq, RemValSeq, RemName)
	exec hencom_SACLedgerQueryAccRemBalance @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1036570,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029972

	-- ȸ�� �����(����_��ǰ����)
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
		<AccDateTo>' + @BasicYM + '31' + '</AccDateTo>
		<SlipUnit>' + CONVERT(NCHAR, @SlipUnit) + '</SlipUnit>
		<AccSeq>189</AccSeq>
		<RemSeq>1017</RemSeq>
		<UMCostType />
		<LinkCreateID />
		<SMAccStd>1</SMAccStd>
	  </DataBlock1>
	</ROOT>'

	INSERT INTO #SaleACAmt(SlipUnitName, SlipUnit, RemValue, RemRefValue,
	                        ForwardDrAmt, DrAmt, CrAmt, RemainAmt, RemSeq, RemValSeq, RemName)
	exec hencom_SACLedgerQueryAccRemBalance @xmlDocument=@SQL,@xmlFlags=2,@ServiceSeq=1036570,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=320,@PgmSeq=1029972


    
	SELECT	a.SlipUnit
	,		a.SlipUnitName
	,		a.CustSeq
	,		a.CustName
	,		SUM(a.TempSLRemainAmt) as TempSLRemainAmt
	,		SUM(a.TempSLChangeAmt) as TempSLChangeAmt
    ,		SUM(a.TempPastSLChangeAmt) as TempPastSLChangeAmt
	,		SUM(a.TempSLPreSaleAmt) as TempSLPreSaleAmt
	,		SUM(a.TempSLAmt) as TempSLAmt
	,		SUM(a.TempACAmt) as TempACAmt
	,		SUM(a.TempDiffAmt) as TempDiffAmt
	,		SUM(a.BondSLAmt) as BondSLAmt
	,		SUM(a.BondACReceiveAmt) as BondACReceiveAmt
	,		SUM(a.BondACPreAmt) as BondACPreAmt
	,		SUM(a.BondSLAmt) - (SUM(a.BondACReceiveAmt) - SUM(a.BondACPreAmt)) as BondDiffAmt
	,		SUM(a.SaleSLAmt) as SaleSLAmt
	,		SUM(a.SaleACAmt) as SaleACAmt
	,		SUM(a.SaleSLAmt) - SUM(a.SaleACAmt) as SaleDiffAmt
	,		SUM(a.TempSLChangeAmt) as TempSLChangeAmt2
    ,		SUM(a.TempPastSLChangeAmt) as TempPastSLChangeAmt2
	,       SUM(a.SalesSLPastAmt) AS SalesSLPastAmt
    ,		SUM(a.SaleSLAmt) - SUM(a.SaleACAmt) - SUM(a.TempSLChangeAmt) -SUM(a.TempPastSLChangeAmt) - SUM(a.SalesSLPastAmt) as TempDiffAmt2
    
	FROM	(
		SELECT	a.SlipUnit
		,		a.SlipUnitName
		,		a.CustSeq
		,		a.CustName
		,		a.TempSLRemainAmt
		,		a.TempSLChangeAmt
        ,       a.TempPastSLChangeAmt
		,		a.TempSLPreSaleAmt
		,		a.TempSLAmt
		,		a.TempACAmt
		,		a.TempDiffAmt
		,		0 as BondSLAmt
		,		0 as BondACReceiveAmt
		,		0 as BondACPreAmt
		,		0 as SaleSLAmt
		,		0 as SaleACAmt
        ,       0 AS SalesSLPastAmt
		FROM	#TempMAINResult as a

		UNION ALL

		SELECT	b.SlipUnit
		,		b.SlipUnitName
		,		b.CustSeq
		,		b.CustName
		,		0, 0, 0, 0, 0, 0, 0
		,		b.TotBillAmt as BondSLAmt
		,		0, 0, 0, 0, 0 
		FROM	#BondSLAmt as b

		UNION ALL

		SELECT	c.SlipUnit
		,		c.SlipUnitName
		,		c.RemValSeq
		,		c.RemValue
		,		0, 0, 0, 0, 0, 0, 0, 0 
		,		c.RemainAmt
		,		0, 0, 0, 0 
		FROM	#BondACReceive as c

		UNION ALL

		SELECT	d.SlipUnit
		,		d.SlipUnitName
		,		d.RemValSeq
		,		d.RemValue
		,		0, 0, 0, 0, 0, 0, 0, 0, 0
		,		d.RemainAmt
		,		0, 0, 0 
		FROM	#BondACPre as d

		UNION ALL

		SELECT	e.SlipUnit
		,		e.SlipUnitName
		,		e.CustSeq
		,		e.CustName
		,		0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		,		e.SaleAmt
		,		0, 0
		FROM	#SaleSLAmt as e

		UNION ALL

		SELECT	f.SlipUnit
		,		f.SlipUnitName
		,		f.RemValSeq
		,		f.RemValue
		,		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		,		f.RemainAmt, 0 
		FROM	#SaleACAmt as f
        
        UNION ALL 

        SELECT  g.SlipUnit
		,		g.SlipUnitName
		,		g.CustSeq
		,		g.CustName
		,		0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		,		0, 0, SalesSLPastAmt
        
		FROM	#SaleSLPastAmt as g

	) as a
	GROUP BY a.SlipUnit
	,		a.SlipUnitName
	,		a.CustSeq
	,		a.CustName
    HAVING @IsBalance = '0' 
        OR ( @IsBalance = '1' AND ( SUM(a.TempDiffAmt) <> 0 
                                 OR SUM(a.BondSLAmt) - (SUM(a.BondACReceiveAmt) - SUM(a.BondACPreAmt)) <> 0 
                                 OR SUM(a.SaleSLAmt) - SUM(a.SaleACAmt) - SUM(a.TempSLChangeAmt) -SUM(a.TempPastSLChangeAmt) - SUM(a.SalesSLPastAmt) <> 0 
                                  ) 
           ) 


    RETURN
    
go
exec hencom_AccountSaleContrastListSub @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <BasicYM>201701</BasicYM>
    <SlipUnit>3</SlipUnit>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsBalance>0</IsBalance>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1510308,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1032119