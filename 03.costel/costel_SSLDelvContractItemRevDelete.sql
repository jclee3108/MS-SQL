  
IF OBJECT_ID('costel_SSLDelvContractItemRevDelete') IS NOT NULL   
    DROP PROC costel_SSLDelvContractItemRevDelete 
GO  
  
-- v2013.09.09  
  
-- ��ǰ�����_costel(ǰ����������) by����õ   
CREATE PROC costel_SSLDelvContractItemRevDelete  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #costel_TSLDelvContractItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#costel_TSLDelvContractItem'   
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('costel_TSLDelvContractItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'costel_TSLDelvContractItem'    , -- ���̺��        
                  '#costel_TSLDelvContractItem'    , -- �ӽ� ���̺��        
                  'ContractSeq,ContractSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��    
    
    UPDATE A
       SET ContractRev = A.ContractRev - 1
      FROM #costel_TSLDelvContractItem AS A
    
    DELETE B
      FROM #costel_TSLDelvContractItem AS A
      JOIN costel_TSLDelvContractItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
     WHERE A.Status = 0 
    
    INSERT INTO costel_TSLDelvContractItem 
    (
        CompanySeq, ContractSeq, ContractSerl, DelvExpectDate, ChgDelvExpectDate,
        ItemSeq, UnitSeq, DelvQty, DelvPrice, DelvCurAmt, 
        DelvCurVAT, SalesExpectDate, Remark, ChangeReason, CollectExpectDate,
        LastUserSeq, LastDateTime
    )
    
    SELECT B.CompanySeq, B.ContractSeq, B.ContractSerl, B.DelvExpectDate, B.ChgDelvExpectDate,
           B.ItemSeq, B.UnitSeq, B.DelvQty, B.DelvPrice, B.DelvCurAmt, 
           B.DelvCurVAT, B.SalesExpectDate, B.Remark, B.ChangeReason, B.CollectExpectDate,
           B.LastUserSeq, B.LastDateTime
      FROM #costel_TSLDelvContractItem   AS A
      JOIN costel_TSLDelvContractItemRev AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq AND B.ContractRev = A.ContractRev ) 
    
    DELETE B
      FROM #costel_TSLDelvContractItem AS A 
      JOIN costel_TSLDelvContractItemRev AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq AND B.ContractRev = A.ContractRev ) 
    
    SELECT * FROM #costel_TSLDelvContractItem 
      
    RETURN  
GO
begin tran
exec costel_SSLDelvContractItemRevDelete @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ContractRev>3</ContractRev>
    <ContractSeq>43</ContractSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017531,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014985
rollback tran