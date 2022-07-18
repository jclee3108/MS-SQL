  
IF OBJECT_ID('KPX_SPDMRPMonthListQuery') IS NOT NULL   
    DROP PROC KPX_SPDMRPMonthListQuery  
GO  
  
-- v2014.12.15  
  
-- ��������ҿ���ȸ-��ȸ by ����õ   
CREATE PROC KPX_SPDMRPMonthListQuery  
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
            @ProdPlanYM NCHAR(6),  
            @PlanDateFr NCHAR(8),  
            @PlanDateTo NCHAR(8),  
            @EmpName    NVARCHAR(100), 
            @MRPNo      NVARCHAR(100) 
            
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ProdPlanYM  = ISNULL( ProdPlanYM , '' ),
           @PlanDateFr  = ISNULL( PlanDateFr , '' ),  
           @PlanDateTo  = ISNULL( PlanDateTo , '' ), 
           @EmpName     = ISNULL( EmpName    , '' ), 
           @MRPNo       = ISNULL( MRPNo      , '' )  
           
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
                ProdPlanYM NCHAR(6),  
                PlanDateFr NCHAR(8),  
                PlanDateTo NCHAR(8),  
                EmpName    NVARCHAR(100),
                MRPNo      NVARCHAR(100) 
           )
    
    IF @PlanDateTo = '' SELECT @PlanDateTo = '99991231' 
    
    -- ������ȸ   
    SELECT A.MRPMonthSeq, 
           A.ProdPlanYM, 
           A.MRPNo, 
           A.SMInOutTypePur, 
           A.EmpSeq, 
           B.EmpName, 
           A.PlanDate, 
           A.PlanTime, 
           
           C.MinorName AS SMInOutTypePurName -- ���ⱸ�� 
      FROM KPX_TPDMRPMonth          AS A 
      LEFT OUTER JOIN _TDAEmp       AS B ON ( B.CompanySeq = @COmpanySeq AND B.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDASMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MInorSeq = A.SMInOutTypePur ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.ProdPlanYM = @ProdPlanYM ) 
       AND ( A.PlanDate BETWEEN @PlanDateFr AND @PlanDateTo ) 
       AND ( @EmpName = '' OR B.EmpName LIKE @EmpName + '%' ) 
       AND ( @MRPNo = '' OR B.MRPNo LIKE @MRPNo + '%' ) 
    
    RETURN  
