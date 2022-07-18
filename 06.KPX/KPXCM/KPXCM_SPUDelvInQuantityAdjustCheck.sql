IF OBJECT_ID('KPXCM_SPUDelvInQuantityAdjustCheck') IS NOT NULL 
    DROP PROC KPXCM_SPUDelvInQuantityAdjustCheck
GO 
    
/************************************************************
 ��  �� - ������-�԰�������� : Check
 �ۼ��� - 20141215
 �ۼ��� - ����ȯ
 ������ - 
************************************************************/
CREATE PROC KPXCM_SPUDelvInQuantityAdjustCheck
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0  
AS   

    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250)
  
    CREATE TABLE #KPX_TPUDelvInQuantityAdjust (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPUDelvInQuantityAdjust'

----===============--
---- �ʼ��Է� üũ --
----===============--

---- �ʼ��Է� Message �޾ƿ���
    EXEC dbo._SCOMMessage @MessageType OUTPUT,
                          @Status      OUTPUT,
                          @Results     OUTPUT,
                          1038               , -- �ʼ��Է� �׸��� �Է����� �ʾҽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ʼ�%')
                          @LanguageSeq       , 
                          0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'

    -- �ʼ��Է� Check 
      UPDATE #KPX_TPUDelvInQuantityAdjust
         SET Result        = @Results,
             MessageType   = @MessageType,
             Status        = @Status
        FROM #KPX_TPUDelvInQuantityAdjust AS A
       WHERE A.WorkingTag IN ('A','U')
         AND A.Status = 0
      -- guide : �̰��� �ʼ��Է� üũ �� �׸��� �������� ��������.
      -- e.g.   :
         AND (A.Qty         = 0
          OR  A.DelvInSeq   = 0
          OR  A.DelvInSerl  = 0)

--==================================================================================--  
------ ������ ���� üũ : UPDATE, DELETE �� ������ �������� ������ ����ó�� ----------
--==================================================================================--  
    IF  EXISTS (SELECT 1   
                  FROM #KPX_TPUDelvInQuantityAdjust AS A   
                       LEFT OUTER JOIN KPX_TPUDelvInQuantityAdjust AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq 
                                                                                    AND ( A.AdjustSeq     = B.AdjustSeq ) 
                                                                                    AND ( A.DelvInSeq     = B.DelvInSeq ) 
                                                                                    AND ( A.DelvInSerl    = B.DelvInSerl ) 
                          
                 WHERE A.WorkingTag IN ('U', 'D')
                   AND B.AdjustSeq IS NULL )  
     BEGIN  
         EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                               @Status      OUTPUT,  
                               @Results     OUTPUT,  
                               7                  , -- �ڷᰡ ��ϵǾ� ���� �ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                               @LanguageSeq       ,   
                               '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'      
         UPDATE #KPX_TPUDelvInQuantityAdjust  
            SET Result        = @Results,  
                MessageType   = @MessageType,  
                Status        = @Status  
           FROM #KPX_TPUDelvInQuantityAdjust AS A   
                LEFT OUTER  JOIN KPX_TPUDelvInQuantityAdjust AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq 
                                                                         AND ( A.AdjustSeq     = B.AdjustSeq ) 
                                                                         AND ( A.DelvInSeq     = B.DelvInSeq ) 
                                                                         AND ( A.DelvInSerl    = B.DelvInSerl ) 
                          
          WHERE A.WorkingTag IN ('U', 'D')
            AND b.AdjustSeq IS NULL 
    END   
    
    ------------------------------------------------------------------------------------
    -- üũ, ��ǥ ó�� �� �����ʹ� ����/���� �� �� �����ϴ�. 
    ------------------------------------------------------------------------------------
    
    UPDATE A 
       SET Result = '��ǥ ó�� �� �����ʹ� ����/���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPX_TPUDelvInQuantityAdjust AS A 
      JOIN _TPUBuyingAcc                AS B ON ( B.CompanySeq = @CompanySeq AND B.SourceType = 1 AND B.SourceSeq = A.DelvInSeq AND B.SourceSerl = A.DelvInSerl AND B.SlipSeq <> 0 ) 
     WHERE A.WorkingTag IN ( 'U', 'D' ) 
       AND A.Status = 0 
    
    ------------------------------------------------------------------------------------
    -- üũ, END 
    ------------------------------------------------------------------------------------
    
    
    --select * From _TUIImpDelv where delvseq = 1000123
    
    
----=========================================================================--
---- �����ڵ�  üũ:������ �� ���̺��� ��� ������ ��� ���̺� üũ sp�Դϴ�.
----=========================================================================--        
    --EXEC dbo._SCOMCodeDeleteCheck  @CompanySeq,@UserSeq,@LanguageSeq,'KPX_TPUDelvInQuantityAdjust', '#KPX_TPUDelvInQuantityAdjust','Ű��'  

----=============================================--
---- �ߺ����� üũ (�ϳ��� �ߺ����� üũ �� ���)--
----=============================================--  
---- �ߺ�üũ Message �޾ƿ���    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)    
                          @LanguageSeq       ,     
                          0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%����ī���ȣ%'    
      
----====================================--
---- �ߺ�����üũ(Ű���� 2�� �̻��� ���)
----====================================-- 
    ---- �ߺ�üũMessage �޾ƿ���   
        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                              @Status      OUTPUT,    
                              @Results     OUTPUT,    
                              6                  , -- �ߺ���@1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)    
                              @LanguageSeq       ,     
                              0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%����ī���ȣ%'    
    ---- �ߺ�����Check --
    
    --========================================--
    -- �̹�����Ƚ�Ʈ�����ߺ��Ǵ°��ִ���Ȯ�� --
    --========================================--
    UPDATE #KPX_TPUDelvInQuantityAdjust     
       SET Result        = @Results     ,     
           MessageType   = @MessageType ,     
           Status        = @Status      
      FROM #KPX_TPUDelvInQuantityAdjust      AS A JOIN KPX_TPUDelvInQuantityAdjust AS B ON A.DelvInSeq   = B.DelvInSeq    
                                                                                       AND A.DelvInSerl  = B.DelvInSerl

     WHERE A.WorkingTag  IN ('A')   
       AND A.Status      = 0    
       AND B.CompanySeq = @CompanySeq    
    --========================================--   
    -- ���������Ʈ�����ߺ��Ǵ°����ִ���Ȯ�� --
    --========================================--     
    UPDATE A      
       SET Result        = @Results      ,     
           MessageType   = @MessageType  ,     
           Status        = @Status    
      FROM #KPX_TPUDelvInQuantityAdjust AS A    JOIN #KPX_TPUDelvInQuantityAdjust AS B ON A.DelvInSeq   = B.DelvInSeq  -- �ߺ� �÷��� �߰� �ɼ��� �Ȱ��� ���� �־��ֱ�
                                                                                      AND A.DelvInSerl  = B.DelvInSerl       
                                                                                      AND A.IDX_NO     <> B.IDX_NO       
     WHERE A.WorkingTag IN ('A')   
       AND A.Status      = 0     

    
    
-- guide : �� �� 'Ű ����', '���࿩�� üũ', '�������� üũ', 'Ȯ������ üũ' ���� üũ������ �ֽ��ϴ�.
--guide : '������ Ű ����' --------------------------
    DECLARE @MaxSeq INT,
            @Count  INT 
    SELECT @Count = Count(1) FROM #KPX_TPUDelvInQuantityAdjust WHERE WorkingTag = 'A' AND Status = 0
    if @Count >0 
    BEGIN
    EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'KPX_TPUDelvInQuantityAdjust','AdjustSeq',@Count --rowcount  
          UPDATE #KPX_TPUDelvInQuantityAdjust             
             SET AdjustSeq  = @MaxSeq + 1
           WHERE WorkingTag = 'A'            
             AND Status = 0 
    END  

                           
    SELECT * FROM #KPX_TPUDelvInQuantityAdjust 
RETURN
GO
