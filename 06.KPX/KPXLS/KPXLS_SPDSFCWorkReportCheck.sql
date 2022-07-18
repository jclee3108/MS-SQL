IF OBJECT_ID('KPXLS_SPDSFCWorkReportCheck') IS NOT NULL 
    DROP PROC KPXLS_SPDSFCWorkReportCheck
GO 

-- v2015.12.03 

-- KPXLS ������ ���� ��� üũ by����õ 
/************************************************************  
��  �� - �������üũ  
�ۼ��� - 2008�� 10�� 22��  
�ۼ��� - ������  
������ - 2010�� 7�� 26��  
������ - ����(�������� ���ΰ� �����Ǵ� ���� ��Ȥ �߻��Ͽ�(�浿�ֶ�) ���� �帧 ������ �ɾ �ش� ������ �������������� �Ǵ���  
UPDATE ::  10.10.25 ��̼� (�۾�����, ����ð� üũ)   
UPDATE ::  11.03.02 �輼ȣ (�ش� ����ǰ�� ��ǰ���ҿ����翡 ��ϵ� ����ǰ��  ��ġ üũ)   
UPDATE ::  11.04.28 ����   (���������ô�������� �������� ��ǰ������ �ʰ��Ͽ� ����� �� ����, �������� ���� ������� ������ ������ �� ����)  
       ::  11.12.19 hkim   (�۾����ù�ȣ�� �ٲ㼭 ������Ʈ �� ��� ���� üũ)  
       ::  11.12.20 �輼ȣ (������Ʈ�������� �ڵ������ǹǷ�  ���� �ȵǵ��� ���� )  
       ::  11.12.22 hkim   (���˻�� �ڵ��԰� ���� �Ŀ�, �˻�ǰ���� �ٲ� �� ������ �� ��� �԰� ���� ���� �����Ǵ� ���� üũ)  
       ::  12.03.18 �輼ȣ (���������̰� ���˻�ǰ�ϰ�� �����˻絥���� �������ִµ�, QCSeq ä�� ����check�󿡼� �̷��������  
                            - test_SPDSFCWorkReportSave ���� QCSeq ä���ɰ�� Ʈ��������� �ߺ�Ű �����߻��Ҽ������Ƿ� )  
       ::  12.04.25 �輼ȣ (�԰����࿩�� üũ �߰� )  
       ::  14.03.31 ����� ȯ�漳�� �߰� <�����ȹ/�������>  ���̳ʽ� ���� ��� ���� �߰��Ͽ� ���̳ʽ� ��� ���� Check  
       ::  14.07.02 ������ ����������� Update,Delete�� �系���ֿ뿪�� ���̺� ������ ���� üũ  
       ::  14.11.18 ����� ȯ�漳�� �߰� <�������>  ������� ���� �� ��������� 0 ���� ���� �ȵǵ��� ��   
       ::  15.03.26 ����� �۾����ð� ���µ�, ��������� ���� �Ǵ� ��찡 ���ܼ� �ش� �κп� ���� Check �� �� �ֵ��� ���� ������ ���� �ľ� �߰�  
************************************************************/  
CREATE PROC KPXLS_SPDSFCWorkReportCheck
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
            @GoodInSeq   INT,  
            @MessageType INT,  
            @Status      INT,  
            @Results     NVARCHAR(250),  
            @EnvValue    NVARCHAR(100),  
            @PrevProcNo  INT,  
            @PrevOKQty   DECIMAL(19, 5),  
            @QCSeq       INT,                -- 12.03.18 �輼ȣ �߰�  
            @QCNo        NCHAR(12)   ,       -- 12.03.18 �輼ȣ �߰�  
            @Env6270     NCHAR(1)   ,  
            @Env6270Text NVARCHAR(500),  
            @Env6273     NCHAR(1),  
            @Env6273Text NVARCHAR(500),  
            @Env6213     NVARCHAR(100)  
  
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TPDSFCWorkReport (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDSFCWorkReport'  
    IF @@ERROR <> 0 RETURN  
    
    --===========================================--  
    -- LotNo �ڵ��ο� üũ 6068003 ( �ڵ����� )  -- 2014.11.21 ����� �Ʒ� �ִ� ȯ�漳�� �κ��� ���� �ø�.  
    --===========================================--  
    EXEC dbo._SCOMEnv @CompanySeq,6213,@UserSeq,@@PROCID,@Env6213 OUTPUT  
      
    
    ------------------------------------------------------------------------------------------------------------
    -- üũ, �������簡 �����Ͽ� ���� �� �� �����ϴ�. �������� ��Һ��� �����Ͻñ� �ٶ��ϴ�. 
    ------------------------------------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '�������簡 �����Ͽ� ���� �� �� �����ϴ�. �������� ��Һ��� �����Ͻñ� �ٶ��ϴ�.', 
           Status = 1234, 
           MessageType = 1234
      FROM #TPDSFCWorkReport AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'D'
       AND EXISTS (SELECT 1 FROM _TPDSFCMatInPut WHERE CompanySeq = @CompanySeq AND WorkReportSeq = A.WorkReportSeq) 
    ------------------------------------------------------------------------------------------------------------
    -- üũ, END 
    ------------------------------------------------------------------------------------------------------------
    
    
    --=======================================================================================================--  
    ----- 2015.03.26 ����� �߰�, �۾����� �����Ͱ� ���µ�, ��������� ���� �Ϸ��� �� ��쿡 ���ؼ� Check -----  
    --=======================================================================================================--  
    IF EXISTS ( SELECT 1   
                  FROM #TPDSFCWorkReport AS A  
                       LEFT OUTER JOIN _TPDSFCWorkOrder AS B WITH(NOLOCK) ON A.WorkOrderSeq  = B.WorkOrderSeq  
                                                                         AND A.WorkOrderSerl = B.WorkOrderSerl  
                                                                         AND B.CompanySeq    = @CompanySeq  
                 WHERE B.WorkOrderSeq IS NULL  
                   AND A.WorkingTag = 'A'  
                   AND A.Status = 0 )  
      
    BEGIN   
  
          EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                @Status      OUTPUT,  
                                @Results     OUTPUT,  
                                2027                 , -- @1��(��) �������� �ʾ� @2��(��) �� �� �����ϴ�.  
                                @LanguageSeq       ,   
        16926, '�۾�����'   ,  
                                17053, '����'  
  
          UPDATE #TPDSFCWorkReport  
             SET Result        = @Results,  
         MessageType   = @MessageType,  
                 Status        = @Status  
            FROM #TPDSFCWorkReport AS A  
                 LEFT OUTER JOIN _TPDSFCWorkOrder AS B WITH(NOLOCK) ON A.WorkOrderSeq  = B.WorkOrderSeq  
                                                                   AND A.WorkOrderSerl = B.WorkOrderSerl  
                                                                   AND B.CompanySeq    = @CompanySeq  
           WHERE B.WorkOrderSeq IS NULL  
             AND A.WorkingTag = 'A'  
             AND A.Status = 0  
    END                                                                               
      
      
    --===================================================================================--  
    ---- <�����ȹ/�������> ���̳ʽ� ���� ��� ���� �߰��Ͽ� ���̳ʽ� ��� ���� Check ---- 2014.03.31 ����� �߰�  
    --===================================================================================--  
    EXEC dbo._SCOMEnv @CompanySeq,6270,@UserSeq,@@PROCID,@Env6270 OUTPUT    
      
    SELECT @Env6270 = ISNULL(@Env6270,'')  
      
      
    SELECT @Env6270Text = ISNULL(Description,'')  
      FROM _TCOMEnv   
     WHERE EnvSeq = 6270  
       AND CompanySeq = @CompanySeq               
  
         
    IF @Env6270 = '1'  
    BEGIN  
          EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                @Status      OUTPUT,  
                                @Results     OUTPUT,  
                                1139                 , -- ȯ�漳������(@1) ���� ��ġ���� �ʽ��ϴ�.  
                                @LanguageSeq       ,   
                                0, @Env6270Text               -- SELECT * FROM _TCADictionary WHERE Word like '%%'  
      
          UPDATE #TPDSFCWorkReport  
             SET Result        = @Results,  
                 MessageType   = @MessageType,  
                 Status        = @Status  
            FROM #TPDSFCWorkReport      AS A  
           WHERE Status = 0  
             AND A.WorkingTag IN ( 'A', 'U' )  
             AND ( A.ProdQty < 0 OR A.OKQty < 0 OR A.BadQty  < 0 )  
  
      
    END   
      
    --=================================================================================--  
    ---- <�������>  ������� ���� �� ��������� 0 ���� ���� �ȵǵ��� �� ȯ�漳�� �߰� -- 2014.11.18 ����� �߰�  
    --=================================================================================--  
  
    EXEC dbo._SCOMEnv @CompanySeq,6273,@UserSeq,@@PROCID,@Env6273 OUTPUT    
      
    SELECT @Env6273 = ISNULL(@Env6273,'')  
      
      
    SELECT @Env6273Text = ISNULL(Description,'')  
      FROM _TCOMEnv   
     WHERE EnvSeq = 6273  
       AND CompanySeq = @CompanySeq  
       
    --======================================================================--  
    ---- ��������� 0�� �ְ� ���� �� ��� ������ �ȵǵ��� Check ���� �߰� ----   
    --======================================================================--  
      
    IF @Env6273 = '1'  
    BEGIN   
      
        IF EXISTS ( SELECT 1 FROM #TPDSFCWorkReport WHERE ProdQty = 0 AND WorkingTag IN ('A','U' ) AND Status = 0 )  
        BEGIN  
             
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  1139                 , -- ȯ�漳������(@1) ���� ��ġ���� �ʽ��ϴ�.  
                                  @LanguageSeq       ,   
                                  0, @Env6273Text               -- SELECT * FROM _TCADictionary WHERE Word like '%%'  
              
            UPDATE #TPDSFCWorkReport  
               SET Result        = @Results     ,  
                   MessageType   = @MessageType ,  
                   Status        = @Status  
              FROM #TPDSFCWorkReport AS A  
          WHERE A.WorkingTag IN ('A','U')  
               AND A.Status = 0  
               AND A.ProdQty = 0   
          
          
        END  
      
    END  
    --------------------------------------------------------------------  
    ---- �۾����۽ð��� �����̽����� ���� �����޼��� ǥ��ǵ��� ����  
      --------------------------------------------------------------------  
    --  EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                        @Status      OUTPUT,  
    --                        @Results     OUTPUT,  
    --                        1363                 , -- @1�� ���ڸ� �Է��� �ֽʽÿ�. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1363)  
    --                        @LanguageSeq       ,   
    --                        8254, ''               -- SELECT * FROM _TCADictionary WHERE Word like '%%'  
    --  UPDATE #TPDSFCWorkReport  
    --     SET Result        = @Results,  
    --         MessageType   = @MessageType,  
    --         Status        = @Status  
    --    FROM #TPDSFCWorkReport      AS A  
    --   WHERE Status = 0  
    --     AND A.WorkStartTime LIKE ' ' + '%' + ' ' + '%' + ' '  
       
  
    --------------------------------------------------------------------  
    ---- �۾�����ð��� �����̽����� ���� �����޼��� ǥ��ǵ��� ����  
    --------------------------------------------------------------------  
    --  EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                        @Status      OUTPUT,  
    --                        @Results     OUTPUT,  
    --                        1363                 , -- @1�� ���ڸ� �Է��� �ֽʽÿ�. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1363)  
    --                        @LanguageSeq       ,   
    --                        8276, ''               -- SELECT * FROM _TCADictionary WHERE Word like '%%'  
    --  UPDATE #TPDSFCWorkReport  
    --     SET Result        = @Results,  
    --         MessageType   = @MessageType,  
    --         Status        = @Status  
    --    FROM #TPDSFCWorkReport      AS A  
    --   WHERE Status = 0  
    --     AND A.WorkEndTime LIKE ' ' + '%' + ' ' + '%' + ' '  
  
  
    ---------------------------------------------------------------------------------------------------------------------------------  
    -- ���������ô�������� �� ������ ��ǰ������ �ʰ��� �� ����, �� ������ ������ ������� ������ ������ �� ���� 2011. 4. 28 hkim  
    ---------------------------------------------------------------------------------------------------------------------------------  
    IF EXISTS (SELECT 1 FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 6230 AND EnvValue = '1')  
    BEGIN                                              
  
  
        -- �� ���� ���� �������� ����  
        SELECT A.ProcNo   
          INTO #ProcNo  
          FROM _TPDSFCWorkOrder         AS A  
               JOIN #TPDSFCWorkReport   AS B ON A.WorkOrderSeq  = B.WorkOrderSeq  
         WHERE A.CompanySeq = @CompanySeq  
      GROUP BY A.ProcNo  
        
        IF (SELECT COUNT(*) FROM #ProcNo) > 1   
        BEGIN  
   
            --�� ���� ��ȣ ��������   
            UPDATE #TPDSFCWorkReport  
               SET PrevProcNo = (SELECT MAX(C.ProcNo) FROM _TPDSFCWorkOrder         AS B   
                                                           JOIN _TPDSFCWorkOrder    AS C ON B.WorkOrderSeq  = C.WorkOrderSeq  
                                                                                        AND B.ProcNo        = C.ToProcNo  
                                                     WHERE B.WorkOrderSeq = A.WorkOrderSeq  
                                                       AND B.WorkOrderSerl = A.WorkOrderSerl   
                                                       AND C.ProcNo <> C.ToProcNo  
                                                       AND B.CompanySeq = @CompanySeq    
                                                       AND C.CompanySeq = @CompanySeq)  
              FROM #TPDSFCWorkReport        AS A  
                   JOIN _TPDSFCWorkOrder    AS B ON A.WorkOrderSeq  = B.WorkOrderSeq  
                                                AND A.WorkOrderSerl = B.WorkOrderSerl  
                   JOIN _TPDSFCWorkOrder    AS C ON B.WorkOrderSeq  = C.WorkOrderSeq  
                                                AND B.ProcNo        = C.ToProcNo  
             WHERE B.CompanySeq = @CompanySeq    
               AND C.CompanySeq = @CompanySeq  
  
            -- �� ���� ���� ��������  
              UPDATE #TPDSFCWorkReport  
               SET PrevOKQty = B.OKQty      
              FROM #TPDSFCWorkReport        AS A    
                   JOIN ( SELECT A.WorkOrderSeq, A.WorkOrderSerl, SUM(C.OKQty) AS OKQty  
                            FROM #TPDSFCWorkReport        AS A  
                                 JOIN _TPDSFCWorkOrder    AS B ON A.WorkOrderSeq  = B.WorkOrderSeq  
                                                              AND A.PrevProcNo    = B.ProcNo  
                                 JOIN _TPDSFCWorkReport   AS C ON B.WorkOrderSeq  = C.WorkOrderSeq  
                                                              AND B.WorkOrderSerl = C.WorkOrderSerl                                              
                           WHERE B.CompanySeq = @CompanySeq  
                             AND C.CompanySeq = @CompanySeq  
                        GROUP BY A.WorkOrderSeq, A.WorkOrderSerl) AS B ON A.WorkOrderSeq  = B.WorkOrderSeq  
                                                                      AND A.WorkOrderSerl = B.WorkOrderSerl  
                                                                    
            -- �� ������ �ְ� �� ���� ������ ���� ���� �� �������� ����϶�� �޽��� ó��  
            IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport       AS A  
                                     JOIN _TPDSFCWorkOrder AS B ON A.WorkOrderSeq = B.WorkOrderSeq  
                                                                AND A.PrevProcNo       = B.ProcNo  
                                     LEFT OUTER JOIN _TPDSFCWorkReport AS C ON B.CompanySeq    = C.CompanySeq  
                                                                           AND B.WorkOrderSeq  = C.WorkOrderSeq  
                                                                           AND B.WorkOrderSerl = C.WorkOrderSerl   
                               WHERE B.CompanySeq = @CompanySeq AND C.WorkReportSeq IS NULL)  
            BEGIN  
                EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                      @Status      OUTPUT,  
                                      @Results     OUTPUT,  
                                      1248                 ,   
                                      @LanguageSeq       ,  
                                      16497,'��������',  
                                      2180,'�������'  
                UPDATE #TPDSFCWorkReport  
                   SET Result       = @Results,  
                       MessageType  = @MessageType,  
                       Status       = @Status  
                  FROM #TPDSFCWorkReport                 AS A  
                                  JOIN _TPDSFCWorkOrder  AS B ON A.WorkOrderSeq = B.WorkOrderSeq  
                                                             AND A.PrevProcNo       = B.ProcNo  
                       LEFT OUTER JOIN _TPDSFCWorkReport AS C ON B.CompanySeq    = C.CompanySeq  
                                                             AND B.WorkOrderSeq  = C.WorkOrderSeq  
                                                             AND B.WorkOrderSerl = C.WorkOrderSerl   
                                                                    
                 WHERE A.WorkingTag IN ('A', 'U')  
                   AND A.Status = 0  
                   AND B.CompanySeq = @CompanySeq  
                   AND C.WorkReportSeq IS NULL    
            END       
                 
            -- �� ������ �ְ� �� ���� ������ �ʰ��� ��� ���� ó��  
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  106                 ,   
                                  @LanguageSeq       ,  
                                  7145,'��ǰ����',  
                                  16497,'��������',  
                                  7145,'��ǰ����'  
            UPDATE #TPDSFCWorkReport  
               SET Result       = @Results,  
                   MessageType  = @MessageType,  
                   Status       = @Status  
                FROM #TPDSFCWorkReport                      
             WHERE WorkingTag IN ('A', 'U')  
               AND Status = 0  
               AND PrevOKQty IS NOT NULL                 
               AND OKQty > PrevOKQty  
                 
            -- ���� ������ ���������Ͱ� �ִµ� ���� �����͸� �����Ϸ��� ���  
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  1006                 ,   
                                  @LanguageSeq       ,  
                                  19339,'�İ���'  
            UPDATE #TPDSFCWorkReport  
               SET Result       = @Results,  
                   MessageType  = @MessageType,  
                   Status       = @Status  
              FROM #TPDSFCWorkReport        AS A  
                   JOIN _TPDSFCWorkOrder    AS B ON A.WorkOrderSeq  = B.WorkOrderSeq  
                                                AND A.WorkOrderSerl = B.WorkOrderSerl  
                   JOIN _TPDSFCWorkOrder    AS C ON B.CompanySeq    = C.CompanySeq  
                                                AND B.WorkOrderSeq  = C.WorkOrderSeq                                                  
                                                AND B.ToProcNo      = C.ProcNo  
                   LEFT OUTER JOIN _TPDSFCWorkReport AS D ON C.CompanySeq    = D.CompanySeq  
                                                         AND C.WorkOrderSeq  = D.WorkOrderSeq  
                                                         AND C.WorkOrderSerl = D.WorkOrderSerl  
             WHERE A.WorkingTag IN ('D')  
               AND B.ProcNo <> B.ToProcNo  
               AND D.WorkReportSeq IS NOT NULL  
               AND A.Status = 0                                                           
              
        END           
    END    
    ---------------------------------------------------------------------------------------------------------------------------------  
    -- ���������ô�������� �� ������ ��ǰ������ �ʰ��� �� ����, �� ������ ������ ������� ������ ������ �� ���� �� 2011. 4. 28 hkim  
    ---------------------------------------------------------------------------------------------------------------------------------  
      
    IF @Env6213 <> '6068003' -- ȯ�漳������ Lot ������ �ڵ����� �� ��쿡�� �Ʒ� ���� Lot�� �ڵ��������� ���ֱ� ������ Check �� ���� �ʵ��� �Ѵ�.  
    BEGIN   
      
     -------------------------------------------  
     -- Lot������ Lot�ʼ�üũ  
     -------------------------------------------  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results     OUTPUT,  
                           1171               , -- �ش�ǰ���� Lot��ȣ ���� ǰ���Դϴ�. Lot��ȣ�� �ʼ��� �Է��ϼ���.(SELECT * FROM _TCAMessage WHERE MessageSeq = 1006)  
                           @LanguageSeq          
  
    UPDATE #TPDSFCWorkReport  
       SET Result       = @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #TPDSFCWorkReport AS A  
           INNER JOIN _TDAItemStock C ON C.CompanySeq = @CompanySeq AND C.ItemSeq = A.AssyItemSeq AND C.IsLotMng = '1'  
     WHERE ISNULL(A.RealLotNo, '') = ''  
       AND IsLastProc   = '1'  
      
    END  
      
     -------------------------------------------  
     -- �ش� ����ǰ�� ��ǰ���ҿ����翡 ��ϵ� ����ǰ��  ��ġ �ϴ���   -- 11.03.02 �輼ȣ �߰�  
     -------------------------------------------  
  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results     OUTPUT,  
                           1170               , -- @1�� @2�� ��ϵǾ� ���� �ʽ��ϴ�.  
                           @LanguageSeq,  
                           11356,'��ǰ���������ҿ�����',  
                           3970,'����ǰ'  
                                                     
  
    UPDATE #TPDSFCWorkReport  
       SET MessageType = @MessageType,  
           Result = @Results,  
           Status = @Status  
       FROM #TPDSFCWorkReport  AS A  
         JOIN _TPDROUItemProcMat AS B ON A.GoodItemSeq = B.ItemSeq                                      AND A.ItemBomRevName = B.BOMRev  
                                   AND A.ProcRev = B.ProcRev  
                                   AND A.ProcSeq = B.ProcSeq  
        WHERE B.CompanySeq = @CompanySeq  
          AND A.Status = 0  
          AND A.AssyItemSeq <> B.AssyItemSeq  
          AND A.WorkingTag IN ('A', 'U')            -- 2011. 8. 29 hkim �����ÿ��� üũ�� �ʿ����   
  
    -------------------------------------------  
    -- �۾����ü��� �ʰ�����üũ  
    -------------------------------------------  
    EXEC dbo._SCOMEnv @CompanySeq,6218,@UserSeq,@@PROCID,@EnvValue OUTPUT  
  
    IF  @EnvValue IN ('1','True')   -- �۾����ü����ʰ��Ұ�  
    BEGIN  
  
        CREATE TABLE #WRQty  
        (  
            WorkOrderSeq        INT,  
            WorkOrderSerl       INT,  
            Qty                 DECIMAL(19,5)  
        )  
  
        CREATE TABLE #WRQtySum  
        (  
            WorkOrderSeq        INT,  
            WorkOrderSerl       INT,  
            Qty                 DECIMAL(19,5),  
            OrdQty              DECIMAL(19,5)  
        )  
  
  
        INSERT #WRQty  
        SELECT A.WorkOrderSeq, A.WorkOrderSerl, A.OKQty  
          FROM _TPDSFCWorkReport    AS A WITH(NOLOCK)  
         WHERE A.CompanySeq = @CompanySeq  
           AND EXISTS(SELECT 1 FROM #TPDSFCWorkReport   
                              WHERE WorkingTag IN ('A','U')  
                                AND Status = 0  
                                AND WorkOrderSeq = A.WorkOrderSeq   
                                AND WorkOrderSerl = A.WorkOrderSerl   
                                AND WorkReportSeq <> A.WorkReportSeq)  
  
  
        INSERT #WRQty  
        SELECT A.WorkOrderSeq, A.WorkOrderSerl, A.OKQty  
          FROM #TPDSFCWorkReport    AS A   
         WHERE A.WorkingTag IN ('A','U')  
           AND A.Status = 0  
  
  
        INSERT #WRQtySum  
        SELECT A.WorkOrderSeq, A.WorkOrderSerl, SUM(A.Qty) , 0  
          FROM #WRQty       AS A   
         GROUP BY A.WorkOrderSeq, A.WorkOrderSerl  
  
  
  
        UPDATE A  
           SET OrdQty = W.OrderQty  
          FROM #WRQtySum            AS A   
            JOIN _TPDSFCWorkOrder   AS W ON A.WorkOrderSeq = W.WorkOrderSeq  
                                        AND A.WorkOrderSerl = W.WorkOrderSerl  
                                        AND W.CompanySeq = @CompanySeq  
  
    -- 2011. 4. 4 hkim �� ȯ�漳���� �Ⱦ�����, �������� �������� ����Ʈ�� ���ؼ� �ش� ȯ�漳���� ������� ��� ���� �޽����� �߸� ��� �� �� �־ �߰�  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           1268               , -- @1�� @2�� ��ϵǾ� ���� �ʽ��ϴ�.    
                           @LanguageSeq,    
                           25598,'�����������',    
                           16930,'�۾������۾�����'    
  
        UPDATE #TPDSFCWorkReport  
           SET Result        = @Results     ,  
               MessageType   = @MessageType ,  
               Status        = @Status  
          FROM #TPDSFCWorkReport AS A  
         WHERE A.WorkingTag IN ('A','U')  
           AND A.Status = 0  
           AND EXISTS(SELECT 1 FROM #WRQtySum WHERE WorkOrderSeq = A.WorkOrderSeq AND WorkOrderSerl = A.WorkOrderSerl AND Qty > OrdQty)  
  
  
    END  
  
    -- ����������� ��ũ���� ���� ���� �ʵ��� ���� 2010. 12. 20 hkim (���ҿ� ���� ����� �ִ�)  
    IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport      AS A  
                             JOIN _TPDSFCWorkReport AS B ON A.WorkReportSeq = B.WorkReportSeq  
                       WHERE A.WorkingTag IN ('U')  
                         AND A.Status = 0  
                         AND B.CompanySeq = @CompanySeq  
                         AND A.WorkCenterSeq <> B.WorkCenterSeq)  
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              19                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                                @LanguageSeq       ,   
                              1059,''     
        UPDATE #TPDSFCWorkReport  
           SET Result       = REPLACE(@Results, '@2', (SELECT Word FROM _TCADictionary WHERE WordSeq = 282 AND LanguageSeq = @LanguageSeq)),  
               MessageType  = @MessageType,  
               Status       = @Status  
          FROM #TPDSFCWorkReport      AS A  
               JOIN _TPDSFCWorkReport AS B ON A.WorkReportSeq = B.WorkReportSeq  
         WHERE A.WorkingTag IN ('U')  
           AND A.Status = 0  
           AND B.CompanySeq = @CompanySeq  
           AND A.WorkCenterSeq <> B.WorkCenterSeq  
    END           
  
    -------------------------------------------  
    -- ���࿩��üũ  
    -------------------------------------------  
  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          1044               , -- ���� �۾��� ����Ǿ ����,������ �� �����ϴ�.  
                          @LanguageSeq  
      
    -- ȯ�漳���� �������� (�������� ������� �ۼ��� �ڵ��԰�ó�� ����  
    EXEC dbo._SCOMEnv @CompanySeq,6202,@UserSeq,@@PROCID,@EnvValue OUTPUT  
  
    IF  @EnvValue IN ('1','True','6069001','6069003') AND EXISTS (SELECT 1 FROM #TPDSFCWorkReport WHERE IsLastProc = '1')  
     BEGIN  
        IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport AS A   
                                 JOIN _TPDBaseWorkCenter AS B ON A.WorkCenterSeq = B.WorkCenterSeq  
                           WHERE B.CompanySeq = @CompanySeq         -- 2011. 3. 7 hkim �����ڵ� �Ȱɷ� �־ ����  
                             AND B.ProdInWhSeq = 0)  
             AND NOT EXISTS (SELECT 1  FROM #TPDSFCWorkReport  AS A  -- 2011. 3. 8 hkim ���� �Ʊ׷� ��û(�ڵ��԰�� ǰ�񺰱⺻â��) ����Ѵٰ� �ؼ�  
                                            JOIN _TDAItemStdWh AS B ON A.GoodItemSeq = B.ItemSeq  
                                      WHERE B.CompanySeq = @CompanySeq AND A.FactUnit = B.FactUnit AND  B.InWHSeq > 0)  
         BEGIN  
            EXEC dbo._SCOMMessage     @MessageType OUTPUT,          
                                      @Status      OUTPUT,          
                                      @Results     OUTPUT,          
                                      1170               , -- @1�� @2�� ��ϵǾ� ���� �ʽ��ϴ�.        
                                      @LanguageSeq       ,           
                                      1059,'��ũ����'    ,          
                                      6451,'�����԰�â��'      
                      
             UPDATE A          
               SET A.Result        = @Results     ,          
                   A.MessageType   = @MessageType ,          
                   A.Status        = @Status          
              FROM #TPDSFCWorkReport AS A   
                   JOIN _TPDBaseWorkCenter AS B ON A.WorkCenterSeq = B.WorkCenterSeq  
              WHERE B.CompanySeq  = @CompanySeq   -- 2011. 3. 7 hkim �����ڵ� �Ȱɷ� �־ ����  
                AND B.ProdInWhSeq = 0    
      AND A.Status = 0     
                AND NOT EXISTS(SELECT 1 FROM _TDAItemStdWh WHERE ItemSeq = A.GoodItemSeq AND FactUnit = A.FactUnit AND  InWHSeq > 0 AND CompanySeq = @CompanySeq)  
  
  
         END         
     END  
  
  
    -------------------------------------------  
    -- �԰���üũ                     -- 12.04.25 BY �輼ȣ  
    -------------------------------------------  
  
    IF @EnvValue  IN ('', '0',  '6069002', '6069003')  -- �԰��� üũ�� ȯ�漳���� '0' �ΰ�쵵 �߰�      -- 12.06.18 BY �輼ȣ  
                                                       -- (ȯ�漳�� �������ð� �״�� ����Ұ�� '0'���� �������⶧����)  
     BEGIN  
  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1044               , -- ���� �۾��� ����Ǿ ����,������ �� �����ϴ�.  
                              @LanguageSeq      
  
  
        IF @EnvValue = '6069003'    -- ����ǰ�� �ڵ��԰� �� ��� ����ǰ�� ���࿩�θ� üũ���� �ʴ´�.   
        BEGIN   
            UPDATE A   
               SET Result        = @Results     ,  
MessageType   = @MessageType ,  
                   Status        = @Status  
            FROM #TPDSFCWorkReport AS A   
            JOIN _TPDSFCGoodIn     AS B ON A.WorkReportSeq = B. WorkReportSeq  
                                       AND @CompanySeq = B.CompanySeq  
            JOIN _TDAItem           AS I ON A.GoodItemSeq = I.ItemSeq  
            JOIN _TDAItemAsset      AS S ON I.AssetSeq = S.AssetSeq  
                                        AND I.CompanySeq = S.CompanySeq                      
            WHERE Status = 0   
              AND WorkingTag IN ('U', 'D')  
              AND I.CompanySeq = @CompanySeq  
              AND S.SMAssetGrp <> 6008004  
        END  
  
        ELSE  
        BEGIN  
            UPDATE A   
               SET Result        = @Results     ,  
                   MessageType   = @MessageType ,  
                   Status        = @Status  
            FROM #TPDSFCWorkReport AS A   
            JOIN _TPDSFCGoodIn     AS B ON A.WorkReportSeq = B. WorkReportSeq  
                                       AND @CompanySeq = B.CompanySeq  
            WHERE Status = 0   
              AND WorkingTag IN ('U', 'D')  
  
        END  
  
  
  
     END  
  
  
--    IF  @EnvValue NOT IN ('1','True','6069001')   -- �������� ������� �ۼ��� �ڵ��԰�ó�� ����  
--    BEGIN  
--  
--        EXEC dbo._SCOMProgressCheck     @CompanySeq             ,  
--                                        '_TPDSFCWorkReport'      ,  
--                                        1                       ,  
--                                        '#TPDSFCWorkReport'      ,  
--                                        'WorkReportSeq'          ,  
--                                        ''         ,  
--                                        ''                      ,  
--                                        'Status'  
--  
--        IF @EnvValue = '6069003'    -- ����ǰ�� �ڵ��԰� �� ��� ����ǰ�� ���࿩�θ� üũ���� �ʴ´�.   
--        BEGIN   
--  
--            UPDATE #TPDSFCWorkReport  
--               SET Status        = 0  
--              FROM #TPDSFCWorkReport    AS A  
--                JOIN _TDAItem           AS I ON A.GoodItemSeq = I.ItemSeq  
--                JOIN _TDAItemAsset      AS S ON I.AssetSeq = S.AssetSeq  
--             WHERE A.WorkingTag IN ('U','D')  
--               AND A.Status = 1  
--               AND I.CompanySeq = @CompanySeq  
--               AND S.CompanySeq = @CompanySeq  
--               AND S.SMAssetGrp = 6008004  
--  
--  
--        END   
--  
--  
--        UPDATE #TPDSFCWorkReport  
--           SET Result        = @Results     ,  
--               MessageType   = @MessageType ,  
--               Status        = @Status  
--          FROM #TPDSFCWorkReport AS A  
--         WHERE A.WorkingTag IN ('U','D')  
--           AND A.Status = 1  
--  
--    END  
  
  
    -------------------------------------------  
    -- �˻翩��üũ (�˻簡 ���࿬���� �� �� �����.)  
    -------------------------------------------  
 IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport   AS A  
           JOIN _TPDQCTestReport   AS B ON A.WorkReportSeq = B.SourceSeq  
                      AND B.CompanySeq = @CompanySeq  
             AND B.SourceType IN ('3')   -- 3: ����, 4: �����˻�  
                             JOIN _TPDBaseItemQCType AS C ON A.GoodItemSeq = C.ItemSeq  
                                                    AND C.CompanySeq = @CompanySeq  
     WHERE A.WorkingTag IN ('U','D')  
       AND A.Status = 0  
       AND A.IsLastProc = '1'   
       AND C.IsLastQc = '1')  
 BEGIN      
  EXEC dbo._SCOMMessage @MessageType OUTPUT,  
         @Status      OUTPUT,  
         @Results     OUTPUT,  
         1006               , -- @1��(��) @2�� @3��(��) �ʰ��� �� �����ϴ�.  
         @LanguageSeq,  
         9410 , '�����˻�'  
  
  UPDATE #TPDSFCWorkReport  
     SET Result        = @Results     ,  
      MessageType   = @MessageType ,  
      Status        = @Status  
    FROM #TPDSFCWorkReport    AS A  
   JOIN _TPDQCTestReport   AS B ON A.WorkReportSeq = B.SourceSeq  
          AND B.CompanySeq = @CompanySeq  
          AND B.SourceType IN ('3')   -- 3: ����, 4: �����˻�  
   WHERE A.WorkingTag IN ('U','D')  
     AND A.Status = 0  
 END       
  
 IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport   AS A  
           JOIN _TPDQCTestReport   AS B ON A.WorkReportSeq = B.SourceSeq  
                      AND B.CompanySeq = @CompanySeq  
             AND B.SourceType IN ('4')   -- 3: ����, 4: �����˻�  
     WHERE A.WorkingTag IN ('U','D')  
       AND A.Status = 0)  
 BEGIN  
  EXEC dbo._SCOMMessage @MessageType OUTPUT,  
         @Status      OUTPUT,  
         @Results     OUTPUT,  
         1006               , -- @1��(��) @2�� @3��(��) �ʰ��� �� �����ϴ�.  
         @LanguageSeq,  
         3965 , '�����˻�'  
  
  UPDATE #TPDSFCWorkReport  
     SET Result        = @Results     ,  
      MessageType   = @MessageType ,  
      Status        = @Status  
    FROM #TPDSFCWorkReport    AS A  
   JOIN _TPDQCTestReport   AS B ON A.WorkReportSeq = B.SourceSeq  
          AND B.CompanySeq = @CompanySeq  
          AND B.SourceType IN ('4')   -- 3: ����, 4: �����˻�  
   WHERE A.WorkingTag IN ('U','D')  
     AND A.Status = 0  
 END       
  
  
  
  
 ------------------------------------------------------------------  
 -- �������� ���� �����Ǵ� �� ������ üũ���� �߰� 2010. 7. 26 hkim  
 -- �ش� �������� �����帧�̳� ��ǰ�������� �����������ΰ� üũ�Ǿ� ������ ���� �����ʹ� üũ �Ǿ� ���� ���� ���  
 ------------------------------------------------------------------  
 -- �����帧���� ����ϴ� ���  
 IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport   AS A  
        JOIN _TPDROUItemProcRev AS B ON A.GoodItemSeq = B.ItemSeq  
               AND A.ProcRev   = B.ProcRev  
        JOIN _TPDProcTypeItem  AS C ON B.CompanySeq  = C.CompanySeq  
               AND B.ProcTypeSeq = C.ProcTypeSeq  
               AND A.ProcSeq   = C.ProcSeq  
        WHERE B.CompanySeq = @CompanySeq  
          AND A.IsLastProc <> '1'  
          AND C.IsLastProc = '1'  
          AND A.WorkingTag IN ('A', 'U')  
          AND A.Status   = 0)  
 BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1196               , -- @1�� ����� ������ �����Ƿ� ����/������ �� �����ϴ�. SELECT * FROM _TCAMessageLanguage WHERE Message like '%����%'  
                              @LanguageSeq,  
                              0 , '������������'  -- SELect * from _TCADictionary where Word like '����%'  
        UPDATE #TPDSFCWorkReport  
           SET Result        = @Results     ,  
               MessageType   = @MessageType ,  
               Status        = @Status  
          FROM #TPDSFCWorkReport    AS A  
      JOIN _TPDROUItemProcRev AS B ON A.GoodItemSeq = B.ItemSeq  
           AND A.ProcRev   = B.ProcRev  
      JOIN _TPDProcTypeItem AS C ON B.CompanySeq  = C.CompanySeq  
           AND B.ProcTypeSeq = C.ProcTypeSeq  
           AND A.ProcSeq   = C.ProcSeq  
   WHERE B.CompanySeq = @CompanySeq  
     AND A.IsLastProc <> '1'  
     AND C.IsLastProc = '1'  
     AND A.WorkingTag IN ('A', 'U')  
     AND A.Status   = 0  
 END    
 -- ��ǰ�� ���� ����ϴ� ���  
 ELSE IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport   AS A  
        JOIN _TPDROUItemProc  AS B ON A.GoodItemSeq = B.ItemSeq  
               AND A.ProcRev   = B.ProcRev  
               AND A.ProcSeq   = B.ProcSeq  
        WHERE B.CompanySeq = @CompanySeq  
          AND A.IsLastProc <> '1'  
          AND B.IsLastProc = '1'  
          AND A.WorkingTag IN ('A', 'U')  
          AND A.Status   = 0)  
 BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1196               , -- @1�� ����� ������ �����Ƿ� ����/������ �� �����ϴ�. SELECT * FROM _TCAMessageLanguage WHERE Message like '%����%'  
                              @LanguageSeq,  
                              0 , '������������'  -- SELect * from _TCADictionary where Word like '����%'  
        UPDATE #TPDSFCWorkReport  
           SET Result        = @Results     ,  
               MessageType   = @MessageType ,  
               Status        = @Status  
          FROM #TPDSFCWorkReport  AS A  
        JOIN _TPDROUItemProc  AS B ON A.GoodItemSeq = B.ItemSeq  
           AND A.ProcRev   = B.ProcRev  
           AND A.ProcSeq   = B.ProcSeq  
   WHERE B.CompanySeq = @CompanySeq  
     AND A.IsLastProc <> '1'  
     AND B.IsLastProc = '1'  
     AND A.WorkingTag IN ('A', 'U')  
     AND A.Status   = 0  
 END                           
 ------------------------------------------------------------------  
 -- �������� ���� �����Ǵ� �� ������ üũ���� �߰� 2010. 7. 26 hkim  
 -- �ش� �������� �����帧�� �����������ΰ� üũ�Ǿ� ������ ���� �����ʹ� üũ �Ǿ� ���� ���� ���  
 -- �߰� ���� �� --  
 ------------------------------------------------------------------  
  
  
    ------------------------------------------------------------------    
    -- ������Ʈ���ϰ��(�ڵ������Ǵ°���) ���� �Ұ��ϵ��� �߰�       2011.12.20 BY �輼ȣ   
    ------------------------------------------------------------------    
    IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport WHERE IsPjt = '1' AND Status = 0)    
    BEGIN    
        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                              @Status      OUTPUT,    
                              @Results     OUTPUT,    
                              1307                , -- @1�� ��� @2��(��) �� �� �����ϴ�.  
                              @LanguageSeq,    
                              353 , '',          -- ������Ʈ   
                              13823 , ''          -- ����   
  
        UPDATE #TPDSFCWorkReport    
           SET Result        = @Results     ,    
               MessageType   = @MessageType ,    
               Status        = @Status    
          FROM #TPDSFCWorkReport    
        WHERE IsPjt = '1'   
          AND Status = 0  
          AND @PgmSeq IN (200125, 1015) -- ���ں���������ȸ ��ȸ���� ������Ʈ�� �����ν� '��������Է�' ȭ������ �����Ǳ⶧����   
                                        -- ������Ʈ���� '��������Է�' ȭ��󿡼� ���� �ȵǵ��� ���´�      -- 12.03.29 BY �輼ȣ  
  
  
    END    
  
 ------------------------------------------------------------------  
 -- ��Ȥ �μ�, ����� �����Ǵ� ��찡 �־� üũ���� �߰� 2010. 10. 13 hkim  
 ------------------------------------------------------------------  
 IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport WHERE (DeptSeq = 0 OR DeptSeq IS NULL) AND WorkingTag IN ('A', 'U') AND Status = 0)  
 BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              133                , -- @1�� ����� ������ �����Ƿ� ����/������ �� �����ϴ�. SELECT * FROM _TCAMessageLanguage WHERE Message like '%����%'  
                              @LanguageSeq,  
                              0 , ''  -- SELect * from _TCADictionary where Word like '����%'  
        UPDATE #TPDSFCWorkReport  
           SET Result        = @Results     ,  
               MessageType   = @MessageType ,  
               Status        = @Status  
          FROM #TPDSFCWorkReport  AS A  
   WHERE (A.DeptSeq = 0 OR A.DeptSeq IS NULL )  
     AND A.WorkingTag IN ('A', 'U')  
           AND A.Status = 0  
 END     
   
  
    -- #################################################################################################################################  
    -- ������ ��� �Ŀ�, �۾����ù�ȣ�� �ڵ嵵������ �ٸ� �۾����÷� �ٲ㼭 ������Ʈ �ϴ� ��쵵 �־, ����ó�� �߰� 2011. 12. 19 hkim  
    IF EXISTS (SELECT 1 FROM _TPDSFCWorkReport      AS A  
                             JOIN #TPDSFCWorkReport AS B ON A.WorkReportSeq = B.WorkReportSeq  
                       WHERE A.CompanySeq = @CompanySeq  
                         AND B.WorkingTag IN ('U')  
                         AND B.Status = 0  
                         AND (A.WorkOrderSeq <> B.WorkOrderSeq OR (A.WorkOrderSeq = B.WorkOrderSeq AND A.WorkOrderSerl <> B.WorkOrderSerl) ) )  
    BEGIN   
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1307               , -- @1�� ����� ������ �����Ƿ� ����/������ �� �����ϴ�. SELECT * FROM _TCAMessageLanguage WHERE Message like '%����%'  
                              @LanguageSeq,  
                                1985 , '�۾����ù�ȣ' ,  -- SELect * from _TCADictionary where Word  like '�۾����ù�ȣ%'  
                              13823 , '����'   
        UPDATE #TPDSFCWorkReport  
           SET Result        = @Results     ,  
               MessageType   = @MessageType ,  
               Status        = @Status  
          FROM #TPDSFCWorkReport  AS A  
               JOIN _TPDSFCWorkReport   AS B ON A.WorkReportSeq = B.WorkReportSeq  
   WHERE A.WorkingTag IN ('U')  
     AND B.CompanySeq = @CompanySeq  
     AND A.Status = 0  
           AND (A.WorkOrderSeq <> B.WorkOrderSeq OR (A.WorkOrderSeq = B.WorkOrderSeq AND A.WorkOrderSerl <> B.WorkOrderSerl) )  
    END                           
                                                        
  
    -- #################################################################################################################################  
  
-- ���˻�ǰ���� �������� ���� ������ �����˻絥���� �ڵ����� �������ָ鼭 �ϱ� üũ ���� �ּ�ó��       -- 12.03.19 BY �輼ȣ  
--    -- #################################################################################################################################  
--    --���˻�ǰ���� �ڵ��԰� ���� �� �Ŀ� �˻�ǰ���� ���� ������ �԰����� ���� ���� �����Ǵ� ���� üũ 2011. 12. 22 hkim  
--    IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport                  AS A  
--                                        JOIN _TPDBaseItemQCType AS D ON A.GoodItemSeq   = D.ItemSeq AND D.CompanySeq = @CompanySeq AND D.IsLastQC = '1'  
--                             LEFT OUTER JOIN _TPDSFCGoodIn      AS B ON A.WorkReportSeq = B.WorkReportSeq AND B.CompanySeq = @CompanySeq  
--                             LEFT OUTER JOIN _TPDQCTestReport   AS C ON A.WorkReportSeq = C.SourceSeq AND C.SourceType = '3' AND C.CompanySeq = @CompanySeq  
--                       WHERE A.WorkingTag IN ('D')  
--                         AND A.Status = 0  
--                         AND B.GoodInSeq IS NOT NULL   
--                         AND C.QCSeq IS NULL)   
--        AND @EnvValue IN ('1','True','6069001','6069003')    
--    BEGIN  
--        DECLARE @ResultLast NVARCHAR(MAX)  
--        SELECT @ResultLast = ''  
--          
--        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
--                              @Status      OUTPUT,  
--                              @Results     OUTPUT,  
--                              1330               , -- @1�� ����� ������ �����Ƿ� ����/������ �� �����ϴ�. SELECT * FROM _TCAMessageLanguage WHERE Message like '%����%'  
--                              @LanguageSeq,  
--                              0 , ''   -- SELect * from _TCADictionary where Word like '�˻�%'  
--          
--        --SELECT @ResultLast = @ResultLast +  @Results  
--                                       
--        UPDATE #TPDSFCWorkReport  
--           SET Result        = @Results, --'�ڵ��԰��̰�, �˻�ǰ���� �����˻絥���� ����, �԰����Ͱ� �����Ƿ� ������ �� �����ϴ�.'     ,  
--               MessageType   = @MessageType ,  
--               Status        = @Status  
--          FROM #TPDSFCWorkReport  AS A  
--               JOIN _TPDSFCWorkReport   AS B ON A.WorkReportSeq = B.WorkReportSeq  
--   WHERE A.WorkingTag IN ('D')  
--     AND B.CompanySeq = @CompanySeq  
--     AND A.Status = 0  
--   
--    END   
--    --#################################################################################################################################  
  
--    -- #################################################################################################################################  
--    --�˻�ǰ���� �ڵ��԰� ���� �� �Ŀ� ���˻�ǰ���� ���� ������ �˻絥���� ���� ����,�԰� �����Ǵ� ���� üũ 2011. 12. 22 hkim  
--    IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport                  AS A  
--                                        JOIN _TPDBaseItemQCType AS D ON A.GoodItemSeq   = D.ItemSeq AND D.CompanySeq = @CompanySeq AND D.IsLastQC = '0'  
--                             LEFT OUTER JOIN _TPDSFCGoodIn      AS B ON A.WorkReportSeq = B.WorkReportSeq AND B.CompanySeq = @CompanySeq  
--                             LEFT OUTER JOIN _TPDQCTestReport   AS C ON A.WorkReportSeq = C.SourceSeq AND C.SourceType = '3' AND C.CompanySeq = @CompanySeq  
--                       WHERE A.WorkingTag IN ('D')  
  --                          AND A.Status = 0  
--                         AND B.GoodInSeq IS NOT NULL   
--                         AND C.QCSeq IS NOT NULL)   
--        AND @EnvValue IN ('1','True','6069001','6069003')    
--    BEGIN  
--        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
--                              @Status      OUTPUT,  
--                              @Results     OUTPUT,  
--                              1331               , -- @1�� ����� ������ �����Ƿ� ����/������ �� �����ϴ�. SELECT * FROM _TCAMessageLanguage WHERE Message like '%����%'  
--                              @LanguageSeq,  
--                              0 , ''   -- SELect * from _TCADictionary where Word like '�˻�%'  
--          
--        --SELECT @ResultLast = @ResultLast +  @Results  
--                                       
--        UPDATE #TPDSFCWorkReport  
--           SET Result        = @Results, --'�ڵ��԰��̰�, �����˻� ������ �ִµ�, ���˻�ǰ���� ���������Ƿ� ������ �� �����ϴ�.'     ,  
--               MessageType   = @MessageType ,  
--               Status        = @Status  
--          FROM #TPDSFCWorkReport  AS A  
--               JOIN _TPDSFCWorkReport   AS B ON A.WorkReportSeq = B.WorkReportSeq  
--   WHERE A.WorkingTag IN ('D')  
--     AND B.CompanySeq = @CompanySeq  
--     AND A.Status = 0  
--   
--    END   
--    --#################################################################################################################################  
  
      
--    -------------------------------------------  
--    -- ���������� ���Ե� ����ǰ�� ���������� �� �� ����.   
--    -------------------------------------------  
--  
--  
--    UPDATE #TPDSFCWorkReport  
--       SET Result        = @Results     ,  
--           MessageType   = @MessageType ,  
--           Status        = @Status  
--      FROM #TPDSFCWorkReport AS A  
--     WHERE A.WorkingTag IN ('U','D')  
--       AND A.Status = 0  
--       AND EXISTS (SELECT 1 FROM _TPDSFCMatinput    AS M WITH(NOLOCK)  
--                            JOIN _TPDSFCWorkReport  AS R WITH(NOLOCK) ON M.CompanySeq = R.CompanySeq  
--                                                                     AND M.WorkReportSeq = R.WorkReportSeq  
--                       WHERE M.CompanySeq   = @CompanySeq   
--                             AND R.WorkOrderSeq = A.WorkOrderSeq  
--                             AND M.MatItemSeq   = A.AssyItemSeq )  
  
  
    ----======================================================================--  
    ------ ��������� 0�� �ְ� ���� �� ��� ������ �ȵǵ��� Check ���� �߰� ---- 2014.01.10 ����� �߰�  
    ----======================================================================--  
      
    --IF EXISTS ( SELECT 1 FROM #TPDSFCWorkReport WHERE ProdQty = 0 AND WorkingTag IN ('A','U' ) AND Status = 0 )  
    --BEGIN  
         
    --    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                          @Status      OUTPUT,  
    --                          @Results     OUTPUT,  
    --                          1331               , -- @1�� ����� ������ �����Ƿ� ����/������ ��   
    --                          @LanguageSeq,  
    --                          0 , ''   --   
          
    --    UPDATE #TPDSFCWorkReport  
    --       SET Result        = '��������� 0 ���� �Է� �� �� �����ϴ�. ��������� Ȯ���ϼ���.'     ,  
    --           MessageType   = @MessageType ,  
    --           Status        = @Status  
    --      FROM #TPDSFCWorkReport AS A  
    --     WHERE A.WorkingTag IN ('A','U')  
    --       AND A.Status = 0  
    --       AND A.ProdQty = 0   
      
      
    --END  
  
    -------------------------------------------  
    -- LotNo �ڵ��ο� üũ 6068003    
    -------------------------------------------  
  
    DECLARE @DataSeq    INT ,  
            @Date       NCHAR(8),  
            @FactUnit   INT ,  
            @MaxNo      NVARCHAR(20)  
    IF @Env6213 = '6068003'  
    BEGIN  
        SELECT @DataSeq = 0  
  
        WHILE (1=1)  
        BEGIN  
  
            SELECT TOP 1 @DataSeq = DataSeq,  
                         @Date = WorkDate,  
                         @FactUnit = FactUnit  
              FROM #TPDSFCWorkReport   
               WHERE  DataSeq      > @DataSeq  
               AND WorkingTag   = 'A'  
               AND Status       = 0  
               AND RealLotNo    = ''  
             ORDER BY DataSeq  
  
            IF @@ROWCOUNT = 0   
                BREAK  
  
            EXEC   dbo._SCOMCreateNo    'PD'                , -- ����(HR/AC/SL/PD/ESM/PMS/SI/SITE)  
                                        '_TPDSFCWorkReport' , -- ���̺�  
                                        @CompanySeq         , -- �����ڵ�  
                                        @FactUnit           , -- �ι��ڵ�  
                                        @Date               ,  -- �����  
                                        @MaxNo OUTPUT  
  
            UPDATE #TPDSFCWorkReport  
               SET RealLotNo = @MaxNo  
             WHERE DataSeq = @DataSeq  
  
        END  
    END   
  
    -------------------------------------------  
    -- �����帧���������� ���� ��� ����Ʈ '00' (���� ���ϴ� ���� ���� ����)  
    -------------------------------------------  
    UPDATE #TPDSFCWorkReport  
       SET ProcRev = '00'  
     WHERE ProcRev = ''  
  
    -------------------------------------------  
    -- ���ֿ뿪�� ��ǥ ���� ����  
    -------------------------------------------  
--    DECLARE @EnvValue NCHAR(1)  
--    SELECT @EnvValue = EnvValue from _TCOMEnv where EnvSeq = 6513 AND CompanySeq = @CompanySeq  
    EXEC dbo._SCOMEnv @CompanySeq,6513,@UserSeq,@@PROCID,@EnvValue OUTPUT  
  
    -- '1' �����԰����, '0' �����������  
    IF @EnvValue = '0'   
    BEGIN  
  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1109               , -- @1�� ����� ������ �����Ƿ� ����/������ �� �����ϴ�. SELECT * FROM _TCAMessageLanguage WHERE Message like '%����%'  
                              @LanguageSeq,  
                              0 , '���ֿ뿪����ǥ'  -- SELect * from _TCADictionary where Word like '����%'  
  
        UPDATE #TPDSFCWorkReport  
           SET Result        = @Results     ,  
               MessageType   = @MessageType ,  
               Status        = @Status  
          FROM #TPDSFCWorkReport    AS A  
            JOIN _TPDSFCOutsourcingCostItem   AS B ON A.WorkReportSeq = B.WorkReportSeq  
                                                  AND B.CompanySeq = @CompanySeq  
                                                  AND B.SlipSeq > 0  
                                          
         WHERE A.WorkingTag IN ('U','D')  
           AND A.Status = 0  
    END  
      
    -------------------------------------------    
    -- ����������� Update,Delete�� �系���ֿ뿪�� ���̺� ������ ���� üũ         --2014.07.02 hjlim �߰�  
    -------------------------------------------    
    -- '1' �����԰����, '0' �����������    
    IF @EnvValue = '0'     
    BEGIN    
    
        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                              @Status      OUTPUT,    
                              @Results     OUTPUT,    
                              1109               , -- @1�� ����� ������ �����Ƿ� ����/������ �� �����ϴ�. SELECT * FROM _TCAMessageLanguage WHERE Message like '%����%'    
                              @LanguageSeq,    
                              1165, '���̺�'  -- SELect * from _TCADictionary where Word like '%���̺�%'    
    
        UPDATE #TPDSFCWorkReport    
           SET Result        = @Results     ,    
               MessageType   = @MessageType ,    
               Status        = @Status    
          FROM #TPDSFCWorkReport    AS A                                       
         WHERE A.WorkingTag IN ('U','D')    
           AND A.Status = 0    
           AND EXISTS ( SELECT 1 FROM _TPDSFCOutsourcingCostItem WHERE CompanySeq    = @CompanySeq   
                                                                   AND WorkReportSeq = A.WorkReportSeq  
                                                                   AND SlipSeq       = 0 )  
    END    
  
    ---------------------------------------------  
    ---- ���������� �ð� üũ(00:00~24:00 ����)  
    ---------------------------------------------  
  
      --    --�۾����۽ð� ����!      --    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                          @Status      OUTPUT,  
    --                          @Results     OUTPUT,  
    --                          1196               , -- @1�� ����� ������ �����Ƿ� ����/������ �� �����ϴ�. SELECT * FROM _TCAMessageLanguage WHERE Message like '%Ȯ��%'  
    --                          @LanguageSeq,  
    --                          8254 , '�۾����۽ð�'  -- SELect * from _TCADictionary where Word like '�۾�%�ð�'  
  
    --    UPDATE #TPDSFCWorkReport  
    --       SET Result        = @Results     ,  
    --           MessageType   = @MessageType ,  
    --           Status        = @Status  
    --      FROM #TPDSFCWorkReport    AS A  
                                          
    --     WHERE A.WorkingTag IN ('U','D','A')  
    --       AND A.Status = 0  
    --       AND (LEFT(CONVERT(INT, WorkStartTime), 2) >= 24 OR RIGHT(CONVERT(INT, WorkStartTime), 2) >= 60)  
          
    --    --�۾�����ð� ����!      
    --    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                          @Status      OUTPUT,  
    --                          @Results     OUTPUT,  
    --                          1196               , -- @1�� ����� ������ �����Ƿ� ����/������ �� �����ϴ�. SELECT * FROM _TCAMessageLanguage WHERE Message like '%Ȯ��%'  
    --                          @LanguageSeq,  
    --                          8276 , '�۾�����ð�'  -- SELect * from _TCADictionary where Word like '�۾�%�ð�'  
  
    --    UPDATE #TPDSFCWorkReport  
    --       SET Result        = @Results     ,  
    --           MessageType   = @MessageType ,  
    --           Status        = @Status  
    --      FROM #TPDSFCWorkReport    AS A  
                                          
    --     WHERE A.WorkingTag IN ('U','D','A')  
    --       AND A.Status = 0  
   --       AND (LEFT(CONVERT(INT, WorkEndTime), 2) >= 24 OR RIGHT(CONVERT(INT, WorkEndTime), 2) >= 60)  
  
  
  
--    -------------------------------------------  
--    -- ���������̰�, ���˻�ǰ�̸� ��������� QC������ �������ִµ�,   
--    -- �˻�Seq, No ����üũSP�󿡼� ä�����ش�(test_SPDSFCWorkReportSave���� ä���Ұ�� Ʈ����ǹ���������)     -- 12.03.14 BY �輼ȣ  
--    -------------------------------------------  
--  
--    IF EXISTS( SELECT 1 FROM #TPDSFCWorkReport  AS A  
--                        JOIN _TPDBaseItemQCType AS B ON A.GoodItemSeq = B.ItemSeq  
--                                                    AND B.CompanySeq = @CompanySeq  
--                        WHERE A.IsLastProc = '1' AND B.IsLastQc <> '1' AND A.Status = 0 AND A.WorkingTag = 'A')  
--      BEGIN  
--  
--  
--      END  
    -------------------------------------------  
    -- INSERT ��ȣ�ο�(�� ������ ó��)  
    -------------------------------------------  
    SELECT @Count = COUNT(1) FROM #TPDSFCWorkReport WHERE WorkingTag = 'A' --@Count������(AND Status = 0 ����)  
    IF @Count > 0  
    BEGIN  
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TPDSFCWorkReport', 'WorkReportSeq', @Count  
  
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #TPDSFCWorkReport  
           SET WorkReportSeq   = @Seq + DataSeq  
         WHERE WorkingTag   = 'A'  
           AND Status       = 0  
  
        -- �ڵ��԰� �����ؼ� ����� ��� GoodInSeq�� test_SPDSFCWorkReportSave �ȿ� _SPDSFCGoodInCheck���� ä������ �ʵ��� �ϱ� ���ؼ� ���⼭���� ä�����ش� 2011. 8. 2. hkim  
        --IF EXISTS (SELECT 1 FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 6202 AND EnvValue IN (6069001, 6069003) )  
        --BEGIN --�ڹ��� MES���������� �ش� ȯ�漳�� ���� ���� ä�� �Ǵ� �κ� ����  
            EXEC @GoodInSeq = dbo._SCOMCreateSeq @CompanySeq, '_TPDSFCGoodIn', 'GoodInSeq', @Count  
              
             UPDATE #TPDSFCWorkReport  
               SET GoodInSeq   = @GoodInSeq + DataSeq  
             WHERE WorkingTag   = 'A'  
               AND Status       = 0   
        --END  
  
  
        -- �������� ���˻�ǰ�ϰ��, �����˻絥���� �������ִµ�, QCSeq ����üũ SP�󿡼� ���ֱ����� �߰�      -- 12.03.18 �輼ȣ �߰�  
        IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport                  AS A  
                              LEFT OUTER JOIN _TPDBaseItemQCType AS D ON A.GoodItemSeq   = D.ItemSeq AND D.CompanySeq = @CompanySeq    
                            WHERE A.WorkingTag = 'A'  
                            AND A.Status = 0  
                            AND A.IsLastProc = '1'  
                            AND ISNULL(D.IsLastQC, '0') = '0')  
         BEGIN  
  
              SELECT @DataSeq = 0  
              SELECT TOP 1 @Date = WorkDate FROM #TPDSFCWorkReport   
              
              EXEC @QCSeq = dbo._SCOMCreateSeq @CompanySeq, '_TPDQCTestReport', 'QCSeq', @Count     
  
              -- ��������Է½� ���˻�ǰ- �������� ���� �������� �� �����Ƿ� loop���鼭 ä��   
              WHILE( 1 > 0)     
              BEGIN    
                   SELECT TOP 1 @DataSeq = DataSeq        
                    FROM #TPDSFCWorkReport            
                    WHERE  WorkingTag = 'A'            
                       AND Status = 0            
                       AND DataSeq > @DataSeq            
                     ORDER BY DataSeq            
            
                      IF @@ROWCOUNT = 0 BREAK          
  
                   EXEC dbo._SCOMCreateNo 'PD', '_TPDQCTestReport', @CompanySeq, '', @Date, @QCNo OUTPUT    
  
                   UPDATE #TPDSFCWorkReport    
                      SET QCSeq = @QCSeq + DataSeq, -- �������� ���� ��� While�� ���鼭 �Ѱǽ� ó���ϱ� ������ 1�� ������    
                       QCNo  = @QCNo    
                    WHERE WorkingTag = 'A'    
                      AND Status  = 0    
                      AND DataSeq = @DataSeq     
                      
              END   
          END  
  
    END  
      
  
  
    SELECT * FROM #TPDSFCWorkReport  
    RETURN  
/*******************************************************************************************************************/
GO

begin tran
exec KPXLS_SPDSFCWorkReportCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ItemBomRevName>00</ItemBomRevName>
    <ProdQty>999999</ProdQty>
    <OKQty>999999</OKQty>
    <BadQty>0</BadQty>
    <ReOrderQty>0</ReOrderQty>
    <LossCostQty>0</LossCostQty>
    <DisuseQty>0</DisuseQty>
    <WorkStartTime />
    <WorkEndTime />
    <WorkHour>0</WorkHour>
    <ProcHour>0</ProcHour>
    <WorkerQty>0</WorkerQty>
    <RealLotNo>�����</RealLotNo>
    <SerialNoFrom />
    <SerialNoTo />
    <WorkCondition1>20151130</WorkCondition1>
    <WorkCondition2 />
    <WorkCondition3 />
    <WorkCondition4>0</WorkCondition4>
    <WorkCondition5>0</WorkCondition5>
    <WorkCondition6>0</WorkCondition6>
    <StdUnitReOrderQty>0</StdUnitReOrderQty>
    <StdUnitLossCostQty>0</StdUnitLossCostQty>
    <StdUnitDisuseQty>0</StdUnitDisuseQty>
    <Remark />
    <ProcRev>00</ProcRev>
    <WorkReportSeq>31</WorkReportSeq>
    <WorkOrderSeq>45</WorkOrderSeq>
    <WorkCenterSeq>38</WorkCenterSeq>
    <GoodItemSeq>4808</GoodItemSeq>
    <AssyItemSeq>4808</AssyItemSeq>
    <ProcSeq>13</ProcSeq>
    <ProdUnitSeq>1</ProdUnitSeq>
    <ChainGoodsSeq>0</ChainGoodsSeq>
    <EmpSeq>0</EmpSeq>
    <WorkOrderSerl>46</WorkOrderSerl>
    <IsProcQC>0</IsProcQC>
    <IsLastProc>1</IsLastProc>
    <IsPjt>0</IsPjt>
    <PJTSeq>0</PJTSeq>
    <WBSSeq>0</WBSSeq>
    <SubEtcInSeq>0</SubEtcInSeq>
    <WorkTimeGroup>0</WorkTimeGroup>
    <QCSeq>0</QCSeq>
    <QCNo />
    <PreProdWRSeq>0</PreProdWRSeq>
    <PreAssySeq>0</PreAssySeq>
    <PreAssyQty>0</PreAssyQty>
    <PreLotNo />
    <PreUnitSeq>0</PreUnitSeq>
    <FactUnit>1</FactUnit>
    <CustSeq>0</CustSeq>
    <WorkType>6041007</WorkType>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <WorkDate>20151130</WorkDate>
    <DeptSeq>3</DeptSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033535,@WorkingTag=N'D',@CompanySeq=3,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1015
rollback 