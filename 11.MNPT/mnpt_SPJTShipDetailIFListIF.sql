  
IF OBJECT_ID('mnpt_SPJTShipDetailIFListIF') IS NOT NULL   
    DROP PROC mnpt_SPJTShipDetailIFListIF
GO  
    
-- v2017.09.06
  
-- ��������ȸ-IF by ����õ
CREATE PROC mnpt_SPJTShipDetailIFListIF  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0 
AS    
    
    DECLARE @FrIFDate   NCHAR(8), 
            @ToIFDate   NCHAR(8) 
      
    SELECT @FrIFDate    = ISNULL( FrIFDate, '' ),   
           @ToIFDate    = ISNULL( ToIFDate, '' )
      FROM #BIZ_IN_DataBlock1    

    exec mnpt_SPJTShipDetailIF @CompanySeq, @UserSeq, @PgmSeq, @FrIFDate, @ToIFDate
    
    RETURN  
