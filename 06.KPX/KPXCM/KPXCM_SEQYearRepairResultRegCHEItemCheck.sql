  
IF OBJECT_ID('KPXCM_SEQYearRepairResultRegCHEItemCheck') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairResultRegCHEItemCheck  
GO  
  
-- v2015.07.17  
  
-- ���������������-������üũ by ����õ   
CREATE PROC KPXCM_SEQYearRepairResultRegCHEItemCheck  
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
    
    CREATE TABLE #KPXCM_TEQYearRepairResultRegItemCHE( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TEQYearRepairResultRegItemCHE'   
    IF @@ERROR <> 0 RETURN     
    
    -----------------------------------------------------------------------
    -- üũ1, �������ڰ� �����Ǿ� �ֽ��ϴ�. (�űԵ��) 
    -----------------------------------------------------------------------
    UPDATE A
       SET Result = '�������ڰ� �����Ǿ� �ֽ��ϴ�. (�űԵ��)', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPXCM_TEQYearRepairResultRegItemCHE     AS A 
      JOIN KPXCM_TEQYearRepairReceiptRegItemCHE     AS B ON ( B.CompanySeq = @CompanySeq AND B.ReceiptRegSeq = A.ReceiptRegSeq AND B.ReceiptRegSerl = A.ReceiptRegSerl ) 
      JOIN KPXCM_TEQYearRepairReqRegItemCHE         AS C ON ( C.CompanySeq = @CompanySeq AND C.ReqSeq = B.ReqSeq AND C.ReqSerl = B.ReqSerl ) 
      JOIN KPXCM_TEQYearRepairReqRegCHE             AS D ON ( D.CompanySeq = @CompanySeq AND D.ReqSeq = C.ReqSeq ) 
      JOIN KPXCM_TEQYearRepairPeriodCHE             AS E ON ( E.CompanySeq = @CompanySeq AND E.RepairSeq = D.RepairSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
       AND E.RepairCfmYn = '1' 
       AND A.ResultDate BETWEEN E.RepairFrDate AND E.RepairToDate
    -----------------------------------------------------------------------
    -- üũ1, END
    -----------------------------------------------------------------------
    
    
    UPDATE A 
       SET ResultSerl = A.DataSeq 
      FROM #KPXCM_TEQYearRepairResultRegItemCHE AS A 
     WHERE A.WorkingTag = 'A' 
       AND A.Status = 0 
    
    SELECT * FROM #KPXCM_TEQYearRepairResultRegItemCHE   
    
    RETURN  
GO

begin tran 
exec KPXCM_SEQYearRepairResultRegCHEItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <FactUnitName>�ƻ����</FactUnitName>
    <FactUnit>1</FactUnit>
    <RepairYear>2015</RepairYear>
    <Amd>4</Amd>
    <WONo>YP-150801-001</WONo>
    <ReqDate>20150801</ReqDate>
    <ReqEmpName>����õ</ReqEmpName>
    <ReqDeptName>���������2</ReqDeptName>
    <RepairFrDate>20150801</RepairFrDate>
    <RepairToDate>20150830</RepairToDate>
    <ReceiptDate>20150801</ReceiptDate>
    <ReceiptEmpName>����õ</ReceiptEmpName>
    <ReceiptDeptName>���������2</ReceiptDeptName>
    <ToolName>������</ToolName>
    <ToolNo>���� ������5</ToolNo>
    <ToolSeq>5</ToolSeq>
    <WorkOperName>����</WorkOperName>
    <WorkOperSeq>20106004</WorkOperSeq>
    <WorkGubnName>����2</WorkGubnName>
    <WorkGubn>1011335002</WorkGubn>
    <WorkContents>1</WorkContents>
    <ProgTypeName>����</ProgTypeName>
    <ProgType>20109002</ProgType>
    <ToolKindName>525</ToolKindName>
    <ProtectKindName>����������3</ProtectKindName>
    <ProtectKind>1011343003</ProtectKind>
    <WorkReasonName />
    <WorkReason>0</WorkReason>
    <ProtectLevelName>11</ProtectLevelName>
    <PreProtectName />
    <PreProtect>0</PreProtect>
    <Remark />
    <ResultSeq>10</ResultSeq>
    <ResultSerl>0</ResultSerl>
    <ReceiptRegSeq>11</ReceiptRegSeq>
    <ReceiptRegSerl>1</ReceiptRegSerl>
    <FileSeq>0</FileSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <ResultDate>20150721</ResultDate>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <FactUnitName>�ƻ����</FactUnitName>
    <FactUnit>1</FactUnit>
    <RepairYear>2015</RepairYear>
    <Amd>4</Amd>
    <WONo>YP-150801-002</WONo>
    <ReqDate>20150801</ReqDate>
    <ReqEmpName>����õ</ReqEmpName>
    <ReqDeptName>���������2</ReqDeptName>
    <RepairFrDate>20150801</RepairFrDate>
    <RepairToDate>20150830</RepairToDate>
    <ReceiptDate>20150801</ReceiptDate>
    <ReceiptEmpName>����õ</ReceiptEmpName>
    <ReceiptDeptName>���������2</ReceiptDeptName>
    <ToolName>������</ToolName>
    <ToolNo>���� ������622</ToolNo>
    <ToolSeq>6</ToolSeq>
    <WorkOperName>����</WorkOperName>
    <WorkOperSeq>20106005</WorkOperSeq>
    <WorkGubnName>����2</WorkGubnName>
    <WorkGubn>1011335002</WorkGubn>
    <WorkContents>2</WorkContents>
    <ProgTypeName>����</ProgTypeName>
    <ProgType>20109002</ProgType>
    <ToolKindName>1</ToolKindName>
    <ProtectKindName>����������1</ProtectKindName>
    <ProtectKind>1011343001</ProtectKind>
    <WorkReasonName />
    <WorkReason>0</WorkReason>
    <ProtectLevelName>1</ProtectLevelName>
    <PreProtectName />
    <PreProtect>0</PreProtect>
    <Remark />
    <ResultSeq>10</ResultSeq>
    <ResultSerl>0</ResultSerl>
    <ReceiptRegSeq>11</ReceiptRegSeq>
    <ReceiptRegSerl>2</ReceiptRegSerl>
    <FileSeq>0</FileSeq>
    <ResultDate>20150721</ResultDate>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <FactUnitName>�ƻ����</FactUnitName>
    <FactUnit>1</FactUnit>
    <RepairYear>2015</RepairYear>
    <Amd>4</Amd>
    <WONo>YP-150801-003</WONo>
    <ReqDate>20150801</ReqDate>
    <ReqEmpName>����õ</ReqEmpName>
    <ReqDeptName>���������2</ReqDeptName>
    <RepairFrDate>20150801</RepairFrDate>
    <RepairToDate>20150830</RepairToDate>
    <ReceiptDate>20150801</ReceiptDate>
    <ReceiptEmpName>����õ</ReceiptEmpName>
    <ReceiptDeptName>���������2</ReceiptDeptName>
    <ToolName>������</ToolName>
    <ToolNo>���� ������8</ToolNo>
    <ToolSeq>8</ToolSeq>
    <WorkOperName>���</WorkOperName>
    <WorkOperSeq>20106003</WorkOperSeq>
    <WorkGubnName>����1</WorkGubnName>
    <WorkGubn>1011335001</WorkGubn>
    <WorkContents>3</WorkContents>
    <ProgTypeName>����</ProgTypeName>
    <ProgType>20109002</ProgType>
    <ToolKindName>1111</ToolKindName>
    <ProtectKindName>����������4</ProtectKindName>
    <ProtectKind>1011343004</ProtectKind>
    <WorkReasonName />
    <WorkReason>0</WorkReason>
    <ProtectLevelName>111</ProtectLevelName>
    <PreProtectName />
    <PreProtect>0</PreProtect>
    <Remark />
    <ResultSeq>10</ResultSeq>
    <ResultSerl>0</ResultSerl>
    <ReceiptRegSeq>11</ReceiptRegSeq>
    <ReceiptRegSerl>3</ReceiptRegSerl>
    <FileSeq>0</FileSeq>
    <ResultDate>20150721</ResultDate>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030930,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025775
rollback 