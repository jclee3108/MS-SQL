IF OBJECT_ID('mnpt_SPJTShipMasterIF') IS NOT NULL 
    DROP PROC mnpt_SPJTShipMasterIF
GO 

-- �𼱿��� by����õ
CREATE PROC mnpt_SPJTShipMasterIF
    @CompanySeq INT, 
    @UserSeq    INT, 
    @PgmSeq     INT 
AS 
    

    SELECT * 
      INTO #DVESSELC
      FROM OPENQUERY(mokpo21, 'SELECT * FROM DVESSELC')
    

    --select * from mnpt_TMoseonM where IFSHipCode = 'MOQN'
    --SELECT * FROM #DVESSELC where VESSEL_CD = 'MOQN'
    --return 
    -- A, U, D ���� ������ ��� 
    CREATE TABLE #mnpt_TPJTShipMaster 
    (
        IDX_NO          INT IDENTITY, 
        WorkingTag      NCHAR(1), 
        Status          INT, 
        ErrMessage      NVARCHAR(2000),
        IFShipCode      NVARCHAR(200),
        EnShipName      NVARCHAR(200), 
        ShipName        NVARCHAR(200), 
        LINECode        NVARCHAR(200), 
        CodeLetters     NVARCHAR(200), 
        NationCode      NVARCHAR(200), 
        TotalTON        DECIMAL(19,5), 
        LoadTON         DECIMAL(19,5), 
        LOA             DECIMAL(19,5), 
        Breadth         DECIMAL(19,5), 
        DRAFT           DECIMAL(19,5), 
        BULKCNTR        NVARCHAR(200), 
        LastWorkTime    NCHAR(12), 
        ShipSeq         INT 
    ) 

    INSERT INTO #mnpt_TPJTShipMaster 
    ( 
        WorkingTag    , IFShipCode    , EnShipName    , ShipName      , LINECode      , 
        CodeLetters   , NationCode    , TotalTON      , LoadTON       , LOA           , 
        Breadth       , DRAFT         , BULKCNTR      , LastWorkTime  , ShipSeq       , 
        Status 
    ) 
    -- �������̽� ���̺� ���� ������ ��� (INSERT) 
    SELECT 'A' AS WorkingTag, 
           A.VESSEL_CD,             -- ���ڵ� 
           A.VESSEL_ENM,            -- �𼱸�(����) 
           A.VESSEL_KNM,            -- �𼱸�(�ѱ�) 
           A.LINE,                  -- LINE�ڵ�
           A.CALL_SIGN,             -- ��ȣ��ȣ 
           A.COUNTRY_CD,            -- �����ڵ� 
           A.TOT_DISP,              -- �����
           A.NET_DISP,              -- �������
           A.LOA,                   -- ���� 
           A.LBP,                   -- ����
           A.SUM_DRAFT,             -- �ϰ踸��Ȧ�� 
           A.CNTR_BULK,             -- ��ũ �����̳ʱ���
           CASE WHEN A.UPD_DATE IS NULL OR A.UPD_DATE = '' THEN A.INS_DATE ELSE A.UPD_DATE END AS LastWorkTime, -- ������� �� ���� �ð�
           0 AS ShipSeq, 
           0 AS Status 
      FROM #DVESSELC    AS A 
     WHERE NOT EXISTS (SELECT 1 FROM mnpt_TPJTShipMaster_IF WHERE CompanySeq = @CompanySeq AND IFShipCode = A.VESSEL_CD)
    
    INSERT INTO #mnpt_TPJTShipMaster 
    ( 
        WorkingTag    , IFShipCode    , EnShipName    , ShipName      , LINECode      , 
        CodeLetters   , NationCode    , TotalTON      , LoadTON       , LOA           , 
        Breadth       , DRAFT         , BULKCNTR      , LastWorkTime  , ShipSeq       , 
        Status 
    ) 
    -- �������̽� �ְ�, ������¥�� �ֽ� ������ ��� (UPDATE) 
    SELECT 'U' AS WorkingTag, 
           B.VESSEL_CD,             -- ���ڵ� 
           B.VESSEL_ENM,            -- �𼱸�(����) 
           B.VESSEL_KNM,            -- �𼱸�(�ѱ�) 
           B.LINE,                  -- LINE�ڵ�
           B.CALL_SIGN,             -- ��ȣ��ȣ 
           B.COUNTRY_CD,            -- �����ڵ� 
           B.TOT_DISP,              -- �����
           B.NET_DISP,              -- �������
           B.LOA,                   -- ���� 
           B.LBP,                   -- ����
           B.SUM_DRAFT,             -- �ϰ踸��Ȧ�� 
           B.CNTR_BULK,             -- ��ũ �����̳ʱ���
           CASE WHEN B.UPD_DATE IS NULL OR B.UPD_DATE = '' THEN B.INS_DATE ELSE B.UPD_DATE END AS LastWorkTime, -- ������� �� ���� �ð�
           A.ShipSeq AS ShipSeq, 
           0 AS Status
      FROM mnpt_TPJTShipMaster_IF   AS A 
      JOIN #DVESSELC                AS B WITH(NOLOCK) ON ( B.VESSEL_CD = A.IFShipCode ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (CASE WHEN B.UPD_DATE IS NULL OR B.UPD_DATE = '' THEN B.INS_DATE ELSE B.UPD_DATE END) > A.LastWorkTime
    
    INSERT INTO #mnpt_TPJTShipMaster 
    ( 
        WorkingTag    , IFShipCode    , EnShipName    , ShipName      , LINECode      , 
        CodeLetters   , NationCode    , TotalTON      , LoadTON       , LOA           , 
        Breadth       , DRAFT         , BULKCNTR      , LastWorkTime  , ShipSeq       , 
        Status 
    ) 
    -- ��õ ���̺� ���� ������ ��� (DELETE) 
    SELECT 'D' AS WorkingTag, 
           A.IFShipCode,                -- ���ڵ� 
           '' AS EnShipName,            -- �𼱸�(����) 
           '' AS ShipName,              -- �𼱸�(�ѱ�) 
           '' AS LINECode,              -- LINE�ڵ�
           '' AS CodeLetters,           -- ��ȣ��ȣ 
           '' AS NationCode,            -- �����ڵ� 
           0 AS TotalTON,               -- �����
           0 AS LoadTON,                -- �������
           0 AS LOA,                    -- ���� 
           0 AS Breadth,                -- ����
           0 AS DRAFT,                  -- �ϰ踸��Ȧ�� 
           '' AS BULKCNTR,              -- ��ũ �����̳ʱ���
           '' AS LastWorkTime,          -- ������� �� ���� �ð�
           A.ShipSeq, 
           0 AS Status 
      FROM mnpt_TPJTShipMaster_IF    AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND NOT EXISTS (SELECT 1 FROM #DVESSELC WHERE VESSEL_CD = A.IFShipCode)
    
    ----------------------------------------------------------------------------------------
    -- üũ, ������ �Ǵ� ��࿡ �����Ͽ� �������� �ʽ��ϴ�. (������ üũ �� Temp(ó���Ǵ����̺�) ����)
    ----------------------------------------------------------------------------------------
    UPDATE A
       SET ErrMessage = '������ �Ǵ� ��࿡ �����Ͽ� �������� �ʽ��ϴ�.', 
           Status = 1234
      FROM #mnpt_TPJTShipMaster AS A 
     WHERE A.WorkingTag = 'D' 
       AND (EXISTS (SELECT 1 FROM mnpt_TPJTShipDetail WHERE CompanySeq = @CompanySeq AND ShipSeq = A.ShipSeq) 
            OR EXISTS (SELECT 1 FROM mnpt_TPJTContract WHERE CompanySeq = @CompanySeq AND ShipSeq = A.ShipSeq)
           )
    UPDATE A
       SET ErrMessage = B.ErrMessage
      FROM mnpt_TPJTShipMaster_IF           AS A 
      LEFT OUTER JOIN #mnpt_TPJTShipMaster  AS B ON ( B.ShipSeq = A.ShipSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.WorkingTag = 'D' 
       AND B.Status <> 0 
    
    DELETE A
      FROM #mnpt_TPJTShipMaster AS A 
     WHERE A.Status <> 0 
       AND A.WorkingTag = 'D'  
    ----------------------------------------------------------------------------------------
    -- üũ, End
    ----------------------------------------------------------------------------------------

    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #mnpt_TPJTShipMaster WHERE WorkingTag = 'A' AND Status = 0 
      
    IF @Count > 0  
    BEGIN  
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'mnpt_TPJTShipMaster', 'ShipSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #mnpt_TPJTShipMaster
           SET ShipSeq = @Seq + IDX_NO  
         WHERE WorkingTag = 'A' 
           AND Status = 0 
    END 
    

    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTShipMaster')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  1             ,        
                  'mnpt_TPJTShipMaster'    , -- ���̺��        
                  '#mnpt_TPJTShipMaster'    , -- �ӽ� ���̺��        
                  'ShipSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
      

    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #mnpt_TPJTShipMaster WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        -- ERP �����̺� 
        DELETE B   
          FROM #mnpt_TPJTShipMaster  AS A   
          JOIN mnpt_TPJTShipMaster   AS B ON ( B.CompanySeq = @CompanySeq AND A.ShipSeq = B.ShipSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  

        -- �߰� IF ���̺� 
        DELETE B   
          FROM #mnpt_TPJTShipMaster      AS A   
          JOIN mnpt_TPJTShipMaster_IF    AS B ON ( B.CompanySeq = @CompanySeq AND A.ShipSeq = B.ShipSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #mnpt_TPJTShipMaster WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        -- �߰� IF ���̺� 
        UPDATE B
           SET LastWorkTime = A.LastWorkTime, 
               ErrMessage = '',  
               LastUserSeq = @UserSeq, 
               LastDateTime = GETDATE(), 
               PgmSeq = @PgmSeq
          FROM #mnpt_TPJTShipMaster      AS A   
          JOIN mnpt_TPJTShipMaster_IF    AS B ON ( B.CompanySeq = @CompanySeq AND A.ShipSeq = B.ShipSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
        
        -- ERP �����̺� 
        UPDATE B   
           SET B.EnShipName     = A.EnShipName   ,
               B.ShipName       = A.ShipName     ,
               B.LINECode       = A.LINECode     ,
               --B.EnLINEName     = A.EnLINEName   ,
               --B.LINEName       = A.LINEName     ,
               B.NationCode     = A.NationCode   ,
               --B.NationName     = A.NationName   , 
               B.CodeLetters    = A.CodeLetters  ,
               B.TotalTON       = A.TotalTON     ,
               B.LoadTON        = A.LoadTON      ,
               B.LOA            = A.LOA          ,
               B.Breadth        = A.Breadth      ,
               B.DRAFT          = A.DRAFT        ,
               B.BULKCNTR       = A.BULKCNTR     , 
               B.LastUserSeq    = @UserSeq, 
               B.LastDateTime   = GETDATE(), 
               B.PgmSeq         = @PgmSeq
          FROM #mnpt_TPJTShipMaster  AS A   
          JOIN mnpt_TPJTShipMaster   AS B ON ( B.CompanySeq = @CompanySeq AND A.ShipSeq = B.ShipSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    

    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #mnpt_TPJTShipMaster WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        -- �߰� IF ���̺� 
        INSERT INTO mnpt_TPJTShipMaster_IF
        ( 
            CompanySeq, ShipSeq, IFShipCode, LastWorkTime, ErrMessage, 
            LastUserSeq, LastDateTime, PgmSeq
        ) 
        SELECT @CompanySeq, ShipSeq, IFShipCode, LastWorkTime, '', 
               @UserSeq, GETDATE(), @PgmSEq
          FROM #mnpt_TPJTShipMaster AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0     
        
        IF @@ERROR <> 0 RETURN  

        -- ERP �����̺� 
        INSERT INTO mnpt_TPJTShipMaster  
        (   
            CompanySeq, ShipSeq, IFShipCode, EnShipName, ShipName, 
            LINECode, EnLINEName, LINEName, NationCode, NationName, 
            CodeLetters, TotalTON, LoadTON, LOA, Breadth, 
            DRAFT, BULKCNTR, IsImagine, Remark, FirstUserSeq, 
            FirstDateTime, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, ShipSeq, IFShipCode, EnShipName, ShipName, 
               LINECode, '', '', NationCode, '', 
               CodeLetters, TotalTON, LoadTON, LOA, Breadth, 
               DRAFT, BULKCNTR, '0', '', @UserSeq, 
               GETDATE(), @UserSeq, GETDATE(), @PgmSeq
          FROM #mnpt_TPJTShipMaster AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #mnpt_TPJTShipMaster 
    
RETURN 
GO

begin tran 

exec mnpt_SPJTShipMasterIF @CompanySeq = 1, @UserSeq = 1, @PgmSeq = 1 

rollback 