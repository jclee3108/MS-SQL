IF OBJECT_ID('_SCOMGroupWareStart_hyei') IS NOT NULl 
    DROP PROC _SCOMGroupWareStart_hyei
GO 

-- v2017.01.04 

-- Start site sp
CREATE PROCEDURE dbo._SCOMGroupWareStart_hyei
    @CompanySeq     INT = 1,
    @LanguageSeq    INT = 1,
    @UserSeq        INT = 0,
    @WorkKind       NVARCHAR(40) = '',
    @TblKey         NVARCHAR(MAX) = '', -- ',' �����Ͽ� ������ ����
    @PgmSeq         INT = 0,
    @WorkingTag     NCHAR(1) = 'Q',
    @MessageType    INT			    OUTPUT,
	@Status         INT			    OUTPUT,
	@Results        NVARCHAR(250)	OUTPUT  
AS    
  
    -- ���� ����  
    DECLARE @TblKeyTmp       NVARCHAR(40),             
            @IsConfirm       NCHAR(1),  
            @ConfirmSeq      INT,  
            @IsProg          NCHAR(1),  
            @ProgSeq         INT,  
            @SQL             NVARCHAR(1000),  
            @ProgSQL         NVARCHAR(1000),  
            @EndSQL          NVARCHAR(1000),  
            @CancelSQL       NVARCHAR(1000),  
            @ERPNextCheckSQL NVARCHAR(1000),  
            @TableName       NVARCHAR(100),  
            @Seq             NVARCHAR(10),  
            @Serl            NVARCHAR(10),  
            @SubSerl         NVARCHAR(10),
            @GroupKey        NVARCHAR(20),
            @SheetSelectColumnName NVARCHAR(100)  ,
            @TblKeyCheck     NVARCHAR(40),
            @btnName         NVARCHAR(100),
            @SiteInit        NVARCHAR(40),
            @SP              NVARCHAR(100)
  
    SELECT @Status      = 0 ,
           @Results     = '',
           @MessageType = 0 
    
    
    --hye�� ���� ���ڰ���� ���� �߰�.
    IF @WorkKind = 'Order_hye'
    BEGIN
        
       IF (SELECT A.UMApproStatus FROM hye_TSLOrderAdd AS A WHERE A.CompanySeq = @CompanySeq AND A.OrderSeq   = @TblKey) IN (1013853001,1013853004)
       BEGIN
            
            SELECT @Status  =  999
                  ,@Results = '�Ǹ�ǰ�� ����� �ƴմϴ�.'       
            
           SELECT @Status AS Status,REPLACE(@Results, '@3', '') AS Results,@MessageType AS MessageType, @TblKey AS TblKey
           RETURN      
       END
       ELSE
       BEGIN
            SELECT @Status AS Status, @Results AS Results,@MessageType AS MessageType, @TblKey AS TblKey
       END 
        
    END
    ELSE 
    BEGIN
        SELECT @Status AS Status, @Results AS Results,@MessageType AS MessageType, @TblKey AS TblKey
    END 

RETURN
GO
exec _SCOMGroupWareStart 1,1,1,'Order_hye','11701','77730006','Q','0','0','0'   