IF OBJECT_ID('hencom_SPDMESErpApplyBatchCancel') IS NOT NULL 
    DROP PROC hencom_SPDMESErpApplyBatchCancel
GO 

-- v2017.02.13 

-- ���Ͽ��� ERP�ݿ���� by����õ 
CREATE PROC hencom_SPDMESErpApplyBatchCancel                                     
      @xmlDocument    NVARCHAR(MAX),                      
      @xmlFlags       INT     = 0,                                                
      @ServiceSeq     INT     = 0,                                                
      @WorkingTag     NVARCHAR(10)= '',                                                
      @CompanySeq     INT     = 1,                                                
      @LanguageSeq    INT     = 1,                                                
      @UserSeq        INT     = 0,                                                
      @PgmSeq         INT     = 0                                                                                              
AS                                                 
    
    DECLARE @MessageType INT, 
            @Status      INT, 
            @Results     NVARCHAR(250) 
    
    CREATE TABLE #hencom_TPDMESErpApplyBatch (WorkingTag NCHAR(1) NULL) 
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TPDMESErpApplyBatch' 
    IF @@ERROR <> 0 RETURN 
    
    -- ����                      
    CREATE TABLE #SComSourceDailyBatch            
    (          
        ToTableName   NVARCHAR(100),          
        ToSeq         INT,          
        ToSerl        INT,          
        ToSubSerl     INT,          
        FromTableName NVARCHAR(100),          
        FromSeq       INT,          
        FromSerl      INT,          
        FromSubSerl   INT,          
        ToQty         DECIMAL(19,5),          
        ToStdQty      DECIMAL(19,5),          
        ToAmt         DECIMAL(19,5),          
        ToVAT         DECIMAL(19,5),          
        FromQty       DECIMAL(19,5),          
        FromSTDQty    DECIMAL(19,5),          
        FromAmt       DECIMAL(19,5),          
        FromVAT       DECIMAL(19,5)          
    ) 
    
    -- ���ݿ�          
    CREATE TABLE #TLGInOutMonth                
    (                  
        InOut           INT,                
        InOutYM         NCHAR(6),                
        WHSeq           INT,                
        FunctionWHSeq   INT,                
        ItemSeq         INT,                
        UnitSeq         INT,                
        Qty             DECIMAL(19, 5),                
        StdQty          DECIMAL(19, 5),                
        ADD_DEL         INT                
    )                           
    
    Create Table #TLGInOutMonthLot              
    (                
        InOut           INT,              
        InOutYM         NCHAR(6),              
        WHSeq           INT,              
        FunctionWHSeq   INT,              
        LotNo            NVARCHAR(30),              
        ItemSeq         INT,              
        UnitSeq         INT,              
        Qty             DECIMAL(19, 5),              
        StdQty          DECIMAL(19, 5),                    
        ADD_DEL         INT                    
    )              
    
    CREATE TABLE #TLGInOutDailyBatch          
    (          
        WorkingTag NCHAR(1),  
        InOutType       INT,          
        InOutSeq        INT,        
        MessageType     INT,        
        Result          NVARCHAR(250),        
        Status          INT     
    )
    
    CREATE TABLE #SSLInvoiceSeq          
    (   SumSeq    INT)          
    
    CREATE TABLE #SSLSalesSeq        
    (   SumSeq    INT)          
    

    SELECT A.SumMesKey, 
           A.WorkOrderSeq, 
           A.WorkReportSeq, 
           A.InvoiceSeq, 
           A.SalesSeq, 
           A.ProdQty, 
           A.CurAmt, 
           A.CurVAT, 
           CONVERT(INT,0) AS GoodInSeq         
      INTO #Main
      FROM hencom_TIFProdWorkReportCloseSum AS A WITH(NOLOCK)                                     
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #hencom_TPDMESErpApplyBatch WHERE SumMesKey = A.SumMesKey)
       AND (   
               ISNULL(A.WorkOrderSeq,0) <> 0 
            OR ISNULL(A.WorkReportSeq,0) <> 0 
            OR ISNULL(A.InvoiceSeq,0) <> 0 
            OR ISNULL(A.SalesSeq,0) <> 0 
           )
    
    ------------------------------------------------------------------------------------------------------------------------
    -- ���� ����
    ------------------------------------------------------------------------------------------------------------------------
    -- TR
    DELETE A 
      FROM _TSLSales AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #Main WHERE SalesSeq = A.SalesSeq) 

    DELETE A 
      FROM _TSLSalesItem AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #Main WHERE SalesSeq = A.SalesSeq) 
    
    -- ����
    TRUNCATE TABLE #SComSourceDailyBatch    
    INSERT INTO #SComSourceDailyBatch    
    SELECT  '_TSLSalesItem', A.SalesSeq, 1, 0,  
            '_TSLInvoiceItem', A.InvoiceSeq, 1, 0,    
        A.ProdQty, A.ProdQty, A.CurAmt, A.CurVAT,    
        A.ProdQty, A.ProdQty, A.CurAmt, A.CurVAT    
    FROM  #Main AS A    
    
    EXEC _SComSourceDailyBatch 'D', @CompanySeq, @UserSeq    
    
    -- ���
    TRUNCATE TABLE #TLGInOutDailyBatch 
       
    INSERT INTO  #TLGInOutDailyBatch    
    SELECT  'D',20, SalesSeq, 0, '', 0    
    FROM #Main    
    
    EXEC _SLGInOutDailyDELETE @CompanySeq    

    EXEC _SLGWHStockUPDATE @CompanySeq                                                             
    EXEC _SLGLOTStockUPDATE @CompanySeq                                                             

    EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyBatch'                                                         
    EXEC _SLGInOutLotMinusCheck @CompanySeq, '#TLGInOutDailyBatch'      
    
    -- ����ó��    
    IF EXISTS(SELECT 1 FROM #TLGInOutDailyBatch WHERE Status <> 0)    
    BEGIN    
        UPDATE #hencom_TPDMESErpApplyBatch    
           SET Result        = C.Result   ,                                                
               MessageType   = C.MessageType ,                                               
               Status        = C.Status     
          FROM  #hencom_TPDMESErpApplyBatch AS A    
          JOIN #Main                        AS B ON A.SumMesKey = B.SumMesKey    
          JOIN #TLGInOutDailyBatch          AS C ON B.SalesSeq = C.InOutSeq    
         WHERE  C.Status <> 0    
  
        SELECT * FROM #hencom_TPDMESErpApplyBatch 
        RETURN                                  
    END    
    
    TRUNCATE TABLE #TLGInOutMonth    
    TRUNCATE TABLE #TLGInOutMonthLot    
    
    -- ��������
    INSERT  #SSLSalesSeq    
    SELECT SalesSeq 
      FROM #Main    
    
    EXEC _SSLSalesSum 'D', @CompanySeq      
    ------------------------------------------------------------------------------------------------------------------------
    -- ���� ����, END 
    ------------------------------------------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------------------------------------------
    -- �ŷ����� ����
    ------------------------------------------------------------------------------------------------------------------------
    -- TR
    DELETE A 
      FROM _TSLInvoice AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #Main WHERE InvoiceSeq = A.InvoiceSeq)

    DELETE A 
      FROM _TSLInvoiceItem AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #Main WHERE InvoiceSeq = A.InvoiceSeq)
    
    -- ���
    TRUNCATE TABLE #TLGInOutDailyBatch    
    
    INSERT INTO #TLGInOutDailyBatch    
    SELECT  'D',10, InvoiceSeq, 0, '', 0    
    FROM  #Main    
    
    EXEC _SLGInOutDailyDELETE @CompanySeq    

    EXEC _SLGWHStockUPDATE @CompanySeq                                                            
    EXEC _SLGLOTStockUPDATE @CompanySeq                                                            
    
    EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyBatch'                                                        
    EXEC _SLGInOutLotMinusCheck @CompanySeq, '#TLGInOutDailyBatch'      
     
    IF EXISTS(SELECT 1 FROM #TLGInOutDailyBatch WHERE Status <> 0)    
    BEGIN    
        UPDATE #hencom_TPDMESErpApplyBatch    
        SET Result        = C.Result   ,                                               
            MessageType   = C.MessageType ,                                               
            Status        = C.Status     
        FROM  #hencom_TPDMESErpApplyBatch   AS A    
        JOIN #Main                          AS B ON A.SumMesKey = B.SumMesKey    
        JOIN #TLGInOutDailyBatch            AS C ON B.InvoiceSeq = C.InOutSeq    
        WHERE  C.Status <> 0    

        SELECT * FROM #hencom_TPDMESErpApplyBatch                                        
        ROLLBACK TRAN                                     
        RETURN                                  
    END    
    
    TRUNCATE TABLE #TLGInOutMonth    
    TRUNCATE TABLE #TLGInOutMonthLot    

    -- �����ݿ�    
    INSERT INTO #SSLInvoiceSeq    
    SELECT InvoiceSeq 
      FROM #Main    

    EXEC _SSLInvoiceSum 'D', @CompanySeq      
    ------------------------------------------------------------------------------------------------------------------------
    -- �ŷ����� ����, END 
    ------------------------------------------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------------------------------------------
    -- �����԰� ����
    ------------------------------------------------------------------------------------------------------------------------
    -- TR 
    UPDATE A
       SET GoodInSeq = B.GoodInSeq 
      FROM #Main            AS A 
      JOIN _TPDSFCGoodIn    AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
    
    DELETE A 
      FROM _TPDSFCGoodIn AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #Main WHERE GoodInSeq = A.GoodInSeq)
      
    -- ����
    TRUNCATE TABLE #SComSourceDailyBatch    
     
    INSERT INTO #SComSourceDailyBatch    
    SELECT '_TPDSFCGoodIn', A.GoodInSeq, 0, 0,
           '_TPDSFCWorkReport', A.WorkReportSeq, 0, 0,
           A.ProdQty, A.ProdQty, 0, 0,    
           A.ProdQty, A.ProdQty, 0, 0    
      FROM #Main AS A    
    
    EXEC _SComSourceDailyBatch 'D', @CompanySeq, @UserSeq    
    
    -- ��� 
    TRUNCATE TABLE #TLGInOutDailyBatch    
    INSERT  #TLGInOutDailyBatch    
    SELECT  'D',140, GoodInSeq, 0, '', 0    
    FROM  #Main    
  
    EXEC _SLGInOutDailyDELETE @CompanySeq    
    
    EXEC _SLGWHStockUPDATE @CompanySeq                                                            
    EXEC _SLGLOTStockUPDATE @CompanySeq                                                             
    
    EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyBatch'                                                        
    EXEC _SLGInOutLotMinusCheck @CompanySeq, '#TLGInOutDailyBatch'      
    
    -- ���� ó��
    IF EXISTS(SELECT 1 FROM #TLGInOutDailyBatch WHERE Status <> 0)    
    BEGIN    
        UPDATE #hencom_TPDMESErpApplyBatch    
           SET Result        = C.Result   ,                                               
               MessageType   = C.MessageType ,                                               
               Status        = C.Status     
          FROM  #hencom_TPDMESErpApplyBatch AS A    
          JOIN #Main                        AS B ON A.SumMesKey = B.SumMesKey    
          JOIN #TLGInOutDailyBatch          AS C ON B.GoodInSeq = C.InOutSeq    
         WHERE C.Status <> 0    
  
        SELECT * FROM #hencom_TPDMESErpApplyBatch                                        
        RETURN                                  
    END    
    
    TRUNCATE TABLE #TLGInOutMonth 
    TRUNCATE TABLE #TLGInOutMonthLot 
    ------------------------------------------------------------------------------------------------------------------------
    -- �����԰� ����, END 
    ------------------------------------------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------------------------------------------
    -- ������� ����
    ------------------------------------------------------------------------------------------------------------------------
    -- TR
    DELETE A 
      FROM _TPDSFCWorkReport AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #Main WHERE WorkReportSeq = A.WorkReportSeq) 
    
    DELETE A 
      FROM _TPDSFCMatInPut AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #Main WHERE WorkReportSeq = A.WorkReportSeq) 
    
    -- ���� 
    TRUNCATE TABLE #SComSourceDailyBatch 
    INSERT INTO #SComSourceDailyBatch    
    SELECT  '_TPDSFCWorkReport', A.WorkReportSeq, 0, 0,        
            '_TPDSFCWorkOrder ', A.WorkOrderSeq, A.WorkOrderSeq, 0, 
            A.ProdQty, A.ProdQty, 0, 0,    
            A.ProdQty, A.ProdQty, 0, 0    
    FROM  #Main A    
    
    EXEC _SComSourceDailyBatch 'D', @CompanySeq, @UserSeq    
    
    -- ���
    INSERT INTO #TLGInOutDailyBatch    
    SELECT 'D',130, WorkReportSeq, 0, '', 0 
    FROM  #Main    
    

    EXEC  _SLGInOutDailyDELETE @CompanySeq    
 
    EXEC _SLGWHStockUPDATE @CompanySeq                                                            
    EXEC _SLGLOTStockUPDATE @CompanySeq                                                            
    
    EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyBatch'                                                        
    EXEC _SLGInOutLotMinusCheck @CompanySeq, '#TLGInOutDailyBatch'       
    
    IF EXISTS(SELECT 1 FROM #TLGInOutDailyBatch WHERE Status <> 0)    
    BEGIN    
        UPDATE #hencom_TPDMESErpApplyBatch  
           SET Result        = C.Result   ,                                               
               MessageType   = C.MessageType ,                                               
               Status        = C.Status     
          FROM #hencom_TPDMESErpApplyBatch  AS A    
          JOIN #Main                        AS B ON A.SumMesKey = B.SumMesKey    
          JOIN #TLGInOutDailyBatch          AS C ON B.WorkReportSeq = C.InOutSeq    
         WHERE C.Status <> 0    
      
        SELECT * FROM #hencom_TPDMESErpApplyBatch      
        RETURN                                  
    END    

    TRUNCATE TABLE #TLGInOutMonth    
    TRUNCATE TABLE #TLGInOutMonthLot    
    ------------------------------------------------------------------------------------------------------------------------
    -- ������� ����, END 
    ------------------------------------------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------------------------------------------
    -- �۾����� ����
    ------------------------------------------------------------------------------------------------------------------------
    -- TR 
    DELETE A 
      FROM _TPDSFCWorkOrder AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #Main WHERE WorkOrderSeq = A.WorkOrderSeq AND WorkOrderSeq = A.WorkOrderSerl)
    ------------------------------------------------------------------------------------------------------------------------
    -- �۾����� ����, END 
    ------------------------------------------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------------------------------------------
    -- ���°� Update
    ------------------------------------------------------------------------------------------------------------------------
    UPDATE A
       SET WorkOrderSeq      = NULL, 
           WorkReportSeq     = NULL, 
           InvoiceSeq        = NULL, 
           ProdIsErpApply    = NULL, 
           ProdResults       = NULL, 
           ProdStatus        = NULL, 
           InvIsErpApply     = NULL, 
           InvResults        = NULL, 
           InvStatus         = NULL, 
           SalesSeq          = NULL 
      FROM hencom_TIFProdWorkReportClosesum AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #Main WHERE SumMesKey = A.SUMMesKey)

    UPDATE A
       SET WorkOrderSeq     = NULL, 
           WorkReportSeq    = NULL, 
           InvoiceSeq       = NULL, 
           ProdIsErpApply   = NULL, 
           ProdResults      = NULL, 
           ProdStatus       = NULL, 
           InvIsErpApply    = NULL, 
           InvResults       = NULL, 
           InvStatus        = NULL 
      FROM hencom_TIFProdWorkReportClose AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #Main WHERE SumMesKey = A.SUMMesKey)

    
    UPDATE A
       SET IsErpApply = NULL
      FROM hencom_TIFProdMatInputCloseSum AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #Main WHERE SumMesKey = A.SumMesKey)
    ------------------------------------------------------------------------------------------------------------------------
    -- ���°� Update, END 
    ------------------------------------------------------------------------------------------------------------------------
    
    SELECT * FROM #hencom_TPDMESErpApplyBatch 
    
    RETURN    
    
go 

begin tran 
exec hencom_SPDMESErpApplyBatchCancel @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <SumMesKey>9378</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <SumMesKey>9379</SumMesKey>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032173,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027245
rollback 