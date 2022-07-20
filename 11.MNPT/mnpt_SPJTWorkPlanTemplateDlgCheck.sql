  
IF OBJECT_ID('mnpt_SPJTWorkPlanTemplateDlgCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkPlanTemplateDlgCheck  
GO  
    
-- v2017.09.18
  
-- �۾���ȹ���ø�-üũ by ����õ
CREATE PROC mnpt_SPJTWorkPlanTemplateDlgCheck      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
    
    
    -- üũ1, �̹� ���ø� �߰� �� �����Դϴ�.
    UPDATE A
       SET Result = '�̹� ���ø� �߰� �� �����Դϴ�.', 
           MessageType = 1234, 
           Status = 1234 
      FROM #BIZ_OUT_DataBlock1  AS A 
      JOIN mnpt_TPJTWorkPlan    AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkPlanSeq = A.WorkPlanSeq ) 
     WHERE A.Status = 0 
       AND @WorkingTag = 'U' 
       AND B.IsTemplate = '1' 
    -- üũ1, End 

    -- üũ2, ������ ���õ��� �ʾҽ��ϴ�.
    UPDATE A
       SET Result = '������ ���õ��� �ʾҽ��ϴ�.', 
           MessageType = 1234, 
           Status = 1234 
      FROM #BIZ_OUT_DataBlock1  AS A 
     WHERE A.Status = 0 
       AND @WorkingTag = 'U' 
       AND ISNULL(A.WorkPlanSeq,0) = 0 
    -- üũ2, End 

    RETURN  
  Go

  