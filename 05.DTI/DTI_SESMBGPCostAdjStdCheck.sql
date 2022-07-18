
IF OBJECT_ID('DTI_SESMBGPCostAdjStdCheck') IS NOT NULL 
    DROP PROC DTI_SESMBGPCostAdjStdCheck 
GO

-- v2014.01.03 

-- ���ͺм� ������� ���ص��_DTI(üũ) by����õ
CREATE PROC DTI_SESMBGPCostAdjStdCheck
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS   
    
    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250)
    
    CREATE TABLE #DTI_TESMBGPCostAdjStd (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TESMBGPCostAdjStd'
      
    UPDATE A  
       SET Result       = N'�ߺ� �� �����Ͱ� �ԷµǾ����ϴ�.', 
           MessageType  = 1234,  
           Status       = 1234  
      FROM #DTI_TESMBGPCostAdjStd AS A   
      JOIN (SELECT S.CostYM, S.CCtrSeq, S.SMAccType 
              FROM (SELECT A1.CostYM, A1.CCtrSeq, A1.SMAccType
                      FROM #DTI_TESMBGPCostAdjStd AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.CostYm, A1.CCtrSeq, A1.SMAccType  
                      FROM DTI_TESMBGPCostAdjStd AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #DTI_TESMBGPCostAdjStd   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND CostYM = A1.CostYM 
                                                 AND CCtrSeq = A1.CCtrSeq 
                                                 AND SMAccType = A1.SMAccType
                                      )  
                   ) AS S  
             GROUP BY S.CostYM, S.CCtrSeq, S.SMAccType  
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.CostYM = B.CostYM AND A.CCtrSeq = B.CCtrSeq AND A.SMAccType = B.SMAccType )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  

    
    SELECT * FROM #DTI_TESMBGPCostAdjStd 
    
    RETURN    
GO
