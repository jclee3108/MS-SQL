  
IF OBJECT_ID('KPX_SHREduRstUploadCheck') IS NOT NULL   
    DROP PROC KPX_SHREduRstUploadCheck  
GO  
  
-- v2014.11.19  
  
-- �������Upload-üũ by ����õ   
CREATE PROC KPX_SHREduRstUploadCheck  
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
      
    CREATE TABLE #THREduPersRst( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#THREduPersRst'   
    IF @@ERROR <> 0 RETURN     
    
    UPDATE A 
       SET EduCourseSeq = B.EduCourseSeq
      FROM #THREduPersRst AS A 
      JOIN _THREduCourse  AS B ON ( B.CompanySeq = @CompanySeq AND B.EduCourseName = A.EduCourseName ) 
     WHERE A.WorkingTag = 'A'
       AND A.Status = 0
    
    ---------------------------------------------------------
    -- ������ ���� �н������� ��� 
    ---------------------------------------------------------
    DECLARE @MaxSeq INT 
    
    CREATE TABLE #THREduCourse
    (
        DataSeq         INT IDENTITY, 
        OriDataSeq      INT, 
        EduCourseSeq    INT, 
        EduCourseName   NVARCHAR(200), 
    )
    INSERT INTO #THREduCourse ( OriDataSeq, EduCourseSeq, EduCourseName ) 
    SELECT DataSeq, EduCourseSeq, EduCourseName
      FROM #THREduPersRst AS A 
     WHERE A.EduCourseSeq IS NULL 
       AND A.WorkingTag = 'A'
       AND A.Status = 0
    
    SELECT @MaxSeq = ISNULL(Max(EduCourseSeq), 0)    -- ���� ū �н������ڵ带 �޾ƿ´�.
      FROM _THREduCourse                            -- �н����� ���̺���
     WHERE CompanySeq = @CompanySeq
  
     UPDATE A
        SET EduCourseSeq = @MaxSeq + DataSeq    -- ���� ū �н������ڵ忡 �Էµ� ��ŭ�� ���Ͽ� �����Ѵ�.
       FROM #THREduCourse AS A
    
    INSERT INTO _THREduCourse 
    (
        CompanySeq, EduCourseSeq, EduCourseName, EduClassSeq, SMEduCourseType, 
        EduRem, LastUserSeq, LastDateTime, UMEduGrpType, IsUse, 
        EtcCourseYN
    )
    SELECT @CompanySeq, EduCourseSeq, EduCourseName, 0, 0, 
           '', @UserSeq, GETDATE(), 0, '0', 
           NULL
      FROM #THREduCourse AS A 
    
    ---------------------------------------------------------
    -- ������ ���� �н������� ���, END 
    ---------------------------------------------------------
    
    -- Input���� ���λ����� �н����� �ڵ� ������Ʈ 
    UPDATE A
       SET EduCourseSeq = B.EduCourseSeq
      FROM #THREduPersRst AS A 
      JOIN #THREduCourse  AS B ON ( B.OriDataSeq = A.DataSeq ) 
     WHERE A.WorkingTag = 'A' 
       AND A.Status = 0 
    
    -- ����ڵ�, �μ��ڵ带 ���ID�� ã�� 
    UPDATE A
       SET A.EmpSeq = B.EmpSeq, 
           A.DeptSeq = B.DeptSeq 
      FROM #THREduPersRst AS A 
      JOIN _fnAdmEmpOrd(@CompanySeq, '') AS B ON ( B.EmpID = A.EmpID ) 
     WHERE A.WorkingTag = 'A' 
       AND A.Status = 0 
    
    -- �н����� �� ������ �ڵ� ã�� 
    UPDATE A
       SET A.EduTypeSeq = ISNULL(B.EduTypeSeq,0), 
           A.SMComplate = CASE WHEN A.ComplateName = '�̼���' THEN 1000273002 WHEN A.ComplateName = '����' THEN 1000273001 ELSE 0 END, 
           A.IsEI = CASE WHEN A.EI = '����' THEN '1' ELSE '0' END 
      FROM #THREduPersRst AS A 
      JOIN _THREduCourse  AS B ON ( B.CompanySeq = @CompanySeq AND B.EduCourseSeq = A.EduCourseSeq ) 
     WHERE A.WorkingTag = 'A' 
       AND A.Status = 0 
    
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT, 
            @MaxNo  INT
      
    SELECT @Count = COUNT(1) FROM #THREduPersRst WHERE WorkingTag = 'A' AND Status = 0  
    IF @Count > 0  
    BEGIN  
        
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_THREduPersRst', 'RstSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #THREduPersRst  
           SET RstSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END 
    
    
    SELECT @MaxNo = CONVERT(INT,MAX(RIGHT(RstNo,4)))
      FROM _THREduPersRst 
     WHERE CompanySeq = @CompanySeq 
       AND LEFT(RstNo,6) = CONVERT(NCHAR(6),GETDATE(),112)
    
    UPDATE A 
       SET RstNo = RIGHT('000' + CONVERT(NVARCHAR(20),@MaxNo + DataSeq ),4) 
      FROM #THREduPersRst AS A 
     WHERE WorkingTag = 'A'  
       AND Status = 0  
    
    
    -------------------------------------------------------
    -- üũ, �ش� ID�� ����� �����ϴ�. 
    -------------------------------------------------------
    UPDATE A 
       SET Result = '�ش� ID�� ����� �����ϴ�. ( ID : ' + EmpID + ' )', 
           Status = 1234, 
           MessageType = 1234 
      FROM #THREduPersRst AS A 
     WHERE ISNULL(EmpSeq,0) = 0 
       AND Status = 0 
       AND A.WorkingTag = 'A' 
    -------------------------------------------------------
    -- üũ, END 
    -------------------------------------------------------
    
    -------------------------------------------------------
    -- üũ, �ش� ID�� �������� �ݿ����� �ʾҽ��ϴ�.
    -------------------------------------------------------
    UPDATE A 
       SET Result = '�ش� ID�� �������� �ݿ����� �ʾҽ��ϴ�. ( ID : ' + EmpID + ' )', 
           Status = 1234, 
           MessageType = 1234 
      FROM #THREduPersRst AS A 
     WHERE ISNULL(SMComplate,0) = 0 
       AND Status = 0 
       AND A.WorkingTag = 'A' 
    -------------------------------------------------------
    -- üũ, END 
    -------------------------------------------------------
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #THREduPersRst   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #THREduPersRst  
     WHERE Status = 0  
       AND ( RstSeq = 0 OR RstSeq IS NULL )  
      
    SELECT * FROM #THREduPersRst   
      
    RETURN  
GO 
begin tran 
exec KPX_SHREduRstUploadCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20000103</EmpID>
    <DeptName>����������</DeptName>
    <EduCourseName>�����ð��� ����</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>�̼���</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark>test</Remark>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20000201</EmpID>
    <DeptName>����2��</DeptName>
    <EduCourseName>�����������Ŵ�����</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>�̼���</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20000202</EmpID>
    <DeptName>���������</DeptName>
    <EduCourseName>����ä�ǰ����ǹ�</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>����</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20000801</EmpID>
    <DeptName>����4��</DeptName>
    <EduCourseName>����ä�ǰ�������</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>�̼���</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20001101</EmpID>
    <DeptName>���������</DeptName>
    <EduCourseName>�����ذ�� �ǻ����</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>�̼���</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20001102</EmpID>
    <DeptName>�ַ�ǿ���1��(test)</DeptName>
    <EduCourseName>���� �缺�� ����_AB</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>����</ComplateName>
    <ReturnAmt>1112</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20010201</EmpID>
    <DeptName>����2��</DeptName>
    <EduCourseName>���μ� �Ű�ǹ�</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>�̼���</ComplateName>
    <ReturnAmt>35153</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20010202</EmpID>
    <DeptName>����2��</DeptName>
    <EduCourseName>����Ͻ���������</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>����</ComplateName>
    <ReturnAmt>513</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20010401</EmpID>
    <DeptName>��������1��</DeptName>
    <EduCourseName>����������ǹ�</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>�̼���</ComplateName>
    <ReturnAmt>213</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20010502</EmpID>
    <DeptName>���������</DeptName>
    <EduCourseName>���� �缺�� ����_AB</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>����</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20010503</EmpID>
    <DeptName>����1��(�Ȼ�_2)</DeptName>
    <EduCourseName>�����ȹ �� �����ǹ�</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>�̼���</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20010802</EmpID>
    <DeptName>������</DeptName>
    <EduCourseName>��������� ���ؿ� ��������</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>�̼���</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark>test11</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>13</IDX_NO>
    <DataSeq>13</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20010901</EmpID>
    <DeptName>����1��</DeptName>
    <EduCourseName>�����׽�Ʈ</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>����</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark />
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>14</IDX_NO>
    <DataSeq>14</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20010902</EmpID>
    <DeptName>����5��</DeptName>
    <EduCourseName>�������(TPM)����</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>�̼���</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark />
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>15</IDX_NO>
    <DataSeq>15</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>12334</EmpID>
    <DeptName>����4��</DeptName>
    <EduCourseName>test123354435</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>����</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025970,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021807
rollback