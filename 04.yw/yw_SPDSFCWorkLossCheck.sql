  
IF OBJECT_ID('yw_SPDSFCWorkLossCheck') IS NOT NULL   
    DROP PROC yw_SPDSFCWorkLossCheck  
GO  
  
-- v2013.08.23 
  
-- ���ǰ����Է�(����)_YW(üũ) by����õ   
CREATE PROC yw_SPDSFCWorkLossCheck  
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
      
    CREATE TABLE #YW_TPDSFCWorkLoss( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TPDSFCWorkLoss'   
    IF @@ERROR <> 0 RETURN     
        
    -- üũ1, �������ᰡ ���� ���� �����Ͱ� �����մϴ�.   

     UPDATE #YW_TPDSFCWorkLoss
        SET Result       = '�������ᰡ ���� ���� �����Ͱ� �����մϴ�. ', 
            MessageType  = @MessageType, 
            Status       = 465131 
      FROM #YW_TPDSFCWorkLoss AS A
      JOIN YW_TPDSFCWorkLoss AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkCenterSeq = A.WorkCenterSeq AND B.WorkDate = A.WorkDate AND B.EndTime = '' ) 
     WHERE A.WorkingTag = 'A'
       AND A.Status = 0 
    
    -- üũ1, END
    
    -- üũ2, �����͸� 2�� �̻� ���� �� �� �����ϴ�.
    
     IF ( SELECT COUNT (1) FROM #YW_TPDSFCWorkLoss WHERE WorkingTag = 'A' AND Status = 0 ) > 1
     BEGIN 
         UPDATE #YW_TPDSFCWorkLoss
            SET Result       = '�����͸� 2�� �̻� ���� �� �� �����ϴ�.', 
                MessageType  = @MessageType, 
                Status       = 454578 
    END
     
    -- üũ2, END

    -- üũ3, ���������� �Է� �� �ķδ� ���ǰ����� ���� �� �� �����ϴ�.
    
    UPDATE #YW_TPDSFCWorkLoss 
       SET Result       = '�����͸� ���� �� �� �����ϴ�.', 
           MessageType  = @MessageType, 
           Status       = 51513 
      FROM #YW_TPDSFCWorkLoss AS A 
     WHERE WorkingTag = 'U' 
       AND Status = 0 
    
    -- üũ3, END
    
    -- üũ4, ���������� ���� �ʾҽ��ϴ�. 
    
    IF @WorkingTag = 'EndTime' 
    BEGIN 
        UPDATE #YW_TPDSFCWorkLoss 
           SET Result       = '���������� ���� �ʾҽ��ϴ�.', 
               MessageType  = @MessageType, 
               Status       = 324523423 
          FROM #YW_TPDSFCWorkLoss AS A 
         WHERE WorkingTag = 'A' 
           AND Status = 0 
           AND A.StartTime = '' 
    END 
    
    -- üũ4, END 
    
    -- Serl ä��
    
    DECLARE @MaxSerl INT
    SELECT @MaxSerl = ISNULL(MAX(B.Serl),0)
      FROM #YW_TPDSFCWorkLoss AS A
      LEFT OUTER JOIN YW_TPDSFCWorkLoss AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkCenterSeq = A.WorkCenterSeq ) 
     GROUP BY A.WorkCenterSeq
    
    UPDATE A
       SET A.Serl = @MaxSerl + A.DataSeq
      FROM #YW_TPDSFCWorkLoss AS A 
     WHERE A.WorkingTag = 'A'
       AND A.Status = 0
    
    -- Serl ä��, END
    
    SELECT * FROM #YW_TPDSFCWorkLoss   
      
    RETURN  
      
GO
exec yw_SPDSFCWorkLossCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>���ǻ���1</UMLossName>
    <UMLossSeq>1008429001</UMLossSeq>
    <StartTime>2013-08-23 09:00</StartTime>
    <EndTime>2013-08-23 10:50</EndTime>
    <LossTime>7800</LossTime>
    <Remark />
    <Serl>1</Serl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>���ǻ���2</UMLossName>
    <UMLossSeq>1008429002</UMLossSeq>
    <StartTime>2013-08-23 10:00</StartTime>
    <EndTime>2013-08-23 12:00</EndTime>
    <LossTime>6600</LossTime>
    <Remark />
    <Serl>2</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>���ǻ���3</UMLossName>
    <UMLossSeq>1008429003</UMLossSeq>
    <StartTime>2013-08-23 10:20</StartTime>
    <EndTime>2013-08-23 11:40</EndTime>
    <LossTime>4200</LossTime>
    <Remark />
    <Serl>3</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>���ǻ���4</UMLossName>
    <UMLossSeq>1008429004</UMLossSeq>
    <StartTime>2013-08-23 10:31</StartTime>
    <EndTime>2013-08-23 11:40</EndTime>
    <LossTime>6420</LossTime>
    <Remark />
    <Serl>4</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>���ǻ���1</UMLossName>
    <UMLossSeq>1008429001</UMLossSeq>
    <StartTime>2013-08-23 10:48</StartTime>
    <EndTime>2013-08-23 10:48</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <Serl>5</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>���ǻ���5</UMLossName>
    <UMLossSeq>1008429005</UMLossSeq>
    <StartTime>2013-08-23 10:49</StartTime>
    <EndTime>2013-08-23 10:49</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <Serl>6</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>���ǻ���3</UMLossName>
    <UMLossSeq>1008429003</UMLossSeq>
    <StartTime>2013-08-23 11:14</StartTime>
    <EndTime>2013-08-23 11:14</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <Serl>7</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>���ǻ���1</UMLossName>
    <UMLossSeq>1008429001</UMLossSeq>
    <StartTime>2013-08-23 11:14</StartTime>
    <EndTime>2013-08-23 11:14</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <Serl>8</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>���ǻ���5</UMLossName>
    <UMLossSeq>1008429005</UMLossSeq>
    <StartTime>2013-08-23 11:17</StartTime>
    <EndTime>2013-08-23 11:18</EndTime>
    <LossTime>180</LossTime>
    <Remark />
    <Serl>9</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>���ǻ���3</UMLossName>
    <UMLossSeq>1008429003</UMLossSeq>
    <StartTime>2013-08-23 11:19</StartTime>
    <EndTime>2013-08-23 11:22</EndTime>
    <LossTime>540</LossTime>
    <Remark />
    <Serl>10</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>���ǻ���1</UMLossName>
    <UMLossSeq>1008429001</UMLossSeq>
    <StartTime>2013-08-23 11:23</StartTime>
    <EndTime>2013-08-23 11:23</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <Serl>11</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>���ǻ���4</UMLossName>
    <UMLossSeq>1008429004</UMLossSeq>
    <StartTime>2013-08-23 11:40</StartTime>
    <EndTime>2013-08-23 11:40</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <Serl>12</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017273,@WorkingTag=N'EndTime',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014775