  
IF OBJECT_ID('mnpt_SPJTEERentToolCalcSlipCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTEERentToolCalcSlipCheck  
GO  
    
-- v2017.11.29
  
-- ȭ���-üũ by �ۼ���   
CREATE PROC mnpt_SPJTEERentToolCalcSlipCheck  
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
    
    ---------------------------------------------------------------
    -- üũ1, ���� �� ��ǥó���� �����մϴ�.
    ---------------------------------------------------------------
    UPDATE A
        SET Result = '���� �� ��ǥó���� �����մϴ�.', 
            Status = 1234, 
            MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND A.CalcSeq = 0 
    ---------------------------------------------------------------
    -- üũ1, End
    ---------------------------------------------------------------

    ---------------------------------------------------------------
    -- üũ2, �ٸ� ������ü�� ���õǾ����ϴ�.
    ---------------------------------------------------------------
    IF EXISTS ( 
                SELECT 1 
                  FROM (
                        SELECT 1 AS Cnt
                          FROM #BIZ_OUT_DataBlock1       AS A 
                          JOIN mnpt_TPJTEERentToolCalc   AS B ON ( B.CompanySeq = @CompanySeq AND B.CalcSeq = A.CalcSeq ) 
                         WHERE A.Status = 0 
                         GROUP BY B.RentCustSeq 
                       ) AS Z 
                 HAVING SUM(Z.Cnt) > 1 
               ) 
    BEGIN 
        UPDATE #BIZ_OUT_DataBlock1
           SET Result = '�ٸ� ������ü�� ���õǾ����ϴ�.', 
               Status = 1234, 
               MessageType = 1234 
    END 
    ---------------------------------------------------------------
    -- üũ2, End
    ---------------------------------------------------------------
      
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

        , CalcSeq INT
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

        , StdYM CHAR(6), BizUnitName NVARCHAR(200), BizUnit INT, Sel CHAR(1), AccUnitName NVARCHAR(200), RentCustName NVARCHAR(200), UMRentTypeName NVARCHAR(200), UMRentKindName NVARCHAR(200), RentToolName NVARCHAR(200), WorkDate CHAR(8), AccUnit INT, RentCustSeq INT, UMRentType INT, UMRentKind INT, RentToolSeq INT, Qty DECIMAL(19, 5), Price DECIMAL(19, 5), Amt DECIMAL(19, 5), AddListName NVARCHAR(200), AddQty DECIMAL(19, 5), AddPrice DECIMAL(19, 5), AddAmt DECIMAL(19, 5), RentAmt DECIMAL(19, 5), RentVAT DECIMAL(19, 5), TotalAmt DECIMAL(19, 5), Remark NVARCHAR(2000), PJTNames NVARCHAR(200), RentSrtDate CHAR(8), RentEndDate CHAR(8), WorkDateCnt INT, NightCnt INT, HolidayCnt INT, AccName NVARCHAR(100), VATAccName NVARCHAR(200), OppAccName NVARCHAR(200), CCtrName NVARCHAR(200), UMCostTypeName NVARCHAR(200), IsCalc CHAR(1), SlipID NVARCHAR(100), IsSlip CHAR(1), AccSeq INT, VATAccSeq INT, OppAccSeq INT, CCtrSeq INT, UMCostType INT, SlipSeq INT, CalcSeq INT, WorkDateSub CHAR(8)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, CalcSeq) 
SELECT N'', 3, 1, 0, 0, NULL, NULL, NULL, N'DataBlock1', N'60' UNION ALL 
SELECT N'', 5, 2, 0, 0, NULL, NULL, NULL, NULL, N'0'
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

SET @ServiceSeq     = 13820052
--SET @MethodSeq      = 3
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820060
SET @IsTransaction  = 0
-- InputData�� OutputData�� ����INSERT INTO #BIZ_OUT_DataBlock1(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, CalcSeq)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, CalcSeq      FROM  #BIZ_IN_DataBlock1-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTEERentToolCalcSlipCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0 
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : EndGOTO_END:SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType
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
        , Result, ROW_IDX, IsChangedMst, CalcSeq  FROM #BIZ_OUT_DataBlock1 ORDER BY IDX_NO, ROW_IDX
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