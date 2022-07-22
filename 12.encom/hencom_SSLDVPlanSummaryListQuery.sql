IF OBJECT_ID('hencom_SSLDVPlanSummaryListQuery') IS NOT NULL 
    DROP PROC hencom_SSLDVPlanSummaryListQuery
GO 

-- v2017.03.23 
/************************************************************        
  ��  �� - ������-���Ͽ����Ѱ���Ȳ_hencom : ��ȸ        
  �ۼ��� - 20151215        
  �ۼ��� - �ڼ���     
 ************************************************************/        
         
 CREATE PROC dbo.hencom_SSLDVPlanSummaryListQuery                        
  @xmlDocument    NVARCHAR(MAX) ,                    
  @xmlFlags     INT  = 0,                    
  @ServiceSeq     INT  = 0,                    
  @WorkingTag     NVARCHAR(10)= '',                          
  @CompanySeq     INT  = 1,                    
  @LanguageSeq  INT  = 1,                    
  @UserSeq      INT  = 0,                    
  @PgmSeq         INT  = 0                 
             
 AS                
          
     DECLARE @docHandle      INT,        
             @StdDate        NCHAR(8) ,        
             @DeptSeq        INT,        
             @LastDate       NCHAR(8),      
             @LastYM         NCHAR(6)          
       
  EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                     
         
     SELECT  @StdDate     = StdDate      ,        
             @DeptSeq     = DeptSeq              
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)        
    WITH (StdDate      NCHAR(8) ,        
          DeptSeq      INT )        
                     
     SELECT @LastDate = CONVERT(NCHAR,DATEADD(DD,-1,@StdDate),112)        
     SELECT @LastYM = CONVERT(NCHAR,DATEADD(YY,-1,@StdDate),112)       
           
   /*0������ ���� ��� ó��*/                
     SET ANSI_WARNINGS OFF                
     SET ARITHIGNORE ON                
     SET ARITHABORT OFF          
           
     CREATE TABLE #TMPMst  
     (  
         DeptSeq INT,  
         DispSeq INT,  
         UMTotalDiv INT  
     )  
     --����Ұ���(�߰�����)�� ��������豸�� ���� �ִ� �͸� ��ȸ.  
     INSERT #TMPMst (DeptSeq,DispSeq,UMTotalDiv)  
     SELECT M.DeptSeq,A.DispSeq,A.UMTotalDiv  
     FROM _TDADept AS M    
     LEFT OUTER JOIN hencom_TDADeptAdd  AS A WITH (NOLOCK) ON A.CompanySeq = @CompanySeq AND A.DeptSeq = M.DeptSeq    
     LEFT OUTER JOIN _TDAUMinor AS UM WITH (NOLOCK) ON UM.CompanySeq = @CompanySeq AND UM.MinorSeq = A.UMTotalDiv  
     WHERE  M.CompanySeq = @CompanySeq    
     AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)     
     AND ISNULL(A.UMTotalDiv,0) <> 0  
     
     
     SELECT  A.ExpShipDate             AS ExpShipDate,        
             A.DeptSeq                 AS DeptSeq  ,        
             (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq ) AS DeptName ,        
             A.ItemSeq                 AS ItemSeq  ,        
             B.SMAssetGrp              AS SMAssetGrp,        
             (SELECT MinorName FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = B.SMAssetGrp ) AS AssetName,        
             SUM(ISNULL(A.Qty,0))      AS Qty      ,        
             SUM(ISNULL(A.CurAmt,0))   AS CurAmt   ,        
             SUM(ISNULL(A.CurVAT,0))   AS CurVAT         
     INTO #TMPData        
     FROM hencom_TSLExpShipment  AS A WITH (NOLOCK)         
     LEFT OUTER JOIN _TDAItem AS I WITH (NOLOCK) ON I.CompanySeq = @CompanySeq AND I.ItemSeq = A.ItemSeq        
     LEFT OUTER JOIN _TDAItemAsset AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.AssetSeq = I.AssetSeq        
   WHERE  A.CompanySeq = @CompanySeq        
     AND (LEFT(A.ExpShipDate,6) = LEFT(@StdDate,6)  OR A.ExpShipDate = @LastDate )           
     AND (@DeptSeq = 0 OR A.DeptSeq  = @DeptSeq)        
     GROUP BY A.ExpShipDate,A.DeptSeq,A.ItemSeq,B.SMAssetGrp        
           
 --���ϱ��ص�����     
 /*  
     SELECT  A.DeptSeq ,      
             A.WorkDate,      
             SUM(ISNULL(A.ProdQty,0))  AS ProdQty ,      
             SUM(ISNULL(A.OutQty,0))   AS OutQty ,      
             SUM(ISNULL(A.CurAmt,0))   AS CurAmt ,      
             SUM(ISNULL(A.CurVAT,0))   AS CurVAT,       
             B.SMAssetGrp              AS SMAssetGrp      
     INTO #TMPCloseData      
     FROM hencom_TIFProdWorkReportClosesum AS A WITH (NOLOCK)         
     LEFT OUTER JOIN _TDAItem AS I WITH (NOLOCK) ON I.CompanySeq = @CompanySeq AND I.ItemSeq = A.GoodItemSeq        
     LEFT OUTER JOIN _TDAItemAsset AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.AssetSeq = I.AssetSeq        
     WHERE A.CompanySeq = @CompanySeq      
     AND (LEFT(A.WorkDate,6) = LEFT(@StdDate,6) OR A.WorkDate = @LastDate OR LEFT(A.WorkDate,6) = @LastYM)      
     GROUP BY A.DeptSeq ,A.WorkDate,B.SMAssetGrp      
 */  
  SELECT     A.DeptSeq ,      
             A.WorkDate,      
             SUM(ISNULL(A.ProdQty,0))  AS ProdQty ,      
             SUM(ISNULL(A.OutQty,0))   AS OutQty ,      
             SUM(ISNULL(A.CurAmt,0))   AS CurAmt ,      
             SUM(ISNULL(A.CurVAT,0))   AS CurVAT,       
             B.SMAssetGrp              AS SMAssetGrp      
     INTO #TMPCloseData      
     FROM hencom_VInvoiceReplaceItem AS A WITH (NOLOCK)         
     LEFT OUTER JOIN _TDAItem AS I WITH (NOLOCK) ON I.CompanySeq = @CompanySeq AND I.ItemSeq = A.ItemSeq        
     LEFT OUTER JOIN _TDAItemAsset AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.AssetSeq = I.AssetSeq        
     WHERE A.CompanySeq = @CompanySeq      
     AND (LEFT(A.WorkDate,6) = LEFT(@StdDate,6) OR A.WorkDate = @LastDate OR LEFT(A.WorkDate,6) = @LastYM)      
     GROUP BY A.DeptSeq ,A.WorkDate,B.SMAssetGrp      
       
 --�����ǸŰ�ȹ�� ����������    
     CREATE TABLE #TMPActPlan    
     (    
         DeptSeq     INT,
         ActPlanQty  DECIMAL(19,5) ,
         ActPlanAmt  DECIMAL(19,5) 
     )    
     INSERT #TMPActPlan (DeptSeq,ActPlanQty,ActPlanAmt)
     SELECT DeptSeq,SUM(ISNULL(PlanQty,0)),SUM(ISNULL(PlanAmt,0)) --,PlanYM
     FROM _TSLPlanYearSales
     WHERE CompanySeq = @CompanySeq
     AND PlanYM = LEFT(@StdDate,6)
     GROUP BY DeptSeq 
     
 --    select * from #TMPCloseData        
 --      return      
     SELECT  
         (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq ) AS DeptName ,      
         W.Weather,        
		 W.Remark,
         W.Temperature, 
         A.Qty,        
         A.CurAmt,        
         L.Qty    AS LastQty,        
         LI.Qty   AS LastItemQty, --���� ��ǰ���Ϸ�        
         LG.QTy   AS LastGoodQty, --���� ��ǰ���Ϸ�        
         ISNULL(LI.Qty,0) + ISNULL(LG.QTy,0) AS LastTotQty , --���� ��ǰ+��ǰ���Ϸ�        
         L.CurAmt            AS LastCurAmt , --���Ͽ����ݾ�       
         AccI.Qty            AS AccItemQty  ,----����������Ϸ� : ��ǰ      
         AccG.Qty            AS AccGoodQty  ,--����������Ϸ� : ��ǰ      
         ISNULL(AccI.Qty,0) + ISNULL(AccG.Qty,0) AS AccTotQty , --�հ����      
         AccTot.CurAmt       AS AccCurAmt , --�������ϱݾ�      
         PrvAcc.CurAmt       AS PrevMMQty , --���⵿�����Ϸ�      
         PL.ActPlanQty     AS YMPalnQty  , --�����ǥ����      
         (ISNULL(AccI.Qty,0) + ISNULL(AccG.Qty,0))/ PL.ActPlanQty * 100 AS SuccQtyRate ,     --������ǥ�޼���     
         PL.ActPlanAmt                       AS YMPalnAmt ,      --�����ǥ�ݾ�
         AccTot.CurAmt / PL.ActPlanAmt * 100 AS SuccAmtRate     --�ݾ׸�ǥ�޼���
     FROM #TMPMst AS M     
     LEFT OUTER JOIN (SELECT DeptSeq, Remark,Temperature,(SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq 
                                                                        AND MinorSeq = UMWeather) AS Weather --���� ����
                        FROM hencom_TSLWeather WHERE CompanySeq = @CompanySeq 
                                                AND WDate = @StdDate        
                  ) AS W ON W.DeptSeq = M.DeptSeq        
     LEFT OUTER JOIN (SELECT DeptSeq,SUM(ISNULL(Qty,0)) AS Qty ,SUM(ISNULL(CurAmt,0)) AS CurAmt  --���Ͽ���        
                  FROM #TMPData         
                  WHERE ExpShipDate = @StdDate         
                  GROUP BY DeptSeq ) AS A ON A.DeptSeq = M.DeptSeq       
     LEFT OUTER JOIN (SELECT DeptSeq,SUM(ISNULL(Qty,0)) AS Qty ,SUM(ISNULL(CurAmt,0)) AS CurAmt  --���Ͽ���        
                  FROM #TMPData         
                  WHERE ExpShipDate = @LastDate         
                  GROUP BY DeptSeq ) AS L ON L.DeptSeq = M.DeptSeq        
     LEFT OUTER JOIN (SELECT DeptSeq,SUM(ISNULL(OutQty,0)) AS Qty ,SUM(ISNULL(CurAmt,0)) AS CurAmt  --��������:��ǰ        
                  FROM #TMPCloseData         
                  WHERE WorkDate = @LastDate AND SMAssetGrp IN ( 6008002 ,6008003) --��ǰ  ,����      
                  GROUP BY DeptSeq ) AS LI ON LI.DeptSeq = M.DeptSeq        
     LEFT OUTER JOIN (SELECT DeptSeq,SUM(ISNULL(OutQty,0)) AS Qty ,SUM(ISNULL(CurAmt,0)) AS CurAmt  --��������:��ǰ        
                  FROM #TMPCloseData         
                  WHERE WorkDate = @LastDate AND SMAssetGrp = 6008001 --��ǰ        
                    GROUP BY DeptSeq ) AS LG ON LG.DeptSeq = M.DeptSeq         
     LEFT OUTER JOIN (SELECT DeptSeq,SUM(ISNULL(OutQty,0)) AS Qty ,SUM(ISNULL(CurAmt,0)) AS CurAmt  --�����������:��ǰ        
                  FROM #TMPCloseData         
                  WHERE LEFT(WorkDate,6) = LEFT(@StdDate,6)       
                  AND SMAssetGrp IN ( 6008002 ,6008003) --��ǰ  ,����         
                  GROUP BY DeptSeq ) AS AccI ON AccI.DeptSeq = M.DeptSeq        
     LEFT OUTER JOIN (SELECT DeptSeq,SUM(ISNULL(OutQty,0)) AS Qty ,SUM(ISNULL(CurAmt,0)) AS CurAmt  --�����������:��ǰ        
                  FROM #TMPCloseData         
                  WHERE LEFT(WorkDate,6) = LEFT(@StdDate,6)       
                  AND SMAssetGrp = 6008001 --��ǰ        
                  GROUP BY DeptSeq ) AS AccG ON AccG.DeptSeq = M.DeptSeq               
       LEFT OUTER JOIN (SELECT DeptSeq,SUM(ISNULL(OutQty,0)) AS Qty ,SUM(ISNULL(CurAmt,0)) AS CurAmt  --�����������: �հ�      
                  FROM #TMPCloseData         
                  WHERE LEFT(WorkDate,6) = LEFT(@StdDate,6)        
                  GROUP BY DeptSeq ) AS AccTot ON AccTot.DeptSeq = M.DeptSeq         
     LEFT OUTER JOIN (SELECT DeptSeq,SUM(ISNULL(OutQty,0)) AS Qty ,SUM(ISNULL(CurAmt,0)) AS CurAmt  --�����������: �հ�      
                  FROM #TMPCloseData         
                  WHERE LEFT(WorkDate,6) = @LastYM      
                  GROUP BY DeptSeq ) AS PrvAcc ON PrvAcc.DeptSeq = M.DeptSeq   
     LEFT OUTER JOIN #TMPActPlan  AS PL ON PL.DeptSeq = M.DeptSeq    --�����ǥ
     ORDER BY M.DispSeq    
	
 RETURN
