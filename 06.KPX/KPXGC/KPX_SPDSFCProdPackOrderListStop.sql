  
IF OBJECT_ID('KPX_SPDSFCProdPackOrderListStop') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackOrderListStop  
GO  
  
-- v2014.11.25  
  
-- �����۾�������ȸ- �ߴ� by ����õ   
CREATE PROC KPX_SPDSFCProdPackOrderListStop  
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
    
    CREATE TABLE #KPX_TPDSFCProdPackOrderItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPDSFCProdPackOrderItem'   
    IF @@ERROR <> 0 RETURN     
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDSFCProdPackOrderItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPDSFCProdPackOrderItem'    , -- ���̺��        
                  '#KPX_TPDSFCProdPackOrderItem'    , -- �ӽ� ���̺��        
                  'PackOrderSeq,PackOrderSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
        
    UPDATE KPX_TPDSFCProdPackOrderItem
       SET IsStop = A.IsStop
      FROM #KPX_TPDSFCProdPackOrderItem AS A 
      JOIN KPX_TPDSFCProdPackOrderItem  AS B ON ( B.CompanySeq = @CompanySeq AND A.PackOrderSeq = B.PackOrderSeq AND A.PackOrderSerl = B.PackOrderSerl ) 
     WHERE A.WorkingTag = 'U' 
       AND A.Status     = 0    

    IF @@ERROR <> 0  RETURN
    
    SELECT * FROM #KPX_TPDSFCProdPackOrderItem 
    
    RETURN    
GO 
begin tran 
select * from KPX_TPDSFCProdPackOrderItemLog
exec KPX_SPDSFCProdPackOrderListStop @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <IsStop>0</IsStop>
    <PackOrderSeq>20</PackOrderSeq>
    <PackOrderSerl>1</PackOrderSerl>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026191,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021350

select * from KPX_TPDSFCProdPackOrderItemLog
select * from KPX_TPDSFCProdPackOrderItem
rollback 