  
IF OBJECT_ID('KPXCM_SPDDailyProdBasisSave') IS NOT NULL   
    DROP PROC KPXCM_SPDDailyProdBasisSave  
GO  
  
-- v2016.05.10  
  
-- ���ϻ��귮�������������Է�(�������)-���� by ����õ   
CREATE PROC KPXCM_SPDDailyProdBasisSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPXCM_TPDDailyProdBasis( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TPDDailyProdBasis'   
    IF @@ERROR <> 0 RETURN     
    
    CREATE TABLE #KPXCM_TPDDailyProdBasisItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TPDDailyProdBasisItem'   
    IF @@ERROR <> 0 RETURN     
    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TPDDailyProdBasis')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TPDDailyProdBasis'    , -- ���̺��        
                  '#KPXCM_TPDDailyProdBasis'    , -- �ӽ� ���̺��        
                  'UnitProcSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
      
    -- Item �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TPDDailyProdBasisItem')    
    
    EXEC _SCOMDeleteLog @CompanySeq     ,      
                        @UserSeq        ,      
                        'KPXCM_TPDDailyProdBasisItem'  ,     
                        '#KPXCM_TPDDailyProdBasisItem'      ,     
                        'UnitProcSeq,ItemSeq'     , -- CompanySeq���� �� Ű     
                        @TableColumns   , 'UnitProcSeq,ItemSeqOld', @PgmSeq     
    
    -- �۾����� : DELETE -> UPDATE -> INSERT  
      
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDDailyProdBasis WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE B   
          FROM #KPXCM_TPDDailyProdBasis AS A   
          JOIN KPXCM_TPDDailyProdBasis AS B ON ( B.CompanySeq = @CompanySeq AND A.UnitProcSeq = B.UnitProcSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
        
        DELETE B   
          FROM #KPXCM_TPDDailyProdBasis AS A   
          JOIN KPXCM_TPDDailyProdBasisItem AS B ON ( B.CompanySeq = @CompanySeq AND A.UnitProcSeq = B.UnitProcSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
        
    END 
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDDailyProdBasisItem WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN 
        DELETE B   
          FROM #KPXCM_TPDDailyProdBasisItem     AS A   
          JOIN KPXCM_TPDDailyProdBasisItem      AS B ON ( B.CompanySeq = @CompanySeq AND A.UnitProcSeq = B.UnitProcSeq AND A.ItemSeqOld = B.ItemSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDDailyProdBasis WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.UnitProcName   = A.UnitProcName,  
               B.Sort           = A.Sort,  
               B.Remark         = A.Remark,    
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE(),  
               B.PgmSeq         = @PgmSeq    
          FROM #KPXCM_TPDDailyProdBasis AS A   
          JOIN KPXCM_TPDDailyProdBasis AS B ON ( B.CompanySeq = @CompanySeq AND A.UnitProcSeq = B.UnitProcSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDDailyProdBasisItem WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.ItemPrtName    = A.ItemPrtName,  
               B.ItemSeq        = A.ItemSeq, 
               B.Sort           = A.Sort,  
               B.ConvDen        = A.ConvDen,
               B.Remark         = A.Remark,    
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE(),  
               B.PgmSeq         = @PgmSeq    
          FROM #KPXCM_TPDDailyProdBasisItem AS A   
          JOIN KPXCM_TPDDailyProdBasisItem AS B ON ( B.CompanySeq = @CompanySeq AND A.UnitProcSeq = B.UnitProcSeq AND B.ItemSeq = A.ItemSeqOld )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
    END    
    
    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDDailyProdBasis WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPXCM_TPDDailyProdBasis  
        (   
            CompanySeq, UnitProcSeq, UMItemKind, UnitProcName, Sort, 
            Remark, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, UnitProcSeq, UMItemKind, UnitProcName, Sort, 
               Remark, @UserSeq, GETDATE(), @PgmSeq
          FROM #KPXCM_TPDDailyProdBasis AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDDailyProdBasisItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPXCM_TPDDailyProdBasisItem  
        (   
            CompanySeq, UnitProcSeq, ItemSeq, ItemPrtName, Sort, 
            ConvDen, Remark, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, UnitProcSeq, ItemSeq, ItemPrtName, Sort, 
               ConvDen, Remark, @UserSeq, GETDATE(), @PgmSeq
          FROM #KPXCM_TPDDailyProdBasisItem AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
           AND A.UnitProcSeq <> 0 
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    UPDATE A 
       SET ItemSeqOld = ItemSeq 
      FROM #KPXCM_TPDDailyProdBasisItem AS A 
    
    
    SELECT * FROM #KPXCM_TPDDailyProdBasis   
    SELECT * FROM #KPXCM_TPDDailyProdBasisItem 
      
    RETURN  
    go
    begin tran
exec KPXCM_SPDDailyProdBasisSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ConvDen>0.00000</ConvDen>
    <ItemName>KONIX KE-810</ItemName>
    <ItemNo>1111010007</ItemNo>
    <ItemPrtName>��ǰ</ItemPrtName>
    <ItemSeq>356</ItemSeq>
    <Remark />
    <Sort>1</Sort>
    <UnitProcSeq>1</UnitProcSeq>
    <ItemSeqOld>81898</ItemSeqOld>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1036949,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1030269
rollback 