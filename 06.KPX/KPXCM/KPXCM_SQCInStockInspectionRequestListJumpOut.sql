IF OBJECT_ID('KPXCM_SQCInStockInspectionRequestListJumpOut') IS NOT NULL 
    DROP PROC KPXCM_SQCInStockInspectionRequestListJumpOut
GO 

-- v2016.06.02 
/************************************************************  
 ��  �� - ������-���˻��Ƿ���ȸ : JumpOut  
 �ۼ��� - 20141204  
 �ۼ��� - ����ȯ  
 ������ -   
************************************************************/  
CREATE PROC KPXCM_SQCInStockInspectionRequestListJumpOut
    @xmlDocument   NVARCHAR(MAX) ,              
    @xmlFlags      INT = 0,              
    @ServiceSeq    INT = 0,              
    @WorkingTag    NVARCHAR(10)= '',                    
    @CompanySeq    INT = 1,              
    @LanguageSeq   INT = 1,              
    @UserSeq       INT = 0,              
    @PgmSeq        INT = 0         
  
AS          
      
    CREATE TABLE #KPX_TQCTestRequestItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCTestRequestItem'       
    IF @@ERROR <> 0 RETURN    
      

    ALTER TABLE #KPX_TQCTestRequestItem ADD Qty DECIMAL(19,5)
    UPDATE #KPX_TQCTestRequestItem
       SET Qty = ReqQty

    -- �ű� ���� 
    IF NOT EXISTS ( SELECT 1 FROM #KPX_TQCTestRequestItem AS A WITH (NOLOCK) JOIN KPX_TQCTestResult AS B ON ( B.CompanySEq = @CompanySEq AND B.ReqSeq = A.ReqSeq AND B.ReqSerl = A.ReqSerl ))
    BEGIN   
          
        UPDATE A    
           SET StockQCSeq = B.QCSeq     
          FROM #KPX_TQCTestRequestItem AS A WITH (NOLOCK) JOIN KPX_TQCTestResult AS B ON ( B.CompanySEq = @CompanySEq AND B.ReqSeq = A.ReqSeq AND B.ReqSerl = A.ReqSerl)     
        
        
        -- LotNo�� ������ LotNo2�� ������Ʈ 
        UPDATE A 
           SET LotNo = Memo1 
          FROM #KPX_TQCTestRequestItem AS A 
         WHERE ISNULL(A.LotNo,'') = ''
        
        SELECT * FROM #KPX_TQCTestRequestItem 
          
        SELECT ISNULL(D.TestItemName,'')    AS TestItemName,   
               ISNULL(D.InTestItemName,'')  AS InTestItemName,
               ISNULL(D.TestItemSeq,0)      AS TestItemSeq,   
               E.QAAnalysisType             AS AnalysisSeq,   
               E.QAAnalysisTypeName         AS AnalysisName,   
               F.QCUnit                     AS QCUnitSeq,   
               F.QCUnitName,   
               C.SMInputType,   
               G.MinorName                  AS SMInputTypeName,   
               C.LowerLimit,   
               C.UpperLimit,   
               '0'                          AS IsExists 
          FROM #KPX_TQCTestRequestItem              AS M LEFT OUTER JOIN KPX_TQCTestRequestItem    AS B ON B.CompanySeq     = @CompanySeq 
                                                                                                       AND M.ReqSeq         = B.ReqSeq
                                                                                                       AND M.ReqSerl        = B.ReqSerl 
                                                         LEFT OUTER JOIN KPX_TQCQASpec             AS C ON C.CompanySeq     = B.CompanySeq 
                                                                                                       AND C.ItemSeq        = B.ItemSeq
                                                                                                       AND C.QCType         = B.QCType
																									   AND M.ReqDate BETWEEN C.SDate AND C.EDate
                                                         LEFT OUTER JOIN KPX_TQCQATestItems        AS D ON D.CompanySeq     = @CompanySeq 
                                                                                                       AND D.TestItemSeq    = C.TestItemSeq
                                                         LEFT OUTER JOIN KPX_TQCQAAnalysisType     AS E ON E.CompanySeq     = @CompanySeq 
                                                                                                       AND E.QAAnalysisType = C.QAAnalysisType
                                                         LEFT OUTER JOIN KPX_TQCQAProcessQCUnit    AS F ON F.CompanySeq     = @CompanySeq 
                                                                                                       AND F.QCUnit         = C.QCUnit
               LEFT OUTER JOIN _TDASMinor                AS G ON G.CompanySeq     = @CompanySeq 
                                                                                                       AND G.MinorSeq       = C.SMInputType
         WHERE B.CompanySeq = @CompanySeq    
           AND ( C.QCType IS NOT NULL OR C.QCType <> 0 )  
      
    END   
    ELSE  
    BEGIN -- ����������   
          
        SELECT B.QCSeq AS StockQCSeq FROM #KPX_TQCTestRequestItem AS A WITH (NOLOCK) JOIN KPX_TQCTestResult AS B ON ( B.CompanySEq = @CompanySEq AND B.ReqSeq = A.ReqSeq )
          
        SELECT TOP 1 '1' AS IsExists FROM #KPX_TQCTestRequestItem AS A WITH (NOLOCK) JOIN KPX_TQCTestResult AS B ON ( B.CompanySEq = @CompanySEq AND B.ReqSeq = A.ReqSeq )
      
    END   
      


    
      
RETURN  
  

GO
exec KPXCM_SQCInStockInspectionRequestListJumpOut @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <ReqSeq>84</ReqSeq>
    <ReqSerl>3</ReqSerl>
    <QCGubnName>�̰˻�</QCGubnName>
    <QCGubnSeq>1010418004</QCGubnSeq>
    <BizUnitName>����-����</BizUnitName>
    <BizUnit>0</BizUnit>
    <ReqNo>201606020001</ReqNo>
    <ReqDate>20160602</ReqDate>
    <DeptName>���������2</DeptName>
    <DeptSeq>1300</DeptSeq>
    <EmpName>����õ</EmpName>
    <EmpSeq>2028</EmpSeq>
    <QCTypeName>1</QCTypeName>
    <QCType>5</QCType>
    <ItemName>Lot_�ٽ��ѹ��׽�Ʈ_����õ</ItemName>
    <ItemNo>Lot_�ٽ��ѹ��׽�ƮNo_����õ</ItemNo>
    <Spec />
    <ItemSeq>1052403</ItemSeq>
    <LotNo />
    <Memo1>333</Memo1>
    <WHName>T�Ϲ�â��1_����õ</WHName>
    <WHSeq>7534</WHSeq>
    <ReqQty>1</ReqQty>
    <UnitName>EA</UnitName>
    <UnitSeq>4</UnitSeq>
    <CreateDate />
    <RegDate />
    <SupplyName />
    <SupplyCustSeq>0</SupplyCustSeq>
    <Remark />
    <StockQCSeq>0</StockQCSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037328,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030570