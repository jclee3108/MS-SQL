      
IF OBJECT_ID('DTI_SESMDEmpCCtrRatioCheck') IS NOT NULL   
    DROP PROC DTI_SESMDEmpCCtrRatioCheck  
GO  
    
-- v2013.06.26 
  
-- ����� Ȱ������ ����� ���(Ȯ��)_DTI by ����õ 
CREATE PROC DTI_SESMDEmpCCtrRatioCheck  
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
  					
    CREATE TABLE #DTI_TESMDEmpCCtrRatio (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TESMDEmpCCtrRatio'
    IF @@ERROR <> 0 RETURN	
    
    --����������üũ: UPDATE, DELETE�� ������ �������� ������ ����ó�� 
     
    IF @WorkingTag <> 'Delete'
    AND NOT EXISTS ( SELECT 1   
                      FROM #DTI_TESMDEmpCCtrRatio AS A   
                      JOIN DTI_TESMDEmpCCtrRatio  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.CostYM = B.CostYM AND A.EmpSeqOld = B.EmpSeq AND A.CCtrSeqOld = B.CCtrSeq )  
                     WHERE A.WorkingTag IN ( 'U', 'D' )  
                       AND Status = 0 
                  )  
    BEGIN  
        
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              7                  , -- �ڷᰡ��ϵǾ������ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                              @LanguageSeq               
        
        UPDATE #DTI_TESMDEmpCCtrRatio  
           SET Result       = @Results,  
               MessageType  = @MessageType,  
               Status       = @Status  
         WHERE WorkingTag IN ( 'U', 'D' )  
           AND Status = 0   
    END   
    
    -- üũ��� ��� 
    SELECT A1.CostYM, A1.CCtrSeq, A1.EmpSeq, A1.EmpCnt
      INTO #TEMP_DTI_TESMDEmpCCtrRatio 
      FROM #DTI_TESMDEmpCCtrRatio AS A1  
     WHERE A1.WorkingTag IN ('A', 'U')  
       AND A1.Status = 0  
    
    UNION ALL   
    
    SELECT A1.CostYM, A1.CCtrSeq, A1.EmpSeq, A1.EmpCnt 
      FROM DTI_TESMDEmpCCtrRatio AS A1  
     WHERE A1.CompanySeq = @CompanySeq  
       AND A1.CostYM = (SELECT TOP 1 CostYM FROM #DTI_TESMDEmpCCtrRatio)
       AND NOT EXISTS (SELECT 1 FROM #DTI_TESMDEmpCCtrRatio   
                               WHERE WorkingTag IN ('U','D')   
                                 AND Status = 0   
                                 AND CostYM = A1.CostYM
                                 AND EmpSeqOld = A1.EmpSeq
                                 AND CCtrSeqOld = A1.CCtrSeq
                      )  
    
    -- üũ1, �ҼӺμ��� Ȱ�����Ͱ� �ƴѰ�� ���� �� ���� �� �� �����ϴ�.
    
    UPDATE A    
       SET A.Result       = N'�ҼӺμ��� Ȱ�����Ͱ� �ƴѰ�� ���� �� ���� �� �� �����ϴ�.',    
           A.MessageType  = 1234,    
           A.Status       = 1234    
      FROM #DTI_TESMDEmpCCtrRatio AS A 
     WHERE WorkingTag IN ('A','U')
       AND Status = 0 
       AND NOT EXISTS (SELECT TOP 1 1 FROM _THROrgDeptCCtr WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CCtrSeq = A.CCtrSeq AND DeptSeq = A.DeptSeq )

    -- üũ1, END
    
    -- üũ2, (�������+���+����Ȱ������)�� �ο����� ���� 1�̾�� �մϴ�. 
    
    UPDATE A  
       SET A.Result       = N'(�������,���)�� �ο����� ���� 1�̾�� �մϴ�.',  
           A.MessageType  = 1234,  
           A.Status       = 1234  
      FROM #DTI_TESMDEmpCCtrRatio AS A 
     WHERE A.WorkingTag IN ('A', 'U')
       AND A.Status = 0  
       AND EXISTS (SELECT 1 
                     FROM #TEMP_DTI_TESMDEmpCCtrRatio AS S
                    GROUP BY S.EmpSeq, S.CostYM
                   HAVING SUM(S.EmpCnt) <> 1 
                  )
    
    -- üũ2, END 
    
    -- üũ3, �ο����� 0�� �ƴϸ� ��Ʈ������ ���� �ʵ���
    
    EXEC dbo._SCOMMessage @MessageType OUTPUT, 
						  @Status      OUTPUT, 
						  @Results     OUTPUT, 
						  1167              , -- @1��(��) ������ �� �����ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE MessageDefault like '%����%') 
						  @LanguageSeq       ,  
						  0,'�ο����� 0�� �ƴ� ��' 

	UPDATE #DTI_TESMDEmpCCtrRatio   
       SET Result        = @Results,   
           MessageType   = @MessageType,   
           Status        = @Status 
      FROM #DTI_TESMDEmpCCtrRatio AS A
      JOIN DTI_TESMDEmpCCtrRatio  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeqOld AND B.CCtrSeq = A.CCtrSeqOld AND B.EmpCnt <> 0)
     WHERE A.WorkingTag = 'D'
       AND A.Status = 0 
    
    -- üũ3, END 
    
    -- üũ4, �ߺ����� üũ (�������,���,Ȱ������)
    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
                          @LanguageSeq       ,  
                          0,'',
                          0,''
    
    UPDATE A  
       SET A.Result       = @Results, --REPLACE( @Results, '@2', B.SampleName ), -- Ȥ�� @Results,  
           A.MessageType  = @MessageType,  
           A.Status       = @Status  
      FROM #DTI_TESMDEmpCCtrRatio AS A   
      JOIN (SELECT S.CCtrSeq, S.CostYM, S.EmpSeq  
              FROM #TEMP_DTI_TESMDEmpCCtrRatio AS S  
             GROUP BY S.CCtrSeq, S.CostYM, S.EmpSeq 
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.CostYM = B.CostYM AND A.CCtrSeq = B.CCtrSeq AND A.EmpSeq = B.EmpSeq )   
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    -- üũ4, END 
    
    SELECT * FROM #DTI_TESMDEmpCCtrRatio 
    
    RETURN 
    
GO