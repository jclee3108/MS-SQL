  
IF OBJECT_ID('KPX_SPDMRPMonthQuery') IS NOT NULL   
    DROP PROC KPX_SPDMRPMonthQuery  
GO  
  
-- v2014.12.16 
  
-- ��������ҿ���-��ȸ by ����õ   
CREATE PROC KPX_SPDMRPMonthQuery  
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
            -- ��ȸ����   
            @MRPMonthSeq    INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @MRPMonthSeq = ISNULL( MRPMonthSeq, 0 )  
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (MRPMonthSeq   INT)    
    
    -- ������ȸ   
    SELECT A.MRPMonthSeq, 
           A.ProdPlanYM, 
           A.MRPNo, 
           STUFF(STUFF(A.PlanDate, 5,0,'-'),8,0,'-') + ' ' + STUFF(A.PlanTime,3,0,':') AS PlanDateTime, 
           A.SMInOutTypePur, 
           B.MinorName AS SMInOutTypePurName 
           
      FROM KPX_TPDMRPMonth AS A 
      LEFT OUTER JOIN _TDASMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SMInOutTypePur ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.MRPMonthSeq = @MRPMonthSeq )   

      
    RETURN  
GO 