IF OBJECT_ID('test_mnpt_SPJTEECNTRReportIF') IS NOT NULL 
    DROP PROC test_mnpt_SPJTEECNTRReportIF
GO 

-- �����̳ʿ��� by����õ
CREATE PROC test_mnpt_SPJTEECNTRReportIF
    @CompanySeq INT, 
    @UserSeq    INT, 
    @PgmSeq     INT, 
    @OutDateFr  NCHAR(8) = '', 
    @OutDateTo  NCHAR(8) = '', 
    @WorkDateFr NCHAR(8) = '', 
    @WorkDateTo NCHAR(8) = ''
AS 
    
    IF @OutDateTo = '' SELECT @OutDateTo = '99991231'
    IF @WorkDateTo = '' SELECT @WorkDateTo = '99991231'
    
    --SELECT * 
      --INTO #dlinesum
      --FROM OPENQUERY(mokpo21, 'SELECT * 
      --                           FROM dlinesum 
      --                          WHERE JOB_CD = ''00'' 
      --                            AND PREMIEM_YN = ''N'' 
      --                            AND SUMMARY_YN = ''Y'' 
      --                            AND DEMEND = ''2''
      --                            AND SubStr(WKR_STRTIME,1,4) >= ''2017''
      --                        '
      --              )

    select * 
    into #dlinesum
     from test_dlinesum
         
    -- ����������ڵ� (���������-û���׸����_mnpt)�� ��� �� ������ �������� 
    DELETE A 
      FROM #dlinesum AS A 
     WHERE NOT EXISTS (SELECT 1 
                         FROM _TDAUMinorValue 
                        WHERE CompanySeq = @CompanySeq 
                          AND MajorSeq = 1016233 
                          AND Serl = 1000001 
                          AND ValueText = A.HATAE
                      )
    
    -- A, U, D ���� ������ ��� 
    CREATE TABLE #mnpt_TPJTEECNTRReport 
    (
        IDX_NO          INT IDENTITY, 
        WorkingTag      NCHAR(1), 
        Status          INT, 
        ErrMessage      NVARCHAR(2000),
        LINE            NVARCHAR(20), 
        IFShipCode      NVARCHAR(20), 
        ShipYear        NVARCHAR(4), 
        SerlNo          INT, 
        ShipSeq         INT, 
        ShipSerl        INT, 
        ItemSeq         INT, 
        IFItemCode      NVARCHAR(20), 
        DLS             NVARCHAR(20), 
        WorkSrtDateTime NVARCHAR(12), 
        VLCD            NVARCHAR(10), 
        Qty             DECIMAL(19,5), 
        WorkEndDateTime NVARCHAR(12), 
        LastWorkTime    NVARCHAR(14), 
        CNTRReportSeq   INT 
    ) 
    
    INSERT INTO #mnpt_TPJTEECNTRReport 
    (
        WorkingTag      , Status          , ErrMessage      , LINE            , IFShipCode      , 
        ShipYear        , SerlNo          , ShipSeq         , ShipSerl        , ItemSeq         , 
        IFItemCode      , DLS             , WorkSrtDateTime , VLCD            , Qty             , 
        WorkEndDateTime , LastWorkTime    , CNTRReportSeq   
    )
    -- �������̽� ���̺� ���� ������ ��� (INSERT) 
    SELECT 'A' AS WorkingTag, 
           0 AS Status, 
           '' AS ErrMessage, 
           A.LINE, 
           A.VESSEL, 

           A.VES_YY, 
           A.VES_SEQ, 
           0 AS ShipSeq, 
           0 AS ShipSerl, 
           0 AS ItemSeq, 

           A.HATAE, 
           A.DLS, 
           A.WKR_STRTIME, 
           A.VLCD, 
           A.WRK_QTY, 

           A.WRK_ENDTIME, 
           CASE WHEN A.UPD_DATE IS NULL OR A.UPD_DATE = '' THEN A.INS_DATE ELSE A.UPD_DATE END AS LastWorkTime, -- ������� �� ���� �ð�
           0 AS CNTRReportSeq
      FROM #dlinesum    AS A 
     WHERE NOT EXISTS (SELECT 1 
                         FROM mnpt_TPJTEECNTRReport_IF 
                        WHERE CompanySeq = @CompanySeq 
                          AND LINE = A.LINE 
                          AND IFShipCode = A.VESSEL 
                          AND ShipYear = A.VES_YY 
                          AND CONVERT(INT,VES_SEQ) = SerlNo
                          AND IFItemCode = A.HATAE 
                          AND DLS = A.DLS 
                          AND WorkSrtDateTime = A.WKR_STRTIME
                          AND VLCD = A.VLCD
                      )
    

    INSERT INTO #mnpt_TPJTEECNTRReport 
    (
        WorkingTag      , Status          , ErrMessage      , LINE            , IFShipCode      , 
        ShipYear        , SerlNo          , ShipSeq         , ShipSerl        , ItemSeq         , 
        IFItemCode      , DLS             , WorkSrtDateTime , VLCD            , Qty             , 
        WorkEndDateTime , LastWorkTime    , CNTRReportSeq   
    )
    -- �������̽� �ְ�, ������¥�� �ֽ� ������ ��� (UPDATE) 
    SELECT 'U' AS WorkingTag, 
           0 AS Status, 
           '' AS ErrMessage, 
           B.LINE, 
           B.VESSEL, 

           B.VES_YY, 
           B.VES_SEQ, 
           0 AS ShipSeq, 
           0 AS ShipSerl, 
           0 AS ItemSeq, 

           B.HATAE, 
           B.DLS, 
           B.WKR_STRTIME, 
           B.VLCD, 
           B.WRK_QTY, 

           B.WRK_ENDTIME, 
           CASE WHEN B.UPD_DATE IS NULL OR B.UPD_DATE = '' THEN B.INS_DATE ELSE B.UPD_DATE END AS LastWorkTime, -- ������� �� ���� �ð�
           A.CNTRReportSeq AS CNTRReportSeq
      FROM mnpt_TPJTEECNTRReport_IF     AS A 
      JOIN #dlinesum                    AS B WITH(NOLOCK) ON ( B.LINE = A.LINE 
                                                           AND B.VESSEL = A.IFShipCode 
                                                           AND B.VES_YY = A.ShipYear 
                                                           AND CONVERT(INT,B.VES_SEQ) = A.SerlNo
                                                           AND B.HATAE = A.IFItemCode 
                                                           AND B.DLS = A.DLS 
                                                           AND B.WKR_STRTIME = A.WorkSrtDateTime
                                                           AND B.VLCD = A.VLCD
                                                             ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (CASE WHEN B.UPD_DATE IS NULL OR B.UPD_DATE = '' THEN B.INS_DATE ELSE B.UPD_DATE END) > A.LastWorkTime
    




    INSERT INTO #mnpt_TPJTEECNTRReport 
    (
        WorkingTag      , Status          , ErrMessage      , LINE            , IFShipCode      , 
        ShipYear        , SerlNo          , ShipSeq         , ShipSerl        , ItemSeq         , 
        IFItemCode      , DLS             , WorkSrtDateTime , VLCD            , Qty             , 
        WorkEndDateTime , LastWorkTime    , CNTRReportSeq   
    )
    -- ��õ ���̺� ���� ������ ��� (DELETE) 
    SELECT 'D' AS WorkingTag, 
           0 AS Status, 
           '', 
           A.LINE, 
           A.IFShipCode, 
           A.ShipYear, 
           A.SerlNo, 
           0 AS ShipSeq, 
           0 AS ShipSerl, 
           0 AS ItemSeq, 
           A.IFItemCode, 
           A.DLS, 
           A.WorkSrtDateTime, 
           A.VLCD, 
           0 AS Qty, 
           '' AS WorkEndDateTime, 
           '' AS LastWorkTime,          -- ������� �� ���� �ð�
           A.CNTRReportSeq

      FROM mnpt_TPJTEECNTRReport_IF    AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND NOT EXISTS (SELECT 1 
                         FROM #dlinesum 
                        WHERE CompanySeq = @CompanySeq 
                          AND LINE = A.LINE 
                          AND VESSEL = A.IFShipCode
                          AND VES_YY = A.ShipYear
                          AND SerlNo = CONVERT(INT,VES_SEQ)
                          AND HATAE = A.IFItemCode
                          AND DLS = A.DLS 
                          AND WKR_STRTIME = A.WorkSrtDateTime
                          AND VLCD = A.VLCD
                      )
    
    -- ��, �����ڵ� ������Ʈ 
    UPDATE A
       SET ShipSeq = B.ShipSeq, 
           ShipSerl = B.ShipSerl 
      FROM #mnpt_TPJTEECNTRReport   AS A 
      JOIN mnpt_TPJTShipDetail      AS B ON ( B.CompanySeq = @CompanySeq 
                                          AND B.IFShipCode + B.ShipSerlNo = A.IFShipCode + A.ShipYear + RIGHT('00' + CONVERT(NVARCHAR(10),A.SerlNo),3) 
                                            ) 
    -- ǰ���ڵ� ������Ʈ 
    UPDATE Z  
       SET ItemSeq = Y.ItemSeq 
      FROM #mnpt_TPJTEECNTRReport AS Z 
      JOIN ( 
            SELECT B.ValueText AS IFItemCode, C.ValueText AS DLS, D.ValueSeq AS ItemSeq
              FROM _TDAUMinor                   AS A 
              LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
              LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
              LEFT OUTER JOIN _TDAUMinorValue   AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.MinorSeq AND D.Serl = 1000003 ) 
              WHERE A.CompanySeq = @CompanySeq 
                AND A.MajorSeq = 1016233
          ) AS Y ON ( Y.IFItemCode = Z.IFItemCode AND Y.DLS = Z.DLS ) 
    
    
    ----------------------------------------------------------------------------------------
    -- üũ, û�������� �Ǿ� �������� �ʽ��ϴ�. (������ üũ �� Temp(ó���Ǵ����̺�) ����)
    ----------------------------------------------------------------------------------------
    UPDATE A
       SET ErrMessage = 'û�������� �Ǿ� �������� �ʽ��ϴ�.', 
           Status = 1234
      FROM #mnpt_TPJTEECNTRReport   AS A 
      JOIN mnpt_TPJTShipDetail      AS C ON ( C.CompanySeq = @CompanySeq AND C.ShipSeq = A.ShipSeq AND C.ShipSerl = A.ShipSerl ) 
     WHERE A.WorkingTag = 'D' 
       AND EXISTS (SELECT 1 
                     FROM mnpt_TPJTLinkInvoiceItem 
                    WHERE CompanySeq = @CompanySeq 
                      AND ShipSeq = C.ShipSeq 
                      AND ShipSerl = C.ShipSerl
                      AND ChargeDate = LEFT(C.OutDateTime,8)
                  ) 
    
    UPDATE A
       SET ErrMessage = B.ErrMessage
      FROM mnpt_TPJTEECNTRReport_IF           AS A 
      LEFT OUTER JOIN #mnpt_TPJTEECNTRReport  AS B ON ( B.CNTRReportSeq = A.CNTRReportSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.WorkingTag = 'D' 
       AND B.Status <> 0 
    
    DELETE A
      FROM #mnpt_TPJTEECNTRReport AS A 
     WHERE A.Status <> 0 
       AND A.WorkingTag = 'D'  
    ----------------------------------------------------------------------------------------
    -- üũ, End
    ----------------------------------------------------------------------------------------
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #mnpt_TPJTEECNTRReport WHERE WorkingTag = 'A' AND Status = 0 
      
    IF @Count > 0  
    BEGIN  
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'mnpt_TPJTEECNTRReport', 'CNTRReportSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #mnpt_TPJTEECNTRReport
           SET CNTRReportSeq = @Seq + IDX_NO  
         WHERE WorkingTag = 'A' 
           AND Status = 0 
    END 

    -- ������ ������ ���͸�
    DELETE Z 
      FROM #mnpt_TPJTEECNTRReport AS Z 
     WHERE NOT EXISTS (
                        SELECT 1
                          FROM #mnpt_TPJTEECNTRReport           AS A 
                          LEFT OUTER JOIN mnpt_TPJTShipDetail   AS B ON ( B.CompanySeq = @CompanySeq AND B.ShipSeq = A.ShipSeq AND B.ShipSerl = A.ShipSerl ) 
                         WHERE LEFT(A.WorkSrtDateTime,8) BETWEEN @WorkDateFr AND @WorkDateTo 
                           AND LEFT(B.OutDateTime,8) BETWEEN @OutDateFr AND @OutDateTo 
                           AND A.CNTRReportSeq = Z.CNTRReportSeq 
                      ) 
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTEECNTRReport')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  1             ,        
                  'mnpt_TPJTEECNTRReport'    , -- ���̺��        
                  '#mnpt_TPJTEECNTRReport'    , -- �ӽ� ���̺��        
                  'CNTRReportSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
      
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #mnpt_TPJTEECNTRReport WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        -- ERP �����̺� 
        DELETE B   
          FROM #mnpt_TPJTEECNTRReport  AS A   
          JOIN mnpt_TPJTEECNTRReport   AS B ON ( B.CompanySeq = @CompanySeq AND A.CNSTReportSeq = B.CNSTReportSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  

        -- �߰� IF ���̺� 
        DELETE B   
          FROM #mnpt_TPJTEECNTRReport      AS A   
          JOIN mnpt_TPJTEECNTRReport_IF    AS B ON ( B.CompanySeq = @CompanySeq AND A.CNSTReportSeq = B.CNSTReportSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    

    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #mnpt_TPJTEECNTRReport WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        -- �߰� IF ���̺� 
        UPDATE B
           SET LastWorkTime = A.LastWorkTime, 
               ErrMessage = '',  
               LastUserSeq = @UserSeq, 
               LastDateTime = GETDATE(), 
               PgmSeq = @PgmSeq
          FROM #mnpt_TPJTEECNTRReport      AS A   
          JOIN mnpt_TPJTEECNTRReport_IF    AS B ON ( B.CompanySeq = @CompanySeq AND A.CNTRReportSeq = B.CNTRReportSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
        
        -- ERP �����̳ʽ��� ���̺� 
        UPDATE B   
           SET B.Qty                = A.Qty, 
               B.WorkEndDateTime    = A.WorkEndDateTime, 
               B.LastUserSeq        = @UserSeq, 
               B.LastDateTime       = GETDATE(), 
               B.PgmSeq             = @PgmSeq
          FROM #mnpt_TPJTEECNTRReport  AS A   
          JOIN mnpt_TPJTEECNTRReport   AS B ON ( B.CompanySeq = @CompanySeq AND A.CNTRReportSeq = B.CNTRReportSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    

    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #mnpt_TPJTEECNTRReport WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        -- �߰� IF ���̺� 
        INSERT INTO mnpt_TPJTEECNTRReport_IF
        ( 
            CompanySeq, CNTRReportSeq, LINE, IFShipCode, ShipYear, 
            SerlNo, IFItemCode, DLS, WorkSrtDateTime, VLCD, 
            LastWorkTime, ErrMessage, LastUserSeq, LastDateTime, PgmSeq
        ) 
        SELECT @CompanySeq, CNTRReportSeq, LINE, IFShipCode, ShipYear, 
               SerlNo, IFItemCode, DLS, WorkSrtDateTime, VLCD, 
               LastWorkTime, '', @UserSeq, GETDATE(), @PgmSeq
          FROM #mnpt_TPJTEECNTRReport AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0     
        
        IF @@ERROR <> 0 RETURN  

        -- ERP �����̺� 
        INSERT INTO mnpt_TPJTEECNTRReport  
        (   
            CompanySeq, CNTRReportSeq, LINE, IFShipCode, ShipYear, 
            SerlNo, ShipSeq, ShipSerl, ItemSeq, IFItemCode, 
            DLS, WorkSrtDateTime, VLCD, Qty, WorkEndDateTime, 
            FirstUserSeq, FirstDateTime, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, CNTRReportSeq, LINE, IFShipCode, ShipYear, 
               SerlNo, ShipSeq, ShipSerl, ItemSeq, IFItemCode, 
               DLS, WorkSrtDateTime, VLCD, Qty, WorkEndDateTime, 
               @UserSeq, GETDATE(), @UserSeq, GETDATE(), @PgmSeq
          FROM #mnpt_TPJTEECNTRReport AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #mnpt_TPJTEECNTRReport 
    
RETURN 
GO

begin tran 

exec test_mnpt_SPJTEECNTRReportIF @CompanySeq = 1, @UserSeq = 1, @PgmSeq = 1

rollback 
