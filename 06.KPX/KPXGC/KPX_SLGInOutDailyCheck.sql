
IF OBJECT_ID('KPX_SLGInOutDailyCheck') IS NOT NULL 
    DROP PROC KPX_SLGInOutDailyCheck
GO

-- v2014.12.05 

-- ����Ʈ���̺�� ���� by����õ 
    -- Ver.20140120  
  
-- 2012.03.29 by ��ö��  
-- ����: �����԰��Է½� �̵�����(�������)�� �԰����ں��� ������ ���� �޽��� ȣ��    
  
-- ��������üũ, 2008.01 by ����ȯ   
-- �����԰��Է�   
CREATE PROC KPX_SLGInOutDailyCheck    
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
            @TableSeq    INT,   
            @LGStartDate NCHAR(6)  
    
    
    -- ���� ����Ÿ ��� ����    
    CREATE TABLE #LGInOutDailyCheck (WorkingTag NCHAR(1) NULL)      
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#LGInOutDailyCheck'         
    IF @@ERROR <> 0 RETURN     
   
    IF @WorkingTag = 'D'       
    BEGIN      
        UPDATE #LGInOutDailyCheck      
           SET WorkingTag = 'D'      
    END      
      
    -- â�����ǻ��Ͽ��� ���� �� ���� ��Ÿ����Է¿��� �����Ұ� :: 20140220 �ڼ�ȣ �߰�  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1167               , -- @1��(��) ������ �� �����ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1167)      
                          @LanguageSeq       ,    
                          0, 'â�����ǻ��Ͽ��� ��� �� ������'  
    UPDATE #LGInOutDailyCheck      
       SET Result        = @Results    ,      
           MessageType   = @MessageType,      
           Status        = @Status  
      FROM #LGInOutDailyCheck      AS A  
     WHERE A.WorkingTag = 'D'  
       AND A.InOutType  = 30  
       AND @PgmSeq      = 1368  
       AND EXISTS ( SELECT 1 FROM _TLGWHStkReal WHERE InOutSeq = A.InOutSeq AND IsEtcOut = '1' AND CompanySeq = @CompanySeq )  
  
    -- â�����ǻ��Ͽ��� ���� �� ���� �ʼ� �����Ϳ� ���� ��Ÿ����Է¿��� �����Ұ� :: 20140220 �ڼ�ȣ �߰�  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          2012               , -- @1��(��) ���� ���� �� �� �����ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 2012)      
                          @LanguageSeq       ,    
                          0, 'â�����ǻ��Ͽ��� ��� �� �������� �ʼ�������'  
    UPDATE #LGInOutDailyCheck      
       SET Result        = REPLACE(@Results, ' ����', '') ,  
           MessageType   = @MessageType                   ,  
           Status        = @Status  
      FROM #LGInOutDailyCheck  AS A  
           JOIN KPX_TPUMatOutEtcOut AS B ON @CompanySeq = B.CompanySeq  
                                   AND A.InOutSeq  = B.InOutSeq  
                                   AND A.InOutType = B.InOutType  
     WHERE B.CompanySeq = @CompanySeq  
       AND A.WorkingTag = 'U'         
       AND A.InOutType  = 30  
       AND @PgmSeq      = 1368  
       AND EXISTS ( SELECT 1 FROM _TLGWHStkReal WHERE InOutSeq = A.InOutSeq AND IsEtcOut = '1' AND CompanySeq = @CompanySeq )  
       AND (A.BizUnit   <> B.BizUnit   OR  
            A.InOutDate <> B.InOutDate OR  
            A.OutWHSeq  <> B.OutWHSeq   )  
  
    -- üũ1, SerialNo �ݿ�����üũ   
      
    -- @2 @1(@3)��(��) ��ϵǾ� ����/���� �� �� �����ϴ�.  
 -- SerialNo��(��) ��ϵǾ� ����/���� �� �� �����ϴ�.  
 EXEC dbo._SCOMMessage @MessageType OUTPUT,            
                          @Status      OUTPUT,            
                          @Results     OUTPUT,            
                          8, -- select * from _TCAMessageLanguage where MessageSeq = 8  
                          @LanguageSeq,             
                          0,'SerialNo'  
   
   
 -- �� ����, ��Ʈǰ����� ������ �ʿ䰡 ����, �� �ܰ�� �� ���� ������ �ܰ� ����ǿ������� SerialNo����� �ϴϱ�...    
 UPDATE A  
      SET A.Result   = REPLACE( REPLACE( @Results, '@2', '' ), '(@3)', '' ),   
     A.MessageType = @MessageType,          
     A.Status   = @Status       
   FROM #LGInOutDailyCheck     AS A   
   --JOIN _TLGInOutSerialSub AS B WITH(NOLOCK) ON ( A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND B.CompanySeq = @CompanySeq )  
   JOIN _TLGInOutSerialStock     AS B WITH(NOLOCK) ON ( A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND B.CompanySeq = @CompanySeq )  
  WHERE A.WorkingTag IN ( 'U', 'D' )   
    AND A.Status = 0    
   
 -- üũ1, END   
   
 -- üũ2, �����԰��Է½� �̵�����(�������)�� �԰����ں��� ������ ���� �޽��� ȣ��   
   
 EXEC dbo._SCOMMessage @MessageType OUTPUT,            
                          @Status      OUTPUT,            
                          @Results     OUTPUT,            
                          1200, -- select * from _TCAMessageLanguage where Message like '%Ů�ϴ�%'  
                          @LanguageSeq,             
                          31997, N'�̵�����', -- select * from _TCADictionary where Word like '�̵�����'  
                       20881, N'�԰�����'   
 UPDATE A  
    SET A.Result   = @Results,   
     A.MessageType = @MessageType,          
     A.Status   = @Status       
 --select A.InOutDate, A.CompleteDate   
   FROM #LGInOutDailyCheck             AS A   
   LEFT OUTER JOIN KPX_TPUMatOutEtcOutItemSub AS B ON ( B.CompanySeq = @CompanySeq AND A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq )  
  WHERE 1=1 --A.WorkingTag IN ( 'A', 'U' )   
    AND A.Status = 0    
    AND A.InOutType = 81   
    --AND ISNULL( A.CompleteDate, '' ) <> '' -- �԰����ڰ� ������ �����԰��Է����� ����   
    AND B.CompanySeq IS NULL   
    AND A.InOutDate > A.CompleteDate  
      
 -- üũ2, END   
   
    --------------------------------------------------------------------------------------    
    -- �������ۿ� ���� �����ʹ� �Էµ��� �ʵ��� �Ѵ�.     
    --------------------------------------------------------------------------------------    
    EXEC dbo._SCOMEnv @CompanySeq, 1006, @UserSeq, @@PROCID, @LGStartDate OUTPUT    
      
    IF EXISTS (SELECT 1 FROM #LGInOutDailyCheck WHERE InOutDate < @LGStartDate + '01')  
    BEGIN   
        EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                              @Status      OUTPUT,      
                              @Results     OUTPUT,      
                              1197               , -- @1�� @2���� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1197)      
                              @LanguageSeq       ,       
                              238,'',     -- SELECT * FROM _TCADictionary WHERE Word like '%ó����%'      
                              28610,''    -- SELECT * FROM _TCADictionary WHERE Word like '%��������%'      
        UPDATE #LGInOutDailyCheck      
           SET Result        = @Results    ,      
               MessageType   = @MessageType,      
               Status        = @Status      
          FROM #LGInOutDailyCheck     
            
    END  
  
    -- ������ ��� ���� ������Ʈ(�������� ���� �ٲ�� �������� �߰�)  
    UPDATE #LGInOutDailyCheck  
       SET IsTrans = '1'  
     WHERE Status = 0    
       AND InOutType IN (81,83)  
  
  
  
  
    -- �̵��� ��, �԰�â��/���â�� ��� �ִ��� üũ  
    IF NOT EXISTS (SELECT 1 FROM #LGInOutDailyCheck WHERE Status <> 0)  
    BEGIN  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,            
                              @Status      OUTPUT,            
                              @Results     OUTPUT,            
                              133, -- select * from _TCAMessageLanguage where Message like '%����%' and LanguageSeq = 1  
                              @LanguageSeq,             
                              0, N''  
     UPDATE A  
        SET A.Result   = CASE WHEN ISNULL(A.InWHSeq,0) = 0 THEN @Results + ' (' + (SELECT Word FROM _TCADictionary WHERE WordSeq = 584 AND LanguageSeq = @LanguageSeq) + ')'  
                                       WHEN ISNULL(A.OutWHSeq,0) = 0 THEN @Results + ' (' + (SELECT Word FROM _TCADictionary WHERE WordSeq = 626 AND LanguageSeq = @LanguageSeq) + ')'  
                                       ELSE @Results END,   
            A.MessageType = @MessageType,          
         A.Status   = @Status       
       FROM #LGInOutDailyCheck AS A  
      WHERE A.WorkingTag IN ( 'A', 'U' )   
        AND A.Status = 0  
        AND A.InOutType = 80  
           AND (ISNULL(A.InWHSeq,0) = 0 OR ISNULL(A.OutWHSeq,0) = 0)  
    END  
  
  
  
  
    -------------------------------------------      
    -- �ߺ�����üũ      
    -------------------------------------------      
--     EXEC dbo._SCOMMessage @MessageType OUTPUT,      
--                           @Status      OUTPUT,      
--                           @Results     OUTPUT,      
--                           6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)      
--                           @LanguageSeq       ,       
--                           0,'�����'        
--     UPDATE #LGInOutDailyCheck      
--        SET Result        = REPLACE(@Results,'@2',RTRIM(B.InOutSeq)),      
--            MessageType   = @MessageType,      
--            Status        = @Status      
--       FROM #LGInOutDailyCheck AS A JOIN ( SELECT S.InOutSeq  
--                                      FROM (      
--                                            SELECT A1.InOutSeq  
--                                              FROM #LGInOutDailyCheck AS A1      
--                                             WHERE A1.WorkingTag IN ('A','U')      
--                                               AND A1.Status = 0      
--                                            UNION ALL      
--                                            SELECT A1.InOutSeq   
--                                              FROM KPX_TPUMatOutEtcOut AS A1      
--                                             WHERE A1.InOutSeq   NOT IN (SELECT InOutSeq    
--                                                                           FROM #LGInOutDailyCheck       
--                                                                          WHERE WorkingTag IN ('U','D')       
--                                                                            AND Status = 0)      
--                                               AND A1.CompanySeq = @CompanySeq      
--                                           ) AS S      
--                                     GROUP BY S.InOutSeq   
--                                     HAVING COUNT(1) > 1      
--                                   ) AS B ON A.InOutSeq = B.InOutSeq      
     
      
    --ERR Message    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1130               , -- ���� �۾��� ����Ǿ ����,������ �� �����ϴ�..(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1044)      
                          @LanguageSeq       ,       
                          0,'������'   -- SELECT * FROM _TCADictionary WHERE Word like '%����%'      
  
    UPDATE #LGInOutDailyCheck      
       SET Result        = @Results    ,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #LGInOutDailyCheck   AS A      
           JOIN (SELECT Seq AS InOutSeq  
                   FROM _TLGTransCarPackingItem   
                  WHERE CompanySeq = @CompanySeq  
                    AND ServiceSeq IN (8039007, 8039009)  
                  GROUP BY Seq) AS B ON A.InOutSeq = B.InOutSeq  
  WHERE A.InOutType NOT IN (81) -- ��������   
    
 --select * from _TDASMinor where MajorSeq = 8042  
   
    --   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1044               , -- ���� �۾��� ����Ǿ ����,������ �� �����ϴ�..(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1044)      
                          @LanguageSeq       ,       
                          0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%����%'      
  
    UPDATE #LGInOutDailyCheck      
         SET Result        = @Results    ,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #LGInOutDailyCheck   AS A      
           JOIN KPX_TPUMatOutEtcOut AS B ON B.CompanySeq = @CompanySeq  
                                   AND A.InOutType  = B.InOutType  
                                   AND A.InOutSeq   = B.InOutSeq  
     WHERE B.IsTrans = '1'   
       AND B.IsCompleted = '1'  
       AND A.IsInTrans = '1'  
  
  
    -- ���ۿ� ���� ���� Update  
    UPDATE #LGInOutDailyCheck  
       SET CompleteDate = ''  
     WHERE Status = 0    
       AND IsCompleted <> '1'  
  
  
    -------------------------------------------    
    -- ���࿩��üũ    
    -------------------------------------------    
    IF EXISTS (SELECT 1 FROM #LGInOutDailyCheck WHERE WorkingTag IN ('U', 'D') )    
    BEGIN    
        -- ����üũ�� ���̺� ���̺�  
        CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT IDENTITY, TABLENAME   NVARCHAR(100))        
          
        -- ����üũ�� ������ ���̺�  
        CREATE TABLE #Temp_InOutDaily(IDX_NO INT IDENTITY, InOutSeq INT, InOutSerl INT, InOutType INT, IsNext NCHAR(1), IsStop NCHAR(1))   
          
        -- ����� ���� ���̺�  
        CREATE TABLE #TCOMProgressTracking(IDX_NO   INT,            IDOrder INT,            Seq INT,           Serl INT,            SubSerl INT,  
                                           Qty      DECIMAL(19, 5), StdQty  DECIMAL(19,5) , Amt DECIMAL(19, 5),VAT DECIMAL(19,5))          
  
        SELECT @TableSeq = ProgTableSeq  
          FROM _TCOMProgTable WITH(NOLOCK)--���������̺�  
         WHERE ProgTableName = 'KPX_TPUMatOutEtcOutItem'  
  
        INSERT INTO #TMP_PROGRESSTABLE(TABLENAME)  
        SELECT B.ProgTableName  
          FROM (SELECT ToTableSeq FROM _TCOMProgRelativeTables WITH(NOLOCK) WHERE FromTableSeq = @TableSeq AND CompanySeq = @CompanySeq) AS A --�������̺����  
                JOIN _TCOMProgTable AS B WITH(NOLOCK) ON A.ToTableSeq = B.ProgTableSeq  
  
       INSERT INTO #Temp_InOutDaily(InOutSeq, InOutSerl, InOutType, IsNext, IsStop) -- IsNext=1(����), 0(������)  
        SELECT  A.InOutSeq, B.InOutSerl, B.InOutType, '0', '0'  
          FROM #LGInOutDailyCheck     AS A WITH(NOLOCK)     
                JOIN KPX_TPUMatOutEtcOut AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                     AND A.InOutSeq   = C.InOutSeq  
                                                     AND A.InOutType  = C.InOutType  
                JOIN KPX_TPUMatOutEtcOutItem AS B WITH(NOLOCK) ON B.CompanySeq   = @CompanySeq    
                                                         AND A.InOutSeq     = B.InOutSeq  
                                                         AND A.InOutType    = B.InOutType  
         WHERE A.WorkingTag IN ('U', 'D')    
           AND A.Status = 0    
  
        EXEC _SCOMProgressTracking @CompanySeq, 'KPX_TPUMatOutEtcOutItem', '#Temp_InOutDaily', 'InOutSeq', 'InOutSerl', 'InOutType'     
    
        --���࿩�� üũ  
        UPDATE #Temp_InOutDaily     
          SET IsNext = '1'    
         FROM  #Temp_InOutDaily AS A    
                JOIN #TCOMProgressTracking AS B ON A.IDX_No = B.IDX_No    
  
        --ERR Message (����)  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                              @Status      OUTPUT,    
                              @Results     OUTPUT,    
                              1044               , -- ���� �۾��� ����Ǿ ����,������ �� �����ϴ�..(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1044)    
                              @LanguageSeq       ,     
                              0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%����%'    
        UPDATE #LGInOutDailyCheck    
           SET Result        = @Results    ,    
               MessageType   = @MessageType,    
               Status        = @Status    
          FROM #LGInOutDailyCheck   AS A    
               JOIN #Temp_InOutDaily AS B ON A.InOutSeq = B.InOutSeq   
         WHERE B.IsNext = '1'   
                         
    END  
  
    -------------------------------------------      
    -- INSERT ��ȣ�ο�(�� ������ ó��)      
      -------------------------------------------      
    SELECT @Count = COUNT(1) FROM #LGInOutDailyCheck WHERE WorkingTag = 'A' --@Count������(AND Status = 0 ����)  
    IF @Count > 0      
    BEGIN        
        SELECT @BizUnit = MAX(BizUnit),      
               @Date    = ISNULL(MAX(InOutDate),REPLACE(CONVERT(CHAR(10),GETDATE(),121),'-',''))      
          FROM #LGInOutDailyCheck WHERE WorkingTag = 'A' AND Status = 0      
    
  
        -- Ű�������ڵ�κ� ����        
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TPUMatOutEtcOut', 'InOutSeq', @Count      
  
    print @Seq  
        -- Temp Talbe �� ������ Ű�� UPDATE      
        UPDATE #LGInOutDailyCheck      
           SET InOutSeq = @Seq + DataSeq      
         WHERE WorkingTag = 'A'      
           AND Status = 0      
      
        -- ��ȣ�����ڵ�κ� ����        
        exec dbo._SCOMCreateNo 'LG', 'KPX_TPUMatOutEtcOut', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT      
        -- Temp Talbe �� ������ Ű�� UPDATE      
        UPDATE #LGInOutDailyCheck      
           SET InOutNo = @MaxNo      
         WHERE WorkingTag = 'A'      
           AND Status = 0      
  
  
    END        
      
    SELECT * FROM #LGInOutDailyCheck      
    
    RETURN        