  
IF OBJECT_ID('yw_SPJTResultCheck') IS NOT NULL   
    DROP PROC yw_SPJTResultCheck  
GO  
  
-- v2014.07.02  
  
-- ������Ʈ�����Է�_YW(üũ) by ����õ   
CREATE PROC yw_SPJTResultCheck  
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
      
    CREATE TABLE #yw_TPJTWBSResult( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#yw_TPJTWBSResult'   
    IF @@ERROR <> 0 RETURN     
    
    DELETE A 
      FROM #yw_TPJTWBSResult AS A 
     WHERE ISNULL(A.BegDate,'') = '' 
       AND ISNULL(A.EndDate,'') = '' 
       AND ISNULL(A.ChgDate,'') = '' 
       AND ISNULL(A.Results,'') = '' 
       AND ISNULL(FileSeq,0) = 0 
    
    --------------------------------------------------------------------------------------------------------------------------
    -- üũ0, ����������üũ: UPDATE, DELETE�� ������ �������� ������ ����ó��  
    --------------------------------------------------------------------------------------------------------------------------
    IF NOT EXISTS ( SELECT 1   
                      FROM #yw_TPJTWBSResult AS A   
                      JOIN yw_TPJTWBSResult AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.PJTSeq = B.PJTSeq AND A.UMWBSSeq = A.UMWBSSeq ) 
                     WHERE A.WorkingTag IN ( 'U', 'D' )  
                       AND Status = 0   
                  )  
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              7                  , -- �ڷᰡ��ϵǾ������ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                              @LanguageSeq               
          
        UPDATE #yw_TPJTWBSResult  
           SET Result       = @Results,  
               MessageType  = @MessageType,  
               Status       = @Status  
         WHERE WorkingTag IN ( 'U', 'D' )  
           AND Status = 0   
    END   
    --------------------------------------------------------------------------------------------------------------------------
    -- üũ0 END 
    --------------------------------------------------------------------------------------------------------------------------
    
    --------------------------------------------------------------------------------------------------------------------------
    -- üũ1, �ش� WBS�� ���۵��� �ʾ� ����, ������ �� �����ϴ�. 
    --------------------------------------------------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '�ش� WBS�� ���۵��� �ʾ� ����, ������ �� �����ϴ�.', 
           MessageType = 1234, 
           Status = 1234
      FROM #yw_TPJTWBSResult AS A 
     WHERE A.WorkingTag IN ('A','U')
      AND A.Status = 0 
       AND ((ISNULL(A.BegDate,'') = '' AND ISNULL(A.ChgDate,'') <> '') OR (ISNULL(A.BegDate,'') = '' AND ISNULL(A.EndDate,'') <> '' ))
    --------------------------------------------------------------------------------------------------------------------------
    -- üũ1, END 
    --------------------------------------------------------------------------------------------------------------------------
    
    --------------------------------------------------------------------------------------------------------------------------
    -- üũ2, �� WBS�� ������� �ʾ� ������ �� �� �����ϴ�. 
    --------------------------------------------------------------------------------------------------------------------------
    
    CREATE TABLE #TEMP 
    (
        UMWBSSeq    INT, 
        BegDate     NCHAR(8), 
        EndDate     NCHAR(8), 
        Original    INT 
    )
    INSERT INTO #TEMP (UMWBSSeq, BegDate, EndDate, Original) 
    SELECT A.UMWBSSeq, A.BegDate, A.EndDate, 1 
      FROM yw_TPJTWBSResult AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PJTSeq = (SELECT TOP 1 PJTSeq FROM #yw_TPJTWBSResult) 
       AND A.UMWBSSeq NOT IN (SELECT UMWBSSeq FROM #yw_TPJTWBSResult)
    
    UNION ALL 
    
    SELECT A.UMWBSSeq, A.BegDate, A.EndDate, 2 
      FROM #yw_TPJTWBSResult AS A 
    
    
    UPDATE #yw_TPJTWBSResult 
       SET Result = '�� WBS�� ������� �ʾ� ������ �� �� �����ϴ�.', 
           MessageType = 1234, 
           Status = 1234
      FROM #TEMP AS A 
     WHERE A.UMWBSSeq <> (SELECT MAX(UMWBSSeq) FROM #yw_TPJTWBSResult) 
       AND A.UMWBSSeq = (SELECT MAX(UMWBSSeq) FROM #TEMP WHERE UMWBSSeq <> (SELECT MAX(UMWBSSeq) FROM #yw_TPJTWBSResult) ) 
       AND ISNULL(A.EndDate,'') = '' 
    
    --------------------------------------------------------------------------------------------------------------------------
    -- üũ2, END 
    --------------------------------------------------------------------------------------------------------------------------
    
    --------------------------------------------------------------------------------------------------------------------------
    -- üũ3, ����,�������� �����Ϻ��� ���� �� �����ϴ�. 
    --------------------------------------------------------------------------------------------------------------------------
    UPDATE A 
        SET Result = '����,�������� �����Ϻ��� ���� �� �����ϴ�.', 
            MessageType = 1234, 
            Status = 1234
      FROM #yw_TPJTWBSResult AS A 
     WHERE A.WorkingTag IN ('A','U')
       AND A.Status = 0 
       AND ((BegDate > ChgDate AND ISNULL(ChgDate,'') <> '') OR (BegDate > EndDate AND ISNULL(EndDate,'') <> ''))
    --------------------------------------------------------------------------------------------------------------------------
    -- üũ3, END 
    --------------------------------------------------------------------------------------------------------------------------
    
    --------------------------------------------------------------------------------------------------------------------------
    -- üũ4, �� WBS �����Ϻ��� ���� �� �����ϴ�. 
    --------------------------------------------------------------------------------------------------------------------------
    
    IF (SELECT BegDate 
          FROM #TEMP 
         WHERE UMWBSSeq = (SELECT MAX(UMWBSSeq) FROM #TEMP) -- �����ϴ� ������ 
        ) <=  (SELECT EndDate 
                FROM #TEMP 
               WHERE UMWBSSeq <> (SELECT MAX(UMWBSSeq) FROM #TEMP) 
                 AND UMWBSSeq = ( SELECT MAX(UMWBSSeq) 
                                    FROM #TEMP 
                                   WHERE UMWBSSeq <> (SELECT MAX(UMWBSSeq) FROM #TEMP) 
                                ) 
             )
    BEGIN
    --select 1 
        UPDATE #yw_TPJTWBSResult 
            SET Result = '�������� ���ܰ� WBS �����Ϻ��� Ŀ�� �˴ϴ�.', 
                MessageType = 1234, 
                Status = 1234 
           FROM #yw_TPJTWBSResult 
          WHERE WorkingTag IN ('A','U') 
            AND Status = 0 
    END 
    
    --------------------------------------------------------------------------------------------------------------------------
    -- üũ4, END 
    --------------------------------------------------------------------------------------------------------------------------
    
    --------------------------------------------------------------------------------------------------------------------------
    -- üũ5, ���� WBS �������� ��ϵǸ� �ش� WBS ������ �� �����ϴ�. 
    --------------------------------------------------------------------------------------------------------------------------
    
    UPDATE A
        SET Result = '���� WBS �������� ��ϵǸ� �ش� WBS ����,���� �� �� �����ϴ�.', 
            MessageType = 1234, 
            Status = 1234 
      FROM #yw_TPJTWBSResult AS A 
     WHERE A.UMWBSSeq NOT IN (SELECT MAX(UMWBSSeq) FROM #TEMP) 
       AND A.WorkingTag IN ( 'U', 'D' ) 
       AND A.Status = 0 
    
    --------------------------------------------------------------------------------------------------------------------------
    -- üũ5, END 
    --------------------------------------------------------------------------------------------------------------------------    
    
    -- �޽��� ����� ���� ������Ʈ 
    IF EXISTS (SELECT 1 FROM #yw_TPJTWBSResult WHERE Status <> 0)
    BEGIN 
        UPDATE #yw_TPJTWBSResult
           SET Result = (SELECT TOP 1 Result FROM #yw_TPJTWBSResult WHERE ISNULL(Result,'') <> ''), 
               MessageType = 1234, 
               Status = 1234 
         WHERE ISNULL(Result,'') = '' 
    END 
    
    SELECT * FROM #yw_TPJTWBSResult   
      
    RETURN  
GO
exec yw_SPJTResultCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>1</Serl>
    <UMWBSSeq>1009757001</UMWBSSeq>
    <TargetDate>19000102</TargetDate>
    <BegDate>20140701</BegDate>
    <EndDate>20140703</EndDate>
    <ChgDate />
    <Results />
    <FileSeq>46387</FileSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <PJTSeq>1</PJTSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>4</Serl>
    <UMWBSSeq>1009757004</UMWBSSeq>
    <TargetDate>19000111</TargetDate>
    <BegDate />
    <EndDate />
    <ChgDate />
    <Results />
    <FileSeq>0</FileSeq>
    <PJTSeq>1</PJTSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>5</Serl>
    <UMWBSSeq>1009757005</UMWBSSeq>
    <TargetDate>19000111</TargetDate>
    <BegDate />
    <EndDate />
    <ChgDate />
    <Results />
    <FileSeq>0</FileSeq>
    <PJTSeq>1</PJTSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>6</Serl>
    <UMWBSSeq>1009757006</UMWBSSeq>
    <TargetDate>19000111</TargetDate>
    <BegDate />
    <EndDate />
    <ChgDate />
    <Results />
    <FileSeq>0</FileSeq>
    <PJTSeq>1</PJTSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>7</Serl>
    <UMWBSSeq>1009757007</UMWBSSeq>
    <TargetDate>19000111</TargetDate>
    <BegDate />
    <EndDate />
    <ChgDate />
    <Results />
    <FileSeq>0</FileSeq>
    <PJTSeq>1</PJTSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>8</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>8</Serl>
    <UMWBSSeq>1009757008</UMWBSSeq>
    <TargetDate>19000111</TargetDate>
    <BegDate />
    <EndDate />
    <ChgDate />
    <Results />
    <FileSeq>0</FileSeq>
    <PJTSeq>1</PJTSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>9</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>9</Serl>
    <UMWBSSeq>1009757009</UMWBSSeq>
    <TargetDate>19000111</TargetDate>
    <BegDate />
    <EndDate />
    <ChgDate />
    <Results />
    <FileSeq>0</FileSeq>
    <PJTSeq>1</PJTSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>10</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>10</Serl>
    <UMWBSSeq>1009757010</UMWBSSeq>
    <TargetDate>19000111</TargetDate>
    <BegDate />
    <EndDate />
    <ChgDate />
    <Results />
    <FileSeq>0</FileSeq>
    <PJTSeq>1</PJTSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1023453,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1019685