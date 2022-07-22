IF OBJECT_ID('hencom_SPDMesProdMatInputQuery') IS NOT NULL 
    DROP PROC hencom_SPDMesProdMatInputQuery
GO 

-- v2017.03.15 
/************************************************************    
   ��  �� - ������-����MES�ڷ�Ȯ��_hencom : ������꺰���系��    
   �ۼ��� - 20160119   
   �ۼ��� - �ڼ���    
  ************************************************************/    
      
  CREATE PROC dbo.hencom_SPDMesProdMatInputQuery  
   @xmlDocument    NVARCHAR(MAX) ,                
   @xmlFlags      INT  = 0,                
   @ServiceSeq     INT  = 0,                
   @WorkingTag     NVARCHAR(10)= '',                      
   @CompanySeq     INT  = 1,                
   @LanguageSeq   INT  = 1,                
   @UserSeq       INT  = 0,                
   @PgmSeq         INT  = 0             
          
  AS            
       
      DECLARE @docHandle      INT,    
              @ExpShipSeq     INT,  
              @DeptSeq        INT,  
              @StdDate        NCHAR(8),  
              @StdDateTo    NCHAR(8)  
        
       EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                 
      
      SELECT  @ExpShipSeq = ISNULL(ExpShipSeq,0) ,  
              @DeptSeq    = ISNULL(DeptSeq,0),    
              @StdDate    = ISNULL(StdDate,''),  
              @StdDateTo = ISNULL(StdDateTo,'')  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
      WITH (ExpShipSeq   INT,  
            DeptSeq      INT,  
            StdDate      NCHAR(8),  
            StdDateTo    NCHAR(8)  
           )    
             
    

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
 --     WHERE (@StdDate = '' OR M.WorkDate = @StdDate)  
     WHERE (@StdDate = '' OR M.WorkDate BETWEEN @StdDate AND @StdDateTo)  
      AND (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)  
      AND (@ExpShipSeq = 0 OR M.ExpShipSeq  = @ExpShipSeq  )   
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
             M.DeptSeq  ,  
             M.BPNo,    
             M.GoodItemSeq  ,  
             M.MesKey,  
             M.ProdQty ,  
          SUBSTRING(M.WorkDate,1,4)+'-'+SUBSTRING(M.WorkDate,5,2)+'-'+SUBSTRING(M.WorkDate,7,2) +' '+SUBSTRING(M.InvPrnTime,1,2) +':'+SUBSTRING(M.InvPrnTime,3,2)+':'+SUBSTRING(M.InvPrnTime,5,2) AS InvPrnTime --�������ð�    
      INTO #TMPRowData    
      FROM hencom_TIFProdWorkReportClose AS M       
  --    JOIN hencom_TIFProdMatInputClose AS D ON D.companyseq = M.companyseq AND D.meskey = M.meskey      
 --     WHERE (@StdDate = '' OR M.WorkDate = @StdDate)  
         WHERE (@StdDate = '' OR M.WorkDate BETWEEN @StdDate AND @StdDateTo)  
      AND (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)  
      AND(@ExpShipSeq = 0 OR M.ExpShipSeq  = @ExpShipSeq  )   
      AND M.CompanySeq = @CompanySeq     
      AND NOT EXISTS (SELECT 1 FROM #PartiontMeskey WHERE MesKey = M.MesKey)
  --    GROUP BY M.BPNo,M.GoodItemSeq    
     ORDER BY M.DeptSeq,M.BPNo  
      
  /*���������� ��ȸ*/    
      SELECT M.RowIDX,    
             (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq) AS DeptName ,  
             M.BPNo,    
             M.GoodItemSeq ,    
             (SELECT ItemName FROM _TDAItem WHERE CompanySeq = @CompanySeq AND ItemSeq = M.GoodItemSeq) AS ItemName ,  
             M.MesKey ,  
             M.ProdQty AS Qty,  
             M.InvPrnTime  
      FROM #TMPRowData AS M    
      ORDER BY M.RowIDX
      
  /*���������� ��ȸ*/    
  SELECT R.RowIDX,T.ColIDX,A.Qty AS MatQty  
  FROM (    
      SELECT M.MesKey,  
             M.BPNo,    
  --            M.GoodItemSeq,    
             D.MatItemName,    
             SUM(ISNULL(D.Qty,0)) AS Qty    
      FROM hencom_TIFProdWorkReportClose AS M       
      JOIN hencom_TIFProdMatInputClose AS D ON D.companyseq = M.companyseq AND D.meskey = M.meskey      
 --     WHERE (@StdDate = '' OR M.WorkDate = @StdDate)  
     WHERE (@StdDate = '' OR M.WorkDate BETWEEN @StdDate AND @StdDateTo)  
      AND (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)  
      AND (@ExpShipSeq = 0 OR M.ExpShipSeq  = @ExpShipSeq )    
      AND M.CompanySeq = @CompanySeq    
      AND NOT EXISTS (SELECT 1 FROM #PartiontMeskey WHERE MesKey = M.MesKey)
      GROUP BY M.MesKey,M.BPNo ,D.MatItemName   
      ) AS A    
  JOIN #TmpTitle AS T ON T.TitleSeq = A.MatItemName    
  JOIN #TMPRowData AS R ON R.MesKey = A.MesKey    
ORDER BY R.RowIDX,T.ColIDX  
          
      
  RETURN
