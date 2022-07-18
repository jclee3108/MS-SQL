IF OBJECT_ID('KPXCM_SQCInQCIResultNoTestCheck') IS NOT NULL 
    DROP PROC KPXCM_SQCInQCIResultNoTestCheck
GO 

-- v2015.11.02 

-- ���˻�ó�� üũ by����õ 
 -- v2015.01.15 
 -- ���̺� ���� by ����õ
 /************************************************************  
  ��  �� - ������-���԰˻���_KPX : üũ  
  �ۼ��� - 20141219  
  �ۼ��� - �ڻ��� 
  ������ - 20150828 CM������ ����üũ �߰�
 ************************************************************/  
 CREATE PROC KPXCM_SQCInQCIResultNoTestCheck
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT     = 0,    
     @ServiceSeq     INT     = 0,    
     @WorkingTag     NVARCHAR(10)= '',    
     @CompanySeq     INT     = 1,    
     @LanguageSeq    INT     = 1,    
     @UserSeq        INT     = 0,    
     @PgmSeq         INT     = 0    
 AS     
   
     DECLARE @MessageType INT,  
             @Status      INT,  
             @Results     NVARCHAR(250),  
             @BaseDate  NCHAR(8)  
     
     CREATE TABLE #KPX_TQCTestResult (WorkingTag NCHAR(1) NULL)  
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCTestResult'  
    
     -- ������ Ű ä�� 
     DECLARE @MaxSeq INT,  
             @Count  INT,  
             @MaxNo  NVARCHAR(20)  
     
     SELECT @MaxNo = ''   
     
     SELECT @Count = Count(1) FROM #KPX_TQCTestResult WHERE ISNULL(InQCSeq,0) = 0 AND Status = 0  
    
     IF @Count >0   
     BEGIN  
     
         EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'KPX_TQCTestResult','QCSeq',@Count --rowcount    
         
         -- ���˻��ȣ����    
         SELECT @BaseDate = CONVERT(NCHAR(8), GETDATE(), 112)  
         
         EXEC _SCOMCreateNo 'SITE', 'KPX_TQCTestResult', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT  
         
         UPDATE #KPX_TQCTestResult               
            SET InQCSeq  = @MaxSeq + DataSeq  
               ,InQCNo   = @MaxNo     
          WHERE Status = 0   
            AND ISNULL(InQCSeq,0) = 0 
     END    
    
    
    
    UPDATE A      
       SET Result       = '�̹� ����Ǿ����ϴ�.',     
           MessageType  = 1234,      
           Status       = 1234      
      FROM #KPX_TQCTestResult AS A      
      JOIN KPX_TQCTestResult AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                              AND B.QCSeq = A.InQCSeq  
                                              AND B.IsEnd = '1'  
     WHERE ISNULL(A.Status,0) = 0  
       AND A.WorkingTag = 'A'   
    
    
    UPDATE A      
       SET Result       = '�̹� ������Ұ� �Ǿ����ϴ�.',     
           MessageType  = 1234,      
           Status       = 1234      
      FROM #KPX_TQCTestResult AS A      
      JOIN KPX_TQCTestResult AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                              AND B.QCSeq = A.InQCSeq  
                                              AND B.IsEnd = '0'  
     WHERE ISNULL(A.Status,0) = 0  
       AND A.WorkingTag = 'D'   
    
    
    --------------------------------------------------------------------------------------  
    -- üũ, �԰����� �� �����ʹ� ���� ��� �� �� �����ϴ�.   
    --------------------------------------------------------------------------------------  
    CREATE TABLE #ProgTable ( IDX_NO INT, DelvSeq INT, DelvSerl INT )   
    INSERT INTO #ProgTable ( IDX_NO, DelvSeq, DelvSerl )   
    SELECT A.IDX_NO, A.DelvSeq, A.DelvSerl   
      FROM #KPX_TQCTestResult                   AS A   
      LEFT OUTER JOIN KPX_TQCTestResult         AS B ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.InQCSeq )   
      LEFT OUTER JOIN KPX_TQCTestRequestItem    AS C ON ( C.CompanySeq = @CompanySeq AND C.ReqSeq = B.ReqSeq AND C.ReqSerl = B.ReqSerl )   
     WHERE A.WorkingTag = 'D'   
       AND A.Status = 0   
       AND C.SMSourceType = 1000522008   
      
    CREATE TABLE #TMP_ProgressTable   
    (  
        IDOrder   INT,   
        TableName NVARCHAR(100)  
    )   
  
    INSERT INTO #TMP_ProgressTable (IDOrder, TableName)   
    SELECT 1, '_TPUDelvInItem'   -- ������ ã�� ���̺�  
  
    CREATE TABLE #TCOMProgressTracking  
    (  
        IDX_NO  INT,    
        IDOrder  INT,   
        Seq      INT,   
        Serl     INT,   
        SubSerl  INT,   
        Qty      DECIMAL(19,5),   
        StdQty   DECIMAL(19,5),   
          Amt      DECIMAL(19,5),   
        VAT      DECIMAL(19,5)  
    )   
   
    EXEC _SCOMProgressTracking   
            @CompanySeq = @CompanySeq,   
            @TableName = '_TPUDelvItem',    -- ������ �Ǵ� ���̺�  
            @TempTableName = '#ProgTable',  -- ������ �Ǵ� �������̺�  
            @TempSeqColumnName = 'DelvSeq',  -- �������̺��� Seq  
            @TempSerlColumnName = 'DelvSerl',  -- �������̺��� Serl  
            @TempSubSerlColumnName = ''    
      
      
    UPDATE A  
       SET Result = '�԰����� �� �����ʹ� ���� ��� �� �� �����ϴ�.',   
           Status = 1234,   
           MessageType = 1234   
      FROM #KPX_TQCTestResult               AS A   
      JOIN #TCOMProgressTracking            AS B ON ( B.IDX_NO = A.IDX_NO )   
      JOIN KPX_TPUDelvInQuantityAdjust      AS C ON ( C.CompanySeq = @CompanySeq AND C.DelvInSeq = B.Seq AND C.DelvInSerl = B.Serl )   
    --------------------------------------------------------------------------------------  
    -- üũ, END   
    --------------------------------------------------------------------------------------  
    
    UPDATE A      
       SET Result       = '�̵�ó���� ���� ' + CASE WHEN B.SMTestResult <> 1010418002 THEN '���������� ���ű⺻â��' ELSE '�߰�����Mapping������ ���԰˻�DATA ���հ�ǰ �̵�â��' END + '�� ������ֽʽÿ�.',     
           MessageType  = @MessageType,      
           Status       = @Status      
      FROM #KPX_TQCTestResult AS A      
      LEFT OUTER JOIN KPX_TQCTestResult AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                         AND B.QCSeq = A.InQCSeq  
      LEFT OUTER JOIN KPX_TQCTestRequest AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq  
                                                          AND C.ReqSeq = B.ReqSeq  
     WHERE ISNULL(A.Status,0) = 0  
       AND ( (ISNULL(B.SMTestResult,0) <> 1010418002 AND (EXISTS (SELECT TOP 1 1 FROM _TDAFactUnit WHERE CompanySeq = @CompanySeq AND BizUnit = C.BizUnit AND ISNULL(WHSeq,0) = 0)))  
            OR (ISNULL(B.SMTestResult,0) = 1010418002 AND  (EXISTS (SELECT TOP 1 1 
                                                                          FROM _TDAWH AS H WITH(NOLOCK)  
                                                                          JOIN KPX_TCOMEnvItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq  
                                                                                                                AND I.EnvSeq = 49  
                                                                                                                AND I.EnvValue = H.WHSeq   
                                                                         WHERE H.CompanySeq = @CompanySeq AND H.BizUnit = C.BizUnit AND ISNULL(H.WHSeq,0) = 0
                                                                       )
                                                           )
               ) 
           )  
    
    -- üũ, â��ǰ���� ȭ�鿡 ��ϵ��� �ʾ� �԰��� �� �����ϴ�.  
    UPDATE A      
       SET Result       = 'â��ǰ���� ȭ�鿡 ��ϵ��� �ʾ� ó���� �� �����ϴ�.',     
           MessageType  = 1234,      
           Status       = 1234      
      FROM #KPX_TQCTestResult           AS A   
      LEFT OUTER JOIN _TUIImpDelvItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq AND B.DelvSerl = A.DelvSerl )   
      LEFT OUTER JOIN _TUIImpDelv       AS D ON ( D.CompanySeq = @CompanySeq AND D.DelvSeq = B.DelvSeq )   
      OUTER APPLY (  
                   SELECT COUNT(1) AS Cnt   
                     FROM _TDAWHItem AS Z   
                     LEFT OUTER JOIN _TDAWH AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.WHSeq = Z.WHSeq )   
                    WHERE Z.CompanySeq = @CompanySeq   
                      AND Z.ItemSeq = B.ItemSeq   
                      AND Y.BizUnit = D.BizUnit   
                 ) AS C   
      LEFT OUTER JOIN KPX_TQCTestResult         AS F ON F.CompanySeq = @CompanySeq AND F.QCSeq = A.InQCSeq  
      LEFT OUTER JOIN KPX_TQCTestRequestItem    AS E ON E.CompanySeq = @CompanySeq AND E.ReqSeq = F.ReqSeq AND E.ReqSerl = F.ReqSerl  
     WHERE ISNULL(C.Cnt,0) = 0   
       AND ISNULL(A.Status,0) = 0   
       AND E.SMSourceType = 1000522007  
       AND A.WorkingTag = 'A' 
    -- üũ, END   
    
    -- üũ, â��ǰ���� ȭ�鿡 ���� â�� �ߺ����� ��ϵǾ� �԰��� �� �����ϴ�.  
      UPDATE A      
         SET Result       = 'â��ǰ���� ȭ�鿡 ���� â�� �ߺ����� ��ϵǾ� ó���� �� �����ϴ�.',     
             MessageType  = 1234,      
             Status       = 1234      
      FROM #KPX_TQCTestResult           AS A   
      LEFT OUTER JOIN _TUIImpDelvItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq AND B.DelvSerl = A.DelvSerl )   
      LEFT OUTER JOIN _TUIImpDelv       AS D ON ( D.CompanySeq = @CompanySeq AND D.DelvSeq = B.DelvSeq )   
      OUTER APPLY (  
                   SELECT COUNT(1) AS Cnt   
                     FROM _TDAWHItem AS Z   
                     LEFT OUTER JOIN _TDAWH AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.WHSeq = Z.WHSeq )   
                    WHERE Z.CompanySeq = @CompanySeq   
                      AND Z.ItemSeq = B.ItemSeq   
                      AND Y.BizUnit = D.BizUnit   
                 ) AS C   
      LEFT OUTER JOIN KPX_TQCTestResult         AS F ON F.CompanySeq = @CompanySeq AND F.QCSeq = A.InQCSeq  
      LEFT OUTER JOIN KPX_TQCTestRequestItem    AS E ON E.CompanySeq = @CompanySeq AND E.ReqSeq = F.ReqSeq AND E.ReqSerl = F.ReqSerl  
     WHERE ISNULL(C.Cnt,0) > 1   
       AND ISNULL(A.Status,0) = 0    
       AND E.SMSourceType = 1000522007 
       AND A.WorkingTag = 'A' 
    -- üũ, END   
    
    
     SELECT * FROM #KPX_TQCTestResult   
     
 RETURN      
  GO
begin tran 
exec KPXCM_SQCInQCIResultNoTestCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <InQCNo />
    <ReqNo>201508260001</ReqNo>
    <SMTestResult>1010418001</SMTestResult>
    <SMTestResultName>�հ�</SMTestResultName>
    <InQCSeq>0</InQCSeq>
    <ItemSeq>133</ItemSeq>
    <ReqSeq>546</ReqSeq>
    <ReqSerl>1</ReqSerl>
    <DelvNo>201509010002</DelvNo>
    <ItemName>EO(ETHYLENE OXIDE)</ItemName>
    <ItemNo>41120001</ItemNo>
    <LotNo>��ũ�θ�LotNo</LotNo>
    <QCTypeName>���԰˻�(����,��ǰ)</QCTypeName>
    <TestDate>20151102</TestDate>
    <DeptSeq>241</DeptSeq>
    <OKQty>10</OKQty>
    <BadQty>0</BadQty>
    <SourceType>1</SourceType>
    <Qty>10</Qty>
    <ReqDate>20150826</ReqDate>
    <EmpSeq>1</EmpSeq>
    <CustName>������</CustName>
    <DelvDate>20150901</DelvDate>
    <InOutType>����</InOutType>
    <QCType>11</QCType>
    <DelvSeq>190</DelvSeq>
    <DelvSerl>1</DelvSerl>
    <SMSourceType>1000522008</SMSourceType>
    <IsNoTest>0</IsNoTest>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030782,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1026257
rollback 