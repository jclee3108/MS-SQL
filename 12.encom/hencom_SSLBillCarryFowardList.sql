IF OBJECT_ID('hencom_SSLBillCarryFowardList') IS NOT NULL 
    DROP PROC hencom_SSLBillCarryFowardList
GO 

-- v2017.05.16 
/************************************************************                  
    ��  �� - ������-�̿�������Ȳ_hencom : ��ȸ                  
    �ۼ��� - 20160222                  
    �ۼ��� - �ڼ��� 
    ����: by�ڼ���2016.06.21 �ΰ�������                 
   ************************************************************/                  
CREATE PROC hencom_SSLBillCarryFowardList
    @xmlDocument      NVARCHAR(MAX) ,                              
    @xmlFlags         INT  = 0,                              
    @ServiceSeq       INT  = 0,                              
    @WorkingTag       NVARCHAR(10)= '',                                    
    @CompanySeq       INT  = 1,                              
    @LanguageSeq      INT  = 1,                              
    @UserSeq          INT  = 0,                              
    @PgmSeq           INT  = 0                           
                         
   AS
                      
       DECLARE @docHandle      INT,                  
               @CustSeq        INT ,                  
               @StdYM          NCHAR(6) ,                  
               @ItemName       NVARCHAR(100) ,                  
               @DeptSeq        INT ,                  
               @PJTSeq         INT ,                  
               @PrevYM         NCHAR(6)                   
                      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                               
                     
      SELECT   @CustSeq    = CustSeq     ,                  
               @StdYM      = StdYM       ,                  
               @ItemName   = ItemName    ,                  
               @DeptSeq    = DeptSeq     ,                  
               @PJTSeq     = PJTSeq                        
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)                  
      WITH (   CustSeq     INT ,                  
               StdYM       NCHAR(6) ,                  
               ItemName    NVARCHAR(100) ,                  
               DeptSeq     INT ,                  
               PJTSeq      INT )                  
	
   --����                  
    SET @PrevYM = CONVERT(NCHAR(8),DATEADD(m,-1,@StdYM+'01'),112)                  
                              
   --����Ұ���(�߰�����)�� ��������豸�� ���� �ִ� �͸� ��ȸ.                    
    SELECT M.DeptSeq,M.DeptName ,A.DispSeq
    INTO #TMPMst
    FROM _TDADept AS M
    LEFT OUTER JOIN hencom_TDADeptAdd  AS A WITH (NOLOCK) ON A.CompanySeq = @CompanySeq                     
                                                        AND A.DeptSeq = M.DeptSeq                       
    WHERE (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)
    AND ISNULL(A.UMTotalDiv,0) <> 0

	CREATE TABLE #TMPData                  
	(
		DeptSeq     INT,            
		WorkDate    NCHAR(8),            
		PJTSeq      INT,            
		CustSeq     INT,            
		ItemSeq     INT,            
		Qty         DECIMAL(19,5),            
		CurAmt      DECIMAL(19,5),            
		CurVAT      DECIMAL(19,5),            
		BillDate    NCHAR(8),            
		IsBill      NCHAR(1),      
		BillAmt     DECIMAL(19,5),      
		BillVAT     DECIMAL(19,5)
	)
	   
    If @DeptSeq <> 0
		Begin
			INSERT #TMPData(DeptSeq,WorkDate ,PJTSeq ,CustSeq,ItemSeq,Qty,CurAmt ,CurVAT ,BillDate,IsBill,BillAmt,BillVAT )
			SELECT  MST.DeptSeq,            
					MST.WorkDate,            
					MST.PJTSeq,            
					MST.CustSeq,            
					MST.ItemSeq,            
					MST.Qty,            
					MST.CurAmt,            
					MST.CurVAT,            
					B.BillDate,               
					MST.IsBill,
					MST.BillAmt,      
					MST.BillVAT        
			FROM hencom_VInvoiceReplaceItem AS MST       
			LEFT OUTER JOIN _TSLBill AS B WITH(NOLOCK) ON B.CompanySeq = MST.CompanySeq AND B.BillSeq = MST.BillSeq
			WHERE MST.CompanySeq = @CompanySeq      
			AND MST.WorkDate <= @StdYM+'31'          
			AND MST.DeptSeq = @DeptSeq
			AND NOT EXISTS (SELECT 1 FROM hencom_TSLPreSalesMapping AS PSM WITH(NOLOCK)   
																	WHERE PSM.ToTableSeq = MST.SourceTableSeq   
																			  AND PSM.ToSeq =   
																				  (CASE MST.SourceTableSeq 
																				        WHEN 1268 THEN MST.InvoiceSeq   
																						WHEN 1000057 THEN MST.SumMesKey
																						WHEN 1000075 THEN MST.ReplaceRegSeq
																				  END  )  
																			  AND PSM.ToSerl =   
																				  (CASE MST.SourceTableSeq 
																				        WHEN 1268 THEN MST.InvoiceSerl   
																						WHEN 1000057 THEN 0
																						WHEN 1000075 THEN MST.ReplaceRegSerl  
																				  END  )) --�����⿬��� ���� ����. 2016.05.16by�ڼ���
			option(recompile)
		End
	Else
		Begin
			INSERT #TMPData(DeptSeq,WorkDate ,PJTSeq ,CustSeq,ItemSeq,Qty,CurAmt ,CurVAT ,BillDate,IsBill,BillAmt,BillVAT )        
			SELECT  MST.DeptSeq,            
					MST.WorkDate,            
					MST.PJTSeq,            
					MST.CustSeq,            
					MST.ItemSeq,            
					MST.Qty,            
					MST.CurAmt,            
					MST.CurVAT,            
					B.BillDate,            
					MST.IsBill,      
					MST.BillAmt,      
					MST.BillVAT        
			FROM hencom_VInvoiceReplaceItem AS MST       
			LEFT OUTER JOIN _TSLBill AS B WITH(NOLOCK) ON B.CompanySeq = MST.CompanySeq AND B.BillSeq = MST.BillSeq      
			WHERE MST.CompanySeq = @CompanySeq
			AND MST.WorkDate <= @StdYM+'31'
			AND NOT EXISTS (SELECT 1 FROM hencom_TSLPreSalesMapping AS PSM WITH(NOLOCK)   
																	WHERE PSM.ToTableSeq = MST.SourceTableSeq   
																			  AND PSM.ToSeq =   
																				  (CASE MST.SourceTableSeq WHEN 1268 THEN MST.InvoiceSeq   
																						--WHEN 1000057 THEN MST.SumMesKey  
																						WHEN 1000057 THEN MST.SumMesKey
																						WHEN 1000075 THEN MST.ReplaceRegSeq
																				  END  )  
																			  AND PSM.ToSerl =   
																				  (CASE MST.SourceTableSeq WHEN 1268 THEN MST.InvoiceSerl   
																										  WHEN 1000057 THEN 0
																										  WHEN 1000075 THEN MST.ReplaceRegSerl  
																								 END  )) --�����⿬��� ���� ����. 2016.05.16by�ڼ���  
			option(recompile)
       End



       CREATE TABLE #TMPResult                  
       (
           DeptSeq     INT,                  
           DeptName    NVARCHAR(200),                  
           PJTName     NVARCHAR(200),                              
           ItemName    NVARCHAR(200),                    
           CustName    NVARCHAR(200),                          
           PrevQty     DECIMAL(19,5),                  
           PrevAmt     DECIMAL(19,5),                  
           ForwardQty  DECIMAL(19,5),                  
           ForwardAmt  DECIMAL(19,5),                  
           Qty         DECIMAL(19,5),                  
           Amt         DECIMAL(19,5),                   
           NotQty      DECIMAL(19,5),                  
           NotAmt      DECIMAL(19,5),                  
           CustSeq     INT,      
           Gubun       INT,               
           ColorCode   INT,            
           ItemSeq     INT,            
           PJTSeq      INT,            
           BizNo       NVARCHAR(200),          
           AssetName   NVARCHAR(200)               
       )                  
       
       INSERT #TMPResult                  
       SELECT A.DeptSeq,                  
               A.DeptName,        
               P.PJTName AS PJTName,                              
               T.ItemName   AS ItemName,                    
               CT.CustName AS CustName,                           
               D.Qty     AS PrevQty ,      -- �̿�����                
               D.CurAmt  AS PrevAmt,       -- �̿��ݾ�            
               E.Qty     AS ForwardQty ,   -- �̿�����(û��)����               
               E.CurAmt  AS ForwardAmt,    -- �̿�����(û��)�ݾ�            
               B.Qty     AS Qty,           -- ����߻�             
               B.CurAmt  AS Amt,           -- ����߻�      
               ISNULL(D.Qty,0) - ISNULL(E.Qty,0) + ISNULL(B.Qty,0)             AS NotQty,--������м��� = �̿����� - �̿�����(û��)���� + ����߻�(��û��)����                  
               ISNULL(D.CurAmt,0) - ISNULL(E.CurAmt,0) + ISNULL(B.CurAmt,0)    AS NotAmt,--������бݾ� = �̿��ݾ� - �̿�����(û��)�ݾ� + ����߻�(��û��)�ݾ�                 
               M.CustSeq AS CustSeq,                  
               1     AS Gubun  ,              
               -1    AS ColorCode,              
              M.ItemSeq ,            
              M.PJTSeq,            
              CT.BizNo,          
              IA.AssetName            
           FROM #TMPMst AS A                  
         LEFT OUTER JOIN (SELECT DeptSeq,PJTSeq,CustSeq,ItemSeq                   
                         FROM #TMPData                   
                          GROUP BY DeptSeq,PJTSeq,CustSeq,ItemSeq) AS M ON M.DeptSeq = A.DeptSeq       
						                         
       LEFT OUTER JOIN (SELECT DeptSeq,PJTSeq,CustSeq,ItemSeq,  --�̿� ��û����            
                               SUM(ISNULL(Qty,0)) AS Qty,                  
                               SUM(ISNULL(CurAmt,0) ) AS CurAmt                
                           FROM #TMPData            
                           WHERE LEFT(WorkDate,6) <= @PrevYM       
                           AND (ISNULL(IsBill,'0') <> '1'  OR LEFT(BillDate,6)> @PrevYM )         
                           GROUP BY DeptSeq,PJTSeq,CustSeq,ItemSeq  ) AS D ON D.DeptSeq = M.DeptSeq AND D.PJTSeq = M.PJTSeq AND D.CustSeq = M.CustSeq AND D.ItemSeq = M.ItemSeq      

           LEFT OUTER JOIN (SELECT DeptSeq,PJTSeq,CustSeq,ItemSeq, --���ؿ� ������ �߿� û������ ���� ������(����߻�)
                                SUM(ISNULL(Qty,0)) AS Qty,                  
                                SUM(ISNULL(CurAmt,0)) AS CurAmt                  
                           FROM #TMPData                        
                             WHERE ((LEFT(WorkDate,6) = @StdYM AND ISNULL(IsBill,'0') <> '1') OR 
							        (LEFT(WorkDate,6) = @StdYM AND LEFT(WorkDate,6) <> LEFT(BillDate,6) AND ISNULL(IsBill,'0') = '1') )          
                             GROUP BY DeptSeq,PJTSeq,CustSeq,ItemSeq  ) AS B ON B.DeptSeq = M.DeptSeq AND B.PJTSeq = M.PJTSeq AND B.CustSeq = M.CustSeq AND B.ItemSeq = M.ItemSeq
							            
       LEFT OUTER JOIN (SELECT DeptSeq,PJTSeq,CustSeq,ItemSeq,
                             SUM(ISNULL(Qty,0)) AS Qty,                  
                             SUM(ISNULL(CurAmt,0)) AS CurAmt                  
                           FROM #TMPData                  
                           WHERE LEFT(WorkDate,6) = @StdYM AND IsBill = '1'                  
                           GROUP BY DeptSeq,PJTSeq,CustSeq,ItemSeq  ) AS C ON C.DeptSeq = M.DeptSeq AND C.PJTSeq = M.PJTSeq AND C.CustSeq = M.CustSeq AND C.ItemSeq = M.ItemSeq

       LEFT OUTER JOIN (SELECT DeptSeq,PJTSeq,CustSeq,ItemSeq,      --�̿� �������߿� ���ؿ��� û���� ������
                               SUM(ISNULL(Qty,0)) AS Qty,
                             SUM(ISNULL(CurAmt,0)) AS CurAmt
                           FROM #TMPData
                           WHERE LEFT(WorkDate,6) <= @PrevYM
                           AND LEFT(BillDate,6) = @StdYM
                           AND IsBill = '1'
                           GROUP BY DeptSeq,PJTSeq,CustSeq,ItemSeq              
                           ) AS E ON E.DeptSeq = M.DeptSeq AND E.PJTSeq = M.PJTSeq AND E.CustSeq = M.CustSeq AND E.ItemSeq = M.ItemSeq                  
       LEFT OUTER JOIN _TDAItem AS T ON T.CompanySeq = @CompanySeq AND T.ItemSeq = M.ItemSeq                  
       LEFT OUTER JOIN _TPJTProject AS P ON P.CompanySeq = @CompanySeq AND P.PJTSeq = M.PJTSeq
       LEFT OUTER JOIN _TDACust AS CT ON CT.CompanySeq = @CompanySeq AND CT.CustSeq = M.CustSeq 
       LEFT OUTER JOIN _TDAItemAsset AS IA WITH(NOLOCK) ON IA.CompanySeq = @CompanySeq AND IA.AssetSeq = T.AssetSeq
      WHERE (@CustSeq = 0 OR CT.CustSeq = @CustSeq )
       AND (@ItemName  = '' OR T.ItemName  LIKE @ItemName + '%'    )
       AND (@PJTSeq = 0 OR P.PJTSeq = @PJTSeq  )
                
     --��� 0�� ���� ���ܽ�Ŵ          
	  DELETE FROM #TMPResult           
	  WHERE ISNULL(PrevQty,0) = 0           
	  AND ISNULL(PrevAmt,0) = 0           
	  AND ISNULL(ForwardQty,0) = 0           
	  AND ISNULL(ForwardAmt,0) =0           
	  AND ISNULL(Qty,0) = 0           
	  AND ISNULL(Amt,0) = 0           
	  AND ISNULL(NotQty,0) = 0           
	  AND ISNULL(NotAmt,0) = 0          
                           
       INSERT #TMPResult                   
       SELECT  DeptSeq,                  
               '',                  
               '' ,                              
               '�ŷ�ó�� �Ұ�'   ,                    
               '',                          
               SUM(PrevQty) ,                  
               SUM(PrevAmt),  
               SUM(ForwardQty) ,                  
               SUM(ForwardAmt),                  
               SUM(Qty),                  
               SUM(Amt),                  
               SUM(NotQty),                  
               SUM(NotAmt),                  
               CustSeq,                  
               2 AS Gubun,              
               -2429197  AS ColorCode,            
               0 AS ItemSeq ,            
            0 AS PJTSeq ,            
              '' AS BizNo,          
              '' AS AssetName                
       FROM #TMPResult                  
       WHERE ISNULL(CustSeq,0) <> 0                
       GROUP BY DeptSeq,CustSeq                  
      
       INSERT #TMPResult                  
       SELECT  -1,                  
               '',                  
               '' ,                              
               '�հ�'   ,                    
               '',                          
               SUM(PrevQty) ,                  
               SUM(PrevAmt),                  
               SUM(ForwardQty) ,                  
               SUM(ForwardAmt),                  
               SUM(Qty),            
               SUM(Amt),                  
               SUM(NotQty),                  
               SUM(NotAmt),                  
               0 AS CustSeq,               
               0 AS Gubun,                 
               -2031936  AS ColorCode ,            
               0 AS ItemSeq ,            
              0 AS PJTSeq ,            
              '' AS BizNo ,          
              '' AS AssetName                
       FROM #TMPResult                  
       WHERE Gubun  = 1          
               
        SELECT * FROM #TMPResult                  
       ORDER BY deptseq,CustSeq,gubun                  
                     
     RETURN      