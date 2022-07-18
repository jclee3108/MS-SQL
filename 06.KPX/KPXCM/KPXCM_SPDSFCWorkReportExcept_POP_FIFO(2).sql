IF OBJECT_ID('KPXCM_SPDSFCWorkReportExcept_POP_FIFO') IS NOT NULL 
    DROP PROC KPXCM_SPDSFCWorkReportExcept_POP_FIFO
GO 

-- v2016.11.16

-- ���� ���Լ��� ���� �ݿ� by����õ 
CREATE PROC KPXCM_SPDSFCWorkReportExcept_POP_FIFO
    @CompanySeq     INT, 
    @ItemSeq        INT, 
    @LotNo          NVARCHAR(100), 
    @WHSeq          INT, 
    @Qty            DECIMAL(19,5), 
    @IsTank         NCHAR(1), 
    @InPutDate      NCHAR(8), 
    @WorkingTag     NCHAR(1), 
    @WorkReportSeq  INT, 
    @ItemSerl       INT, 
    @Seq            INT 
AS 
    
    /*
    CREATE TABLE #FIFO 
    (
        ItemSeq     INT, 
        LotNo       NVARCHAR(100), 
        WHSeq       INT, 
        Status      INT, 
        Result      NVARCHAR(500)
    )

    --*/



    DECLARE @IsGoodItem     NCHAR(1), -- ��ǰ,����ǰ���� 
            @OutWHSeq       INT, 
            @XmlData        NVARCHAR(MAX)

    -- ����������ڵ� - ǰ���ڻ�з��� ����⺻â��
    -- �⺻ ����â�� ���� 
    SELECT @OutWHSeq = E.ValueSeq
      FROM _TDAItem                     AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MajorSeq = 1012905 AND C.Serl = 1000001 ) -- �������� 
                 JOIN _TDAUMinorValue   AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.MinorSeq AND D.ValueSeq = A.AssetSeq AND D.Serl = 1000002 ) -- ǰ���ڻ�з� 
      LEFT OUTER JOIN _TDAUMinorValue   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = C.MinorSeq AND E.Serl = 1000003 ) -- ����â�� 
      LEFT OUTER JOIN _TDAUMinorValue   AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = C.MinorSeq AND F.Serl = 1000004 ) -- ��ũ���� 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ItemSeq = @ItemSeq 
       AND C.ValueSeq = 3 -- �췹ź ����� 
       AND ISNULL(F.ValueSeq,0) = 0 -- ��ũ���Ͱ� ���°͸� 
    
    SELECT @IsGoodItem = CASE WHEN B.SMAssetGrp = 6008004 THEN '1' ELSE '0' END 
      FROM _TDAItem                 AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TDAItemAsset AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.AssetSeq = A.AssetSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ItemSeq = @ItemSeq 
    
    -- ���η�, ��ũ���� 
    IF @IsGoodItem = '0' AND @IsTank = '1' 
    BEGIN 
        INSERT INTO #FIFO ( ItemSeq, LotNo, WHSeq ) 
        SELECT @ItemSeq, A.ItemNo, @OutWHSeq 
          FROM _TDAItem AS A WITH(NOLOCK) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.ItemSeq = @ItemSeq 
    END 
    -- ���η�, �巳���� 
    ELSE IF @IsGoodItem = '0' AND @IsTank = '0' 
    BEGIN
        INSERT INTO #FIFO ( ItemSeq, LotNo, WHSeq ) 
        SELECT @ItemSeq, @LotNo, @WHSeq
    END 


    -- ��ǰ����ǰ, ��ũ���� 
    IF @IsGoodItem = '1' AND @IsTank = '1' 
    BEGIN 
        
        -- ���� ����Ÿ ��� ����  
        CREATE TABLE #LGInOutDailyCheck (WorkingTag NCHAR(1) NULL)    
        EXEC dbo._SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock1', '#LGInOutDailyCheck'       
        IF @@ERROR <> 0 RETURN   



        IF @WorkingTag IN ( 'U' , 'D' ) 
        BEGIN 
            SELECT 'D' AS WorkingTag, 
                   1 AS IDX_NO, 
                   1 AS DataSeq, 
                   0 AS Status, 
                   1 AS Selected, 
                   A.InOutSeq, 
                   InOutType 
              INTO #InOutDailyDel_Xml
              FROM KPXCM_TPDSFCMatInputFIFORelation AS A WITH(NOLOCK)  
             WHERE A.CompanySeq = @CompanySeq 
               AND A.WorkReportSeq = @WorkReportSeq 
               AND A.ItemSerl = @ItemSerl 

            SELECT @XmlData = CONVERT(NVARCHAR(MAX),(              
                                                        SELECT *               
                                                          FROM #InOutDailyDel_Xml              
                                                          FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                     )) 

            
            TRUNCATE TABLE #LGInOutDailyCheck 
            INSERT INTO #LGInOutDailyCheck 
            EXEC _SLGInOutDailyCheck               
                     @xmlDocument  = @XmlData,              
                     @xmlFlags     = 2,              
                     @ServiceSeq   = 2619,              
                     @WorkingTag   = '',              
                     @CompanySeq   = @CompanySeq,              
                     @LanguageSeq  = 1,              
                     @UserSeq      = 1,           
                     @PgmSeq       = 5042  
        

            SELECT @XmlData = CONVERT(NVARCHAR(MAX),(              
                                                        SELECT *               
                                                          FROM #LGInOutDailyCheck 
                                                          FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                     )) 
            TRUNCATE TABLE #LGInOutDailyCheck 
            INSERT INTO #LGInOutDailyCheck 
            EXEC _SLGInOutDailySave               
                     @xmlDocument  = @XmlData,              
                     @xmlFlags     = 2,              
                     @ServiceSeq   = 2619,              
                     @WorkingTag   = '',              
                     @CompanySeq   = @CompanySeq,              
                     @LanguageSeq  = 1,              
                     @UserSeq      = 1,           
                     @PgmSeq       = 5042    
        
        
            DELETE A 
              FROM KPXCM_TPDSFCMatInputFIFORelation AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.WorkReportSeq = @WorkReportSeq 
               AND A.ItemSerl = @ItemSerl 

        END 


        CREATE TABLE #LotConvert
        (
            IDX_NO      INT IDENTITY,
            InOutSeq    INT, 
            ItemSeq     INT, 
            Qty         INT, 
            LotNo       NVARCHAR(100)
        )

        IF @WorkingTag IN ( 'A' , 'U' ) 
        BEGIN 
            CREATE TABLE #GetInOutLot    
            (      
                LotNo         NVARCHAR(30),    
                ItemSeq       INT,
                ItemClassSSeq INT, ItemClassSName NVARCHAR(200),        -- ǰ����߼Һз�, 2012.07.05 ������ �߰�
                ItemClassMSeq INT, ItemClassMName NVARCHAR(200),  
                ItemClassLSeq INT, ItemClassLName NVARCHAR(200)      
            )      
          
            CREATE TABLE #GetInOutLotStock      
            (      
                WHSeq           INT,      
                FunctionWHSeq   INT,      
                LotNo           NVARCHAR(30),    
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
        
            -- _TLGLotStock���� Lot�� ǰ�� ����
            INSERT INTO #GetInOutLot ( LotNo, ItemSeq ) 
            SELECT A.LotNo, A.ItemSeq 
              FROM _TLGLotMaster AS A WITH(NOLOCK) 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.ItemSeq = @ItemSeq 
            

            -- â����� ��������      
            EXEC _SLGGetInOutLotStock   @CompanySeq   = @CompanySeq,   -- �����ڵ�      
                                        @BizUnit      = 0,      -- ����ι�      
                                        @FactUnit     = 0,     -- ��������      
                                        @DateFr       = @InPutDate,       -- ��ȸ�ⰣFr      
                                        @DateTo       = @InPutDate,       -- ��ȸ�ⰣTo      
                                        @WHSeq        = @OutWHSeq,        -- â������      
                                        @SMWHKind     = 0,     -- â���к� ��ȸ      
                                        @CustSeq      = 0,      -- ��Ź�ŷ�ó      
                                        @IsTrustCust  = '0',  -- ��Ź����      
                                        @IsSubDisplay = '0', -- ���â�� ��ȸ      
                                        @IsUnitQry    = '0',    -- ������ ��ȸ      
                                        @QryType      = 'S'       -- 'S': 1007 �����, 'B':1008 �ڻ�����, 'A':1011 �������      
            
            SELECT ROW_NUMBER() OVER(ORDER BY B.CreateDate) AS IDX_NO, 
                   A.ItemSeq, 
                   A.LotNo, 
                   A.STDStockQty AS Qty, 
                   B.CreateDate  
              INTO #LotStock 
              FROM #GetInOutLotStock    AS A 
              JOIN _TLGLotMaster        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.LotNo = A.LotNo ) 
             WHERE B.CreateDate <> '' 
               AND A.STDStockQty > 0 
             ORDER BY B.CreateDate 
        


            DECLARE @Cnt        INT, -- While Cnt 
                    @StockQty   DECIMAL(19,5), -- Lot�� ��� 
                    @RealQty    DECIMAL(19,5), -- Lot��ü ��� ���� 
                    @RealLotNo  NVARCHAR(100) -- Lot��ü ��� Lot 
            
            --select * from #LotStock 
            --return 
            SELECT @Cnt = 1 

            WHILE ( 1 = 1 ) 
            BEGIN
            
                SELECT @StockQty = Qty, 
                       @RealLotNo = LotNo 
                  FROM #LotStock 
                 WHERE IDX_NO = @Cnt 

                SELECT @RealQty = CASE WHEN ISNULL(@StockQty,0) < @Qty THEN ISNULL(@StockQty,0) ELSE @Qty END 

            
                INSERT INTO #LotConvert ( ItemSeq, Qty, LotNo ) 
                SELECT @ItemSeq, @RealQty , @RealLotNo
                 WHERE @RealLotNo IS NOT NULL 

            
                IF @RealQty = @Qty OR ISNULL(@StockQty,0) = 0 
                BEGIN 
                    BREAK 
                END 
                ELSE 
                BEGIN 
                    SELECT @Qty = @Qty - @RealQty 
                    SELECT @Cnt = @Cnt + 1 
                END 
        
            END -- while end 
            
            SELECT DISTINCT 
                   'A' AS WorkingTag, 
                   1 AS IDX_NO, 
                   1 AS DataSeq, 
                   0 AS Status, 
                   1 AS Selected, 
                   InOutSeq, 
                   310 AS InOutType, 
                   @OutWHSeq AS InWHSeq, 
                   (SELECT BizUnit FROM _TDAFactUnit WHERE CompanySeq = @CompanySeq AND FactUnit = 3) AS BizUnit, 
                   @InPutDate AS InOutDate, 
                   @OutWHSeq AS OutWHSeq, 
                   '��ǰ,����ǰ ��ũ���� ���Լ��� Lot��ü' AS Remark 
              INTO #InOutDaily_xml
              FROM #LotConvert 

            SELECT @XmlData = CONVERT(NVARCHAR(MAX),(              
                                                        SELECT *               
                                                          FROM #InOutDaily_xml              
                                                          FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                     )) 


        
            TRUNCATE TABLE #LGInOutDailyCheck 
            INSERT INTO #LGInOutDailyCheck 
            EXEC _SLGInOutDailyCheck               
                     @xmlDocument  = @XmlData,              
                     @xmlFlags     = 2,              
                     @ServiceSeq   = 2619,              
                     @WorkingTag   = '',              
                     @CompanySeq   = @CompanySeq,              
                     @LanguageSeq  = 1,              
                     @UserSeq      = 1,           
                     @PgmSeq       = 5042    
        
            IF EXISTS (SELECT 1 FROM #LGInOutDailyCheck WHERE Status <> 0) 
            BEGIN 
                INSERT INTO #FIFO ( ItemSeq, LotNo, WHSeq, Status, Result ) 
                SELECT ItemSeq, '', 0, Status, Result 
                  FROM #LGInOutDailyCheck 
                 WHERE Status <> 0 

                 RETURN 
            END 

            SELECT 'A' AS WorkingTag, 
                   A.IDX_NO,  
                   A.IDX_NO AS DataSeq, 
                   0 AS Status, 
                   0 AS Selected, 
                   8023042 AS InOutKind, 
                   @OutWHSeq AS InWHSeq, 
                   @OutWHSeq AS OutWHSeq, 
                   C.InOutSeq, 
                   0 AS InOutSerl, 
                   A.ItemSeq, 
                   B.UnitSeq, 
                   A.LotNo AS OriLotNo,
                   B.ItemNo AS LotNo, 
                   A.Qty, 
                   A.Qty AS STDQty, 
                   310 AS InOutType, 
                   0 AS InOutDetailKind, 
                   '��ǰ,����ǰ ��ũ���� ���Լ��� Lot��ü' AS Remark 
              INTO #InOutDailyItem_xml 
              FROM #LotConvert          AS A 
              LEFT OUTER JOIN _TDAItem  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
              LEFT OUTER JOIN #LGInOutDailyCheck AS C ON ( 1 = 1 ) 
        
            SELECT @XmlData = CONVERT(NVARCHAR(MAX),(              
                                                        SELECT *               
                                                          FROM #InOutDailyItem_xml 
                                                          FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS           
                                                     )) 


            -- ���� ����Ÿ ��� ����          
            CREATE TABLE #TLGInOutDailyItem (WorkingTag NCHAR(1) NULL)          
            ExEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock2', '#TLGInOutDailyItem'         
            IF @@ERROR <> 0 RETURN   

            INSERT INTO #TLGInOutDailyItem 
            EXEC _SLGInOutDailyItemCheck               
                     @xmlDocument  = @XmlData,              
                     @xmlFlags     = 2,              
                     @ServiceSeq   = 2619,              
                     @WorkingTag   = '',              
                     @CompanySeq   = @CompanySeq,              
                     @LanguageSeq  = 1,              
                     @UserSeq      = 1,           
                     @PgmSeq       = 5042    
            
            IF EXISTS (SELECT 1 FROM #TLGInOutDailyItem WHERE Status <> 0) 
            BEGIN 
                INSERT INTO #FIFO ( ItemSeq, LotNo, WHSeq, Status, Result ) 
                SELECT ItemSeq, LotNo, 0, Status, Result 
                  FROM #TLGInOutDailyItem 
                 WHERE Status <> 0 

                 RETURN 
            END 
        

            SELECT @XmlData = CONVERT(NVARCHAR(MAX),(              
                                                        SELECT *               
                                                          FROM #LGInOutDailyCheck 
                                                          FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                     )) 
            TRUNCATE TABLE #LGInOutDailyCheck 
            INSERT INTO #LGInOutDailyCheck 
            EXEC _SLGInOutDailySave               
                     @xmlDocument  = @XmlData,              
                     @xmlFlags     = 2,              
                     @ServiceSeq   = 2619,              
                     @WorkingTag   = '',              
                     @CompanySeq   = @CompanySeq,              
                     @LanguageSeq  = 1,              
                     @UserSeq      = 1,           
                     @PgmSeq       = 5042    
        
            -- ���Լ��� Lot��ü ���� ���̺� 
            INSERT INTO KPXCM_TPDSFCMatInputFIFORelation ( CompanySeq, Seq, WorkReportSeq, ItemSerl, InOutType, InOutSeq, LastUserSeq, LastDateTime  )
            SELECT @CompanySeq, @Seq, 0, 0, 310, InOutSeq, 1, GETDATE()
              FROM #LGInOutDailyCheck 
        
            SELECT @XmlData = CONVERT(NVARCHAR(MAX),(              
                                                        SELECT *               
                                                          FROM #TLGInOutDailyItem 
                                                          FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS           
                                                     )) 
        

            ALTER TABLE #TLGInOutDailyItem ADD IsStockQty   NCHAR(1) ---- ��������������  
            ALTER TABLE #TLGInOutDailyItem ADD IsStockAmt   NCHAR(1) ---- ���ݾװ�������  
            ALTER TABLE #TLGInOutDailyItem ADD IsLot        NCHAR(1) ---- Lot��������  
            ALTER TABLE #TLGInOutDailyItem ADD IsSerial     NCHAR(1) ---- �ø����������  
            ALTER TABLE #TLGInOutDailyItem ADD IsItemStockCheck   NCHAR(1) ---- ǰ�������� üũ  
            ALTER TABLE #TLGInOutDailyItem ADD InOutDate    NCHAR(8) ----  üũ  
            ALTER TABLE #TLGInOutDailyItem ADD CustSeq    INT ----  üũ  
            ALTER TABLE #TLGInOutDailyItem ADD SalesCustSeq    INT ----  üũ  
            ALTER TABLE #TLGInOutDailyItem ADD IsTrans    NCHAR(1) ----  üũ  

            TRUNCATE TABLE #TLGInOutDailyItem 
            INSERT INTO #TLGInOutDailyItem 
            EXEC _SLGInOutDailyItemSave               
                     @xmlDocument  = @XmlData,              
                     @xmlFlags     = 2,              
                     @ServiceSeq   = 2619,              
                     @WorkingTag   = '',              
                     @CompanySeq   = @CompanySeq,              
                     @LanguageSeq  = 1,              
                     @UserSeq      = 1,           
                     @PgmSeq       = 5042    
        END -- workingtag end 
        
        INSERT INTO #FIFO ( ItemSeq, LotNo, WHSeq ) 
        SELECT @ItemSeq, A.ItemNo, @OutWHSeq 
          FROM _TDAItem AS A WITH(NOLOCK)  
         WHERE A.CompanySeq = @CompanySeq 
           AND A.ItemSeq = @ItemSeq 

    END 
    
    -- ��ǰ����ǰ, �巳���� 
    ELSE IF @IsGoodItem = '1' AND @IsTank = '0' 
    BEGIN
        INSERT INTO #FIFO ( ItemSeq, LotNo, WHSeq ) 
        SELECT @ItemSeq, @LotNo, @WHSeq
    END 
    

    --select * FROM  #FIFO 




RETURN 

--GO 

--begin tran 
--exec KPXCM_SPDSFCWorkReportExcept_POP_FIFO 2, 295,	1115990703	,NULL,	1603.00000	,'1',	'20161101'	,'A',	63250,	0,	229839
--rollback 

----select * from _TDAItem where itemseq = 318 