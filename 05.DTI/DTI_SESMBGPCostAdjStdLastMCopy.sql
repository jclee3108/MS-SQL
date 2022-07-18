
IF OBJECT_ID('DTI_SESMBGPCostAdjStdLastMCopy') IS NOT NULL 
    DROP PROC DTI_SESMBGPCostAdjStdLastMCopy 
GO

-- v2014.01.03 

-- ���ͺм� ������� ���ص��_DTI(��������) by����õ
CREATE PROC dbo.DTI_SESMBGPCostAdjStdLastMCopy
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS   
    
    CREATE TABLE #DTI_TESMBGPCostAdjStd (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TESMBGPCostAdjStd'     
    IF @@ERROR <> 0 RETURN  
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('DTI_TESMBGPCostAdjStd')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'DTI_TESMBGPCostAdjStd'    , -- ���̺��        
                  '#DTI_TESMBGPCostAdjStd'    , -- �ӽ� ���̺��        
                  'CostYM,CCtrSeq,SMAccType'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
      --select @WorkingTag, * from #DTI_TESMBGPCostAdjStd 
      
    DELETE A 
      FROM DTI_TESMBGPCostAdjStd AS A 
      JOIN #DTI_TESMBGPCostAdjStd AS B ON ( B.CostYM = A.CostYM ) 
     WHERE A.CompanySeq = @CompanySeq 
    
    INSERT INTO DTI_TESMBGPCostAdjStd 
               (
                    CompanySeq , CCtrSeq , AdjCCtrSeq , SMAccType, CostYM , 
                    LastUserSeq , LastDateTime, PgmSeq
               ) 
    SELECT @CompanySeq, A.CCtrSeq, A.AdjCCtrSeq, A.SMAccType, CONVERT(NCHAR(6),DATEADD(MONTH, 1, CONVERT(NCHAR(6),A.CostYM) + '01'),112)  , 
           @UserSeq, GETDATE(), @PgmSeq 
      FROM DTI_TESMBGPCostAdjStd AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.CostYM = (SELECT CONVERT(NCHAR(6),DATEADD(MONTH, -1, CONVERT(NCHAR(6),CostYM) + '01'),112) FROM #DTI_TESMBGPCostAdjStd)
    return 
 
    RETURN    
GO
begin tran 
exec DTI_SESMBGPCostAdjStdLastMCopy @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <CostYM>201402</CostYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1020337,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1017104
select * from DTI_TESMBGPCostAdjStd 
rollback 