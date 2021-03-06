if object_id('mnpt_TPJTWorkReportItem') is null
begin 
    CREATE TABLE mnpt_TPJTWorkReportItem
    (
        CompanySeq		INT 	 NOT NULL, 
        WorkReportSeq		INT 	 NOT NULL, 
        WorkReportSerl		INT 	 NOT NULL, 
        UMBisWorkType		INT 	 NOT NULL, 
        SelfToolSeq		INT 	 NULL, 
        RentToolSeq		INT 	 NULL, 
        ToolWorkTime		DECIMAL(19,5) 	 NULL, 
        DriverEmpSeq1		INT 	 NULL, 
        DriverEmpSeq2		INT 	 NULL, 
        DriverEmpSeq3		INT 	 NULL, 
        DUnionDay		DECIMAL(19,5) 	 NULL, 
        DUnionHalf		DECIMAL(19,5) 	 NULL, 
        DUnionMonth		DECIMAL(19,5) 	 NULL, 
        DDailyEmpSeq    INT NULL, 
        DDailyDay		DECIMAL(19,5) 	 NULL, 
        DDailyHalf		DECIMAL(19,5) 	 NULL, 
        DDailyMonth		DECIMAL(19,5) 	 NULL, 
        DOSDay		DECIMAL(19,5) 	 NULL, 
        DOSHalf		DECIMAL(19,5) 	 NULL, 
        DOSMonth		DECIMAL(19,5) 	 NULL, 
        DEtcDay		DECIMAL(19,5) 	 NULL, 
        DEtcHalf		DECIMAL(19,5) 	 NULL, 
        DEtcMonth		DECIMAL(19,5) 	 NULL, 
        NDEmpSeq		INT 	 NULL, 
        NDUnionUnloadGang		DECIMAL(19,5) 	 NULL, 
        NDUnionUnloadMan		DECIMAL(19,5) 	 NULL, 
        NDUnionDailyDay		DECIMAL(19,5) 	 NULL, 
        NDUnionDailyHalf		DECIMAL(19,5) 	 NULL, 
        NDUnionDailyMonth		DECIMAL(19,5) 	 NULL, 
        NDUnionSignalDay		DECIMAL(19,5) 	 NULL, 
        NDUnionSignalHalf		DECIMAL(19,5) 	 NULL, 
        NDUnionSignalMonth		DECIMAL(19,5) 	 NULL, 
        NDUnionEtcDay		DECIMAL(19,5) 	 NULL, 
        NDUnionEtcHalf		DECIMAL(19,5) 	 NULL, 
        NDUnionEtcMonth		DECIMAL(19,5) 	 NULL, 
        NDDailyEmpSeq    INT NULL, 
        NDDailyDay		DECIMAL(19,5) 	 NULL, 
        NDDailyHalf		DECIMAL(19,5) 	 NULL, 
        NDDailyMonth		DECIMAL(19,5) 	 NULL, 
        NDOSDay		DECIMAL(19,5) 	 NULL, 
        NDOSHalf		DECIMAL(19,5) 	 NULL, 
        NDOSMonth		DECIMAL(19,5) 	 NULL, 
        NDEtcDay		DECIMAL(19,5) 	 NULL, 
        NDEtcHalf		DECIMAL(19,5) 	 NULL, 
        NDEtcMonth		DECIMAL(19,5) 	 NULL, 
        DRemark		NVARCHAR(2000) 	 NULL, 
        IsCfm       NCHAR(1)    NULL, 
        WorkPlanSeq		INT 	 NULL, 
        WorkPlanSerl		INT 	 NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTWorkReportItem PRIMARY KEY CLUSTERED (CompanySeq ASC, WorkReportSeq ASC, WorkReportSerl ASC)

    )
end 


if object_id('mnpt_TPJTWorkReportItemLog') is null
begin 
    CREATE TABLE mnpt_TPJTWorkReportItemLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        WorkReportSeq		INT 	 NOT NULL, 
        WorkReportSerl		INT 	 NOT NULL, 
        UMBisWorkType		INT 	 NOT NULL, 
        SelfToolSeq		INT 	 NULL, 
        RentToolSeq		INT 	 NULL, 
        ToolWorkTime		DECIMAL(19,5) 	 NULL, 
        DriverEmpSeq1		INT 	 NULL, 
        DriverEmpSeq2		INT 	 NULL, 
        DriverEmpSeq3		INT 	 NULL, 
        DUnionDay		DECIMAL(19,5) 	 NULL, 
        DUnionHalf		DECIMAL(19,5) 	 NULL, 
        DUnionMonth		DECIMAL(19,5) 	 NULL, 
        DDailyEmpSeq    INT NULL, 
        DDailyDay		DECIMAL(19,5) 	 NULL, 
        DDailyHalf		DECIMAL(19,5) 	 NULL, 
        DDailyMonth		DECIMAL(19,5) 	 NULL, 
        DOSDay		DECIMAL(19,5) 	 NULL, 
        DOSHalf		DECIMAL(19,5) 	 NULL, 
        DOSMonth		DECIMAL(19,5) 	 NULL, 
        DEtcDay		DECIMAL(19,5) 	 NULL, 
        DEtcHalf		DECIMAL(19,5) 	 NULL, 
        DEtcMonth		DECIMAL(19,5) 	 NULL, 
        NDEmpSeq		INT 	 NULL, 
        NDUnionUnloadGang		DECIMAL(19,5) 	 NULL, 
        NDUnionUnloadMan		DECIMAL(19,5) 	 NULL, 
        NDUnionDailyDay		DECIMAL(19,5) 	 NULL, 
        NDUnionDailyHalf		DECIMAL(19,5) 	 NULL, 
        NDUnionDailyMonth		DECIMAL(19,5) 	 NULL, 
        NDUnionSignalDay		DECIMAL(19,5) 	 NULL, 
        NDUnionSignalHalf		DECIMAL(19,5) 	 NULL, 
        NDUnionSignalMonth		DECIMAL(19,5) 	 NULL, 
        NDUnionEtcDay		DECIMAL(19,5) 	 NULL, 
        NDUnionEtcHalf		DECIMAL(19,5) 	 NULL, 
        NDUnionEtcMonth		DECIMAL(19,5) 	 NULL, 
        NDDailyEmpSeq    INT NULL, 
        NDDailyDay		DECIMAL(19,5) 	 NULL, 
        NDDailyHalf		DECIMAL(19,5) 	 NULL, 
        NDDailyMonth		DECIMAL(19,5) 	 NULL, 
        NDOSDay		DECIMAL(19,5) 	 NULL, 
        NDOSHalf		DECIMAL(19,5) 	 NULL, 
        NDOSMonth		DECIMAL(19,5) 	 NULL, 
        NDEtcDay		DECIMAL(19,5) 	 NULL, 
        NDEtcHalf		DECIMAL(19,5) 	 NULL, 
        NDEtcMonth		DECIMAL(19,5) 	 NULL, 
        DRemark		NVARCHAR(2000) 	 NULL, 
        IsCfm       NCHAR(1)    NULL, 
        WorkPlanSeq		INT 	 NULL, 
        WorkPlanSerl		INT 	 NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTWorkReportItemLog ON mnpt_TPJTWorkReportItemLog (LogSeq)
end 

