IF OBJECT_ID('hencom_SPDMesMatItemMappingLinkQuery') IS NOT NULL 
    DROP PROC hencom_SPDMesMatItemMappingLinkQuery
GO 

-- v2017.02.16 

-- �������� �Ǻ��� �� �� �ֵ��� ����
/************************************************************                  
  ��  �� - ������-����Һ������������_hencom : ���α��ذ�������                  
  �ۼ��� - 20150924                  
  �ۼ��� - �ڼ���  
  ����: �ð��뺰�������縦 ���� ������ �� ����ó���� ����Ǿ� �����߷�ó����� ���� �����by�ڼ��� 2016.03.21                  
 ************************************************************/                  
                   
 CREATE PROC dbo.hencom_SPDMesMatItemMappingLinkQuery                               
  @xmlDocument       NVARCHAR(MAX) ,                              
  @xmlFlags          INT  = 0,                              
  @ServiceSeq        INT  = 0,                              
  @WorkingTag        NVARCHAR(10)= '',                                    
  @CompanySeq        INT  = 1,                              
  @LanguageSeq       INT  = 1,                              
  @UserSeq           INT  = 0,                              
  @PgmSeq            INT  = 0                           
                       
 AS                          
     /*0������ ���� ��� ó��*/              
     SET ANSI_WARNINGS OFF              
     SET ARITHIGNORE ON              
     SET ARITHABORT OFF              
                   
     DECLARE @docHandle      INT,                  
             @DeptSeq        INT ,                  
             @StdDate        NCHAR(8)  ,              
             @PJTSeq         INT,      
             @CustSeq        INT,      
             @ExpShipSeq     INT              
                    
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                               
                   
     SELECT  @DeptSeq      = DeptSeq  ,                  
             @StdDate      = StdDate   ,            
             @PJTSeq       = PJTSeq  ,      
             @CustSeq      = CustSeq ,      
             @ExpShipSeq   = ExpShipSeq                 
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)                  
       WITH (DeptSeq     INT ,                  
             StdDate     NCHAR(8) ,               
             PJTSeq          INT,      
             CustSeq         INT,      
             ExpShipSeq      INT        
             )                  
                             
                  
                    
     SELECT  D.SumMesKey,                  
             D.SumMesSerl,           
             M.ExpShipSeq    AS ExpShipSeq ,--���Ͽ��������ڵ�          
             D.MatItemName   AS MatItemType,                  
             D.Qty,                  
             D.Remark,                  
             D.MatUnitSeq,                  
             D.MatItemSeq AS MatItemSeq,                  
             D.StdUnitQty,                  
             D.IsErpApply,                                  
             -----------                    
             M.DeptSeq,                  
             M.WorkDate ,                          
             (SELECT ToolName FROM V_mstm_PDToolBP WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq AND BPNo = M.BPNo) AS ToolName , --ERP��������               
             (SELECT ItemName FROM _TDAItem WHERE CompanySeq = @CompanySeq AND ItemSeq = M.GoodItemSeq)    AS GoodItemName, --���� ����� ǰ��                  
             (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq)      AS DeptName,                  
--             (SELECT SD.ItemSeq                  
--                 FROM hencom_VSLStdMatInputData AS SM                  
--                 JOIN hencom_TPDDeptInputMatItemDet AS SD ON SD.CompanySeq = SM.CompanySeq AND SD.MatItemMstSeq = SM.MatItemMstSeq                  
--                 LEFT OUTER JOIN _TDAUMinor AS SU ON SU.CompanySeq = @CompanySeq AND SU.MinorSeq = SD.UMMatType                  
--                 LEFT OUTER JOIN V_mstm_PDToolBP AS BP ON BP.CompanySeq = @CompanySeq AND BP.ToolSeq = SM.ToolSeq                
--                 WHERE SM.CompanySeq = @CompanySeq   
--                 AND SM.DeptSeq = M.DeptSeq   
  --                 AND M.WorkDate BETWEEN SM.StartDate AND SM.EndDate             
--                 AND SU.MinorName = D.MatItemName                
--                 AND BP.BPNo = M.BPNo ) AS MatItemSeq ,          
                 ----------------------------------------  
             EXSP.ExpShipNo      AS ExpShipNo, --���Ͽ�����ȣ                                        
            (SELECT PJTName FROM _TPJTProject WHERE CompanySeq = @CompanySeq AND PJTSeq = M.PJTSeq )       AS PJTName        ,                          
            (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = EXSP.CustSeq )        AS CustName ,          
             EXSP.CustSeq    AS CustSeq,          
             M.PJTSeq        AS PJTSeq ,  
             M.ProdQty       AS ProdQty         ,        
             M.GoodItemSeq   AS GoodItemSeq     ,
             (SELECT 1 FROM hencom_TPDQCStMix
                    WHERE CompanySeq = @CompanySeq
                    AND DeptSeq = M.DeptSeq
                    AND StYear = LEFT(M.WorkDate,4)
                    AND ItemSeq = M.GoodItemSeq
                    ) AS IsRegMix --ǥ�ع��պ��Ͽ���
            ,ISNULL(M.CfmCode,'0') AS IsCfm
     INTO #TMPResultData                  
     FROM hencom_TIFProdMatInputCloseSum AS D WITH (NOLOCK)                   
     JOIN hencom_TIFProdWorkReportCloseSum AS M WITH (NOLOCK) ON M.CompanySeq = D.CompanySeq AND M.SumMesKey = D.SumMesKey          
     LEFT OUTER JOIN hencom_TSLExpShipment AS EXSP ON EXSP.CompanySeq = @CompanySeq AND EXSP.ExpShipSeq = M.ExpShipSeq                
                           
     WHERE D.CompanySeq = @CompanySeq                  
         AND M.DeptSeq = @DeptSeq                        
         AND M.WorkDate = @StdDate                       
         AND (@PJTSeq =0 OR  M.PJTSeq = @PJTSeq)      
         AND (@CustSeq = 0 OR M.CustSeq = @CustSeq )      
         AND ISNULL(D.Qty,0) <> 0 --���Ե� ������ 0�� ���� ����.    
 --        AND (@ExpShipSeq   = 0 M.ExpShipSeq = @ExpShipSeq )                
                           
                 
     SELECT  A.SumMesKey,                  
             A.SumMesSerl,                  
             A.MatItemType,                  
             A.Qty,                  
             A.Remark,                  
             A.MatUnitSeq,                  
               A.MatItemSeq,                  
 --            A.StdUnitQty,                  
             A.IsErpApply,                  
             A.Qty / (SELECT ConvFactor FROM hencom_VPDConvFactorDate                   
                                 WHERE DeptSeq = A.DeptSeq                   
                          AND ItemSeq = A.MatItemSeq                   
                                 AND A.WorkDate BETWEEN StartDate AND EndDate) AS StdUnitQty,                  
             (SELECT ConvFactor FROM hencom_VPDConvFactorDate                   
                                 WHERE DeptSeq = A.DeptSeq                   
                                 AND ItemSeq = A.MatItemSeq                   
                                 AND A.WorkDate BETWEEN StartDate AND EndDate)  AS ConvFactor,                  
             -----------                  
 --            A.MesNo,                 
             A.ToolName,            
             A.GoodItemName, --���� ����� ǰ��                   
             A.DeptName,                  
             A.DeptSeq,                  
             A.MatItemSeq,                  
             (SELECT ItemName FROM _TDAItem WHERE CompanySeq = @CompanySeq AND ItemSeq = A.MatItemSeq ) AS MatItemName ,        
             A.ExpShipNo     AS ExpShipNo, --���Ͽ�����ȣ             
             A.ExpShipSeq    AS ExpShipSeq ,                             
             A.PJTName       AS PJTName ,                          
             A.CustName      AS CustName ,          
             A.CustSeq       AS CustSeq,          
             A.PJTSeq        AS PJTSeq ,           
             A.ProdQty       AS ProdQty  ,        
             A.GoodItemSeq   AS GoodItemSeq ,
             A.IsRegMix                , 
             A.IsCfm
     FROM #TMPResultData AS A               
     LEFT OUTER JOIN _TDAUMinor AS UM ON UM.CompanySeq = @CompanySeq AND UM.MajorSeq = 1011629 AND UM.MinorName = A.MatItemType  --����������ڵ� : ��������Ÿ��_hncom               
     LEFT OUTER JOIN _TDAUMinorValue AS B ON B.companyseq = UM.CompanySeq     
                                           AND B.MajorSeq = UM.MajorSeq     
                                         AND B.MinorSeq = UM.minorSeq     
                                         AND B.Serl = 1000001    
     WHERE ISNULL(B.ValueText,'') <> '1' --������������ üũ�� �� ����    
     ORDER BY A.ExpShipSeq,UM.MinorSort                  
  
 RETURN
 GO
 exec hencom_SPDMesMatItemMappingLinkQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <DeptSeq>42</DeptSeq>
    <StdDate>20151209</StdDate>
    <PJTSeq />
    <CustSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032296,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1026744