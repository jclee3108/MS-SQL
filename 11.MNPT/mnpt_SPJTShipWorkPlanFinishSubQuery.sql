     
IF OBJECT_ID('mnpt_SPJTShipWorkPlanFinishSubQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTShipWorkPlanFinishSubQuery      
GO      
      
-- v2017.10.11
  
-- �����۾���ȹ�Ϸ��Է�-Sub��ȸ by ����õ
CREATE PROC mnpt_SPJTShipWorkPlanFinishSubQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @ShipSeq        INT, 
            @ShipSerl       INT, 
            @PJTSeq         INT 
    
    SELECT @ShipSeq     = ISNULL( ShipSeq, 0 ),   
           @ShipSerl    = ISNULL( ShipSerl, 0 ), 
           @PJTSeq      = ISNULL( PJTSeq, 0 ) 
      FROM #BIZ_IN_DataBlock1    
    

    --------------------------------------------------
    -- ���������ڵ带 �������и�Ī���� �ٲ��ֱ�, Srt
    --------------------------------------------------
    CREATE TABLE #ExtraSeq
    (
        IDX_NO          INT IDENTITY, 
        WorkReportSeq     INT, 
        ExtraGroupSeq   NVARCHAR(500)
    )
    
    INSERT INTO #ExtraSeq ( WorkReportSeq, ExtraGroupSeq ) 
    SELECT WorkReportSeq, '<XmlString><Code>' + REPLACE(ExtraGroupSeq,',','</Code><Code>') + '</Code></XmlString>'
      FROM mnpt_TPJTWorkReport 
     WHERE CompanySeq = @CompanySeq 
       AND ShipSeq = @ShipSeq 
       AND ShipSerl = @ShipSerl 
       AND PJTSeq = @PJTSeq 
    
    
    CREATE TABLE #CheckExtraSeq 
    (
        WorkReportSeq     INT, 
        UMExtraType     INT, 
        UMExtraTypeName NVARCHAR(200)
    )
    CREATE TABLE #GroupExtraName
    (
        WorkReportSeq     INT, 
        MultiExtraName  NVARCHAR(500)
    )
    
    DECLARE @Cnt            INT, 
            @ExtraGroupSeq  NVARCHAR(500), 
            @WorkReportSeq    INT, 
            @ExtraGroupName NVARCHAR(500)

    SELECT @Cnt = 1 

    WHILE ( 1 = 1 ) 
    BEGIN 
        
        SELECT @ExtraGroupSeq = ExtraGroupSeq, 
               @WorkReportSeq   = WorkReportSeq
          FROM #ExtraSeq 
         WHERE IDX_NO = @Cnt 
        

        TRUNCATE TABLE #CheckExtraSeq 

        INSERT INTO #CheckExtraSeq ( WorkReportSeq, UMExtraType, UMExtraTypeName ) 
        SELECT @WorkReportSeq, Code, B.MinorName
          FROM _FCOMXmlToSeq(0, @ExtraGroupSeq) AS A 
          JOIN _TDAUMinor     AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.Code ) 
        

        SELECT @ExtraGroupName = '' 

        SELECT @ExtraGroupName = @ExtraGroupName + ',' + UMExtraTypeName
          FROM #CheckExtraSeq 
        
        INSERT INTO #GroupExtraName ( WorkReportSeq, MultiExtraName ) 
        SELECT @WorkReportSeq, STUFF(@ExtraGroupName,1,1,'')


        IF @Cnt >= ISNULL((SELECT MAX(IDX_NO) FROM #ExtraSeq),0) 
        BEGIN
            BREAK 
        END 
        ELSE
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 
    END 
    --------------------------------------------------
    -- ���������ڵ带 �������и�Ī���� �ٲ��ֱ�, End  
    --------------------------------------------------
        
    SELECT A.WorkDate,                                  -- �۾���
           DATENAME (WeekDay, A.WorkDate) AS WorkDay,   -- ���� 
           B.DayTypeName AS UMHoliDayTypeName,          -- ���ޱ��� 
           C.MinorName AS UMWeatherName,                -- ���� 
           A.UMWorkType,                                -- �۾��׸��ڵ�
           D.MinorName AS UMWorkTypeName,               -- �۾��׸� 
           A.UMWorkTeam,                                -- �־��ڵ�
           E.MinorName AS UMWorkTeamName,               -- �־� 
           A.TodayQty,                                  -- ���� 
           A.TodayMTWeight,                             -- MT�۾���
           A.TodayCBMWeight,                            -- CBM�۾���
           F.MultiExtraName AS MultiExtraName, 
           A.WorkSrtTime,
           A.WorkEndTime, 
           A.RealWorkTime,
           A.DRemark, 
           CASE WHEN K.UMWorkType IS NULL THEN '0' ELSE '1' END AS IsInvoice, 


           H.EnShipName AS SubEnShipName, 
           G.IFShipCode + '-' + LEFT(G.ShipSerlNo,4) + '-' + RIGHT(G.ShipSerlNo,3) AS SubShipSerlNo, 
           I.PJTName AS SubPJTName, 
           J.PJTTypeName AS SubPJTTypeName
      FROM mnpt_TPJTWorkReport AS A 
      LEFT OUTER JOIN ( 
                        SELECT Z.Solar,
                               MAX(X.DayTypeName) AS DayTypeName
                          FROM _TCOMCalendarHolidayPRWkUnit AS Z 
                          LEFT OUTER JOIN _TDAUMinorValue   AS Y ON ( Y.CompanySeq  = @CompanySeq
                                                                  AND Y.ValueSeq    = Z.DayTypeSeq
                                                                  AND Y.MajorSeq    = 1015916
                                                                  AND Y.Serl        = 1000001 
                                                                    )
                          LEFT OUTER JOIN _TPRWkDayType     AS X ON ( X.CompanySeq = @CompanySeq AND X.DayTypeSeq = Y.ValueSeq ) 
	                     WHERE Z.CompanySeq = @CompanySeq
	                     GROUP BY Z.Solar 
                       ) AS B ON ( B.Solar = A.WorkDate ) 
      LEFT OUTER JOIN _TDAUMinor            AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMWeather ) 
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = UMWorkType ) 
      LEFT OUTER JOIN _TDAUMinor            AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = UMWorkTeam ) 
      LEFT OUTER JOIN #GroupExtraName       AS F ON ( F.WorkReportSeq = A.WorkReportSeq ) 
      LEFT OUTER JOIN mnpt_TPJTShipDetail   AS G ON ( G.CompanySeq = @CompanySeq AND G.ShipSeq = A.ShipSeq AND G.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN mnpt_TPJTShipMaster   AS H ON ( H.CompanySeq = @CompanySeq AND H.ShipSeq = A.ShipSeq ) 
      LEFT OUTER JOIN _TPJTProject          AS I ON ( I.CompanySeq = @CompanySeq AND I.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN _TPJTType             AS J ON ( J.CompanySeq = @CompanySeq AND J.PJTTypeSeq = I.PJTTypeSeq ) 
      OUTER APPLY (
                    SELECT DISTINCT Z.UMWorkType
                      FROM mnpt_TPJTProjectMapping AS Z
                     WHERE Z.CompanySeq = @CompanySeq
                       AND Z.IsAmt = '1' 
                       AND Z.PJTSeq = A.PJTSeq 
                       AND Z.UMWorkType = A.UMWorkType 
                  ) AS K 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ShipSeq = @ShipSeq 
       AND A.ShipSerl = @ShipSerl 
       AND A.PJTSeq = @PJTSeq 
    
    RETURN     
GO 