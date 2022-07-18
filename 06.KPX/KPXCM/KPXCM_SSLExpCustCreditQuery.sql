IF OBJECT_ID('KPXCM_SSLExpCustCreditQuery') IS NOT NULL 
    DROP PROC KPXCM_SSLExpCustCreditQuery
GO 

/************************************************************
    Ver. 20140514
 ��  �� - ������-�ŷ�ó�̼���Ȳ : ��ȸ
 �ۼ��� - 20090714
 �ۼ��� - �̼���
 ������ - 20150709 
		- 20150907 �����μ� �߰�
		- 20150914 ����OA���� ������ �ȸ´� �κ� ����  
		- 20151001 �ŷ�ó���հ�����ȸ, ��ü�հ�, �Ǹű��� �߰�
************************************************************/
CREATE PROC KPXCM_SSLExpCustCreditQuery          
	@xmlDocument    NVARCHAR(MAX) ,            
	@xmlFlags	    INT 	= 0,            
	@ServiceSeq	    INT 	= 0,            
	@WorkingTag	    NVARCHAR(10)= '',                  
	@CompanySeq	    INT 	= 1,            
	@LanguageSeq	INT 	= 1,            
	@UserSeq	    INT 	= 0,            
	@PgmSeq	        INT 	= 0         
    
AS      
    --���޹��� ����
    DECLARE @docHandle		    INT,
            @BizUnit		    INT,   --����ι�
            @StdDate            NCHAR(8),   --������
            @DeptSeq            INT,   --�μ�
            @SLDeptSeq			INT,
            @EmpSeq             INT,   --���
            @ResultClass	    INT,   --��������
            @CustSeq            INT,   --�ŷ�ó
            @CustClass          INT,   --�ŷ�ó����
            @CurrSeq		    INT,   --��ȭ   
            @CurrClass		    INT,		    --��ȭ����  
            @IsCreditCheck      NCHAR(1),   -- �̼����翩��
            @IsCustSalesMan     NCHAR(1),    -- ���ŷ�ó�������ȸ
            @CustNo             NVARCHAR(100),
            @UMCustClass        INT,
            @IsCustSumQry		NCHAR(1)

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    

	SELECT @BizUnit		        = ISNULL(BizUnit,0),
           @StdDate		        = ISNULL(StdDate,''),
           @DeptSeq		        = ISNULL(DeptSeq,0),
           @SLDeptSeq			= ISNULL(SLDeptSeq,0),
           @EmpSeq		        = ISNULL(EmpSeq,0),
           @ResultClass	        = ISNULL(ResultClass,0),
           @CustSeq	            = ISNULL(CustSeq,0),
           @CustClass	        = ISNULL(CustClass,0),
           @IsCreditCheck       = ISNULL(IsCreditCheck, ''),
           @IsCustSalesMan      = ISNULL(IsCustSalesMan, ''),
           @CustNo              = ISNULL(CustNo, ''),
           @UMCustClass         = ISNULL(UMCustClass, 0),
           @IsCustSumQry		= ISNULL(IsCustSumQry, '0')
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)             
      WITH (BizUnit             INT,
            StdDate             NCHAR(8),
            DeptSeq             INT,
            SLDeptSeq			INT,
            EmpSeq              INT,
            ResultClass         INT,
            CustSeq             INT,
            CustClass           INT,
            IsCreditCheck       NCHAR(1),
            IsCustSalesMan      NCHAR(1),
            CustNo              NVARCHAR(100),
            UMCustClass         INT,
            IsCustSumQry		NCHAR(1))
            
	DECLARE @OrganKind		    INT,
			@CustKind		    INT,
			@SalesKind		    INT,
			@DateKind		    INT,
			@CurrKind		    INT,
            @FlowKind           INT,
            @FromDate           NCHAR(8),
            @ToDate             NCHAR(8),
            @IsCredit           NCHAR(1),
            @IsMiNote           NCHAR(1),
            @IsSalesAnalysis    NCHAR(1),
            @IsCycleDay         NCHAR(1),
            @AvailMon           INT,
            @InvFromDate        NCHAR(8),
            @SalesAmt           DECIMAL(19,5),
            @ThisToDate         NCHAR(8),
            @NextMonthFromDate  NCHAR(8),
			@AvgDayCnt2         DECIMAL(19,5),
			@PreAvgDayCnt2      DECIMAL(19,5)


    -- ����_����� ���� ��ȿ �Ⱓ(��)  
    EXEC @AvailMon = dbo._SCOMEnvR @CompanySeq, 8023, @UserSeq, @@PROCID    


    --SP ��ȸ ��� ���̺�
    CREATE TABLE #TMP_SSLCreditSub    
    (   OrganSeq                INT,                    -- ����(����ι�/�μ�/���):�Ⱦ� ��쿡 0��    
        CustKindSeq             INT,                    -- �ŷ�ó    
        CurrSeq                 INT,                    -- ��ȭ    
        PrevCreditAmt           DECIMAL(19,5),          -- �����̼�      
        SalesAmt                DECIMAL(19,5),          -- �Ǹűݾ�      
        SalesVAT                DECIMAL(19,5),          -- �Ǹźΰ��� 
        TotSalesAmt             DECIMAL(19,5),          -- �ݿ��ǸŰ�          --�߰� 20120326 ������     
        ReceiptAmt              DECIMAL(19,5),          -- ���ݾ�      
        PrevMiNoteAmt           DECIMAL(19,5),          -- �����̵���������    
        MiNoteAmt               DECIMAL(19,5),          -- �̵���������     
        ProcNoteAmt             DECIMAL(19,5),          -- ����Ⱦ���    
        SalesReceiptAmt         DECIMAL(19,5),          -- �̼�     
        SalesReceiptNoteAmt     DECIMAL(19,5),          -- �̼� + �̵�������     
        SalesReceipt            DECIMAL(19,5),          -- (�̻��)         
        PrevCreditDOMAmt        DECIMAL(19,5),          -- ������ȭ�̼�      
        SalesDOMAmt             DECIMAL(19,5),          -- ��ȭ�Ǹűݾ�      
        SalesDOMVAT             DECIMAL(19,5),          -- ��ȭ�Ǹźΰ���      
        ReceiptDOMAmt           DECIMAL(19,5),          -- ��ȭ���ݾ�      
        PrevMiNoteDOMAmt        DECIMAL(19,5),          -- ���������̵�����ȭ     
        MiNoteDOMAmt            DECIMAL(19,5),          -- �̵���������ȭ    
        ProcNoteDOMAmt          DECIMAL(19,5),          -- ����Ⱦ�����ȭ    
        SalesReceiptDOMAmt      DECIMAL(19,5),          -- �̼���ȭ    
        SalesReceiptNoteDOMAmt  DECIMAL(19,5),          -- �̼� + �̵������� ��ȭ    
        SalesReceiptDOM         DECIMAL(19,5),          -- (�̻��)    
        MaxCreditAmt            DECIMAL(19,5)   NULL,   -- �����ѵ�      
        SpecialCreditAmt        DECIMAL(19,5)   NULL,   -- Ư�������ѵ�      
        MaxNoteAmt              DECIMAL(19,5)   NULL,   -- �����ѵ�      
        IsIncludeNote           NCHAR(1)        NULL,    -- �̵����������Կ���      
        NotBillAmt              DECIMAL(19,5)   NULL,
        NotBillDOMAmt           DECIMAL(19,5)   NULL
    )    

	--���� ���� ���̺� ����
	CREATE TABLE #TMP_SSLCustCreditListQuery (
        CustSeq		        INT,
        CurrSeq		        INT,
        DeptSeq				INT,	-- 151001
		PrevCreditAmt		DECIMAL(19,5),  --�����̿�
		SalesAmt		    DECIMAL(19,5),  --�ݿ��Ǹ�
		SalesVat		    DECIMAL(19,5),  --VAT
        TotSalesAmt         DECIMAL(19,5),  --�ݿ��ǸŰ�                    --�߰� 20120326 ������   
		ReceiptAmt		    DECIMAL(19,5),  --�ݿ�����
		NoReceiptAmt		DECIMAL(19,5),  --���̼���
		MiNoteAmt			DECIMAL(19,5),  --�����̵�����
        ABAmt               DECIMAL(19,5),  --���̼���+�����̵�����         --�߰� 20120326 ������   
		BillNoCheckAmt		DECIMAL(19,5),  --��꼭�̹����
		CreditLeftAmt		DECIMAL(19,5),  --�����ܾ�
		MaxCredit		    DECIMAL(19,5),  --�����ѵ�
		NoReceiptDomAmt		DECIMAL(19,5),  --��ȭ�̼���
		MiNoteDomAmt		DECIMAL(19,5),  --��ȭ�����̵�����
		BillNoCheckDomAmt	DECIMAL(19,5),  --��ȭ��꼭�̹����
		PrevCreditDOMAmt    DECIMAL(19,5),  --��ȭ�����̿�
		SalesDOMAmt			DECIMAL(19,5),  --��ȭ�ݿ��Ǹ�  
		SalesDOMVAT			DECIMAL(19,5),  --��ȭ�ΰ���  
		ReceiptDOMAmt		DECIMAL(19,5),  --��ȭ�ݿ����� 
		SalesReceiptDOMAmt  DECIMAL(19,5)   --SalesReceiptDOMAmt
	)

    

    --SP �μ���	����
    SELECT  @OrganKind = 2 -- �μ��������� �Ͽ� ��ȸ�ǵ��� ����

    --�ŷ�ó ���� ����
	IF (@CustClass IS NULL OR @CustClass = '')
		SELECT  @CustKind = 2          -- �ŷ�ó ����
	ELSE
		SELECT  @CustKind = @CustClass

	--SELECT  @SalesKind = CASE @ResultClass WHEN 8058001 THEN 1  -- �ŷ�����
	--								       WHEN 8058002 THEN 2  -- ���ݰ�꼭
	--								       ELSE 0 END
	
	SELECT  @SalesKind = 2 -- ���ݰ�꼭 

    SELECT  @DateKind = 2                                       -- ����� ����

    -- ��ȭ������ ������ ������ȭ�θ� ��ȸ : 20130307 �̼���
    SELECT  @CurrKind = 2,
            @CurrSeq = 0


    SELECT  @FlowKind = 0,                                      -- ���뱸��
            @IsCredit = '1',                                    -- 
            @IsMiNote = '1',                                    -- �̵������� ���Կ���
            @IsSalesAnalysis = '0',                             -- �̼��� �м� ���� (���ܷ� 24������ ���� ���� ���Ѵ�)
            @IsCycleDay = '0'


    -- ���� ����
    SELECT  @FromDate = LEFT(@StdDate, 6) + '01',
            @ToDate = @StdDate

    SELECT  @ThisToDate = CONVERT(NCHAR(8), DATEADD(DAY, -1, CONVERT(NCHAR(8), DATEADD(MONTH, 1, @FromDate), 112)), 112)

    -- ���ؿ� ������ ������
    SELECT @NextMonthFromDate = CONVERT(NCHAR(8), DATEADD(DAY, 1, @ThisToDate), 112)


    ------������ �� ���� ����      
    ----SELECT @FromDate AS FromDate, @ToDate AS ToDate,  
    ----       --@PrevFromDate AS PrevFromDate, @PrevToDate AS PrevToDate,  
    ----       --@AvailMon AS AvailMon, @AvailDate AS AvailDate,  
    ----       @StdDate AS StdDate
  
  
  
    ------������ �� ���� ����      
    ----SELECT @OrganKind       AS OrganKind,  
    ----       @CustKind        AS CustKind,  
    ----       @IsCustSalesMan  AS IsCustSalesMan,  
    ----       @SalesKind       AS SalesKind,  
    ----       @DateKind        AS DateKind,  
    ----       @CurrKind        AS CurrKind,  
    ----       @CurrSeq         AS CurrSeq,  
    ----       @FromDate        AS FromDate,  
    ----       @ToDate          AS ToDate,  
    ----       @BizUnit         AS BizUnit,  
    ----       @DeptSeq         AS DeptSeq,  
    ----       @EmpSeq          AS EmpSeq,      
    ----       @FlowKind        AS FlowKind,  
    ----       @CustSeq         AS CustSeq,  
    ----       @IsCredit        AS IsCredit,  
    ----       @IsMiNote        AS IsMiNote,  
    ----       @IsSalesAnalysis AS IsSalesAnalysis,      
    ----       @IsCycleDay      AS IsCycleDay  
  
 
    --===============================================================================================================
	--��ȸ SP ȣ��
	EXEC _SSLCreditSub2
			@CompanySeq         = @CompanySeq,
			@OrganKind          = @OrganKind,       -- 1:����ι�, 2:�μ�, 3:���    
			@CustKind           = @CustKind,        -- 1:���뱸��, 2:�ŷ�ó, xxxxxxxx:����ó�� �ŷ�ó    
			@IsCustSalesMan     = @IsCustSalesMan,  -- '1': ���    
			@SalesKind          = @SalesKind,       -- 1:�ŷ���������, 2:���ݰ�꼭����    
			@DateKind           = @DateKind,        -- 1:���, 2:�����       
			@CurrKind           = @CurrKind,        -- 1:DOMAmt, 2:�ŷ�ȭ�����, 3:����ȭ�����    
			@CurrSeq            = @CurrSeq,
			@FromDate           = @FromDate,
			@ToDate             = @ToDate,
			@BizUnit            = @BizUnit,
			@DeptSeq            = @DeptSeq,
			@EmpSeq             = @EmpSeq,
			@FlowKind           = @FlowKind,
			@CustSeq            = @CustSeq,
			@IsCredit           = @IsCredit,
			@IsMiNote           = @IsMiNote,
			@IsSalesAnalysis    = @IsSalesAnalysis, ---- ä�Ǻм�����(���ܷ� 24������ ���� ���� ���Ѵ�. 0 : ���,...)    
            @IsCycleDay         = @IsCycleDay
    
    select * from #TMP_SSLCreditSub 
    return 
    --SELECT D.UMCustClass
    --  FROM #TMP_SSLCreditSub AS A 
    --  LEFT OUTER JOIN _TDACust    AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.CustKindSeq = B.CustSeq
    --  LEFT OUTER JOIN _TDACustClass AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq AND D.CustSeq = B.CustSeq AND D.UMajorCustClass = 8004
    --             select * From _TDAUMajor where MajorSeq = 8004 
    --return 
    
    ----------------------------------------- BEGIN : �ŷ�ó���п� ���� �ŷ�ó ���� (����)-------------------------------------------

    --�ŷ�ó���п� ���� �ŷ�ó ����
    DECLARE @TDACustGroup TABLE
    (
        UpperCustSeq    INT,
        CustSeq         INT
    )
    IF @CustClass <> 0
    BEGIN
        INSERT @TDACustGroup
        SELECT UpperCustSeq,
               CustSeq
          FROM _TDACustGroup WITH(NOLOCK)
         WHERE CompanySeq = @CompanySeq
           AND UMCustGroup = @CustClass
           AND (@CustSeq = 0 OR UpperCustSeq = @CustSeq)
    END
    ELSE
    BEGIN
        INSERT @TDACustGroup
        SELECT CustSeq,
               CustSeq
          FROM _TDACust WITH(NOLOCK)
         WHERE CompanySeq = @CompanySeq
           AND (@CustSeq = 0 OR CustSeq = @CustSeq)
    END

--select '@TDACustGroup', * from @TDACustGroup

    ----------------------------------------- END : �ŷ�ó���п� ���� �ŷ�ó ���� (����)-------------------------------------------


    ----------------------------------------- BEGIN : �ݿ����ݾ� (����)-------------------------------------------

    SELECT C.UpperCustSeq AS CustSeq,    
           A.CurrSeq,    
           SUM(B.CurAmt + B.CurVat) AS ThisMonOutAmt,
           A.DeptSeq
      INTO #TEMP_ThisMonOut    
      FROM _TSLInvoice AS A WITH(NOLOCK)      
           JOIN _TSLInvoiceItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.InvoiceSeq = B.InvoiceSeq      
           JOIN @TDACustGroup AS C ON C.CustSeq = A.CustSeq
     WHERE A.CompanySeq = @CompanySeq      
       AND A.InvoiceDate BETWEEN @FromDate AND @ThisToDate      
       AND (@BizUnit = 0 OR A.BizUnit = @BizUnit)      
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)      
  GROUP BY C.UpperCustSeq, A.CurrSeq, A.DeptSeq


--select '#TEMP_ThisMonOut', * from #TEMP_ThisMonOut

    ----------------------------------------- END : �ݿ����ݾ� (����)-------------------------------------------



    ----------------------------------------- BEGIN : �̵������� (����)-------------------------------------------

    DECLARE @TMiNoteAmt TABLE
    (
        CustSeq         INT,
        CurrSeq         INT,
        DeptSeq			INT,
        CurAmt DECIMAL(19,5),
        DomAmt          DECIMAL(19,5)
    )

    INSERT @TMiNoteAmt
    SELECT C.UpperCustSeq, A.CurrSeq, A.DeptSeq, SUM(B.CurAmt) AS CurAmt, SUM(B.DomAmt) AS DomAmt  
      FROM _TSLReceipt AS A WITH(NOLOCK)
           JOIN _TSLReceiptDesc AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.ReceiptSeq = A.ReceiptSeq
           JOIN @TDACustGroup AS C ON C.CustSeq = A.CustSeq
     WHERE (A.CompanySeq = @CompanySeq)
       AND (@BizUnit = 0 OR A.BizUnit = @BizUnit)      
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)      
       AND (B.DueDate BETWEEN @NextMonthFromDate AND '99991231')
       AND (B.IssueDate BETWEEN '' AND @ThisToDate)
  GROUP BY C.UpperCustSeq, A.CurrSeq, A.DeptSeq 


--select '@TMiNoteAmt', * from @TMiNoteAmt

    ----------------------------------------- END : �̵������� (����)-------------------------------------------



    ----------------------------------------- BEGIN : ���ؿ����� (����)-------------------------------------------

    DECLARE @TReceiptAmt TABLE
    (
        CustSeq         INT,
        CurrSeq         INT,
        DeptSeq			INT,
        CurAmt          DECIMAL(19,5),
        DomAmt          DECIMAL(19,5)
    )

    INSERT @TReceiptAmt
    SELECT C.UpperCustSeq, A.CurrSeq, A.DeptSeq, --SUM(B.CurAmt * B.SMDrOrCr) AS CurAmt, SUM(B.DomAmt * B.SMDrOrCr) AS DomAmt 
		   SUM(B.CurAmt) AS CurAmt, SUM(B.DomAmt) AS DomAmt  
      FROM _TSLReceipt AS A WITH(NOLOCK)
           JOIN _TSLReceiptBill AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.ReceiptSeq = A.ReceiptSeq 
           --JOIN _TSLReceiptDesc AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.ReceiptSeq = A.ReceiptSeq
           JOIN @TDACustGroup AS C ON C.CustSeq = A.CustSeq
     WHERE (A.CompanySeq = @CompanySeq)
       AND (A.ReceiptDate BETWEEN @FromDate AND @ThisToDate)
       AND (@BizUnit = 0 OR A.BizUnit = @BizUnit)      
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)      
  GROUP BY C.UpperCustSeq, A.CurrSeq, A.DeptSeq  


--select '@TReceiptAmt', * from @TReceiptAmt

    ----------------------------------------- END : ���ؿ����� (����)-------------------------------------------

--select * From _TDASMajor where MajorSeq = 8009 and CompanySeq = 2 
--select * From _TDASMinor where MajorSeq = 8009 and CompanySeq = 2 
--select * From _TDASMinorValue where CompanySeq = 2 and MinorSeq = 8009 and Serl =1002 

    ----------------------------------------- BEGIN : OA�Ա� ���� -------------------------------------------

    DECLARE @TExpOA TABLE
    (
        CustSeq         INT,
        CurrSeq         INT,
        DeptSeq			INT,
        PrevCurAmt		DECIMAL(19,5),  
        PrevDomAmt		DECIMAL(19,5),  
        CurAmt          DECIMAL(19,5),
        DomAmt          DECIMAL(19,5)
    )

    INSERT @TExpOA(CustSeq, CurrSeq, DeptSeq, PrevCurAmt, PrevDomAmt, CurAmt, DomAmt)
    SELECT C.UpperCustSeq, A.CurrSeq, A.DeptSeq,
   SUM(CASE WHEN A.OADate < @FromDate THEN B.CurAmt ELSE 0 END) AS PrevCurAmt,    
   SUM(CASE WHEN A.OADate < @FromDate THEN B.DomAmt ELSE 0 END) AS PrevDomAmt,    
   SUM(CASE WHEN A.OADate >= @FromDate AND A.OADate <= @ToDate THEN B.CurAmt ELSE 0 END) AS CurAmt,   
   SUM(CASE WHEN A.OADate >= @FromDate AND A.OADate <= @ToDate THEN B.DomAmt ELSE 0 END) AS DomAmt  
      FROM KPX_TSLExpOA AS A WITH(NOLOCK)
           JOIN KPX_TSLExpOADesc AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.OASeq = A.OASeq
           JOIN @TDACustGroup AS C ON C.CustSeq = A.CustSeq
     WHERE (A.CompanySeq = @CompanySeq)
        --AND (A.OADate BETWEEN @FromDate AND @ThisToDate)  
        AND (A.OADate <= @ToDate) -- 150914  
       AND (@BizUnit = 0 OR A.BizUnit = @BizUnit)
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)
    GROUP BY C.UpperCustSeq, A.CurrSeq, A.DeptSeq  


--select '@TExpOA', * from @TExpOA

    ----------------------------------------- END : OA�Ա� ���� -------------------------------------------


    ----------------------------------------- BEGIN : OA��ȯ�Ǿ� �Էµ� �Ա����� -------------------------------------------

    DECLARE @TReceiptOARepayAmt TABLE
    (
        CustSeq         INT,
        CurrSeq         INT,
        DeptSeq			INT,
        PrevCurAmt   DECIMAL(19,5),  
        PrevDomAmt   DECIMAL(19,5),  
        CurAmt          DECIMAL(19,5),
        DomAmt          DECIMAL(19,5)
    )

    INSERT @TReceiptOARepayAmt(CustSeq, CurrSeq, DeptSeq, PrevCurAmt, PrevDomAmt, CurAmt, DomAmt)
    SELECT C.UpperCustSeq, A.CurrSeq, A.DeptSeq,
   SUM(CASE WHEN A.ReceiptDate < @FromDate THEN B.CurAmt ELSE 0 END) AS PrevCurAmt,    
   SUM(CASE WHEN A.ReceiptDate < @FromDate THEN B.DomAmt ELSE 0 END) AS PrevDomAmt,    
   SUM(CASE WHEN A.ReceiptDate >= @FromDate AND A.ReceiptDate <= @ToDate THEN B.CurAmt ELSE 0 END) AS CurAmt,   
   SUM(CASE WHEN A.ReceiptDate >= @FromDate AND A.ReceiptDate <= @ToDate THEN B.DomAmt ELSE 0 END) AS DomAmt  
      FROM _TSLReceipt AS A WITH(NOLOCK)
           JOIN _TSLReceiptBill AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.ReceiptSeq = A.ReceiptSeq
           JOIN @TDACustGroup AS C ON C.CustSeq = A.CustSeq
     WHERE (A.CompanySeq = @CompanySeq)
        --AND (A.ReceiptDate BETWEEN @FromDate AND @ThisToDate)  
        AND (A.ReceiptDate <= @ToDate)  
       AND (@BizUnit = 0 OR A.BizUnit = @BizUnit)      
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)      
        AND A.ReceiptSeq IN (SELECT ReceiptSeq FROM KPX_TSLExpOARepay AS D WITH(NOLOCK)   
         WHERE D.CompanySeq = @CompanySeq)  
    GROUP BY C.UpperCustSeq, A.CurrSeq, A.DeptSeq  


--select '@TReceiptOARepayAmt', * from @TReceiptOARepayAmt

    ----------------------------------------- END : OA��ȯ�Ǿ� �Էµ� �Ա����� -------------------------------------------
     ----------------------------------------- BEGIN : ����-�Աݰ� ȯ���ݾ� ���� ���� --------------------------------------  
    
    DECLARE @TReceiptExcAmt TABLE  
    (  
        CustSeq     INT, 
        CurrSeq     INT, 
        DeptSeq     INT, 
        PrevCurAmt  DECIMAL(19,5), 
        PrevDomAmt  DECIMAL(19,5), 
        CurAmt      DECIMAL(19,5), 
        DomAmt      DECIMAL(19,5) 
    )  
       

    CREATE TABLE #Receipt2(ReceiptDate NCHAR(8), CustSeq INT, CurrSeq INT, DeptSeq INT,
							PrevCurAmt2 DECIMAL(19,5), PrevDomAmt2 DECIMAL(19,5),
							CurAmt2 DECIMAL(19,5), DomAmt2 DECIMAL(19,5))
    INSERT INTO #Receipt2
    SELECT A.ReceiptDate, A.CustSeq, A.CurrSeq, A.DeptSeq,  
           SUM(CASE WHEN A.ReceiptDate < @FromDate THEN CurAmt ELSE 0 END) AS PrevCurAmt2,  
           SUM(CASE WHEN A.ReceiptDate < @FromDate THEN DomAmt ELSE 0 END) AS PrevDomAmt2,  
           SUM(CASE WHEN A.ReceiptDate >= @FromDate AND A.ReceiptDate <= @ToDate THEN CurAmt ELSE 0 END) AS CurAmt2,   
           SUM(CASE WHEN A.ReceiptDate >= @FromDate AND A.ReceiptDate <= @ToDate THEN DomAmt ELSE 0 END) AS DomAmt2   
      FROM _TSLReceipt AS A  
      JOIN _TSLReceiptBill AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.ReceiptSeq = A.ReceiptSeq  
     WHERE A.CompanySeq = @CompanySeq  
       AND A.ReceiptDate <= @ToDate  
       AND ISNULL(A.IsAuto,'0') <> '1' 
       AND ISNULL(A.IsPreReceipt,'0') <> '1'
     GROUP BY A.ReceiptDate, A.CustSeq, A.CurrSeq, A.DeptSeq
    
    UNION 
    
    SELECT A.ReceiptDate, A.CustSeq, A.CurrSeq, A.DeptSeq,  
           SUM(CASE WHEN A.ReceiptDate < @FromDate THEN CurAmt ELSE 0 END) AS PrevCurAmt2,  
           SUM(CASE WHEN A.ReceiptDate < @FromDate THEN DomAmt ELSE 0 END) AS PrevDomAmt2,  
           SUM(CASE WHEN A.ReceiptDate >= @FromDate AND A.ReceiptDate <= @ToDate THEN CurAmt ELSE 0 END) AS CurAmt2,   
           SUM(CASE WHEN A.ReceiptDate >= @FromDate AND A.ReceiptDate <= @ToDate THEN DomAmt ELSE 0 END) AS DomAmt2   
      FROM _TSLReceipt AS A  
      JOIN _TSLReceiptDesc AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.ReceiptSeq = A.ReceiptSeq  
	   WHERE A.CompanySeq = @CompanySeq  
	     AND A.ReceiptDate <= @ToDate  
	     AND ISNULL(A.IsAuto,'0') <> '1' 
	     AND ISNULL(A.IsPreReceipt,'0') = '1'
     GROUP BY A.ReceiptDate, A.CustSeq, A.CurrSeq, A.DeptSeq

    INSERT INTO @TReceiptExcAmt(CustSeq, CurrSeq, DeptSeq, PrevCurAmt, PrevDomamt, CurAmt, DomAmt)
    SELECT C.CustSeq, C.CurrSeq, C.DeptSeq,
           SUM(ISNULL(D.PrevCurAmt2,0) - ISNULL(C.PrevCurAmt,0)),  
           SUM(ISNULL(D.PrevDomAmt2,0) - ISNULL(C.PrevDomAmt,0)),  
           SUM(ISNULL(D.CurAmt2,0) - ISNULL(C.CurAmt,0)),  
           SUM(ISNULL(D.DomAmt2,0) - ISNULL(C.DomAmt,0))   
      FROM (SELECT SumDate, CustSeq, CurrSeq, DeptSeq,
                   SUM(CASE WHEN SumDate < @FromDate THEN CurAmt ELSE 0 END) AS PrevCurAmt,  
                   SUM(CASE WHEN SumDate < @FromDate THEN DomAmt ELSE 0 END) AS PrevDomAmt,  
                   SUM(CASE WHEN SumDate >= @FromDate AND SumDate <= @ToDate THEN CurAmt ELSE 0 END) AS CurAmt,   
                   SUM(CASE WHEN SumDate >= @FromDate AND SumDate <= @ToDate THEN DomAmt ELSE 0 END) AS DomAmt   
              FROM _TSLBillCreditDaily   
             WHERE CompanySeq = @CompanySeq  
               AND SumDate <= @ToDate  
               AND SumType = 2 -- ����  
               AND ISNULL(DomAmt,0) <> 0   
             GROUP BY SumDate, CustSeq, CurrSeq, DeptSeq) AS C  
      JOIN (SELECT ReceiptDate, CustSeq, CurrSeq, DeptSeq,  
                   SUM(PrevCurAmt2) AS PrevCurAmt2,  
                   SUM(PrevDomAmt2) AS PrevDomAmt2,  
                   SUM(CurAmt2) AS CurAmt2,   
                   SUM(DomAmt2) AS DomAmt2   
              FROM #Receipt2
             GROUP BY ReceiptDate, CustSeq, CurrSeq, DeptSeq) AS D ON D.ReceiptDate = C.SumDate  
                                                                  AND D.CustSeq = C.CustSeq  
                                                                  AND D.CurrSeq = C.CurrSeq  
                                                                  AND D.DeptSeq = C.DeptSeq

     WHERE (ISNULL(C.DomAmt,0) <> ISNULL(D.DomAmt2,0)   
        OR ISNULL(C.CurAmt,0) <> ISNULL(D.CurAmt2,0)   
        OR ISNULL(C.PrevCurAmt,0) <> ISNULL(D.PrevCurAmt2,0)  
        OR ISNULL(C.PrevDomAmt,0) <> ISNULL(D.PrevDomAmt2,0))  
     GROUP BY C.CustSeq, C.CurrSeq, C.DeptSeq 
    
    ----------------------------------------- END : ����-�Աݰ� ȯ���ݾ� ���� ���� ---------------------------------------  

    --���� ��� ���̺� ����
    INSERT INTO #TMP_SSLCustCreditListQuery
    (
        CustSeq,
        CurrSeq,
        DeptSeq, -- 151001
        PrevCreditAmt,
        SalesAmt,
        SalesVat,

        TotSalesAmt,
        ReceiptAmt,
        NoReceiptAmt,
        MiNoteAmt, 
        ABAmt,

        BillNoCheckAmt,
        CreditLeftAmt,
        MaxCredit,
        NoReceiptDomAmt,
        MiNoteDomAmt,

        BillNoCheckDomAmt,
		PrevCreditDOMAmt,   
		SalesDOMAmt,			
		SalesDOMVAT,			
		ReceiptDOMAmt,		
		SalesReceiptDOMAmt 
    )
    SELECT A.CustKindSeq,  
           A.CurrSeq,  
           A.OrganSeq,
           ISNULL(A.PrevCreditAmt,0) - ISNULL(C.PrevCurAmt,0) + ISNULL(D.PrevCurAmt,0) - ISNULL(E.PrevCurAmt,0),    
           ISNULL(A.SalesAmt,0),  
           ISNULL(A.SalesVAT,0),
           ISNULL(A.SalesAmt,0) + ISNULL(A.SalesVAT,0),      --�߰� 20120326 ������
           (ISNULL(A.ReceiptAmt,0) + ISNULL(C.CurAmt,0) - ISNULL(D.CurAmt,0)) + ISNULL(E.CurAmt,0),  -- 150709  
           ISNULL(A.PrevCreditAmt,0) - ISNULL(C.PrevCurAmt,0) + ISNULL(D.PrevCurAmt,0) + ISNULL(A.SalesAmt,0) +   
           ISNULL(A.SalesVAT,0) - (ISNULL(A.ReceiptAmt,0)  + ISNULL(C.CurAmt,0) - ISNULL(D.CurAmt,0)) - ISNULL(E.PrevCurAmt,0) - ISNULL(E.CurAmt,0),  -- 150709  
           ISNULL(A.MiNoteAmt,0),
           ISNULL(A.PrevCreditAmt,0) - ISNULL(C.PrevCurAmt,0) + ISNULL(D.PrevCurAmt,0) + ISNULL(A.SalesAmt,0) + ISNULL(A.SalesVAT,0) -   
           (ISNULL(A.ReceiptAmt,0)  + ISNULL(C.CurAmt,0) - ISNULL(D.CurAmt,0)) + ISNULL(A.MiNoteAmt,0) - ISNULL(E.PrevCurAmt,0) - ISNULL(E.CurAmt,0),   --�߰� 20120326 ������  
           ISNULL(A.NotBillAmt,0),  
           --(ISNULL(A.MaxCreditAmt,0) + ISNULL(A.SpecialCreditAmt,0) -     
           --(ISNULL(A.PrevCreditAmt,0) + ISNULL(B.ThisMonOutAmt,0) - ISNULL(A.ReceiptAmt,0)) -
           --ISNULL(A.MiNoteAmt,0)),                                      -- ���뿩���ѵ��� = �����ѵ��� - ���̼���(�ܻ����) - ���̼���(����)
           0,   -- �����ܾ�
           ISNULL(A.MaxCreditAmt,0) + ISNULL(A.SpecialCreditAmt,0),  
           ISNULL(A.PrevCreditDOMAmt,0) - ISNULL(C.PrevDomAmt,0) + ISNULL(D.PrevDomAmt,0) + ISNULL(A.SalesDOMAmt,0) + ISNULL(A.SalesDOMVAT,0) -   
           (ISNULL(A.ReceiptDOMAmt,0) + ISNULL(C.DomAmt,0) - ISNULL(D.DomAmt,0)) - ISNULL(E.PrevDomAmt,0) - ISNULL(E.DomAmt,0),   -- ��ȭ�����̿�(�����̼�)
           ISNULL(A.MiNoteDOMAmt,0),  
           ISNULL(A.NotBillDOMAmt,0),
           ISNULL(A.PrevCreditDOMAmt,0) - ISNULL(C.PrevDomAmt,0) + ISNULL(D.PrevDomAmt,0) - ISNULL(E.PrevDomAmt,0),  
		   ISNULL(A.SalesDOMAmt,0),
		   ISNULL(A.SalesDOMVAT,0),
           (ISNULL(A.ReceiptDOMAmt,0) + ISNULL(C.DomAmt,0) - ISNULL(D.DomAmt,0)) + ISNULL(E.DomAmt,0), -- 150709  
		   ISNULL(A.SalesReceiptDOMAmt,0)
      FROM #TMP_SSLCreditSub AS A
           --LEFT OUTER JOIN #TEMP_ThisMonOut AS B ON B.CustSeq = A.CustKindSeq AND B.CurrSeq = A.CurrSeq
           LEFT OUTER JOIN @TExpOA AS C ON C.CustSeq = A.CustKindSeq AND C.CurrSeq = A.CurrSeq AND C.DeptSeq = A.OrganSeq
           LEFT OUTER JOIN @TReceiptOARepayAmt AS D ON D.CustSeq = A.CustKindSeq AND D.CurrSeq = A.CurrSeq AND D.DeptSeq = A.OrganSeq
           LEFT OUTER JOIN @TReceiptExcAmt AS E ON E.CustSeq = A.CustKindSeq AND E.CurrSeq = A.CurrSeq AND E.DeptSeq = A.OrganSeq
            
    --�����ܾ� ������Ʈ
    --�����ܾ� = (�����ѵ� + Ư������) -
    --    (�����̼��ݾ� + ���ؿ��Ǹűݾ� - ���ؿ����ݾ�) -
    --            �̵�������
    UPDATE #TMP_SSLCustCreditListQuery
       SET CreditLeftAmt = (ISNULL(B.MaxCreditAmt,0) + ISNULL(B.SpecialCreditAmt,0) -     
                           (ISNULL(B.PrevCreditAmt,0) + ISNULL(C.ThisMonOutAmt,0) - ISNULL(E.CurAmt,0)) -
                            ISNULL(D.CurAmt,0))
      FROM #TMP_SSLCustCreditListQuery AS A
           LEFT OUTER JOIN #TMP_SSLCreditSub AS B ON B.CustKindSeq = A.CustSeq AND B.CurrSeq = A.CurrSeq AND B.OrganSeq = A.DeptSeq
           LEFT OUTER JOIN #TEMP_ThisMonOut AS C ON C.CustSeq = A.CustSeq AND C.CurrSeq = A.CurrSeq AND C.DeptSeq = A.DeptSeq
           LEFT OUTER JOIN @TMiNoteAmt AS D ON D.CustSeq = A.CustSeq AND D.CurrSeq = A.CurrSeq AND D.DeptSeq = A.DeptSeq
           LEFT OUTER JOIN @TReceiptAmt AS E ON E.CustSeq = A.CustSeq AND E.CurrSeq = A.CurrSeq AND E.DeptSeq = A.DeptSeq
           
    -- ��õ���̺�      
    CREATE TABLE #TMP_SOURCETABLE (IDOrder INT, TABLENAME   NVARCHAR(100))    
  
    -- ��õ ������ ���̺�      
    CREATE TABLE #TCOMSourceTracking (IDX_NO INT,             IDOrder INT,            Seq  INT,            Serl  INT,        SubSerl     INT,              
                                      Qty    DECIMAL(19, 5),  STDQty  DECIMAL(19, 5), Amt  DECIMAL(19, 5), VAT   DECIMAL(19, 5))    
  

	-- ���� ������ ���̺�  
    CREATE TABLE #TSLBill  
    (     
        IDX_NO INT IDENTITY, BillSeq INT, SalesSeq  INT, SalesSerl INT,ReceiptSeq INT,CustSeq INT
    )    

    CREATE TABLE #TSLReceipt(ReceiptSeq INT, ReceiptDate NCHAR(8), BillSeq INT)
    INSERT INTO #TSLReceipt(ReceiptDate, ReceiptSeq, BillSeq)
    SELECT B.ReceiptDate, A.ReceiptSeq, A.BillSeq
      FROM _TSLReceiptBill AS A
      LEFT OUTER JOIN _TSLReceipt AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq
												   AND B.ReceiptSeq = A.ReceiptSeq
	  LEFT OUTER JOIN KPX_TSLExpOARepay AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq
														 AND C.ReceiptSeq = B.ReceiptSeq
	 WHERE A.CompanySeq = @CompanySeq
	   AND ISNULL(C.ReceiptSeq,0) = 0
	   AND B.ReceiptDate BETWEEN LEFT(@StdDate,6)+'01' and @StdDate
	 GROUP BY B.ReceiptDate, A.ReceiptSeq, A.BillSeq
	 
	INSERT INTO #TSLReceipt(ReceiptDate, ReceiptSeq, BillSeq)
    SELECT B.OADate, A.OASeq, A.BillSeq
      FROM KPX_TSLExpOABill AS A
      LEFT OUTER JOIN KPX_TSLExpOA AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq
												    AND B.OASeq = A.OASeq
	 WHERE A.CompanySeq = @CompanySeq
	   AND B.OADate BETWEEN LEFT(@StdDate,6)+'01' and @StdDate
	 GROUP BY B.OADate, A.OASeq, A.BillSeq
   
    INSERT INTO #TSLBill
	  SELECT A.BillSeq, B.SalesSeq, B.SalesSerl,C.ReceiptSeq ,A.CustSeq 
      FROM _TSLBill                         AS A WITH(NOLOCK)  
      LEFT OUTER JOIN _TSLSalesBillRelation AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.BillSeq = B.BillSeq  
      LEFT OUTER JOIN _TSLSalesItem         AS K WITH(NOLOCK) ON B.CompanySeq = K.CompanySeq AND B.SalesSeq = K.SalesSeq AND B.SalesSerl = K.SalesSerl  
	   LEFT OUTER JOIN #TSLReceipt			AS C WITH(NOLOCK) ON A.BillSeq  = C.BillSeq
	  WHERE A.CompanySeq = @CompanySeq
	    AND (@CustSeq=0 OR A.CustSeq=@CustSeq)
		AND (@BizUnit=0 OR A.BizUnit=@BizUnit)
	    AND (C.ReceiptDate BETWEEN LEFT(@StdDate,6)+'01' and @StdDate)	
    
    INSERT #TMP_SOURCETABLE        
    SELECT 1,'_TSLInvoiceItem'   -- �ŷ�����          
  
    -- ��õ������ ã�� (�ŷ�����������)      
    EXEC _SCOMSourceTracking @CompanySeq, '_TSLSalesItem', '#TSLBill', 'SalesSeq', 'SalesSerl', ''   

    CREATE TABLE #TmpCust
    (
        CNT		INT IDENTITY(1,1),
        CustSeq INT
    )
    
    
    CREATE TABLE #TmpInvoice 
    (   
        CNT         INT, 
        InvoiceSeq  INT,
		CustSeq     INT,
		InvoiceDate NCHAR(8),
		Amt         DECIMAL(19,5),
		BalAmt      DECIMAL(19,5)
    ) 
    
    CREATE TABLE #TmpReceiptSub
    (
        ReceiptSeq  INT,
        ReceiptSerl INT,
        CustSeq     INT,
        CalcDate    NCHAR(8), -- �����ϼ� : �Աݱ����� ���������� ��� ������ �׿��� ��� �Ա���
        BalAmt      DECIMAL(19,5), -- �ܾ�
        IsOA        NCHAR(1)
    )
    
    CREATE TABLE #TmpReceipt
    (
        CNT		    INT ,
        ReceiptSeq  INT,
        ReceiptSerl INT,
        CalcDate	NCHAR(8), -- �����ϼ� : �Աݱ����� ���������� ��� ������ �׿��� ��� �Ա���
        BalAmt		DECIMAL(19,5), -- �ܾ� 
        IsOA	NCHAR(1)
    )

    CREATE TABLE #TmpInvoiceReceipt
    (
        CNT		    INT IDENTITY(1,1),
        CustSeq		INT,
        InvoiceSeq	INT,
        ReceiptSeq  INT,
        ReceiptSerl INT,
        InvoiceDate NCHAR(8),
        CalcDate	NCHAR(8), -- �����ϼ� : �Աݱ����� ���������� ��� ������ �׿��� ��� �Ա���
        Amt			DECIMAL(19,5), -- �ܾ� 
        IsOA	NCHAR(1)
    )

    CREATE TABLE #PreMonthResultLast (
                                        CustSeq		INT,
                                        DeptSeq		INT,
                                        AvgDayCnt	DECIMAL(19,5)
                                     )
    
    INSERT INTO #PreMonthResultLast
    EXEC KPXCM_SSLCustCreditPreMonthQuery2 @CompanySeq,@BizUnit,@CustSeq,@StdDate

    INSERT INTO #TmpCust
    SELECT DISTINCT CustSeq from #TSLBill  ORDER BY  CustSeq--,InvoiceDate 

    DECLARE @Cnt         INT,
            @MaxCnt      INT,
            -- @CustSeq     INT,
            @Cnt2        INT,
            @MaxCnt2     INT,
            @Cnt3        INT,
            @MaxCnt3     INT,
            @InvoiceSeq  INT,
            @ReceiptSeq  INT,
            @ReceiptSerl INT,
            @IsOA		NCHAR(1),
            @InvoiceDate NCHAR(8),
            @CalcDate    NCHAR(8),
            @InvBalAmt  DECIMAL(19,5),
            @RecBalAmt  DECIMAL(19,5)
	
	--   SELECT ROW_NUMBER() OVER(ORDER BY BB.CustSeq,BB.InvoiceDate,AA.InvoiceSeq) AS CNT,
	--				  AA.InvoiceSeq,
	--				  BB.CustSeq,
	--				  BB.InvoiceDate,
	--				  BB.Amt,BB.Amt
	--			 FROM (SELECT DISTINCT Seq AS InvoiceSeq
	--					 FROM #TCOMSourceTracking
	--				  )AA LEFT OUTER JOIN (SELECT A.InvoiceSeq,B.CustSeq,B.InvoiceDate,SUM(A.DomAmt)+SUM(A.DomVat) AS Amt
	--										 FROM _TSLInvoiceItem A LEFT OUTER JOIN _TSLInvoice B ON A.CompanySeq = B.CompanySeq AND A.InvoiceSeq = B.InvoiceSeq 
	--										WHERE A.CompanySeq=@CompanySeq
	--										  AND A.InvoiceSeq IN(SELECT DISTINCT Seq FROM #TCOMSourceTracking) 
	--										 GROUP BY A.InvoiceSeq,B.CustSeq,B.InvoiceDate 
	--									   ) BB
	--								   ON AA.InvoiceSeq = BB.InvoiceSeq
	--		    WHERE BB.CustSeq = 1000055
	--		 ORDER BY BB.CustSeq,BB.InvoiceDate,AA.InvoiceSeq

	--return
	
   SET @Cnt=1
   SELECT  @MaxCnt=CNT FROM #TmpCust 
   IF @MaxCnt IS NULL
      SET @MaxCnt=0
	  

   WHILE @cnt <= @MaxCnt
     BEGIN
		   SELECT @CustSeq=CustSeq
		     FROM #TmpCust
			WHERE CNT=@Cnt

		   INSERT INTO #TmpInvoice
			   SELECT ROW_NUMBER() OVER(ORDER BY BB.CustSeq,BB.InvoiceDate,AA.InvoiceSeq) AS CNT,
					  AA.InvoiceSeq,
					  BB.CustSeq,
					  BB.InvoiceDate,
					  BB.Amt,BB.Amt
				 FROM (SELECT DISTINCT Seq AS InvoiceSeq
						 FROM #TCOMSourceTracking
					  )AA LEFT OUTER JOIN (SELECT A.InvoiceSeq,B.CustSeq,B.InvoiceDate,SUM(A.DomAmt)+SUM(A.DomVat) AS Amt
											 FROM _TSLInvoiceItem A LEFT OUTER JOIN _TSLInvoice B ON A.CompanySeq = B.CompanySeq AND A.InvoiceSeq = B.InvoiceSeq 
											WHERE A.CompanySeq=@CompanySeq
											  AND A.InvoiceSeq IN(SELECT DISTINCT Seq FROM #TCOMSourceTracking) 
											 GROUP BY A.InvoiceSeq,B.CustSeq,B.InvoiceDate 
										   ) BB
									   ON AA.InvoiceSeq = BB.InvoiceSeq
			    WHERE BB.CustSeq = @CustSeq
			 ORDER BY BB.CustSeq,BB.InvoiceDate,AA.InvoiceSeq

			SET @Cnt2 = 1
			SELECT @MaxCnt2=CNT
			  FROM #TmpInvoice
		
			 

        

			  WHILE @Cnt2<=@MaxCnt2
			  BEGIN
			          SET @InvoiceSeq=0
					  SET @InvoiceDate=''
					  SET @InvBalAmt=0

			       SELECT @InvoiceSeq=InvoiceSeq ,@InvoiceDate=InvoiceDate,@InvBalAmt=BalAmt
				     FROM #TmpInvoice
					WHERE CNT=@Cnt2
					
				  INSERT INTO #TmpReceiptSub(ReceiptSeq, ReceiptSerl, CustSeq, CalcDate, BalAmt, IsOA)
				  SELECT B.ReceiptSeq AS ReceiptSeq,
						 B.ReceiptSerl AS ReceiptSerl,
						 A.CustSeq AS CustSeq,
						 CASE WHEN B.UMReceiptKind IN(8017004,8017009,8017010) THEN B.DueDate ELSE A.ReceiptDate END AS CalcDate,
						 ISNULL(B.DomAmt,0) - ISNULL(C.AMT,0) AS BalAmt,
						 '0' AS IsOA
					FROM _TSLReceipt A 
					LEFT OUTER JOIN _TSLReceiptDesc B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
																  AND A.ReceiptSeq = B.ReceiptSeq
					LEFT OUTER JOIN (SELECT CustSeq,ReceiptSeq,ReceiptSerl,SUM(Amt) AS AMT
									   FROM #TmpInvoiceReceipt
									  WHERE ISNULL(IsOA,'0') = '0'
									  GROUP BY CustSeq,ReceiptSeq,ReceiptSerl) C ON A.CompanySeq = @CompanySeq
																				AND B.ReceiptSeq = C.ReceiptSeq
																				AND B.ReceiptSerl = C.ReceiptSerl
					 LEFT OUTER JOIN KPX_TSLExpOARepay AS D WITH(NOLOCK) ON D.CompanySeq = B.CompanySeq
																		AND D.ReceiptSeq = B.ReceiptSeq
																		AND D.ReceiptSerl = B.ReceiptSerl
					WHERE A.CompanySeq = @CompanySeq
					  AND (@BizUnit=0 OR A.BizUnit=@BizUnit)
					  AND (A.ReceiptDate BETWEEN LEFT(@StdDate,6)+'01' and @StdDate)
					  AND (A.CustSeq=@CustSeq)
					  AND ((ISNULL(B.DomAmt,0) - ISNULL(C.AMT,0)) > 0)
					  AND ISNULL(D.ReceiptSeq,0) = 0
				  UNION   
				  SELECT B.OASeq AS ReceiptSeq,
						 B.OASerl AS ReceiptSerl,
						 A.CustSeq AS CustSeq,
						 CASE WHEN B.UMReceiptKind IN(8017004,8017009,8017010) THEN B.DueDate ELSE A.OADate END AS CalcDate,
						 ISNULL(B.DomAmt,0) - ISNULL(C.AMT,0) AS BalAmt,
						 '1' AS IsOA
					FROM KPX_TSLExpOA A 
					LEFT OUTER JOIN KPX_TSLExpOADesc B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
																   AND A.OASeq = B.OASeq
					LEFT OUTER JOIN (SELECT CustSeq,ReceiptSeq,ReceiptSerl,SUM(Amt) AS AMT
									   FROM #TmpInvoiceReceipt
									  WHERE IsOA = '1'
									  GROUP BY CustSeq,ReceiptSeq,ReceiptSerl) C ON A.CompanySeq = @CompanySeq
																				AND B.OASeq = C.ReceiptSeq
																				AND B.OASerl = C.ReceiptSerl
					WHERE A.CompanySeq = @CompanySeq
					  AND (@BizUnit=0 OR A.BizUnit=@BizUnit)
					  AND (A.OADate BETWEEN LEFT(@StdDate,6)+'01' and @StdDate)
					  AND (A.CustSeq=@CustSeq)
					  AND ((ISNULL(B.DomAmt,0) - ISNULL(C.AMT,0)) > 0)
					ORDER BY CustSeq,ReceiptSeq,ReceiptSerl

				  INSERT INTO #TmpReceipt(CNT, ReceiptSeq, ReceiptSerl, CalcDate, BalAmt, IsOA)
				  SELECT ROW_NUMBER() OVER(ORDER BY CustSeq, IsOA, ReceiptSeq, ReceiptSerl) AS CNT,
						 ReceiptSeq,
						 ReceiptSerl,
						 CalcDate,
						 BalAmt,
						 IsOA
					FROM #TmpReceiptSub
					ORDER BY CustSeq, IsOA, ReceiptSeq, ReceiptSerl
					
				   DELETE #TmpReceiptSub
       
                      SET @Cnt3 = 1
				   SELECT @MaxCnt3=CNT
					FROM #TmpReceipt	

					WHILE @Cnt3 <= @MaxCnt3
					   BEGIN
					           SET @ReceiptSeq  = 0
							   SET @ReceiptSerl = 0
							   SET @RecBalAmt   = 0
							   SET @IsOA = '0'
							   
							SELECT @ReceiptSeq = ReceiptSeq ,@ReceiptSerl=ReceiptSerl,@CalcDate=CalcDate,@RecBalAmt=BalAmt, @IsOA=IsOA
							  FROM #TmpReceipt
							 WHERE CNT=@Cnt3
							

							IF @InvBalAmt<=@RecBalAmt
							   BEGIN
								  INSERT INTO #TmpInvoiceReceipt
											SELECT @CustSeq,@InvoiceSeq,@ReceiptSeq,@ReceiptSerl,@InvoiceDate,@CalcDate,@InvBalAmt,@IsOA
								  
								  UPDATE #TmpInvoice
								     SET BalAmt=0
								   WHERE InvoiceSeq=@InvoiceSeq	
						
								  UPDATE #TmpReceipt
								     SET BalAmt=BalAmt-@InvBalAmt
								   WHERE ReceiptSeq=@ReceiptSeq AND ReceiptSerl=@ReceiptSerl AND IsOA=@IsOA

								  SET @RecBalAmt=@RecBalAmt-@InvBalAmt
								  SET @InvBalAmt=0
							   END
							ELSE IF @InvBalAmt > @RecBalAmt
							    BEGIN
								  INSERT INTO #TmpInvoiceReceipt
											SELECT @CustSeq,@InvoiceSeq,@ReceiptSeq,@ReceiptSerl,@InvoiceDate,@CalcDate,@RecBalAmt,@IsOA
								  
								    UPDATE #TmpInvoice
								       SET BalAmt=BalAmt-@RecBalAmt
								     WHERE InvoiceSeq=@InvoiceSeq	
									 
									   UPDATE #TmpReceipt
								     SET BalAmt=0
								   WHERE ReceiptSeq=@ReceiptSeq AND ReceiptSerl=@ReceiptSerl AND IsOA=@IsOA	
								   
								  SET @InvBalAmt=@InvBalAmt-@RecBalAmt
								  SET @RecBalAmt=0  
								   	
							   END  

							  IF @InvBalAmt>0
							     SET @Cnt3=@Cnt3+1
							  ELSE
							     BREAK;
					  END 
					SET @Cnt2=@Cnt2+1
			  END
			DELETE FROM #TmpInvoice
			DELETE FROM #TmpReceipt
			SET @Cnt=@Cnt+1

	 END


    UPDATE A
	   SET A.CalcDate=B.CalcDate
	  FROM #TmpInvoiceReceipt A LEFT OUTER JOIN(SELECT InvoiceSeq,MAX(CalcDate) AS CalcDate
												  FROM #TmpInvoiceReceipt
												 GROUP BY InvoiceSeq
												)B ON A.InvoiceSeq=B.InvoiceSeq

	DELETE FROM  #TmpInvoiceReceipt WHERE AMT=0



	 SELECT DISTINCT A.CustSeq,
					 C.DeptSeq,
					 A.InvoiceSeq,
					 DATEDIFF(D,A.InvoiceDate,A.CalcDate) AS DayCnt,
					 ISNULL(B.Amt,0) AS Amt ,
					 DATEDIFF(D,A.InvoiceDate,A.CalcDate)*ISNULL(B.Amt,0) AS DayCntAmt
	   INTO #Result
	   FROM #TmpInvoiceReceipt A LEFT OUTER JOIN (SELECT InvoiceSeq,SUM(DomAmt)+SUM(DomVat) AS Amt 
													FROM _TSLInvoiceItem 
												   WHERE CompanySeq=@CompanySeq
												   GROUP BY  InvoiceSeq
												 ) B
										      ON A.InvoiceSeq = B.InvoiceSeq 
	   LEFT OUTER JOIN _TSLInvoice AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
													AND C.InvoiceSeq = A.InvoiceSeq
										      
	 SELECT CustSeq, DeptSeq, CASE WHEN ISNULL(SUM(Amt),0) = 0 THEN 0 ELSE SUM(DayCntAmt)/SUM(Amt) END AS AvgDayCnt
	   INTO #ResultLast
	   FROM #Result 
	  GROUP BY CustSeq, DeptSeq
	  
	CREATE TABLE #TMP_Result(CustSeq INT, UMCustClass INT, UMCustClassName NVARCHAR(100),
							 CustName NVARCHAR(200), CustNo NVARCHAR(100), CurrSeq INT,
							 CurrName NVARCHAR(100), 
							 DeptSeq INT, DeptName NVARCHAR(100),
							 PrevCreditAmt DECIMAL(19,5), SalesAmt DECIMAL(19,5),
							 SalesVat DECIMAL(19,5), TotSalesAmt DECIMAL(19,5), ReceiptAmt DECIMAL(19,5),
							 NoReceiptAmt DECIMAL(19,5), MiNoteAmt DECIMAL(19,5), ABAmt DECIMAL(19,5),
							 BillNoCheckAmt DECIMAL(19,5), CreditLeftAmt DECIMAL(19,5), MaxCredit DECIMAL(19,5),
							 NoReceiptDomAmt DECIMAL(19,5), MiNoteDomAmt DECIMAL(19,5), BillNoCheckDomAmt DECIMAL(19,5),
							 PrevCreditDOMAmt DECIMAL(19,5), SalesDOMAmt DECIMAL(19,5), SalesDOMVAT DECIMAL(19,5), TotSalesDomAmt DECIMAL(19,5),
							 ReceiptDOMAmt DECIMAL(19,5), SalesReceiptDOMAmt DECIMAL(19,5), AvgDayCnt DECIMAL(19,5), PreAvgDayCnt DECIMAL(19,5),
							 SLDeptName NVARCHAR(100), IsSum NCHAR(1), IsTotal NCHAR(1))
    
    --select * From #TMP_SSLCustCreditListQuery return 
        
    --���� ��� ���̺� ����
    INSERT INTO #TMP_Result(CustSeq, UMCustClass, UMCustClassName, CustName, CustNo, CurrSeq, CurrName, 
							DeptSeq, DeptName,
							PrevCreditAmt, SalesAmt, SalesVat, TotSalesAmt, ReceiptAmt, NoReceiptAmt,
							MiNoteAmt, ABAmt, BillNoCheckAmt, CreditLeftAmt, MaxCredit, NoReceiptDomAmt,
							MiNoteDomAmt, BillNoCheckDomAmt, PrevCreditDOMAmt, SalesDOMAmt, SalesDOMVAT,
							TotSalesDomAmt, ReceiptDOMAmt, SalesReceiptDOMAmt, AvgDayCnt, PreAvgDayCnt,
							SLDeptName, IsSum, IsTotal)
	SELECT A.CustSeq,
           D.UMCustClass,
           E.MinorName AS UMCustClassName,
           ISNULL(B.CustName,'')       AS CustName         ,
           ISNULL(B.CustNo,'')         AS CustNo           ,
           A.CurrSeq                   AS CurrSeq          ,
           ISNULL(C.CurrName,'')       AS CurrName         , 
           A.DeptSeq,
           H.DeptName,
           SUM(A.PrevCreditAmt)        AS PrevCreditAmt    , 
           SUM(A.SalesAmt)             AS SalesAmt         , 
           SUM(A.SalesVat)             AS SalesVat         , 
           SUM(A.TotSalesAmt)          AS TotSalesAmt      , --�߰� 20120326 ������
           SUM(A.ReceiptAmt)           AS ReceiptAmt       , 
           SUM(A.NoReceiptAmt)         AS NoReceiptAmt     , 
           SUM(A.MiNoteAmt)            AS MiNoteAmt        , 
           SUM(A.ABAmt)                AS ABAmt            , --�߰� 20120326 ������ 
           SUM(A.BillNoCheckAmt)       AS BillNoCheckAmt   , 
           SUM(A.CreditLeftAmt)        AS CreditLeftAmt    , -- �����ܾ�
           SUM(A.MaxCredit)            AS MaxCredit        , 
           SUM(A.NoReceiptDomAmt)      AS NoReceiptDomAmt  , 
           SUM(A.MiNoteDomAmt)         AS MiNoteDomAmt     , 
           SUM(A.BillNoCheckDomAmt)    AS BillNoCheckDomAmt,

		   SUM(A.PrevCreditDOMAmt)     AS PrevCreditDOMAmt,
		   SUM(A.SalesDOMAmt)		   AS SalesDOMAmt,
		   SUM(A.SalesDOMVAT)		   AS SalesDOMVAT,
		   SUM(A.SalesDOMAmt)+SUM(A.SalesDOMVAT) AS TotSalesDomAmt, -- �������
		   SUM(A.ReceiptDOMAmt)		   AS ReceiptDOMAmt,
		   SUM(A.SalesReceiptDOMAmt)   AS SalesReceiptDOMAmt,

		   MAX(ROUND(P.AvgDayCnt,1))   AS AvgDayCnt,
		   MAX(ROUND(Q.AvgDayCnt,1))   AS PreAvgDayCnt,
		   G.DeptName AS SLDeptName,
		   '0' AS IsSum,
		   '0' AS IsTotal
      FROM #TMP_SSLCustCreditListQuery AS A
           LEFT OUTER JOIN _TDACust    AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.CustSeq = B.CustSeq
           LEFT OUTER JOIN _TDACustClass AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq AND D.CustSeq = B.CustSeq AND D.UMajorCustClass = 8004
           LEFT OUTER JOIN _TDAUMinor  AS E WITH(NOLOCK) ON E.CompanySeq = @CompanySeq AND E.MinorSeq = D.UMCustClass AND E.MajorSeq = 8004
           LEFT OUTER JOIN _TDACurr    AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq AND A.CurrSeq = C.CurrSeq
		   LEFT OUTER JOIN #ResultLast AS P WITH(NOLOCK) ON B.CustSeq=P.CustSeq AND A.DeptSeq = P.DeptSeq
		   LEFT OUTER JOIN #PreMonthResultLast AS Q WITH(NOLOCK) ON B.CustSeq=Q.CustSeq AND A.DeptSeq = Q.DeptSeq
		   LEFT OUTER JOIN _TDACustUserDefine AS F WITH(NOLOCK) ON F.CompanySeq = @CompanySeq AND F.CustSeq = A.CustSeq AND F.MngSerl = 1000003
		   LEFT OUTER JOIN _TDADept	   AS G WITH(NOLOCK) ON G.CompanySeq = F.CompanySeq AND G.DeptSeq = F.MngValSeq
		   LEFT OUTER JOIN _TDADept	   AS H WITH(NOLOCK) ON H.CompanySeq = @CompanySeq AND H.DeptSeq = A.DeptSeq
     WHERE B.CustNo LIKE @CustNo + '%'
       AND (@UMCustClass = 0 OR D.UMCustClass = @UMCustClass)
       AND (@SLDeptSeq = 0 OR F.MngValSeq = @SLDeptSeq)
     GROUP BY B.CustName, B.CustNo, A.CustSeq, D.UMCustClass, E.MinorName, A.CurrSeq, C.CurrName, G.DeptName, A.DeptSeq, H.DeptName
    HAVING SUM(A.PrevCreditAmt)   <> 0 OR SUM(A.SalesAmt)        <> 0 OR SUM(A.SalesVat)          <> 0 OR SUM(A.ReceiptAmt)  <> 0
        OR SUM(A.MiNoteAmt)       <> 0 OR SUM(A.BillNoCheckAmt)  <> 0 OR SUM(A.CreditLeftAmt)     <> 0 OR SUM(A.MaxCredit)   <> 0 
        OR SUM(A.NoReceiptDomAmt) <> 0 OR SUM(A.MiNoteDomAmt)    <> 0 OR SUM(A.BillNoCheckDomAmt) <> 0 OR SUM(A.TotSalesAmt) <> 0 
        OR SUM(A.ABAmt)           <> 0
    -- 20130408 �ڼ�ȣ �߰�
    
	 SELECT @AvgDayCnt2    = ROUND(AVG(AvgDayCnt),1) from #TMP_Result WHERE AvgDayCnt > 0
	 SELECT @PreAvgDayCnt2 = ROUND(AVG(AvgDayCnt),1) from #PreMonthResultLast WHERE AvgDayCnt > 0
	 
    IF ISNULL(@IsCreditCheck, '') = '1'      -- �̼� �����ϴ� �ŷ�ó�� ��ȸ
    BEGIN
         DELETE #TMP_Result WHERE ISNULL(NoReceiptAmt,0) = 0 
    END
    
	 
	IF @IsCustSumQry = '1'
	BEGIN
		INSERT INTO #TMP_Result(CustSeq, UMCustClass, UMCustClassName, CustName, CustNo, CurrSeq, CurrName, 
								PrevCreditAmt, SalesAmt, SalesVat, TotSalesAmt, ReceiptAmt, NoReceiptAmt,
								MiNoteAmt, ABAmt, BillNoCheckAmt, CreditLeftAmt, MaxCredit, NoReceiptDomAmt,
								MiNoteDomAmt, BillNoCheckDomAmt, PrevCreditDOMAmt, SalesDOMAmt, SalesDOMVAT,
								TotSalesDomAmt, ReceiptDOMAmt, SalesReceiptDOMAmt, AvgDayCnt, PreAvgDayCnt,
								SLDeptName, IsSum, IsTotal)
		SELECT CustSeq, UMCustClass, UMCustClassName, CustName, CustNo, 0, '', 
			   SUM(PrevCreditAmt), SUM(SalesAmt), SUM(SalesVat), SUM(TotSalesAmt), SUM(ReceiptAmt), SUM(NoReceiptAmt),
			   SUM(MiNoteAmt), SUM(ABAmt), SUM(BillNoCheckAmt), SUM(CreditLeftAmt), SUM(MaxCredit), SUM(NoReceiptDomAmt),
			   SUM(MiNoteDomAmt), SUM(BillNoCheckDomAmt), SUM(PrevCreditDOMAmt), SUM(SalesDOMAmt), SUM(SalesDOMVAT),
			   SUM(TotSalesDomAmt), SUM(ReceiptDOMAmt), SUM(SalesReceiptDOMAmt), SUM(AvgDayCnt), SUM(PreAvgDayCnt),
			   SLDeptName, '1', '0'
		  FROM #TMP_Result
		 GROUP BY CustSeq, UMCustClass, UMCustClassName, CustName, CustNo, SLDeptName
	END

	INSERT INTO #TMP_Result(CustSeq, UMCustClass, UMCustClassName, CustName, CustNo, CurrSeq, CurrName, 
							PrevCreditAmt, SalesAmt, SalesVat, TotSalesAmt, ReceiptAmt, NoReceiptAmt,
							MiNoteAmt, ABAmt, BillNoCheckAmt, CreditLeftAmt, MaxCredit, NoReceiptDomAmt,
							MiNoteDomAmt, BillNoCheckDomAmt, PrevCreditDOMAmt, SalesDOMAmt, SalesDOMVAT,
							TotSalesDomAmt, ReceiptDOMAmt, SalesReceiptDOMAmt, AvgDayCnt, PreAvgDayCnt,
							SLDeptName, IsSum, IsTotal)
	SELECT 0, 0, '', 'TOTAL', '', 0, '', 
		   SUM(PrevCreditAmt), SUM(SalesAmt), SUM(SalesVat), SUM(TotSalesAmt), SUM(ReceiptAmt), SUM(NoReceiptAmt),
		   SUM(MiNoteAmt), SUM(ABAmt), SUM(BillNoCheckAmt), SUM(CreditLeftAmt), SUM(MaxCredit), SUM(NoReceiptDomAmt),
		   SUM(MiNoteDomAmt), SUM(BillNoCheckDomAmt), SUM(PrevCreditDOMAmt), SUM(SalesDOMAmt), SUM(SalesDOMVAT),
		   SUM(TotSalesDomAmt), SUM(ReceiptDOMAmt), SUM(SalesReceiptDOMAmt), SUM(AvgDayCnt), SUM(PreAvgDayCnt),
		   '', '2', '1'
	  FROM #TMP_Result
	 WHERE ISNULL(IsSum,'0') <> '1'
    
    
    IF ISNULL(@IsCreditCheck, '') <> '1'      -- �̼� �����ϴ� �ŷ�ó�� ��ȸ
    BEGIN
    
        SELECT *,@AvgDayCnt2 AS AvgDayCnt2,@PreAvgDayCnt2 AS PreAvgDayCnt2
          FROM #TMP_Result
         ORDER BY IsTotal DESC, CustName, IsSum
    
    END
    ELSE        -- �̼� �������� �ʴ� �ŷ�ó ���� ��ȸ
    BEGIN
    
        SELECT *,@AvgDayCnt2 AS AvgDayCnt2,@PreAvgDayCnt2 AS PreAvgDayCnt2
          FROM #TMP_Result
         WHERE NoReceiptAmt <> 0 OR ISNULL(IsSum,'0') <> '0'
         ORDER BY IsTotal DESC, CustName, IsSum

    END


RETURN
GO

 exec KPXCM_SSLexpCustCreditQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <IsCustSalesMan>0</IsCustSalesMan>
    <BizUnit />
    <StdDate>20151023</StdDate>
    <ResultClass>8058002</ResultClass>
    <CustSeq />
    <CustNo />
    <UMCustClass />
    <UMCustClassName />
    <SLDeptSeq />
    <EmpSeq />
    <IsCreditCheck>0</IsCreditCheck>
    <IsCustSumQry>0</IsCustSumQry>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030779,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1026532