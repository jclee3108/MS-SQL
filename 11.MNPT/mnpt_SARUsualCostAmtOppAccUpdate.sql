IF OBJECT_ID('mnpt_SARUsualCostAmtOppAccUpdate') IS NOT NULL 
    DROP PROC mnpt_SARUsualCostAmtOppAccUpdate
GO 

-- v2018.01.12
  
-- �Ϲݺ���û_mnpt-���������� by ����õ
/************************************************************
��  �� - �Ϲݺ���û���ݾ� - ����
�ۼ��� - 2010�� 04�� 19�� 
�ۼ��� - �۰��
************************************************************/
CREATE PROC dbo.mnpt_SARUsualCostAmtOppAccUpdate
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    DECLARE @UMCostTypeKind     INT,
            @UMCostType         INT,
            @DeptCCtrSeq        INT
    -- ���� ����Ÿ ��� ����
    CREATE TABLE #TARUsualCostAmt (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TARUsualCostAmt'     
    IF @@ERROR <> 0 RETURN    
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
    EXEC _SCOMLog  @CompanySeq   ,
                   @UserSeq      ,
                   '_TARUsualCostAmt', -- �����̺��
                   '#TARUsualCostAmt', -- �������̺��
                   'UsualCostSeq,UsualCostSerl' , -- Ű�� �������� ���� , �� �����Ѵ�. 
                   'CompanySeq,UsualCostSeq,UsualCostSerl,CostSeq,RemValSeq,Amt,IsVat,SupplyAmt,VatAmt,CustSeq,CustText,EvidSeq,Remark,AccSeq,VatAccSeq,OppAccSeq,LastUserSeq,LastDateTime,UMCostType,CostCashDate,CustDate,BgtDeptCCtrSeq'

    -- UPDATE    
    IF EXISTS (SELECT 1 FROM #TARUsualCostAmt WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN
        UPDATE _TARUsualCostAmt
           SET  EvidSeq         = B.EvidSeq    
              , CustText        = B.CustText
              , OppAccSeq       = B.OppAccSeq  
              , CustDate        = B.CustDate 
              , LastUserSeq     = @UserSeq
              , LastDateTime    = GETDATE()  
          FROM _TARUsualCostAmt AS A JOIN #TARUsualCostAmt AS B ON (A.UsualCostSeq = B.UsualCostSeq AND A.UsualCostSerl = B.UsualCostSerl)  
         WHERE B.WorkingTag = 'U' AND B.Status = 0    
           AND A.CompanySeq  = @CompanySeq 
        IF @@ERROR <> 0  RETURN
    END   
    
    SELECT * FROM #TARUsualCostAmt   
RETURN    
--go
--begin tran 
--EXEC mnpt_SARUsualCostAmtOppAccUpdate @xmlDocument = N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>U</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <UsualCostSerl>1</UsualCostSerl>
--    <EvidSeq>20</EvidSeq>
--    <OppAccSeq>5</OppAccSeq>
--    <TABLE_NAME>DataBlock1</TABLE_NAME>
--  </DataBlock1>
--</ROOT>', @xmlFlags = 2, @ServiceSeq = 13820117, @WorkingTag = N'', @CompanySeq = 1, @LanguageSeq = 1, @UserSeq = 167, @PgmSeq = 13820108
--rollback 