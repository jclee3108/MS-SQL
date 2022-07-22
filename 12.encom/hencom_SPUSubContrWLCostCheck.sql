IF OBJECT_ID('hencom_SPUSubContrWLCostCheck') IS NOT NULL 
    DROP PROC hencom_SPUSubContrWLCostCheck
GO 

-- v2017.07.31 

/************************************************************
 ��  �� - ������-WL�������ó��_hencom : üũ
 �ۼ��� - 20151002
 �ۼ��� - ������
************************************************************/
CREATE PROC dbo.hencom_SPUSubContrWLCostCheck
	@xmlDocument    NVARCHAR(MAX),  
	@xmlFlags       INT     = 0,  
	@ServiceSeq     INT     = 0,  
	@WorkingTag     NVARCHAR(10)= '',  
	@CompanySeq     INT     = 1,  
	@LanguageSeq    INT     = 1,  
	@UserSeq        INT     = 0,  
	@PgmSeq         INT     = 0  
AS   
	DECLARE @MessageType	INT,
					@Status				INT,
					@Results			NVARCHAR(250)
  					
  CREATE TABLE #hencom_TPUSubContrWL (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TPUSubContrWL'
    /*����׸� ����ȭ���� ���а� �����´�. (WL���꿡 ���� ����׸񱸺�)*/
	DECLARE @SMKindSeq INT,@CostSeq INT
	
    -- �ý������� �߰������� �߰� 
	SELECT @CostSeq = MAX(B.ValueSeq), 
           @SMKindSeq = MAX(A.MinorSeq)
	FROM _TDASMinor AS A 
    JOIN _TDASMinorValue AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 )
	WHERE A.CompanySeq = @CompanySeq AND A.MajorSeq = 4503 AND A.MinorName LIKE '%WL%' -- <<��Ī���� ã��.
    

    IF @CostSeq IS NULL OR @CostSeq = 0 
    BEGIN     
        SELECT @CostSeq = MAX(A.CostSeq) FROM _TARCostAcc AS A 
        WHERE A.CompanySeq = @CompanySeq AND A.SMKindSeq = @SMKindSeq
    END 
    -- �ý������� �߰������� �߰� 
    
    UPDATE #hencom_TPUSubContrWL
    SET CostSeq = @CostSeq
    WHERE WorkingTag IN ('A','U')
	   AND Status = 0
	---------------------------
	-- �ʼ��Է� üũ
	---------------------------
	
	-- �ʼ��Է� Message �޾ƿ���
	EXEC dbo._SCOMMessage @MessageType OUTPUT,
						  @Status      OUTPUT,
						  @Results     OUTPUT,
						  1038               , -- �ʼ��Է� �׸��� �Է����� �ʾҽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ʼ�%')
						  @LanguageSeq       , 
						  0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'
	-- �ʼ��Է� Check 
	UPDATE #hencom_TPUSubContrWL
	   SET Result        = 'WL���꿡 ����� ����׸��� ��ϵ��� �ʾҽ��ϴ�.',
		   MessageType   = @MessageType,
		   Status        = @Status
	  FROM #hencom_TPUSubContrWL AS A
	 WHERE A.WorkingTag IN ('A','U')
	   AND A.Status = 0 AND ISNULL(@CostSeq,0) = 0 
  
	---------------------------
	-- �ߺ����� üũ
	---------------------------  
	-- �ߺ�üũ Message �޾ƿ���    
	EXEC dbo._SCOMMessage @MessageType OUTPUT,    
						  @Status      OUTPUT,    
						  @Results     OUTPUT,    
						  6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)    
						  @LanguageSeq       ,     
						  0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%����ī���ȣ%'    
      
	-- �ߺ����� Check
--	UPDATE #TPDOSPDelvInSubItem 
--	   SET Status = 6,      -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.      
--		   result = @Results      
--	  FROM #TPDOSPDelvInSubItem A      
--	 WHERE A.WorkingTag IN ('A', 'U')
--	   AND A.Status = 0
  -- guide : �̰��� �ߺ�üũ ������ ��������.
  -- e.g.  : 
  -- AND EXISTS (SELECT TOP 1 1 FROM _TPDOSPDelvInItemMat   
  --                           WHERE CompanySeq = @CompanySeq   
  --                             AND OSPDelvInSeq = B.OSPDelvInSeq     
  --                             AND OSPDelvInSerl = B.OSPDelvInSerl   
  --                             AND ItemSeq = B.ItemSeq  )    
          
	-- guide : �� �� 'Ű ����', '���࿩�� üũ', '�������� üũ', 'Ȯ������ üũ' ���� üũ������ �ֽ��ϴ�.
    DECLARE @MaxSeq INT,
            @Count  INT 
    SELECT @Count = Count(1) FROM #hencom_TPUSubContrWL WHERE WorkingTag = 'A' AND Status = 0
    IF @Count >0 
    BEGIN
    EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'hencom_TPUSubContrWL','WLReqSeq',@Count --rowcount  
          UPDATE #hencom_TPUSubContrWL             
             SET WLReqSeq  = @MaxSeq + DataSeq   
           WHERE WorkingTag = 'A'            
             AND Status = 0 
    END  
	SELECT * FROM #hencom_TPUSubContrWL 
RETURN

go 

exec hencom_SPUSubContrWLCostCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <DeptName>����</DeptName>
    <WLDate>20170701</WLDate>
    <WLComment />
    <ContrAmt>100</ContrAmt>
    <UMOTTypeName />
    <OTAmt>0</OTAmt>
    <UMAddPayTypeName />
    <AddPayAmt>0</AddPayAmt>
    <UMDeductionTypeName />
    <DeductionAmt>0</DeductionAmt>
    <CurVAT>10</CurVAT>
    <CostName />
    <Remark />
    <DeptSeq>45</DeptSeq>
    <WLReqSeq>0</WLReqSeq>
    <CostSeq>0</CostSeq>
    <UMOTType>0</UMOTType>
    <UMAddPayType>0</UMAddPayType>
    <UMDeductionType>0</UMDeductionType>
    <SubContrCarSeq>321</SubContrCarSeq>
    <CarNo>7302</CarNo>
    <CustSeq />
    <CustName />
    <UMCarClass>8030001</UMCarClass>
    <UMCarClassName>����</UMCarClassName>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032408,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1026829