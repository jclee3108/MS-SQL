  
IF OBJECT_ID('hencom_SPNPLMatItemConvfactorCheck') IS NOT NULL   
    DROP PROC hencom_SPNPLMatItemConvfactorCheck  
GO  
  
-- v2017.06.01
  
-- �����ȹ������ߵ��-üũ by ����õ   
CREATE PROC hencom_SPNPLMatItemConvfactorCheck  
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
    
    CREATE TABLE #hencom_TPNPLMatItemConvfactor( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TPNPLMatItemConvfactor'   
    IF @@ERROR <> 0 RETURN 
    
    --�ߺ����� üũ :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
                          @LanguageSeq       ,  
                          0, ''--,  -- SELECT * FROM _TCADictionary WHERE Word like '%��%'  
                          --3543, '��2'  
      
    UPDATE #hencom_TPNPLMatItemConvfactor  
       SET Result       = @Results, 
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #hencom_TPNPLMatItemConvfactor AS A   
      JOIN (SELECT S.StdYear, DeptSeq, ItemSeq   
              FROM (SELECT A1.StdYear, A1.DeptSeq, A1.ItemSeq   
                      FROM #hencom_TPNPLMatItemConvfactor  AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.StdYear, A1.DeptSeq, A1.ItemSeq   
                      FROM hencom_TPNPLMatItemConvfactor AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #hencom_TPNPLMatItemConvfactor   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND StdYear = A1.StdYear
                                                 AND DeptSeq = A1.DeptSeq 
                                                 AND ItemSeq = A1.ItemSeq
                                      )  
                   ) AS S  
             GROUP BY S.StdYear, DeptSeq, ItemSeq
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.StdYear = B.StdYear AND A.DeptSeq = B.DeptSeq AND A.ItemSeq = B.ItemSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  


    -- ��ȣ+�ڵ� ���� : 
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #hencom_TPNPLMatItemConvfactor WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'hencom_TPNPLMatItemConvfactor', 'CFSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #hencom_TPNPLMatItemConvfactor  
           SET CFSeq = @Seq + DataSeq    
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
      
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #hencom_TPNPLMatItemConvfactor   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #hencom_TPNPLMatItemConvfactor  
     WHERE Status = 0  
       AND ( CFSeq = 0 OR CFSeq IS NULL )  
      
    SELECT * FROM #hencom_TPNPLMatItemConvfactor   
      
    RETURN  
