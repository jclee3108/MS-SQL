IF OBJECT_ID('hencom_SSLSaleBondTermTotalSlipUnit') IS NOT NULL 
    DROP PROC hencom_SSLSaleBondTermTotalSlipUnit
GO 
/************************************************************      
 ��  �� - ������-��ä����Ȳ_hencom : ��ȸ      
 �ۼ��� - 20160420      
 �ۼ��� - �ڼ���      
 ���� 2017.02.24 by free�ڼ���
 ��������: ����κ� ��ȸ���� ���� ��ȸ �����ϵ��� ��.
************************************************************/      
      
CREATE PROC dbo.hencom_SSLSaleBondTermTotalSlipUnit
 @xmlDocument    NVARCHAR(MAX) ,                  
 @xmlFlags     INT  = 0,                  
 @ServiceSeq     INT  = 0,                  
 @WorkingTag     NVARCHAR(10)= '',                        
 @CompanySeq     INT  = 1,                  
 @LanguageSeq INT  = 1,                  
 @UserSeq     INT  = 0,                  
 @PgmSeq         INT  = 0               
          
AS              
       
    DECLARE @docHandle      INT,      
            @StdSaleType    INT ,      
            @StdYM          NCHAR(6)  ,  
            @SlipUnit       INT, 
            @FromDate       NCHAR(8),    
            @ToDate         NCHAR(8),    
            @PrevFromYM     NCHAR(6),    
            @FrDate         NCHAR(6),    
            @AccInitYM      NCHAR(6),  
            @PrevYM         NCHAR(6),  
            @EnvValue       NVARCHAR(500),  
            @EnvValue2      NVARCHAR(500),
			@BizUnit        int,
			@CustSeq        int,
			@DeptTag        NCHAR(1)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                   
      
    SELECT  @StdSaleType  = ISNULL(StdSaleType,0),      
            @StdYM        = ISNULL(StdYM ,     ''),
            @SlipUnit     = ISNULL(SlipUnit,   0),
			@BizUnit	  = ISNULL(BizUnit,    0),
			@CustSeq      = ISNULL(CustSeq,    0),
			@DeptTag      = ISNULL(DeptTag,    '0')
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)      
    WITH (StdSaleType   INT ,      
          StdYM         NCHAR(6) ,  
          SlipUnit      INT, 
		  BizUnit       int,
		  CustSeq       int,
		  DeptTag       NCHAR(1) )      
	
    --SELECT @CustSeq = ISNULL(@CustSeq,0),
	   --    @BizUnit = ISNULL(@BizUnit,0),
		   --@DeptSeq = (CASE WHEN @DeptTag = '1' THEN 0 ELSE ISNULL(@DeptSeq,0) END),
		   --@DeptTag = ISNULL(@DeptTag,'0')
-- SELECT @DeptTag 

   --��¥����    
    SET @FromDate = @StdYM+'01'    
    SET @ToDate = CONVERT(NCHAR(8),DATEADD(D,-1,CONVERT(NCHAR(8),DATEADD(M,1,@StdYM+'01'),112)),112)    
  --����                
    SET @PrevYM = CONVERT(NCHAR(8),DATEADD(M,-1,@StdYM+'01'),112)    
     ------- ȸ��� ã��                                  
     SELECT  @AccInitYM = FrSttlYM                                  
       FROM  _TDAAccFiscal                                  
      WHERE  CompanySeq = @CompanySeq                                  
        AND  LEFT(@FromDate, 6) BETWEEN FrSttlYM AND ToSttlYM    
             
    SET @FrDate = @AccInitYM     
    SET @PrevFromYM = CONVERT(NCHAR(6), DATEADD(month, -1, @FromDate), 112)    
    
   --�Ⱓ���ݾ�    
    SELECT  D.SlipUnit, 
            M.CustSeq,    
           SUM(CASE WHEN M.SumType = 2 THEN ISNULL(M.CurAmt,0) + ISNULL(M.CurVat,0)  ELSE 0 END) AS ReceiptAmt --�Ⱓ���ݾ�    
    INTO #TMPBillCreditSum    
    FROM _TSLBillCreditSum AS M WITH(NOLOCK) 
    LEFT OUTER JOIN _TDADept AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = M.DeptSeq ) 
    WHERE M.CompanySeq = @CompanySeq
	  --and m.BizUnit = @BizUnit
	  AND (@BizUnit = 0 OR m.BizUnit = @BizUnit)
      AND M.SumYM = @StdYM
      AND (@SlipUnit = 0 OR D.SlipUnit = @SlipUnit ) 
      AND (@CustSeq = 0 OR M.CustSeq = @CustSeq)
    GROUP BY D.SlipUnit ,M.CustSeq
	-- SELECT @FrDate, @TODATE, @PrevFromYM
    

    -- �����̿�    -- ���ݰ�꼭�������� ���� 20160527
    create table #TMPPrevCredit (SlipUnit int, CustSeq int, PrevCreditAmt decimal(19,5))
	insert #TMPPrevCredit (SlipUnit, CustSeq, PrevCreditAmt)
	SELECT D.SlipUnit, A.CustSeq,  
			SUM(CASE WHEN A.SumYM = @FrDate AND A.SumType = 0 THEN A.CurAmt      
			WHEN A.SumYM BETWEEN @FrDate AND @PrevFromYM AND A.SumType = 1 THEN  A.CurAmt + A.CurVAT        
			WHEN A.SumYM BETWEEN @FrDate AND @PrevFromYM AND A.SumType = 2 THEN A.CurAmt * (-1)
			ELSE 0 END ) AS  PrevCreditAmt 
	FROM _TSLBillCreditSum AS A WITH(NOLOCK)
    LEFT OUTER JOIN _TDADept AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq ) 
	WHERE A.CompanySeq = @CompanySeq     
		--and a.BizUnit = @BizUnit   
		AND (@BizUnit = 0 OR a.BizUnit = @BizUnit)    
		AND  A.SumYM BETWEEN @FrDate AND @ToDate
        AND (@SlipUnit = 0 OR D.SlipUnit = @SlipUnit ) 
		AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)
    GROUP BY D.SlipUnit ,A.CustSeq
    
    --����    
    SELECT D.SlipUnit,A.CustSeq,    
           sum( CASE WHEN A1.DueDate > case @StdYM when convert(nchar(6),getdate(),112) then convert(nchar(8), getdate() , 112) else  @StdYM+'31' end  THEN A1.CurAmt * A1.SMDrOrCr ELSE 0 END) AS MiNoteAmt --�̵�������        
    INTO #TMPReceipt
    FROM  _TSLReceipt A WITH(NOLOCK)
    JOIN  _TSLReceiptDESC A1 WITH(NOLOCK) ON A.CompanySeq = A1.CompanySeq      
        AND A.ReceiptSeq = A1.ReceiptSeq      
    LEFT OUTER JOIN _TDADept AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq ) 
    WHERE A.CompanySeq = @CompanySeq    
	  --and a.BizUnit = @BizUnit       
	  AND (@BizUnit = 0 OR a.BizUnit = @BizUnit)
      AND  A.ReceiptDate between CONVERT(NCHAR(6), DATEADD(year, -1,  LEFT(@FromDate, 6) + '01'), 112)  and      case @StdYM when convert(nchar(6),getdate(),112) then convert(nchar(8), getdate() , 112) else  @StdYM+'31' end    
    --AND  A1.DueDate >= @FromDate      
      AND  A1.DueDate >= CONVERT(NCHAR(6), DATEADD(year, -1,  LEFT(@FromDate, 6) + '01'), 112)   
      AND (@SlipUnit = 0 OR D.SlipUnit = @SlipUnit ) 
	  AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)
 group by D.SlipUnit, A.CustSeq
    


	--����Ǹ�  
    CREATE TABLE #TMPRowData                 
    (                 
        SlipUnit    INT,                
	    CustSeq     INT,         
        Qty         DECIMAL(19,5),                
        DomAmt      DECIMAL(19,5),                
        DomVAT      DECIMAL(19,5) ,                       
    )                       
      -- @StdSaleType = (1011915001 ���� / 1011915002 û��)
      IF @StdSaleType = 1011915001 --����������:  mes����������ó��, �ŷ����������Է�,��ü��� �������� ��ȸ�Ѵ�.            
      BEGIN
          INSERT #TMPRowData (SlipUnit,CustSeq,Qty,DomAmt,DomVAT)                
          SELECT  D.SlipUnit, B.CustSeq,                
                  SUM(ISNULL(B.Qty,0)) AS Qty,                
                  SUM(ISNULL(B.CurAmt,0)) AS DomAmt,                
                  SUM(ISNuLL(B.CurVAT,0)) AS DomVAT           
          FROM hencom_VInvoiceReplaceItem AS B WITH(NOLOCK)                  
         LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq AND I.ItemSeq = B.ItemSeq                       
         LEFT OUTER JOIN _TDADept AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = B.DeptSeq ) 
          WHERE B.CompanySeq = @CompanySeq     
            AND B.WorkDate like @StdYM + '%'                                   
            AND B.CloseCfmCode = '1'    --Ȯ���Ǹ� ��ȸ:�����ڷ������ȸ�� ����   
            AND (@SlipUnit = 0 OR D.SlipUnit = @SlipUnit ) 
	        AND (@CustSeq = 0 OR b.CustSeq = @CustSeq)      
          GROUP BY D.SlipUnit,B.CustSeq
		  option (recompile)
      END   
                


 ----------------------------------------------------------------------          
     IF @StdSaleType = 1011915002 --����������:  ���ݰ�꼭                
     BEGIN            
         INSERT #TMPRowData (SlipUnit,CustSeq,DomAmt,DomVAT)      
		 SELECT D.SlipUnit,     
				M.CustSeq,    
			    SUM(M.CurAmt) AS DomAmt, --�Ⱓ���ݾ�    
			    SUM(M.CurVat) AS DomVat --�Ⱓ���ݾ�    
		   FROM _TSLBillCreditSum AS m WITH(NOLOCK)      
           LEFT OUTER JOIN _TDADept AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = M.DeptSeq ) 
		  WHERE M.CompanySeq = @CompanySeq 
		    --and m.BizUnit = @BizUnit  
			AND (@BizUnit = 0 OR m.BizUnit = @BizUnit)         
			AND M.SumYM = @StdYM       
			AND (@SlipUnit = 0 OR D.SlipUnit = @SlipUnit ) 
			AND (@CustSeq = 0 OR M.CustSeq = @CustSeq)
			and m.SumType = 1
	   GROUP BY D.SlipUnit, M.CustSeq 
	 end      
--    select * from #TMPRowData return  
--	SELECT	@StdYM, @FromDate, @ToDate, @PrevYM, @PrevFromYM RETURN
	/* 5�� ��ȸ��
		@StdYM		= 201605
		@FromDate	= 20160501
		@ToDate		= 20160531
		@PrevYM		= 201604
		@PrevFromYM	= 201604
	*/




--  �̿� ����û��
    CREATE TABLE #PrevBillAmt
    (
      SlipUnit    INT,  
      CustSeq     INT,          
      TotAmt      DECIMAL(19,5)
    )
--  �̿� �� ����û��
    CREATE TABLE #PrevNotBillAmt
    (                
      SlipUnit    INT,          
      CustSeq     INT,          
      CurAmt      DECIMAL(19,5)  ,
      CurVat      DECIMAL(19,5)  ,        
    )                  
   IF @StdSaleType = 1011915001 -- û���ϰ�� �ǹ̰� �����Ƿ� �����϶��� ����
   begin
		insert #PrevBillAmt (SlipUnit,CustSeq, TotAmt)
		Select	D.SlipUnit,
				a.CustSeq,
				sum(a.CurAmt + a.CurVAT) as TotAmt
		FROM	hencom_VInvoiceReplaceItem AS A  WITH(NOLOCK)
			JOIN hencom_VSLBill AS B WITH(NOLOCK) ON A.BillSeq = B.BillSeq AND B.BillDate Between @FromDate AND @ToDate
            LEFT OUTER JOIN _TDADept AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq ) 
		WHERE	A.CompanySeq = @CompanySeq
		AND		A.WorkDate < @FromDate
		AND     (@SlipUnit = 0 OR D.SlipUnit = @SlipUnit ) 
		AND		( @CustSeq = 0 OR A.CustSeq = @CustSeq )
		AND		A.CloseCfmCode = '1'
		group by D.SlipUnit, a.CustSeq
		option (recompile)
        insert #PrevNotBillAmt (SlipUnit,CustSeq, CurAmt, CurVat)
 		select  D.SlipUnit,
				a.CustSeq,
				sum(a.CurAmt) as CurAmt,
				sum(a.CurVAT) as CurVAT
			FROM hencom_VInvoiceReplaceItem    AS A  WITH(NOLOCK)       
         LEFT OUTER JOIN _TSLBill AS BL WITH(NOLOCK) ON BL.CompanySeq  = @CompanySeq AND BL.BillSeq = A.BillSeq   
         LEFT OUTER JOIN hencom_TSLPreSalesMapping AS PSM WITH(NOLOCK) ON PSM.ToTableSeq = A.SourceTableSeq   
                                                                    AND PSM.ToSeq = (CASE A.SourceTableSeq WHEN 1268 THEN A.InvoiceSeq   
																						                    WHEN 1000057 THEN A.SumMesKey  
                                                                                                            WHEN 1000075 THEN A.ReplaceRegSeq END)  
                                                                    AND PSM.ToSerl = (CASE A.SourceTableSeq WHEN 1268 THEN A.InvoiceSerl   
                                                              WHEN 1000057 THEN 0
													          WHEN 1000075 THEN A.ReplaceRegSerl END  )  
        LEFT OUTER JOIN _TDADept AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq ) 
			WHERE A.CompanySeq = @CompanySeq                                     
			AND A.WorkDate <= @PrevYM + '31'
			AND (@SlipUnit = 0 OR D.SlipUnit = @SlipUnit ) 
			AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)            
			AND A.CloseCfmCode = '1'    --Ȯ���Ǹ� ��ȸ        
			AND  CASE WHEN A.IsBill = '1' OR ISNULL(PSM.FromSeq,0) <> 0 THEN '1' ELSE A.IsBill END = '0' 
       group by D.SlipUnit, a.CustSeq
	   option (recompile)		
    end  




--select * from #PrevNotBillAmt  
--���������ȸ    
    CREATE TABLE #TMPCustData  
    (  
        SlipUnit    INT ,  
        CustSeq     INT  
    )  
  
    INSERT #TMPCustData(SlipUnit,CustSeq)  
    SELECT DISTINCT SlipUnit,CustSeq FROM #TMPBillCreditSum WHERE ISNULL(ReceiptAmt,0) <> 0  
    UNION  
    SELECT DISTINCT SlipUnit,CustSeq FROM #TMPReceipt WHERE ISNULL(MiNoteAmt,0) <> 0  
    UNION  
    SELECT DISTINCT SlipUnit,CustSeq FROM #TMPPrevCredit WHERE ISNULL(PrevCreditAmt,0) <> 0  
    UNION  
    SELECT DISTINCT SlipUnit,CustSeq FROM #TMPRowData WHERE (ISNULL(DomAmt,0) + ISNULL(DomVAT,0)) <> 0  
    UNION  
    SELECT DISTINCT SlipUnit,CustSeq FROM #PrevNotBillAmt
    UNION  
    SELECT DISTINCT SlipUnit,CustSeq FROM #PrevBillAmt
  
 -- ȯ�漳���� ���� ����ڹ�ȣ������ ��´�.          
    SELECT @EnvValue = ISNULL(EnvValue, '') FROM _TCOMEnv            
    WHERE CompanySeq = @CompanySeq AND EnvSeq = 17          
    IF @@ROWCOUNT = 0 OR ISNULL(@EnvValue, '') = ''          
    BEGIN          
        SELECT @EnvValue = '999-99-99999'          
    END       
      
  -- ȯ�漳���� ���� �ֹε�Ϲ�ȣ���� ��´�.          
    SELECT @EnvValue2 = ISNULL(EnvValue, '') FROM _TCOMEnv            
    WHERE CompanySeq = @CompanySeq AND EnvSeq = 16          
    IF @@ROWCOUNT = 0 OR ISNULL(@EnvValue2, '') = ''          
    BEGIN          
        SELECT @EnvValue2 = '999999-9999999'
    END
    
    
    SELECT B.SlipUnit, MAX(UMTotalDiv) AS UMTotalDiv
      INTO #hencom_TDADeptAdd
      FROM hencom_TDADeptAdd AS A 
      LEFT OUTER JOIN _TDADept AS B ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND ( @SlipUnit = 0 OR B.SlipUnit = @SlipUnit ) 
     GROUP BY SlipUnit 
    

IF @WorkingTag = 'SS1'
BEGIN   -- ����Һ�
	SELECT	A.SlipUnit, A.SlipUnitName, 
			SUM(IsNull(A.ReceiptAmt,0))	ReceiptAmt,
			SUM(IsNull(A.NoReceiptAmt,0))	NoReceiptAmt,
			SUM(IsNull(A.MiNoteAmt,0))	MiNoteAmt,
			SUM(IsNull(A.PrevCreditAmt,0))	PrevCreditAmt,
			SUM(IsNull(A.SalesAmt,0))	SalesAmt,
			SUM(IsNull(A.PrevBillAmt,0))	PrevBillAmt,
			SUM(IsNull(A.PrevNotBillAmt,0))	PrevNotBillAmt,
			SUM(IsNull(A.TotSalesAmt,0))	TotSalesAmt,
			SUM(IsNull(A.TotBillAmt,0))	TotBillAmt,
			SUM(IsNull(A.TotBillAmtMiNote,0))	TotBillAmtMiNote
	  FROM (
				SELECT  M.SlipUnit,  
                        M.SlipUnitName, 
						BCR.ReceiptAmt  AS ReceiptAmt,    
						ISNULL(PC.PrevCreditAmt,0) - ISNULL(BCR.ReceiptAmt,0) /*- ISNULL(MT.MiNoteAmt,0)*/ AS NoReceiptAmt, --�̼��� = �����ܻ����� - �Ⱓ���� /* - �����̵�����  */
						MT.MiNoteAmt            AS MiNoteAmt,       --�̵���������    
						PC.PrevCreditAmt        AS PrevCreditAmt,   --�����̿�  
						ISNULL(S.DomAmt,0) + ISNULL(S.DomVAT,0)     AS  SalesAmt,        --����Ǹ�     
						ISNULL(F.TotAmt,0)							AS PrevBillAmt , --�̿� ����û��
						ISNULL(E.CurAmt,0) + ISNULL(E.CurVAT,0)     AS PrevNotBillAmt , --�̿�������û��
						ISNULL(PC.PrevCreditAmt,0) + ISNULL(S.DomAmt,0) + ISNULL(S.DomVAT,0) AS TotSalesAmt,  --����հ� = �����ܻ����� + ����Ǹ�  
						(ISNULL(PC.PrevCreditAmt,0) - ISNULL(BCR.ReceiptAmt,0)) + ISNULL(E.CurAmt,0) + ISNULL(E.CurVAT,0) + ISNULL(S.DomAmt,0) + ISNULL(S.DomVAT,0) AS TotBillAmt, --�հ�ݾ� = �̼��� + �����ܻ����� + �̿� ����(û��) + ����Ǹ�
						(ISNULL(PC.PrevCreditAmt,0) - ISNULL(BCR.ReceiptAmt,0)) + ISNULL(MT.MiNoteAmt,0) + ISNULL(E.CurAmt,0) + ISNULL(E.CurVAT,0) + ISNULL(S.DomAmt,0) + ISNULL(S.DomVAT,0)  AS TotBillAmtMiNote --�հ�ݾ� = �̼��� + �����ܻ����� + ����Ǹ�
				FROM _TACSlipUnit AS M WITH(NOLOCK)        
					  JOIN #hencom_TDADeptAdd AS AD ON ( AD.SlipUnit = M.SlipUnit ) 
					  LEFT OUTER JOIN (SELECT SlipUnit,  
										SUM(ISNULL(ReceiptAmt,0)) AS ReceiptAmt   
								FROM #TMPBillCreditSum GROUP BY SlipUnit   
								) AS BCR ON BCR.SlipUnit = M.SlipUnit    
					  LEFT OUTER JOIN (SELECT SlipUnit,   
										SUM(ISNULL(MiNoteAmt,0)) AS MiNoteAmt   
								FROM #TMPReceipt GROUP BY SlipUnit  
								) AS MT ON MT.SlipUnit = M.SlipUnit    
					  LEFT OUTER JOIN (SELECT SlipUnit ,  
										SUM(ISNULL(PrevCreditAmt,0)) AS PrevCreditAmt   
								FROM #TMPPrevCredit GROUP BY SlipUnit  
								) AS PC ON PC.SlipUnit = M.SlipUnit     
						LEFT OUTER JOIN (SELECT SlipUnit,  
							SUM(ISNULL(DomAmt,0)) AS DomAmt,  
							SUM(ISNULL(DomVAT,0)) AS DomVAT   
									FROM #TMPRowData  
									GROUP BY SlipUnit) AS S ON S.SlipUnit = M.SlipUnit  
					  LEFT OUTER JOIN (SELECT SlipUnit,     --������ �������߿� ���ؿ��� ��û���� ������                       
										SUM(ISNULL(CurAmt,0)) AS CurAmt,  
										SUM(ISNULL(CurVAT,0)) AS CurVAT    
								  FROM #PrevNotBillAmt
								  GROUP BY SlipUnit            
								  ) AS E ON E.SlipUnit = M.SlipUnit        
					  LEFT OUTER JOIN (SELECT SlipUnit,     --������ �������߿� ���ؿ��� û���� ������                       
										SUM(ISNULL(TotAmt,0)) AS TotAmt
								  FROM #PrevBillAmt
								  GROUP BY SlipUnit            
								  ) AS F ON F.SlipUnit = M.SlipUnit   
				WHERE M.CompanySeq  = @CompanySeq     
				AND ISNULL(AD.UMTotalDiv,0) <> 0  
				AND (@SlipUnit = 0 OR M.SlipUnit = @SlipUnit ) 
				and ( isnull(BCR.ReceiptAmt,0) <> 0 or (ISNULL(PC.PrevCreditAmt,0) - ISNULL(BCR.ReceiptAmt,0) <> 0) or isnull(MT.MiNoteAmt,0) <> 0 or  isnull(PC.PrevCreditAmt,0) <> 0  or   (ISNULL(S.DomAmt,0) + ISNULL(S.DomVAT,0)) <> 0 or (ISNULL(E.CurAmt,0) + ISNULL(E.CurVAT,0)) <> 0 ) 
			--	ORDER BY AD.DispSeq    
		)	AS	A
		GROUP BY A.SlipUnit, A.SlipUnitName
END  
ELSE  
BEGIN  -- �ŷ�ó��
	SELECT	A.SlipUnit, A.SlipUnitName, A.BizNo, A.CustSeq, A.CustName,
			SUM(IsNull(A.ReceiptAmt,0))	ReceiptAmt,
			SUM(IsNull(A.NoReceiptAmt,0))	NoReceiptAmt,
			SUM(IsNull(A.MiNoteAmt,0))	MiNoteAmt,
			SUM(IsNull(A.PrevCreditAmt,0))	PrevCreditAmt,
			SUM(IsNull(A.SalesAmt,0))	SalesAmt,
			SUM(IsNull(A.PrevBillAmt,0))	PrevBillAmt,
			SUM(IsNull(A.PrevNotBillAmt,0))	PrevNotBillAmt,
			SUM(IsNull(A.TotSalesAmt,0))	TotSalesAmt,
			SUM(IsNull(A.TotBillAmt,0))	TotBillAmt,
			SUM(IsNull(A.TotBillAmtMiNote,0))	TotBillAmtMiNote
	  FROM (	
					 SELECT M.SlipUnit, 
							M.SlipUnitName, 
							C.CustSeq       AS CustSeq,   
							CN.CustName     AS CustName,  
							CASE WHEN ISNULL(CN.BizNo, '') = '' THEN dbo._FCOMMaskConv(@EnvValue2,dbo._fnResidMask(dbo._FCOMDecrypt(CN.PersonId, '_TDACust', 'PersonId', @CompanySeq)))         
								ELSE dbo._FCOMMaskConv(@EnvValue,CN.BizNo) END      AS BizNo, --����ڹ�ȣ    
							BCR.ReceiptAmt  AS ReceiptAmt,    
							  ISNULL(PC.PrevCreditAmt,0) - ISNULL(BCR.ReceiptAmt,0) /*- ISNULL(MT.MiNoteAmt,0)*/ AS NoReceiptAmt, --�̼��� = �����ܻ����� - �Ⱓ���� /* - �����̵����� */   
							MT.MiNoteAmt            AS MiNoteAmt,       --�̵���������    
							PC.PrevCreditAmt        AS PrevCreditAmt,   --�����̿�  
							ISNULL(S.DomAmt,0) + ISNULL(S.DomVAT,0)     AS  SalesAmt,        --����Ǹ�
							ISNULL(F.TotAmt, 0)						    AS PrevBillAmt,      -- �̿� û��
							ISNULL(E.CurAmt,0) + ISNULL(E.CurVAT,0)     AS PrevNotBillAmt , -- �̿���û��  
							 ISNULL(PC.PrevCreditAmt,0) + ISNULL(S.DomAmt,0) + ISNULL(S.DomVAT,0) AS TotSalesAmt,  --����հ� = �����ܻ����� + ����Ǹ�  
				--            ISNULL(PC.PrevCreditAmt,0) + ISNULL(E.CurAmt,0) + ISNULL(E.CurVAT,0) + ISNULL(S.DomAmt,0) + ISNULL(S.DomVAT,0) AS TotBillAmt --�հ�ݾ� = �����ܻ����� + �̿� ����(û��) + ����Ǹ�  
							(ISNULL(PC.PrevCreditAmt,0)  - ISNULL(BCR.ReceiptAmt,0)) + ISNULL(E.CurAmt,0) + ISNULL(E.CurVAT,0) + ISNULL(S.DomAmt,0) + ISNULL(S.DomVAT,0) AS TotBillAmt, --�հ�ݾ� = �̼��� + �����ܻ����� + �̿� ����(û��) + ����Ǹ�
							(ISNULL(PC.PrevCreditAmt,0) - ISNULL(BCR.ReceiptAmt,0)) + ISNULL(MT.MiNoteAmt,0) + ISNULL(E.CurAmt,0) + ISNULL(E.CurVAT,0) + ISNULL(S.DomAmt,0) + ISNULL(S.DomVAT,0) AS TotBillAmtMiNote --�հ�ݾ� = �̼��� + �����ܻ����� + ����Ǹ�
					FROM _TACSlipUnit AS M WITH(NOLOCK)        
					JOIN #hencom_TDADeptAdd AS AD ON ( AD.SlipUnit = M.SlipUnit ) 
					LEFT OUTER JOIN #TMPCustData AS C ON C.SlipUnit = M.SlipUnit  
					LEFT OUTER JOIN #TMPBillCreditSum AS BCR ON BCR.SlipUnit = M.SlipUnit AND BCR.CustSeq = C.CustSeq  
					LEFT OUTER JOIN #TMPReceipt AS MT ON MT.SlipUnit = M.SlipUnit AND MT.CustSeq = C.CustSeq  
					LEFT OUTER JOIN #TMPPrevCredit AS PC ON PC.SlipUnit = M.SlipUnit AND PC.CustSeq = C.CustSeq  
					LEFT OUTER JOIN #TMPRowData AS S ON S.SlipUnit = M.SlipUnit AND S.CustSeq = C.CustSeq  
					LEFT OUTER JOIN (SELECT SlipUnit,CustSeq,     --������ �������߿� ���ؿ��� ��û���� ������                       
											SUM(ISNULL(CurAmt,0)) AS CurAmt,  
											SUM(ISNULL(CurVAT,0)) AS CurVAT    
								FROM #PrevNotBillAmt                  
									  GROUP BY SlipUnit ,CustSeq
									  ) AS E ON E.SlipUnit = M.SlipUnit  AND E.CustSeq = C.CustSeq
					LEFT OUTER JOIN (SELECT SlipUnit,CustSeq,     --������ �������߿� ���ؿ��� û���� ������                       
											SUM(ISNULL(TotAmt,0)) AS TotAmt
								FROM #PrevBillAmt                  
									  GROUP BY SlipUnit ,CustSeq
									  ) AS F ON F.SlipUnit = M.SlipUnit  AND F.CustSeq = C.CustSeq
					LEFT OUTER JOIN _TDACust AS CN WITH(NOLOCK) ON CN.CompanySeq = @CompanySeq AND CN.CustSeq = C.CustSeq  
					WHERE M.CompanySeq  = @CompanySeq     
					AND ISNULL(AD.UMTotalDiv,0) <> 0   
					AND (@SlipUnit = 0 OR M.SlipUnit = @SlipUnit ) 
		)	AS	A
		GROUP BY A.SlipUnit, A.SlipUnitName, A.BizNo, A.CustSeq, A.CustName	
END  

RETURN

go