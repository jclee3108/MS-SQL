
IF OBJECT_ID('backup_20151001_KPX_SLGInOutDailyItemSave') IS NOT NULL
    DROP PROC backup_20151001_KPX_SLGInOutDailyItemSave 
GO 

-- v2012.06.02  
  /*************************************************************************************************        
  ��  �� - �����ǰ�� ����        
  �ۼ��� - 2008.10 : CREATED BY ����ȯ           
 CompanySeq    
 InOutSeq    
 InOutSerl    
 DataKind    
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
 IsStockSales       ----------- �Ǹ��ĺ�������(�ŷ��������� ���Ǵ� ��)    
 OriUnitSeq    
 OriItemSeq    
 OriQty    
 OriStdQty   --------- �԰ݴ�ü�ÿ��� ���� ������ ����� �� ����    
 *************************************************************************************************/        
 CREATE PROC backup_20151001_KPX_SLGInOutDailyItemSave      
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
    CREATE TABLE #TLGInOutDailyItem (WorkingTag NCHAR(1) NULL)        
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TLGInOutDailyItem'       
      
    Create Table #TLGInOutMinusCheck    
    (      
        WHSeq           INT,    
        FunctionWHSeq   INT,    
        ItemSeq         INT  
    )    
    Create Table #TLGInOutMonth  
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
      
    -- �α� �����  
    DECLARE @TableColumns NVARCHAR(4000)  
      
    SELECT @TableColumns = dbo._FGetColumnsForLog('_TLGInOutDailyItem')  
      
    EXEC _SCOMLog  @CompanySeq   ,        
                   @UserSeq      ,        
                   '_TLGInOutDailyItem', -- �����̺��        
                   '#TLGInOutDailyItem', -- �������̺��        
                   'InOutType,InOutSeq,InOutSerl' , -- Ű�� �������� ���� , �� �����Ѵ�.         
                   --'CompanySeq,InOutType,InOutSeq,InOutSerl,ItemSeq,InOutRemark,CCtrSeq,DVPlaceSeq,InWHSeq,OutWHSeq,UnitSeq,Qty,STDQty,Amt,EtcOutAmt,EtcOutVAT,InOutKind,  
                   -- InOutDetailKind,LotNo,SerialNo,IsStockSales,OriUnitSeq,OriItemSeq,OriQty,OriSTDQty, OriLotNo, LastUserSeq,LastDateTime'            
                   @TableColumns, '', @PgmSeq   
       
    SELECT @TableColumns = dbo._FGetColumnsForLog('_TLGInOutDailyItemSub')  
       
    -- _S%Save �� _S%Delete �ΰ��� SP���� ���ؼ� ...   
    EXEC _SCOMDeleteLog @CompanySeq,    
                        @UserSeq,    
                        '_TLGInOutDailyItemSub',    
                        '#TLGInOutDailyItem',   
                        'InOutType, InOutSeq, InOutSerl', -- CompanySeq���� �� Ű   
                        @TableColumns, '', @PgmSeq   
      
    SELECT @TableColumns = dbo._FGetColumnsForLog('_TLGInOutLotSub')  
       
    -- _S%Save �� _S%Delete �ΰ��� SP���� ���ؼ� ...   
    EXEC _SCOMDeleteLog @CompanySeq,    
                        @UserSeq,    
                        '_TLGInOutLotSub',   
                        '#TLGInOutDailyItem',   
                        'InOutType, InOutSeq, InOutSerl', -- CompanySeq���� �� Ű   
                        @TableColumns, '', @PgmSeq   
       
      ALTER TABLE #TLGInOutDailyItem ADD IsStockQty   NCHAR(1) ---- ��������������    
    ALTER TABLE #TLGInOutDailyItem ADD IsStockAmt   NCHAR(1) ---- ���ݾװ�������    
    ALTER TABLE #TLGInOutDailyItem ADD IsLot        NCHAR(1) ---- Lot��������    
    ALTER TABLE #TLGInOutDailyItem ADD IsSerial     NCHAR(1) ---- �ø����������    
    ALTER TABLE #TLGInOutDailyItem ADD IsItemStockCheck   NCHAR(1) ---- ǰ�������� üũ    
    ALTER TABLE #TLGInOutDailyItem ADD InOutDate    NCHAR(8) ----  üũ    
    ALTER TABLE #TLGInOutDailyItem ADD CustSeq    INT ----  üũ    
    ALTER TABLE #TLGInOutDailyItem ADD SalesCustSeq    INT ----  üũ    
    ALTER TABLE #TLGInOutDailyItem ADD IsTrans    NCHAR(1) ----  üũ    
      
    CREATE TABLE #TLGInOutStock  
    (    
        InOutType int,    
        InOutSeq int,    
        InOutSerl int,    
        DataKind int default 0,    
        InOutDataSerl int default 0,    
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
    CREATE TABLE #TLGInOutLotStock  
    (                
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
    
    UPDATE #TLGInOutDailyItem    
       SET IsStockQty          = IsNULL(C.IsQty, '0'),    
           IsStockAmt          = IsNULL(C.IsAmt, '0'),    
           IsItemStockCheck    = IsNULL(C.IsMinus, '0')    
      FROM  #TLGInOutDailyItem      AS A    
      LEFT OUTER JOIN _TDAItem      AS B WITH(NOLOCK) ON A.ItemSeq = B.ItemSeq    
      LEFT OUTER JOIN _TDAItemAsset AS C WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq AND B.AssetSeq = C.AssetSeq    
      WHERE  B.CompanySeq = @CompanySeq    
      
    UPDATE  #TLGInOutDailyItem    
       SET  IsLot               = IsNULL(B.IsLotMng, '0'),    
            IsSerial            = IsNULL(B.IsSerialMng, '0')    
      FROM  #TLGInOutDailyItem A    
            LEFT OUTER JOIN _TDAItemStock B WITH(NOLOCK) ON A.ItemSeq = B.ItemSeq    
     WHERE  B.CompanySeq = @CompanySeq    
     
    UPDATE  #TLGInOutDailyItem    
       SET  InOutDate               = B.InOutDate,    
            CustSeq                 = B.CustSeq,    
            OutWHSeq                = Case A.OutWHSeq when 0 then B.OutWHSeq else A.OutWHSeq end,    
            InWHSeq                 = Case A.InWHSeq when 0 then B.InWHSeq else A.InWHSeq end  ,    
            IsTrans                 = B.IsTrans    
      FROM  #TLGInOutDailyItem A    
            JOIN _TLGInOutDaily B WITH(NOLOCK) ON A.InOutType = B.InOutType  AND  A.InOutSeq = B.InOutSeq    
     WHERE  B.CompanySeq = @CompanySeq    
     
    -- DELETE          
    IF EXISTS (SELECT 1 FROM #TLGInOutDailyItem WHERE WorkingTag = 'D' AND Status = 0  )        
    BEGIN        
        INSERT #TLGInOutMonth    
        (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,    
                       ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,    
                       ADD_DEL)    
          SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,    
                       B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,    
                       -1    
          FROM #TLGInOutDailyItem AS A        
               JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq        
                                                     AND B.InOutType  = A.InOutType        
                                                     AND B.InOutSeq   = A.InOutSeq        
                                                     AND B.InOutSerl  = A.InOutSerl      
         WHERE A.WorkingTag = 'D' AND A.Status = 0         
          INSERT #TLGInOutMonthLot    
        (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,  LotNo,    
                       ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,      
                       ADD_DEL)      
        SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,  B.LotNo,    
                       B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,      
                       -1      
          FROM #TLGInOutDailyItem AS A          
               JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq          
                                                        AND B.InOutType  = A.InOutType          
                                                        AND B.InOutSeq   = A.InOutSeq          
                                                        AND B.InOutSerl  = A.InOutSerl        
         WHERE A.WorkingTag = 'D' AND A.Status = 0           
     
     
        -- LOT ��� DELETE        
        DELETE _TLGInOutLotStock          
          FROM #TLGInOutDailyItem AS A          
               JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq          
                                                        AND B.InOutType   = A.InOutType      
                                                        AND B.InOutSeq    = A.InOutSeq          
                                                        AND B.InOutSerl   = A.InOutSerl        
         WHERE A.WorkingTag = 'D' AND A.Status = 0           
        
        IF @@ERROR <> 0            
        BEGIN            
            RETURN            
        END          
     
        -- LOT ����� DELETE        
        DELETE _TLGInOutLotSub          
          FROM #TLGInOutDailyItem AS A          
               JOIN _TLGInOutLotSub AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq        
                                                            AND C.InOutType  = A.InOutType        
                                                            AND C.InOutSeq   = A.InOutSeq          
                                                            AND C.InOutSerl  = A.InOutSerl   
         WHERE  A.WorkingTag = 'D' AND A.Status = 0           
        
        IF @@ERROR <> 0            
        BEGIN            
            RETURN            
        END        
    
        DELETE _TLGInOutStock       
          FROM #TLGInOutDailyItem AS A        
               JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq        
                                                    AND B.InOutType   = A.InOutType        
                                                    AND B.InOutSeq   = A.InOutSeq        
                                                    AND B.InOutSerl  = A.InOutSerl      
         WHERE A.WorkingTag = 'D' AND A.Status = 0         
      
        IF @@ERROR <> 0          
        BEGIN          
            RETURN          
      END        
     
     
        DELETE _TLGInOutDailyItem        
          FROM #TLGInOutDailyItem AS A        
               JOIN _TLGInOutDailyItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq        
                                                      AND B.InOutType  = A.InOutType        
                                                    AND B.InOutSeq   = A.InOutSeq         
                                                    AND B.InOutSerl  = A.InOutSerl      
         WHERE A.WorkingTag = 'D' AND A.Status = 0         
      
        IF @@ERROR <> 0          
        BEGIN          
            RETURN          
        END        
        DELETE _TLGInOutDailyItemSub        
          FROM #TLGInOutDailyItem AS A        
               JOIN _TLGInOutDailyItemSub AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq        
                                                    AND B.InOutType   = A.InOutType        
                                                    AND B.InOutSeq   = A.InOutSeq        
                                                    AND B.InOutSerl  = A.InOutSerl      
         WHERE A.WorkingTag = 'D' AND A.Status = 0         
      
        IF @@ERROR <> 0          
        BEGIN          
            RETURN          
        END        
     END        
      
    -- Update          
    IF EXISTS (SELECT 1 FROM #TLGInOutDailyItem WHERE WorkingTag = 'U' AND Status = 0  )        
    BEGIN         
      
        EXEC  _SLGCreateDataForInOutStock @CompanySeq, 'U'    
        /*  
            _TLGInOutLotSub���� ���� ���� ���� �����ʹ� �����Ѵ�.  
            �Ʒ� _SLGCreateDataForInOutLotStock���� �ٽ� �ν�Ʈ ��  
        */   
        DELETE  _TLGInOutLotSub   
        FROM    _TLGInOutLotSub X   
                JOIN (  
                SELECT  B.CompanySeq, B.InOutType, B.InOutSeq, B.InOutSerl  
                  FROM  #TLGInOutDailyItem A  
                        JOIN  _TLGInOutLotSub B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq      -- WITH(NOLOCK) �߰� 2011. 9. 1 hkim       
                                                            AND B.InOutType   = A.InOutType          
                                                            AND B.InOutSeq   = A.InOutSeq          
                                                            AND B.InOutSerl  = A.InOutSerl   
                GROUP BY B.CompanySeq, B.InOutType, B.InOutSeq, B.InOutSerl  
                HAVING COUNT(1) = 1) Y ON X.CompanySeq = Y.CompanySeq  
                                      AND X.InOutType = Y.InOutType  
                                      AND X.InOutSeq = Y.InOutSeq  
                                      AND X.InOutSerl = Y.InOutSerl  
                                        
        UPDATE _TLGInOutDailyItem        
           SET  ItemSeq = A.ItemSeq,    
                InOutRemark = A.InOutRemark,    
                CCtrSeq = A.CCtrSeq,    
                DVPlaceSeq = A.DVPlaceSeq,    
                InWHSeq = A.InWHSeq,    
                OutWHSeq = A.OutWHSeq,    
                UnitSeq = A.UnitSeq,    
                Qty = A.Qty,    
                STDQty = A.STDQty,    
                Amt = A.Amt,    
                EtcOutAmt = A.EtcOutAmt,    
                EtcOutVAT = A.EtcOutVAT,    
                InOutKind = A.InOutKind,    
                InOutDetailKind = A.InOutDetailKind,    
                LotNo = A.LotNo,    
                SerialNo = A.SerialNo,    
                IsStockSales = A.IsStockSales,    
                OriUnitSeq = A.OriUnitSeq,  
                OriItemSeq = A.OriItemSeq,    
                OriQty = A.OriQty,    
                OriSTDQty = A.OriSTDQty,    
                OriLotNo = A.OriLotNo,    
                LastUserSeq  = @UserSeq,      
                LastDateTime = GETDATE(),  
                PJTSeq = A.PJTSeq,  
                PgmSeq = @PgmSeq  
           FROM #TLGInOutDailyItem AS A        
                JOIN _TLGInOutDailyItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq        
                                                     AND B.InOutType   = A.InOutType        
                                                     AND B.InOutSeq   = A.InOutSeq        
                                                     AND B.InOutSerl  = A.InOutSerl      
           WHERE A.WorkingTag = 'U' AND A.Status = 0      
   
         IF @@ERROR <> 0          
         BEGIN          
             RETURN          
         END        
    
         INSERT #TLGInOutMonth    
         (              InOut           ,        InOutYM          ,        WHSeq           ,        FunctionWHSeq   ,    
                        ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,    
                        ADD_DEL)    
         SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,    
                        B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,    
                        -1    
           FROM #TLGInOutDailyItem AS A        
                JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq        
                                                      AND B.InOutType  = A.InOutType        
                                                      AND B.InOutSeq   = A.InOutSeq        
                                                      AND B.InOutSerl  = A.InOutSerl      
          WHERE A.WorkingTag = 'U' AND A.Status = 0         
        
         DELETE _TLGInOutStock       
           FROM #TLGInOutDailyItem AS A        
                JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq        
                                                     AND B.InOutType   = A.InOutType        
                                                     AND B.InOutSeq   = A.InOutSeq        
                                                     AND B.InOutSerl  = A.InOutSerl    
          WHERE A.WorkingTag = 'U' AND A.Status = 0         
       
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
          EXEC    _SLGCreateDataForInOutLotStock @CompanySeq, 'U', @LanguageSeq, @PgmSeq      
          INSERT #TLGInOutMonthLot      
         (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,   LotNo,   
                        ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,      
                        ADD_DEL)      
         SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,   B.LotNo,  
                        B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,      
                        -1      
           FROM  #TLGInOutDailyItem AS A          
                 JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq          
                                                      AND B.InOutType  = A.InOutType          
                                                      AND B.InOutSeq   = A.InOutSeq          
                                                      AND B.InOutSerl  = A.InOutSerl        
          WHERE  A.WorkingTag = 'U' AND A.Status = 0           
     
         
         DELETE _TLGInOutLotStock         
           FROM #TLGInOutDailyItem AS A          
                  JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq          
                                                     AND B.InOutType   = A.InOutType          
                                                     AND B.InOutSeq   = A.InOutSeq          
                                                     AND B.InOutSerl  = A.InOutSerl      
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
     IF EXISTS (SELECT 1 FROM #TLGInOutDailyItem WHERE WorkingTag = 'A' AND Status = 0 )        
     BEGIN        
         TRUNCATE TABLE #TLGInOutStock      
         TRUNCATE TABLE #TLGInOutLotStock      
          EXEC  _SLGCreateDataForInOutStock @CompanySeq, 'A'      
         INSERT INTO _TLGInOutDailyItem(        
                 CompanySeq,    
                 InOutType,    
                 InOutSeq,    
                 InOutSerl,    
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
                 IsStockSales,    
                 OriUnitSeq,    
                 OriItemSeq,    
                 OriQty,    
                 OriSTDQty,  OriLotNo,  
                 LastUserSeq,    
                 LastDateTime,  
                 PJTSeq,  
                 PgmSeq)      
         SELECT  @CompanySeq,      
                 InOutType,    
                 InOutSeq,    
                 InOutSerl,    
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
                 IsStockSales,    
                 OriUnitSeq,    
                 OriItemSeq,    
                 OriQty,    
                 OriSTDQty,  OriLotNo,  
                 @UserSeq,      
                 GETDATE(),  
                 PJTSeq,  
                 @PgmSeq      
           FROM #TLGInOutDailyItem A        
          WHERE WorkingTag = 'A' AND Status = 0      
         
         IF @@ERROR <> 0          
         BEGIN          
             RETURN          
         END        
     
         INSERT  _TLGInOutStock    
         SELECT  @CompanySeq, *    
           FROM  #TLGInOutStock    
    
         INSERT  #TLGInOutMonth                
           (        InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,                 
                        ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,                
                        ADD_DEL)                
         SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,                
                        B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,                
                        1                
           FROM  #TLGInOutStock   B                
      
         -- ���⼭ _TLGInOutLotSub�� ���� �־��ش�   
         EXEC  _SLGCreateDataForInOutLotStock @CompanySeq, 'A', @LanguageSeq, @PgmSeq   
          INSERT  _TLGInOutLotStock      
         SELECT  @CompanySeq, *      
           FROM  #TLGInOutLotStock      
     
     
         INSERT  #TLGInOutMonthLot                  
         (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,  LOTNO,                
                        ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,                  
                        ADD_DEL)                  
         SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,  B.LotNo,              
                        B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,                  
                        1                  
           FROM  #TLGInOutLotStock   B                       
     END            
      EXEC _SLGWHStockUPDATE @CompanySeq    
      EXEC _SLGLOTStockUPDATE @CompanySeq    
      EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyItem', @LanguageSeq  
     EXEC _SLGInOutLotMinusCheck @CompanySeq, '#TLGInOutDailyItem', @LanguageSeq  
      
    DECLARE @Status INT   
      
    SELECT @Status = (SELECT MAX(Status) FROM #TLGInOutDailyItem)  
      
      RETURN @Status  