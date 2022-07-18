  
IF OBJECT_ID('KPX_SHREduPersPlanSheetCheck') IS NOT NULL   
    DROP PROC KPX_SHREduPersPlanSheetCheck  
GO  
  
-- v2015.04.14  
  
-- ������ȹ���(1sheet)-üũ by ����õ   
CREATE PROC KPX_SHREduPersPlanSheetCheck  
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
      
    CREATE TABLE #KPX_THREduPersPlanSheet( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THREduPersPlanSheet'   
    IF @@ERROR <> 0 RETURN     
    
    -- �ߺ����� üũ :   
    --EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                      @Status      OUTPUT,  
    --                      @Results     OUTPUT,  
    --                      6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
    --                      @LanguageSeq       ,  
    --                      3542, '��1'--,  -- SELECT * FROM _TCADictionary WHERE Word like '%��%'  
    --                      --3543, '��2'  
      
    --UPDATE #KPX_THREduPersPlanSheet  
    --   SET Result       = REPLACE( @Results, '@2', B.SampleName ), -- Ȥ�� @Results,  
    --       MessageType  = @MessageType,  
    --       Status       = @Status  
    --  FROM #KPX_THREduPersPlanSheet AS A   
    --  JOIN (SELECT S.SampleName  
    --          FROM (SELECT A1.SampleName  
    --                  FROM #KPX_THREduPersPlanSheet AS A1  
    --                 WHERE A1.WorkingTag IN ('A', 'U')  
    --                   AND A1.Status = 0  
                                              
    --                UNION ALL  
                                             
    --                SELECT A1.SampleName  
    --                  FROM KPX_THREduPersPlanSheet AS A1  
    --                 WHERE A1.CompanySeq = @CompanySeq   
    --                   AND NOT EXISTS (SELECT 1 FROM #KPX_THREduPersPlanSheet   
    --                                           WHERE WorkingTag IN ('U','D')   
    --                                             AND Status = 0   
    --                                             AND PlanSeq = A1.PlanSeq  
    --                                  )  
    --               ) AS S  
    --         GROUP BY S.SampleName  
    --        HAVING COUNT(1) > 1  
    --       ) AS B ON ( A.SampleName = B.SampleName )  
    -- WHERE A.WorkingTag IN ('A', 'U')  
    --   AND A.Status = 0  
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_THREduPersPlanSheet WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_THREduPersPlanSheet', 'PlanSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPX_THREduPersPlanSheet  
           SET PlanSeq = @Seq + DataSeq  
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_THREduPersPlanSheet   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_THREduPersPlanSheet  
     WHERE Status = 0  
       AND ( PlanSeq = 0 OR PlanSeq IS NULL )  
    
    SELECT * FROM #KPX_THREduPersPlanSheet   
    
    RETURN  