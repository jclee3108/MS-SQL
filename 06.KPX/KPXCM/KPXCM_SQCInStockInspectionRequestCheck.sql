IF OBJECT_ID('KPXCM_SQCInStockInspectionRequestCheck') IS NOT NULL 
    DROP PROC KPXCM_SQCInStockInspectionRequestCheck
GO 

-- v2016.06.02 

/************************************************************
 ��  �� - ���˻��Ƿ�-Müũ
 �ۼ��� - 20141202
 �ۼ��� - ���游
************************************************************/
CREATE PROCEDURE KPXCM_SQCInStockInspectionRequestCheck
    @xmlDocument    NVARCHAR(MAX),
    @xmlFlags       INT = 0,
    @ServiceSeq     INT = 0,-- ���񽺵���Ѱ� Seq�� �Ѿ�´�.
    @WorkingTag     NVARCHAR(10)= '',
    @CompanySeq     INT = 1,
    @LanguageSeq    INT = 1,
    @UserSeq        INT = 0,
    @PgmSeq         INT = 0
AS
	DECLARE @MessageType	INT,
			@Status			INT,
			@Results		NVARCHAR(250),
			@Seq            INT,
			@Count          INT,
			@MaxNo          NVARCHAR(20),
			@BaseDate       NCHAR(8)
  					
    CREATE TABLE #QCInStock (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#QCInStock'

    SELECT @BaseDate = ReqDate FROM #QCInStock
    
    SELECT @Count = COUNT(1) FROM #QCInStock WHERE WorkingTag = 'A' --@Count������ (AND Status = 0 ����)
    IF @Count > 0        
    BEGIN          
        -- Ű�������ڵ�κ� ����          
    EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TQCTestRequest', 'ReqSeq', @Count
    
    -- ���˻��Ƿڹ�ȣ����  
    EXEC _SCOMCreateNo 'SITE', 'KPX_TQCTestRequest', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT  
    
    -- Temp Talbe �� ������ Ű�� UPDATE        
    UPDATE #QCInStock        
       SET ReqSeq = @Seq + DataSeq,
           ReqNo  = @MaxNo     
     WHERE WorkingTag = 'A'        
       AND Status = 0        
    END 

    SELECT * FROM #QCInStock
RETURN


GO


