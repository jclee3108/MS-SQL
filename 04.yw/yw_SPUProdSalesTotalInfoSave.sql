  
IF OBJECT_ID('yw_SPUProdSalesTotalInfoSave') IS NOT NULL   
    DROP PROC yw_SPUProdSalesTotalInfoSave  
GO  
  
-- v2013.11.28  
  
-- ������ǥ�ڷ����(����)_YW(����) by����õ   
CREATE PROC yw_SPUProdSalesTotalInfoSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    CREATE TABLE #YW_TPUProdSalesTotalInfo (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TPUProdSalesTotalInfo'     
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('YW_TPUProdSalesTotalInfo')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'YW_TPUProdSalesTotalInfo'    , -- ���̺��        
                  '#YW_TPUProdSalesTotalInfo'    , -- �ӽ� ���̺��        
                  'OSPPOSeq,OSPPOSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #YW_TPUProdSalesTotalInfo WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.Remark = A.Remark, 
               B.InfoDate = CONVERT(NVARCHAR(8),GETDATE(),112),  
               B.LastUserSeq = @UserSeq,  
               B.LastDateTime = GETDATE() 
          FROM #YW_TPUProdSalesTotalInfo AS A   
          JOIN YW_TPUProdSalesTotalInfo  AS B ON ( B.CompanySeq = @CompanySeq AND A.OSPPOSeq = B.OSPPOSeq AND A.OSPPOSerl = B.OSPPOSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #YW_TPUProdSalesTotalInfo WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO YW_TPUProdSalesTotalInfo  
        (CompanySeq, OSPPOSeq, OSPPOSerl, InfoDate, Remark, LastUserSeq, LastDateTime)   
        SELECT @CompanySeq, A.OSPPOSeq, A.OSPPOSerl, CONVERT(NVARCHAR(8),GETDATE(),112), A.Remark, @UserSeq, GETDATE()
          FROM #YW_TPUProdSalesTotalInfo AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END 
    
    UPDATE A 
       SET InfoDate = B.InfoDate 
      FROM #YW_TPUProdSalesTotalInfo AS A 
      JOIN YW_TPUProdSalesTotalInfo  AS B ON ( B.CompanySeq = @CompanySeq AND B.OSPPOSeq = A.OSPPOSeq AND B.OSPPOSerl = A.OSPPOSerl ) 
    
    SELECT * FROM #YW_TPUProdSalesTotalInfo   
      
    RETURN  
GO
begin tran
exec yw_SPUProdSalesTotalInfoSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <OSPPOSeq>5</OSPPOSeq>
    <OSPPOSerl>3</OSPPOSerl>
    <Remark>awerawetet</Remark>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019637,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016581
rollback  
