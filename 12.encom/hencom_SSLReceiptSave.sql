IF OBJECT_ID('hencom_SSLReceiptSave') IS NOT NULL 
    DROP PROC hencom_SSLReceiptSave 
GO 

-- v2017.03.20 
/*********************************************************************************************************************
    ȭ��� : �Ա�ó��_�Ա�����
    SP Name: _SSLReceiptSave
    �ۼ��� : 2008.08.05 : CREATEd by ������    
    ������ : 
********************************************************************************************************************/
CREATE PROCEDURE hencom_SSLReceiptSave  
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
            @ReceiptSeq INT, 
            @count      INT, 
            @BizUnit    INT, 
            @CurrDate   NCHAR(8),
            @ReceiptNo  NCHAR(12)
    
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TSLReceipt (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TSLReceipt' 
    


    ---------------------------------------------------------------------------------------------
    -- �Ա��Է½� ���ŵ���� 0 ���� ������ش�. ��,���� ������ ��ϵǾ� ���� ���� ��쿡��...
    -- ���ŵ��, Srt
    ---------------------------------------------------------------------------------------------
    DECLARE @CLSeq      INT, 
            @Seq        INT, 
            @MaxSerl    INT 

    SELECT @CLSeq = B.CLSeq 
      FROM #TSLReceipt AS A 
      LEFT OUTER JOIN ( 
                        SELECT Z.CustSeq, MAX(Z.CLSeq) AS CLSeq 
                          FROM hencom_TSLCreditLimitM AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                         GROUP BY Z.CustSeq 
                      ) AS B ON ( B.CustSeq = A.CustSeq ) 
     WHERE A.WorkingTag IN ( 'A', 'U' ) 
    
    -- Master ä�� �� ���� 
    IF ISNULL(@CLSeq,0) = 0 AND (SELECT WorkingTag FROM #TSLReceipt) IN ( 'A', 'U' )
    BEGIN 
        
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'hencom_TSLCreditLimitM', 'CLSeq', 1  

        INSERT INTO hencom_TSLCreditLimitM
        (
            CompanySeq, CLSeq, CustSeq, CurrSeq, TotalCreditAmt, 
            IsContainBill, Remark, LastUserSeq, LastDateTime
        )
        SELECT @CompanySeq, @Seq + 1, A.CustSeq, A.CurrSeq, 1, '1', '�Ա��Է� �ڵ�����', @UserSeq, GETDATE()
          FROM #TSLReceipt AS A 
         WHERE A.WorkingTag IN ( 'A', 'U' ) 
        
        SELECT @CLSeq = @Seq + 1
    END 
    
    -- Detail ���� 
    SELECT @MaxSerl = ISNULL(( 
                                SELECT MAX(CLSerl) 
                                  FROM hencom_TSLCreditLimitD AS A 
                                 WHERE A.CompanySeq = @CompanySeq 
                                   AND A.CLSeq = @CLSeq 
                             ),0)
    
    IF (SELECT WorkingTag FROM #TSLReceipt) IN ( 'A', 'U' )
    BEGIN 
        
        INSERT INTO hencom_TSLCreditLimitD 
        (
            CompanySeq, CLSeq, CLSerl, CreditAmt, Remark, 
            LastUserSeq, LastDateTime, DeptSeq
        ) 
        SELECT @CompanySeq, @CLSeq, @MaxSerl + 1, 0, '�Ա��Է� �ڵ�����', @UserSeq, GETDATE(), A.DeptSeq 
          FROM #TSLReceipt AS A 
         WHERE A.Status = 0 
           AND A.WorkingTag IN ( 'A', 'U' ) 
           AND NOT EXISTS (SELECT 1 FROM hencom_TSLCreditLimitD WHERE CompanySeq = @CompanySeq AND CLSeq = @CLSeq AND DeptSeq = A.DeptSeq) 
    END 
    ---------------------------------------------------------------------------------------------
    -- ���ŵ��, End
    ---------------------------------------------------------------------------------------------
    
    SELECT @ReceiptSeq = ReceiptSeq, 
           @BizUnit    = BizUnit
      FROM #TSLReceipt 
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
    EXEC _SCOMLog  @CompanySeq   ,
                   @UserSeq      ,
                   '_TSLReceipt', -- �����̺��
                   '#TSLReceipt', -- �������̺��
                   'ReceiptSeq' , -- Ű�� �������� ���� , �� �����Ѵ�. 
                   'CompanySeq, ReceiptSeq, BizUnit, SMExpKind, ReceiptNo, ReceiptDate, EmpSeq, DeptSeq, CustSeq, CurrSeq, ExRate, Remark, 
                    SlipSeq, OppAccSeq, IsPreReceipt, IsReplace, PaymentNo, LastUserSeq, LastDateTime, PgmSeq', '',@Pgmseq

-- DELETE                                                                                                
    IF EXISTS (SELECT 1 FROM #TSLReceipt WHERE WorkingTag = 'D' AND Status = 0 )  
    BEGIN  
        EXEC _SCOMDeleteLog  @CompanySeq   ,  
                             @UserSeq      ,  
                             '_TSLReceiptDesc', -- �����̺��  
                             '#TSLReceipt', -- �������̺��  
                             'ReceiptSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                             'CompanySeq,ReceiptSeq,ReceiptSerl,SMDrOrCr,UMReceiptKind,DomAmt,BankSeq,BankAccSeq,AdminNo,Commission,
                              IssueDate,DueDate,IssueMan,Endorse,Remark,SlipSeq,InDate,CurAmt,LastUserSeq,LastDateTime,
                              TempSlipSeq,NotifySeq,NotifySerl,NotifyDate,ExRate,PgmSeq'  
        EXEC _SCOMDeleteLog  @CompanySeq   ,  
                             @UserSeq      ,  
                             '_TSLReceiptBill', -- �����̺��  
                             '#TSLReceipt', -- �������̺��  
                             'ReceiptSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                             'CompanySeq,ReceiptSeq,BillSeq,CurAmt,DomAmt, LastUserSeq, LastDateTime,PgmSeq'  
        EXEC _SCOMDeleteLog  @CompanySeq   ,  
                             @UserSeq      ,  
                             '_TSLAltReceipt', -- �����̺��  
                             '#TSLReceipt', -- �������̺��  
                             'ReceiptSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                             'CompanySeq,ReceiptSeq,BillSeq,SalesSeq,SalesSerl,CurAmt,DomAmt,PgmSeq'  
        DELETE _TSLReceipt  
          FROM _TSLReceipt AS A
                 JOIN #TSLReceipt AS B ON  A.ReceiptSeq = B.ReceiptSeq AND A.CompanySeq = @CompanySeq
         WHERE B.WorkingTag = 'D' 
           AND B.Status = 0
  
        IF @@ERROR <> 0 RETURN 
        DELETE _TSLReceiptDesc
          FROM _TSLReceiptDesc AS A
                 JOIN #TSLReceipt AS B ON  A.ReceiptSeq = B.ReceiptSeq AND A.CompanySeq = @CompanySeq
         WHERE B.WorkingTag = 'D' 
           AND B.Status = 0
  
        IF @@ERROR <> 0 RETURN 
        DELETE _TSLReceiptBill
          FROM _TSLReceiptBill AS A
                 JOIN #TSLReceipt AS B ON  A.ReceiptSeq = B.ReceiptSeq AND A.CompanySeq = @CompanySeq
         WHERE B.WorkingTag = 'D' 
           AND B.Status = 0
  
        IF @@ERROR <> 0 RETURN 
        DELETE _TSLAltReceipt
          FROM _TSLAltReceipt AS A
                 JOIN #TSLReceipt AS B ON  A.ReceiptSeq = B.ReceiptSeq AND A.CompanySeq = @CompanySeq
         WHERE B.WorkingTag = 'D' 
           AND B.Status = 0
  
        IF @@ERROR <> 0 RETURN 
    END   
-- Update                                                                                                 
    IF EXISTS (SELECT 1 FROM #TSLReceipt WHERE WorkingTag = 'U' AND Status = 0 )  
    BEGIN   
        UPDATE _TSLReceipt   
           SET BizUnit      = B.BizUnit,
               SMExpKind    = B.SMExpKind,
               ReceiptNo    = B.ReceiptNo,
               ReceiptDate  = B.ReceiptDate,
               EmpSeq       = B.EmpSeq,
               DeptSeq      = B.DeptSeq, 
               CustSeq      = B.CustSeq, 
               CurrSeq      = B.CurrSeq, 
               ExRate       = B.ExRate, 
               Remark       = B.Remark, 
               OppAccSeq    = B.OppAccSeq, 
               IsPreReceipt = B.IsPreReceipt, 
               IsReplace    = B.IsReplace, 
               PaymentNo    = B.PaymentNo,
               LastUserSeq  = @UserSeq, 
               LastDateTime = GETDATE()  ,
               PgmSeq       = @PgmSeq
          FROM _TSLReceipt AS A 
                 JOIN #TSLReceipt AS B ON A.ReceiptSeq = B.ReceiptSeq AND A.CompanySeq = @CompanySeq 
         WHERE B.WorkingTag = 'U' 
           AND B.Status = 0
  
        IF @@ERROR <> 0 RETURN 
    END 
-- INSERT                                                                                                 
    IF EXISTS (SELECT 1 FROM #TSLReceipt WHERE WorkingTag = 'A' AND Status = 0 )  
    BEGIN  
        -- ���� INSERT  
        INSERT INTO _TSLReceipt (CompanySeq,    ReceiptSeq,     BizUnit,     SMExpKind,      ReceiptNo, 
                                 ReceiptDate,   EmpSeq,         DeptSeq,     CustSeq,        CurrSeq, 
                                 ExRate,        Remark,         SlipSeq,     OppAccSeq,      IsPreReceipt, 
                                 IsReplace,     PaymentNo,      LastUserSeq, LastDateTime,   PgmSeq)        
            SELECT @CompanySeq,     ReceiptSeq ,    BizUnit,     SMExpKind,      ReceiptNo, 
                   ReceiptDate,     EmpSeq,         DeptSeq,     CustSeq,        CurrSeq, 
                   ExRate,          Remark,         0,           OppAccSeq,      IsPreReceipt, 
                   IsReplace,       PaymentNo,      @UserSeq,    GETDATE() ,     @PgmSeq
              FROM #TSLReceipt  
             WHERE WorkingTag = 'A' AND Status = 0  
       
        IF @@ERROR <> 0 RETURN 
    END   
    
    UPDATE A
	   SET A.BizUnitOld = B.BizUnit, 
	       A.DeptSeqOld	= B.DeptSeq,
	       A.DateOld	= B.ReceiptDate 
      FROM #TSLReceipt AS A   
      JOIN _TSLReceipt AS B ON ( B.CompanySeq = @CompanySeq AND A.ReceiptSeq = B.ReceiptSeq )
	
	SELECT * FROM #TSLReceipt
	
	RETURN
go
begin tran 
exec hencom_SSLReceiptSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <BizUnit>1</BizUnit>
    <SMExpKind>8009001</SMExpKind>
    <ReceiptNo>2017032000003</ReceiptNo>
    <ReceiptDate>20170320</ReceiptDate>
    <EmpSeq>716</EmpSeq>
    <DeptSeq>29</DeptSeq>
    <CustSeq>2099</CustSeq>
    <CurrSeq>1</CurrSeq>
    <ExRate>1.000000</ExRate>
    <Remark />
    <SlipSeq>0</SlipSeq>
    <OppAccSeq>18</OppAccSeq>
    <IsPreReceipt>0</IsPreReceipt>
    <IsReplace>0</IsReplace>
    <PaymentNo />
    <SMExpKindName>����</SMExpKindName>
    <BizUnitName>������</BizUnitName>
    <EmpName>������</EmpName>
    <DeptName>����</DeptName>
    <CustName>(��)��ȭ���հǼ�</CustName>
    <CurrName>KRW</CurrName>
    <OppAccName>�ܻ�����</OppAccName>
    <SlipID />
    <ReceiptSeq>72906</ReceiptSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1511489,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=6050
rollback 