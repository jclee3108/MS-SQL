  
IF OBJECT_ID('mnpt_SPJTOperatorPriceDataCopyCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTOperatorPriceDataCopyCheck  
GO  
    
-- v2017.09.20
  
-- ���������Ӵܰ��Է�-�ֱ��ڷẹ��üũ by ����õ
CREATE PROC mnpt_SPJTOperatorPriceDataCopyCheck
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    
    -- üũ1, �ֱ��ڷᰡ �������� �ʽ��ϴ�.
    DECLARE @MaxStdDate NCHAR(8) 

    SELECT @MaxStdDate = MAX(B.StdDate) 
      FROM #BIZ_OUT_DataBlock2          AS A 
      JOIN mnpt_TPJTOperatorPriceMaster AS B ON ( B.CompanySeq = @CompanySeq AND B.StdDate < A.StdDate ) 
     WHERE A.Status = 0 
    
    IF @MaxStdDate IS NULL OR @MaxStdDate = '' 
    BEGIN 
        UPDATE A
           SET Result = '�ֱ��ڷᰡ �������� �ʽ��ϴ�.', 
               Status = 1234, 
               MessageType = 1234 
          FROM #BIZ_OUT_DataBlock2 AS A 
    END 
    -- üũ1, END 
    
    RETURN  
 

 GO 


 begin tran 


 DECLARE   @CONST_#BIZ_IN_DataBlock2 INT        , @CONST_#BIZ_OUT_DataBlock2 INTSELECT    @CONST_#BIZ_IN_DataBlock2 = 0        , @CONST_#BIZ_OUT_DataBlock2 = 0
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

        , StdDate CHAR(8), StdSeq INT
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

        , StdDate CHAR(8), UMToolTypeName NVARCHAR(200), UMEnToolTypeName NVARCHAR(200), UMToolType INT, PJTTypeCnt INT, StdSeq INT, StdSerl INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock2 = 1

END
INSERT INTO #BIZ_IN_DataBlock2 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, StdDate, StdSeq) 
SELECT N'A', 1, 1, 1, 0, NULL, NULL, N'0', N'', N'20170903', N'20'
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

SET @ServiceSeq     = 13820020
--SET @MethodSeq      = 5
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820017
SET @IsTransaction  = 1
-- InputData�� OutputData�� ����INSERT INTO #BIZ_OUT_DataBlock2(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdDate, StdSeq)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdDate, StdSeq      FROM  #BIZ_IN_DataBlock2-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTOperatorPriceDataCopyCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : End-- ExecuteOrder : 2 : StartSET @UseTransaction = N'1'BEGIN TRANEXEC    mnpt_SPJTOperatorPriceDataCopy            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0)
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
        , Result, ROW_IDX, IsChangedMst, StdDate, StdSeq  FROM #BIZ_OUT_DataBlock2 ORDER BY IDX_NO, ROW_IDX
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
DROP TABLE #BIZ_IN_DataBlock2DROP TABLE #BIZ_OUT_DataBlock2rollback 