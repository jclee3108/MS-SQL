 
IF OBJECT_ID('hencom_SPUMatItemDelvInListQuery') IS NOT NULL   
    DROP PROC hencom_SPUMatItemDelvInListQuery  
GO  
  
-- v2017.02.26
  
-- �����԰���Ȳ-��ȸ by ����õ   
CREATE PROC hencom_SPUMatItemDelvInListQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @docHandle  INT,  
            -- ��ȸ����   
            @StdDate    NCHAR(8), 
            @DeptSeq    INT, 
            @ItemName   NVARCHAR(100)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdDate     = ISNULL( StdDate, '' ),  
           @DeptSeq     = ISNULL( DeptSeq, 0 ), 
           @ItemName    = ISNULL( ItemName, '')
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
              StdDate    NCHAR(8),
              DeptSeq    INT, 
              ItemName   NVARCHAR(100)
           )    
    
    -- ��ǰ�� 
    SELECT D.ItemName, 
           B.ItemSeq, 
           E.UnitName, 
           B.UnitSeq, 
           B.StdUnitQty AS Qty, 
           ISNULL(C.PuPrice,0) AS Price, -- ���Դܰ�
           --ISNULL(C.PuAmt,0) AS CurAmt,
           --ISNULL(C.PuVat,0) AS CurVAT,
           ISNULL(C.PuAmt,0) + ISNULL(C.PuVat,0) AS Amt, -- ���Աݾװ�
           F.CustName, 
           '��ǰ��' AS DelvTypeName, 
           A.DeptSeq, 
           1 AS Sort, 
           1 AS MainSort
      INTO #Result  
      FROM _TPUDelv                         AS A 
      JOIN _TPUDelvItem                     AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
      LEFT OUTER JOIN hencom_TPUDelvItemAdd AS C ON ( C.CompanySeq = @CompanySeq AND C.DelvSeq = B.DelvSeq AND C.DelvSerl = B.DelvSerl ) 
      LEFT OUTER JOIN _TDAItem              AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit              AS E ON ( E.CompanySeq = @CompanySeq AND E.UnitSeq = B.UnitSeq ) 
      LEFT OUTER JOIN _TDACust              AS F ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = A.CustSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.DelvDate = @StdDate 
       AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq ) 
       AND ( @ItemName = '' OR D.ItemName LIKE @ItemName + '%' ) 
    
    UNION ALL     

    -- ������ۺ� 
    SELECT D.ItemName, 
           B.ItemSeq, 
           E.UnitName, 
           B.UnitSeq, 
           B.StdUnitQty AS Qty, 
           ISNULL(C.DeliChargePrice,0) AS Price, -- ���Դܰ�
           --ISNULL(C.PuAmt,0) AS CurAmt,
           --ISNULL(C.PuVat,0) AS CurVAT,
           ISNULL(C.DeliChargeAmt,0) + ISNULL(C.DeliChargeVat,0) AS Amt, -- ���Աݾװ�
           F.CustName, 
           '������ۺ�' AS DelvTypeName, 
           A.DeptSeq, 
           2 AS Sort, 
           1 AS MainSort
      FROM _TPUDelv                         AS A 
      JOIN _TPUDelvItem                     AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
      LEFT OUTER JOIN hencom_TPUDelvItemAdd AS C ON ( C.CompanySeq = @CompanySeq AND C.DelvSeq = B.DelvSeq AND C.DelvSerl = B.DelvSerl ) 
      LEFT OUTER JOIN _TDAItem              AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit              AS E ON ( E.CompanySeq = @CompanySeq AND E.UnitSeq = B.UnitSeq ) 
      LEFT OUTER JOIN _TDACust              AS F ON ( F.CompanySeq = @CompanySeq AND F.CustSeq= C.DeliCustSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.DelvDate = @StdDate 
       AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq ) 
       AND ( @ItemName = '' OR D.ItemName LIKE @ItemName + '%' ) 
       AND ISNULL(C.DeliChargeAmt,0) <> 0 
    
    
    -- �����հ� 
    IF EXISTS (SELECT 1 FROM #Result)
    BEGIN 
        INSERT INTO #Result 
        SELECT A.ItemName, 
               A.ItemSeq, 
               '�����',
               99999999,
               SUM(ISNULL(A.Qty,0)) AS Qty,  
               0 AS Price, 
               SUM(ISNULL(A.Amt,0)) AS Amt, 
               '' AS CustName, 
               '' AS DelvTypeName, 
               MAX(A.DeptSeq) AS DeptSeq, 
               3 AS Sort, 
               1 AS MainSort
          FROM #Result AS A 
         GROUP BY A.ItemName, A.ItemSeq 
    END 
    
    -- ���հ� 
    IF EXISTS (SELECT 1 FROM #Result WHERE Sort IN ( 1, 2 ))
    BEGIN 
        INSERT INTO #Result 
        SELECT '', 
               99999999, 
               '�հ�',
               99999999,
               SUM(ISNULL(A.Qty,0)) AS Qty,  
               0 AS Price, 
               SUM(ISNULL(A.Amt,0)) AS Amt, 
               '' AS CustName, 
               '' AS DelvTypeName, 
               MAX(A.DeptSeq) AS DeptSeq, 
               4 AS Sort, 
               2 AS MainSort
          FROM #Result AS A 
         WHERE A.Sort IN ( 1, 2 ) 
           AND EXISTS (SELECT 1 FROM #Result WHERE A.Sort IN ( 1, 2 ))
    END 
    
    -- ������ȸ
    SELECT A.*, @StdDate AS StdDate, B.DeptName 
      FROM #Result AS A 
      LEFT OUTER JOIN _TDADept AS B ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
     ORDER BY A.MainSort, A.ItemName, A.Sort
    
    RETURN  
    go

exec hencom_SPUMatItemDelvInListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <StdDate>20170226</StdDate>
    <DeptSeq>28</DeptSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1511343,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1032922