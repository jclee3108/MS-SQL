  
IF OBJECT_ID('DTI_SESMCSlipAdjCheck') IS NOT NULL   
    DROP PROC DTI_SESMCSlipAdjCheck  
GO  
  
-- v2013.12.21 
  
-- ����ȸ����ǥ�ۼ�_DTI(üũ) by����õ   
CREATE PROC DTI_SESMCSlipAdjCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
      
    CREATE TABLE #DTI_TESMCSlipAdj( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TESMCSlipAdj'   
    IF @@ERROR <> 0 RETURN     
    
    -- üũ1, ��������� �����Ǿ� ����,����,������ �� �� �����ϴ�. 
    
    UPDATE A
       SET Result = N'��������� �����Ǿ� ����,����,������ �� �� �����ϴ�.', 
           MessageType = 1234, 
           Status = 1234
      FROM #DTI_TESMCSlipAdj AS A 
      JOIN _TESMDCostKey AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CostYM = A.CostYM AND B.SMCostMng = 5512001 ) 
      JOIN DTI_TESMBMAClosing AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CostKeySeq = B.CostKeySeq AND IsClosed = '1' AND SMClosing = 1000394004 ) 
     WHERE A.Status = 0 
    
    -- üũ1, END 
    
    -- üũ2, �������� ��뱸���� �����ϸ� ��뱸���� �ʼ� �Դϴ�.
    
    UPDATE A 
       SET Result = N'�������� ��뱸���� �����ϸ� ��뱸���� �ʼ� �Դϴ�.', 
           MessageType = 1234, 
           Status =1234
      FROM #DTI_TESMCSlipAdj AS A 
     WHERE A.Status = 0
       AND ISNULL(A.UMCostType,0) = 0  
       AND EXISTS (SELECT 1
                     FROM _TDAAccountCostType  AS B 
                    WHERE B.CompanySeq = @CompanySeq  
                      AND B.AccSeq = A.AccSeq 
                  )
                           
    -- üũ2, END 
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Serl    INT   
      
    SELECT @Count = COUNT(1) FROM #DTI_TESMCSlipAdj WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        SELECT @Serl = ISNULL((SELECT MAX(B.Serl) 
                                FROM #DTI_TESMCSlipAdj AS A
                                JOIN DTI_TESMCSlipAdj  AS B ON ( B.CompanySeq = @CompanySeq AND B.CostUnit = A.CostUnit AND B.CostYM = A.CostYM ) 
                              ),0)
        UPDATE #DTI_TESMCSlipAdj  
           SET Serl = @Serl + DataSeq--,  
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   

      
    SELECT * FROM #DTI_TESMCSlipAdj   
      
    RETURN  
GO
exec DTI_SESMCSlipAdjCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <CostYM>201312</CostYM>
    <AccName>�Ǹ�������</AccName>
    <UMCostTypeName />
    <CCtrName>(����) �׽�Ʈ - 1130</CCtrName>
    <DrAmt>10000</DrAmt>
    <CrAmt>0</CrAmt>
    <Summary>test</Summary>
    <SlipNo>A0-S1-20131216-0009-001</SlipNo>
    <SlipAmt>100</SlipAmt>
    <SlipSeq>1001426</SlipSeq>
    <AccSeq>762</AccSeq>
    <UMCostType>0</UMCostType>
    <CCtrSeq>1121</CCtrSeq>
    <Serl>0</Serl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <CostUnit>1</CostUnit>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019994,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016860