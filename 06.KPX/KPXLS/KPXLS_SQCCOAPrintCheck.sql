IF OBJECT_ID('KPXLS_SQCCOAPrintCheck') IS NOT NULL 
    DROP PROC KPXLS_SQCCOAPrintCheck
GO 

-- v2015.12.08 
  
-- ���輺��������(COA)-üũ by ����õ   
CREATE PROC KPXLS_SQCCOAPrintCheck
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
    
    CREATE TABLE #KPXLS_TQCCOAPrint( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXLS_TQCCOAPrint'   
    IF @@ERROR <> 0 RETURN     
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
        @Seq    INT   
    
    SELECT @Count = COUNT(1) FROM #KPXLS_TQCCOAPrint WHERE WorkingTag = 'A' AND Status = 0  
    
    IF @Count > 0  
    BEGIN  
        
        DECLARE @BaseDate           NVARCHAR(8),   
                @MaxNo              NVARCHAR(50)  
          
        SELECT @BaseDate    = CONVERT( NVARCHAR(8), GETDATE(), 112 )   
          FROM #KPXLS_TQCCOAPrint   
         WHERE WorkingTag = 'A'   
           AND Status = 0     

        EXEC dbo._SCOMCreateNo 'SITE', 'KPXLS_TQCCOAPrint', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT     
        
   
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXLS_TQCCOAPrint', 'COASeq', @Count  
        
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPXLS_TQCCOAPrint  
           SET COASeq = @Seq + DataSeq,  
               COANo  = @MaxNo      
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPXLS_TQCCOAPrint   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPXLS_TQCCOAPrint  
     WHERE Status = 0  
       AND ( COASeq = 0 OR COASeq IS NULL )  
      
    SELECT * FROM #KPXLS_TQCCOAPrint   
      
    RETURN 
GO

begin tran 
exec KPXLS_SQCCOAPrintCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <QCDate />
    <COACount>0</COACount>
    <LifeCycle>0</LifeCycle>
    <COASeq>0</COASeq>
    <QCSeq>0</QCSeq>
    <KindSeq>0</KindSeq>
    <SMSourceType />
    <SMSourceTypeName />
    <CreateDate>20151201</CreateDate>
    <ReTestDate>20151201</ReTestDate>
    <TestResultDate>20151201</TestResultDate>
    <CustSeq>42507</CustSeq>
    <CustEngName />
    <DVPlaceSeq>0</DVPlaceSeq>
    <DVPlaceName />
    <COANo />
    <COADate />
    <ItemSeq>1052403</ItemSeq>
    <CasNo>��������</CasNo>
    <TestEmpName>��������</TestEmpName>
    <LotNo />
    <QCType>5</QCType>
    <OriWeight>123</OriWeight>
    <TotWeight>123</TotWeight>
    <ShipDate>20151202</ShipDate>
    <MasterRemark />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033540,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027778
rollback 