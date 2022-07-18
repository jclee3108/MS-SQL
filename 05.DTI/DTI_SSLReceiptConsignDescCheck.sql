
IF OBJECT_ID('DTI_SSLReceiptConsignDescCheck') IS NOT NULL 
    DROP PROC DTI_SSLReceiptConsignDescCheck
GO 

-- v2014.05.21 

-- ����Ź�Ա��Է�_DTI(����Ź����üũ) by����õ 
CREATE PROC DTI_SSLReceiptConsignDescCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS 
    
    DECLARE @Count           INT,
            @ReceiptSeq      INT, 
            @MessageType     INT,
            @Status          INT,
            @Results         NVARCHAR(250)
    
    CREATE TABLE #DTI_TSLReceiptConsign(WorkingTag NCHAR(1) NULL)  
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TSLReceiptConsign'  
        
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #DTI_TSLReceiptConsignDesc(WorkingTag NCHAR(1) NULL)  
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#DTI_TSLReceiptConsignDesc'  
    
    CREATE TABLE #AtmDiff(ReceiptSeq INT, ReceiptSerl INT, Notifyseq INT, NotifySerl INT, DiffAmt DECIMAL(19,5))
    CREATE TABLE #Tmp_SumAmt(ReceiptSeq INT, TempDomAmt DECIMAL(19,5), OriDomAmt DECIMAL(19,5), DiffAmt DECIMAL(19,5))
    
    -- �ڱ���ȭ�̰� ��ȭ�ݾ��� 0�� �ƴ� ���¿��� ��ȭ�ݾ� <> ��ȭ�ݾ��̸� ���� ���� 
    -- 2012.05.29 by ��ö�� 
    DECLARE @EnvValue INT, @Word NVARCHAR(200)
    
    SELECT @EnvValue = CONVERT( INT, EnvValue ) FROM _TCOMEnv WHERE CompanySeq = @CompanySeq and EnvSeq = 13
    IF @@ROWCOUNT <> 0 SELECT @EnvValue = 1 
    
    SELECT @Word = Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq and WordSeq = 7648
    IF @@ROWCOUNT <> 0 SELECT @Word = N'��ȭ�Աݾ�' 
    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,
                          @Status      OUTPUT,
                          @Results     OUTPUT,
                          1102, -- @1��(��) ��ġ���� �ʽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%��ġ%')
                          @LanguageSeq, 
                          7489, N'��ȭ�Աݾ�' -- SELECT * FROM _TCADictionary WHERE Word like '%��ȭ�Աݾ�%'        
    UPDATE A
       SET A.Result        = @Word+', '+@Results,
           A.MessageType   = @MessageType,
           A.Status        = @Status
      FROM #DTI_TSLReceiptConsignDesc AS A 
      JOIN #DTI_TSLReceiptConsign     AS B ON ( A.ReceiptSeq = B.ReceiptSeq AND B.CurrSeq = @EnvValue )
     WHERE A.Status = 0 
       AND ISNULL(A.CurAmt,0) <> 0 
       AND A.CurAmt <> A.DomAmt
    
    -------------------------------------------
    -- �ʼ�������üũ
    -------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,
                          @Status      OUTPUT,
                          @Results     OUTPUT,
                          1                  , -- �ʼ��Է� ����Ÿ�� �Է��ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)
                          @LanguageSeq       , 
                          '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%�㺸%'        
    UPDATE #DTI_TSLReceiptConsignDesc
       SET Result        = @Results,
           MessageType   = @MessageType,
           Status        = @Status
     WHERE ReceiptSeq = 0
        OR ReceiptSeq IS NULL
    
    --------------------------------------------------------------------------------------
    -- ������ ���� üũ : UPDATE, DELETE �� ������ �������� ������ ����ó��
    --------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 
                     FROM #DTI_TSLReceiptConsignDesc AS A 
                     JOIN DTI_TSLReceiptConsignDesc AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ReceiptSeq = B.ReceiptSeq AND A.ReceiptSerl = B.ReceiptSerl ) 
                    WHERE A.WorkingTag IN ('U', 'D'))
    BEGIN
        EXEC dbo._SCOMMessage @MessageType OUTPUT,
                              @Status      OUTPUT,
                              @Results     OUTPUT,
                              7                  , -- �ڷᰡ ��ϵǾ� ���� �ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)
                              @LanguageSeq       , 
                              '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
        UPDATE #DTI_TSLReceiptConsignDesc
           SET Result        = @Results,
               MessageType   = @MessageType,
               Status        = @Status
         WHERE WorkingTag IN ('U','D')
    END 
    /*
    -------------------------------------------
    -- ��ǥ����üũ                            
    -------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          8                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1562)    
                          @LanguageSeq       ,
                          1562, '', 0, ' '
    
    UPDATE #DTI_TSLReceiptConsignDesc    
       SET Result        = REPLACE(@Results,'@3',A2.PreOffNo),    
           MessageType   = @MessageType,    
           Status        = @Status    
      FROM #DTI_TSLReceiptConsignDesc      AS A 
      JOIN _TSLPreReceiptItem   AS A1 ON ( A1.CompanySeq = @CompanySeq AND A.ReceiptSeq = A1.ReceiptSeq ) 
      JOIN _TSLPreReceipt       AS A2 ON ( A2.CompanySeq = @CompanySeq AND A1.PreOffSeq = A2.PreOffSeq ) 
     WHERE A.WorkingTag IN ('A','U','D')
       AND A.Status = 0
    
     -------------------------------------------
     -- �Ա��뺸�ܾ�üũ                        
     -------------------------------------------
     INSERT INTO #AtmDiff(ReceiptSeq, ReceiptSerl, Notifyseq, NotifySerl, DiffAmt)
     SELECT A.ReceiptSeq, A.ReceiptSerl, ISNULL(E.Notifyseq, 0), ISNULL(E.NotifySerl, 0), CASE ISNULL(E.CurAmt, 0) WHEN 0 THEN ISNULL(A.CurAmt, 0) ELSE ISNULL(E.CurAmt, 0) - ISNULL(A.CurAmt, 0) END
       FROM #DTI_TSLReceiptConsignDesc AS A 
             LEFT OUTER JOIN (SELECT B.NotifySeq AS NotifySeq, B.NotifySerl AS NotifySerl, ISNULL(C.ForAmt, 0) - ISNULL(D.CurAmt, 0) AS CurAmt
                                FROM #DTI_TSLReceiptConsignDesc AS B
                                     LEFT OUTER JOIN _TSLReceiptDesc AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq
                                                                                      AND B.NotifySeq  = D.NotifySeq
                                                                                      AND B.NotifySerl = D.NotifySerl
                                                                                      AND NOT(B.ReceiptSeq = D.ReceiptSeq AND B.ReceiptSerl = D.ReceiptSerl) --- 20101118 by ����ȯ
                                     LEFT OUTER JOIN _TACRevNotifyDesc AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                                                        AND B.NotifySeq     = C.Notifyseq 
                                                                                        AND B.NotifySerl    = C.Serl ) AS E ON A.NotifySeq  = E.NotifySeq
                                                                                                                           AND A.NotifySerl = E.NotifySerl    
      WHERE A.NotifySeq <> 0                                                                                                                                                                                                                          
      EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           106                  , -- @1��(��) @2�� @3��(��) �ʰ��� �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 106)    
                           @LanguageSeq       ,
         1923, '', 
         11348, '', 
         11349, ''
     
     UPDATE #DTI_TSLReceiptConsignDesc    
        SET Result        = @Results,    
            MessageType   = @MessageType,    
            Status        = @Status    
       FROM #DTI_TSLReceiptConsignDesc AS A
             LEFT OUTER JOIN #AtmDiff AS B ON A.ReceiptSeq  = B.ReceiptSeq
                                          AND A.ReceiptSerl = B.ReceiptSerl
      WHERE A.WorkingTag IN ('A','U')
        AND A.Status = 0
        AND B.DiffAmt < 0 
    */
     -------------------------------------------
     -- ������ �հ�ݾ� üũ              
     -- ������Ϸ��� ���� 0���� �Ͽ� �հ�ݾ��� ���� �Ŀ� �����ϵ��� �Ѵ�. 
     -- 2010.12.20 �ش� ��� ���� by ������
     -------------------------------------------
     --EXEC dbo._SCOMMessage @MessageType OUTPUT,    
     --                      @Status      OUTPUT,    
     --                      @Results     OUTPUT,    
     --                      105               , -- @1��(��) @2 �̾�� �մϴ�.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 105)    
     --                      @LanguageSeq      ,
     --    290, '',            -- (SELECT * from _TCADictionary WHERE LanguageSEq = 1 AND Word Like '%0%')
     --                      '', '0'
     --UPDATE #DTI_TSLReceiptConsignDesc    
     --   SET Result        = @Results,    
     --       MessageType   = @MessageType,    
     --       Status        = @Status    
     --  FROM #DTI_TSLReceiptConsignDesc AS A
     -- WHERE A.WorkingTag = 'D'
     --   AND A.Status = 0
     --   AND A.DomAmt <> 0      
        
      -- ����update---------------------------------------------------------------------------------------------------------------
     /* �Աݴ����Է��� �����ϹǷ� �ѹ��� �������� ReceiptSeq�� ���� �� �����Ƿ� Seq���� Serl�� ���ֵ��� �Ѵ�. */
    UPDATE #DTI_TSLReceiptConsignDesc  
       SET ReceiptSerl = D.Serl  
      FROM #DTI_TSLReceiptConsignDesc AS C  
      JOIN (SELECT A.IDX_NO, ISNULL(B.MaxSerl, 0) + ROW_NUMBER() OVER(PARTITION BY A.ReceiptSeq ORDER BY A.IDX_NO) AS Serl  
              FROM #DTI_TSLReceiptConsignDesc AS A  
              LEFT OUTER JOIN (SELECT CompanySeq, ReceiptSeq, MAX(ReceiptSerl) AS MaxSerl  
                                 FROM _TSLReceiptDesc  
                                GROUP BY CompanySeq, ReceiptSeq  
                              ) AS B ON ( B.CompanySeq = @CompanySeq AND A.ReceiptSeq = B.ReceiptSeq ) 
             WHERE A.WorkingTag = 'A'   
               AND A.Status = 0  
           ) AS D ON C.IDX_NO = D.IDX_NO  
    
    --���뱸�а��� 0���� ���� �� üũ
    IF EXISTS (SELECT 1 FROM #DTI_TSLReceiptConsignDesc WHERE SMDrOrCr = 0)
    BEGIN
    UPDATE #DTI_TSLReceiptConsignDesc
       SET SMDrOrCr = ISNULL(B.ValueSeq,'1')
      FROM  #DTI_TSLReceiptConsignDesc AS A    
      LEFT OUTER JOIN _TDAUMinorValue AS B WITH (NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.UMReceiptKind = B.MinorSeq AND B.Serl = 1002 ) 
     WHERE A.SMDrOrCr = 0
    END
    
    -------------------------------------------  
    -- �����ڵ� 0���Ͻ� ���� �߻�
    -------------------------------------------      
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          1055               , -- ó���۾��� ������ �߻��߽��ϴ�. �ٽ� ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 1055)    
                          @LanguageSeq       
    UPDATE #DTI_TSLReceiptConsignDesc                               
       SET Result        = @Results     ,    
           MessageType   = @MessageType ,    
           Status        = @Status    
      FROM #DTI_TSLReceiptConsignDesc
     WHERE Status = 0
       AND (ReceiptSerl = 0 OR ReceiptSerl IS NULL)
    
    SELECT * FROM #DTI_TSLReceiptConsignDesc
    
    RETURN