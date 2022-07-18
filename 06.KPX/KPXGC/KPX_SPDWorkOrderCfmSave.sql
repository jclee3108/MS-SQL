  
IF OBJECT_ID('KPX_SPDWorkOrderCfmSave') IS NOT NULL   
    DROP PROC KPX_SPDWorkOrderCfmSave  
GO  
  
-- v2014.10.21 
  
-- �۾����ü�����-���� by ����õ (_SPDMPSProdPlanWorkOrderSaveNotCapa ���)
CREATE PROC KPX_SPDWorkOrderCfmSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    DECLARE @docHANDle      INT, 
            @FactUnit       INT, 
            @ProdDateFr     NCHAR(8), 
            @ProdDateTo     NCHAR(8), 
            @WorkcenterSeq  INT, 
            @ItemName       NVARCHAR(100), 
            @ItemNo         NVARCHAR(100), 
            @Spec           NVARCHAR(100), 
            @ProdWeekSeq    INT, 
            @EnvValue       NVARCHAR(100), 
            @Dec            INT, 
            @Count          INT, 
            @MessageType    INT, 
            @Status         INT, 
            @Results        NVARCHAR(250), 
            @ExsistCnt      INT, 
            @QtyPoint       INT 
    
    CREATE TABLE #TPDSFCWorkOrder (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDSFCWorkOrder'   
    IF @@ERROR <> 0 RETURN    
    
    
    CREATE TABLE #TPDMPSDailyProdPlan 
    (
        ProdPlanSeq     INT, 
        FactUnit        INT, 
        SrtDate         NCHAR(12), 
        EndDate         NCHAR(12) 
    )
    INSERT INTO #TPDMPSDailyProdPlan (ProdPlanSeq, FactUnit, SrtDate, EndDate)
    SELECT A.ProdPlanSeq, A.FactUnit, A.SrtDate + A.WorkCond1, A.EndDate + A.WorkCond2 
      FROM #TPDSFCWorkOrder         AS B 
      JOIN _TPDMPSDailyProdPlan     AS A ON ( (A.SrtDate + WorkCond1 BETWEEN B.FrStdDate + FrTime AND B.ToStdDate + ToTime) AND B.WorkCenterSeq = A.WorkCenterSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND ProdPlanSeq NOT IN (SELECT ProdPlanSeq 
                                 FROM _TPDSFCWorkOrder 
                                WHERE CompanySeq = @CompanySeq 
                                  AND WorkCenterSeq = B.WorkCenterSeq 
                                  AND (WorkDate + WorkStartTime BETWEEN B.FrStdDate + FrTime AND WorkCond1 + WorkEndTime) 
                              )
    
    ------------------------------------------------------------------------------------------
    -- üũ1, �۾����� �ߺ��Ǵ� �����Ͱ� �����Ͽ� �۾����ø� ������ �� �����ϴ�. 
    ------------------------------------------------------------------------------------------
    IF EXISTS (SELECT 1 
                 FROM #TPDMPSDailyProdPlan AS A 
                 LEFT OUTER JOIN #TPDMPSDailyProdPlan AS B ON ( 1 = 1 )
                WHERE (B.SrtDate BETWEEN A.SrtDate AND A.EndDate  
                  OR B.EndDate BETWEEN A.SrtDate AND A.EndDate ) 
                 AND A.SrtDate <> B.EndDate 
                 AND A.EndDate <> B.SrtDate 
                 AND A.ProdPlanSeq <> B.ProdPlanSeq 
                ) 
    BEGIN 
        UPDATE #TPDSFCWorkOrder
           SET Result = '�۾����� �ߺ��Ǵ� �����Ͱ� �����Ͽ� �۾����ø� ������ �� �����ϴ�.', 
               MessageType = 1234, 
               Status = 1234 
        
        SELECT * FROM #TPDSFCWorkOrder 
        RETURN 
    END 
    
    
    ------------------------------------------------------------------------------------------
    -- üũ2, ó���� �����Ͱ� �����ϴ�. 
    ------------------------------------------------------------------------------------------
    
    IF NOT EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlan) 
    BEGIN
        UPDATE #TPDSFCWorkOrder
           SET Result = 'ó���� �����Ͱ� �����ϴ�.', 
               MessageType = 1234, 
               Status = 1234 
          FROM #TPDSFCWorkOrder 
         WHERE Status = 0 
         
        SELECT * FROM #TPDSFCWorkOrder 
        RETURN 
    END 
    
    -- �����ȹ Ȯ���ϱ� 
    UPDATE A
       SET CfmCode = '1', 
           CfmDate = CONVERT(nCHAR(8), CONVERT(DATETIME, GETDATE()),112), 
           CfmEmpSeq = (SELECT EmpSeq FROM _TCAUSer WHERE CompanySeq = @CompanySeq AND USerseq = @UserSeq), 
           LastDateTime = GETDATE()
      FROM _TPDMPSDailyProdPlan_Confirm AS A 
      JOIN #TPDMPSDailyProdPlan         AS B ON ( A.CfmSeq = B.ProdPlanSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
    
    
    -- �Ǹ�/��ǰ ���� �Ҽ��� �ڸ���     --  12.04.25 BY �輼ȣ 
    EXEC dbo._SCOMEnv @CompanySeq,8,@UserSeq,@@PROCID,@QtyPoint OUTPUT
    
    -- ȯ�漳���� �������� (�Ҽ��� �ڸ��� 5)
    EXEC dbo._SCOMEnv @CompanySeq,5,0,@@PROCID,@EnvValue OUTPUT
    SELECT @Dec = ISNULL(@EnvValue, 0)
    
    DECLARE @WeekDay    NVARCHAR(10), 
            @WeekSeq    INT, 
            @Cnt        INT, 
            @CheckDate  NCHAR(8),
            @SrtDate    NCHAR(8), 
            @EndDate    NCHAR(8) 
    
    DECLARE @DailyProdPlan TABLE
    (
        FactUnit    INT,
        ProdPlanSeq INT,
        ProdPlanNo  NVARCHAR(30),
        WorkDate    NCHAR(8),
        ItemSeq     INT,
        BOMRev      NCHAR(2),
        ProcRev     NCHAR(2),
        ProdQty     DECIMAL(19,5),
        UnitSeq     INT,
        SMSource    INT,
        EndDate     NCHAR(8),
        DeptSeq     INT,
        BOMUnitSeq  INT,                -- BOM����
        BOMUnitQty  DECIMAL(19, 5),      -- BOM���� ����(��ȹ������ BOM������ ȯ��)        11.11.11 �輼ȣ �߰�  
        WorkCond1   NVARCHAR(500),        -- �۾����� 2012. 1. 13 hkim �߰�  
        SrtTime     NCHAR(4), 
        EndTime     NCHAR(4)
    ) 
    INSERT INTO @DailyProdPlan (
                                FactUnit, ProdPlanSeq, ProdPlanNo, WorkDate, ItemSeq, 
                                BOMRev, ProcRev, ProdQty, UnitSeq, SMSource, 
                                EndDate,DeptSeq, WorkCond1, SrtTime, EndTime 
                               ) 
    SELECT B.FactUnit, A.ProdPlanSeq, A.ProdPlanNo, A.SrtDate, A.ItemSeq, 
           A.BOMRev, A.ProcRev, A.ProdQty, A.UnitSeq, A.SMSource, 
           A.EndDate, A.DeptSeq, A.EndDate, WorkCond1, WorkCond2 
      FROM _TPDMPSDailyProdPlan As A 
      JOIN #TPDMPSDailyProdPlan AS B ON A.ProdPlanSeq = B.ProdPlanSeq AND A.FactUnit = B.FactUnit
     WHERE A.CompanySeq = @CompanySeq
    
    -- ��ȹ����(�������)�� BOM������������ ȯ��            11.11.11 �輼ȣ �߰� 
    UPDATE A  
       SET A.BOMUnitSeq = B.STDUnitSeq,  
           A.BOMUnitQty = CASE WHEN UP.ConvDen * US.ConvNum * US.ConvDen <> 0 
                               THEN A.ProdQty * (UP.ConvNum / UP.ConvDen) / (US.ConvNum / US.ConvDen)    
                               ELSE A.ProdQty    
                               END 
      FROM @DailyProdPlan  AS A 
      JOIN _TDAItemDefUnit AS B WITH(NOLOCK)  ON A.ItemSeq   = B.ItemSeq  
                                              AND @CompanySeq = B.CompanySeq
                                              AND B.UMModuleSeq = 1003004
      JOIN _TDAItemUnit    AS US WITH(NOLOCK)  ON B.ItemSeq = US.ItemSeq  
                                                AND B.CompanySeq = US.CompanySeq  
                                                AND B.STDUnitSeq = US.UnitSeq  
      JOIN _TDAItemUnit    AS UP WITH(NOLOCK)  ON A.ItemSeq = UP.ItemSeq  
                                                AND @CompanySeq = UP.CompanySeq  
                                                AND A.UnitSeq = UP.UnitSeq   
    
    /*****************************************************************************************************************************/
    -- ����ǰ�� ��ġSeq ���
    DECLARE @TempBatchItem TABLE
    (
        FactUnit    INT,
        ProdPlanSeq INT,
        ItemSeq     INT,
        BatchSeq    INT
    )
    INSERT INTO @TempBatchItem
    SELECT A.FactUnit, A.ProdPlanSeq, A.ItemSeq, B.BatchSeq
      FROM @DailyProdPlan AS A 
      JOIN _TPDBOMBatch AS B With(NOLOCK) ON A.FactUnit = B.FactUnit 
                                         AND A.ItemSeq = B.ItemSeq 
                                         AND B.CompanySeq = @CompanySeq
                                         AND A.EndDate >= B.DateFr 
                                         AND A.EndDate <= B.DateTo
    -- select * from _TPDBOMBatch where ItemSEq = 14768
    /****************************************************************************************************************************/
    
    
    SELECT @EndDate = MAX(WorkDate) FROM @DailyProdPlan
    SELECT @SrtDate = CONVERT(NCHAR(8),DATEADD(M,-12, CONVERT(DATETIME, @EndDate)),112)
    
    
    -- ���� �۾���ȹ ����
    DELETE _TPDMPSWorkOrder
      FROM _TPDMPSWorkOrder AS A 
      JOIN @DailyProdPlan AS B ON A.ProdPlanSeq = B.ProdPlanSeq AND A.FactUnit = B.FactUnit 
      JOIN #TPDMPSDailyProdPlan AS C ON A.ProdPlanSeq = C.ProdPlanSeq AND A.FactUnit = C.FactUnit
     WHERE A.CompanySeq = @CompanySeq 
    
    
    DECLARE @ItemProcInfo TABLE
    (
        FactUnit        INT,
        ItemSeq         INT,
        BOMRev          NCHAR(2),
        ProcRev         NCHAR(2),
        ProcSeq         INT,
        WorkCenterSeq   INT,
        ProcNo          INT,
        IsProcQC        NCHAR(1),
        IsLastProc      NCHAR(1),
        TimeUnit        INT,
        StdWorkTime     DECIMAL(19,5),
        ToProcNo        INT,
        SMToProcMovType INT,
        ISBatch         NCHAR(1),
        BatchSize       Decimal(19,5)
    )
    -- ��ǰ����������ũ���Ϳ��� MIN(�켱����)�� MIN(Serl) ��ũ���͸� �۾����� ��� ��ũ���ͷ� �Ѵ�.     -- 11.11.08 �輼ȣ �߰�   
    SELECT A.FactUnit, X.ItemSeq, X.BOMRev, X.ProcRev, B.ProcSeq, MIN(C.Serl) AS Serl  
      INTO #TMP_ItemProcWC  
      FROM @DailyProdPlan             AS X       
      JOIN _TPDROUItemProcRevFactUnit AS A WITH(NOLOCK) ON X.ItemSeq = A.ItemSeq       
                                                       AND X.BomRev = A.BomRev       
                                                       AND X.ProcRev = A.ProcRev       
                                                       AND X.FactUnit = A.FactUnit      
      JOIN _TPDROUItemProcRev         AS D WITH(NOLOCK) ON A.ItemSeq = D.ItemSeq       
                                                       AND a.ProcRev = D.ProcRev        
                                                       AND D.isProcType = '1'       
                                                       AND D.CompanySeq = @ComPanySeq      
      JOIN _TPDProcTypeItem           AS B WITH(NOLOCK) ON D.ProcTypeSeq = B.ProcTypeSeq       
                                                         AND A.ComPanySeq = B.ComPanySeq      
      JOIN _TPDROUItemProcWC          AS C WITH(NOLOCK) ON A.ItemSeq = C.ItemSeq       
                                                       AND A.ProcRev = C.ProcRev       
                                                       AND B.ProcSeq = C.ProcSeq       
                                                       AND B.ComPanySeq = C.ComPanySeq       
                                                       AND C.FactUnit = A.FactUnit      
     WHERE A.ComPanySeq = @ComPanySeq      
       AND B.ProcSeq <> 0      
       AND C.Ranking = (SELECT MIN(Ranking) FROM _TPDROUItemProcWC   
                          WHERE CompanySeq = @CompanySeq AND ItemSeq = C.ItemSeq AND ProcRev = C.ProcRev AND ProcSeq = C.ProcSeq AND FactUnit = C.FactUnit)     
     GROUP BY A.FactUnit, X.ItemSeq, X.BOMRev, X.ProcRev, B.ProcSeq   
    
    
    /*
    ǰ�񺰰������̺�(_TPDROUItemProc)�� �ʱ�ER �� ��� �ȵǴٰ�, ��ǰ�������ҿ����翡�� ���ǰ� �Ǿ����Ƿ�,
    ������ �ߺ����� �������ʵ��� �ش� ������ �ּ�ó��              -- 13.08.14 BY �輼ȣ 
    */
    INSERT INTO @ItemProcInfo(FactUnit,ItemSeq,    BOMRev,   ProcRev,     ProcSeq,  WorkCenterSeq,   ProcNo,    
                               IsProcQC,IsLastProc, TimeUnit, StdWorkTime, ToProcNo, SMToProcMovType, ISBatch, BatchSize )      
    SELECT DISTINCT A.FactUnit, X.ItemSeq,    X.BOMRev,   X.ProcRev,     B.ProcSeq,  C.WorkCenterSeq, B.ProcNo,    
            B.IsProcQC, B.IsLastProc, C.TimeUnit, C.StdWorkTime, B.ToProcNo, B.SMToProcMovQty,     C.ISBatch, 0  
      FROM @DailyProdPlan             AS X       
      JOIN _TPDROUItemProcRevFactUnit AS A WITH(NOLOCK) ON X.ItemSeq = A.ItemSeq       
                                                       AND X.BomRev = A.BomRev       
                                                       AND X.ProcRev = A.ProcRev       
                                                       AND X.FactUnit = A.FactUnit      
      JOIN _TPDROUItemProcRev         AS D WITH(NOLOCK) ON A.ItemSeq = D.ItemSeq       
                                                       AND a.ProcRev = D.ProcRev       
                                                       AND D.isProcType = '1'       
                                                     AND D.CompanySeq = @ComPanySeq      
      JOIN _TPDProcTypeItem           AS B WITH(NOLOCK) ON D.ProcTypeSeq = B.ProcTypeSeq       
                                                       AND A.ComPanySeq = B.ComPanySeq      
      JOIN _TPDROUItemProcWC          AS C WITH(NOLOCK) ON A.ItemSeq = C.ItemSeq       
                                                       AND A.ProcRev = C.ProcRev       
                                                       AND B.ProcSeq = C.ProcSeq       
                                                       AND B.ComPanySeq = C.ComPanySeq       
                                                       AND C.FactUnit = A.FactUnit   
      JOIN #TMP_ItemProcWC            AS E WITH(NOLOCK)  ON C.ItemSeq = E.ItemSeq       
                                                       AND C.ProcRev = E.ProcRev       
                                                       AND C.ProcSeq = E.ProcSeq         
                                                       AND C.FactUnit = E.FactUnit    
                                                       AND C.Serl     = E.Serl   
     WHERE A.ComPanySeq = @ComPanySeq      
       AND B.ProcSeq <> 0     
    
    
    
    UPDATE @ItemProcInfo
       SET ISBatch = B.ISBatch,  
           BatchSize = B.BatchSize
      FROM @ItemProcInfo AS A 
      JOIN _TPDROUItemProcWC AS B ON A.FactUnit = B.FactUnit AND A.ItemSeq = B.ItemSeq AND A.ProcRev = B.ProcRev AND A.ProcSeq = B.ProcSeq AND A.Workcenterseq = B.Workcenterseq
    
    
    DELETE FROM @ItemProcInfo WHERE TimeUnit = 0
    
    DECLARE @ItemProcAssy TABLE
    (
        ItemSeq INT,
        BOMRev  NCHAR(2),
        ProcRev NCHAR(2),
        ProcSeq INT,
        AssyItemSeq INT,
        AssyQtyNumerator DECIMAL(19,5),
        AssyQtyDenominator DECIMAL(19,5)
    )
    INSERT INTO @ItemProcAssy
    SELECT B.ItemSeq, B.BOMRev, B.ProcRev,B.ProcSeq,B.AssyItemSeq,B.AssyQtyNumerator,B.AssyQtyDenominator    
      FROM @DailyProdPlan AS A 
      JOIN _TPDROUItemProcMat AS B ON A.ItemSeq = B.ItemSeq 
                                   AND A.BOMRev = B.BOMRev 
                                   AND A.ProcRev = B.ProcRev 
                                   AND B.ProcSeq <> 0 
                                   AND AssyItemSeq <> 0 
                                   AND B.CompanySeq = @CompanySeq
     GROUP BY B.ItemSeq, B.BOMRev, B.ProcRev,B.ProcSeq,B.AssyItemSeq,B.AssyQtyNumerator,B.AssyQtyDenominator 
    
    CREATE TABLE #TPDMPSWorkOrder
    (
        Seq                     INT IDENTITY,
        CompanySeq    INT,-- 0 ���γ����ڵ�
        FactUnit    INT ,--0 ��������
        ProdPlanSeq    INT ,--0 �����ȹ�����ڵ�
        WorkOrderSeq   INT,-- 0 �۾����ó����ڵ�
        WorkOrderNo    NCHAR(20),-- 20 �۾����ù�ȣ
        WorkOrderSerl   INT ,--0 �۾����ü���
        WorkOrderDate   NCHAR(8),-- 8 �۾�������
        WorkPlanSerl   INT,-- 0 �۾���ȹ����
        DailyWorkPlanSerl     INT,-- 0 ���ں��۾���ȹ����
        WorkCenterSeq   INT,-- 0 ��ũ���ͳ����ڵ�
        GoodItemSeq    INT,-- 0 ��ǰ�ڵ�
        ProcSeq     INT,-- 0 ���������ڵ�
        AssyItemSeq    INT,-- 0 ����ǰ�ڵ�
        ProdUnitSeq    INT,-- 0 �������
        OrderQty    DECIMAL(19,5),-- 19 ���ü���
        StdUnitQty    DECIMAL(19,5),-- 19 ���ش�������
        WorkDate    NCHAR(8),-- 8 �۾���
        WorkStartTime   NCHAR(4),-- 4 �۾����۽ð�
        WorkENDTime    NCHAR(4),-- 4 �۾�����ð�
        ChainGoodsSeq   INT,-- 0 ����ǰ�����ڵ�
        WorkType    INT,-- 0 �۾�����
        DeptSeq     INT,-- 0 ����μ��ڵ�
        ItemUnitSeq    INT,-- 0 ��ǰ�����ڵ�
        ProcRev     NCHAR(2),-- 2 �����帧����
        Remark     NVARCHAR(200),-- 200 ���
        IsProcQC    NCHAR(1),-- 1 �����˻翩��
        IsLastProc    NCHAR(1),-- 1 ������������
        IsPjt     NCHAR(1),-- 1 ������Ʈ����
        PjtSeq     INT,-- 0 ������Ʈ�����ڵ�
        WBSSeq     INT,-- 0 WBS�����ڵ�
        ItemBomRev    NCHAR(2),
        ProcNo     INT,
        ToProcNo    INT,
        SMToProcMovType   INT,
        LastUserSeq    INT,-- 0 �۾���
        LastDateTime   DATETIME, -- 0 �۾���
        SMSource                INT,
        WorkTime                DECIMAL(19,5),
        StdWorkTime             DECIMAL(19,5),
        TimeUnit                INT,
        ISBatch                 NCHAR(1),
        BatchSizeQty            DECIMAL(19,5),
        WorkCond1       NVARCHAR(500) 
    )
    
    -- �����ȹ �Ǻ� �۾����� �۾�����/����ð� �������� (Default : 09:00 ~ 18:00)     -- 13.01.08 BY �輼ȣ
    SELECT A.ProdPlanSeq, 
          SrtTime AS SrtTime, 
          EndTime AS EndTime
      INTO #TMP_TPDBaseProdWorkHour
      FROM @DailyProdPlan                                AS A 
    
    INSERT INTO #TPDMPSWorkOrder
    (
        CompanySeq    ,--INT 0 ���γ����ڵ�
        FactUnit     ,--INT 0 ��������
        ProdPlanSeq    ,--INT 0 �����ȹ�����ڵ�
        WorkOrderSeq   ,--INT 0 �۾����ó����ڵ�
        WorkOrderNo    ,--NCHAR 20 �۾����ù�ȣ
        WorkOrderSerl   ,--INT 0 �۾����ü���
        WorkOrderDate   ,--NCHAR 8 �۾�������
        WorkPlanSerl   ,--INT 0 �۾���ȹ����
        DailyWorkPlanSerl     ,--INT 0 ���ں��۾���ȹ����
        WorkCenterSeq   ,--INT 0 ��ũ���ͳ����ڵ�
        GoodItemSeq    ,--INT 0 ��ǰ�ڵ�
        ProcSeq      ,--INT 0 ���������ڵ�
        AssyItemSeq    ,--INT 0 ����ǰ�ڵ�
        ProdUnitSeq    ,--INT 0 �������
        OrderQty     ,--DECIMAL 19 ���ü���
        StdUnitQty    ,--DECIMAL 19 ���ش�������
        WorkDate     ,--NCHAR 8 �۾���
        WorkStartTime   ,--NCHAR 4 �۾����۽ð�
        WorkENDTime    ,--NCHAR 4 �۾�����ð�
        ChainGoodsSeq   ,--INT 0 ����ǰ�����ڵ�
        WorkType     ,--INT 0 �۾�����
        DeptSeq      ,--INT 0 ����μ��ڵ�
        ItemUnitSeq    ,--INT 0 ��ǰ�����ڵ�
        ProcRev      ,--NCHAR 2 �����帧����
        Remark      ,--NVARCHAR 200 ���
        IsProcQC     ,--NCHAR 1 �����˻翩��
        IsLastProc    ,--NCHAR 1 ������������
        IsPjt       ,--NCHAR 1 ������Ʈ����
        PjtSeq      ,--INT 0 ������Ʈ�����ڵ�
        WBSSeq      ,--INT 0 WBS�����ڵ�
        ItemBomRev,
        ProcNo,
        ToProcNo,
        SMToProcMovType,
        LastUserSeq    ,--INT 0 �۾���
        LastDateTime   , --DATETIME 0 �۾���
        SMSource,
        WorkTime,
        StdWorkTime,
        TimeUnit,
        ISBatch,
        BatchSizeQty,
        WorkCond1        
    )
    SELECT  
            @CompanySeq,
            A.FactUnit,
            a.ProdPlanSeq,
            0,
            '',
            0,
            A.WorkDate,
            0,
            0,
            F.WorkCenterSeq,

            a.ItemSeq,
            B.ProcSeq,
            c.AssyItemSeq,
            ISNULL((SELECT STDUnitSeq FROM _TDAItemDefUnit WHERE ItemSeq = c.AssyItemSeq AND UMModuleSeq = 1003003 AND ComPanySeq = @ComPanySeq),A.UnitSeq),    
            CASE WHEN ISNULL(C.AssyQtyDenominator,0) = 0 THEN a.BOMUnitQty ELSE a.BOMUnitQty * C.AssyQtyNumerator / C.AssyQtyDenominator END,    

            CASE WHEN ISNULL(C.AssyQtyDenominator,0) = 0 THEN a.BOMUnitQty ELSE a.BOMUnitQty * C.AssyQtyNumerator / C.AssyQtyDenominator END,   
            A.WorkDate,
            T.SrtTime,
            T.EndTime,
            0,

            6041001,
            F.DeptSeq,
            A.UnitSeq,
            A.ProcRev,
            '',
            B.IsProcQC,
            B.IsLastProc,
            '0',
            0,
            0,
            A.BOMRev,
            ISNULL(B.ProcNo,0),
            B.ToProcNo,
            B.SMToProcMovType,
            @UserSeq,
            GETDATE(),
            A.SMSource,
            -- CEILING((CASE WHEN ISNULL(C.AssyQtyDenominator,0) = 0 THEN 0 ELSE a.ProdQty * C.AssyQtyNumerator / C.AssyQtyDenominator END) * B.StdWorkTime),
            CEILING((CASE WHEN ISNULL(C.AssyQtyDenominator,0) = 0 THEN 0 ELSE a.ProdQty * C.AssyQtyNumerator / C.AssyQtyDenominator * ISNULL(D.WorkRate,0) /100 END) / B.StdWorkTime),  
            B.StdWorkTime,
            B.TimeUnit,
            B.ISBatch,
            B.BatchSize,
            A.WorkCond1 -- ����ð� 
    
      FROM @DailyProdPlan AS A 
      JOIN @ItemProcInfo AS B ON A.ItemSeq = B.ItemSeq AND A.BomRev = B.BomRev AND A.ProcRev = B.ProcRev  
      JOIN #TMP_TPDBaseProdWorkHour AS T ON A.ProdPlanSeq = T.ProdPlanSeq   
      LEFT OUTER JOIN @ItemProcAssy AS C ON B.ItemSeq = C.ItemSeq 
                                        AND B.ProcRev = C.ProcRev 
                                        AND B.Bomrev = C.Bomrev 
                                        AND B.ProcSeq = C.ProcSeq
      LEFT OUTER JOIN _TPDROUItemProcWC  AS D ON B.ItemSeq = D.ItemSeq 
                                             AND B.ProcRev = D.ProcRev 
                                             AND B.ProcSeq = D.ProcSeq 
                                             AND B.WorkCenterSeq = D.WorkCenterSeq
                                             AND B.FactUnit = D.FactUnit 
                                             AND D.Ranking = 1
                                             AND D.CompanySeq = @CompanySeq 
      LEFT OUTER JOIN _TPDBaseWorkcenter AS F ON B.WorkcenterSeq = F.WorkcenterSeq 
                   AND F.Companyseq = @Companyseq                                                              
     Order by a.ProdPlanSeq, B.ProcNo
    
    UPDATE #TPDMPSWorkOrder
       SET AssyItemSeq = GoodItemSeq
     WHERE ISNULL(AssyItemSeq,0) = 0
       and IsLastProc = '1'
    -- ����ǰ �ν��� �ݿ�      
           
    UPDATE #TPDMPSWorkOrder      
       SET OrderQty = A.OrderQty + (A.OrderQty * B.InLossRate / 100)      
      FROM #TPDMPSWorkOrder AS A JOIN _TPDROUItemProcMat AS B ON A.CompanySeq = B.CompanySeq       
                                                             AND A.GoodItemSeq = B.ItemSeq       
                                                             AND A.ItemBomRev = B.BomRev      
                                                             AND A.ProcRev = B.ProcRev      
                                                             AND A.AssyItemSeq = B.MatItemSeq      
     WHERE ISNULL(A.AssyItemSeq,0) <> 0    
    
    /****************************************************************************************************************/    
    
    -- �۾����ü���(BOM����) ��������� ȯ��            -- 11.11.11 �輼ȣ 
    UPDATE A
       SET A.OrderQty = A.OrderQty * (US.ConvNum / US.ConvDen) / (UP.ConvNum / UP.ConvDen)  ,
           A.StdUnitQty = A.StdUnitQty * (US.ConvNum / US.ConvDen) / (UP.ConvNum / UP.ConvDen)  
      FROM #TPDMPSWorkOrder AS A  
      JOIN _TDAItemDefUnit    AS B WITH(NOLOCK)  ON A.AssyItemSeq = B.ItemSeq 
                                                AND @CompanySeq   = B.CompanySeq 
                                                AND UMModuleSeq   = 1003004
      JOIN _TDAItemUnit       AS US WITH(NOLOCK)  ON B.ItemSeq = US.ItemSeq  
                                                 AND B.CompanySeq = US.CompanySeq  
                                                 AND B.STDUnitSeq = US.UnitSeq  
      JOIN _TDAItemUnit       AS UP WITH(NOLOCK)  ON A.AssyItemSeq = UP.ItemSeq  
                                                 AND @CompanySeq = UP.CompanySeq  
                                                 AND A.ProdUnitSeq = UP.UnitSeq 
    
    -- ȯ���� �۾����ü���(�������)�� �۾��ð� ����           -- 11.11.11 �輼ȣ 
    UPDATE A
       SET A.WorkTime = CEILING(A.OrderQty * ISNULL(D.WorkRate,0) /100 / A.StdWorkTime)
      FROM #TPDMPSWorkOrder AS A  
      LEFT OUTER JOIN _TPDROUItemProcWC AS D ON A.GoodItemSeq = D.ItemSeq     
                                            AND A.ProcRev = D.ProcRev     
                                            AND A.ProcSeq = D.ProcSeq     
                                            AND A.WorkCenterSeq = D.WorkCenterSeq    
                                            AND A.FactUnit = D.FactUnit     
                                            AND A.CompanySeq = D.CompanySeq
    
    -- ���ش��� ȯ��ǵ���      -- 12.04.25 BY �輼ȣ
    UPDATE A
       SET StdUnitQty = CASE WHEN A.ProdUnitSeq <> B.UnitSeq THEN A.OrderQty * (C.ConvNum / C.ConvDen) ELSE A.OrderQty END
      FROM #TPDMPSWorkOrder        AS A
      JOIN _TDAItem                AS B ON @CompanySeq = B.CompanySeq
                                       AND A.AssyItemSeq = B.ItemSeq
      JOIN _TDAItemUnit            AS C ON @CompanySeq = C.CompanySeq
                                       AND A.AssyItemSeq = C.ItemSeq
                                       AND A.ProdUnitSeq = C.UnitSeq
    /****************************************************************************************************************/    
    
    
    -- �۾����� ��ȣ, ���� �����ϱ�    
    DECLARE @Seq                INT, 
             @ProdPlanSeq       INT, 
             @WorkDate          NCHAR(8), 
             @chkProdPlanSeq    INT, 
             @WorkOrderNo       NVARCHAR(20),
             @WorkOrderSeq      INT, 
             @WorkOrderSerl     INT, 
             @DeptSeq           INT,
             @NoLen             INT,
             @CountNo           INT,            -- 2011. 4. 29 �����ȹ���� �۾����ø� �����Ҷ� 1������ ���������� �����ǵ��� �߰�    
             @WorkOrderNoOld    NVARCHAR(20)    -- 2011. 5. 6 �����ȹ��ȣ�� ����, �۾����� �ڵ�� �ٸ� ��� �ߺ��ؼ� ä�� �� �� ����    
    
    SELECT @Seq = 0, @chkProdPlanSeq = 0
    
    ---------------------------------------------------------------------------------------------------------------------------------------------------  
    
    -- ȯ�漳�� (6214 �����ȹ��ȣ�� �۾����ù�ȣ�� ���) --12.02.23 �輼ȣ �߰�
    DECLARE @IsUseProdPlanNo    NCHAR(1)                
    EXEC dbo._SCOMEnv @CompanySeq,6214,@UserSeq,@@PROCID,@IsUseProdPlanNo OUTPUT     
    WHILE(1=1)      
    BEGIN      
    
        SET ROWCOUNT 1      
    
        SELECT @Seq = Seq, 
               @ProdPlanSeq = ProdPlanSeq, 
               @WorkDate =  WorkOrderDate , 
               @WorkCenterSeq = WorkCenterSeq,    
               @FactUnit = FactUnit     
          FROM #TPDMPSWorkOrder      
         WHERE Seq > @Seq      
        ORDER BY Seq      
        
        IF @@ROWCOUNT = 0  BREAK      
        
        SET ROWCOUNT 0      
        
        
        -- ��ũ���� �����ڸ� ����ϴ� ���    
        IF EXISTS (select * from _TCOMCreateNoDefine  WHERE TableName = '_TPDSFCWorkOrder' and Composition like '%E%')    
        BEGIN    
            
            IF @ProdPlanSeq <> @chkProdPlanSeq      
            
            BEGIN      
                
                SELECT @DeptSeq = DeptSeq FROM @DailyProdPlan WHERE ProdPlanSeq = @ProdPlanSeq    
               
                -- �����ȹ ��ȣ �������� 2011. 3. 11 hkim    
                SELECT @WorkOrderNo = ProdPlanNo FROM @DailyProdPlan WHERE ProdPlanSeq = @ProdPlanSeq    
                
                -- �����ȹ���� �۾����� ������, ���� �۾����� ��ȣ + '0001', '0002' ������ ���� ���� 2011. 3. 4 hkim    
                SELECT @NoLen = LEN(@WOrkOrderNo)    
                
                -- ����ǰ �����ȹ�� Ǯ�� ���� �̹� ������ �۾����� �Ǽ��� ������ ������ 2011. 4. 20 hkim    
                IF EXISTS (SELECT 1 FROM _TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND  WorkOrderNo LIKE @WorkOrderNo + '%')    
                BEGIN    
                 --SELECT @ExsistCnt = COUNT(1) FROM _TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%'     
                 -- 2011. 5. 17 hkim �߰��� ������ �� ��� Row Count�δ� �ߺ� ä���� �� �� �־ �Ʒ��� ���� Max �� ���������� ����
                    IF ISNUMERIC((SELECT SUBSTRING(MAX(WorkORderNo), @NoLen + 1, 4)  FROM _TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%')) = 1
                    BEGIN  
                        SELECT @ExsistCnt =  CONVERT(INT, SUBSTRING(MAX(WorkORderNo), @NoLen + 1, 4))  FROM _TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%'     
                    END
                    ELSE
                        SELECT @ExsistCnt = 0   
                END                    
                ELSE     
                BEGIN    
                    SELECT @ExsistCnt = 0    
                END      
                -- �ӽ����̺� �ش� �۾����� �Ǽ��� ������ ������ 2011. 5. 12 hkim    
                IF EXISTS (SELECT 1 FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND  WorkOrderNo LIKE @WorkOrderNo + '%')    
                BEGIN    
                SELECT @CountNo = COUNT(1) FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%'     
                -- 2011. 5. 17 row count �� �ƴ� Max ������     
                               --SELECT @CountNo = CONVERT(INT, SUBSTRING(MAX(WorkORderNo), @NoLen + 1, 4)) FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%'     
                END                    
                ELSE     
                BEGIN    
                    SELECT @CountNo = 0    
                END       
                   
                
                EXEC @WorkOrderSeq = dbo._SCOMCreateSeq @CompanySeq, '_TPDSFCWorkOrder', 'WorkOrderSerl', 1      
                --EXEC @WorkOrderSerl = dbo._SCOMCreateSeq @CompanySeq, '_TPDSFCWorkOrder', 'WorkOrderSerl', 1      
                
                -- �����ȹ���� ����, �۾������Է�ȭ�鿡�� ����. �� �ΰ��� ���� �� ��� �ߺ�Ű�� �߻��� �� �־ �Ʒ� ���� �߰� 2010. 12. 15 hkim    
                SELECT @WorkOrderSeq = @WorkOrderSeq + 1    
                  
                IF  @IsUseProdPlanNo <> '1'  -- �����ȹ��ȣ �۾����ù�ȣ�� �����Ұ�� 0001, 0002 �� ä�� �ǵ���  --12.02.23 �輼ȣ �߰�
                BEGIN  
                    -- 2011. 4. 20 hkim Seq�� 10�� �Ѿ �� �־ �Ʒ��� ���� ����  -- 2011. 4. 29 �����ȹ���� �۾����ø� �����Ҷ� 1������ ���������� �����ǵ��� @Seq���� @CountNo�� ����    
                    IF @CountNo + @ExsistCnt < 9      
                        SELECT @WorkOrderNo = @WorkOrderNo + '000' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)        
                    ELSE IF @CountNo + @ExsistCnt BETWEEN 9 AND 98      
                        SELECT @WorkOrderNo = @WorkOrderNo + '00' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)        
                    ELSE IF @CountNo + @ExsistCnt BETWEEN 99 AND 998      
                        SELECT @WorkOrderNo = @WorkOrderNo + '0' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)        
                    ELSE                           
                        SELECT @WorkOrderNo = @WorkOrderNo +  CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)                        
                            -- �����ȹ���� �۾����� ������, ���� �۾����� ��ȣ + '0001', '0002' ������ ���� ���� 2011. 3. 4 hkim ��    
                END
                
                UPDATE #TPDMPSWorkOrder      
                   SET WorkOrderNo = @WorkOrderNo, WorkOrderSeq = @WorkOrderSeq, WorkOrderSerl = @WorkOrderSerl      
                 WHERE Seq = @Seq      
                               
                SELECT @chkProdPlanSeq = @ProdPlanSeq      
                    
                --SELECT @CountNo = @CountNo + 1      -- 2011. 4. 29 �����ȹ���� �۾����ø� �����Ҷ� 1������ ���������� �����ǵ��� �߰� -- 2011. 5. 12 �ߺ� ä�� �� �� �־ �ּ�ó�� hkim     
     
             END   
    
             ELSE      
             BEGIN      
                
                SELECT @DeptSeq = DeptSeq FROM @DailyProdPlan WHERE ProdPlanSeq = @ProdPlanSeq    
                
                -- �����ȹ ��ȣ �������� 2011. 3. 11 hkim    
                --SELECT @WorkOrderNo = ProdPlanNo FROM @DailyProdPlan WHERE ProdPlanSeq = @ProdPlanSeq    
                
               EXEC @WorkOrderSerl = dbo._SCOMCreateSeq @CompanySeq, '_TPDSFCWorkOrder', 'WorkOrderSerl', 1      
               
               -- �ӽ����̺� �ش� �۾����� �Ǽ��� ������ ������ 2011. 5. 12 hkim    
                IF EXISTS (SELECT 1 FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND  WorkOrderNo LIKE @WorkOrderNo + '%')    
                BEGIN    
                --SELECT @CountNo = COUNT(1) FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%'     
                -- 2011. 5. 17 row count �� �ƴ� Max ������ 
                   IF ISNUMERIC((SELECT SUBSTRING(MAX(WorkOrderNo), @NoLen + 1, 4) FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%')) = 1    
                   BEGIN
                       SELECT @CountNo = CONVERT(INT, SUBSTRING(MAX(WorkOrderNo), @NoLen + 1, 4)) FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%'          
                   END
                   ELSE   
                       SELECT @CountNo = 0    
                END                    
                ELSE     
                BEGIN    
                    SELECT @CountNo = 0    
                END      
                  
                IF  @IsUseProdPlanNo <> '1'  -- �����ȹ��ȣ �۾����ù�ȣ�� �����Ұ�� 0001, 0002 �� ä�� �ǵ���  --12.02.23 �輼ȣ �߰�
                BEGIN             
                    -- �����ȹ���� �۾����� ������, ���� �۾����� ��ȣ + '0001', '0002' ������ ���� ���� 2011. 3. 4 hkim  -- 2011. 4. 29 �����ȹ���� �۾����ø� �����Ҷ� 1������ ���������� �����ǵ��� @Seq���� @CountNo�� ����    
                    IF @CountNo + @ExsistCnt < 9     
                        SELECT @WorkOrderNo = LEFT(@WorkOrderNo, @NoLen) + '000' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)      
                    ELSE IF @CountNo + @ExsistCnt BETWEEN 9 AND 98      
                        SELECT @WorkOrderNo = LEFT(@WorkOrderNo, @NoLen) + '00' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)      
                    ELSE IF @CountNo + @ExsistCnt BETWEEN 99 AND 998      
                        SELECT @WorkOrderNo = LEFT(@WorkOrderNo, @NoLen) + '0' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)      
                    ELSE                           
                        SELECT @WorkOrderNo = LEFT(@WorkOrderNo, @NoLen) + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)      
                    -- �����ȹ���� �۾����� ������, ���� �۾����� ��ȣ + '0001', '0002' ������ ���� ���� 2011. 3. 4 hkim ��    
                END
                
                UPDATE #TPDMPSWorkOrder      
                   SET WorkOrderNo = @WorkOrderNo, WorkOrderSeq = @WorkOrderSeq, WorkOrderSerl = @WorkOrderSerl      
                 WHERE Seq = @Seq      
                
                SELECT @chkProdPlanSeq = @ProdPlanSeq      
                
                --SELECT @CountNo = @CountNo + 1      -- 2011. 4. 29 �����ȹ���� �۾����ø� �����Ҷ� 1������ ���������� �����ǵ��� �߰� -- 2011. 5. 12 �ߺ� ä�� �� �� �־ �ּ�ó�� hkim     
     
            END              
     
        END  
    
        ELSE    
        BEGIN    
            IF @ProdPlanSeq <> @chkProdPlanSeq      
            BEGIN      
                
                SELECT @DeptSeq = DeptSeq FROM @DailyProdPlan WHERE ProdPlanSeq = @ProdPlanSeq    
                
                -- �����ȹ ��ȣ �������� 2011. 3. 11 hkim    
                SELECT @WorkOrderNo = ProdPlanNo FROM @DailyProdPlan WHERE ProdPlanSeq = @ProdPlanSeq    
                
                -- �����ȹ���� �۾����� ������, ���� �۾����� ��ȣ + '0001', '0002' ������ ���� ���� 2011. 3. 4 hkim    

                SELECT @NoLen = LEN(@WOrkOrderNo)      

                -- ����ǰ �����ȹ�� Ǯ�� ���� �̹� ������ �۾����� �Ǽ��� ������ ������ 2011. 4. 20 hkim    
                IF EXISTS (SELECT 1 FROM _TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%')    
                BEGIN    
                    -- 2011. 5. 17 hkim �߰��� ������ �� ��� Row Count�δ� �ߺ� ä���� �� �� �־ �Ʒ��� ���� Max �� ���������� ����  
                    IF ISNUMERIC((SELECT SUBSTRING(MAX(WorkORderNo), @NoLen + 1, 4)  FROM _TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%')) = 1
                    BEGIN  
                        SELECT @ExsistCnt =  CONVERT(INT, SUBSTRING(MAX(WorkORderNo), @NoLen + 1, 4))  FROM _TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%'     
                    END
                    ELSE  
                        SELECT @ExsistCnt = 0                            
                END                    
                ELSE     
                BEGIN    
                    SELECT @ExsistCnt = 0    
                END            
                -- �ӽ����̺� �ش� �۾����� �Ǽ��� ������ ������ 2011. 5. 12 hkim    
                IF EXISTS (SELECT 1 FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND  WorkOrderNo LIKE @WorkOrderNo + '%')    
                BEGIN    
                    SELECT @CountNo = COUNT(1) FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%'     
                END                    
                ELSE     
                BEGIN    
                    SELECT @CountNo = 0    
                END      
                
                EXEC @WorkOrderSeq = dbo._SCOMCreateSeq @CompanySeq, '_TPDSFCWorkOrder', 'WorkOrderSerl', 1 
                --EXEC @WorkOrderSerl = dbo._SCOMCreateSeq @CompanySeq, '_TPDSFCWorkOrder', 'WorkOrderSerl', 1      
                
                
                -- �����ȹ���� ����, �۾������Է�ȭ�鿡�� ����. �� �ΰ��� ���� �� ��� �ߺ�Ű�� �߻��� �� �־ �Ʒ� ���� �߰� 2010. 12. 15 hkim    
                SELECT @WorkOrderSeq = @WorkOrderSeq + 1    
                
                IF  @IsUseProdPlanNo <> '1'  -- �����ȹ��ȣ �۾����ù�ȣ�� �����Ұ�� 0001, 0002 �� ä�� �ǵ���  --12.02.23 �輼ȣ �߰�
                BEGIN
                    IF @CountNo + @ExsistCnt < 9       -- 2011. 4. 29 �����ȹ���� �۾����ø� �����Ҷ� 1������ ���������� �����ǵ��� @Seq���� @CountNo�� ����    
                        SELECT @WorkOrderNo = @WorkOrderNo + '000' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)        
                    ELSE IF @CountNo + @ExsistCnt BETWEEN 9 AND 98      
                        SELECT @WorkOrderNo = @WorkOrderNo + '00' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)        
                    ELSE IF @CountNo + @ExsistCnt BETWEEN 99 AND 998      
                         SELECT @WorkOrderNo = @WorkOrderNo + '0' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)        
                    ELSE                           
                        SELECT @WorkOrderNo = @WorkOrderNo +  CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)   
                     -- �����ȹ���� �۾����� ������, ���� �۾����� ��ȣ + '0001', '0002' ������ ���� ���� 2011. 3. 4 hkim ��    
                END
                
                UPDATE #TPDMPSWorkOrder      
                   SET WorkOrderNo = @WorkOrderNo, WorkOrderSeq = @WorkOrderSeq, WorkOrderSerl = @WorkOrderSerl      
                 WHERE Seq = @Seq      
                
                SELECT @chkProdPlanSeq = @ProdPlanSeq      
                
                --SELECT @CountNo = @CountNo + 1      -- 2011. 4. 29 �����ȹ���� �۾����ø� �����Ҷ� 1������ ���������� �����ǵ��� �߰� -- 2011. 5. 12 �ߺ� ä�� �� �� �־ �ּ�ó�� hkim     
     
            END  
            
            ELSE      
            BEGIN      
                
                EXEC @WorkOrderSerl = dbo._SCOMCreateSeq @CompanySeq, '_TPDSFCWorkOrder', 'WorkOrderSerl', 1      
                    
                -- �ӽ����̺� �ش� �۾����� �Ǽ��� ������ ������ 2011. 5. 12 hkim    
                IF EXISTS (SELECT 1 FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND  WorkOrderNo LIKE @WorkOrderNo + '%')    
                BEGIN    
                -- 2011. 5. 17 Row count�� �ƴ� max ������     
                    IF ISNUMERIC((SELECT SUBSTRING(MAX(WorkORderNo), @NoLen + 1, 4) FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%')) = 1
                    BEGIN
                        SELECT @CountNo = CONVERT(INT, SUBSTRING(MAX(WorkORderNo), @NoLen + 1, 4)) FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%'     
                    END
                    ELSE
                        SELECT @CountNo = 0 
                END                    
                ELSE     
                BEGIN    
                    SELECT @CountNo = 0    
                END      
                
                IF  @IsUseProdPlanNo <> '1'  -- �����ȹ��ȣ �۾����ù�ȣ�� �����Ұ�� 0001, 0002 �� ä�� �ǵ���  --12.02.23 �輼ȣ �߰�
                BEGIN
                    -- �����ȹ���� �۾����� ������, ���� �۾����� ��ȣ + '0001', '0002' ������ ���� ���� 2011. 3. 4 hkim  -- 2011. 4. 29 �����ȹ���� �۾����ø� �����Ҷ� 1������ ���������� �����ǵ��� @Seq���� @CountNo�� ����    
                    IF @CountNo + @ExsistCnt < 9      
                        SELECT @WorkOrderNo = LEFT(@WorkOrderNo, @NoLen) + '000' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)      
                    ELSE IF @CountNo + @ExsistCnt BETWEEN 9 AND 98      
                        SELECT @WorkOrderNo = LEFT(@WorkOrderNo, @NoLen) + '00' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)      
                    ELSE IF @CountNo + @ExsistCnt BETWEEN 99 AND 9998      
                        SELECT @WorkOrderNo = LEFT(@WorkOrderNo, @NoLen) + '0' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)      
                    ELSE                           
                        SELECT @WorkOrderNo = LEFT(@WorkOrderNo, @NoLen) + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)      
                    -- �����ȹ���� �۾����� ������, ���� �۾����� ��ȣ + '0001', '0002' ������ ���� ���� 2011. 3. 4 hkim ��    
                    END
                    
                    UPDATE #TPDMPSWorkOrder      
                       SET WorkOrderNo = @WorkOrderNo, WorkOrderSeq = @WorkOrderSeq, WorkOrderSerl = @WorkOrderSerl     
                     WHERE Seq = @Seq      
     
                    SELECT @chkProdPlanSeq = @ProdPlanSeq      
                     
                 --SELECT @CountNo = @CountNo + 1  -- 2011. 4. 29 �����ȹ���� �۾����ø� �����Ҷ� 1������ ���������� �����ǵ��� �߰� -- 2011. 5. 12 �ߺ� ä�� �� �� �־ �ּ�ó�� hkim     
                
                END      
            END    
        END   
    

    
    SET ROWCOUNT 0      
    
    ALTER TABLE #TPDMPSWorkOrder ADD BatchSeq INT
    UPDATE #TPDMPSWorkOrder
       SET BatchSeq = ISNULL(B.BatchSeq,0)
      FROM #TPDMPSWorkOrder AS A JOIN @TempBatchItem AS B ON A.ProdPlanSeq = B.ProdPlanSeq
    
    -- ��ǰ�� �����˻� ��ϵ� �κ� �ݿ��ϱ� �۱⿬ 20100421------------------------------------------------------------------------------------------------------------------------
    UPDATE #TPDMPSWorkOrder
       SET IsProcQC = B.IsProcQC
      FROM #TPDMPSWorkOrder AS A 
      JOIN _TPDROUItemProcQC AS B ON A.GoodItemSeq = B.ItemSeq AND A.ProcRev = B.ProcRev 
                                 AND A.ProcSeq = B.ProcSeq AND B.CompanySeq = @CompanySeq
    ----------------------------------------------------------------------------------------------------------------------------------------------------------------  
    
    UPDATE A 
       SET WorkOrderSerl = WorkOrderSeq 
      FROM #TPDMPSWorkOrder AS A 
    
    
    -- �����ȹ, �۾����� �߰����̺� 
    INSERT INTO _TPDMPSWorkOrder       
    (      
        CompanySeq,   FactUnit,      ProdPlanSeq,   WorkOrderSeq,      WorkOrderSerl,      
        WorkOrderNo,  WorkOrderDate, WorkPlanSerl,  DailyWorkPlanSerl, WorkCenterSeq,      
        GoodItemSeq,  ProcSeq,       AssyItemSeq,   ProdUnitSeq,       OrderQty,      
        StdUnitQty,   WorkDate,      WorkStartTime, WorkEndTime,       ChainGoodsSeq,      
        WorkType,     DeptSeq,       ItemUnitSeq,   ProcRev,           Remark,      
        IsProcQC,     IsLastProc,    IsPjt,         PjtSeq,            WBSSeq,      
        ItemBomRev,   ProcNo,        ToProcNo,      SMToProcMovType,   LastUserSeq,      
        LastDateTime, BatchSeq,      WorkCond1     
    )      
    SELECT           
            A.CompanySeq,   FactUnit,         ProdPlanSeq,           WorkOrderSeq,      WorkOrderSerl,        
            WorkOrderNo,  WorkOrderDate,    WorkPlanSerl,          DailyWorkPlanSerl, ISNULL(WorkCenterSeq,0),        
            GoodItemSeq,  ProcSeq,          ISNULL(AssyItemSeq,0), ProdUnitSeq,       CASE WHEN B.SMDecPointSeq = 1003001 THEN ROUND(OrderQty, @QtyPoint, 0)   -- 2011. 4. 19 hkim �Ҽ��� �ڸ��� �����ϱ� ���ؼ� ����--CONVERT(DECIMAL(19,5),OrderQty),        
                                                                                           WHEN B.SMDecPointSeq = 1003002 THEN ROUND(OrderQty, @QtyPoint, -1)             
                                                                                           WHEN B.SMDecPointSeq = 1003003 THEN ROUND(OrderQty + CAST(4 AS DECIMAL(19, 5)) / POWER(10,(@QtyPoint + 1)), @QtyPoint)     
                                                                                           ELSE ROUND(OrderQty  , @QtyPoint, 0) END,     
            CASE WHEN D.SMDecPointSeq = 1003001 THEN ROUND(StdUnitQty, @QtyPoint, 0)  -- ���ش��������� �Ҽ���ó�� �ǵ���   12.04.25 BY �輼ȣ
                 WHEN D.SMDecPointSeq = 1003002 THEN ROUND(StdUnitQty, @QtyPoint, -1)             
                 WHEN D.SMDecPointSeq = 1003003 THEN ROUND(StdUnitQty + CAST(4 AS DECIMAL(19, 5)) / POWER(10,(@QtyPoint + 1)), @QtyPoint)     
                 ELSE ROUND(OrderQty  , @QtyPoint, 0) END,   WorkDate,         WorkStartTime,         WorkENDTime,       ChainGoodsSeq,        
            WorkType,     ISNULL(A.DeptSeq,0) ,ItemUnitSeq,          ProcRev,           A.Remark,        
            IsProcQC,     IsLastProc,       IsPjt,                 PjtSeq,            WBSSeq,        
            ItemBomRev,   ProcNo,           ToProcNo,              SMToProcMovType,   A.LastUserSeq,        
            A.LastDateTime, A.BatchSeq,     WorkCond1  -- ����ð�     
      FROM #TPDMPSWorkOrder AS A    
      JOIN _TDAUnit          AS B ON A.ProdUnitSeq = B.UnitSeq    -- 2011. 4. 19 hkim ���� ����� �Ҽ��� ������� �������� ����  
      JOIN _TDAItem          AS C ON B.CompanySeq = C.CompanySeq AND A.AssyItemSeq = C.ItemSeq  
      JOIN _TDAUnit          AS D ON C.CompanySeq = D.CompanySeq AND C.UnitSeq = D.UnitSeq
     WHERE ISNULL(WorkOrderNo ,'') <> ''         
       AND B.CompanySeq = @CompanySeq  
       AND A.OrderQty <> 0   --2013.02.05 BY ��³�  :: �۾��ð� ���� �� ��ǰ ������ �۾��ð��� ���ϰ� �� �۾��ð��� ���ϴ� �κп��� ȯ��ó���ϸ鼭 �ܼ����̰� �߻��ϰ� �Ǿ� ���۾��ð��� �ø�ó���Ǹ鼭 �۾������� 0 �� �����Ͱ� ������ �� �־ ���� 
    
    
    -- �۾����� ���̺� 
    INSERT INTO _TPDSFCWorkOrder
    (
        CompanySeq,WorkOrderSeq,FactUnit,WorkOrderNo,WorkOrderSerl,
        WorkOrderDate,ProdPlanSeq,WorkPlanSerl,DailyWorkPlanSerl,WorkCenterSeq,
        GoodItemSeq,ProcSeq,AssyItemSeq,ProdUnitSeq,OrderQty,
        StdUnitQty,WorkDate,WorkStartTime,WorkEndTime,ChainGoodsSeq,
        WorkType,DeptSeq,ItemUnitSeq,ProcRev,Remark,
        IsProcQC,IsLastProc,IsPjt,PjtSeq,WBSSeq,
        ItemBomRev,ProcNo,ToProcNo,SMToProcMovType, ProdOrderSeq, 
        IsCancel, LastUserSeq, LastDateTime, BatchSeq, WorkCond1 -- ����ð� 
    ) 
    SELECT A.CompanySeq,
           A.WorkOrderSeq,
           A.FactUnit,
           A.WorkOrderNo,
           A.WorkOrderSerl,
           CONVERT(nCHAR(8), CONVERT(DATETIME, GETDATE()),112), -- �۾��������� ���� �����ȹ�Ϸ����� �ƴ� �����ȹ Ȯ�����ڷ� ���� 2012.06.18 by ��³�
           A.ProdPlanSeq,
           A.WorkPlanSerl,
           A.DailyWorkPlanSerl,
           A.WorkCenterSeq,
           A.GoodItemSeq,
           A.ProcSeq,
           A.AssyItemSeq,
           A.ProdUnitSeq,
           A.OrderQty,
           A.StdUnitQty,
           A.WorkDate,
           A.WorkStartTime,
           A.WorkEndTime,
           A.ChainGoodsSeq,
           6041001,
           A.DeptSeq,
           A.ItemUnitSeq,
           A.ProcRev,
           A.Remark,
           A.IsProcQC,--IsProcQC,
           A.IsLastProc,--IsLastProc,
           A.IsPjt,
           A.PjtSeq,
           A.WBSSeq,
           A.ItemBomRev,
           A.ProcNo,
           A.ToProcNo,
           A.SMToProcMovType,
           0,
           '0',
           A.LastUserSeq,
           A.LastDateTime,
           A.BatchSeq,
           A.WorkCond1 -- ����ð� 
        FROM _TPDMPSWorkOrder AS A 
        JOIN #TPDMPSDailyProdPlan AS B ON ( A.ProdPlanSeq = B.ProdPlanSeq ) 
       WHERE A.CompanySeq = @CompanySeq
    
    
    
    -- �۾����� Ȯ�������� �����
    INSERT INTO _TPDSFCWorkOrder_Confirm
    (
        CompanySeq,     CfmSeq,         CfmSerl,        CfmSubSerl,     CfmSecuSeq,
        IsAuto,         CfmCode,        CfmDate,        CfmEmpSeq,      UMCfmReason,
        CfmReason,      LastDateTime
    )
    SELECT @CompanySeq,
           A.WorkOrderSeq,
           A.WorkOrderSerl,
           0,
           1009,
           '0',
           0,
           '',
           (SELECT EmpSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq),
           0,
           '',
           GETDATE()
      FROM _TPDMPSWorkOrder                     AS A 
      JOIN #TPDMPSDailyProdPlan                 AS C ON A.ProdPlanSeq = C.ProdPlanSeq 
      LEFT OUTER JOIN _TPDSFCWorkOrder_Confirm  AS B ON A.WorkOrderSeq = B.CfmSeq 
                                                    AND A.WorkOrderSerl = B.CfmSerl
                                                    AND B.CompanySeq = @CompanySeq
     WHERE A.CompanySeq = @CompanySeq
       AND B.CfmSeq IS NULL
    
    IF ISNULL((SELECT IsNotUsed FROM _TCOMConfirmDef WHERE CompanySeq = @CompanySeq AND ConfirmSeq = 6320),'0') = '1'  
    BEGIN
        UPDATE _TPDSFCWorkOrder_Confirm
           SET CfmCode = 1,
               CfmDate = CONVERT(nCHAR(8), CONVERT(DATETIME, GETDATE()),112) --�۾�����Ȯ�����ڰ� Convert�� ����� ���� ���� ���·� ���� ���� 12.11.22 by snheo
          FROM _TPDMPSWorkOrder                     AS A 
          JOIN #TPDMPSDailyProdPlan                 AS C ON A.ProdPlanSeq = C.ProdPlanSeq 
          LEFT OUter JOIN _TPDSFCWorkOrder_Confirm  AS B ON A.WorkOrderSeq = B.CfmSeq 
                                                       AND A.WorkOrderSerl = B.CfmSerl
                                                       AND B.CompanySeq = @CompanySeq
         WHERE A.CompanySeq = @CompanySeq
    END
    
    -- �����ȹ -> �۾����� �������-------------------------------------------------------------------------------------------
    CREATE TABLE #SComSourceDailyBatch    
    (  
        ToTableName   NVARCHAR(100),  
        ToSeq         INT,  
        ToSerl        INT,  
        ToSubSerl     INT,  
        FromTableName NVARCHAR(100),  
        FromSeq       INT,  
        FromSerl      INT,  
        FromSubSerl   INT,  
        ToQty         DECIMAL(19,5),  
        ToStdQty      DECIMAL(19,5),  
        ToAmt         DECIMAL(19,5),  
        ToVAT         DECIMAL(19,5),  
        FromQty       DECIMAL(19,5),  
        FromSTDQty    DECIMAL(19,5),  
        FromAmt       DECIMAL(19,5),  
        FromVAT       DECIMAL(19,5)  
    )  
    -- ���࿬��(�����ȹ => �۾�����)  
    INSERT INTO #SComSourceDailyBatch  
    SELECT '_TPDSFCWorkOrder', A.WorkOrderSeq, A.WorkOrderSerl, 0,   
           '_TPDMPSDailyProdPlan', B.ProdPlanSeq, 0, 0,  
           0, 0, 0,   0,  
           0, 0, 0,   0 
      FROM _TPDMPSWorkOrder AS A JOIN #TPDMPSDailyProdPlan AS B ON A.ProdPlanSeq = B.ProdPlanSeq 
     WHERE A.CompanySeq = @CompanySeq
    
    IF @@ERROR <> 0      
    BEGIN      
        RETURN      
    END    
    
     -- ���࿬��  
     EXEC _SComSourceDailyBatch 'A', @CompanySeq, @UserSeq  
    
    SELECT * FROM #TPDSFCWorkOrder   
    
    RETURN  
go 
begin tran 
exec KPX_SPDWorkOrderCfmSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <FrStdDate>20141020</FrStdDate>
    <FrTime>1200</FrTime>
    <ToStdDate>20141031</ToStdDate>
    <ToTime>1200</ToTime>
    <WorkCenterName>����2</WorkCenterName>
    <WorkCenterSeq>34</WorkCenterSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025108,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021101
rollback  