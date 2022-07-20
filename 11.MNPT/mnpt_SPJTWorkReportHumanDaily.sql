     
IF OBJECT_ID('mnpt_SPJTWorkReportHumanDaily') IS NOT NULL       
    DROP PROC mnpt_SPJTWorkReportHumanDaily      
GO      
      
-- v2017.09.26 
      
-- �۾������Է�-������Ʈ�����Է�(�����ڿ�-���ں�)���� by ����õ  
CREATE PROC mnpt_SPJTWorkReportHumanDaily      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    DECLARE @WorkDate       NCHAR(8) 
      
    SELECT @WorkDate = ISNULL( WorkDate, '' )  
      FROM #BIZ_IN_DataBlock1    
    
    DELETE A
      FROM _TPJTResultHumanRes AS A 
     WHERE CompanySeq = @CompanySeq 
       AND WorkStartDate = @WorkDate 
       AND SMInPutKind = 7021004
    
    
    -- �۾������� �ο����ϱ�
    SELECT Z.WorkReportSeq, SUM(EmpCnt) AS EmpCnt 
      INTO #EmpCnt
      FROM ( 
            -- ����
            SELECT A.WorkReportSeq, CASE WHEN A.EmpSeq = 0 THEN 0 ELSE 1 END AS EmpCnt 
              FROM mnpt_TPJTWorkReport      AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.WorkDate = @WorkDate 
            UNION ALL 
            -- ������ ���1
            SELECT A.WorkReportSeq, CASE WHEN B.DriverEmpSeq1 = 0 THEN 0 ELSE 1 END AS EmpCnt 
              FROM mnpt_TPJTWorkReport      AS A 
              JOIN mnpt_TPJTWorkReportItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.WorkDate = @WorkDate 
            UNION ALL 
            -- �������� ���
            SELECT A.WorkReportSeq, CASE WHEN B.NDEmpSeq = 0 THEN 0 ELSE 1 END AS EmpCnt   
              FROM mnpt_TPJTWorkReport      AS A 
              JOIN mnpt_TPJTWorkReportItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.WorkDate = @WorkDate 
           ) AS Z 
     GROUP BY Z.WorkReportSeq 
    
    
    -- <�۾�>�۾����� �Է¿� �����ڿ�
    DECLARE @ResrcSeq INT 
    
    SELECT @ResrcSeq = EnvValue
      FROM mnpt_TCOMEnv 
     WHERE CompanySeq = @CompanySeq 
       AND EnvSeq = 16 
    
    -- ��Ű���� �� �� ���ϱ� 
    SELECT ROW_NUMBER() OVER(PARTITION BY A.PJTSeq ORDER BY A.PJTSeq) AS PJT_IDX_NO, -- ���� ������Ʈ�ϱ� ���� ä�� 
           0 AS HumanResSerl, 
           A.PJTSeq, -- ������Ʈ�ڵ�
           @ResrcSeq AS ResrcSeq, -- Site ȯ�漳���� (<�۾�>�۾����� �Է¿� �����ڿ�) 
           A.WorkDate,  -- �۾��� 
           ISNULL(A.RealWorkTime,0) * ISNULL(B.EmpCnt,0) AS ManHour, -- ���� ��� ( ���۾��ð� * �ο� ) 
           1 AS ProcCnt, 
           ResultStdUnitSeq AS ProcUnitSeq 
      INTO #TPJTResultHumanRes
      FROM mnpt_TPJTWorkReport          AS A 
                 JOIN #EmpCnt           AS B ON ( B.WorkReportSeq = A.WorkReportSeq ) 
      LEFT OUTER JOIN _TPJTProjectDesc  AS D ON ( D.CompanySeq = @CompanySeq AND D.PJTSeq = A.PJTSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND ISNULL(A.RealWorkTime,0) * ISNULL(B.EmpCnt,0) > 0 
    
    -- ������Ʈ�� Max���� ���ϱ� (��Ű��Table) 
    SELECT A.PJTSeq, MAX(HumanResSerl) AS MaxHumanResSerl
      INTO #MaxHumanResSerl
      FROM _TPJTResultHumanRes AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #TPJTResultHumanRes WHERE PJTSeq = A.PJTSeq) 
     GROUP BY A.PJTSeq 
    
    UPDATE A
       SET HumanResSerl = ISNULL(B.MaxHumanResSerl,0) + A.PJT_IDX_NO
      FROM #TPJTResultHumanRes          AS A 
      LEFT OUTER JOIN #MaxHumanResSerl  AS B ON ( B.PJTSeq = A.PJTSeq ) 
    

    INSERT INTO _TPJTResultHumanRes
    (
        CompanySeq, PJTSeq, HumanResSerl, WBSSeq, ResrcSeq, 
        WorkStartDate, WorkEndDate, WorkTime, StartTime, EndTime, 
        ProcCnt, ManHour, ActivitySeq, ActivityQty, UMLossType, 
        ProdQty, WorkDesc, ExpenseCustSeq, ApprManHour, ApprDate, 
        ApprEmpSeq, ApprRemark, LastUserSeq, LastDateTime, SMInputKind, 
        SupplyDelvSeq, SupplyDelvSerl, SupplyDelvItemSerl, UMWorkType, DayWorkTime, 
        NightWorkTime, OverWorkTime, SetupTime, WaitTime, MoveTime, 
        SourceSeq, SourceSerl, SourceNo, IsAppr, ProcUnitSeq, 
        Remark, WorkTimeGroup
    )
    SELECT @CompanySeq, PJTSeq, HumanResSerl, 0, ResrcSeq, 
           WorkDate, WorkDate, 0, '', '', 
           ProcCnt, ManHour, 0, 0, 0, 
           0, '', 0, 0, '', 
           0, '', @UserSEq, GETDATE(), 7021004, 
           NULL, NULL, NULL, 0, 0, 
           0, 0, NULL, NULL, NULL, 
           NULL, NULL, NULL, NULL, ProcUnitSeq, 
           NULL, NULL
      FROM #TPJTResultHumanRes 

    
    RETURN     
Go

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

        , WorkDate NVARCHAR(100)
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

        , PJTName NVARCHAR(200), PJTSeq INT, PJTTypeName NVARCHAR(200), CustName NVARCHAR(200), UMCustKindName NVARCHAR(200), AGCustName NVARCHAR(200), IFShipCode NVARCHAR(100), ShipSeq INT, ShipSerlNo NVARCHAR(100), ShipSerl INT, LOA DECIMAL(19, 5), UMWorkDivision NVARCHAR(200), UMWorkTypeName NVARCHAR(200), UMWorkType INT, GoodsQty DECIMAL(19, 5), GoodsMTWeight DECIMAL(19, 5), GoodsCBMWeight DECIMAL(19, 5), SumQty DECIMAL(19, 5), SumMTWeight DECIMAL(19, 5), SumCBMWeight DECIMAL(19, 5), TodayQty DECIMAL(19, 5), TodayMTWeight DECIMAL(19, 5), TodayCBMWeight DECIMAL(19, 5), EtcQty DECIMAL(19, 5), EtcMTWeight DECIMAL(19, 5), EtcCBMWeight DECIMAL(19, 5), MultiExtraName NVARCHAR(500), WorkSrtTime NVARCHAR(10), WorkEndTime NVARCHAR(10), RealWorkTime DECIMAL(19, 5), EmpName NVARCHAR(200), EmpSeq INT, UMBisWorkTypeCnt INT, BizUnitName NVARCHAR(200), PJTNo NVARCHAR(200), AgentName NVARCHAR(200), DRemark NVARCHAR(2000), WorkReportSeq INT, ExtraGroupSeq NVARCHAR(500), WorkDate NVARCHAR(100), UMWeatherName NVARCHAR(100), UMWeather NVARCHAR(100), MRemark NVARCHAR(100), IsCfm NVARCHAR(100), Confirm NVARCHAR(100), NightQty DECIMAL(19, 5), NightMTWeight DECIMAL(19, 5), NightCBMWeight DECIMAL(19, 5), EnShipName NVARCHAR(200), WorkPlanSeq INT, UMWorkTeamName NVARCHAR(200), UMWorkTeam INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, WorkDate) 
SELECT N'U', 1, 1, 1, 0, NULL, NULL, N'0', N'', N'20170926'
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

SET @ServiceSeq     = 13820024
--SET @MethodSeq      = 9
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820019
SET @IsTransaction  = 0
-- InputData�� OutputData�� ����INSERT INTO #BIZ_OUT_DataBlock1(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, WorkDate)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, WorkDate      FROM  #BIZ_IN_DataBlock1-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTWorkReportHumanDaily            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
        , Result, ROW_IDX, IsChangedMst, WorkDate  FROM #BIZ_OUT_DataBlock1 ORDER BY IDX_NO, ROW_IDX
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1rollback 