  
IF OBJECT_ID('hencom_SPDMESPartitionAddCheck') IS NOT NULL   
    DROP PROC hencom_SPDMESPartitionAddCheck  
GO  
  
-- v2017.03.24
  
-- ������ҹ��߰�-üũ by ����õ
CREATE PROC hencom_SPDMESPartitionAddCheck  
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
      
    CREATE TABLE #hencom_TIFProdWorkReportClose( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TIFProdWorkReportClose'   
    IF @@ERROR <> 0 RETURN     
    
    

    DECLARE @IsPartition NCHAR(1) 

    SELECT @IsPartition = (SELECT MAX(IsPartition) FROM #hencom_TIFProdWorkReportClose)

    
    IF @IsPartition = '1' 
    BEGIN 
        -- ���� �� ����MesKey�� �߰��� �ο�
        DECLARE @MaxMesKey  INT 

        SELECT @MaxMesKey = CONVERT(INT,RIGHT(A.MesKey,3))
          FROM hencom_TIFProdWorkReportClose    AS A 
          JOIN #hencom_TIFProdWorkReportClose   AS B ON ( B.MesKey = LEFT(A.MesKey,19) ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND LEN(A.MesKey) > 19 
    
        SELECT @MaxMesKey = ISNULL(@MaxMesKey,0)
    
    

        UPDATE A
           SET NewMesKey = A.MesKey + '_' + RIGHT('00' + CONVERT(NVARCHAR(20),@MaxMesKey + A.DataSeq),3)
          FROM #hencom_TIFProdWorkReportClose AS A 
         WHERE A.Status = 0 
           AND A.WorkingTag = 'A' 
    END 
    ELSE 
    BEGIN
        -- �߰� �� ���ο� ��ȣ�� �߰� 
        DECLARE @MaxNewMesKey  INT 

        SELECT @MaxNewMesKey = CONVERT(INT,RIGHT(A.MesKey,3))
          FROM hencom_TIFProdWorkReportClose    AS A 
         WHERE A.CompanySeq = @CompanySeq 
           AND LEFT(A.MesKey,12) = 'NEW_' + A.WorkDate 
    
        SELECT @MaxNewMesKey = ISNULL(@MaxNewMesKey,0)
        

        UPDATE A
           SET NewMesKey = 'NEW_' + A.WorkDate + '_' + RIGHT('00' + CONVERT(NVARCHAR(20),@MaxNewMesKey + A.DataSeq),3)
          FROM #hencom_TIFProdWorkReportClose AS A 
         WHERE A.Status = 0 
           AND A.WorkingTag = 'A' 

    END 
    

    -- üũ0, ����ó���Ǿ� ����/���� �� �� �����ϴ�.
    IF @IsPartition = '0' 
    BEGIN 
        UPDATE A
           SET Result = '����ó���Ǿ� ����/���� �� �� �����ϴ�.', 
               Status = 1234, 
               MessageType = 1234 
          FROM #hencom_TIFProdWorkReportClose AS A 
          JOIN hencom_TIFProdWorkReportClose  AS B ON ( B.CompanySeq = @CompanySeq AND B.MesKey = A.MesKey ) 
         WHERE A.Status = 0 
           AND A.WorkingTag IN ( 'U', 'D' ) 
           AND ISNULL(B.SumMesKey,0) <> 0 
    END 
    ELSE IF @IsPartition = '1' 
    BEGIN 
        SELECT B.MesKey, ISNULL(B.SumMesKey,0) AS SumMesKey
          INTO #SumMesKey
          FROM #hencom_TIFProdWorkReportClose AS A 
          LEFT OUTER JOIN hencom_TIFProdWorkReportClose AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND LEFT(B.MesKey,19) = A.MesKey ) 
         WHERE LEN(B.MesKey) > 19 
        
        IF EXISTS (SELECT 1 FROM #SumMesKey WHERE SumMesKey <> 0)
        BEGIN 
            UPDATE A
               SET Result = '����ó���Ǿ� ó�� �� �� �����ϴ�.', 
                   Status = 1234, 
                   MessageType = 1234 
              FROM #hencom_TIFProdWorkReportClose AS A 
             WHERE A.Status = 0 
        END 
    END 
    -- üũ0, END 



    -- üũ1, ���޺������� Ȯ�� ó�� �Ǿ� ���� �� �� �����ϴ�.
    UPDATE A
       SET Result = '���޺������� Ȯ�� ó�� �Ǿ� ���� �� �� �����ϴ�.',
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TIFProdWorkReportClose       AS A 
                 JOIN hencom_TPUSubContrCalc    AS B ON ( B.CompanySeq = @CompanySeq AND B.MesKey = A.MesKey ) 
      LEFT OUTER JOIN hencom_TPUSubContrCalcCfm AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = B.DeptSeq AND C.WorkDate = B.WorkDate ) 
     WHERE A.Status = 0 
       AND C.IsConfirm = '1'   
    -- üũ1, END 


    -- üũ2, ������ ������ �������� ������ �ٸ��ϴ�. ( ���� ������ ��쿡�� �ش� ) 
    IF EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE Status = 0 AND WorkingTag IN ( 'A', 'U' )) AND @IsPartition = '1' 
    BEGIN 
        
        SELECT ProdQty, OutQty 
          INTO #Qty
          FROM hencom_TIFProdWorkReportClose    AS A 
         WHERE A.CompanySeq = @CompanySeq 
           AND NOT EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE NewMesKey = A.MesKey)
           AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE MesKey = LEFT(A.MesKey,19))
           AND LEN(A.MesKey) > 19 
    
        UNION ALL 
    
        SELECT ProdQty, OutQty 
          FROM #hencom_TIFProdWorkReportClose 
        



        DECLARE @OldProdQty DECIMAL(19,5), 
                @OldOutQty  DECIMAL(19,5)
        
        SELECT @OldProdQty = (
                                SELECT MAX(ProdQty)
                                  FROM hencom_TIFProdWorkReportClose AS A 
                                 WHERE A.CompanySeq = @CompanySeq 
                                   AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE MesKey = A.MesKey)
                             )

        SELECT @OldOutQty = (
                                SELECT MAX(OutQty)
                                  FROM hencom_TIFProdWorkReportClose AS A 
                                 WHERE A.CompanySeq = @CompanySeq 
                                   AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE MesKey = A.MesKey)
                             )

        
        UPDATE #hencom_TIFProdWorkReportClose 
           SET Result = '������ ������ �������� ������ �ٸ��ϴ�.', 
               Status = 1234, 
               MessageType = 1234 
          FROM (
                SELECT SUM(ProdQty) AS ProdQty, SUM(OutQty) AS OutQty
                  FROM #Qty
               ) AS A 
         WHERE A.ProdQty <> @OldProdQty 
            OR A.OutQty <> @OldOutQty
    
    END 
    -- üũ2, END 

    -- üũ3, �ű��߰��� ������ �����մϴ�. 
    UPDATE A
       SET Result = '�ű��߰��� ������ �����մϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TIFProdWorkReportClose   AS A 
      LEFT OUTER JOIN _TDAUMinorValue       AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMOutTypeSeq AND B.Serl = 2015 ) 
     WHERE A.Status = 0 
       AND A.IsPartition = '0'
       AND ISNULL(B.ValueText,'0') = '0' 
       AND A.WorkingTag IN ( 'A', 'U' ) 
    -- üũ3, END 

    -- üũ4, ��������� ���������� ���ϱ����� �����Ͻñ� �ٶ��ϴ�.
    UPDATE A
       SET Result = '��������� ���������� ���ϱ����� �����Ͻñ� �ٶ��ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TIFProdWorkReportClose   AS A 
      LEFT OUTER JOIN _TDAUMinorValue       AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMOutTypeSeq AND B.Serl = 2015 ) 
     WHERE A.Status = 0 
       AND A.IsPartition = '1'
       AND ISNULL(B.ValueText,'0') = '1' 
    -- üũ4, END 

    SELECT * FROM #hencom_TIFProdWorkReportClose 
    
    
    RETURN  
    go
begin tran 
exec hencom_SPDMESPartitionAddCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ExpShipNo>20170208004</ExpShipNo>
    <MesNo>0001</MesNo>
    <UMOutTypeName>�����Ǹ�</UMOutTypeName>
    <PJTName>�»�S-OIL RUC area4 ����</PJTName>
    <GoodItemName>25-27-120</GoodItemName>
    <CustName>(��)���Ǽ�</CustName>
    <MesKey>0041_20170208_10001</MesKey>
    <IsPartition>1</IsPartition>
    <DeptSeq>41</DeptSeq>
    <WorkDate>20170208</WorkDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1511366,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1032936
rollback 