
IF OBJECT_ID('DTI_SSLInvoiceItemCheck') IS NOT NULL
    DROP PROC DTI_SSLInvoiceItemCheck 

GO
-- v2013.06.18   
  
/*********************************************************************************************************************    
    ȭ��� : �ŷ�����_����üũ    
    SP Name: _SSLInvoiceItemCheck    
    �ۼ��� : 2008.08.13 : CREATEd by ������        
    ������ :     
********************************************************************************************************************/    
CREATE PROC DTI_SSLInvoiceItemCheck      
    @xmlDocument    NVARCHAR(MAX),      
    @xmlFlags       INT = 0,      
    @ServiceSeq     INT = 0,      
    @WorkingTag     NVARCHAR(10)= '',      
    @CompanySeq     INT = 1,      
    @LanguageSeq    INT = 1,      
    @UserSeq        INT = 0,      
    @PgmSeq         INT = 0      
AS        
    DECLARE @Count            INT,    
            @InvoiceSeq       INT,    
            @BizUnit         INT,     
            @MaxInvoiceSerl   INT,    
            @MessageType      INT,    
            @Status           INT,    
            @GoodQtyDecLength INT,  
            @Results          NVARCHAR(250)    
  
    EXEC @GoodQtyDecLength = dbo._SCOMEnvR @CompanySeq, 8, @UserSeq, @@PROCID -- �Ǹ�/��ǰ �Ҽ����ڸ���  
      
    -- ���� ����Ÿ ��� ����      
    CREATE TABLE #TSLInvoiceItem (WorkingTag NCHAR(1) NULL)      
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TSLInvoiceItem'     
      
    CREATE TABLE #TSLInvoice (WorkingTag NCHAR(1) NULL)  -- ����ι��� �ش��ϴ� â������ ���ϱ����� �߰� 2011.03.24 hyjung    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TSLInvoice'      
   
    -- üũ 0, ��õ�ڵ尡 �ִ� �����Ͽ��� .. ��õ-���� Ȥ�� �����Ƿڰ� ������ ����ȣ��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
       @Status      OUTPUT,  
       @Results     OUTPUT,  
                            1365               , -- @1(��)�� �������� �ʽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%��������%')  
                            @LanguageSeq       ,  
                            2451, N'��õ'  
    
    DECLARE @WORD1 NVARCHAR(50), @WORD2 NVARCHAR(50), @WORD3 NVARCHAR(50)  
      
    SELECT @WORD1 = Word FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = @LanguageSeq AND WordSeq = 25275  
    IF @@ROWCOUNT = 0 SELECT @WORD1 = N'�����Ƿ�'   
      
    SELECT @WORD2 = Word FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = @LanguageSeq AND WordSeq = 23642  
    IF @@ROWCOUNT = 0 SELECT @WORD2 = N'����'   
      
    SELECT @WORD3 = Word FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = @LanguageSeq AND WordSeq = 607  
    IF @@ROWCOUNT = 0 SELECT @WORD3 = N'Ȯ��'   
      
    -- SELECT * FROM _TCADictionary WITH(NOLOCK) WHERE Word like 'Ȯ��'  
    --select * from _TCOMProgTable where ProgTableName = '_TSLDVReqItem' -- 16  
      
    UPDATE A  
       SET A.Result        = '('+@WORD3+')'+@WORD1+' '+@Results,   
     A.MessageType   = @MessageType,   
     A.Status        = @Status  
    --select B.* --FromTableSeq, FromSeq, FromSerl, FromSubSerl   
      FROM #TSLInvoiceItem              AS A   
      LEFT OUTER JOIN _TSLDVReqItem     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.FromSeq = B.DVReqSeq AND A.FromSerl = B.DVReqSerl )  
      LEFT OUTER JOIN _TSLDVReq_Confirm AS C WITH(NOLOCK) ON ( B.CompanySeq = C.CompanySeq AND C.CfmSecuSeq = 6304 AND B.DVReqSeq = C.CfmSeq )  
     WHERE A.WorkingTag = 'A'  
       AND A.Status = 0   
       AND ISNULL(A.FromTableSeq,0) = 16 -- �����Ƿ�   
       AND ISNULL(A.FromSeq,0) <> 0 -- ��õ�ڵ尡 �ִ� �����Ͽ��� ..  
       AND (B.DVReqSeq IS NULL OR ISNULL(C.CfmCode,'0') <> '1') -- ��õ�� ���ų�, Ȯ��ó�� ���� ������ ...  
      
    IF @@ROWCOUNT <> 0 BEGIN SELECT * FROM #TSLInvoiceItem RETURN END  
      
    UPDATE A  
       SET A.Result        = '('+@WORD3+')'+@WORD2+' '+@Results,   
     A.MessageType   = @MessageType,   
     A.Status        = @Status  
    --select B.* --FromTableSeq, FromSeq, FromSerl, FromSubSerl   
      FROM #TSLInvoiceItem              AS A   
        LEFT OUTER JOIN _TSLOrderItem     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.FromSeq = B.OrderSeq AND A.FromSerl = B.OrderSerl  )  
      LEFT OUTER JOIN _TSLOrder_Confirm AS C WITH(NOLOCK) ON ( B.CompanySeq = C.CompanySeq AND C.CfmSecuSeq = 6303 AND B.OrderSeq = C.CfmSeq )  
     WHERE A.WorkingTag = 'A'  
       AND A.Status = 0   
       AND ISNULL(A.FromTableSeq,0) = 19 -- ����   
       AND ISNULL(A.FromSeq,0) <> 0 -- ��õ�ڵ尡 �ִ� �����Ͽ��� ..  
       AND (B.OrderSeq IS NULL OR ISNULL(C.CfmCode,'0') <> '1') -- ��õ�� ���ų�, Ȯ��ó�� ���� ������ ...  
      
    IF @@ROWCOUNT <> 0 BEGIN SELECT * FROM #TSLInvoiceItem RETURN END  
      
    -- üũ 0, END   
      
 -- üũ1, �����������ϴ� ǰ�� ���Ͽ� ������â�� ���� â���϶� ������ �߻����� ���ϰ� ����   
 EXEC dbo._SCOMMessage @MessageType OUTPUT,  
       @Status      OUTPUT,  
       @Results     OUTPUT,  
                            125                , -- �� �ش��ϴ� @1�� ã���� �����ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%�����ϴ�%')  
                            @LanguageSeq       ,   
                            23906,'������â��'   -- SELECT * FROM _TCADictionary WHERE Word like '%������â��%'          
   
 UPDATE C  
       SET C.Result        = (select WHName from _TDAWH where CompanySeq = @CompanySeq and WHSeq = C.WHSeq)+@Results,  
     C.MessageType   = @MessageType,  
     C.Status        = @Status  
 --select *   
   FROM #TSLInvoiceItem as C       
   JOIN _TDAItem   as D with(nolock) on ( D.CompanySeq = @CompanySeq and C.ItemSeq = D.ItemSeq )  
   JOIN _TDAItemAsset as E with(nolock) on ( E.CompanySeq = @CompanySeq and D.AssetSeq = E.AssetSeq and E.IsQty = '0' )  
  WHERE C.WorkingTag IN ( 'A', 'U' )  
    AND C.Status = 0   
    AND NOT EXISTS (select 1 from _TDAWHSub where CompanySeq = @CompanySeq and UpWHSeq = C.WHSeq and SMWHKind = 8002009 and IsUse = '1')  
   
 IF @@ROWCOUNT <> 0 BEGIN SELECT * FROM #TSLInvoiceItem RETURN END  
   
 -- üũ1 end   
 
   
 -- üũ2, �����������ϴ� ǰ�� ���Ͽ� �Ǹ��� �����̸� ��Źâ�� ���� â���϶� ������ �߻����� ���ϰ� ����   
   
 EXEC dbo._SCOMMessage @MessageType OUTPUT,  
       @Status      OUTPUT,  
       @Results     OUTPUT,  
                            125                , -- �� �ش��ϴ� @1�� ã���� �����ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%�����ϴ�%')  
                            @LanguageSeq       ,   
                            780,'��Źâ��'   -- SELECT * FROM _TCADictionary WHERE Word like '%��Źâ��%'          
   
 UPDATE C  
       SET C.Result        = (select WHName from _TDAWH where CompanySeq = @CompanySeq and WHSeq = C.WHSeq)+@Results,  
     C.MessageType   = @MessageType,  
     C.Status        = @Status  
   FROM #TSLInvoiceItem as C       
   JOIN _TDAItem   as D with(nolock) on ( D.CompanySeq = @CompanySeq and C.ItemSeq = D.ItemSeq )  
   JOIN _TDAItemAsset as E with(nolock) on ( E.CompanySeq = @CompanySeq and D.AssetSeq = E.AssetSeq and E.IsQty = '0' )  
   JOIN #TSLInvoice  as F     on ( C.InvoiceSeq = F.InvoiceSeq )  
  WHERE C.WorkingTag IN ( 'A', 'U' )  
    AND C.Status = 0   
    AND NOT EXISTS (select 1 from _TDAWHSub where CompanySeq = @CompanySeq and UpWHSeq = C.WHSeq and SMWHKind = 8002004 and TrustCustSeq = F.CustSeq and IsUse = '1')  
    AND F.IsStockSales = '1'  
   
 IF @@ROWCOUNT <> 0 BEGIN SELECT * FROM #TSLInvoiceItem RETURN END  
   
 -- üũ2 end   
   
 -- üũ3, ��Ʈǰ���϶� �ش� â��� ���� ����ι��� �ִ� ����ι�����â�� ��Ʈ���â�� �ִ��� üũ   
 EXEC dbo._SCOMMessage @MessageType OUTPUT,  
       @Status      OUTPUT,  
       @Results     OUTPUT,  
                            125                , -- �� �ش��ϴ� @1�� ã���� �����ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%�����ϴ�%')  
                            @LanguageSeq       ,   
                            22670,'����ι�����â��'   -- SELECT * FROM _TCADictionary WHERE Word like '%����ι�����%'          
   
 UPDATE C  
       SET C.Result        = (select BizUnitName from _TDABizUnit where CompanySeq = @CompanySeq and BizUnit = F.BizUnit)+@Results,  
     C.MessageType   = @MessageType,  
     C.Status        = @Status  
   FROM #TSLInvoiceItem AS C       
   JOIN _TDAItemSales AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND C.ItemSeq = E.ItemSeq AND E.IsSet = '1' )  
     JOIN _TDAWH   AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND C.WHSeq =  F.WHSeq )   
  WHERE C.WorkingTag IN ( 'A', 'U' )  
    AND C.Status = 0   
    AND NOT EXISTS (SELECT 1 FROM _TDAWH WHERE CompanySeq = F.CompanySeq AND BizUnit = F.BizUnit AND SMWHKind = 8002013 AND IsNotUse = '0' ) -- ����ι�����â��   
   
 IF @@ROWCOUNT <> 0 BEGIN SELECT * FROM #TSLInvoiceItem RETURN END  
   
 EXEC dbo._SCOMMessage @MessageType OUTPUT,  
       @Status      OUTPUT,  
       @Results     OUTPUT,  
                            125                , -- �� �ش��ϴ� @1�� ã���� �����ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%�����ϴ�%')  
                            @LanguageSeq       ,   
                            23908,'��Ʈ����ǰâ��'   -- SELECT * FROM _TCADictionary WHERE Word like '%��Ʈ%â��%'          
   
 UPDATE C  
       SET C.Result        = '['+(select BizUnitName from _TDABizUnit where CompanySeq = @CompanySeq and BizUnit = F.BizUnit)+'] '  
         + (select WHName from _TDAWH where CompanySeq = @CompanySeq and WHSeq = G.WHSeq)+@Results,  
     C.MessageType   = @MessageType,  
     C.Status        = @Status  
   FROM #TSLInvoiceItem AS C       
   JOIN _TDAItemSales AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND C.ItemSeq = E.ItemSeq AND E.IsSet = '1' )  
   JOIN _TDAWH   AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND C.WHSeq = F.WHSeq )   
   JOIN _TDAWH   AS G WITH(NOLOCK) ON ( F.CompanySeq = G.CompanySeq AND F.BizUnit = G.BizUnit AND G.SMWHKind = 8002013 ) -- ����ι�����â��   
  WHERE C.WorkingTag IN ( 'A', 'U' )  
    AND C.Status = 0   
    AND NOT EXISTS (SELECT 1 FROM _TDAWHSub WHERE CompanySeq = G.CompanySeq AND UpWHSeq = G.WHSeq AND SMWHKind = 8002011 AND IsUse = '1') -- ��Ʈ���â��   
   
 IF @@ROWCOUNT <> 0 BEGIN SELECT * FROM #TSLInvoiceItem RETURN END  
   
 -- üũ3 end   
 

    EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                          @Status      OUTPUT,        
                          @Results     OUTPUT,        
                          1001                  , -- �ʼ��Է� ����Ÿ�� �Է��ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE MessageDefault LIKE '%�����ϴ�%')        
                          @LanguageSeq       ,         
                          0, '��ǰ������ �ش� LotNo'   -- SELECT * FROM _TCADictionary WHERE Word like '%��ǥ%'                
    UPDATE #TSLInvoiceItem        
       SET Result        = @Results,        
           MessageType   = @MessageType,        
           Status        = @Status      
      FROM #TSLInvoiceItem    AS A
      LEFT OUTER JOIN #TSLInvoice AS C ON ( C.InvoiceSeq = A.InvoiceSeq )
      LEFT OUTER JOIN (SELECT A.CompanySeq, B.Memo1 AS CustSeq, B.Memo2 AS EndUserSeq, A.EmpSeq, B.ItemSeq, B.LotNo    
                         FROM _TPUDelv AS A LEFT OUTER JOIN _TPUDelvItem AS B ON B.CompanySeq = A.CompanySeq AND B.DelvSeq = A.DelvSeq
                      ) AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = C.EmpSeq AND B.ItemSeq = A.ItemSeq AND B.CustSeq = C.CustSeq 
                                  AND (B.EndUserSeq = C.BKCustSeq OR B.EndUserSeq IN (SELECT EnvValue FROM DTI_TCOMEnv WHERE EnvSeq IN (2,3)))
                                ) 
     WHERE A.WorkingTag IN ('A','U')
       AND B.LotNo <> A.LotNo
  
    -------------------------------------------    
    -- ��Ʈǰ�� ����ǰ�� ������� ����ȵŵ��� üũ  
    -------------------------------------------  
 EXEC dbo._SCOMMessage @MessageType OUTPUT,  
       @Status      OUTPUT,  
       @Results     OUTPUT,  
                            1009               , -- �� �ش��ϴ� @1�� ã���� �����ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%��%')  
                            @LanguageSeq       ,   
                            4219,'����ǰ'   -- SELECT * FROM _TCADictionary WHERE Word like '%����ǰ%'          
   
 UPDATE #TSLInvoiceItem  
       SET Result        = @Results,  
     MessageType   = @MessageType,  
     Status        = @Status   
   FROM #TSLInvoiceItem   AS A  
        JOIN _TDAItemSales AS B ON B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq AND B.IsSet = '1'  
  WHERE A.WorkingTag IN ( 'A', 'U' )  
    AND A.Status = 0   
    AND NOT EXISTS (SELECT 1 FROM _TSLSetItem WHERE CompanySeq = @CompanySeq AND SetItemSeq = A.ItemSeq) -- ��Ʈ����ǰ����   
  
  
    SELECT @InvoiceSeq = InvoiceSeq    
      FROM #TSLInvoiceItem    
          
    SELECT @BizUnit = BizUnit    
      FROM #TSLInvoice     
   
    -- ǰ���ڵ尡 ���� �����ʹ� �����ش�.  
    
     -------------------------------------------    
     -- �ʼ�������üũ    
     -------------------------------------------    
         EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                               @Status      OUTPUT,    
                               @Results     OUTPUT,    
                               1                  , -- �ʼ��Է� ����Ÿ�� �Է��ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
                               @LanguageSeq       ,     
                               '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%�㺸%'            
     
         UPDATE #TSLInvoiceItem    
            SET Result        = @Results,    
                MessageType   = @MessageType,    
                Status        = @Status    
          WHERE InvoiceSeq IS NULL    
  
         EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                               @Status      OUTPUT,    
                               @Results     OUTPUT,    
                               1                  , -- �ʼ��Է� ����Ÿ�� �Է��ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
                                 @LanguageSeq       ,     
                               7,''   -- SELECT * FROM _TCADictionary WHERE Word like 'ǰ��%'            
     
         UPDATE #TSLInvoiceItem    
            SET Result        = @Results,    
                MessageType   = @MessageType,    
                Status        = @Status    
          WHERE ItemSeq IS NULL    
             OR ItemSeq = 0  
  
     --------------------------------------------------------------------------------------  
     -- ������ ���� üũ : UPDATE, DELETE �� ������ �������� ������ ����ó��  
     --------------------------------------------------------------------------------------  
     IF NOT EXISTS (SELECT 1   
                      FROM #TSLInvoiceItem AS A   
                            JOIN _TSLInvoiceItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.InvoiceSeq = B.InvoiceSeq AND A.InvoiceSerl = B.InvoiceSerl  
                     WHERE A.WorkingTag IN ('U', 'D'))  
     BEGIN  
         EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                               @Status      OUTPUT,  
                               @Results     OUTPUT,  
                               7                  , -- �ڷᰡ ��ϵǾ� ���� �ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                               @LanguageSeq       ,   
                               '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'          
  
         UPDATE #TSLInvoiceItem  
            SET Result        = @Results,  
                MessageType   = @MessageType,  
                Status        = @Status  
          WHERE WorkingTag IN ('U','D')  
    END     
    
     -------------------------------------------    
     -- �ߺ�����üũ     
     -------------------------------------------    
--     EXEC dbo._SCOMMessage @MessageType OUTPUT,        
--                           @Status      OUTPUT,        
--                           @Results     OUTPUT,        
--                           6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)        
--                           @LanguageSeq       ,         
--                           0,'�ŷ�����'          
--     UPDATE #TSLInvoiceItem        
--        SET Result        = REPLACE(@Results,'@2',RTRIM(B.InvoiceSeq)),        
--            MessageType   = @MessageType,        
--            Status        = @Status        
--       FROM #TSLInvoiceItem AS A JOIN ( SELECT S.InvoiceSeq, S.InvoiceSerl      
--                                      FROM (        
--                                            SELECT A1.InvoiceSeq, A1.InvoiceSerl      
--                                              FROM #TSLInvoiceItem AS A1        
--                                             WHERE A1.WorkingTag IN ('U')        
--                                               AND A1.Status = 0        
--                                            UNION ALL        
--                                            SELECT A1.InvoiceSeq, A1.InvoiceSerl      
--                                              FROM _TSLInvoiceItem AS A1        
--                                             WHERE A1.InvoiceSeq  NOT IN (SELECT InvoiceSeq        
--                                                                            FROM #TSLInvoiceItem         
--                                                                           WHERE WorkingTag IN ('U','D')         
--                                                                             AND Status = 0)        
--                                               AND A1.InvoiceSerl  NOT IN (SELECT InvoiceSerl        
--                                                                             FROM #TSLInvoiceItem         
--                                                                            WHERE WorkingTag IN ('U','D')         
--                                                                              AND Status = 0)        
--                                               AND A1.CompanySeq = @CompanySeq        
  --                                            ) AS S        
--                                     GROUP BY S.InvoiceSeq, S.InvoiceSerl      
--                                     HAVING COUNT(1) > 1        
--                                   ) AS B ON A.InvoiceSeq  = B.InvoiceSeq        
--                                         AND A.InvoiceSerl = B.InvoiceSerl       
  
    -------------------------------------------      
    -- ����ι��� ���� â�� �´��� üũ      
    ---------------------------------------------      
    IF @BizUnit <> 0    
    BEGIN     
        SELECT A.WHSeq    
          INTO #TmpBizWH    
          FROM _TDAWH AS A WITH(NOLOCK)     
         WHERE A.CompanySeq = @CompanySeq    
           AND A.IsNotUse <> '1'     
           AND A.BizUnit = @BizUnit    
  
        -- ����ι��� ���� ����� ǰ��â�� üũ          
        EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                              @Status      OUTPUT,      
                              @Results     OUTPUT,      
                              11               , -- �ش� @1��  @2 �� �ƴմϴ�.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 11)      
                              @LanguageSeq       ,       
                              2,'',   -- SELECT * FROM _TCADictionary WHERE Word like '%����ι�%'      
                              783,''  -- SELECT * FROM _TCADictionary WHERE Word like '%â��%'      
    
        UPDATE #TSLInvoiceItem                                 
           SET Result        = @Results     ,      
               MessageType   = @MessageType ,      
               Status        = @Status      
          FROM #TSLInvoiceItem AS A      
                LEFT OUTER JOIN #TmpBizWH AS B ON A.WHSeq    = B.WHSeq    
         WHERE A.WorkingTag IN ('A','U')      
           AND B.WHSeq IS NULL    
           AND (A.WHSeq IS NOT NULL AND A.WHSeq <> 0 )    
                                      
    END   
  
  
  
    --���ش������� ��� 2010.02.05 by ��³�  
    UPDATE #TSLInvoiceItem    
       SET STDQty = ROUND((CASE WHEN ISNULL(B.ConvDen,0) = 0 THEN 0 ELSE ISNULL(A.Qty,0) * ISNULL(B.ConvNum,0) / ISNULL(B.ConvDen,0) END),@GoodQtyDecLength)    
      FROM #TSLInvoiceItem AS A    
           JOIN _TDAItemUnit AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq    
                                              AND A.ItemSeq    = B.ItemSeq    
                                              AND A.UnitSeq    = B.UnitSeq    
           JOIN _TDAItemStock AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq    
                                               AND A.ItemSeq    = C.ItemSeq    
     WHERE A.Status = 0    
       AND ISNULL(A.Qty,0) <> 0    
       AND ISNULL(C.IsQtyChange,'') <> '1'    
    
    
    
    -- ����update---------------------------------------------------------------------------------------------------------------    
    SELECT @MaxInvoiceSerl = ISNULL(MAX(InvoiceSerl), 0)    
      FROM _TSLInvoiceItem     
     WHERE CompanySeq = @CompanySeq  
       AND InvoiceSeq = @InvoiceSeq    
    
    UPDATE #TSLInvoiceItem    
       SET InvoiceSerl = @MaxInvoiceSerl + IDX_NO    
      FROM #TSLInvoiceItem    
     WHERE WorkingTag = 'A'     
       AND Status = 0    
               
  
    IF @WorkingTag = 'D'    
        UPDATE #TSLInvoiceItem    
           SET WorkingTag = 'D'    
  
  
    -------------------------------------------    
    -- �����ڵ� 0���Ͻ� ���� �߻�  
    -------------------------------------------        
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��� ������ �߻��߽��ϴ�. �ٽ� ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 1055)      
                          @LanguageSeq         
  
    UPDATE #TSLInvoiceItem                                 
       SET Result        = @Results     ,      
           MessageType   = @MessageType ,      
           Status        = @Status      
      FROM #TSLInvoiceItem  
     WHERE Status = 0  
         AND (InvoiceSerl = 0 OR InvoiceSerl IS NULL)  
  
            
    SELECT * FROM #TSLInvoiceItem    
    
    RETURN      

GO
