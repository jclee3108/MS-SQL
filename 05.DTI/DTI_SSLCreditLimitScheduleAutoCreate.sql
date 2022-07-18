
IF OBJECT_ID('DTI_SSLCreditLimitScheduleAutoCreate') IS NOT NULL 
    DROP PROC DTI_SSLCreditLimitScheduleAutoCreate
GO

-- v2014.04.29 

-- �ڵ������� ��ũ��Ʈ ���� by����õ 
CREATE PROC DTI_SSLCreditLimitScheduleAutoCreate
    @CompanySeq INT = 1 
    
AS     
    
    IF CONVERT(NCHAR(8),GETDATE(),112) = CONVERT(NCHAR(8),DATEADD(DAY,-1,DATEADD(MONTH,1,LEFT(CONVERT(NCHAR(8),GETDATE(),112),6) + '01')),112) -- �ش���� ���Ͽ� ����
    BEGIN
        UPDATE A
           SET IsStop = '1', 
               StopDate = CONVERT(NCHAR(8),GETDATE(),112), 
               StopEmpSeq = 1 
          FROM DTI_TSLCreditLimitReq AS A 
        WHERE A.CompanySeq = @CompanySeq 
          AND A.EndYM = LEFT(CONVERT(NCHAR(6),GETDATE(),112),6) -- ����� = �����(�ý���)
    END
GO
exec DTI_SSLCreditLimitScheduleAutoCreate 