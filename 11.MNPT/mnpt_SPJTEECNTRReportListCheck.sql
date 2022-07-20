  
IF OBJECT_ID('mnpt_SPJTEECNTRReportListCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTEECNTRReportListCheck  
GO  
    
-- v2017.11.07
  
-- �����̳ʽ�����ȸ-üũ by ����õ   
CREATE PROC mnpt_SPJTEECNTRReportListCheck  
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
    
    ----------------------------------------------------------------------------------------
    -- üũ1, û�������� �Ǿ� ���� �� �� �����ϴ�.
    ----------------------------------------------------------------------------------------
    UPDATE A
       SET Result = 'û�������� �Ǿ� ���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234
      FROM #BIZ_OUT_DataBlock1      AS A 
      JOIN mnpt_TPJTEECNTRReport    AS B ON ( B.CompanySeq = @CompanySeq AND B.CNTRReportSeq = A.CNTRReportSeq ) 
      JOIN mnpt_TPJTShipDetail      AS C ON ( C.CompanySeq = @CompanySeq AND C.ShipSeq = B.ShipSeq AND C.ShipSerl = B.ShipSerl ) 
     WHERE A.WorkingTag = 'D' 
       AND A.Status = 0 
       AND EXISTS (SELECT 1 
                     FROM mnpt_TPJTLinkInvoiceItem 
                    WHERE CompanySeq = @CompanySeq 
                      AND OldShipSeq = C.ShipSeq 
                      AND OldShipSerl = C.ShipSerl
                      AND ChargeDate = LEFT(C.OutDateTime,8)
                  ) 
    ----------------------------------------------------------------------------------------
    -- üũ1, END 
    ----------------------------------------------------------------------------------------
    
    RETURN  
