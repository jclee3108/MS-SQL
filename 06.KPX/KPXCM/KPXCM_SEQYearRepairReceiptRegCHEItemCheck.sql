  
IF OBJECT_ID('KPXCM_SEQYearRepairReceiptRegCHEItemCheck') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReceiptRegCHEItemCheck  
GO  
  
-- v2015.07.15  
  
-- ���������������-������üũ by ����õ   
CREATE PROC KPXCM_SEQYearRepairReceiptRegCHEItemCheck  
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
    
    CREATE TABLE #KPXCM_TEQYearRepairReceiptRegItemCHE( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TEQYearRepairReceiptRegItemCHE'   
    IF @@ERROR <> 0 RETURN 
    
    -----------------------------------------------------------------------
    -- üũ1, ��û,�������ڰ� �����Ǿ� �ֽ��ϴ�. (�űԵ��) 
    -----------------------------------------------------------------------
    UPDATE A
       SET Result = '��û,�������ڰ� �����Ǿ� �ֽ��ϴ�. (�űԵ��) ', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPXCM_TEQYearRepairReceiptRegItemCHE    AS A 
      JOIN KPXCM_TEQYearRepairReqRegItemCHE         AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq AND B.ReqSerl = A.ReqSerl ) 
      JOIN KPXCM_TEQYearRepairReqRegCHE             AS C ON ( C.CompanySeq = @CompanySeq AND C.ReqSeq = B.ReqSeq ) 
      JOIN KPXCM_TEQYearRepairPeriodCHE             AS D ON ( D.CompanySeq = @CompanySeq AND D.RepairSeq = C.RepairSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
       AND D.ReceiptCfmyn = '1' 
       AND A.ReceiptRegDate BETWEEN D.ReceiptFrDate AND D.ReceiptToDate
    -----------------------------------------------------------------------
    -- üũ1, END
    -----------------------------------------------------------------------
    
    ------------------------------------------------------------------------------
    -- üũ2, ����� �����ʹ� ����,���� �� �� �����ϴ�. 
    ------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '����� �����ʹ� ����,���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPXCM_TEQYearRepairReceiptRegItemCHE AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U','D' ) 
       AND EXISTS (SELECT 1 FROM KPXCM_TEQYearRepairResultRegItemCHE WHERE CompanySeq = @CompanySeq AND ReceiptRegSeq = A.ReceiptRegSeq AND ReceiptRegSerl = A.ReceiptRegSerl ) 
    ------------------------------------------------------------------------------
    -- üũ2, END 
    ------------------------------------------------------------------------------
    
    ------------------------------------------------------------------------------
    -- üũ3, ������°� ����,ȸ���� ��� ����ȸ�ۻ����� �ʼ��Դϴ�.
    ------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '������°� ����,ȸ���� ��� ����ȸ�ۻ����� �ʼ��Դϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPXCM_TEQYearRepairReceiptRegItemCHE AS A 
      LEFT OUTER JOIN _TDAUMinorValue            AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.ProgType AND B.Serl = 1000007 ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A','U' ) 
       AND ISNULL(B.ValueText,'0') = '1' 
       AND A.RtnReason = '' 
    ------------------------------------------------------------------------------
    -- üũ3, END 
    ------------------------------------------------------------------------------
    
    UPDATE A 
       SET ReceiptRegSerl = DataSeq 
      FROM #KPXCM_TEQYearRepairReceiptRegItemCHE AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
    
    SELECT * FROM #KPXCM_TEQYearRepairReceiptRegItemCHE 
    
    RETURN  
GO 

begin tran 
exec KPXCM_SEQYearRepairReceiptRegCHEItemCheck @xmlDocument=N'<ROOT>
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
    <ReqDate>20150801</ReqDate>
    <ReceiptFrDate>20150701</ReceiptFrDate>
    <ReceiptToDate>20150731</ReceiptToDate>
    <RepairFrDate>20150801</RepairFrDate>
    <RepairToDate>20150830</RepairToDate>
    <EmpName>����õ</EmpName>
    <EmpSeq>2028</EmpSeq>
    <DeptName>���������2</DeptName>
    <DeptSeq>1300</DeptSeq>
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
    <RtnReason />
    <WONo>YP-150801-001</WONo>
    <ReqSeq>11</ReqSeq>
    <ReqSerl>1</ReqSerl>
    <ReceiptRegSeq>11</ReceiptRegSeq>
    <ReceiptRegSerl>0</ReceiptRegSerl>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <ReceiptRegDate>20150721</ReceiptRegDate>
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
    <ReqDate>20150801</ReqDate>
    <ReceiptFrDate>20150701</ReceiptFrDate>
    <ReceiptToDate>20150731</ReceiptToDate>
    <RepairFrDate>20150801</RepairFrDate>
    <RepairToDate>20150830</RepairToDate>
    <EmpName>����õ</EmpName>
    <EmpSeq>2028</EmpSeq>
    <DeptName>���������2</DeptName>
    <DeptSeq>1300</DeptSeq>
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
    <RtnReason />
    <WONo>YP-150801-002</WONo>
    <ReqSeq>11</ReqSeq>
    <ReqSerl>2</ReqSerl>
    <ReceiptRegSeq>11</ReceiptRegSeq>
    <ReceiptRegSerl>0</ReceiptRegSerl>
    <ReceiptRegDate>20150721</ReceiptRegDate>
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
    <ReqDate>20150801</ReqDate>
    <ReceiptFrDate>20150701</ReceiptFrDate>
    <ReceiptToDate>20150731</ReceiptToDate>
    <RepairFrDate>20150801</RepairFrDate>
    <RepairToDate>20150830</RepairToDate>
    <EmpName>����õ</EmpName>
    <EmpSeq>2028</EmpSeq>
    <DeptName>���������2</DeptName>
    <DeptSeq>1300</DeptSeq>
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
    <RtnReason />
    <WONo>YP-150801-003</WONo>
    <ReqSeq>11</ReqSeq>
    <ReqSerl>3</ReqSerl>
    <ReceiptRegSeq>11</ReceiptRegSeq>
    <ReceiptRegSerl>0</ReceiptRegSerl>
    <ReceiptRegDate>20150721</ReceiptRegDate>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030864,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025743
rollback 