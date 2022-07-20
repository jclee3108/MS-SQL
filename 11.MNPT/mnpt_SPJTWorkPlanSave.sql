  
IF OBJECT_ID('mnpt_SPJTWorkPlanSave') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkPlanSave  
GO  
    
-- v2017.09.13
  
-- �۾���ȹ�Է�-SS1���� by ����õ
CREATE PROC mnpt_SPJTWorkPlanSave
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       

    --------------------------------------------------
    -- ���������ڵ忡�� ����,���� ������ֱ�
    --------------------------------------------------
    -- ���, �Ͽ�(����), ���ޱ���
    SELECT CASE WHEN DATENAME(WEEKDAY, A.WorkDate) = '�����' THEN B.MinorSeq ELSE C.MinorSeq END AS UMExtraSeq
        INTO #StaHoliDay
        FROM #BIZ_OUT_DataBlock1 AS A 
        LEFT OUTER JOIN (
                        SELECT MAX(MinorSeq) AS MinorSeq
                            FROM _TDAUMinorValue AS Z
                            WHERE Z.CompanySeq = @CompanySeq
                            AND Z.MajorSeq = 1015782
                            AND Z.Serl = 1000001 
                            AND Z.ValueText = '1' 
                        ) AS B ON ( 1 = 1 ) 
        LEFT OUTER JOIN (
                        SELECT MAX(MinorSeq) AS MinorSeq
                            FROM _TDAUMinorValue AS Z
                            WHERE Z.CompanySeq = @CompanySeq
                            AND Z.MajorSeq = 1015782
                            AND Z.Serl = 1000002 
                            AND Z.ValueText = '1' 
                        ) AS C ON ( 1 = 1 ) 
        WHERE A.WorkingTag IN ( 'U', 'A' ) 
        AND A.Status = 0 
        AND DATENAME(WEEKDAY, A.WorkDate) IN ( '�����', '�Ͽ���' ) 
    UNION ALL 
    -- ���ޱ���
    SELECT C.MinorSeq AS UMExtraSeq 
        FROM #BIZ_OUT_DataBlock1 AS A 
        LEFT OUTER JOIN (
		    	        SELECT Z.Solar
		    		        FROM _TCOMCalendarHolidayPRWkUnit AS Z
		    			    LEFT OUTER JOIN _TDAUMinorValue   AS Y ON Z.CompanySeq = @CompanySeq
		    					                                AND Y.ValueSeq = Z.DayTypeSeq
		    					                                AND Y.MajorSeq = 1015916
		    					                                AND Y.Serl = 1000001 
		    		        WHERE Z.CompanySeq	= @CompanySeq 
                                AND Y.CompanySeq IS NOT NULL 
		    		        GROUP BY Z.Solar
		    	        ) AS H ON ( H.Solar = A.WorkDate ) 
        LEFT OUTER JOIN (
                        SELECT MAX(MinorSeq) AS MinorSeq
                            FROM _TDAUMinorValue AS Z
                            WHERE Z.CompanySeq = @CompanySeq
                            AND Z.MajorSeq = 1015782
                            AND Z.Serl = 1000002 
                            AND Z.ValueText = '1' 
                        ) AS C ON ( 1 = 1 ) 
        WHERE A.WorkingTag IN ( 'U', 'A' ) 
        AND A.Status = 0 
        AND H.Solar IS NOT NULL 
        
    DECLARE @SatHoilUMExtraSeq NVARCHAR(100) 

    SELECT @SatHoilUMExtraSeq = MAX(UMExtraSeq)
        FROM #StaHoliDay 
        WHERE UMExtraSeq IS NOT NULL


    -- ���� ����, ��� ����� �ٽ� ������ֱ� 
    CREATE TABLE #ExtraSeq
    (
        IDX_NO          INT IDENTITY, 
        WorkPlanSeq     INT, 
        ExtraGroupSeq   NVARCHAR(500)
    )
    
    INSERT INTO #ExtraSeq ( WorkPlanSeq, ExtraGroupSeq ) 
    SELECT WorkPlanSeq, '<XmlString><Code>' + REPLACE(ExtraGroupSeq,',','</Code><Code>') + '</Code></XmlString>'
      FROM #BIZ_OUT_DataBlock1 
    
    CREATE TABLE #CheckExtraSeq 
    (
        WorkPlanSeq     INT, 
        UMExtraType     INT, 
        UMExtraTypeName NVARCHAR(200)
    )
    CREATE TABLE #GroupExtraName
    (
        WorkPlanSeq     INT, 
        MultiExtraName  NVARCHAR(500)
    )
    
    DECLARE @CntSub         INT, 
            @ExtraGroupSeq  NVARCHAR(500), 
            @WorkPlanSeq    INT, 
            @ExtraGroupName NVARCHAR(500)

    SELECT @CntSub = 1 

    WHILE ( 1 = 1 ) 
    BEGIN 
        
        SELECT @ExtraGroupSeq = ExtraGroupSeq, 
               @WorkPlanSeq   = WorkPlanSeq
          FROM #ExtraSeq 
         WHERE IDX_NO = @CntSub 
        

        TRUNCATE TABLE #CheckExtraSeq 

        INSERT INTO #CheckExtraSeq ( WorkPlanSeq, UMExtraType, UMExtraTypeName ) 
        SELECT @WorkPlanSeq, Code, B.MinorName
          FROM _FCOMXmlToSeq(0, @ExtraGroupSeq) AS A 
          JOIN _TDAUMinor     AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.Code ) 
        

        DELETE A 
          FROM #CheckExtraSeq AS A 
          JOIN ( 
                SELECT A.MinorSeq 
                  FROM _TDAUMinor                   AS A 
                  LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
                  LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
                 WHERE A.CompanySeq = @CompanySeq 
                   AND A.MajorSeq = 1015782
                   AND ( B.ValueText = '1' OR C.ValueText = '1' ) 
               ) AS B ON ( B.MInorSeq = A.UMExtraType ) 
        
        SELECT @ExtraGroupName = '' 

        SELECT @ExtraGroupName = @ExtraGroupName + ',' + CONVERT(NVARCHAR(100),UMExtraType)
          FROM #CheckExtraSeq 
        
        INSERT INTO #GroupExtraName ( WorkPlanSeq, MultiExtraName ) 
        SELECT @WorkPlanSeq, STUFF(@ExtraGroupName,1,1,'')


        IF @CntSub >= ISNULL((SELECT MAX(IDX_NO) FROM #ExtraSeq),0) 
        BEGIN
            BREAK 
        END 
        ELSE
        BEGIN
            SELECT @CntSub = @CntSub + 1 
        END 
    END 

    UPDATE A
       SET ExtraGroupSeq = B.MultiExtraName 
      FROM #BIZ_OUT_DataBlock1  AS A 
      JOIN #GroupExtraName      AS B ON ( B.WorkPlanSeq = A.WorkPlanSeq ) 
     WHERE A.WorkingTag IN ( 'A', 'U' ) 
       AND A.Status = 0 
    
    
    UPDATE A
        SET ExtraGroupSeq = CASE WHEN LEN(@SatHoilUMExtraSeq) = 10
                                THEN (CASE WHEN ISNULL(ExtraGroupSeq,'') = '' THEN @SatHoilUMExtraSeq ELSE ExtraGroupSeq + ',' + @SatHoilUMExtraSeq END)
                                ELSE ExtraGroupSeq
                                END 
               
        FROM #BIZ_OUT_DataBlock1 AS A 
        WHERE A.WorkingTag IN ( 'U', 'A' ) 
        AND A.Status = 0 
    --------------------------------------------------
    -- ���������ڵ忡�� ����,���� ������ֱ�, End  
    --------------------------------------------------


    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTWorkPlan')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTWorkPlan'    , -- ���̺��        
                  '#BIZ_OUT_DataBlock1'    , -- �ӽ� ���̺��        
                  'WorkPlanSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    --------------------------------------------------------------
    -- ���۾��ð����  
    --------------------------------------------------------------
    DECLARE @EnvTime NCHAR(4) 

    SELECT @EnvTime = REPLACE(A.EnvValue,':','')
      FROM mnpt_TCOMEnv AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.EnvSeq = 5
    


    create table #MainTime
    (
        WorkPlanSeq     INT, 
        WorkSrtTime     NCHAR(12), 
        WorkEndTime     NCHAR(12)
    )

    create table #ResultTime
    (
        WorkPlanSeq     INT, 
        WorkSrtTime     NCHAR(12), 
        WorkEndTime     NCHAR(12)
    )


    INSERT INTO #MainTime (WorkPlanSeq, WorkSrtTime, WorkEndTime)
    SELECT A.WorkPlanSeq, 
           CASE WHEN REPLACE(A.WorkSrtTime,':','') < @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + REPLACE(A.WorkSrtTime,':',''), 
           CASE WHEN REPLACE(A.WorkEndTime,':','') <= @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + REPLACE(A.WorkEndTime,':','')
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND A.WorkSrtTime <> '' 
       AND A.WorkEndTime <> ''
    
    SELECT ROW_NUMBER() OVER(Order BY A.MinorSeq) AS IDX_NO, 
           CASE WHEN B.ValueText < @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + B.ValueText AS SrtTime, 
           CASE WHEN C.ValueText <= @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + C.ValueText AS EndTime
      INTO #UMinorTime
      from _TDAUMinor AS A 
      LEFT OUTER JOIN _TDAUMinorValue AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1015905
    

    CREATE TABLE #WorkSrtTime
    (
        WorkPlanSeq     INT, 
        WorkSrtTime     NCHAR(12)
    )

    DECLARE @Cnt            INT

    SELECT @Cnt = 1 

    WHILE ( @Cnt <= ISNULL((SELECT MAX(IDX_NO) FROM #UMinorTime),0) + 1 ) 
    BEGIN 
        
        INSERT INTO #ResultTime 
        SELECT A.WorkPlanSeq, 
               
               CASE WHEN ISNULL(C.WorkSrtTime,A.WorkSrtTime) > CASE WHEN A.WorkEndTime > B.SrtTime THEN B.SrtTime ELSE A.WorkEndTime END OR C.WorkSrtTime = '' 
                    THEN '' 
                    ELSE ISNULL(C.WorkSrtTime,A.WorkSrtTime)
                    END, 
               
               CASE WHEN ISNULL(C.WorkSrtTime,A.WorkSrtTime) > CASE WHEN A.WorkEndTime > B.SrtTime THEN B.SrtTime ELSE A.WorkEndTime END 
                    THEN '' 
                    ELSE CASE WHEN A.WorkEndTime > B.SrtTime THEN B.SrtTime ELSE A.WorkEndTime END 
                    END

          FROM #MainTime                AS A 
          LEFT OUTER JOIN #UMinorTime   AS B ON ( B.IDX_NO = @Cnt ) 
          LEFT OUTER JOIN #WorkSrtTime  AS C ON ( C.WorkPlanSeq = A.WorkPlanSeq ) 
        
        TRUNCATE TABLE #WorkSrtTime 
        INSERT INTO #WorkSrtTime ( WorkPlanSeq, WorkSrtTime)
        SELECT A.WorkPlanSeq, 
               CASE WHEN A.WorkSrtTime > CASE WHEN A.WorkEndTime > B.SrtTime THEN B.EndTime ELSE A.WorkEndTime END 
                    THEN A.WorkSrtTime 
                    ELSE CASE WHEN A.WorkEndTime > B.SrtTime THEN B.EndTime ELSE A.WorkEndTime END 
                    END
          FROM #MainTime                AS A 
          LEFT OUTER JOIN #UMinorTime   AS B ON ( B.IDX_NO = @Cnt ) 
        
        SELECT @Cnt = @Cnt + 1 

    END 
    
    SELECT WorkPlanSeq, 
            SUM(
                CASE WHEN 
                        DATEDIFF( MI, 
                                    STUFF(STUFF(LEFT(WorkSrtTime,8),5,0,'-'),8,0,'-') + ' ' +  
                                    STUFF(RIGHT(WorkSrtTime,4),3,0,':') + ':00.000', 
                                    STUFF(STUFF(LEFT(WorkEndTime,8),5,0,'-'),8,0,'-') + ' ' +  
                                    STUFF(RIGHT(WorkEndTime,4),3,0,':') + ':00.000'
                                ) < 0 
                    THEN 0 
                    ELSE 
                        DATEDIFF( MI, 
                                    STUFF(STUFF(LEFT(WorkSrtTime,8),5,0,'-'),8,0,'-') + ' ' +  
                                    STUFF(RIGHT(WorkSrtTime,4),3,0,':') + ':00.000', 
                                    STUFF(STUFF(LEFT(WorkEndTime,8),5,0,'-'),8,0,'-') + ' ' +  
                                    STUFF(RIGHT(WorkEndTime,4),3,0,':') + ':00.000'
                                )
                    END 
                ) / 60. AS RealWorkTime 
        INTO #RealWorkTime
        FROM #ResultTime 
        WHERE WorkSrtTime <> '' 
        GROUP BY WorkPlanSeq 

    UPDATE A
       SET RealWorkTime = B.RealWorkTime
      FROM #BIZ_OUT_DataBlock1  AS A 
      JOIN #RealWorkTime        AS B ON ( B.WorkPlanSeq = A.WorkPlanSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND A.WorkSrtTime <> '' 
       AND A.WorkEndTime <> ''
    --------------------------------------------------------------
    -- ���۾��ð����, END 
    --------------------------------------------------------------

    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock1  AS A   
          JOIN mnpt_TPJTWorkPlan    AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkPlanSeq = B.WorkPlanSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN 
        

        --------------------------------------------------------------
        -- ������ ������ ������ �α׳����, Srt
        --------------------------------------------------------------
        SELECT A.WorkingTag, 
               A.Status, 
               A.WorkPlanSeq, 
               B.WorkPlanSerl
          INTO #ItemLog 
          FROM #BIZ_OUT_DataBlock1      AS A 
          JOIN mnpt_TPJTWorkPlanItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkPlanSeq = A.WorkPlanSeq )
         WHERE A.Status = 0 
           AND A.WorkingTag = 'D' 

        SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTWorkPlanItem')    
      
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'mnpt_TPJTWorkPlanItem'    , -- ���̺��        
                      '#ItemLog'    , -- �ӽ� ���̺��        
                      'WorkPlanSeq,WorkPlanSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                      @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
        --------------------------------------------------------------
        -- ������ ������ ������ �α׳����, End
        --------------------------------------------------------------
        
        DELETE B   
          FROM #BIZ_OUT_DataBlock1      AS A   
          JOIN mnpt_TPJTWorkPlanItem    AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkPlanSeq = B.WorkPlanSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.PJTSeq         = A.PJTSeq        ,  
               B.ShipSeq        = A.ShipSeq       ,  
               B.ShipSerl       = A.ShipSerl      ,  
               B.UMLoadType     = A.UMLoadType    , 
               B.UMWorkType     = A.UMWorkType    ,  
               B.TodayQty       = A.TodayQty      ,  
               B.TodayMTWeight  = A.TodayMTWeight ,  
               B.TodayCBMWeight  = A.TodayCBMWeight ,  
               B.UMWorkTeam     = A.UMWorkTeam      ,
               B.ExtraGroupSeq  = A.ExtraGroupSeq ,  
               B.WorkSrtTime    = A.WorkSrtTime   ,  
               B.WorkEndTime    = A.WorkEndTime   ,  
               B.RealWorkTime   = A.RealWorkTime  , 
               B.EmpSeq         = A.EmpSeq        ,  
               B.DRemark        = A.DRemark       ,  
               B.LastUserSeq    = @UserSeq        ,  
               B.LastDateTime   = GETDATE()       ,
               B.PgmSeq         = @PgmSeq
          FROM #BIZ_OUT_DataBlock1  AS A   
          JOIN mnpt_TPJTWorkPlan    AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkPlanSeq = B.WorkPlanSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
        UPDATE B   
           SET B.UMWeather      = A.UMWeather     ,  
               B.MRemark        = A.MRemark       , 
               B.ManRemark      = A.ManRemark
          FROM #BIZ_OUT_DataBlock1  AS A   
          JOIN mnpt_TPJTWorkPlan    AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkDate = B.WorkDate )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    

        INSERT INTO mnpt_TPJTWorkPlan  
        (   
            CompanySeq, WorkPlanSeq, WorkDate, UMWeather, MRemark, 
            ManRemark, IsCfm, PJTSeq, ShipSeq, ShipSerl, 
            UMWorkType, TodayQty, TodayMTWeight, TodayCBMWeight, UMWorkTeam, 
            ExtraGroupSeq, WorkSrtTime, WorkEndTime, RealWorkTime, EmpSeq, 
            DRemark, FirstUserSeq, FirstDateTime, LastUserSeq, LastDateTime, 
            PgmSeq, SourceWorkPlanSeq, UMLoadType
        )   
        SELECT @CompanySeq, WorkPlanSeq, WorkDate, UMWeather, MRemark, 
               ManRemark, '0', PJTSeq, ShipSeq, ShipSerl, 
               UMWorkType, TodayQty, TodayMTWeight, TodayCBMWeight, UMWorkTeam, 
               ExtraGroupSeq, REPLACE(WorkSrtTime,':',''), REPLACE(WorkEndTime,':',''), RealWorkTime, EmpSeq, 
               DRemark, @UserSeq, GETDATE(), @UserSeq, GETDATE(), 
               @PgmSeq, SourceWorkPlanSeq, UMLoadType
          FROM #BIZ_OUT_DataBlock1 AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    
    -- ó������ݿ� 
    UPDATE A
       SET UMWorkDivision = CASE WHEN A.ShipSeq = 0 OR A.ShipSeq IS NULL THEN (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015815002) 
                                 ELSE (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015815001) 
                                 END, -- �۾����� 
           
           SumQty = CASE WHEN A.ShipSerl = 0 THEN 0 ELSE ISNULL(KK.SumQty,0) END,           -- ���ϴ��� ����
           SumMTWeight = CASE WHEN A.ShipSerl = 0 THEN 0 ELSE ISNULL(KK.SumMTWeight,0) END, -- ���ϴ��� MT
           SumCBMWeight = CASE WHEN A.ShipSerl = 0 THEN 0 ELSE  ISNULL(KK.SumCBMWeight,0) END, -- ���ϴ��� CBM

           EtcQty = CASE WHEN A.ShipSerl = 0 THEN 0 ELSE ISNULL(A.GoodsQty,0) - (ISNULL(KK.SumQty,0) + ISNULL(W.TodayQty,0)) END, -- �ܿ�����
           EtcMTWeight = CASE WHEN A.ShipSerl = 0 THEN 0 ELSE ISNULL(A.GoodsMTWeight,0) - (ISNULL(KK.SumMTWeight,0) + ISNULL(W.TodayMTWeight,0)) END, -- �ܿ�MT
           EtcCBMWeight = CASE WHEN A.ShipSerl = 0 THEN 0 ELSE ISNULL(A.GoodsCBMWeight,0) - (ISNULL(KK.SumCBMWeight,0) + ISNULL(W.TodayCBMWeight,0)) END, -- �ܿ�CBM
           UMBisWorkTypeCnt = ISNULL(M.UMBisWorkTypeCnt,0) -- ��������Cnt
      FROM #BIZ_OUT_DataBlock1 AS A 
      OUTER APPLY ( -- ���� ����
                    SELECT PJTSeq, 
                           UMWorkType, 
                           SUM(TodayQty) AS SumQty, 
                           SUM(TodayMTWeight) AS SumMTWeight, 
                           SUM(TodayCBMWeight) AS SumCBMWeight
                      FROM mnpt_TPJTWorkPlan 
                     WHERE CompanySeq = @CompanySeq 
                       AND WorkDate < A.WorkDate  
                       AND PJTSeq = A.PJTSeq 
                       AND UMWorkType = A.UMWorkType
                    GROUP BY PJTSeq, UMWorkType 
                  ) AS K 
      LEFT OUTER JOIN (
                        SELECT Z.WorkPlanSeq, Count(1) AS UMBisWorkTypeCnt 
                          FROM mnpt_TPJTWorkPlanItem AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                         GROUP BY Z.WorkPlanSeq 
                      ) AS M ON ( M.WorkPlanSeq = A.WorkPlanSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS R ON ( R.CompanySeq = @CompanySeq AND R.MinorSeq = A.UMWorkType AND R.Serl = 1000001 ) 
      OUTER APPLY ( -- ���� ����
                        SELECT Z.PJTSeq, 
                               Z.ShipSeq, 
                               Z.ShipSerl, 
                               CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END AS UMWorkType, 
                               SUM(Z.TodayQty) AS SumQty, 
                               SUM(Z.TodayMTWeight) AS SumMTWeight, 
                               SUM(Z.TodayCBMWeight) AS SumCBMWeight
                          FROM mnpt_TPJTWorkPlan AS Z 
                          LEFT OUTER JOIN _TDAUMinorValue AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.UMWorkType AND Y.Serl = 1000001 ) 
                          LEFT OUTER JOIN _TDAUMinor      AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = Z.UMWorkType ) 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.WorkDate < A.WorkDate
                           AND Z.PJTSeq = A.PJTSeq
                           AND CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END = CASE WHEN ISNULL(R.ValueText,'0') = '1' THEN 999 ELSE A.UMWorkType END
                           AND Z.ShipSeq = A.ShipSeq
                           AND Z.ShipSerl = A.ShipSerl
                         GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END
                  ) AS KK
      OUTER APPLY ( -- ���� �۾�
                    SELECT Z.PJTSeq, 
                           Z.ShipSeq, 
                           Z.ShipSerl, 
                           CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END AS UMWorkType, 
                           SUM(Z.TodayQty) AS TodayQty, 
                           SUM(Z.TodayMTWeight) AS TodayMTWeight, 
                           SUM(Z.TodayCBMWeight) AS TodayCBMWeight
                      FROM mnpt_TPJTWorkPlan AS Z 
                      LEFT OUTER JOIN _TDAUMinorValue AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.UMWorkType AND Y.Serl = 1000001 ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.WorkDate = A.WorkDate 
                       AND Z.PJTSeq = A.PJTSeq 
                       AND CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END = CASE WHEN ISNULL(R.ValueText,'0') = '1' THEN 999 ELSE A.UMWorkType END
                       AND Z.ShipSeq = A.ShipSeq 
                       AND Z.ShipSerl = A.ShipSerl
                     GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END
                  ) AS W
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 



    RETURN  

go

--begin tran 
--DECLARE   @CONST_#BIZ_IN_DataBlock1 INT--        , @CONST_#BIZ_IN_DataBlock2 INT--        , @CONST_#BIZ_OUT_DataBlock1 INT--        , @CONST_#BIZ_OUT_DataBlock2 INT--SELECT    @CONST_#BIZ_IN_DataBlock1 = 0--        , @CONST_#BIZ_IN_DataBlock2 = 0--        , @CONST_#BIZ_OUT_DataBlock1 = 0--        , @CONST_#BIZ_OUT_DataBlock2 = 0
--IF @CONST_#BIZ_IN_DataBlock1 = 0
--BEGIN
--    CREATE TABLE #BIZ_IN_DataBlock1
--    (
--        WorkingTag      NCHAR(1)
--        , IDX_NO        INT
--        , DataSeq       INT
--        , Selected      INT
--        , MessageType   INT
--        , Status        INT
--        , Result        NVARCHAR(255)
--        , ROW_IDX       INT
--        , IsChangedMst  NCHAR(1)
--        , TABLE_NAME    NVARCHAR(255)

--        , PJTName NVARCHAR(200), PJTSeq INT, PJTTypeName NVARCHAR(200), CustName NVARCHAR(200), UMCustKindName NVARCHAR(200), AGCustName NVARCHAR(200), IFShipCode NVARCHAR(100), ShipSeq INT, ShipSerlNo NVARCHAR(100), ShipSerl INT, LOA DECIMAL(19, 5), UMWorkDivision NVARCHAR(200), UMWorkTypeName NVARCHAR(200), UMWorkType INT, GoodsQty DECIMAL(19, 5), GoodsMTWeight DECIMAL(19, 5), GoodsCBMWeight DECIMAL(19, 5), SumQty DECIMAL(19, 5), SumMTWeight DECIMAL(19, 5), SumCBMWeight DECIMAL(19, 5), TodayQty DECIMAL(19, 5), TodayMTWeight DECIMAL(19, 5), TodayCBMWeight DECIMAL(19, 5), EtcQty DECIMAL(19, 5), EtcMTWeight DECIMAL(19, 5), EtcCBMWeight DECIMAL(19, 5), MultiExtraName NVARCHAR(500), WorkSrtTime NVARCHAR(10), WorkEndTime NVARCHAR(10), RealWorkTime DECIMAL(19, 5), EmpName NVARCHAR(200), EmpSeq INT, UMBisWorkTypeCnt INT, BizUnitName NVARCHAR(200), PJTNo NVARCHAR(200), AgentName NVARCHAR(200), DRemark NVARCHAR(2000), WorkPlanSeq INT, ExtraGroupSeq NVARCHAR(500), WorkDate NVARCHAR(100), UMWeatherName NVARCHAR(100), UMWeather NVARCHAR(100), MRemark NVARCHAR(100), IsCfm NVARCHAR(100), Confirm NVARCHAR(100), NightQty DECIMAL(19, 5), NightMTWeight DECIMAL(19, 5), NightCBMWeight DECIMAL(19, 5), EnShipName NVARCHAR(200), SourceWorkPlanSeq INT, UMWorkTeamName NVARCHAR(200), UMWorkTeam INT
--    )
    
--    SET @CONST_#BIZ_IN_DataBlock1 = 1

--END

--IF @CONST_#BIZ_OUT_DataBlock1 = 0
--BEGIN
--    CREATE TABLE #BIZ_OUT_DataBlock1
--    (
--        WorkingTag      NCHAR(1)
--        , IDX_NO        INT
--        , DataSeq       INT
--        , Selected      INT
--        , MessageType   INT
--        , Status        INT
--        , Result        NVARCHAR(255)
--        , ROW_IDX       INT
--        , IsChangedMst  NCHAR(1)
--        , TABLE_NAME    NVARCHAR(255)

--        , PJTName NVARCHAR(200), PJTSeq INT, PJTTypeName NVARCHAR(200), CustName NVARCHAR(200), UMCustKindName NVARCHAR(200), AGCustName NVARCHAR(200), IFShipCode NVARCHAR(100), ShipSeq INT, ShipSerlNo NVARCHAR(100), ShipSerl INT, LOA DECIMAL(19, 5), UMWorkDivision NVARCHAR(200), UMWorkTypeName NVARCHAR(200), UMWorkType INT, GoodsQty DECIMAL(19, 5), GoodsMTWeight DECIMAL(19, 5), GoodsCBMWeight DECIMAL(19, 5), SumQty DECIMAL(19, 5), SumMTWeight DECIMAL(19, 5), SumCBMWeight DECIMAL(19, 5), TodayQty DECIMAL(19, 5), TodayMTWeight DECIMAL(19, 5), TodayCBMWeight DECIMAL(19, 5), EtcQty DECIMAL(19, 5), EtcMTWeight DECIMAL(19, 5), EtcCBMWeight DECIMAL(19, 5), MultiExtraName NVARCHAR(500), WorkSrtTime NVARCHAR(10), WorkEndTime NVARCHAR(10), RealWorkTime DECIMAL(19, 5), EmpName NVARCHAR(200), EmpSeq INT, UMBisWorkTypeCnt INT, BizUnitName NVARCHAR(200), PJTNo NVARCHAR(200), AgentName NVARCHAR(200), DRemark NVARCHAR(2000), WorkPlanSeq INT, ExtraGroupSeq NVARCHAR(500), WorkDate NVARCHAR(100), UMWeatherName NVARCHAR(100), UMWeather NVARCHAR(100), MRemark NVARCHAR(100), IsCfm NVARCHAR(100), Confirm NVARCHAR(100), NightQty DECIMAL(19, 5), NightMTWeight DECIMAL(19, 5), NightCBMWeight DECIMAL(19, 5), EnShipName NVARCHAR(200), SourceWorkPlanSeq INT, UMWorkTeamName NVARCHAR(200), UMWorkTeam INT
--    )
    
--    SET @CONST_#BIZ_OUT_DataBlock1 = 1

--END

--IF @CONST_#BIZ_IN_DataBlock2 = 0
--BEGIN
--    CREATE TABLE #BIZ_IN_DataBlock2
--    (
--        WorkingTag      NCHAR(1)
--        , IDX_NO        INT
--        , DataSeq       INT
--        , Selected      INT
--        , MessageType   INT
--        , Status        INT
--        , Result        NVARCHAR(255)
--        , ROW_IDX       INT
--        , IsChangedMst  NCHAR(1)
--        , TABLE_NAME    NVARCHAR(255)

--        , UMBisWorkTypeName NVARCHAR(200), UMBisWorkType INT, SelfToolName NVARCHAR(200), SelfToolSeq INT, RentToolName NVARCHAR(200), RentToolSeq INT, ToolWorkTime DECIMAL(19, 5), DriverEmpName1 NVARCHAR(200), DriverEmpSeq1 INT, DriverEmpName2 NVARCHAR(200), DriverEmpSeq2 INT, DriverEmpName3 NVARCHAR(200), DriverEmpSeq3 INT, DUnionDay DECIMAL(19, 5), DUnionHalf DECIMAL(19, 5), DUnionMonth DECIMAL(19, 5), DDailyDay DECIMAL(19, 5), DDailyHalf DECIMAL(19, 5), DDailyMonth DECIMAL(19, 5), DOSDay DECIMAL(19, 5), DOSHalf DECIMAL(19, 5), DOSMonth DECIMAL(19, 5), DEtcDay DECIMAL(19, 5), DEtcHalf DECIMAL(19, 5), DEtcMonth DECIMAL(19, 5), NDEmpName NVARCHAR(200), NDEmpSeq INT, NDUnionUnloadGang DECIMAL(19, 5), NDUnionUnloadMan DECIMAL(19, 5), NDUnionDailyDay DECIMAL(19, 5), NDUnionDailyHalf DECIMAL(19, 5), NDUnionDailyMonth DECIMAL(19, 5), NDUnionSignalDay DECIMAL(19, 5), NDUnionSignalHalf DECIMAL(19, 5), NDUnionSignalMonth DECIMAL(19, 5), NDUnionEtcDay DECIMAL(19, 5), NDUnionEtcHalf DECIMAL(19, 5), NDUnionEtcMonth DECIMAL(19, 5), NDDailyDay DECIMAL(19, 5), NDDailyHalf DECIMAL(19, 5), NDDailyMonth DECIMAL(19, 5), NDOSDay DECIMAL(19, 5), NDOSHalf DECIMAL(19, 5), NDOSMonth DECIMAL(19, 5), NDEtcDay DECIMAL(19, 5), NDEtcHalf DECIMAL(19, 5), NDEtcMonth DECIMAL(19, 5), DRemark NVARCHAR(2000), WorkPlanSeq INT, WorkPlanSerl INT, IsMain CHAR(1)
--    )
    
--    SET @CONST_#BIZ_IN_DataBlock2 = 1

--END

--IF @CONST_#BIZ_OUT_DataBlock2 = 0
--BEGIN
--    CREATE TABLE #BIZ_OUT_DataBlock2
--    (
--        WorkingTag      NCHAR(1)
--        , IDX_NO        INT
--        , DataSeq       INT
--        , Selected      INT
--        , MessageType   INT
--        , Status        INT
--        , Result        NVARCHAR(255)
--        , ROW_IDX       INT
--        , IsChangedMst  NCHAR(1)
--        , TABLE_NAME    NVARCHAR(255)

--        , UMBisWorkTypeName NVARCHAR(200), UMBisWorkType INT, SelfToolName NVARCHAR(200), SelfToolSeq INT, RentToolName NVARCHAR(200), RentToolSeq INT, ToolWorkTime DECIMAL(19, 5), DriverEmpName1 NVARCHAR(200), DriverEmpSeq1 INT, DriverEmpName2 NVARCHAR(200), DriverEmpSeq2 INT, DriverEmpName3 NVARCHAR(200), DriverEmpSeq3 INT, DUnionDay DECIMAL(19, 5), DUnionHalf DECIMAL(19, 5), DUnionMonth DECIMAL(19, 5), DDailyDay DECIMAL(19, 5), DDailyHalf DECIMAL(19, 5), DDailyMonth DECIMAL(19, 5), DOSDay DECIMAL(19, 5), DOSHalf DECIMAL(19, 5), DOSMonth DECIMAL(19, 5), DEtcDay DECIMAL(19, 5), DEtcHalf DECIMAL(19, 5), DEtcMonth DECIMAL(19, 5), NDEmpName NVARCHAR(200), NDEmpSeq INT, NDUnionUnloadGang DECIMAL(19, 5), NDUnionUnloadMan DECIMAL(19, 5), NDUnionDailyDay DECIMAL(19, 5), NDUnionDailyHalf DECIMAL(19, 5), NDUnionDailyMonth DECIMAL(19, 5), NDUnionSignalDay DECIMAL(19, 5), NDUnionSignalHalf DECIMAL(19, 5), NDUnionSignalMonth DECIMAL(19, 5), NDUnionEtcDay DECIMAL(19, 5), NDUnionEtcHalf DECIMAL(19, 5), NDUnionEtcMonth DECIMAL(19, 5), NDDailyDay DECIMAL(19, 5), NDDailyHalf DECIMAL(19, 5), NDDailyMonth DECIMAL(19, 5), NDOSDay DECIMAL(19, 5), NDOSHalf DECIMAL(19, 5), NDOSMonth DECIMAL(19, 5), NDEtcDay DECIMAL(19, 5), NDEtcHalf DECIMAL(19, 5), NDEtcMonth DECIMAL(19, 5), DRemark NVARCHAR(2000), WorkPlanSeq INT, WorkPlanSerl INT, IsMain CHAR(1)
--    )
    
--    SET @CONST_#BIZ_OUT_DataBlock2 = 1

--END
--INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, PJTName, PJTSeq, PJTTypeName, CustName, UMCustKindName, AGCustName, IFShipCode, ShipSeq, ShipSerlNo, ShipSerl, LOA, UMWorkDivision, UMWorkTypeName, UMWorkType, GoodsQty, GoodsMTWeight, GoodsCBMWeight, SumQty, SumMTWeight, SumCBMWeight, TodayQty, TodayMTWeight, TodayCBMWeight, EtcQty, EtcMTWeight, EtcCBMWeight, MultiExtraName, WorkSrtTime, WorkEndTime, RealWorkTime, EmpName, EmpSeq, UMBisWorkTypeCnt, BizUnitName, PJTNo, AgentName, DRemark, WorkPlanSeq, ExtraGroupSeq, WorkDate, UMWeatherName, UMWeather, MRemark, IsCfm, Confirm, NightQty, NightMTWeight, NightCBMWeight, EnShipName, SourceWorkPlanSeq, UMWorkTeamName, UMWorkTeam) 
--SELECT N'U', 1, 1, 0, 0, NULL, NULL, NULL, N'DataBlock1', N'2017��12�� ~ 2018��3�� ��û���׽�Ʈ.', N'401', N'456', N'��������', N'��������ŷ�ó,���԰ŷ�ó(�ܱ����),�׽�Ʈ,�׽�Ʈ2', N'', NULL, N'67', N'ASVT-2005-001', N'377', N'184', N'�����۾�', N'����', N'1015816001', N'200', N'300', N'400', N'50', N'80', N'15', N'20', N'5', N'7', N'120', N'209', N'370', N'����ȭ��', N'0800', N'1800', N'9', N'��ҷ�', N'3', N'0', N'�������ι�', N'20171201001A', N'', N'test1', N'246', N'1015782005', N'20200102', NULL, N'', N'', NULL, NULL, NULL, NULL, NULL, N'MV. ASIAN VENTURE', N'0', N'�ְ�', N'6017001' UNION ALL 
--SELECT N'U', 2, 2, 0, 0, NULL, NULL, NULL, NULL, N'2017��12�� ~ 2018��3�� ��û���׽�Ʈ.', N'401', N'456', N'��������', N'��������ŷ�ó,���԰ŷ�ó(�ܱ����),�׽�Ʈ,�׽�Ʈ2', N'', NULL, N'67', N'ASVT-2005-001', N'377', N'184', N'�����۾�', N'����', N'1015816001', N'200', N'300', N'400', N'50', N'80', N'15', N'10', N'6', N'8', N'120', N'209', N'370', N'����ȭ��', N'1800', N'2300', N'4', N'�����', N'51', N'0', N'�������ι�', N'20171201001A', N'', N'test2', N'247', N'1015782005', N'20200102', NULL, N'', N'', NULL, NULL, NULL, NULL, NULL, N'MV. ASIAN VENTURE', N'0', N'�߰�', N'6017002'
--IF @@ERROR <> 0 RETURN


--DECLARE @HasError           NCHAR(1)
--        , @UseTransaction   NCHAR(1)
--        -- ���� SP�� �Ķ����
--        , @ServiceSeq       INT
--        , @MethodSeq        INT
--        , @WorkingTag       NVARCHAR(10)
--        , @CompanySeq       INT
--        , @LanguageSeq      INT
--        , @UserSeq          INT
--        , @PgmSeq           INT
--        , @IsTransaction    BIT

--SET @HasError = N'0'
--SET @UseTransaction = N'0'

--BEGIN TRY

--SET @ServiceSeq     = 13820013
----SET @MethodSeq      = 2
--SET @WorkingTag     = N''
--SET @CompanySeq     = 1
--SET @LanguageSeq    = 1
--SET @UserSeq        = 167
--SET @PgmSeq         = 13820008
--SET @IsTransaction  = 1
---- InputData�� OutputData�� ����--INSERT INTO #BIZ_OUT_DataBlock1(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, PJTName, PJTSeq, PJTTypeName, CustName, UMCustKindName, AGCustName, IFShipCode, ShipSeq, ShipSerlNo, ShipSerl, LOA, UMWorkDivision, UMWorkTypeName, UMWorkType, GoodsQty, GoodsMTWeight, GoodsCBMWeight, SumQty, SumMTWeight, SumCBMWeight, TodayQty, TodayMTWeight, TodayCBMWeight, EtcQty, EtcMTWeight, EtcCBMWeight, MultiExtraName, WorkSrtTime, WorkEndTime, RealWorkTime, EmpName, EmpSeq, UMBisWorkTypeCnt, BizUnitName, PJTNo, AgentName, DRemark, WorkPlanSeq, ExtraGroupSeq, WorkDate, UMWeatherName, UMWeather, MRemark, IsCfm, Confirm, NightQty, NightMTWeight, NightCBMWeight, EnShipName, SourceWorkPlanSeq, UMWorkTeamName, UMWorkTeam)--    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, PJTName, PJTSeq, PJTTypeName, CustName, UMCustKindName, AGCustName, IFShipCode, ShipSeq, ShipSerlNo, ShipSerl, LOA, UMWorkDivision, UMWorkTypeName, UMWorkType, GoodsQty, GoodsMTWeight, GoodsCBMWeight, SumQty, SumMTWeight, SumCBMWeight, TodayQty, TodayMTWeight, TodayCBMWeight, EtcQty, EtcMTWeight, EtcCBMWeight, MultiExtraName, WorkSrtTime, WorkEndTime, RealWorkTime, EmpName, EmpSeq, UMBisWorkTypeCnt, BizUnitName, PJTNo, AgentName, DRemark, WorkPlanSeq, ExtraGroupSeq, WorkDate, UMWeatherName, UMWeather, MRemark, IsCfm, Confirm, NightQty, NightMTWeight, NightCBMWeight, EnShipName, SourceWorkPlanSeq, UMWorkTeamName, UMWorkTeam--      FROM  #BIZ_IN_DataBlock1---- ExecuteOrder : 1 : Start--EXEC    mnpt_SPJTWorkPlanCheck--            @ServiceSeq--            , @WorkingTag--            , @CompanySeq--            , @LanguageSeq--            , @UserSeq--            , @PgmSeq--            , @IsTransaction
--IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0)
--BEGIN
--    SET @HasError = N'1'
--    GOTO GOTO_END
--END
---- ExecuteOrder : 1 : End---- ExecuteOrder : 2 : Start--SET @UseTransaction = N'1'--BEGIN TRAN--EXEC    mnpt_SPJTWorkPlanSave--            @ServiceSeq--            , @WorkingTag--            , @CompanySeq--            , @LanguageSeq--            , @UserSeq--            , @PgmSeq--            , @IsTransaction
--IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0)
--BEGIN
--    --ROLLBACK TRAN
--    SET @HasError = N'1'
--    GOTO GOTO_END
--END
---- ExecuteOrder : 2 : End--COMMIT TRAN--SET @UseTransaction = N'0'--GOTO_END:--SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType
--        , CASE
--            WHEN Status = 0 OR Status IS NULL THEN
--                -- �����ΰ� �߿�
--                CASE
--                    WHEN @HasError = N'1' THEN
--                        -- ������ �߻��� ���̸�
--                        CASE
--                            WHEN @UseTransaction = N'1' THEN
--                                999999  -- Ʈ������� ���
--                            ELSE
--                                999998  -- Ʈ������� �ƴ� ���
--                        END
--                    ELSE
--                        -- ������ �߻����� ���� ���̸�
--                        0
--                END
--            ELSE
--                Status
--        END AS Status
--        , Result, ROW_IDX, IsChangedMst, PJTName, PJTSeq, PJTTypeName, CustName, UMCustKindName, AGCustName, IFShipCode, ShipSeq, ShipSerlNo, ShipSerl, LOA, UMWorkDivision, UMWorkTypeName, UMWorkType, GoodsQty, GoodsMTWeight, GoodsCBMWeight, SumQty, SumMTWeight, SumCBMWeight, TodayQty, TodayMTWeight, TodayCBMWeight, EtcQty, EtcMTWeight, EtcCBMWeight, MultiExtraName, WorkSrtTime, WorkEndTime, RealWorkTime, EmpName, EmpSeq, UMBisWorkTypeCnt, BizUnitName, PJTNo, AgentName, DRemark, WorkPlanSeq, ExtraGroupSeq, WorkDate, UMWeatherName, UMWeather, MRemark, IsCfm, Confirm, NightQty, NightMTWeight, NightCBMWeight, EnShipName, SourceWorkPlanSeq, UMWorkTeamName, UMWorkTeam--  FROM #BIZ_OUT_DataBlock1-- ORDER BY IDX_NO, ROW_IDX
--END TRY
--BEGIN CATCH
---- SQL ������ ���� ���⼭ ó���� �ȴ�
--    IF @UseTransaction = N'1'
--        ROLLBACK TRAN
    
--    DECLARE   @ERROR_MESSAGE    NVARCHAR(4000)
--            , @ERROR_SEVERITY   INT
--            , @ERROR_STATE      INT
--            , @ERROR_PROCEDURE  NVARCHAR(128)

--    SELECT    @ERROR_MESSAGE    = ERROR_MESSAGE()
--            , @ERROR_SEVERITY   = ERROR_SEVERITY() 
--            , @ERROR_STATE      = ERROR_STATE() 
--            , @ERROR_PROCEDURE  = ERROR_PROCEDURE()
--    RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE, @ERROR_PROCEDURE)

--    RETURN
--END CATCH

---- SQL ������ ������ üũ�������� �߻��� ������ ���⼭ ó��
--IF @HasError = N'1' AND @UseTransaction = N'1'
--    ROLLBACK TRAN
--DROP TABLE #BIZ_IN_DataBlock1--DROP TABLE #BIZ_OUT_DataBlock1--DROP TABLE #BIZ_IN_DataBlock2--DROP TABLE #BIZ_OUT_DataBlock2--rollback 