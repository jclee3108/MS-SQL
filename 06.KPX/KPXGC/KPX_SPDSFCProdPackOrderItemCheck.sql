  
IF OBJECT_ID('KPX_SPDSFCProdPackOrderItemCheck') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackOrderItemCheck  
GO  
  
-- v2014.11.25  
  
-- �����۾������Է�-ǰ�� üũ by ����õ   
CREATE PROC KPX_SPDSFCProdPackOrderItemCheck  
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
    
    -- ����������üũ: UPDATE, DELETE�� ������ �������� ������ ����ó��  
    IF NOT EXISTS ( SELECT 1   
                      FROM #KPX_TPDSFCProdPackOrderItem AS A   
                      JOIN KPX_TPDSFCProdPackOrderItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.PackOrderSeq = B.PackOrderSeq AND A.PackOrderSerl = B.PackOrderSerl )  
                     WHERE A.WorkingTag IN ( 'U', 'D' )  
                       AND Status = 0   
                  )  
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              7                  , -- �ڷᰡ��ϵǾ������ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                              @LanguageSeq               
          
        UPDATE #KPX_TPDSFCProdPackOrderItem  
           SET Result       = @Results,  
               MessageType  = @MessageType,  
               Status       = @Status  
         WHERE WorkingTag IN ( 'U', 'D' )  
           AND Status = 0   
    END   
    
    -- üũ1, Ȯ�� �� �����ʹ� ���� �� �� �����ϴ�. 
    UPDATE A 
       SET Result       = ' Ȯ�� �� �����ʹ� ���� �� �� �����ϴ�.',  
           MessageType  = 1234,  
           Status       = 1234 
      FROM #KPX_TPDSFCProdPackOrderItem AS A 
      LEFT OUTER JOIN KPX_TPDSFCProdPackOrder_Confirm AS B ON ( B.CompanySeq = @CompanySeq AND B.CfmSeq = A.PackOrderSeq ) 
     WHERE B.CfmCode = '1'  
       AND A.Status = 0 
       AND A.WorkingTag = 'D' 
    
    -- ���� ���� :           
    DECLARE @Serl           INT, 
            @PackOrderSeq   INT 
    
    SELECT @PackOrderSeq = (SELECT TOP 1 PackOrderSeq FROM #KPX_TPDSFCProdPackOrderItem WHERE Status = 0 AND WorkingTag = 'A')
       --    -- Ű�������ڵ�κ� ����  
    SELECT @Serl = ISNULL((SELECT MAX( PackOrderSerl ) FROM KPX_TPDSFCProdPackOrderItem AS A WHERE CompanySeq = @CompanySeq AND PackOrderSeq = @PackOrderSeq),0)
    
    -- Temp Talbe �� ������ ���� ������Ʈ 
        UPDATE #KPX_TPDSFCProdPackOrderItem  
           SET PackOrderSerl = @Serl + DataSeq  
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    SELECT * FROM #KPX_TPDSFCProdPackOrderItem   
      
    RETURN  
GO 
begin tran 
exec KPX_SPDSFCProdPackOrderItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IsStop>0</IsStop>
    <ItemSeq>14503</ItemSeq>
    <UnitSeq>2</UnitSeq>
    <OrderQty>2</OrderQty>
    <LotNo />
    <UMDMMarking>0</UMDMMarking>
    <OutLotNo />
    <PackOnDate />
    <PackReOnDate />
    <Remark />
    <BrandName />
    <SubItemSeq>14528</SubItemSeq>
    <SubUnitSeq>2</SubUnitSeq>
    <SubQty>0</SubQty>
    <NonMarking />
    <PopInfo />
    <PackOrderSeq>18</PackOrderSeq>
    <PackOrderSerl>2</PackOrderSerl>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026147,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021349

rollback 