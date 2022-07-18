  
IF OBJECT_ID('KPX_SPRBasWelFareCodeCreateCheck') IS NOT NULL   
    DROP PROC KPX_SPRBasWelFareCodeCreateCheck  
GO  
  
-- v2014.12.01  
  
-- �����Ļ��ڵ���-�Ⱓ���� üũ by ����õ   
CREATE PROC KPX_SPRBasWelFareCodeCreateCheck  
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
    
    CREATE TABLE #KPX_THRWelCodeYearItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_THRWelCodeYearItem'   
    IF @@ERROR <> 0 RETURN     
    
    -- üũ 1, ���� ��Ʈ�� ���� �� �ֽñ� �ٶ��ϴ�.
    UPDATE A
       SET Result = '���� ��Ʈ�� ���� �� �ֽñ� �ٶ��ϴ�.', 
           MessageType = 1234, 
           Status = 1234 
           
      FROM #KPX_THRWelCodeYearItem AS A 
     WHERE A.Status = 0 
       AND (A.SMRegType = 0 OR A.SubWelCodeSeq = 0 OR A.SubWelCodeName = '')
    -- üũ 1, END 
    
    
    -- üũ 2, �̹� ������ �����Ͱ� �ֽ��ϴ�.
    IF EXISTS (SELECT 1 
                 FROM KPX_THRWelCodeYearItem AS A 
                 JOIN #KPX_THRWelCodeYearItem AS B ON ( B.YY = A.YY AND B.SubWelCodeSeq = A.WelCodeSeq ) 
                WHERE A.CompanySeq = @CompanySeq 
              ) 
    BEGIN
        UPDATE A
       SET Result = '�̹� ������ �����Ͱ� �ֽ��ϴ�.', 
           MessageType = 1234, 
           Status = 1234     
      FROM #KPX_THRWelCodeYearItem AS A 
     WHERE A.Status = 0 
    END 
    -- üũ 2, END 
    
    -- üũ 3, �ش� �⵵�� �ʼ��Դϴ�.
    UPDATE A
       SET Result = '�ش� �⵵�� �ʼ��Դϴ�.', 
           MessageType = 1234, 
           Status = 1234     
      FROM #KPX_THRWelCodeYearItem AS A 
     WHERE A.Status = 0 
       AND A.YY = '' 
    -- üũ 2, END 
    
    SELECT * FROM #KPX_THRWelCodeYearItem 
    
    RETURN  
GO 
exec KPX_SPRBasWelFareCodeCreateCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <SubWelCodeName>�����Ļ���</SubWelCodeName>
    <YY>2014</YY>
    <SubWelCodeSeq>10</SubWelCodeSeq>
    <SMRegType>3226002</SMRegType>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026356,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021406