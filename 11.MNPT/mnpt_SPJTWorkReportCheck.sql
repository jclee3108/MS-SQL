  
IF OBJECT_ID('mnpt_SPJTWorkReportCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkReportCheck  
GO  
    
-- v2018.02.05
  
-- �۾������Է�-SS1üũ by ����õ
CREATE PROC mnpt_SPJTWorkReportCheck      
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
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  

        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'mnpt_TPJTWorkReport', 'WorkReportSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #BIZ_OUT_DataBlock1  
           SET WorkReportSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- üũ1-1, ����ó���� �Ǿ� �ű�/����/������ �� �� �����ϴ�. 
    
    UPDATE A
       SET Result = '����ó���� �Ǿ� �ű�/����/������ �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234
      FROM #BIZ_OUT_DataBlock1  AS A 
      JOIN mnpt_TPJTWorkReport  AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
     WHERE A.Status = 0 
       AND B.IsCfm = '1'
    -- üũ1-1, END 


    -- üũ1-2, ����ó���� �Ǿ� �ű�/����/������ �� �� �����ϴ�. 
    
    UPDATE A
       SET Result = '����ó���� �Ǿ� �ű�/����/������ �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234
      FROM #BIZ_OUT_DataBlock1  AS A 
      JOIN mnpt_TPJTWorkReport  AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.SourceWorkReportSeq ) 
     WHERE A.Status = 0 
       AND B.IsCfm = '1'
       AND A.WorkingTag = 'A'
    -- üũ1-2, END 


    -- üũ2, �۾����ܽð��� �ùٸ��� �ʽ��ϴ�.
    DECLARE @EnvTime NCHAR(4) 

    SELECT @EnvTime = REPLACE(A.EnvValue,':','')
      FROM mnpt_TCOMEnv AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.EnvSeq = 5

    SELECT CASE WHEN B.ValueText < @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + B.ValueText AS SrtTime, 
           CASE WHEN C.ValueText <= @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + C.ValueText AS EndTime
      INTO #UMinorTime
      from _TDAUMinor AS A 
      LEFT OUTER JOIN _TDAUMinorValue AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1015905
    
    IF EXISTS (SELECT 1 from #UMinorTime WHERE SrtTime > EndTime ) 
    BEGIN 
        UPDATE #BIZ_OUT_DataBlock1   
           SET Result        = '�۾����ܽð��� �ùٸ��� �ʽ��ϴ�.',      
               MessageType   = 1234,      
               Status        = 1234      
          FROM #BIZ_OUT_DataBlock1  
         WHERE Status = 0  
           AND WorkingTag IN ( 'A', 'U' ) 
    END 
    -- üũ2, End

    -- üũ3, �۾��ð��� �ùٸ��� �ʽ��ϴ�.
    UPDATE A
       SET Result        = '�۾��ð��� �ùٸ��� �ʽ��ϴ�.',      
           MessageType   = 1234,      
           Status        = 1234      
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND A.WorkSrtTime <> '' 
       AND A.WorkEndTime <> ''
       AND CASE WHEN REPLACE(A.WorkSrtTime,':','') < @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + REPLACE(A.WorkSrtTime,':','') > 
           CASE WHEN REPLACE(A.WorkEndTime,':','') <= @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + REPLACE(A.WorkEndTime,':','')
    -- üũ3, End

    -- üũ4, �̹� �۾������� ������ ������ �����մϴ�.
    UPDATE A
       SET Result        = '�̹� �۾������� ������ ������ �����մϴ�.',      
           MessageType   = 1234,      
           Status        = 1234      
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
       AND EXISTS (SELECT 1 FROM mnpt_TPJTWorkReport WHERE CompanySeq = @CompanySeq AND WorkPlanSeq = A.WorkPlanSeq)
       AND ISNULL(A.SourceWorkReportSeq,0) = 0 
    -- üũ4, End


    --üũ5, ������Ʈ ����ÿ��� Mapping������ Ȯ���Ͻñ� �ٶ��ϴ�.
    UPDATE A
       SET Result        = '������Ʈ ����ÿ��� Mapping������ Ȯ���Ͻñ� �ٶ��ϴ�.', 
           MessageType   = 1234,      
           Status        = 1234      
      FROM #BIZ_OUT_DataBlock1      AS A 
      JOIN mnpt_TPJTWorkReport      AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
     WHERE NOT EXISTS (SELECT 1 
                         FROM mnpt_TPJTProjectMapping AS Z 
                        WHERE Z.CompanySeq = @CompanySeq 
                          AND Z.PJTSeq = A.PJTSeq 
                          AND Z.UMWorkType = B.UMWorkType
                      )
    -- üũ5, End

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
       AND ( WorkReportSeq = 0 OR WorkReportSeq IS NULL )  
    
    RETURN  
 go
 
 begin tran 
 DECLARE   @CONST_#BIZ_IN_DataBlock1 INT        , @CONST_#BIZ_IN_DataBlock2 INT        , @CONST_#BIZ_OUT_DataBlock1 INT        , @CONST_#BIZ_OUT_DataBlock2 INTSELECT    @CONST_#BIZ_IN_DataBlock1 = 0        , @CONST_#BIZ_IN_DataBlock2 = 0        , @CONST_#BIZ_OUT_DataBlock1 = 0        , @CONST_#BIZ_OUT_DataBlock2 = 0
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

        , PJTName NVARCHAR(200), PJTSeq INT, PJTTypeName NVARCHAR(200), CustName NVARCHAR(200), UMCustKindName NVARCHAR(200), AGCustName NVARCHAR(200), IFShipCode NVARCHAR(100), ShipSeq INT, ShipSerlNo NVARCHAR(100), ShipSerl INT, LOA DECIMAL(19, 5), UMWorkDivision NVARCHAR(200), UMWorkTypeName NVARCHAR(200), UMWorkType INT, GoodsQty DECIMAL(19, 5), GoodsMTWeight DECIMAL(19, 5), GoodsCBMWeight DECIMAL(19, 5), SumQty DECIMAL(19, 5), SumMTWeight DECIMAL(19, 5), SumCBMWeight DECIMAL(19, 5), TodayQty DECIMAL(19, 5), TodayMTWeight DECIMAL(19, 5), TodayCBMWeight DECIMAL(19, 5), EtcQty DECIMAL(19, 5), EtcMTWeight DECIMAL(19, 5), EtcCBMWeight DECIMAL(19, 5), MultiExtraName NVARCHAR(500), WorkSrtTime NVARCHAR(10), WorkEndTime NVARCHAR(10), RealWorkTime DECIMAL(19, 5), EmpName NVARCHAR(200), EmpSeq INT, UMBisWorkTypeCnt INT, BizUnitName NVARCHAR(200), PJTNo NVARCHAR(200), AgentName NVARCHAR(200), DRemark NVARCHAR(2000), WorkReportSeq INT, ExtraGroupSeq NVARCHAR(500), WorkDate NVARCHAR(100), UMWeatherName NVARCHAR(100), UMWeather NVARCHAR(100), MRemark NVARCHAR(2000), IsCfm NVARCHAR(100), Confirm NVARCHAR(100), NightQty DECIMAL(19, 5), NightMTWeight DECIMAL(19, 5), NightCBMWeight DECIMAL(19, 5), EnShipName NVARCHAR(200), WorkPlanSeq INT, UMWorkTeamName NVARCHAR(200), UMWorkTeam INT, ManRemark NVARCHAR(2000), UMLoadType INT, UMLoadTypeName NVARCHAR(100), SourceWorkReportSeq INT
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

        , PJTName NVARCHAR(200), PJTSeq INT, PJTTypeName NVARCHAR(200), CustName NVARCHAR(200), UMCustKindName NVARCHAR(200), AGCustName NVARCHAR(200), IFShipCode NVARCHAR(100), ShipSeq INT, ShipSerlNo NVARCHAR(100), ShipSerl INT, LOA DECIMAL(19, 5), UMWorkDivision NVARCHAR(200), UMWorkTypeName NVARCHAR(200), UMWorkType INT, GoodsQty DECIMAL(19, 5), GoodsMTWeight DECIMAL(19, 5), GoodsCBMWeight DECIMAL(19, 5), SumQty DECIMAL(19, 5), SumMTWeight DECIMAL(19, 5), SumCBMWeight DECIMAL(19, 5), TodayQty DECIMAL(19, 5), TodayMTWeight DECIMAL(19, 5), TodayCBMWeight DECIMAL(19, 5), EtcQty DECIMAL(19, 5), EtcMTWeight DECIMAL(19, 5), EtcCBMWeight DECIMAL(19, 5), MultiExtraName NVARCHAR(500), WorkSrtTime NVARCHAR(10), WorkEndTime NVARCHAR(10), RealWorkTime DECIMAL(19, 5), EmpName NVARCHAR(200), EmpSeq INT, UMBisWorkTypeCnt INT, BizUnitName NVARCHAR(200), PJTNo NVARCHAR(200), AgentName NVARCHAR(200), DRemark NVARCHAR(2000), WorkReportSeq INT, ExtraGroupSeq NVARCHAR(500), WorkDate NVARCHAR(100), UMWeatherName NVARCHAR(100), UMWeather NVARCHAR(100), MRemark NVARCHAR(2000), IsCfm NVARCHAR(100), Confirm NVARCHAR(100), NightQty DECIMAL(19, 5), NightMTWeight DECIMAL(19, 5), NightCBMWeight DECIMAL(19, 5), EnShipName NVARCHAR(200), WorkPlanSeq INT, UMWorkTeamName NVARCHAR(200), UMWorkTeam INT, ManRemark NVARCHAR(2000), IsCfmDetail CHAR(1), UMLoadType INT, UMLoadTypeName NVARCHAR(100), SourceWorkReportSeq INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END

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

        , UMBisWorkTypeName NVARCHAR(200), UMBisWorkType INT, SelfToolName NVARCHAR(200), SelfToolSeq INT, RentToolName NVARCHAR(200), RentToolSeq INT, ToolWorkTime DECIMAL(19, 5), DriverEmpName1 NVARCHAR(200), DriverEmpSeq1 INT, DriverEmpName2 NVARCHAR(200), DriverEmpSeq2 INT, DriverEmpName3 NVARCHAR(200), DriverEmpSeq3 INT, DUnionDay DECIMAL(19, 5), DUnionHalf DECIMAL(19, 5), DUnionMonth DECIMAL(19, 5), DDailyDay DECIMAL(19, 5), DDailyHalf DECIMAL(19, 5), DDailyMonth DECIMAL(19, 5), DOSDay DECIMAL(19, 5), DOSHalf DECIMAL(19, 5), DOSMonth DECIMAL(19, 5), DEtcDay DECIMAL(19, 5), DEtcHalf DECIMAL(19, 5), DEtcMonth DECIMAL(19, 5), NDEmpName NVARCHAR(200), NDEmpSeq INT, NDUnionUnloadGang DECIMAL(19, 5), NDUnionUnloadMan DECIMAL(19, 5), NDUnionDailyDay DECIMAL(19, 5), NDUnionDailyHalf DECIMAL(19, 5), NDUnionDailyMonth DECIMAL(19, 5), NDUnionSignalDay DECIMAL(19, 5), NDUnionSignalHalf DECIMAL(19, 5), NDUnionSignalMonth DECIMAL(19, 5), NDUnionEtcDay DECIMAL(19, 5), NDUnionEtcHalf DECIMAL(19, 5), NDUnionEtcMonth DECIMAL(19, 5), NDDailyDay DECIMAL(19, 5), NDDailyHalf DECIMAL(19, 5), NDDailyMonth DECIMAL(19, 5), NDOSDay DECIMAL(19, 5), NDOSHalf DECIMAL(19, 5), NDOSMonth DECIMAL(19, 5), NDEtcDay DECIMAL(19, 5), NDEtcHalf DECIMAL(19, 5), NDEtcMonth DECIMAL(19, 5), DRemark NVARCHAR(2000), WorkReportSeq INT, WorkReportSerl INT, IsMain CHAR(1), WorkPlanSeq NVARCHAR(100), WorkPlanSerl NVARCHAR(100), SubWorkPlanSeq INT, IsCfmDetail CHAR(1), WorkDate CHAR(8), DDailyEmpSeq INT, NDDailyEmpSeq INT, DDailyEmpName NVARCHAR(100), NDDailyEmpName NVARCHAR(100)
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

        , UMBisWorkTypeName NVARCHAR(200), UMBisWorkType INT, SelfToolName NVARCHAR(200), SelfToolSeq INT, RentToolName NVARCHAR(200), RentToolSeq INT, ToolWorkTime DECIMAL(19, 5), DriverEmpName1 NVARCHAR(200), DriverEmpSeq1 INT, DriverEmpName2 NVARCHAR(200), DriverEmpSeq2 INT, DriverEmpName3 NVARCHAR(200), DriverEmpSeq3 INT, DUnionDay DECIMAL(19, 5), DUnionHalf DECIMAL(19, 5), DUnionMonth DECIMAL(19, 5), DDailyDay DECIMAL(19, 5), DDailyHalf DECIMAL(19, 5), DDailyMonth DECIMAL(19, 5), DOSDay DECIMAL(19, 5), DOSHalf DECIMAL(19, 5), DOSMonth DECIMAL(19, 5), DEtcDay DECIMAL(19, 5), DEtcHalf DECIMAL(19, 5), DEtcMonth DECIMAL(19, 5), NDEmpName NVARCHAR(200), NDEmpSeq INT, NDUnionUnloadGang DECIMAL(19, 5), NDUnionUnloadMan DECIMAL(19, 5), NDUnionDailyDay DECIMAL(19, 5), NDUnionDailyHalf DECIMAL(19, 5), NDUnionDailyMonth DECIMAL(19, 5), NDUnionSignalDay DECIMAL(19, 5), NDUnionSignalHalf DECIMAL(19, 5), NDUnionSignalMonth DECIMAL(19, 5), NDUnionEtcDay DECIMAL(19, 5), NDUnionEtcHalf DECIMAL(19, 5), NDUnionEtcMonth DECIMAL(19, 5), NDDailyDay DECIMAL(19, 5), NDDailyHalf DECIMAL(19, 5), NDDailyMonth DECIMAL(19, 5), NDOSDay DECIMAL(19, 5), NDOSHalf DECIMAL(19, 5), NDOSMonth DECIMAL(19, 5), NDEtcDay DECIMAL(19, 5), NDEtcHalf DECIMAL(19, 5), NDEtcMonth DECIMAL(19, 5), DRemark NVARCHAR(2000), WorkReportSeq INT, WorkReportSerl INT, IsMain CHAR(1), WorkPlanSeq NVARCHAR(100), WorkPlanSerl NVARCHAR(100), SubWorkPlanSeq INT, IsCfmDetail CHAR(1), WorkDate CHAR(8), DDailyEmpSeq INT, NDDailyEmpSeq INT, DDailyEmpName NVARCHAR(100), NDDailyEmpName NVARCHAR(100)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock2 = 1

END
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, PJTName, PJTSeq, PJTTypeName, CustName, UMCustKindName, AGCustName, IFShipCode, ShipSeq, ShipSerlNo, ShipSerl, LOA, UMWorkDivision, UMWorkTypeName, UMWorkType, GoodsQty, GoodsMTWeight, GoodsCBMWeight, SumQty, SumMTWeight, SumCBMWeight, TodayQty, TodayMTWeight, TodayCBMWeight, EtcQty, EtcMTWeight, EtcCBMWeight, MultiExtraName, WorkSrtTime, WorkEndTime, RealWorkTime, EmpName, EmpSeq, UMBisWorkTypeCnt, BizUnitName, PJTNo, AgentName, DRemark, WorkReportSeq, ExtraGroupSeq, WorkDate, UMWeatherName, UMWeather, MRemark, IsCfm, Confirm, NightQty, NightMTWeight, NightCBMWeight, EnShipName, WorkPlanSeq, UMWorkTeamName, UMWorkTeam, ManRemark, UMLoadType, UMLoadTypeName, SourceWorkReportSeq) 
SELECT N'U', 3, 1, 0, 0, NULL, NULL, NULL, N'DataBlock1', N'TEST_PJT', N'386', N'���񿬼Һз�2�׽�Ʈ', N'��귡�̾���', N'��������ŷ�ó,���԰ŷ�ó(�ܱ����),�����ްŷ�ó', N'', NULL, N'64', N'MNMD-2007-001', N'1590', N'199', N'�����۾�', N'����', N'1015816001', N'0', N'0', N'0', N'0', N'0', N'0', N'100', N'100', N'100', N'-100', N'-100', N'-100', N'��õ(��õ),���', N'1111', N'1111', N'0', N'', N'0', N'0', N'��ǰ����ι�(���ں�ǰ)', N'20171003028A', N'', N'', N'517', N'1015782003,1015782001', N'20171202', NULL, N'', N'', N'0', NULL, NULL, NULL, NULL, N'MV. MORNING MERIDIAN', N'354', N'�ְ�', N'6017001', N'', N'1015935001', N'LOLO(���׳�ƽ)', N'0'



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
--SET @MethodSeq      = 2
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820019
SET @IsTransaction  = 1
-- InputData�� OutputData�� ����INSERT INTO #BIZ_OUT_DataBlock1(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, PJTName, PJTSeq, PJTTypeName, CustName, UMCustKindName, AGCustName, IFShipCode, ShipSeq, ShipSerlNo, ShipSerl, LOA, UMWorkDivision, UMWorkTypeName, UMWorkType, GoodsQty, GoodsMTWeight, GoodsCBMWeight, SumQty, SumMTWeight, SumCBMWeight, TodayQty, TodayMTWeight, TodayCBMWeight, EtcQty, EtcMTWeight, EtcCBMWeight, MultiExtraName, WorkSrtTime, WorkEndTime, RealWorkTime, EmpName, EmpSeq, UMBisWorkTypeCnt, BizUnitName, PJTNo, AgentName, DRemark, WorkReportSeq, ExtraGroupSeq, WorkDate, UMWeatherName, UMWeather, MRemark, IsCfm, Confirm, NightQty, NightMTWeight, NightCBMWeight, EnShipName, WorkPlanSeq, UMWorkTeamName, UMWorkTeam, ManRemark, UMLoadType, UMLoadTypeName, SourceWorkReportSeq)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, PJTName, PJTSeq, PJTTypeName, CustName, UMCustKindName, AGCustName, IFShipCode, ShipSeq, ShipSerlNo, ShipSerl, LOA, UMWorkDivision, UMWorkTypeName, UMWorkType, GoodsQty, GoodsMTWeight, GoodsCBMWeight, SumQty, SumMTWeight, SumCBMWeight, TodayQty, TodayMTWeight, TodayCBMWeight, EtcQty, EtcMTWeight, EtcCBMWeight, MultiExtraName, WorkSrtTime, WorkEndTime, RealWorkTime, EmpName, EmpSeq, UMBisWorkTypeCnt, BizUnitName, PJTNo, AgentName, DRemark, WorkReportSeq, ExtraGroupSeq, WorkDate, UMWeatherName, UMWeather, MRemark, IsCfm, Confirm, NightQty, NightMTWeight, NightCBMWeight, EnShipName, WorkPlanSeq, UMWorkTeamName, UMWorkTeam, ManRemark, UMLoadType, UMLoadTypeName, SourceWorkReportSeq      FROM  #BIZ_IN_DataBlock1-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTWorkReportCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : End-- ExecuteOrder : 2 : StartSET @UseTransaction = N'1'BEGIN TRANEXEC    mnpt_SPJTWorkReportSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0)
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
        , Result, ROW_IDX, IsChangedMst, PJTName, PJTSeq, PJTTypeName, CustName, UMCustKindName, AGCustName, IFShipCode, ShipSeq, ShipSerlNo, ShipSerl, LOA, UMWorkDivision, UMWorkTypeName, UMWorkType, GoodsQty, GoodsMTWeight, GoodsCBMWeight, SumQty, SumMTWeight, SumCBMWeight, TodayQty, TodayMTWeight, TodayCBMWeight, EtcQty, EtcMTWeight, EtcCBMWeight, MultiExtraName, WorkSrtTime, WorkEndTime, RealWorkTime, EmpName, EmpSeq, UMBisWorkTypeCnt, BizUnitName, PJTNo, AgentName, DRemark, WorkReportSeq, ExtraGroupSeq, WorkDate, UMWeatherName, UMWeather, MRemark, IsCfm, Confirm, NightQty, NightMTWeight, NightCBMWeight, EnShipName, WorkPlanSeq, UMWorkTeamName, UMWorkTeam, ManRemark, UMLoadType, UMLoadTypeName, SourceWorkReportSeq  FROM #BIZ_OUT_DataBlock1 ORDER BY IDX_NO, ROW_IDX
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1DROP TABLE #BIZ_IN_DataBlock2DROP TABLE #BIZ_OUT_DataBlock2rollback 