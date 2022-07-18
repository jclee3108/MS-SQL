IF OBJECT_ID('KPXCM_SPDSFCWorkReportMatQuery') IS NOT NULL 
    DROP PROC KPXCM_SPDSFCWorkReportMatQuery
GO 

-- v2015.09.16 

-- ����ҿ���ȸ�ϴ� ����SP ��ü���� by����õ 

/************************************************************      
 ��  �� - �����������������ȸ      
 �ۼ��� - 2008�� 10�� 22��      
 �ۼ��� - ������      
 ������ - 2010�� 01�� 25�� BY �ڼҿ� :: ����â���� ��� �������� �߰�      
          2010�� 01�� 26�� BY �ڼҿ� :: ������簡�����⿡�� ��ǰ ���� ����      
          2010�� 12�� 13�� BY SYPARK :: ������簡�����⿡�� �����Լ��� ����, �������� �ߺ����� ��ȸ�����ʰ� GROUP BY     
          2012�� 01�� 30�� BY �輼ȣ :: ��Ź����, ���ⱸ�� ��ȸ �߰�     
          2012�� 02�� 14�� BY SYPARK :: �������������ö� �۾����� ��������� �۾����ڷ�   
          2012�� 05�� 08�� BY �輼ȣ :: '������簡������' �ÿ��� ������� ��ȸ�ǵ��� ����           
          2012�� 05�� 17�� BY �輼ȣ :: '�ҿ�������ȸ' �� ��Ź�����ϰ�� ����â���� �ش� ��Źó ���â����� ��ȸ�ǵ��� 
          2012�� 05�� 18�� BY �輼ȣ :: ������ ��ǰ���� �����ö�, â���ڵ�� �ش� ������ ���� â���ڵ�� ���������� ����
          2012�� 05�� 30�� BY �輼ȣ :: ������ ��ǰ���� �����ö�, �����ڵ�� �ش� ������ �����ڵ�� ���������� ����
          2012�� 06�� 05�� BY �輼ȣ :: �ҿ����簡���ö� ��/�ܺ� �ν��� ����ϱ����� IsOut Į�� �������µ�, 
                                        �ش� ��ũ���Ͱ� '��ü����' �̸� '0'���� ���������� (���ην����� ���ǵ���)
          2013�� 10�� 27�� BY ��ǿ� :: ���� ����, ���� ���� ȯ�漳�� ���� �޾ƿͼ� ȯ�漳������ ���� �������orBOM������ ���� ǥ�� �ǵ��� ����
          2014��  7�� 18�� BY ������ :: â��� �߰�
          2015��  2�� 16�� BY ������ :: (������簡������) �� ���Լ��� ���� �� ���ǿ� ����, LotNo �߰�
 ************************************************************/      
 CREATE PROC KPXCM_SPDSFCWorkReportMatQuery    
     @xmlDocument    NVARCHAR(MAX) ,      
     @xmlFlags       INT = 0,      
     @ServiceSeq     INT = 0,      
     @WorkingTag     NVARCHAR(10)= '',      
     @CompanySeq     INT = 1,      
     @LanguageSeq    INT = 1,      
     @UserSeq        INT = 0,      
     @PgmSeq         INT = 0      
       
 AS      
     
      DECLARE @docHandle      INT,        
             @WorkReportSeq  INT,        
             @FactUnit       INT,        
             @CurrDate       NCHAR(8),        
             @WorkDate       NCHAR(8),        
             @StkDate        NCHAR(8),      
             @WorkOrderSeq   INT     ,   -- 11.03.09 �輼ȣ �߰�        
             @WorkOrderSerl  INT         -- 11.03.09 �輼ȣ �߰�        
         
      SELECT @CurrDate = CONVERT(NCHAR(8),GETDATE(),112)        
         
         
     CREATE TABLE #MatNeed_GoodItem        
     (        
         IDX_NO          INT IDENTITY(1,1),        
         ItemSeq         INT,        -- ��ǰ�ڵ�        
         ProcRev         NCHAR(2),   -- �����帧����        
         BOMRev          NCHAR(2),   -- BOM����        
         ProcSeq         INT,        -- �����ڵ�        
         AssyItemSeq     INT,        -- ����ǰ�ڵ�        
         UnitSeq         INT,        -- �����ڵ�     (����ǰ�ڵ尡 ������ ����ǰ�����ڵ�, ������ ��ǰ�����ڵ�)        
         Qty             DECIMAL(19,5),    -- ��ǰ����     (����ǰ�ڵ尡 ������ ����ǰ����)        
         ProdPlanSeq     INT,        -- �����ȹ���ι�ȣ (�����Ƿڿ��� �߰��� �ɼ����縦 ������������)        
         WorkOrderSeq    INT,        -- �۾����ó��ι�ȣ (�۾����ÿ��� �߰������ ��ϵ� ���縦 ������������)        
         WorkOrderSerl   INT,        -- �۾����ó��μ��� (�۾����ÿ��� �߰������ ��ϵ� ���縦 ������������)        
         IsOut           NCHAR(1),   -- �ν��� ���뿡 ��� '1'�̸� OutLossRate ����        
         WorkReportSeq   INT        
     )        
         
     CREATE TABLE #MatNeed_MatItem_Result        
     (        
         IDX_NO          INT,            -- ��ǰ�ڵ�        
         MatItemSeq      INT,            -- �����ڵ�        
         UnitSeq         INT,            -- �������        
         NeedQty         DECIMAL(19,5),  -- �ҿ䷮        
         InputType       INT        
     )        
         
         
         
     CREATE TABLE #NeedMatSUM        
     (        
         ProcSeq         INT,        
         MatItemSeq      INT,        
         UnitSeq         INT,        
         NeedQty         NUMERIC(19,5),        
         InputQty        NUMERIC(19,5),        
         InputType       INT,        
         ItemSeq         INT,        -- ��ǰ�ڵ�        
         BOMRev          NCHAR(2),   -- BOM����        
         AssyItemSeq     INT,        -- ����ǰ�ڵ�        
         BOMSerl         INT        
     )        
         
     -- 20100125 �ڼҿ� �߰�        
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
         
    -- 20100125 �ڼҿ� �߰�        
    CREATE TABLE #GetInOutItem        
    (        
   ItemSeq    INT        
    )        
         
         
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument        
         
         
     SELECT  @WorkReportSeq   = ISNULL(WorkReportSeq    ,0),        
             @FactUnit        = ISNULL(FactUnit         ,0),   -- 20100125 �ڼҿ� �߰�       
             @WorkOrderSeq   = ISNULL(WorkOrderSeq    ,0),     -- 11.03.09 �輼ȣ �߰�       
          @WorkOrderSerl   = ISNULL(WorkOrderSerl    ,0)    -- 11.03.09 �輼ȣ �߰�      
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)        
       WITH (WorkReportSeq    INT,        
             FactUnit         INT,                             -- 20100125 �ڼҿ� �߰�       
             WorkOrderSeq     INT,                             -- 11.03.09 �輼ȣ �߰�      
               WorkOrderSerl    INT)                              -- 11.03.09 �輼ȣ �߰�      
         
         
     SELECT @WorkDate = LEFT(WorkDate,6)+'01' FROM _TPDSFCWorkReport WHERE CompanySeq = @CompanySeq AND WorkReportSeq = @WorkReportSeq        
         
 --�ڡ� ȯ�漳�� ��(�������, ���Դ���) �ҷ�����  
 DECLARE @BaseProdUnit INT  
 EXEC dbo._SCOMEnv @CompanySeq,6259,@UserSeq,@@PROCID,@BaseProdUnit OUTPUT   
       
 --    -- �������� ���� �������� ������� �������� 20100305 �۱⿬        
 --    SELECT @StkDate = CONVERT(NCHAR(8),DATEADD(DD,-1, CONVERT(DATETIME, CONVERT(NCHAR(8),DATEADD(MM,1, CONVERT(DATETIME, @WorkDate)),112))),112)        
           
     -- �������� �������� ������� �������� 20100318 �۱⿬ ���̳ʽ����üũ�� �ش���� �����ڱ����� ���� �����ϱ����� ��� ��� üũ��        
     SELECT @StkDate = @CurrDate        
 --select @WorkDate, @StkDate        
     IF @WorkingTag IN ('','Q')        
         GOTO Qry_MatNeed        
     ELSE IF @WorkingTag = 'S'   -- �ҿ�������ȸ        
         GOTO Qry_MatNeed        
 ELSE IF @WorkingTag = 'G'   -- ������簡������        
         GOTO Qry_GetItem        
         
 RETURN        
 /***************************************************************************************************************/        
 Qry_Proc:   -- ����������ȸ        
      
     DELETE  #GetInOutItem  -- 20100125 �ڼҿ� �߰�        
     DELETE  #GetInOutStock -- 20100125 �ڼҿ� �߰�        
         
     SELECT        
              A.WorkReportSeq        
             ,A.ItemSerl        
             ,A.InputDate        
             ,A.MatItemSeq        
             ,A.MatUnitSeq        
             ,N.NeedQty        
             ,CASE WHEN R.WorkType = 6041010 THEN ABS(A.Qty)        
       WHEN R.WorkType = 6041004 THEN ABS(A.Qty) ELSE A.Qty END AS Qty        
             ,CASE WHEN R.WorkType = 6041010 THEN ABS(A.StdUnitQty)        
       WHEN R.WorkType = 6041004 THEN ABS(A.StdUnitQty) ELSE A.StdUnitQty END AS StdUnitQty        
             ,A.RealLotNo        
             ,A.SerialNoFrom        
             ,A.ProcSeq        
             ,A.AssyYn        
             ,A.IsConsign        
             ,A.GoodItemSeq        
             ,A.InputType        
             ,A.IsPaid        
             ,A.IsPjt        
             ,A.PjtSeq        
             ,A.WBSSeq        
             ,A.Remark        
             ,I.ItemName         AS MatItemName        
             ,I.ItemNo           AS MatItemNo        
             ,I.Spec             AS MatItemSpec        
             ,U.UnitName         AS MatUnitName        
             ,W.FieldWHSeq       AS WHSeq  
             ,Z.AssetName  AS AssetName
             ,WH.WHName    AS WHName       --20140718 ������ �߰�
       INTO  #TEM_MatinputInfo  -- 20100125 �ڼҿ� �߰�        
       FROM  _TPDSFCMatinput                AS A WITH(NOLOCK)        
         LEFT  OUTER JOIN _TDAItem           AS I WITH(NOLOCK) ON A.CompanySeq    = I.CompanySeq        
                                                             AND A.MatItemSeq    = I.ItemSeq        
         LEFT OUTER JOIN _TDAUnit           AS U WITH(NOLOCK) ON A.CompanySeq    = U.CompanySeq        
                                                   AND A.MatUnitSeq    = U.UnitSeq        
         LEFT OUTER JOIN #NeedMatSUM        AS N              ON A.MatItemSeq    = N.MatItemSeq  
                                                             --AND A.ProcSeq       = N.ProcSeq  
         LEFT OUTER JOIN _TPDSFCWorkReport  AS R WITH(NOLOCK) ON A.CompanySeq    = R.CompanySeq        
                                                             AND A.WorkReportSeq = R.WorkReportSeq        
         LEFT OUTER JOIN _TPDBaseWorkCenter AS W WITH(NOLOCK) ON R.CompanySeq    = W.CompanySeq        
                                                             AND R.WorkcenterSeq = W.WorkcenterSeq
         LEFT OUTER JOIN _TDAWH             AS WH WITH(NOLOCK) ON W.CompanySeq = WH.CompanySeq   
                                                             AND W.FieldWhSeq = WH.WHSeq               --20140718 ������ �߰�                                             
         LEFT OUTER JOIN _TDAItemAsset    AS Z WITH(NOLOCK) ON I.CompanySeq    = Z.CompanySeq  
                AND I.AssetSeq      = Z.AssetSeq      
      WHERE  A.CompanySeq  = @CompanySeq        
        AND  A.WorkReportSeq   = @WorkReportSeq        
      ORDER BY N.BOMSerl, MatItemNo        
         
  ---����â�� ��� ������������ Item��� 20100125 �ڼҿ� �߰�        
     INSERT INTO #GetInOutItem        
     SELECT MatItemSeq        
       FROM #TEM_MatinputInfo        
      GROUP BY MatItemSeq        
         
    /**************����â����������� 20100125 �ڼҿ� �߰�**********************************************/        
         
       EXEC _SLGGetInOutStock        
            @CompanySeq    = @CompanySeq, -- �����ڵ�        
            @BizUnit       = 0,           -- ����ι�        
            @FactUnit      = @FactUnit,   -- ��������        
            @DateFr        = @StkDate,   -- ��ȸ�ⰣFr        
            @DateTo        = @StkDate,   -- ��ȸ�ⰣTo         
            @WHSeq         = 0,           -- â������        
            @SMWHKind      = 0,           -- â���к� ��ȸ        
            @CustSeq       = 0,           -- ��Ź�ŷ�ó        
            @IsSubDisplay  = '',          -- ���â�� ��ȸ        
            @IsUnitQry      = '',          -- ������ ��ȸ        
            @QryType       = 'S'          -- 'S': 1007 �����, 'B':1008 �ڻ�����, 'A':1011 �������        
         
  /**************����â����������� ��**************************************************************/        
     
     SELECT   A.*        
             ,ISNULL(B.STDStockQty, 0) AS STDStockQty -- 20100125 �ڼҿ� �߰�        
             ,M.MinorName              AS SMOutKind   -- 12.01.30 �輼ȣ �߰�     
             ,ISNULL(ST.IsLotMng,'')   AS IsLotMng  
       FROM #TEM_MatinputInfo AS A        
            LEFT OUTER JOIN #GetInOutStock  AS B  ON A.MatItemSeq = B.ItemSeq   
                                                 AND A.WHSeq      = B.WHSeq  -- 20100125 �ڼҿ� �߰�       
            LEFT OUTER JOIN _TDAItemProduct AS P  WITH(NOLOCK) ON @CompanySeq   = P.CompanySeq    
                                                               AND A.MatItemSeq = P.ItemSeq     
            LEFT OUTER JOIN _TDASMinor      AS M  WITH(NOLOCK) ON P.CompanySeq  = M.CompanySeq    
                                                               AND P.SMOutKind  = M.MinorSeq  
            LEFT OUTER JOIN _TDAItemStock   AS ST WITH(NOLOCK) ON @CompanySeq   = ST.CompanySeq  
                                                              AND A.MatItemSeq  = ST.ItemSeq              
         
 RETURN        
 /***************************************************************************************************************/        
 Qry_MatNeed:   -- �ҿ�������ȸ        
   
     DECLARE @InputDate      NCHAR(8),        
 --            @WorkOrderSeq   INT,        
             @GoodItemSeq    INT,        
             @IsPjt          NCHAR(1),        
             @AssyYn         NCHAR(1),        
             @PjtSeq         INT,        
             @WBSSeq         INT,        
             @ExistsYn       NCHAR(1),        
             @FieldWHSeq     INT,
             @WHName         NVARCHAR(100)        
         
     SELECT  @WorkOrderSeq    = W.WorkOrderSeq        
            ,@GoodItemSeq     = W.GoodItemSeq        
            ,@InputDate       = W.WorkDate        
            ,@AssyYn          = CASE WHEN W.GoodItemSeq = W.AssyItemSeq THEN '0'        
                                       WHEN W.IsLastProc  = '1'            THEN '0'        
                                     ELSE '1'        
                                END      -- ����ǰ����        
            ,@IsPjt           = W.IsPjt        
            ,@PjtSeq          = W.PjtSeq        
            ,@WBSSeq          = W.WBSSeq        
       FROM _TPDSFCWorkReport        AS W        
      WHERE W.CompanySeq  = @CompanySeq        
        AND W.WorkReportSeq = @WorkReportSeq        
         
     SELECT @ExistsYn = '1'        
       FROM _TPDSFCMatinput  WITH(NOLOCK)        
      WHERE CompanySeq  = @CompanySeq        
        AND WorkReportSeq = @WorkReportSeq        
         
     SELECT @ExistsYn  = ISNULL(@ExistsYn, '0')        
   
   
     -- �ҿ䷮��� �� ���� ǰ����.        
     INSERT #MatNeed_GoodItem (ItemSeq,ProcRev,BOMRev,ProcSeq,AssyItemSeq,UnitSeq,Qty,ProdPlanSeq,WorkOrderSeq,WorkOrderSerl,IsOut,WorkReportSeq)        
     SELECT W.GoodItemSeq, W.ProcRev, W.ItemBomRev, W.ProcSeq, W.AssyItemSeq, W.ProdUnitSeq,        
            --W.ProdQty * (CASE WHEN W.WorkType = 6041004 THEN (-1) ELSE 1 END),  -- ��ü(���)�۾��̸� (-),        
            W.ProdQty,   -- ����� ��ȸ�ǰ� ����ÿ��� ������ ����ǰ� �ϱ� ���ؼ� ���� 2010. 7. 15 hkim        
            O.ProdPlanSeq, W.WorkOrderSeq, W.WorkOrderSerl,      -- ProdPlanSeq�� ���� 0�̾����� �۾������� ProdPlanSeq ���������� ���� 2012. 5. 21 hkim  
            CASE WHEN C.SMWorkCenterType = 6011003 THEN '1' ELSE '0' END , WorkReportSeq        
       FROM _TPDSFCWorkReport     AS W        
            JOIN _TPDBaseWorkCenter AS C ON W.CompanySeq    = C.CompanySeq        
                                        AND W.WorkCenterSeq = C.WorkCenterSeq      
      LEFT OUTER JOIN _TPDSFCWorkOrder AS O ON W.CompanySeq = O.CompanySeq   -- ����ɼ�ǰ ������ ���� �߰� 2012. 5. 21 hkim  
             AND W.WorkOrderSeq = O.WorkOrderSeq  
             AND W.WorkOrderSerl = O.WorkOrderSerl                                           
      WHERE W.CompanySeq    = @CompanySeq        
        AND W.WorkReportSeq = @WorkReportSeq        
         
     -- �ҿ����� ��������        
       EXEC KPXCM_SPDMMGetItemNeedQty @CompanySeq         
         
     
     -------------------------------        
     -- �ҿ䷮ ���� ----------------        
     INSERT #NeedMatSUM (ProcSeq,MatItemSeq,UnitSeq,NeedQty,InputQty,InputType, ItemSeq, BOMRev, AssyItemSeq,BOMSerl) -- �ҿ䷮        
     SELECT A.ProcSeq, B.MatItemSeq, B.UnitSeq, B.NeedQty, B.NeedQty, B.InputType, A.ItemSeq, A.BOMRev, A.AssyItemSeq, 9999        
       FROM #MatNeed_GoodItem            AS A        
            JOIN #MatNeed_MatItem_Result AS B ON A.IDX_NO = B.IDX_NO        
      
    DECLARE @BomLevel INT        
     SELECT @BomLevel = 1        
         
     SELECT ItemSeq, BOMRev, ItemSeq AS SubItemSeq, BOMRev AS SubBOMRev, @BomLevel AS BOMLevel, 0 AS UserSeq        
       INTO #BOM        
       FROM #NeedMatSUM        
   
   
   
     WHILE(1=1)        
     BEGIN        
         
         SELECT @BomLevel = @BomLevel + 1        
         
         INSERT #BOM        
         SELECT A.ItemSeq, A.ItemBomRev, A.SubItemSeq, A.SubItemBomRev, @BomLevel, A.UserSeq        
           FROM _TPDBOM     AS A        
                JOIN #BOM   AS B ON A.ItemSeq = B.SubItemSeq        
                                AND A.ItemBomRev  = B.SubBOMRev        
            WHERE A.CompanySeq = @CompanySeq        
            AND B.BOMLevel = @BomLevel - 1        
  
         IF @@ROWCOUNT = 0        
             BREAK        
         
     END        
     
      -- BOM����ǥ��        
     UPDATE A        
        SET BOMSerl = UserSeq        
       FROM #NeedMatSUM      AS A        
            JOIN #BOM        AS B WITH(NOLOCK) ON A.AssyItemSeq = B.ItemSeq        
                                              AND A.MatItemSeq  = B.SubItemSeq        
      WHERE B.UserSeq > 0        
         
     -----------------------------------        
     IF @WorkingTag IN ('','Q')        
         GOTO Qry_Proc        
     -----------------------------------        
       
         
     -- �����Ե� ��������ݿ�        
         
     UPDATE #NeedMatSUM        
        SET InputQty = A.InputQty - B.Qty        
         FROM #NeedMatSUM               AS A        
         JOIN (SELECT MatItemSeq, SUM(Qty) AS Qty        
                 FROM _TPDSFCMatinput WITH(NOLOCK)        
                WHERE CompanySeq     = @CompanySeq        
                  AND WorkReportSeq  = @WorkReportSeq        
                GROUP BY MatItemSeq) AS B ON A.MatItemSeq = B.MatItemSeq        
      -- ����â�� ��������       
     SELECT @FieldWHSeq = B.FieldWHSeq,
            @WHName     = W.WHName                 --20140718 ������ �߰�
       FROM _TPDSFCWorkReport                  AS A WITH(NOLOCK)        
            LEFT OUTER JOIN _TPDBaseWorkCenter AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq        
                                                                AND A.WorkcenterSeq = B.WorkcenterSeq
            LEFT OUTER JOIN _TDAWH             AS W WITH(NOLOCK) ON @CompanySeq = W.CompanySeq   
                                                                AND B.FieldWhSeq = W.WHSeq            --20140718 ������ �߰�                                                                                          
      WHERE A.CompanySeq    = @CompanySeq        
        AND A.WorkReportSeq = @WorkReportSeq        
   
     DELETE #GetInOutItem  -- 20100125 �ڼҿ� �߰�        
     DELETE #GetInOutStock -- 20100125 �ڼҿ� �߰�        
         
   ---����â�� ��� ������������ Item��� 20100125 �ڼҿ� �߰�        
     INSERT INTO #GetInOutItem        
     SELECT MatItemSeq        
       FROM #NeedMatSUM        
      GROUP BY MatItemSeq        
         
   
     ALTER TABLE #NeedMatSUM ADD STDStockQty DECIMAL (19, 5) -- ����â�� ���  
   
 /**************����â����������� 20100125 �ڼҿ� �߰�**********************************************/        
         
       EXEC _SLGGetInOutStock        
            @CompanySeq    = @CompanySeq, -- �����ڵ�        
            @BizUnit       = 0,           -- ����ι�        
            @FactUnit      = @FactUnit,   -- ��������        
            @DateFr        = @StkDate,   -- ��ȸ�ⰣFr        
            @DateTo        = @StkDate,   -- ��ȸ�ⰣTo        
            @WHSeq         = @FieldWHSeq, -- â������        
            @SMWHKind      = 0,           -- â���к� ��ȸ        
            @CustSeq       = 0,           -- ��Ź�ŷ�ó        
            @IsSubDisplay  = '',          -- ���â�� ��ȸ        
            @IsUnitQry     = '',          -- ������ ��ȸ        
            @QryType       = 'S'          -- 'S': 1007 �����, 'B':1008 �ڻ�����, 'A':1011 �������        
         
   
     UPDATE N  
        SET STDStockQty = ISNULL(V.STDStockQty, 0)  
       FROM #NeedMatSUM          AS N             
         LEFT OUTER JOIN #GetInOutStock  AS V WITH(NOLOCK) ON N.MatItemSeq   = V.ItemSeq  -- 20100125 �ڼҿ� �߰�        
                                                          AND V.WHSeq        = @FieldWHSeq    
   
  /**************����â����������� ��**************************************************************/        
       
   
   
 /**************����â���� ��Źâ�� ��� �������� 20120517 �輼ȣ �߰�**********************************************/        
     IF EXISTS(SELECT 1 FROM #NeedMatSUM WHERE InputType = 6042003)  
      BEGIN  
         DELETE #GetInOutStock   
   
         DECLARE @CustSeq    INT  
         SELECT @CustSeq = (SELECT ISNULL(CustSeq, 0) FROM _TPDSFCWorkReport WHERE WorkReportSeq = @WorkReportSeq AND CompanySeq = @CompanySeq)  
   
   
          EXEC _SLGGetInOutStock  @CompanySeq   = @CompanySeq,   -- �����ڵ�  
                                  @BizUnit      = 0,             -- ����ι�  
                                  @FactUnit     = @FactUnit,     -- ��������  
                                  @DateFr       = @StkDate,      -- ��ȸ�ⰣFr  
                                  @DateTo       = @StkDate,      -- ��ȸ�ⰣTo  
                                  @WHSeq        = @FieldWHSeq,   -- â������  
                                  @SMWHKind     = 0,             -- â���к� ��ȸ  
                                  @CustSeq      = @CustSeq,      -- ��Ź�ŷ�ó  
                                  @IsTrustCust  = '1',           -- ��Ź����  
                                  @IsSubDisplay = '1',           -- ���â�� ��ȸ  
                                  @IsUnitQry    = '' ,           -- ������ ��ȸ  
                                  @QryType      = ''            -- 'S': 1007 �����, 'B':1008 �ڻ�����, 'A':1011 �������  
   
         UPDATE N  
            SET STDStockQty = ISNULL(V.STDStockQty, 0)  
           FROM #NeedMatSUM          AS N             
             LEFT OUTER JOIN #GetInOutStock  AS V WITH(NOLOCK) ON N.MatItemSeq   = V.ItemSeq  -- 20100125 �ڼҿ� �߰�        
                                                  AND V.WHSeq        = @FieldWHSeq    
          WHERE N.InputType = 6042003  
      END  
  /**************����â���� ��Źâ�� ��� ��������  ��**************************************************************/        
   
     SELECT          
              @WorkReportSeq     AS WorkReportSeq          
             ,@InputDate         AS InputDate          
             ,N.MatItemSeq       AS MatItemSeq   
             ,CASE WHEN @BaseProdUnit = 6105001 THEN N.UnitSeq ELSE DU.STDUnitSeq END AS MatUnitSeq  
             ,CASE WHEN @BaseProdUnit = 6105001 THEN N.NeedQty ELSE N.NeedQty * (US.ConvNum / US.ConvDen) / (UP.ConvNum / UP.ConvDen) END AS NeedQty  
             ,CASE WHEN @BaseProdUnit = 6105001 THEN N.InputQty ELSE N.InputQty * (US.ConvNum / US.ConvDen) / (UP.ConvNum / UP.ConvDen) END AS Qty  
             --,N.UnitSeq          AS MatUnitSeq  
             --,N.NeedQty          AS NeedQty  
             --,N.InputQty         AS Qty  
             ,N.ProcSeq          AS ProcSeq          
             ,@AssyYn            AS AssyYn          
             ,@GoodItemSeq       AS GoodItemSeq          
             ,InputType          AS InputType          
             ,@IsPjt             AS IsPjt          
             ,@PjtSeq            AS PjtSeq          
             ,@WBSSeq            AS WBSSeq          
             ,I.ItemName         AS MatItemName          
             ,I.ItemNo           AS MatItemNo          
             ,I.Spec             AS MatItemSpec          
             ,CASE WHEN @BaseProdUnit = 6105001 THEN U.UnitName ELSE Z.UnitName END AS MatUnitName  
             --,U.UnitName         AS MatUnitName  
             ,@ExistsYn          AS ExistsYn          
             ,@FieldWHSeq        AS WHSeq          
             ,CASE WHEN @BaseProdUnit = 6105001 THEN ISNULL((N.InputQty * (SELECT ConvNum / ConvDen          
                                                                             FROM _TDAItemUnit          
                                                                            WHERE CompanySeq = @CompanySeq          
                                                                              AND ItemSeq = N.MatItemSeq          
                                                                              AND UnitSeq = N.UnitSeq          
                                  AND ConvDen <> 0 )),0 )   
                                                ELSE ISNULL((N.InputQty * (US.ConvNum / US.ConvDen) / (UP.ConvNum / UP.ConvDen) * (SELECT ConvNum / ConvDen          
                                                                                                                                     FROM _TDAItemUnit          
           WHERE CompanySeq = @CompanySeq          
                                                                                                                                      AND ItemSeq = N.MatItemSeq          
                                                                                                                                      AND UnitSeq = DU.STDUnitSeq          
                                                                                                                                      AND ConvDen <> 0 )),0 ) END   AS StdUnitQty          
             ,N.STDStockQty      AS STDStockQty -- 20100125 �ڼҿ� �߰�  
             ,M.MinorName        AS SMOutKind                                    -- 12.01.30 �輼ȣ �߰�  
             ,CASE N.InputType WHEN 6042003 THEN '1' ELSE '0' END  AS IsConsign  -- 12.01.30 �輼ȣ �߰�  
             ,ISNULL(ST.IsLotMng,'') AS IsLotMng
             ,@WHName            AS WHName                                         --20140718 ������ �߰�
       FROM #NeedMatSUM          AS N          
         LEFT OUTER JOIN _TDAItem        AS I WITH(NOLOCK) ON N.MatItemSeq   = I.ItemSeq                
         LEFT OUTER JOIN _TDAUnit        AS U WITH(NOLOCK) ON I.CompanySeq   = U.CompanySeq          
                                 AND N.UnitSeq      = U.UnitSeq              
         LEFT OUTER JOIN _TDAItemProduct AS P WITH(NOLOCK) ON I.CompanySeq   = P.CompanySeq      
                                                          AND I.ItemSeq      = P.ItemSeq       
         LEFT OUTER JOIN _TDASMinor      AS M WITH(NOLOCK) ON P.CompanySeq   = M.CompanySeq      
                                                          AND P.SMOutKind    = M.MinorSeq   
          LEFT OUTER JOIN _TDAItemDefUnit AS DU ON @CompanySeq = DU.CompanySeq  
                                         AND N.MatItemSeq = DU.ItemSeq  
                                         AND DU.UMModuleSeq = 1003004  
         LEFT OUTER JOIN _TDAUnit        AS Z WITH(NOLOCK) ON Z.CompanySeq   = DU.CompanySeq          
                                                          AND Z.UnitSeq      = DU.STDUnitSeq  
         LEFT OUTER JOIN _TDAItemUnit       AS US WITH(NOLOCK)  ON @CompanySeq = US.CompanySeq  
                                                               AND N.MatItemSeq = US.ItemSeq          
                                                               AND N.UnitSeq    = US.UnitSeq          
         LEFT OUTER JOIN _TDAItemUnit       AS UP WITH(NOLOCK)  ON @CompanySeq = UP.CompanySeq  
                                                               AND N.MatItemSeq = UP.ItemSeq          
                                                               AND DU.STDUnitSeq = UP.UnitSeq          
         LEFT OUTER JOIN _TDAItemStock      AS ST WITH(NOLOCK) ON @CompanySeq = ST.CompanySeq  
                                                              AND N.MatItemSeq = ST.ItemSeq  
      WHERE I.CompanySeq  = @CompanySeq          
        AND N.InputQty <> 0          
      ORDER BY N.BOMSerl, MatItemNo        
   
         
 RETURN        
 /***************************************************************************************************************/        
 Qry_GetItem:   -- ������簡������        
         
     SELECT        
              R.WorkReportSeq        
             ,R.WorkDate         AS InputDate        
             ,O.ItemSeq          AS MatItemSeq        
             ,O.UnitSeq          AS MatUnitSeq      
             ,SUM(O.Qty)         AS Qty        
             ,R.ProcSeq          AS ProcSeq        
             ,CASE WHEN R.IsLastProc = '1' THEN '0'        
                   ELSE '1'        
              END                AS AssyYn        
             ,R.GoodItemSeq      AS GoodItemSeq        
             ,CASE WHEN ISNULL(O.ConsgnmtCustSeq,0) = 0 THEN 6042002 ELSE 6042003 END AS InputType -- ��Ź������ ��� ���Ա��� ��Ź���� ���� �۱⿬ 201010616        
             ,R.IsPjt        
             ,R.PjtSeq        
             ,R.WBSSeq        
             ,I.ItemName         AS MatItemName        
             ,I.ItemNo           AS MatItemNo        
             ,I.Spec             AS MatItemSpec        
             ,U.UnitName         AS MatUnitName        
             ,''                 AS MatOutNo        
             ,0                  AS MatOutSeq        
             ,O.ItemLotNo  AS RealLotNo        
             ,WC.FieldWHSeq      AS WHSeq        
             ,W.ProcNo           AS ProcNo        
             ,O.WorkOrderSeq     AS WorkOrderSeq        
             ,O.WorkOrderSerl    AS WorkOrderSerl
             ,WH.WHName          AS WHName
       INTO #OutItem       
       FROM _TPDMMOutItem        AS O        
           JOIN _TPDMMOutM         AS M ON O.CompanySeq    = M.CompanySeq        
                                     AND O.MatOutSeq     = M.MatOutSeq        
         JOIN _TPDSFCWorkReport  AS R ON O.CompanySeq    = R.CompanySeq        
                                     AND O.WorkOrderSeq  = R.WorkOrderSeq        
                                     AND O.WorkOrderSerl = R.WorkOrderSerl        
         JOIN _TPDSFCWorkOrder   AS W ON O.CompanySeq    = W.CompanySeq        
                                     AND O.WorkOrderSeq  = W.WorkOrderSeq        
                                     AND O.WorkOrderSerl = W.WorkOrderSerl        
         JOIN _TDAItem            AS I ON O.CompanySeq    = I.CompanySeq        
                                     AND O.ItemSeq       = I.ItemSeq        
         JOIN _TDAUnit           AS U ON O.CompanySeq    = U.CompanySeq        
                                     AND O.UnitSeq       = U.UnitSeq        
         LEFT OUTER JOIN _TPDBaseWorkcenter AS WC ON W.CompanySeq    = WC.CompanySeq        
                                                 AND W.WorkcenterSeq = WC.WorkcenterSeq
         LEFT OUTER JOIN _TDAWH             AS WH WITH(NOLOCK) ON WC.CompanySeq = WH.CompanySeq   
                                                              AND WC.FieldWhSeq = WH.WHSeq                --20140718 ������ �߰�                                                                                          
      WHERE O.CompanySeq     = @CompanySeq        
        AND R.WorkReportSeq  = @WorkReportSeq        
        AND M.UseType        NOT IN (6044006, 6044007) -- 20100126 �ڼҿ� ���� ��ǰ�� ����        
      GROUP BY R.WorkReportSeq, R.WorkDate, O.ItemSeq, O.UnitSeq, R.ProcSeq, R.IsLastProc, R.GoodItemSeq, O.ConsgnmtCustSeq, R.IsPjt, R.PjtSeq, R.WBSSeq ,        
               I.ItemName, I.ItemNo, I.Spec, U.UnitName, O.ItemLotNo, WC.FieldWHSeq, W.ProcNo, O.WorkOrderSeq,O.WorkOrderSerl ,WH.WHName       
       
     
 ------------------------------------------------------------------------------------------    
     -- ����â���� �����ǰ�� �ִ� ��� �� ���� ��ŭ ���� ���翡�� �������ش�.        
 ------------------------------------------------------------------------------------------    
     SELECT B.ItemSeq, B.UnitSeq, B.ItemLotNo, SUM(B.Qty) AS Qty        
       INTO #OutItemReturn        
       FROM _TPDSFCWorkReport AS A WITH(NOLOCK)        
            INNER JOIN _TPDMMOutItem AS B WITH(NOLOCK)        
                    ON B.WorkOrderSeq    = A.WorkOrderSeq        
                   AND B.WorkOrderSerl   = A.WorkOrderSerl        
                   AND B.CompanySeq      = A.CompanySeq        
                     AND EXISTS (        
                                 SELECT *        
                           FROM #OutItem        
                                  WHERE MatItemSeq   = B.ItemSeq        
                                    AND RealLotNo    = B.ItemLotNo        
                             )        
            INNER JOIN _TPDMMOutM AS C WITH(NOLOCK)        
                    ON C.MatOutSeq       = B.MatOutSeq        
                   AND C.CompanySeq      = B.CompanySeq        
                   AND C.UseType         IN (6044007, 6044010)   -- �����ǰ        
      WHERE A.WorkReportSeq  = @WorkReportSeq        
        AND A.CompanySeq     = @CompanySeq        
      GROUP BY B.ItemSeq, B.UnitSeq, B.ItemLotNo        
         
         
     UPDATE #OutItem        
        SET Qty  = A.Qty - B.Qty        
       FROM #OutItem AS A        
            INNER JOIN #OutItemReturn AS B        
                    ON B.ItemSeq     = A.MatItemSeq        
                   AND B.UnitSeq     = A.MatUnitSeq         
                   AND B.ItemLotNo   = A.RealLotNo              
 ------------------------------------------------------------------------------------------       
         
         
     SELECT A.MatItemSeq, A.MatUnitSeq, A.RealLotNo, SUM(A.Qty) AS Qty        
       INTO #Input        
       FROM _TPDSFCMatInput          AS A WITH(NOLOCK)        
      WHERE A.CompanySeq         = @CompanySeq        
        AND EXISTS(SELECT 1 FROM _TPDSFCWorkReport   AS R WITH(NOLOCK)        
                             JOIN #OutItem           AS I ON R.WorkOrderSeq = I.WorkOrderSeq        
                                                         AND R.WorkOrderSerl = I.WorkOrderSerl        
                           WHERE R.CompanySeq = @CompanySeq        
                             AND R.WorkReportSeq = A.WorkReportSeq     )        
      GROUP BY A.MatItemSeq, A.MatUnitSeq, A.RealLotNo                                --2015.02.16 ������ ����        
         
         
   ------------------------------------------------------------------------------------------        
     -- �� ���Ե� ������� ����.        
 ------------------------------------------------------------------------------------------    
     UPDATE A        
        SET Qty  = A.Qty - ISNULL(B.Qty,0)        
       FROM #OutItem             AS A        
         JOIN #Input             AS B ON A.MatItemSeq  = B.MatItemSeq
                                     AND A.MatUnitSeq  = B.MatUnitSeq        
                                     AND A.RealLotNo   = B.RealLotNo                  --2015.02.16 ������ ���� 
     
 ------------------------------------------------------------------------------------------    
     
      
   ------------------------------------------------------------------------------------------        
  --==== ������ ����ǰ �������� ----===                    -- 11.03.09 �輼ȣ �߰�      
  ------------------------------------------------------------------------------------------    
      
     DECLARE @EnvValue   NVARCHAR(100)   -- 6217           
     EXEC dbo._SCOMEnv @CompanySeq,6217,@UserSeq,@@PROCID,@EnvValue OUTPUT        
         
   IF  (@EnvValue IN ('1','True')  AND @WorkReportSeq <> 0 )          
      BEGIN      
       
        INSERT             
        INTO #OutItem      
         SELECT       
   
                  @WorkReportSeq      
                 ,(SELECT WorkDate FROM _TPDSFCWorkReport WHERE CompanySeq = @CompanySeq AND WorkReportSeq = @WorkReportSeq) AS InputDate      
                 ,I.ItemSeq          AS MatItemSeq      
                 ,U.UnitSeq          AS MatUnitSeq      
                 ,R.OKQty            AS Qty      
                  --������ ��ǰ���� �����ö�, �����ڵ�� �ش� ������ �����ڵ�� ���������� ���� -- 12.05.30   BY �輼ȣ  
                 ,(SELECT ProcSeq FROM _TPDSFCWorkReport WHERE CompanySeq = @CompanySeq AND WorkReportSeq = @WorkReportSeq) AS ProcSeq   
                 ,CASE WHEN R.IsLastProc = '1' THEN '0'      
                       ELSE '1'      
                  END                AS AssyYn      
        ,R.GoodItemSeq      AS GoodItemSeq      
                 ,6042002            AS InputType       
                 ,R.IsPjt      
                 ,R.PjtSeq      
                 ,R.WBSSeq      
                 ,I.ItemName         AS MatItemName      
                 ,I.ItemNo           AS MatItemNo      
                 ,I.Spec             AS MatItemSpec      
                 ,U.UnitName         AS MatUnitName      
                 ,''                 AS MatOutNo      
                 ,0                  AS MatOutSeq      
                 ,R.RealLotNo        AS RealLotNo      
                 -- ������ ��ǰ���� �����ö�, â���ڵ�� �ش� ������ ���� â���ڵ�� ���������� ����         -- 12.05.18 BY �輼ȣ  
                 ,(SELECT FieldWhSeq FROM _TPDSFCWorkReport WHERE CompanySeq = @CompanySeq AND WorkReportSeq = @WorkReportSeq)   AS WHSeq      
                 ,W.ProcNo           AS ProcNo      
                 ,W.WorkOrderSeq     AS WorkOrderSeq      
                 ,W.WorkOrderSerl    AS WorkOrderSerl      
                 ,WH.WHName          AS WHName
           FROM   _TPDSFCWorkReport  AS R       
             JOIN _TPDSFCWorkOrder   AS W ON R.WorkOrderSeq  = W.WorkOrderSeq      
                                         AND R.WorkOrderSerl = W.WorkOrderSerl      
                                         AND R.CompanySeq    = W.CompanySeq      -- ���� ���� �߰�   12.10.29 BY �輼ȣ  
             JOIN _TDAItem           AS I ON R.CompanySeq    = I.CompanySeq      
                                         AND W.AssyItemSeq       = I.ItemSeq      
             JOIN _TDAUnit           AS U ON R.CompanySeq    = U.CompanySeq      
                                         AND I.UnitSeq       = U.UnitSeq      
             JOIN _TDAWH             AS WH ON R.CompanySeq = WH.CompanySeq
                                          AND R.FieldWhSeq = WH.WHSeq
          WHERE R.CompanySeq     = @CompanySeq      
            AND W.WorkOrderSeq   = @WorkOrderSeq      
            AND W.IsLastProc     <> 1      
            AND W.ToProcNo IN (SELECT A.ProcNo      
                                    FROM _TPDSFCWorkOrder   AS A      
                                     WHERE  @CompanySeq    = A.CompanySeq      
                                        AND @WorkOrderSeq   = A.WorkOrderSeq      
                                        AND @WorkOrderSerl  = A.WorkOrderSerl)      
       
        END        
 ------------------------------------------------------------------------------------------------------------    
      -- ����â�� ��������    -- 12.05.08 �輼ȣ �߰�          
     SELECT @FieldWHSeq = B.FieldWHSeq
           
       FROM _TPDSFCWorkReport                  AS A WITH(NOLOCK)        
            LEFT OUTER JOIN _TPDBaseWorkCenter AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq        
                                                                AND A.WorkcenterSeq = B.WorkcenterSeq
                                                                                           
      WHERE A.CompanySeq    = @CompanySeq        
        AND A.WorkReportSeq = @WorkReportSeq  
        
     DELETE #GetInOutItem  -- 20100125 �ڼҿ� �߰�        
     DELETE #GetInOutStock -- 20100125 �ڼҿ� �߰�        
         
     ---����â�� ��� ������������ Item��� 20100125 �ڼҿ� �߰�        
     INSERT INTO #GetInOutItem        
     SELECT DISTINCT MatItemSeq        
       FROM #OutItem        
      GROUP BY MatItemSeq        
         
     
     /**************����â����������� 20100125 �ڼҿ� �߰�**********************************************/        
         
       EXEC _SLGGetInOutStock        
            @CompanySeq    = @CompanySeq, -- �����ڵ�        
            @BizUnit       = 0,           -- ����ι�        
            @FactUnit      = @FactUnit,   -- ��������        
            @DateFr        = @StkDate,   -- ��ȸ�ⰣFr        
            @DateTo        = @StkDate,   -- ��ȸ�ⰣTo        
            @WHSeq         = @FieldWHSeq, -- â������        
            @SMWHKind      = 0,                 -- â���к� ��ȸ(8002002 : ����â��)     
            @CustSeq       = 0,           -- ��Ź�ŷ�ó        
            @IsSubDisplay  = '',          -- ���â�� ��ȸ        
            @IsUnitQry     = '',          -- ������ ��ȸ        
            @QryType       = 'S'          -- 'S': 1007 �����, 'B':1008 �ڻ�����, 'A':1011 �������        
         
     /**************����â����������� ��**************************************************************/        
     
   --select * from #GetInOutStock  
     
     DECLARE @MatItemPoint INT  
       
     ---- ����/���� �Ҽ��� �ڸ��� �������� ---- 2014.07.17 ����� �߰�  
     EXEC dbo._SCOMEnv @CompanySeq,5,@UserSeq,@@PROCID,@MatItemPoint OUTPUT    
     
     SELECT A.*,        
            (CASE WHEN V.SMDecPointSeq = 1003001 THEN ROUND(A.Qty * (CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END ), @MatItemPoint, 0)   -- �ݿø�      
                  WHEN V.SMDecPointSeq = 1003002 THEN ROUND(A.Qty * (CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END ), @MatItemPoint, -1)  -- ����      
                  WHEN V.SMDecPointSeq = 1003003 THEN ROUND((CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END ) * A.Qty + CAST(4 AS DECIMAL(19, 5)) / POWER(10,(@MatItemPoint + 1)), @MatItemPoint)   -- �ø�      
                  ELSE ROUND(A.Qty * (CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END ), @MatItemPoint, 0) END) -- 2014.07.17 ����� �������� ������ �������� ����  
            AS StdUnitQty,      
                                    
            ISNULL(B.STDStockQty, 0) AS STDStockQty -- 20100125 �ڼҿ� �߰�    
              
             ,M.MinorName        AS SMOutKind                        -- 12.01.30 �輼ȣ �߰�     
             ,CASE A.InputType WHEN 6042003 THEN '1' ELSE '0' END  AS IsConsign          -- 12.01.30 �輼ȣ �߰�     
             ,ISNULL(ST.IsLotMng,'') AS IsLotMng
            
       FROM #OutItem     AS A        
             LEFT OUTER JOIN #GetInOutStock AS B ON A.MatItemSeq = B.ItemSeq AND A.WHSeq = B.WHSeq       
             LEFT OUTER JOIN _TDAItemProduct AS P WITH(NOLOCK) ON @CompanySeq   = P.CompanySeq    
                                                              AND A.MatItemSeq      = P.ItemSeq     
             LEFT OUTER JOIN _TDASMinor      AS M WITH(NOLOCK) ON P.CompanySeq   = M.CompanySeq    
                                                              AND P.SMOutKind    = M.MinorSeq  
             LEFT OUTER JOIN _TDAItemStock   AS ST WITH(NOLOCK) ON @CompanySeq = ST.CompanySeq  
                                                               AND A.MatItemSeq = ST.ItemSeq       
                        JOIN _TDAItemUnit   AS U ON A.MatItemSeq = U.ItemSeq        
                                                AND A.MatUnitSeq = U.UnitSeq    
                                                AND U.CompanySeq = @CompanySeq      
                        JOIN _TDAUnit       AS V ON A.MatUnitSeq = V.UnitSeq   
                                                AND U.CompanySeq = V.CompanySeq 
                                       
                                                 
      WHERE A.Qty > 0        
         
         
         
 RETURN        
 /***************************************************************************************************************/