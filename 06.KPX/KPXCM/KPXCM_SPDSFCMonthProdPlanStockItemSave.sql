  
IF OBJECT_ID('KPXCM_SPDSFCMonthProdPlanStockItemSave') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCMonthProdPlanStockItemSave  
GO  
  
-- v2015.10.20  
  
-- �������ȹ-���� by ����õ   
CREATE PROC KPXCM_SPDSFCMonthProdPlanStockItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPXCM_TPDSFCMonthProdPlanStockItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TPDSFCMonthProdPlanStockItem'   
    IF @@ERROR <> 0 RETURN    
    
    
    ALTER TABLE #KPXCM_TPDSFCMonthProdPlanStockItem ADD PlanYMSub NCHAR(6) NULL 
    ALTER TABLE #KPXCM_TPDSFCMonthProdPlanStockItem ADD SalesPlanQtyM1 DECIMAL(19,5) NULL 
    ALTER TABLE #KPXCM_TPDSFCMonthProdPlanStockItem ADD SalesPlanQtyM2 DECIMAL(19,5) NULL 
    ALTER TABLE #KPXCM_TPDSFCMonthProdPlanStockItem ADD ProdPlanQtyM1 DECIMAL(19,5) NULL 
    ALTER TABLE #KPXCM_TPDSFCMonthProdPlanStockItem ADD ProdPlanQtyM2 DECIMAL(19,5) NULL 
    ALTER TABLE #KPXCM_TPDSFCMonthProdPlanStockItem ADD SelfQtyM1 DECIMAL(19,5) NULL 
    ALTER TABLE #KPXCM_TPDSFCMonthProdPlanStockItem ADD SelfQtyM2 DECIMAL(19,5) NULL 
    ALTER TABLE #KPXCM_TPDSFCMonthProdPlanStockItem ADD LastQtyM1 DECIMAL(19,5) NULL 
    ALTER TABLE #KPXCM_TPDSFCMonthProdPlanStockItem ADD LastQtyM2 DECIMAL(19,5) NULL 
    
    UPDATE A 
       SET PlanYMSub = PlanYM 
      FROM #KPXCM_TPDSFCMonthProdPlanStockItem AS A 
    
    
    --select * from #KPXCM_TPDSFCMonthProdPlanStockItem 
    --return 
    
    --IF @WorkingTag = 'Cfm'
    --BEGIN 
    --    UPDATE A 
    --       SET WorkingTag = 'A'
    --      FROM #KPXCM_TPDSFCMonthProdPlanStockItem AS A 
    --END 
    
    
    IF @WorkingTag <> 'SS'
    BEGIN 
        
        ----------------------------------------------------------------------------------
        -- �ǸŰ�ȹ ���� 
        ----------------------------------------------------------------------------------
        DECLARE @BizUnit    INT, 
                @PlanYM     NCHAR(6) 
        
        SELECT TOP 1 
               @PlanYM = PlanYM, 
               @BizUnit = B.BizUnit 
          FROM #KPXCM_TPDSFCMonthProdPlanStockItem  AS A 
          JOIN _TDAFactUnit                         AS B ON ( B.CompanySeq = @CompanySeq AND B.FactUnit = A.FactUnit ) 
            

        
        UPDATE A 
           SET SalesPlanQty = ISNULL(B.PlanQty,0),  -- Month 
               SalesPlanQtyM1 = ISNULL(C.PlanQty,0), -- Month + 1 
               SalesPlanQtyM2 = ISNULL(D.PlanQty,0) -- Month + 2 
          FROM #KPXCM_TPDSFCMonthProdPlanStockItem AS A 
          LEFT OUTER JOIN ( 
                            SELECT Z.ItemSeq, SUM(Z.PlanQty) AS PlanQty 
                              FROM KPXCM_TSLMonthSalesPlan AS Z 
                              JOIN ( 
                                    SELECT Y.BizUnit, Y.DeptSeq, Y.PlanYM, MAX(PlanRev) MaxPlanRev
                                      FROM KPXCM_TSLMonthSalesPlan AS Y
                                     WHERE Y.CompanySeq = @CompanySeq 
                                     GROUP BY Y.BizUnit, Y.DeptSeq, Y.PlanYM 
                                   ) AS Q ON ( Q.BizUnit = Z.BizUnit AND Q.DeptSeq = Z.DeptSeq AND Q.PlanYM = Z.PlanYM AND Q.MaxPlanRev = Z.PlanRev ) 
                             WHERE Z.CompanySeq = @CompanySeq 
                               AND Z.BizUnit = @BizUnit 
                               AND Z.PlanYM = @PlanYM 
                             GROUP BY Z.ItemSeq
                          ) AS B ON ( B.ItemSeq = A.ItemSeq ) 
          LEFT OUTER JOIN ( 
                            SELECT Z.ItemSeq, SUM(Z.PlanQty) AS PlanQty 
                              FROM KPXCM_TSLMonthSalesPlan AS Z 
                              JOIN ( 
                                    SELECT Y.BizUnit, Y.DeptSeq, Y.PlanYM, MAX(PlanRev) MaxPlanRev
                                      FROM KPXCM_TSLMonthSalesPlan AS Y
                                     WHERE Y.CompanySeq = @CompanySeq 
                                     GROUP BY Y.BizUnit, Y.DeptSeq, Y.PlanYM 
                                   ) AS Q ON ( Q.BizUnit = Z.BizUnit AND Q.DeptSeq = Z.DeptSeq AND Q.PlanYM = Z.PlanYM AND Q.MaxPlanRev = Z.PlanRev ) 
                             WHERE Z.CompanySeq = @CompanySeq 
                               AND Z.BizUnit = @BizUnit 
                               AND Z.PlanYM = CONVERT(NCHAR(6),DATEADD(MM,1,@PlanYM + '01'),112)
                             GROUP BY Z.ItemSeq
                          ) AS C ON ( C.ItemSeq = A.ItemSeq ) 
          LEFT OUTER JOIN ( 
                            SELECT Z.ItemSeq, SUM(Z.PlanQty) AS PlanQty 
                              FROM KPXCM_TSLMonthSalesPlan AS Z 
                              JOIN ( 
                                    SELECT Y.BizUnit, Y.DeptSeq, Y.PlanYM, MAX(PlanRev) MaxPlanRev
                                      FROM KPXCM_TSLMonthSalesPlan AS Y
                                     WHERE Y.CompanySeq = @CompanySeq 
                                     GROUP BY Y.BizUnit, Y.DeptSeq, Y.PlanYM 
                                   ) AS Q ON ( Q.BizUnit = Z.BizUnit AND Q.DeptSeq = Z.DeptSeq AND Q.PlanYM = Z.PlanYM AND Q.MaxPlanRev = Z.PlanRev ) 
                             WHERE Z.CompanySeq = @CompanySeq 
                               AND Z.BizUnit = @BizUnit 
                               AND Z.PlanYM = CONVERT(NCHAR(6),DATEADD(MM,2,@PlanYM + '01'),112)
                             GROUP BY Z.ItemSeq
                          ) AS D ON ( D.ItemSeq = A.ItemSeq ) 
        ----------------------------------------------------------------------------------
        -- �ǸŰ�ȹ ����, END 
        ----------------------------------------------------------------------------------

        
        IF @WorkingTag = 'Cfm'
        BEGIN 
            ----------------------------------------------------------------------------------
            -- �����ȹ���� (�ڰ��Һ������) 
            ----------------------------------------------------------------------------------
            UPDATE A 
               SET ProdPlanQty = CASE WHEN SalesPlanQty - BaseQty >= 0 THEN SalesPlanQty - BaseQty ELSE 0 END, 
                   ProdPlanQtyM1 = CASE WHEN SalesPlanQtyM1 >= 0 THEN SalesPlanQtyM1 ELSE 0 END, 
                   ProdPlanQtyM2 = CASE WHEN SalesPlanQtyM2 >= 0 THEN SalesPlanQtyM2 ELSE 0 END 
              FROM #KPXCM_TPDSFCMonthProdPlanStockItem AS A 
        END 
        
        
        --------------------------------------------
        -- �ڰ��Һ� ��� 
        --------------------------------------------
        CREATE TABLE #BOMSpread 
        (
            ItemSeq             INT,
            ItemBOMRev          NCHAR(2),
            UnitSeq             INT,
            BOMLevelText        NVARCHAR(200),
            Location            NVARCHAR(1000),
            Remark              NVARCHAR(500),
            Serl                INT,
            NeedQtyNumerator    DECIMAL(19,5),
            NeedQtyDenominator  DECIMAL(19,5),
            NeedQty             DECIMAL(19,10),
            Seq                 INT IDENTITY(1,1),
            ParentSeq           INT,
            Sort                INT,
            BOMLevel            INT
        )  
        
        
        IF @WorkingTag <> 'Cfm'
        BEGIN 
            -- Update�� ���� TempTable 
            CREATE TABLE #UpdateTable 
            (
                PlanSeq         INT, 
                PlanSerl        INT, 
                ItemSeq         INT, 
                BaseQty         DECIMAL(19,5), 
                ProdPlanQty     DECIMAL(19,5), 
                SalesPlanQty    DECIMAL(19,5), 
                SelfQty         DECIMAL(19,5), 
                LastQty         DECIMAL(19,5), 
                WorkingTag      NCHAR(1), 
                Status          INT, 
                PlanYM          NCHAR(6) 
            )
            
            
            --select * From #KPXCM_TPDSFCMonthProdPlanStockItem 
            
            INSERT INTO #UpdateTable 
            ( 
                PlanSeq, PlanSerl, ItemSeq, BaseQty, ProdPlanQty, 
                SalesPlanQty, SelfQty, LastQty, WorkingTag, Status, 
                PlanYM 
            ) 
            SELECT A.PlanSeq, A.PlanSerl, A.ItemSeq, A.BaseQty, ISNULL(B.ProdPlanQty,A.ProdPlanQty),
                   A.SalesPlanQty, A.SelfQty, A.LastQty, 
                   (SELECT TOP 1 WorkingTag FROM #KPXCM_TPDSFCMonthProdPlanStockItem), 
                   (SELECT TOP 1 Status FROM #KPXCM_TPDSFCMonthProdPlanStockItem), 
                   A.PlanYMSub
            
              FROM KPXCM_TPDSFCMonthProdPlanStockItem               AS A 
              LEFT OUTER JOIN #KPXCM_TPDSFCMonthProdPlanStockItem   AS B ON ( B.PlanSeq = A.PlanSeq AND B.PlanSerl = A.PlanSerl ) 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.PlanSeq = ( SELECT MAX(PlanSeq) FROM #KPXCM_TPDSFCMonthProdPlanStockItem ) 
        END 
        
        
        
        
        
        DECLARE @Cnt                INT, 
                @ItemSeq            INT, 
                @ProdPlanQty        DECIMAL(19,5), 
                @ProdPlanDiffQty    DECIMAL(19,5), 
                @MaxDataSeq         INT, 
                @ProdPlanQtyM1      DECIMAL(19,5), 
                @ProdPlanQtyM2      DECIMAL(19,5)
        
        SELECT @Cnt = 1 
        SELECT @MaxDataSeq = (SELECT MAX(DataSeq) FROM #KPXCM_TPDSFCMonthProdPlanStockItem) 
        
        WHILE ( 1 = 1 ) 
        BEGIN 
            
            SELECT @ItemSeq = A.ItemSeq, 
                   @ProdPlanQty = A.ProdPlanQty, 
                   @ProdPlanDiffQty = A.ProdPlanQty - B.ProdPlanQty, -- ������ �����ȹ�� �߰��Ǵ� ���� 
                   @ProdPlanQtyM1 = CASE WHEN @WorkingTag = 'Cfm' THEN A.ProdPlanQtyM1 ELSE 0 END, 
                   @ProdPlanQtyM2 = CASE WHEN @WorkingTag = 'Cfm' THEN A.ProdPlanQtyM2 ELSE 0 END 
              FROM #KPXCM_TPDSFCMonthProdPlanStockItem  AS A 
              LEFT OUTER JOIN KPXCM_TPDSFCMonthProdPlanStockItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanSeq = A.PlanSeq AND B.PlanSerl = A.PlanSerl AND B.PlanYMSub = A.PlanYM ) 
             WHERE DataSeq = @Cnt 
            
            TRUNCATE TABLE #BOMSpread 

            EXEC dbo._SPDBOMSpreadTree @CompanySeq    = @CompanySeq
                                      ,@ItemSeq       = @ItemSeq
                                      ,@ItemBomRev    = '00'
                                      ,@SemiType      = 0
                                      ,@IsReverse     = 0
                                      ,@BOMNeedQty    = 0
            
            
            IF @WorkingTag = 'Cfm'
            BEGIN 

                
                UPDATE A 
                   SET SelfQty = SelfQty + (ISNULL(B.NeedQty,0) * @ProdPlanQty), 
                       SelfQtyM1 = SelfQtyM1 + (ISNULL(B.NeedQty,0) * @ProdPlanQtyM1), 
                       SelfQtyM2 = SelfQtyM2 + (ISNULL(B.NeedQty,0) * @ProdPlanQtyM2)
                  FROM #KPXCM_TPDSFCMonthProdPlanStockItem AS A 
                  LEFT OUTER JOIN #BOMSpread               AS B ON ( B.ItemSeq = A.ItemSeq AND B.BOMLevel <> 1 ) 
            END 
            ELSE
            BEGIN
                UPDATE A 
                   SET SelfQty = CASE WHEN SelfQty + (ISNULL(B.NeedQty,0) * @ProdPlanDiffQty) >= 0 THEN SelfQty + (ISNULL(B.NeedQty,0) * @ProdPlanDiffQty) ELSE 0 END 
                  FROM #UpdateTable             AS A 
                  LEFT OUTER JOIN #BOMSpread    AS B ON ( B.ItemSeq = A.ItemSeq AND B.BOMLevel <> 1 ) 
            END 
            
            
            
            IF @Cnt >= (SELECT ISNULL(@MaxDataSeq,0))
            BEGIN 
                BREAK 
            END 
            ELSE
            BEGIN
                SELECT @Cnt = @Cnt + 1 
            END 
        
        
        END 
        --------------------------------------------
        -- �ڰ��Һ� ���, END  
        --------------------------------------------
        
        --select ItemName, ItemSeq, BaseQty, ProdPlanQty, SalesPlanQty, SelfQty, LastQty  From #KPXCM_TPDSFCMonthProdPlanStockItem 
        --return 
        
        --select * from #KPXCM_TPDSFCMonthProdPlanStockItem 
        --return 
        
        --------------------------------------------------------------------------------
        -- �����ȹ������ �ڰ��Һ��� ��ġ��, �⸻��� ������Ʈ 
        -------------------------------------------------------------------------------- 
        IF @WorkingTag = 'Cfm'
        BEGIN 

            
            UPDATE A 
               SET ProdPlanQty = CASE WHEN (SalesPlanQty + SelfQty) - BaseQty >= 0 THEN (SalesPlanQty + SelfQty) - BaseQty ELSE 0 END, 
                   ProdPlanQtyM1 = CASE WHEN (SalesPlanQtyM1 + SelfQtyM1) >= 0 THEN (SalesPlanQtyM1 + SelfQtyM1) ELSE 0 END, 
                   ProdPlanQtyM2 = CASE WHEN (SalesPlanQtyM2 + SelfQtyM2) >= 0 THEN (SalesPlanQtyM2 + SelfQtyM2) ELSE 0 END, 
                   LastQty = (BaseQty + (CASE WHEN (SalesPlanQty + SelfQty) - BaseQty >= 0 THEN (SalesPlanQty + SelfQty) - BaseQty ELSE 0 END)) - (SalesPlanQty + SelfQty),
                   LastQtyM1 = (CASE WHEN (SalesPlanQtyM1 + SelfQtyM1) >= 0 THEN (SalesPlanQtyM1 + SelfQtyM1) ELSE 0 END) - (SalesPlanQtyM1 + SelfQtyM1),
                   LastQtyM2 = (CASE WHEN (SalesPlanQtyM2 + SelfQtyM2) >= 0 THEN (SalesPlanQtyM2 + SelfQtyM2) ELSE 0 END) - (SalesPlanQtyM2 + SelfQtyM2)
              FROM #KPXCM_TPDSFCMonthProdPlanStockItem AS A 
        END 
        ELSE
        BEGIN
            UPDATE A              
               SET ProdPlanQty = CASE WHEN ISNULL(C.ItemSeq,0) = 0 
                                      THEN (CASE WHEN ISNULL(B.ItemSeq,0) = 0 THEN A.ProdPlanQty ELSE (CASE WHEN (A.SalesPlanQty + A.SelfQty) - A.BaseQty >= 0 THEN (A.SalesPlanQty + A.SelfQty) - A.BaseQty ELSE 0 END) END)
                                      ELSE A.ProdPlanQty
                                      END, 
                   LastQty = (A.BaseQty + (CASE WHEN ISNULL(C.ItemSeq,0) = 0 
                                                THEN (CASE WHEN ISNULL(B.ItemSeq,0) = 0 THEN A.ProdPlanQty ELSE (CASE WHEN (A.SalesPlanQty + A.SelfQty) - A.BaseQty >= 0 THEN (A.SalesPlanQty + A.SelfQty) - A.BaseQty ELSE 0 END) END)
                                                ELSE A.ProdPlanQty
                                                END)) 
                             - (A.SalesPlanQty + A.SelfQty)
              FROM #UpdateTable AS A 
              LEFT OUTER JOIN #BOMSpread AS B ON ( B.ItemSeq = A.ItemSeq ) 
              LEFT OUTER JOIN #KPXCM_TPDSFCMonthProdPlanStockItem AS C ON ( C.ItemSeq = A.ItemSeq ) 
        END 
        --------------------------------------------------------------------------------
        -- �����ȹ������ �ڰ��Һ��� ��ġ��, �⸻��� ������Ʈ, END 
        --------------------------------------------------------------------------------      
    END 
    
    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TPDSFCMonthProdPlanStockItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TPDSFCMonthProdPlanStockItem'    , -- ���̺��        
                  '#KPXCM_TPDSFCMonthProdPlanStockItem'    , -- �ӽ� ���̺��        
                  'PlanSeq,PlanSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDSFCMonthProdPlanStockItem WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        
        
        IF @WorkingTag = 'SS' -- ����������� 
        BEGIN 
            UPDATE B   
               SET B.BaseQty    = A.BaseQty, 
                   B.LastDateTime   = GETDATE(),  
                   B.PgmSeq         = @PgmSeq
              FROM #KPXCM_TPDSFCMonthProdPlanStockItem  AS A   
              JOIN KPXCM_TPDSFCMonthProdPlanStockItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanSeq = A.PlanSeq AND B.PlanSerl = A.PlanSerl AND B.PlanYMSub = A.PlanYM )   
             WHERE A.WorkingTag = 'U'   
               AND A.Status = 0      
            
            IF @@ERROR <> 0  RETURN  
            
        END 
        ELSE 
        BEGIN 
            UPDATE A   
               SET A.ProdPlanQty    = B.ProdPlanQty,  
                   A.SalesPlanQty   = B.SalesPlanQty,  
                   A.SelfQty        = B.SelfQty,  
                   A.LastQty        = B.LastQty,  
                   A.LastUserSeq    = @UserSeq, 
                   A.LastDateTime   = GETDATE(),  
                   A.PgmSeq         = @PgmSeq
              FROM KPXCM_TPDSFCMonthProdPlanStockItem   AS A  
              JOIN #UpdateTable                         AS B ON ( B.PlanSeq = A.PlanSeq AND B.PlanSerl = A.PlanSerl )   
             WHERE A.CompanySeq = @CompanySeq 
               AND B.WorkingTag = 'U'   
               AND B.Status = 0      
               AND A.PlanYMSub = B.PlanYM   
            
            IF @@ERROR <> 0  RETURN  
        END 
          
    END    
    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDSFCMonthProdPlanStockItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        
        IF @WorkingTag = 'Cfm' 
        BEGIN 
            DELETE B
              FROM #KPXCM_TPDSFCMonthProdPlanStockItem AS A 
              JOIN KPXCM_TPDSFCMonthProdPlanStockItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanSeq = A.PlanSeq )
             WHERE A.WorkingTag = 'A' 
               AND A.Status = 0 
        END 
        
        
        INSERT INTO KPXCM_TPDSFCMonthProdPlanStockItem  
        (   
            CompanySeq, PlanSeq, PlanSerl, ItemSeq, BaseQty, 
            ProdPlanQty, SalesPlanQty, SelfQty, LastQty, LastUserSeq, 
            LastDateTime, PgmSeq, PlanYMSub
        )   
        SELECT @CompanySeq, A.PlanSeq, A.PlanSerl, A.ItemSeq, A.BaseQty, 
               A.ProdPlanQty, A.SalesPlanQty, A.SelfQty, A.LastQty, @UserSeq, 
               GETDATE(), @PgmSeq, A.PlanYM
          FROM #KPXCM_TPDSFCMonthProdPlanStockItem AS A   
         WHERE A.WorkingTag = 'A'   
             AND A.Status = 0 
        
        UNION ALL 
        
        SELECT @CompanySeq, A.PlanSeq, A.PlanSerl, A.ItemSeq, 0, 
               ISNULL(A.ProdPlanQtyM1,0), ISNULL(A.SalesPlanQtyM1,0), ISNULL(A.SelfQtyM1,0), ISNULL(A.LastQtyM1,0), @UserSeq, 
               GETDATE(), @PgmSeq, CONVERT(NCHAR(6),DATEADD(MM,1,A.PlanYM + '01'),112)
          FROM #KPXCM_TPDSFCMonthProdPlanStockItem AS A   
         WHERE A.WorkingTag = 'A'   
             AND A.Status = 0 
        
        UNION ALL 
        
        SELECT @CompanySeq, A.PlanSeq, A.PlanSerl, A.ItemSeq, 0, 
               ISNULL(A.ProdPlanQtyM2,0), ISNULL(A.SalesPlanQtyM2,0), ISNULL(A.SelfQtyM2,0), ISNULL(A.LastQtyM2,0), @UserSeq, 
               GETDATE(), @PgmSeq,CONVERT(NCHAR(6),DATEADD(MM,2,A.PlanYM + '01'),112)
          FROM #KPXCM_TPDSFCMonthProdPlanStockItem AS A   
         WHERE A.WorkingTag = 'A'   
             AND A.Status = 0 
        
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPXCM_TPDSFCMonthProdPlanStockItem   
    
      
    RETURN  
GO
begin tran 
exec KPXCM_SPDSFCMonthProdPlanStockItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-645.00000</BaseQty>
    <ItemName>(){}[]!@#$%^&amp;*�ڼҿ�!@#$%^&amp;*(){}[]</ItemName>
    <ItemNo>(){}[]!@#$%^&amp;*�ڼҿ�!@#$%^&amp;*(){}[]</ItemNo>
    <ItemSeq>1052054</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>1</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>470.00000</BaseQty>
    <ItemName>@��������123</ItemName>
    <ItemNo>@��������</ItemNo>
    <ItemSeq>14497</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>2</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-1.00000</BaseQty>
    <ItemName>@��������11</ItemName>
    <ItemNo>@��������11</ItemNo>
    <ItemSeq>14503</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>3</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-100.00000</BaseQty>
    <ItemName>@asdfasdf</ItemName>
    <ItemNo>0106591</ItemNo>
    <ItemSeq>14526</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>4</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>900.00000</BaseQty>
    <ItemName>@asdfasdfasdf</ItemName>
    <ItemNo>@asdfasdfasdf</ItemNo>
    <ItemSeq>14527</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>5</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-1.00000</BaseQty>
    <ItemName>@we</ItemName>
    <ItemNo>@we</ItemNo>
    <ItemSeq>14508</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>6</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-4.00000</BaseQty>
    <ItemName>0.6/1KV �����������̺�</ItemName>
    <ItemNo>CRDC-06-011--00050</ItemNo>
    <ItemSeq>1000534</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>7</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>3300.00000</BaseQty>
    <ItemName>0.6/1KV �����������̺�</ItemName>
    <ItemNo>CRDC-06-005--00007</ItemNo>
    <ItemSeq>1000513</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>8</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>0.00000</BaseQty>
    <ItemName>0.6/1KV ������ƿ�� �������̺�</ItemName>
    <ItemNo>CRDC-06-011--00052</ItemNo>
    <ItemSeq>1000536</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>9</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>0.00000</BaseQty>
    <ItemName>0.6/1KV ������ƿ�� �������̺�</ItemName>
    <ItemNo>CRDC-06-011--00051</ItemNo>
    <ItemSeq>1000535</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>10</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>100.00000</BaseQty>
    <ItemName>0.6/1KV ������ƿ�� �������̺�</ItemName>
    <ItemNo>CRDC-06-005--00008</ItemNo>
    <ItemSeq>1000514</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>11</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>0.00000</BaseQty>
    <ItemName>0.6/1KV PVC���� ����������</ItemName>
    <ItemNo>CRDC-06-011--00054</ItemNo>
    <ItemSeq>1000538</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>12</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>13</IDX_NO>
    <DataSeq>13</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>0.00000</BaseQty>
    <ItemName>0.6/1KV PVC���� ����������</ItemName>
    <ItemNo>CRDC-06-005--00009</ItemNo>
    <ItemSeq>1000515</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>13</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>14</IDX_NO>
    <DataSeq>14</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-5.00000</BaseQty>
    <ItemName>0.6/1KV PVC���� ����������</ItemName>
    <ItemNo>CRDC-06-011--00010</ItemNo>
    <ItemSeq>1000376</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>14</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>15</IDX_NO>
    <DataSeq>15</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>200.00000</BaseQty>
    <ItemName>0407_��Ȯ��ǰ</ItemName>
    <ItemNo>0407_��Ȯ��ǰ_ǰ��</ItemNo>
    <ItemSeq>1052002</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>15</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>16</IDX_NO>
    <DataSeq>16</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-1000.00000</BaseQty>
    <ItemName>17�� ��ǰ</ItemName>
    <ItemNo>17�� ��ǰ��ȣ</ItemNo>
    <ItemSeq>23792</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>16</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>17</IDX_NO>
    <DataSeq>17</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-96.00000</BaseQty>
    <ItemName>2014-��Ʈ��</ItemName>
    <ItemNo>2014-��Ʈ��</ItemNo>
    <ItemSeq>1001167</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>17</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>18</IDX_NO>
    <DataSeq>18</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>10000.00000</BaseQty>
    <ItemName>2014-��ũ</ItemName>
    <ItemNo>2014-��ũ</ItemNo>
    <ItemSeq>1001194</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>18</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>19</IDX_NO>
    <DataSeq>19</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-100.00000</BaseQty>
    <ItemName>27�� ��ǰ</ItemName>
    <ItemNo>27�� ��ǰ��ȣ</ItemNo>
    <ItemSeq>23795</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>19</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>20</IDX_NO>
    <DataSeq>20</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>1.00000</BaseQty>
    <ItemName>�����_��������ǰ</ItemName>
    <ItemNo>�����_��������ǰ</ItemNo>
    <ItemSeq>27524</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>20</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>21</IDX_NO>
    <DataSeq>21</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>290.00000</BaseQty>
    <ItemName>�ǿ�ö_�±�_LOTǰ��_11111111</ItemName>
    <ItemNo>OCKWON1</ItemNo>
    <ItemSeq>1001366</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>21</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>22</IDX_NO>
    <DataSeq>22</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>200.00000</BaseQty>
    <ItemName>�ǿ�ö_�±�_LOTǰ��_2</ItemName>
    <ItemNo>OCKWON2</ItemNo>
    <ItemSeq>1001367</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>22</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>23</IDX_NO>
    <DataSeq>23</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-20.00000</BaseQty>
    <ItemName>�����_������ǰ</ItemName>
    <ItemNo>�����_������ǰ</ItemNo>
    <ItemSeq>24854</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>23</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>24</IDX_NO>
    <DataSeq>24</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>10.00000</BaseQty>
    <ItemName>��μ�_ǰ��1</ItemName>
    <ItemNo>��μ�_ǰ��1</ItemNo>
    <ItemSeq>1052017</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>24</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>25</IDX_NO>
    <DataSeq>25</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>100.00000</BaseQty>
    <ItemName>���ȣ����ǰ001</ItemName>
    <ItemNo>���ȣ����ǰ001</ItemNo>
    <ItemSeq>1052374</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>25</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>26</IDX_NO>
    <DataSeq>26</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>100.00000</BaseQty>
    <ItemName>���ȣ��ǰ001</ItemName>
    <ItemNo>���ȣ��ǰ001</ItemNo>
    <ItemSeq>1052372</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>26</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>27</IDX_NO>
    <DataSeq>27</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-2.00000</BaseQty>
    <ItemName>�輼ȣ_test</ItemName>
    <ItemNo>3344</ItemNo>
    <ItemSeq>22568</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>27</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>28</IDX_NO>
    <DataSeq>28</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>10000.00000</BaseQty>
    <ItemName>���â-����ǰ</ItemName>
    <ItemNo>���â-����ǰ</ItemNo>
    <ItemSeq>1000919</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>28</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>29</IDX_NO>
    <DataSeq>29</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-100.00000</BaseQty>
    <ItemName>�������ڷ�</ItemName>
    <ItemNo>DYC001</ItemNo>
    <ItemSeq>1051288</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>29</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>30</IDX_NO>
    <DataSeq>30</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>120.00000</BaseQty>
    <ItemName>�ڼ�����ǰ_TPC</ItemName>
    <ItemNo>�ڼ�����ǰ_TPC</ItemNo>
    <ItemSeq>1051791</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>30</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>31</IDX_NO>
    <DataSeq>31</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>10.00000</BaseQty>
    <ItemName>����ǰ_�赿��</ItemName>
    <ItemNo>����ǰ_�赿��</ItemNo>
    <ItemSeq>1000385</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>31</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>32</IDX_NO>
    <DataSeq>32</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-6.00000</BaseQty>
    <ItemName>����ǰ_������</ItemName>
    <ItemNo>P123456789-SDFFESD2-jele</ItemNo>
    <ItemSeq>27441</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>32</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>33</IDX_NO>
    <DataSeq>33</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-10.00000</BaseQty>
    <ItemName>����ǰ_jhlee</ItemName>
    <ItemNo>����ǰ_jhlee</ItemNo>
    <ItemSeq>1052383</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>33</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>34</IDX_NO>
    <DataSeq>34</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>1000.00000</BaseQty>
    <ItemName>����-Lotǰ��</ItemName>
    <ItemNo>����-Lotǰ��</ItemNo>
    <ItemSeq>26509</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>34</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>35</IDX_NO>
    <DataSeq>35</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>2.00000</BaseQty>
    <ItemName>��ȣ-�����</ItemName>
    <ItemNo>��ȣ-�����</ItemNo>
    <ItemSeq>23917</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>35</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>36</IDX_NO>
    <DataSeq>36</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>240440.00000</BaseQty>
    <ItemName>��ȣ-��ü�޸�</ItemName>
    <ItemNo>��ȣ-��ü�޸�</ItemNo>
    <ItemSeq>23854</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>36</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>37</IDX_NO>
    <DataSeq>37</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-93.00000</BaseQty>
    <ItemName>�������</ItemName>
    <ItemNo>������_��ǰ_1</ItemNo>
    <ItemSeq>1051583</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>37</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>38</IDX_NO>
    <DataSeq>38</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>195.00000</BaseQty>
    <ItemName>��������_�ڼҿ�</ItemName>
    <ItemNo>��������_�ڼҿ�</ItemNo>
    <ItemSeq>23520</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>38</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>39</IDX_NO>
    <DataSeq>39</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>100.00000</BaseQty>
    <ItemName>����_����ǰ2</ItemName>
    <ItemNo>����_����ǰ2</ItemNo>
    <ItemSeq>1000806</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>39</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>40</IDX_NO>
    <DataSeq>40</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>10.00000</BaseQty>
    <ItemName>�̹�Ȯ_�����׽�Ʈ_��ǰ</ItemName>
    <ItemNo>�̹�Ȯ_�����׽�Ʈ_��ǰ_ǰ��</ItemNo>
    <ItemSeq>1051994</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>40</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>41</IDX_NO>
    <DataSeq>41</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>100.00000</BaseQty>
    <ItemName>�̹�Ȯ_�����׽�Ʈ_��ǰ</ItemName>
    <ItemNo>�̹�Ȯ_�����׽�Ʈ_��ǰ_ǰ��</ItemNo>
    <ItemSeq>1051990</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>41</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>42</IDX_NO>
    <DataSeq>42</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-15.00000</BaseQty>
    <ItemName>�̹�Ȯ_�׽�Ʈ_����ǰ1</ItemName>
    <ItemNo>�̹�Ȯ_�׽�Ʈ_����ǰ1_ǰ��</ItemNo>
    <ItemSeq>1051985</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>42</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>43</IDX_NO>
    <DataSeq>43</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-15.00000</BaseQty>
    <ItemName>�̹�Ȯ_�׽�Ʈ_����ǰ2</ItemName>
    <ItemNo>�̹�Ȯ_�׽�Ʈ_����ǰ2_ǰ��</ItemNo>
    <ItemSeq>1051986</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>43</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>44</IDX_NO>
    <DataSeq>44</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>15.00000</BaseQty>
    <ItemName>�̹�Ȯ_�׽�Ʈ_��ǰ1</ItemName>
    <ItemNo>�̹�Ȯ_�׽�Ʈ_��ǰ1_ǰ��</ItemNo>
    <ItemSeq>1051980</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>44</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>45</IDX_NO>
    <DataSeq>45</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-11.00000</BaseQty>
    <ItemName>�̻���-��ǰ1</ItemName>
    <ItemNo>�̻���-��ǰ1</ItemNo>
    <ItemSeq>15980</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>45</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>46</IDX_NO>
    <DataSeq>46</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-11.00000</BaseQty>
    <ItemName>�̿��-����ǰ</ItemName>
    <ItemNo>yg-002</ItemNo>
    <ItemSeq>1051563</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>46</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>47</IDX_NO>
    <DataSeq>47</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-29.00000</BaseQty>
    <ItemName>�̿��-��ǰ</ItemName>
    <ItemNo>yg-001</ItemNo>
    <ItemSeq>1051562</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>47</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>48</IDX_NO>
    <DataSeq>48</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-10.00000</BaseQty>
    <ItemName>���ؽ�_ǰ���׽�Ʈ</ItemName>
    <ItemNo>���ؽ�_ǰ���׽�Ʈ</ItemNo>
    <ItemSeq>1052341</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>48</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>49</IDX_NO>
    <DataSeq>49</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-210.00000</BaseQty>
    <ItemName>������_����ǰ</ItemName>
    <ItemNo>������_����ǰ0001</ItemNo>
    <ItemSeq>25281</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>49</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>50</IDX_NO>
    <DataSeq>50</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>4.00000</BaseQty>
    <ItemName>��漱_����ǰg����</ItemName>
    <ItemNo>��漱_����ǰg����_ǰ��</ItemNo>
    <ItemSeq>1052191</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>50</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>51</IDX_NO>
    <DataSeq>51</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>10000766.00000</BaseQty>
    <ItemName>������-����-���������պ�</ItemName>
    <ItemNo>19920229201</ItemNo>
    <ItemSeq>1001334</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>51</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>52</IDX_NO>
    <DataSeq>52</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>100993863.00000</BaseQty>
    <ItemName>������-�ۿ�-����⺻1</ItemName>
    <ItemNo>19920229201</ItemNo>
    <ItemSeq>1052127</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>52</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>53</IDX_NO>
    <DataSeq>53</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>997838.00000</BaseQty>
    <ItemName>������-�ۿ�-����⺻2</ItemName>
    <ItemNo>19920229201</ItemNo>
    <ItemSeq>1052129</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>53</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>54</IDX_NO>
    <DataSeq>54</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>999996.00000</BaseQty>
    <ItemName>������-�ۿ�-����⺻����</ItemName>
    <ItemNo>19920229201</ItemNo>
    <ItemSeq>1052128</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>54</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>55</IDX_NO>
    <DataSeq>55</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>996984.00000</BaseQty>
    <ItemName>������-�ۿ�-����⺻����1</ItemName>
    <ItemNo>19920229201</ItemNo>
    <ItemSeq>1052132</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>55</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>56</IDX_NO>
    <DataSeq>56</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>999991.00000</BaseQty>
    <ItemName>������-�ۿ�-����ȸ ����ǰ1</ItemName>
    <ItemNo>������-�ۿ�-����ȸ ����ǰ1</ItemNo>
    <ItemSeq>1052015</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>56</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>57</IDX_NO>
    <DataSeq>57</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>999895.00000</BaseQty>
    <ItemName>������-�ۿ�-����ȸ ����ǰ2</ItemName>
    <ItemNo>������-�ۿ�-����ȸ ����ǰ2</ItemNo>
    <ItemSeq>1052014</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>57</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>58</IDX_NO>
    <DataSeq>58</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>1995873.00000</BaseQty>
    <ItemName>������-�ۿ�-����ȸ ��ǰ1</ItemName>
    <ItemNo>������-�ۿ�-����ȸ ��ǰ1</ItemNo>
    <ItemSeq>1052012</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>58</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>59</IDX_NO>
    <DataSeq>59</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>994860.00000</BaseQty>
    <ItemName>������-�ۿ�-����ȸ ��ǰ2</ItemName>
    <ItemNo>������-�ۿ�-����ȸ ��ǰ2</ItemNo>
    <ItemSeq>1052013</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>59</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>60</IDX_NO>
    <DataSeq>60</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-17.00000</BaseQty>
    <ItemName>������-�ۿ�-Bag�����1</ItemName>
    <ItemNo>������-�ۿ�-Bag�����1</ItemNo>
    <ItemSeq>1052008</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>60</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>61</IDX_NO>
    <DataSeq>61</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-18.00000</BaseQty>
    <ItemName>������-�ۿ�-Bag�����2</ItemName>
    <ItemNo>������-�ۿ�-Bag�����2</ItemNo>
    <ItemSeq>1052009</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>61</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>62</IDX_NO>
    <DataSeq>62</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>10.00000</BaseQty>
    <ItemName>������_LOT����</ItemName>
    <ItemNo>������_LOT����</ItemNo>
    <ItemSeq>1052068</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>62</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>63</IDX_NO>
    <DataSeq>63</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-777.00000</BaseQty>
    <ItemName>������_������ǰ</ItemName>
    <ItemNo>������_������ǰ</ItemNo>
    <ItemSeq>27533</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>63</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>64</IDX_NO>
    <DataSeq>64</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-5.00000</BaseQty>
    <ItemName>��ǰ_�赿��</ItemName>
    <ItemNo>��ǰ_�赿��</ItemNo>
    <ItemSeq>1000384</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>64</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>65</IDX_NO>
    <DataSeq>65</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-55095.00000</BaseQty>
    <ItemName>��ǰ_������</ItemName>
    <ItemNo>��ǰ_������1234</ItemNo>
    <ItemSeq>27440</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>65</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>66</IDX_NO>
    <DataSeq>66</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>9.00000</BaseQty>
    <ItemName>��ǰ_jhlee</ItemName>
    <ItemNo>��ǰ_jhlee</ItemNo>
    <ItemSeq>1052380</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>66</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>67</IDX_NO>
    <DataSeq>67</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-11.00000</BaseQty>
    <ItemName>��ǰ02_jhlee</ItemName>
    <ItemNo>��ǰ02_jhlee</ItemNo>
    <ItemSeq>1052396</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>67</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>68</IDX_NO>
    <DataSeq>68</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>11.00000</BaseQty>
    <ItemName>��ǰidf_������</ItemName>
    <ItemNo>��ǰidf_������</ItemNo>
    <ItemSeq>1002274</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>68</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>69</IDX_NO>
    <DataSeq>69</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>200.00000</BaseQty>
    <ItemName>��ǰMARO0001</ItemName>
    <ItemNo>GOODMARO00001</ItemNo>
    <ItemSeq>1052445</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>69</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>70</IDX_NO>
    <DataSeq>70</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-600.00000</BaseQty>
    <ItemName>õ���_����ǰ</ItemName>
    <ItemNo>õ���_����ǰ</ItemNo>
    <ItemSeq>1051526</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>70</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>71</IDX_NO>
    <DataSeq>71</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>200.00000</BaseQty>
    <ItemName>�Ļ��� ����������ƿ�� ������</ItemName>
    <ItemNo>CRDC-06-011--00072</ItemNo>
    <ItemSeq>1000556</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>71</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>72</IDX_NO>
    <DataSeq>72</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>400.00000</BaseQty>
    <ItemName>DY��ǰ</ItemName>
    <ItemNo>DYGE0001</ItemNo>
    <ItemSeq>26216</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>72</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>73</IDX_NO>
    <DataSeq>73</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>300.00000</BaseQty>
    <ItemName>G_JJANG_01</ItemName>
    <ItemNo>G_JJANG_01</ItemNo>
    <ItemSeq>1000446</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>73</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>74</IDX_NO>
    <DataSeq>74</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-10000.00000</BaseQty>
    <ItemName>Genuine-��ǰ-000003</ItemName>
    <ItemNo>2000003</ItemNo>
    <ItemSeq>3</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>74</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>75</IDX_NO>
    <DataSeq>75</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-15.00000</BaseQty>
    <ItemName>hycheon_����ǰ</ItemName>
    <ItemNo>hycheon_����ǰ</ItemNo>
    <ItemSeq>27603</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>75</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>76</IDX_NO>
    <DataSeq>76</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-60.00000</BaseQty>
    <ItemName>iPhone5</ItemName>
    <ItemNo>i5</ItemNo>
    <ItemSeq>15837</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>76</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>77</IDX_NO>
    <DataSeq>77</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-300.00000</BaseQty>
    <ItemName>Jykim2_��ǰ(B)</ItemName>
    <ItemNo>0625JY002</ItemNo>
    <ItemSeq>25290</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>77</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>78</IDX_NO>
    <DataSeq>78</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-1.00000</BaseQty>
    <ItemName>mn_�׽�Ʈ����ǰ</ItemName>
    <ItemNo>mn_�׽�Ʈ����ǰ</ItemNo>
    <ItemSeq>1000574</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>78</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>79</IDX_NO>
    <DataSeq>79</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>720.00000</BaseQty>
    <ItemName>PISTON</ItemName>
    <ItemNo>1234567890</ItemNo>
    <ItemSeq>1002329</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>79</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>80</IDX_NO>
    <DataSeq>80</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>1446.00000</BaseQty>
    <ItemName>SJǰ��</ItemName>
    <ItemNo>SJǰ��</ItemNo>
    <ItemSeq>1051713</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>80</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>81</IDX_NO>
    <DataSeq>81</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-4.00000</BaseQty>
    <ItemName>test_����ǰ2(����õ)</ItemName>
    <ItemNo>test_����ǰ2No(����õ)</ItemNo>
    <ItemSeq>1000591</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>81</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>82</IDX_NO>
    <DataSeq>82</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-5.00000</BaseQty>
    <ItemName>test_����ǰ3(����õ)</ItemName>
    <ItemNo>test_����ǰ3No(����õ)</ItemNo>
    <ItemSeq>1000617</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>82</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>83</IDX_NO>
    <DataSeq>83</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-1.00000</BaseQty>
    <ItemName>test_����ǰ5(����õ)</ItemName>
    <ItemNo>test_����ǰ5No(����õ)</ItemNo>
    <ItemSeq>1000619</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>83</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>84</IDX_NO>
    <DataSeq>84</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-2.00000</BaseQty>
    <ItemName>test_����õ(����ǰ)</ItemName>
    <ItemNo>P563009220-5K2C0TE1-0002</ItemNo>
    <ItemSeq>1000570</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>84</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>85</IDX_NO>
    <DataSeq>85</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>-3.00000</BaseQty>
    <ItemName>test1_����õ(����ǰ)</ItemName>
    <ItemNo>test1_����õ(����ǰ)NO</ItemNo>
    <ItemSeq>1000626</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>85</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>86</IDX_NO>
    <DataSeq>86</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>30.00000</BaseQty>
    <ItemName>yh-��ǰA</ItemName>
    <ItemNo>yh-��ǰA</ItemNo>
    <ItemSeq>1052058</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>86</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>87</IDX_NO>
    <DataSeq>87</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseQty>131.00000</BaseQty>
    <ItemName>yjno2015081_��ǰ</ItemName>
    <ItemNo>yjno2015081_��ǰ</ItemNo>
    <ItemSeq>1052221</ItemSeq>
    <LastQty>0.00000</LastQty>
    <PlanSerl>87</PlanSerl>
    <PlanSeq>25</PlanSeq>
    <ProdPlanQty>0.00000</ProdPlanQty>
    <SalesPlanQty>0.00000</SalesPlanQty>
    <SelfQty>0.00000</SelfQty>
    <FactUnit>0</FactUnit>
    <PlanYM>201403</PlanYM>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032672,@WorkingTag=N'SS',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027069
rollback 