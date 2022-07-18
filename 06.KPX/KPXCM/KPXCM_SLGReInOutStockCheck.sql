IF OBJECT_ID('KPXCM_SLGReInOutStockCheck') IS NOT NULL 
    DROP PROC KPXCM_SLGReInOutStockCheck
GO 

-- v2015.11.11 

-- KPX �� 2015.08������ ��������� ���� �ʵ��� üũ �߰� 
  /************************************************************
  ��  �� - ��������� �� üũ
  �ۼ��� - 2011.03.31
  �ۼ��� - ����
  �������� :  ����ι��� ��ǥüũ
 ************************************************************/
  -- ��������� - ��ȸ 
 CREATE PROC KPXCM_SLGReInOutStockCheck
     @xmlDocument       NVARCHAR(MAX) ,
     @xmlFlags          INT  = 0,
     @ServiceSeq        INT  = 0,
     @WorkingTag        NVARCHAR(10)= '',
     @CompanySeq        INT  = 1,
     @LanguageSeq       INT  = 1,
     @UserSeq           INT  = 0,
     @PgmSeq            INT  = 0
 AS
      DECLARE @MessageType INT,
              @Status      INT,
              @Results     NVARCHAR(250),
              @SMCostMng   INT,
              @UseCost     INT  ,
              @IsUseIFRS   INT
       -- ���� ������ ��� ����
      CREATE TABLE #TLGStockReSumCheck (WorkingTag NCHAR(1) NULL)
      EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TLGStockReSumCheck'
    
    
    --------------------------------------------------------------------------------
    -- KPX �� 2015.08������ ��������� ���� �ʵ��� üũ �߰� 
    --------------------------------------------------------------------------------
    
    UPDATE A 
       SET Result = '2015�� 9�� ���� ���� ������ �� �� �����ϴ�.', 
           MessageType = 1234, 
           Status = 1234 
      FROM #TLGStockReSumCheck AS A 
     WHERE A.Status = 0 
       AND A.InOutYM <= '201508'
    
    --------------------------------------------------------------------------------
    -- KPX �� 2015.08������ ��������� ���� �ʵ��� üũ �߰� 
    --------------------------------------------------------------------------------
      -- ���������� ��������
      DECLARE @ItemPriceUnit      INT,
              @GoodPriceUnit      INT,
              @FGoodPriceUnit     INT,
              @ProfCostUnitKind   INT,
              @CostUnitKind       INT
       SELECT @CostUnitKind     = EnvValue FROM _TComEnv WHERE EnvSeq = 5524  AND CompanySeq = @CompanySeq --��������������(�������� or ȸ�����)
      SELECT @ProfCostUnitKind = EnvValue FROM _TComEnv WHERE EnvSeq = 5518  AND CompanySeq = @CompanySeq --�ѿ���������  (ȸ����� or����ι�)--������Ʈ ��ǥ����..
      SELECT @ItemPriceUnit    = EnvValue FROM _TComEnv WHERE EnvSeq = 5521  AND CompanySeq = @CompanySeq --����ܰ�������(ȸ����� or����ι�)
      SELECT @GoodPriceUnit    = EnvValue FROM _TComEnv WHERE EnvSeq = 5522  AND CompanySeq = @CompanySeq --��ǰ�ܰ�������(ȸ����� or����ι�)
      SELECT @FGoodPriceUnit   = EnvValue FROM _TComEnv WHERE EnvSeq = 5523  AND CompanySeq = @CompanySeq --��ǰ�ܰ�������(ȸ����� or����ι�)
  
      -- ȯ�漳������ '����������' ��������
      EXEC dbo._SCOMEnv @CompanySeq,5531,@UserSeq,@@PROCID,@UseCost OUTPUT
  
      -- IFRS�θ� ���ó�� ���࿩��
      EXEC dbo._SCOMEnv @CompanySeq,5563,@UserSeq,@@PROCID,@IsUseIFRS OUTPUT
       IF @UseCost = 5518001 -- �⺻����
         IF @IsUseIFRS = '1'
         SELECT @SMCostMng = 5512006
         ELSE
         SELECT @SMCostMng = 5512004
      ELSE -- Ȱ�����ؿ���
         IF @IsUseIFRS = '1'
         SELECT @SMCostMng = 5512005
         ELSE
         SELECT @SMCostMng = 5512001
        EXEC dbo._SCOMMessage @MessageType OUTPUT,
                             @Status      OUTPUT,
                             @Results     OUTPUT,
                             1173               , -- @1�� �ڷ�� @2@3�� �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE  LanguageSeq = 1 and MessageSeq = 1285)
                             @LanguageSeq     ,
                             28676 , '',  -- �������ó����
                             0,'',
                             17036,''
       IF '' = ISNULL((SELECT tOP 1 BizUnit FROM #TLGStockReSumCheck),''  ) --����ι��� ������ϸ�
      BEGIN
         UPDATE #TLGStockReSumCheck
            SET Result        = REPLACE(@Results,'@2','')+'('+ C.MinorName +')',
                MessageType   = @MessageType,
                Status        = @Status
           FROM _TESMCProdSlipM AS A
                              JOIN (  SELECT A.TransSeq ,
                                             C.InOutYM
                                        FROM _TESMCProdSlipM   AS A WITH(NOLOCK)
                                        JOIN _TESMDCostKey     AS B WITH(NOLOCK) ON A.CostKeySeq    = B.CostKeySeq
                                                                                AND B.SMCostMng     = @SMCostMng
                                                                                AND B.RptUnit       = 0
                                                                                AND B.CostMngAmdSeq = 0
                                                                                AND B.PlanYear      = ''
          AND A.CompanySeq    = B.Companyseq
                                        JOIN #TLGStockReSumCheck AS C ON B.CostYM = C.InOutYM
               WHERE A.CompanySeq = @CompanySeq
                                         AND A.SlipSeq <> 0
                                       GROUP BY A.TransSeq, C.InOutYM
                                   )  AS B ON A.TransSeq = B.TransSeq
           LEFT OUTER JOIN _TDASMinor AS C WITH(NOLOCK) ON A.SMSlipKind = C.MinorSeq AND A.CompanySeq = C.CompanySeq
           JOIN #TLGStockReSumCheck   AS D ON B.InOutYM  = D.InOutYM
          WHERE Status = 0
            AND A.CompanySeq = @CompanySeq
     END
     ELSE
     BEGIN
          CREATE TABLE  #CostUnitList
          (
              AccUnit INT,
              AccUnitName NVARCHAR(100),
              BizUnit INT,
              BizUnitName NVARCHAR(100),
              FactUnit INT,
              FactUnitName NVARCHAR(50)
          )
          INSERT #CostUnitList
          SELECT A.AccUnit, ISNULL(A.AccUnitName, '') AS AccUnitName,
                 ISNULL(B.BizUnit, 0) AS BizUnit, ISNULL(B.BizUnitName, '') AS BizUnitName,
                 ISNULL(C.FactUnit, 0) AS FactUnit, ISNULL(C.FactUnitName, '') AS FactUnitName
            FROM _TDAAccUnit AS A WITH(NOLOCK)
                      LEFT OUTER JOIN _TDABizUnit AS  B WITH(NOLOCK) ON A.AccUnit = B.AccUnit AND A.CompanySeq = B.CompanySeq
                      LEFT OUTER JOIN _TDAFactUnit AS C WITH(NOLOCK) ON B.BizUnit = C.BizUnit AND B.CompanySeq = C.CompanySeq
           WHERE A.CompanySeq = @CompanySeq
          UPDATE #TLGStockReSumCheck
             SET Result        = REPLACE(REPLACE(REPLACE(@Results,'@1',''),'@2',''), '@3', ISNULL(D.MinorName,'')),  --CONVERT(NVARCHAR(7) , CONVERT(DATETIME, B.ClosingYM+'01'), 120) + ' ' +
                 MessageType   = @MessageType,
                 Status        = @Status
            FROM #TLGStockReSumCheck AS A
              JOIN (
              SELECT D.BizUnit ,
                     A.TransSeq ,
                     A.CostKeySeq
                FROM _TESMCProdSlipM   AS A WITH(NOLOCK)
                              JOIN _TESMDCostKey     AS B WITH(NOLOCK) ON A.CostKeySeq    = B.CostKeySeq
                                                                      AND B.SMCostMng     = @SMCostMng
                                                                      AND B.RptUnit       = 0
                                                                      AND B.CostMngAmdSeq = 0
                                                                      AND B.PlanYear      = ''
                                                                      AND A.CompanySeq    = B.Companyseq
                              JOIN #CostUnitList     AS C              ON A.CostUnit      = CASE WHEN A.SMSlipKind IN (5522001,5522002,5522003,5522016)   --���������������� ��ϵ� ��ǥ�� ���
                                                                                                      THEN CASE @CostUnitKind WHEN 5502001 THEN C.FactUnit ELSE C.AccUnit END
                                                                                                 WHEN A.SMSlipKind IN (5522004,5522013,5522017)                   --����ܰ��������� ��ϵ� ��ǥ�� ���
                                                                                                      THEN CASE @ItemPriceUnit WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                 WHEN A.SMSlipKind IN (5522005,5522014)                   --��ǰ�ܰ��������� ��ϵ� ��ǥ�� ���
                                                                                                      THEN CASE @GoodPriceUnit WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                 WHEN A.SMSlipKind IN (5522006,5522007,5522012,5522015)   --��ǰ�ܰ��������� ��ϵ� ��ǥ�� ���
                                                                    THEN CASE @FGoodPriceUnit WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                 WHEN A.SMSlipKind IN (5522009,5522010,5522011)           --������Ʈ��ǥó���� ��� �ѿ���������...
                                                                                                      THEN CASE @ProfCostUnitKind WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                 WHEN A.SMSlipKind IN (5522008)       --������ǥó��(ȸ�������...)
                                                                                                      THEN C.AccUnit
                                               ELSE 0 END
                              JOIN #TLGStockReSumCheck AS D WITH(NOLOCK) ON  C.BizUnit = D.BizUnit AND D.Status  = 0 AND B.CostYM = D.InOutYM
               WHERE A.CompanySeq = @CompanySeq
                 AND A.SlipSeq <> 0
               GROUP BY D.BizUnit , A.TransSeq,A.CostKeySeq
                                   ) AS B ON A.BizUnit = B.BizUnit
                              JOIN _TESMCProdSlipM AS C WITH(NOLOCK) ON C.TransSeq = B.TransSeq AND C.CompanySeq = @CompanySeq
                   LEFT OUTER JOIN _TDASMinor AS D WITH(NOLOCK) ON C.SMSlipKind = D.MinorSeq AND C.CompanySeq = D.CompanySeq
           WHERE A.Status = 0
  
     END
      /*
     AND D.PriceCalcKind IN (5515002) --�����ϰ��
     AND A.SMSlipKind NOT IN (5522005,5522006,5522007,5522012,5522014,5522015,5522016)
     AND D.PriceCalcKind IN (5515003) --��ǰ
     AND A.SMSlipKind NOT IN (5522004,5522013)
     AND D.PriceCalcKind IN (5515001) --��ǰ�ϰ��
     AND A.SMSlipKind NOT IN (5522004,5522005,5522007,5522012,5522013,5522014,5522015,5522016,5522017)
     AND ISNULL(D.PriceCalcKind,0)  = 0  --��ǰ����
     AND A.SMSlipKind NOT IN (5522004,5522005,5522007,5522013,5522014,5522015,5522016,5522017)
     */
     
     INSERT INTO _TLGReInOutStockHist
     (   
         CompanySeq,
         InOutYM,
         SMInOutType,
         LastUserSeq,
         LastDateTime,
         BizUnit,
         PgmSeq 
     )
     SELECT @CompanySeq,
            A.InOutYM,
            A.SMInOutType,
            @UserSeq,
            GETDATE(),
            BizUnit,
            @PgmSeq 
       FROM #TLGStockReSumCheck AS A
      WHERE A.Status = 0
     
     SELECT * FROM #TLGStockReSumCheck
     
     RETURN