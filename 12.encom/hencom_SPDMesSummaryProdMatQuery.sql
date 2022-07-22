IF OBJECT_ID('hencom_SPDMesSummaryProdMatQuery') IS NOT NULL 
    DROP PROC hencom_SPDMesSummaryProdMatQuery
GO 

-- v2017.03.15 
/************************************************************
  ��  �� - ������-����MES�ڷ�Ȯ��_hencom : ���곻��
  �ۼ��� - 20151111
  �ۼ��� - ������
 ************************************************************/
  CREATE PROC dbo.hencom_SPDMesSummaryProdMatQuery                
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
       @ExpShipSeq INT  
  
  EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
   SELECT  @ExpShipSeq = ExpShipSeq  
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
    WITH (ExpShipSeq  INT )
  
    -- ���ҵ� ������ ������ �ʵ��� �Ѵ�.
    SELECT DISTINCT LEFT(A.MesKey,19) AS MesKey
      INTO #PartiontMeskey
      FROM hencom_TIFProdWorkReportClose AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEN(A.MesKey) > 19 
    

     CREATE TABLE #TmpTitle         
     (             
         ColIDX       INT IDENTITY(0,1)  ,          
         Title        NVARCHAR(100)   ,    
         TitleSeq     NVARCHAR(100)       
                  
     )          
     CREATE TABLE #TmpTitle_Tmp         
     (                
         Title        NVARCHAR(100)      ,          
         TitleSeq     NVARCHAR(100)      ,        
         Sort         INT      
     )          
     
           
     INSERT #TmpTitle_Tmp(Title,TitleSeq,Sort)      
               
     SELECT D.MatItemName AS Title , D.MatItemName AS TitleSeq,       
             (SELECT MAX(MinorSort) FROM _TDAUMinor WHERE  CompanySeq = @CompanySeq   
                                                         AND MinorName =  D.MatItemName   
                                                         AND MajorSeq = 1011629  ) AS MinorSort  
     FROM hencom_TIFProdWorkReportClose AS M   
     JOIN hencom_TIFProdMatInputClose AS D ON D.companyseq = M.companyseq AND D.meskey = M.meskey  
     WHERE M.ExpShipSeq  = @ExpShipSeq 
     AND M.CompanySeq = @CompanySeq  
     AND NOT EXISTS (SELECT 1 FROM #PartiontMeskey WHERE MesKey = M.MesKey)
     GROUP BY D.MatItemName  
       
     INSERT #TmpTitle(Title,TitleSeq)      
     SELECT Title,TitleSeq     
     FROM #TmpTitle_Tmp      
     ORDER BY Sort ,TitleSeq    
           
     /*��� Ÿ��Ʋ ��ȸ*/
     SELECT * FROM #TmpTitle   
     
     SELECT IDENTITY(int, 0,1) AS RowIDX,
            M.BPNo,
            M.GoodItemSeq
     INTO #TMPRowData
     FROM hencom_TIFProdWorkReportClose AS M   
 --    JOIN hencom_TIFProdMatInputClose AS D ON D.companyseq = M.companyseq AND D.meskey = M.meskey  
     WHERE M.ExpShipSeq  = @ExpShipSeq 
     AND M.CompanySeq = @CompanySeq 
     AND NOT EXISTS (SELECT 1 FROM #PartiontMeskey WHERE MesKey = M.MesKey)
     GROUP BY M.BPNo,M.GoodItemSeq
     
  /*���������� ��ȸ*/
     SELECT M.RowIDX,
            M.BPNo,
            M.GoodItemSeq ,
            (SELECT ItemName FROM _TDAItem WHERE CompanySeq = @CompanySeq AND ItemSeq = M.GoodItemSeq) AS ItemName
     FROM #TMPRowData AS M
     ORDER BY M.RowIDX
     
  /*���������� ��ȸ*/
 SELECT R.RowIDX,T.ColIDX,A.Qty AS MatQty
 FROM (
     SELECT M.BPNo,
            M.GoodItemSeq,
            D.MatItemName,
            SUM(ISNULL(D.Qty,0)) AS Qty
     FROM hencom_TIFProdWorkReportClose AS M   
     JOIN hencom_TIFProdMatInputClose AS D ON D.companyseq = M.companyseq AND D.meskey = M.meskey  
     WHERE M.ExpShipSeq  = @ExpShipSeq 
     AND M.CompanySeq = @CompanySeq 
     AND NOT EXISTS (SELECT 1 FROM #PartiontMeskey WHERE MesKey = M.MesKey)
     GROUP BY M.BPNo,M.GoodItemSeq,D.MatItemName
     ) AS A
 JOIN #TmpTitle AS T ON T.TitleSeq = A.MatItemName
 JOIN #TMPRowData AS R ON R.BPNo = A.BPNo AND R.GoodItemSeq = A.GoodItemSeq
ORDER BY R.RowIDX,T.ColIDX  
     
RETURN
