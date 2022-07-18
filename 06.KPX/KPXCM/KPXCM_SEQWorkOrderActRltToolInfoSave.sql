  
IF OBJECT_ID('KPXCM_SEQWorkOrderActRltToolInfoSave') IS NOT NULL   
    DROP PROC KPXCM_SEQWorkOrderActRltToolInfoSave  
GO  
  
-- v2015.07.22 
  
-- �۾��������(�Ϲ�)-������������ by ����õ 
CREATE PROC KPXCM_SEQWorkOrderActRltToolInfoSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    
    CREATE TABLE #KPXCM_TEQWorkOrderActRltToolInfo( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TEQWorkOrderActRltToolInfo'   
    IF @@ERROR <> 0 RETURN     
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQWorkOrderActRltToolInfo')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TEQWorkOrderActRltToolInfo'    , -- ���̺��        
                  '#KPXCM_TEQWorkOrderActRltToolInfo'    , -- �ӽ� ���̺��        
                  'ReceiptSeq,WOReqSeq,WOReqSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQWorkOrderActRltToolInfo WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPXCM_TEQWorkOrderActRltToolInfo AS A   
          JOIN KPXCM_TEQWorkOrderActRltToolInfo AS B ON ( B.CompanySeq = @CompanySeq 
                                                      AND A.ReceiptSeq = B.ReceiptSeq
                                                      AND A.WOReqSeq = B.WOReqSeq
                                                      AND A.WOReqSerl = B.WOReqSerl
                                                        )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
    
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQWorkOrderActRltToolInfo WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.ProtectKind = A.ProtectKind, 
               B.WorkReason = A.WorkReason, 
               B.PreProtect = A.PreProtect, 
               B.Remark     = A.Remark, 
               B.FileSeq    = A.FileSeq, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
                 
          FROM #KPXCM_TEQWorkOrderActRltToolInfo AS A   
          JOIN KPXCM_TEQWorkOrderActRltToolInfo AS B ON ( B.CompanySeq = @CompanySeq 
                                                      AND A.ReceiptSeq = B.ReceiptSeq
                                                      AND A.WOReqSeq = B.WOReqSeq
                                                      AND A.WOReqSerl = B.WOReqSerl
                                                        )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQWorkOrderActRltToolInfo WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPXCM_TEQWorkOrderActRltToolInfo  
        (   
            CompanySeq, ReceiptSeq, WOReqSeq, WOReqSerl, ToolSeq, 
            ProtectKind, WorkReason, PreProtect, Remark, FileSeq, 
            LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, ReceiptSeq, WOReqSeq, WOReqSerl, ToolSeq, 
               ProtectKind, WorkReason, PreProtect, Remark, FileSeq, 
               @UserSeq, GETDATE(), @PgmSeq 
          FROM #KPXCM_TEQWorkOrderActRltToolInfo AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPXCM_TEQWorkOrderActRltToolInfo   
      
    RETURN  
go
begin tran 
exec KPXCM_SEQWorkOrderActRltToolInfoSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ReceiptSeq>11</ReceiptSeq>
    <WOReqSeq>21</WOReqSeq>
    <WOReqSerl>1</WOReqSerl>
    <ProtectKindName>����������3</ProtectKindName>
    <ProtectKind>1011343003</ProtectKind>
    <WorkReasonName>�����۾�����5</WorkReasonName>
    <WorkReason>1011344005</WorkReason>
    <ToolKindName />
    <ProtectLevelName />
    <PreProtectName>���񿹹溸������1</PreProtectName>
    <PreProtect>1011345001</PreProtect>
    <Remark>test</Remark>
    <FileSeq>0</FileSeq>
    <ToolSeq>0</ToolSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031016,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025850

rollback 