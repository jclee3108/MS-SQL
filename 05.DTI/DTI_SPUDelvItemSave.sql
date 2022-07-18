
IF OBJECT_ID('DTI_SPUDelvItemSave') IS NOT NULL
    DROP PROC DTI_SPUDelvItemSave
    
GO

--v2013.06.12

-- ���ų�ǰ_DTI (����ó/EndUser �߰�) By����õ
/************************************************************    
 ��  �� - ���Ű��� �� ����    
 �ۼ��� - 2008�� 8�� 20��     
 �ۼ��� - �뿵��    
 ������ - 2009�� 9�� 2��    
 ������ - ����(���˻�ǰ �ڵ��԰� �߰�)    
 ������ - 2010�� 10�� 21��  
 ������ - �̿���( MakerSeq �߰�)  
 ������ - 2011. 12. 30 hkim (�������� ���� ����, ������Ʈ �ǵ��� ����)
 ************************************************************/    
CREATE PROC DTI_SPUDelvItemSave    
    @xmlDocument   NVARCHAR(MAX),      
    @xmlFlags     INT = 0,      
    @ServiceSeq   INT = 0,      
    @WorkingTag   NVARCHAR(10)= '',      
    @CompanySeq   INT = 1,      
    @LanguageSeq  INT = 1,      
    @UserSeq      INT = 0,      
    @PgmSeq       INT = 0      
AS 
    
    DECLARE @VatAccSeq    INT,    
            @QCAutoIn     NCHAR(1),    
            @DelvInSeq    INT,    
            @DelvInSerl   INT,    
            @DelvInNo     NCHAR(12),    
            @DelvInDate   NCHAR(8),    
            @BuyingAccSeq INT    

    -- ���� ����Ÿ ��� ����    
    CREATE TABLE #TPUDelvItem (WorkingTag NCHAR(1) NULL)      
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUDelvItem'         
    IF @@ERROR <> 0 RETURN        
     
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)    
    EXEC _SCOMLog @CompanySeq   ,    
                  @UserSeq      ,    
                  '_TPUDelvItem', -- �����̺��    
                  '#TPUDelvItem', -- �������̺��    
                  'DelvSeq,DelvSerl' , -- Ű�� �������� ���� , �� �����Ѵ�.     
                  'CompanySeq,DelvSeq,DelvSerl,ItemSeq,UnitSeq,    
                   Price,Qty,CurAmt,CurVAT,DomPrice,    
                   DomAmt,DomVAT,IsVAT,StdUnitSeq,StdUnitQty,    
                   SMQcType,QcEmpSeq,QcDate,QcQty,QcCurAmt,    
                   WHSeq,LOTNo,FromSerial,ToSerial,SalesCustSeq,    
                   DelvCustSeq,PJTSeq,WBSSeq,UMDelayType,Remark,    
                   IsReturn,LastUserSeq,LastDateTime,MakerSeq,SourceSeq,SourceSerl,IsFiction,FicRateNum,FicRateDen,EvidSeq'    
    
    -- DELETE        
    IF EXISTS (SELECT TOP 1 1 FROM #TPUDelvItem WHERE WorkingTag = 'D' AND Status = 0)      
    BEGIN      
        DELETE _TPUDelvItem    
          FROM _TPUDelvItem A JOIN #TPUDelvItem B ON ( A.DelvSeq = B.DelvSeq AND A.DelvSerl = B.DelvSerl ) 
         WHERE B.WorkingTag = 'D' AND B.Status = 0 
           AND A.CompanySeq  = @CompanySeq    
        
        IF @@ERROR <> 0  RETURN    
    
    END      
    
    -- UPDATE        
    IF EXISTS (SELECT 1 FROM #TPUDelvItem WHERE WorkingTag = 'U' AND Status = 0)      
    BEGIN    
        UPDATE _TPUDelvItem    
           SET ItemSeq      = B.ItemSeq      ,    
               UnitSeq      = B.UnitSeq      ,    
               Price        = ISNULL(B.Price        , 0),    
               DomPrice     = ISNULL(B.DomPrice     , 0),    
               Qty          = ISNULL(B.Qty          , 0),    
               CurAmt       = ISNULL(B.CurAmt       , 0),    
               DomAmt       = ISNULL(B.DomAmt       , 0),    
               CurVAT       = ISNULL(B.CurVAT       , 0),    
               DomVAT       = ISNULL(B.DomVAT       , 0),    
               IsVAT        = B.IsVAT        ,    
               StdUnitSeq   = B.StdUnitSeq   ,    
               StdUnitQty   = B.StdUnitQty   ,    
               SMQcType     = B.SMQcType     ,    
               QcEmpSeq     = B.QcEmpSeq     ,    
               QcDate       = B.QcDate       ,    
               QcQty        = B.QcQty        ,    
               QcCurAmt     = B.QcCurAmt     ,    
               WHSeq        = B.WHSeq        ,    
               LOTNo        = B.LOTNo        ,    
               FromSerial   = B.FromSerial   ,    
               ToSerial     = B.ToSerial     ,    
               SalesCustSeq = B.SalesCustSeq ,    
               DelvCustSeq  = B.DelvCustSeq  ,    
               PJTSeq       = B.PJTSeq       ,    
               WBSSeq       = B.WBSSeq       ,    
               UMDelayType  = B.UMDelayType  ,    
               Remark       = B.Remark       ,    
               IsReturn     = B.IsReturn     ,    
               LastUserSeq  = @UserSeq,    
               LastDateTime = GETDATE(),  
               MakerSeq     = B.MakerSeq     ,         -- MakerSeq  �߰�  
               IsFiction    = B.IsFiction    ,         --2011. 12. 30 hkim �߰�
               FicRateNum   = B.FicRateNum   ,         --2011. 12. 30 hkim �߰�
               FicRateDen   = B.FicRateDen   ,         --2011. 12. 30 hkim �߰�
               EvidSeq      = B.EvidSeq                --2011. 12. 30 hkim �߰�
          FROM _TPUDelvItem AS A JOIN #TPUDelvItem AS B ON ( A.DelvSeq = B.DelvSeq AND A.DelvSerl = B.DelvSerl ) 
         WHERE B.WorkingTag  = 'U'     
           AND B.Status      = 0        
           AND A.CompanySeq  = @CompanySeq      
             IF @@ERROR <> 0  RETURN    
    END    
     
    -- INSERT    
    IF EXISTS (SELECT 1 FROM #TPUDelvItem WHERE WorkingTag = 'A' AND Status = 0)      
    BEGIN      
        INSERT INTO _TPUDelvItem(CompanySeq   ,DelvSeq      ,DelvSerl     ,ItemSeq      ,UnitSeq      ,    
                                 Price        ,Qty          ,CurAmt       ,DomAmt       ,StdUnitSeq    ,    
                                 StdUnitQty   ,SMQcType     ,QcEmpSeq     ,QcDate       ,QcQty        ,    
                                 QcCurAmt     ,WHSeq        ,LOTNo        ,FromSerial   ,ToSerial     ,    
                                 SalesCustSeq ,DelvCustSeq  ,PJTSeq       ,WBSSeq       ,UMDelayType  ,    
                                 DomPrice     ,CurVAT       ,DomVAT       ,IsVAT        ,    
                                 Remark       ,IsReturn     ,LastUserSeq  ,LastDateTime, MakerSeq     ,       -- MakerSeq  �߰�  
                                 IsFiction    ,FicRateNum   ,FicRateDen   ,EvidSeq, SupplyAmt, SupplyVAT,
                                 Memo1        ,Memo2)    
        SELECT @CompanySeq     ,DelvSeq      ,DelvSerl        ,ItemSeq         ,UnitSeq      ,    
               ISNULL(Price,0)   ,ISNULL(Qty,0)   ,ISNULL(CurAmt,0) ,ISNULL(DomAmt,0) ,StdUnitSeq   ,    
               StdUnitQty        ,SMQcType        ,QcEmpSeq         ,QcDate           ,QcQty        ,    
               QcCurAmt          ,WHSeq           ,LOTNo            ,FromSerial       ,ToSerial     ,    
               SalesCustSeq      ,DelvCustSeq     ,PJTSeq           , WBSSeq          ,UMDelayType  ,    
               ISNULL(DomPrice,0),ISNULL(CurVAT,0),ISNULL(DomVAT,0) ,IsVAT            ,    
               Remark            ,IsReturn        ,@UserSeq         ,GETDATE(),    ISNULL(MakerSeq,0),   -- MakerSeq  �߰�  
               ISNULL(IsFiction, '0')         ,FicRateNum      ,FicRateDen       ,EvidSeq, ISNULL(DomAmt,0), 0,--ISNULL(DomVAT,0)  -- ���ް��� �÷��� ��ȭ �ݾ�, �ΰ��� ������ �߰� 2012. 5. 22 hkim
               SalesCustSeq      ,EndUserSeq
          FROM #TPUDelvItem AS A       
         WHERE A.WorkingTag = 'A' AND A.Status = 0        
         
         IF @@ERROR <> 0 RETURN    
    END       
     
        SELECT * FROM #TPUDelvItem       
     
    RETURN 
GO 
exec DTI_SPUDelvItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <ItemName>@����Ȱ������������</ItemName>
    <ItemNo>@����Ȱ������������</ItemNo>
    <Spec />
    <Price>23.00000</Price>
    <Qty>24.00000</Qty>
    <CurAmt>552.00000</CurAmt>
    <DomPrice>23.00000</DomPrice>
    <DomAmt>552.00000</DomAmt>
    <WHName>(��)û�ֱ���õ�ֱ�ȸ������� ����ġ������ ��</WHName>
    <WHSeq>5</WHSeq>
    <DelvCustName />
    <DelvCustSeq>0</DelvCustSeq>
    <SalesCustName />
    <SalesCustSeq>0</SalesCustSeq>
    <SMQcTypeName>���˻�</SMQcTypeName>
    <SMQcType>6035001</SMQcType>
    <QcDate xml:space="preserve">        </QcDate>
    <QCQty>0.00000</QCQty>
    <QCCurAmt>0.00000</QCCurAmt>
    <QCStdUnitQty>0.00000</QCStdUnitQty>
    <STDUnitName>EA</STDUnitName>
    <STDUnitQty>2.40000</STDUnitQty>
    <StdConvQty>0.10000</StdConvQty>
    <STDUnitSeq>2</STDUnitSeq>
    <ItemSeq>14540</ItemSeq>
    <UnitSeq>2</UnitSeq>
    <LotNo>P201306120003-1</LotNo>
    <FromSerial />
    <Toserial />
    <DelvSeq>133657</DelvSeq>
    <DelvSerl>1</DelvSerl>
    <Remark />
    <LotMngYN xml:space="preserve"> </LotMngYN>
    <PJTName />
    <PJTNo />
    <PJTSeq>0</PJTSeq>
    <WBSName />
    <WBSSeq>0</WBSSeq>
    <BizUnit>1</BizUnit>
    <VATRate>0.00000</VATRate>
    <CurVAT>0.00000</CurVAT>
    <DomVAT>0.00000</DomVAT>
    <IsVAT>0</IsVAT>
    <TotCurAmt>552.00000</TotCurAmt>
    <TotDomAmt>552.00000</TotDomAmt>
    <LotNo_Old />
    <DelvNo>201306120003</DelvNo>
    <ItemSeq_Old>14541</ItemSeq_Old>
    <MakerSeq>0</MakerSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1015948,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1001553
