IF OBJECT_ID('KPXCM_SESMCProdMatInputItemQuery') IS NOT NULL 
    DROP PROC KPXCM_SESMCProdMatInputItemQuery
GO 

-- v2016.06.20 

/************************************************************      
 ��  �� - D-������������ : ���Գ�����ȸ-��ǰ      
 �ۼ��� - 20090623      
 �ۼ��� - ������      
      
       
************************************************************/
 CREATE PROC KPXCM_SESMCProdMatInputItemQuery
             
    @xmlDocument    NVARCHAR(MAX),                  
    @xmlFlags       INT = 0,                  
    @ServiceSeq     INT = 0,                  
    @WorkingTag     NVARCHAR(10)= '',                  
    @CompanySeq     INT = 1,                  
    @LanguageSeq    INT = 1,                  
    @UserSeq        INT = 0,                  
    @PgmSeq         INT = 0                  
                
AS                    
                
 DECLARE    @docHandle       INT ,            
            @MessageType     INT ,                
            @Status          INT ,                
            @Results         NVARCHAR(250)   ,                       
            @CostYM          CHAR(6) ,                    
            @CostUnit        INT ,                    
            @ItemSeq         INT ,                
            @CostKeySeq      INT ,            
            @SMCostMng       INT ,  
            @MatItemNo       NVARCHAR(100)   ,  
            @MatItemSeq      INT,   
            @MatItemClassSeq INT,
            @InputItemOrMat  INT,
            @AssetSeq        INT, 
            @IsProcItem      NCHAR(1) 
              
                                
    -- ���� ����Ÿ ��� ����
    CREATE TABLE #InPut (WorkingTag NCHAR(1) NULL)          
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#InPut'             
    IF @@ERROR <> 0 RETURN          

	IF (SELECT SMCostMng FROM #InPut) IN (5512002, 5512003)  --�濵��ȹ, �����ȹ
		 BEGIN     
			 SELECT  @CostKeySeq       = B.CostKeySeq  ,       
					 @CostYM           = ISNULL(A.CostYM          ,  '') ,          
					 @ItemSeq          = ISNULL(A.ItemSeq         ,  0 ) ,      
					 @SMCostMng        = ISNULL(A.SMCostMng       ,  0 ) ,       
					 @CostUnit         = ISNULL(A.CostUnit        ,  0 ) ,  
					 @MatItemNo        = ISNULL(A.MatItemNo       ,  '') ,  
					 @MatItemSeq       = ISNULL(A.MatItemSeq      ,  0 ) ,  
					 @MatItemClassSeq  = ISNULL(A.MatItemClassSeq ,  0 ) ,
					 @InputItemOrMat   = ISNULL(A.InputItemOrMat  ,  0 ) ,
					 @ItemSeq          = ISNULL(A.ItemSeq         ,  0 ) ,
					 @AssetSeq         = ISNULL(A.AssetSeq        ,  0 ), --2016.06.02 hylim ǰ���ڻ��з� �߰� 
					 @IsProcItem       = ISNULL(A.IsProcItem      , '0')
			   FROM #InPut AS A       
					JOIN _TESMDCostKey AS B WITH(NOLOCK) ON B.CompanySeq        = @CompanySeq
														AND ISNULL(A.RptUnit,0) = B.RptUnit
														AND A.CostYM            = B.CostYM
														AND A.SMCostMng         = B.SMCostMng
														AND A.CostMngAmdSeq     = B.CostMngAmdSeq
														AND B.PlanYear          = LEFT(A.CostYM, 4)
			      
			   WHERE Status = 0 
		 END
		 ELSE
		 BEGIN 
			  SELECT  @CostKeySeq     = B.CostKeySeq  ,       
				 @CostYM           = ISNULL(A.CostYM          ,  '') ,          
				 @ItemSeq          = ISNULL(A.ItemSeq         ,  0 ) ,      
				 @SMCostMng        = ISNULL(A.SMCostMng       ,  0 ) ,       
				 @CostUnit         = ISNULL(A.CostUnit        ,  0 ) ,  
				 @MatItemNo        = ISNULL(A.MatItemNo       ,  '') ,  
				 @MatItemSeq       = ISNULL(A.MatItemSeq      ,  0 ) ,  
				 @MatItemClassSeq  = ISNULL(A.MatItemClassSeq ,  0 ) ,
				 @InputItemOrMat   = ISNULL(A.InputItemOrMat  ,  0 ) ,
				 @ItemSeq          = ISNULL(A.ItemSeq         ,  0 ) ,
				 @AssetSeq         = ISNULL(A.AssetSeq        ,  0 ), --2016.06.02 hylim ǰ���ڻ��з� �߰�
				 @IsProcItem       = ISNULL(A.IsProcItem      , '0')
		        FROM #InPut AS A       
					JOIN _TESMDCostKey AS B WITH(NOLOCK) ON B.CompanySeq         = @CompanySeq
													    AND ISNULL(A.RptUnit, 0) = B.RptUnit
													    AND A.CostYM             = B.CostYM
													    AND A.SMCostMng          = B.SMCostMng
													    AND A.CostMngAmdSeq      = B.CostMngAmdSeq
													    AND B.PlanYear           = ''
			  WHERE Status = 0
	   END  

    DECLARE @cItemClss INT       
    SELECT @cItemClss   = EnvValue FROM _TComEnv WHERE EnvSeq = 5509  And CompanySeq = @CompanySeq     
      
    --5028001	5028	���纰 �հ�
    --5028002	5028	��ǰ�� �հ�
    
    
    CREATE TABLE #Result 
    (
        MatItemNo           NVARCHAR(200), 
        MatItemNm           NVARCHAR(200), 
        MatItemSpec         NVARCHAR(200), 
        Qty                 DECIMAL(19,5), 
        Amt                 DECIMAL(19,5), 
        MatAccName          NVARCHAR(200), 
        MatItemSeq          INT, 
        MatItemClassName    NVARCHAR(200), 
        MatItemClass        INT, 
        AssetSeq            INT, 
        AssetName           NVARCHAR(200) 
    )
    
    
    
    IF @InputItemOrMat = 5028001    --���纰 �հ� ���纰�� ���Լ��� �� ���Աݾ��� �հ� ��ȸ    
    BEGIN
            
            INSERT INTO #Result 
            (
                MatItemNo, MatItemNm, MatItemSpec, Qty, Amt, 
                MatAccName, MatItemSeq, MatItemClassName, MatItemClass, AssetSeq, 
                AssetName
            )
            SELECT ISNULL(F.ItemNo, '') AS MatItemNo , ISNULL(F.ItemName, '') AS MatItemNm ,  ISNULL(F.Spec , '') AS MatItemSpec    ,         
                   SUM(A.Qty)   AS Qty  , SUM(A.Amt)   AS Amt  , 
                   CASE WHEN ISNULL(C.AccName , '') = '' THEN '' 
                        ELSE ISNULL(C.AccName , '') + '(' + RTRIM(ISNULL(E.MinorName, '')) +')'  END AS  MatAccName   ,    
                   A.MatItemSeq    , ISNULL(I.ItemClasSName , '') AS MatItemClassName   , ISNULL(I.ITemClassSSeq , '') AS MatItemClass    ,
                   F.AssetSeq      , N.AssetName
             FROM _TESMCProdFMatInput    AS A WITH(NOLOCK)
                                      JOIN _TDAItem      AS F WITH(NOLOCK) ON A.MatItemSeq  = F.ItemSeq  AND A.CompanySeq = F.CompanySeq         
                           LEFT OUTER JOIN _TDAAccount   AS C WITH(NOLOCK) ON A.MatAccSeq   = C.AccSeq   AND C.CompanySeq = @CompanySeq       
                           LEFT OUTER JOIN _TDAUMinor    AS E WITH(NOLOCK) ON A.UMCostType  = E.MinorSeq AND E.CompanySeq = @CompanySeq     
                           LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq,0) AS I ON A.MatItemSeq = I.ITemSeq 
                           LEFT OUTER JOIN _TDAItemAsset AS N WITH(NOLOCK) ON N.AssetSeq    = F.AssetSeq AND N.CompanySeq  = F.CompanySeq
            WHERE  A.CostKeySeq = @CostkeySeq       
              AND A.CostUnit    = @CostUnit       
              AND A.CompanySeq  = @CompanySeq        
              AND F.ItemNo LIKE @MatItemNo + '%'
              AND (@MatItemSeq  = 0  OR A.MatItemSeq = @MatItemSeq) --2016.06.15 hylim �����ڵ带 ������ �� �ֵ��� ���� (@ItemSeq  = 0  OR A.MatItemSeq = @ItemSeq)
              AND (@MatItemClassSeq = 0 OR @MatItemClassSeq = I.ITemClassSSeq)
              AND (@AssetSeq = 0 OR N.SMAssetGrp = @AssetSeq) --2016.06.02 hylim ǰ���ڻ��з� �߰�
            GROUP BY F.ItemNo, F.ItemName , F.Spec , C.AccName , E.MinorName , A.MatItemSeq , I.ItemClasSName , I.ITemClassSSeq , F.AssetSeq , N.AssetName
            ORDER BY F.ItemNo

    END
    ELSE IF  @InputItemOrMat = 5028002    --��ǰ�� �հ� ��ǰ�� ����Ŭ���Ҷ� ���Ե� ������� ����Ʈ ��ȸ   
    BEGIN       
            INSERT INTO #Result 
            (
                MatItemNo, MatItemNm, MatItemSpec, Qty, Amt, 
                MatAccName, MatItemSeq, MatItemClassName, MatItemClass, AssetSeq, 
                AssetName
            )
            SELECT ISNULL(F.ItemNo, '') AS MatItemNo , ISNULL(F.ItemName, '') AS MatItemNm ,  ISNULL(F.Spec , '') AS MatItemSpec ,         
                   SUM(A.Qty )  AS Qty  , SUM( A.Amt )  AS Amt  , 
                   CASE WHEN ISNULL(C.AccName , '') = '' THEN '' 
                        ELSE ISNULL(C.AccName , '') + '(' +  RTRIM(ISNULL(E.MinorName, '')) +')'  END AS  MatAccName   ,    
                   A.MatItemSeq    , ISNULL(I.ItemClasSName , '') AS MatItemClassName    , ISNULL(I.ITemClassSSeq , '') AS MatItemClass,
                   F.AssetSeq      , N.AssetName          
            FROM _TESMCProdFMatInput     AS A WITH(NOLOCK)
                                       JOIN _TDAItem      AS F WITH(NOLOCK) ON A.MatItemSeq  = F.ItemSeq  AND A.CompanySeq = F.CompanySeq             
                            LEFT OUTER JOIN _TDAAccount   AS C WITH(NOLOCK) ON A.MatAccSeq   = C.AccSeq   AND C.CompanySeq = @CompanySeq       
                            LEFT OUTER JOIN _TDAUMinor    AS E WITH(NOLOCK) ON A.UMCostType  = E.MinorSeq AND E.CompanySeq = @CompanySeq      
                            LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq,0)  AS I ON A.MatItemSeq = I.ITemSeq 
                            LEFT OUTER JOIN _TDAItemAsset AS N WITH (NOLOCK)ON N.AssetSeq    = F.AssetSeq AND N.CompanySeq  = F.CompanySeq
             WHERE A.CostKeySeq = @CostkeySeq       
              AND A.CostUnit    = @CostUnit       
              AND A.CompanySeq  = @CompanySeq
              AND F.ItemNo LIKE @MatItemNo + '%'
              AND (@ItemSeq = 0 OR A.ItemSeq = @ItemSeq)
              AND (@MatItemClassSeq = 0 OR @MatItemClassSeq = I.ITemClassSSeq) 
              AND ((@PgmSeq = 10376  AND N.SMAssetGrp <> 6008005) OR @PgmSeq <> 10376)  --ǰ�� ǰ���ڻ� ���Ժ���ȸ������ ���ǰ �Ⱥ����ش�. 
              AND (@AssetSeq = 0 OR N.SMAssetGrp = @AssetSeq) --2016.06.02 hylim ǰ���ڻ��з� �߰�
            GROUP BY F.ItemNo, F.ItemName , F.Spec , C.AccName , E.MinorName , A.MatItemSeq , I.ItemClasSName , I.ITemClassSSeq ,  F.AssetSeq , N.AssetName   
            ORDER BY F.ItemNo       
    END       
    ELSE 
    BEGIN  
            INSERT INTO #Result 
            (
                MatItemNo, MatItemNm, MatItemSpec, Qty, Amt, 
                MatAccName, MatItemSeq, MatItemClassName, MatItemClass, AssetSeq, 
                AssetName
            )
            SELECT ISNULL(F.ItemNo, '') AS MatItemNo , ISNULL(F.ItemName, '') AS MatItemNm ,  ISNULL(F.Spec , '') AS MatItemSpec ,         
                   A.Qty   AS Qty  , A.Amt   AS Amt  , 
                   CASE WHEN ISNULL(C.AccName , '') = '' THEN '' 
                        ELSE ISNULL(C.AccName , '') + '(' +  RTRIM(ISNULL(E.MinorName, '')) +')'  END AS  MatAccName   ,    
                   A.MatItemSeq    , ISNULL(I.ItemClasSName, '') AS MatItemClassName    , ISNULL(I.ITemClassSSeq, '') AS MatItemClass,
                   F.AssetSeq      , N.AssetName  
             FROM _TESMCProdFMatInput     AS A WITH(NOLOCK)
                                        JOIN _TDAItem      AS F WITH(NOLOCK) ON A.MatItemSeq  = F.ItemSeq  AND A.CompanySeq = F.CompanySeq             
                             LEFT OUTER JOIN _TDAAccount   AS C WITH(NOLOCK) ON A.MatAccSeq   = C.AccSeq   AND C.CompanySeq = @CompanySeq       
                             LEFT OUTER JOIN _TDAUMinor    AS E WITH(NOLOCK) ON A.UMCostType  = E.MinorSeq AND E.CompanySeq = @CompanySeq      
                             LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq,0)  AS I ON A.MatItemSeq = I.ITemSeq 
                             LEFT OUTER JOIN _TDAItemAsset AS N WITH (NOLOCK) ON N.AssetSeq    = F.AssetSeq AND N.CompanySeq  = F.CompanySeq   
            WHERE A.CostKeySeq  = @CostkeySeq       
              AND A.CostUnit    = @CostUnit       
              AND A.CompanySeq  = @CompanySeq     
              AND F.ItemNo LIKE @MatItemNo + '%'
              AND (@MatItemSeq  = 0  OR A.MatItemSeq = @MatItemSeq) 
              AND (@MatItemClassSeq = 0 OR @MatItemClassSeq = I.ITemClassSSeq) 
              AND (@AssetSeq = 0 OR N.SMAssetGrp = @AssetSeq) --2016.06.02 hylim ǰ���ڻ��з� �߰�
            ORDER BY F.ItemNo
    END    
    
    IF @IsProcItem = '1' -- ���ǰ ���� 
    BEGIN
        DELETE 
          FROM #Result 
         WHERE AssetSeq IN (
                            SELECT AssetSeq  
                              FROM _TDAItemAsset AS A 
                             WHERE A.CompanySeq = @CompanySeq   
                               AND A.SMAssetGrp = 6008005 
                           )
    END 
    
    SELECT * FROM #Result 
    
    RETURN
GO


