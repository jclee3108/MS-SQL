IF OBJECT_ID('mnpt_SARCostAccCheck') IS NOT NULL 
    DROP PROC mnpt_SARCostAccCheck
GO 

-- v2018.01.08 
/*********************************************************************************************************************          
    ȭ��� : ���ڰ��翬������ȯ�漳�� - üũ      
    SP Name: _SARCostAccCheck          
    �ۼ��� : 2010.04.19 : CREATEd by �۰��              
    ������ :       
********************************************************************************************************************/        
CREATE PROC mnpt_SARCostAccCheck      
    @xmlDocument    NVARCHAR(MAX),        
    @xmlFlags       INT = 0,        
    @ServiceSeq     INT = 0,        
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0        
      
AS          
    DECLARE @Count       INT,      
            @Seq         INT,      
            @MessageType INT,      
            @Status      INT,      
            @Results     NVARCHAR(250)      
      
    -- ���� ����Ÿ ��� ����      
    CREATE TABLE #TARCostAcc (WorkingTag NCHAR(1) NULL)       
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TARCostAcc'           
    IF @@ERROR <> 0 RETURN       

    UPDATE a
       SET SMKindSeq = 4503004
      FROM #TARCostAcc as a 
      
      
    -------------------------------------------      
    -- �����׸�(Key)�� �����Ұ�      
    -------------------------------------------      
     EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          19                  , -- @1��(��) @2(��)�� �� �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE message like '%@2%��%')      
                          @LanguageSeq       ,       
                          2271,'����',282,''   -- SELECT * FROM _TCADictionary WHERE Word like '����%'      
      
     UPDATE #TARCostAcc      
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #TARCostAcc       
     WHERE WorkingTag = 'U'      
           AND Status = 0      
           AND SMKindSeq <> OldSMKindSeq      
      
    -- OldKey�� ����      
    UPDATE #TARCostAcc      
       SET OldSMKindSeq = SMKindSeq      
      FROM #TARCostAcc       
     WHERE WorkingTag = 'A'      
           AND Status = 0      
           AND OldSMKindSeq = 0      
      
    -------------------------------------------      
    -- �����׸񼼺� �ʼ�üũ      
    -------------------------------------------      
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1039                  , -- �ʼ��׸��� @1��(��) �Էµ��� �ʾҽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1039)      
                          @LanguageSeq       ,       
                          12467,''   -- SELECT * FROM _TCADictionary WHERE Word like '�⺻�����׸�%'      
    UPDATE #TARCostAcc      
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #TARCostAcc AS A JOIN _TDAAccount AS B      
                              ON B.CompanySeq   = @CompanySeq      
                             AND A.AccSeq       = B.AccSeq      
                            JOIN _TDAAccountSub AS C      
                              ON C.CompanySeq   = @CompanySeq      
                             AND A.AccSeq       = C.AccSeq      
                             AND A.RemSeq       = C.RemSeq      
                             AND C.IsDrEss      = '1'      
     WHERE A.WorkingTag IN ('A','U')      
       AND A.Status      = 0      
       AND ISNULL(A.RemValSeq, 0) = 0      
      
    
    -------------------------------------------      
    -- �ߺ�����üũ      
    -------------------------------------------      
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1107                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE message like '%�ߺ�%'MessageSeq = 6)      
                          @LanguageSeq       ,       
                      652,'',652,''   -- SELECT * FROM _TCADictionary WHERE Word like '��뱸��%'      
    UPDATE #TARCostAcc      
       SET Result        = '����׸��� �ߺ��Ǿ����ϴ�.',      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #TARCostAcc AS A JOIN ( SELECT S.SMKindSeq, S.CostName      
                                     FROM (      
                                           SELECT A1.SMKindSeq, A1.CostName      
                                             FROM #TARCostAcc AS A1      
                                            WHERE A1.WorkingTag IN ('A','U')      
                                              AND A1.Status = 0      
                                           UNION ALL      
                                           SELECT A1.SMKindSeq, A1.CostName      
                                             FROM _TARCostAcc AS A1      
                                            WHERE  A1.CompanySeq =  @CompanySeq      
                                              AND  NOT Exists (SELECT *      
                                                                  FROM #TARCostAcc       
                                                                 WHERE WorkingTag IN ('U','D')      
                                                                   AND Status = 0      
                                                                   AND CostSeq = A1.CostSeq      
                                                                   AND SMKindSeq = A1.SMKindSeq)      
                                          ) AS S      
                                    GROUP BY S.SMKindSeq, S.CostName      
                                    HAVING COUNT(1) > 1      
                                  ) AS B ON (A.SMKindSeq = B.SMKindSeq      
                                             AND A.CostName = B.CostName)      
      
      
      
    -------------------------------------------  
    -- ����׸��� ��뱸�а� ���������� ��뱸�� üũ
    -------------------------------------------  
    DECLARE @WordCostType   NVARCHAR(100)    
    
    EXEC @WordCostType = _FCOMGetWord @LanguageSeq, 652, N'��뱸��'
    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          1292               , -- @1��(��) @2��(��) ���ƾ� �մϴ�.. SELECT * FROM _TCAMessageLanguage WHERE languageSeq = 1 AND  Message LIKE '%%���ƾ�%' 
                          @LanguageSeq       , 
                          8     , N'��������',   -- SELECT * FROM _TCADictionary WHERE languageSeq = 1 AND  Word like '%��������%'  
                          1054  , N'����׸�' 
                          
    UPDATE #TARCostAcc  
       SET Result        = @WordCostType + N' - ' + @Results,  
           MessageType   = @MessageType,  
           Status        = @Status  
      FROM #TARCostAcc AS A                
                JOIN _TARCostAcc AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq AND A.CostSeq = C.CostSeq       
     WHERE A.WorkingTag IN ('A', 'U')
       AND A.Status = 0
       AND A.UMCostType > 0
       AND EXISTS     ( SELECT 1 FROM _TDAAccountCostType WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = C.AccSeq)
       AND NOT EXISTS ( SELECT 1 FROM _TDAAccountCostType WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = C.AccSeq AND UMCostType = A.UMCostType)
    
    
    -------------------------------------------      
    -- ��뿩��üũ      
    -------------------------------------------      
   
    EXEC dbo._SCOMCodeDeleteCheck  @CompanySeq,@UserSeq,@LanguageSeq,'_TARCostAcc','#TARCostAcc','CostSeq'      
      
    --SELECT * FROM #TARCostAcc    
    -------------------------------------------      
    -- ��������üũ      
    -------------------------------------------      
      
    -------------------------------------------      
    -- ���࿩��üũ      
    -------------------------------------------      
      
    -------------------------------------------      
    -- Ȯ������üũ      
    -------------------------------------------      
    -- ���� SP Call ����      
      
      
      
    -------------------------------------------      
    -- INSERT ��ȣ�ο�(�� ������ ó��)      
    -------------------------------------------      
    SELECT @Count = COUNT(1) FROM #TARCostAcc WHERE WorkingTag = 'A' --@Count������(AND Status = 0 ����)      
    IF @Count > 0      
    BEGIN        
        -- Ű�������ڵ�κ� ����        
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TARCostAcc', 'CostSeq', @Count      
        -- Temp Talbe �� ������ Ű�� UPDATE      
        UPDATE #TARCostAcc      
           SET CostSeq = @Seq + DataSeq      
         WHERE WorkingTag = 'A'      
           AND Status = 0      
    END       
        
       
    SELECT * FROM #TARCostAcc         
      
    RETURN          
go
begin tran 
exec mnpt_SARCostAccCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SMKindName />
    <CostSClassName>�Һз�3</CostSClassName>
    <CostSeq>8</CostSeq>
    <CostName>ȸ�ĺ�1</CostName>
    <AccName>�����Ļ���</AccName>
    <RemName />
    <RemValueName />
    <OppAccName />
    <EvidName />
    <AccSeq>212</AccSeq>
    <CashDate>0</CashDate>
    <Remark />
    <RemSeq>0</RemSeq>
    <RemValSeq>0</RemValSeq>
    <SMKindSeq>0</SMKindSeq>
    <OldSMKindSeq>0</OldSMKindSeq>
    <OppAccSeq>0</OppAccSeq>
    <EvidSeq>0</EvidSeq>
    <UMCostTypeName />
    <UMCostType>0</UMCostType>
    <BgtName />
    <Sort>0</Sort>
    <IsNotUse>0</IsNotUse>
    <CostSClassSeq>1016729003</CostSClassSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=13820111,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=167,@PgmSeq=13820107
rollback 