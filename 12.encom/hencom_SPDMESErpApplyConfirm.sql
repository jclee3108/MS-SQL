IF OBJECT_ID('hencom_SPDMESErpApplyConfirm') IS NOT NULL 
    DROP PROC hencom_SPDMESErpApplyConfirm
GO 

-- v2017.02.16 

-- ���Ͽ���ERP�ݿ�-Ȯ�� by����õ
/************************************************************      
  ��  �� - ������-���Ͽ���ERP�ݿ�_hencom : Ȯ��      
  �ۼ��� - 20151203      
  �ۼ��� - �ڼ���     
  ����: �ð��뺰�������纯������ ���� ����2016.03.22by�ڼ��� 
 ************************************************************/      
 CREATE PROC dbo.hencom_SPDMESErpApplyConfirm      
  @xmlDocument    NVARCHAR(MAX),        
  @xmlFlags       INT     = 0,        
  @ServiceSeq     INT     = 0,        
  @WorkingTag     NVARCHAR(10)= '',        
  @CompanySeq     INT     = 1,        
  @LanguageSeq    INT     = 1,        
  @UserSeq        INT     = 0,        
  @PgmSeq         INT     = 0        
       
 AS         
        
  CREATE TABLE #hencom_TIFProdWorkReportCloseSum (WorkingTag NCHAR(1) NULL)        
  EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TIFProdWorkReportCloseSum'           
  IF @@ERROR <> 0 RETURN        
            
     CREATE TABLE #TMPMaster      
     (   WorkingTag      NCHAR(1),      
         Status          INT,      
         CompanySeq      INT,      
         SumMesKey       NVARCHAR(30),      
         DeptSeq         INT,      
         WorkDate        NCHAR(8),      
         InPutCfmCode    NCHAR(1),      
         InvIsErpApply   NCHAR(1),      
         ProdIsErpApply  NCHAR(1),      
         CfmCode         NCHAR(1),    
         UMOutType       INT     
     )      
           
     INSERT #TMPMaster (WorkingTag,Status,CompanySeq,SumMesKey,DeptSeq,WorkDate,InPutCfmCode,InvIsErpApply,ProdIsErpApply,CfmCode,UMOutType)      
     SELECT 'U',0,A.CompanySeq,A.SumMesKey,A.DeptSeq,A.WorkDate,B.CfmCode,A.InvIsErpApply,A.ProdIsErpApply,A.CfmCode  ,A.UMOutType    
     FROM hencom_TIFProdWorkReportCloseSum AS A      
     JOIN #hencom_TIFProdWorkReportCloseSum AS B ON B.DateFr = A.WorkDate AND B.DeptSeq = A.DeptSeq      
     WHERE B.Status = 0 
       AND ISNULL(A.CfmCode,'0') = '0'
    
     DECLARE @MessageType    INT,        
             @Status         INT,        
             @Results        NVARCHAR(250)        
                   
     -- �ʼ��Է� Message �޾ƿ���        
     EXEC dbo._SCOMMessage @MessageType OUTPUT,        
         @Status      OUTPUT,        
         @Results     OUTPUT,        
         1355               , -- �ʼ��Է� �׸��� �Է����� �ʾҽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%����%' )         
         @LanguageSeq       ,         
         0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'  
               
     /*ó���� �����Ͱ� ���� ��� üũ*/
     IF NOT EXISTS (SELECT 1 FROM #TMPMaster)      
     BEGIN      
         UPDATE #hencom_TIFProdWorkReportCloseSum      
            SET Result        = '����ó���� �����Ͱ� �����ϴ�.',        
                MessageType   = @MessageType,        
                Status        = @Status        
               
         SELECT * FROM #hencom_TIFProdWorkReportCloseSum      
         RETURN      
     END  
     
     IF EXISTS (SELECT 1 FROM #TMPMaster WHERE InvIsErpApply = '1' OR ProdIsErpApply = '1')      
     BEGIN      
         UPDATE #hencom_TIFProdWorkReportCloseSum      
            SET Result        = '�̹� ���� �� ����ó�� ����Ǿ� ó���� �� �����ϴ�.',        
                MessageType   = @MessageType,        
                Status        = @Status        
               
         SELECT * FROM #hencom_TIFProdWorkReportCloseSum      
         RETURN      
     END      
           
     IF @WorkingTag = 'N'      
     BEGIN      
         IF NOT EXISTS (SELECT 1 FROM #TMPMaster WHERE InPutCfmCode = '0' AND CfmCode = '1')      
         BEGIN      
             UPDATE #hencom_TIFProdWorkReportCloseSum      
                SET Result        = 'Ȯ���� �����Ͱ� �����ϴ�.',        
                    MessageType   = @MessageType,        
                    Status        = @Status        
                   
             SELECT * FROM #hencom_TIFProdWorkReportCloseSum  
             RETURN      
         END      
     END      
         
     /*������� ����: ���޺�������� ���� �� üũ*/      
     /*���޺����꿡 �Ѱ��̶� ������*/    
 --    IF @WorkingTag <> 'N'      
 --    BEGIN     
 --        UPDATE #hencom_TIFProdWorkReportCloseSum    
 --           SET Result = '���޺�����ó���� �����Ͱ� �����ϴ�.',        
 --               MessageType   = @MessageType,        
 --               Status        = @Status        
 --        FROM #TMPMaster AS M    
 --        WHERE NOT EXISTS     
 --        (SELECT 1 FROM hencom_TIFProdWorkReportClose    
 --                WHERE CompanySeq = @CompanySeq     
 --                AND MesKey IN (SELECT MesKey    
   --                               FROM hencom_TPUSubContrCalc WHERE CompanySeq = @CompanySeq )    
 --                AND SumMesKey = M.SumMesKey)    
 --    END    
 --    
     
     /*��������üũ*/    
     IF @WorkingTag <> 'N' AND EXISTS    
     (    SELECT 1    
         FROM #TMPMaster AS M    
           LEFT OUTER JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = M.UMOutType    
         LEFT OUTER JOIN hencom_TIFProdMatInputCloseSum AS MI ON MI.CompanySeq = @CompanySeq AND MI.SumMesKey = M.SumMesKey    
         LEFT OUTER JOIN _TDAUMinor AS UM ON UM.CompanySeq = @CompanySeq AND UM.MajorSeq = 1011629 AND UM.MinorName = MI.MatItemName  --����������ڵ� : ��������Ÿ��_hncom             
         LEFT OUTER JOIN _TDAUMinorValue AS B ON B.companyseq = UM.CompanySeq       
                                             AND B.MajorSeq = UM.MajorSeq       
                                             AND B.MinorSeq = UM.minorSeq       
                                             AND B.Serl = 1000001      
        WHERE C.IsCrtProd = '1'     
         AND ISNULL(B.ValueText,'') <> '1'   --������������ üũ�� �� ����    
--         AND ISNULL(MI.MatItemSeq,0) = 0     --���Ե� ERPǰ���ڵ�      
         AND ((ISNULL(MI.Qty,0) <> 0 AND ISNULL(MI.StdUnitQty,0) = 0) OR  (ISNULL(MI.Qty,0) <> 0 AND ISNULL(MI.MatItemSeq,0) = 0))        --���Լ����� 0�̾ƴѵ� ����ȯ����� 0�̰ų�, ���Լ�����0�� �ƴѵ� �����ڵ尡 ���°��       
--         WHERE C.IsCrtProd = '1'     
--         AND ISNULL(B.ValueText,'') <> '1'   --������������ üũ�� �� ����    
--         AND ISNULL(MI.MatItemSeq,0) = 0     --���Ե� ERPǰ���ڵ�      
--         AND ISNULL(MI.Qty,0) <> 0           --���Ե� ����    
     )    
     BEGIN    
         UPDATE #hencom_TIFProdWorkReportCloseSum    
                SET Result = '������������� ���� �ʾҽ��ϴ�.',        
                    MessageType   = @MessageType,        
                    Status        = @Status        
     END    
     
     --������ ��� �ݾ� �� �ܰ� 0�� ��� üũ by�ڼ���2015.03.22
    IF @WorkingTag <> 'N'   
    BEGIN 
       IF EXISTS (SELECT 1 FROM #TMPMaster AS B
                            JOIN hencom_TIFProdWorkReportCloseSum AS A ON ( B.CompanySeq = A.CompanySeq AND A.SumMesKey = B.SumMesKey )       
                            WHERE A.CompanySeq = @CompanySeq     
                                AND B.Status = 0
                                AND A.UMOutType = 8020097
                                AND (ISNULL(A.CurAmt,0) = 0 OR ISNULL(A.Price,0) = 0)
                )
        BEGIN
            UPDATE #hencom_TIFProdWorkReportCloseSum
            SET Result = '������ ��� �ܰ� �Ǵ� �ݾ��� 0�� �� �����ϴ�.',        
                MessageType   = @MessageType,        
                Status        = @Status    
        END
            
    END
    
     DECLARE @TableColumns NVARCHAR(4000)      
            
     SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TIFProdWorkReportCloseSum')       
  -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)      
      EXEC _SCOMLog  @CompanySeq   ,      
         @UserSeq      ,      
         'hencom_TIFProdWorkReportCloseSum', -- �����̺��      
         '#TMPMaster', -- �������̺��      
         'SumMesKey  ' , -- Ű�� �������� ���� , �� �����Ѵ�.       
         @TableColumns,      
         '',       
         @PgmSeq       
       
  -- UPDATE          
     IF EXISTS (SELECT 1 FROM #TMPMaster WHERE WorkingTag = 'U' AND Status = 0)        
     BEGIN      
         UPDATE hencom_TIFProdWorkReportCloseSum      
           SET  CfmCode           = B.InputCfmCode ,      
                LastDateTime      = GETDATE(),         
                LastUserSeq       = @UserSeq              
          FROM hencom_TIFProdWorkReportCloseSum AS A       
            JOIN #TMPMaster AS B ON ( B.CompanySeq = A.CompanySeq AND A.SumMesKey = B.SumMesKey )       
         WHERE A.CompanySeq = @CompanySeq      
         --      AND A.WorkingTag = 'U'       
             AND B.Status = 0          
                 
     IF @@ERROR <> 0  RETURN      
     END        
       
     SELECT * FROM #hencom_TIFProdWorkReportCloseSum       
        
 RETURN

go 
begin tran 
exec hencom_SPDMESErpApplyConfirm @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <DateFr>20151209</DateFr>
    <DeptSeq>42</DeptSeq>
    <CfmCode>1</CfmCode>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032173,@WorkingTag=N'Y',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027245
rollback 