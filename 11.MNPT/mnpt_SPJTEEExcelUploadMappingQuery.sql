  
IF OBJECT_ID('mnpt_SPJTEEExcelUploadMappingQuery') IS NOT NULL   
    DROP PROC mnpt_SPJTEEExcelUploadMappingQuery  
GO  
    

-- v2017.11.20
  
-- ���ֿ��ȿ������ε����_mnpt-üũ by ����õ   
CREATE PROC mnpt_SPJTEEExcelUploadMappingQuery
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @PJTSeq     INT, 
            @ItemSeq    INT  
      
    SELECT @PJTSeq  = ISNULL( PJTSeq    , 0 ),   
           @ItemSeq = ISNULL( ItemSeq   , 0 )   
      FROM #BIZ_IN_DataBlock1    
  
    SELECT A.MappingSeq, 
           A.PJTSeq, 
           B.PJTName, 
           A.TextPJTType, -- �׸�
           A.ItemSeq, 
           C.ItemName, 
           A.TextItemKind, -- ���� 
           A.Remark 
      FROM mnpt_TPJTEEExcelUploadMapping    AS A   
      LEFT OUTER JOIN _TPJTProject          AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN _TDAItem              AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq   
       AND (@PJTSeq = 0 OR A.PJTSeq = @PJTSeq)
       AND (@ItemSeq = 0 OR A.ItemSeq = @ItemSeq)
     ORDER BY PJTName, TextPJTType, ItemName
    
    RETURN     