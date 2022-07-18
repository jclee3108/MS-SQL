
IF OBJECT_ID('jongie_SCMEnvQuery') IS NOT NULL
    DROP PROC jongie_SCMEnvQuery
GO
    
-- v2013.08.07   
  
-- (���̳���) �߰����� Mapping���� ����_jongie-��ȸ by ��ö�� (copy ����õ)      
CREATE PROC jongie_SCMEnvQuery        
    @xmlDocument    NVARCHAR(MAX) ,        
    @xmlFlags       INT     = 0,        
    @ServiceSeq     INT     = 0,        
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT     = 1,        
    @LanguageSeq    INT     = 1,        
    @UserSeq        INT     = 0,        
    @PgmSeq         INT     = 0        
AS        
    --DECLARE @docHandle      INT,        
    --        @ConfigSeq      INT,        
    --        @SMUseType     INT        
          
    --EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument        
          
    --SELECT @ConfigSeq  = ISNULL(Seq, 0),        
    --       @SMUseType  = ISNULL(SMUseType, 0)        
    --  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)        
    --  WITH (Seq         INT,        
    --        SMUseType   INT      
    --       )        
          
    -- �ڵ�����Name �������� �ӽ�Table        
    CREATE TABLE #GetName        
    (        
        EnvSeq          INT,        
        EnvSerl         INT,        
        EnvValueName    NVARCHAR(100)        
    )        
        
    DECLARE @EnvValue       NVARCHAR(500),        
            @SqlState       NVARCHAR(MAX),        
            @EnvSeq         INT,       
            @EnvSerl        INT,        
            @CodeHelpSeq    INT,        
            @MinorSeq       INT        
          
    DECLARE Name_cursor CURSOR FOR         
    --SELECT B.EnvSeq, B.EnvValue, B.CodeHelpSeq, B.MinorSeq        
    --  FROM _TCOMEnvConfigItem   AS A       
    --  JOIN _TCOMEnv             AS B ON(A.EnvSeq = B.EnvSeq)        
    --  JOIN _TCACodeHelpData     AS C WITH(NOLOCK) ON B.CodeHelpSeq = C.CodeHelpSeq        
    -- WHERE  A.ConfigSeq      = @ConfigSeq        
    --   AND  B.CompanySeq     = @CompanySeq        
    --   AND (B.SMControlType  = 84003 OR ( B.SMControlType = 84004 AND B.MinorSeq = 0 ))        
    --   AND  B.CodeHelpSeq   <> 0        
    --   AND  B.EnvValue       > ''        
    --   AND  C.NameColumnName > ''        
    --   AND  C.TableName      > ''        
    --   AND  C.SeqColumnName  > ''      
    SELECT B.EnvSeq, B.EnvSerl, B.EnvValue, B.CodeHelpSeq, B.MinorSeq        
      FROM jongie_TCOMEnv          AS B WITH(NOLOCK)      
      JOIN _TCACodeHelpData     AS C WITH(NOLOCK) ON B.CodeHelpSeq = C.CodeHelpSeq        
     WHERE B.CompanySeq = @CompanySeq        
       AND (B.SMControlType  = 84003 OR ( B.SMControlType = 84004 AND B.MinorSeq = 0 ))        
       AND B.CodeHelpSeq   <> 0        
       AND B.EnvValue       > ''        
       AND C.NameColumnName > ''        
       AND C.TableName      > ''        
       AND C.SeqColumnName  > ''          
     ORDER BY B.EnvSeq        
          
    OPEN Name_cursor        
          
    FETCH NEXT FROM Name_cursor INTO @EnvSeq, @EnvSerl, @EnvValue, @CodeHelpSeq, @MinorSeq        
          
    WHILE @@FETCH_STATUS = 0        
    BEGIN        
        IF @CodeHelpSeq = 19998 -- �ý���������Ÿ�ڵ�        
        BEGIN       
                  
            SELECT @SqlState = 'SELECT ' + CONVERT(NVARCHAR(10), @EnvSeq) + ', ' + CONVERT(NVARCHAR(10), @EnvSerl) + ', ' + A.NameColumnName +         
                               ' FROM ' + A.TableName + ' WITH(NOLOCK)' +        
                               ' WHERE CompanySeq = ' + CONVERT(NVARCHAR(10), @CompanySeq) +        
                               '   AND MajorSeq = ' + CONVERT(NVARCHAR(10), @MinorSeq) +        
                               '   AND ' + (CASE B.SysType WHEN '1' THEN 'MinorSeq'        
                                                           WHEN '2' THEN 'MinorValue' END) + ' = ' + '''' + @EnvValue + ''''        
              FROM _TCACodeHelpData AS A WITH(NOLOCK)        
              JOIN _TDASMajor       AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND B.MajorSeq = @MinorSeq        
             WHERE A.CodeHelpSeq = @CodeHelpSeq        
                  
        END      
        ELSE      
          BEGIN          
                  
            SELECT @SqlState = 'SELECT ' + CONVERT(NVARCHAR(10), @EnvSeq) + ', ' + CONVERT(NVARCHAR(10), @EnvSerl) + ', ' + NameColumnName +         
              ' FROM ' + TableName + ' WITH(NOLOCK)' +        
                               ' WHERE CompanySeq = ' + CONVERT(NVARCHAR(10), @CompanySeq) +        
       '   AND ' + SeqColumnName + ' = ' + @EnvValue        
              FROM _TCACodeHelpData WITH(NOLOCK)       
             WHERE CodeHelpSeq = @CodeHelpSeq        
                  
        END -- end if       
              
        INSERT #GetName EXEC ( @SqlState )        
              
        FETCH NEXT FROM Name_cursor INTO @EnvSeq, @EnvSerl, @EnvValue, @CodeHelpSeq, @MinorSeq        
              
    END -- end while       
          
    CLOSE Name_cursor        
          
    DEALLOCATE Name_cursor        
          
    --select * From #GetName      
    --return      
          
    --SELECT B.EnvSeq        , B.EnvName       , B.Description   , B.EnvValue      ,        
    --       B.ModuleSeq     , B.SMControlType , B.CodeHelpSeq   , B.MinorSeq      , B.SMUseType     ,        
    --       B.QuerySort     , B.LastDateTime  , B.DecLength     ,      
    --       C.UserName       AS LastUserName  ,      
    --       D.CodeHelpTitle  AS CodeHelpName  ,      
    --       B.EnvValue       AS EnvValueName  ,      
    --       B.AddCheckScript,      
    --       B.AddSaveScript         
    --  FROM _TCOMEnvConfigItem AS A         
    --  JOIN _TCOMEnv           AS B WITH(NOLOCK) ON A.EnvSeq = B.EnvSeq        
    --                                    AND B.CompanySeq = @CompanySeq        
    --                                    AND (B.SMControlType IN (84001, 84002, 84005, 84006, 84007, 84008)          -- ����, ����, ��¥, üũ, ���̾�α�, ����ũ        
    --                                        OR (B.SMControlType = 84004 AND B.MinorSeq <> 0)                        -- ��������� �ڵ�����(�޺�)        
    --                                        OR (B.SMControlType = 84004 AND B.MinorSeq = 0 AND B.CodeHelpSeq = 0))  -- ���� ���� �ڵ�����(�޺�)        
    --  LEFT OUTER JOIN _TCAUser         AS C WITH(NOLOCK) ON B.LastUserSeq = C.UserSeq        
    --  LEFT OUTER JOIN _TCACodeHelpData AS D WITH(NOLOCK) ON B.CodeHelpSeq = D.CodeHelpSeq        
    -- WHERE A.ConfigSeq = @ConfigSeq        
    --   AND B.SMUseType & @SMUseType  = @SMUseType        
          
    SELECT B.EnvSeq        , B.EnvSerl,       
           B.EnvName       , B.Description   , B.EnvValue      ,        
           B.ModuleSeq     , B.SMControlType , B.CodeHelpSeq   , B.MinorSeq      , B.SMUseType     ,        
           B.QuerySort     , B.LastDateTime  , B.DecLength     ,      
           C.UserName       AS LastUserName  ,      
           D.CodeHelpTitle  AS CodeHelpName  ,      
           B.EnvValue       AS EnvValueName  ,      
           B.AddCheckScript,      
           B.AddSaveScript         
      FROM jongie_TCOMEnv                  AS B WITH(NOLOCK)      
      LEFT OUTER JOIN _TCAUser          AS C WITH(NOLOCK) ON ( B.LastUserSeq = C.UserSeq )      
      LEFT OUTER JOIN _TCACodeHelpData  AS D WITH(NOLOCK) ON ( B.CodeHelpSeq = D.CodeHelpSeq )       
     WHERE B.CompanySeq = @CompanySeq      
       AND (B.SMControlType IN (84001, 84002, 84005, 84006, 84007, 84008)      -- ����, ����, ��¥, üũ, ���̾�α�, ����ũ        
         OR (B.SMControlType = 84004 AND B.MinorSeq <> 0)                      -- ��������� �ڵ�����(�޺�)        
         OR (B.SMControlType = 84004 AND B.MinorSeq = 0 AND B.CodeHelpSeq = 0) -- ���� ���� �ڵ�����(�޺�)        
           )        
          
    UNION ALL        
          
    -- �ڵ�����        
    --SELECT DISTINCT        
    --       B.EnvSeq        , B.EnvName       , B.Description   , B.EnvValue      ,        
    --       B.ModuleSeq     , B.SMControlType , B.CodeHelpSeq   , B.MinorSeq      , B.SMUseType     ,        
    --       B.QuerySort     , B.LastDateTime  , B.DecLength     ,      
    --       C.UserName       AS LastUserName  ,      
      --       D.CodeHelpTitle  AS CodeHelpName  ,      
    --       ISNULL(E.EnvValueName, '') AS EnvValueName,      
    --       B.AddCheckScript,      
    --       B.AddSaveScript       
    --  FROM _TCOMEnvConfigItem AS A         
    --  JOIN _TCOMEnv           AS B WITH(NOLOCK) ON A.EnvSeq = B.EnvSeq        
    --          AND B.CompanySeq = @CompanySeq        
    --                                    AND (B.SMControlType = 84003                                                -- �ڵ�����         
    --                                        OR (B.SMControlType = 84004 AND B.MinorSeq = 0 AND B.CodeHelpSeq <> 0)) -- �ڵ�����(�޺�)        
    --  LEFT OUTER JOIN _TCAUser          AS C WITH(NOLOCK) ON B.LastUserSeq = C.UserSeq        
    --  LEFT OUTER JOIN _TCACodeHelpData  AS D WITH(NOLOCK) ON B.CodeHelpSeq = D.CodeHelpSeq        
    --  LEFT OUTER JOIN #GetName          AS E WITH(NOLOCK) ON B.EnvSeq = E.EnvSeq        
    -- WHERE A.ConfigSeq = @ConfigSeq        
    --   AND B.SMUseType & @SMUseType  = @SMUseType        
    SELECT DISTINCT        
           B.EnvSeq        , B.EnvSerl,       
           B.EnvName       , B.Description   , B.EnvValue      ,        
           B.ModuleSeq     , B.SMControlType , B.CodeHelpSeq   , B.MinorSeq      , B.SMUseType     ,        
           B.QuerySort     , B.LastDateTime  , B.DecLength     ,      
           C.UserName       AS LastUserName  ,      
           D.CodeHelpTitle  AS CodeHelpName  ,      
           ISNULL(E.EnvValueName, '') AS EnvValueName,      
           B.AddCheckScript,      
           B.AddSaveScript       
      FROM jongie_TCOMEnv                  AS B WITH(NOLOCK)      
      LEFT OUTER JOIN _TCAUser          AS C WITH(NOLOCK) ON ( B.LastUserSeq = C.UserSeq )       
      LEFT OUTER JOIN _TCACodeHelpData  AS D WITH(NOLOCK) ON ( B.CodeHelpSeq = D.CodeHelpSeq )       
      LEFT OUTER JOIN #GetName          AS E WITH(NOLOCK) ON ( B.EnvSeq = E.EnvSeq AND B.EnvSerl = E.EnvSerl )       
     WHERE B.CompanySeq = @CompanySeq        
       AND (B.SMControlType = 84003                                             -- �ڵ�����         
         OR (B.SMControlType = 84004 AND B.MinorSeq = 0 AND B.CodeHelpSeq <> 0) -- �ڵ�����(�޺�)        
           )       
     ORDER BY B.QuerySort        
          
    RETURN        