  
IF OBJECT_ID('KPXLS_SQCProInspRequestSave') IS NOT NULL   
    DROP PROC KPXLS_SQCProInspRequestSave  
GO  
  
-- v2015.12.08  
  
-- (검사품)수입검사의뢰-저장 by 이재천   
CREATE PROC KPXLS_SQCProInspRequestSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPXLS_TQCRequest (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXLS_TQCRequest'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXLS_TQCRequest')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXLS_TQCRequest'    , -- 테이블명        
                  '#KPXLS_TQCRequest'    , -- 임시 테이블명        
                  'ReqSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명  
    
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXLS_TQCRequestAdd_PUR')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXLS_TQCRequestAdd_PUR'    , -- 테이블명        
                  '#KPXLS_TQCRequest'    , -- 임시 테이블명        
                  'ReqSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명  
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXLS_TQCRequest WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE B   
          FROM #KPXLS_TQCRequest AS A   
          JOIN KPXLS_TQCRequest AS B ON ( B.CompanySeq = @CompanySeq AND A.ReqSeq = B.ReqSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
        
        DELETE B   
          FROM #KPXLS_TQCRequest        AS A   
          JOIN KPXLS_TQCRequestAdd_PUR  AS B ON ( B.CompanySeq = @CompanySeq AND A.ReqSeq = B.ReqSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
        
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPXLS_TQCRequestItem')    
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPXLS_TQCRequestItem'    , -- 테이블명        
                      '#KPXLS_TQCRequest'    , -- 임시 테이블명        
                      'ReqSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명  
            
        DELETE B   
          FROM #KPXLS_TQCRequest     AS A   
          JOIN KPXLS_TQCRequestItem AS B ON ( B.CompanySeq = @CompanySeq AND A.ReqSeq = B.ReqSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
        
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPXLS_TQCRequestItemAdd_PUR')    
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPXLS_TQCRequestItemAdd_PUR'    , -- 테이블명        
                      '#KPXLS_TQCRequest'    , -- 임시 테이블명        
                      'ReqSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명  
            
        DELETE B   
          FROM #KPXLS_TQCRequest     AS A   
          JOIN KPXLS_TQCRequestItemAdd_PUR AS B ON ( B.CompanySeq = @CompanySeq AND A.ReqSeq = B.ReqSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXLS_TQCRequest WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.ReqDate       = A.ReqDate      ,
               B.EmpSeq        = A.EmpSeq       ,
               B.DeptSeq       = A.DeptSeq      ,
               B.Remark        = A.Remark       ,
               B.LastUserSeq     = @UserSeq,
               B.LastDateTime    = GETDATE()    ,
               B.PgmSeq        = @PgmSeq 
          FROM #KPXLS_TQCRequest AS A   
          JOIN KPXLS_TQCRequest AS B ON ( B.CompanySeq = @CompanySeq AND A.ReqSeq = B.ReqSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
        
        UPDATE B   
           SET B.Storage         = ISNULL(A.Storage,''),  
               B.CarNo           = ISNULL(A.CarNo,''),  
               B.CreateCustName  = ISNULL(A.CreateCustName,''),  
               B.QCReqList       = ISNULL(A.QCReqList,''),  
               B.LastUserSeq     = @UserSeq,  
               B.LastDateTime    = GETDATE()    ,  
               B.PgmSeq          = @PgmSeq  
          FROM #KPXLS_TQCRequest AS A   
          JOIN KPXLS_TQCRequestAdd_PUR AS B ON ( B.CompanySeq = @CompanySeq AND A.ReqSeq = B.ReqSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXLS_TQCRequest WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPXLS_TQCRequest  
        (   
            CompanySeq, ReqSeq, ReqNo, ReqDate, EmpSeq, 
            DeptSeq, FromPgmSeq, SMSourceType, SourceSeq, Remark, 
            LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, A.ReqSeq, A.ReqNo, A.ReqDate, A.EmpSeq, 
               A.DeptSeq, A.FromPgmSeq, CASE WHEN A.ExpKind = 1 THEN 1000522008 ELSE 1000522007 END, A.DelvSeq, A.Remark, 
               @UserSeq, GETDATE(), @PgmSeq   
          FROM #KPXLS_TQCRequest AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
           
        INSERT INTO KPXLS_TQCRequestAdd_PUR  
        (   
            CompanySeq, ReqSeq, Storage, CarNo, CreateCustName, 
            QCReqList, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, A.ReqSeq, ISNULL(A.Storage,''), ISNULL(A.CarNo,''), ISNULL(A.CreateCustName,''), 
               ISNULL(A.QCReqList,''), @UserSeq, GETDATE(), @PgmSeq  
          FROM #KPXLS_TQCRequest AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPXLS_TQCRequest   
      
    RETURN  
    GO
    begin tran 
    
  exec KPXLS_SQCProInspRequestSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <BizUnit>1</BizUnit>
    <BizUnitName>아산공장</BizUnitName>
    <CarNo>sdf</CarNo>
    <CreateCustName>sdf</CreateCustName>
    <CustName> ㈜농심1</CustName>
    <DelvDate>20151207</DelvDate>
    <DelvNo>201512070006</DelvNo>
    <DelvSeq>1002122</DelvSeq>
    <DelvTotQty>10.00000</DelvTotQty>
    <DeptName>국내영업1팀</DeptName>
    <DeptSeq>45</DeptSeq>
    <EmpName>dung</EmpName>
    <EmpSeq>270</EmpSeq>
    <ExpKindName>국내</ExpKindName>
    <ItemName>Lot품목1_이재천</ItemName>
    <ItemNo>Lot품목1_이재천</ItemNo>
    <ItemSeq>27367</ItemSeq>
    <QCReqList>sdf</QCReqList>
    <QCType>5</QCType>
    <QCTypeName>1</QCTypeName>
    <Remark>sdf</Remark>
    <ReqDate>20151201</ReqDate>
    <ReqNo>201512010001</ReqNo>
    <ReqSeq>9999</ReqSeq>
    <Storage>sdf</Storage>
    <SubReqNo>sdf</SubReqNo>
    <UnitName>Kg</UnitName>
    <ExpKind>1</ExpKind>
    <FromPgmSeq>0</FromPgmSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033628,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027845
rollback 