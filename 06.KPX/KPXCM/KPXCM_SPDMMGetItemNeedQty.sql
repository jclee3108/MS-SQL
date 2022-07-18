IF OBJECT_ID('KPXCM_SPDMMGetItemNeedQty') IS NOT NULL 
    DROP PROC KPXCM_SPDMMGetItemNeedQty
GO 

-- v2015.09.16 

-- ����ҿ���ȸ �� ����ǰ Batch Size Formula ���� by����õ 

/************************************************************
 ��  �� - �ҿ����籸�ϱ�
 �ۼ��� - 2008�� 12�� 19��
 �ۼ��� - ������
 ������ - 2010�� 04�� 24�� UPDATEd BY �ڼҿ� :: �ӽ����̺� �ε��� ����
 ������ - 2010�� 05�� 06�� ���� / SMDelvType 6032003 �� ���� �ҿ䷮ ���ϴ� �κп��� ���� (BOM������)
 ������ = 2010�� 06�� 11�� ������ : ȯ�漳����  BOM������ǰ MRP���Կ��� �߰�
                                  : BOM�����󼼴� ������� �� ���ԵǴ� ǰ���� �ƴ����� �ι���ũ�� ó�� ����ǰ�� ���ŷ� ó���ϰ� �ش����ǰ�� ������絵 �Բ� MRP�� Ǯ��� �ϴ� ��쵵 �־ �߰�.
 ������ - 2010�� 08�� 09�� ������ : ���պ�(_TPDBOMBatchItem) ���̺� overage �ִ� ��� overage�ݿ��Ͽ� ����û���� ����
                                  : �۾����ü����� ���պ�(_TPDBOMBatchItem) ���̺� ��ġ������� ������ �ٸ� ��� �� ������ ���� ����Ͽ� ����û���� ����
           2011�� 10�� 07�� �輼ȣ : BOM������ ȯ���� �ҿ䷮ ���ϵ��� ����(��ǰ���������ҿ�������  BOM���� ������� ����Ǿ�)
          2015��  2�� 27�� ������ : 1. ��ǰ���������κ��� ����ҿ䱸�� ��, ������ �ִ� ��쿡�� �ҿ䷮�и�*����ǰ �ҿ䷮(����)*����ǰ �ҿ䷮(�и�) ���� ����
                                     (������ �ĸ� 201502260421���� ��� ���� �÷ο� ���� �߻�)
    
      CREATE TABLE #MatNeed_GoodItem
     (
         IDX_NO          INT IDENTITY(1,1),
         ItemSeq         INT,        -- ��ǰ�ڵ�
         ProcRev         NCHAR(2),   -- �����帧����
         BOMRev          NCHAR(2),   -- BOM����
         ProcSeq         INT,        -- �����ڵ�
         AssyItemSeq     INT,        -- ����ǰ�ڵ�
         UnitSeq         INT,        -- �����ڵ�     (����ǰ�ڵ尡 ������ ����ǰ�����ڵ�, ������ ��ǰ�����ڵ�)
         Qty             DECIMAL,    -- ��ǰ����     (����ǰ�ڵ尡 ������ ����ǰ����)
         ProdPlanSeq     INT,        -- �����ȹ���ι�ȣ (�����Ƿڿ��� �߰��� �ɼ����縦 ������������)
         WorkOrderSeq    INT,        -- �۾����ó��ι�ȣ (�۾����ÿ��� �߰������ ��ϵ� ���縦 ������������)
         WorkOrderSerl   INT,        -- �۾����ó��μ��� (�۾����ÿ��� �߰������ ��ϵ� ���縦 ������������)
         IsOut           NCHAR(1)    -- �ν��� ���뿡 ��� '1'�̸� OutLossRate ����
     )
      CREATE TABLE #MatNeed_MatItem_Result
     (
         IDX_NO          INT,            -- ��ǰ�ڵ�
         MatItemSeq      INT,            -- �����ڵ�
         UnitSeq         INT,            -- �������
         NeedQty         DECIMAL(19,5),  -- �ҿ䷮
         InputType       INT
     )
      --
  ************************************************************/
 CREATE PROC KPXCM_SPDMMGetItemNeedQty    
     @CompanySeq     INT = 1            ,    
     @SMDelvType     NCHAR(1) = '0'     ,    
     @IsMRP          NCHAR(1) = '0'      --MRP���� �ҿ����縦 ���ϴ��� ����(BOM������ǰ MRP���Կ��� �������߰�)    
 AS    
     
     
     CREATE TABLE #MatNeed_MatItem    
     (    
         IDX_NO          INT,            -- ��ǰ�ڵ�    
         MatItemSeq      INT,            -- �����ڵ�    
         UnitSeq         INT,            -- �������    
         MatUnitSeq      INT,            -- ������    
         NeedQty         DECIMAL(19,5),  -- �ҿ䷮    
         InputType       INT,    
         SMDelvType      INT    
     )    
     
     CREATE TABLE #TMP_SOURCETABLE    
     (    
         IDOrder INT,    
         TABLENAME   NVARCHAR(100)    
     )    
     
     CREATE TABLE #TCOMSourceTracking    
     (    
         IDX_NO      INT,    
         IDOrder     INT,    
         Seq         INT,    
         Serl        INT,    
         SubSerl     INT,    
         Qty         DECIMAL(19, 5),    
         STDQty      DECIMAL(19, 5),    
         Amt         DECIMAL(19, 5),    
         VAT         DECIMAL(19, 5)    
     )    
     
     
     DECLARE  @EnvValue   NVARCHAR(100)   -- BOM������ǰ MRP���Կ���    
             ,@IsInclude  NCHAR(1)    
     EXEC dbo._SCOMEnv @CompanySeq,6227  ,1,@@PROCID,@EnvValue OUTPUT    
     
     IF @IsMRP = '1' AND @EnvValue IN ('1','True')    
         SELECT @IsInclude = '1'    
     ELSE    
         SELECT @IsInclude = '0'    
     
     
     DECLARE @ProdModuleSeq    INT,    
             @BOMModuleSeq     INT    
     SELECT  @ProdModuleSeq = 1003003,    -- ������� ���� �ڵ�    
             @BOMModuleSeq  = 1003004    -- BOM���� ���� �ڵ�    
     
     IF EXISTS(SELECT 1 FROM #MatNeed_GoodItem WHERE ProdPlanSeq > 0)    
     BEGIN    
     
         INSERT #TMP_SOURCETABLE    
         SELECT 1,'_TPDMPSProdReqItem'    
         UNION    
         SELECT 2,'_TSLOrderItem'    
     
     
     
 EXEC _SCOMSourceTracking @CompanySeq, '_TPDMPSDailyProdPlan', '#MatNeed_GoodItem', 'ProdPlanSeq', '', ''    
     
   END    
     
     
 -- CREATE INDEX IX_#MatNeed_GoodItem ON #MatNeed_GoodItem (IDX_NO) -- 20100424 �ڼҿ� �߰�    
     
     
     -- ��ǰ������ BOM������ �ٸ����    
     -- BOM������ ȯ�� �Ѵ�.    
     UPDATE #MatNeed_GoodItem      
        SET Qty = CASE WHEN US.ConvDen * UP.ConvNum * UP.ConvDen <> 0 THEN A.Qty * (US.ConvNum / US.ConvDen) / (UP.ConvNum / UP.ConvDen)      
                                                                 ELSE A.Qty      
                  END      
       FROM #MatNeed_GoodItem    AS A      
         JOIN _TDAItemDefUnit    AS B WITH(NOLOCK)  ON A.ItemSeq = B.ItemSeq      
         JOIN _TDAItemUnit       AS US WITH(NOLOCK)  ON A.ItemSeq = US.ItemSeq      
                                                    AND B.CompanySeq = US.CompanySeq      
                                                    AND A.UnitSeq = US.UnitSeq      
         JOIN _TDAItemUnit       AS UP WITH(NOLOCK)  ON A.ItemSeq = UP.ItemSeq      
                                                    AND B.CompanySeq = UP.CompanySeq      
                                                    AND B.STDUnitSeq = UP.UnitSeq      
      WHERE A.AssyItemSeq = 0      
        AND B.CompanySeq = @CompanySeq      
        AND B.UMModuleSeq = @BOMModuleSeq      
        AND A.UnitSeq <> B.STDUnitSeq      
     
     
     
     -- ����ǰ �ڵ尡 �ִ� ���    
     UPDATE #MatNeed_GoodItem      
        SET Qty = CASE WHEN US.ConvDen * UP.ConvNum * UP.ConvDen <> 0 THEN A.Qty * (US.ConvNum / US.ConvDen) / (UP.ConvNum / UP.ConvDen)      
                                                                      ELSE A.Qty      
                  END      
       FROM #MatNeed_GoodItem    AS A      
         JOIN _TDAItemDefUnit    AS B  WITH(NOLOCK)  ON A.AssyItemSeq = B.ItemSeq      
         JOIN _TDAItemUnit       AS US WITH(NOLOCK)  ON A.AssyItemSeq = US.ItemSeq      
                                                    AND B.CompanySeq = US.CompanySeq      
                                                    AND A.UnitSeq = US.UnitSeq      
         JOIN _TDAItemUnit       AS UP WITH(NOLOCK)  ON A.AssyItemSeq = UP.ItemSeq      
                                                    AND B.CompanySeq = UP.CompanySeq      
                                                    AND B.STDUnitSeq = UP.UnitSeq      
      WHERE A.AssyItemSeq <> 0      
        AND B.CompanySeq = @CompanySeq      
        AND B.UMModuleSeq = @BOMModuleSeq      
        AND A.UnitSeq <> B.STDUnitSeq      
     
     
     
     -- 1. ��ǰ���������κ��� ����ҿ䱸�ϱ�    
     -- ��ǰ��ü�� ���    
     INSERT  #MatNeed_MatItem    
     SELECT   A.IDX_NO    
             ,M.MatItemSeq    
             ,M.UnitSeq    
             ,ISNULL(U.STDUnitSeq,M.UnitSeq)    
             ,A.Qty  * CASE WHEN M.NeedQtyNumerator * M.NeedQtyDenominator <> 0 THEN (M.NeedQtyNumerator / M.NeedQtyDenominator) ELSE 1 END    
                     * CASE WHEN A.IsOut = '1' THEN (1 + M.OutLossRate / 100.0) ELSE (1 + M.InLossRate / 100.0) END    
             ,CASE M.SMDelvType  WHEN 6032004    THEN 6042003    -- ������    
                                 WHEN 6032005    THEN 6042004    -- ���������    
                                 ELSE                 6042002    -- ����    
              END    
             ,M.SMDelvType    
       FROM #MatNeed_GoodItem                    AS A    
                    JOIN _TPDROUItemProcMat      AS M  WITH(NOLOCK) ON A.ItemSeq     = M.ItemSeq    
                                                                   AND A.ProcRev     = M.ProcRev    
                                                                   AND A.BOMRev      = M.BOMRev    
         LEFT OUTER JOIN _TDAItemDefUnit         AS U  WITH(NOLOCK) ON M.CompanySeq  = U.CompanySeq    
                                                                   AND M.MatItemSeq  = U.ItemSeq    
           AND U.UMModuleSeq = @ProdModuleSeq    
      WHERE A.ProcSeq = 0    
        AND M.CompanySeq = @CompanySeq    
     
     
     
     --  ������ �ִ� ���    
     INSERT  #MatNeed_MatItem    
     SELECT   A.IDX_NO    
             ,M.MatItemSeq    
             ,M.UnitSeq    
             ,ISNULL(U.STDUnitSeq,M.UnitSeq)    
               --,CASE WHEN M.NeedQtyDenominator*M.AssyQtyNumerator*M.AssyQtyDenominator <> 0 THEN CONVERT(DECIMAL(19,5), A.Qty * (CONVERT(DECIMAL(19,10),(M.NeedQtyNumerator / M.NeedQtyDenominator)) / CONVERT(DECIMAL(19,10), (M.AssyQtyNumerator / M.AssyQtyDenominator)))) -- �Ҽ����� �ʹ� ���Ƽ� ©�� ����� �־� �Ҽ��� 5�ڸ��� ����    
             , CASE WHEN(M.NeedQtyDenominator <> 0 AND M.AssyQtyNumerator <> 0 AND M.AssyQtyDenominator <> 0) THEN CONVERT(DECIMAL(19,5), A.Qty * (CONVERT(DECIMAL(19,10),(M.NeedQtyNumerator / M.NeedQtyDenominator)) / CONVERT(DECIMAL(19,10), (M.AssyQtyNumerator / M.AssyQtyDenominator))))           --case when ���� ���� 2015.02.27 hjlim
                    WHEN M.NeedQtyDenominator <> 0                                                            THEN A.Qty * (M.NeedQtyNumerator / M.NeedQtyDenominator)    
                    ELSE A.Qty * 1 END   -- A.Qty�� ����ǰ�� �����̸� �����ҿ䷮���� ��������Ѵ�.    
                     * CASE WHEN A.IsOut = '1' THEN (1 + M.OutLossRate / 100.0) ELSE (1 + M.InLossRate / 100.0) END    
             ,CASE M.SMDelvType  WHEN 6032004    THEN 6042003    -- ������    
                                 WHEN 6032005    THEN 6042004    -- ���������    
                                 ELSE                 6042002    -- ����    
              END    
             ,M.SMDelvType    
       FROM #MatNeed_GoodItem                    AS A    
                    JOIN _TPDROUItemProcMat      AS M  WITH(NOLOCK) ON A.ItemSeq     = M.ItemSeq    
                                                                   AND A.ProcRev     = M.ProcRev    
                                                                   AND A.BOMRev      = M.BOMRev    
                                                                   AND A.ProcSeq     = M.ProcSeq    
         LEFT OUTER JOIN _TDAItemDefUnit         AS U  WITH(NOLOCK) ON M.CompanySeq  = U.CompanySeq    
                                                                   AND M.MatItemSeq  = U.ItemSeq    
                                                                   AND U.UMModuleSeq = @ProdModuleSeq    
      WHERE A.ProcSeq > 0    
        AND M.CompanySeq = @CompanySeq    
            
     -- �����ȹ�� ������ �ҿ����翡 ���� �ҿ䷮ �������� �߰� 2011-01-03 �۱⿬ �߰�    
                
     IF EXISTS (SELECT * FROM sysobjects where name = '_TPDMPSProdPlanProcMat')    
     BEGIN       
         UPDATE #MatNeed_GoodItem    
            SET ProdPlanSeq = B.ProdPlanSeq    
           FROM #MatNeed_GoodItem AS A JOIN _TPDSFCWorkOrder AS B ON A.WorkOrderSerl = B.WorkOrderSerl and B.CompanySeq = @CompanySeq    
          WHERE ISNULL(A.ProdPlanSeq,0) = 0    
          
          
         IF EXISTS(SELECT 1 FROM _TPDMPSProdPlanProcMat AS A JOIN #MatNeed_GoodItem AS B ON A.ProdPlanSeq = B.ProdPlanSeq AND A.CompanySeq = @CompanySeq)    
         BEGIN    
             DELETE #MatNeed_MatItem FROM #MatNeed_MatItem As A JOIN #MatNeed_GoodItem AS B ON A.IDX_NO = B.IDX_NO    
                                                                JOIN _TPDMPSProdPlanProcMat AS C On B.ProdPlanSeq = C.ProdPlanSeq AND C.CompanySeq = @CompanySeq    
                                                                    
                                                                                
             INSERT  #MatNeed_MatItem    
             SELECT   A.IDX_NO    
                     ,M.MatItemSeq    
                     ,M.UnitSeq    
                     ,ISNULL(U.STDUnitSeq,M.UnitSeq)    
                     ,A.Qty  * CASE WHEN M.NeedQtyNumerator * M.NeedQtyDenominator <> 0 THEN (M.NeedQtyNumerator / M.NeedQtyDenominator) ELSE 1 END    
                             * CASE WHEN A.IsOut = '1' THEN (1 + M.OutLossRate / 100.0) ELSE (1 + M.InLossRate / 100.0) END    
                     ,CASE M.SMDelvType  WHEN 6032004    THEN 6042003    -- ������    
                                         WHEN 6032005    THEN 6042004    -- ���������    
                                         ELSE                  6042002    -- ����    
                      END    
                     ,M.SMDelvType    
               FROM #MatNeed_GoodItem                    AS A    
                            JOIN _TPDMPSProdPlanProcMat  AS M  WITH(NOLOCK) ON A.ItemSeq     = M.ItemSeq    
                                                                           AND A.ProcRev     = M.ProcRev    
                                                                           AND A.BOMRev      = M.BOMRev    
                                                                           AND A.ProdPlanSeq = M.ProdPlanSeq    
     LEFT OUTER JOIN _TDAItemDefUnit         AS U  WITH(NOLOCK) ON M.CompanySeq  = U.CompanySeq    
                                                                           AND M.MatItemSeq  = U.ItemSeq    
                                                                           AND U.UMModuleSeq = @ProdModuleSeq    
              WHERE A.ProcSeq = 0    
                AND M.CompanySeq = @CompanySeq    
     
     
     
             --  ������ �ִ� ���    
             INSERT  #MatNeed_MatItem    
             SELECT   A.IDX_NO    
                     ,M.MatItemSeq    
                     ,M.UnitSeq    
                     ,ISNULL(U.STDUnitSeq,M.UnitSeq)    
                     --,CASE WHEN M.NeedQtyDenominator*M.AssyQtyNumerator*M.AssyQtyDenominator <> 0 THEN CONVERT(DECIMAL(19,5), A.Qty * (CONVERT(DECIMAL(19,10),(M.NeedQtyNumerator / M.NeedQtyDenominator)) / CONVERT(DECIMAL(19,10), (M.AssyQtyNumerator / M.AssyQtyDenominator))))     
                     ,CASE WHEN(M.NeedQtyDenominator <> 0 AND M.AssyQtyNumerator <> 0 AND M.AssyQtyDenominator <> 0) THEN CONVERT(DECIMAL(19,5), A.Qty * (CONVERT(DECIMAL(19,10),(M.NeedQtyNumerator / M.NeedQtyDenominator)) / CONVERT(DECIMAL(19,10), (M.AssyQtyNumerator / M.AssyQtyDenominator))))           --case when ���� ���� 2015.02.27 hjlim
                           WHEN M.NeedQtyDenominator <> 0                                         THEN A.Qty * (M.NeedQtyNumerator / M.NeedQtyDenominator)    
                           ELSE A.Qty * 1 END   -- A.Qty�� ����ǰ�� �����̸� �����ҿ䷮���� ��������Ѵ�.    
                             * CASE WHEN A.IsOut = '1' THEN (1 + M.OutLossRate / 100.0) ELSE (1 + M.InLossRate / 100.0) END    
                     ,CASE M.SMDelvType  WHEN 6032004    THEN 6042003    -- ������    
                                         WHEN 6032005    THEN 6042004    -- ���������    
                                         ELSE                 6042002    -- ����    
                      END    
                     ,M.SMDelvType    
               FROM #MatNeed_GoodItem                    AS A    
                            JOIN _TPDMPSProdPlanProcMat  AS M  WITH(NOLOCK) ON A.ItemSeq     = M.ItemSeq    
                                                                           AND A.ProcRev     = M.ProcRev    
                                                                           AND A.BOMRev      = M.BOMRev    
                                                                           AND A.ProcSeq     = M.ProcSeq    
                                                                           AND A.ProdPlanSeq = M.ProdPlanSeq    
                 LEFT OUTER JOIN _TDAItemDefUnit         AS U  WITH(NOLOCK) ON M.CompanySeq  = U.CompanySeq    
                                                                           AND M.MatItemSeq  = U.ItemSeq    
                                                                           AND U.UMModuleSeq = @ProdModuleSeq    
              WHERE A.ProcSeq > 0    
                AND M.CompanySeq = @CompanySeq    
         END          
     END             
     
     
     -- 2. �����Ƿڿ��� �߰��� ����(�ɼ�����)      -->> �����ȹ���� Ȯ���� �۾����ù�ȣ�� ������ �Էµ�.    
     INSERT  #MatNeed_MatItem    
     SELECT   A.IDX_NO    
             ,M.MatItemSeq    
             ,M.UnitSeq    
             ,ISNULL(U.STDUnitSeq,M.UnitSeq)    
             ,A.Qty  * CASE WHEN M.NeedQtyNumerator * M.NeedQtyDenominator <> 0 THEN (M.NeedQtyNumerator / M.NeedQtyDenominator)     
                            ELSE 1    
                       END   -- A.Qty�� ����ǰ�� �����̸� �����ҿ䷮���� ��������Ѵ�.    
                     * CASE WHEN A.IsOut = '1' THEN (1 + M.OutLossRate / 100) ELSE (1 + M.InLossRate / 100) END    
                     * CASE M.SMAddType WHEN 6048002 THEN -1    
                                        ELSE 1    
                       END    
             ,CASE  --WHEN M.ReqType = '1'        THEN 6042005    -- �����ɼ�    
                    WHEN M.SMDelvType = 6032004 THEN 6042003    -- ������    
                    WHEN M.SMDelvType = 6032005 THEN 6042004    -- ���������    
                    ELSE                             6042002    -- ����    
              END    
             ,M.SMDelvType    
       FROM #MatNeed_GoodItem                    AS A    
 --                   JOIN _TPDMPSDailyProdPlan    AS P  WITH(NOLOCK) ON A.ProdPlanSeq   = P.ProdPlanSeq    
                    JOIN #TCOMSourceTracking     AS T               ON A.IDX_NO        = T.IDX_NO    
                      JOIN _TPDROUItemProcMatAdd   AS M  WITH(NOLOCK) ON T.Seq           = M.ProdReqSeq    
                                                                   AND T.Serl          = M.ProdReqSerl    
                                                                   AND (A.ProcSeq = 0 OR  A.ProcSeq = M.ProcSeq)    
         LEFT OUTER JOIN _TDAItemDefUnit         AS U  WITH(NOLOCK) ON M.CompanySeq    = U.CompanySeq    
                                                                   AND M.MatItemSeq    = U.ItemSeq    
                                                                   AND U.UMModuleSeq   = @ProdModuleSeq    
        WHERE A.ProdPlanSeq > 0    
        AND M.CompanySeq = @CompanySeq    
        AND (M.WorkOrderSeq = 0 OR M.WorkOrderSeq IS NULL)    
        AND T.IDOrder = 1    
     
     
     
     --UPDATE A    
     --   SET InputType = 6042005    
     --  FROM #MatNeed_MatItem             AS A    
     --    JOIN #TCOMSourceTracking        AS T                ON A.IDX_NO         = T.IDX_NO    
     --    JOIN _TSLOrderItemSpecOption    AS S WITH(NOLOCK)   ON T.Seq            = S.OrderSeq    
     --                                                       AND T.Serl           = S.OrderSerl    
     --    JOIN _TSLOption                 AS P WITH(NOLOCK)   ON S.OptionSeq      = P.OptionSeq    
     -- WHERE T.IDOrder = 2    
     --   AND S.CompanySeq = @CompanySeq    
     --   AND P.CompanySeq = @CompanySeq    
     --   AND P.SMOptionKind = 8020002    
     
     
     --3. �۾������� �߰����簡 �ִ� ���    
     INSERT  #MatNeed_MatItem    
     SELECT   A.IDX_NO    
             ,M.MatItemSeq    
             ,M.UnitSeq    
             ,ISNULL(U.STDUnitSeq,M.UnitSeq)    
             ,A.Qty  * CASE WHEN M.NeedQtyNumerator * M.NeedQtyDenominator <> 0 THEN (M.NeedQtyNumerator / M.NeedQtyDenominator)    
                            ELSE 1    
                       END   -- A.Qty�� ����ǰ�� �����̸� �����ҿ䷮���� ��������Ѵ�.    
                     * CASE WHEN A.IsOut = '1' THEN (1 + M.OutLossRate / 100.0) ELSE (1 + M.InLossRate / 100.0) END    
                     * CASE M.SMAddType WHEN 6048002 THEN -1    
                                        ELSE 1    
                       END    
             ,CASE  --WHEN M.ReqType = '1'        THEN 6042005    -- �����ɼ�    
                    WHEN M.SMDelvType = 6032004 THEN 6042003    -- ������    
                    WHEN M.SMDelvType = 6032005 THEN 6042004    -- ���������    
                    ELSE                             6042002    -- ����    
              END    
             ,M.SMDelvType    
       FROM #MatNeed_GoodItem                    AS A   
                    JOIN _TPDROUItemProcMatAdd   AS M  WITH(NOLOCK) ON A.WorkOrderSeq  = M.WorkOrderSeq    
                                                                   AND A.WorkOrderSerl = M.WorkOrderSerl    
         LEFT OUTER JOIN _TDAItemDefUnit         AS U  WITH(NOLOCK) ON M.CompanySeq    = U.CompanySeq    
                                                                   AND M.MatItemSeq    = U.ItemSeq    
                                                                   AND U.UMModuleSeq   = @ProdModuleSeq    
      WHERE A.WorkOrderSeq > 0    
        AND M.CompanySeq = @CompanySeq    
     
  -- ����ɼ�ǰ�� ���� ������ ����ɼ����� ����  ������ �ּ� ó���ϰ� ��ġ ���� 2012. 5. 21 hkim    
     UPDATE A    
        SET InputType = 6042005    
       FROM #MatNeed_MatItem             AS A    
         JOIN #TCOMSourceTracking        AS T                ON A.IDX_NO         = T.IDX_NO    
         JOIN _TSLOrderItemSpecOption    AS S WITH(NOLOCK)   ON T.Seq            = S.OrderSeq    
                                                            AND T.Serl           = S.OrderSerl    
                                                            AND A.MatItemSeq  = S.ItemSeq  -- 2012. 5. 21 ItemSeq �߰� hkim    
         JOIN _TSLOption                 AS P WITH(NOLOCK)   ON S.OptionSeq      = P.OptionSeq    
      WHERE T.IDOrder = 2    
        AND S.CompanySeq = @CompanySeq    
        AND P.CompanySeq = @CompanySeq    
        AND P.SMOptionKind = 8020002    
     
     

    
    -- ���պ� ��ϵǾ� ������ ���� 
    DELETE A
      FROM #MatNeed_MatItem					 AS A WITH(NOLOCK)  
      LEFT OUTER JOIN #MatNeed_GoodItem		 AS B WITH(NOLOCK) ON ( A.IDX_NO = B.IDX_NO ) 
      LEFT OUTER JOIN _TPDSFCWorkReport		 AS W WITH(NOLOCK) ON ( W.CompanySeq = @CompanySeq AND B.WorkOrderSeq = W.WorkOrderSeq AND B.WorkOrderSerl = W.WorkOrderSerl ) 
                 JOIN KPXCM_TPDBOMBatch      AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq 
                                                                AND C.FactUnit = W.FactUnit 
                                                                AND C.ItemSeq = W.GoodItemSeq 
                                                                AND W.WorkDate BETWEEN C.DateFr AND C.DateTo 
                                                                  ) 
    -- ���պ� ��ϵǾ� ������ ����, END 
    
    --1-2. ���պ� ��� �ִ� ��� (2009.09.29 �߰�) 
    INSERT  #MatNeed_MatItem    
    SELECT A.IDX_NO    
           ,I.ItemSeq    
           ,I.InputUnitSeq    
           ,ISNULL(U.STDUnitSeq,I.InputUnitSeq)    
           ,CASE WHEN I.NeedQtyNumerator * I.NeedQtyDenominator <> 0 
                 THEN (
                          CASE WHEN I.Overage > 0 
                               THEN ((W.ProdQty/C.BatchSize) * (I.NeedQtyNumerator / I.NeedQtyDenominator) * I.Overage / 100) * (CASE WHEN UP.ConvDen = 0 THEN 0 ELSE CONVERT(DECIMAL(19,5),ISNULL(UP.ConvNum,1) / ISNULL(UP.ConvDen,1)) END)
                               ELSE (W.ProdQty/C.BatchSize) * (I.NeedQtyNumerator / I.NeedQtyDenominator) * (CASE WHEN UP.ConvDen = 0 THEN 0 ELSE CONVERT(DECIMAL(19,5),ISNULL(UP.ConvNum,1) / ISNULL(UP.ConvDen,1)) END)
                               END
                      )    
                  ELSE 1    
            END     
            ,CASE I.SMDelvType WHEN 6032004    THEN 6042003    -- ������    
                               WHEN 6032005    THEN 6042004    -- ���������    
                               ELSE 6042002    -- ����    
             END
            ,I.SMDelvType    
      FROM #MatNeed_GoodItem                     AS A    
                    JOIN _TPDSFCWorkReport       AS W  WITH(NOLOCK) ON A.WorkOrderSeq= W.WorkOrderSeq    
                                                                   AND A.WorkOrderSerl = W.WorkOrderSerl    
                                                                   AND W.CompanySeq    = @CompanySeq 
                    JOIN KPXCM_TPDBOMBatch       AS C  WITH(NOLOCK) ON C.CompanySeq  = W.CompanySeq
																   AND C.FactUnit    = W.FactUnit    
                                                                   AND C.ItemSeq  = W.AssyItemSeq 
                                                                   AND W.WorkDate BETWEEN C.DateFr AND C.DateTo 
                    JOIN KPXCM_TPDBOMBatchItem   AS I  WITH(NOLOCK) ON C.BatchSeq    = I.BatchSeq    
                                                                   AND C.CompanySeq  = I.CompanySeq    
                                                                   AND (ISNULL(I.ProcSeq, 0) = 0  OR W.ProcSeq  = I.ProcSeq) 
                                                                   AND W.WorkDate BETWEEN I.DateFr AND I.DateTo 
         LEFT OUTER JOIN _TDAItemDefUnit         AS U  WITH(NOLOCK) ON I.CompanySeq  = U.CompanySeq    
                                                                   AND I.ItemSeq     = U.ItemSeq    
                                                                   AND U.UMModuleSeq = @ProdModuleSeq 
         LEFT OUTER JOIN _TDAItemUnit			 AS UP WITH(NOLOCK) ON UP.CompanySeq  = I.CompanySeq	
																   AND UP.UnitSeq = I.InputUnitSeq		
                                                                   AND UP.ItemSeq = A.ItemSeq			
    
      CREATE INDEX IDX_MatNeed_MatItem1 ON #MatNeed_MatItem(MatItemSeq,UnitSeq )
      CREATE INDEX IDX_MatNeed_MatItem2 ON #MatNeed_MatItem(MatItemSeq,MatUnitSeq )
     
     -- 4. ��������� ��ϵ� ��������� �ٸ� ��� ����ȯ���� �ؾ��Ѵ�.    
     UPDATE #MatNeed_MatItem    
        SET NeedQty = A.NeedQty * (US.ConvNum / US.ConvDen) / (UP.ConvNum / UP.ConvDen)    
       FROM #MatNeed_MatItem     AS A    
         JOIN _TDAItemUnit       AS US WITH(NOLOCK)  ON A.MatItemSeq = US.ItemSeq    
                                                    AND A.UnitSeq    = US.UnitSeq    
         JOIN _TDAItemUnit       AS UP WITH(NOLOCK)  ON A.MatItemSeq = UP.ItemSeq    
                                                    AND A.MatUnitSeq = UP.UnitSeq    
    WHERE A.UnitSeq <> A.MatUnitSeq    
        AND US.CompanySeq = @CompanySeq    
        AND UP.CompanySeq = @CompanySeq    
        AND US.ConvDen <> 0    
        AND UP.ConvNum <> 0    
        AND UP.ConvDen <> 0    
     
     
     DECLARE @Dec        INT    
     
     
     -- ȯ�漳���� �������� (�Ҽ��� �ڸ��� 5)    
     EXEC dbo._SCOMEnv @CompanySeq,5,0,@@PROCID,@EnvValue OUTPUT -- �Ҽ����ڸ����� ȯ�漳���� BOM �ڸ����� ������ �;��ؼ� 5���� 4�� �ٲ�  -- 4���� 5�� �ٽ� �ٲ� 2012. 1. 9 hkim    
     
     SELECT @Dec = ISNULL(@EnvValue, 0) 
     
     CREATE INDEX IDX_MatNeed_MatItem3 ON #MatNeed_MatItem(MatUnitSeq)
     
     -- 5 ǰ�� ����    
     IF @SMDelvType = '1'    
     BEGIN    
         INSERT #MatNeed_MatItem_Result    
         SELECT IDX_NO, MatItemSeq, MatUnitSeq,    
                CASE WHEN B.SMDecPointSeq IN (1003001, 0) THEN ROUND(SUM(NeedQty), @Dec, 0)   -- �ݿø�    
                     WHEN B.SMDecPointSeq = 1003002 THEN ROUND(SUM(NeedQty), @Dec, -1)         -- ����    
                     WHEN B.SMDecPointSeq = 1003003 THEN ROUND(SUM(NeedQty) + CAST(4 AS DECIMAL(19, 5)) / POWER(10, (@Dec + 1)),@Dec, 0)       -- �ø�    
                     ELSE ROUND(SUM(NeedQty), @Dec, 0)   -- �ݿø�    
     --                ELSE CEILING(SUM(NeedQty) * POWER(10,@Dec)) / POWER(10,@Dec)    -- ����Ʈ : �Ҽ������Ͽ��� �ø�.    
                END  ,    
                InputType     
                  --MAX(SMDelvType)  -- �߰������Է½ÿ��� �� �����Ͱ� ���� �׷��Ƿ� MAX������ ó���Ѵ�. -- 2010. 12. 30 hkim Ÿ SP���� ȣ��� ���� �߻�    
           FROM #MatNeed_MatItem     AS A    
             JOIN _TDAUnit           AS B ON A.MatUnitSeq = B.UnitSeq    
                                         AND B.CompanySeq = @CompanySeq    
       WHERE (@IsInclude = '1' OR A.SMDelvType <> 6032003)      -- 2010. 5. 6 ���� ����(BOM������ ����)    
          GROUP BY IDX_NO, MatItemSeq, MatUnitSeq, InputType, B.SMDecPointSeq    
     END    
     ELSE    
     BEGIN    
         INSERT #MatNeed_MatItem_Result    
         SELECT IDX_NO, MatItemSeq, MatUnitSeq,    
                CASE WHEN B.SMDecPointSeq IN (1003001, 0) THEN ROUND(SUM(NeedQty), @Dec, 0)   -- �ݿø�    
                     WHEN B.SMDecPointSeq = 1003002 THEN ROUND(SUM(NeedQty), @Dec, -1)         -- ����    
                     WHEN B.SMDecPointSeq = 1003003 THEN ROUND(SUM(NeedQty) + CAST(4 AS DECIMAL(19, 5)) / POWER(10, (@Dec + 1)),@Dec, 0)        -- �ø�    
                     ELSE ROUND(SUM(NeedQty), @Dec, 0)   -- �ݿø�    
     --                ELSE CEILING(SUM(NeedQty) * POWER(10,@Dec)) / POWER(10,@Dec)    -- ����Ʈ : �Ҽ������Ͽ��� �ø�.    
                END  ,    
                InputType     
                --MAX(SMDelvType)  -- �߰������Է½ÿ��� �� �����Ͱ� ���� �׷��Ƿ� MAX������ ó���Ѵ�. -- 2010. 12. 30 hkim Ÿ SP���� ȣ��� ���� �߻�    
           FROM #MatNeed_MatItem     AS A    
             JOIN _TDAUnit           AS B ON A.MatUnitSeq = B.UnitSeq    
                                         AND B.CompanySeq = @CompanySeq    
       WHERE (@IsInclude = '1' OR A.SMDelvType <> 6032003)      -- 2010. 5. 6 ���� ����(BOM������ ����)    
          GROUP BY IDX_NO, MatItemSeq, MatUnitSeq, InputType, B.SMDecPointSeq    
     END    
     
   RETURN