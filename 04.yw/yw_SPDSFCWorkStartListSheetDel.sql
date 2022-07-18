
IF OBJECT_ID('yw_SPDSFCWorkStartListSheetDel') IS NOT NULL 
    DROP PROC yw_SPDSFCWorkStartListSheetDel
GO 

-- v2014.02.14 

-- ����������Ȳ_YW(��Ʈ����) by����õ
CREATE PROC dbo.yw_SPDSFCWorkStartListSheetDel
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
    CREATE TABLE #YW_TPDSFCWorkStart (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TPDSFCWorkStart'     
    IF @@ERROR <> 0 RETURN  
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('YW_TPDSFCWorkStart')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'YW_TPDSFCWorkStart'    , -- ���̺��        
                  '#YW_TPDSFCWorkStart'    , -- �ӽ� ���̺��        
                  'WorkOrderSerl,WorkOrderSeq,Serl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE    
    IF EXISTS (SELECT TOP 1 1 FROM #YW_TPDSFCWorkStart WHERE WorkingTag = 'D' AND Status = 0)  
        BEGIN  
            DELETE B
              FROM #YW_TPDSFCWorkStart  AS A 
              JOIN YW_TPDSFCWorkStart AS B ON ( A.WorkOrderSerl = B.WorkOrderSerl AND A.WorkOrderSeq = B.WorkOrderSeq AND A.Serl = B.Serl AND A.EmpSeq = B.EmpSeq ) 
             WHERE B.CompanySeq = @CompanySeq
               AND A.WorkingTag = 'D' 
               AND A.Status = 0    
            
             IF @@ERROR <> 0  RETURN
        END  
    
    SELECT * FROM #YW_TPDSFCWorkStart 
    
    RETURN    
GO
begin tran 
exec yw_SPDSFCWorkStartListSheetDel @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EmpName>�輼ȣ</EmpName>
    <EmpSeq>1575</EmpSeq>
    <WorkCenterName>��ũ����1_������</WorkCenterName>
    <WorkCenterSeq>100374</WorkCenterSeq>
    <WorkDate>20140213</WorkDate>
    <WorkEndTime xml:space="preserve">              </WorkEndTime>
    <WorkOrderNo>2013050700090001</WorkOrderNo>
    <WorkStartTime>20140213 17054</WorkStartTime>
    <WorkOrderSeq>134469</WorkOrderSeq>
    <WorkOrderSerl>134469</WorkOrderSerl>
    <Serl>1</Serl>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1021108,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1017737
rollback 