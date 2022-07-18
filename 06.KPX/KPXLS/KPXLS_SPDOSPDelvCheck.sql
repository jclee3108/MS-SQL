IF OBJECT_ID('KPXLS_SPDOSPDelvCheck') IS NOT NULL 
    DROP PROC KPXLS_SPDOSPDelvCheck
GO 

-- v2016.02.22 

-- ���԰˻��Ƿ� �����Ͱ� ���� ��� �������� �Ұ� �߰� by����õ 
/************************************************************
��  �� - ���Ű���üũ
�ۼ��� - 2008�� 8�� 20�� 
�ۼ��� - �뿵��
��������

-- 2011.03.03   ����â�� ���°�� ����üũ  UPDATE BY �輼ȣ
-- 2011.11.03   �������â��üũ�� â���뿩�� ���� �߰�  UPDATE BY �輼ȣ
************************************************************/

CREATE PROC KPXLS_SPDOSPDelvCheck
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
            @OSPDelvSeq  INT,       
            @OSPDelvNo   NVARCHAR(12),      
            @BaseDate    NVARCHAR(8),      
            @MaxNo       NVARCHAR(12),      
            @BizUnit     INT,      
            @MaxQutoRev  INT,
            @MessageType INT,      
            @Status      INT,      
            @Results     NVARCHAR(250)            

  
    -- �ӽ� ���̺� ����  _TPDOSPDelv    
    CREATE TABLE #TPDOSPDelv (WorkingTag NCHAR(1) NULL)    
    -- �ӽ� ���̺� ������ �÷��� �߰��ϰ�, xml�κ����� ���� insert�Ѵ�.    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDOSPDelv'       

    CREATE TABLE #TPDOSPDelvIn (WorkingTag NCHAR(1) NULL)    
    -- �ӽ� ���̺� ������ �÷��� �߰��ϰ�, xml�κ����� ���� insert�Ѵ�.    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2979, 'DataBlock1', '#TPDOSPDelvIn'       
    
    
    -- üũ1, ���԰˻��Ƿ� �����Ͱ� �����Ͽ� ����/���� �� �� �����ϴ�. 
    UPDATE A
       SET Result = '���԰˻��Ƿ� �����Ͱ� �����Ͽ� ����/���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #TPDOSPDelv AS A 
     WHERE A.WorkingTag IN ( 'U', 'D' ) 
       AND A.Status = 0  
       AND EXISTS (SELECT 1 FROM KPXLS_TQCRequest WHERE CompanySeq = @CompanySeq AND FromPgmSeq = 1028274 AND SourceSeq = A.OSPDelvSeq)
    -- üũ1, END 
    
    
    SELECT TOP 1 @OSPDelvSeq = ISNULL(OSPDelvSeq, 0)   
      FROM #TPDOSPDelv  



     -------------------------------------------  
     -- �ʼ�������üũ  
     -------------------------------------------  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results     OUTPUT,  
                           1                  , -- �ʼ��Է� ����Ÿ�� �Է��ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)  
                           @LanguageSeq       ,   
                           0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%�㺸%'          
     UPDATE #TPDOSPDelv  
        SET Result        = @Results,  
            MessageType   = @MessageType,  
            Status        = @Status  
      WHERE OSPDelvDate = ''  
         OR OSPDelvDate IS NULL  

    
    -------------------------------------------
    -- ���࿩��üũ
    -------------------------------------------
    DECLARE @EnvValue   NVARCHAR(100)   -- �������� ������� �ۼ��� �ڵ��԰�ó�� ����

    -- ȯ�漳���� �������� ����ǰ�� �ڵ��԰���
    EXEC dbo._SCOMEnv @CompanySeq,6503,@UserSeq,@@PROCID,@EnvValue OUTPUT


    IF  @EnvValue NOT IN ('1','True') -- ����ǰ�� �ڵ��԰���
       AND EXISTS (SELECT 1 FROM #TPDOSPDelv WHERE WorkingTag IN ('U', 'D') AND Status = 0)
    BEGIN 

        EXEC dbo._SCOMProgressCheck     @CompanySeq             ,
                                        '_TPDOSPDelvItem'      ,
                                        1                       ,
                                        '#TPDOSPDelv'      ,
                                        'OSPDelvSeq'          ,
                                        ''         ,
                                        ''                      ,
                                        'Status'

        EXEC dbo._SCOMMessage @MessageType OUTPUT,
                              @Status      OUTPUT,
                              @Results     OUTPUT,
                              1044               , -- ���� �۾��� ����Ǿ ����,������ �� �����ϴ�.
                              @LanguageSeq

        UPDATE #TPDOSPDelv 
           SET Result        = @Results     ,
               MessageType   = @MessageType ,
               Status        = @Status
          FROM #TPDOSPDelv AS A
         WHERE A.WorkingTag IN ('U','D')
           AND A.Status = 1

    END 

    -- �ڵ��԰��ο� ������� �˻�ǰ �˻����࿩�θ� üũ�Ѵ�. 
    -- ��Ʈ���� �ƴҰ�츸 üũ(���˻�ǰ/�˻�ǰ�� �Ѱ����� ��ǰ�������� ���˻�ǰ ��Ʈ������ /'�ϱ� üũŸ�� �ȵǹǷ�,
    --                               ��Ʈ������ ���� ǰ��üũSP ���� �ϱ� üũ�ǵ��� ó��)           -- 12.11.15 BY �輼ȣ
    IF  @WorkingTag <> 'SC' AND EXISTS (SELECT 1 FROM #TPDOSPDelv WHERE WorkingTag IN ('U', 'D') AND Status = 0)
    BEGIN 

        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                              @Status      OUTPUT,    
                              @Results     OUTPUT,    
                              102               , -- @1 �����Ͱ� �����մϴ�.  
                              @LanguageSeq  ,  
                              7908, ''  

        UPDATE #TPDOSPDelv 
           SET Result        = @Results     ,
               MessageType   = @MessageType ,
               Status        = @Status
          FROM #TPDOSPDelv AS A JOIN _TPDQCTestReport AS B ON A.OSPDelvSeq = B.SourceSeq and B.CompanySeq = @CompanySeq
                                                          AND B.SourceType = '2'
         WHERE A.WorkingTag IN ('U', 'D')
           AND A.Status = 0

    END 


    -- �ڵ��԰������� ��ǥ���� ����� ���� �����Ǿ�� �ȵȴ�(�ű԰� ���� �����Ǹ� ó���Ѵ�)
    IF @EnvValue IN ('1', 'True') AND EXISTS (SELECT 1 FROM #TPDOSPDelv WHERE WorkingTag IN ('U', 'D') AND Status = 0) AND @WorkingTag <> 'SC'  
    BEGIN
----------------------------------------------------------------------------
                            --�԰����࿩��-----
----------------------------------------------------------------------------
        CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))    
    
        CREATE TABLE #TCOMProgressTracking(IDX_NO INT, IDOrder INT, Seq INT,Serl INT, SubSerl INT,Qty DECIMAL(19, 5), StdQty DECIMAL(19,5) , Amt    DECIMAL(19, 5),VAT DECIMAL(19,5))      
    
        CREATE TABLE #OrderTracking(IDX_NO INT, Qty DECIMAL(19,5), POCurAmt DECIMAL(19,5))
    
        INSERT #TMP_PROGRESSTABLE     
        SELECT 1, '_TPDOSPDelvInItem'               -- �����԰�
        
        EXEC _SCOMProgressTracking @CompanySeq, '_TPDOSPDelvItem', '#TPDOSPDelv', 'OSPDelvSeq', '', ''    
        
        IF EXISTS (SELECT 1 FROM #TCOMProgressTracking)
        BEGIN
            UPDATE #TPDOSPDelvIn
               SET OSPDelvInSeq   = (SELECT TOP 1 Seq FROM #TCOMProgressTracking),
                   OSPDelvInDate  = (SELECT TOP 1 OSPDelvDate FROM #TPDOSPDelv),
                   WorkingTag     = (SELECT TOP 1 WorkingTag FROM #TPDOSPDelv)
            -- üũ
            EXEC _SPDOSPDelvInCheck     @xmlDocument    = N''           ,
                                        @xmlFlags       = @xmlFlags     ,
                                        @ServiceSeq     = 2979   ,
                                        @WorkingTag     = 'AUTO'  ,
                                        @CompanySeq     = @CompanySeq   ,
                                        @LanguageSeq    = @LanguageSeq  ,
                                        @UserSeq        = @UserSeq      ,
                                        @PgmSeq         = @PgmSeq
            IF @@ERROR <> 0 RETURN    
            
            UPDATE #TPDOSPDelv
               SET Status      = A.Status     ,
                   MessageType = A.MessageType,
                   Result      = A.Result
              FROM #TPDOSPDelvIn AS A
        END
    END


----------------------------------------------------------------------------
                           ----�ŷ�ó â�� üũ-----                    -- 11.03.03 �輼ȣ �߰�
----------------------------------------------------------------------------

  -- ��������� �����ִ� ����ι� �ڵ� ��������
  SELECT @BizUnit = B.BizUnit
    FROM #TPDOSPDelv AS A
      JOIN _TDAFactUnit   AS B ON A.FactUnit   = B.FactUnit
   WHERE B.CompanySeq = @CompanySeq


-- �ش� ����ι�, ����ó�� �ɸ� �������â�� �������     --11.10.19 �輼ȣ ����

EXEC dbo._SCOMMessage @MessageType OUTPUT,    
         @Status      OUTPUT,    
         @Results     OUTPUT,    
         1293         , 
         @LanguageSeq       , 
         21676, '',    
         14881, ''  

UPDATE #TPDOSPDelv                 
   SET MessageType = @MessageType,
       Status      = @Status,
       Result       = @Results
   FROM #TPDOSPDelv AS C
   WHERE  C.Status = 0 
      AND C.WorkingTag IN ('A', 'U')
      AND NOT EXISTS (SELECT 1
           FROM #TPDOSPDelv AS A
           JOIN _TDAWH      AS B ON A.CustSeq = B.CommissionCustSeq 
                                AND @BizUnit  = B.BizUnit
                                AND B.IsNotUse <> '1'
           WHERE @CompanySeq = B.CompanySeq
             AND B.SMWHKind  = 8002024)




-- �ش� ����ι�, �����, ����ó�� �ɸ� �������â�� 2�� �̻��� ���     --12.01.06 �輼ȣ ����

EXEC dbo._SCOMMessage @MessageType OUTPUT,    
         @Status      OUTPUT,    
         @Results     OUTPUT,    
         1204                  , 
         @LanguageSeq       ,     
         14881, '�������â��'  


UPDATE #TPDOSPDelv                    
   SET MessageType = @MessageType,  
       Status      = @Status,  
       Result       = LEFT(REPLACE(@Results, '@2', '2���̻�'), 23)  
   FROM #TPDOSPDelv AS C  
   WHERE  C.Status = 0   
      AND C.WorkingTag IN ('A', 'U')  
      AND EXISTS  (SELECT 1         
                       FROM #TPDOSPDelv AS A  
                       JOIN _TDAWH      AS B ON  A.CustSeq = B.CommissionCustSeq   
                                            AND @BizUnit  = B.BizUnit  
                                            AND B.IsNotUse <> '1'  
                       WHERE @CompanySeq = B.CompanySeq  
                         AND B.SMWHKind  = 8002024
                    GROUP BY B.BizUnit, B.FactUnit, B.CommissionCustSeq, B.SMWHKind
                     HAVING COUNT(1) > 1)  



       -- ����update---------------------------------------------------------------------------------------------------------------      
    SELECT   @DataSeq = 0      
    
    WHILE ( 1 = 1 )       
    BEGIN      
        SELECT TOP 1 @DataSeq = DataSeq, @BaseDate = OSPDelvDate      
          FROM #TPDOSPDelv      
         WHERE WorkingTag = 'A'      
           AND Status = 0      
           AND DataSeq > @DataSeq      
         ORDER BY DataSeq      
          
        IF @@ROWCOUNT = 0 BREAK      
      
        -- OSPDelvNo ����      
        EXEC _SCOMCreateNo 'PD', '_TPDOSPDelv', @CompanySeq, '', @BaseDate, @OSPDelvNo OUTPUT      
      

  
        SELECT @count = COUNT(*)        
          FROM #TPDOSPDelv        
         WHERE WorkingTag = 'A' AND Status = 0          
          
        IF @count > 0      
        BEGIN      
            -- OSPDelvSeq ����      
            EXEC @OSPDelvSeq = _SCOMCreateSeq @CompanySeq, '_TPDOSPDelv', 'OSPDelvSeq', @count       
        END      
      
        UPDATE #TPDOSPDelv      
           SET OSPDelvSeq = @OSPDelvSeq + 1,       
               OSPDelvNo  = @OSPDelvNo      
         WHERE WorkingTag = 'A'      
           AND Status = 0      
           AND DataSeq = @DataSeq      
    END      
     
  
   
    SELECT * FROM #TPDOSPDelv      
        
    
RETURN
GO


