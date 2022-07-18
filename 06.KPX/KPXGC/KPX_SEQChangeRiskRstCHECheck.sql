  
IF OBJECT_ID('KPX_SEQChangeRiskRstCHECheck') IS NOT NULL   
    DROP PROC KPX_SEQChangeRiskRstCHECheck  
GO  
  
-- v2014.12.12  
  
-- �������輺�򰡵��-üũ by ����õ   
CREATE PROC KPX_SEQChangeRiskRstCHECheck  
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
    
    CREATE TABLE #KPX_TEQChangeRiskRstCHE( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEQChangeRiskRstCHE'   
    IF @@ERROR <> 0 RETURN     
    
    -- ����������üũ: UPDATE, DELETE�� ������ �������� ������ ����ó��  
    --IF NOT EXISTS ( SELECT 1   
    --                  FROM #KPX_TEQChangeRiskRstCHE AS A   
    --                  JOIN KPX_TEQChangeRiskRstCHE AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.RiskRstSeq = B.RiskRstSeq )  
    --                 WHERE A.WorkingTag IN ( 'U', 'D' )  
    --                   AND Status = 0   
    --              )  
    --BEGIN  
    --    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                          @Status      OUTPUT,  
    --                          @Results     OUTPUT,  
    --                          7                  , -- �ڷᰡ��ϵǾ������ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
    --                          @LanguageSeq               
          
    --    UPDATE #KPX_TEQChangeRiskRstCHE  
    --       SET Result       = @Results,  
    --           MessageType  = @MessageType,  
    --           Status       = @Status  
    --     WHERE WorkingTag IN ( 'U', 'D' )  
    --       AND Status = 0   
    --END   
      
    -- �ߺ����� üũ :   
    --EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                      @Status      OUTPUT,  
    --                      @Results     OUTPUT,  
    --                      6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
    --                      @LanguageSeq       ,  
    --                      3542, '��1'--,  -- SELECT * FROM _TCADictionary WHERE Word like '%��%'  
    --                      --3543, '��2'  
      
    --UPDATE #KPX_TEQChangeRiskRstCHE  
    --   SET Result       = REPLACE( @Results, '@2', B.SampleName ), -- Ȥ�� @Results,  
    --       MessageType  = @MessageType,  
    --       Status       = @Status  
    --  FROM #KPX_TEQChangeRiskRstCHE AS A   
    --  JOIN (SELECT S.SampleName  
    --          FROM (SELECT A1.SampleName  
    --                  FROM #KPX_TEQChangeRiskRstCHE AS A1  
    --                 WHERE A1.WorkingTag IN ('A', 'U')  
    --                   AND A1.Status = 0  
                                              
    --                UNION ALL  
                                             
    --                SELECT A1.SampleName  
    --                  FROM KPX_TEQChangeRiskRstCHE AS A1  
    --                 WHERE A1.CompanySeq = @CompanySeq   
    --                   AND NOT EXISTS (SELECT 1 FROM #KPX_TEQChangeRiskRstCHE   
    --                                           WHERE WorkingTag IN ('U','D')   
    --                                             AND Status = 0   
    --                                             AND RiskRstSeq = A1.RiskRstSeq  
    --                                  )  
    --               ) AS S  
    --         GROUP BY S.SampleName  
    --        HAVING COUNT(1) > 1  
    --       ) AS B ON ( A.SampleName = B.SampleName )  
    -- WHERE A.WorkingTag IN ('A', 'U')  
    --   AND A.Status = 0  
      
    -- ��뿩��üũ : K-Studio -> �������� -> �����ڵ� -> �ڵ������ ��뿩��üũ ȭ�鿡�� ����� �ؾ� üũ��    
    --IF EXISTS ( SELECT 1 FROM #KPX_TEQChangeRiskRstCHE WHERE WorkingTag = 'D' )    
    --BEGIN    
      --    EXEC _SCOMCodeDeleteCheck @CompanySeq, @UserSeq, @LanguageSeq, 'KPX_TEQChangeRiskRstCHE', '#KPX_TEQChangeRiskRstCHE', 'RiskRstSeq'    
    --END    
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TEQChangeRiskRstCHE WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TEQChangeRiskRstCHE', 'RiskRstSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPX_TEQChangeRiskRstCHE  
           SET RiskRstSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
      
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_TEQChangeRiskRstCHE   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TEQChangeRiskRstCHE  
     WHERE Status = 0  
       AND ( RiskRstSeq = 0 OR RiskRstSeq IS NULL )  
      
    SELECT * FROM #KPX_TEQChangeRiskRstCHE   
      
    RETURN  