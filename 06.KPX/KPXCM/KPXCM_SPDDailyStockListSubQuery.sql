  
IF OBJECT_ID('KPXCM_SPDDailyStockListSubQuery') IS NOT NULL   
    DROP PROC KPXCM_SPDDailyStockListSubQuery  
GO  
  
-- v2016.04.20  
  
-- ���������Ȳ-��ȸ by ����õ   
CREATE PROC KPXCM_SPDDailyStockListSubQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) ���
    
    DECLARE @docHandle  INT,  
            -- ��ȸ����   
            @IsItem     NCHAR(1),
            @FactUnit   INT, 
            @StdDate    NCHAR(8), 
            @SrtDate    NCHAR(8)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @IsItem      = ISNULL( IsItem, '0' ),  
           @FactUnit    = ISNULL( FactUnit, 0 ), 
           @StdDate     = ISNULL( StdDate, '' )  
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            IsItem     NCHAR(1),
            FactUnit   INT, 
            StdDate    NCHAR(8) 
           )    
    
    
    SELECT @SrtDate = LEFT(@StdDate,6) + '01'  
    
    -- ���ǰ�� 
    CREATE TABLE #GetInOutItem
    ( 
        ItemSeq     INT, 
        AssetSeq    INT 
    )
    
    -- �����
    CREATE TABLE #GetInOutStock
    (
        WHSeq           INT,
        FunctionWHSeq   INT,
        ItemSeq         INT,
        UnitSeq         INT,
        PrevQty         DECIMAL(19,5),
        InQty           DECIMAL(19,5),
        OutQty          DECIMAL(19,5),
        StockQty        DECIMAL(19,5),
        STDPrevQty      DECIMAL(19,5),
        STDInQty        DECIMAL(19,5),
        STDOutQty       DECIMAL(19,5),
        STDStockQty     DECIMAL(19,5)
    )
    

    -- ��������� 
    CREATE TABLE #TLGInOutStock  
    (  
        InOutType INT,  
        InOutSeq  INT,  
        InOutSerl INT,  
        DataKind  INT,  
        InOutSubSerl  INT,  
        
        InOut INT,  
        InOutDate NCHAR(8),  
        WHSeq INT,  
        FunctionWHSeq INT,  
        ItemSeq INT,  
        
        UnitSeq INT,  
        Qty DECIMAL(19,5),  
        StdQty DECIMAL(19,5),
        InOutKind INT,
        InOutDetailKind INT 
    )  
    
    INSERT INTO #GetInOutItem ( ItemSeq, AssetSeq ) 
    SELECT A.ItemSeq, B.AssetSeq 
      FROM _TDAItem                 AS A 
      LEFT OUTER JOIN _TDAItemAsset AS B ON ( B.CompanySeq = A.CompanySeq AND B.AssetSeq = A.AssetSeq ) 
      LEFT OUTER JOIN _TDAItemSales AS C ON ( C.CompanySeq = A.CompanySeq AND C.ItemSeq = A.ItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.AssetSeq IN ( 18, 20 ) 
       AND C.IsSet = '0'  
       AND A.SMStatus = 2001001 
    
    --select * From _TDASMinor where MajorSeq = 2001 and CompanySeq = 2 
    
    -- â����� ��������
    EXEC _SLGGetInOutStock @CompanySeq   = @CompanySeq,   -- �����ڵ�
                           @BizUnit      = 0,      -- ����ι�
                           @FactUnit     = @FactUnit,     -- ��������
                           @DateFr       = @SrtDate,       -- ��ȸ�ⰣFr
                           @DateTo       = @StdDate,       -- ��ȸ�ⰣTo
                           @WHSeq        = 0,        -- â������
                           @SMWHKind     = 0,     -- â���� 
                           @CustSeq      = 0,      -- ��Ź�ŷ�ó
                           @IsTrustCust  = '0',  -- ��Ź����
                           @IsSubDisplay = '0', -- ���â�� ��ȸ
                           @IsUnitQry    = '0',    -- ������ ��ȸ
                           @QryType      = 'S',      -- 'S': 1007 �����, 'B':1008 �ڻ�����, 'A':1011 �������
                           @MngDeptSeq   = 0,
                           @IsUseDetail  = '1'
    
    
    --select SUM(StdQty) From #TLGInOutStock where InOutType = 180 and InOut = -1 and ItemSeq = 426 
    --select StdQty , ItemSeq, WHSeq From #TLGInOutStock where InOutType = 140 and InOut = 1
    --select StdQty , ItemSeq, WHSeq From #TLGInOutStock where InOutType = 140 and InOut = -1
    --return 
    
    
    
    CREATE TABLE #Result_Sub 
    (
        GubunName       NVARCHAR(200), 
        Gubun           INT, 
        ItemName        NVARCHAR(200), 
        ItemSeq         INT, 
        AssetSeq        INT, 
        OpenStockQty    DECIMAL(19,5), 
        DailyProdQty    DECIMAL(19,5), 
        SumProdQty      DECIMAL(19,5), 
        DailySalsQty    DECIMAL(19,5), 
        SumSalsQty      DECIMAL(19,5), 
        DailySelfQty    DECIMAL(19,5), 
        SumSelfQty      DECIMAL(19,5), 
        EtcOutQty       DECIMAL(19,5), 
        ClosStockQty    DECIMAL(19,5), 
        InQty           DECIMAL(19,5), 
        OutQty          DECIMAL(19,5) 
    ) 
    CREATE TABLE #Result
    (
        GubunName       NVARCHAR(200), 
        Gubun           INT, 
        ItemName        NVARCHAR(200), 
        ItemSeq         INT, 
        AssetSeq        INT, 
        OpenStockQty    DECIMAL(19,5), 
        DailyProdQty    DECIMAL(19,5), 
        SumProdQty      DECIMAL(19,5), 
        DailySalsQty    DECIMAL(19,5), 
        SumSalsQty      DECIMAL(19,5), 
        DailySelfQty    DECIMAL(19,5), 
        SumSelfQty      DECIMAL(19,5), 
        EtcOutQty       DECIMAL(19,5), 
        ClosStockQty    DECIMAL(19,5), 
        InQty           DECIMAL(19,5), 
        OutQty          DECIMAL(19,5) 
    ) 
    
    -- ǰ������ 
    INSERT INTO #Result_Sub ( ItemSeq, ItemName, AssetSeq ) 
    SELECT A.ItemSeq, B.ItemEngSName, B.AssetSeq
      FROM #GetInOutItem    AS A 
      JOIN _TDAItem         AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )    
    
    -- ������� 
    UPDATE A 
       SET OpenStockQty = ISNULL(B.PrevQty,0)
      FROM #Result_Sub AS A 
      LEFT OUTER JOIN (
                        SELECT Z.ItemSeq, SUM(PrevQty) AS PrevQty
                          FROM #GetInOutStock AS Z 
                         GROUP BY Z.ItemSeq 
                       ) AS B ON ( B.ItemSeq = A.ItemSeq ) 
    -- ���귮 
    UPDATE A
       SET DailyProdQty = ISNULL(C.Qty,0), 
           SumProdQty   = ISNULL(B.Qty,0)
      FROM #Result_Sub AS A 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(StdQty) AS Qty 
                          FROM #TLGInOutStock AS Z 
                         WHERE Z.InOutDate BETWEEN @SrtDate AND @StdDate 
                           AND Z.InOutType = 140 
                           AND Z.InOut = 1
                         GROUP BY Z.ItemSeq 
                      ) AS B ON ( B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(StdQty) AS Qty 
                          FROM #TLGInOutStock AS Z 
                         WHERE Z.InOutDate = @StdDate 
                           AND Z.InOutType = 140 
                           AND Z.InOut = 1
                         GROUP BY Z.ItemSeq 
                      ) AS C ON ( C.ItemSeq = A.ItemSeq ) 

    -- �Ǹŷ� 
    UPDATE A
       SET DailySalsQty = ISNULL(C.Qty,0), 
           SumSalsQty   = ISNULL(B.Qty,0)
      FROM #Result_Sub AS A 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(StdQty) AS Qty 
                          FROM #TLGInOutStock AS Z 
                         WHERE Z.InOutDate BETWEEN @SrtDate AND @StdDate 
                           AND Z.InOutType = 10 
                           AND Z.InOut = -1
                         GROUP BY Z.ItemSeq 
                      ) AS B ON ( B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(StdQty) AS Qty 
                          FROM #TLGInOutStock AS Z 
                         WHERE Z.InOutDate = @StdDate 
                           AND Z.InOutType = 10 
                           AND Z.InOut = -1
                         GROUP BY Z.ItemSeq 
                      ) AS C ON ( C.ItemSeq = A.ItemSeq ) 
    
    -- �ڰ��Һ� 
    UPDATE A
       SET DailySelfQty = ISNULL(C.Qty,0), 
           SumSelfQty   = ISNULL(B.Qty,0)
      FROM #Result_Sub AS A 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(StdQty) AS Qty 
                          FROM #TLGInOutStock AS Z 
                         WHERE Z.InOutDate BETWEEN @SrtDate AND @StdDate 
                           AND Z.InOutType = 130 
                           AND Z.InOut = -1
                         GROUP BY Z.ItemSeq 
                      ) AS B ON ( B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(StdQty) AS Qty 
                          FROM #TLGInOutStock AS Z 
                         WHERE Z.InOutDate = @StdDate 
                           AND Z.InOutType = 130  
                           AND Z.InOut = -1
                         GROUP BY Z.ItemSeq 
                      ) AS C ON ( C.ItemSeq = A.ItemSeq ) 
    
    -- ��Ÿ��� 
    UPDATE A
       SET EtcOutQty = ISNULL(B.Qty,0)
      FROM #Result_Sub AS A 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(StdQty) AS Qty 
                          FROM #TLGInOutStock AS Z 
                         WHERE Z.InOutDate = @StdDate 
                           AND Z.InOutType = 30 
                           AND Z.InOut = -1 
                         GROUP BY Z.ItemSeq 
                      ) AS B ON ( B.ItemSeq = A.ItemSeq ) 
    
    -- �⸻��� 
    UPDATE A
       SET ClosStockQty = ISNULL(B.Qty,0)
      FROM #Result_Sub AS A 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(STDStockQty) AS Qty 
                          FROM #GetInOutStock AS Z 
                         GROUP BY Z.ItemSeq 
                      ) AS B ON ( B.ItemSeq = A.ItemSeq ) 
    
    -- �׿��� �԰�, ��� 
    UPDATE A
       SET InQty = ISNULL(C.Qty,0), 
           OutQty   = ISNULL(B.Qty,0)
      FROM #Result_Sub AS A 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(StdQty) AS Qty 
                          FROM #TLGInOutStock AS Z 
                         WHERE Z.InOutDate BETWEEN @SrtDate AND @StdDate 
                           AND Z.InOutType IN ( 80, 81, 90 ) -- �̵�, ����, �԰ݴ�ü
                           AND Z.InOut = -1
                         GROUP BY Z.ItemSeq 
                      ) AS B ON ( B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(StdQty) AS Qty 
                          FROM #TLGInOutStock AS Z 
                         WHERE Z.InOutDate BETWEEN @SrtDate AND @StdDate 
                           AND Z.InOutType IN ( 170, 110, 150, 240, 40, 41, 80, 81, 90 ) -- �����԰�, ��Ź�԰�, �����԰�, �����԰�, ��Ÿ�԰�, �����Ÿ�԰�, �̵�, ����, �԰ݴ�ü
                           AND Z.InOut = 1
                         GROUP BY Z.ItemSeq 
                      ) AS C ON ( C.ItemSeq = A.ItemSeq ) 
    
    -- ��ǰ �з��ϱ� 
    UPDATE A 
       SET GubunName = CASE WHEN C.ValueSeq IN ( 1012814002, 1012814003 ) THEN D.MinorName ELSE 'PPG ��ǰ' END, 
           Gubun = CASE WHEN C.ValueSeq = 1012814002 THEN 101 
                        WHEN C.ValueSeq = 1012814003 THEN 102 
                        ELSE 100 END 
      From #Result_Sub                  AS A 
      LEFT OUTER JOIN _TDAItemUserDefine AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.MngSerl = 1000003 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.MngValSeq AND C.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDAUMinor        AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.ValueSeq ) 
     --WHERE A.AssetSeq = 18 
    
    
    -- ����ǰ �з��ϱ� 
    UPDATE A 
       SET GubunName = CASE WHEN C.ValueSeq IN ( 1012814002, 1012814003 ) THEN D.MinorName ELSE 'PPG ����ǰ' END, 
           Gubun = CASE WHEN C.ValueSeq = 1012814002 THEN 301 
                        WHEN C.ValueSeq = 1012814003 THEN 302
                        ELSE 300 END 
      From #Result_Sub                  AS A 
      LEFT OUTER JOIN _TDAItemUserDefine AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.MngSerl = 1000003 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.MngValSeq AND C.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDAUMinor        AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.ValueSeq ) 
     WHERE A.AssetSeq = 20
    
    IF @IsItem = '1' -- ǰ����ȸ���� 
    BEGIN
        
        -- �⺻������ 
        INSERT INTO #Result
        (
            GubunName      ,Gubun          ,ItemName       ,ItemSeq        ,AssetSeq       ,
            OpenStockQty   ,DailyProdQty   ,SumProdQty     ,DailySalsQty   ,SumSalsQty     ,
            DailySelfQty   ,SumSelfQty     ,EtcOutQty      ,ClosStockQty   ,InQty          ,
            OutQty         
        )
        SELECT GubunName      ,Gubun          ,ItemName       ,ItemSeq        ,AssetSeq       ,
               OpenStockQty   ,DailyProdQty   ,SumProdQty     ,DailySalsQty   ,SumSalsQty     ,
               DailySelfQty   ,SumSelfQty     ,EtcOutQty      ,ClosStockQty   ,InQty          ,
               OutQty         
          FROM #Result_Sub
        
        -- ��ǰ �Ұ� 
        INSERT INTO #Result
        (
            GubunName      ,Gubun          ,ItemName       ,ItemSeq        ,AssetSeq       ,
            OpenStockQty   ,DailyProdQty   ,SumProdQty     ,DailySalsQty   ,SumSalsQty     ,
            DailySelfQty   ,SumSelfQty     ,EtcOutQty      ,ClosStockQty   ,InQty          ,
            OutQty         
        )
        SELECT '�� ��', 200, '', 0, 0,
               SUM(OpenStockQty)   ,SUM(DailyProdQty)   ,SUM(SumProdQty)     ,SUM(DailySalsQty)   ,SUM(SumSalsQty)     ,
               SUM(DailySelfQty)   ,SUM(SumSelfQty)     ,SUM(EtcOutQty)      ,SUM(ClosStockQty)   ,SUM(InQty)          ,
               SUM(OutQty)         
          FROM #Result_Sub
         WHERE Gubun < 200  
         
        -- ����ǰ �Ұ� 
        INSERT INTO #Result
        (
            GubunName      ,Gubun          ,ItemName       ,ItemSeq        ,AssetSeq       ,
            OpenStockQty   ,DailyProdQty   ,SumProdQty     ,DailySalsQty   ,SumSalsQty     ,
            DailySelfQty   ,SumSelfQty     ,EtcOutQty      ,ClosStockQty   ,InQty          ,
            OutQty         
        )
        SELECT '�� ��', 350, '', 0, 0,
               SUM(OpenStockQty)   ,SUM(DailyProdQty)   ,SUM(SumProdQty)     ,SUM(DailySalsQty)   ,SUM(SumSalsQty)     ,
               SUM(DailySelfQty)   ,SUM(SumSelfQty)     ,SUM(EtcOutQty)      ,SUM(ClosStockQty)   ,SUM(InQty)          ,
               SUM(OutQty)         
          FROM #Result_Sub
         WHERE 300 <= Gubun 
        
        -- �հ� �Ұ� 
        INSERT INTO #Result
        (
            GubunName      ,Gubun          ,ItemName       ,ItemSeq        ,AssetSeq       ,
            OpenStockQty   ,DailyProdQty   ,SumProdQty     ,DailySalsQty   ,SumSalsQty     ,
            DailySelfQty   ,SumSelfQty     ,EtcOutQty      ,ClosStockQty   ,InQty          ,
            OutQty         
        )
        SELECT '�� ��', 400, '', 0, 0,
               SUM(OpenStockQty)   ,SUM(DailyProdQty)   ,SUM(SumProdQty)     ,SUM(DailySalsQty)   ,SUM(SumSalsQty)     ,
               SUM(DailySelfQty)   ,SUM(SumSelfQty)     ,SUM(EtcOutQty)      ,SUM(ClosStockQty)   ,SUM(InQty)          ,
               SUM(OutQty)         
          FROM #Result_Sub 
         WHERE Gubun NOT IN ( 350, 200 ) 
    
    END 
    ELSE
    BEGIN
    
        -- �⺻������ 
        INSERT INTO #Result
        (
            GubunName      ,Gubun          ,ItemName       ,ItemSeq        ,AssetSeq       ,
            OpenStockQty   ,DailyProdQty   ,SumProdQty     ,DailySalsQty   ,SumSalsQty     ,
            DailySelfQty   ,SumSelfQty     ,EtcOutQty      ,ClosStockQty   ,InQty          ,
            OutQty         
        )
        SELECT MAX(GubunName)      ,Gubun          ,''       ,0        ,0       ,
               SUM(OpenStockQty)   ,SUM(DailyProdQty)   ,SUM(SumProdQty)     ,SUM(DailySalsQty)   ,SUM(SumSalsQty)     ,
               SUM(DailySelfQty)   ,SUM(SumSelfQty)     ,SUM(EtcOutQty)      ,SUM(ClosStockQty)   ,SUM(InQty)          ,
               SUM(OutQty)         
          FROM #Result_Sub
         GROUP BY Gubun
        
        -- ��ǰ �Ұ� 
        INSERT INTO #Result
        (
            GubunName      ,Gubun          ,ItemName       ,ItemSeq        ,AssetSeq       ,
            OpenStockQty   ,DailyProdQty   ,SumProdQty     ,DailySalsQty   ,SumSalsQty     ,
            DailySelfQty   ,SumSelfQty     ,EtcOutQty      ,ClosStockQty   ,InQty          ,
            OutQty         
        )
        SELECT '�� ��', 200, '', 0, 0,
               SUM(OpenStockQty)   ,SUM(DailyProdQty)   ,SUM(SumProdQty)     ,SUM(DailySalsQty)   ,SUM(SumSalsQty)     ,
               SUM(DailySelfQty)   ,SUM(SumSelfQty)     ,SUM(EtcOutQty)      ,SUM(ClosStockQty)   ,SUM(InQty)          ,
               SUM(OutQty)         
          FROM #Result_Sub
         WHERE Gubun < 200  
         
        -- �հ� �Ұ� 
        INSERT INTO #Result
        (
            GubunName      ,Gubun          ,ItemName       ,ItemSeq        ,AssetSeq       ,
            OpenStockQty   ,DailyProdQty   ,SumProdQty     ,DailySalsQty   ,SumSalsQty     ,
            DailySelfQty   ,SumSelfQty     ,EtcOutQty      ,ClosStockQty   ,InQty          ,
            OutQty         
        )
        SELECT '�� ��', 400, '', 0, 0,
               SUM(OpenStockQty)   ,SUM(DailyProdQty)   ,SUM(SumProdQty)     ,SUM(DailySalsQty)   ,SUM(SumSalsQty)     ,
               SUM(DailySelfQty)   ,SUM(SumSelfQty)     ,SUM(EtcOutQty)      ,SUM(ClosStockQty)   ,SUM(InQty)          ,
               SUM(OutQty)         
          FROM #Result_Sub 
         WHERE Gubun <> 200 
        
    END 
    
    
    SELECT * FROM #Result ORDER BY Gubun, ItemSeq 
    
    

    
    RETURN  
go
EXEC KPXCM_SPDDailyStockListSubQuery @xmlDocument = N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <FactUnit>3</FactUnit>
    <StdDate>20160408</StdDate>
    <IsItem>0</IsItem>
  </DataBlock1>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 1036580, @WorkingTag = N'', @CompanySeq = 2, @LanguageSeq = 1, @UserSeq = 50322, @PgmSeq = 1029979

