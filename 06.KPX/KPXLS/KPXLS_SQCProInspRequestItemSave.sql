  
IF OBJECT_ID('KPXLS_SQCProInspRequestItemSave') IS NOT NULL   
    DROP PROC KPXLS_SQCProInspRequestItemSave  
GO  
  
-- v2015.12.08  
  
-- (검사품)수입검사의뢰-디테일저장 by 이재천   
CREATE PROC KPXLS_SQCProInspRequestItemSave  
    @xmlDocument    NVARCHAR(MAX),
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPXLS_TQCRequestItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXLS_TQCRequestItem'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXLS_TQCRequestItemAdd_PUR')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXLS_TQCRequestItemAdd_PUR'    , -- 테이블명        
                  '#KPXLS_TQCRequestItem'    , -- 임시 테이블명        
                  'ReqSeq,ReqSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명  
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXLS_TQCRequestItem WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.SMTestResult = A.SMTestResult      ,
               B.LastUserSeq  = @UserSeq, 
               B.LastDateTime = GETDATE(), 
               B.PgmSeq       = @PgmSeq 
          FROM #KPXLS_TQCRequestItem    AS A   
          JOIN KPXLS_TQCRequestItemAdd_PUR     AS B ON ( B.CompanySeq = @CompanySeq AND A.ReqSeq = B.ReqSeq AND A.ReqSerl = B.ReqSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXLS_TQCRequestItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPXLS_TQCRequestItem  
        (   
            CompanySeq, ReqSeq, ReqSerl, SourceSeq, SourceSerl, 
            Remark, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, A.ReqSeq, A.ReqSerl, A.DelvSeq, A.DelvSerl, 
               '', @UserSeq, GETDATE(), @PgmSeq
          FROM #KPXLS_TQCRequestItem AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
        
        INSERT INTO KPXLS_TQCRequestItemAdd_PUR  
        (   
            CompanySeq, ReqSeq, ReqSerl, SMTestResult, LastUserSeq, 
            LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, A.ReqSeq, A.ReqSerl, A.SMTestResult, @UserSeq, 
               GETDATE(), @PgmSeq
          FROM #KPXLS_TQCRequestItem AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPXLS_TQCRequestItem   
      
    RETURN  
    GO
    begin tran 
exec KPXLS_SQCProInspRequestItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <CreateDate>20151204</CreateDate>
    <DelvQty>10.00000</DelvQty>
    <DelvSeq>1002122</DelvSeq>
    <DelvSerl>1</DelvSerl>
    <IsPass>1</IsPass>
    <IsQCRequest>0</IsQCRequest>
    <LotNo>jjw3</LotNo>
    <MakerLotNo>jj4</MakerLotNo>
    <ReqSeq>16</ReqSeq>
    <ReqSerl>1</ReqSerl>
    <UMQcTypeName />
    <ValiDate>20151208</ValiDate>
    <ExpKind>1</ExpKind>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033628,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027845
rollback