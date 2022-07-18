  
IF OBJECT_ID('KPX_SPDSFCProdPackOrderSave') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackOrderSave  
GO  
  
-- v2014.11.25  
  
-- �����۾������Է�-���� by ����õ   
CREATE PROC KPX_SPDSFCProdPackOrderSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TPDSFCProdPackOrder (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPDSFCProdPackOrder'   
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDSFCProdPackOrder')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPDSFCProdPackOrder'    , -- ���̺��        
                  '#KPX_TPDSFCProdPackOrder'    , -- �ӽ� ���̺��        
                  'PackOrderSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    ---- DELETE      
    --IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDSFCProdPackOrder WHERE WorkingTag = 'D' AND Status = 0 )    
    --BEGIN    
    --    DELETE B   
    --      FROM #KPX_TPDSFCProdPackOrder AS A   
    --      JOIN KPX_TPDSFCProdPackOrder AS B ON ( B.CompanySeq = @CompanySeq AND A.SampleSeq = B.SampleSeq )   
    --     WHERE A.WorkingTag = 'D'   
    --       AND A.Status = 0   
          
    --    IF @@ERROR <> 0  RETURN  
          
    --    DELETE B   
    --      FROM #TSample     AS A   
    --      JOIN _TSampleItem AS B ON ( B.CompanySeq = @CompanySeq AND A.SampleSeq = B.SampleSeq )   
    --     WHERE A.WorkingTag = 'D'   
    --       AND A.Status = 0   
          
    --    IF @@ERROR <> 0  RETURN  
          
    --END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDSFCProdPackOrder WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.FactUnit = A.FactUnit,  
               B.PackDate = A.PackDate, 
               B.OutWHSeq = A.OutWHSeq, 
               B.InWHSeq = A.InWHSeq, 
               B.UMProgType = A.UMProgType, 
               B.SubOutWHSeq = A.SubOutWHSeq, 
               B.Remark = A.Remark, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
        
          FROM #KPX_TPDSFCProdPackOrder AS A   
          JOIN KPX_TPDSFCProdPackOrder AS B ON ( B.CompanySeq = @CompanySeq AND A.PackOrderSeq = B.PackOrderSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDSFCProdPackOrder WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TPDSFCProdPackOrder  
        (   
            CompanySeq,PackOrderSeq,FactUnit,PackDate,OrderNo,
            OutWHSeq,InWHSeq,UMProgType,SubOutWHSeq,Remark,
            LastUserSeq, LastDateTime  
        )   
        SELECT @CompanySeq, A.PackOrderSeq, A.FactUnit, A.PackDate, A.OrderNo,
               A.OutWHSeq, A.InWHSeq, A.UMProgType, A.SubOutWHSeq, A.Remark, 
               @UserSeq, GETDATE() 
          FROM #KPX_TPDSFCProdPackOrder AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_TPDSFCProdPackOrder   
      
    RETURN  
GO 

BEGIN TRAN 
exec KPX_SPDSFCProdPackOrderSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <FactUnit>1</FactUnit>
    <InWHSeq>7</InWHSeq>
    <OrderNo>141125004</OrderNo>
    <OutWHSeq>3</OutWHSeq>
    <PackDate>20141125</PackDate>
    <PackOrderSeq>7</PackOrderSeq>
    <Remark>test</Remark>
    <UMProgType>1010345001</UMProgType>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026147,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021349
select * from KPX_TPDSFCProdPackOrder 
rollback 