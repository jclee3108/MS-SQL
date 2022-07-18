
IF OBJECT_ID('DTI_SPJTSalesProfitListDelete') IS NOT NULL 
    DROP PROC DTI_SPJTSalesProfitListDelete
GO 

-- v2014.03.20 

-- ������Ʈ������������Ȳ_DTI(����) by����õ
CREATE PROC dbo.DTI_SPJTSalesProfitListDelete
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250)
    
    CREATE TABLE #DTI_TPJTSalesProfitPlan (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TPJTSalesProfitPlan'
    
    IF (SELECT MAX(B.Rev)
          FROM #DTI_TPJTSalesProfitPlan AS A 
          JOIN DTI_TPJTSalesProfitPlan  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq ) 
       ) <> (SELECT PlanRev FROM #DTI_TPJTSalesProfitPlan)
    BEGIN 
        UPDATE #DTI_TPJTSalesProfitPlan
           SET Result = N'���� ������ �ƴϸ� ���� �� �� �����ϴ�.', 
               MessageType = 1234, 
               Status = 1234 
    END 
    
    DELETE B
      FROM #DTI_TPJTSalesProfitPlan AS A 
      JOIN DTI_TPJTSalesProfitPlan  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.Rev = A.PlanRev ) 
     WHERE A.Status = 0 
    
    UPDATE A 
       SET PlanRev = PlanRev - 1 
      FROM #DTI_TPJTSalesProfitPlan AS A 
    
    SELECT * FROM #DTI_TPJTSalesProfitPlan 
    
    RETURN 
GO