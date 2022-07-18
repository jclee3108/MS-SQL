  
IF OBJECT_ID('KPX_SEQChangeCmmReviewEmpCHESave') IS NOT NULL   
    DROP PROC KPX_SEQChangeCmmReviewEmpCHESave  
GO  
  
-- v2014.12.12  
  
-- ��������ȸȸ�Ƿϵ��- ������ ���� by ����õ   
CREATE PROC KPX_SEQChangeCmmReviewEmpCHESave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPX_TEQChangeCmmReviewEmpCHE( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TEQChangeCmmReviewEmpCHE'   
    IF @@ERROR <> 0 RETURN     
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TEQChangeCmmReviewEmpCHE')    
    
    IF @WorkingTag = 'Del' 
    BEGIN 
        
        EXEC _SCOMLog @CompanySeq   ,        
             @UserSeq      ,        
             'KPX_TEQChangeCmmReviewEmpCHE'    , -- ���̺��        
             '#KPX_TEQChangeCmmReviewEmpCHE'    , -- �ӽ� ���̺��        
             'ReviewSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
             @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ�� 
    
    END 
    ELSE 
    BEGIN 
    
        EXEC _SCOMLog @CompanySeq   ,        
              @UserSeq      ,        
              'KPX_TEQChangeCmmReviewEmpCHE'    , -- ���̺��        
              '#KPX_TEQChangeCmmReviewEmpCHE'    , -- �ӽ� ���̺��        
              'ReviewSeq,EmpSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
              @TableColumns , 'ReviewSeq,EmpSeqOld', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    END 
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEQChangeCmmReviewEmpCHE WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        IF @WorkingTag = 'Del' 
        BEGIN 
            
            DELETE B   
              FROM #KPX_TEQChangeCmmReviewEmpCHE AS A   
              JOIN KPX_TEQChangeCmmReviewEmpCHE AS B ON ( B.CompanySeq = @CompanySeq AND B.ReviewSeq = A.ReviewSeq )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
              
            IF @@ERROR <> 0  RETURN  
            
        END 
        ELSE 
        BEGIN
            
            DELETE B   
              FROM #KPX_TEQChangeCmmReviewEmpCHE AS A   
              JOIN KPX_TEQChangeCmmReviewEmpCHE AS B ON ( B.CompanySeq = @CompanySeq AND B.ReviewSeq = A.ReviewSeq AND B.EmpSeq = A.EmpSeqOld )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
            
            IF @@ERROR <> 0  RETURN  
        
        END 
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEQChangeCmmReviewEmpCHE WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        
        UPDATE B   
           SET B.EmpSeq = A.EmpSeq, 
               B.DeptSeq = A.DeptSeq, 
            
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()  
                 
          FROM #KPX_TEQChangeCmmReviewEmpCHE AS A   
          JOIN KPX_TEQChangeCmmReviewEmpCHE AS B ON ( B.CompanySeq = @CompanySeq AND B.ReviewSeq = A.ReviewSeq AND B.EmpSeq = A.EmpSeqOld  )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEQChangeCmmReviewEmpCHE WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TEQChangeCmmReviewEmpCHE  
        (   
            CompanySeq, ReviewSeq, EmpSeq, DeptSeq, LastUserSeq,
            LastDateTime 
        )   
        SELECT @CompanySeq, A.ReviewSeq, A.EmpSeq, A.DeptSeq, @UserSeq, 
               GETDATE()
          FROM #KPX_TEQChangeCmmReviewEmpCHE AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    UPDATE A 
       SET EmpSeqOld = EmpSeq 
      FROM #KPX_TEQChangeCmmReviewEmpCHE AS A 
    
    SELECT * FROM #KPX_TEQChangeCmmReviewEmpCHE   
      
    RETURN  
    go
    
    begin tran 
    
    exec KPX_SEQChangeCmmReviewEmpCHESave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <DeptSeq>1300</DeptSeq>
    <EmpSeq>2028</EmpSeq>
    <IsJoin>0</IsJoin>
    <ReviewSeq>1</ReviewSeq>
    <EmpSeqOld>0</EmpSeqOld>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <DeptSeq>1679</DeptSeq>
    <EmpSeq>2017</EmpSeq>
    <IsJoin>0</IsJoin>
    <ReviewSeq>1</ReviewSeq>
    <EmpSeqOld>0</EmpSeqOld>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026713,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021388
rollback 