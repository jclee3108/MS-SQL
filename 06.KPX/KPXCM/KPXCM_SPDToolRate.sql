  
IF OBJECT_ID('KPXCM_SPDToolRate') IS NOT NULL   
    DROP PROC KPXCM_SPDToolRate  
GO  
  
-- v2016.05.19  
  
-- �������񰡵���-���� ��ȸ by ����õ   
CREATE PROC KPXCM_SPDToolRate  
    @CompanySeq     INT = 2, 
    @FactUnit       INT = 3,                -- �������� 
    @StdYearFr      NCHAR(4),               -- From����
    @StdYearTo      NCHAR(4),               -- To���� 
    @SMPlanType     INT = 1080002,          -- ��ȹ/���� ���� (1080001 : ��ȹ, 1080002 : ����)
    @StdYM          NCHAR(6) = NULL,        -- ��ȸ���ؿ�(��������)
    @StyleKind      NCHAR(1) = 'M',         -- ���� ���� ( Y : ����, M : �� ) 
    @PgmSeq         INT = 0,                -- Ư���� ��츦 Case ��������� �ʿ� 
    @IsRemark       NCHAR(1) = '0'          -- �������Կ��� 
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) ���
    
    
    --------------��� ���̺�-----------------------------------
    /*
    CREATE TABLE #Result_Main  
    (
        StdMonthSub     NCHAR(6), 
        StdMonth        NVARCHAR(20), 
        AllWorkDate     DECIMAL(19,5), 
        RealWorkDate    DECIMAL(19,5), 
        AllWorkTime     DECIMAL(19,5), 
        RealWorkTime    DECIMAL(19,5), 
        ShutDownTime    DECIMAL(19,5), 
        ToolRate        DECIMAL(19,5), 
        Remark1         NVARCHAR(MAX), 
        Remark2         NVARCHAR(MAX), 
        StdYear         NCHAR(4)  
    )
    */
    --------------��� ���̺�-----------------------------------
    
    IF ISNULL(@StdYM,'') = '' SELECT @StdYM = '999912'
    
    CREATE TABLE #Result_Main  
    (
        StdMonthSub     NCHAR(6), 
        StdMonth        NVARCHAR(20), 
        AllWorkDate     DECIMAL(19,5), 
        RealWorkDate    DECIMAL(19,5), 
        AllWorkTime     DECIMAL(19,5), 
        RealWorkTime    DECIMAL(19,5), 
        ShutDownTime    DECIMAL(19,5), 
        ToolRate        DECIMAL(19,5), 
        Remark          NVARCHAR(MAX), 
        Remark2         NVARCHAR(MAX), 
        StdYear         NCHAR(4)
    )
    
    CREATE TABLE #Result 
    (
        StdMonthSub     NCHAR(6), 
        StdMonth        NVARCHAR(20), 
        AllWorkDate     DECIMAL(19,5), 
        RealWorkDate    DECIMAL(19,5), 
        AllWorkTime     DECIMAL(19,5), 
        RealWorkTime    DECIMAL(19,5), 
        ShutDownTime    DECIMAL(19,5), 
        ToolRate        DECIMAL(19,5), 
        Remark          NVARCHAR(MAX), 
        Remark2         NVARCHAR(MAX), 
        StdYear         NCHAR(4)  
    )
    
    INSERT INTO #Result( StdMonthSub, StdMonth ) 
    SELECT CONVERT(NCHAR(4),A.StdYear) + B.StdMonthSub, StdMonth 
      FROM ( 
            SELECT DISTINCT SYear AS StdYear 
              FROM _TCOMCalendar AS A 
             WHERE SYear BETWEEN @StdYearFr AND @StdYearTo
           ) AS A 
      JOIN ( 
            SELECT '01' AS StdMonthSub , '1��' AS StdMonth 
            UNION ALL 
            SELECT '02', '2��'
            UNION ALL 
            SELECT '03', '3��'
            UNION ALL 
            SELECT '04', '4��'
            UNION ALL 
            SELECT '05', '5��'
            UNION ALL 
            SELECT '06', '6��'
            UNION ALL 
            SELECT '07', '7��'
            UNION ALL 
            SELECT '08', '8��'
            UNION ALL 
            SELECT '09', '9��'
            UNION ALL 
            SELECT '10', '10��'
            UNION ALL 
            SELECT '11', '11��'
            UNION ALL 
            SELECT '12', '12��'
           ) AS B ON  ( 1 = 1 ) 
    
    CREATE TABLE #ShutDown 
    (
        SrtDateTime     DATETIME, 
        EndDateTime     DATETIME, 
        HourDiff        INT, 
        AllHour         INT,  
        AllDay          INT, 
        StdMonthSub     NCHAR(6), 
        Remark          NVARCHAR(MAX), 
        Remark1         NVARCHAR(MAX) 
    )
    -- ���� ��ģ��� ������ �־��ֱ� 
    INSERT INTO #ShutDown ( SrtDateTime, EndDateTime, HourDiff, Remark, Remark1 )
    SELECT LEFT(A.SrtDate,4) + '-' + SUBSTRING(A.SrtDate,5,2) + '-' + RIGHT(A.SrtDate,2) + ' ' + B.MinorName + ':00.000', 
           CASE WHEN LEFT(A.SrtDate,6) = LEFT(A.EndDate,6) 
                THEN LEFT(A.EndDate,4) + '-' + SUBSTRING(A.EndDate,5,2) + '-' + RIGHT(A.EndDate,2) + ' ' + C.MinorName + ':00.000'
                ELSE LEFT(A.EndDate,4) + '-' + SUBSTRING(A.EndDate,5,2) + '-' + '01' + ' ' + '00:00:00.000'
                END, 
           0, 
           SUBSTRING(A.SrtDate,5,2) + '/' + RIGHT(A.SrtDate,2) + ' ' + B.MinorName + ' ~ ' + 
           CASE WHEN LEFT(A.SrtDate,6) = LEFT(A.EndDate,6) 
                THEN SUBSTRING(A.EndDate,5,2) + '/' + RIGHT(A.EndDate,2) + ' ' + C.MinorName 
                ELSE SUBSTRING(A.EndDate,5,2) + '/' + '01' + ' ' + '00:00'
                END AS Remark, 
           A.Remark 
      FROM KPXCM_TPDShutDown        AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SrtTimeSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSEq = A.EndTimeSeq ) 
     WHERE A.FactUnit = @FactUnit 
       AND LEFT(A.SrtDate,4) BETWEEN @StdYearFr AND @StdYearTo
       AND ( @SMPlanType = 0 OR A.SMPlanType = @SMPlanType) -- ��ȹ/���� �߰� 20160518 jhpark 
    UNION ALL 
    SELECT LEFT(A.EndDate,4) + '-' + SUBSTRING(A.EndDate,5,2) + '-' + '01' + ' ' + '00:00:00.000', 
           LEFT(A.EndDate,4) + '-' + SUBSTRING(A.EndDate,5,2) + '-' + RIGHT(A.EndDate,2) + ' ' + C.MinorName + ':00.000', 
           0, 
           SUBSTRING(A.EndDate,5,2) + '/' + '01' + ' ' + '00:00' + ' ~ ' + 
           SUBSTRING(A.EndDate,5,2) + '/' + RIGHT(A.EndDate,2) + ' ' + C.MinorName AS Remark, 
           A.Remark 
      FROM KPXCM_TPDShutDown        AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SrtTimeSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSEq = A.EndTimeSeq ) 
     WHERE A.FactUnit = @FactUnit 
       AND LEFT(A.SrtDate,4) BETWEEN @StdYearFr AND @StdYearTo
       AND LEFT(A.SrtDate,6) <> LEFT(A.EndDate,6) 
       AND ( @SMPlanType = 0 OR A.SMPlanType = @SMPlanType) -- ��ȹ/���� �߰� 20160518 jhpark 
    
    
    --select * from #ShutDown Order by SrtDateTime 
    --return 

    -- ShutDown �ð�����  
    UPDATE A 
       SET HourDiff = DATEDIFF(Hour, SrtDateTime, EndDateTime), 
           StdMonthSub = CONVERT(NCHAR(6),SrtDateTime,112), 
           Remark = Remark + '('+ CONVERT(NVARCHAR(100),DATEDIFF(Hour, SrtDateTime, EndDateTime)) +'HR)'
      FROM #ShutDown AS A 
    
    
    -- �ش���� ��ü �ð� 
    UPDATE A 
       SET AllWorkTime = (ISNULL(C.AllDay,0) * 24), -- ��ü�ð� 
           ShutDownTime = ISNULL(B.HourDiff,0), -- Shutdown �ð� -- bgkeum
           RealWorkTime = (ISNULL(C.AllDay,0) * 24) - ISNULL(B.HourDiff,0), -- ���������ð�  -- bgkeum
           AllWorkDate = ISNULL(C.AllDay,0) -- ��ü�ϼ� 
      FROM #Result AS A 
      LEFT OUTER JOIN (
                        SELECT StdMonthSub, SUM(HourDiff) AS HourDiff, MAX(AllHour) AS AllHour, MAX(AllDay) AS AllDay 
                          FROM #ShutDown 
                         GROUP BY StdMonthSub
                      ) AS B ON ( B.StdMonthSub = A.StdMonthSub ) 
      LEFT OUTER JOIN (
                        SELECT MAX(CONVERT(INT,RIGHT(Solar,2))) AS AllDay, LEFT(Solar,6) AS StdYM
                          FROM _TCOMCalendar 
                         WHERE SYear BETWEEN @StdYearFr AND @StdYearTo 
                         GROUP BY LEFT(Solar,6) 
                        ) AS C ON ( A.StdMonthSub = C.StdYM ) 
     WHERE A.StdMonthSub <= @StdYM 
    
    -- ���������� ��� 
    UPDATE A 
       SET RealWorkDate = CASE WHEN AllWorkTime = 0 THEN 0 ELSE (RealWorkTime / AllWorkTime) * AllWorkDate END, 
           ToolRate = CASE WHEN AllWorkTime = 0 THEN 0 ELSE (RealWorkTime / AllWorkTime) * 100 END 
      FROM #Result AS A 
     WHERE A.StdMonthSub <= @StdYM  
    
    
    
    -- ��� #Temp
    CREATE TABLE #Remark
    (
        StdMonthSub     NCHAR(6), 
        Remark1         NVARCHAR(MAX), 
        Remark2         NVARCHAR(MAX) 
    )
    
    IF @PgmSeq = 1030027 -- �������񰡵�����ȸ(�췹ź)
    BEGIN      
        IF @IsRemark = '1' -- �������Կ��� 
        BEGIN 
            INSERT INTO #Remark ( StdMonthSub, Remark1 ) 
            SELECT B.StdMonthSub, REPLACE ( REPLACE ( REPLACE ( (SELECT A.Remark + ' : ' + A.Remark1 AS Remark FROM #ShutDown AS A WHERE StdMonthSub = B.StdMonthSub  FOR XML AUTO, ELEMENTS),'</Remark></A><A><Remark>',', '), '<A><Remark>',''), '</Remark></A>', '') AS Remark 
            FROM #ShutDown AS B 
            GROUP BY B.StdMonthSub		
        END 
        ELSE
        BEGIN
            INSERT INTO #Remark ( StdMonthSub, Remark1 ) 
            SELECT B.StdMonthSub, REPLACE ( REPLACE ( REPLACE ( (SELECT A.Remark FROM #ShutDown AS A WHERE StdMonthSub = B.StdMonthSub  FOR XML AUTO, ELEMENTS),'</Remark></A><A><Remark>',', '), '<A><Remark>',''), '</Remark></A>', '') AS Remark 
            FROM #ShutDown AS B 
            GROUP BY B.StdMonthSub	
        END
        
    END 
    ELSE
    BEGIN 
        INSERT INTO #Remark ( StdMonthSub, Remark1, Remark2  ) 
        SELECT B.StdMonthSub, 
               REPLACE ( REPLACE ( REPLACE ( (SELECT A.Remark AS Remark FROM #ShutDown AS A WHERE StdMonthSub = B.StdMonthSub  FOR XML AUTO, ELEMENTS),'</Remark></A><A><Remark>',NCHAR(13)), '<A><Remark>',''), '</Remark></A>', '') AS Remark1,  
               REPLACE ( REPLACE ( REPLACE ( (SELECT A.Remark1 AS Remark FROM #ShutDown AS A WHERE StdMonthSub = B.StdMonthSub  FOR XML AUTO, ELEMENTS),'</Remark></A><A><Remark>',NCHAR(13)), '<A><Remark>',''), '</Remark></A>', '') AS Remark2 
        FROM #ShutDown AS B 
        GROUP BY B.StdMonthSub		
    END 
    

    -- ��� Update 
    UPDATE A
       SET Remark = ISNULL(B.Remark1,''),
           Remark2 = ISNULL(B.Remark2,'')
      FROM #Result AS A 
      LEFT OUTER JOIN #Remark AS B ON ( B.StdMonthSub = A.StdMonthSub ) 
     WHERE A.StdMonthSub <= @StdYM  
    
    
    IF @StyleKind = 'M' -- ���� ���� 
    BEGIN 
        INSERT INTO #Result_Main
        SELECT * 
          FROM #Result
    END 
    ELSE -- ���� ���� 
    BEGIN 
        INSERT INTO #Result_Main 
        ( 
            StdMonthSub, AllWorkDate, AllWorkTime, RealWorkTime, ShutDownTime, 
            RealWorkDate, ToolRate, Remark, Remark2, StdMonth
        ) 
        SELECT LEFT(StdMonthSub,4), 
               SUM(AllWorkDate), 
               SUM(AllWorkTime), 
               SUM(AllWorkTime) - SUM(ShutDownTime), 
               SUM(ShutDownTime), 
               
               CASE WHEN SUM(AllWorkTime) = 0 THEN 0 ELSE ((SUM(AllWorkTime) - SUM(ShutDownTime)) / SUM(AllWorkTime)) * SUM(AllWorkDate) END, 
               CASE WHEN SUM(AllWorkTime) = 0 THEN 0 ELSE ((SUM(AllWorkTime) - SUM(ShutDownTime)) / SUM(AllWorkTime)) * 100 END,
               '', '', ''
          FROM #Result 
         GROUP BY LEFT(StdMonthSub,4) 
    END 
    
    -- �հ� 
    INSERT INTO #Result_Main 
    ( 
        StdMonthSub, StdMonth, AllWorkDate, RealWorkDate, AllWorkTime, 
        RealWorkTime, ShutDownTime, ToolRate, Remark 
    ) 
    SELECT 999998, '��', SUM(AllWorkDate), SUM(RealWorkDate), SUM(AllWorkTime), 
           SUM(RealWorkTime), SUM(ShutDownTime), CASE WHEN SUM(AllWorkTime) = 0 THEN 0 ELSE (SUM(RealWorkTime) / SUM(AllWorkTime)) * 100 END, 
           '�� SHUT-DOWN�ð� : '+ CONVERT(NVARCHAR(100),CONVERT(INT,SUM(ShutDownTime))) + 'HR (' + CONVERT(NVARCHAR(100),CONVERT(INT,SUM(ShutDownTime)) / 24) + '��)'
      FROM #Result_Main
    
    -- ��� 
    INSERT INTO #Result_Main 
    ( 
        StdMonthSub, StdMonth, AllWorkDate, RealWorkDate, AllWorkTime, 
        RealWorkTime, ShutDownTime, ToolRate, Remark 
    ) 
    SELECT 999999, '���', AVG(AllWorkDate), AVG(RealWorkDate), AVG(AllWorkTime), 
           AVG(RealWorkTime), AVG(ShutDownTime), CASE WHEN AVG(AllWorkTime) = 0 THEN 0 ELSE (AVG(RealWorkTime) / AVG(AllWorkTime)) * 100 END, 
           '��� SHUT-DOWN�ð� : '+ CONVERT(NVARCHAR(100),CONVERT(INT,AVG(ShutDownTime))) + 'HR (' + CONVERT(NVARCHAR(100),CONVERT(INT,AVG(ShutDownTime)) / 24) + '��)'
      FROM #Result_Main
     WHERE StdMonthSub < 999998 
    
    IF @PgmSeq = 1030027 -- �������񰡵�����ȸ(�췹ź) ��¹� 
    BEGIN 
        UPDATE A 
           SET StdYear = LEFT(StdMonthSub,4)
          FROM #Result_Main AS A 
    END 
    
    SELECT *
      FROM #Result_Main 
    
    RETURN  
    GO
begin tran 

exec KPXCM_SPDToolRate @CompanySeq = 1             
                      ,@FactUnit   = 1              -- �������� 
                      ,@StdYearFr  = '2015'         -- From����
                      ,@StdYearTo  = '2016'         -- To���� 
                      ,@SMPlanType  = 1080002       -- ��ȹ/���� ���� (1080001 : ��ȹ, 1080002 : ����) -> �������� �⺻ : ����(1080002)
                      ,@StdYM       = '201605'      -- ��ȸ���ؿ� -> �������� �⺻ : ����� 
                      ,@StyleKind   = 'M'           -- ���� ���� ( Y : ����, M : �� ) -> �������� �⺻ : �� 
                      --,@PgmSeq      = 1030027       -- Ư���� ��츦 Case ��������� �ʿ�  
                      --,@IsRemark    = '1'           -- �������Կ��� 
rollback 