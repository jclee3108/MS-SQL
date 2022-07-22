IF OBJECT_ID('hencom_SPDMESErpApplyGroupDataCreate') IS NOT NULL 
    DROP PROC hencom_SPDMESErpApplyGroupDataCreate
GO 

-- v2017.02.20 
-- Ȯ������ ���� ������ ������ ���� �߰� by����õ 
/************************************************************                                                
��  �� - ������-���Ͽ���ERP�ݿ�_hencom : �հ踶�������ͻ���                                                
�ۼ��� - 20160321                                               
�ۼ��� - �ڼ���        
����: �ð��뺰�������纯������ ����κ� ����by�ڼ���2015.03.21                                          
************************************************************/                                                
CREATE PROC hencom_SPDMESErpApplyGroupDataCreate                                           
    @xmlDocument    NVARCHAR(MAX),                                                  
    @xmlFlags       INT     = 0,                                                  
    @ServiceSeq     INT     = 0,                                                  
    @WorkingTag     NVARCHAR(10)= '',                                                  
    @CompanySeq     INT     = 1,                                                  
    @LanguageSeq    INT     = 1,                                                  
    @UserSeq        INT     = 0,                                                  
    @PgmSeq         INT     = 0                                                                                                  
AS                                                   
                                                      
    DECLARE @docHandle      INT,                                                
            @DateFr         NCHAR(8) ,                                                
            @DeptSeq        INT  ,                                                
            @MessageType    INT,                                                  
            @Status         INT,                                                  
            @Results        NVARCHAR(250)                                                 
                                                      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                                                             
                                                     
                                             
    CREATE TABLE #hencom_TIFProdWorkReportClose (WorkingTag NCHAR(1) NULL)                                                  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TIFProdWorkReportClose'                                                     
    IF @@ERROR <> 0 RETURN                                                  
    
    ---- �ʼ��Է� Message �޾ƿ���                                                  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,                                                  
                          @Status      OUTPUT,                                                  
                          @Results     OUTPUT,                                                  
                          1038               , -- �ʼ��Է� �׸��� �Է����� �ʾҽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ʼ�%')                                                  
                          @LanguageSeq       ,                                                   
                          0,''                                                    
                                                   
                                                     
    SELECT SumMesKey  ,CfmCode                                      
      INTO #TMPSumData                                        
      FROM hencom_TIFProdWorkReportCloseSum AS M                                        
     WHERE M.CompanySeq = @CompanySeq                                        
       AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE Status = 0 AND DeptSeq = M.DeptSeq AND DateFr = M.WorkDate)                                              
       AND ISNULL(M.CfmCode,'0') = (CASE WHEN @WorkingTag = 'Cancel' THEN ISNULL(M.CfmCode,'0') ELSE '0' END)
    
                                   
    IF  EXISTS (SELECT 1 FROM #TMPSumData WHERE CfmCode = '1')                                
    BEGIN                                
        UPDATE #hencom_TIFProdWorkReportClose                                                 
           SET Result        = 'Ȯ��ó���� �����Ͱ� �����ؼ� ó���� �� �����ϴ�.',                                                   
               MessageType   = @MessageType,  
               Status        = @Status                                                 
                               
        SELECT * FROM #hencom_TIFProdWorkReportClose                                                  
        RETURN                                                
    END                                
                                         
        /* ERP�ݿ��� �����ʹ� üũ ,���������ǰ� ERP�ݿ��ȵ� ������ ���� */                                        
         IF EXISTS (SELECT 1                                         
                       FROM hencom_TIFProdWorkReportCloseSum AS M                                        
                       WHERE M.CompanySeq = @CompanySeq                                         
                       AND EXISTS (SELECT 1 FROM #TMPSumData WHERE SumMesKey = M.SumMesKey)                                                      
                       AND (ISNULL(M.ProdIsErpApply,'') <> '' OR ISNULL(M.InvIsErpApply,'') <> '')                                        
        )                                        
         BEGIN                                        
             UPDATE #hencom_TIFProdWorkReportClose                                                
                SET Result        = '�̹� ERP�ݿ��� �����Ͱ� �ֽ��ϴ�.',                                                  
                    MessageType   = @MessageType,                                                   
                    Status        = @Status                                        
                                                         
               SELECT * FROM #hencom_TIFProdWorkReportClose                                         
                                                     
             RETURN                                        
                                                 
         END                                   
       /*���޺����� ó���� ���� �ִ°�� ��� �� ������� �� ��������.      20160810 ���޺������� ����� �� �ֵ��� ������ */   
    /*                        
             UPDATE #hencom_TIFProdWorkReportClose                        
                SET Result = '���޺�����ó���� �����Ͱ� �����մϴ�.',                            
                    MessageType   = @MessageType,                            
                    Status        = @Status                            
             FROM #TMPSumData AS M                        
             WHERE EXISTS                         
             (SELECT 1 FROM hencom_TIFProdWorkReportClose                        
                     WHERE CompanySeq = @CompanySeq                         
                     AND MesKey IN ( SELECT MesKey                        
                                     FROM hencom_TPUSubContrCalc WHERE CompanySeq = @CompanySeq )                        
                     AND SumMesKey = M.SumMesKey )                        
         IF EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE ISNULL(Status,0) <> 0)                      
         BEGIN                      
             SELECT * FROM #hencom_TIFProdWorkReportClose                      
             RETURN                      
         END                    */  
     
  
         /*�԰ݴ�ü��ϵ� �� �ִ� ��� ��� �� ������� �� ��������. */                
         UPDATE #hencom_TIFProdWorkReportClose                        
                SET Result = '�԰ݴ�ü��ϵ� ���� �����մϴ�. �԰ݴ�ü ���� �� ó�������մϴ�.',                            
         MessageType   = @MessageType,                            
                    Status        = @Status                            
                FROM #TMPSumData AS M                           
             WHERE EXISTS (SELECT 1 FROM hencom_TSLCloseSumReplaceMapping                        
                                     WHERE CompanySeq = @CompanySeq                       
                                       AND SumMesKey = M.SumMesKey )                         
         IF EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE ISNULL(Status,0) <> 0)                      
         BEGIN                      
             SELECT * FROM #hencom_TIFProdWorkReportClose                      
             RETURN                      
         END                      
                             
                              
                                                 
         --���������� ���� ����                                        
         DELETE hencom_TIFProdMatInputCloseSum                                         
         FROM hencom_TIFProdMatInputCloseSum AS A                                        
         WHERE A.CompanySeq = @CompanySeq                                          
           AND EXISTS (SELECT 1 FROM #TMPSumData WHERE SumMesKey  = A.SumMesKey)                                        
           IF @@ERROR <> 0 RETURN                                       --���������� ���� ����                                                    
         DELETE hencom_TIFProdWorkReportCloseSum                                         
         FROM hencom_TIFProdWorkReportCloseSum AS M                                        
           WHERE M.CompanySeq = @CompanySeq AND EXISTS (SELECT 1 FROM #TMPSumData WHERE SumMesKey = M.SumMesKey)                                         
         IF @@ERROR <> 0 RETURN                                         
         --���嵥���� �������̺�Ű ������Ʈ                                        
         UPDATE hencom_TIFProdWorkReportClose                                        
           SET SumMesKey = NULL  ,IsErpApply = NULL                                      
         FROM hencom_TIFProdWorkReportClose AS A                           
           WHERE CompanySeq = @CompanySeq AND EXISTS (SELECT 1 FROM #TMPSumData WHERE SumMesKey = A.SumMesKey)                                        
         IF @@ERROR <> 0 RETURN                                         
         --�������絥���� �������̺�Ű ������Ʈ                                        
         UPDATE hencom_TIFProdMatInputClose                                         
         SET SumMesKey = NULL, SumMesSerl = NULL   ,IsErpApply = NULL                                      
         FROM hencom_TIFProdMatInputClose AS A                                        
           WHERE CompanySeq = @CompanySeq AND EXISTS (SELECT 1 FROM #TMPSumData WHERE SumMesKey = A.SumMesKey)                                        
         IF @@ERROR <> 0 RETURN                                         
                                                 
         IF @WorkingTag = 'Cancel' --������ҹ�ư                            
         BEGIN                            
             SELECT * FROM #hencom_TIFProdWorkReportClose                            
             RETURN                            
         END                            

         /*ó���� ������ ���� Meskey ��´�.*/                                                
         SELECT M.MesKey,M.GoodItemSeq ,M.CustSeq ,M.PJTSeq,M.DeptSeq , M.UMOutType ,M.ExpShipSeq ,M.WorkDate,M.OutQty,M.SubContrCarSeq , M.BPNo,C.IsCrtProd ,C.IsCrtInvo,M.ProdQty                                        
         INTO #TMPRowData                                                
         FROM hencom_TIFProdWorkReportClose AS M                                                
           LEFT OUTER  JOIN V_mstm_UMOutType AS C ON C.CompanySeq   = @CompanySeq AND C.MinorSeq = M.UMOutType                                           
         WHERE M.companyseq = @CompanySeq                                                 
             AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE Status = 0 AND DeptSeq = M.DeptSeq AND DateFr = M.WorkDate) 
             AND ISNULL(M.SumMesKey,0) = 0
    
    
    -- üũ, ���� ���� ������ �� �̹� Ȯ�� �� �����Ͱ� �����մϴ�.
    UPDATE #hencom_TIFProdWorkReportClose
       SET Result = '���� ���� ������ �� �̹� Ȯ�� �� �����Ͱ� �����մϴ�.' + 
                    ' ( ���Ͽ�����ȣ : ' + F.ExpShipNo + 
                    ', ���ϱ��� : ' + D.MinorName + 
                    ', ���� : ' + E.PJTName + 
                    ', �ŷ�ó : ' + C.CustName + 
                    ', �԰� : ' + B.ItemName + ' )', 
           MessageType = 1234, 
           Status = 1234 
           
      FROM hencom_TIFProdWorkReportCloseSum AS A 
      LEFT OUTER JOIN _TDAItem              AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq ) 
      LEFT OUTER JOIN _TDACust              AS C ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMOutType ) 
      LEFT OUTER JOIN _TPJTProject          AS E ON ( E.CompanySeq = @CompanySeq AND E.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN hencom_TSLExpShipment AS F ON ( F.CompanySeq = @CompanySeq AND F.ExpShipSeq = A.ExpShipSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (
                   SELECT 1 
                     FROM #TMPRowData 
                    WHERE GoodItemSeq = A.GoodItemSeq
                      AND CustSeq = A.CustSeq 
                      AND PJTSeq = A.PJTSeq 
                      AND DeptSeq = A.DeptSeq 
                      AND UMOutType = A.UMOutType 
                      AND ExpShipSeq  = A.ExpShipSeq
                      AND BPNo = A.BPNo
                  )
    -- üũ, END 
    
--select * from hencom_TIFProdWorkReportClose where deptseq = 42 and workdate = '20151209'
--GROUP  BY M.CompanySeq,M.GoodItemSeq ,M.CustSeq ,M.PJTSeq  ,M.DeptSeq ,M.UMOutType ,M.ExpShipSeq ,M.BPNo                       

                                                     
           --select * from #TMPRowData return                                  
     --select *                                         
     --from hencom_TIFProdWorkReportCloseSum as a                                         
         --left outer join  hencom_TIFProdMatInputCloseSum as b on b.companyseq = a.companyseq and b.summeskey = a.summeskey                                        
     --where a.workdate = '20151110' and a.deptseq = 49                                        
                                   
     --select *                                         
     --from hencom_TIFProdWorkReportClose as a                                        
   --left outer join  hencom_TIFProdMatInputClose as b on b.companyseq = a.companyseq and b.meskey = a.meskey                                         
     --where a.workdate = '20151110' and a.deptseq = 49                                        
     --return                                        
                                                
         IF NOT EXISTS (SELECT 1 FROM #TMPRowData)                                                
           BEGIN                                                 
             UPDATE #hencom_TIFProdWorkReportClose                                                
             SET Result        = 'ó���� �����Ͱ� �����ϴ�.',         
                 MessageType   = @MessageType,                                                  
                     Status         = @Status                                                 
                                
             SELECT * FROM #hencom_TIFProdWorkReportClose                                                
             RETURN                                                
         END                                        
    

                                                         
           UPDATE #hencom_TIFProdWorkReportClose                                                
               SET Result        = @Results+ CASE WHEN ISNULL(R.GoodItemSeq,0) = 0 THEN '(�԰�)' WHEN ISNULL(R.CustSeq,0) = 0 THEN '(�ŷ�ó)'                                         
                                               WHEN ISNULL(R.PJTSeq,0) = 0 THEN '(����)' WHEN ISNULL(R.DeptSeq,0) = 0  THEN '(�����)'                                         
                                               WHEN ISNULL(R.UMOutType,0) = 0 THEN '(�����)'  WHEN ISNULL(R.ExpShipSeq,0) = 0 THEN '(���Ͽ���)'                                         
     --                WHEN ISNULL(R.ProdQty,0) = 0 THEN '(����)'                                         
                                             WHEN ISNULL(R.SubContrCarSeq,0) = 0 THEN '(����)'                                         
                                             WHEN R.IsCrtProd = '1' AND ISNULL(R.ProdQty,0) <> 0 AND (ISNULL(R.BPNo,'') = '' OR R.BPNo = '0') THEN '(ȣ��BP��ȣ)' END ,                                                  
                 MessageType   = @MessageType,                                                  
                 Status        = @Status                                                
           FROM #hencom_TIFProdWorkReportClose AS M                                                 
         JOIN #TMPRowData AS R ON 1=1                                                
         WHERE ISNULL(M.Status,0) = 0                                                
         AND( ISNULL(R.GoodItemSeq,0) = 0  --�԰�                                                
         OR ISNULL(R.CustSeq,0) = 0  --�ŷ�ó                                                
         OR ISNULL(R.PJTSeq,0) = 0  --����                                                
         OR ISNULL(R.DeptSeq,0) = 0  --�μ�                                                
         OR ISNULL(R.UMOutType,0) = 0 --�����                                                 
           OR ISNULL(R.ExpShipSeq,0) = 0   --���Ͽ�����ȣ                                          
         OR ISNULL(R.WorkDate,'') = '' --��������                                                       
     --    OR ((R.IsCrtProd = '1' OR R.IsCrtInvo = '1') AND ISNULL(R.ProdQty,0) = 0) --�������                                
         OR ISNULL(R.SubContrCarSeq,0) = 0 --�������� ERP�����ڵ�                                                
          OR (R.IsCrtProd = '1' AND ISNULL(R.ProdQty,0) <> 0 AND (ISNULL(R.BPNo,'') = '' OR R.BPNo = '0')) --������ ��� ȣ���������� ���üũ(������� 0�� ��� �������� ����)                                               
             )                                                  
                                                       
                                                         
                                
         /*�ʼ��� üũó��*/                                                
     IF EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE ISNULL(Status,0) <> 0)                                                
     BEGIN                                                 
             SELECT * FROM #hencom_TIFProdWorkReportClose                                                
             RETURN                                                
     END              
                 
    --������� ����ų �����ʹ� ǰ���ڻ�з��� ������ �͸� ��������ǵ��� üũ(���꿩�ο� üũ�Ǿ������� ��������� 0�� ��쿡 ���񽺷� �����ؾ� ��.�������� ����)        
       IF EXISTS (SELECT 1         
                   FROM #TMPRowData AS A        
                   JOIN _TDAItem AS I ON I.CompanySeq = @CompanySeq AND I.ItemSeq = A.GoodItemSeq        
                     JOIN _TDAItemAsset AS B ON B.CompanySeq = @CompanySeq AND B.AssetSeq = I.AssetSeq        
                   WHERE ((A.IsCrtProd <> '1' AND A.IsCrtInvo = '1') OR (A.IsCrtProd = '1' AND ISNULL(A.ProdQty,0) = 0 )) AND B.AssetSeq <> 3 --ǰ���ڻ�з�: ����        
                   )        
       BEGIN        
           UPDATE #hencom_TIFProdWorkReportClose                                                
           SET Result        = '������� ����ų ������(������� 0 ����) �߿� ǰ���ڻ�з��� [����] �ƴ� �԰��� �����մϴ�.',                                                  
               MessageType   = @MessageType,                                                  
               Status         = @Status                                                 
              
           SELECT * FROM #hencom_TIFProdWorkReportClose                                                
           RETURN                                                
       END             
               
    --�����ϰ�, ������ 0�� �ƴѵ� ǰ���ڻ�з��� ������ �� üũ.        
       IF EXISTS (SELECT 1         
                   FROM #TMPRowData AS A        
                   JOIN _TDAItem AS I ON I.CompanySeq = @CompanySeq AND I.ItemSeq = A.GoodItemSeq        
                   JOIN _TDAItemAsset AS B ON B.CompanySeq = @CompanySeq AND B.AssetSeq = I.AssetSeq        
                   WHERE A.IsCrtProd = '1' AND ISNULL(A.ProdQty,0) <> 0  AND B.AssetSeq = 3 --ǰ���ڻ�з�: ����        
                   )        
       BEGIN        
           UPDATE #hencom_TIFProdWorkReportClose                                                
           SET Result        = '�����ϰ� ������ 0�� �ƴѵ� ǰ���ڻ�з��� [����]�� �԰��� �����մϴ�.',                                                  
               MessageType   = @MessageType,                                                  
               Status         = @Status                                                 
              
           SELECT * FROM #hencom_TIFProdWorkReportClose                                                  
           RETURN                                                
       END         
          
  --����ų�ǵ� â��ǰ���Ͽ� ��ϵ��� ���� �� üũ        
      IF EXISTS (SELECT 1        
              FROM #TMPRowData   AS M                     
              LEFT OUTER JOIN (SELECT Y.ItemSeq, Z.MngDeptSeq,ISNULL(Y.WHSeq,0) AS WHSeq /*â��ǰ���� ȭ���� ǰ�������� â��*/                                   
                                     FROM _TDAWH AS Z                                        
                JOIN _TDAWHItem AS Y  WITH(NOLOCK) ON Y.CompanySeq = @CompanySeq                                      
                                                            AND Y.WHSeq = Z.WHSeq                                
                          WHERE Z.CompanySeq = @CompanySeq                                     
                                   GROUP BY Z.MngDeptSeq ,Y.ItemSeq,Y.WHSeq) AS SW ON SW.MngDeptSeq = M.DeptSeq AND SW.ItemSeq = M.GoodItemSeq           
              WHERE M.IsCrtInvo = '1' AND ISNULL(SW.WHSeq,0) = 0        
      )        
      BEGIN        
          UPDATE #hencom_TIFProdWorkReportClose                                                
                 SET Result        = '����ų �������߿� â��ǰ���ϵ��� ���� �԰��� �����մϴ�.',                                                  
                   MessageType   = @MessageType,                                                  
                   Status         = @Status                                                 
              
           SELECT * FROM #hencom_TIFProdWorkReportClose                                                
           RETURN                                                
      END        
                                           
         /*�հ踶�������� ����*/                                                 
           SELECT IDENTITY(INT,1,1) AS DataSeq ,'A' AS WorkingTag ,0 AS Status                                                
                         , CONVERT(NVARCHAR(30),'') AS   SumMesKey                                                
                     , M.CompanySeq                                                
                     , M.GoodItemSeq ,M.CustSeq ,M.PJTSeq                                                 
                     ,M.DeptSeq , M.UMOutType ,M.ExpShipSeq ,MAX(M.WorkDate) AS WorkDate                                                 
                     ,SUM(ISNULL(M.ProdQty,0)) AS ProdQty, SUM(ISNULL(M.OutQty,0)) AS OutQty        
                     ,ISNULL(M.BPNo,'') AS BPNo                                          
                    ,CONVERT(DECIMAL(19,5),NULL) AS ItemPrice --���ôܰ�: ����: �԰ݴܰ�                                       
                     ,CONVERT(DECIMAL(19,5),NULL) AS CustPrice --�Ǹű��ذ�                                  
                     ,CONVERT(DECIMAL(19,5),NULL) AS Price --����ܰ�                                  
                     ,CONVERT(DECIMAL(19,5),NULL) AS VATRate        
                     ,NULL AS IsInclusedVAT                                   
                     ,CONVERT(DECIMAL(19,5),NULL) AS CurAmt        
                     ,CONVERT(DECIMAL(19,5),NULL) AS CurVAT                                   
                     ,CONVERT(DECIMAL(19,5),NULL) AS TempAmt                                  
     --                ,MAX(dbo.hencom_FunGetProdDept( @CompanySeq ,M.DeptSeq )) AS ProdDeptSeq                         
     --                ,dbo.hencom_FunGetProdDept( @CompanySeq ,M.DeptSeq ) AS ProdDeptSeq                     
                     ,dbo.hencom_FunGetProdDept( @CompanySeq ,M.GoodItemSeq ) AS ProdDeptSeq        
                     ,0 AS PurDeptSeq  --���Ի����                                   
                     ,0 AS PurGoodItemSeq --���Ի������ �԰�                                  
                     ,dbo.hencom_FnGetFactUnit( @CompanySeq ,M.GoodItemSeq ) AS FactUnit              
                     ,dbo.hencom_FnGetWorkCenter( @CompanySeq ,M.GoodItemSeq) AS WorkCenterSeq              
         INTO #TMPResultData                                                
         FROM hencom_TIFProdWorkReportClose AS M                                                
         LEFT OUTER JOIN hencom_TSLExpShipment AS E ON E.CompanySeq = @CompanySeq AND E.ExpShipSeq = M.ExpShipSeq                                            
         JOIN #TMPRowData AS T ON T.Meskey = M.MesKey                                                
           WHERE M.companyseq = @CompanySeq                 
               GROUP  BY M.CompanySeq,M.GoodItemSeq ,M.CustSeq ,M.PJTSeq  ,M.DeptSeq ,M.UMOutType ,M.ExpShipSeq ,M.BPNo                       
                                                     
     /*����μ��� ������ ��ϵ� ��� -1�� üũ��.: �μ���� ȭ�� ����(����ڵ�ϸ�, ��뱸��)*/            
         IF EXISTS (SELECT 1 FROM #TMPResultData AS A                      
                             LEFT OUTER JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMOutType               
                             WHERE ISNULL(A.ProdDeptSeq,0) = -1 AND C.IsCrtProd = '1' )                                             
         BEGIN                                            
             UPDATE #hencom_TIFProdWorkReportClose                                                
                  SET Result        = '�ش� �μ��� ����μ��� �ߺ���ϵǾ� �ֽ��ϴ�.(�μ����,�������庰����ǰ����)',                                                  
                    MessageType   = @MessageType,                                                  
                    Status        = @Status                                            
                                               
             SELECT * FROM #hencom_TIFProdWorkReportClose                                                
             RETURN                                              
         END                       
                             
     --���굥���� �� ��� ����μ�(��뱸�� : ����)�� ���� ���üũ                                            
         IF EXISTS (SELECT 1 FROM #TMPResultData AS A                                            
                             LEFT OUTER JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMOutType                                             
                          WHERE ISNULL(A.ProdDeptSeq,0) = 0 AND C.IsCrtProd = '1' AND ISNULL(ProdQty,0) <> 0)                                            
         BEGIN                                            
               UPDATE #hencom_TIFProdWorkReportClose                                                
                SET Result        = '����μ���(�μ����,�������庰����ǰ���� ����) ��ϵ��� �ʾҽ��ϴ�.',                                                  
                    MessageType   = @MessageType,                                                  
                    Status        = @Status                                            
                     
               SELECT * FROM #hencom_TIFProdWorkReportClose                                                 
             RETURN                                              
         END                      
          /*�������� ������ ��ϵ� ��� -1�� üũ��.: */                    
         IF EXISTS (SELECT 1 FROM #TMPResultData AS A                  
                             LEFT OUTER JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMOutType                                        
                             WHERE ISNULL(A.FactUnit,0) = -1 AND C.IsCrtProd = '1' )                                             
         BEGIN                                            
             UPDATE #hencom_TIFProdWorkReportClose                                                
                SET Result        = '���������� �ߺ� ��ϵǾ� �ֽ��ϴ�.(�������庰����ǰ����ȭ�� ����)',                                                  
                 MessageType   = @MessageType,                                                    
                    Status        = @Status                                            
                                                             
             SELECT * FROM #hencom_TIFProdWorkReportClose                                                
             RETURN                                              
         END                
         /*�������� ���°�� : */                    
         IF EXISTS (SELECT 1 FROM #TMPResultData AS A                  
                               LEFT OUTER JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMOutType                           
          WHERE ISNULL(A.FactUnit,0) = 0 AND C.IsCrtProd = '1' AND ISNULL(ProdQty,0) <> 0 )                                            
         BEGIN                                            
             UPDATE #hencom_TIFProdWorkReportClose                      
                SET Result        = '���������� ��ϵ��� �ʾҽ��ϴ�.(�������庰����ǰ����ȭ�� ����)',                                                   
                    MessageType   = @MessageType,                                                  
                    Status        = @Status                                            
                  
             SELECT * FROM #hencom_TIFProdWorkReportClose                                                
             RETURN                                              
         END                
           /*��ũ���� �ߺ��� ��� üũ  : */                    
         IF EXISTS (SELECT 1 FROM #TMPResultData AS A                  
         LEFT OUTER JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMOutType                                        
                             WHERE ISNULL(A.WorkCenterSeq,0) = -1 AND C.IsCrtProd = '1' )                                            
         BEGIN                                            
             UPDATE #hencom_TIFProdWorkReportClose                                                
                SET Result  = '��ũ���Ͱ� �ߺ� ��ϵǾ����ϴ�.(��ũ���͵��ȭ�� ����)',                                                  
                    MessageType   = @MessageType,                                          
                    Status        = @Status                                             
                                                             
             SELECT * FROM #hencom_TIFProdWorkReportClose                                                 
             RETURN                                              
         END                
             /*��ũ���� ���°�� : */                     
         IF EXISTS (SELECT 1 FROM #TMPResultData AS A                  
                             LEFT OUTER JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMOutType                                        
                             WHERE ISNULL(A.FactUnit,0) = 0 AND C.IsCrtProd = '1' AND ISNULL(ProdQty,0) <> 0 )                                            
         BEGIN                                            
             UPDATE #hencom_TIFProdWorkReportClose                                                
                SET Result        = '��ũ���Ͱ� ��ϵ��� �ʾҽ��ϴ�.(��ũ���͵��ȭ�� ����)',                                                  
                      MessageType   = @MessageType,                                                   
                    Status        = @Status                                            
                                                             
             SELECT * FROM #hencom_TIFProdWorkReportClose                                                
          RETURN                                              
         END                
                       
                       
           /*���Ի���� ������Ʈ*/                                  
         UPDATE #TMPResultData                                  
           SET PurDeptSeq  = ISNULL((SELECT MngValSeq FROM _TDACustUserDefine WHERE CompanySeq = @CompanySeq AND CustSeq = E.PurCustSeq AND MngSerl = 1000001),0),                                  
             PurGoodItemSeq = ISNULL((SELECT ItemSeq FROM _TDAItem WHERE CompanySeq = @CompanySeq                                   
                                             AND ItemName = I.ItemName --���������� �԰ݸ�Ī�� ������ �԰��� ���Ի���ҿ��� ã�´�.            
                                             AND AssetSeq = I.AssetSeq --ǰ���ڻ�з� ������ ��. by �ڼ��� 2016.01.26                                 
                                             AND DeptSeq = (SELECT MngValSeq FROM _TDACustUserDefine WHERE CompanySeq = @CompanySeq AND CustSeq = E.PurCustSeq AND MngSerl = 1000001)                                    
                                                            ),0)                                  
           FROM #TMPResultData AS M                                   
           LEFT OUTER JOIN hencom_TSLExpShipment AS E ON E.CompanySeq = @CompanySeq AND E.ExpShipSeq = M.ExpShipSeq                    
         LEFT OUTER JOIN _TDAItem AS I ON I.CompanySeq = @CompanySeq AND I.ItemSeq = M.GoodItemSeq                                    
         WHERE M.UMOutType = 8020097 ---����                                  
  
  
     --   select * from #TMPResultData return                                   
         IF EXISTS (SELECT 1 FROM #TMPResultData WHERE UMOutType = 8020097 AND PurDeptSeq = 0 )                                   
         BEGIN                                   
             UPDATE #hencom_TIFProdWorkReportClose                                                
             SET Result        = '������ ��� ���Ի���Ұ� �����ϴ�.',  
                 MessageType   = @MessageType,                                                  
                 Status        = @Status                             
                                                                         
            SELECT * FROM #hencom_TIFProdWorkReportClose           
            RETURN                                                
         END                                  
    
     ---- �ܰ����� ----                                  
         /*0������ ���� ��� ó��*/                                    
     DECLARE @EnvValue1      NVARCHAR(50),                                     
             @EnvValue2      NVARCHAR(50)                                          
                 
     SET ANSI_WARNINGS OFF                                            
     SET ARITHIGNORE ON                                            
     SET ARITHABORT OFF                                        
                                         
      EXEC dbo._SCOMEnv @CompanySeq, 8040, @UserSeq, @@PROCID, @EnvValue1 OUTPUT                                       
      EXEC dbo._SCOMEnv @CompanySeq, 8041, @UserSeq, @@PROCID, @EnvValue2 OUTPUT                                    
                                            
     --     select * from #TMPResultData                                  
     --     return                                  
                                       
       --�ܰ��÷� CustPrice, Price ���� �����ϰ� �����ϰ� Price�� ����ڰ� ȭ�鿡�� ��������.                     
       --�ݾ��� ���ϼ���(OutQty)�� ���.                               
         UPDATE #TMPResultData                                            
            SET ItemPrice      = ISNULL(P.Price,0) , --�԰ݺ��ܰ�                                  
                CustPrice      = ISNULL(ROUND(P.Price*B.PriceRate*0.01,ISNULL(RS.RoundStd,0),1),0), --����ܰ�  : �԰ݺ��ܰ����ȭ���� �ܰ��� �����߰���������� �ܰ��� ������ �ܰ�                                            
                  Price          = ISNULL(ROUND(P.Price*B.PriceRate*0.01,ISNULL(RS.RoundStd,0),1),0), --�ܰ� ISNULL(B.Price,0) * ISNULL(B.PriceRate,0) *0.01 , --������ܰ�  : �����߰����������  �����������                                         
                VATRate        = B.VATRate , --�ΰ�����                                    
                IsInclusedVAT  = B.IsInclusedVAT ,   --�ΰ������Կ���        
                CurVAT          = CASE WHEN  B.IsInclusedVAT = '1' THEN (ROUND(P.Price*B.PriceRate*0.01,ISNULL(RS.RoundStd,0),1) * ISNULL(A.OutQty,0)) /( 10+ B.VATRate * 0.1 )                                     
                                   ELSE (ROUND(P.Price*B.PriceRate*0.01,ISNULL(RS.RoundStd,0),1) * ISNULL(A.OutQty,0)) * B.VATRate * 0.01 END   ,        
                  TempAmt        = ROUND(P.Price * B.PriceRate * 0.01,ISNULL(RS.RoundStd,0),1) * ISNULL(A.OutQty,0)                                    
                                                      
         FROM #TMPResultData AS A                                            
         LEFT OUTER JOIN hencom_VPJTAddInfoDate AS B ON B.CompanySeq = @CompanySeq    /*�����߰��������*/                                                
         AND B.DeptSeq = A.DeptSeq                                                
                                             AND B.PJTSeq = A.PJTSeq                                          
           AND A.WorkDate BETWEEN B.StartDate AND B.EndDate                                          
         LEFT OUTER JOIN  hencom_VSLItemPrice AS P ON P.CompanySeq = @CompanySeq /*�԰ݺ��ܰ����*/                                                
                                             AND P.DeptSeq = A.DeptSeq                                             
                                                  AND P.ItemSeq = A.GoodItemSeq                                              
                                                  AND P.UMPriceType = B.UMPriceType                                          
                                                    AND A.WorkDate BETWEEN P.StartDate AND P.EndDate                                            
             LEFT OUTER JOIN hencom_ViewRoundStd AS RS ON RS.CompanySeq = @CompanySeq                                         
                                                 AND RS.UMTruncateType = B.UMTruncateType                                   
         WHERE A.UMOutType <> 8020097 ---���� �ƴѰ�     
                                      
       --������ ���� ���� �ܰ�����                                  
       UPDATE #TMPResultData                                            
            SET ItemPrice      = ISNULL(P.Price,0) , --�԰ݺ��ܰ�                                  
                CustPrice      = ISNULL(ROUND(P.Price*B.PriceRate*0.01,ISNULL(RS.RoundStd,0),1),0), --����ܰ�  : �԰ݺ��ܰ����ȭ���� �ܰ��� �����߰���������� �ܰ��� ������ �ܰ�                                            
                Price          = ISNULL(ROUND(P.Price*B.PriceRate*0.01,ISNULL(RS.RoundStd,0),1),0), --�ܰ� ISNULL(B.Price,0) * ISNULL(B.PriceRate,0) *0.01 , --������ܰ�  : �����߰����������  �����������                                         
                VATRate        = B.VATRate , --�ΰ�����                                    
                IsInclusedVAT  = B.IsInclusedVAT ,   --�ΰ������Կ���                                      
                  CurVAT         = CASE WHEN B.IsInclusedVAT = '1' THEN (ROUND(P.Price*B.PriceRate*0.01,ISNULL(RS.RoundStd,0),1) * ISNULL(A.OutQty,0)) /( 10+ B.VATRate * 0.1 )                                     
                                   ELSE (ROUND(P.Price*B.PriceRate*0.01,ISNULL(RS.RoundStd,0),1) * ISNULL(A.OutQty,0)) * B.VATRate * 0.01 END   ,                                  
                TempAmt      = ROUND(P.Price * B.PriceRate * 0.01,ISNULL(RS.RoundStd,0),1) * ISNULL(A.OutQty,0)                                    
                                                      
          FROM #TMPResultData AS A                                            
         LEFT OUTER JOIN hencom_VPJTAddInfoDate AS B ON B.CompanySeq = @CompanySeq    /*�����߰��������*/                                           
                                             AND B.DeptSeq = A.PurDeptSeq   
                                             AND B.PJTSeq = A.PJTSeq                                          
                                             AND A.WorkDate BETWEEN B.StartDate AND B.EndDate                                          
         LEFT OUTER JOIN  hencom_VSLItemPrice AS P ON P.CompanySeq = @CompanySeq /*�԰ݺ��ܰ����*/                                                
                                                  AND P.DeptSeq = A.PurDeptSeq                                              
                                                  AND P.ItemSeq = A.PurGoodItemSeq                                              
                                                  AND P.UMPriceType = B.UMPriceType                                          
                                                  AND A.WorkDate BETWEEN P.StartDate AND P.EndDate                                           
    LEFT OUTER JOIN hencom_ViewRoundStd AS RS ON RS.CompanySeq = @CompanySeq                                          
                                                   AND RS.UMTruncateType = B.UMTruncateType                                   
         WHERE A.UMOutType = 8020097 ---���� �ΰ�                           
                                           
                                              
     --     select * from #TMPResultData                                   
     --     return                                  
     --                                       
                                      
         IF @EnvValue1 = 1003001 --�ݿø�                                    
         BEGIN                                    
             UPDATE #TMPResultData                                    
             SET CurVAT = ISNULL(ROUND(CurVAT,0),0), --�Ҽ���ù�ڸ����� �ݿø�                                    
                 CurAmt = ISNULL(CASE WHEN IsInclusedVAT = '1' THEN TempAmt - ROUND(CurVAT,0)                                    
                                    ELSE  TempAmt END , 0 )  --�ݾ�                                    
                                                 
         END                                     
           IF @EnvValue1  = 1003002 --����                                    
         BEGIN                                    
             UPDATE #TMPResultData                                    
             SET CurVAT = ISNULL(ROUND(CurVAT,0,1),0), --�Ҽ���ù�ڸ����� ����                                    
                 CurAmt = ISNULL(CASE WHEN IsInclusedVAT = '1' THEN TempAmt - ROUND(CurVAT,0,1)                                    
                                 ELSE  TempAmt END,0)  --�ݾ�                                    
                                                 
           END                                      
                                             
         IF @EnvValue1 = 1003003 --�ø�                                    
         BEGIN                                    
             UPDATE #TMPResultData                                     
               SET CurVAT = ISNULL(CEILING(CurVAT),0), --�Ҽ������� �ø�                                    
                 CurAmt = ISNULL(CASE WHEN IsInclusedVAT = '1' THEN TempAmt - CEILING(CurVAT)                                    
                                 ELSE  TempAmt END,0)  --�ݾ�                                    
                                                 
         END                     
                                  
           /*�ݾ� üũó��: �ݾ�0�� �� üũ: ������ͻ����ϴ� ��� �ʼ�.*/                                                
     --    IF EXISTS (SELECT 1 FROM #TMPResultData AS A                                            
     --                        LEFT OUTER JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMOutType                                              
     --                        WHERE ISNULL(A.Price,0) = 0 AND C.IsCrtInvo = '1' )                                                  
     --    BEGIN                                                
         --         UPDATE #hencom_TIFProdWorkReportClose                                                
     --        SET Result        = '��� �����ϴ� �������߿� �ݾ��� 0�� �԰�( '+I.ItemName+' )�� �ֽ��ϴ�.'+'(����:'+ P.PJTName+', �����ȣ:'+P.PJTNo+')',                                                  
     --            MessageType   = @MessageType,                                                  
       --            Status        = @Status                                                
       --        FROM #TMPResultData AS A                                             
     --        LEFT OUTER JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMOutType                                             
       --        LEFT OUTER JOIN _TDAItem  AS I ON I.CompanySeq = @CompanySeq AND I.ItemSeq =A.GoodItemSeq                                            
       --        LEFT OUTER  JOIN _TPJTProject AS P ON P.CompanySeq = @CompanySeq AND P.PJTSeq = A.PJTSeq                                            
     --        WHERE ((ISNULL(A.Price,0) = 0 OR A.CurAmt = 0 ) AND C.IsCrtInvo = '1' )                                           
     --                                                            
     --        SELECT * FROM #hencom_TIFProdWorkReportClose                      
     --        RETURN                                              
     --    END                                                 
                                                       
         /*Ű����*/                                                
         DECLARE @MaxSeq INT,                                                  
                 @Count  INT                                                   
          SELECT @Count = Count(1) FROM #TMPResultData WHERE WorkingTag = 'A' AND Status = 0                                                  
         IF @Count >0                                                    
         BEGIN                                                  
                 EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'hencom_TIFProdWorkReportCloseSum','SumMesKey',@Count --rowcount                                                     
               UPDATE #TMPResultData                                                               
                  SET SumMesKey  = @MaxSeq + DataSeq                                                     
           WHERE WorkingTag = 'A'                                                               
                  AND Status = 0                                                   
         END                                  
         IF @@ERROR <> 0 RETURN                                        
     --Ű�� �����ȵ� ��� üũ                                        
         IF EXISTS (SELECT 1 FROM  #TMPResultData  WHERE WorkingTag = 'A'                                                               
                                                         AND Status = 0                                           
                                                         AND ISNULL(SumMesKey ,0) = 0                                                          
                   )                                        
         BEGIN                                         
               UPDATE #hencom_TIFProdWorkReportClose                                 
                SET Result        = 'Key(SumMesKey)���� �������� �ʾҽ��ϴ�.',                                                  
                    MessageType   = @MessageType,                                                   
                    Status        = @Status                                        
                 
              SELECT * FROM #hencom_TIFProdWorkReportClose                                                
             RETURN                                         
         END      
 --0�ܰ����� ó�� by�ڼ��� 2016.02.25    
      UPDATE #TMPResultData    
      SET Price       = 0,                    
          CurAmt      = 0,                    
          CurVAT      = 0,                    
          ItemPrice   = 0,                    
          CustPrice   = 0    
      FROM #TMPResultData AS M    
      JOIN V_mstm_UMOutType AS C ON C.CompanySeq = @CompanySeq AND C.MinorSeq = M.UMOutType    
      WHERE C.SetPrice = 1011590002 --�ܰ�������: 0�ܰ�      
      AND M.Status = 0    
          IF EXISTS (SELECT 1 FROM #TMPResultData WHERE WorkingTag = 'A' AND Status = 0)                                                  
           BEGIN                                                   
                                                     
             INSERT INTO hencom_TIFProdWorkReportCloseSum(CompanySeq,SumMesKey,GoodItemSeq,CustSeq,PJTSeq                                                
                                                         ,DeptSeq,UMOutType,ExpShipSeq,WorkDate ,BPNo                              
,ProdQty,OutQty,CurAmt,CurVAT,Price                                                 
           ,LastUserSeq,LastDateTime,ProdDeptSeq,ItemPrice,CustPrice,VATRate,IsInclusedVAT              
                                                         ,FactUnit,WorkCenterSeq,PurDeptSeq )         
               SELECT CompanySeq, SumMesKey , GoodItemSeq ,CustSeq ,PJTSeq                                                 
                     ,DeptSeq , UMOutType ,ExpShipSeq ,WorkDate  ,BPNo                                               
                     ,ProdQty AS ProdQty, OutQty,  ISNULL(CurAmt,0) , ISNULL(CurVAT,0) , ISNULL(Price,0)                                                
                     ,@UserSeq AS LastUserSeq , GETDATE() AS LastDateTime ,ProdDeptSeq,ISNULL(ItemPrice,0),ISNULL(CustPrice,0),ISNULL(VATRate,0),IsInclusedVAT               
                     ,FactUnit,WorkCenterSeq,PurDeptSeq--���Ի�����߰� 2016.01.11by�ڼ���                                           
             FROM  #TMPResultData                                                 
             IF @@ERROR <> 0 RETURN                               
         
         /*��õ�����Ϳ� ���������� Ű���� ������Ʈ*/                                         
                                                        
           UPDATE hencom_TIFProdWorkReportClose                                                
         SET SumMesKey = B.SumMesKey ,                                      
             IsErpApply = '1'                                      
         FROM hencom_TIFProdWorkReportClose AS A                                 
         JOIN #TMPResultData AS B ON B.CompanySeq = A.CompanySeq                                                 
                                 AND B.GoodItemSeq = A.GoodItemSeq                                                  
                                 AND B.CustSeq = A.CustSeq                                                 
                                 AND B.PJTSeq = B.PJTSeq                                                 
                                 AND B.DeptSeq = A.DeptSeq                                                 
                                 AND B.UMOutType = A.UMOutType                                                 
                                 AND B.ExpShipSeq = A.ExpShipSeq          
                                 AND B.BPNo = A.BPNo                                                
         WHERE A.CompanySeq = @CompanySeq                                                 
         AND EXISTS (SELECT 1 FROM #TMPRowData WHERE MesKey = A.MesKey)                                                                      
                                                
         IF @@ERROR <> 0 RETURN                                                
                           
         /*�������� ���*/                                                  
         SELECT A.CompanySeq ,A.MesKey,A.MesSerl ,A.MatItemName, M.SumMesKey ,A.Qty ,A.MatItemSeq                                              
         INTO #TMPMaiItem                                            
           FROM hencom_TIFProdMatInputClose AS A                                                 
         JOIN #TMPRowData AS B ON B.MesKey = A.MesKey                                                
        JOIN hencom_TIFProdWorkReportClose AS M ON M.MesKey = A.MesKey AND M.CompanySeq = A.CompanySeq                                              
         WHERE A.CompanySeq = @CompanySeq                                   
     --    AND ISNULL(A.Qty,0) <> 0 --��������� 0�ΰ��� ����                                  
         AND ISNULL(A.SumMesKey,'') = ''                                        
       --    AND  NOT EXISTS (SELECT 1 FROM  _TDAUMinor AS UM                            
     --                            LEFT OUTER JOIN _TDAUMinorValue AS UMV ON UMV.companyseq = UM.CompanySeq                             
       --                                                                     AND UMV.MajorSeq = UM.MajorSeq                             
       --                                                                 AND UMV.MinorSeq = UM.minorSeq                             
       --                                                                AND UMV.Serl = 1000001                                
     --               WHERE UM.CompanySeq = @CompanySeq                           
       --                                            AND UM.MajorSeq = 1011629                            
     --                                            AND UM.MinorName = A.MatItemName                          
     --                                            AND ISNULL(UMV.ValueText,'') = '1' --������������ üũ�� �� ����                           
     --                                     )                            
                                                       
       IF EXISTS (SELECT 1 FROM #TMPMaiItem WHERE ISNULL(MatItemName,'') = '')                                              
       BEGIN                                              
    UPDATE #hencom_TIFProdWorkReportClose                                                 
               SET Result        = '����������� ���� �����Ͱ� �ֽ��ϴ�.',                                                  
                   MessageType   = @MessageType,                                                  
                   Status        = @Status                                                  
                                                   
               SELECT * FROM #hencom_TIFProdWorkReportClose                                                
             RETURN                                               
         END               
    --����ݿ��ϴ� ������ε� ���簡 ���� ��� üũ('W1','W2','W3' �����ϰ� ������ 0,���絥���Ͱ� ���°��)  :����- ������, �۾�_�ƽ���     
        IF EXISTS ( SELECT 1         
                   FROM #TMPRowData AS M        
                   WHERE M.IsCrtProd = '1' AND ISNULL(M.ProdQty,0) <> 0  AND DeptSeq NOT IN  (31,53)    
 --               AND ISNULL((SELECT SUM(ISNULL(Qty,0)) FROM #TMPMaiItem WHERE MesKey = M.MesKey AND MatItemName NOT IN('W1','W2','W3')),0) = 0    
                 AND ISNULL((SELECT SUM(ISNULL(Qty,0)) FROM #TMPMaiItem WHERE MesKey = M.MesKey   
                 AND MatItemName NOT IN( SELECT B.MinorName  
                                         FROM _TDAUMinorValue AS A  
                                         LEFT OUTER JOIN _TDAUMinor AS B ON B.CompanySeq = A.CompanySeq AND B.MinorSeq = A.MinorSeq  
                                         WHERE A.CompanySeq = @CompanySeq AND A.MajorSeq = 1011629  
                                         AND  A.Serl = 1000001     
                                         AND ISNULL(A.ValueText,'') = '1' )  
                 ),0) = 0 )
       BEGIN                                               
           UPDATE #hencom_TIFProdWorkReportClose                                                
           SET Result        = '������ �������߿� ������ ���簡 �����ϴ�.',                                                  
               MessageType   = @MessageType,                                                  
               Status        = @Status        
                       
           SELECT * FROM #hencom_TIFProdWorkReportClose                                                
           RETURN                           
       END                        
    

        -- ERP, MES ������ ��ġȮ��, Srt
        DECLARE @ErpQty DECIMAL(19,5), 
                @MesQty DECIMAL(19,5) 


        SELECT @ErpQty = SUM(ISNULL(Qty,0)) 
          FROM hencom_TIFProdMatInputClose AS A WITH(NOLOCK)  
         WHERE A.CompanySeq = @CompanySeq 
           AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE DateFr = A.WorkDate AND DeptSeq = A.DeptSeq) 
    
        SELECT @MesQty = 
               SUM(
                   ISNULL(b_g1, 0) + ISNULL(b_g2, 0) + ISNULL(b_g3, 0) + ISNULL(b_g4, 0) + 
                   ISNULL(b_s1, 0) + ISNULL(b_s2, 0) + ISNULL(b_s3, 0) + ISNULL(b_s4, 0) + 
                   ISNULL(b_ad1, 0) + ISNULL(b_ad2, 0) + ISNULL(b_ad3, 0) + ISNULL(b_ad4, 0) + ISNULL(b_ad5, 0) + ISNULL(b_ad6, 0) +
                   ISNULL(b_w1, 0) + ISNULL(b_w2, 0) + ISNULL(b_w3, 0) + 
                   ISNULL(b_c1, 0) + ISNULL(b_c2, 0) + ISNULL(b_c3, 0) + ISNULL(b_c4, 0) + ISNULL(b_c5, 0) + ISNULL(b_c6, 0)
                  )
          FROM hencom_TIFBCPProdClose AS A with(nolock)
         WHERE A.CompanySeq = @CompanySeq 
           AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE DateFr = A.b_date AND DeptSeq = A.DeptSeq) 
        
        IF ISNULL(@ErpQty,0) <> ISNULL(@MesQty,0)
        BEGIN
            UPDATE #hencom_TIFProdWorkReportClose                                                
            SET Result        = 'ERP�� MES ������ ��ġ���� �ʽ��ϴ�.',                                                  
                MessageType   = 1234,                                                  
                Status        = 1234        
                       
            SELECT * FROM #hencom_TIFProdWorkReportClose                                                
            RETURN   
        END 
        -- ERP, MES ������ ��ġȮ��, End
            --@DeptSeq        INT  ,                                                
            --@MessageType    INT,                                                  
            --@Status         INT,                                                  
            --@Results        NVARCHAR(250)        
 
 
--select sum(IsNull(b_g1, 0) + IsNull(b_g2, 0) + IsNull(b_g3, 0) + IsNull(b_g4, 0) + 
--       IsNull(b_s1, 0) + IsNull(b_s2, 0) + IsNull(b_s3, 0) + IsNull(b_s4, 0) + 
--       IsNull(b_ad1, 0) + IsNull(b_ad2, 0) + IsNull(b_ad3, 0) + IsNull(b_ad4, 0) + IsNull(b_ad5, 0) + IsNull(b_ad6, 0) +
--       IsNull(b_w1, 0) + IsNull(b_w2, 0) + IsNull(b_w3, 0) + 
--       IsNull(b_c1, 0) + IsNull(b_c2, 0) + IsNull(b_c3, 0) + IsNull(b_c4, 0) + IsNull(b_c5, 0) + IsNull(b_c6, 0))
--from    hencom_TIFBCPProdClose with(nolock)
--where   deptseq = 49 and b_date = '20170628'
 
                                                                   
     --    IF EXISTS (SELECT 1 FROM #TMPMaiItem WHERE ISNULL(Qty,0) = 0)                                              
     --    BEGIN                                              
     --          UPDATE #hencom_TIFProdWorkReportClose                                                
     --        SET Result        = '�������� ������ ���� �����Ͱ� �ֽ��ϴ�.',         
       --            MessageType   = @MessageType,                              --            Status        = @Status                                                    
     --                                              
         --        SELECT * FROM #hencom_TIFProdWorkReportClose                                                 
     --        RETURN                                               
     --    END                                              
                                  
                                                     
        SELECT A.SumMesKey, A.MatItemName ,ISNULL(A.MatItemSeq,0) AS MatItemSeq , A.CompanySeq , SUM(B.Qty) AS Qty , ROW_NUMBER() OVER(PARTITION BY A.SumMesKey ORDER BY A.MatItemName ) AS DataSeq                                                  
        INTO #TMPMatItemResult                                                
         FROM #TMPMaiItem AS A                                                
        JOIN hencom_TIFProdMatInputClose AS B ON B.CompanySeq = A.CompanySeq   
                                            AND B.MesKey = A.MesKey   
                                            AND B.MesSerl = A.MesSerl                                                
        GROUP BY A.SumMesKey, A.MatItemName , A.CompanySeq  ,ISNULL(A.MatItemSeq,0)                                          
                                          
         INSERT  INTO hencom_TIFProdMatInputCloseSum (CompanySeq,SumMesKey,SumMesSerl,MatItemName,Qty,LastUserSeq,LastDateTime ,MatItemSeq)                                                              
         SELECT CompanySeq,SumMesKey, DataSeq, MatItemName , Qty ,@UserSeq,GETDATE() ,MatItemSeq                                                  
         FROM #TMPMatItemResult                                                 
         IF @@ERROR <> 0 RETURN                                         
           
         /*�����������̺�  ������Ʈ*/                                                
         UPDATE hencom_TIFProdMatInputClose                                                
         SET SumMesKey = B.SumMesKey ,                                                
             SumMesSerl = C.SumMesSerl  ,                                      
             IsErpApply = '1'                                              
         FROM hencom_TIFProdMatInputClose AS A                                                  
         JOIN #TMPMaiItem AS B ON B.MesKey = A.MesKey AND B.MesSerl = A.MesSerl                                                
         JOIN hencom_TIFProdMatInputCloseSum AS C ON C.CompanySeq = A.CompanySeq   
                                                   AND C.SumMesKey = B.SumMesKey   
                                                   AND C.MatItemName = B.MatItemName    
                                                   AND ISNULL(C.MatItemSeq,0) = ISNULL(B.MatItemSeq,0)                                               
         WHERE A.CompanySeq = @CompanySeq                                                
         IF @@ERROR <> 0 RETURN                                         
      END                                                   
                  
       SELECT * FROM #hencom_TIFProdWorkReportClose       
                             
       --���Ȯ��      
     /*  
 --        select * from hencom_TIFProdWorkReportClosesum where summeskey in (                 
 --        select summeskey from hencom_TIFProdWorkReportClose where workdate = '20151229' and deptseq = 39  )           
          select * from hencom_TIFProdMatInputClose where summeskey in (                 
         select summeskey from hencom_TIFProdWorkReportClose where workdate = '20151231' and deptseq = 40  )   
          select * from hencom_TIFProdMatInputCloseSum where summeskey in (                 
         select summeskey from hencom_TIFProdWorkReportClose where workdate = '20151231' and deptseq = 40  )   
     */  
       RETURN
