
IF OBJECT_ID('KPX_SDAItemUnitCheck') IS NOT NULL 
    DROP PROC KPX_SDAItemUnitCheck
GO 

-- v2014.11.04 

-- ǰ�����ȯ��üũ by����õ
/************************************************************  
��  �� - ǰ�����ȯ�� üũ  
�ۼ��� - 2008�� 7��    
�ۼ��� - ���ظ�  
************************************************************/  
CREATE PROC KPX_SDAItemUnitCheck  
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
            @StkUnitSeq  INT -- ���ش���  
  
  
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #KPX_TDAItemUnit (WorkingTag NCHAR(1) NULL)    
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPX_TDAItemUnit'       
    IF @@ERROR <> 0 RETURN   
    
    -- ǰ������ ����ȣ��ܿ��� ����Ͻ��� ������ ȣ���ϱ⿡ �Ʒ��� ���� ����ȯ�� ��Ͽ��θ� üũ�ص� ǰ�������� ������ �Ǵ� ��Ȳ��   
    --IF NOT EXISTS ( SELECT 1 FROM #KPX_TDAItemUnit )  
    --BEGIN  
    --    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
    --                          @Status      OUTPUT,    
    --                          @Results     OUTPUT,    
    --                          1001                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�����ϴ�%')    
    --                          @LanguageSeq       ,     
    --                          3117,'����ȯ��/�Ӽ�����'   -- SELECT * FROM _TCADictionary WHERE Word like '%ȯ��%'    
                                
    --    SELECT @Status AS Status, @Results AS Result, @MessageType AS MessageType  
    --    RETURN  
    --END  
  
    -------------------------------------------  
    -- �ߺ�����üũ  
    -------------------------------------------  
--     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
--                           @Status      OUTPUT,  
--                           @Results     OUTPUT,  
--                           6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
--                           @LanguageSeq       ,   
--                           0,'ȯ�����'    
--   
--   
--   
--     UPDATE #KPX_TDAItemUnit  
--        SET Result        = REPLACE(@Results,'@2', C.UnitName),  
--            MessageType   = @MessageType,  
--            Status        = @Status  
--       FROM #KPX_TDAItemUnit AS A JOIN ( SELECT S.ItemSeq, S.UnitSeq  
--                                      FROM (  
--                                            SELECT A1.ItemSeq, A1.UnitSeq  
--                                              FROM #KPX_TDAItemUnit AS A1  
--                                             WHERE A1.WorkingTag IN ('A', 'U')  
--                                               AND A1.Status = 0  
--                                             GROUP BY A1.ItemSeq, A1.UnitSeq  
--                                            UNION ALL  
--                                            SELECT A1.ItemSeq, A1.UnitSeq  
--                                              FROM _TDAItemUnit AS A1 LEFT OUTER JOIN (SELECT ItemSeq, UnitSeq   
--                                                                            FROM #KPX_TDAItemUnit   
--                                                                           WHERE WorkingTag NOT IN ('D')   
--                                                                             AND Status = 0) AS A2  
--                                                                    ON A1.CompanySeq = @CompanySeq  
--                                                                   AND A1.ItemSeq    = A2.ItemSeq  
--                                                                   AND A1.UnitSeq    = A2.UnitSeq  
--                                             WHERE ISNULL(A2.UnitSeq, 0) = 0  
--                                           ) AS S  
--                                     GROUP BY S.ItemSeq, S.UnitSeq  
  --                                     HAVING COUNT(1) > 1  
--                                   ) AS B ON A.ItemSeq = B.ItemSeq  
--                                         AND A.UnitSeq = B.UnitSeq  
--                           JOIN _TDAUnit AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq  
--                                                           AND B.UnitSeq    = C.UnitSeq  
    -------------------------------------------  
    -- ��뿩��üũ  
    -------------------------------------------  
    
    -------------------------------------------    
    -- ������������üũ   
    -------------------------------------------    
    IF EXISTS (SELECT 1   
                 FROM #KPX_TDAItemUnit AS A  
                      JOIN KPX_TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                          AND A.ItemSeq    = B.ItemSeq  
                                                          AND A.UnitSeqOld = B.UnitSeq  
                WHERE A.WorkingTag IN ('U','D')  
                  AND A.Status = 0  
                  AND (A.UnitSeq <> B.UnitSeq OR A.WorkingTag = 'D'))  
    BEGIN  
        -------------------------------------------  
        -------------------------------------------  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              19                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                              @LanguageSeq       ,   
                              0,'���� ����'   -- SELECT * FROM _TCADictionary WHERE Word like '%����ī���ȣ%'  
        UPDATE #KPX_TDAItemUnit  
           SET Result        = REPLACE(@Results,'@2','����/����'),  
               MessageType   = @MessageType,  
               Status        = @Status  
          FROM #KPX_TDAItemUnit AS X JOIN (SELECT C.ItemSeq, C.UnitSeq  
                                         FROM #KPX_TDAItemUnit AS A  
                                              JOIN KPX_TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                  AND A.ItemSeq    = B.ItemSeq  
                                                                                  AND A.UnitSeqOld = B.UnitSeq  
                                              JOIN _TLGInOutStock AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                                    AND B.ItemSeq    = C.ItemSeq  
                                                                                    AND B.UnitSeq    = C.UnitSeq  
                                        WHERE A.WorkingTag IN ('U','D')  
                                          AND A.Status = 0  
                                          AND (A.UnitSeq <> B.UnitSeq OR A.WorkingTag = 'D')  
                                        GROUP BY C.ItemSeq, C.UnitSeq  
                                          ) AS Y ON (X.ItemSeq = Y.ItemSeq)  
                                                AND (X.UnitSeqOld = Y.UnitSeq)  
  
  
        -------------------------------------------  
        -------------------------------------------  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              19                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                              @LanguageSeq       ,   
                              0,'���� ����'   -- SELECT * FROM _TCADictionary WHERE Word like '%����ī���ȣ%'  
        UPDATE #KPX_TDAItemUnit  
           SET Result        = REPLACE(@Results,'@2','����/����'),  
               MessageType   = @MessageType,  
               Status        = @Status  
          FROM #KPX_TDAItemUnit AS X JOIN (SELECT C.ItemSeq, C.UnitSeq  
                                         FROM #KPX_TDAItemUnit AS A  
                                                JOIN KPX_TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                  AND A.ItemSeq    = B.ItemSeq  
                                                                                  AND A.UnitSeqOld = B.UnitSeq  
                                              JOIN _TPDBOM AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                             AND B.ItemSeq    = C.ItemSeq  
                                                                             AND B.UnitSeq    = C.UnitSeq  
                                        WHERE A.WorkingTag IN ('U','D')  
                                          AND A.Status = 0  
                                          AND (A.UnitSeq <> B.UnitSeq OR A.WorkingTag = 'D')  
                                        GROUP BY C.ItemSeq, C.UnitSeq  
                                          ) AS Y ON (X.ItemSeq = Y.ItemSeq)  
                                                AND (X.UnitSeqOld = Y.UnitSeq)  
  
        -------------------------------------------  
        -------------------------------------------  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              19                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                              @LanguageSeq       ,   
                              0,'���� ����'   -- SELECT * FROM _TCADictionary WHERE Word like '%����ī���ȣ%'  
        UPDATE #KPX_TDAItemUnit  
           SET Result        = REPLACE(@Results,'@2','����/����'),  
               MessageType   = @MessageType,  
               Status        = @Status  
          FROM #KPX_TDAItemUnit AS X JOIN (SELECT C.ItemSeq, C.UnitSeq  
                                         FROM #KPX_TDAItemUnit AS A  
                                              JOIN KPX_TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                  AND A.ItemSeq    = B.ItemSeq  
                                                                                  AND A.UnitSeqOld = B.UnitSeq  
                                              JOIN _TSLItemUnitPrice AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                                       AND B.ItemSeq    = C.ItemSeq  
                                                                                       AND B.UnitSeq    = C.UnitSeq  
                                        WHERE A.WorkingTag IN ('U','D')  
                                          AND A.Status = 0  
                                          AND (A.UnitSeq <> B.UnitSeq OR A.WorkingTag = 'D')  
                                        GROUP BY C.ItemSeq, C.UnitSeq  
                                          ) AS Y ON (X.ItemSeq = Y.ItemSeq)  
                                                AND (X.UnitSeqOld = Y.UnitSeq)  
    END  
  
    -------------------------------------------    
    -- ���ش�����������üũ   
    -------------------------------------------    
    IF EXISTS (SELECT 1   
                 FROM #KPX_TDAItemUnit AS A  
                      JOIN KPX_TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                      AND A.ItemSeq    = B.ItemSeq  
                                                      AND A.UnitSeqOld = B.UnitSeq  
                WHERE A.WorkingTag IN ('U','D')  
                  AND A.Status = 0  
                  AND (A.UnitSeq <> A.UnitSeqOld OR A.WorkingTag = 'D'))  
    BEGIN  
        -------------------------------------------  
        -------------------------------------------  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                                19                   , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                              @LanguageSeq       ,   
                              0,'���ش���'   -- SELECT * FROM _TCADictionary WHERE Word like '%����ī���ȣ%'  
        UPDATE #KPX_TDAItemUnit  
           SET Result        = REPLACE(@Results,'@2','����/����'),  
               MessageType   = @MessageType,  
               Status        = @Status  
          FROM #KPX_TDAItemUnit AS X JOIN (SELECT B.ItemSeq, B.UnitSeq   
                                         FROM #KPX_TDAItemUnit AS A  
                                              JOIN KPX_TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                              AND A.ItemSeq    = B.ItemSeq  
                                                                              AND A.UnitSeqOld = B.UnitSeq  
                                        WHERE A.WorkingTag IN ('U','D')  
                                          AND A.Status = 0  
                                          AND (A.UnitSeq <> A.UnitSeqOld OR A.WorkingTag = 'D')  
                                        GROUP BY B.ItemSeq, B.UnitSeq  
                                          ) AS Y ON (X.ItemSeq = Y.ItemSeq)  
                                                AND (X.UnitSeqOld = Y.UnitSeq)  
    END  
  
    -------------------------------------------------------------------------------------------------------------------------  
    -- ���� �и� üũ : ���ش����� ȯ������� ���� ��� ����, �и�� �ٸ� ���ڷ� �Է� �� �� ����. 2010.12.24 by ������  
    -------------------------------------------------------------------------------------------------------------------------  
    SELECT @StkUnitSeq = B.UnitSeq  
      FROM #KPX_TDAItemUnit AS A   
            LEFT OUTER JOIN KPX_TDAItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                      AND A.ItemSeq    = B.ItemSeq  
                                                            
    IF EXISTS(SELECT 1 FROM #KPX_TDAItemUnit WHERE UnitSeq = @StkUnitSeq)  
    BEGIN                                                            
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1273               , -- ���ش����� ȯ������� ������ ȯ�귮���ڿ� ȯ�귮���ڵ� ���ƾ� �մϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1273)  
                              @LanguageSeq       ,   
                              0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'     
        UPDATE A  
           SET Result        = @Results,  
               MessageType   = @MessageType,  
               Status        = @Status  
          FROM #KPX_TDAItemUnit AS A  
                JOIN #KPX_TDAItemUnit AS B ON A.UnitSeq = B.UnitSeq  
                                      AND A.ConvNum <> B.ConvDen  
         WHERE A.UnitSeq = @StkUnitSeq  
    END  
  
    -------------------------------------------  
    -- ��������üũ  
    -------------------------------------------  
    -- ���� SP Call ����  
  
    -------------------------------------------  
    -- ���࿩��üũ  
    -------------------------------------------  
    -- ���� SP Call ����  
  
    -------------------------------------------  
    -- Ȯ������üũ   
    -------------------------------------------  
    -- ���� SP Call ����  
  
   
    SELECT * FROM #KPX_TDAItemUnit     
    RETURN      
GO 
exec KPX_SDAItemUnitCheck @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=1025582,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021310