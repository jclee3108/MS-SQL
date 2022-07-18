IF OBJECT_ID('KPXCM_SPUDelvInAutoSave_MES') IS NOT NULL    
    DROP PROC KPXCM_SPUDelvInAutoSave_MES
GO 

-- v2015.09.23 KPXCM MES ��

/************************************************************
 ��  �� - ���� �ڵ��԰� 
 �ۼ��� - 2009�� 10�� 22�� 
 �ۼ��� - ����
 ������ - 2010�� 05�� 06�� UPDATEd BY �ڼҿ� :: �ⳳ���/ ������ �������� �߰�
 ������ - 2012. 1. 2 hkim (�������԰��� �ڵ��԰�� ������ �б��Ͽ� �����ϵ���)
 ************************************************************/
 CREATE PROC dbo.KPXCM_SPUDelvInAutoSave_MES
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
  AS    
     DECLARE @VatAccSeq   INT,
             @QCAutoIn   NCHAR(1),
             @DelvInSeq   INT,
             @DelvInSerl   INT,
             @DelvInNo   NCHAR(12),
 --            @DelvInDate   NCHAR(8),
             @SMImpType   INT,
             @VATEnvSeq   INT,
             @AmtEnvSeq   INT,
             @DomPointEnvSeq  INT,
             @DataSeq   INT 
      -- ���� ����Ÿ ��� ����
     CREATE TABLE #TPUDelvIn (WorkingTag NCHAR(1) NULL)    
     EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUDelvIn'    
     IF @@ERROR <> 0 RETURN    
      CREATE TABLE #TPUDelvInItem (WorkingTag NCHAR(1) NULL)  
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2608, 'DataBlock2', '#TPUDelvInItem'     
     IF @@ERROR <> 0 RETURN    
      -- ȯ�漳���� ��������  # ���˻�ǰ �ڵ��԰� ����
     --EXEC dbo._SCOMEnv @CompanySeq,6500,@UserSeq,@@PROCID,@QCAutoIn OUTPUT  
      -- ���˻�ǰ�� �̰˻�ǰ�� ���� ���� ��� �ڵ��԰� ��� X
 --     IF EXISTS (SELECT 1 FROM _TPUDelvItem      AS A
 --                              JOIN #TPUDelvItem AS B ON A.DelvSeq = B.DelvSeq
 --                        WHERE A.CompanySeq = @CompanySeq
 --                          AND A.SMQCType <> '6035001')
 --         SELECT @QCAutoIn = '0'
     -- �ڵ��԰� �ƴ� ��� �׳� ����
     --IF ISNULL(@QCAutoIn, '0') NOT IN ('1','True')
     --BEGIN
     --    SELECT * FROM #TPUDelvIn
     --    RETURN
     --END 
      SELECT * INTO #TPUDelvIn_Result FROM #TPUDelvIn
      -- ������� ���̺�
     CREATE TABLE #SCOMSourceDailyBatch 
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
     -- ��� �ݿ�
     Create Table #TLGInOutMinusCheck  
     (    
         WHSeq           INT,  
         FunctionWHSeq   INT,  
         ItemSeq         INT
     )  
      CREATE TABLE #TLGInOutDailyBatch
     (   
         InOutType    INT     ,
         InOutSeq     INT     ,
         Result       NVARCHAR(250),
         MessageType  INT     ,
         Status       INT
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
      CREATE TABLE #TMP_Item_Prog
     (
         IDX_NO      INT,
         OrderSeq    INT,
         OrderSerl   INT,
         Qty         DECIMAL(19, 5),
         STDQty      DECIMAL(19, 5)
     ) 
     -- ���� �������� ���̺�
     CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))    
           
     CREATE TABLE #Temp_Order(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT,IsDelvIn NCHAR(1))            
     
     CREATE TABLE #TCOMProgressTracking(IDX_NO INT, IDOrder INT, Seq INT,Serl INT, SubSerl INT,Qty DECIMAL(19, 5), StdQty DECIMAL(19,5) , Amt    DECIMAL(19, 5),VAT DECIMAL(19,5))      
     
     CREATE TABLE #OrderTracking(IDX_NO INT, Qty DECIMAL(19,5), POCurAmt DECIMAL(19,5))
  
  
     -- ���հ�, �̰˻�ǰ�� ������ ǰ�� �ڵ��԰�
     DELETE #TPUDelvIn
       FROM #TPUDelvIn        AS A
            JOIN _TPUDelvItem AS B ON A.DelvSeq  = B.DelvSeq
                                   AND A.DelvSerl = B.DelvSerl
      WHERE B.CompanySeq = @CompanySeq
        AND B.SMQCType IN (6035002, 6035004)
        AND A.SourceType = '1'
        AND A.WorkingTag IN ('A', 'U')
        
  -- �˻� �� ���հݰ� ����
     DELETE #TPUDelvIn
       FROM #TPUDelvIn        AS A
            JOIN _TPUDelvItem AS B ON A.DelvSeq  = B.DelvSeq
                                   AND A.DelvSerl = B.DelvSerl
      WHERE B.CompanySeq = @CompanySeq
        AND B.SMQCType IN (6035004)
        AND A.SourceType = '1'
        AND A.WorkingTag IN ('A', 'U')
      -- �ڵ��԰� �̻�� ǰ�� ����
     DELETE #TPUDelvIn
       FROM #TPUDelvIn        AS A
            JOIN _TPUDelvItem AS B ON A.DelvSeq  = B.DelvSeq
                                  AND A.DelvSerl = B.DelvSerl
            LEFT OUTER JOIN _TPDBaseItemQCType AS C ON B.CompanySeq = C.CompanySeq
                                                   ANd B.ItemSeq    = C.ItemSeq
      WHERE B.CompanySeq = @CompanySeq
        AND A.SourceType = '1' 
        AND A.WorkingTag IN ('A', 'U')
        AND C.IsNotAutoIn = '1'
      DELETE #TPUDelvIn
       FROM #TPUDelvIn    AS A
      WHERE A.SourceType <> '1'
        AND A.WorkingTag IN ('A', 'U')
      DELETE #TPUDelvIn
       FROM #TPUDelvIn                         AS A
            JOIN _TPUDelvItem                  AS B ON A.DelvSeq  = B.DelvSeq
                                                   AND A.DelvSerl = B.DelvSerl
            LEFT OUTER JOIN _TPDBaseItemQCType AS C ON B.CompanySeq = C.CompanySeq
                                                   ANd B.ItemSeq    = C.ItemSeq
      WHERE B.CompanySeq = @CompanySeq
        AND A.SourceType = '1'
        AND A.WorkingTag IN ('A', 'U')
        AND C.IsNotAutoIn = '1'
      DELETE #TPUDelvIn
       FROM #TPUDelvIn        AS A
            JOIN _TPUDelvItem AS B ON A.DelvSeq  = B.DelvSeq
                                  AND A.DelvSerl = B.DelvSerl
            LEFT OUTER JOIN _TPDBaseItemQCType AS C ON B.CompanySeq = C.CompanySeq
                                                   ANd B.ItemSeq    = C.ItemSeq
      WHERE B.CompanySeq = @CompanySeq
        AND A.SourceType IS NULL
        AND C.IsNotAutoIn = '1'
        AND A.WorkingTag IN ('A', 'U')
      -- �ڵ��԰��� ǰ���� ���� ��� ����
     IF NOT EXISTS (SELECT 1 FROM #TPUDelvIn)
     BEGIN
         SELECT *  FROM #TPUDelvIn_Result
          RETURN
     END
      -- ����/������ �� ��� �԰��ڵ带 ã�Ƽ� ���� �� ����
     IF EXISTS (SELECT 1 FROM #TPUDelvIn WHERE WorkingTag IN ('U','D') AND Status = 0)
     BEGIN
     /********************************
         �԰� ���� ����
     *********************************/    
         INSERT #TMP_PROGRESSTABLE     
         SELECT 1, '_TPUDelvInItem'               -- �����԰�
      -- ���ų�ǰ
 --     INSERT INTO #Temp_Order(OrderSeq, OrderSerl, IsDelvIn)    
 --     SELECT  A.DelvSeq, A.DelvSerl, '2'    
 --       FROM #TPUDelvItem AS A WITH(NOLOCK)     
 --      WHERE A.WorkingTag IN ('U', 'D')
 --        AND A.Status = 0
 --        AND A.SMQCType = '6035001'
      INSERT INTO #TMP_Item_Prog
         SELECT IDX_NO, DelvSeq, DelvSerl, SUM(Qty), SUM(STDQty)
           FROM #TPUDelvIn    
          WHERE WorkingTag IN ('U','D')  
            AND SourceType IS NULL OR SourceType = '1'
     AND Status = 0  
       GROUP BY IDX_NO, DelvSeq, DelvSerl
          EXEC _SCOMProgressTracking @CompanySeq, '_TPUDelvItem', '#TMP_Item_Prog', 'OrderSeq', 'OrderSerl', ''           
     /********************************
         ���� ���� ���� üũ(Ÿ�ý��� ����� �����ʹ� ����/���� ���� ����
     *********************************/    
         --- #TCOMProgressTracking �÷� �߰�
         ALTER TABLE #TCOMProgressTracking ADD MessageType INT null
         ALTER TABLE #TCOMProgressTracking ADD Status INT null
         ALTER TABLE #TCOMProgressTracking ADD Result NVARCHAR(250) null
          UPDATE   #TCOMProgressTracking
            SET   MessageType = 0, Status = 0, Result = ''
            
   INSERT INTO #TPUDelvInItem(IDX_NO, WorkingTag, DelvInSeq, DelvInSerl, Status)
   SELECT A.IDX_NO, B.WorkingTag, A.Seq, A.Serl, B.Status
     FROM #TCOMProgressTracking AS A 
       JOIN #TPUDelvIn   AS B ON A.IDX_NO = B.IDX_NO
  
        -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)      
     EXEC _SCOMLog  @CompanySeq,
                    @UserSeq,
                    '_TPUDelvIn', 
                    '#TPUDelvInItem',
                    'DelvInSeq',
                    'CompanySeq,DelvInSeq,BizUnit,DelvInNo,SMImpType,DelvInDate,DeptSeq,EmpSeq,CustSeq,Remark,TaxDate,PayDate,IsPJT,IsReturn,IsRetroACT,SMWareHouseType,CurrSeq,ExRate,LastUserSeq,LastDateTime'       
      -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
     EXEC _SCOMLog  @CompanySeq,
                    @UserSeq,
                    '_TPUDelvInItem', 
                    '#TPUDelvInItem',
                    'DelvInSeq, DelvInSerl',
                    'CompanySeq,DelvInSeq,DelvInSerl,SMImpType,SMDelvType,SMStkType,ItemSeq,UnitSeq,Price,DomPrice,Qty,CurAmt,DomAmt,StdUnitSeq,StdUnitQty,IsVAT,CurVAT,DomVAT,WHSeq,SalesCustSeq,DelvCustSeq,LOTNo,FromSerial,ToSerial,SMPayType,AccSeq,AntiAccSeq,IsFiction,FicRateNum,FicRateDen,EvidSeq,PJTSeq,WBSSeq,Remark,IsReturn,SlipSeq,TaxDate,PayDate,SourceType,SourceSeq,SourceSerl,LastUserSeq,LastDateTime'
   
   -- ��ǥ ���� �Ȱ��� ���� ���� �ʵ��� ����
   EXEC _SPUDelvInItemCheck @xmlDocument    = N''           ,
          @xmlFlags       = @xmlFlags     ,
          @ServiceSeq     = 2608   ,
          @WorkingTag     = 'AUTO'  ,
          @CompanySeq     = @CompanySeq   ,
          @LanguageSeq    = @LanguageSeq  ,
          @UserSeq        = @UserSeq      ,
          @PgmSeq         = @PgmSeq
   IF @@ERROR <> 0 RETURN  
   -- üũ �� ���� �߻���
   IF EXISTS (SELECT 1 FROM #TPUDelvInItem WHERE Status <> 0)
   BEGIN
             UPDATE  #TPUDelvIn_Result
                SET  Result        = B.Result     ,
                     MessageType   = B.MessageType, 
                     Status        = B.Status
               FROM  #TPUDelvIn_Result A
                     JOIN #TPUDelvInItem B ON A.IDX_NO = B.IDX_NO
                     
             SELECT  *  FROM  #TPUDelvIn_Result
             RETURN
   END          
   -- ���� �߻� �ȵǾ����� ���̺� ����
   DELETE FROM #TPUDelvInItem
   
         EXEC _SCOMDeleteCHECKForConnectSP @CompanySeq, '_TPUDelvInItem', '#TCOMProgressTracking', 'Seq', 'Serl', '', @LanguageSeq
         
         IF EXISTS(SELECT 1 FROM #TCOMProgressTracking WHERE Status <> 0)
         BEGIN
             UPDATE  #TPUDelvIn_Result
                SET  Result        = B.Result     ,
                     MessageType   = B.MessageType, 
                     Status        = B.Status
               FROM  #TPUDelvIn_Result A
                     JOIN #TCOMProgressTracking B ON A.IDX_NO = B.IDX_NO
             SELECT  *  FROM  #TPUDelvIn_Result
             RETURN
         END
  -------------------------------------------------------------------------------------------------
          -- ���࿬�����(���ų�ǰ => �����԰�)  
         INSERT INTO #SComSourceDailyBatch  
         SELECT '_TPUDelvInItem', P.Seq  , P.Serl  , 0,   
                '_TPUDelvItem'  , A.OrderSeq , A.OrderSerl, 0,  
                B.ToQty, B.ToSTDQty , B.ToAmt , B.ToVAT,
                B.FromQty, ISNULL(B.FromSTDQty, 0),  B.FromAmt , B.FromVAT
           FROM #TMP_Item_Prog               AS A  
                JOIN #TCOMProgressTracking   AS P ON A.IDX_NO = P.IDX_NO
                JOIN _TCOMSourceDaily  AS B ON A.OrderSeq = B.FromSeq
             AND A.OrderSerl = B.FromSerl
             AND P.Seq  = B.ToSeq
             AND P.Serl  = B.ToSerl
    WHERE B.CompanySeq   = @CompanySeq            
      AND B.FromTableSeq = 10
      AND B.ToTableSeq   = 9
 --          WHERE A.WorkingTag IN ('U','D')  
 --            AND A.SourceType IS NULL OR A.SourceType = '1'
 --            AND A.Status = 0  
          -- �������
         EXEC _SComSourceDailyBatch 'D', @CompanySeq, @UserSeq  
         IF @@ERROR <> 0 RETURN    
          -- ���һ���
         INSERT INTO #TLGInOutDailyBatch  
         SELECT DISTINCT 170, A.Seq, '', 0, 0  
           FROM #TCOMProgressTracking    AS A
             JOIN #TPUDelvIn             AS D ON A.IDX_NO = D.IDX_NO
          WHERE D.WorkingTag IN ('U','D')
          EXEC _SLGInOutDailyDELETE @CompanySeq
          -- �԰�ǰ�� ���̺� ����
         DELETE _TPUDelvInItem 
           FROM _TPUDelvInItem  AS A
                JOIN #TCOMProgressTracking AS P ON A.DelvInSeq  = P.Seq
                                               AND A.DelvInSerl = P.Serl
          WHERE A.CompanySeq = @CompanySeq
          -- �԰����� ���̺� ����
         DELETE _TPUDelvIn
           FROM _TPUDelvIn  AS A
                JOIN #TCOMProgressTracking AS P ON A.DelvInSeq  = P.Seq
          WHERE A.CompanySeq = @CompanySeq
            AND NOT EXISTS (SELECT 1 FROM _TPUDelvInItem WHERE CompanySeq = @CompanySeq AND DelvInSeq = A.DelvInSeq)
          -- �԰��������̺� ����
         DELETE _TPUBuyingAcc
           FROM _TPUBuyingAcc AS A
                JOIN #TCOMProgressTracking AS P ON A.SourceSeq  = P.Seq
                                               AND A.SourceSerl = P.Serl
                                               AND A.SourceType = '1'
          WHERE A.CompanySeq = @CompanySeq
          -- ������ ��� üũ�� ���ؼ� DelvInSeq�� �־��ش�
         UPDATE #TPUDelvIn_Result
            SET DelvInSeq    = B.Seq, 
                DelvInSerl   = B.Serl
           FROM #TPUDelvIn_Result            AS A
                JOIN #TCOMProgressTracking   AS B ON A.IDX_NO = B.IDX_NO 
          WHERE A.WorkingTag IN ('D')               
     END
      -- �԰�ǰ���� 2�� �̻��� ���(�ڵ��԰�� ���ٷ�)
      IF NOT EXISTS (SELECT 1 FROM #TPUDelvIn WHERE WorkingTag IN ('A', 'U') AND Status = 0 AND SourceType IS NOT NULL)
      BEGIN
         SET ROWCOUNT 1
          TRUNCATE TABLE #TPUDelvIn
         INSERT INTO #TPUDelvIn
         SELECT * FROM #TPUDelvIn_Result
          SET ROWCOUNT 0
      END
      -- �˻� ���� ��� (�ϰ��˻�ó���� �������� �� �� �����Ƿ� �����ٷ�)
      ELSE 
      BEGIN
         TRUNCATE TABLE #TPUDelvIn
         INSERT INTO #TPUDelvIn
         SELECT * FROM #TPUDelvIn_Result
          SET ROWCOUNT 0
  END     
  
     UPDATE #TPUDelvIn
        SET DelvInDate = D.DelvDate
       FROM #TPUDelvIn    AS I
            JOIN _TPUDelv AS D ON I.DelvSeq = D.DelvSeq
      WHERE D.CompanySeq = @CompanySeq
     AND I.WorkingTag IN ('A', 'U')
        AND I.Status     = 0
        --AND (I.DelvInDate IS NULL OR ISNULL(I.DelvInDate, '') = '')
  
  --�˻� �հݰ��� �԰����� �˻��Ϸ� ����
  UPDATE #TPUDelvIn
     SET DelvInDate = B.TestEndDate
    FROM #TPUDelvIn AS A
      JOIN _TPDQCTestReport AS B ON A.DelvSeq  = B.SourceSeq
           AND A.DelvSerl = B.SourceSerl
   WHERE B.CompanySeq = @CompanySeq
     AND A.WorkingTag IN ('A', 'U')
     AND A.Status  = 0
     AND B.SourceType = '1'
     
     UPDATE #TPUDelvIn
        SET WorkingTag = 'A'
      WHERE WorkingTag = 'U'
     
     -- �԰����� üũ
     EXEC _SPUDelvInCheck    @xmlDocument = N''            ,
                             @xmlFlags    = @xmlFlags      ,
 @ServiceSeq  = 2608           ,
                             @WorkingTag  = 'AUTO'         ,
                             @CompanySeq  = @CompanySeq    ,
                             @LanguageSeq = @LanguageSeq   ,
                             @UserSeq     = @UserSeq       ,
                             @PgmSeq      = @PgmSeq
     IF @@ERROR <> 0 RETURN
      SELECT DISTINCT DelvSeq, DelvInSeq, DelvInNo, DelvInDate
       INTO #DelvIn
       FROM #TPUDelvIn
      WHERE WorkingTag IN ('A', 'U')
        AND Status = 0
        
     -- �԰��ڵ� ������Ʈ
     UPDATE #TPUDelvIn_Result
     SET DelvInSeq = B.DelvInSeq
    FROM #TPUDelvIn_Result AS A
      JOIN #TPUDelvIn  AS B ON A.IDX_NO = B.IDX_NO
      WHERE A.WorkingTag IN ('A', 'U')
      
     -- �˻��ϰ� ó������ ��by������ ó��
  IF (SELECT COUNT(*) FROM #TPUDelvIn) > 1
  BEGIN  
   SELECT @DataSeq = 0
   WHILE ( 1 > 0 )
   BEGIN
             SELECT TOP 1 @DataSeq = DataSeq    
             FROM #TPUDelvIn        
              WHERE WorkingTag IN ('A', 'U')  
                AND Status = 0        
                AND DataSeq > @DataSeq        
              ORDER BY DataSeq        
              IF @@ROWCOUNT = 0 BREAK     
             
    INSERT INTO _TPUDelvIn(CompanySeq, DelvInSeq, BizUnit    , DelvInNo    , SMImpType  , DelvInDate, DeptSeq   , EmpSeq,
            CustSeq   , Remark   , TaxDate    , PayDate     , IsPJT      , IsReturn  , IsRetroACT, SMWareHouseType,
            CurrSeq   , ExRate   , LastUserSeq, LastDateTime, DtiProcType)
    SELECT @CompanySeq, B.DelvInSeq, A.BizUnit, B.DelvInNo, A.SMImpType, B.DelvInDate, A.DeptSeq, A.EmpSeq,
        A.CustSeq  , A.Remark   , ''       , ''        , A.IsPJT    , A.IsReturn                      , ''       , ''      ,
        A.CurrSeq  , A.ExRate   , @UserSeq , GETDATE() , ''
      FROM _TPUDelv     AS A WITH(NOLOCK)
        JOIN #TPUDelvIn AS B ON A.DelvSeq = B.DelvSeq
     WHERE A.CompanySeq = @CompanySeq
       AND B.DataSeq = @DataSeq
       
    UPDATE #TPUDelvIn
       SET DelvInSerl = IDX_NO + 1
     WHERE WorkingTag IN ('A', 'U')
       AND Status     = 0
     -- �����ڱ��� ��������
    SELECT @SMImpType = SMImpType 
      FROM _TPUDelv     AS A WITH(NOLOCK)
        JOIN #DelvIn AS B ON A.DelvSeq = B.DelvSeq
     WHERE A.CompanySeq = @CompanySeq
     -- �԰������ ���(���������� �ƴ� ��)
    INSERT INTO #TPUDelvInItem(DelvInSeq  , DelvInSerl, SMImpType , SMDelvType, SMStkType, ItemSeq   , UnitSeq  , Price     , DomPrice    , Qty        ,
             CurAmt     , DomAmt    , StdUnitSeq, StdUnitQty, IsVAT    , CurVAT    , DomVAT   , WHSeq     , SalesCustSeq, DelvCustSeq,
             LOTNo      , FromSerial, ToSerial  , SMPayType , IsFiction, FicRateNum, FicRateDen  , EvidSeq    , -- AccSeq   , AntiAccSeq, 
             PJTSeq     , WBSSeq    , Remark    , IsReturn  , SlipSeq  , SourceType, SourceSeq   , SourceSerl , -- TaxDate   , PayDate  , 
             WorkingTag , Status    , IDX_NO    , Result    , MessageType, DataSeq, CurrSeq, ExRate, SMPriceType  ) -- , FromSeq   , FromSerl 
    SELECT C.DelvInSeq, 0, E.SMImpType, 0, 0, A.ItemSeq, A.UnitSeq, A.Price, A.DomPrice, B.Qty, 
        -- �ݾ�
        CASE WHEN A.Qty = B.Qty THEN A.CurAmt 
            ELSE CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.Price,0) ) * 100 / (100 + ISNULL(Rate.VatRate,0) )
                       ELSE (ISNULL(B.Qty,0) * ISNULL(A.Price,0) ) END
        END,
        -- ��ȭ�ݾ�
        CASE WHEN A.Qty = B.Qty THEN A.DomAmt
            ELSE CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0) ) * 100 / (100 + ISNULL(Rate.VatRate,0) )
           ELSE                             (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0) )  
            END
        END,                          
        A.StdUnitSeq, A.StdUnitQty, A.IsVAT, 
        -- �ΰ���
        CASE WHEN A.Qty = B.Qty THEN A.CurVAT 
            ELSE CASE @SMImpType WHEN 8008001 THEN CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.Price,0)) -  (ISNULL(B.Qty,0) * ISNULL(A.Price,0) ) * 100 / (100 + ISNULL(Rate.VatRate,0) )
                      ELSE                             (ISNULL(B.Qty,0) * ISNULL(A.Price,0)) / ISNULL(Rate.VatRate,0)
                      END
          ELSE 0 END
        END,
        -- ��ȭ�ΰ���
        CASE WHEN A.Qty = B.Qty THEN A.DomVAT 
            ELSE CASE @SMImpType WHEN 8008001 THEN CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0)) -  (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0) ) * 100 / (100 + ISNULL(Rate.VatRate,0) )
                      ELSE                             (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0)) / ISNULL(Rate.VatRate,0)
                      END
          ELSE 0 END
        END,
        A.WHSeq, A.SalesCustSeq, A.DelvCustSeq, 
        A.LOTNo    , A.FromSerial, A.ToSerial, 0, 
   --            CASE ISNULL(A.AccSeq, 0) WHEN 0 THEN T.AccSeq ELSE ISNULL(A.AccSeq, 0) END AS AccSeq,
   --            CASE ISNULL(A.AntiAccSeq, 0) WHEN 0 THEN TT.AccSeq ELSE ISNULL(A.AntiAccSeq, 0) END AS AntiAccSeq,
        A.IsFiction, A.FicRateNum, A.FicRateDen, A.EvidSeq,
        A.PJTSeq, A.WBSSeq, A.Remark, A.IsReturn, 0, '',  A.DelvSeq, A.DelvSerl,  -- '', '', 
        'A', 0, @DataSeq, B.Result, B.MessageType, @DataSeq,--(ROW_NUMBER() OVER(ORDER BY @CompanySeq)), B.Result, B.MessageType, (ROW_NUMBER() OVER(ORDER BY @CompanySeq)),
        E.CurrSeq, E.ExRate, A.SMPriceType
      FROM _TPUDelvItem     AS A
        JOIN #TPUDelvIn_Result  AS B ON A.DelvSeq  = B.DelvSeq
           AND A.DelvSerl = B.DelvSerl
        JOIN #TPUDelvIn     AS C ON A.DelvSeq  = C.DelvSeq
        JOIN _TPUDelv AS E ON E.CompanySeq = @CompanySeq
           AND C.DelvSeq  = E.DelvSeq
        LEFT OUTER JOIN _TDAItem AS D ON A.CompanySeq = D.CompanySeq
             AND A.ItemSeq    = D.ItemSeq
        LEFT OUTER JOIN _TDAItemAssetAcc AS S ON D.CompanySeq = S.CompanySeq
               AND D.AssetSeq   = S.AssetSeq
               AND S.AssetAccKindSeq = 1
        LEFT OUTER JOIN _TDAAccount      AS T ON S.CompanySeq = T.CompanySeq
               AND S.AccSeq     = T.AccSeq  
        LEFT OUTER JOIN _TDAItemAssetAcc AS SS ON D.CompanySeq = SS.CompanySeq
                AND D.AssetSeq   = SS.AssetSeq
                AND S.AssetAccKindSeq = 9
        LEFT OUTER JOIN _TDAAccount      AS TT ON S.CompanySeq = TT.CompanySeq
                AND S.AccSeq     = TT.AccSeq
                 LEFT OUTER JOIN _TDAItemSales    AS Sales ON A.CompanySeq = Sales.CompanySeq
                            AND A.ItemSeq    = Sales.ItemSeq
                 LEFT OUTER JOIN _TDAVATRate  AS Rate  ON Sales.CompanySeq = Rate.CompanySeq
                               AND E.DelvDate >= Rate.SDate
                               AND E.DelvDate <= Rate.EDate
                               AND Sales.SMVatType = Rate.SMVatType 
     WHERE A.CompanySeq = @CompanySeq
       AND A.SMQCType NOT IN (6035002, 6035004)
       AND B.DataSeq = @DataSeq 
       AND C.DataSeq = @DataSeq 
       AND ISNULL(A.IsFiction, '0') <> '1'
     -- �԰������ ���(���������� ��)
    INSERT INTO #TPUDelvInItem(DelvInSeq  , DelvInSerl, SMImpType , SMDelvType, SMStkType, ItemSeq   , UnitSeq  , Price     , DomPrice    , Qty        ,
             CurAmt     , DomAmt    , StdUnitSeq, StdUnitQty, IsVAT    , CurVAT    , DomVAT   , WHSeq     , SalesCustSeq, DelvCustSeq,
             LOTNo      , FromSerial, ToSerial  , SMPayType , IsFiction, FicRateNum, FicRateDen  , EvidSeq    , -- AccSeq   , AntiAccSeq, 
             PJTSeq     , WBSSeq    , Remark    , IsReturn  , SlipSeq  , SourceType, SourceSeq   , SourceSerl , -- TaxDate   , PayDate  , 
             WorkingTag , Status    , IDX_NO    , Result    , MessageType, DataSeq, CurrSeq, ExRate, SMPriceType ) -- , FromSeq   , FromSerl 
    SELECT C.DelvInSeq, 0, E.SMImpType, 0, 0, A.ItemSeq, A.UnitSeq, A.Price, A.DomPrice, B.Qty, 
        -- �ݾ�
        CASE WHEN A.Qty = B.Qty THEN A.CurAmt 
            ELSE CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.Price,0) ) * 100 / (100 + (A.FicRateDen/A.FicRateNum))
                       ELSE (ISNULL(B.Qty,0) * ISNULL(A.Price,0) ) END
        END,
        -- ��ȭ�ݾ�
        CASE WHEN A.Qty = B.Qty THEN A.DomAmt
            ELSE CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0) ) * 100 / (100 + (A.FicRateDen/A.FicRateNum))
           ELSE                             (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0) )  
            END
        END,                          
        A.StdUnitSeq, A.StdUnitQty, A.IsVAT, 
        -- �ΰ���
        CASE WHEN A.Qty = B.Qty THEN A.CurVAT 
            ELSE CASE @SMImpType WHEN 8008001 THEN CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.Price,0)) -  (ISNULL(B.Qty,0) * ISNULL(A.Price,0) ) * 100 / (100 + (A.FicRateDen/A.FicRateNum))
                      ELSE                             (ISNULL(B.Qty,0) * ISNULL(A.Price,0)) / (A.FicRateNum/A.FicRateDen)
                      END
          ELSE 0 END
        END,
        -- ��ȭ�ΰ���
        CASE WHEN A.Qty = B.Qty THEN A.DomVAT 
            ELSE CASE @SMImpType WHEN 8008001 THEN CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0)) -  (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0) ) * 100 / (100 + (A.FicRateDen/A.FicRateNum))
                      ELSE                             (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0)) / (A.FicRateNum/A.FicRateDen)
                      END
          ELSE 0 END
        END,
        A.WHSeq, A.SalesCustSeq, A.DelvCustSeq, 
        A.LOTNo    , A.FromSerial, A.ToSerial, 0, 
   --            CASE ISNULL(A.AccSeq, 0) WHEN 0 THEN T.AccSeq ELSE ISNULL(A.AccSeq, 0) END AS AccSeq,
   --            CASE ISNULL(A.AntiAccSeq, 0) WHEN 0 THEN TT.AccSeq ELSE ISNULL(A.AntiAccSeq, 0) END AS AntiAccSeq,
        A.IsFiction, A.FicRateNum, A.FicRateDen, A.EvidSeq,
        A.PJTSeq, A.WBSSeq, A.Remark, A.IsReturn, 0, '',  A.DelvSeq, A.DelvSerl,  -- '', '', 
        'A', 0, @DataSeq, B.Result, B.MessageType, @DataSeq,--(ROW_NUMBER() OVER(ORDER BY @CompanySeq)), B.Result, B.MessageType, (ROW_NUMBER() OVER(ORDER BY @CompanySeq)),
        E.CurrSeq, E.ExRate, A.SMPriceType
      FROM _TPUDelvItem     AS A
        JOIN #TPUDelvIn_Result  AS B ON A.DelvSeq  = B.DelvSeq
           AND A.DelvSerl = B.DelvSerl
        JOIN #TPUDelvIn     AS C ON A.DelvSeq  = C.DelvSeq
        JOIN _TPUDelv AS E ON E.CompanySeq = @CompanySeq
           AND C.DelvSeq  = E.DelvSeq
        LEFT OUTER JOIN _TDAItem AS D ON A.CompanySeq = D.CompanySeq
             AND A.ItemSeq    = D.ItemSeq
        LEFT OUTER JOIN _TDAItemAssetAcc AS S ON D.CompanySeq = S.CompanySeq
               AND D.AssetSeq   = S.AssetSeq
               AND S.AssetAccKindSeq = 1
        LEFT OUTER JOIN _TDAAccount      AS T ON S.CompanySeq = T.CompanySeq
               AND S.AccSeq     = T.AccSeq  
        LEFT OUTER JOIN _TDAItemAssetAcc AS SS ON D.CompanySeq = SS.CompanySeq
                AND D.AssetSeq   = SS.AssetSeq
                AND S.AssetAccKindSeq = 9
        LEFT OUTER JOIN _TDAAccount      AS TT ON S.CompanySeq = TT.CompanySeq
                AND S.AccSeq     = TT.AccSeq 
     WHERE A.CompanySeq = @CompanySeq
       AND A.SMQCType NOT IN (6035002, 6035004)
       AND B.DataSeq = @DataSeq 
       AND C.DataSeq = @DataSeq  
       AND ISNULL(A.IsFiction, '0') = '1'          
   END
  END
  ELSE
  BEGIN
   -- �԰����� ����
   INSERT INTO _TPUDelvIn(CompanySeq, DelvInSeq, BizUnit    , DelvInNo    , SMImpType  , DelvInDate, DeptSeq   , EmpSeq,
           CustSeq   , Remark   , TaxDate    , PayDate     , IsPJT      , IsReturn  , IsRetroACT, SMWareHouseType,
           CurrSeq   , ExRate   , LastUserSeq, LastDateTime, DtiProcType)
   SELECT @CompanySeq, B.DelvInSeq, A.BizUnit, B.DelvInNo, A.SMImpType, B.DelvInDate, A.DeptSeq, A.EmpSeq,
       A.CustSeq  , A.Remark   , ''       , ''        , A.IsPJT    , A.IsReturn                      , ''       , ''      ,
       A.CurrSeq  , A.ExRate   , @UserSeq , GETDATE() , ''
     FROM _TPUDelv     AS A WITH(NOLOCK)
       JOIN #DelvIn AS B ON A.DelvSeq = B.DelvSeq
    WHERE A.CompanySeq = @CompanySeq
    
   UPDATE #TPUDelvIn
      SET DelvInSerl = IDX_NO + 1
    WHERE WorkingTag IN ('A', 'U')
      AND Status     = 0
    -- �����ڱ��� ��������
   SELECT @SMImpType = SMImpType 
     FROM _TPUDelv     AS A WITH(NOLOCK)
       JOIN #DelvIn AS B ON A.DelvSeq = B.DelvSeq
    WHERE A.CompanySeq = @CompanySeq
    
   -- �԰������ ���(���������� �ƴ� ��)
   INSERT INTO #TPUDelvInItem(DelvInSeq  , DelvInSerl, SMImpType , SMDelvType, SMStkType, ItemSeq   , UnitSeq  , Price     , DomPrice    , Qty        ,
            CurAmt     , DomAmt    , StdUnitSeq, StdUnitQty, IsVAT    , CurVAT    , DomVAT   , WHSeq     , SalesCustSeq, DelvCustSeq,
            LOTNo      , FromSerial, ToSerial  , SMPayType , IsFiction, FicRateNum, FicRateDen  , EvidSeq    , -- AccSeq   , AntiAccSeq, 
            PJTSeq     , WBSSeq    , Remark    , IsReturn  , SlipSeq  , SourceType, SourceSeq   , SourceSerl , -- TaxDate   , PayDate  , 
            WorkingTag , Status    , IDX_NO    , Result    , MessageType, DataSeq, CurrSeq, ExRate, SMPriceType ) -- , FromSeq   , FromSerl 
   SELECT C.DelvInSeq, 0, @SMImpType, 0, 0, A.ItemSeq, A.UnitSeq, A.Price, A.DomPrice, B.Qty, 
       -- �ݾ�
       CASE WHEN A.Qty = B.Qty THEN A.CurAmt 
           ELSE CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.Price,0) ) * 100 / (100 + ISNULL(Rate.VatRate,0) )
                      ELSE (ISNULL(B.Qty,0) * ISNULL(A.Price,0) ) END
       END,
       -- ��ȭ�ݾ�
       CASE WHEN A.Qty = B.Qty THEN A.DomAmt
           ELSE CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0) ) * 100 / (100 + ISNULL(Rate.VatRate,0) )
          ELSE                             (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0) )  
           END
       END,                          
       A.StdUnitSeq, A.StdUnitQty, A.IsVAT, 
       -- �ΰ���
       CASE WHEN A.Qty = B.Qty THEN A.CurVAT 
           ELSE CASE @SMImpType WHEN 8008001 THEN CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.Price,0)) -  (ISNULL(B.Qty,0) * ISNULL(A.Price,0) ) * 100 / (100 + ISNULL(Rate.VatRate,0) )
                     ELSE                             (ISNULL(B.Qty,0) * ISNULL(A.Price,0)) / ISNULL(Rate.VatRate,0)
                     END
         ELSE 0 END
       END,
       -- ��ȭ�ΰ���
       CASE WHEN A.Qty = B.Qty THEN A.DomVAT 
           ELSE CASE @SMImpType WHEN 8008001 THEN CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0)) -  (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0) ) * 100 / (100 + ISNULL(Rate.VatRate,0) )
                     ELSE                             (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0)) / ISNULL(Rate.VatRate,0)
                     END
         ELSE 0 END
       END,
       A.WHSeq, A.SalesCustSeq, A.DelvCustSeq, 
       A.LOTNo    , A.FromSerial, A.ToSerial, 0, 
  --            CASE ISNULL(A.AccSeq, 0) WHEN 0 THEN T.AccSeq ELSE ISNULL(A.AccSeq, 0) END AS AccSeq,
  --            CASE ISNULL(A.AntiAccSeq, 0) WHEN 0 THEN TT.AccSeq ELSE ISNULL(A.AntiAccSeq, 0) END AS AntiAccSeq,
       A.IsFiction, A.FicRateNum, A.FicRateDen, A.EvidSeq,
       A.PJTSeq, A.WBSSeq, A.Remark, A.IsReturn, 0, '',  A.DelvSeq, A.DelvSerl,  -- '', '', 
       'A', 0, A.DelvSerl, B.Result, B.MessageType, A.DelvSerl,--(ROW_NUMBER() OVER(ORDER BY @CompanySeq)), B.Result, B.MessageType, (ROW_NUMBER() OVER(ORDER BY @CompanySeq)),
       E.CurrSeq, E.ExRate, A.SMPriceType
     FROM _TPUDelvItem     AS A
       JOIN #TPUDelvIn_Result  AS B ON A.DelvSeq  = B.DelvSeq
          AND A.DelvSerl = B.DelvSerl
       JOIN #DelvIn     AS C ON A.DelvSeq  = C.DelvSeq
       JOIN _TPUDelv AS E ON E.CompanySeq = @CompanySeq
          AND C.DelvSeq  = E.DelvSeq
       LEFT OUTER JOIN _TDAItem AS D ON A.CompanySeq = D.CompanySeq
            AND A.ItemSeq    = D.ItemSeq
       LEFT OUTER JOIN _TDAItemAssetAcc AS S ON D.CompanySeq = S.CompanySeq
              AND D.AssetSeq   = S.AssetSeq
              AND S.AssetAccKindSeq = 1
       LEFT OUTER JOIN _TDAAccount      AS T ON S.CompanySeq = T.CompanySeq
              AND S.AccSeq     = T.AccSeq  
       LEFT OUTER JOIN _TDAItemAssetAcc AS SS ON D.CompanySeq = SS.CompanySeq
               AND D.AssetSeq   = SS.AssetSeq
               AND S.AssetAccKindSeq = 9
       LEFT OUTER JOIN _TDAAccount      AS TT ON S.CompanySeq = TT.CompanySeq
               AND S.AccSeq     = TT.AccSeq 
                LEFT OUTER JOIN _TDAItemSales    AS Sales ON A.CompanySeq = Sales.CompanySeq
                           AND A.ItemSeq    = Sales.ItemSeq
                LEFT OUTER JOIN _TDAVATRate  AS Rate  ON Sales.CompanySeq = Rate.CompanySeq
                              AND E.DelvDate >= Rate.SDate
                               AND E.DelvDate <= Rate.EDate
                              AND Sales.SMVatType = Rate.SMVatType 
    WHERE A.CompanySeq = @CompanySeq
      AND A.SMQCType NOT IN (6035002, 6035004) 
      AND ISNULL(A.IsFiction, '0') <> '1'  
    -- �԰������ ���(���������� ��)
   INSERT INTO #TPUDelvInItem(DelvInSeq  , DelvInSerl, SMImpType , SMDelvType, SMStkType, ItemSeq   , UnitSeq  , Price     , DomPrice    , Qty        ,
            CurAmt     , DomAmt    , StdUnitSeq, StdUnitQty, IsVAT    , CurVAT    , DomVAT   , WHSeq     , SalesCustSeq, DelvCustSeq,
            LOTNo      , FromSerial, ToSerial  , SMPayType , IsFiction, FicRateNum, FicRateDen  , EvidSeq    , -- AccSeq   , AntiAccSeq, 
            PJTSeq     , WBSSeq    , Remark    , IsReturn  , SlipSeq  , SourceType, SourceSeq   , SourceSerl , -- TaxDate   , PayDate  , 
            WorkingTag , Status    , IDX_NO    , Result    , MessageType, DataSeq, CurrSeq, ExRate, SMPriceType ) -- , FromSeq   , FromSerl 
   SELECT C.DelvInSeq, 0, @SMImpType, 0, 0, A.ItemSeq, A.UnitSeq, A.Price, A.DomPrice, B.Qty, 
       -- �ݾ�
       CASE WHEN A.Qty = B.Qty THEN A.CurAmt 
           ELSE CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.Price,0) ) * 100 / (100 + (A.FicRateDen/A.FicRateNum))
                      ELSE (ISNULL(B.Qty,0) * ISNULL(A.Price,0) ) END
       END,
       -- ��ȭ�ݾ�
       CASE WHEN A.Qty = B.Qty THEN A.DomAmt
           ELSE CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0) ) * 100 / (100 + (A.FicRateDen/A.FicRateNum))
          ELSE                             (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0) )  
           END
       END,                          
       A.StdUnitSeq, A.StdUnitQty, A.IsVAT, 
       -- �ΰ���
       CASE WHEN A.Qty = B.Qty THEN A.CurVAT 
           ELSE CASE @SMImpType WHEN 8008001 THEN CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.Price,0)) -  (ISNULL(B.Qty,0) * ISNULL(A.Price,0) ) * 100 / (100 + (A.FicRateDen/A.FicRateNum))
                     ELSE                             (ISNULL(B.Qty,0) * ISNULL(A.Price,0)) / (A.FicRateNum/A.FicRateDen)
                     END
         ELSE 0 END
       END,
       -- ��ȭ�ΰ���
       CASE WHEN A.Qty = B.Qty THEN A.DomVAT 
           ELSE CASE @SMImpType WHEN 8008001 THEN CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0)) -  (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0) ) * 100 / (100 + (A.FicRateDen/A.FicRateNum))
                     ELSE                             (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0)) / (A.FicRateNum/A.FicRateDen)
                     END
         ELSE 0 END
       END,
       A.WHSeq, A.SalesCustSeq, A.DelvCustSeq, 
       A.LOTNo    , A.FromSerial, A.ToSerial, 0, 
  --            CASE ISNULL(A.AccSeq, 0) WHEN 0 THEN T.AccSeq ELSE ISNULL(A.AccSeq, 0) END AS AccSeq,
  --            CASE ISNULL(A.AntiAccSeq, 0) WHEN 0 THEN TT.AccSeq ELSE ISNULL(A.AntiAccSeq, 0) END AS AntiAccSeq,
       A.IsFiction, A.FicRateNum, A.FicRateDen, A.EvidSeq,
       A.PJTSeq, A.WBSSeq, A.Remark, A.IsReturn, 0, '',  A.DelvSeq, A.DelvSerl,  -- '', '', 
       'A', 0, A.DelvSerl, B.Result, B.MessageType, A.DelvSerl,
       E.CurrSeq, E.ExRate, A.SMPriceType
     FROM _TPUDelvItem     AS A
       JOIN #TPUDelvIn_Result  AS B ON A.DelvSeq  = B.DelvSeq
          AND A.DelvSerl = B.DelvSerl
       JOIN #DelvIn     AS C ON A.DelvSeq  = C.DelvSeq
       JOIN _TPUDelv AS E ON E.CompanySeq = @CompanySeq
          AND C.DelvSeq  = E.DelvSeq
       LEFT OUTER JOIN _TDAItem AS D ON A.CompanySeq = D.CompanySeq
            AND A.ItemSeq    = D.ItemSeq
       LEFT OUTER JOIN _TDAItemAssetAcc AS S ON D.CompanySeq = S.CompanySeq
              AND D.AssetSeq   = S.AssetSeq
              AND S.AssetAccKindSeq = 1
       LEFT OUTER JOIN _TDAAccount      AS T ON S.CompanySeq = T.CompanySeq
              AND S.AccSeq     = T.AccSeq  
       LEFT OUTER JOIN _TDAItemAssetAcc AS SS ON D.CompanySeq = SS.CompanySeq
               AND D.AssetSeq   = SS.AssetSeq
               AND S.AssetAccKindSeq = 9
       LEFT  OUTER JOIN _TDAAccount      AS TT ON S.CompanySeq = TT.CompanySeq
               AND S.AccSeq     = TT.AccSeq 
    WHERE A.CompanySeq = @CompanySeq
      AND A.SMQCType NOT IN (6035002, 6035004) 
      AND ISNULL(A.IsFiction, '0') = '1'   
  END
  
     --UPDATE #TPUDelvIn
     --   SET DelvInSerl = IDX_NO + 1
     -- WHERE WorkingTag IN ('A', 'U')
     --   AND Status     = 0
      ---- �����ڱ��� ��������
     --SELECT @SMImpType = SMImpType 
     --  FROM _TPUDelv     AS A WITH(NOLOCK)
     --       JOIN #DelvIn AS B ON A.DelvSeq = B.DelvSeq
     -- WHERE A.CompanySeq = @CompanySeq
  
 --    -- �԰������ ���
 --    INSERT INTO #TPUDelvInItem(DelvInSeq  , DelvInSerl, SMImpType , SMDelvType, SMStkType, ItemSeq   , UnitSeq  , Price     , DomPrice    , Qty        ,
 --                               CurAmt     , DomAmt    , StdUnitSeq, StdUnitQty, IsVAT    , CurVAT    , DomVAT   , WHSeq     , SalesCustSeq, DelvCustSeq,
 --                               LOTNo      , FromSerial, ToSerial  , SMPayType , IsFiction, FicRateNum, FicRateDen  , EvidSeq    , -- AccSeq   , AntiAccSeq, 
 --                               PJTSeq     , WBSSeq    , Remark    , IsReturn  , SlipSeq  , SourceType, SourceSeq   , SourceSerl , -- TaxDate   , PayDate  , 
 --                               WorkingTag , Status    , IDX_NO    , Result    , MessageType, DataSeq, CurrSeq, ExRate  ) -- , FromSeq   , FromSerl 
 --    SELECT C.DelvInSeq, 0, @SMImpType, 0, 0, A.ItemSeq, A.UnitSeq, A.Price, A.DomPrice, B.Qty, 
 --     -- �ݾ�
 --           CASE WHEN A.Qty = B.Qty THEN A.CurAmt 
 --         ELSE CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.Price,0) ) * 100 / (100 + 10 )
 --                       ELSE (ISNULL(B.Qty,0) * ISNULL(A.Price,0) ) END
 --     END,
 --     -- ��ȭ�ݾ�
 --           CASE WHEN A.Qty = B.Qty THEN A.DomAmt
 --         ELSE CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0) ) * 100 / (100 + 10 )
 --                                ELSE                             (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0) )  
 --                           END
 --     END,                          
 --           A.StdUnitSeq, A.StdUnitQty, A.IsVAT, 
 --     -- �ΰ���
 --           CASE WHEN A.Qty = B.Qty THEN A.CurVAT 
 --         ELSE CASE @SMImpType WHEN 8008001 THEN CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.Price,0)) -  (ISNULL(B.Qty,0) * ISNULL(A.Price,0) ) * 100 / (100 + 10 )
 --                   ELSE                             (ISNULL(B.Qty,0) * ISNULL(A.Price,0)) / 10
 --                   END
 --       ELSE 0 END
 --     END,
 --     -- ��ȭ�ΰ���
 --           CASE WHEN A.Qty = B.Qty THEN A.DomVAT 
 --         ELSE CASE @SMImpType WHEN 8008001 THEN CASE WHEN ISNULL(A.IsVAT,'') = '1' THEN (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0)) -  (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0) ) * 100 / (100 + 10 )
 --                   ELSE                             (ISNULL(B.Qty,0) * ISNULL(A.DomPrice,0)) / 10
 --                   END
 --       ELSE 0 END
 --     END,
 --           A.WHSeq, A.SalesCustSeq, A.DelvCustSeq, 
 --           A.LOTNo    , A.FromSerial, A.ToSerial, 0, 
 ----            CASE ISNULL(A.AccSeq, 0) WHEN 0 THEN T.AccSeq ELSE ISNULL(A.AccSeq, 0) END AS AccSeq,
 ----            CASE ISNULL(A.AntiAccSeq, 0) WHEN 0 THEN TT.AccSeq ELSE ISNULL(A.AntiAccSeq, 0) END AS AntiAccSeq,
 --           '', 0, 0, 0,
 --           A.PJTSeq, A.WBSSeq, A.Remark, A.IsReturn, 0, '',  A.DelvSeq, A.DelvSerl,  -- '', '', 
 --           'A', 0, (ROW_NUMBER() OVER(ORDER BY @CompanySeq)), B.Result, B.MessageType, (ROW_NUMBER() OVER(ORDER BY @CompanySeq)),
 --           E.CurrSeq, E.ExRate
 --      FROM _TPUDelvItem     AS A
 --           JOIN #TPUDelvIn_Result  AS B ON A.DelvSeq  = B.DelvSeq
 --                                AND A.DelvSerl = B.DelvSerl
 --           JOIN #DelvIn     AS C ON A.DelvSeq  = C.DelvSeq
 --           JOIN _TPUDelv AS E ON E.CompanySeq = @CompanySeq
 --        AND C.DelvSeq  = E.DelvSeq
 --           LEFT OUTER JOIN _TDAItem AS D ON A.CompanySeq = D.CompanySeq
 --                                         AND A.ItemSeq    = D.ItemSeq
 --           LEFT OUTER JOIN _TDAItemAssetAcc AS S ON D.CompanySeq = S.CompanySeq
 --                                                AND D.AssetSeq   = S.AssetSeq
 --                                                AND S.AssetAccKindSeq = 1
 --           LEFT OUTER JOIN _TDAAccount      AS T ON S.CompanySeq = T.CompanySeq
 --                                                AND S.AccSeq     = T.AccSeq  
 --           LEFT OUTER JOIN _TDAItemAssetAcc AS SS ON D.CompanySeq = SS.CompanySeq
 --                                                 AND D.AssetSeq   = SS.AssetSeq
 --                                                 AND S.AssetAccKindSeq = 9
 --           LEFT OUTER JOIN _TDAAccount      AS TT ON S.CompanySeq = TT.CompanySeq
 --                                                 AND S.AccSeq     = TT.AccSeq 
 --     WHERE A.CompanySeq = @CompanySeq
 --       AND A.SMQCType NOT IN (6035002, 6035004)
  
  
  -- �ⳳ���/ �������� �������� 20100506 �ڼҿ� �߰�
  DECLARE @SMRNPMethod INT, @PayDate NCHAR(8), @CustSeq INT, @DelvInDate NCHAR(8),@SMPayType INT
  ALTER TABLE #TPUDelvInItem ADD SMRNPMethod INT, PayDate NCHAR(8)
      --SELECT @CustSeq =A.CustSeq, 
     --       @DelvInDate = A.DelvDate
     --  FROM #TPUDelvInItem 
      SELECT @CustSeq =A.CustSeq, 
            @DelvInDate = A.DelvDate
       FROM _TPUDelv     AS A WITH(NOLOCK)
            JOIN #DelvIn AS B ON A.DelvSeq = B.DelvSeq
      WHERE A.CompanySeq = @CompanySeq
  
      SELECT @SMRNPMethod = SMRNPMethod,
            @PayDate     = PayDate,
            @SMPayType   = SMPayMethod
       FROM dbo._FPDGetSMRNPMethod(@CompanySeq, 4012, @CustSeq, @DelvInDate)
   UPDATE A
        SET A.SMRNPMethod = ISNULL(@SMRNPMethod, 0)
            ,A.PayDate    = ISNULL(@PayDate, '')
            ,A.SMPayType    = ISNULL(@SMPayType, '')
       FROM #TPUDelvInItem AS A
  
  
   -- ## ��ȭ�ݾ� �Ҽ��� ó�� ## --
     -- ��ȭ�ΰ���, ��ȭ�ݾ� �Ҽ��� ó�� ȯ�漳�� ��������(����)
     EXEC dbo._SCOMEnv @CompanySeq,6504,@UserSeq,@@PROCID,@VATEnvSeq OUTPUT  
     EXEC dbo._SCOMEnv @CompanySeq,6505,@UserSeq,@@PROCID,@AmtEnvSeq OUTPUT  
     -- ��ȭ�ΰ���, ��ȭ�ݾ� �Ҽ��� �ڸ��� ��������
     EXEC dbo._SCOMEnv @CompanySeq,15,@UserSeq,@@PROCID,@DomPointEnvSeq OUTPUT  
  
     -- �ΰ��� �Ҽ��� �ڸ� ó��
     IF RIGHT(@VATEnvSeq, 1) = '1'        -- �ݿø�    
         UPDATE #TPUDelvInItem
            SET DomVAT = ROUND(DomVAT, @DomPointEnvSeq)
     ELSE IF RIGHT(@VATEnvSeq, 1) = '2'   -- ����
         UPDATE #TPUDelvInItem
            SET DomVAT = ROUND(DomVAT, @DomPointEnvSeq , @DomPointEnvSeq + 1 )
     ELSE                                 -- �ø�
         UPDATE #TPUDelvInItem
            SET DomVAT = ROUND(DomVAT + CAST(4 AS DECIMAL(19, 5)) / POWER(10,(@DomPointEnvSeq + 1)), @DomPointEnvSeq)
      -- �ݾ� �Ҽ��� �ڸ� ó��
     IF RIGHT(@AmtEnvSeq, 1) = '1'        -- �ݿø�
         UPDATE #TPUDelvInItem
            SET DomAmt = ROUND(DomAmt, @DomPointEnvSeq)
     ELSE IF RIGHT(@AmtEnvSeq, 1) = '2'   -- ����
         UPDATE #TPUDelvInItem
            SET DomAmt = ROUND(DomAmt, @DomPointEnvSeq , @DomPointEnvSeq + 1 )
     ELSE                                 -- �ø�
  UPDATE #TPUDelvInItem
            SET DomAmt = ROUND(DomAmt + CAST(4 AS DECIMAL(19, 5)) / POWER(10,(@DomPointEnvSeq + 1)), @DomPointEnvSeq)
      -- �԰������ üũ
     EXEC _SPUDelvInItemCheck @xmlDocument    = N''           ,
                              @xmlFlags       = @xmlFlags     ,
                              @ServiceSeq     = 2608   ,
                              @WorkingTag     = 'AUTO'  ,
                              @CompanySeq     = @CompanySeq   ,
                              @LanguageSeq    = @LanguageSeq  ,
                              @UserSeq        = @UserSeq      ,
                              @PgmSeq         = @PgmSeq
     IF @@ERROR <> 0 RETURN  
  -- üũ �� ���� �߻���
     UPDATE #TPUDelvIn_Result
        SET Result        = B.Result     ,
            MessageType   = B.MessageType, 
            Status        = B.Status
       FROM #TPUDelvIn_Result        AS A
      JOIN #DelvIn    AS C ON A.DelvSeq = C.DelvSeq
            JOIN #TPUDelvInItem      AS B ON C.DelvInSeq = B.DelvInSeq
      WHERE ISNULL(B.Status, 0) <> 0
     -- �԰�ó��
     EXEC _SPUDelvInItemSave  @xmlDocument    = N''           ,
                              @xmlFlags       = @xmlFlags     ,
                              @ServiceSeq     = 2608   ,
                              @WorkingTag     = 'AUTO'  ,
                              @CompanySeq     = @CompanySeq   ,
                              @LanguageSeq    = @LanguageSeq  ,
                              @UserSeq        = @UserSeq      ,
                              @PgmSeq         = @PgmSeq
     IF @@ERROR <> 0 RETURN  
      -- ���࿬��
     TRUNCATE TABLE #SComSourceDailyBatch  
      INSERT INTO #SCOMSourceDailyBatch  
     SELECT '_TPUDelvInItem', P.DelvInSeq, P.DelvInSerl, 0,   
            '_TPUDelvItem'  , P.SourceSeq, P.SourceSerl, 0,  
            P.Qty, P.StdUnitQty, P.CurAmt,   P.CurVAT,  
            P.Qty, P.StdUnitQty, P.CurAmt,   P.CurVAT
       FROM #TPUDelvInItem    AS P
      WHERE P.Status = 0  
      EXEC _SComSourceDailyBatch 'A', @CompanySeq, @UserSeq  
      INSERT INTO #TLGInOutDailyBatch  
     SELECT DISTINCT 170, A.DelvInSeq, '', 0, 0  
       FROM #TPUDelvInItem    AS A
      WHERE A.Status = 0  
  
     EXEC _SLGInOutDailyINSERT @CompanySeq
      EXEC _SLGWHStockUPDATE @CompanySeq    
     EXEC _SLGLOTStockUPDATE @CompanySeq    
      EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyBatch'
     EXEC _SLGInOutLotMinusCheck @CompanySeq, '#TLGInOutDailyBatch'
      UPDATE #TPUDelvIn_Result
        SET Result        = B.Result     ,
            MessageType   = B.MessageType, 
            Status        = B.Status
       FROM #TPUDelvIn_Result        AS A
            JOIN #TLGInOutDailyBatch AS B ON A.DelvInSeq = B.InOutSeq
      WHERE ISNULL(B.Status, 0) <> 0
    
    DECLARE @Status INT   
      
    SELECT @Status = (SELECT MAX(Status) FROM #TPUDelvIn_Result )  
      
    RETURN @Status  
