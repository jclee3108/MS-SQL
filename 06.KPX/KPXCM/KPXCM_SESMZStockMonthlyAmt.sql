
IF OBJECT_ID('KPXCM_SESMZStockMonthlyAmt') IS NOT NULL 
    DROP PROC KPXCM_SESMZStockMonthlyAmt
GO 

-- v2015.06.18 

-- KPXCM �ڵ�ȭ���� ������ ���� ����Ʈ ���� by����õ 

/************************************************************                
  ��  �� -  D-ǰ�� �������ݾ� ����  /  ��ȸ        
  �ۼ��� -              
  �ۼ��� -             
  ���� - 2010�� 01�� 19��   �� �� ��             
 ************************************************************/            
 CREATE PROCEDURE KPXCM_SESMZStockMonthlyAmt   
     @xmlDocument    NVARCHAR(MAX),                
     @xmlFlags       INT = 0,                
     @ServiceSeq     INT = 0,                
     @WorkingTag     NVARCHAR(10)= '',                
     @CompanySeq     INT = 1,                
     @LanguageSeq    INT = 1,                
     @UserSeq        INT = 0,                
     @PgmSeq         INT = 0                
               
 AS                   
            
         
  DECLARE    @docHandle      INT,          
             @MessageType    INT,              
             @Status         INT,              
             @Results        NVARCHAR(250),            
             @CostYMFr       CHAR(6)      ,                        
             @CostUnit       INT       ,                  
             @CostUnitName   NVARCHAR(100) ,           
             @AssetSeq       INT       ,           
             @ItemName       NVARCHAR(100) ,                    
             @ItemNo         NVARCHAR(100) ,          
             @BizUnitKind    INT       ,         
             @SMCostMng      INT       ,        
             @RptUnit        INT       ,        
             @CostMngAmdSeq  INT       ,        
             @PreCostKeySeq  INT       ,         
             @PreYM          NCHAR(6)  ,@CostYMTo NCHAR(6) ,        
             @CostKeySeq     INT       ,         
             @ItemKind       NCHAR(1)  , @ItemSeq INT   , @CostUnitKind INT,        
             @AssetGroupSeq  INT       , @WonAmt  INT   , @AppPriceKind INT , @EnvValue NVARCHAR(50) ,             
             @FrDate         NCHAR(8)  ,             
             @ToDate         NCHAR(8)  ,  
    @ItemClassKind  INT    ,  
    @ItemClassSeq   INT       ,  
    @IsAssetType    NCHAR(1)  ,    --����ڻ꺰�� �������  
    @IsDiff          NCHAR(1)  
     
     -- ���� ����Ÿ ��� ����              
            
     CREATE TABLE #Param (WorkingTag NCHAR(1) NULL)          
            
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#Param'                       
                     
             
       IF @@ERROR <> 0 RETURN              
             
      SELECT @CostKeySeq     = B.CostKeySeq          ,           
             @CostUnit       = A.CostUnit            ,           
             @CostUnitName   = A.CostUnitName        ,        
             @CostYMFr       = A.CostYMFr            ,          
             @CostYMTo       = A.CostYMTo            ,          
             @ItemKind       = A.ItemKind            ,         
             @RptUnit        = B.RptUnit             ,           
             @SMCostMng      = B.SMCostMng           ,           
             @CostMngAmdSeq  = B.CostMngAmdSeq       ,        
             @ItemName       = ISNULL(A.ItemName      , '' ),           
             @ItemNo         = ISNULL(A.ItemNo        , '' ),         
             @AssetSeq       = ISNULL(A.AssetSeq      , 0),        
             @ItemSeq        = ISNULL(A.ItemSeq       , 0),        
             @AssetGroupSeq  = ISNULL(A.AssetGroupSeq , 0),        
             @AppPriceKind   = ISNULL(A.AppPriceKind  , 0),  
    @ItemClassKind  = ISNULL(A.ItemClassKind , 0) ,  
     @ItemClassSeq   = ISNULL(A.ItemClassSeq  , 0),   
     @IsAssetType    = ISNULL(A.IsAssetType   , '0'),  
     @IsDiff         = ISNULL(A.IsDiff, '')  
       FROM #Param AS A           
         JOIN _TESMDCostKey AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq             
                                           AND ISNULL(A.RptUnit, 0) = B.RptUnit         
                                           AND A.CostYMTo  = B.CostYM       --20110608����  
                                             AND A.SMCostMng = B.SMCostMng          
                                           AND  B.CostMngAmdSeq  = 0     
                                           AND  B.PlanYear  = ''        
                                                
     WHERE B.CompanySeq = @CompanySeq           
       AND A.Status = 0     
         
         
         
        
    IF @CostYMFr IS NULL         
    BEGIN         
     SELECT * FROM #Param        
     RETURN         
    END         
         
   DECLARE @FrSttlYM             CHAR(6)   ,         
           @PreFrSttlYM          NCHAR(6)  ,        
           @PreSttleYMStd        NCHAR(6)  ,         
           @FrSttleCostKeySeq    INT  ,         
           @PreFrSttleCostKeySeq INT  ,    
           @InitYM               NCHAR(6)            
   DECLARE @StartYM NCHAR(6)      
   DECLARE @InOutKindPre INT       
       
       
   CREATE TABLE #COSTKEY(  
     CostKeySeq INT ,  
     CostYM     NCHAR(6))  
      
    INSERT INTO #COSTKEY  
    SELECT CostKeySeq,CostYM  
      FROM _TESMDCostKey  AS A  
     WHERE A.CompanySeq = @CompanySeq   
       AND A.RptUnit    = @RptUnit         
       AND A.SMCostMng  = @SMCostMng  
       AND A.CostMngAmdSeq  = @CostMngAmdSeq        
       AND A.PlanYear   = ''        
       AND A.CostYM  BETWEEN @CostYMFr AND @CostYMTo      
         
      -- ȯ�漳������ '�������ۿ�' ��������        
   EXEC dbo._SCOMEnv @CompanySeq,1006,0  /*@UserSeq*/,@@PROCID,@StartYM OUTPUT      
       
   SELECT  @InitYM = FrSttlYM         
     FROM  _TDAAccFiscal         
    WHERE  CompanySeq = @CompanySeq        
      AND  @StartYM BETWEEN FrSttlYM AND ToSttlYM        
        
       
     EXEC dbo._SCOMEnv @CompanySeq,15,0  /*@UserSeq*/,@@PROCID,@EnvValue OUTPUT          
     SELECT @WonAmt = @EnvValue          
      ---- ȸ����ۿ� ã��        
     SELECT  @FrSttlYM = FrSttlYM         
       FROM  _TDAAccFiscal         
      WHERE  CompanySeq = @CompanySeq        
        AND  LEFT(@CostYMFr, 6) BETWEEN FrSttlYM AND ToSttlYM            
     
     SELECT @PreYM  = CONVERT(CHAR(6),DATEADD(Month,-1,LEFT(@CostYMFr, 6)+'01'),112)      
     IF @CostYMFr < @StartYM   
         SET @CostYMFr = @StartYM-- 2010.09.30 sjjin ���� - �������ۿ��� ȸ����ۿ��� �ٸ� ��� ������� ���������� �κ� ����  
           
     IF @InitYM = @FrSttlYM --ó�� ȸ����ۿ��� �������      
     BEGIN      
        
           IF @InitYM <> @StartYM      
           BEGIN      
                 IF LEFT(@CostYMFr, 6) = @StartYM     
                 BEGIN     
                     SELECT @FrSttlYM = CONVERT(CHAR(6),DATEADD(Month,-1,@StartYM+'01'),112)      
                     SELECT @InOutKindPre =   8023022  --�⸻���          
                     
                 END     
                 ELSE     
                 BEGIN    
                     SELECT @FrSttlYM = CONVERT(CHAR(6),DATEADD(Month,-1,LEFT(@CostYMFr, 6)+'01'),112)      
                     SELECT @InOutKindPre =   8023022  --�⸻���          
                         
                 END     
           END      
           ELSE    
           BEGIN    
                 IF LEFT(@CostYMFr, 6) = @StartYM     
                 BEGIN     
                     SELECT @FrSttlYM = @InitYM    
                     SELECT @InOutKindPre =   8023000  --�⸻���          
                     
                 END     
                 ELSE     
                 BEGIN    
                     SELECT @FrSttlYM = CONVERT(CHAR(6),DATEADD(Month,-1,LEFT(@CostYMFr, 6)+'01'),112)      
                     SELECT @InOutKindPre =   8023022  --�⸻���          
                         
                 END     
           END     
              
               
     END       
     ELSE -- ���� ȸ����ϰ��      
     BEGIN      
           
         SELECT @InOutKindPre  =  8023000       
         IF LEFT(@CostYMFr, 6) <> @FrSttlYM     
         BEGIN    
             SELECT @FrSttlYM = CONVERT(CHAR(6),DATEADD(Month,-1,LEFT(@CostYMFr, 6)+'01'),112)      
             SELECT @InOutKindPre =   8023022  --�⸻���                
         END      
     
     END       
       SELECT @PreCostKeySeq = B.CostKeySeq  --������ Ű��.         
          FROM _TESMDCostKey AS B  WITH(NOLOCK)           
       WHERE B.CompanySeq = @CompanySeq         
         AND B.CostYM     = @FrSttlYM           
         AND B.RptUnit    = @RptUnit        
         AND B.SMCostMng  = @SMCostMng        
         AND B.CostMngAmdSeq = @CostMngAmdSeq        
          
           
         
  DECLARE @ItemPriceUnit INT , @GoodPriceUnit INT , @FGoodPriceUnit INT         
   
     SELECT @ItemPriceUnit = EnvValue FROM _TComEnv WHERE EnvSeq  = 5521  And CompanySeq = @CompanySeq --����ܰ�������                   
     SELECT @GoodPriceUnit = EnvValue FROM _TComEnv WHERE EnvSeq  = 5522  And CompanySeq = @CompanySeq --��ǰ�ܰ�������                   
     SELECT @FGoodPriceUnit = EnvValue FROM _TComEnv WHERE EnvSeq = 5523  And CompanySeq = @CompanySeq --��ǰ�ܰ�������                   
         
         
            EXEC dbo._SCOMEnv @CompanySeq,15,0  /*@UserSeq*/,@@PROCID,@EnvValue OUTPUT            
             SELECT @WonAmt = @EnvValue            
                       
         
         
 IF @ItemKind = ''  --�����̸�  �ܰ��������� ��������� �ص� ��������.          
 BEGIN         
          
         
     IF @ItemPriceUnit <> @GoodPriceUnit OR @GoodPriceUnit <> @FGoodPriceUnit OR @ItemPriceUnit <> @FGoodPriceUnit         
      BEGIN            
             EXEC dbo._SCOMMessage @MessageType OUTPUT,          
                                   @Status      OUTPUT,          
                                   @Results     OUTPUT,          
                                   1149               , -- ����ڻ��� �ܰ��������� ���� Ʋ���ϴ�. ����ȭ���� �ƴ� �ڻ꺰 �����忡�� ��ȸ�ϼž� �մϴ�.          
                                   @LanguageSeq       ,           
                                   0,''             
             UPDATE #Param          
                SET Result        = REPLACE(@Results, '@2', ''),          
                    MessageType   = @MessageType,          
                    Status        = @Status          
              WHERE Status = 0          
         
         SELECT * FROM #Param         
         
         
        RETURN         
         
      END               
 END         
          
 CREATE TABLE #TempItem        
 ( ItemSeq INT ,  PriceUnit  INT  ,  IsItem NCHAR(1)  )           
         
          
         
          
 DECLARE @ItemKindName NVARCHAR(100)         
         
 IF @ItemKind = ''         
  BEGIN         
      SELECT @ItemKindName = '����' --= Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND        
      SELECT @CostUnitKind = @ItemPriceUnit   --����ܰ�������        
  END         
 ELSE IF @ItemKind = 'G'        
  BEGIN         
      SELECT @ItemKindName = '��ǰ' -- Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 1968         
      SELECT @CostUnitKind  = @GoodPriceUnit   --��ǰ�ܰ�������        
         
 END        
 ELSE IF @ItemKind = 'F'         
  BEGIN         
      SELECT @ItemKindName = Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 2031         
      SELECT @CostUnitKind  = @FGoodPriceUnit   --��ǰ�ܰ�������        
  END        
 ELSE IF @ItemKind = 'M'        
  BEGIN         
      SELECT @ItemKindName = Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 1968         
      SELECT @CostUnitKind  = @ItemPriceUnit   --��ǰ�ܰ�������        
  END        
    
  CREATE TABLE #ItemClass(  
      ItemClassSSeq    INT,    
      ItemClassMSeq    INT,    
      ItemClassLSeq    INT,    
      ItemClasSName    NVARCHAR(100),    
      ItemClasMName    NVARCHAR(100),    
      ItemClasLName    NVARCHAR(100)    
      )  
    
  INSERT INTO #ItemClass(  
                ItemClassSSeq,ItemClassMSeq,ItemClassLSeq,  
                ItemClasSName,ItemClasMName,ItemClasLName)  
         SELECT SM.MinorSeq, ISNULL(MM.MinorSeq,''), ISNULL(LM.MinorSeq,'') ,    
             SM.MinorName, ISNULL(MM.MinorName,''), ISNULL(LM.MinorName,'')     
        FROM  _TDAUMinor         AS SM WITH(NOLOCK)   
          JOIN _TDAUMinorValue    AS MS WITH(NOLOCK) ON SM.MinorSeq = MS.MinorSeq    
                                                      AND SM.CompanySeq = MS.CompanySeq    
                                                    AND MS.Serl = CASE SM.MajorSeq WHEN 2001 THEN 1001 WHEN 2004 THEN 2001 END     
          LEFT OUTER JOIN _TDAUMinor         AS MM WITH(NOLOCK) ON MS.ValueSeq = MM.MinorSeq    
                            AND SM.CompanySeq = MM.CompanySeq    
          LEFT OUTER JOIN _TDAUMinorValue    AS LS WITH(NOLOCK) ON MS.ValueSeq = LS.MinorSeq    
                                                    AND SM.CompanySeq = LS.CompanySeq    
                                                    AND LS.Serl = 2001    
          LEFT OUTER JOIN _TDAUMinor         AS LM WITH(NOLOCK) ON LS.ValueSeq = LM.MinorSeq    
                                                    AND SM.CompanySeq = LM.CompanySeq    
       WHERE SM.CompanySeq     = @CompanySeq    
        AND SM.MajorSeq IN (2001,2004)    
        
      
        
         
     INSERT INTO #TempItem         
     SELECT C.ItemSeq  ,  CASE WHEN @ItemKind = '' THEN @ItemPriceUnit         
                             WHEN @ItemKind = 'G' THEN @GoodPriceUnit         
                             WHEN @ItemKind = 'F' THEN @FGoodPriceUnit         
                             WHEN @ItemKind = 'M' THEN @ItemPriceUnit  END ,   
             CONVERT(NCHAR(1),H.MinorValue)    --2011.01.12 ����: ���� ���ζ󿡼�  �������ڿ� �����߻� ����Ʈ ��Ű�ϱ� �߻�����.-_-    
       FROM _TDAItem            AS C WITH(NOLOCK)  
            JOIN _TDAItemAsset  AS D WITH(NOLOCK) ON C.AssetSeq   = D.AssetSeq   
                                                 AND C.CompanySeq = D.CompanySeq         
            JOIN _TDAItemAsset  AS G WITH(NOLOCK) ON C.CompanySeq = G.CompanySeq            
                                                 AND C.AssetSeq   = G.AssetSeq            
                                                 AND G.IsAmt      <> '1'            
            JOIN _TDASMinor     AS H  WITH(NOLOCK) ON G.CompanySeq = H.CompanySeq         
                                                  AND G.SMAssetGrp = H.MinorSeq            
            JOIN _TDAITemClass  AS IC  WITH(NOLOCK) ON C.ItemSeq = IC.ItemSeq    
                                                   AND C.CompanySeq = IC.CompanySeq    
                                                   AND IC.UMajorItemClass IN (2001,2004)    
            LEFT OUTER JOIN #ItemClass AS I   WITH(NOLOCK) ON IC.UMItemClass = I.ItemClassSSeq  
            --LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq,0)  AS I ON C.ItemSeq = I.ITemSeq   
       WHERE (   (@ItemKind = ''  AND   G.SMAssetGrp <> 6008005 )         
              OR (@ItemKind = 'G' AND  G.SMAssetGrp = 6008001 )            
              OR (@ItemKind = 'F' AND  G.SMAssetGrp IN ( 6008002 ,6008004 ) )            
              OR (@ItemKind = 'M' AND  H.MinorValue = '1' AND G.SMAssetGrp <> 6008005  ) )          
         AND (@IsAssetType = '1' OR (  
                  (@ItemSeq = 0 OR   C.ItemSeq = @ItemSeq)         
             AND  (@ItemName = '' OR  C.ItemName LIKE @ItemName + '%'  )           
             AND  (@ItemNo   = '' OR  C.ItemNo   LIKE @ItemNo   + '%'  )           
             AND  (@AssetSeq = 0 OR   C.AssetSeq = @AssetSeq    )            
             AND  (@AssetGroupSeq  = 0 OR G.SMAssetGrp = @AssetGroupSeq)     
             ))     
         AND ( @ItemClassKind = 0 OR @ItemClassSeq = 0 OR   
              (   @ItemClassKind IN (2001, 2004) AND I.ItemClassSSeq = @ItemClassSeq)  
              OR (@ItemClassKind IN (2002, 2005) AND I.ItemClassMSeq = @ItemClassSeq)  
              OR (@ItemClassKind IN (2003, 2006) AND I.ItemClassLSeq = @ItemClassSeq)  
              )  
         AND  C.Companyseq = @CompanySeq          
    
     CREATE CLUSTERED INDEX IDX_#TempItem ON #TempItem(ItemSeq)  
              
    CREATE TABLE #TempStock         
    ( ItemSeq   INT            , PreQty DECIMAL(19, 5) , PreAmt DECIMAL(19, 5) , ProdQty DECIMAL(19, 5) , ProdAmt DECIMAL(19, 5) ,         
        BuyQty    DECIMAL(19, 5) , BuyAmt DECIMAL(19, 5) , MvInQty DECIMAL(19, 5) , MvInAmt DECIMAL(19, 5) , EtcInQty DECIMAL(19, 5) ,         
      EtcInAmt  DECIMAL(19, 5) , ExchangeInQty DECIMAL(19, 5) , ExchangeInAmt DECIMAL(19, 5) , SalesQty DECIMAL(19, 5) , SalesAmt DECIMAL(19, 5) ,         
      InputQty  DECIMAL(19, 5) , InputAmt DECIMAL(19, 5) , MvOutQty DECIMAL(19, 5) , MvOutAmt DECIMAL(19, 5) , EtcOutQty DECIMAL(19, 5) ,         
      EtcOutAmt DECIMAL(19, 5) , ExchangeOutQty DECIMAL(19, 5) , ExchangeOutAmt DECIMAL(19, 5) , InQty DECIMAL(19, 5) , OutAmt DECIMAL(19, 5) ,         
      InAmt DECIMAL(19, 5)     , StockQty DECIMAL(19, 5) , OutQty DECIMAL(19, 5) , StockAmt DECIMAL(19, 5)  , SumYn NCHAR(1)         
      ,StockQty2 DECIMAL(19, 5), StockAmt2 DECIMAL(19, 5)  
 )        
         
    -- �̿� ����            
     SELECT @CostUnitKind = @FGoodPriceUnit        
         
 ------�������� 10.03.06         
 ------������ ����ȸ�� ���̺��� ����������.. �����δ� �����ʰ� �����ؼ� ������ ������������ �������� �ݾ��� �ܰ����뱸�п� ����         
 ------ǥ�����ܰ����ÿ� �������� * ǥ�����ܰ�, �����ܰ����ÿ� ����ȸ�� ���̺��� ���������� �����ȴ�.         
 ------�԰����, �԰�ݾ�(�����԰�����)�� ������ �������� �����´�.         
          
             
     CREATE TABLE #LGStockINToMNGACC              
     (                 
         InOutType       INT,              
         InOutSeq        INT,              
         InOutSerl       INT,              
         DataKind        INT,              
         InOutDataSerl   INT,              
         InOutSubSerl    INT,              
         InOut           INT,              
         InOutDate       NCHAR(8),              
         ItemSeq         INT,              
         IsItem          NCHAR(1)  ,             
         Qty             DECIMAL(19, 5),              
         Amt             DECIMAL(19, 5),              
         InOutKind       INT,              
         InOutDetailKind INT,              
         FactUnit        INT,              
         BizUnit         INT,              
         AccUnit         INT,              
         CostYm          NCHAR(6) ,        
         InOutLotSerl    INT   , --LOT�����         
         LotNo           NVARCHAR(30),   --LOT�����          
         CostKeySeq      INT  
                       
     )               
    CREATE INDEX IDX1_#LGStockINToMNGACC ON #LGStockINToMNGACC(InOutType , InOutSeq , InOutSerl , DataKind , InOutSubSerl , ItemSeq,CostKeySeq )         
             
         --(138266�� ���� ������ ����)  
     ------ 22514 _TLGInOutStock�κ��� â������ ������� ������ ������              
     INSERT  #LGStockINToMNGACC (   
             InOutType       ,InOutSeq        ,InOutSerl       ,DataKind         ,               
             InOutDataSerl   ,InOutSubSerl    ,InOut           ,InOutDate        , ItemSeq     ,  
             IsItem          ,Qty             ,Amt             ,InOutKind        ,               
             InOutDetailKind ,FactUnit        ,BizUnit         ,AccUnit          , CostYm      ,  
             CostKeySeq       )             
     SELECT  A.InOutType, A.InOutSeq, A.InOutSerl, A.DataKind,             
             A.InOutDataSerl, A.InOutSubSerl, A.InOut, A.InOutDate, A.ItemSeq,             
             B1.IsItem , A.StdQty, CASE WHEN A.InOut = 1 AND A.InOutKind NOT IN (8023008, 8023009, 8023016) THEN A.Amt  ELSE ISNULL(J.Amt, 0) END,  -- �̵�ó��, �԰ݴ�ü, ��ǰ�԰�   
       A.InOutKind, A.InOutDetailKind,  B.FactUnit, B.BizUnit, I.AccUnit  , A.InOutYM   ,K.CostKeySeq          
       FROM  _TLGInOutStock      AS A  WITH(NOLOCK)  
             JOIN #TempItem      AS B1              ON A.ItemSeq       = B1.ItemSeq             
             JOIN _TDAWH         AS B  WITH(NOLOCK) ON A.CompanySeq    = B.CompanySeq               
                                                   AND A.WHSeq         = B.WHSeq              
                                                   AND A.FunctionWHSeq = 0              
             JOIN _TDABizUnit    AS I  WITH(NOLOCK) ON B.CompanySeq    = I.CompanySeq               
                                                   AND B.BizUnit       = I.BizUnit              
             JOIN _TDASMinorValue AS C WITH(NOLOCK) ON C.CompanySeq    = B.CompanySeq               
                                                AND B.SMWHKind      = C.MinorSeq              
                                                   AND C.MajorSeq      = 8002   
                                                   AND C.SERL          = 1008   
                                                   AND C.ValueText     = '1'             
 LEFT OUTER JOIN #COSTKEY      AS K    ON A.InOutYM       = K.CostYM       
             LEFT OUTER JOIN _TDAItemSales AS E WITH(NOLOCK)  ON A.CompanySeq  = E.CompanySeq              
                                                             AND A.ItemSeq     = E.ItemSeq    
             LEFT OUTER JOIN _TESMGInOutStock AS J ON J.CompanySeq    = A.CompanySeq       
                                                  AND J.InOutSeq      = A.InOutSeq       
                                                  AND J.InOutType     = A.InOutType      
                                                  AND J.InOutSerl     = A.InOutSerl      
                                                  AND J.InOutSubSerl  = A.InOutSubSerl      
                                                  AND J.DataKind      = A.DataKind      
                                                  AND J.InOutDataSerl = A.InOutDataSerl    
                                                  AND K.CostKeySeq    = J.CostKeySeq   
                                                  AND J.InOutKind     = A.InOutKind  
                                                  AND J.ESMAdjustSeq = 0   
                                                  AND J.ItemSeq       =A.ItemSeq     
        WHERE  A.CompanySeq = @CompanySeq              
         AND A.InOutDate BETWEEN @CostYMFr +'01' AND @CostYMTo +'31'             
         AND  IsNull(E.IsSet, '0') <> '1'            
         AND ( (@CostUnit = 0)  
             OR ( B1.PriceUnit = 5502002 AND I.AccUnit = @CostUnit )             
             OR ( B1.PriceUnit = 5502003 AND B.BizUnit = @CostUnit )             
             )           
         AND A.InOutKind IN ( SELECT MinorSeq FROM _TDASMinor             
                               WHERE MajorSeq = 8023 AND MinorValue = 1              
                                 AND CompanySeq = @CompanySeq   )            
         AND ( A.InOutKind <> 8023016 OR ( A.InOutKind = 8023016 AND A.InOut = 1)  )      
         AND A.InOutType >0     
         AND A.InOutYM   BETWEEN @CostYMFr  AND @CostYMTo                   
      INSERT  #LGStockINToMNGACC (   
             InOutType       ,InOutSeq        ,InOutSerl       ,DataKind         ,               
             InOutDataSerl   ,InOutSubSerl    ,InOut           ,InOutDate        , ItemSeq     ,  
             IsItem          ,Qty             ,Amt             ,InOutKind        ,               
             InOutDetailKind ,FactUnit        ,BizUnit         ,AccUnit          , CostYm      ,  
             CostKeySeq       )             
            
     SELECT  A.InOutType, A.InOutSeq, A.InOutSerl, A.DataKind, A.InOutDataSerl, A.InOutSubSerl,               
             A.InOut, A.InOutDate, A.ItemSeq, B1.IsItem ,              
             A.StdQty, CASE WHEN A.InOut = 1 AND A.InOutKind NOT IN (8023008, 8023009, 8023016) THEN A.Amt  ELSE ISNULL(J.Amt, 0) END,  -- �̵�ó��, �԰ݴ�ü, ��ǰ�԰�   
    A.InOutKind, A.InOutDetailKind, D.FactUnit, D.BizUnit,               
             ISNULL((SELECT AccUnit FROM _TDABizUnit WHERE CompanySeq = D.CompanySeq And BizUnit = D.BizUnit), 1),              
             A.InOutYM        ,K.CostKeySeq     
       FROM  _TLGInOutStock          AS A WITH(NOLOCK)             
             JOIN #TempItem          AS B1 ON A.ItemSeq = B1.ItemSeq             
             JOIN _TDAWHSub          AS B WITH(NOLOCK) ON  A.CompanySeq    = B.CompanySeq              
                                                      AND  A.FunctionWHSeq = B.WHSeq              
             JOIN _TDASMinorValue    AS C WITH(NOLOCK) ON  C.CompanySeq    = B.CompanySeq              
AND C.MinorSeq      = B.SMWHKind  
                                                       AND C.MajorSeq      = 8002  
                                                       AND C.SERL          = 1008   
                                                       AND C.ValueText     = '1'              
             JOIN _TDAWH             AS D WITH(NOLOCK) ON  A.CompanySeq    = D.CompanySeq        
                                                      AND  A.WHSeq         = D.WHSeq              
             JOIN _TDABizUnit        AS I WITH(NOLOCK) ON  I.CompanySeq    = D.CompanySeq              
                                                      AND  I.BizUnit       = D.BizUnit             
             LEFT OUTER JOIN #COSTKEY         AS K              ON   A.InOutYM       = K.CostYM       
             LEFT Outer JOIN _TDAItemSales    AS E WITH(NOLOCK) ON   A.CompanySeq    = E.CompanySeq               
                                                                AND  A.ItemSeq       = E.ItemSeq    
             LEFT OUTER JOIN _TESMGInOutStock AS J WITH(NOLOCK) ON   J.CompanySeq    = A.CompanySeq       
                                                                 AND J.InOutSeq      = A.InOutSeq      
                                                                 AND J.InOutType     = A.InOutType      
                                                                 AND J.InOutSerl     = A.InOutSerl      
                                                                 AND J.InOutSubSerl  = A.InOutSubSerl      
                                                                 AND J.DataKind      = A.DataKind      
                                                                 AND J.InOutDataSerl = A.InOutDataSerl      
                                                                 AND J.CostKeySeq    = K.CostKeySeq       
                                                                 AND J.InOutKind     = A.InOutKind                                                                    
                                                                 AND J.ESMAdjustSeq = 0   
                                                                 AND J.ItemSeq       =A.ItemSeq                                                                     
       WHERE  A.CompanySeq = @CompanySeq              
         AND A.InOutDate  BETWEEN @CostYMFr +'01' AND @CostYMTo +'31'            
         AND ISNULL(E.IsSet, '0') <> '1'               
         AND ( (@CostUnit = 0)  
             OR ( B1.PriceUnit = 5502002 AND I.AccUnit = @CostUnit )             
             OR ( B1.PriceUnit = 5502003 AND D.BizUnit = @CostUnit )             
             )         
         AND A.InOutKind IN ( SELECT MinorSeq FROM _TDASMinor             
                               WHERE MajorSeq = 8023 AND MinorValue = 1              
                                 AND CompanySeq = @CompanySeq   )            
        AND ( A.InOutKind <> 8023016 OR ( A.InOutKind = 8023016 AND A.InOut = 1)  )             
         AND A.InOutType >0     
         AND A.InOutYM   BETWEEN @CostYMFr  AND @CostYMTo                   
    
     --2010.11.29 sjjin �߰� ��Ÿ�԰�� ifrs, �������� ��� KGAAP�� IFRS���� ��ǰ�� �ܰ��� Ʋ�� ��� _TLGInOutStock_ESM���̺� �����͸� ����ϰ� �Ǵµ�   
     --_TLGInOutStock_ESM ���̺��� �����Ͱ� ������ ��� _TLGInOutStock_ESM���̺� �����ͷ� �����ش�  
     IF @SMCostMng IN (5512005, 5512006, 5512007, 5512008) --IFRS, �������� ���  
     BEGIN  
         UPDATE #LGStockINToMNGACC   
             SET Qty = B.Qty,  
                 Amt = B.Amt  
           FROM #LGStockINToMNGACC AS A  
                         JOIN #TempItem          AS B1             ON A.ItemSeq = B1.ItemSeq        
                         JOIN _TLGInOutStock_ESM AS B WITH(NOLOCK) ON A.InOutSeq      = B.InOutSeq  
                                                                  AND A.InOutSerl     = B.InOutSerl  
                                                                  AND A.InOutType     = B.InOutType  
       AND A.DataKind      = B.DataKind  
                                                                  AND A.InOutDataSerl = B.InOutDataSerl  
                                                                  AND A.InOutSubSerl  = B.InOutSubSerl  
                                                                  AND B.SMCostMng     = @SMCostMng  
              LEFT OUTER JOIN _TDAItemSales     AS E WITH(NOLOCK) ON  B.CompanySeq    = E.CompanySeq              
                                                                  AND B.ItemSeq       = E.ItemSeq      
                         JOIN _TDAWH             AS D WITH(NOLOCK) ON B.CompanySeq    = D.CompanySeq  
                                                                  AND B.WHSeq         = D.WHSeq  
                         JOIN _TDABizUnit        AS I WITH(NOLOCK) ON I.CompanySeq    = D.CompanySeq  
                                                                  AND I.BizUnit       = D.BizUnit     
           WHERE B.CompanySeq = @CompanySeq              
             AND B.InOutDate  BETWEEN @CostYMFr +'01' AND @CostYMTo +'31'            
             AND ISNULL(E.IsSet, '0') <> '1'               
             AND ( (@CostUnit = 0)  
                 OR ( B1.PriceUnit = 5502002 AND I.AccUnit = @CostUnit )             
                 OR ( B1.PriceUnit = 5502003 AND D.BizUnit = @CostUnit )             
                 )         
             AND B.InOutKind = 8023004 -- ��Ÿ�԰�...  
     END  
       
  CREATE TABLE #_TESMGInOutStock         
   (   CompanySeq INT NOT NULL,    InOutSeq INT NOT NULL,    InOutType INT NOT NULL,    InOutSerl INT NOT NULL,            
       InOutSubSerl INT NOT NULL,    DataKind INT NOT NULL,    InOutDataSerl INT NOT NULL,    ESMAdjustSeq INT NOT NULL,            
       CostKeySeq INT NOT NULL,    InOutDate NCHAR(8) NOT NULL,    InOut INT NOT NULL,    ItemSeq INT NOT NULL,           
       Qty DECIMAL(19,5) NOT NULL,    Amt DECIMAL(19,5) NOT NULL,    InOutKind INT NOT NULL,    InOutDetailKind INT NOT NULL,            
       FactUnit INT NOT NULL,    BizUnit INT NOT NULL,    AccUnit INT NOT NULL,    SMAdjustKind INT NOT NULL,           
       CostUnit INT NOT NULL       
    )         
          
         
     INSERT  #_TESMGInOutStock              
     (       CompanySeq,              
             InOutType,              
             InOutSeq,              
             InOutSerl,              
             DataKind,              
             InOutDataSerl,              
             InOutSubSerl,              
             ESMAdjustSeq,             
             CostKeySeq  ,              
             InOut,              
             InOutDate,              
             ItemSeq,               
             Qty,              
             Amt,              
             InOutKind,              
             InOutDetailKind,              
             FactUnit,              
             BizUnit,              
             AccUnit,              
             SMAdjustKind ,            
             CostUnit            
             )              
     SELECT  @CompanySeq,              
             X.InOutType,              
             X.InOutSeq,              
             X.InOutSerl,               
             X.DataKind,               
             X.InOutDataSerl,              
             X.InOutSubSerl,              
             0,              
             X.CostKeySeq   ,             
             X.InOut,              
             X.InOutDate,              
             X.ItemSeq,               
             X.Qty,              
             X.Amt,              
             X.InOutKind,              
             X.InOutDetailKind,              
             X.FactUnit,              
             X.BizUnit,              
             X.AccUnit,              
             0        ,            
            CASE B1.PriceUnit WHEN  5502001 THEN X.FactUnit            
                                WHEN  5502002 THEN X.AccUnit             
                                  WHEN   5502003 THEN X.BizUnit END            
       FROM   #LGStockINToMNGACC X    JOIN   #TempItem AS B1 ON X.ItemSeq = B1.ItemSeq         
                                      JOIN  (              
                                          SELECT  DISTINCT   A.InOutType, A.InOutSeq, A.InOutSerl, A.InOutSubSerl, A.ItemSeq, A.DataKind              
                                           FROM   #LGStockINToMNGACC A  JOIN   #TempItem AS B1 ON A.ItemSeq = B1.ItemSeq             
          GROUP BY  A.InOutType, A.InOutSeq, A.InOutSerl, A.InOutSubSerl, A.ItemSeq, A.DataKind,          
                                                     CASE  B1.PriceUnit WHEN 5502003 THEN A.BizUnit ELSE 0 END ,              
                                                     A.AccUnit  , A.INOUTKIND               
                                           Having ( ( Sum(A.Qty) = 0 AND SUM(A.Amt) <> 0 ) OR ( SUM(A.Qty) <> 0 AND Sum(A.InOut * A.Qty) <> 0 ) )  
       
                                                     ) Y ON  X.InOutType      = Y.InOutType              
                                                                                  AND X.InOutSeq       = Y.InOutSeq              
                                                                                  AND X.InOutSerl      = Y.InOutSerl              
                                                                                  AND X.DataKind       = Y.DataKind              
                                                                                  AND X.InOutSubSerl   = Y.InOutSubSerl              
                                                                                  AND X.ItemSeq        = Y.ItemSeq              
          
          
         
           INSERT INTO #TempStock( ItemSeq , PreQty , PreAmt   )         
             SELECT A.ItemSeq , SUM(Qty), SUM(Amt)          
              FROM _TESMGMonthlyStockAmt AS A  WITH(NOLOCK)  JOIN #TempItem AS B1 ON A.ItemSeq = B1.ItemSeq         
            WHERE A.Companyseq = @CompanySeq         
              AND A.CostKeySeq = @PreCostKeySeq         
              AND  (    (@CostUnit = 0)  
                       OR ( B1.PriceUnit = 5502002 AND A.AccUnit = @CostUnit )        
                       OR ( B1.PriceUnit = 5502003 AND A.BizUnit = @CostUnit )        
                   )         
              AND A.InOutKind =  @InOutKindPre         
          GROUP BY A.ItemSeq         
          -- ������, ���ݾ��� _TESMGMonthlyStockAmt �� �����Ϳ� ���ϱ����� �߰�. 2010.08.10 ������.   
           INSERT INTO #TempStock( ItemSeq , StockQty2 , StockAmt2   )         
             SELECT A.ItemSeq , SUM(Qty), SUM(Amt)          
              FROM _TESMGMonthlyStockAmt AS A  WITH(NOLOCK)  JOIN #TempItem AS B1 ON A.ItemSeq = B1.ItemSeq         
            WHERE A.Companyseq = @CompanySeq         
              AND A.CostKeySeq = @CostKeySeq         
              AND  (   (@CostUnit = 0)  
                       OR ( B1.PriceUnit = 5502002 AND A.AccUnit = @CostUnit )        
                       OR ( B1.PriceUnit = 5502003 AND A.BizUnit = @CostUnit )        
                   )         
              AND A.InOutKind =  8023022         
          GROUP BY A.ItemSeq         
    
 -------------------------------------------------  
 --��������� �ȵǾ������ �̿� �������� _TLGInOutStock���� �������� -����ι��� ���   
 -------------------------------------------------        
  IF @AppPriceKind = 5533002  --ǥ�����ܰ�         
  BEGIN         
       
            INSERT INTO #TempStock( ItemSeq , ProdQty ,ProdAmt ,BuyQty  ,BuyAmt   ,MvInQty  ,MvInAmt ,EtcInQty ,EtcInAmt ,        
                         ExchangeInQty ,ExchangeInAmt ,SalesQty,SalesAmt,InputQty ,InputAmt ,MvOutQty,MvOutAmt ,EtcOutQty,        
                         EtcOutAmt ,ExchangeOutQty ,ExchangeOutAmt    )         
             SELECT A.ItemSeq ,CASE WHEN A.InOutKind = 8023016 OR A.InOutKind = 8023017 THEN  A.Qty  ELSE 0 END ,         
                             --2010.11.16 ���� �����԰� /�����԰� ǥ�����ܰ� ����      
      CASE WHEN A.InOutKind = 8023016 OR A.InOutKind = 8023017  THEN   ROUND(A.Qty * ISNULL(C.Price, 0) * power(10,@WonAmt), 0) / power(10,@WonAmt)   ELSE 0 END ,     
                              CASE WHEN A.InOutKind IN( 8023019 ,8023036,8023046,802345) THEN  A.Qty * A.InOut   ELSE 0 END ,         
                              CASE WHEN A.InOutKind IN( 8023019 ,8023036,8023046,802345) THEN  A.Amt * A.InOut   ELSE 0 END ,         
         
                              CASE WHEN A.InOutKind = 8023008 AND A.InOut =  1 THEN  A.Qty   ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023008 AND A.InOut =  1 THEN  ROUND(A.Qty * ISNULL(C.Price, 0) * power(10,@WonAmt), 0) / power(10,@WonAmt) ELSE 0 END  ,         
         
                              CASE WHEN A.InOutKind = 8023004  THEN  A.Qty   ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023004  THEN  A.Amt   ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023009 AND A.InOut =  1  THEN  A.Qty   ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023009 AND A.InOut =  1  THEN  B.Amt   ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023002  THEN  A.Qty    ELSE 0 END , --���⼭���� ���.         
                              CASE WHEN A.InOutKind = 8023002  THEN  ROUND(A.Qty * ISNULL(C.Price, 0) * power(10,@WonAmt), 0) / power(10,@WonAmt)    ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023015 OR A.InOutKind = 8023021 THEN  A.Qty   ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023015 OR A.InOutKind = 8023021 THEN  ROUND(A.Qty * ISNULL(C.Price, 0) * power(10,@WonAmt), 0) / power(10,@WonAmt)   ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023008 AND A.InOut = -1 THEN  A.Qty   ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023008 AND A.InOut = -1 THEN  ROUND(A.Qty * ISNULL(C.Price, 0) * power(10,@WonAmt), 0) / power(10,@WonAmt) ELSE 0 END ,         
         
                              CASE WHEN A.InOutKind = 8023003  THEN  A.Qty   ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023003 THEN  ROUND(A.Qty * ISNULL(C.Price, 0) * power(10,@WonAmt), 0) / power(10,@WonAmt)   ELSE 0 END ,         
          
                              CASE WHEN A.InOutKind = 8023009 AND A.InOut = -1 THEN  A.Qty   ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023009 AND A.InOut = -1 THEN  ROUND(A.Qty * ISNULL(C.Price, 0) * power(10,@WonAmt), 0) / power(10,@WonAmt)   ELSE 0 END          
                                       
          
                     FROM #_TESMGInOutStock AS A JOIN #TempItem AS B1 ON A.ItemSeq = B1.ItemSeq          
                                                   LEFT OUTER JOIN _TESMGInOutStock AS B  WITH(NOLOCK)          
                                                               ON A.InOutType      = B.InOutType              
                                                              AND A.InOutSeq       = B.InOutSeq              
                                                              AND A.InOutSerl      = B.InOutSerl              
                                                              AND A.DataKind       = B.DataKind              
                                                              AND A.InOutSubSerl   = B.InOutSubSerl     
                                                              AND A.InOutDataSerl  = B.InOutDataSerl       
                                                              AND A.CompanySeq     = B.CompanySeq  
                                                              AND A.ItemSeq        = B.ItemSeq       
                 AND A.CostKeySeq      = B.CostKeySeq         
                 AND A.InOutKind      = B.InOutKind    
                                                              AND B.ESMAdjustSeq = 0   
                                  AND A.ItemSeq       =B.ItemSeq                  
                   
                                                    LEFT OUTER JOIN _TESMBItemStdPrice AS C         
                                                                 ON A.ItemSeq    = C.ItemSeq         
                                                                  AND  (  ( B1.PriceUnit  = 5502002 AND A.AccUnit = C.CostUnit )        
                                                                       OR ( B1.PriceUnit  = 5502003 AND A.BizUnit = C.CostUnit )       
                                                                       )               
                                                                AND C.CompanySeq = @CompanySeq         
                    WHERE A.Companyseq = @CompanySeq          
                      AND  (   (@CostUnit = 0)  
                               OR ( B1.PriceUnit  = 5502002 AND A.AccUnit = @CostUnit )        
                               OR ( B1.PriceUnit  = 5502003 AND A.BizUnit = @CostUnit )        
                           )         
                      AND A.InOutKind <> 8023022         
                    
         
            INSERT INTO #TempStock(ItemSeq , InQty , InAmt,  OutQty ,OutAmt ,  StockQty ,StockAmt  )        
                  SELECT A.ItemSeq , SUM(ISNULL(ProdQty,0)+ISNULL(BuyQty,0) + ISNULL(MvInQty,0) +ISNULL(EtcInQty,0) + ISNULL(ExchangeInQty,0) ),         
                          SUM(ISNULL(ProdAmt, 0) + ISNULL(BuyAmt,0) + ISNULL(MvInAmt ,0) + ISNULL(EtcInAmt, 0) + ISNULL(ExchangeInAmt, 0) ),        
                          SUM(ISNULL(SalesQty ,0)+ ISNULL(InputQty,0) + ISNULL(MvOutQty , 0)+ISNULL(EtcOutQty,0) + ISNULL(ExchangeOutQty,0 )),         
                          SUM(ISNULL(SalesAmt ,0)+ ISNULL(InputAmt,0) + ISNULL(MvOutAmt,0) +ISNULL(EtcOutAmt, 0) + ISNULL(ExchangeOutAmt, 0 )),        
                          0  ,          
                          0        
         
                     FROM #TempStock AS A          
              GROUP BY A.ItemSeq         
         
          
  END         
  ELSE         
  BEGIN          
           
         
            INSERT INTO #TempStock( ItemSeq , ProdQty ,ProdAmt ,BuyQty  ,BuyAmt   ,MvInQty  ,MvInAmt ,EtcInQty ,EtcInAmt ,        
                         ExchangeInQty ,ExchangeInAmt ,SalesQty,SalesAmt,InputQty ,InputAmt ,MvOutQty,MvOutAmt ,EtcOutQty,        
                         EtcOutAmt ,ExchangeOutQty ,ExchangeOutAmt    )         
             SELECT A.ItemSeq ,CASE WHEN A.InOutKind = 8023016 OR A.InOutKind = 8023017 THEN  A.Qty  ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023016 OR A.InOutKind = 8023017  THEN  ISNULL(B.Amt , 0)   ELSE 0 END ,         
                              CASE WHEN A.InOutKind IN( 8023019 ,8023036,8023045,8023046) THEN  A.Qty * A.InOut   ELSE 0 END ,         
                              CASE WHEN A.InOutKind IN( 8023019 ,8023036,8023045,8023046) THEN  A.Amt * A.InOut   ELSE 0 END ,         
         
                              CASE WHEN A.InOutKind = 8023008 AND A.InOut =  1 THEN  A.Qty   ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023008 AND A.InOut =  1 THEN   ISNULL(B.Amt , 0)   ELSE 0 END ,         
         
                              CASE WHEN A.InOutKind = 8023004  THEN  A.Qty   ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023004  THEN  A.Amt   ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023009 AND A.InOut =  1  THEN  A.Qty   ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023009 AND A.InOut =  1  THEN  B.Amt   ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023002  THEN  A.Qty   ELSE 0 END , ---���⼭���� ���         
                              CASE WHEN A.InOutKind = 8023002  THEN  ISNULL(B.Amt , 0)    ELSE 0 END ,         
                                CASE WHEN A.InOutKind = 8023015 OR A.InOutKind = 8023021 THEN A.Qty   ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023015 OR A.InOutKind = 8023021 THEN ISNULL(B.Amt , 0)  ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023008 AND A.InOut = -1 THEN  A.Qty   ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023008 AND A.InOut = -1 THEN  ISNULL(B.Amt , 0)   ELSE 0 END ,         
         
                              CASE WHEN A.InOutKind = 8023003  THEN  A.Qty   ELSE 0 END ,            
                              CASE WHEN A.InOutKind = 8023003  THEN  ISNULL(B.Amt , 0)   ELSE 0 END ,         
          
                              CASE WHEN A.InOutKind = 8023009 AND A.InOut = -1 THEN  A.Qty   ELSE 0 END ,         
                              CASE WHEN A.InOutKind = 8023009 AND A.InOut = -1 THEN  ISNULL(B.Amt , 0)   ELSE 0 END            
                     FROM #_TESMGInOutStock AS A  JOIN #TempItem AS B1 ON A.ItemSeq = B1.ItemSeq          
                                                  LEFT OUTER JOIN _TESMGInOutStock AS B  WITH(NOLOCK)          
                                                               ON A.InOutType      = B.InOutType              
                                                              AND A.InOutSeq       = B.InOutSeq              
                                                              AND A.InOutSerl      = B.InOutSerl               
                                                              AND A.DataKind       = B.DataKind              
                                                              AND A.InOutSubSerl   = B.InOutSubSerl          
                                                              AND A.InOutDataSerl  = B.InOutDataSerl       
                                                              AND A.CompanySeq     = B.CompanySeq   
                                                              AND A.ItemSeq        = B.ItemSeq    
                 AND A.CostKeySeq     = B.CostKeySeq            
                 AND A.InOutKind      = B.InOutKind                    
                    WHERE A.Companyseq = @CompanySeq          
                      AND  (   (@CostUnit = 0)  
                               OR ( B1.PriceUnit  = 5502002 AND A.AccUnit = @CostUnit )        
                               OR ( B1.PriceUnit  = 5502003 AND A.BizUnit = @CostUnit )        
                           )         
                      AND A.InOutKind <> 8023022    
                   
    
 ----����ȸ�� ����ó���� ����   
             INSERT INTO #TempStock( ItemSeq , ProdQty ,ProdAmt ,BuyQty  ,BuyAmt   ,MvInQty  ,MvInAmt ,EtcInQty ,EtcInAmt ,        
                         ExchangeInQty ,ExchangeInAmt ,SalesQty,SalesAmt,InputQty ,InputAmt ,MvOutQty,MvOutAmt ,EtcOutQty,        
                         EtcOutAmt ,ExchangeOutQty ,ExchangeOutAmt    )         
             SELECT A.ItemSeq ,0 ,0 ,0  ,0   ,0  ,0 ,0 ,0 ,        
                         0 ,0 ,0,0,0 ,0 ,0,CASE WHEN A.InOutKind = 8023008 THEN A.Amt ELSE 0 END  ,0,        
                         CASE WHEN A.InOutKind <> 8023008 THEN  A.Amt ELSE 0 END ,0 ,0  
              FROM  _TESMGInOutStock   AS A    
                    JOIN #TempItem     AS B1 ON A.ItemSeq = B1.ItemSeq      
                    JOIN #COSTKEY      AS K  ON A.CostKeySeq       = K.CostKeySeq     
             WHERE A.CompanySeq = @CompanySeq          
               AND A.InOutDate  BETWEEN @CostYMFr +'01' AND @CostYMTo +'31'            
               AND ( (@CostUnit = 0)  
                   OR( B1.PriceUnit = 5502002 AND A.AccUnit = @CostUnit )             
                   OR( B1.PriceUnit = 5502003 AND A.BizUnit = @CostUnit )             
                    )         
               AND A.ESMAdjustSeq <> 0   
               AND A.InOutKind = 8023003   --2011.10.18 �߰� ����Ʈ������ �԰��� ������ �߻��� �� ����  
                --2011.10.18 �߰� ����Ʈ������ �԰��� ������ �߻��� �� ����   
              INSERT INTO #TempStock( ItemSeq , ProdQty ,ProdAmt ,BuyQty  ,BuyAmt   ,MvInQty  ,MvInAmt ,EtcInQty ,EtcInAmt ,          
                     ExchangeInQty ,ExchangeInAmt ,SalesQty,SalesAmt,InputQty ,InputAmt ,MvOutQty,MvOutAmt ,EtcOutQty,          
                     EtcOutAmt ,ExchangeOutQty ,ExchangeOutAmt    )           
             SELECT A.ItemSeq ,0 ,A.Amt ,0  ,0   ,0  ,0 ,0 ,0 ,          
                         0 ,0 ,0,0,0 ,0 ,0,0 ,0,          
                         0 ,0 ,0    
              FROM  _TESMGInOutStock AS A  JOIN   #TempItem AS B1 ON A.ItemSeq = B1.ItemSeq    
                    JOIN #COSTKEY      AS K  ON A.CostKeySeq       = K.CostKeySeq                     
             WHERE A.CompanySeq = @CompanySeq        
               AND A.InOutDate  BETWEEN @CostYMFr +'01' AND @CostYMTo +'31'              
               AND ( (@CostUnit = 0)    
                   OR( B1.PriceUnit = 5502002 AND A.AccUnit = @CostUnit )               
                   OR( B1.PriceUnit = 5502003 AND A.BizUnit = @CostUnit )               
                    )           
               AND A.ESMAdjustSeq <> 0     
               AND A.InOutKind = 8023016     
    
             INSERT INTO #TempStock(ItemSeq , InQty , InAmt,  OutQty ,OutAmt , StockQty ,StockAmt  )        
                  SELECT A.ItemSeq , SUM(ISNULL(ProdQty,0)+ISNULL(BuyQty,0) + ISNULL(MvInQty,0) +ISNULL(EtcInQty,0) + ISNULL(ExchangeInQty,0) ),         
                          SUM(ISNULL(ProdAmt, 0) + ISNULL(BuyAmt,0) + ISNULL(MvInAmt ,0) + ISNULL(EtcInAmt, 0) + ISNULL(ExchangeInAmt, 0) ),        
                          SUM(ISNULL(SalesQty ,0)+ ISNULL(InputQty,0) + ISNULL(MvOutQty , 0)+ISNULL(EtcOutQty,0) + ISNULL(ExchangeOutQty,0 )),         
                          SUM(ISNULL(SalesAmt ,0)+ ISNULL(InputAmt,0) + ISNULL(MvOutAmt,0) +ISNULL(EtcOutAmt, 0) + ISNULL(ExchangeOutAmt, 0 )),        
                          0,         
                          0         
                     FROM #TempStock AS A          
              GROUP BY A.ItemSeq         
           
                   
 END --�����ܰ��̸�..        
     
         
 --8023000 �̿�����        
 --8023002 �������        
 --8023003 ��Ÿ���        
 --8023004 ��Ÿ�԰�        
 --8023008 �̵�ó��        
 --8023009 �԰ݴ�ü        
 --8023012 ����ó��        
 --8023015 ��������        
 --8023016 ��ǰ�԰�        
 --8023021 ������������        
 --8023022 �⸻���        
 --8023017 ��������(�����԰�)        
     INSERT INTO #TempStock( ItemSeq      , PreQty       ,PreAmt         ,ProdQty       ,ProdAmt        ,BuyQty     ,BuyAmt   ,        
                            MvInQty       ,MvInAmt       ,EtcInQty       ,EtcInAmt   ,        
                            ExchangeInQty ,ExchangeInAmt ,SalesQty       ,SalesAmt   ,        
                            InputQty      ,InputAmt      ,MvOutQty       ,MvOutAmt   ,        
                            EtcOutQty     ,EtcOutAmt     ,ExchangeOutQty ,ExchangeOutAmt  ,        
                            InQty         ,OutAmt        ,InAmt          ,OutQty ,        
                            StockQty      , StockAmt     , SumYn         ,StockQty2  , StockAmt2)         
         SELECT  ItemSeq,    SUM(ISNULL(PreQty, 0))      , SUM(ISNULL(PreAmt, 0)) ,SUM(ISNULL(ProdQty, 0))     , SUM(ISNULL(ProdAmt, 0)) , SUM(ISNULL(BuyQty, 0)) , SUM(ISNULL(BuyAmt, 0)) ,        
                             SUM(ISNULL(MvInQty, 0))     , SUM(ISNULL(MvInAmt, 0)) , SUM(ISNULL(EtcInQty, 0)),  SUM(ISNULL(EtcInAmt, 0)) ,        
                             SUM(ISNULL(ExchangeInQty,0)), SUM(ISNULL(ExchangeInAmt, 0)),  SUM(ISNULL(SalesQty, 0)),  SUM(ISNULL(SalesAmt, 0)) ,        
                             SUM(ISNULL(InputQty, 0))    , SUM(ISNULL(InputAmt, 0)),  SUM(ISNULL(MvOutQty, 0)),  SUM(ISNULL(MvOutAmt, 0)) ,        
                             SUM(ISNULL(EtcOutQty, 0))   , SUM(ISNULL(EtcOutAmt, 0)),  SUM(ISNULL(ExchangeOutQty, 0)),  SUM(ISNULL(ExchangeOutAmt, 0)) ,        
                             SUM(ISNULL(InQty, 0))       , SUM(ISNULL(OutAmt, 0)),  SUM(ISNULL(InAmt, 0)),  SUM(ISNULL(OutQty, 0)) ,        
      SUM(ISNULL(PreQty, 0) + ISNULL(InQty, 0) - ISNULL(OutQty, 0) )    , SUM(ISNULL(PreAmt, 0)+ ISNULL(InAmt, 0) -ISNULL(OutAmt, 0) )  , '1'       ,  
                             SUM(ISNULL(StockQty2, 0))              , SUM(ISNULL(StockAmt2, 0))  
         FROM #TempStock AS A         
        GROUP BY ItemSeq   
      
      
    --2010.03.04 Jihlee ����,�ݾ��� ���°� �����ϱ�        
    DELETE FROM #TempStock        
       WHERE ABS(PreQty) + ABS(PreAmt) + ABS(ProdQty) + ABS(ProdAmt) +   
       ABS(BuyQty) + ABS(BuyAmt) + ABS(MvInQty) + ABS(MvInAmt) +   
       ABS(EtcInQty) + ABS(EtcInAmt) + ABS(ExchangeInQty) + ABS(ExchangeInAmt) +   
       ABS(SalesQty) + ABS(SalesAmt) + ABS(InputQty) + ABS(InputAmt) +   
       ABS(MvOutQty) + ABS(MvOutAmt) + ABS(EtcOutQty) + ABS(EtcOutAmt) +   
       ABS(ExchangeOutQty) + ABS(ExchangeOutAmt) + ABS(InQty) + ABS(OutAmt) +   
       ABS(InAmt) + ABS(OutQty)  + ABS(StockQty) + ABS(StockQty2) + ABS(StockAmt) + ABS(StockAmt2) = 0  --���ó�� �� �԰� �����Ͽ� ������������� ���� ���̽��� �־ ����.  
      
    SELECT @CostUnit,   
           @ItemKind AS ItemKind, 
           A.PreAmt,                                 
           A.EtcOutAmt,                    
           A.StockAmt, 
           
           A.BuyQty, -- ���ż���
           A.BuyAmt, -- ���űݾ�
           A.EtcInAmt, -- ��Ÿ�԰�ݾ�
           
           A.PreQty, 
           A.ProdQty, 
           A.ProdAmt, 
           A.InPutQty,
           A.InPutAmt 
           
           
           
      FROM #TempStock           AS A   
                 JOIN _TDAItem       AS C WITH(NOLOCK) ON a.ItemSeq = C.ItemSeq AND C.CompanySeq = @CompanySeq           
                 JOIN _TDAItemAsset  AS D WITH(NOLOCK) ON C.AssetSeq = D.AssetSeq AND  D.CompanySeq = @CompanySeq           
                 JOIN _TDAUnit       AS U WITH(NOLOCK) ON C.UnitSeq = U.UnitSeq AND  U.CompanySeq = @CompanySeq    
                 JOIN _TDAITemClass  AS IC WITH(NOLOCK) ON C.ItemSeq = IC.ItemSeq AND C.CompanySeq = IC.CompanySeq AND IC.UMajorItemClass IN (2001,2004)    
      LEFT OUTER JOIN #ItemClass AS I    ON IC.UMItemClass = I.ItemClassSSeq  
     WHERE ISNULL( SumYn, '0') = '1'   
       AND ( (@IsDiff = '1' AND (A.StockQty  - A.StockQty2 <> 0 OR A.StockAmt  - A.StockAmt2 <> 0))  
           OR @IsDiff = '0' OR @IsDiff = ''  
           )  
     ORDER BY A.ItemSeq, C.ItemNo, C.ItemName,  C.Spec, D.AssetName            
      
 RETURN  