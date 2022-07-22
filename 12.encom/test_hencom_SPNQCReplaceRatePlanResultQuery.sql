drop proc test_hencom_SPNQCReplaceRatePlanResultQuery 
go
/************************************************************      
  ��  �� - ������-�����ȹġȯ����ǥ�ع��յ��������_hencom : ��ȸ      
  �ۼ��� - 20161111      
  �ۼ��� - �ڼ���      
  ����: ���� ���� �÷� �߰��Ǿ� ��մܰ� ��� ������.2017.03.30 by�ڼ���
 ************************************************************/      
       
 CREATE PROC dbo.test_hencom_SPNQCReplaceRatePlanResultQuery                     
  @xmlDocument    NVARCHAR(MAX) ,                  
  @xmlFlags     INT  = 0,                  
  @ServiceSeq     INT  = 0,                  
  @WorkingTag     NVARCHAR(10)= '',                        
  @CompanySeq     INT  = 1,                  
  @LanguageSeq INT  = 1,                  
  @UserSeq     INT  = 0,                  
  @PgmSeq         INT  = 0               
           
 AS              
     
     DECLARE @docHandle      INT ,      
             @DeptSeq        INT ,      
             @PlanSeq        INT        
     
  EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                   
       
     SELECT  @DeptSeq = DeptSeq  ,      
             @PlanSeq = PlanSeq        
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)      
    WITH (DeptSeq  INT ,      
          PlanSeq  INT )      
        
   /*0������ ���� ��� ó��*/          
      SET ANSI_WARNINGS OFF          
      SET ARITHIGNORE ON          
      SET ARITHABORT OFF  
      
     DECLARE @Year           NCHAR(4), 
             @PrevYear       NCHAR(4) ,
             @ProdDeptSeq    INT, 
             @PrevCfmPlanSeq INT   
     
     SELECT @Year = PlanYear    ,  
            @PrevYear = CONVERT(INT,PlanYear)-1  
     FROM hencom_TPNPlan WITH(NOLOCK)      
     WHERE CompanySeq = @CompanySeq      
     AND PlanSeq = @PlanSeq      
   
 --��������ã��  
     SELECT @ProdDeptSeq = ProdDeptSeq   
     FROM hencom_TDADeptAdd WITH(NOLOCK) 
     WHERE CompanySeq= @CompanySeq  
     AND DeptSeq = @DeptSeq  
   
 --���⵵ �����߿� Ȯ������  
     SELECT @PrevCfmPlanSeq = PlanSeq   
     FROM hencom_TPNPlan WITH(NOLOCK)   
     WHERE CompanySeq = @CompanySeq   
     AND PlanYear = @PrevYear   
     AND IsCfm = '1'   
       
 -- �����ȹ�⵵�� ���⵵�� �ش��ϴ� ǥ�ع���������� ��´�.     
     CREATE TABLE #TMP_MatItem (Gubun INT, ItemSeq INT )   
     
     --���Ϸ� �������
     INSERT #TMP_MatItem (Gubun , ItemSeq)
     SELECT -1,-1
     
     INSERT #TMP_MatItem (ItemSeq)    
     SELECT DISTINCT ItemSeq     
     FROM hencom_VPNPalnMatItemMapping     
     WHERE CompanySeq = @CompanySeq
     AND DeptSeq = @DeptSeq     
     AND StYear IN(@Year, @PrevYear)    
     AND ISNULL(ItemSeq,0) <> 0    
  --      select * from #TMP_MatItem 
  --  ���⵵ ��ǰ�����ȹ  
     SELECT '���⵵ ��ǰ�����ȹ' AS Test,  
         A.ItemSeq,  
         B.BPYm,  
         SUM(ISNULL(B.SalesQty,0)) AS SalesQty  ,
         SUM(ISNULL(SalesAmt,0)) AS SalesAmt 
     INTO #TMP_SalesPlanPrev  
     FROM hencom_TPNPSalesPlan AS A WITH(NOLOCK)    
     LEFT OUTER JOIN hencom_TPNPSalesPlanD AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq   
                                             AND B.PSalesRegSeq = A.PSalesRegSeq    
     WHERE A.DeptSeq = @DeptSeq      
     AND A.ItemSeq <> 0  --��ǰ�� ���.  
     --�⵵�� �����߿� Ȯ���� ������ ������� �Ѵ�.  
     AND A.PlanSeq = @PrevCfmPlanSeq  
     GROUP BY A.ItemSeq, B.BPYm  
     
   
 --������Դܰ�: �Ҽ���ù°�ڸ����� �ݿø�ó��.  
     SELECT '������Դܰ�' AS Test,  
         A.ItemSeq AS MatItemSeq,  
		 /*
         ROUND(SUM(B.Price01)/COUNT(1),0) AS Price01,  
         ROUND(SUM(B.Price02)/COUNT(1),0) AS Price02,  
         ROUND(SUM(B.Price03)/COUNT(1),0) AS Price03,  
         ROUND(SUM(B.Price04)/COUNT(1),0) AS Price04,  
         ROUND(SUM(B.Price05)/COUNT(1),0) AS Price05,  
         ROUND(SUM(B.Price06)/COUNT(1),0) AS Price06,  
         ROUND(SUM(B.Price07)/COUNT(1),0) AS Price07,  
         ROUND(SUM(B.Price08)/COUNT(1),0) AS Price08,  
         ROUND(SUM(B.Price09)/COUNT(1),0) AS Price09,  
         ROUND(SUM(B.Price10)/COUNT(1),0) AS Price10,  
         ROUND(SUM(B.Price11)/COUNT(1),0) AS Price11,         
		 ROUND(SUM(B.Price12)/COUNT(1),0) AS Price12  
		 */
	ROUND(SUM(ISNULL(B.Price01*B.WegtRate1*0.01,0)),0) AS Price01 ,
	ROUND(SUM(ISNULL(B.Price02*B.WegtRate2*0.01,0)),0) AS Price02 ,
	ROUND(SUM(ISNULL(B.Price03*B.WegtRate3*0.01,0)),0) AS Price03 ,
	ROUND(SUM(ISNULL(B.Price04*B.WegtRate4*0.01,0)),0) AS Price04 ,
	ROUND(SUM(ISNULL(B.Price05*B.WegtRate5*0.01,0)),0) AS Price05 ,
	ROUND(SUM(ISNULL(B.Price06*B.WegtRate6*0.01,0)),0) AS Price06 ,
	ROUND(SUM(ISNULL(B.Price07*B.WegtRate7*0.01,0)),0) AS Price07 ,
	ROUND(SUM(ISNULL(B.Price08*B.WegtRate8*0.01,0)),0) AS Price08 ,
	ROUND(SUM(ISNULL(B.Price09*B.WegtRate9*0.01,0)),0) AS Price09 ,
	ROUND(SUM(ISNULL(B.Price10*B.WegtRate10*0.01,0)),0) AS Price10 ,
	ROUND(SUM(ISNULL(B.Price11*B.WegtRate11*0.01,0)),0) AS Price11 ,
	ROUND(SUM(ISNULL(B.Price12*B.WegtRate12*0.01,0)),0) AS Price12
     INTO #TMP_MatPricePrev  
     FROM hencom_TPNMatPrice AS A WITH(NOLOCK) 
     JOIN hencom_TPNMatPriceD AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND B.MatPriceSeq = A.MatPriceSeq  
     WHERE A.CompanySeq = @CompanySeq  
     AND A.DeptSeq = @DeptSeq  
     AND A.PlanSeq = @PrevCfmPlanSeq  
     GROUP BY A.ItemSeq  
   
   --�����⵵�� ���� ������Դܰ��� ��մܰ�
     SELECT   
         U.MatItemSeq,  
         @PrevYear+RIGHT(U.YM,2) AS YM,  
         U.Price  
     INTO #TMP_PrevYMPrice  
     FROM #TMP_MatPricePrev AS B    
     UNPIVOT (Price FOR YM IN (Price01 ,Price02,Price03,Price04,Price05,Price06  
     ,Price07,Price08,Price09,Price10,Price11,Price12  
     )) AS U    
   
  
     SELECT 'hencom_VPNPalnReplaceRateMonthItem' AS Test,  
             A.StYM,  
             A.ItemSeq,  
             A.PerQty / f.ConvFactor as PerQty,  
             P.MatItemSeq ,  
             (SELECT Price FROM #TMP_PrevYMPrice WHERE YM = A.StYM AND MatItemSeq =P.MatItemSeq) AS Price  
     INTO #TMP_MonthItemPrev  --���� �ܰ�
     FROM test_hencom_VPNPalnReplaceRateMonthItem AS A  
     LEFT OUTER JOIN (SELECT MatItem,ItemSeq AS MatItemSeq  
                     FROM hencom_VPNPalnMatItemMapping  
                     WHERE CompanySeq = @CompanySeq 
                     AND StYear = @PrevYear  --���⵵
                     AND DeptSeq = @DeptSeq) AS P ON P.MatItem = A.MatItem   
     left outer join hencom_VPDConvFactorDate as f on f.CompanySeq = a.CompanySeq
	                                              and f.DeptSeq = a.DeptSeq
												  and f.ItemSeq = p.MatItemSeq
     WHERE A.PlanSeq = @PrevCfmPlanSeq  --���� �⵵�� �����߿� Ȯ���� ����.
   

  
     SELECT P.MatItemSeq                                 AS MatItemSeq, --��������  
           SUM(ISNULL(M.SalesQty*P.PerQty,0))            AS MatInputQty,  
           SUM(ISNULL(M.SalesQty*P.PerQty*P.Price,0))    AS MatInputAmt  
     INTO #TMP_PrevMatInputPaln  
     FROM #TMP_SalesPlanPrev AS M  
     JOIN #TMP_MonthItemPrev AS P ON P.StYM = M.BPYm AND P.ItemSeq = M.ItemSeq   
     WHERE ISNULL(P.MatItemSeq,0) <> 0  
     GROUP BY P.MatItemSeq  
   
   
 --���⵵ ���� �������� �ݾ�  
     SELECT  --DeptSeq,  
             ItemSeq,  
             SUM(Qty) AS Qty,  
             SUM(Amt) AS Amt   
     INTO #TMP_MatPrevInput  
     FROM _TESMGInoutstock WITH(NOLOCK) 
     WHERE CompanySeq = @CompanySeq
     AND InOut = -1  
     AND InOutKind = 8023015 --��������  
     AND DeptSeq = @ProdDeptSeq  
     AND LEFT(InOutDate,4) =@PrevYear  
     GROUP BY ItemSeq  
   
 --�ش����� ������ ��ȸ -----------------------------------------------------------------------------------------
 -- ��ǰ�����ȹ  
     SELECT '�ش����� ��ǰ�����ȹ' AS Test,  
         A.ItemSeq,  
         B.BPYm,  
         SUM(ISNULL(B.SalesQty,0)) AS SalesQty ,
		 sum(isnull(b.SalesAmt,0)) as SalesAmt  
     INTO #TMP_SalesPlanThis  
     FROM hencom_TPNPSalesPlan AS A WITH(NOLOCK)    
     LEFT OUTER JOIN hencom_TPNPSalesPlanD AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq   
         AND B.PSalesRegSeq = A.PSalesRegSeq    
     WHERE A.DeptSeq = @DeptSeq      
     AND A.ItemSeq <> 0  --��ǰ�� ���.  
     AND A.PlanSeq = @PlanSeq  

     --and right(B.BPYM ,2) = '01'
     --and a.itemSeq in (  22413, 61089 ) 
     GROUP BY A.ItemSeq, B.BPYm  
    
    --return 


 --  select '#TMP_SalesPlanThis',* from #TMP_SalesPlanThis return
 --������Դܰ�: �Ҽ���ù°�ڸ����� �ݿø�ó��.  
     SELECT '������Դܰ�' AS Test,  
         A.ItemSeq AS MatItemSeq,  
		 /*
         ROUND(SUM(B.Price01)/COUNT(1),0) AS Price01,  
         ROUND(SUM(B.Price02)/COUNT(1),0) AS Price02,  
         ROUND(SUM(B.Price03)/COUNT(1),0) AS Price03,  
         ROUND(SUM(B.Price04)/COUNT(1),0) AS Price04,  
         ROUND(SUM(B.Price05)/COUNT(1),0) AS Price05,  
         ROUND(SUM(B.Price06)/COUNT(1),0) AS Price06,  
         ROUND(SUM(B.Price07)/COUNT(1),0) AS Price07,  
         ROUND(SUM(B.Price08)/COUNT(1),0) AS Price08,  
         ROUND(SUM(B.Price09)/COUNT(1),0) AS Price09,  
         ROUND(SUM(B.Price10)/COUNT(1),0) AS Price10,  
         ROUND(SUM(B.Price11)/COUNT(1),0) AS Price11,  
         ROUND(SUM(B.Price12)/COUNT(1),0) AS Price12  
		 */
		ROUND(SUM(ISNULL(B.Price01*B.WegtRate1*0.01,0)),0) AS Price01 ,
		ROUND(SUM(ISNULL(B.Price02*B.WegtRate2*0.01,0)),0) AS Price02 ,
		ROUND(SUM(ISNULL(B.Price03*B.WegtRate3*0.01,0)),0) AS Price03 ,
		ROUND(SUM(ISNULL(B.Price04*B.WegtRate4*0.01,0)),0) AS Price04 ,
		ROUND(SUM(ISNULL(B.Price05*B.WegtRate5*0.01,0)),0) AS Price05 ,
		ROUND(SUM(ISNULL(B.Price06*B.WegtRate6*0.01,0)),0) AS Price06 ,
		ROUND(SUM(ISNULL(B.Price07*B.WegtRate7*0.01,0)),0) AS Price07 ,
		ROUND(SUM(ISNULL(B.Price08*B.WegtRate8*0.01,0)),0) AS Price08 ,
		ROUND(SUM(ISNULL(B.Price09*B.WegtRate9*0.01,0)),0) AS Price09 ,
		ROUND(SUM(ISNULL(B.Price10*B.WegtRate10*0.01,0)),0) AS Price10 ,
		ROUND(SUM(ISNULL(B.Price11*B.WegtRate11*0.01,0)),0) AS Price11 ,
		ROUND(SUM(ISNULL(B.Price12*B.WegtRate12*0.01,0)),0) AS Price12
     INTO #TMP_MatPriceThis  
     FROM hencom_TPNMatPrice AS A WITH(NOLOCK) 
     JOIN hencom_TPNMatPriceD AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND B.MatPriceSeq = A.MatPriceSeq  
     WHERE A.CompanySeq = @CompanySeq  
     AND A.DeptSeq = @DeptSeq  
     AND A.PlanSeq = @PlanSeq  
     GROUP BY A.ItemSeq  
   
 --  select * from #TMP_MatPriceThis return
   --���� ������Դܰ��� ��մܰ�
     SELECT   
         U.MatItemSeq,  
         @Year+RIGHT(U.YM,2) AS YM,  
         U.Price  
     INTO #TMP_ThisYMPrice  
     FROM #TMP_MatPriceThis AS B    
     UNPIVOT (Price FOR YM IN (Price01 ,Price02,Price03,Price04,Price05,Price06  
     ,Price07,Price08,Price09,Price10,Price11,Price12  
     )) AS U    
  

  --select * from test_hencom_VPNPalnReplaceRateMonthItem where stym = '201701' and itemseq in ( 2416, 2420 ) and matitem in ( 'A1', 'A2' ) 
  --return 
  --select * from hencom_VPNPalnReplaceRateMonthItem where stym = '201701' and itemseq in ( 2416, 2420 ) and matitem in ( 'A1', 'A2', 
  --return 

     SELECT 'hencom_VPNPalnReplaceRateMonthItem' AS Test,  
             A.StYM,  
             A.ItemSeq,  
             A.PerQty / f.ConvFactor as PerQty,  
             P.MatItemSeq ,  
             (SELECT Price FROM #TMP_ThisYMPrice WHERE YM = A.StYM AND MatItemSeq =P.MatItemSeq) AS Price  
     INTO #TMP_MonthItemThis  --���� �ܰ�
     FROM test_hencom_VPNPalnReplaceRateMonthItem AS A  
     LEFT OUTER JOIN (SELECT MatItem,ItemSeq AS MatItemSeq  
                     FROM hencom_VPNPalnMatItemMapping  
                     WHERE CompanySeq = @CompanySeq 
                     AND StYear = @Year  --�⵵
                     AND DeptSeq = @DeptSeq) AS P ON P.MatItem = A.MatItem  
     left outer join hencom_VPDConvFactorDate as f on f.CompanySeq = a.CompanySeq
	                                              and f.DeptSeq = a.DeptSeq
												  and f.ItemSeq = p.MatItemSeq
     WHERE A.PlanSeq = @PlanSeq 
      --and a.stym = '201702' 
      --and matitemseq in ( 22413, 61089 ) 
      --and a.itemseq in ( 2416, 2420 )
	 
     --returCn 

     --select * From _TDAITem where itemseq =22413 
    --select sum(PerQty * Price ) / Sum(PerQty)


    --from #TMP_MonthItemThis where right(stym,2) = '01' and  itemseq in ( 2416, 2420 ) and matitemseq in (  22413, 61089 )

    ----select *from #TMP_MonthItemThis where right(stym,2) = '02' and  itemseq in ( 2416, 2420 )  and matitemseq in (  22413, 61089 )

    --return 
	 


    -- select * from #TMP_SalesPlanThis
    ---- --select * from #TMP_SalesPlanThis where right(bpym,2) = '01'
    --select * 
    --  from #TMP_MonthItemThis as a 
    --  join #TMP_SalesPlanThis as b on ( b.itemseq = a.itemseq ) 
    -- where  right(StYM,2) = '01' and MatItemSeq in (  22413, 61089 ) 
    -- and right(bpym,2) = '01'

    -- return 
    -- --select * from #TMP_SalesPlanThis where right(bpym,2) = '02'
    --select * 
    --  from #TMP_MonthItemThis as a 
    --  join #TMP_SalesPlanThis as b on ( b.itemseq = a.itemseq ) 
    --where  right(StYM,2) = '02' and MatItemSeq in (  22413, 61089 ) 
    --and right(bpym,2) = '02'

    --return 



 --select '#TMP_SalesPlanThis',* from #TMP_SalesPlanThis 
 --select '#TMP_MonthItemThis',* from #TMP_MonthItemThis return
      SELECT P.MatItemSeq                                 AS MatItemSeq, --��������  
           M.BPYm                                        AS BPYm , 
           SUM(ISNULL(M.SalesQty*P.PerQty,0))            AS MatInputQty,  
           SUM(ISNULL(M.SalesQty*P.PerQty*P.Price,0))    AS MatInputAmt  
     INTO #TMP_ThisMatInputPaln  
     FROM #TMP_SalesPlanThis AS M  
     JOIN #TMP_MonthItemThis AS P ON P.StYM = M.BPYm AND P.ItemSeq = M.ItemSeq   
     WHERE ISNULL(P.MatItemSeq,0) <> 0  
       and P.MatItemSeq in (  22413, 61089 ) 

       and RIGHT(M.BPYm,2) = '01'
     GROUP BY P.MatItemSeq,M.BPYm
    
--return 
    -- select *From _TDAItem where itemseq = 61089 
    -- select * From _TDAitem where ItemSeq = 61089
    
    --return 





      SELECT B.MatItemSeq    
             --����    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '01' THEN MatInputQty ELSE 0 END) AS MatInputQty1    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '02' THEN MatInputQty ELSE 0 END) AS MatInputQty2    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '03' THEN MatInputQty ELSE 0 END) AS MatInputQty3    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '04' THEN MatInputQty ELSE 0 END) AS MatInputQty4    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '05' THEN MatInputQty ELSE 0 END) AS MatInputQty5    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '06' THEN MatInputQty ELSE 0 END) AS MatInputQty6    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '07' THEN MatInputQty ELSE 0 END) AS MatInputQty7    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '08' THEN MatInputQty ELSE 0 END) AS MatInputQty8    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '09' THEN MatInputQty ELSE 0 END) AS MatInputQty9    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '10' THEN MatInputQty ELSE 0 END) AS MatInputQty10    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '11' THEN MatInputQty ELSE 0 END) AS MatInputQty11    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '12' THEN MatInputQty ELSE 0 END) AS MatInputQty12    
             --�ݾ�    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '01' THEN MatInputAmt ELSE 0 END) AS MatInputAmt1    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '02' THEN MatInputAmt  ELSE 0 END) AS MatInputAmt2    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '03' THEN MatInputAmt ELSE 0 END) AS MatInputAmt3    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '04' THEN MatInputAmt ELSE 0 END) AS MatInputAmt4    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '05' THEN MatInputAmt ELSE 0 END) AS MatInputAmt5    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '06' THEN  MatInputAmt ELSE 0 END) AS MatInputAmt6    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '07' THEN MatInputAmt ELSE 0 END) AS MatInputAmt7    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '08' THEN MatInputAmt ELSE 0 END) AS MatInputAmt8    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '09' THEN MatInputAmt ELSE 0 END) AS MatInputAmt9    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '10' THEN MatInputAmt ELSE 0 END) AS MatInputAmt10    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '11' THEN MatInputAmt ELSE 0 END) AS MatInputAmt11    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '12' THEN MatInputAmt ELSE 0 END) AS MatInputAmt12    
     INTO #TMP_ThisMatInputPalnYMData
     FROM #TMP_ThisMatInputPaln AS B 
     --where B.MatItemSeq in  ( 22413, 61089 ) 
     GROUP BY B.MatItemSeq
      --�ش� ������ �Ѱ�
     SELECT MatItemSeq,
         SUM(ISNULL(MatInputQty,0)) AS TotQty,
         SUM(ISNULL(MatInputAmt,0)) AS TotAmt,
         SUM(ISNULL(MatInputAmt,0)) / SUM(ISNULL(MatInputQty,0)) AS AvgPrice
     INTO #TMP_ThisTot
     FROM #TMP_ThisMatInputPaln
     GROUP BY MatItemSeq
     
     --select * from #TMP_ThisMatInputPaln where matitemseq in ( 22413, 61089 ) 
     --return 

    
    --return 
     --MES ���Ͻý��ۿ��� �Ѿ�� ���ϵ����͸� �հ�ó���� ���Ͻ����հ� 
		 ---- ��������ȹ �� ����հ�
      SELECT -1 AS Gubun   ,max(LEFT(BPYm,4)) AS YY
     --����    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '01' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty1    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '02' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty2    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '03' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty3    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '04' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty4    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '05' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty5    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '06' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty6    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '07' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty7    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '08' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty8    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '09' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty9    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '10' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty10    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '11' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty11    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '12' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty12    
         --�ݾ�    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '01' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt1    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '02' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt2    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '03' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt3    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '04' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt4    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '05' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt5    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '06' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt6    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '07' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt7    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '08' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt8    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '09' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt9    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '10' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt10    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '11' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt11    
         ,SUM(CASE WHEN RIGHT(BPYm,2) = '12' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt12    
     INTO #TMPIFProdWorkReportCloseSumThisYear
     FROM #TMP_SalesPlanThis AS B
     
     SELECT  -1 AS Gubun ,
             LEFT(WorkDate,4) AS YY ,
             SUM(ISNULL(OutQty,0)) AS OutQty ,
        SUM(ISNULL(CurAmt,0)) AS CurAmt
     INTO #TMPIFProdWorkReportCloseSumThisTot
     FROM hencom_TIFProdWorkReportCloseSum AS B
     WHERE CompanySeq = @CompanySeq
     AND LEFT(WorkDate,4) IN (@PrevYear )
     AND DeptSeq = @DeptSeq
     GROUP BY LEFT(WorkDate,4)
     
     
    -- select * from #TMP_ThisMatInputPalnYMData where MatItemSeq in ( 22413, 61089 ) 
    
    --return 

--     select * from #TMPIFProdWorkReportCloseSumThis return
  --������ȸ  
     
     SELECT A.ItemSeq,  
             B.ItemName,  
             B.ItemNo,  
             B.Spec,    
             C.ItemClasLName                         AS ItemClassLName, --�����з�     
             C.ItemClassLSeq                         AS ItemClassLSeq  ,  
             MatPrev.Qty                             AS PrevQty , --���⵵ ����  
             MatPrev.Amt                             AS PrevAmt, --���⵵ ����  
             MatPrev.Amt / MatPrev.Qty               AS PrevPrice, --���⵵ ����  
             MPPrev.MatItemSeq                       AS MatItemSeq,--���⵵ �����ȹ ����  
             MPPrev.MatInputQty                      AS PrevTotQty, --���⵵ �����ȹ �������� ����  
             MPPrev.MatInputAmt                      AS PrevTotAmt , --���⵵ �����ȹ �������� �ݾ�  
             MPPrev.MatInputAmt / MPPrev.MatInputQty AS PrevAvgPrice , --���⵵ �����ȹ �������� �ܰ� 
             T.MatInputQty1 AS Qty1 ,
             T.MatInputAmt1 AS Amt1 ,
             T.MatInputAmt1 / T.MatInputQty1 AS Price1 ,
             T.MatInputQty2 AS Qty2 ,
             T.MatInputAmt2 AS Amt2 ,
             T.MatInputAmt2 / T.MatInputQty2 AS Price2 ,
             T.MatInputQty3 AS Qty3 ,
             T.MatInputAmt3 AS Amt3 ,
             T.MatInputAmt3 / T.MatInputQty3 AS Price3 ,
             T.MatInputQty4 AS Qty4 ,
             T.MatInputAmt4 AS Amt4 ,
             T.MatInputAmt4 / T.MatInputQty4 AS Price4 ,
             T.MatInputQty5 AS Qty5 ,
             T.MatInputAmt5 AS Amt5 ,
             T.MatInputAmt5 / T.MatInputQty5 AS Price5 ,
             T.MatInputQty6 AS Qty6 ,
             T.MatInputAmt6 AS Amt6 ,
             T.MatInputAmt6 / T.MatInputQty6 AS Price6 ,
             T.MatInputQty7 AS Qty7 ,
             T.MatInputAmt7 AS Amt7 ,
             T.MatInputAmt7 / T.MatInputQty7 AS Price7 ,
             T.MatInputQty8 AS Qty8 ,
             T.MatInputAmt8 AS Amt8 ,
             T.MatInputAmt8 / T.MatInputQty8 AS Price8 ,
             T.MatInputQty9 AS Qty9 ,
             T.MatInputAmt9 AS Amt9 ,
             T.MatInputAmt9 / T.MatInputQty9 AS Price9 ,
             T.MatInputQty10 AS Qty10 ,
             T.MatInputAmt10 AS Amt10 ,
             T.MatInputAmt10 / T.MatInputQty10 AS Price10 ,
             T.MatInputQty11 AS Qty11 ,
             T.MatInputAmt11 AS Amt11 ,
             T.MatInputAmt11 / T.MatInputQty11 AS Price11 ,
             T.MatInputQty12 AS Qty12 ,
             T.MatInputAmt12 AS Amt12,
             T.MatInputAmt12 / T.MatInputQty12 AS Price12 ,
             Tot.TotQty      AS TotQty,
             Tot.TotAmt      AS TotAmt,
             Tot.AvgPrice    AS AvgPrice
     into #tempresult_sub
     FROM #TMP_MatItem AS A    
     LEFT OUTER JOIN _TDAItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq   
                                                 AND B.ItemSeq = A.ItemSeq    
     LEFT OUTER JOIN dbo._FDAGetItemClass(@CompanySeq,0) AS C ON C.ItemSeq = A.ItemSeq   
     LEFT OUTER JOIN #TMP_MatPrevInput AS MatPrev ON  MatPrev.ItemSeq = A.ItemSeq  
     LEFT OUTER JOIN #TMP_PrevMatInputPaln AS MPPrev ON MPPrev.MatItemseq = A.ItemSeq  
     LEFT OUTER JOIN #TMP_ThisMatInputPalnYMData AS T ON T.MatItemSeq = A.ItemSeq
     LEFT OUTER JOIN #TMP_ThisTot AS ToT ON ToT.MatItemSeq = A.ItemSeq
     WHERE ISNULL(A.Gubun,0) = 0


     --select ItemSeq, ItemName, ItemClassLName, ItemClassLSeq, Qty1, Price1 from #tempresult_sub where itemclasslseq = 2006006
     --return 


  insert #tempresult_sub
  SELECT  -1 AS ItemSeq,  
             '����' AS ItemName,  
             '' AS ItemNo,  
             '' AS Spec,    
             '' AS ItemClassLName, --�����з�     
             0 AS ItemClassLSeq  ,  
             STP.OutQty                          AS PrevQty , --���⵵ ����  
             STP.CurAmt                          AS PrevAmt, --���⵵ ����  
             STP.CurAmt/STP.OutQty               AS PrevPrice, --���⵵ ����  
             -1                                  AS MatItemSeq,--���⵵ �����ȹ ����  
             PrevTot.SalesQty                    AS PrevTotQty, --���⵵ �����ȹ �������� ����  
             PrevTot.SalesAmt                    AS PrevTotAmt , --���⵵ �����ȹ �������� �ݾ�  
             PrevTot.SalesAmt /PrevTot.SalesQty  AS PrevAvgPrice , --���⵵ �����ȹ �������� �ܰ� 
             S.Qty1 AS Qty1 ,
             S.Amt1 AS Amt1 ,
             S.Amt1 / S.Qty1 AS Price1 ,
             S.Qty2 AS Qty2 ,
             S.Amt2 AS Amt2 ,
             S.Amt2 / S.Qty2 AS Price2 ,
             S.Qty3 AS Qty3 ,
             S.Amt3 AS Amt3 ,
             S.Amt3 / S.Qty3 AS Price3 ,
             S.Qty4 AS Qty4 ,
             S.Amt4 AS Amt4 ,
             S.Amt4 / S.Qty4 AS Price4 ,
             S.Qty5 AS Qty5 ,
             S.Amt5 AS Amt5 ,
             S.Amt5 / S.Qty5 AS Price5 ,
             S.Qty6 AS Qty6 ,
             S.Amt6 AS Amt6 ,
             S.Amt6 / S.Qty6 AS Price6 ,
             S.Qty7 AS Qty7 ,
             S.Amt7 AS Amt7 ,
             S.Amt7 / S.Qty7 AS Price7 ,
             S.Qty8 AS Qty8 ,
             S.Amt8 AS Amt8 ,
             S.Amt8 / S.Qty8 AS Price8 ,
             S.Qty9 AS Qty9 ,
             S.Amt9 AS Amt9 ,
             S.Amt9 / S.Qty9 AS Price9 ,
             S.Qty10 AS Qty10 ,
             S.Amt10 AS Amt10 ,
             S.Amt10  / S.Qty10 AS Price10 ,
             S.Qty11 AS Qty11 ,
             S.Amt11 AS Amt11 ,
             S.Amt11 / S.Qty11 AS Price11 ,
             S.Qty12 AS Qty12 ,
             S.Amt12 AS Amt12,
             S.Amt12 / S.Qty12 AS Price12 ,
             ST.SalesQty      AS TotQty,
             ST.SalesAmt      AS TotAmt,
             ST.SalesAmt /ST.SalesQty   AS AvgPrice
     FROM #TMP_MatItem AS A    
     LEFT OUTER JOIN #TMPIFProdWorkReportCloseSumThisYear AS S ON S.Gubun = A.Gubun
     LEFT OUTER JOIN ( select sum(Salesqty) as SalesQty, sum(SalesAmt) as SalesAmt   from #TMP_SalesPlanThis) AS ST ON 1=1  ---- ���س⵵��ȹ��Ż    ---- �ִ� �ٽø����� ��
     LEFT OUTER JOIN #TMPIFProdWorkReportCloseSumThisTot AS STP ON STP.Gubun = A.Gubun AND STP.YY = @PrevYear -- ���⵵������Ż
     LEFT OUTER JOIN (SELECT SUM(ISNULL(SalesQty,0)) AS SalesQty ,SUM(ISNULL(SalesAmt,0)) AS SalesAmt  
                     FROM #TMP_SalesPlanPrev) AS PrevTot ON 1=1  
     WHERE A.Gubun = -1
	 alter table #tempresult_sub add 
						PrevM3Qty decimal(19,5) null,
						PrevM3TotQty decimal(19,5) null,
						TotM3Qty decimal(19,5) null,
						M3Qty1 decimal(19,5) null,
						M3Qty2 decimal(19,5) null,
						M3Qty3 decimal(19,5) null,
						M3Qty4 decimal(19,5) null,
						M3Qty5 decimal(19,5) null,
						M3Qty6 decimal(19,5) null,
						M3Qty7 decimal(19,5) null,
						M3Qty8 decimal(19,5) null,
						M3Qty9 decimal(19,5) null,
						M3Qty10 decimal(19,5) null,
						M3Qty11 decimal(19,5) null,
						M3Qty12 decimal(19,5) null
	 update a
	    set PrevPrice = a.PrevAmt / b.PrevQty ,
		    PrevAvgPrice = a.PrevTotAmt /b.PrevTotQty,
			Price1 = a.Amt1  / b.Qty1 ,
			Price2 = a.Amt2  / b.Qty2,
			Price3 = a.Amt3   / b.Qty3,
			Price4 = a.Amt4   / b.Qty4,
			Price5 = a.Amt5   / b.Qty5,
			Price6 = a.Amt6   / b.Qty6,
			Price7 = a.Amt7   / b.Qty7,
			Price8 = a.Amt8   / b.Qty8,
			Price9 = a.Amt9   / b.Qty9,
			Price10 = a.Amt10   / b.Qty10,
			Price11 = a.Amt11   / b.Qty11,
			Price12 = a.Amt12   / b.Qty12,
			AvgPrice = a.TotAmt / b.TotQty,
			PrevM3Qty = a.PrevQty /  b.PrevQty ,
			PrevM3TotQty = a.PrevTotQty / b.PrevTotQty,
			TotM3Qty = a.TotQty / b.TotQty,
			M3Qty1 = a.Qty1 / b.Qty1,
			M3Qty2 = a.Qty2 / b.Qty2,
			M3Qty3 = a.Qty3 / b.Qty3,
			M3Qty4 = a.Qty4 / b.Qty4,
			M3Qty5 = a.Qty5 / b.Qty5,
			M3Qty6 = a.Qty6 / b.Qty6,
			M3Qty7 = a.Qty7 / b.Qty7,
			M3Qty8 = a.Qty8 / b.Qty8,
			M3Qty9 = a.Qty9 / b.Qty9,
			M3Qty10 = a.Qty10 / b.Qty10,
			M3Qty11 = a.Qty11 / b.Qty11,
			M3Qty12 = a.Qty12 / b.Qty12
	   from #tempresult_sub as a
	   join #tempresult_sub as b on b.ItemSeq = -1 
	  where a.itemseq <> -1
	 select *
	   from #tempresult_sub 
   order by itemseq
     
 RETURN

go 
begin tran 

exec test_hencom_SPNQCReplaceRatePlanResultQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <DeptSeq>44</DeptSeq>
    <PlanSeq>3</PlanSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1510198,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1031857
rollback 