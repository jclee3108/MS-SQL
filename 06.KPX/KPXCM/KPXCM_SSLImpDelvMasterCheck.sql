IF OBJECT_ID('KPXCM_SSLImpDelvMasterCheck') IS NOT NULL 
    DROP PROC KPXCM_SSLImpDelvMasterCheck
GO 

-- v2015.10.01 

-- MES���� üũ �߰� by����õ 
/*********************************************************************************************************************    
     ȭ��� : ���Ը��� ������üũ
     SP Name: _SSLImpDelvMasterCheck    
     �ۼ��� : 2009�� 03�� 19��
     ������ :     
 ********************************************************************************************************************/    
 CREATE PROCEDURE KPXCM_SSLImpDelvMasterCheck      
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
             @DataSeq     INT,    
             @DelvSeq       INT,     
             @DelvNo        NVARCHAR(12),
             @BaseDate    NVARCHAR(8),
             @MaxNo       NVARCHAR(12),
             @BizUnit     INT,     
             @MessageType INT,    
             @Status      INT,    
             @Results     NVARCHAR(250)    ,
             @MinorSeq    INT, 
             @TableSeq    INT
   
    
    
    -- ���� ����Ÿ ��� ����      
    CREATE TABLE #TUIImpDelv (WorkingTag NCHAR(1) NULL)      
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TUIImpDelv'
    
    -------------------------------------------
    -- �ʼ�������üũ    
    -------------------------------------------
          EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                                @Status      OUTPUT,    
                                @Results     OUTPUT,    
                                1                  , -- �ʼ��Է� ����Ÿ�� �Է��ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
                                @LanguageSeq       ,     
                                '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%�㺸%'            
      
          -- ����ι� üũ
          UPDATE #TUIImpDelv    
             SET Result        = REPLACE(@Results,'@1','����ι�'),    
                 MessageType   = @MessageType,    
                 Status        = @Status    
           WHERE BizUnit   = ''
           -- B/L Date
          UPDATE #TUIImpDelv    
             SET Result        = REPLACE(@Results,'@1','�԰�����'),    
                 MessageType   = @MessageType,    
                 Status        = @Status    
           WHERE BizUnit   = ''
              OR DelvDate       = ''
       --------------------------------------------------------------------------------------
      -- ����������üũ: UPDATE, DELETE �õ������������������鿡��ó��
      --------------------------------------------------------------------------------------
      IF NOT EXISTS (SELECT 1 
                       FROM #TUIImpDelv AS A 
                             JOIN _TUIImpDelv AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.DelvSeq = B.DelvSeq
                      WHERE A.WorkingTag IN ('U', 'D'))
      BEGIN
          EXEC dbo._SCOMMessage @MessageType OUTPUT,
                                @Status      OUTPUT,
                                @Results     OUTPUT,
                                7                  , -- �ڷᰡ��ϵǾ������ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)
                                @LanguageSeq       , 
                                '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
           UPDATE #TUIImpDelv
             SET Result        = @Results,
                 MessageType   = @MessageType,
                 Status        = @Status
           WHERE WorkingTag IN ('U','D')
     END 
    
    
    ------------------------------------------------------------------------
    -- üũ, MES �������� �԰� �� ������ ���� �� �� �����ϴ�. 
    ------------------------------------------------------------------------
    CREATE TABLE #BaseData 
    (
        IDX_NO      INT IDENTITY, 
        DelvSeq     INT, 
        DelvSerl    INT, 
        POSeq       INT, 
        POSerl      INT 
    )
    INSERT INTO #BaseData ( DelvSeq, DelvSerl, POSeq, POSerl ) 
    SELECT B.DelvSeq, B.DelvSerl, 0, 0 
      FROM #TUIImpDelv      AS A 
      JOIN _TUIImpDelvItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
     WHERE A.WorkingTag = 'D' 
       AND A.Status = 0 
    
    -- ��õ 
    CREATE TABLE #TMP_SourceTable 
    (
        IDOrder   INT, 
        TableName NVARCHAR(100)
    )  
    
    INSERT INTO #TMP_SourceTable (IDOrder, TableName) 
    SELECT 1, '_TPUORDPOItem'   -- ã�� �������� ���̺�
    
    CREATE TABLE #TCOMSourceTracking 
    (
        IDX_NO  INT, 
        IDOrder  INT, 
        Seq      INT, 
        Serl     INT, 
        SubSerl  INT, 
        Qty      DECIMAL(19,5), 
        StdQty   DECIMAL(19,5), 
        Amt      DECIMAL(19,5), 
        VAT      DECIMAL(19,5)
    ) 
          
    EXEC _SCOMSourceTracking @CompanySeq = @CompanySeq, 
                             @TableName = '_TUIImpDelvItem',  -- ���� ���̺�
                             @TempTableName = '#BaseData',  -- �����������̺�
                             @TempSeqColumnName = 'DelvSeq',  -- �������̺� Seq
                             @TempSerlColumnName = 'DelvSerl',  -- �������̺� Serl
                             @TempSubSerlColumnName = '' 
    
    UPDATE A 
       SET POSeq = B.Seq, 
           POSerl = B.Serl 
      FROM #BaseData            AS A 
      JOIN #TCOMSourceTracking  AS B ON ( B.IDX_NO = A.IDX_NO ) 
    
    UPDATE A 
       SET Result = 'MES �������� �԰� �� ������ ���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #TUIImpDelv  AS A 
      JOIN #BaseData    AS B ON ( B.DelvSeq = A.DelvSeq ) 
     WHERE EXISTS (SELECT 1 FROM IF_PUInQCResult_MES WHERE CompanySeq = @CompanySeq AND ImpType = 1 AND POSeq = B.POSeq AND POSerl = B.POSerl) 
       AND A.Status = 0 
       AND A.WorkingTag = 'D' 
    ------------------------------------------------------------------------
    -- üũ, END 
    ------------------------------------------------------------------------
    
    
    -------------------------------------------  
    -- ��뵥����üũ  
    -------------------------------------------  
          SELECT @MinorSeq = ISNULL(MinorSeq, 0)
           FROM _TDAUMinorValue WITH (NOLOCK)
          WHERE CompanySeq = @CompanySeq
            AND MajorSeq   = 8212
            AND Serl       = 1003
            AND ValueText  = '1'
           EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                                @Results     OUTPUT,  
                                102                , -- @1 �����Ͱ� �����մϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 102)  
                                @LanguageSeq       ,   
                                0,'���ó��'   -- SELECT * FROM _TCADictionary WHERE Word like '%�㺸%'          
    
          UPDATE #TUIImpDelv  
             SET Result        = @Results,  
                 MessageType   = @MessageType,  
                 Status        = @Status  
            FROM #TUIImpDelv AS A
                 JOIN _TSLExpExpense AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                                       AND B.SMSourceType = 8215006
                                                       AND A.DelvSeq   = B.SourceSeq
                 JOIN _TSLExpExpenseDesc AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq
                                                           AND B.ExpenseSeq = C.ExpenseSeq
           WHERE ((A.WorkingTag = 'D')
              OR (A.WorkingTag = 'U' AND C.UMExpenseItem = @MinorSeq))
             AND  A.Status = 0
     
 -- select * from _TDASMinor where CompanySeq = 1 and MajorSeq = 8215
       -------------------------------------------    
      -- �ߺ�����üũ                                
      -------------------------------------------    
 --     EXEC dbo._SCOMMessage @MessageType OUTPUT,        
 --                           @Status      OUTPUT,        
 --                           @Results     OUTPUT,        
 --                           6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)        
 --                           @LanguageSeq       ,         
 --                           0,'�ŷ�����'          
 --     UPDATE #TUIImpDelv        
 --        SET Result        = REPLACE(@Results,'@2',RTRIM(B.DelvSeq)),        
 --            MessageType   = @MessageType,        
 --            Status        = @Status        
 --       FROM #TUIImpDelv AS A JOIN ( SELECT S.DelvSeq    
 --                                      FROM (        
 --                                            SELECT A1.DelvSeq    
 --                                              FROM #TUIImpDelv AS A1        
 --                                             WHERE A1.WorkingTag IN ('A','U')        
 --                                               AND A1.Status = 0        
 --                                            UNION ALL        
 --                                            SELECT A1.DelvSeq    
 --                                              FROM _TUIImpDelv AS A1        
 --                                             WHERE A1.CompanySeq  = @CompanySeq    
 --                                               AND A1.DelvSeq NOT IN (SELECT DelvSeq      
 --                                                                         FROM #TUIImpDelv         
 --                                                                        WHERE WorkingTag IN ('U','D')    
 --                                                                          AND Status = 0)   
 --                                               AND A1.CompanySeq = @CompanySeq        
 --                                           ) AS S        
 --                                     GROUP BY S.DelvSeq    
 --           HAVING COUNT(1) > 1        
 --                                   ) AS B ON A.DelvSeq = B.DelvSeq      
 --     
 --    
 --    
 --    
 --    
 --                                           SELECT A1.DelvSeq    
 --                                             FROM #TUIImpDelv AS A1        
 --                                            WHERE A1.WorkingTag IN ('A','U')        
 --                                              AND A1.Status = 0        
 --                      UNION ALL        
 --                                           SELECT A1.DelvSeq    
 --                                             FROM _TUIImpDelv AS A1         
 --                                            WHERE A1.CompanySeq  = @CompanySeq    
 --                                              AND A1.DelvSeq NOT IN (SELECT DelvSeq      
 --                                                                        FROM #TUIImpDelv         
 --                                                                       WHERE WorkingTag IN ('U','D')    
 --                                                                         AND Status = 0)        
 --                                              AND A1.CompanySeq = @CompanySeq
       -------------------------------------------    
      -- ��������üũ                                
      -------------------------------------------   
      EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                            @Status      OUTPUT,  
                            @Results     OUTPUT,  
                            5                , -- �̹� @1��(��) �Ϸ�� @2�Դϴ�. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 102)  
                            @LanguageSeq       ,   
                            0,'��������'   -- SELECT * FROM _TCADictionary WHERE Word like '%�㺸%'          
       UPDATE #TUIImpDelv  
         SET Result        = REPLACE(@Results,'@2','�԰�'),  
             MessageType   = @MessageType,  
             Status        = @Status  
        FROM #TUIImpDelv AS A
             JOIN _TUIImpDelvCostDiv AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                                       AND A.DelvSeq    = B.DelvSeq
       WHERE A.WorkingTag IN ('A','U','D')
         AND ISNULL(B.SlipSeq,0) <> 0
         AND A.Status = 0
     ----------------------------------------------------
     -- �����԰� �� �˻�� ���� ���� üũ 2010. 7. 5 hkim
     ----------------------------------------------------
  IF EXISTS (SELECT 1 FROM _TPDQCTestReport AS A
         JOIN #TUIImpDelv AS B ON A.SourceSeq = B.DelvSeq
         WHERE A.CompanySeq = @CompanySeq 
           AND B.WorkingTag IN ('U', 'D') AND B.Status = 0
           AND A.SourceType = '9')
  BEGIN
         EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                               @Status      OUTPUT,    
                               @Results     OUTPUT,    
                               18                  , -- �ʼ��Է� ����Ÿ�� �Է��ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
                               @LanguageSeq       ,     
                               0, '�����԰��İ˻�� ����� ��'   -- SELECT * FROM _TCADictionary WHERE Word like '%��ǥ%'            
          UPDATE #TUIImpDelv    
             SET Result        = @Results,    
                 MessageType   = @MessageType,    
                 Status        = @Status  
           FROM  #TUIImpDelv            AS A 
                 JOIN _TPDQCTestReport  AS B ON A.DelvSeq = B.SourceSeq
           WHERE A.WorkingTag IN ('U', 'D')
             AND A.Status     = 0
             AND B.CompanySeq = @CompanySeq
             AND B.SourceType = '9'
   
  END                  
     -------------------------------------------------------
     -- �����԰� �� �˻�� ���� ���� üũ �� 2010. 7. 5 hkim
     -------------------------------------------------------
     IF EXISTS (SELECT 1 FROM #TUIImpDelv WHERE WorkingTag IN ('U', 'D') )  
     BEGIN  
         -- ����üũ�� ���̺� ���̺�
         CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT IDENTITY, TABLENAME   NVARCHAR(100))      
         
         -- ����üũ�� ������ ���̺�
         CREATE TABLE #Temp_ImpDelv(IDX_NO INT IDENTITY, DelvSeq INT, DelvSerl INT, IsNext NCHAR(1)) 
         
         -- ����� ���� ���̺�
         CREATE TABLE #TCOMProgressTracking(IDX_NO   INT,            IDOrder INT,            Seq INT,           Serl INT,            SubSerl INT,
                                            Qty      DECIMAL(19, 5), StdQty  DECIMAL(19,5) , Amt DECIMAL(19, 5),VAT DECIMAL(19,5))
       
         SELECT @TableSeq = ProgTableSeq
           FROM _TCOMProgTable WITH(NOLOCK)--���������̺�
          WHERE ProgTableName = '_TUIImpDelvItem'
          INSERT INTO #TMP_PROGRESSTABLE(TABLENAME)
         SELECT B.ProgTableName
           FROM (SELECT ToTableSeq FROM _TCOMProgRelativeTables WITH(NOLOCK) WHERE FromTableSeq = @TableSeq AND CompanySeq = @CompanySeq) AS A --�������̺����
                 JOIN _TCOMProgTable AS B WITH(NOLOCK) ON A.ToTableSeq = B.ProgTableSeq
  
         
         INSERT INTO #Temp_ImpDelv(DelvSeq, DelvSerl, IsNext) -- IsNext=1(����), 0(������)
         SELECT  A.DelvSeq, B.DelvSerl, '0'
           FROM #TUIImpDelv     AS A WITH(NOLOCK)       
                 JOIN _TUIImpDelvItem AS B WITH(NOLOCK) ON B.CompanySeq   = @CompanySeq  
                                                     AND A.DelvSeq     = B.DelvSeq
          WHERE A.WorkingTag IN ('U', 'D')  
            AND A.Status = 0  
   
         EXEC _SCOMProgressTracking @CompanySeq, '_TUIImpDelvItem', '#Temp_ImpDelv', 'DelvSeq', 'DelvSerl', ''    
   
   
         UPDATE #Temp_ImpDelv   
           SET IsNext = '1'  
          FROM  #Temp_ImpDelv AS A  
                 JOIN #TCOMProgressTracking AS B ON A.IDX_No = B.IDX_No  
   
         --ERR Message
         EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                               @Status      OUTPUT,  
                               @Results     OUTPUT,  
                               1044               , -- ���� �۾��� ����Ǿ ����,������ �� �����ϴ�..(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1045)  
                               @LanguageSeq       ,   
                               0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%����%'  
         UPDATE #TUIImpDelv  
            SET Result        = @Results    ,  
                MessageType   = @MessageType,  
                Status        = @Status  
           FROM #TUIImpDelv   AS A  
                JOIN #Temp_ImpDelv AS B ON A.DelvSeq = B.DelvSeq  
          WHERE B.IsNext = '1' 
     END  
     -- ����update---------------------------------------------------------------------------------------------------------------    
     SELECT   @DataSeq = 0    
      WHILE ( 1 = 1 )     
     BEGIN    
         SELECT TOP 1 @DataSeq = DataSeq, @BaseDate = DelvDate, @DelvNo = DelvNo
           FROM #TUIImpDelv
          WHERE WorkingTag = 'A'    
            AND Status = 0    
            AND DataSeq > @DataSeq
          ORDER BY DataSeq
         
         IF @@ROWCOUNT = 0 BREAK
     
         -- DelvNo ����
         EXEC _SCOMCreateNo 'SL', '_TUIImpDelv', @CompanySeq, '', @BaseDate, @DelvNo OUTPUT    
  
         SELECT @count = COUNT(*)
           FROM #TUIImpDelv      
          WHERE WorkingTag = 'A' AND Status = 0        
         
         IF @count > 0    
         BEGIN    
             -- DelvSeq ����    
             EXEC @DelvSeq = _SCOMCreateSeq @CompanySeq, '_TUIImpDelv', 'DelvSeq', @Count
         END
     
         UPDATE #TUIImpDelv
            SET DelvSeq = @DelvSeq + DataSeq,     
                DelvNo  = @DelvNo    
          WHERE WorkingTag = 'A'
            AND Status = 0    
            AND DataSeq = @DataSeq    
     END    
     
 --    --��������� ��
 --    UPDATE #TUIImpDelv  
 --       SET IsSalesWith = M.ValueText  
 --      FROM #TUIImpDelv AS A  
 --            LEFT OUTER JOIN _TDAUMinorValue AS M WITH(NOLOCK) ON M.CompanySeq = @CompanySeq  
 --                                                             AND A.UMOutKind  = M.MinorSeq  
 --                                                             AND M.Serl = 2001  
     -------------------------------------------  
     -- �����ڵ�0���Ͻÿ����߻�
     -------------------------------------------      
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 1055)    
                           @LanguageSeq       
      UPDATE #TUIImpDelv                               
        SET Result        = @Results     ,    
            MessageType   = @MessageType ,    
            Status        = @Status    
       FROM #TUIImpDelv
      WHERE Status = 0
        AND (DelvSeq = 0 OR DelvSeq IS NULL)
      SELECT * FROM #TUIImpDelv    
     
     RETURN
GO
begin tran 
exec KPXCM_SSLImpDelvMasterCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <BizUnit>2</BizUnit>
    <DelvSeq>1000185</DelvSeq>
    <DelvDate>20151001</DelvDate>
    <EmpSeq>2028</EmpSeq>
    <DeptSeq>1300</DeptSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030539,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026155

rollback 