IF OBJECT_ID('hencom_SSLPJTBaseIniAmtSave') IS NOT NULL 
    DROP PROC hencom_SSLPJTBaseIniAmtSave
GO 

-- v2017.02.24 
/************************************************************  
 ��  �� - ������-���庰�����ܾ׵��_hencom : ����  
 �ۼ��� - 20160219  
 �ۼ��� - �ڼ���  
************************************************************/  
CREATE PROC dbo.hencom_SSLPJTBaseIniAmtSave  
 @xmlDocument    NVARCHAR(MAX),    
 @xmlFlags       INT     = 0,    
 @ServiceSeq     INT     = 0,    
 @WorkingTag     NVARCHAR(10)= '',    
 @CompanySeq     INT     = 1,    
 @LanguageSeq    INT     = 1,    
 @UserSeq        INT     = 0,    
 @PgmSeq         INT     = 0    
  
AS     
   
 CREATE TABLE #hencom_TSLSalesCreditBasicData (WorkingTag NCHAR(1) NULL)    
 EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TSLSalesCreditBasicData'       
 IF @@ERROR <> 0 RETURN    
       
  -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)  
       
    SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TSLSalesCreditBasicData')  
 -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
 EXEC _SCOMLog  @CompanySeq   ,  
          @UserSeq      ,  
          'hencom_TSLSalesCreditBasicData', -- �����̺��  
          '#hencom_TSLSalesCreditBasicData', -- �������̺��  
          'CBDRegSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.   
          @TableColumns,  
           '',   
           @PgmSeq   
                     
  
 -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT  
  
 -- DELETE      
 IF EXISTS (SELECT TOP 1 1 FROM #hencom_TSLSalesCreditBasicData WHERE WorkingTag = 'D' AND Status = 0)    
 BEGIN    
   DELETE hencom_TSLSalesCreditBasicData  
     FROM #hencom_TSLSalesCreditBasicData A   
       JOIN hencom_TSLSalesCreditBasicData B ON ( A.CBDRegSeq = B.CBDRegSeq )   
                           
    WHERE B.CompanySeq  = @CompanySeq  
      AND A.WorkingTag = 'D'   
      AND A.Status = 0      
    IF @@ERROR <> 0  RETURN  
 END    
  
  
 -- UPDATE      
 IF EXISTS (SELECT 1 FROM #hencom_TSLSalesCreditBasicData WHERE WorkingTag = 'U' AND Status = 0)    
 BEGIN  
   UPDATE hencom_TSLSalesCreditBasicData  
      SET CurAmt     = A.CurAmt     ,  
          DomAmt     = A.CurAmt     ,  
           PJTSeq     = A.PJTSeq     ,  
           DeptSeq    = A.DeptSeq    ,  
           CustSeq    = A.CustSeq  ,  
           Remark     = A.Remark  ,
           BizUnit  =  A.BizUnit,
		   WorkDate = A.WorkDate,
		   ReturnRegSeq = A.ReturnRegSeq
     FROM #hencom_TSLSalesCreditBasicData AS A   
          JOIN hencom_TSLSalesCreditBasicData AS B ON ( A.CBDRegSeq = B.CBDRegSeq )   
                           
    WHERE B.CompanySeq = @CompanySeq  
      AND A.WorkingTag = 'U'   
      AND A.Status = 0      
        
   IF @@ERROR <> 0  RETURN  
 END    
  
 -- INSERT  
 IF EXISTS (SELECT 1 FROM #hencom_TSLSalesCreditBasicData WHERE WorkingTag = 'A' AND Status = 0)    
 BEGIN    
   INSERT INTO hencom_TSLSalesCreditBasicData ( CompanySeq,CBDRegSeq,CustSeq,DeptSeq,PJTSeq,CurrSeq,Qty,CurAmt  
                                                        ,CurVAT,DomAmt,DomVat,Remark,LastUserSeq,LastDateTime,BizUnit,workdate, ReturnRegSeq )   
                                                          
   SELECT @CompanySeq,CBDRegSeq,CustSeq,DeptSeq,PJTSeq,NULL,0,CurAmt  
                ,0,CurAmt,0,Remark,@UserSeq,GETDATE()  ,BizUnit, workdate, ReturnRegSeq
     FROM #hencom_TSLSalesCreditBasicData AS A     
    WHERE A.WorkingTag = 'A'   
      AND A.Status = 0      
   IF @@ERROR <> 0 RETURN  
 END     
    
    SELECT * FROM #hencom_TSLSalesCreditBasicData 
    
    RETURN 
