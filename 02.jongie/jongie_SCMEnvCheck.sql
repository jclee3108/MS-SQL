
IF OBJECT_ID('jongie_SCMEnvCheck') IS NOT NULL
    DROP PROC jongie_SCMEnvCheck
GO
    
-- v2013.08.07   
  
-- (���̳���) �߰����� Mapping���� ����_jongie-üũ by ��ö�� (copy ����õ)
CREATE PROC jongie_SCMEnvCheck        
    @xmlDocument    NVARCHAR(MAX),        
    @xmlFlags       INT     = 0,        
    @ServiceSeq     INT     = 0,        
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT     = 1,        
    @LanguageSeq    INT     = 1,        
    @UserSeq        INT     = 0,        
    @PgmSeq         INT     = 0        
AS        
        
    DECLARE @PriceUnitEnvSeq    INT,        
            @Word               NVARCHAR(100),        
            @MessageType        INT,        
            @Status             INT,        
            @Results            NVARCHAR(250)        
        
    CREATE TABLE #TCOMEnv (WorkingTag NCHAR(1) NULL)        
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TCOMEnv'        
    IF @@ERROR <> 0 RETURN        
          
    SELECT @PriceUnitEnvSeq = EnvSeq FROM #TCOMEnv        
            
    --ȯ�漳������ ����ܰ�������, ��ǰ�ܰ�������, ��ǰ�ܰ������� ���� �����͸� ���� �� �ʱ� �Էµ� �����Ͱ� �̻��� �߻��ϴ� ��찡 ������.        
    --�̸� �����ϱ� ���Ͽ� �ش� �Ӽ� ���� �� �ʱ�ݾ��Է� ȭ�鿡 �����Ͱ� �����ϸ� �̹� �ʱ⿡ ��ϵ� �ڷᰡ �����Ͽ� ������ �� ���ٴ� �޽��� ó��        
    CREATE TABLE #TempAsset (SMAssetGrp INT)         
        
    IF @PriceUnitEnvSeq =5521          
    BEGIN        
        INSERT INTO #TempAsset        
        SELECT MinorSeq          
          FROM _TDASMinor         
         WHERE MinorValue = '1' --����         
           AND MinorSeq <> '6008005' --���ǰ         
           AND MajorSeq = 6008        
           AND CompanySeq = @CompanySeq         
        SELECT @Word = Word FROM _TCADictionary WHERE WordSeq = 1968 AND LanguageSeq = @LanguageSeq        
    END        
    ELSE IF @PriceUnitEnvSeq =5522 --��ǰ         
    BEGIN        
        INSERT INTO #TempAsset        
        SELECT MinorSeq         
          FROM _TDASMinor          
         WHERE  MinorSeq = 6008001        
           AND CompanySeq = @CompanySeq         
        SELECT @Word = Word FROM _TCADictionary WHERE WordSeq = 3069 AND LanguageSeq = @LanguageSeq        
    END        
    ELSE IF @PriceUnitEnvSeq =5523 --��ǰ         
    BEGIN         
        INSERT INTO #TempAsset        
        SELECT MinorSeq         
          FROM _TDASMinor          
         WHERE  MinorSeq IN ( 6008002 , 6008004 )         
           AND CompanySeq = @CompanySeq         
        SELECT @Word = Word FROM _TCADictionary WHERE WordSeq = 2031 AND LanguageSeq = @LanguageSeq        
        SELECT @Word = @Word + '(' + Word + ')' FROM _TCADictionary WHERE WordSeq = 8731 AND LanguageSeq = @LanguageSeq        
    END        
        
    IF EXISTS (        
                SELECT TOP 1 1        
                  FROM _TESMGMonthlyStockAmt    AS A WITH(NOLOCK)        
                  JOIN _TDAItem      AS C WITH(NOLOCK) ON A.ItemSeq      = C.ItemSeq        
                                                      AND A.CompanySeq   = C.CompanySeq        
                  JOIN _TDAItemAsset AS E WITH(NOLOCK) ON C.CompanySeq   = E.CompanySeq        
                                                      AND C.AssetSeq     = E.AssetSeq        
                  JOIN #TempAsset    AS F WITH(NOLOCK) ON E.SMAssetGrp   = F.SMAssetGrp         
                 WHERE A.CompanySeq   = @CompanySeq        
                   AND A.InOutKind    = 8023000        
                )        
    BEGIN        
        EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                              @Status      OUTPUT,        
                              @Results     OUTPUT,        
                              8                  , -- @2 @1(@3)��(��) ��ϵǾ� ����/���� �� �� �����ϴ�. SELECT * FROM _TCAMessageLanguage WHERE Message like '%���%'        
                              @LanguageSeq       ,         
                              9357,''            ,        
                              0, @Word           ,        
                              8316,''               -- SELECT * FROM _TCADictionary WHERE Word like '%��ǰ%'        
          UPDATE #TCOMEnv        
           SET Result        = @Results,        
               MessageType   = @MessageType,        
               Status        = @Status        
          FROM #TCOMEnv AS A        
         WHERE  A.WorkingTag IN ('A','U')        
              AND A.Status = 0        
    END        
        
    --ȯ�漳������ ���� �ش� �ϴ� �����Ͱ� �ƴ� ��� ���� �޽��� ó����        
    IF @PriceUnitEnvSeq IN (5518,5521,5522,5523)        
    BEGIN        
        IF (SELECT EnvValue FROM #TCOMEnv) NOT IN (5502002,5502003)        
        BEGIN        
            EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                                  @Status      OUTPUT,        
                                  @Results     OUTPUT,        
                                  1139               , -- ȯ�漳������(@1) ���� ��ġ���� �ʽ��ϴ�. SELECT * FROM _TCAMessageLanguage WHERE Message like '%ȯ�漳��%'        
                                  @LanguageSeq       ,         
                                  0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
        
            UPDATE #TCOMEnv        
               SET Result        = REPLACE(@Results,'@1',EnvValueName),        
                   MessageType   = @MessageType,        
                   Status        = @Status        
              FROM #TCOMEnv AS A        
             WHERE  A.WorkingTag IN ('A','U')        
                AND A.Status = 0        
        END        
    END        
    ELSE IF @PriceUnitEnvSeq = 5524        
    BEGIN        
        IF (SELECT EnvValue FROM #TCOMEnv) NOT IN (5502001,5502002)        
        BEGIN        
            EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                                  @Status      OUTPUT,        
                                  @Results     OUTPUT,        
                                  1139               , -- ȯ�漳������(@1) ���� ��ġ���� �ʽ��ϴ�. SELECT * FROM _TCAMessageLanguage WHERE Message like '%ȯ�漳��%'        
                                  @LanguageSeq       ,         
                                  0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
        
            UPDATE #TCOMEnv        
               SET Result        = REPLACE(@Results,'@1',EnvValueName),        
                   MessageType   = @MessageType,        
                   Status        = @Status        
              FROM #TCOMEnv AS A        
             WHERE  A.WorkingTag IN ('A','U')        
                AND A.Status = 0        
        END        
    END        
        
---------------------------------------------------------------------------------------------------------------        
    --�ʼ��Է�(���, �����ID, ȸ��)        
    --EXEC dbo._SCOMMessage @MessageType OUTPUT,        
    --                      @Status      OUTPUT,        
    --                      @Results     OUTPUT,        
    --                      1038               , -- �ʼ��Է� �׸��� �Է����� �ʾҽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ʼ�%')        
    --                      @LanguageSeq       ,         
    --                      0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
        
    --UPDATE #TCOMEnv        
    --   SET Result        = '[ȯ�漳����]'+@Results,        
    --       MessageType   = @MessageType,        
    --       Status        = @Status        
    --  FROM #TCOMEnv AS A        
    -- WHERE  A.WorkingTag IN ('A','U')        
    --    AND A.Status = 0        
    --    AND A.EnvName = ''        
          
    -- üũ�ڽ��϶��� 1,0���� ����        
    IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag IN ('A','U') AND SMControlType = '84006' AND Status = 0)        
    BEGIN        
        UPDATE #TCOMEnv        
           SET EnvValue = '1'        
          FROM #TCOMEnv AS A        
         WHERE  A.WorkingTag IN ('A','U')        
            AND A.Status = 0        
            AND A.SMControlType = '84006'        
            AND A.EnvValue = 'True'        
        UPDATE #TCOMEnv        
           SET EnvValue = '0'        
            FROM #TCOMEnv AS A         
         WHERE  A.WorkingTag IN ('A','U')        
            AND A.Status = 0        
            AND A.SMControlType = '84006'        
            AND A.EnvValue = 'False'        
    END        
        
        
        
    -- FloatŸ���ΰ�� ,�� ''�� ����        
    IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag IN ('A','U') AND SMControlType = '84002' AND Status = 0)        
    BEGIN        
        UPDATE #TCOMEnv        
           SET EnvValue = REPLACE(EnvValue, ',', '')        
          FROM #TCOMEnv        
         WHERE  WorkingTag IN ('A','U')        
            AND Status = 0        
            AND SMControlType = '84002'        
    END        
        
        
    -- �Ҽ��� �ڸ��� 5�̻����� �Է�������� ������ �߰� �Ҽ��� �����ϴ� �κ��� ��� �ڵ�� �����ϴ��� ���� ����ũ�� ��        
    --IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag IN ('A','U') AND SMControlType = '84002' AND Status = 0 AND DecLength > 5)          
  IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag IN ('A','U') AND SMControlType = '84002' AND Status = 0 AND CONVERT(DECIMAL(19,5),EnvValue) > 5 AND (EnvName LIKE '%�Ҽ���%' OR EnvName LIKE '%�Ҽ���%'))        
    BEGIN        
        
  UPDATE #TCOMEnv        
     SET Result  = N'�Ҽ����ڸ����� 0~5 �θ� ������ �� �ֽ��ϴ�.',        
      MessageType = -1,        
      Status       = 9999        
   WHERE WorkingTag IN ('A','U')        
     AND Status = 0        
     AND SMControlType = '84002'        
    END        
        
    -- �系���ֺ������ �����԰�������� ����� �����Ͱ� ���� ��� �����ϸ� Ű ���� ���δ�. �׷��� �����Ͱ� ���� ��쿡�� ������ ���� ���ϵ��� �Ѵ� 2012. 1. 11 hkim        
    IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE EnvSeq = 6513 AND Status = 0 AND WorkingTag IN ('U') ) AND EXISTS (SELECT 1 FROM _TPDSFCOutsourcingCostItem WHERE CompanySeq = @CompanySeq)        
    BEGIN        
        EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                              @Status      OUTPUT,        
                              @Results     OUTPUT,        
                              1310               , -- ȯ�漳������(@1) ���� ��ġ���� �ʽ��ϴ�. SELECT * FROM _TCAMessageLanguage WHERE Message like '%ȯ�漳��%'        
                              @LanguageSeq       ,         
                              25334,'�系����',   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
                              355,'������',   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
                              13823,'����'   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
        UPDATE #TCOMEnv        
           SET Result        = @Results,        
               MessageType   = @MessageType,        
               Status        = @Status        
          FROM #TCOMEnv AS A        
         WHERE A.WorkingTag IN ('A','U')        
           AND A.Status = 0        
        
    END        
        
    -- AddCheck �߰�üũSP�� �������        
    IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag IN ('A','U') AND Status = 0 AND ISNULL(AddCheckScript, '') <> '')        
    BEGIN        
        DECLARE @EnvSeq         INT,        
                @AddCheckScript NVARCHAR(100),        
                @EnvValue       NVARCHAR(50)        
        
        DECLARE Check_cursor CURSOR FOR        
            SELECT EnvSeq, AddCheckScript,EnvValue        
              FROM #TCOMEnv        
             WHERE  WorkingTag IN ('A','U')        
                AND Status = 0        
                AND ISNULL(AddCheckScript, '') <> ''        
             ORDER BY EnvSeq        
        OPEN Check_cursor        
        FETCH NEXT FROM Check_cursor INTO @EnvSeq, @AddCheckScript,@EnvValue        
        WHILE @@FETCH_STATUS = 0        
        BEGIN        
        
            EXEC @AddCheckScript @EnvSeq, @CompanySeq, @LanguageSeq, @UserSeq, @PgmSeq,@EnvValue        
        
            FETCH NEXT FROM Check_cursor        
            INTO @EnvSeq, @AddCheckScript,@EnvValue        
        END        
        Deallocate Check_cursor        
    END        
        
    SELECT * FROM #TCOMEnv        
      
    RETURN        