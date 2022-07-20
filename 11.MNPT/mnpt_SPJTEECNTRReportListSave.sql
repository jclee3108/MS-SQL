  
IF OBJECT_ID('mnpt_SPJTEECNTRReportListSave') IS NOT NULL   
    DROP PROC mnpt_SPJTEECNTRReportListSave  
GO  
    
-- v2017.11.07
  
-- �����̳ʽ�����ȸ-���� by ����õ   
CREATE PROC mnpt_SPJTEECNTRReportListSave  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0   
AS    
       
      
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTEECNTRReport')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTEECNTRReport'    , -- ���̺��        
                  '#BIZ_OUT_DataBlock1'    , -- �ӽ� ���̺��        
                  'CNTRReportSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock1      AS A   
          JOIN mnpt_TPJTEECNTRReport    AS B ON ( B.CompanySeq = @CompanySeq AND A.CNTRReportSeq = B.CNTRReportSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  

        DELETE B   
          FROM #BIZ_OUT_DataBlock1      AS A   
          JOIN mnpt_TPJTEECNTRReport_IF AS B ON ( B.CompanySeq = @CompanySeq AND A.CNTRReportSeq = B.CNTRReportSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    RETURN  
