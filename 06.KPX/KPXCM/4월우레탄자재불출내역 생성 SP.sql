drop proc test_SPDSFCWorkReportMatSave
go 
/************************************************************      
 ��  �� - ���������������      
 �ۼ��� - 2008�� 10�� 22��       
 �ۼ��� - ������      
 UPDATE ::  '��������ǰ���� ��������' ����ϸ鼭, ���ǰ ���� ó�� �� ��ҽ� (������ ȭ��ܿ��� ����) , ������ ����â��� ������ ����â�� �ٸ����,  
             �̵� ������ �������ش�( ������ ����â�� -> �� ���� ����â��)      -- 12.12.28 BY �輼ȣ  
    2013.04.15 ��³� :: ��ü�۾��� ��� �ڵ������� �ʿ�����Ƿ� ���ⵥ���� ������ ���ܽ�����.  
 ************************************************************/   
 CREATE PROC dbo.test_SPDSFCWorkReportMatSave  
     @xmlDocument    NVARCHAR(MAX),        
     @xmlFlags       INT = 0,        
     @ServiceSeq     INT = 0,        
     @WorkingTag     NVARCHAR(10)= '',        
     @CompanySeq     INT = 1,        
     @LanguageSeq    INT = 1,        
     @UserSeq        INT = 0,        
     @PgmSeq         INT = 0        
 AS          
     DECLARE @MatItemPoint   INT,    
             @Env6217        NCHAR(2),  
             @Env6201        NCHAR(2),  
             @WorkOrderSeq   INT,  
             @WorkOrderSerl  INT,  
             @WorkReportSeq  INT,      
             @EmpSeq         INT,  
             @XmlData        NVARCHAR(MAX)  
      -- ���� ����Ÿ ��� ����      
     CREATE TABLE #TPDSFCMatinput (WorkingTag NCHAR(1) NULL)        
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPDSFCMatinput'           
     IF @@ERROR <> 0 RETURN          
       
    
  -- PgmSeq �۾� 2014�� 07�� 20�� �ϰ� �۾��մϴ�. (���� ����ȭ �Ǹ� ��������)   
  IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPDSFCMatinput' AND A.xtype = 'U' AND B.Name = 'PgmSeq')  
  BEGIN  
    ALTER TABLE _TPDSFCMatinput ADD PgmSeq INT NULL  
  END   
   IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPDSFCMatinputLog' AND A.xtype = 'U' AND B.Name = 'PgmSeq')  
  BEGIN  
    ALTER TABLE _TPDSFCMatinputLog ADD PgmSeq INT NULL  
  END    
   IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPDMMOutM' AND A.xtype = 'U' AND B.Name = 'PgmSeq')  
  BEGIN  
    ALTER TABLE _TPDMMOutM ADD PgmSeq INT NULL  
  END   
   IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPDMMOutItem' AND A.xtype = 'U' AND B.Name = 'PgmSeq')  
  BEGIN  
    ALTER TABLE _TPDMMOutItem ADD PgmSeq INT NULL  
  END     

     -- ���ݿ�        
     Create Table #TLGInOutMinusCheck        
     (          
         WHSeq           INT,        
         FunctionWHSeq   INT,        
         ItemSeq         INT      
     )        
       
     CREATE TABLE #TLGInOutMonth              
     (                
         InOut           INT,              
         InOutYM         NCHAR(6),              
         WHSeq           INT,              
         FunctionWHSeq   INT,              
         ItemSeq         INT,              
         UnitSeq         INT,              
         Qty             DECIMAL(19, 5),              
         StdQty          DECIMAL(19, 5),              
         ADD_DEL         INT              
     )                      
       
     CREATE TABLE #TLGInOutDailyBatch        
     (        
         InOutType       INT,        
         InOutSeq        INT,      
         MessageType     INT,      
         Result          NVARCHAR(250),      
         Status          INT      
     )        
       
     Create Table #TLGInOutMonthLot            
     (              
         InOut           INT,            
         InOutYM         NCHAR(6),            
         WHSeq           INT,            
         FunctionWHSeq   INT,            
         LotNo           NVARCHAR(30),            
         ItemSeq         INT,            
         UnitSeq         INT,            
         Qty             DECIMAL(19, 5),            
         StdQty          DECIMAL(19, 5),                  
         ADD_DEL         INT                  
     )            
       
     EXEC dbo._SCOMEnv @CompanySeq,5,@UserSeq,@@PROCID,@MatItemPoint OUTPUT       
     
  
     -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)      
 --    EXEC _SCOMInsertColumnList '_TPDSFCMatinput'      
       
     EXEC _SCOMLog  @CompanySeq,      
                    @UserSeq,      
                    '_TPDSFCMatinput',      
          '#TPDSFCMatinput',      
                    'WorkReportSeq, ItemSerl',      
                    'CompanySeq,WorkReportSeq,ItemSerl,InputDate,MatItemSeq,MatUnitSeq,Qty,StdUnitQty,RealLotNo,SerialNoFrom,ProcSeq,AssyYn,IsConsign,GoodItemSeq,InputType,IsPaid,IsPjt,PjtSeq,WBSSeq,LastUserSeq,LastDateTime,Remark,ProdWRSeq,PgmSeq',  
        '',@PgmSeq      
       
/*
        
     -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT      
       
       
     -- DELETE          
     IF EXISTS (SELECT TOP 1 1 FROM #TPDSFCMatinput WHERE WorkingTag = 'D' AND Status = 0)        
     BEGIN        
          -- ���� ���԰��� ���� ������ UPDATE (���� ���̳ʽ� �̵������� ������ ���)  
         UPDATE #TPDSFCMatinput   
            SET Qty = B.Qty,  
                StdUnitQty  = B.StdUnitQty  
           FROM #TPDSFCMatinput  AS A  
           JOIN _TPDSFCMatInput  AS B ON A.WorkReportSeq = B.WorkReportSeq      
                                          AND A.ItemSerl = B.ItemSerl   
          WHERE A.WorkingTag = 'D'       
            AND A.Status = 0      
            AND B.CompanySeq  = @CompanySeq    
             
         DELETE _TPDSFCMatinput      
           FROM _TPDSFCMatinput   AS A       
             JOIN #TPDSFCMatinput AS B ON A.WorkReportSeq = B.WorkReportSeq      
                                          AND A.ItemSerl = B.ItemSerl      
          WHERE B.WorkingTag = 'D'       
            AND B.Status = 0      
            AND A.CompanySeq  = @CompanySeq      
         IF @@ERROR <> 0  RETURN      
       
         -- �����ô� _TLGInOutLotSub ����  2011. 3. 15 hkim    
         DELETE _TLGInOutLotSub    
           FROM _TLGInOutLotSub      AS A    
                JOIN #TPDSFCMatinput AS B ON A.InOutSeq   = B.WorkReportSeq    
                JOIN _TDAItemStock   AS C ON B.MatItemSeq = C.ItemSeq    
          WHERE A.InOutType     = 130    
            AND C.IsLotMng      = '1'    
            AND A.LotNo         = B.RealLotNo    
            AND A.InOutDataSerl = B.ItemSerl    
            AND B.WorkingTag    = 'D'    
            AND B.Status        = 0    
            AND A.CompanySeq    = @CompanySeq    
          IF @@ERROR <> 0  RETURN      
            
         -- 2010.01.19. ������ ������ҽ� �ڵ���� �������� �ʴ� ������ �־ �߰�.       
         INSERT INTO #TLGInOutDailyBatch        
         SELECT DISTINCT 180, A.MatOutSeq, 0, '', 0      
           FROM _TPDMMOutM               AS A       
             JOIN #TPDSFCMatinput        AS B ON A.WorkReportSeq = B.WorkReportSeq        
          WHERE B.WorkingTag = 'D'       
            AND B.Status     = 0      
            AND A.CompanySeq = @CompanySeq      
            AND B.WorkReportSeq <> 0    
            AND A.UseType = 6044006    
       
         IF EXISTS (SELECT 1 FROM #TLGInOutDailyBatch )      
         BEGIN      
             EXEC _SLGInOutDailyDELETE @CompanySeq      
 --      
 --            EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyBatch'      
 --      
 --            UPDATE A      
 --               SET Result        = B.Result     ,          
 --                   MessageType   = B.MessageType,          
 --                   Status        = B.Status          
 --              FROM #TPDSFCMatinput          AS A       
 --        JOIN _TPDMMOutM             AS M ON A.WorkReportSeq = M.WorkReportSeq      
 --                JOIN #TLGInOutDailyBatch    AS B ON M.MatOutSeq = B.InOutSeq      
 --             WHERE B.Status <> 0       
 --               AND A.WorkingTag = 'D'       
 --               AND A.Status     = 0      
 --                     
 --            TRUNCATE TABLE #TLGInOutDailyBatch      
         END      
       
       
         -- �� ����� �ڵ������� (������Һ�)      
         DELETE _TPDMMOutItem      
           FROM _TPDMMOutItem        AS A       
             JOIN _TPDMMOutM         AS M ON A.MatOutSeq = M.MatOutSeq      
  
       AND A.CompanySeq = M.CompanySeq      
             JOIN #TPDSFCMatinput    AS B ON M.WorkReportSeq = B.WorkReportSeq      
          WHERE A.CompanySeq  = @CompanySeq      
            AND B.WorkingTag = 'D'       
            AND B.Status = 0      
            AND M.UseType = 6044006      
            AND B.WorkReportSeq <> 0      
         IF @@ERROR <> 0  RETURN      
    
         -- �����͵� ����       
         DELETE _TPDMMOutM      
           FROM _TPDMMOutM           AS M       
             JOIN #TPDSFCMatinput    AS B ON M.WorkReportSeq = B.WorkReportSeq      
          WHERE M.CompanySeq  = @CompanySeq      
            AND B.WorkingTag = 'D'       
            AND B.Status = 0      
            AND NOT EXISTS (SELECT 1 FROM _TPDMMOutItem WHERE CompanySeq = M.CompanySeq AND MatOutSeq = M.MatOutSeq)      
            AND M.UseType = 6044006      
            AND B.WorkReportSeq <> 0      
         IF @@ERROR <> 0  RETURN      
       
     END        
       
       
     -- ���ش������� ����      
     UPDATE T      
        --SET StdUnitQty = T.Qty * (CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END )      
        SET StdUnitQty = (CASE WHEN V.SMDecPointSeq = 1003001 THEN ROUND(T.Qty * (CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END ), @MatItemPoint, 0)   -- �ݿø�    
                               WHEN V.SMDecPointSeq = 1003002 THEN ROUND(T.Qty * (CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END ), @MatItemPoint, -1)  -- ����    
                               WHEN V.SMDecPointSeq = 1003003 THEN ROUND((CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END ) * T.Qty + CAST(4 AS DECIMAL(19, 5)) / POWER(10,(@MatItemPoint + 1)), @MatItemPoint)   -- �ø�    
                               ELSE ROUND(T.Qty * (CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END ), @MatItemPoint, 0) END)  -- �⺻�� �ݿø����� ���� 2011. 3. 3. hkim    
       FROM #TPDSFCMatinput  AS T      
         JOIN _TDAItemUnit   AS U ON T.MatItemSeq = U.ItemSeq      
                                 AND T.MatUnitSeq = U.UnitSeq      
         JOIN _TDAUnit       AS V ON T.MatUnitSeq = V.UnitSeq     
      WHERE U.CompanySeq = @CompanySeq    
        AND V.CompanySeq = @CompanySeq          
    
    
        
     -- ������      
     UPDATE #TPDSFCMatinput      
        SET InputDate = B.WorkDate      
       FROM #TPDSFCMatinput      AS A       
         JOIN _TPDSFCWorkReport  AS B ON A.WorkReportSeq = B.WorkReportSeq      
                                     AND B.CompanySeq  = @CompanySeq        
      WHERE InputDate = ''      
       
       
    -- ����â��      
     UPDATE #TPDSFCMatinput      
        SET WHSeq = B.FieldWhSeq      
       FROM #TPDSFCMatinput      AS A       
         JOIN _TPDSFCWorkReport  AS B ON A.WorkReportSeq = B.WorkReportSeq      
                                     AND B.CompanySeq  = @CompanySeq        
       
       
     -- ���Ա��� - ȭ�鿡���� �Էµ� ����� �������� ó���Ѵ�.       
     UPDATE #TPDSFCMatinput      
        SET InputType = 6042002      
      WHERE InputType = 0      
       
 --------------------------------------------------------------------------------------------------------------------------------------------------------------      
     -- �߰��������簡 ��Ź�ΰ�� ���Ա��� ��Ź���� ����      
       
       
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
  
         IsOut            NCHAR(1),   -- �ν��� ���뿡 ��� '1'�̸� OutLossRate ����      
         WorkReportSeq   INT      
     )      
            
     CREATE TABLE #MatNeed_MatItem_Result      
     (      
         IDX_NO          INT,            -- ��ǰ�ڵ�      
         MatItemSeq    INT,            -- �����ڵ�      
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
       
     DECLARE @WorkReportSeqQry INT       
       
     SELECT TOP 1 @WorkReportSeqQry = WorkReportSeq FROM #TPDSFCMatinput      
       
     -- �ҿ䷮��� �� ���� ǰ����.      
     INSERT #MatNeed_GoodItem (ItemSeq,ProcRev,BOMRev,ProcSeq,AssyItemSeq,UnitSeq,Qty,ProdPlanSeq,WorkOrderSeq,WorkOrderSerl,IsOut,WorkReportSeq)      
     SELECT W.GoodItemSeq, W.ProcRev, W.ItemBomRev, W.ProcSeq, W.AssyItemSeq, W.ProdUnitSeq,       
            W.ProdQty * (CASE WHEN W.WorkType = 6041004 THEN (-1)       
         WHEN W.WorkType = 6041010 THEN (-1) ELSE 1 END),  -- ��ü(���)�۾��̸� (-),       
            O.ProdPlanSeq, W.WorkOrderSeq, W.WorkOrderSerl,  -- 2012. 5. 21 hkim ProdPlanSeq �߰�    
            '0' , WorkReportSeq      
       FROM _TPDSFCWorkReport    AS W       
      LEFT OUTER JOIN _TPDSFCWorkOrder AS O ON W.CompanySeq = O.CompanySeq   -- 2012. 5. 21 hkim ProdPlanSeq �߰� ���� �۾����� join     
             AND W.WorkOrderSeq = O.WorkOrderSeq    
             AND W.WorkOrderSerl = O.WorkOrderSerl    
      WHERE W.CompanySeq    = @CompanySeq      
        AND W.WorkReportSeq = @WorkReportSeqQry      
       
       
     -- �ҿ����� ��������      
     EXEC dbo._SPDMMGetItemNeedQty @CompanySeq       
       
 --select * from #MatNeed_GoodItem      
 -- select * from #MatNeed_MatItem_Result      
     -------------------------------      
     -- �ҿ䷮ ���� ----------------      
     INSERT #NeedMatSUM (ProcSeq,MatItemSeq,UnitSeq,NeedQty,InputQty,InputType, ItemSeq, BOMRev, AssyItemSeq,BOMSerl) -- �ҿ䷮      
     SELECT A.ProcSeq, B.MatItemSeq, B.UnitSeq, B.NeedQty, B.NeedQty, B.InputType, A.ItemSeq, A.BOMRev, A.AssyItemSeq, 9999      
       FROM #MatNeed_GoodItem            AS A      
            JOIN #MatNeed_MatItem_Result AS B ON A.IDX_NO = B.IDX_NO      
       
       
       
     UPDATE #TPDSFCMatinput      
        SET InputType = B.InputType      
         FROM #TPDSFCMatinput AS A JOIN #NeedMatSUM  AS B ON A.MatItemSeq = B.MatItemSeq      
        
  -- �������� ������������ ó���Ǵ� ���� ���Ա����� ������������ ������Ʈ ���ش� 2010. 8. 18 hkim      
  IF @PgmSeq = 1023  -- �������Լ������� ȭ�鿡�� ó���� ���      
  BEGIN      
   UPDATE #TPDSFCMatinput      
      SET InputType = 6042007      
  END      
    
 -------------------------------------------------------------------------------------------------------------------------------------------------------------      
 -- �����˻� ����۾�(��ü�۾��ΰ�� ���� - �������� ó��)      
  IF EXISTS (SELECt 1 FROM #TPDSFCMatinput  AS A      
         JOIN _TPDSFCWorkReport AS B ON A.WorkReportSeq = B.WorkReportSeq      
         WHERE B.CompanySeq = @CompanySeq       
           AND B.WorkType   IN (6041004, 6041010) )      
  BEGIN      
   UPDATE #TPDSFCMatinput      
      SET Qty     = -Qty,      
       StdUnitQty = -StdUnitQty      
     FROM #TPDSFCMatinput  AS A      
       JOIN _TPDSFCWorkReport AS B ON A.WorkReportSeq = B.WorkReportSeq      
    WHERE B.CompanySeq = @CompanySeq       
      AND B.WorkType IN (6041004, 6041010)      
  END                
       
       
     -- UPDATE          
     IF EXISTS (SELECT 1 FROM #TPDSFCMatinput WHERE WorkingTag = 'U' AND Status = 0)        
  
     BEGIN       
       
    
         UPDATE _TPDSFCMatinput      
            SET  InputDate           = ( SELECT TOP 1 WorkDate FROM _TPDSFCWorkReport WHERE WorkReportSeq = B.WorkReportSeq  -- 2014.11.14 ����� ����  
                                                                                        AND CompanySeq    = @CompanySeq)  ,  --B.InputDate             
                 MatItemSeq          = B.MatItemSeq          ,      
                 MatUnitSeq          = B.MatUnitSeq          ,      
                 Qty                 = B.Qty                 ,      
                 StdUnitQty          = B.StdUnitQty          ,      
                 RealLotNo           = B.RealLotNo           ,      
                 SerialNoFrom         = B.SerialNoFrom        ,      
                 ProcSeq             = B.ProcSeq             ,      
                 AssyYn              = B.AssyYn              ,      
                 IsConsign           = B.IsConsign           ,      
                 GoodItemSeq         = B.GoodItemSeq         ,      
                 InputType           = B.InputType           ,      
                 IsPaid              = B.IsPaid              ,      
                 IsPjt               = B.IsPjt               ,      
                 PjtSeq              = ISNULL(B.PjtSeq,0)    ,      
                 WBSSeq              = B.WBSSeq              ,      
                 LastUserSeq         = @UserSeq              ,      
                 LastDateTime        = GETDATE()             ,      
                 Remark              = B.Remark              ,  
     PgmSeq              = @PgmSeq  
           FROM _TPDSFCMatinput   AS A       
             JOIN #TPDSFCMatinput AS B ON A.WorkReportSeq = B.WorkReportSeq      
                                          AND A.ItemSerl = B.ItemSerl      
          WHERE B.WorkingTag = 'U'       
            AND B.Status = 0          
            AND A.CompanySeq  = @CompanySeq        
         IF @@ERROR <> 0  RETURN      
     END         
       
       
     -- INSERT      
     IF EXISTS (SELECT 1 FROM #TPDSFCMatinput WHERE WorkingTag = 'A' AND Status = 0)        
     BEGIN        
         INSERT INTO _TPDSFCMatinput       
                    (CompanySeq      , WorkReportSeq     , ItemSerl          , InputDate             , MatItemSeq        ,       
                     MatUnitSeq      , Qty               , StdUnitQty        , RealLotNo             , SerialNoFrom      ,       
                     ProcSeq         , AssyYn            , IsConsign         , GoodItemSeq       ,       
                     InputType       , IsPaid            , IsPjt             , PjtSeq                , WBSSeq            ,      
                     LastUserSeq     , LastDateTime      , Remark            , ProdWRSeq             , PgmSeq)      
             SELECT @CompanySeq        ,A.WorkReportSeq      ,A.ItemSerl           ,( SELECT TOP 1 WorkDate FROM _TPDSFCWorkReport WHERE WorkReportSeq = A.WorkReportSeq   
                                                                                                                                     AND CompanySeq    = @CompanySeq) ,A.MatItemSeq       ,      
                     A.MatUnitSeq      , A.Qty               , A.StdUnitQty        , A.RealLotNo             , A.SerialNoFrom      ,       
                     A.ProcSeq         , A.AssyYn            , A.IsConsign         , A.GoodItemSeq       ,       
                     A.InputType       , A.IsPaid            , A.IsPjt             , ISNULL(A.PjtSeq,0)                , A.WBSSeq            ,      
                     @UserSeq           ,GETDATE()           , A.Remark            , A.ProdWRSeq              , @PgmSeq  
               FROM #TPDSFCMatinput AS A         
              WHERE A.WorkingTag = 'A' AND A.Status = 0          
         IF @@ERROR <> 0 RETURN      
     END         
    */
  -- ���� �� ���� ����� �����ֱ� ���ؼ�  ����ó���� ����� �Ѿ�� �ּ�ó��      
  --UPDATE #TPDSFCMatinput      
  --   SET Qty    = ABS(Qty),      
  
  --    StdUnitQty = ABS(StdUnitQty)      
       
       
     /************ �ڵ���� ǰ���� ó�� ********************************/      
     -- ������ ��� �ڵ���� ����� ���� �ڵ������� ����Ѵ�.       
     -- �׷��� �׻� ���ܰ� �ֱ� ������ �������Կ����� �ڵ���� �����ؾ��Ѵ�.       
     -- ������ �ݿ��� ��������� ���Ұ� �Բ� ó���ȴ�.       
       
     -- #TPDSFCMatinput ���� ����� �Ǹ� �����Ϸ��� �ߴ��� �ڵ����ǰ��<-> ���ڵ����ǰ������ ������ ��� ����������.       
     -- �׷��� ���Ե� ��ǰ���� �׳� �ٽ� ������ش�. ������ �۾��� �ѹ��� ó���ǰ� ���ҹݿ��� �Ѳ����� �̷�����Ƿ� �̰� �����ϴ�.       
       
     -- ������Ʈ����� ��� �ڵ����ǰ���̾ �Ʒ� ��ƾ�� Ÿ�� �ʾƾ��Ѵ�.(2010.08.25)      
    
    

delete A
      From _TPDMMOutItem as a 
      join _TPDMMOutM as b on ( b.CompanySeq = a.CompanySeq and b.MatOutSeq = a.MatOutSeq ) 
     where a.CompanySeq = @CompanySeq 
       AND B.FactUnit = 3
       and left(b.MatOutDate,6) = '201604'
    
    
    delete From _TPDMMOutM where CompanySeq = @CompanySeq and  left(MatOutDate,6) = '201604' AND FactUnit = 3

     SELECT A.*      
       INTO #MatAutoOut      
       FROM _TPDSFCMatinput      AS A       
         JOIN _TDAItemProduct    AS P WITH(NOLOCK) ON A.MatItemSeq = P.ItemSeq      
                                                  AND A.CompanySeq  = P.CompanySeq      
         JOIN _TDAItem           AS I WITH(NOLOCK) ON A.MatItemSeq = I.ItemSeq                                                        
                                                  AND A.CompanySeq  = I.CompanySeq      
         JOIN _TDAItemAsset      AS S WITH(NOLOCK) ON A.CompanySeq = S.CompanySeq      
                                                  AND I.AssetSeq      = S.AssetSeq     
         JOIN _TPDSFCWorkReport  AS B WITH(NOLOCK) ON A.CompanySeq  = B.CompanySeq
                                                  AND A.WorkReportSeq  = B.WorkReportSeq
      WHERE P.SMOutKind = 6005002        
        AND A.CompanySeq = @CompanySeq        
        --AND EXISTS (SELECT 1 FROM #TPDSFCMatinput WHERE WorkReportSeq = A.WorkReportSeq)        
        AND S.SMAssetGrp <> 6008005        
        AND A.ISPJT <> '1'      
        AND B.FactUnit  = 3
        and left(A.InputDate ,6) = '201604'
    
    
    --select * from #MatAutoOut 
    --return 
    
     IF EXISTS(SELECT 1 FROM #MatAutoOut)
     BEGIN      
               
         DECLARE @MaxNo          NVARCHAR(50)    ,      
                 @FactUnit       INT             ,      
                 @Seq            INT             ,      
                 @Date           NVARCHAR(8)     ,      
                 @WorkCenterSeq  INT             ,      
                 @MatOutWHSeq    INT             ,      
                 @FieldWhSeq     INT      
       
         SELECT @EmpSeq = EmpSeq      
           FROM _TCAUser       
          WHERE CompanySeq = @CompanySeq      
            AND UserSeq = @UserSeq      
       
         SELECT @EmpSeq = ISNULL(@EmpSeq, 0 )      
       
         -- ����������� ����Ǹ� WorkReportSeq�� �ϳ� ���̴�.       
         -- �׷��� ���� �������� ���簡 ���ÿ� ����� ��츦 ����ؼ� Cursor�� �̿��Ѵ�.       
       
         DECLARE CUR_Mat CURSOR FOR      
         SELECT DISTINCT A.WorkReportSeq       
           FROM #MatAutoOut   AS A JOIN _TPDSFCWorkReport AS B ON B.CompanySeq = @CompanySeq   
                    AND A.WorkReportSeq = B.WorkReportSeq  
         -- WHERE B.WorkType NOT IN ( 6041004,6041010)  --��ü�۾��� ��� �ڵ���� ������ �������� �ʱ����� ���ܽ�����.   
       
         OPEN CUR_Mat      
       
         FETCH NEXT FROM CUR_Mat INTO @WorkReportSeq      
           WHILE (@@FETCH_STATUS = 0)      
         BEGIN      
       
             -- �ڵ����ǰ���� �ִµ� ������Ͱ� ������ ������������Ѵ�.       
             IF NOT EXISTS (SELECT 1 FROM _TPDMMOutM WHERE CompanySeq = @CompanySeq AND WorkReportSeq = @WorkReportSeq)      
             BEGIN      
       
                 -- Ű�������ڵ�κ� ����        
                 EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TPDMMOutM', 'MatOutSeq', 1      
       
                 SELECT @Seq = @Seq + 1       
       
                 SELECT  @FactUnit       = FactUnit      ,      
                         @Date           = WorkDate      ,      
                         @WorkCenterSeq  = WorkCenterSeq ,      
                         @FieldWhSeq     = FieldWhSeq      
                   FROM _TPDSFCWorkReport WITH(NOLOCK)      
                  WHERE CompanySeq = @CompanySeq      
                    AND WorkReportSeq = @WorkReportSeq      
       
       
                 SELECT @MatOutWHSeq = MatOutWhSeq      
                   FROM _TPDBaseWorkCenter WITH(NOLOCK)      
                  WHERE CompanySeq = @CompanySeq      
                    AND WorkCenterSeq = @WorkCenterSeq      
       
       
                 EXEC   dbo._SCOMCreateNo    'PD'                , -- ����(HR/AC/SL/PD/ESM/PMS/SI/SITE)      
                                             '_TPDMMOutM'        , -- ���̺�      
  
            @CompanySeq         , -- �����ڵ�      
                                             @FactUnit           , -- �ι��ڵ�      
                                             @Date               , -- �����      
                                             @MaxNo OUTPUT      
       
       
                 INSERT INTO _TPDMMOutM       
                            (CompanySeq      , MatOutSeq         , FactUnit          , MatOutNo          , MatOutDate            ,       
               UseType         , MatOutType        , IsOutSide         , OutWHSeq          , InWHSeq               ,       
                             EmpSeq          , Remark            , WorkReportSeq     , LastUserSeq       , LastDateTime          ,  
        PgmSeq)      
                     SELECT @CompanySeq      , @Seq              , @FactUnit         , @MaxNo            , @Date                 ,      
                            6044006          , 0                 , '0'               , @MatOutWHSeq      , @FieldWhSeq           ,       
                           @EmpSeq          , ''                , @WorkReportSeq    , @UserSeq          , GETDATE()             ,  
          @PgmSeq  
       
                 IF @@ERROR <> 0 RETURN      
       
             END      
       
             FETCH NEXT FROM CUR_Mat INTO @WorkReportSeq      
         END      
       
         DEALLOCATE CUR_Mat      
        
        
         -- �� ����� �ڵ�������      
         DELETE _TPDMMOutItem      
           FROM _TPDMMOutItem   AS A       
             JOIN _TPDMMOutM    AS M ON A.MatOutSeq = M.MatOutSeq      
                                    AND A.CompanySeq = M.CompanySeq      
             JOIN #MatAutoOut   AS B ON M.WorkReportSeq = B.WorkReportSeq      
          WHERE A.CompanySeq  = @CompanySeq      
            AND B.WorkReportSeq <> 0    
            AND M.UseType = 6044006    
                
         IF @@ERROR <> 0  RETURN      
       
       --select * from _TDASMinor where companyseq = 2 and MajorSeq = 8042 
       
         TRUNCATE TABLE #TLGInOutDailyBatch      
       
         -- ���һ���      
         INSERT INTO #TLGInOutDailyBatch        
         SELECT DISTINCT 180, D.MatOutSeq, 0, '', 0      
           FROM _TPDMMOutM       AS D      
             JOIN #MatAutoOut    AS A ON D.WorkReportSeq = A.WorkReportSeq      
          WHERE D.CompanySeq = @CompanySeq      
            AND A.WorkReportSeq <> 0    
            AND D.UseType = 6044006    
       
         EXEC _SLGInOutDailyDELETE @CompanySeq      
       
 --        IF EXISTS(SELECT 1 FROM #TLGInOutDailyBatch)      
 --            EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyBatch'      
       
         UPDATE A      
            SET Result        = B.Result     ,          
                MessageType   = B.MessageType,          
                Status        = B.Status          
           FROM #TPDSFCMatinput          AS A       
             JOIN _TPDMMOutM             AS M ON A.WorkReportSeq = M.WorkReportSeq      
             JOIN #TLGInOutDailyBatch    AS B ON M.MatOutSeq = B.InOutSeq      
          WHERE B.Status <> 0       
            AND M.CompanySeq = @CompanySeq    
       
         -- �ڵ���� ����      
       
         -- Default ���â��      
         -- : 1. â�� ǰ�� ��ϵǾ� �ִ� ǰ���� �ش�â���� �����´�.       
         -- : 2. ��ũ������ �⺻���â���� ���縦 �����´�.       
        
        
        -- ǰ�� �⺻â�� �ƴϸ� ��ũ������ ���â��.      
        CREATE TABLE #ItemWH 
        (
            WorkReportSeq   INT, 
            ItemSeq         INT, 
            OutWHSeq        INT, 
            FactUnit        INT, 
            AssetSeq        INT 
        )
        INSERT INTO #ItemWH ( WorkReportSeq, ItemSeq, OutWHSeq, FactUnit, AssetSeq ) 
        SELECT DISTINCT A.WorkReportSeq, A.MatItemSeq AS ItemSeq, ISNULL(B.OutWHSeq, M.OutWHSeq) AS OutWHSeq, M.FactUnit, D.AssetSeq 
          FROM #MatAutoOut                 AS A 
                     JOIN _TPDMMOutM       AS M ON ( A.WorkReportSeq = M.WorkReportSeq ) 
          LEFT OUTER JOIN _TDAItemStdWh    AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.MatItemSeq AND B.FactUnit = M.FactUnit ) 
          LEFT OUTER JOIN _TDAItem         AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.MatItemSeq ) 


        -- KPXCM�� ����������ڵ� ����â�� ���� 
        UPDATE A
           SET OutWHSeq = Y.OutWHSeq 
          FROM #ItemWH AS A 
          JOIN ( 
                SELECT A.ValueSeq AS OutWHSeq, B.ValueSeq AS FactUnit, C.ValueSeq AS AssetSeq 
                  FROM _TDAUMinorValue AS A 
                  JOIN _TDAUMinorValue AS B ON ( B.CompanySeq = A.CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
                  JOIN _TDAUMinorValue AS C ON ( C.CompanySeq = A.CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
                 WHERE A.CompanySeq = @CompanySeq 
                   AND A.Serl = 1000003 
                   AND A.MajorSeq = 1012905
               ) AS Y ON ( Y.AssetSeq = A.AssetSeq AND Y.FactUnit = A.FactUnit ) 


        
         INSERT INTO  _TPDMMOutItem      
                    (CompanySeq      ,MatOutSeq          ,OutItemSerl       ,ItemSeq            ,OutWHSeq           ,      
                     InWHSeq         ,UnitSeq            ,Qty                ,StdUnitQty         ,Price              ,      
                     Amt             ,ItemLotNo          ,SerialNoFrom       ,WorkOrderSeq       ,WorkOrderSerl      ,ConsgnmtCustSeq    ,      
                     Remark          ,OutReqSeq          ,OutReqItemSerl     ,PJTSeq             ,WBSSeq             ,      
                     LastUserSeq     ,LastDateTime       ,PgmSeq)      
             SELECT @CompanySeq      ,M.MatOutSeq        ,A.ItemSerl         ,A.MatItemSeq       ,ISNULL(W.OutWHSeq, 0), 
                     M.InWHSeq       ,A.MatUnitSeq       ,A.Qty              ,A.StdUnitQty       ,0                  ,      
                     0               ,A.RealLotNo        ,''                 ,R.WorkOrderSeq     ,R.WorkOrderSerl      ,0              ,  -- RealLotNo�� ''�� �� �־ ���� 2011. 2. 11 hkim    
                     ''              ,0                  ,0                  ,R.PjtSeq           ,R.WBSSeq                  ,      
                     @UserSeq           ,GETDATE()       ,@PgmSeq   
               FROM #MatAutoOut          AS A         
                 JOIN _TPDMMOutM         AS M ON A.WorkReportSeq = M.WorkReportSeq      
                 JOIN _TPDSFCWorkReport  AS R WITH(NOLOCK) ON A.WorkReportSeq = R.WorkReportSeq      
                 LEFT OUTER JOIN #ItemWH AS W ON ( W.WorkReportSeq = A.WorkReportSeq AND W.ItemSeq = A.MatItemSeq )    
             AND M.CompanySeq = R.CompanySeq      
              WHERE M.CompanySeq = @CompanySeq      
       
         EXEC _SLGInOutDailyINSERT @CompanySeq      
     END      
       
     EXEC _SLGWHStockUPDATE @CompanySeq          
     EXEC _SLGLOTStockUPDATE @CompanySeq          
       
    /*
     -- ������� (WorkignTag ='D')�ϰ�� ���� �����ϰ�ó�� (_SLGInOutDailyBatch) ����    
     -- ���� â��� ����â�� �����ؼ� ��� ���̳ʽ� ���üũ�� �ϹǷ�  ���⼭�� �ּ�ó��                                 -- 12.07.18 BY �輼ȣ    
     -- (������ҽ� , �ڵ����� ���ҹ߻��� ���⼭ ���̳ʽ����üũ�� �Ұ�� ���Լ��������� ��� ���̳ʽ����üũ�ɸ��Ƿ�)  
  -- ��ü�۾��� ��� ������ - ���ó���ϱ⶧���� ���̳ʽ����üũ�� ���ܽ�����.  ���̳ʽ����üũ�� ��� üũ�� �ɸ��� ��.  
     IF NOT EXISTS (SELECT 1 FROM #TPDSFCMatinput AS A JOIN _TPDSFCWorkReport AS B ON A.WorkReportSeq = B.WorkReportSeq      
                     WHERE B.CompanySeq = @CompanySeq       
                       AND (B.WorkType IN (6041004, 6041010)  AND A.Qty < 0  )  
                       OR  A.WorkingTag = 'D' )         
      BEGIN    
         EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyBatch'      
         EXEC _SLGInOutLotMinusCheck @CompanySeq, '#TLGInOutDailyBatch'      
      END    
     
     UPDATE A      
        SET Result        = B.Result     ,          
            MessageType   = B.MessageType,          
            Status        = B.Status        
       FROM #TPDSFCMatinput          AS A       
         JOIN _TPDMMOutM             AS M ON A.WorkReportSeq = M.WorkReportSeq      
         JOIN #TLGInOutDailyBatch    AS B ON M.MatOutSeq = B.InOutSeq      
      WHERE B.Status <> 0       
        AND M.CompanySeq = @CompanySeq    
       
       
     ----------------------------------------------------------------------------------------------------------------------------------------  
     -- '��������ǰ���� ��������' ����ϸ鼭, ���ǰ ���� ó�� �� ��ҽ� (������ ȭ��ܿ��� ����) , ������ ����â��� ������ ����â�� �ٸ����,  
     --  �̵� ������ �������ش�( ������ ����â�� -> �� ���� ����â��)       
     -- �ڵ����� ����� ���� ���� (�ڵ����� ����� ��� ����ó���� �̵������͵� �� ������ֹǷ�)    -- 12.12.28 BY �輼ȣ  
     ----------------------------------------------------------------------------------------------------------------------------------------  
     EXEC dbo._SCOMEnv @CompanySeq,6217,@UserSeq,@@PROCID,@Env6217 OUTPUT    -- ������ǰ �������� ����   
     EXEC dbo._SCOMEnv @CompanySeq,6201,@UserSeq,@@PROCID,@Env6201 OUTPUT    -- �ڵ����� ����   
       
     -- '��������ǰ����', ����ϸ� ���ǰ ���� ó�� �� ��ҽ�  
     IF @Env6217  = '1' AND  
        @Env6201 <> '1' AND  
         EXISTS( SELECT 1  
                   FROM #TPDSFCMatinput AS A  
                   JOIN _TDAItem        AS B ON A.MatItemSeq = B.ItemSeq  
                                             AND B.CompanySeq = @CompanySeq  
                   JOIN _TDAItemAsset    AS C ON B.COmpanySeq = C.CompanySeq  
                                             AND B.AssetSeq = C.AssetSeq  
                  WHERE A.WorkingTag IN ('A', 'D') AND C.SMAssetGrp  = 6008005 AND A.Status = 0)  
      BEGIN  
         -- ������ ���� �ڵ� ��������          
         SELECT TOP 1 @WorkOrderSeq = R.WorkOrderSeq,   
                      @WorkOrderSerl= R.WorkOrderSerl,  
                      @WorkReportSeq = R.WorkReportSeq   
           FROM #TPDSFCMatinput      AS B  
             JOIN _TPDSFCWorkReport  AS R ON @CompanySeq     = R.CompanySeq  
                                         AND B.WorkReportSeq = R.WorkReportSeq  
          
         SELECT @EmpSeq = ISNULL(EmpSeq, 0)  
           FROM _TCAUser       
          WHERE CompanySeq = @CompanySeq      
            AND UserSeq = @UserSeq      
    
         -- ������ ���ǰ  ������ ���  
         SELECT R.AssyItemSeq                AS ItemSeq,  
                R.FieldWHSeq                 AS FieldWHSeq              
           INTO #TMP_PreProcInfo  
           FROM   _TPDSFCWorkReport  AS R   
             JOIN _TPDSFCWorkOrder   AS W ON R.WorkOrderSeq  = W.WorkOrderSeq        
                                         AND R.WorkOrderSerl = W.WorkOrderSerl        
                                         AND R.CompanySeq    = W.CompanySeq      
          WHERE R.CompanySeq     = @CompanySeq        
            AND W.WorkOrderSeq   = @WorkOrderSeq        
            AND W.IsLastProc     <> 1        
            AND W.ToProcNo IN (SELECT A.ProcNo        
                                FROM _TPDSFCWorkOrder   AS A        
                                     WHERE  @CompanySeq    = A.CompanySeq        
                                        AND @WorkOrderSeq   = A.WorkOrderSeq        
                                        AND @WorkOrderSerl  = A.WorkOrderSerl)  
          GROUP BY R.AssyItemSeq, R.FieldWHSeq  
    
         -- �̵� Sheet ������ ���  
         SELECT  IDENTITY(INT, 1, 1)          AS IDX_NO,                  
                 'A'                          AS WorkingTag,  
                 0                            AS Status,  
                 0                            AS Selected,  
                 0                            AS InOutSeq,  
                 0                            AS InOutSerl,  
                 80                           AS InOutType,  
                 8023008                      AS InOutKind,  
                 8012001                      AS InOutDetailKind,  
                 'DataBlock2'                 AS TABLE_NAME,  
                 A.MatItemSeq                 AS ItemSeq ,  
                 CASE WHEN A.WorkingTag = 'A' THEN A.Qty ELSE A.Qty * -1 END AS Qty,    
                 CASE WHEN A.WorkingTag = 'A' THEN A.StdUnitQty ELSE A.StdUnitQty * -1 END AS STDQty,    
                 A.MatUnitSeq                 AS UnitSeq,  
                 C.FieldWHSeq                 AS InWHSeq,  
                 B.FieldWHSeq                 AS OutWHSeq,  
                 A.InputDate                  AS Date,  
                 F.BizUnit                    AS BizUnit,  
                 C.DeptSeq                    AS DeptSeq,  
                 @EmpSeq                      AS EmpSeq,  
                 0                            AS Amt  
           INTO #TMP_TLGInOutDailyItem                   
           FROM #TPDSFCMatinput      AS A   
           JOIN #TMP_PreProcInfo     AS B ON A.MatItemSeq = B.ItemSeq  
           JOIN _TPDSFCWorkReport    AS C ON A.WorkReportSeq = C.WorkReportSeq  
                                         AND C.COmpanySeq = @CompanySeq  
           JOIN _TDAFactUnit        AS F ON C.CompanySeq    = F.CompanySeq  
                                        AND C.FactUnit = F.FactUnit  
           JOIN _TDAItem             AS I ON A.MatItemSeq   = I.ItemSeq  
                                         AND I.CompanySeq = @CompanySeq  
           JOIN _TDAItemAsset        AS S ON I.Companyseq = S.CompanySeq  
                                         AND I.AssetSeq = S.AssetSeq  
                                         AND S.SMAssetGrp = 6008005  
         WHERE A.WorkingTag IN ('A', 'D')  
           AND C.FieldWHSeq <> B.FieldWHSeq  
    
         IF @@ROWCOUNT = 0     
         BEGIN    
  
             SELECT * FROM #TPDSFCMatinput         
             RETURN      
         END    
          ELSE  
         BEGIN  
              -- ������ ��� ���� ���� ���Һ��� ���� �߻���Ų��.  
              IF EXISTS (SELECT 1 FROM #TPDSFCMatinput WHERE WorkingTag = 'D')  
              BEGIN   
                  SELECT  A.WorkingTag            AS WorkingTag,  
                         IDENTITY(INT, 1, 1)     AS IDX_NO,  
                         0                       AS Selected,                                          
                         0                       AS Status,  
                         'DataBlock3'            AS TABLE_NAME,  
          130                     AS InOutType,  
                         8023015                 AS InOutKind,  
                         0                       AS InOutSerl,  
                         0                       AS DataKind,  
                         0                       AS InWHSeq,  
                         A.WorkReportSeq         AS InOutSeq,  
                         A.ItemSerl              AS InOutDataSerl,  
                         A.MatItemSeq            AS ItemSeq,  
                         A.MatUnitSeq            AS UnitSeq,  
                         I.UnitSeq               AS StdUnitSeq,  
                         A.QTy                   AS Qty,  
                         A.StdUnitQty            AS STDQty,  
                         6042002                 AS InOutDetailKind,  
                         B.FieldWHSeq            AS OutWHSeq                          
                   INTO #TMP_TPDSFCMatinput                                                                    
                   FROM #TPDSFCMatinput      AS A  
                   JOIN _TPDSFCWorkReport    AS B ON A.WorkReportSeq = B.WorkReportSeq  
                                                 AND B.COmpanySeq = @CompanySeq  
                   JOIN _TDAItem             AS I ON A.MatItemSeq   = I.ItemSeq  
                                                 AND I.CompanySeq = @CompanySeq  
                   JOIN _TDAItemAsset        AS S ON I.Companyseq = S.CompanySeq  
                                                 AND I.AssetSeq = S.AssetSeq  
                                                 AND S.SMAssetGrp = 6008005  
                 WHERE A.WorkingTag = 'D'  
                    
          
                 SELECT @XmlData = CONVERT(NVARCHAR(MAX),(      
                                                             SELECT IDX_NO AS DataSeq, *       
                                                               FROM #TMP_TPDSFCMatinput      
                                                                FOR XML RAW ('DataBlock3'), ROOT('ROOT'), ELEMENTS      
                                                         ))      
    
                 CREATE TABLE #TLGInOutDailyItemSub (WorkingTag NCHAR(1) NULL)        
                 EXEC dbo._SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock3', '#TLGInOutDailyItemSub'           
                  ALTER TABLE #TLGInOutDailyItemSub ADD IsStockQty   NCHAR(1) ---- ��������������    
                 ALTER TABLE #TLGInOutDailyItemSub ADD IsStockAmt   NCHAR(1) ---- ���ݾװ�������    
                 ALTER TABLE #TLGInOutDailyItemSub ADD IsLot        NCHAR(1) ---- Lot��������    
                 ALTER TABLE #TLGInOutDailyItemSub ADD IsSerial     NCHAR(1) ---- �ø����������    
                 ALTER TABLE #TLGInOutDailyItemSub ADD IsItemStockCheck   NCHAR(1) ---- ǰ�������� üũ    
                 ALTER TABLE #TLGInOutDailyItemSub ADD InOutDate    NCHAR(8) ----  üũ    
                 ALTER TABLE #TLGInOutDailyItemSub ADD CustSeq    INT ----  üũ    
                 ALTER TABLE #TLGInOutDailyItemSub ADD LastUserSeq    INT ----  üũ    
                 ALTER TABLE #TLGInOutDailyItemSub ADD LastDateTime   DATETIME ----  üũ    
                  INSERT INTO #TLGInOutDailyItemSub  
                 EXEC _SLGInOutDailyItemSubSave       
                      @xmlDocument  = @XmlData,      
  
                      @xmlFlags     = 2,       
                      @ServiceSeq   = 2619,      
                      @WorkingTag   = '',      
                      @CompanySeq   = @CompanySeq,      
                      @LanguageSeq  = @LanguageSeq,      
                      @UserSeq      = @UserSeq,      
                      @PgmSeq       = 1015      
                       IF @@ERROR <> 0 RETURN   
                  IF EXISTS (SELECT 1 FROM #TLGInOutDailyItemSub WHERE Status <> 0)  
                  BEGIN  
                     UPDATE #TPDSFCMatinput  
                         SET Result        = B.Result     ,    
                             MessageType   = B.MessageType,    
  Status        = B.Status  
                       FROM #TPDSFCMatinput  AS A  
                       JOIN #TLGInOutDailyItemSub AS B ON A.MatItemSeq = B.ItemSeq  
                      WHERE ISNULL(B.Status, 0) <> 0                    
                      SELECT * FROM #TPDSFCMatinput   
                     RETURN  
                  END  
               END   
               
              -- �̵� Master ������ ���  
             SELECT  TOP 1   'A'                          AS WorkingTag,  
                             IDENTITY(INT, 1, 1)          AS IDX_NO,                                                 
                             0                            AS Status,  
                             'DataBlock1'                 AS TABLE_NAME,               
                             1                            AS Selected,     
                             '1'                          AS IsChangedMst,       
                             0                            AS InOutSeq,  
                             A.BizUnit                    AS ReqBizUnit,  
                             ''                           AS InOutNo,  
                             80                           AS InOutType,  
                             0                            AS InOutDetailType,  
                             A.BizUnit                    AS BizUnit,  
                             '0'                          AS IsTrans,  
                             '1'                          AS IsCompleted,  
                             A.DeptSeq                    AS CompleteDeptSeq,  
                             A.EmpSeq                     AS CompleteEmpSeq,  
                             A.Date                       AS CompleteDate,  
                             A.InWHSeq                    AS InWHSeq,  
                             A.OutWHSeq                   AS OutWHSeq,  
                             A.Date                       AS InOutDate,  
                             A.DeptSeq                    AS DeptSeq,  
                             A.EmpSeq                     AS EmpSeq  
                INTO #TMP_TLGInOutDaily  
               FROM #TMP_TLGInOutDailyItem           AS A  
              ------------------------------      
             -- �̵� master XML      
             ------------------------------      
             SELECT @XmlData = CONVERT(NVARCHAR(MAX),(      
                                                         SELECT IDX_NO AS DataSeq, *       
                                                           FROM #TMP_TLGInOutDaily      
                                                            FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS      
                                                     ))      
    
             CREATE TABLE #LGInOutDailyCheck (WorkingTag NCHAR(1) NULL)        
             EXEC dbo._SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock1', '#LGInOutDailyCheck'           
    
             ------------------------------      
             -- �̵� master Check SP      
             ------------------------------   
             INSERT INTO #LGInOutDailyCheck  
             EXEC _SLGInOutDailyCheck       
                  @xmlDocument  = @XmlData,      
                  @xmlFlags     = 2,      
                  @ServiceSeq   = 2619,      
                  @WorkingTag   = '',      
  
              @CompanySeq   = @CompanySeq,      
                  @LanguageSeq  = @LanguageSeq,      
                  @UserSeq      = @UserSeq,      
                  @PgmSeq       = 1317      
                   IF @@ERROR <> 0 RETURN   
              IF EXISTS (SELECT 1 FROM #LGInOutDailyCheck WHERE Status <> 0)  
              BEGIN  
                 UPDATE #TPDSFCMatinput  
                     SET Result        = B.Result     ,    
                         MessageType   = B.MessageType,    
                         Status        = B.Status  
                   FROM #TPDSFCMatinput  AS A  
                   JOIN #TMP_TLGInOutDailyItem  AS C ON A.MatItemSeq = C.ItemSeq  
                   JOIN #LGInOutDailyCheck AS B ON 1=1                    
                  WHERE ISNULL(B.Status, 0) <> 0                    
                       
                 SELECT * FROM #TPDSFCMatinput   
                 RETURN  
              END  
    
             -- ������ڵ� UPDATE  
             UPDATE #TMP_TLGInOutDailyItem  
                SET InOutSeq = (SELECT TOP 1 InOutSeq FROM #LGInOutDailyCheck WHERE Status = 0)  
               FROM #TMP_TLGInOutDailyItem  
              ------------------------------      
             -- �̵� Sheet XML      
             ------------------------------      
             SELECT @XmlData = CONVERT(NVARCHAR(MAX),(      
                                                         SELECT IDX_NO AS DataSeq, *       
                                                           FROM #TMP_TLGInOutDailyItem     
                                                            FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS      
            ))        
    
              CREATE TABLE #TLGInOutDaily (WorkingTag NCHAR(1) NULL)              
             ExEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock1', '#TLGInOutDaily'    
              CREATE TABLE #TLGInOutDailyItem (WorkingTag NCHAR(1) NULL)        
             EXEC dbo._SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock2', '#TLGInOutDailyItem'   
    
             ------------------------------      
             -- �̵� Sheet Check SP      
             ------------------------------   
             INSERT INTO #TLGInOutDailyItem  
             EXEC _SLGInOutDailyItemCheck     
                  @xmlDocument  = @XmlData,      
                  @xmlFlags     = 2,      
                  @ServiceSeq   = 2619,      
                  @WorkingTag   = '',      
                  @CompanySeq   = @CompanySeq,      
                  @LanguageSeq  = @LanguageSeq,      
                  @UserSeq      = @UserSeq,      
                  @PgmSeq       = 1317      
                   IF @@ERROR <> 0 RETURN   
    
             IF EXISTS (SELECT 1 FROM #TLGInOutDailyItem WHERE Status <> 0)  
              BEGIN  
                 UPDATE #TPDSFCMatinput  
                     SET Result        = B.Result     ,    
                         MessageType   = B.MessageType,    
                         Status        = B.Status  
                   FROM #TPDSFCMatinput  AS A  
                   JOIN #TLGInOutDailyItem AS B ON A.MatItemSeq = B.ItemSeq  
                  WHERE ISNULL(B.Status, 0) <> 0                    
                       
                 SELECT * FROM #TPDSFCMatinput   
                 RETURN  
              END  
    
             ------------------------------      
             -- �̵� Master Save SP      
             ------------------------------   
              SELECT @XmlData = CONVERT(NVARCHAR(MAX),(      
                                                         SELECT *       
                                                           FROM #LGInOutDailyCheck      
                                                            FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS      
                                                     ))     
    
             DELETE FROM #LGInOutDailyCheck  
              INSERT INTO #LGInOutDailyCheck  
             EXEC _SLGInOutDailySave       
                  @xmlDocument  = @XmlData,      
                  @xmlFlags     = 2,      
                  @ServiceSeq   = 2619,      
                  @WorkingTag   = '',      
                  @CompanySeq   = @CompanySeq,      
                  @LanguageSeq  = @LanguageSeq,      
                  @UserSeq      = @UserSeq,      
                  @PgmSeq       = 1317     
    
                  IF @@ERROR <> 0 RETURN             
                
             IF EXISTS (SELECT 1 FROM #LGInOutDailyCheck WHERE Status <> 0)  
              BEGIN  
                 UPDATE #TPDSFCMatinput  
                     SET Result        = B.Result     ,    
                         MessageType   = B.MessageType,    
  Status        = B.Status  
                   FROM #TPDSFCMatinput  AS A  
                   JOIN #TMP_TLGInOutDailyItem  AS C ON A.MatItemSeq = C.ItemSeq  
                   JOIN #LGInOutDailyCheck AS B ON 1=1                    
                  WHERE ISNULL(B.Status, 0) <> 0                    
                       
                 SELECT * FROM #TPDSFCMatinput   
                 RETURN  
              END  
    
             ------------------------------      
             -- �̵� Sheet Save SP      
             ------------------------------   
             SELECT @XmlData = CONVERT(NVARCHAR(MAX),(      
                                                         SELECT *       
                                                           FROM #TLGInOutDailyItem                                                              
                                                            FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS      
                                                     ))     
              DELETE FROM #TLGInOutDailyItem  
              -- ����� Sheet����SP ������ ADD���ִ� Į�� ADD ����   
           ALTER TABLE #TLGInOutDailyItem ADD IsStockQty   NCHAR(1) ---- ��������������      
             ALTER TABLE #TLGInOutDailyItem ADD IsStockAmt   NCHAR(1) ---- ���ݾװ�������      
             ALTER TABLE #TLGInOutDailyItem ADD IsLot        NCHAR(1) ---- Lot��������      
             ALTER TABLE #TLGInOutDailyItem ADD IsSerial     NCHAR(1) ---- �ø����������      
             ALTER TABLE #TLGInOutDailyItem ADD IsItemStockCheck   NCHAR(1) ---- ǰ�������� üũ      
             ALTER TABLE #TLGInOutDailyItem ADD InOutDate    NCHAR(8) ----  üũ      
             ALTER TABLE #TLGInOutDailyItem ADD CustSeq    INT ----  üũ      
             ALTER TABLE #TLGInOutDailyItem ADD SalesCustSeq    INT ----  üũ      
             ALTER TABLE #TLGInOutDailyItem ADD IsTrans    NCHAR(1) ----  üũ   
    
             INSERT INTO #TLGInOutDailyItem  
             EXEC _SLGInOutDailyItemSave       
                  @xmlDocument  = @XmlData,      
                  @xmlFlags     = 2,      
                  @ServiceSeq   = 2619,      
                  @WorkingTag   = '',      
                  @CompanySeq   = @CompanySeq,      
                  @LanguageSeq  = @LanguageSeq,      
                  @UserSeq      = @UserSeq,      
                  @PgmSeq       = 1317     
                   IF @@ERROR <> 0 RETURN   
    
             IF EXISTS (SELECT 1 FROM #TLGInOutDailyItem WHERE Status <> 0)  
              BEGIN  
                 UPDATE #TPDSFCMatinput  
                     SET Result        = B.Result     ,    
                         MessageType   = B.MessageType,    
                         Status        = B.Status  
                   FROM #TPDSFCMatinput  AS A  
                   JOIN #TLGInOutDailyItem AS B ON A.MatItemSeq = B.ItemSeq  
                  WHERE ISNULL(B.Status, 0) <> 0                    
                       
                 SELECT * FROM #TPDSFCMatinput   
                 RETURN  
              END  
    
         END  
       
      END  
    */
     SELECT * FROM #TPDSFCMatinput         
  
     RETURN
     go
--begin tran 

exec test_SPDSFCWorkReportMatSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsPjt>0</IsPjt>
    <WBSSeq>0</WBSSeq>
    <WorkReportSeq>45334</WorkReportSeq>
    <ItemSerl>12</ItemSerl>
    <InputDate>20160430</InputDate>
    <MatItemSeq>617</MatItemSeq>
    <MatUnitSeq>9</MatUnitSeq>
    <StdUnitSeq>0</StdUnitSeq>
    <Qty>210.00000</Qty>
    <StdUnitQty>210.00000</StdUnitQty>
    <RealLotNo>1111010070</RealLotNo>
    <SerialNoFrom />
    <ProcSeq>26</ProcSeq>
    <AssyYn>0</AssyYn>
    <IsConsign>0</IsConsign>
    <GoodItemSeq>547</GoodItemSeq>
    <InputType>6042002</InputType>
    <IsPaid>0</IsPaid>
    <Remark>�������� ���԰�(���Կ���)</Remark>
    <WHSeq>13</WHSeq>
    <ProdWRSeq>0</ProdWRSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=2909,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1015
--rollback 
