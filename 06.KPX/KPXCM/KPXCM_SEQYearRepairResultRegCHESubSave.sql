  
IF OBJECT_ID('KPXCM_SEQYearRepairResultRegCHESubSave') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairResultRegCHESubSave  
GO  
  
-- v2015.07.18

-- ���������������-Sub���� by ����õ 
CREATE PROC KPXCM_SEQYearRepairResultRegCHESubSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPXCM_TEQYearRepairRltManHourCHE (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPXCM_TEQYearRepairRltManHourCHE'   
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQYearRepairRltManHourCHE')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TEQYearRepairRltManHourCHE'    , -- ���̺��        
                  '#KPXCM_TEQYearRepairRltManHourCHE'    , -- �ӽ� ���̺��        
                  'ResultSeq,ResultSerl,ResultSubSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairRltManHourCHE WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPXCM_TEQYearRepairRltManHourCHE AS A   
          JOIN KPXCM_TEQYearRepairRltManHourCHE AS B ON ( B.CompanySeq = @CompanySeq AND A.ResultSeq = B.ResultSeq AND A.ResultSerl = B.ResultSerl AND A.ResultSubSerl = B.ResultSubSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairRltManHourCHE WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.DivSeq         = A.DivSeq, 
               B.EmpSeq         = A.EmpSeq, 
               B.WorkOperSerl   = A.WorkOperSerl, 
               B.ManHour        = A.ManHour, 
               B.OTManHour      = A.OTManHour, 
               B.LastUserSeq    = @UserSeq, 
               B.LastDateTime   = GETDATE(), 
               B.PgmSeq         = @PgmSeq 
          FROM #KPXCM_TEQYearRepairRltManHourCHE AS A   
          JOIN KPXCM_TEQYearRepairRltManHourCHE AS B ON ( B.CompanySeq = @CompanySeq AND A.ResultSeq = B.ResultSeq AND A.ResultSerl = B.ResultSerl AND A.ResultSubSerl = B.ResultSubSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END 
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairRltManHourCHE WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
            
        DECLARE @MAXSubSerl INT 
        
        SELECT @MAXSubSerl = MAX(B.ResultSubSerl)
          FROM #KPXCM_TEQYearRepairRltManHourCHE AS A   
          JOIN KPXCM_TEQYearRepairRltManHourCHE AS B ON ( B.CompanySeq = @CompanySeq AND A.ResultSeq = B.ResultSeq AND A.ResultSerl = B.ResultSerl ) 
          
        SELECT @MAXSubSerl = ISNULL(@MAXSubSerl,0) 
        
        UPDATE A 
           SET ResultSubSerl = ISNULL(@MAXSubSerl,0) + DataSeq 
          FROM #KPXCM_TEQYearRepairRltManHourCHE AS A 
         WHERE A.Status = 0 
           AND A.WorkingTag = 'A' 
        
        INSERT INTO KPXCM_TEQYearRepairRltManHourCHE  
        (   
            CompanySeq, ResultSeq, ResultSerl, ResultSubSerl, DivSeq, 
            EmpSeq, WorkOperSerl, ManHour, OTManHour, LastUserSeq, 
            LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, ResultSeq, ResultSerl, ResultSubSerl, DivSeq, 
               EmpSeq, WorkOperSerl, ManHour, OTManHour, @UserSeq, 
               GETDATE(), @PgmSeq
          FROM #KPXCM_TEQYearRepairRltManHourCHE AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    SELECT * FROM #KPXCM_TEQYearRepairRltManHourCHE   
    
    RETURN  
GO
begin tran 
exec KPXCM_SEQYearRepairResultRegCHESubSave @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ResultSeq>4</ResultSeq>
    <ResultSerl>4</ResultSerl>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <ResultSeq>4</ResultSeq>
    <ResultSerl>4</ResultSerl>
    <DivName>���</DivName>
    <DivSeq>20117001</DivSeq>
    <EmpName>A3</EmpName>
    <EmpSeq>1000066</EmpSeq>
    <WorkOperSerlName>�׽�Ʈ1</WorkOperSerlName>
    <WorkOperSerl>20107001</WorkOperSerl>
    <ManHour>3</ManHour>
    <OTManHour>4</OTManHour>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030930,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025775

select *from KPXCM_TEQYearRepairRltManHourCHE 
rollback 