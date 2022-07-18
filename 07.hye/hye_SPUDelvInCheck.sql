IF OBJECT_ID('hye_SPUDelvInCheck') IS NOT NULL 
    DROP PROC hye_SPUDelvInCheck
GO 

-- v2016.11.08 

-- �����԰�üũ by����õ 
-- �ڵ��԰� �ƴ� ��(��ǰ)�� �԰��� ���� �� �� �ֵ��� 
/************************************************************  
��  �� - �����԰�üũ
�ۼ��� - 2008�� 8�� 20��   
�ۼ��� - �뿵��  
������ - 2009�� 9�� 9��
������ - ����
************************************************************/    
CREATE PROC hye_SPUDelvInCheck    
    @xmlDocument    NVARCHAR(MAX),      
    @xmlFlags       INT = 0,      
    @ServiceSeq     INT = 0,      
    @WorkingTag     NVARCHAR(10) = '',      
    @CompanySeq     INT = 0,      
    @LanguageSeq    INT = 1,      
    @UserSeq        INT = 0,      
    @PgmSeq         INT = 0      
AS      
      
    -- ���� ����      
    DECLARE @Count       INT,   
            @DataSeq     INT,        
            @DelvInSeq   INT,         
            @DelvInNo    NVARCHAR(12),        
            @BaseDate    NVARCHAR(8),        
            @MaxNo       NVARCHAR(12), 
            @DelvInDate  NCHAR(8),       
            @BizUnit     INT,        
            @MaxQutoRev  INT,  
            @MessageType INT,        
            @Status      INT,        
            @Results     NVARCHAR(250),
            @QCAutoIn    NCHAR(1)              
     

    IF @WorkingTag <> 'AUTO'        -- �ڵ��԰�ÿ��� �ӽ� ���̺� ���� X
    BEGIN    
    -- �ӽ� ���̺� ����  
    CREATE TABLE #TPUDelvIn (WorkingTag NCHAR(1) NULL)      
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUDelvIn'         
    END

    IF @@ERROR <> 0 RETURN   
    
    CREATE TABLE #TMP_SourceTable 
    (
        IDOrder   INT, 
        TableName NVARCHAR(100)
    )  

    CREATE TABLE #TCOMSourceTracking 
    (
        IDX_NO  INT, 
        IDOrder  INT, 
        Seq      INT, 
        Serl     INT, 
        SubSerl  INT, 
        Qty      DECIMAL(19,5), 
        StdQty   DECIMAL(19,5), 
        Amt      DECIMAL(19,5), 
        VAT      DECIMAL(19,5)
    ) 

    

    -- ���ų�ǰ�� �����Ͱ� �ڵ��԰�� �԰��ߴ��� ���μ����� �����ߴ��� Ȯ��
    IF EXISTS (SELECT 1 FROM #TPUDelvIn WHERE Status = 0 AND WorkingTag IN ( 'U', 'D' )) 
    BEGIN 
        
        DECLARE @IsAuto NCHAR(1) 

        SELECT TOP 1 1 AS IDX_NO, B.DelvInSeq, B.DelvInSerl  
          INTO #BaseData
          FROM #TPUDelvIn       AS A 
          JOIN _TPUDelvInItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvInSeq = A.DelvInSeq ) 
         WHERE Status = 0 
           AND A.WorkingTag IN ( 'U', 'D' )
    
        INSERT INTO #TMP_SourceTable (IDOrder, TableName) 
        SELECT 1, '_TPUDelvItem'   -- ã�� �������� ���̺�

          
        EXEC _SCOMSourceTracking @CompanySeq = @CompanySeq, 
                                 @TableName = '_TPUDelvInItem',  -- ���� ���̺�
                                 @TempTableName = '#BaseData',  -- �����������̺�
                                 @TempSeqColumnName = 'DelvInSeq',  -- �������̺� Seq
                                 @TempSerlColumnName = 'DelvInSerl',  -- �������̺� Serl
                                 @TempSubSerlColumnName = '' 
        
        SELECT @IsAuto = C.IsAuto
          FROM #BaseData            AS A 
          JOIN #TCOMSourceTracking  AS B ON ( B.IDX_NO = A.IDX_NO ) 
          JOIN _TPUDelv_Confirm      AS C ON ( C.CompanySeq = @CompanySeq AND C.CfmSeq = B.Seq )
    
    END 
    
    -- ȯ�漳���� ��������  # ���˻�ǰ �ڵ��԰� ����
    EXEC dbo._SCOMEnv @CompanySeq,6500,@UserSeq,@@PROCID,@QCAutoIn OUTPUT  

    -- �ڵ��԰� �ƴѰ��� ȯ�漳���� ������� '0'���� ���� by����õ 
    IF @IsAuto = '0' 
    BEGIN
        SELECT @QCAutoIn = '0' 
    END 

    -- �ڵ��԰���� ���� X
    IF @QCAutoIn = '1'
    BEGIN
        -------------------
        --��ǰ��ȣ ���� ---
        -------------------
        TRUNCATE TABLE #TMP_SourceTable  
        TRUNCATE TABLE #TCOMSourceTracking 

        CREATE TABLE #TMP_SOURCEITEM    
        (          
            IDX_NO     INT IDENTITY,          
            SourceSeq  INT,          
            SourceSerl INT,          
            Qty        DECIMAL(19, 5)    
        )
        CREATE TABLE #TMP_EXPENSE    
        (          
            IDX_NO     INT,          
            SourceSeq  INT,          
            SourceSerl INT,          
            ExpenseSeq INT    
        ) 
        INSERT #TMP_SOURCETABLE    
        SELECT '','_TPUDelvItem'    
    
        INSERT #TMP_SOURCETABLE    
        SELECT '','_TPUDelvInItem'
    
        INSERT #TMP_SOURCEITEM
             ( SourceSeq    , SourceSerl    , Qty)
        SELECT A.DelvInSeq    , B.DelvInSerl    , B.Qty
          FROM #TPUDelvIn          AS A
               JOIN _TPUDelvInItem AS B ON B.CompanySeq  = @CompanySeq
                                       AND A.DelvInSeq   = B.DelvInSeq
        WHERE A.WorkingTag IN ('U', 'D')
           AND A.Status    = 0

        EXEC _SCOMSourceTracking @CompanySeq, '_TPUDelvInItem', '#TMP_SOURCEITEM', 'SourceSeq', 'SourceSerl', ''          

        IF EXISTS (SELECT 1 FROM #TCOMSourceTracking)           -- �԰��Է� ȭ�鿡�� �Է��� ���� ����     
            IF  EXISTS (SELECT 1 FROM _TPUDelvItem AS A
                                         JOIN #TCOMSourceTracking AS B ON A.DelvSeq  = B.Seq
                                                                      AND A.DelvSerl = B.Serl            
                                   WHERE A.CompanySeq = @CompanySeq) 
            BEGIN
                EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                                      @Status      OUTPUT,    
                                      @Results     OUTPUT,    
                                      18                 , -- �ʼ��Է� ����Ÿ�� �Է��ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 18)    
                                      @LanguageSeq       ,     
                                      0,'�ڵ��԰��'   -- SELECT * FROM _TCADictionary WHERE Word like '%�㺸%'            
                UPDATE #TPUDelvIn    
                   SET Result        = @Results,
                       MessageType   = @MessageType,    
                       Status        = @Status   
                  FROM #TPUDelvIn		AS A
					   JOIN _TPUDelvIn  AS B ON B.CompanySeq = @CompanySeq
											AND A.DelvInSeq  = B.DelvInSeq
					   LEFT OUTER JOIN _TPUDelvInItem AS C ON B.CompanySeq = C.CompanySeq
														  AND B.DelvInSeq  = C.DelvInSeq	
					   LEFT OUTER JOIN _TPDBaseItemQCType AS D ON C.CompanySeq = D.CompanySeq	
															  AND C.ItemSeq	   = D.ItemSeq											  										
                 WHERE A.WorkingTag IN ('U', 'D')
                   AND ISNULL(B.IsReturn, '')  <> '1'
                   AND @WorkingTag <> 'AUTO'
                   AND ISNULL(D.IsNotAutoIn, '0') <> '1'			-- �ڵ��԰� �̻�� ǰ���� ������ �ǵ��� ���� 2010. 5. 28 Hkim
            END     
        -------------------
        --��ǰ��ȣ ���� ��  ----
        -------------------  
    END    
     -------------------------------------------    
     -- �ʼ�������üũ    D �˻�� ������ üũ(���ż��԰˻�)  
     -------------------------------------------    
     -------------------------------------------    
     -- �ʼ�������üũ    D ��ǰȮ��(��ǰ���� ������ �����Ǹ� �� �ȴ�.)  
     -------------------------------------------    
     -------------------------------------------    
     -- �ʼ�������üũ    
     -------------------------------------------    
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           1                  , -- �ʼ��Է� ����Ÿ�� �Է��ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
                           @LanguageSeq       ,     
                           0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%�㺸%'            
     UPDATE #TPUDelvIn    
        SET Result        = @Results,    
            MessageType   = @MessageType,    
            Status        = @Status    
      WHERE DelvInDate = ''    
         OR DelvInDate IS NULL    
     -------------------------------------------    
     -- ��ǥó�� üũ
     -------------------------------------------    
     --EXEC dbo._SCOMMessage @MessageType OUTPUT,    
     --                      @Status      OUTPUT,    
     --                      @Results     OUTPUT,    
     --                      18                  , -- �ʼ��Է� ����Ÿ�� �Է��ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
     --                      @LanguageSeq       ,     
     --                      0,'��ǥó�� ��'   -- SELECT * FROM _TCADictionary WHERE Word like '%��ǥ%'            
     --UPDATE #TPUDelvIn    
     --   SET Result        = @Results,    
     --       MessageType   = @MessageType,    
     --       Status        = @Status  
     -- FROM   #TPUDelvIn AS A JOIN _TPUBuyingAcc AS B ON B.CompanySeq = @CompanySeq
     --                                               AND A.DelvInSeq  = B.SourceSeq
     --                                               AND B.SourceType = '1'
     -- WHERE A.WorkingTag IN ('U', 'D')
     --   AND  ISNULL(B.SlipSeq,0) > 0

    --## �����԰� �� �˻簡 ó�� �� ���� ����/������ ���� �ʵ��� �߰� ##
    IF EXISTS (SELECT 1 FROM #TPUDelvIn WHERE WorkingTag IN ('U', 'D') AND Status = 0)
    BEGIN
        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                              @Status      OUTPUT,    
                              @Results     OUTPUT,    
    18                  , -- �ʼ��Է� ����Ÿ�� �Է��ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
                              @LanguageSeq       ,     
                              0, '�����԰��İ˻�� ����� ��'   -- SELECT * FROM _TCADictionary WHERE Word like '%��ǥ%'            
         UPDATE #TPUDelvIn    
            SET Result        = @Results,    
                MessageType   = @MessageType,    
                Status        = @Status  
          FROM  #TPUDelvIn            AS A 
                JOIN _TPDQCTestReport AS B ON A.DelvInSeq = B.SourceSeq
          WHERE A.WorkingTag IN ('U', 'D')
            AND A.Status     = 0
            AND B.CompanySeq = @CompanySeq
            AND B.SourceType = '7'
    END
	
	-- �ڵ��԰��ϰ�� �Ǻ��� DelvInSeq, DelvInNo ���� ����(�˻��ϰ�ó���� ������, �Ϲ� �ڵ��԰�� �Ѱ�)
	IF @WorkingTag = 'AUTO'
	BEGIN
		SELECT @DataSeq = 0
		
		WHILE( 1 > 0) 
		BEGIN
            SELECT TOP 1 @DataSeq = DataSeq    
            FROM #TPUDelvIn        
             WHERE WorkingTag = 'A'        
               AND Status = 0        
               AND DataSeq > @DataSeq        
             ORDER BY DataSeq        

            IF @@ROWCOUNT = 0 BREAK     
			
			SELECT @DelvInDate = DelvInDate FROM #TPUDelvIn WHERE DataSeq = @DataSeq
			EXEC @DelvInSeq = dbo._SCOMCreateSeq @CompanySeq, '_TPUDelvIn', 'DelvInSeq', 1		
			EXEC dbo._SCOMCreateNo 'PU', '_TPUDelvIn', @CompanySeq, '', @DelvInDate, @DelvInNo OUTPUT
			
			UPDATE #TPUDelvIn
			   SET DelvInSeq = @DelvInSeq + 1, -- �������� ���� ��� While�� ���鼭 �Ѱǽ� ó���ϱ� ������ 1�� ������
				   DelvInNo	 = @DelvInNo
			 WHERE WorkingTag = 'A'
			   AND Status  = 0
			   AND DataSeq = @DataSeq
		END
	END
	-- �ڵ��԰� �ƴ� ���
	ELSE
	BEGIN
		-- MAX POSeq Seq
		SELECT @Count = COUNT(*) FROM #TPUDelvIn WHERE WorkingTag = 'A' AND Status = 0 
		IF @Count > 0
		BEGIN   
			SELECT @DelvInDate = DelvInDate FROM #TPUDelvIn
			EXEC dbo._SCOMCreateNo 'PU', '_TPUDelvIn', @CompanySeq, '', @DelvInDate, @DelvInNo OUTPUT
			EXEC @DelvInSeq = dbo._SCOMCreateSeq @CompanySeq, '_TPUDelvIn', 'DelvInSeq', @Count     
			UPDATE #TPUDelvIn
			   SET DelvInSeq = @DelvInSeq + DataSeq , 
				   DelvInNo  = @DelvInNo
			 WHERE WorkingTag = 'A'
			   AND Status = 0
		END  
	END    


--     IF @WorkingTag <> 'AUTO'
--     BEGIN
--         UPDATE #TPUDelvIn
--            SET SMImpType = 8008001
--          WHERE ISNULL(SMIMPType,0) = 0
--     END
           
    
    IF @WorkingTag <> 'AUTO'
    BEGIN     
        SELECT * FROM #TPUDelvIn        
    END
          
      
RETURN
go
begin tran 
exec hye_SPUDelvInCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <SMWareHouseType>6201001</SMWareHouseType>
    <DelvInSeq>5205</DelvInSeq>
    <DelvInNo>201611080003</DelvInNo>
    <BizUnit>1</BizUnit>
    <DelvInDate>20161108</DelvInDate>
    <CustSeq>8829</CustSeq>
    <CustName>(��)�������չ��</CustName>
    <CustNo />
    <EmpSeq>1</EmpSeq>
    <EmpName>������</EmpName>
    <DeptSeq>7</DeptSeq>
    <DeptName>�濵��������</DeptName>
    <Remark />
    <CurrSeq>1</CurrSeq>
    <CurrName>KRW</CurrName>
    <ExRate>1</ExRate>
    <SMImpType>8008001</SMImpType>
    <InOutType>170</InOutType>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730151,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1137
rollback 