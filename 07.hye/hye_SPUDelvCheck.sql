IF OBJECT_ID('hye_SPUDelvCheck') IS NOT NULL 
    DROP PROC hye_SPUDelvCheck 
GO 

-- v2016.09.29 

-- ���ų�ǰ�Է�_üũ by����õ 
/************************************************************  
��  �� - ���ų�ǰüũ(������)
�ۼ��� - 2008�� 8�� 20��   
�ۼ��� - �뿵��  
************************************************************/  
  
CREATE PROC hye_SPUDelvCheck    
    @xmlDocument    NVARCHAR(MAX),      
    @xmlFlags       INT = 0,      
    @ServiceSeq     INT = 0,      
    @WorkingTag     NVARCHAR(10) = '',      
    @CompanySeq     INT = 0,      
    @LanguageSeq    INT = 1,      
    @UserSeq        INT = 0,      
    @PgmSeq         INT = 0      
AS      
      
    -- ���� ����      
    DECLARE @Count       INT,        
            @DataSeq     INT,        
            @DelvSeq  INT,         
            @DelvNo   NVARCHAR(12),        
            @BaseDate    NVARCHAR(8),        
            @MaxNo       NVARCHAR(12),        
            @BizUnit     INT,        
            @MaxQutoRev  INT,  
            @MessageType INT,        
            @Status      INT,        
            @Results     NVARCHAR(250),
            @QCAutoIn    NCHAR(1)              
     
    
    -- �ӽ� ���̺� ����  _TPUDelv      
    CREATE TABLE #TPUDelv (WorkingTag NCHAR(1) NULL)      
    -- �ӽ� ���̺� ������ �÷��� �߰��ϰ�, xml�κ����� ���� insert�Ѵ�.      
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUDelv'         
   
    CREATE TABLE #TPUDelvIn (WorkingTag NCHAR(1) NULL)    
    -- �ӽ� ���̺� ������ �÷��� �߰��ϰ�, xml�κ����� ���� insert�Ѵ�.    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2608, 'DataBlock1', '#TPUDelvIn'       
    

    -- Ȯ��üũ �߰� by����õ 
    UPDATE A
       SET Result = '���ڰ��簡 ���� �� ���ų�ǰ ���� ����/���� �� �� �����ϴ�.(��ǰ)', 
           Status = 1234,
           MessageType = 1234 
      FROM #TPUDelv                    AS A 
      LEFT OUTER JOIN _TPUDelv_Confirm  AS B ON ( B.CompanySeq = @CompanySeq AND B.CfmSeq = A.DelvSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
       AND B.IsAuto = '0' 
       AND B.CfmCode <> 0 
    -- Ȯ��üũ, END 
    
     -------------------------------------------    
     -- �ʼ�������üũ    
     -------------------------------------------    
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           1                  , -- �ʼ��Է� ����Ÿ�� �Է��ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
                           @LanguageSeq       ,     
                           0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%�㺸%'            
     UPDATE #TPUDelv    
        SET Result        = @Results,    
            MessageType   = @MessageType,    
            Status        = @Status    
      WHERE DelvDate = ''    
         OR DelvDate IS NULL    
    -- �����԰� ���� �� ���� ���� ����
    IF EXISTS (SELECT 1 FROM #TPUDelv WHERE WorkingTag IN ('U', 'D') )
    BEGIN
        -------------------
        --�԰����࿩��-----
        -------------------
        CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))    
          
        CREATE TABLE #Temp_Order(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT,IsDelvIn NCHAR(1))    
        
    
        CREATE TABLE #TCOMProgressTracking(IDX_NO INT, IDOrder INT, Seq INT,Serl INT, SubSerl INT,Qty DECIMAL(19, 5), StdQty DECIMAL(19,5) , Amt    DECIMAL(19, 5),VAT DECIMAL(19,5))      
    
        CREATE TABLE #OrderTracking(IDX_NO INT, POQty DECIMAL(19,5), POCurAmt DECIMAL(19,5))
    
        INSERT #TMP_PROGRESSTABLE     
        SELECT 1, '_TPUDelvInItem'               -- �����԰�

        -- ���ų�ǰ
        INSERT INTO #Temp_Order(OrderSeq, OrderSerl, IsDelvIn)    
        SELECT  A.DelvSeq, B.DelvSerl, '2'    
          FROM #TPUDelv     AS A WITH(NOLOCK)     
          JOIN _TPUDelvItem AS B WITH(NOLOCK) ON @CompanySeq = B.CompanySeq    
                                              AND A.DelvSeq  = B.DelvSeq  
         WHERE A.WorkingTag IN ('U', 'D')
           AND A.Status = 0

        EXEC _SCOMProgressTracking @CompanySeq, '_TPUDelvItem', '#Temp_Order', 'OrderSeq', 'OrderSerl', ''    
       
        
        INSERT INTO #OrderTracking    
        SELECT IDX_NO,    
               SUM(CASE IDOrder WHEN 1 THEN Qty     ELSE 0 END),    
               SUM(CASE IDOrder WHEN 1 THEN Amt     ELSE 0 END)   
          FROM #TCOMProgressTracking    
         GROUP BY IDX_No    
 
        UPDATE #Temp_Order 
           SET IsDelvIn = '1'
          FROM #Temp_Order AS A  
               JOIN #OrderTracking AS B ON A.IDX_No = B.IDX_No
        
        -- ȯ�漳���� ��������  # ���˻�ǰ �ڵ��԰� ����
        EXEC dbo._SCOMEnv @CompanySeq,6500,@UserSeq,@@PROCID,@QCAutoIn OUTPUT  
    
        IF @QCAutoIn <> '1'    -- ���˻�ǰ �ڵ��԰� �ƴ� ���
        BEGIN
            -------------------
            --�԰����࿩��END------
            -------------------
            EXEC dbo._SCOMMessage @MessageType OUTPUT,
                                  @Status      OUTPUT,
                                  @Results     OUTPUT,
                                  1044               , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
                                  @LanguageSeq       , 
                                  0,'��ǰ������'   -- SELECT * FROM _TCADictionary WHERE Word like '%����%'
            UPDATE #TPUDelv
               SET Result        = @Results    ,
                   MessageType   = @MessageType,
                   Status        = @Status
              FROM #TPUDelv         AS A
                   JOIN #Temp_Order AS B ON A.DelvSeq = B.OrderSeq
                   JOIN _TPUDelv	AS C ON A.DelvSeq = C.DelvSeq
             WHERE B.IsDelvIn   IN ('1') 
               AND A.WorkingTag IN ('U')
               AND A.Status = 0
		       AND ( (A.DelvDate    <> C.DelvDate) OR (A.CustSeq   <> C.CustSeq) OR (A.SMImpType <> C.SMImpType) 
				  OR (A.CurrSeq   <> C.CurrSeq) OR (A.ExRate    <> C.ExRate) )
        END
        ELSE 
        BEGIN
            -- ��ǥó������ ����/���� ���� �ʵ��� �߰�
            UPDATE #TPUDelvIn
               SET DelvInSeq  = (SELECT TOP 1 Seq FROM #TCOMProgressTracking),
                   DelvInDate = (SELECT TOP 1 DelvDate FROM #TPUDelv),
                   WorkingTag = (SELECT TOP 1 WorkingTag FROM #TPUDelvIn)

            EXEC _SPUDelvInCheck     @xmlDocument    = N''           ,
                                     @xmlFlags       = @xmlFlags     ,
                                     @ServiceSeq     = 2608   ,
                                     @WorkingTag     = 'AUTO'  ,
                                     @CompanySeq     = @CompanySeq   ,
                                     @LanguageSeq    = @LanguageSeq  ,
                                     @UserSeq        = @UserSeq      ,
                                     @PgmSeq         = @PgmSeq
            IF @@ERROR <> 0 RETURN    
            
            UPDATE #TPUDelv
               SET Status      = A.Status     ,
                   MessageType = A.MessageType,
                   Result      = A.Result
              FROM #TPUDelvIn AS A

            --## �ڵ��԰� ������ �����԰� �� �˻簡 ó�� �� ���� ����/������ ���� �ʵ��� �߰� ##
            EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                                  @Status      OUTPUT,    
                                  @Results     OUTPUT,    
                                  18                  , -- �ʼ��Է� ����Ÿ�� �Է��ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
                                  @LanguageSeq       ,     
                                  0, '�����԰��İ˻�� ����� ��'   -- SELECT * FROM _TCADictionary WHERE Word like '%��ǥ%'            
             UPDATE #TPUDelv    
                SET Result        = @Results,    
                    MessageType   = @MessageType,    
                    Status        = @Status  
              FROM  #TPUDelv                 AS A 
                    JOIN #Temp_Order           AS B ON A.DelvSeq   = B.OrderSeq
                    JOIN #TCOMProgressTracking AS C ON B.IDX_No = C.IDX_No
                    JOIN _TPDQCTestReport      AS D ON C.Seq  = D.SourceSeq
              WHERE A.WorkingTag IN ('U', 'D')
                AND A.Status     = 0
                AND D.CompanySeq = @CompanySeq
                AND D.SourceType = '7'
        END

    END  
     -- �μ��˻簡 �Ϸ�� ���� ����/���� ����
     IF EXISTS (SELECT 1 FROM _TPDQCTestReport AS A
                              JOIN #TPUDelv    AS B ON A.SourceSeq = B.DelvSeq 
                        WHERE A.CompanySeq = @CompanySeq AND A.SourceType = '1' AND B.WorkingTag IN ('D') AND B.Status = 0)
     BEGIN
             EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                                   @Status      OUTPUT,    
                                   @Results     OUTPUT,    
                                   18                  , -- �ʼ��Է� ����Ÿ�� �Է��ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
                                   @LanguageSeq       ,     
                                   0, '�����μ��˻�� ����� ��'   -- SELECT * FROM _TCADictionary WHERE Word like '%��ǥ%'            
              UPDATE #TPUDelv    
                 SET Result        = @Results,    
                     MessageType   = @MessageType,    
                     Status        = @Status  
               FROM  #TPUDelv      
     END    
    
  
    --����update---------------------------------------------------------------------------------------------------------------        
    SELECT   @DataSeq = 0        
      
    WHILE ( 1 = 1 )         
    BEGIN        
        SELECT TOP 1 @DataSeq = DataSeq, @BaseDate = DelvDate        
        FROM #TPUDelv        
         WHERE WorkingTag = 'A'        
           AND Status = 0        
           AND DataSeq > @DataSeq        
         ORDER BY DataSeq        
            
        IF @@ROWCOUNT = 0 BREAK     

        -- DelvNo ����        
        EXEC _SCOMCreateNo 'PU', '_TPUDelv', @CompanySeq, '', @BaseDate, @DelvNo OUTPUT        
        
    
        SELECT @count = COUNT(*)          
          FROM #TPUDelv          
         WHERE WorkingTag = 'A' AND Status = 0            
            
        IF @count > 0        
        BEGIN     
            EXEC @DelvSeq = _SCOMCreateSeq @CompanySeq, '_TPUDelv', 'DelvSeq', 1    
        END        
        
        UPDATE #TPUDelv        
           SET DelvSeq = @DelvSeq + 1,--DataSeq, :: ������ �ѰǾ� ó���ǹǷ� �ϰ�ó���� ����ϸ� 1�� �����Ǿ�� �ϹǷ� 20120828 by õ���
               DelvNo  = @DelvNo        
         WHERE WorkingTag = 'A'        
           AND Status = 0        
           AND DataSeq = @DataSeq        
    END        
    
    UPDATE #TPUDelv
       SET SMImpType = 8008001
     WHERE ISNULL(SMIMPType,0) = 0
     
    SELECT * FROM #TPUDelv        
          
      
RETURN      
/***********************************************************************************************************************/