
IF OBJECT_ID('KPX_SPDSFCWorkOrderQuery') IS NOT NULL
    DROP PROC KPX_SPDSFCWorkOrderQuery
GO 

-- v2015.04.09 

-- �۾�������ȸ_KPX by����õ
/************************************************************  
  ��  �� - �۾�������ȸ    
  �ۼ��� - 2008�� 10�� 16��     
  �ۼ��� - ������    
  ������ - 2009.12.28 BY �ڼҿ�    
           2009.12.29 BY �ڼҿ� ��ũ���͸� ��ȸ���� ����    
           2010.01.04 BY �ڼҿ� ���������    
           2010.01.05 BY �ڼҿ� �����ȹ��ȣ ��ȸ���� ����    
           2010.01.21 BY �ڼҿ� ����ǰ�� ����ǰ�� ã�� ����ǰ�� ������ ��������    
           2010.07.21 BY �ڼҿ� ��ǰ/�ҷ�����    
           2010.11.24 BY ������ �ŷ�ó ǰ�� / ǰ�� / �԰� �߰�    
           2010.12.09 BY �۱⿬ �־߱��� �߰� (�����ȹ �۾����ú��� ȭ�鿡�� �Էµ� �־� ���� ��ȸ)    
           2010.12.26 BY ����   �����˻�ҷ����۾�,�԰��ĺҷ����۾����� LotNo �����ؼ� ��������    
           2011. 3. 9 BY ����   �ŷ�ó�� ���ֿ��� �귯���� ���� ���� �����Ƿڿ��� ���������� ����    
           2011.04.25 BY �輭�� ������ �߰�    
           2011.11.22 BY �輼ȣ :: ���ü��� 0 �ΰ� ��ȸ �ȵǵ��� ����( �ĳ������� ��ġ���� ���� 0�ΰ� ���ܼ� �ӽ÷� ���� �߰�)    
           2012.1.5 hkim :: ���������� �÷� �߰�    
           2012.01.10 BY �輼ȣ :: �ŷ�ó�� �ŷ�ó��OEMǰ���Ͽ� ��Ͼȵ������� �����Ƿ�ǰ���� �ŷ�ó�� ��ȸ�ǵ��� ���� 
           2012.05.24 BY �輼ȣ :: ���۾��ǵ� ��õ�۾����ð��� �ŷ�ó ��ȸ�ǵ��� ���� �� �ŷ�ó �������� �켱���� ���� 
                                  (1. �ŷ�ó�� OEMǰ�� -> 2. �����Ƿ�  -> 3. ����)
           2013.01.08 BY ���â :: BOM������ �߰� _TPDBOMManagement ���� ItemBOMRevRemark ��� ���Ͻ� ���� BOM������ �������� ����
           2013.05.22 BY ��ǿ� :: �۾�������ȸ ȭ�鿡�� ��ȹ��ȣ�� ��ȸ �� �ش� ǰ���� �����͸� ǥ�� �ǵ��� ����
           2014.04.04 BY ����� :: ���۾����ð��� ������, ��õ�۾����ðǵ� ��´� �κп��� ���� ���� #TPDSFCWorkOrder �� ���� ��,
                                   �÷� 2���� �߰� �Ǿ INSERT �÷����� �ȸ¾Ƽ� �������� �κ� ����
  ************************************************************/    
 CREATE PROC KPX_SPDSFCWorkOrderQuery   
      @xmlDocument    NVARCHAR(MAX) ,                
      @xmlFlags       INT = 0,                
      @ServiceSeq     INT = 0,                
      @WorkingTag     NVARCHAR(10)= '',                      
      @CompanySeq     INT = 1,                
      @LanguageSeq    INT = 1,                
      @UserSeq        INT = 0,                
      @PgmSeq         INT = 0      
  AS             
      CREATE TABLE #TMP_PROGRESSTABLE          
      (          
          IDOrder             INT,          
          TABLENAME           NVARCHAR(100)          
      )         
      
      CREATE TABLE #TCOMProgressTracking          
      (    
          IDX_NO              INT,          
          IDOrder             INT,          
          Seq                 INT,          
          Serl                INT,          
          SubSerl             INT,          
          Qty                 DECIMAL(19, 5),          
          STDQty              DECIMAL(19, 5),          
          Amt                 DECIMAL(19, 5)   ,          
          VAT                 DECIMAL(19, 5)          
      )          
      
      DECLARE @docHandle          INT,    
              @WorkOrderSeq       INT,    
              @WorkOrderSerl      INT,    
              @FactUnit           INT,    
              @DeptSeq            INT,    
              @ChainGoodsSeq      INT,            -- ����ǰ��ȸ�̸� 1, �ƴϸ� 0    
              @ProgStatus         INT,    
              @WorkType           INT,    
              --@DeptName           NVARCHAR(100),    
              @WorkOrderNo     NVARCHAR(20),    
              @ProdPlanNo         NVARCHAR(20),    
              @GoodItemName       NVARCHAR(200),    
              @GoodItemNo         NVARCHAR(100),    
              @GoodItemSpec       NVARCHAR(100),    
              @WorkCenterSeq      INT,    
              @WorkCenterName     NVARCHAR(200),    
              @ProcName           NVARCHAR(100),    
              @WorkOrderDate      NCHAR(8),    
              @WorkOrderDateTo    NCHAR(8),    
              @WorkDate         NCHAR(8),    
              @WorkDateTo         NCHAR(8),    
              -- ������Ʈ ���� �Ǵ� ����    
              @Cnt                INT            ,    
              @Seq                INT            ,    
              @WHSeq              INT            ,    
              @PJTName            NVARCHAR(60)   ,    
              @PJTNo              NVARCHAR(40)  ,    
              @CustSeq            INT            , -- 20091228 �ڼҿ� �߰�    
              @PoNo               NVARCHAR(40)   ,  -- 20091228 �ڼҿ� �߰�    
              @PlanEndDateFr      NCHAR(8), 
              @PlanEndDateTo      NCHAR(8)

                       
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                 
      
      SELECT  @WorkOrderSeq       = ISNULL(WorkOrderSeq       ,0),    
              @WorkOrderSerl      = ISNULL(WorkOrderSerl      ,0),    
              @FactUnit           = ISNULL(FactUnit           ,0),    
              @DeptSeq            = ISNULL(DeptSeq            ,0),    
              @ChainGoodsSeq      = ISNULL(ChainGoodsSeq      ,0),    
            @ProgStatus         = ISNULL(ProgStatus         ,0),    
              @WHSeq              = ISNULL(WHSeq              ,0),    
              @WorkType           = ISNULL(WorkType           ,0),    
       --@DeptName           = ISNULL(DeptName           , ''),    
              @WorkOrderNo     = ISNULL(WorkOrderNo        , ''),    
              @ProdPlanNo         = ISNULL(ProdPlanNo         , ''),    
              @GoodItemName       = ISNULL(GoodItemName       , ''),    
              @GoodItemNo         = ISNULL(GoodItemNo         , ''),    
              @GoodItemSpec       = ISNULL(GoodItemSpec       , ''),    
              @WorkCenterSeq      = ISNULL(WorkCenterSeq      ,0),    
              @WorkCenterName     = ISNULL(WorkCenterName     , ''),    
              @ProcName           = ISNULL(ProcName           , ''),    
              @WorkOrderDate     = ISNULL(WorkOrderDate      , ''),    
              @WorkOrderDateTo    = ISNULL(WorkOrderDateTo    , ''),    
              @WorkDate         = ISNULL(WorkDate           , ''),    
              @WorkDateTo         = ISNULL(WorkDateTo         , ''),                
              @PJTName         = ISNULL(PJTName            , ''),        -- ������Ʈ ���� �߰�    09.1.3 ����    
              @PJTNo             = ISNULL(PJTNo              , ''),        -- ������Ʈ ���� �߰�    09.1.3 ����    
              @CustSeq            = ISNULL(CustSeq           ,0),          -- 20091228 �ڼҿ� �߰�    
              @PoNo               = ISNULL(PoNo               , ''),          -- 20091228 �ڼҿ� �߰�    
              @PlanEndDateFr      = ISNULL(PlanEndDateFr, ''), 
              @PlanEndDateTo      = ISNULL(PlanEndDateTo, '') 
              
        FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
        WITH (
              WorkOrderSeq        INT,    
              WorkOrderSerl       INT,    
              FactUnit            INT,    
              DeptSeq             INT,    
              ChainGoodsSeq       INT,    
              ProgStatus          INT,    
              WHSeq               INT,    
              WorkType            INT,    
              --DeptName            NVARCHAR(100),    
              WorkOrderNo         NVARCHAR(20),    
              ProdPlanNo         NVARCHAR(20),    
              GoodItemName        NVARCHAR(200),    
              GoodItemNo          NVARCHAR(100),    
              GoodItemSpec        NVARCHAR(100),    
              WorkCenterSeq       INT,    
              WorkCenterName      NVARCHAR(200),    
              ProcName            NVARCHAR(100),    
              WorkOrderDate       NCHAR(8),    
              WorkOrderDateTo     NCHAR(8),    
              WorkDate         NCHAR(8),    
              WorkDateTo         NCHAR(8),    
              PJTName             NVARCHAR(60),                -- ������Ʈ ���� �߰�    09.1.3 ����    
              PJTNo               NVARCHAR(40),                -- ������Ʈ ���� �߰�    09.1.3 ����    
              CustSeq             INT,                         -- 20091228 �ڼҿ� �߰�    
              PoNo                NVARCHAR(40), 
              PlanEndDateFr      NCHAR(8),
              PlanEndDateTo      NCHAR(8)
             )                -- 20091228 �ڼҿ� �߰�    
      
      -- ��ȸ������ �ӽ����̺�� ����    
      CREATE TABLE #TPDSFCProdOrder (WorkingTag NCHAR(1) NULL)      
      EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDSFCProdOrder'         
      IF @@ERROR <> 0 RETURN        
    
    IF @PlanEndDateTo = '' SELECT @PlanEndDateTo = '99991231'
  --select @WorkOrderDate, @WorkOrderDateTo    
  --    IF ISNULL(@WorkOrderDate,'') = '' SELECT @WorkOrderDate = '00000000'    
      
      ---- #TempTable �� ��� ����� INTO �� �ƴ� �����Ŀ� �־��ִ� ���·� ���� ---- 2014.04.04 �����
      CREATE TABLE #TPDSFCWorkOrder  
      (  
         WorkOrderSeq        INT                 ,       
         FactUnit            INT                 ,  
         WorkOrderNo         NVARCHAR(30)        ,  
         WorkOrderSerl       INT                 ,  
         WorkOrderDate       NCHAR(8)            ,  
         ProdPlanSeq         INT                 ,  
         WorkPlanSerl        INT                 ,  
         DailyWorkPlanSerl   INT                 ,  
         WorkCenterSeq       INT                 ,  
         GoodItemSeq         INT                 ,  
         ProcSeq             INT                 ,  
         AssyItemSeq         INT                 ,  
         ProdUnitSeq         INT                 ,  
         OrderQty            DECIMAL(19,5)       ,  
         ProgressQty         DECIMAL(19,5)       ,  
         OKQty               DECIMAL(19,5)       ,  
         BadQty              DECIMAL(19,5)       ,  
         ProdQty             DECIMAL(19,5)       ,  
         MatProgQty          DECIMAL(19,5)       ,  
         ProgStatus          INT                 ,  
         StdUnitQty          DECIMAL(19,5)       ,  
         WorkDate            NCHAR(8)            ,  
         WorkStartTime       NCHAR(4)            ,  
         WorkEndTime         NCHAR(4)            ,  
         ChainGoodsSeq       INT                 ,  
         WorkType            INT                  ,  
         DeptSeq             INT                 ,  
         ItemUnitSeq         INT                 ,  
         ProcRev             NCHAR(2)            ,  
         ItemBomRev          NCHAR(2)            ,  
         ItemBomRevName      NVARCHAR(2)         ,  
         Remark              NVARCHAR(200)       ,  
         IsProcQC            NCHAR(1)            ,  
         IsLastProc          NCHAR(1)            ,  
         IsPjt               NCHAR(1)            ,  
         PjtSeq              INT                 ,  
         WBSSeq              INT                 ,  
         ProdOrderSeq        INT                 ,  
         IsCancel            NCHAR(1)            ,  
         ProcNo              INT                 ,  
         Priority            INT                 ,  
         GoodItemName        NVARCHAR(200)       ,  
         GoodItemNo          NVARCHAR(100)       ,  
         GoodItemSpec        NVARCHAR(100)       ,  
         AssyItemName        NVARCHAR(200)       ,  
         AssyItemNo          NVARCHAR(100)       ,  
         AssyItemSpec        NVARCHAR(100)       ,  
         DeptName            NVARCHAR(200)       ,  
         ItemUnitName        NVARCHAR(30)        ,  
         ProdUnitName        NVARCHAR(30)        ,  
         WorkCenterName      NVARCHAR(100)       ,  
         ProcName            NVARCHAR(50)        ,  
         ProcRevName         NVARCHAR(40)        ,  
         ChainGoodsName      NVARCHAR(200)       ,  
         ChainGoodsNo        NVARCHAR(100)       ,  
         IDX_NO              INT IDENTITY(1, 1)  ,  
         PJTName             NVARCHAR(60)        ,  
         PJTNo               NVARCHAR(40)        ,  
         WBSName             NVARCHAR(80)        ,  
         ProdPlanNo          NVARCHAR(30)        ,  
         ProdPlanQty         DECIMAL(19,5)       ,  
         WHName              NVARCHAR(100)       ,  
         WorkerQty           DECIMAL(19,5)       ,  
         IsConfirm           NCHAR(1)            ,  
         WorkCond1           NVARCHAR(500)       ,  
         WorkCond2           NVARCHAR(500)       ,  
         WorkCond3           NVARCHAR(500)       ,  
         WorkCond4           DECIMAL(19,5)       ,  
         WorkCond5           DECIMAL(19,5)       ,  
         WorkCond6           DECIMAL(19,5)       ,  
         WorkCond7           DECIMAL(19,5)       ,  
         WorkTimeGroupName   NVARCHAR(100)       ,  
         RealLotNo      NVARCHAR(100)       ,  
         LastUserName        NVARCHAR(40)        ,  
         ProdRemark          NVARCHAR(200)       ,  
         LastDateTime        DATETIME            ,  
         EmpSeq              INT                  ,  
         EmpName             NVARCHAR(100)  , 
         ProdPlanDate       NCHAR(8), 
         PlanSrtDate        NCHAR(8), 
         PlanEndDate        NCHAR(8) , 
         IsMatInput         NCHAR(1), 
         IsGoodIn           NCHAR(1), 
         ReportEmpName      NVARCHAR(100), 
         ReportEmpSeq       INT 
         
      )  
     
      IF @WorkOrderSeq > 0  OR @WorkingTag = 'P' -- �����ؼ� �� ��� �ٸ� ������ ����.    
      BEGIN    
      
          SELECT  @FactUnit           = 0,    
                  @DeptSeq            = 0,    
                  @WHSeq              = 0,    
                  --@DeptName           = '',    
                  @DeptSeq            = 0,    
                  @WorkOrderNo     = '',    
                  @ProdPlanNo         = '',    
                  @GoodItemName       = '',    
                  @GoodItemNo         = '',    
                  @GoodItemSpec       = '',    
                  @WorkCenterSeq      = 0,    
            @ProcName           = '',    
                  @WorkDate         = '',    
                  @WorkDateTo         = '',      
                @WorkOrderDate      = '',      
                  @WorkOrderDateTo    = ''    
      
      END    
      
      
      INSERT INTO #TPDSFCWorkOrder  
         (  
             WorkOrderSeq        , FactUnit            , WorkOrderNo         , WorkOrderSerl       , WorkOrderDate       ,   
             ProdPlanSeq         , WorkPlanSerl        , DailyWorkPlanSerl   , WorkCenterSeq       , GoodItemSeq         ,   
             ProcSeq             , AssyItemSeq         , ProdUnitSeq         , OrderQty            , ProgressQty         ,   
             OKQty               , BadQty              , ProdQty             , MatProgQty          , ProgStatus          ,   
               StdUnitQty           , WorkDate            , WorkStartTime       , WorkEndTime         , ChainGoodsSeq       ,   
             WorkType            , DeptSeq             , ItemUnitSeq         , ProcRev             , ItemBomRev          ,   
             ItemBomRevName      , Remark              , IsProcQC            , IsLastProc          , IsPjt               ,   
             PjtSeq              , WBSSeq              , ProdOrderSeq        , IsCancel            , ProcNo              ,   
             Priority            , GoodItemName        , GoodItemNo          , GoodItemSpec        , AssyItemName        ,   
             AssyItemNo          , AssyItemSpec        , DeptName            , ItemUnitName        , ProdUnitName        ,   
             WorkCenterName      , ProcName            , ProcRevName         , ChainGoodsName      , ChainGoodsNo        ,   
             PJTName             , PJTNo               , WBSName             , ProdPlanNo          , ProdPlanQty         ,   
             WHName              , WorkerQty           , IsConfirm           , WorkCond1           , WorkCond2           ,   
             WorkCond3           , WorkCond4           , WorkCond5           , WorkCond6           , WorkCond7           ,   
             WorkTimeGroupName   , RealLotNo           , LastUserName        , ProdRemark          , LastDateTime        ,   
             EmpSeq              , EmpName             , ProdPlanDate       , PlanSrtDate          , PlanEndDate         , 
             IsMatInput          , IsGoodIn            , ReportEmpName      , ReportEmpSeq  
             
             
             
             
             
         ) 
      SELECT   A.WorkOrderSeq    
              ,A.FactUnit    
              ,A.WorkOrderNo    
              ,A.WorkOrderSerl    
              ,A.WorkOrderDate    
              ,A.ProdPlanSeq    
              ,A.WorkPlanSerl    
              ,A.DailyWorkPlanSerl    
              ,A.WorkCenterSeq    
              ,A.GoodItemSeq    
              ,A.ProcSeq    
              ,A.AssyItemSeq    
              ,A.ProdUnitSeq    
              ,A.OrderQty    
              ,CONVERT(DECIMAL(19,5),0) AS ProgressQty      -- �������    
              ,CONVERT(DECIMAL(19,5),0) AS OKQty            -- ��ǰ����    
              ,CONVERT(DECIMAL(19,5),0) AS BadQty           -- �ҷ�����    
              ,A.OrderQty               AS ProdQty          -- �ܷ�    
              ,CONVERT(DECIMAL(19,5),0) AS MatProgQty     -- ��������������    
              ,6036001                  AS ProgStatus       -- �����������    
              ,A.StdUnitQty    
              ,A.WorkDate    
              ,A.WorkStartTime    
              ,A.WorkEndTime    
              ,A.ChainGoodsSeq    
              ,A.WorkType    
              ,A.DeptSeq    
              ,A.ItemUnitSeq    
      
              ,A.ProcRev    
              ,A.ItemBomRev    
              ,CASE WHEN ISNULL(BM.ItemBOMRevRemark,'') = '' THEN  A.ItemBomRev ELSE BM.ItemBOMRevRemark END  AS ItemBomRevName      -- ECO ���볻���̿��� ���������ʰ� �׳�BOM���� �״�� ��ȸ�ϵ���        12.07.25 BY �輼ȣ
 --             ,ISNULL((SELECT BOMRevName FROM _TPDBOMECOApply WHERE CompanySeq = A.CompanySeq AND ItemSeq = A.GoodItemSeq AND chgBOMRev = A.ItemBomRev and IsRevUp = '1' AND IsApplied = '1'), A.ItemBomRev) AS ItemBomRevName    
              ,A.Remark    
              ,A.IsProcQC    
              ,A.IsLastProc    
              ,A.IsPjt    
              ,A.PjtSeq    
              ,A.WBSSeq    
              ,A.ProdOrderSeq    
              ,A.IsCancel    
              ,A.ProcNo    
              ,A.Priority    
      
              ,I.ItemName             AS GoodItemName    
              ,I.ItemNo               AS GoodItemNo    
              ,I.Spec                 AS GoodItemSpec    
              ,S.ItemName             AS AssyItemName    
              ,S.ItemNo               AS AssyItemNo    
              ,S.Spec                 AS AssyItemSpec    
              ,D.DeptName          
              ,U.UnitName             AS ItemUnitName    
              ,Y.UnitName             AS ProdUnitName    
              ,W.WorkCenterName       AS WorkCenterName    
              ,P.ProcName             AS ProcName    
              ,ISNULL(V.ProcRevName,A.ProcRev)           AS ProcRevName    
      
              ,C.ChainGoodsName       AS ChainGoodsName    
              ,C.ChainGoodsNo         AS ChainGoodsNo    
              ,F.PJTName              AS PJTName    -- ������Ʈ ���� �߰� 09.1.3 ����    
              ,F.PJTNo                AS PJTNo      -- ������Ʈ ���� �߰� 09.1.3 ����    
              ,G.WBSName              AS WBSName    -- ������Ʈ ���� �߰� 09.1.3 ����    
              ,M.ProdPlanNo           AS ProdPlanNo    
              ,M.ProdQty              AS ProdPlanQty    
              ,WH.WHName              AS WHName    
              ,(Select SUM(CurrWorkerCnt) from _TPDBaseWorkCenterEmp where CompanySeq = 14 AND WorkCenterSeq = A.WorkCenterSeq)   AS WorkerQty    
              ,ISNULL((SELECT CONVERT(NCHAR(1),CfmCode) FROM _TPDSFCWorkOrder_Confirm WITH(NOLOCK)     
                                                           WHERE CompanySeq = @CompanySeq    
                                                             AND CfmSeq = A.WorkOrderSeq    
                                                             AND CfmSerl = A.WorkOrderSerl),'0')         AS IsConfirm    
              ,A.WorkCond1    
              ,A.WorkCond2    
              ,A.WorkCond3    
              ,A.WorkCond4    
              ,A.WorkCond5    
              ,A.WorkCond6    
              ,A.WorkCond7    
              ,ISNULL((SELECT MinorName FROM _TDAUMinor where CompanySeq = @CompanySeq AND A.WorkTimeGroup = MinorSeq),'')  AS WorkTimeGroupName -- �۱⿬ �߰�    
              ,CONVERT(NVARCHAR(50), '') AS RealLotNo     -- 2010. 12. 26 hkim �߰�(�ҷ����۾��� LotNo ��������)    
              ,LU.UserName AS LastUserName  
              ,M.Remark    AS ProdRemark
              ,A.LastDateTime AS LastDateTime  
              ,A.EmpSeq       AS EmpSeq   -- 20140103 ������߰�
              ,Emp.EmpName     AS EmpName  -- 20140103 ������߰�
              ,M.ProdPlanDate 
              ,M.SrtDate 
              ,M.EndDate 
              ,CASE WHEN EXISTS (SELECT 1 FROM _TPDSFCMatinput WHERE CompanySeq = @CompanySeq AND WorkReportSeq = ZZ.WorkReportSeq) THEN '1' ELSE '0'END AS IsMatInput 
              ,CASE WHEN EXISTS (SELECT 1 FROM _TPDSFCGoodIn WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND WorkReportSeq = ZZ.WorkReportSeq) THEN '1' ELSE '0' END AS IsGoodIn 
              ,ZZ.EmpName
              ,ZZ.EmpSeq 
        FROM  _TPDSFCWorkOrder            AS A WITH(NOLOCK)     
          LEFT OUTER JOIN _TDAItem        AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq    
                    AND A.GoodItemSeq  = I.ItemSeq    
          LEFT OUTER JOIN _TDAItem        AS S WITH(NOLOCK) ON A.CompanySeq   = S.CompanySeq    
                                AND A.AssyItemSeq  = S.ItemSeq    
          LEFT OUTER JOIN _TDAUnit        AS U WITH(NOLOCK) ON A.CompanySeq   = U.CompanySeq    
                                                           AND A.ItemUnitSeq  = U.UnitSeq    
          LEFT OUTER JOIN _TDAUnit        AS Y WITH(NOLOCK) ON A.CompanySeq   = Y.CompanySeq    
                                     AND A.ProdUnitSeq  = Y.UnitSeq    
      
          LEFT OUTER JOIN _TDADept        AS D WITH(NOLOCK) ON A.CompanySeq   = D.CompanySeq    
                                                           AND A.DeptSeq      = D.DeptSeq    
          LEFT OUTER JOIN _TPDBaseWorkCenter  AS W WITH(NOLOCK) ON A.CompanySeq   = W.CompanySeq    
                                                           AND A.WorkCenterSeq      = W.WorkCenterSeq    
          LEFT OUTER JOIN _TPDBaseProcess  AS P WITH(NOLOCK) ON A.CompanySeq   = P.CompanySeq    
                                                           AND A.ProcSeq      = P.ProcSeq    
          LEFT OUTER JOIN _TPDROUItemProcRev  AS V WITH(NOLOCK) ON A.CompanySeq   = V.CompanySeq    
                                                           AND A.GoodItemSeq      = V.ItemSeq    
                                                           AND A.ProcRev          = V.ProcRev    
          LEFT OUTER JOIN _TPDBOMChainProd    AS C WITH(NOLOCK) ON A.CompanySeq   = C.CompanySeq    
                                                           AND A.ChainGoodsSeq    = C.ChainGoodsSeq    
          LEFT OUTER JOIN _TPJTProject    AS F WITH(NOLOCK) ON A.CompanySeq   = F.CompanySeq            -- ������Ʈ ���� �߰� 09.1.3 ����    
                                                           AND A.PJTSeq       = F.PJTSeq    
          LEFT OUTER JOIN _TPJTWBS        AS G WITH(NOLOCK) ON A.CompanySeq   = G.CompanySeq           -- ������Ʈ ���� �߰� 09.1.3 ����    
                                                           AND A.PJTSeq       = G.PJTSeq    
                                                           AND A.WBSSeq       = G.WBSSeq    
          LEFT OUTER JOIN _TPDMPSDailyProdPlan AS M WITH(NOLOCK) ON A.CompanySeq   = M.CompanySeq     
                                                           AND A.ProdPlanSeq       = M.ProdPlanSeq
          LEFT OUTER JOIN _TPDBOMManagement    AS BM WITH(NOLOCK) ON A.CompanySeq = BM.CompanySeq
                                                                 AND M.ItemSeq    = BM.ItemSeq
                                                                 AND M.BOMRev     = BM.ItemBomRev
          LEFT OUTER JOIN _TDAWH          AS WH WITH(NOLOCK) ON A.CompanySeq   = WH.CompanySeq     
                                                            AND W.FieldWhSeq = WH.WHSeq    
          LEFT OUTER JOIN _TCAUser        AS LU WITH(NOLOCK) ON A.CompanySeq = LU.CompanySeq    
                                                            AND A.LastUserSeq = LU.UserSeq    
          LEFT OUTER JOIN _TDAEmp         AS EMP WITH(NOLOCK) ON A.EmpSeq     = EMP.EmpSeq
                                                             AND A.CompanySeq = EMP.CompanySeq 
          OUTER APPLY (
                        SELECT TOP 1 Z.WorkReportSeq, Z.EmpSeq, Y.EmpName
                          FROM _TPDSFCWorkReport AS Z 
                          LEFT OUTER JOIN _TDAEmp AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.EmpSeq = Z.EmpSeq ) 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.WorkOrderSeq = A.WorkOrderSeq 
                           AND Z.WorkOrderSerl = A.WorkOrderSerl 
                     ) AS ZZ 
       WHERE  A.CompanySeq        = @CompanySeq     
         AND  (@WorkOrderSeq      = 0     OR A.WorkOrderSeq   = @WorkOrderSeq)    
         AND  (@WorkOrderSerl     = 0     OR A.WorkOrderSerl  = @WorkOrderSerl)    
         AND  (@WorkOrderNo       = ''    OR A.WorkOrderNo    LIKE @WorkOrderNo + '%')    
         AND  (@FactUnit          = 0     OR A.FactUnit       = @FactUnit)    
         AND  (@DeptSeq           = 0     OR A.DeptSeq        = @DeptSeq)    
         --AND  (@DeptName          = ''    OR D.DeptName       LIKE @DeptName + '%')    
         AND  (@WorkDate          = ''    OR A.WorkDate       >= @WorkDate)    
         AND  (@WorkDateTo        = ''    OR A.WorkDate       <= @WorkDateTo)    
         AND  (@WorkOrderDate  = ''    OR A.WorkOrderDate  >= @WorkOrderDate)    
         AND  (@WorkOrderDateTo   = ''    OR A.WorkOrderDate  <= @WorkOrderDateTo)    
         AND  (@WorkOrderNo       = ''    OR A.WorkOrderNo    LIKE @WorkOrderNo + '%')    
             
         AND  (@GoodItemName      = ''    OR I.ItemName       LIKE @GoodItemName + '%')    
         AND  (@GoodItemNo        = ''    OR I.ItemNo         LIKE @GoodItemNo + '%')    
         AND  (@GoodItemSpec      = ''    OR I.Spec           LIKE @GoodItemSpec + '%')    
         AND  (@WorkCenterSeq     = 0     OR A.WorkCenterSeq = @WorkCenterSeq)    
         AND  (@ProcName          = ''    OR P.ProcName       LIKE @ProcName + '%')    
             
         AND  (@ProdPlanNo        = ''    OR ISNULL(M.ProdPlanNo, '')       LIKE @ProdPlanNo + '%') -- 20100105 �ڼҿ� ����    
         AND  ((@ChainGoodsSeq > 0 AND A.ChainGoodsSeq > 0)     OR A.ChainGoodsSeq  = @ChainGoodsSeq) -- @ChainGoodsSeq : ����ǰ��ȸ�̸� 1, �ƴϸ� 0    
         AND  (@PJTName           = ''    OR F.PJTName        LIKE @PJTName + '%')                -- ������Ʈ ���� �߰� 09.1.3 ����    
         AND  (@PJTNo            = ''    OR F.PJTNo          LIKE @PJTNo   + '%')                -- ������Ʈ ���� �߰� 09.1.3 ����    
         AND  (@WHSeq             = 0     OR W.FieldWhSeq     = @WHSeq)    
         AND  (@WorkingTag <> 'P' OR EXISTS (SELECT 1 FROM #TPDSFCProdOrder WHERE ProdOrderSeq = A.ProdOrderSeq))    
         AND  (@PgmSeq            IN (1009,5563)  OR W.SMWorkCenterType   IN (6011001,6011002))  -- �۾������Է�ȭ�鿡���� ��� ���̰� �۾�������ȸ ȭ�鿡���� ���ִ� ����    
         AND (@WorkType          = 0     OR A.WorkType       = @WorkType)
         AND (M.EndDate BETWEEN @PlanEndDateFr AND @PlanEndDateTo) 
     
  
      -- ���۾����ð��� ������, ��õ�۾����ðǵ� ��´�
      --(_SCOMSourceTracking �Ͽ� ��õ�۾����ð��� �ŷ�ó �������� ����. ������ȸ�ÿ��� ���ܵ�)  -- 12.06.01 BY �輼ȣ
     IF EXISTS(SELECT 1  
                 FROM #TPDSFCWorkOrder AS A  
                   JOIN #TPDSFCWorkOrder AS B ON A.WorkOrderSeq = B.WorkOrderSeq  
                WHERE A.WorkType IN (6041003, 6041009))  
     BEGIN  
         INSERT #TPDSFCWorkOrder(WorkOrderSeq, FactUnit, WorkOrderNo, WorkOrderSerl, GoodItemSeq, WorkDate)  
         SELECT B.WorkOrderSeq, 0, '0', MIN(B.WorkOrderSerl), B.GoodItemSeq, MIN(B.WorkDate)  
           FROM #TPDSFCWorkOrder AS A  
             JOIN _TPDSFCWorkORder AS B WITH(NOLOCK) ON A.WorkOrderSeq = B.WorkOrderSeq  
                                                    AND B.CompanySeq   = @CompanySeq  
          WHERE A.WorkType IN (6041003, 6041009)  
            AND  B.WorkType IN (6041001)  
          GROUP BY B.WorkOrderSeq, B.GoodItemSeq  
     END  
  
      -- �����������.    
      INSERT #TMP_PROGRESSTABLE    
      SELECT 1, '_TPDSFCWorkReport'    
      UNION    
      SELECT 2, '_TPDMMOutReqGood'    
          
      
      EXEC _SCOMProgressTracking  @CompanySeq, '_TPDSFCWorkOrder', '#TPDSFCWorkOrder','WorkOrderSeq', 'WorkOrderSerl',''    
      
      
      SELECT A.IDX_NO, A.IDOrder, SUM(A.Qty) AS Qty, SUM(C.OKQty) AS OKQty, SUM(C.BadQty) AS BadQty    
        INTO #TCOMProgressTrackingSUM    
        FROM #TCOMProgressTracking      AS A    
             JOIN _TPDSFCWorkReport     AS C ON C.CompanySeq = @CompanySeq -- ��ǰ/�ҷ����� 20100721 �ڼҿ� �߰�    
                                            AND C.WorkReportSeq = A.Seq    
       GROUP BY IDX_NO, IDOrder    
      
      
      UPDATE #TPDSFCWorkOrder    
         SET ProgressQty = ISNULL(B.Qty, 0)  ,    
             OKQty       = ISNULL(B.OKQty, 0),    
             BadQty      = ISNULL(B.BadQty, 0),    
             ProdQty     = CASE --WHEN A.WorkType = 6041004 AND ISNULL(B.Qty,0) - A.OrderQty <= 0 THEN 0     
                                --WHEN A.WorkType = 6041004 AND ISNULL(B.Qty,0) - A.OrderQty > 0 THEN  A.OrderQty - ISNULL(B.Qty,0)    
                                WHEN A.OrderQty - ISNULL(B.Qty,0) <= 0 THEN 0     
                                ELSE A.OrderQty - ISNULL(B.Qty,0)     
                           END,    
             ProgStatus  = CASE WHEN A.IsCancel = '1' THEN 6036005 -- �ߴ�    
                                WHEN EXISTS(SELECT 1 
                                              FROM _TPDSFCWorkReport AS A1 WITH(NOLOCK) 
                                                   JOIN _TPDSFCGoodIn AS B1 WITH(NOLOCK) ON A1.WorkReportSeq = B1.WorkReportSeq
                                                                                        AND A1.CompanySeq    = B1.CompanySeq
                                             WHERE A1.CompanySeq       = @CompanySeq 
                        AND A1.WorkOrderSeq  = A.WorkOrderSeq 
                                               AND A1.WorkOrderSerl = A.WorkOrderSerl
                                               AND B1.IsWorkOrderEnd = '1') THEN 6036004 --�Ϸ�     
                                -- 2010.11.19 ����������. �����԰�ȭ���� �۾����ÿϷῡ üũ�� �ϰԵǸ� ����������ŭ ������ ������� �ʴ��� �ش������� �Ϸ�� ó���Ѵ�.     
                                WHEN ABS(A.OrderQty) > ABS(B.Qty) THEN 6036003 -- ������    
                                WHEN ABS(A.OrderQty) <= ABS(B.Qty) THEN 6036004 --�Ϸ�    
                                WHEN A.IsConfirm = '1' THEN 6036002   -- Ȯ��    
                                ELSE 6036001 -- �ۼ�    
                           END     
        FROM #TPDSFCWorkOrder                      AS A    
          LEFT OUTER JOIN #TCOMProgressTrackingSUM AS B ON A.IDX_NO = B.IDX_NO    
                                                       AND B.IDOrder = 1    
  
      
      UPDATE #TPDSFCWorkOrder    
         SET MatProgQty = B.Qty     
        FROM #TPDSFCWorkOrder             AS A    
          JOIN #TCOMProgressTrackingSUM   AS B ON A.IDX_NO = B.IDX_NO    
                                              AND B.IDOrder = 2    
      
  /***********[PoNo��������]��õ �������� ���� 20091228 �ڼҿ� �߰� **************/      
        
      -- ��õ���̺�        
      CREATE TABLE #TMP_SOURCETABLE (IDOrder INT, TABLENAME   NVARCHAR(100))                
          
      -- ��õ ������ ���̺�        
      CREATE TABLE #TCOMSourceTracking (IDX_NO INT,             IDOrder INT,            Seq  INT,            Serl  INT,        SubSerl     INT,                
                                        Qty    DECIMAL(19, 5),  STDQty  DECIMAL(19, 5), Amt  DECIMAL(19, 5), VAT   DECIMAL(19, 5))                      
          
        
      INSERT #TMP_SOURCETABLE          
         
       SELECT 2, '_TPDMPSProdReqItem'            -- �����Ƿ�      
      union    
      SELECT 3, '_TSLOrderItem'               -- ����      
      UNION      
      SELECT 4, '_TPDQAAfterInBadReworkItem'  -- �԰��� �ҷ�ó��    
      UNION     
      SELECT 5, '_TPDQCLastProcBad'           -- �����˻�ҷ�    
          
      
        
      EXEC _SCOMSourceTracking  @CompanySeq, '_TPDSFCWorkOrder', '#TPDSFCWorkOrder','WorkOrderSeq', 'WorkOrderSerl',''     
        
      SELECT X.IDX_NO ,      
             X.ProdPlanSeq,    
             ISNULL(C.OrderNo,'') AS SoNo ,      
             ISNULL(C.PONo   ,'') AS PoNo ,    
             ISNULL(C.CustSeq, 0) AS CustSeq,        
             ISNULL(A.Seq, 0) AS OrderSeq,    
             ISNULL(A.Serl, 0) AS OrderSerl,
             ISNULL(D.ItemSeq, 0) AS ItemSeq     
        INTO #SOInfo      
        FROM #TPDSFCWorkOrder AS X Left Outer JOIN #TCOMSourceTracking AS A ON X.IDX_NO = A.IDX_NO    
             Left OUTER JOIN _TSLOrder AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq AND A.Seq  = C.OrderSeq
             LEFT OUTER JOIN _TSLOrderItem AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq AND A.Seq = D.OrderSeq AND A.Serl = D.OrderSerl        
       WHERE A.IDOrder = 3      
         AND C.CompanySeq = @CompanySeq      
  
      -- ���ְŷ�ó�� ���� ��� �����Ƿ��� �ŷ�ó ���������� �߰� 2011. 3. 9 hkim           
      SELECT DISTINCT     -- �Ѱ��� ���ҵǾ� ���� �Ǿ��� ��� �ߺ��ؼ� ��ȸ�� ���� �־ DISTINCT �߰� 2011. 6. 14 hkim    
             X.IDX_NO,    
             ISNULL(C.CUstSeq, 0) AS CustSeq,     
             C.DelvDate    
        INTO #ProdReqInfo               
        FROM #TPDSFCWorkOrder AS X JOIN #TCOMSourceTracking AS A ON X.IDX_NO = A.IDX_NO    
             JOIN _TPDMPSProdReqItem  AS C ON A.Seq  = C.ProdReqSeq    
                                          AND A.Serl = C.Serl    
       WHERE A.IDOrder = 2        
         AND C.CompanySeq = @CompanySeq            
  
      -- �԰��� �ҷ� �˻� Lot��ȣ ����    
      UPDATE #TPDSFCWorkOrder    
         SET RealLotNo = B.LotNo    
        FROM #TPDSFCWorkOrder AS X     
             JOIN #TCOMSourceTracking         AS A ON X.IDX_NO = A.IDX_NO    
             JOIN _TPDQAAfterInBadReworkItem  AS B ON A.Seq    = B.BadReworkSeq    
                             AND A.Serl   = B.BadReworkSerl    
       WHERE A.IDOrder    = 4    
         AND B.CompanySeq = @CompanySeq    
      -- �����˻� �ҷ� Lot��ȣ ����    
      UPDATE #TPDSFCWorkOrder    
         SET RealLotNo = C.RealLotNo    
        FROM #TPDSFCWorkOrder AS X     
             JOIN #TCOMSourceTracking         AS A ON X.IDX_NO     = A.IDX_NO    
             JOIN _TPDQCTestReport            AS B ON A.Seq        = B.QCSeq    
         JOIN _TPDSFCWorkReport           AS C ON B.CompanySeq = C.CompanySeq    
                                                  AND B.SourceSeq  = C.WorkReportSeq    
       WHERE A.IDOrder    = 5    
         AND B.CompanySeq = @CompanySeq    
         AND B.SourceType = '3'    
             
      
      INSERT INTO #SOInfo    
      SELECT A.IDX_NO,    
             A.ProdPlanSeq,    
           '','',0,0,0,0    
        FROM #TPDSFCWorkOrder AS A LEFT OUTER JOIN #SOInfo AS B ON A.IDX_NO = B.IDX_NO    
       WHERE B.IDX_NO IS NULL    
  
   -- �����ȹ�ڵ�� ���ֹ�ȣ�� ã���� ���� 2010. 4. 5 ����    
   SELECT A.IDX_NO AS IDX_NO,     
       B.ProdPlanSeq AS ProdPlanSeq    
     INTO #ProdInfo    
     FROM #SOInfo        AS A    
       JOIN _TPDDailyProdPlanSemiPlan AS B ON A.ProdPlanSeq = B.SemiProdPlanSeq AND B.CompanySeq = @CompanySeq    
    WHERE ISNULL(A.SONo, '') = ''      
       
   DELETE FROM  #TCOMSourceTracking      
      
      EXEC _SCOMSourceTracking  @CompanySeq, '_TPDMPSDailyProdPlan', '#ProdInfo','ProdPlanSeq', '',''      
      
     UPDATE #SOInfo    
      SET SONo  = ISNULL(C.OrderNo,'') ,    
       PONo  = ISNULL(C.PONo   ,'') ,    
       CustSeq = ISNULL(C.CustSeq, 0)  ,    
       OrderSeq = ISNULL(B.Seq, 0)  ,    
       OrderSerl= ISNULL(B.Serl, 0)   
     FROM #SOInfo     AS A    
       JOIN #TCOMSourceTracking AS B ON A.IDX_NO = B.IDX_NO    
             Left OUTER JOIN _TSLOrder AS C WITH(NOLOCK) ON B.Seq  = C.OrderSeq        
       WHERE C.CompanySeq = @CompanySeq    
         AND B.IDOrder    = 3     
   -- 2010. 4. 5. ����    
      
       DELETE FROM  #TCOMSourceTracking  -- 20100121 �ڼҿ� �߰�     
      
      
  --  /*����ǰ�� ����ǰ ���ֹ�ȣ�������� 20100121 �ڼҿ� �߰�*/    
  --    SELECT C.WorkOrderSeq, C.WorkOrderSerl, A.IDX_NO, 0 AS OrderSeq, 0 AS OrderSerl, CONVERT(NVARCHAR(200), '') AS OrderNo    
  --      INTO #SemiProd    
  --      FROM #TPDSFCWorkOrder AS A     
  --           JOIN _TPDDailyProdPlanSemiPlan AS B ON B.CompanySeq = @CompanySeq AND A.ProdPlanSeq = B.SemiProdPlanSeq    
  --           JOIN _TPDSFCWorkOrder AS C ON B.CompanySeq = C.CompanySeq AND B.ProdPlanSeq = C.ProdPlanSeq    
  --     WHERE A.IDX_NO NOT IN(SELECT IDX_NO FROM #SOInfo)    
  --      
  --      EXEC _SCOMSourceTracking  @CompanySeq, '_TPDSFCWorkOrder', '#SemiProd','WorkOrderSeq', 'WorkOrderSerl',''     
  --    
  ----SELECT * FROM #TCOMSourceTracking    
  --    
  --    UPDATE A    
  --       SET A.OrderSeq  = ISNULL(B.Seq, 0),    
  --           A.OrderSerl = ISNULL(B.Serl, 0),    
  --           A.OrderNo   = ISNULL(C.OrderNo,'')    
  --      FROM #SemiProd AS A    
  --           JOIN #TCOMSourceTracking AS B ON A.IDX_NO = B.IDX_NO      
  --           JOIN _TSLOrder AS C WITH(NOLOCK) ON B.Seq  = C.OrderSeq       
  ----           JOIN _TSLOrderItem AS I WITH(NOLOCK) ON B.Seq = I.OrderSeq AND B.Serl = I.OrderSerl AND B.SubSerl = I.OrderSubSerl                                        
  -- WHERE B.IDOrder = 3      
  --       AND C.CompanySeq  =@CompanySeq      
      
     /*����ǰ�� ����ǰ ���ֹ�ȣ�������� ��*/    
      
                
  /**************************[PoNo��������]��õ �������� ��********************************/      
      
  /**************************[������ ��������] 20091228 �ڼҿ� �߰�***********************************/    
  DECLARE @SpecName NVARCHAR(100), @SpecValue NVARCHAR(100), @OrderSeq INT, @OrderSerl INT, @SpecSeq INT, @SubSeq INT    
      
  CREATE TABLE #TempSOSpec    
  (    
      Seq      INT IDENTITY,    
      OrderSeq INT,    
      OrderSerl INT,    
      SpecName  NVARCHAR(100),    
      SpecValue NVARCHAR(100)    
  )    
      
      
  INSERT INTO #TempSOSpec    
  SELECT DISTINCT C.OrderSeq, C.OrderSerl,'',''    
    FROM #SOInfo AS A JOIN _TSLOrder AS D ON A.Sono = D.OrderNo AND D.CompanySeq = @CompanySeq    
                    JOIN _TSLOrderItem AS B ON D.OrderSeq = B.OrderSeq AND B.CompanySeq = @CompanySeq    
                      JOIN _TSLOrderItemspecItem AS C ON B.OrderSeq = C.OrderSeq AND B.OrderSerl = C.OrderSerl AND C.CompanySeq = @CompanySeq    
      
  --UNION  -- 20100121 �ڼҿ� �߰�     
  --    
  --SELECT DISTINCT C.OrderSeq, C.OrderSerl,'',''  -- 20100121 �ڼҿ� �߰�     
  --  FROM #SemiProd AS A JOIN _TSLOrder AS D ON A.OrderNo = D.OrderNo AND D.CompanySeq = @CompanySeq    
  --                      JOIN _TSLOrderItem AS B ON D.OrderSeq = B.OrderSeq AND B.CompanySeq = @CompanySeq    
  --     JOIN _TSLOrderItemspecItem AS C ON B.OrderSeq = C.OrderSeq AND B.OrderSerl = C.OrderSerl AND C.CompanySeq = @CompanySeq    
  -- WHERE A.OrderSeq <> 0     
       SELECT @SpecSeq = 0    
      
      WHILE (1=1)    
      BEGIN    
          SET ROWCOUNT 1    
      
          SELECT @SpecSeq = Seq, @OrderSeq = OrderSeq, @OrderSerl = OrderSerl    
            FROM #TempSOSpec    
           WHERE Seq > @SpecSeq    
           ORDER BY Seq    
      
          IF @@Rowcount = 0 BREAK    
      
          SET ROWCOUNT 0    
      
          SELECT @SubSeq = 0, @SpecName = '', @SpecValue = ''    
      
          WHILE(1=1)    
          BEGIN    
              SET ROWCOUNT 1    
      
              SELECT @SubSeq = OrderSpecSerl    
                FROM _TSLOrderItemspecItem    
               WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl > @SubSeq AND CompanySeq = @CompanySeq    
               ORDER BY OrderSpecSerl    
      
              IF @@Rowcount = 0 BREAK    
      
              SET ROWCOUNT 0    
      
              IF ISNULL(@SpecName,'') = ''    
              BEGIN    
                  SELECT @SpecName = B.SpecName, @SpecValue = (CASE WHEN B.UMSpecKind = 84003 THEN ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SpecItemValue), '')    
                                                                                              ELSE ISNULL(A.SpecItemValue, '') END)    
                    FROM _TSLOrderItemspecItem AS A JOIN _TSLSpec AS B ON A.SpecSeq = B.SpecSeq AND A.CompanySeq = B.CompanySeq    
                   WHERE A.CompanySeq = @CompanySeq AND OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl = @SubSeq    
              END    
              ELSE    
              BEGIN    
                  SELECT @SpecName = @SpecName +'/'+B.SpecName, @SpecValue = @SpecValue+'/'+ (CASE WHEN B.UMSpecKind = 84003 THEN ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SpecItemValue), '')    
                                                                                              ELSE ISNULL(A.SpecItemValue, '') END)    
                    FROM _TSLOrderItemspecItem AS A JOIN _TSLSpec AS B ON A.SpecSeq = B.SpecSeq AND A.CompanySeq = B.CompanySeq    
                   WHERE A.CompanySeq = @CompanySeq AND OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl = @SubSeq    
              END    
      
              UPDATE #TempSOSpec    
                 SET SpecName = @SpecName, SpecValue = @SpecValue    
               WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl    
      
          END    
      
      END    
      SET ROWCOUNT 0    
  /*********************[������ ��������] ��***************************************************/      
  
 ---------------------------------------------------------------------------------------------------------
     -- �ŷ�ó �������� ( �켱���� : �ŷ�ó��OEMǰ�� -> �����Ƿ� -> ����)        -- 12.05.24 BY �輼ȣ
 ---------------------------------------------------------------------------------------------------------
     
        ALTER TABLE #TPDSFCWorkOrder ADD CustSeq INT
         UPDATE #TPDSFCWorkOrder    
          SET CustSeq = B.CustSeq
         FROM #TPDSFCWorkOrder AS A 
         JOIN _TPDBaseCustOEMItem AS B ON A.GoodItemSeq = B.ItemSeq 
                                      AND B.CompanySeq = @CompanySeq   
                                      AND A.WorkDate BETWEEN B.DateFr AND B.DateTo                           
  
         UPDATE #TPDSFCWorkOrder
           SET CustSeq = CASE WHEN ISNULL(B.CustSeq, 0) = 0 THEN ISNULL(C.CustSeq, 0) ELSE ISNULL(B.CustSeq, 0) END
          FROM #TPDSFCWorkOrder           AS A
          LEFT OUTER JOIN #ProdReqInfo    AS B ON A.IDX_NO = B.IDX_NO    
          LEFT OUTER JOIN #SOInfo         AS C ON A.IDX_NO = C.IDX_NO   
         WHERE A.CustSeq IS NULL
   
         -- ���۾��ǵ��� ��õ �۾������� �ŷ�ó �ڵ� ��ȸ�ǵ���
         UPDATE #TPDSFCWorkOrder
            SET CustSeq = (SELECT TOP 1 CustSeq FROM #TPDSFCWorkOrder WHERE WorkOrderSeq = WorkOrderSeq AND CustSeq <> 0)
           FROM #TPDSFCWorkOrder AS A
          WHERE A.WorkType IN (6041003, 6041009)
          DELETE FROM #TPDSFCWorkOrder WHERE WorkOrderNo = '0'        -- �ŷ�ó������ ��Ҵ� ��õ�۾����ð��� ����
 ---------------------------------------------------------------------------------------------------------
       -- ���࿬���� ��ǰ������ �ƴ� ����������� �Ѵ�.     
      -- ��ũ���ͺ��۾�������Ȳ�� ��ǰ������ ��ȸ �ϹǷ�         
      IF @WorkingTag = 'W'    
          GOTO WorkCenterList -- ��ũ���ͺ� �۾�������Ȳ    
  -----------------------------------------------------------------------------------------------------------------    
      
  
       SELECT      
             A.*    
             ,ISNULL( ch1.FactUnitName, '')    AS FactUnitName    
             ,ISNULL( ch2.MinorName, '')   AS ProgStatusName    
             ,ISNULL( ch3.MinorName, '')   AS WorkTypeName    
             --,ISNULL((SELECT TOP 1 '1' FROM #TCOMProgressTracking WHERE IDX_NO = A.IDX_NO AND IDOrder = '2'),'0') AS MatOutYn    
             ,(SELECT TOP 1 1 FROM _TPDMMOutReqItem WHERE CompanySeq = @CompanySeq AND WorkOrderSeq = A.WorkOrderSeq AND WorkOrderSerl = A.WorkOrderSerl) AS MatOutYn     -- 2011.5.6 hkim ��������û���� ������� ���� �����Ͽ�     
             ,C.PoNo    
             ,A.CustSeq  AS CustSeq      -- 12.05.24 BY �輼ȣ ����
             ,J.CustName AS CustName     -- 12.05.24 BY �輼ȣ ����
             ,(SELECT TOP 1 1 FROM _TSLOrderItemSpec WHERE CompanySeq = @CompanySeq AND OrderSeq = C.OrderSeq AND OrderSerl = C.OrderSerl)AS IsSpec  -- 20100121 �ڼҿ� �߰�    
             ,ISNULL(D.SpecName,'')   AS SpecName  -- 20100121 �ڼҿ� �߰�     
             ,ISNULL(D.SpecValue, '') AS SpecValue -- 20100121 �ڼҿ� �߰�    
             ,ISNULL(CASE ISNULL(H.CustItemNo, '')      
                      WHEN '' THEN (SELECT CI.CustItemNo FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = C.CustSeq  AND A.GoodItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)       
                      ELSE H.CustItemNo END, '')  AS  CustItemNo       
             ,ISNULL(CASE ISNULL(H.CustItemName, '')      
                      WHEN '' THEN (SELECT CI.CustItemName FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = C.CustSeq  AND A.GoodItemSeq = CI.ItemSeq AND CI.UnitSeq = 0) 
                      ELSE H.CustItemName END, '') AS  CustItemName      
             ,ISNULL(CASE ISNULL(H.CustItemSpec, '')      
                      WHEN '' THEN (SELECT CI.CustItemSpec FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = C.CustSeq  AND A.GoodItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)       
                      ELSE H.CustItemSpec END, '') AS  CustItemSpec     
             ,A.Remark AS ProdRemark    
              -- 2011.04.25 �輭�� �߰�    
             , CASE ISNULL(I.DelvDate,'') WHEN '' THEN CASE ISNULL(G.DVDate,'') WHEN '' THEN Z.DVDate     
                       ELSE G.DVDate     
                        END     
              ELSE I.DelvDate 
                 END AS DVDate             
        FROM #TPDSFCWorkOrder     AS A    
         LEFT OUTER JOIN #SOInfo         AS C ON A.IDX_NO = C.IDX_NO AND A.GoodItemSeq = C.ItemSeq   
         LEFT OUTER JOIN #ProdReqInfo    AS I ON A.IDX_NO = I.IDX_NO               
         LEFT OUTER JOIN #TempSOSpec     AS D ON D.OrderSeq = C.OrderSeq AND D.OrderSerl = C.OrderSerl       
         LEFT OUTER JOIN _TSLOrderItem   AS G ON G.OrderSeq   = C.OrderSeq                         -- 20101124 ������ �߰�    
                                            AND G.OrderSerl  = C.OrderSerl                        -- 20101124 ������ �߰�    
                                            AND G.CompanySeq = @CompanySeq                        -- 20101124 ������ �߰�    
                                            AND G.OrderSubSerl = 0                                -- �Ǹſɼ��� ����     
         LEFT OUTER JOIN _TSLOrder AS Z ON  Z.CompanySeq = G.CompanySeq     
                                       AND Z.OrderSeq = G.OrderSeq        -- 2011.04.25 �輭�� �߰�    
         LEFT OUTER JOIN _TSLCustItem    AS H WITH(NOLOCK) ON G.ItemSeq = H.ItemSeq            -- 20101124 ������ �߰�    
                                                         AND C.CustSeq     = H.CustSeq            -- 20101124 ������ �߰�    
                                                         AND G.UnitSeq     = H.UnitSeq            -- 20101124 ������ �߰�    
                                                             AND G.CompanySeq  = H.CompanySeq         -- 20101124 ������ �߰�    
         LEFT OUTER JOIN _TDAFactUnit AS ch1 ON ch1.CompanySeq = @CompanySeq     
                  AND ch1.FactUnit = A.FactUnit      
         LEFT OUTEr JOIN _TDASMinor   AS ch2 ON ch2.CompanySeq = @CompanySeq     
                  AND ch2.MajorSeq = 6036             
                  AND ch2.MinorSeq = A.ProgStatus    
         LEFT OUTER JOIN _TDASMinor   AS ch3 ON ch3.CompanySeq = @CompanySeq     
                  AND ch3.MajorSeq = 6041             
                  AND ch3.MinorSeq = A.WorkType  
         LEFT OUTER JOIN _TDACust  AS J ON J.CompanySeq = @CompanySeq
                                       AND J.CustSeq = A.CustSeq  
       WHERE (@ProgStatus = 0     
              OR (@ProgStatus = 6036006 AND A.ProgStatus IN (6036001,6036002,6036003))    
              OR A.ProgStatus = @ProgStatus)    
         AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)    
         AND (@PoNo = '' OR C.PoNo LIKE @PoNo + '%')   
  
  --       AND A.OrderQty > 0    
         --AND  (@GoodItemName      = ''    OR A.GoodItemName       LIKE @GoodItemName + '%')    
         --AND  (@GoodItemNo        = ''    OR A.GoodItemNo         LIKE @GoodItemNo + '%')    
         --AND  (@GoodItemSpec      = ''    OR A.GoodItemSpec           LIKE @GoodItemSpec + '%')    
         --AND  (@ProcName          = ''    OR A.ProcName       LIKE @ProcName + '%')    
         --AND  (@WorkCenterSeq     = 0     OR A.WorkCenterSeq = @WorkCenterSeq)    
      
      ORDER BY A.WorkOrderNo, A.ProcNo    
      
      
  RETURN    
  /**********************************************************************************************************/    
  WorkCenterList:     
      
      
      -- �۾����ú� ��ǰ����, �ҷ�����.    
      
      SELECT R.WorkOrderSeq    
            ,R.WorkOrderSerl    
            ,SUM(OKQty)   AS MadeQty    
            ,SUM(BadQty)  AS ProgBadQty    
        INTO #WorkQty    
        FROM _TPDSFCWorkReport        AS R WITH(NOLOCK)     
       WHERE R.CompanySeq        = @CompanySeq     
         AND EXISTS (SELECT 1 FROM #TPDSFCWorkOrder WHERE WorkOrderSeq = R.WorkOrderSeq AND WorkOrderSerl = R.WorkOrderSerl)    
      GROUP BY R.WorkOrderSeq,R.WorkOrderSerl    
         
        
      SELECT      
             A.*    
             ,ISNULL( ch1.FactUnitName, '')    AS FactUnitName    
             ,ISNULL( ch2.MinorName, '')   AS ProgStatusName    
             ,ISNULL( ch3.MinorName, '')   AS WorkTypeName    
             ,ISNULL(B.MadeQty, 0)             AS MadeQty    
             ,ISNULL(B.ProgBadQty , 0)         AS ProgBadQty    
             ,DATENAME(WEEKDAY, A.WorkDate)    AS WeekDay    
             ,C.PoNo     
             ,A.CustSeq   AS CustSeq    -- 12.05.24 BY �輼ȣ ����
             ,J.CustName  AS CustName   -- 12.05.24 BY �輼ȣ ����              
             ,(SELECT TOP 1 1 FROM _TSLOrderItemSpec WHERE CompanySeq = @CompanySeq AND OrderSeq = C.OrderSeq AND OrderSerl = C.OrderSerl)AS IsSpec  -- 20100121 �ڼҿ� �߰�    
             ,ISNULL(D.SpecName, '')   AS SpecName  -- 20100121 �ڼҿ� �߰�     
             ,ISNULL(D.SpecValue, '') AS SpecValue  -- 20100121 �ڼҿ� �߰�    
      
             ,ISNULL(CASE ISNULL(H.CustItemNo, '')      
                      WHEN '' THEN (SELECT CI.CustItemNo FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = C.CustSeq  AND A.GoodItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)       
                      ELSE H.CustItemNo END, '')  AS  CustItemNo       
             ,ISNULL(CASE ISNULL(H.CustItemName, '')      
                      WHEN '' THEN (SELECT CI.CustItemName FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = C.CustSeq  AND A.GoodItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)       
                      ELSE H.CustItemName END, '') AS  CustItemName      
             ,ISNULL(CASE ISNULL(H.CustItemSpec, '')      
                      WHEN '' THEN (SELECT CI.CustItemSpec FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = C.CustSeq  AND A.GoodItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)       
                      ELSE H.CustItemSpec END, '') AS  CustItemSpec      
             ,A.Remark AS ProdRemark    
             -- 2011.04.25 �輭�� �߰�    
             , CASE ISNULL(I.DelvDate,'') WHEN '' THEN CASE ISNULL(G.DVDate,'') WHEN '' THEN Z.DVDate     
                       ELSE G.DVDate     
                        END     
                ELSE I.DelvDate     
                 END AS DVDate    
         FROM #TPDSFCWorkOrder             AS A    
             LEFT OUTER JOIN #WorkQty        AS B ON A.WorkOrderSeq = B.WorkOrderSeq     
                                              AND A.WorkOrderSerl = B.WorkOrderSerl    
             LEFT OUTER JOIN #SOInfo         AS C ON A.IDX_NO = C.IDX_NO    
             LEFT OUTER JOIN #ProdReqInfo    AS I ON A.IDX_NO = I.IDX_NO    
             LEFT OUTER JOIN #TempSOSpec     AS D ON D.OrderSeq = C.OrderSeq AND D.OrderSerl = C.OrderSerl    
   
           LEFT OUTER JOIN _TSLOrderItem   AS G ON G.OrderSeq   = C.OrderSeq                         -- 20101124 ������ �߰�    
                                                AND G.OrderSerl  = C.OrderSerl                        -- 20101124 ������ �߰�    
                                                ANd G.CompanySeq = @CompanySeq                        -- 20101124 ������ �߰�    
                                                AND G.OrderSubSerl = 0                                -- �Ǹſɼ��� ����     
           LEFT OUTER JOIN _TSLOrder AS Z ON  Z.CompanySeq = G.CompanySeq                            -- 2011.04.25 �輭�� �߰�    
                                               AND Z.OrderSeq = G.OrderSeq    
           LEFT OUTER JOIN _TSLCustItem    AS H WITH(NOLOCK) ON G.ItemSeq = H.ItemSeq            -- 20101124 ������ �߰�    
                                                             AND C.CustSeq     = H.CustSeq            -- 20101124 ������ �߰�    
                          AND G.UnitSeq     = H.UnitSeq            -- 20101124 ������ �߰�    
                                                             AND G.CompanySeq  = H.CompanySeq         -- 20101124 ������ �߰�    
             LEFT OUTER JOIN _TDAFactUnit AS ch1 ON ch1.CompanySeq = @CompanySeq     
                      AND ch1.FactUnit = A.FactUnit      
             LEFT OUTEr JOIN _TDASMinor   AS ch2 ON ch2.CompanySeq = @CompanySeq     
                      AND ch2.MajorSeq = 6036             
                      AND ch2.MinorSeq = A.ProgStatus    
             LEFT OUTEr JOIN _TDASMinor   AS ch3 ON ch3.CompanySeq = @CompanySeq     
                      AND ch3.MajorSeq = 6041             
                      AND ch3.MinorSeq = A.WorkType    
             LEFT OUTER JOIN _TDACust  AS J ON J.CompanySeq = @CompanySeq
                                           AND J.CustSeq = A.CustSeq  
       WHERE (@ProgStatus = 0     
              OR (@ProgStatus = 6036006 AND A.ProgStatus IN (6036001,6036002,6036003))    
              OR A.ProgStatus = @ProgStatus)    
         AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)    
         AND (@PoNo = '' OR C.PoNo LIKE @PoNo + '%')  
   
         --AND  (@WorkCenterSeq     = 0     OR A.WorkCenterSeq = @WorkCenterSeq)    
      
         --AND  (@GoodItemName      = ''    OR A.GoodItemName       LIKE @GoodItemName + '%')    
         --AND  (@GoodItemNo        = ''    OR A.GoodItemNo         LIKE @GoodItemNo + '%')    
         --AND  (@GoodItemSpec      = ''    OR A.GoodItemSpec       LIKE @GoodItemSpec + '%')    
         --AND  (@ProcName          = ''    OR A.ProcName           LIKE @ProcName + '%')    
      
       
          
  RETURN    
 /**********************************************************************************************************/