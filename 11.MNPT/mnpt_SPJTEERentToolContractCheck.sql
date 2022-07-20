  
IF OBJECT_ID('mnpt_SPJTEERentToolContractCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTEERentToolContractCheck  
GO  
    
-- v2017.11.21
  
-- �ܺ������������Է�-SS1üũ by ����õ
CREATE PROC mnpt_SPJTEERentToolContractCheck      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
    


    ------------------------------------------------------------------------
    -- üũ1, ���� �� ����� ����,���� �� �� �����ϴ�.
    ------------------------------------------------------------------------
    UPDATE A
       SET Result = '���� �� ����� ����,���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
       AND EXISTS (SELECT 1 
                     FROM mnpt_TPJTEERentToolCalc 
                    WHERE CompanySeq = @CompanySeq 
                      AND ContractSeq = A.ContractSeq 
                  ) 
    ------------------------------------------------------------------------
    -- üũ1, End 
    ------------------------------------------------------------------------



    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT, 
            @Cnt    INT 
    
    SELECT @Cnt = 1 
      
    SELECT @Count = COUNT(1) FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        DECLARE @BaseDate           NVARCHAR(8),   
                @MaxNo              NVARCHAR(50)  
        
        CREATE TABLE #CreateNo 
        (
            IDX_NO          INT IDENTITY, 
            Main_IDX_NO     INT, 
            ContractDate    NCHAR(8), 
            MaxNo           NVARCHAR(200)
        )
        INSERT INTO #CreateNo ( ContractDate, Main_IDX_NO, MaxNo )
        SELECT ContractDate, IDX_NO, ''
          FROM #BIZ_OUT_DataBlock1 
         WHERE Status = 0 
           AND WorkingTag = 'A' 
        
        
        WHILE ( @Cnt <= ISNULL((SELECT MAX(IDX_NO) FROM #CreateNo),0) ) 
        BEGIN 
            SELECT @BaseDate = ISNULL( MAX(ContractDate), CONVERT( NVARCHAR(8), GETDATE(), 112 ) )  
              FROM #CreateNo   
             WHERE IDX_NO = @Cnt 
          
            EXEC dbo._SCOMCreateNo 'SITE', 'mnpt_TPJTEERentToolContract', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT      
          
            -- Temp Talbe �� ������ Ű�� UPDATE  
            UPDATE #CreateNo  
               SET MaxNo = @MaxNo      
             WHERE IDX_NO = @Cnt 
        
            SELECT @Cnt = @Cnt + 1 
        END 
        
        UPDATE A
           SET ContractNo = B.MaxNo
          FROM #BIZ_OUT_DataBlock1  AS A 
          JOIN #CreateNo            AS B ON ( B.Main_IDX_NO = A.IDX_NO )  
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   




    IF @Count > 0  
    BEGIN  
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'mnpt_TPJTEERentToolContract', 'ContractSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #BIZ_OUT_DataBlock1  
           SET ContractSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    END -- end if   


    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #BIZ_OUT_DataBlock1   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #BIZ_OUT_DataBlock1  
     WHERE Status = 0  
       AND ( ContractSeq = 0 OR ContractSeq IS NULL )  
    
    RETURN  
    


go


