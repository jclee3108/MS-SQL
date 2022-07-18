IF OBJECT_ID('KPXLS_SPUDelvInItemSave') IS NOT NULL 
    DROP PROC KPXLS_SPUDelvInItemSave
GO 

-- v2016.01.12 

-- �����԰��Է� LotMaster �԰����� upd��te ���� �߰� by ����õ 
/************************************************************      
��  �� - �����԰�    
�ۼ��� - 2008�� 8�� 20��       
�ۼ��� - �뿵��      
������ - 2009�� 7�� 15��    
������ - ����    
������ - 2010�� 5�� 4�� UPDATEd BY �ڼҿ� :: �ⳳ��� �߰�    
         2010��10��20�� UPDATEd BY õ��� :: ���ſ�û���� �Է��� Ȱ�����Ͱ� ������ �ش� Ȱ�����͸� �԰��������̺� ����    
         2011��4��  7�� UPDATEd BY ������ :: ������Ʈ�� ��� ������Ʈ�� Ȱ�����ͷ�   
         2011��11��16�� UPDATED BY �輼ȣ :: ������Ʈ �ΰ������� �����ö� PgmSeq ������Ʈ���ų�ǰ(200107) �ϰ�� �߰� (�ڵ��԰��� ��� ���)  
         2012��01��10�� UPDATED BY �輼ȣ :: UPDATE �� _TPUBuyingAcc �� ��ȭ, ȯ�� �ݿ��ȵǵ��� (�����԰����� ����(_SPUDelvInSave)���� ó��) 
         2012��03��09�� UPDATED BY �輼ȣ :: ������Ʈ �԰���ϰ�� ��ǥ���� '������Ʈ���ſ��ָ�������'���� ���� ���������� ����
************************************************************/      
CREATE PROC KPXLS_SPUDelvInItemSave
    @xmlDocument    NVARCHAR(MAX),        
    @xmlFlags       INT = 0,        
    @ServiceSeq     INT = 0,        
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0        
AS          
    DECLARE @AccSeq         INT,    
            @AntiAccSeq     INT,    
            @VatAccSeq      INT,    
            @SlipAutoEnvSeq INT,    
            @SMImpType      INT,    
            @SlipType  INT    
    
IF @WorkingTag <> 'AUTO'    
BEGIN    
    -- ���� ����Ÿ ��� ����      
    CREATE TABLE #TPUDelvInItem (WorkingTag NCHAR(1) NULL)        
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUDelvInItem'     
    
    -- �ⳳ���/ �������� �������� 20100504 �ڼҿ� �߰�    
 DECLARE @SMRNPMethod INT, @PayDate NCHAR(8), @CustSeq INT, @DelvInDate NCHAR(8), @SMPayMethod INT    
 ALTER TABLE #TPUDelvInItem ADD SMRNPMethod INT, PayDate NCHAR(8)    
    
    SELECT @CustSeq    = CustSeq,     
           @DelvInDate = DelvInDate    
      FROM #TPUDelvInItem     
    
    SELECT @SMRNPMethod = SMRNPMethod,    
           @PayDate     = PayDate,    
           @SMPayMethod = SMPayMethod    
      FROM dbo._FPDGetSMRNPMethod(@CompanySeq, 4012, @CustSeq, @DelvInDate)    
    
 UPDATE A    
       SET A.SMRNPMethod = ISNULL(@SMRNPMethod, 0)    
           ,A.PayDate    = ISNULL(@PayDate, '')    
           ,A.SMPayType  = ISNULL(@SMPayMethod, '')    
      FROM #TPUDelvInItem AS A          
    
    IF @@ERROR <> 0 RETURN          
END    

    
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)      
    EXEC _SCOMLog  @CompanySeq,    
                   @UserSeq,    
                   '_TPUDelvInItem',     
                   '#TPUDelvInItem',    
                   'DelvInSeq, DelvInSerl',    
                   'CompanySeq,DelvInSeq,DelvInSerl,SMImpType,SMDelvType,SMStkType,ItemSeq,UnitSeq,Price,DomPrice,Qty,CurAmt,DomAmt,StdUnitSeq,StdUnitQty,IsVAT,CurVAT,DomVAT,WHSeq,SalesCustSeq,DelvCustSeq,LOTNo,FromSerial,ToSerial,SMPayType,AccSeq,AntiAccSeq,IsFiction,FicRateNum,FicRateDen,EvidSeq,PJTSeq,WBSSeq,Remark,IsReturn,SlipSeq,TaxDate,PayDate,SourceType,SourceSeq,SourceSerl,LastUserSeq,LastDateTime'    

    
    -- ��õ ���̺�    
    CREATE TABLE #TMP_SOURCETABLE    
    (    
        IDOrder     INT,    
        TABLENAME   NVARCHAR(100)    
    )    
              
    -- ��õ ������ ���̺�    
    CREATE TABLE #TCOMSourceTracking    
    (    
        IDX_NO      INT,    
        IDOrder     INT,    
        Seq         INT,    
        Serl        INT,    
        SubSerl     INT,    
        Qty         DECIMAL(19,5),    
        STDQty      DECIMAL(19,5),    
        Amt         DECIMAL(19,5),    
        VAT         DECIMAL(19,5)    
    )    
    
 -- �����������а� ������� ���̺� ������� ��������    
 SELECT @SlipType = JourMethod     
   FROM _TACSlipKind    
  WHERE CompanySeq = @CompanySeq    
    AND SlipKindNo = 'FrmPUBuyingAcc'    
    
    
    
    
 IF @SlipType = 4030002 -- �������ڵ��а�    
 BEGIN    
  --�ڵ���ǥ�ڵ� ��������    
  SELECT @SlipAutoEnvSeq = B.SlipAutoEnvSeq    
    FROM _TACSlipKind                    AS A WITH(NOLOCK)     
      LEFT OUTER JOIN _TACSlipAutoEnv AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
                AND A.SlipKindNo = B.SlipKindNo    
   WHERE A.CompanySeq = @CompanySeq    
     AND A.SlipKindNo = 'FrmPUBuyingAcc'     
    
  -- �ΰ������� ��������    
  SELECT @VatAccSeq = B.AccSeq    
   FROM _TACSlipAutoEnvRow AS A WITH(NOLOCK)    
        JOIN _TDAAccount  AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq     
              AND A.AccSeq    = B.AccSeq      
              AND B.SMAccType  = 4002009    
  WHERE A.companyseq     = @CompanySeq      
    AND A.SlipAutoEnvSeq = @SlipAutoEnvSeq     
    
    IF EXISTS(SELECT 1 FROM #TPUDelvInItem AS A
                       JOIN _TPUDelvIn     AS B ON A.DelvInSeq = B.DelvInSeq
                                               AND @CompanySeq = B.CompanySeq
                      WHERE ISNULL(B.IsPJT, '0') = '1')     -- ������Ʈ �԰���ϰ�� ��ǥ���� '������Ʈ���ſ��ָ�������'���� ���� ���������� ���� -12 .03.09 BY �輼ȣ
    BEGIN   
        SELECT @SlipAutoEnvSeq = B.SlipAutoEnvSeq    
          FROM _TACSlipKind                    AS A WITH(NOLOCK)     
            LEFT OUTER JOIN _TACSlipAutoEnv AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
                      AND A.SlipKindNo = B.SlipKindNo    
         WHERE A.CompanySeq = @CompanySeq    
           AND A.SlipKindNo = 'FrmPUBuyingAcc_PMSPur'     
        
        -- �ΰ������� ��������    
        SELECT @VatAccSeq = B.AccSeq    
         FROM _TACSlipAutoEnvRow AS A WITH(NOLOCK)    
           JOIN _TDAAccount  AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq     
                    AND A.AccSeq    = B.AccSeq      
                    AND B.SMAccType  = 4002009    
        WHERE A.companyseq     = @CompanySeq      
          AND A.SlipAutoEnvSeq = @SlipAutoEnvSeq     
        
   END     
  
 END    
  
  
 ELSE IF @SlipType = 4030003 -- ���̺������ڵ��а�    
 BEGIN    
  SELECT @VatAccSeq = B.AccSeq    
       FROM _TACSlipRowAutoEnvTable AS A WITH(NOLOCK)     
      JOIN _TDAAccount     AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq     
              AND A.AccSeq  = B.AccSeq      
              AND B.SMAccType  = 4002009    
   WHERE A.Companyseq = @CompanySeq     
     AND A.SlipKindNo = 'FrmPUBuyingAcc'    
 END     
     
    -- ���Ź�ǰ���� - �������� ����     
    UPDATE #TPUDelvInItem    
       SET Price      = Price ,    
           DomPrice   = DomPrice,    
           Qty        = - Qty   ,    
           CurAmt     = - CurAmt,    
           DomAmt     = - DomAmt,    
           CurVAT     = - CurVAT,    
           DomVAT     = - DomVAT,    
           StdUnitQty = - StdUnitQty     
     WHERE ISNULL(IsReturn, '') = '1'    
         
    -- ���Ź�ǰ���� �԰� �����Ϳ� ��ǰ ���� üũ    
    UPDATE _TPUDelvIn    
       SET IsReturn = '1'    
      FROM _TPUDelvIn          AS A    
           JOIN #TPUDelvInItem AS B ON A.DelvInSeq = B.DelvInSeq                                       
     WHERE A.CompanySeq = @CompanySeq    
       AND ISNULL(B.IsReturn, '') = '1'    
    
    -- �������� �����ڱ��� ��������    
    SELECT @SMImpType = MAX(A.SMImpType)    
      FROM _TPUDelvIn          AS A WITH(NOLOCK)     
           JOIN #TPUDelvInItem AS B ON A.DelvInSeq = B.DelvInSeq    
     WHERE A.CompanySeq = @CompanySeq    
    
    
    -- DELETE          
    IF EXISTS (SELECT TOP 1 1 FROM #TPUDelvInItem WHERE WorkingTag = 'D' AND Status = 0)        
    BEGIN        
        DELETE _TPUDelvInItem      
          FROM _TPUDelvInItem      AS A     
               JOIN #TPUDelvInItem AS B ON A.DelvInSeq  = B.DelvInSeq       
                                       AND A.DelvInSerl = B.DelvInSerl      
         WHERE B.WorkingTag = 'D'     
           AND B.Status = 0          
           AND A.CompanySeq  = @CompanySeq      
    
        IF @@ERROR <> 0  RETURN      
    
        DELETE _TPUBuyingAcc      
          FROM _TPUBuyingAcc AS A     
               JOIN #TPUDelvInItem AS B ON A.CompanySeq = @CompanySeq    
                                       AND A.SourceSeq  = B.DelvInSeq    
                                       AND A.SourceSerl = B.DelvINSerl    
                                       AND A.SourceType = '1'     
         WHERE B.WorkingTag = 'D'     
           AND B.Status = 0          
           AND A.CompanySeq  = @CompanySeq      
    
        IF @@ERROR <> 0  RETURN      
    END      
      
    -- UPDATE          
    IF EXISTS (SELECT 1 FROM #TPUDelvInItem WHERE WorkingTag = 'U' AND Status = 0)        
    BEGIN      
        UPDATE _TPUDelvInItem      
           SET        
                SMImpType    = @SMImpType     ,    
                SMDelvType   = B.SMDelvType   ,    
                SMStkType    = B.SMStkType    ,    
                ItemSeq      = B.ItemSeq      ,    
           UnitSeq      = B.UnitSeq      ,    
                Price        = B.Price        ,    
                DomPrice     = B.DomPrice     ,    
                Qty          = B.Qty          ,    
                CurAmt       = B.CurAmt       ,    
                DomAmt       = B.DomAmt       ,    
                StdUnitSeq   = B.StdUnitSeq   ,    
                StdUnitQty   = B.StdUnitQty   ,    
                IsVAT        = B.IsVAT        ,    
                CurVAT       = B.CurVAT       ,    
                DomVAT       = B.DomVAT       ,    
                WHSeq        = B.WHSeq        ,    
                SalesCustSeq = B.SalesCustSeq ,    
                DelvCustSeq  = B.DelvCustSeq  ,    
                LOTNo        = B.LotNo        ,    
                FromSerial   = B.FromSerial   ,    
                ToSerial     = B.ToSerial     ,    
                SMPayType    = B.SMPayType    ,       
                IsFiction    = B.IsFiction    ,    
                FicRateNum   = B.FicRateNum   ,    
                FicRateDen   = B.FicRateDen   ,    
                EvidSeq      = B.EvidSeq      ,    
                PJTSeq       = B.PJTSeq       ,    
                WBSSeq       = B.WBSSeq       ,     
                Remark       = B.Remark       ,    
                IsReturn     = B.IsReturn     ,    
                LastUserSeq      = @UserSeq,      
                LastDateTime     = GETDATE(),
                SMPriceType  = B.SMPriceType       
          FROM _TPUDelvInItem      AS A     
               JOIN #TPUDelvInItem AS B ON A.DelvInSeq = B.DelvInSeq       
                                       AND A.DelvInSerl = B.DelvInSerl      
         WHERE B.WorkingTag = 'U'       
           AND B.Status = 0          
           AND A.CompanySeq  = @CompanySeq        
    
        IF @@ERROR <> 0  RETURN      
    END         
    
    IF EXISTS (SELECT 1 FROM #TPUDelvInItem WHERE  WorkingTag = 'U' AND Status = 0)        
    BEGIN        
        UPDATE _TPUBuyingAcc    
           SET        
                ItemSeq       = B.ItemSeq        ,    
                UnitSeq       = B.UnitSeq        ,    
--                CurrSeq       = B.CurrSeq        ,    
--                ExRate        = B.ExRate         ,    
                Price         = B.Price          ,    
                DomPrice      = B.DomPrice       ,    
                Qty           = B.Qty            ,    
                PriceUnitSeq  = B.UnitSeq        ,    
                PriceQty      = B.Qty            ,    
                CurAmt        = B.CurAmt         ,    
                CurVAT        = B.CurVAT         ,    
                DomAmt        = B.DomAmt         ,    
                DomVAT        = B.DomVAT         ,    
                StdUnitSeq    = B.StdUnitSeq     ,    
                StdUnitQty    = B.StdUnitQty     ,    
                IsVAT         = B.IsVAT          ,    
                SMImpType     = B.SMImpType      ,    
                WHSeq         = B.WHSeq          ,    
                DelvCustSeq   = B.DelvCustSeq    ,    
                SMPayType     = B.SMPayType      ,       
                IsFiction     = B.IsFiction      ,    
                FicRateNum    = B.FicRateNum     ,    
                FicRateDen    = B.FicRateDen     ,    
                EvidSeq       = B.EvidSeq        ,    
                PjtSeq        = B.PjtSeq         ,    
                WBSSeq        = B.WBSSeq         ,    
                Remark        = B.Remark         ,    
                LastUserSeq   = @UserSeq         ,    
                LastDateTime  = GETDATE()        ,    
                PayDate       = B.PayDate        ,    
                SMRNPMethod   = B.SMRNPMethod        
         FROM _TPUBuyingAcc       AS A     
              JOIN #TPUDelvInItem AS B ON A.SourceSeq  = B.DelvInSeq    
            AND A.SourceSerl = B.DelvINSerl    
                                      AND A.SourceType = '1'    
     WHERE A.CompanySeq = @CompanySeq    
              
        IF @@ERROR <> 0  RETURN      
    
        -- Ȱ������ �߰� 2010.05.11 by bgKeum    
        UPDATE _TPUBuyingAcc    
           SET CCtrSeq      = ISNULL(CC.CCtrSeq, 0)    
          FROM _TPUBuyingAcc AS A JOIN #TPUDelvInItem AS B    
                                    ON A.SourceSeq  = B.DelvInSeq    
                                   AND A.SourceSerl = B.DelvINSerl    
                                   AND A.SourceType = '1'    
                                  JOIN dbo._FnAdmEmpCCtr(@CompanySeq, @DelvInDate) AS CC     
                  ON A.EmpSeq = CC.EmpSeq       
         WHERE A.CompanySeq = @CompanySeq    
           AND (A.CCtrSeq   = 0 OR A.CCtrSeq IS NULL)    
    
        IF @@ERROR <> 0  RETURN     
    
    END    
    
    -- INSERT      
    IF EXISTS (SELECT 1 FROM #TPUDelvInItem WHERE WorkingTag = 'A' AND Status = 0)        
    BEGIN        
        INSERT INTO _TPUDelvInItem(CompanySeq   ,DelvInSeq    ,DelvInSerl   ,SMImpType     ,SMDelvType   ,    
                                    SMStkType    ,ItemSeq      ,UnitSeq      ,--CurrSeq      ,ExRate       ,    
                                    Price        ,Qty          ,CurAmt       ,DomAmt       ,StdUnitSeq   ,    
                                    StdUnitQty   ,CurVAT     ,WHSeq        ,SalesCustSeq ,DelvCustSeq  ,    
                                    LOTNo        ,FromSerial   ,ToSerial     ,SMPayType    ,    
                                    AccSeq   ,    
                                    AntiAccSeq   ,    
                                    IsFiction    ,FicRateNum   ,FicRateDen   ,EvidSeq      ,    
                                    PJTSeq       ,WBSSeq       ,Remark       ,IsReturn     ,LastUserSeq  ,    
                                    DomPrice     ,DomVAT       ,IsVAT        ,    
                                    LastDateTime ,SupplyAmt	   ,SupplyVAT    ,SMPriceType)      
    
        SELECT  @CompanySeq    ,A.DelvInSeq    ,A.DelvInSerl   ,A.SMImpType      ,A.SMDelvType   ,    
                A.SMStkType    ,A.ItemSeq      ,A.UnitSeq      ,--A.CurrSeq        ,A.ExRate       ,    
                A.Price        ,A.Qty          ,A.CurAmt       ,A.DomAmt         ,A.StdUnitSeq   ,    
                A.StdUnitQty   ,A.CurVAT       ,A.WHSeq        ,A.SalesCustSeq   ,A.DelvCustSeq  ,    
                A.LotNo        ,A.FromSerial   ,A.ToSerial     ,A.SMPayType      ,    
                CASE ISNULL(A.AccSeq, 0)     WHEN 0 THEN T.AccSeq  ELSE ISNULL(A.AccSeq, 0)     END AS AccSeq,    
--                 CASE ISNULL(A.AntiAccSeq, 0) WHEN 0 THEN TT.AccSeq ELSE ISNULL(A.AntiAccSeq, 0) END AS AntiAccSeq,    
                CASE WHEN @SMImpType = 8008001 THEN ISNULL(TT.AccSeq, 0) ELSE ISNULL(TTT.AccSeq, 0) END AS AntiAccSeq,    
                A.IsFiction    ,A.FicRateNum   ,A.FicRateDen   ,A.EvidSeq        ,    
                A.PJTSeq       ,A.WBSSeq      ,A.Remark       ,A.IsReturn       ,@UserSeq     ,    
                A.DomPrice     ,A.DomVAT       ,A.IsVAT        ,     
                GETDATE()	   ,A.DomAmt	   ,0              ,SMPriceType--A.DomVAT		-- 2012. 5. 22 ���ް��� �÷� �߰� hkim
          FROM #TPUDelvInItem AS A         
                LEFT OUTER JOIN _TDAItem         AS B ON B.CompanySeq  = @CompanySeq    
                                                     AND A.ItemSeq     = B.ItemSeq    
                LEFT OUTER JOIN _TDAItemAssetAcc AS S WITH(NOLOCK) ON B.CompanySeq  = S.CompanySeq     --      
                                                                  AND B.AssetSeq    = S.AssetSeq     
                                                                  AND S.AssetAccKindSeq = 1    
                LEFT OUTER JOIN _TDAAccount      AS T WITH(NOLOCK) ON S.CompanySeq = T.CompanySeq    
                                                               AND S.AccSeq   = T.AccSeq      
                LEFT OUTER JOIN _TDAItemAssetAcc AS SS WITH(NOLOCK) ON B.CompanySeq  = SS.CompanySeq     --      
                                                       AND B.AssetSeq    = SS.AssetSeq     
                                                                  AND SS.AssetAccKindSeq = 9    
                LEFT OUTER JOIN _TDAAccount      AS TT WITH(NOLOCK) ON SS.CompanySeq = TT.CompanySeq    
                                                               AND SS.AccSeq   = TT.AccSeq      
                LEFT OUTER JOIN _TDAItemAssetAcc AS SSS WITH(NOLOCK) ON B.CompanySeq  = SSS.CompanySeq     --  Local ä�������� ������ ����    
                                                                  AND B.AssetSeq    = SSS.AssetSeq     
                                                                  AND SSS.AssetAccKindSeq = 12    
                LEFT OUTER JOIN _TDAAccount      AS TTT WITH(NOLOCK) ON SSS.CompanySeq = TTT.CompanySeq    
                                                                  AND SSS.AccSeq   = TTT.AccSeq      
         WHERE A.WorkingTag = 'A' AND A.Status = 0          
    
        IF @@ERROR <> 0 RETURN      
    
        -------------------------    
        -- �԰����� ������ ����--    
        -------------------------    
        DECLARE @DataSeq INT,    
                @BuyingAccSeq INT,    
                @count INT    
    
        SELECT  @DataSeq = 0    
              
        WHILE ( 1 = 1 )             
        BEGIN            
            SELECT TOP 1 @DataSeq = DataSeq        
            FROM #TPUDelvInItem            
             WHERE WorkingTag = 'A'            
               AND Status = 0            
               AND DataSeq > @DataSeq            
             ORDER BY DataSeq            
    
            IF @@ROWCOUNT = 0 BREAK         
    
            SELECT @count = COUNT(*)              
       FROM #TPUDelvInItem              
             WHERE WorkingTag = 'A' AND Status = 0                
                      
            IF @count > 0            
            BEGIN            
                EXEC @BuyingAccSeq = _SCOMCreateSeq @CompanySeq, '_TPUBuyingAcc', 'BuyingAccSeq', 1             
            END            
    
            UPDATE #TPUDelvInItem            
               SET BuyingAccSeq = @BuyingAccSeq + 1    
             WHERE WorkingTag = 'A'            
               AND Status = 0            
               AND DataSeq = @DataSeq           
    
            IF @WorkingTag = 'D'    
                UPDATE #TPUBuyingAcc          
                   SET WorkingTag = 'D'          
        END    
    
        -- ���ſ�û ��õ ������ ��������(���ų�ǰ�ڵ�� ���ſ�û�� Ȱ������ �������� ����) �߰� by õ���    
        INSERT #TMP_SOURCETABLE    
        SELECT 1, '_TPUORDPOReqItem'   -- ���ſ�ûǰ��    
    
    
        IF @WorkingTag <> 'AUTO'    
            EXEC _SCOMSourceTracking @CompanySeq, '_TPUDelvItem', '#TPUDelvInItem', 'FromSeq', 'FromSerl', ''    
        ELSE  -- ���ų�ǰ���� �ڵ��԰�� ��ǰ�����ڵ�� �ٸ���    
            EXEC _SCOMSourceTracking @CompanySeq, '_TPUDelvItem', '#TPUDelvInItem', 'SourceSeq', 'SourceSerl', ''    
    
    
        SELECT DISTINCT A.IDX_NO, B.CCtrSeq -- �ߺ� ���� ���� �߻��ؼ� ���� 2011. 1. 21 hkim    
          INTO #CCtrSeq    
          FROM #TCOMSourceTracking   AS A    
               JOIN _TPUORDPOReqItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                      AND A.Seq        = B.POReqSeq    
                                                      AND A.Serl       = B.POReqSerl    
               JOIN _TPUORDPOReq     AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq    
                                                      AND B.POReqSeq   = C.POReqSeq    
    
    
/*    
Ȱ������ ���� ����    
IF ������Ʈ    
 ������ ������Ʈ�� Ȱ������    
ELSE    
 1. ���ſ�û�� Ȱ������    
 2. �����԰�μ��� Ȱ������    
*/    
    
        INSERT INTO _TPUBuyingAcc(CompanySeq         ,BuyingAccSeq     ,SourceType       ,SourceSeq        ,SourceSerl       ,    
                                    BizUnit          ,FactUnit         ,BuyingAccDate    ,DelvInNo         ,DelvInDate       ,    
                                    ItemSeq          ,CustSeq          ,EmpSeq           ,DeptSeq         ,UnitSeq          ,    
                                    CurrSeq          ,ExRate           ,Price            ,DomPrice         ,Qty              ,    
                                    PriceUnitSeq     ,PriceQty         ,CurAmt           ,CurVAT           ,DomAmt           ,    
                                    DomVAT           ,StdUnitSeq       ,StdUnitQty       ,IsVAT            ,SMImpType        ,    
                                    WHSeq            ,DelvCustSeq      ,SMPayType        ,AccSeq           ,MatAccSeq        ,    
                                    AntiAccSeq       ,VatAccSeq        ,IsFiction        ,FicRateNum       ,FicRateDen       ,    
                                    EvidSeq          ,PjtSeq           ,WBSSeq           ,Remark           ,IsReturn         ,    
                                    SlipSeq          ,TaxDate          ,PayDate          ,ImpDomAmt        ,ImpCurAmt        ,    
								    LastUserSeq      ,LastDateTime     ,SMRNPMethod      ,CCtrSeq		   ,SupplyAmt		 ,SupplyVAT) -- Ȱ������ �߰� 2010.05.11 by bgKeum    
        SELECT A.CompanySeq ,C.BuyingAccSeq ,'1'            ,A.DelvInSeq            ,A.DelvInSerl       ,    
               B.BizUnit    ,0              ,B.DelvInDate   ,B.DelvInNo             ,B.DelvInDate       ,    
               A.ItemSeq    ,B.CustSeq      ,B.EmpSeq       ,B.DeptSeq              ,A.UnitSeq          ,    
               B.CurrSeq    ,B.ExRate       ,A.Price        ,A.DomPrice             ,A.Qty              ,                 
               A.UnitSEq    ,A.Qty          ,A.CurAmt       ,A.CurVAT               ,A.DomAmt           ,    
               A.DomVAT     ,A.StdUnitSeq   ,A.StdUnitQty   ,A.IsVAT                ,A.SMImpType        ,    
               A.WHSeq      ,A.DelvCustSeq  ,A.SMPayType    ,A.AccSeq               ,0                  ,    
               A.AntiAccSeq ,@VatAccSeq     ,A.IsFiction    ,A.FicRateNum           ,A.FicRateDen       ,    
               A.EvidSeq    ,A.PjtSeq       ,A.WBSSeq       ,A.Remark               , ''                ,    
               0            ,''             ,C.PayDate      ,0                      ,0                  ,     
               --@UserSeq     ,GETDATE()      ,C.SMRNPMethod  ,ISNULL(D.CCtrSeq, ISNULL(CC.CCtrSeq, 0)) -- Ȱ������ �߰� 2010.05.11 by bgKeum    
               @UserSeq     ,GETDATE()      ,C.SMRNPMethod  ,    
               CASE WHEN A.PJTSeq <> 0 THEN P.CCTRSeq     
									   ELSE ISNULL(D.CCtrSeq, ISNULL(CC.CCtrSeq, 0)) END, -- 20110407 ������ ������Ʈ Ȱ������    
			   A.DomAmt		,0--A.DomVAT			-- 2012. 5. 22 hkim ���ް��� �÷� �߰� 
          FROM _TPUDelvInItem      AS A WITH(NOLOCK)      
               JOIN _TPUDelvIn     AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
                                                    AND A.DelvInSeq  = B.DelvInSeq    
               JOIN #TPUDelvInItem AS C              ON A.DelvInSeq  = C.DelvInSeq    
                                                    AND A.DelvInSerl = C.DelvInSerl    
      -- 20110407 ������ ������Ʈ Ȱ������    
      LEFT OUTER JOIN _TPJTProject   AS P              ON A.CompanySeq = P.CompanySeq    
             AND A.PJTSeq  = P.PJTSeq    
               LEFT OUTER JOIN dbo._FnAdmEmpCCtr(@CompanySeq, @DelvInDate) AS CC ON B.EmpSeq = CC.EmpSeq -- Ȱ������ �߰� 2010.05.11 by bgKeum    
               LEFT OUTER JOIN #CCtrSeq AS D ON C.IDX_NO = D.IDX_NO  -- �켱 ���ſ�û�� Ȱ������ ���� ���� by õ���    
         WHERE C.WorkingTag = 'A'     
           AND C.Status     = 0          
           AND A.CompanySeq = @CompanySeq    
    END    
        
    -- ��������� ���ؼ� �ּ�ó�� 2010. 1. 14 ����    
    -- ���Ź�ǰ���� -���� ȯ��(ȭ�鿡 �����ֱ� ����)    
--     UPDATE #TPUDelvInItem    
--        SET Price      = Price ,    
--            DomPrice   = DomPrice,    
--            Qty        = -Qty   ,    
--            CurAmt     = -CurAmt,    
--            DomAmt     = -DomAmt,    
--            CurVAT     = -CurVAT,    
--            DomVAT     = -DomVAT,    
--            StdUnitQty = -StdUnitQty     
--      WHERE IsReturn = '1'    

    
    ------------------------------------------------------------------------------------------
    -- LotNo Master �԰����� Update ���� �߰� 
    ------------------------------------------------------------------------------------------
    --=======================================================================================================================
    -- ������ ���� ��ǰ�� ��������, ��ȿ���� �������� -- START
    --=======================================================================================================================
    CREATE TABLE #TEMP_DelvInItem    
    (    
        IDX_NO     INT IDENTITY(1,1) ,
        DelvSeq    INT NULL,    
        DelvSerl   INT NULL,
        DelvInSeq  INT,    
        DelvInSerl INT,    
        CreateDate NCHAR(8) NULL, -- ��������
        ValiDate   NCHAR(8) NULL  -- ��ȿ����
    )      

    INSERT INTO #TEMP_DelvInItem (DelvSeq, DelvSerl, DelvInSeq, DelvInSerl)
        SELECT 0, 0, A.DelvInSeq, A.DelvInSerl
          FROM #TPUDelvInItem AS A 
         WHERE A.WorkingTag IN ('A', 'U')
           AND A.Status      = 0
    
    TRUNCATE TABLE #TMP_SOURCETABLE
    TRUNCATE TABLE #TCOMSourceTracking
    
    INSERT #TMP_SOURCETABLE          
    SELECT 1, '_TPUDelvItem'            -- ��ǰ 
      
    EXEC _SCOMSourceTracking  @CompanySeq, '_TPUDelvInItem', '#TEMP_DelvInItem','DelvInSeq', 'DelvInSerl',''      
    
    
    
    UPDATE #TEMP_DelvInItem 
       SET DelvSeq    = B.Seq,
           DelvSerl   = B.Serl,
           CreateDate = D.CreateDate,
           ValiDate   = D.ValiDate
      FROM #TEMP_DelvInItem AS A
           JOIN #TCOMSourceTracking    AS B ON ( A.IDX_NO = B.IDX_NO AND B.IDOrder = 1 ) 
           JOIN KPXLS_TPUDelvItemAdd   AS D ON ( D.CompanySeq = @CompanySeq AND B.Seq = D.DelvSeq AND B.Serl = D.DelvSerl ) 
    --=======================================================================================================================
    -- ������ ���� ��ǰ�� ��������, ��ȿ���� �������� -- END
    --=======================================================================================================================
    
    
    UPDATE A 
       SET RegDate = B.DelvInDate, 
           CreateDate  = ISNULL(C.CreateDate, ''),
           ValiDate    = ISNULL(C.ValiDate, '')
      FROM _TLGLotMaster            AS A 
      JOIN #TPUDelvInItem           AS B ON ( B.ItemSeq = A.ItemSeq AND B.LotNo = A.LotNo ) 
      JOIN #TEMP_DelvInItem         AS C ON ( B.DelvInSeq = C.DelvInSeq AND B.DelvInSerl = C.DelvInSerl )
     WHERE A.CompanySeq = @CompanySeq 
       AND B.WorkingTag IN ( 'A' , 'U' ) 
    ------------------------------------------------------------------------------------------
    -- LotNo Master �԰����� Update ���� �߰�,END 
    ------------------------------------------------------------------------------------------
    
    IF @WorkingTag <> 'AUTO' 
    SELECT * FROM #TPUDelvInItem 
    
    RETURN          
/*******************************************************************************************************************/
GO


begin tran
exec KPXLS_SPUDelvInItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Memo1 />
    <Memo2 />
    <Memo3 />
    <Memo4 />
    <Memo5 />
    <Memo6 />
    <Memo7>0</Memo7>
    <Memo8>0</Memo8>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <CustSeq>357</CustSeq>
    <DelvInSeq>100000863</DelvInSeq>
    <DelvInSerl>1</DelvInSerl>
    <SMImpType>8008001</SMImpType>
    <ItemName>GON_������1</ItemName>
    <ItemNo>GON0001</ItemNo>
    <Spec>GON0001</Spec>
    <UnitName>Kg</UnitName>
    <Price>0.00000</Price>
    <Qty>7.00000</Qty>
    <CurAmt>0.00000</CurAmt>
    <DomPrice>0.00000</DomPrice>
    <DomAmt>0.00000</DomAmt>
    <WHSeq>1222</WHSeq>
    <WHName>���������ũ</WHName>
    <DelvCustName />
    <DelvCustSeq>0</DelvCustSeq>
    <SalesCustName />
    <SalesCustSeq>0</SalesCustSeq>
    <STDUnitName>Kg</STDUnitName>
    <STDUnitQty>7.00000</STDUnitQty>
    <StdConvQty>1.00000</StdConvQty>
    <STDUnitSeq>2</STDUnitSeq>
    <SMPayType>0</SMPayType>
    <SMPayTypeName />
    <SMDelvType>0</SMDelvType>
    <SMDelvTypeName />
    <SMStkType>0</SMStkType>
    <SMStkTypeName />
    <ItemSeq>25292</ItemSeq>
    <UnitSeq>2</UnitSeq>
    <LotNo />
    <FromSerial />
    <ToSerial />
    <Remark />
    <LotMngYN>0</LotMngYN>
    <AccSeq>86</AccSeq>
    <AccName>�����</AccName>
    <AntiAccSeq>209</AntiAccSeq>
    <AntiAccName>�ܻ���Ա�</AntiAccName>
    <IsFiction>0</IsFiction>
    <FicRateNum>0.00000</FicRateNum>
    <FicRateDen>0.00000</FicRateDen>
    <EvidSeq>0</EvidSeq>
    <EvidName />
    <IsReturn xml:space="preserve"> </IsReturn>
    <DelvInDate>20160108</DelvInDate>
    <CurVAT>0.00000</CurVAT>
    <DomVAT>0.00000</DomVAT>
    <PJTName />
    <PJTNo />
    <PJTSeq>0</PJTSeq>
    <WBSName />
    <WBSSeq>0</WBSSeq>
    <IsVAT>0</IsVAT>
    <FromSeq>0</FromSeq>
    <FromSerl>0</FromSerl>
    <ItemSeqOLD>25292</ItemSeqOLD>
    <LotNoOLD />
    <SMPriceType>0</SMPriceType>
    <SMPriceTypeName />
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=2608,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=200109
rollback 