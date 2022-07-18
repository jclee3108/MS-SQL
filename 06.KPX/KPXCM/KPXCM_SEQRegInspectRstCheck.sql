  
IF OBJECT_ID('KPXCM_SEQRegInspectRstCheck') IS NOT NULL   
    DROP PROC KPXCM_SEQRegInspectRstCheck  
GO  
  
-- v2015.07.03  
  
-- ����˻系�����-üũ by ����õ   
CREATE PROC KPXCM_SEQRegInspectRstCheck  
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
      
    CREATE TABLE #KPXCM_TEQRegInspectRst( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQRegInspectRst'   
    IF @@ERROR <> 0 RETURN     
    
    CREATE TABLE #KPXCM_TEQRegInspectRstSub( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TEQRegInspectRstSub'   
    IF @@ERROR <> 0 RETURN     
    
    -- �ߺ����� üũ :   
    --EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                      @Status      OUTPUT,  
    --                      @Results     OUTPUT,  
    --                      6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
    --                      @LanguageSeq       ,  
    --                      3542, '��1'--,  -- SELECT * FROM _TCADictionary WHERE Word like '%��%'  
    --                      --3543, '��2'  
      
    --UPDATE #KPXCM_TEQRegInspectRst  
    --   SET Result       = REPLACE( @Results, '@2', B.SampleName ), -- Ȥ�� @Results,  
    --       MessageType  = @MessageType,  
    --       Status       = @Status  
    --  FROM #KPXCM_TEQRegInspectRst AS A   
    --  JOIN (SELECT S.SampleName  
    --          FROM (SELECT A1.SampleName  
    --                  FROM #KPXCM_TEQRegInspectRst AS A1  
    --                 WHERE A1.WorkingTag IN ('A', 'U')  
    --                   AND A1.Status = 0  
                                              
    --                UNION ALL  
                                             
    --                SELECT A1.SampleName  
    --                  FROM KPXCM_TEQRegInspectRst AS A1  
    --                 WHERE A1.CompanySeq = @CompanySeq   
    --                   AND NOT EXISTS (SELECT 1 FROM #KPXCM_TEQRegInspectRst   
    --                                           WHERE WorkingTag IN ('U','D')   
    --                                             AND Status = 0   
    --                                             AND RegInspectSeq = A1.RegInspectSeq  
    --                                  )  
    --               ) AS S  
    --         GROUP BY S.SampleName  
    --        HAVING COUNT(1) > 1  
    --       ) AS B ON ( A.SampleName = B.SampleName )  
    -- WHERE A.WorkingTag IN ('A', 'U')  
    --   AND A.Status = 0  
      
    -- ��뿩��üũ : K-Studio -> �������� -> �����ڵ� -> �ڵ������ ��뿩��üũ ȭ�鿡�� ����� �ؾ� üũ��    
    --IF EXISTS ( SELECT 1 FROM #KPXCM_TEQRegInspectRst WHERE WorkingTag = 'D' )    
    --BEGIN    
      --    EXEC _SCOMCodeDeleteCheck @CompanySeq, @UserSeq, @LanguageSeq, 'KPXCM_TEQRegInspectRst', '#KPXCM_TEQRegInspectRst', 'RegInspectSeq'    
    --END    
    
    SELECT * FROM #KPXCM_TEQRegInspectRst  
    
    SELECT * FROM #KPXCM_TEQRegInspectRstSub 
      
    RETURN  