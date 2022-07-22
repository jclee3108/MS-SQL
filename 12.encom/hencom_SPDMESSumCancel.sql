  
IF OBJECT_ID('hencom_SPDMESSumCancel') IS NOT NULL   
    DROP PROC hencom_SPDMESSumCancel  
GO  
  
-- v2017.02.20
  
-- MES�������(����)-���� by ����õ
CREATE PROC hencom_SPDMESSumCancel  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hencom_TIFProdWorkReportClosesum (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TIFProdWorkReportClosesum'   
    IF @@ERROR <> 0 RETURN    
    
    
    --���������� ���� ����                                        
    DELETE A                                         
      FROM hencom_TIFProdMatInputCloseSum AS A                                        
     WHERE A.CompanySeq = @CompanySeq                                          
       AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClosesum WHERE SumMesKey  = A.SumMesKey)                                        
    
    IF @@ERROR <> 0 RETURN 
    
    --���������� ���� ����                                                    
    DELETE A                                         
      FROM hencom_TIFProdWorkReportCloseSum AS A                                        
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClosesum WHERE SumMesKey = A.SumMesKey)                                         
    
    IF @@ERROR <> 0 RETURN                                         
    
    --���嵥���� �������̺�Ű ������Ʈ                                        
    UPDATE A 
       SET SumMesKey = NULL,
           IsErpApply = NULL                                      
      FROM hencom_TIFProdWorkReportClose AS A                           
     WHERE CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClosesum WHERE SumMesKey = A.SumMesKey)                                        
    
    IF @@ERROR <> 0 RETURN                                         
    
    --�������絥���� �������̺�Ű ������Ʈ                                        
    UPDATE A 
       SET SumMesKey = NULL, SumMesSerl = NULL   ,IsErpApply = NULL                                      
      FROM hencom_TIFProdMatInputClose AS A                                        
     WHERE CompanySeq = @CompanySeq 
        AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClosesum WHERE SumMesKey = A.SumMesKey)                                        
    
    IF @@ERROR <> 0 RETURN                      
    
    SELECT * FROM #hencom_TIFProdWorkReportClosesum 
    
    RETURN  
