  
IF OBJECT_ID('jongie_SPDSemiItemProdPlanListQuery') IS NOT NULL   
    DROP PROC jongie_SPDSemiItemProdPlanListQuery  
GO  
  
-- v2013.10.08  
  
-- ��������ǰ�����ȹ�����ȸ_jongie(��ȸ) by����õ   
CREATE PROC jongie_SPDSemiItemProdPlanListQuery  
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
            @FactUnit       INT,  
            @ProdPlanYM     NVARCHAR(6), 
            @DeptSeq        INT, 
            @ItemName       NVARCHAR(100), 
            @ItemNo         NVARCHAR(100), 
            @Spec           NVARCHAR(100), 
            @SemiItemName   NVARCHAR(100), 
            @SemiItemNo     NVARCHAR(100), 
            @SemiSpec       NVARCHAR(100) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit     = ISNULL(FactUnit,0), 
           @ProdPlanYM   = ISNULL(ProdPlanYM,''), 
           @DeptSeq      = ISNULL(DeptSeq,0), 
           @ItemName     = ISNULL(ItemName,''), 
           @ItemNo       = ISNULL(ItemNo,''), 
           @Spec         = ISNULL(Spec,''), 
           @SemiItemName = ISNULL(SemiItemName,''), 
           @SemiItemNo   = ISNULL(SemiItemNo,''), 
           @SemiSpec     = ISNULL(SemiSpec,'') 
           
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags ) 
      
      WITH (
            FactUnit        INT,  
            ProdPlanYM      NVARCHAR(6), 
            DeptSeq         INT, 
            ItemName        NVARCHAR(100),
            ItemNo          NVARCHAR(100),
            Spec            NVARCHAR(100), 
            SemiItemName    NVARCHAR(100), 
            SemiItemNo      NVARCHAR(100), 
            SemiSpec        NVARCHAR(100) 
           )    
    
    -- ������ȸ   
    SELECT ROW_NUMBER() OVER (Order BY ProdPlanSeq) AS IDX_NO, 0 AS Status, CONVERT(NVARCHAR(1000),NULL) AS Result, NULL AS MessageType,  
           A.CompanySeq, A.ProdPlanSeq, A.FactUnit, A.ProdPlanNo, A.SrtDate, 
           A.EndDate AS ProdPlanEndDate, A.DeptSeq AS ProdDeptSeq, A.WorkcenterSeq, A.ItemSeq, A.BOMRev, A.ProcRev, 
           A.UnitSeq, A.BaseStkQty, A.PreSalesQty, A.SOQty, A.StkQty, 
           A.PreInQty, A.ProdQty AS ProdPlanQty, A.StdProdQty, A.SMSource, A.SourceSeq, 
           A.SourceSerl, A.Remark, IsCfm, CfmEmpSeq, BatchSeq, StdUnitSeq
    
      INTO #TPDMPProdPlan
      FROM _TPDMPSDailyProdPlan AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TDAItem  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
    
     WHERE A.CompanySeq = @CompanySeq  
       AND (@FactUnit = 0 OR A.FactUnit = FactUnit) 
       AND @ProdPlanYM = LEFT(A.EndDate,6) 
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq) 
       AND (@ItemName = '' OR B.ItemName LIKE @ItemName + '%') 
       AND (@ItemNo = '' OR B.ItemNo LIKE @ItemNo + '%') 
       AND (@Spec = '' OR B.Spec LIKE @Spec + '%') 
     
     --select * from #TPDMPProdPlan
     --return
-------------------------------------------------------------------------------------------------------------- 
    DECLARE @EnvValue INT
    SELECT @EnvValue =  CONVERT(INT,EnvValue) FROM _TCOMEnv WHERE CompanySeq = @CompanySeq and EnvSeq like '6219%'           
    
    -- ǰ�� ��������      
    DECLARE @ItemProcInfo TABLE      
    (      
        FactUnit        INT,      
        ItemSeq         INT,      
        BOMRev          NCHAR(2),      
        ProcRev         NCHAR(2),      
        ProcSeq         INT,      
        WorkCenterSeq   INT      
    )      
      
    DECLARE @ProdItem TABLE      
    (      
        SrtDate     NCHAR(8),      
        WorkDate    NCHAR(8),      
        ItemSeq     INT,      
        BOMRev      NCHAR(2),      
        ProcRev     NCHAR(2),      
        ProdQty     DECIMAL(19,5),      
        ProdPlanSeq INT,      
        FactUnit    INT      
       
    )      
      
    INSERT INTO @ProdItem      
    SELECT B.SrtDate, A.ProdPlanEndDate, A.ItemSeq, A.BOMRev,A.ProcRev,A.ProdPlanQty, A.ProdPlanSeq, A.FactUnit      
      FROM #TPDMPProdPlan AS A JOIN _TPDMPSDailyProdPlan AS B ON B.CompanySeq = @CompanySeq and A.ProdPlanSeq = B.ProdPlanSeq AND A.FactUnit = B.FactUnit      
     WHERE B.SMSource < 6054003      
     ORDER BY EndDate      
         
    UPDATE @ProdItem      
       SET BOMRev = B.BOMRev      
      FROM @ProdItem AS A JOIN @ItemProcInfo AS B ON A.FactUnit = B.FactUnit AND a.ItemSeq = B.ItemSeq      
      
    CREATE TABLE #MatNeed_GoodItem        
    (        
        IDX_NO          INT IDENTITY(1,1),        
        ItemSeq         INT,        -- ��ǰ�ڵ�        
        ProcRev         NCHAR(2),   -- �����帧����        
        BOMRev          NCHAR(2),   -- BOM����        
        ProcSeq         INT,        -- �����ڵ�        
        AssyItemSeq     INT,        -- ����ǰ�ڵ�        
        UnitSeq         INT,        -- �����ڵ�     (����ǰ�ڵ尡 ������ ����ǰ�����ڵ�, ������ ��ǰ�����ڵ�)        
        Qty             DECIMAL(19, 5),    -- ��ǰ����     (����ǰ�ڵ尡 ������ ����ǰ����)        
        ProdPlanSeq     INT,        -- �����ȹ���ι�ȣ (�����Ƿڿ��� �߰��� �ɼ����縦 ������������)        
        WorkOrderSeq    INT,        -- �۾����ó��ι�ȣ (�۾����ÿ��� �߰������ ��ϵ� ���縦 ������������)      
        WorkOrderSerl   INT,        -- �۾����ó��ι�ȣ (�۾����ÿ��� �߰������ ��ϵ� ���縦 ������������)         
        IsOut           NCHAR(1),    -- �ν��� ���뿡 ��� '1'�̸� OutLossRate ����        
        WorkDAte        NCHAR(8),  
        SemiGoodSeq     INT NULL,  
        SemiBOMRev      NCHAR(2) NULL  
    )        
             
    CREATE TABLE #MatNeed_MatItem_Result        
    (        
        IDX_NO          INT,            -- ��ǰ�ڵ�        
        MatItemSeq      INT,            -- �����ڵ�        
        UnitSeq         INT,            -- �������        
        NeedQty         DECIMAL(19,5),  -- �ҿ䷮        
        InputType       INT        
    )        
        
    CREATE TABLE #NeedQtySum        
    (        
        WorkOrderSeq        INT,        
        ProcSeq             INT,        
        MatItemSeq          INT,        
        UnitSeq             INT,        
        Qty                 NUMERIC(19,5),        
        NeedQty             NUMERIC(19,5),        
        TimeStep            NUMERIC(19,5)        
    )        
      
    DECLARE @SemiGoodQty TABLE      
    (      
        WorkDate    NCHAR(8),      
        ItemSeq     INT,      
        ProdQty     DECIMAL(19,5),      
        SemiGoodSeq INT,      
        NeedQty     DECIMAL(19,5),      
        ProdPlanSeq INT,      
        SemiBomrev  NCHAR(2),      
        SemiProcRev NCHAR(2),      
        levCnt      INT,      
        FactUnit    INT,      
        SMAssetGrp  INT      
    )      
          
    -- �ҿ䷮��� �� ���� ǰ����.        
    INSERT #MatNeed_GoodItem (ItemSeq,ProcRev,BOMRev,ProcSeq,AssyItemSeq,UnitSeq,Qty,ProdPlanSeq,WorkOrderSeq,WorkOrderSerl,IsOut,WorkDate)        
    SELECT W.ItemSeq, W.ProcRev, W.BomRev, 0, 0, B.STDUnitSeq, W.ProdQty, W.ProdPlanSeq, 0,0,'0',W.SrtDate         
      FROM @ProdItem    AS W        
       JOIN _TDAItemDefUnit AS B ON W.ItemSeq = B.ItemSeq AND @CompanySeq = B.CompanySeq   
                                AND B.UMModuleSeq = 1003003    -- �ҿ����� ������������ ��������� �㵵�� ���� (_SPDMMGetItemNeedQty�󿡼� BOM������ ȯ���Ͽ� �ҿ䷮ ���ϱ�����)  
                                                               -- 11.10.07 �輼ȣ �߰�  
   
    -- �ҿ����� ��������        
    EXEC dbo._SPDMMGetItemNeedQty @CompanySeq        
    
    INSERT INTO @SemiGoodQty      
    SELECT CONVERT(NCHAR(8),(DATEADD(DD,@EnvValue *(-1),A.WorkDate)),112),      
           A.ItemSeq, A.Qty, B.MatItemSeq, B.NeedQty, A.ProdPlanSeq, F.SubItemBomRev,'00',1,0, D.SMAssetGrp      
      FROM #MatNeed_GoodItem AS A JOIN #MatNeed_MatItem_Result AS B ON A.IDX_NO = B.IDX_NO      
                                  JOIN _TDAItem AS C ON B.MatItemSeq = C.ItemSeq AND C.CompanySeq = @CompanySeq --and AssetSeq = 4      
                                  JOIN _TDAItemAsset AS D ON C.AssetSeq = D.AssetSeq AND D.CompanySeq = @CompanySeq      
                                  JOIN _TDASMinor AS E ON D.SMAssetGrp = E.MinorSeq AND E.MinorSeq IN (6008002,6008004,6008005)       
                                                      AND E.CompanySeq = @CompanySeq      
                                  JOIN _TPDBOM    AS F ON A.ItemSeq = F.ItemSeq AND A.BOMRev = F.ItemBomRev AND B.MatItemSeq = F.SubItemSeq AND F.CompanySeq = @CompanySeq      
      
    DECLARE @MaxCheckDate NCHAR(8), @CheckDate NCHAR(8)      
    
    SELECT @CheckDate = Min(WorkDAte) from @ProdItem       
    SELECT @MaxCheckDate = MAX(WorkDAte) from @ProdItem       
    
    UPDATE @SemiGoodQty      
       SET FactUnit = B.FactUnit      
      FROM @SemiGoodQty AS A JOIN @ProdItem AS B ON A.ProdPlanSeq = B.ProdPlanSeq      
    
    DELETE @SemiGoodQty      
      FROM @SemiGoodQty AS A JOIN _TPDBaseAheadItem AS B ON A.SemiGoodSeq = B.ItemSeq and A.FactUnit = B.FactUnit      
    
    UPDATE @SemiGoodQty      
       SET SemiProcRev = B.ProcRev      
      FROM @SemiGoodQty  AS A JOIN       
    (SELECT A.WorkDate, A.SemiGoodSeq, A.SemiBomRev, MAX(B.ProcRev) AS ProcRev      
       FROM @SemiGoodQty AS A        
        JOIN _TPDROUItemProcRevFactUnit AS B ON A.FactUnit = B.FactUnit       
                                            AND A.SemiGoodSeq = B.ItemSeq        
                                            AND A.SemiBomrev = B.BOMrev      
                                            AND B.CompanySeq = @CompanySeq      
                                            AND B.FrDate <= A.WorkDate      
                                            AND B.ToDate >= A.WorkDate      
      GROUP BY A.WorkDate, A.SemiGoodSeq, A.SemiBomRev
    ) AS B ON A.WorkDate = B.WorkDate AND A.SemiGoodSeq = B.SemiGoodSeq AND A.SemiBomRev = B.SemiBomRev      
       
  
      
    SELECT @CheckDate = Min(WorkDAte) FROM @ProdItem       
    SELECT @MaxCheckDate = MAX(WorkDAte) FROM @ProdItem       
    
    DECLARE @levCnt INT      
    
    SELECT @levCnt = 1      
    
    --## �ɼ� ����ǰ ��������(�ɼ� �߰��� ����ǰ�� �޸� ��� ���� ���� ���� ��. �׷��� �ش� ���� �߰� 2011. 1. 12 hkim ##  
    CREATE TABLE #Option_Item  
    (  
        ItemSeq INT  
    )  
    INSERT INTO #Option_Item  
    SELECT DISTINCT C.MatItemSeq  
      FROM _TCOMSourceDaily AS A  
           JOIN @SemiGoodQty AS B ON A.ToSeq = B.ProdPlanSeq   
           JOIN _TPDROUItemProcMatAdd AS C ON A.FromSeq = C.ProdReqSeq AND A.FromSerl = C.ProdReqSerl  
     WHERE A.ToTableSeq = 32 AND A.FromTableSeq =  1        
    --## �ɼ� ����ǰ �������� �� (�ɼ� �߰��� ����ǰ�� �޸� ��� ���� ���� ���� ��. �׷��� �ش� ���� �߰� 2011. 1. 12 hkim ##  
      
     
    WHILE(1=1)  
    BEGIN      
    
    IF (SELECT Count(*) FROM @SemiGoodQty WHERE LevCnt = @levCnt) = 0 BREAK      
    
    DELETE FROM #MatNeed_GoodItem      
    DELETE FROM #MatNeed_MatItem_Result        
    
    -- �ҿ䷮��� �� ���� ǰ����.        
    INSERT #MatNeed_GoodItem (ItemSeq,ProcRev,BOMRev,ProcSeq,AssyItemSeq,UnitSeq,Qty,ProdPlanSeq,WorkOrderSeq,WorkOrderSerl,IsOut,WorkDate, SemiGoodSeq, SemiBOMRev)          
    SELECT W.SemiGoodSeq, W.SemiProcRev, W.SemiBomRev, 0, 0, D.STDUnitSeq, W.NeedQty, W.ProdPlanSeq, 0,0,'0', W.WorkDate, W.SemiGoodSeq, W.SemiBOMRev        
      FROM @SemiGoodQty    AS W    
      JOIN _TDAItemDefUnit AS D ON W.SemiGoodSeq = D.ItemSeq  
                               AND @CompanySeq = D.CompanySeq   
                               AND D.UMModuleSeq = 1003003      -- �ҿ����� ������������ ��������� �㵵�� ���� (_SPDMMGetItemNeedQty�󿡼� BOM������ ȯ���Ͽ� �ҿ䷮ ���ϱ�����)  
                                                                -- 11.10.07 �輼ȣ �߰�  
    WHERE W.levCnt = @levCnt      
      AND W.SMAssetGrp = 6008004  
   -- 2012. 5. 22 hkim �Ʒ��κ� �ٽ� �ּ�ó�� ;; �ɼ��� ����� ��� 1���� ������ ����ǰ Ǯ������ ����      
      --AND ( NOT EXISTS (SELECT 1 FROM #Option_Item) OR (W.SemiGoodSeq NOT IN (SELECT ISNULL(ItemSeq, 0) FROM #Option_Item) AND LevCnt <> 1) )      -- 2011. 1. 12 hkim �ɼ� ����ǰ�� ����ҿ信�� ����(����ǰ�� ��� ���ѷ��� ����)  
  
   --��ǰ�� �����ȹ�� ������ �� �ֵ��� �߰� 12.05.14 snheo  
   INSERT #MatNeed_GoodItem (ItemSeq,ProcRev,BOMRev,ProcSeq,AssyItemSeq,UnitSeq,Qty,ProdPlanSeq,WorkOrderSeq,WorkOrderSerl,IsOut,WorkDate)          
   SELECT W.SemiGoodSeq, W.SemiProcRev, W.SemiBomRev, 0, 0, D.STDUnitSeq, W.NeedQty, W.ProdPlanSeq, 0,0,'0', W.WorkDate         
     FROM @SemiGoodQty    AS W    
    JOIN _TDAItemDefUnit AS D ON W.SemiGoodSeq = D.ItemSeq  
                         AND @CompanySeq = D.CompanySeq   
                         AND D.UMModuleSeq = 1003003      -- �ҿ����� ������������ ��������� �㵵�� ���� (_SPDMMGetItemNeedQty�󿡼� BOM������ ȯ���Ͽ� �ҿ䷮ ���ϱ�����)  
                                                            -- 11.10.07 �輼ȣ �߰�  
    WHERE W.levCnt = @levCnt      
      AND W.SMAssetGrp = 6008002     
   -- 2012. 5. 22 hkim �Ʒ��κ� �ٽ� �ּ�ó�� ;; �ɼ��� ����� ��� 1���� ������ ����ǰ Ǯ������ ����         
      --AND ( NOT EXISTS (SELECT 1 FROM #Option_Item) OR (W.SemiGoodSeq NOT IN (SELECT ISNULL(ItemSeq, 0) FROM #Option_Item) AND LevCnt <> 1) )      -- 2011. 1. 12 hkim �ɼ� ����ǰ�� ����ҿ信�� ����(����ǰ�� ��� ���ѷ��� ����)  
      
   INSERT #MatNeed_GoodItem (ItemSeq,ProcRev,BOMRev,ProcSeq,AssyItemSeq,UnitSeq,Qty,ProdPlanSeq,WorkOrderSeq,WorkOrderSerl,IsOut,WorkDate, SemiGoodSeq, SemiBOMRev)          
   SELECT DISTINCT B.ItemSeq, B.ProcRev, B.BOMRev, C.ProcSeq, 0, D.STDUnitSeq, W.NeedQty, W.ProdPlanSeq, 0,0,'0', W.WorkDate, W.SemiGoodSeq, W.SemiBomRev  
     FROM @SemiGoodQty    AS W JOIN _TPDMPSDailyProdPlan AS B On W.ProdPlanSeq = B.ProdPlanSeq AND B.CompanySeq = @CompanySeq      
                               JOIN _TPDROUItemProcMat   AS C ON B.ItemSeq = C.ItemSeq AND B.BomRev = C.BOMRev AND B.ProcRev = C.ProcRev AND W.SemiGoodSeq = C.AssyItemSeq AND C.CompanySeq = @CompanySeq       
  
                                JOIN _TDAItemDefUnit AS D ON W.SemiGoodSeq = D.ItemSeq  
                                                     AND @CompanySeq = D.CompanySeq   
                                                     AND D.UMModuleSeq = 1003003      -- �ҿ����� ������������ ��������� �㵵�� ���� 11.10.07 �輼ȣ �߰�  
                                                                                        -- (_SPDMMGetItemNeedQty�󿡼� BOM������ ȯ���Ͽ� �ҿ䷮ ���ϱ�����)  
    WHERE W.levCnt = @levCnt      
      AND W.SMAssetGrp = 6008005  
   -- 2012. 5. 22 hkim �Ʒ��κ� �ٽ� �ּ�ó�� ;; �ɼ��� ����� ��� 1���� ������ ����ǰ Ǯ������ ����            
      --AND ( NOT EXISTS (SELECT 1 FROM #Option_Item) OR (W.SemiGoodSeq NOT IN (SELECT ISNULL(ItemSeq, 0) FROM #Option_Item) AND LevCnt <> 1) )      -- 2011. 1. 12 hkim �ɼ� ����ǰ�� ����ҿ信�� ����(����ǰ�� ��� ���ѷ��� ����)  
  
   -- �ҿ����� ��������        
   EXEC dbo._SPDMMGetItemNeedQty @CompanySeq        
     
   INSERT INTO @SemiGoodQty(WorkDate,ItemSeq,ProdQty,SemiGoodSeq ,NeedQty ,ProdPlanSeq ,SemiBomrev,SemiProcRev ,levCnt,FactUnit,SMAssetGrp)      
   SELECT CONVERT(NCHAR(8),(DATEADD(DD,@EnvValue *(-1),A.WorkDate)),112),      
                   0, 0, B.MatItemSeq, B.NeedQty, A.ProdPlanSeq, F.SubItemBomRev,'00',@levCnt+1,0,D.SMAssetGrp      
     FROM #MatNeed_GoodItem AS A JOIN #MatNeed_MatItem_Result AS B ON A.IDX_NO = B.IDX_NO      
            JOIN _TDAItem AS C ON B.MatItemSeq = C.ItemSeq and C.CompanySeq = @CompanySeq --and AssetSeq = 4      
                                            JOIN _TDAItemAsset AS D ON C.AssetSeq = D.AssetSeq and D.CompanySeq = @CompanySeq      
                                          JOIN _TDASMinor AS E ON D.SMAssetGrp = E.MinorSeq AND E.MinorSeq IN ( 6008004)       
                                                              and E.CompanySeq = @CompanySeq      
            LEFT OUTER JOIN _TPDBOM    AS F ON A.SemiGoodSeq = F.ItemSeq AND A.SemiBOMRev = F.ItemBOMRev AND B.MatItemSeq = F.SubItemSeq AND F.CompanySeq = @CompanySeq      
  
  
   INSERT INTO @SemiGoodQty(WorkDate,ItemSeq,ProdQty,SemiGoodSeq ,NeedQty ,ProdPlanSeq ,SemiBomrev,SemiProcRev ,levCnt,FactUnit,SMAssetGrp)      
   SELECT CONVERT(NCHAR(8),(DATEADD(DD,@EnvValue *(-1),A.WorkDate)),112),      
                   0, 0, B.MatItemSeq, B.NeedQty, A.ProdPlanSeq, ISNULL(F.SubItemBomRev,'00'),'00',@levCnt+1,0,D.SMAssetGrp      
     FROM #MatNeed_GoodItem AS A JOIN #MatNeed_MatItem_Result AS B ON A.IDX_NO = B.IDX_NO      
            JOIN _TDAItem AS C ON B.MatItemSeq = C.ItemSeq and C.CompanySeq = @CompanySeq --and AssetSeq = 4      
                                          JOIN _TDAItemAsset AS D ON C.AssetSeq = D.AssetSeq and D.CompanySeq = @CompanySeq      
                                          JOIN _TDASMinor AS E ON D.SMAssetGrp = E.MinorSeq AND E.MinorSeq IN ( 6008002)       
                                                              and E.CompanySeq = @CompanySeq      
                                          LEFT OUTER JOIN _TPDBOM    AS F ON A.ItemSeq = F.ItemSeq AND A.BOMRev = F.ItemBomRev AND B.MatItemSeq = F.SubItemSeq AND F.CompanySeq = @CompanySeq      
     
  
   INSERT INTO @SemiGoodQty(WorkDate,ItemSeq,ProdQty,SemiGoodSeq ,NeedQty ,ProdPlanSeq ,SemiBomrev,SemiProcRev ,levCnt,FactUnit,SMAssetGrp)      
   SELECT DISTINCT CONVERT(NCHAR(8),(DATEADD(DD,@EnvValue *(-1),A.WorkDate)),112),      
                   0, A.Qty, B.MatItemSeq, B.NeedQty, A.ProdPlanSeq, '00','00',@levCnt+1,0,D.SMAssetGrp      
     FROM #MatNeed_GoodItem AS A JOIN #MatNeed_MatItem_Result AS B ON A.IDX_NO = B.IDX_NO      
            JOIN _TDAItem AS C ON B.MatItemSeq = C.ItemSeq and C.CompanySeq = @CompanySeq --and AssetSeq = 4      
                                          JOIN _TDAItemAsset AS D ON C.AssetSeq = D.AssetSeq and D.CompanySeq = @CompanySeq      
                                          JOIN _TDASMinor AS E ON D.SMAssetGrp = E.MinorSeq AND E.MinorSeq IN (6008005)       
                                                              and E.CompanySeq = @CompanySeq      
  
  
   -- BOM ���� NULL �ΰ� ����庰����ǰ���� MAX������ UPDATE  
   --(��ǰA - ����ǰA - ���ǰA - ����ǰB �� ��� ����ǰ�� B�� BOM ������ �������´�   
   -- ����ǰ A�� �������� Ǯ� ���ǰ A - ����ǰ B�� BOM���踦 ��ƾߵŴµ�, ����ǰ A�� �����帧������ ��Ȯ�� �˼��� ���� ������)     -- 12.11.28 BY �輼ȣ  
  
    UPDATE @SemiGoodQty  
       SET SemiBomrev = (SELECT  ISNULL(MAX(BOMRev), '00') FROM _TPDROUItemProcRevFactUnit WHERE CompanySeq = @CompanySeq AND ItemSeq = A.SemiGoodSeq)  
      FROM @SemiGoodQty     AS A  
     WHERE SemiBomrev IS NULL  
  
  
    UPDATE @SemiGoodQty      
       SET FactUnit = B.FactUnit      
      FROM @SemiGoodQty AS A JOIN @ProdItem AS B ON A.ProdPlanSeq = B.ProdPlanSeq      
  
  
    DELETE @SemiGoodQty      
     FROM @SemiGoodQty AS A JOIN _TPDBaseAheadItem AS B ON A.SemiGoodSeq = B.ItemSeq and A.FactUnit = B.FactUnit      
  
  
    UPDATE @SemiGoodQty      
       SET SemiProcRev = B.ProcRev      
     FROM @SemiGoodQty  AS A JOIN       
    (SELECT A.WorkDate, A.SemiGoodSeq, A.SemiBomRev, MAX(B.ProcRev) AS ProcRev      
      FROM @SemiGoodQty AS A        
      JOIN _TPDROUItemProcRevFactUnit AS B ON A.FactUnit = B.FactUnit AND A.SemiGoodSeq = B.ItemSeq AND A.SemiBomrev = B.BOMrev      
                                          AND B.CompanySeq = @CompanySeq AND B.FrDate <= A.WorkDate AND B.ToDate >= A.WorkDate      
     WHERE A.levCnt = @levCnt+1      
     GROUP BY A.WorkDate, A.SemiGoodSeq, A.SemiBomRev
    ) AS B ON A.WorkDate = B.WorkDate AND A.SemiGoodSeq = B.SemiGoodSeq AND A.SemiBomRev = B.SemiBomRev      
     WHERE levCnt = @levCnt+1      
  
    SELECT @levCnt = @levCnt + 1      
    
    END      
    
    -- ����ǰ ����      
    DELETE @SemiGoodQty      
      FROM @SemiGoodQty AS A JOIN _TDAItem AS C ON A.SemiGoodSeq = C.ItemSeq and C.CompanySeq = @CompanySeq --and AssetSeq = 4      
                             JOIN _TDAItemAsset AS D ON C.AssetSeq = D.AssetSeq and D.CompanySeq = @CompanySeq      
                             JOIN _TDASMinor AS E ON D.SMAssetGrp = E.MinorSeq AND E.MinorSeq = 6008005 and E.CompanySeq = @CompanySeq      
    
    UPDATE @SemiGoodQty      
       SET ItemSeq = B.ItemSeq      
      FROM @SemiGoodQty AS A JOIN _TPDMPSDailyProdPlan AS B ON A.ProdPlanSeq = B.ProdPlanSeq and CompanySeq = @CompanySeq      
     WHERE A.ItemSeq = 0      
      
    DECLARE @SemiGoodQtySeq TABLE      
    (      
        Seq         INT IDENTITY ,      
        WorkDate    NCHAR(8),      
        ItemSeq     INT,      
        ProdQty     DECIMAL(19,5),      
        SemiGoodSeq INT,      
        NeedQty     DECIMAL(19,5),      
        ProdPlanSeq INT,      
        SemiBomrev  NCHAR(2),      
        SemiProcRev NCHAR(2),      
        levCnt      INT,      
        SemiProdPlanSeq INT,      
        ProdPlanNo  NVARCHAR(30),      
        FactUnit    INT      
    )      
  
    --������ ����ǰ�� ��� �ϳ��� ��ȹ���� �����ǵ���   
    INSERT INTO @SemiGoodQtySeq      
    SELECT DISTINCT A.WorkDate,      
           A.ItemSeq,      
           A.ProdQty,      
           A.SemiGoodSeq,      
           A.NeedQty,      
           A.ProdPlanSeq, 
           A.SemiBomrev, 
           A.SemiProcRev, 
           A.levCnt, 
           0, 
           B.ProdPlanNo, 
           B.FactUnit 
      FROM @SemiGoodQty   AS A 
      JOIN #TPDMPProdPlan AS B ON A.ProdPlanSeq = B.ProdPlanSeq      
                
    -- ��õ���̺�            
    CREATE TABLE #TMP_SOURCETABLE (IDOrder INT, TABLENAME   NVARCHAR(100))                    

    -- ��õ ������ ���̺�            
    CREATE TABLE #TCOMSourceTracking (IDX_NO INT,             IDOrder INT,            Seq  INT,            Serl  INT,        SubSerl     INT,                    
                                      Qty    DECIMAL(19, 5),  STDQty  DECIMAL(19, 5), Amt  DECIMAL(19, 5), VAT   DECIMAL(19, 5))                          
            

    INSERT #TMP_SOURCETABLE              
             
    SELECT 1, '_TPDMPSProdReqItem'       -- �����Ƿ�        
    
    EXEC _SCOMSourceTracking  @CompanySeq, '_TPDMPSDailyProdPlan', '#TPDMPProdPlan','ProdPlanSeq', '',''         
    
    DECLARE @SemiGoodQtySeqADD TABLE      
    (      
        WorkDate    NCHAR(8),      
        ItemSeq     INT,      
        ProdQty     DECIMAL(19,5),      
        SemiGoodSeq INT,      
        NeedQty     DECIMAL(19,5),      
        ProdPlanSeq INT,      
        SemiBomrev  NCHAR(2),      
        SemiProcRev NCHAR(2),      
        levCnt      INT,      
        SemiProdPlanSeq INT,      
        ProdPlanNo  NVARCHAR(30),      
        FactUnit    INT,      
        SMAddType   INT      
    )      
    
      INSERT INTO @SemiGoodQtySeqADD      
      SELECT CONVERT(NCHAR(8),(DATEADD(DD,@EnvValue *(-1),A.ProdPlanEndDate)),112) AS WorkDate,      
             A.ItemSeq      AS ItemSeq,      
             A.ProdplanQty  AS ProdQty,      
             C.MatItemSeq   As SemiGoodSeq,      
             CEILING(A.ProdplanQty * C.NeedQtyDenominator / C.NeedQtyNumerator) AS NeedQty,   -- �ø�ó�� 100831 ������      
             A.ProdPlanSeq  AS ProdPlanSeq,      
             MAX(F.BomRev),      
             MAX(F.ProcRev),      
             1,  -- 9999���� 1�� ����    
             0,      
             A.ProdPlanNo,      
             A.FactUnit,      
             C.SMAddType      
    
        FROM #TPDMPProdPlan AS A JOIN #TCOMSourceTracking           AS B ON A.IDX_NO = B.IDX_NO      
                                 JOIN _TPDROUItemProcMatAdd         AS C ON B.Seq = C.ProdReqSeq AND B.Serl = C.ProdReqSerl AND C.CompanySeq = @CompanySeq      
                                 JOIN _TDAItem                      AS D ON C.MatItemSeq = D.ItemSeq AND D.CompanySeq = @CompanySeq      
                                 JOIN _TDAItemAsset                 AS E ON D.AssetSeq = E.AssetSeq AND E.CompanySeq = @CompanySeq AND E.SMAssetGrp IN (6008002, 6008004)       
                                 JOIN _TPDROUItemProcRevFactUnit    AS F ON A.FactUnit = F.FactUnit AND C.MatItemSeq = F.ItemSeq AND F.CompanySeq = @CompanySEq      
      GROUP BY A.ProdPlanEndDate, A.ItemSeq, A.ProdplanQty, C.MatItemSeq ,A.ProdplanQty, 
               C.NeedQtyDenominator, C.NeedQtyNumerator ,A.ProdPlanSeq, A.ProdPlanNo, A.FactUnit, C.SMAddType       
    
    -- ���� ����ǰ       
          
    DELETE @SemiGoodQtySeqADD      
      FROM @SemiGoodQtySeqADD AS A JOIN @SemiGoodQtySeq AS B ON A.ProdPlanSeq = B.ProdPlanSeq And A.SemiGoodSeq = B.SemiGoodSeq      
     WHERE A.SMAddType = 6048001 -- ����      
  
  
    -- ######################### 2012. 5. 23 hkim While������ ��� ������ Ǯ����  
    -- �ɼ�ǰ ������ ����ǰ Ǯ��  
    DELETE @SemiGoodQty   

    INSERT INTO @SemiGoodQty (WorkDate,ItemSeq,ProdQty,SemiGoodSeq ,NeedQty ,ProdPlanSeq ,SemiBomrev,SemiProcRev ,levCnt,FactUnit)      
    SELECT WorkDate,ItemSeq,ProdQty,SemiGoodSeq ,NeedQty ,ProdPlanSeq ,SemiBomrev,SemiProcRev ,levCnt,FactUnit  
      FROM @SemiGoodQtySeqADD  
    
    SELECT @levCnt = 1  
    
    WHILE(1=1)      
    BEGIN      
    TRUNCATE TABLE #MatNeed_GoodItem     
    TRUNCATE TABLE #MatNeed_MatItem_Result  

     
    IF (SELECT Count(*) FROM @SemiGoodQty WHERE LevCnt = @levCnt) = 0 BREAK      
    
    INSERT #MatNeed_GoodItem (ItemSeq,ProcRev,BOMRev,ProcSeq,AssyItemSeq,UnitSeq,Qty,ProdPlanSeq,WorkOrderSeq,WorkOrderSerl,IsOut,WorkDate)            
    SELECT DISTINCT W.SemiGoodSeq, W.SemiProcRev, W.SemiBomrev, 0, 0, D.STDUnitSeq, W.NeedQty, W.ProdPlanSeq, 0,0,'0', W.WorkDate         
      FROM @SemiGoodQty     AS W --JOIN _TPDMPSDailyProdPlan AS B On W.ProdPlanSeq = B.ProdPlanSeq AND B.CompanySeq = @CompanySeq  
      JOIN _TDAItem         AS I ON W.SemiGoodSeq = I.ItemSeq AND I.CompanySeq = @CompanySeq        
      JOIN _TDAItemAsset    AS A ON I.AssetSeq = A.AssetSeq AND A.CompanySeq = @CompanySeq        
      JOIN _TDAItemDefUnit  AS D ON W.SemiGoodSeq = D.ItemSeq AND @CompanySeq = D.CompanySeq     
                                AND D.UMModuleSeq = 1003003      -- �ҿ����� ������������ ��������� �㵵�� ���� 11.10.07 �輼ȣ �߰�    
                                                                 -- (_SPDMMGetItemNeedQty�󿡼� BOM������ ȯ���Ͽ� �ҿ䷮ ���ϱ�����)    
     WHERE W.levCnt = @levCnt      
       AND A.SMAssetGrp = 6008004        
    
    -- �ҿ����� ��������          
    EXEC dbo._SPDMMGetItemNeedQty @CompanySeq          
    
    INSERT INTO @SemiGoodQty(WorkDate,ItemSeq,ProdQty,SemiGoodSeq ,NeedQty ,ProdPlanSeq ,SemiBomrev,SemiProcRev ,levCnt,FactUnit,SMAssetGrp)        
    SELECT CONVERT(NCHAR(8),(DATEADD(DD,@EnvValue *(-1),A.WorkDate)),112),        
                   0, 0, B.MatItemSeq, B.NeedQty, A.ProdPlanSeq, ISNULL(F.SubItemBomRev,'00'),'00',@levCnt+1,0,D.SMAssetGrp        
      FROM #MatNeed_GoodItem        AS A 
      JOIN #MatNeed_MatItem_Result  AS B ON A.IDX_NO = B.IDX_NO        
      JOIN _TDAItem                 AS C ON B.MatItemSeq = C.ItemSeq and C.CompanySeq = @CompanySeq --and AssetSeq = 4        
      JOIN _TDAItemAsset            AS D ON C.AssetSeq = D.AssetSeq and D.CompanySeq = @CompanySeq        
      JOIN _TDASMinor               AS E ON D.SMAssetGrp = E.MinorSeq AND E.MinorSeq IN (6008004) AND E.CompanySeq = @CompanySeq        
      LEFT OUTER JOIN _TPDBOM       AS F ON A.ItemSeq = F.ItemSeq AND A.BOMRev = F.ItemBomRev  AND B.MatItemSeq = F.SubItemSeq AND F.CompanySeq = @CompanySeq        
      --LEFT OUTER JOIN (SELECT PB.ItemSeq, MAX(PB.ItemBOMRev) AS BOMRev   
      --                   FROM _TPDBOM AS PB  
      --                            JOIN _TDAItem AS IC ON PB.ItemSeq = IC.ItemSeq and IC.CompanySeq = @CompanySeq --and AssetSeq = 4      
      --                            JOIN _TDAItemAsset AS IA ON IC.AssetSeq = IA.AssetSeq   
      --                                                    and IA.CompanySeq = @CompanySeq     
      --                            JOIN _TDASMinor    AS SM ON IA.SMAssetGrp = SM.MinorSeq   
      --                                                    AND SM.MinorSeq IN ( 6008004)       
      --                                                    AND SM.CompanySeq = @CompanySeq      
      --                  WHERE PB.CompanySeq = @CompanySeq   
      --                  GROUP BY PB.ItemSeq)  AS SF ON B.MatItemSeq = SF.ItemSeq       --2012.07.13 BY ��³� :: 2���� �̻��� ����ǰ ��� BOM������ '00'���� ���õǴ� ���� �����ϱ� ���� ���� BOM������ ��������  
    UPDATE @SemiGoodQty        
       SET FactUnit = B.FactUnit        
      FROM @SemiGoodQty AS A JOIN @SemiGoodQtySeqADD AS B ON A.ProdPlanSeq = B.ProdPlanSeq        
    
    
    
    DELETE @SemiGoodQty        
     FROM @SemiGoodQty AS A JOIN _TPDBaseAheadItem AS B ON A.SemiGoodSeq = B.ItemSeq and A.FactUnit = B.FactUnit        
    
    
    UPDATE @SemiGoodQty        
       SET SemiProcRev = B.ProcRev        
     FROM @SemiGoodQty  AS A JOIN         
    (SELECT A.WorkDate, A.SemiGoodSeq, A.SemiBomRev, MAX(B.ProcRev) AS ProcRev        
      FROM @SemiGoodQty AS A          
      JOIN _TPDROUItemProcRevFactUnit AS B ON A.FactUnit = B.FactUnit         
                                          and A.SemiGoodSeq = B.ItemSeq          
                                          and A.SemiBomrev = B.BOMrev        
                                          and B.CompanySeq = @CompanySeq        
                                          and B.FrDate <= A.WorkDate        
                                          and B.ToDate >= A.WorkDate       
    GROUP BY A.WorkDate, A.SemiGoodSeq, A.SemiBomRev) AS B ON A.WorkDate = B.WorkDate AND A.SemiGoodSeq = B.SemiGoodSeq AND A.SemiBomRev = B.SemiBomRev        
    WHERE levCnt = @levCnt+1      
   
    SELECT @levCnt = @levCnt + 1  
    END        
    
   -- --������ ����ǰ�� �ΰ� �̻��� ��� ��ȹ������ �ߺ����� ������ ������ ������ ����ǰ ����ŭ ��ȹ�������� ������ ��ȹ�� ������ ��. 2012.07.05 By ��³�  
   -- ----------------------------------------------------------------------------------------------------------------------------------------------------  
   -- SELECT SemiGoodSeq, COUNT(*) AS Cnt  INTO #TempGoodCnt FROM @SemiGoodQtySeq GROUP BY SemiGoodSeq  
  
   -- UPDATE @SemiGoodQtySeq  
   --    SET NeedQty = CASE WHEN Cnt > 1 THEN NeedQty/Cnt ELSE NeedQty END   
   --   FROM @SemiGoodQtySeq AS A   
   --             JOIN #TempGoodCnt AS B ON A.SemiGoodSeq =  B.SemiGoodSeq  
      
   --------------------------------------------------------------------------------------------------------------------------------------------------------  
  
  
   -- --������ ����ǰ�� ���� ������ �ٸ����, �ջ�ó���� ���� ���� �����͸� ������ grouping 2012.07.16 BY ��³�  
  
    SELECT *  
      INTO #tempSemiGoodQtySeq  
      FROM @SemiGoodQtySeq  
  
    DELETE @SemiGoodQtySeq  
  
    INSERT INTO @SemiGoodQtySeq  
    SELECT WorkDate    ,        
           ItemSeq     ,        
           ProdQty     ,        
           SemiGoodSeq ,        
           SUM(NeedQty),        
           ProdPlanSeq ,        
           MAX(SemiBomrev)  ,        
           MAX(SemiProcRev) ,        
           MAX(levCnt)      ,        
           0             ,        
           ProdPlanNo  ,        
           FactUnit        
      FROM #tempSemiGoodQtySeq  
     GROUP BY WorkDate,ItemSeq,ProdQty,SemiGoodSeq,ProdPlanSeq, ProdPlanNo,FactUnit  
    
    -- ������ȸ
    SELECT MAX(X.FactUnit) AS FactUnit,   --���������ڵ� 
           MAX(B.FactUnitName) AS FactUnitName, --�������� 
           MAX(C.ItemName) AS ItemName, --ǰ�� 
           MAX(C.ItemNo) AS ItemNo, --ǰ�� 
           MAX(C.Spec) AS Spec, --�԰� 
           MAX(X.ProdPlanNo) AS ProdPlanNo, --�����ȹ��ȣ 
           X.SemiGoodSeq AS ItemSeq, --ǰ���ڵ� 
           MAX(D.UnitName) AS UnitName, --���� 
           MAX(Z.UnitSeq) AS UnitSeq, --�����ڵ� 
           X.SemiBOMRev AS BOMRev, --BOM���� 
           X.SemiBOMRev AS BOMRevName , --CASE WHEN E.BomRevName > '' THEN E.BomRevName ELSE A.BOMRev END AS BOMRevName,    --BOM���� BOMRevName 
           MAX(X.SemiProcRev) AS ProcRev, --�����帧���� 
           MAX(F.ProcRevName) AS ProcRevName      ,   --�����帧������ ProcRevName 
           SUM(X.NeedQty) AS ProdQty      , --�����ȹ���� 
           MAX(Z.ProdPlanEndDate) AS EndDate  , --�����ȹ�Ϸ��� 
           MAX(Q.AssetName) AS AssetName, 
           MAX(Q.AssetSeq) AS AssetSeq  
    
      FROM @SemiGoodQtySeq                AS X 
      LEFT OUTER JOIN #TPDMPProdPlan      AS Z WITH(NOLOCK) ON ( Z.ProdPlanSeq = X.ProdPlanSeq ) 
      JOIN _TPDMPSDailyProdPlan_Confirm   AS Y WITH(NOLOCK) ON ( Y.CompanySeq = @CompanySeq AND Y.CfmSeq = Z.ProdPlanSeq AND Y.CfmCode = 1)
      LEFT OUTER JOIN _TDAFactUnit        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.FactUnit = X.FactUnit ) 
      LEFT OUTER JOIN _TDAItem            AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq  = X.SemiGoodSeq ) 
      LEFT OUTER JOIN _TDAUnit            AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.UnitSeq  = Z.UnitSeq ) 
      LEFT OUTER JOIN _TPDBOMECOApply     AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq  = X.SemiGoodSeq AND E.ChgBomRev = X.SemiBOMRev AND E.chgBOMRev = '1' ) 
      LEFT OUTER JOIN _TPDROUItemProcRev  AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq  = X.SemiGoodSeq AND F.ProcRev = X.SemiProcRev ) 
      LEFT OUTER JOIN _TDAItemAsset       AS Q WITH(NOLOCK) ON ( Q.CompanySeq = @CompanySeq AND C.AssetSeq = Q.AssetSeq ) 
     
     WHERE (@SemiItemName = '' OR C.ItemName LIKE @SemiItemName + '%') 
       AND (@SemiItemNo = '' OR C.ItemNo LIKE @SemiItemNo + '%') 
       AND (@SemiSpec = '' OR C.Spec LIKE @SemiSpec + '%') 
     GROUP BY X.SemiGoodSeq, X.SemiBomRev
        
    RETURN 
GO
exec jongie_SPDSemiItemProdPlanListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <FactUnit>1</FactUnit>
    <ProdPlanYM>201310</ProdPlanYM>
    <DeptSeq />
    <ItemName />
    <ItemNo />
    <Spec />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1018427,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1015669