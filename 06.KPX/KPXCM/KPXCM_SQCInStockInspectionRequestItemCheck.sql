IF OBJECT_ID('KPXCM_SQCInStockInspectionRequestItemCheck') IS NOT NULL 
    DROP PROC KPXCM_SQCInStockInspectionRequestItemCheck
GO 

-- v2016.06.02 
/************************************************************
 ��  �� - ���˻��Ƿ�-Itemüũ
 �ۼ��� - 20141202
 �ۼ��� - ���游
************************************************************/
CREATE PROCEDURE KPXCM_SQCInStockInspectionRequestItemCheck
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
			@BaseDate       NCHAR(8),
			@MaxSerl        INT,
			@ReqSeq         INT
  					
    CREATE TABLE #QCInStockItem (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#QCInStockItem'
    
    SELECT @ReqSeq = ReqSeq FROM #QCInStockItem

	-------------------------------------------      
	-- ���� 0 üũ
	-------------------------------------------      
	EXEC dbo._SCOMMessage @MessageType OUTPUT,      
						  @Status      OUTPUT,      
						  @Results     OUTPUT,      
						  1001                  , -- @1��(��) �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1001)      
						  @LanguageSeq       ,       
						  0,'�˻��Ƿڼ���'     -- SELECT * FROM _TCADictionary WHERE Word like '%�㺸%'              
	UPDATE A
	   SET Result        = REPLACE(@Results,'��(��)', '��'),
		   MessageType   = @MessageType,
		   Status        = @Status 
	  FROM #QCInStockItem AS A
	 WHERE ISNULL(ReqQty ,0) = 0
    
    ------------------------------------------------------------------------
    -- üũ1, LotNo�� LotNo2�� ���ÿ� �Է� �� �� �����ϴ�. 
    ------------------------------------------------------------------------
    UPDATE A 
       SET Result = 'LotNo�� LotNo2�� ���ÿ� �Է� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #QCInStockItem AS A 
     WHERE Status = 0 
       AND WorkingTag IN ( 'A', 'U' ) 
       AND LotNo <> '' 
       AND Memo1 <> '' 
    ------------------------------------------------------------------------
    -- üũ1, END 
    ------------------------------------------------------------------------
    
    ------------------------------------------------------------------------
    -- üũ2, LotNo���� ���ǰ���� �ƴϸ� LotNo2�� �ʼ��Դϴ�.
    ------------------------------------------------------------------------
    UPDATE A 
       SET Result = 'LotNo���� ���ǰ���� �ƴϸ� LotNo2�� �ʼ��Դϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #QCInStockItem   AS A 
      JOIN _TDAItemStock    AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )     
     WHERE Status = 0 
       AND WorkingTag IN ( 'A', 'U' ) 
       AND ISNULL(B.IsLotMng,'0') = '0' 
       AND Memo1 = '' 
    ------------------------------------------------------------------------
    -- üũ2, END 
    ------------------------------------------------------------------------
    
    ------------------------------------------------------------------------
    -- üũ3, LotNo���� ���ǰ���� LotNo�� �ʼ��Դϴ�.
    ------------------------------------------------------------------------
    UPDATE A 
       SET Result = 'LotNo���� ���ǰ���� LotNo�� �ʼ��Դϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #QCInStockItem   AS A 
      JOIN _TDAItemStock    AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )     
     WHERE Status = 0 
       AND WorkingTag IN ( 'A', 'U' ) 
       AND ISNULL(B.IsLotMng,'0') = '1' 
       AND LotNo = '' 
    ------------------------------------------------------------------------
    -- üũ3, END 
    ------------------------------------------------------------------------
    
    

    -- ����update---------------------------------------------------------------------------------------------------------------    
    SELECT @MaxSerl = ISNULL(MAX(ReqSerl), 0)    
      FROM KPX_TQCTestRequestItem     
     WHERE CompanySeq = @CompanySeq  
       AND ReqSeq = @ReqSeq    

    UPDATE A    
       SET ReqSerl = @MaxSerl + IDX_NO    
      FROM #QCInStockItem AS A    
     WHERE WorkingTag = 'A'     
       AND Status = 0    

    SELECT * FROM #QCInStockItem

RETURN
GO

begin tran 
exec KPXCM_SQCInStockInspectionRequestItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <QCTypeName />
    <ItemName>Lot_�ٽ��ѹ��׽�Ʈ_����õ</ItemName>
    <ItemNo>Lot_�ٽ��ѹ��׽�ƮNo_����õ</ItemNo>
    <Spec />
    <LotNo />
    <Memo1>333</Memo1>
    <WHName>T�Ϲ�â��1_����õ</WHName>
    <BizUnitName>�ƻ����</BizUnitName>
    <ReqQty>1</ReqQty>
    <UnitName>EA</UnitName>
    <RegDate />
    <CreateDate />
    <SupplyName />
    <Remark />
    <ReqSeq>84</ReqSeq>
    <ReqSerl>3</ReqSerl>
    <QCType>5</QCType>
    <ItemSeq>1052403</ItemSeq>
    <WHSeq>7534</WHSeq>
    <UnitSeq>4</UnitSeq>
    <SupplyCustSeq>0</SupplyCustSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037318,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030558
rollback 