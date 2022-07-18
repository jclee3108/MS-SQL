
IF OBJECT_ID('KPX_SQCCOAPrintLifeCycle') IS NOT NULL 
    DROP PROC KPX_SQCCOAPrintLifeCycle
GO 

-- v2014.12.18    
    
-- ���輺��������(COA)-LifeCycle  by ����õ     
CREATE PROC KPX_SQCCOAPrintLifeCycle    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,     
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS     
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
      
    DECLARE @docHandle  INT,    
            -- ��ȸ����     
            @ItemSeq    INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
      
    SELECT @ItemSeq   = ISNULL( ItemSeq, 0 ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )         
      WITH (
            ItemSeq INT 
           )    
    
    SELECT LimitTerm AS LifeCycle
      FROM _TDAitemStock AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ItemSeq = @ItemSeq
    
    RETURN 
