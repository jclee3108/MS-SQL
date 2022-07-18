
IF OBJECT_ID('DTI_SPJTSalesProfitListResultCreateCheck') IS NOT NULL 
    DROP PROC DTI_SPJTSalesProfitListResultCreateCheck
GO 

-- v2014.04.08 

-- ������Ʈ������������Ȳ_DTI(��������üũ) by����õ
CREATE PROC dbo.DTI_SPJTSalesProfitListResultCreateCheck
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
    
    CREATE TABLE #DTI_TPJTSalesProfitResult (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TPJTSalesProfitResult' 
--SELECT A.CostYM
--                                                                FROM _TESMDCostKey AS A   
--                                                                JOIN _TESMCProfClosing AS B ON ( B.CompanySeq = @CompanySeq AND B.CostKeySeq = A.CostKeySeq )   
--                                                               WHERE B.IsClosing = '1'   
--                                                                 AND A.CompanySeq = @CompanySeq
--                                                                 return 
                                                                 
   -- select * from _TESMDCostKey AS A 
   -- JOIN _TESMCProfClosing AS B ON ( B.CompanySeq = @CompanySeq AND B.CostKeySeq = A.CostKeySeq )   
   --where b.IsClosing = '1' 
   --and A.CompanySeq = 1 
    
    -- üũ1, ������ ���� �������踦 �� �� �����ϴ�. 
    IF (select ResultYM from #DTI_TPJTSalesProfitResult) IN ( SELECT A.CostYM
                                                                FROM _TESMDCostKey AS A   
                                                                JOIN _TESMCProfClosing AS B ON ( B.CompanySeq = @CompanySeq AND B.CostKeySeq = A.CostKeySeq )   
                                                               WHERE B.IsClosing = '1'   
                                                                 AND A.CompanySeq = @CompanySeq
                                                            ) 
    BEGIN
        UPDATE A 
           SET Result = N'������ ���� �������踦 �� �� �����ϴ�. ', 
               Status = 1234, 
               MessageType = 1234 
          FROM #DTI_TPJTSalesProfitResult AS A 
    END
    
    SELECT * FROM #DTI_TPJTSalesProfitResult 
    
    RETURN    
GO
exec DTI_SPJTSalesProfitListResultCreateCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ResultYM>201301</ResultYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1021749,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1018260