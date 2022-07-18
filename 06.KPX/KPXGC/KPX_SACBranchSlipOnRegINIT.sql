  
IF OBJECT_ID('KPX_SACBranchSlipOnRegINIT') IS NOT NULL   
    DROP PROC KPX_SACBranchSlipOnRegINIT  
GO  
  
-- v2015.02.26 
  
-- ��������ü��ǥ����(�Ǻ�����)-INIT by ����õ 
CREATE PROC KPX_SACBranchSlipOnRegINIT  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    SELECT B.AccUnitName, A.EnvValue AS AccUnit 
      FROM KPX_TCOMEnvItem AS A 
      LEFT OUTER JOIN _TDAAccUnit AS B ON ( B.CompanySeq = @CompanySeq AND B.AccUnit = A.EnvValue ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.EnvSeq = 31 
       AND A.EnvSerl = 1 
      
    RETURN  