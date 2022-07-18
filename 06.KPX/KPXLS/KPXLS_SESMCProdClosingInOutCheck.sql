IF OBJECT_ID('KPXLS_SESMCProdClosingInOutCheck') IS NOT NULL 
    DROP PROC KPXLS_SESMCProdClosingInOutCheck
GO 

-- v2016.02.16 

-- KPXLS�� ���ึ�� �����층 by����õ 

/************************************************************
  ��  �� - D-������������ : ������������Ȯ��(���Ҿ�������ȭ�鿡�� üũ)
  �ۼ��� - 2010.10.11
  �ۼ��� - ������
  ������ - 2011.01.10 ���� : ��ǰ�� ������ ����üũ�� ����ϴ� ��ǥ ������. 
  ��ǥ�����ڵ� ��ǥ����          ���� ��ǰ/��ǰ
 5522001 �������� �����ü          V V
 5522002 �������� ��ǥó��             V V
 5522003 ������� ��ǥó��             V V
 5522004 ��Ÿ�������ǥ_����             V 
 5522005 ��Ÿ�������ǥ_��ǰ              V
 5522006 ��Ÿ�������ǥ_��ǰ              V
 5522007 ��Ÿ�������ǥ_��ǰ���������  V
 5522008 ���� ��ǥó��                 V V
 5522009 ������Ʈ ���� ��ü ��ǥó�� V V
 5522010 ������Ʈ ��ǥó��             V V
 5522011 ������Ʈ ���� ��ü ��ǥó��     V V
 5522012 ������� ������ǥ_��ǰ          V
 5522013 ������� ������ǥ_����         V 
 5522014 ������� ������ǥ_��ǰ          V
 5522015 ��Ÿ�������ǥ_��ǰ(ǰ��)      V
 5522016 ��������ǥó��          V   V
  
 ************************************************************/
 CREATE PROC KPXLS_SESMCProdClosingInOutCheck
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
  AS  
     DECLARE @MessageType        INT,
             @Status             INT,
             @Results            NVARCHAR(250),
             @CostUnitKind       INT,
             @EnvValue           INT,
             @SMCostMng          INT,
             @ItemPriceUnit      INT,
             @GoodPriceUnit      INT,
             @FGoodPriceUnit     INT,
             @ProfCostUnitKind   INT
      -- ���� ����Ÿ ��� ����
     CREATE TABLE #TESMCProdClosing (WorkingTag NCHAR(1) NULL)  
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TESMCProdClosing'     
     IF @@ERROR <> 0 RETURN    
    
    CREATE TABLE #TSMCostMng
    (
        SMCostMng INT
    ) 

    --select * from _TESMDCostKey
    --select * from _TDASMinor where CompanySeq = 1 and MajorSeq = 5512  
    
    SELECT @EnvValue = EnvValue FROM _TComEnv WHERE EnvSeq = 5531  AND CompanySeq = @CompanySeq --����������(�⺻���� 5518001, Ȱ�����ؿ��� 5518002)  
    
    IF @EnvValue = 5518001
    BEGIN
        INSERT #TSMCostMng
        SELECT 5512004
        
        INSERT #TSMCostMng
        SELECT 5512006
    END
    ELSE IF @EnvValue = 5518002
    BEGIN
        INSERT #TSMCostMng
        SELECT 5512001
        
        INSERT #TSMCostMng
        SELECT 5512005
    END
  
    IF NOT EXISTS (SELECT * FROM #TSMCostMng) --���������ȵǾ� ���� ��� return
    BEGIN
        SELECT * FROM #TESMCProdClosing
        RETURN
    END
    
    SELECT @CostUnitKind     = EnvValue FROM _TComEnv WHERE EnvSeq = 5524  AND CompanySeq = @CompanySeq --��������������(�������� or ȸ�����)
    SELECT @ProfCostUnitKind = EnvValue FROM _TComEnv WHERE EnvSeq = 5518  AND CompanySeq = @CompanySeq --�ѿ���������  (ȸ����� or����ι�)--������Ʈ ��ǥ����..
    SELECT @ItemPriceUnit    = EnvValue FROM _TComEnv WHERE EnvSeq = 5521  AND CompanySeq = @CompanySeq --����ܰ�������(ȸ����� or����ι�)    
    SELECT @GoodPriceUnit    = EnvValue FROM _TComEnv WHERE EnvSeq = 5522  AND CompanySeq = @CompanySeq --��ǰ�ܰ�������(ȸ����� or����ι�)            
    SELECT @FGoodPriceUnit   = EnvValue FROM _TComEnv WHERE EnvSeq = 5523  AND CompanySeq = @CompanySeq --��ǰ�ܰ�������(ȸ����� or����ι�) 
    
    --CostUnit���� ���
    DECLARE @CostUnitList TABLE
    (
        AccUnit INT,
        AccUnitName NVARCHAR(100),
        BizUnit INT,
        BizUnitName NVARCHAR(100),
        FactUnit INT,
        FactUnitName NVARCHAR(50)
    )
    INSERT @CostUnitList
    SELECT A.AccUnit, ISNULL(A.AccUnitName, '') AS AccUnitName, ISNULL(B.BizUnit, 0) AS BizUnit, ISNULL(B.BizUnitName, '') AS BizUnitName, ISNULL(C.FactUnit, 0) AS FactUnit, ISNULL(C.FactUnitName, '') AS FactUnitName
         
      FROM _TDAAccUnit AS A WITH(NOLOCK)
      LEFT OUTER JOIN _TDABizUnit AS  B WITH(NOLOCK) ON A.AccUnit = B.AccUnit AND A.CompanySeq = B.CompanySeq 
      LEFT OUTER JOIN _TDAFactUnit AS C WITH(NOLOCK) ON B.BizUnit = C.BizUnit AND B.CompanySeq = C.CompanySeq 
     WHERE A.CompanySeq = @CompanySeq
    
    -------------------------------------------
    -- �ߺ�����üũ
    -------------------------------------------                          
     
     
    /*������ Ǯ��� ��ǥ�� ������ �� �����ϱ� ������������ üũ����. */
    -------------------------------------------
    -- ��������üũ
    -------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          1249               , -- @3(@2) �� ���������� �����Ǿ� ����� �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1249)  
                          @LanguageSeq         -- ex)�ȼ�����(��������) �� ���������� �����Ǿ� ����� �� �����ϴ�.
                                
    SELECT @Results = REPLACE(@Results, '@2', Word) FROM _TCADictionary where WordSeq=2074 AND LanguageSeq = @LanguageSeq --#������������(ȸ�����/��������)
    
    --���������� ������������������ �Ѵ�. 
    UPDATE #TESMCProdClosing  
       SET Result = CONVERT(NVARCHAR(7) , CONVERT(DATETIME, B.ClosingYM+'01'), 120) + ' ' 
                    + REPLACE(@Results, '@3', ISNULL(CASE @CostUnitKind WHEN 5502001 THEN C.FactUnitName ELSE C.AccUnitName END,'')),  
           MessageType = @MessageType,  
           Status = @Status  
      FROM #TESMCProdClosing AS A 
      JOIN (
                SELECT C.BizUnit AS UnitSeq, D.DtlUnitSeq, MAX(B.CostYM) AS ClosingYM, MAX(A.CostUnit) AS CostUnit
                  FROM _TESMCProdClosing    AS A WITH(NOLOCK) 
                  JOIN _TESMDCostKey        AS B WITH(NOLOCK) ON A.CostKeySeq = B.CostKeySeq 
                                                             AND B.RptUnit       = 0 
                                                             AND B.CostMngAmdSeq = 0 
                                                             AND B.PlanYear      = '' 
                                                             AND A.CompanySeq    = B.Companyseq
                  JOIN @CostUnitList        AS C              ON A.CostUnit = CASE @CostUnitKind WHEN 5502001 THEN C.FactUnit ELSE C.AccUnit END
                  JOIN #TESMCProdClosing    AS D WITH(NOLOCK) ON D.UnitSeq = C.BizUnit 
                                                             AND D.ClosingSeq    = 69
                                                             AND D.IsClose       = '0' 
                                                             AND D.Status        = 0
                  LEFT OUTER JOIN _TCOMClosingYM    AS E WITH(NOLOCK) ON E.ClosingYM = D.ClosingYM
                                                                     AND E.UnitSeq = D.UnitSeq
                                                                     AND E.DtlUnitSeq = D.DtlUnitSeq
                                                                     AND E.ClosingSeq = 69
                 WHERE A.CompanySeq = @CompanySeq 
                   AND A.IsClosing = '1'
                   AND D.IsClose <> ISNULL(E.IsClose, '0')
                   AND B.SMCostMng     IN(SELECT SMCostMng FROM #TSMCostMng) 
                 GROUP BY C.BizUnit, D.DtlUnitSeq
           ) AS B ON A.UnitSeq = B.UnitSeq AND A.DtlUnitSeq = B.DtlUnitSeq AND A.ClosingYM <= B.ClosingYM --���Ҹ����� Ǯ���� �ϴ� ������ ���������� ���� �� ū ���̳� ���� ���� ������ ���� ��Ǭ��
      LEFT OUTER JOIN @CostUnitList AS C ON B.CostUnit      = CASE @CostUnitKind WHEN 5502001 THEN C.FactUnit ELSE C.AccUnit END
     WHERE A.Status = 0
    
    -- ���� SP Call ����
    
    -------------------------------------------
    -- ��ǥó������üũ
    -------------------------------------------
    --5522001 �������� �����ü
    --5522002 �������� ��ǥó��
    --5522003 ������� ��ǥó��
    --5522004 ��Ÿ�������ǥ_����
    --5522005 ��Ÿ�������ǥ_��ǰ
    --5522006 ��Ÿ�������ǥ_��ǰ
    --5522007 ��Ÿ�������ǥ_��ǰ���������
    --5522008 ���� ��ǥó��
    --5522009 ������Ʈ ���� ��ü ��ǥó��
    --5522010 ������Ʈ ��ǥó��
    --5522011 ������Ʈ ���� ��ü ��ǥó��
    --5522012 ������� ������ǥ_��ǰ
    --5522013 ������� ������ǥ_����
    --5522014 ������� ������ǥ_��ǰ
    --5522015 ��Ÿ�������ǥ_��ǰ(ǰ��)
    --5522016 ��������ǥó��
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          1250               , -- ��ǥó��(@3)�� �����Ͱ� �����Ͽ� ���Ҹ����� ����� �� �����ϴ�(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1250)  
                          @LanguageSeq       
    
    UPDATE #TESMCProdClosing  
       SET Result        = CONVERT(NVARCHAR(7) , CONVERT(DATETIME, B.ClosingYM+'01'), 120) + ' ' + REPLACE(@Results, '@3', ISNULL(D.MinorName,'')),  
           MessageType   = @MessageType,  
           Status        = @Status  
      FROM #TESMCProdClosing AS A 
                         JOIN (
                                 SELECT C.BizUnit AS UnitSeq, D.DtlUnitSeq, MAX(B.CostYM) AS ClosingYM, 
                                        A.TransSeq
 --                                        (SELECT TOP 1 TransSeq FROM _TESMCProdSlipM WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CostKeySeq = MAX(B.CostKeySeq) ORDER BY LastDateTime DESC) AS TransSeq
                                   FROM _TESMCProdSlipM   AS A WITH(NOLOCK) 
                                                 JOIN _TESMDCostKey     AS B WITH(NOLOCK) ON A.CostKeySeq    = B.CostKeySeq 
                                                                                         AND B.RptUnit       = 0 
                                                                                         AND B.CostMngAmdSeq = 0 
                                                                                         AND B.PlanYear      = '' 
                                                                                         AND A.CompanySeq    = B.Companyseq
                                                 JOIN @CostUnitList     AS C              ON A.CostUnit      = CASE WHEN A.SMSlipKind IN (5522001,5522002,5522003,5522016)   --���������������� ��ϵ� ��ǥ�� ���     
                                                                                                                         THEN CASE @CostUnitKind WHEN 5502001 THEN C.FactUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522004,5522013)                   --����ܰ��������� ��ϵ� ��ǥ�� ���     
                                                                                                                         THEN CASE @ItemPriceUnit WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522005,5522014)                   --��ǰ�ܰ��������� ��ϵ� ��ǥ�� ���     
                                                                                                                         THEN CASE @GoodPriceUnit WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522006,5522007,5522012,5522015)   --��ǰ�ܰ��������� ��ϵ� ��ǥ�� ���     
                                                                                                                         THEN CASE @FGoodPriceUnit WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522009,5522010,5522011)           --������Ʈ��ǥó���� ��� �ѿ���������...  
                                               THEN CASE @ProfCostUnitKind WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522008)                           --������ǥó��(ȸ�������...)
                                                                                                                         THEN C.AccUnit
                                                                                                                    ELSE 0 END
                                                 JOIN #TESMCProdClosing AS D WITH(NOLOCK) ON D.UnitSeq       = C.BizUnit 
                                                                                         AND D.ClosingSeq    = 69
                                                                                         AND D.IsClose       = '0' 
                                                                                         AND D.Status        = 0
                                      LEFT OUTER JOIN _TCOMClosingYM    AS E WITH(NOLOCK) ON E.ClosingYM     = D.ClosingYM
                                                                                         AND E.UnitSeq       = D.UnitSeq
                                                                                         AND E.DtlUnitSeq    = D.DtlUnitSeq
                                                                                         AND E.ClosingSeq    = 69                                                                                        
                                                 --JOIN _TACSlipRow       AS F WITH(NOLOCK) ON A.SlipSeq       = F.SlipSeq
                                                 --                                        AND A.CompanySeq    = F.CompanySeq
                                                 --JOIN _TACSlip          AS G WITH(NOLOCK) ON F.SlipMstSeq    = G.SlipMstSeq
                                                 --                                        AND F.CompanySeq    = G.CompanySeq select * from _TDASminor where Majorseq = 5522 and companySeq=1
                                  WHERE A.CompanySeq = @CompanySeq 
                                    AND A.SlipSeq <> 0
                                    --AND G.IsSet = '1' -- ��ǥ���εȰ�?
                                    AND D.IsClose <> ISNULL(E.IsClose, '0')
                                    AND D.DtlUnitSeq = 1 --�����ϰ�� 
                                    AND A.SMSlipKind NOT IN (5522005,5522006,5522007,5522012,5522014,5522015,5522016)
                                    AND B.SMCostMng     IN(SELECT SMCostMng FROM #TSMCostMng) 
                                  GROUP BY C.BizUnit, D.DtlUnitSeq, A.TransSeq
                              ) AS B ON A.UnitSeq = B.UnitSeq AND A.DtlUnitSeq = B.DtlUnitSeq AND A.ClosingYM <= B.ClosingYM --���Ҹ����� Ǯ���� �ϴ� ������ ������ǥó���� ���� �� ū ���̳� ���� �� ������ ���� ��Ǭ��
                         JOIN _TESMCProdSlipM AS C WITH(NOLOCK) ON C.TransSeq = B.TransSeq AND C.CompanySeq = @CompanySeq
              LEFT OUTER JOIN _TDASMinor AS D WITH(NOLOCK) ON C.SMSlipKind = D.MinorSeq AND C.CompanySeq = D.CompanySeq
      WHERE A.Status = 0  
     UPDATE #TESMCProdClosing  
        SET Result        = CONVERT(NVARCHAR(7) , CONVERT(DATETIME, B.ClosingYM+'01'), 120) + ' ' + REPLACE(@Results, '@3', ISNULL(D.MinorName,'')),  
            MessageType   = @MessageType,  
            Status        = @Status  
       FROM #TESMCProdClosing AS A 
                         JOIN (
                                 SELECT C.BizUnit AS UnitSeq, D.DtlUnitSeq, MAX(B.CostYM) AS ClosingYM, 
                                        A.TransSeq
 --                                        (SELECT TOP 1 TransSeq FROM _TESMCProdSlipM WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CostKeySeq = MAX(B.CostKeySeq) ORDER BY LastDateTime DESC) AS TransSeq
                                   FROM _TESMCProdSlipM   AS A WITH(NOLOCK) 
                                                 JOIN _TESMDCostKey     AS B WITH(NOLOCK) ON A.CostKeySeq    = B.CostKeySeq  
                                                                                         AND B.RptUnit       = 0 
                                                                                         AND B.CostMngAmdSeq = 0 
                                                                                         AND B.PlanYear      = '' 
                                                                                         AND A.CompanySeq    = B.Companyseq
                                                 JOIN @CostUnitList     AS C              ON A.CostUnit      = CASE WHEN A.SMSlipKind IN (5522001,5522002,5522003,5522016)   --���������������� ��ϵ� ��ǥ�� ���     
                                                                                                                         THEN CASE @CostUnitKind WHEN 5502001 THEN C.FactUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522004,5522013)                   --����ܰ��������� ��ϵ� ��ǥ�� ���     
                                                                                                                         THEN CASE @ItemPriceUnit WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522005,5522014)                   --��ǰ�ܰ��������� ��ϵ� ��ǥ�� ���     
                                                                                                                         THEN CASE @GoodPriceUnit WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522006,5522007,5522012,5522015)   --��ǰ�ܰ��������� ��ϵ� ��ǥ�� ���     
                                                                                                                         THEN CASE @FGoodPriceUnit WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522009,5522010,5522011)           --������Ʈ��ǥó���� ��� �ѿ���������...  
                                                                                                                         THEN CASE @ProfCostUnitKind WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522008)                           --������ǥó��(ȸ�������...)
                                                                                                                         THEN C.AccUnit
                                                                                                                    ELSE 0 END
                                                 JOIN #TESMCProdClosing AS D WITH(NOLOCK) ON D.UnitSeq       = C.BizUnit 
                                                                                         AND D.ClosingSeq    = 69
                                                                                         AND D.IsClose       = '0' 
                                                                                         AND D.Status        = 0
                                      LEFT OUTER JOIN _TCOMClosingYM    AS E WITH(NOLOCK) ON E.ClosingYM     = D.ClosingYM
                                                                                         AND E.UnitSeq       = D.UnitSeq
                                                                                         AND E.DtlUnitSeq    = D.DtlUnitSeq
                                                                                         AND E.ClosingSeq    = 69                                                                              
                                                 --JOIN _TACSlipRow       AS F WITH(NOLOCK) ON A.SlipSeq       = F.SlipSeq
                                                 --                                        AND A.CompanySeq    = F.CompanySeq
     --JOIN _TACSlip          AS G WITH(NOLOCK) ON F.SlipMstSeq    = G.SlipMstSeq
                                                 --                                        AND F.CompanySeq    = G.CompanySeq select * from _TDASminor where Majorseq = 5522 and companySeq=1
                                  WHERE A.CompanySeq = @CompanySeq 
                                    AND A.SlipSeq <> 0
                                    --AND G.IsSet = '1' -- ��ǥ���εȰ�?
                                    AND D.IsClose <> ISNULL(E.IsClose, '0')
                                     AND D.DtlUnitSeq = 2 --��ǰ/��ǰ�ϰ�� 
                                     AND A.SMSlipKind NOT IN (5522004,5522013)
                                     AND B.SMCostMng     IN(SELECT SMCostMng FROM #TSMCostMng) 
                                  GROUP BY C.BizUnit, D.DtlUnitSeq, A.TransSeq
                              ) AS B ON A.UnitSeq = B.UnitSeq AND A.DtlUnitSeq = B.DtlUnitSeq AND A.ClosingYM <= B.ClosingYM --���Ҹ����� Ǯ���� �ϴ� ������ ������ǥó���� ���� �� ū ���̳� ���� �� ������ ���� ��Ǭ��
                         JOIN _TESMCProdSlipM AS C WITH(NOLOCK) ON C.TransSeq = B.TransSeq AND C.CompanySeq = @CompanySeq
              LEFT OUTER JOIN _TDASMinor AS D WITH(NOLOCK) ON C.SMSlipKind = D.MinorSeq AND C.CompanySeq = D.CompanySeq
      WHERE A.Status = 0   
     
     -------------------------------------------
     -- ���࿩��üũ
     -------------------------------------------
     -- ���� SP Call ����
      -------------------------------------------
     -- Ȯ������üũ
     -------------------------------------------
      -------------------------------------------
     -- INSERT ��ȣ�ο�(�� ������ ó��)
     ------------------------------------------- 
    
   
-----------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------KPX�� ���� üũ���� �߰�----------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
	DECLARE  @AccUnit INT, @UnitSeq INT, @BizUnit INT      
	DECLARE @Cnt INT, @MaxCnt INT, @DateFr NCHAR(8), @DateTo NCHAR(8), @MinorValue INT, @ClosingSeq INT     


	SELECT @ClosingSeq = MAX(ClosingSeq) FROM #TESMCProdClosing WHERE Status = 0 
	IF @ClosingSeq IN (69)	
	BEGIN

	----------���̳ʽ� ��� üũ---------------

    /*
        select * from _TComEnv where CompanySeq = 1 and EnvSeq  = 5521 

    */
        -- ȯ�漳��-Ȱ�����ؿ��� 
    SELECT @ItemPriceUnit = EnvValue FROM _TCOMEnv WHERE EnvSeq  = 5521  And CompanySeq = @CompanySeq --����ܰ�������                       
    SELECT @GoodPriceUnit = EnvValue FROM _TCOMEnv WHERE EnvSeq  = 5522  And CompanySeq = @CompanySeq --��ǰ�ܰ�������                       
    SELECT @FGoodPriceUnit = EnvValue FROM _TCOMEnv WHERE EnvSeq = 5523  And CompanySeq = @CompanySeq --��ǰ�ܰ�������                       
    
	
    -- ����/��������Ҽ����ڸ������ϱ�
    --SELECT @EnvMatQty = EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 5
    
    -- ����ι���� : ����ι� & ȸ����� 
	SELECT @UnitSeq = MAX(UnitSeq)		 FROM #TESMCProdClosing  

	

    SELECT  @AccUnit = ISNULL(A.AccUnit	,0)
		   ,@BizUnit = ISNULL(A.BizUnit	,0)
   
		FROM _TDABizUnit AS A 
		WHERE A.CompanySeq	=	@CompanySeq
		  AND A.BizUnit		=	@UnitSeq

    
	
	
    -- ���ǰ�� 
    CREATE TABLE #GetInOutItem
    ( 
        ItemSeq INT, 
        ItemClassSSeq INT, ItemClassSName NVARCHAR(200), -- ǰ��Һз�
        ItemClassMSeq INT, ItemClassMName NVARCHAR(200), -- ǰ���ߺз�
        ItemClassLSeq INT, ItemClassLName NVARCHAR(200)  -- ǰ���з�
    )
    

   
    -- �����
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
    
    -- ��������� 
    CREATE TABLE #TLGInOutStock  
    (  
        InOutType INT,  
        InOutSeq  INT,  
        InOutSerl INT,  
        DataKind  INT,  
        InOutSubSerl  INT,  
        
        InOut INT,  
        InOutDate NCHAR(8),  
        WHSeq INT,  
        FunctionWHSeq INT,  
        ItemSeq INT,  
        
        UnitSeq INT,  
        Qty DECIMAL(19,5),  
        StdQty DECIMAL(19,5),
        InOutKind INT,
        InOutDetailKind INT 
    )  
    
 
	 SELECT @MaxCnt = MAX(IDX_NO),
			@Cnt	= 1 
	 FROM #TESMCProdClosing 
	 WHERE IsClose = '1'
    

	----�ݺ� ����
	WHILE (@Cnt <= @MaxCnt)
	BEGIN

		-- ��¥ ����
	SELECT	  @DateFr = CONVERT(NCHAR(6),MAX(ClosingYM))+'01' 
			, @DateTo = CONVERT(NCHAR(8),DATEADD(DD,-1,DATEADD(MM,1,CONVERT(NCHAR(6),MAX(ClosingYM))+'01' )),112)
			, @MinorValue = CASE WHEN MAX(DtlUnitSeq) = 1 THEN 1 ELSE 0 END
	FROM #TESMCProdClosing
	WHERE IDX_NO = @Cnt
	  AND IsClose = '1'





	
	TRUNCATE TABLE #GetInOutItem
	TRUNCATE TABLE #GetInOutStock
	TRUNCATE TABLE #TLGInOutStock

	-- ���ǰ�� ��� 

    INSERT INTO #GetInOutItem

    ( 
        ItemSeq, 
        ItemClassSSeq, ItemClassSName, -- ǰ��Һз�
        ItemClassMSeq, ItemClassMName, -- ǰ���ߺз�
        ItemClassLSeq, ItemClassLName  -- ǰ���з�
    )
    SELECT DISTINCT A.ItemSeq,
           C.MinorSeq AS ItemClassSSeq, C.MinorName AS ItemClassSName, -- 'ǰ��Һз�' 
	       E.MinorSeq AS ItemClassMSeq, E.MinorName AS ItemClassMName, -- 'ǰ���ߺз�' 
	       G.MinorSeq AS ItemClassLSeq, G.MinorName AS ItemClassLName  -- 'ǰ���з�' 

	  
     FROM _TDAItem                     AS A WITH (NOLOCK)
      JOIN _TDAItemSales                AS H WITH (NOLOCK) ON A.CompanySeq = H.CompanySeq AND A.ItemSeq = H.ItemSeq 
      JOIN _TDAItemAsset                AS I WITH (NOLOCK) ON A.CompanySeq = I.CompanySeq AND A.AssetSeq = I.AssetSeq -- ǰ���ڻ�з� 
      
      -- �Һз� 
      LEFT OUTER JOIN _TDAItemClass	    AS B WITH(NOLOCK) ON ( A.ItemSeq = B.ItemSeq AND B.UMajorItemClass IN (2001,2004) AND A.CompanySeq = B.CompanySeq )
      LEFT OUTER JOIN _TDAUMinor		AS C WITH(NOLOCK) ON ( B.UMItemClass = C.MinorSeq AND B.CompanySeq = C.CompanySeq AND C.IsUse = '1' )
      LEFT OUTER JOIN _TDAUMinorValue	AS D WITH(NOLOCK) ON ( C.MinorSeq = D.MinorSeq AND D.Serl in (1001,2001) AND C.MajorSeq = D.MajorSeq AND C.CompanySeq = D.CompanySeq )
      -- �ߺз� 
      LEFT OUTER JOIN _TDAUMinor		AS E WITH(NOLOCK) ON ( D.ValueSeq = E.MinorSeq AND D.CompanySeq = E.CompanySeq AND E.IsUse = '1' )
      LEFT OUTER JOIN _TDAUMinorValue	AS F WITH(NOLOCK) ON ( E.MinorSeq = F.MinorSeq AND F.Serl = 2001 AND E.MajorSeq = F.MajorSeq AND E.CompanySeq = F.CompanySeq )
      -- ��з� 
      LEFT OUTER JOIN _TDAUMinor		AS G WITH(NOLOCK) ON ( F.ValueSeq = G.MinorSeq AND F.CompanySeq = G.CompanySeq AND G.IsUse = '1' )
	  LEFT OUTER JOIN _TDAItemAsset		AS J WITH(NOLOCK) ON ( J.CompanySeq = A.CompanySeq AND J.AssetSeq = A.AssetSeq)
	  LEFT OUTER JOIN _TDASMinor		AS K WITH(NOLOCK) ON ( K.CompanySeq = J.CompanySeq AND K.MinorSeq = J.SMAssetGrp) 

     WHERE A.CompanySeq = @CompanySeq
       AND I.IsQty <> '1' -- ������ ���� 
	   AND K.MinorValue = @MinorValue
	   


    -- â����� ��������
 
   EXEC _SLGGetInOutStock @CompanySeq   = @CompanySeq,   -- �����ڵ�
                           @BizUnit      = @BizUnit,	  -- ����ι�
						   @FactUnit     = 0,     -- ��������
                           @DateFr       = @DateFr,       -- ��ȸ�ⰣFr
                           @DateTo       = @DateTo,       -- ��ȸ�ⰣTo
                           @WHSeq        = 0,			  -- â������
                           @SMWHKind     = 0,			  -- â���� 
                           @CustSeq      = 0,			  -- ��Ź�ŷ�ó
                           @IsTrustCust  = '',			  -- ��Ź����
                           @IsSubDisplay = 0,			 -- ���â�� ��ȸ
                           @IsUnitQry    = 0,    -- ������ ��ȸ
                           @QryType      = 'S',      -- 'S': 1007 �����, 'B':1008 �ڻ�����, 'A':1011 �������
                           @MngDeptSeq   =  0,
                           @IsUseDetail  = '1'
    

	IF EXISTS (SELECT TOP(1) 1 FROM #GetInOutStock WHERE STDStockQty < 0 ) 
	BEGIN 
		
		UPDATE A
		SET  Status = 991
			,Result = '���̳ʽ� ��� �־� ���� �� �� �����ϴ�.'
		FROM #TESMCProdClosing AS A
		WHERE A.IDX_NO = @Cnt


		BREAK 
	END
		
		
	 	
		SELECT @Cnt = @Cnt+1
	END
		
	-------------���̳ʽ���� üũ ��------------------

--  �ŷ�ó���̼��� üũ���� �ʵ��� �� - ������ ��û 20160106 => 20160202 �ٽ� üũ�ϵ��� ����
	-------------�ŷ�ó�� �̼��� ���� üũ-------------
	-- SELECT @MaxCnt = MAX(IDX_NO),
	--		@Cnt	= 1 
	--	 FROM #TESMCProdClosing 
	--	 WHERE IsClose='1'

	--	 -- ����ι���� : ����ι� & ȸ����� 
	--	 SELECT @UnitSeq = MAX(UnitSeq)		 FROM #TESMCProdClosing  

	--	 SELECT @AccUnit = ISNULL(B.AccUnit, 0),
	--			@BizUnit = ISNULL(A.BizUnit, 0) 
	--     FROM _TDAFactUnit AS A WITH(NOLOCK)
	--     LEFT OUTER JOIN _TDABizUnit AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq
	--   												  AND B.BizUnit	= A.BizUnit
	--    WHERE A.CompanySeq = @CompanySeq 
	--	  AND A.FactUnit = @UnitSeq


	--	DECLARE @CheckResult INT,  @xml NVARCHAR(MAX)

	--	WHILE (@Cnt <= @MaxCnt)
	--	BEGIN
		
	--		SELECT	  @DateFr = CONVERT(NCHAR(6),MAX(ClosingYM))+'01' 
	--				, @DateTo = CONVERT(NCHAR(8),DATEADD(DD,-1,DATEADD(MM,1,CONVERT(NCHAR(6),MAX(ClosingYM))+'01' )),112)
	--		FROM #TESMCProdClosing
	--		WHERE IDX_NO = @Cnt
	--		  AND IsClose = '1'

			
	--	SELECT @xml=
	--		  N'<ROOT>
	--		  <DataBlock1>
	--			<WorkingTag>A</WorkingTag>
	--			<IDX_NO>1</IDX_NO>
	--			<Status>0</Status>
	--			<DataSeq>1</DataSeq>
	--			<Selected>1</Selected>
	--			<TABLE_NAME>DataBlock1</TABLE_NAME>
	--			<IsChangedMst>1</IsChangedMst>
	--			<IsDiff>1</IsDiff>
	--			<AccUnit>'+CONVERT(NVARCHAR(10),@AccUnit)+'</AccUnit>
	--			<QryDateFr>'+@DateFr+'</QryDateFr>
	--			<QryDateTo>'+@DateTo+'</QryDateTo>
	--		  </DataBlock1>
	--		</ROOT>'

		
	
	--	exec @CheckResult= KPX_SSLCustCreditCompareCheckSub @xmlDocument=@xml,@xmlFlags=2,@ServiceSeq=1031121,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1025932 

		
	--		IF @CheckResult = 1
	--	BEGIN 
		
	--		UPDATE A
	--		SET  Status = 992
	--			,Result = '�ŷ�ó�� �̼��������� �־� ���� �� �� �����ϴ�.'
	--		FROM #TESMCProdClosing AS A
	--		WHERE A.IDX_NO = @Cnt

	--		BREAK 
	--	END
		
		
	 	
	--	SELECT @Cnt = @Cnt+1
	--END


	-------------�ŷ�ó�� �̼��� ���� üũ ��-------------

	END
    
    
    
    
    
   
     
      SELECT * FROM #TESMCProdClosing   
 RETURN
 /**********************************************************************************************************/
-- go
-- exec KPX_SESMCProdClosingInOutCheck @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>U</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <ROW_IDX>9</ROW_IDX>
--    <ClosingYM>201510</ClosingYM>
--    <IsClose>0</IsClose>
--    <DtlUnitSeq>1</DtlUnitSeq>
--    <TABLE_NAME>DataBlock1</TABLE_NAME>
--    <UnitSeq>1</UnitSeq>
--    <ClosingSeq>69</ClosingSeq>
--  </DataBlock1>
--  <DataBlock1>
--    <WorkingTag>U</WorkingTag>
--    <IDX_NO>2</IDX_NO>
--    <DataSeq>2</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <ROW_IDX>9</ROW_IDX>
--    <ClosingYM>201510</ClosingYM>
--    <IsClose>0</IsClose>
--    <DtlUnitSeq>2</DtlUnitSeq>
--    <UnitSeq>1</UnitSeq>
--    <ClosingSeq>69</ClosingSeq>
--  </DataBlock1>
--  <DataBlock1>
--    <WorkingTag>U</WorkingTag>
--    <IDX_NO>3</IDX_NO>
--    <DataSeq>3</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <ROW_IDX>10</ROW_IDX>
--    <ClosingYM>201511</ClosingYM>
--    <IsClose>1</IsClose>
--    <DtlUnitSeq>1</DtlUnitSeq>
--    <UnitSeq>1</UnitSeq>
--    <ClosingSeq>69</ClosingSeq>
--  </DataBlock1>
--  <DataBlock1>
--    <WorkingTag>U</WorkingTag>
--    <IDX_NO>4</IDX_NO>
--    <DataSeq>4</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <ROW_IDX>10</ROW_IDX>
--    <ClosingYM>201511</ClosingYM>
--    <IsClose>1</IsClose>
--    <DtlUnitSeq>2</DtlUnitSeq>
--    <UnitSeq>1</UnitSeq>
--    <ClosingSeq>69</ClosingSeq>
--  </DataBlock1>
--  <DataBlock1>
--    <WorkingTag>U</WorkingTag>
--    <IDX_NO>5</IDX_NO>
--    <DataSeq>5</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <ROW_IDX>11</ROW_IDX>
--    <ClosingYM>201512</ClosingYM>
--    <IsClose>1</IsClose>
--    <DtlUnitSeq>1</DtlUnitSeq>
--    <UnitSeq>1</UnitSeq>
--    <ClosingSeq>69</ClosingSeq>
--  </DataBlock1>
--  <DataBlock1>
--    <WorkingTag>U</WorkingTag>
--    <IDX_NO>6</IDX_NO>
--    <DataSeq>6</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <ROW_IDX>11</ROW_IDX>
--    <ClosingYM>201512</ClosingYM>
--    <IsClose>1</IsClose>
--    <DtlUnitSeq>2</DtlUnitSeq>
--    <UnitSeq>1</UnitSeq>
--    <ClosingSeq>69</ClosingSeq>
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=6561,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=200857

GO


