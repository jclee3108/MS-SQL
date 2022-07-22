IF OBJECT_ID('hencom_SSLDeptAddInfoSave') IS NOT NULL 
    DROP PROC hencom_SSLDeptAddInfoSave
GO 

-- v2017.05.22 

/************************************************************
  ��  �� - ������-����Ұ���(�߰�����)_hencom : ����
  �ۼ��� - 20151020
  �ۼ��� - �ڼ���
         - 2016.03.17  kth ���ο� �������� �߰�
 ************************************************************/
 CREATE PROC hencom_SSLDeptAddInfoSave
  @xmlDocument    NVARCHAR(MAX),  
  @xmlFlags       INT     = 0,  
  @ServiceSeq     INT     = 0,  
  @WorkingTag     NVARCHAR(10)= '',  
  @CompanySeq     INT     = 1,  
  @LanguageSeq    INT     = 1,  
  @UserSeq        INT     = 0,  
  @PgmSeq         INT     = 0  
  AS   
  
  CREATE TABLE #hencom_TDADeptAdd (WorkingTag NCHAR(1) NULL)  
  EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TDADeptAdd'     
  IF @@ERROR <> 0 RETURN  
      
     DECLARE @TableColumns NVARCHAR(4000)
      
      SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TDADeptAdd') 
  -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
    EXEC _SCOMLog  @CompanySeq   ,
        @UserSeq      ,
        'hencom_TDADeptAdd', -- �����̺��
        '#hencom_TDADeptAdd', -- �������̺��
        'DeptSeq ' , -- Ű�� �������� ���� , �� �����Ѵ�. 
        @TableColumns,
        '', 
        @PgmSeq 
  -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT
   -- DELETE    
  IF EXISTS (SELECT TOP 1 1 FROM #hencom_TDADeptAdd WHERE WorkingTag = 'D' AND Status = 0)  
  BEGIN  
    DELETE hencom_TDADeptAdd
      FROM #hencom_TDADeptAdd A 
     JOIN hencom_TDADeptAdd B ON ( A.DeptSeq = B.DeptSeq ) 
                          
     WHERE B.CompanySeq  = @CompanySeq
       AND A.WorkingTag = 'D' 
       AND A.Status = 0    
     IF @@ERROR <> 0  RETURN
  END  
  
  -- UPDATE    
    IF EXISTS (SELECT 1 FROM #hencom_TDADeptAdd WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN
        UPDATE hencom_TDADeptAdd
           SET  UmAreaLClass      = A.UMAreaLClass      ,
                UMTotalDiv        = A.UMTotalDiv        ,
                DispSeq           = A.DispSeq           ,
                IsLentCarPrice    = A.IsLentCarPrice    ,
                MinRotation       = A.MinRotation       ,
                OracleKey         = A.OracleKey         ,
                Remark            = A.Remark            ,
                LastUserSeq       = @UserSeq            ,
                LastDateTime      = GETDATE()           ,
                ProdDeptSeq       = A.ProdDeptSeq       , -- 2016.03.17  kth ���ο� �������� �߰�
                DispQC            = A.DispQC            , 
                IsUseReport       = A.IsUseReport
          FROM #hencom_TDADeptAdd AS A 
               JOIN hencom_TDADeptAdd AS B ON (A.DeptSeq = B.DeptSeq ) 
                              
         WHERE B.CompanySeq = @CompanySeq
           AND A.WorkingTag = 'U' 
           AND A.Status = 0    
       
    IF @@ERROR <> 0  RETURN
    END  
   -- INSERT
  IF EXISTS (SELECT 1 FROM #hencom_TDADeptAdd WHERE WorkingTag = 'A' AND Status = 0)  
  BEGIN  
             -- 2016.03.17  kth ���ο� �������� �߰�
    INSERT INTO hencom_TDADeptAdd ( CompanySeq,DeptSeq,UmAreaLClass,UMTotalDiv,DispSeq,IsLentCarPrice
                                             ,MinRotation,OracleKey,Remark,LastUserSeq,LastDateTime,ProdDeptSeq,DispQC,IsUseReport) 
    SELECT @CompanySeq,DeptSeq,UMAreaLClass,UMTotalDiv,DispSeq,IsLentCarPrice
                     ,MinRotation,OracleKey,Remark,@UserSeq,GETDATE(),ProdDeptSeq ,DispQC,IsUseReport
      FROM #hencom_TDADeptAdd AS A   
     WHERE A.WorkingTag = 'A' 
       AND A.Status = 0    
    IF @@ERROR <> 0 RETURN
  END   
  
  SELECT * FROM #hencom_TDADeptAdd 
 RETURN
