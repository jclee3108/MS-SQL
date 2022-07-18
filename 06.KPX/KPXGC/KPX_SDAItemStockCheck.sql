
IF OBJECT_ID('KPX_SDAItemStockCheck') IS NOT NULL 
    DROP PROC KPX_SDAItemStockCheck
GO 

-- v2014.11.06 

-- �������üũ by����õ 

-- v2012.10.16   
  
-- ǰ���� - �������üũ   
CREATE PROC KPX_SDAItemStockCheck  
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS      
    DECLARE @MessageType INT,  
            @Status   INT,  
            @Results  NVARCHAR(250)  
   
 -- _TDAItemStock  
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TDAItemStock (WorkingTag NCHAR(1) NULL)    
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TDAItemStock'       
    IF @@ERROR <> 0 RETURN   
      
 EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
        @Results     OUTPUT,  
        18                 , -- @1��(��) ����/���� �Ҽ� �����ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE MessageDefault like '%����%')  
        @LanguageSeq       ,   
                       0, '@1'   -- SELECT * FROM _TCADictionary WHERE Word like '%��������'  
   
 DECLARE @WORD1 NVARCHAR(50),   
         @WORD2 NVARCHAR(50),   
         @WORD3 NVARCHAR(50)  
   
 SELECT @WORD1 = Word FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = @LanguageSeq AND WordSeq = 11022   
 IF @@ROWCOUNT = 0 SELECT @WORD1 = N'Lot��������'   
   
 SELECT @WORD2 = Word FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = @LanguageSeq AND WordSeq = 14166   
 IF @@ROWCOUNT = 0 SELECT @WORD2 = N'SerialNo��������'   
   
 SELECT @WORD3 = Word FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = @LanguageSeq AND WordSeq = 48754   
 IF @@ROWCOUNT = 0 SELECT @WORD3 = N'Roll��������'   
   
 UPDATE A   
       SET A.Result        = replace( @Results, '@1', @WORD3+'/'+@WORD1+'/'+@WORD2 ),  
           A.MessageType   = @MessageType,  
           A.Status        = @Status  
 --SELECT *   
   FROM #TDAItemStock            AS A   
   LEFT OUTER JOIN _TDAItemStock AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )  
  WHERE A.WorkingTag IN ( 'U', 'D' )  
    AND A.Status = 0   
    AND EXISTS (SELECT TOP 1 1 FROM _TLGInOutStock WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND ItemSeq = A.ItemSeq)  
       AND ( A.IsSerialMng <> B.IsSerialMng OR A.IsLotMng <> B.IsLotMng OR A.IsRollUnit <> B.IsRollUnit )  
      
    SELECT * FROM #TDAItemStock     
  
    RETURN      