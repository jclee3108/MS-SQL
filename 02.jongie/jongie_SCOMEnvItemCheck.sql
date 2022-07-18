
IF OBJECT_ID('jongie_SCOMEnvItemCheck') IS NOT NULL
    DROP PROC jongie_SCOMEnvItemCheck
GO
    
-- v2013.08.07   
  
-- (���̳���) �߰����� Mapping���� ����_jongie-üũ by ��ö�� (copy ����õ)
CREATE PROC jongie_SCOMEnvItemCheck    
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
        
    CREATE TABLE #jongie_TCOMEnvItem( WorkingTag NCHAR(1) NULL )      
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#jongie_TCOMEnvItem'     
    IF @@ERROR <> 0 RETURN       
        
    -- ����������üũ: UPDATE, DELETE�� ������ �������� ������ ����ó��    
    IF NOT EXISTS ( SELECT 1     
                      FROM #jongie_TCOMEnvItem AS A     
                      JOIN jongie_TCOMEnvItem  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ItemSeqOld = B.ItemSeq )    
                     WHERE A.WorkingTag IN ( 'U', 'D' )    
                       AND Status = 0     
                  )    
    BEGIN    
        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                              @Status      OUTPUT,    
                              @Results     OUTPUT,    
                              7                  , -- �ڷᰡ��ϵǾ������ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)    
                              @LanguageSeq                 
            
        UPDATE #jongie_TCOMEnvItem    
           SET Result       = @Results,    
               MessageType  = @MessageType,    
               Status       = @Status    
         WHERE WorkingTag IN ( 'U', 'D' )    
           AND Status = 0     
    END     
      
    -- �ߺ����� üũ :     
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')    
                          @LanguageSeq       ,    
                          2109, N'ǰ������'--,  -- SELECT * FROM _TCADictionary WHERE Word like '%ǰ������%'    
                          --3543, '��2'    
        
    UPDATE #jongie_TCOMEnvItem    
       SET Result       = REPLACE( @Results, '@2', '' ), -- Ȥ�� @Results,    
           MessageType  = @MessageType,    
           Status       = @Status    
      
      FROM #jongie_TCOMEnvItem AS A     
      JOIN (SELECT S.ItemSeq    
              FROM (SELECT A1.ItemSeq    
                      FROM #jongie_TCOMEnvItem AS A1    
                     WHERE A1.WorkingTag IN ('A', 'U')    
                       AND A1.Status = 0    
                                                
                    UNION ALL    
                                               
                    SELECT A1.ItemSeq    
                      FROM jongie_TCOMEnvItem AS A1    
                     WHERE A1.CompanySeq = @CompanySeq     
                       AND NOT EXISTS (SELECT 1 FROM #jongie_TCOMEnvItem     
                                               WHERE WorkingTag IN ('U','D')     
                                                 AND Status = 0     
                                                 AND ItemSeqOld = A1.ItemSeq    
                                      )    
                   ) AS S    
             GROUP BY S.ItemSeq    
            HAVING COUNT(1) > 1    
           ) AS B ON ( A.ItemSeq = B.ItemSeq )    
     WHERE A.WorkingTag IN ('A', 'U')    
       AND A.Status = 0    
      
    SELECT * FROM #jongie_TCOMEnvItem     
      
    RETURN    