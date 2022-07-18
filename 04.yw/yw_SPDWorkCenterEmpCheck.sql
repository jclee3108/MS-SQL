  
IF OBJECT_ID('yw_SPDWorkCenterEmpCheck') IS NOT NULL   
    DROP PROC yw_SPDWorkCenterEmpCheck  
GO  
  
-- v.2007.07.19
  
-- ��ũ���ͺ��۾��ڵ��_YW (üũ) by����õ
CREATE PROC yw_SPDWorkCenterEmpCheck
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
      
    CREATE TABLE #YW_TPDWorkCenterEmp( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TPDWorkCenterEmp'   
    IF @@ERROR <> 0 RETURN     

    -- ����������üũ: UPDATE, DELETE�� ������ �������� ������ ����ó��  
    IF NOT EXISTS ( SELECT 1   
                      FROM #YW_TPDWorkCenterEmp AS A   
                      JOIN YW_TPDWorkCenterEmp AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.WorkCenterSeq = B.WorkCenterSeq AND A.EmpSeqOld = B.EmpSeq )  
                     WHERE A.WorkingTag IN ( 'U', 'D' )  
                       AND Status = 0   
                  )  
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              7                  , -- �ڷᰡ��ϵǾ������ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                              @LanguageSeq               
          
        UPDATE #YW_TPDWorkCenterEmp  
           SET Result       = @Results,  
               MessageType  = @MessageType,  
               Status       = @Status  
         WHERE WorkingTag IN ( 'U', 'D' )  
           AND Status = 0   
    END   
      
    -- �ߺ����� üũ :   
      
    UPDATE #YW_TPDWorkCenterEmp  
       SET Result       = '�۾��ڸ� �ߺ����� ���� �� �� �����ϴ�.',
           MessageType  = @MessageType,  
           Status       = 12341255  
      FROM #YW_TPDWorkCenterEmp AS A   
      JOIN (SELECT S.EmpSeq  
              FROM (SELECT A1.EmpSeq  
                      FROM #YW_TPDWorkCenterEmp AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.EmpSeq  
                      FROM YW_TPDWorkCenterEmp AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #YW_TPDWorkCenterEmp   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND WorkCenterSeq = A1.WorkCenterSeq
                                                 AND EmpSeq = A1.EmpSeq  
                                      )  
                   ) AS S  
             GROUP BY S.EmpSeq  
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.EmpSeq = B.EmpSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
      
    SELECT * FROM #YW_TPDWorkCenterEmp   
      
    RETURN  
Go
exec yw_SPDWorkCenterEmpCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpName>����õ</EmpName>
    <EmpSeq>2028</EmpSeq>
    <EmpSeqOld>2017</EmpSeqOld>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <WorkCenterSeq>2</WorkCenterSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016735,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014291


