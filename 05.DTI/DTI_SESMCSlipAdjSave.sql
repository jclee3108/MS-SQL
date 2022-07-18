  
IF OBJECT_ID('DTI_SESMCSlipAdjSave') IS NOT NULL   
    DROP PROC DTI_SESMCSlipAdjSave  
GO  
  
-- v2013.12.18  
  
-- ����ȸ����ǥ�ۼ�_DTI-���� by ����õ   
CREATE PROC DTI_SESMCSlipAdjSave 
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #DTI_TESMCSlipAdj (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TESMCSlipAdj'   
    IF @@ERROR <> 0 RETURN    
    --SELECT * FROM #DTI_TESMCSlipAdj 
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('DTI_TESMCSlipAdj')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'DTI_TESMCSlipAdj'    , -- ���̺��        
                  '#DTI_TESMCSlipAdj'    , -- �ӽ� ���̺��        
                  'CostUnit,CostYM,Serl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #DTI_TESMCSlipAdj WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE B   
          FROM #DTI_TESMCSlipAdj AS A   
          JOIN DTI_TESMCSlipAdj AS B ON ( B.CompanySeq = @CompanySeq AND B.CostUnit = A.CostUnit AND B.CostYM = A.CostYM AND B.Serl = A.Serl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
    
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #DTI_TESMCSlipAdj WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.AccSeq         = A.AccSeq, 
               B.UMCostType     = A.UMCostType, 
               B.CCtrSeq        = A.CCtrSeq, 
               B.DrAmt          = A.DrAmt, 
               B.CrAmt          = A.CrAmt, 
               B.Summary        = A.Summary, 
               B.OrgSlipSeq     = A.SlipSeq, 
               B.LastUserSeq    = @UserSeq, 
               B.LastDateTime   = GETDATE(), 
               B.PgmSeq         = @PgmSeq 
          FROM #DTI_TESMCSlipAdj AS A   
          JOIN DTI_TESMCSlipAdj AS B ON ( B.CompanySeq = @CompanySeq AND B.CostUnit = A.CostUnit AND B.CostYM = A.CostYM AND B.Serl = A.Serl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #DTI_TESMCSlipAdj WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO DTI_TESMCSlipAdj  
        (   
            CompanySeq, CostUnit, CostYM, Serl, AccSeq, 
            UMCostType, CCtrSeq, DrAmt, CrAmt, Summary, 
            OrgSlipSeq, LastUserSeq, LastDateTime, PgmSeq 
        )   
        SELECT @CompanySeq, A.CostUnit, A.CostYM, A.Serl, A.AccSeq, 
               A.UMCostTYpe, A.CCtrSeq, A.DrAmt, A.CrAmt, A.Summary, 
               A.SlipSeq, @UserSeq, GETDATE(), @PgmSeq
        
          FROM #DTI_TESMCSlipAdj AS A 
         WHERE A.WorkingTag = 'A' 
           AND A.Status = 0 
        
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #DTI_TESMCSlipAdj   
      
    RETURN  
GO
begin tran
exec DTI_SESMCSlipAdjSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AccName>���뿹��-��ȭ</AccName>
    <AccSeq>1230</AccSeq>
    <CCtrName>(������Ʈ��)����10% - X ǰ�� ����</CCtrName>
    <CCtrSeq>1239</CCtrSeq>
    <CostUnit>1</CostUnit>
    <CostYM>201312</CostYM>
    <CrAmt>0.00000</CrAmt>
    <SlipAmt>100000.00000</SlipAmt>
    <SlipNo>A0-S1-20131203-0001-001</SlipNo>
    <SlipSeq>1001384</SlipSeq>
    <Summary>test11</Summary>
    <UMCostType>4001001</UMCostType>
    <UMCostTypeName>����</UMCostTypeName>
    <Serl>1</Serl>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019994,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016860
--select * from DTI_TESMCSlipAdj 
rollback