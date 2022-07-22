  
IF OBJECT_ID('hencom_SACSubContrAmtListCheck') IS NOT NULL   
    DROP PROC hencom_SACSubContrAmtListCheck  
GO  
  
-- v2017.07.07
  
-- ���޺����޳���-üũ by ����õ
CREATE PROC hencom_SACSubContrAmtListCheck  
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
      
    CREATE TABLE #hencom_TACSubContrAmtList( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TACSubContrAmtList'   
    IF @@ERROR <> 0 RETURN     
    
    -- üũ1, �ϸ����� �Ǿ� �ű�����/����/������(��) �� �� �����ϴ�.
    UPDATE A
       SET Result = '�ϸ����� �Ǿ� �ű�����/����/��Ʈ������(��) �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TACSubContrAmtList   AS A 
      JOIN hencom_TACFundPlanClose      AS B ON ( B.CompanySeq = @CompanySeq AND B.StdDate = A.StdDate ) 
     WHERE B.Check3 = '1' 
       AND A.Status = 0 
    -- üũ1, END 

    SELECT * FROM #hencom_TACSubContrAmtList   
      
    RETURN  
