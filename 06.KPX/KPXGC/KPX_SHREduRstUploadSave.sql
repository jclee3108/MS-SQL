  
IF OBJECT_ID('KPX_SHREduRstUploadSave') IS NOT NULL   
    DROP PROC KPX_SHREduRstUploadSave  
GO  
  
-- v2014.11.19  
  
-- �������Upload-���� by ����õ   
CREATE PROC KPX_SHREduRstUploadSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #THREduPersRst (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#THREduPersRst'   
    IF @@ERROR <> 0 RETURN    
    
    --select * from #THREduPersRst 
    
    --return 
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
    EXEC _SCOMLog  @CompanySeq     ,    -- ȸ���ȣ  
                   @UserSeq        ,    -- ����� ��ȣ  
                   '_THREduPersRst',    -- �����̺��  
                   '#THREduPersRst',    -- �ӽ����̺��  
                   'RstSeq'        ,    -- Ű�� �������� ���� , �� �����Ѵ�.  
                   'CompanySeq, RstSeq, RstNo, RegDate, EmpSeq, EduClassSeq, UMEduGrpType, EduTypeSeq, EduCourseSeq, EtcCourseName, SMInOutType, EduBegDate,   
                    EduEndDate, EduDd, EduTm, RstSummary, RstRem, SatisRate, EduOkDd, EduOkTm, SMGradeSeq, IsEndEval, IsEnd, FileNo, SMEduPlanType,  
                    LastUserSeq, LastDateTime,CfmEmpSeq, ReqSeq, UMInstitute, UMlocation, LecturerSeq, SatisLevel, EduPoint, EduOKPoint'    -- �� ���̺��� Į����  
                  
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_THREduRstWithCost')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_THREduRstWithCost'    , -- ���̺��        
                  '#THREduPersRst'    , -- �ӽ� ���̺��        
                  'RstSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��  
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #THREduPersRst WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #THREduPersRst AS A   
          JOIN _THREduPersRst AS B ON ( B.CompanySeq = @CompanySeq AND A.RstSeq = B.RstSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
        
        DELETE B   
          FROM #THREduPersRst AS A   
          JOIN KPX_THREduRstWithCost AS B ON ( B.CompanySeq = @CompanySeq AND A.RstSeq = B.RstSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
          
    END   
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #THREduPersRst WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO _THREduPersRst  
        (   
            CompanySeq, RstSeq, RstNo, RegDate, EmpSeq, 
            EduClassSeq, UMEduGrpType, EduTypeSeq, EduCourseSeq, EtcCourseName, 
            SMInOutType, EduBegDate, EduEndDate, EduDd, EduTm, 
            RstSummary, RstRem, SatisRate, EduOkDd, EduOkTm, 
            SMGradeSeq, IsEndEval, IsEnd, FileNo, SMEduPlanType, 
            LastUserSeq, LastDateTime, CfmEmpSeq, ReqSeq, UMInstitute, 
            UMlocation, LecturerSeq, SatisLevel, EduPoint, EduOKPoint, 
            ProgFromSeq, ProgFromSerl, ProgFromSubSerl, ProgFromTableSeq, IsBatchReq, 
            EtcInstitute ,Etclocation, EtcLecturer 
        )   
        SELECT @CompanySeq, A.RstSeq, A.RstNo, CONVERT(NCHAR(8),GETDATE(),112), A.EmpSeq, 
                0, NULL, A.EduTypeSeq, A.EduCourseSeq, '', 
                1012001, A.EduBegDate, A.EduEndDate, 0, A.ComplateTime, 
                NULL, '', NULL, 0, A.ComplateTime, 
                NULL, NULL, NULL, 0, 0, 
                @UserSeq, GETDATE(), 0, 0, NULL, 
                NULL, NULL, NULL, 0, 0, 
                NULL, NULL, NULL, NULL, NULL, 
                NULL ,NULL, NULL 
          FROM #THREduPersRst AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
        
        INSERT INTO KPX_THREduRstWithCost
        (
            CompanySeq, RstSeq, IsEI, SMComplate, LastUserSeq, LastDateTime
        )
        SELECT @CompanySeq, RstSeq, IsEI, SMComplate, @UserSeq, GETDATE()
          FROM #THREduPersRst
        
    END     
    
    SELECT * FROM #THREduPersRst   
      
    RETURN  
GO 
begin tran 
exec KPX_SHREduRstUploadSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ComplateName>�̼���</ComplateName>
    <ComplateTime>9.00000</ComplateTime>
    <DeptName>����������</DeptName>
    <EduBegDate>20141112</EduBegDate>
    <EduCourseName>�����ð��� ����</EduCourseName>
    <EduEndDate>20141112</EduEndDate>
    <EI>����</EI>
    <EmpID>20000103</EmpID>
    <Remark>test</Remark>
    <ReturnAmt>0.00000</ReturnAmt>
    <DeptSeq>11</DeptSeq>
    <EduCourseSeq>24</EduCourseSeq>
    <EmpSeq>20</EmpSeq>
    <RstSeq>294</RstSeq>
    <SMComplate>1000273002</SMComplate>
    <EduTypeSeq>0</EduTypeSeq>
    <IsEI>1</IsEI>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ComplateName>�̼���</ComplateName>
    <ComplateTime>5.00000</ComplateTime>
    <DeptName>����2��</DeptName>
    <EduBegDate>20141112</EduBegDate>
    <EduCourseName>�����������Ŵ�����</EduCourseName>
    <EduEndDate>20141112</EduEndDate>
    <EI>������</EI>
    <EmpID>20000201</EmpID>
    <Remark>test</Remark>
    <ReturnAmt>0.00000</ReturnAmt>
    <DeptSeq>19</DeptSeq>
    <EduCourseSeq>35</EduCourseSeq>
    <EmpSeq>21</EmpSeq>
    <RstSeq>295</RstSeq>
    <SMComplate>1000273002</SMComplate>
    <EduTypeSeq>0</EduTypeSeq>
    <IsEI>0</IsEI>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ComplateName>����</ComplateName>
    <ComplateTime>1.00000</ComplateTime>
    <DeptName>���������</DeptName>
    <EduBegDate>20141112</EduBegDate>
    <EduCourseName>����ä�ǰ����ǹ�</EduCourseName>
    <EduEndDate>20141112</EduEndDate>
    <EI>������</EI>
    <EmpID>20000202</EmpID>
    <Remark>test</Remark>
    <ReturnAmt>0.00000</ReturnAmt>
    <DeptSeq>53</DeptSeq>
    <EduCourseSeq>36</EduCourseSeq>
    <EmpSeq>22</EmpSeq>
    <RstSeq>296</RstSeq>
    <SMComplate>1000273001</SMComplate>
    <EduTypeSeq>0</EduTypeSeq>
    <IsEI>0</IsEI>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ComplateName>�̼���</ComplateName>
    <ComplateTime>3.00000</ComplateTime>
    <DeptName>����4��</DeptName>
    <EduBegDate>20141112</EduBegDate>
    <EduCourseName>����ä�ǰ�������</EduCourseName>
    <EduEndDate>20141112</EduEndDate>
    <EI>����</EI>
    <EmpID>20000801</EmpID>
    <Remark>test</Remark>
    <ReturnAmt>0.00000</ReturnAmt>
    <DeptSeq>24</DeptSeq>
    <EduCourseSeq>29</EduCourseSeq>
    <EmpSeq>25</EmpSeq>
    <RstSeq>297</RstSeq>
    <SMComplate>1000273002</SMComplate>
    <EduTypeSeq>0</EduTypeSeq>
    <IsEI>1</IsEI>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ComplateName>�̼���</ComplateName>
    <ComplateTime>21.00000</ComplateTime>
    <DeptName>���������</DeptName>
    <EduBegDate>20141112</EduBegDate>
    <EduCourseName>�����ذ�� �ǻ����</EduCourseName>
    <EduEndDate>20141112</EduEndDate>
    <EI>������</EI>
    <EmpID>20001101</EmpID>
    <Remark>test</Remark>
    <ReturnAmt>0.00000</ReturnAmt>
    <DeptSeq>23</DeptSeq>
    <EduCourseSeq>43</EduCourseSeq>
    <EmpSeq>27</EmpSeq>
    <RstSeq>298</RstSeq>
    <SMComplate>1000273002</SMComplate>
    <EduTypeSeq>0</EduTypeSeq>
    <IsEI>0</IsEI>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ComplateName>����</ComplateName>
    <ComplateTime>5.00000</ComplateTime>
    <DeptName>�ַ�ǿ���1��(test)</DeptName>
    <EduBegDate>20141112</EduBegDate>
    <EduCourseName>���� �缺�� ����_AB</EduCourseName>
    <EduEndDate>20141112</EduEndDate>
    <EI>����</EI>
    <EmpID>20001102</EmpID>
    <Remark>test</Remark>
    <ReturnAmt>1112.00000</ReturnAmt>
    <DeptSeq>6</DeptSeq>
    <EduCourseSeq>57</EduCourseSeq>
    <EmpSeq>28</EmpSeq>
    <RstSeq>299</RstSeq>
    <SMComplate>1000273001</SMComplate>
    <EduTypeSeq>15</EduTypeSeq>
    <IsEI>1</IsEI>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ComplateName>�̼���</ComplateName>
    <ComplateTime>2.00000</ComplateTime>
    <DeptName>����2��</DeptName>
    <EduBegDate>20141112</EduBegDate>
    <EduCourseName>���μ� �Ű�ǹ�</EduCourseName>
    <EduEndDate>20141112</EduEndDate>
    <EI>������</EI>
    <EmpID>20010201</EmpID>
    <Remark>test</Remark>
    <ReturnAmt>35153.00000</ReturnAmt>
    <DeptSeq>19</DeptSeq>
    <EduCourseSeq>20</EduCourseSeq>
    <EmpSeq>29</EmpSeq>
    <RstSeq>300</RstSeq>
    <SMComplate>1000273002</SMComplate>
    <EduTypeSeq>0</EduTypeSeq>
    <IsEI>0</IsEI>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ComplateName>����</ComplateName>
    <ComplateTime>3.00000</ComplateTime>
    <DeptName>����2��</DeptName>
    <EduBegDate>20141112</EduBegDate>
    <EduCourseName>����Ͻ���������</EduCourseName>
    <EduEndDate>20141112</EduEndDate>
    <EI>����</EI>
    <EmpID>20010202</EmpID>
    <Remark>test</Remark>
    <ReturnAmt>513.00000</ReturnAmt>
    <DeptSeq>19</DeptSeq>
    <EduCourseSeq>34</EduCourseSeq>
    <EmpSeq>30</EmpSeq>
    <RstSeq>301</RstSeq>
    <SMComplate>1000273001</SMComplate>
    <EduTypeSeq>0</EduTypeSeq>
    <IsEI>1</IsEI>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ComplateName>�̼���</ComplateName>
    <ComplateTime>210.00000</ComplateTime>
    <DeptName>��������1��</DeptName>
    <EduBegDate>20141112</EduBegDate>
    <EduCourseName>����������ǹ�</EduCourseName>
    <EduEndDate>20141112</EduEndDate>
    <EI>������</EI>
    <EmpID>20010401</EmpID>
    <Remark>test</Remark>
    <ReturnAmt>213.00000</ReturnAmt>
    <DeptSeq>45</DeptSeq>
    <EduCourseSeq>21</EduCourseSeq>
    <EmpSeq>33</EmpSeq>
    <RstSeq>302</RstSeq>
    <SMComplate>1000273002</SMComplate>
    <EduTypeSeq>0</EduTypeSeq>
    <IsEI>0</IsEI>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <ComplateName>����</ComplateName>
    <ComplateTime>513.00000</ComplateTime>
    <DeptName>���������</DeptName>
    <EduBegDate>20141112</EduBegDate>
    <EduCourseName>���� �缺�� ����_AB</EduCourseName>
    <EduEndDate>20141112</EduEndDate>
    <EI>����</EI>
    <EmpID>20010502</EmpID>
    <Remark>test</Remark>
    <ReturnAmt>0.00000</ReturnAmt>
    <DeptSeq>53</DeptSeq>
    <EduCourseSeq>56</EduCourseSeq>
    <EmpSeq>35</EmpSeq>
    <RstSeq>303</RstSeq>
    <SMComplate>1000273001</SMComplate>
    <EduTypeSeq>21</EduTypeSeq>
    <IsEI>1</IsEI>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ComplateName>�̼���</ComplateName>
    <ComplateTime>21.00000</ComplateTime>
    <DeptName>����1��(�Ȼ�_2)</DeptName>
    <EduBegDate>20141112</EduBegDate>
    <EduCourseName>�����ȹ �� �����ǹ�</EduCourseName>
    <EduEndDate>20141112</EduEndDate>
    <EI>������</EI>
    <EmpID>20010503</EmpID>
    <Remark>test</Remark>
    <ReturnAmt>0.00000</ReturnAmt>
    <DeptSeq>62</DeptSeq>
    <EduCourseSeq>37</EduCourseSeq>
    <EmpSeq>36</EmpSeq>
    <RstSeq>304</RstSeq>
    <SMComplate>1000273002</SMComplate>
    <EduTypeSeq>0</EduTypeSeq>
    <IsEI>0</IsEI>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ComplateName>�̼���</ComplateName>
    <ComplateTime>51.00000</ComplateTime>
    <DeptName>������</DeptName>
    <EduBegDate>20141112</EduBegDate>
    <EduCourseName>��������� ���ؿ� ��������</EduCourseName>
    <EduEndDate>20141112</EduEndDate>
    <EI>����</EI>
    <EmpID>20010802</EmpID>
    <Remark>test11</Remark>
    <ReturnAmt>0.00000</ReturnAmt>
    <DeptSeq>14</DeptSeq>
    <EduCourseSeq>32</EduCourseSeq>
    <EmpSeq>38</EmpSeq>
    <RstSeq>305</RstSeq>
    <SMComplate>1000273002</SMComplate>
    <EduTypeSeq>0</EduTypeSeq>
    <IsEI>1</IsEI>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>13</IDX_NO>
    <DataSeq>13</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ComplateName>����</ComplateName>
    <ComplateTime>321.00000</ComplateTime>
    <DeptName>����1��</DeptName>
    <EduBegDate>20141112</EduBegDate>
    <EduCourseName>�����׽�Ʈ</EduCourseName>
    <EduEndDate>20141112</EduEndDate>
    <EI>������</EI>
    <EmpID>20010901</EmpID>
    <Remark />
    <ReturnAmt>0.00000</ReturnAmt>
    <DeptSeq>18</DeptSeq>
    <EduCourseSeq>49</EduCourseSeq>
    <EmpSeq>39</EmpSeq>
    <RstSeq>306</RstSeq>
    <SMComplate>1000273001</SMComplate>
    <EduTypeSeq>0</EduTypeSeq>
    <IsEI>0</IsEI>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>14</IDX_NO>
    <DataSeq>14</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ComplateName>�̼���</ComplateName>
    <ComplateTime>321.00000</ComplateTime>
    <DeptName>����5��</DeptName>
    <EduBegDate>20141112</EduBegDate>
    <EduCourseName>�������(TPM)����</EduCourseName>
    <EduEndDate>20141112</EduEndDate>
    <EI>������</EI>
    <EmpID>20010902</EmpID>
    <Remark />
    <ReturnAmt>0.00000</ReturnAmt>
    <DeptSeq>34</DeptSeq>
    <EduCourseSeq>31</EduCourseSeq>
    <EmpSeq>40</EmpSeq>
    <RstSeq>307</RstSeq>
    <SMComplate>1000273002</SMComplate>
    <EduTypeSeq>0</EduTypeSeq>
    <IsEI>0</IsEI>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025970,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021807
rollback 