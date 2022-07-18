  
IF OBJECT_ID('yw_SPDWorkCenterEmpQuery2') IS NOT NULL   
    DROP PROC yw_SPDWorkCenterEmpQuery2
GO 
    
-- v2013.07.19  
  
-- ��ũ���ͺ��۾��ڵ��_YW(�۾�����ȸ) by����õ   
CREATE PROC yw_SPDWorkCenterEmpQuery2
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    DECLARE @docHandle      INT, 
            @WorkCenterSeq  INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @WorkCenterSeq = ISNULL( WorkCenterSeq, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (WorkCenterSeq INT) 
      
    -- ������ȸ   
    SELECT A.EmpSeq, 
           B.EmpName, 
           A.WorkCenterSeq, 
           A.EmpSeq AS EmpSeqOld
      FROM YW_TPDWorkCenterEmp AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TDAEmp  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq ) 
     WHERE A.CompanySeq = @CompanySeq   
       AND A.WorkCenterSeq = @WorkCenterSeq
      
    RETURN 
Go
