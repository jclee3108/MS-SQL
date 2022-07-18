  
IF OBJECT_ID('KPX_SACEvalProfitItemMasterIsClose') IS NOT NULL   
    DROP PROC KPX_SACEvalProfitItemMasterIsClose  
GO  
  
-- v2015.04.28   
  
-- �򰡼��ͻ�ǰ������-���� by ����õ 
CREATE PROC KPX_SACEvalProfitItemMasterIsClose  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    
    CREATE TABLE #KPX_TACEvalProfitItemMaster (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TACEvalProfitItemMaster'   
    IF @@ERROR <> 0 RETURN 
    
    IF @WorkingTag <> 'Close'
    BEGIN 
        -- üũ 1, �򰡱ݾ��� �ݿ� �� �����Ͱ� �ֽ��ϴ�. ������ ��� �� �� �����ϴ�.
        UPDATE A
           SET Result = '�򰡱ݾ��� �ݿ� �� �����Ͱ� �ֽ��ϴ�. ������ ��� �� �� �����ϴ�.', 
               Status = 1234, 
               MessageType = 1234 
          FROM #KPX_TACEvalProfitItemMaster AS A 
          JOIN KPX_TACEvalProfitItemMaster  AS B ON ( B.CompanySeq = @CompanySeq AND B.EvalProfitSeq = A.EvalProfitSeq ) 
         WHERE B.IsTestAmt = '1' 
        -- üũ 1, END 

        UPDATE #KPX_TACEvalProfitItemMaster
           SET Result = A.Result,
               Status = A.Status,
               MessageType = A.MessageType
          FROM (
                SELECT MAX(ISNULL(Result,'')) AS Result, 
                       MAX(ISNULL(Status,0)) AS Status, 
                       MAX(ISNULL(MessageType,0)) AS MessageType 
                  FROM #KPX_TACEvalProfitItemMaster 
               ) AS A 
    END 
    
    -- ������ȸ   
    UPDATE B 
       SET IsClose = A.IsClose
      FROM #KPX_TACEvalProfitItemMaster AS A 
      JOIN KPX_TACEvalProfitItemMaster AS B ON ( B.CompanySeq = @CompanySeq AND B.EvalProfitSeq = A.EvalProfitSeq ) 
     WHERE A.Status = 0 
    
    SELECT * FROM #KPX_TACEvalProfitItemMaster 
    
    RETURN  
GO 

begin tran 
exec KPX_SACEvalProfitItemMasterIsClose @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IsClose>0</IsClose>
    <EvalProfitSeq>36</EvalProfitSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IsClose>0</IsClose>
    <EvalProfitSeq>37</EvalProfitSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <IsClose>0</IsClose>
    <EvalProfitSeq>38</EvalProfitSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026966,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020380
rollback 