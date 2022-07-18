IF OBJECT_ID('KPXCM_SPDBOMBatchCheck') IS NOT NULL 
    DROP PROC KPXCM_SPDBOMBatchCheck
GO 

-- v2015.09.16

/*************************************************************************************************  
  FORM NAME           -       FrmPDBOMBatch
  DESCRIPTION         -     ���պ� üũ 
  CREAE DATE          -       2008.07.01      CREATE BY: ����
  LAST UPDATE  DATE   -       2008.09.01         UPDATE BY: ����
  LAST UPDATE  DATE   -       2014.05.22         UPDATE BY: ����� �����ߺ� ��� ���� ȯ�漳�� �Ե��� �߰�
 *************************************************************************************************/ 
 CREATE PROC KPXCM_SPDBOMBatchCheck
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
             @Results     NVARCHAR(250),
             @BatchSeq    INT,
             @EnvValue    NCHAR(1)
  
     -- ���� ����Ÿ ��� ����
     CREATE TABLE #KPXCM_TPDBOMBatch (WorkingTag NCHAR(1) NULL)  
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TPDBOMBatch' 
    
     IF @@ERROR <> 0 RETURN   
     
     --- BOM �����ߺ� ��� ȯ�漳�� ---
     EXEC dbo._SCOMEnv @CompanySeq,6206,0,@@PROCID,@EnvValue OUTPUT      
  
     IF @EnvValue = '0'  -- 2014.05.22 ����� �����ߺ� ��� ���� ���� ��� ( ��üũ ) �Ʒ� Check ���� �ߵ�
    BEGIN
    
    IF EXISTS (SELECT 1 FROM KPXCM_TPDBOMBatch AS A JOIN #KPXCM_TPDBOMBatch AS B ON A.ItemSeq = B.ItemSeq AND A.BatchSize = B.BatchSize ANd A.FactUnit = B.FactUnit   
                       WHERE A.CompanySeq = @CompanySeq AND B.WorkingTag in('A', 'U') AND B.Status = 0)  
    BEGIN
         -------------------------------------------
         -- �ߺ�����üũ
         -------------------------------------------
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
                               @LanguageSeq       , 
                               0,'���պ�'   -- SELECT * FROM _TCADictionary WHERE Word like '%���պ�%'
         UPDATE #KPXCM_TPDBOMBatch
            SET Result        = REPLACE(@Results,'@2',B.BatchSize),
                MessageType   = @MessageType,
                Status        = @Status
           FROM #KPXCM_TPDBOMBatch AS A JOIN ( SELECT S.BatchSize
                                          FROM (
                                                SELECT A1.BatchSize
                                                  FROM #KPXCM_TPDBOMBatch AS A1
                                                 WHERE A1.WorkingTag IN ('A','U')
                                                   AND A1.Status = 0
                                                UNION ALL
                                                SELECT A1.BatchSize
                                                  FROM KPXCM_TPDBOMBatch AS A1
                                                 WHERE A1.ItemSeq IN (SELECT ItemSeq 
                                                                                FROM #KPXCM_TPDBOMBatch 
                                                                               WHERE WorkingTag NOT IN ('U','D') 
                                                                                 AND Status = 0)
                                                   AND A1.CompanySeq = @CompanySeq
                                               ) AS S
                                         GROUP BY S.BatchSize
                                         HAVING COUNT(1) > 1
                                       ) AS B ON (A.BatchSize = B.BatchSize)
          WHERE A.Status     = 0
            AND A.WorkingTag IN ('A', 'U')
     END
     
     
     
     
     IF EXISTS (SELECT 1 FROM #KPXCM_TPDBOMBatch WHERE DateFr >= DateTo AND Status = 0 AND WorkingTag IN ('A', 'U'))
     BEGIN
         -------------------------------------------
         -- ���� üũ
         -------------------------------------------
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               31                 , -- @1�� @2 ���� Ŀ�� �մϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%�մ�%' AND LanguageSeq = 1)
                               @LanguageSeq       , 
                               232, '������'      , -- SELECT * FROM _TCADictionary WHERE Word like '%������%'
                               191, '������'
         UPDATE #KPXCM_TPDBOMBatch
            SET Result        = @Results,
                MessageType   = @MessageType,
                Status        = @Status
           FROM #KPXCM_TPDBOMBatch 
          WHERE DateFr     >= DateTo
            AND Status     = 0
            AND WorkingTag IN ('A', 'U')
     END
     
     -- �����ϰ� �������� �ߺ��Ǹ� �ȵȴ�.
     IF EXISTS (SELECT 1 
                  FROM #KPXCM_TPDBOMBatch      AS A
                       JOIN KPXCM_TPDBOMBatch AS B ON A.ItemSeq  = B.ItemSeq 
                                             AND A.BatchSeq <> B.BatchSeq
          WHERE (B.DateFr BETWEEN A.DateFr AND A.DateTo OR B.DateTo BETWEEN A.DateFr AND A.DateTo)
            AND A.Status     = 0
            AND A.WorkingTag IN ('A', 'U')
            AND B.CompanySeq = @CompanySeq)
     BEGIN
         -------------------------------------------
         -- �ߺ��� ���� üũ
         -------------------------------------------
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               1107               , -- �ش� @1��(��) ������ ��ϵ� @2��(��) �ߺ��˴ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%����%' AND LanguageSeq = 1)
                               @LanguageSeq       , 
                               222, '������'      , -- SELECT * FROM _TCADictionary WHERE Word like '%������%'
                               222, '������'
         UPDATE #KPXCM_TPDBOMBatch
            SET Result        = @Results,
                MessageType   = @MessageType,
                Status        = @Status
           FROM #KPXCM_TPDBOMBatch      AS A
                JOIN KPXCM_TPDBOMBatch AS B ON A.ItemSeq     = B.ItemSeq 
                                      AND A.BatchSeq    <> B.BatchSeq
                                      AND A.FactUnit    = B.FactUnit
                                      AND A.ProcTypeSeq = B.ProcTypeSeq
          WHERE (B.DateFr BETWEEN A.DateFr AND A.DateTo OR B.DateTo BETWEEN A.DateFr AND A.DateTo)
            AND A.Status     = 0
            AND A.WorkingTag IN ('A', 'U')
            AND B.CompanySeq = @CompanySeq
     END
     
     
     -- �����ȹ���� ����� �����Ͱ� �����ϸ� ���� �Ұ�
     IF EXISTS (SELECT 1 
                  FROM #KPXCM_TPDBOMBatch          AS A
                       JOIN _TPDMPSWorkOrder AS B ON A.BatchSeq <> B.BatchSeq
          WHERE A.Status     = 0
            AND A.WorkingTag = 'D'
            AND B.CompanySeq = @CompanySeq)
     BEGIN
         -------------------------------------------
         -- �ߺ��� ���� üũ
         -------------------------------------------
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               1044               , -- ���� �۾��� ����Ǿ ����,������ �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%����%' AND LanguageSeq = 1)
                               @LanguageSeq       
                               
         UPDATE #KPXCM_TPDBOMBatch
            SET Result        = REPLACE(@Results, '����,', ''),
                MessageType   = @MessageType,
                Status        = @Status
           FROM #KPXCM_TPDBOMBatch          AS A
                JOIN _TPDMPSWorkOrder AS B ON A.BatchSeq    = B.BatchSeq
          WHERE A.Status     = 0
            AND A.WorkingTag = 'D'
            AND B.CompanySeq = @CompanySeq
     END
     
     END
        
        
        
        
 -- MAX UnitSeq
     SELECT @Count = COUNT(*) FROM #KPXCM_TPDBOMBatch WHERE WorkingTag = 'A' AND Status = 0 
     IF @Count > 0
     BEGIN   
         EXEC @BatchSeq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TPDBOMBatch', 'BatchSeq', @Count
         UPDATE #KPXCM_TPDBOMBatch
            SET BatchSeq   = @BatchSeq + DataSeq
          WHERE WorkingTag = 'A'
            AND Status     = 0
     END  
      SELECT * FROM #KPXCM_TPDBOMBatch
  RETURN    
 /*******************************************************************************************************************/