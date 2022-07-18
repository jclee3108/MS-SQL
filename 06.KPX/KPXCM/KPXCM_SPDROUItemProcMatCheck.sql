  
IF OBJECT_ID('KPXCM_SPDROUItemProcMatCheck') IS NOT NULL   
    DROP PROC KPXCM_SPDROUItemProcMatCheck  
GO  
  
-- v2016.03.04 
  
-- ��ǰ���������ҿ�������� by����õ 
CREATE PROC KPXCM_SPDROUItemProcMatCheck  
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
    
    CREATE TABLE #TPDROUItemProcMat( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDROUItemProcMat'   
    IF @@ERROR <> 0 RETURN     
    
    ------------------------------------------------------------------------------------------------------------------------------
    -- üũ1, ��ǰ���������ҿ����簡 �����մϴ�. ���� �� ���� �Ͻñ� �ٶ��ϴ�. 
    ------------------------------------------------------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '��ǰ���������ҿ����簡 �����մϴ�.' + NCHAR(13) + '���� �� ���� �Ͻñ� �ٶ��ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #TPDROUItemProcMat AS A 
      JOIN _TPDROUItemProcMat AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.BOMRev = A.BOMRev AND B.ProcRev = A.ProcRev ) 
     WHERE A.Status = 0 
    ------------------------------------------------------------------------------------------------------------------------------
    -- üũ1, ��ǰ���������ҿ����簡 �����մϴ�. ���� �� ���� �Ͻñ� �ٶ��ϴ�. 
    ------------------------------------------------------------------------------------------------------------------------------
    
    SELECT * FROM #TPDROUItemProcMat 
    
    RETURN  