  
IF OBJECT_ID('hencom_SACSendAmtListCheck') IS NOT NULL   
    DROP PROC hencom_SACSendAmtListCheck  
GO  
  
-- v2017.07.10
  
-- �����ݳ���-üũ by ����õ
CREATE PROC hencom_SACSendAmtListCheck  
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
      
    CREATE TABLE #hencom_TACSendAmtList( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TACSendAmtList'   
    IF @@ERROR <> 0 RETURN     
    
    -- üũ1, �ϸ����� �Ǿ� �ű�����/����/������(��) �� �� �����ϴ�.
    UPDATE A
       SET Result = '�ϸ����� �Ǿ� �ű�����/����/��Ʈ������(��) �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TACSendAmtList   AS A 
      JOIN hencom_TACFundPlanClose  AS B ON ( B.CompanySeq = @CompanySeq AND B.StdDate = A.StdDate ) 
     WHERE B.Check4 = '1' 
       AND A.Status = 0 
    -- üũ1, END 

    SELECT * FROM #hencom_TACSendAmtList   
      
    RETURN  
