  
IF OBJECT_ID('mnpt_SARUsaulCostAmtOppAccUpdateCheck') IS NOT NULL   
    DROP PROC mnpt_SARUsaulCostAmtOppAccUpdateCheck  
GO  
    
-- v2018.01.12
  
-- �Ϲݺ���û_mnpt-����������üũ by ����õ
CREATE PROC mnpt_SARUsaulCostAmtOppAccUpdateCheck  
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
      
    CREATE TABLE #TARUsualCostAmt( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TARUsualCostAmt'   
    IF @@ERROR <> 0 RETURN     

    -------------------------------------------------------
    -- üũ1, ��ǥ�� �����Ǿ� ���� �� �� �����ϴ�. 
    -------------------------------------------------------
    UPDATE A
       SET Result = '��ǥ�� �����Ǿ� ���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #TARUsualCostAmt AS A 
      JOIN _TARUsualCost    AS B ON ( B.CompanySeq = @CompanySeq AND B.UsualCostSeq = A.UsualCostSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'U' 
       AND B.SlipSeq <> 0 
    -------------------------------------------------------
    -- üũ1, End 
    -------------------------------------------------------

    -------------------------------------------------------
    -- üũ2, ���� �� ������ ���� �� �� �ֽ��ϴ�.
    -------------------------------------------------------
    UPDATE A
       SET Result = '���� �� ������ ���� �� �� �ֽ��ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #TARUsualCostAmt AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'U' 
       AND A.UsualCostSeq = 0 
    -------------------------------------------------------
    -- üũ2, End 
    -------------------------------------------------------
    


    SELECT * FROM #TARUsualCostAmt   
      
    RETURN  