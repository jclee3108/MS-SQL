  
IF OBJECT_ID('KPX_SPRPayRetEstCheck') IS NOT NULL   
    DROP PROC KPX_SPRPayRetEstCheck  
GO  
  
-- v2014.12.15  
  
-- �޿����� �������߰�׵��-üũ by ����õ   
CREATE PROC KPX_SPRPayRetEstCheck  
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
    
    CREATE TABLE #KPX_TPRPayRetEst( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPRPayRetEst'   
    IF @@ERROR <> 0 RETURN     
    
    -- �ߺ����� üũ :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
                          @LanguageSeq       ,  
                          0
    
    UPDATE #KPX_TPRPayRetEst  
       SET Result       = @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #KPX_TPRPayRetEst AS A   
      JOIN (SELECT S.YY, S.EmpSeq  
              FROM (SELECT A1.YY, A1.EmpSeq   
                      FROM #KPX_TPRPayRetEst AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.YY, A1.EmpSeq   
                      FROM KPX_TPRPayRetEst AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPX_TPRPayRetEst   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND YY = A1.YY 
                                                 AND EmpSeqOld = A1.EmpSeq 
                                      )  
                   ) AS S  
             GROUP BY S.YY, S.EmpSeq 
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.YY = B.YY AND A.EmpSeq = B.EmpSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    SELECT * FROM #KPX_TPRPayRetEst   
      
    RETURN  
GO 
exec KPX_SPRPayRetEstCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpName>������         </EmpName>
    <EmpID>20060103            </EmpID>
    <EmpSeq>166</EmpSeq>
    <RetEstAmt>22</RetEstAmt>
    <Remark />
    <EmpSeqOld>0</EmpSeqOld>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <YY>2014</YY>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpName>�����</EmpName>
    <EmpID>20120012</EmpID>
    <EmpSeq>1807</EmpSeq>
    <RetEstAmt>22</RetEstAmt>
    <Remark />
    <EmpSeqOld>0</EmpSeqOld>
    <YY>2014</YY>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpName>���ؼ�</EmpName>
    <EmpID>100001</EmpID>
    <EmpSeq>1000016</EmpSeq>
    <RetEstAmt>22</RetEstAmt>
    <Remark />
    <EmpSeqOld>0</EmpSeqOld>
    <YY>2014</YY>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpName>������</EmpName>
    <EmpID>20140601</EmpID>
    <EmpSeq>1000117</EmpSeq>
    <RetEstAmt>22</RetEstAmt>
    <Remark />
    <EmpSeqOld>0</EmpSeqOld>
    <YY>2014</YY>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026749,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022383