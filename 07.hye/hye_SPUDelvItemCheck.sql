IF OBJECT_ID('hye_SPUDelvItemCheck') IS NOT NULL 
    DROP PROC hye_SPUDelvItemCheck
GO 

-- v2016.09.29 

-- ���ų�ǰ�Է�_������üũ by����õ 
/************************************************************    
��  �� - ���ų�ǰüũ(������)    
�ۼ��� - 2008�� 8�� 20��     
�ۼ��� - �뿵��    
UPDATE ::  ���ش������� ���Ҷ� �Ҽ��� �ڸ� ó��              :: 12.01.25 BY �輼ȣ  
       ::  ��õ���� �������ں��� ��ǰ���� ������ �ϰ�� üũ :: 12.04.24 BY �輼ȣ
       ::  �˻籸�� '0' �� ��� üũ                     :: 12.05.29 BY �輼ȣ
************************************************************/          
CREATE PROC hye_SPUDelvItemCheck     
    @xmlDocument    NVARCHAR(MAX),        
    @xmlFlags       INT = 0,        
    @ServiceSeq     INT = 0,        
    @WorkingTag     NVARCHAR(10) = '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0        
AS      
    -- ���� ����        
    DECLARE @docHandle      INT,        
            @MessageType    INT,        
            @MessageStatus  INT,        
            @Results        NVARCHAR(300),        
            @Count          INT,        
            @Seq            INT,        
            @Status         INT,       
            @DelvSeq        INT,  
            @BizUnit        INT,       
            @MaxDelvSerl    INT,  
            @QCAutoIn       NCHAR(1),  
            @QtyPoint         INT         
      
    -- �ӽ� ���̺� ����  _TPUORDQutoReq        
    CREATE TABLE #TPUDelvItem (WorkingTag NCHAR(1) NULL)        
    -- �ӽ� ���̺� ������ �÷��� �߰��ϰ�, xml�κ����� ���� insert�Ѵ�.     
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUDelvItem'        
    IF @@ERROR <> 0 RETURN        
  
    -- Ȯ��üũ �߰� by����õ 
    UPDATE A
       SET Result = '���ڰ��簡 ���� �� ���ų�ǰ ���� ����/���� �� �� �����ϴ�.(��ǰ)', 
           Status = 1234,
           MessageType = 1234 
      FROM #TPUDelvItem                AS A 
      LEFT OUTER JOIN _TPUDelv_Confirm  AS B ON ( B.CompanySeq = @CompanySeq AND B.CfmSeq = A.DelvSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
       AND B.IsAuto = '0' 
       AND B.CfmCode <> 0 
    -- Ȯ��üũ, END 


     
    -- ��ǰ�� ��ǰ�� �ƴ� �� ���� ���� �� �� ����
    IF EXISTS (SELECT 1 FROM #TPUDelvItem WHERE WorkingTag IN ('A', 'U')) AND NOT EXISTS (SELECT 1 FROM #TPUDelvItem WHERE Status <> 0)
    BEGIN
        DECLARE @ItemKind INT -- 1:��ǰ , 0:��ǰX

        CREATE TABLE #Item 
        (
            IDX_NO      INT IDENTITY, 
            ItemSeq     INT, 
            ItemKind    INT 
        )

        INSERT INTO #Item ( ItemSeq, ItemKind ) 
        SELECT A.ItemSeq, CASE WHEN C.SMAssetGrp = 6008001 THEN 1 ELSE 0 END  
          FROM _TPUDelvItem             AS A 
          LEFT OUTER JOIN _TDAItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
          LEFT OUTER JOIN _TDAItemAsset AS C ON ( C.CompanySeq = @CompanySeq AND C.AssetSeq = B.AssetSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.DelvSeq = ( SELECT TOP 1 DelvSeq FROM #TPUDelvItem ) 
           AND NOT EXISTS ( SELECT 1 FROM #TPUDelvItem WHERE DelvSeq = A.DelvSeq AND DelvSerl = A.DelvSerl ) 
        UNION ALL 
        SELECT A.ItemSeq, CASE WHEN C.SMAssetGrp = 6008001 THEN 1 ELSE 0 END  
          FROM #TPUDelvItem             AS A 
          LEFT OUTER JOIN _TDAItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
          LEFT OUTER JOIN _TDAItemAsset AS C ON ( C.CompanySeq = @CompanySeq AND C.AssetSeq = B.AssetSeq ) 
    
        SELECT @ItemKind = A.ItemKind
          FROM #Item                    AS A 
         WHERE A.IDX_NO = 1 
        

        IF EXISTS ( SELECT 1 FROM #Item WHERE ItemKind <> @ItemKind )
        BEGIN
            UPDATE A
               SET Result = '��ǰ�� ��ǰ�� �ƴ� ǰ���� ���� ���� �� �� �����ϴ�.', 
                   Status = 1234,
                   MessageType = 1234 
              FROM #TPUDelvItem AS A 
        END 
    END 
    -- ��ǰ�� ��ǰ�� �ƴ� �� ���� ���� �� �� ����, END 




    ---- ��ǰ�� ��ǰ�� �ƴ� �� ���� ���� �� �� ����

    --SELECT C.SMAssetGrp
    --  FROM #TPUDelvItem             AS A 
    --  LEFT OUTER JOIN _TDAItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
    --  LEFT OUTER JOIN _TDAItemAsset AS C ON ( C.CompanySeq = @CompanySeq AND C.AssetSeq = B.AssetSeq ) 
    -- WHERE A.Status = 0 
    --   AND A.WorkingTag IN ( 'U', 'D' ) 



    --UPDATE A
    --   SET Result = 'ǰ��з��� ��ǰ�� ��ǰ�� ǰ���� ���� �� �� �����ϴ�.', 
    --       Status = 1234,
    --       MessageType = 1234 
    --  FROM #TPUDelvItem                AS A 
    --  LEFT OUTER JOIN _TDAItem          AS B ON ( B.CompanySeq = @CompanySeq AND B.CfmSeq = A.DelvSeq ) 
    -- WHERE A.Status = 0 
    --   AND A.WorkingTag IN ( 'U', 'D' ) 
    --   AND B.IsAuto = '0' 
    --   AND B.CfmCode <> 0 
    ---- Ȯ��üũ, END 


    SELECT @DelvSeq = DelvSeq      
      FROM #TPUDelvItem      
  
    SELECT @QCAutoIn = EnvValue   
      FROM _TCOMEnv  
     WHERE CompanySeq = @CompanySeq  
       AND EnvSeq     = 6500  

    SELECT  DISTINCT ISNULL(B.IsNotAutoIn,0) AS IsNotAutoIn
      INTO #ROWCOUNT
      FROM #TPUDelvItem AS A  
           LEFT OUTER JOIN _TPDBaseItemQCType AS B ON B.CompanySeq = @CompanySeq  
                                                  AND B.ItemSeq    = A.ItemSeq

    -- �ڵ��԰� ����� ��� �ڵ��԰�̻�뿡 üũ �� ǰ���� ������ üũ --2013.10.04 UPDATED BY ��ǿ�  
    IF @QCAutoIn = '1' -- �ڵ��԰��� ���  
    BEGIN  
        IF 1 < (SELECT COUNT(*) FROM #ROWCOUNT)
        BEGIN
            EXEC dbo._SCOMMessage @MessageType OUTPUT,    
            @Status      OUTPUT,    
            @Results     OUTPUT,    
            2064               , -- @1 @2�� ���ԵǾ� �־� ���� �� �� �����ϴ�.
            @LanguageSeq       ,     
            16790,'�ڵ��԰�̻��',7,'ǰ��'   -- SELECT * FROM _TCADictionary WHERE WordSeq IN (16790, 7)

            UPDATE #TPUDelvItem    
               SET Result        = @Results    ,    
                   MessageType   = @MessageType,    
                   Status        = @Status    
              FROM #TPUDelvItem AS A
                   JOIN _TPDBaseItemQCType AS B ON B.CompanySeq = @CompanySeq
                                               AND B.ItemSeq    = A.ItemSeq
             WHERE Status = 0   
               AND WorkingTag IN ('A', 'U') 
               AND B.IsNotAutoIn = '1' 
        END
    END

    -- �˻籸��(SMQCType) 0�� ��� üũ         -- 12.05.29 BY �輼ȣ
    -- (�ູ��� ���� �˻籸�� 0���� ���°�� ���������� �߻� �ؼ� �߰�)

    IF EXISTS (SELECT 1 FROM #TPUDelvItem WHERE WorkingTag IN ('A', 'U'))
     BEGIN

        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1196               , -- @��(��) Ȯ���ϼ���
                              @LanguageSeq       ,   
                              474,''   -- select * from _TCADictionary where WOrd ='�˻籸��'


        UPDATE #TPUDelvItem  
           SET Result        = @Results    ,  
               MessageType   = @MessageType,  
               Status        = @Status  
          FROM #TPUDelvItem       
         WHERE Status = 0 
           AND (SMQCType IS NULL OR SMQCType = 0)
           AND WorkingTag IN ('A', 'U')
     END


       
    -- �����԰� ���� �� ���� ���� ����  
    IF EXISTS (SELECT 1 FROM #TPUDelvItem WHERE WorkingTag IN ('U', 'D') )  
    BEGIN  
        -------------------  
        --�԰����࿩��-----  
        -------------------  
        CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))      
            
        CREATE TABLE #Temp_Order(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT,IsDelvIn NCHAR(1))      
          
      
        CREATE TABLE #TCOMProgressTracking(IDX_NO INT, IDOrder INT, Seq INT,Serl INT, SubSerl INT,Qty DECIMAL(19, 5), StdQty DECIMAL(19,5) , Amt    DECIMAL(19, 5),VAT DECIMAL(19,5))        
      
        CREATE TABLE #OrderTracking(IDX_NO INT, POQty DECIMAL(19,5), POCurAmt DECIMAL(19,5))  
      
        INSERT #TMP_PROGRESSTABLE       
        SELECT 1, '_TPUDelvInItem'               -- �����԰�  
  
        -- ���ų�ǰ  
        INSERT INTO #Temp_Order(OrderSeq, OrderSerl, IsDelvIn)      
        SELECT  A.DelvSeq, A.DelvSerl, '2'      
          FROM #TPUDelvItem AS A WITH(NOLOCK)       
         WHERE A.WorkingTag IN ('U', 'D')  
           AND A.Status = 0  
  
        EXEC _SCOMProgressTracking @CompanySeq, '_TPUDelvItem', '#Temp_Order', 'OrderSeq', 'OrderSerl', ''      
         
          
        INSERT INTO #OrderTracking      
        SELECT IDX_NO,      
               SUM(CASE IDOrder WHEN 1 THEN Qty     ELSE 0 END),      
               SUM(CASE IDOrder WHEN 1 THEN Amt     ELSE 0 END)     
          FROM #TCOMProgressTracking      
         GROUP BY IDX_No      
  
        UPDATE #Temp_Order   
          SET IsDelvIn = '1'  
           FROM   #Temp_Order AS A  JOIN #TCOMProgressTracking AS B ON A.IDX_No = B.IDX_No  

  
        IF @QCAutoIn <> '1'    -- ���˻�ǰ �ڵ��԰� �ƴ� ���  
        BEGIN  
            -------------------  
            --�԰����࿩��END------  
            -------------------  
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  1044               , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                                  @LanguageSeq       ,   
                                  0,'��ǰ������'   -- SELECT * FROM _TCADictionary WHERE Word like '%����%'  
            UPDATE #TPUDelvItem  
               SET Result        = @Results    ,  
                   MessageType   = @MessageType,  
                   Status        = @Status  
              FROM #TPUDelvItem     AS A  
                   JOIN #Temp_Order AS B ON A.DelvSeq = B.OrderSeq  
             WHERE B.IsDelvIn = '1'  
        END  
  
        -------------------  
        --�԰����࿩��END------  
        -------------------  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1044               , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                              @LanguageSeq       ,   
                              0,'��ǰ������'   -- SELECT * FROM _TCADictionary WHERE Word like '%����%'  
        UPDATE #TPUDelvItem  
           SET Result        = @Results    ,  
               MessageType   = @MessageType,  
               Status        = @Status  
          FROM #TPUDelvItem     AS A  
               JOIN #Temp_Order AS B ON A.DelvSeq  = B.OrderSeq  
                                    AND A.DelvSerl = B.OrderSerl  
         WHERE B.IsDelvIn = '1'  
           AND A.SMQCType <> 6035001
    END        
    -- ����ι� ���� â�� �ƴ� ��� ���� ó��  
    SELECT @BizUnit = ISNULL(BizUnit, 0)   
      FROM #TPUDelvItem   
  
    IF EXISTS (SELECT 1 FROM #TPUDelvItem           AS A  
                             LEFT OUTER JOIN _TDAWH AS B ON A.WHSeq      = B.WHSeq  
                                                        AND B.CompanySeq = @CompanySeq  
                       WHERE B.BizUnit <> @BizUnit   
                         AND A.WorkingTag IN ('A', 'U')  
                         AND A.Status     = 0)  
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              11               , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                              @LanguageSeq       ,   
                              0,'����ι�'   -- SELECT * FROM _TCADictionary WHERE Word like '%����%'  
        UPDATE #TPUDelvItem  
           SET Result        = REPLACE(@Results,'@2', 'â��'),  
               MessageType   = @MessageType,  
               Status        = @Status  
          FROM #TPUDelvItem     AS A  
    END  
    -- �μ��˻簡 �Ϸ�� ���� ����/���� ����  
    IF EXISTS (SELECT 1 FROM _TPDQCTestReport  AS A  
                             JOIN #TPUDelvItem AS B ON A.SourceSeq  = B.DelvSeq   
                                                   AND A.SourceSerl = B.DelvSerl  
                       WHERE A.CompanySeq = @CompanySeq AND A.SourceType = '1' AND B.WorkingTag IN ('U', 'D') AND B.Status = 0)  
    BEGIN  
            EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                                  @Status      OUTPUT,      
                                  @Results     OUTPUT,      
                                  18                  , -- �ʼ��Է� ����Ÿ�� �Է��ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)      
                                  @LanguageSeq       ,       
                                    0, '�����μ��˻�� ����� ��'   -- SELECT * FROM _TCADictionary WHERE Word like '%��ǥ%'              
             UPDATE #TPUDelvItem      
                SET Result        = @Results,      
                    MessageType   = @MessageType,      
                    Status        = @Status    
              FROM  #TPUDelvItem        
    END          
      
     -------------------------------------------        
     -- �������Լ��ý� ����üũ   2012. 1. 2. hkim  
     -------------------------------------------        
     EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                           @Status      OUTPUT,        
                           @Results     OUTPUT,        
                           1                  , -- �ʼ��Է� ����Ÿ�� �Է��ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)        
                           @LanguageSeq       ,         
                           341,''   -- SELECT * FROM _TCADictionary WHERE Word like '%����%'                
     UPDATE #TPUDelvItem        
        SET Result        = @Results,        
            MessageType   = @MessageType,        
            Status        = @Status        
      WHERE IsFiction = '1' AND EvidSeq = 0         
                 
  
     
     -------------------------------------------        
     -- ��õ���� �������ں��� ��ǰ���� ������ ��� üũ      12.04.24 BY �輼ȣ
     ------------------------------------------- 
    
      
    IF EXISTS(SELECT 1 FROM #TPUDelvItem WHERE FromTableSeq = 13 ANd FromSeq <> 0)
     BEGIN


        EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                              @Status      OUTPUT,        
                              @Results     OUTPUT,        
                              1150                  , -- @1�� @2���� Ŀ�� �մϴ�.
                              @LanguageSeq       ,         
                              141,'',   -- ��ǰ��
                              166,''    -- ������

        UPDATE A
           SET   Result        = @Results,      
                 MessageType   = @MessageType,      
                 Status        = @Status  
          FROM #TPUDelvItem     AS A
          JOIN _TPUORDPO        AS B ON @CompanySeq = B.CompanySeq
                                    AND A.FromSeq = B.POSeq                                  
         WHERE A.DelvDate < B.PODate
           AND A.Status = 0
           AND A.WorkingTag IN ('A', 'U')
     END




    -- ����update---------------------------------------------------------------------------------------------------------------      
    SELECT @MaxDelvSerl = ISNULL(MAX(DelvSerl), 0)      
      FROM _TPUDelvItem       
     WHERE DelvSeq = @DelvSeq     
      AND CompanySeq   = @CompanySeq  
  
    UPDATE #TPUDelvItem      
       SET DelvSerl = @MaxDelvSerl + DataSeq      
      FROM #TPUDelvItem      
     WHERE WorkingTag = 'A'       
       AND Status = 0      
                 
    IF @WorkingTag = 'D'      
        UPDATE #TPUDelvItem      
           SET WorkingTag = 'D'      
  
  
    -- ���ش������  
    UPDATE #TPUDelvItem  
      SET StdUnitSeq = B.UnitSeq,  
          StdUnitQty = (CASE ISNULL(C.ConvDen,0) WHEN  0 THEN 0 ELSE Qty * (C.ConvNum/C.ConvDen) END)  
     FROM #TPUDelvItem AS A LEFT OUTER JOIN  _TDAItem AS B ON B.CompanySeq = @CompanySeq  
                                                            AND A.ItemSeq = B.ItemSeq  
                              LEFT OUTER JOIN _TDAItemUnit AS C ON C.CompanySeq = @CompanySeq  
                                                               AND A.ItemSeq = C.ItemSeq  
                                                               AND A.UnitSeq = C.UnitSeq  
  
  
    -- ���ش������� �Ҽ��� �ڸ� ó��        -- 12.01.25 BY �輼ȣ    
      
    EXEC dbo._SCOMEnv @CompanySeq,5,@UserSeq,@@PROCID,@QtyPoint OUTPUT   -- ����/���� ���� �Ҽ��� �ڸ���     
  
    UPDATE #TPUDelvItem    
      SET STDUnitQty = CASE WHEN B.SMDecPointSeq = 1003001 THEN ROUND(StdUnitQty, @QtyPoint, 0)     
                            WHEN B.SMDecPointSeq = 1003002 THEN ROUND(StdUnitQty, @QtyPoint, -1)                 
                            WHEN B.SMDecPointSeq = 1003003 THEN ROUND(StdUnitQty + CAST(4 AS DECIMAL(19, 5)) / POWER(10,(@QtyPoint + 1)), @QtyPoint)         
                            ELSE ROUND(StdUnitQty  , @QtyPoint, 0) END    
     FROM #TPUDelvItem AS A     
     JOIN _TDAUnit         AS B ON B.CompanySeq = @CompanySeq    
                               AND A.StdUnitSeq = B.UnitSeq      
  
              
    SELECT * FROM #TPUDelvItem      
       
             
RETURN  
go
begin tran 
exec hye_SPUDelvItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <PJTName />
    <PJTNo />
    <PJTSeq>0</PJTSeq>
    <WBSName />
    <WBSSeq>0</WBSSeq>
    <ItemName>����ũž ��ǻ��</ItemName>
    <ItemNo>DeskTop PC</ItemNo>
    <Spec />
    <UnitName>EA</UnitName>
    <MakerSeq>0</MakerSeq>
    <Price>3</Price>
    <Qty>4</Qty>
    <IsVAT>0</IsVAT>
    <VATRate>10</VATRate>
    <CurAmt>12</CurAmt>
    <CurVAT>1</CurVAT>
    <TotCurAmt>13</TotCurAmt>
    <DomPrice>0.03</DomPrice>
    <DomAmt>0</DomAmt>
    <DomVAT>0</DomVAT>
    <TotDomAmt>0</TotDomAmt>
    <WHName>��ǰâ��</WHName>
    <WHSeq>1</WHSeq>
    <DelvCustName />
    <DelvCustSeq>0</DelvCustSeq>
    <SalesCustName />
    <SalesCustSeq>0</SalesCustSeq>
    <SMPriceTypeName />
    <SMPriceType>0</SMPriceType>
    <SMQcTypeName>���˻�</SMQcTypeName>
    <SMQcType>6035001</SMQcType>
    <QcDate />
    <QCQty>0</QCQty>
    <QCCurAmt>0</QCCurAmt>
    <QCStdUnitQty>0</QCStdUnitQty>
    <STDUnitName>EA</STDUnitName>
    <STDUnitQty>4</STDUnitQty>
    <StdConvQty>1</StdConvQty>
    <UnitSeq>1</UnitSeq>
    <FromSerial />
    <Toserial />
    <Remark />
    <LotMngYN />
    <FromTableSeq>0</FromTableSeq>
    <FromSeq>0</FromSeq>
    <FromSerl>0</FromSerl>
    <STDUnitSeq>1</STDUnitSeq>
    <LotNo_Old />
    <ItemSeq_Old>0</ItemSeq_Old>
    <IsFiction>0</IsFiction>
    <FicRateNum>0</FicRateNum>
    <FicRateDen>0</FicRateDen>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <Memo1>0</Memo1>
    <Memo2>0</Memo2>
    <Memo3 />
    <Memo4 />
    <Memo5 />
    <Memo6 />
    <Memo7>0</Memo7>
    <Memo8>0</Memo8>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <DelvNo>201609290008</DelvNo>
    <DelvSeq>109</DelvSeq>
    <DelvSerl>0</DelvSerl>
    <ItemSeq>26</ItemSeq>
    <LotNo />
    <DelvDate>20160929</DelvDate>
    <BizUnit>1</BizUnit>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <PJTName />
    <PJTNo />
    <PJTSeq>0</PJTSeq>
    <WBSName />
    <WBSSeq>0</WBSSeq>
    <ItemName>�μ�_��ǰ1(Lot)</ItemName>
    <ItemNo>�μ�_��ǰ1(Lot)</ItemNo>
    <Spec />
    <UnitName>EA</UnitName>
    <MakerSeq>0</MakerSeq>
    <Price>3</Price>
    <Qty>2</Qty>
    <IsVAT>0</IsVAT>
    <VATRate>10</VATRate>
    <CurAmt>6</CurAmt>
    <CurVAT>1</CurVAT>
    <TotCurAmt>7</TotCurAmt>
    <DomPrice>0.03</DomPrice>
    <DomAmt>0</DomAmt>
    <DomVAT>0</DomVAT>
    <TotDomAmt>0</TotDomAmt>
    <WHName>��ǰâ��</WHName>
    <WHSeq>1</WHSeq>
    <DelvCustName />
    <DelvCustSeq>0</DelvCustSeq>
    <SalesCustName />
    <SalesCustSeq>0</SalesCustSeq>
    <SMPriceTypeName />
    <SMPriceType>0</SMPriceType>
    <SMQcTypeName>���˻�</SMQcTypeName>
    <SMQcType>6035001</SMQcType>
    <QcDate />
    <QCQty>0</QCQty>
    <QCCurAmt>0</QCCurAmt>
    <QCStdUnitQty>0</QCStdUnitQty>
    <STDUnitName>EA</STDUnitName>
    <STDUnitQty>2</STDUnitQty>
    <StdConvQty>1</StdConvQty>
    <UnitSeq>1</UnitSeq>
    <FromSerial />
    <Toserial />
    <Remark />
    <LotMngYN />
    <FromTableSeq>0</FromTableSeq>
    <FromSeq>0</FromSeq>
    <FromSerl>0</FromSerl>
    <STDUnitSeq>1</STDUnitSeq>
    <LotNo_Old />
    <ItemSeq_Old>0</ItemSeq_Old>
    <IsFiction>0</IsFiction>
    <FicRateNum>0</FicRateNum>
    <FicRateDen>0</FicRateDen>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <Memo1>0</Memo1>
    <Memo2>0</Memo2>
    <Memo3 />
    <Memo4 />
    <Memo5 />
    <Memo6 />
    <Memo7>0</Memo7>
    <Memo8>0</Memo8>
    <DelvNo>201609290008</DelvNo>
    <DelvSeq>109</DelvSeq>
    <DelvSerl>0</DelvSerl>
    <ItemSeq>4</ItemSeq>
    <LotNo />
    <DelvDate>20160929</DelvDate>
    <BizUnit>1</BizUnit>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <PJTName />
    <PJTNo />
    <PJTSeq>0</PJTSeq>
    <WBSName />
    <WBSSeq>0</WBSSeq>
    <ItemName>��ȸ��(�ݻ�)��</ItemName>
    <ItemNo>MLLSGSMID4565</ItemNo>
    <Spec>40/60MM</Spec>
    <UnitName>KG</UnitName>
    <MakerSeq>0</MakerSeq>
    <Price>4</Price>
    <Qty>2</Qty>
    <IsVAT>0</IsVAT>
    <VATRate>10</VATRate>
    <CurAmt>8</CurAmt>
    <CurVAT>1</CurVAT>
    <TotCurAmt>9</TotCurAmt>
    <DomPrice>0.04</DomPrice>
    <DomAmt>0</DomAmt>
    <DomVAT>0</DomVAT>
    <TotDomAmt>0</TotDomAmt>
    <WHName>(�Ϲ�â��)�ܾ�1����â��</WHName>
    <WHSeq>129</WHSeq>
    <DelvCustName />
    <DelvCustSeq>0</DelvCustSeq>
    <SalesCustName />
    <SalesCustSeq>0</SalesCustSeq>
    <SMPriceTypeName />
    <SMPriceType>0</SMPriceType>
    <SMQcTypeName>�̰˻�</SMQcTypeName>
    <SMQcType>6035002</SMQcType>
    <QcDate />
    <QCQty>0</QCQty>
    <QCCurAmt>0</QCCurAmt>
    <QCStdUnitQty>0</QCStdUnitQty>
    <STDUnitName>KG</STDUnitName>
    <STDUnitQty>2</STDUnitQty>
    <StdConvQty>1</StdConvQty>
    <UnitSeq>2</UnitSeq>
    <FromSerial />
    <Toserial />
    <Remark />
    <LotMngYN />
    <FromTableSeq>0</FromTableSeq>
    <FromSeq>0</FromSeq>
    <FromSerl>0</FromSerl>
    <STDUnitSeq>2</STDUnitSeq>
    <LotNo_Old />
    <ItemSeq_Old>0</ItemSeq_Old>
    <IsFiction>0</IsFiction>
    <FicRateNum>0</FicRateNum>
    <FicRateDen>0</FicRateDen>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <Memo1>0</Memo1>
    <Memo2>0</Memo2>
    <Memo3 />
    <Memo4 />
    <Memo5 />
    <Memo6 />
    <Memo7>0</Memo7>
    <Memo8>0</Memo8>
    <DelvNo>201609290008</DelvNo>
    <DelvSeq>109</DelvSeq>
    <DelvSerl>0</DelvSerl>
    <ItemSeq>71</ItemSeq>
    <LotNo />
    <DelvDate>20160929</DelvDate>
    <BizUnit>1</BizUnit>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730087,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730012
rollback 