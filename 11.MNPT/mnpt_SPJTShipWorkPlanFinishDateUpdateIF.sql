     
IF OBJECT_ID('mnpt_SPJTShipWorkPlanFinishDateUpdateIF') IS NOT NULL       
    DROP PROC mnpt_SPJTShipWorkPlanFinishDateUpdateIF
GO      
      
-- v2017.12.06
      
-- �����۾���ȹ�Ϸ��Է�-������ý��� ���� by ����õ  
CREATE PROC mnpt_SPJTShipWorkPlanFinishDateUpdateIF      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    
    IF DB_NAME() = 'MNPT'
    BEGIN 
        EXEC mnpt_SPJTShipDetailUpdate @CompanySeq
    END 

    RETURN     
