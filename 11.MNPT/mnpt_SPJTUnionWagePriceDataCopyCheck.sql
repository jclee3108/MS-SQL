  
IF OBJECT_ID('mnpt_SPJTUnionWagePriceDataCopyCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTUnionWagePriceDataCopyCheck  
GO  
    
-- v2017.09.28
  
-- �������Ӵܰ��Է�-�ֱ��ڷẹ��üũ by ����õ
CREATE PROC mnpt_SPJTUnionWagePriceDataCopyCheck
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    
    -- üũ1, �ֱ��ڷᰡ �������� �ʽ��ϴ�.
    DECLARE @MaxStdDate NCHAR(8) 

    SELECT @MaxStdDate = MAX(B.StdDate) 
      FROM #BIZ_OUT_DataBlock1          AS A 
      JOIN mnpt_TPJTUnionWagePrice      AS B ON ( B.CompanySeq = @CompanySeq AND B.StdDate < A.StdDate ) 
     WHERE A.Status = 0 
    
    IF @MaxStdDate IS NULL OR @MaxStdDate = '' 
    BEGIN 
        UPDATE A
           SET Result = '�ֱ��ڷᰡ �������� �ʽ��ϴ�.', 
               Status = 1234, 
               MessageType = 1234 
          FROM #BIZ_OUT_DataBlock1 AS A 
    END 
    -- üũ1, END 
    
    RETURN  
 

 GO 

