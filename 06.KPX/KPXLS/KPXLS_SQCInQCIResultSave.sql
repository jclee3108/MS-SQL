  
IF OBJECT_ID('KPXLS_SQCInQCIResultSave') IS NOT NULL   
    DROP PROC KPXLS_SQCInQCIResultSave  
GO  
  
-- v2015.12.15  
  
-- (검사품)수입검사등록-저장 by 이재천   
CREATE PROC KPXLS_SQCInQCIResultSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TQCTestResult (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCTestResult'   
    IF @@ERROR <> 0 RETURN    
    
    
    UPDATE A 
       SET OKQty = CASE WHEN A.UMQcType IN  ( 1010418001 , 1010418003 ) THEN A.DelvTotQty ELSE 0 END, 
           BadQty = CASE WHEN A.UMQcType IN  ( 1010418002 ) THEN A.DelvTotQty ELSE 0 END 
      FROM #KPX_TQCTestResult AS A 

    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQCTestResult')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TQCTestResult'    , -- 테이블명        
                  '#KPX_TQCTestResult'    , -- 임시 테이블명        
                  'QCSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
                  
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXLS_TQCTestResultAdd')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXLS_TQCTestResultAdd'    , -- 테이블명        
                  '#KPX_TQCTestResult'    , -- 임시 테이블명        
                  'QCSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCTestResult WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE B   
          FROM #KPX_TQCTestResult AS A   
          JOIN KPX_TQCTestResult AS B ON ( B.CompanySeq = @CompanySeq AND A.QCSeq = B.QCSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
        
        DELETE B   
          FROM #KPX_TQCTestResult AS A   
          JOIN KPXLS_TQCTestResultAdd AS B ON ( B.CompanySeq = @CompanySeq AND A.QCSeq = B.QCSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
        
        
        -- Master 로그   
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQCTestResultItem')    
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TQCTestResultItem'    , -- 테이블명        
                      '#KPX_TQCTestResult'    , -- 임시 테이블명        
                      'QCSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
        DELETE B   
          FROM #KPX_TQCTestResult       AS A   
          JOIN KPX_TQCTestResultItem    AS B ON ( B.CompanySeq = @CompanySeq AND A.QCSeq = B.QCSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    --select * from #KPX_TQCTestResult 
    --return 
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCTestResult WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.QCNo           = A.QCNo, 
               --B.QCDate         = A.QCDate, 
               B.SMTestResult   = A.UMQcType, 
               B.OKQty          = A.OKQty, 
               B.BadQty         = A.BadQty, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
          FROM #KPX_TQCTestResult   AS A   
          JOIN KPX_TQCTestResult    AS B ON ( B.CompanySeq = @CompanySeq AND A.QCSeq = B.QCSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN 
        
        UPDATE B   
           SET B.SCDate         = A.SCDate, 
               B.SCAmount       = A.SCAmount, 
               B.SCEmpName      = A.SCEmpName, 
               B.SCPackage      = A.SCPackage, 
               --B.IsCfm          = A.IsCfm, 
               --B.CfmEmpSeq      = A.CfmEmpSeq, 
               --B.CfmDate        = A.CfmDate, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(), 
               B.SCRocate = A.SCRocate, 
               B.UseItemName = A.UseItemName, 
               B.TestDate = A.QCDate 
          FROM #KPX_TQCTestResult   AS A   
          JOIN KPXLS_TQCTestResultAdd    AS B ON ( B.CompanySeq = @CompanySeq AND A.QCSeq = B.QCSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCTestResult WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TQCTestResult  
        (   
            CompanySeq, QCSeq, QCNo, SMTestResult, OKQty, 
            BadQty, LastUserSeq, LastDateTime, ItemSeq, LotNo,
            ReqSeq, ReqSerl, QCType, WHSeq
        )   
        SELECT @CompanySeq, A.QCSeq, A.QCNo, A.UMQcType, A.OKQty, 
               A.BadQty, @UserSeq, GETDATE(), A.ItemSeq, A.LotNo, 
               A.ReqSeq, A.ReqSerl, QCType, 0 
          FROM #KPX_TQCTestResult AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
        
        INSERT INTO KPXLS_TQCTestResultAdd  
        (   
            CompanySeq, QCSeq, IsCfm, CfmEmpSeq, CfmDateTime, 
            SCDate, SCAmount, SCEmpName, SCPackage, LastUserSeq, 
            LastDateTime, SCRocate, UseItemName, TestDate
        )   
        SELECT @CompanySeq, A.QCSeq, A.IsCfm, 0, '', 
               SCDate, SCAmount, SCEmpName, SCPackage , @UserSeq, 
               GETDATE(), SCRocate, UseItemName, QCDate
          FROM #KPX_TQCTestResult AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_TQCTestResult   
      
    RETURN  
    go
    begin tran
exec KPXLS_SQCInQCIResultSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <BadQty>0.00000</BadQty>
    <BizUnit>1</BizUnit>
    <BizUnitName>의약</BizUnitName>
    <CarNo>testtest2</CarNo>
    <CfmDate />
    <CfmEmpName />
    <CreateCustName>test</CreateCustName>
    <CustName>(유)대웅관광</CustName>
    <DelvDate>20151216</DelvDate>
    <DelvNo>201512160001</DelvNo>
    <DelvTotQty>200.00000</DelvTotQty>
    <DeptName>경영지원팀</DeptName>
    <DeptSeq>0</DeptSeq>
    <EmpName>강상욱</EmpName>
    <EmpSeq>0</EmpSeq>
    <ExpKindName>국내</ExpKindName>
    <IsCfm>0</IsCfm>
    <ItemName>신희범-자재</ItemName>
    <ItemNo>신희범-자재</ItemNo>
    <LotNo>2</LotNo>
    <MakerLotNo>4</MakerLotNo>
    <OKQty>0.00000</OKQty>
    <QCDate>20151217</QCDate>
    <QCNo>A1001</QCNo>
    <QCNoSub />
    <QCReqList>testtest4</QCReqList>
    <QCSeq>20</QCSeq>
    <QCType>4</QCType>
    <QCTypeName>수입검사</QCTypeName>
    <Remark>testtest3</Remark>
    <ReqDate>20151216</ReqDate>
    <ReqNo>A1111</ReqNo>
    <ReqSeq>16</ReqSeq>
    <ReqSerl>1</ReqSerl>
    <SCAmount>test1</SCAmount>
    <SCDate>20151212</SCDate>
    <SCEmpName>test4</SCEmpName>
    <SCPackage>test5</SCPackage>
    <SCRocate>test2</SCRocate>
    <Storage>test1</Storage>
    <UMQcType>1010418001</UMQcType>
    <UMQcTypeName>합격</UMQcTypeName>
    <UnitName>KG</UnitName>
    <UseItemName>test3</UseItemName>
    <ItemSeq>4824</ItemSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033819,@WorkingTag=N'',@CompanySeq=3,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027993
select * From KPX_TQCTestResult where qcseq = 20
rollback 

--select * From KPX_TQCTestResult where qcseq = 20