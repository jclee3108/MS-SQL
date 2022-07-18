  
IF OBJECT_ID('KPX_SEIS_DEBT_STATUSCheck') IS NOT NULL   
    DROP PROC KPX_SEIS_DEBT_STATUSCheck  
GO  
  
-- v2014.11.24  
  
-- (�濵����)����ä��-üũ by ����õ   
CREATE PROC KPX_SEIS_DEBT_STATUSCheck  
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
      
    CREATE TABLE #KPX_TEIS_DEBT_STATUS( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEIS_DEBT_STATUS'   
    IF @@ERROR <> 0 RETURN     
    
    ---- ����������üũ: UPDATE, DELETE�� ������ �������� ������ ����ó��  
    ----IF NOT EXISTS ( SELECT 1   
    ----                  FROM #KPX_TEIS_DEBT_STATUS AS A   
    ----                  JOIN KPX_TEIS_DEBT_STATUS AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.PlanYM = B.PlanYM )  
    ----                 WHERE A.WorkingTag IN ( 'U', 'D' )  
    ----                   AND Status = 0   
    ----              )  
    ----BEGIN  
    ----    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    ----                          @Status      OUTPUT,  
    ----                          @Results     OUTPUT,  
    ----                          7                  , -- �ڷᰡ��ϵǾ������ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
    ----                          @LanguageSeq               
          
    ----    UPDATE #KPX_TEIS_DEBT_STATUS  
    ----       SET Result       = @Results,  
    ----           MessageType  = @MessageType,  
    ----           Status       = @Status  
    ----     WHERE WorkingTag IN ( 'U', 'D' )  
    ----       AND Status = 0   
    ----END   
      
    ---- �ߺ����� üũ :   
    ----EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    ----                      @Status      OUTPUT,  
    ----                      @Results     OUTPUT,  
    ----                      6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
    ----                      @LanguageSeq       ,  
    ----                      3542, '��1'--,  -- SELECT * FROM _TCADictionary WHERE Word like '%��%'  
    ----                      --3543, '��2'  
      
    ----UPDATE #KPX_TEIS_DEBT_STATUS  
    ----   SET Result       = REPLACE( @Results, '@2', B.SampleName ), -- Ȥ�� @Results,  
    ----       MessageType  = @MessageType,  
    ----       Status       = @Status  
    ----  FROM #KPX_TEIS_DEBT_STATUS AS A   
    ----  JOIN (SELECT S.SampleName  
    ----          FROM (SELECT A1.SampleName  
    ----                  FROM #KPX_TEIS_DEBT_STATUS AS A1  
    ----                 WHERE A1.WorkingTag IN ('A', 'U')  
    ----                   AND A1.Status = 0  
                                              
    ----                UNION ALL  
                                             
    ----                SELECT A1.SampleName  
    ----                  FROM KPX_TEIS_DEBT_STATUS AS A1  
    ----                 WHERE A1.CompanySeq = @CompanySeq   
    ----                   AND NOT EXISTS (SELECT 1 FROM #KPX_TEIS_DEBT_STATUS   
    ----                                           WHERE WorkingTag IN ('U','D')   
    ----                                             AND Status = 0   
    ----                                             AND PlanYM = A1.PlanYM  
    ----                                  )  
    ----               ) AS S  
    ----         GROUP BY S.SampleName  
    ----        HAVING COUNT(1) > 1  
    ----       ) AS B ON ( A.SampleName = B.SampleName )  
    ---- WHERE A.WorkingTag IN ('A', 'U')  
    ----   AND A.Status = 0  
    
    SELECT * FROM #KPX_TEIS_DEBT_STATUS   
      
    RETURN  