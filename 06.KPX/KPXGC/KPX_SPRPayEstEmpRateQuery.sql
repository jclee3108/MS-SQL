  
IF OBJECT_ID('KPX_SPRPayEstEmpRateQuery') IS NOT NULL   
    DROP PROC KPX_SPRPayEstEmpRateQuery  
GO  
  
-- v2014.12.15  
  
-- �޿����� ���κ��λ���-��ȸ by ����õ   
CREATE PROC KPX_SPRPayEstEmpRateQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT,  
            -- ��ȸ����   
            @YY         NCHAR(4)    
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @YY   = ISNULL( YY, '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (YY   NCHAR(4))    
      
    -- ������ȸ   
    SELECT A.EmpSeq, 
           A.YY, 
           B.EmpName, 
           B.EmpID, 
           A.EstRate, 
           A.AddRate, 
           A.Remark, 
           
           A.EmpSeq AS EmpSeqOld
      FROM KPX_TPRPayEstEmpRate AS A 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS B ON ( B.EmpSeq = A.EmpSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @YY = A.YY ) 
      
    RETURN  