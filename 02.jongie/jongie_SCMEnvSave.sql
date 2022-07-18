
IF OBJECT_ID('jongie_SCMEnvSave') IS NOT NULL
    DROP PROC jongie_SCMEnvSave
GO
    
-- v2013.08.07   
  
-- (���̳���) �߰����� Mapping���� ����_jongie-���� by ��ö�� (copy ����õ)      
CREATE PROC jongie_SCMEnvSave        
    @xmlDocument    NVARCHAR(MAX),        
    @xmlFlags       INT     = 0,        
    @ServiceSeq     INT     = 0,        
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT     = 1,        
    @LanguageSeq    INT     = 1,        
    @UserSeq        INT     = 0,        
    @PgmSeq         INT     = 0        
AS        
    CREATE TABLE #TCOMEnv (WorkingTag NCHAR(1) NULL)        
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TCOMEnv'        
    IF @@ERROR <> 0 RETURN        
          
    -- �α� �����          
    DECLARE @TableColumns NVARCHAR(4000)          
          
    -- Master �α�         
    SELECT @TableColumns = dbo._FGetColumnsForLog('jongie_TCOMEnv')          
          
    EXEC _SCOMLog @CompanySeq   ,              
                  @UserSeq      ,              
                  'jongie_TCOMEnv'    , -- ���̺��      -- JYO_TSLYearSalesPlanItemLog        
                  '#TCOMEnv'    , -- �ӽ� ���̺��              
                  'EnvSeq, EnvSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )              
                  @TableColumns, '', @PgmSeq  -- ���̺� ��� �ʵ��         
          
    -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT        
          
    -- DELETE        
    --IF EXISTS (SELECT TOP 1 1 FROM #TCOMEnv WHERE WorkingTag = 'D' AND Status = 0)        
    --BEGIN        
    --    DELETE _TCOMEnv        
    --      FROM #TCOMEnv AS A        
    --        JOIN _TCOMEnv AS B ON (A.EnvSeq = B.EnvSeq)        
    --     WHERE  A.WorkingTag = 'D'        
    --        AND A.Status = 0        
    --        AND B.CompanySeq = @CompanySeq        
    --    IF @@ERROR <> 0  RETURN        
    --END        
          
    -- UPDATE        
    IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag = 'U' AND Status = 0)        
    BEGIN        
              
        UPDATE B        
           SET EnvValue        = A.EnvValue,        
               LastUserSeq     = @UserSeq,        
               LastDateTime    = GETDATE()        
          FROM #TCOMEnv     AS A        
          JOIN jongie_TCOMEnv  AS B ON ( A.EnvSeq = B.EnvSeq AND A.EnvSerl = B.EnvSerl )        
         WHERE  A.WorkingTag = 'U'        
           AND A.Status = 0        
           AND B.CompanySeq = @CompanySeq        
              
        IF @@ERROR <> 0  RETURN        
          
    END -- end if       
        
    -- INSERT        
    --IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag = 'A' AND Status = 0)        
    --BEGIN        
    --    INSERT INTO _TCOMEnv       
    --    (      
    --        CompanySeq, EnvSeq, EnvName, Description, EnvValue,       
    --        ModuleSeq, SMControlType, CodeHelpSeq, MinorSeq, SMUseType,       
    --        QuerySort, DecLength, AddCheckScript, AddSaveScript, LastUserSeq,       
    --        LastDateTime      
    --    )        
    --    SELECT @CompanySeq, EnvSeq, EnvName, Description, EnvValue, ModuleSeq, SMControlType, CodeHelpSeq, MinorSeq, SMUseType, QuerySort, DecLength, AddCheckScript, AddSaveScript, @UserSeq, GETDATE()        
    --          FROM #TCOMEnv AS A        
    --         WHERE  A.WorkingTag = 'A'        
    --            AND A.Status = 0        
    --    IF @@ERROR <> 0 RETURN        
    --END        
          
    -- AddSave �߰�����SP�� �������        
    IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag IN ('A','U') AND Status = 0 AND ISNULL(AddSaveScript, '') <> '')        
    BEGIN        
        DECLARE @EnvSeq         INT,        
                @AddSaveScript  NVARCHAR(100),        
                @EnvValue       NVARCHAR(50)              
        
        DECLARE Check_cursor CURSOR FOR        
              SELECT EnvSeq, AddSaveScript,EnvValue        
              FROM #TCOMEnv        
             WHERE  WorkingTag IN ('A','U')        
                AND Status = 0        
                AND ISNULL(AddSaveScript, '') <> ''        
               ORDER BY EnvSeq         
        OPEN Check_cursor        
        FETCH NEXT FROM Check_cursor INTO @EnvSeq, @AddSaveScript,@EnvValue        
        WHILE @@FETCH_STATUS = 0        
        BEGIN        
        
            EXEC @AddSaveScript @EnvSeq, @CompanySeq, @LanguageSeq, @UserSeq, @PgmSeq,@EnvValue        
        
            FETCH NEXT FROM Check_cursor        
            INTO @EnvSeq, @AddSaveScript,@EnvValue        
        END        
    END        
          
    SELECT * FROM #TCOMEnv        
          
    RETURN        