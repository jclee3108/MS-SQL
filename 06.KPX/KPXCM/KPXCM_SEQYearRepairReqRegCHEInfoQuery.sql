  
IF OBJECT_ID('KPXCM_SEQYearRepairReqRegCHEInfoQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReqRegCHEInfoQuery  
GO  
  
-- v2015.07.14  
  
-- ����������û���-������ȸ by ����õ   
CREATE PROC KPXCM_SEQYearRepairReqRegCHEInfoQuery  
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
            @FactUnit   INT, 
            @RepairYear NCHAR(4), 
            @Amd        INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit = ISNULL( FactUnit, 0 ), 
           @RepairYear = ISNULL( RepairYear, '' ), 
           @Amd = ISNULL( Amd, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit   INT, 
            RepairYear NCHAR(4), 
            Amd        INT 
           )    
    
    -- ������ȸ   
    SELECT A.RepairFrDate, 
           A.RepairToDate, 
           A.ReceiptFrDate, 
           A.ReceiptToDate
      FROM KPXCM_TEQYearRepairPeriodCHE AS A 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.FactUnit = @FactUnit 
       AND A.RepairYear = @RepairYear 
       AND A.Amd = @Amd 
    
    RETURN  
GO 