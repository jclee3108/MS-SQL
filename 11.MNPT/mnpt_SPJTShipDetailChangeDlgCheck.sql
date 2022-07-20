  
IF OBJECT_ID('mnpt_SPJTShipDetailChangeDlgCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTShipDetailChangeDlgCheck  
GO  
    
-- v2017.09.27
  
-- (Dlg)�̾��Է�-üũ by ����õ   
CREATE PROC mnpt_SPJTShipDetailChangeDlgCheck  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250), 
            @MaxShipSubSerl INT 
    
    ------------------------------------------------------------------------------
    -- üũ1, ������ �ִ°�쿡�� �̾��� ��� �� �� �ֽ��ϴ�.
    ------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '������ �ִ� ��쿡�� �̾��� ��� �� �� �ֽ��ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       --AND ISNULL(A.ApproachDate,'') + ISNULL(A.ApproachTime,'') > ISNULL(A.ChangeDate,'') + ISNULL(A.ChangeTime,'')
       AND ISNULL(A.ApproachDate,'') = '' 
       AND ISNULL(A.ChangeDate,'') <> '' 
    ------------------------------------------------------------------------------
    -- üũ1, END
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- üũ2, ����, �ð� ��� �Է��Ͻñ� �ٶ��ϴ�.
    ------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '����, �ð� ��� �Է��Ͻñ� �ٶ��ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND ( (ISNULL(A.ApproachDate,'') = '' AND ISNULL(A.ApproachTime, '') <> '') 
          OR (ISNULL(A.ApproachTime,'') = '' AND ISNULL(A.ApproachDate, '') <> '') 
          OR (ISNULL(A.ChangeDate,'') = '' AND ISNULL(A.ChangeTime, '') <> '') 
          OR (ISNULL(A.ChangeTime,'') = '' AND ISNULL(A.ChangeDate, '') <> '') 
           ) 
    ------------------------------------------------------------------------------
    -- üũ2, END
    ------------------------------------------------------------------------------

    
    --SubSerl ä�� 
    SELECT @MaxShipSubSerl = MAX(A.ShipSubSerl) 
      FROM mnpt_TPJTShipDetailChange AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE ShipSeq = A.ShipSeq AND ShipSerl = A.ShipSerl) 
     GROUP BY A.ShipSeq, A.ShipSerl 
    
    UPDATE A 
       SET ShipSubSerl = ISNULL(@MaxShipSubSerl,0) + A.IDX_NO
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE Status = 0 
       AND WorkingTag = 'A' 
      
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #BIZ_OUT_DataBlock1   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #BIZ_OUT_DataBlock1  
     WHERE Status = 0  
       AND ( 
                ( ShipSeq = 0 OR ShipSeq IS NULL ) OR 
                ( ShipSerl = 0 OR ShipSerl IS NULL ) OR 
                ( ShipSubSerl = 0 OR ShipSubSerl IS NULL ) 
           )
    
    RETURN  
    