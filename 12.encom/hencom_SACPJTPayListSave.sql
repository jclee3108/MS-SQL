IF OBJECT_ID('hencom_SACPJTPayListSave') IS NOT NULL 
    DROP PROC hencom_SACPJTPayListSave
GO 

-- v2017.05.10

/************************************************************
 ��  �� - ������-���庰�ӱݴ���_hencom : ����
 �ۼ��� - 20160119
 �ۼ��� - ������
************************************************************/
CREATE PROC dbo.hencom_SACPJTPayListSave
	@xmlDocument    NVARCHAR(MAX),  
	@xmlFlags       INT     = 0,  
	@ServiceSeq     INT     = 0,  
	@WorkingTag     NVARCHAR(10)= '',  
	@CompanySeq     INT     = 1,  
	@LanguageSeq    INT     = 1,  
	@UserSeq        INT     = 0,  
	@PgmSeq         INT     = 0  
AS   
	
	CREATE TABLE #hencom_TACPJTPayList (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TACPJTPayList'     
	IF @@ERROR <> 0 RETURN  
	    
	-- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
	EXEC _SCOMLog  @CompanySeq   ,
   				   @UserSeq      ,
   				   'hencom_TACPJTPayList', -- �����̺��
   				   '#hencom_TACPJTPayList', -- �������̺��
   				   'PJTPayRegSeq          ' , -- Ű�� �������� ���� , �� �����Ѵ�. 
   				   'companyseq, PJTPayRegSeq,PayYM,PJTSeq,DeptSeq,EmpCustSeq,SlipSeq,WorkingDay,Price,TotalPay,IncomTax,ResidenceTax,HealthIns,NationalPension,
						UnemployIns,ContributionAmt,UMBankHQ,BankAccNo,Owner,SubcCustSeq,SubsAccSeq,CalcAccSeq,PrepaidExpenseAccSeq,PayAccSeq,Remark,LastUserSeq,LastDateTime, Calc2AccSeq, CashDate'

	-- �۾����� ���߱�: DELETE -> UPDATE -> INSERT
	-- DELETE    
	IF EXISTS (SELECT TOP 1 1 FROM #hencom_TACPJTPayList WHERE WorkingTag = 'D' AND Status = 0)  
	BEGIN  
			DELETE hencom_TACPJTPayList
			  FROM #hencom_TACPJTPayList A 
				   JOIN hencom_TACPJTPayList B ON ( A.PJTPayRegSeq = B.PJTPayRegSeq ) 
			 WHERE B.CompanySeq  = @CompanySeq
			   AND A.WorkingTag = 'D' 
			   AND A.Status = 0    
			 IF @@ERROR <> 0  RETURN
	END  

	-- UPDATE    
	IF EXISTS (SELECT 1 FROM #hencom_TACPJTPayList WHERE WorkingTag = 'U' AND Status = 0)  
	BEGIN
        UPDATE hencom_TACPJTPayList
        SET PayYM           = a.PayYM,
            PJTSeq          = a.PJTSeq,
            DeptSeq         = a.DeptSeq,
            EmpCustSeq      = a.EmpCustSeq,
            SlipSeq         = a.SlipSeq,
            WorkingDay      = a.WorkingDay,
            Price           = a.Price,
            TotalPay        = a.TotalPay,
            IncomTax        = a.IncomTax,
            ResidenceTax    = a.ResidenceTax,
            HealthIns       = a.HealthIns,
            NationalPension = a.NationalPension,
            UnemployIns     = a.UnemployIns,
            ContributionAmt = a.ContributionAmt,
            UMBankHQ        = a.UMBankHQ,
            BankAccNo       = a.BankAccNo,
            Owner           = a.Owner,
            SubcCustSeq     = a.SubcCustSeq,
            SubsAccSeq      = a.SubsAccSeq,
            CalcAccSeq      = a.CalcAccSeq,
            PrepaidExpenseAccSeq = a.PrepaidExpenseAccSeq,
            PayAccSeq       = a.PayAccSeq,
            Remark          = a.Remark,
            LastDateTime    = getdate(),               
            LastUserSeq     = @UserSeq,
            Calc2AccSeq     = a.Calc2AccSeq, 
            CashDate        = A.CashDate
          FROM #hencom_TACPJTPayList    AS A 
          JOIN hencom_TACPJTPayList     AS B ON ( A.PJTPayRegSeq = B.PJTPayRegSeq ) 
         WHERE B.CompanySeq = @CompanySeq
           AND A.WorkingTag = 'U' 
           AND A.Status = 0    
			   
        IF @@ERROR <> 0  RETURN
    END  
    
    -- INSERT
    IF EXISTS (SELECT 1 FROM #hencom_TACPJTPayList WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        INSERT INTO hencom_TACPJTPayList 
        ( 
            CompanySeq,PJTPayRegSeq,PayYM,PJTSeq,DeptSeq,
            EmpCustSeq,SlipSeq,WorkingDay,Price,TotalPay,
            IncomTax,ResidenceTax,HealthIns,NationalPension,UnemployIns,
            ContributionAmt,UMBankHQ,BankAccNo,Owner,SubcCustSeq,
            SubsAccSeq,CalcAccSeq,PrepaidExpenseAccSeq,PayAccSeq,Remark,
            LastUserSeq,LastDateTime,Calc2AccSeq,CashDate
        ) 
        SELECT @CompanySeq ,PJTPayRegSeq,PayYM,PJTSeq,DeptSeq,
               EmpCustSeq,SlipSeq,WorkingDay,Price,TotalPay,
               IncomTax,ResidenceTax,HealthIns,NationalPension,UnemployIns,
               ContributionAmt,UMBankHQ,BankAccNo,Owner,SubcCustSeq,
               SubsAccSeq,CalcAccSeq,PrepaidExpenseAccSeq,PayAccSeq,Remark,
               @UserSeq,getdate(),Calc2AccSeq,CashDate
          FROM #hencom_TACPJTPayList AS A   
         WHERE A.WorkingTag = 'A' 
           AND A.Status = 0    
        
        IF @@ERROR <> 0 RETURN
        
	END   

	SELECT * FROM #hencom_TACPJTPayList 
    
    RETURN
