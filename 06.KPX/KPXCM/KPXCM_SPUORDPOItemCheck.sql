IF OBJECT_ID('KPXCM_SPUORDPOItemCheck') IS NOT NULL 
    DROP PROC KPXCM_SPUORDPOItemCheck
GO 

-- v2015.09.24 

/*************************************************************************************************  
  FORM NAME           -       FrmPPUORDPO 
  DESCRIPTION         -     ���Ź��� ������ üũ
  CREAE DATE          -       2008.10.09      CREATE BY: ����
  LAST UPDATE  DATE   -       2008.10.09         UPDATE BY: ����
 *************************************************************************************************/  
 CREATE PROC dbo.KPXCM_SPUORDPOItemCheck
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
             @Results     NVARCHAR(250)
      -- ���� ����Ÿ ��� ����
     CREATE TABLE #TPUORDPOItem (WorkingTag NCHAR(1) NULL)  
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUORDPOItem' 
    
     IF @@ERROR <> 0 RETURN   
       --------------------------------------------------------------------------------------
      -- ����������üũ: UPDATE, DELETE �õ������������������鿡��ó��
      --------------------------------------------------------------------------------------
      IF NOT EXISTS (SELECT 1 
                       FROM #TPUORDPOItem AS A 
                             JOIN _TPUORDPOItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.POSeq = B.POSeq
                      WHERE A.WorkingTag IN ('U', 'D'))
      BEGIN
          EXEC dbo._SCOMMessage @MessageType OUTPUT,
                                @Status      OUTPUT,
                                @Results     OUTPUT,
                                7                  , -- �ڷᰡ��ϵǾ������ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)
                                @LanguageSeq       , 
                                '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
           UPDATE #TPUORDPOItem
             SET Result        = @Results,
                 MessageType   = @MessageType,
                 Status        = @Status
           WHERE WorkingTag IN ('U','D')
             AND Status = 0
       END
    
    ------------------------------------------------------------------------
    -- MES ����ó�� �Ǿ����Ƿ� ���� �� �� �����ϴ�. 
    ------------------------------------------------------------------------
    UPDATE A 
       SET Result = 'MES ����ó�� �Ǿ����Ƿ� ���� �� �� �����ϴ�. ', 
           MessageType = 1234, 
           Status = 1234 
      FROM #TPUORDPOItem        AS A 
     WHERE EXISTS (SELECT 1 FROM IF_PUDelv_MES WHERE CompanySeq = @CompanySeq AND POSeq = A.POSeq AND POSerl = A.POSerl AND ConfirmFlag = 'Y')
       AND A.WorkingTag = 'D' 
       AND A.Status = 0 
    ------------------------------------------------------------------------
    -- MES ����ó�� �Ǿ����Ƿ� ���� �� �� �����ϴ�. 
    ------------------------------------------------------------------------    
    
    
    
    
      --------------------------------------------------------------------------------------
      -- ������ üũ : �������� �����Ϻ��� ���� �ϰ�� üũ      -- 12.11.20 BY �輼ȣ
      --------------------------------------------------------------------------------------
      
     EXEC dbo._SCOMMessage @MessageType OUTPUT,          
                           @Status      OUTPUT,          
                           @Results     OUTPUT,          
                           1150                  , -- @1�� @2���� Ŀ�� �մϴ�.  
                           @LanguageSeq       ,           
                           138,'',   -- ������  
                           166,''    -- ������  
      
       UPDATE #TPUORDPOItem
         SET Result        = @Results,
             MessageType   = @MessageType,
             Status        = @Status
       WHERE WorkingTag IN ('A','U')
         AND Status = 0
         AND DelvDate < PODate
  
     -- ���ų�ǰ ���� �� ���� ���� ����
     IF EXISTS (SELECT 1 FROM #TPUORDPOItem WHERE WorkingTag IN ('U', 'D'))
     BEGIN
         -------------------
         --��ǰ���࿩��-----
         -------------------
         CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))    
           
         CREATE TABLE #Temp_Order(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT,IsDelv NCHAR(1))    
         
     
         CREATE TABLE #TCOMProgressTracking(IDX_NO INT, IDOrder INT, Seq INT,Serl INT, SubSerl INT,Qty DECIMAL(19, 5), StdQty DECIMAL(19,5) , Amt    DECIMAL(19, 5),VAT DECIMAL(19,5))      
     
         CREATE TABLE #OrderTracking(IDX_NO INT, POQty DECIMAL(19,5), POCurAmt DECIMAL(19,5))
     
         INSERT #TMP_PROGRESSTABLE     
         SELECT 1, '_TPUDelvItem'               -- ���ų�ǰ
          -- ���Ź���
         INSERT INTO #Temp_Order(OrderSeq, OrderSerl, IsDelv)    
         SELECT  A.POSeq, A.POSerl, '2'    
           FROM #TPUORDPOItem AS A
          WHERE A.WorkingTag IN ('U', 'D')
            AND A.Status = 0
          EXEC _SCOMProgressTracking @CompanySeq, '_TPUORDPOItem', '#Temp_Order', 'OrderSeq', 'OrderSerl', ''    
        
         
         INSERT INTO #OrderTracking    
         SELECT IDX_NO,    
                SUM(CASE IDOrder WHEN 1 THEN Qty     ELSE 0 END),    
                SUM(CASE IDOrder WHEN 1 THEN Amt     ELSE 0 END)   
           FROM #TCOMProgressTracking    
          GROUP BY IDX_No    
          UPDATE #Temp_Order 
           SET IsDelv = '1'
          FROM  #Temp_Order AS A  JOIN #TCOMProgressTracking AS B ON A.IDX_No = B.IDX_No
                                                                 AND B.Amt <> 0
                                                                 AND B.Qty <> 0
          -------------------
         --��ǰ���࿩��END------
         -------------------
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               1044               , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
                               @LanguageSeq       , 
                               0,'��ǰ������'   -- SELECT * FROM _TCADictionary WHERE Word like '%����%'
         UPDATE #TPUORDPOItem
            SET Result        = @Results    ,
                MessageType   = @MessageType,
                Status        = @Status
           FROM #TPUORDPOItem    AS A
                JOIN #Temp_Order AS B ON A.POSeq  = B.OrderSeq
          AND A.POSerl = B.OrderSerl
          WHERE B.IsDelv = '1'
            AND A.WorkingTag IN ('U', 'D')
     END    
  
      -- MAX Serl
     SELECT @Count = COUNT(*) FROM #TPUORDPOItem WHERE WorkingTag = 'A' AND Status = 0 
     IF @Count > 0
     BEGIN   
         SELECT @Serl = ISNULL(MAX(A.POSerl), 0) FROM _TPUORDPOItem AS A JOIN #TPUORDPOItem AS B ON A.POSeq = B.POSeq
                                                WHERE A.CompanySeq = @CompanySeq
         UPDATE #TPUORDPOItem SET POSerl = @Serl + DataSeq 
          WHERE WorkingTag = 'A' AND Status = 0
     END  
  
     -------------------------------------------  
     -- �����ڵ�0���Ͻÿ����߻�
     -------------------------------------------      
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 1055)    
                           @LanguageSeq       
      UPDATE #TPUORDPOItem                               
        SET Result        = @Results     ,    
            MessageType   = @MessageType ,    
            Status        = @Status    
       FROM #TPUORDPOItem
      WHERE Status = 0
        AND (POSeq = 0 OR POSeq IS NULL)
  
     SELECT * FROM #TPUORDPOItem
 RETURN    
 /*******************************************************************************************************************/