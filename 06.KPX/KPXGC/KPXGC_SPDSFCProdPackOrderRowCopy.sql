  
IF OBJECT_ID('KPXGC_SPDSFCProdPackOrderRowCopy') IS NOT NULL   
    DROP PROC KPXGC_SPDSFCProdPackOrderRowCopy  
GO  
  
-- v2015.08.18  
  
-- �����۾������Է�(����)-�ູ�� by ����õ 
CREATE PROC KPXGC_SPDSFCProdPackOrderRowCopy  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
      
    CREATE TABLE #KPX_TPDSFCProdPackOrderItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TPDSFCProdPackOrderItem'   
    IF @@ERROR <> 0 RETURN     
    
    
    SELECT IsChangedMst, 
           BrandName, 
           CustName, 
           CustSeq, 
           GHS, 
           HamBa, 
           InWHName, 
           IsBase, 
           IsCS, 
           IsReUse, 
           IsStop, 
           ItemName, 
           ItemNo,
           ItemSeq, 
           LotNo,
           LotNoSeq, 
           NonMarking, 
           OrderQty, 
           '' AS OutLotNo, 
           OutWHName, 
           OutWHSeq, 
           PackingDate, 
           PackingLocation, 
           PackingQty, 
           PackOnDate, 
           0 AS PackOrderSeq , 
           0 AS PackOrderSerl, 
           PackReOnDate, 
           PackUnitName, 
           PackUnitSeq, 
           PopInfo, 
           QCLotNo, 
           Remark, 
           SameName, 
           SourceSeq, 
           SOurceSerl, 
           '' AS SubItemName, 
           '' AS SubItemNo, 
           0 AS SubItemSeq, 
           SubOutWHName, 
           SubOutWHSeq, 
           0 AS SubQty, 
           '' AS SubSpec, 
           '' AS SubUnitName, 
           0 AS SubUnitSeq, 
           TankName, 
           TankSeq, 
           UMDMMarking, 
           UMDMMarkingName, 
           UnitName, 
           UnitSeq, 
           WorkOrderNo
      FROM #KPX_TPDSFCProdPackOrderItem   
     --ORDER BY DataSeq DESC 
    
      
    RETURN  
go
EXEC KPXGC_SPDSFCProdPackOrderRowCopy @xmlDocument = N'<ROOT>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IsStop>0</IsStop>
    <ItemName>@FNS/CNDC/Developer</ItemName>
    <ItemNo>KSYS080227S-02</ItemNo>
    <ItemSeq>13010</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <WorkOrderNo />
    <SourceSeq>0</SourceSeq>
    <SourceSerl>0</SourceSerl>
    <CustSeq>0</CustSeq>
    <CustName />
    <SameName />
    <OrderQty>1</OrderQty>
    <PackUnitName />
    <PackUnitSeq />
    <LotNo />
    <IsBase>0</IsBase>
    <UMDMMarkingName>ǥ��</UMDMMarkingName>
    <UMDMMarking>1010344001</UMDMMarking>
    <OutLotNo>��</OutLotNo>
    <QCLotNo>��</QCLotNo>
    <PackingDate>20150811</PackingDate>
    <PackOnDate />
    <IsReUse>0</IsReUse>
    <PackReOnDate />
    <Remark>���</Remark>
    <HamBa />
    <BrandName />
    <GHS />
    <SubItemName>������-��ǰ������</SubItemName>
    <SubItemNo>������-��ǰ������</SubItemNo>
    <SubSpec />
    <SubUnitName>Kg</SubUnitName>
    <SubItemSeq>1001867</SubItemSeq>
    <SubUnitSeq>2</SubUnitSeq>
    <PackingQty>0</PackingQty>
    <PackingLocation>��</PackingLocation>
    <SubQty>0</SubQty>
    <NonMarking>��</NonMarking>
    <PopInfo />
    <PackOrderSeq>161</PackOrderSeq>
    <PackOrderSerl>1</PackOrderSerl>
    <TankName>12</TankName>
    <TankSeq>5</TankSeq>
    <OutWHSeq>49</OutWHSeq>
    <OutWHName>����1��</OutWHName>
    <InWHSeq>49</InWHSeq>
    <InWHName>����1��</InWHName>
    <SubOutWHSeq>49</SubOutWHSeq>
    <SubOutWHName>����1��</SubOutWHName>
    <IsCS>1</IsCS>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IsStop>0</IsStop>
    <ItemName>@FNS/CNDC/Developer</ItemName>
    <ItemNo>KSYS080227S-02</ItemNo>
    <ItemSeq>13010</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <WorkOrderNo />
    <SourceSeq>0</SourceSeq>
    <SourceSerl>0</SourceSerl>
    <CustSeq>0</CustSeq>
    <CustName />
    <SameName />
    <OrderQty>2</OrderQty>
    <PackUnitName />
    <PackUnitSeq />
    <LotNo />
    <IsBase>0</IsBase>
    <UMDMMarkingName>��ǥ��</UMDMMarkingName>
    <UMDMMarking>1010344002</UMDMMarking>
    <OutLotNo>��</OutLotNo>
    <QCLotNo>��</QCLotNo>
    <PackingDate>20150812</PackingDate>
    <PackOnDate />
    <IsReUse>0</IsReUse>
    <PackReOnDate />
    <Remark>���2</Remark>
    <HamBa />
    <BrandName />
    <GHS />
    <SubItemName>���ڷ����</SubItemName>
    <SubItemNo>DYC001Yong</SubItemNo>
    <SubSpec />
    <SubUnitName>Kg</SubUnitName>
    <SubItemSeq>1051292</SubItemSeq>
    <SubUnitSeq>2</SubUnitSeq>
    <PackingQty>0</PackingQty>
    <PackingLocation>��</PackingLocation>
    <SubQty>0</SubQty>
    <NonMarking>��</NonMarking>
    <PopInfo />
    <PackOrderSeq>161</PackOrderSeq>
    <PackOrderSerl>2</PackOrderSerl>
    <TankName>��ũ1231</TankName>
    <TankSeq>4</TankSeq>
    <OutWHSeq>49</OutWHSeq>
    <OutWHName>����1��</OutWHName>
    <InWHSeq>49</InWHSeq>
    <InWHName>����1��</InWHName>
    <SubOutWHSeq>49</SubOutWHSeq>
    <SubOutWHName>����1��</SubOutWHName>
    <IsCS>1</IsCS>
  </DataBlock2>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 1031473, @WorkingTag = N'', @CompanySeq = 1, @LanguageSeq = 1, @UserSeq = 50322, @PgmSeq = 1026201