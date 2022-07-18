  
IF OBJECT_ID('KPX_SLGInOutDailyItemSubCheck') IS NOT NULL 
    DROP PROC KPX_SLGInOutDailyItemSubCheck
GO 

-- v2014.12.05 

-- ����Ʈ���̺�� ���� by����õ 

-- v2013.01.04  
  
/************************************************************        
��  �� - �����ǰ�� üũ        
�ۼ��� - 2008�� 10��          
�ۼ��� - ����ȯ        
_SSLOrderItemCheck      
************************************************************/        
CREATE PROC KPX_SLGInOutDailyItemSubCheck        
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
    CREATE TABLE #TLGInOutDailyItemSub (WorkingTag NCHAR(1) NULL)          
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TLGInOutDailyItemSub'          
      
    -- üũ1, serial��Ͽ���   
      
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
   FROM #TLGInOutDailyItemSub AS A   
   --JOIN _TLGInOutSerialSub  AS B WITH(NOLOCK) ON ( A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND B.CompanySeq = @CompanySeq )  
   JOIN _TLGInOutSerialStock     AS B WITH(NOLOCK) ON ( A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND B.CompanySeq = @CompanySeq )  
  WHERE A.WorkingTag IN ( 'U', 'D' )   
    AND A.Status = 0    
   
 -- üũ1, END  
      
    -- üũ2, ������â�� ���翩��   
      
    EXEC dbo._SCOMMessage @MessageType OUTPUT,            
                          @Status      OUTPUT,            
                          @Results     OUTPUT,            
                          1001, -- select * from _TCAMessageLanguage where MessageSeq = 1001  
                          @LanguageSeq,             
                          23905, N'������â��' -- select * from _TCADictionary where Word like '%������%'  
    
 UPDATE A  
    SET A.Result   = A.OutWHName + '-' + @Results,  
     A.MessageType = @MessageType,          
     A.Status   = @Status       
   FROM #TLGInOutDailyItemSub AS A   
  WHERE A.WorkingTag IN ( 'A' )   
    AND A.Status = 0    
    AND A.InOutType = 81   
    AND NOT EXISTS (select 1 from _TDAWHSub where CompanySeq = @CompanySeq and UpWHSeq = A.OutWHSeq AND SMWHKind = 8002008 )  
      
    --select * from _TDASMinor where CompanySeq = 1 and MajorSeq = 8002   
      
    -- üũ2, END  
      
    DECLARE @InOutSeq INT--, @clock datetime   
    --select @clock = getdate()  
      
    SELECT TOP 1 @InOutSeq = InOutSeq FROM #TLGInOutDailyItemSub WHERE WorkingTag = 'A' AND Status = 0    
      
    -- üũ3, �����Է¼��� <> �����԰��Է¼���   
    IF ( (SELECT COUNT(1) FROM #TLGInOutDailyItemSub WHERE WorkingTag = 'A' AND Status = 0)   
         <>   
         (SELECT COUNT(1) FROM KPX_TPUMatOutEtcOutItem WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND InOutType IN(81,83) AND InOutSeq = @InOutSeq)  
       )   
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,            
                              @Status      OUTPUT,            
                              @Results     OUTPUT,            
                              1292, -- select * from _TCAMessageLanguage where Message like '%��%'  
                              @LanguageSeq,             
              48675, N'�����Է¼���', -- select * from _TCADictionary where Word like '%�����԰��Է�%'  
                              48676, N'�����԰��Է¼���'  
          
        UPDATE A  
        SET A.Result   = @Results,  
         A.MessageType = @MessageType,          
         A.Status   = @Status       
       FROM #TLGInOutDailyItemSub AS A   
      WHERE A.WorkingTag IN ( 'A' )   
        AND A.Status = 0    
          
    END  
      
    --select datediff( ms, @clock, getdate() )   
      
    -- üũ3, END  
      
     -------------------------------------------          
     -- Lot������ Lot�ʼ�üũüũ          
     -------------------------------------------          
     EXEC dbo._SCOMMessage @MessageType OUTPUT,          
                           @Status      OUTPUT,          
                           @Results     OUTPUT,          
                           1171               , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessage WHERE MessageSeq = 1171)          
                           @LanguageSeq       ,           
                           0,'�����'       
  
     UPDATE #TLGInOutDailyItemSub          
        SET Result        = @Results,          
            MessageType   = @MessageType,          
            Status        = @Status          
      FROM  #TLGInOutDailyItemSub A  
            JOIN (SELECT  X.InOutType, X.InOutSeq, X.InOutSerl, X.DataKind, X.InOutDataSerl  
                    FROM  #TLGInOutDailyItemSub X  
                          LEFT OUTER JOIN _TLGInOutLotSub Y WITH(NOLOCK) ON Y.CompanySeq = @CompanySeq  
                                                   AND X.InOutType  = Y.InOutType  
                                                   AND X.InOutSeq   = Y.InOutSeq  
                                                   AND X.InOutSerl  = Y.InOutSerl  
                                                   AND X.DataKind  = Y.DataKind  
                                                   AND X.InOutDataSerl  = Y.InOutDataSerl  
                  GROUP BY X.InOutType, X.InOutSeq, X.InOutSerl, X.DataKind, X.InOutDataSerl  
                  HAVING COUNT(1) = 1 ) B ON B.InOutType  = A.InOutType  
                                         AND B.InOutSeq   = A.InOutSeq  
                                         AND B.InOutSerl  = A.InOutSerl  
                                         AND B.DataKind  = A.DataKind  
                                         AND B.InOutDataSerl  = A.InOutDataSerl  
            JOIN  _TDAItemStock C ON A.ItemSeq = C.ItemSeq AND C.IsLotMng = '1'  
     WHERE  ISNULL(A.LotNo, '') = ''  
  
    -------------------------------------------    
    -- ���۱�Ÿ����üũ                                
    -------------------------------------------    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                          @Status      OUTPUT,        
                          @Results     OUTPUT,        
                          15                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 15)        
                          @LanguageSeq, 3043, ''  
  
    
    UPDATE #TLGInOutDailyItemSub        
       SET Result        = Replace(Replace(@Results, '@2', ''), '(@3)', ''),  
           MessageType   = @MessageType,        
           Status        = @Status        
      FROM #TLGInOutDailyItemSub AS A   
           JOIN KPX_TPUMatOutEtcOutItemSub AS A1 WITH(NOLOCK) ON A1.CompanySeq = @CompanySeq    
                                           AND A.InOutType  = A1.InOutType    
                                           AND A.InOutSeq  = A1.InOutSeq    
                                           AND A.InOutSerl  = A1.InOutSerl    
     WHERE A.WorkingTag IN ('D')    
       AND A.Status = 0    
       AND A.InOutType IN (81,83)  
       AND (A.DataKind = 1 AND A1.DataKind = 2)  
  
    -------------------------------------------          
    -- ���翩��üũ          
    -------------------------------------------          
    EXEC dbo._SCOMMessage @MessageType OUTPUT,          
                            @Status      OUTPUT,           
                          @Results     OUTPUT,          
                          5                  , -- �̹� @1��(��) �Ϸ�� @2�Դϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 5)          
                          @LanguageSeq       ,           
                          0,'�԰�ó��',0,'�ڷ�'            
    UPDATE #TLGInOutDailyItemSub          
       SET Result        = REPLACE(@Results,'@2',RTRIM(B.InOutSeq)),          
           MessageType   = @MessageType,          
           Status        = @Status          
      FROM #TLGInOutDailyItemSub AS A JOIN ( SELECT S.InOutSeq, S.InOutSerl, S.InOutType      
                                     FROM (          
                                           SELECT A1.InOutSeq, A1.InOutSerl, A1.InOutType        
                                             FROM #TLGInOutDailyItemSub AS A1          
                                            WHERE A1.WorkingTag IN ('A')          
                                              AND A1.Status = 0          
                                           UNION ALL          
                                           SELECT A1.InOutSeq, A1.InOutSerl, A1.InOutType        
                                             FROM KPX_TPUMatOutEtcOutItemSub AS A1          
                                            WHERE A1.InOutSeq  NOT IN (SELECT InOutSeq          
                                                                           FROM #TLGInOutDailyItemSub           
                                                                          WHERE WorkingTag IN ('U','D')           
                                                                            AND Status = 0)          
                                              AND A1.InOutSerl  NOT IN (SELECT InOutSerl          
                                                                            FROM #TLGInOutDailyItemSub           
                                                                           WHERE WorkingTag IN ('U','D')           
                                                                             AND Status = 0)          
                                              AND A1.CompanySeq = @CompanySeq          
                                          ) AS S          
                                    GROUP BY S.InOutSeq, S.InOutSerl, S.InOutType       
                                    HAVING COUNT(1) > 1          
                                  ) AS B ON A.InOutSeq  = B.InOutSeq          
                                        AND A.InOutSerl = B.InOutSerl     
                                        AND A.InOutType = B.InOutType     --InoutType�� ���ǿ��߰� 20120105 jhpark  
          
          
    SELECT @Count = COUNT(1) FROM #TLGInOutDailyItemSub WHERE WorkingTag = 'A' --@Count������(AND Status = 0 ����)  
             
    IF @Count > 0          
    BEGIN            
        -- Ű�������ڵ�κ� ����            
--        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TPUMatOutEtcOutItemSub', 'TransReqSerl', @Count          
        SELECT @Seq = ISNULL((SELECT MAX(A.InOutDataSerl)          
                                FROM KPX_TPUMatOutEtcOutItemSub AS A WITH(NOLOCK)   JOIN KPX_TPUMatOutEtcOut AS A10 WITH(NOLOCK)       
                                                          ON A.CompanySeq = A10.CompanySeq  
                                                         AND A.InOutSeq   = A10.InOutSeq  
                                                         AND A10.IsBatch <> '1'        
                               WHERE A.CompanySeq = @CompanySeq          
                                 AND A.InOutSeq  IN (SELECT InOutSeq        
                                                       FROM #TLGInOutDailyItemSub          
                                                      WHERE InOutSeq = A.InOutSeq          
                                                        AND InOutSerl = A.InOutSerl)),0)          
          
        -- Temp Talbe �� ������ Ű�� UPDATE          
        UPDATE #TLGInOutDailyItemSub          
      SET InOutDataSerl   = @Seq + A.DataSeq      
          FROM #TLGInOutDailyItemSub AS A         
         WHERE A.WorkingTag = 'A'          
           AND A.Status = 0          
    END            
          
    SELECT * FROM #TLGInOutDailyItemSub          
      
    RETURN          
  