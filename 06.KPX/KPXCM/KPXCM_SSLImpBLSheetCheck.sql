IF OBJECT_ID('KPXCM_SSLImpBLSheetCheck') IS NOT NULL 
    DROP PROC KPXCM_SSLImpBLSheetCheck
GO 

-- v2015.10.05 

-- ���� üũ by����õ 

-- v2012.10.24
  /*********************************************************************************************************************
     ȭ��� : �������_ǰ��üũ
     SP Name: _SUIImpBLItemCheck
     �ۼ��� : 2008.10.15 : 
     ������ : 
 ********************************************************************************************************************/
  -- ����BL�Է� - üũ 
 CREATE PROC KPXCM_SSLImpBLSheetCheck  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
  AS    
      DECLARE @Count           INT,
             @BLSeq           INT, 
             @MaxBLSerl       INT,
             @MessageType     INT,
             @Status          INT,
             @Results         NVARCHAR(250),
             @MinorSeq        INT
    
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TUIImpBLItem (WorkingTag NCHAR(1) NULL)  
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TUIImpBLItem'  
    
    
    SELECT @BLSeq = BLSeq
      FROM #TUIImpBLItem     
       -------------------------------------------
      -- �ʼ�������üũ
      -------------------------------------------
          EXEC dbo._SCOMMessage @MessageType OUTPUT,
                                @Status      OUTPUT,
                                @Results     OUTPUT,
                                1                  , -- �ʼ��Է� ����Ÿ�� �Է��ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)
                                @LanguageSeq       , 
                                '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%�㺸%'        
  
          UPDATE #TUIImpBLItem
             SET Result        = @Results,
                 MessageType   = @MessageType,
                 Status        = @Status
           WHERE BLSeq IS NULL
     
      --------------------------------------------------------------------------------------
      -- ����������üũ: UPDATE, DELETE �õ������������������鿡��ó��
      --------------------------------------------------------------------------------------
      IF NOT EXISTS (SELECT 1 
                       FROM #TUIImpBLItem AS A 
                             JOIN _TUIImpBLItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.BLSeq = B.BLSeq
                      WHERE A.WorkingTag IN ('U', 'D'))
      BEGIN
          EXEC dbo._SCOMMessage @MessageType OUTPUT,
                                @Status      OUTPUT,
                                @Results     OUTPUT,
                                7                  , -- �ڷᰡ��ϵǾ������ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)
                                @LanguageSeq       , 
                                '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
           UPDATE #TUIImpBLItem
             SET Result        = @Results,
                 MessageType   = @MessageType,
                 Status        = @Status
           WHERE WorkingTag IN ('U','D')
     END 
     
    --------------------------------------------------------------------------------------
    -- üũ1, 
    --------------------------------------------------------------------------------------
     
    ------------------------------------------------------------------------------------------
    -- üũ, L/C������ 5.00% �ʰ��Ͽ� ����/���� �� �� �����ϴ�. 
    ------------------------------------------------------------------------------------------

    
    CREATE TABLE #ProgBaseData 
    (
        IDX_NO      INT, 
        FromSeq     INT, 
        FromSerl    INT, 
    )
    INSERT INTO #ProgBaseData ( IDX_NO, FromSeq, FromSerl ) 
    SELECT IDX_NO, FromSeq, FromSerl 
      FROM #TUIImpBLItem 
     WHERE FromTableSeq = 41 
    
    
    CREATE TABLE #TMP_ProgressTable 
    (
        IDOrder   INT, 
        TableName NVARCHAR(100)
    ) 
    INSERT INTO #TMP_ProgressTable (IDOrder, TableName) 
    SELECT 1, '_TUIImpBLItem'   -- ������ ã�� ���̺�

    CREATE TABLE #TCOMProgressTracking
    (
        IDX_NO  INT,  
        IDOrder  INT, 
        Seq      INT, 
        Serl     INT, 
        SubSerl  INT, 
        Qty      DECIMAL(19,5), 
        StdQty   DECIMAL(19,5), 
        Amt      DECIMAL(19,5), 
        VAT      DECIMAL(19,5)
    ) 
 
    EXEC _SCOMProgressTracking 
            @CompanySeq = @CompanySeq, 
            @TableName = '_TSLImpPaymentItem',    -- ������ �Ǵ� ���̺�
            @TempTableName = '#ProgBaseData',  -- ������ �Ǵ� �������̺�
            @TempSeqColumnName = 'FromSeq',  -- �������̺��� Seq
            @TempSerlColumnName = 'FromSerl',  -- �������̺��� Serl
            @TempSubSerlColumnName = ''  
    

    DELETE A -- Update�� ��� �ش絥���� ���� 
      FROM #TCOMProgressTracking AS A 
     WHERE EXISTS (SELECT 1 FROM #TUIImpBLItem WHERE BLSeq = A.Seq AND BLSerl = A.Serl AND WorkingTag = 'U') 
    
     
    
    DECLARE @OverQtyRate DECIMAL(19,5)
    SELECT @OverQtyRate = EnvValue FROM KPX_TCOMEnvItem where CompanySeq = @CompanySeq AND EnvSeq = 59 AND EnvSerl = 1 
    
    
    UPDATE A 
       SET Result = 'L/C������ '+ CONVERT(NVARCHAR(10),CONVERT(DECIMAL(19,2),@OverQtyRate))+'% �ʰ��Ͽ� ����/���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #TUIImpBLItem AS A 
      JOIN _TSLImpPaymentItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PaymentSeq = A.FromSeq AND B.PaymentSerl = A.FromSerl ) 
      LEFT OUTER JOIN ( SELECT A.IDX_NO, SUM(B.Qty) AS SumQty 
                          FROM #TCOMProgressTracking AS A 
                          JOIN _TUIImpBLItem          AS B ON ( B.CompanySeq = @CompanySeq AND B.BLSeq = A.Seq AND B.BLSerl = A.Serl ) 
                         GROUP BY A.IDX_NO 
                      ) AS C ON ( A.IDX_NO = C.IDX_NO ) 
     WHERE A.FromTableSeq = 41 
       AND A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND ROUND((((ISNULL(C.SumQty,0) + ISNULL(A.Qty,0)) / B.Qty) * 100) - 100 ,2) > @OverQtyRate 
    ------------------------------------------------------------------------------------------
    -- üũ, END 
    ------------------------------------------------------------------------------------------
 
    
    -------------------------------------------  
    -- ��뵥����üũ  
    -------------------------------------------  
          SELECT @MinorSeq = ISNULL(MinorSeq, 0)
           FROM _TDAUMinorValue WITH (NOLOCK)
          WHERE CompanySeq = @CompanySeq
            AND MajorSeq   = 8212
            AND Serl       = 1003
            AND ValueText  = '1'
           EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                @Status      OUTPUT,  
                                @Results     OUTPUT,  
                                102                , -- @1 �����Ͱ� �����մϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 102)  
                                @LanguageSeq       ,   
                                0,'���ó��'   -- SELECT * FROM _TCADictionary WHERE Word like '%�㺸%'          
    
          UPDATE #TUIImpBLItem  
       SET Result        = @Results,  
            MessageType   = @MessageType,  
            Status        = @Status  
            FROM #TUIImpBLItem AS A
                 JOIN _TSLExpExpense AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                                       AND B.SMSourceType = 8215004
                                                       AND A.BLSeq   = B.SourceSeq
                 JOIN _TSLExpExpenseDesc AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq
                                                           AND B.ExpenseSeq = C.ExpenseSeq
           WHERE (A.WorkingTag = 'D')
 --             OR (A.WorkingTag = 'U' AND C.UMExpenseItem = @MinorSeq))
             AND  A.Status = 0
  
 --     -------------------------------------------  
 --     -- ����������üũ  
 --     -------------------------------------------  
 --         EXEC dbo._SCOMMessage @MessageType OUTPUT,  
 --                               @Status      OUTPUT,  
 --                               @Results     OUTPUT,  
 --                               102                , -- @1 �����Ͱ� �����մϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 102)  
 --                               @LanguageSeq       ,   
 --                               0,'������ü'   -- SELECT * FROM _TCADictionary WHERE Word like '%�㺸%'          
 --   
 --         UPDATE #TUIImpBLItem  
 --            SET Result        = @Results,  
 --                MessageType   = @MessageType,  
 --                Status        = @Status  
 --           FROM #TUIImpBLItem AS A
 --                JOIN _TSLExpExpense AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
 --                                                      AND B.SMSourceType = 8215004
 --                                                      AND A.BLSeq   = B.SourceSeq
 --                JOIN _TSLExpExpenseDesc AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq
 --                                                          AND B.ExpenseSeq = C.ExpenseSeq
 --                JOIN _TUIImpDelvCostDivItem AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq
 --                                                             AND C.ExpenseSeq  = D.ExpenseSeq
 --                                                             AND C.ExpenseSerl = D.ExpenseSerl
 --          WHERE A.WorkingTag IN ('U','D')
 --            AND A.Status = 0
  
 --     -------------------------------------------
 --     -- �ߺ�����üũ 
 --     -------------------------------------------
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)    
                           @LanguageSeq       ,     
                           0,'����BL'      
     UPDATE #TUIImpBLItem    
        SET Result        = REPLACE(@Results,'@2',RTRIM(B.BLSeq)),    
            MessageType   = @MessageType,    
            Status        = @Status    
       FROM #TUIImpBLItem AS A JOIN ( SELECT S.BLSeq, S.BLSerl  
                                             FROM (SELECT A1.BLSeq, A1.BLSerl  
                                                     FROM #TUIImpBLItem AS A1    
                                                    WHERE A1.WorkingTag IN ('U')    
                                                      AND A1.Status = 0    
                                                    UNION ALL    
                                                   SELECT A1.BLSeq, A1.BLSerl  
                                                     FROM _TUIImpBLItem AS A1    
                                                    WHERE A1.BLSeq  NOT IN (SELECT BLSeq    
                                                                                   FROM #TUIImpBLItem     
                                                                                  WHERE WorkingTag IN ('U','D')     
                                                                                    AND Status = 0)    
  AND A1.BLSerl  NOT IN (SELECT BLSerl    
                                                                                   FROM #TUIImpBLItem     
                                                                                  WHERE WorkingTag IN ('U','D')     
                                                                                    AND Status = 0)    
                                                     AND A1.CompanySeq = @CompanySeq    
                                           ) AS S    
                                     GROUP BY S.BLSeq, S.BLSerl  
                                     HAVING COUNT(1) > 1    
                                   ) AS B ON A.BLSeq  = B.BLSeq    
                                         AND A.BLSerl = B.BLSerl  
  
     -- ����update---------------------------------------------------------------------------------------------------------------
      SELECT @Count = COUNT(1) FROM #TUIImpBLItem WHERE WorkingTag = 'A' AND Status = 0    
        
     IF @Count > 0    
     BEGIN    
         SELECT @MaxBLSerl = ISNULL(MAX(BLSerl), 0)
           FROM _TUIImpBLItem 
          WHERE BLSeq = @BLSeq
          UPDATE #TUIImpBLItem
            SET BLSerl = @MaxBLSerl + IDX_NO
           FROM #TUIImpBLItem
          WHERE WorkingTag = 'A' 
            AND Status = 0
                
         IF @WorkingTag = 'D'
             UPDATE #TUIImpBLItem
                SET WorkingTag = 'D'
     END
      -------------------------------------------  
     -- �����ڵ�0���Ͻÿ����߻�
     -------------------------------------------      
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 1055)    
                           @LanguageSeq       
      UPDATE #TUIImpBLItem                               
        SET Result        = @Results     ,    
            MessageType   = @MessageType ,    
            Status        = @Status    
       FROM #TUIImpBLItem
      WHERE Status = 0
        AND (BLSeq = 0 OR BLSeq IS NULL)
      SELECT * FROM #TUIImpBLItem
      RETURN
GO 
begin tran 
exec KPXCM_SSLImpBLSheetCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BLSeq>78</BLSeq>
    <HSNo />
    <PJTSeq>0</PJTSeq>
    <WBSSeq>0</WBSSeq>
    <ItemName>[���ϰ���Ʈ] V-Belt, ���̺�Ʈ</ItemName>
    <ItemNo>90111003</ItemNo>
    <UnitName>EA</UnitName>
    <InvoiceQty>0</InvoiceQty>
    <PreBLQty>0</PreBLQty>
    <Price>1</Price>
    <Qty>25</Qty>
    <CurAmt>25</CurAmt>
    <DomAmt>25</DomAmt>
    <ShipDate />
    <Remark />
    <MakerName />
    <IsFin>0</IsFin>
    <BLRefNo />
    <BLSerl />
    <InvoiceRefNo />
    <InvoiceSerl>0</InvoiceSerl>
    <IsStop xml:space="preserve"> </IsStop>
    <StopDate xml:space="preserve">        </StopDate>
    <STDUnitName>EA</STDUnitName>
    <UnitSeq>6</UnitSeq>
    <STDQty>25</STDQty>
    <LotNo />
    <STDUnitSeq>6</STDUnitSeq>
    <StopEmpName />
    <StopEmpSeq>0</StopEmpSeq>
    <ItemSeq>851</ItemSeq>
    <MakerSeq>0</MakerSeq>
    <FromTableSeq>41</FromTableSeq>
    <FromSeq>138</FromSeq>
    <FromSerl>3</FromSerl>
    <FromSubSerl>0</FromSubSerl>
    <ToTableSeq>43</ToTableSeq>
    <FromQty>100</FromQty>
    <FromSTDQty>100</FromSTDQty>
    <FromAmt>100</FromAmt>
    <FromVAT>0</FromVAT>
    <PrevFromTableSeq>0</PrevFromTableSeq>
    <FromPgmSeq>0</FromPgmSeq>
    <ToPgmSeq>0</ToPgmSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BLSeq>78</BLSeq>
    <HSNo />
    <PJTSeq>0</PJTSeq>
    <WBSSeq>0</WBSSeq>
    <ItemName>[���ϰ���Ʈ] V-Belt, ���̺�Ʈ</ItemName>
    <ItemNo>90111005</ItemNo>
    <UnitName>EA</UnitName>
    <InvoiceQty>0</InvoiceQty>
    <PreBLQty>0</PreBLQty>
    <Price>1</Price>
    <Qty>65</Qty>
    <CurAmt>65</CurAmt>
    <DomAmt>65</DomAmt>
    <ShipDate />
    <Remark />
    <MakerName />
    <IsFin>0</IsFin>
    <BLRefNo />
    <BLSerl />
    <InvoiceRefNo />
    <InvoiceSerl>0</InvoiceSerl>
    <IsStop xml:space="preserve"> </IsStop>
    <StopDate xml:space="preserve">        </StopDate>
    <STDUnitName>EA</STDUnitName>
    <UnitSeq>6</UnitSeq>
    <STDQty>65</STDQty>
    <LotNo />
    <STDUnitSeq>6</STDUnitSeq>
    <StopEmpName />
    <StopEmpSeq>0</StopEmpSeq>
    <ItemSeq>853</ItemSeq>
    <MakerSeq>0</MakerSeq>
    <FromTableSeq>41</FromTableSeq>
    <FromSeq>138</FromSeq>
    <FromSerl>4</FromSerl>
    <FromSubSerl>0</FromSubSerl>
    <ToTableSeq>43</ToTableSeq>
    <FromQty>100</FromQty>
    <FromSTDQty>100</FromSTDQty>
    <FromAmt>100</FromAmt>
    <FromVAT>0</FromVAT>
    <PrevFromTableSeq>0</PrevFromTableSeq>
    <FromPgmSeq>0</FromPgmSeq>
    <ToPgmSeq>0</ToPgmSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032424,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1333rollback 