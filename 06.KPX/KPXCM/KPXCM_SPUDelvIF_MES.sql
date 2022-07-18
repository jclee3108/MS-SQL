IF OBJECT_ID('KPXCM_SPUDelvIF_MES') IS NOT NULL 
    DROP PROC KPXCM_SPUDelvIF_MES
GO 

-- v2016.10.26
  
-- ���ų�ǰ(����) ����(MES õ�Ȱ���) by����õ
CREATE PROC KPXCM_SPUDelvIF_MES
    @CompanySeq INT 
AS      
    
    CREATE TABLE #DelvAll -- ���ų�ǰ ������ ��� ������ 
    (
        IDX_NO      INT IDENTITY, 
        WorkingTag  NCHAR(1), 
        DelvSeq     INT, 
        DelvNo      NVARCHAR(100), 
        DelvDate    NCHAR(8), 
        CustSeq     INT, 
        DeptSeq     INT, 
        EmpSeq      INT, 
        Remark      NVARCHAR(500), 
        SMImpType   INT, 
        CurrSeq     INT, 
        ExRate      DECIMAL(10,5), 
        SMDelvType  INT, 
        SMStkType   INT, 
        BizUnit     INT, 
        POSeq       INT 
    ) 
    
    CREATE TABLE #Delv -- ���ų�ǰ ������ �ϳ��� ������ 
    (
        IDX_NO      INT IDENTITY, 
        WorkingTag  NCHAR(1), 
        DelvSeq     INT, 
        DelvNo      NVARCHAR(100), 
        DelvDate    NCHAR(8), 
        CustSeq     INT, 
        DeptSeq     INT, 
        EmpSeq      INT, 
        Remark      NVARCHAR(500), 
        SMImpType   INT, 
        CurrSeq     INT, 
        ExRate      DECIMAL(10,5), 
        SMDelvType  INT, 
        SMStkType   INT, 
        BizUnit     INT, 
        POSeq       INT 
    ) 
    
    CREATE TABLE #DelvItem -- ���ų�ǰ ������ ������ 
    (
        IDX_NO      INT IDENTITY, 
        DelvSeq     INT, 
        DelvSerl    INT, 
        ItemSeq     INT,  
        UnitSeq     INT, 
        Price       DECIMAL(19,5), 
        Qty         DECIMAL(19,5), 
        CurAmt      DECIMAL(19,5), 
        DomAmt      DECIMAL(19,5), 
        StdUnitSeq  INT, 
        StdUnitQty  DECIMAL(19,5), 
        WHSeq       INT, 
        LOTNo       NVARCHAR(100), 
        DomPrice    DECIMAL(19,5), 
        CurVAT      DECIMAL(19,5), 
        DomVAT      DECIMAL(19,5), 
        IsVAT       NCHAR(1), 
        Remark      NVARCHAR(500), 
        SupplyAmt   DECIMAL(19,5), 
        SupplyVAT   DECIMAL(19,5), 
        ValiDate    NCHAR(8), 
        POSeq       INT, 
        POSerl      INT, 
        Seq         NVARCHAR(20) 
    ) 
    
    CREATE TABLE #LotMaster -- Lot������ 
    (
        IDX_NO      INT IDENTITY, 
        LotNo       NVARCHAR(100), 
        ItemSeq     INT, 
        UnitSeq     INT, 
        Qty         DECIMAL(19,5), 
        RegDate     NCHAR(8), 
        CustSeq     INT, 
        Remark      NVARCHAR(500), 
        InNo        NVARCHAR(200), 
        WorkingTag  NCHAR(1), 
        ValiDate    NCHAR(8) 
    ) 
    
    CREATE TABLE #SourceDaily -- ����->��ǰ ���� 
    (
        IDX_NO          INT IDENTITY, 
        WorkingTag      NCHAR(1), 
        FromTableSeq    INT, 
        FromSeq         INT, 
        FromSerl        INT, 
        FromQty         DECIMAL(19,5), 
        FromSTDQty      DECIMAL(19,5), 
        FromAmt         DECIMAL(19,5), 
        FromVAT         DECIMAL(19,5), 
        ToTableSeq      INT, 
        ToSeq           INT, 
        ToSerl          INT, 
        ToQty           DECIMAL(19,5), 
        ToSTDQty        DECIMAL(19,5), 
        ToAmt           DECIMAL(19,5), 
        ToVAT           DECIMAL(19,5)
    )
    
    CREATE TABLE #DelvInAuto -- �����ڵ� �԰� 
    (
        IDX_NO      INT IDENTITY, 
        WorkingTag  NCHAR(1), 
        DelvSeq     INT, 
        DelvSerl    INT, 
        Qty         DECIMAL(19,5), 
        STDQty      DECIMAL(19,5) 
    ) 
    
    DECLARE @BizUnit    INT, 
            @Status     INT 
    
    SELECT @BizUnit = 26 
    
    INSERT INTO #DelvAll -- ���ų�ǰ ������ (��ü)
    (
        WorkingTag , DelvSeq    , DelvNo     , DelvDate   , CustSeq    , 
        DeptSeq    , EmpSeq     , Remark     , SMImpType  , CurrSeq    , 
        ExRate     , SMDelvType , SMStkType  , BizUnit    , POSeq      
    ) 
    SELECT A.WorkingTag, 0, 0, MAX(A.DelvDate), MAX(B.CustSeq), 
           MAX(B.DeptSeq), MAX(B.EmpSeq), 'MES����������', MAX(B.SMImpType), MAX(B.CurrSeq), 
           MAX(B.ExRate), 6034001, 6033001, @BizUnit, A.POSeq -- õ�Ȱ��� 
      FROM IF_PUInQCResult_MES  AS A 
      JOIN _TPUORDPO AS B ON ( B.CompanySeq = @CompanySeq AND B.POSeq = A.POSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ImpType = 0 -- ���� 
       AND ISNULL(A.ProcYn,'0') = '0' 
       
       AND A.WorkingTag = 'A' -- ���Ŀ� ���� ���� 
       
     GROUP BY A.POSeq, A.WorkingTag
     
     --order by A.POSeq desc      
    
    
    -- ó���� ������ ������ return 
    IF NOT EXISTS (SELECT 1 FROM #DelvAll)
    BEGIN
        
        SELECT * FROM #DelvAll 
        RETURN 
    END 
    
    
    
    
    DECLARE @MainCnt INT -- �ѰǾ� ó���ϱ����� ���� 
    SELECT @MainCnt = 1 
    
    
    WHILE ( 1 = 1 ) 
    BEGIN 
        
        
        TRUNCATE TABLE #Delv 
        INSERT INTO #Delv -- ���ų�ǰ ������ 
        (
            WorkingTag , DelvSeq    , DelvNo     , DelvDate   , CustSeq    , 
            DeptSeq    , EmpSeq     , Remark     , SMImpType  , CurrSeq    , 
            ExRate     , SMDelvType , SMStkType  , BizUnit    , POSeq
        ) 
        SELECT TOP 1 
               WorkingTag , DelvSeq    , DelvNo     , DelvDate   , CustSeq    , 
               DeptSeq    , EmpSeq     , Remark     , SMImpType  , CurrSeq    , 
               ExRate     , SMDelvType , SMStkType  , BizUnit    , POSeq 
          FROM #DelvAll 
         WHERE IDX_NO = @MainCnt 
        

        
        IF EXISTS (SELECT 1 FROM #Delv WHERE WorkingTag = 'A') 
        BEGIN 
        
            DECLARE @Count      INT, -- ä�� ���� 
                    @DelvSeq    INT, 
                    @Cnt        INT, -- WHILE ���� 
                    @BaseDate   NCHAR(8), -- ��ȣ ä���ϱ����� ��¥ 
                    @DelvNo     NVARCHAR(100) -- ä�� ��ȣ 
            
            SELECT @Count = COUNT(1) FROM #Delv 
            
            -- DelvSeq ä�� 
            EXEC @DelvSeq = _SCOMCreateSeq @CompanySeq, '_TPUDelv', 'DelvSeq', 1 
            
            
            SELECT @BaseDate = DelvDate 
              FROM #Delv 
             WHERE WorkingTag = 'A' 
            
            EXEC _SCOMCreateNo 'PU', '_TPUDelv', @CompanySeq, '', @BaseDate, @DelvNo OUTPUT  
            
            UPDATE A 
               SET DelvSeq = @DelvSeq + A.IDX_NO, 
                   DelvNo = @DelvNo 
              FROM #Delv AS A 
             WHERE A.WorkingTag = 'A' 
        
            
        END 
        
        
        
        TRUNCATE TABLE #DelvItem
        INSERT INTO #DelvItem -- ���ų�ǰ ������ ������ 
        (
            DelvSeq       , DelvSerl      , ItemSeq       , UnitSeq       , Price         , 
            Qty           , CurAmt        , DomAmt        , StdUnitSeq    , StdUnitQty    , 
            WHSeq         , LOTNo         , DomPrice      , CurVAT        , DomVAT        , 
            IsVAT         , Remark        , SupplyAmt     , SupplyVAT     , ValiDate      , 
            POSeq         , POSerl        , Seq 
        ) 

        SELECT A.DelvSeq, ROW_NUMBER() OVER(ORDER BY A.DelvSeq), C.ItemSeq, C.UnitSeq, C.Price, 
               B.Qty, C.Price * B.Qty, C.Price * B.Qty, C.StdUnitSeq, B.Qty, 
               ISNULL(F.WHSeq,179), B.LotNo, C.Price, ISNULL((C.Price * B.Qty) / CONVERT(INT,REPLACE(E.MinorName,'%','')),0),ISNULL((C.Price * B.Qty) / CONVERT(INT,REPLACE(E.MinorName,'%','')),0), 
               '0', 'MES����������', 0, 0, B.ValiDate, 
               C.POSeq, C.POSerl, B.Seq 
          FROM #Delv                 AS A 
          JOIN IF_PUInQCResult_MES      AS B ON ( B.CompanySeq = @CompanySeq AND B.POSeq = A.POSeq AND ISNULL(B.ProcYn,'0') ='0' AND B.ImpType = 0 AND A.WorkingTag = B.WorkingTag ) 
          JOIN _TPUORDPOItem            AS C ON ( C.CompanySeq = @CompanySeq AND C.POSeq = B.POSeq AND C.POSerl = B.POSerl ) 
          LEFT OUTER JOIN _TDAItemSales AS D ON ( D.CompanySeq = @COmpanySeq AND D.ItemSeq = C.ItemSeq )   
          LEFT OUTER JOIN _TDASMinor    AS E ON ( E.CompanySeq = @COmpanySeq AND E.MinorSeq = D.SMVatType )   
          LEFT OUTER JOIN (SELECT Z.ItemSeq, MAX(Z.WHSeq) AS WHSeq 
                             FROM _TDAWHItem AS Z 
                            WHERE Z.CompanySeq = @CompanySeq 
                            GROUP BY Z.ItemSeq 
                          ) AS F ON ( F.ItemSeq = C.ItemSeq ) 
         WHERE B.WorkingTag = 'A' -- ���Ŀ� �������� 
        
        
        ----------------------------------------------------        
        -- ����/������ DelvSeq, DelvSerl ������Ʈ 
        ----------------------------------------------------
        
        -- ���� -> ��ǰ�ڵ� ã�� 
        CREATE TABLE #ProgData 
        (
            IDX_NO      INT IDENTITY, 
            POSeq       INT, 
            POSerl      INT, 
            DelvSeq     INT, 
            DelvSerl    INT 
        ) 
        INSERT INTO #ProgData ( POSeq, POSerl, DelvSeq, DelvSerl ) 
         SELECT DISTINCT A.POSeq, A.POSerl, 0, 0 
          FROM #DelvItem AS A 
          JOIN #Delv     AS B ON ( B.DelvSeq = A.DelvSeq ) 
         WHERE B.WorkingTag IN ( 'U', 'D' ) 
        

        CREATE TABLE #TMP_ProgressTable 
        (
            IDOrder   INT, 
            TableName NVARCHAR(100)
        ) 
        
        INSERT INTO #TMP_ProgressTable (IDOrder, TableName) 
        SELECT 1, '_TPUDelvItem'   -- ������ ã�� ���̺� 
        
        CREATE TABLE #TCOMProgressTracking
        (
            IDX_NO  INT,  
            IDOrder  INT, 
            Seq      INT, 
            Serl     INT, 
            SubSerl  INT, 
            Qty      DECIMAL(19,5), 
            StdQty   DECIMAL(19,5), 
            Amt      DECIMAL(19,5), 
            VAT      DECIMAL(19,5)
        ) 
        EXEC _SCOMProgressTracking 
                @CompanySeq = @CompanySeq, 
                @TableName = '_TPUORDPOItem',    -- ������ �Ǵ� ���̺�
                @TempTableName = '#ProgData',  -- ������ �Ǵ� �������̺�
                @TempSeqColumnName = 'POSeq',  -- �������̺��� Seq
                @TempSerlColumnName = 'POSerl',  -- �������̺��� Serl
                @TempSubSerlColumnName = ''  
        
        

        
        UPDATE A 
           SET DelvSeq = B.Seq, 
               DelvSerl = B.Serl 
          FROM #ProgData AS A 
          JOIN #TCOMProgressTracking  AS B ON ( B.IDX_NO = A.IDX_NO ) 
        
        UPDATE A 
           SET DelvSeq = C.DelvSeq, 
               DelvSerl = C.DelvSerl 
          FROM #DelvItem AS A 
          JOIN #Delv     AS B ON ( B.DelvSeq = A.DelvSeq ) 
          JOIN #ProgData AS C ON ( C.POSeq = A.POSeq AND C.POSerl = A.POSerl ) 
         WHERE B.WorkingTag IN ( 'U', 'D' )  
         
        UPDATE A 
           SET DelvSeq = B.DelvSeq
          FROM #Delv     AS A 
          JOIN #ProgData AS B ON ( B.POSeq = A.POSeq ) 
         WHERE A.WorkingTag IN ( 'U', 'D' )  
        
        DROP TABLE #TCOMProgressTracking
        DROP TABLE #TMP_ProgressTable 
        
        ----------------------------------------------------        
        -- ����/������ DelvSeq, DelvSerl ������Ʈ, END  
        ----------------------------------------------------
        
        
        
        TRUNCATE TABLE #LotMaster 
        INSERT INTO #LotMaster 
        (
            LotNo    , ItemSeq  , UnitSeq  , Qty        , RegDate  , 
            CustSeq  , Remark   , InNo     , WorkingTag , ValiDate 
        ) 
        SELECT A.LOTNo, A.ItemSeq, A.UnitSeq, A.Qty, B.DelvDate, 
               B.CustSeq, B.Remark, B.DelvNo, B.WorkingTag, A.ValiDate 
          FROM #DelvItem AS A 
          JOIN #Delv     AS B ON ( B.DelvSeq = A.DelvSeq ) 
         WHERE NOT EXISTS (SELECT 1 FROM _TLGLotMaster WHERE CompanySeq = @CompanySeq AND ItemSeq = A.ItemSeq AND LotNo = A.LOTNo) 
        
        
        TRUNCATE TABLE #SourceDaily 
        INSERT INTO #SourceDaily 
        (
            WorkingTag    , FromTableSeq      , FromSeq           , FromSerl          , FromQty           , 
            FromSTDQty    , FromAmt           , FromVAT           , ToTableSeq        , ToSeq             , 
            ToSerl        , ToQty             , ToSTDQty          , ToAmt             , ToVAT                 
        )
        SELECT B.WorkingTag, 13, A.POSeq, A.POSerl, C.Qty, 
               C.Qty, C.CurAmt, C.CurVAT, 10, A.DelvSeq, 
               A.DelvSerl, A.Qty, A.Qty, A.CurAmt, A.CurVAT 
          FROM #DelvItem     AS A 
          JOIN #Delv         AS B ON ( B.DelvSeq = A.DelvSeq ) 
          JOIN _TPUORDPOItem    AS C ON ( C.CompanySeq = @CompanySeq AND C.POSeq = A.POSeq AND C.POSerl = A.POSerl ) 
        
        
        
        TRUNCATE TABLE #DelvInAuto 
        INSERT INTO #DelvInAuto 
        (
            WorkingTag, DelvSeq, DelvSerl, Qty, STDQty 
        )
        SELECT B.WorkingTag, A.DelvSeq, A.DelvSerl,A.Qty, A.StdUnitQty
          FROM #DelvItem     AS A 
          JOIN #Delv         AS B ON ( B.DelvSeq = A.DelvSeq ) 
        
        
        -- ���̺� �ݿ� 
        
        DECLARE @XmlData NVARCHAR(MAX) 
        
        BEGIN TRAN 
        -- Delv ���� 
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,         
                                                          A.IDX_NO,         
                                                          A.IDX_NO AS DataSeq,         
                                                          1 AS Selected,         
                                                          0 AS Status,         
                                                          A.DelvSeq,         
                                                          A.DelvNo, 
                                                          A.DelvDate, 
                                                          A.CustSeq, 
                                                          A.DeptSeq, 
                                                          A.EmpSeq, 
                                                          A.Remark, 
                                                          A.SMImpType, 
                                                          A.CurrSeq, 
                                                          A.ExRate, 
                                                          A.SMDelvType, 
                                                          A.SMStkType, 
                                                          A.BizUnit, 
                                                          '0' AS IsPJT
                                                      FROM #Delv AS A         
                                                     FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                      )) 
            
            EXEC @Status = 
                 KPXCM_SPUDelvSave_MES         
                 @xmlDocument  = @XmlData,           
                 @xmlFlags     = 2,           
                 @ServiceSeq   = 2548,           
                 @WorkingTag   = '',           
                 @CompanySeq   = @CompanySeq,           
                 @LanguageSeq  = 1,           
                 @UserSeq      = 1,           
                 @PgmSeq       = 1134    
        
        
        IF @@ERROR <> 0 OR @Status <> 0 
        BEGIN 
            ROLLBACK 
            
            UPDATE A 
               SET ProcYn = '2', 
                   ErrorMessage = '���ų�ǰ �����͵����� ����' 
              FROM IF_PUInQCResult_MES AS A 
              JOIN #DelvItem           AS B ON ( B.Seq = A.Seq ) 
              
            RETURN 
        END 
        
        -- DelvItem ���� 
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT B.WorkingTag,         
                                                          A.IDX_NO,         
                                                          A.IDX_NO AS DataSeq,         
                                                          1 AS Selected,         
                                                          0 AS Status,         
                                                          A.DelvSeq,         
                                                          A.DelvSerl, 
                                                          A.Price, 
                                                          A.Qty, 
                                                          A.CurAmt, 
                                                          A.DomPrice, 
                                                          A.DomAmt, 
                                                          A.WHSeq, 
                                                          0 AS DelvCustSeq, 
                                                          0 AS SalesCustSeq, 
                                                          6035001 AS SMQcType, 
                                                          '' AS QCDate, 
                                                          0 AS QCQty, 
                                                          0 AS QCCurrAmt, 
                                                          0 AS QCStdUnitQty, 
                                                          A.StdUnitSeq AS STDUnitSeq, 
                                                          A.StdUnitQty AS STDUnitQty, 
                                                          A.ItemSeq, 
                                                          A.UnitSeq, 
                                                          A.LOTNo AS LotNo, 
                                                          A.Remark, 
                                                          A.CurVAT, 
                                                          A.DomVAT, 
                                                          A.IsVAT
                                                      FROM #DelvItem AS A  
                                                      JOIN #Delv     AS B ON ( B.DelvSeq = A.DelvSeq ) 
                                                     FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS           
                                                      )) 
        
            EXEC @Status = 
                 KPXCM_SPUDelvItemSave_MES         
                 @xmlDocument  = @XmlData,           
                 @xmlFlags     = 2,           
                 @ServiceSeq   = 2548,           
                 @WorkingTag   = '',           
                 @CompanySeq   = @CompanySeq,           
                 @LanguageSeq  = 1,           
                 @UserSeq      = 1,           
                 @PgmSeq       = 1134    
        
        IF @@ERROR <> 0 OR @Status <> 0 
        BEGIN 
            ROLLBACK 
            
            UPDATE A 
               SET ProcYn = '2', 
                   ErrorMessage = '���ų�ǰ ǰ������ ����' 
              FROM #DelvItem AS A 
              JOIN IF_PUInQCResult_MES AS B ON ( B.Seq = A.Seq ) 
            
            RETURN 
        END 
        

        -- Lot������ ���� 
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,         
                                                          A.IDX_NO,         
                                                          A.IDX_NO AS DataSeq,         
                                                          1 AS Selected,         
                                                          0 AS Status,         
                                                          A.LotNo, 
                                                          A.ItemSeq, 
                                                          A.UnitSeq, 
                                                          A.Qty, 
                                                          A.RegDate, 
                                                          A.CustSeq, 
                                                          A.Remark, 
                                                          A.InNo, 
                                                          A.ValiDate 
                                                      FROM #LotMaster AS A  
                                                     FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                      )) 
        
            EXEC @Status = 
                 KPXCM_SLGLotNoMasterSave_MES         
                 @xmlDocument  = @XmlData,           
                 @xmlFlags     = 2,           
                 @ServiceSeq   = 4422,           
                 @WorkingTag   = '',           
                 @CompanySeq   = @CompanySeq,           
                 @LanguageSeq  = 1,           
                 @UserSeq      = 1,           
                 @PgmSeq       = 1134   
        
        IF @@ERROR <> 0 OR @Status <> 0 
        BEGIN 
            ROLLBACK 
            
            UPDATE A 
               SET ProcYn = '2', 
                   ErrorMessage = 'Lot������ ����' 
              FROM IF_PUInQCResult_MES  AS A 
              JOIN #DelvItem            AS B ON ( B.Seq = A.Seq ) 
              
            RETURN 
        END 
        
        
        -- ����->��ǰ ������� 
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,         
                                                          A.IDX_NO,         
                                                          A.IDX_NO AS DataSeq,         
                                                          1 AS Selected,         
                                                          0 AS Status,         
                                                          A.ToTableSeq, 
                                                          A.FromQty, 
                                                          A.FromSTDQty, 
                                                          A.FromAmt, 
                                                          A.FromVAT, 
                                                          A.FromSeq, 
                                                          A.FromSerl, 
                                                          A.FromTableSeq, 
                                                          A.ToAmt, 
                                                          A.ToSTDQty, 
                                                          A.ToSeq, 
                                                          A.ToSerl, 
                                                          A.ToVAT, 
                                                          A.ToQty 
                                                      FROM #SourceDaily AS A  
                                                     FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                      )) 
        
            EXEC @Status = 
                 KPXCM_SCOMSourceDailySave_MES         
                 @xmlDocument  = @XmlData,           
                 @xmlFlags     = 2,           
                 @ServiceSeq   = 3181,           
                 @WorkingTag   = '',           
                 @CompanySeq   = @CompanySeq,           
                 @LanguageSeq  = 1,           
                 @UserSeq      = 1,           
                 @PgmSeq       = 1134   
        
        IF @@ERROR <> 0 OR @Status <> 0 
        BEGIN 
            ROLLBACK 
            
            UPDATE A 
               SET ProcYn = '2', 
                   ErrorMessage = '���Ź��� -> ���ų�ǰ ���� ����' 
              FROM IF_PUInQCResult_MES  AS A 
              JOIN #DelvItem            AS B ON ( B.Seq = A.Seq ) 
              
            RETURN 
        END 
        
        -- �����ڵ��԰� 
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,         
                                                          A.IDX_NO,         
                                                          A.IDX_NO AS DataSeq,         
                                                          1 AS Selected,         
                                                          0 AS Status,         
                                                          A.DelvSeq, 
                                                          A.DelvSerl, 
                                                          A.Qty, 
                                                          A.STDQty
                                                      FROM #DelvInAuto AS A  
                                                     FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                      )) 
        
            EXEC @Status = 
                 KPXCM_SPUDelvInAutoSave_MES         
                 @xmlDocument  = @XmlData,           
                 @xmlFlags     = 2,           
                 @ServiceSeq   = 5545,           
                 @WorkingTag   = '',           
                 @CompanySeq   = @CompanySeq,           
                 @LanguageSeq  = 1,           
                 @UserSeq      = 1,           
                 @PgmSeq       = 1134   
        
        IF @@ERROR <> 0 OR @Status <> 0 
        BEGIN 
            ROLLBACK 
            
            UPDATE A 
               SET ProcYn = '2', 
                   ErrorMessage = '�����԰� ����' 
              FROM IF_PUInQCResult_MES  AS A 
              JOIN #DelvItem            AS B ON ( B.Seq = A.Seq ) 
            
            RETURN 
        END 
        ELSE 
        BEGIN 
            
            UPDATE A
               SET ProcYn = '1' 
              FROM IF_PUInQCResult_MES  AS A 
              JOIN #DelvItem            AS B ON ( B.Seq = A.Seq ) 
            --select * from #DelvItem 
            
            
            COMMIT TRAN 
            RETURN 
        END 
        
        IF @MainCnt >= (SELECT MAX(IDX_NO) FROM #DelvAll) 
        BEGIN 
            BREAK 
        END 
        ELSE 
        BEGIN 
            SELECT @MainCnt = @MainCnt + 1 
        END 
    
    END -- while end 
    
    

GO



--exec KPXCM_SPUDelvIF_MES 2 