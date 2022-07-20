  
IF OBJECT_ID('mnpt_SPJTWorkPlanCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkPlanCheck  
GO  
    
-- v2017.09.13
  
-- �۾���ȹ�Է�-SS1üũ by ����õ
CREATE PROC mnpt_SPJTWorkPlanCheck      
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
            @Results        NVARCHAR(250)   
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  

        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'mnpt_TPJTWorkPlan', 'WorkPlanSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #BIZ_OUT_DataBlock1  
           SET WorkPlanSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    ------------------------------------------------------------------
    -- üũ1, ����ó���� �Ǿ� �ű�/����/������ �� �� �����ϴ�. 
    ------------------------------------------------------------------
    DECLARE @WorkDate NCHAR(8) 
    SELECT @WorkDate = CASE WHEN A.WorkingTag = 'A' THEN A.WorkDate ELSE B.WorkDate END 
      FROM #BIZ_OUT_DataBlock1  AS A 
      LEFT OUTER JOIN mnpt_TPJTWorkPlan    AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkPlanSeq = A.WorkPlanSeq ) 
    
    UPDATE A
       SET Result = '����ó���� �Ǿ� �ű�/����/������ �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND EXISTS (SELECT 1 
                     FROM mnpt_TPJTWorkPlan AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.WorkDate = @WorkDate
                      AND Z.IsCfm = '1' 
                   )
    ------------------------------------------------------------------
    -- üũ1, END 
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- üũ2, �۾����ܽð��� �ùٸ��� �ʽ��ϴ�.
    ------------------------------------------------------------------
    DECLARE @EnvTime NCHAR(4) 

    SELECT @EnvTime = REPLACE(A.EnvValue,':','')
      FROM mnpt_TCOMEnv AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.EnvSeq = 5

    SELECT CASE WHEN B.ValueText < @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + B.ValueText AS SrtTime, 
           CASE WHEN C.ValueText <= @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + C.ValueText AS EndTime
      INTO #UMinorTime
      from _TDAUMinor AS A 
      LEFT OUTER JOIN _TDAUMinorValue AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1015905
    
    IF EXISTS (SELECT 1 from #UMinorTime WHERE SrtTime > EndTime ) 
    BEGIN 
        UPDATE #BIZ_OUT_DataBlock1   
           SET Result        = '�۾����ܽð��� �ùٸ��� �ʽ��ϴ�.',      
               MessageType   = 1234,      
               Status        = 1234      
          FROM #BIZ_OUT_DataBlock1  
         WHERE Status = 0  
           AND WorkingTag IN ( 'A', 'U' ) 
    END 
    ------------------------------------------------------------------
    -- üũ2, End
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- üũ3, �۾��ð��� �ùٸ��� �ʽ��ϴ�.
    ------------------------------------------------------------------
    UPDATE A
       SET Result        = '�۾��ð��� �ùٸ��� �ʽ��ϴ�.',      
           MessageType   = 1234,      
           Status        = 1234      
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND A.WorkSrtTime <> '' 
       AND A.WorkEndTime <> ''
       AND CASE WHEN REPLACE(A.WorkSrtTime,':','') < @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + REPLACE(A.WorkSrtTime,':','') > 
           CASE WHEN REPLACE(A.WorkEndTime,':','') <= @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + REPLACE(A.WorkEndTime,':','')
    ------------------------------------------------------------------
    -- üũ3, End
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- üũ4, �۾��������� ������ ������ ����/������ �� �� �����ϴ�.
    ------------------------------------------------------------------
    UPDATE A
       SET Result        = '�۾��������� ������ ������ ����/������ �� �� �����ϴ�.',  
           MessageType   = 1234,      
           Status        = 1234      
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.WorkingTag IN ( 'U', 'D' ) 
       AND A.Status = 0 
       AND EXISTS (SELECT 1 FROM mnpt_TPJTWorkReport WHERE CompanySeq = @CompanySeq AND WorkPlanSeq = A.WorkPlanSeq) 
    ------------------------------------------------------------------
    -- üũ4, END 
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- üũ5, �𼱺�û���� �۾��׸��� ���� �������� �ʼ��Դϴ�.
    ------------------------------------------------------------------
    UPDATE A
       SET Result = '�𼱺�û���� �۾��׸��� ���� �������� �ʼ��Դϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1      AS A 
      JOIN mnpt_TPJTProjectMapping  AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.UMWorkType = A.UMWorkType ) 
      JOIN _TPJTProjectDelivery     AS C ON ( C.companyseq = @CompanySeq AND C.pjtseq = B.pjtseq and B.itemseq = c.itemseq ) 
      JOIN mnpt_TPJTProjectDelivery AS D ON ( D.companyseq = @CompanySeq AND D.PJTSeq = C.PJTSeq AND D.DelvSerl = C.DelvSerl ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND A.ShipSerl = 0 
       AND D.IsShipCharge = '1'
    ------------------------------------------------------------------
    -- üũ5, END 
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- üũ6, �𼱺�û���� �ƴ� �۾��׸��� ���� �������� �Է� �� �� �����ϴ�.
    ------------------------------------------------------------------
    UPDATE A
       SET Result = '�𼱺�û���� �ƴ� �۾��׸��� ���� �������� �Է� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1      AS A 
      JOIN mnpt_TPJTProjectMapping  AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.UMWorkType = A.UMWorkType ) 
      JOIN _TPJTProjectDelivery     AS C ON ( C.companyseq = @CompanySeq AND C.pjtseq = B.pjtseq and B.itemseq = c.itemseq ) 
      JOIN mnpt_TPJTProjectDelivery AS D ON ( D.companyseq = @CompanySeq AND D.PJTSeq = C.PJTSeq AND D.DelvSerl = C.DelvSerl ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND D.IsShipCharge = '0'
       AND A.ShipSerl <> 0 
    ------------------------------------------------------------------
    -- üũ6, END 
    ------------------------------------------------------------------
    

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
       AND ( WorkPlanSeq = 0 OR WorkPlanSeq IS NULL )  
    

    RETURN  
 