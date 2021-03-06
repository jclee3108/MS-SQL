IF OBJECT_ID('KPX_SESMCCostSlipGetEtcDataQuery') IS NOT NULL 
    DROP PROC KPX_SESMCCostSlipGetEtcDataQuery
GO 

-- v2015.12.21 

-- 포장용기 하드코딩 -> 추가정보설정값으로 변경 by이재천 
/************************************************************    
 설  명 - D-원가결산전표처리 : 기타입출데이터가져오기    
 작성일 - 20090413    
 작성자 - 이지해    
 내용   - 물류의 기타출고, 기타입고된 내역의 전표처리를 하는 sp임 (자재,상품,제품)
          제품의 경우 원가계산전과 후가 있는데 전은 제조원가비용으로 출고된 품목을 처리하고
          후는 제품의 기타입고 제조원가비용이 아닌 기타출고건, 
               제조원가비용으로 만들어진 것과 재고비용의 차이가 출고건이 없을 경우 보정처리 되는 부분이 나오게 된다.
 추가정보 - 기타입고구분, 기타출고구분의 계정.비용구분을 사용함.
            기타입고구분(1001	계정과목,1002	비용구분)
            기타출고구분(2003	계정과목,2004	비용구분)
수정일 - 2011.06.30 지해 1) 기타입출고 전표처리에서 부서로 말고 거래처로 집계 가능하도록 옵션 추가 
                            => 현재시점이후에 적용될 경우 _TESMGINOutstock의  custseq에 기타출고에 대한 데이터도 집계 가능하도록 수정처리함.
ALTER TABLE _TESMCProdSlipD ADD UMRealDetilKind    INT
************************************************************/    
CREATE PROCEDURE KPX_SESMCCostSlipGetEtcDataQuery
    @xmlDocument    NVARCHAR(MAX),                
    @xmlFlags       INT = 0,                
    @ServiceSeq     INT = 0,                
    @WorkingTag     NVARCHAR(10)= '',                
    @CompanySeq     INT = 1,                
    @LanguageSeq    INT = 1,                
    @UserSeq        INT = 0,                
    @PgmSeq         INT = 0                
              
AS                  
              
DECLARE	@docHandle      INT,          
        @MessageType    INT,              
        @Status         INT,              
        @Results        NVARCHAR(250),            
        @CostUnit       INT,    
        @CostYM         CHAR(6)      ,            
        @RptUnit        INT,    
        @SMCostMng      INT,    
        @CostMngAmdSeq  INT,    
        @PlanYear       NCHAR(4),    
        @SMSlipKind     INT,
        @IsDivideCCtrItem INT,
        @YAVGAdjTransType INT 
             
    -- 서비스 마스타 등록 생성              
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument          
           
	SELECT	@CostUnit         = ISNULL(CostUnit       ,0),          
			@RptUnit          = ISNULL(RptUnit        ,0),    
			@SMCostMng        = ISNULL(SMCostMng      ,0),    
			@CostMngAmdSeq    = ISNULL(CostMngAmdSeq  ,0),    
			@SMSlipKind       = ISNULL(SMSlipKind     ,0),      
			@CostYM           = ISNULL(CostYM         ,''),      
			@PlanYear         = ISNULL(PlanYear       ,'')        
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1',@xmlFlags)          
	  WITH (CostUnit          INT , RptUnit           INT ,      
			SMCostMng         INT , CostMngAmdSeq     INT ,    
			SMSlipKind        INT , CostYM            NCHAR(6),    
			PlanYear          NCHAR(4))          

    CREATE TABLE #AssetSeq 
    (AssetSeq INT)

DECLARE @CostKeySeq             INT,
		@cTRANsAdjAccSeq        INT,
		@cTRANsAdjUMcostTypeSeq INT,
		@MatPriceUnit           INT    
    
	EXEC @CostKeySeq = dbo._SESMDCostKeySeq @CompanySeq,@CostYM ,@RptUnit,@SMCostMng,@CostMngAmdSeq,@PlanYear,@PgmSeq    

 
 CREATE TABLE #Slip (WorkingTag NCHAR(1) NULL)  
 EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#Slip'  
 IF @@ERROR <> 0 RETURN  

    --반제품 재공으로 처리 옵션
    DECLARE @BanToProc INT 
    EXEC dbo._SCOMEnv @CompanySeq,5547,0  /*@UserSeq*/,@@PROCID,@BanToProc OUTPUT
    
    
    DECLARE @FSDomainSeq INT           
    --SELECT @FSDomainSeq = 11  --추후변경해야함.   
    
 ----제품단가계산에 따라 Sub호출을 연총평균, 선입선출, 월총평균으로 나뉘어서 처리해야한다.     
    
      
   IF @SMCostMng IN (5512001 , 5512004 )     --5512001/관리회계          , 5512004/기본원가                 
      SELECT @FSDomainSeq =  FSDomainSeq FROM _TCOMFSDomain WITH(NOLOCK) WHERE CompanySeq =@CompanySeq AND FSDomainNo = 'GAAPFS'           
   ELSE IF @SMCostMng IN (5512005 , 5512006) --5512005/IFRS(관리회계)    , 5512006/IFRS(기본원가)           
      SELECT @FSDomainSeq =  FSDomainSeq FROM _TCOMFSDomain WITH(NOLOCK) WHERE CompanySeq =@CompanySeq AND FSDomainNo = 'IFRSFS'           
   ELSE IF @SMCostMng IN (5512007 , 5512008) --5512007/보고결산(관리회계) , 5512008/보고결산(기본원가)     
    BEGIN       
       SELECT @FSDomainSeq = FSDomainSeq FROM _TCRRptUnit WITH(NOLOCK) WHERE RptUnit = @RptUnit AND CompanySeq = @CompanySeq       
    END        
          



--    1)당월처리된 내역삭제    
--    이미 전표 처리된 내역은 기존 데이터 불러다 보여주기
 

    IF EXISTS (SELECT 1 FROM KPX_TESMCProdSlipM A 
                WHERE A.CompanySeq     = @CompanySeq    
                  AND A.CostUnit       = @CostUnit    
                  AND A.CostKeySeq     = @CostKeySeq
                  AND A.SMSlipKind     = @SMSlipKind     
                  AND A.SlipSeq        > 0)
    BEGIN
        
--        -------------------------------------------  
--        -- 전표처리 여부 
--        -------------------------------------------  
--        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
--                              @Status      OUTPUT,  
--                              @Results     OUTPUT,  
--                              15                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE languageseq = 1 and messageDefault like '%전표%' MessageSeq = 6)  
--                              @LanguageSeq       ,   
--                              0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%관점%'  
--
--
--       UPDATE #Slip    
--           SET Result        =@Results,    
--               MessageType   = @MessageType,    
--               Status        = @Status    
--        SELECT * FROM #Slip
--        RETURN 

        GOTO Proc_Query
    END 
    ELSE 
    BEGIN
		DELETE KPX_TESMCProdSlipD    
          FROM KPX_TESMCProdSlipM      AS A     
          JOIN KPX_TESMCProdSlipD AS B ON A.CompanySeq = B.CompanySeq    
                                   AND A.TransSeq   = B.TransSeq    
         WHERE A.CompanySeq = @CompanySeq    
           AND A.CostUnit   = @CostUnit    
           AND A.CostKeySeq = @CostKeySeq
           AND A.SMSlipKind = @SMSlipKind    
    END

    --처리 데이터 들어가는 데이틀
    CREATE TABLE #TempInOut    
    (    
        SMSlipKind         INT ,     --전표구분    
        INOutDetailKind    INT ,     --입출고구분    
        Remark             NVARCHAR(100),     
        AssetSeq           INT ,     -- 재고자산분류    
        DrAccSeq           INT ,     -- 계정코드    
        DrUMCostType       INT ,                
        CrAccSeq           INT ,     -- 재고자산계정코드    
        CrUMCostType       INT ,    
        Amt                DECIMAL(19,5),  -- 금액    
        ShowOrder          INT ,     
        DeptSeq            INT ,    
        CCtrSeq            INT ,
        CustSeq            INT ,     --매출거래처/기타출고 거래처.
        GoodItemSeq        INT ,      --투입제품
        ISSum              INT NULL , --2011.06.30 거래처, 부서의 집계를 위하여 추가
        UMRealDetilKind    INT NULL  --2011.09.02 기타입출고 구분별 집계를 위하여 추가
            )    
            
--###############연총평균용 시작 #################################################################--
            
      --처리 데이터 들어가는 데이터(타계정을 위한 임시집계 테이블)
    CREATE TABLE #TempInOut_Garbege    
    (    
        SMSlipKind         INT ,     --전표구분    
        INOutDetailKind    INT ,     --입출고구분    
        Remark             NVARCHAR(100),     
        AssetSeq           INT ,     -- 재고자산분류    
        DrAccSeq           INT ,     -- 계정코드    
        DrUMCostType       INT ,                
        CrAccSeq           INT ,     -- 재고자산계정코드    
        CrUMCostType       INT ,    
        Amt                DECIMAL(19,5),  -- 금액    
        ShowOrder          INT ,     
        DeptSeq            INT ,    
        CCtrSeq            INT ,
        CustSeq            INT ,     --매출거래처/기타출고 거래처.
        GoodItemSeq        INT ,      --투입제품
        UMRealDetilKind    INT NULL,  --2011.09.02 기타입출고 구분별 집계를 위하여 추가
        IsFromOtherAcc     NCHAR(1) NULL
            )   
            
    --타계정으로 대체의 계정
    CREATE TABLE #OtherAcc(
        AssetSeq   INT,
        IsFromOtherAcc NCHAR(1),
        DrAccSeq     INT,
DrUMCostType INT,
        CrAccSeq     INT,
        CrUMCostType INT,
        DrOrCr       int)
    
    INSERT INTO #OtherAcc --차변 타계정으로 
    SELECT A.AssetSeq,A.IsFromOtherAcc, B.AccSeq,  B.UMCostType,0,0,-1
     FROM _TDAItemAsset AS A 
         JOIN _TDAItemAssetAcc AS B ON A.CompanySeq = B.CompanySeq
                                   AND A.AssetSEq   = B.AssetSeq
    WHERE A.Companyseq = @CompanySeq       
      AND AssetAccKindSeq = 21 --타계정으로 
      AND A.IsFromOtherAcc = '1'
      
    INSERT INTO #OtherAcc  --대변 타계정으로 
    SELECT AssetSeq,IsFromOtherAcc,0,0,DrAccSeq,DrUMCostType,1
      FROM #OtherAcc
      

      
     INSERT INTO #AssetSeq  
     SELECT  E.AssetSeq   
      FROM  _TDAItemAsset  AS E WITH(NOLOCK)  
                    JOIN _TDAItemAssetAcc    AS N WITH(NOLOCK) ON E.CompanySeq       = N.CompanySeq      
                                                             AND E.AssetSeq         = N.AssetSeq       
                                                             AND  N.AssetAccKindSeq  = 23 --매출보정계정  
                    JOIN _TDAItemAssetAcc    AS O WITH(NOLOCK) ON E.CompanySeq       = O.CompanySeq      
                                                             AND E.AssetSeq         = O.AssetSeq       
                                                             AND  O.AssetAccKindSeq  = 24 --기타보정계정  
                    JOIN _TDAItemAssetAcc    AS M WITH(NOLOCK) ON E.CompanySeq       = M.CompanySeq      
                                                             AND E.AssetSeq         = M.AssetSeq      
                                                             AND M.AssetAccKindSeq  = 6 --매출원가계정   
       WHERE E.CompanySeq = @CompanySeq            
        AND ( @BanToProc <> '1' OR (@BanToProc = '1' AND E.SMAssetGrp <> 6008004)) --반제품 재공으로 옵션 사용시 타계정 나옴
    --5555:연총평균보정전표 매출원가/기타출고 보정건 활동센터별 품목별 집계여부 
    --연총평균보정전표 매출원가/기타출고 보정건 활동센터별 품목별 집계하여 내역조회가 됨.
    EXEC dbo._SCOMEnv @CompanySeq,5555 ,0  /*@UserSeq*/,@@PROCID,@IsDivideCCtrItem OUTPUT    
    
    --5551:연총평균 출고금액 보정 조건
    --연총평균시 출고금액의 보정건 발생하면 보정방법을 선택합니다.(원천데이터별보정/출고구분별 보정)
    EXEC dbo._SCOMEnv @CompanySeq,5551 ,0  /*@UserSeq*/,@@PROCID,@YAVGAdjTransType OUTPUT    
     --@YAVGAdjTransType
     ----원천데이터별 보정	    5536001
     ----출고구분별 보정		5536002


      
--###############연총평균용 끝 #################################################################--
DECLARE	@ItemPriceUnit  INT ,
        @GoodPriceUnit  INT ,
        @FGoodPriceUnit INT 

    EXEC dbo._SCOMEnv @CompanySeq, 5521,@UserSeq,@@PROCID,@ItemPriceUnit OUTPUT   --자재단가계산단위 

    EXEC dbo._SCOMEnv @CompanySeq, 5522,@UserSeq,@@PROCID,@GoodPriceUnit OUTPUT   --상품단가계산단위 

    EXEC dbo._SCOMEnv @CompanySeq, 5523,@UserSeq,@@PROCID,@FGoodPriceUnit OUTPUT  --제품단가계산단위 

--5535001 5535 연총평균 매출원가조정  
--5535002 5535 연총평균 투입금액조정  
--5535003 5535 연총평균 기타출고금액 조정  
  
    EXEC dbo._SCOMEnv @CompanySeq,5555 ,0  /*@UserSeq*/,@@PROCID,@IsDivideCCtrItem OUTPUT    
    

---------------제품일경우 사용하는 항목-----------------------------------------------------
--    IF @SMSlipKind IN (5522007,5522006,5522012)
--    BEGIN
		--사용가능한 원가계정가져오기    
		--재료비,노무비,경비    
		CREATE TABLE  #ESMAccount ( SMCostKind INT ,SMCostDiv INT , CostAccSeq INT , AccSeq INT  , BgtSeq INT , UMCostType INT )      

        EXEC _SESMBAccountScopeQuery @CompanySeq , @FSDomainSeq , 5507001 ,  0        
           
        CREATE TABLE #ESMProdAcc( AccSeq INT ,UMCostType INT)
    
        CREATE TABLE #ESMMatAcc( AccSeq INT ,UMCostType INT)

		INSERT INTO #ESMProdAcc
		SELECT DISTINCT ACCSEQ ,UMCostType FROM #ESMAccount WHERE SMCostDiv = 5507001   --제조원가계정 확인하는데 쓴다.
    
		INSERT INTO #ESMMatAcc
		SELECT DISTINCT ACCSEQ ,UMCostType FROM #ESMAccount WHERE SMCostKind = 5519001   --재료비 계정 확인에 사용

   
--    END


	IF @SMSlipKind = 5522007        --5522007 기타입출고전표_제품원가계산전    
		GOTO PROC_PreProd
	ELSE IF @SMSlipKind = 5522006   --5522006  기타입출고전표_제품    
		GOTO PROC_AfterProd
	ELSE IF @SMSlipKind = 5522005   --5522005  기타입출고전표_상품    
		GOTO PROC_Goods
	ELSE IF @SMSlipKind = 5522004   --5522004  기타입출고전표_자재    
		GOTO Proc_Mat
	ELSE IF @SMSlipKind = 5522012   --5522012  연총평균 보정전표_제품   
		GOTO AVG_Prod
	ELSE IF @SMSlipKind = 5522014   --5522014  연총평균 보정전표_상품    
		GOTO AVG_Goods
	ELSE IF @SMSlipKind = 5522013   --5522013  연총평균 보정전표_자재    
		GOTO AVG_Mat
	ELSE IF @SMSlipKind = 5522015	--5522015 기타입출고전표_제품(품목별)
		GOTO Proc_ItemAfterProd
	ELSE 
		GOTO Proc_Query
	RETURN 

/*****************************************************************************************/
PROC_PreProd:  --5522007 기타입출고전표_제품원가계산전    

    --2) 운영환경관리값 가져오기    
    DECLARE @SMGoodSetPrice    INT        
    -- 제품기타출고시 적용단가    
    EXEC dbo._SCOMEnv @CompanySeq, 5539,@UserSeq,@@PROCID,@SMGoodSetPrice OUTPUT    
    --5523001  전월 재고단가    
    --5523002  표준 재고단가    
    --5523003  표준원가    
   
    CREATE TABLE #GoodPrice    
    (ItemSeq    INT,    
     StkPrice   DECIMAL(19,5))    
    

 
    IF @SMGoodSetPrice = 5523001 --전월재고단가    
    BEGIN    
       -- 전월 키를 가지고 온다.    

        DECLARE @PreCostKeySeq   INT    
                
        SELECT TOP 1 @PreCostKeySeq = CostKeySeq    
          FROM _TESMDCostKey  AS A     
         WHERE A.CompanySeq    = @CompanySeq    
           AND A.CostYM        < @CostYM    
           AND A.RptUnit       = @RptUnit    
           AND A.SMCostMng     = @SMCostMng    
           AND A.CostMngAmdSeq = @CostMngAmdSeq    
           AND A.PlanYear      = @PlanYear    
         ORDER BY A.CostYM DESC    
        
        --전월 재고단가의 금액을 가지고 온다.     
        INSERT INTO #GoodPrice (ItemSeq, StkPrice)    
        SELECT A.itemSeq, ISNULL(C.Price,0)    
          FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
                     JOIN _TDAItem           AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                              AND A.ItemSeq    = D.ItemSeq    
                     JOIN _TDAItemAsset      AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                              AND D.AssetSeq   = E.AssetSeq     
                     JOIN _TDASMInor         AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                              AND E.SMAssetGrp = F.MinorSeq    
          LEFT OUTER JOIN _TESMCProdStkPrice AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq    
                                                              AND A.ItemSeq    = C.ItemSeq    
                                                              AND C.CostUnit   = A.CostUnit     
                                                              AND C.CostKeySeq = @PreCostKeySeq     
         WHERE A.CompanySeq = @CompanySeq 
		   AND A.CostKeySeq = @CostKeySeq   
           AND F.MinorValue = '0'    --제품/상품    
           AND A.InOutDate  LIKE @CostYM + '%'    
           AND A.InOutKind  = 8023003
           AND ( (@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
              OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ) )

           AND F.MinorSeq <> 6008001 -- 상품제외    
           --기타출고 계정에 설정된 계정 범위 한정시키기.    
    
    
		-- 전월 재고단가가 없을 경우 표준재고단가를 사용한다.     
		UPDATE #GoodPrice    
		   SET StkPrice = ISNULL(B.Price,0)    
		  FROM  #GoodPrice AS A     
		  JOIN _TESMBItemStdPrice AS B ON B.CompanySeq = @CompanySeq
									  AND A.ItemSeq    = B.ItemSeq 
          LEFT OUTER JOIN _TESMCProdStkPrice AS C WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq    --2011.02.01  지해: 전월재고단가없는경우 추가.ㅠ,.ㅠ
                                                              AND B.ItemSeq    = C.ItemSeq    
                                                              AND B.CostUnit   = C.CostUnit     
                                                              AND C.CostKeySeq = @PreCostKeySeq   
		 WHERE B.CostUnit = @CostUnit    
           AND C.Price IS NULL 
	     

		--출고금액 Update     
		UPDATE _TESMGInOutStock    
		   SET Amt      = Round(ISNULL(C.StkPrice, 0) * A.Qty,0)    
		  FROM _TESMGInOutStock           AS A WITH(NOLOCK)    
					 JOIN _TDAItem        AS D WITH(NOLOCK) ON A.CompanySeq  = D.CompanySeq    
															AND A.ItemSeq    = D.ItemSeq    
					 JOIN _TDAItemAsset   AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
															AND D.AssetSeq   = E.AssetSeq     
					 JOIN _TDASMInor      AS F WITH(NOLOCK) ON E.CompanySeq  = F.CompanySeq    
															AND E.SMAssetGrp = F.MinorSeq    
		  LEFT OUTER JOIN #GoodPrice      AS C WITH(NOLOCK) ON A.ItemSeq     = C.ItemSeq        
		  LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq  = J.CompanySeq    
														   AND A.InOutDetailKind = J.MinorSeq    
														   AND J.ValueSeq    > 0    
														   AND J.Serl        = '2003'      -- 계정과목 
		  LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq  = K.CompanySeq    
														   AND A.InOutDetailKind = K.MinorSeq    
														   AND K.Serl            = '2004'      -- 비용구분  
					 JOIN #ESMProdAcc     AS Z              ON J.ValueSeq        = Z.AccSeq    
                                                           AND K.ValueSeq        = Z.UMCostType                                                         
		 WHERE A.CompanySeq = @CompanySeq    
		   AND A.CostKeySeq = @CostKeySeq
		   AND F.MinorValue  = '0'    
		   AND F.MinorSeq <> 6008001 -- 상품제외    
		   AND A.InOutDate LIKE @CostYM + '%'    
		   AND A.InOutKind = 8023003
		   AND ( (@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
			  OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ) )
--		   AND C.StkPrice <> 0     --이렇게 해두면 전월이나 표준재고단가값이 없어졌을때 0으로 되어야 하는데 업데이트안되고 그대로 남게됨. 
 

	 
	END    
    ELSE IF  @SMGoodSetPrice = 5523002 --표준재고단가    
    BEGIN 
		UPDATE _TESMGInOutStock    
           SET Amt      = Round(ISNULL(C.Price,0) * A.Qty,0)    
          FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
                     JOIN _TDAItem           AS D WITH(NOLOCK) ON A.CompanySeq  = D.CompanySeq    
                                                              AND A.ItemSeq     = D.ItemSeq    
                     JOIN _TDAItemAsset      AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                              AND D.AssetSeq    = E.AssetSeq     
                     JOIN _TDASMInor         AS F WITH(NOLOCK) ON E.CompanySeq  = F.CompanySeq    
                                                              AND E.SMAssetGrp  = F.MinorSeq    
          LEFT OUTER JOIN _TESMBItemStdPrice AS C WITH(NOLOCK) ON A.CompanySeq  = C.CompanySeq
														      AND A.ItemSeq     = C.ItemSeq                                                                       
                                                              AND C.CostUnit    = @CostUnit    
                                                              AND C.CostUnitKind     = @FGoodPriceUnit     
          LEFT OUTER JOIN _TDAUMinorValue    AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                              AND A.InOutDetailKind  = J.MinorSeq    
                                                              AND J.ValueSeq         > 0    
                                                              AND J.Serl             = '2003'     -- 계정과목    
          LEFT OUTER JOIN _TDAUMinorValue    AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                              AND A.InOutDetailKind  = K.MinorSeq    
                                                              AND K.Serl             = '2004'     -- 비용구분    
                   JOIN #ESMProdAcc          AS Z              ON J.ValueSeq = Z.AccSeq               
                                                              AND K.ValueSeq        = Z.UMCostType
         WHERE A.CompanySeq = @CompanySeq 
           AND A.CostKeySeq = @CostKeySeq   
           AND F.MinorValue  = '0'    
           AND F.MinorSeq <> 6008001 -- 상품제외    
           AND A.InOutDate LIKE @CostYM + '%'    
           AND A.InOutKind = 8023003 
           AND ( (@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
              OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ) )
--		   AND C.Price <> 0     
 

 

    END    
    ELSE --표준원가    
    BEGIN    
		UPDATE _TESMGInOutStock    
           SET Amt      = Round(ISNULL(C.CostStdPrice,0) * A.Qty,0)    
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                     JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq  = D.CompanySeq    
                                                             AND A.ItemSeq     = D.ItemSeq    
                     JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                             AND D.AssetSeq    = E.AssetSeq     
                     JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq  = F.CompanySeq    
                                                             AND E.SMAssetGrp  = F.MinorSeq    
          LEFT OUTER JOIN _TESMSItemStdCost AS C WITH(NOLOCK) ON A.CompanySeq  = C.CompanySeq 
															 AND A.ItemSeq     = C.ItemSeq                                                                       
                                                             AND A.CostUnit    = C.CostUnit    
          LEFT OUTER JOIN _TDAUMinorValue   AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                             AND A.InOutDetailKind  = J.MinorSeq    
                                                             AND J.ValueSeq         > 0    
                                                             AND J.Serl             = '2003'   -- 계정과목      
           LEFT OUTER JOIN _TDAUMinorValue  AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                             AND A.InOutDetailKind  = K.MinorSeq    
                                                             AND K.Serl             = '2004'   -- 비용구분    
                   JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq                 
                                                             AND K.ValueSeq        = Z.UMCostType
            WHERE A.CompanySeq = @CompanySeq 
              AND A.CostKeySeq = @CostKeySeq    
              AND F.MinorValue  = '0'    
              AND F.MinorSeq <> 6008001 -- 상품제외    
              AND A.InOutDate LIKE @CostYM + '%'    
              AND A.InOutKind = 8023003     
              AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
                   OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
--              AND C.CostStdPrice <> 0     
    END    
    
    --자산계정/기타출고의처리계정    
    --제품    

    --기타입고     
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(L.AccSeq, 0)  , --대변계정    
           L.UMCostType         , --대변비용구분    
           ISNULL(j.ValueSeq, 0), --차변계정    
           ISNULL(K.ValueSeq, 0), --차변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0),
           ISNULL(A.CustSeq       , 0)
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
          JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq   
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --제조원가 계산대상인 항목 
                                                         AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq 
     AND A.CostKeySeq = @CostKeySeq    
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp <>  6008004 --반제품 
    AND ( E.IsToOtherAcc = '0' OR E.IsToOtherAcc IS NULL)  
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           L.AccSeq             , --대변계정    
           L.UMCostType           , --대변비용구분    
           j.ValueSeq            , --차변계정    
           K.ValueSeq            , --차변비용구분  
           A.CCtrSeq			 ,
		   A.DeptSeq  ,
           A.CustSeq
                 

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark     , AssetSeq  , DrAccSeq,    
           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq        ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(L.AccSeq, 0)  , --대변계정    
           L.UMCostType         , --대변비용구분    
           ISNULL(N.AccSeq, 0), --차변계정    
 ISNULL(N.UMCostType, 0), --차변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0) ,
           ISNULL(A.CustSeq     , 0) 
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq   
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- 타계정에서 대체  
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq= Z.AccSeq          --제조원가 계산대상인 항목 
                                                         AND K.ValueSeq         = Z.UMCostType

   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp <>  6008004 --반제품 
     AND E.IsToOtherAcc = '1'
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           L.AccSeq       , --대변계정    
           L.UMCostType           , --대변비용구분    
           N.AccSeq            , --차변계정    
           N.UMCostType            , --차변비용구분  
           A.CCtrSeq			 ,
		   A.DeptSeq   ,
           A.CustSeq 
		   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(N.AccSeq, 0)  , --대변계정    
           N.UMCostType         , --대변비용구분    
           ISNULL(j.ValueSeq, 0), --차변계정    
           ISNULL(K.ValueSeq, 0), --차변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0)   ,
           ISNULL(A.CustSeq ,0) 
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq   
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'     

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- 타계정에서 대체  
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --제조원가 계산대상인 항목 
                                                         AND K.ValueSeq        = Z.UMCostType

   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp <>  6008004 --반제품 
     AND E.IsToOtherAcc = '1'
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           N.AccSeq       , --대변계정    
           N.UMCostType           , --대변비용구분    
           j.ValueSeq            , --차변계정    
           K.ValueSeq            , --차변비용구분  
           A.CCtrSeq			 ,
		   A.DeptSeq      ,
           A.CustSeq         
 

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(j.ValueSeq, 0) , --대변계정    
           ISNULL(K.ValueSeq, 0) , --대변비용구분    
           ISNULL(L.AccSeq  , 0) , --차변계정    
           L.UMCostType          , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           5                     , --순서    
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0)  ,              
           ISNULL(A.CustSeq , 0)  

      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq           
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'        -- 계정과목      
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'        -- 비용구분    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정 
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --제조원가 계산대상인 항목 
                                                         AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --기타출고
     AND F.MinorSeq <> 6008001 
--     AND A.CostUnit  = @CostUnit
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND (E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL)
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind           , --입출고유형    
           j.ValueSeq          , --대변계정    
           K.ValueSeq          , --대변비용구분    
           L.AccSeq             , --차변계정    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq            ,
           A.CustSeq
    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt       , ShowOrder ,    
           DeptSeq      ,CCtrSeq , CustSeq )    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(N.AccSeq, 0) , --대변계정    
           ISNULL(N.UMCostType, 0) , --대변비용구분    
           ISNULL(L.AccSeq  , 0) , --차변계정    
           L.UMCostType          , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           5                     , --순서    
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0)    ,            
           ISNULL(A.CustSeq , 0)    
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
--               JOIN _TDAUMinorValue  AS M WITH(NOLOCK) ON G.CompanySeq  = M.CompanySeq    
--                                                      AND G.MinorSeq    = M.MinorSeq    
--                                                      AND M.ValueText   <> '1'     
--                                                      AND M.Serl        = '2003'    --부가세신고대상제외?? 필요한지 알아오기    
--              LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                  ON C.DeptSeq    = P.DeptSeq      
--                                                 AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'        -- 계정과목      
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'        -- 비용구분    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정 
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --제조원가 계산대상인 항목 
                                                         AND K.ValueSeq        = Z.UMCostType
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                         AND N.AssetAccKindSeq = 21 -- 타계정으로대체  
   WHERE A.CompanySeq = @CompanySeq 
     AND A.CostKeySeq = @CostKeySeq    
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --기타출고
     AND F.MinorSeq <> 6008001 
--     AND A.CostUnit  = @CostUnit
 AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1'
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind           , --입출고유형    
           N.AccSeq          , --대변계정    
           N.UMCostType          , --대변비용구분    
           L.AccSeq             , --차변계정    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq          ,
           A.CustSeq        
    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(j.ValueSeq, 0) , --대변계정    
           ISNULL(K.ValueSeq, 0) , --대변비용구분    
           ISNULL(N.AccSeq, 0) , --대변계정    
           ISNULL(N.UMCostType, 0) , --대변비용구분     
           SUM(A.Amt )           , --기타출고금액    
           5                     , --순서    
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0) ,               
           ISNULL(A.CustSeq , 0) 
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
--               JOIN _TDAUMinorValue  AS M WITH(NOLOCK) ON G.CompanySeq  = M.CompanySeq    
--                                                      AND G.MinorSeq    = M.MinorSeq    
--                                                      AND M.ValueText   <> '1'     
--                                                      AND M.Serl        = '2003'    --부가세신고대상제외?? 필요한지 알아오기    
--              LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                  ON C.DeptSeq    = P.DeptSeq      
--                                                 AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'        -- 계정과목      
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'        -- 비용구분    
               --LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
               --                                          AND E.AssetSeq         = L.AssetSeq    
               --                                AND L.AssetAccKindSeq  = 1 --자산처리계정 
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --제조원가 계산대상인 항목 
                                                         AND K.ValueSeq        = Z.UMCostType
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                         AND N.AssetAccKindSeq = 21 -- 타계정으로대체  
   WHERE A.CompanySeq = @CompanySeq 
     AND A.CostKeySeq = @CostKeySeq    
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --기타출고
     AND F.MinorSeq <> 6008001 
--     AND A.CostUnit  = @CostUnit
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1'
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind           , --입출고유형    
           j.ValueSeq          , --대변계정    
           K.ValueSeq          , --대변비용구분    
           N.AccSeq          , --대변계정    
           N.UMCostType          , --대변비용구분   
           A.DeptSeq            ,    
           A.CCtrSeq        ,
           A.CustSeq

    IF @BanToProc = 1  --반제품 재공으로 처리
    BEGIN

    --기타입고  ( 타계정에서 대체 /  잡이익 ) 
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq ,CustSeq )    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(N.AccSeq, 0)  , --차변계정    
           ISNULL(N.UMCostType,0), --차변비용구분    
           ISNULL(j.ValueSeq, 0), --대변계정    
           ISNULL(K.ValueSeq, 0), --대변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0) ,   
           ISNULL(A.CustSeq     , 0) 
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- 타계정에서 대체  
		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --제조원가 계산대상인 항목 
                                                         AND K.ValueSeq        = Z.UMCostType

  
--재공품-재공에서 타계정으로대체
--타계정에서 계정 : 17
--타계정으로 계정 : 21  

   WHERE A.CompanySeq = @CompanySeq    
     AND A.CostKeySeq = @CostKeySeq 
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp  = 6008004 --반제품 
  
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           N.AccSeq       , --대변계정    
           N.UMCostType           , --대변비용구분    
           j.ValueSeq            , --차변계정    
           K.ValueSeq            , --차변비용구분  
           A.CCtrSeq			 ,
		   A.DeptSeq        ,
           A.CustSeq        


    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(L.AccSeq, 0)  , --대변계정    
           L.UMCostType         , --대변비용구분    
           ISNULL(N.AccSeq, 0)  , --차변계정    
           ISNULL(N.UMCostType, 0), --차변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0) ,
           ISNULL(A.CustSeq     , 0)    
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
       AND K.Serl             = '1002'    

               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정    

               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- 타계정으로대체  
		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq  = Z.AccSeq          --제조원가 계산대상인 항목 
                                    AND K.ValueSeq         = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp = 6008004 --반제품 
  
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           L.AccSeq       , --대변계정    
           L.UMCostType           , --대변비용구분    
           N.AccSeq           , --차변계정    
           N.UMCostType            , --차변비용구분  
           A.CCtrSeq			 ,
		   A.DeptSeq        ,
           A.CustSeq     

 
END
   ELSE --반제품을 재공으로 처리하지 않을때 
   BEGIN 

    --기타입고    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq , CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(L.AccSeq, 0)  , --대변계정    
           L.UMCostType         , --대변비용구분    
           ISNULL(j.ValueSeq, 0), --차변계정    
           ISNULL(K.ValueSeq, 0), --차변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0) ,   
           ISNULL(A.CustSeq     , 0) 
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq      
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                               AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --제조원가 계산대상인 항목 
                                                         AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.SMAssetGrp = 6008004 --반제품 
    AND ( E.IsToOtherAcc = '0' OR E.IsToOtherAcc IS NULL)  
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           L.AccSeq       , --대변계정    
           L.UMCostType           , --대변비용구분    
           j.ValueSeq            , --차변계정    
           K.ValueSeq            , --차변비용구분  
           A.CCtrSeq			 ,
		   A.DeptSeq  ,
           A.CustSeq          

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(L.AccSeq, 0)  , --대변계정    
           L.UMCostType         , --대변비용구분    
           ISNULL(N.AccSeq, 0), --차변계정    
           ISNULL(N.UMCostType, 0), --차변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0)    ,
           ISNULL(A.CustSeq     , 0)    
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq      
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                      AND N.AssetAccKindSeq = 17 -- 타계정에서 대체  
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq  = Z.AccSeq          --제조원가 계산대상인 항목 
                                                         AND K.Valueseq   = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.SMAssetGrp = 6008004 --반제품 
     AND E.IsToOtherAcc = '1'
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           L.AccSeq       , --대변계정    
           L.UMCostType           , --대변비용구분    
           N.AccSeq            , --차변계정    
           N.UMCostType            , --차변비용구분  
           A.CCtrSeq			 ,
		   A.DeptSeq    ,
           A.CustSeq
		   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(N.AccSeq, 0)  , --대변계정    
           N.UMCostType         , --대변비용구분    
           ISNULL(j.ValueSeq, 0), --차변계정    
           ISNULL(K.ValueSeq, 0), --차변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0) ,
           ISNULL(A.CustSeq     ,0)
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq      
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                        AND M.MajorSeq = 8025			-- 기타입고
												        AND M.Serl     = 2009	        -- 품목별전표처리여부
													    AND A.InOutDetailKind = M.minorseq 
													    AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                        AND N.AssetAccKindSeq = 17 -- 타계정에서 대체 
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq  = Z.AccSeq          --제조원가 계산대상인 항목 
                                                         AND K.Valueseq   = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.SMAssetGrp = 6008004 --반제품 
     AND E.IsToOtherAcc = '1'
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           N.AccSeq       , --대변계정    
           N.UMCostType           , --대변비용구분    
           j.ValueSeq            , --차변계정    
           K.ValueSeq            , --차변비용구분  
           A.CCtrSeq			 ,
		   A.DeptSeq ,
           A.CustSeq   
		   
END
         
    GOTO Proc_Query

 

RETURN 
/**************************************************************************************************************/
PROC_AfterProd: --원가계산 후

   

    ---제품의 기타입고, 기타출고 

    --기타입고     
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq )    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(L.AccSeq, 0)  , --대변계정    
           L.UMCostType         , --대변비용구분    
           ISNULL(j.ValueSeq, 0), --차변계정    
           ISNULL(K.ValueSeq, 0), --차변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0)   , 
           ISNULL(A.CustSeq     , 0)   
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq   
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
                LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --제조원가 계산대상인 항목 
                                                         AND K.ValueSeq        = Z.UMCostType

   WHERE A.CompanySeq = @CompanySeq 
     AND A.CostKeySeq = @CostKeySeq    
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp <>  6008004 --반제품 
    AND ( E.IsToOtherAcc = '0' OR E.IsToOtherAcc IS NULL) 
    AND Z.AccSeq IS NULL 
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           L.AccSeq       , --대변계정    
           L.UMCostType           , --대변비용구분    
           j.ValueSeq            , --차변계정    
           K.ValueSeq            , --차변비용구분  
           A.CCtrSeq			 ,
		   A.DeptSeq  ,
           A.CustSeq       

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(L.AccSeq, 0)  , --대변계정    
           L.UMCostType         , --대변비용구분    
           ISNULL(N.AccSeq, 0), --차변계정    
           ISNULL(N.UMCostType, 0), --차변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0)    ,
           ISNULL(A.CustSeq     ,0) 
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq   
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- 타계정에서 대체  
                LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq  = Z.AccSeq          --제조원가 계산대상인 항목 
                                                         AND K.ValueSeq         = Z.UMCostType


   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp <>  6008004 --반제품 
     AND E.IsToOtherAcc = '1'
    AND Z.AccSeq IS NULL 
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           L.AccSeq       , --대변계정    
           L.UMCostType           , --대변비용구분    
           N.AccSeq            , --차변계정    
           N.UMCostType            , --차변비용구분  
           A.CCtrSeq			 ,
		   A.DeptSeq   ,
           A.CustSeq    
		   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(N.AccSeq, 0)  , --대변계정    
           N.UMCostType         , --대변비용구분    
           ISNULL(j.ValueSeq, 0), --차변계정    
           ISNULL(K.ValueSeq, 0), --차변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0)    ,
           ISNULL(A.CustSeq     , 0)    
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq   
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'     

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- 타계정에서 대체  
                LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --제조원가 계산대상인 항목 
                                                         AND K.ValueSeq        = Z.UMCostType


   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp <>  6008004 --반제품 
     AND E.IsToOtherAcc = '1'
     AND Z.AccSeq IS NULL 
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           N.AccSeq       , --대변계정    
           N.UMCostType           , --대변비용구분    
           j.ValueSeq            , --차변계정    
           K.ValueSeq            , --차변비용구분  
           A.CCtrSeq			 ,
		   A.DeptSeq    ,
           A.CustSeq          
    --기타출고(제조계정 제외)
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq )    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(j.ValueSeq, 0) , --대변계정    
           ISNULL(K.ValueSeq , 0), --대변비용구분    
           ISNULL(L.AccSeq, 0)   , --차변계정    
           L.UMCostType          , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           5                     , --순서
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0) ,               
           ISNULL(A.CustSeq , 0) 
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정 
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType

		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
   WHERE A.CompanySeq = @CompanySeq    
     AND A.CostKeySeq = @CostKeySeq 
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --기타출고
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
     AND E.SMAssetGrp <>  6008004 --반제품  
     AND ( E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL )
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind           , --입출고유형    
           j.ValueSeq          , --대변계정    
           K.ValueSeq          , --대변비용구분    
           L.AccSeq             , --차변계정    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq            ,
           A.CustSeq          
          
    INSERT INTO #TempInOut(    
           SMSlipKind  ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(N.AccSeq, 0) , --대변계정    
           ISNULL(N.UMCostType , 0), --대변비용구분    
           ISNULL(L.AccSeq, 0)   , --차변계정    
           L.UMCostType          , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           5                     , --순서
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0) ,
           ISNULL(A.CustSeq , 0)       
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                            AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정 
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType

		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- 타계정으로대체  

   WHERE A.CompanySeq = @CompanySeq  
     AND A.CostKeySeq = @CostKeySeq   
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --기타출고
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
     AND E.SMAssetGrp <>  6008004 --반제품  
     AND E.IsFromOtherAcc = '1'
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind           , --입출고유형    
           N.AccSeq          , --대변계정    
           N.UMCostType          , --대변비용구분    
           L.AccSeq             , --차변계정    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq            ,
           A.CustSeq        
           
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(j.ValueSeq, 0) , --대변계정    
           ISNULL(K.ValueSeq , 0), --대변비용구분    
           ISNULL(N.AccSeq, 0)   , --차변계정    
           N.UMCostType          , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           5                     , --순서
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0) ,               
           ISNULL(A.CustSeq , 0) 
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
           JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType

		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- 타계정으로대체  
   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --기타출고
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit  = @CostUnit    ))
     AND Z.AccSeq IS NULL
     AND E.SMAssetGrp <>  6008004 --반제품  
     AND E.IsFromOtherAcc = '1'
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind           , --입출고유형    
           j.ValueSeq          , --대변계정    
           K.ValueSeq          , --대변비용구분    
           N.AccSeq             , --차변계정    
           N.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq            ,
           A.CustSeq             
    /*****************************************************/    
    --적송보정금액처리    
    --적송건이 있거나 당월 출고가 기타출고(원가계산전)만 발생한경우의 보정처리이다.                       
    /*****************************************************/    
    
--    --적송조정계정    
--    EXEC dbo._SCOMEnv @CompanySeq, 5506,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    
--    --적송조정 계정의 비용구분    
--    EXEC dbo._SCOMEnv @CompanySeq, 5540,@UserSeq,@@PROCID,@cTRANsAdjUMcostTypeSeq OUTPUT    
--    
     --단수조정계정    
    EXEC dbo._SCOMEnv @CompanySeq, 5507,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    


    -- 기타춝고의 원가계산 후    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
        SELECT @SMSlipKind,    
               A.SMAdjustKind , --기타출고유형    
               A.InOutKind , --입출고유형    
               E.AssetSeq             , --재고자산분류    
               --@cTRANsAdjAccSeq       , --대변계정(적송조정계정)    
               --0, --대변비용구분(적송조정계정 비용구분)    
               CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --대변계정  
               CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --대변비용구분    
               ISNULL(L.AccSeq, 0)    , --차변계정    
               L.UMCostType          , --차변비용구분    
               SUM(A.Amt )           , --기타출고금액    
               1                     , --순서    
               A.DeptSeq             ,    
               0        ,
               0  
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                   JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                          AND A.ItemSeq    = D.ItemSeq    
                   JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                          AND D.AssetSeq    = E.AssetSeq      
                   LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                         AND E.AssetSeq     = L.AssetSeq    
                                                         AND L.AssetAccKindSeq = 1 --자산처리계정    
                   LEFT OUTER JOIN _TDAItemAssetAcc AS O WITH(NOLOCK) ON D.AssetSeq  = O.AssetSeq  
                                                         AND D.Companyseq = O.CompanySeq      
                                                         AND O.AssetAccKindSeq = 21-- 타계정으로대체   
        WHERE A.CompanySeq = @CompanySeq 
          AND A.CostKeySeq = @CostKeySeq
          AND A.SMAdjustKind = 5513001 -- 제품단가보정    
          AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
               OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
          AND A.CostKeySeq   = @CostKeySeq    
          AND A.InOutKind    = 8023003  --기타출고   
          AND E.SMAssetGrp <>  6008004 --반제품  
        GROUP BY E.AssetSeq ,A.InOutKind , A.DeptSeq , 
                 A.SMAdjustKind,
                 CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --대변계정  
                 CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --대변비용구분    
                 L.AccSeq,L.UMCostType

 
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
        SELECT @SMSlipKind,    
               A.SMAdjustKind , --기타출고유형    
               A.InOutKind , --입출고유형    
               E.AssetSeq             , --재고자산분류    
               @cTRANsAdjAccSeq       , --대변계정(적송조정계정)    
               0, --대변비용구분(적송조정계정 비용구분)     
               ISNULL(L.AccSeq, 0)    , --차변계정    
               L.UMCostType          , --차변비용구분    
               SUM(A.Amt )           , --기타출고금액    
               1                     , --순서    
               A.DeptSeq             ,    
               0        ,0 
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                   JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                          AND A.ItemSeq    = D.ItemSeq    
                   JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                          AND D.AssetSeq    = E.AssetSeq      
                   LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                         AND E.AssetSeq     = L.AssetSeq    
                                                         AND L.AssetAccKindSeq = 21 --타계정으로대체
        WHERE A.CompanySeq = @CompanySeq 
          AND A.CostKeySeq = @CostKeySeq
          AND A.SMAdjustKind = 5513001 -- 제품단가보정    
          AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
               OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
          AND A.CostKeySeq   = @CostKeySeq    
          AND A.InOutKind    = 8023003  --기타출고   
          AND E.SMAssetGrp <>  6008004 --반제품  
          AND E.IsFromOtherAcc = '1' 
        GROUP BY E.AssetSeq ,A.InOutKind , A.DeptSeq , 
                 A.SMAdjustKind,  
                 L.AccSeq,L.UMCostType
 

    IF @BanToProc = 1  --반제품 재공으로 처리
    BEGIN

    --기타입고  ( 타계정에서 대체 /  잡이익 ) 
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(N.AccSeq, 0)  , --차변계정    
           ISNULL(N.UMCostType,0), --차변비용구분    
           ISNULL(j.ValueSeq, 0), --대변계정    
           ISNULL(K.ValueSeq, 0), --대변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0)   ,
           ISNULL(A.CustSeq    ,0)  
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                 AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- 타계정에서 대체  
		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --제조원가 계산대상인 항목 
                                                                    AND K.ValueSeq        = Z.UMCostType

  
--재공품-재공에서 타계정으로대체
--타계정에서 계정 : 17
--타계정으로 계정 : 21  

   WHERE A.CompanySeq = @CompanySeq    
     AND A.CostKeySeq = @CostKeySeq 
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp  = 6008004 --반제품 
     AND Z.AccSeq  IS NULL
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           N.AccSeq       , --대변계정    
           N.UMCostType           , --대변비용구분    
           j.ValueSeq            , --차변계정    
           K.ValueSeq            , --차변비용구분  
           A.CCtrSeq			 ,
		   A.DeptSeq   ,
           A.CustSeq     

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(L.AccSeq, 0)  , --대변계정    
           L.UMCostType         , --대변비용구분    
           ISNULL(N.AccSeq, 0)  , --차변계정    
           ISNULL(N.UMCostType, 0), --차변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0)    ,
           ISNULL(A.CustSeq     ,0)
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'   
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정    

               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- 타계정으로대체  
		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --제조원가 계산대상인 항목 
         AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp = 6008004 --반제품 
     AND Z.AccSeq IS NULL
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           L.AccSeq       , --대변계정    
           L.UMCostType           , --대변비용구분    
           N.AccSeq           , --차변계정    
           N.UMCostType            , --차변비용구분  
           A.CCtrSeq			 ,
		   A.DeptSeq         ,
           A.CustSeq

 
    --기타출고(제조계정 제외)  타계정으로대체/ 재공품
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(N.AccSeq, 0) , --대변계정    
           ISNULL(N.UMCostType , 0), --대변비용구분    
           ISNULL(L.AccSeq, 0)   , --차변계정    
           ISNULL(L.UMCostType, 0) , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           5                     , --순서
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0) ,          
           ISNULL(A.CustSeq , 0)
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
 JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- 타계정으로대체  
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '2004'    
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq         = Z.AccSeq     
            AND K.ValueSeq        = Z.UMCostType

		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --기타출고
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
     AND E.SMAssetGrp = 6008004 --반제품 
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind           , --입출고유형    
           N.AccSeq          , --대변계정    
           N.UMCostType          , --대변비용구분    
           L.AccSeq             , --차변계정    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq  ,
           A.CustSeq    

    --기타출고(제조계정 제외) 판관비/타계정으로대체 
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(j.ValueSeq, 0) , --대변계정    
           ISNULL(K.ValueSeq , 0), --대변비용구분    
           ISNULL(N.AccSeq, 0)   , --차변계정    
           N.UMCostType          , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           5                     , --순서
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0) ,
           ISNULL(A.CustSeq , 0)              
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- 타계정으로대체  
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType

		        LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --기타출고
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
     AND E.SMAssetGrp = 6008004 --반제품 
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind           , --입출고유형    
           j.ValueSeq          , --대변계정    
           K.ValueSeq          , --대변비용구분    
           N.AccSeq             , --차변계정    
           N.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq   ,
           A.CustSeq

        
    /*****************************************************/    
    --적송보정금액처리    
    --적송건이 있거나 당월 출고가 기타출고(원가계산전)만 발생한경우의 보정처리이다.                       
    /*****************************************************/    
    
    --적송조정계정    
    EXEC dbo._SCOMEnv @CompanySeq, 5507,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    
    --적송조정 계정의 비용구분    
--    EXEC dbo._SCOMEnv @CompanySeq, 5540,@UserSeq,@@PROCID,@cTRANsAdjUMcostTypeSeq OUTPUT    
    
    
    -- 기타춝고의 원가계산 후  (  타계정으로 대체    /재공품  
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
        SELECT @SMSlipKind,    
               A.SMAdjustKind , --기타출고유형    
               A.InOutKind , --입출고유형    
               E.AssetSeq             , --재고자산분류    
               ISNULL(N.AccSeq, 0)    , --차변계정    
               ISNULL(N.UMCostType,0)          , --차변비용구분    
               ISNULL(L.AccSeq, 0)    , --차변계정    
               ISNULL(L.UMCostType,0)          , --차변비용구분    
               SUM(A.Amt )           , --기타출고금액    
               1                     , --순서    
               A.DeptSeq             ,    
               0        ,0
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                   JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                          AND A.ItemSeq    = D.ItemSeq    
                   JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                          AND D.AssetSeq    = E.AssetSeq      
                   LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                         AND E.AssetSeq     = L.AssetSeq    
                                                         AND L.AssetAccKindSeq = 1 --자산처리계정    
                   LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- 타계정으로대체  
        WHERE A.CompanySeq = @CompanySeq 
          AND A.CostKeySeq = @CostKeySeq
          AND A.SMAdjustKind = 5513001 -- 제품단가보정   
          AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
               OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
          AND A.InOutKind    = 8023003  --기타출고    
          AND E.SMAssetGrp = 6008004 --반제품 
        GROUP BY E.AssetSeq ,A.InOutKind , A.DeptSeq , 
                 A.SMAdjustKind, L.AccSeq,L.UMCostType , N.AccSeq,N.UMCostType     
    
  

    -- 기타춝고의 원가계산 후  ( 조정계정 / 타계정으로 대체)   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
        SELECT @SMSlipKind,    
               A.SMAdjustKind , --기타출고유형    
               A.InOutKind , --입출고유형    
               E.AssetSeq             , --재고자산분류    
               @cTRANsAdjAccSeq       , --대변계정(적송조정계정)    
               0, --대변비용구분(적송조정계정 비용구분)    
               ISNULL(N.AccSeq, 0)    , --차변계정    
               ISNULL(N.UMCostType,0)          , --차변비용구분    
               SUM(A.Amt )           , --기타출고금액    
               1                     , --순서    
               A.DeptSeq             ,    
               0        ,0
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                   JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                          AND A.ItemSeq    = D.ItemSeq    
                   JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                          AND D.AssetSeq    = E.AssetSeq      
                   LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- 타계정으로대체  
        WHERE A.CompanySeq = @CompanySeq 
          AND A.CostKeySeq = @CostKeySeq
          AND A.SMAdjustKind = 5513001 -- 제품단가보정   
    AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit      = @CostUnit    )
               OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
          AND A.InOutKind    = 8023003  --기타출고    
          AND E.SMAssetGrp   = 6008004  --반제품 
        GROUP BY E.AssetSeq ,A.InOutKind , A.DeptSeq , 
                 A.SMAdjustKind, N.AccSeq,N.UMCostType   

 

   END 
   ELSE --반제품을 재공으로 처리하지 않을때 
   BEGIN 

    --기타입고    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(L.AccSeq, 0)  , --대변계정    
           L.UMCostType         , --대변비용구분    
           ISNULL(j.ValueSeq, 0), --차변계정    
           ISNULL(K.ValueSeq, 0), --차변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0)  ,  
           ISNULL(A.CustSeq     , 0)  
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq      
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --제조원가 계산대상인 항목 
                                                         AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.SMAssetGrp = 6008004 --반제품 
    AND ( E.IsToOtherAcc = '0' OR E.IsToOtherAcc IS NULL)  
    AND Z.AccSeq IS NULL
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           L.AccSeq       , --대변계정    
           L.UMCostType           , --대변비용구분    
           j.ValueSeq            , --차변계정    
           K.ValueSeq            , --차변비용구분  
           A.CCtrSeq			 ,
		   A.DeptSeq    ,
           A.CustSeq    

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(L.AccSeq, 0)  , --대변계정    
           L.UMCostType         , --대변비용구분    
           ISNULL(N.AccSeq, 0), --차변계정    
           ISNULL(N.UMCostType, 0), --차변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0) ,  
           ISNULL(A.CustSeq     , 0)     
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq      
                                                         AND A.InOutDetailKind  = I.MinorSeq    
           AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'   
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                      AND N.AssetAccKindSeq = 17 -- 타계정에서 대체  
               LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --제조원가 계산대상인 항목 
                                                         AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.SMAssetGrp = 6008004 --반제품 
     AND E.IsToOtherAcc = '1'
     AND Z.AccSeq IS NULL
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           L.AccSeq       , --대변계정    
           L.UMCostType           , --대변비용구분    
           N.AccSeq            , --차변계정    
           N.UMCostType            , --차변비용구분  
           A.CCtrSeq			 ,
		   A.DeptSeq   ,
           A.CustSeq 
		   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(N.AccSeq, 0)  , --대변계정    
           N.UMCostType         , --대변비용구분    
           ISNULL(j.ValueSeq, 0), --차변계정    
           ISNULL(K.ValueSeq, 0), --차변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0),  
           ISNULL(A.CustSeq     , 0)   
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq   
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq      
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                        AND M.MajorSeq = 8025			-- 기타입고
												        AND M.Serl     = 2009	        -- 품목별전표처리여부
													    AND A.InOutDetailKind = M.minorseq 
													    AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                          AND N.AssetAccKindSeq = 17 -- 타계정에서 대체 
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.SMAssetGrp = 6008004 --반제품 
     AND E.IsToOtherAcc = '1'
     AND Z.AccSeq IS NULL
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           N.AccSeq       , --대변계정    
           N.UMCostType           , --대변비용구분    
           j.ValueSeq            , --차변계정    
           K.ValueSeq            , --차변비용구분  
           A.CCtrSeq			 ,
		   A.DeptSeq            ,
           A.CustSeq  
		   
    --기타출고(제조계정 제외)
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(j.ValueSeq, 0) , --대변계정    
           ISNULL(K.ValueSeq , 0), --대변비용구분    
           ISNULL(L.AccSeq, 0)   , --차변계정    
           L.UMCostType          , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           5                     , --순서
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0)    ,  
           ISNULL(A.CustSeq     , 0)              
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정 
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType

		        LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --기타출고
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
      AND E.SMAssetGrp = 6008004 --반제품 
      AND ( E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL )
  GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind           , --입출고유형    
           j.ValueSeq          , --대변계정    
           K.ValueSeq          , --대변비용구분    
           L.AccSeq             , --차변계정    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq    ,
           A.CustSeq 
           
           
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(N.AccSeq, 0) , --대변계정    
           ISNULL(N.UMCostType , 0), --대변비용구분    
           ISNULL(L.AccSeq, 0)   , --차변계정    
           L.UMCostType          , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           5                     , --순서
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0)   ,  
           ISNULL(A.CustSeq     , 0)               
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'  
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType

		        LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                      AND N.AssetAccKindSeq = 21 -- 타계정으로대체  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --기타출고
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
      AND E.SMAssetGrp = 6008004 --반제품 
     AND E.IsFromOtherAcc = '1'
  GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind           , --입출고유형    
           N.AccSeq          , --대변계정    
           N.UMCostType          , --대변비용구분    
           L.AccSeq             , --차변계정    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq   ,
           A.CustSeq
           
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(j.ValueSeq, 0) , --대변계정    
           ISNULL(K.ValueSeq , 0), --대변비용구분    
           ISNULL(N.AccSeq, 0)   , --차변계정    
           N.UMCostType          , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           5                     , --순서
           A.DeptSeq             ,    
   ISNULL(A.CCtrSeq , 0) ,  
           ISNULL(A.CustSeq     , 0)                 
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType

		        LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                      AND N.AssetAccKindSeq = 21 -- 타계정으로대체  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --기타출고
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
      AND E.SMAssetGrp = 6008004 --반제품 
     AND E.IsFromOtherAcc = '1'
  GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind           , --입출고유형    
           j.ValueSeq          , --대변계정    
           K.ValueSeq          , --대변비용구분    
           N.AccSeq             , --차변계정    
           N.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq            ,
           A.CustSeq          
    /*****************************************************/    
    --적송보정금액처리    
    --적송건이 있거나 당월 출고가 기타출고(원가계산전)만 발생한경우의 보정처리이다.                       
    /*****************************************************/    
    
    --적송조정계정    
    EXEC dbo._SCOMEnv @CompanySeq, 5507,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    
    --적송조정 계정의 비용구분    
--    EXEC dbo._SCOMEnv @CompanySeq, 5540,@UserSeq,@@PROCID,@cTRANsAdjUMcostTypeSeq OUTPUT    
    
    
    -- 기타춝고의 원가계산 후    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
          DeptSeq      ,CCtrSeq    ,CustSeq)    
        SELECT @SMSlipKind,    
               A.SMAdjustKind , --기타출고유형    
               A.InOutKind , --입출고유형    
               E.AssetSeq             , --재고자산분류    
               --@cTRANsAdjAccSeq       , --대변계정(적송조정계정)    
               --0, --대변비용구분(적송조정계정 비용구분)  
               CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --대변계정  
               CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --대변비용구분      
               ISNULL(L.AccSeq, 0)    , --차변계정    
               L.UMCostType          , --차변비용구분    
               SUM(A.Amt )           , --기타출고금액    
               1                     , --순서    
               A.DeptSeq             ,    
               0     ,0   
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                   JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                          AND A.ItemSeq    = D.ItemSeq    
                   JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                          AND D.AssetSeq    = E.AssetSeq      
                   LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                         AND E.AssetSeq     = L.AssetSeq    
                                                         AND L.AssetAccKindSeq = 1 --자산처리계정   
                   LEFT OUTER JOIN _TDAItemAssetAcc AS O WITH(NOLOCK) ON D.AssetSeq  = O.AssetSeq  
                                                         AND D.Companyseq = O.CompanySeq      
                                                         AND O.AssetAccKindSeq = 21-- 타계정으로대체    
        WHERE A.CompanySeq = @CompanySeq 
          AND A.CostKeySeq = @CostKeySeq
          AND A.SMAdjustKind = 5513001 -- 제품단가보정   
          AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
               OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
          AND A.CostKeySeq   = @CostKeySeq    
          AND A.InOutKind    = 8023003  --기타출고    
          AND E.SMAssetGrp = 6008004 --반제품 
   GROUP BY E.AssetSeq ,A.InOutKind , A.DeptSeq , 
                 A.SMAdjustKind,
                 CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --대변계정  
                 CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --대변비용구분    
                 L.AccSeq,L.UMCostType
                 
                 
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
        SELECT @SMSlipKind,    
               A.SMAdjustKind , --기타출고유형    
               A.InOutKind , --입출고유형    
               E.AssetSeq             , --재고자산분류    
               @cTRANsAdjAccSeq       , --대변계정(적송조정계정)    
               0, --대변비용구분(적송조정계정 비용구분)    
               ISNULL(L.AccSeq, 0)    , --차변계정    
               L.UMCostType          , --차변비용구분    
               SUM(A.Amt )           , --기타출고금액    
               1                     , --순서    
               A.DeptSeq             ,    
               0                     ,0 
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                   JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                          AND A.ItemSeq    = D.ItemSeq    
                   JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                          AND D.AssetSeq    = E.AssetSeq      
                   LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                         AND E.AssetSeq     = L.AssetSeq    
                                                         AND L.AssetAccKindSeq = 21-- 타계정으로대체  
        WHERE A.CompanySeq = @CompanySeq 
          AND A.CostKeySeq = @CostKeySeq
          AND A.SMAdjustKind = 5513001 -- 제품단가보정   
          AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
               OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
          AND A.CostKeySeq   = @CostKeySeq    
          AND A.InOutKind    = 8023003  --기타출고    
          AND E.SMAssetGrp = 6008004 --반제품 
          AND E.IsFromOtherAcc = '1' 
   GROUP BY E.AssetSeq ,A.InOutKind , A.DeptSeq , 
                 A.SMAdjustKind, L.AccSeq,L.UMCostType  


   END 



    /******************************************************************/    
    --대체출고 :우선 제외(기타입출고를 써라)    
    /******************************************************************/    
     

    GOTO Proc_Query
   
RETURN 

/*****************************************************************************************/
PROC_GoodS: --상품
    
    --기타입고    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(L.AccSeq, 0)   , --차변계정    
           L.UMCostType          , --차변비용구분    
           ISNULL(j.ValueSeq, 0) , --대변계정    
           ISNULL(K.ValueSeq, 0) , --대변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           1                     , --순서    
           A.DeptSeq            ,    
         ISNULL(A.CCtrSeq , 0)  ,  
           ISNULL(A.CustSeq     , 0)                      
      FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
--               LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                  ON C.DeptSeq    = P.DeptSeq      
--                                                 AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --지우리    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '1002'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                   AND L.AssetAccKindSeq = 1 --자산처리계정    
                  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001상품/    
     AND A.InOutKind IN (8023004)  --기타입고/기타출고    
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
    AND ( E.IsToOtherAcc = '0' OR E.IsToOtherAcc IS NULL) --타계정에서 대체가 아닌경우
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --이미 등록된 내용 제외    
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           j.ValueSeq          , --대변계정    
           K.ValueSeq          , --대변비용구분    
           L.AccSeq             , --차변계정    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq       ,  
           A.InOutKind   ,
           A.CustSeq
        
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq   ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq) 
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(L.AccSeq, 0)   , --대변계정    
           L.UMCostType          , --대변비용구분
           ISNULL(N.AccSeq, 0) , --차변계정    
           ISNULL(N.UMCostType, 0) , --차변비용구분        
           SUM(A.Amt )           , --기타출고금액    
           1                     , --순서    
           A.DeptSeq            ,    
         ISNULL(A.CCtrSeq , 0) ,  
           ISNULL(A.CustSeq     , 0)                       
      FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
--               LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                  ON C.DeptSeq    = P.DeptSeq      
--                                                 AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --지우리    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28  
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --자산처리계정   
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- 타계정에서 대체  
                  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001상품/    
     AND A.InOutKind IN (8023004)  --기타입고/기타출고   
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsToOtherAcc = '1' --타계정에서 대체인 경우
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --이미 등록된 내용 제외    
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형  
           L.AccSeq             , --대변계정    
           L.UMCostType         ,       
           N.AccSeq             , --차변계정    
           N.UMCostType         , --차변비용구분   
           A.DeptSeq            ,    
           A.CCtrSeq       ,  
           A.InOutKind     ,
           A.CustSeq 
           
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq    ) 
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(N.AccSeq, 0) , --대변계정    
           ISNULL(N.UMCostType, 0) , --대변비용구분    
           ISNULL(J.ValueSeq, 0)   , --차변계정    
           K.ValueSeq          , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
      1                     , --순서    
           A.DeptSeq            ,    
         ISNULL(A.CCtrSeq , 0)    ,  
           ISNULL(A.CustSeq     , 0)                    
      FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '1002'    
--               LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                  ON C.DeptSeq    = P.DeptSeq      
--                                                 AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --지우리    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28  
               --LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
               --                                      AND E.AssetSeq     = L.AssetSeq    
               --                                      AND L.AssetAccKindSeq = 1 --자산처리계정   
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- 타계정에서 대체  
                  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001상품/    
     AND A.InOutKind IN (8023004)  --기타입고/기타출고    
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsToOtherAcc = '1' --타계정에서 대체인 경우
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --이미 등록된 내용 제외    
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           N.AccSeq             , --대변계정    
           N.UMCostType         , --대변비용구분    
           J.ValueSeq             , --차변계정    
           K.ValueSeq         ,    
           A.DeptSeq            ,    
           A.CCtrSeq       ,  
           A.InOutKind      ,
           A.CustSeq
           
           
    --기타출고   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(j.ValueSeq, 0) , --차변계정    
           ISNULL(K.ValueSeq, 0) , --차변비용구분    
           ISNULL(L.AccSeq, 0)   , --대변계정    
           L.UMCostType          , --대변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           1                     , --순서    
           A.DeptSeq            ,    
         ISNULL(A.CCtrSeq , 0),  
           ISNULL(A.CustSeq     , 0)                        
      FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
--              LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                  ON C.DeptSeq    = P.DeptSeq      
--                                                 AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --지우리    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --자산처리계정    
                  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001상품/    
     AND A.InOutKind IN (8023003)  --기타입고/기타출고    
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND ( E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL )--타계정으로 대체가 아닌 경우
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --이미 등록된 내용 제외    
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           j.ValueSeq          , --차변계정    
           K.ValueSeq          , --차변비용구분    
           L.AccSeq             , --대변계정    
           L.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq       ,  
           A.InOutKind    ,
           A.CustSeq
           
           
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(N.AccSeq, 0) , --차변계정    
           ISNULL(N.UMCostType, 0) , --차변비용구분    
           ISNULL(L.AccSeq, 0)   , --대변계정    
L.UMCostType          , --대변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           1                     , --순서    
           A.DeptSeq            ,    
         ISNULL(A.CCtrSeq , 0)  ,  
           ISNULL(A.CustSeq     , 0)                      
      FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq     
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --지우리    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --자산처리계정    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- 타계정으로대체  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001상품/    
     AND A.InOutKind IN (8023003)  --기타입고/기타출고    
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1' --타계정으로 대체가 아닌 경우
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --이미 등록된 내용 제외    
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           N.AccSeq          , --차변계정    
           N.UMCostType          , --차변비용구분    
           L.AccSeq             , --대변계정    
           L.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq       ,  
           A.InOutKind    ,
           A.CustSeq

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(J.ValueSeq, 0)   , --차변계정    
   K.ValueSeq          , --차변비용구분    
           ISNULL(N.AccSeq, 0) , --대변계정    
           ISNULL(N.UMCostType, 0) , --대변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           1                     , --순서    
           A.DeptSeq            ,    
         ISNULL(A.CCtrSeq , 0)   ,  
           ISNULL(A.CustSeq     , 0)                     
      FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                               AND E.SMAssetGrp    = F.MinorSeq     
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --지우리    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '2004'    
               --LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
               --                                      AND E.AssetSeq     = L.AssetSeq    
               --                                      AND L.AssetAccKindSeq = 1 --자산처리계정    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- 타계정으로대체  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001상품/    
     AND A.InOutKind IN (8023003)  --기타입고/기타출고    
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1' --타계정으로 대체가 아닌 경우
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --이미 등록된 내용 제외    
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           J.ValueSeq             , --차변계정    
           K.ValueSeq         ,    
           N.AccSeq          , --대변계정    
           N.UMCostType          , --대변비용구분    
           A.DeptSeq              ,    
           A.CCtrSeq       ,  
           A.InOutKind    ,
           A.CustSeq

--    /*****************************************************/    
--    --단수보정금액처리    
--    --적송건이 있거나 당월 출고가 기타출고(원가계산전)만 발생한경우의 보정처리이다.                       
--    /*****************************************************/    
--    
    --단수조정계정    
    EXEC dbo._SCOMEnv @CompanySeq, 5507,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    
--    --적송조정 계정의 비용구분    
--    EXEC dbo._SCOMEnv @CompanySeq, 5540,@UserSeq,@@PROCID,@cTRANsAdjUMcostTypeSeq OUTPUT    
--    select * from _TDASMinor where minorname like '%보정%'
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt     , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT  @SMSlipKind,    
           0      , --기타출고유형    
           5513003           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           --ISNULL(@cTRANsAdjAccSeq, 0) , --대변계정    
           --ISNULL(0, 0) , --대변비용구분    
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --대변계정  
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --대변비용구분   
           ISNULL(N.AccSeq, 0)   , --차변계정    
           N.UMCostType  , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           1                     , --순서    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0)   ,  
           ISNULL(A.CustSeq     , 0)         
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq     
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                     AND N.AssetAccKindSeq = 1 -- 자산처리계정   
               LEFT OUTER JOIN _TDAItemAssetAcc AS O WITH(NOLOCK) ON D.AssetSeq  = O.AssetSeq  
                                                     AND D.Companyseq = O.CompanySeq      
                                                     AND O.AssetAccKindSeq = 21-- 타계정으로대체   
 
                   
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001상품/  
     --AND F.MinorValue  = '1'    --자재    
     --AND F.MinorSeq    <> 6008005   --재공품이 아닌것 
     AND A.InOutKind IN (8023003)  --기타입고/기타출고    
     AND A.SMAdjustKind = 5513003 
--     AND A.CostUnit = @CostUnit    
     AND  (   ( @GoodPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @GoodPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )  
--     AND E.IsFromOtherAcc = '1'
     -- 재고관리 안하는것 재외, 외주가아닌것, 등..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --이미 등록된 내용 제외    
    GROUP BY E.AssetSeq         , --재고자산분류    
           N.AccSeq             , --차변계정    
           N.UMCostType         ,    
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --대변계정  
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END,--대변비용구분   
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind   ,
           A.CustSeq 
           
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT  @SMSlipKind,    
           0      , --기타출고유형    
           5513003           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(@cTRANsAdjAccSeq, 0) , --대변계정    
           ISNULL(0, 0) , --대변비용구분    
           ISNULL(N.AccSeq, 0)   , --차변계정    
           N.UMCostType  , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           1                     , --순서    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0) ,  
           ISNULL(A.CustSeq     , 0)           
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq     
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
             AND N.AssetAccKindSeq = 21 -- 타계정으로대체  
 
                   
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001상품/  
     --AND F.MinorValue  = '1'    --자재    
     --AND F.MinorSeq    <> 6008005   --재공품이 아닌것 
     AND A.InOutKind IN (8023003)  --기타입고/기타출고    
     AND A.SMAdjustKind = 5513003 
--     AND A.CostUnit = @CostUnit    
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1'
     -- 재고관리 안하는것 재외, 외주가아닌것, 등..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --이미 등록된 내용 제외    
    GROUP BY E.AssetSeq         , --재고자산분류    
           N.AccSeq             , --차변계정    
           N.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind    ,
           A.CustSeq
--    /*****************************************************/    
--    --적송보정금액처리    
--    --적송건이 있거나 당월 출고가 기타출고(원가계산전)만 발생한경우의 보정처리이다.                       
--    /*****************************************************/    
--    
--    --적송조정계정    
--    EXEC dbo._SCOMEnv @CompanySeq, 5506,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    
--    --적송조정 계정의 비용구분    
--        
--    EXEC dbo._SCOMEnv @CompanySeq, 5506,@UserSeq,@@PROCID,@cTRANsAdjUMcostTypeSeq OUTPUT    
--    --단수금액 보정    
--    UPDATE #TempInOut     
--       SET Amt  = AMt + ISNULL((SELECT SUM(Amt) FROM _TESMGInOutStock  A  WHERE A.CompanySeq   = @CompanySeq    
--              AND A.SMAdjustKind = 5513003 -- 자재단가보정    
--              AND A.CostUnit     = @CostUnit     
--              AND A.CostKeySeq   = @CostKeySeq    
--              AND A.InOutKind    = 8023003  --기타출고     
--              ),0)    
--      FROM #TempInOut     
--    /******************************************************************/    
--    --대체출고 :우선 제외(기타입출고를 써라)    
--    /******************************************************************/    
    
    GOTO Proc_Query
        
RETURN 
/*********************************************************************************************************/  
PROC_Mat: --기타입출고 자재


    --기타입고    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(L.AccSeq, 0)   , --차변계정    
           L.UMCostType           , --차변비용구분    
           ISNULL(j.ValueSeq, 0)  , --대변계정    
           ISNULL(K.ValueSeq, 0)  , --대변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           1                     , --순서    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0),  
           ISNULL(A.CustSeq     , 0),
		   ISNULL(AB.ItemSeq,0)            
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
--               LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                      ON C.DeptSeq    = P.DeptSeq      
--                                                     AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --지우리    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     --AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '1002'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --자산처리계정     
               LEFT OUTER JOIN #ESMMatAcc   AS O ON j.ValueSeq = O.AccSeq  AND K.ValueSeq = O.UMCostType
			    LEFT OUTER JOIN KPX_TPDSFCProdPackReportRelation AS AA WITH(NOLOCK) ON A.CompanySeq    = AA.CompanySeq
																				  AND A.InOutSeq      = AA.InOutSeq
																				  AND A.InOutSerl     = AA.InOutSerl
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem     AS AB WITH(NOLOCK) ON AA.CompanySeq   = AB.CompanySeq
																				  AND AA.WorkOrderSeq = AB.PackOrderSeq
																				  AND AA.WorkOrderSerl= AB.PackOrderSerl
                   
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '1'    --자재    
     AND F.MinorSeq    <> 6008005   --재공품이 아닌것    
     AND A.InOutKind IN (8023004)  --기타입고/기타출고    
--     AND A.CostUnit = @CostUnit   
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )     
    AND (( E.IsToOtherAcc = '0' OR E.IsToOtherAcc IS NULL)  
        OR (O.AccSeq IS NOT NULL ))
		 AND (A.InOutDetailKind IN (SELECT MinorSeq 
                                      FROM _TDAUMinorValue AS A 
                                     WHERE A.CompanySeq = @CompanySeq 
                                       AND A.MajorSeq = 8025
                                       AND A.Serl = 1000005 
                                       AND A.ValueText = '1' 
                                   ) 
             )		-- 드럼포장
	 AND (AA.InOutType=31) 

     -- 재고관리 안하는것 재외, 외주가아닌것, 등..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --이미 등록된 내용 제외    
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형   
           L.AccSeq             , --차변계정    
           L.UMCostType         ,    
           j.ValueSeq          , --대변계정    
           K.ValueSeq          , --대변비용구분     
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind          ,
           A.CustSeq ,
		   AB.ItemSeq
	
	
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind, 
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(L.AccSeq, 0)   , --차변계정    
           L.UMCostType           , --차변비용구분    
           ISNULL(N.AccSeq, 0)  , --대변계정    
           ISNULL(N.UMCostType, 0)  , --대변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           1                     , --순서    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0),  
           ISNULL(A.CustSeq     , 0),
		   ISNULL(AB.ItemSeq,0)
	  --SELECT A.InOutDetailKind,A.InOutSeq, A.InOutSerl, AA.InOutSeq, AA.InOutSerl            
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
--               LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                      ON C.DeptSeq    = P.DeptSeq      
--                                                     AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --지우리    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     --AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '1002'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --자산처리계정 
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- 타계정에서 대체  
               LEFT OUTER JOIN #ESMMatAcc   AS O ON j.ValueSeq = O.AccSeq  AND K.ValueSeq = O.UMCostType
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportRelation AS AA WITH(NOLOCK) ON A.CompanySeq    = AA.CompanySeq
																				  AND A.InOutSeq      = AA.InOutSeq
																				  AND A.InOutSerl     = AA.InOutSerl
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem     AS AB WITH(NOLOCK) ON AA.CompanySeq   = AB.CompanySeq
																				  AND AA.WorkOrderSeq = AB.PackOrderSeq
																				  AND AA.WorkOrderSerl= AB.PackOrderSerl
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '1'    --자재    
     AND F.MinorSeq    <> 6008005   --재공품이 아닌것    
     AND A.InOutKind IN (8023004)  --기타입고/기타출고    
--     AND A.CostUnit = @CostUnit   
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
      )     
    AND E.IsToOtherAcc = '1' AND O.AccSeq IS NULL 
	AND (A.InOutDetailKind IN (8025007) )		-- 드럼포장
	AND (AA.InOutType=31)

  --    재고관리 안하는것 재외, 외주가아닌것, 등..    
   --  AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --이미 등록된 내용 제외    
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           L.AccSeq             , --차변계정    
           L.UMCostType         ,    
           N.AccSeq          , --대변계정    
           N.UMCostType          , --대변비용구분    
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind  ,
           A.CustSeq,
		   AB.ItemSeq
  
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(N.AccSeq, 0)   , --차변계정    
           N.UMCostType           , --차변비용구분    
           ISNULL(j.ValueSeq, 0)  , --대변계정    
           ISNULL(K.ValueSeq, 0)  , --대변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           1                     , --순서    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0) ,  
           ISNULL(A.CustSeq     , 0) ,
		   ISNULL(AB.ItemSeq,0)          
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
--               LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                      ON C.DeptSeq    = P.DeptSeq      
--                                                     AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --지우리    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     --AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '1002'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- 타계정에서 대체  
               LEFT OUTER JOIN #ESMMatAcc   AS O ON j.ValueSeq = O.AccSeq  AND K.ValueSeq = O.UMCostType
			    LEFT OUTER JOIN KPX_TPDSFCProdPackReportRelation AS AA WITH(NOLOCK) ON A.CompanySeq    = AA.CompanySeq
																				  AND A.InOutSeq      = AA.InOutSeq
																				  AND A.InOutSerl     = AA.InOutSerl
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem     AS AB WITH(NOLOCK) ON AA.CompanySeq   = AB.CompanySeq
																				  AND AA.WorkOrderSeq = AB.PackOrderSeq
																				  AND AA.WorkOrderSerl= AB.PackOrderSerl
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '1'    --자재    
     AND F.MinorSeq    <> 6008005   --재공품이 아닌것    
     AND A.InOutKind IN (8023004)  --기타입고/기타출고    
--     AND A.CostUnit = @CostUnit   
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )     
    AND E.IsToOtherAcc = '1'  AND O.AccSeq IS NULL
	AND (A.InOutDetailKind IN (8025007) )		-- 드럼포장 
	AND (AA.InOutType=31)
     -- 재고관리 안하는것 재외, 외주가아닌것, 등..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --이미 등록된 내용 제외    
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형   
           N.AccSeq             , --차변계정    
           N.UMCostType         ,    
           j.ValueSeq          , --대변계정    
           K.ValueSeq          , --대변비용구분     
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind   ,
           A.CustSeq	,
           AB.ItemSeq 


     --기타출고 
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(j.ValueSeq, 0) , --대변계정    
           ISNULL(K.ValueSeq, 0) , --대변비용구분    
           ISNULL(L.AccSeq, 0)   , --차변계정    
           L.UMCostType  , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           1                     , --순서    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0),  
           ISNULL(A.CustSeq     , 0),
		   ISNULL(AB.ItemSeq,0)        
	  --SELECT AA.InOutType,A.*    
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                               AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
--               LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                      ON C.DeptSeq    = P.DeptSeq      
--                                                     AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --지우리    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                   --  AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --자산처리계정    
               LEFT OUTER JOIN #ESMMatAcc   AS O ON j.ValueSeq = O.AccSeq  AND K.ValueSeq = O.UMCostType
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportRelation AS AA WITH(NOLOCK) ON A.CompanySeq    = AA.CompanySeq
																				  AND A.InOutSeq      = AA.InOutSeq
																				  AND A.InOutSerl     = AA.InOutSerl
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem     AS AB WITH(NOLOCK) ON AA.CompanySeq   = AB.CompanySeq
																				  AND AA.WorkOrderSeq = AB.PackOrderSeq
																				  AND AA.WorkOrderSerl= AB.PackOrderSerl

   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '1'    --자재    
     AND F.MinorSeq    <> 6008005   --재공품이 아닌것    
     AND A.InOutKind IN (8023003)  --기타입고/기타출고    
--     AND A.CostUnit = @CostUnit    
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )  
     AND (( E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL )
         OR (O.AccSeq IS NOT NULL))
	 AND (A.InOutDetailKind IN (8025007) )		-- 드럼포장
	-- AND (AA.InOutType=31) 
     -- 재고관리 안하는것 재외, 외주가아닌것, 등..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --이미 등록된 내용 제외    
    GROUP BY E.AssetSeq         , --재고자산분류    
          A.InOutDetailKind    , --기타출고유형    
           j.ValueSeq          , --대변계정    
           K.ValueSeq          , --대변비용구분    
           L.AccSeq             , --차변계정    
           L.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind    ,
           A.CustSeq,
		   AB.ItemSeq
   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(N.AccSeq, 0) , --대변계정    
           ISNULL(N.UMCostType, 0) , --대변비용구분    
           ISNULL(L.AccSeq, 0)   , --차변계정    
           L.UMCostType  , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           1                     , --순서    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0) ,  
           ISNULL(A.CustSeq     , 0),
		   ISNULL(AB.ItemSeq,0)           
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
--               LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                      ON C.DeptSeq    = P.DeptSeq      
--                                                     AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --지우리    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     --AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
        LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --자산처리계정    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- 타계정으로대체  
               LEFT OUTER JOIN #ESMMatAcc   AS O ON j.ValueSeq = O.AccSeq  AND K.ValueSeq = O.UMCostType
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportRelation AS AA WITH(NOLOCK) ON A.CompanySeq    = AA.CompanySeq
																				  AND A.InOutSeq      = AA.InOutSeq
																				  AND A.InOutSerl     = AA.InOutSerl
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem     AS AB WITH(NOLOCK) ON AA.CompanySeq   = AB.CompanySeq
																				  AND AA.WorkOrderSeq = AB.PackOrderSeq
																				  AND AA.WorkOrderSerl= AB.PackOrderSerl
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '1'    --자재    
     AND F.MinorSeq    <> 6008005   --재공품이 아닌것    
     AND A.InOutKind IN (8023003)  --기타입고/기타출고    
--     AND A.CostUnit = @CostUnit    
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )  
     AND E.IsFromOtherAcc = '1' AND O.AccSeq IS NULL 
	 AND (A.InOutDetailKind IN (8025007) )		-- 드럼포장
	 AND (AA.InOutType=31) 
     -- 재고관리 안하는것 재외, 외주가아닌것, 등..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --이미 등록된 내용 제외    
    GROUP BY E.AssetSeq         , --재고자산분류    
          A.InOutDetailKind    , --기타출고유형    
           N.AccSeq         , --대변계정    
           N.UMCostType          , --대변비용구분    
           L.AccSeq             , --차변계정    
           L.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind  ,
           A.CustSeq  ,
		   AB.ItemSeq
           

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(j.ValueSeq, 0) , --대변계정    
           ISNULL(K.ValueSeq, 0) , --대변비용구분    
           ISNULL(N.AccSeq, 0)   , --차변계정    
           N.UMCostType  , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           1                     , --순서    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0),  
           ISNULL(A.CustSeq     , 0)  ,
		   ISNULL(AB.ItemSeq,0)          
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
--               LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                      ON C.DeptSeq    = P.DeptSeq      
--                                                     AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --지우리    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     --AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                     AND N.AssetAccKindSeq = 21 -- 타계정으로대체  
               LEFT OUTER JOIN #ESMMatAcc   AS O ON j.ValueSeq = O.AccSeq  AND K.ValueSeq = O.UMCostType
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportRelation AS AA WITH(NOLOCK) ON A.CompanySeq    = AA.CompanySeq
																				  AND A.InOutSeq      = AA.InOutSeq
																				  AND A.InOutSerl     = AA.InOutSerl
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem     AS AB WITH(NOLOCK) ON AA.CompanySeq   = AB.CompanySeq
																				  AND AA.WorkOrderSeq = AB.PackOrderSeq
																				  AND AA.WorkOrderSerl= AB.PackOrderSerl
                   
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '1'    --자재    
     AND F.MinorSeq    <> 6008005   --재공품이 아닌것    
     AND A.InOutKind IN (8023003)  --기타입고/기타출고    
--     AND A.CostUnit = @CostUnit    
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )  
     AND E.IsFromOtherAcc = '1'AND O.AccSeq IS NULL 
	 AND (A.InOutDetailKind IN (8025007) )		-- 드럼포장
	 AND (AA.InOutType=31) 
     -- 재고관리 안하는것 재외, 외주가아닌것, 등..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --이미 등록된 내용 제외    
    GROUP BY E.AssetSeq         , --재고자산분류    
          A.InOutDetailKind    , --기타출고유형    
           j.ValueSeq          , --대변계정    
           K.ValueSeq          , --대변비용구분    
           N.AccSeq             , --차변계정    
           N.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind    ,
           A.CustSeq,
		   AB.ItemSeq
--    /*****************************************************/    
--    --단수보정금액처리    
--    --적송건이 있거나 당월 출고가 기타출고(원가계산전)만 발생한경우의 보정처리이다.                       
--    /*****************************************************/    
--    
    --단수조정계정    
    EXEC dbo._SCOMEnv @CompanySeq, 5507,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    
--    --적송조정 계정의 비용구분    
--    EXEC dbo._SCOMEnv @CompanySeq, 5540,@UserSeq,@@PROCID,@cTRANsAdjUMcostTypeSeq OUTPUT    
--    select * from _TDASMinor where minorname like '%보정%'


    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind,    
           0      , --기타출고유형    
           5513002           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           --ISNULL(@cTRANsAdjAccSeq, 0) , --대변계정  
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --대변계정  
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --대변비용구분    
           ISNULL(N.AccSeq, 0)   , --차변계정    
           N.UMCostType  , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           1                     , --순서    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0) ,  
           ISNULL(A.CustSeq     , 0) ,
		   ISNULL(AB.ItemSeq,0)        
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq     
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                     AND N.AssetAccKindSeq = 1 --자산처리계정
               LEFT OUTER JOIN _TDAItemAssetAcc AS O WITH(NOLOCK) ON D.AssetSeq  = O.AssetSeq  AND O.Companyseq = @CompanySeq      
                                                     AND O.AssetAccKindSeq = 21-- 타계정으로대체   
                LEFT OUTER JOIN KPX_TPDSFCProdPackReportRelation AS AA WITH(NOLOCK) ON A.CompanySeq    = AA.CompanySeq
																				  AND A.InOutSeq      = AA.InOutSeq
																				  AND A.InOutSerl     = AA.InOutSerl
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem     AS AB WITH(NOLOCK) ON AA.CompanySeq   = AB.CompanySeq
																				  AND AA.WorkOrderSeq = AB.PackOrderSeq
																				  AND AA.WorkOrderSerl= AB.PackOrderSerl    
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '1'    --자재    
     AND F.MinorSeq    <> 6008005   --재공품이 아닌것    
     AND A.InOutKind IN (8023003)  --기타입고/기타출고    
     AND A.SMAdjustKind = 5513002 
--     AND A.CostUnit = @CostUnit    
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )
	 AND (A.InOutDetailKind IN (8025007) )		-- 드럼포장
	 AND (AA.InOutType=31)   
--     AND E.IsFromOtherAcc = '1'
     -- 재고관리 안하는것 재외, 외주가아닌것, 등..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --이미 등록된 내용 제외    
    GROUP BY E.AssetSeq         , --재고자산분류    
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --대변계정 
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --대변비용구분     
           N.AccSeq             , --차변계정    
           N.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind  ,
           A.CustSeq  ,
		   AB.ItemSeq
         
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind,    
           0   , --기타출고유형    
           5513002           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(@cTRANsAdjAccSeq, 0) , --대변계정  
           ISNULL(0, 0), --대변비용구분    
           ISNULL(N.AccSeq, 0)   , --차변계정    
           N.UMCostType  , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           1              , --순서    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0) ,  
           ISNULL(A.CustSeq     , 0),
		   ISNULL(AB.ItemSeq,0)           
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq     
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                     AND N.AssetAccKindSeq = 21 --타계정으로대체
                LEFT OUTER JOIN KPX_TPDSFCProdPackReportRelation AS AA WITH(NOLOCK) ON A.CompanySeq    = AA.CompanySeq
																				  AND A.InOutSeq      = AA.InOutSeq
																				  AND A.InOutSerl     = AA.InOutSerl
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem     AS AB WITH(NOLOCK) ON AA.CompanySeq   = AB.CompanySeq
																				  AND AA.WorkOrderSeq = AB.PackOrderSeq
																				  AND AA.WorkOrderSerl= AB.PackOrderSerl    
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '1'    --자재    
     AND F.MinorSeq    <> 6008005   --재공품이 아닌것    
     AND A.InOutKind IN (8023003)  --기타입고/기타출고    
     AND A.SMAdjustKind = 5513002 
     AND E.IsFromOtherAcc = '1'
--     AND A.CostUnit = @CostUnit    
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         ) 
	 AND (A.InOutDetailKind IN (8025007) )		-- 드럼포장
	 AND (AA.InOutType=31)  
--     AND E.IsFromOtherAcc = '1'
     -- 재고관리 안하는것 재외, 외주가아닌것, 등..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --이미 등록된 내용 제외    
    GROUP BY E.AssetSeq         , --재고자산분류    
           N.AccSeq             , --차변계정    
           N.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind   ,
           A.CustSeq,
		   AB.ItemSeq
----단수금액 보정    
--UPDATE #TempInOut     
--   SET Amt  = AMt + ISNULL((SELECT SUM(Amt) FROM _TESMGInOutStock  A  WHERE A.CompanySeq   = @CompanySeq    
--          AND A.SMAdjustKind = 5513002 -- 자재단가보정    
--          AND A.CostUnit     = @CostUnit     
--          AND A.CostKeySeq   = @CostKeySeq    
--          AND A.InOutKind    = 8023003  --기타출고     
--          ),0)    
--  FROM #TempInOut     
  
    GOTO Proc_Query
RETURN 
/**************************************************************************************************************/
AVG_Prod: 
    --연총평균 보정전표_제품(제조계정 제외)

--  _TDAItemAssetAcc : 
--         AssetAccKindSeq 22 : 년총평균 투입보정계정
--         AssetAccKindSeq 23 : 년총평균 매출보정계정
--         AssetAccKindSeq 24 : 년총평균 기타보정계정
-- 
--select * From _TDADefineItemAssetAcc
--where companyseq = 1 
--연총평균 보정계정은 자산분류별 계정세팅에서 가져오도록 한다. 
--활동센터별, 품목별로 전표발행은 환경설정을 따른다. 매출원가를 건별로 보정하는것은 
--수익성을 위해 필요하나 전표까지 건별로 발행할 필요는 없슴. 

  
--- 매출원가 전표처리에 활동센터, 판매부서별로 매출원가를 나눠서 내역조회를 하는것은 환경설정 값에 따른다.   
--- 5538 매출원가전표 활동센터(or 부서)별 로 집계 여부  
  

--제품매출원가 보정시 타계정으로 전표는 발행할 필요가 없다. 본 계정으로 가는 계정이므로 타계정으로는 
--빼도록 하기위해 보정계정이 본계정과 같은 매출원가 계정인 경우에는 그 재고자산분류에는 타계정전표는 
--발행하지 않도록 해야한다.  
                                      
-- 
--5535001	5535	연총평균 매출원가조정
--5535002	5535	연총평균 투입금액조정
--5535003	5535	연총평균 기타출고금액 조정

    INSERT INTO #TempInOut_Garbege(    
           SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,    
           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind ,IsFromOtherAcc )    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(N.AccSeq, 0) , --차변계정    
           ISNULL(N.UMCostType, 0) , --차변비용구분    
           ISNULL(L.AccSeq, 0)   , --대변계정    
           L.UMCostType  , --대변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           1                    , --순서
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          , 
           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,         
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE  A.CustSeq   END          ,   --매출거래처 
           CASE WHEN ( @IsDivideCCtrItem = '0' AND ( A.InOutDetailKind <> 5535002 ) ) THEN 0 ELSE   A.GoodItemSeq   END ,    --투입제품   
           0,
           CASE WHEN  E.IsFromOtherAcc = '1' AND  M.AssetSeq IS NULL  THEN '1'  
                ELSE '0'  
           END      
       FROM _TESMGInOutStock             AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정 
               LEFT OUTER JOIN _TDAItemAssetAcc    AS N WITH(NOLOCK) ON E.CompanySeq       = N.CompanySeq    
                                                         AND E.AssetSeq         = N.AssetSeq    
                                                         AND (   (( A.InOutDetailKind = 5535002 )
                                                                   AND  N.AssetAccKindSeq  = 22 --투입보정계정
                                                                  )   
                                                              OR (( A.InOutDetailKind = 5535001 )
                                                                   AND  N.AssetAccKindSeq  = 23 --매출보정계정
                                                                  )   
                                                              OR (( A.InOutDetailKind = 5535003 )
                                                                   AND  N.AssetAccKindSeq  = 24 --기타보정계정
                                                                 )
                                                             )   
               LEFT OUTER JOIN #AssetSeq    AS M WITH(NOLOCK) ON E.AssetSeq = M.AssetSeq 
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'   
     AND A.SMAdjustKind = 5513004 --제품금액보정_연총평균 
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003       --기타출고
     AND F.MinorSeq <> 6008001     
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
       OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     --AND (@YAVGAdjTransType = 5536002  OR (@YAVGAdjTransType = 5536001 AND  A.InOutDetailKind <> 5535003))--원천구분별 보정이 아닐 경우 매출기타보정 사용  
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           N.AccSeq             ,    
           N.UMCostType         ,  
           L.AccSeq             ,  
           L.UMCostType         ,    
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,    
--           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE ISNULL(A.CCtrSeq , 0) END          ,    
           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,         
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE  A.CustSeq   END          ,   --매출거래처 
           CASE WHEN @IsDivideCCtrItem = '0' AND ( A.InOutDetailKind <> 5535002 )  THEN 0 ELSE   A.GoodItemSeq   END,     --투입제품   
           CASE WHEN  E.IsFromOtherAcc = '1' AND  M.AssetSeq IS NULL  THEN '1'  
                ELSE '0'  
           END     
   ORDER BY A.InOutDetailKind , E.AssetSeq 


    --제품의 경우  투입이 보정 되는 경우와 기타출고가 보정되는 경우를 분리하기 어려움
    
--    INSERT INTO #TempInOut_Garbege(    
--           SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,    
--           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,    
--           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind , IsFromOtherAcc )    
--    SELECT @SMSlipKind           ,    
--           5513004    , --기타출고유형    
--           A.InOutKind           , --입출고유형    
--           E.AssetSeq            , --재고자산분류    
--           ISNULL(j.ValueSeq, 0) , --차변계정        
--           ISNULL(K.ValueSeq, 0) , --차변비용구분  
--           ISNULL(L.AccSeq, 0)   , --대변계정    
--           L.UMCostType          , --대변비용구분    
--           SUM(A.Amt )           , --기타출고금액    
--           1                    , --순서
--           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          , 
--           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,         
--           0,   --매출거래처 
--           0 ,    --투입제품   
--           A.InOutDetailKind AS UMRealDetilKind,            
--           CASE WHEN  E.IsFromOtherAcc = '1' AND M.AssetSeq IS NULL  THEN '1'  
--                ELSE '0'  
--           END      
--       FROM _TESMGInOutStock_YAVGAdj             AS A WITH(NOLOCK)    
--               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
--                                                         AND A.ItemSeq    = D.ItemSeq    
--               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
--                                                         AND D.AssetSeq   = E.AssetSeq     
--               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
--                                                         AND E.SMAssetGrp = F.MinorSeq    
--               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
--                                                         AND E.AssetSeq         = L.AssetSeq    
--                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정 
--               LEFT OUTER JOIN _TDAUMinorValue  AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq        
--                                                                 AND A.InOutDetailKind  = J.MinorSeq        
--                                                                 AND J.ValueSeq         > 0        
--                                                                 AND J.Serl             = '2003'        
--               LEFT OUTER JOIN _TDAUMinorValue  AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq        
--                                                                 AND A.InOutDetailKind  = K.MinorSeq        
--                                                                 AND K.Serl             = '2004'       
--               LEFT OUTER JOIN #AssetSeq    AS M WITH(NOLOCK) ON E.AssetSeq = M.AssetSeq 
--   WHERE A.CompanySeq = @CompanySeq         
--     AND A.AdjCostKeySeq = @CostKeySeq
--     --AND A.InOutDate LIKE @CostYM + '%'   
--     --AND A.SMAdjustKind = 5513004 --제품금액보정_연총평균 
--     AND F.MinorValue  = '0'    
--     AND A.InOutKind = 8023003       --기타출고
--     AND F.MinorSeq <> 6008001     
--     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
--       OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
--     AND (@YAVGAdjTransType = 5536001 ) --원천구분별이고 기타보정 계정일 경우 원천별로 보정함  
--    GROUP BY E.AssetSeq         , --재고자산분류    
--           A.InOutDetailKind    , --기타출고유형    
--           A.InOutKind          , --입출고유형    
--           ISNULL(j.ValueSeq, 0) , --차변계정        
--           ISNULL(K.ValueSeq, 0) , --차변비용구분  
--           L.AccSeq             ,  
--           L.UMCostType         ,    
--           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,    
----           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE ISNULL(A.CCtrSeq , 0) END          ,    
--           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,         
--           A.InOutDetailKind,
--           CASE WHEN  E.IsFromOtherAcc = '1' AND  M.AssetSeq IS  NULL  THEN '1'  
--                ELSE '0'  
--           END            
--   ORDER BY A.InOutDetailKind , E.AssetSeq 
 
     INSERT INTO #TempInOut(        
       SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,        
       DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,        
       DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind,ISSUM)            
   SELECT SMSlipKind   ,INOutDetailKind,Remark      ,A.AssetSeq   ,   
          CASE WHEN ISNULL(B.DrAccSeq    ,0) = 0 THEN A.DrAccSeq ELSE B.DrAccSeq END    ,  
          CASE WHEN ISNULL(B.DrUMCostType,0) = 0 THEN A.DrUMCostType  ELSE B.DrUMCostType END  ,  
          CASE WHEN ISNULL(B.CrAccSeq    ,0) = 0 THEN A.CrAccSeq     ELSE B.CrAccSeq END     ,  
          CASE WHEN ISNULL(B.CrUMCostType,0) = 0 THEN A.CrUMCostType  ELSE B.CrUMCostType END  ,  
           Amt        , ShowOrder ,        
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind,'1'  
     FROM #TempInOut_Garbege AS A   
          LEFT OUTER JOIN #OtherAcc AS B ON A.AssetSeq = B.AssetSeq AND A.IsFromOtherAcc = B.isFromOtherAcc  

    GOTO Proc_Query
 
   
RETURN 
/*****************************************************************************************/
AVG_GoodS: --연총평균 보정전표_상품
     
--제품매출원가 보정시 타계정으로 전표는 발행할 필요가 없다. 본 계정으로 가는 계정이므로 타계정으로는   
--빼도록 하기위해 보정계정이 본계정과 같은 매출원가 계정인 경우에는 그 재고자산분류에는 타계정전표는   
--발행하지 않도록 해야한다.   

--5535001 5535 연총평균 매출원가조정  
--5535002 5535 연총평균 투입금액조정  
--5535003 5535 연총평균 기타출고금액 조정   
 
    
    INSERT INTO #TempInOut_Garbege (      
           SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,      
           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,      
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind,IsFromOtherAcc)    
    SELECT @SMSlipKind           ,      
           A.InOutDetailKind    , --기타출고유형      
           A.InOutKind           , --입출고유형      
           E.AssetSeq            , --재고자산분류      
           ISNULL(N.AccSeq, 0) , --차변계정      
           ISNULL(N.UMCostType, 0) , --차변비용구분      
           ISNULL(L.AccSeq, 0)   , --대변계정      
           L.UMCostType          , --대변비용구분      
           SUM(A.Amt )           , --기타출고금액      
           1                    , --순서  
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END         ,      
           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE  A.CustSeq   END          ,   --매출거래처   
           --CASE WHEN ( @IsDivideCCtrItem = '0' AND ( A.InOutDetailKind <> 5535002 ) ) THEN 0 ELSE   A.GoodItemSeq   END     --투입제품     
           CASE WHEN ( @IsDivideCCtrItem = '0'  --eykim. 110701. 투입일 경우는 연총보정에서 원천구분별 보정일 경우는 원가항목에 투입된 제품을 조회시켜야 한다. 
					 AND ( ( A.InOutDetailKind <> 5535002 ) OR ( A.InOutDetailKind = 5535002 AND @YAVGAdjTransType = 5536002 ) ) ) THEN 0 ELSE   A.GoodItemSeq   END,     --투입제품     
		   0,
           CASE WHEN  E.IsFromOtherAcc = '1'  AND M.AssetSeq IS NULL THEN '1'  
                ELSE '0'  
           END   
					 
       FROM _TESMGInOutStock             AS A WITH(NOLOCK)      
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq      
                                                         AND A.ItemSeq    = D.ItemSeq      
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq      
                                                         AND D.AssetSeq   = E.AssetSeq       
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq      
                                                         AND E.SMAssetGrp = F.MinorSeq      
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq      
                                                         AND E.AssetSeq         = L.AssetSeq      
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정   
               LEFT OUTER JOIN _TDAItemAssetAcc    AS N WITH(NOLOCK) ON E.CompanySeq       = N.CompanySeq      
                                                         AND E.AssetSeq         = N.AssetSeq      
                                                         AND (   (( A.InOutDetailKind = 5535002 )  
                                                                   AND  N.AssetAccKindSeq  = 22 --투입보정계정  
                                                                  )     
                                                              OR (( A.InOutDetailKind = 5535001 )  
                                                                   AND  N.AssetAccKindSeq  = 23 --매출보정계정  
                                                                  )     
                                                              OR (( A.InOutDetailKind = 5535003 )  
                                                                   AND  N.AssetAccKindSeq  = 24 --기타보정계정  
                                                                 )  
                                                             )     
               LEFT OUTER JOIN #AssetSeq    AS M WITH(NOLOCK) ON E.AssetSeq = M.AssetSeq   
   WHERE A.CompanySeq = @CompanySeq           
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'     
     AND A.SMAdjustKind = 5513006 --상품금액보정_ 연총평균  
     AND F.MinorValue  = '0'      
     AND A.InOutKind = 8023003       --기타출고  
     AND F.MinorSeq  = 6008001       
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )  
       OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))  
     AND (@YAVGAdjTransType = 5536002  OR (@YAVGAdjTransType = 5536001 AND  A.InOutDetailKind <> 5535003))--원천구분별 보정이 아닐 경우 매출기타보정 사용  
    GROUP BY E.AssetSeq         , --재고자산분류      
           A.InOutDetailKind    , --기타출고유형      
           A.InOutKind          , --입출고유형      
           N.AccSeq             ,      
           N.UMCostType         ,    
           L.AccSeq             ,    
           L.UMCostType         ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0) END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE  A.CustSeq   END          ,   --매출거래처   
           --CASE WHEN @IsDivideCCtrItem = '0' AND ( A.InOutDetailKind <> 5535002 )  THEN 0 ELSE   A.GoodItemSeq   END     --투입제품     
           CASE WHEN ( @IsDivideCCtrItem = '0'  --eykim. 110701. 투입일 경우는 연총보정에서 원천구분별 보정일 경우는 원가항목에 투입된 제품을 조회시켜야 한다. 
					 AND ( ( A.InOutDetailKind <> 5535002 ) OR ( A.InOutDetailKind = 5535002 AND @YAVGAdjTransType = 5536002 ) ) ) THEN 0 ELSE   A.GoodItemSeq   END,     --투입제품     
           CASE WHEN  E.IsFromOtherAcc = '1' AND   M.AssetSeq IS NULL THEN '1'  
                ELSE '0'  
           END   
   ORDER BY A.InOutDetailKind , E.AssetSeq   
   
   
     
    INSERT INTO #TempInOut_Garbege (      
           SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,      
           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,      
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind, IsFromOtherAcc)    
    SELECT @SMSlipKind           ,      
           5513006               , --기타출고유형      
           A.InOutKind           , --입출고유형      
           E.AssetSeq            , --재고자산분류      
           ISNULL(j.ValueSeq, 0) , --차변계정        
           ISNULL(K.ValueSeq, 0) , --차변비용구분     
           ISNULL(L.AccSeq, 0)   , --대변계정      
           L.UMCostType          , --대변비용구분      
           SUM(A.Amt )           , --기타출고금액      
           1                    , --순서  
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END         ,      
           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,      
           0,     --매출거래처   
           0,     --투입제품     
           A.InOutDetailKind AS UMRealDetilKind, 					 
           CASE WHEN  E.IsFromOtherAcc = '1' AND   M.AssetSeq IS NULL THEN '1'  
                ELSE '0'  
           END   					 
       FROM _TESMGInOutStock_YAVGAdj             AS A WITH(NOLOCK)      
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq      
                                                         AND A.ItemSeq    = D.ItemSeq      
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq      
                                                         AND D.AssetSeq   = E.AssetSeq       
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq      
                                                         AND E.SMAssetGrp = F.MinorSeq      
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq      
                                                         AND E.AssetSeq         = L.AssetSeq      
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정   
               LEFT OUTER JOIN _TDAUMinorValue  AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq        
                                                                 AND A.InOutDetailKind  = J.MinorSeq        
                                                                 AND J.ValueSeq         > 0        
                                                                 AND J.Serl             = '2003'        
               LEFT OUTER JOIN _TDAUMinorValue  AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq        
                                                                 AND A.InOutDetailKind  = K.MinorSeq        
                                                                 AND K.Serl             = '2004'    
               LEFT OUTER JOIN #AssetSeq    AS M WITH(NOLOCK) ON E.AssetSeq = M.AssetSeq   
   WHERE A.CompanySeq = @CompanySeq           
     AND A.AdjCostKeySeq = @CostKeySeq  
     --AND A.InOutDate LIKE @CostYM + '%'     
     --AND A.SMAdjustKind = 5513006 --상품금액보정_ 연총평균  
     AND F.MinorValue  = '0'      
     AND A.InOutKind = 8023003       --기타출고  
     AND F.MinorSeq  = 6008001       
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )  
       OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))  
     AND (@YAVGAdjTransType = 5536001 ) --원천구분별이고 기타보정 계정일 경우 원천별로 보정함  
    GROUP BY E.AssetSeq         , --재고자산분류      
           A.InOutDetailKind    , --기타출고유형      
           A.InOutKind          , --입출고유형      
      ISNULL(j.ValueSeq, 0) , --차변계정        
           ISNULL(K.ValueSeq, 0) , --차변비용구분   
           L.AccSeq             ,    
           L.UMCostType         ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0) END          ,      
           CASE WHEN  E.IsFromOtherAcc = '1' AND   M.AssetSeq IS NULL THEN '1'  
                ELSE '0'  
           END   ,A.InOutDetailKind 
   ORDER BY A.InOutDetailKind , E.AssetSeq   
   

   INSERT INTO #TempInOut(        
       SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,        
       DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,        
       DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind,ISSUM)            
   SELECT SMSlipKind   ,INOutDetailKind,Remark      ,A.AssetSeq   ,   
          CASE WHEN ISNULL(B.DrAccSeq    ,0) = 0 THEN A.DrAccSeq ELSE B.DrAccSeq END    ,  
          CASE WHEN ISNULL(B.DrUMCostType,0) = 0 THEN A.DrUMCostType  ELSE B.DrUMCostType END  ,  
          CASE WHEN ISNULL(B.CrAccSeq    ,0) = 0 THEN A.CrAccSeq     ELSE B.CrAccSeq END     ,  
          CASE WHEN ISNULL(B.CrUMCostType,0) = 0 THEN A.CrUMCostType  ELSE B.CrUMCostType END  ,  
           Amt        , ShowOrder ,        
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind,'1'  
     FROM #TempInOut_Garbege AS A   
          LEFT OUTER JOIN #OtherAcc AS B ON A.AssetSeq = B.AssetSeq AND A.IsFromOtherAcc = B.isFromOtherAcc  

    GOTO Proc_Query  
RETURN 
/*********************************************************************************************************/  
AVG_Mat: --연총평균 보정전표_자재

--2011.05.25 지해
--자재의 보정전표이기 때문에 재료비로 대체가 되는 계정은 타계정을 생성하지 않도록 한다.
-- #ESMMatAcc 사용

--5535001 5535 연총평균 매출원가조정  
--5535002 5535 연총평균 투입금액조정  
--5535003 5535 연총평균 기타출고금액 조정  
    
 --   EXEC dbo._SCOMEnv @CompanySeq,5555 ,0  /*@UserSeq*/,@@PROCID,@IsDivideCCtrItem OUTPUT    
 --   EXEC dbo._SCOMEnv @CompanySeq,5551 ,0  /*@UserSeq*/,@@PROCID,@YAVGAdjTransType OUTPUT    
 ----@YAVGAdjTransType
 ----원천데이터별 보정	5536001
 ----출고구분별 보정		5536002

   ---#################[기타입출고의 원천데이터별 보정일 경우 기타출고구분별로 가능하게 수정함] ###################################
   
    
    INSERT INTO #TempInOut_Garbege(      
           SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,      
           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,      
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind ,IsFromOtherAcc)      
    SELECT @SMSlipKind           ,      
           A.InOutDetailKind     , --기타출고유형      
           A.InOutKind           , --입출고유형      
           E.AssetSeq            , --재고자산분류      
           ISNULL(N.AccSeq, 0)   , --차변계정      
           ISNULL(N.UMCostType, 0) , --차변비용구분      
           ISNULL(L.AccSeq, 0)   , --대변계정      
           L.UMCostType          , --대변비용구분      
           SUM(A.Amt )           , --기타출고금액      
           1                    , --순서  
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE  A.CustSeq   END          ,   --매출거래처   
           --CASE WHEN ( @IsDivideCCtrItem = '0' /*AND ( A.InOutDetailKind <> 5535002 )*/ ) THEN 0 ELSE   A.GoodItemSeq   END     --투입제품     
           CASE WHEN ( @IsDivideCCtrItem = '0'  --eykim. 110701. 투입일 경우는 연총보정에서 원천구분별 보정일 경우는 원가항목에 투입된 제품을 조회시켜야 한다. 
					 AND ( ( A.InOutDetailKind <> 5535002 ) OR ( A.InOutDetailKind = 5535002 AND @YAVGAdjTransType = 5536002 ) ) ) THEN 0 ELSE   A.GoodItemSeq   END ,    --투입제품     
		   0 ,
           CASE WHEN  E.IsFromOtherAcc = '1' AND A.InOutDetailKind  IN ( 5535001)            AND M.AssetSeq IS NOT NULL 	THEN '1'
                WHEN  E.IsFromOtherAcc = '1' AND  A.InOutDetailKind IN ( 5535002 , 5535003)  AND O.AccSeq IS NULL	THEN '1'
                ELSE '0'
           END 
        FROM _TESMGInOutStock             AS A WITH(NOLOCK)      
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq      
                                                         AND A.ItemSeq    = D.ItemSeq      
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq      
                                                         AND D.AssetSeq   = E.AssetSeq       
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq      
                                                         AND E.SMAssetGrp = F.MinorSeq      
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq      
                                                         AND E.AssetSeq         = L.AssetSeq      
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정   
               LEFT OUTER JOIN _TDAItemAssetAcc    AS N WITH(NOLOCK) ON E.CompanySeq       = N.CompanySeq      
                                                         AND E.AssetSeq         = N.AssetSeq      
                                                         AND (   (( A.InOutDetailKind = 5535002 )  
                                                                   AND  N.AssetAccKindSeq  = 22 --투입보정계정  
                                                                  )     
                                                              OR (( A.InOutDetailKind = 5535001 )  
                                                                   AND  N.AssetAccKindSeq  = 23 --매출보정계정  
                                                                  )     
                                                              OR (( A.InOutDetailKind = 5535003 )  
                                                                   AND  N.AssetAccKindSeq  = 24 --기타보정계정  
                                                                 )  
                                                             )     
               LEFT OUTER JOIN #AssetSeq    AS M WITH(NOLOCK) ON E.AssetSeq = M.AssetSeq 
               LEFT OUTER JOIN #ESMMatAcc   AS O ON  N.AccSeq = O.AccSeq  AND N.UMCostType = O.UMCostType
   WHERE A.CompanySeq = @CompanySeq           
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'     
     AND A.SMAdjustKind = 5513005 --자재금액보정_연총평균  
     AND F.MinorValue  = '1'      
     AND A.InOutKind = 8023003       --기타출고  
     AND F.MinorSeq  <> 6008005       
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )  
       OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))  
     AND (@YAVGAdjTransType = 5536002  OR (@YAVGAdjTransType = 5536001 AND  A.InOutDetailKind <> 5535003))--원천구분별 보정이 아닐 경우 매출기타보정 사용

    GROUP BY E.AssetSeq         , --재고자산분류      
           A.InOutDetailKind    , --기타출고유형      
           A.InOutKind          , --입출고유형      
           N.AccSeq             ,      
           N.UMCostType         ,    
           L.AccSeq             ,    
           L.UMCostType         ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0) END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE  A.CustSeq   END          ,   --매출거래처   
           CASE WHEN ( @IsDivideCCtrItem = '0' 
			    AND ( ( A.InOutDetailKind <> 5535002 ) OR ( A.InOutDetailKind = 5535002 AND @YAVGAdjTransType = 5536002 )  )) THEN 0 ELSE   A.GoodItemSeq   END     --투입제품     
           ,CASE WHEN  E.IsFromOtherAcc = '1' AND A.InOutDetailKind IN( 5535001)            AND M.AssetSeq IS NOT NULL 	THEN '1'
                WHEN  E.IsFromOtherAcc = '1' AND  A.InOutDetailKind IN( 5535002 , 5535003) AND O.AccSeq IS NULL	THEN '1'
                ELSE '0'
           END 
   ORDER BY A.InOutDetailKind , E.AssetSeq   


   
    INSERT INTO #TempInOut_Garbege(      
           SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,      
           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,      
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind,IsFromOtherAcc)      
    SELECT @SMSlipKind           ,      
           5535003               , --기타출고유형      
           A.InOutKind           , --입출고유형      
           E.AssetSeq            , --재고자산분류      
           ISNULL(j.ValueSeq, 0) , --차변계정      
           ISNULL(K.ValueSeq, 0) , --차변비용구분      
           ISNULL(L.AccSeq, 0)   , --대변계정      
           L.UMCostType          , --대변비용구분      
           SUM(A.Amt )           , --기타출고금액      
           1                    , --순서  
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,      
           0         ,  
           0         ,
           A.InOutDetailKind AS UMRealDetilKind,
           CASE WHEN  E.IsFromOtherAcc = '1' AND  O.AccSeq IS NULL	THEN '1'
                ELSE '0'
           END 			 
           
        FROM _TESMGInOutStock_YAVGAdj   AS A WITH(NOLOCK)      
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq      
                                                         AND A.ItemSeq    = D.ItemSeq      
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq      
                                                         AND D.AssetSeq   = E.AssetSeq       
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq      
                                                         AND E.SMAssetGrp = F.MinorSeq      
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq        = I.CompanySeq  --지우리      
                                                         AND A.InOutDetailKind   = I.MinorSeq      
                                                         AND I.IsUse             ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28                                                            
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq      
                                                                 AND E.AssetSeq         = L.AssetSeq      
                                                                 AND L.AssetAccKindSeq  = 1 --자산처리계정   
               LEFT OUTER JOIN _TDAUMinorValue  AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq      
                                                                 AND A.InOutDetailKind  = J.MinorSeq      
                                                                 AND J.ValueSeq         > 0      
                                                                 AND J.Serl             = '2003'      
               LEFT OUTER JOIN _TDAUMinorValue  AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq      
                                                                 AND A.InOutDetailKind  = K.MinorSeq      
        AND K.Serl             = '2004'     
               LEFT OUTER JOIN #ESMMatAcc       AS O              ON j.ValueSeq         = O.AccSeq  
                                                                 AND K.ValueSeq         = O.UMCostType  
                                                                 
   WHERE A.CompanySeq  = @CompanySeq           
     AND A.AdjCostKeySeq    = @CostKeySeq  
     --AND A.InOutDate        LIKE @CostYM + '%'     
     --AND A.SMAdjustKind     = 5513005 --자재금액보정_연총평균  
     AND F.MinorValue       = '1'      --자재
     AND F.MinorSeq         <> 6008005       --재공품이 아닌것 
     AND A.InOutKind        = 8023003       --기타출고  
     AND ((@FGoodPriceUnit  = 5502003 AND A.BizUnit   = @CostUnit    )  
       OR (@FGoodPriceUnit  = 5502002 AND A.AccUnit   = @CostUnit    ))  
     AND (@YAVGAdjTransType = 5536001 ) --원천구분별이고 기타보정 계정일 경우 원천별로 보정함
    
    GROUP BY E.AssetSeq         , --재고자산분류          
           A.InOutKind          , --입출고유형      
           ISNULL(j.ValueSeq, 0),      
           ISNULL(K.ValueSeq, 0),    
           L.AccSeq             ,    
           L.UMCostType         ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0) END          ,      
            A.InOutDetailKind,
           CASE WHEN  E.IsFromOtherAcc = '1' AND  O.AccSeq IS NULL	THEN '1'
                ELSE '0'
           END 	          
   ORDER BY A.InOutDetailKind , E.AssetSeq   

   INSERT INTO #TempInOut(      
       SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,      
       DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,      
       DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind,ISSUM)          
   SELECT SMSlipKind   ,INOutDetailKind,Remark      ,A.AssetSeq   , 
          CASE WHEN ISNULL(B.DrAccSeq    ,0) = 0 THEN A.DrAccSeq ELSE B.DrAccSeq END    ,
          CASE WHEN ISNULL(B.DrUMCostType,0) = 0 THEN A.DrUMCostType  ELSE B.DrUMCostType END  ,
          CASE WHEN ISNULL(B.CrAccSeq    ,0) = 0 THEN A.CrAccSeq     ELSE B.CrAccSeq END     ,
          CASE WHEN ISNULL(B.CrUMCostType,0) = 0 THEN A.CrUMCostType  ELSE B.CrUMCostType END  ,
           Amt        , ShowOrder ,      
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind, '1'
     FROM #TempInOut_Garbege AS A 
          LEFT OUTER JOIN #OtherAcc AS B ON A.AssetSeq = B.AssetSeq AND A.IsFromOtherAcc = B.isFromOtherAcc
          
   
   GOTO Proc_Query  
RETURN 
/*****************************************************************************************/
Proc_ItemAfterProd:	--5522015 기타입출고전표_제품(품목별)


    --기타입고    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq, GoodItemSeq   ,CustSeq )    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(L.AccSeq, 0)  , --대변계정    
           L.UMCostType         , --대변비용구분    
           ISNULL(j.ValueSeq, 0), --차변계정    
           ISNULL(K.ValueSeq, 0), --차변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq , 0),
		   A.ItemSeq    ,  
           ISNULL(A.CustSeq     , 0)  
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                        AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq
              JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    -- 계정과목
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '1002'    -- 비용구분
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정    


		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- 기타입고
												      AND M.Serl     = 2009	        -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText = 1
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고 
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND ( E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL )
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           L.AccSeq       , --대변계정    
           L.UMCostType           , --대변비용구분    
           j.ValueSeq            , --차변계정    
           K.ValueSeq            , --차변비용구분  
           A.CCtrSeq			 ,
		   A.DeptSeq   ,
		   A.ItemSeq    ,
           A.CustSeq 

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq, GoodItemSeq,CustSeq )    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(L.AccSeq, 0)  , --대변계정    
           L.UMCostType         , --대변비용구분    
           ISNULL(N.AccSeq, 0), --차변계정    
           ISNULL(N.UMCostType, 0), --차변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq , 0),
		   A.ItemSeq    ,  
           ISNULL(A.CustSeq     , 0)  
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq
               JOIN _TDAUMinor     AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정 
		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                         AND M.MajorSeq = 8025			-- 기타입고
												         AND M.Serl     = 2009	        -- 품목별전표처리여부
													     AND A.InOutDetailKind = M.minorseq 
													     AND M.ValueText = 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                         AND N.AssetAccKindSeq = 21 -- 타계정으로대체  
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsToOtherAcc = '1'
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           L.AccSeq             , --대변계정    
           L.UMCostType         , --대변비용구분    
           N.AccSeq             , --차변계정    
           N.UMCostType         , --차변비용구분  
           A.CCtrSeq			,
		   A.DeptSeq            ,
		   A.ItemSeq            ,
           A.CustSeq
		   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq, GoodItemSeq   ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind          , --입출고유형    
           E.AssetSeq           , --재고자산분류    
           ISNULL(N.AccSeq, 0)  , --대변계정    
           N.UMCostType         , --대변비용구분    
           ISNULL(j.ValueSeq, 0), --차변계정    
           ISNULL(K.ValueSeq, 0), --차변비용구분    
           SUM(A.Amt )          , --기타출고금액    
           1                    , --순서    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq , 0),
		   A.ItemSeq    ,  
           ISNULL(A.CustSeq     , 0)  
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq
              JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --사용여부체 체크된것만 가져와야함. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                       AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    -- 계정과목
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '1002'    -- 비용구분
		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                         AND M.MajorSeq = 8025			-- 기타입고
												         AND M.Serl     = 2009	        -- 품목별전표처리여부
													     AND A.InOutDetailKind = M.minorseq 
													     AND M.ValueText = 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                         AND N.AssetAccKindSeq = 21 -- 타계정으로대체  
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --기타입고 
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
    AND E.IsToOtherAcc = '1'
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind,    
           N.AccSeq       , --대변계정    
           N.UMCostType           , --대변비용구분    
           j.ValueSeq            , --차변계정    
           K.ValueSeq            , --차변비용구분  
           A.CCtrSeq			 ,
		   A.DeptSeq   ,
		   A.ItemSeq  ,
           A.CustSeq   

    --기타출고(제조계정 제외)
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq, GoodItemSeq ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(j.ValueSeq, 0) , --대변계정    
           ISNULL(K.ValueSeq, 0) , --대변비용구분    
           ISNULL(L.AccSeq, 0)   , --차변계정    
           L.UMCostType          , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           5                     , --순서
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0) ,
		   A.ItemSeq           ,  
           ISNULL(A.CustSeq     , 0)       
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                     AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정 

		       JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8026			-- 기타출고
												      AND M.Serl     = 1005		    -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText = 1
     
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --기타출고
     AND F.MinorSeq <> 6008001 
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND (E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL)
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind           , --입출고유형    
           j.ValueSeq          , --대변계정    
           K.ValueSeq          , --대변비용구분    
           L.AccSeq             , --차변계정    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq  ,
		   A.ItemSeq     ,
           A.CustSeq

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq, GoodItemSeq ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(N.AccSeq, 0) , --대변계정    
           ISNULL(N.UMCostType, 0) , --대변비용구분    
           ISNULL(L.AccSeq, 0)   , --차변계정    
           L.UMCostType          , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           5                     , --순서
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0) ,
		   A.ItemSeq     ,  
           ISNULL(A.CustSeq     , 0)             
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --자산처리계정 

		       JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                         AND M.MajorSeq = 8026			-- 기타출고
												         AND M.Serl     = 1005		    -- 품목별전표처리여부
													     AND A.InOutDetailKind = M.minorseq 
													     AND M.ValueText = 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                         AND N.AssetAccKindSeq = 21 -- 타계정으로대체  
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --기타출고
     AND F.MinorSeq <> 6008001 
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1'
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind           , --입출고유형    
           N.AccSeq          , --대변계정    
           N.UMCostType          , --대변비용구분    
           L.AccSeq             , --차변계정    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq  ,
		   A.ItemSeq   ,
           A.CustSeq
		   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq, GoodItemSeq ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --기타출고유형    
           A.InOutKind           , --입출고유형    
           E.AssetSeq            , --재고자산분류    
           ISNULL(j.ValueSeq, 0) , --대변계정    
           ISNULL(K.ValueSeq, 0) , --대변비용구분    
           ISNULL(N.AccSeq, 0)   , --차변계정    
           N.UMCostType          , --차변비용구분    
           SUM(A.Amt )           , --기타출고금액    
           5                     , --순서
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0) ,
		   A.ItemSeq        ,  
           ISNULL(A.CustSeq     , 0)  
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --지우리    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
		       JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8026			-- 기타출고
												      AND M.Serl     = 1005		    -- 품목별전표처리여부
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText = 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq     
                                                         AND N.AssetAccKindSeq = 21 -- 타계정으로대체  
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --기타출고
     AND F.MinorSeq <> 6008001 
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1'
    GROUP BY E.AssetSeq         , --재고자산분류    
           A.InOutDetailKind    , --기타출고유형    
           A.InOutKind           , --입출고유형    
           j.ValueSeq          , --대변계정    
           K.ValueSeq          , --대변비용구분    
           N.AccSeq             , --차변계정    
           N.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq  ,
		   A.ItemSeq  ,
           A.CustSeq  
    GOTO Proc_Query
RETURN 
/******************************************************************************************************/
Proc_Query: --조회

    IF EXISTS (SELECT 1 FROM KPX_TESMCProdSlipM  A   
                WHERE A.CompanySeq     = @CompanySeq    
                  AND A.CostUnit       = @CostUnit    
                  AND A.CostKeySeq     = @CostKeySeq
                  AND A.SMSlipKind     = @SMSlipKind     
                  AND A.SlipSeq        > 0
				)
    BEGIN 
		  
           SELECT  B.TransSeq      ,
                    B.TransSerl     ,
                    B.Remark        ,
                    ISNULL(B.InOutDetailKind   , 0)  AS InOutDetailKind,
--                    ISNULL(I.MinorName , 0) AS InOutDetailKindName,
                     CASE WHEN I.MinorName IS NULL THEN 
                         CASE WHEN L.MinorName IS NULL THEN '' ELSE '※'+L.MinorName END --2011.02.17 지해 :보정데이터 표시 (입출고구분에.)
                         ELSE ISNULL(I.MinorName,'')
                     END AS InOutDetailKindName,
                    B.CCtrSeq       ,
                    ISNULL(H.CCtrName, '')  AS CCtrName    ,
                    B.DeptSeq       ,
                    E.DeptName      ,
                    B.CrAccSeq   ,
                    ISNULL(G.AccName , '') AS CrAccName,
                    B.DrAccSeq     ,
                    ISNULL(D.AccName , '') AS DrAccName  ,
                    B.CrAmt      ,
                    B.DrAmt        ,
                    B.AssetSeq      ,
                    ISNULL(C.AssetName  , '') AS AssetName  ,
                    B.IsVat                     ,
                    B.CrUMCostType              , 
                    B.DrUMCostType              ,
                    ISNULL(J.MinorName , '') AS CrUMCostTypeName,
                    ISNULL(K.MinorName , '') AS DrUMCostTypeName,
                    N.CustSeq           AS CustSeq,
                    N.CustName          AS CustName,
                    B.GoodItemSeq       AS GoodItemSeq,
                    M2.ItemName         AS GoodItemName,
					M.ItemName, M.ItemNo, M.Spec,
					ISNULL(O.MinorName,'')         AS UMRealDetilKindName,
					ISNULL(B.UMRealDetilKind ,0)   AS UMRealDetilKind
             FROM  KPX_TESMCProdSlipM                 AS A WITH(NOLOCK)
                              JOIN KPX_TESMCProdSlipD AS b WITH(NOLOCK) ON a.CompanySeq = b.CompanySeq AND a.TransSeq   = b.TransSeq       
                   LEFT OUTER JOIN _TDAAccount     AS g WITH(NOLOCK) ON b.CrAccSeq   = g.AccSeq     AND a.CompanySeq = G.CompanySeq          
                   LEFT OUTER JOIN _TDAItemAsset   AS c WITH(NOLOCK) ON b.AssetSeq   = c.AssetSeq   AND B.CompanySeq = C.CompanySeq                           
                   LEFT OUTER JOIN _TDAAccount     AS d WITH(NOLOCK) ON b.DrAccSeq   = d.AccSeq     AND a.CompanySeq = D.CompanySeq              
                   LEFT OUTER JOIN _TDADept        AS e WITH(NOLOCK) ON B.DeptSeq    = E.DeptSeq    AND B.CompanySeq = E.CompanySeq            
                   LEFT OUTER JOIN _TDACCtr AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq AND B.CCtrSeq    = H.CCtrSeq
                   LEFT OUTER JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq AND B.InOutDetailKind = I.MInorSeq
                   LEFT OUTER JOIN _TDAUMinor      AS J WITH(NOLOCK) ON B.CompanySeq = J.CompanySeq AND B.CrUMCostType = J.MInorSeq
                   LEFT OUTER JOIN _TDAUMinor      AS K WITH(NOLOCK) ON B.CompanySeq = K.CompanySeq AND B.DrUMCostType = K.MInorSeq

			       LEFT OUTER JOIN _TDAItem        AS M WITH (NOLOCK) ON B.CompanySeq = M.CompanySeq 
																	 AND B.ItemSeq    = M.ItemSeq
                   LEFT OUTER JOIN _TDASMInor   AS L WITH(NOLOCK) ON @CompanySeq    = L.CompanySeq AND B.INOutDetailKind     = L.MinorSeq AND L.MajorSeq IN (5513,5535)
                   LEFT OUTER JOIN _TDACust        AS N WITH(NOLOCK) ON @CompanySeq    = N.CompanySeq AND B.CustSeq         = N.CustSeq  
                   LEFT OUTER JOIN _TDAUMInor   AS O WITH(NOLOCK) ON @CompanySeq    = O.CompanySeq AND B.UMRealDetilKind     = O.MinorSeq 
				   LEFT OUTER JOIN _TDAItem		AS M2 WITH(NOLOCK) ON B.CompanySeq = M2.CompanySeq AND B.GoodItemSeq = M2.ItemSeq

                   
           WHERE A.CompanySeq     = @CompanySeq    
              AND A.CostUnit       = @CostUnit    
              AND A.CostKeySeq     = @CostKeySeq
              AND A.SMSlipKind     = @SMSlipKind 
             ORDER BY B.TransSerl



    END 
    ELSE 
    BEGIN 



    --기타입출고전표처리시집계구분선택(부서/거래처)
    DECLARE	@EtcGroupType  INT 

    EXEC dbo._SCOMEnv @CompanySeq, 5910,@UserSeq,@@PROCID,@EtcGroupType OUTPUT   --자재단가계산단위 


    IF @SMSlipKind NOT IN (5522012,5522013,5522014) --연총평균 보정전표가 아닐때 
    BEGIN 
	  
      IF @EtcGroupType =  5544001 --부서로 집계
		
        INSERT INTO #TempInOut(    
               SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
               DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
               DeptSeq      ,CCtrSeq, GoodItemSeq ,CustSeq,IsSum , UMRealDetilKind)    
        SELECT  SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
               DrUMCostType,CrAccSeq    ,CrUMCostType,SUM(Amt)        , ShowOrder ,    
               DeptSeq      ,CCtrSeq, GoodItemSeq ,0,'1',UMRealDetilKind
          FROM #TempInOut
        GROUP BY SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
               DrUMCostType,CrAccSeq    ,CrUMCostType,ShowOrder ,    
               DeptSeq      ,CCtrSeq, GoodItemSeq,UMRealDetilKind


      ELSE  --거래처로 집계
        INSERT INTO #TempInOut(    
               SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
               DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
               DeptSeq      ,CCtrSeq, GoodItemSeq ,CustSeq,IsSum,UMRealDetilKind)    
        SELECT  SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
               DrUMCostType,CrAccSeq    ,CrUMCostType,SUM(Amt)        , ShowOrder ,    
               0      ,CCtrSeq, GoodItemSeq, CustSeq,'1',UMRealDetilKind
          FROM #TempInOut
        GROUP BY SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
               DrUMCostType,CrAccSeq    ,CrUMCostType,ShowOrder ,    
               CCtrSeq, CustSeq, GoodItemSeq,UMRealDetilKind


        DELETE #TempInOut WHERE IsSum IS NULL 
    END 
			

            SELECT  A.SMSlipKind        AS SMSlipKind,    
                    A.InOutDetailKind   AS InOutDetailKind, 
--           CASE WHEN A.InOutDetailKind = 5535002 THEN '투입금액보정'
--                WHEN A.InOutDetailKind = 5535001 THEN '매출원가보정'  
--                WHEN A.InOutDetailKind = 5535003 THEN '기타출고보정'  
--                ELSE  B.MinorName        END  AS InOutDetailKindName ,    
                     CASE WHEN B.MinorName IS NULL THEN 
                         CASE WHEN M.MinorName IS NULL THEN '' ELSE '※'+M.MinorName END --2011.02.17 지해 :보정데이터 표시 (입출고구분에.)
              ELSE ISNULL(B.MinorName,'')
                     END AS InOutDetailKindName,
                    A.AssetSeq          AS AssetSeq,    
                    F.AssetName         AS AssetName ,    
                    A.DrAccSeq          AS DrAccSeq,    
                    D.AccName           AS DrAccName,    
                    A.DrUMCostType      AS DrUMCostType,    
                    E.MinorName         AS DrUMCostTypeName,     
                    A.CrAccSeq          AS CrAccSeq ,    
                    G.AccName           AS CrAccName  ,    
                    A.CrUMCostType      AS CrUMCostType,    
                    H.MinorName         AS CrUMCostTypeName ,    
                    A.Amt               AS DrAmt      ,     
                    A.Amt               AS CrAmt      ,     
                    A.ShowOrder         AS ShowOrder,    
                    CASE WHEN ISNULL(A.DeptSeq,0) = 0 THEN 8  ELSE A.DeptSeq END   AS DeptSeq      ,    
                    CASE WHEN ISNULL(A.CCtrSeq,0) = 0 THEN 22 ELSE A.CCtrSeq END   AS CCtrSeq,    
                    C.MinorName         AS Remark,    
                    I.DeptName          AS DeptName,    
                    J.CCtrName          AS CCtrName,
                    A.CustSeq           AS CustSeq,
                    K.CustName          AS CustName,
                    A.GoodItemSeq       AS GoodItemSeq,
                    L.ItemName          AS GoodItemName,
			        L.ItemNO			AS GoodItemNo,
					L.Spec				AS Spec,
					ISNULL(N.MinorName,'')         AS UMRealDetilKindName,
					ISNULL(A.UMRealDetilKind ,0)   AS UMRealDetilKind
              FROM #TempInOut AS A     
                   LEFT OUTER JOIN _TDAUMinor   AS B WITH(NOLOCK) ON @CompanySeq    = B.CompanySeq AND A.INOutDetailKind = B.MinorSeq 
                   LEFT OUTER JOIN _TDASMInor   AS C WITH(NOLOCK) ON @CompanySeq    = C.CompanySeq AND A.Remark          = C.MinorSeq    
                   LEFT OUTER JOIN _TDAAccount  AS D WITH(NOLOCK) ON @CompanySeq    = D.CompanySeq AND A.DrAccSeq        = D.AccSeq    
                   LEFT OUTER JOIN _TDAUMinor   AS E WITH(NOLOCK) ON @CompanySeq    = E.CompanySeq AND A.DrUMCostType    = E.MInorSeq    
                   LEFT OUTER JOIN _TDAItemAsset AS F WITH(NOLOCK) ON @CompanySeq   = F.CompanySeq AND A.AssetSeq        = F.AssetSeq    
                   LEFT OUTER JOIN _TDAAccount  AS G WITH(NOLOCK) ON @CompanySeq    = G.CompanySeq AND A.CrAccSeq        = G.AccSeq    
                   LEFT OUTER JOIN _TDAUMinor   AS H WITH(NOLOCK) ON @CompanySeq    = H.CompanySeq AND A.CrUMCostType    = H.MinorSeq    
                   LEFT OUTER JOIN _TDADept     AS I WITH(NOLOCK) ON @CompanySeq    = I.CompanySeq AND CASE WHEN ISNULL(A.DeptSeq,0) = 0 THEN 8  ELSE A.DeptSeq END        = I.DeptSeq    
                   LEFT OUTER JOIN _TDACCtr     AS J WITH(NOLOCK) ON @CompanySeq    = J.CompanySeq AND CASE WHEN ISNULL(A.CCtrSeq,0) = 0 THEN 22 ELSE A.CCtrSeq END        = J.CCtrSeq  
                   LEFT OUTER JOIN _TDACust     AS K WITH(NOLOCK) ON @CompanySeq    = K.CompanySeq AND A.CustSeq         = K.CustSeq  
                   LEFT OUTER JOIN _TDAItem     AS L WITH(NOLOCK) ON @CompanySeq    = L.CompanySeq AND A.GoodItemSeq     = L.ItemSeq 
                   LEFT OUTER JOIN _TDASMInor   AS M WITH(NOLOCK) ON @CompanySeq    = M.CompanySeq AND A.INOutDetailKind     = M.MinorSeq AND M.MajorSeq IN (5513,5535)
                   LEFT OUTER JOIN _TDAUMInor   AS N WITH(NOLOCK) ON @CompanySeq    = N.CompanySeq AND A.UMRealDetilKind     = N.MinorSeq 
			
            ORDER BY A.ShowOrder , InOutDetailKindName , A.AssetSeq  


    END 

  
RETURN


GO


