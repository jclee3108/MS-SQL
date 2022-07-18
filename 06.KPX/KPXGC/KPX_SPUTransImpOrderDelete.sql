  
IF OBJECT_ID('KPX_SPUTransImpOrderDelete') IS NOT NULL   
    DROP PROC KPX_SPUTransImpOrderDelete  
GO  
  
-- v2014.11.28  
  
-- ���Կ������-���� by ����õ   
CREATE PROC KPX_SPUTransImpOrderDelete  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TPUTransImpOrder (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPUTransImpOrder'   
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPUTransImpOrder')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPUTransImpOrder'    , -- ���̺��        
                  '#KPX_TPUTransImpOrder'    , -- �ӽ� ���̺��        
                  'TransImpSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    
    DELETE B 
      FROM #KPX_TPUTransImpOrder AS A 
      JOIN KPX_TPUTransImpOrder  AS B ON ( B.CompanySeq = @CompanySeq AND B.TransImpSeq = A.TransImpSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'D' 
    
    -- ��Ʈ �α� 
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPUTransImpOrderItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPUTransImpOrderItem'    , -- ���̺��        
                  '#KPX_TPUTransImpOrder'    , -- �ӽ� ���̺��        
                  'TransImpSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��  
    
    DELETE B 
      FROM #KPX_TPUTransImpOrder    AS A 
      JOIN KPX_TPUTransImpOrderItem AS B ON ( B.CompanySeq = @CompanySeq AND B.TransImpSeq = A.TransImpSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'D' 
    
    SELECT * FROM #KPX_TPUTransImpOrder
    
    RETURN 