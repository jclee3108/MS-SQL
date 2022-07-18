IF OBJECT_ID('KPXCM_SPUDelvInQuantityAdjustSave') IS NOT NULL 
    DROP PROC KPXCM_SPUDelvInQuantityAdjustSave
GO 

-- v2015.10.08 

-- �ɹ�Į�� ���� ( ������� �߰� ) 

-- �԰�, ��ǰ, ����, ���԰˻��Ƿ�, ���� ����,�ݾ� Update �߰� by����õ 
/************************************************************
 ��  �� - ������-�԰�������� : Save
 �ۼ��� - 20141215
 �ۼ��� - ����ȯ
 ������ - 
************************************************************/
CREATE PROC KPXCM_SPUDelvInQuantityAdjustSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0
AS   
    
    CREATE TABLE #KPX_TPUDelvInQuantityAdjust (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPUDelvInQuantityAdjust'     
    IF @@ERROR <> 0 RETURN  
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPUDelvInQuantityAdjust')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPUDelvInQuantityAdjust'    , -- ���̺��        
                  '#KPX_TPUDelvInQuantityAdjust'    , -- �ӽ� ���̺��        
                  'AdjustSeq,DelvInSeq,DelvInSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   

-- �۾����� ���߱�: DELETE -> UPDATE -> INSERT

-- DELETE    
IF EXISTS (SELECT TOP 1 1 FROM #KPX_TPUDelvInQuantityAdjust WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
            DELETE KPX_TPUDelvInQuantityAdjust
              FROM #KPX_TPUDelvInQuantityAdjust      AS A JOIN KPX_TPUDelvInQuantityAdjust AS B ON ( A.AdjustSeq     = B.AdjustSeq ) 
                                                                                               AND ( A.DelvInSeq     = B.DelvInSeq ) 
                                                                                               AND ( A.DelvInSerl    = B.DelvInSerl ) 
             WHERE B.CompanySeq  = @CompanySeq
               AND A.WorkingTag  = 'D' 
               AND A.Status      = 0    
         
             IF @@ERROR <> 0  RETURN
    END  

-- UPDATE    
IF EXISTS (SELECT 1 FROM #KPX_TPUDelvInQuantityAdjust WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN
            UPDATE KPX_TPUDelvInQuantityAdjust
               SET AdjustDate    = A.AdjustDate    ,
                   DelvInSeq     = A.DelvInSeq      ,
                   OldQty        = A.OldQty        ,
                   DeptSeq       = A.DeptSeq       ,
                   EmpSeq        = A.EmpSeq        ,
                   Qty           = A.Qty          ,
                   LastUserSeq  = @UserSeq,
                   LastDateTime = GetDate()
              FROM #KPX_TPUDelvInQuantityAdjust      AS A JOIN KPX_TPUDelvInQuantityAdjust AS B ON ( A.AdjustSeq     = B.AdjustSeq ) 
                                                                                               AND ( A.DelvInSeq     = B.DelvInSeq ) 
                                                                                               AND ( A.DelvInSerl    = B.DelvInSerl ) 
                         
             WHERE B.CompanySeq = @CompanySeq
               AND A.WorkingTag = 'U' 
               AND A.Status     = 0    
    
            IF @@ERROR <> 0  RETURN
    END  

-- INSERT
IF EXISTS (SELECT 1 FROM #KPX_TPUDelvInQuantityAdjust WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
            INSERT INTO KPX_TPUDelvInQuantityAdjust (
                                                        CompanySeq, 
                                                        AdjustSeq       ,
                                                        AdjustDate      ,
                                                        DelvInSerl      ,
                                                        DelvInSeq       ,
                                                        OldQty          ,
                                                        DeptSeq         ,
                                                        EmpSeq          ,
                                                        Qty             ,
                                                        LastUserSeq     , 
                                                        LastDateTime 
                                                    ) 
            SELECT @CompanySeq      , 
                   AdjustSeq        ,
                   AdjustDate       ,
                   DelvInSerl       ,
                   DelvInSeq        ,
                   OldQty           ,
                   DeptSeq          ,
                   EmpSeq           ,
                   Qty              ,
                   @UserSeq         ,
                   GetDate() 
              FROM #KPX_TPUDelvInQuantityAdjust AS A   
             WHERE A.WorkingTag = 'A' 
               AND A.Status = 0    

            IF @@ERROR <> 0 RETURN
    END   
    
    -- �߰� by ����õ 
    
    -- ���� �� ��� �Ǽ����� ������ �԰�������� ���� by����õ 
    UPDATE A 
       SET Qty = OldQty 
      FROM #KPX_TPUDelvInQuantityAdjust AS A 
     WHERE A.WorkingTag = 'D' 
       AND A.Status = 0 
    
    --------------------------------------------------------------------------------------
    -- �԰� ���� Update 
    --------------------------------------------------------------------------------------
    UPDATE B
       SET B.Qty = A.Qty, 
           B.StdUnitQty = A.Qty * CASE WHEN ISNULL(ConvDen,0) = 0 THEN 0 ELSE CONVERT(DECIMAL(19,5),C.ConvNum/C.ConvDen) END, 
           B.CurAmt = A.Qty * B.Price, 
           B.DomAmt = A.Qty * B.DomPrice, 
           B.CurVAT = (A.Qty * B.Price) * (F.VatRate / 100), 
           B.DomVAT = (A.Qty * B.DomPrice) * (F.VatRate / 100)
      FROM #KPX_TPUDelvInQuantityAdjust AS A 
      JOIN _TPUDelvInItem               AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DelvInSeq = A.DelvInSeq AND B.DelvInSerl = A.DelvInSerl ) 
      LEFT OUTER JOIN _TDAItemUnit      AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq AND C.UnitSeq = B.UnitSeq ) 
      LEFT OUTER JOIN _TDAItemSales     AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDAVatRate       AS F WITH(NOLOCK) ON ( F.CompanySeq = @COmpanySeq AND F.SMVatType = E.SMVatType AND CONVERT(NCHAR(8),GETDATE(),112) BETWEEN F.SDate AND F.EDate ) 
    --------------------------------------------------------------------------------------
    -- �԰� ���� Update, END 
    --------------------------------------------------------------------------------------
    
    --------------------------------------------------------------------------------------
    -- ��ǰ ���� Update 
    --------------------------------------------------------------------------------------
    CREATE TABLE #TMP_SourceTable 
    (
        IDOrder   INT, 
        TableName NVARCHAR(100)
    )  
    INSERT INTO #TMP_SourceTable (IDOrder, TableName) 
    SELECT 1, '_TPUDelvItem'   -- ã�� �������� ���̺�
    
    CREATE TABLE #TCOMSourceTracking 
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
    
    EXEC _SCOMSourceTracking @CompanySeq = @CompanySeq, 
                             @TableName = '_TPUDelvInItem',  -- ���� ���̺�
                             @TempTableName = '#KPX_TPUDelvInQuantityAdjust',  -- �����������̺�
                             @TempSeqColumnName = 'DelvInSeq',  -- �������̺� Seq
                             @TempSerlColumnName = 'DelvInSerl',  -- �������̺� Serl
                             @TempSubSerlColumnName = '' 
    
    UPDATE C
       SET C.Qty = A.Qty, 
           C.StdUnitQty = A.Qty * CASE WHEN ISNULL(D.ConvDen,0) = 0 THEN 0 ELSE CONVERT(DECIMAL(19,5),D.ConvNum/D.ConvDen) END, 
           C.CurAmt = A.Qty * C.Price, 
           C.DomAmt = A.Qty * C.DomPrice, 
           C.CurVAT = (A.Qty * C.Price) * (F.VatRate / 100), 
           C.DomVAT = (A.Qty * C.DomPrice) * (F.VatRate / 100)
      FROM #KPX_TPUDelvInQuantityAdjust AS A 
      JOIN #TCOMSourceTracking          AS B              ON ( B.IDX_NO = A.IDX_NO ) 
      JOIN _TPUDelvItem                 AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.DelvSeq = B.Seq AND C.DelvSerl = B.Serl ) 
      LEFT OUTER JOIN _TDAItemUnit      AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = C.ItemSeq AND D.UnitSeq = C.UnitSeq ) 
      LEFT OUTER JOIN _TDAItemSales     AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = C.ItemSeq ) 
      LEFT OUTER JOIN _TDAVatRate       AS F WITH(NOLOCK) ON ( F.CompanySeq = @COmpanySeq AND F.SMVatType = E.SMVatType AND CONVERT(NCHAR(8),GETDATE(),112) BETWEEN F.SDate AND F.EDate ) 
    --------------------------------------------------------------------------------------
    -- ��ǰ ���� Update, END 
    --------------------------------------------------------------------------------------
    
    --------------------------------------------------------------------------------------
    -- ���� ������ ���� Update
    --------------------------------------------------------------------------------------
    UPDATE B
       SET B.Qty = A.Qty, 
           B.StdUnitQty = A.Qty * CASE WHEN ISNULL(ConvDen,0) = 0 THEN 0 ELSE CONVERT(DECIMAL(19,5),C.ConvNum/C.ConvDen) END, 
           B.CurAmt = A.Qty * B.Price, 
           B.DomAmt = A.Qty * B.DomPrice, 
           B.CurVAT = (A.Qty * B.Price) * (F.VatRate / 100), 
           B.DomVAT = (A.Qty * B.DomPrice) * (F.VatRate / 100)
      FROM #KPX_TPUDelvInQuantityAdjust AS A 
      JOIN _TPUBuyingAcc                AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.SourceSeq = A.DelvInSeq AND B.SourceSerl = A.DelvInSerl AND B.SourceType = 1 ) 
      LEFT OUTER JOIN _TDAItemUnit      AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq AND C.UnitSeq = B.UnitSeq ) 
      LEFT OUTER JOIN _TDAItemSales     AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDAVatRate       AS F WITH(NOLOCK) ON ( F.CompanySeq = @COmpanySeq AND F.SMVatType = E.SMVatType AND CONVERT(NCHAR(8),GETDATE(),112) BETWEEN F.SDate AND F.EDate ) 
    --------------------------------------------------------------------------------------
    -- ���� ������ ���� Update, END 
    --------------------------------------------------------------------------------------
    
    
    --------------------------------------------------------------------------------------
    -- ��ǰ->�԰� ���� ���� Update
    --------------------------------------------------------------------------------------    
    UPDATE C
       SET ToAmt = (CASE WHEN ISNULL(C.ToQty,0) = 0 THEN 0 ELSE C.ToAmt / C.ToQty END) * A.Qty, 
           ToVAT = (CASE WHEN ISNULL(C.ToQty,0) = 0 THEN 0 ELSE C.ToAmt / C.ToQty END) * A.Qty * (F.VatRate / 100), 
           ToQty = A.Qty, 
           ToSTDQty = A.Qty * CASE WHEN ISNULL(D.ConvDen,0) = 0 THEN 0 ELSE CONVERT(DECIMAL(19,5),D.ConvNum/D.ConvDen) END, 
           FromAmt = (CASE WHEN ISNULL(C.ToQty,0) = 0 THEN 0 ELSE C.ToAmt / C.ToQty END) * A.Qty, 
           FromVAT = (CASE WHEN ISNULL(C.ToQty,0) = 0 THEN 0 ELSE C.ToAmt / C.ToQty END) * A.Qty * (F.VatRate / 100), 
           FromQty = A.Qty, 
           FromSTDQty = A.Qty * CASE WHEN ISNULL(D.ConvDen,0) = 0 THEN 0 ELSE CONVERT(DECIMAL(19,5),D.ConvNum/D.ConvDen) END
      FROM #KPX_TPUDelvInQuantityAdjust AS A 
      JOIN _TPUDelvInItem               AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DelvInSeq = A.DelvInSeq AND B.DelvInSerl = A.DelvInSerl ) 
      JOIN _TCOMSourceDaily             AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ToTableSeq = 9 AND C.ToSeq = B.DelvInSeq AND C.ToSerl = B.DelvInSerl ) 
      LEFT OUTER JOIN _TDAItemUnit      AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = B.ItemSeq AND D.UnitSeq = B.UnitSeq ) 
      LEFT OUTER JOIN _TDAItemSales     AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDAVatRate       AS F WITH(NOLOCK) ON ( F.CompanySeq = @COmpanySeq AND F.SMVatType = E.SMVatType AND CONVERT(NCHAR(8),GETDATE(),112) BETWEEN F.SDate AND F.EDate ) 
    --------------------------------------------------------------------------------------
    -- ��ǰ->�԰� ���� ���� Update, END 
    --------------------------------------------------------------------------------------    
    
    
    --------------------------------------------------------------------------------------
    -- ���԰˻��Ƿ� ���� Update
    --------------------------------------------------------------------------------------        
    UPDATE C 
       SET ReqQty = A.Qty
      FROM #KPX_TPUDelvInQuantityAdjust AS A 
      JOIN #TCOMSourceTracking          AS B              ON ( B.IDX_NO = A.IDX_NO ) 
      JOIN KPX_TQCTestRequestItem       AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.SMSourceType = 1000522008 AND C.SourceSeq = B.Seq AND C.SourceSerl = B.Serl ) 
    --------------------------------------------------------------------------------------
    -- ���԰˻��Ƿ� ���� Update, END 
    --------------------------------------------------------------------------------------        
    
    
    --------------------------------------------------------------------------------------
    -- ���� ���� Update 
    --------------------------------------------------------------------------------------        
    /*    
    --exec _SLGInOutDailyBatch @xmlDocument=N'<ROOT>
    --  <DataBlock1>
    --    <WorkingTag>U</WorkingTag>
    --    <IDX_NO>1</IDX_NO>
    --    <DataSeq>1</DataSeq>
    --    <Selected>0</Selected>
    --    <Status>0</Status>
    --    <InOutSeq>100000711</InOutSeq>
    --    <InOutType>170</InOutType>
    --  </DataBlock1>
    --</ROOT>',@xmlFlags=2,@ServiceSeq=2619,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1137
    */
    
    
    IF (SELECT Count(1) FROM #KPX_TPUDelvInQuantityAdjust) = 0 
    BEGIN 
        SELECT * FROM #KPX_TPUDelvInQuantityAdjust 
        RETURN 
    END 
    ELSE 
    BEGIN 
        CREATE TABLE #KPX_TPUDelvInQuantityAdjust_Sub
        (
            WorkingTag      NCHAR(1), 
            IDX_NO          INT IDENTITY, 
            Selected        INT, 
            Status          INT, 
            InOutSeq        INT, 
            InOutType       INT 
        )
        
        INSERT INTO #KPX_TPUDelvInQuantityAdjust_Sub
        SELECT 'U' AS WorkingTag, 
               MAX(A.Selected) AS Selected, 
               MAX(A.Status) AS Status, 
               DelvInSeq, 
               170
          FROM #KPX_TPUDelvInQuantityAdjust AS A 
         GROUP BY DelvInSeq 
        
        
        DECLARE @XmlData    NVARCHAR(MAX), 
                @Cnt        INT 
        
        SELECT @Cnt = 1 
        
        WHILE ( 1 = 1 ) -- InOutSeq ���� �������� �� ����
        BEGIN 
            
            
            SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT WorkingTag, 
                                                              IDX_NO, 
                                                              IDX_NO AS DataSeq, 
                                                              Selected, 
                                                              Status, 
                                                              InOutSeq, 
                                                              InOutType 
                                                         FROM #KPX_TPUDelvInQuantityAdjust_Sub
                                                        WHERE IDX_NO = @Cnt 
                                                         FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS  
                                                        
                                                     )
                                     ) 
            
            CREATE TABLE #TEMP (WorkingTag NCHAR(1) NULL)             
            EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 1026739, 'DataBlock1', '#TEMP'        
            
            
            INSERT INTO #TEMP
            EXEC _SLGInOutDailyBatch @xmlDocument = @XmlData,
                                     @xmlFlags = 2,
                                     @ServiceSeq = 1026739, 
                                     @WorkingTag = N'',
                                     @CompanySeq = @CompanySeq, 
                                     @LanguageSeq = 1, 
                                     @UserSeq = @UserSeq, 
                                     @PgmSeq = @PgmSeq 
            
            
            IF @Cnt = (SELECT MAX(IDX_NO) FROM #KPX_TPUDelvInQuantityAdjust_Sub) 
            BEGIN
                BREAK
            END 
            ELSE
            BEGIN
                SELECT @Cnt = @Cnt + 1 
                DROP TABLE #TEMP 
            END 
        END 
        --------------------------------------------------------------------------------------
        -- ���� ���� Update, END 
        --------------------------------------------------------------------------------------        
        
        SELECT * FROM #KPX_TPUDelvInQuantityAdjust 
    END 

    RETURN    
        go 
        begin tran 
exec KPXCM_SPUDelvInQuantityAdjustSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BizUnit>1</BizUnit>
    <BizUnitName>�ƻ����</BizUnitName>
    <DelvInSeq>100000897</DelvInSeq>
    <DelvInSerl>2</DelvInSerl>
    <DelvInNo>NB1509240001</DelvInNo>
    <DelvInDate>20150924</DelvInDate>
    <CustSeq>1000195</CustSeq>
    <CustName>������-���Űŷ�ó</CustName>
    <DelvEmpSeq>0</DelvEmpSeq>
    <DelvEmpName />
    <ItemSeq>1052405</ItemSeq>
    <ItemName>������-������1_test</ItemName>
    <ItemNo>������-������1_test</ItemNo>
    <Spec />
    <UnitSeq>2</UnitSeq>
    <UnitName>Kg</UnitName>
    <Price>0</Price>
    <OldQty>25</OldQty>
    <Qty>15</Qty>
    <DiffQty>10</DiffQty>
    <WhSeq>1001052</WhSeq>
    <WhName>������-����â��</WhName>
    <DelvCustSeq>0</DelvCustSeq>
    <DelvCustName />
    <STDUnitName>Kg</STDUnitName>
    <STDUnitQty />
    <LOTNo>-20150924-0002</LOTNo>
    <Remark />
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032473,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026919
rollback 