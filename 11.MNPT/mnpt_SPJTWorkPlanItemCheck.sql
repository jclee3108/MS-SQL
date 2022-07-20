  
IF OBJECT_ID('mnpt_SPJTWorkPlanItemCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkPlanItemCheck  
GO  
    
-- v2017.09.25
  
-- �۾������Է�-SS2üũ by ����õ
CREATE PROC mnpt_SPJTWorkPlanItemCheck      
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
            @Results        NVARCHAR(250), 
            @MaxSerl        INT 
    
    
    ------------------------------------------------------------------
    -- Serl ä�� 
    ------------------------------------------------------------------
    SELECT @MaxSerl = MAX(A.WorkPlanSerl) 
      FROM mnpt_TPJTWorkPlanItem AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock2 WHERE WorkPlanSeq = A.WorkPlanSeq) 
    
    UPDATE A 
       SET WorkPlanSerl = ISNULL(@MaxSerl,0) + A.DataSeq
      FROM #BIZ_OUT_DataBlock2 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
    
    ------------------------------------------------------------------
    -- üũ1, ����ó���� �Ǿ� �ű�/����/������ �� �� �����ϴ�. 
    ------------------------------------------------------------------
    UPDATE A
       SET Result = '����ó���� �Ǿ� �ű�/����/������ �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234
      FROM #BIZ_OUT_DataBlock2 AS A 
      JOIN mnpt_TPJTWorkPlan   AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkPlanSeq = A.WorkPlanSeq ) 
     WHERE A.Status = 0 
       AND B.IsCfm = '1' 
    ------------------------------------------------------------------
    -- üũ1, END 
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- üũ2, �۾��������� ������ ������ ����/������ �� �� �����ϴ�.
    ------------------------------------------------------------------
    UPDATE A
       SET Result        = '�۾��������� ������ ������ ����/������ �� �� �����ϴ�.',  
           MessageType   = 1234,      
           Status        = 1234      
      FROM #BIZ_OUT_DataBlock2 AS A 
     WHERE A.WorkingTag IN ( 'U', 'D' ) 
       AND A.Status = 0 
       AND EXISTS (SELECT 1 FROM mnpt_TPJTWorkReportItem WHERE CompanySeq = @CompanySeq AND WorkPlanSeq = A.WorkPlanSeq AND WorkPlanSerl = A.WorkPlanSerl) 
    ------------------------------------------------------------------
    -- üũ2, END 
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- üũ3, �ڰ����� �������� �����Ͽ� �����Ͻñ� �ٶ��ϴ�.
    ------------------------------------------------------------------
    UPDATE A
       SET Result        = '�ڰ����� �������� �����Ͽ� �����Ͻñ� �ٶ��ϴ�.',  
           MessageType   = 1234,      
           Status        = 1234      
      FROM #BIZ_OUT_DataBlock2 AS A 
     WHERE A.WorkingTag IN ( 'A', 'U' ) 
       AND A.Status = 0 
       AND A.SelfToolSeq <> 0 AND A.RentToolSeq <> 0 
    ------------------------------------------------------------------
    -- üũ3, END 
    ------------------------------------------------------------------

    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #BIZ_OUT_DataBlock2   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #BIZ_OUT_DataBlock2  
     WHERE Status = 0  
       AND ( WorkPlanSeq = 0 OR WorkPlanSeq IS NULL )  
        OR ( WorkPlanSerl = 0 OR WorkPlanSerl IS NULL ) 
    
    RETURN  
  
go
begin tran 
DECLARE   @CONST_#BIZ_IN_DataBlock2 INT        , @CONST_#BIZ_OUT_DataBlock2 INTSELECT    @CONST_#BIZ_IN_DataBlock2 = 0        , @CONST_#BIZ_OUT_DataBlock2 = 0
IF @CONST_#BIZ_IN_DataBlock2 = 0
BEGIN
    CREATE TABLE #BIZ_IN_DataBlock2
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

        , UMBisWorkTypeName NVARCHAR(200), UMBisWorkType INT, SelfToolName NVARCHAR(200), SelfToolSeq INT, RentToolName NVARCHAR(200), RentToolSeq INT, ToolWorkTime DECIMAL(19, 5), DriverEmpName1 NVARCHAR(200), DriverEmpSeq1 INT, DriverEmpName2 NVARCHAR(200), DriverEmpSeq2 INT, DriverEmpName3 NVARCHAR(200), DriverEmpSeq3 INT, DUnionDay DECIMAL(19, 5), DUnionHalf DECIMAL(19, 5), DUnionMonth DECIMAL(19, 5), DDailyDay DECIMAL(19, 5), DDailyHalf DECIMAL(19, 5), DDailyMonth DECIMAL(19, 5), DOSDay DECIMAL(19, 5), DOSHalf DECIMAL(19, 5), DOSMonth DECIMAL(19, 5), DEtcDay DECIMAL(19, 5), DEtcHalf DECIMAL(19, 5), DEtcMonth DECIMAL(19, 5), NDEmpName NVARCHAR(200), NDEmpSeq INT, NDUnionUnloadGang DECIMAL(19, 5), NDUnionUnloadMan DECIMAL(19, 5), NDUnionDailyDay DECIMAL(19, 5), NDUnionDailyHalf DECIMAL(19, 5), NDUnionDailyMonth DECIMAL(19, 5), NDUnionSignalDay DECIMAL(19, 5), NDUnionSignalHalf DECIMAL(19, 5), NDUnionSignalMonth DECIMAL(19, 5), NDUnionEtcDay DECIMAL(19, 5), NDUnionEtcHalf DECIMAL(19, 5), NDUnionEtcMonth DECIMAL(19, 5), NDDailyDay DECIMAL(19, 5), NDDailyHalf DECIMAL(19, 5), NDDailyMonth DECIMAL(19, 5), NDOSDay DECIMAL(19, 5), NDOSHalf DECIMAL(19, 5), NDOSMonth DECIMAL(19, 5), NDEtcDay DECIMAL(19, 5), NDEtcHalf DECIMAL(19, 5), NDEtcMonth DECIMAL(19, 5), DRemark NVARCHAR(2000), WorkPlanSeq INT, WorkPlanSerl INT
    )
    
    SET @CONST_#BIZ_IN_DataBlock2 = 1

END

IF @CONST_#BIZ_OUT_DataBlock2 = 0
BEGIN
    CREATE TABLE #BIZ_OUT_DataBlock2
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

        , UMBisWorkTypeName NVARCHAR(200), UMBisWorkType INT, SelfToolName NVARCHAR(200), SelfToolSeq INT, RentToolName NVARCHAR(200), RentToolSeq INT, ToolWorkTime DECIMAL(19, 5), DriverEmpName1 NVARCHAR(200), DriverEmpSeq1 INT, DriverEmpName2 NVARCHAR(200), DriverEmpSeq2 INT, DriverEmpName3 NVARCHAR(200), DriverEmpSeq3 INT, DUnionDay DECIMAL(19, 5), DUnionHalf DECIMAL(19, 5), DUnionMonth DECIMAL(19, 5), DDailyDay DECIMAL(19, 5), DDailyHalf DECIMAL(19, 5), DDailyMonth DECIMAL(19, 5), DOSDay DECIMAL(19, 5), DOSHalf DECIMAL(19, 5), DOSMonth DECIMAL(19, 5), DEtcDay DECIMAL(19, 5), DEtcHalf DECIMAL(19, 5), DEtcMonth DECIMAL(19, 5), NDEmpName NVARCHAR(200), NDEmpSeq INT, NDUnionUnloadGang DECIMAL(19, 5), NDUnionUnloadMan DECIMAL(19, 5), NDUnionDailyDay DECIMAL(19, 5), NDUnionDailyHalf DECIMAL(19, 5), NDUnionDailyMonth DECIMAL(19, 5), NDUnionSignalDay DECIMAL(19, 5), NDUnionSignalHalf DECIMAL(19, 5), NDUnionSignalMonth DECIMAL(19, 5), NDUnionEtcDay DECIMAL(19, 5), NDUnionEtcHalf DECIMAL(19, 5), NDUnionEtcMonth DECIMAL(19, 5), NDDailyDay DECIMAL(19, 5), NDDailyHalf DECIMAL(19, 5), NDDailyMonth DECIMAL(19, 5), NDOSDay DECIMAL(19, 5), NDOSHalf DECIMAL(19, 5), NDOSMonth DECIMAL(19, 5), NDEtcDay DECIMAL(19, 5), NDEtcHalf DECIMAL(19, 5), NDEtcMonth DECIMAL(19, 5), DRemark NVARCHAR(2000), WorkPlanSeq INT, WorkPlanSerl INT, IsMain CHAR(1)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock2 = 1

END


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

SET @ServiceSeq     = 13820013
--SET @MethodSeq      = 4
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820008
SET @IsTransaction  = 1
-- InputData�� OutputData�� ����INSERT INTO #BIZ_OUT_DataBlock2(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, UMBisWorkTypeName, UMBisWorkType, SelfToolName, SelfToolSeq, RentToolName, RentToolSeq, ToolWorkTime, DriverEmpName1, DriverEmpSeq1, DriverEmpName2, DriverEmpSeq2, DriverEmpName3, DriverEmpSeq3, DUnionDay, DUnionHalf, DUnionMonth, DDailyDay, DDailyHalf, DDailyMonth, DOSDay, DOSHalf, DOSMonth, DEtcDay, DEtcHalf, DEtcMonth, NDEmpName, NDEmpSeq, NDUnionUnloadGang, NDUnionUnloadMan, NDUnionDailyDay, NDUnionDailyHalf, NDUnionDailyMonth, NDUnionSignalDay, NDUnionSignalHalf, NDUnionSignalMonth, NDUnionEtcDay, NDUnionEtcHalf, NDUnionEtcMonth, NDDailyDay, NDDailyHalf, NDDailyMonth, NDOSDay, NDOSHalf, NDOSMonth, NDEtcDay, NDEtcHalf, NDEtcMonth, DRemark, WorkPlanSeq, WorkPlanSerl)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, UMBisWorkTypeName, UMBisWorkType, SelfToolName, SelfToolSeq, RentToolName, RentToolSeq, ToolWorkTime, DriverEmpName1, DriverEmpSeq1, DriverEmpName2, DriverEmpSeq2, DriverEmpName3, DriverEmpSeq3, DUnionDay, DUnionHalf, DUnionMonth, DDailyDay, DDailyHalf, DDailyMonth, DOSDay, DOSHalf, DOSMonth, DEtcDay, DEtcHalf, DEtcMonth, NDEmpName, NDEmpSeq, NDUnionUnloadGang, NDUnionUnloadMan, NDUnionDailyDay, NDUnionDailyHalf, NDUnionDailyMonth, NDUnionSignalDay, NDUnionSignalHalf, NDUnionSignalMonth, NDUnionEtcDay, NDUnionEtcHalf, NDUnionEtcMonth, NDDailyDay, NDDailyHalf, NDDailyMonth, NDOSDay, NDOSHalf, NDOSMonth, NDEtcDay, NDEtcHalf, NDEtcMonth, DRemark, WorkPlanSeq, WorkPlanSerl      FROM  #BIZ_IN_DataBlock2-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTWorkPlanItemCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0 
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : End-- ExecuteOrder : 2 : StartSET @UseTransaction = N'1'BEGIN TRANEXEC    mnpt_SPJTWorkPlanItemSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0 
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
        , Result, ROW_IDX, IsChangedMst, UMBisWorkTypeName, UMBisWorkType, SelfToolName, SelfToolSeq, RentToolName, RentToolSeq, ToolWorkTime, DriverEmpName1, DriverEmpSeq1, DriverEmpName2, DriverEmpSeq2, DriverEmpName3, DriverEmpSeq3, DUnionDay, DUnionHalf, DUnionMonth, DDailyDay, DDailyHalf, DDailyMonth, DOSDay, DOSHalf, DOSMonth, DEtcDay, DEtcHalf, DEtcMonth, NDEmpName, NDEmpSeq, NDUnionUnloadGang, NDUnionUnloadMan, NDUnionDailyDay, NDUnionDailyHalf, NDUnionDailyMonth, NDUnionSignalDay, NDUnionSignalHalf, NDUnionSignalMonth, NDUnionEtcDay, NDUnionEtcHalf, NDUnionEtcMonth, NDDailyDay, NDDailyHalf, NDDailyMonth, NDOSDay, NDOSHalf, NDOSMonth, NDEtcDay, NDEtcHalf, NDEtcMonth, DRemark, WorkPlanSeq, WorkPlanSerl  FROM #BIZ_OUT_DataBlock2 ORDER BY IDX_NO, ROW_IDX
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
DROP TABLE #BIZ_IN_DataBlock2DROP TABLE #BIZ_OUT_DataBlock2rollback 