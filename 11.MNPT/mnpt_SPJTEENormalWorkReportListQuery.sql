     
IF OBJECT_ID('mnpt_SPJTEENormalWorkReportListQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTEENormalWorkReportListQuery      
GO      
      
-- v2017.12.07
      
-- �Ϲ�ȭ��ó��������ȸ-��ȸ by����õ
CREATE PROC mnpt_SPJTEENormalWorkReportListQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    DECLARE @FrStdYM        NCHAR(6), 
            @ToStdYM        NCHAR(6), 
            @WorkReportType INT
    
    SELECT @FrStdYM         = ISNULL( FrStdYM       , '' ),   
           @ToStdYM         = ISNULL( ToStdYM       , '' ), 
           @WorkReportType  = ISNULL( WorkReportType, 0 )
      FROM #BIZ_IN_DataBlock1    
  
    
    --select @FrStdYM, @ToStdYM, @WorkReportType 

    -- �����̳� �۾��׸� X or �����۾� O
    SELECT A.MinorSeq AS UMWorkType 
      INTO #CNTRWorkType 
      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000002 ) -- �����̳��۾�����
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000001 ) -- �����۾����� 
     WHERE A.CompanySeq = @CompanySeq
       AND A.MajorSeq = 1015816 
       AND ( ISNULL(B.ValueText,'0') = '0' AND C.ValueText = '1' )
    
    -- ��ȸ ��� WorkReportSeq ��� ( 1 = �Ϲ�, 2 = ���ֿ��� ) 
    CREATE TABLE #WorkReportSeq ( WorkReportSeq   INT )

    INSERT INTO #WorkReportSeq ( WorkReportSeq ) 
    SELECT A.WorkReportSeq 
      FROM mnpt_TPJTWorkReport AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.IsCfm = '1' 
       AND LEFT(A.WorkDate ,6) BETWEEN @FrStdYM AND @ToStdYM 
       AND ( (@WorkReportType = '1' AND EXISTS (SELECT 1 FROM mnpt_TPJTEEExcelUploadMapping WHERE CompanySeq = @CompanySeq AND PJTSeq = A.PJTSeq)) -- ���ֿ��� �۾�����
          OR (@WorkReportType = '2' AND NOT EXISTS (SELECT 1 FROM mnpt_TPJTEEExcelUploadMapping WHERE CompanySeq = @CompanySeq AND PJTSeq = A.PJTSeq)) -- ���ֿ��� ������ �Ϲ� �۾�����
           )
       AND EXISTS (SELECT 1 FROM #CNTRWorkType WHERE UMWorkType = A.UMWorkType) -- �����̳� �۾��׸� X or �����۾� O
    

    SELECT * 
      FROM mnpt_TPJTWorkReport AS A
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #WorkReportSeq WHERE WorkReportSeq = A.WorkReportSeq) 
    
    
    
    return 

  
      RETURN     
GO 
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

        , FrStdYM CHAR(6), ToStdYM CHAR(6), WorkReportType INT
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

        , TRADETypeName NVARCHAR(200), ShipSerlNo NVARCHAR(200), EnShipName NVARCHAR(200), OutDate CHAR(8), ItemClassMName NVARCHAR(200), WorkTypeName NVARCHAR(200), PJTTypeName NVARCHAR(200), Qty DECIMAL(19, 5), MTWeight DECIMAL(19, 5), CBMWeight DECIMAL(19, 5), RTWeight DECIMAL(19, 5), CustName NVARCHAR(200), LOA NVARCHAR(200), AgentName NVARCHAR(200), ShipSeq INT, ShipSerl INT, FrStdYM CHAR(6), ToStdYM CHAR(6), WorkReportTypeName NVARCHAR(200), WorkReportType INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, FrStdYM, ToStdYM, WorkReportType) 
SELECT N'A', 1, 1, 1, 0, NULL, NULL, N'0', N'', N'201701', N'201712', N'2'
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

SET @ServiceSeq     = 13820076
--SET @MethodSeq      = 1
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820080
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTEENormalWorkReportListQuery            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1rollback 