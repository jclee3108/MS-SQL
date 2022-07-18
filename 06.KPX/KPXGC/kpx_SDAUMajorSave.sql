
IF OBJECT_ID('kpx_SDAUMajorSave') IS NOT NULL 
    DROP PROC kpx_SDAUMajorSave
GO 

-- v2014.08.27 

-- ��������Ǳ�Ÿ�ڵ� ���_KPX(�����������Ʈ��з�����) by����õ 
CREATE PROC kpx_SDAUMajorSave
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS   
    
    CREATE TABLE #KPX_TDAUMajorMaster (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAUMajorMaster'     
    IF @@ERROR <> 0 RETURN  
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TDAUMajorMaster')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TDAUMajorMaster'    , -- ���̺��        
                  '#KPX_TDAUMajorMaster'    , -- �ӽ� ���̺��        
                  'UMajorSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , 'MajorSeq', @PgmSeq  -- ���̺� ��� �ʵ��  
    -- DELETE    
    IF EXISTS (SELECT TOP 1 1 FROM #KPX_TDAUMajorMaster WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
        DELETE KPX_TDAUMajorMaster
          FROM #KPX_TDAUMajorMaster      AS A 
          JOIN KPX_TDAUMajorMaster AS B ON ( A.MajorSeq = B.UMajorSeq ) 
         WHERE B.CompanySeq  = @CompanySeq
           AND A.WorkingTag  = 'D' 
           AND A.Status      = 0    
        
        IF @@ERROR <> 0  RETURN
    END  
    
    -- INSERT
    IF EXISTS (SELECT 1 FROM #KPX_TDAUMajorMaster WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        INSERT INTO KPX_TDAUMajorMaster (CompanySeq, UMajorSeq, LastUserSeq, LastDateTime ) 
        SELECT @CompanySeq, MajorSeq, @UserSeq, GetDate() 
          FROM #KPX_TDAUMajorMaster AS A   
         WHERE A.WorkingTag = 'A' 
           AND A.Status = 0    
        
        IF @@ERROR <> 0 RETURN
    END   
    
    SELECT * FROM #KPX_TDAUMajorMaster 
    
    RETURN    
GO
begin tran 
exec kpx_SDAUMajorSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <MajorSeq>1008011</MajorSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1024286,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020436
rollback 