  
IF OBJECT_ID('KPXCM_SPDProdPlanScenarioRevQuerySub') IS NOT NULL   
    DROP PROC KPXCM_SPDProdPlanScenarioRevQuerySub  
GO  
  
-- v2016.05.20  
  
-- �����ȹ�ó����� ��������-Sub��ȸ by ����õ   
CREATE PROC KPXCM_SPDProdPlanScenarioRevQuerySub  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) ���
    
    DECLARE @docHandle  INT,  
            -- ��ȸ����   
            @FactUnit   INT,  
            @PlanYM     NCHAR(6) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit   = ISNULL( FactUnit, 0 ),  
           @PlanYM     = ISNULL( PlanYM, '' ) 
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit   INT,  
            PlanYM     NCHAR(6)       
           )    
    
    -- ������ȸ   
    SELECT A.FactUnit, 
           A.PlanYM, 
           A.PlanRev, 
           A.PlanRevName, 
           A.Remark
      FROM KPXCM_TPDMonthProdPlanRev AS A 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.FactUnit = @FactUnit 
       AND A.PlanYM = @PlanYM 
      
    RETURN  