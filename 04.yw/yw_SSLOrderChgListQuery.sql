
IF OBJECT_ID('yw_SSLOrderChgListQuery') IS NOT NULL
    DROP PROC yw_SSLOrderChgListQuery
GO

-- v2013.07.11

-- ���ֺ����̷�_YM(��ȸ) by ����õ
CREATE PROC yw_SSLOrderChgListQuery                
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10) = '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
    DECLARE @docHandle       INT, 
            @EmpSeq          INT, 
            @Orderstatus     INT, 
            @ItemName        NVARCHAR(200), 
            @OrderItemNo     NVARCHAR(200), 
            @ExportKind      INT, 
            @ExportKindName  NVARCHAR(100), 
            @ItemNo          NVARCHAR(100), 
            @OrderNo         NVARCHAR(20), 
            @RevDateTo       NCHAR(8), 
            @CustName        NVARCHAR(100), 
            @OrderDateFr     NCHAR(8), 
            @OrderDateTo     NCHAR(8), 
            @DeptSeq         INT, 
            @RevDateFr       NCHAR(8) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @EmpSeq          = EmpSeq, 
           @Orderstatus     = Orderstatus, 
           @ItemName        = ItemName, 
           @OrderItemNo     = OrderItemNo, 
           @ExportKind      = ExportKind, 
           @ExPortKindName  = ExportKindName,
           @ItemNo          = ItemNo, 
           @OrderNo         = OrderNo, 
           @RevDateTo       = RevDateTo, 
           @CustName        = CustName, 
           @OrderDateFr     = OrderDateFr, 
           @OrderDateTo     = OrderDateTo, 
           @DeptSeq         = DeptSeq, 
           @RevDateFr       = RevDateFr        
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (
            EmpSeq           INT, 
            Orderstatus      INT, 
            ItemName         NVARCHAR(200), 
            OrderItemNo      NVARCHAR(200), 
            ExportKind       INT, 
            ExportKindName   NVARCHAR(100), 
            ItemNo           NVARCHAR(100), 
            OrderNo          NVARCHAR(20), 
            RevDateTo        NCHAR(8), 
            CustName         NVARCHAR(100), 
            OrderDateFr      NCHAR(8), 
            OrderDateTo      NCHAR(8), 
            DeptSeq          INT, 
            RevDateFr        NCHAR(8) 
           )

    IF @OrderDateFr = '' SELECT @OrderDateFr = '10000101'
    IF @OrderDateTo = '' SELECT @OrderDateTo = '99991231'

    -- �������� Table    
    CREATE TABLE #Tmp_OrderItemSLProg(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT, OrderSubSerl INT, CompleteCHECK INT, SMProgressType INT NULL, IsStop NCHAR(1), SMConfirm INT)    
    
    ---------------------- ������ ���� ����    
    DECLARE @SMOrgSortSeq INT, @OrgStdDate NCHAR(8)    
    
    IF @OrderDateTo = '99991231'    
        SELECT @OrgStdDate = CONVERT(NCHAR(8), GETDATE(), 112)    
    ELSE 
        SELECT @OrgStdDate = @OrderDateTo    
    
    SELECT @SMOrgSortSeq = 0    
    SELECT @SMOrgSortSeq = SMOrgSortSeq    
      FROM _TCOMOrgLinkMng 
     WHERE CompanySeq = @CompanySeq 
       AND PgmSeq = @PgmSeq 
    
    DECLARE @DeptTable Table    
        ( DeptSeq INT)    
    
    INSERT @DeptTable    
    SELECT DISTINCT DeptSeq    
      FROM dbo._fnOrgDept(@CompanySeq, @SMOrgSortSeq, @DeptSeq, @OrgStdDate)    

    ---------------------- ������ ���� ����    
      
    INSERT INTO #Tmp_OrderItemSLProg(OrderSeq, OrderSerl, OrderSubSerl, CompleteCHECK, IsStop)    
    SELECT A.OrderSeq, B.OrderSerl, B.OrderSubSerl, -1, B.IsStop    
      FROM _TSLOrder     AS A WITH(NOLOCK)     
      JOIN _TSLOrderItem AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.OrderSeq = B.OrderSeq ) 
      LEFT OUTER JOIN _TDASMinorValue AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND A.SMExpKind = C.MinorSeq AND C.Serl = 1001 ) 
    
     WHERE A.CompanySeq = @CompanySeq      
       AND A.OrderDate BETWEEN @RevDateFr AND @RevDateTo
       AND (@OrderNo = '' OR A.OrderNo LIKE @OrderNo + '%')

    ---------------------------------------------------------------------------------------------------------  
    -- ������� ���ϱ� (����)
    ---------------------------------------------------------------------------------------------------------  
      
    EXEC _SCOMProgStatus @CompanySeq, '_TSLOrderItem', 1036001, '#Tmp_OrderItemSLProg',    
                         'OrderSeq', 'OrderSerl', 'OrderSubSerl', '', '', '', '', '',    
                         'CompleteCHECK', 1, 'Qty', 'STDQty', 'CurAmt', 'CurVAT',    
                         'OrderSeq', 'OrderSerl', '', '_TSLOrder' , @PgmSeq      
    
    UPDATE #Tmp_OrderItemSLProg     
       SET SMProgressType = (SELECT CASE WHEN A.IsStop = '1' AND B.MinorSeq = 1037006 THEN 1037007 --�����ߴ�    
                                         WHEN B.MinorSeq = 1037009 THEN 1037009 -- �Ϸ�    
                                         WHEN A.IsStop = '1' THEN 1037005 -- �ߴ�    
                                         ELSE B.MinorSeq END)    
      FROM #Tmp_OrderItemSLProg AS A    
      LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON ( B.MajorSeq = 1037 AND A.CompleteCHECK = B.Minorvalue ) 
    
    -- ����/���ⱸ�� ��ȸ�ϱ� ���ؼ� ���
    CREATE TABLE #ExpKind 
        (
         OrderSeq   INT,
         OrderSerl  INT,
         OrderRev   INT,
         ExportKind INT,
         ItemSeq    INT
        )
        
    INSERT INTO #ExpKind (OrderSeq, OrderSerl, OrderRev, ExportKind,ItemSeq)
    
    SELECT A.OrderSeq, B.OrderSerl, A.OrderRev, CASE WHEN C.ValueText = '1' THEN 8918001 ELSE 8918002 END AS ExportKind, B.ItemSeq
      FROM _TSLOrder AS A
      LEFT OUTER JOIN _TSLOrderItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.OrderSeq = A.OrderSeq ) 
      LEFT OUTER JOIN _TDASMinorValue  AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMExpKind AND C.Serl = 1001 ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.OrderDate BETWEEN @RevDateFr AND @RevDateTo 
    
    UNION ALL
    
    SELECT A.OrderSeq, A.OrderSerl, A.OrderRev, CASE WHEN C.ValueText = '1' THEN 8918001 ELSE 8918002 END AS ExportKind, A.ItemSeq
      FROM _TSLOrderItemRev           AS A 
      LEFT OUTER JOIN _TSLOrderRev    AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.OrderSeq = A.OrderSeq ) 
      LEFT OUTER JOIN _TSLOrder       AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.OrderSeq = A.OrderSeq ) 
      LEFT OUTER JOIN _TDASMinorValue AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.SMExpKind AND C.Serl = 1001 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.OrderRevDate BETWEEN @RevDateFr AND @RevDateTo 

    -- ������ȸ
    
    SELECT CASE WHEN N.ValueText = '1' THEN '����' ELSE '����' END AS ExportKindName, -- ����/���� ���� 
           A.OrderSeq, 
           B.OrderSerl,
           A.OrderRev, -- Amd����
           CASE WHEN A.OrderRevDate = '' THEN A.OrderDate ELSE A.OrderRevDate END AS OrderRevDate, -- ��������
           A.OrderDate, -- ��������
           A.OrderNo, -- ���ֹ�ȣ
           A.PONo,
           D.CustName,
           A.CustSeq,
           E.DeptName,
           A.DeptSeq,
           F.EmpName,
           A.EmpSeq,
           -- �������
           A.Remark, 
           G.ItemClasLName, -- ǰ���з�
           G.ItemClassLSeq, -- ǰ���з��ڵ�
           C.ItemName, 
           B.ItemSeq, 
           C.ItemNo, 
           C.Spec, 
           I.CustItemNo, -- �ŷ�óǰ��
           B.Dummy1   AS OrderItemNo, -- �ֹ�������ȣ
           J.UnitName AS STDUnitName, -- ���ش���
           B.Price, -- �ǸŴܰ�
           O.CustName AS DVPlaceName, -- ��ǰó
           B.DVPlaceSeq, 
           CASE WHEN B.UMEtcOutKind = 0 THEN B.Qty ELSE 0 END AS Qty,
           CASE WHEN R.DiscountPrice <> 0 THEN R.DiscountPrice ELSE B.Price END AS DiscountPrice, -- �ܰ�
           (
            SELECT (Qty - B.Qty) * Price
              FROM _TSLOrderItemRev 
             WHERE CompanySeq = @CompanySeq AND OrderSeq = B.OrderSeq AND OrderSerl = B.OrderSerl AND OrderRev = (B.OrderRev - 1) AND UMEtcOutKind = 0
           ) AS CancleAmt, -- ��ұݾ�
           (CASE WHEN B.UMEtcOutKind = 0 THEN B.Qty ELSE 0 END * 
            CASE WHEN R.DiscountPrice <> 0 THEN B.Price - R.DiscountPrice ELSE B.Price END) AS CurAmt, -- �Ǹűݾ�
           B.CurVAT,
           (CASE WHEN B.UMEtcOutKind = 0 THEN B.Qty ELSE 0 END * 
            CASE WHEN R.DiscountPrice <> 0 THEN R.DiscountPrice ELSE B.Price END) + B.CurVAT AS TotCurAmt, -- �Ǹűݾװ�
           (CASE WHEN B.UMEtcOutKind <> 0 THEN B.Qty ELSE 0 END) AS ExtraQty, -- ������ ����
           
           -- �߰����� �⺻����(HID) --
           I.CustItemName, -- �ŷ�óǰ��
           I.CustItemSpec, -- �ŷ�óǰ��԰�
           S.UnitName, -- �ǸŴ���
           B.ItemPrice, -- ����
           B.CustPrice, -- �Ǹű��ذ�
           T.WHName, -- â��
           B.IsInclusedVAT, -- �ΰ������Կ���
           B.VATRate, -- �ΰ�����
           B.DomAmt, -- ��ȭ�Ǹűݾ�
           B.DomVAT, -- ��ȭ�ΰ���
           B.DomAmt + B.DomVAT AS DomAmtTotal, -- ��ȭ�Ǹűݾװ�
           B.STDQty, -- ���ش�������
           B.DVDate, -- ������
           B.DVTime, -- ��ǰ�ú�
           B.Remark AS SheetRemark, -- Item ���
           U.CCtrName -- Ȱ������                      
      
      FROM _TSLOrderRev AS A WITH(NOLOCK)
      LEFT OUTER JOIN _TSLOrderItemRev  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.OrderSeq = A.OrderSeq AND B.OrderRev = A.OrderRev ) 
      LEFT OUTER JOIN _TSLOrder         AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.OrderSeq = A.OrderSeq ) 
      LEFT OUTER JOIN _TSLOrderItem     AS L WITH(NOLOCK) ON ( L.CompanySeq = @CompanySeq AND L.OrderSeq = B.OrderSeq AND L.OrderSerl = B.OrderSerl ) 
      LEFT OUTER JOIN _TDAItem          AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _fdagetitemclass(@CompanySeq ,0) AS G ON ( G.ItemSeq = B.ItemSeq )
      LEFT OUTER JOIN _TDACust          AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDADept          AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp           AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TSLCustItem      AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.CustSeq = A.CustSeq AND I.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit          AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.UnitSeq = B.STDUnitSeq ) 
      LEFT OUTER JOIN _TSLExpOrder      AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.OrderSeq = H.OrderSeq ) 
      LEFT OUTER JOIN _TDASMinorValue   AS N WITH(NOLOCK) ON ( N.CompanySeq = @CompanySeq AND N.MinorSeq = H.SMExpKind AND N.Serl = 1001 )
      LEFT OUTER JOIN _TDACust          AS O WITH(NOLOCK) ON ( O.CompanySeq = @CompanySeq AND O.CustSeq = B.DVPlaceSeq ) 
      LEFT OUTER JOIN #Tmp_OrderItemSLProg AS P ON ( P.OrderSeq = B.OrderSeq AND P.OrderSerl = B.OrderSerl ) 
      LEFT OUTER JOIN #ExpKind          AS Q ON ( Q.OrderSeq = B.OrderSeq AND Q.OrderSerl = B.OrderSerl AND Q.OrderRev = B.OrderRev ) 
      LEFT OUTER JOIN _TSLCustItemPrice AS R WITH(NOLOCK) ON ( R.CompanySeq = @CompanySeq AND R.CustSeq = A.CustSeq AND R.ItemSeq = B.ItemSeq AND R.SMPriceKind = 8011002 ) 
      LEFT OUTER JOIN _TDAUnit          AS S WITH(NOLOCK) ON ( S.CompanySeq = @CompanySeq AND S.UnitSeq = B.UnitSeq ) 
      LEFT OUTER JOIN _TDAWH            AS T WITH(NOLOCK) ON ( T.CompanySeq = @CompanySeq AND T.WHSeq = B.WHSeq ) 
      LEFT OUTER JOIN _TDACCtr          AS U WITH(NOLOCK) ON ( U.CompanySeq = @CompanySeq AND U.CCtrSeq = B.CCtrSeq ) 
     
     WHERE A.CompanySeq = @CompanySeq
       AND (CASE WHEN A.OrderRevDate = '' THEN A.OrderDate
                                          ELSE A.OrderRevDate
                                          END
           )  BETWEEN @RevDateFr AND @RevDateTo 
       AND (@OrderNo = '' OR A.OrderNo LIKE @OrderNo + '%')
       AND (@CustName = '' OR D.CustName LIKE @CustName + '%')
       AND (@ItemNo = '' OR C.ItemNo LIKE @ItemNo + '%')
       AND (@ItemName = '' OR C.ItemName LIKE @ItemName + '%')
       AND (@OrderItemNo = '' OR B.Dummy1 LIKE @OrderItemNo + '%')
       AND A.OrderDate BETWEEN @OrderDateFr AND @OrderDateTo
       AND (@Orderstatus = 0 OR P.SMProgressType = @Orderstatus)
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)
       AND (@ExportKind = 0 OR Q.ExportKind = @ExportKind)

UNION ALL

    SELECT CASE WHEN N.ValueText = '1' THEN '����' ELSE '����' END AS ExportKindName, -- ����/���� ���� 
           A.OrderSeq, 
           B.OrderSerl,
           A.OrderRev, -- Amd����
           A.OrderRevDate, -- ��������
           A.OrderDate, -- ��������
           A.OrderNo, -- ���ֹ�ȣ
           A.PONo,
           D.CustName,
           A.CustSeq,
           E.DeptName,
           A.DeptSeq,
           F.EmpName,
           A.EmpSeq,
           -- �������
           A.Remark, 
           G.ItemClasLName, -- ǰ���з�
           G.ItemClassLSeq, -- ǰ���з��ڵ�
           C.ItemName, 
           B.ItemSeq, 
           C.ItemNo, 
           C.Spec, 
           I.CustItemNo, -- �ŷ�óǰ��
           B.Dummy1   AS OrderItemNo, -- �ֹ�������ȣ
           J.UnitName AS STDUnitName, -- ���ش���
           B.Price, -- �ǸŴܰ�
           O.CustName AS DVPlaceName, -- ��ǰó
           B.DVPlaceSeq, 
           CASE WHEN B.UMEtcOutKind = 0 THEN B.Qty ELSE 0 END AS Qty,
           CASE WHEN R.DiscountPrice <> 0 THEN R.DiscountPrice ELSE B.Price END AS DiscountPrice, -- �ܰ�
           (
            SELECT (Qty - B.Qty) * Price
              FROM _TSLOrderItemRev AS A 
             WHERE CompanySeq = @CompanySeq
               AND OrderSeq = B.OrderSeq AND OrderSerl = B.OrderSerl AND UMEtcOutKind = 0 
               AND OrderRev = (SELECT MAX(OrderRev) 
                                 FROM _TSLOrderItemRev 
                                WHERE CompanySeq = @CompanySeq AND OrderSeq = A.OrderSeq AND OrderSerl = A.OrderSerl
                              )
           ) AS CancleAmt, -- ��ұݾ�
           (CASE WHEN B.UMEtcOutKind = 0 THEN B.Qty ELSE 0 END * 
            CASE WHEN R.DiscountPrice <> 0 THEN B.Price - R.DiscountPrice ELSE B.Price END) AS CurAmt, -- �Ǹűݾ�
           B.CurVAT,
           (CASE WHEN B.UMEtcOutKind = 0 THEN B.Qty ELSE 0 END * 
            CASE WHEN R.DiscountPrice <> 0 THEN R.DiscountPrice ELSE B.Price END) + B.CurVAT AS TotCurAmt, -- �Ǹűݾװ�
           (CASE WHEN B.UMEtcOutKind <> 0 THEN B.Qty ELSE 0 END) AS ExtraQty, -- ������ ����
          
           -- �߰����� �⺻����(HID) --
           I.CustItemName, -- �ŷ�óǰ��
           I.CustItemSpec, -- �ŷ�óǰ��԰�
           S.UnitName, -- �ǸŴ���
           B.ItemPrice, -- ����
           B.CustPrice, -- �Ǹű��ذ�
           T.WHName, -- â��
           B.IsInclusedVAT, -- �ΰ������Կ���
           B.VATRate, -- �ΰ�����
           B.DomAmt, -- ��ȭ�Ǹűݾ�
           B.DomVAT, -- ��ȭ�ΰ���
           B.DomAmt + B.DomVAT AS DomAmtTotal, -- ��ȭ�Ǹűݾװ�
           B.STDQty, -- ���ش�������
           B.DVDate, -- ������
           B.DVTime, -- ��ǰ�ú�
           B.Remark AS SheetRemark, -- Item ���
           U.CCtrName -- Ȱ������
              
      FROM _TSLOrder AS A
      LEFT OUTER JOIN _TSLOrderItem     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.OrderSeq = A.OrderSeq )
      LEFT OUTER JOIN _TDAItem          AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _fdagetitemclass(@CompanySeq ,0) AS G ON ( G.ItemSeq = B.ItemSeq )
      LEFT OUTER JOIN _TDACust          AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDADept          AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp           AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TSLCustItem      AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.CustSeq = A.CustSeq AND I.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit          AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.UnitSeq = B.STDUnitSeq ) 
      LEFT OUTER JOIN _TSLExpOrder      AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.OrderSeq = A.OrderSeq ) 
      LEFT OUTER JOIN _TDASMinorValue   AS N WITH(NOLOCK) ON ( N.CompanySeq = @CompanySeq AND N.MinorSeq = A.SMExpKind AND N.Serl = 1001 )
      LEFT OUTER JOIN _TDACust          AS O WITH(NOLOCK) ON ( O.CompanySeq = @CompanySeq AND O.CustSeq = B.DVPlaceSeq ) 
      LEFT OUTER JOIN #Tmp_OrderItemSLProg AS P ON ( P.OrderSeq = B.OrderSeq AND P.OrderSerl = B.OrderSerl ) 
      LEFT OUTER JOIN #ExpKind          AS Q ON ( Q.OrderSeq = B.OrderSeq AND Q.OrderSerl = B.OrderSerl AND Q.OrderRev = A.OrderRev ) 
      LEFT OUTER JOIN _TSLCustItemPrice AS R WITH(NOLOCK) ON ( R.CompanySeq = @CompanySeq AND R.CustSeq = A.CustSeq AND R.ItemSeq = B.ItemSeq AND R.SMPriceKind = 8011002 ) 
      LEFT OUTER JOIN _TDAUnit          AS S WITH(NOLOCK) ON ( S.CompanySeq = @CompanySeq AND S.UnitSeq = B.UnitSeq ) 
      LEFT OUTER JOIN _TDAWH            AS T WITH(NOLOCK) ON ( T.CompanySeq = @CompanySeq AND T.WHSeq = B.WHSeq ) 
      LEFT OUTER JOIN _TDACCtr          AS U WITH(NOLOCK) ON ( U.CompanySeq = @CompanySeq AND U.CCtrSeq = B.CCtrSeq ) 
     
     WHERE A.CompanySeq = @CompanySeq
       AND (CASE WHEN A.OrderRevDate = '' THEN A.OrderDate
                                          ELSE A.OrderRevDate
                                          END
           )  BETWEEN @RevDateFr AND @RevDateTo 
       AND (@OrderNo = '' OR A.OrderNo LIKE @OrderNo + '%')
       AND (@CustName = '' OR D.CustName LIKE @CustName + '%')
       AND (@ItemNo = '' OR C.ItemNo LIKE @ItemNo + '%')
       AND (@ItemName = '' OR C.ItemName LIKE @ItemName + '%')
       AND (@OrderItemNo = '' OR B.Dummy1 LIKE @OrderItemNo + '%')
       AND A.OrderDate BETWEEN @OrderDateFr AND @OrderDateTo
       AND (@Orderstatus = 0 OR P.SMProgressType = @Orderstatus)
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)
       AND (@ExportKind = 0 OR Q.ExportKind = @ExportKind)
     ORDER BY A.OrderSeq, B.ItemSeq, A.OrderRev, B.OrderSerl
 
    RETURN
GO
exec yw_SSLOrderChgListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <RevDateFr>99991231</RevDateFr>
    <RevDateTo>99991231</RevDateTo>
    <OrderNo />
    <CustName />
    <ItemNo />
    <ItemName />
    <OrderItemNo></OrderItemNo>
    <OrderDateFr />
    <OrderDateTo />
    <Orderstatus />
    <OrderstatusName />
    <DeptSeq />
    <DeptName />
    <EmpSeq />
    <EmpName />
    <ExportKind />
    <ExportKindName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016510,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014109