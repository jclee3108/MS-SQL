  
IF OBJECT_ID('KPXLS_SQCProInspRequestCheck') IS NOT NULL   
    DROP PROC KPXLS_SQCProInspRequestCheck  
GO  
  
-- v2015.12.08  
  
-- (검사품)수입검사의뢰-체크 by 이재천   
CREATE PROC KPXLS_SQCProInspRequestCheck  
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
    
    CREATE TABLE #KPXLS_TQCRequest( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXLS_TQCRequest'   
    IF @@ERROR <> 0 RETURN     
    
    UPDATE A 
       SET WorkingTag = CASE WHEN B.CompanySeq IS NULL THEN 'A' ELSE 'U' END 
      FROM #KPXLS_TQCRequest            AS A 
      LEFT OUTER JOIN KPXLS_TQCRequest  AS B ON ( B.CompanySeq = @CompanySeq 
                                              AND B.SourceSeq = A.DelvSeq 
                                              AND B.SMSourceType = CASE WHEN A.ExpKind = 1 THEN 1000522008 ELSE 1000522007 END 
                                              AND B.PgmSeq = CASE WHEN A.IsPass = '1' THEN 1027881 ELSE 1027845 END 
                                                ) 
     WHERE A.WorkingTag IN ( 'A', 'U' ) 
       AND B.CompanySeq IS NULL 
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPXLS_TQCRequest WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
    --    DECLARE @BaseDate           NVARCHAR(8),   
    --            @MaxNo              NVARCHAR(50)  
          
        --SELECT @BaseDate    = ISNULL( MAX(ReqDate), CONVERT( NVARCHAR(8), GETDATE(), 112 ) )  
        --  FROM #KPXLS_TQCRequest   
        -- WHERE WorkingTag = 'A'   
        --   AND Status = 0     
        
        --EXEC dbo._SCOMCreateNo 'SITE', 'KPXLS_TQCRequest', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT      
          
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXLS_TQCRequest', 'ReqSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPXLS_TQCRequest  
           SET ReqSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPXLS_TQCRequest   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPXLS_TQCRequest  
     WHERE Status = 0  
       AND ( ReqSeq = 0 OR ReqSeq IS NULL )  
      
    SELECT * FROM #KPXLS_TQCRequest   
      
    RETURN  
    go
    begin tran
exec KPXLS_SQCProInspRequestCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <BizUnit>1</BizUnit>
    <BizUnitName>아산공장</BizUnitName>
    <CustName>강변스파랜드                                  </CustName>
    <DelvNo>201512090001</DelvNo>
    <ItemName>Lot테스트_이재천</ItemName>
    <ItemNo>Lot테스트_이재천</ItemNo>
    <ExpKindName>국내</ExpKindName>
    <DelvDate>20151209</DelvDate>
    <DelvTotQty>7</DelvTotQty>
    <UnitName>Kg</UnitName>
    <ReqDate>20151216</ReqDate>
    <ReqNo>A004</ReqNo>
    <SubReqNo>A003</SubReqNo>
    <Storage>ㅁㄴㅇㄹ</Storage>
    <QCType>5</QCType>
    <QCTypeName>1</QCTypeName>
    <EmpSeq>2028</EmpSeq>
    <EmpName>이재천</EmpName>
    <DeptSeq>1300</DeptSeq>
    <DeptName>사업개발팀2</DeptName>
    <CarNo>ㄴㅇㅎ</CarNo>
    <CreateCustName>ㄴㅇㄹ</CreateCustName>
    <QCReqList>ㅁㄶ</QCReqList>
    <Remark>ㄴㄻㄴㅇㄹ</Remark>
    <ReqSeq>0</ReqSeq>
    <DelvSeq>1002125</DelvSeq>
    <ItemSeq>27375</ItemSeq>
    <ExpKind>1</ExpKind>
    <FromPgmSeq>1027813</FromPgmSeq>
    <IsPass>0</IsPass>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033628,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027845
rollback 