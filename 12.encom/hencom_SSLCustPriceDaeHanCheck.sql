IF OBJECT_ID('hencom_SSLCustPriceDaeHanCheck') IS NOT NULL 
	DROP PROC hencom_SSLCustPriceDaeHanCheck
GO 

-- v 2017.02.02 
/************************************************************
 ��  �� - �ŷ�ó���ܰ����(����)üũ_hencom
 �ۼ��� - 2015.10.20
 �ۼ��� - kth
 ������ -
************************************************************/	
CREATE PROC hencom_SSLCustPriceDaeHanCheck
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
            @Results     NVARCHAR(250)  
  
  
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TSLCustPriceDaeHan (WorkingTag NCHAR(1) NULL)    
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TSLCustPriceDaeHan'       
    IF @@ERROR <> 0 RETURN      
  
--�� Default ���� üũ ǥ�� : ���������� ��ϵ� ��������� ǥ��
    --�� �����, �ŷ�ó, ����, ǰ��, ��������� �ʼ� �� üũ
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          133                , -- �ʼ��׸��� �����Ǿ����ϴ� (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 133)  
                          @LanguageSeq       
    UPDATE #TSLCustPriceDaeHan 
       SET Result       = @Results      , 
           MessageType  = @MessageType  , 
           Status       = @Status  
      FROM #TSLCustPriceDaeHan
     WHERE WorkingTag IN ('A', 'U')  
       AND Status = 0
       AND (ISNULL(CustSeq, 0) = 0 OR ISNULL(DeptSeq, 0) = 0 OR ISNULL(ItemSeq, 0) = 0 OR ISNULL(StartDate, '') = '')
       -- ISNULL(ProdDistrictSeq, 0) = 0    ������ ���� �߰��� ��
	
	-- 2017.02.02 ����ó��
	/*
    UPDATE #TSLCustPriceDaeHan 
       SET Result       = '�ǸŴܰ��� ���Դܰ����� �۽��ϴ�.', 
           Status       = 1  
      FROM #TSLCustPriceDaeHan
     WHERE WorkingTag IN ('A', 'U')  
       AND Status = 0
       AND (ISNULL(SalesPrice, 0) < ISNULL(RealItemPrice, 0)) -- �ǸŴܰ��� ���Դܰ����� ���� ��� ����
	*/
    
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
    
    ----========================================--
    ---- �̹�����Ƚ�Ʈ�����ߺ��Ǵ°��ִ���Ȯ�� --
    ----========================================--
    UPDATE #TSLCustPriceDaeHan     
       SET Result        = @Results     ,     
           MessageType   = @MessageType ,     
           Status        = @Status      
      FROM #TSLCustPriceDaeHan      AS A    
           JOIN hencom_TSLCustPriceDaeHan AS B ON A.CPDRegSeq <> B.CPDRegSeq 
                                               AND A.DeptSeq = B.DeptSeq  -- �ߺ� �÷��� �߰� �ɼ��� �Ȱ��� ���� �־��ֱ�
                                               AND ISNULL(A.ProdDistrictSeq, 0) = ISNULL(B.ProdDistrictSeq, 0)
                                               AND ISNULL(A.CustSeq, 0) = ISNULL(B.CustSeq, 0)
                                               AND A.ItemSeq = B.ItemSeq
                                               AND ISNULL(A.DeliCustSeq, 0) = ISNULL(B.DeliCustSeq, 0)
                                               AND ISNULL(A.PUCustSeq, 0) = ISNULL(B.PUCustSeq, 0)
                                               AND A.StartDate = B.StartDate
     WHERE A.WorkingTag  IN ('A','U')   
       AND A.Status      = 0    
       AND B.CompanySeq = @CompanySeq  
    ----========================================--   
    ---- ���������Ʈ�����ߺ��Ǵ°����ִ���Ȯ�� --
    ----========================================--     
    UPDATE A      
       SET Result        = @Results      ,     
           MessageType   = @MessageType  ,     
           Status        = @Status    
      FROM #TSLCustPriceDaeHan AS A    
           JOIN #TSLCustPriceDaeHan AS B ON A.DeptSeq = B.DeptSeq  -- �ߺ� �÷��� �߰� �ɼ��� �Ȱ��� ���� �־��ֱ�
                                         AND ISNULL(A.ProdDistrictSeq, 0) = ISNULL(B.ProdDistrictSeq, 0)
                                         AND ISNULL(A.CustSeq, 0) = ISNULL(B.CustSeq, 0)
                                         AND A.ItemSeq = B.ItemSeq
                                         AND ISNULL(A.DeliCustSeq, 0) = ISNULL(B.DeliCustSeq, 0)
                                         AND ISNULL(A.PUCustSeq, 0) = ISNULL(B.PUCustSeq, 0)
                                         AND A.StartDate = B.StartDate
                                         AND A.IDX_NO <> B.IDX_NO       
     WHERE A.WorkingTag IN ( 'A','U' )   
       AND A.Status      = 0     


    --�� ���ų�ǰ �����Ͱ� �ִ� ���, ���� & ������Ʈ �Ұ��ǵ��� [���� �޽��� : ���� ��ǰ���� �־, ���� �Ұ��մϴ�.]
    --Ư���ϰ� �ܰ��� JOIN �� �ִ´�.
    --UPDATE #TSLCustPriceDaeHan    
    --   SET Result        = '[���� �޽��� : ���� ��ǰ���� �־, ���� �Ұ��մϴ�.]',    
    --       Status        = 1    
    --  FROM #TSLCustPriceDaeHan AS A 
    --  JOIN hencom_TSLCustPriceDaeHan AS D ON D.CompanySeq = @CompanySeq
    --                                      AND D.BuyPriceSeq = A.BuyPriceSeq  
    -- WHERE A.Status = 0    
    --   AND A.WorkingTag IN ('U', 'D')    
    --   AND EXISTS (SELECT 1 FROM _TPUDelvItem AS B
    --                        JOIN _TPUDelv AS M ON M.CompanySeq = B.CompanySeq
    --                                          AND M.DelvSeq = B.DelvSeq
    --                        JOIN hencom_TPUDelvItemAdd AS C ON C.CompanySeq = B.CompanySeq
    --                                                       AND C.DelvSeq = B.DelvSeq
    --                                                       AND C.DelvSerl = B.DelvSerl
    --                       WHERE B.CompanySeq = @CompanySeq 
    --                         AND B.ItemSeq = D.ItemSeq
    --                         AND M.CustSeq = D.CustSeq
    --                         AND M.DeptSeq = D.DeptSeq
    --                         AND ISNULL(C.ProdDistrictSeq, 0) = ISNULL(D.ProdDistrictSeq, 0)
    --                         AND ISNULL(B.Price, 0) = ISNULL(D.RealItemPrice, 0))  
    -------------------------------------------  
    -- MaxStartDate Update  
    -------------------------------------------  
    ALTER TABLE #TSLCustPriceDaeHan ADD MaxStartDate NCHAR(8) NULL
    UPDATE #TSLCustPriceDaeHan  
       SET MaxStartDate = (SELECT MAX(StartDate)   
                             FROM hencom_TSLCustPriceDaeHan   
                            WHERE ItemSeq = A.ItemSeq   
                              AND PUCustSeq = A.PUCustSeq  
                              AND DeptSeq = A.DeptSeq   
                              AND ProdDistrictSeq = A.ProdDistrictSeq 
                              AND ISNULL(DeliCustSeq, 0) = ISNULL(A.DeliCustSeq, 0) 
                              AND CustSeq = A.CustSeq
                              AND CompanySeq = @CompanySeq  )  
      FROM #TSLCustPriceDaeHan AS A    

    -------------------------------------------  
    -- ����������� ���� �����Ϻ��� Ŀ������ üũ (WorkIngTag = 'A')   
    -------------------------------------------  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          100                 , 
                          @LanguageSeq       ,   
                          0,'������'   
    UPDATE #TSLCustPriceDaeHan  
       SET Result        = REPLACE(@Results,'@2',A.StartDate),  
           MessageType   = @MessageType,  
           Status        = @Status  
      FROM #TSLCustPriceDaeHan AS A JOIN ( SELECT ItemSeq  ,DeptSeq  ,PUCustSeq ,ProdDistrictSeq, DeliCustSeq, CustSeq    
                                      FROM #TSLCustPriceDaeHan AS A1  
                                               WHERE A1.WorkingTag IN ('A')  
                                                 AND A1.Status = 0  
                                                 AND A1.StartDate <= A1.MaxStartDate  
                                             ) AS B ON  A.ItemSeq = B.ItemSeq   
                                                    AND A.DeptSeq = B.DeptSeq  
                                                    AND A.PUCustSeq = B.PUCustSeq   
                                                    AND A.ProdDistrictSeq = B.ProdDistrictSeq   
                                                    AND A.DeliCustSeq = B.DeliCustSeq
                                                    AND A.CustSeq = B.CustSeq
     WHERE A.Status = 0 

     --------------------------------------------  
     -- ������ ������ ���������Ϻ��� Ŀ������ üũ   (WorkIngTag = 'U')   
     ---------------------------------------------  
     --UPDATE #TSLCustPriceDaeHan  
     --      SET Result        = REPLACE(@Results,'@2',A.StartDate),  
     --          MessageType   = @MessageType,  
     --          Status        = @Status  
     --  FROM #TSLCustPriceDaeHan AS A JOIN ( SELECT MAX(A.StartDate) AS SecondStartDate, A.ItemSeq, A.CustSeq, A.CurrSeq, A.UnitSeq  
     --                                        FROM hencom_TSLCustPriceDaeHan AS A join #TSLCustPriceDaeHan AS B on (A.ItemSeq = B.ItemSeq and  
     --                                                         A.CustSeq = B.CustSeq and  
     --                                                         A.CurrSeq = B.CurrSeq and  
     --                                                         A.UnitSeq = B.UnitSeq and
     --                                                         A.CompanySeq = @CompanySeq)  
     --                                       WHERE A.StartDate <> B.MaxStartDate and B.WorkingTag IN ('U') AND IsLast = '1'  AND B.Status = 0
     --                                       GROUP BY A.ItemSeq, A.CustSeq, A.CurrSeq, A.UnitSeq   
     --           ) AS B ON ( A.ItemSeq = B.ItemSeq AND  
     --                       A.CustSeq = B.CustSeq AND  
     --                       A.CurrSeq = B.CurrSeq AND  
     --                       A.UnitSeq = B.UnitSeq AND
     --                       IsLast = '1' )  
     -- WHERE B.SecondStartDate > A.StartDate   
     --   AND A.Status = 0 

        

--    -- �������� ���ϱ�
     
--    ALTER TABLE #TSLCustPriceDaeHan ADD IsLast VARCHAR(2)
    
--    UPDATE A 
--      SET IsLast = CASE WHEN EndDate = (SELECT TOP 1 EndDate FROM _TSLCustPriceDaeHan 
--                                                            WHERE  A.ItemSeq = ItemSeq   
--                                                               AND A.CustSeq = CustSeq  
--                                                               AND A.CurrOldSeq = CurrSeq   
--                                                               AND A.UnitOldSeq = UnitSeq
--                                                               AND @CompanySeq = CompanySeq
--                                                          ORDER BY EndDate DESC)  
--                         THEN '1' ELSE '0' END
--    FROM #TSLCustPriceDaeHan AS A
--    WHERE WorkingTag IN ('U', 'D')
      
--    -- �������� �ߴܰ��ϰ�� ������ ���� �ȵǾ�� �ϹǷ� IsLast '0'���� ó��
--    UPDATE A
--       SET IsLast = '0'
--      FROM #TSLCustPriceDaeHan AS A
--       JOIN _TSLCustPriceDaeHan AS B ON A.ItemSeq = B.ItemSeq   
--                                     AND A.CustSeq = B.CustSeq  
--                                     AND A.CurrSeq = B.CurrSeq   
--                                     AND A.UnitSeq = B.UnitSeq   
--              AND A.Serl    = B.Serl  
--                                     AND B.CompanySeq   = @CompanySeq  
--    WHERE A.IsLast = '1'
--      AND B.IsStop = '1'

--    -------------------------------------------  
--    -- MaxStartDate Update  
--    -------------------------------------------  
--    UPDATE #TSLCustPriceDaeHan  
--       SET MaxStartDate = (SELECT MAX(StartDate)   
--                             FROM _TSLCustPriceDaeHan   
--                            WHERE ItemSeq = A.ItemSeq   
--                              AND CustSeq = A.CustSeq  
--                              AND CurrSeq = A.CurrSeq   
--                              AND UnitSeq = A.UnitSeq  
--                              AND CompanySeq = @CompanySeq  )  
--      FROM #TSLCustPriceDaeHan AS A     
    
--    -------------------------------------------    
--    -- ���������,������ üũ 
--    -----------------------------------------    
--    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
--                          @Status      OUTPUT,  
--                          @Results     OUTPUT,  
--                          31                  , -- @1�� @2 ���� Ŀ�� �մϴ�. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 31)  
--                          @LanguageSeq       ,   
--                          223,'����������' 

--        UPDATE #TSLCustPriceDaeHan  
--           SET Result        = REPLACE(@Results,'@2',A.StartDate),  
--               MessageType   = @MessageType,  
--               Status        = @Status  
--          FROM #TSLCustPriceDaeHan AS A   
--         WHERE StartDate > EndDate  
--           AND EndDate > ''  
--           AND A.WorkingTag IN ('U')  
--           AND A.Status = 0  

--    -------------------------------------------  
--    -- ����������� ���� �����Ϻ��� Ŀ������ üũ (WorkIngTag = 'A')   
--    -------------------------------------------  
--    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
--                          @Status      OUTPUT,  
--                          @Results     OUTPUT,  
--                          100                 , 
--                          @LanguageSeq       ,   
--                          0,'������'   
--    UPDATE #TSLCustPriceDaeHan  
--       SET Result        = REPLACE(@Results,'@2',A.StartDate),  
--           MessageType   = @MessageType,  
--           Status        = @Status  
--      FROM #TSLCustPriceDaeHan AS A JOIN ( SELECT ItemSeq  ,CustSeq  ,CurrSeq ,UnitSeq      
--                                                FROM #TSLCustPriceDaeHan AS A1  
--                                               WHERE A1.WorkingTag IN ('A')  
--                                                 AND A1.Status = 0  
--                                                 AND A1.StartDate <= A1.MaxStartDate  
--                                             ) AS B ON  A.ItemSeq = B.ItemSeq   
--                                                    AND A.CustSeq = B.CustSeq  
--                                                    AND A.CurrSeq = B.CurrSeq   
--                                                    AND A.UnitSeq = B.UnitSeq   
--    WHERE A.Status = 0 
--  --------------------------------------------  
-- -- ������ ������ ���������Ϻ��� Ŀ������ üũ   (WorkIngTag = 'U')   
--  ---------------------------------------------  

-- UPDATE #TSLCustPriceDaeHan  
--       SET Result        = REPLACE(@Results,'@2',A.StartDate),  
--           MessageType   = @MessageType,  
--           Status        = @Status  
--   FROM #TSLCustPriceDaeHan AS A JOIN ( SELECT MAX(A.StartDate) AS SecondStartDate, A.ItemSeq, A.CustSeq, A.CurrSeq, A.UnitSeq  
--                                         FROM _TSLCustPriceDaeHan AS A join #TSLCustPriceDaeHan AS B on (A.ItemSeq = B.ItemSeq and  
--                                                          A.CustSeq = B.CustSeq and  
--                                                          A.CurrSeq = B.CurrSeq and  
--                                           A.UnitSeq = B.UnitSeq and
--                                                          A.CompanySeq = @CompanySeq)  
--                                        WHERE A.StartDate <> B.MaxStartDate and B.WorkingTag IN ('U') AND IsLast = '1'  AND B.Status = 0
--                                        GROUP BY A.ItemSeq, A.CustSeq, A.CurrSeq, A.UnitSeq   
--            ) AS B ON ( A.ItemSeq = B.ItemSeq AND  
--               A.CustSeq = B.CustSeq AND  
--               A.CurrSeq = B.CurrSeq AND  
--               A.UnitSeq = B.UnitSeq AND
--               IsLast = '1' )  
--  WHERE B.SecondStartDate > A.StartDate   
--    AND A.Status = 0 

--    -------------------------------------------    
--    -- ���������  ���� �ߺ�����üũ     (WorkIngTag = 'U')   
--    -----------------------------------------    
--    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
--                          @Status      OUTPUT,    
--                          @Results     OUTPUT,    
--                          6                  ,   -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)    
--                          @LanguageSeq       ,     
--                          0,'���������'           
--    UPDATE #TSLCustPriceDaeHan    
--       SET Result        = REPLACE(@Results,'@2',A.StartDate),    
--           MessageType   = @MessageType,    
--           Status        = @Status    
--      FROM #TSLCustPriceDaeHan AS A JOIN (    select   A.ItemSeq AS ItemSeq,A.CustSeq AS CustSeq, A.CurrSeq AS CurrSeq,  A.UnitSeq AS UnitSeq ,A.Serl AS Serl  
--                                                        FROM #TSLCustPriceDaeHan       AS A    
--                                                             JOIN _TSLCustPriceDaeHan AS B  ON A.ItemSeq = B.ItemSeq   
--                                                                                            AND A.CustSeq = B.CustSeq  
--                                                                                     AND A.CurrSeq = B.CurrSeq   
--                                                                                            AND A.UnitSeq = B.UnitSeq   
--                                                                                            AND A.Serl   <> B.Serl  
--              AND B.CompanySeq   = @CompanySeq  
--                                                        WHERE (( B.StartDate BETWEEN A.StartDate AND A.EndDate ) OR ( B.EndDate  BETWEEN A.StartDate AND A.EndDate)  
--                                                          OR (B.StartDate < = A.StartDate AND B.EndDate > A.EndDate )  OR (A.StartDate > = B.StartDate AND A.EndDate <= B.EndDate ) ) 
--                                                         AND (A.WorkingTag  = 'U' OR (A.WorkingTag = 'A' AND B.IsStop = '1'))  -- �ߴ�ó���� �ű� ��Ͻ� �ű԰� ������ �ߴܰ� ����Ⱓ �ߺ� üũ  11.10.25 �輼ȣ ���� 
--                                                         AND A.Status = 0    
--                                                         AND ((A.WorkingTag  = 'U' AND A.IsLast = '1') OR (A.WorkingTag = 'A' AND B.IsStop = '1'))  
--                                              )   
                                                          
--                                               AS B  ON A.ItemSeq = B.ItemSeq   
--                                                    AND A.CustSeq = B.CustSeq  
--                                                    AND A.CurrSeq = B.CurrSeq   
--                                                    AND A.UnitSeq = B.UnitSeq    
--                                                    AND A.Serl    = B.Serl  
--     WHERE A.Status = 0 
  
  
  
--    -------------------------------------------------------------  
--    -- ��ǰ�� �ܰ� ���ÿ� ������ �߰� �� ��� ��������� üũ       -- 11.10.11 �輼ȣ �߰�
--    -------------------------------------------------------------      
      
  
--    UPDATE #TSLCustPriceDaeHan    
--      SET Result        = REPLACE(@Results,'@2',A.StartDate),    
--           MessageType   = @MessageType,    
--           Status        = @Status    
--    FROM #TSLCustPriceDaeHan                       AS A
--    JOIN (SELECT ItemSeq, CustSeq, CurrSeq, UnitSeq  
--          FROM #TSLCustPriceDaeHan
--         WHERE WorkingTag = 'A'
--           AND Status =  0
--        GROUP BY ItemSeq, CustSeq, CurrSeq, UnitSeq, StartDate 
--        HAVING COUNT(1) > 1)                         AS B ON  A.ItemSeq = B.ItemSeq  
--                                                         AND A.CustSeq = B.CustSeq  
--                                                         AND A.CurrSeq = B.CurrSeq  
--                                                         AND A.UnitSeq = B.UnitSeq
--    WHERE A.WorkingTag = 'A'
--      AND A.Status = 0 

--    -------------------------------------------    
--    -- NOT EXISTS    
--    -------------------------------------------    
--    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
--                          @Status      OUTPUT,    
--                          @Results     OUTPUT,    
--                          7                  , -- �ڷᰡ ��ϵǾ� ���� �ʽ��ϴ�..(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)    
--                          @LanguageSeq       ,     
--                          0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%����ī���ȣ%'    
    
--    UPDATE #TSLCustPriceDaeHan    
--       SET Result        = @Results,    
--           MessageType   = @MessageType,    
--           Status        = @Status    
--      FROM #TSLCustPriceDaeHan AS A    
--     WHERE A.Status = 0    
--       AND A.WorkingTag IN ('U', 'D')    
--    AND NOT EXISTS(SELECT 1 FROM _TSLCustPriceDaeHan WHERE CompanySeq = @CompanySeq AND Serl = A.Serl)  
      
 
--    -------------------------------------------  
--    -- ���� ������ ������Ʈ  (WorkingTag 'A' ���)
--    -------------------------------------------  
--    UPDATE _TSLCustPriceDaeHan  
--      SET   EndDate = CONVERT(CHAR(8),DATEADD(day, - 1,B.StartDate),112)    
--     From  _TSLCustPriceDaeHan    AS A   
--         JOIN (SELECT ItemSeq, CustSeq, CurrSeq, UnitSeq, MaxStartDate, MIN(StartDate) AS StartDate
--                 FROM #TSLCustPriceDaeHan 
--                      WHERE  WorkingTag IN ('A')   
--                         AND Status = 0  
--                 GROUP BY ItemSeq, CustSeq, CurrSeq, UnitSeq, MaxStartDate) AS B ON   A.ItemSeq    = B.ItemSeq  
--                                                                                  AND A.CustSeq    = B.CustSeq  
--                                                                                  AND A.CurrSeq    = B.CurrSeq   
--                                                                                  AND A.UnitSeq    = B.UnitSeq   
--                                                                                  AND A.StartDate  = B.MaxStartDate  
--      WHERE  A.CompanySeq   = @CompanySeq   
--        AND  ISNULL(A.IsStop, '0') <> '1'    -- �ߴ�ó���� �ű� ��Ͻ� �ߴܰ� ������ ��������ʵ��� ���� 11.10.25 �輼ȣ �߰� 
   

--    -------------------------------------------  
--    -- ���� ������ ������Ʈ  (WorkingTag 'U' ���)
--    -------------------------------------------  
-- UPDATE _TSLCustPriceDaeHan  
--       SET EndDate = CONVERT( CHAR(8), DATEADD( day, -1, B.StartDate ), 112 )           
--      FROM _TSLCustPriceDaeHan AS A   
--      JOIN ( SELECT MAX(A.EndDate) AS MaxEndDate, A.ItemSeq, A.CustSeq, A.CurrSeq, A.UnitSeq, B.StartDate  
--     FROM _TSLCustPriceDaeHan AS A   
--     JOIN #TSLCustPriceDaeHan AS B ON (A.ItemSeq = B.ItemSeq  
--           AND A.CustSeq = B.CustSeq  
--           AND A.CurrSeq = B.CurrSeq  
--           AND A.UnitSeq = B.UnitSeq  
--           AND A.Serl <> B.Serl  
--           AND B.WorkingTag IN ('U') 
--           AND B.IsLast = '1'
--           AND B.Status = 0 
--           AND A.CompanySeq = @CompanySeq)                                        
--    GROUP BY A.ItemSeq, A.CustSeq, A.CurrSeq, A.UnitSeq, B.StartDate   
--     ) AS B ON ( A.ItemSeq = B.ItemSeq  
--     AND A.CustSeq = B.CustSeq  
--     AND A.CurrSeq = B.CurrSeq  
--     AND A.UnitSeq = B.UnitSeq   
--     AND A.EndDate = B.MaxEndDate )  
--  WHERE A.CompanySeq = @CompanySeq  
--   AND  ISNULL(A.IsStop, '0') <> '1'     -- �ߴ�ó���� �ű� ��Ͻ� �ߴܰ� ������ ��������ʵ��� ���� 11.10.25 �輼ȣ �߰� 

    -- ���� üũ
    EXEC dbo._SCOMCodeDeleteCheck  @CompanySeq,@UserSeq,@LanguageSeq,'hencom_TSLCustPriceDaeHan','#TSLCustPriceDaeHan','CPDRegSeq'
    -- MAX CPDRegSeq
    SELECT @Count = COUNT(*) FROM #TSLCustPriceDaeHan WHERE WorkingTag = 'A' AND Status = 0 
    IF @Count > 0
    BEGIN   
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'hencom_TSLCustPriceDaeHan', 'CPDRegSeq', @Count
        UPDATE #TSLCustPriceDaeHan
           SET CPDRegSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'
           AND Status = 0
    END  
    SELECT * FROM #TSLCustPriceDaeHan

    --SELECT @Count = COUNT(1) FROM #TSLCustPriceDaeHan WHERE WorkingTag = 'A' AND Status = 0  
    --IF @Count > 0  
    --BEGIN    
    --    -- Ű�������ڵ�κ� ����    
  
    --    DECLARE @Serl INT  
  
    --    SELECT @Serl = ISNULL((SELECT MAX(A.CPDRegSeq) FROM hencom_TSLCustPriceDaeHan AS A ),0)  
  
    --    UPDATE #TSLCustPriceDaeHan  
    --    SET CPDRegSeq = @Serl + DataSeq  
    --    WHERE WorkingTag = 'A' AND Status = 0  
    --END
    --SELECT * FROM #TSLCustPriceDaeHan    
     
RETURN      
/*******************************************************************************************************************/
