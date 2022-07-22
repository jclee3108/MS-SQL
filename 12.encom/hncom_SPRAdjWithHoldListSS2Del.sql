  
IF OBJECT_ID('hncom_SPRAdjWithHoldListSS2Del') IS NOT NULL   
    DROP PROC hncom_SPRAdjWithHoldListSS2Del  
GO  
  
-- v2017.02.08
      
-- ��õ���Ű���-SS2����üũ by ����õ    
CREATE PROC hncom_SPRAdjWithHoldListSS2Del  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hncom_TAdjWithHoldList (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#hncom_TAdjWithHoldList'   
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('hncom_TAdjWithHoldList')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'hncom_TAdjWithHoldList'    , -- ���̺��        
                  '#hncom_TAdjWithHoldList'    , -- �ӽ� ���̺��        
                  'AdjSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
      
    -- �۾����� : DELETE -> UPDATE -> INSERT  
      
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hncom_TAdjWithHoldList WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #hncom_TAdjWithHoldList  AS A   
          JOIN hncom_TAdjWithHoldList   AS B ON ( B.CompanySeq = @CompanySeq AND A.AdjSeq = B.AdjSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
                    
    END    
      
      
    SELECT * FROM #hncom_TAdjWithHoldList   
      
    RETURN  
