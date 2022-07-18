
IF OBJECT_ID('KPX_SSLReceiptPlanExpCheck') IS NOT NULL 
    DROP PROC KPX_SSLReceiptPlanExpCheck
GO 

-- v2014.12.19 
    
-- ä�Ǽ��ݰ�ȹ(����)-üũ by ����õ     
CREATE PROC KPX_SSLReceiptPlanExpCheck    
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
        
    CREATE TABLE #KPX_TLReceiptPlanDom( WorkingTag NCHAR(1) NULL )      
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TLReceiptPlanDom'     
    IF @@ERROR <> 0 RETURN       
        
    -- ��ȣ+�ڵ� ���� :             
    DECLARE @Count  INT,    
            @Seq    INT     
        
    SELECT @Count = COUNT(1) FROM #KPX_TLReceiptPlanDom WHERE WorkingTag = 'A' AND Status = 0    
        
    IF @Count > 0    
    BEGIN    
        -- Ű�������ڵ�κ� ����    
        SELECT @Seq = (  
                       SELECT MAX(B.Serl)   
                         FROM #KPX_TLReceiptPlanDom    AS A   
                         JOIN KPX_TLReceiptPlanDom     AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanYM = A.PlanYM AND B.PlanType = '1' )   
                      )  
        -- Temp Talbe �� ������ Ű�� UPDATE    
        UPDATE #KPX_TLReceiptPlanDom    
           SET Serl = ISNULL(@Seq,0) + DataSeq       
         WHERE WorkingTag = 'A'    
           AND Status = 0    
        
    END -- end if     
  
    SELECT * FROM #KPX_TLReceiptPlanDom     
        
    RETURN    