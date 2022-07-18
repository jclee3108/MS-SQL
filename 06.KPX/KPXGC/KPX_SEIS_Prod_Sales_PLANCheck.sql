  
IF OBJECT_ID('KPX_SEIS_Prod_Sales_PLANCheck') IS NOT NULL   
    DROP PROC KPX_SEIS_Prod_Sales_PLANCheck  
GO  
  
-- v2014.11.24  
  
-- (�濵����)���� �ǸŰ�ȹ-üũ by ����õ   
CREATE PROC KPX_SEIS_Prod_Sales_PLANCheck  
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
      
    CREATE TABLE #KPX_TEIS_PROD_SALES_PLAN( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEIS_PROD_SALES_PLAN'   
    IF @@ERROR <> 0 RETURN   
    
    CREATE TABLE #KPX_TEIS_BC_UR_PLAN( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TEIS_BC_UR_PLAN'   
    IF @@ERROR <> 0 RETURN     
    
    ------------------------------------------------------------------------------------------------
    -- üũ1, �����ǸŰ�ȹ ��Ʈ�� �ű�/����/���� �� ����ι��� �ʼ� �Դϴ�.
    ------------------------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '�����ǸŰ�ȹ ��Ʈ�� �ű�/����/���� �� ����ι��� �ʼ� �Դϴ�.', 
           Status = 1234, 
           MessageType = 1234
      FROM #KPX_TEIS_PROD_SALES_PLAN AS A 
     WHERE A.Status = 0 
       AND A.BizUnit = 0 
    ------------------------------------------------------------------------------------------------
    -- üũ1, END
    ------------------------------------------------------------------------------------------------
    
    SELECT * FROM #KPX_TEIS_PROD_SALES_PLAN 
    
    SELECT * FROM #KPX_TEIS_BC_UR_PLAN
      
    RETURN  
GO 
exec KPX_SEIS_Prod_Sales_PLANCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BizUnitName>�ƻ����</BizUnitName>
    <BizUnit>1</BizUnit>
    <UMURTypeName>����</UMURTypeName>
    <UMURType>1010342001</UMURType>
    <PlanAmt>1</PlanAmt>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <PlanYM>201411</PlanYM>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BizUnitName>�ƻ����</BizUnitName>
    <BizUnit>1</BizUnit>
    <UMURTypeName>�̼���</UMURTypeName>
    <UMURType>1010342002</UMURType>
    <PlanAmt>1</PlanAmt>
    <PlanYM>201411</PlanYM>
  </DataBlock2>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMItemClassLName>test5</UMItemClassLName>
    <UMItemClassL>2003013</UMItemClassL>
    <ProdQty>1</ProdQty>
    <SalesQty>1</SalesQty>
    <SalesAmt>1</SalesAmt>
    <SpendQty>1</SpendQty>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <PlanYM>201411</PlanYM>
    <BizUnit />
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMItemClassLName>ǰ���з�</UMItemClassLName>
    <UMItemClassL>2003047</UMItemClassL>
    <ProdQty>1</ProdQty>
    <SalesQty>1</SalesQty>
    <SalesAmt>1</SalesAmt>
    <SpendQty>1</SpendQty>
    <PlanYM>201411</PlanYM>
    <BizUnit />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026127,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021922