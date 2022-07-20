  
IF OBJECT_ID('mnpt_SPJTOperatorPriceSave') IS NOT NULL   
    DROP PROC mnpt_SPJTOperatorPriceSave  
GO  
    
-- v2017.09.19
  
-- ���������Ӵܰ��Է�-SS1���� by ����õ
CREATE PROC mnpt_SPJTOperatorPriceSave
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       

    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTOperatorPriceMaster')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTOperatorPriceMaster'    , -- ���̺���        
                  '#BIZ_OUT_DataBlock1'    , -- �ӽ� ���̺���        
                  'StdSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock1          AS A   
          JOIN mnpt_TPJTOperatorPriceMaster AS B ON ( B.CompanySeq = @CompanySeq AND A.StdSeq = B.StdSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN 
        

        --------------------------------------------------------------
        -- ������ ������ ������ �α׳����, Srt
        --------------------------------------------------------------
        SELECT A.WorkingTag, 
               A.Status, 
               A.StdSeq, 
               B.StdSerl
          INTO #ItemLog 
          FROM #BIZ_OUT_DataBlock1      AS A 
          JOIN mnpt_TPJTOperatorPriceItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq )
         WHERE A.Status = 0 
           AND A.WorkingTag = 'D' 

        SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTOperatorPriceItem')    
      
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'mnpt_TPJTOperatorPriceItem'    , -- ���̺���        
                      '#ItemLog'    , -- �ӽ� ���̺���        
                      'StdSeq,StdSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                      @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
        --------------------------------------------------------------
        -- ������ ������ ������ �α׳����, End
        --------------------------------------------------------------
        
        DELETE B 
          FROM #BIZ_OUT_DataBlock1          AS A   
          JOIN mnpt_TPJTOperatorPriceItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  

        --------------------------------------------------------------
        -- ������ ������ ������ �α׳����, Srt
        --------------------------------------------------------------
        SELECT A.WorkingTag, 
               A.Status, 
               A.StdSeq, 
               B.StdSerl, 
               B.StdSubSerl
          INTO #SubItemLog 
          FROM #BIZ_OUT_DataBlock1      AS A 
          JOIN mnpt_TPJTOperatorPriceSubItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq )
         WHERE A.Status = 0 
           AND A.WorkingTag = 'D' 

        SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTOperatorPriceSubItem')    
      
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'mnpt_TPJTOperatorPriceSubItem'    , -- ���̺���        
                      '#SubItemLog'    , -- �ӽ� ���̺���        
                      'StdSeq,StdSerl,StdSubSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                      @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
        --------------------------------------------------------------
        -- ������ ������ ������ �α׳����, End
        --------------------------------------------------------------
        
        DELETE B   
          FROM #BIZ_OUT_DataBlock1      AS A   
          JOIN mnpt_TPJTOperatorPriceSubItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.StdDate        = A.StdDate ,  
               B.Remark         = A.Remark  ,  
               B.LastUserSeq    = @UserSeq  ,  
               B.LastDateTime   = GETDATE() ,
               B.PgmSeq         = @PgmSeq   
          FROM #BIZ_OUT_DataBlock1  AS A   
          JOIN mnpt_TPJTOperatorPriceMaster    AS B ON ( B.CompanySeq = @CompanySeq AND A.StdSeq = B.StdSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    

    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO mnpt_TPJTOperatorPriceMaster  
        (   
            Companyseq, StdSeq, StdDate, Remark, FirstUserSeq, 
            FirstDateTime, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @Companyseq, StdSeq, StdDate, Remark, @UserSeq, 
               GETDATE(), @UserSeq, GETDATE(), @PgmSeq
          FROM #BIZ_OUT_DataBlock1 AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
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

        , UMToolTypeName NVARCHAR(200), UMToolType INT, PJTTypeName NVARCHAR(200), PJTTypeSeq INT, UnDayPrice DECIMAL(19, 5), UnHalfPrice DECIMAL(19, 5), UnMonthPrice DECIMAL(19, 5), DailyDayPrice DECIMAL(19, 5), DailyHalfPrice DECIMAL(19, 5), DailyMonthPrice DECIMAL(19, 5), OSDayPrice DECIMAL(19, 5), OSHalfPrice DECIMAL(19, 5), OSMonthPrice DECIMAL(19, 5), EtcDayPrice DECIMAL(19, 5), EtcHalfPrice DECIMAL(19, 5), EtcMonthPrice DECIMAL(19, 5), StdSeq INT, StdSerl INT, StdSubSerl INT
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

SELECT N'A', 1, 1, 0, 0, NULL, NULL, NULL, N'DataBlock1', N'20170901', N'', N'0'
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
        , Result, ROW_IDX, IsChangedMst, UMToolTypeName, UMToolType, PJTTypeName, PJTTypeSeq, UnDayPrice, UnHalfPrice, UnMonthPrice, DailyDayPrice, DailyHalfPrice, DailyMonthPrice, OSDayPrice, OSHalfPrice, OSMonthPrice, EtcDayPrice, EtcHalfPrice, EtcMonthPrice, StdSeq, StdSerl, StdSubSerl
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
