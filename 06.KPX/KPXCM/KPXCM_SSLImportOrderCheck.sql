IF OBJECT_ID('KPXCM_SSLImportOrderCheck') IS NOT NULL 
    DROP PROC KPXCM_SSLImportOrderCheck
GO 

-- v2015.09.25 

-- MES ������ ������ ����üũ �߰� by����õ 
/*************************************************************************************************    
     ȭ��� : ����Order����üũ    
     SP Name: _SSLImportOrderCheck    
     �ۼ��� : 2009.01.05 : CREATEd by õ����        
     ������ :    
 *************************************************************************************************/    
 CREATE PROC dbo.KPXCM_SSLImportOrderCheck  
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
             @Serl        INT,  
             @MessageType INT,  
             @Status      INT,  
             @Results     NVARCHAR(250),  
             @PODate      NCHAR(8)     ,  
             @PONo        NCHAR(12)    ,  
             @POSeq       INT, 
             @TableSeq    INT
   
  
     -- ���� ����Ÿ ��� ����  
     CREATE TABLE #TPUORDPO (WorkingTag NCHAR(1) NULL)    
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUORDPO'   
    
     IF @@ERROR <> 0 RETURN     
      -------------------------------------------  
     -- �ڱ���ȭ & ȯ��üũ :: 20140426 �ڼ�ȣ
     -------------------------------------------  
     DECLARE @BaseCurr  INT
      -- �ڱ���ȭ
     SELECT @BaseCurr  = ( SELECT EnvValue FROM _TCOMEnv where CompanySeq = @CompanySeq AND EnvSeq = 13 )
     IF @@ROWCOUNT = 0 SELECT @BaseCurr = ISNULL(CurrSeq, 1) FROM _TDACurr WHERE CompanySeq = @CompanySeq AND CurrName = 'KRW'
      -- �ڱ���ȭ�� �ƴ� ��, ȯ���� 1�̸� �޽���ó��
     IF @BaseCurr <> ( SELECT CurrSeq FROM #TPUORDPO )
     BEGIN
         EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                               @Status      OUTPUT,  
                               @Results     OUTPUT,  
                               1196               , -- @1��(��) Ȯ���ϼ��� (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1196)  
                               @LanguageSeq       ,   
                               364, ''              -- SELECT * FROM _TCADictionary WHERE Word = 'ȯ��'
    
         UPDATE #TPUORDPO  
            SET Result        = @Results,  
                MessageType   = @MessageType,  
                Status        = @Status  
           FROM #TPUORDPO
          WHERE ExRate = 1
     END  
     
      --------------------------------------------------------------------------------------
      -- ����������üũ: UPDATE, DELETE �õ������������������鿡��ó��
      --------------------------------------------------------------------------------------
      IF NOT EXISTS (SELECT 1 
                       FROM #TPUORDPO AS A 
                             JOIN _TPUORDPOItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.POSeq = B.POSeq
                      WHERE A.WorkingTag IN ('U', 'D'))
      BEGIN
          EXEC dbo._SCOMMessage @MessageType OUTPUT,
                                @Status      OUTPUT,
                                @Results     OUTPUT,
                                7                  , -- �ڷᰡ��ϵǾ������ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)
                                @LanguageSeq       , 
                                '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
           UPDATE #TPUORDPO
             SET Result        = @Results,
                 MessageType   = @MessageType,
                 Status        = @Status
           WHERE WorkingTag IN ('U','D')
     END
    
     ------------------------------------------------------------------------
     -- üũ, MES ����ó�� �Ǿ����Ƿ� ���� �� �� �����ϴ�. 
     ------------------------------------------------------------------------
     UPDATE A 
        SET Result = 'MES ����ó�� �Ǿ����Ƿ� ���� �� �� �����ϴ�. ', 
            MessageType = 1234, 
            Status = 1234 
       FROM #TPUORDPO        AS A 
      WHERE EXISTS (SELECT 1 FROM IF_PUDelv_MES WHERE CompanySeq = @CompanySeq AND POSeq = A.POSeq AND ConfirmFlag = 'Y')
        AND A.WorkingTag = 'D' 
        AND A.Status = 0 
     ------------------------------------------------------------------------
     -- üũ, MES ����ó�� �Ǿ����Ƿ� ���� �� �� �����ϴ�. END
     ------------------------------------------------------------------------    
    
    
     -------------------------------------------  
     -- �ߺ�����üũ  
     -------------------------------------------  
 --     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
 --                           @Status      OUTPUT,  
 --                           @Results     OUTPUT,  
 --                           6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
 --                           @LanguageSeq       ,   
 --                           0,'��ǰ������'   -- SELECT * FROM _TCADictionary WHERE Word like '%����%'  
 --     UPDATE #TPUORDPODelvDate  
 --        SET Result        = REPLACE(@Results,'@2', A.PODelvDate),  
 --            MessageType   = @MessageType,  
 --            Status        = @Status  
 --       FROM #TPUORDPODelvDate AS A JOIN ( SELECT S.PODelvDate  
 --                                   FROM (  
 --                                          SELECT A1.PODelvDate  
 --                                            FROM #TPUORDPODelvDate AS A1  
 --                                           WHERE A1.WorkingTag IN ('A','U')  
 --                                             AND A1.Status = 0  
 --                                           UNION ALL  
 --                                          SELECT A1.PODelvDate  
 --                                            FROM _TPUORDPODelvDate AS A1  
 --                                           WHERE A1.POSeq IN (SELECT POSeq   
 --                                                                       FROM #TPUORDPODelvDate   
 --                                                                      WHERE WorkingTag NOT IN ('U','D')   
 --                                                                        AND Status = 0)  
 --                                             AND A1.POSerl IN (SELECT POSerl   
 --                                                                       FROM #TPUORDPODelvDate   
 --                                                                      WHERE WorkingTag NOT IN ('U','D')   
 --                                                                        AND Status = 0)  
 --                                         ) AS S  
 --                                    GROUP BY S.PODelvDate  
 --                                    HAVING COUNT(1) > 1  
 --                                  ) AS B ON (A.PODelvDate = B.PODelvDate)  
  
     -------------------------------------------  
     -- ���࿩��üũ  
     -------------------------------------------  
     IF EXISTS (SELECT 1 FROM #TPUORDPO WHERE WorkingTag IN ('D') )  
     BEGIN  
         -- ����üũ�� ���̺� ���̺�
         CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT IDENTITY, TABLENAME   NVARCHAR(100))      
         
         -- ����üũ�� ������ ���̺�
         CREATE TABLE #Temp_ORDPO(IDX_NO INT IDENTITY, POSeq INT, POSerl INT, IsNext NCHAR(1)) 
         
         -- ����� ���� ���̺�
         CREATE TABLE #TCOMProgressTracking(IDX_NO   INT,            IDOrder INT,            Seq INT,           Serl INT,            SubSerl INT,
                                            Qty      DECIMAL(19, 5), StdQty  DECIMAL(19,5) , Amt DECIMAL(19, 5),VAT DECIMAL(19,5))
       
         SELECT @TableSeq = ProgTableSeq
           FROM _TCOMProgTable WITH(NOLOCK)--���������̺�
          WHERE ProgTableName = '_TPUORDPOItem'
          INSERT INTO #TMP_PROGRESSTABLE(TABLENAME)
         SELECT B.ProgTableName
           FROM (SELECT ToTableSeq FROM _TCOMProgRelativeTables WITH(NOLOCK) WHERE FromTableSeq = @TableSeq AND CompanySeq = @CompanySeq) AS A --�������̺����
                 JOIN _TCOMProgTable AS B WITH(NOLOCK) ON A.ToTableSeq = B.ProgTableSeq
  
         
         INSERT INTO #Temp_ORDPO(POSeq, POSerl, IsNext) -- IsNext=1(����), 0(������)
         SELECT  A.POSeq, B.POSerl, '0'
           FROM #TPUORDPO     AS A WITH(NOLOCK)       
                 JOIN _TPUORDPOItem AS B WITH(NOLOCK) ON B.CompanySeq   = @CompanySeq  
                                                     AND A.POSeq        = B.POSeq
          WHERE A.WorkingTag IN ('D')  
            AND A.Status = 0  
   
         EXEC _SCOMProgressTracking @CompanySeq, '_TPUORDPOItem', '#Temp_ORDPO', 'POSeq', 'POSerl', ''    
   
   
         UPDATE #Temp_ORDPO   
           SET IsNext = '1'  
          FROM  #Temp_ORDPO AS A  
                 JOIN #TCOMProgressTracking AS B ON A.IDX_No = B.IDX_No  
   
         --ERR Message
         EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                               @Status      OUTPUT,  
                               @Results     OUTPUT,  
        1044               , -- ���� �۾��� ����Ǿ ����,������ �� �����ϴ�..(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1045)  
                               @LanguageSeq       ,   
                               0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%����%'  
         UPDATE #TPUORDPO  
            SET Result        = @Results    ,  
                MessageType   = @MessageType,  
                Status        = @Status  
           FROM #TPUORDPO   AS A  
                JOIN #Temp_ORDPO AS B ON A.POSeq = B.POSeq  
          WHERE B.IsNext = '1' 
     END  
   
     -- MAX POSeq Seq  
     SELECT @Count = COUNT(*) FROM #TPUORDPO WHERE WorkingTag = 'A' AND Status = 0   
     IF @Count > 0  
     BEGIN     
         SELECT @PODate = PODate FROM #TPUORDPO  
         EXEC dbo._SCOMCreateNo 'PU', '_TPUORDPO', @CompanySeq, '', @PODate, @PONo OUTPUT  
         EXEC @POSeq = dbo._SCOMCreateSeq @CompanySeq, '_TPUORDPO', 'POSeq', @Count  
         UPDATE #TPUORDPO  
            SET POSeq = @POSeq + DataSeq ,   
          PONo  = @PONo  
          WHERE WorkingTag = 'A'  
            AND Status = 0  
     END    
      -------------------------------------------  
     -- �����ڵ�0���Ͻÿ����߻�
     -------------------------------------------      
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 1055)    
                           @LanguageSeq       
      UPDATE #TPUORDPO                               
        SET Result        = @Results     ,    
            MessageType   = @MessageType ,    
            Status        = @Status    
       FROM #TPUORDPO
      WHERE Status = 0
        AND (POSeq = 0 OR POSeq IS NULL)
    
     SELECT * FROM #TPUORDPO  
   
 RETURN      
 /*******************************************************************************************************************/