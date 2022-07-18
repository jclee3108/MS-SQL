  
IF OBJECT_ID('KPX_SSLMonthSalesPlanLastRevQuery') IS NOT NULL   
    DROP PROC KPX_SSLMonthSalesPlanLastRevQuery  
GO  
  
-- v2015.04.14 
  
-- �����ǸŰ�ȹ�Է�-����������ȸ by����õ
CREATE PROC KPX_SSLMonthSalesPlanLastRevQuery  
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
            @BizUnit    INT,  
            @PlanYM     NCHAR(8)  
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @BizUnit   = ISNULL( BizUnit, 0 ), 
           @PlanYM    = ISNULL( PlanYM, '' ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            BizUnit   INT, 
            PlanYM    NCHAR(8)
           )    
    
    -- ������ȸ   
    SELECT MAX(PlanRev) AS PlanRev, CONVERT(INT,MAX(PlanRev)) AS PlanRevSeq
      FROM KPX_TSLMonthSalesPlanRev AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.BizUnit = @BizUnit 
       AND A.PlanYM = @PlanYM 
    
    RETURN  