  
IF OBJECT_ID('mnpt_SPJTOperatorPriceSubItemCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTOperatorPriceSubItemCheck  
GO  
    
-- v2017.09.19
  
-- ���������Ӵܰ��Է�-SS3üũ by ����õ
CREATE PROC mnpt_SPJTOperatorPriceSubItemCheck      
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
            @MaxSubSerl     INT 
        
    -- �ߺ����� üũ :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
                          @LanguageSeq       ,  
                          0, ''--,  -- SELECT * FROM _TCADictionary WHERE Word like '%��%'  
                          --3543, '��2'  
      
    UPDATE #BIZ_OUT_DataBlock3  
       SET Result       = @Results, 
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #BIZ_OUT_DataBlock3 AS A   
      JOIN (SELECT S.PJTTypeSeq, S.StdSeq, S.StdSerl    
              FROM (SELECT A1.PJTTypeSeq, A1.StdSeq, A1.StdSerl  
                      FROM #BIZ_OUT_DataBlock3 AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.PJTTypeSeq, A1.StdSeq, A1.StdSerl
                      FROM mnpt_TPJTOperatorPriceSubItem AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock3   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND StdSeq = A1.StdSeq  
                                                 AND StdSerl = A1.StdSerl 
                                                 AND StdSubSerl = A1.StdSubSerl
                                      )  
                   ) AS S  
             GROUP BY S.PJTTypeSeq, S.StdSeq, S.StdSerl     
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.PJTTypeSeq = B.PJTTypeSeq AND A.StdSeq = B.StdSeq AND A.StdSerl = B.StdSerl )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  


    -- Serl ä�� 
    SELECT @MaxSubSerl = MAX(A.StdSubSerl) 
      FROM mnpt_TPJTOperatorPriceSubItem AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock3 WHERE StdSeq = A.StdSeq AND StdSerl = A.StdSerl) 
    
    UPDATE A 
       SET StdSubSerl = ISNULL(@MaxSubSerl,0) + A.DataSeq
      FROM #BIZ_OUT_DataBlock3 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
    




    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #BIZ_OUT_DataBlock3   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #BIZ_OUT_DataBlock3  
     WHERE Status = 0  
       AND (( StdSeq = 0 OR StdSeq IS NULL ) 
            OR ( StdSerl = 0 OR StdSerl IS NULL )
            OR ( StdSubSerl = 0 OR StdSubSerl IS NULL )
            )
    
    RETURN  
  
  go

  begin tran 


  DECLARE   @CONST_#BIZ_IN_DataBlock1 INT
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

        , StdDate CHAR(8), Remark NVARCHAR(2000), StdSeq INT
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

        , FrStdDate CHAR(8), ToStdDate CHAR(8), StdDate CHAR(8), Remark NVARCHAR(2000), StdSeq INT
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

        , StdDate CHAR(8), UMToolTypeName NVARCHAR(200), UMEnToolTypeName NVARCHAR(200), UMToolType INT, PJTTypeCnt INT, StdSeq INT, StdSerl INT
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

        , UMToolTypeName NVARCHAR(200), UMToolType INT, PJTTypeName NVARCHAR(200), PJTTypeSeq INT, UnDayPrice DECIMAL(19, 5), UnHalfPrice DECIMAL(19, 5), UnMonthPrice DECIMAL(19, 5), DailyDayPrice DECIMAL(19, 5), DailyHalfPrice DECIMAL(19, 5), DailyMonthPrice DECIMAL(19, 5), OSDayPrice DECIMAL(19, 5), OSHalfPrice DECIMAL(19, 5), OSMonthPrice DECIMAL(19, 5), EtcDayPrice DECIMAL(19, 5)
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

        , UMToolTypeName NVARCHAR(200), UMToolType INT, PJTTypeName NVARCHAR(200), PJTTypeSeq INT, UnDayPrice DECIMAL(19, 5), UnHalfPrice DECIMAL(19, 5), UnMonthPrice DECIMAL(19, 5), DailyDayPrice DECIMAL(19, 5), DailyHalfPrice DECIMAL(19, 5), DailyMonthPrice DECIMAL(19, 5), OSDayPrice DECIMAL(19, 5), OSHalfPrice DECIMAL(19, 5), OSMonthPrice DECIMAL(19, 5), EtcDayPrice DECIMAL(19, 5), EtcHalfPrice DECIMAL(19, 5), EtcMonthPrice DECIMAL(19, 5), StdSeq INT, StdSerl INT, StdSubSerl INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock3 = 1

END

SELECT N'A', 1, 1, 0, 0, NULL, NULL, NULL, N'DataBlock3', NULL, NULL, N'����', N'2', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0' UNION ALL 
SELECT N'A', 2, 2, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, N'���񿬼Һз�2�׽�Ʈ', N'3', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0' UNION ALL 
SELECT N'A', 3, 3, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, N'������Ʈ�� ǰ����� ������Ʈ', N'1', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0'
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
--SET @MethodSeq      = 2
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820017
SET @IsTransaction  = 1
-- InputData�� OutputData�� ����
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END

IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END

IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END

IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0)
BEGIN
    --ROLLBACK TRAN
    SET @HasError = N'1'
    GOTO GOTO_END
END

IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0)
BEGIN
    --ROLLBACK TRAN
    SET @HasError = N'1'
    GOTO GOTO_END
END

IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0)
BEGIN
    --ROLLBACK TRAN
    SET @HasError = N'1'
    GOTO GOTO_END
END

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
        , Result, ROW_IDX, IsChangedMst, StdDate, Remark, StdSeq
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
        , Result, ROW_IDX, IsChangedMst, StdDate, UMToolTypeName, UMEnToolTypeName, UMToolType, PJTTypeCnt, StdSeq, StdSerl
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
        , Result, ROW_IDX, IsChangedMst, UMToolTypeName, UMToolType, PJTTypeName, PJTTypeSeq, UnDayPrice, UnHalfPrice, UnMonthPrice, DailyDayPrice, DailyHalfPrice, DailyMonthPrice, OSDayPrice, OSHalfPrice, OSMonthPrice, EtcDayPrice
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


rollback 
 