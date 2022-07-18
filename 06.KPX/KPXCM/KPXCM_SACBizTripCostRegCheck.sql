IF OBJECT_ID('KPXCM_SACBizTripCostRegCheck') IS NOT NULL 
    DROP PROC KPXCM_SACBizTripCostRegCheck
GO 

-- v2015.09.24 

-- ������(üũ) by����õ   Save As
/************************************************************  
 ��  �� - ������-�Ϲ��������_kpx : Ȯ��  
 �ۼ��� - 20150811  
 �ۼ��� - ������  
************************************************************/  
CREATE PROC KPXCM_SACBizTripCostRegCheck  
 @xmlDocument    NVARCHAR(MAX),    
 @xmlFlags       INT     = 0,    
 @ServiceSeq     INT     = 0,    
 @WorkingTag     NVARCHAR(10)= '',    
 @CompanySeq     INT     = 1,    
 @LanguageSeq    INT     = 1,    
 @UserSeq        INT     = 0,    
 @PgmSeq         INT     = 0    
  
AS     
    
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)  
    
    CREATE TABLE #KPXCM_TACBizTripCostReg (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TACBizTripCostReg'  
    
    ---------------------------  
    -- ��ǥó�� �����ʹ� �������� �Ұ�  
    ---------------------------     
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          5                  , -- �̹� @1��(��) �Ϸ�� @2�Դϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%�̹�%')      
                          @LanguageSeq       ,       
                          12,'�а���ǥó��',   -- SELECT * FROM _TCADictionary WHERE Word like '��'      
                          2529, '��'  
        
    -- �ߺ����� Check  
    UPDATE #KPXCM_TACBizTripCostReg   
       SET Status = @Status,      -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.        
           result = @Results,  
           MessageType = @MessageType       
      FROM #KPXCM_TACBizTripCostReg AS A  
      JOIN KPXCM_TACBizTripCostReg  AS A2 ON A2.CompanySeq = @CompanySeq AND A.Seq = A2.Seq  
      JOIN _TACSlipRow              AS B ON B.CompanySeq = @CompanySeq AND A2.SlipSeq = B.SlipSeq  
     WHERE A.WorkingTag IN ('D', 'U')  
       AND A.Status = 0  
       AND B.SlipSeq <> 0  
    
  
    DECLARE @MaxSeq INT,  
            @Count  INT   
    
    SELECT @Count = Count(1) FROM #KPXCM_TACBizTripCostReg WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count >0   
    BEGIN  
        EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'KPXCM_TACBizTripCostReg','Seq',@Count --rowcount    
          
       UPDATE #KPXCM_TACBizTripCostReg               
          SET Seq  = @MaxSeq + DataSeq     
        WHERE WorkingTag = 'A'              
          AND Status = 0   
    END    
    
    SELECT * FROM #KPXCM_TACBizTripCostReg   
    
    RETURN      