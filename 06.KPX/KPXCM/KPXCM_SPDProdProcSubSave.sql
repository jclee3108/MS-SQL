IF OBJECT_ID('KPXCM_SPDProdProcSubSave') IS NOT NULL 
    DROP PROC KPXCM_SPDProdProcSubSave
GO 

-- v2016.03.07 

-- ��ǰ������ҿ���-������ by ���游
CREATE PROC KPXCM_SPDProdProcSubSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle      INT
  
    CREATE TABLE #ProdProcRev (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#ProdProcRev'
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDProdProcItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPDProdProcItem'    , -- ���̺��        
                  '#ProdProcRev'    , -- �ӽ� ���̺��        
                  'ItemSeq,PatternRev, SubItemSeq,Serl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    --DEL
    IF EXISTS (SELECT 1 FROM #ProdProcRev WHERE WorkingTag = 'D' AND Status = 0)
    BEGIN
        DELETE KPX_TPDProdProcItem
          FROM KPX_TPDProdProcItem AS A
               JOIN #ProdProcRev AS B ON B.ItemSeq = A.ItemSeq 
                                     ANd B.PatternRev = A.PatternRev
                                     AND B.SubItemSeq = A.SubItemSeq
									 AND B.Serl = A.Serl
         WHERE A.CompanySeq = @CompanySeq
           AND B.WorkingTag = 'D'
           AND B.Status = 0
    END 

    --UPDATE
    IF EXISTS (SELECT 1 FROM #ProdProcRev WHERE WorkingTag = 'U' AND Status = 0)
    BEGIN
        UPDATE A
           SET PatternQty = B.PatternQty,
			   SortNum     = B.SortNum,
			   BOMSerl     = B.BOMSerl,
			   RowNum      = B.RowNum,
			   ProdQty     = B.ProdQty, 
			   LastUserSeq = @UserSeq,
               LastDateTime = GETDATE()
          FROM KPX_TPDProdProcItem AS A
               JOIN #ProdProcRev AS B ON B.ItemSeq = A.ItemSeq 
                                     ANd B.PatternRev = A.PatternRev
                                     AND B.SubItemSeq = A.SubItemSeq
									 and B.Serl = A.Serl
         WHERE A.CompanySeq = @CompanySeq
           AND B.WorkingTag = 'U'
           AND B.Status = 0
    
    END 
    
    --INSERT 
    IF EXISTS (SELECT 1 FROM #ProdProcRev WHERE WorkingTag = 'A' AND Status = 0)
    BEGIN
        INSERT INTO KPX_TPDProdProcItem(CompanySeq, ItemSeq, PatternRev, SubItemSeq,
                                        PatternQty, LastUserSeq ,LastDateTime,SortNum,Serl,BomSerl,RowNum, ProdQty)
             SELECT @CompanySeq, ItemSeq, PatternRev, SubItemSeq,
                    PatternQty, @UserSeq, GETDATE(),SortNum,Serl,BomSerl,RowNum, ProdQty
               FROM #ProdProcRev
              WHERE WorkingTag = 'A'
                AND Status = 0
    
    END 
    --KPX_TPDProdProcItem
    
    SELECT * FROM #ProdProcRev
    
    RETURN
    
GO


