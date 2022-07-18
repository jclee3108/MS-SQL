  
IF OBJECT_ID('KPX_SEQTaskOrderCHEQuery') IS NOT NULL   
    DROP PROC KPX_SEQTaskOrderCHEQuery  
GO  
  
-- v2014.12.08  
  
-- ������������-��ȸ by ����õ   
CREATE PROC KPX_SEQTaskOrderCHEQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle  INT,  
            -- ��ȸ����   
            @TaskOrderSeq  INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @TaskOrderSeq   = ISNULL( TaskOrderSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (TaskOrderSeq   INT)    
    
    -- ������ȸ   
    SELECT *   
      FROM KPX_TEQTaskOrderCHE AS A 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @TaskOrderSeq = 0 OR A.TaskOrderSeq = @TaskOrderSeq )   
    
    RETURN  