
IF OBJECT_ID('KPX_SDAItemUnitSpecCheck') IS NOT NULL 
    DROP PROC KPX_SDAItemUnitSpecCheck
GO 

-- v2014.11.04 

-- ǰ������Ӽ� üũ by����õ

/************************************************************  
��  �� - ǰ������Ӽ� üũ  
�ۼ��� - 2008�� 7��    
�ۼ��� - ���ظ�  
************************************************************/  
CREATE PROC KPX_SDAItemUnitSpecCheck  
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
    CREATE TABLE #KPX_TDAItemUnitSpec (WorkingTag NCHAR(1) NULL)    
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPX_TDAItemUnitSpec'       
    IF @@ERROR <> 0 RETURN   
  
    -------------------------------------------  
    -- �ߺ�����üũ  
    -------------------------------------------  
--     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
--                           @Status      OUTPUT,  
--                           @Results     OUTPUT,  
--                           6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
--                           @LanguageSeq       ,   
--                           0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%����ī���ȣ%'  
--     UPDATE #TDAItem  
--        SET Result        = REPLACE(@Results,'@2',B.ItemSeq),  
--            MessageType   = @MessageType,  
--            Status        = @Status  
--       FROM #TDAItem AS A JOIN ( SELECT S.ItemNo  
--                                      FROM (  
--                                            SELECT A1.ItemNo  
--                                              FROM #TDAItem AS A1  
--                                             WHERE A1.WorkingTag IN ('A', 'U')  
--                                               AND A1.Status = 0  
--                                            UNION ALL  
--                                            SELECT A1.ItemNo  
--                                              FROM _TDAItem AS A1  
--                                             WHERE A1.ItemSeq NOT IN (SELECT ItemSeq   
--                                                                            FROM #TDAItem   
--                                                                           WHERE WorkingTag IN ('U','D')   
--                                                                             AND Status = 0)  
--                                           ) AS S  
--                                     GROUP BY S.ItemNo  
--                                     HAVING COUNT(1) > 1  
--                                   ) AS B ON (A.ItemNo = B.ItemNo)  
  
    -- ��뿩��üũ  
    -------------------------------------------  
    -- 1.��ǥ���࿩��üũ  
--     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
--                           @Status      OUTPUT,  
--                           @Results     OUTPUT,  
--                           8                  , -- @2 @1(@3)��(��) ��ϵǾ� ����/���� �� �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 8)  
--                           @LanguageSeq       ,   
--                           9,'��ǥ'             -- SELECT * FROM _TCADictionary WHERE Word like '%��ǥ%'  
--     UPDATE #TDAItemCard  
--        SET Result        = REPLACE(REPLACE(@Results,'@2',A.BillCardNo),'@3',dbo._FCOMMask(@CompanySeq,'SlipID',C.SlipID)),  
--            MessageType   = @MessageType,  
--            Status        = @Status  
--       FROM #TDAItemCard AS A JOIN _TACSlipRem AS B ON(A.BillCardSeq = B.RemValSeq)  
--                              JOIN _TACSlipRow AS C ON(B.CompanySeq = C.CompanySeq AND B.SlipSeq = C.SlipSeq)  
--      WHERE B.CompanySeq = @CompanySeq  
--        AND C.CompanySeq = @CompanySeq  
--        AND B.RemSeq = 0 -- Ȯ���ȵ�(^^)  
--        AND A.WorkingTag NOT IN ('D')   
--        AND A.Status = 0  
  
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
  
    -------------------------------------------  
    -- INSERT ��ȣ�ο�(�� ������ ó��)  
    -------------------------------------------  
   
    SELECT * FROM #KPX_TDAItemUnitSpec     
    RETURN      
/*******************************************************************************************************************/  
  