IF OBJECT_ID('hencom_SPUDelvItemAnalysisQuery') IS NOT NULL 
    DROP PROC hencom_SPUDelvItemAnalysisQuery
GO 

-- v2017.04.24 

/************************************************************  
  ��  �� - ������-���Ÿ��Ժм�_hencom : ��ȸ  
  �ۼ��� - 20151124  
  �ۼ��� - ������  
 ************************************************************/  
 CREATE PROC dbo.hencom_SPUDelvItemAnalysisQuery                 
  @xmlDocument   NVARCHAR(MAX) ,              
  @xmlFlags      INT  = 0,              
  @ServiceSeq    INT  = 0,              
  @WorkingTag    NVARCHAR(10)= '',                    
  @CompanySeq    INT  = 1,              
  @LanguageSeq   INT  = 1,              
  @UserSeq       INT  = 0,              
  @PgmSeq        INT  = 0           
       
 AS          
    
     DECLARE @docHandle        INT,  
             @YMFrom           NCHAR(8) ,  
             @YMTo             NCHAR(8) ,  
             @UMItemClassLSeq  INT ,  
             @UMItemClassMSeq  INT ,  
             @UMItemClassSSeq  INT ,  
             @DeptSeq          INT ,
             @ItemName         NVARCHAR(200) ,  
             @CustName         NVARCHAR(200) ,  
             @DeliCustName     NVARCHAR(200) ,
             @CompanyNo       NVARCHAR(100) 
    
  EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
   
     SELECT  @DeptSeq          = DeptSeq           ,
             @YMFrom           = YMFrom            ,  
             @YMTo             = YMTo              ,  
             @UMItemClassLSeq  = UMItemClassLSeq   ,  
             @UMItemClassMSeq  = UMItemClassMSeq   ,  
             @UMItemClassSSeq  = UMItemClassSSeq   ,
             @CustName           = CustName,
             @DeliCustName       = DeliCustName,
             @ItemName           = ItemName
  
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
     WITH (  DeptSeq           INT ,   
             YMFrom            NCHAR(8) ,  
             YMTo              NCHAR(8) ,  
             UMItemClassLSeq   INT ,  
             UMItemClassMSeq   INT ,  
             UMItemClassSSeq   INT ,  
             CustName        NVARCHAR(200),
             DeliCustName    NVARCHAR(200),
             ItemName        NVARCHAR(200)
          )
    
  /*0������ ���� ��� ó��*/          
     SET ANSI_WARNINGS OFF          
     SET ARITHIGNORE ON          
     SET ARITHABORT OFF          

/* ���ΰ����� ���ε�Ϲ�ȣ�� �Ѷ��İ� ���ѻ���� ������.
�Ѷ���(1411110002605)�� ǰ���ڻ�з��� �����縸 ��ȸ. 
���ѻ��( )�� ��� ��ȸ.*/

    SELECT @CompanyNo = CompanyNo FROM _TCACompany
    
    SELECT 
           x.CustSeq, 
           x.DeptSeq,
           x.ProdDistrictSeq, 
           x.DeliCustSeq,
           x.SalesCustSeq,
           x.ItemSeq, 
           x.StartDate,
           x.IsStop,
           x.UMPayMethod,
           x.DeliUMPayMethod,
           CASE WHEN (SELECT MAX(StartDate)   
                        FROM hencom_TPUBASEBuyPriceItem   
                       WHERE X.CompanySeq = CompanySeq   
                         AND X.CustSeq = CustSeq 
                         AND X.DeptSeq = DeptSeq   
                         AND X.ProdDistrictSeq = ProdDistrictSeq 
                         AND ISNULL(X.DeliCustSeq, 0) = ISNULL(DeliCustSeq, 0)
                         AND ISNULL(X.SalesCustSeq, 0) = ISNULL(SalesCustSeq, 0)
                         AND X.ItemSeq = ItemSeq) = X.StartDate THEN '99991231'  
           ELSE
           (SELECT CONVERT(NCHAR(8),DATEADD(D, -1, MIN(StartDate)),112) 
              FROM hencom_TPUBASEBuyPriceItem
             WHERE X.CompanySeq = CompanySeq
               AND X.CustSeq = CustSeq 
               AND X.DeptSeq = DeptSeq 
               AND X.ProdDistrictSeq = ProdDistrictSeq 
               AND X.ItemSeq = ItemSeq 
               AND ISNULL(X.DeliCustSeq, 0) = ISNULL(DeliCustSeq, 0)
               AND ISNULL(X.SalesCustSeq, 0) = ISNULL(SalesCustSeq, 0)
               AND X.StartDate < StartDate) END AS EndDate,        -- ����������
           CASE WHEN X.StartDate = (SELECT TOP 1 StartDate 
                                      FROM hencom_TPUBASEBuyPriceItem WITH(NOLOCK)
                                     WHERE CompanySeq = X.CompanySeq
                                       AND ItemSeq = X.ItemSeq
                                       AND CustSeq = X.CustSeq
                                       AND DeptSeq = X.DeptSeq
                                       AND ProdDistrictSeq = X.ProdDistrictSeq
                                       AND ISNULL(DeliCustSeq, 0) = ISNULL(X.DeliCustSeq, 0)
                                       AND ISNULL(SalesCustSeq, 0) = ISNULL(X.SalesCustSeq, 0)
                                     ORDER BY StartDate DESC ) THEN '1' END AS IsLast     -- ��������
      INTO #hencom_TPUBASEBuyPriceItem 
      FROM hencom_TPUBASEBuyPriceItem AS X 
     WHERE X.CompanySeq = @CompanySeq

     SELECT  A.DeptSeq,  
             A.CustSeq,  
             B.ItemSeq,  
             B.UnitSeq,  
             C.ProdDistrictSeq, --����  
             C.DeliCustSeq, --���ó  
             L.ValueSeq          AS ItemClassLSeq,  -- ǰ���з�    
             K.ValueSeq          AS ItemClassMSeq,  -- ǰ���ߺз�  
             IC.UMItemClass      AS ItemClassSSeq, -- ǰ��Һз�    
             BBP.UMPayMethod ,--����ó��������  
             BBP.DeliUMPayMethod , --���ó��������  
             SUM(ISNULL(Qty,0))  AS Qty ,  
             SUM(ISNULL(C.PuAmt,0)) AS PuAmt , --���Աݾ�  
             SUM(ISNULL(C.PuVat,0)) AS PuVat , --���Ժΰ���  
             SUM(ISNULL(C.PuAmt,0)) AS PuTotAmt , --�հ�ݾ�  
             SUM(ISNULL(C.DeliChargeAmt,0)) AS DeliChargeAmt , --��ݺ�  
             SUM(ISNULL(C.DeliChargeVat,0)) AS DeliChargeVat , --��ۺ�ΰ���  
 --            SUM(ISNULL(C.DeliChargeAmt,0)) AS DeliTotAmt --��ۺ��հ�  
 --            SUM(ISNULL(C.DeliChargeAmt,0)) + SUM(ISNULL(C.DeliChargeVat,0)) AS DeliTotAmt --��ۺ��հ�  
             T.PuPrice AS PuPrice, --��ǰ��
             T.DeliChargePrice AS DeliPrice --��ۺ�
     INTO #TMPData  
     FROM _TPUDelv AS A  
     LEFT OUTER JOIN _TPUDelvItem AS B ON B.CompanySeq = A.CompanySeq AND B.DelvSeq = A.DelvSeq  
     LEFT OUTER JOIN hencom_TPUDelvItemAdd AS C ON C.CompanySeq = B.CompanySeq AND C.DelvSeq = B.DelvSeq AND C.DelvSerl = B.DelvSerl  
     LEFT OUTER JOIN _TDAItemClass  AS IC WITH(NOLOCK) ON IC.CompanySeq = B.CompanySeq   
      AND IC.ItemSeq = B.ItemSeq   
                                           AND IC.UMajorItemClass IN (2001,2004)  
     LEFT OUTER JOIN _TDAUMinor  AS H WITH(NOLOCK) ON H.CompanySeq = IC.CompanySeq  
                               AND H.MajorSeq = LEFT( IC.UMItemClass, 4 )   
                                                 AND H.MinorSeq = IC.UMItemClass  
     LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON K.CompanySeq = H.CompanySeq   
                                                     AND K.MajorSeq IN (2001,2004)   
                                               AND K.MinorSeq = H.MinorSeq  
                                                     AND K.Serl IN (1001,2001)  
     LEFT OUTER JOIN _TDAUMinorValue AS L WITH(NOLOCK) ON L.CompanySeq  = K.CompanySeq  
                                                     AND L.MajorSeq IN (2002,2005)   
                                                     AND L.MinorSeq = K.ValueSeq  
                                                     AND L.Serl = 2001   
     LEFT OUTER JOIN hencom_TPUDelvItemAdd AS T ON ( T.CompanySeq = @CompanySeq AND T.DelvSeq = B.DelvSeq AND T.DelvSerl = B.DelvSerl )
     LEFT OUTER JOIN #hencom_TPUBASEBuyPriceItem AS BBP ON BBP.CustSeq = A.CustSeq    
                                                       AND BBP.DeptSeq = A.DeptSeq    
                                                       AND BBP.ProdDistrictSeq = C.ProdDistrictSeq    
                                                       AND ISNULL(BBP.DeliCustSeq, 0) = ISNULL(C.DeliCustSeq, 0)    
                                                       AND ISNULL(BBP.SalesCustSeq, 0) = ISNULL(C.SalesCustSeq, 0)    
                                                       AND BBP.ItemSeq = B.ItemSeq    
                                                       AND (A.DelvDate BETWEEN BBP.StartDate AND BBP.EndDate)   
     LEFT OUTER JOIN _TDACust AS CT ON CT.CompanySeq = @CompanySeq AND CT.CustSeq = A.CustSeq
     LEFT OUTER JOIN _TDACust AS DLCust ON DLCust.CompanySeq = @CompanySeq AND DLCust.CustSeq = C.DeliCustSeq
     LEFT OUTER JOIN _TDAItem AS I ON I.CompanySeq = @CompanySeq AND I.ItemSeq = B.ItemSeq
     WHERE A.CompanySeq = @CompanySeq   
     AND (@UMItemClassLSeq = 0 OR L.ValueSeq = @UMItemClassLSeq )  
     AND (@UMItemClassMSeq = 0 OR K.ValueSeq  = @UMItemClassMSeq )   
     AND (@UMItemClassSSeq = 0 OR IC.UMItemClass  = @UMItemClassSSeq )        
     AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq   )        
 --    AND (@ItemSeq = 0 OR B.ItemSeq  = @ItemSeq  )      
     AND (@CustName = '' OR CT.CustName LIKE @CustName + '%' )  
     AND (@DeliCustName = '' OR DLCust.CustName LIKE @DeliCustName + '%' )  
     AND (@ItemName = '' OR I.ItemName LIKE @ItemName + '%' )    
     AND A.DelvDate BETWEEN CASE WHEN @YMFrom = '' THEN A.DelvDate ELSE @YMFrom END   
                                 AND CASE WHEN @YMTo = '' THEN A.DelvDate ELSE @YMTo END  
     AND ((@CompanyNo = '1411110002605' AND I.AssetSeq = 6) OR @CompanyNo <> '1411110002605') --�Ѷ����� ǰ���ڻ�з�: �����縸 ��ȸ
     GROUP BY A.DeptSeq,A.CustSeq,B.ItemSeq,B.UnitSeq,C.ProdDistrictSeq, C.DeliCustSeq,L.ValueSeq , K.ValueSeq ,IC.UMItemClass ,BBP.UMPayMethod, BBP.DeliUMPayMethod ,T.PuPrice ,T.DeliChargePrice     
   
   
 --  select * from #TMPData return
     SELECT  0 AS Sort,  
             M.DeptSeq,  
             (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq) AS DeptName ,  
             M.CustSeq,  
             C.CustName AS CustName ,  
             M.ItemSeq,  
             I.ItemName AS ItemName,  
             I.ItemNo AS ItemNo ,  
             M.UnitSeq,  
             (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = M.UnitSeq ) AS UnitName ,  
             M.ProdDistrictSeq, --����  
             (SELECT ProdDistirct FROM hencom_TPUPurchaseArea WHERE CompanySeq = @CompanySeq AND ProdDistrictSeq = M.ProdDistrictSeq) AS Location , --����
			 M.DeliCustSeq, --���ó  
  (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = M.DeliCustSeq ) AS DeliCustName , --���ó��              
             M.ItemClassLSeq,  -- ǰ���з�    
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = M.ItemClassLSeq ) AS UMItemClassLName ,  
             M.ItemClassMSeq,  -- ǰ���ߺз�  
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = M.ItemClassMSeq ) AS UMItemClassMName ,  
             M.ItemClassSSeq, -- ǰ��Һз�    
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = M.ItemClassSSeq ) AS UMItemClassSName ,  
             M.UMPayMethod ,--����ó��������  
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = M.UMPayMethod ) AS UMPayMethodName , --����ó��������  
             M.DeliUMPayMethod,  
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = M.DeliUMPayMethod ) AS DeliUMPayMethodName ,--��ۻ��������  
             M.Qty ,  
             M.PuAmt , --���Աݾ�  
             M.PuVat , --���Ժΰ���  
             M.PuTotAmt , --�հ�ݾ�  
             M.PuPrice   AS PuPrice, --��ǰ��
             M.DeliPrice AS DeliPrice , --��ۺ� 
             ISNULL(M.PuPrice,0) + ISNULL(M.DeliPrice,0)     AS TotPrice, --�ܰ���(��ǰ��+��ۺ�)
             M.DeliChargeAmt             AS DeliTotAmt , --��ۺ��հ�(�ΰ�������)
             M.PuAmt + M.DeliChargeAmt   AS TotAmt --�հ�ݾ�  
     INTO #TMPRowData  
     FROM #TMPData AS M  
     LEFT OUTER JOIN _TDACust AS C ON C.CompanySeq = @CompanySeq AND C.CustSeq = M.CustSeq  
     LEFT OUTER JOIN _TDAItem AS I ON I.CompanySeq = @CompanySeq AND I.ItemSeq = M.ItemSeq  
     ORDER BY M.DeptSeq  
   
     SELECT *   
     INTO #TMPResult
     FROM #TMPRowData  
     
     UNION ALL  
     
     SELECT  1 AS Sort,  
             M.DeptSeq,  
              (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq) AS DeptName ,  
             0 AS CustSeq,  
             '' AS CustName ,  
             0 AS ItemSeq,  
             '' AS ItemName,  
             '' AS ItemNo ,  
             0 AS UnitSeq,  
             '' AS UnitName ,  
             0 AS ProdDistrictSeq, --����  
             '' AS Location, --����  
             0 AS DeliCustSeq, --���ó  
             '' AS DeliCustName, --���ó��              
             0 AS ItemClassLSeq,  -- ǰ���з�    
             '�Ұ�' AS UMItemClassLName ,  
             0 AS ItemClassMSeq,  -- ǰ���ߺз�  
            '' AS UMItemClassMName ,  
             0 AS ItemClassSSeq, -- ǰ��Һз�    
             '' AS UMItemClassSName ,  
             0 AS UMPayMethod ,--����ó��������  
             '' AS UMPayMethodName , --����ó��������  
             0 AS DeliUMPayMethod,  
            '' AS DeliUMPayMethodName ,--��ۻ��������  
             SUM(ISNULL(M.Qty,0))        AS Qty ,  
             SUM(ISNULL(M.PuAmt,0))      AS PuAmt, --���Աݾ�  
             SUM(ISNULL(M.PuVat,0))      AS PuVat, --���Ժΰ���  
             SUM(ISNULL(M.PuTotAmt,0))   AS PuTotAmt , --�հ�ݾ�  
             SUM(ISNULL(M.PuPrice,0))    AS PuPrice, --��ǰ��
             SUM(ISNULL(M.DeliPrice,0))  AS DeliPrice , --��ۺ� 
             SUM(M.TotPrice)               AS TotPrice, --�ܰ���(��ǰ��+��ۺ�)
             SUM(ISNULL(M.DeliTotAmt,0)) AS DeliTotAmt , --��ۺ��հ�(�ΰ�������) 
             SUM(ISNULL(M.TotAmt,0))     AS TotAmt --�հ�ݾ� from #TMPRowData  
     FROM #TMPRowData AS M  
     GROUP BY M.DeptSeq
   
     SELECT * FROM #TMPResult  
     ORDER BY DeptSeq,Sort  

RETURN
go
exec hencom_SPUDelvItemAnalysisQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <YMFrom>20170301</YMFrom>
    <YMTo>20170424</YMTo>
    <DeptSeq>28</DeptSeq>
    <ItemName />
    <CustName />
    <UMItemClassLSeq />
    <UMItemClassMSeq />
    <UMItemClassSSeq>2004005</UMItemClassSSeq>
    <DeliCustName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033340,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027619