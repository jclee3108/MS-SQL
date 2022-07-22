IF OBJECT_ID('hencom_SPDMESErpApplyBatchQuery') IS NOT NULL 
    DROP PROC hencom_SPDMESErpApplyBatchQuery
GO 

-- v2017.03.08 
/************************************************************                                      
 ��  �� - ������-���Ͽ���ERP�ݿ�_hencom : ��ȸ                                      
 �ۼ��� - 20150921                                      
 �ۼ��� - ������                                      
************************************************************/                                      
                                      
CREATE PROC dbo.hencom_SPDMESErpApplyBatchQuery                                                      
 @xmlDocument   NVARCHAR(MAX) ,                                                  
 @xmlFlags      INT  = 0,                                                  
 @ServiceSeq    INT  = 0,                                                  
 @WorkingTag    NVARCHAR(10)= '',                                                        
 @CompanySeq    INT  = 1,                                                  
 @LanguageSeq   INT  = 1,                                                  
 @UserSeq       INT  = 0,                                                  
 @PgmSeq        INT  = 0                                               
                                          
AS                                              
                                       
    DECLARE @docHandle      INT,                                      
            @DateFr         NCHAR(8),                             
            @DeptSeq        INT,                
            @ExpShipSeq     INT ,  
            @UMOutTypeSeq   INT ,  
            @GoodItemSeq    INT                   
                                       
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                                                   
                                      
    SELECT  @ExpShipSeq     = ISNULL(ExpShipSeq,0),          
            @DateFr         = ISNULL(DateFr,''),                               
            @DeptSeq        = ISNULL(DeptSeq,0)   ,             
            @UMOutTypeSeq   = ISNULL(UMOutTypeSeq ,0)   ,  
            @GoodItemSeq    = ISNULL(GoodItemSeq ,0)                                            
   FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)                                      
     WITH (ExpShipSeq       INT ,         
           DateFr           NCHAR(8),                               
           DeptSeq          INT  ,            
           UMOutTypeSeq     INT  ,  
           GoodItemSeq      INT    
           )                                      
    
    -- ���ҵ� ������ ������ �ʵ��� �Ѵ�.
    SELECT DISTINCT LEFT(A.MesKey,19) AS MesKey
      INTO #PartiontMeskey
      FROM hencom_TIFProdWorkReportClose AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEN(A.MesKey) > 19 
    
    SELECT  A.MesKey         ,                                       
            A.ExpShipSeq     ,                                       
            A.WorkDate       ,                                       
            A.ProdQty       AS ProdQty      ,                                       
            A.OutQty        AS OutQty       ,--ǥ�����                                     
            A.CarNo         AS NewCarNo     ,--�ű�����                                  
            A.CarCode       AS NewCarCode   ,--�ű�����                        
            A.Driver        AS NewDriver    ,--�ű�����                    
            A.GPSDepartTime  ,                                       
            A.GPSArriveTime  ,                                       
            A.Rotation       ,                                      
            A.RealDistance   ,                                       
            CONVERT(NVARCHAR,A.InvCreDateTime,121) AS InvCreDateTime ,                                       
--            CONVERT(DATETIME,A.WorkDate)  AS InvPrnTime ,                
--            CONVERT(NVARCHAR,CONVERT(DATETIME,A.WorkDate+' '+SUBSTRING(A.InvPrnTime,1,2) +':'+SUBSTRING(A.InvPrnTime,3,2)+':'+SUBSTRING(A.InvPrnTime,5,2),121)) AS InvPrnTime , --�������ð�             
                  SUBSTRING(A.WorkDate,1,4)+'-'+SUBSTRING(A.WorkDate,5,2)+'-'+SUBSTRING(A.WorkDate,7,2) +' '+SUBSTRING(A.InvPrnTime,1,2) +':'+SUBSTRING(A.InvPrnTime,3,2)+':'+SUBSTRING(A.InvPrnTime,5,2) AS InvPrnTime , --�������ð�                               
            A.IsNew          ,                                       
              A.WorkOrderSeq   ,                                        
            A.WorkReportSeq  ,                                       
            A.InvoiceSeq     ,                                       
            A.ProdIsErpApply ,                                       
            A.ProdResults    ,                                       
            A.ProdStatus     ,                                       
            A.InvIsErpApply  ,                                       
              A.InvResults     ,                                       
            A.InvStatus      ,                                      
            -----��Ī�����ð�-------------------------------                                      
              (SELECT ItemName FROM _TDAItem WHERE CompanySeq = @CompanySeq AND ItemSeq = A.GoodItemSeq ) AS GoodItemName   ,                                       
              (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq )     AS DeptName       ,                                       
            (SELECT PJTName FROM _TPJTProject WHERE CompanySeq = @CompanySeq AND PJTSeq = A.PJTSeq )    AS PJTName        ,                                      
              (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq )     AS CustName       ,                                      
            A.CustSeq,                                   
            A.PJTSeq ,                              
            A.GoodItemSeq ,                
            (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMOutType )  AS UMOutTypeName  ,                                       
            A.UMOutType AS UMOutTypeSeq,                
            C.CarCode       AS CarCode , --ERP�� ��������                  
            C.CarNo         AS CarNo , --ERP�� ��������                  
            C.Driver        AS Driver ,  --ERP�� ��������                   
            (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = C.UMCarClass)  AS UMCarClassName, --ERP�� ��������                                    
            --������ üũ�� ��-----------------                                      
            A.SubContrCarSeq AS SubContrCarSeq,                                      
            A.DeptSeq,                                      
            A.MesNo ,                                  
            EXSP.ExpShipNo      AS ExpShipNo, --���Ͽ�����ȣ                                
            EXSP.UMExpShipType  AS UMExpShipType , --���Ͽ�������                               
            (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND Minorseq = EXSP.UMExpShipType ) AS UMExpShipTypeName ,                          
            (SELECT ToolName FROM V_mstm_PDToolBP WHERE CompanySeq = A.CompanySeq AND DeptSeq = A.DeptSeq AND BPNo = A.BPNo) AS ToolName , --ERP��������                          
            A.BPNo AS BPNo ,                        
            --�����߰������� �ܰ�����                        
            (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = EXSP.UMPriceType ) AS UMPriceTypeName , --�ܰ�����                        
            dbo.hencom_FunGetItemPrice( @CompanySeq ,A.DeptSeq  ,A.PJTSeq ,A.GoodItemSeq ,EXSP.UMPriceType ,A.WorkDate)  AS Price,                   
            dbo.hencom_FunGetItemPrice( @CompanySeq ,A.DeptSeq  ,A.PJTSeq ,A.GoodItemSeq ,EXSP.UMPriceType ,A.WorkDate) * A.ProdQty AS DomAmt ,                  
            --���Ͽ��� �űԵ�����                  
            A.CustName AS NewCustName,                  
            (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMCarClass) AS NewCarClass,  --�ű��� ��� �ּҿ��� ERP�� ���������ڵ�� �Ѱܹ޴´�.                  
            CASE WHEN ISNULL(A.SumMesKey,'0') = '0' THEN '0' ELSE '1' END  IsSummary --�����ڷ� ����ó������                
      --            (SELECT MAX(Price) FROM hencom_VPJTAddInfoDate WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq AND PJTSeq = A.PJTSeq AND ItemSeq = A.GoodItemSeq AND UMPriceType = EXSP.UMPriceType AND A.WorkDate BETWEEN StartDate AND EndDate) AS Price,                         
  --            (SELECT MAX(Price) FROM hencom_VPJTAddInfoDate WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq AND PJTSeq = A.PJTSeq AND ItemSeq = A.GoodItemSeq AND UMPriceType = EXSP.UMPriceType AND A.WorkDate BETWEEN  StartDate AND EndDate) * A.ProdQty AS DomAmt                        
           ,CASE WHEN LEN(A.MesKey) > 19 THEN '1' ELSE '0' END AS IsPartition
           ,CASE WHEN LEFT(A.MesKey,3) = 'NEW' THEN '1' ELSE '0' END AS IsNewAdd
      FROM hencom_TIFProdWorkReportClose  AS A WITH (NOLOCK)                                             
    LEFT OUTER JOIN hencom_TSLExpShipment AS EXSP ON EXSP.CompanySeq = @CompanySeq AND EXSP.ExpShipSeq = A.ExpShipSeq                    
    LEFT OUTER JOIN hencom_TPUSubContrCar AS C ON C.CompanySeq = @CompanySeq AND C.SubContrCarSeq = A.SubContrCarSeq                  
    WHERE  A.CompanySeq = @CompanySeq            
      AND ((@WorkingTag = '' AND (@ExpShipSeq = 0 OR A.ExpShipSeq = @ExpShipSeq)) OR (@WorkingTag = 'DblQry' AND A.ExpShipSeq = @ExpShipSeq ))     
      AND (@DateFr = ''   OR A.WorkDate = @DateFr )                                
      AND (@DeptSeq = 0   OR A.DeptSeq = @DeptSeq )       
      AND (@UMOutTypeSeq = 0 OR A.UMOutType = @UMOutTypeSeq)  
      AND (@GoodItemSeq = 0 OR A.GoodItemSeq = @GoodItemSeq )                    
      AND NOT EXISTS (SELECT 1 FROM #PartiontMeskey WHERE MesKey = A.MesKey)
   ORDER BY A.WorkDate  ,A.InvPrnTime                         
                      
                                      
RETURN
go
exec hencom_SPDMESErpApplyBatchQuery @xmlDocument=N'<ROOT>
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
    <PJTSeq />
    <CustSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032173,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1026660