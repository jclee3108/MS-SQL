 
IF OBJECT_ID('KPX_SHREduRstWithCostSave') IS NOT NULL 
    DROP PROC KPX_SHREduRstWithCostSave
GO 

-- v2014.11.19 

-- ����������(����) by����õ 
CREATE PROCEDURE KPX_SHREduRstWithCostSave  
    @xmlDocument    NVARCHAR(MAX)   ,    -- ȭ���� ������ XML������ ����  
    @xmlFlags       INT = 0         ,    -- �ش� XML������ Type  
    @ServiceSeq     INT = 0         ,    -- ���� ��ȣ  
    @WorkingTag     NVARCHAR(10)= '',    -- WorkingTag  
    @CompanySeq     INT = 1         ,    -- ȸ�� ��ȣ  
    @LanguageSeq    INT = 1         ,    -- ��� ��ȣ  
    @UserSeq        INT = 0         ,    -- ����� ��ȣ  
    @PgmSeq         INT = 0              -- ���α׷� ��ȣ  
    
AS  
    
    CREATE TABLE #KPX_THREduRstWithCost (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THREduRstWithCost'   
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_THREduRstWithCost')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_THREduRstWithCost'    , -- ���̺��        
                  '#KPX_THREduRstWithCost'    , -- �ӽ� ���̺��        
                  'RstSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE  
    IF EXISTS (SELECT 1 FROM #KPX_THREduRstWithCost WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
        
        DELETE B
          FROM #KPX_THREduRstWithCost AS A 
          JOIN KPX_THREduRstWithCost  AS B ON ( B.CompanySeq = @CompanySeq AND A.RstSeq = B.RstSeq ) 
         WHERE A.WorkingTag = 'D' 
           AND A.Status = 0 
    
        IF @@ERROR <> 0  RETURN  
    
    END    -- DELETE ��  
    
    -- UPDATE  
    IF EXISTS (SELECT 1 FROM #KPX_THREduRstWithCost WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN  
        
        UPDATE B   
           SET B.IsEI   = A.IsEI,  
               B.SMComplate = A.SMComplate,  
               B.LastUserSeq = @UserSeq,  
               B.LastDateTime = GETDATE() 
                 
          FROM #KPX_THREduRstWithCost AS A   
          JOIN KPX_THREduRstWithCost AS B ON ( B.CompanySeq = @CompanySeq AND A.RstSeq = B.RstSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
    
    END    -- UPDATE ��  
    
    -- INSERT  
    IF EXISTS (SELECT 1 FROM #KPX_THREduRstWithCost WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        
        INSERT INTO KPX_THREduRstWithCost  
        (   
            CompanySeq, RstSeq, IsEI, SMComplate, LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.RstSeq, A.IsEI, SMComplate, @UserSeq, GETDATE() 
          FROM #KPX_THREduRstWithCost AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
  
    END    -- INSERT ��  

    SELECT * FROM #KPX_THREduRstWithCost    -- Output  
  
    RETURN  
GO 
exec KPX_SHREduRstWithCostSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <IsEI>1</IsEI>
    <SMComplate>1000273001</SMComplate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <IsEI>0</IsEI>
    <SMComplate>1000273002</SMComplate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025956,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021800