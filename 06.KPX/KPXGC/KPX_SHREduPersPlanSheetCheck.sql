  
IF OBJECT_ID('KPX_SHREduPersPlanSheetCheck') IS NOT NULL   
    DROP PROC KPX_SHREduPersPlanSheetCheck  
GO  
  
-- v2015.04.14  
  
-- 교육계획등록(1sheet)-체크 by 이재천   
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
    
    -- 중복여부 체크 :   
    --EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                      @Status      OUTPUT,  
    --                      @Results     OUTPUT,  
    --                      6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
    --                      @LanguageSeq       ,  
    --                      3542, '값1'--,  -- SELECT * FROM _TCADictionary WHERE Word like '%값%'  
    --                      --3543, '값2'  
      
    --UPDATE #KPX_THREduPersPlanSheet  
    --   SET Result       = REPLACE( @Results, '@2', B.SampleName ), -- 혹은 @Results,  
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
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_THREduPersPlanSheet WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_THREduPersPlanSheet', 'PlanSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_THREduPersPlanSheet  
           SET PlanSeq = @Seq + DataSeq  
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
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