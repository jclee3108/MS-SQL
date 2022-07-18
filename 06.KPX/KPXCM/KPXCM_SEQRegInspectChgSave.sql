  
IF OBJECT_ID('KPXCM_SEQRegInspectChgSave') IS NOT NULL   
    DROP PROC KPXCM_SEQRegInspectChgSave  
GO  
  
-- v2015.07.01  
  
-- ����˻��ȹ�������-���� by ����õ   
CREATE PROC KPXCM_SEQRegInspectChgSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPXCM_TEQRegInspectChg (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQRegInspectChg'   
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQRegInspectChg')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TEQRegInspectChg'    , -- ���̺��        
                  '#KPXCM_TEQRegInspectChg'    , -- �ӽ� ���̺��        
                  'RegInspectSeq,QCPlanDate'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQRegInspectChg WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPXCM_TEQRegInspectChg AS A   
          JOIN KPXCM_TEQRegInspectChg AS B ON ( B.CompanySeq = @CompanySeq AND B.RegInspectSeq = A.RegInspectSeq AND B.QCPlanDate = A.QCPlanDate )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQRegInspectChg WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.ReplaceDate = A.ReplaceDate,  
               B.Remark = A.Remark,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
          FROM #KPXCM_TEQRegInspectChg AS A   
          JOIN KPXCM_TEQRegInspectChg AS B ON ( B.CompanySeq = @CompanySeq AND B.RegInspectSeq = A.RegInspectSeq AND B.QCPlanDate = A.QCPlanDate )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQRegInspectChg WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPXCM_TEQRegInspectChg  
        (   
            CompanySeq,RegInspectSeq,QCPlanDate,ReplaceDate,Remark,
            LastUserSeq,LastDateTime,PgmSeq   
        )   
        SELECT @CompanySeq,A.RegInspectSeq,A.QCPlanDate,A.ReplaceDate,A.Remark,
               @UserSeq,GETDATE(),@PgmSeq   
          FROM #KPXCM_TEQRegInspectChg AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    UPDATE A 
       SET A.ReplaceDateOld = A.ReplaceDate
      FROM #KPXCM_TEQRegInspectChg AS A 
    
    SELECT * FROM #KPXCM_TEQRegInspectChg   
      
    RETURN  
--    go
--    begin tran 
    
--    exec KPXCM_SEQRegInspectChgSave @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <QCPlanDate>20150719</QCPlanDate>
--    <RegInspectSeq>6</RegInspectSeq>
--    <Remark />
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1030624,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025548

--rollback 