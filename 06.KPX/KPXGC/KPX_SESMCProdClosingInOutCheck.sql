IF OBJECT_ID('KPX_SESMCProdClosingInOutCheck') IS NOT NULL 
    DROP PROC KPX_SESMCProdClosingInOutCheck
GO 

-- v2015.07.27 

-- ���̳ʽ���� ������� üũ by����õ 
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
 CREATE PROC dbo.KPX_SESMCProdClosingInOutCheck
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
    
    SELECT * FROM #TESMCProdClosing 
    
    RETURN 
    
    
    
    
    
    
    
     
     
      SELECT * FROM #TESMCProdClosing   
 RETURN
 /**********************************************************************************************************/
 go
 exec KPX_SESMCProdClosingInOutCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>9</ROW_IDX>
    <ClosingYM>201510</ClosingYM>
    <IsClose>0</IsClose>
    <DtlUnitSeq>1</DtlUnitSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <UnitSeq>3</UnitSeq>
    <ClosingSeq>69</ClosingSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>9</ROW_IDX>
    <ClosingYM>201510</ClosingYM>
    <IsClose>0</IsClose>
    <DtlUnitSeq>2</DtlUnitSeq>
    <UnitSeq>3</UnitSeq>
    <ClosingSeq>69</ClosingSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>10</ROW_IDX>
    <ClosingYM>201511</ClosingYM>
    <IsClose>1</IsClose>
    <DtlUnitSeq>1</DtlUnitSeq>
    <UnitSeq>3</UnitSeq>
    <ClosingSeq>69</ClosingSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>10</ROW_IDX>
    <ClosingYM>201511</ClosingYM>
    <IsClose>1</IsClose>
    <DtlUnitSeq>2</DtlUnitSeq>
    <UnitSeq>3</UnitSeq>
    <ClosingSeq>69</ClosingSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>11</ROW_IDX>
    <ClosingYM>201512</ClosingYM>
    <IsClose>1</IsClose>
    <DtlUnitSeq>1</DtlUnitSeq>
    <UnitSeq>3</UnitSeq>
    <ClosingSeq>69</ClosingSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>11</ROW_IDX>
    <ClosingYM>201512</ClosingYM>
    <IsClose>1</IsClose>
    <DtlUnitSeq>2</DtlUnitSeq>
    <UnitSeq>3</UnitSeq>
    <ClosingSeq>69</ClosingSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=6561,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=200857