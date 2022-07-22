IF OBJECT_ID('hencom_SPNCostOfTransportVarSave') IS NOT NULL 
    DROP PROC hencom_SPNCostOfTransportVarSave
GO 

-- v2017.04.21

/************************************************************  
 ��  �� - ������-�����ȹ��ۺ񺯼����_hencom : ����  
 �ۼ��� - 20161109  
 �ۼ��� - �ڼ���  
************************************************************/  
CREATE PROC dbo.hencom_SPNCostOfTransportVarSave  
 @xmlDocument    NVARCHAR(MAX),    
 @xmlFlags       INT     = 0,    
 @ServiceSeq     INT     = 0,    
 @WorkingTag     NVARCHAR(10)= '',    
 @CompanySeq     INT     = 1,    
 @LanguageSeq    INT     = 1,    
 @UserSeq        INT     = 0,    
 @PgmSeq         INT     = 0    
  
AS     
   
 CREATE TABLE #hencom_TPNCostOfTransportVar (WorkingTag NCHAR(1) NULL)    
 EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TPNCostOfTransportVar'       
 IF @@ERROR <> 0 RETURN    
       
  
 -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
 DECLARE @TableColumns NVARCHAR(4000)  
    SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TPNCostOfTransportVar')   
                      
 -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)                 
    EXEC _SCOMLog  @CompanySeq   ,  
                    @UserSeq      ,  
                    'hencom_TPNCostOfTransportVar', -- �����̺��  
                    '#hencom_TPNCostOfTransportVar', -- �������̺��  
                    'COTVRegSeq ' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                    @TableColumns,
                    '',
                    @PgmSeq   
                                      
 -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT  
  
 -- DELETE      
 IF EXISTS (SELECT TOP 1 1 FROM #hencom_TPNCostOfTransportVar WHERE WorkingTag = 'D' AND Status = 0)    
 BEGIN    
   DELETE hencom_TPNCostOfTransportVar  
     FROM #hencom_TPNCostOfTransportVar A   
       JOIN hencom_TPNCostOfTransportVar B ON ( A.COTVRegSeq = B.COTVRegSeq )   
                           
    WHERE B.CompanySeq  = @CompanySeq  
      AND A.WorkingTag = 'D'   
      AND A.Status = 0      
    IF @@ERROR <> 0  RETURN  
 END    
  
  
 -- UPDATE      
 IF EXISTS (SELECT 1 FROM #hencom_TPNCostOfTransportVar WHERE WorkingTag = 'U' AND Status = 0)    
 BEGIN  
   UPDATE hencom_TPNCostOfTransportVar  
      SET           BPYm            = A.BPYm            ,  
                    OwnMilege       = A.OwnMilege       ,  
                    LentMilege      = A.LentMilege      ,  
                    MTCnt           = A.MTCnt           ,  
                    OilAid          = A.OilAid          ,  
                    LentRotation    = A.LentRotation    ,  
                    WaterUseRate    = A.WaterUseRate    ,  
                    OwnOTRate       = A.OwnOTRate       ,  
                    OwnOTMNRate     = A.OwnOTMNRate     ,  
                    OwnReturnRate   = A.OwnReturnRate   ,  
                    MinPreserveRate = A.MinPreserveRate ,  
                    PayforMeal      = A.PayforMeal      ,  
                    IndusAccidInsur = A.IndusAccidInsur ,  
                    EtcCost         = A.EtcCost         ,  
                    Remark          = A.Remark          ,  
                    LentUseRate     = A.LentUseRate     , --���������
                    LastUserSeq     = @UserSeq          ,  
                    LastDateTime    = GETDATE()         , 
                    LentAvgAmt      = A.LentAvgAmt
     FROM #hencom_TPNCostOfTransportVar AS A   
          JOIN hencom_TPNCostOfTransportVar AS B ON ( A.COTVRegSeq = B.COTVRegSeq )   
                           
    WHERE B.CompanySeq = @CompanySeq  
      AND A.WorkingTag = 'U'   
      AND A.Status = 0      
        
   IF @@ERROR <> 0  RETURN  
 END    
  
 -- INSERT  
 IF EXISTS (SELECT 1 FROM #hencom_TPNCostOfTransportVar WHERE WorkingTag = 'A' AND Status = 0)    
 BEGIN    
   INSERT INTO hencom_TPNCostOfTransportVar ( CompanySeq ,COTVRegSeq ,DeptSeq ,BPYm ,OwnMilege ,LentMilege ,  
                                                        MTCnt ,OilAid ,LentRotation ,WaterUseRate ,OwnOTRate ,OwnOTMNRate ,  
        OwnReturnRate ,MinPreserveRate ,PayforMeal ,IndusAccidInsur ,EtcCost ,  
                                                        Remark ,LastUserSeq ,LastDateTime ,PlanSeq,LentUseRate , LentAvgAmt)   
   SELECT @CompanySeq ,COTVRegSeq ,DeptSeq ,BPYm ,OwnMilege ,LentMilege ,  
      MTCnt ,OilAid ,LentRotation ,WaterUseRate ,OwnOTRate ,OwnOTMNRate ,  
                                                        OwnReturnRate ,MinPreserveRate ,PayforMeal ,IndusAccidInsur ,EtcCost ,  
                                                        Remark ,@UserSeq ,GETDATE() ,PlanSeq  ,LentUseRate , LentAvgAmt
                    
    FROM #hencom_TPNCostOfTransportVar AS A     
    WHERE A.WorkingTag = 'A'   
      AND A.Status = 0      
   IF @@ERROR <> 0 RETURN  
 END     
  
  
 SELECT * FROM #hencom_TPNCostOfTransportVar   
RETURN
