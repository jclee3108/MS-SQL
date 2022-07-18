  
IF OBJECT_ID('KPXCM_SEQRegInspectRstSave') IS NOT NULL   
    DROP PROC KPXCM_SEQRegInspectRstSave  
GO  
  
-- v2015.07.03  
  
-- ����˻系�����-���� by ����õ   
CREATE PROC KPXCM_SEQRegInspectRstSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPXCM_TEQRegInspectRst (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQRegInspectRst'   
    IF @@ERROR <> 0 RETURN    
    
    CREATE TABLE #KPXCM_TEQRegInspectRstSub( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TEQRegInspectRstSub'   
    IF @@ERROR <> 0 RETURN  
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQRegInspectRst')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TEQRegInspectRst'    , -- ���̺��        
                  '#KPXCM_TEQRegInspectRst'    , -- �ӽ� ���̺��        
                  'RegInspectSeq,QCDate'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQRegInspectRst WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPXCM_TEQRegInspectRst AS A   
          JOIN KPXCM_TEQRegInspectRst AS B ON ( B.CompanySeq = @CompanySeq AND B.RegInspectSeq = A.RegInspectSeq AND B.QCDate = A.QCDate )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQRegInspectRst WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        
        UPDATE B   
           SET B.QCResultDate = A.QCResultDate, 
               B.Remark = A.Remark,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
          FROM #KPXCM_TEQRegInspectRst AS A   
          JOIN KPXCM_TEQRegInspectRst AS B ON ( B.CompanySeq = @CompanySeq AND B.RegInspectSeq = A.RegInspectSeq AND B.QCDate = A.QCDate )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQRegInspectRst WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPXCM_TEQRegInspectRst  
        (   
            CompanySeq,RegInspectSeq,QCDate,QCResultDate,Remark,
            FileSeq,LastUserSeq,LastDateTime,PgmSeq   
        )   
        SELECT @CompanySeq,A.RegInspectSeq,A.QCDate,A.QCResultDate,A.Remark,
               0,@UserSeq,GETDATE(),@PgmSeq   
          FROM #KPXCM_TEQRegInspectRst AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    UPDATE A 
       SET QCResultDateOld = QCResultDate 
      FROM #KPXCM_TEQRegInspectRst AS A 
     WHERE A.Status = 0 
    
    
    
    IF EXISTS (SELECT 1 FROM #KPXCM_TEQRegInspectRstSub WHERE ToolSeqSub <> 0) 
          AND EXISTS (SELECT 1 
                        FROM #KPXCM_TEQRegInspectRstSub  AS A 
                        JOIN KPXCM_TEQRegInspectRst      AS B ON ( B.CompanySeq = @CompanySeq AND B.RegInspectSeq = A.RegInspectSeq AND B.QCDate = A.QCDate ) 
                       WHERE A.FileSeq <> B.FileSeq 
                     ) 
    BEGIN 
    
        
        UPDATE A 
           SET WorkingTag = 'U'
          FROM #KPXCM_TEQRegInspectRstSub AS A 
        
        
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPXCM_TEQRegInspectRst'    , -- ���̺��        
                      '#KPXCM_TEQRegInspectRstSub'    , -- �ӽ� ���̺��        
                      'RegInspectSeq,QCDate'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                      @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
        
        UPDATE B   
           SET B.FileSeq = A.FileSeq, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
          FROM #KPXCM_TEQRegInspectRstSub   AS A   
          JOIN KPXCM_TEQRegInspectRst       AS B ON ( B.CompanySeq = @CompanySeq AND B.RegInspectSeq = A.RegInspectSeq AND B.QCDate = A.QCDate )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
    
    END 
    
    
    SELECT * FROM #KPXCM_TEQRegInspectRst   
    
    SELECT * FROM #KPXCM_TEQRegInspectRstSub
    
    RETURN  
GO 
--begin tran 
--exec KPXCM_SEQRegInspectRstSave @xmlDocument=N'<ROOT>
--  <DataBlock2>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Selected>1</Selected>
--    <Status>0</Status>
--    <FileSeq>0</FileSeq>
--    <ToolNameSub />
--    <ToolNoSub />
--    <ToolSeqSub>0</ToolSeqSub>
--    <QCDate>20150720</QCDate>
--    <RegInspectSeq>6</RegInspectSeq>
--  </DataBlock2>
--  <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>2</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <EmpName>doan</EmpName>
--    <EmpSeq>276</EmpSeq>
--    <FactUnitName>�ƻ����</FactUnitName>
--    <LastQCDate>20150711</LastQCDate>
--    <QCDate>20150712</QCDate>
--    <Remark>sdgsdg</Remark>
--    <Spec>txxt</Spec>
--    <ToolName>����111</ToolName>
--    <ToolNo>Lie111</ToolNo>
--    <ToolSeq>74</ToolSeq>
--    <UMLicense>1011263002</UMLicense>
--    <UMLicenseName>�ڰ�����2</UMLicenseName>
--    <UMQCCompany>1011262003</UMQCCompany>
--    <UMQCCompanyName>�˻���3</UMQCCompanyName>
--    <UMQCCycle>1011264001</UMQCCycle>
--    <UMQCCycleName>��</UMQCCycleName>
--    <UMQCName>�˻��2</UMQCName>
--    <UMQCSeq>1011261002</UMQCSeq>
--    <RegInspectSeq>7</RegInspectSeq>
--    <QCDateOld xml:space="preserve">        </QCDateOld>
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1030662,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025556
--rollback 