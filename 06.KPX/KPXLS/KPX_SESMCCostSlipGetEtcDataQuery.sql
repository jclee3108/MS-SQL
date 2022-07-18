IF OBJECT_ID('KPX_SESMCCostSlipGetEtcDataQuery') IS NOT NULL 
    DROP PROC KPX_SESMCCostSlipGetEtcDataQuery
GO 

-- v2015.12.21 

-- ������ �ϵ��ڵ� -> �߰��������������� ���� by����õ 
/************************************************************    
 ��  �� - D-���������ǥó�� : ��Ÿ���ⵥ���Ͱ�������    
 �ۼ��� - 20090413    
 �ۼ��� - ������    
 ����   - ������ ��Ÿ���, ��Ÿ�԰�� ������ ��ǥó���� �ϴ� sp�� (����,��ǰ,��ǰ)
          ��ǰ�� ��� ����������� �İ� �ִµ� ���� ��������������� ���� ǰ���� ó���ϰ�
          �Ĵ� ��ǰ�� ��Ÿ�԰� ������������� �ƴ� ��Ÿ����, 
               ��������������� ������� �Ͱ� ������� ���̰� ������ ���� ��� ����ó�� �Ǵ� �κ��� ������ �ȴ�.
 �߰����� - ��Ÿ�԰���, ��Ÿ������� ����.��뱸���� �����.
            ��Ÿ�԰���(1001	��������,1002	��뱸��)
            ��Ÿ�����(2003	��������,2004	��뱸��)
������ - 2011.06.30 ���� 1) ��Ÿ����� ��ǥó������ �μ��� ���� �ŷ�ó�� ���� �����ϵ��� �ɼ� �߰� 
                            => ����������Ŀ� ����� ��� _TESMGINOutstock��  custseq�� ��Ÿ��� ���� �����͵� ���� �����ϵ��� ����ó����.
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
             
    -- ���� ����Ÿ ��� ����              
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

    --����ǰ ������� ó�� �ɼ�
    DECLARE @BanToProc INT 
    EXEC dbo._SCOMEnv @CompanySeq,5547,0  /*@UserSeq*/,@@PROCID,@BanToProc OUTPUT
    
    
    DECLARE @FSDomainSeq INT           
    --SELECT @FSDomainSeq = 11  --���ĺ����ؾ���.   
    
 ----��ǰ�ܰ���꿡 ���� Subȣ���� �������, ���Լ���, ����������� ����� ó���ؾ��Ѵ�.     
    
      
   IF @SMCostMng IN (5512001 , 5512004 )     --5512001/����ȸ��          , 5512004/�⺻����                 
      SELECT @FSDomainSeq =  FSDomainSeq FROM _TCOMFSDomain WITH(NOLOCK) WHERE CompanySeq =@CompanySeq AND FSDomainNo = 'GAAPFS'           
   ELSE IF @SMCostMng IN (5512005 , 5512006) --5512005/IFRS(����ȸ��)    , 5512006/IFRS(�⺻����)           
      SELECT @FSDomainSeq =  FSDomainSeq FROM _TCOMFSDomain WITH(NOLOCK) WHERE CompanySeq =@CompanySeq AND FSDomainNo = 'IFRSFS'           
   ELSE IF @SMCostMng IN (5512007 , 5512008) --5512007/������(����ȸ��) , 5512008/������(�⺻����)     
    BEGIN       
       SELECT @FSDomainSeq = FSDomainSeq FROM _TCRRptUnit WITH(NOLOCK) WHERE RptUnit = @RptUnit AND CompanySeq = @CompanySeq       
    END        
          



--    1)���ó���� ��������    
--    �̹� ��ǥ ó���� ������ ���� ������ �ҷ��� �����ֱ�
 

    IF EXISTS (SELECT 1 FROM KPX_TESMCProdSlipM A 
                WHERE A.CompanySeq     = @CompanySeq    
                  AND A.CostUnit       = @CostUnit    
                  AND A.CostKeySeq     = @CostKeySeq
                  AND A.SMSlipKind     = @SMSlipKind     
                  AND A.SlipSeq        > 0)
    BEGIN
        
--        -------------------------------------------  
--        -- ��ǥó�� ���� 
--        -------------------------------------------  
--        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
--                              @Status      OUTPUT,  
--                              @Results     OUTPUT,  
--                              15                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE languageseq = 1 and messageDefault like '%��ǥ%' MessageSeq = 6)  
--                              @LanguageSeq       ,   
--                              0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%����%'  
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

    --ó�� ������ ���� ����Ʋ
    CREATE TABLE #TempInOut    
    (    
        SMSlipKind         INT ,     --��ǥ����    
        INOutDetailKind    INT ,     --�������    
        Remark             NVARCHAR(100),     
        AssetSeq           INT ,     -- ����ڻ�з�    
        DrAccSeq           INT ,     -- �����ڵ�    
        DrUMCostType       INT ,                
        CrAccSeq           INT ,     -- ����ڻ�����ڵ�    
        CrUMCostType       INT ,    
        Amt                DECIMAL(19,5),  -- �ݾ�    
        ShowOrder          INT ,     
        DeptSeq            INT ,    
        CCtrSeq            INT ,
        CustSeq            INT ,     --����ŷ�ó/��Ÿ��� �ŷ�ó.
        GoodItemSeq        INT ,      --������ǰ
        ISSum              INT NULL , --2011.06.30 �ŷ�ó, �μ��� ���踦 ���Ͽ� �߰�
        UMRealDetilKind    INT NULL  --2011.09.02 ��Ÿ����� ���к� ���踦 ���Ͽ� �߰�
            )    
            
--###############������տ� ���� #################################################################--
            
      --ó�� ������ ���� ������(Ÿ������ ���� �ӽ����� ���̺�)
    CREATE TABLE #TempInOut_Garbege    
    (    
        SMSlipKind         INT ,     --��ǥ����    
        INOutDetailKind    INT ,     --�������    
        Remark             NVARCHAR(100),     
        AssetSeq           INT ,     -- ����ڻ�з�    
        DrAccSeq           INT ,     -- �����ڵ�    
        DrUMCostType       INT ,                
        CrAccSeq           INT ,     -- ����ڻ�����ڵ�    
        CrUMCostType       INT ,    
        Amt                DECIMAL(19,5),  -- �ݾ�    
        ShowOrder          INT ,     
        DeptSeq            INT ,    
        CCtrSeq            INT ,
        CustSeq            INT ,     --����ŷ�ó/��Ÿ��� �ŷ�ó.
        GoodItemSeq        INT ,      --������ǰ
        UMRealDetilKind    INT NULL,  --2011.09.02 ��Ÿ����� ���к� ���踦 ���Ͽ� �߰�
        IsFromOtherAcc     NCHAR(1) NULL
            )   
            
    --Ÿ�������� ��ü�� ����
    CREATE TABLE #OtherAcc(
        AssetSeq   INT,
        IsFromOtherAcc NCHAR(1),
        DrAccSeq     INT,
DrUMCostType INT,
        CrAccSeq     INT,
        CrUMCostType INT,
        DrOrCr       int)
    
    INSERT INTO #OtherAcc --���� Ÿ�������� 
    SELECT A.AssetSeq,A.IsFromOtherAcc, B.AccSeq,  B.UMCostType,0,0,-1
     FROM _TDAItemAsset AS A 
         JOIN _TDAItemAssetAcc AS B ON A.CompanySeq = B.CompanySeq
                                   AND A.AssetSEq   = B.AssetSeq
    WHERE A.Companyseq = @CompanySeq       
      AND AssetAccKindSeq = 21 --Ÿ�������� 
      AND A.IsFromOtherAcc = '1'
      
    INSERT INTO #OtherAcc  --�뺯 Ÿ�������� 
    SELECT AssetSeq,IsFromOtherAcc,0,0,DrAccSeq,DrUMCostType,1
      FROM #OtherAcc
      

      
     INSERT INTO #AssetSeq  
     SELECT  E.AssetSeq   
      FROM  _TDAItemAsset  AS E WITH(NOLOCK)  
                    JOIN _TDAItemAssetAcc    AS N WITH(NOLOCK) ON E.CompanySeq       = N.CompanySeq      
                                                             AND E.AssetSeq         = N.AssetSeq       
                                                             AND  N.AssetAccKindSeq  = 23 --���⺸������  
                    JOIN _TDAItemAssetAcc    AS O WITH(NOLOCK) ON E.CompanySeq       = O.CompanySeq      
                                                             AND E.AssetSeq         = O.AssetSeq       
                                                             AND  O.AssetAccKindSeq  = 24 --��Ÿ��������  
                    JOIN _TDAItemAssetAcc    AS M WITH(NOLOCK) ON E.CompanySeq       = M.CompanySeq      
                                                             AND E.AssetSeq         = M.AssetSeq      
                                                             AND M.AssetAccKindSeq  = 6 --�����������   
       WHERE E.CompanySeq = @CompanySeq            
        AND ( @BanToProc <> '1' OR (@BanToProc = '1' AND E.SMAssetGrp <> 6008004)) --����ǰ ������� �ɼ� ���� Ÿ���� ����
    --5555:������պ�����ǥ �������/��Ÿ��� ������ Ȱ�����ͺ� ǰ�� ���迩�� 
    --������պ�����ǥ �������/��Ÿ��� ������ Ȱ�����ͺ� ǰ�� �����Ͽ� ������ȸ�� ��.
    EXEC dbo._SCOMEnv @CompanySeq,5555 ,0  /*@UserSeq*/,@@PROCID,@IsDivideCCtrItem OUTPUT    
    
    --5551:������� ���ݾ� ���� ����
    --������ս� ���ݾ��� ������ �߻��ϸ� ��������� �����մϴ�.(��õ�����ͺ�����/����к� ����)
    EXEC dbo._SCOMEnv @CompanySeq,5551 ,0  /*@UserSeq*/,@@PROCID,@YAVGAdjTransType OUTPUT    
     --@YAVGAdjTransType
     ----��õ�����ͺ� ����	    5536001
     ----����к� ����		5536002


      
--###############������տ� �� #################################################################--
DECLARE	@ItemPriceUnit  INT ,
        @GoodPriceUnit  INT ,
        @FGoodPriceUnit INT 

    EXEC dbo._SCOMEnv @CompanySeq, 5521,@UserSeq,@@PROCID,@ItemPriceUnit OUTPUT   --����ܰ������� 

    EXEC dbo._SCOMEnv @CompanySeq, 5522,@UserSeq,@@PROCID,@GoodPriceUnit OUTPUT   --��ǰ�ܰ������� 

    EXEC dbo._SCOMEnv @CompanySeq, 5523,@UserSeq,@@PROCID,@FGoodPriceUnit OUTPUT  --��ǰ�ܰ������� 

--5535001 5535 ������� �����������  
--5535002 5535 ������� ���Աݾ�����  
--5535003 5535 ������� ��Ÿ���ݾ� ����  
  
    EXEC dbo._SCOMEnv @CompanySeq,5555 ,0  /*@UserSeq*/,@@PROCID,@IsDivideCCtrItem OUTPUT    
    

---------------��ǰ�ϰ�� ����ϴ� �׸�-----------------------------------------------------
--    IF @SMSlipKind IN (5522007,5522006,5522012)
--    BEGIN
		--��밡���� ����������������    
		--����,�빫��,���    
		CREATE TABLE  #ESMAccount ( SMCostKind INT ,SMCostDiv INT , CostAccSeq INT , AccSeq INT  , BgtSeq INT , UMCostType INT )      

        EXEC _SESMBAccountScopeQuery @CompanySeq , @FSDomainSeq , 5507001 ,  0        
           
        CREATE TABLE #ESMProdAcc( AccSeq INT ,UMCostType INT)
    
        CREATE TABLE #ESMMatAcc( AccSeq INT ,UMCostType INT)

		INSERT INTO #ESMProdAcc
		SELECT DISTINCT ACCSEQ ,UMCostType FROM #ESMAccount WHERE SMCostDiv = 5507001   --������������ Ȯ���ϴµ� ����.
    
		INSERT INTO #ESMMatAcc
		SELECT DISTINCT ACCSEQ ,UMCostType FROM #ESMAccount WHERE SMCostKind = 5519001   --���� ���� Ȯ�ο� ���

   
--    END


	IF @SMSlipKind = 5522007        --5522007 ��Ÿ�������ǥ_��ǰ���������    
		GOTO PROC_PreProd
	ELSE IF @SMSlipKind = 5522006   --5522006  ��Ÿ�������ǥ_��ǰ    
		GOTO PROC_AfterProd
	ELSE IF @SMSlipKind = 5522005   --5522005  ��Ÿ�������ǥ_��ǰ    
		GOTO PROC_Goods
	ELSE IF @SMSlipKind = 5522004   --5522004  ��Ÿ�������ǥ_����    
		GOTO Proc_Mat
	ELSE IF @SMSlipKind = 5522012   --5522012  ������� ������ǥ_��ǰ   
		GOTO AVG_Prod
	ELSE IF @SMSlipKind = 5522014   --5522014  ������� ������ǥ_��ǰ    
		GOTO AVG_Goods
	ELSE IF @SMSlipKind = 5522013   --5522013  ������� ������ǥ_����    
		GOTO AVG_Mat
	ELSE IF @SMSlipKind = 5522015	--5522015 ��Ÿ�������ǥ_��ǰ(ǰ��)
		GOTO Proc_ItemAfterProd
	ELSE 
		GOTO Proc_Query
	RETURN 

/*****************************************************************************************/
PROC_PreProd:  --5522007 ��Ÿ�������ǥ_��ǰ���������    

    --2) �ȯ������� ��������    
    DECLARE @SMGoodSetPrice    INT        
    -- ��ǰ��Ÿ���� ����ܰ�    
    EXEC dbo._SCOMEnv @CompanySeq, 5539,@UserSeq,@@PROCID,@SMGoodSetPrice OUTPUT    
    --5523001  ���� ���ܰ�    
    --5523002  ǥ�� ���ܰ�    
    --5523003  ǥ�ؿ���    
   
    CREATE TABLE #GoodPrice    
    (ItemSeq    INT,    
     StkPrice   DECIMAL(19,5))    
    

 
    IF @SMGoodSetPrice = 5523001 --�������ܰ�    
    BEGIN    
       -- ���� Ű�� ������ �´�.    

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
        
        --���� ���ܰ��� �ݾ��� ������ �´�.     
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
           AND F.MinorValue = '0'    --��ǰ/��ǰ    
           AND A.InOutDate  LIKE @CostYM + '%'    
           AND A.InOutKind  = 8023003
           AND ( (@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
              OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ) )

           AND F.MinorSeq <> 6008001 -- ��ǰ����    
           --��Ÿ��� ������ ������ ���� ���� ������Ű��.    
    
    
		-- ���� ���ܰ��� ���� ��� ǥ�����ܰ��� ����Ѵ�.     
		UPDATE #GoodPrice    
		   SET StkPrice = ISNULL(B.Price,0)    
		  FROM  #GoodPrice AS A     
		  JOIN _TESMBItemStdPrice AS B ON B.CompanySeq = @CompanySeq
									  AND A.ItemSeq    = B.ItemSeq 
          LEFT OUTER JOIN _TESMCProdStkPrice AS C WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq    --2011.02.01  ����: �������ܰ����°�� �߰�.��,.��
                                                              AND B.ItemSeq    = C.ItemSeq    
                                                              AND B.CostUnit   = C.CostUnit     
                                                              AND C.CostKeySeq = @PreCostKeySeq   
		 WHERE B.CostUnit = @CostUnit    
           AND C.Price IS NULL 
	     

		--���ݾ� Update     
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
														   AND J.Serl        = '2003'      -- �������� 
		  LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq  = K.CompanySeq    
														   AND A.InOutDetailKind = K.MinorSeq    
														   AND K.Serl            = '2004'      -- ��뱸��  
					 JOIN #ESMProdAcc     AS Z              ON J.ValueSeq        = Z.AccSeq    
                                                           AND K.ValueSeq        = Z.UMCostType                                                         
		 WHERE A.CompanySeq = @CompanySeq    
		   AND A.CostKeySeq = @CostKeySeq
		   AND F.MinorValue  = '0'    
		   AND F.MinorSeq <> 6008001 -- ��ǰ����    
		   AND A.InOutDate LIKE @CostYM + '%'    
		   AND A.InOutKind = 8023003
		   AND ( (@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
			  OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ) )
--		   AND C.StkPrice <> 0     --�̷��� �صθ� �����̳� ǥ�����ܰ����� ���������� 0���� �Ǿ�� �ϴµ� ������Ʈ�ȵǰ� �״�� ���Ե�. 
 

	 
	END    
    ELSE IF  @SMGoodSetPrice = 5523002 --ǥ�����ܰ�    
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
                                                              AND J.Serl             = '2003'     -- ��������    
          LEFT OUTER JOIN _TDAUMinorValue    AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                              AND A.InOutDetailKind  = K.MinorSeq    
                                                              AND K.Serl             = '2004'     -- ��뱸��    
                   JOIN #ESMProdAcc          AS Z              ON J.ValueSeq = Z.AccSeq               
                                                              AND K.ValueSeq        = Z.UMCostType
         WHERE A.CompanySeq = @CompanySeq 
           AND A.CostKeySeq = @CostKeySeq   
           AND F.MinorValue  = '0'    
           AND F.MinorSeq <> 6008001 -- ��ǰ����    
           AND A.InOutDate LIKE @CostYM + '%'    
           AND A.InOutKind = 8023003 
           AND ( (@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
              OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ) )
--		   AND C.Price <> 0     
 

 

    END    
    ELSE --ǥ�ؿ���    
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
                                                             AND J.Serl             = '2003'   -- ��������      
           LEFT OUTER JOIN _TDAUMinorValue  AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                             AND A.InOutDetailKind  = K.MinorSeq    
                                                             AND K.Serl             = '2004'   -- ��뱸��    
                   JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq                 
                                                             AND K.ValueSeq        = Z.UMCostType
            WHERE A.CompanySeq = @CompanySeq 
              AND A.CostKeySeq = @CostKeySeq    
              AND F.MinorValue  = '0'    
              AND F.MinorSeq <> 6008001 -- ��ǰ����    
              AND A.InOutDate LIKE @CostYM + '%'    
              AND A.InOutKind = 8023003     
              AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
                   OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
--              AND C.CostStdPrice <> 0     
    END    
    
    --�ڻ����/��Ÿ�����ó������    
    --��ǰ    

    --��Ÿ�԰�     
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(L.AccSeq, 0)  , --�뺯����    
           L.UMCostType         , --�뺯��뱸��    
           ISNULL(j.ValueSeq, 0), --��������    
           ISNULL(K.ValueSeq, 0), --������뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq   
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --�������� ������� �׸� 
                                                         AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq 
     AND A.CostKeySeq = @CostKeySeq    
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰� 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp <>  6008004 --����ǰ 
    AND ( E.IsToOtherAcc = '0' OR E.IsToOtherAcc IS NULL)  
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           L.AccSeq             , --�뺯����    
           L.UMCostType           , --�뺯��뱸��    
           j.ValueSeq            , --��������    
           K.ValueSeq            , --������뱸��  
           A.CCtrSeq			 ,
		   A.DeptSeq  ,
           A.CustSeq
                 

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark     , AssetSeq  , DrAccSeq,    
           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq        ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(L.AccSeq, 0)  , --�뺯����    
           L.UMCostType         , --�뺯��뱸��    
           ISNULL(N.AccSeq, 0), --��������    
 ISNULL(N.UMCostType, 0), --������뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq   
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Ÿ�������� ��ü  
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq= Z.AccSeq          --�������� ������� �׸� 
                                                         AND K.ValueSeq         = Z.UMCostType

   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰� 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp <>  6008004 --����ǰ 
     AND E.IsToOtherAcc = '1'
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           L.AccSeq       , --�뺯����    
           L.UMCostType           , --�뺯��뱸��    
           N.AccSeq            , --��������    
           N.UMCostType            , --������뱸��  
           A.CCtrSeq			 ,
		   A.DeptSeq   ,
           A.CustSeq 
		   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(N.AccSeq, 0)  , --�뺯����    
           N.UMCostType         , --�뺯��뱸��    
           ISNULL(j.ValueSeq, 0), --��������    
           ISNULL(K.ValueSeq, 0), --������뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq   
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'     

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Ÿ�������� ��ü  
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --�������� ������� �׸� 
                                                         AND K.ValueSeq        = Z.UMCostType

   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰� 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp <>  6008004 --����ǰ 
     AND E.IsToOtherAcc = '1'
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           N.AccSeq       , --�뺯����    
           N.UMCostType           , --�뺯��뱸��    
           j.ValueSeq            , --��������    
           K.ValueSeq            , --������뱸��  
           A.CCtrSeq			 ,
		   A.DeptSeq      ,
           A.CustSeq         
 

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(j.ValueSeq, 0) , --�뺯����    
           ISNULL(K.ValueSeq, 0) , --�뺯��뱸��    
           ISNULL(L.AccSeq  , 0) , --��������    
           L.UMCostType          , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           5                     , --����    
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'        -- ��������      
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'        -- ��뱸��    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������ 
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --�������� ������� �׸� 
                                                         AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --��Ÿ���
     AND F.MinorSeq <> 6008001 
--     AND A.CostUnit  = @CostUnit
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND (E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL)
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind           , --���������    
           j.ValueSeq          , --�뺯����    
           K.ValueSeq          , --�뺯��뱸��    
           L.AccSeq             , --��������    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq            ,
           A.CustSeq
    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt       , ShowOrder ,    
           DeptSeq      ,CCtrSeq , CustSeq )    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(N.AccSeq, 0) , --�뺯����    
           ISNULL(N.UMCostType, 0) , --�뺯��뱸��    
           ISNULL(L.AccSeq  , 0) , --��������    
           L.UMCostType          , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           5                     , --����    
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
--                                                      AND M.Serl        = '2003'    --�ΰ����Ű�������?? �ʿ����� �˾ƿ���    
--              LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                  ON C.DeptSeq    = P.DeptSeq      
--                                                 AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'        -- ��������      
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'        -- ��뱸��    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������ 
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --�������� ������� �׸� 
                                                         AND K.ValueSeq        = Z.UMCostType
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                         AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  
   WHERE A.CompanySeq = @CompanySeq 
     AND A.CostKeySeq = @CostKeySeq    
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --��Ÿ���
     AND F.MinorSeq <> 6008001 
--     AND A.CostUnit  = @CostUnit
 AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1'
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind           , --���������    
           N.AccSeq          , --�뺯����    
           N.UMCostType          , --�뺯��뱸��    
           L.AccSeq             , --��������    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq          ,
           A.CustSeq        
    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(j.ValueSeq, 0) , --�뺯����    
           ISNULL(K.ValueSeq, 0) , --�뺯��뱸��    
           ISNULL(N.AccSeq, 0) , --�뺯����    
           ISNULL(N.UMCostType, 0) , --�뺯��뱸��     
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           5                     , --����    
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
--                                                      AND M.Serl        = '2003'    --�ΰ����Ű�������?? �ʿ����� �˾ƿ���    
--              LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                  ON C.DeptSeq    = P.DeptSeq      
--                                                 AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'        -- ��������      
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'        -- ��뱸��    
               --LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
               --                                          AND E.AssetSeq         = L.AssetSeq    
               --                                AND L.AssetAccKindSeq  = 1 --�ڻ�ó������ 
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --�������� ������� �׸� 
                                                         AND K.ValueSeq        = Z.UMCostType
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                         AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  
   WHERE A.CompanySeq = @CompanySeq 
     AND A.CostKeySeq = @CostKeySeq    
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --��Ÿ���
     AND F.MinorSeq <> 6008001 
--     AND A.CostUnit  = @CostUnit
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1'
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind           , --���������    
           j.ValueSeq          , --�뺯����    
           K.ValueSeq          , --�뺯��뱸��    
           N.AccSeq          , --�뺯����    
           N.UMCostType          , --�뺯��뱸��   
           A.DeptSeq            ,    
           A.CCtrSeq        ,
           A.CustSeq

    IF @BanToProc = 1  --����ǰ ������� ó��
    BEGIN

    --��Ÿ�԰�  ( Ÿ�������� ��ü /  ������ ) 
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq ,CustSeq )    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(N.AccSeq, 0)  , --��������    
           ISNULL(N.UMCostType,0), --������뱸��    
           ISNULL(j.ValueSeq, 0), --�뺯����    
           ISNULL(K.ValueSeq, 0), --�뺯��뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Ÿ�������� ��ü  
		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --�������� ������� �׸� 
                                                         AND K.ValueSeq        = Z.UMCostType

  
--���ǰ-������� Ÿ�������δ�ü
--Ÿ�������� ���� : 17
--Ÿ�������� ���� : 21  

   WHERE A.CompanySeq = @CompanySeq    
     AND A.CostKeySeq = @CostKeySeq 
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰� 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp  = 6008004 --����ǰ 
  
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           N.AccSeq       , --�뺯����    
           N.UMCostType           , --�뺯��뱸��    
           j.ValueSeq            , --��������    
           K.ValueSeq            , --������뱸��  
           A.CCtrSeq			 ,
		   A.DeptSeq        ,
           A.CustSeq        


    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(L.AccSeq, 0)  , --�뺯����    
           L.UMCostType         , --�뺯��뱸��    
           ISNULL(N.AccSeq, 0)  , --��������    
           ISNULL(N.UMCostType, 0), --������뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
       AND K.Serl             = '1002'    

               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������    

               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Ÿ�������δ�ü  
		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq  = Z.AccSeq          --�������� ������� �׸� 
                                    AND K.ValueSeq         = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰� 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp = 6008004 --����ǰ 
  
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           L.AccSeq       , --�뺯����    
           L.UMCostType           , --�뺯��뱸��    
           N.AccSeq           , --��������    
           N.UMCostType            , --������뱸��  
           A.CCtrSeq			 ,
		   A.DeptSeq        ,
           A.CustSeq     

 
END
   ELSE --����ǰ�� ������� ó������ ������ 
   BEGIN 

    --��Ÿ�԰�    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq , CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(L.AccSeq, 0)  , --�뺯����    
           L.UMCostType         , --�뺯��뱸��    
           ISNULL(j.ValueSeq, 0), --��������    
           ISNULL(K.ValueSeq, 0), --������뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                               AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --�������� ������� �׸� 
                                                         AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰�
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.SMAssetGrp = 6008004 --����ǰ 
    AND ( E.IsToOtherAcc = '0' OR E.IsToOtherAcc IS NULL)  
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           L.AccSeq       , --�뺯����    
           L.UMCostType           , --�뺯��뱸��    
           j.ValueSeq            , --��������    
           K.ValueSeq            , --������뱸��  
           A.CCtrSeq			 ,
		   A.DeptSeq  ,
           A.CustSeq          

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(L.AccSeq, 0)  , --�뺯����    
           L.UMCostType         , --�뺯��뱸��    
           ISNULL(N.AccSeq, 0), --��������    
           ISNULL(N.UMCostType, 0), --������뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                      AND N.AssetAccKindSeq = 17 -- Ÿ�������� ��ü  
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq  = Z.AccSeq          --�������� ������� �׸� 
                                                         AND K.Valueseq   = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰�
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.SMAssetGrp = 6008004 --����ǰ 
     AND E.IsToOtherAcc = '1'
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           L.AccSeq       , --�뺯����    
           L.UMCostType           , --�뺯��뱸��    
           N.AccSeq            , --��������    
           N.UMCostType            , --������뱸��  
           A.CCtrSeq			 ,
		   A.DeptSeq    ,
           A.CustSeq
		   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(N.AccSeq, 0)  , --�뺯����    
           N.UMCostType         , --�뺯��뱸��    
           ISNULL(j.ValueSeq, 0), --��������    
           ISNULL(K.ValueSeq, 0), --������뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                        AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												        AND M.Serl     = 2009	        -- ǰ����ǥó������
													    AND A.InOutDetailKind = M.minorseq 
													    AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                        AND N.AssetAccKindSeq = 17 -- Ÿ�������� ��ü 
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq  = Z.AccSeq          --�������� ������� �׸� 
                                                         AND K.Valueseq   = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰�
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.SMAssetGrp = 6008004 --����ǰ 
     AND E.IsToOtherAcc = '1'
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           N.AccSeq       , --�뺯����    
           N.UMCostType           , --�뺯��뱸��    
           j.ValueSeq            , --��������    
           K.ValueSeq            , --������뱸��  
           A.CCtrSeq			 ,
		   A.DeptSeq ,
           A.CustSeq   
		   
END
         
    GOTO Proc_Query

 

RETURN 
/**************************************************************************************************************/
PROC_AfterProd: --������� ��

   

    ---��ǰ�� ��Ÿ�԰�, ��Ÿ��� 

    --��Ÿ�԰�     
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq )    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(L.AccSeq, 0)  , --�뺯����    
           L.UMCostType         , --�뺯��뱸��    
           ISNULL(j.ValueSeq, 0), --��������    
           ISNULL(K.ValueSeq, 0), --������뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq   
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
                LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --�������� ������� �׸� 
                                                         AND K.ValueSeq        = Z.UMCostType

   WHERE A.CompanySeq = @CompanySeq 
     AND A.CostKeySeq = @CostKeySeq    
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰� 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp <>  6008004 --����ǰ 
    AND ( E.IsToOtherAcc = '0' OR E.IsToOtherAcc IS NULL) 
    AND Z.AccSeq IS NULL 
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           L.AccSeq       , --�뺯����    
           L.UMCostType           , --�뺯��뱸��    
           j.ValueSeq            , --��������    
           K.ValueSeq            , --������뱸��  
           A.CCtrSeq			 ,
		   A.DeptSeq  ,
           A.CustSeq       

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(L.AccSeq, 0)  , --�뺯����    
           L.UMCostType         , --�뺯��뱸��    
           ISNULL(N.AccSeq, 0), --��������    
           ISNULL(N.UMCostType, 0), --������뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq   
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Ÿ�������� ��ü  
                LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq  = Z.AccSeq          --�������� ������� �׸� 
                                                         AND K.ValueSeq         = Z.UMCostType


   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰� 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp <>  6008004 --����ǰ 
     AND E.IsToOtherAcc = '1'
    AND Z.AccSeq IS NULL 
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           L.AccSeq       , --�뺯����    
           L.UMCostType           , --�뺯��뱸��    
           N.AccSeq            , --��������    
           N.UMCostType            , --������뱸��  
           A.CCtrSeq			 ,
		   A.DeptSeq   ,
           A.CustSeq    
		   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(N.AccSeq, 0)  , --�뺯����    
           N.UMCostType         , --�뺯��뱸��    
           ISNULL(j.ValueSeq, 0), --��������    
           ISNULL(K.ValueSeq, 0), --������뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq   
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'     

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Ÿ�������� ��ü  
                LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --�������� ������� �׸� 
                                                         AND K.ValueSeq        = Z.UMCostType


   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰� 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp <>  6008004 --����ǰ 
     AND E.IsToOtherAcc = '1'
     AND Z.AccSeq IS NULL 
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           N.AccSeq       , --�뺯����    
           N.UMCostType           , --�뺯��뱸��    
           j.ValueSeq            , --��������    
           K.ValueSeq            , --������뱸��  
           A.CCtrSeq			 ,
		   A.DeptSeq    ,
           A.CustSeq          
    --��Ÿ���(�������� ����)
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq )    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(j.ValueSeq, 0) , --�뺯����    
           ISNULL(K.ValueSeq , 0), --�뺯��뱸��    
           ISNULL(L.AccSeq, 0)   , --��������    
           L.UMCostType          , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           5                     , --����
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������ 
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType

		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
   WHERE A.CompanySeq = @CompanySeq    
     AND A.CostKeySeq = @CostKeySeq 
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --��Ÿ���
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
     AND E.SMAssetGrp <>  6008004 --����ǰ  
     AND ( E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL )
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind           , --���������    
           j.ValueSeq          , --�뺯����    
           K.ValueSeq          , --�뺯��뱸��    
           L.AccSeq             , --��������    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq            ,
           A.CustSeq          
          
    INSERT INTO #TempInOut(    
           SMSlipKind  ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(N.AccSeq, 0) , --�뺯����    
           ISNULL(N.UMCostType , 0), --�뺯��뱸��    
           ISNULL(L.AccSeq, 0)   , --��������    
           L.UMCostType          , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           5                     , --����
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                            AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������ 
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType

		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  

   WHERE A.CompanySeq = @CompanySeq  
     AND A.CostKeySeq = @CostKeySeq   
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --��Ÿ���
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
     AND E.SMAssetGrp <>  6008004 --����ǰ  
     AND E.IsFromOtherAcc = '1'
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind           , --���������    
           N.AccSeq          , --�뺯����    
           N.UMCostType          , --�뺯��뱸��    
           L.AccSeq             , --��������    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq            ,
           A.CustSeq        
           
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(j.ValueSeq, 0) , --�뺯����    
           ISNULL(K.ValueSeq , 0), --�뺯��뱸��    
           ISNULL(N.AccSeq, 0)   , --��������    
           N.UMCostType          , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           5                     , --����
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
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
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  
   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --��Ÿ���
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit  = @CostUnit    ))
     AND Z.AccSeq IS NULL
     AND E.SMAssetGrp <>  6008004 --����ǰ  
     AND E.IsFromOtherAcc = '1'
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind           , --���������    
           j.ValueSeq          , --�뺯����    
           K.ValueSeq          , --�뺯��뱸��    
           N.AccSeq             , --��������    
           N.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq            ,
           A.CustSeq             
    /*****************************************************/    
    --���ۺ����ݾ�ó��    
    --���۰��� �ְų� ��� ��� ��Ÿ���(���������)�� �߻��Ѱ���� ����ó���̴�.                       
    /*****************************************************/    
    
--    --������������    
--    EXEC dbo._SCOMEnv @CompanySeq, 5506,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    
--    --�������� ������ ��뱸��    
--    EXEC dbo._SCOMEnv @CompanySeq, 5540,@UserSeq,@@PROCID,@cTRANsAdjUMcostTypeSeq OUTPUT    
--    
     --�ܼ���������    
    EXEC dbo._SCOMEnv @CompanySeq, 5507,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    


    -- ��Ÿ�x���� ������� ��    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
        SELECT @SMSlipKind,    
               A.SMAdjustKind , --��Ÿ�������    
               A.InOutKind , --���������    
               E.AssetSeq             , --����ڻ�з�    
               --@cTRANsAdjAccSeq       , --�뺯����(������������)    
               --0, --�뺯��뱸��(������������ ��뱸��)    
               CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --�뺯����  
               CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --�뺯��뱸��    
               ISNULL(L.AccSeq, 0)    , --��������    
               L.UMCostType          , --������뱸��    
               SUM(A.Amt )           , --��Ÿ���ݾ�    
               1                     , --����    
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
                                                         AND L.AssetAccKindSeq = 1 --�ڻ�ó������    
                   LEFT OUTER JOIN _TDAItemAssetAcc AS O WITH(NOLOCK) ON D.AssetSeq  = O.AssetSeq  
                                                         AND D.Companyseq = O.CompanySeq      
                                                         AND O.AssetAccKindSeq = 21-- Ÿ�������δ�ü   
        WHERE A.CompanySeq = @CompanySeq 
          AND A.CostKeySeq = @CostKeySeq
          AND A.SMAdjustKind = 5513001 -- ��ǰ�ܰ�����    
          AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
               OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
          AND A.CostKeySeq   = @CostKeySeq    
          AND A.InOutKind    = 8023003  --��Ÿ���   
          AND E.SMAssetGrp <>  6008004 --����ǰ  
        GROUP BY E.AssetSeq ,A.InOutKind , A.DeptSeq , 
                 A.SMAdjustKind,
                 CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --�뺯����  
                 CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --�뺯��뱸��    
                 L.AccSeq,L.UMCostType

 
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
        SELECT @SMSlipKind,    
               A.SMAdjustKind , --��Ÿ�������    
               A.InOutKind , --���������    
               E.AssetSeq             , --����ڻ�з�    
               @cTRANsAdjAccSeq       , --�뺯����(������������)    
               0, --�뺯��뱸��(������������ ��뱸��)     
               ISNULL(L.AccSeq, 0)    , --��������    
               L.UMCostType          , --������뱸��    
               SUM(A.Amt )           , --��Ÿ���ݾ�    
               1                     , --����    
               A.DeptSeq             ,    
               0        ,0 
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                   JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                          AND A.ItemSeq    = D.ItemSeq    
                   JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                          AND D.AssetSeq    = E.AssetSeq      
                   LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                         AND E.AssetSeq     = L.AssetSeq    
                                                         AND L.AssetAccKindSeq = 21 --Ÿ�������δ�ü
        WHERE A.CompanySeq = @CompanySeq 
          AND A.CostKeySeq = @CostKeySeq
          AND A.SMAdjustKind = 5513001 -- ��ǰ�ܰ�����    
          AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
               OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
          AND A.CostKeySeq   = @CostKeySeq    
          AND A.InOutKind    = 8023003  --��Ÿ���   
          AND E.SMAssetGrp <>  6008004 --����ǰ  
          AND E.IsFromOtherAcc = '1' 
        GROUP BY E.AssetSeq ,A.InOutKind , A.DeptSeq , 
                 A.SMAdjustKind,  
                 L.AccSeq,L.UMCostType
 

    IF @BanToProc = 1  --����ǰ ������� ó��
    BEGIN

    --��Ÿ�԰�  ( Ÿ�������� ��ü /  ������ ) 
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(N.AccSeq, 0)  , --��������    
           ISNULL(N.UMCostType,0), --������뱸��    
           ISNULL(j.ValueSeq, 0), --�뺯����    
           ISNULL(K.ValueSeq, 0), --�뺯��뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                 AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Ÿ�������� ��ü  
		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --�������� ������� �׸� 
                                                                    AND K.ValueSeq        = Z.UMCostType

  
--���ǰ-������� Ÿ�������δ�ü
--Ÿ�������� ���� : 17
--Ÿ�������� ���� : 21  

   WHERE A.CompanySeq = @CompanySeq    
     AND A.CostKeySeq = @CostKeySeq 
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰� 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp  = 6008004 --����ǰ 
     AND Z.AccSeq  IS NULL
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           N.AccSeq       , --�뺯����    
           N.UMCostType           , --�뺯��뱸��    
           j.ValueSeq            , --��������    
           K.ValueSeq            , --������뱸��  
           A.CCtrSeq			 ,
		   A.DeptSeq   ,
           A.CustSeq     

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(L.AccSeq, 0)  , --�뺯����    
           L.UMCostType         , --�뺯��뱸��    
           ISNULL(N.AccSeq, 0)  , --��������    
           ISNULL(N.UMCostType, 0), --������뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'   
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������    

               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Ÿ�������δ�ü  
		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --�������� ������� �׸� 
         AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰� 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp = 6008004 --����ǰ 
     AND Z.AccSeq IS NULL
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           L.AccSeq       , --�뺯����    
           L.UMCostType           , --�뺯��뱸��    
           N.AccSeq           , --��������    
           N.UMCostType            , --������뱸��  
           A.CCtrSeq			 ,
		   A.DeptSeq         ,
           A.CustSeq

 
    --��Ÿ���(�������� ����)  Ÿ�������δ�ü/ ���ǰ
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(N.AccSeq, 0) , --�뺯����    
           ISNULL(N.UMCostType , 0), --�뺯��뱸��    
           ISNULL(L.AccSeq, 0)   , --��������    
           ISNULL(L.UMCostType, 0) , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           5                     , --����
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������ 
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
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --��Ÿ���
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
     AND E.SMAssetGrp = 6008004 --����ǰ 
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind           , --���������    
           N.AccSeq          , --�뺯����    
           N.UMCostType          , --�뺯��뱸��    
           L.AccSeq             , --��������    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq  ,
           A.CustSeq    

    --��Ÿ���(�������� ����) �ǰ���/Ÿ�������δ�ü 
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(j.ValueSeq, 0) , --�뺯����    
           ISNULL(K.ValueSeq , 0), --�뺯��뱸��    
           ISNULL(N.AccSeq, 0)   , --��������    
           N.UMCostType          , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           5                     , --����
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType

		        LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --��Ÿ���
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
     AND E.SMAssetGrp = 6008004 --����ǰ 
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind           , --���������    
           j.ValueSeq          , --�뺯����    
           K.ValueSeq          , --�뺯��뱸��    
           N.AccSeq             , --��������    
           N.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq   ,
           A.CustSeq

        
    /*****************************************************/    
    --���ۺ����ݾ�ó��    
    --���۰��� �ְų� ��� ��� ��Ÿ���(���������)�� �߻��Ѱ���� ����ó���̴�.                       
    /*****************************************************/    
    
    --������������    
    EXEC dbo._SCOMEnv @CompanySeq, 5507,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    
    --�������� ������ ��뱸��    
--    EXEC dbo._SCOMEnv @CompanySeq, 5540,@UserSeq,@@PROCID,@cTRANsAdjUMcostTypeSeq OUTPUT    
    
    
    -- ��Ÿ�x���� ������� ��  (  Ÿ�������� ��ü    /���ǰ  
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
        SELECT @SMSlipKind,    
               A.SMAdjustKind , --��Ÿ�������    
               A.InOutKind , --���������    
               E.AssetSeq             , --����ڻ�з�    
               ISNULL(N.AccSeq, 0)    , --��������    
               ISNULL(N.UMCostType,0)          , --������뱸��    
               ISNULL(L.AccSeq, 0)    , --��������    
               ISNULL(L.UMCostType,0)          , --������뱸��    
               SUM(A.Amt )           , --��Ÿ���ݾ�    
               1                     , --����    
               A.DeptSeq             ,    
               0        ,0
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                   JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                          AND A.ItemSeq    = D.ItemSeq    
                   JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                          AND D.AssetSeq    = E.AssetSeq      
                   LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                         AND E.AssetSeq     = L.AssetSeq    
                                                         AND L.AssetAccKindSeq = 1 --�ڻ�ó������    
                   LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  
        WHERE A.CompanySeq = @CompanySeq 
          AND A.CostKeySeq = @CostKeySeq
          AND A.SMAdjustKind = 5513001 -- ��ǰ�ܰ�����   
          AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
               OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
          AND A.InOutKind    = 8023003  --��Ÿ���    
          AND E.SMAssetGrp = 6008004 --����ǰ 
        GROUP BY E.AssetSeq ,A.InOutKind , A.DeptSeq , 
                 A.SMAdjustKind, L.AccSeq,L.UMCostType , N.AccSeq,N.UMCostType     
    
  

    -- ��Ÿ�x���� ������� ��  ( �������� / Ÿ�������� ��ü)   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
        SELECT @SMSlipKind,    
               A.SMAdjustKind , --��Ÿ�������    
               A.InOutKind , --���������    
               E.AssetSeq             , --����ڻ�з�    
               @cTRANsAdjAccSeq       , --�뺯����(������������)    
               0, --�뺯��뱸��(������������ ��뱸��)    
               ISNULL(N.AccSeq, 0)    , --��������    
               ISNULL(N.UMCostType,0)          , --������뱸��    
               SUM(A.Amt )           , --��Ÿ���ݾ�    
               1                     , --����    
               A.DeptSeq             ,    
               0        ,0
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                   JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                          AND A.ItemSeq    = D.ItemSeq    
                   JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                          AND D.AssetSeq    = E.AssetSeq      
                   LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  
        WHERE A.CompanySeq = @CompanySeq 
          AND A.CostKeySeq = @CostKeySeq
          AND A.SMAdjustKind = 5513001 -- ��ǰ�ܰ�����   
    AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit      = @CostUnit    )
               OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
          AND A.InOutKind    = 8023003  --��Ÿ���    
          AND E.SMAssetGrp   = 6008004  --����ǰ 
        GROUP BY E.AssetSeq ,A.InOutKind , A.DeptSeq , 
                 A.SMAdjustKind, N.AccSeq,N.UMCostType   

 

   END 
   ELSE --����ǰ�� ������� ó������ ������ 
   BEGIN 

    --��Ÿ�԰�    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(L.AccSeq, 0)  , --�뺯����    
           L.UMCostType         , --�뺯��뱸��    
           ISNULL(j.ValueSeq, 0), --��������    
           ISNULL(K.ValueSeq, 0), --������뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --�������� ������� �׸� 
                                                         AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰�
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.SMAssetGrp = 6008004 --����ǰ 
    AND ( E.IsToOtherAcc = '0' OR E.IsToOtherAcc IS NULL)  
    AND Z.AccSeq IS NULL
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           L.AccSeq       , --�뺯����    
           L.UMCostType           , --�뺯��뱸��    
           j.ValueSeq            , --��������    
           K.ValueSeq            , --������뱸��  
           A.CCtrSeq			 ,
		   A.DeptSeq    ,
           A.CustSeq    

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(L.AccSeq, 0)  , --�뺯����    
           L.UMCostType         , --�뺯��뱸��    
           ISNULL(N.AccSeq, 0), --��������    
           ISNULL(N.UMCostType, 0), --������뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
           AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'   
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                      AND N.AssetAccKindSeq = 17 -- Ÿ�������� ��ü  
               LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --�������� ������� �׸� 
                                                         AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰�
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.SMAssetGrp = 6008004 --����ǰ 
     AND E.IsToOtherAcc = '1'
     AND Z.AccSeq IS NULL
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           L.AccSeq       , --�뺯����    
           L.UMCostType           , --�뺯��뱸��    
           N.AccSeq            , --��������    
           N.UMCostType            , --������뱸��  
           A.CCtrSeq			 ,
		   A.DeptSeq   ,
           A.CustSeq 
		   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(N.AccSeq, 0)  , --�뺯����    
           N.UMCostType         , --�뺯��뱸��    
           ISNULL(j.ValueSeq, 0), --��������    
           ISNULL(K.ValueSeq, 0), --������뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                        AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												        AND M.Serl     = 2009	        -- ǰ����ǥó������
													    AND A.InOutDetailKind = M.minorseq 
													    AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                          AND N.AssetAccKindSeq = 17 -- Ÿ�������� ��ü 
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰�
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.SMAssetGrp = 6008004 --����ǰ 
     AND E.IsToOtherAcc = '1'
     AND Z.AccSeq IS NULL
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           N.AccSeq       , --�뺯����    
           N.UMCostType           , --�뺯��뱸��    
           j.ValueSeq            , --��������    
           K.ValueSeq            , --������뱸��  
           A.CCtrSeq			 ,
		   A.DeptSeq            ,
           A.CustSeq  
		   
    --��Ÿ���(�������� ����)
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(j.ValueSeq, 0) , --�뺯����    
           ISNULL(K.ValueSeq , 0), --�뺯��뱸��    
           ISNULL(L.AccSeq, 0)   , --��������    
           L.UMCostType          , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           5                     , --����
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������ 
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType

		        LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --��Ÿ���
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
      AND E.SMAssetGrp = 6008004 --����ǰ 
      AND ( E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL )
  GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind           , --���������    
           j.ValueSeq          , --�뺯����    
           K.ValueSeq          , --�뺯��뱸��    
           L.AccSeq             , --��������    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq    ,
           A.CustSeq 
           
           
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(N.AccSeq, 0) , --�뺯����    
           ISNULL(N.UMCostType , 0), --�뺯��뱸��    
           ISNULL(L.AccSeq, 0)   , --��������    
           L.UMCostType          , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           5                     , --����
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������ 
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
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                      AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --��Ÿ���
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
      AND E.SMAssetGrp = 6008004 --����ǰ 
     AND E.IsFromOtherAcc = '1'
  GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind           , --���������    
           N.AccSeq          , --�뺯����    
           N.UMCostType          , --�뺯��뱸��    
           L.AccSeq             , --��������    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq   ,
           A.CustSeq
           
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(j.ValueSeq, 0) , --�뺯����    
           ISNULL(K.ValueSeq , 0), --�뺯��뱸��    
           ISNULL(N.AccSeq, 0)   , --��������    
           N.UMCostType          , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           5                     , --����
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
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
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                      AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --��Ÿ���
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
      AND E.SMAssetGrp = 6008004 --����ǰ 
     AND E.IsFromOtherAcc = '1'
  GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind           , --���������    
           j.ValueSeq          , --�뺯����    
           K.ValueSeq          , --�뺯��뱸��    
           N.AccSeq             , --��������    
           N.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq            ,
           A.CustSeq          
    /*****************************************************/    
    --���ۺ����ݾ�ó��    
    --���۰��� �ְų� ��� ��� ��Ÿ���(���������)�� �߻��Ѱ���� ����ó���̴�.                       
    /*****************************************************/    
    
    --������������    
    EXEC dbo._SCOMEnv @CompanySeq, 5507,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    
    --�������� ������ ��뱸��    
--    EXEC dbo._SCOMEnv @CompanySeq, 5540,@UserSeq,@@PROCID,@cTRANsAdjUMcostTypeSeq OUTPUT    
    
    
    -- ��Ÿ�x���� ������� ��    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
          DeptSeq      ,CCtrSeq    ,CustSeq)    
        SELECT @SMSlipKind,    
               A.SMAdjustKind , --��Ÿ�������    
               A.InOutKind , --���������    
               E.AssetSeq             , --����ڻ�з�    
               --@cTRANsAdjAccSeq       , --�뺯����(������������)    
               --0, --�뺯��뱸��(������������ ��뱸��)  
               CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --�뺯����  
               CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --�뺯��뱸��      
               ISNULL(L.AccSeq, 0)    , --��������    
               L.UMCostType          , --������뱸��    
               SUM(A.Amt )           , --��Ÿ���ݾ�    
               1                     , --����    
               A.DeptSeq             ,    
               0     ,0   
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                   JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                          AND A.ItemSeq    = D.ItemSeq    
                   JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                          AND D.AssetSeq    = E.AssetSeq      
                   LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                         AND E.AssetSeq     = L.AssetSeq    
                                                         AND L.AssetAccKindSeq = 1 --�ڻ�ó������   
                   LEFT OUTER JOIN _TDAItemAssetAcc AS O WITH(NOLOCK) ON D.AssetSeq  = O.AssetSeq  
                                                         AND D.Companyseq = O.CompanySeq      
                                                         AND O.AssetAccKindSeq = 21-- Ÿ�������δ�ü    
        WHERE A.CompanySeq = @CompanySeq 
          AND A.CostKeySeq = @CostKeySeq
          AND A.SMAdjustKind = 5513001 -- ��ǰ�ܰ�����   
          AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
               OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
          AND A.CostKeySeq   = @CostKeySeq    
          AND A.InOutKind    = 8023003  --��Ÿ���    
          AND E.SMAssetGrp = 6008004 --����ǰ 
   GROUP BY E.AssetSeq ,A.InOutKind , A.DeptSeq , 
                 A.SMAdjustKind,
                 CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --�뺯����  
                 CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --�뺯��뱸��    
                 L.AccSeq,L.UMCostType
                 
                 
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
        SELECT @SMSlipKind,    
               A.SMAdjustKind , --��Ÿ�������    
               A.InOutKind , --���������    
               E.AssetSeq             , --����ڻ�з�    
               @cTRANsAdjAccSeq       , --�뺯����(������������)    
               0, --�뺯��뱸��(������������ ��뱸��)    
               ISNULL(L.AccSeq, 0)    , --��������    
               L.UMCostType          , --������뱸��    
               SUM(A.Amt )           , --��Ÿ���ݾ�    
               1                     , --����    
               A.DeptSeq             ,    
               0                     ,0 
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                   JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                          AND A.ItemSeq    = D.ItemSeq    
                   JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                          AND D.AssetSeq    = E.AssetSeq      
                   LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                         AND E.AssetSeq     = L.AssetSeq    
                                                         AND L.AssetAccKindSeq = 21-- Ÿ�������δ�ü  
        WHERE A.CompanySeq = @CompanySeq 
          AND A.CostKeySeq = @CostKeySeq
          AND A.SMAdjustKind = 5513001 -- ��ǰ�ܰ�����   
          AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
               OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
          AND A.CostKeySeq   = @CostKeySeq    
          AND A.InOutKind    = 8023003  --��Ÿ���    
          AND E.SMAssetGrp = 6008004 --����ǰ 
          AND E.IsFromOtherAcc = '1' 
   GROUP BY E.AssetSeq ,A.InOutKind , A.DeptSeq , 
                 A.SMAdjustKind, L.AccSeq,L.UMCostType  


   END 



    /******************************************************************/    
    --��ü��� :�켱 ����(��Ÿ����� ���)    
    /******************************************************************/    
     

    GOTO Proc_Query
   
RETURN 

/*****************************************************************************************/
PROC_GoodS: --��ǰ
    
    --��Ÿ�԰�    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(L.AccSeq, 0)   , --��������    
           L.UMCostType          , --������뱸��    
           ISNULL(j.ValueSeq, 0) , --�뺯����    
           ISNULL(K.ValueSeq, 0) , --�뺯��뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           1                     , --����    
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
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --���츮    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '1002'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                   AND L.AssetAccKindSeq = 1 --�ڻ�ó������    
                  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001��ǰ/    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰�/��Ÿ���    
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
    AND ( E.IsToOtherAcc = '0' OR E.IsToOtherAcc IS NULL) --Ÿ�������� ��ü�� �ƴѰ��
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --�̹� ��ϵ� ���� ����    
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           j.ValueSeq          , --�뺯����    
           K.ValueSeq          , --�뺯��뱸��    
           L.AccSeq             , --��������    
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
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(L.AccSeq, 0)   , --�뺯����    
           L.UMCostType          , --�뺯��뱸��
           ISNULL(N.AccSeq, 0) , --��������    
           ISNULL(N.UMCostType, 0) , --������뱸��        
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           1                     , --����    
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
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --���츮    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28  
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --�ڻ�ó������   
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Ÿ�������� ��ü  
                  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001��ǰ/    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰�/��Ÿ���   
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsToOtherAcc = '1' --Ÿ�������� ��ü�� ���
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --�̹� ��ϵ� ���� ����    
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������  
           L.AccSeq             , --�뺯����    
           L.UMCostType         ,       
           N.AccSeq             , --��������    
           N.UMCostType         , --������뱸��   
           A.DeptSeq            ,    
           A.CCtrSeq       ,  
           A.InOutKind     ,
           A.CustSeq 
           
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq    ) 
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(N.AccSeq, 0) , --�뺯����    
           ISNULL(N.UMCostType, 0) , --�뺯��뱸��    
           ISNULL(J.ValueSeq, 0)   , --��������    
           K.ValueSeq          , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
      1                     , --����    
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
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --���츮    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28  
               --LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
               --                                      AND E.AssetSeq     = L.AssetSeq    
               --                                      AND L.AssetAccKindSeq = 1 --�ڻ�ó������   
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Ÿ�������� ��ü  
                  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001��ǰ/    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰�/��Ÿ���    
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsToOtherAcc = '1' --Ÿ�������� ��ü�� ���
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --�̹� ��ϵ� ���� ����    
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           N.AccSeq             , --�뺯����    
           N.UMCostType         , --�뺯��뱸��    
           J.ValueSeq             , --��������    
           K.ValueSeq         ,    
           A.DeptSeq            ,    
           A.CCtrSeq       ,  
           A.InOutKind      ,
           A.CustSeq
           
           
    --��Ÿ���   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(j.ValueSeq, 0) , --��������    
           ISNULL(K.ValueSeq, 0) , --������뱸��    
           ISNULL(L.AccSeq, 0)   , --�뺯����    
           L.UMCostType          , --�뺯��뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           1                     , --����    
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
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --���츮    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --�ڻ�ó������    
                  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001��ǰ/    
     AND A.InOutKind IN (8023003)  --��Ÿ�԰�/��Ÿ���    
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND ( E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL )--Ÿ�������� ��ü�� �ƴ� ���
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --�̹� ��ϵ� ���� ����    
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           j.ValueSeq          , --��������    
           K.ValueSeq          , --������뱸��    
           L.AccSeq             , --�뺯����    
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
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(N.AccSeq, 0) , --��������    
           ISNULL(N.UMCostType, 0) , --������뱸��    
           ISNULL(L.AccSeq, 0)   , --�뺯����    
L.UMCostType          , --�뺯��뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           1                     , --����    
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
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --���츮    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --�ڻ�ó������    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001��ǰ/    
     AND A.InOutKind IN (8023003)  --��Ÿ�԰�/��Ÿ���    
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1' --Ÿ�������� ��ü�� �ƴ� ���
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --�̹� ��ϵ� ���� ����    
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           N.AccSeq          , --��������    
           N.UMCostType          , --������뱸��    
           L.AccSeq             , --�뺯����    
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
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(J.ValueSeq, 0)   , --��������    
   K.ValueSeq          , --������뱸��    
           ISNULL(N.AccSeq, 0) , --�뺯����    
           ISNULL(N.UMCostType, 0) , --�뺯��뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           1                     , --����    
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
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --���츮    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '2004'    
               --LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
               --                                      AND E.AssetSeq     = L.AssetSeq    
               --                                      AND L.AssetAccKindSeq = 1 --�ڻ�ó������    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001��ǰ/    
     AND A.InOutKind IN (8023003)  --��Ÿ�԰�/��Ÿ���    
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1' --Ÿ�������� ��ü�� �ƴ� ���
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --�̹� ��ϵ� ���� ����    
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           J.ValueSeq             , --��������    
           K.ValueSeq         ,    
           N.AccSeq          , --�뺯����    
           N.UMCostType          , --�뺯��뱸��    
           A.DeptSeq              ,    
           A.CCtrSeq       ,  
           A.InOutKind    ,
           A.CustSeq

--    /*****************************************************/    
--    --�ܼ������ݾ�ó��    
--    --���۰��� �ְų� ��� ��� ��Ÿ���(���������)�� �߻��Ѱ���� ����ó���̴�.                       
--    /*****************************************************/    
--    
    --�ܼ���������    
    EXEC dbo._SCOMEnv @CompanySeq, 5507,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    
--    --�������� ������ ��뱸��    
--    EXEC dbo._SCOMEnv @CompanySeq, 5540,@UserSeq,@@PROCID,@cTRANsAdjUMcostTypeSeq OUTPUT    
--    select * from _TDASMinor where minorname like '%����%'
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt     , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT  @SMSlipKind,    
           0      , --��Ÿ�������    
           5513003           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           --ISNULL(@cTRANsAdjAccSeq, 0) , --�뺯����    
           --ISNULL(0, 0) , --�뺯��뱸��    
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --�뺯����  
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --�뺯��뱸��   
           ISNULL(N.AccSeq, 0)   , --��������    
           N.UMCostType  , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           1                     , --����    
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
                                                     AND N.AssetAccKindSeq = 1 -- �ڻ�ó������   
               LEFT OUTER JOIN _TDAItemAssetAcc AS O WITH(NOLOCK) ON D.AssetSeq  = O.AssetSeq  
                                                     AND D.Companyseq = O.CompanySeq      
                                                     AND O.AssetAccKindSeq = 21-- Ÿ�������δ�ü   
 
                   
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001��ǰ/  
     --AND F.MinorValue  = '1'    --����    
     --AND F.MinorSeq    <> 6008005   --���ǰ�� �ƴѰ� 
     AND A.InOutKind IN (8023003)  --��Ÿ�԰�/��Ÿ���    
     AND A.SMAdjustKind = 5513003 
--     AND A.CostUnit = @CostUnit    
     AND  (   ( @GoodPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @GoodPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )  
--     AND E.IsFromOtherAcc = '1'
     -- ������ ���ϴ°� ���, ���ְ��ƴѰ�, ��..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --�̹� ��ϵ� ���� ����    
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           N.AccSeq             , --��������    
           N.UMCostType         ,    
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --�뺯����  
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END,--�뺯��뱸��   
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind   ,
           A.CustSeq 
           
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT  @SMSlipKind,    
           0      , --��Ÿ�������    
           5513003           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(@cTRANsAdjAccSeq, 0) , --�뺯����    
           ISNULL(0, 0) , --�뺯��뱸��    
           ISNULL(N.AccSeq, 0)   , --��������    
           N.UMCostType  , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           1                     , --����    
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
             AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  
 
                   
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001��ǰ/  
     --AND F.MinorValue  = '1'    --����    
     --AND F.MinorSeq    <> 6008005   --���ǰ�� �ƴѰ� 
     AND A.InOutKind IN (8023003)  --��Ÿ�԰�/��Ÿ���    
     AND A.SMAdjustKind = 5513003 
--     AND A.CostUnit = @CostUnit    
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1'
     -- ������ ���ϴ°� ���, ���ְ��ƴѰ�, ��..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --�̹� ��ϵ� ���� ����    
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           N.AccSeq             , --��������    
           N.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind    ,
           A.CustSeq
--    /*****************************************************/    
--    --���ۺ����ݾ�ó��    
--    --���۰��� �ְų� ��� ��� ��Ÿ���(���������)�� �߻��Ѱ���� ����ó���̴�.                       
--    /*****************************************************/    
--    
--    --������������    
--    EXEC dbo._SCOMEnv @CompanySeq, 5506,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    
--    --�������� ������ ��뱸��    
--        
--    EXEC dbo._SCOMEnv @CompanySeq, 5506,@UserSeq,@@PROCID,@cTRANsAdjUMcostTypeSeq OUTPUT    
--    --�ܼ��ݾ� ����    
--    UPDATE #TempInOut     
--       SET Amt  = AMt + ISNULL((SELECT SUM(Amt) FROM _TESMGInOutStock  A  WHERE A.CompanySeq   = @CompanySeq    
--              AND A.SMAdjustKind = 5513003 -- ����ܰ�����    
--              AND A.CostUnit     = @CostUnit     
--              AND A.CostKeySeq   = @CostKeySeq    
--              AND A.InOutKind    = 8023003  --��Ÿ���     
--              ),0)    
--      FROM #TempInOut     
--    /******************************************************************/    
--    --��ü��� :�켱 ����(��Ÿ����� ���)    
--    /******************************************************************/    
    
    GOTO Proc_Query
        
RETURN 
/*********************************************************************************************************/  
PROC_Mat: --��Ÿ����� ����


    --��Ÿ�԰�    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(L.AccSeq, 0)   , --��������    
           L.UMCostType           , --������뱸��    
           ISNULL(j.ValueSeq, 0)  , --�뺯����    
           ISNULL(K.ValueSeq, 0)  , --�뺯��뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           1                     , --����    
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
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --���츮    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     --AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '1002'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --�ڻ�ó������     
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
     AND F.MinorValue  = '1'    --����    
     AND F.MinorSeq    <> 6008005   --���ǰ�� �ƴѰ�    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰�/��Ÿ���    
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
             )		-- �巳����
	 AND (AA.InOutType=31) 

     -- ������ ���ϴ°� ���, ���ְ��ƴѰ�, ��..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --�̹� ��ϵ� ���� ����    
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������   
           L.AccSeq             , --��������    
           L.UMCostType         ,    
           j.ValueSeq          , --�뺯����    
           K.ValueSeq          , --�뺯��뱸��     
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
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(L.AccSeq, 0)   , --��������    
           L.UMCostType           , --������뱸��    
           ISNULL(N.AccSeq, 0)  , --�뺯����    
           ISNULL(N.UMCostType, 0)  , --�뺯��뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           1                     , --����    
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
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --���츮    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     --AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '1002'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --�ڻ�ó������ 
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Ÿ�������� ��ü  
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
     AND F.MinorValue  = '1'    --����    
     AND F.MinorSeq    <> 6008005   --���ǰ�� �ƴѰ�    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰�/��Ÿ���    
--     AND A.CostUnit = @CostUnit   
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
      )     
    AND E.IsToOtherAcc = '1' AND O.AccSeq IS NULL 
	AND (A.InOutDetailKind IN (8025007) )		-- �巳����
	AND (AA.InOutType=31)

  --    ������ ���ϴ°� ���, ���ְ��ƴѰ�, ��..    
   --  AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --�̹� ��ϵ� ���� ����    
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           L.AccSeq             , --��������    
           L.UMCostType         ,    
           N.AccSeq          , --�뺯����    
           N.UMCostType          , --�뺯��뱸��    
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
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(N.AccSeq, 0)   , --��������    
           N.UMCostType           , --������뱸��    
           ISNULL(j.ValueSeq, 0)  , --�뺯����    
           ISNULL(K.ValueSeq, 0)  , --�뺯��뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           1                     , --����    
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
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --���츮    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     --AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '1002'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Ÿ�������� ��ü  
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
     AND F.MinorValue  = '1'    --����    
     AND F.MinorSeq    <> 6008005   --���ǰ�� �ƴѰ�    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰�/��Ÿ���    
--     AND A.CostUnit = @CostUnit   
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )     
    AND E.IsToOtherAcc = '1'  AND O.AccSeq IS NULL
	AND (A.InOutDetailKind IN (8025007) )		-- �巳���� 
	AND (AA.InOutType=31)
     -- ������ ���ϴ°� ���, ���ְ��ƴѰ�, ��..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --�̹� ��ϵ� ���� ����    
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������   
           N.AccSeq             , --��������    
           N.UMCostType         ,    
           j.ValueSeq          , --�뺯����    
           K.ValueSeq          , --�뺯��뱸��     
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind   ,
           A.CustSeq	,
           AB.ItemSeq 


     --��Ÿ��� 
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(j.ValueSeq, 0) , --�뺯����    
           ISNULL(K.ValueSeq, 0) , --�뺯��뱸��    
           ISNULL(L.AccSeq, 0)   , --��������    
           L.UMCostType  , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           1                     , --����    
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
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --���츮    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                   --  AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --�ڻ�ó������    
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
     AND F.MinorValue  = '1'    --����    
     AND F.MinorSeq    <> 6008005   --���ǰ�� �ƴѰ�    
     AND A.InOutKind IN (8023003)  --��Ÿ�԰�/��Ÿ���    
--     AND A.CostUnit = @CostUnit    
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )  
     AND (( E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL )
         OR (O.AccSeq IS NOT NULL))
	 AND (A.InOutDetailKind IN (8025007) )		-- �巳����
	-- AND (AA.InOutType=31) 
     -- ������ ���ϴ°� ���, ���ְ��ƴѰ�, ��..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --�̹� ��ϵ� ���� ����    
    GROUP BY E.AssetSeq         , --����ڻ�з�    
          A.InOutDetailKind    , --��Ÿ�������    
           j.ValueSeq          , --�뺯����    
           K.ValueSeq          , --�뺯��뱸��    
           L.AccSeq             , --��������    
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
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(N.AccSeq, 0) , --�뺯����    
           ISNULL(N.UMCostType, 0) , --�뺯��뱸��    
           ISNULL(L.AccSeq, 0)   , --��������    
           L.UMCostType  , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           1                     , --����    
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
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --���츮    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     --AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
        LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --�ڻ�ó������    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  
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
     AND F.MinorValue  = '1'    --����    
     AND F.MinorSeq    <> 6008005   --���ǰ�� �ƴѰ�    
     AND A.InOutKind IN (8023003)  --��Ÿ�԰�/��Ÿ���    
--     AND A.CostUnit = @CostUnit    
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )  
     AND E.IsFromOtherAcc = '1' AND O.AccSeq IS NULL 
	 AND (A.InOutDetailKind IN (8025007) )		-- �巳����
	 AND (AA.InOutType=31) 
     -- ������ ���ϴ°� ���, ���ְ��ƴѰ�, ��..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --�̹� ��ϵ� ���� ����    
    GROUP BY E.AssetSeq         , --����ڻ�з�    
          A.InOutDetailKind    , --��Ÿ�������    
           N.AccSeq         , --�뺯����    
           N.UMCostType          , --�뺯��뱸��    
           L.AccSeq             , --��������    
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
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(j.ValueSeq, 0) , --�뺯����    
           ISNULL(K.ValueSeq, 0) , --�뺯��뱸��    
           ISNULL(N.AccSeq, 0)   , --��������    
           N.UMCostType  , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           1                     , --����    
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
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --���츮    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     --AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                     AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  
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
     AND F.MinorValue  = '1'    --����    
     AND F.MinorSeq    <> 6008005   --���ǰ�� �ƴѰ�    
     AND A.InOutKind IN (8023003)  --��Ÿ�԰�/��Ÿ���    
--     AND A.CostUnit = @CostUnit    
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )  
     AND E.IsFromOtherAcc = '1'AND O.AccSeq IS NULL 
	 AND (A.InOutDetailKind IN (8025007) )		-- �巳����
	 AND (AA.InOutType=31) 
     -- ������ ���ϴ°� ���, ���ְ��ƴѰ�, ��..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --�̹� ��ϵ� ���� ����    
    GROUP BY E.AssetSeq         , --����ڻ�з�    
          A.InOutDetailKind    , --��Ÿ�������    
           j.ValueSeq          , --�뺯����    
           K.ValueSeq          , --�뺯��뱸��    
           N.AccSeq             , --��������    
           N.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind    ,
           A.CustSeq,
		   AB.ItemSeq
--    /*****************************************************/    
--    --�ܼ������ݾ�ó��    
--    --���۰��� �ְų� ��� ��� ��Ÿ���(���������)�� �߻��Ѱ���� ����ó���̴�.                       
--    /*****************************************************/    
--    
    --�ܼ���������    
    EXEC dbo._SCOMEnv @CompanySeq, 5507,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    
--    --�������� ������ ��뱸��    
--    EXEC dbo._SCOMEnv @CompanySeq, 5540,@UserSeq,@@PROCID,@cTRANsAdjUMcostTypeSeq OUTPUT    
--    select * from _TDASMinor where minorname like '%����%'


    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind,    
           0      , --��Ÿ�������    
           5513002           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           --ISNULL(@cTRANsAdjAccSeq, 0) , --�뺯����  
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --�뺯����  
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --�뺯��뱸��    
           ISNULL(N.AccSeq, 0)   , --��������    
           N.UMCostType  , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           1                     , --����    
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
                                                     AND N.AssetAccKindSeq = 1 --�ڻ�ó������
               LEFT OUTER JOIN _TDAItemAssetAcc AS O WITH(NOLOCK) ON D.AssetSeq  = O.AssetSeq  AND O.Companyseq = @CompanySeq      
                                                     AND O.AssetAccKindSeq = 21-- Ÿ�������δ�ü   
                LEFT OUTER JOIN KPX_TPDSFCProdPackReportRelation AS AA WITH(NOLOCK) ON A.CompanySeq    = AA.CompanySeq
																				  AND A.InOutSeq      = AA.InOutSeq
																				  AND A.InOutSerl     = AA.InOutSerl
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem     AS AB WITH(NOLOCK) ON AA.CompanySeq   = AB.CompanySeq
																				  AND AA.WorkOrderSeq = AB.PackOrderSeq
																				  AND AA.WorkOrderSerl= AB.PackOrderSerl    
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '1'    --����    
     AND F.MinorSeq    <> 6008005   --���ǰ�� �ƴѰ�    
     AND A.InOutKind IN (8023003)  --��Ÿ�԰�/��Ÿ���    
     AND A.SMAdjustKind = 5513002 
--     AND A.CostUnit = @CostUnit    
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )
	 AND (A.InOutDetailKind IN (8025007) )		-- �巳����
	 AND (AA.InOutType=31)   
--     AND E.IsFromOtherAcc = '1'
     -- ������ ���ϴ°� ���, ���ְ��ƴѰ�, ��..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --�̹� ��ϵ� ���� ����    
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --�뺯���� 
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --�뺯��뱸��     
           N.AccSeq             , --��������    
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
           0   , --��Ÿ�������    
           5513002           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(@cTRANsAdjAccSeq, 0) , --�뺯����  
           ISNULL(0, 0), --�뺯��뱸��    
           ISNULL(N.AccSeq, 0)   , --��������    
           N.UMCostType  , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           1              , --����    
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
                                                     AND N.AssetAccKindSeq = 21 --Ÿ�������δ�ü
                LEFT OUTER JOIN KPX_TPDSFCProdPackReportRelation AS AA WITH(NOLOCK) ON A.CompanySeq    = AA.CompanySeq
																				  AND A.InOutSeq      = AA.InOutSeq
																				  AND A.InOutSerl     = AA.InOutSerl
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem     AS AB WITH(NOLOCK) ON AA.CompanySeq   = AB.CompanySeq
																				  AND AA.WorkOrderSeq = AB.PackOrderSeq
																				  AND AA.WorkOrderSerl= AB.PackOrderSerl    
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '1'    --����    
     AND F.MinorSeq    <> 6008005   --���ǰ�� �ƴѰ�    
     AND A.InOutKind IN (8023003)  --��Ÿ�԰�/��Ÿ���    
     AND A.SMAdjustKind = 5513002 
     AND E.IsFromOtherAcc = '1'
--     AND A.CostUnit = @CostUnit    
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         ) 
	 AND (A.InOutDetailKind IN (8025007) )		-- �巳����
	 AND (AA.InOutType=31)  
--     AND E.IsFromOtherAcc = '1'
     -- ������ ���ϴ°� ���, ���ְ��ƴѰ�, ��..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --�̹� ��ϵ� ���� ����    
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           N.AccSeq             , --��������    
           N.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind   ,
           A.CustSeq,
		   AB.ItemSeq
----�ܼ��ݾ� ����    
--UPDATE #TempInOut     
--   SET Amt  = AMt + ISNULL((SELECT SUM(Amt) FROM _TESMGInOutStock  A  WHERE A.CompanySeq   = @CompanySeq    
--          AND A.SMAdjustKind = 5513002 -- ����ܰ�����    
--          AND A.CostUnit     = @CostUnit     
--          AND A.CostKeySeq   = @CostKeySeq    
--          AND A.InOutKind    = 8023003  --��Ÿ���     
--          ),0)    
--  FROM #TempInOut     
  
    GOTO Proc_Query
RETURN 
/**************************************************************************************************************/
AVG_Prod: 
    --������� ������ǥ_��ǰ(�������� ����)

--  _TDAItemAssetAcc : 
--         AssetAccKindSeq 22 : ������� ���Ժ�������
--         AssetAccKindSeq 23 : ������� ���⺸������
--         AssetAccKindSeq 24 : ������� ��Ÿ��������
-- 
--select * From _TDADefineItemAssetAcc
--where companyseq = 1 
--������� ���������� �ڻ�з��� �������ÿ��� ���������� �Ѵ�. 
--Ȱ�����ͺ�, ǰ�񺰷� ��ǥ������ ȯ�漳���� ������. ��������� �Ǻ��� �����ϴ°��� 
--���ͼ��� ���� �ʿ��ϳ� ��ǥ���� �Ǻ��� ������ �ʿ�� ����. 

  
--- ������� ��ǥó���� Ȱ������, �Ǹźμ����� ��������� ������ ������ȸ�� �ϴ°��� ȯ�漳�� ���� ������.   
--- 5538 ���������ǥ Ȱ������(or �μ�)�� �� ���� ����  
  

--��ǰ������� ������ Ÿ�������� ��ǥ�� ������ �ʿ䰡 ����. �� �������� ���� �����̹Ƿ� Ÿ�������δ� 
--������ �ϱ����� ���������� �������� ���� ������� ������ ��쿡�� �� ����ڻ�з����� Ÿ������ǥ�� 
--�������� �ʵ��� �ؾ��Ѵ�.  
                                      
-- 
--5535001	5535	������� �����������
--5535002	5535	������� ���Աݾ�����
--5535003	5535	������� ��Ÿ���ݾ� ����

    INSERT INTO #TempInOut_Garbege(    
           SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,    
           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind ,IsFromOtherAcc )    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(N.AccSeq, 0) , --��������    
           ISNULL(N.UMCostType, 0) , --������뱸��    
           ISNULL(L.AccSeq, 0)   , --�뺯����    
           L.UMCostType  , --�뺯��뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           1                    , --����
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          , 
           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,         
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE  A.CustSeq   END          ,   --����ŷ�ó 
           CASE WHEN ( @IsDivideCCtrItem = '0' AND ( A.InOutDetailKind <> 5535002 ) ) THEN 0 ELSE   A.GoodItemSeq   END ,    --������ǰ   
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
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������ 
               LEFT OUTER JOIN _TDAItemAssetAcc    AS N WITH(NOLOCK) ON E.CompanySeq       = N.CompanySeq    
                                                         AND E.AssetSeq         = N.AssetSeq    
                                                         AND (   (( A.InOutDetailKind = 5535002 )
                                                                   AND  N.AssetAccKindSeq  = 22 --���Ժ�������
                                                                  )   
                                                              OR (( A.InOutDetailKind = 5535001 )
                                                                   AND  N.AssetAccKindSeq  = 23 --���⺸������
                                                                  )   
                                                              OR (( A.InOutDetailKind = 5535003 )
                                                                   AND  N.AssetAccKindSeq  = 24 --��Ÿ��������
                                                                 )
                                                             )   
               LEFT OUTER JOIN #AssetSeq    AS M WITH(NOLOCK) ON E.AssetSeq = M.AssetSeq 
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'   
     AND A.SMAdjustKind = 5513004 --��ǰ�ݾ׺���_������� 
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003       --��Ÿ���
     AND F.MinorSeq <> 6008001     
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
       OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     --AND (@YAVGAdjTransType = 5536002  OR (@YAVGAdjTransType = 5536001 AND  A.InOutDetailKind <> 5535003))--��õ���к� ������ �ƴ� ��� �����Ÿ���� ���  
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           N.AccSeq             ,    
           N.UMCostType         ,  
           L.AccSeq             ,  
           L.UMCostType         ,    
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,    
--           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE ISNULL(A.CCtrSeq , 0) END          ,    
           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,         
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE  A.CustSeq   END          ,   --����ŷ�ó 
           CASE WHEN @IsDivideCCtrItem = '0' AND ( A.InOutDetailKind <> 5535002 )  THEN 0 ELSE   A.GoodItemSeq   END,     --������ǰ   
           CASE WHEN  E.IsFromOtherAcc = '1' AND  M.AssetSeq IS NULL  THEN '1'  
                ELSE '0'  
           END     
   ORDER BY A.InOutDetailKind , E.AssetSeq 


    --��ǰ�� ���  ������ ���� �Ǵ� ���� ��Ÿ��� �����Ǵ� ��츦 �и��ϱ� �����
    
--    INSERT INTO #TempInOut_Garbege(    
--           SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,    
--           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,    
--           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind , IsFromOtherAcc )    
--    SELECT @SMSlipKind           ,    
--           5513004    , --��Ÿ�������    
--           A.InOutKind           , --���������    
--           E.AssetSeq            , --����ڻ�з�    
--           ISNULL(j.ValueSeq, 0) , --��������        
--           ISNULL(K.ValueSeq, 0) , --������뱸��  
--           ISNULL(L.AccSeq, 0)   , --�뺯����    
--           L.UMCostType          , --�뺯��뱸��    
--           SUM(A.Amt )           , --��Ÿ���ݾ�    
--           1                    , --����
--           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          , 
--           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,         
--           0,   --����ŷ�ó 
--           0 ,    --������ǰ   
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
--                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������ 
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
--     --AND A.SMAdjustKind = 5513004 --��ǰ�ݾ׺���_������� 
--     AND F.MinorValue  = '0'    
--     AND A.InOutKind = 8023003       --��Ÿ���
--     AND F.MinorSeq <> 6008001     
--     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
--       OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
--     AND (@YAVGAdjTransType = 5536001 ) --��õ���к��̰� ��Ÿ���� ������ ��� ��õ���� ������  
--    GROUP BY E.AssetSeq         , --����ڻ�з�    
--           A.InOutDetailKind    , --��Ÿ�������    
--           A.InOutKind          , --���������    
--           ISNULL(j.ValueSeq, 0) , --��������        
--           ISNULL(K.ValueSeq, 0) , --������뱸��  
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
AVG_GoodS: --������� ������ǥ_��ǰ
     
--��ǰ������� ������ Ÿ�������� ��ǥ�� ������ �ʿ䰡 ����. �� �������� ���� �����̹Ƿ� Ÿ�������δ�   
--������ �ϱ����� ���������� �������� ���� ������� ������ ��쿡�� �� ����ڻ�з����� Ÿ������ǥ��   
--�������� �ʵ��� �ؾ��Ѵ�.   

--5535001 5535 ������� �����������  
--5535002 5535 ������� ���Աݾ�����  
--5535003 5535 ������� ��Ÿ���ݾ� ����   
 
    
    INSERT INTO #TempInOut_Garbege (      
           SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,      
           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,      
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind,IsFromOtherAcc)    
    SELECT @SMSlipKind           ,      
           A.InOutDetailKind    , --��Ÿ�������      
           A.InOutKind           , --���������      
           E.AssetSeq            , --����ڻ�з�      
           ISNULL(N.AccSeq, 0) , --��������      
           ISNULL(N.UMCostType, 0) , --������뱸��      
           ISNULL(L.AccSeq, 0)   , --�뺯����      
           L.UMCostType          , --�뺯��뱸��      
           SUM(A.Amt )           , --��Ÿ���ݾ�      
           1                    , --����  
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END         ,      
           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE  A.CustSeq   END          ,   --����ŷ�ó   
           --CASE WHEN ( @IsDivideCCtrItem = '0' AND ( A.InOutDetailKind <> 5535002 ) ) THEN 0 ELSE   A.GoodItemSeq   END     --������ǰ     
           CASE WHEN ( @IsDivideCCtrItem = '0'  --eykim. 110701. ������ ���� ���Ѻ������� ��õ���к� ������ ���� �����׸� ���Ե� ��ǰ�� ��ȸ���Ѿ� �Ѵ�. 
					 AND ( ( A.InOutDetailKind <> 5535002 ) OR ( A.InOutDetailKind = 5535002 AND @YAVGAdjTransType = 5536002 ) ) ) THEN 0 ELSE   A.GoodItemSeq   END,     --������ǰ     
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
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������   
               LEFT OUTER JOIN _TDAItemAssetAcc    AS N WITH(NOLOCK) ON E.CompanySeq       = N.CompanySeq      
                                                         AND E.AssetSeq         = N.AssetSeq      
                                                         AND (   (( A.InOutDetailKind = 5535002 )  
                                                                   AND  N.AssetAccKindSeq  = 22 --���Ժ�������  
                                                                  )     
                                                              OR (( A.InOutDetailKind = 5535001 )  
                                                                   AND  N.AssetAccKindSeq  = 23 --���⺸������  
                                                                  )     
                                                              OR (( A.InOutDetailKind = 5535003 )  
                                                                   AND  N.AssetAccKindSeq  = 24 --��Ÿ��������  
                                                                 )  
                                                             )     
               LEFT OUTER JOIN #AssetSeq    AS M WITH(NOLOCK) ON E.AssetSeq = M.AssetSeq   
   WHERE A.CompanySeq = @CompanySeq           
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'     
     AND A.SMAdjustKind = 5513006 --��ǰ�ݾ׺���_ �������  
     AND F.MinorValue  = '0'      
     AND A.InOutKind = 8023003       --��Ÿ���  
     AND F.MinorSeq  = 6008001       
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )  
       OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))  
     AND (@YAVGAdjTransType = 5536002  OR (@YAVGAdjTransType = 5536001 AND  A.InOutDetailKind <> 5535003))--��õ���к� ������ �ƴ� ��� �����Ÿ���� ���  
    GROUP BY E.AssetSeq         , --����ڻ�з�      
           A.InOutDetailKind    , --��Ÿ�������      
           A.InOutKind          , --���������      
           N.AccSeq             ,      
           N.UMCostType         ,    
           L.AccSeq             ,    
           L.UMCostType         ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0) END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE  A.CustSeq   END          ,   --����ŷ�ó   
           --CASE WHEN @IsDivideCCtrItem = '0' AND ( A.InOutDetailKind <> 5535002 )  THEN 0 ELSE   A.GoodItemSeq   END     --������ǰ     
           CASE WHEN ( @IsDivideCCtrItem = '0'  --eykim. 110701. ������ ���� ���Ѻ������� ��õ���к� ������ ���� �����׸� ���Ե� ��ǰ�� ��ȸ���Ѿ� �Ѵ�. 
					 AND ( ( A.InOutDetailKind <> 5535002 ) OR ( A.InOutDetailKind = 5535002 AND @YAVGAdjTransType = 5536002 ) ) ) THEN 0 ELSE   A.GoodItemSeq   END,     --������ǰ     
           CASE WHEN  E.IsFromOtherAcc = '1' AND   M.AssetSeq IS NULL THEN '1'  
                ELSE '0'  
           END   
   ORDER BY A.InOutDetailKind , E.AssetSeq   
   
   
     
    INSERT INTO #TempInOut_Garbege (      
           SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,      
           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,      
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind, IsFromOtherAcc)    
    SELECT @SMSlipKind           ,      
           5513006               , --��Ÿ�������      
           A.InOutKind           , --���������      
           E.AssetSeq            , --����ڻ�з�      
           ISNULL(j.ValueSeq, 0) , --��������        
           ISNULL(K.ValueSeq, 0) , --������뱸��     
           ISNULL(L.AccSeq, 0)   , --�뺯����      
           L.UMCostType          , --�뺯��뱸��      
           SUM(A.Amt )           , --��Ÿ���ݾ�      
           1                    , --����  
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END         ,      
           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,      
           0,     --����ŷ�ó   
           0,     --������ǰ     
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
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������   
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
     --AND A.SMAdjustKind = 5513006 --��ǰ�ݾ׺���_ �������  
     AND F.MinorValue  = '0'      
     AND A.InOutKind = 8023003       --��Ÿ���  
     AND F.MinorSeq  = 6008001       
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )  
       OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))  
     AND (@YAVGAdjTransType = 5536001 ) --��õ���к��̰� ��Ÿ���� ������ ��� ��õ���� ������  
    GROUP BY E.AssetSeq         , --����ڻ�з�      
           A.InOutDetailKind    , --��Ÿ�������      
           A.InOutKind          , --���������      
      ISNULL(j.ValueSeq, 0) , --��������        
           ISNULL(K.ValueSeq, 0) , --������뱸��   
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
AVG_Mat: --������� ������ǥ_����

--2011.05.25 ����
--������ ������ǥ�̱� ������ ����� ��ü�� �Ǵ� ������ Ÿ������ �������� �ʵ��� �Ѵ�.
-- #ESMMatAcc ���

--5535001 5535 ������� �����������  
--5535002 5535 ������� ���Աݾ�����  
--5535003 5535 ������� ��Ÿ���ݾ� ����  
    
 --   EXEC dbo._SCOMEnv @CompanySeq,5555 ,0  /*@UserSeq*/,@@PROCID,@IsDivideCCtrItem OUTPUT    
 --   EXEC dbo._SCOMEnv @CompanySeq,5551 ,0  /*@UserSeq*/,@@PROCID,@YAVGAdjTransType OUTPUT    
 ----@YAVGAdjTransType
 ----��õ�����ͺ� ����	5536001
 ----����к� ����		5536002

   ---#################[��Ÿ������� ��õ�����ͺ� ������ ��� ��Ÿ����к��� �����ϰ� ������] ###################################
   
    
    INSERT INTO #TempInOut_Garbege(      
           SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,      
           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,      
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind ,IsFromOtherAcc)      
    SELECT @SMSlipKind           ,      
           A.InOutDetailKind     , --��Ÿ�������      
           A.InOutKind           , --���������      
           E.AssetSeq            , --����ڻ�з�      
           ISNULL(N.AccSeq, 0)   , --��������      
           ISNULL(N.UMCostType, 0) , --������뱸��      
           ISNULL(L.AccSeq, 0)   , --�뺯����      
           L.UMCostType          , --�뺯��뱸��      
           SUM(A.Amt )           , --��Ÿ���ݾ�      
           1                    , --����  
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE  A.CustSeq   END          ,   --����ŷ�ó   
           --CASE WHEN ( @IsDivideCCtrItem = '0' /*AND ( A.InOutDetailKind <> 5535002 )*/ ) THEN 0 ELSE   A.GoodItemSeq   END     --������ǰ     
           CASE WHEN ( @IsDivideCCtrItem = '0'  --eykim. 110701. ������ ���� ���Ѻ������� ��õ���к� ������ ���� �����׸� ���Ե� ��ǰ�� ��ȸ���Ѿ� �Ѵ�. 
					 AND ( ( A.InOutDetailKind <> 5535002 ) OR ( A.InOutDetailKind = 5535002 AND @YAVGAdjTransType = 5536002 ) ) ) THEN 0 ELSE   A.GoodItemSeq   END ,    --������ǰ     
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
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������   
               LEFT OUTER JOIN _TDAItemAssetAcc    AS N WITH(NOLOCK) ON E.CompanySeq       = N.CompanySeq      
                                                         AND E.AssetSeq         = N.AssetSeq      
                                                         AND (   (( A.InOutDetailKind = 5535002 )  
                                                                   AND  N.AssetAccKindSeq  = 22 --���Ժ�������  
                                                                  )     
                                                              OR (( A.InOutDetailKind = 5535001 )  
                                                                   AND  N.AssetAccKindSeq  = 23 --���⺸������  
                                                                  )     
                                                              OR (( A.InOutDetailKind = 5535003 )  
                                                                   AND  N.AssetAccKindSeq  = 24 --��Ÿ��������  
                                                                 )  
                                                             )     
               LEFT OUTER JOIN #AssetSeq    AS M WITH(NOLOCK) ON E.AssetSeq = M.AssetSeq 
               LEFT OUTER JOIN #ESMMatAcc   AS O ON  N.AccSeq = O.AccSeq  AND N.UMCostType = O.UMCostType
   WHERE A.CompanySeq = @CompanySeq           
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'     
     AND A.SMAdjustKind = 5513005 --����ݾ׺���_�������  
     AND F.MinorValue  = '1'      
     AND A.InOutKind = 8023003       --��Ÿ���  
     AND F.MinorSeq  <> 6008005       
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )  
       OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))  
     AND (@YAVGAdjTransType = 5536002  OR (@YAVGAdjTransType = 5536001 AND  A.InOutDetailKind <> 5535003))--��õ���к� ������ �ƴ� ��� �����Ÿ���� ���

    GROUP BY E.AssetSeq         , --����ڻ�з�      
           A.InOutDetailKind    , --��Ÿ�������      
           A.InOutKind          , --���������      
           N.AccSeq             ,      
           N.UMCostType         ,    
           L.AccSeq             ,    
           L.UMCostType         ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0) END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE  A.CustSeq   END          ,   --����ŷ�ó   
           CASE WHEN ( @IsDivideCCtrItem = '0' 
			    AND ( ( A.InOutDetailKind <> 5535002 ) OR ( A.InOutDetailKind = 5535002 AND @YAVGAdjTransType = 5536002 )  )) THEN 0 ELSE   A.GoodItemSeq   END     --������ǰ     
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
           5535003               , --��Ÿ�������      
           A.InOutKind           , --���������      
           E.AssetSeq            , --����ڻ�з�      
           ISNULL(j.ValueSeq, 0) , --��������      
           ISNULL(K.ValueSeq, 0) , --������뱸��      
           ISNULL(L.AccSeq, 0)   , --�뺯����      
           L.UMCostType          , --�뺯��뱸��      
           SUM(A.Amt )           , --��Ÿ���ݾ�      
           1                    , --����  
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq        = I.CompanySeq  --���츮      
                                                         AND A.InOutDetailKind   = I.MinorSeq      
                                                         AND I.IsUse             ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28                                                            
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq      
                                                                 AND E.AssetSeq         = L.AssetSeq      
                                                                 AND L.AssetAccKindSeq  = 1 --�ڻ�ó������   
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
     --AND A.SMAdjustKind     = 5513005 --����ݾ׺���_�������  
     AND F.MinorValue       = '1'      --����
     AND F.MinorSeq         <> 6008005       --���ǰ�� �ƴѰ� 
     AND A.InOutKind        = 8023003       --��Ÿ���  
     AND ((@FGoodPriceUnit  = 5502003 AND A.BizUnit   = @CostUnit    )  
       OR (@FGoodPriceUnit  = 5502002 AND A.AccUnit   = @CostUnit    ))  
     AND (@YAVGAdjTransType = 5536001 ) --��õ���к��̰� ��Ÿ���� ������ ��� ��õ���� ������
    
    GROUP BY E.AssetSeq         , --����ڻ�з�          
           A.InOutKind          , --���������      
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
Proc_ItemAfterProd:	--5522015 ��Ÿ�������ǥ_��ǰ(ǰ��)


    --��Ÿ�԰�    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq, GoodItemSeq   ,CustSeq )    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(L.AccSeq, 0)  , --�뺯����    
           L.UMCostType         , --�뺯��뱸��    
           ISNULL(j.ValueSeq, 0), --��������    
           ISNULL(K.ValueSeq, 0), --������뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
              JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    -- ��������
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '1002'    -- ��뱸��
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������    


		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												      AND M.Serl     = 2009	        -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText = 1
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰� 
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND ( E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL )
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           L.AccSeq       , --�뺯����    
           L.UMCostType           , --�뺯��뱸��    
           j.ValueSeq            , --��������    
           K.ValueSeq            , --������뱸��  
           A.CCtrSeq			 ,
		   A.DeptSeq   ,
		   A.ItemSeq    ,
           A.CustSeq 

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq, GoodItemSeq,CustSeq )    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(L.AccSeq, 0)  , --�뺯����    
           L.UMCostType         , --�뺯��뱸��    
           ISNULL(N.AccSeq, 0), --��������    
           ISNULL(N.UMCostType, 0), --������뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
               JOIN _TDAUMinor     AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������ 
		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                         AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												         AND M.Serl     = 2009	        -- ǰ����ǥó������
													     AND A.InOutDetailKind = M.minorseq 
													     AND M.ValueText = 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                         AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰� 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsToOtherAcc = '1'
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           L.AccSeq             , --�뺯����    
           L.UMCostType         , --�뺯��뱸��    
           N.AccSeq             , --��������    
           N.UMCostType         , --������뱸��  
           A.CCtrSeq			,
		   A.DeptSeq            ,
		   A.ItemSeq            ,
           A.CustSeq
		   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq, GoodItemSeq   ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind          , --���������    
           E.AssetSeq           , --����ڻ�з�    
           ISNULL(N.AccSeq, 0)  , --�뺯����    
           N.UMCostType         , --�뺯��뱸��    
           ISNULL(j.ValueSeq, 0), --��������    
           ISNULL(K.ValueSeq, 0), --������뱸��    
           SUM(A.Amt )          , --��Ÿ���ݾ�    
           1                    , --����    
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
              JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --��뿩��ü üũ�Ȱ͸� �����;���. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                       AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    -- ��������
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '1002'    -- ��뱸��
		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                         AND M.MajorSeq = 8025			-- ��Ÿ�԰�
												         AND M.Serl     = 2009	        -- ǰ����ǥó������
													     AND A.InOutDetailKind = M.minorseq 
													     AND M.ValueText = 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                         AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --��Ÿ�԰� 
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
    AND E.IsToOtherAcc = '1'
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind,    
           N.AccSeq       , --�뺯����    
           N.UMCostType           , --�뺯��뱸��    
           j.ValueSeq            , --��������    
           K.ValueSeq            , --������뱸��  
           A.CCtrSeq			 ,
		   A.DeptSeq   ,
		   A.ItemSeq  ,
           A.CustSeq   

    --��Ÿ���(�������� ����)
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq, GoodItemSeq ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(j.ValueSeq, 0) , --�뺯����    
           ISNULL(K.ValueSeq, 0) , --�뺯��뱸��    
           ISNULL(L.AccSeq, 0)   , --��������    
           L.UMCostType          , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           5                     , --����
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
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
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������ 

		       JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8026			-- ��Ÿ���
												      AND M.Serl     = 1005		    -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText = 1
     
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --��Ÿ���
     AND F.MinorSeq <> 6008001 
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND (E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL)
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind           , --���������    
           j.ValueSeq          , --�뺯����    
           K.ValueSeq          , --�뺯��뱸��    
           L.AccSeq             , --��������    
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
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(N.AccSeq, 0) , --�뺯����    
           ISNULL(N.UMCostType, 0) , --�뺯��뱸��    
           ISNULL(L.AccSeq, 0)   , --��������    
           L.UMCostType          , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           5                     , --����
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --�ڻ�ó������ 

		       JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                         AND M.MajorSeq = 8026			-- ��Ÿ���
												         AND M.Serl     = 1005		    -- ǰ����ǥó������
													     AND A.InOutDetailKind = M.minorseq 
													     AND M.ValueText = 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                         AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --��Ÿ���
     AND F.MinorSeq <> 6008001 
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1'
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind           , --���������    
           N.AccSeq          , --�뺯����    
           N.UMCostType          , --�뺯��뱸��    
           L.AccSeq             , --��������    
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
           A.InOutDetailKind     , --��Ÿ�������    
           A.InOutKind           , --���������    
           E.AssetSeq            , --����ڻ�з�    
           ISNULL(j.ValueSeq, 0) , --�뺯����    
           ISNULL(K.ValueSeq, 0) , --�뺯��뱸��    
           ISNULL(N.AccSeq, 0)   , --��������    
           N.UMCostType          , --������뱸��    
           SUM(A.Amt )           , --��Ÿ���ݾ�    
           5                     , --����
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
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --���츮    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
		       JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8026			-- ��Ÿ���
												      AND M.Serl     = 1005		    -- ǰ����ǥó������
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText = 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq     
                                                         AND N.AssetAccKindSeq = 21 -- Ÿ�������δ�ü  
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --��Ÿ���
     AND F.MinorSeq <> 6008001 
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1'
    GROUP BY E.AssetSeq         , --����ڻ�з�    
           A.InOutDetailKind    , --��Ÿ�������    
           A.InOutKind           , --���������    
           j.ValueSeq          , --�뺯����    
           K.ValueSeq          , --�뺯��뱸��    
           N.AccSeq             , --��������    
           N.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq  ,
		   A.ItemSeq  ,
           A.CustSeq  
    GOTO Proc_Query
RETURN 
/******************************************************************************************************/
Proc_Query: --��ȸ

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
                         CASE WHEN L.MinorName IS NULL THEN '' ELSE '��'+L.MinorName END --2011.02.17 ���� :���������� ǥ�� (������п�.)
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



    --��Ÿ�������ǥó�������豸�м���(�μ�/�ŷ�ó)
    DECLARE	@EtcGroupType  INT 

    EXEC dbo._SCOMEnv @CompanySeq, 5910,@UserSeq,@@PROCID,@EtcGroupType OUTPUT   --����ܰ������� 


    IF @SMSlipKind NOT IN (5522012,5522013,5522014) --������� ������ǥ�� �ƴҶ� 
    BEGIN 
	  
      IF @EtcGroupType =  5544001 --�μ��� ����
		
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


      ELSE  --�ŷ�ó�� ����
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
--           CASE WHEN A.InOutDetailKind = 5535002 THEN '���Աݾ׺���'
--                WHEN A.InOutDetailKind = 5535001 THEN '�����������'  
--                WHEN A.InOutDetailKind = 5535003 THEN '��Ÿ�����'  
--                ELSE  B.MinorName        END  AS InOutDetailKindName ,    
                     CASE WHEN B.MinorName IS NULL THEN 
                         CASE WHEN M.MinorName IS NULL THEN '' ELSE '��'+M.MinorName END --2011.02.17 ���� :���������� ǥ�� (������п�.)
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


