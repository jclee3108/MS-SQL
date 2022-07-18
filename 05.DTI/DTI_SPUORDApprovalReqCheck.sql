
IF OBJECT_ID('DTI_SPUORDApprovalReqCheck') IS NOT NULL 
    DROP PROC DTI_SPUORDApprovalReqCheck
GO

-- v2014.01.16 

-- ����ǰ���Է�_DTI(������üũ) by����õ
CREATE PROC dbo.DTI_SPUORDApprovalReqCheck  
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10) = '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    DECLARE @Count           INT, 
            @ApproReqSeq     INT, 
            @ApproReqNo      NVARCHAR(12), 
            @bfApproReqNo      NVARCHAR(12), 
            @ApproReqDate    NVARCHAR(8), 
            @MessageType     INT, 
            @Status          INT, 
            @Results         NVARCHAR(250) 
    
    CREATE TABLE #TPUORDApprovalReq (WorkingTag NCHAR(1) NULL)    
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUORDApprovalReq'   
    
    -- üũ, ����� ����ڿ� ������ �����(�μ�)�� �ٸ��ϴ�. 
    UPDATE A 
       SET Result = N'����� ����ڿ� ������ �����(�μ�)�� �ٸ��ϴ�.', 
           MessageType = 1234, 
           Status = 1234
      FROM #TPUORDApprovalReq AS A 
      JOIN _TPUORDApprovalReqItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ApproReqSeq = A.ApproReqSeq ) 
      JOIN DTI_TSLContractMng     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ContractSeq = CONVERT(INT,B.Memo3) ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'U' 
       AND (A.EmpSeq <> C.EmpSeq 
        OR A.DeptSeq <> C.DeptSeq) 
    -- üũ, END 
    
    IF @@ERROR <> 0 RETURN     
    -- Ȯ���Ȱ��� ���������� �Ҽ� ������ �Ѵ�. -- ȭ�鿡�� ó��  
  
    SELECT @bfApproReqNo = ApproReqNo FROM #TPUORDApprovalReq  
  
    -- MAX POReqSeq Seq  
    SELECT @Count = COUNT(*) FROM #TPUORDApprovalReq WHERE WorkingTag = 'A' AND Status = 0   
    IF @Count > 0  
    BEGIN     
        SELECT @ApproReqDate = ApproReqDate FROM #TPUORDApprovalReq  
        EXEC dbo._SCOMCreateNo 'PU', '_TPUORDApprovalReq', @CompanySeq, '', @ApproReqDate, @ApproReqNo OUTPUT  
        EXEC @ApproReqSeq = dbo._SCOMCreateSeq @CompanySeq, '_TPUORDApprovalReq', 'ApproReqSeq', @Count  
        UPDATE #TPUORDApprovalReq  
           SET ApproReqSeq = @ApproReqSeq + DataSeq ,   
               ApproReqNo  = @ApproReqNo  
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    END 
    
    --�ڵ������� �ƴ϶�� ���� ���� �ٽ� ���� �Ѵ�. ������  
    IF (SELECT IsAutoCreate FROM _TCOMCreateNoDefine WHERE CompanySeq = @CompanySeq AND TableName = '_TPUORDApprovalReq' AND NoColumnname = 'ApproReqNo') = 0  
    BEGIN  
        UPDATE #TPUORDApprovalReq  
           SET ApproReqNo  = @bfApproReqNo  
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    END  
    
    SELECT * FROM #TPUORDApprovalReq  
    
    RETURN    
GO
begin tran 
exec DTI_SPUORDApprovalReqCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ApproReqSeq>1000154</ApproReqSeq>
    <ApproReqDate>20140116</ApproReqDate>
    <ApproReqNo>SN1401160003</ApproReqNo>
    <EmpSeq>2028</EmpSeq>
    <EmpName>����õ</EmpName>
    <Remark />
    <DeptSeq>147</DeptSeq>
    <DeptName>���������</DeptName>
    <FileSeq>0</FileSeq>
    <IsPJT />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1015926,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1013785
rollback 