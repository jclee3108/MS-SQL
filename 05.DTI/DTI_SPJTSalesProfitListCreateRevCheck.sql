
IF OBJECT_ID('DTI_SPJTSalesProfitListCreateRevCheck') IS NOT NULL 
    DROP PROC DTI_SPJTSalesProfitListCreateRevCheck 
GO 

-- v2014.03.20 

-- ������Ʈ������������Ȳ_DTI(��������üũ) by����õ
CREATE PROC dbo.DTI_SPJTSalesProfitListCreateRevCheck
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
           SET Result = N'���� ���� ��ȸ �� ���������� ���ֽñ� �ٶ��ϴ�.', 
               MessageType = 1234, 
               Status = 1234 
    END 
    
    SELECT * FROM #DTI_TPJTSalesProfitPlan 
    
    RETURN 
GO
exec DTI_SPJTSalesProfitListCreateRevCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <PJTSeq>156</PJTSeq>
    <PlanRev>2</PlanRev>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1021749,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1018260