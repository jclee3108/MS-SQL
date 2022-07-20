     
IF OBJECT_ID('mnpt_SPJTShipDetailIFListQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTShipDetailIFListQuery      
GO      
      
-- v2017.09.07
      
-- ��������ȸ-��ȸ by ����õ  
CREATE PROC mnpt_SPJTShipDetailIFListQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS     
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
      
    DECLARE @IFShipCode     NVARCHAR(200),   
            @EnShipName     NVARCHAR(200),   
            @BizUnit        INT, 
            @ShipSerlNo     NVARCHAR(100),   
            @ShipName       NVARCHAR(100),   
            @UMBulkCntr     INT, 
            @FrSerlYear     NCHAR(4), 
            @ToSerlYear     NCHAR(4), 
            @FrSerlNo       NCHAR(3), 
            @ToSerlNo       NCHAR(3), 
            @FrInPlanDate   NCHAR(8), 
            @ToInPlanDate   NCHAR(8), 
            @FrInDate       NCHAR(8), 
            @ToInDate       NCHAR(8), 
            @IsNotOutDate   NCHAR(1) 
      
    SELECT @IFShipCode    = ISNULL( IFShipCode      , '' ),   
           @EnShipName    = ISNULL( EnShipName      , '' ),   
           @BizUnit       = ISNULL( BizUnit         , 0 ),   
           @ShipSerlNo    = ISNULL( ShipSerlNo      , '' ),   
           @ShipName      = ISNULL( ShipName        , '' ),   
           @UMBulkCntr    = ISNULL( UMBulkCntr      , 0 ),   
           @FrSerlYear    = ISNULL( FrSerlYear      , '' ),   
           @ToSerlYear    = ISNULL( ToSerlYear      , '' ),   
           @FrSerlNo      = ISNULL( FrSerlNo        , '' ),   
           @ToSerlNo      = ISNULL( ToSerlNo        , '' ),   
           @FrInPlanDate  = ISNULL( FrInPlanDate    , '' ),   
           @ToInPlanDate  = ISNULL( ToInPlanDate    , '' ),   
           @FrInDate      = ISNULL( FrInDate        , '' ),   
           @ToInDate      = ISNULL( ToInDate        , '' ),   
           @IsNotOutDate  = ISNULL( IsNotOutDate    , '0' )
      FROM #BIZ_IN_DataBlock1    
             
    IF @ToSerlYear = '' SELECT @ToSerlYear = '9999'
    IF @ToSerlNo = '' SELECT @ToSerlNo = '999'
    IF @ToInPlanDate = '' SELECT @ToInPlanDate = '99991231'
    IF @ToInDate = '' SELECT @ToInDate = '99991231'


    ------------------------------------------------------------------------
    -- Title 
    ------------------------------------------------------------------------
    CREATE TABLE #Title
    (
        ColIdx     INT IDENTITY(0, 1), 
        TitleName   NVARCHAR(100), 
        TitleSeq   INT
    )
    INSERT INTO #Title (TitleName, TitleSeq) 
    SELECT A.MinorName + '�߷�'  AS TitleName, 
           A.MinorSeq   AS TitleSeq 
      FROM _TDAUMinor       AS A 
      JOIN _TDAUMinorValue  AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000005 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1015782 
       AND B.ValueText = '1'
    
    SELECT * FROM #Title 
    ------------------------------------------------------------------------
    -- Fix
    ------------------------------------------------------------------------
    SELECT ROW_NUMBER() OVER(ORDER BY A.InPlanDateTime,A.ShipSerl) - 1 AS RowIdx, 
           A.ShipSeq           -- �𼱳����ڵ� 
          ,A.ShipSerl          -- ���������� 
          ,STUFF(A.ShipSerlNo,5,0,'-') AS ShipSerlNo       -- ���� 
          ,B.IFShipCode        -- ���ڵ� 
          ,B.EnShipName        -- �𼱸�(����) 
          ,B.ShipName          -- �𼱸�(�ѱ�) 
          ,B.TotalTON          -- GRT(TON) 
          ,B.LOA               -- LOA 
          ,B.DRAFT             -- DRAFT 
          ,B.LINECode          -- LINE 
          ,STUFF(STUFF(LEFT(A.InPlanDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.InPlanDateTime,4),3,0,':')   AS InPlanDateTime  -- ���׿����Ͻ�
          ,STUFF(STUFF(LEFT(A.OutPlanDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.OutPlanDateTime,4),3,0,':') AS OutPlanDateTime -- ���׿����Ͻ�
          ,STUFF(STUFF(LEFT(A.InDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.InDateTime,4),3,0,':') AS InDateTime                -- �����Ͻ� 
          ,STUFF(STUFF(LEFT(A.ApproachDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.ApproachDateTime,4),3,0,':') AS ApproachDateTime -- �����Ͻ�
          ,STUFF(STUFF(LEFT(A.WorkSrtDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.WorkSrtDateTime,4),3,0,':') AS WorkSrtDateTime -- �Ͽ������Ͻ�
          ,STUFF(STUFF(LEFT(A.WorkEndDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.WorkEndDateTime,4),3,0,':') AS WorkEndDateTime -- �Ͽ������Ͻ�
          ,STUFF(STUFF(LEFT(A.OutDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.OutDateTime,4),3,0,':') AS OutDateTime                -- �����Ͻ� 
          -- ���Ƚð�(�ð������� �ø�) : (�����Ͻ�[DATETIME Ÿ��(������ ���)] - �����Ͻ�[DATETIME Ÿ��(������ ���)]) / 60. 
          ,A.DiffApproachTime -- ���Ƚð�

          ,A.BERTH             -- ���� 
          ,A.BRIDGE            -- BRIDGE 
          ,A.FROM_BIT + '~' + A.TO_BIT AS BIT   -- BIT 
          ,A.PORT              -- ������PORT
          ,A.TRADECode         -- �׷� 
          ,CASE WHEN EXISTS (SELECT 1 FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MajorSeq = 1015793 AND MinorName = A.TRADECode) 
                THEN '���׼�'
                WHEN ISNULL(A.TRADECode,'') = '' 
                THEN '' 
                ELSE '���׼�' 
                END AS TRADETypeName 
          ,F.MinorName AS BULKCNTR -- ��ũ�����̳ʱ���
          ,I.BizUnitName AS BizUnitName 
          ,A.AgentName          -- �븮�� 
          ,CASE WHEN A.FirstUserSeq = 1 THEN '' ELSE D.UserName END AS FirstUserName -- �Է���
          ,CONVERT(NVARCHAr(200),A.FirstDateTime,120) AS FirstDateTime -- �Է½ð�
          ,A.UMApplyTon
          ,J.MinorName AS UMApplyTonName 
          ,ISNULL(K.ChangeCnt,0) AS ChangeCnt
      INTO #FixCol
      FROM mnpt_TPJTShipDetail               AS A   
      LEFT OUTER JOIN mnpt_TPJTShipMaster    AS B ON ( B.CompanySeq = @CompanySeq AND B.ShipSeq = A.ShipSeq ) 
      LEFT OUTER JOIN _TCAUser              AS D ON ( D.CompanySeq = @CompanySeq AND D.UserSeq = A.FirstUserSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E ON ( E.CompanySeq = @CompanySeq AND E.Majorseq = 1015786 AND E.Serl = 1000001 AND E.ValueText = A.BULKCNTR ) 
      LEFT OUTER JOIN _TDAUMinor            AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS G ON ( G.CompanySeq = @CompanySeq AND G.Majorseq = 1015794 AND G.Serl = 1000001 AND G.ValueText = A.BizUnitCode ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = G.MinorSeq AND H.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDABizUnit           AS I ON ( I.CompanySeq = @CompanySeq AND I.BizUnit = H.ValueSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS J ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = A.UMApplyTon ) 
      LEFT OUTER JOIN (
                  SELECT ShipSeq, ShipSerl, COUNT(1) AS ChangeCnt
                      FROM mnpt_TPJTShipDetailChange 
                      WHERE CompanySeq = @CompanySeq
                      GROUP BY ShipSeq, ShipSerl 
                  ) AS K ON ( K.ShipSeq = A.ShipSeq AND K.ShipSerl = A.ShipSerl ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND ( @IFShipCode = '' OR A.IFShipCode LIKE @IFShipCode + '%' ) -- �� 
       AND ( @EnShipName = '' OR B.EnShipName LIKE @EnShipName + '%' ) -- �𼱸�(����) 
       AND ( @ShipName = '' OR B.ShipName LIKE @ShipName + '%' ) -- �𼱸�(�ѱ�) 
       AND ( @BizUnit = 0 OR H.ValueSeq = @BizUnit ) -- ����ι� 
       AND ( @ShipSerlNo = '' OR A.ShipSerlNo LIKE @ShipSerlNo + '%' )  -- ���� 
       AND ( @UMBulkCntr = 0 OR E.MinorSeq = @UMBulkCntr ) -- ȭ������ 
       --AND ( LEFT(ISNULL(A.ShipSerlNo,''),4) BETWEEN @FrSerlYear AND @ToSerlYear ) -- �����⵵ 
       AND ( A.ShipSerlNo BETWEEN @FrSerlYear + @FrSerlNo AND @ToSerlYear + @ToSerlNo ) 
       AND ( LEFT(ISNULL(A.InPlanDateTime,''),8) BETWEEN @FrInPlanDate AND @ToInPlanDate ) -- ���׿����� 
       AND ( LEFT(ISNULL(A.InDateTime,''),8) BETWEEN @FrInDate AND @ToInDate ) -- ������ 
       AND ( @IsNotOutDate = '0' 
             OR (@IsNotOutDate = '1' AND ISNULL(A.InDateTime,'') <> '' AND ISNULL(A.OutDateTime,'') = '') 
            ) -- ����� �� 
     ORDER BY A.InPlanDateTime, A.ShipSerl
    
    SELECT * FROM #FixCol 

    ------------------------------------------------------------------------
    -- Value 
    ------------------------------------------------------------------------
    CREATE TABLE #Value
    (
        Value      DECIMAL(19, 5), 
        ShipSeq    INT, 
        ShipSerl   INT, 
        TitleSeq   INT
    )
    INSERT INTO #Value ( Value, ShipSeq, ShipSerl, TitleSeq ) 
    SELECT A.Value, 
           A.ShipSeq, 
           A.ShipSerl, 
           A.TitleSeq
      FROM mnpt_TPJTShipDetailValue AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #FixCol WHERE ShipSeq = A.ShipSeq AND ShipSerl = A.ShipSerl ) 
    
    
    ------------------------------------------------------------------------
    -- ������ȸ 
    ------------------------------------------------------------------------
    SELECT B.RowIdx, A.ColIdx, C.Value AS Result	
      FROM #Value AS C	
      JOIN #Title AS A ON ( A.TitleSeq = C.TitleSeq ) 	
      JOIN #FixCol AS B ON ( B.ShipSeq = C.ShipSeq AND B.ShipSerl = C.ShipSerl ) 	
     ORDER BY A.ColIdx, B.RowIdx	


    RETURN   
      
      go
begin tran   
DECLARE   @CONST_#BIZ_IN_DataBlock1 INT        , @CONST_#BIZ_IN_DataBlock2 INT        , @CONST_#BIZ_IN_DataBlock3 INT        , @CONST_#BIZ_IN_DataBlock4 INT        , @CONST_#BIZ_OUT_DataBlock1 INT        , @CONST_#BIZ_OUT_DataBlock2 INT        , @CONST_#BIZ_OUT_DataBlock3 INT        , @CONST_#BIZ_OUT_DataBlock4 INTSELECT    @CONST_#BIZ_IN_DataBlock1 = 0        , @CONST_#BIZ_IN_DataBlock2 = 0        , @CONST_#BIZ_IN_DataBlock3 = 0        , @CONST_#BIZ_IN_DataBlock4 = 0        , @CONST_#BIZ_OUT_DataBlock1 = 0        , @CONST_#BIZ_OUT_DataBlock2 = 0        , @CONST_#BIZ_OUT_DataBlock3 = 0        , @CONST_#BIZ_OUT_DataBlock4 = 0
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

        , FrIFDate CHAR(8), ToIFDate CHAR(8), FrSerlYear CHAR(4), ToSerlYear CHAR(4), FrInPlanDate CHAR(8), ToInPlanDate CHAR(8), FrInDate CHAR(8), ToInDate CHAR(8), IsNotOutDate CHAR(8), BizUnit INT, UMBulkCntr INT, FrSerlNo CHAR(3), ToSerlNo CHAR(3), IFShipCode NVARCHAR(200), ShipSerlNo NVARCHAR(200), EnShipName NVARCHAR(200), ShipName NVARCHAR(200)
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

        , FrIFDate CHAR(8), ToIFDate CHAR(8), FrSerlYear CHAR(4), ToSerlYear CHAR(4), FrInPlanDate CHAR(8), ToInPlanDate CHAR(8), FrInDate CHAR(8), ToInDate CHAR(8), IsNotOutDate CHAR(8), BizUnit INT, UMBulkCntr INT, FrSerlNo CHAR(3), ToSerlNo CHAR(3), IFShipCode NVARCHAR(200), ShipSerlNo NVARCHAR(200), EnShipName NVARCHAR(200), ShipName NVARCHAR(200)
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

        , TitleName NVARCHAR(200), TitleSeq INT
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

        , TitleName NVARCHAR(200), TitleSeq INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock2 = 1

END

IF @CONST_#BIZ_IN_DataBlock3 = 0
BEGIN
    CREATE TABLE #BIZ_IN_DataBlock3
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

        , IFShipCode NVARCHAR(200), ShipSerlNo NVARCHAR(200), EnShipName NVARCHAR(200), ShipName NVARCHAR(200), TotalTON DECIMAL(19, 5), LOA DECIMAL(19, 5), DRAFT DECIMAL(19, 5), LINECode NVARCHAR(200), InPlanDateTime NVARCHAR(200), OutPlanDateTime NVARCHAR(200), InDateTime NVARCHAR(200), ApproachDateTime NVARCHAR(200), WorkSrtDateTime NVARCHAR(200), WorkEndDateTime NVARCHAR(200), OutDateTime NVARCHAR(200), DiffApproachTime INT, BERTH NVARCHAR(200), BRIDGE NVARCHAR(200), BIT NVARCHAR(200), PORT NVARCHAR(200), TRADECode NVARCHAR(200), TRADETypeName NVARCHAR(200), BULKCNTR NVARCHAR(200), BizUnitName NVARCHAR(200), FirstUserName NVARCHAR(200), FirstDateTime NVARCHAR(200), ShipSeq INT, ShipSerl INT, AgentName NVARCHAR(200), TITLE_IDX0_SEQ INT, Value DECIMAL(19, 5), UMApplyTon NVARCHAR(100), UMApplyTonName NVARCHAR(200)
    )
    
    SET @CONST_#BIZ_IN_DataBlock3 = 1

END

IF @CONST_#BIZ_OUT_DataBlock3 = 0
BEGIN
    CREATE TABLE #BIZ_OUT_DataBlock3
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

        , IFShipCode NVARCHAR(200), ShipSerlNo NVARCHAR(200), EnShipName NVARCHAR(200), ShipName NVARCHAR(200), TotalTON DECIMAL(19, 5), LOA DECIMAL(19, 5), DRAFT DECIMAL(19, 5), LINECode NVARCHAR(200), InPlanDateTime NVARCHAR(200), OutPlanDateTime NVARCHAR(200), InDateTime NVARCHAR(200), ApproachDateTime NVARCHAR(200), WorkSrtDateTime NVARCHAR(200), WorkEndDateTime NVARCHAR(200), OutDateTime NVARCHAR(200), DiffApproachTime INT, BERTH NVARCHAR(200), BRIDGE NVARCHAR(200), BIT NVARCHAR(200), PORT NVARCHAR(200), TRADECode NVARCHAR(200), TRADETypeName NVARCHAR(200), BULKCNTR NVARCHAR(200), BizUnitName NVARCHAR(200), FirstUserName NVARCHAR(200), FirstDateTime NVARCHAR(200), ShipSeq INT, ShipSerl INT, AgentName NVARCHAR(200), TITLE_IDX0_SEQ INT, Value DECIMAL(19, 5), UMApplyTon NVARCHAR(100), UMApplyTonName NVARCHAR(200)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock3 = 1

END

IF @CONST_#BIZ_IN_DataBlock4 = 0
BEGIN
    CREATE TABLE #BIZ_IN_DataBlock4
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

        , RowIdx INT, ColIdx INT, Value DECIMAL(19, 5)
    )
    
    SET @CONST_#BIZ_IN_DataBlock4 = 1

END

IF @CONST_#BIZ_OUT_DataBlock4 = 0
BEGIN
    CREATE TABLE #BIZ_OUT_DataBlock4
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

        , RowIdx INT, ColIdx INT, Value DECIMAL(19, 5)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock4 = 1

END
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, FrIFDate, ToIFDate, FrSerlYear, ToSerlYear, FrInPlanDate, ToInPlanDate, FrInDate, ToInDate, IsNotOutDate, BizUnit, UMBulkCntr, FrSerlNo, ToSerlNo, IFShipCode, ShipSerlNo, EnShipName, ShipName) 
SELECT N'A', 1, 1, 1, 0, NULL, NULL, N'0', N'', N'20170901', N'20170915', N'', N'', N'', N'', N'', N'', N'0', N'', N'', N'', N'', N'', N'', N'', N''
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

SET @ServiceSeq     = 13820003
--SET @MethodSeq      = 1
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820004
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTShipDetailIFListQuery            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0 
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : EndGOTO_END:
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1DROP TABLE #BIZ_IN_DataBlock2DROP TABLE #BIZ_OUT_DataBlock2DROP TABLE #BIZ_IN_DataBlock3DROP TABLE #BIZ_OUT_DataBlock3DROP TABLE #BIZ_IN_DataBlock4DROP TABLE #BIZ_OUT_DataBlock4rollback 