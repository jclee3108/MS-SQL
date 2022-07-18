  
IF OBJECT_ID('KPX_SHREduRstUploadQuery') IS NOT NULL   
    DROP PROC KPX_SHREduRstUploadQuery  
GO  
  
-- v2014.11.19  
  
-- �������Upload-��ȸ by ����õ   
CREATE PROC KPX_SHREduRstUploadQuery  
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
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#THREduPersRst'         
    IF @@ERROR <> 0 RETURN     

    SELECT REPLACE(EduBegDate,'-','') AS EduBegDate, 
           REPLACE(EduEndDate,'-','') AS EduEndDate, 
           *
      FROM #THREduPersRst AS A 
    
    RETURN  
    
GO 
exec KPX_SHREduRstUploadQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <No>1</No>
    <EmpName>��±�         </EmpName>
    <DeptName>����������</DeptName>
    <EduCourseName>�����ð��� ����</EduCourseName>
    <EduBegDate>2014-11-12</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>����</EI>
    <ComplateTime>9</ComplateTime>
    <ProgRate>100</ProgRate>
    <ProgPoint>0</ProgPoint>
    <HWPoint>0</HWPoint>
    <TestPoint>0</TestPoint>
    <MeetPoint>0</MeetPoint>
    <ComplatePoint>0</ComplatePoint>
    <ComplateName>�̼���</ComplateName>
    <ComplateStdPoint>50</ComplateStdPoint>
    <EduAmt>10000</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>2</No>
    <EmpName>���ö</EmpName>
    <DeptName>����2��</DeptName>
    <EduCourseName>�����������Ŵ�����</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>������</EI>
    <ComplateTime>5</ComplateTime>
    <ProgRate>71</ProgRate>
    <ProgPoint>1</ProgPoint>
    <HWPoint>1</HWPoint>
    <TestPoint>1</TestPoint>
    <MeetPoint>1</MeetPoint>
    <ComplatePoint>1</ComplatePoint>
    <ComplateName>�̼���</ComplateName>
    <ComplateStdPoint>51</ComplateStdPoint>
    <EduAmt>10001</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>3</No>
    <EmpName>������         </EmpName>
    <DeptName>���������</DeptName>
    <EduCourseName>����ä�ǰ����ǹ�</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>������</EI>
    <ComplateTime>1</ComplateTime>
    <ProgRate>56.25</ProgRate>
    <ProgPoint>2</ProgPoint>
    <HWPoint>2</HWPoint>
    <TestPoint>2</TestPoint>
    <MeetPoint>2</MeetPoint>
    <ComplatePoint>2</ComplatePoint>
    <ComplateName>����</ComplateName>
    <ComplateStdPoint>52</ComplateStdPoint>
    <EduAmt>10002</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>4</No>
    <EmpName>������</EmpName>
    <DeptName>����4��</DeptName>
    <EduCourseName>����ä�ǰ�������</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>����</EI>
    <ComplateTime>3</ComplateTime>
    <ProgRate>30</ProgRate>
    <ProgPoint>3</ProgPoint>
    <HWPoint>3</HWPoint>
    <TestPoint>3</TestPoint>
    <MeetPoint>3</MeetPoint>
    <ComplatePoint>3</ComplatePoint>
    <ComplateName>�̼���</ComplateName>
    <ComplateStdPoint>53</ComplateStdPoint>
    <EduAmt>10003</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>5</No>
    <EmpName>����           </EmpName>
    <DeptName>���������</DeptName>
    <EduCourseName>�����ذ�� �ǻ����</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>������</EI>
    <ComplateTime>21</ComplateTime>
    <ProgRate>50</ProgRate>
    <ProgPoint>4</ProgPoint>
    <HWPoint>4</HWPoint>
    <TestPoint>4</TestPoint>
    <MeetPoint>4</MeetPoint>
    <ComplatePoint>4</ComplatePoint>
    <ComplateName>�̼���</ComplateName>
    <ComplateStdPoint>54</ComplateStdPoint>
    <EduAmt>10004</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>6</No>
    <EmpName>Kimyoungmi</EmpName>
    <DeptName>�ַ�ǿ���1��(test)</DeptName>
    <EduCourseName>���� �缺�� ����_AB</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>����</EI>
    <ComplateTime>5</ComplateTime>
    <ProgRate>10</ProgRate>
    <ProgPoint>5</ProgPoint>
    <HWPoint>5</HWPoint>
    <TestPoint>5</TestPoint>
    <MeetPoint>5</MeetPoint>
    <ComplatePoint>5</ComplatePoint>
    <ComplateName>����</ComplateName>
    <ComplateStdPoint>55</ComplateStdPoint>
    <EduAmt>10005</EduAmt>
    <ReturnAmt>1112</ReturnAmt>
    <FrtReturnAmt>1112</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>7</No>
    <EmpName>�̰��         </EmpName>
    <DeptName>����2��</DeptName>
    <EduCourseName>���μ� �Ű�ǹ�</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>������</EI>
    <ComplateTime>2</ComplateTime>
    <ProgRate>10.5</ProgRate>
    <ProgPoint>6</ProgPoint>
    <HWPoint>6</HWPoint>
    <TestPoint>6</TestPoint>
    <MeetPoint>6</MeetPoint>
    <ComplatePoint>6</ComplatePoint>
    <ComplateName>�̼���</ComplateName>
    <ComplateStdPoint>56</ComplateStdPoint>
    <EduAmt>10006</EduAmt>
    <ReturnAmt>35153</ReturnAmt>
    <FrtReturnAmt>35153</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>8</No>
    <EmpName>�����         </EmpName>
    <DeptName>����2��</DeptName>
    <EduCourseName>����Ͻ���������</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>����</EI>
    <ComplateTime>3</ComplateTime>
    <ProgRate>93.91</ProgRate>
    <ProgPoint>7</ProgPoint>
    <HWPoint>7</HWPoint>
    <TestPoint>7</TestPoint>
    <MeetPoint>7</MeetPoint>
    <ComplatePoint>7</ComplatePoint>
    <ComplateName>����</ComplateName>
    <ComplateStdPoint>57</ComplateStdPoint>
    <EduAmt>10007</EduAmt>
    <ReturnAmt>513</ReturnAmt>
    <FrtReturnAmt>513</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>9</No>
    <EmpName>õ�翵         </EmpName>
    <DeptName>��������1��</DeptName>
    <EduCourseName>����������ǹ�</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>������</EI>
    <ComplateTime>210</ComplateTime>
    <ProgRate>100</ProgRate>
    <ProgPoint>8</ProgPoint>
    <HWPoint>8</HWPoint>
    <TestPoint>8</TestPoint>
    <MeetPoint>8</MeetPoint>
    <ComplatePoint>8</ComplatePoint>
    <ComplateName>�̼���</ComplateName>
    <ComplateStdPoint>58</ComplateStdPoint>
    <EduAmt>10008</EduAmt>
    <ReturnAmt>213</ReturnAmt>
    <FrtReturnAmt>213</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>10</No>
    <EmpName>����ȯ         </EmpName>
    <DeptName>���������</DeptName>
    <EduCourseName>���� �缺�� ����_AB</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>����</EI>
    <ComplateTime>513</ComplateTime>
    <ProgRate>75</ProgRate>
    <ProgPoint>9</ProgPoint>
    <HWPoint>9</HWPoint>
    <TestPoint>9</TestPoint>
    <MeetPoint>9</MeetPoint>
    <ComplatePoint>9</ComplatePoint>
    <ComplateName>����</ComplateName>
    <ComplateStdPoint>59</ComplateStdPoint>
    <EduAmt>10009</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>11</No>
    <EmpName>�ڰ�ȿ         </EmpName>
    <DeptName>����1��(�Ȼ�_2)</DeptName>
    <EduCourseName>�����ȹ �� �����ǹ�</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>������</EI>
    <ComplateTime>21</ComplateTime>
    <ProgRate>90</ProgRate>
    <ProgPoint>10</ProgPoint>
    <HWPoint>10</HWPoint>
    <TestPoint>10</TestPoint>
    <MeetPoint>10</MeetPoint>
    <ComplatePoint>10</ComplatePoint>
    <ComplateName>�̼���</ComplateName>
    <ComplateStdPoint>60</ComplateStdPoint>
    <EduAmt>10010</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>12</No>
    <EmpName>���μ�         </EmpName>
    <DeptName>������</DeptName>
    <EduCourseName>��������� ���ؿ� ��������</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>����</EI>
    <ComplateTime>51</ComplateTime>
    <ProgRate>83.15</ProgRate>
    <ProgPoint>11</ProgPoint>
    <HWPoint>11</HWPoint>
    <TestPoint>11</TestPoint>
    <MeetPoint>11</MeetPoint>
    <ComplatePoint>11</ComplatePoint>
    <ComplateName>�̼���</ComplateName>
    <ComplateStdPoint>61</ComplateStdPoint>
    <EduAmt>10011</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
    <Remark>test11</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>13</No>
    <EmpName>������         </EmpName>
    <DeptName>����1��</DeptName>
    <EduCourseName>�����׽�Ʈ</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>������</EI>
    <ComplateTime>321</ComplateTime>
    <ProgRate>80.23</ProgRate>
    <ProgPoint>12</ProgPoint>
    <HWPoint>12</HWPoint>
    <TestPoint>12</TestPoint>
    <MeetPoint>12</MeetPoint>
    <ComplatePoint>12</ComplatePoint>
    <ComplateName>����</ComplateName>
    <ComplateStdPoint>62</ComplateStdPoint>
    <EduAmt>10012</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
  </DataBlock1>
  <DataBlock1>
    <No>14</No>
    <EmpName>���±�         </EmpName>
    <DeptName>����5��</DeptName>
    <EduCourseName>�������(TPM)����</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>������</EI>
    <ComplateTime>321</ComplateTime>
    <ProgRate>91</ProgRate>
    <ProgPoint>13</ProgPoint>
    <HWPoint>13</HWPoint>
    <TestPoint>13</TestPoint>
    <MeetPoint>13</MeetPoint>
    <ComplatePoint>13</ComplatePoint>
    <ComplateName>�̼���</ComplateName>
    <ComplateStdPoint>63</ComplateStdPoint>
    <EduAmt>10013</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
  </DataBlock1>
  <DataBlock1>
    <No>15</No>
    <EmpName>����ȣ         </EmpName>
    <DeptName>����4��</DeptName>
    <EduCourseName>�������(TPM)����</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>����</EI>
    <ComplateTime>21</ComplateTime>
    <ProgRate>0</ProgRate>
    <ProgPoint>14</ProgPoint>
    <HWPoint>14</HWPoint>
    <TestPoint>14</TestPoint>
    <MeetPoint>14</MeetPoint>
    <ComplatePoint>14</ComplatePoint>
    <ComplateName>����</ComplateName>
    <ComplateStdPoint>64</ComplateStdPoint>
    <EduAmt>10014</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025970,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021807