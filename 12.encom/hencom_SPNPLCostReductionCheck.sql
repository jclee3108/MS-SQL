  
IF OBJECT_ID('hencom_SPNPLCostReductionCheck') IS NOT NULL   
    DROP PROC hencom_SPNPLCostReductionCheck  
GO  
  
-- v2017.04.27  
  
-- ����������ǥ�ݾ׵��_hencom-üũ by ����õ
CREATE PROC hencom_SPNPLCostReductionCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
      
    CREATE TABLE #hencom_TPNPLCostReduction( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TPNPLCostReduction'   
    IF @@ERROR <> 0 RETURN     
    

    -- PlanSerl ä�� 
    DECLARE @MaxSerl INT 

    SELECT @MaxSerl = (
                        SELECT MAX(A.PlanSerl) 
                          FROM hencom_TPNPLCostReduction    AS A 
                          JOIN #hencom_TPNPLCostReduction   AS B ON ( B.DeptSeq = A.DeptSeq AND B.PlanSeq = A.PlanSeq ) 
                         WHERE A.CompanySeq = @CompanySeq 
                      )
    
    UPDATE A
       SET PlanSerl = ISNULL(@MaxSerl,0) + A.DataSeq
      FROM #hencom_TPNPLCostReduction AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A'
    -- PlanSerl ä��, END 

    -- üũ1, �����,��ȹ�������� 1�Ǹ� ��� �� �� �ֽ��ϴ�. 
    UPDATE A
       SET Result = '�����,��ȹ�������� 1�Ǹ� ��� �� �� �ֽ��ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TPNPLCostReduction AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
       AND A.PlanSerl > 1 
    -- üũ1, END 

    SELECT * FROM #hencom_TPNPLCostReduction   

    RETURN  
    GO
begin tran 
exec hencom_SPNPLCostReductionCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Month01>15151</Month01>
    <Month02>1213</Month02>
    <Month03>131313</Month03>
    <Month04>0</Month04>
    <Month05>0</Month05>
    <Month06>0</Month06>
    <Month07>0</Month07>
    <Month08>0</Month08>
    <Month09>0</Month09>
    <Month10>0</Month10>
    <Month11>0</Month11>
    <Month12>0</Month12>
    <Remark />
    <PlanSerl>0</PlanSerl>
    <PlanSeq>18</PlanSeq>
    <DeptSeq>1</DeptSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1512105,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033516
rollback 

    