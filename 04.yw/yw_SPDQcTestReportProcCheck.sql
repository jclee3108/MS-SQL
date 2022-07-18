  
IF OBJECT_ID('yw_SPDQcTestReportProcCheck') IS NOT NULL 
    DROP PROC yw_SPDQcTestReportProcCheck 
GO

-- v2013.07.18 
  
-- �����˻��Է�_YW(üũ) by����õ 
CREATE PROC yw_SPDQcTestReportProcCheck 
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS     
    DECLARE @MessageType  INT, 
            @Status       INT, 
            @Results      NVARCHAR(250), 
            @Count        INT, 
            @Seq          INT 
    
    CREATE TABLE #YW_TPDQCTestReport( WorkingTag NCHAR(1) NULL ) 
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TPDQCTestReport' 
    IF @@ERROR <> 0 RETURN 
    
    CREATE TABLE #YW_TPDQCTestReportSub( WorkingTag NCHAR(1) NULL ) 
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#YW_TPDQCTestReportSub' 
    IF @@ERROR <> 0 RETURN 
    
    IF EXISTS ( SELECT 1 FROM #YW_TPDQCTestReport ) 
    BEGIN 
        -- ����������üũ: UPDATE, DELETE�� ������ �������� ������ ����ó�� 
        IF NOT EXISTS ( SELECT 1 
                          FROM #YW_TPDQCTestReport AS A 
                          JOIN YW_TPDQCTestReport  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.QCSeq ) 
                         WHERE A.WorkingTag IN ( 'U', 'D' ) 
                           AND A.Status = 0 
                      ) 
        BEGIN 
            EXEC dbo._SCOMMessage @MessageType OUTPUT, 
                                  @Status      OUTPUT, 
                                  @Results     OUTPUT, 
                                  7                  , -- �ڷᰡ��ϵǾ������ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7) 
                                  @LanguageSeq 
        
            UPDATE #YW_TPDQCTestReport 
               SET Result       = @Results, 
                   MessageType  = @MessageType, 
                   Status       = @Status 
             WHERE WorkingTag IN ( 'U', 'D' ) 
               AND Status = 0 
        END 
        
        -- Seq ���� 
        SELECT @Count = COUNT(1) FROM #YW_TPDQCTestReport WHERE WorkingTag = 'A' AND Status = 0 
        
        IF @Count > 0 
        BEGIN 
            -- Ű�������ڵ�κ� ����    
            EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'YW_TPDQCTestReport', 'QCSeq', @Count 
        
            -- Temp Talbe �� ������ Ű�� UPDATE 
            UPDATE #YW_TPDQCTestReport 
               SET QCSeq = @Seq 
             WHERE WorkingTag = 'A' 
               AND Status =  0 
        END 
        ELSE 
            SELECT @Seq = (SELECT QCSeq FROM #YW_TPDQCTestReport) 
        
        EXEC dbo._SCOMMessage @MessageType OUTPUT, 
                              @Status      OUTPUT, 
                              @Results     OUTPUT, 
                              1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055) 
                              @LanguageSeq 
        
        UPDATE #YW_TPDQCTestReport 
           SET Result        = @Results, 
               MessageType   = @MessageType, 
               Status        = @Status 
         WHERE Status = 0 
           AND ( QCSeq = 0 OR QCSeq IS NULL ) 
    END 
    
    IF EXISTS ( SELECT 1 FROM #YW_TPDQCTestReportSub ) 
    BEGIN 
        -- ����������üũ: UPDATE, DELETE�� ������ �������� ������ ����ó�� 
        IF EXISTS ( SELECT 1 
                      FROM #YW_TPDQCTestReportSub AS A 
                      LEFT OUTER JOIN YW_TPDQCTestReportSub AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.QCSeq 
                                                                             AND B.UMQcTitleSeq = A.UMQcTitleSeqOld AND B.Serl = A.Serl ) 
                     WHERE A.WorkingTag IN ( 'U', 'D' ) 
                       AND A.Status = 0 
                       AND B.QCSeq IS NULL 
                  ) 
        BEGIN 
            EXEC dbo._SCOMMessage @MessageType OUTPUT, 
                                  @Status      OUTPUT, 
                                  @Results     OUTPUT, 
                                  7                  , -- �ڷᰡ��ϵǾ������ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7) 
                                  @LanguageSeq 
        
            UPDATE A 
               SET Result       = @Results, 
                   MessageType  = @MessageType, 
                   Status       = @Status 
              FROM #YW_TPDQCTestReportSub AS A 
              LEFT OUTER JOIN YW_TPDQCTestReportSub  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.QCSeq 
                                                                      AND B.UMQcTitleSeq = A.UMQcTitleSeqOld AND B.Serl = A.Serl ) 
             WHERE A.WorkingTag IN ( 'U', 'D' ) 
               AND A.Status = 0 
               AND B.QCSeq IS NULL 
        END 
        
        UPDATE #YW_TPDQCTestReportSub 
           SET QCSeq = @Seq, 
               Serl  = 1 
         WHERE WorkingTag = 'A' 
           AND Status = 0 
          
        -- �ߺ����� üũ 
        EXEC dbo._SCOMMessage @MessageType OUTPUT, 
                              @Status      OUTPUT, 
                              @Results     OUTPUT, 
                              1107               , -- �ش� @1��(��) ������ ��ϵ� @2��(��) �ߺ��˴ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%') 
                              @LanguageSeq       , 
                              0, '�˻缼���׸�',  -- SELECT * FROM _TCADictionary WHERE Word like '%��%' 
                              0, '�˻缼���׸�' 
          
        UPDATE A    
           SET Result       = @Results, 
               MessageType  = @MessageType, 
               Status       = @Status 
          FROM #YW_TPDQCTestReportSub AS A 
          JOIN (SELECT S.QCSeq, S.UMQcTitleSeq, ISNULL(S.Serl,1) AS Serl 
                  FROM (SELECT A1.QCSeq, A1.UMQcTitleSeq, A1.Serl 
                          FROM #YW_TPDQCTestReportSub AS A1 
                         WHERE A1.WorkingTag IN ('A', 'U') 
                           AND A1.Status = 0 
        
                        UNION ALL 
        
                        SELECT A1.QCSeq, A1.UMQcTitleSeq, A1.Serl 
                          FROM YW_TPDQcTestReportSub AS A1 
        WHERE A1.CompanySeq = @CompanySeq 
                           AND NOT EXISTS (SELECT 1 FROM #YW_TPDQCTestReportSub 
                                                   WHERE Status = 0 
                                                     AND ( WorkingTag = 'D' 
                                                      OR ( WorkingTag = 'U' AND UMQCTitleSeq <> UMQCTitleSeqOld )) 
                                                     AND QCSeq = A1.QCSeq 
                                                     AND Serl = A1.Serl 
                                                     AND UMQcTitleSeqOld = A1.UMQcTitleSeq 
                                          ) 
                       ) AS S 
                 GROUP BY S.QCSeq, S.UMQcTitleSeq, Serl 
                HAVING COUNT(1) > 1 
               ) AS B ON ( A.QCSeq = B.QCSeq AND A.Serl = B.Serl AND A.UMQcTitleSeq = B.UMQcTitleSeq ) 
         WHERE A.WorkingTag IN ('A', 'U') 
           AND A.Status = 0 
          
    END    
      
    SELECT * FROM #YW_TPDQCTestReport 
    SELECT * FROM #YW_TPDQCTestReportSub 
    
    RETURN 
GO