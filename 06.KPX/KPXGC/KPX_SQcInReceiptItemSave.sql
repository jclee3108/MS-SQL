IF OBJECT_ID('KPX_SQcInReceiptItemSave') IS NOT NULL 
    DROP PROC KPX_SQcInReceiptItemSave
GO 

-- v2014.12.05 

-- ���԰˻���ǰ���� - ���� by����õ 
CREATE PROCEDURE KPX_SQcInReceiptItemSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS       
    DECLARE @docHandle  INT,  
            @Seq        INT,  
            @Count      INT  
  
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #KPX_TQcInReceiptItem (WorkingTag NCHAR(1) NULL)  
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQcInReceiptItem'  
    IF @@ERROR <> 0 RETURN    
    
    ALTER TABLE #KPX_TQcInReceiptItem ADD IsExists NCHAR(1)  
  
    UPDATE #KPX_TQcInReceiptItem  
       SET IsExists = '0'  
  
    UPDATE #KPX_TQcInReceiptItem  
       SET IsExists = '1'  
      FROM #KPX_TQcInReceiptItem AS A 
      JOIN KPX_TQcInReceiptItem AS B ON ( A.ItemSeq = B.ItemSeq AND B.CompanySeq = @CompanySeq ) 
    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQcInReceiptItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TQcInReceiptItem'    , -- ���̺��        
                  '#KPX_TQcInReceiptItem'    , -- �ӽ� ���̺��        
                  'ItemSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ�� 
    
    -- Update    
    IF EXISTS (SELECT 1 FROM #KPX_TQcInReceiptItem WHERE WorkingTag = 'U' AND Status = 0 AND IsExists = '1' )  
    BEGIN   
        UPDATE B 
           SET IsInQC       = A.IsInQC ,  
               IsAutoDelvIn = A.IsAutoDelvIn,  
               LastUserSeq  = @UserSeq ,   
               LastDateTime = GETDATE()  
          FROM #KPX_TQcInReceiptItem    AS A   
          JOIN KPX_TQcInReceiptItem     AS B ON ( B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq ) 
         WHERE A.WorkingTag = 'U' 
           AND A.Status = 0    
           AND A.IsExists = '1'
        
        IF @@ERROR <> 0 RETURN    
    
    END   
    
    IF EXISTS (SELECT 1 FROM #KPX_TQcInReceiptItem WHERE WorkingTag = 'U' AND Status = 0 AND IsExists = '0' )  
    BEGIN   
        
        INSERT INTO KPX_TQcInReceiptItem 
        (
            CompanySeq,ItemSeq,IsInQC,IsAutoDelvIn,LastUserSeq,
            LastDateTime
        )
        
        SELECT @CompanySeq, A.ItemSeq, A.IsInQC, A.IsAutoDelvIn, @UserSeq, 
                   GETDATE()
          FROM #KPX_TQcInReceiptItem AS A 
         WHERE A.WorkingTag = 'U' 
           AND A.Status = 0   
           AND A.IsExists = '0'  
        
        IF @@ERROR <> 0 RETURN   
  
    END  
    
    
    SELECT * FROM #KPX_TQcInReceiptItem
    
    RETURN 
  