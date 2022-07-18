  
IF OBJECT_ID('yw_SPDEjectSubItemRateListQuery') IS NOT NULL   
    DROP PROC yw_SPDEjectSubItemRateListQuery  
GO  
  
-- v2013.08.27  
  
-- ���������������_YW(��ȸ) by����õ   
CREATE PROC yw_SPDEjectSubItemRateListQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    DECLARE @docHandle  INT,  
            -- ��ȸ����   
            @MatItemName    NVARCHAR(200), 
            @ItemNo         NVARCHAR(100), 
            @WorkOrderNo    NVARCHAR(100), 
            @ItemName       NVARCHAR(200), 
            @ToolNo         NVARCHAR(100), 
            @WorkCenterName NVARCHAR(200), 
            @DeptSeq        INT, 
            @WorkDateFr     NVARCHAR(8), 
            @WorkDateTo     NVARCHAR(8), 
            @GetDate        NVARCHAR(8), 
            @QueryKind      INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
      
    SELECT @MatItemName    = ISNULL(MatItemName,''), 
           @ItemNo         = ISNULL(ItemNo,''),
           @WorkOrderNo    = ISNULL(WorkOrderNo,''), 
           @ItemName       = ISNULL(ItemName,''), 
           @ToolNo         = ISNULL(ToolNo,''), 
           @WorkCenterName = ISNULL(WorkCenterName,''), 
           @DeptSeq        = ISNULL(DeptSeq,0), 
           @WorkDateFr     = ISNULL(WorkDateFr,''), 
           @WorkDateTo     = ISNULL(WorkDateTo,''), 
           @GetDate        = ISNULL(GetDate,''), 
           @QueryKind      = ISNULL(QueryKind,0)
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            MatItemName    NVARCHAR(200),
            ItemNo         NVARCHAR(100),
            WorkOrderNo    NVARCHAR(100),
            ItemName       NVARCHAR(200),
            ToolNo         NVARCHAR(100),
            WorkCenterName NVARCHAR(200),
            DeptSeq        INT, 
            WorkDateFr     NVARCHAR(8), 
            WorkDateTo     NVARCHAR(8), 
            GetDate        NVARCHAR(8),
            QueryKind      INT
           ) 
    
    SELECT @GetDate = CONVERT(NVARCHAR(8),GETDATE(),112)
    
    -- ������ȸ 
    SELECT A.WorkReportSeq, 
           D.WorkCenterName, 
           A.WorkCenterSeq, 
           B.WorkOrderNo, 
           B.WorkCond2 AS ToolNo, 
           C.ItemName, 
           C.ItemNo, 
           I.UnitName, 
           A.GoodItemSeq AS ItemSeq, 
           L.Price, 
           CONVERT(DECIMAL(19,0),ISNULL(A.OKQty,0)) AS OKQty, 
           CONVERT(DECIMAL(19,0),ISNULL(A.BadQty,0)) AS BadQty, 
           CONVERT(DECIMAL(19,0),ISNULL(A.ProdQty,0)) AS ProdQty, 
           F.ItemName AS MatItemName, 
           F.ItemSeq AS MatItemSeq,  
           CONVERT(DECIMAL(19,0),ISNULL(G.PurgingQty,0)) AS PurgingQty, -- ��¡��
           J.ToolSeq, 
           ISNULL(K.MngValText,0) AS MngValText, -- ���������� ���� �߷� 
           CONVERT(DECIMAL(19,0),ISNULL(A.ProdQty,0) * ISNULL(K.MngValText,0)) AS TheoryOutQty, -- �̷к��ⷮ
           CONVERT(DECIMAL(19,0),ISNULL(E.Qty,0)) AS LiveOutQty, -- �������ⷮ 
           CONVERT(DECIMAL(19,0),ISNULL(A.OKQty,0) * ISNULL(K.MngValText,0)) AS OKInQty, -- ��ǰ���Է� 
           CONVERT(DECIMAL(19,0),ISNULL(A.BadQty,0) * ISNULL(K.MngValText,0)) AS BadInQty, -- �ҷ����Է� 
           CONVERT(DECIMAL(19,0),ISNULL(A.OKQty,0) * ISNULL(K.MngValText,0) + 
                                 ISNULL(A.BadQty,0) * ISNULL(K.MngValText,0) + 
                                 ISNULL(G.PurgingQty,0)
                   ) AS TotOutQty, -- �����Է�(��ǰ���Է�+�ҷ����Է�+��¡��) 
           CONVERT(DECIMAL(19,2),CASE WHEN ISNULL(A.OKQty,0) * ISNULL(K.MngValText,0) + 
                                           ISNULL(A.BadQty,0) * ISNULL(K.MngValText,0) + 
                                           ISNULL(G.PurgingQty,0) = 0 
                                      THEN 0 
                                      ELSE ISNULL(A.OKQty,0) * ISNULL(K.MngValText,0) / 
                                           (ISNULL(A.OKQty,0) * ISNULL(K.MngValText,0) + ISNULL(A.BadQty,0) * ISNULL(K.MngValText,0) + ISNULL(G.PurgingQty,0)) * 100 
                                      END
                  ) AS OKInPercent, -- ��ǰ������ 
           CONVERT(DECIMAL(19,2),CASE WHEN ISNULL(A.OKQty,0) * ISNULL(K.MngValText,0) + ISNULL(A.BadQty,0) * ISNULL(K.MngValText,0) + ISNULL(G.PurgingQty,0) = 0 
                                      THEN 0 
                                      ELSE ISNULL(A.BadQty,0) * ISNULL(K.MngValText,0) / 
                                           (ISNULL(A.OKQty,0) * ISNULL(K.MngValText,0) + ISNULL(A.BadQty,0) * ISNULL(K.MngValText,0) + ISNULL(G.PurgingQty,0)) * 100 
                                      END
                  ) AS BadInPercent, -- �ҷ������� 
           CONVERT(DECIMAL(19,2),CASE WHEN (ISNULL(A.ProdQty,0) * ISNULL(K.MngValText,0)) = 0 
                                      THEN 0
                                      ELSE (ISNULL(E.Qty,0) - (ISNULL(A.ProdQty,0) * ISNULL(K.MngValText,0)))/ 
                                           (ISNULL(A.ProdQty,0) * ISNULL(K.MngValText,0)) * 100 
                                      END
                  ) AS OverInPercent, -- �������� 
           ISNULL(E.Qty,0) * ISNULL(L.Price, 0) AS LiveOutAmt, -- ��������ݾ�
           ISNULL(A.OKQty,0) * ISNULL(K.MngValText,0) * ISNULL(L.Price, 0) AS OKInAmt, -- ��ǰ���Աݾ� 
           ISNULL(A.BadQty,0) * ISNULL(K.MngValText,0) * ISNULL(L.Price, 0) AS BadInAmt, -- �ҷ����Աݾ� 
           ISNULL(G.PurgingQty,0) * ISNULL(K.MngValText,0) * ISNULL(L.Price, 0) AS PurgingAmt, -- ��¡�ݾ� 
           (ISNULL(E.Qty,0) - ISNULL(A.ProdQty,0) * ISNULL(K.MngValText,0)) * ISNULL(L.Price, 0) AS OverInAmt, -- �����Աݾ�
           H.DeptName, 
           A.DeptSeq
      INTO #Temp      
      FROM _TPDSFCWorkReport AS A WITH(NOLOCK)   
      LEFT OUTER JOIN _TPDSFCWorkOrder     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkOrderSeq = A.WorkOrderSeq AND B.WorkOrderSerl = A.WorkOrderSerl ) 
      LEFT OUTER JOIN _TDAItem             AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.GoodItemSeq ) 
      LEFT OUTER JOIN _TPDBaseWorkCenter   AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.WorkCenterSeq = A.WorkCenterSeq ) 
      LEFT OUTER JOIN _TPDSFCMatInput      AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.WorkReportSeq = A.WorkReportSeq ) 
      LEFT OUTER JOIN _TDAItem             AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq = E.MatItemSeq ) 
      LEFT OUTER JOIN YW_TPDSFCMatinput    AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.WorkReportSeq = E.WorkReportSeq AND G.ItemSerl = E.ItemSerl ) 
      LEFT OUTER JOIN _TDADept             AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAUnit             AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.UnitSeq = C.UnitSeq ) 
      LEFT OUTER JOIN _TPDTool             AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.ToolNo = B.WorkCond2 ) 
      LEFT OUTER JOIN _TPDToolUserDefine   AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.ToolSeq = J.ToolSeq AND MngSerl = 1000003 ) 
      LEFT OUTER JOIN _TPUBASEBuyPriceItem AS L WITH(NOLOCK) ON ( L.CompanySeq = @CompanySeq AND E.MatItemSeq = L.ItemSeq AND @GetDate BETWEEN L.StartDate AND L.EndDate AND IsPrice = '1' ) 
    
     WHERE A.CompanySeq = @CompanySeq 
       AND (@MatItemName = '' OR F.ItemName LIKE @MatItemName + '%') 
       AND A.WorkDate BETWEEN @WorkDateFr AND @WorkDateTo 
       AND (@ItemNo = '' OR C.ItemNo LIKE @ItemNo + '%') 
       AND (@WorkOrderNo = '' OR B.WorkOrderNo LIKE @WorkOrderNo + '%') 
       AND (@ItemName = '' OR C.ItemName LIKE @ItemName + '%') 
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq) 
       AND (@ToolNo = '' OR B.WorkCond2 LIKE @ToolNo + '%') 
       AND (@WorkCenterName = '' OR D.WorkCenterName LIKE @WorkCenterName + '%') 
    
    IF @QueryKind = 1008438001
    BEGIN
        SELECT * FROM #Temp
    END
    
    ELSE
    BEGIN
        SELECT MAX(MatItemName) AS MatItemName, 
               MatItemSeq, 
               SUM(PurgingQty) AS PurgingQty, 
               MAX(ToolSeq) AS ToolSeq, 
               SUM(TheoryOutQty) AS TheoryOutQty, 
               SUM(LiveOutQty) AS LiveOutQty, 
               SUM(OKInQty) AS OKInQty, 
               SUM(BadInQty) AS BadInQty, 
               SUM(TotOutQty) AS TotOutQty, 
               CASE WHEN SUM(TotOutQty) = 0 THEN 0 ELSE SUM(OKInQty)/ SUM(TotOutQty) * 100 END AS OKInPercent, 
               CASE WHEN SUM(TotOutQty) = 0 THEN 0 ELSE SUM(BadInQty)/ SUM(TotOutQty) * 100 END AS BadInPercent, 
               CASE WHEN SUM(TheoryOutQty) = 0 THEN 0 ELSE (SUM(LiveOutQty) - SUM(TheoryOutQty)) / SUM(TheoryOutQty) * 100 END AS OverInPercent, 
               SUM(LiveOutQty) * MAX(Price) AS LiveOutAmt, 
               SUM(OKInQty) * MAX(Price) AS OKInAmt, 
               SUM(BadInQty) * MAX(Price) AS BadInAmt, 
               SUM(PurgingQty) * MAX(Price) AS PurgingAmt, 
               (SUM(LiveOutQty) - SUM(TheoryOutQty)) * MAX(Price) AS OverInAmt, 
               MAX(DeptName) AS DeptName, 
               MAX(DeptSeq) AS DeptSeq 
        
          FROM #Temp
         GROUP BY MatItemSeq
    END
     
    RETURN  
    
GO
exec yw_SPDEjectSubItemRateListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <DeptSeq />
    <WorkDateFr>20130801</WorkDateFr>
    <WorkDateTo>20130827</WorkDateTo>
    <WorkOrderNo />
    <ItemNo />
    <ItemName />
    <WorkCenterName />
    <MatItemName />
    <ToolNo />
    <QueryKind>1008438001</QueryKind>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017379,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014872

--select (11628-1942500) / 1942500 * 100