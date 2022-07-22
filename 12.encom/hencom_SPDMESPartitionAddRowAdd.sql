IF OBJECT_ID('hencom_SPDMESPartitionAddRowAdd') IS NOT NULL 
    DROP PROC hencom_SPDMESPartitionAddRowAdd
GO 

-- v2017.02.28 

/************************************************************                                      
 ��  �� - ������-���Ͽ���ERP�ݿ�_hencom : ��ȸ                                      
 �ۼ��� - 20150921                                      
 �ۼ��� - ������                                      
************************************************************/                                      
CREATE PROC dbo.hencom_SPDMESPartitionAddRowAdd                                                      
 @xmlDocument   NVARCHAR(MAX) ,                                                  
 @xmlFlags      INT  = 0,                                                  
 @ServiceSeq    INT  = 0,                                                  
 @WorkingTag    NVARCHAR(10)= '',                                                        
 @CompanySeq    INT  = 1,                                                  
 @LanguageSeq   INT  = 1,                                                  
 @UserSeq       INT  = 0,                                                  
 @PgmSeq        INT  = 0                                               
                                          
AS                                              
                                       
    DECLARE @docHandle  INT,                                      
            @MesKey     NVARCHAR(100)           
                                       
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                                                   
                                      
    SELECT  @MesKey = ISNULL(MesKey,'')                                
   FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)                                      
     WITH (MesKey NVARCHAR(100))                                     
    
    SELECT  A.ExpShipSeq     ,                                       
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
            A.UMCarClass, 
            --������ üũ�� ��-----------------                                      
            A.SubContrCarSeq AS SubContrCarSeq,                                      
            A.DeptSeq,                                      
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
      FROM hencom_TIFProdWorkReportClose  AS A WITH (NOLOCK)                                             
      LEFT OUTER JOIN hencom_TSLExpShipment AS EXSP ON EXSP.CompanySeq = @CompanySeq AND EXSP.ExpShipSeq = A.ExpShipSeq                    
      LEFT OUTER JOIN hencom_TPUSubContrCar AS C ON C.CompanySeq = @CompanySeq AND C.SubContrCarSeq = A.SubContrCarSeq                  
     WHERE A.CompanySeq = @CompanySeq            
       AND A.MesKey = @MesKey
     ORDER BY A.WorkDate  ,A.InvPrnTime                         
                      
                                      
RETURN
go
begin tran 
exec hencom_SPDMESPartitionAddRowAdd @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <MesKey>0036_20151209_10002</MesKey>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1511366,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1032936

rollback 