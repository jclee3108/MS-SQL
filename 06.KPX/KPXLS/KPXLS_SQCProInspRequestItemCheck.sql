  
IF OBJECT_ID('KPXLS_SQCProInspRequestItemCheck') IS NOT NULL   
    DROP PROC KPXLS_SQCProInspRequestItemCheck 
GO  
  
-- v2015.12.08  
  
-- (검사품)수입검사의뢰-디테일체크 by 이재천   
CREATE PROC KPXLS_SQCProInspRequestItemCheck  
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
    
    CREATE TABLE #KPXLS_TQCRequestItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXLS_TQCRequestItem'   
    IF @@ERROR <> 0 RETURN     
    
    UPDATE A 
       SET WorkingTag = CASE WHEN C.CompanySeq IS NULL THEN 'A' ELSE 'U' END 
      FROM #KPXLS_TQCRequestItem            AS A 
      LEFT OUTER JOIN KPXLS_TQCRequestItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.SourceSeq = A.DelvSeq AND B.SourceSerl = A.DelvSerl ) 
      LEFT OUTER JOIN KPXLS_TQCRequest      AS C ON ( C.CompanySeq = @CompanySeq 
                                                  AND C.ReqSeq = B.ReqSeq 
                                                  AND C.SMSourceType = CASE WHEN A.ExpKind = 1 THEN 1000522008 ELSE 1000522007 END 
                                                  AND C.PgmSeq = CASE WHEN A.IsPass = '1' THEN 1027881 ELSE 1027845 END 
                                                    ) 
    
    DECLARE @MaxSerl INT 
    
    SELECT @MaxSerl = MAX(ReqSerl) 
      FROM #KPXLS_TQCRequestItem        AS A 
      LEFT OUTER JOIN KPXLS_TQCRequest  AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq ) 
    
    UPDATE A 
       SET ReqSerl = ISNULL(@MaxSerl,0) + A.DataSeq 
      FROM #KPXLS_TQCRequestItem AS A 
     WHERE A.WorkingTag = 'A' 
    
    SELECT * FROM #KPXLS_TQCRequestItem 
    
    RETURN  
    go
    begin tran
exec KPXLS_SQCProInspRequestItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IsQCRequest>0</IsQCRequest>
    <IsPass>1</IsPass>
    <UMQcTypeName />
    <LotNo>jjw3</LotNo>
    <MakerLotNo>jj4</MakerLotNo>
    <CreateDate>20151204</CreateDate>
    <ValiDate>20151208</ValiDate>
    <DelvQty>10</DelvQty>
    <DelvSeq>1002122</DelvSeq>
    <DelvSerl>1</DelvSerl>
    <ReqSeq>13</ReqSeq>
    <ReqSerl>0</ReqSerl>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <ExpKind>1</ExpKind>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033628,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027845
rollback 