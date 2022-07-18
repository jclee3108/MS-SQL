
IF OBJECT_ID('KPX_SHRWelmediAccCCtrCheck') IS NOT NULL
    DROP PROC KPX_SHRWelmediAccCCtrCheck
GO 

-- v2014.12.08 

-- �Ƿ��������(Ȱ������)-üũ by����õ
 CREATE PROCEDURE KPX_SHRWelmediAccCCtrCheck  
     @xmlDocument NVARCHAR(MAX)   ,    -- ȭ���� ������ XML�� ����  
     @xmlFlags    INT = 0         ,    -- �ش� XML�� Type  
     @ServiceSeq  INT = 0         ,    -- ���� ��ȣ  
     @WorkingTag  NVARCHAR(10)= '',    -- WorkingTag  
     @CompanySeq  INT = 1         ,    -- ȸ�� ��ȣ  
     @LanguageSeq INT = 1         ,    -- ��� ��ȣ  
     @UserSeq     INT = 0         ,    -- ����� ��ȣ  
     @PgmSeq      INT = 0              -- ���α׷� ��ȣ  
 AS  
    
    -- ����� ������ �����Ѵ�.  
    DECLARE @MessageType  INT,  
            @Status       INT,  
            @Results      NVARCHAR(250)
    
    -- ���� ������ ��� ����  
    CREATE TABLE #KPX_THRWelmediAccCCtr (WorkingTag NCHAR(1) NULL)    -- ����� �ӽ����̺��� �����Ѵ�.  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THRWelmediAccCCtr'  
    IF @@ERROR <> 0 RETURN    -- ������ �߻��ϸ� ����  
    
    SELECT * FROM #KPX_THRWelmediAccCCtr 
    
    RETURN