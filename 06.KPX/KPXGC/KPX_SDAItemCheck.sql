IF OBJECT_ID('KPX_SDAItemCheck') IS NOT NULL 
    DROP PROC KPX_SDAItemCheck
GO 

-- v2014.11.04 

-- ǰ����(�⺻_��������)üũ by����õ
/************************************************************
      Ver.20140212
  ��  �� - ǰ���� üũ
 �ۼ��� - 2008�� 6��  
 �ۼ��� - ���ظ�
 ������ - 20110511 by ��ö��
   1) �����Ͽ��� ���ǰ�� ��� Lot���� �� Serial������ ���� ���ϵ��� �����Ͽ���
 ************************************************************/
 CREATE PROC KPX_SDAItemCheck
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
  AS    
    DECLARE @Count   INT,
            @Seq   INT,
            @MessageType INT,
            @Status   INT,
            @ItemName  NVARCHAR(200),
            @TrunName  NVARCHAR(200),
            @Results  NVARCHAR(250),
            @ItemNameCheck NCHAR(1),
            @ItemNoCheck NCHAR(1),
            @SpecCheck  NCHAR(1), 
            @DataSeq  INT, 
            @MaxDataSeq  INT,
            @IsLotMng  NCHAR(1),
            @IsSerialMng NCHAR(1),
            @AssetSeq  INT,
            @UpdateUseItemCheck INT
    
    -- ���� ����Ÿ ��� ����
    CREATE TABLE #KPX_TDAItem (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItem'     
    IF @@ERROR <> 0 RETURN 
    
    
    -- üũ, Ȯ���� �����ʹ� ���� �� �� �����ϴ�.
    EXEC dbo._SCOMMessage @MessageType OUTPUT,
                          @Status      OUTPUT,
                          @Results     OUTPUT,
                          1083               , -- @1��(��) @2(��)�� �� �� �����ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE MessageDefault like '%ó���� �� �����ϴ�%')
                          @LanguageSeq       , 
                          0 
    
    UPDATE A
       SET Result = @Results, 
           Status = @Status, 
           MessageType = @MessageType
      FROM #KPX_TDAItem AS A 
     WHERE A.Status = 0 
       AND EXISTS (SELECT 1 FROM KPX_TDAItem_Confirm WHERE CompanySeq = @CompanySeq AND CfmSeq = A.ItemSeq AND CfmCode = 1)
     -- üũ, END 
    
    SELECT @ItemName = ISNULL(ItemName, ''),
           @IsLotMng = IsLotMng,
           @IsSerialMng = IsSerialMng,
           @AssetSeq = AssetSeq
      FROM #KPX_TDAItem
    
    -- �����Ͽ��� ���ǰ�� ��� Lot���� �� Serial������ ���� ���ϵ��� ����
    IF EXISTS ( SELECT * FROM _TDAItemAsset WHERE CompanySeq = @CompanySeq AND AssetSeq = @AssetSeq AND SMAssetGrp = 6008005 ) -- ���ǰ 
    BEGIN
    EXEC dbo._SCOMMessage @MessageType OUTPUT,
                          @Status      OUTPUT,
                          @Results     OUTPUT,
                          19               , -- @1��(��) @2(��)�� �� �� �����ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE MessageDefault like '%�����ϴ�.')
                          @LanguageSeq       , 
                          22654,'���ǰ'   -- SELECT * FROM _TCADictionary WHERE Word like '%Serial����%'
    IF @IsLotMng = 1 
    UPDATE #KPX_TDAItem
       SET Result        = REPLACE(@Results,'@2', (SELECT Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 14046)),
        MessageType   = @MessageType,
        Status        = @Status
   ELSE IF @IsSerialMng = 1
    UPDATE #KPX_TDAItem
       SET Result        = REPLACE(@Results,'@2', (SELECT Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 14156)),
        MessageType   = @MessageType,
        Status        = @Status
                
  END
  
     --ǰ�� �ߺ�üũ     
     EXEC dbo._SCOMEnv @CompanySeq,1001,@UserSeq,@@PROCID,@ItemNameCheck  OUTPUT  
      --ǰ�� �ߺ�üũ     
     EXEC dbo._SCOMEnv @CompanySeq,1002,@UserSeq,@@PROCID,@ItemNoCheck  OUTPUT  
      --ǰ��+�԰� �ߺ�üũ     
     EXEC dbo._SCOMEnv @CompanySeq,1003,@UserSeq,@@PROCID,@SpecCheck  OUTPUT  
     
     -- ǰ��/ǰ�� ���� ��, ��뿩�� üũ
     EXEC dbo._SCOMEnv @CompanySeq,28,@UserSeq,@@PROCID,@UpdateUseItemCheck  OUTPUT  
  
  
      IF ISNULL(@ItemNameCheck,'') = '1'
     BEGIN
         -------------------------------------------
         -- ǰ���ߺ�����üũ
         -------------------------------------------
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
                               @LanguageSeq       , 
                               0,'ǰ��'   -- SELECT * FROM _TCADictionary WHERE Word like '%����ī���ȣ%'
         UPDATE #KPX_TDAItem
            SET Result        = REPLACE(@Results,'@2', A.ItemName),
                MessageType   = @MessageType,
                Status        = @Status
           FROM #KPX_TDAItem AS A JOIN ( SELECT S.ItemName
                                          FROM (
                        SELECT A1.ItemName
                                                  FROM #KPX_TDAItem AS A1
                              WHERE A1.WorkingTag IN ('A', 'U')
                                                   AND A1.Status = 0
                                                UNION ALL
                                                SELECT A1.ItemName
                                                  FROM KPX_TDAItem AS A1
                                                 WHERE A1.CompanySeq = @CompanySeq
                                                   AND A1.ItemSeq NOT IN (SELECT ItemSeq 
                                                                                FROM #KPX_TDAItem 
                                                                               WHERE WorkingTag IN ('U','D') 
                                                                                 AND Status = 0)
                                               ) AS S
                                         GROUP BY S.ItemName
                                         HAVING COUNT(1) > 1
                                       ) AS B ON (A.ItemName = B.ItemName)
     END
      IF ISNULL(@ItemNoCheck,'') = '1'
     BEGIN
         -------------------------------------------
         -- ǰ���ߺ�����üũ
         -------------------------------------------
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
                               @LanguageSeq       , 
                               0,'ǰ��'   -- SELECT * FROM _TCADictionary WHERE Word like '%����ī���ȣ%'
         UPDATE #KPX_TDAItem
            SET Result        = REPLACE(@Results,'@2', A.ItemNo),
                MessageType   = @MessageType,
                Status        = @Status
           FROM #KPX_TDAItem AS A JOIN ( SELECT S.ItemNo
                                          FROM (
                                                SELECT A1.ItemNo
                                                  FROM #KPX_TDAItem AS A1
                                                 WHERE A1.WorkingTag IN ('A', 'U')
                                                   AND A1.Status = 0
                                                UNION ALL
                                                SELECT A1.ItemNo
                                                  FROM KPX_TDAItem AS A1
                                                 WHERE A1.CompanySeq = @CompanySeq
                                                   AND A1.ItemSeq NOT IN (SELECT ItemSeq 
                                                                                FROM #KPX_TDAItem 
                                                                               WHERE WorkingTag IN ('U','D') 
                                                                                 AND Status = 0)
                                               ) AS S
                                         GROUP BY S.ItemNo
                                         HAVING COUNT(1) > 1
                                       ) AS B ON (A.ItemNo = B.ItemNo)
     END
      IF ISNULL(@SpecCheck,'') = '1'
     BEGIN
         -------------------------------------------
         -- ǰ�� + �԰��ߺ�����üũ
         -------------------------------------------
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
                               @LanguageSeq       , 
                               0,'ǰ�� + �԰�'   -- SELECT * FROM _TCADictionary WHERE Word like '%����ī���ȣ%'
         UPDATE #KPX_TDAItem
            SET Result        = REPLACE(@Results,'@2', A.ItemName + ' + ' + A.Spec),
                MessageType   = @MessageType,
                Status        = @Status
           FROM #KPX_TDAItem AS A JOIN ( SELECT S.ItemName, S.Spec
                                 FROM (
                                                SELECT A1.ItemName, A1.Spec
                                                  FROM #KPX_TDAItem AS A1
                                                 WHERE A1.WorkingTag IN ('A', 'U')
                                                   AND A1.Status = 0
                                                UNION ALL
                                                SELECT A1.ItemName, A1.Spec
                                                  FROM KPX_TDAItem AS A1
                                                 WHERE A1.CompanySeq = @CompanySeq
                                                   AND A1.ItemSeq NOT IN (SELECT ItemSeq 
                                                                                FROM #KPX_TDAItem 
                                                                               WHERE WorkingTag IN ('U','D') 
                                                                                 AND Status = 0)
                                               ) AS S
                                         GROUP BY S.ItemName, S.Spec
                                         HAVING COUNT(1) > 1
                                       ) AS B ON (A.ItemName = B.ItemName)
                                             AND (A.Spec     = B.Spec)
     END
    
      -------------------------------------------  
     -- ��뿩��üũ 
     -------------------------------------------  
     IF EXISTS (SELECT 1 FROM #KPX_TDAItem WHERE WorkingTag = 'D')
     BEGIN
         EXEC _SCOMCodeDeleteCheck @CompanySeq, @UserSeq, @LanguageSeq, 'KPX_TDAItem', '#KPX_TDAItem', 'ItemSeq'
     END
    
    
    ------------------------------------------------------------
    -- ���ش��� & ǰ���ڻ�з� ��������üũ 20130604 �ڼ�ȣ ����
    ------------------------------------------------------------
     
     -- ���ش��� & ǰ���ڻ�з� UPDATE �Ǵ��� üũ
     IF EXISTS (SELECT 1 
                  FROM #KPX_TDAItem AS A
                       JOIN KPX_TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                                       AND A.ItemSeq    = B.ItemSeq
                 WHERE A.WorkingTag = 'U' 
                   AND A.Status = 0
                   AND (A.UnitSeq <> B.UnitSeq OR A.AssetSeq <> B.AssetSeq))
     BEGIN       
          -- ����SP ����� ���� WorkingTag UPDATE
         UPDATE #KPX_TDAItem SET WorkingTag = 'D'
     
         EXEC _SCOMCodeDeleteCheck @CompanySeq, @UserSeq, @LanguageSeq, 'KPX_TDAItem', '#KPX_TDAItem', 'ItemSeq'
          -- ����SP ���� �� ���� ���̺��� ������, �ٽ� WorkingTag�� UPDATE    
         IF ( SELECT Status FROM #KPX_TDAItem ) = 0
         BEGIN
             UPDATE #KPX_TDAItem SET WorkingTag = 'U'
         END
      END
  
  
      -----------------------------------------------------------------------------------
     --������� ǰ�� ���� ǰ��/ǰ�� �������ɿ��� ���� 20140212 by sdlee
     --�̻������ ǰ���� ��� ������ �����ϸ�, ������� ��쿡�� ������ ���� ǰ��/ǰ���� ������ �� �ֵ��� �����մϴ�.
     --8121001  ǰ�� ��������/ǰ�� �������� : ��üũ
     --8121002  ǰ�� ��������/ǰ�� �����Ұ�
     --8121003  ǰ�� �����Ұ�/ǰ�� ��������
     --8121004  ǰ�� �����Ұ�/ǰ�� �����Ұ�
     -----------------------------------------------------------------------------------
     IF @UpdateUseItemCheck IN (8121002,8121003,8121004)
     BEGIN
          -- ��뿩��üũ
         SELECT *
           INTO #TEMP_Check_TDAItem
           FROM #KPX_TDAItem
  
  
         -- ǰ�� ��������/ǰ�� �����Ұ�
         IF @UpdateUseItemCheck = 8121002
         BEGIN
              -- ǰ�� üũ
             IF EXISTS (SELECT 1 
                          FROM #KPX_TDAItem AS A
                               JOIN KPX_TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq
                         WHERE A.WorkingTag = 'U'
                           AND A.Status = 0
                           AND A.ItemNo <> B.ItemNo)
             BEGIN
             -- ��뿩�� üũ
                 -- ����SP ����� ���� WorkingTag UPDATE
                 UPDATE #KPX_TDAItem SET WorkingTag = 'D' WHERE WorkingTag = 'U'
                  EXEC _SCOMCodeDeleteCheck @CompanySeq, @UserSeq, @LanguageSeq, 'KPX_TDAItem', '#KPX_TDAItem', 'ItemSeq'
  
                 -- ����SP ���� �� ���� ���̺��� ������, �ٽ� WorkingTag�� UPDATE    
                 IF ( SELECT Status FROM #KPX_TDAItem ) = 0
                 BEGIN
                     UPDATE #KPX_TDAItem
                        SET WorkingTag = B.WorkingTag
                       FROM #KPX_TDAItem AS A
                            JOIN #TEMP_Check_TDAItem AS B ON B.DataSeq = A.DataSeq
                 END
                  --EXEC dbo._SCOMMessage   @MessageType OUTPUT,
                 --                        @Status      OUTPUT,
                 --                        @Results     OUTPUT,
                 --                        1366               ,    -- @1��(��) �����Ҽ� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1366)
                 --                        @LanguageSeq       , 
                 --                        2091,'ǰ��'             -- ǰ��(SELECT Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 2091)
                 --UPDATE #KPX_TDAItem
                 --   SET Result        = @Results,
                 --       MessageType   = @MessageType,
                 --       Status        = @Status
                 --  FROM #KPX_TDAItem
                 -- WHERE WorkingTag = 'U'
                 --   AND Status = 0
             END
         END
          -- ǰ�� �����Ұ�/ǰ�� ��������
         IF @UpdateUseItemCheck = 8121003
         BEGIN
              IF EXISTS (SELECT 1 
                          FROM #KPX_TDAItem AS A
                               JOIN KPX_TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq
                         WHERE A.WorkingTag = 'U'
                           AND A.Status = 0
                           AND A.ItemName <> B.ItemName)
             BEGIN
                  -- ��뿩�� üũ
                 -- ����SP ����� ���� WorkingTag UPDATE
                 UPDATE #KPX_TDAItem SET WorkingTag = 'D' WHERE WorkingTag = 'U'
                  EXEC _SCOMCodeDeleteCheck @CompanySeq, @UserSeq, @LanguageSeq, 'KPX_TDAItem', '#KPX_TDAItem', 'ItemSeq'
  
                 -- ����SP ���� �� ���� ���̺��� ������, �ٽ� WorkingTag�� UPDATE    
                 IF ( SELECT Status FROM #KPX_TDAItem ) = 0
                 BEGIN
                     UPDATE #KPX_TDAItem
                        SET WorkingTag = B.WorkingTag
                       FROM #KPX_TDAItem AS A
                            JOIN #TEMP_Check_TDAItem AS B ON B.DataSeq = A.DataSeq
                 END
  
                 --EXEC dbo._SCOMMessage   @MessageType OUTPUT,
                 --                        @Status      OUTPUT,
                 --                        @Results     OUTPUT,
                 --                        1366               ,    -- @1��(��) �����Ҽ� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1366)
                 --                        @LanguageSeq       , 
                 --                        2090,'ǰ��'             -- ǰ��(SELECT Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 2090)
                 --UPDATE #KPX_TDAItem
                 --   SET Result        = @Results,
                 --       MessageType   = @MessageType,
                 --       Status        = @Status
                 --  FROM #KPX_TDAItem
                 -- WHERE WorkingTag = 'U'
                 --   AND Status = 0
             END
         END
          -- ǰ�� �����Ұ�/ǰ�� �����Ұ�
         IF @UpdateUseItemCheck = 8121004
         BEGIN
              IF EXISTS (SELECT 1 
                          FROM #KPX_TDAItem AS A
                               JOIN KPX_TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq
                         WHERE A.WorkingTag = 'U'
                           AND A.Status = 0
                           AND (A.ItemName <> B.ItemName OR A.ItemNo <> B.ItemNo))
             BEGIN
                  -- ��뿩�� üũ
                 -- ����SP ����� ���� WorkingTag UPDATE
                 UPDATE #KPX_TDAItem SET WorkingTag = 'D' WHERE WorkingTag = 'U'
                  EXEC _SCOMCodeDeleteCheck @CompanySeq, @UserSeq, @LanguageSeq, 'KPX_TDAItem', '#KPX_TDAItem', 'ItemSeq'
  
                 -- ����SP ���� �� ���� ���̺��� ������, �ٽ� WorkingTag�� UPDATE    
                 IF ( SELECT Status FROM #KPX_TDAItem ) = 0
                 BEGIN
                     UPDATE #KPX_TDAItem
                        SET WorkingTag = B.WorkingTag
                       FROM #KPX_TDAItem AS A
                            JOIN #TEMP_Check_TDAItem AS B ON B.DataSeq = A.DataSeq
                 END
  

             END
         END
      END
    
     --------------------------------------------------------------------  
     -- ��Ʈǰ���ϰ�� -- ǰ���ڻ�з� ��ǰ�� ��ϰ��� 2012.02.27 jhpark
     --------------------------------------------------------------------
     IF Exists (SELECT TOP 1 1 FROM #KPX_TDAItem WHERE IsSet = 1)
     BEGIN
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               1291               , -- @1�� @2�� @3���� ����ؾ� �մϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1291)
                               @LanguageSeq       , 
                               1615,''    ,-- SELECT * FROM _TCADictionary WHERE Word like '%��ǰ%'
                               3259,''    ,-- SELECT * FROM _TCADictionary WHERE Word like '%��ǰ%'
                               3069,''     -- SELECT * FROM _TCADictionary WHERE Word like '%��ǰ%'
         UPDATE #KPX_TDAItem
            SET Result        = @Results,
                MessageType   = @MessageType,
                Status        = @Status
           FROM #KPX_TDAItem AS A
                 JOIN _TDAItemAsset AS B WITH (NOLOCK) ON A.AssetSeq   = B.AssetSeq
                                                      AND B.CompanySeq = @CompanySeq
                                                      AND B.SMAssetGrp <> 6008001 -- ��ǰ
          WHERE A.WorkingTag <> 'D' 
            AND A.Status = 0
      END
      -------------------------------------------
     -- ��������
     -------------------------------------------
  SELECT @MaxDataSeq = COUNT(1) + 1 FROM #KPX_TDAItem WHERE WorkingTag IN ('A', 'U') AND Status = 0
  
  SET @DataSeq = 1  
  
  WHILE (@DataSeq < @MaxDataSeq) 
  BEGIN
   SELECT @ItemName = ItemName
     FROM #KPX_TDAItem
    WHERE DataSeq = @DataSeq
    
   EXEC _SDATrSpace  @ItemName, @TrunName OUTPUT
    UPDATE #KPX_TDAItem
      SET TrunName = @TrunName
     FROM #KPX_TDAItem
       WHERE DataSeq = @DataSeq
       
       SET @DataSeq = @DataSeq + 1
  END
      -------------------------------------------
     -- ��������üũ
     -------------------------------------------
     -- ���� SP Call ����
      -------------------------------------------
     -- ���࿩��üũ
     -------------------------------------------
     -- ���� SP Call ����
      -------------------------------------------
     -- Ȯ������üũ
     -------------------------------------------
     -- ���� SP Call ����
      -------------------------------------------
     -- INSERT ��ȣ�ο�(�� ������ ó��)
     -------------------------------------------
     SELECT @Count = COUNT(1) FROM #KPX_TDAItem WHERE WorkingTag = 'A' --@Count������(AND Status = 0 ����)
     IF @Count > 0
     BEGIN  
         -- Ű�������ڵ�κ� ����  
         EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TDAItem', 'ItemSeq', @Count
         -- Temp Talbe �� ������ Ű�� UPDATE
         UPDATE #KPX_TDAItem
            SET ItemSeq = @Seq + DataSeq
          WHERE WorkingTag = 'A'
            AND Status = 0
     END   
      UPDATE #KPX_TDAItem
        SET ItemSeq = ItemSeqOLD
      WHERE WorkingTag = 'A'
        AND ItemSeq = 0
        AND Status <> 0
  
     SELECT * FROM #KPX_TDAItem   
  
    RETURN
GO 
begin tran 
exec KPX_SDAItemCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ItemSeq>1051541</ItemSeq>
    <TrunName>TEST123456</TrunName>
    <ModelName />
    <ModelSeq>0</ModelSeq>
    <STDItemName />
    <ItemSeqOLD>1051541</ItemSeqOLD>
    <IsInherit>0</IsInherit>
    <ItemName>test123456</ItemName>
    <UnitSeq>2</UnitSeq>
    <UnitName>EA</UnitName>
    <AssetSeq>15</AssetSeq>
    <AssetName>��ǰ</AssetName>
    <ItemNo>test123456</ItemNo>
    <DeptSeq>0</DeptSeq>
    <DeptName />
    <SMInOutKind>8007001</SMInOutKind>
    <SMStatus>2001001</SMStatus>
    <Spec />
    <EmpSeq>0</EmpSeq>
    <EmpName />
    <SMABC>2002001</SMABC>
    <ItemClassLName>test5</ItemClassLName>
    <ItemClassMName>1111</ItemClassMName>
    <RegUser>����õ</RegUser>
    <RegDate>20141105</RegDate>
    <LastUser />
    <LastDate />
    <UMItemClassS>2001040</UMItemClassS>
    <ItemClassSName>TEST</ItemClassSName>
    <ItemSName />
    <ItemEngName />
    <ItemEngSName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025570,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021310

rollback 