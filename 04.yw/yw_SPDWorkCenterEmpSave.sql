  
IF OBJECT_ID('yw_SPDWorkCenterEmpSave') IS NOT NULL   
    DROP PROC yw_SPDWorkCenterEmpSave  
GO  
  
-- v.2007.07.19
  
-- ��ũ���ͺ��۾��ڵ��_YW (����) by����õ
CREATE PROC yw_SPDWorkCenterEmpSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #YW_TPDWorkCenterEmp (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TPDWorkCenterEmp'   
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('YW_TPDWorkCenterEmp')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'YW_TPDWorkCenterEmp'    , -- ���̺��        
                  '#YW_TPDWorkCenterEmp'    , -- �ӽ� ���̺��        
                  'WorkCenterSeq,EmpSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , 'WorkCenterSeq,EmpSeqOld', @PgmSeq  -- ���̺� ��� �ʵ��   
        
    -- �۾����� : DELETE -> UPDATE -> INSERT     

    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #YW_TPDWorkCenterEmp WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE B   
          FROM #YW_TPDWorkCenterEmp AS A   
          JOIN YW_TPDWorkCenterEmp  AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkCenterSeq = B.WorkCenterSeq AND A.EmpSeq = B.EmpSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    END    

    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #YW_TPDWorkCenterEmp WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.EmpSeq       = A.EmpSeq,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
          FROM #YW_TPDWorkCenterEmp AS A   
          JOIN YW_TPDWorkCenterEmp AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkCenterSeq = B.WorkCenterSeq AND A.EmpSeqOld = B.EmpSeq ) 
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
           
        IF @@ERROR <> 0  RETURN  
        
        UPDATE #YW_TPDWorkCenterEmp
           SET EmpSeqOld = A.EmpSeq
          FROM #YW_TPDWorkCenterEmp AS A
         WHERE WorkingTag = 'U'
           AND Status = 0
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #YW_TPDWorkCenterEmp WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO YW_TPDWorkCenterEmp  
        (   
            CompanySeq, WorkCenterSeq, EmpSeq, LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.WorkCenterSeq, A.EmpSeq, @UserSeq, GETDATE()
          FROM #YW_TPDWorkCenterEmp AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  

        UPDATE #YW_TPDWorkCenterEmp
           SET EmpSeqOld = A.EmpSeq
          FROM #YW_TPDWorkCenterEmp AS A
         WHERE WorkingTag = 'A'
           AND Status = 0
    
    END     
      
    SELECT * FROM #YW_TPDWorkCenterEmp   
      
    RETURN 
GO

begin tran 
exec yw_SPDWorkCenterEmpSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <WorkCenterSeq>1</WorkCenterSeq>
    <EmpName>����õ</EmpName>
    <EmpSeq>2028</EmpSeq>
    <EmpSeqOld>2029</EmpSeqOld>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016735,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014291
rollback tran