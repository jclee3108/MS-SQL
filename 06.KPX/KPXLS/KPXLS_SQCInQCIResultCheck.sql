  
IF OBJECT_ID('KPXLS_SQCInQCIResultCheck') IS NOT NULL   
    DROP PROC KPXLS_SQCInQCIResultCheck  
GO  
  
-- v2015.12.15  
  
-- (�˻�ǰ)���԰˻���-üũ by ����õ   
CREATE PROC KPXLS_SQCInQCIResultCheck  
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
      
    CREATE TABLE #KPX_TQCTestResult( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCTestResult'   
    IF @@ERROR <> 0 RETURN     
    
    ------------------------------------------------------------------------
    -- üũ1, �˻���� �� �����ʹ� ����, ���� �� �� �����ϴ�. 
    ------------------------------------------------------------------------
    
    UPDATE A 
       SET Result = '�˻���� �� �����ʹ� ����, ���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPX_TQCTestResult AS A 
      JOIN KPXLS_TQCTestResultAdd AS B ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.QCSeq ) 
     WHERE B.IsCfm = '1' 
       AND A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
    
    ------------------------------------------------------------------------
    -- üũ1, END 
    ------------------------------------------------------------------------
    
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TQCTestResult WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN    
    
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TQCTestResult', 'QCSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPX_TQCTestResult  
           SET QCSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
    
    UPDATE #KPX_TQCTestResult   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TQCTestResult  
     WHERE Status = 0  
       AND ( QCSeq = 0 OR QCSeq IS NULL )  
    
    SELECT * FROM #KPX_TQCTestResult   
    
    RETURN 
    GO 
    begin tran
    exec KPXLS_SQCInQCIResultCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <QCNo>A003</QCNo>
    <QCNoSub>A004</QCNoSub>
    <QCDate>20151216</QCDate>
    <UseItemName>123</UseItemName>
    <UMQcType>1010418001</UMQcType>
    <UMQcTypeName>�հ�</UMQcTypeName>
    <SCDate>20151213</SCDate>
    <SCRocate>123</SCRocate>
    <SCAmount>test</SCAmount>
    <SCEmpName>asdfasdf</SCEmpName>
    <SCPackage>asdfasdf</SCPackage>
    <OKQty>0</OKQty>
    <BadQty>0</BadQty>
    <IsCfm>1</IsCfm>
    <CfmEmpName>����õ</CfmEmpName>
    <CfmDate>2015-12-17 ���� 1:22:45</CfmDate>
    <QCSeq>182</QCSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033819,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027993
rollback 