
IF OBJECT_ID('DTI_SESMBGPCostAdjStdSave') IS NOT NULL 
    DROP PROC DTI_SESMBGPCostAdjStdSave 
GO

-- v2014.01.03 

-- ���ͺм� ������� ���ص��_DTI(����) by����õ
CREATE PROC dbo.DTI_SESMBGPCostAdjStdSave
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

    -- DELETE
    IF EXISTS (SELECT TOP 1 1 FROM #DTI_TESMBGPCostAdjStd WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
        IF @WorkingTag = 'SheetDel'
        BEGIN 
            DELETE B
              FROM #DTI_TESMBGPCostAdjStd   AS A 
              JOIN DTI_TESMBGPCostAdjStd    AS B ON ( B.CompanySeq = @CompanySeq 
                                                  AND A.CostYM = B.CostYM 
                                                  AND A.CCtrSeqOld = B.CCtrSeq 
                                                  AND A.SMAccTypeOld = B.SMAccType 
                                                    ) 
             WHERE B.CompanySeq  = @CompanySeq
               AND A.WorkingTag  = 'D' 
               AND A.Status      = 0    
        
            IF @@ERROR <> 0  RETURN
        END
        ELSE
        BEGIN 
            DELETE B
              FROM #DTI_TESMBGPCostAdjStd   AS A 
              JOIN DTI_TESMBGPCostAdjStd    AS B ON ( B.CompanySeq = @CompanySeq AND A.CostYM = B.CostYM ) 
             WHERE B.CompanySeq  = @CompanySeq
               AND A.WorkingTag  = 'D' 
               AND A.Status      = 0    

            IF @@ERROR <> 0  RETURN 
        END
    END  

    -- UPDATE    
    IF EXISTS (SELECT 1 FROM #DTI_TESMBGPCostAdjStd WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN
        UPDATE B
           SET SMAccType    = A.SMAccType, 
               AdjCCtrSeq   = A.AdjCCtrSeq, 
               CCtrSeq      = A.CCtrSeq, 
               LastUserSeq  = @UserSeq, 
               LastDateTime = GetDate()
          FROM #DTI_TESMBGPCostAdjStd   AS A 
          JOIN DTI_TESMBGPCostAdjStd    AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq 
                                                           AND A.CostYM = B.CostYM 
                                                           AND A.CCtrSeqOld = B.CCtrSeq 
                                                           AND A.SMAccTypeOld = B.SMAccType 
                                                             ) 
         WHERE B.CompanySeq = @CompanySeq
           AND A.WorkingTag = 'U' 
           AND A.Status     = 0    
        
        IF @@ERROR <> 0  RETURN
    END  

    -- INSERT
    IF EXISTS (SELECT 1 FROM #DTI_TESMBGPCostAdjStd WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        INSERT INTO DTI_TESMBGPCostAdjStd 
                   (
                        CompanySeq , CCtrSeq , AdjCCtrSeq , SMAccType, CostYM , 
                        LastUserSeq , LastDateTime, PgmSeq
                   ) 
        SELECT @CompanySeq, A.CCtrSeq, A.AdjCCtrSeq, A.SMAccType, A.CostYM,
               @UserSeq ,GETDATE(), @PgmSeq 
          FROM #DTI_TESMBGPCostAdjStd AS A   
         WHERE A.WorkingTag = 'A' 
           AND A.Status = 0    
        
        IF @@ERROR <> 0 RETURN
    END   
    
    UPDATE A 
       SET CCtrSeqOld = CCtrSeq, 
           SMAccTypeOld = SMAccType
      FROM #DTI_TESMBGPCostAdjStd AS A 
     WHERE A.WorkingTag = 'A' 
       AND A.Status = 0 
      
    
    SELECT * FROM #DTI_TESMBGPCostAdjStd 
    
    RETURN 
go
begin tran
exec DTI_SESMBGPCostAdjStdSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AdjCCtrName>(������ ������Ʈ)</AdjCCtrName>
    <AdjCCtrSeq>618</AdjCCtrSeq>
    <CCtrName>[2009] ������ġ�ý� ��ä������</CCtrName>
    <CCtrSeq>958</CCtrSeq>
    <SMAccType>1000395002</SMAccType>
    <SMAccTypeName>��������2</SMAccTypeName>
    <CCtrSeqOld>958</CCtrSeqOld>
    <SMAccTypeOld>1000395002</SMAccTypeOld>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1020337,@WorkingTag=N'SheetDel',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1017104
select * from DTI_TESMBGPCostAdjStd where companyseq = 1 
rollback 