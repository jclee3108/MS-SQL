IF OBJECT_ID('hencom_SSLPrePublicSalesSave') IS NOT NULL 
    DROP PROC hencom_SSLPrePublicSalesSave
GO 

/************************************************************
 ��  �� - ������-���޹����������_hencom : ����
 �ۼ��� - 20160307
 �ۼ��� - ������
************************************************************/
CREATE PROC dbo.hencom_SSLPrePublicSalesSave
	@xmlDocument    NVARCHAR(MAX),  
	@xmlFlags       INT     = 0,  
	@ServiceSeq     INT     = 0,  
	@WorkingTag     NVARCHAR(10)= '',  
	@CompanySeq     INT     = 1,  
	@LanguageSeq    INT     = 1,  
	@UserSeq        INT     = 0,  
	@PgmSeq         INT     = 0  
AS   
	
	CREATE TABLE #hencom_TSLPrePublicSales (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TSLPrePublicSales'     
	IF @@ERROR <> 0 RETURN  
	
	-- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
	EXEC _SCOMLog  @CompanySeq   ,
   				   @UserSeq      ,
   				   'hencom_TSLPrePublicSales', -- �����̺��
   				   '#hencom_TSLPrePublicSales', -- �������̺��
   				   'PPSRegSeq      ' , -- Ű�� �������� ���� , �� �����Ѵ�. 
   				   'companyseq, DeptSeq, LastUserSeq, PPSRegSeq,ItemSeq, Qty, PublicSalesNo, Price, AssignDate, CurAmt, LastDateTime, PJTSeq, CurVat, CustSeq, Remark, DueDate, DelayDate, AddDate, IsAdd, AllotQty, AddQty'
	-- �۾����� ���߱�: DELETE -> UPDATE -> INSERT
	-- DELETE    
	IF EXISTS (SELECT TOP 1 1 FROM #hencom_TSLPrePublicSales WHERE WorkingTag = 'D' AND Status = 0)  
	BEGIN  
			DELETE hencom_TSLPrePublicSales
			  FROM #hencom_TSLPrePublicSales A 
				   JOIN hencom_TSLPrePublicSales B ON ( A.PPSRegSeq      = B.PPSRegSeq ) 
			 WHERE B.CompanySeq  = @CompanySeq
			   AND A.WorkingTag = 'D' 
			   AND A.Status = 0    
			 IF @@ERROR <> 0  RETURN
	END  
	-- UPDATE    
	IF EXISTS (SELECT 1 FROM #hencom_TSLPrePublicSales WHERE WorkingTag = 'U' AND Status = 0)  
	BEGIN
			UPDATE hencom_TSLPrePublicSales
			   SET DeptSeq        = A.DeptSeq        ,
                   LastUserSeq    = @UserSeq    ,
                   ItemSeq        = A.ItemSeq        ,
                   Qty            = IsNull(A.AllotQty,0)+IsNull(A.AddQty,0)    ,
                   PublicSalesNo  = A.PublicSalesNo  ,
                   Price          = A.Price          ,
                   AssignDate     = A.AssignDate     ,
                   CurAmt         = ((IsNull(A.AllotQty,0)+IsNull(A.AddQty,0))*A.Price)/1.1+0.5         ,
                   LastDateTime   = GetDate()   ,
                   PJTSeq         = A.PJTSeq         ,
                   CurVat         = ((IsNull(A.AllotQty,0)+IsNull(A.AddQty,0))*A.Price)-((IsNull(A.AllotQty,0)+IsNull(A.AddQty,0))*A.Price)/1.1+0.5        ,
                   CustSeq        = A.CustSeq        ,
                   Remark         = A.Remark         ,
				   DueDate        = A.DueDate        ,
				   DelayDate      = A.DelayDate      ,
				   AddDate        = A.AddDate        ,
				   IsAdd          = A.IsAdd,
				   AllotQty       = A.AllotQty,
				   AddQty         = A.AddQty
			  FROM #hencom_TSLPrePublicSales AS A 
			       JOIN hencom_TSLPrePublicSales AS B ON ( A.PPSRegSeq      = B.PPSRegSeq ) 
			 WHERE B.CompanySeq = @CompanySeq
			   AND A.WorkingTag = 'U' 
			   AND A.Status = 0    
			   
			IF @@ERROR <> 0  RETURN
	END  
	-- INSERT
	IF EXISTS (SELECT 1 FROM #hencom_TSLPrePublicSales WHERE WorkingTag = 'A' AND Status = 0)  
	BEGIN  
			INSERT INTO hencom_TSLPrePublicSales ( companyseq, DeptSeq        ,LastUserSeq    ,PPSRegSeq      ,
                         ItemSeq        ,Qty            ,PublicSalesNo  ,
                         Price          ,AssignDate     ,CurAmt         ,LastDateTime   ,
                         PJTSeq         ,CurVat         ,CustSeq        ,Remark,
						 DueDate        ,DelayDate      ,AddDate        ,IsAdd,
						 AllotQty       ,AddQty) 
			SELECT @CompanySeq,DeptSeq        , @UserSeq    ,PPSRegSeq      ,
                   ItemSeq        ,Qty            ,PublicSalesNo  ,
                   Price          ,AssignDate     ,((IsNull(A.AllotQty,0)+IsNull(A.AddQty,0))*A.Price)/1.1+0.5         ,GetDate()   ,
                   PJTSeq         ,((IsNull(A.AllotQty,0)+IsNull(A.AddQty,0))*A.Price)-((IsNull(A.AllotQty,0)+IsNull(A.AddQty,0))*A.Price)/1.1+0.5         ,CustSeq        ,Remark,
				   DueDate        ,DelayDate      ,AddDate        ,IsAdd,
				   AllotQty       ,AddQty
			  FROM #hencom_TSLPrePublicSales AS A   
			 WHERE A.WorkingTag = 'A' 
			   AND A.Status = 0    
			IF @@ERROR <> 0 RETURN
	END   
	SELECT * FROM #hencom_TSLPrePublicSales 
RETURN
