  
IF OBJECT_ID('hye_SPUBaseBuyPriceItemCheck') IS NOT NULL   
    DROP PROC hye_SPUBaseBuyPriceItemCheck  
GO  
  
-- v2016.12.15
  
-- ���Ŵܰ����-üũ by ����õ
CREATE PROC hye_SPUBaseBuyPriceItemCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
      
    CREATE TABLE #hye_TPUBaseBuyPriceItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hye_TPUBaseBuyPriceItem'   
    IF @@ERROR <> 0 RETURN     
    
    --------------------------------------------------------------
    -- üũ1, �������� �ƴϸ� ����,������ �� �� �����ϴ�. 
    --------------------------------------------------------------
    UPDATE A
       SET Result = '�������� �ƴϸ� ����,������ �� �� �����ϴ�.', 
           MessageType = 1234, 
           Status = 1234 
      FROM #hye_TPUBaseBuyPriceItem AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
       AND A.EndDate <> '99991231'
    --------------------------------------------------------------
    -- üũ1, END 
    --------------------------------------------------------------

    --------------------------------------------------------------
    -- üũ2, �����Ǻ��� ��ȿ�������� �۰ų� �����ϴ�.
    --------------------------------------------------------------
    UPDATE A
       SET Result = '�����Ǻ��� ��ȿ�������� �۰ų� �����ϴ�.', 
           MessageType = 1234, 
           Status = 1234 
      FROM #hye_TPUBaseBuyPriceItem AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND EXISTS (SELECT 1 
                     FROM hye_TPUBaseBuyPriceItem AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.UMDVGroupSeq = A.UMDVGroupSeq 
                      AND Z.ItemSeq = A.ItemSeq 
                      AND Z.UnitSeq = A.UnitSeq 
                      AND Z.CurrSeq = A.CurrSeq 
                      AND Z.SrtDate >= A.SrtDate 
                      AND Z.PriceSeq <> A.PriceSeq 
                  )
    --------------------------------------------------------------
    -- üũ2, END 
    --------------------------------------------------------------

    --------------------------------------------------------------
    -- üũ3, �ߺ� �� �����Ͱ� �ԷµǾ����ϴ�.
    --------------------------------------------------------------
     IF EXISTS ( SELECT 1 
                   FROM #hye_TPUBaseBuyPriceItem 
                  WHERE WorkingTag IN ( 'A', 'U' ) 
                  GROUP BY UMDVGroupSeq, ItemSeq, UnitSeq, CurrSeq, SrtDate
                  HAVING COUNT(1) > 1 
               )
    BEGIN
        UPDATE A
           SET Result = '�ߺ� �� �����Ͱ� �ԷµǾ����ϴ�.', 
               MessageType = 1234, 
               Status = 1234 
          FROM #hye_TPUBaseBuyPriceItem AS A 
    END 
    --------------------------------------------------------------
    -- üũ3, END 
    --------------------------------------------------------------

    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #hye_TPUBaseBuyPriceItem WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'hye_TPUBaseBuyPriceItem', 'PriceSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #hye_TPUBaseBuyPriceItem  
           SET PriceSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
      
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #hye_TPUBaseBuyPriceItem   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #hye_TPUBaseBuyPriceItem  
     WHERE Status = 0  
       AND ( PriceSeq = 0 OR PriceSeq IS NULL )  
      
    SELECT * FROM #hye_TPUBaseBuyPriceItem   
      
    RETURN  

GO
begin tran


exec hye_SPUBaseBuyPriceItemCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <PriceSeq />
    <ItemNo>*�ٳ���ũ����</ItemNo>
    <ItemName>*�ٳ���ũ����</ItemName>
    <Spec />
    <ItemSeq>226</ItemSeq>
    <UnitName>EA</UnitName>
    <UnitSeq>1</UnitSeq>
    <CurrName>KRW</CurrName>
    <CurrSeq>1</CurrSeq>
    <UMDVGroup>���ϱ׷�2</UMDVGroup>
    <UMDVGroupSeq>1013554002</UMDVGroupSeq>
    <SrtDate>20161208</SrtDate>
    <EndDate />
    <YSSPrice>0</YSSPrice>
    <DelvPrice>0</DelvPrice>
    <StdPrice>0</StdPrice>
    <SalesPrice>0</SalesPrice>
    <ChgPrice>0</ChgPrice>
    <IsChg>0</IsChg>
    <Summary />
    <Remark />
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730168,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730058
rollback 