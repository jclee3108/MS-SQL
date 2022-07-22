  
IF OBJECT_ID('hencom_SPDMESErpApplyBatchCancelCheck') IS NOT NULL   
    DROP PROC hencom_SPDMESErpApplyBatchCancelCheck  
GO  
  
-- v2017.02.13
  
-- ���Ͽ��� ERP�ݿ����-üũ by����õ 
CREATE PROC hencom_SPDMESErpApplyBatchCancelCheck  
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
      
    CREATE TABLE #hencom_TPDMESErpApplyBatch( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TPDMESErpApplyBatch'   
    IF @@ERROR <> 0 RETURN     
    
    ----------------------------------------------------------------------
    -- üũ1, ó���� �����Ͱ� �����ϴ�.
    ----------------------------------------------------------------------
    DECLARE @DataCnt INT
    SELECT @DataCnt = SUM(CASE WHEN ISNULL(B.ProdIsErpApply,'0') = '0' AND ISNULL(B.InvIsErpApply,'0') = '0' THEN 0 ELSE 1 END)
      FROM #hencom_TPDMESErpApplyBatch                  AS A 
      LEFT OUTER JOIN hencom_TIFProdWorkReportClosesum  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.SumMesKey = A.SumMesKey )
    
    IF ISNULL(@DataCnt,0) = 0 
    BEGIN
        UPDATE A
           SET Result = 'ó���� �����Ͱ� �����ϴ�.', 
               MessageType = 1234, 
               Status = 1234
          FROM #hencom_TPDMESErpApplyBatch AS A 
    END 
    ----------------------------------------------------------------------
    -- üũ1, END 
    ----------------------------------------------------------------------
    
    ----------------------------------------------------------------------
    -- üũ2, ���ݰ�꼭�� ���� �Ǿ� ó�� �� �� �����ϴ�.
    ----------------------------------------------------------------------
    UPDATE A
       SET Result = '���ݰ�꼭�� ���� �Ǿ� ó�� �� �� �����ϴ�.', 
           MessageType = 1234, 
           Status = 1234
      FROM #hencom_TPDMESErpApplyBatch                  AS A 
      LEFT OUTER JOIN hencom_TIFProdWorkReportClosesum  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.SumMesKey = A.SumMesKey )
     WHERE EXISTS (SELECT 1 FROM _TSLSalesBillRelation WHERE CompanySeq = @CompanySeq AND SalesSeq = B.SalesSeq)
       AND A.Status = 0 
    ----------------------------------------------------------------------
    -- üũ2, END
    ----------------------------------------------------------------------
    
    ----------------------------------------------------------------------
    -- üũ3, ���Ҹ���üũ 
    ----------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,                                          
                          @Status      OUTPUT,                                          
                          @Results     OUTPUT,                                           
                          2               , -- �ʼ��Է� �׸��� �Է�����  �ʾҽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%����%')                          
                          @LanguageSeq       ,                                           
                          2637,'����'   -- SELECT * FROM _TCADictionary WHERE Word like '%����%'   
                          
    
    ALTER TABLE #hencom_TPDMESErpApplyBatch ADD BizUnit INT 

    UPDATE A
       SET BizUnit = C.BizUnit 
      FROM #hencom_TPDMESErpApplyBatch                  AS A 
      LEFT OUTER JOIN hencom_TIFProdWorkReportClosesum  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.SumMesKey = A.SumMesKey )
      JOIN _TDAFactUnit                                 AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.FactUnit = B.FactUnit ) 

    UPDATE A
       SET Result        = REPLACE(@Results,'@2',''),                                               
           MessageType   = @MessageType ,                                                
           Status        = @Status         
      FROM #hencom_TPDMESErpApplyBatch                      AS A 
      LEFT OUTER JOIN hencom_TIFProdWorkReportClosesum      AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.SumMesKey = A.SumMesKey ) 
      LEFT OUTER JOIN _TCOMClosingYM                        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq 
                                                                               AND B.ClosingSeq = 69 
                                                                               AND B.UnitSeq = A.BizUnit 
                                                                               AND B.ClosingSeq = LEFT(A.WorkDate,6)
                                                                                 )
     WHERE A.Status = 0 
       AND ISNULL(B.IsClose,'0') = '1' 
    ----------------------------------------------------------------------
    -- üũ3, END 
    ----------------------------------------------------------------------
    
    ----------------------------------------------------------------------
    -- üũ4, �����ǥ�� ����Ǿ� ó�� �� �� �����ϴ�.
    ----------------------------------------------------------------------
    UPDATE A 
       SET Result = '�����ǥ�� ����Ǿ� ó�� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TPDMESErpApplyBatch      AS A 
      JOIN hencom_TIFProdWorkReportCloseSum AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.SumMesKey = A.SumMesKey ) 
      JOIN _TSLSales                        AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.SalesSeq = B.SalesSeq ) 
     WHERE A.Status = 0 
       AND ISNULL(C.SlipSeq,0) <> 0 
    ----------------------------------------------------------------------
    -- üũ4, END 
    ----------------------------------------------------------------------

    ----------------------------------------------------------------------
    -- üũ5, �԰ݴ�ü�� �����Ͽ� ó�� �� �� �����ϴ�. 
    ----------------------------------------------------------------------
    UPDATE A
       SET Result = '�԰ݴ�ü�� �����Ͽ� ó�� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TPDMESErpApplyBatch AS A 
     WHERE A.Status = 0 
       AND EXISTS (SELECT 1 FROM hencom_TSLCloseSumReplaceMapping WHERE CompanySeq = @CompanySeq AND SumMesKey = A.SumMesKey)
    ----------------------------------------------------------------------
    -- üũ5, END 
    ----------------------------------------------------------------------

    
    SELECT * FROM #hencom_TPDMESErpApplyBatch 
      
    RETURN  
    GO 
    
begin tran 
exec hencom_SPDMESErpApplyBatchCancelCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9500</SumMesKey>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032173,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027245
rollback 