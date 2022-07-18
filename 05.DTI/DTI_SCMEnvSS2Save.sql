
IF OBJECT_ID('DTI_SCMEnvSS2Save') IS NOT NULL 
    DROP PROC DTI_SCMEnvSS2Save 
GO 

-- v2013.12.27 

-- ȯ�漳��_DTI(SS2����) by����õ
CREATE PROC DTI_SCMEnvSS2Save
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0
AS   
    
    CREATE TABLE #DTI_TCOMEnvContractEmp (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#DTI_TCOMEnvContractEmp'     
    IF @@ERROR <> 0 RETURN  
    
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
    EXEC _SCOMLog  @CompanySeq   ,
                   @UserSeq      ,
                   'DTI_TCOMEnvContractEmp', -- �����̺��
                   '#DTI_TCOMEnvContractEmp', -- �������̺��
                   'DeptSeq' , -- Ű�� �������� ���� , �� �����Ѵ�. 
                   'CompanySeq, DeptSeq,EmpSeq,
                   LastUserSeq,LastDateTime',
                   '',
                   @PgmSeq
    
    -- DELETE    
    IF EXISTS (SELECT TOP 1 1 FROM #DTI_TCOMEnvContractEmp WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
        DELETE B
          FROM #DTI_TCOMEnvContractEmp      AS A 
          JOIN DTI_TCOMEnvContractEmp AS B ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeqOld AND B.EmpSeq = A.EmpSeqOld ) 
         WHERE B.CompanySeq  = @CompanySeq
           AND A.WorkingTag  = 'D' 
           AND A.Status      = 0 
        
        IF @@ERROR <> 0  RETURN
    END  

    -- UPDATE    
    IF EXISTS (SELECT 1 FROM #DTI_TCOMEnvContractEmp WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN
        UPDATE B
           SET DeptSeq = A.DeptSeq, 
               EmpSeq = A.EmpSeq, 
               LastUserSeq  = @UserSeq,
               LastDateTime = GetDate()
          FROM #DTI_TCOMEnvContractEmp      AS A 
               JOIN DTI_TCOMEnvContractEmp AS B ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeqOld AND B.EmpSeq = A.EmpSeqOld ) 
         WHERE B.CompanySeq = @CompanySeq
           AND A.WorkingTag = 'U' 
           AND A.Status     = 0    

        IF @@ERROR <> 0  RETURN
    END  

    -- INSERT
    IF EXISTS (SELECT 1 FROM #DTI_TCOMEnvContractEmp WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        INSERT INTO DTI_TCOMEnvContractEmp (CompanySeq,DeptSeq,EmpSeq,LastUserSeq,LastDateTime)
        SELECT @CompanySeq, A.DeptSeq, A.EmpSeq, @UserSeq, GETDATE() 
          FROM #DTI_TCOMEnvContractEmp AS A   
         WHERE A.WorkingTag = 'A' 
           AND A.Status = 0    
        
        IF @@ERROR <> 0 RETURN
    END   
    
    UPDATE A 
       SET EmpSeqOld = A.EmpSeq, 
           DeptSeqOld = A.DeptSeq 
      FROM #DTI_TCOMEnvContractEmp AS A
     
    SELECT * FROM #DTI_TCOMEnvContractEmp 
    
    RETURN    
GO
begin tran 
exec DTI_SCMEnvSS2Save @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <DeptSeq>19</DeptSeq>
    <EmpSeq>268</EmpSeq>
    <DeptSeqOld>19</DeptSeqOld>
    <EmpSeqOld>268</EmpSeqOld>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016063,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1013862
select * from DTI_TCOMEnvContractEmp 
rollback