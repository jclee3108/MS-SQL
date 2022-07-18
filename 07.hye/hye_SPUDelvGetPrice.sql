IF OBJECT_ID('hye_SPUDelvGetPrice') IS NOT NULL 
    DROP PROC hye_SPUDelvGetPrice
GO 

-- v2016.12.19 

-- ���Ŵܰ� ��������(���Ŵܰ����_hye ����) by����õ 
/**********************************************************************************************
    �ڵ������� ǰ�� �������� ��������
    �ۼ���     - �뿵��
    ������     - ����
    ������     - 2010. 6. 21 -- Ŀ�� ���ְ� ������Ʈ ������� ����  
    ��������   - 2011. 3. 18 -- hkim ( �ֱٱ��Űŷ�ó�� ������ �� ��ȭ�� �ڱ� ��ȭ�� �ɸ��� �κ��� �����ؼ� ����)  
               - 2011. 6. 20 -- �輭��(â�������� �켱���� �������� - 1���� �Ƿںμ��� �Һз��� ���ű⺻â�� �߰�)  
               - 2011. 7. 15 -- �輼ȣ(���Ź�ǰ�Է�ȭ�鿡�� ������(6518��ǰ�⺻�ܰ� ��������) ������ �ܰ� ���÷��� �߰� )  
               - 2012.01. 02 -- �輼ȣ(���Ź��ֿ��� ��ǰâ�����ö�- ǰ�񺰱⺻â�� �������� ���� ����
                                      ::�α������� ����ι��� â�� �������� ������ ����ι�0���� �ɷ��ִ� â�� ����������, �ߺ������������ â������������)  
               - 2014.06.25  -- ����� ����ǰ�� ��Ʈ���� �ش� ǰ���� ���Ŵܰ���Ͽ� ��ϵ� �����Ͱ� ���ٸ�, �ŷ�ó�� �� ������ ������µ�,
                                       �������� �������� ���� �⺻����ó�� ���� ������ ����
               - 2014.06.30  -- ������ ( ��ǥ�ܰ����ο� üũ�� �Ǿ� �ְ� ���� ǰ��� �ŷ�ó�� ��ϵ� ������ �����鼭 PreLeadTime + LeadTime + PostLeadTime ���� ������� �����ϼ��� ǥ�� )                                                                        
               - 2015.04.03  -- ���ظ� ( ���ſ�û���� ǰ��Jump�� �������� ���� ��û�� ��ȭ�� ���� ������ �߰��Ǿ� �ִ� �κж����� ��ǥ�ܰ��� ��ȭ�� ������� ���ϰ� �־���
                                         �� �κ��� �������� ��� ��û�� ��ȭ�� �ڱ���ȭ�� �ƴ� ��� ������Ʈ �ϵ��� ����) 
               - 2015.04.10  -- ������ (����ǰ�ǿ��� ���Űŷ�ó�� �ٽ� ���� �� �������� ��� ��ȭ�� ������Ʈ �Ǿ� �ش籸���� �ּ�ó�� �Ϸ� ������, 
                                        ������ �߰��� ������ �� �� ���� �ŷ�ó�� 0 �� ����� ���� �߰�) - ������  201504090167 
               - 2015.08.31  -- ������ (��� ������ �߰��� if���� ���Ŵܰ���� �����Ͱ� �������� ���� �� �ش� ���� �����ϵ��� ���� �߰�
                                        -> _SPUBaseGetPriceSub���� ���Ŵܰ������ ��ȭ�� UPDATE �Ǿ������� �ұ��ϰ� ��� ������ �� ����ǰ� �־���) - Ƽ������ 201508270042                                                                    
               - 2015.10.08  -- �ڼ��� (���� Temp���̺� �� â�����ڵ� �־��ְ� ���� �����ϵ��� ���� - KPX�׸��ɹ�Į
               - 2015.10.21  -- �ڼ��� (���� ǰ�� ���Ͽ� �ٸ� ����ι����� ��ǰó�� �� â�������� ������ ���� â�� ������ ��, ����ι����� �ɾ� ������ �� �ֵ��� ���� -�ۿ�
               - 2016.05.10  -- �ڼ��� (�����ڱ��� ������ ��, ȭ�鿡�� ������ ������ �ִٸ�, ǰ�񸶽��ͱ��� �����ڱ��� ���� ���� ���, ȭ�鿡�� ������ ������ ����)
			   - 2016.11.10  -- ������ (Maker���� �������� �켱 ���� ����
			                           1. ȭ��󿡼� ���� �� / 2. ���Ŵܰ����(�ش� ǰ��,�ŷ�ó,��ȭ�� ��ġ�ϴ� Maker����) / 3. ������-��������-Maker)
***********************************************************************************************/
CREATE PROC dbo.hye_SPUDelvGetPrice 
    @xmlDocument    NVARCHAR(MAX),
    @xmlFlags       INT = 0,        
    @ServiceSeq     INT = 0,        
    @WorkingTag     NVARCHAR(10)= 0,         
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0
AS
    SET NOCOUNT ON

    
    DECLARE @docHandle      INT,        
            @PUType         NVARCHAR(200),        
            @GetPriceType   INT,        
            @BizUnit        INT,       
            @pDate          NCHAR(8) ,          
            @xKorCurrSeq    INT,      
            @xForCurrSeq    INT,      
            @MaxRow         INT,      
            @Count          INT,      
            @wItemSeq       INT,      
            @wCustSeq2      INT,  
            @CurrSeq        INT,         -- 2011. 3. 18 hkim (�ֱٰŷ�ó ������ �� ��ȭ�� �ɾ��ֱ� ����)  
            @WHSeq   INT,  
            @GetReturnPriceType INT,      -- 2011. 7. 15 �輼ȣ (���Ź�ǰ�Է�ȭ�鿡�� �ܰ��������� ������)   
            @CostEnv        INT,            -- ������ ȯ�漳��            -- 11.07.15 �輼ȣ �߰� (���� ���ܰ� ������������)  
            @IFRSEnv        INT,            -- IFRS ��� ���� ȯ�漳��      -- 11.07.15 �輼ȣ �߰� (���� ���ܰ� ������������)  
            @SMCostMng      INT,  
            @MatPriceEnv    INT,            -- ����ܰ�������             -- 11.07.15 �輼ȣ �߰� (���� ���ܰ� ������������)  
            @GoodsPriceEnv  INT             -- ��ǰ�ܰ�������             -- 11.07.15 �輼ȣ �߰� (���� ���ܰ� ������������)  
   
  
    -- ���� ����Ÿ ��� ����(����ǰ�� �ϰ������� ��쿡�� �ӽ����̺� ���� X        
    IF @WorkingTag <> 'AUTO'        
    BEGIN        
        CREATE TABLE #TPUBaseGetPrice (WorkingTag NCHAR(1) NULL)        
        EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUBaseGetPrice'    
    END  
    IF @@ERROR <> 0 RETURN        
    
    
    --select * from #TPUBaseGetPrice 
    --return 
    CREATE TABLE #TPUSheetData       
    (      
        IDX_NO    INT    ,   
        ComPanySeq INT,     
        ItemSeq   INT    ,      
        AssetSeq  INT    ,      
        CustSeq   INT    ,      
        MakerSeq  INT    ,      
        CurrSeq   INT    ,      
        STDUnitSeq  INT    ,      
        ImpType   INT    NULL,      
        Price   DECIMAL(19,5) ,      
        StdUnitQty  DECIMAL(19,5) ,      
        MinQty   DECIMAL(19,5) ,      
        StepQty   DECIMAL(19,5) ,      
        QCType   INT    ,      
        PUStatus  NVARCHAR(10) NULL,      
        PUResults  NVARCHAR(100) NULL,      
        WHSeq   INT    NULL,      
        HSNo   NVARCHAR(40) NULL,      
        ExRate   DECIMAL(19,5) ,      
        LeadTime  DECIMAL(19,5),  
        DeptSeq   INT  ,
        UnitSeq     INT,
        GetImpType  INT,         --2016.05.10 �ڼ��� ::ȭ�鿡�� ���� �����ڱ��а� (���� ImpType �� ���� �Ʒ� ������ ����� Ÿ�� ����)
        UMDVGroupSeq    INT
    )     
   
     
    -- ���Ŵܰ� ��� ȭ�鿡�� ȣ���        
    IF EXISTS (SELECT 1 FROM #TPUBaseGetPrice WHERE PUType = 'PUBasePrice')        
        GOTO PUBasePrice_Proc   
              
    SELECT @PUType = (SELECT TOP 1 PUType FROM #TPUBaseGetPrice)        
                   
    -- ������ ��������(�ֱ� ���Ŵܰ� ��� ����)        
    EXEC dbo._SCOMEnv @CompanySeq,6501,@UserSeq,@@PROCID,@GetPriceType OUTPUT    
    
    
     
    -- ��ȭ ��������        
    EXEC dbo._SCOMEnv @CompanySeq,13,@UserSeq,@@PROCID,@xKorCurrSeq OUTPUT        
    EXEC dbo._SCOMEnv @CompanySeq,12,@UserSeq,@@PROCID,@xForCurrSeq OUTPUT        

    -- ���� ��������
    SELECT @pDate = ISNULL(DATE, CONVERT(NCHAR(8),GETDATE(),112)) FROM #TPUBaseGetPrice        

    -- ����κ� ��������
    SELECT @BizUnit = ISNULL(BizUnit, 0) FROM #TPUBaseGetPrice   

    INSERT INTO #TPUSheetData(IDX_NO, CompanySeq,ItemSeq , MakerSeq , STDUnitSeq , AssetSeq , LeadTime ,      
                              CustSeq , QCType , ExRate  , StdUnitQty, CurrSeq ,      
                              MinQty , StepQty , Price , DeptSeq, UnitSeq, WHSeq, GetImpType, UMDVGroupSeq)      
    SELECT A.IDX_NO, @CompanySeq, A.ItemSeq , ISNULL(A.MakerSeq,0) , ISNULL(D.STDUnitSeq, 0) , B.AssetSeq , 
           CASE WHEN ISNULL(E.PreLeadTime,0)+ISNULL(E.LeadTime,0)+ISNULL(E.PostLeadTime,0) = 0 THEN ISNULL(C.DelvDay,0)
           ELSE ISNULL(E.PreLeadTime,0)+ISNULL(E.LeadTime,0)+ISNULL(E.PostLeadTime,0) END AS LeadTime ,         --���� �ϼ� ���� 2014.06.30 ������  
           ISNULL(A.CustSeq, 0), 6035001, A.ExRate, ISNULL(A.StdUnitQty, 1), ISNULL(A.CurrSeq, 0),      
           ISNULL(C.MinQty, 1)  , ISNULL(C.StepQty, 1), 0 , A.DeptSeq    , A.UnitSeq , A.WHSeq, ISNULL(A.SMImpType,0), CONVERT(INT,A.Memo2)
      FROM #TPUBaseGetPrice                 AS A
           JOIN _TDAItem                    AS B ON A.ItemSeq   = B.ItemSeq
           LEFT OUTER JOIN _TDAItemPurchase AS C ON B.CompanySeq  = C.ComPanySeq    
                                                AND B.ItemSeq   = C.ItemSeq
           LEFT OUTER JOIN _TDAItemDefUnit  AS D ON B.CompanySeq  = D.ComPanySeq
                                                AND B.ItemSeq   = D.ItemSeq
                                                AND D.UMModuleSeq = '1003001'
           LEFT OUTER JOIN _TPUBASEBuyPriceItem  AS E WITH(NOLOCK) ON E.CompanySeq = @CompanySeq
                                                                  AND A.ItemSeq    = E.ItemSeq      /** ��ǥ�ܰ����ο� üũ�� �Ǿ� �ְ� **/
                                                                  AND E.IsPrice    = '1'            /** PreLeadTime + LeadTime + PostLeadTime ���� �������
                                                                                                        �����ϼ��� ǥ�� 2014.06.30 ������ �߰�**/
     WHERE B.CompanySeq = @CompanySeq
    ORDER BY A.IDX_NO

    -- ����ǰ�ǿ��� �ܰ���� �ȵȰǵ��� �׳� �Է� �� �����ֵ��� �߰� 2011. 1. 10 hkim  
    IF @GetPriceType = '6072001' AND @PUType = 'PUORDApprovalReq' AND NOT EXISTS (SELECT 1 FROM #TPUBaseGetPrice          AS A   
                                                          JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq  
                                                   WHERE  B.CompanySeq = @CompanySeq   
                                                     AND  @pDate BETWEEN B.StartDate AND B.EndDate)  
    BEGIN   
        -- ���Ŵܰ������ �Ǿ� ���� ���� �� �����ڱ��� �������� ���ؼ� �߰� 2011. 4. 8 hkim  
        UPDATE #TPUBaseGetPrice      
           SET SMImpType = CASE ISNULL(SMInOutKind, 0) WHEN 8007001 THEN 8008001 WHEN 0 THEN 8008001 ELSE 8008004 END         
          FROM #TPUBaseGetPrice AS A      
               JOIN _TDAItem AS B ON A.ItemSeq = B.ItemSeq        
         WHERE B.CompanySeq = @CompanySeq      
           AND A.SMImpType IS NULL OR A.SMImpType = 0          
        
        UPDATE #TPUBaseGetPrice
           SET CurrSeq = B.CurrSeq
          FROM #TPUBaseGetPrice AS A
               JOIN _TDACurr    AS B ON B.CompanySeq = @CompanySeq
                                    AND B.CurrName   = 'USD'    -- 2014.06.25 ����� ���� �����ڱ����� ���� �ΰ�쿡 
                                                                -- Default ������ USD ��ȭ�� �ѷ������� CurrSeq ������Ʈ �۾�
         WHERE A.SMImpType = 8008004
        
        -- ��ȭ�� 0�� ���� �⺻ ��ȭ  
        UPDATE #TPUBaseGetPrice  
          SET CurrSeq  = @xKorCurrSeq   ,  
              CurrName = (SELECT TOP 1 CurrName FROM _TDACurr WHERE CompanySeq = @CompanySeq AND CurrSeq = @xKorCurrSeq )  
         WHERE CurrSeq = 0 OR CurrSeq IS NULL  
            -- ȯ���� 0�� ���� �⺻ ��ȭ  
         UPDATE #TPUBaseGetPrice  
           SET ExRate = 1  
         WHERE ExRate = 0 OR ExRate IS NULL  
        
        
        -- �ŷ�ó�� ���Ŵܰ���Ͽ� ��� �Ǿ� ���� ���� ��쿡 ������ - �������� ���� �⺻����ó�� ���������� ���� 2014.06.25 �����
        UPDATE #TPUBaseGetPrice
           SET CustSeq = ISNULL(B.PurCustSeq,0)
          FROM #TPUBaseGetPrice AS A
               JOIN _TDAItemPurchase AS B ON A.ItemSeq = B.ItemSeq
         WHERE B.CompanySeq = @CompanySeq                                         
           AND A.CustSeq    = 0   
                 
                   
            /**ǰ���� �������� �ѹ��� ó���ϱ� ���� �ٷ� Return �ϴ� �κ� �ּ�ó�� 2012.06.19 by ��³� **/    
            --SELECT  * FROM #TPUBaseGetPrice  
            --RETURN  
    END                                                           
                                 
 -- �ڵ����� �� ������ ������ ǰ���� ������ �ߴ�   
 IF NOT EXISTS (SELECT 1 FROM #TPUSheetData)  
 BEGIN  
  SELECT * FROM #TPUSheetData  
  RETURN        
 END  
  



  
    IF @GetPriceType = '6072001' OR  @PUType = 'PUReturn'  -- �ֱٱ��Ŵܰ� ��� ���� ��� �ŷ�ó ��������      
    BEGIN      
        IF @PUType IN ('ImportBargain', 'LCAdd', 'PUORDPO', 'Delivery', 'PUORDApprovalReq', 'PUReturn')      
        BEGIN      
            UPDATE #TPUSheetData      
               SET CustSeq = ISNULL(B.CustSeq, 0)      
              FROM #TPUSheetData    AS A      
                   JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq      
             WHERE B.CompanySeq = @CompanySeq      
               AND @pDate BETWEEN B.StartDate AND B.EndDate      
               AND B.IsPrice = '1'       
               AND A.CustSeq = 0      
                  
            UPDATE #TPUSheetData      
               SET CustSeq = ISNULL(B.CustSeq, 0)      
              FROM #TPUSheetData    AS A      
                   JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq      
             WHERE B.CompanySeq = @CompanySeq      
               AND @pDate BETWEEN B.StartDate AND B.EndDate      
               AND A.CustSeq = 0            
        END      
    END      
    ELSE IF @GetPriceType = '6072002'  -- �ֱٴܰ�(����) ���� �ŷ�ó ��������      
    BEGIN      
        IF EXISTS (SELECT 1 FROM #TPUSheetData WHERE CustSeq = 0) AND @PUType IN ('PUORDApprovalReq')      
        BEGIN      
            SELECT @MaxRow = MAX(IDX_NO) FROM #TPUSheetData      
            SELECT @Count  = 0      
              
            WHILE( 1 = 1 )      
            BEGIN      
                IF @Count > @MaxRow BREAK      
              
                IF EXISTS (SELECT 1 FROM #TPUSheetData WHERE IDX_NO = @Count AND CustSeq = 0)       
                BEGIN       
                    SELECT @wItemSeq = ItemSeq FROM #TPUSheetData WHERE IDX_NO = @Count      
                    SELECT @CurrSeq  = CurrSeq FROM #TPUSheetData WHERE IDX_NO = @Count       -- 2011. 3. 18 hkim ��ȭ �ɾ �ŷ�ó ����������   
           
                    SELECT @wCustSeq2 = ISNULL(B.CustSeq, 0)        
                      FROM _TPUORDPOItem  AS A        
                           JOIN _TPUORDPO AS B ON A.CompanySeq = B.CompanySeq        
                                              AND A.POSeq      = B.POSeq        
                     WHERE A.CompanySeq = @CompanySeq        
                       AND A.ItemSeq    = @wItemSeq        
                       AND B.CurrSeq    = @CurrSeq        
                       AND A.POSeq      = ( SELECT TOP 1 ISNULL(B.POSeq, 0) FROM _TPUORDPOItem  AS A        
                                                                                 JOIN _TPUORDPO AS B ON A.CompanySeq = B.CompanySeq        
                                                                                                    AND A.POSeq      = B.POSeq        
                                                                           WHERE A.CompanySeq = @CompanySeq        
                                                                             AND A.ItemSeq    = @wItemSeq        
                                                                             AND B.CurrSeq    = @CurrSeq        
                                                                             AND B.PONo       = (SELECT TOP 1 ISNULL(MAX(B.PONo), '0') FROM _TPUORDPOItem  AS A        
                                                                                                                                            JOIN _TPUORDPO AS B ON A.CompanySeq  = B.CompanySeq        
                                                                                                                                                               AND A.POSeq     = B.POSeq        
                                                                                                                                      WHERE A.CompanySeq = @CompanySeq        
                                                                                                                                        AND @wItemSeq IN (A.ItemSeq)        
                                                                                                                                        AND B.CurrSeq    = @CurrSeq) )       
                    UPDATE #TPUSheetData                                                                                                         
                       SET CustSeq = @wCustSeq2      
                      FROM #TPUSheetData      
                     WHERE IDX_NO = @Count    
                END      
              
            SELECT @Count = @Count + 1                   
            SELECT @wCustSeq2 = 0           -- 0 ���� �ʱ�ȭ   
              
            END      
        END    
    END    
    ELSE IF @GetPriceType = '6072003'  -- �ֱٴܰ�(��ǰ) ���� �ŷ�ó ��������      
    BEGIN      
        IF EXISTS (SELECT 1 FROM #TPUSheetData WHERE CustSeq = 0) AND @PUType IN ('PUORDApprovalReq')      
        BEGIN      
            SELECT @MaxRow = MAX(IDX_NO) FROM #TPUSheetData      
            SELECT @Count  = 0      
            WHILE( 1 = 1 )      
            BEGIN      
                IF @Count > @MaxRow BREAK      
          
                IF EXISTS (SELECT 1 FROM #TPUSheetData WHERE IDX_NO = @Count AND CustSeq = 0)       
                BEGIN       
                    SELECT @wItemSeq = ItemSeq FROM #TPUSheetData WHERE IDX_NO = @Count      
                    SELECT @CurrSeq  = CurrSeq FROM #TPUSheetData WHERE IDX_NO = @Count       -- 2011. 3. 18 hkim ��ȭ �ɾ �ŷ�ó ����������   
         
                    SELECT @wCustSeq2 = ISNULL(B.CustSeq, 0)        
                      FROM _TPUDelvItem  AS A        
                           JOIN _TPUDelv AS B ON A.CompanySeq = B.CompanySeq        
                           AND A.DelvSeq   = B.DelvSeq        
                     WHERE A.CompanySeq = @CompanySeq        
                       AND A.ItemSeq    = @wItemSeq        
                       AND B.CurrSeq    = @CurrSeq        
                       AND A.DelvSeq    = ( SELECT TOP 1 ISNULL(B.DelvSeq, 0) FROM _TPUDelvItem  AS A        
                                   JOIN _TPUDelv AS B ON A.CompanySeq = B.CompanySeq        
                                         AND A.DelvSeq    = B.DelvSeq        
                                                                             WHERE A.CompanySeq = @CompanySeq        
                                                                               AND A.ItemSeq    = @wItemSeq        
                                                                               AND B.CurrSeq    = @CurrSeq        
                                                                               AND B.DelvNo       = (SELECT TOP 1 ISNULL(MAX(B.DelvNo), '0') FROM _TPUDelvItem  AS A        
                                                                                         JOIN _TPUDelv AS B ON A.CompanySeq  = B.CompanySeq        
                                                                                                 AND A.DelvSeq     = B.DelvSeq        
                                                                                         WHERE A.CompanySeq = @CompanySeq        
                                                                                        AND @wItemSeq IN (A.ItemSeq)        
                                                                                        AND B.CurrSeq    = @CurrSeq) )       
                    UPDATE #TPUSheetData                                                                                                         
                       SET CustSeq = @wCustSeq2      
                      FROM #TPUSheetData      
                    WHERE IDX_NO = @Count      
                END      
          
                SELECT @Count = @Count + 1    
                SELECT @wCustSeq2 = 0       -- 0 ���� �ʱ�ȭ   

            END
        END
    END

    -- �����ڱ��� ��������(1, ��ǥ�ܰ� 2. ��ǥ�ܰ� üũ �ȵȰ� �� 3. ǰ���Ͽ� ��� �� ��      
    UPDATE #TPUSheetData      
       SET ImpType = ISNULL(B.ImpType, 0)      
      FROM #TPUSheetData    AS A      
           JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq      
     WHERE B.CompanySeq = @CompanySeq      
       AND @pDate BETWEEN B.StartDate AND B.EndDate      
       AND B.IsPrice = '1'      
       AND A.ImpType IS NULL OR A.ImpType = 0      
  
    UPDATE #TPUSheetData      
       SET ImpType = ISNULL(B.ImpType, 0)       
      FROM #TPUSheetData    AS A      
           JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq      
     WHERE B.CompanySeq = @CompanySeq      
       AND @pDate BETWEEN B.StartDate AND B.EndDate      
       AND A.ImpType IS NULL OR A.ImpType = 0        


    --2016.05.10 �ڼ��� ::ǰ�񸶽����� �����ڱ����� ������ ���� �����ϰ�, ��/���ڱ��� �� ����ǵ��� ����
    UPDATE #TPUSheetData
       SET ImpType = CASE ISNULL(SMInOutKind, 0) WHEN 8007001 THEN 8008001 
                                                 WHEN 8007002 THEN 8008004 
                                                 ELSE 0
                     END
      FROM #TPUSheetData AS A
           JOIN _TDAItem AS B ON A.ItemSeq = B.ItemSeq
     WHERE B.CompanySeq = @CompanySeq
       AND A.ImpType IS NULL OR A.ImpType = 0
       

    --2016.05.10 �ڼ��� ::ǰ�񸶽��Ϳ��� �����ڱ����� ���� �ȵ� ���, ȭ�鿡�� ������ �����ڱ���, �װ͵� ������ ����
    UPDATE #TPUSheetData
       SET ImpType = CASE WHEN ISNULL(GetImpType, 0) <> 0 THEN GetImpType ELSE 8008001 END
      FROM #TPUSheetData AS A
     WHERE A.ImpType IS NULL OR A.ImpType = 0
       
    -- �����ڱ��� �������� ��      
       
    ------------------------------------------------------
    -- â��������
    ------------------------------------------------------
        -- 1. �Ƿںμ��� �Һз��� ���ű⺻â��  
        SELECT TOP 1 @WHSeq = C.WHSeq  
          FROM #TPUSheetData AS A   
               JOIN _TDAItemClass AS B ON A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq  
               JOIN _TPUReqDeptBasicWH AS C ON A.CompanySeq = C.CompanySeq AND A.DeptSeq = C.DeptSeq AND B.UMItemClass = C.UMItemClass  
     IF @WHSeq IS NULL OR @WHSeq = 0  
      BEGIN  
         SELECT TOP 1 @WHSeq = B.WHSeq   
           FROM #TPUSheetData AS A  
                JOIN _TPUReqDeptBasicWH AS B ON A.CompanySeq = B.CompanySeq AND A.DeptSeq = B.DeptSeq AND B.UMItemClass = 0  
      END  
             IF @WHSeq IS NULL OR @WHSeq = 0  
             BEGIN  
                SELECT TOP 1 @WHSeq = C.WHSeq  
                  FROM #TPUSheetData AS A   
                       JOIN _TDAItemClass AS B ON A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq  
                       JOIN _TPUReqDeptBasicWH AS C ON A.CompanySeq = C.CompanySeq AND B.UMItemClass = C.UMItemClass AND C.DeptSeq = 0  
             END  
                    IF @WHSeq IS NULL OR @WHSeq = 0  
                    BEGIN  
                       SELECT TOP 1 @WHSeq = B.WHSeq   
                         FROM #TPUSheetData AS A  
                              JOIN _TPUReqDeptBasicWH AS B ON A.CompanySeq = B.CompanySeq AND B.DeptSeq = 0 AND B.UMItemClass = 0  
                     END  
       

         UPDATE #TPUSheetData  
            SET WHSeq = @WHSeq  
          WHERE WHSeq IS NULL OR WHSeq = 0  



        -- 2. ǰ�� �⺻â��       

        IF @PUType = 'PUORDPO'   
         BEGIN

        -- �α������� ����ι��� â�� �������� ������ ����ι�0���� �ɷ��ִ� â�� ����������, �ߺ������������ â������������
        
            UPDATE #TPUSheetData
             SET WHSeq = CASE (SELECT COUNT(1) FROM _TDAItemStdWH WHERE ItemSeq = A.ItemSeq AND CompanySeq = @CompanySeq AND (@BIzUnit = 0 OR BizUnit = @BIzUnit)) WHEN 1 THEN InWHSeq ELSE 0 END 
             FROM #TPUSheetData  AS A      
                   JOIN _TDAItemStdWH AS B ON A.ItemSeq = B.ItemSeq      
             WHERE B.CompanySeq = @CompanySeq            
               AND (@BIzUnit = 0 OR B.BizUnit = @BizUnit)
               AND (A.WHSeq IS NULL OR A.WHSeq = 0)

            UPDATE #TPUSheetData
             SET WHSeq = CASE (SELECT COUNT(1) FROM _TDAItemStdWH WHERE ItemSeq = A.ItemSeq AND CompanySeq = @CompanySeq AND BizUnit = 0) WHEN 1 THEN InWHSeq ELSE 0 END 
             FROM #TPUSheetData  AS A      
                   JOIN _TDAItemStdWH AS B ON A.ItemSeq = B.ItemSeq      
             WHERE B.CompanySeq = @CompanySeq            
               AND B.BizUnit = 0  
               AND (A.WHSeq IS NULL OR A.WHSeq = 0)
         END


      ELSE 
       BEGIN
        UPDATE #TPUSheetData      
           SET WHSeq = (SELECT TOP 1 B.InWHSeq)      
          FROM #TPUSheetData  AS A      
               JOIN _TDAItemStdWH AS B ON A.ItemSeq = B.ItemSeq      
         WHERE B.CompanySeq = @CompanySeq            
           AND (@BIzUnit = 0 OR B.BizUnit = @BizUnit)
           AND A.WHSeq IS NULL OR A.WHSeq = 0  
       END
        -- 3. â��ǰ��      
        UPDATE #TPUSheetData      
           SET WHSeq = (SELECT TOP 1 B.WHSeq)      
          FROM #TPUSheetData  AS A      
               JOIN _TDAWHItem  AS B ON A.ItemSeq = B.ItemSeq          
         WHERE B.CompanySeq = @CompanySeq  
           AND A.WHSeq IS NULL OR A.WHSeq = 0  
      
        -- 4. ���Ŵܰ������ â��      
        UPDATE #TPUSheetData      
           SET WHSeq = (SELECT TOP 1 B.WHSeq)      
         FROM #TPUSheetData    AS A      
              JOIN _TPUBaseBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq          
        WHERE B.CompanySeq = @CompanySeq            
          AND @pDate BETWEEN B.StartDate AND B.EndDate      
          AND B.IsPrice = '1'  
          AND A.WHSeq IS NULL OR A.WHSeq = 0  
      
        -- 5. ���� ǰ�� ��ǰâ��      
       UPDATE #TPUSheetData      
          SET WHSeq = G.WHSeq      
         FROM #TPUSheetData  AS A      
              JOIN (SELECT B.DelvSeq AS DelvSeq, E.ItemSeq AS ItemSeq FROM _TPUDelv AS B      
                                                                           JOIN (SELECT MAX(C.DelvNo) AS DelvNo, D.ItemSeq AS ItemSeq      
                                                                                   FROM _TPUDelv            AS C      
                                                                                        JOIN _TPUDelvItem   AS D ON C.CompanySeq = D.CompanySeq      
                                                                                                                AND C.DelvSeq = D.DelvSeq      
                                                                                        JOIN #TPUSheetData  AS E ON D.ItemSeq = E.ItemSeq      
                                                                                  WHERE C.CompanySeq = @CompanySeq
                                                                                    AND (@BizUnit = 0 OR C.BizUnit = @BizUnit)  -- ���� ǰ�� ���Ͽ� �ٸ� ����ι����� ��ǰó���Ǿ����� ����ι����� �ɾ� ������ �� �ֵ��� ���� 2015.10.21 �ڼ���
                                                                                    AND ISNULL(C.IsReturn, '0') <> '1'   -- ��ǰ�� ���� 12.02.14 �輼ȣ �߰�
                                                                               GROUP BY D.ItemSeq)          AS E ON B.DelvNo = E.DelvNo AND B.CompanySeq = @CompanySeq) AS F ON A.ItemSeq = F.ItemSeq      
              JOIN _TPUDelvItem AS G ON F.DelvSeq = G.DelvSeq AND G.CompanySeq = @CompanySeq
        WHERE A.WHSeq IS NULL OR A.WHSeq = 0

        --â�� �������� ���ߴٸ� ȭ�鿡�� ���� â�� 20110307 ������  
        --1=1 �� ������ �ɷ��־�, ����� ������ �ȵ�, IDX_NO �� JOIN   20150824 �ڼ���
        UPDATE  #TPUSheetData  
           SET  WHSeq = B.WHSeq  
          FROM  #TPUSheetData AS A JOIN #TPUBaseGetPrice AS B ON A.IDX_NO = B.IDX_NO
         WHERE  A.WHSeq = 0  
                OR A.WHSeq = ''  
                OR A.WHSeq IS NULL OR A.WHSeq = 0  
    --####################################################################################################������
        UPDATE #TPUSheetData  -- â�� �������̸� ����ش� 
        SET WHSeq = 0
       FROM #TPUSheetData AS A JOIN _TDAWH AS B ON B.CompanySeq = @CompanySeq 
                                               AND A.WHSeq = B.WHSeq 
      WHERE B.CompanySeq = @CompanySeq 
      AND B.IsNotUse = 1 
    --####################################################################################################  
    -------------------------------------
    -- â�� �������� ��      
    -------------------------------------
    

  
    /*****************************************************************************/      
    /**** ȭ�� ���Ŵ��� ����Ŀ, �ܰ��ּұ��ż������Ŵ������� ��������  ***********/      
    /*****************************************************************************/      
    -- ȭ��      
    EXEC _SPUBaseGetPriceSub 'CurrSeq',@CompanySeq, @pDate, @PUType, @UserSeq      
    -- ���Ŵ����ڵ�        
    EXEC _SPUBaseGetPriceSub 'StdUnitSeq',@CompanySeq, @pDate, @PUType, @UserSeq      
    -- ����Ŀ�ڵ�        
    EXEC _SPUBaseGetPriceSub 'MakerSeq',@CompanySeq, @pDate, @PUType, @UserSeq     
    -- �ܰ�, �ּҼ���, ���� ��������        
    EXEC hye_SPUDelvGetPriceSub 'Price',@CompanySeq, @pDate, @PUType, @UserSeq      
    /*****************************************************************************/      
    /**** ȭ�� ���Ŵ��� ����Ŀ, �ܰ��ּұ��ż������Ŵ������� ������    ***********/      
    /*****************************************************************************/      
    
----------------------------------------------------------------------------------------------------------  
--   ���Ź�ǰ�Է¿����� �ܰ��������� --������(6518��ǰ�⺻�ܰ� ��������)--          -- 11.07.15 �輼ȣ �߰�    
----------------------------------------------------------------------------------------------------------  
  
    IF @PUType = 'PUReturn'   
     BEGIN   
  
        EXEC dbo._SCOMEnv @CompanySeq,6518,@UserSeq,@@PROCID,@GetReturnPriceType OUTPUT  -- ���Ź�ǰ�ܰ� ���� ������  
  
        -- �����Է�  
        IF @GetReturnPriceType = '6215001'  
         BEGIN   
            UPDATE #TPUSheetData  
               SET Price = 0  
              FROM #TPUSheetData    AS A  
              JOIN #TPUBaseGetPrice AS B ON A.IDX_NO = B.IDX_NO  
          END  
        -- ���ű⺻�ܰ� (��ǥ�ܰ�)  
        ELSE IF @GetReturnPriceType = '6215002'  
         BEGIN   
            UPDATE #TPUSheetData  
               SET Price = ISNULL(Price, 0)  
         END  
        -- ���� ���ܰ�   
        ELSE  
         BEGIN  
  
            EXEC dbo._SCOMEnv @CompanySeq,5531,@UserSeq,@@PROCID,@CostEnv OUTPUT   -- ����������  
            EXEC dbo._SCOMEnv @CompanySeq,5563,@UserSeq,@@PROCID,@IFRSEnv OUTPUT   -- IFRS�θ� ���ó�� ���࿩��     
          
            IF @CostEnv = 5518001 AND ISNULL(@IFRSEnv, 0) = 0          -- �⺻���� ���    
            BEGIN    
                SELECT @SMCostMng = 5512004    
            END    
            ELSE IF @CostEnv = 5518001 AND @IFRSEnv = 1     -- �⺻����, IFRS ���    
            BEGIN    
                SELECT @SMCostMng = 5512006    
            END    
            ELSE IF @CostEnv = 5518002 AND ISNULL(@IFRSEnv, 0) = 0     -- Ȱ�����ؿ��� ���    
            BEGIN    
                SELECT @SMCostMng = 5512001    
            END    
            ELSE IF @CostEnv = 5518002 AND @IFRSEnv = 1     -- Ȱ�����ؿ���, IFRS ���    
            BEGIN       
                SELECT @SMCostMng = 5512005    
            END    
  
            ALTER TABLE #TPUSheetData  ADD EnvValue INT  
  
  
            -- �ڻ�з��� ���� ȯ�漳���� ��������   
            EXEC dbo._SCOMEnv @CompanySeq,5521,@UserSeq,@@PROCID,@MatPriceEnv OUTPUT   -- ����ܰ�������  
            EXEC dbo._SCOMEnv @CompanySeq,5522,@UserSeq,@@PROCID,@GoodsPriceEnv OUTPUT   -- ��ǰ�ܰ�������  
  
  
            UPDATE #TPUSheetData   
               SET EnvValue = CASE WHEN ISNULL(B.SMAssetGrp, 0) = 6008001 THEN @GoodsPriceEnv ELSE @MatPriceEnv END  
             FROM  #TPUSheetData            AS A  
            LEFT OUTER JOIN  _TDAItemAsset  AS B ON @CompanySeq = B.CompanySeq  
                                                AND A.AssetSeq  = B.AssetSeq  
            UPDATE #TPUSheetData  
               SET EnvValue = CASE A.EnvValue WHEN 5502002 THEN ISNULL(B.AccUnit, 0) ELSE ISNULL(B.BizUnit, 0) END  
              FROM #TPUSheetData          AS A   
              LEFT OUTER JOIN _TDABizUnit AS B ON @CompanySeq = B.CompanySeq  
                                              AND (@BIzUnit = 0 OR @BizUnit = B.BizUnit)
  
  
  
            -- �������ܰ� ��������  
            UPDATE #TPUSheetData  
               SET Price = (SELECT TOP 1 ISNULL(B.Price, ISNULL(A.Price, 0))  
                             FROM #TPUSheetData                 AS A   
                             JOIN _TESMCProdStkPrice            AS B ON @CompanySeq  = B.CompanySeq  
                                                                    AND A.ItemSeq    = B.ItemSeq  
                                                                    AND A.EnvValue    = B.CostUnit   
                             JOIN _TESMDCostKey                 AS C ON B.CompanySeq = C.CompanySeq   
                                                                    AND B.CostKeySeq = C.CostKeySeq   
                                                                    AND C.RptUnit     = 0  
                                                                    AND C.PlanYear   = ''  
                                                                    AND C.CostMngAmdSeq   = 0  
  
                            WHERE @SMCostMng = C.SMCostMng                                 
                            ORDER BY CostYM DESC)  
  
         END  
     END  
----------------------------------------------------------------------------------------------------------  
--   ���Ź�ǰ�Է¿����� �ܰ��������� ��   
----------------------------------------------------------------------------------------------------------  
  

  
    --��Ÿ ������ ��������      
    IF EXISTS (SELECT 1 FROM #TPUSheetData WHERE StdUnitSeq = 0)  -- ���ش��� �ڵ� ���� ǰ��      
    BEGIN      
        UPDATE #TPUSheetData      
           SET StdUnitSeq = B.UnitSeq      
          FROM #TPUSheetData AS A      
               JOIN _TDAItem AS B ON A.ItemSeq = B.ItemSeq      
         WHERE B.CompanySeq = @CompanySeq        
               AND A.StdUnitSeq = 0          
    END      
      
    IF EXISTS (SELECT 1 FROM #TPUSheetData WHERE StdUnitSeq = 0 OR CurrSeq = 0)  -- ��ȭ ���� ǰ��      
    BEGIN      
        UPDATE #TPUSheetData      
           SET CurrSeq = CASE ImpType WHEN 8008001 THEN @xKorCurrSeq      
                                                   ELSE @xForCurrSeq END      
         WHERE CurrSeq = 0        
    END      
    IF EXISTS (SELECT 1 FROM #TPUSheetData WHERE StdUnitQty = 0)  -- ���ش��� ���� ���� ǰ��      
    BEGIN       
        UPDATE #TPUSheetData      
           SET StdUnitQty = ISNULL((B.ConvNum /B.ConvDen),1)      
          FROM #TPUSheetData  AS A      
               JOIN _TDAItemUnit AS B ON A.ItemSeq = B.ItemSeq AND A.StdUnitSeq = B.UnitSeq      
         WHERE B.CompanySeq = @CompanySeq      
           AND A.StdUnitQty = 0        
    END        
    IF EXISTS (SELECT 1 FROM #TPUSheetData WHERE ExRate = 0 OR ExRate IS NULL)    -- ȯ�� ���� ǰ��      
    BEGIN      
        UPDATE #TPUSheetData      
           SET ExRate = 1      
          FROM #TPUSheetData AS A      
         WHERE ExRate = 0 OR ExRate IS NULL          
    END       
    IF EXISTS (SELECT 1 FROM #TPUSheetData    AS A         -- �˻�ǰ�� ���� ���      
                             JOIN _TPDBaseItemQCType AS B ON A.ItemSeq = B.ItemSeq       
                       WHERE B.CompanySeq = @CompanySeq AND B.IsInQC = '1')      
    BEGIN      
        UPDATE #TPUSheetData      
           SET QCType = 6035002      
          FROM #TPUSheetData   AS A      
               JOIN _TPDBaseItemQCType AS B ON A.ItemSeq = B.ItemSeq      
         WHERE B.CompanySeq = @CompanySeq AND B.IsInQC = '1'      
    END       
  
    -- ����ǰ�ǿ��� �Է� �ܰ��� �ְ�, ������ �ܰ��� 0�� ��쿡�� �Էµ� �ܰ��� ��� �ǵ���   
    IF @PUType = 'PUORDApprovalReq' AND EXISTS (SELECT 1 FROM #TPUSheetData AS A WHERE A.Price = 0)  
    BEGIN  
        UPDATE #TPUSheetData  
           SET Price = B.Price  
          FROM #TPUSheetData         AS A  
               JOIN #TPUBaseGetPrice AS B ON A.IDX_NO = B.IDX_NO  
         WHERE B.Price <> 0 AND A.Price = 0                 
        
    END   
    
    -- ����ǰ�ǿ��� ���Ŵܰ���Ͽ� �ش��ϴ� �ŷ�ó�� ���� ��쿡, ������ - �������� �� �⺻����ó�� ���� �ǵ��� 2014.06.25 ����� �߰�
    IF @PUType = 'PUORDApprovalReq' AND EXISTS (SELECT 1 FROM #TPUSheetData AS A WHERE A.CustSeq = 0 )    
    BEGIN    
    
        UPDATE #TPUSheetData    
           SET CustSeq = B.CustSeq   
          FROM #TPUSheetData         AS A    
               JOIN #TPUBaseGetPrice AS B ON A.IDX_NO = B.IDX_NO    
         WHERE B.CustSeq <> 0 AND A.CustSeq = 0                   
          
    END  

    
    IF @PUType = 'PUORDApprovalReq' AND EXISTS ( SELECT 1 FROM #TPUBaseGetPrice AS A WHERE A.SMImpType = 8008004 AND ISNULL(A.CustSeq,0) = 0 )
                                    AND NOT EXISTS (SELECT 1 FROM #TPUBaseGetPrice          AS A   
                                                                  JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq  
                                                            WHERE B.CompanySeq = @CompanySeq   
                                                              AND @pDate BETWEEN B.StartDate AND B.EndDate)    
    BEGIN     
        UPDATE #TPUSheetData      
           SET CurrSeq = B.CurrSeq     
          FROM #TPUSheetData         AS A      
               JOIN #TPUBaseGetPrice AS B ON A.IDX_NO = B.IDX_NO      
         WHERE B.SMImpType = 8008004            
           AND B.CurrSeq <> 0   
           AND B.CurrSeq <> @xKorCurrSeq 
           AND ISNULL(B.CustSeq,0) = 0         --20150410 ������ :: ���ſ�û���� ������ �� ������ �ν�
    END                                                                                                                                
    
    IF @PUType = 'PUORDApprovalReq' AND EXISTS (SELECT 1 FROM #TPUSheetData AS A WHERE A.MakerSeq = 0 )   
    BEGIN    
		--  ������-��������-Maker (1,2�� �� �� ���� ��) 16.11.10 ������ �߰�
		UPDATE #TPUSheetData    
           SET MakerSeq = C.MkCustSeq   
          FROM #TPUSheetData         AS A    
               JOIN #TPUBaseGetPrice AS B ON A.IDX_NO = B.IDX_NO
			   JOIN _TDAItemPurchase AS C ON A.ItemSeq = C.ItemSeq    
										 AND C.CompanySeq = @CompanySeq
         WHERE ISNULL(B.MakerSeq,0) = 0 
		   AND ISNULL(A.MakerSeq,0) = 0 
	END
       
          
    IF @WorkingTag <> 'AUTO'      
    BEGIN      
    SELECT A.IDX_NO   AS IDX_NO  ,      
           A.CustSeq  AS CustSeq  ,      
           B.CustName  AS CustName  ,      
           A.MakerSeq  AS MakerSeq  ,      
           C.CustName  AS MakerName ,      
           A.ImpType  AS SMImpType ,       
           A.ImpType  AS SMImpTypeName,       
           A.ImpType  AS SMInOutType ,      
           A.ImpType  AS SMInOutTypeName,      
           A.CurrSeq  AS CurrSeq  ,      
           D.CurrName  AS CurrName  ,      
           A.Price   AS Price  ,      
           A.StdUnitQty  AS STDUnitQty ,      
           A.StdUnitQty  AS StdConvQty ,      
           A.MinQty   AS MinQty  ,      
           A.StepQty  AS StepQty  ,      
           A.QCType    AS SMQcType  ,       
           E.MinorName  AS SMQcTypeName ,       
           A.WHSeq   AS WHSeq  ,      
           F.WHName   AS WHName  ,      
           A.ExRate   AS ExRate  ,      
           A.AssetSeq  AS AssetSeq  ,      
           A.LeadTime  AS LeadTime  ,      
           A.StdUnitSeq  AS PUUnitSeq ,      
           CASE WHEN ISNULL(A.UnitSeq,0) = 0 THEN A.STDUnitSeq ELSE A.UnitSeq END  AS UnitSeq  ,      
           G.UnitName  AS PUUnitName ,      
           CASE WHEN ISNULL(U.UnitName,'') = '' THEN G.UnitName ELSE U.UnitName END  AS UnitName,
           CASE WHEN ISNULL(H.UnitSeq,0) = 0 THEN A.STDUnitSeq ELSE H.UnitSeq END  AS ReqUnitSeq       
      FROM #TPUSheetData    AS A      
           LEFT OUTER JOIN _TDACust      AS B ON B.CompanySeq = @CompanySeq      
                                             AND A.CustSeq  = B.CustSeq      
           LEFT OUTER JOIN _TDACust      AS C ON C.CompanySeq = @CompanySeq      
                                             AND A.MakerSeq  = C.CustSeq      
           LEFT OUTER JOIN _TDACurr      AS D ON D.CompanySeq = @CompanySeq      
                                             AND A.CurrSeq  = D.CurrSeq             
           LEFT OUTER JOIN _TDASMinor    AS E ON E.CompanySeq = @CompanySeq      
                                             AND A.QCType  = E.MinorSeq      
           LEFT OUTER JOIN _TDAWH        AS F ON F.CompanySeq = @CompanySeq      
                                             AND A.WHSeq   = F.WHSeq      
           LEFT OUTER JOIN _TDAUnit      AS G ON G.CompanySeq = @CompanySeq      
                                             AND A.StdUnitSeq = G.UnitSeq  
           LEFT OUTER JOIN _TDAUnit      AS U ON A.UnitSeq    = U.UnitSeq
                                             AND U.CompanySeq = @CompanySeq                                                
           --LEFT OUTER JOIN #TPUBaseGetPrice AS H ON A.ItemSeq = H.ItemSeq   
           LEFT OUTER JOIN #TPUBaseGetPrice AS H ON A.IDX_No = H.IDX_No
  ORDER BY A.IDX_NO      
    
    END         
    ELSE   -- ����ǰ�� �ϰ� ������ ��� �ӽ����̺��� ������Ʈ ����      
    BEGIN      
        UPDATE #TPUBaseGetPrice        
           SET CustSeq   = B.CustSeq ,         
               MakerSeq  = B.MakerSeq   ,        
               SMImpType = ISNULL(B.ImpType, 0) ,        
               CurrSeq   = B.CurrSeq ,        
               UnitSeq   = B.StdUnitSeq ,      
               Price  = ISNULL(B.Price           ,  0)   ,        
               StdConvQty= ISNULL(B.StdUnitQty      ,  1)   ,        
               MinQty  = ISNULL(B.MinQty          ,  1)   ,        
               StepQty  = ISNULL(B.StepQty         ,  1)   ,        
               ExRate  = ISNULL(B.ExRate          ,  1)   ,        
               PUUnitSeq= ISNULL(B.StdUnitSeq  ,  0)   ,        
               STDUnitQty= ISNULL(B.StdUnitQty      ,  1)        
          FROM #TPUBaseGetPrice   AS A        
               JOIN #TPUSheetData AS B ON A.IDX_NO = B.IDX_NO        
    END      
RETURN        
/*************************���Ŵܰ� ��� ȭ�鿡�� ȣ���********************************************/        
PUBasePrice_Proc:       

    -- ������ ���� �� ���ش��� ��������      
    INSERT INTO #TPUSheetData(ItemSeq, ImpType , STDUnitSeq)      
    SELECT A.ItemSeq, CASE ISNULL(B.SMInOutKind, 0) WHEN 8007001 THEN 8008001 WHEN 0 THEN 8008001 ELSE 8008004 END,      
           C.STDUnitSeq      
      FROM #TPUBaseGetPrice                AS A      
           JOIN _TDAItem                   AS B ON A.ItemSeq = B.ItemSeq      
           LEFT OUTER JOIN _TDAItemDefUnit AS C ON B.CompanySeq = C.CompanySeq      
                                               AND B.ItemSeq = C.ItemSeq      
     WHERE B.CompanySeq = @CompanySeq           
       AND C.UMModuleSeq= 1003001      
  ORDER BY A.IDX_No          
    -- �����ڱ��п� ���� ��ȭ ������Ʈ      
    -- ���� ��ȭ ��������        
    EXEC dbo._SCOMEnv @CompanySeq,13,@UserSeq,@@PROCID,@xKorCurrSeq OUTPUT        
    EXEC dbo._SCOMEnv @CompanySeq,12,@UserSeq,@@PROCID,@xForCurrSeq OUTPUT        
       
    UPDATE #TPUSheetData      
       SET CurrSeq = @xForCurrSeq      
     WHERE ImpType = 8008004      
      
    UPDATE #TPUSheetData      
       SET CurrSeq = @xKorCurrSeq      
     WHERE ImpType <> 8008004      
      
    SELECT A.ImpType  AS SMImpType ,      
           B.MinorName  AS SMImpTypeName,      
           A.STDUnitSeq  AS UnitSeq  ,      
           C.UnitName  AS UnitName  ,      
           A.CurrSeq  AS CurrSeq  ,      
           D.CurrName  AS CurrName      
      FROM #TPUSheetData AS A      
           LEFT OUTER JOIN _TDASMinor AS B ON B.CompanySeq = @CompanySeq      
                                          AND A.ImpType    = B.MinorSeq      
           LEFT OUTER JOIN _TDAUnit   AS C ON C.CompanySeq = @CompanySeq      
                                          AND A.STDUnitSeq = C.UnitSeq                  
           LEFT OUTER JOIN _TDACurr   AS D ON D.CompanySeq = @CompanySeq      
                                          AND A.CurrSeq    = D.CurrSeq      
  ORDER BY IDX_NO      
        
RETURN        

go
begin tran 
exec hye_SPUDelvGetPrice @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BizUnit>1</BizUnit>
    <UnitName>EA</UnitName>
    <MakerName />
    <MakerSeq>0</MakerSeq>
    <Price>20000</Price>
    <WHName>�������â��</WHName>
    <WHSeq>45</WHSeq>
    <STDUnitQty>10</STDUnitQty>
    <ItemSeq>18</ItemSeq>
    <UnitSeq>1</UnitSeq>
    <Memo2>1013554001</Memo2>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <CustSeq />
    <CurrSeq>3</CurrSeq>
    <PUType>Delivery</PUType>
    <Date>20161219</Date>
    <DeptSeq>3</DeptSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730170,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730012
rollback 
