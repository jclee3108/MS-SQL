  
IF OBJECT_ID('KPXCM_SEQYearRepairReqRegCHEItemSave') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReqRegCHEItemSave  
GO  
  
-- v2015.07.14  
  
-- ����������û���-���������� by ����õ   
CREATE PROC KPXCM_SEQYearRepairReqRegCHEItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPXCM_TEQYearRepairReqRegItemCHE (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TEQYearRepairReqRegItemCHE'   
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQYearRepairReqRegItemCHE')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TEQYearRepairReqRegItemCHE'    , -- ���̺��        
                  '#KPXCM_TEQYearRepairReqRegItemCHE'    , -- �ӽ� ���̺��        
                  'ReqSeq,ReqSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairReqRegItemCHE WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        DELETE B   
          FROM #KPXCM_TEQYearRepairReqRegItemCHE AS A   
          JOIN KPXCM_TEQYearRepairReqRegItemCHE AS B ON ( B.CompanySeq = @CompanySeq AND A.ReqSeq = B.ReqSeq AND A.ReqSerl = B.ReqSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
        
        
        IF NOT EXISTS (
                        SELECT 1 
                          FROM KPXCM_TEQYearRepairReqRegItemCHE AS A 
                         WHERE A.CompanySeq = @CompanySeq 
                           AND A.ReqSeq IN ( SELECT TOP 1 ReqSeq FROM #KPXCM_TEQYearRepairReqRegItemCHE ) 
                      )
        BEGIN
            
            CREATE TABLE #Log 
            (
                IDX_NO      INT IDENTITY, 
                WorkingTag  NVARCHAR(1), 
                Status      INT, 
                ReqSeq      INT, 
                
            )
            INSERT INTO #Log (WorkingTag, Status, ReqSeq) 
            SELECT TOP 1 A.WorkingTag, A.Status, ReqSeq 
              FROM #KPXCM_TEQYearRepairReqRegItemCHE AS A 
             WHERE A.WorkingTag = 'D' 
               AND A.Status = 0 
               
            -- Master �α�   
            SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQYearRepairReqRegCHE')    
              
            EXEC _SCOMLog @CompanySeq   ,        
                          @UserSeq      ,        
                          'KPXCM_TEQYearRepairReqRegCHE'    , -- ���̺��        
                          '#Log'    , -- �ӽ� ���̺��        
                          'ReqSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                          @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
            
            DELETE B
              FROM #KPXCM_TEQYearRepairReqRegItemCHE    AS A 
              JOIN KPXCM_TEQYearRepairReqRegCHE         AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq ) 
             WHERE A.WorkingTag = 'D' 
               AND A.Status = 0 
        END 
    END   
    
    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairReqRegItemCHE WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.ToolSeq = A.ToolSeq, 
               B.WorkOperSeq = A.WorkOperSeq, 
               B.WorkGubn = A.WorkGubn, 
               B.WorkContents = A.WorkContents, 
               B.ProgType = A.ProgType, 
               B.LastUserSeq = @UserSeq, 
               B.LastDateTime = GETDATE(), 
               B.PgmSeq = @PgmSeq 
          FROM #KPXCM_TEQYearRepairReqRegItemCHE AS A   
          JOIN KPXCM_TEQYearRepairReqRegItemCHE AS B ON ( B.CompanySeq = @CompanySeq AND A.ReqSeq = B.ReqSeq AND A.ReqSerl = B.ReqSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
    
        IF @@ERROR <> 0  RETURN  
    
    END    
    --select *from #KPXCM_TEQYearRepairReqRegCHE 
    
    --return 
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairReqRegItemCHE WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPXCM_TEQYearRepairReqRegItemCHE  
        (   
            CompanySeq, ReqSeq, ReqSerl, WONo, ToolSeq, 
            WorkOperSeq, WorkGubn, WorkContents, ProgType, LastUserSeq, 
            LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, ReqSeq, ReqSerl, WONo, ToolSeq, 
               WorkOperSeq, WorkGubn, WorkContents, 20109001, @UserSeq, -- 20109001 = ��û 
               GETDATE(), @PgmSeq
          FROM #KPXCM_TEQYearRepairReqRegItemCHE AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
        
    END 
    
    UPDATE A 
       SET ProgTypeName = (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 20109001) 
      FROM #KPXCM_TEQYearRepairReqRegItemCHE AS A 
      
    SELECT * FROM #KPXCM_TEQYearRepairReqRegItemCHE   
      
    RETURN  
Go
begin tran 
exec KPXCM_SEQYearRepairReqRegCHEItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ProgType>0</ProgType>
    <ProgTypeName />
    <ReqSeq>1</ReqSeq>
    <ReqSerl>1</ReqSerl>
    <ToolName>����3ȣ��sssss</ToolName>
    <ToolNo>����3ȣ��ssssss</ToolNo>
    <ToolSeq>3</ToolSeq>
    <WONo />
    <WorkContents>test</WorkContents>
    <WorkGubn>80001003</WorkGubn>
    <WorkGubnName>3. ȸ����� ���� �۾�</WorkGubnName>
    <WorkOperName>���</WorkOperName>
    <WorkOperSeq>20106003</WorkOperSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ProgType>0</ProgType>
    <ProgTypeName />
    <ReqSeq>1</ReqSeq>
    <ReqSerl>2</ReqSerl>
    <ToolName>������</ToolName>
    <ToolNo>���� ������5</ToolNo>
    <ToolSeq>5</ToolSeq>
    <WONo />
    <WorkContents>test2</WorkContents>
    <WorkGubn>80001012</WorkGubn>
    <WorkGubnName>5. VALVE REPACKING �� ��ü�۾�</WorkGubnName>
    <WorkOperName>����</WorkOperName>
    <WorkOperSeq>20106005</WorkOperSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ProgType>0</ProgType>
    <ProgTypeName />
    <ReqSeq>1</ReqSeq>
    <ReqSerl>3</ReqSerl>
    <ToolName>������</ToolName>
    <ToolNo>���� ������622</ToolNo>
    <ToolSeq>6</ToolSeq>
    <WONo />
    <WorkContents>test4</WorkContents>
    <WorkGubn>80001012</WorkGubn>
    <WorkGubnName>5. VALVE REPACKING �� ��ü�۾�</WorkGubnName>
    <WorkOperName>����</WorkOperName>
    <WorkOperSeq>20106005</WorkOperSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030838,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025722
select * from KPXCM_TEQYearRepairReqRegItemCHE 
rollback 