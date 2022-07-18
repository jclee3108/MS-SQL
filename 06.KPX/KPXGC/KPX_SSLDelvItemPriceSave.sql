  
IF OBJECT_ID('KPX_SSLDelvItemPriceSave') IS NOT NULL   
    DROP PROC KPX_SSLDelvItemPriceSave  
GO  
  
-- v2014.11.12  
  
-- �ŷ�ó����ǰó�ܰ����-���� by ����õ   
CREATE PROC KPX_SSLDelvItemPriceSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TSLDelvItemPrice (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TSLDelvItemPrice'   
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TSLDelvItemPrice')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TSLDelvItemPrice'    , -- ���̺��        
                  '#KPX_TSLDelvItemPrice'    , -- �ӽ� ���̺��        
                  'DVItemPriceSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    DECLARE @Cnt        INT, 
            @ItemSeq    INT, 
            @UnitSeq    INT, 
            @CurrSeq    INT, 
            @CustSeq    INT, 
            @SDate      NCHAR(8), 
            @SDateMax   NCHAR(8), 
            @EDate      NCHAR(8), 
            @DVItemPriceSeq INT, 
            @DrumPrice  DECIMAL(19,5), 
            @TankPrice  DECIMAL(19,5), 
            @BoxPrice   DECIMAL(19,5), 
            @Remark     NVARCHAR(2000) 
    
    
    SELECT @Cnt = 1 
    
    

    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TSLDelvItemPrice WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        WHILE( 1 = 1 ) 
        BEGIN 
            SELECT @DVItemPriceSeq = DVItemPriceSeq
                   
              FROM #KPX_TSLDelvItemPrice
             WHERE WorkingTag = 'D' 
               AND DataSeq = @Cnt 
            
            SELECT @ItemSeq = ItemSeq, 
                   @UnitSeq = UnitSeq, 
                   @CurrSeq = CurrSeq, 
                   @CustSeq = CustSeq, 
                   @SDate   = SDate 
                       
              FROM KPX_TSLDelvItemPrice 
             WHERE DVItemPriceSeq = @DVItemPriceSeq 
            
            --select @ItemSeq , @DVItemPriceSeq
            /** �������� ������ �����Ͱ� �����ϴ°�? **/  
            IF EXISTS (SELECT 1   
                         FROM KPX_TSLDelvItemPrice AS A WITH(NOLOCK)    
                        WHERE A.CompanySeq = @CompanySeq 
                          AND A.ItemSeq = @ItemSeq 
                          AND A.UnitSeq = @UnitSeq 
                          AND A.CurrSeq = @CurrSeq 
                          AND A.CustSeq = @CustSeq 
                          AND A.DVItemPriceSeq <> @DVItemPriceSeq )  
            BEGIN  
                /** ���� ������������ ������ ���� **/  
                SELECT @SDateMax = '' 
                SELECT @SDateMax = B.SDate   
                  FROM KPX_TSLDelvItemPrice AS A WITH(NOLOCK) 
                  OUTER APPLY (SELECT Max(SDate) AS SDate 
                                 FROM KPX_TSLDelvItemPrice AS Z 
                                WHERE Z.CompanySeq = @CompanySeq 
                                  AND Z.ItemSeq = A.ItemSeq 
                                  AND Z.UnitSeq = A.UnitSeq 
                                  AND Z.CurrSeq = A.CurrSeq
                                  AND Z.CustSeq = A.CustSeq 
                                  AND Z.DVItemPriceSeq = A.DVItemPriceSeq 
                              ) AS B 
                 WHERE A.CompanySeq = @CompanySeq  
                   AND A.ItemSeq  = @ItemSeq      
                   AND A.UnitSeq  = @UnitSeq      
                   AND A.CurrSeq  = @CurrSeq  
                   AND A.CustSeq  = @CustSeq 
                   AND A.DVItemPriceSeq <> @DVItemPriceSeq

                UPDATE A    
                  SET EDate = '99991231'
                --select * 
                 FROM KPX_TSLDelvItemPrice AS A 
                     WHERE A.CompanySeq = @CompanySeq 
                       AND A.ItemSeq  = @ItemSeq  
                       AND A.UnitSeq  = @UnitSeq 
                       AND A.CurrSeq  = @CurrSeq 
                       AND A.CustSeq  = @CustSeq 
                       AND A.SDate    = @SDateMax 
                       AND A.DVItemPriceSeq <> @DVItemPriceSeq 
                
                DELETE FROM KPX_TSLDelvItemPrice WHERE CompanySeq = @CompanySeq AND DVItemPriceSeq = @DVItemPriceSeq 
            END 
            ELSE
            BEGIN
                DELETE FROM KPX_TSLDelvItemPrice WHERE CompanySeq = @CompanySeq AND DVItemPriceSeq = @DVItemPriceSeq 
            END 
            
            IF @Cnt = (SELECT MAX(DataSeq) FROM #KPX_TSLDelvItemPrice WHERE WorkingTag = 'D')
            BEGIN 
                BREAK
            END 
            ELSE
            BEGIN
                SELECT @Cnt = @Cnt + 1 
            END 
        END 
    END    
    
    
    SELECT @Cnt = 1 
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TSLDelvItemPrice WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        
        WHILE( 1 = 1 ) 
        BEGIN 
            SELECT @ItemSeq = ItemSeq, 
                   @UnitSeq = UnitSeq, 
                   @CurrSeq = CurrSeq, 
                   @CustSeq = CustSeq, 
                   @SDate   = SDate, 
                   @EDate   = EDate, 
                   @DVItemPriceSeq = DVItemPriceSeq, 
                   @DrumPrice = DrumPrice, 
                   @TankPrice = TankPrice, 
                   @BoxPrice = BoxPrice, 
                   @Remark = Remark 
                   
                   
              FROM #KPX_TSLDelvItemPrice
             WHERE WorkingTag = 'U' 
               AND DataSeq = @Cnt 
            
            /** �������� ������ �����Ͱ� �����ϴ°�? **/  
            IF EXISTS (SELECT 1   
                         FROM KPX_TSLDelvItemPrice AS A WITH(NOLOCK)    
                        WHERE A.CompanySeq = @CompanySeq 
                          AND A.ItemSeq = @ItemSeq 
                          AND A.UnitSeq = @UnitSeq 
                          AND A.CurrSeq = @CurrSeq 
                          AND A.CustSeq = @CustSeq 
                          AND A.DVItemPriceSeq <> @DVItemPriceSeq )  
            BEGIN  
                /** �Էµ� �������� ���������������� �����Ϻ��� ū��? **/  
                SELECT @SDateMax = '' 
                SELECT @SDateMax = B.SDate   
                  FROM KPX_TSLDelvItemPrice AS A WITH(NOLOCK) 
                  OUTER APPLY (SELECT Max(SDate) AS SDate 
                                 FROM KPX_TSLDelvItemPrice AS Z 
                                WHERE Z.CompanySeq = @CompanySeq 
                                  AND Z.ItemSeq = A.ItemSeq 
                                  AND Z.UnitSeq = A.UnitSeq 
                                  AND Z.CurrSeq = A.CurrSeq
                                  AND Z.CustSeq = A.CustSeq 
                                  AND Z.DVItemPriceSeq = A.DVItemPriceSeq 
                              ) AS B 
                 WHERE A.CompanySeq = @CompanySeq  
                   AND A.ItemSeq  = @ItemSeq      
                   AND A.UnitSeq  = @UnitSeq      
                   AND A.CurrSeq  = @CurrSeq  
                   AND A.CustSeq  = @CustSeq 
                   AND A.DVItemPriceSeq <> @DVItemPriceSeq
                                          
                IF @SDateMax >= @SDate  
                BEGIN    
          
                    UPDATE A
                       SET Result ='����������� �����ܰ��� ��������Ϻ��� Ŀ�� �մϴ�.', 
                           Status = 1234, 
                           MessageType = 1234
                      FROM #KPX_TSLDelvItemPrice AS A 
                     WHERE DataSeq = @Cnt 
          
                    RETURN     
                END   
                ELSE  
                BEGIN  
                    /** ���� ������������ ������ ���� **/  
                    UPDATE A    
                      SET EDate = CONVERT(CHAR(8), DATEADD(Day, -1, @SDate), 112) 
                     FROM KPX_TSLDelvItemPrice AS A 
                         WHERE A.CompanySeq = @CompanySeq 
                           AND A.ItemSeq  = @ItemSeq  
                           AND A.UnitSeq  = @UnitSeq 
                           AND A.CurrSeq  = @CurrSeq 
                           AND A.CustSeq  = @CustSeq 
                           AND A.SDate    = @SDateMax 
                           AND A.DVItemPriceSeq <> @DVItemPriceSeq
                END  
            END  
            
            UPDATE A 
               SET ItemSeq = @ItemSeq, 
                   UnitSeq = @UnitSeq, 
                   CurrSeq = @CurrSeq, 
                   SDate = @SDate, 
                   DrumPrice = @DrumPrice, 
                   TankPrice = @TankPrice, 
                   BoxPrice = @BoxPrice, 
                   Remark = @Remark
              FROM KPX_TSLDelvItemPrice AS A 
              WHERE A.CompanySeq = @CompanySeq 
                AND A.DVItemPriceSeq = @DVItemPriceSeq
              
        
            IF @Cnt = (SELECT MAX(DataSeq) FROM #KPX_TSLDelvItemPrice WHERE WorkingTag = 'U')
            BEGIN 
                BREAK
            END 
            ELSE
            BEGIN
                SELECT @Cnt = @Cnt + 1 
            END 
        END 
    END    
    
    

    
    SELECT @Cnt = 1 
    

    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TSLDelvItemPrice WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        
        WHILE( 1 = 1 ) 
        BEGIN 
            
            SELECT @ItemSeq = ItemSeq, 
                   @UnitSeq = UnitSeq, 
                   @CurrSeq = CurrSeq, 
                   @CustSeq = CustSeq, 
                   @SDate   = SDate 
              FROM #KPX_TSLDelvItemPrice
             WHERE WorkingTag = 'A' 
               AND DataSeq = @Cnt 
            
            
            /** �������� ������ �����Ͱ� �����ϴ°�? **/  
            IF EXISTS (SELECT 1   
                         FROM KPX_TSLDelvItemPrice AS A WITH(NOLOCK)    
                        WHERE A.CompanySeq = @CompanySeq AND A.ItemSeq = @ItemSeq AND A.UnitSeq = @UnitSeq AND A.CurrSeq = @CurrSeq AND A.CustSeq = @CustSeq )  
            BEGIN  
          
                /** �Էµ� �������� ���������������� �����Ϻ��� ū��? **/  
                SELECT @SDateMax = '' 
                SELECT @SDateMax = A.SDate   
                  FROM KPX_TSLDelvItemPrice AS A WITH(NOLOCK)    
                 WHERE A.CompanySeq = @CompanySeq  
                   AND A.ItemSeq  = @ItemSeq      
                   AND A.UnitSeq  = @UnitSeq      
                   AND A.CurrSeq  = @CurrSeq  
                   AND A.CustSeq  = @CustSeq 
                   AND A.EDate = '99991231'    
                                          
                
                /** ���� ������������ ������ ���� **/  
                UPDATE A    
                  SET EDate = CONVERT(CHAR(8), DATEADD(Day, -1, @SDate), 112)    
                 FROM KPX_TSLDelvItemPrice AS A 
                     WHERE A.CompanySeq = @CompanySeq 
                       AND A.ItemSeq  = @ItemSeq  
                       AND A.UnitSeq  = @UnitSeq 
                       AND A.CurrSeq  = @CurrSeq 
                       AND A.CustSeq  = @CustSeq 
                       AND A.SDate    = @SDateMax
            END  
            
            IF @Cnt = (SELECT MAX(DataSeq) FROM #KPX_TSLDelvItemPrice WHERE WorkingTag = 'A')
            BEGIN 
                BREAK
            END 
            ELSE
            BEGIN
                SELECT @Cnt = @Cnt + 1 
            END 
            
        END 
        
        /**�Էµ����� �߰�����**/  
        INSERT INTO KPX_TSLDelvItemPrice  
        (   
            CompanySeq,DVItemPriceSeq,CustSeq,DVPlaceSeq,ItemSeq,UnitSeq,  
            CurrSeq,SDate,EDate,DrumPrice,TankPrice,  
            BoxPrice,Remark,LastUserSeq,LastDateTime  
               
        )   
        SELECT @CompanySeq,A.DVItemPriceSeq,A.CustSeq,A.DVPlaceSeq,A.ItemSeq,A.UnitSeq,  
               A.CurrSeq,A.SDate,'99991231',A.DrumPrice,A.TankPrice,  
               A.BoxPrice,A.Remark,@UserSeq,GETDATE()  
          FROM #KPX_TSLDelvItemPrice AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_TSLDelvItemPrice   
      
    RETURN  
GO 
begin tran 
exec KPX_SSLDelvItemPriceSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BoxPrice>0.00000</BoxPrice>
    <CurrSeq>1</CurrSeq>
    <DrumPrice>0.00000</DrumPrice>
    <DVItemPriceSeq>25</DVItemPriceSeq>
    <EDate>20141125</EDate>
    <ItemSeq>27439</ItemSeq>
    <Remark />
    <SDate>20141120        </SDate>
    <TankPrice>0.00000</TankPrice>
    <UnitSeq>2</UnitSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025779,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021314

select * from KPX_TSLDelvItemPrice 
rollback 