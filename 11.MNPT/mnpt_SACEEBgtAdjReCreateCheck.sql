  
IF OBJECT_ID('mnpt_SACEEBgtAdjReCreateCheck') IS NOT NULL   
    DROP PROC mnpt_SACEEBgtAdjReCreateCheck  
GO  
    
-- v2017.12.18
  
-- ��񿹻��Է�-����� üũ by ����õ   
CREATE PROC mnpt_SACEEBgtAdjReCreateCheck  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0    
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250), 
            @EnvValue       INT 
        
    --------------------------------------------------------------------------------------
    -- üũ1, �⿹�긶��üũ
    --------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          5                  , -- �̹� @1��(��) �Ϸ�� @2�Դϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 5)  
                          @LanguageSeq       ,   
                          0,'�⿹�긶�� ',   -- SELECT * FROM _TCADictionary WHERE Word like '%����ī���ȣ%'  
                          0,'�ڷ�'  
    UPDATE #BIZ_OUT_DataBlock1  
       SET Result        = @Results,  
           MessageType   = @MessageType,  
           Status        = @Status  
      FROM #BIZ_OUT_DataBlock1 AS A   
                JOIN _TACBgtClosing AS B WITH(NOLOCK) ON A.StdYear = B.BgtYear AND A.AccUnit = B.AccUnit   
      WHERE B.CompanySeq = @CompanySeq   
        AND B.IsCfm = '1'  
        AND Status = 0  
    --------------------------------------------------------------------------------------
    -- üũ1, END
    --------------------------------------------------------------------------------------  
    --------------------------------------------------------------------------------------
    -- üũ2, ���ΰ��� ��꿬���� ������ ���Ϸ��� ������ ��ϵǾ� ���� �ʾ��� �� 
    --------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM _TDAAccFiscal WHERE CompanySeq = @CompanySeq AND FiscalYear IN (SELECT StdYear FROM #BIZ_OUT_DataBlock1))
    BEGIN
        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                              @Status      OUTPUT,    
                              @Results     OUTPUT,    
                              1170                  , -- @1�� @2��(��) ��ϵǾ� ���� �ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%���%')    
                              @LanguageSeq       ,     
                              27121,'���ΰ��� ',   -- SELECT * FROM _TCADictionary WHERE Word like '%����%'    
                              1749,'���꿬��' -- SELECT * FROM _TCADictionary WHERE Word like '%���꿬��%'    
  
        UPDATE #BIZ_OUT_DataBlock1    
           SET Result        = @Results,    
               MessageType   = @MessageType,    
               Status        = @Status  
    END  
    --------------------------------------------------------------------------------------
    -- üũ2, END 
    --------------------------------------------------------------------------------------
    
    RETURN  

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

        , StdYear CHAR(4), AccUnitName NVARCHAR(200), AmtUnit DECIMAL(19, 5), AccUnit INT, DeptCCtrName NVARCHAR(200), AccName NVARCHAR(200), UMCostTypeName NVARCHAR(200), Month01 DECIMAL(19, 5), Month02 DECIMAL(19, 5), Month03 DECIMAL(19, 5), Month04 DECIMAL(19, 5), Month05 DECIMAL(19, 5), Month06 DECIMAL(19, 5), Month07 DECIMAL(19, 5), Month08 DECIMAL(19, 5), Month09 DECIMAL(19, 5), Month10 DECIMAL(19, 5), Month11 DECIMAL(19, 5), Month12 DECIMAL(19, 5), MonthSum DECIMAL(19, 5), DeptCCtrSeq INT, AccSeq INT, UMCostType INT, AdjSeq INT, DeptSeq INT, CCtrSeq INT
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

        , StdYear CHAR(4), AccUnitName NVARCHAR(200), AmtUnit DECIMAL(19, 5), AccUnit INT, DeptCCtrName NVARCHAR(200), AccName NVARCHAR(200), UMCostTypeName NVARCHAR(200), Month01 DECIMAL(19, 5), Month02 DECIMAL(19, 5), Month03 DECIMAL(19, 5), Month04 DECIMAL(19, 5), Month05 DECIMAL(19, 5), Month06 DECIMAL(19, 5), Month07 DECIMAL(19, 5), Month08 DECIMAL(19, 5), Month09 DECIMAL(19, 5), Month10 DECIMAL(19, 5), Month11 DECIMAL(19, 5), Month12 DECIMAL(19, 5), MonthSum DECIMAL(19, 5), DeptCCtrSeq INT, AccSeq INT, UMCostType INT, AdjSeq INT, DeptSeq INT, CCtrSeq INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
DECLARE   @INPUT_ERROR_MESSAGE    NVARCHAR(4000)
        , @INPUT_ERROR_SEVERITY   INT
        , @INPUT_ERROR_STATE      INT
        , @INPUT_ERROR_PROCEDURE  NVARCHAR(128)
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, StdYear, AccUnitName, AmtUnit, AccUnit, DeptCCtrName, AccName, UMCostTypeName, Month01, Month02, Month03, Month04, Month05, Month06, Month07, Month08, Month09, Month10, Month11, Month12, MonthSum, DeptCCtrSeq, AccSeq, UMCostType, AdjSeq, DeptSeq, CCtrSeq) 
SELECT N'A', 3, 1, 0, 0, NULL, NULL, NULL, N'DataBlock1', N'2019', NULL, N'1000', N'1', N'���ƺμ�', N'�����Ļ���', N'�ǰ�', N'4', N'2', N'2', N'2', N'2', N'2', N'2', N'2', N'2', N'2', N'2', N'2', N'26', N'2', N'212', N'4001002', N'0', NULL, NULL
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

SET @ServiceSeq     = 13820089
--SET @MethodSeq      = 2
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820092
SET @IsTransaction  = 1
-- InputData�� OutputData�� ����INSERT INTO #BIZ_OUT_DataBlock1(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdYear, AccUnitName, AmtUnit, AccUnit, DeptCCtrName, AccName, UMCostTypeName, Month01, Month02, Month03, Month04, Month05, Month06, Month07, Month08, Month09, Month10, Month11, Month12, MonthSum, DeptCCtrSeq, AccSeq, UMCostType, AdjSeq, DeptSeq, CCtrSeq)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdYear, AccUnitName, AmtUnit, AccUnit, DeptCCtrName, AccName, UMCostTypeName, Month01, Month02, Month03, Month04, Month05, Month06, Month07, Month08, Month09, Month10, Month11, Month12, MonthSum, DeptCCtrSeq, AccSeq, UMCostType, AdjSeq, DeptSeq, CCtrSeq      FROM  #BIZ_IN_DataBlock1-- ExecuteOrder : 1 : StartEXEC    mnpt_SACEEBgtAdjCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : End-- ExecuteOrder : 2 : StartSET @UseTransaction = N'1'BEGIN TRANEXEC    mnpt_SACEEBgtAdjSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0)
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
        , Result, ROW_IDX, IsChangedMst, StdYear, AccUnitName, AmtUnit, AccUnit, DeptCCtrName, AccName, UMCostTypeName, Month01, Month02, Month03, Month04, Month05, Month06, Month07, Month08, Month09, Month10, Month11, Month12, MonthSum, DeptCCtrSeq, AccSeq, UMCostType, AdjSeq, DeptSeq, CCtrSeq  FROM #BIZ_OUT_DataBlock1 ORDER BY IDX_NO, ROW_IDX
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