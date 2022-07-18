  
IF OBJECT_ID('KPX_SPUEORegClosingCheck') IS NOT NULL   
    DROP PROC KPX_SPUEORegClosingCheck  
GO  
  
-- v2016.01.13
  
-- EO�����԰����ó��- ����üũ by ����õ 
CREATE PROC KPX_SPUEORegClosingCheck  
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
      
    CREATE TABLE #Closing( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#Closing'   
    IF @@ERROR <> 0 RETURN     
    
    ------------------------------------------------------
    -- ����(����)���� üũ 
    ------------------------------------------------------
    UPDATE A 
       SET Result = '����(����)������ �Ǿ����ϴ�. ó�� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #Closing   AS A 
      JOIN _TCOMClosingYM   AS B ON ( B.CompanySeq = @CompanySeq AND B.ClosingSeq = 1292 AND B.ClosingYM = LEFT(A.InOutDate,6) AND B.IsClose = '1' )
     WHERE A.Status = 0 
    ------------------------------------------------------
    -- ����(����)���� üũ, END  
    ------------------------------------------------------
    
    ------------------------------------------------------
    -- ����(����)���� üũ 
    ------------------------------------------------------
    UPDATE A 
       SET Result = '����(����)������ �Ǿ����ϴ�. ó�� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #Closing   AS A 
      JOIN _TCOMClosingYM   AS B ON ( B.CompanySeq = @CompanySeq AND B.ClosingSeq = 69 AND B.ClosingYM = LEFT(A.InOutDate,6) AND B.IsClose = '1' AND B.DtlUnitSeq = 1 )
     WHERE A.Status = 0 
    ------------------------------------------------------
    -- ����(����)���� üũ, END  
    ------------------------------------------------------
    
    SELECT * FROM #Closing   
      
    RETURN  