     
IF OBJECT_ID('mnpt_SPJTShipIFListQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTShipIFListQuery      
GO      
      
-- v2017.09.06
      
-- ����ȸ-��ȸ by ����õ  
CREATE PROC mnpt_SPJTShipIFListQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @IFShipCode  NVARCHAR(200),   
            @EnShipName  NVARCHAR(200),   
            @ShipName    NVARCHAR(200),   
            @LINECode    NVARCHAR(200),   
            @EnLINEName  NVARCHAR(200),   
            @LINEName    NVARCHAR(200),   
            @NationCode  NVARCHAR(200),   
            @NationName  NVARCHAR(200)
    
    SELECT @IFShipCode  = ISNULL( IFShipCode    , '' ),   
           @EnShipName  = ISNULL( EnShipName    , '' ),   
           @ShipName    = ISNULL( ShipName      , '' ),   
           @LINECode    = ISNULL( LINECode      , '' ),   
           @EnLINEName  = ISNULL( EnLINEName    , '' ),   
           @LINEName    = ISNULL( LINEName      , '' ),   
           @NationCode  = ISNULL( NationCode    , '' ),   
           @NationName  = ISNULL( NationName    , '' )
      FROM #BIZ_IN_DataBlock1    
  

    SELECT A.ShipSeq          -- �𼱳����ڵ� 
          ,A.IFShipCode       -- ���ڵ�
          ,A.EnShipName       -- �𼱸�(����)
          ,A.ShipName         -- �𼱸�(�ѱ�)
          ,A.LINECode         -- LINE�ڵ� 
          ,A.EnLINEName       -- LINE��(����)
          ,A.LINEName         -- LINE��(�ѱ�)
          ,A.NationCode       -- �����ڵ�
          ,A.NationName       -- ������
          ,A.CodeLetters      -- ��ȣ��ȣ
          ,A.TotalTON         -- �����
          ,A.LoadTON          -- �������
          ,A.LOA              -- ����
          ,A.Breadth          -- ����
          ,A.DRAFT            -- �ϰ踸�����
          ,C.MInorName AS BULKCNTR         -- ��ũ �����̳� ����

          ,A.IsImagine        -- ����𼱿���
          ,A.Remark           -- ��� 
          ,CASE WHEN A.FirstUserSeq = 1 THEN '' ELSE D.UserName END AS FirstUserName -- �Է���
          ,CONVERT(NVARCHAr(200),A.FirstDateTime,120) AS FirstDateTime -- �Է½ð�

      FROM mnpt_TPJTShipMaster           AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MajorSeq = 1015786 AND B.Serl = 1000001 AND B.ValueText = A.BULKCNTR ) 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.MinorSeq ) 
      LEFT OUTER JOIN _TCAUser          AS D ON ( D.CompanySeq = @CompanySeq AND D.UserSeq = A.FirstUserSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND ( @IFShipCode = '' OR A.IFShipCode LIKE @IFShipCode +'%' ) 
       AND ( @EnShipName = '' OR A.EnShipName LIKE @EnShipName +'%' ) 
       AND ( @ShipName = '' OR A.ShipName LIKE @ShipName +'%' ) 
       AND ( @LINECode = '' OR A.LINECode LIKE @LINECode +'%' ) 
       AND ( @EnLINEName = '' OR A.EnLINEName LIKE @EnLINEName +'%' ) 
       AND ( @LINEName = '' OR A.LINEName LIKE @LINEName +'%' ) 
       AND ( @NationCode = '' OR A.NationCode LIKE @NationCode +'%' ) 
       AND ( @NationName = '' OR A.NationName LIKE @NationName +'%' ) 

    RETURN     



--/*
    go

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

        , IFShipCode NVARCHAR(200), EnShipName NVARCHAR(200), ShipName NVARCHAR(200), LINECode NVARCHAR(200), EnLINEName NVARCHAR(200), LINEName NVARCHAR(200), NationCode NVARCHAR(200), NationName NVARCHAR(200)
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

        , IFShipCode NVARCHAR(200), EnShipName NVARCHAR(200), ShipName NVARCHAR(200), LINECode NVARCHAR(200), EnLINEName NVARCHAR(200), LINEName NVARCHAR(200), NationCode NVARCHAR(200), NationName NVARCHAR(200), CodeLetters NVARCHAR(200), TotalTON DECIMAL(19, 5), LoadTON DECIMAL(19, 5), LOA DECIMAL(19, 5), Breadth DECIMAL(19, 5), DRAFT DECIMAL(19, 5), BULKCNTR NVARCHAR(100), IsImagine CHAR(1), Remark NVARCHAR(2000), FirstUserName NVARCHAR(100), FirstDateTime NVARCHAR(100), ShipSeq INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, IFShipCode, EnShipName, ShipName, LINECode, EnLINEName, LINEName, NationCode, NationName) 
SELECT N'A', 1, 1, 1, 0, NULL, NULL, N'0', N'', N'', N'', N'', N'', N'', N'', N'', N''
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

SET @ServiceSeq     = 13820002
--SET @MethodSeq      = 1
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820002
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTShipIFListQuery            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1rollback --*/