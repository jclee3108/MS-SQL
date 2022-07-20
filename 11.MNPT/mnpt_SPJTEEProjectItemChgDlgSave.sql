  
IF OBJECT_ID('mnpt_SPJTEEProjectItemChgDlgSave') IS NOT NULL   
    DROP PROC mnpt_SPJTEEProjectItemChgDlgSave  
GO  
      
-- v2018.02.12
      
-- û���׸񺯰�-���� by ����õ 
CREATE PROC mnpt_SPJTEEProjectItemChgDlgSave  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0   
AS    
    
    --select '_TPJTProjectDelivery', 1, ItemSeq from _TPJTProjectDelivery where pjtseq = 424 and delvserl = 2 
    --select 'mnpt_TPJTProjectMapping', 1, ItemSeq from mnpt_TPJTProjectMapping where pjtseq = 424 
    --select 'mnpt_TPJTLinkInvoiceItem', 1, ItemSeq from mnpt_TPJTLinkInvoiceItem where pjtseq = 424 and invoiceserl = 2 
    --select '_TSLInvoiceItem', 1, ItemSeq from _TSLInvoiceItem where invoiceseq = 630 and invoiceserl = 2 
    --select '_TSLSalesItem', 1, ItemSeq from _TSLSalesItem where SalesSeq = 135 and SalesSErl = 2 

    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        -- �α� �����    
        DECLARE @TableColumns NVARCHAR(4000)    

        -- ��� Mapping
        SELECT A.PJTSeq, A.MappingSerl, B.ItemSeqOld, B.ItemSeq, B.WorkingTag, B.IDX_NO, B.DataSeq, B.Status
          INTO #MappingLog 
          FROM mnpt_TPJTProjectMapping  AS A 
          JOIN ( 
                SELECT Z.PJTSeq, Z.ItemSeq AS ItemSeqOld, Y.ItemSeq, Y.WorkingTag, Y.IDX_NO, Y.DataSeq, Y.Status
                  FROM _TPJTProjectDelivery AS Z 
                  JOIN #BIZ_OUT_DataBlock1  AS Y ON ( Y.PJTSeq = Z.PJTSeq AND Y.DelvSerl = Z.DelvSerl )
                 WHERE Z.CompanySeq = @CompanySeq 
               ) AS B ON ( B.PJTSeq = A.PJTSeq AND B.ItemSeqOld = A.ItemSeq ) 
        
        -- Master �α�   
        SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTProjectMapping')    
      
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'mnpt_TPJTProjectMapping'    , -- ���̺��        
                      '#MappingLog'    , -- �ӽ� ���̺��        
                      'PJTSeq,MappingSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                      @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
        UPDATE A
           SET ItemSeq = B.ItemSeq 
          FROM mnpt_TPJTProjectMapping  AS A 
          JOIN #MappingLog              AS B ON ( B.PJTSeq = A.PJTSeq AND B.MappingSerl = A.MappingSerl ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND B.WorkingTag = 'U' 
           AND B.Status = 0 

        -- ���-û���׸�
        SELECT @TableColumns = dbo._FGetColumnsForLog('_TPJTProjectDelivery')    
      
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      '_TPJTProjectDelivery'    , -- ���̺��        
                      '#BIZ_OUT_DataBlock1'    , -- �ӽ� ���̺��        
                      'PJTSeq,DelvSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                      @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   

        UPDATE B   
           SET B.ItemSeq        = A.ItemSeq,  
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE() 
          FROM #BIZ_OUT_DataBlock1  AS A   
          JOIN _TPJTProjectDelivery AS B ON ( B.CompanySeq = @CompanySeq AND A.PJTseq = B.PJTseq AND A.DelvSerl = B.DelvSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          

        -- û��-û���׸�
        SELECT B.InvoiceSeq, B.InvoiceSerl, A.ItemSeqOld, A.ItemSeq, A.WorkingTag, A.IDX_NO, A.DataSeq, A.Status
          INTO #InvoiceItemLog 
          FROM #MappingLog              AS A 
          JOIN mnpt_TPJTLinkInvoiceItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.ItemSeq = A.ItemSeqOld ) 
                
        -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
        EXEC _SCOMLog  @CompanySeq   ,
                       @UserSeq      ,
                       '_TSLInvoiceItem', -- �����̺��
                       '#InvoiceItemLog', -- �������̺��
                       'InvoiceSeq, InvoiceSerl' , -- Ű�� �������� ���� , �� �����Ѵ�. 
                       'CompanySeq, InvoiceSeq, InvoiceSerl, ItemSeq, UnitSeq, ItemPrice, CustPrice, Qty, IsInclusedVAT, VATRate, CurAmt, CurVAT, DomAmt, DomVAT,
                        STDUnitSeq, STDQty, WHSeq, Remark, UMEtcOutKind, TrustCustSeq, LotNo, SerialNo, PJTSeq, WBSSeq, CCtrSeq, LastUserSeq, LastDateTime,Price,PgmSeq,Dummy1,Dummy2,Dummy3,Dummy4,Dummy5,Dummy6,Dummy7,Dummy8,Dummy9,Dummy10',
                       '', @PgmSeq 
        --return 
        UPDATE A
           SET ItemSeq = B.ItemSeq 
          FROM _TSLInvoiceItem  AS A 
          JOIN #InvoiceItemLog  AS B ON ( B.InvoiceSeq = A.InvoiceSeq AND B.InvoiceSerl = A.InvoiceSerl ) 
         WHERE A.CompanySeq = @CompanySeq 

        -- û��-Link
        -- Master �α�   
        SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTLinkInvoiceItem')    
      
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'mnpt_TPJTLinkInvoiceItem'    , -- ���̺��        
                      '#InvoiceItemLog'    , -- �ӽ� ���̺��        
                      'InvoiceSeq,InvoiceSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                      @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
        
        UPDATE A
           SET ItemSeq = B.ItemSeq 
          FROM mnpt_TPJTLinkInvoiceItem AS A 
          JOIN #InvoiceItemLog          AS B ON ( B.InvoiceSeq = A.InvoiceSeq AND B.InvoiceSerl = A.InvoiceSerl ) 
         WHERE A.CompanySeq = @CompanySeq 

        -- ����-û���׸�
        CREATE TABLE #InvoiceProg 
        ( 
            IDX_NO      INT IDENTITY, 
            InvoiceSeq  INT, 
            InvoiceSerl INT, 
            ItemSeq     INT, 
            WorkingTag  NCHAR(1), 
            DataSeq     INT, 
            Status      INT 
        )   
        INSERT INTO #InvoiceProg ( InvoiceSeq, InvoiceSerl, ItemSeq, WorkingTag, DataSeq, Status ) 
        SELECT InvoiceSeq, InvoiceSerl, ItemSeq, WorkingTag, DataSeq, Status 
          FROM #InvoiceItemLog 

        CREATE TABLE #TMP_ProgressTable 
        (
            IDOrder   INT, 
            TableName NVARCHAR(100)
        ) 

        INSERT INTO #TMP_ProgressTable (IDOrder, TableName) 
        SELECT 1, '_TSLSalesItem'   -- ������ ã�� ���̺�
        
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
            @TableName = '_TSLInvoiceItem',    -- ������ �Ǵ� ���̺�
            @TempTableName = '#InvoiceProg',  -- ������ �Ǵ� �������̺�
            @TempSeqColumnName = 'InvoiceSeq',  -- �������̺��� Seq
            @TempSerlColumnName = 'InvoiceSerl',  -- �������̺��� Serl
            @TempSubSerlColumnName = ''  
        

        SELECT A.*, C.SalesSeq, C.SalesSerl 
          INTO #SalesItemLog 
          FROM #InvoiceProg             AS A 
          JOIN #TCOMProgressTracking    AS B ON ( B.IDX_NO = A.IDX_NO ) 
          JOIN _TSLSalesItem            AS C ON ( C.CompanySeq = @CompanySeq AND C.SalesSeq = B.Seq AND C.SalesSerl = B.Serl ) 
        
        -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
        EXEC _SCOMLog  @CompanySeq   ,
                       @UserSeq      ,
                       '_TSLSalesItem', -- �����̺��
                       '#SalesItemLog', -- �������̺��
                       'SalesSeq, SalesSerl' , -- Ű�� �������� ���� , �� �����Ѵ�. 
                       'CompanySeq, SalesSeq, SalesSerl, ItemSeq, UnitSeq, ItemPrice, CustPrice, Qty, IsInclusedVAT, VATRate, CurAmt, CurVAT, DomAmt, DomVAT, STDUnitSeq, STDQty, WHSeq, 
                        Remark, AccSeq, VATSeq, OppAccSeq, LotNo, SerialNo, MngSalesSerl, IsSetItem, PJTSeq, WBSSeq, CustSeq, DeptSeq, EmpSeq, LastUserSeq, LastDateTime, Price, PgmSeq', 
                       '', @PgmSeq 
        
        UPDATE A 
           SET ItemSeq = B.ItemSeq, 
               AccSeq = D.AccSeq 
          FROM _TSLSalesItem                AS A 
                     JOIN #SalesItemLog     AS B ON ( B.SalesSeq = A.SalesSeq AND B.SalesSerl = A.SalesSerl ) 
          LEFT OUTER JOIN _TDAItem          AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
          LEFT OUTER JOIN _TDAItemAssetAcc  AS D ON ( D.CompanySeq = @CompanySeq AND D.AssetSeq = C.AssetSeq AND D.AssetAccKindSeq = 2 ) 
         WHERE A.CompanySeq = @CompanySeq 
    END    

    --select '_TPJTProjectDelivery', 2, ItemSeq from _TPJTProjectDelivery where pjtseq = 424 and delvserl = 2 
    --select 'mnpt_TPJTProjectMapping', 2, ItemSeq from mnpt_TPJTProjectMapping where pjtseq = 424 
    --select 'mnpt_TPJTLinkInvoiceItem', 2, ItemSeq from mnpt_TPJTLinkInvoiceItem where pjtseq = 424 and invoiceserl = 2 
    --select '_TSLInvoiceItem', 2, ItemSeq from _TSLInvoiceItem where invoiceseq = 630 and invoiceserl = 2 
    --select '_TSLSalesItem', 2, ItemSeq from _TSLSalesItem where SalesSeq = 135 and SalesSErl = 2 

    
    --select * from _TPJTProjectDeliveryLog where pjtseq = 424 and delvserl = 2 and LogUserSeq = 167 and LogDateTime > '20180212'
    --select * from mnpt_TPJTProjectMappingLog where pjtseq = 424 and LogUserSeq = 167 and LogDateTime > '20180212'
    --select * from mnpt_TPJTLinkInvoiceItemLog where pjtseq = 424 and invoiceserl = 2 and LogUserSeq = 167 and LogDateTime > '20180212'
    --select * from _TSLInvoiceItemLog where invoiceseq = 630 and invoiceserl = 2 and LogUserSeq = 167 and LogDateTime > '20180212'
    --select * from _TSLSalesItemLog where SalesSeq = 135 and SalesSErl = 2 and LogUserSeq = 167 and LogDateTime > '20180212'


    RETURN  
go
begin tran 
DECLARE   @CONST_#BIZ_IN_DataBlock1 INT        , @CONST_#BIZ_OUT_DataBlock1 INTSELECT    @CONST_#BIZ_IN_DataBlock1 = 0        , @CONST_#BIZ_OUT_DataBlock1 = 0
IF @CONST_#BIZ_IN_DataBlock1 = 0
BEGIN
    CREATE TABLE #BIZ_IN_DataBlock1
    (
        WorkingTag      NCHAR(1)
        , IDX_NO        INT
        , DataSeq       INT
        , Selected      INT
        , MessageType   INT
        , Status        INT
        , Result        NVARCHAR(255)
        , ROW_IDX       INT
        , IsChangedMst  NCHAR(1)
        , TABLE_NAME    NVARCHAR(255)

        , ItemName NVARCHAR(200), ItemSeq INT, PJTSeq INT, DelvSerl INT, PJTName NVARCHAR(200), ItemNameOld NVARCHAR(200), ItemSeqOld INT
    )
    
    SET @CONST_#BIZ_IN_DataBlock1 = 1

END

IF @CONST_#BIZ_OUT_DataBlock1 = 0
BEGIN
    CREATE TABLE #BIZ_OUT_DataBlock1
    (
        WorkingTag      NCHAR(1)
        , IDX_NO        INT
        , DataSeq       INT
        , Selected      INT
        , MessageType   INT
        , Status        INT
        , Result        NVARCHAR(255)
        , ROW_IDX       INT
        , IsChangedMst  NCHAR(1)
        , TABLE_NAME    NVARCHAR(255)

        , ItemName NVARCHAR(200), ItemSeq INT, PJTSeq INT, DelvSerl INT, PJTName NVARCHAR(200), ItemNameOld NVARCHAR(200), ItemSeqOld INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, ItemName, ItemSeq, PJTSeq, DelvSerl, PJTName, ItemNameOld, ItemSeqOld) 
SELECT N'U', 2, 1, 0, 0, NULL, NULL, NULL, N'DataBlock1', N'�����������', N'533', N'424', N'2', NULL, N'�������׽�Ʈ.', N'517'



DECLARE @HasError           NCHAR(1)
        , @UseTransaction   NCHAR(1)
        -- ���� SP�� �Ķ����
        , @ServiceSeq       INT
        , @MethodSeq        INT
        , @WorkingTag       NVARCHAR(10)
        , @CompanySeq       INT
        , @LanguageSeq      INT
        , @UserSeq          INT
        , @PgmSeq           INT
        , @IsTransaction    BIT

SET @HasError = N'0'
SET @UseTransaction = N'0'

BEGIN TRY

SET @ServiceSeq     = 13820156
--SET @MethodSeq      = 2
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820136
SET @IsTransaction  = 1
-- InputData�� OutputData�� ����INSERT INTO #BIZ_OUT_DataBlock1(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, ItemName, ItemSeq, PJTSeq, DelvSerl, PJTName, ItemNameOld, ItemSeqOld)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, ItemName, ItemSeq, PJTSeq, DelvSerl, PJTName, ItemNameOld, ItemSeqOld      FROM  #BIZ_IN_DataBlock1-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTEEProjectItemChgDlgCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : End-- ExecuteOrder : 2 : StartSET @UseTransaction = N'1'BEGIN TRANEXEC    mnpt_SPJTEEProjectItemChgDlgSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0)
BEGIN
    --ROLLBACK TRAN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 2 : EndCOMMIT TRANSET @UseTransaction = N'0'GOTO_END:SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType
        , CASE
            WHEN Status = 0 OR Status IS NULL THEN
                -- �����ΰ� �߿�
                CASE
                    WHEN @HasError = N'1' THEN
                        -- ������ �߻��� ���̸�
                        CASE
                            WHEN @UseTransaction = N'1' THEN
                                999999  -- Ʈ������� ���
                            ELSE
                                999998  -- Ʈ������� �ƴ� ���
                        END
                    ELSE
                        -- ������ �߻����� ���� ���̸�
                        0
                END
            ELSE
                Status
        END AS Status
        , Result, ROW_IDX, IsChangedMst, ItemName, ItemSeq, PJTSeq, DelvSerl, PJTName, ItemNameOld, ItemSeqOld  FROM #BIZ_OUT_DataBlock1 ORDER BY IDX_NO, ROW_IDX
END TRY
BEGIN CATCH
-- SQL ������ ���� ���⼭ ó���� �ȴ�
    IF @UseTransaction = N'1'
        ROLLBACK TRAN
    
    DECLARE   @ERROR_MESSAGE    NVARCHAR(4000)
            , @ERROR_SEVERITY   INT
            , @ERROR_STATE      INT
            , @ERROR_PROCEDURE  NVARCHAR(128)

    SELECT    @ERROR_MESSAGE    = ERROR_MESSAGE()
            , @ERROR_SEVERITY   = ERROR_SEVERITY() 
            , @ERROR_STATE      = ERROR_STATE() 
            , @ERROR_PROCEDURE  = ERROR_PROCEDURE()
    RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE, @ERROR_PROCEDURE)

    RETURN
END CATCH

-- SQL ������ ������ üũ�������� �߻��� ������ ���⼭ ó��
IF @HasError = N'1' AND @UseTransaction = N'1'
    ROLLBACK TRAN
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1rollback 