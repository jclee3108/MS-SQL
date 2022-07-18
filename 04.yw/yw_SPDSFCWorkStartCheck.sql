  
IF OBJECT_ID('yw_SPDSFCWorkStartCheck') IS NOT NULL 
    DROP PROC yw_SPDSFCWorkStartCheck 
GO 
  
-- v2013.08.01 
  
-- ���������Է�(����)_YW(üũ) by����õ
CREATE PROC yw_SPDSFCWorkStartCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
      
    CREATE TABLE #YW_TPDSFCWorkStart( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TPDSFCWorkStart'   
    IF @@ERROR <> 0 RETURN     
    
    -- ���� �α׳�������� ������ INSERT
    
    INSERT INTO #YW_TPDSFCWorkStart
    (
        WorkingTag, Status, EmpSeqOld, Serl, WorkCenterSeq, WorkOrderSeq
    )    
    SELECT B.WorkingTag, B.Status, A.EmpSeq, A.Serl, B.WorkCenterSeq, B.WorkOrderSeq
      FROM YW_TPDSFCWorkStart AS A
      JOIN #YW_TPDSFCWorkStart AS B ON ( B.WorkCenterSeq = A.WorkCenterSeq AND B.WorkOrderSeq = A.WorkOrderSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND @WorkingTag = 'Delete'
    
    DELETE FROM #YW_TPDSFCWorkStart WHERE @WorkingTag = 'Delete' AND EmpSeqOld IS NULL
    
    -- ����������üũ: UPDATE, DELETE�� ������ �������� ������ ����ó��  
    
    IF NOT EXISTS ( SELECT 1   
                      FROM #YW_TPDSFCWorkStart AS A   
                      JOIN YW_TPDSFCWorkStart AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.WorkCenterSeq = B.WorkCenterSeq AND A.EmpSeqOld = B.EmpSeq )  
                     WHERE A.WorkingTag IN ( 'U', 'D' )  
                       AND Status = 0   
                  )  
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              7                  , -- �ڷᰡ��ϵǾ������ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                              @LanguageSeq               
    
        UPDATE #YW_TPDSFCWorkStart  
           SET Result       = @Results,  
               MessageType  = @MessageType,  
               Status       = @Status  
         WHERE WorkingTag IN ( 'U', 'D' )  
           AND Status = 0   
    END   
    
    -- üũ 1, �ߺ��� ���� �ԷµǾ����ϴ�. 
    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
                          @LanguageSeq       ,  
                          3542, '��1'--,  -- SELECT * FROM _TCADictionary WHERE Word like '%��%'  
                          --3543, '��2'  
    
    UPDATE #YW_TPDSFCWorkStart 
       SET Result       = @Results, 
           MessageType  = @MessageType, 
           Status       = @Status 
      FROM #YW_TPDSFCWorkStart AS A 
      JOIN (SELECT S.WorkCenterSeq, S.EmpSeq 
              FROM (SELECT A1.WorkCenterSeq, A1.EmpSeq 
                      FROM #YW_TPDSFCWorkStart AS A1 
                     WHERE A1.WorkingTag IN ('A', 'U') 
                       AND A1.Status = 0 
    
                    UNION ALL 
    
                    SELECT A1.WorkCenterSeq, A1.EmpSeq 
                      FROM YW_TPDSFCWorkStart AS A1 
                     WHERE A1.CompanySeq = @CompanySeq 
                       AND NOT EXISTS (SELECT 1 FROM #YW_TPDSFCWorkStart 
                                               WHERE WorkingTag IN ('U','D') 
                                                 AND Status = 0 
                                                 AND WorkCenterSeq = A1.WorkCenterSeq 
                                                 AND EmpSeq = A1.EmpSeq 
                                      ) 
                   ) AS S 
             GROUP BY S.WorkCenterSeq, S.EmpSeq 
            HAVING COUNT(1) > 1 
           ) AS B ON ( A.WorkCenterSeq = B.WorkCenterSeq AND A.EmpSeq = B.EmpSeq ) 
     WHERE A.WorkingTag IN ('A', 'U') 
       AND A.Status = 0 
    
    -- üũ1, END 
    
    -- üũ2, ���Խ����� �Է� �� �ķδ� �۾��ڸ� ���� �� �� �����ϴ�. 
    
    UPDATE #YW_TPDSFCWorkStart 
       SET Result       = '���Խ����� �Է� �� �ķδ� �۾��ڸ� ���� �� �� �����ϴ�.', 
           MessageType  = @MessageType, 
           Status       = 51315 
      FROM #YW_TPDSFCWorkStart AS A 
     WHERE WorkingTag = 'U' 
       AND Status = 0 
       AND A.StartTime <> '' 
       AND A.EmpSeq <> A.EmpSeqOld 
    
    -- üũ2, END 
    
    -- üũ3, ���Խ����� ���� �ʾҽ��ϴ�. 
    
    IF @WorkingTag = 'EndTime' 
    BEGIN 
        UPDATE #YW_TPDSFCWorkStart 
           SET Result       = '���Խ����� ���� �ʾҽ��ϴ�.', 
               MessageType  = @MessageType, 
               Status       = 324523423 
          FROM #YW_TPDSFCWorkStart AS A 
         WHERE WorkingTag = 'A' 
           AND Status = 0 
           AND A.StartTime = '' 
    END 
    
    -- üũ3, END 
    
    -- üũ4, �̹� �������ᰡ �Ϸ�Ǿ����ϴ�. 
    
    IF @WorkingTag = 'EndTime' 
    BEGIN 
        UPDATE #YW_TPDSFCWorkStart 
           SET Result       = '�̹� �������ᰡ �Ϸ�Ǿ����ϴ�.', 
               MessageType  = @MessageType, 
               Status       = 324523423 
          FROM #YW_TPDSFCWorkStart AS A 
         WHERE WorkingTag = 'U' 
           AND Status = 0 
           AND A.EndTime <> '' 
    END 
    
    -- üũ4, END 
    

    -- �ø��� ä���ϱ� 
    IF @WorkingTag = 'StartTime' 
    BEGIN 
        -- ��ȣ+�ڵ� ���� 
        DECLARE @Count  INT, 
                @Serl   INT 
                
        -- �������ᰡ �ϳ��� ���� �ʾ��� ��� MAX�� ���� ����
        IF EXISTS (SELECT TOP 1 A.EndTime 
                      FROM YW_TPDSFCWorkStart AS A
                      JOIN #YW_TPDSFCWorkStart AS B WITH(NOLOCK) ON ( B.WorkOrderSeq = A.WorkOrderSeq AND B.WorkCenterSeq = A.WorkCenterSeq ) 
                     WHERE A.CompanySeq = @CompanySeq 
                       AND A.EndTime = '' 
                  )
        BEGIN
            UPDATE B
               SET B.Serl = A.Serl
              FROM YW_TPDSFCWorkStart AS A
              JOIN #YW_TPDSFCWorkStart AS B WITH(NOLOCK) ON ( B.WorkOrderSeq = A.WorkOrderSeq AND B.WorkCenterSeq = A.WorkCenterSeq ) 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.EndTime = '' 
               AND WorkingTag = 'A' 
               AND Status = 0 
        END
        
        -- ��� �������ᰡ �Ǿ��� ��� ä��
        ELSE
        BEGIN             
            SELECT @Count = COUNT(1) FROM #YW_TPDSFCWorkStart WHERE WorkingTag = 'A' AND Status = 0 
        
            IF @Count > 0 
            BEGIN 
                -- Ű�������ڵ�κ� ���� 
                EXEC @Serl = dbo._SCOMCreateSeq @CompanySeq, 'YW_TPDSFCWorkStart', 'Serl', 1 
        
                -- Temp Talbe �� ������ Ű�� UPDATE 
                UPDATE #YW_TPDSFCWorkStart 
                   SET Serl = @Serl + 1 
                 WHERE WorkingTag = 'A' 
                   AND Status = 0 
            END
        END
    END 
    
    SELECT * FROM #YW_TPDSFCWorkStart 
    
    RETURN  
GO

exec yw_SPDSFCWorkStartCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Sel>0</Sel>
    <EmpName>������</EmpName>
    <EmpSeq>2017</EmpSeq>
    <StartTime />
    <EndTime />
    <EmpSeqOld>0</EmpSeqOld>
    <Serl>0</Serl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <WorkCenterSeq>2</WorkCenterSeq>
    <WorkOrderSeq>131292</WorkOrderSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016755,@WorkingTag=N'StartTime',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014297