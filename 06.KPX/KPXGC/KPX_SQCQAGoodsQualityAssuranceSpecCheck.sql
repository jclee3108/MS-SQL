  
IF OBJECT_ID('KPX_SQCQAGoodsQualityAssuranceSpecCheck') IS NOT NULL   
    DROP PROC KPX_SQCQAGoodsQualityAssuranceSpecCheck  
GO  
  
-- v2014.11.20  
  
-- ǰ�����԰ݵ��(����ǰ)-üũ by ����õ   
CREATE PROC KPX_SQCQAGoodsQualityAssuranceSpecCheck  
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
    
    CREATE TABLE #KPX_TQCQAQualityAssuranceSpec( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCQAQualityAssuranceSpec'   
    IF @@ERROR <> 0 RETURN 
    
    --select * from #KPX_TQCQAQualityAssuranceSpec
    
    --return 
    ------------------------------------------------------------------------------------------
    -- üũ0, ������ �����Ͱ� �����մϴ�.(������)
    ------------------------------------------------------------------------------------------
    IF @WorkingTag = 'SaveAs' 
    BEGIN
        IF EXISTS (SELECT 1 FROM #KPX_TQCQAQualityAssuranceSpec AS A 
                            JOIN KPX_TQCQAQualityAssuranceSpec  AS B ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq AND B.ItemSeq = A.ItemSeq AND B.QCType = A.QCType AND B.IsProd = CASE WHEN @PgmSeq = 1021430 THEN '1' ELSE '0' END ) 
                  ) 
        BEGIN
            UPDATE A
               SET Result = '������ �����Ͱ� �����մϴ�.(������)', 
                   Status = 1234, 
                   MessageType = 1234 
              FROM #KPX_TQCQAQualityAssuranceSpec AS A 
             WHERE A.Status = 0 
        END 
    END 
    
    ------------------------------------------------------------------------------------------
    -- üũ0, END 
    ------------------------------------------------------------------------------------------
    
     
    ------------------------------------------------------------------------------------------
    -- üũ0, ���ص����ʹ� ������ �� �����ϴ�. 
    ------------------------------------------------------------------------------------------
    IF EXISTS ( SELECT 1 
                  FROM #KPX_TQCQAQualityAssuranceSpec AS A 
                  JOIN KPX_TQCQAQualityAssuranceSpec  AS B ON ( B.CompanySeq = @CompanySeq AND B.Serl = A.Serl ) 
                 WHERE B.TestItemSeq <> A.TestItemSeq 
                    OR B.QAAnalysisType <> A.QAAnalysisType 
              ) 
    --OR EXISTS (SELECT 1 FROM #KPX_TQCQAQualityAssuranceSpec WHERE CustSeq <> CustSeqOld OR ItemSeq <> ItemSeqOld OR QCType <> QCType)
    BEGIN
        UPDATE A
           SET Result = '���ص����ʹ� ������ �� �����ϴ�. ', 
               Status = 1234, 
               MessageType = 1234 
          FROM #KPX_TQCQAQualityAssuranceSpec AS A 
         WHERE A.Status = 0 
           AND A.Workingtag = 'U' 
    END 
    
    ------------------------------------------------------------------------------------------
    -- üũ0, END 
    ------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------
    -- üũ1, �ߺ����� üũ 
    ------------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
                          @LanguageSeq       ,  
                          0
      
    UPDATE #KPX_TQCQAQualityAssuranceSpec
       SET Result       = @Results, 
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #KPX_TQCQAQualityAssuranceSpec AS A  
      JOIN (SELECT S.CustSeq, S.ItemSeq, S.QCType, S.TestItemSeq, S.QAAnalysisType, S.SDate
              FROM (SELECT A1.CustSeq, A1.ItemSeq, A1.QCType, A1.TestItemSeq, A1.QAAnalysisType, A1.SDate
                      FROM #KPX_TQCQAQualityAssuranceSpec AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.CustSeq, A1.ItemSeq, A1.QCType, A1.TestItemSeq, A1.QAAnalysisType, A1.SDate
                      FROM KPX_TQCQAQualityAssuranceSpec AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND A1.IsProd = CASE WHEN @PgmSeq = 1021430 THEN '1' ELSE '0' END
                       AND NOT EXISTS (SELECT 1 FROM #KPX_TQCQAQualityAssuranceSpec   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND CustSeq = A1.CustSeq 
                                                 AND ItemSeq = A1.ItemSeq 
                                                 AND QCType = A1.QCType 
                                                 AND TestItemSeq = A1.TestItemSeq 
                                                 AND QAAnalysisType = A1.QAAnalysisType 
                                                 AND SDate = A1.SDate
                                      )  
                   ) AS S  
             GROUP BY S.CustSeq, S.ItemSeq, S.QCType, S.TestItemSeq, S.QAAnalysisType, S.SDate
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.CustSeq = B.CustSeq AND A.ItemSeq = B.ItemSeq AND A.QCType = B.QCType AND A.TestItemSeq = B.TestItemSeq AND A.QAAnalysisType = B.QAAnalysisType AND A.SDate = B.SDate )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    ------------------------------------------------------------------------------------------
    -- üũ1, END 
    ------------------------------------------------------------------------------------------
    
    
    ------------------------------------------------------------------------------------------
    -- üũ2, ���� �����͸��� ����/������ �� �ֽ��ϴ�.
    ------------------------------------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM #KPX_TQCQAQualityAssuranceSpec WHERE Status = 0 AND WorkingTag IN ( 'D','U' ) AND EDate <> '99991231') 
    BEGIN
        UPDATE A
           SET Result = '���� �����͸��� ����/������ �� �ֽ��ϴ�.', 
               Status = 1234, 
               MessageType = 1234 
          FROM #KPX_TQCQAQualityAssuranceSpec AS A 
         WHERE Status = 0 
    END 
    ------------------------------------------------------------------------------------------
    -- üũ2, END 
    ------------------------------------------------------------------------------------------
    
    
    ------------------------------------------------------------------------------------------
    -- üũ3, ����������� �����ܰ��� ��������Ϻ��� Ŀ�� �մϴ�. 
    ------------------------------------------------------------------------------------------
    IF EXISTS (SELECT 1
                 FROM #KPX_TQCQAQualityAssuranceSpec AS A 
                 OUTER APPLY (SELECT MAX(Y.SDate) AS MaxSDate, Z.CustSeq, Z.ItemSeq, Z.QCType, Z.TestItemSeq, Z.QAAnalysisType
                                FROM #KPX_TQCQAQualityAssuranceSpec AS Z 
                                JOIN KPX_TQCQAQualityAssuranceSpec  AS Y ON ( Y.CompanySeq = @CompanySeq 
                                                                          AND Y.CustSeq = Z.CustSeq 
                                                                          AND Y.ItemSeq = Z.ItemSeq 
                                                                          AND Y.QCType = Z.QCType 
                                                                          AND Y.TestItemSeq = Z.TestItemSeq 
                                                                          AND Y.QAAnalysisType = Z.QAAnalysisType 
                                                                          AND Y.Serl <> Z.Serl 
                                                                          AND Y.IsProd = CASE WHEN @PgmSeq = 1021430 THEN '1' ELSE '0' END
                                                                            ) 
                               WHERE Z.CustSeq = A.CustSeq 
                                 AND Z.ItemSeq = A.ItemSeq 
                                 AND Z.QCType = A.QCType 
                                 AND Z.TestItemSeq = A.TestItemSeq 
                                 AND Z.QAAnalysisType = A.QAAnalysisType 
                               GROUP BY Z.CustSeq, Z.ItemSeq, Z.QCType, Z.TestItemSeq, Z.QAAnalysisType
                             ) AS B 
                WHERE A.Status = 0 
                  AND A.WorkingTag IN ( 'A', 'U' ) 
                  AND A.SDate <= B.MaxSDate 
              )
    BEGIN
        UPDATE A
           SET Result = '����������� �����ܰ��� ��������Ϻ��� Ŀ�� �մϴ�.', 
               Status = 1234, 
               MessageType = 1234 
          FROM #KPX_TQCQAQualityAssuranceSpec AS A 
         WHERE Status = 0 
    END 
    
    ------------------------------------------------------------------------------------------
    -- üũ3, END 
    ------------------------------------------------------------------------------------------
    
    ------------------------------------------------------------------------------------------
    -- ��ȣ+�ڵ� ���� :           
    ------------------------------------------------------------------------------------------
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TQCQAQualityAssuranceSpec WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TQCQAQualityAssuranceSpec', 'Serl', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPX_TQCQAQualityAssuranceSpec  
           SET Serl = @Seq + DataSeq 
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END 
    
    ------------------------------------------------------------------------------------------
    -- �����ڵ� 0�� �� �� ����ó��   
    ------------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE A   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TQCQAQualityAssuranceSpec AS A 
     WHERE Status = 0  
       AND ( Serl = 0 OR Serl IS NULL )  
       AND WorkingTag IN ( 'A' , 'U' ) 
    
    SELECT * FROM #KPX_TQCQAQualityAssuranceSpec   
      
    RETURN  
GO 
begin tran 
exec KPX_SQCQAGoodsQualityAssuranceSpecCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>19</Serl>
    <TestItemName>as</TestItemName>
    <InTestItemName>1r1</InTestItemName>
    <OutTestItemName>1</OutTestItemName>
    <TestItemSeq>3</TestItemSeq>
    <QAAnalysisTypeNo>test1232432222</QAAnalysisTypeNo>
    <QAAnalysisTypeName>test123243222</QAAnalysisTypeName>
    <QAAnalysisType>4</QAAnalysisType>
    <SMInputTypeName />
    <SMInputType>0</SMInputType>
    <LowerLimit />
    <UpperLimit>12314</UpperLimit>
    <QCUnitName>�˻����3</QCUnitName>
    <QCUnit>3</QCUnit>
    <SDate>20141101</SDate>
    <EDate>20141102</EDate>
    <RegEmpName>����õ</RegEmpName>
    <RegEmpSeq>2028</RegEmpSeq>
    <RegDateTime>20141120</RegDateTime>
    <LastUserName>����õ</LastUserName>
    <LastUserSeq>2028</LastUserSeq>
    <LastDateTime>20141120</LastDateTime>
    <Remark />
    <TestItemSeqOld>3</TestItemSeqOld>
    <QAAnalysisTypeOld>4</QAAnalysisTypeOld>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <CustSeq>42507</CustSeq>
    <ItemSeq>27439</ItemSeq>
    <QCType>3</QCType>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>20</Serl>
    <TestItemName>as</TestItemName>
    <InTestItemName>1r1</InTestItemName>
    <OutTestItemName>1</OutTestItemName>
    <TestItemSeq>3</TestItemSeq>
    <QAAnalysisTypeNo>test1232432222</QAAnalysisTypeNo>
    <QAAnalysisTypeName>test123243222</QAAnalysisTypeName>
    <QAAnalysisType>4</QAAnalysisType>
    <SMInputTypeName>����</SMInputTypeName>
    <SMInputType>1018002</SMInputType>
    <LowerLimit>123124</LowerLimit>
    <UpperLimit>21314</UpperLimit>
    <QCUnitName>�˻����3</QCUnitName>
    <QCUnit>3</QCUnit>
    <SDate>20141103</SDate>
    <EDate>99991231</EDate>
    <RegEmpName>����õ</RegEmpName>
    <RegEmpSeq>2028</RegEmpSeq>
    <RegDateTime>20141120</RegDateTime>
    <LastUserName>����õ</LastUserName>
    <LastUserSeq>2028</LastUserSeq>
    <LastDateTime>20141120</LastDateTime>
    <Remark />
    <TestItemSeqOld>3</TestItemSeqOld>
    <QAAnalysisTypeOld>4</QAAnalysisTypeOld>
    <CustSeq>42507</CustSeq>
    <ItemSeq>27439</ItemSeq>
    <QCType>3</QCType>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>27</Serl>
    <TestItemName>a</TestItemName>
    <InTestItemName>a</InTestItemName>
    <OutTestItemName>a</OutTestItemName>
    <TestItemSeq>2</TestItemSeq>
    <QAAnalysisTypeNo>test123243</QAAnalysisTypeNo>
    <QAAnalysisTypeName>test123243</QAAnalysisTypeName>
    <QAAnalysisType>3</QAAnalysisType>
    <SMInputTypeName>����</SMInputTypeName>
    <SMInputType>1018001</SMInputType>
    <LowerLimit>123,143</LowerLimit>
    <UpperLimit>12,314</UpperLimit>
    <QCUnitName>�˻����3</QCUnitName>
    <QCUnit>3</QCUnit>
    <SDate>20141105</SDate>
    <EDate>20141105</EDate>
    <RegEmpName>����õ</RegEmpName>
    <RegEmpSeq>2028</RegEmpSeq>
    <RegDateTime>20141120</RegDateTime>
    <LastUserName />
    <LastUserSeq>0</LastUserSeq>
    <LastDateTime />
    <Remark />
    <TestItemSeqOld>2</TestItemSeqOld>
    <QAAnalysisTypeOld>3</QAAnalysisTypeOld>
    <CustSeq>42507</CustSeq>
    <ItemSeq>27439</ItemSeq>
    <QCType>3</QCType>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>0</Serl>
    <TestItemName>a</TestItemName>
    <InTestItemName>a</InTestItemName>
    <OutTestItemName>a</OutTestItemName>
    <TestItemSeq>2</TestItemSeq>
    <QAAnalysisTypeNo>test123243</QAAnalysisTypeNo>
    <QAAnalysisTypeName>test123243</QAAnalysisTypeName>
    <QAAnalysisType>3</QAAnalysisType>
    <SMInputTypeName>����</SMInputTypeName>
    <SMInputType>1018002</SMInputType>
    <LowerLimit>123</LowerLimit>
    <UpperLimit>123</UpperLimit>
    <QCUnitName>�˻����2</QCUnitName>
    <QCUnit>2</QCUnit>
    <SDate>20141106</SDate>
    <EDate>99991231</EDate>
    <RegEmpName>����õ</RegEmpName>
    <RegEmpSeq>2028</RegEmpSeq>
    <RegDateTime>20141121</RegDateTime>
    <LastUserName />
    <LastUserSeq>0</LastUserSeq>
    <LastDateTime />
    <Remark />
    <TestItemSeqOld>2</TestItemSeqOld>
    <QAAnalysisTypeOld>3</QAAnalysisTypeOld>
    <CustSeq>42507</CustSeq>
    <ItemSeq>27439</ItemSeq>
    <QCType>3</QCType>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026006,@WorkingTag=N'SaveAs',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021430
rollback 