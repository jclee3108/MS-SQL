  
IF OBJECT_ID('KPX_SCOMReservationYMClosingCheck') IS NOT NULL   
    DROP PROC KPX_SCOMReservationYMClosingCheck  
GO  
  
-- v2015.07.28  
  
-- ���ึ������-üũ by ����õ   
CREATE PROC KPX_SCOMReservationYMClosingCheck  
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
      
    CREATE TABLE #KPX_TCOMReservationYMClosing( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TCOMReservationYMClosing'   
    IF @@ERROR <> 0 RETURN     
    
    UPDATE A 
       SET WorkingTag = 'A' 
      FROM #KPX_TCOMReservationYMClosing AS A 
     WHERE NOT EXISTS (SELECT 1 FROM KPX_TCOMReservationYMClosing WHERE CompanySeq = @CompanySeq AND ClosingYM = A.ClosingYM AND AccUnit = A.AccUnit) 
    
    UPDATE A 
       SET ReservationTime = ReservationTime + '00'
      FROM #KPX_TCOMReservationYMClosing AS A 
    
    ------------------------------------------------------------    
    -- üũ1, ����ð����� ����ð��� �����ϴ�. 
    ------------------------------------------------------------
    UPDATE A
       SET Result = '����ð����� ����ð��� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPX_TCOMReservationYMClosing AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A','U' ) 
       AND A.ReservationDate + A.ReservationTime <= CONVERT(NCHAR(8),GETDATE(),112) + CONVERT(NCHAR(2),GETDATE(),108) + '00' 
    ------------------------------------------------------------
    -- üũ1, END 
    ------------------------------------------------------------
    
    ------------------------------------------------------------    
    -- üũ2, �ð����°� �ǹٸ��� �ʽ��ϴ�. 
    ------------------------------------------------------------
    UPDATE A
       SET Result = '�ð����°� �ǹٸ��� �ʽ��ϴ�. ', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPX_TCOMReservationYMClosing AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A','U' ) 
       AND ( LEFT(A.ReservationTime,2) >= 24 OR LEN(A.ReservationTime) <> 4 ) 
    ------------------------------------------------------------    
    -- üũ2, END 
    ------------------------------------------------------------
    
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TCOMReservationYMClosing WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TCOMReservationYMClosing', 'ClosingSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPX_TCOMReservationYMClosing  
           SET ClosingSeq = @Seq + DataSeq--,  
               --SampleNo  = @MaxNo      
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_TCOMReservationYMClosing   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TCOMReservationYMClosing  
     WHERE Status = 0  
       AND ( ClosingSeq = 0 OR ClosingSeq IS NULL )  
      
    SELECT * FROM #KPX_TCOMReservationYMClosing   
      
    RETURN  
GO 
begin tran 
exec KPX_SCOMReservationYMClosingCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Sel>0</Sel>
    <IsCancel>0</IsCancel>
    <ClosingYM>201501</ClosingYM>
    <AccUnitName>����-����</AccUnitName>
    <AccUnit>3</AccUnit>
    <ReservationDate>20150801</ReservationDate>
    <ReservationTime>13</ReservationTime>
    <ProcDate />
    <ProcResult />
    <ClosingSeq />
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <ClosingYear>2015</ClosingYear>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031128,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025935
rollback 

