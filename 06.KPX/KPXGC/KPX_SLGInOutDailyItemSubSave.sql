IF OBJECT_ID('KPX_SLGInOutDailyItemSubSave') IS NOT NULL
    DROP PROC KPX_SLGInOutDailyItemSubSave
GO 

-- v2014.12.05 

-- ����Ʈ���̺�� ���� by����õ 
    
    
-- v2012.06.02
  /*************************************************************************************************    
  ��  �� - �����ǰ�� ����    
  �ۼ��� - 2008.10 : CREATED BY ����ȯ       
 CompanySeq
 InOutSeq
 InOutSerl
 ItemSeq
 InOutRemark
 CCtrSeq
 DVPlaceSeq
 InWHSeq
 OutWHSeq
 UnitSeq
 Qty
 StdQty
 Amt
 EtcOutAmt
 EtcOutVAT
 InOutKind
 InOutDetailKind
 LotNo
 SerialNo
 *************************************************************************************************/    
 CREATE PROC KPX_SLGInOutDailyItemSubSave  
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,    
     @WorkingTag     NVARCHAR(10)= '',    
     
     @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
 AS    
     DECLARE @docHandle        INT  
   
     -- ���� ����Ÿ ��� ����    
     CREATE TABLE #TLGInOutDailyItemSub (WorkingTag NCHAR(1) NULL)    
     EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TLGInOutDailyItemSub'    
     
     -- �����԰� ���Ͽ� ��õ�� ���� ���� �ӽ� ���̺��� ���� 
     DELETE A 
       FROM #TLGInOutDailyItemSub         AS A 
       LEFT OUTER JOIN KPX_TPUMatOutEtcOutItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND A.InOutSerl = B.InOutSerl )
      WHERE A.InOutType IN(81,83)
        AND A.WorkingTag = 'A'
        AND B.CompanySeq IS NULL
     
     UPDATE A 
        SET A.InOutRemark     = B.InOutRemark,
            A.ItemSeq         = B.ItemSeq,
            A.UnitSeq         = B.UnitSeq,
            A.InWHSeq         = B.InWHSeq,
            A.OutWHSeq        = B.OutWHSeq,
            A.Qty             = B.Qty,
            A.InOutDetailKind = B.InOutDetailKind,
            A.LotNo = B.LotNo
       FROM #TLGInOutDailyItemSub    AS A 
       JOIN KPX_TPUMatOutEtcOutItem       AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND A.InOutSerl = B.InOutSerl )
      WHERE A.InOutType IN(81,83)
        AND A.WorkingTag = 'A'
     
     CREATE TABLE #TLGInOutMinusCheck  
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
  
  /*
     Create Table #TLGInOutSerialSub
     (
         InOutType   INT,
         InOutSeq    INT,
         InOutSerl   INT,    
         DataKind    INT,
         InOutDataSerl   INT,
         InOutSerialSerl INT,
         SerialNo    NVARCHAR(30),
         ItemSeq     INT,
         MessageType INT,    
         Result      NVARCHAR(250),
         Status      INT 
     ) 
  */
  --     ALTER TABLE #TLGInOutDailyItemSub ADD InOutType   INT
  --     UPDATE #TLGInOutDailyItemSub
 --        SET InOutType = B.InOutType
 --       FROM #TLGInOutDailyItemSub A
 --             JOIN KPX_TPUMatOutEtcOut B ON B.CompanySeq = @CompanySeq
 --                                  AND A.InOutSeq = B.InOutSeq
 --                                  AND B.IsBatch <> '1'
      -- �α� �����
     DECLARE @TableColumns NVARCHAR(4000)
     
     SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPUMatOutEtcOutItemSub')
     
     EXEC _SCOMLog  @CompanySeq   ,    
                    @UserSeq      ,    
                    'KPX_TPUMatOutEtcOutItemSub', -- �����̺��    
                    '#TLGInOutDailyItemSub', -- �������̺��     
                    'InOutType,InOutSeq,InOutSerl, DataKind, InOutDataSerl' , -- Ű�� �������� ���� , �� �����Ѵ�.     
                    --'CompanySeq,InOutType,InOutSeq,InOutSerl, DataKind, InOutDataSerl, ItemSeq,InOutRemark,CCtrSeq,DVPlaceSeq,InWHSeq,OutWHSeq,UnitSeq,Qty,STDQty,Amt,EtcOutAmt,EtcOutVAT,InOutKind,InOutDetailKind,LotNo,SerialNo,LastUserSeq,LastDateTime'        
                    @TableColumns,'',@PgmSeq
     
     SELECT @TableColumns = dbo._FGetColumnsForLog('_TLGInOutLotSub')
     
     -- _S%Save �� _S%Delete �ΰ��� SP���� ���ؼ� ... 
     EXEC _SCOMDeleteLog @CompanySeq,  
                         @UserSeq,  
                         '_TLGInOutLotSub', 
                         '#TLGInOutDailyItemSub', 
                         'InOutType, InOutSeq, InOutSerl, DataKind, InOutDataSerl', -- CompanySeq���� �� Ű 
                         @TableColumns, '', @PgmSeq 
     
 --    ALTER TABLE #TLGInOutDailyItemSub ADD InOutDate    NCHAR(8) ---- ���������
     ALTER TABLE #TLGInOutDailyItemSub ADD IsStockQty   NCHAR(1) ---- ��������������
     ALTER TABLE #TLGInOutDailyItemSub ADD IsStockAmt   NCHAR(1) ---- ���ݾװ�������
     ALTER TABLE #TLGInOutDailyItemSub ADD IsLot        NCHAR(1) ---- Lot��������
     ALTER TABLE #TLGInOutDailyItemSub ADD IsSerial     NCHAR(1) ---- �ø����������
     ALTER TABLE #TLGInOutDailyItemSub ADD IsItemStockCheck   NCHAR(1) ---- ǰ�������� üũ
     ALTER TABLE #TLGInOutDailyItemSub ADD InOutDate    NCHAR(8) ----  üũ
     ALTER TABLE #TLGInOutDailyItemSub ADD CustSeq    INT ----  üũ
     ALTER TABLE #TLGInOutDailyItemSub ADD LastUserSeq    INT ----  üũ
     ALTER TABLE #TLGInOutDailyItemSub ADD LastDateTime   DATETIME ----  üũ
      UPDATE #TLGInOutDailyItemSub
        SET LastUserSeq  = @UserSeq,  
            LastDateTime = GETDATE()  
  --    ALTER TABLE #TLGInOutDailyItemSub ADD IsWHStockCheck     NCHAR(1) ---- â�������� üũ
     CREATE TABLE #TLGInOutStock(
         InOutType int,  
         InOutSeq int,
         InOutSerl int,
         DataKind int,
         InOutDataSerl int,
         InOutSubSerl int,
         InOut int,
         InOutYM nchar(6),
         InOutDate nchar(8),
         WHSeq int,
         FunctionWHSeq int,
         ItemSeq int,
         UnitSeq int,
         Qty decimal(19,5),
         StdQty decimal(19,5),
         Amt decimal(19,5),
         InOutKind int,
         InOutDetailKind int
     )
      CREATE TABLE #TLGInOutLotStock(              
         InOutType int,              
         InOutSeq int,              
         InOutSerl int,              
         DataKind int default 0,              
         InOutDataSerl int default 0,              
         InOutSubSerl int,              
         InOutLotSerl int,              
         InOut int,              
         InOutYM nchar(6),              
         InOutDate nchar(8),              
         WHSeq int,              
         FunctionWHSeq int,  
         LotNo   NVARCHAR(30),            
         ItemSeq int,              
         UnitSeq int,              
         Qty decimal(19,5),              
         StdQty decimal(19,5),              
         InOutKind int,              
         InOutDetailKind int ,              
         Amt decimal(19,5)             
     )              
  
  /*
  DECLARE @MessageType INT,
    @Status   INT,
    @Results  NVARCHAR(300)
    
  -- @2 @1(@3)��(��) ��ϵǾ� ����/���� �� �� �����ϴ�.
  -- SerialNo��(��) ��ϵǾ� ����/���� �� �� �����ϴ�.
  EXEC dbo._SCOMMessage @MessageType OUTPUT,          
                           @Status      OUTPUT,          
                           @Results     OUTPUT,          
                           8, -- select * from _TCAMessageLanguage where MessageSeq = 8
                           @LanguageSeq,           
                           0,'SerialNo'
  
  
  -- �� ����, ��Ʈǰ����� ������ �ʿ䰡 ����, �� �ܰ�� �� ���� ������ �ܰ� ����ǿ������� SerialNo����� �ϴϱ�...  
  UPDATE A
     SET A.Result   = REPLACE( REPLACE( @Results, '@2', '' ), '(@3)', '' ), 
      A.MessageType = @MessageType,        
      A.Status   = @Status     
    FROM #TLGInOutDailyItemSub AS A 
    JOIN _TLGInOutSerialSub  AS B WITH(NOLOCK) ON ( A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND B.CompanySeq = @CompanySeq )
   WHERE A.WorkingTag IN ( 'U', 'D' ) 
     AND A.Status = 0  
     */
     
     UPDATE  #TLGInOutDailyItemSub
        SET  IsStockQty          = IsNULL(C.IsQty, '0'),
             IsStockAmt          = IsNULL(C.IsAmt, '0'),
             IsItemStockCheck    = IsNULL(C.IsMinus, '0')
       FROM  #TLGInOutDailyItemSub A
             LEFT OUTER JOIN _TDAItem B WITH(NOLOCK) ON A.ItemSeq = B.ItemSeq
             LEFT OUTER JOIN _TDAItemAsset C WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq
                                                         AND B.AssetSeq   = C.AssetSeq
      WHERE  B.CompanySeq = @CompanySeq
      UPDATE  #TLGInOutDailyItemSub
        SET  IsLot               = IsNULL(B.IsLotMng, '0'),
             IsSerial            = IsNULL(B.IsSerialMng, '0')
       FROM  #TLGInOutDailyItemSub A
             LEFT OUTER JOIN _TDAItemStock B WITH(NOLOCK) ON A.ItemSeq = B.ItemSeq
      WHERE  B.CompanySeq = @CompanySeq
      UPDATE  #TLGInOutDailyItemSub
        SET  InOutDate               = CASE ISNULL(B.CompleteDate, '') WHEN '' THEN B.InOutDate ELSE B.CompleteDate END,
             CustSeq                 = B.CustSeq,
             OutWHSeq                = Case A.OutWHSeq when 0 then B.OutWHSeq else A.OutWHSeq end,
             InWHSeq                 = Case A.InWHSeq when 0 then B.InWHSeq else A.InWHSeq end
       FROM  #TLGInOutDailyItemSub A
             JOIN KPX_TPUMatOutEtcOut B WITH(NOLOCK) ON A.InOutSeq = B.InOutSeq
                                               AND A.InOutType = B.InOutType
      WHERE  B.CompanySeq = @CompanySeq
  
  -- DELETE      
     IF EXISTS (SELECT 1 FROM #TLGInOutDailyItemSub WHERE WorkingTag = 'D' AND Status = 0  )    
     BEGIN    
   /*
         -- SERIAL ����
         INSERT INTO #TLGInOutSerialSub
         SELECT B.InOutType, B.InOutSeq, B.InOutSerl, B.DataKind, B.InOutDataSerl, B.InOutSerialSerl, B.SerialNo, B.ItemSeq, 0, '', 0
           FROM #TLGInOutDailyItemSub AS A
                 JOIN _TLGInOutSerialSub AS B ON B.CompanySeq = @CompanySeq
                                             AND A.InOutType  = B.InOutType
                                             AND A.InOutSeq   = B.InOutSeq
                                             AND A.InOutSerl  = B.InOutSerl
                                             AND A.DataKind   = B.DataKind  
                                             AND A.InOutDataSerl = B.InOutDataSerl  
          WHERE A.WorkingTag = 'D' AND A.Status = 0   
          IF EXISTS (SELECT 1 FROM #TLGInOutSerialSub)
         BEGIN
             -- SERIAL ������        
             EXEC  _SLGCreateDataForInOutSerialStockBatch @CompanySeq, 'D'  
              UPDATE #TLGInOutDailyItemSub    
                SET Result        = B.Result     ,        
                    MessageType   = B.MessageType,        
                    Status        = B.Status        
               FROM #TLGInOutDailyItemSub AS A     
                    JOIN #TLGInOutSerialSub AS B ON A.InOutType = B.InOutType    
                                                AND A.InOutSeq  = B.InOutSeq
                                                AND A.InOutSerl  = B.InOutSerl
                                                AND A.DataKind   = B.DataKind  
                                                AND A.InOutDataSerl  = B.InOutDataSerl  
              WHERE B.Status <> 0     
  
             -- SerialSub DELETE
             DELETE _TLGInOutSerialSub  
               FROM #TLGInOutDailyItemSub AS A  
                    JOIN _TLGInOutSerialSub AS B ON B.CompanySeq = @CompanySeq
                                                AND A.InOutType  = B.InOutType
                                                AND A.InOutSeq   = B.InOutSeq
                                                AND A.InOutSerl  = B.InOutSerl
                                                AND A.DataKind   = B.DataKind  
                                                AND A.InOutDataSerl  = B.InOutDataSerl  
              WHERE A.WorkingTag = 'D' AND A.Status = 0   
              IF @@ERROR <> 0    
             BEGIN    
                 RETURN    
             END  
         END      
   */
   
         INSERT #TLGInOutMonth  
         (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,  
                        ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,  
                        ADD_DEL)  
         SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,  
                        B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,  
                        -1  
           FROM #TLGInOutDailyItemSub AS A      
                JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq      
                                                      AND B.InOutType  = A.InOutType      
                                                      AND B.InOutSeq   = A.InOutSeq      
                                                      AND B.InOutSerl  = A.InOutSerl    
                                                      AND B.DataKind   = A.DataKind  
                                                      AND B.InOutSubSerl  = A.InOutDataSerl  
          WHERE A.WorkingTag = 'D' AND A.Status = 0       
           INSERT #TLGInOutMonthLot  
         (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,  LotNo,  
                        ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,    
                        ADD_DEL)    
         SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,  B.LotNo,  
                        B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,    
                        -1    
           FROM #TLGInOutDailyItemSub AS A        
                JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq        
                                                         AND B.InOutType  = A.InOutType        
                                                         AND B.InOutSeq   = A.InOutSeq        
                                                         AND B.InOutSerl  = A.InOutSerl      
                                                         AND B.DataKind   = A.DataKind    
                                                         AND B.InOutSubSerl  = A.InOutDataSerl    
          WHERE A.WorkingTag = 'D' AND A.Status = 0         
          -- LOT ��� DELETE      
         DELETE _TLGInOutLotStock        
           FROM #TLGInOutDailyItemSub AS A        
                JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq        
                                                         AND B.InOutType   = A.InOutType    
                                                         AND B.InOutSeq    = A.InOutSeq        
                                                         AND B.InOutSerl   = A.InOutSerl      
                                                         AND B.DataKind   = A.DataKind    
                                                         AND B.InOutSubSerl  = A.InOutDataSerl    
          WHERE A.WorkingTag = 'D' AND A.Status = 0         
       
         IF @@ERROR <> 0          
         BEGIN          
             RETURN          
         END        
   
         -- LOT ����� DELETE      
         DELETE _TLGInOutLotSub        
           FROM #TLGInOutDailyItemSub AS A        
   JOIN KPX_TPUMatOutEtcOutItemSub AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq      
                                                             AND B.InOutType   = A.InOutType      
                                                             AND B.InOutSeq   = A.InOutSeq      
                                                             AND B.InOutSerl   = A.InOutSerl      
                                                          AND B.DataKind   = A.DataKind    
                                                             AND B.InOutDataSerl  = A.InOutDataSerl    
                JOIN _TLGInOutLotSub AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq      
                                                             AND C.InOutType  = B.InOutType      
                                                             AND C.InOutSeq   = B.InOutSeq        
                                                             AND C.InOutSerl  = B.InOutSerl 
                                                             AND C.DataKind   = B.DataKind    
                                                             AND C.InOutDataSerl  = B.InOutDataSerl    
          WHERE  B.LotNo > ''     
            AND  A.WorkingTag = 'D' AND A.Status = 0         
       
         IF @@ERROR <> 0          
         BEGIN          
             RETURN          
         END        
          DELETE _TLGInOutStock   
           FROM #TLGInOutDailyItemSub AS A    
                JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                     AND A.InOutType = B.InOutType
                                                     AND B.InOutSeq   = A.InOutSeq    
                                                     AND B.InOutSerl  = A.InOutSerl  
                                                     AND B.DataKind   = A.DataKind  
                                                     AND B.InOutSubSerl  = A.InOutDataSerl  
          WHERE A.WorkingTag = 'D' AND A.Status = 0     
   
         IF @@ERROR <> 0      
         BEGIN      
             RETURN      
         END    
          DELETE KPX_TPUMatOutEtcOutItemSub    
           FROM #TLGInOutDailyItemSub AS A    
                JOIN KPX_TPUMatOutEtcOutItemSub AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                     AND A.InOutType = B.InOutType
                                                     AND B.InOutSeq   = A.InOutSeq    
                                                     AND B.InOutSerl  = A.InOutSerl  
                                                     AND B.DataKind   = A.DataKind  
                                                     AND B.InOutDataSerl  = A.InOutDataSerl  
          WHERE A.WorkingTag = 'D' AND A.Status = 0     
   
         IF @@ERROR <> 0      
         BEGIN      
             RETURN      
         END    
     END    
   
     -- Update      
     IF EXISTS (SELECT 1 FROM #TLGInOutDailyItemSub WHERE WorkingTag = 'U' AND Status = 0  )    
     BEGIN     
          EXEC  _SLGCreateDataForInOutSubStock @CompanySeq, 'U'
   
         /*
             _TLGInOutLotSub���� ���� ���� ���� �����ʹ� �����Ѵ�.
             �Ʒ� _SLGCreateDataForInOutLotStock���� �ٽ� �ν�Ʈ ��
         */ 
         DELETE  _TLGInOutLotSub 
         FROM    _TLGInOutLotSub X 
                 JOIN (
                 SELECT  B.CompanySeq, B.InOutType, B.InOutSeq, B.InOutSerl, B.DataKind, B.InOutDataSerl
                   FROM  #TLGInOutDailyItemSub A
                         JOIN  _TLGInOutLotSub B ON B.CompanySeq = @CompanySeq        
                                                AND B.InOutType   = A.InOutType        
                                                AND B.InOutSeq   = A.InOutSeq        
                                                AND B.InOutSerl  = A.InOutSerl 
                                                AND B.DataKind   = A.DataKind    
                                                AND B.InOutDataSerl  = A.InOutDataSerl    
 --                 WHERE  B.InOutDataSerl = 0
                 GROUP BY B.CompanySeq, B.InOutType, B.InOutSeq, B.InOutSerl, B.DataKind, B.InOutDataSerl
                 HAVING COUNT(1) = 1) Y ON X.CompanySeq = Y.CompanySeq
                                       AND X.InOutType = Y.InOutType
                                       AND X.InOutSeq = Y.InOutSeq
                                       AND X.InOutSerl = Y.InOutSerl
                                       AND X.DataKind = Y.DataKind
                                       AND X.InOutDataSerl = Y.InOutDataSerl
          UPDATE KPX_TPUMatOutEtcOutItemSub    
            SET  ItemSeq = ISNULL(A.ItemSeq,0),
                 InOutRemark = ISNULL(A.Remark,''),
                 CCtrSeq = ISNULL(A.CCtrSeq,0),
                 DVPlaceSeq = ISNULL(A.DVPlaceSeq,0),
                 InWHSeq = ISNULL(A.InWHSeq,0),
                 OutWHSeq = ISNULL(A.OutWHSeq,0),
                 UnitSeq = ISNULL(A.UnitSeq,0),
                 Qty = ISNULL(A.Qty,0),
                 STDQty = ISNULL(A.STDQty,0),
                 Amt = ISNULL(A.Amt,0),
                 EtcOutAmt = ISNULL(A.EtcOutAmt,0),
                 EtcOutVAT = ISNULL(A.EtcOutVAT,0),
                 InOutKind = ISNULL(A.InOutKind,0),
                 InOutDetailKind = ISNULL(A.InOutDetailKind,0),
                 LotNo = ISNULL(A.LotNo,''),
                 SerialNo = ISNULL(A.SerialNo,''),
                 LastUserSeq  = @UserSeq,  
                 LastDateTime = GETDATE(),
                 PgmSeq = @PgmSeq
           FROM #TLGInOutDailyItemSub AS A    
                JOIN KPX_TPUMatOutEtcOutItemSub AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                     AND A.InOutType = B.InOutType
                                                     AND B.InOutSeq   = A.InOutSeq    
                                                     AND B.InOutSerl  = A.InOutSerl  
                                                     AND B.DataKind   = A.DataKind  
                                                     AND B.InOutDataSerl  = A.InOutDataSerl  
           WHERE A.WorkingTag = 'U' AND A.Status = 0  
      
         IF @@ERROR <> 0      
         BEGIN      
             RETURN      
         END    
          INSERT #TLGInOutMonth  
         (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,  
                        ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,  
                        ADD_DEL)  
         SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,  
                        B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,  
                        -1  
           FROM #TLGInOutDailyItemSub AS A      
                JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq      
                                                      AND B.InOutType  = A.InOutType      
                                                      AND B.InOutSeq   = A.InOutSeq      
                                                      AND B.InOutSerl  = A.InOutSerl    
                                                      AND B.DataKind   = A.DataKind  
                                                      AND B.InOutSubSerl  = A.InOutDataSerl  
          WHERE A.WorkingTag = 'U' AND A.Status = 0       
   
         DELETE _TLGInOutStock   
           FROM #TLGInOutDailyItemSub AS A    
                JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                     AND B.InOutType  = A.InOutType      
                                                     AND B.InOutSeq   = A.InOutSeq    
                                                     AND B.InOutSerl  = A.InOutSerl  
         AND B.DataKind   = A.DataKind  
                                                     AND B.InOutSubSerl  = A.InOutDataSerl  
          WHERE A.WorkingTag = 'U' AND A.Status = 0     
   
         IF @@ERROR <> 0      
         BEGIN      
             RETURN      
         END    
 --SELECT * FROM #TLGInOutStock
 --SELECT * FROM _TLGInOutStock
         INSERT  _TLGInOutStock
         SELECT  @CompanySeq, *
           FROM  #TLGInOutStock
  
         INSERT  #TLGInOutMonth              
         (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,              
                        ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,              
                        ADD_DEL)              
         SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,              
                        B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,              
                        1              
           FROM  #TLGInOutStock   B    
          EXEC    _SLGCreateDataForInOutLotSubStock @CompanySeq, 'U'    
          INSERT #TLGInOutMonthLot    
         (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,   LotNo, 
                        ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,    
                        ADD_DEL)    
         SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,   B.LotNo,
                        B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,    
                        -1    
           FROM  #TLGInOutDailyItemSub AS A        
                 JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq        
                                                      AND B.InOutType  = A.InOutType        
                                                      AND B.InOutSeq   = A.InOutSeq        
                                                      AND B.InOutSerl  = A.InOutSerl      
                                                      AND B.DataKind   = A.DataKind    
                                                      AND B.InOutSubSerl  = A.InOutDataSerl    
          WHERE  A.WorkingTag = 'U' AND A.Status = 0         
   
       
         DELETE _TLGInOutLotStock       
           FROM #TLGInOutDailyItemSub AS A        
                JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq        
                                                     AND B.InOutType   = A.InOutType        
                                                     AND B.InOutSeq   = A.InOutSeq        
                                                     AND B.InOutSerl  = A.InOutSerl    
                                                     AND B.DataKind   = A.DataKind    
                                                     AND B.InOutSubSerl  = A.InOutDataSerl    
          WHERE A.WorkingTag = 'U' AND A.Status = 0         
       
         IF @@ERROR <> 0          
         BEGIN          
             RETURN          
         END        
         INSERT  _TLGInOutLotStock    
         SELECT  @CompanySeq, *    
           FROM  #TLGInOutLotStock    
   
   
         INSERT  #TLGInOutMonthLot                
         (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,  LotNo,              
                        ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,                
                        ADD_DEL)                
         SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,  B.LotNo,             
                        B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,                
                        1                
           FROM  #TLGInOutLotStock   B                          
     END    
        
     -- INSERT      
     IF EXISTS (SELECT 1 FROM #TLGInOutDailyItemSub WHERE WorkingTag = 'A' AND Status = 0 )    
     BEGIN    
         TRUNCATE TABLE #TLGInOutStock  
         TRUNCATE TABLE #TLGInOutLotStock    
          EXEC  _SLGCreateDataForInOutSubStock @CompanySeq, 'A'  
          INSERT INTO KPX_TPUMatOutEtcOutItemSub(    
                 CompanySeq,
                 InOutType,
                 InOutSeq,
                 InOutSerl,
                 DataKind,
                 InOutDataSerl,
                 ItemSeq,
                 InOutRemark,
                 CCtrSeq,
                 DVPlaceSeq,
                 InWHSeq,
                 OutWHSeq,
                 UnitSeq,
                 Qty,
                 STDQty,
                 Amt,
                 EtcOutAmt,
                 EtcOutVAT,
                 InOutKind,
                 InOutDetailKind,
                 LotNo,
                 SerialNo,
                 LastUserSeq,
                 LastDateTime,
                 PgmSeq)  
         SELECT  @CompanySeq, 
                 ISNULL(InOutType ,0),
                 ISNULL(InOutSeq,0),
                 ISNULL(InOutSerl,0),
                 ISNULL(DataKind,0),
                 ISNULL(InOutDataSerl,0),
                 ISNULL(ItemSeq,0),
                 ISNULL(Remark,''),
                 ISNULL(CCtrSeq,0),
                 ISNULL(DVPlaceSeq,0),
                 ISNULL(InWHSeq,0),
                 ISNULL(OutWHSeq,0),
                 ISNULL(UnitSeq,0),
                 ISNULL(Qty,0),
                 ISNULL(STDQty,0),
                 ISNULL(Amt,0),
                 ISNULL(EtcOutAmt,0),
                 ISNULL(EtcOutVAT,0),
                 ISNULL(InOutKind,0),
                 ISNULL(InOutDetailKind,0),
                 ISNULL(LotNo,''),
                 ISNULL(SerialNo,''),
                 @UserSeq,  
                 GETDATE(),
                 @PgmSeq
           FROM #TLGInOutDailyItemSub A    
          WHERE WorkingTag = 'A' AND Status = 0  
     
         IF @@ERROR <> 0      
         BEGIN      
             RETURN      
         END    
          INSERT  _TLGInOutStock
         SELECT  @CompanySeq, *
           FROM  #TLGInOutStock
  
         INSERT  #TLGInOutMonth              
         (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,              
                        ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,              
                        ADD_DEL)              
         SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,              
                        B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,              
                        1              
           FROM  #TLGInOutStock   B           
          EXEC  _SLGCreateDataForInOutLotSubStock @CompanySeq, 'A'    -- 2011. 1. 26 hkim ������� �������� ó���ÿ� ���������� ���̺� �ݿ����� �ʾƼ� SP ȣ�� ��ġ ����
          INSERT  _TLGInOutLotStock    
         SELECT  @CompanySeq, *    
           FROM  #TLGInOutLotStock    
   
         --EXEC  _SLGCreateDataForInOutLotSubStock @CompanySeq, 'A'    
   
         INSERT  #TLGInOutMonthLot                
         (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,                
                        ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,     LotNo    ,      
                        ADD_DEL)                
         SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,                
         B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,     LotNo    ,      
                        1                
           FROM  #TLGInOutLotStock   B                   
    
     END        
       
     EXEC _SLGWHStockUPDATE @CompanySeq  
     EXEC _SLGLOTStockUPDATE @CompanySeq  
      EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyItemSub', @LanguageSeq
     EXEC _SLGInOutLotMinusCheck @CompanySeq, '#TLGInOutDailyItemSub', @LanguageSeq
      SELECT * FROM #TLGInOutDailyItemSub    
      RETURN