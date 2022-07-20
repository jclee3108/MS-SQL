  
IF OBJECT_ID('mnpt_SPJTShipWorkPlanFinishCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTShipWorkPlanFinishCheck  
GO  
    
-- v2017.12.07

-- �����۾���ȹ�Ϸ��Է�-üũ by ����õ
CREATE PROC mnpt_SPJTShipWorkPlanFinishCheck  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0    
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
    
    -- �ߺ����� üũ :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
                          @LanguageSeq       ,  
                          0, ''
      
    UPDATE #BIZ_OUT_DataBlock1  
       SET Result       = @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #BIZ_OUT_DataBlock1 AS A   
      JOIN (SELECT S.ShipSeq, S.ShipSerl, S.PJTSeq
              FROM (SELECT A1.ShipSeq, A1.ShipSerl, A1.PJTSeq
                      FROM #BIZ_OUT_DataBlock1 AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.ShipSeq, A1.ShipSerl, A1.PJTSeq  
                      FROM mnpt_TPJTShipWorkPlanFinish AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND ShipPlanFinishSeq = A1.ShipPlanFinishSeq 
                                      )  
                   ) AS S  
             GROUP BY S.ShipSeq, S.ShipSerl, S.PJTSeq
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.ShipSeq = B.ShipSeq AND A.ShipSerl = B.ShipSerl AND A.PJTSeq = B.PJTSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    /*
    ------------------------------------------------------------------------------------------
    -- üũ0, ���� �������� ���ȷ�������Ʈ�� �ٸ��� �Է� �� �� �����ϴ�.
    ------------------------------------------------------------------------------------------
    
    SELECT DISTINCT S.ShipSeq, S.ShipSerl, S.DockPJTSeq 
      INTO #DockPJTCnt
      FROM ( 
            SELECT A.ShipSeq, A.ShipSerl, A.DockPJTSeq 
              FROM mnpt_TPJTShipWorkPlanFinish AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE ShipSeq = A.ShipSeq AND ShipSerl = A.ShipSerl) 
               AND NOT EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE ShipPlanFinishSeq = A.ShipPlanFinishSeq) 
               AND ISNULL(A.DockPJTSeq,0) <> 0 
            UNION ALL 
            SELECT A.ShipSeq, A.ShipSerl, A.DockPJTSeq 
              FROM #BIZ_OUT_DataBlock1 AS A 
             WHERE ISNULL(A.DockPJTSeq,0) <> 0 
           ) AS S 
    
    UPDATE A
       SET Result = '���� �������� ���ȷ�������Ʈ�� �ٸ��� �Է� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234
      FROM #BIZ_OUT_DataBlock1 AS A 
      JOIN ( 
            SELECT ShipSeq, ShipSerl, COUNT(1) AS Cnt 
              FROM #DockPJTCnt 
             GROUP BY ShipSeq, ShipSerl 
             HAVING COUNT(1) > 1 
           ) AS B ON ( B.ShipSeq = A.ShipSeq AND B.ShipSerl = A.ShipSerl ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
    ------------------------------------------------------------------------------------------
    -- üũ0, End
    ------------------------------------------------------------------------------------------
    */
    ------------------------------------------------------------------------------------------
    -- üũ1, �۾���ȹ�� ����Ǿ� ���� �� �� �����ϴ�.(������,������Ʈ)
    ------------------------------------------------------------------------------------------
    UPDATE A
       SET Result = '�۾���ȹ�� ����Ǿ� ���� �� �� �����ϴ�.(������,������Ʈ)', 
           Status = 1234, 
           MessageType = 1234 
      From #BIZ_OUT_DataBlock1                      AS A 
      LEFT OUTER JOIN mnpt_TPJTShipWorkPlanFinish   AS B ON ( B.CompanySeq = @CompanySeq AND B.ShipPlanFinishSeq = A.ShipPlanFinishSeq ) 
     WHERE A.WorkingTag = 'U'
       AND A.Status = 0 
       AND ( B.PJTSeq <> A.PJTSeq OR B.ShipSeq <> A.ShipSeq OR B.ShipSerl <> A.ShipSerl ) 
       AND EXISTS (SELECT 1 FROM mnpt_TPJTWorkPlan WHERE CompanySeq = @CompanySeq AND ShipSeq = B.ShipSeq AND ShipSerl = B.ShipSerl AND PJTSeq = B.PJTSeq) 
    ------------------------------------------------------------------------------------------
    -- üũ1, End
    ------------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------------
    -- üũ2, �۾���ȹ�� ����Ǿ� ���� �� �� �����ϴ�.(������,������Ʈ)
    ------------------------------------------------------------------------------------------
    UPDATE A
       SET Result = '�۾���ȹ�� ����Ǿ� ���� �� �� �����ϴ�.(������,������Ʈ)', 
           Status = 1234, 
           MessageType = 1234 
      From #BIZ_OUT_DataBlock1                      AS A 
      LEFT OUTER JOIN mnpt_TPJTShipWorkPlanFinish   AS B ON ( B.CompanySeq = @CompanySeq AND B.ShipPlanFinishSeq = A.ShipPlanFinishSeq ) 
     WHERE A.WorkingTag = 'D'
       AND A.Status = 0 
       AND EXISTS (SELECT 1 FROM mnpt_TPJTWorkPlan WHERE CompanySeq = @CompanySeq AND ShipSeq = B.ShipSeq AND ShipSerl = B.ShipSerl AND PJTSeq = B.PJTSeq) 
    ------------------------------------------------------------------------------------------
    -- üũ2, End
    ------------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------------
    -- üũ3, û�������� �Ǿ� ���� �� �� �����ϴ�.
    ------------------------------------------------------------------------------------------
    UPDATE A
       SET Result = 'û�������� �Ǿ� ���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      From #BIZ_OUT_DataBlock1                      AS A 
      LEFT OUTER JOIN mnpt_TPJTShipWorkPlanFinish   AS B ON ( B.CompanySeq = @CompanySeq AND B.ShipPlanFinishSeq = A.ShipPlanFinishSeq ) 
                 JOIN mnpt_TPJTShipDetail           AS C ON ( C.CompanySeq = @CompanySeq AND C.ShipSeq = B.ShipSeq AND C.ShipSerl = B.ShipSerl ) 
     WHERE A.WorkingTag = 'D'
       AND A.Status = 0 
       AND EXISTS (SELECT 1 
                     FROM mnpt_TPJTLinkInvoiceItem 
                    WHERE CompanySeq = @CompanySeq 
                      AND OldShipSeq = C.ShipSeq 
                      AND OldShipSerl = C.ShipSerl
                      AND ChargeDate = LEFT(C.OutDateTime,6)
                      AND PJTSeq = B.PJTSeq 
                  ) 
    ------------------------------------------------------------------------------------------
    -- üũ3, End
    ------------------------------------------------------------------------------------------
    
    
    ------------------------------------------------------------------------------------------
    -- üũ4, û�������� �Ǿ� ���� �� �� �����ϴ�.
    --------------------------------------------------------------------------------------------
    UPDATE A
       SET Result = 'û�������� �Ǿ� ���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      From #BIZ_OUT_DataBlock1                      AS A 
      LEFT OUTER JOIN mnpt_TPJTShipWorkPlanFinish   AS B ON ( B.CompanySeq = @CompanySeq AND B.ShipPlanFinishSeq = A.ShipPlanFinishSeq ) 
                 JOIN mnpt_TPJTShipDetail           AS C ON ( C.CompanySeq = @CompanySeq AND C.ShipSeq = B.ShipSeq AND C.ShipSerl = B.ShipSerl ) 
     WHERE A.WorkingTag = 'U'
       AND A.Status = 0 
       AND ( A.ShipSeq <> B.ShipSeq 
            OR A.ShipSerl <> B.ShipSerl 
            OR A.PJTSeq <> B.PJTSeq 
            OR A.PlanQty <> B.PlanQty 
            OR A.PlanQty <> B.PlanQty 
            OR A.PlanMTWeight <> B.PlanMTWeight 
            OR A.PlanCBMWeight <> B.PlanCBMWeight 
            OR A.IsCfm <> B.IsCfm 
           )
       AND EXISTS (SELECT 1 
                     FROM mnpt_TPJTLinkInvoiceItem 
                    WHERE CompanySeq = @CompanySeq 
                      AND OldShipSeq = C.ShipSeq 
                      AND OldShipSerl = C.ShipSerl
                      AND ChargeDate = LEFT(C.OutDateTime,6)
                      AND PJTSeq = B.PJTSeq 
                  ) 
    ------------------------------------------------------------------------------------------
    -- üũ4, End
    ------------------------------------------------------------------------------------------


    ------------------------------------------------------------------------------------------
    -- üũ5, �������������� ����Ǿ� ���� �� �� �����ϴ�.
    ------------------------------------------------------------------------------------------
    UPDATE A
       SET Result = '�������������� ����Ǿ� ���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      From #BIZ_OUT_DataBlock1                      AS A 
      LEFT OUTER JOIN mnpt_TPJTShipWorkPlanFinish   AS B ON ( B.CompanySeq = @CompanySeq AND B.ShipPlanFinishSeq = A.ShipPlanFinishSeq ) 
     WHERE A.WorkingTag = 'U'
       AND A.Status = 0 
       AND (EXISTS (SELECT 1 FROM mnpt_TPJTUnionPayDaily WHERE CompanySeq = @CompanySeq AND ShipSeq = B.ShipSeq AND ShipSerl = B.ShipSerl AND PJTSeq = B.PJTSeq)
           OR EXISTS (SELECT 1 FROM mnpt_TPJTUnionPayDaily2 WHERE CompanySeq = @CompanySeq AND ShipSeq = B.ShipSeq AND ShipSerl = B.ShipSerl AND PJTSeq = B.PJTSeq)
           )
    -------------------------------------------------------------------------
    -- üũ5, End
    ------------------------------------------------------------------------------------------


    ------------------------------------------------------------------------------------------
    -- üũ6, û������(���ȷ�)�� �Ǿ� ���� �� �� �����ϴ�.
    ------------------------------------------------------------------------------------------
    UPDATE A
       SET Result = 'û������(���ȷ�)�� �Ǿ� ���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      From #BIZ_OUT_DataBlock1                      AS A 
      LEFT OUTER JOIN mnpt_TPJTShipWorkPlanFinish   AS B ON ( B.CompanySeq = @CompanySeq AND B.ShipPlanFinishSeq = A.ShipPlanFinishSeq ) 
                 JOIN mnpt_TPJTShipDetail           AS C ON ( C.CompanySeq = @CompanySeq AND C.ShipSeq = B.ShipSeq AND C.ShipSerl = B.ShipSerl ) 
     WHERE A.WorkingTag = 'U'
       AND A.Status = 0 
       AND ( A.DockPJTSeq <> B.DockPJTSeq )
       AND EXISTS (SELECT 1 
                     FROM mnpt_TPJTLinkInvoiceItem 
                    WHERE CompanySeq = @CompanySeq 
                      AND OldShipSeq = C.ShipSeq 
                      AND OldShipSerl = C.ShipSerl
                      AND ChargeDate = LEFT(C.OutDateTime,8)
                      AND PJTSeq = B.DockPJTSeq 
                  ) 
    ------------------------------------------------------------------------------------------
    -- üũ6, End
    ------------------------------------------------------------------------------------------

    --select * from #BIZ_OUT_DataBlock1 
    
    --return 
    ------------------------------------------------------------------------------------------
    -- üũ7, �۾������� ����(�۾��׸�)�� ���� �ʾ� �����Ϸ�ó���� �� �� �����ϴ�.
    ------------------------------------------------------------------------------------------
    UPDATE A
       SET Result = '�۾������� ����(�۾��׸�)�� ���� �ʾ� �����Ϸ�ó���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      From #BIZ_OUT_DataBlock1                      AS A 
      LEFT OUTER JOIN mnpt_TPJTShipWorkPlanFinish   AS B ON ( B.CompanySeq = @CompanySeq AND B.ShipPlanFinishSeq = A.ShipPlanFinishSeq ) 
      OUTER APPLY ( 
                    SELECT MIN(ISNULL(Z.IsCfm,'0')) AS IsReportCfm
                      FROM mnpt_TPJTWorkReport AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.ShipSeq = A.ShipSeq 
                       AND Z.ShipSerl = A.ShipSerl 
                       AND Z.PJTSeq = A.PJTSeq 
                   ) AS C
     WHERE A.WorkingTag = 'U'
       AND A.Status = 0 
       AND B.IsCfm <> A.IsCfm 
       AND ISNULL(C.IsReportCfm,'0') = '0'
       AND A.IsCfm = '1'
       AND EXISTS (SELECT 1 FROM mnpt_TPJTWorkPlan WHERE CompanySeq = @CompanySeq AND ShipSeq = B.ShipSeq AND ShipSerl = B.ShipSerl )
    ------------------------------------------------------------------------------------------
    -- üũ7, End
    ------------------------------------------------------------------------------------------


    ------------------------------------------------------------------------------------------
    -- üũ8, �۾������� ����(��������)�� ���� �ʾ� �����Ϸ�ó���� �� �� �����ϴ�.
    ------------------------------------------------------------------------------------------
    UPDATE A
       SET Result = '�۾������� ����(��������)�� ���� �ʾ� �����Ϸ�ó���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      From #BIZ_OUT_DataBlock1                      AS A 
      LEFT OUTER JOIN mnpt_TPJTShipWorkPlanFinish   AS B ON ( B.CompanySeq = @CompanySeq AND B.ShipPlanFinishSeq = A.ShipPlanFinishSeq ) 
      CROSS APPLY ( 
                    SELECT MIN(ISNULL(Y.IsCfm,'0')) AS IsReportCfm
                      FROM mnpt_TPJTWorkReport      AS Z 
                      JOIN mnpt_TPJTWorkReportItem  AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.WorkReportSeq = Z.WorkReportSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.ShipSeq = A.ShipSeq 
                       AND Z.ShipSerl = A.ShipSerl 
                       AND Z.PJTSeq = A.PJTSeq 
                   ) AS C
     WHERE A.WorkingTag = 'U'
       AND A.Status = 0 
       AND B.IsCfm <> A.IsCfm 
       AND C.IsReportCfm = '0'
       AND A.IsCfm = '1' 
       
    ------------------------------------------------------------------------------------------
    -- üũ8, End
    ------------------------------------------------------------------------------------------
    
    ------------------------------------------------------------------------------------------
    -- üũ9, �Ͻÿ� �ð��� ���� �Է����ֽñ� �ٶ��ϴ�. ( ����, ����, ���� ) 
    ------------------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '�Ͻÿ� �ð��� ���� �Է����ֽñ� �ٶ��ϴ�. ( ����, ����, ���� )', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND ( (A.InDate <> '' AND A.InTime = '') OR (A.InTime <> '' AND A.InDate = '') 
           OR (A.ApproachDate <> '' AND A.ApproachTime = '') OR (A.ApproachTime <> '' AND A.ApproachDate = '') 
           OR (A.OutDate <> '' AND A.OutTime = '') OR (A.OutTime <> '' AND A.OutDate = '') 
           )
    ------------------------------------------------------------------------------------------
    -- üũ9, End
    ------------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------------
    -- üũ10, �̾ȳ����� �����Ͽ� ���Ƚð��� ���� �� �� �����ϴ�.
    ------------------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '�̾ȳ����� �����Ͽ� ���Ƚð��� ���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1 AS A 
      LEFT OUTER JOIN mnpt_TPJTShipDetail AS B ON ( B.CompanySeq = @CompanySeq AND B.ShipSeq = A.ShipSeq AND B.ShipSerl = A.ShipSerl ) 
     WHERE A.WorkingTag = 'U' 
       AND A.Status = 0 
       AND EXISTS (SELECT 1 FROM mnpt_TPJTShipDetailChange WHERE CompanySeq = @CompanySeq AND ShipSeq = A.ShipSeq AND ShipSerl = A.ShipSerl) 
       AND A.ApproachDate + A.ApproachTime <> B.ApproachDateTime
    ------------------------------------------------------------------------------------------
    -- üũ10, End
    ------------------------------------------------------------------------------------------

    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'mnpt_TPJTShipWorkPlanFinish', 'ShipPlanFinishSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #BIZ_OUT_DataBlock1  
           SET ShipPlanFinishSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #BIZ_OUT_DataBlock1   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #BIZ_OUT_DataBlock1  
     WHERE Status = 0  
       AND ( ShipPlanFinishSeq = 0 OR ShipPlanFinishSeq IS NULL )  
    

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

        , IFShipCode NVARCHAR(100), SerlYear CHAR(4), SerlNo NVARCHAR(100), BizUnitName NVARCHAR(200), CustName NVARCHAR(200), PJTNo NVARCHAR(200), EnShipName NVARCHAR(200), ContractName NVARCHAR(200), PJTTypeName NVARCHAR(200), PJTName NVARCHAR(200), FrWorkDate CHAR(8), ToWorkDate CHAR(8), FrContractDate CHAR(8), ToContractDate CHAR(8), BizUnit INT, CustSeq INT, ShipSeq INT, PJTTypeSeq INT, ShipSerlNo NVARCHAR(200), ShipSerl INT, PJTSeq INT, PlanQty DECIMAL(19, 5), PlanMTWeight DECIMAL(19, 5), PlanCBMWeight DECIMAL(19, 5), WorkDayCnt INT, UMWorkTypeName NVARCHAR(200), ResultQty DECIMAL(19, 5), ResultMTWeight DECIMAL(19, 5), ResultCBMWeight DECIMAL(19, 5), IsReportCfm CHAR(1), IsCfm CHAR(1), InDate CHAR(8), InTime NVARCHAR(5), ApproachDate CHAR(8), ApproachTime NVARCHAR(5), WorkSrtDate CHAR(8), WorkSrtTime NVARCHAR(5), WorkEndDate CHAR(8), WorkEndTime NVARCHAR(5), OutDate CHAR(8), OutTime NVARCHAR(5), ChangeCnt INT, DiffApproachTime DECIMAL(19, 5), InPlanDateTime NVARCHAR(200), OutPlanDateTime NVARCHAR(200), ShipPlanFinishSeq INT, FinishTypeName NVARCHAR(200), FinishType INT, DockPJTName NVARCHAR(200), DockPJTSeq INT, DockCustSeq INT, DockCustName NVARCHAR(100)
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

        , IFShipCode NVARCHAR(100), SerlYear CHAR(4), SerlNo NVARCHAR(100), BizUnitName NVARCHAR(200), CustName NVARCHAR(200), PJTNo NVARCHAR(200), EnShipName NVARCHAR(200), ContractName NVARCHAR(200), PJTTypeName NVARCHAR(200), PJTName NVARCHAR(200), FrWorkDate CHAR(8), ToWorkDate CHAR(8), FrContractDate CHAR(8), ToContractDate CHAR(8), BizUnit INT, CustSeq INT, ShipSeq INT, PJTTypeSeq INT, ShipSerlNo NVARCHAR(200), ShipSerl INT, PJTSeq INT, PlanQty DECIMAL(19, 5), PlanMTWeight DECIMAL(19, 5), PlanCBMWeight DECIMAL(19, 5), WorkDayCnt INT, UMWorkTypeName NVARCHAR(200), ResultQty DECIMAL(19, 5), ResultMTWeight DECIMAL(19, 5), ResultCBMWeight DECIMAL(19, 5), IsReportCfm CHAR(1), IsCfm CHAR(1), InDate CHAR(8), InTime NVARCHAR(5), ApproachDate CHAR(8), ApproachTime NVARCHAR(5), WorkSrtDate CHAR(8), WorkSrtTime NVARCHAR(5), WorkEndDate CHAR(8), WorkEndTime NVARCHAR(5), OutDate CHAR(8), OutTime NVARCHAR(5), ChangeCnt INT, DiffApproachTime DECIMAL(19, 5), InPlanDateTime NVARCHAR(200), OutPlanDateTime NVARCHAR(200), ShipPlanFinishSeq INT, FinishTypeName NVARCHAR(200), FinishType INT, IsPlanExists CHAR(1), DockPJTName NVARCHAR(200), DockPJTSeq INT, DockCustSeq INT, DockCustName NVARCHAR(100)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, IFShipCode, SerlYear, SerlNo, BizUnitName, CustName, PJTNo, EnShipName, ContractName, PJTTypeName, PJTName, FrWorkDate, ToWorkDate, FrContractDate, ToContractDate, BizUnit, CustSeq, ShipSeq, PJTTypeSeq, ShipSerlNo, ShipSerl, PJTSeq, PlanQty, PlanMTWeight, PlanCBMWeight, WorkDayCnt, UMWorkTypeName, ResultQty, ResultMTWeight, ResultCBMWeight, IsReportCfm, IsCfm, InDate, InTime, ApproachDate, ApproachTime, WorkSrtDate, WorkSrtTime, WorkEndDate, WorkEndTime, OutDate, OutTime, ChangeCnt, DiffApproachTime, InPlanDateTime, OutPlanDateTime, ShipPlanFinishSeq, FinishTypeName, FinishType, DockPJTName, DockPJTSeq, DockCustSeq, DockCustName) 
SELECT N'U', 1, 1, 0, 0, NULL, NULL, NULL, N'DataBlock1', NULL, NULL, NULL, N'�������ι�', N'��������', N'20171201003A', N'MV. MORNING MERIDIAN', N'��û�� ����..�׽�Ʈ', N'3', N'��û�� ����..�׽�Ʈ', NULL, NULL, NULL, NULL, NULL, NULL, N'64', NULL, N'MNMD-2007-001', N'1590', N'525', N'0', N'0', N'0', N'1', N'����', N'100', N'100', N'0', N'1', N'0', N'20070625', N'1348', N'20070625', N'1355', N'20171201', N'1111', N'20171201', N'1111', N'20171231', N'1730', N'0', N'92212', N'2007-06-25 13:40', N'2007-06-25 17:30', N'81', NULL, NULL, N'', N'0', N'0', N''
IF @@ERROR <> 0 RETURN


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

SET @ServiceSeq     = 13820029
--SET @MethodSeq      = 2
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820024
SET @IsTransaction  = 1
-- InputData�� OutputData�� ����INSERT INTO #BIZ_OUT_DataBlock1(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, IFShipCode, SerlYear, SerlNo, BizUnitName, CustName, PJTNo, EnShipName, ContractName, PJTTypeName, PJTName, FrWorkDate, ToWorkDate, FrContractDate, ToContractDate, BizUnit, CustSeq, ShipSeq, PJTTypeSeq, ShipSerlNo, ShipSerl, PJTSeq, PlanQty, PlanMTWeight, PlanCBMWeight, WorkDayCnt, UMWorkTypeName, ResultQty, ResultMTWeight, ResultCBMWeight, IsReportCfm, IsCfm, InDate, InTime, ApproachDate, ApproachTime, WorkSrtDate, WorkSrtTime, WorkEndDate, WorkEndTime, OutDate, OutTime, ChangeCnt, DiffApproachTime, InPlanDateTime, OutPlanDateTime, ShipPlanFinishSeq, FinishTypeName, FinishType, DockPJTName, DockPJTSeq, DockCustSeq, DockCustName)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, IFShipCode, SerlYear, SerlNo, BizUnitName, CustName, PJTNo, EnShipName, ContractName, PJTTypeName, PJTName, FrWorkDate, ToWorkDate, FrContractDate, ToContractDate, BizUnit, CustSeq, ShipSeq, PJTTypeSeq, ShipSerlNo, ShipSerl, PJTSeq, PlanQty, PlanMTWeight, PlanCBMWeight, WorkDayCnt, UMWorkTypeName, ResultQty, ResultMTWeight, ResultCBMWeight, IsReportCfm, IsCfm, InDate, InTime, ApproachDate, ApproachTime, WorkSrtDate, WorkSrtTime, WorkEndDate, WorkEndTime, OutDate, OutTime, ChangeCnt, DiffApproachTime, InPlanDateTime, OutPlanDateTime, ShipPlanFinishSeq, FinishTypeName, FinishType, DockPJTName, DockPJTSeq, DockCustSeq, DockCustName      FROM  #BIZ_IN_DataBlock1-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTShipWorkPlanFinishCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : End-- ExecuteOrder : 2 : StartSET @UseTransaction = N'1'BEGIN TRANEXEC    mnpt_SPJTShipWorkPlanFinishSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0)
BEGIN
    --ROLLBACK TRAN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 2 : End-- ExecuteOrder : 3 : StartEXEC    mnpt_SPJTShipWorkPlanContractCreate            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0)
BEGIN
    --ROLLBACK TRAN
    SET @HasError = N'1'
    GOTO GOTO_END
END
COMMIT TRANSET @UseTransaction = N'0'-- ExecuteOrder : 3 : EndGOTO_END:SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType
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
        , Result, ROW_IDX, IsChangedMst, IFShipCode, SerlYear, SerlNo, BizUnitName, CustName, PJTNo, EnShipName, ContractName, PJTTypeName, PJTName, FrWorkDate, ToWorkDate, FrContractDate, ToContractDate, BizUnit, CustSeq, ShipSeq, PJTTypeSeq, ShipSerlNo, ShipSerl, PJTSeq, PlanQty, PlanMTWeight, PlanCBMWeight, WorkDayCnt, UMWorkTypeName, ResultQty, ResultMTWeight, ResultCBMWeight, IsReportCfm, IsCfm, InDate, InTime, ApproachDate, ApproachTime, WorkSrtDate, WorkSrtTime, WorkEndDate, WorkEndTime, OutDate, OutTime, ChangeCnt, DiffApproachTime, InPlanDateTime, OutPlanDateTime, ShipPlanFinishSeq, FinishTypeName, FinishType, DockPJTName, DockPJTSeq, DockCustSeq, DockCustName  FROM #BIZ_OUT_DataBlock1 ORDER BY IDX_NO, ROW_IDX
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