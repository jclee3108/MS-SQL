IF OBJECT_ID('hencom_SSLMesProcMonitorQuery') IS NOT NULL 
    DROP PROC hencom_SSLMesProcMonitorQuery
GO 

-- v2017.03.21 

/************************************************************
   ��  �� - ������-�����Ͼ�����������͸�_hencom : ��ȸ
   �ۼ��� - 20160104
   �ۼ��� - �ڼ���
   ����: �����������������-- ��������üũ by�ڼ���2016.03.21
  ************************************************************/
   CREATE PROC dbo.hencom_SSLMesProcMonitorQuery                
   @xmlDocument      NVARCHAR(MAX) ,            
   @xmlFlags         INT  = 0,            
   @ServiceSeq       INT  = 0,            
   @WorkingTag       NVARCHAR(10)= '',                  
   @CompanySeq       INT  = 1,            
   @LanguageSeq      INT  = 1,            
   @UserSeq          INT  = 0,            
   @PgmSeq           INT  = 0         
      
  AS        
   
     DECLARE @docHandle     INT,
             @DeptSeq       INT, 
             @FrStdDate     NCHAR(8), 
             @ToStdDate     NCHAR(8) 
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    SELECT @DeptSeq     = ISNULL(DeptSeq,0), 
           @FrStdDate   = ISNULL(FrStdDate,''), 
           @ToStdDate   = ISNULL(ToStdDate,'')

     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
     WITH (
             DeptSeq       INT, 
             FrStdDate     NCHAR(8),
             ToStdDate     NCHAR(8) 
          )
    
    -- �Ⱓ ��¥ ��� 
    SELECT Solar AS StdDate 
      INTO #DateFrTo
      FROM _TCOMCalendar AS A 
     WHERE A.Solar BETWEEN @FrStdDate AND @ToStdDate 
    
    CREATE TABLE #TMPDept 
    (
        DeptSeq INT,
        DispSeq INT, 
        StdDate NCHAR(8)
    )
      
    INSERT #TMPDept(DeptSeq,DispSeq,StdDate)
    SELECT A.DeptSeq,A.DispSeq,B.StdDate
      FROM hencom_TDADeptAdd    AS A 
      LEFT OUTER JOIN #DateFrTo AS B ON ( 1 = 1 )
     WHERE CompanySeq = @CompanySeq
       AND ISNULL(UMTotalDiv,0) <> 0
       AND (@DeptSeq = 0 OR DeptSeq = @DeptSeq)
    
      SELECT 
          (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq) AS DeptName ,
          M.DeptSeq AS DeptSeq,
          M.StdDate, 
          DATENAME(DW,M.StdDate) AS StdDay,
          (SELECT MAX(1) FROM hencom_TSLExpShipment WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq AND ExpShipDate = M.StdDate) AS IsExpShip, --���Ͽ�����Ͽ���
          (SELECT 1 FROM hencom_TSLWeather WHERE WDate = M.StdDate AND DeptSeq = M.DeptSeq) AS IsWeather ,--������Ͽ���
          (SELECT MAX(1) FROM hencom_TIFProdWorkReportClose WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq AND WorkDate = M.StdDate) AS IsMesData, --�����ڷ����翩��
          (SELECT MAX(1) FROM hencom_TIFProdWorkReportCloseSum WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq AND WorkDate = M.StdDate) AS IsGroupData,--�����ڷ� ����ó������
          (SELECT MAX(1) FROM hencom_TPUSubContrCalc WHERE CompanySeq = @CompanySeq AND WorkDate = M.StdDate AND DeptSeq = M.DeptSeq) AS IsSubContrCalc, --���޿�ݺ�����ó������
          (SELECT MAX(1) FROM hencom_TIFProdWorkReportCloseSum WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq AND WorkDate = M.StdDate AND CfmCode = '1') AS IsMesCfm, --�����ڷ�����Ȯ������
          (SELECT MAX(1) FROM hencom_TIFProdMatInputCloseSum 
                          WHERE CompanySeq = @CompanySeq 
                          AND ISNULL(StdUnitQty,0) <>  0 
                          AND SumMesKey IN (SELECT SumMesKey FROM hencom_TIFProdWorkReportCloseSum 
                                                              WHERE CompanySeq = @CompanySeq 
                                                              AND WorkDate = M.StdDate 
                                                              AND DeptSeq = M.DeptSeq)) AS IsMatMapping, --�����������
          (SELECT MAX(1) FROM _TPUDelv WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq AND DelvDate = M.StdDate) AS IsDelv,--���ų�ǰ�Է�_hncom  
          (SELECT MAX(1) FROM hencom_TPUFuelIn WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq AND InDate = M.StdDate) AS IsFuelIn, --�����԰� ����
          (SELECT MAX(1) FROM hencom_TPUFuelOut WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq AND OutDate = M.StdDate) AS IsFuelOut, --������� ����
          (SELECT MAX(1) FROM hencom_TIFProdWorkReportCloseSum WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq AND WorkDate = M.StdDate AND (InvIsErpApply = '1' OR ProdIsErpApply = '1') ) AS IsApply --�����ڷ� ERP�ݿ�����
      FROM #TMPDept AS M
      ORDER BY M.DispSeq, M.StdDate
                
   RETURN
   GO
exec hencom_SSLMesProcMonitorQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FrStdDate>20170205</FrStdDate>
    <DeptSeq />
    <ToStdDate>20170206</ToStdDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034211,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1028297
