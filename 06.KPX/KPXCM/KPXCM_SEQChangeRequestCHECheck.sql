
IF OBJECT_ID('KPXCM_SEQChangeRequestCHECheck') IS NOT NULL 
    DROP PROC KPXCM_SEQChangeRequestCHECheck
GO 

-- v2015.06.10 

-- ������-üũ by����õ 
CREATE PROC dbo.KPXCM_SEQChangeRequestCHECheck  
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT     = 0,    
    @ServiceSeq     INT     = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT     = 1,    
    @LanguageSeq    INT     = 1,    
    @UserSeq        INT     = 0,    
    @PgmSeq         INT     = 0    
AS  

    DECLARE @docHandle      INT,  
            @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250),  
            @Seq            INT,  
            @Count          INT,  
            @MaxSeq         INT  
    
    CREATE TABLE #KPXCM_TEQChangeRequestCHE (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQChangeRequestCHE'  
    IF @@ERROR <> 0 RETURN    
    
    
    -- üũ1, ���� �� �����ʹ� ����/���� �� �� �����ϴ�.   
    UPDATE A   
       SET Result = '���� �� �����ʹ� ����/���� �� �� �����ϴ�.',   
           Status = 1234,   
           MessageType = 1234   
      FROM #KPXCM_TEQChangeRequestCHE AS A   
     WHERE A.WorkingTag IN ( 'U', 'D' )   
       AND A.Status = 0   
       AND EXISTS (SELECT 1 FROM KPXCM_TEQChangeRequestRecv WHERE CompanySeq = @CompanySeq AND ChangeRequestSeq = A.ChangeRequestSeq )   
    -- üũ1, END   
    

    
    --��û��ȣ����  
    DECLARE @BaseDate           NCHAR(8), 
            @ChangeRequestNo    NVARCHAR(100),   
            @UMPlantType        INT,  
            @UMPlantTypeName    NVARCHAR(100),  
            @ChangeRequestSeq   INT 
    
    SELECT @Count = Count(1) FROM #KPXCM_TEQChangeRequestCHE WHERE WorkingTag = 'A'  
    
    IF @Count > 0  
    BEGIN  
        
        EXEC @ChangeRequestSeq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TEQChangeRequestCHE', 'ChangeRequestSeq', @Count  
        
        UPDATE A   
          SET ChangeRequestSeq  = @ChangeRequestSeq + DataSeq  
         FROM #KPXCM_TEQChangeRequestCHE AS A    
        WHERE WorkingTag = 'A'  
          AND Status     = 0  
        
        SELECT @BaseDate = A.BaseDate,  
               @UMPlantType = A.UMPlantType,   
               @UMPlantTypeName = B.Remark 
          FROM #KPXCM_TEQChangeRequestCHE AS A  
          LEFT OUTER JOIN _TDAUMinor AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMPlantType )  
         WHERE A.WorkingTag = 'A'  
           AND A.Status = 0  
        
        EXEC _SCOMCreateNo 'SITE', 'KPXCM_TEQChangeRequestCHE', @CompanySeq, @UMPlantType, @BaseDate, @ChangeRequestNo OUTPUT    
        
        UPDATE #KPXCM_TEQChangeRequestCHE    
           SET ChangeRequestNo  = REPLACE(@ChangeRequestNo, 'CR--', 'CR-'+ISNULL(@UMPlantTypeName,'')+'-'  )  
         WHERE WorkingTag = 'A'    
           AND Status = 0    
          
        -- �Ϸù�ȣ�� �⵵��, Plant ���к� �� ä���ǵ��� �߰�   
        DECLARE @MaxNo NVARCHAR(20)   
          
        SELECT @MaxNo = ISNULL(RIGHT('000' + CONVERT(NVARCHAR(5),MAX(CONVERT(INT,RIGHT(A.ChangeRequestNo,3))) + 1),3 ),'001')  
          FROM KPXCM_TEQChangeRequestCHE AS A   
         WHERE CompanySeq = 1   
           AND LEFT(ChangeRequestNo,8) = ( SELECT TOP 1 LEFT(ChangeRequestNo,8) From #KPXCM_TEQChangeRequestCHE )   
          
        UPDATE A  
           SET ChangeRequestNo = LEFT(A.ChangeRequestNo,8) + @MaxNo  
          FROM #KPXCM_TEQChangeRequestCHE AS A   
         WHERE WorkingTag = 'A'      
           AND Status = 0      
        -- �Ϸù�ȣ�� �⵵��, Plant ���к� �� ä���ǵ��� �߰�, END   
    END   
    
    SELECT * FROM #KPXCM_TEQChangeRequestCHE  
    
RETURN  
go 
begin tran

exec KPXCM_SEQChangeRequestCHECheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ChangeRequestSeq>0</ChangeRequestSeq>
    <ChangeRequestNo />
    <BaseDate>20150610</BaseDate>
    <DeptSeq>1300</DeptSeq>
    <DeptName>���������2</DeptName>
    <EmpSeq>2028</EmpSeq>
    <EmpName>����õ</EmpName>
    <Title>��������</Title>
    <UMChangeType>20139001</UMChangeType>
    <UMChangeTypeName>���󺯰�</UMChangeTypeName>
    <UMChangeReson1>20140001</UMChangeReson1>
    <UMChangeResonName1>���������</UMChangeResonName1>
    <UMPlantType>1010356001</UMPlantType>
    <UMPlantTypeName>DMC</UMPlantTypeName>
    <Purpose />
    <Effect>��������������</Effect>
    <Remark>������������</Remark>
    <UMChangeReson2>20140001</UMChangeReson2>
    <UMChangeResonName2>���������</UMChangeResonName2>
    <IsPID>0</IsPID>
    <IsPFD>1</IsPFD>
    <IsLayOut>0</IsLayOut>
    <IsProposal>0</IsProposal>
    <IsMinutes>0</IsMinutes>
    <IsReview>1</IsReview>
    <IsOpinion>0</IsOpinion>
    <IsDange>1</IsDange>
    <Etc />
    <IsReport>1</IsReport>
    <FileSeq>0</FileSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030192,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025199

rollback 