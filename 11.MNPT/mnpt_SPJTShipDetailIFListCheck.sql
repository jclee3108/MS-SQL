     
IF OBJECT_ID('mnpt_SPJTShipDetailIFListCheck') IS NOT NULL       
    DROP PROC mnpt_SPJTShipDetailIFListCheck      
GO      
      
-- v2017.09.15
      
-- ��������ȸ-üũ by ����õ  
CREATE PROC mnpt_SPJTShipDetailIFListCheck      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       

    RETURN     