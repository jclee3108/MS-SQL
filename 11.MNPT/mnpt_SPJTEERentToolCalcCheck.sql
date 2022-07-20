  
IF OBJECT_ID('mnpt_SPJTEERentToolCalcCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTEERentToolCalcCheck  
GO  
    
-- v2017.11.28
  
-- �ܺ������������-üũ by ����õ
CREATE PROC mnpt_SPJTEERentToolCalcCheck  
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
    


    UPDATE A
        SET WorkingTag = LEFT(@WorkingTag,1)
        FROM #BIZ_OUT_DataBlock1 AS A 
    
    
    --------------------------------------------------------------------------
    -- üũ0, ����� ���� ���� �ʾ� ó�� �� �� �����ϴ�.
    --------------------------------------------------------------------------
    UPDATE A
       SET Result = '����� ���� ���� �ʾ� ó�� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE Status = 0        
       AND BizUnit = 0 
    --------------------------------------------------------------------------
    -- üũ0, End 
    --------------------------------------------------------------------------
    --------------------------------------------------------------------------
    -- üũ1, �̹� ���� �Ǿ� �ֽ��ϴ�.
    --------------------------------------------------------------------------
    UPDATE A
       SET Result = '�̹� ���� �Ǿ� �ֽ��ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
       AND EXISTS (
                   SELECT 1 
                     FROM mnpt_TPJTEERentToolCalc 
                    WHERE CompanySeq = @CompanySeq 
                      AND BizUnit = A.BizUnit 
                      AND RentCustSeq = A.RentCustSeq 
                      AND UMRentType = A.UMRentType 
                      AND UMRentKind = A.UMRentKind 
                      AND RentToolSeq = A.RentToolSeq 
                      AND WorkDate = A.WorkDateSub
                      AND ContractSeq = A.ContractSeq 
                      AND ContractSerl = A.ContractSerl 
                  ) 
    --------------------------------------------------------------------------
    -- üũ1, End 
    --------------------------------------------------------------------------

    --------------------------------------------------------------------------
    -- üũ2, ���� ���� ���� ���Դϴ�.
    --------------------------------------------------------------------------
    UPDATE A
       SET Result = '���� ���� ���� ���Դϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1 AS A 
      JOIN mnpt_TPJTEERentToolCalc AS B ON ( B.CompanySeq = @CompanySeq AND B.CalcSeq = A.CalcSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'D' 
       AND NOT EXISTS (
                       SELECT 1 
                         FROM mnpt_TPJTEERentToolCalc 
                        WHERE CompanySeq = @CompanySeq 
                          AND ContractSeq = A.ContractSeq 
                          AND ContractSerl = A.ContractSerl
                          AND StdYM = B.StdYM
                    ) 
    --------------------------------------------------------------------------
    -- üũ2, End 
    --------------------------------------------------------------------------

    --------------------------------------------------------------------------
    -- üũ3, ���� �� ó�� �� �� �ֽ��ϴ�.
    --------------------------------------------------------------------------
    UPDATE A
       SET Result = '���� �� ó�� �� �� �ֽ��ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'U' 
       AND (A.CalcSeq = 0 OR A.CalcSeq IS NULL)
    --------------------------------------------------------------------------
    -- üũ3, End 
    --------------------------------------------------------------------------

    --------------------------------------------------------------------------
    -- üũ4, ��ǥ�� ����Ǿ� ó�� �� �� �����ϴ�.
    --------------------------------------------------------------------------
    UPDATE A
       SET Result = '��ǥ�� ����Ǿ� ó�� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1 AS A 
      JOIN mnpt_TPJTEERentToolCalc AS B ON ( B.CompanySeq = @CompanySeq AND B.CalcSeq = A.CalcSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U' , 'D' ) 
       AND B.SlipSeq <> 0 
    --------------------------------------------------------------------------
    -- üũ4, End 
    --------------------------------------------------------------------------
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'mnpt_TPJTEERentToolCalc', 'CalcSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #BIZ_OUT_DataBlock1  
           SET CalcSeq = @Seq + DataSeq
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
       AND ( CalcSeq = 0 OR CalcSeq IS NULL )  
    
    RETURN  
    go
