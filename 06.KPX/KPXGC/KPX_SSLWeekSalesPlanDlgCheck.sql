
IF OBJECT_ID('KPX_SSLWeekSalesPlanDlgCheck') IS NOT NULL 
    DROP PROC KPX_SSLWeekSalesPlanDlgCheck
GO 

-- v2014.11.17 
    
-- �ְ��ǸŰ�ȹ�Է�Dlg-üũ by ����õ     
CREATE PROC KPX_SSLWeekSalesPlanDlgCheck    
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
      
    CREATE TABLE #KPX_TSLWeekSalesPlanRev( WorkingTag NCHAR(1) NULL )      
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TSLWeekSalesPlanRev'     
    IF @@ERROR <> 0 RETURN       
      
    -- üũ 1, �� ������ �����Ͱ� �������� �ʽ��ϴ�.  
    IF NOT EXISTS ( SELECT 1  
                     FROM #KPX_TSLWeekSalesPlanRev AS A   
                     JOIN KPX_TSLWeekSalesPlan     AS B ON ( B.CompanySeq = @CompanySeq   
                                                          AND B.BizUnit = A.BizUnit   
                                                          AND B.WeekSeq = A.WeekSeq
                                                          AND B.PlanRev = RIGHT('0' + CONVERT(NVARCHAR(2),CONVERT(INT,A.PlanRev)-1),2) )   
                  )  
       AND (SELECT PlanRev FROM #KPX_TSLWeekSalesPlanRev) <> '01'  
    BEGIN  
        UPDATE A  
           SET Result = '�� ������ �����Ͱ� �������� �ʽ��ϴ�.',   
               Status = 1234,   
               MessageType = 1234  
          FROM #KPX_TSLWeekSalesPlanRev AS A   
    END                     
    -- üũ 1, END   
  
      
    SELECT * FROM #KPX_TSLWeekSalesPlanRev     
        
    RETURN    