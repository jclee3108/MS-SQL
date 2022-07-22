IF OBJECT_ID('hencom_SPNPlanPJTSave') IS NOT NULL 
    DROP PROC hencom_SPNPlanPJTSave
GO 

-- v2017.04.18 

-- ������������ �÷��߰� 
/************************************************************
 ��  �� - ������-�����ȹ������_hncom : ����
 �ۼ��� - 20161014
 �ۼ��� - �ڼ���
************************************************************/
CREATE PROC dbo.hencom_SPNPlanPJTSave
	@xmlDocument    NVARCHAR(MAX),  
	@xmlFlags       INT     = 0,  
	@ServiceSeq     INT     = 0,  
	@WorkingTag     NVARCHAR(10)= '',  
	@CompanySeq     INT     = 1,  
	@LanguageSeq    INT     = 1,  
	@UserSeq        INT     = 0,  
	@PgmSeq         INT     = 0  
AS   
	
	CREATE TABLE #hencom_TPNPJT (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TPNPJT'     
	IF @@ERROR <> 0 RETURN  
	    
	DECLARE @TableColumns NVARCHAR(4000)
     
    SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TPNPJT') 
	-- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
	EXEC _SCOMLog  @CompanySeq   ,
   				   @UserSeq      ,
   				   'hencom_TPNPJT', -- �����̺��
   				   '#hencom_TPNPJT', -- �������̺��
   				   'PJTRegSeq' , -- Ű�� �������� ���� , �� �����Ѵ�. 
                    @TableColumns,
                    '', 
                    @PgmSeq
	-- �۾����� ���߱�: DELETE -> UPDATE -> INSERT
	-- DELETE    
	IF EXISTS (SELECT TOP 1 1 FROM #hencom_TPNPJT WHERE WorkingTag = 'D' AND Status = 0)  
	BEGIN  
			DELETE hencom_TPNPJT
			  FROM #hencom_TPNPJT A 
				   JOIN hencom_TPNPJT B ON ( A.PJTRegSeq = B.PJTRegSeq ) 
                         
			 WHERE B.CompanySeq  = @CompanySeq
			   AND A.WorkingTag = 'D' 
			   AND A.Status = 0    
			 IF @@ERROR <> 0  RETURN
	END  

	-- UPDATE    
	IF EXISTS (SELECT 1 FROM #hencom_TPNPJT WHERE WorkingTag = 'U' AND Status = 0)  
	BEGIN
			UPDATE hencom_TPNPJT
			   SET PlanPJTName      = A.PlanPJTName      ,
                   CustRegSeq       = A.CustRegSeq       ,
                   ShuttleDistance  = A.ShuttleDistance  ,
                   PriceRate        = A.PriceRate        ,
                   UMPriceType      = A.UMPriceType      ,
                   PJTSeq           = A.PJTSeq           ,
                   Remark           = A.Remark           , 
                   UMDistanceDegree = A.UMDistanceDegree 
			  FROM #hencom_TPNPJT AS A 
			       JOIN hencom_TPNPJT AS B ON ( A.PJTRegSeq = B.PJTRegSeq ) 
                         
			 WHERE B.CompanySeq = @CompanySeq
			   AND A.WorkingTag = 'U' 
			   AND A.Status = 0    
			   
			IF @@ERROR <> 0  RETURN
	END  
	-- INSERT
	IF EXISTS (SELECT 1 FROM #hencom_TPNPJT WHERE WorkingTag = 'A' AND Status = 0)  
	BEGIN  
			INSERT INTO hencom_TPNPJT ( CompanySeq,PJTRegSeq,BPYear,DeptSeq,PlanPJTName,ShuttleDistance,
			                            UMPriceType,PriceRate,Remark,LastUserSeq,LastDateTime,PJTSeq,CustRegSeq, UMDistanceDegree  ) 
			SELECT @CompanySeq,PJTRegSeq,BPYear,DeptSeq,PlanPJTName,ShuttleDistance,
			                            UMPriceType,PriceRate,Remark,@UserSeq,GETDATE(),PJTSeq,CustRegSeq, UMDistanceDegree
			  FROM #hencom_TPNPJT AS A   
			 WHERE A.WorkingTag = 'A' 
			   AND A.Status = 0    
			IF @@ERROR <> 0 RETURN
	END   

	SELECT * FROM #hencom_TPNPJT 
RETURN
go
begin tran
exec hencom_SPNPlanPJTSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <PJTRegSeq>37</PJTRegSeq>
    <BPYear>2017</BPYear>
    <DeptSeq>44</DeptSeq>
    <PlanPJTName>���</PlanPJTName>
    <ShuttleDistance>10.00000</ShuttleDistance>
    <UMPriceTypeName>��޴ܰ�6</UMPriceTypeName>
    <PriceRate>85.00000</PriceRate>
    <Remark />
    <PJTName>���</PJTName>
    <PlanCustName />
    <CustRegSeq>0</CustRegSeq>
    <PJTSeq>7477</PJTSeq>
    <UMPriceType>1011588006</UMPriceType>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1038924,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1031709
rollback 