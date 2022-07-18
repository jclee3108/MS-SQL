  
IF OBJECT_ID('hye_SSLOilDailySalesData') IS NOT NULL   
    DROP PROC hye_SSLOilDailySalesData  
GO  
  
-- v2016.10.14
  
-- �����Ǹ��Ϻ�����_hye-���������ͻ��� by ����õ 
CREATE PROC hye_SSLOilDailySalesData  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #SS3 (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#SS3'   
    IF @@ERROR <> 0 RETURN    
    

    IF EXISTS (SELECT 1 FROM #SS3 WHERE SlipKind = 1013901001) -- �Ǹ��Աݱ��п��� �Ա��� ���� ���� 
    BEGIN
        SELECT * 
          FROM #SS3 
        RETURN 
    END 

    DECLARE @XmlData        NVARCHAR(MAX), 
            @TableColumns   NVARCHAR(4000), 
            @SMExpKind      INT, 
            @WHSeq          INT, 
            @CustSeq        INT, 
            @OppAccSeq      INT, 
            @VatAccSeq      INT, 
            @EmpSeq         INT, 
            @DeptSeq        INT 
    

    
    -- ǰ��Mapping 
    SELECT D.ItemName, D.ItemSeq, B.ValueText AS POSItemSeq
      INTO #TDAItem 
      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAItem          AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = C.ValueSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.MajorSeq = 1013797
    
    -- ����κ�Mapping 
    SELECT A.ValueSeq AS BizUnit, B.ValueText AS  POSBizUnit 
      INTO #POSBizUnit
      FROM _TDAUMinorValue AS A 
      LEFT OUTER JOIN _TDAUMinorValue AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000002 ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.MajorSeq = 1013753
       AND A.Serl = 1000001
    
    
    -- �������ⱸ�� 
    SELECT @SMExpKind = 8009001

    -- ���â�� 
    
    DECLARE @erp_BizUnit INT 
    
    SELECT @erp_BizUnit = BizUnit 
      FROM #POSBizUnit AS A 
     WHERE EXISTS (SELECT 1 FROM #SS3 WHERE BizUnit = A.POSBizUnit) 


    SELECT @EmpSeq = B.ValueSeq, -- ����� 
           @DeptSeq = (SELECT DeptSeq FROM _fnAdmEmpOrd(@CompanySeq, '') WHERE EmpSeq = B.ValueSeq), -- �μ� 
           @CustSeq = C.ValueSeq, -- �ŷ�ó 
           @WHSeq = D.ValueSeq 
      FROM _TDAUMinorValue AS A 
      LEFT OUTER JOIN _TDAUMinorValue AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000002 ) -- ����� 
      LEFT OUTER JOIN _TDAUMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000003 ) -- �ŷ�ó 
      LEFT OUTER JOIN _TDAUMinorValue AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.MinorSeq AND D.Serl = 1000004 ) -- â�� 
     WHERE A.CompanySeq = @CompanySeq
       AND A.MajorSeq = 1013955 
       AND A.Serl = 1000001 
       AND A.ValueSeq = @erp_BizUnit 
    
    -- �ܻ����� 
    SELECT @OppAccSeq = (SELECT EnvValue FROM hye_TCOMEnvItem WHERE CompanySeq = 1 AND EnvSeq = 1 AND EnvSerl = 1) -- Mapping���� EnvSeq = 1 
    -- �ΰ���
    SELECT @VatAccSeq = (SELECT EnvValue FROM hye_TCOMEnvItem WHERE CompanySeq = 1 AND EnvSeq = 2 AND EnvSerl = 1) -- Mapping���� EnvSeq = 2 

    -- �Ұ�, ���� �����ϱ� ���� Main ���̺� ��� 
    CREATE TABLE #Main 
    (
        IDX_NO          INT IDENTITY, 
        WorkingTag      NCHAR(1), 
        item_code       NVARCHAR(100), 
        erp_itemseq     INT, 
        sale_total_qty  DECIMAL(19,5), 
        sale_price      DECIMAL(19,5), 
        total_amt       DECIMAL(19,5), 
        BizUnit         INT, 
        erp_BizUnit     INT, 
        StdDate         NCHAR(8), 
        CustSeq         INT, 
        EmpSeq          INT, 
        DeptSeq         INT, 
        Ori_IDX_NO      INT,
        CurrSeq         INT 
    )
    INSERT INTO #Main 
    ( 
        item_code, erp_itemseq, sale_total_qty, sale_price, total_amt, 
        BizUnit, erp_BizUnit, StdDate, CustSeq, 
        EmpSeq, DeptSeq, Ori_IDX_NO, CurrSeq 
    )
    SELECT A.item_code, B.ItemSeq, A.sale_total_qty, A.sale_price, A.total_amt, 
           A.BizUnit, D.BizUnit, A.StdDate, @CustSeq, 
           @EmpSeq, @DeptSeq, A.IDX_NO, (SELECT EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 13)
      FROM #SS3                 AS A 
      JOIN #TDAItem             AS B ON ( B.POSItemSeq = A.item_code ) 
      JOIN #POSBizUnit          AS D ON ( D.POSBizUnit = A.BizUnit ) 
     WHERE sort = 1 
    
    
    -- �ű� IDX_NO �� ���� IDX_NO �����ϱ� 
    ALTER TABLE #SS3 ADD New_IDX_NO INT NULL 

    UPDATE A
       SET New_IDX_NO = B.IDX_NO 
      FROM #SS3     AS A 
      JOIN #Main    AS B ON ( B.Ori_IDX_NO = A.IDX_NO ) 
    
    -- WorkingTag ���� 
    UPDATE A
       SET WorkingTag = CASE WHEN @WorkingTag = 'C' THEN 'A' 
                             WHEN @WorkingTag = 'CC' THEN 'D' 
                             ELSE '' END 
      FROM #Main AS A 
    -- WorkingTag ����, END 

    -- �Ǹ�, �Ա� ���� �� ������ �ϸ����� ���� ������ �״�� ���� 
    DECLARE @p_div_code INT, 
            @p_yyyymmdd NCHAR(8) 
    
    SELECT @p_div_code = BizUnit, 
           @p_yyyymmdd = StdDate 
      FROM #Main  

    IF @WorkingTag = 'C' AND EXISTS ( 
                                        SELECT 1 
                                            FROM hye_TSLOilDailySalesDataRelation 
                                        WHERE date_type     = 'DD'
                                          AND div_code      = @p_div_code
                                          AND process_date  = @p_yyyymmdd 
                                          AND CompanySeq    = @CompanySeq 
                                    )
    BEGIN 
        SELECT * 
          FROM #SS3 
        RETURN 
    END 
    
    /***********************************************************************************************************************
    -- �ŷ�����, Start
    ************************************************************************************************************************/
    -- �ϸ�����Ҹ� ���� InvoiceSeq ������Ʈ 
    ALTER TABLE #Main ADD InvoiceSeq INT NULL

    UPDATE A 
       SET InvoiceSeq = B.InvoiceSeq
      FROM #Main AS A 
      LEFT OUTER JOIN hye_TSLOilDailySalesDataRelation AS B ON ( B.CompanySeq = @CompanySeq 
                                                             AND B.div_Code = A.BizUnit 
                                                             AND B.process_date = A.StdDate 
                                                             AND B.date_type = 'DD' 
                                                               ) 

    -- �������̺� 
    CREATE TABLE #TCOMCloseItemCheck (WorkingTag NCHAR(1) NULL)   
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2639, 'DataBlock2', '#TCOMCloseItemCheck'   
    TRUNCATE TABLE #TCOMCloseItemCheck
    IF @@ERROR <> 0 RETURN     
    
    -- ��������������̺� 
    CREATE TABLE #TSLDeleteOutSum (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 4784, 'DataBlock1', '#TSLDeleteOutSum' 
    TRUNCATE TABLE #TSLDeleteOutSum
    IF @@ERROR <> 0 RETURN 

    -- ����������̺� 
    CREATE TABLE #TLGInOutDailyBatch (WorkingTag NCHAR(1) NULL)
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2619, 'DataBlock1', '#TLGInOutDailyBatch'      
    TRUNCATE TABLE #TLGInOutDailyBatch
    IF @@ERROR <> 0 RETURN    

    -- ��������������̺� 
    CREATE TABLE #TSLCreateOutSum (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 4784, 'DataBlock1', '#TSLCreateOutSum' 
    TRUNCATE TABLE #TSLCreateOutSum
    IF @@ERROR <> 0 RETURN

    --=======================================================================
    -- �ŷ�����
    --=======================================================================    
    /*
    ------------------------------            
    -- �������� üũ      
    ------------------------------   
    --�������� ��������
    --CREATE TABLE #TCOMGetCloseTypeTMP (IDX_NO INT, CloseTypeSeq INT)

    --INSERT INTO #TCOMGetCloseTypeTMP    
    --exec _SCOMGetCloseTypeQuery @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=4960,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=41,@PgmSeq=@PgmSeq
    --return 
    
    SELECT DISTINCT
           WorkingTag, 
           InvoiceSeq, 
           StdDate,  
           erp_BizUnit AS BizUnit 
      INTO #Close
      FROM #Main
    
    select *From #Close 
    return 

    ------------------------------       
    -- �������� üũ
    ------------------------------           
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT DISTINCT 
                                                       WorkingTag
                                                      ,1 AS IDX_NO
                                                      ,1 AS DataSeq     
                                                      ,'0' AS Selected
                                                      ,(SELECT MAX(CloseTypeSeq) FROM #TCOMGetCloseTypeTMP) AS DtlUnitSeq
                                                      ,BizUnit
                                                      ,StdDate      AS Date
                                                      ,2639         AS ServiceSeq
                                                      ,2            AS MethodSeq
                                                  FROM #Close AS A
                                                   FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  
    CREATE TABLE #TCOMCloseCheck (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2639, 'DataBlock1', '#TCOMCloseCheck'  
    TRUNCATE TABLE #TCOMCloseCheck
    IF @@ERROR <> 0 RETURN  

    INSERT INTO #TCOMCloseCheck    
    EXEC _SCOMCloseCheck         
         @xmlDocument  = @XmlData,        
         @xmlFlags     = 2,        
         @ServiceSeq   = 2639,        
         @WorkingTag   = '',        
         @CompanySeq   = @CompanySeq,        
         @LanguageSeq  = 1,        
         @UserSeq      = @UserSeq,
         @PgmSeq       = @PgmSeq      


    IF EXISTS (SELECT 1 FROM #TCOMCloseCheck   WHERE Status <> 0) 
    BEGIN
        UPDATE A
           SET Result = B.Result, 
               MessageType = B.MessageType, 
               Status = B.Status 
          FROM #SS3                 AS A 
          JOIN ##TCOMCloseCheck     AS B ON ( 1 = 1 ) 
         WHERE sort = 1 
        
        SELECT * FROM #SS3 
        RETURN  
    END 

    */
    ------------------------------            
    -- �ŷ����� ������ Check           
    ------------------------------      
    SELECT DISTINCT 
           WorkingTag, 
           1 AS IDX_NO, 
           1 AS DataSeq, 
           0 AS Status, 
           1 AS Selected, 
           --'DataBlock1' AS TABLE_NAME, 
           '1' AS IsChangedMst, 
           InvoiceSeq, 
           '' AS InvoiceNo, 
           8017002 AS SMSalesCrtKind, 
           erp_BizUnit AS BizUnit, 
           StdDate AS InvoiceDate, 
           CustSeq, 
           8020001 AS UMOutKind, 
           8060001 AS SMConsignKind, 
           CurrSeq, 
           1 AS ExRate, 
           '0' AS IsStockSales, 
           EmpSeq, 
           DeptSeq, 
           @SMExpKind AS SMExpKind
      INTO #Invoice_Xml
      FROM #Main 
      
    
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(            
                                                SELECT *             
                                                  FROM #Invoice_Xml            
                                                   FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS            
                                            ))            
      
    -- ���� ����Ÿ ��� ����    
    CREATE TABLE #TSLInvoice (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, 2, @CompanySeq, 2328, 'DataBlock1', '#TSLInvoice'            
    TRUNCATE TABLE #TSLInvoice
            
    INSERT INTO #TSLInvoice        
    EXEC _SSLInvoiceCheck             
         @xmlDocument  = @XmlData,            
         @xmlFlags     = 2,            
         @ServiceSeq   = 2328,            
         @WorkingTag   = '',            
         @CompanySeq   = @CompanySeq,            
         @LanguageSeq  = 1,            
         @UserSeq      = @UserSeq,         
         @PgmSeq       = @PgmSeq            
    
    IF EXISTS (SELECT 1 FROM #TSLInvoice WHERE Status <> 0) 
    BEGIN
        UPDATE A
           SET Result = B.Result, 
               MessageType = B.MessageType, 
               Status = B.Status 
          FROM #SS3         AS A 
          JOIN #TSLInvoice  AS B ON ( 1 = 1 ) 
         WHERE sort = 1 
        
        SELECT * FROM #SS3 
        RETURN  
    END 


    UPDATE A
       SET InvoiceSeq = B.InvoiceSeq 
      FROM #Main        AS A 
      JOIN #TSLInvoice  AS B ON ( B.BizUnit = A.erp_BizUnit AND B.InvoiceDate = A.StdDate ) 

    ------------------------------            
    -- �ŷ����� ������ Check
    ------------------------------  
    SELECT DISTINCT 
           A.WorkingTag, 
           A.IDX_NO, 
           A.IDX_NO AS DataSeq, 
           0 AS Status, 
           1 AS Selected, 
           A.InvoiceSeq, 
           A.IDX_NO AS InvoiceSerl, 
           A.erp_itemSeq AS ItemSeq, 
           B.UnitSeq, 
           A.sale_price AS Price, 
           A.sale_total_qty AS Qty, 
           '0' AS IsInclusedVAT, 
           CONVERT(INT,REPLACE(D.MinorName,'%','')) AS VATRate, 
           A.total_amt AS CurAmt, 
           A.total_amt * (CONVERT(DECIMAL(19,5),REPLACE(D.MinorName,'%','')) / 100)  CurVAT, 
           A.total_amt AS DomAmt, 
           A.total_amt * (CONVERT(DECIMAL(19,5),REPLACE(D.MinorName,'%','')) / 100)  DomVAT, 
           B.UnitSeq AS STDUnitSeq, 
           A.sale_total_qty AS STDQty, 
           @WHSeq AS WHSeq, 
           A.erp_itemSeq AS STDItemSeq, 
           0 AS ItemPrice, 
           0 AS CustPrice, 
           0 AS UMEtcOutKind, 
           0 AS TrustCustSeq, 
           '' AS LotNo, 
           '' AS SerialNo
      INTO #InvoiceItem_Xml 
      FROM #Main                    AS A 
      LEFT OUTER JOIN _TDAItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.erp_itemSeq ) 
      LEFT OUTER JOIN _TDAItemSales AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDASMinor    AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.SMVatType ) 
    
    --select * From #InvoiceItem_Xml 
    --return 

    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(            
                                                SELECT *             
                                                  FROM #InvoiceItem_Xml            
                                                   FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS            
                                            ))            
      
    -- ���� ����Ÿ ��� ����    
    CREATE TABLE #TSLInvoiceItem (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, 2, @CompanySeq, 2328, 'DataBlock2', '#TSLInvoiceItem'            
    TRUNCATE TABLE #TSLInvoiceItem
    

    
    INSERT INTO #TSLInvoiceItem        
    EXEC _SSLInvoiceItemCheck             
         @xmlDocument  = @XmlData,            
         @xmlFlags     = 2,            
         @ServiceSeq   = 2328,            
         @WorkingTag   = '',            
         @CompanySeq   = @CompanySeq,            
         @LanguageSeq  = 1,            
         @UserSeq      = @UserSeq,         
         @PgmSeq       = @PgmSeq   
    
    --select *from _TSLInvoiceItem where invoiceseq = 666 
    --select * from #TSLInvoiceItem 
    --return 
    
    IF EXISTS (SELECT 1 FROM #TSLInvoiceItem WHERE Status <> 0) 
    BEGIN
        UPDATE A
           SET Result = B.Result, 
               MessageType = B.MessageType, 
               Status = B.Status 
          FROM #SS3             AS A 
          JOIN #TSLInvoiceItem  AS B ON ( B.IDX_NO = A.New_IDX_NO ) 
         WHERE sort = 1 
        
        SELECT * FROM #SS3 
        RETURN  
    END 

    SELECT A.WorkingTag, 
           A.IDX_NO, 
           A.DataSeq, 
           A.Status, 
           A.Selected, 
           A.WHSeq, 
           B.EmpSeq
      INTO #TLGWHEmp_Xml
      FROM #TSLInvoiceItem  AS A 
      JOIN #TSLInvoice      AS B ON ( B.InvoiceSeq = A.InvoiceSeq ) 

    
    
    ------------------------------        
    -- â��������ġüũ
    ------------------------------   
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *         
                                                    FROM #TLGWHEmp_Xml
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  
    CREATE TABLE #TLGWHEmp (WorkingTag NCHAR(1) NULL)    
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 935, 'DataBlock1', '#TLGWHEmp' 
    TRUNCATE TABLE #TLGWHEmp
    IF @@ERROR <> 0 RETURN   

    INSERT INTO #TLGWHEmp    
    EXEC _SLGWHStockEmpCheck
            @xmlDocument  = @XmlData,        
            @xmlFlags     = 2,        
            @ServiceSeq   = 935,        
            @WorkingTag   = '',        
            @CompanySeq   = @CompanySeq,        
            @LanguageSeq  = 1,        
            @UserSeq      = @UserSeq,
            @PgmSeq       = @PgmSeq      
    
    IF EXISTS (SELECT 1 FROM #TLGWHEmp WHERE Status <> 0) 
    BEGIN
        UPDATE A
           SET Result = B.Result, 
               MessageType = B.MessageType, 
               Status = B.Status 
          FROM #SS3             AS A 
          JOIN #TLGWHEmp        AS B ON ( B.IDX_NO = A.New_IDX_NO ) 
         WHERE sort = 1 
        
        SELECT * FROM #SS3 
        RETURN  
    END 
    
    ------------------------------            
    -- �ŷ����� ������ Save 
    ------------------------------  
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(            
                                                SELECT *             
                                                  FROM #TSLInvoice            
                                                   FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS            
                                            )) 
    
    TRUNCATE TABLE #TSLInvoice 

    INSERT INTO #TSLInvoice        
    EXEC _SSLInvoiceSave
         @xmlDocument  = @XmlData,            
         @xmlFlags     = 2,            
         @ServiceSeq   = 2328,            
         @WorkingTag   = '',            
         @CompanySeq   = @CompanySeq,            
         @LanguageSeq  = 1,            
         @UserSeq      = @UserSeq,         
         @PgmSeq       = @PgmSeq    
    
    ------------------------------            
    -- �ŷ����� ������ Save 
    ------------------------------  
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(            
                                                SELECT *             
                                                  FROM #TSLInvoiceItem            
                                                   FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS            
                                            )) 
    
    TRUNCATE TABLE #TSLInvoiceItem 

    INSERT INTO #TSLInvoiceItem        
    EXEC _SSLInvoiceItemSave
         @xmlDocument  = @XmlData,            
         @xmlFlags     = 2,            
         @ServiceSeq   = 2328,            
         @WorkingTag   = '',            
         @CompanySeq   = @CompanySeq,            
         @LanguageSeq  = 1,            
         @UserSeq      = @UserSeq,         
         @PgmSeq       = @PgmSeq   
    --select * from hye_TSLOilDailySalesDataRelation 
        ------------------------------ 
    -- Relation ���̺� Insert
    ------------------------------ 
    INSERT INTO hye_TSLOilDailySalesDataRelation 
    (
        CompanySeq, div_code, process_date, date_type, InvoiceSeq, 
        SalesSeq, BillSeq, MaxReceiptSeq, LastUserSeq, LastDateTime, 
        PgmSeq, erp_BizUnit
    )
    SELECT DISTINCT 
           @CompanySeq, BizUnit, STDDate, 'DD', InvoiceSeq, 
           0, 0, 0, @UserSeq, GETDATE(), 
           @PgmSeq, erp_BizUnit 
      FROM #Main 
     WHERE WorkingTag = 'A' 
    
    ------------------------------            
    -- �ŷ����� Ȯ�������� ����
    ------------------------------ 
    INSERT INTO _TSLInvoice_Confirm
    (
        CompanySeq,CfmSeq,CfmSerl,CfmSubSerl,CfmSecuSeq,
        IsAuto,CfmCode,CfmDate,CfmEmpSeq,UMCfmReason,
        CfmReason,LastDateTime
    )
    SELECT @CompanySeq, InvoiceSeq, 0, 0, 6339,
           '1', '1', InvoiceDate, EmpSeq, 0,
           '', GETDATE()
      FROM #TSLInvoice 
     WHERE WorkingTag = 'A' 
    
    ------------------------------            
    -- �ŷ������������     
    ------------------------------ 
    SELECT WorkingTag, 
           IDX_NO, 
           DataSeq, 
           Selected, 
           MessageType, 
           Status, 
           Result, 
           Row_IDX, 
           InvoiceSeq
      INTO #TSLCreateInvoiceSum_Xml
      FROM #TSLInvoice
    
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *      
                                                    FROM #TSLCreateInvoiceSum_Xml     
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                         
                                            ))  
    
    CREATE TABLE #TSLCreateInvoiceSum (WorkingTag NCHAR(1) NULL)   
    ExEC _SCAOpenXmlToTemp @xmlDocument, 2, @CompanySeq, 4784, 'DataBlock1', '#TSLCreateInvoiceSum'   
    TRUNCATE TABLE #TSLCreateInvoiceSum
    IF @@ERROR <> 0 RETURN        

    INSERT INTO #TSLCreateInvoiceSum    
    EXEC _SSLCreateInvoiceSum
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 4784,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq      

    IF EXISTS (SELECT 1 FROM #TSLCreateInvoiceSum WHERE Status <> 0) 
    BEGIN
        UPDATE A
           SET Result = B.Result, 
               MessageType = B.MessageType, 
               Status = B.Status 
          FROM #SS3                 AS A 
          JOIN #TSLCreateInvoiceSum AS B ON ( 1 = 1 ) 
        
        SELECT * FROM #SS3 
        RETURN  
    END 
    --=======================================================================
    -- �ŷ�����, END 
    --=======================================================================    
    --=======================================================================
    -- �ŷ����� ���ó��
    --=======================================================================
    ------------------------------        
    -- ���Ҹ���üũ
    ------------------------------           
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT A.WorkingTag
                                                        ,A.IDX_NO
                                                        ,A.DataSeq     
                                                        ,A.Selected
                                                        ,A.MessageType
                                                        ,A.Status
                                                        ,A.Result
                                                        ,A.Row_IDX
                                                        ,A.BizUnit
                                                        ,A.BizUnit     AS BizUnitOld
                                                        ,A.InvoiceDate AS Date
                                                        ,A.InvoiceDate AS DateOld
                                                        ,A.DeptSeq     AS DeptSeq
                                                        ,A.DeptSeq     AS DeptSeqOld
                                                        ,2327          AS ServiceSeq
                                                        ,7             AS MethodSeq
                                                        ,B.ItemSeq     AS ItemSeq
                                                    FROM #TSLInvoice                AS A
                                                    LEFT OUTER JOIN #TSLInvoiceItem AS B ON ( B.InvoiceSeq = A.InvoiceSeq ) 
                                                    FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS        
                                            ))  


    TRUNCATE TABLE #TCOMCloseItemCheck
    INSERT INTO #TCOMCloseItemCheck    
    EXEC _SCOMCloseItemCheck
            @xmlDocument  = @XmlData,        
            @xmlFlags     = 2,        
            @ServiceSeq   = 2639,        
            @WorkingTag   = '',        
            @CompanySeq   = @CompanySeq,        
            @LanguageSeq  = 1,        
            @UserSeq      = @UserSeq,
            @PgmSeq       = @PgmSeq      
    
    IF EXISTS (SELECT 1 FROM #TCOMCloseItemCheck WHERE Status <> 0) 
    BEGIN
        UPDATE A
            SET Result = B.Result, 
                MessageType = B.MessageType, 
                Status = B.Status 
            FROM #SS3                 AS A 
            JOIN #TCOMCloseItemCheck  AS B ON ( B.IDX_NO = A.New_IDX_NO ) 
        
        SELECT * FROM #SS3 
        RETURN  
    END 

        

    --SPȣ������ �ʰ� �׳� ���ó�� UPDATE ��
    -- �α� �����  
    SELECT @TableColumns = dbo._FGetColumnsForLog('_TSLInvoice')  
        
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
    EXEC _SCOMLog @CompanySeq  ,
                    @UserSeq     ,
                    '_TSLInvoice', -- �����̺��
                    '#TSLInvoice', -- �������̺��
                    'InvoiceSeq' , -- Ű�� �������� ���� , �� �����Ѵ�. 
                    @TableColumns, '', @PgmSeq 
    
    UPDATE _TSLInvoice     
        SET IsDelvCfm     = '1', -- ����� 
            DelvCfmEmpSeq =  @UserSeq,   
            DelvCfmDate   =  B.InvoiceDate,   
            PgmSeq        = @PgmSeq   
        FROM _TSLInvoice AS A   
        JOIN #TSLInvoice AS B ON ( A.InvoiceSeq = B.InvoiceSeq ) 
        WHERE A.CompanySeq = @CompanySeq  
        AND B.Status = 0  
    
    IF @@ERROR <> 0 RETURN   
    
        
    ------------------------------        
    -- ����������
    ------------------------------   
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT WorkingTag
                                                        ,IDX_NO
                                                        ,DataSeq     
                                                        ,Selected
                                                        ,MessageType
                                                        ,Status
                                                        ,Result
                                                        ,Row_IDX
                                                        ,InvoiceSeq         
                                                    FROM #TSLInvoice     
                                                FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  
    TRUNCATE TABLE #TSLDeleteOutSum
    INSERT INTO #TSLDeleteOutSum    
    EXEC _SSLDeleteInvoiceOutSum
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 4784,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq      
    
    IF EXISTS (SELECT 1 FROM #TSLDeleteOutSum WHERE Status <> 0) 
    BEGIN
        UPDATE A
            SET Result = B.Result, 
                MessageType = B.MessageType, 
                Status = B.Status 
            FROM #SS3                 AS A 
            JOIN #TSLDeleteOutSum AS B ON ( 1 = 1 ) 
        
        SELECT * FROM #SS3 
        RETURN  
    END 
               
    ------------------------------        
    -- ������-����� �ϰ�����
    ------------------------------   
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT WorkingTag
                                                        ,IDX_NO
                                                        ,DataSeq     
                                                        ,Selected
                                                        ,MessageType
                                                        ,Status
                                                        ,Result
                                                        ,Row_IDX
                                                        ,InvoiceSeq AS InOutSeq
                                                        ,10         AS InOutType         
                                                    FROM #TSLInvoice     
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                            ))  
    
    TRUNCATE TABLE #TLGInOutDailyBatch
    INSERT INTO #TLGInOutDailyBatch    
    EXEC _SLGInOutDailyBatch
            @xmlDocument  = @XmlData,        
            @xmlFlags     = 2,        
            @ServiceSeq   = 2619,        
            @WorkingTag   = '',        
            @CompanySeq   = @CompanySeq,        
            @LanguageSeq  = 1,        
            @UserSeq      = @UserSeq,
            @PgmSeq       = @PgmSeq      

    IF EXISTS (SELECT 1 FROM #TLGInOutDailyBatch WHERE Status <> 0) 
    BEGIN
        UPDATE A
            SET Result = B.Result, 
                MessageType = B.MessageType, 
                Status = B.Status 
            FROM #SS3                 AS A 
            JOIN #TLGInOutDailyBatch  AS B ON ( 1 = 1 ) 
        
        SELECT * FROM #SS3 
        RETURN  
    END 
    
    ------------------------------        
    -- ����������
    ------------------------------   
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT WorkingTag
                                                        ,IDX_NO
                                                        ,DataSeq     
                                                        ,Selected
                                                        ,MessageType
                                                        ,Status
                                                        ,Result
                                                        ,Row_IDX
                                                        ,InvoiceSeq         
                                                    FROM #TSLInvoice     
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  
        

    TRUNCATE TABLE #TSLCreateOutSum
    INSERT INTO #TSLCreateOutSum    
    EXEC _SSLCreateInvoiceOutSum
            @xmlDocument  = @XmlData,        
            @xmlFlags     = 2,        
            @ServiceSeq   = 4784,        
            @WorkingTag   = '',        
            @CompanySeq   = @CompanySeq,        
            @LanguageSeq  = 1,        
            @UserSeq      = @UserSeq,
            @PgmSeq       = @PgmSeq      
        
    IF EXISTS (SELECT 1 FROM #TSLCreateOutSum WHERE Status <> 0) 
    BEGIN
        UPDATE A
            SET Result = B.Result, 
                MessageType = B.MessageType, 
                Status = B.Status 
            FROM #SS3                 AS A 
            JOIN #TLGInOutDailyBatch  AS B ON ( 1 = 1 ) 
        
        SELECT * FROM #SS3 
        RETURN  
    END 

    --=======================================================================
    -- �ŷ����� ���ó��, END 
    --=======================================================================
    /***********************************************************************************************************************
    -- �ŷ�����, End  
    ************************************************************************************************************************/

    /***********************************************************************************************************************
    -- ���ݰ�꼭, Start 
    ************************************************************************************************************************/

    ------------------------------        
    -- �����������
    ------------------------------   
    SELECT DISTINCT 
           WorkingTag, 
           1 AS IDX_NO, 
           1 AS DataSeq, 
           '0' AS Selected,
           0 AS Status,  
           0 AS SalesSeq 
      INTO #TSLDeleteSalesSum_Xml
      FROM #Main 

    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLDeleteSalesSum_Xml    
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  
        
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TSLDeleteSalesSum (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, 2, @CompanySeq, 4784, 'DataBlock1', '#TSLDeleteSalesSum' 
    TRUNCATE TABLE #TSLDeleteSalesSum
    
    INSERT INTO #TSLDeleteSalesSum    
    EXEC _SSLDeleteSalesSum
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 4784,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   
    

    IF EXISTS (SELECT 1 FROM #TSLDeleteSalesSum WHERE Status <> 0) 
    BEGIN
        UPDATE A
            SET Result = B.Result, 
                MessageType = B.MessageType, 
                Status = B.Status 
            FROM #SS3               AS A 
            JOIN #TSLDeleteSalesSum AS B ON ( 1 = 1 ) 
        
        SELECT * FROM #SS3 
        RETURN  
    END 


    ------------------------------        
    -- û���������
    ------------------------------   
    SELECT DISTINCT 
           WorkingTag, 
           1 AS IDX_NO, 
           1 AS DataSeq, 
           '0' AS Selected,
           0 AS Status,  
           0 AS BillSeq  
      INTO #TSLDeleteBillSum_Xml
      FROM #Main 

    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLDeleteBillSum_Xml    
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  
        
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TSLDeleteBillSum (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 4784, 'DataBlock1', '#TSLDeleteBillSum' 
    TRUNCATE TABLE #TSLDeleteBillSum
    
    INSERT INTO #TSLDeleteBillSum    
    EXEC _SSLDeleteBillSum
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 4784,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   
    
    IF EXISTS (SELECT 1 FROM #TSLDeleteBillSum WHERE Status <> 0) 
    BEGIN
        UPDATE A
            SET Result = B.Result, 
                MessageType = B.MessageType, 
                Status = B.Status 
            FROM #SS3               AS A 
            JOIN #TSLDeleteBillSum  AS B ON ( 1 = 1 ) 
        
        SELECT * FROM #SS3 
        RETURN  
    END 


    ------------------------------        
    -- ����üũ
    ------------------------------ 
    SELECT DISTINCT 
           WorkingTag, 
           1 AS IDX_NO, 
           1 AS DataSeq, 
           '1' AS Selected,
           0 AS SalesSeq, 
           0 AS Status, 
           @SMExpKind AS SMExpKind, 
           erp_BizUnit AS BizUnit, 
           StdDate AS SalesDate, 
           CustSeq, 
           EmpSeq, 
           DeptSeq, 
           CurrSeq, 
           1 AS ExRate, 
           @OppAccSeq AS OppAccSeq -- �ܻ�����, �����ؾߵ� 
      INTO #TSLSales_Xml
      FROM #Main 

    
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLSales_Xml    
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  
    
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TSLSales (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2629, 'DataBlock1', '#TSLSales' 
    TRUNCATE TABLE #TSLSales
    
    INSERT INTO #TSLSales    
    EXEC _SSLSalesCheck
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 2629,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   
    
    IF EXISTS (SELECT 1 FROM #TSLSales WHERE Status <> 0) 
    BEGIN
        UPDATE A
            SET Result = B.Result, 
                MessageType = B.MessageType, 
                Status = B.Status 
            FROM #SS3       AS A 
            JOIN #TSLSales  AS B ON ( 1 = 1 ) 
        
        SELECT * FROM #SS3 
        RETURN  
    END 
    

    ALTER TABLE #Main ADD SalesSeq INT NULL 

    UPDATE A
       SET SalesSeq = (SELECT TOP 1 SalesSeq FROM #TSLSales)
      FROM #Main AS A 

      
      --select *from _TSLInvoiceItem where companyseq = 1 and invoiceseq = (select invoiceseq from #TSLInvoice ) 
      --return 
    ------------------------------        
    -- ����ǰ��üũ
    ------------------------------ 
    SELECT A.WorkingTag, 
           A.IDX_NO AS IDX_NO, 
           A.IDX_NO AS DataSeq, 
           0 AS Status, 
           '0' AS Selected,
           A.SalesSeq, 
           0 AS SalesSerl, 
           B.ItemSeq AS ItemSeq, 
           B.UnitSeq, 
           B.STDUnitSeq AS STDUnitSeq, 
           B.Qty AS Qty, 
           B.Qty AS STDQty, 
           B.ItemPrice AS ItemPrice, 
           B.CustPrice AS CustPrice, 
           B.Price AS Price, 
           B.VATRate, 
           B.CurAmt, 
           B.CurVAT, 
           B.DomAmt, 
           B.DomVAT, 
           B.WHSeq, 
           182 AS AccSeq, 
           0 AS OppAccSeq, 
           18 AS FromTableSeq, 
           B.InvoiceSeq AS FromSeq, 
           B.InvoiceSerl AS FromSerl, 
           0 AS FromSubSerl, 
           A.CustSeq, 
           A.DeptSeq, 
           A.EmpSeq, 
           '' AS LotNo, 
           A.StdDate AS BillDate 
      INTO #TSLSalesItem_Xml
      FROM #Main AS A 
      LEFT OUTER JOIN _TSLInvoiceItem AS B ON ( B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.InvoiceSeq AND B.InvoiceSerl = A.IDX_NO ) 
      

    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLSalesItem_Xml    
                                                    FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  
    
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TSLSalesItem (WorkingTag NCHAR(1) NULL)  
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2629, 'DataBlock2', '#TSLSalesItem' 
    TRUNCATE TABLE #TSLSalesItem
    
    INSERT INTO #TSLSalesItem    
    EXEC _SSLSalesItemCheck
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 2629,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   
    
    IF EXISTS (SELECT 1 FROM #TSLSalesItem WHERE Status <> 0) 
    BEGIN
        UPDATE A
            SET Result = B.Result, 
                MessageType = B.MessageType, 
                Status = B.Status 
            FROM #SS3           AS A 
            JOIN #TSLSalesItem  AS B ON ( B.IDX_NO = A.New_IDX_NO ) 
        
        SELECT * FROM #SS3 
        RETURN  
    END 

    ------------------------------        
    -- ���ݰ�꼭 üũ 
    ------------------------------ 
    SELECT DISTINCT 
           WorkingTag, 
           1 AS IDX_NO, 
           1 AS DataSeq, 
           '1' AS Selected,
           0 AS BillSeq, 
           0 AS Status, 
           '0' AS IsPrint, 
           '1' AS IsDate, 
           erp_BizUnit AS BizUnit, 
           @SMExpKind AS SMExpKind, 
           StdDate AS BillDate, 
           8027001 AS UMBillKind, 
           8026001 AS SMBillType, 
           CustSeq, 
           EmpSeq, 
           DeptSeq, 
           erp_BizUnit AS TaxUnit, 
           CurrSeq, 
           1 AS ExRate, 
           @OppAccSeq AS OppAccSeq, 
           8027002 AS SMBilling, 
           @VatAccSeq AS VatAccSeq
      INTO #TSLBill_Xml
      FROM #Main 

      SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLBill_Xml    
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  
    
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TSLBill (WorkingTag NCHAR(1) NULL)  
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2637, 'DataBlock1', '#TSLBill' 
    TRUNCATE TABLE #TSLBill
    
    INSERT INTO #TSLBill    
    EXEC _SSLBillCheck
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 2637,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   
    
    IF EXISTS (SELECT 1 FROM #TSLBill WHERE Status <> 0) 
    BEGIN
        UPDATE A
            SET Result = B.Result, 
                MessageType = B.MessageType, 
                Status = B.Status 
            FROM #SS3           AS A 
            JOIN #TSLBill       AS B ON ( 1 = 1 ) 
        
        SELECT * FROM #SS3 
        RETURN  
    END 
    

    ALTER TABLE #Main ADD BillSeq INT NULL 

    UPDATE A
       SET BillSeq = (SELECT TOP 1 BillSeq FROM #TSLBill)
      FROM #Main AS A 

    ------------------------------        
    -- ���ݰ�꼭 ǰ��üũ 
    ------------------------------ 

    DECLARE @DataCnt INT 
    SELECT @DataCnt = (SELECT COUNT(1) FROM #Main)


    SELECT A.WorkingTag, 
           A.IDX_NO, 
           A.IDX_NO AS DataSeq, 
           0 AS Status, 
           '0' AS Selected, 
           A.BillSeq, 
           0 AS BillSerl, 
           StdDate AS BillPrtDate, 
           B.ItemName + ' �� ' + CONVERT(NVARCHAR(10),@DataCnt - 1) +'��' AS ItemName, 
           C.Qty, 
           C.CurAmt, 
           C.CurVAT, 
           C.CurAmt AS DomAmt, 
           C.CurVAT AS DomVAT 
      INTO #TSLBillItem_Xml
      FROM #Main AS A 
      JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.erp_itemseq ) 
      OUTER APPLY (
                    SELECT SUM(Qty) AS Qty, 
                           SUM(CurAmt) AS CurAmt, 
                           SUM(CurVAT) AS CurVAT
                      FROM _TSLInvoiceItem AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.InvoiceSeq = A.InvoiceSeq 
                  ) AS C 
     WHERE IDX_NO = 1 


     SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLBillItem_Xml    
                                                    FOR XML RAW ('DataBlock3'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  
    
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TSLBillItem (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2637, 'DataBlock3', '#TSLBillItem' 
    TRUNCATE TABLE #TSLBillItem
    
    INSERT INTO #TSLBillItem    
    EXEC _SSLBillItemCheck
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 2637,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   
    
    IF EXISTS (SELECT 1 FROM #TSLBillItem WHERE Status <> 0) 
    BEGIN
        UPDATE A
            SET Result = B.Result, 
                MessageType = B.MessageType, 
                Status = B.Status 
            FROM #SS3           AS A 
            JOIN #TSLBillItem   AS B ON ( 1 = 1 ) 
        
        SELECT * FROM #SS3 
        RETURN  
    END 

    ------------------------------        
    -- ���⼼�ݰ�꼭 üũ 
    ------------------------------ 
    
    SELECT A.WorkingTag, 
           A.IDX_NO, 
           A.IDX_NO AS DataSeq, 
           0 AS Status, 
           '0' Selected, 
           A.SalesSeq, 
           A.IDX_NO AS SalesSerl, 
           B.CurAmt, 
           B.CurVAT, 
           B.DomAmt, 
           B.DomVAT, 
           A.BillSeq 
      INTO #TSLSalesBillRelation_Xml
      FROM #Main AS A 
      LEFT OUTER JOIN _TSLInvoiceItem AS B ON ( B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.InvoiceSeq AND B.InvoiceSerl = A.IDX_NO ) 

     SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLSalesBillRelation_Xml    
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  
    
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TSLSalesBillRelation (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 3048, 'DataBlock1', '#TSLSalesBillRelation' 
    TRUNCATE TABLE #TSLSalesBillRelation
    
    INSERT INTO #TSLSalesBillRelation    
    EXEC _SSLSalesBillRelationCheck
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 3048,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   
    
    IF EXISTS (SELECT 1 FROM #TSLSalesBillRelation WHERE Status <> 0) 
    BEGIN
        UPDATE A
            SET Result = B.Result, 
                MessageType = B.MessageType, 
                Status = B.Status 
            FROM #SS3                   AS A 
            JOIN #TSLSalesBillRelation  AS B ON ( B.IDX_NO = A.New_IDX_NO ) 
        
        SELECT * FROM #SS3 
        RETURN  
    END 
    
    ------------------------------        
    -- ���� ���� 
    ------------------------------      
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLSales    
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  
    TRUNCATE TABLE #TSLSales
    INSERT INTO #TSLSales    
    EXEC _SSLSalesSave
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 2629,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   

    
    ------------------------------        
    -- ����ǰ�� ���� 
    ------------------------------    
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLSalesItem    
                                                    FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  
    TRUNCATE TABLE #TSLSalesItem
    INSERT INTO #TSLSalesItem    
    EXEC _SSLSalesItemSave
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 2629,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   

    ------------------------------        
    -- �ŷ�����, ���� ��������
    ------------------------------    
    SELECT A.WorkingTag, 
           A.IDX_NO, 
           A.IDX_NO AS DataSeq, 
           0 AS Status, 
           '0' Selected, 
           18 AS FromTableSeq, 
           A.InvoiceSeq AS FromSeq, 
           A.IDX_NO AS FromSerl, 
           20 AS ToTableSeq, 
           B.Qty AS FromQty, 
           B.Qty AS FromSTDQty, 
           B.CurAmt AS FromAmt, 
           B.CurVAT AS FromVAT, 
           0 AS PrevFromTableSeq, 
           A.SalesSeq AS ToSeq, 
           A.IDX_NO AS ToSerl, 
           B.Qty AS ToQty, 
           B.Qty AS ToSTDQty, 
           B.CurAmt AS ToAmt, 
           B.CurVAT AS ToVAT, 
           B.DomAmt, 
           B.DomVAT
      INTO #TCOMSourceDaily_Xml
      FROM #Main AS A 
      LEFT OUTER JOIN _TSLInvoiceItem AS B ON ( B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.InvoiceSeq AND B.InvoiceSerl = A.IDX_NO ) 
    
    --select * from #TCOMSourceDaily_Xml 
    --return 

    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TCOMSourceDaily_Xml    
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  
    -- ���� ����Ÿ ��� ����          
    CREATE TABLE #TCOMSourceDaily  (WorkingTag NCHAR(1) NULL)              
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 3181, 'DataBlock1', '#TCOMSourceDaily' 
    TRUNCATE TABLE #TCOMSourceDaily

    ----------------------- Column �߰�(OldToQty , OldToAmt) Update & Delete �� �����          
    Alter Table #TCOMSourceDaily Add OldToQty DECIMAL(19, 5)           
    Alter Table #TCOMSourceDaily Add OldToSTDQty DECIMAL(19, 5)           
    Alter Table #TCOMSourceDaily Add OldToAmt DECIMAL(19, 5)           
    Alter Table #TCOMSourceDaily Add OldToVAT DECIMAL(19, 5)     

    INSERT INTO #TCOMSourceDaily    
    EXEC _SCOMSourceDailySave
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 3181,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   
    

    ------------------------------        
    -- ��Ʈǰ���������
    ------------------------------    
    SELECT A.WorkingTag, 
           A.IDX_NO, 
           A.IDX_NO AS DataSeq, 
           0 AS Status, 
           '0' Selected, 
           A.SalesSeq
      INTO #TSLSalesApp_Xml
      FROM #Main AS A 
    
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLSalesApp_Xml    
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  

     CREATE TABLE #TSLSalesApp (WorkingTag NCHAR(1) NULL)
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 3151, 'DataBlock1', '#TSLSalesApp'
     TRUNCATE TABLE #TSLSalesApp

    INSERT INTO #TSLSalesApp    
    EXEC _SSLSetItemSalesAppSave
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 3151,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   
    
    ------------------------------        
    -- �����������
    ------------------------------    
    SELECT DISTINCT 
           A.WorkingTag, 
           1 AS IDX_NO, 
           1 AS DataSeq, 
           0 AS Status, 
           '0' Selected, 
           A.SalesSeq
      INTO #TSLCreateSalesSum_Xml
      FROM #Main AS A 
    
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLCreateSalesSum_Xml    
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  


    ---- ���� ����Ÿ ��� ����  
    CREATE TABLE #TSLCreateSalesSum (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 4784, 'DataBlock1', '#TSLCreateSalesSum' 
    TRUNCATE TABLE #TSLCreateSalesSum 
    
    INSERT INTO #TSLCreateSalesSum    
    EXEC _SSLCreateSalesSum
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 4784,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   

    ------------------------------        
    -- ���ݰ�꼭 ���������� 
    ------------------------------  
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLBill    
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  
    TRUNCATE TABLE #TSLBill
    INSERT INTO #TSLBill    
    EXEC _SSLBillSave
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 2637,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   
    
    
    ------------------------------        
    -- ���ݰ�꼭 ������ ���� 
    ------------------------------ 
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLBillItem    
                                                    FOR XML RAW ('DataBlock3'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  
    TRUNCATE TABLE #TSLBillItem
    INSERT INTO #TSLBillItem    
    EXEC _SSLBillItemSave
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 2637,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   
    
    ------------------------------        
    -- ���⼼�ݰ�꼭 ���� 
    ------------------------------ 
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLSalesBillRelation    
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  


    TRUNCATE TABLE #TSLSalesBillRelation
    INSERT INTO #TSLSalesBillRelation    
    EXEC _SSLSalesBillRelationSave
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 3048,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   

    ------------------------------ 
    -- ���ҵ��������� 
    ------------------------------ 
    SELECT DISTINCT 
           WorkingTag, 
           1 AS IDX_NO, 
           1 AS DataSeq, 
           '1' AS Selected, 
           0 AS Status, 
           SalesSeq AS InOutSeq, 
           20 AS InOutType 
      INTO #TLGInOutDailyBatch_Xml
      FROM #Main 

    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TLGInOutDailyBatch_Xml    
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  

    
    TRUNCATE TABLE #TLGInOutDailyBatch 
    INSERT INTO #TLGInOutDailyBatch    
    EXEC _SLGInOutDailyBatch
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 2619,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   
        
    ------------------------------ 
    -- û��������� 
    ------------------------------ 
    SELECT DISTINCT 
           WorkingTag, 
           1 AS IDX_NO, 
           1 AS DataSeq, 
           '1' AS Selected, 
           0 AS Status, 
           SalesSeq AS InOutSeq, 
           20 AS InOutType 
      INTO #TSLCreateBillSum_Xml
      FROM #Main 
    
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLCreateBillSum_Xml    
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  

    -- ���� ����Ÿ ��� ����    
    CREATE TABLE #TSLCreateBillSum (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 4784, 'DataBlock1', '#TSLCreateBillSum'   
    TRUNCATE TABLE #TSLCreateBillSum 

    INSERT INTO #TSLCreateBillSum    
    EXEC _SSLCreateBillSum
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 4784,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   
    
    UPDATE A 
       SET SalesSeq = B.SalesSeq, 
           BillSeq = B.BillSeq 
      FROM hye_TSLOilDailySalesDataRelation AS A 
      LEFT OUTER JOIN #Main                 AS B ON ( B.BizUnit = A.div_code AND B.StdDate = A.process_date )
     WHERE A.CompanySeq = @CompanySeq 
       AND A.date_type = 'DD'

    /***********************************************************************************************************************
    -- ���ݰ�꼭, End  
    ************************************************************************************************************************/

    /***********************************************************************************************************************
    -- �Ա�, Start  
    ************************************************************************************************************************/
        
    -- �������� Mapping 
    SELECT A.ValueSeq AS erp_ACCSeq, C.AccName, B.ValueText AS b2b_ACCSeq 
      INTO #AccSeq 
      FROM _TDAUMinorValue              AS A -- ERP�������� 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000002 ) -- B2B���������ڵ� 
      LEFT OUTER JOIN _TDAAccount       AS C ON ( C.CompanySeq = @CompanySeq AND C.AccSeq = A.ValueSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1013939 
       AND A.Serl = 1000001
    
    -- �Ա�ȸ�� ���赥���� 
    SELECT IDENTITY(INT,1,1) AS IDX_NO,
           B.erp_ACCSeq AS AccSeq, 
           B.AccName AS AccName,  
           amount_i AS Amt, 
           C.BizUnit, 
           C.StdDate AS ReceiptDate, 
           C.CustSeq, 
           C.CurrSeq, 
           C.ExRate, 
           C.DeptSeq, 
           C.EmpSeq, 
           C.WorkingTag, 
           0 AS ReceiptSeq
      INTO #Receipt
      FROM POS910T AS A 
      LEFT OUTER JOIN #AccSeq AS B ON ( B.b2b_ACCSeq = A.accnt ) 
      LEFT OUTER JOIN (
                        SELECT TOP 1 
                               WorkingTag, 
                               erp_BizUnit AS BizUnit, 
                               StdDate, 
                               CustSeq, 
                               CurrSeq, 
                               1 AS ExRate, 
                               DeptSeq, 
                               EmpSeq
                          FROM #Main 
                      ) AS C ON ( 1 = 1 ) 
     WHERE a.date_type    = 'DD'
       AND EXISTS (SELECT 1 FROM #Main WHERE StdDate = a.process_date AND BizUnit = a.div_code)
       AND io_type = 'I'
     ORDER BY a.process_category, a.process_code
    
    ------------------------------ 
    -- �Ա� üũ 
    ------------------------------ 
    SELECT DISTINCT 
           A.WorkingTag, 
           A.IDX_NO, 
           A.IDX_NO AS DataSeq, 
           0 AS Status, 
           '0' Selected, 
           0 AS ReceiptSeq, 
           A.BizUnit, 
           A.ReceiptDate, 
           @SMExpKind AS SMExpKind, 
           A.CustSeq, 
           A.CurrSeq, 
           A.ExRate, 
           A.DeptSeq, 
           A.EmpSeq, 
           0 AS BizUnitOld, 
           0 AS DeptSeqOld, 
           '0' AS IsReplace, 
           '0' AS IsPreReceipt
      INTO #TSLReceipt_Xml
      FROM #Receipt AS A 
    
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLReceipt_Xml    
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TSLReceipt (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2277, 'DataBlock1', '#TSLReceipt' 
    TRUNCATE TABLE #TSLReceipt 

    INSERT INTO #TSLReceipt 
    EXEC _SSLReceiptCheck
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 2277,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   
    
    IF EXISTS (SELECT 1 FROM #TSLReceipt WHERE Status <> 0) 
    BEGIN
        UPDATE A
            SET Result = B.Result, 
                MessageType = B.MessageType, 
                Status = B.Status 
            FROM #SS3                   AS A 
            LEFT OUTER JOIN (
                                SELECT TOP 1 Result, MessageType, Status 
                                  FROM #TSLReceipt 
                                 WHERE Status <> 0 
                            ) AS B ON ( 1 = 1 ) 
        
        SELECT * FROM #SS3 
        RETURN  
    END 

    UPDATE A
       SET ReceiptSeq = B.ReceiptSeq
      FROM #Receipt AS A 
      JOIN #TSLReceipt AS B ON ( B.IDX_NO = A.IDX_NO ) 

      --select *from _TDAUMajor where majorseq = 8017 
    ------------------------------ 
    -- �Աݵ����� üũ 
    ------------------------------ 
    -- �Աݱ��� ���ϱ� 
    SELECT A.ValueSeq AS AccSeq, A.MinorSeq AS UMReceiptKind
      INTO #UMReceiptKind
      FROM _TDAUMinorValue              AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1005 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1006 ) 
     WHERE A.CompanySeq = 1 
       AND A.MajorSeq = 8017
       AND A.Serl = 1001
       AND ISNULL(B.ValueText,'0') = '0' 
       AND ISNULL(C.ValueText,'0') = '0' 
    
    SELECT WorkingTag, 
           IDX_NO, 
           IDX_NO AS DataSeq, 
           '1' AS Selected, 
           0 AS Status, 
           ReceiptSeq, 
           CurrSeq 
      INTO #TSLReceiptDesc_DataBlock1
      FROM #Receipt 

    SELECT WorkingTag, 
           IDX_NO, 
           IDX_NO AS DataSeq, 
           '1' AS Selected, 
           0 AS Status, 
           ReceiptSeq, 
           0 AS ReceiptSerl, 
           Amt AS CurAmt, 
           Amt AS DomAmt, 
           B.SMDrOrCr, 
           C.UMReceiptKind AS UMReceiptKind, 
           A.AccSeq 
      INTO #TSLReceiptDesc_DataBlock2
      FROM #Receipt AS A 
      LEFT OUTER JOIN _TDAAccount       AS B ON ( B.CompanySeq = @CompanySeq AND B.AccSeq = A.AccSeq ) 
      LEFT OUTER JOIN #UMReceiptKind    AS C ON ( C.AccSeq = A.AccSeq ) 
    
    
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLReceiptDesc_DataBlock1    
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  

    SELECT @XmlData = REPLACE(@XmlData,'</DataBlock1></ROOT>', '</DataBlock1>')

    DECLARE @XmlData2 NVARCHAR(MAX) 

    SELECT @XmlData2 = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLReceiptDesc_DataBlock2    
                                                    FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS        
                                                                            
                                            ))  
    SELECT @XmlData2 = REPLACE(@XmlData2, '<ROOT><DataBlock2>', '<DataBlock2>')


    SELECT @XmlData = @XmlData + ' ' + @XmlData2 


    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TSLReceiptDesc(WorkingTag NCHAR(1) NULL)  
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2277, 'DataBlock2', '#TSLReceiptDesc'  
    TRUNCATE TABLE #TSLReceiptDesc

    INSERT INTO #TSLReceiptDesc 
    EXEC _SSLReceiptDescCheck
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 2277,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   
    
    IF EXISTS (SELECT 1 FROM #TSLReceiptDesc WHERE Status <> 0) 
    BEGIN
        UPDATE A
            SET Result = B.Result, 
                MessageType = B.MessageType, 
                Status = B.Status 
            FROM #SS3                   AS A 
            LEFT OUTER JOIN (
                                SELECT TOP 1 Result, MessageType, Status 
                                  FROM #TSLReceiptDesc 
                                 WHERE Status <> 0 
                            ) AS B ON ( 1 = 1 ) 
        
        SELECT * FROM #SS3 
        RETURN  
    END 
    
    ------------------------------ 
    -- �Ա��������
    ------------------------------ 
    SELECT WorkingTag, 
           IDX_NO, 
           IDX_NO AS DataSeq, 
           '1' AS Selected, 
           0 AS Status, 
           ReceiptSeq
      INTO #TSLDeleteReceiptSum_Xml
      FROM #Receipt 
      

    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLDeleteReceiptSum_Xml    
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  

    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TSLDeleteReceiptSum (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 4784, 'DataBlock1', '#TSLDeleteReceiptSum' 
    TRUNCATE TABLE #TSLDeleteReceiptSum

    INSERT INTO #TSLDeleteReceiptSum 
    EXEC _SSLDeleteReceiptSum
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 4784,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   

    IF EXISTS (SELECT 1 FROM #TSLDeleteReceiptSum WHERE Status <> 0) 
    BEGIN
        UPDATE A
            SET Result = B.Result, 
                MessageType = B.MessageType, 
                Status = B.Status 
            FROM #SS3                   AS A 
            LEFT OUTER JOIN (
                                SELECT TOP 1 Result, MessageType, Status 
                                  FROM #TSLDeleteReceiptSum 
                                 WHERE Status <> 0 
                            ) AS B ON ( 1 = 1 ) 
        
        SELECT * FROM #SS3 
        RETURN  
    END 
    
    ------------------------------ 
    -- �Ա� ���� 
    ------------------------------
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLReceipt    
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  

    TRUNCATE TABLE #TSLReceipt 
    INSERT INTO #TSLReceipt 
    EXEC _SSLReceiptSave
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 2277,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   
        
    --select * from #TSLReceipt 

    --select * from _TSLReceipt WHERE Companyseq = 1 and ReceiptSeq in ( SELECT ReceiptSeq FROM #TSLReceipt ) 


    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLReceiptDesc    
                                                    FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  

    TRUNCATE TABLE #TSLReceiptDesc 
    INSERT INTO #TSLReceiptDesc 
    EXEC _SSLReceiptDescSave
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 2277,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   


    --select * from _TSLReceipt WHERE Companyseq = 1 and ReceiptSeq in ( SELECT ReceiptSeq FROM #TSLReceipt ) 
    --select * from _TSLReceiptDesc WHERE Companyseq = 1 and ReceiptSeq in ( SELECT ReceiptSeq FROM #TSLReceipt ) 

    ------------------------------ 
    -- �Ա�������� 
    ------------------------------ 
 
    SELECT WorkingTag, 
           IDX_NO, 
           IDX_NO AS DataSeq, 
           '1' AS Selected, 
           0 AS Status, 
           ReceiptSeq
      INTO #TSLCreateReceiptSum_Xml
      FROM #Receipt 
      
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(        
                                                SELECT *        
                                                    FROM #TSLCreateReceiptSum_Xml    
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS        
                                                          
                                            ))  

    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TSLCreateReceiptSum (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 4784, 'DataBlock1', '#TSLCreateReceiptSum' 
    TRUNCATE TABLE #TSLCreateReceiptSum

    INSERT INTO #TSLCreateReceiptSum 
    EXEC _SSLCreateReceiptSum
        @xmlDocument  = @XmlData,        
        @xmlFlags     = 2,        
        @ServiceSeq   = 4784,        
        @WorkingTag   = '',        
        @CompanySeq   = @CompanySeq,        
        @LanguageSeq  = 1,        
        @UserSeq      = @UserSeq,
        @PgmSeq       = @PgmSeq   

    IF EXISTS (SELECT 1 FROM #TSLCreateReceiptSum WHERE Status <> 0) 
    BEGIN
        UPDATE A
            SET Result = B.Result, 
                MessageType = B.MessageType, 
                Status = B.Status 
            FROM #SS3                   AS A 
            LEFT OUTER JOIN (
                                SELECT TOP 1 Result, MessageType, Status 
                                  FROM #TSLCreateReceiptSum 
                                 WHERE Status <> 0 
                            ) AS B ON ( 1 = 1 ) 
        
        SELECT * FROM #SS3 
        RETURN  
    END 
    
    ALTER TABLE #Main ADD ReceiptSeq INT NULL 

    UPDATE A
       SET ReceiptSeq = B.ReceiptSeq
      FROM #Main AS A 
      LEFT OUTER JOIN (
                        SELECT MAX(ReceiptSeq) AS ReceiptSeq 
                          FROM #TSLReceipt
                      ) AS B ON ( 1 = 1 ) 


    -- Relation���̺� ���� 
    UPDATE A
       SET MaxReceiptSeq = B.ReceiptSeq
      FROM hye_TSLOilDailySalesDataRelation AS A 
      OUTER APPLY (
                    SELECT Z.ReceiptSeq
                      FROM #Main AS Z 
                     WHERE Z.BizUnit = A.div_code
                       AND Z.StdDate = A.process_date
                  ) AS B 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.date_type = 'DD' 
    
    DECLARE @MaxReceiptSeq INT 

    SELECT @MaxReceiptSeq = A.MaxReceiptSeq
      FROM hye_TSLOilDailySalesDataRelation AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #Main WHERE BizUnit = A.div_code AND StdDate = A.process_date) 

    -- �Աݿ� ���� Relation ���̺� ���� 
    INSERT INTO hye_TSLOilDailySalesDataRelationReceipt 
    ( 
        CompanySeq, MaxReceiptSeq, ReceiptSeq, LastUserSeq, LastDateTime, 
        PgmSeq 
    ) 
    SELECT @CompanySeq, @MaxReceiptSeq, A.ReceiptSeq, @UserSeq, GETDATE(), 
           @PgmSeq 
      FROM #TSLReceipt AS A 
    
    /***********************************************************************************************************************
    -- �Ա�, End  
    ************************************************************************************************************************/



    SELECT * FROM #SS3 
    
    RETURN  
GO



begin tran 

exec hye_SSLOilDailySalesClose @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <BizUnit>901</BizUnit>
    <StdDate>20160601</StdDate>
    <SlipKind>1013901002</SlipKind>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730106,@WorkingTag=N'C',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=77730031
exec hye_SSLOilDailySalesData @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <sale_total_qty>51584520</sale_total_qty>
    <sale_price>77300</sale_price>
    <total_amt>39874818</total_amt>
    <CASH_sale_amt>988176</CASH_sale_amt>
    <CARD_sale_amt>16351963</CARD_sale_amt>
    <AR_sale_amt>22504679</AR_sale_amt>
    <GIFT_sale_amt>0</GIFT_sale_amt>
    <OKCASH_sale_amt>30000</OKCASH_sale_amt>
    <COUPON_sale_amt>0</COUPON_sale_amt>
    <M_COUPON_sale_amt>0</M_COUPON_sale_amt>
    <POINT_sale_amt>0</POINT_sale_amt>
    <BLUE_POINT_sale_amt>0</BLUE_POINT_sale_amt>
    <descr2 />
    <sort>1</sort>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <BizUnit>901</BizUnit>
    <StdDate>20160601</StdDate>
    <SlipKind>1013901002</SlipKind>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <sale_total_qty>51584520</sale_total_qty>
    <sale_price>0</sale_price>
    <total_amt>39874818</total_amt>
    <CASH_sale_amt>988176</CASH_sale_amt>
    <CARD_sale_amt>16351963</CARD_sale_amt>
    <AR_sale_amt>22504679</AR_sale_amt>
    <GIFT_sale_amt>0</GIFT_sale_amt>
    <OKCASH_sale_amt>30000</OKCASH_sale_amt>
    <COUPON_sale_amt>0</COUPON_sale_amt>
    <M_COUPON_sale_amt>0</M_COUPON_sale_amt>
    <POINT_sale_amt>0</POINT_sale_amt>
    <BLUE_POINT_sale_amt>0</BLUE_POINT_sale_amt>
    <descr2 />
    <sort>2</sort>
    <BizUnit>901</BizUnit>
    <StdDate>20160601</StdDate>
    <SlipKind>1013901002</SlipKind>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code />
    <sale_total_qty>51584520</sale_total_qty>
    <sale_price>0</sale_price>
    <total_amt>39874818</total_amt>
    <CASH_sale_amt>988176</CASH_sale_amt>
    <CARD_sale_amt>16351963</CARD_sale_amt>
    <AR_sale_amt>22504679</AR_sale_amt>
    <GIFT_sale_amt>0</GIFT_sale_amt>
    <OKCASH_sale_amt>30000</OKCASH_sale_amt>
    <COUPON_sale_amt>0</COUPON_sale_amt>
    <M_COUPON_sale_amt>0</M_COUPON_sale_amt>
    <POINT_sale_amt>0</POINT_sale_amt>
    <BLUE_POINT_sale_amt>0</BLUE_POINT_sale_amt>
    <descr2 />
    <sort>3</sort>
    <BizUnit>901</BizUnit>
    <StdDate>20160601</StdDate>
    <SlipKind>1013901002</SlipKind>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730106,@WorkingTag=N'C',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=77730031
rollback 