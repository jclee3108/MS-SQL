IF OBJECT_ID('KPXCM_SSLExpExpenseSave') IS NOT NULL 
    DROP PROC KPXCM_SSLExpExpenseSave
GO 

-- v2015.09.30 

-- ��ǰ��� �߰� by����õ 
/*********************************************************************************************************************
     ȭ��� : ������_����������
     SP Name: _SSLExpExpenseSave
     �ۼ��� : 2009. 3 : CREATEd by ���ظ�
     ������ : 
 ********************************************************************************************************************/
 CREATE PROCEDURE KPXCM_SSLExpExpenseSave  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '', 
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS       
     DECLARE @docHandle  INT, 
             @ExpenseSeq INT, 
             @count      INT, 
             @BizUnit    INT, 
             @CurrDate   NCHAR(8)
      -- ���� ����Ÿ ��� ����  
     CREATE TABLE #TSLExpExpense (WorkingTag NCHAR(1) NULL)  
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TSLExpExpense' 
    
     -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TSLExpExpense', -- �����̺��
                    '#TSLExpExpense', -- �������̺��
                    'ExpenseSeq' , -- Ű�� �������� ���� , �� �����Ѵ�. 
                    'CompanySeq,ExpenseSeq,BizUnit,ExpenseDate,SMImpOrExp,SMExpKind,SMSourceType,SourceSeq,CustSeq,DeptSeq,EmpSeq,Remark,LastUserSeq,LastDateTime'
  
     -- DELETE
     IF EXISTS (SELECT 1 FROM #TSLExpExpense WHERE WorkingTag = 'D' AND Status = 0 )  
     BEGIN  
         DELETE _TSLExpExpense  
           FROM _TSLExpExpense AS A
                  JOIN #TSLExpExpense AS B ON A.CompanySeq = @CompanySeq
                                          AND A.ExpenseSeq = B.ExpenseSeq
          WHERE B.WorkingTag = 'D' 
            AND B.Status = 0
          IF @@ERROR <> 0 RETURN 
  
         DELETE _TSLExpExpenseDesc
           FROM _TSLExpExpenseDesc AS A
                  JOIN #TSLExpExpense AS B ON A.CompanySeq = @CompanySeq
                                          AND A.ExpenseSeq = B.ExpenseSeq
          WHERE B.WorkingTag = 'D' 
            AND B.Status = 0
          IF @@ERROR <> 0 RETURN 
          
         DELETE KPXCM_TSLExpExpenseDesc
           FROM KPXCM_TSLExpExpenseDesc AS A
                  JOIN #TSLExpExpense AS B ON A.CompanySeq = @CompanySeq
                                          AND A.ExpenseSeq = B.ExpenseSeq
          WHERE B.WorkingTag = 'D' 
            AND B.Status = 0
          IF @@ERROR <> 0 RETURN 
     END
      -- UPDATE                                                                                                 
     IF EXISTS (SELECT 1 FROM #TSLExpExpense WHERE WorkingTag = 'U' AND Status = 0 )  
     BEGIN   
         UPDATE _TSLExpExpense   
            SET BizUnit  = B.BizUnit,
                ExpenseDate  = B.ExpenseDate,
                SMExpKind    = B.SMExpKind,
                SMSourceType = B.SMSourceType,
                SourceSeq    = B.SourceSeq,
                CustSeq      = B.CustSeq,
                DeptSeq      = B.DeptSeq,
                EmpSeq       = B.EmpSeq,
                Remark       = B.Remark,
                LastUserSeq  = @UserSeq,
                LastDateTime = GETDATE()
           FROM _TSLExpExpense AS A
                  JOIN #TSLExpExpense AS B ON A.CompanySeq = @CompanySeq 
                                          AND A.ExpenseSeq = B.ExpenseSeq
          WHERE B.WorkingTag = 'U'
            AND B.Status = 0
          IF @@ERROR <> 0 RETURN 
     END 
      -- INSERT                                                                                                 
     IF EXISTS (SELECT 1 FROM #TSLExpExpense WHERE WorkingTag = 'A' AND Status = 0 )  
     BEGIN  
          -- ���� INSERT  
         INSERT INTO _TSLExpExpense 
                    (CompanySeq,  ExpenseSeq,  BizUnit,     ExpenseDate, SMExpKind,
                     SMSourceType,SourceSeq,   CustSeq,     DeptSeq,     EmpSeq,
                     Remark,      SMImpOrExp,  LastUserSeq, LastDateTime)        
          SELECT  @CompanySeq, ExpenseSeq,  BizUnit,     ExpenseDate, SMExpKind,
                     SMSourceType,SourceSeq,   CustSeq,     DeptSeq,     EmpSeq,
                     Remark,      SMImpOrExp,  @UserSeq,    GETDATE()   
        FROM #TSLExpExpense  
              WHERE WorkingTag = 'A' AND Status = 0  
          IF @@ERROR  <> 0 RETURN 
     END
     
     SELECT * FROM #TSLExpExpense 
   
 RETURN
 go
 begin tran 
 exec KPXCM_SSLExpExpenseSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <ExpenseSeq>99</ExpenseSeq>
    <BizUnitName>PPG�����</BizUnitName>
    <BizUnit>1</BizUnit>
    <ExpenseDate>20150930</ExpenseDate>
    <SMExpKindName>������</SMExpKindName>
    <SMExpKind>8008004</SMExpKind>
    <SMSourceTypeName>����Payment</SMSourceTypeName>
    <SMSourceType>8215002</SMSourceType>
    <SourceSeq>135</SourceSeq>
    <CustName>������û�� ���繫��</CustName>
    <CustSeq>4981</CustSeq>
    <DeptName>J ������Ʈ��</DeptName>
    <DeptSeq>142</DeptSeq>
    <EmpName>������</EmpName>
    <EmpSeq>1</EmpSeq>
    <Remark />
    <SMImpOrExp>8212002</SMImpOrExp>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031958,@WorkingTag=N'D',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=5070
rollback 