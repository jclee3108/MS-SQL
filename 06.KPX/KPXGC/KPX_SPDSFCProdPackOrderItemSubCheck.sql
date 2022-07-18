  
IF OBJECT_ID('KPX_SPDSFCProdPackOrderItemSubCheck') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackOrderItemSubCheck  
GO  
  
-- v2014.11.25  
  
-- �����۾������Է�-ǰ��Sub üũ by ����õ   
CREATE PROC KPX_SPDSFCProdPackOrderItemSubCheck  
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
      
    CREATE TABLE #KPX_TPDSFCProdPackOrderItemSub( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock4', '#KPX_TPDSFCProdPackOrderItemSub'   
    IF @@ERROR <> 0 RETURN     
    
    -- üũ1, Ȯ�� �� �����ʹ� ���� �� �� �����ϴ�. 
    UPDATE A 
       SET Result       = ' Ȯ�� �� �����ʹ� ���� �� �� �����ϴ�.',  
           MessageType  = 1234,  
           Status       = 1234 
      FROM #KPX_TPDSFCProdPackOrderItemSub AS A 
      LEFT OUTER JOIN KPX_TPDSFCProdPackOrder_Confirm AS B ON ( B.CompanySeq = @CompanySeq AND B.CfmSeq = A.PackOrderSeq ) 
     WHERE B.CfmCode = '1'  
       AND A.Status = 0 
       AND A.WorkingTag = 'D' 
    -- üũ1, END 
    
    -- ���� ���� :           
    DECLARE @Serl           INT, 
            @PackOrderSeq   INT, 
            @PackOrderSerl  INT 
    
    SELECT @PackOrderSeq = (SELECT TOP 1 PackOrderSeq FROM #KPX_TPDSFCProdPackOrderItemSub WHERE Status = 0 AND WorkingTag = 'A')
    SELECT @PackOrderSerl = (SELECT TOP 1 PackOrderSerl FROM #KPX_TPDSFCProdPackOrderItemSub WHERE Status = 0 AND WorkingTag = 'A')
       --    -- Ű�������ڵ�κ� ����  
    SELECT @Serl = ISNULL((SELECT MAX( PackOrderSubSerl ) FROM KPX_TPDSFCProdPackOrderItemSub AS A WHERE CompanySeq = @CompanySeq AND PackOrderSeq = @PackOrderSeq AND PackOrderSerl = @PackOrderSerl),0)
    
    -- Temp Talbe �� ������ ���� ������Ʈ 
        UPDATE #KPX_TPDSFCProdPackOrderItemSub  
           SET PackOrderSubSerl = @Serl + DataSeq  
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    SELECT * FROM #KPX_TPDSFCProdPackOrderItemSub   
    
    RETURN  
GO 
exec KPX_SPDSFCProdPackOrderItemSubCheck @xmlDocument=N'<ROOT>
  <DataBlock4>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <InDate>20140123</InDate>
    <InQty>123</InQty>
    <Remark />
    <PackOrderSubSerl>1</PackOrderSubSerl>
    <TABLE_NAME>DataBlock4</TABLE_NAME>
    <PackOrderSeq>19</PackOrderSeq>
    <PackOrderSerl>1</PackOrderSerl>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <InDate>20140123</InDate>
    <InQty>123</InQty>
    <Remark />
    <PackOrderSubSerl>2</PackOrderSubSerl>
    <PackOrderSeq>19</PackOrderSeq>
    <PackOrderSerl>1</PackOrderSerl>
  </DataBlock4>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026147,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021349