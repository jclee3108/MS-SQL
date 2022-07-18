IF OBJECT_ID('hye_SPUDelvGetPriceSub') IS NOT NULL 
    DROP PROC hye_SPUDelvGetPriceSub
GO 

-- v2016.12.19 

-- ǰ�� �������� ��������(���Ŵܰ����_hye����) by����õ
/**********************************************************************************************  
    �ڵ������� ǰ�� �������� �������� Sub SP  
    �ۼ���     - �뿵��  
      
    [****���� �̷�****]  
    [������]    [������]   [��������]  
 ����  2010. 6. 21   Ŀ�� ���� ��Ŀ��� ������Ʈ ������� ����  
    ������  2010.11.09   �ֱٴܰ��� �������� ������ PONo, DelvNo�� Max���� �������� �κ���   
         ����(PODate, DelvDate)�� ����   
    �۱⿬      2011.01.15          �ܰ��������Ⱑ ����Ʈ���� �ٸ� ��� ����Ʈ SP�� ����Ҽ� �ֵ��� �߰� ����  
                2012.06.04          ��ȭ, ����, Maker �����Ë� ������Ʈ ���� ����  
                                    (������������ ��ǥ�ܰ��� �ƴѰ��� ���� UPDATE��, ��ǥ�ܰ��ΰ� UPDATE �ǵ���)  
    �����      2014.04.15          �ֱ� �ŷ�ó �ܰ� ���������� ��� ���� JOIN ������ ����� �Ȱɷ� �־,  
                                    ���� �Ǵ� �κ� ������.   
    ����ȯ(2014) 2014.09.26         �ֱ� �ŷ�ó �ܰ� ���������� ��� ���� JOIN ���� ����   
                                    (������������ ������¥�� Aǰ���� A,B �ŷ�ó���� ���ÿ� ���� �����Ͽ��� ��� �����߻���)       
***********************************************************************************************/     
CREATE PROCEDURE hye_SPUDelvGetPriceSub    
 @Tag  NVARCHAR(20),    
 @CompanySeq INT   ,    
 @Date  NCHAR(8) ,    
 @PUType  NVARCHAR(100),    
 @UserSeq INT         
AS          

      
DECLARE @xKorCurrSeq    INT,        
        @GetPriceType   INT,      
  @MaxRow   INT,    
  @Count   INT    
            
 -- �ڱ� ��ȭ ��������    
 EXEC dbo._SCOMEnv @CompanySeq,13,@UserSeq,@@PROCID,@xKorCurrSeq OUTPUT      
     
 IF @Tag = 'CurrSeq'    
 BEGIN    
  IF @PUType IN ('ItemBuyPrice') AND EXISTS (SELECT 1 FROM #TPUSheetData WHERE CurrSeq IS NULL)    
  BEGIN    
          
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
  
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.IsPrice = '1'    
  
  END    
  ELSE IF @PUType IN ('PUORDPOReq', 'PUORDApprovalReq')    
  BEGIN    
   -- ����    
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.CurrSeq <> @xKorCurrSeq    
      AND A.ImpType = 8008001      
  
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.CurrSeq = @xKorCurrSeq    
      AND A.ImpType = 8008001    
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
         JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.CurrSeq = @xKorCurrSeq    
      AND B.IsPrice = '1'    
      AND A.ImpType = 8008001    
           
  
          
   
    
   -- ����    
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.CurrSeq = @xKorCurrSeq    
      AND A.ImpType = 8008004    
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.CurrSeq <> @xKorCurrSeq    
      AND A.ImpType = 8008004    
          
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.CurrSeq <> @xKorCurrSeq    
      AND B.IsPrice = '1'    
      AND A.ImpType = 8008004    
           
  
    
   -- ���� ���԰��� �ƴ� ���    
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND A.ImpType NOT IN (8008001, 8008004)    
  
    
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND A.ImpType NOT IN (8008001, 8008004)    
    
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.IsPrice = '1'          
      AND A.ImpType NOT IN (8008001, 8008004)    
  
  END    
  ELSE IF @PUType IN ('Delivery', 'PUORDPO', 'PUReturn')    
  BEGIN    
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.CurrSeq = @xKorCurrSeq    
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.CurrSeq = @xKorCurrSeq    
      AND B.IsPrice = '1'    
           
  
  END      
 END       
 ELSE IF @Tag = 'StdUnitSeq'    
 BEGIN    
  IF @PUType IN ('ItemBuyPrice')    
  BEGIN    
  
   UPDATE #TPUSheetData    
      SET StdUnitSeq = B.UnitSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate   
  
  
   UPDATE #TPUSheetData    
      SET StdUnitSeq = B.UnitSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
        AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.IsPrice = '1'    
          
   
  END    
  ELSE IF @PUType IN ('PUORDPOReq', 'PUORDApprovalReq', 'Delivery', 'PUORDPO', 'PUReturn')    
  BEGIN    
  
   UPDATE #TPUSheetData    
      SET StdUnitSeq = B.UnitSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND A.CurrSeq = B.CurrSeq    
  
   UPDATE #TPUSheetData    
      SET StdUnitSeq = B.UnitSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND A.CurrSeq = B.CurrSeq    
      AND B.IsPrice = '1'    
          
  
  END    
 END      
 ELSE IF @Tag = 'MakerSeq'    
 BEGIN    
  IF @PUType IN ('ItemBuyPrice')    
  BEGIN    
  
   UPDATE #TPUSheetData    
      SET MakerSeq = B.MakerSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
  
   UPDATE #TPUSheetData    
      SET MakerSeq = B.MakerSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.IsPrice = '1'    
          
    
  END    
  ELSE IF @PUType IN ('PUORDPOReq', 'PUORDApprovalReq', 'Delivery', 'PUORDPO','PUReturn')    
  BEGIN    
  
   UPDATE #TPUSheetData    
      SET MakerSeq = B.MakerSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq AND A.CurrSeq = B.CurrSeq     
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate     
  
   UPDATE #TPUSheetData    
      SET MakerSeq = B.MakerSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq AND A.CurrSeq = B.CurrSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.IsPrice = '1'    
          
  
  END    
 END      
 ELSE IF @Tag = 'Price'    
    BEGIN    
        -- ������ ��������(�ֱ� ���Ŵܰ� ��� ����)      
        EXEC dbo._SCOMEnv @CompanySeq,6501,@UserSeq,@@PROCID,@GetPriceType OUTPUT    

        -- ���Ŵܰ���Ͽ��� �ܰ� ��������      
        IF @GetPriceType = '6072001'  -- ���Ŵܰ���Ͽ��� ��������    
        BEGIN    
            IF @PUType IN ('PUORDPOReq')     
            BEGIN    
                UPDATE #TPUSheetData    
                   SET Price = B.Price ,    
                       MinQty = B.MinQty ,    
                       StepQty  = B.StepQty    
                  FROM #TPUSheetData    AS A    
                  JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq AND A.CurrSeq = B.CurrSeq    
                 WHERE B.CompanySeq = @CompanySeq     
                   AND @Date BETWEEN B.StartDate AND B.EndDate    
                   AND B.IsPrice = '1'     
                   AND A.Price = 0           
      
                UPDATE #TPUSheetData    
                   SET Price = B.Price ,    
                       MinQty = B.MinQty ,    
                       StepQty  = B.StepQty    
                  FROM #TPUSheetData    AS A    
                  JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq AND A.CurrSeq = B.CurrSeq    
                 WHERE B.CompanySeq = @CompanySeq     
                   AND @Date BETWEEN B.StartDate AND B.EndDate    
                   AND A.Price = 0    
            END    
            ELSE IF @PUType IN ('PUORDApprovalReq')     
            BEGIN    
     
                UPDATE #TPUSheetData    
                   SET Price = B.Price ,    
                       MinQty = B.MinQty ,    
                       StepQty  = B.StepQty    
                  FROM #TPUSheetData    AS A    
                 JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq AND A.CurrSeq = B.CurrSeq  AND A.UnitSeq = B.UnitSeq  -- ��������� ���� �� �� �ֵ��� �߰�
                 WHERE B.CompanySeq = @CompanySeq     
                   AND @Date BETWEEN B.StartDate AND B.EndDate    
                   AND A.Price = 0     
                
                UPDATE #TPUSheetData    
                   SET Price = B.Price ,    
                       MinQty = B.MinQty ,    
                       StepQty  = B.StepQty    
                  FROM #TPUSheetData    AS A    
                  JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq AND A.CurrSeq = B.CurrSeq  -- ǰ�ǿ��� ��ȭ���� �߰�  12.04.23 BY �輼ȣ  
                 WHERE B.CompanySeq = @CompanySeq     
                   AND @Date BETWEEN B.StartDate AND B.EndDate    
                   AND B.IsPrice = '1'     
                   AND A.Price = 0         
      
                UPDATE #TPUSheetData    
                   SET Price = B.Price ,    
                       MinQty = B.MinQty ,    
                       StepQty  = B.StepQty    
                  FROM #TPUSheetData    AS A    
                  JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq AND A.CurrSeq = B.CurrSeq   -- ǰ�ǿ��� ��ȭ���� �߰�  12.04.23 BY �輼ȣ    
                 WHERE B.CompanySeq = @CompanySeq     
                   AND @Date BETWEEN B.StartDate AND B.EndDate    
                   AND A.Price = 0    
            END    
            ELSE IF @PUType IN ('Delivery', 'PUORDPO', 'ImportBargain', 'LCAdd', 'PUReturn')     
            BEGIN    
     
                ---- ������ ���� �� ��쿡 ���شܰ����ο� üũ�� �ݾ׸� �������µ�, ���� �ŷ�ó�� ���� ǰ�� ������ �ٸ� ��쿡�� �Ȱ��� �ܰ��� �������Ƿ�,----  
                ---- ������ ��, �Ͽ�, ȭ����� ������ ���� �� ��� �׿� �´� �ܰ��� ���������� �� ---- 2014.04.21 ����� �߰�  
                UPDATE #TPUSheetData    
                   SET Price = B.Price ,    
                       MinQty = B.MinQty ,    
                       StepQty  = B.StepQty    
                  FROM #TPUSheetData    AS A    
                  JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq   
                                                AND A.CustSeq = B.CustSeq   
                                                AND A.CurrSeq = B.CurrSeq   
                                                AND A.UnitSeq = B.UnitSeq   
                 WHERE B.CompanySeq = @CompanySeq     
                   AND @Date BETWEEN B.StartDate AND B.EndDate    
                   --AND B.IsPrice = '1'     
                   AND A.Price = 0    
                
                UPDATE #TPUSheetData    
                   SET Price = B.Price ,    
                       MinQty = B.MinQty ,    
                       StepQty  = B.StepQty    
                  FROM #TPUSheetData    AS A    
                  JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq AND A.CurrSeq = B.CurrSeq    
                 WHERE B.CompanySeq = @CompanySeq     
                   AND @Date BETWEEN B.StartDate AND B.EndDate    
                   AND B.IsPrice = '1'     
                   AND A.Price = 0         
      
                UPDATE #TPUSheetData    
                   SET Price = B.Price ,    
                       MinQty = B.MinQty ,    
                       StepQty  = B.StepQty    
                  FROM #TPUSheetData    AS A    
                  JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq AND A.CurrSeq = B.CurrSeq    
                 WHERE B.CompanySeq = @CompanySeq     
                   AND @Date BETWEEN B.StartDate AND B.EndDate    
                   AND A.Price = 0    
      
                UPDATE #TPUSheetData    
                   SET Price = B.Price ,    
                       MinQty = B.MinQty ,    
                       StepQty  = B.StepQty    
                  FROM #TPUSheetData    AS A    
                  JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq      
                 WHERE B.CompanySeq = @CompanySeq     
                   AND @Date BETWEEN B.StartDate AND B.EndDate    
                   AND A.Price = 0    
            END    
            
            -- ���Ŵܰ����_hye ���� by����õ 
            DECLARE @SKCustSeq INT 
            SELECT @SKCustSeq = (SELECT TOP 1 EnvValue FROM hye_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 5) 

            UPDATE A
               SET Price = B.YSSPrice 
              from #TPUSheetData AS A 
              JOIN hye_TPUBaseBuyPriceItem AS B ON ( B.CompanySeq = @CompanySeq 
                                                 AND B.ItemSeq = A.ItemSeq 
                                                 AND B.UnitSeq = A.UnitSeq 
                                                 AND B.CurrSeq = A.CurrSeq 
                                                 AND B.UMDVGroupSeq = A.UMDVGroupSeq 
                                                    ) 
              LEFT OUTER JOIN _TDAItemPurchase  AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
              LEFT OUTER JOIN _TDAItemUserDefine AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = B.ItemSeq AND D.MngSerl = 1000005 )     
             WHERE @Date BETWEEN B.SrtDate AND B.EndDate 
               AND C.PurCustSeq = @SKCustSeq 
               AND ISNULL(C.PurCustSeq,0) <> 0 
               AND (D.MngValText = '1' OR D.MngValText = 'True')
            -- ���Ŵܰ����_hye ����, END 
           
        END    
        ELSE IF @GetPriceType = '6072002'   -- ���� ����ó �ֱ� �ܰ� ����(����)  
        BEGIN      
            IF @PUType IN ('PUORDPOReq')    
            BEGIN    
                SELECT @MaxRow = MAX(IDX_NO) FROM #TPUSheetData    
                SELECT @Count  = MIN(IDX_NO) FROM #TPUSheetData   
                
                WHILE ( 1 = 1)    
                BEGIN    
                    IF @Count > @MaxRow BREAK    
            
                    UPDATE #TPUSheetData    
                       SET Price = B.Price    
                      FROM #TPUSheetData  AS A    
                      JOIN _TPUORDPOItem AS B ON A.ItemSeq = B.ItemSeq    
                      JOIN _TPUORDPO  AS C ON B.CompanySeq = C.CompanySeq AND B.POSeq = C.POSeq    
                     WHERE B.CompanySeq = @CompanySeq           
                       AND A.IDX_NO  = @Count         
                       AND A.CurrSeq = C.CurrSeq  
                       AND C.PONo= (SELECT MAx(PONo) 
                                      FROM _TPUORDPO AS A   
                                      JOIN _TPUORDPOITem AS B ON A.CompanySeq = B.CompanySeq AND A.POSeq = B.POSeq            
                                      JOIN ( SELECT ISNULL(MAX(B.PODate), 0) PODate, A.ItemSeq AS ItemSeq, B.CustSeq as CustSeq  
                                               FROM _TPUORDPOItem AS A    
                                               JOIN _TPUORDPO  AS B ON A.CompanySeq = B.CompanySeq AND A.POSeq = B.POSeq    
                                               JOIN #TPUSheetData AS C ON A.ItemSeq = C.ItemSeq AND B.CustSeq = C.CustSeq  -- 2014.04.15 ����� �ŷ�ó�� �Ȱɷ� �־ �ɾ���   
                                               WHERE A.CompanySeq = @CompanySeq    
                                                 AND C.IDX_NO  = @Count    
                                                 AND B.CurrSeq = C.CurrSeq  
                                                 AND A.Price <> 0 
                                               Group by A.ItemSeq, B.CustSeq
                                           ) AS C ON A.PODate = C.PODate AND B.ItemSeq = C.ItemSeq AND A.Custseq = C.Custseq -- �ŷ�ó ��ȸ���� �߰� : 20140926 ����ȯ2014      
                                     WHERE A.CompanySeq = @CompanySeq ) -- CompanySeq �� ���ó� �ѹ� �� �ɾ�� �ȴ�( �ٸ� ���� ���� ������ ��찡 ���� )   
                
                    SELECT @Count = @Count + 1    
                END -- while end   
            END  -- @PUType end 
            ELSE    
            BEGIN    
                SELECT @MaxRow = MAX(IDX_NO) FROM #TPUSheetData    
                SELECT @Count  = MIN(IDX_NO) FROM #TPUSheetData    
                
                WHILE ( 1 = 1)    
                BEGIN    
                    IF @Count > @MaxRow BREAK    
  
                    UPDATE #TPUSheetData    
                       SET Price = B.Price    
                      FROM #TPUSheetData AS A    
                      JOIN _TPUORDPOItem AS B ON A.ItemSeq = B.ItemSeq    
                      JOIN _TPUORDPO  AS C ON B.CompanySeq = C.CompanySeq AND B.POSeq = C.POSeq    
                     WHERE B.CompanySeq = @CompanySeq           
                       AND A.IDX_NO  = @Count         
                       AND A.CurrSeq = C.CurrSeq    
                       AND A.CustSeq = C.CustSeq    
                       AND C.PONo = (SELECT MAx(PONo) 
                                       FROM _TPUORDPO AS A   
                                       JOIN _TPUORDPOITem AS B ON A.CompanySeq = B.CompanySeq AND A.POSeq = B.POSeq            
                                       JOIN ( SELECT ISNULL(MAX(B.PODate), 0) PODate, A.ItemSeq AS ItemSeq, B.CustSeq AS CustSeq  
                                                FROM _TPUORDPOItem AS A    
                                                JOIN _TPUORDPO  AS B ON A.CompanySeq = B.CompanySeq AND A.POSeq = B.POSeq    
                                                JOIN #TPUSheetData AS C ON A.ItemSeq  = C.ItemSeq AND B.CustSeq = C.CustSeq   -- 2014.04.15 ����� �ŷ�ó�� �Ȱɷ� �־ �ɾ���   
                                               WHERE A.CompanySeq = @CompanySeq    
                                                 AND C.IDX_NO  = @Count    
                                                 AND B.CurrSeq = C.CurrSeq  
                                                 AND A.Price <> 0 
                                               Group by A.ItemSeq, B.CustSeq
                                            ) AS C ON A.PODate = C.PODate AND B.ItemSeq = C.ItemSeq AND A.Custseq = C.Custseq -- �ŷ�ó ��ȸ���� �߰� : 20140926 ����ȯ2014       
                                      WHERE A.CompanySeq = @CompanySeq   ) -- CompanySeq �� ���ó� �ѹ� �� �ɾ�� �ȴ�( �ٸ� ���� ���� ������ ��찡 ���� )   
                
                    SELECT @Count = @Count + 1    
                END -- while end 
            END    
        END  
        ELSE IF @GetPriceType = '6072003'   -- ���� ����ó �ֱ� �ܰ� ����(��ǰ)  
        BEGIN    
            IF @PUType IN ('PUORDPOReq')    
            BEGIN    
                SELECT @MaxRow = MAX(IDX_NO) FROM #TPUSheetData    
                SELECT @Count  = MIN(IDX_NO) FROM #TPUSheetData   
                
                WHILE ( 1 = 1)    
                BEGIN    
                    
                    IF @Count > @MaxRow BREAK    
            
                    UPDATE #TPUSheetData    
                       SET Price = B.Price    
                      FROM #TPUSheetData    AS A    
                      JOIN _TPUDelvItem     AS B ON A.ItemSeq = B.ItemSeq    
                      JOIN _TPUDelv         AS C ON B.CompanySeq = C.CompanySeq AND B.DelvSeq = C.DelvSeq    
                     WHERE B.CompanySeq = @CompanySeq           
                       AND A.IDX_NO  = @Count         
                       AND A.CurrSeq = C.CurrSeq  
                       AND C.DelvNo= (SELECT MAx(DelvNo) 
                                        FROM _TPUDelv AS A   
                                        JOIN _TPUDelvItem AS B ON A.CompanySeq = B.CompanySeq AND A.DelvSeq = B.DelvSeq            
                                        JOIN ( SELECT ISNULL(MAX(B.DelvDate), 0) DelvDate, A.ItemSeq AS ItemSeq, B.CustSeq as CustSeq  
                                                 FROM _TPUDelvItem AS A    
                                                 JOIN _TPUDelv  AS B ON A.CompanySeq = B.CompanySeq AND A.DelvSeq = B.DelvSeq    
                                                 JOIN #TPUSheetData AS C ON A.ItemSeq = C.ItemSeq AND B.CustSeq = C.CustSeq   -- 2014.04.15 ����� �߰�    
                                                WHERE A.CompanySeq = @CompanySeq    
                                                  AND C.IDX_NO  = @Count    
                                                  AND B.CurrSeq = C.CurrSeq  
                                                  AND A.Price <> 0 
                                                Group by A.ItemSeq, B.CustSeq
                                             ) AS C ON A.DelvDate = C.DelvDate AND B.ItemSeq = C.ItemSeq AND A.Custseq = C.Custseq -- �ŷ�ó ��ȸ���� �߰� : 20140926 ����ȯ2014      
                                       WHERE A.CompanySeq = @CompanySeq) -- CompanySeq �� ���ó� �ѹ� �� �ɾ�� �ȴ�( �ٸ� ���� ���� ������ ��찡 ���� )        
                  
                    SELECT @Count = @Count + 1    
                END -- while end 
            END -- @PUType end 
            ELSE    
            BEGIN    
                SELECT @MaxRow = MAX(IDX_NO) FROM #TPUSheetData    
                SELECT @Count  = MIN(IDX_NO) FROM #TPUSheetData   
      
                WHILE ( 1 =  1)    
                BEGIN    
                    IF @Count > @MaxRow BREAK    
             
                    UPDATE #TPUSheetData    
                       SET Price = B.Price    
                      FROM #TPUSheetData AS A    
                      JOIN _TPUDelvItem  AS B ON A.ItemSeq = B.ItemSeq    
                      JOIN _TPUDelv  AS C ON B.CompanySeq = C.CompanySeq AND B.DelvSeq = C.DelvSeq    
                     WHERE B.CompanySeq = @CompanySeq           
                       AND A.IDX_NO  = @Count         
                       AND A.CurrSeq = C.CurrSeq    
                       AND A.CustSeq = C.CustSeq    
                       AND C.DelvNo= (SELECT MAx(DelvNo) 
                                        FROM _TPUDelv AS A   
                                        JOIN _TPUDelvItem AS B ON A.CompanySeq = B.CompanySeq AND A.DelvSeq = B.DelvSeq            
                                        JOIN ( SELECT ISNULL(MAX(B.DelvDate), 0) DelvDate, A.ItemSeq AS ItemSeq, B.CustSeq as Custseq  
                                                 FROM _TPUDelvItem AS A    
                                                 JOIN _TPUDelv  AS B ON A.CompanySeq = B.CompanySeq AND A.DelvSeq = B.DelvSeq    
                                                 JOIN #TPUSheetData AS C ON A.ItemSeq = C.ItemSeq AND B.CustSeq = C.CustSeq  -- 2014.04.15 ����� �߰�   
                                                WHERE A.CompanySeq = @CompanySeq    
                                                  AND C.IDX_NO  = @Count    
                                                  AND B.CurrSeq = C.CurrSeq  
                                                  AND A.Price <> 0 
                                                Group by A.ItemSeq, B.CustSeq
                                             ) AS C ON A.DelvDate = C.DelvDate AND B.ItemSeq = C.ItemSeq AND A.CustSeq = C.CustSeq -- �ŷ�ó ��ȸ���� �߰� : 20140926 ����ȯ2014     
                                       WHERE A.CompanySeq = @CompanySeq ) -- CompanySeq �� ���ó� �ѹ� �� �ɾ�� �ȴ�( �ٸ� ���� ���� ������ ��찡 ���� )         
    
                    SELECT @Count = @Count + 1    
                END -- while end 
            END -- else end 
        END  -- @GetPriceType 
    END -- @Tag
    
RETURN


go 