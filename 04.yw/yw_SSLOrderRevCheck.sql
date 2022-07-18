IF OBJECT_ID('yw_SSLOrderRevCheck') IS NOT NULL 
    DROP PROC yw_SSLOrderRevCheck
GO 

-- v2014.02.28 
/************************************************************
 ��  �� - ������������ üũ
 �ۼ��� - 2008�� 7��  
 �ۼ��� - ���ظ�
 ************************************************************/
 CREATE PROC yw_SSLOrderRevCheck
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
             @BizUnit     INT,  
             @Date        NVARCHAR(8),  
             @MaxNo       NVARCHAR(50),
             @OrderSeq INT,
             @OrderRev INT
  
      -- ���� ����Ÿ ��� ����
     CREATE TABLE #TSLOrder (WorkingTag NCHAR(1) NULL)  
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TSLOrder'     
     IF @@ERROR <> 0 RETURN 
      SELECT TOP 1 @OrderSeq = ISNULL(OrderSeq, 0) 
       FROM #TSLOrder
  
     IF @WorkingTag = 'D'   
     BEGIN  
         UPDATE #TSLOrder  
            SET WorkingTag = 'D'  
          UPDATE #TSLOrder
            SET OrderRev = ISNULL((SELECT MAX(B.OrderRev)
                                     FROM #TSLOrder A 
                                          JOIN _TSLOrderRev AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                                                             AND A.OrderSeq   = B.OrderSeq
                                    WHERE A.WorkingTag = 'D' AND A.Status = 0), 0)
     END 
      --------------------------------------------------------------------------------------  
     -- ������ ���� üũ : UPDATE, DELETE �� ������ �������� ������ ����ó��  
     --------------------------------------------------------------------------------------  
     IF NOT EXISTS (SELECT 1   
                      FROM #TSLOrder AS A   
                            JOIN _TSLOrder AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.OrderSeq = B.OrderSeq  
                     WHERE A.WorkingTag IN ('U', 'D'))  
     BEGIN  
         EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                               @Status      OUTPUT,  
                               @Results     OUTPUT,  
                               7                  , -- �ڷᰡ ��ϵǾ� ���� �ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                               @LanguageSeq       ,   
                               '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'          
          UPDATE #TSLOrder  
            SET Result        = @Results,  
                MessageType   = @MessageType,  
                Status        = @Status  
          WHERE WorkingTag IN ('U','D')
     END 
  
     --------------------------------------------------------------------------------------  
     -- Ȯ�� Ȯ�� : Ȯ������ ���� ���� ���� ������ �� �� ����. 
     --------------------------------------------------------------------------------------  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           1209               , -- @1�� @2�� �ƴմϴ�.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 MessageSeq = 1209)    
                           @LanguageSeq       ,     
                           607,'',       -- SELECT * FROM _TCADictionary WHERE WordSeq like '607'    Ȯ��
                           23642, ''     -- SELECT * FROM _TCADictionary WHERE WordSeq like '23642'    ����    
      UPDATE #TSLOrder    
        SET Result        = @Results    ,    
            MessageType   = @MessageType,    
            Status        = @Status   
       FROM #TSLOrder AS A
             JOIN _TSLOrder_Confirm AS B ON B.CompanySeq = @CompanySeq
                                        AND A.OrderSeq   = B.CfmSeq   
                             AND B.CfmSerl    = 0                                                  
WHERE B.CfmCode = '0' -- ��Ȯ��
        AND A.WorkingTag = 'U' -- ���������� U �� D �� ����
      --------------------------------------------------------------------------------------  
     -- Ȯ�� Ȯ�� : Ȯ������ Ȯ���� ���� ����, ���� �� �� ����. 
     --------------------------------------------------------------------------------------  
     IF EXISTS(SELECT TOP 1 1  
                 FROM _TCOMConfirmDef A  
                      JOIN _TCOMConfirmPGM B ON A.CompanySeq = B.CompanySeq  
                                            AND A.ConfirmSeq = B.ConfirmSeq  
                WHERE A.CompanySeq = @CompanySeq  
                  AND B.PGMSeq = @PgmSeq  
                  AND A.IsNotUsed <> '1')     
     BEGIN                  
         EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                               @Status      OUTPUT,    
                               @Results     OUTPUT,    
                               1083               , -- Ȯ��(����)�� �ڷ�� ����/������ �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 MessageSeq = 1083)    
                               @LanguageSeq                         
          UPDATE #TSLOrder    
            SET Result        = @Results    ,    
                MessageType   = @MessageType,    
                Status        = @Status   
           FROM #TSLOrder AS A
                 JOIN _TSLOrder_Confirm AS B ON B.CompanySeq = @CompanySeq
                                            AND A.OrderSeq   = B.CfmSeq                                       
          WHERE B.CfmCode = '1' -- Ȯ��
            AND A.WorkingTag = 'D'   
     END                
      
     --------------------------------------------------------------------------------------  
     -- �ʼ��� ���� : ������� ���ƾ� �� �����Ͱ� ����Ǿ������ �޽���ó��  
     --------------------------------------------------------------------------------------  
     -- �ŷ�ó �����
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           19               , -- @1��(��) @2(��)�� �� �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 MessageSeq = 19)    
                           @LanguageSeq       ,     
                           6,'',       -- SELECT * FROM _TCADictionary WHERE WordSeq like '2524'    �ŷ�ó
                           13823, ''   -- SELECT * FROM _TCADictionary WHERE WordSeq like '13823'    ����
                           
     UPDATE #TSLOrder    
        SET Result        = @Results    ,    
            MessageType   = @MessageType,    
            Status        = @Status   
       FROM #TSLOrder AS A
             JOIN _TSLOrder AS B ON B.CompanySeq = @CompanySeq
                                AND A.OrderSeq   = B.OrderSeq
      WHERE A.CustSeq <> B.CustSeq
     
     -- ����ι� �����
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           19               , -- @1��(��) @2(��)�� �� �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 MessageSeq = 19)    
                           @LanguageSeq       ,     
                           2,'',         -- SELECT * FROM _TCADictionary WHERE WordSeq like '2'    ����ι�
                           13823, ''     -- SELECT * FROM _TCADictionary WHERE WordSeq like '13823'    ����
                           
     UPDATE #TSLOrder    
        SET Result        = @Results    ,    
            MessageType   = @MessageType,    
            Status        = @Status   
       FROM #TSLOrder AS A
             JOIN _TSLOrder AS B ON B.CompanySeq = @CompanySeq
                                AND A.OrderSeq   = B.OrderSeq
      WHERE A.BizUnit <> B.BizUnit
      
     -- ��Ź���� �����
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,  
                           @Results     OUTPUT,    
                           19               , -- @1��(��) @2(��)�� �� �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq =  1 MessageSeq = 19)    
                           @LanguageSeq       ,     
                           11263,'',         -- SELECT * FROM _TCADictionary WHERE WordSeq like '11263'    ��Ź����
                           13823, ''     -- SELECT * FROM _TCADictionary WHERE WordSeq like '13823'    ����
                           
     UPDATE #TSLOrder    
        SET Result        = @Results    ,    
            MessageType   = @MessageType,    
            Status        = @Status   
       FROM #TSLOrder AS A
             JOIN _TSLOrder AS B ON B.CompanySeq = @CompanySeq
                                AND A.OrderSeq   = B.OrderSeq
      WHERE A.SMConsignKind <> B.SMConsignKind
      /*
     -- ���ֱ��� �����
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           19               , -- @1��(��) @2(��)�� �� �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 MessageSeq = 19)    
                           @LanguageSeq       ,     
                           630,'',         -- SELECT * FROM _TCADictionary WHERE WordSeq like '630'    ���ֱ���
                           13823, ''     -- SELECT * FROM _TCADictionary WHERE WordSeq like '13823'    ����
                           
     UPDATE #TSLOrder    
        SET Result        = @Results    ,    
            MessageType   = @MessageType,    
            Status        = @Status   
       FROM #TSLOrder AS A
             JOIN _TSLOrder AS B ON B.CompanySeq = @CompanySeq
                                AND A.OrderSeq   = B.OrderSeq
      WHERE A.UMOrderKind <> B.UMOrderKind    
      */
     -- local���� �����
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           19               , -- @1��(��) @2(��)�� �� �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 MessageSeq = 19)    
                           @LanguageSeq       ,     
                           14037,'',         -- SELECT * FROM _TCADictionary WHERE WordSeq like '14037'    local����
                           13823, ''     -- SELECT * FROM _TCADictionary WHERE WordSeq like '13823'    ����
                           
     UPDATE #TSLOrder    
        SET Result        = @Results    ,    
            MessageType   = @MessageType,    
            Status        = @Status   
       FROM #TSLOrder AS A
             JOIN _TSLOrder AS B ON B.CompanySeq = @CompanySeq
                                AND A.OrderSeq   = B.OrderSeq
      WHERE A.SMExpKind <> B.SMExpKind       
  
     -------------------------------------------  
     -- INSERT ��ȣ�ο�(�� ������ ó��)  
     -------------------------------------------  
     SELECT @Count = COUNT(1) FROM #TSLOrder WHERE WorkingTag = 'U' AND Status = 0  
     IF @Count > 0  
     BEGIN    
         SELECT @OrderRev = MAX(ISNULL(OrderRev, 0))
           FROM _TSLOrder 
          WHERE CompanySeq  = @CompanySeq
            AND OrderSeq = @OrderSeq
          -- Temp Talbe �� ������ Ű�� UPDATE  
         UPDATE #TSLOrder  
            SET OrderRevOLD = ISNULL(OrderRev,0),
                OrderRev = ISNULL(@OrderRev,0) + 1
          WHERE WorkingTag = 'U'  
            AND Status = 0  
     END    
   
     SELECT * FROM #TSLOrder  
      RETURN    
 /*******************************************************************************************************************/