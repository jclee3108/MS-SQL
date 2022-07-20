IF OBJECT_ID('mnpt_STAXVATEdiCREATEFile') IS NOT NULL 
    DROP PROC mnpt_STAXVATEdiCREATEFile
GO 

-- v2018.02.08 

-- ����ں��� ���ι�ȣ ���� by����õ
/************************************************************    
��  �� - ���ڽŰ����ϻ���    
�ۼ��� - 2009. 10. 16         
�ۼ��� -     
    I104400     �������Ȳ����
    I103400     �ſ�ī�������ǥ����ݾ׵� ����ǥ 
    I105800     ������÷�μ����������
    I102300     �������Լ��װ����Ű�
    M116300     ��Ȱ�����ڿ��� �� �߰��ڵ������Լ��װ����Ű�
    I103600     �ε����Ӵ�������� ����
    I102800     ��ռ��װ���(����)�Ű�
    I104500     ����庰 �ΰ���ġ�� ����ǥ�� �� ���μ���(ȯ�޼���)�Ű���� 
    I103800     �ǹ��� �������ڻ� ������ 
    I103300     �������� ���� ���Լ��� ����
    M200100     �����Ǹž��հ�ǥ
    M118000     �����ڹ��༼�ݰ�꼭�հ�ǥ
    I104300     �ǹ���������
    I103900    ����ڴ��������ǻ���庰�ΰ���ġ������ǥ�ع׳��μ���(ȯ�޼���)�Ű����    
    I103700     ���ݸ������
    I105600     �����ſ��� / ����Ȯ�μ� ���ڹ߱޸���
    I104000     �������������
    M202300     �ܱ��ΰ����� �鼼��ǰ �Ǹ� �� ȯ�޽�������
    M125200     ������ũ���� ���Լ��װ����Ű�
    I102600     ���������ȯ �������ڻ�Ű�        2017�� 1�� ���� �߰� by dhkim3
    I402100     ��ȭȹ�����
    I106900     �ܱ��ΰ����� ���ȯ�� ��ǰ �Ǹ� ��������
    I401500     ����ȯ�ޱݵ� ���� 2016�� 2�� ���� �߰� by dhkim3
-----------------------------------
���ڼ��ݰ�꼭 �߱޼��װ����Ű�   -- 2016�� 1����� ���� ��� / _TTAXEBillTaxDeductCard
************************************************************/     
CREATE PROCEDURE mnpt_STAXVATEdiCREATEFile                           
    @xmlDocument    NVARCHAR(MAX) ,                      
    @xmlFlags       INT = 0,                      
    @ServiceSeq     INT = 0,                      
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,                      
    @LanguageSeq    INT = 1,                      
    @UserSeq        INT = 0,                      
    @PgmSeq         INT = 0
AS    
  
    DECLARE @SaleCnt            INT,  
            @SupAmt             DECIMAL(19,5),  
            @TaxAmt             DECIMAL(19,5),  
            @Count_A            INT,  
            @Count_B            INT,  
            @Cnt                INT,  
            @MaxCnt             INT,  
            @BuildingSeq        INT,            
            @CustCntBiz         INT,  
            @CustCntPer         INT,  
            @TotCntBiz          INT,  
            @TotCntPer          INT,  
            @SAmtBiz            DECIMAL(19,5),  
            @SAmtPer            DECIMAL(19,5),  
            @VAmtBiz            DECIMAL(19,5),  
            @VAmtPer            DECIMAL(19,5),  
            @CurrDate           VARCHAR(8)
    DECLARE @docHandle          INT
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                       
    DECLARE @TaxTermSeq         INT,    
            @TaxUnit            INT,    
            @RptDate            NVARCHAR(08)                 
    -- WorkingTag �߿� : ���ڽŰ�� ''(A�γѾ���� �Ʒ��� ''���� ����),   
    --���ϽŰ� : ���ݰ�꼭 �հ�ǥ 'K',   
                -- ��꼭�հ�ǥ 'H',   
                -- ����������� 'A',   
                -- �ſ�ī�������ǥ�������(��,��) 'J',      
                -- ����庰 �ΰ���ġ�� ����ǥ�ع׳��μ���(ȯ�޼���)�Ű�� 'M'  
                -- ����ڴ��������� ����庰�ΰ���ġ������ǥ�ع׳��μ��� 'U'
                
    SELECT @TaxTermSeq      = ISNULL(TaxTermSeq     ,  0),    
           @TaxUnit         = ISNULL(TaxUnit        ,  0),    
           @RptDate         = ISNULL(RptDate        , ''),    
           @WorkingTag      = ISNULL(WorkingTag     , '')
    FROM OPENXML (@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
    WITH (  TaxTermSeq      INT,    
            TaxUnit         INT,    
            RptDate         NVARCHAR(08),    
            WorkingTag      NVARCHAR(10) )   
    IF ISNULL(@RptDate, '') = ''
        SELECT @RptDate = CONVERT(NVARCHAR(8), GETDATE(), 112)

    -----------------------------------------------------
    -- ȯ�漳��
    -----------------------------------------------------
    DECLARE @IsESERO        NCHAR(1),  
            @Env4728        NCHAR(1),
            @Env4735        NCHAR(1),
            @Env4016        INT,
            @Env4017        NVARCHAR(8),
            @Env4501        NVARCHAR(10),
            @V166Cfm        CHAR(7),
            @KorCurrNo      VARCHAR(03),    -- ��ȭȭ���ڵ�      
            @StkCurrCd      VARCHAR(03),    -- �ڱ���ȭ    
            @StkCurrSeq     INT
    --DECLARE @CompanySeq INT =1,
    --        @UserSeq INT = 1
    EXEC dbo._SCOMEnv @CompanySeq, 4509 , @UserSeq , @@PROCID , @IsESERO OUTPUT         -- [ȯ�漳��4509] Ȩ�ý������ͷ� ���ڼ��ݰ�꼭 �Ǽ�/�ݾ� �Ű���
    EXEC dbo._SCOMEnv @CompanySeq, 4728 , @UserSeq , @@PROCID , @Env4728 OUTPUT         -- [ȯ�漳��4728] Ȩ�ý������ͷ� ���ڰ�꼭 �Ǽ�/�ݾ� �Ű���
    EXEC dbo._SCOMEnv @CompanySeq, 4735 , @UserSeq , @@PROCID , @Env4735 OUTPUT         -- [ȯ�漳��4735] ����������� �ݾ��� ��ȭȹ����� �ݾ����� �ڵ����� ����
    EXEC dbo._SCOMEnv @CompanySeq, 4016 , @UserSeq , @@PROCID , @Env4016 OUTPUT         -- [ȯ�漳��4016] <����ȸ��>  �ΰ����Ű���
    EXEC dbo._SCOMEnv @CompanySeq, 4017 , @UserSeq , @@PROCID , @Env4017 OUTPUT         -- [ȯ�漳��4017] <����ȸ��>  ����ڴ����������� ��������
    EXEC dbo._SCOMEnv @CompanySeq, 4501 , @UserSeq , @@PROCID , @Env4501 OUTPUT         -- [ȯ�漳��4501] <����ȸ��>  ����ڴ������� ���ι�ȣ
    EXEC dbo._SCOMEnv @CompanySeq, 13   , @UserSeq , @@PROCID , @StkCurrSeq OUTPUT      -- [ȯ�漳��13]   <�����>  �ڱ� ��ȭ
    SELECT @IsESERO = ISNULL(@IsESERO, '0')
    SELECT @Env4728 = ISNULL(@Env4728, '0')
    SELECT @Env4735 = ISNULL(@Env4735, '0')
    SELECT @Env4016 = ISNULL(@Env4016, 0)
    SELECT @Env4017 = ISNULL(@Env4017, '29991231')
    SELECT @V166Cfm = REPLACE(ISNULL(@Env4501, ''), '-', '') 
    SELECT @StkCurrSeq = ISNULL(@StkCurrSeq, 0)
    SELECT @KorCurrNo   = 'KRW'
    SELECT @StkCurrCd = ISNULL(CurrNo, '') FROM _TDACurr WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CurrSeq = @StkCurrSeq
    IF @@ROWCOUNT = 0 OR ISNULL(@StkCurrCd, '') = ''    
    BEGIN    
        SELECT @StkCurrCd = CurrNo, @StkCurrSeq = CurrSeq FROM _TDACurr WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CurrNo = @KorCurrNo    
    END    
    -----------------------------------------------------
    -- ȯ�漳�� END
    -----------------------------------------------------
    
    DECLARE @CompanyNo          CHAR(13),   -- ���ε�Ϲ�ȣ      
            -- �����Ⱓ
            @TaxFrDate          CHAR(8),    -- ��������      
            @TaxToDate          CHAR(8),    -- ��������      
            @BillFrDate         CHAR(8),    -- ��꼭���� ��������
            @BillToDate         CHAR(8),    -- ��꼭���� ��������
            @Term_SMTaxationType    INT,
            -- �����
            @CashSaleKind       NCHAR(2),
            @Addr1              VARCHAR(70),    -- ������ּ�(���� 70��)      
            @Addr2              VARCHAR(45),    -- ������ּ�(���� 45��)    
            @TaxBizTypeNo       CHAR(7),        -- �־����ڵ�      
            @TaxSumPaymentNo    CHAR(7),        -- �Ѱ����ν��ι�ȣ      
            @TaxNo              VARCHAR(10),
            @BizCancelDate      CHAR(8),
            @Unit_SMTaxationType    INT,
            @OverDate           CHAR(8)
    
    --------------------------      
    --�������� �� ��������      
    --------------------------     
    SELECT @TaxFrDate   = TaxFrDate     ,
           @TaxToDate   = TaxToDate     ,
           @BillFrDate  = BillSumFrDate ,  
           @BillToDate  = BillSumToDate ,
           @Term_SMTaxationType = SMTaxationType    -- �Ű���(���� 4090001 / Ȯ�� 4090002 / ������ �� ����ȯ�� 4090006 / �Ϲ� 4090004)
      FROM _TTAXTerm WITH (NOLOCK)    
     WHERE CompanySeq   = @CompanySeq  
       AND TaxTermSeq   = @TaxTermSeq  
    SELECT @CurrDate = CONVERT(VARCHAR(8), GETDATE(), 112)      -- ������ / ��������
    IF @PgmSeq = 480        -- FrmTAXVatRptEdi
    BEGIN  
        SELECT @WorkingTag = ''  
    END
    -- ����ڴ��������� ��� WorkingTag����  
    -- ����庰 �ΰ���ġ�� ����ǥ�ع׳��μ���(ȯ�޼���)�Ű�� 'M'
    -- => ����ڴ��������� ����庰�ΰ���ġ������ǥ�ع׳��μ��� 'U'
    IF @WorkingTag = 'M' AND (@Env4016 = 4125002 AND @TaxFrDate >= @Env4017)
    BEGIN  
        SELECT @WorkingTag = 'U'  
    END
    -----------------------------------------------------------------------------
    -- ��������� �̷� ��������
    -----------------------------------------------------------------------------
    DECLARE @MaxUnitIDX     INT,
            @UnitIDX        INT,
            @IDX_TaxUnit    INT,
            @HistCnt        INT
    CREATE TABLE #TaxUnitAll ( IDX INT IDENTITY(1,1), TaxUnit INT )
    CREATE TABLE #TDATaxUnit (
	    CompanySeq	        INT	, 
	    TaxUnit	            INT	, 
	    TaxNo	            NVARCHAR(50)	, 
	    TaxName	            NVARCHAR(100)	, 
	    Owner	            NVARCHAR(100)	, 
	    BizType	            NVARCHAR(50)	, 
	    ResidID	            NVARCHAR(200)	, 
	    BizItem	            NVARCHAR(50)	, 
	    Zip	                NVARCHAR(10)	, 
	    Addr1	            NVARCHAR(100)	, 
	    Addr2	            NVARCHAR(100)	, 
	    Addr3	            NVARCHAR(100)	, 
	    TelNo	            NVARCHAR(30)	, 
	    CellPhone	        NVARCHAR(30)	, 
	    EMail	            NVARCHAR(100)	, 
	    VATRptAddr	        NVARCHAR(200)	, 	
	    BizCancelDate	    NCHAR(8)	    , 
	    HomeTaxID	        NVARCHAR(100)	, 	
	    TaxOfficeNo	        NCHAR(3)	    , 
	    TaxBizTypeNo	    NVARCHAR(10)	, 
	    liquorWholeSaleNo	NVARCHAR(10)	, 
	    liquorRetailSaleNo	NVARCHAR(10)	, 
	    SMTaxationType	    INT	            , 
	    BillTaxName	        NVARCHAR(100)	, 
	    TaxSumPaymentNo	    NVARCHAR(20)	, 
	    TaxNoSerl	        NVARCHAR(20)	, 
	    CashSaleKind	    NCHAR(2)	    , 
	    RoadAddr	        NVARCHAR(200)	  ) 
    CREATE TABLE #TaxUnitHist(
        TaxUnit         INT,
        SMTaxationType  INT,
        TaxNoSerl       NVARCHAR(20)
    )

    INSERT INTO #TaxUnitAll(TaxUnit)
    SELECT TaxUnit
      FROM _TDATaxUnit WITH(NOLOCK)
     WHERE CompanySeq = @CompanySeq
    SELECT @UnitIDX    = 1,
           @MaxUnitIDX = (SELECT MAX(IDX) FROM #TaxUnitAll)
    WHILE(@UnitIDX <= @MaxUnitIDX)
    BEGIN
        SELECT @IDX_TaxUnit = (SELECT TaxUnit FROM #TaxUnitAll WHERE IDX = @UnitIDX)
        INSERT INTO #TDATaxUnit(CompanySeq      , TaxUnit       , TaxNo         , TaxName           , Owner         ,
                                BizType         , ResidID       , BizItem       , Zip               , Addr1         ,
                                Addr2           , Addr3         , TelNo         , CellPhone         , EMail         ,
                                VATRptAddr      , BizCancelDate , HomeTaxID     , TaxOfficeNo       , TaxBizTypeNo  ,
                                SMTaxationType  , BillTaxName   , TaxSumPaymentNo,TaxNoSerl         , CashSaleKind  ,
                                RoadAddr        , liquorWholeSaleNo             ,liquorRetailSaleNo )
        SELECT T.CompanySeq      , T.TaxUnit       , T.TaxNo            , T.TaxName           , T.Owner         ,
                T.BizType         , T.ResidID       , T.BizItem          , T.Zip               , T.Addr1         ,
                T.Addr2           , T.Addr3         , T.TelNo            , T.CellPhone         , T.EMail         ,
                T.VATRptAddr      , T.BizCancelDate , T.HomeTaxID        , T.TaxOfficeNo       , T.TaxBizTypeNo  ,
                T.SMTaxationType  , T.BillTaxName   , T.TaxSumPaymentNo  , T.TaxNoSerl         , T.CashSaleKind  ,
                T.RoadAddr        , T.liquorWholeSaleNo                  , T.liquorRetailSaleNo 
            FROM _TDATaxUnit AS T WITH(NOLOCK)
        WHERE T.CompanySeq = @CompanySeq 
            AND T.TaxUnit    = @IDX_TaxUnit

        SELECT @HistCnt = COUNT(Y.TaxNoAlias)
          FROM _TTAXTerm AS X WITH(NOLOCK)
                    LEFT JOIN _TDATaxUnitHist AS Y WITH(NOLOCK)
                           ON X.CompanySeq = Y.CompanySeq                     
                          AND X.TaxToDate <= Y.ToDate
         WHERE X.CompanySeq = @CompanySeq  
           AND X.TaxTermSeq = @TaxTermSeq  
           AND Y.TaxUnit    = @IDX_TaxUnit
        IF @HistCnt <> 0 -- ����ڵ�� �̷��� �ִ� ���        
        BEGIN
            INSERT INTO #TaxUnitHist(TaxUnit, SMTaxationType, TaxNoSerl)
            SELECT T.TaxUnit, T.SMTaxationType, T.TaxNoSerl
              FROM _TTAXTerm AS B WITH(NOLOCK)
                        JOIN _TDATaxUnitHist AS T WITH(NOLOCK)
                          ON B.CompanySeq = T.CompanySeq
                         AND B.TaxToDate <= T.ToDate
             WHERE  B.CompanySeq = @CompanySeq
               AND  B.TaxTermSeq = @TaxTermSeq
               AND  T.TaxUnit    = @IDX_TaxUnit
             ORDER BY T.Serl
            
            -- �Ϲݰ����ڱ��� / ��������Ϸù�ȣ�� Hist ���� by shkim1
            -- �Ѱ�����/�Ϲݻ���� -> ����ڴ������� ���� �� ���� �̷����� �Ű��ϱ� ����
            UPDATE #TDATaxUnit
               SET SMTaxationType = T.SMTaxationType,
                   TaxNoSerl      = T.TaxNoSerl
              FROM #TDATaxUnit AS A
                        JOIN #TaxUnitHist AS T ON T.TaxUnit = A.TaxUnit
             WHERE A.TaxUnit = @IDX_TaxUnit
        END
        SELECT @UnitIDX = @UnitIDX + 1
    END

    -----------------------------------------------------------------------------
    -- ��������� �̷� �������� END
    -----------------------------------------------------------------------------
    --------------------------------
    -- ����� ����
    --------------------------------
    SELECT @CashSaleKind    = ISNULL(CashSaleKind,''),
           @Addr1           = ISNULL(SUBSTRING(LTRIM(RTRIM(VATRptAddr)), 1, 70), SPACE(70)),    
           @Addr2           = ISNULL(SUBSTRING(LTRIM(RTRIM(VATRptAddr)), 1, 45), SPACE(45)),    
           @TaxBizTypeNo    = ISNULL(TaxBizTypeNo   , ''),    
           @TaxSumPaymentNo = CASE WHEN SMTaxationType = 4128002 THEN ISNULL(TaxSumPaymentNo, '') ELSE '' END,
           @TaxNo           = CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '')),
           @BizCancelDate   = ISNULL(BizCancelDate, '') ,
           @Unit_SMTaxationType = SMTaxationType
      FROM #TDATaxUnit
     WHERE CompanySeq = @CompanySeq
       AND TaxUnit    = @TaxUnit
    
    --========================================================================  
    -- üũ����
    --======================================================================== 
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250),
            @Word1          NVARCHAR(200)
    EXEC @Word1    = _FCOMGetWord @LanguageSeq , 14542   , N'�����'
      
    IF (SELECT TelNo FROM #TDATaxUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq  AND TaxUnit = @TaxUnit ) = ''
    BEGIN
    
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1008               , -- @1��(��) �Է����� �ʾҽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%�Է�%')  
                              @LanguageSeq       ,
                              1396  ,   '��ȭ��ȣ'
        
        SELECT -1 AS tmp_Seq, @Word1 + ' ' + @Results AS tmp_file
        RETURN
    END
    
    IF @WorkingTag = ''
    BEGIN                        
        -- ����ڵ�� - ���ڽŰ�ID ���� üũ
        IF ( SELECT HomeTaxID FROM #TDATaxUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq  AND TaxUnit = @TaxUnit ) = ''
        BEGIN
            
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  1008               , -- @1��(��) �Է����� �ʾҽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%�Է�%')  
                                  @LanguageSeq       ,
                                  2159  ,   '���ڽŰ�ID'
                                  
            SELECT -1 AS tmp_Seq, @Results AS tmp_file
            RETURN
        END
        
        -- ����ڵ�� - �־����ڵ� ���� üũ
        IF ( SELECT TaxBizTypeNo FROM #TDATaxUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq  AND TaxUnit = @TaxUnit ) = ''
        BEGIN
            
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  1008               , -- @1��(��) �Է����� �ʾҽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%�Է�%')  
                                  @LanguageSeq       ,
                                  1334  ,   '�־����ڵ�'	
                                  
            SELECT -1 AS tmp_Seq, @Results AS tmp_file
            RETURN
        END
        
        -- �����ڵ� �ߺ� üũ
        IF EXISTS(SELECT BizTypeSeq 
                    FROM _TTAXVATRptBizAmt AS A WITH(NOLOCK)
                            JOIN _TTAXBizKind AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq 
                                                               AND A.TaxUnit    = B.TaxUnit 
                                                               AND A.BizKindSeq = B.BizKindSeq
                   WHERE A.CompanySeq = @CompanySeq
                     AND A.TaxTermSeq = @TaxTermSeq 
                     AND A.TaxUnit    = @TaxUnit  
                     AND A.RptNo      IN ('3010', '3020', '3030')
                     AND A.SpplyAmt  <> 0
                   GROUP BY BizTypeSeq
                   HAVING COUNT(B.BizTypeSeq) > 1)
        OR EXISTS( SELECT BizTypeSeq 
                     FROM _TTAXVATRptBizAmt AS A WITH(NOLOCK)
                            JOIN _TTAXBizKind AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq 
                                                               AND A.TaxUnit    = B.TaxUnit 
                                                               AND A.BizKindSeq = B.BizKindSeq
                   WHERE A.CompanySeq = @CompanySeq
                     AND A.TaxTermSeq = @TaxTermSeq 
                     AND A.TaxUnit    = @TaxUnit  
                     AND A.RptNo      IN ('7010', '7020')
                     AND A.SpplyAmt  <> 0  
                   GROUP BY BizTypeSeq
                   HAVING COUNT(B.BizTypeSeq) > 1)
        BEGIN
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%�ߺ�%')  
                                  @LanguageSeq       ,
                                  7196  ,  '�����ڵ�'  -- SELECT * FROM _TCADictionary WHERE Word LIKE '%�����ڵ�%'
            SELECT -1 AS tmp_Seq, @Results AS tmp_file
            RETURN
        END
        
        -- �����ڵ� ���� üũ
        IF EXISTS (SELECT 1 FROM _TTAXVATRptBizAmt AS A WITH(NOLOCK)
                            JOIN _TTAXBizKind AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq 
                                                               AND A.TaxUnit    = B.TaxUnit 
                                                               AND A.BizKindSeq = B.BizKindSeq
                    WHERE A.CompanySeq = @CompanySeq
                      AND A.TaxTermSeq = @TaxTermSeq
                      AND A.TaxUnit    = @TaxUnit  
                      AND A.RptNo      IN ('3010','3020','3030','7010','7020', '7025')
                      AND A.SpplyAmt  <> 0
                      AND (B.BizTypeSeq = '0' OR B.BizTypeSeq = ''))
        BEGIN
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  1005               , -- @1�� ���� �Է��ϼž� �մϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%�Է�%' AND LanguageSeq = 1)  
                                  @LanguageSeq       ,
                                  7196  ,  '�����ڵ�'  -- SELECT * FROM _TCADictionary WHERE Word LIKE '%�����ڵ�%'
            SELECT -1 AS tmp_Seq, @Results AS tmp_file
            RETURN
        END
        
        -- ����ǥ�ظ� - ���Աݾ����� �������� �̵�� üũ
        IF EXISTS (SELECT 1 FROM _TTAXVATRptBizAmt AS A WITH(NOLOCK)
                    WHERE A.CompanySeq = @CompanySeq
                      AND A.TaxTermSeq = @TaxTermSeq
                      AND A.TaxUnit    = @TaxUnit  
                      AND A.RptNo      IN ('3040')
                      AND A.SpplyAmt  <> 0)
          AND (SELECT COUNT(*) FROM _TTAXBizKind AS B WITH(NOLOCK)
                WHERE B.CompanySeq = @CompanySeq
                  AND B.TaxUnit    = @TaxUnit
                  AND B.RptSort    = '3040') <> 1
        BEGIN
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  7                  , -- @1��(��) ��ϵǾ� ���� �ʽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%���%' AND LanguageSeq = 1)  
                                  @LanguageSeq       ,
                                  7194  ,  '�������и�'  -- SELECT * FROM _TCADictionary WHERE Word LIKE '%��������%'
            SELECT -1 AS tmp_Seq, '�ΰ����Ű�-����ǥ�ظ� ���Աݾ������� ' + @Results AS tmp_file
            RETURN
        END
        
        -- �鼼��� - ���Աݾ����� �������� �̵�� üũ
        IF EXISTS (SELECT 1 FROM _TTAXVATRptBizAmt AS A WITH(NOLOCK)
                    WHERE A.CompanySeq = @CompanySeq
                      AND A.TaxTermSeq = @TaxTermSeq
                      AND A.TaxUnit    = @TaxUnit  
                      AND A.RptNo      IN ('7025')
                      AND A.SpplyAmt  <> 0)
          AND (SELECT COUNT(*) FROM _TTAXBizKind AS B WITH(NOLOCK)
                WHERE B.CompanySeq = @CompanySeq
                  AND B.TaxUnit    = @TaxUnit
                  AND B.RptSort    = '7025') <> 1
        BEGIN
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  7                  , -- @1��(��) ��ϵǾ� ���� �ʽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%���%' AND LanguageSeq = 1)  
                                  @LanguageSeq       ,
                                  7194  ,  '�������и�'  -- SELECT * FROM _TCADictionary WHERE Word LIKE '%��������%'
            SELECT -1 AS tmp_Seq, '�ΰ����Ű�-�鼼��� ���Աݾ������� ' + @Results AS tmp_file
            RETURN
        END
        
        
        -- ���ݸ���������ڵ�� ��ϵǾ� ���� ������ ���ݸ�������� �ۼ��� ��� üũ
        --IF @CashSaleKind = ''
        --  AND (EXISTS (SELECT 1 FROM _TTAXBizStdSumV167 WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
        --    OR EXISTS (SELECT 1 FROM _TTAXBizStdSumV167M WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit))  
        --BEGIN
        --    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
        --                          @Status      OUTPUT,  
        --                          @Results     OUTPUT,  
        --                          7                  , -- @1��(��) ��ϵǾ� ���� �ʽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7 AND LanguageSeq = 1)  
        --                          @LanguageSeq       ,
        --                          28742  ,  N'���ݸ���������ڵ�'  -- SELECT * FROM _TCADictionary WHERE Word LIKE '���ݸ��������%'
        --    SELECT -1 AS tmp_Seq, '[����ڵ��] ' + @Results AS tmp_file
        --    RETURN
        --END
        
        -- �������Ȳ üũ
        IF (@Term_SMTaxationType <> 4090002 )
          AND( EXISTS (SELECT * FROM _TTAXBizPlace WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit))
        BEGIN
            EXEC dbo._SCOMMessage @MessageType OUTPUT,
                                  @Status      OUTPUT,
                                  @Results     OUTPUT,
                                  1345               , -- @1�� @2@3�� @4�� �� �ֽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 AND MessageSeq = 1345)
                                  @LanguageSeq       ,
                                  14965     , N'����', -- SELECT * FROM _TCADictionary WHERE Word LIKE '%����%' AND LanguageSeq = 1
                                  607       , N'Ȯ��', -- SELECT * FROM _TCADictionary WHERE Word LIKE 'Ȯ��' AND LanguageSeq = 1
                                  25241     , N'�Ű�', -- SELECT * FROM _TCADictionary WHERE Word LIKE '�Ű�' AND LanguageSeq = 1
                                  25241     , N'�Ű�'  -- SELECT * FROM _TCADictionary WHERE Word LIKE '���' AND LanguageSeq = 1
            SELECT -1 AS tmp_Seq, '[�������Ȳ����] ' + @Results AS tmp_file
            RETURN        
        END
        -- ��ռ��װ���(����)�Ű� üũ
        IF (@Term_SMTaxationType <> 4090002 )
          AND( EXISTS (SELECT * FROM _TTAXBadDebt WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit))
        BEGIN
            EXEC dbo._SCOMMessage @MessageType OUTPUT,
                                  @Status      OUTPUT,
                                  @Results     OUTPUT,
                                  1345               , -- @1�� @2@3�� @4�� �� �ֽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 AND MessageSeq = 1345)
                                  @LanguageSeq       ,
                                  14965     , N'����', -- SELECT * FROM _TCADictionary WHERE Word LIKE '%����%' AND LanguageSeq = 1
                                  607       , N'Ȯ��', -- SELECT * FROM _TCADictionary WHERE Word LIKE 'Ȯ��' AND LanguageSeq = 1
                                  25241     , N'�Ű�', -- SELECT * FROM _TCADictionary WHERE Word LIKE '�Ű�' AND LanguageSeq = 1
                                  25241     , N'�Ű�'  -- SELECT * FROM _TCADictionary WHERE Word LIKE '���' AND LanguageSeq = 1
            SELECT -1 AS tmp_Seq, '[��ռ��װ���(����)�Ű�] ' + @Results AS tmp_file
            RETURN        
        END
        -- ��ũ������Լ��װ����Ű� üũ
        IF (@Term_SMTaxationType = 4090002 )
          AND( EXISTS (SELECT * FROM _TTAXCuDeductScrap WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit))
        BEGIN
            EXEC dbo._SCOMMessage @MessageType OUTPUT,
                                  @Status      OUTPUT,
                                  @Results     OUTPUT,
                                  19                  , -- @1��(��) @2(��)�� �� �� �����ϴ�.
                                  @LanguageSeq       ,
                                  19221,    N'Ȯ���Ű�',
                                  29061,    N'����'
            SELECT -1 AS tmp_Seq, '[��ũ������Լ��װ����Ű�] ' + @Results AS tmp_file
            RETURN        
        END
        
    END
 
    IF @WorkingTag IN('Z', 'E', 'M', 'U', 'L')   -- ������(Z), �ε����Ӵ�(E), ����庰�ΰ���ġ��(M), ����ڴ���(U), �����ſ���(L)
        AND (SELECT ResidID FROM #TDATaxUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq  AND TaxUnit = @TaxUnit ) = ''
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1008               , -- @1��(��) �Է����� �ʾҽ��ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%�Է�%')  
                              @LanguageSeq       ,
                              13066  ,  '��ǥ�� �ֹε�Ϲ�ȣ'
                      
      
        SELECT -1 AS tmp_Seq, @Results AS tmp_file
        RETURN
    END
    
    --========================================================================================
    -- üũ ���� END
    --========================================================================================
    --------------------------      
    --�����Ⱓ ������ ������ 11��
    --------------------------    
    SELECT @OverDate = OverDate
      FROM _TTAXOverTerm WITH(NOLOCK)
     WHERE YearMonth = LEFT(@TaxToDate,6)
  
    /*
    --------------------------      
    --���ε�Ϲ�ȣ      
    --------------------------      
    SELECT @CompanyNo   = ISNULL(LTRIM(RTRIM(CompanyNo)), SPACE(13))
      FROM _TCACompany WITH (NOLOCK)    
     WHERE CompanySeq   = @CompanySeq  
    */
    
    -------------------------------------------------------
    -- ����ں� ���ι�ȣ Setting, 2018.02.08
    -------------------------------------------------------
    SELECT @CompanyNo = ISNULL(LTRIM(RTRIM(REPLACE(SemuNo,'-',''))), SPACE(13))
      FROM _TDATaxUnit 
     WHERE CompanySeq = @CompanySeq 
       AND TaxUnit = @TaxUnit 
    

    IF EXISTS (SELECT 1 FROM #TDATaxUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxUnit = @TaxUnit AND (CHARINDEX(CHAR(10), BizType) <> 0 OR CHARINDEX(CHAR(10), BizItem) <> 0 ))  
    BEGIN  
        UPDATE #TDATaxUnit  
           SET BizType  = REPLACE(BizType, CHAR(10), ''),  
               BizItem  = REPLACE(BizItem, CHAR(10), '')  
         WHERE CompanySeq   = @CompanySeq  
           AND TaxUnit      = @TaxUnit  
    END  
  
  
    CREATE TABLE #TTAXVATRptAmt (    
        TaxTermSeq          INT,    
        TaxUnit             INT,    
        Amt01             DECIMAL(19, 5),         Amt02             DECIMAL(19, 5),         Amt03             DECIMAL(19, 5),     
        Amt04             DECIMAL(19, 5),         Amt05             DECIMAL(19, 5),         Amt06             DECIMAL(19, 5), 
        Amt08             DECIMAL(19, 5),         Amt09             DECIMAL(19, 5),         Amt10             DECIMAL(19, 5),         
        Amt12             DECIMAL(19, 5),         Amt14             DECIMAL(19, 5),         Amt21             DECIMAL(19, 5),         
        Amt22             DECIMAL(19, 5),         Amt23             DECIMAL(19, 5),         Amt24             DECIMAL(19, 5),         
        Amt26             DECIMAL(19, 5),         Amt27             DECIMAL(19, 5),         Amt28             DECIMAL(19, 5),         
        Amt29             DECIMAL(19, 5),         Amt31             DECIMAL(19, 5),         Amt32             DECIMAL(19, 5),         
        Amt33             DECIMAL(19, 5),         Amt37             DECIMAL(19, 5),         Amt38             DECIMAL(19, 5),        
        Amt39             DECIMAL(19, 5),         Amt41             DECIMAL(19, 5),         Amt42             DECIMAL(19, 5),         
        Amt43             DECIMAL(19, 5),         Amt44             DECIMAL(19, 5),         Amt46             DECIMAL(19, 5),         
        Amt47             DECIMAL(19, 5),         Amt48             DECIMAL(19, 5),         Amt49             DECIMAL(19, 5),         
        Amt50             DECIMAL(19, 5),         Amt52             DECIMAL(19, 5),         Amt53             DECIMAL(19, 5),         
        Amt55             DECIMAL(19, 5),         Amt56             DECIMAL(19, 5),         Amt57             DECIMAL(19, 5),         
        Amt58             DECIMAL(19, 5),         Amt59             DECIMAL(19, 5),         Amt16             DECIMAL(19, 5),         
        Amt43_1           DECIMAL(19, 5),         Amt32_1           DECIMAL(19, 5),         Amt46_1           DECIMAL(19, 5),         
        Amt116            DECIMAL(19, 5),         Amt118            DECIMAL(19, 5),         Amt121            DECIMAL(19, 5),         
        Amt123            DECIMAL(19, 5),         Amt07             DECIMAL(19, 5),         Amt11             DECIMAL(19, 5),         
        Amt13             DECIMAL(19, 5),         Amt25             DECIMAL(19, 5),         Amt30             DECIMAL(19, 5),         
        Amt36             DECIMAL(19, 5),         Amt40             DECIMAL(19, 5),         Amt45             DECIMAL(19, 5),         
        Amt54             DECIMAL(19, 5),         Amt60             DECIMAL(19, 5),         Amt124            DECIMAL(19, 5),         
        Amt126            DECIMAL(19, 5),         Amt128            DECIMAL(19, 5),         Amt129            DECIMAL(19, 5),
        -- 130,131 2012��1�⿹�� �Ű� �߰�
        Amt130            DECIMAL(19, 5),         Amt131            DECIMAL(19, 5),             
        -- 2013�� 1�� ����
        Amt47_1           DECIMAL(19, 5),         Amt48_1           DECIMAL(19, 5),         Amt48_2           DECIMAL(19, 5),         
        Amt48_3           DECIMAL(19, 5),     Amt48_4           DECIMAL(19, 5),         Amt61             DECIMAL(19, 5),
        Amt132            DECIMAL(19, 5),         Amt133            DECIMAL(19, 5),         Amt64             DECIMAL(19, 5),
        Amt65             DECIMAL(19, 5),         Amt51             DECIMAL(19, 5) )
  
    CREATE TABLE #TTAXVATRptTax (    
        TaxTermSeq          INT,    
        TaxUnit             INT,               
        Tax01             DECIMAL(19, 5),        Tax02             DECIMAL(19, 5),        Tax05             DECIMAL(19, 5),        
        Tax06             DECIMAL(19, 5),        Tax08             DECIMAL(19, 5),        Tax08_1           DECIMAL(19, 5),
        Tax09             DECIMAL(19, 5),        
        Tax10             DECIMAL(19, 5),        Tax12             DECIMAL(19, 5),        Tax14             DECIMAL(19, 5),    
        Tax15             DECIMAL(19, 5),        Tax16             DECIMAL(19, 5),        Tax17             DECIMAL(19, 5),    
        Tax19             DECIMAL(19, 5),        Tax26             DECIMAL(19, 5),        Tax27             DECIMAL(19, 5),    
        Tax31             DECIMAL(19, 5),        Tax32             DECIMAL(19, 5),        Tax33             DECIMAL(19, 5),    
        Tax34             DECIMAL(19, 5),        Tax35             DECIMAL(19, 5),        Tax37             DECIMAL(19, 5),    
        Tax38             DECIMAL(19, 5),        Tax39             DECIMAL(19, 5),        Tax41             DECIMAL(19, 5),    
        Tax42             DECIMAL(19, 5),        Tax43             DECIMAL(19, 5),        Tax44             DECIMAL(19, 5),    
        Tax46             DECIMAL(19, 5),        Tax47             DECIMAL(19, 5),        Tax48             DECIMAL(19, 5),    
        Tax49             DECIMAL(19, 5),        Tax50             DECIMAL(19, 5),        Tax57             DECIMAL(19, 5),    
        Tax58             DECIMAL(19, 5),        Tax59             DECIMAL(19, 5),        PaymentTax        DECIMAL(19, 5),    
        Tax43_1           DECIMAL(19, 5),        Tax32_1           DECIMAL(19, 5),        Tax46_1           DECIMAL(19, 5),    
        Tax15_1           DECIMAL(19, 5),        Tax117            DECIMAL(19, 5),        Tax119            DECIMAL(19, 5),    
        Tax120            DECIMAL(19, 5),        Tax122            DECIMAL(19, 5),        Tax07             DECIMAL(19, 5),  
        Tax11             DECIMAL(19, 5),        Tax13             DECIMAL(19, 5),        Tax18             DECIMAL(19, 5),  
        Tax20             DECIMAL(19, 5),        Tax30             DECIMAL(19, 5),        Tax36             DECIMAL(19, 5),  
        Tax40             DECIMAL(19, 5),        Tax45             DECIMAL(19, 5),        Tax51             DECIMAL(19, 5),  
        Tax60             DECIMAL(19, 5),        TaxDa             DECIMAL(19, 5),        Tax125            DECIMAL(19, 5),
        Tax127            DECIMAL(19, 5),        Tax128            DECIMAL(19, 5),        Tax129            DECIMAL(19, 5),
        -- 130,131 2012��1�⿹�� �Ű� �߰�
        Tax130            DECIMAL(19, 5),        Tax131            DECIMAL(19, 5),
        -- 2013�� 1�� ����
        Tax47_1           DECIMAL(19, 5),         Tax48_1           DECIMAL(19, 5),         Tax48_2           DECIMAL(19, 5),         
        Tax48_3           DECIMAL(19, 5),         Tax48_4           DECIMAL(19, 5),         Tax61             DECIMAL(19, 5),
        Tax132            DECIMAL(19, 5),         Tax133            DECIMAL(19, 5),         Tax62             DECIMAL(19, 5),
        Tax63             DECIMAL(19, 5),         Tax64             DECIMAL(19, 5),         Tax65             DECIMAL(19, 5))
    
    INSERT INTO #TTAXVATRptAmt (TaxTermSeq , TaxUnit ,    
                                Amt01    , Amt02    , Amt03    , Amt04    , Amt05    , Amt06    , 
                                Amt08    , Amt09    , Amt10    , Amt12    , Amt14    , Amt21    , 
                                Amt22    , Amt23    , Amt24    , Amt26    , Amt27    , Amt28    , 
                                Amt29    , Amt31    , Amt32    , Amt33    , Amt37    , Amt38    , 
                                Amt39    , Amt41    , Amt42    , Amt43    , Amt44    , Amt46    , 
                                Amt47    , Amt48    , Amt49    , Amt50    , Amt52    , Amt53    , 
                                Amt55    , Amt56    , Amt57    , Amt58    , Amt59    , Amt16    , 
                                Amt43_1  , Amt32_1  , Amt46_1  , Amt116   , Amt118   , Amt121   , 
                                Amt123   , Amt07    , Amt11    , Amt13    , Amt25    , Amt30    , 
                                Amt36    , Amt40    , Amt45    , Amt54    , Amt60    , Amt124   , 
                                Amt126   , Amt128   , Amt129   , Amt130   , Amt131   , Amt47_1  , 
                                Amt48_1  , Amt48_2  , Amt48_3  , Amt48_4  , Amt61    , Amt132   ,
                                Amt133   , Amt64    , Amt65    , Amt51 )
        SELECT    
        @TaxTermSeq, @TaxUnit,    
        -- Amt01    , Amt02  , Amt03 ,    Amt04    , Amt05  , Amt06   , Amt08 ,    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1010'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1030'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1040'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1050'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1060'), 0),   
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1070'), 0),         
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1090'), 0),    
        -- Amt09    , Amt10  , Amt12 ,    Amt14    , Amt21  , Amt22 ,    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1100'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1130'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1150'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1220'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptBizAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '3010'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptBizAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '3020'), 0),    
        -- Amt23    , Amt24  , Amt26 ,    Amt27    , Amt28  , Amt29 ,    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptBizAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '3030'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptBizAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '3040'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5010'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5020'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5030'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5040'), 0),    
        -- Amt31    , Amt32  , Amt33 ,    Amt37    , Amt38  , Amt39 ,    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5090'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5100'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5110'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5170'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5180'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5190'), 0),    
        -- Amt41    , Amt42  , Amt43 ,    Amt44    , Amt46  , Amt47 ,    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5220'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5210'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5230'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5240'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5260'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5280'), 0),    
        -- Amt48    , Amt49  , Amt50 ,    Amt52    , Amt53  , Amt55 ,    
        ISNULL((SELECT SUM(ISNULL(SpplyAmt, 0)) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo IN ('5290', '5291', '5292', '5293')), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5300'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5310'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptBizAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '7010'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptBizAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '7020'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '8010'), 0),    
        -- Amt56    , Amt57  , Amt58 ,    Amt59    , Amt16  , Amt43_1 ,    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '8020'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1110'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5060'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5070'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = 'XXXX'), 0), -- ????    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = 'XXXX'), 0), -- ????    
        -- Amt32_1    , Amt46_1 , Amt116 ,    Amt118    , Amt121  , Amt123 )    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5120'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5270'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1025'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5095'), 0),  
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5276'), 0),   
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptBizAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '7025'), 0),   
        -- Amt07    , Amt11   , Amt13  ,   Amt25    , Amt30   , Amt36   ,  
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1080'), 0),            
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1140'), 0),  
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1080'), 0),  
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptBizAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '3050'), 0),  
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5050'), 0),  
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5160'), 0),  
        -- Amt40    , Amt45   , Amt54  ,   Amt60
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5200'), 0),  
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5250'), 0),  
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptBizAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '7030'), 0),  
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5080'), 0),            
        -- Amt124   , Amt126  , Amt128  , Amt129
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5277'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5270'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5275'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5320'), 0),
        -- Amt130   , Amt131  , Amt47_1 , Amt48_1
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5225'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5273'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5281'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5290'), 0),        
        -- Amt48_2  , Amt48_3 , Amt48_4 , Amt61
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5291'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5292'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5293'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5321'), 0),
        -- Amt132, Amt133   , Amt64    , Amt65    , Amt51
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1020'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1120'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5325'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5327'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5190'), 0)
    INSERT INTO #TTAXVATRptTax (TaxTermSeq, TaxUnit  ,    
                                Tax01   , Tax02    , Tax05     , Tax06     , Tax08   , Tax08_1    , Tax09      ,    -- Tax08_1 : 2016.2��Ȯ�� :   ������ ���Ժ� �������� (10-1) �߰� : dhkim3 2016.06.27   
                                Tax10   , Tax12    , Tax14     , Tax15     , Tax16   , Tax17      ,    
                                Tax19   , Tax26    , Tax27     , Tax31     , Tax32   , Tax33      ,    
                                Tax34   , Tax35    , Tax37     , Tax38     , Tax39   , Tax41  ,    
                                Tax42   , Tax43    , Tax44     , Tax46     , Tax47   , Tax48      ,    
                                Tax49   , Tax50    , Tax57     , Tax58     , Tax59   , PaymentTax ,    
                                Tax43_1 , Tax32_1  , Tax46_1   , Tax15_1   , Tax117  , Tax119     ,    
                                Tax120  , Tax122   , Tax07     , Tax11     , Tax13   , Tax18      ,  
                                Tax20   , Tax30    , Tax36     , Tax40     , Tax45   , Tax51      ,  
                                Tax60   , TaxDa    , Tax125    , Tax127    , Tax128  , Tax129     ,
                                Tax130  , Tax131   , Tax47_1   , Tax48_1   , Tax48_2 , Tax48_3    ,
                                Tax48_4 , Tax61    , Tax132    , Tax133    , Tax62   , Tax63      ,
                                Tax64   , Tax65)
        SELECT    
        @TaxTermSeq, @TaxUnit,    
        -- Tax01   , Tax02  , Tax05     , Tax06       , Tax08  , Tax08_1, Tax09     ,     
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1010'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1030'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1060'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1070'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1090'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1095'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1100'), 0),    
        -- Tax10   , Tax12  , Tax14     , Tax15       , Tax16  , Tax17     ,    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1130'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1150'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1220'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1210'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1190'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1180'), 0),    
        -- Tax19   , Tax26  , Tax27     , Tax31       , Tax32  , Tax33     ,    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1240'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5010'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5020'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5090'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5100'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5110'), 0),    
        -- Tax34   , Tax35  , Tax37     , Tax38       , Tax39  , Tax41     ,    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5140'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5150'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5170'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5180'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5190'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5220'), 0),    
        -- Tax42   , Tax43  , Tax44     , Tax46       , Tax47  , Tax48     ,    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5210'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5230'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5240'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5260'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5280'), 0),    
        ISNULL((SELECT SUM(ISNULL(VATAmt, 0)) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo IN ('5290', '5291', '5292', '5293')), 0),    
        -- Tax49   , Tax50  , Tax57     , Tax58       , Tax59  , PaymentTax ,    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5300'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5310'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1110'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5060'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5070'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1260'), 0),    
        -- Tax43_1   , Tax32_1  , Tax46_1     , Tax15_1   , Tax117  , Tax119     ,    
   ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = 'XXXX'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5120'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5270'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1230'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1025'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5095'), 0),    
        -- Tax120   , Tax122  )    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5215'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5276'), 0),  
        -- Tax07     , Tax11     , Tax13   , Tax18      ,  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1080'), 0),  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1140'), 0),  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1160'), 0),  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1200'), 0),  
        -- Tax20   , Tax30    , Tax36     , Tax40     , Tax45   , Tax51      ,  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1250'), 0),  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5050'), 0),  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5160'), 0),  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5200'), 0),  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5250'), 0),  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5330'), 0),  
        -- Tax60   , TaxDa  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5080'), 0),  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1170'), 0),  
        -- Tax125   , Tax127,   Tax128,  Tax129
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5277'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5270'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5275'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5320'), 0),
        -- Tax130   , Tax131,   Tax47_1,  Tax48_1
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5225'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5273'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5281'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5290'), 0),                     
        -- Tax48_2  , Tax48_3,  Tax48_4,  Tax61  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5291'), 0),        
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5292'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5293'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5321'), 0),
        -- Tax132    , Tax133    , Tax62   , Tax63      ,Tax64   , Tax65
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1020'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1120'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1225'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5155'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5325'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5327'), 0)
        
    DECLARE @TermKind           CHAR(1),        -- �������         '1', '2' (���)
            @ProOrFix           CHAR(1),        -- ����, Ȯ�� ����  '1', '2' (1:����, 2:Ȯ��)
            @TermKind_Bill      CHAR(1),        -- ��꼭 �������
            @ProOrFix_Bill      CHAR(1),        -- ��꼭 ����, Ȯ�� ����
            @YearHalfMM         CHAR(1),        -- �ݱ⳻��
            @MinPaymentTax      DECIMAL(19,5),  -- (26) ����.�����Ͽ� ������ ����(ȯ�޹��� ����)
            @BankCode           CHAR(3),        -- �����ڵ�
            @BankName           VARCHAR(30),    -- �����
            @BankAccNo          VARCHAR(20),    -- ���¹�ȣ
            @BankHQName         NVARCHAR(100),  -- �������
            @RtnTaxKind         CHAR(2),        -- 74. ȯ�ޱ���
            @CloseDate          CHAR(8),        -- 79. �������
            @TaxationType       CHAR(1),        -- 83. �Ϲݰ����ڱ���
            @RtnTaxType         CHAR(1)         -- 84. ����ȯ����ұ���
    ---------------------------------------------------------------      
    --��� �� ����, Ȯ�� ���� / (��꼭�հ�ǥ�� ������ ���� �ʿ�)          
    ---------------------------------------------------------------      
    IF      (SUBSTRING(@TaxFrDate, 5, 2) >= '01' AND SUBSTRING(@TaxFrDate, 5, 2) <= '03')   SELECT @TermKind = '1', @ProOrFix = '1' -- 1�� ����
    ELSE IF (SUBSTRING(@TaxFrDate, 5, 2) >= '04' AND SUBSTRING(@TaxFrDate, 5, 2) <= '06')   SELECT @TermKind = '1', @ProOrFix = '2' -- 1�� Ȯ��
    ELSE IF (SUBSTRING(@TaxFrDate, 5, 2) >= '07' AND SUBSTRING(@TaxFrDate, 5, 2) <= '09')   SELECT @TermKind = '2', @ProOrFix = '1' -- 2�� ����
    ELSE IF (SUBSTRING(@TaxFrDate, 5, 2) >= '10' AND SUBSTRING(@TaxFrDate, 5, 2) <= '12')   SELECT @TermKind = '2', @ProOrFix = '2' -- 2�� ����
  
    IF      (SUBSTRING(@BillToDate, 5, 2) >= '01' AND SUBSTRING(@BillToDate, 5, 2) <= '03') SELECT @TermKind_Bill = '1', @ProOrFix_Bill = '1' -- 1�� ����
    ELSE IF (SUBSTRING(@BillToDate, 5, 2) >= '04' AND SUBSTRING(@BillToDate, 5, 2) <= '06') SELECT @TermKind_Bill = '1', @ProOrFix_Bill = '2' -- 1�� Ȯ��
    ELSE IF (SUBSTRING(@BillToDate, 5, 2) >= '07' AND SUBSTRING(@BillToDate, 5, 2) <= '09') SELECT @TermKind_Bill = '2', @ProOrFix_Bill = '1' -- 2�� ����
    ELSE IF (SUBSTRING(@BillToDate, 5, 2) >= '10' AND SUBSTRING(@BillToDate, 5, 2) <= '12') SELECT @TermKind_Bill = '2', @ProOrFix_Bill = '2' -- 2�� ����
  
    ---------------------------------------------------------------
    -- ����Ű� �ϴ� ������� ��� �Ű���(@ProOrFix) : Ȯ��(2)
    ---------------------------------------------------------------
    IF @BizCancelDate <> ''    
    BEGIN    
        SELECT @ProOrFix = '2', @ProOrFix_Bill = '2'
        SELECT @TaxToDate = @BizCancelDate
    END
    ----------------------------------------------------      
    -- �ݱ⳻ ������ : 1/2/3/4/5/6 (��, ���� 3, Ȯ�� 6)
    ----------------------------------------------------
    IF DATEDIFF(mm, @TaxFrDate, @TaxToDate) <= 2 AND (SUBSTRING(@TaxToDate, 5, 2) NOT IN ('06', '12') ) -- Ȯ���Ű� �ƴ� ���
    BEGIN  
        SELECT @YearHalfMM = ( CASE WHEN CONVERT(INT, SUBSTRING(@TaxToDate, 5, 2)) <= 6
                                    THEN CONVERT(INT, SUBSTRING(@TaxToDate, 5, 2))
                                    ELSE CONVERT(INT, SUBSTRING(@TaxToDate, 5, 2)) - 6 END )    
    END  
    ELSE    
    BEGIN  
        SELECT @YearHalfMM = CASE WHEN @Term_SMTaxationType = 4090001 THEN '3' ELSE '6' END      --  ���� 3 , Ȯ�� 6
    END  
    SELECT @YearHalfMM = ISNULL(@YearHalfMM,'')
      
    -----------------------      
    --�ΰ���ȯ�� ��������      
    -----------------------      
    SELECT @BankCode    = CONVERT(CHAR(3), ISNULL(MV.ValueText, ''))        , -- �����ڵ�    
           @BankName    = CONVERT(VARCHAR(30), ISNULL(B.BankName   , ''))   , -- �����
           @BankHQName  = ISNULL(M.MinorName, '')                           , -- ���������
           @BankAccNo   = dbo._FCOMDecrypt(C.BankAccNo, '_TDABankAcc', 'BankAccNo', @CompanySeq)  -- ȯ�ް���
      FROM _TTAXVatRpt AS A WITH(NOLOCK)
                            LEFT OUTER JOIN _TDABank AS B WITH(NOLOCK)
                              ON A.CompanySeq   = B.CompanySeq    
                             AND A.BankSeq      = B.BankSeq    
                            LEFT OUTER JOIN _TDABankAcc AS C WITH(NOLOCK)
                              ON A.CompanySeq   = C.CompanySeq    
                             AND A.AccNoSeq     = C.BankAccSeq    
                            LEFT OUTER JOIN _TDAUMinor AS M WITH(NOLOCK)
                              ON A.CompanySeq   = M.CompanySeq    
                             AND B.BankHQ       = M.MinorSeq    
                             AND M.MajorSeq     = 4003    
                            LEFT OUTER JOIN _TDAUMinorValue AS MV WITH(NOLOCK)
                              ON A.CompanySeq   = MV.CompanySeq    
                             AND M.MinorSeq     = MV.MinorSeq    
                             AND MV.MajorSeq    = 4003    
                             AND MV.Serl        = 1001 --- �����ڵ�
     WHERE A.CompanySeq     = @CompanySeq    
    AND A.TaxTermSeq     = @TaxTermSeq    
       AND A.TaxUnit        = @TaxUnit
    SELECT @BankCode    = ISNULL(@BankCode      , ''),    
           @BankName    = ISNULL(@BankName      , ''),    
           @BankAccNo   = ISNULL(@BankAccNo     , '')        
       
    -- �ϳ�����/��ȯ���� ���տ� ���� �ϳ������ڵ� ��ü
    IF ISNULL(@BankCode, '') = '005'    
        SELECT @BankCode = '081'    -- �ϳ�����
    IF @WorkingTag = ''
    BEGIN
        IF (@BankAccNo <> '' AND @BankName > '' AND @BankCode = '')
        BEGIN
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  1248               , -- @1�� @2��(��) �Է��ϼ���. (SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%�Է�%')  
                                  @LanguageSeq       ,
                                  0     ,   '@1'     ,          -- SELECT * FROM _TCADictionary WHERE Word LIKE '%�ŷ�����%'
                                  31498 ,   '�����ڵ�(FBS)'     -- SELECT * FROM _TCADictionary WHERE Word LIKE '%�����ڵ�%'        
            SELECT -1 AS tmp_Seq, '�ΰ����Ű�-�ŷ������� ������� ' + REPLACE(@Results, '@1', '[' + @BankHQName + ']') AS tmp_file
            RETURN
        
        END
    
        IF (NOT(@BankCode = '' AND @BankAccNo = '')) AND (NOT(@BankCode <> '' AND @BankAccNo <> ''))  
        BEGIN  
            SELECT @Results = '�ΰ����Ű��� �ŷ������ ���¹�ȣ�� ��� �ְų� ��� ����� �մϴ�.'
            SELECT -1 AS tmp_Seq, @Results AS tmp_file
            RETURN
        END
    END
      
    --===========================================================================================
    -- 83. �Ϲݰ����ڱ���  
    -- 0 : ����ڴ����Ű�.�����ڰ� �ƴ� �Ϲ� �����
    -- 2 : �Ѱ����λ������ �ֻ����    
    -- 3 : �Ѱ����λ������ �������
    -- 5 : ����ڴ���������������    
    --===========================================================================================  
    IF @Env4016 = 4125002 AND (LEFT(@TaxFrDate, 6) + '01') >= @Env4017  -- ����ڴ����Ű�
    BEGIN    
        SELECT @TaxationType = '5'    
    END
    ELSE
    BEGIN
        SELECT @TaxationType = CASE @Unit_SMTaxationType    -- �Ϲݰ����ڱ���
                                    WHEN 4128001 THEN '0'       -- �Ϲݻ����
                                    WHEN 4128002 THEN '2'       -- �Ѱ����� �ֻ����
                                    WHEN 4128003 THEN '3'       -- �Ѱ����� �������
                                                 ELSE '0' END   -- �Ϲݻ����
    END
    --===========================================================================================
    -- 74. ȯ�ޱ����ڵ�
    -- �Ϲ�ȯ��                     [10] : ������ȯ��/�ü�����ȯ�޿� �ش���� �ʴ� ���
    -- ������ȯ��                   [20]     : (5,6) ������ ������ �ִ� ���
    -- �ü�����ȯ��                 [30] : (5,6) ������ ������ ���� (11)�����ڻ� ������ �ִ� ���
    -- �Ѱ������ֻ����ȯ��         [40] : �Ѱ�����ȯ�޼����� 0 �̻� & (26) �����������Ҽ����� 0 �̸�
    -- �Ѱ������ֻ�����Ϲ�ȯ��     [41] : �Ѱ�����ȯ�޼����� 0 �̸� & ����ȯ��(������ �� �ü�����ȯ��)�� �ƴ� ���
    -- �Ѱ������ֻ���ڿ�����ȯ��   [42] : �Ѱ�����ȯ�޼����� 0 �̸� & ������ ȯ��
    -- �Ѱ������ֻ���ڽü�����ȯ�� [43] : �Ѱ�����ȯ�޼����� 0 �̸� & �ü�����ȯ��
    -- 84. ����ȯ����ұ���
    -- �ü�����ȯ��(30)�� �ش������ ȯ�޹��� ���� ��� �Ϲ�ȯ��(10) & ����ȯ�����(1)
    -- �Ѱ����νü�����ȯ��(43)�� ��� �Ѱ��Ϲ�ȯ��(41) & ����ȯ�����(1)
    -- ��, ������ȯ��(20) ����ȯ����� �Ұ�
    --===========================================================================================
    SELECT @RtnTaxKind  = CASE ISNULL(SMRtnKind, 0)         -- ȯ�ޱ���
                            WHEN 0       THEN '  '        -- ȯ�޾���    
                            WHEN 4112001 THEN '  '        -- ȯ�޾���    
                            WHEN 4112002 THEN '10'        -- �Ϲ�ȯ��    
                            WHEN 4112003 THEN '20'        -- ������ȯ��  
                            WHEN 4112004 THEN '30' END,   -- �ü�����ȯ��            
           @RtnTaxType  = CASE WHEN ISNULL(IsNotEarlyRefund, '') = '' THEN '0'
                               ELSE ISNULL(IsNotEarlyRefund, '')
                          END,                              -- ����ȯ����ұ���(default '0')
           @CloseDate   = ISNULL(CloseDate  , '')           -- �������
      FROM _TTAXVatRpt WITH(NOLOCK)
     WHERE CompanySeq   = @CompanySeq    
       AND TaxTermSeq   = @TaxTermSeq    
       AND TaxUnit      = @TaxUnit    
    -----------------------------------
    -- �Ѱ����� �ֻ������ ���
    -----------------------------------
    IF @TaxationType = '2'
    BEGIN
        -------------------------------------------------
        -- (26) ����.�����Ͽ� ������ ����(ȯ�޹��� ����)
        -------------------------------------------------    
        SELECT @MinPaymentTax = Tax20
          FROM #TTAXVATRptTax
         WHERE TaxTermSeq   = @TaxTermSeq
           AND TaxUnit      = @TaxUnit
        SELECT @RtnTaxKind = CASE WHEN @RtnTaxKind =  '  ' 
                                   AND @MinPaymentTax < 0  THEN '40'  -- �Ѱ������ֻ����ȯ�� (�Ѱ����μ��� > 0 & (26) �����������Ҽ��� < 0)
                                  WHEN @RtnTaxKind =  '10' THEN '41'  -- �Ѱ������ֻ�����Ϲ�ȯ��
                                  WHEN @RtnTaxKind =  '20' THEN '42'  -- �Ѱ������ֻ���ڿ�����ȯ��
                                  WHEN @RtnTaxKind =  '30' THEN '43'  -- �Ѱ������ֻ���ڽü�����ȯ��
                             ELSE @RtnTaxKind END
    END
    

    CREATE TABLE #CREATEFile_tmp (      
        tmp_seq     INT IDENTITY,      
        tmp_file    VARCHAR(3000),      
        tmp_size    INT )  
  
/***************************************************************************************************************************    
1. �ΰ���ġ�� Header    
    
01. �ڷᱸ��(2) : 11(�Ϲ�)    
02. �����ڵ�(4) : I103200 / V101(�Ϲݰ����� �ΰ��� �Ű�)
03. ������ID(13) : ����ڵ�Ϲ�ȣ    
04. �����ڵ�(2) : 41(FIX)    
05. �Ű����ڵ�(2)         -- ����Ű� �ϴ� ��쿡�� �����Ⱓ�� Ȯ���Ű�� �Ű��Ѵ�.    
06. �Ű��л��ڵ�(2)
07. �����Ⱓ_���(��)(6)    
08. �Ű������ڵ�(3)
09. �����ID(20)    
10. �����ڹ�ȣ(13) : �ֹε�Ϲ�ȣ(����) �Ǵ� ���ε�Ϲ�ȣ(����)    
11. �����븮�μ���(30)    
12. �����븮����ȭ��ȣ(4) - ������ȣ    
13. �����븮����ȭ��ȣ(5) - ����    
14. �����븮����ȭ��ȣ(5) - ������ ��ȣ    
15. ��ȣ(���θ�)(30)    
16. ����(��ǥ�ڸ�)(30)    
17. ����������(70)    
18. �������ȭ��ȣ(14)    
19. ������ּ�(70)    
20. �������ȭ��ȣ(14)    
21. ���¸�(30)    
22. ������(50)    
23. �����ڵ�(7)    
24. �����Ⱓ(8) : ������    
25. �����Ⱓ(8) : ������    
26. �ۼ�����(8)    
27. �����Ű���(1)    
28. ������޴��ȣ(14)    
29. �������α׷��ڵ�(4)    
30. �����븮�λ���ڹ�ȣ(13)    
31. ���ڸ����ּ�(50)    
32. ����(65)    
*****************************************************************************************************************************/   
IF @WorkingTag = ''  
BEGIN  
    INSERT INTO #CREATEFile_tmp (tmp_File, tmp_size)  
    SELECT '11'  
          + 'I103200'                                                   --02. �����ڵ�(FIX)    
          + CONVERT(VARCHAR(13), REPLACE(TaxNo, '-', '')) + SPACE(13 - DATALENGTH(CONVERT(VARCHAR(13), REPLACE(TaxNo, '-', ''))))   --03. ������ID    
          + '41'                                                        --04. ���������ڵ�(FIX)    
          + CASE WHEN @ProOrFix = '1' THEN '03' ELSE '01' END           --05. �Ű���
          + '01'                                                        --06. �Ű��л��ڵ� 
          + SUBSTRING(@TaxToDate, 1, 4) + RIGHT('00' + @TermKind, 2)    --07. �����Ⱓ_��� 
          + CASE WHEN @CloseDate > ''                THEN 'C07'      -- ����Ű�� C07 (���̴� C03)
                 WHEN @Term_SMTaxationType = 4090001 THEN 'C17'      -- ���� �Ϲ� �Ű�
                 WHEN @Term_SMTaxationType = 4090002 THEN 'C07'      -- Ȯ�� �Ϲ� �Ű�
                 WHEN @Term_SMTaxationType = 4090004 THEN 'C07'      -- Ȯ�� �Ϲ� �Ű�
                 WHEN @Term_SMTaxationType = 4090003 AND SUBSTRING(@TaxToDate, 5, 2) = '03' THEN 'C17'           -- ���� �Ϲ� �Ű�
                 WHEN @Term_SMTaxationType = 4090003 AND SUBSTRING(@TaxToDate, 5, 2) = '12' THEN 'C07'           -- Ȯ�� �Ϲ� �Ű�
                 WHEN @Term_SMTaxationType = 4090003 AND SUBSTRING(@TaxToDate, 5, 2) IN ('01', '07') THEN 'C15'  -- ���� 1,7�� ���� �Ű�
                 WHEN @Term_SMTaxationType = 4090003 AND SUBSTRING(@TaxToDate, 5, 2) IN ('02', '08') THEN 'C16'  -- ���� 2,8�� ���� �Ű�
             WHEN @Term_SMTaxationType = 4090003 AND SUBSTRING(@TaxToDate, 5, 2) IN ('04', '10') THEN 'C05'  -- Ȯ�� 4,10�� ���� �Ű�
                 WHEN @Term_SMTaxationType = 4090003 AND SUBSTRING(@TaxToDate, 5, 2) IN ('05', '11') THEN 'C06'  -- Ȯ�� 5,11�� ���� �Ű�                 
                 ELSE SPACE(3)
            END      --8.�Ű������ڵ�
          + CONVERT(VARCHAR(20), LTRIM(RTRIM(HomeTaxID))) + SPACE(20 - DATALENGTH(CONVERT(VARCHAR(20), LTRIM(RTRIM(HomeTaxID))))) --9. �����ID    
          + CONVERT(VARCHAR(13), @CompanyNo) + SPACE(13 - DATALENGTH(CONVERT(VARCHAR(13), @CompanyNo)))             --10. �����ڹ�ȣ    
          + SPACE(30)                                                   --11. �����븮�μ���    
          + SPACE(14)                                                   --12.13.14. �����븮����ȭ��ȣ    
          + CONVERT(VARCHAR(30), LTRIM(RTRIM( CASE WHEN ISNULL(BillTaxName,'') <> '' THEN BillTaxName ELSE TaxName END  )))    
                    + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM( CASE WHEN ISNULL(BillTaxName,'') <> '' THEN BillTaxName ELSE TaxName END  )))))   --15. ��ȣ(��꼭��ȣ�� ���) 2009.04.03 by �ڱټ�    
          + CONVERT(VARCHAR(30), LTRIM(RTRIM(Owner ))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(Owner )))))   --16. ����(��ǥ�ڸ�)    
          + CONVERT(VARCHAR(70), LTRIM(RTRIM(@Addr1))) + SPACE(70 - DATALENGTH(CONVERT(VARCHAR(70), LTRIM(RTRIM(@Addr1)))))   --17. ����������    
          + CONVERT(VARCHAR(14), LTRIM(RTRIM(dbo._FnTaxTelChk(TelNo))))   + SPACE(14 - DATALENGTH(CONVERT(VARCHAR(14), LTRIM(RTRIM(dbo._FnTaxTelChk(TelNo))))))   --18. ��ȭ��ȣ    [��ȭ��ȣ]�׸��� ����,�������� ���ڴ� �Է¸���. (,-���� Ư�����ڴ� ������ �� ����.    
          + SPACE(70)		                                --19. ����� �ּ�    
          + SPACE(14)                                       --20. �������ȭ��ȣ    
          + CONVERT(VARCHAR(30), LTRIM(RTRIM(BizType     ))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(BizType     ))))) --21. ���¸�    
          + CONVERT(VARCHAR(50), LTRIM(RTRIM(BizItem     ))) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), LTRIM(RTRIM(BizItem     ))))) --22. �����    
          + CONVERT(VARCHAR(07), LTRIM(RTRIM(TaxBizTypeNo))) + SPACE(7  - DATALENGTH(CONVERT(VARCHAR(07), LTRIM(RTRIM(TaxBizTypeNo))))) --23. �־����ڵ�    
          + CONVERT(VARCHAR(8), @TaxFrDate) + SPACE(8 - DATALENGTH(CONVERT(VARCHAR(8), @TaxFrDate)))    --24. �����Ⱓ(������)    
          + CONVERT(VARCHAR(8), @TaxToDate) + SPACE(8 - DATALENGTH(CONVERT(VARCHAR(8), @TaxToDate)))    --25. �����Ⱓ(������)    
          + CONVERT(VARCHAR(8), @RptDate  ) + SPACE(8 - DATALENGTH(CONVERT(VARCHAR(8), @RptDate  )))    --26. �ۼ�����    
          + 'N'                 --27. �����Ű���(Fix)
          + CONVERT(VARCHAR(14), LTRIM(RTRIM(ISNULL(CellPhone,'')))) + SPACE(14 - DATALENGTH(CONVERT(VARCHAR(14), LTRIM(RTRIM(ISNULL(CellPhone,'')))))) --28. ������޴���ȭ    
          + '9000'              --29. �������α׷��ڵ�    
          + SPACE(13)           --30. �����븮�λ���ڹ�ȣ    
          + CONVERT(VARCHAR(50), LTRIM(RTRIM(EMail)))     + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), LTRIM(RTRIM(EMail)))))  --31. ���ڸ����ּ�    
          + SPACE(65)           --32. ����  
          , 600    
      FROM #TDATaxUnit WITH(NOLOCK)
     WHERE CompanySeq = @CompanySeq  
       AND TaxUnit    = @TaxUnit  
END        
  
/***************************************************************************************************************************    
2. �ΰ���ġ��_�ϹݽŰ�    
01. �ڷᱸ��    (02)
02. �����ڵ�    (07)
03. ����������ݰ�꼭�߱ޱݾ�   (15)
04. ����������ݰ�꼭�߱޼���   (13)
05. ������������ڹ��༼�ݰ�꼭�ݾ�    (13)
06. ������������ڹ��༼�ݰ�꼭����    (13)
07. �������ī�����ݹ���ݾ�    (15)
08. �������ī�����ݹ��༼��    (15)
09. ���������Ÿ�ݾ�    (13)
10. ���������Ÿ����    (13)
11. ���⿵�������ݰ�꼭�߱ޱݾ�  (13)
12. ���⿵������Ÿ�ݾ�   (15)
13. ���⿹�������հ�ݾ�  (13)
14. ���⿹�������հ輼��  (13)
15. �����������⼼�ݰ�꼭�ݾ�   (13)
16. �����������⼼�ݰ�꼭����   (13)
17. �����������������Ÿ�ݾ�    (13)
18. �����������������Ÿ����    (13)
19. �����������⿵�������ݰ�꼭�ݾ�    (13)
20. �����������⿵������Ÿ�ݾ�   (13)
21. ��������������հ�ݾ�    (13)
22. ��������������հ輼��    (13)
23. �����ռ��װ�������  (13)
24. ����ǥ�رݾ�  (15)
25. ���⼼��    (15)
26. ���Լ��ݰ�꼭�����Ϲݱݾ�   (15)
27. ���Լ��ݰ�꼭�����Ϲݼ���   (13)
28. ���Լ��ݰ�꼭��������ڻ�ݾ� (13)
29. ���Լ��ݰ�꼭��������ڻ꼼�� (13)
30. ���Կ��������հ�ݾ�  (13)
31. ���Կ��������հ輼��  (13)
32. �����������ԽŰ��ݰ�꼭�ݾ� (13)
33. �����������ԽŰ��ݰ�꼭���� (13)
34. �����������Ա�Ÿ�����ݾ�    (13)
35. �����������Ա�Ÿ��������    (13)
36. �����������Ը��հ�ݾ�    (13)
37. �����������Ը��հ輼��    (13)
38. �����ڹ��༼�ݰ�꼭���Աݾ�  (13)
39. �����ڹ��༼�ݰ�꼭���Լ���  (13)
40. ���Ա�Ÿ�������Աݾ�  (13)
41. ���Ա�Ÿ�������Լ���  (13)
42. �׹��ǰ������Ը��հ�ݾ�   (13)
43. �׹��ǰ������Ը��հ輼��   (13)
44. ���Լ����հ�ݾ�    (15)
45. ���Լ����հ輼��    (13)
46. �����������Ҹ����հ�ݾ�    (13)
47. �����������Ҹ����հ輼��    (13)
48. �����������Ҹ��Աݾ�  (13)
49. �����������Ҹ��Լ���  (13)
50. �����������Ұ�����Ը鼼����ݾ�    (13)
51. �����������Ұ�����Ը鼼�������    (13)
52. �����������Ҵ��ó�бݾ�    (13)
53. �����������Ҵ��ó�м���    (13)
54. �����������Ҹ��Ը��հ�ݾ�  (13)
55. �����������Ҹ��Ը��հ輼��  (13)
56. �����հ�ݾ�  (15)
57. �����հ輼��  (13)
58. ����(ȯ��)����    (13)
59. �׹��ǰ氨��������   (15)
60. �׹��ǰ氨�������հ輼��   (15)
61. �氨�����հ輼��    (13)
62. �����Ű��ȯ�޼���   (13)
63. ������������  (13)
64. ���������Ǵ븮���αⳳ�μ��� (13)
65. �����ڳ���Ư�ʱⳳ�μ���    (13)
66. ���꼼�װ�   (13)
67. ���������Ҽ��� (15)
68. ����ǥ�ظ����Աݾ����ܱݾ�  (13)
69. ����ǥ�ظ��հ���Աݾ�    (15)
70. �鼼������Աݾ����ܱݾ�    (13)
71. �鼼����հ���Աݾ�  (15)
72. ��꼭���αݾ� (15)
73. ��꼭����ݾ� (15)
74. ȯ�ޱ����ڵ�  (02)
75. �����ڵ�(����ȯ�ޱ�) (03)
76. ���¹�ȣ(����ȯ�ޱ�) (20)
77. �Ѱ����ν��ι�ȣ    (09)
78. ����������   (30)
79. �������    (08)
80. �������    (03)
81. ������(����ǥ��)���� (01)
82. �����������Ҽ���    (15)
83. �Ϲݰ����ڱ��� (01)
84. ����ȯ����ұ���    (01)
85. ������ ���� �������� (15)
86. ����  (28)
*****************************************************************************************************************************/   
  
IF @WorkingTag = ''  
BEGIN   
    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
    SELECT '17'    
          + 'I103200'    
          + CASE WHEN Amt.Amt01 >= 0 THEN    
                  RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt01)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt01))), 15), 1, 1, '-')    
             END  --03. ��ǥ�Ű� �������ݰ�꼭�ݾ�    
          + CASE WHEN Tax.Tax01 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax01)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax01))), 13), 1, 1, '-')    
             END  --04. ��ǥ�Ű� �������ݰ�꼭����
------------------------------------------------------------------------------------------------------
		  + CASE WHEN ISNULL(Amt.Amt132,0) >= 0 THEN
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt132)), 13)
              ELSE
                 STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt132))), 13), 1, 1, '-')
              END   --05. ������������ڹ��༼�ݰ�꼭�ݾ�
          + CASE WHEN ISNULL(Tax.Tax132,0) >= 0 THEN
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax132)), 13)            
             ELSE
               STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax132))), 13), 1, 1, '-')
             END    --06. ������������ڹ��༼�ݰ�꼭����
------------------------------------------------------------------------------------------------------             
          + dbo._FnVATIntChg(ISNULL(Amt.Amt116,0),15,0,1)            --07.�������ī�����ݹ���ݾ�
          + dbo._FnVATIntChg(ISNULL(Tax.Tax117,0),15,0,1)            --08.�������ī�����ݹ��༼�� 
------------------------------------------------------------------------------------------------------
          + CASE WHEN Amt.Amt02 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt02)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt02))), 13), 1, 1, '-')    
             END  --09. ���������Ÿ�ݾ�        
          + CASE WHEN Tax.Tax02 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax02)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax02))), 13), 1, 1, '-')    
             END  --10. ���������Ÿ����
------------------------------------------------------------------------------------------------------
          + CASE WHEN Amt.Amt03 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt03)), 13)    
             ELSE    
                    STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt03))), 13), 1, 1, '-')    
             END  --11. ���⿵�������ݰ�꼭�߱ޱݾ� 
          + CASE WHEN Amt.Amt04 >= 0 THEN    
                  RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt04)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt04))), 15), 1, 1, '-')    
             END  --12. ���⿵������Ÿ�ݾ�
------------------------------------------------------------------------------------------------------
		  + CASE WHEN Amt.Amt05 >= 0 THEN    
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt05)), 13)   
             ELSE    
                    STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt05))), 13), 1, 1, '-')    
             END  --13. ���⿹�������հ�ݾ�   
          + CASE WHEN Tax.Tax05 >= 0 THEN    
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax05)), 13)            
             ELSE    
                    STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax05))), 13), 1, 1, '-')    
             END  --14, ���⿹�������հ輼��                    
------------------------------------------------------------------------------------------------------
          + CASE WHEN Amt.Amt26 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt26)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt26))), 13), 1, 1, '-')    
             END  --15. �����������⼼�ݰ�꼭�ݾ� 
          + CASE WHEN Tax.Tax26 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax26)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax26))), 13), 1, 1, '-')    
             END  --16. �����������⼼�ݰ�꼭����      
------------------------------------------------------------------------------------------------------
          + CASE WHEN Amt.Amt27 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt27)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt27))), 13), 1, 1, '-')    
             END  --17. �����������������Ÿ�ݾ�
          + CASE WHEN Tax.Tax27 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax27)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax27))), 13), 1, 1, '-')    
             END  --18. �����������������Ÿ����    
------------------------------------------------------------------------------------------------------
          + CASE WHEN Amt.Amt28 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt28)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt28))), 13), 1, 1, '-')    
             END  --19. �����������⿵�������ݰ�꼭�ݾ� 
          + CASE WHEN Amt.Amt29 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt29)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt29))), 13), 1, 1, '-')    
             END  --20. �����������⿵������Ÿ�ݾ�
------------------------------------------------------------------------------------------------------
		  + CASE WHEN Amt.Amt26 + Amt.Amt27 + Amt.Amt28 + Amt.Amt29 >= 0 THEN    
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt26 + Amt.Amt27 + Amt.Amt28 + Amt.Amt29)), 13)        
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt26 + Amt.Amt27 + Amt.Amt28 + Amt.Amt29))), 13), 1, 1, '-')    
             END  --21. ��������������հ�ݾ�
          + CASE WHEN Tax.Tax26 + Tax.Tax27 >= 0 THEN    
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax26 + Tax.Tax27)), 13)             
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax26 + Tax.Tax27))), 13), 1, 1, '-')    
             END  --22. ��������������հ輼��
------------------------------------------------------------------------------------------------------                    
          + CASE WHEN Tax.Tax06 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax06)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax06))), 13), 1, 1, '-')    
             END   --23. �����ռ��װ������� 
          + CASE WHEN FLOOR(Amt.Amt01 + Amt.Amt02 + Amt.Amt03 + Amt.Amt04 + Amt.Amt05 + ISNULL(Amt116,0) + ISNULL(Amt132, 0)) >= 0 THEN    
                    RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt01 + Amt.Amt02 + Amt.Amt03 + Amt.Amt04 + Amt.Amt05 + ISNULL(Amt116,0) + ISNULL(Amt132, 0))), 15)     
             ELSE    
                    STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt01 + Amt.Amt02 + Amt.Amt03 + Amt.Amt04 + Amt.Amt05 + ISNULL(Amt116,0) + ISNULL(Amt132, 0)))), 15), 1, 1, '-')    
             END   --24. ����ǥ�رݾ�   
          + CASE WHEN Tax.Tax01 + Tax.Tax02 + Tax.Tax05 + Tax.Tax06 + ISNULL(Tax.Tax117,0) + ISNULL(Tax.Tax132,0)>= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Tax.Tax01 + Tax.Tax02 + Tax.Tax05 + Tax.Tax06 + ISNULL(Tax.Tax117,0) + ISNULL(Tax.Tax132,0))), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Tax.Tax01 + Tax.Tax02 + Tax.Tax05 + Tax.Tax06 + ISNULL(Tax.Tax117,0) + ISNULL(Tax.Tax132,0)))), 15), 1, 1, '-')    
             END   --25. ���⼼�� 2008��2�� ���� by �ڱټ� : ���� ó���� ����                               
------------------------------------------------------------------------------------------------------
          + CASE WHEN FLOOR(Amt.Amt08) >= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt08)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt08))), 15), 1, 1, '-')    
             END   --26. ���Լ��ݰ�꼭�����Ϲݱݾ�          
          + CASE WHEN FLOOR(Tax.Tax08) >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax08)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax08))), 13), 1, 1, '-')    
             END  --27. ���Լ��ݰ�꼭�����Ϲݼ���     
------------------------------------------------------------------------------------------------------
          + CASE WHEN Amt.Amt09 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt09)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt09))), 13), 1, 1, '-')    
             END  --28. ���Լ��ݰ�꼭��������ڻ�ݾ�    
          + CASE WHEN Tax.Tax09 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax09)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax09))), 13), 1, 1, '-')    
             END  --29. ���Լ��ݰ�꼭��������ڻ꼼�� 
------------------------------------------------------------------------------------------------------
		  + CASE WHEN Amt.Amt57 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt57)), 13)            --30. ���Կ��������հ�ݾ�    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt57))), 13), 1, 1, '-')    
             END    
          + CASE WHEN Tax.Tax57 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax57)), 13)            --31. ���Կ��������հ輼��    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax57))), 13), 1, 1, '-')    
             END                     
------------------------------------------------------------------------------------------------------
          + CASE WHEN Amt.Amt58 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt58)), 13)            --32. �����������ԽŰ��ݰ�꼭�ݾ�    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt58))), 13), 1, 1, '-')    
             END    
          + CASE WHEN Tax.Tax58 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax58)), 13)            --33. �����������ԽŰ��ݰ�꼭����    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax58))), 13), 1, 1, '-')    
             END                 
------------------------------------------------------------------------------------------------------
          + CASE WHEN Amt.Amt59 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt59)), 13)            --34. �����������Ա�Ÿ�����ݾ�    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt59))), 13), 1, 1, '-')    
             END    
          + CASE WHEN Tax.Tax59 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax59)), 13)            --35. �����������Ա�Ÿ��������    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax59))), 13), 1, 1, '-')    
             END                 
------------------------------------------------------------------------------------------------------
          + CASE WHEN FLOOR(Amt.Amt58 + Amt.Amt59) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt58 + Amt.Amt59)), 13)         --36. �����������Ը��հ�ݾ�    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt58 + Amt.Amt59))), 13), 1, 1, '-')    
             END    
          + CASE WHEN FLOOR(Tax.Tax58 + Tax.Tax59) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax58 + Tax.Tax59)), 13)            --37. �����������Ը��հ輼��    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax58 + Tax.Tax59))), 13), 1, 1, '-')    
             END                                   
------------------------------------------------------------------------------------------------------
          + CASE WHEN isnull(Amt.Amt133,0) >= 0 THEN
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt133)), 13)            --38.�����ڹ��༼�ݰ�꼭���Աݾ�
              ELSE
               STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt133))), 13), 1, 1, '-')
              END
           + CASE WHEN isnull(Tax.Tax133,0) >= 0 THEN
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax133)), 13)            --39.�����ڹ��༼�ݰ�꼭���Լ���
              ELSE
               STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax133))), 13), 1, 1, '-')
              END  
------------------------------------------------------------------------------------------------------
          + CASE WHEN Amt.Amt10 >= 0 THEN    
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt10)), 13)            --40. ���Ա�Ÿ�������Աݾ�    
             ELSE    
                    STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt10))), 13), 1, 1, '-')    
             END    
          + CASE WHEN Tax.Tax10 >= 0 THEN    
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax10)), 13)            --41. ���Ա�Ÿ�������Լ���    
             ELSE    
                    STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax10))), 13), 1, 1, '-')    
             END                   
------------------------------------------------------------------------------------------------------  
          + CASE WHEN FLOOR(Amt.Amt31 + Amt.Amt118 + Amt.Amt32 + Amt.Amt33 +  ISNULL(Amt.Amt118,0)) >= 0 THEN    
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt31 + Amt.Amt32 + Amt.Amt33 +  ISNULL(Amt.Amt118,0))), 13)       
             ELSE    
                    STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt31 + Amt.Amt32 + Amt.Amt33 +  ISNULL(Amt.Amt118,0)))), 13), 1, 1, '-')    
             END  --42. ��Ÿ�������Ը��հ�ݾ�       
          + CASE WHEN FLOOR(Tax.Tax31 + Tax.Tax119 + Tax.Tax32 + Tax.Tax33 + Tax.Tax34 + Tax.Tax35 + Tax.Tax63 + ISNULL(Tax.Tax119,0)) >= 0 THEN    
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax31 + Tax.Tax32 + Tax.Tax33 + Tax.Tax34 + Tax.Tax35 + Tax.Tax63 + ISNULL(Tax.Tax119,0))), 13) 
    
             ELSE    
                    STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax31 + Tax.Tax32 + Tax.Tax33 + Tax.Tax34 + Tax.Tax35 + Tax.Tax63 + ISNULL(Tax.Tax119,0)))), 13), 1, 1, '-')    
             END  --43. ��Ÿ�������Ը��հ輼��   
------------------------------------------------------------------------------------------------------                                                
          + CASE WHEN FLOOR(Amt.Amt08 + Amt.Amt09 + Amt.Amt57 + Amt.Amt10 + Amt.Amt133) >= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt08 + Amt.Amt09 + Amt.Amt57 + Amt.Amt10 + Amt.Amt133)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt08 + Amt.Amt09 + Amt.Amt57 + Amt.Amt10 + Amt.Amt133))), 15), 1, 1, '-')    
             END                      --44. ���Լ����հ�ݾ�    
          + CASE WHEN FLOOR(Tax.Tax08 - Tax.Tax08_1 + Tax.Tax09 + Tax.Tax57 + Tax.Tax10 + Tax.Tax133) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax08 - Tax.Tax08_1 + Tax.Tax09 + Tax.Tax57 + Tax.Tax10 + Tax.Tax133)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax08 - Tax.Tax08_1 + Tax.Tax09 + Tax.Tax57 + Tax.Tax10 + Tax.Tax133))), 13), 1, 1, '-')    
             END                      --45. ���Լ����հ輼��                 
------------------------------------------------------------------------------------------------------ 
          + CASE WHEN FLOOR(Amt.Amt12) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt12)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt12))), 13), 1, 1, '-')    
             END                           --46. �����������Ҹ����հ�ݾ�    
          + CASE WHEN FLOOR(Tax.Tax12) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax12)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax12))), 13), 1, 1, '-')    
             END                           --47. �����������Ҹ����հ輼��      
------------------------------------------------------------------------------------------------------               
          + CASE WHEN FLOOR(Amt.Amt37) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt37)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt37))), 13), 1, 1, '-')    
             END                           --48. �����������Ҹ��Աݾ�    
          + CASE WHEN FLOOR(Tax.Tax37) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax37)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax37))), 13), 1, 1, '-')    
             END                           --49. �����������Ҹ��Լ���    
------------------------------------------------------------------------------------------------------              
          + CASE WHEN FLOOR(Amt.Amt38) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt38)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt38))), 13), 1, 1, '-')    
             END                           --50. �����������Ұ�����Ը鼼����ݾ�    
          + CASE WHEN FLOOR(Tax.Tax38) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax38)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax38))), 13), 1, 1, '-')    
             END                           --51. �����������Ұ�����Ը鼼������� 
------------------------------------------------------------------------------------------------------
          + CASE WHEN FLOOR(Amt.Amt51) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt51)), 13)    
             ELSE                          --52. �����������Ҵ��ó�бݾ�                
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt51))), 13), 1, 1, '-')    
             END                                     
          + CASE WHEN FLOOR(Tax.Tax39) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax39)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax39))), 13), 1, 1, '-')    
             END                           --53. �����������Ҵ��ó�м���         
------------------------------------------------------------------------------------------------------           
          + CASE WHEN FLOOR(Amt.Amt37 + Amt.Amt38 + Amt.Amt39) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt37 + Amt.Amt38 + Amt.Amt39)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt37 + Amt.Amt38 + Amt.Amt39))), 13), 1, 1, '-')    
             END                           --54. �����������Ҹ��Ը��հ�ݾ�    
          + CASE WHEN FLOOR(Tax.Tax37 + Tax.Tax38 + Tax.Tax39) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax37 + Tax.Tax38 + Tax.Tax39)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax37 + Tax.Tax38 + Tax.Tax39))), 13), 1, 1, '-')    
             END                           --55. �����������Ҹ��Ը��հ輼��         
------------------------------------------------------------------------------------------------------          
          + CASE WHEN (Amt.Amt08 + Amt.Amt09 + Amt.Amt57 + Amt.Amt10 + Amt.Amt133 - Amt12) >= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt08 + Amt.Amt09 + Amt.Amt57 + Amt.Amt10 + Amt.Amt133 - Amt12)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt08 + Amt.Amt09 + Amt.Amt57 + Amt.Amt10 + Amt.Amt133 - Amt12))), 15), 1, 1, '-')    
             END                           --56. �����հ�ݾ�
          + CASE WHEN (Tax.Tax08 - Tax.Tax08_1 + Tax.Tax09 + Tax.Tax57 + Tax.Tax10 + Tax.Tax133 - Tax12) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax08 - Tax.Tax08_1 + Tax.Tax09 + Tax.Tax57 + Tax.Tax10 + Tax.Tax133 - Tax12)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax08 - Tax.Tax08_1 + Tax.Tax09 + Tax.Tax57 + Tax.Tax10 + Tax.Tax133 - Tax12))), 13), 1, 1, '-')    
             END                           --57. �����հ輼��       
------------------------------------------------------------------------------------------------------
          + CASE WHEN Tax.TaxDa >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.TaxDa)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.TaxDa))), 13), 1, 1, '-')    
             END                           --58. ����(ȯ��)����          
------------------------------------------------------------------------------------------------------
          + CASE WHEN Tax.Tax17 >= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Tax.Tax17)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Tax.Tax17))), 15), 1, 1, '-')    
             END                            --59. ��Ÿ�氨��������      
          + CASE WHEN Tax.Tax45 >= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Tax.Tax45)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Tax.Tax45))), 15), 1, 1, '-')    
             END							--60. ��Ÿ�氨�������հ輼��                   
          + CASE WHEN FLOOR(Tax.Tax16 + Tax.Tax17) >= 0 THEN    
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax16 + Tax.Tax17)), 13)         
             ELSE    
                    STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax16 + Tax.Tax17))), 13), 1, 1, '-')    
             END                            --61. �氨�����հ輼��      
------------------------------------------------------------------------------------------------------
          + CASE WHEN Tax.Tax15 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax15)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax15))), 13), 1, 1, '-')    
             END                           --62. �����Ű��ȯ�޼���          
          + CASE WHEN Tax.Tax14 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax14)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax14))), 13), 1, 1, '-')    
             END                           --63. ������������                  
------------------------------------------------------------------------------------------------------
          + CASE WHEN isnull(Tax.Tax62,0) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax62)), 13)            
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax62))), 13), 1, 1, '-')    
             END                           -- 64.���������Ǵ븮���αⳳ�μ���
          + CASE WHEN isnull(Tax.Tax15_1,0) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax15_1)), 13)            
             ELSE    
              STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax15_1))), 13), 1, 1, '-')    
             END                           --65.�����ڳ���Ư�ʱⳳ�μ���
------------------------------------------------------------------------------------------------------
		  + RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax19)), 13)           --66. ���꼼�װ�                     
------------------------------------------------------------------------------------------------------
          + CASE WHEN (Tax.Tax20) >= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Tax.Tax20)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Tax.Tax20))), 15), 1, 1, '-')    
             END                           --67. ���������Ҽ���    
------------------------------------------------------------------------------------------------------                
          + CASE WHEN Amt.Amt24 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt24)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt24))), 13), 1, 1, '-')    
             END                     --68. ��Ÿ���Աݾ��հ�-> �������Աݾ����ܱݾ����� ��Ī �ٲ�     
          + CASE WHEN (Amt.Amt21 + Amt.Amt22 + Amt.Amt23 + Amt.Amt24) >= 0 THEN    
							RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt21 + Amt.Amt22 + Amt.Amt23 + Amt.Amt24)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt21 + Amt.Amt22 + Amt.Amt23 + Amt.Amt24))), 15), 1, 1, '-')    
             END                           --69. ����ǥ�ظ��հ���Աݾ�
          + dbo._FnVATIntChg(isnull(Amt.Amt123,0),13,0,1)            --70.�鼼������Աݾ����ܱݾ�
          + CASE WHEN (Amt.Amt52 + Amt.Amt53 + Amt.Amt123) >= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt52 + Amt.Amt53 + ISNULL(Amt.Amt123,0))), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt52 + Amt.Amt53 + ISNULL(Amt.Amt123,0)))), 15), 1, 1, '-')    
             END                           --71. �鼼����հ���Աݾ�         
------------------------------------------------------------------------------------------------------       
          + CASE WHEN Amt.Amt55 >= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt55)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt55))), 15), 1, 1, '-')    
             END                            --72. ��꼭���αݾ�    
          + CASE WHEN Amt.Amt56 >= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt56)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt56))), 15), 1, 1, '-')    
             END                            --73. ��꼭����ݾ�   
------------------------------------------------------------------------------------------------------
		  + CONVERT(CHAR(2), @RtnTaxKind)   --74. ȯ�ޱ����ڵ� 
		  + LTRIM(RTRIM(@BankCode       )) + SPACE(3  - DATALENGTH(LTRIM(RTRIM(@BankCode       )))) --75. �����ڵ�(����ȯ�ޱ�)
		  + LTRIM(RTRIM(@BankAccNo      )) + SPACE(20 - DATALENGTH(LTRIM(RTRIM(@BankAccNo      )))) --76. ���¹�ȣ(����ȯ�ޱ�)
		  + LTRIM(RTRIM(@TaxSumPaymentNo)) + SPACE(9  - DATALENGTH(LTRIM(RTRIM(@TaxSumPaymentNo)))) --77. �Ѱ����ν��ι�ȣ
          + LTRIM(RTRIM(@BankName       )) + SPACE(30 - DATALENGTH(LTRIM(RTRIM(@BankName       )))) --78. ����������     
          + LTRIM(RTRIM(@CloseDate      )) + SPACE(8  - DATALENGTH(LTRIM(RTRIM(@CloseDate      )))) --79. �������
          + SPACE(3)                --80. �������(���ڽŰ�� �������θ�)    
          + 'N'                     --81. ������(����ǥ��)����, 'N'���� Fix    
          + CASE @TaxationType
                WHEN '3' THEN '000000000000000'                             -- �Ѱ����� �������   0�� ����    
                WHEN '2' THEN CASE WHEN ISNULL(Tax.PaymentTax, 0) >= 0      -- �Ѱ����� �ֻ���ڸ� �Ѱ������Ҽ���(ȯ�޹��� ����) �Է�
                                   THEN       RIGHT('000000000000000' + CONVERT(VARCHAR(15),     FLOOR(ISNULL(Tax.PaymentTax, 0))) , 15)    
                                   ELSE STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(ISNULL(Tax.PaymentTax, 0)))), 15), 1, 1, '-')
                              END
                         ELSE CASE WHEN (Tax.Tax20) >= 0                    -- �� �ܻ���ڴ� (67) ���������� ���� �Է�
                                   THEN       RIGHT('000000000000000' + CONVERT(VARCHAR(15),     FLOOR(Tax.Tax20)) , 15)    
                                   ELSE STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Tax.Tax20))), 15), 1, 1, '-')    
                              END
            END                     --82. �����������Ҽ���
		   + @TaxationType          --83. �Ϲݰ����ڱ��� 
		   + @RtnTaxType            --84. ����ȯ����ұ���  
           + CASE WHEN FLOOR(Tax.Tax08_1) >= 0 
                  THEN       RIGHT('000000000000000' + CONVERT(VARCHAR(15),     FLOOR(Tax.Tax08_1)) , 15)    
                  ELSE STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Tax.Tax08_1))), 15), 1, 1, '-')    
             END                    --85.������ ���� �������� 
           + SPACE(28)              --85.����
           , 1100
    FROM #TTAXVATRptAmt Amt JOIN #TTAXVATRptTax Tax  
                              ON Amt.TaxTermSeq     = Tax.TaxTermSeq  
                             AND Amt.TaxUnit        = Tax.TaxUnit  
    WHERE Amt.TaxTermSeq    = @TaxTermSeq  
      AND Amt.TaxUnit       = @TaxUnit  
END
/***************************************************************************************************************************    
�ΰ���ġ�� - ���Աݾ� ��      
01. �ڷᱸ��(2) : 15    
02. �����ڵ�(7) : I103200
03. ���Աݾ���������(2) : ���������Աݾ� '01', ���Աݾ����� '02', �ſ�ī������������ '04',
                          ��Ÿ���Աݾ�   '07', �鼼���Աݾ� '08', �鼼���Աݾ�����     '14'
04. ���¸�(30)    
05. �����(50)    
06. �����ڵ�(7)    
07. ���Աݾ�(15)    
08. ����(37)    
*****************************************************************************************************************************/    
IF @WorkingTag = ''  
    BEGIN  
    ---------------------------    
    -- 1. ����ǥ�ظ�    
    ---------------------------    
    IF (SELECT Amt21 + Amt22 + Amt23 FROM #TTAXVATRptAmt WHERE TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit) = 0    
    BEGIN    
         INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
         SELECT '15'        --01. �ڷᱸ��    
               + 'I103200'  --02. �����ڵ�    
               + '01'       --03. ���Աݾ���������    
               + CONVERT(VARCHAR(30), LTRIM(RTRIM(BizType     ))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(BizType     )))))    --04. ���¸�    
               + CONVERT(VARCHAR(50), LTRIM(RTRIM(BizItem     ))) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), LTRIM(RTRIM(BizItem     )))))    --05. �����    
               + CONVERT(VARCHAR(07), LTRIM(RTRIM(TaxBizTypeNo))) + SPACE(07 - DATALENGTH(CONVERT(VARCHAR(07), LTRIM(RTRIM(TaxBizTypeNo)))))    --06. �־����ڵ�    
               + '000000000000000'                 --07. ���Աݾ�    
               + SPACE(37)    
               , 150    
         FROM #TDATaxUnit WITH(NOLOCK)
         WHERE CompanySeq   = @CompanySeq  
           AND TaxUnit      = @TaxUnit  
    END    
    ELSE    
    BEGIN    
         INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
         SELECT '15'            --01. �ڷᱸ��    
               + 'I103200'      --02. �����ڵ�    
               + '01'           --03. ���Աݾ���������    
               + CONVERT(VARCHAR(30), LTRIM(RTRIM(ISNULL(B.BizCond   , '')))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(ISNULL(B.BizCond   , ''))))))   --04. ���¸�    
               + CONVERT(VARCHAR(50), LTRIM(RTRIM(ISNULL(B.BizType   , '')))) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), LTRIM(RTRIM(ISNULL(B.BizType   , ''))))))   --05. �����    
               + CONVERT(VARCHAR(07), LTRIM(RTRIM(ISNULL(B.BizTypeSeq, '')))) + SPACE(07 - DATALENGTH(CONVERT(VARCHAR(07), LTRIM(RTRIM(ISNULL(B.BizTypeSeq, ''))))))   --06. �����ڵ�    
               + CASE WHEN A.SpplyAmt >= 0 THEN    
                       RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(A.SpplyAmt)), 15)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.SpplyAmt))), 15), 1, 1, '-')    
                  END         --07. ���Աݾ�    
               + SPACE(37)    
               , 150  
            FROM _TTAXVATRptBizAmt AS A WITH(NOLOCK)
                                        JOIN _TTAXBizKind AS B WITH(NOLOCK)
                                          ON A.CompanySeq   = B.CompanySeq  
                                         AND A.TaxUnit      = B.TaxUnit  
                                         AND A.BizKindSeq   = B.BizKindSeq  
           WHERE A.CompanySeq       = @CompanySeq  
             AND A.TaxTermSeq       = @TaxTermSeq  
             AND A.TaxUnit          = @TaxUnit 
             AND A.SpplyAmt         <> 0
             AND A.RptNo            IN ('3010', '3020', '3030')
           ORDER BY A.RptNo
    END    
  
    ---------------------------    
    -- 2. ���Աݾ�����    
    ---------------------------    
    IF (SELECT SpplyAmt FROM _TTAXVATRptBizAmt WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '3040') <> 0  
    BEGIN  
         INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
         SELECT '15'        --01. �ڷᱸ��    
               + 'I103200'  --02. �����ڵ�    
               + '02'       --03. ���Աݾ���������    
               + CONVERT(VARCHAR(30), LTRIM(RTRIM('���Աݾ�����'       ))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM('���Աݾ�����'       )))))   --04. ���¸�    
               + CONVERT(VARCHAR(50), LTRIM(RTRIM(ISNULL(B.BizType, '')))) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), LTRIM(RTRIM(ISNULL(B.BizType, ''))))))   --05. �����    
               + CONVERT(VARCHAR(07), LTRIM(RTRIM(@TaxBizTypeNo        ))) + SPACE(07 - DATALENGTH(CONVERT(VARCHAR(07), LTRIM(RTRIM(@TaxBizTypeNo        )))))   --06. �����ڵ� (�־����ڵ�)   
               + CASE WHEN A.SpplyAmt >= 0 THEN    
                       RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(A.SpplyAmt)), 15)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.SpplyAmt))), 15), 1, 1, '-')    
                  END         --07. ���Աݾ�    
               + SPACE(37)    
               , 150  
            FROM _TTAXVATRptBizAmt AS A WITH(NOLOCK)
                                        JOIN _TTAXBizKind AS B WITH(NOLOCK)
                                          ON A.CompanySeq   = B.CompanySeq  
                                         AND A.TaxUnit      = B.TaxUnit  
                                         AND A.RptNo        = B.RptSort  
           WHERE A.CompanySeq       = @CompanySeq  
             AND A.TaxTermSeq       = @TaxTermSeq  
             AND A.TaxUnit          = @TaxUnit  
             AND A.RptNo            = '3040'  
    END  
  
    ---------------------------    
    -- 4. �ſ�ī�����������׵�    
    ---------------------------    
    IF (SELECT Tax16 FROM #TTAXVATRptTax WHERE TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit) <> 0  
    BEGIN  
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
         SELECT '15'                --01. �ڷᱸ��    
               + 'I103200'      --02. �����ڵ�    
               + '04'           --03. �ſ�ī������������    
               + CONVERT(VARCHAR(30), LTRIM(RTRIM(ComInfo.BizType     ))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(ComInfo.BizType     )))))   --04. ���¸�    
               + CONVERT(VARCHAR(50), LTRIM(RTRIM(ComInfo.BizItem     ))) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), LTRIM(RTRIM(ComInfo.BizItem     )))))   --05. �����    
               + CONVERT(VARCHAR(07), LTRIM(RTRIM(ComInfo.TaxBizTypeNo))) + SPACE(07 - DATALENGTH(CONVERT(VARCHAR(07), LTRIM(RTRIM(ComInfo.TaxBizTypeNo)))))   --06. �����ڵ�    
               + CASE WHEN Tax.Tax16 >= 0 THEN    
                       RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Tax.Tax16)), 15)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Tax.Tax16))), 15), 1, 1, '-')    
                  END         --07. ���Աݾ�    
               + SPACE(37)    
               , 150    
         FROM #TTAXVATRptTax AS Tax JOIN #TDATaxUnit AS ComInfo WITH(NOLOCK)
                                      ON ComInfo.CompanySeq = @CompanySeq  
                                     AND Tax.TaxUnit        = ComInfo.TaxUnit  
        WHERE Tax.TaxTermSeq    = @TaxTermSeq  
          AND Tax.TaxUnit       = @TaxUnit  
    END  
  
    ---------------------------    
    -- 7. ��Ÿ�氨, ��������    
    ---------------------------    
    IF (SELECT Tax17 FROM #TTAXVATRptTax WHERE TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit) <> 0    
    BEGIN    
         INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
         SELECT '15'            --01. �ڷᱸ��    
               + 'I103200'  --02. �����ڵ�    
               + '07'       --03. �ſ�ī������������    
               + CONVERT(VARCHAR(30), LTRIM(RTRIM(ComInfo.BizType     ))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(ComInfo.BizType     )))))   --04. ���¸�    
               + CONVERT(VARCHAR(50), LTRIM(RTRIM(ComInfo.BizItem     ))) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), LTRIM(RTRIM(ComInfo.BizItem     )))))   --05. �����    
               + CONVERT(VARCHAR(07), LTRIM(RTRIM(ComInfo.TaxBizTypeNo))) + SPACE(07 - DATALENGTH(CONVERT(VARCHAR(07), LTRIM(RTRIM(ComInfo.TaxBizTypeNo)))))   --06. �����ڵ�    
               + CASE WHEN Tax.Tax17 >= 0 THEN    
                       RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Tax.Tax17)), 15)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Tax.Tax17))), 15), 1, 1, '-')    
                  END         --07. ���Աݾ�    
               + SPACE(37)    
               , 150    
         FROM #TTAXVATRptTax AS Tax JOIN #TDATaxUnit AS ComInfo WITH(NOLOCK)
                                      ON ComInfo.CompanySeq = @CompanySeq  
                                     AND Tax.TaxUnit        = ComInfo.TaxUnit  
        WHERE Tax.TaxTermSeq    = @TaxTermSeq  
          AND Tax.TaxUnit       = @TaxUnit  
    END    
  
  
    ---------------------------    
    -- 8. �鼼������Աݾ�    
    ---------------------------    
    IF (SELECT Amt52 + Amt53 + Amt123 FROM #TTAXVATRptAmt WHERE TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit) <> 0    
    BEGIN    
         INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
         SELECT '15'            --01. �ڷᱸ��    
                   + 'I103200'  --02. �����ڵ�    
                   + '08'       --03. ���Աݾ���������    
                   + CONVERT(VARCHAR(30), LTRIM(RTRIM(ISNULL(B.BizCond   , '')))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(ISNULL(B.BizCond   , ''))))))   --04. ���¸�    
                   + CONVERT(VARCHAR(50), LTRIM(RTRIM(ISNULL(B.BizType   , '')))) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), LTRIM(RTRIM(ISNULL(B.BizType   , ''))))))   --05. �����    
                   + CONVERT(VARCHAR(07), LTRIM(RTRIM(ISNULL(B.BizTypeSeq, '')))) + SPACE(07 - DATALENGTH(CONVERT(VARCHAR(07), LTRIM(RTRIM(ISNULL(B.BizTypeSeq, ''))))))   --06. �����ڵ�    
                   + CASE WHEN A.SpplyAmt >= 0 THEN    
                           RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(A.SpplyAmt)), 15)    
                      ELSE    
                           STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.SpplyAmt))), 15), 1, 1, '-')    
                      END         --07. ���Աݾ�    
                   + SPACE(37)    
                   , 150  
            FROM _TTAXVATRptBizAmt AS A WITH(NOLOCK)
                                        JOIN _TTAXBizKind AS B WITH(NOLOCK)
                                          ON A.CompanySeq   = B.CompanySeq  
                             AND A.TaxUnit      = B.TaxUnit  
                                         AND A.BizKindSeq   = B.BizKindSeq  
           WHERE A.CompanySeq       = @CompanySeq  
             AND A.TaxTermSeq       = @TaxTermSeq  
             AND A.TaxUnit          = @TaxUnit  
             AND A.RptNo            IN ('7010', '7020') 
             AND A.SpplyAmt        <> 0  
         UNION  
         SELECT '15'            --01. �ڷᱸ��    
               + 'I103200'  --02. �����ڵ�    
               + '14'       --03. ���Աݾ���������    
               + CONVERT(VARCHAR(30), LTRIM(RTRIM(ISNULL(B.BizCond   , '')))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(ISNULL(B.BizCond   , ''))))))   --04. ���¸�    
               + CONVERT(VARCHAR(50), LTRIM(RTRIM(ISNULL(B.BizType   , '')))) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), LTRIM(RTRIM(ISNULL(B.BizType   , ''))))))   --05. �����    
               + CONVERT(VARCHAR(07), LTRIM(RTRIM(ISNULL(@TaxBizTypeNo,'')))) + SPACE(07 - DATALENGTH(CONVERT(VARCHAR(07), LTRIM(RTRIM(ISNULL(@TaxBizTypeNo,''))))))   --06. �����ڵ�(�־����ڵ�)
               + CASE WHEN A.SpplyAmt >= 0 THEN    
                       RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(A.SpplyAmt)), 15)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.SpplyAmt))), 15), 1, 1, '-')    
                  END         --07. ���Աݾ�    
               + SPACE(37)    
               , 150  
       FROM _TTAXVATRptBizAmt AS A WITH(NOLOCK)
                                        JOIN _TTAXBizKind AS B WITH(NOLOCK)
                                          ON A.CompanySeq   = B.CompanySeq  
                                         AND A.TaxUnit      = B.TaxUnit  
                                         AND A.BizKindSeq   = B.BizKindSeq  
           WHERE A.CompanySeq       = @CompanySeq  
             AND A.TaxTermSeq       = @TaxTermSeq  
             AND A.TaxUnit          = @TaxUnit  
             AND A.RptNo            = '7025'  
             AND A.SpplyAmt        <> 0  
    END  
END  
/***************************************************************************************************************************    
�ΰ���ġ�� - �������� �Ű�    
01. �ڷᱸ��(2) : 14    
02. �����ڵ�(7) : I103200
03. ���������ڵ�(3)
04. ����Ϸù�ȣ(12) : "1" FIX
05. ��������ݾ�
06. �������鼼��
07. ����
*****************************************************************************************************************************/    
IF @WorkingTag = ''  
BEGIN
    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)
    SELECT '14'             -- 01. �ڷᱸ��
        + 'I103200'     -- 02. �����ڵ�
        + CASE RptNo WHEN '5090' THEN '211'         -- �ſ�ī�� ������ǥ�� ���ɸ��� ����� �Ϲݸ���
                     WHEN '5095' THEN '212'         -- �ſ�ī�� ������ǥ�� ���ɸ��� ����� �����ڻ����
                     WHEN '5100' THEN '230'         -- �������Լ���
                     WHEN '5110' THEN '270'         -- ��Ȱ�� ���ڿ��� ���Լ���
                     WHEN '5130' THEN '291'         -- ���������ȯ ���Լ���
                     WHEN '5140' THEN '292'         -- �����Լ���
                     WHEN '5150' THEN '293'         -- ������ռ���
                     WHEN '5155' THEN '294'         -- �ܱ��� �������� ���� ȯ�޼���
                     WHEN '5210' THEN '310'         -- ���ڽŰ� ���� ����
                     WHEN '5215' THEN '321'         -- ���ڼ��ݰ�꼭 �߱޼���
                     WHEN '5220' THEN '331'         -- �ýÿ�ۻ���ڰ氨����
                     WHEN '5230' THEN '351'         -- ���ݿ����� ����� ����
                     WHEN '5240' THEN '361'         -- ��Ÿ����
                     WHEN '1190' THEN '410'         -- �ſ�ī�� ������ǥ�� ������� ��
                     ELSE SPACE(3) END                      -- 03. ���������ڵ�
        + '000000000001'                                    -- 04. ����Ϸù�ȣ (Fix "1")
        + dbo._FnVATIntChg(ISNULL(A.SpplyAmt,0),15,0,1)     -- 05. ��������ݾ�
        + dbo._FnVATIntChg(ISNULL(A.VATAmt  ,0),15,0,1)     -- 06. �������鼼�� 
        + SPACE(46)                                         -- 07. ����
        ,100                                   
       FROM _TTAXVATRptAmt AS A WITH(NOLOCK)
      WHERE CompanySeq    = @CompanySeq  
        AND TaxTermSeq    = @TaxTermSeq  
        AND TaxUnit       = @TaxUnit
        AND (A.SpplyAmt   <> 0 OR A.VATAmt     <> 0)        -- ���鼼�׸� �ִ� �׸� ����
        AND RptNo IN ('5090','5095','5100','5110','5130','5140',
                      '5150','5155','5210','5215','5220','5230',
                      '5240','1190')
END
/***************************************************************************************************************************    
�ΰ���ġ�� - ���꼼 �Ű�     
01. �ڷᱸ��(2) : 13    
02. �����ڵ�(7) : I103200
03. ���꼼�ڵ�(10)
04. ����Ϸù�ȣ(12) : "1" FIX
05. ���꼼�ݾ�
06. ���꼼��
07. ����
*****************************************************************************************************************************/    
IF @WorkingTag = ''  
BEGIN
    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)
    SELECT '13'             -- 01. �ڷᱸ��
            + 'I103200'     -- 02. �����ڵ�
            + CASE RptNo WHEN '5260' THEN 'B1100'       -- ����ڹ̵��
                         WHEN '5270' THEN 'B3100'       -- ���ݰ�꼭�����߱�
                         WHEN '5273' THEN 'B3200'       -- ���ݰ�꼭��������
                         WHEN '5275' THEN 'B3400'       -- ���ݰ�꼭�̹߱�
                         WHEN '5276' THEN 'B4300'       -- ���ڼ��ݰ�꼭��������
                         WHEN '5277' THEN 'B4100'       -- ���ڼ��ݰ�꼭������
                         WHEN '5280' THEN 'B5100'       -- ���ݰ�꼭����Ҽ���
                         WHEN '5281' THEN 'B5300'       -- ���ݰ�꼭��������
                         WHEN '5290' THEN 'A2110'       -- �Ű�Ҽ��ǹ��Ű��Ϲ�
                         WHEN '5291' THEN 'A2210'       -- �Ű�Ҽ��ǹ��Ű�δ�                        
                         WHEN '5292' THEN 'A3110'       -- �Ű�Ҽ��ǰ���,�ʰ�ȯ�޽Ű��Ϲ�
                         WHEN '5293' THEN 'A3210'       -- �Ű�μ��̰���,�ʰ�ȯ�޽Ű�δ�
                         WHEN '5300' THEN 'A7100'       -- ���κҼ���
                         WHEN '5310' THEN 'A4200'       -- ����������ǥ�ؽŰ�Ҽ���
                         WHEN '5320' THEN 'B7100'       -- ���ݸ�������Ҽ���
                         WHEN '5321' THEN 'B7200'       -- �ε����Ӵ���ް��׸����Ҽ���
                         WHEN '5325' THEN 'B9100'       -- �����ڳ���Ư�ʰŷ����¹̻��
                         WHEN '5327' THEN 'B9200'       -- �����ڳ���Ư�ʰŷ����������Ա�
                         ELSE SPACE(5) END + SPACE(5)           -- 03. ���꼼�ڵ�
            + '000000000001'                                    -- 04. ����Ϸù�ȣ (Fix "1")
            + dbo._FnVATIntChg(ISNULL(A.SpplyAmt,0),15,0,1)     -- 05. ���꼼�ݾ�
            + dbo._FnVATIntChg(ISNULL(A.VATAmt  ,0),15,0,1)     -- 06. ���꼼��
            + SPACE(39)                                         -- 07. ����
            ,100
       FROM _TTAXVATRptAmt AS A WITH(NOLOCK)
      WHERE CompanySeq    = @CompanySeq  
        AND TaxTermSeq    = @TaxTermSeq  
        AND TaxUnit       = @TaxUnit
        AND (A.SpplyAmt   <> 0 OR A.VATAmt     <> 0)            -- ���鼼�׸� �ִ� �׸� ����
        AND RptNo IN ('5260','5270','5273','5275','5276','5277',
                      '5280','5281','5290','5291','5292','5293',
                      '5300','5310','5320','5321','5325','5327')
END
    
  
/***************************************************************************************************************************    
�������Ȳ����    
    
01. �ڷᱸ��(2) : 14    
02. �����ڵ�(7) : I104400 / V142
03. ��_Ÿ�� ����(2) : '01' �ڰ�, '02' Ÿ��    
04. ��������(7)    
05. �����ǹ�_����(3)    
06. �����ǹ�_����(3)    
07. �����ǹ� �ٴڸ���(7)    
08. �����ǹ� ������(7)    
09. ���Ǽ�(7)    
10. Ź�ڼ�(7)    
11. ���ڼ�(7)    
12. ������ ������(1) : 'Y' ��, 'N' ��    
13. ��������(7)    
14. ������(�¿���)(7)    
15. ������(ȭ����)(7)    
16. ������(2) : Ÿ���� ��� '06' 6������, '12' 12������    
17. ������(9)    
18. ����(11)    
19. ����_������(9)    
20. ������(9)    
21. �ΰǺ�(9)    
22. ��Ÿ���(9)    
23. ���⺻����(9)    
24. ����(52)    
*****************************************************************************************************************************/    
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT * FROM _TTAXBizPlace WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)    
    BEGIN    
            INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
            SELECT    '14'                --01.�ڷᱸ��    
                    + 'I104400'          --02. �����ڵ�    
                    + CASE WHEN SMIsOwner = 4097001 THEN '01' ELSE '02' END              --03. ��_Ÿ������    
                    + RIGHT('0000000' + CONVERT(VARCHAR(7), FLOOR(BizGround))       , 7) --04.��������    
                    + RIGHT('000'     + CONVERT(VARCHAR(3), FLOOR(BizBuildingDown)) , 3) --05.�����ǹ�_��������    
                    + RIGHT('000'     + CONVERT(VARCHAR(3), FLOOR(BizBuildingUp))   , 3) --06.�����ǹ�_��������    
                    + RIGHT('0000000' + CONVERT(VARCHAR(7), FLOOR(BizBuildingSize1)), 7) --07.�����ǹ� �ٴڸ���    
                    + RIGHT('0000000' + CONVERT(VARCHAR(7), FLOOR(BizBuildingSize2)), 7) --08.�����ǹ� ������    
                    + RIGHT('0000000' + CONVERT(VARCHAR(7), FLOOR(RoomCnt))         , 7) --09.���Ǽ�    
                    + RIGHT('0000000' + CONVERT(VARCHAR(7), FLOOR(TableCnt))        , 7) --10.Ź�ڼ�    
                    + RIGHT('0000000' + CONVERT(VARCHAR(7), FLOOR(ChairCnt))        , 7) --11.���ڼ�    
                    + CASE IsParking    
                            WHEN '1' THEN 'Y'    
                            WHEN '0' THEN 'N'    
                            ELSE SPACE(1)    
                       END --12.������ ����    
                    + RIGHT('0000000' + CONVERT(VARCHAR(7), FLOOR(EmpCnt)) , 7) --13.��������    
                    + RIGHT('0000000' + CONVERT(VARCHAR(7), FLOOR(CarCnt1)), 7) --14.������(�¿���)    
                    + RIGHT('0000000' + CONVERT(VARCHAR(7), FLOOR(CarCnt2)), 7) --15.������(ȭ����)
                    + CASE SMBaseCostKind    
                            WHEN 4098001 THEN '06'    
                            WHEN 4098002 THEN '12'    
                            ELSE SPACE(2)    
                       END --16.������    
                    + RIGHT('000000000' + CONVERT(VARCHAR(9) , FLOOR(Deposit))  , 9) --17.������    
                    + RIGHT('00000000000' + CONVERT(VARCHAR(11), FLOOR(MonAmt)) ,11) --18.����    
                    + RIGHT('000000000' + CONVERT(VARCHAR(9) , FLOOR(ElectAmt)) , 9) --19.����_������    
                    + RIGHT('000000000' + CONVERT(VARCHAR(9), FLOOR(WaterAmt))  , 9) --20.������    
                    + RIGHT('000000000' + CONVERT(VARCHAR(9), FLOOR(PayAmt))    , 9) --21.�ΰǺ�    
                    + RIGHT('000000000' + CONVERT(VARCHAR(9), FLOOR(EtcAmt))    , 9) --22.��Ÿ���    
                    + RIGHT('000000000' + CONVERT(VARCHAR(9), FLOOR(MonSumAmt)) , 9) --24.���⺻����    
                    + SPACE(52)    
                    , 200    
                FROM _TTAXBizPlace WITH(NOLOCK)
                WHERE CompanySeq    = @CompanySeq  
                  AND TaxTermSeq    = @TaxTermSeq  
                  AND TaxUnit       = @TaxUnit  
    END    
END  
  
/***************************************************************************************************************************    
�ſ�ī�������ǥ����ݾ׵� ����ǥ    
    
    
01. �ڷᱸ��(2) : 17    
02. �����ڵ�(7) : I103400 / V117
03. ��ü����ݾ�_�հ�(15) : 4.�ſ�ī������ݾ�_�հ� + 5.���ݿ���������ݾ�_�հ�    
04. �ſ�ī�����ݾ�_�հ�(13)    
05. ���ݿ���������ݾ�_�հ�(13)    
06. ����ݾ��հ�_���������(13) : 7.�ſ�ī������ݾ�_�������� + 8.���ݿ���������ݾ�_���������    
07. �ſ�ī������ݾ�_��������(13)    
08. ���ݿ���������ݾ�_��������(13)    
09. ����ݾ��հ�_�鼼����(13) : 10.�ſ�ī������ݾ�_�鼼���� + 11.���ݿ���������ݾ�_�鼼�����    
10. �ſ�ī������ݾ�_�鼼����(13)    
11. ���ݿ���������ݾ�_�鼼����(13)    
12. ����ݾ��հ�_�����(13) : 13.�ſ�ī������ݾ�_����� + 14.���ݿ���������ݾ�_�����    
13. �ſ�ī������ݾ�_�����(13)    
14. ���ݿ���������ݾ�_�����(13)    
15. ���ݰ�꼭���αݾ�(����ǥ)(13)    
16. ��꼭���αݾ�(����ǥ)(13)    
17. ����(10)    
*****************************************************************************************************************************/    
DECLARE @A_Amt  DECIMAL(19,5),  @B_Amt  DECIMAL(19,5),  @C_Amt  DECIMAL(19,5),  
        @D_Amt  DECIMAL(19,5),  @E_Amt  DECIMAL(19,5),  @F_Amt  DECIMAL(19,5),  
        @G_Amt  DECIMAL(19,5),  @H_Amt  DECIMAL(19,5),  @I_Amt  DECIMAL(19,5),  
        @J_Amt  DECIMAL(19,5),  @K_Amt  DECIMAL(19,5)
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT * FROM _TTAXCardBillDraw WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
    BEGIN  
        SELECT @A_Amt = FLOOR(SUM(SupplyAmt + VATAmt)) ,                                                 -- ��ü����ݾ�_�հ�
               @B_Amt = FLOOR(SUM(CASE WHEN B.IsCard = '1'                                   THEN SupplyAmt + VATAmt ELSE 0 END)), -- �ſ�ī�����ݾ�_�հ�
               @C_Amt = FLOOR(SUM(CASE WHEN B.SMEvidKind = 4115003                           THEN SupplyAmt + VATAmt ELSE 0 END)), -- ���ݿ���������ݾ�_�հ�
               @D_Amt = FLOOR(SUM(CASE WHEN B.SMTaxKind = 4114001                            THEN SupplyAmt + VATAmt ELSE 0 END)), -- ����ݾ��հ�_���������
               @E_Amt = FLOOR(SUM(CASE WHEN B.SMTaxKind = 4114001 AND B.IsCard = '1'         THEN SupplyAmt + VATAmt ELSE 0 END)), -- �ſ�ī������ݾ�_���������
               @F_Amt = FLOOR(SUM(CASE WHEN B.SMTaxKind = 4114001 AND B.SMEvidKind = 4115003 THEN SupplyAmt + VATAmt ELSE 0 END)), -- ���ݿ���������ݾ�_���������
               @G_Amt = FLOOR(SUM(CASE WHEN B.SMTaxKind = 4114002                            THEN SupplyAmt + VATAmt ELSE 0 END)), -- ����ݾ��հ�_�鼼�����
               @H_Amt = FLOOR(SUM(CASE WHEN B.SMTaxKind = 4114002 AND B.IsCard = '1'         THEN SupplyAmt + VATAmt ELSE 0 END)), -- �ſ�ī������ݾ�_�鼼�����
               @I_Amt = FLOOR(SUM(CASE WHEN B.SMTaxKind = 4114002 AND B.SMEvidKind = 4115003 THEN SupplyAmt + VATAmt ELSE 0 END)), -- ���ݿ���������ݾ�_�鼼�����
               @J_Amt = FLOOR(SUM(CASE WHEN B.SMEvidKind IN (4115001, 4115006) AND B.IsBuyerBill <> '1' THEN SupplyAmt + VATAmt ELSE 0 END)),  -- ���ݰ�꼭���αݾ�
               @K_Amt = FLOOR(SUM(CASE WHEN B.SMEvidKind = 4115002                           THEN SupplyAmt + VATAmt ELSE 0 END ))  -- ��꼭���αݾ�
          FROM _TTAXCardBillDraw AS A WITH(NOLOCK)
                    JOIN _TDAEvid AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq 
                                                   AND A.EvidSeq    = B.EvidSeq
         WHERE A.CompanySeq     = @CompanySeq
           AND A.TaxTermSeq     = @TaxTermSeq
           AND A.TaxUnit        = @TaxUnit

        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
        SELECT '17'         --01. �ڷᱸ��
             + 'I103400'  --02. �����ڵ�
             + dbo._FnVATIntChg(ISNULL(@A_Amt,0) , 15, 0, 1)  --03. ��ü����ݾ�_�հ�           (15)
             + dbo._FnVATIntChg(ISNULL(@B_Amt,0) , 13, 0, 1)  --04. �ſ�ī�����ݾ�_�հ�       (13)
             + dbo._FnVATIntChg(ISNULL(@C_Amt,0) , 13, 0, 1)  --05. ���ݿ���������ݾ�_�հ�     (13)
             + dbo._FnVATIntChg(ISNULL(@D_Amt,0) , 13, 0, 1)  --06. ����ݾ��հ�_���������     (13)
             + dbo._FnVATIntChg(ISNULL(@E_Amt,0) , 13, 0, 1)  --07. �ſ�ī������ݾ�_�������� (13)
             + dbo._FnVATIntChg(ISNULL(@F_Amt,0) , 13, 0, 1)  --08. ���ݿ���������ݾ�_�������� (13)
             + dbo._FnVATIntChg(ISNULL(@G_Amt,0) , 13, 0, 1)  --09. ����ݾ��հ�_�鼼����       (13)
             + dbo._FnVATIntChg(ISNULL(@H_Amt,0) , 13, 0, 1)  --10. �ſ�ī������ݾ�_�鼼���� (13)
             + dbo._FnVATIntChg(ISNULL(@I_Amt,0) , 13, 0, 1)  --11. ���ݿ���������ݾ�_�鼼���� (13)
             + '0000000000000'                                --12. ����ݾ��հ�_�����         (13)
             + '0000000000000'                                --13. �ſ�ī������ݾ�_�����   (13)
             + '0000000000000'                                --14. ���ݿ���������ݾ�_�����   (13)
             + dbo._FnVATIntChg(ISNULL(@J_Amt,0) , 13, 0, 1)  --15. ���ݰ�꼭���αݾ�(����ǥ)  (13)
             + dbo._FnVATIntChg(ISNULL(@K_Amt,0) , 13, 0, 1)  --16. ��꼭���αݾ�(����ǥ)      (13)
             + SPACE(7)                   --17. ����                        (10)
            , 200 
    END    
END  
/***************************************************************************************************************************    
������÷�μ����������    
    
01. �ڷᱸ��(2) : 17    
02. �����ڵ�(7) : I105800 / V106
03. ��������ڵ�(2) : 01 - Ư���Һ� ����ǥ�ؽŰ��� �Բ� ����  02 - ������� �Ǵ� �������� ����    -- 20070409 2007_1th by Him    
04. �������(60) : "Ư���Һ� ����ǥ�ؽŰ��� �Բ� ����" �Ǵ� "������� �Ǵ� �������� ����"    
05. �Ϸù�ȣ(6)    
06. ������(40) : ����Ű�����    
07. �߱���(20)    
08. �߱�����(8)    
09. ��������(8)    
10. ������ȭ�ڵ�(3)    
11. ȯ��(9, 4)    
12. �������ݾ�(��ȭ)(15, 2)    
13. �������ݾ�(��ȭ)(15)    
14. ���Ű��ش��(��ȭ)(15, 2)    
15. ���Ű��ش��(��ȭ)(15)    
16. ����(25)    
****************************************************************************************************************************/    
IF @WorkingTag IN ('', 'Z')  
BEGIN  
    IF EXISTS (SELECT * FROM _TTAXZero WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
    BEGIN    
        IF @WorkingTag = 'Z' ------- ���ϽŰ� (������÷�μ���)  
        BEGIN  
            --=============================================================================  
            -- ������ ��������(HEAD RECORD)    
            --=============================================================================  
            --��ȣ  �׸�                        ����  ����  ��������  ���  
            --1   ���ڵ屸��                    ����  2     2         ZH  
            --2   �ͼӳ⵵                      ����  4     6         YYYY��  
            --3   �ݱⱸ��                      ����  1     7         1: 1��, 2: 2��  
            --4   �ݱ⳻ �� ����                ����  1     8         1/2/3/4/5/6  
            --5   ������(������)����ڵ�Ϲ�ȣ  ����  10    18  
            --6   ��ȣ(���θ�)                  ����  60    78  
            --7   ����(��ǥ��)                  ����  30    108  
            --8   �ֹ�(����)��Ϲ�ȣ            ����  13    121  
            --9   ��������                      ����  8     129  
            --10  ������(������)��ȭ��ȣ        ����  12    141  
            --11  ����                          ����  59    200       SPACE              
            
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)    
                SELECT 'ZH'                         -- ���ڵ屸��    
                    +  LEFT(@TaxFrDate, 4)          -- �ͼӳ⵵    
                    +  @TermKind                    -- �ݱⱸ��    
                    +  @YearHalfMM                  -- �ݱ⳻ �� ����    
                    + CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '') + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '') )))) -- ������(������)����ڵ�Ϲ�ȣ  
                    + CONVERT(VARCHAR(60), TaxName                 + SPACE(60 - DATALENGTH(CONVERT(VARCHAR(60), TaxName                 )))) -- ��ȣ(���θ�)  
                    + CONVERT(VARCHAR(30), Owner                   + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), Owner                   )))) -- ����(��ǥ��)      
                    + CONVERT(VARCHAR(13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','') 
                                         + SPACE(13 - DATALENGTH(CONVERT(VARCHAR(13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','') )))) -- �ֹ�(����)��Ϲ�ȣ  
                    + CONVERT(VARCHAR( 8), @CurrDate               + SPACE( 8 - DATALENGTH(CONVERT(VARCHAR( 8), @CurrDate               )))) -- ��������  
                    + CONVERT(VARCHAR(12), TelNo                   + SPACE(12 - DATALENGTH(CONVERT(VARCHAR(12), TelNo                   )))) -- ������(������)��ȭ��ȣ  
                    + SPACE(59)    -- ����  
                    , 200  
               FROM #TDATaxUnit WITH(NOLOCK)
              WHERE CompanySeq  = @CompanySeq  
                AND TaxUnit     = @TaxUnit  
  
            --=============================================================================  
            -- ������÷�μ����������(DATA RECORD)    
            --=============================================================================  
            --��ȣ  �׸�                        ����  ����  ��������  ���  
            --1   ���ڵ屸��                    ����  2     2         ZD  
            --2   �ͼӳ⵵                      ����  4     6         YYYY��  
            --3   �ݱⱸ��                      ����  1     7         1: 1��, 2: 2��  
            --4   �ݱ⳻ �� ����                ����  1     8         1/2/3/4/5/6  
            --5   ������(������)����ڵ�Ϲ�ȣ  ����  10    18  
            --6   ��������ڵ�                  ����  2     20        01,02  
            --7   �Ϸù�ȣ                      ����  6     26        SEQ  
            --8   ������                        ����  40    66  
            --9   �߱���                        ����  20    86  
            --10  �߱�����                      ����  8     94  
            --11  ��������                      ����  8     102  
            --12  ������ȭ�ڵ�                  ����  3     105       MONEY CD,������  
            --13  ȯ��                          ����  9,4   114  
            --14  �������ݾ�(��ȭ)            ����  15,2  129  
            --15  �������ݾ�(��ȭ)            ����  15    144  
            --16  ���Ű��ش��(��ȭ)          ����  15,2  159  
            --17  ���Ű��ش��(��ȭ)          ����  15    174  
            --18  ����                          ����  26    200       SPACE  
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)    
                SELECT 'ZD'                         -- ���ڵ屸��    
                    +  LEFT(@TaxFrDate, 4)          -- �ͼӳ⵵    
                    +  @TermKind                    -- �ݱⱸ��    
                    +  @YearHalfMM                  -- �ݱ⳻ �� ����    
                    +  dbo._FnVATCHARChg(convert(VARCHAR(10), @TaxNo)       ,10,1)                  -- ������(������)����ڵ�Ϲ�ȣ    
                    + ( CASE A.SMRptRemType WHEN 4130001 THEN '01' ELSE '02' END )                  -- ��������ڵ�  
                    +  RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY Seq)), 6)   -- �Ϸù�ȣ  
                    +  CONVERT(VARCHAR(40), LTRIM(RTRIM(A.ReportName   ))) + SPACE(40 - DATALENGTH(CONVERT(VARCHAR(40), LTRIM(RTRIM(A.ReportName   ))))) -- ������  
                    +  CONVERT(VARCHAR(20), LTRIM(RTRIM(A.ExpermitNm   ))) + SPACE(20 - DATALENGTH(CONVERT(VARCHAR(20), LTRIM(RTRIM(A.ExpermitNm   )))))   -- �߱���  
                    +  CASE WHEN ISNULL(A.ExpermitDate, '') = '' THEN SPACE(8) ELSE A.ExpermitDate END       -- �߱�����  
                    +  CASE WHEN ISNULL(A.ShippingDate, '') = '' THEN SPACE(8) ELSE A.ShippingDate END       -- ��������  
                    + CASE WHEN ISNULL(A.CurrSeq, 0) = 0 THEN SPACE(3) ELSE ( CASE A.CurrSeq WHEN @StkCurrSeq THEN @KorCurrNo ELSE B.CurrName END ) END -- ������ȭ�ڵ�  
                    + RIGHT('000000000' + REPLACE(CONVERT(VARCHAR(10), CONVERT(NUMERIC(19, 4), A.ExRate)), '.', ''), 9)   -- ȯ��  
                    +  dbo._FnVATIntChg(CONVERT(NUMERIC(19,2),ForAmt1)       ,15,2,1)    -- �������ݾ�(��ȭ)  
                    +  dbo._FnVATIntChg(KoAmt1                               ,15,0,1)    -- �������ݾ�(��ȭ)  
                    +  dbo._FnVATIntChg(CONVERT(NUMERIC(19,2),ForAmt2)       ,15,2,1)    -- ���Ű��ش��(��ȭ)  
                    +  dbo._FnVATIntChg(KoAmt2                               ,15,0,1)    -- ���Ű��ش��(��ȭ)  
                    +  SPACE(26)                    -- ����    
                    ,  200                          -- ��������    
                 FROM _TTAXZero AS A WITH(NOLOCK)
                                      LEFT OUTER JOIN _TDACurr AS B WITH(NOLOCK)
                                       ON A.CompanySeq  = B.CompanySeq  
                                      AND A.CurrSeq     = B.CurrSeq  
                 WHERE A.CompanySeq     = @CompanySeq  
                   AND A.TaxTermSeq     = @TaxTermSeq  
                   AND A.TaxUnit        = @TaxUnit  
  
            --=============================================================================  
            -- ������÷�μ���������� �հ�(TAIL RECORD)    
            --=============================================================================  
            --��ȣ  �׸�                        ����  ����  ��������  ���  
            --1   ���ڵ屸��                    ����  2     2         ZT  
            --2   �ͼӳ⵵                      ����  4     6         YYYY����  
            --3   �ݱⱸ��                      ����  1     7         1: 1��, 2: 2��  
            --4   �ݱ⳻ �� ����                ����  1     8         1/2/3/4/5/6  
            --5   ������(������)����ڵ�Ϲ�ȣ  ����  10    18  
            --6   DATA �Ǽ�                     ����  7     25  
            --7   �������ݾ�(��ȭ)_�հ�       ����  15    40  
            --8   ���Ű��ش��(��ȭ)_�հ�     ����  15    55  
            --9   ����                          ����  145   200  
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)    
                SELECT 'ZT'                         -- ���ڵ屸��    
                    +  LEFT(@TaxFrDate, 4)          -- �ͼӳ⵵    
                    +  @TermKind                    -- �ݱⱸ��    
                    +  @YearHalfMM                  -- �ݱ⳻ �� ����    
                    +  dbo._FnVATCHARChg(CONVERT(VARCHAR(10), @TaxNo)    ,10,1)    -- ������(������)����ڵ�Ϲ�ȣ    
                    +  dbo._FnVATIntChg(COUNT(Seq)                       , 7,0,1)  -- DATA�Ǽ�      
                    +  dbo._FnVATIntChg(SUM(KoAmt1)                      ,15,0,1)  -- �������ݾ�(��ȭ)_�հ�  
                    +  dbo._FnVATIntChg(SUM(KoAmt2)                      ,15,0,1)  -- ���Ű��ش��(��ȭ)_�հ�  
                    +  SPACE(145)                   -- ����    
                    ,  200                          -- ��������    
                  FROM _TTAXZero AS A WITH(NOLOCK)
                 WHERE A.CompanySeq     = @CompanySeq  
                   AND A.TaxTermSeq     = @TaxTermSeq  
                   AND A.TaxUnit        = @TaxUnit  
        END  
        ELSE ---------------------- ���ڽŰ�  (������÷�μ���)  
        BEGIN  
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT '17'  --01. �ڷᱸ��    
                       + 'I105800' --02. �����ڵ�    
                       + ( CASE A.SMRptRemType WHEN 4130001 THEN '01' ELSE '02' END ) -- 03. ��������ڵ�
                       + CONVERT(VARCHAR(60), LTRIM(RTRIM(A.Remark     ))) + SPACE(60 - DATALENGTH(CONVERT(VARCHAR(60), LTRIM(RTRIM(A.Remark     )))))   --04. �������    
                       + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY Seq)), 6) -- 05. �Ϸù�ȣ    
                       + CONVERT(VARCHAR(40), LTRIM(RTRIM(A.ReportName ))) + SPACE(40 - DATALENGTH(CONVERT(VARCHAR(40), LTRIM(RTRIM(A.ReportName )))))   --06. ������    
                       + CONVERT(VARCHAR(20), LTRIM(RTRIM(A.ExpermitNm ))) + SPACE(20 - DATALENGTH(CONVERT(VARCHAR(20), LTRIM(RTRIM(A.ExpermitNm )))))   --07. �߱���    
                       + CASE WHEN ISNULL(A.ExpermitDate, '') = '' THEN SPACE(8) ELSE A.ExpermitDate END       --08. �߱�����    
                       + CASE WHEN ISNULL(A.ShippingDate, '') = '' THEN SPACE(8) ELSE A.ShippingDate END       --09. ��������    
                       + CASE WHEN ISNULL(A.CurrSeq, 0) = 0 THEN SPACE(3) ELSE ( CASE A.CurrSeq WHEN @StkCurrSeq THEN @KorCurrNo ELSE B.CurrName END ) END      --10. ������ȭ�ڵ�
                       + RIGHT('000000000' + REPLACE(CONVERT(VARCHAR(10), CONVERT(NUMERIC(19, 4), CASE WHEN ISNULL(B.BasicAmt, 0) = 0 THEN A.ExRate ELSE A.ExRate/B.BasicAmt END)), '.', ''), 9)   --11. ȯ��    
                       + CASE WHEN A.ForAmt1 >= 0 THEN    
                               RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), A.ForAmt1)), '.', ''), 15)    
                          ELSE    
                               STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), ABS(CONVERT(NUMERIC(19, 2), A.ForAmt1))), '.', ''), 15), 1, 1, '-')    
                          END             --12. �������ݾ�(��ȭ)    
                       + CASE WHEN A.KoAmt1 >= 0 THEN    
                               RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(A.KoAmt1)), 15)    
                          ELSE    
                               STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.KoAmt1))), 15), 1, 1, '-')    
                          END            --13. �������ݾ�(��ȭ)    
                       + CASE WHEN A.ForAmt2 >= 0 THEN    
                               RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), A.ForAmt2)), '.', ''), 15)    
                          ELSE    
                               STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), ABS(CONVERT(NUMERIC(19, 2), A.ForAmt2))), '.', ''), 15), 1, 1, '-')    
                          END             --14. ���Ű��ش��(��ȭ)    
                       + CASE WHEN A.KoAmt2 >= 0 THEN    
                               RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(A.KoAmt2)), 15)
                          ELSE    
                               STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.KoAmt2))), 15), 1, 1, '-')    
                          END            --15. ���Ű��ش��(��ȭ)    
                       + SPACE(25)       --16. ����    
                       , 250  
             FROM _TTAXZero AS A WITH(NOLOCK)
                                 LEFT OUTER JOIN _TDACurr AS B WITH(NOLOCK)
                                   ON A.CompanySeq  = B.CompanySeq  
                                  AND A.CurrSeq     = B.CurrSeq  
             WHERE A.CompanySeq     = @CompanySeq  
               AND A.TaxTermSeq     = @TaxTermSeq  
               AND A.TaxUnit        = @TaxUnit  
        END  
    END    
END  
-- /***************************************************************************************************************************    
-- �������Լ��װ����Ű�
-- ****************************************************************************************************************************/      
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT * FROM _TTAXFictionSum WITH(NOLOCK) WHERE CompanySeq = @CompanySEq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)    
    BEGIN    
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT    '17'     --01. �ڷᱸ��    
                       + 'I102300'    --02. �����ڵ�    
                       + RIGHT('0000000' + CONVERT(VARCHAR(7), SUM(ISNULL(BillCustCnt,0)+ISNULL(CardCustCnt,0)+ISNULL(FarmCustCnt,0))),  7) --03.�ŷ�ó��_�հ�    
                       + RIGHT('00000000000' + CONVERT(VARCHAR(11), FLOOR(SUM(ISNULL(BillCnt,0)+ISNULL(CardCnt,0)+ISNULL(FarmCnt,0)))), 11) --04.���԰Ǽ�_�հ�    
                       + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(ISNULL(BillSpplyAmt,0)+ISNULL(CardSpplyAmt,0)+ISNULL(FarmSpplyAmt,0)))), 15) --05.���Աݾ�_�հ�    
                       + CASE WHEN SMSumDeductRate = 4143001 THEN '2' -- 2/102  
                              WHEN SMSumDeductRate = 4143002 THEN '6' -- 6/106  
                              WHEN SMSumDeductRate = 4143003 THEN '9' -- 2/102 OR 6/106  
                              WHEN SMSumDeductRate = 4143004 THEN '8' -- 8/108  
                              WHEN SMSumDeductRate = 4143005 THEN '0' -- 2/102 Or 8/108  
                              WHEN SMSumDeductRate = 4143006 THEN '4' -- 4/104  
                              WHEN SMSumDeductRate = 4143007 THEN 'A' -- 2/102 Or 4/104  
                              WHEN SMSumDeductRate = 4143008 THEN 'B' -- 4/104 Or 6/106  
                              WHEN SMSumDeductRate = 4143009 THEN 'C' -- 4/104 Or 8/108  
                              WHEN SMSumDeductRate = 4143010 THEN 'D' -- 2/102 Or 4/104 Or 6/106  
                              WHEN SMSumDeductRate = 4143011 THEN 'E' -- 2/102 Or 4/104 Or 8/108  
                              ELSE SPACE(1) END -- 06.����������_�հ�    
                       + RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(ISNULL(BillVATAmt,0)+ISNULL(CardVATAmt,0)+ISNULL(FarmVATAmt,0)))), 13) --07.�����������Լ���_�հ�
                       -- ��꼭
                       + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(ISNULL(BillCustCnt,0))), 6)                    --08.�ŷ�ó��_��꼭    
                       + RIGHT('00000000000' + CONVERT(VARCHAR(11), FLOOR(SUM(ISNULL(BillCnt,0)))), 11)          --09.���԰Ǽ�_��꼭    
                       + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(ISNULL(BillSpplyAmt,0)))), 15) --10.���Աݾ�_��꼭    
                       + CASE WHEN SMBillDeductRate = 4143001 THEN '2' -- 2/102  
                              WHEN SMBillDeductRate = 4143002 THEN '6' -- 6/106  
                              WHEN SMBillDeductRate = 4143003 THEN '9' -- 2/102 OR 6/106  
                              WHEN SMBillDeductRate = 4143004 THEN '8' -- 8/108  
                              WHEN SMBillDeductRate = 4143005 THEN '0' -- 2/102 Or 8/108  
                              WHEN SMBillDeductRate = 4143006 THEN '4' -- 4/104  
                              WHEN SMBillDeductRate = 4143007 THEN 'A' -- 2/102 Or 4/104  
                              WHEN SMBillDeductRate = 4143008 THEN 'B' -- 4/104 Or 6/106  
                              WHEN SMBillDeductRate = 4143009 THEN 'C' -- 4/104 Or 8/108  
                              WHEN SMBillDeductRate = 4143010 THEN 'D' -- 2/102 Or 4/104 Or 6/106  
                              WHEN SMBillDeductRate = 4143011 THEN 'E' -- 2/102 Or 4/104 Or 8/108  
                              ELSE SPACE(1) END                                                                  --11.����������_��꼭    
                       + RIGHT('0000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(ISNULL(BillVATAmt,0)))), 13)     --12.�����������Լ���_��꼭
                       -- �ſ�ī��
                       + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(ISNULL(CardCustCnt,0))), 6)                    --13.�ŷ�ó��_�ſ�ī��    
                       + RIGHT('00000000000' + CONVERT(VARCHAR(11), FLOOR(SUM(ISNULL(CardCnt,0)))), 11)          --14.���԰Ǽ�_�ſ�ī��    
                       + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(ISNULL(CardSpplyAmt,0)))), 15) --15.���Աݾ�_�ſ�ī��    
                       + CASE WHEN SMCardDeductRate = 4143001 THEN '2' -- 2/102  
                              WHEN SMCardDeductRate = 4143002 THEN '6' -- 6/106  
                              WHEN SMCardDeductRate = 4143003 THEN '9' -- 2/102 OR 6/106  
                              WHEN SMCardDeductRate = 4143004 THEN '8' -- 8/108  
                              WHEN SMCardDeductRate = 4143005 THEN '0' -- 2/102 Or 8/108  
                              WHEN SMCardDeductRate = 4143006 THEN '4' -- 4/104  
                              WHEN SMCardDeductRate = 4143007 THEN 'A' -- 2/102 Or 4/104  
                              WHEN SMCardDeductRate = 4143008 THEN 'B' -- 4/104 Or 6/106  
                              WHEN SMCardDeductRate = 4143009 THEN 'C' -- 4/104 Or 8/108  
                              WHEN SMCardDeductRate = 4143010 THEN 'D' -- 2/102 Or 4/104 Or 6/106  
                              WHEN SMCardDeductRate = 4143011 THEN 'E' -- 2/102 Or 4/104 Or 8/108  
                              ELSE SPACE(1) END                                                                  --16.����������_�ſ�ī��  
                       + RIGHT('0000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(ISNULL(CardVATAmt,0)))), 13)     --17.�����������Լ���_�ſ�ī��
                       -- ����
                       + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(ISNULL(FarmCustCnt,0))), 6)                    --18.�ŷ�ó��_����    
                       + RIGHT('00000000000' + CONVERT(VARCHAR(6), FLOOR(SUM(ISNULL(FarmCnt,0)))), 11)           --19.���԰Ǽ�_����    
                       + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(ISNULL(FarmSpplyAmt,0)))), 15) --20.���Աݾ�_����    
                       + CASE WHEN SMFarmDeductRate = 4143001 THEN '2' -- 2/102  
                              WHEN SMFarmDeductRate = 4143002 THEN '6' -- 6/106  
                          WHEN SMFarmDeductRate = 4143003 THEN '9' -- 2/102 OR 6/106  
                              WHEN SMFarmDeductRate = 4143004 THEN '8' -- 8/108  
                              WHEN SMFarmDeductRate = 4143005 THEN '0' -- 2/102 Or 8/108  
                              WHEN SMFarmDeductRate = 4143006 THEN '4' -- 4/104  
                              WHEN SMFarmDeductRate = 4143007 THEN 'A' -- 2/102 Or 4/104  
                              WHEN SMFarmDeductRate = 4143008 THEN 'B' -- 4/104 Or 6/106  
                              WHEN SMFarmDeductRate = 4143009 THEN 'C' -- 4/104 Or 8/108  
                              WHEN SMFarmDeductRate = 4143010 THEN 'D' -- 2/102 Or 4/104 Or 6/106  
                              WHEN SMFarmDeductRate = 4143011 THEN 'E' -- 2/102 Or 4/104 Or 8/108  
                              ELSE SPACE(1) END --21.����������_����  
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(FarmVATAmt   ,0))), 13, 0, 1)    --22.����a_����                           
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(PlanAmt      ,0))), 15, 0, 1)    --23.����ǥ��_������  
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(FinalAmt     ,0))), 15, 0, 1)    --24.����ǥ��_Ȯ����  
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(SumTaxAmt    ,0))), 15, 0, 1)    --25.����ǥ��_�հ�  
                       + ISNULL( MAX( CASE WHEN SMLimitRate = '9' THEN '3'      --35/100�� ��� ���� 30/100�� �����ϱ� ���� ������ 9�� �ǳ� �Ű��ڵ�� '3'
                                           WHEN SMLimitRate IN ('', '0') THEN SPACE(1)
                                           ELSE SMLimitRate END ),SPACE(1))                 --26.�����ѵ����_�ѵ���
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(LimitAmt     ,0))), 15, 0, 1)    --27.�����ѵ����_�ѵ���  
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(BuyingAmt    ,0))), 15, 0, 1)    --28.�����Ծ�  
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(DeductAmt    ,0))), 15, 0, 1)    --29.�������ݾ�
                       + CASE WHEN SMDeductRate = 4143001 THEN '2' -- 2/102    
                              WHEN SMDeductRate = 4143002 THEN '6' -- 6/106    
                              WHEN SMDeductRate = 4143003 THEN '9' -- 2/102 OR 6/106    
                              WHEN SMDeductRate = 4143004 THEN '8' -- 8/108    
                              WHEN SMDeductRate = 4143005 THEN '0' -- 2/102 Or 8/108    
                              WHEN SMDeductRate = 4143006 THEN '4' -- 4/104    
                              WHEN SMDeductRate = 4143007 THEN 'A' -- 2/102 Or 4/104    
                              WHEN SMDeductRate = 4143008 THEN 'B' -- 4/104 Or 6/106    
                              WHEN SMDeductRate = 4143009 THEN 'C' -- 4/104 Or 8/108    
                              WHEN SMDeductRate = 4143010 THEN 'D' -- 2/102 Or 4/104 Or 6/106    
                              WHEN SMDeductRate = 4143011 THEN 'E' -- 2/102 Or 4/104 Or 8/108    
                              ELSE SPACE(1) END --30.������󼼾�_������
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(DeductCompTax    ,0))), 13, 0, 1)        --31.������󼼾�_������󼼾�
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(PlandeductedTax  ,0))), 13, 0, 1)        --32.�̹̰�����������_�����Ű��
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(MondeductedTax   ,0))), 13, 0, 1)        --33.�̹̰�����������_���������  
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(SumdeductedTax   ,0))), 13, 0, 1)        --34.�̹̰�����������_�հ�  
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(DeductTax        ,0))), 13, 0, 1)        --35.����(����)�Ҽ���
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.StdSumTaxAmt1,0))),   15,0,1)     --36.��1��_����ǥ��(������)                    (15)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.StdSumTaxAmt2,0))),   15,0,1)     --37.��2��_����ǥ��(������)                    (15)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.StdSumTaxAmt,0))),    15,0,1)     --38.1�������ǥ���հ�(������)                 (15)
                       + CONVERT(CHAR(1), ISNULL(MAX(CASE WHEN Fic.SMLimitrate4 = '9' THEN '3'          --35/100�� ��� ���� 30/100�� �����ϱ� ���� ������ 9�� �ǳ� �Ű��ڵ�� '3'
                                                          WHEN Fic.SMLimitrate4 IN ('', '0') THEN SPACE(1)
                                                          ELSE Fic.SMLimitrate4 END),SPACE(1))) --39.�����ѵ����_�ѵ���(������)             (1)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.LimitAmt4,0)))    ,   15,0,1)     --40.�����ѵ����_�ѵ���(������)             (15)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.BuySumTaxAmt1,0))),   15,0,1)     --41.��1��_���Ծ�(������)                      (15)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.BuySumTaxAmt2,0))),   15,0,1)     --42.��2��_���Ծ�(������)                      (15)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.BuySumTaxAmt,0))),    15,0,1)     --43.1������Ծ��հ�(������)                   (15)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.DeductAmt4,0))),      15,0,1)     --44.�������ݾ�(������)                      (15)
                       + MAX( CASE WHEN SMDeductRate4 = 4143001 THEN '2' -- 2/102    
                                   WHEN SMDeductRate4 = 4143002 THEN '6' -- 6/106    
                                   WHEN SMDeductRate4 = 4143003 THEN '9' -- 2/102 OR 6/106    
                                   WHEN SMDeductRate4 = 4143004 THEN '8' -- 8/108    
                                   WHEN SMDeductRate4 = 4143005 THEN '0' -- 2/102 Or 8/108    
                                   WHEN SMDeductRate4 = 4143006 THEN '4' -- 4/104    
                                   WHEN SMDeductRate4 = 4143007 THEN 'A' -- 2/102 Or 4/104    
                                   WHEN SMDeductRate4 = 4143008 THEN 'B' -- 4/104 Or 6/106    
                                   WHEN SMDeductRate4 = 4143009 THEN 'C' -- 4/104 Or 8/108    
                                   WHEN SMDeductRate4 = 4143010 THEN 'D' -- 2/102 Or 4/104 Or 6/106    
                                   WHEN SMDeductRate4 = 4143011 THEN 'E' -- 2/102 Or 4/104 Or 8/108    
                                   ELSE SPACE(1) END )                               --45.������󼼾�_������(������)               (1)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.DeductCompTax4,0))),  13,0,1)     --46.������󼼾�(������)                      (13)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.TotDeductTax1,0))),   13,0,1)     --47.��1��_�̹̰�����������(������)            (13)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.TotPlanTax,0))),      13,0,1)     --48.��2��_�̹̰�����������_������(������)     (13)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.TotMonTax,0))),       13,0,1)     --49.��2��_�̹̰�����������_���������(������) (13)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.TotDeductTax2,0))),   13,0,1)     --50.��2��_�̹̰�����������_�հ�(������)       (13)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.TotDeductTax,0))),    13,0,1)     --51.�̹̰�����������_���հ�(������)           (13)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.DeductTax4,0))),      13,0,1)     --52.����(����)�Ҽ���(������)                  (13)
                       + SPACE(36)                                                              --53.����                                      (36)
                       , 600 
              FROM _TTAXFictionSum AS Fic WITH(NOLOCK)
             WHERE Fic.CompanySeq   = @CompanySeq  
               AND Fic.TaxTermSeq   = @TaxTermSeq  
               AND Fic.TaxUnit      = @TaxUnit  
               AND ( Fic.BillCustCnt <> 0 OR Fic.BillSpplyAmt <> 0 OR Fic.BillVATAmt <> 0 OR Fic.CardCustCnt <> 0 OR Fic.CardCnt <> 0   
                  OR Fic.CardSpplyAmt <> 0 OR Fic.CardVATAmt <> 0 OR Fic.FarmCustCnt <> 0 OR Fic.FarmCnt <> 0 OR Fic.FarmSpplyAmt <> 0  
                  OR Fic.FarmVATAmt <> 0)  
             GROUP BY SMSumDeductRate, SMBillDeductRate, SMCardDeductRate, SMFarmDeductRate, SMDeductRate
    END   
    
    IF EXISTS (SELECT 1 FROM _TTAXFictionDetail WITH(NOLOCK) WHERE CompanySeq = @CompanySEq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND IsFF = 1)    
    BEGIN     
              INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
               SELECT    '18'     --01. �ڷᱸ��    
                        + 'I102300'    --02. �����ڵ�        
                        + RIGHT('000000' + CONVERT(NVARCHAR(6), ROW_NUMBER() OVER (ORDER BY A.CustSeq)), 6)        -- 03. �Ϸù�ȣ(6)
                        + dbo._FCOMDecrypt(B.PersonID, '_TDACust', 'PersonId', @CompanySeq)          -- 04. �ֹε�Ϲ�ȣ(13)
                        + dbo._FnVATCHARChg(B.Owner, 30, 1)         -- 05. ����(30) 
                        + dbo._FnVATIntChg(COUNT(*), 11, 0, 1)      -- 06. ���԰Ǽ�(11)
                        + dbo._FnVATCHARChg(C.ItemName, 30, 1)      -- 07. ǰ��(30)
                        + dbo._FnVATIntChg(SUM(A.OrgQty), 20, 0, 1) -- 08. ���Լ���(20)
                        + dbo._FnVATIntChg(SUM(A.OrgAmt), 13, 0, 1) -- 09. ���Աݾ�(13)
                        + SPACE(68)    -- 10 ���� (71)
                        , 200
                  FROM _TTAXFictionDetail AS A WITH(NOLOCK)
                                            JOIN _TDACust AS B WITH (NOLOCK)
                                              ON A.CompanySeq = B.CompanySeq
                                             AND A.CustSeq    = B.CustSeq
                                            JOIN _TDAItem AS C WITH (NOLOCK)
                                              ON A.CompanySeq = C.CompanySeq
                                             AND A.ItemSeq    = C.ItemSeq
                 WHERE A.CompanySeq = @CompanySeq
                   and A.TaxTermSeq  = @TaxTermSeq
                   AND A.TaxUnit      = @TaxUnit
                   AND A.IsFF = '1'
                 GROUP BY A.CustSeq, B.PersonID, B.Owner, C.ItemName
                  
              
     
    END 
         
END      

/***************************************************************************************************************************    
        ��Ȱ�����ڿ��� �� �߰��ڵ������Լ��װ����Ű�_�հ�  
****************************************************************************************************************************/    
IF @WorkingTag = ''
BEGIN
  
    IF EXISTS (SELECT * FROM _TTAXRecycleSet WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)    
    BEGIN    
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT '17'     --01. �ڷᱸ��    
                   + 'M116300'    --02. �����ڵ�    
                   + RIGHT('0000000'     + CONVERT(VARCHAR(7) , SUM(ISNULL(ReceiptCustCnt,0)+ISNULL(BillCustCnt,0))), 7) --03.����ó�� �հ�    
                   + RIGHT('00000000000' + CONVERT(VARCHAR(11), SUM(ISNULL(ReceiptCnt,0)+ISNULL(BillCnt,0))), 11)        --04.���԰Ǽ�_�հ�
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(ReceiptAmt,0)+ISNULL(BillAmt,0)))           , 15, 0, 1) --05.���Աݾ�_�հ� 
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(ReceiptVATAmt,0)+ISNULL(BillVATAmt,0)))     , 15, 0, 1) --06.���Լ��װ�����_�հ�
                   + RIGHT('000000'      + CONVERT(VARCHAR(6) , SUM(ISNULL(ReceiptCustCnt,0))), 6)  --07.����ó��_������  
                   + RIGHT('00000000000' + CONVERT(VARCHAR(11), SUM(ISNULL(ReceiptCnt,0)))    ,11)  --08.���԰Ǽ�_������
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(ReceiptAmt      ,0)))   , 15, 0, 1)     --09.���Աݾ�_������  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(ReceiptVATAmt   ,0)))   , 15, 0, 1)     --10.�����������Լ���_������
                   + RIGHT('000000'      + CONVERT(VARCHAR(6) , SUM(ISNULL(BillCustCnt,0))), 6) --11.����ó��_��꼭
                   + RIGHT('00000000000' + CONVERT(VARCHAR(11), SUM(ISNULL(BillCnt,0)))    ,11) --12.���԰Ǽ�_��꼭
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(BillAmt         ,0)))   , 15, 0, 1)     --13.���Աݾ�_��꼭
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(BillVATAmt      ,0)))   , 15, 0, 1)     --14.���Լ��װ���_��꼭  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(SumSalesAmt     ,0)))   , 15, 0, 1)     --15.�հ� �����  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(PlanAmt         ,0)))   , 15, 0, 1)     --16.������ �����  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(FinalAmt        ,0)))   , 15, 0, 1)     --17.Ȯ���и����
                   + '00080'                                                                    --18.�ѵ���  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(LimitAmt        ,0)))   , 15, 0, 1)     --19.�����ѵ����_�ѵ��� 
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(SumBuyingAmt    ,0)))   , 15, 0, 1)     --20.�հ�����Ծ� 
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(BillBuyingAmt   ,0)))   , 15, 0, 1)     --21.�հ�����Ծ�_���ݰ�꼭  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(ReciptBuyingAmt ,0)))   , 15, 0, 1)     --22.�հ�����Ծ�_������
                   + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(ISNULL(DeductibleAmt  ,0)))), 15) --23.���������ѱݾ�                     
                   + CASE WHEN MAX(Recycle.SMDeductRate) = '1' THEN RIGHT('00000' + CONVERT(VARCHAR(5), '00005'), 5)
                                                               ELSE RIGHT('00000' + CONVERT(VARCHAR(5), '00003'), 5) END    --24.������ ����  
                   + CASE WHEN MAX(Recycle.SMDeductRate) = '1' THEN RIGHT('00000' + CONVERT(VARCHAR(5), '00105'), 5) 
                                                               ELSE RIGHT('00000' + CONVERT(VARCHAR(5), '00103'), 5) END    --25.������ �и�
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(DeductAmt       ,0)))   , 15, 0, 1)     --26.�������ݾ�  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(DeductCompTax   ,0)))   , 13, 0, 1)     --27.������󼼾�  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(SumdeductedTax  ,0)))   , 13, 0, 1)     --28.�̹̰�����������_�հ�  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(PlandeductedTax ,0)))   , 13, 0, 1)     --29.�̹̰�����������_�����Ű��  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(MondeductedTax  ,0)))   , 13, 0, 1)     --30.�̹̰�����������_���������   
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(DeductTax       ,0)))   , 13, 0, 1)     --31.����(����)�Ҽ���                                      
                   + SPACE(34)    
                   , 400    
         FROM _TTAXRecycleSet AS Recycle WITH (NOLOCK)    
         WHERE CompanySeq = @CompanySeq 
           AND TaxTermSeq = @TaxTermSeq 
           AND TaxUnit = @TaxUnit
           
       CREATE TABLE #TATRecycleTaxDeduc  
        (Seq                INT IDENTITY(1,1),  
         PersonId_TelexNo   NVARCHAR(200) NULL,  
         CustNm             NVARCHAR(200) NULL,  
         Cnt                NUMERIC(19,5) NULL,  
         ItemNm             NVARCHAR(30)  NOT NULL,  
         Qty                NUMERIC(19,5) NOT NULL,  
         GainAmt            NUMERIC(19,5) NOT NULL,  
         CarNumber          CHAR(20)      NOT NULL,  
         CarIDNumber        CHAR(20)      NOT NULL )  
  
      INSERT INTO #TATRecycleTaxDeduc(PersonId_TelexNo, CustNm, Cnt, ItemNm, Qty, GainAmt,CarNumber,CarIDNumber)  
         SELECT CASE WHEN ISNULL(B.PersonId,'') <> ''   
                     THEN dbo._FCOMDecrypt(PersonId, '_TDACust', 'PersonId', @CompanySeq)  
                     ELSE ISNULL(B.BizNo,'')
                END,  
                B.CustName,A.Cnt,C.ItemName,A.Qty, A.GainAmt, A.CarNumber, A.CarIDNumber  
           FROM _TTAXRecycleSetDetail AS A WITH (NOLOCK)  
                    JOIN _TDACust AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.CustSeq = B.CustSeq
                    JOIN _TDAItem AS C WITH (NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.ItemSeq = C.ItemSeq
          WHERE A.CompanySeq = @CompanySeq
        AND A.SupplyDate BETWEEN @TaxFrDate AND @TaxToDate    
            AND A.TaxUnit       = @TaxUnit  
  
/***************************************************************************************************************************    
        ��Ȱ�����ڿ��� �� �߰��ڵ������Լ��װ����Ű�_��  
****************************************************************************************************************************/  
           INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)   
                 SELECT '18'                                                            -- 01. �ڷᱸ��  
                       + 'M116300'                                                      -- 02. �����ڵ�  
                       + RIGHT('000000' + CONVERT(VARCHAR(6), Seq), 6)                  -- 03. �Ϸù�ȣ  
                       + dbo.fnVATCHARChg(CONVERT(VARCHAR(60), CustNm), 60, 1)          -- 04. �����ڼ���_��ȣ  
                       + dbo.fnVATCHARChg(CONVERT(VARCHAR(13), PersonId_TelexNo),13,1)  -- 05. �������ֹ�(�����)��ȣ  
                       + dbo.fnVATIntChg(ISNULL(Cnt,0),11,0,1)                          -- 06. �Ǽ�  
                       + dbo.fnVATCHARChg(CONVERT(VARCHAR(30), ItemNm), 30, 1)          -- 07. ǰ��  
                       + dbo.fnVATIntChg(ISNULL(Qty,0),11,0,1)                          -- 08. ����  
                       + dbo.fnVATIntChg(ISNULL(GainAmt,0),13,0,1)                      -- 09. ���ݾ�  
                       + dbo.fnVATCHARChg(CONVERT(VARCHAR(20), CarNumber),20,1)         -- 10. ������ȣ  
                       + dbo.fnVATCHARChg(CONVERT(VARCHAR(17), CarIDNumber),17,1)       -- 11. �����ȣ  
                       + SPACE(10)    
                        , 200    
                   FROM #TATRecycleTaxDeduc  
        END
END
  

  
/***************************************************************************************************************************    
�ε����Ӵ�������� ����    
  
01. �ڷᱸ��(2) : 17    
02. �����ڵ�(7) : I103600 / V120
03. �Ϸù�ȣ����(6) : 000001 Fix    
04. �ε��������(70)    
05. �Ӵ��೻�� �������հ�(15)    
06. �Ӵ��೻�� �������հ�(15)    
07. �Ӵ�� ���Աݾ��հ�(15)    
08. �Ӵ�� ���Ժ����������հ�(15)    
09. �Ӵ�ǥ ���Կ������հ�(15)    
10. �Ӵ��λ���ڵ�Ϲ�ȣ(10)    
11. �Ӵ�Ǽ�(6)    
12. ��������Ϸù�ȣ(4)    
13. ����(70)    
****************************************************************************************************************************/   
/***************************************************************************************************************************    
�ε����Ӵ���ް��׸��� ���γ���    
    
01. �ڷᱸ��(2) : 18    
02. �����ڵ�(7) : I103600 / V120
03. �Ϸù�ȣ����(6)    
04. �Ϸù�ȣ(6)    
05. ��(10)
06. ��(30)    
07. ȣ��(10)    
08. ����(10)    
09. �����λ�ȣ(����)(30)    
10. ������ ����ڵ�Ϲ�ȣ(13)    
11. �Ӵ��� ������(8)    
12. �Ӵ��� �����(8)    
13. �Ӵ��೻�� ������(13)    
14. �Ӵ��೻����Ӵ��(13)    
15. �Ӵ�� ���Աݾְ�(��ǥ)(13)    
16. �Ӵ�� ����������(13)    
17. �Ӵ����Աݾ׿��Ӵ��(13)    
18. ��������Ϸù�ȣ(4)    
19. �Ӵ���������������(8)
20. ����(33)    
****************************************************************************************************************************/     
IF @WorkingTag IN ('','E')  
BEGIN  
    IF EXISTS (SELECT * FROM _TTAXLandLease WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq)  -- �ֻ���ڿ� ��� �ȵǾ� �ִ� Case�� �����Ͽ� @TaxUnit ����   
    BEGIN  
        IF @WorkingTag  = 'E' -- ���ϽŰ�(�ε����Ӵ�)
        BEGIN  
            --=============================================================================    
            -- ������ ��������(HEAD RECORD)      
            --=============================================================================    
            --��ȣ  �׸�                        ����  ����  ��������  ���    
            --1   ���ڵ屸��                    ����  2     2         EH    
            --2   �ͼӳ⵵                      ����  4     6         YYYY��    
            --3   �ݱⱸ��                      ����  1     7         1: 1��, 2: 2��    
            --4   �ݱ⳻ �� ����                ����  1     8         1/2/3/4/5/6    
            --5   ������(������)����ڵ�Ϲ�ȣ  ����  10    18    
            --6   ��ȣ(���θ�)                  ����  60    78    
            --7   ����(��ǥ��)                  ����  30    108    
            --8   �ֹ�(����)��Ϲ�ȣ            ����  13    121    
            --9   ��������                      ����  8     129    
            --10  ������(������)��ȭ��ȣ        ����  12    141    
            --11  ����                          ����  109   250       SPACE  
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)      
                SELECT 'EH'                         -- ���ڵ屸��      
                    +  LEFT(@TaxFrDate, 4)          -- �ͼӳ⵵      
                    +  @TermKind                    -- �ݱⱸ��      
                    +  @YearHalfMM                  -- �ݱ⳻ �� ����      
                    + CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '') + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '') )))) -- ������(������)����ڵ�Ϲ�ȣ    
                    + CONVERT(VARCHAR(60), TaxName                 + SPACE(60 - DATALENGTH(CONVERT(VARCHAR(60), TaxName                 )))) -- ��ȣ(���θ�)    
                    + CONVERT(VARCHAR(30), Owner                   + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), Owner                   )))) -- ����(��ǥ��)        
                    + CONVERT(VARCHAR(13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','') 
                       + SPACE(13 - DATALENGTH(CONVERT(VARCHAR(13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','') )))) -- �ֹ�(����)��Ϲ�ȣ    
                    + CONVERT(VARCHAR( 8), @CurrDate               + SPACE( 8 - DATALENGTH(CONVERT(VARCHAR( 8), @CurrDate               )))) -- ��������    
                    + CONVERT(VARCHAR(12), TelNo                   + SPACE(12 - DATALENGTH(CONVERT(VARCHAR(12), TelNo                   )))) -- ������(������)��ȭ��ȣ    
                    + SPACE(109)    -- ����    
                    , 250    
                FROM #TDATaxUnit WITH(NOLOCK)
                WHERE CompanySeq  = @CompanySeq    
                  AND TaxUnit     = @TaxUnit    
            --=============================================================================    
            -- �ε����Ӵ���ް��׸���(DATA RECORD)      
            --=============================================================================    
            --��ȣ  �׸�                        ����  ����  ��������  ���    
            --1   ���ڵ屸��                    ����  2     2         ED    
            --2   �ͼӳ⵵                      ����  4     6         YYYY��    
            --3   �ݱⱸ��                      ����  1     7         1: 1��, 2: 2��    
            --4   �ݱ⳻ �� ����                ����  1     8         1/2/3/4/5/6    
            --5   ������(������)����ڵ�Ϲ�ȣ  ����  10    18    
            --6   �Ϸù�ȣ����                  ����  6     24        SEQ    
            --7   �Ϸù�ȣ                      ����  6     30        SEQ    
            --8   ��                            ����  10    40    
            --9   ȣ��                          ����  10    50    
            --10  ����                          ����  10    60    
            --11  �����λ�ȣ(����)              ����  30    90    
            --12  �����λ���ڵ�Ϲ�ȣ          ����  13    103       MONEY CD,������    
            --13  �Ӵ���������                ����  8     111 
            --14  �Ӵ��������                ����  8     119   
            --15  �Ӵ��೻�뺸����            ����  13    132    
            --16  �Ӵ��೻����Ӵ��          ����  13    145    
            --17  �Ӵ����Աݾװ�(����ǥ��)    ����  13    158    
            --18  �Ӵ�Ẹ��������              ����  13    171
            --19  �Ӵ����Աݾ׿��Ӵ��        ����  13    184
            --20  ���Ͽ���[����]                ����  1     185       SPACE
            --21  ��������Ϸù�ȣ              ����  4     189
            --22  ��                            ����  20    209
            --23  ������                        ����  8     217                        
            --24  ����                          ����  33    250       SPACE 
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)   
                SELECT 'ED'                         -- 1.���ڵ屸��      
                    +  LEFT(@TaxFrDate, 4)          -- 2.�ͼӳ⵵      
                    +  @TermKind                    -- 3.�ݱⱸ��      
                    +  @YearHalfMM                  -- 4.�ݱ⳻ �� ����      
                    +  dbo._FnVATCHARChg(convert(VARCHAR(10), @TaxNo)       ,10,1)                  -- 5.������(������)����ڵ�Ϲ�ȣ      
                    + '000001'                      -- 6.�Ϸù�ȣ����    
                    + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY Land.LandSerl)), 6) --7.�Ϸù�ȣ    
                    + CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.FloorNum   ))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.FloorNum   )))))   --8.��    
                    + CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.RegNum     ))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.RegNum     )))))   --9.ȣ��    
                    + RIGHT('0000000000' + CONVERT(VARCHAR(10), LTRIM(RTRIM(FLOOR(CASE WHEN Land.LandSize = '' THEN '0' ELSE REPLACE(Land.LandSize, ',', '') END)))), 10) --10.����, �޸��� �� ��� �����߻��Ͽ� ���÷��̽� �Լ� �߰� 2016.01.25. by shpark          
                    + LTRIM(RTRIM(CONVERT(VARCHAR(30), Cust.FullName))) + SPACE(30 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(30), Cust.FullName))))) --11.�����λ�ȣ(����)    
                    + CASE WHEN ISNULL(REPLACE(Cust.BizNo, '-', ''), '') = '' THEN    
                            LTRIM(RTRIM(REPLACE(dbo._FCOMDecrypt(Cust.PersonId, '_TDACust', 'PersonId', @CompanySeq),'-',''))) 
                            + SPACE(13 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(13),REPLACE(dbo._FCOMDecrypt(Cust.PersonId, '_TDACust', 'PersonId', @CompanySeq),'-',''))))))    
                       ELSE    
                            LTRIM(RTRIM(REPLACE(Cust.BizNo, '-', ''))) + SPACE(13 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(13),REPLACE(Cust.BizNo, '-', ''))))))    
                       END --12.������ ����ڵ�Ϲ�ȣ    
                    + LTRIM(RTRIM(Land.FrDate)) + SPACE(8 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8),Land.FrDate))))) --13.�Ӵ��� ������    
                    + LTRIM(RTRIM(Land.ToDate)) + SPACE(8 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8),Land.ToDate))))) --14.�Ӵ��� �����    
                    + dbo.fnVATIntChg( FLOOR(Land.Deposit)                                ,13,0,1)    --15.�Ӵ��೻�� ������
                    + dbo.fnVATIntChg( FLOOR(Land.MonthlyRent)                            ,13,0,1)    --16.�Ӵ����Աݾ׿��Ӵ��
                    + dbo.fnVATIntChg( FLOOR(Land.DepositInterest + Land.MonthlyRentTot)  ,13,0,1)    --17.�Ӵ����Աݾװ�(����ǥ��)
                    + dbo.fnVATIntChg( FLOOR(Land.DepositInterest)                        ,13,0,1)    --18.�Ӵ�� ����������
                    + dbo.fnVATIntChg( FLOOR(Land.MonthlyRentTot)                         ,13,0,1)    --19.�Ӵ����Աݾ׿��Ӵ��
                    + SPACE(1)  --20.���Ͽ���[����]    
                    + '0000'  --21.��������Ϸù�ȣ  
                    + LTRIM(RTRIM(CONVERT(VARCHAR(20), ISNULL(Land.Dong   , '')))) + SPACE(20 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(20), ISNULL(Land.Dong   , '')))))) --19.��    
                    + LTRIM(RTRIM(CONVERT(VARCHAR(8) , ISNULL(Land.ModDate, '')))) + SPACE(8  - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8) , ISNULL(Land.ModDate, '')))))) --20.������    
                    + SPACE(33)    
                    , 250    
                FROM _TTAXLandLeaseDtl AS Land WITH(NOLOCK)
                                               JOIN _TTAXLandLease AS Dtl WITH(NOLOCK)
                                                 ON Land.CompanySeq = Dtl.CompanySeq  
                                                AND Land.TaxTermSeq = Dtl.TaxTermSeq  
                                                AND Land.TaxUnit    = Dtl.TaxUnit   
                                                AND Land.LandPlaceSeq = Dtl.LandPlaceSeq  
                                               LEFT OUTER JOIN _TDACust AS Cust WITH(NOLOCK)
                                              ON Land.CompanySeq = Cust.CompanySeq  
                                                AND Land.CustSeq    = Cust.CustSeq  
                WHERE Land.CompanySeq  = @CompanySeq  
                  AND Land.TaxTermSeq  = @TaxTermSeq  
                  AND Land.TaxUnit     = @TaxUnit  

            --=============================================================================    
            -- �ε����Ӵ���ް��׸���  �հ�(TAIL RECORD)      
            --=============================================================================    
            --��ȣ  �׸�                        ����  ����  ��������  ���    
            --1   ���ڵ屸��                    ����  2     2         ET    
            --2   �ͼӳ⵵                      ����  4     6         YYYY����    
            --3   �ݱⱸ��                      ����  1     7         1: 1��, 2: 2��    
            --4   �ݱ⳻ �� ����                ����  1     8         1/2/3/4/5/6    
            --5   ������(������)����ڵ�Ϲ�ȣ  ����  10    18    
            --6   DATA �Ǽ�                     ����  7     25  
            --7   �Ϸù�ȣ����                  ����  6     31  
            --8   �ε��������                  ����  70    101
            --9   �Ӵ��೻�뺸�����հ�        ����  15    116
            --10  �Ӵ��೻��������հ�        ����  15    131
            --11  �Ӵ����Աݾ��հ�            ����  15    146
            --12  �Ӵ����Ժ����������հ�      ����  15    161
            --13  �Ӵ����Կ������հ�          ����  15    176  
            --14  �Ӵ�Ǽ�                      ����  6     182    
            --15  ��������Ϸù�ȣ              ����  4     186    
            --16  ����                          ����  64    250    
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)      
                SELECT 'ET'                         -- 1.���ڵ屸��      
                    +  LEFT(@TaxFrDate, 4)          -- 2.�ͼӳ⵵      
                    +  @TermKind                    -- 3.�ݱⱸ��      
                    +  @YearHalfMM                  -- 4.�ݱ⳻ �� ����      
                    +  dbo._FnVATCHARChg(CONVERT(VARCHAR(10), @TaxNo)    ,10,1)    -- 5.������(������)����ڵ�Ϲ�ȣ      
                    +  dbo._FnVATIntChg(COUNT(B.LandSerl)  , 7,0,1)  -- 6.DATA�Ǽ�        
                    + '000001'           -- 7.�Ϸù�ȣ����    
                    + dbo.fnVATCHARChg(CONVERT(VARCHAR(70), A.LandPlace)                   ,70,  1)    --8.�ε��������
                    + dbo.fnVATIntChg( FLOOR(SUM(B.Deposit))                               ,15,0,1)    --09.�Ӵ��೻�� �������հ�
                    + dbo.fnVATIntChg( FLOOR(SUM(B.MonthlyRent))                           ,15,0,1)    --10.�Ӵ��೻�� �������հ�
                    + dbo.fnVATIntChg( FLOOR(SUM(B.DepositInterest + B.MonthlyRentTot))    ,15,0,1)    --11.�Ӵ�� ���Աݾ��հ�
                    + dbo.fnVATIntChg( FLOOR(SUM(B.DepositInterest))                       ,15,0,1)    --12.�Ӵ�� ���Ժ����������հ�
                    + dbo.fnVATIntChg( FLOOR(SUM(B.MonthlyRentTot))                        ,15,0,1)    --13.�Ӵ�� ���Կ������հ�
                    + RIGHT('000000' + CONVERT(VARCHAR(6), COUNT(A.TaxUnit)), 6) --14.�Ӵ�Ǽ�    
                    + '0000'    --15.��������Ϸù�ȣ�߰�    
                    + SPACE(64) --16.����    
                    , 250    
                FROM _TTAXLandLease AS A WITH(NOLOCK)
                                         JOIN _TTAXLandLeaseDtl AS B WITH(NOLOCK)
                                           ON A.CompanySeq      = B.CompanySeq  
                                          AND A.TaxTermSeq      = B.TaxTermSeq  
                                          AND A.TaxUnit         = B.TaxUnit  
                                          AND A.LandPlaceSeq    = B.LandPlaceSeq  
                                         JOIN #TDATaxUnit AS C WITH(NOLOCK)
                                           ON A.CompanySeq      = C.CompanySeq  
                                          AND A.TaxUnit         = C.TaxUnit  
                WHERE A.CompanySeq  = @CompanySeq  
                  AND A.TaxTermSeq  = @TaxTermSeq  
                  AND A.TaxUnit     = @TaxUnit  
                GROUP BY A.TaxUnit, A.LandPlace, C.TaxNo  
           END
           ELSE        -- ���ڽŰ� (�ε����Ӵ�)
           BEGIN
            IF @Env4016 = 4125002     -- ����ڴ�������
				AND EXISTS (SELECT 1 FROM _TTAXLandLeaseDtl WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq)
                AND @TaxFrDate >= @Env4017
				AND @Unit_SMTaxationType = 4128002  -- �ֻ����
			BEGIN 
				
				CREATE TABLE #LandData (  
					Cnt         INT IDENTITY,  
					TaxNo       VARCHAR(15),  
					TaxNoSerl   NVARCHAR(15),  
					OrgTaxNo    VARCHAR(15))  
				CREATE TABLE #LandTmp (  
					Cnt         INT IDENTITY, --- �߿�!!  
					TaxNo       VARCHAR(15),  
					Seq         CHAR(6))  
				CREATE TABLE #LandDataSerl (  
					Cnt         INT,         ---- IDENTITY �ƴ�  
					TaxNo       VARCHAR(15),  
					Seq         CHAR(6))
					
				INSERT INTO #LandData (TaxNo, TaxNoSerl, OrgTaxNo)  
					SELECT DISTINCT @TaxUnit, CASE WHEN B.SMTaxationType = 4128002 THEN '0000' ELSE B.TaxNoSerl END AS TaxNoSerl, A.TaxUnit  
					  FROM _TTAXLandLeaseDtl AS A WITH(NOLOCK)
					                            JOIN #TDATaxUnit AS B WITH(NOLOCK)
												  ON A.CompanySeq      = B.CompanySeq
												 AND A.TaxUnit         = B.TaxUnit  
                                                 AND B.SMTaxationType <> 4128001
					 WHERE A.CompanySeq  = @CompanySeq 
					   AND A.TaxTermSeq  = @TaxTermSeq  
				     --ORDER BY B.TaxNoSerl 
				     
				IF NOT EXISTS (SELECT 1 FROM _TTAXLandLeaseDtl WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq  = @TaxTermSeq AND TaxUnit = @TaxUnit)  
				BEGIN  
				    INSERT INTO #LandData (TaxNo, TaxNoSerl, OrgTaxNo) SELECT @TaxUnit, '0000', @TaxUnit  
				END  
					
				
				DECLARE @TempTaxUnit INT
				
				SELECT @Cnt = 1  
				SELECT @MaxCnt = COUNT(*) FROM #LandData
				  
				WHILE  @Cnt <= @MaxCnt  
				BEGIN  
					SELECT @TempTaxUnit = OrgTaxNo FROM #LandData WHERE Cnt = @Cnt  
  
				    INSERT INTO #LandTmp (TaxNo, Seq)  
					    SELECT DISTINCT A.TaxUnit, A.LandSerl  
					      FROM _TTAXLandLeaseDtl AS A WITH(NOLOCK)
					     WHERE A.CompanySeq	= @CompanySeq
					       AND A.TaxTermSeq = @TaxTermSeq  
					       AND A.TaxUnit	= @TempTaxUnit  
      
				    INSERT INTO #LandDataSerl (Cnt, TaxNo, Seq)  
					    SELECT Cnt, TaxNo, Seq  
					      FROM #LandTmp                                  
                     		
				    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                     SELECT    '17'                 --01.�ڷᱸ��    
                             + 'I103600'            --02.�����ڵ�    
                             + RIGHT('000000' + CONVERT(VARCHAR(6), D.Cnt), 6) -- 03.�Ϸù�ȣ   
                             + dbo.fnVATCHARChg(CONVERT(VARCHAR(70), A.LandPlace)                   ,70,  1)    --04.�ε��������
                             + dbo.fnVATIntChg( FLOOR(SUM(B.Deposit))                               ,15,0,1)    --05.�Ӵ��೻�� �������հ�
                             + dbo.fnVATIntChg( FLOOR(SUM(B.MonthlyRent))                           ,15,0,1)    --06.�Ӵ��೻�� �������հ�
                             + dbo.fnVATIntChg( FLOOR(SUM(B.DepositInterest + B.MonthlyRentTot))    ,15,0,1)    --07.�Ӵ��೻�� ���Աݾ��հ�
                             + dbo.fnVATIntChg( FLOOR(SUM(B.DepositInterest))                       ,15,0,1)    --08.�Ӵ��೻�� ���Ժ����������հ�
                             + dbo.fnVATIntChg( FLOOR(SUM(B.MonthlyRentTot))                        ,15,0,1)    --09.�Ӵ��೻�� ���Կ������հ�
                             + LTRIM(RTRIM(REPLACE(CONVERT(VARCHAR(10), C.TaxNo), '-', ''))) 
                                + SPACE(10 - DATALENGTH(LTRIM(RTRIM(REPLACE(CONVERT(VARCHAR(10), C.TaxNo), '-', ''))))) --10.�Ӵ��λ���ڵ�Ϲ�ȣ    
                             + dbo.fnVATIntChg( COUNT(A.TaxUnit)    , 6,0,1)        --11.�Ӵ�Ǽ�
                             + dbo.fnVATCHARChg(CONVERT(VARCHAR(4), D.TaxNoSerl) ,4, 1)             --13.��������Ϸù�ȣ�߰�    
                             + SPACE(70) --12.����    
                             , 250
                     FROM #LandData AS D JOIN _TTAXLandLease AS A WITH(NOLOCK)
											    ON A.TaxUnit		 = D.OrgTaxNo	
								         JOIN _TTAXLandLeaseDtl AS B WITH(NOLOCK)
                                                ON A.CompanySeq      = B.CompanySeq  
                                               AND A.TaxTermSeq      = B.TaxTermSeq  
                                               AND A.TaxUnit         = B.TaxUnit  
                                               AND A.LandPlaceSeq    = B.LandPlaceSeq  
                                         JOIN #TDATaxUnit AS C WITH(NOLOCK)
                                                ON A.CompanySeq      = C.CompanySeq  
                                               AND D.TaxNo         = C.TaxUnit  
                     WHERE A.CompanySeq  = @CompanySeq 
                       AND D.OrgTaxNo	 = @TempTaxUnit 
                       AND A.TaxTermSeq  = @TaxTermSeq  
                       --AND A.TaxUnit     = @TaxUnit  
                     GROUP BY A.TaxUnit, A.LandPlace, C.TaxNo,D.Cnt ,D.TaxNoSerl

                      INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                      SELECT    '18'                    --01.�ڷᱸ��    
                              + 'I103600'              --02.�����ڵ�    
                              + RIGHT('000000' + CONVERT(VARCHAR(6), D.Cnt), 6) --03.�Ϸù�ȣ����
                              + RIGHT('000000' + CONVERT(VARCHAR(6), C.Cnt), 6) --04.�Ϸù�ȣ     
                              + CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.FloorNum   ))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.FloorNum   )))))   --05.�� 
                              + LTRIM(RTRIM(CONVERT(VARCHAR(30), ISNULL(Land.Dong, '')))) + SPACE(30 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(30), ISNULL(Land.Dong, '')))))) --06.��   
                              + CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.RegNum     ))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.RegNum     )))))   --07.ȣ��    
                              + RIGHT('0000000000' + CONVERT(VARCHAR(10), LTRIM(RTRIM(CONVERT(DECIMAL(19,2),REPLACE((CASE WHEN Land.LandSize = '' THEN '0' ELSE Land.LandSize END),',',''))))), 10) --08.����
                              + LTRIM(RTRIM(CONVERT(VARCHAR(30), Cust.FullName))) + SPACE(30 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(30), Cust.FullName))))) --09.�����λ�ȣ(����)    
                              + CASE WHEN ISNULL(REPLACE(Cust.BizNo, '-', ''), '') = '' THEN    
                                      LTRIM(RTRIM(REPLACE(dbo._FCOMDecrypt(Cust.PersonId, '_TDACust', 'PersonId', @CompanySeq),'-',''))) 
                                      + SPACE(13 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(13),REPLACE(dbo._FCOMDecrypt(Cust.PersonId, '_TDACust', 'PersonId', @CompanySeq),'-',''))))))    
                                 ELSE    
                                      LTRIM(RTRIM(REPLACE(Cust.BizNo, '-', ''))) + SPACE(13 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(13),REPLACE(Cust.BizNo, '-', ''))))))    
                                 END --10.������ ����ڵ�Ϲ�ȣ    
                              + LTRIM(RTRIM(Land.FrDate)) + SPACE(8 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8),Land.FrDate))))) --11.�Ӵ��� ������    
                              + LTRIM(RTRIM(Land.ToDate)) + SPACE(8 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8),Land.ToDate))))) --12.�Ӵ��� �����    
                              + dbo.fnVATIntChg( FLOOR(Land.Deposit)                                ,13,0,1)    --13.�Ӵ��೻�� ������ 
                              + dbo.fnVATIntChg( FLOOR(Land.MonthlyRent)                            ,13,0,1)    --14.�Ӵ��೻�� ������
                              + dbo.fnVATIntChg( FLOOR(Land.DepositInterest + Land.MonthlyRentTot)  ,13,0,1)    --15.�Ӵ�� ���Աݾװ�(��ǥ)
                              + dbo.fnVATIntChg( FLOOR(Land.DepositInterest)                        ,13,0,1)    --16.�Ӵ�� ����������
                              + dbo.fnVATIntChg( FLOOR(Land.MonthlyRentTot)                         ,13,0,1)    --17.�Ӵ�� ���Աݾ׿�����
                              + CASE WHEN LAND.TaxUnit = @TaxUnit THEN '0000'  
                                     ELSE dbo.fnVATCHARChg(CONVERT(VARCHAR(4), D.TaxNoSerl) ,4, 1) END  --18.��������Ϸù�ȣ�߰�    
                              + LTRIM(RTRIM(CONVERT(VARCHAR(8), ISNULL(Land.ModDate, '')))) + SPACE(8 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8), ISNULL(Land.ModDate, '')))))) --19.������
                              + SPACE(33)    
                              , 250     
                        FROM _TTAXLandLeaseDtl AS Land WITH(NOLOCK)
                                                JOIN _TTAXLandLease AS Dtl WITH(NOLOCK) 
                                                  ON Land.CompanySeq = Dtl.CompanySeq  
                                                 AND Land.TaxTermSeq = Dtl.TaxTermSeq  
                                                 AND Land.TaxUnit    = Dtl.TaxUnit   
                                                 AND Land.LandPlaceSeq = Dtl.LandPlaceSeq  
                                     LEFT OUTER JOIN _TDACust AS Cust WITH(NOLOCK)
                                                  ON Land.CompanySeq = Cust.CompanySeq  
                                                 AND Land.CustSeq    = Cust.CustSeq 
                                                JOIN #LandData AS D ON Land.TaxUnit = D.OrgTaxNo 
                                                JOIN #LandDataSerl AS C  
                                                  ON LAND.TaxUnit     = C.TaxNo  
                                                 AND LAND.LandSerl    = C.Seq
                       WHERE Land.CompanySeq  = @CompanySeq  
                         AND Land.TaxTermSeq  = @TaxTermSeq 
                         AND D.OrgTaxNo = @TempTaxUnit 
                       --AND Land.TaxUnit     = @TaxUnit  	
                     ORDER BY D.Cnt,C.Cnt  
                 
                    SELECT @Cnt = @Cnt +1 
                END -- WHILE END
             
			END 
			ELSE IF EXISTS (SELECT * FROM _TTAXLandLeaseDtl WITH(NOLOCK) WHERE CompanySeq  = @CompanySeq and TaxTermSeq = @TaxTermSeq  AND TaxUnit = @TaxUnit ) -- ����ڴ��������� �ƴ� ���
			BEGIN
                INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                SELECT    '17'              --01.�ڷᱸ��    
                        + 'I103600'         --02.�����ڵ�    
                        + '000001'          --03.�Ϸù�ȣ    
                        + dbo.fnVATCHARChg(CONVERT(VARCHAR(70), A.LandPlace)                   ,70,  1)    --04.�ε��������
                        + dbo.fnVATIntChg( FLOOR(SUM(B.Deposit))                               ,15,0,1)    --05.�Ӵ��೻�� �������հ�
                        + dbo.fnVATIntChg( FLOOR(SUM(B.MonthlyRent))                           ,15,0,1)    --05.�Ӵ��೻�� �������հ�
                        + dbo.fnVATIntChg( FLOOR(SUM(B.DepositInterest + B.MonthlyRentTot))    ,15,0,1)    --05.�Ӵ��೻�� ���Աݾ��հ�
                        + dbo.fnVATIntChg( FLOOR(SUM(B.DepositInterest))                       ,15,0,1)    --05.�Ӵ��೻�� ���Ժ����������հ�
                        + dbo.fnVATIntChg( FLOOR(SUM(B.MonthlyRentTot))                        ,15,0,1)    --05.�Ӵ��೻�� ���Կ������հ�
                        + LTRIM(RTRIM(REPLACE(CONVERT(VARCHAR(10), C.TaxNo), '-', ''))) + SPACE(10 - DATALENGTH(LTRIM(RTRIM(REPLACE(CONVERT(VARCHAR(10), C.TaxNo), '-', ''))))) --10.�Ӵ��λ���ڵ�Ϲ�ȣ    
                        + RIGHT('000000' + CONVERT(VARCHAR(6), COUNT(A.TaxUnit)), 6) --11.�Ӵ�Ǽ�    
                        + '0000'    --13.��������Ϸù�ȣ�߰�    
                        + SPACE(70) --12.����    
                        , 250    
                FROM _TTAXLandLease AS A WITH(NOLOCK)
                                         JOIN _TTAXLandLeaseDtl AS B WITH(NOLOCK)
                  ON A.CompanySeq      = B.CompanySeq  
                                          AND A.TaxTermSeq      = B.TaxTermSeq  
                                          AND A.TaxUnit         = B.TaxUnit  
                                          AND A.LandPlaceSeq    = B.LandPlaceSeq  
                                         JOIN #TDATaxUnit AS C WITH(NOLOCK)
                                           ON A.CompanySeq      = C.CompanySeq  
                                          AND A.TaxUnit         = C.TaxUnit  
                WHERE A.CompanySeq  = @CompanySeq  
                  AND A.TaxTermSeq  = @TaxTermSeq  
                  AND A.TaxUnit     = @TaxUnit  
                GROUP BY A.TaxUnit, A.LandPlace, C.TaxNo  
  

                INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                SELECT    '18'                    --01.�ڷᱸ��    
                        + 'I103600'              --02.�����ڵ�    
                        + '000001'           --03.�Ϸù�ȣ����    
                        + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY Land.LandSerl)), 6) --04.�Ϸù�ȣ    
                        + CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.FloorNum   ))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.FloorNum   )))))   --05.��    
                        + LTRIM(RTRIM(CONVERT(VARCHAR(30), ISNULL(Land.Dong, '')))) + SPACE(30 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(30), ISNULL(Land.Dong, '')))))) --06.��                                
                        + CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.RegNum      ))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.RegNum      )))))   --07.ȣ��    
                        + RIGHT('0000000000' + CONVERT(VARCHAR(10), LTRIM(RTRIM(CONVERT(DECIMAL(19,2),REPLACE((CASE WHEN Land.LandSize = '' THEN '0' ELSE Land.LandSize END),',',''))))), 10) --08.����
                        + LTRIM(RTRIM(CONVERT(VARCHAR(30), Cust.FullName))) + SPACE(30 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(30), Cust.FullName))))) --08.�����λ�ȣ(����)    
                        + CASE WHEN ISNULL(REPLACE(Cust.BizNo, '-', ''), '') = '' THEN    
                                LTRIM(RTRIM(REPLACE(dbo._FCOMDecrypt(Cust.PersonId, '_TDACust', 'PersonId', @CompanySeq),'-',''))) 
                                + SPACE(13 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(13),REPLACE(dbo._FCOMDecrypt(Cust.PersonId, '_TDACust', 'PersonId', @CompanySeq),'-',''))))))    
                           ELSE    
                                LTRIM(RTRIM(REPLACE(Cust.BizNo, '-', ''))) + SPACE(13 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(13),REPLACE(Cust.BizNo, '-', ''))))))    
                           END --09.������ ����ڵ�Ϲ�ȣ    
                        + LTRIM(RTRIM(Land.FrDate)) + SPACE(8 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8),Land.FrDate))))) --10.�Ӵ��� ������    
                        + LTRIM(RTRIM(Land.ToDate)) + SPACE(8 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8),Land.ToDate))))) --11.�Ӵ��� �����    
                        + dbo.fnVATIntChg( FLOOR(Land.Deposit)                                ,13,0,1)    --13.�Ӵ��೻�� ������ 
                        + dbo.fnVATIntChg( FLOOR(Land.MonthlyRent)                            ,13,0,1)    --14.�Ӵ��೻�� ������
                        + dbo.fnVATIntChg( FLOOR(Land.DepositInterest + Land.MonthlyRentTot)  ,13,0,1)    --15.�Ӵ�� ���Աݾװ�(��ǥ)
                        + dbo.fnVATIntChg( FLOOR(Land.DepositInterest)                        ,13,0,1)    --16.�Ӵ�� ����������
                        + dbo.fnVATIntChg( FLOOR(Land.MonthlyRentTot)                         ,13,0,1)    --17.�Ӵ�� ���Աݾ׿�����                            
                        + '0000'    
                        + LTRIM(RTRIM(CONVERT(VARCHAR(8), ISNULL(Land.ModDate, '')))) + SPACE(8 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8), ISNULL(Land.ModDate, '')))))) --20.������    
                        + SPACE(33)    
                        , 250    
                  FROM _TTAXLandLeaseDtl AS Land WITH(NOLOCK)
                                           JOIN _TTAXLandLease AS Dtl WITH(NOLOCK)
                                             ON Land.CompanySeq = Dtl.CompanySeq  
                                            AND Land.TaxTermSeq = Dtl.TaxTermSeq  
                                            AND Land.TaxUnit    = Dtl.TaxUnit   
                                            AND Land.LandPlaceSeq = Dtl.LandPlaceSeq  
                                LEFT OUTER JOIN _TDACust AS Cust WITH(NOLOCK)
                                             ON Land.CompanySeq = Cust.CompanySeq  
                                            AND Land.CustSeq    = Cust.CustSeq  
                 WHERE Land.CompanySeq  = @CompanySeq  
                   AND Land.TaxTermSeq  = @TaxTermSeq  
                   AND Land.TaxUnit     = @TaxUnit
                   
            END  -- ����ڴ��������� �ƴ� ��� END
        END -- ���ڽŰ� END
    END -- �ε����Ӵ�������� END
END  
  
/***************************************************************************************************************************    
��ռ��װ���(����)�Ű�
01. �ڷᱸ��(1) : 17    
02. �����ڵ�(7) : I102800 / V112
03. ��պ�������(2) : ��� '01', ���� '02'    
04. �Ϸù�ȣ(6)    
05. ��պ�����(8)    
06. ��պ����ݾ�(13)    
07. ��պ�������(13)    
08. ���θ�(��ȣ)(30)    
09. ����(��ǥ��)(30)    
10. �ŷ�ó������ID(13) : �ŷ�ó����ڵ�Ϲ�ȣ    
11. ��պ�������(30)    
13. ����(46)    
****************************************************************************************************************************/    
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT * FROM _TTAXBadDebt WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
    BEGIN  
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT '17'            --01. �ڷᱸ��    
                   + 'I102800'      --02. �����ڵ�    
                   + CASE WHEN A.SMDebtKind = 4044001 THEN '01' ELSE '02' END                       --03. ��պ�������    
                   + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY A.Seq)), 6)   --04. �Ϸù�ȣ
                   + CONVERT(VARCHAR(8), A.CfmDate)                                                 --05. ��պ�����    
                   + dbo.fnVATIntChg( FLOOR(A.SupplyAmt)  ,13,0,1)                                  --06. ��պ����ݾ�
                   + dbo.fnVATIntChg( FLOOR(A.VATAmt)     ,13,0,1)                                  --07. ��պ�������
                   + LTRIM(RTRIM(CONVERT(VARCHAR(30), Cust.FullName))) + SPACE(30 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(30), Cust.FullName)))))  --08. �ŷ��ڻ�ȣ    
                   + CONVERT(VARCHAR(30), LTRIM(RTRIM(Cust.Owner))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(Cust.Owner      )))))  --09. ����(��ǥ��)    
                   + CONVERT(VARCHAR(13), LTRIM(RTRIM( ( CASE ISNULL(REPLACE(Cust.BizNo,'-',''),'') WHEN '' 
                                                              THEN ISNULL(REPLACE(dbo._FCOMDecrypt(Cust.PersonId, '_TDACust', 'PersonId', @CompanySeq),'-',''),'') 
                                                              ELSE ISNULL(REPLACE(Cust.BizNo,'-',''),'') END ) )))    
                     + SPACE(13 - DATALENGTH(CONVERT(VARCHAR(13), LTRIM(RTRIM(( CASE ISNULL(REPLACE(Cust.BizNo,'-',''),'') WHEN '' 
                                                                                     THEN ISNULL(dbo._FCOMDecrypt(Cust.PersonId, '_TDACust', 'PersonId', @CompanySeq),'') 
                                                                                     ELSE ISNULL(REPLACE(Cust.BizNo,'-',''),'') END ) )))))   --10. �ŷ�ó������ID     
                   + CONVERT(VARCHAR(30), LTRIM(RTRIM(A.Remark  ))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(A.Remark        )))))  --11. ��պ�������    
                   + SPACE(46)    
                   , 200    
             FROM _TTAXBadDebt AS A WITH(NOLOCK)
                                    JOIN _TDACust AS Cust WITH(NOLOCK)
                                      ON A.CompanySeq   = Cust.CompanySeq  
                                     AND A.CustSeq      = Cust.CustSeq  
             WHERE A.CompanySeq     = @CompanySeq  
               AND A.TaxTermSeq     = @TaxTermSeq  
               AND A.TaxUnit        = @TaxUnit  
    END    
END  
  
/***************************************************************************************************************************   
����庰�ΰ���ġ������ǥ�� �� ���μ���(ȯ�޼���)�Ű�
****************************************************************************************************************************/    
IF @WorkingTag IN ('','M')  
BEGIN  
  
    -- ����ڴ��������� �ƴ� ��츸 ���  
    IF NOT (@Env4016 <> 4125001 AND @TaxFrDate >= @Env4017) 
    BEGIN  
        --==================================================================================================================================================  
        -- ����庰�ΰ���ġ������ǥ�ع׳��μ���(ȯ�޼���)�Ű�� ���� �ۼ�    
        --==================================================================================================================================================  
        IF @WorkingTag = 'M' AND @Unit_SMTaxationType = 4128002 -- �ֻ����
        BEGIN  
            -- ������ ��������(HEAD RECORD)    
            /*    
            ��ȣ ��  �� ���� ���� �������� ���    
            1 ���ڵ屸�� ���� 2 2 MH    
            2 �ͼӳ⵵ ���� 4 6 YYYY��    
            3 �ݱⱸ�� ���� 1 7 1: 1��, 2: 2��    
            4 �ݱ⳻ �� ���� ���� 1 8 1/2/3/4/5/6    
            5 ������(������)����ڵ�Ϲ�ȣ ���� 10 18 ��    
            6 �Ѱ����ν��ι�ȣ ���� 7 25      
            7 ��ȣ(���θ�) ���� 60 85 ��    
            8 ����(��ǥ��) ���� 30 115 ��    
            9 �ֹ�(����)��Ϲ�ȣ ���� 13 128 ��    
            10 �������� ���� 8 136 ��    
            11 ������(������)��ȭ��ȣ ���� 12 148      
            12 ���� ���� 152 300 SPACE    
            */    
  
            INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                SELECT 'MH'                             -- ���ڵ屸��  
                        + LEFT(@TaxFrDate, 4)           -- �ͼӳ⵵  
                        + @TermKind                     -- �ݱⱸ��  
                        + @YearHalfMM                   -- �ݱ⳻ �� ����  
                        + CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '') + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '') )))) -- ������(������)����ڵ�Ϲ�ȣ  
                        + CONVERT(VARCHAR(07), TaxSumPaymentNo         + SPACE( 7 - DATALENGTH(CONVERT(VARCHAR( 7), TaxSumPaymentNo         )))) -- �Ѱ����ν��ι�ȣ  
                        + CONVERT(VARCHAR(60), TaxName                 + SPACE(60 - DATALENGTH(CONVERT(VARCHAR(60), TaxName                 )))) -- ��ȣ(���θ�)  
                        + CONVERT(VARCHAR(30), Owner                   + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), Owner                   )))) -- ����(��ǥ��)      
                        + CONVERT(VARCHAR(13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','') 
                            + SPACE(13 - DATALENGTH(CONVERT(VARCHAR(13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','') )))) -- �ֹ�(����)��Ϲ�ȣ  
                        + CONVERT(VARCHAR( 8), @CurrDate               + SPACE( 8 - DATALENGTH(CONVERT(VARCHAR( 8), @CurrDate               )))) -- ��������  
                        + CONVERT(VARCHAR(12), TelNo                   + SPACE(12 - DATALENGTH(CONVERT(VARCHAR(12), TelNo                   )))) -- ������(������)��ȭ��ȣ  
                        + SPACE(152)    -- ����  
                        , 300  
                   FROM #TDATaxUnit WITH(NOLOCK)
                  WHERE CompanySeq  = @CompanySeq  
                    AND TaxUnit     = @TaxUnit  
  
            -- ����庰�ΰ���ġ������ǥ�ع׳��μ���(ȯ�޼���)�Ű��(DATA RECORD)    
            /*    
            ��ȣ ��  �� ���� ���� �������� ���    
            1 ���ڵ屸�� ���� 2 2 MD    
            2 �ͼӳ⵵ ���� 4 6 YYYY��    
            3 �ݱⱸ�� ���� 1 7 1: 1��, 2: 2��    
            4 �ݱ⳻ �� ���� ���� 1 8 1/2/3/4/5/6    
            5 ������(������)����ڵ�Ϲ�ȣ ���� 10 18 ��    
            6 ����ڵ�Ϲ�ȣ ���� 10 28      
            7 ���������� ���� 70 98 ��    
            8 ��������ݾ� ���� 15 113 ��    
            9 ����������� ���� 13 126 ��    
            10 ���⿵���ݾ� ���� 15 141      
            11 ���⿵������ ���� 13 154 ��    
            12 ���԰����ݾ� ���� 15 169 ��    
            13 ���԰������� ���� 13 182 0���� ����    
            14 ���������ݾ� ���� 15 197      
            15 ������������ ���� 13 210      
            16 ���꼼 ���� 13 223      
            17 �������� ���� 15 238      
            18 ����(ȯ��)���� ���� 15 253      
            19 ���ΰŷ�(�ǸŸ���)����� ���� 15 268      
            20 ���ΰŷ�(�ǸŸ���)���Ծ� ���� 15 283      
            21 ���� ���� 17 300      
            */    
  
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)    
                SELECT 'MD'                         -- ���ڵ屸��    
                        +  LEFT(@TaxFrDate,4)           -- �ͼӳ⵵    
                        +  @TermKind                    -- �ݱⱸ��    
                        +  @YearHalfMM                  -- �ݱ⳻ �� ����    
                        + dbo._FnVATCHARChg(@TaxNo,10,1) --05.������(������)����ڵ�Ϲ�ȣ ���� 10 18 ��  
                        + dbo._FnVATCHARChg(CONVERT(VARCHAR(10),REPLACE(Tax.TaxNo,'-','')),10,1) --06.����ڵ�Ϲ�ȣ  
                        + dbo._FnVATCHARChg(CONVERT(VARCHAR(70),Tax.VATRptAddr),70,1)            --07.����������  
                        + dbo._FnVATIntChg(Rpt.SaleSupplyAmt  ,  15, 0, 1)    --08.��������ݾ�  
                        + dbo._FnVATIntChg(Rpt.SaleVATAmt     ,  13, 0, 1)    --09.�����������  
                        + dbo._FnVATIntChg(Rpt.SaleZeroVATAmt ,  15, 0, 1)    --10.���⿵���ݾ�  
                        + '0000000000000'                                     --11.���⿵������  
                        + dbo._FnVATIntChg(Rpt.BuySupplyAmt   ,  15, 0, 1)    --12.���԰����ݾ�  
                        + dbo._FnVATIntChg(Rpt.BuyVATAmt      ,  13, 0, 1)    --13.���԰�������  
                        + dbo._FnVATIntChg(Rpt.BuyEtcAmt      ,  15, 0, 1)    --14.���������ݾ�  
                        + dbo._FnVATIntChg(Rpt.BuyEtcVATAmt   ,  13, 0, 1)    --15.������������  
                        + dbo._FnVATIntChg(Rpt.AddVATAmt      ,  13, 0, 1)    --16.���꼼  
                        + dbo._FnVATIntChg(Rpt.DeducVATAmt    ,  15, 0, 1)    --17.��������  
                        + dbo._FnVATIntChg(Rpt.PayAmt         ,  15, 0, 1)    --18.����(ȯ��)����  
                        + dbo._FnVATIntChg(Rpt.OutAmt         ,  15, 0, 1)    --19.���ΰŷ�(�ǸŸ���)�����  
                        + dbo._FnVATIntChg(Rpt.InAmt          ,  15, 0, 1)    --20.���ΰŷ�(�ǸŸ���)���Ծ�  
                        + SPACE(17)  
                        , 300  
                  FROM _TTAXBizStdSum AS Rpt WITH(NOLOCK)
                    LEFT OUTER JOIN #TDATaxUnit AS Tax WITH(NOLOCK) ON Rpt.CompanySeq = Tax.CompanySeq AND Rpt.RptTaxUnit = Tax.TaxUnit  
                 WHERE Rpt.CompanySeq = @CompanySeq   
                   AND Rpt.TaxTermSeq = @TaxTermSeq   
                   AND Rpt.TaxUnit    = @TaxUnit  
  
            -- ����庰�ΰ���ġ������ǥ�ع׳��μ���(ȯ�޼���)�Ű�� �հ�(TAIL RECORD)    
            /*    
            ��ȣ ��  �� ���� ���� �������� ���    
            1 ���ڵ屸�� ���� 2 2 MT    
            2 �ͼӳ⵵ ���� 4 6 YYYY����    
            3 �ݱⱸ�� ���� 1 7 1: 1��, 2: 2��    
            4 �ݱ⳻ �� ���� ���� 1 8 1/2/3/4/5/6    
            5 ������(������)����ڵ�Ϲ�ȣ ���� 10 18 ��    
            6 DATA �Ǽ� ���� 7 25      
            7 ��������ݾ��հ� ���� 15 40      
            8 ������������հ� ���� 15 55      
            9 ���⿵���ݾ��հ� ���� 15 70      
            10 ���⿵�������հ� ���� 15 85 0���� ����    
            11 ���԰����ݾ��հ� ���� 15 100      
            12 ���԰��������հ� ���� 15 115      
            13 ���������ݾ��հ� ���� 15 130      
            14 �������������հ� ���� 15 145      
            15 ���꼼�հ� ���� 15 160      
            16 ���������հ� ���� 15 175      
            17 ����(ȯ��)�����հ� ���� 15 190      
            18 ���ΰŷ�(�ǸŸ���)������հ� ���� 15 205      
            19 ���ΰŷ�(�ǸŸ���)���Ծ��հ� ���� 15 220      
            20 ���� ���� 80 300      
            */    
  INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)    
                SELECT 'MT'                         -- 1 ���ڵ屸�� ���� 2 2 MT    
                        +  LEFT(@TaxFrDate,4)           -- 2 �ͼӳ⵵ ���� 4 6 YYYY����      
                        +  @TermKind                    -- 3 �ݱⱸ�� ���� 1 7 1: 1��, 2: 2��      
                        +  @YearHalfMM                  -- 4 �ݱ⳻ �� ���� ���� 1 8 1/2/3/4/5/6    
                        + dbo._FnVATCHARChg(CONVERT(VARCHAR(10),REPLACE(@TaxNo,'-','')),10,1) --5 ������(������)����ڵ�Ϲ�ȣ ���� 10 18    
                        + dbo._FnVATIntChg(COUNT(*), 7, 0, 1)                                 --6 DATA �Ǽ� ���� 7 25      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.SaleSupplyAmt  ), 0),  15, 0, 1)    --7 ��������ݾ��հ� ���� 15 40      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.SaleVATAmt     ), 0),  15, 0, 1)    --8 ������������հ� ���� 15 55      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.SaleZeroVATAmt ), 0),  15, 0, 1)    --9 ���⿵���ݾ��հ� ���� 15 70      
                        + '000000000000000'                                                   --10 ���⿵�������հ� ���� 15 85 0���� ����    
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.BuySupplyAmt   ), 0),  15, 0, 1)    --11 ���԰����ݾ��հ� ���� 15 100      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.BuyVATAmt      ), 0),  15, 0, 1)    --12 ���԰��������հ� ���� 15 115      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.BuyEtcAmt      ), 0),  15, 0, 1)    --13 ���������ݾ��հ� ���� 15 130      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.BuyEtcVATAmt   ), 0),  15, 0, 1)    --14 �������������հ� ���� 15 145      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.AddVATAmt      ), 0),  15, 0, 1)    --15 ���꼼�հ� ���� 15 160      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.DeducVATAmt    ), 0),  15, 0, 1)    --16 ���������հ� ���� 15 175      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.PayAmt         ), 0),  15, 0, 1)    --17 ����(ȯ��)�����հ� ���� 15 190      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.OutAmt         ), 0),  15, 0, 1)    --18 ���ΰŷ�(�ǸŸ���)������հ� ���� 15 205      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.InAmt          ), 0),  15, 0, 1)    --19 ���ΰŷ�(�ǸŸ���)���Ծ��հ� ���� 15 220      
                        + SPACE(80)                                                           --20 ���� ���� 80 300      
                        , 300  
                  FROM _TTAXBizStdSum AS Rpt WITH(NOLOCK)
                    LEFT OUTER JOIN #TDATaxUnit AS Tax WITH(NOLOCK) ON Rpt.CompanySeq = Tax.CompanySeq AND Rpt.RptTaxUnit = Tax.TaxUnit  
                 WHERE Rpt.CompanySeq = @CompanySeq   
                   AND Rpt.TaxTermSeq = @TaxTermSeq   
                   AND Rpt.TaxUnit    = @TaxUnit  
        END  
        ELSE        -- ���ڽŰ�
        BEGIN   
            /***************************************************************************************************************************  
            ����庰 �ΰ���ġ�� ����ǥ�� �� ���μ���(ȯ�޼���)�Ű����  
  
            01. �ڷᱸ��(2) : 17  
            02. �����ڵ�(7) : I104500 / V115
            03. ��������ݾ��հ�(15)  
            04. ���Ⱑ�������հ�(15)  
            05. ���⿵���ݾ��հ�(15)  
            06. ���⿵�������հ�(15)  
            07. ���԰����ݾ��հ�(15)  
            08. ���԰��������հ�(15)  
            09. ���������ݾ��հ�(15)  
            10. �������������հ�(15)  
            11. ���꼼�հ�(15)  
            12. ���������հ�(15)  
            13. ����(ȯ��)�����հ�(15)  
            14. ���ΰŷ�(�ǸŸ���)������հ�(15)  
            15. ���ΰŷ�(�ǸŸ���)���Ծ��հ�(15)  
            16. ����(96)  
            ****************************************************************************************************************************/  
            IF EXISTS (SELECT * FROM _TTAXBizStdSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
            BEGIN  
                INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                SELECT    '17'         --01.�ڷᱸ��  
                        + 'I104500'       --02.�����ڵ�  
                        + dbo._FnVATIntChg(SUM(Rpt.SaleSupplyAmt)  ,  15, 0, 1)    --03.��������ݾ��հ�  
                        + dbo._FnVATIntChg(SUM(Rpt.SaleVATAmt)     ,  15, 0, 1)    --04.������������հ�  
                        + dbo._FnVATIntChg(SUM(Rpt.SaleZeroVATAmt) ,  15, 0, 1)    --05.���⿵���ݾ��հ�  
                        + '000000000000000'                                        --06.���⿵�������հ�  
                        + dbo._FnVATIntChg(SUM(Rpt.BuySupplyAmt)   ,  15, 0, 1)    --07.���԰����ݾ��հ�  
                        + dbo._FnVATIntChg(SUM(Rpt.BuyVATAmt)      ,  15, 0, 1)    --08.���԰��������հ�  
                        + dbo._FnVATIntChg(SUM(Rpt.BuyEtcAmt)      ,  15, 0, 1)    --09.���������ݾ��հ�  
                        + dbo._FnVATIntChg(SUM(Rpt.BuyEtcVATAmt)   ,  15, 0, 1)    --10.�������������հ�  
                        + dbo._FnVATIntChg(SUM(Rpt.AddVATAmt)      ,  15, 0, 1)    --11.���꼼�հ�  
                        + dbo._FnVATIntChg(SUM(Rpt.DeducVATAmt)    ,  15, 0, 1)    --12.���������հ�  
                        + dbo._FnVATIntChg(SUM(Rpt.PayAmt)         ,  15, 0, 1)    --13.����(ȯ��)�����հ�  
                        + dbo._FnVATIntChg(SUM(Rpt.OutAmt)         ,  15, 0, 1)    --14.���ΰŷ�(�ǸŸ���)������հ�  
                        + dbo._FnVATIntChg(SUM(Rpt.InAmt)          ,  15, 0, 1)    --15.���ΰŷ�(�ǸŸ���)���Ծ��հ�  
                        + SPACE(96)  
                        , 300  
                  FROM _TTAXBizStdSum AS Rpt WITH(NOLOCK)
                 WHERE Rpt.CompanySeq = @CompanySeq   
                   AND Rpt.TaxTermSeq = @TaxTermSeq   
                   AND Rpt.TaxUnit    = @TaxUnit  
  
  
                /***************************************************************************************************************************  
                ����庰 �ΰ���ġ�� ����ǥ�� �� ���μ���(ȯ�޼���)�Ű���� ���γ���  
  
                01. �ڷᱸ��(2) : 18  
                02. �����ڵ�(7) : I104500 / V115
                03. ����ڵ�Ϲ�ȣ(10)  
                04. ����������(70)  
                05. ��������ݾ�(15)  
                06. �����������(13)  
                07. ���⿵���ݾ�(15)  
                08. ���⿵������(13)  
                09. ���԰����ݾ�(15)  
                10. ���԰�������(13)  
                11. ���������ݾ�(15)  
                12. ������������(13)  
                13. ���꼼(13)  
                14. ��������(15)  
                15. ����(ȯ��)����(15)  
                16. ���ΰŷ�(�ǸŸ���)�����(15)  
                17. ���ΰŷ�(�ǸŸ���)���Ծ�(15)  
                18. ����(26)  
                ****************************************************************************************************************************/  
                INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                SELECT    '18'                --01.�ڷᱸ��  
                        + 'I104500'          --02.�����ڵ�  
                        + dbo._FnVATCHARChg(CONVERT(VARCHAR(10),REPLACE(Tax.TaxNo,'-','')),10,1) --03.����ڵ�Ϲ�ȣ  
                        + dbo._FnVATCHARChg(CONVERT(VARCHAR(70),Tax.VATRptAddr),70,1)            --04.����������  
                        + dbo._FnVATIntChg(Rpt.SaleSupplyAmt  ,  15, 0, 1)    --03.��������ݾ�  
                        + dbo._FnVATIntChg(Rpt.SaleVATAmt     ,  13, 0, 1)    --04.�����������  
                        + dbo._FnVATIntChg(Rpt.SaleZeroVATAmt ,  15, 0, 1)    --05.���⿵���ݾ�  
                        + '0000000000000'                                     --06.���⿵������  
                        + dbo._FnVATIntChg(Rpt.BuySupplyAmt   ,  15, 0, 1)    --07.���԰����ݾ�  
                        + dbo._FnVATIntChg(Rpt.BuyVATAmt      ,  13, 0, 1)    --08.���԰�������  
                        + dbo._FnVATIntChg(Rpt.BuyEtcAmt      ,  15, 0, 1)    --09.���������ݾ�  
                        + dbo._FnVATIntChg(Rpt.BuyEtcVATAmt   ,  13, 0, 1)    --10.������������  
                        + dbo._FnVATIntChg(Rpt.AddVATAmt      ,  13, 0, 1)    --11.���꼼  
                        + dbo._FnVATIntChg(Rpt.DeducVATAmt    ,  15, 0, 1)    --12.��������  
                        + dbo._FnVATIntChg(Rpt.PayAmt         ,  15, 0, 1)    --13.����(ȯ��)����  
                        + dbo._FnVATIntChg(Rpt.OutAmt         ,  15, 0, 1)    --14.���ΰŷ�(�ǸŸ���)�����  
                        + dbo._FnVATIntChg(Rpt.InAmt          ,  15, 0, 1)    --15.���ΰŷ�(�ǸŸ���)���Ծ�  
                        + SPACE(26)  
                        , 300  
                  FROM _TTAXBizStdSum AS Rpt WITH(NOLOCK)
                    LEFT OUTER JOIN #TDATaxUnit AS Tax WITH(NOLOCK) ON Rpt.CompanySeq = Tax.CompanySeq AND Rpt.RptTaxUnit = Tax.TaxUnit  
                 WHERE Rpt.CompanySeq = @CompanySeq   
                   AND Rpt.TaxTermSeq = @TaxTermSeq   
                   AND Rpt.TaxUnit    = @TaxUnit  
  
            END  
        END  -- ���ڽŰ� END
    END  
END  

/***************************************************************************************************************************    
�ǹ��� �������ڻ� ������    
    
01. �ڷᱸ��(2) : 17    
02. �����ڵ�(7) : I103800 / V149
03. �Ǽ��հ�_�����ڻ�(11)    
04. ���ް����հ�_�����ڻ�(13)    
05. �����հ�_�����ڻ�(13)    
06. �Ǽ�_�ǹ�, ���๰(11)    
07. ���ް���_�ǹ�, ���๰(13)    
08. ����_�ǹ�, ���๰(13)    
09. �Ǽ�_�����ġ(11)    
10. ���ް���_�����ġ(13)    
11. ����_�����ġ(13)    
12. �Ǽ�_������ݱ�(11)    
13. ���ް���_������ݱ�(13)    
14. ����_������ݱ�(13)    
15. �Ǽ�_��Ÿ�������ڻ�(11)    
16. ���ް���_��Ÿ�������ڻ�(13)    
17. ����_��Ÿ�������ڻ�(13)    
18. ����(6)    
****************************************************************************************************************************/    
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT 1 FROM _TTAXAsstPur WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND (Cnt <> 0 OR SupplyAmt <> 0 OR VATAmt <> 0))  
    BEGIN  
         INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
         SELECT '17'      --01 �ڷᱸ��    
               + 'I103800'     --02. �����ڵ�    
               + RIGHT('00000000000' + CONVERT(VARCHAR(11), SUM(Cnt)), 11)            --03. �Ǽ��հ�_�����ڻ�    
               + CASE WHEN SUM(SupplyAmt) >= 0 THEN    
                       RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(SupplyAmt))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(SupplyAmt)))), 13), 1, 1, '-')    
                  END --04. ���ް����հ�_�����ڻ�    
               + CASE WHEN SUM(VATAmt) >= 0 THEN    
                       RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(VATAmt))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(VATAmt)))), 13), 1, 1, '-')    
                  END --05. �����հ�_�����ڻ�    
               + RIGHT('00000000000' + CONVERT(VARCHAR(11), SUM(CASE WHEN SMAsstKind = 4110001 THEN Cnt ELSE 0 END)), 11)    --06. �Ǽ�_�ǹ�, ���๰    
               + CASE WHEN SUM(CASE WHEN SMAsstKind = 4110001 THEN SupplyAmt ELSE 0 END) >= 0 THEN    
                       RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(CASE WHEN SMAsstKind = 4110001 THEN SupplyAmt ELSE 0 END))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(CASE WHEN SMAsstKind = 4110001 THEN SupplyAmt ELSE 0 END)))), 13), 1, 1, '-')    
                  END --07. ���ް���_�ǹ�, ���๰    
               + CASE WHEN SUM(CASE WHEN SMAsstKind = 4110001 THEN VATAmt ELSE 0 END) >= 0 THEN    
                       RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(CASE WHEN SMAsstKind = 4110001 THEN VATAmt ELSE 0 END))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(CASE WHEN SMAsstKind = 4110001 THEN VATAmt ELSE 0 END)))), 13), 1, 1, '-')    
                  END --08. ����_�ǹ�, ���๰    
               + RIGHT('00000000000' + CONVERT(VARCHAR(11), SUM(CASE WHEN SMAsstKind = 4110002 THEN Cnt ELSE 0 END)), 11)    --09. �Ǽ�_�����ġ    
          + CASE WHEN SUM(CASE WHEN SMAsstKind = 4110002 THEN SupplyAmt ELSE 0 END) >= 0 THEN    
                       RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(CASE WHEN SMAsstKind = 4110002 THEN SupplyAmt ELSE 0 END))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(CASE WHEN SMAsstKind = 4110002 THEN SupplyAmt ELSE 0 END)))), 13), 1, 1, '-')    
                  END --10. ���ް���_�����ġ    
               + CASE WHEN SUM(CASE WHEN SMAsstKind = 4110002 THEN VATAmt ELSE 0 END) >= 0 THEN    
                       RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(CASE WHEN SMAsstKind = 4110002 THEN VATAmt ELSE 0 END))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(CASE WHEN SMAsstKind = 4110002 THEN VATAmt ELSE 0 END)))), 13), 1, 1, '-')    
                  END --11. ����_�����ġ    
               + RIGHT('00000000000' + CONVERT(VARCHAR(11), SUM(CASE WHEN SMAsstKind = 4110003 THEN Cnt ELSE 0 END)), 11)    --12. �Ǽ�_������ݱ�    
               + CASE WHEN SUM(CASE WHEN SMAsstKind = 4110003 THEN SupplyAmt ELSE 0 END) >= 0 THEN    
                       RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(CASE WHEN SMAsstKind = 4110003 THEN SupplyAmt ELSE 0 END))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(CASE WHEN SMAsstKind = 4110003 THEN SupplyAmt ELSE 0 END)))), 13), 1, 1, '-')    
                  END --13. ���ް���_������ݱ�    
               + CASE WHEN SUM(CASE WHEN SMAsstKind = 4110003 THEN VATAmt ELSE 0 END) >= 0 THEN    
                       RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(CASE WHEN SMAsstKind = 4110003 THEN VATAmt ELSE 0 END))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(CASE WHEN SMAsstKind = 4110003 THEN VATAmt ELSE 0 END)))), 13), 1, 1, '-')    
                  END --14. ����_������ݱ�    
               + RIGHT('00000000000' + CONVERT(VARCHAR(11), SUM(CASE WHEN SMAsstKind = 4110004 THEN Cnt ELSE 0 END)), 11)    --15. �Ǽ�_��Ÿ�������ڻ�    
               + CASE WHEN SUM(CASE WHEN SMAsstKind = 4110004 THEN SupplyAmt ELSE 0 END) >= 0 THEN    
                 RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(CASE WHEN SMAsstKind = 4110004 THEN SupplyAmt ELSE 0 END))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(CASE WHEN SMAsstKind = 4110004 THEN SupplyAmt ELSE 0 END)))), 13), 1, 1, '-')    
                  END --16. ���ް���_������ݱ�    
               + CASE WHEN SUM(CASE WHEN SMAsstKind = 4110004 THEN VATAmt ELSE 0 END) >= 0 THEN    
                       RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(CASE WHEN SMAsstKind = 4110004 THEN VATAmt ELSE 0 END))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(CASE WHEN SMAsstKind = 4110004 THEN VATAmt ELSE 0 END)))), 13), 1, 1, '-')    
                  END --17. ����_������ݱ�    
               + SPACE(6)    
               , 200    
         FROM _TTAXAsstPur WITH(NOLOCK)
         WHERE CompanySeq   = @CompanySeq  
           AND TaxTermSeq   = @TaxTermSeq  
           AND TaxUnit      = @TaxUnit  
    END    
END  
/***************************************************************************************************************************    
�������� ���� ���Լ��� ����
    
01. �ڷᱸ��(2) : 17    
02. �����ڵ�(7) : I103300 / V153
03. �ż��հ�_���ݰ�꼭(11)    
04. ���ް����հ�_���ݰ�꼭(15)    
05. ���Լ����հ�_���ݰ�꼭(15)
06. ������԰��ް����հ�_�Ⱥа��(15)    
07. ������Լ����հ�_�Ⱥа��(15)    
08. �Ұ������Լ����հ�_�Ⱥа��(15)    
09. �Ұ������Լ����Ѿ��հ�_���곻��(15)    
10. ��Ұ������Լ����հ�_���곻��(15)    
11. ����, �������Լ����հ�_���곻��(15)    
12. ����, �������Լ����հ�_��������(15)    
13. ����(45)    
****************************************************************************************************************************/    
  
    DECLARE @NotDeducNum    DECIMAL(19,5) ,    
            @NotDeducAmt    DECIMAL(19,5) ,    
            @NotDeducTaxAmt DECIMAL(19,5) ,    
            @Amt19V153_09   DECIMAL(19,4) ,    
            @Amt19V153_10   DECIMAL(19,4) ,    
            @Amt19V153_13   DECIMAL(19,4) ,    
            @Amt20V153_16   DECIMAL(19,4) ,    
            @Amt20V153_17   DECIMAL(19,4) ,    
            @Amt20V153_18   DECIMAL(19,4) ,    
            @Amt21V153_22   DECIMAL(19,4)    
  
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT 1 FROM _TTAXNotDeductSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND (SupplyAmt <> 0 OR VATAmt <> 0) )  
         --OR EXISTS (SELECT 1 FROM _TTAXNotDeduct19Sum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit  
         --                                                            AND ( Amt19V153_09 <> 0 OR Amt19V153_10 <> 0 OR Amt19V153_11 <> 0 OR Amt19V153_12 <> 0 OR Amt19V153_13 <> 0 ) )  
         OR EXISTS (SELECT 1 FROM _TTAXNotDeduct20Sum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit  
                                                                     AND ( Amt20V153_14 <> 0 OR Amt20V153_15 <> 0 OR Amt20V153_17 <> 0) )  
         OR EXISTS (SELECT 1 FROM _TTAXNotDeduct21Sum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit  
                                                                     AND ( Amt21V153_19 <> 0 OR Amt21V153_20 <> 0 OR Amt21V153_21 <> 0) )  
    BEGIN  
        SELECT @NotDeducNum = SUM( ISNULL( NotDeduc.Cnt ,0) ) ,         --03. ���ݰ�꼭�ż�    
               @NotDeducAmt = SUM( ISNULL( NotDeduc.SupplyAmt ,0) ) ,   --04. ���ݰ�꼭 ���ް���    
               @NotDeducTaxAmt = SUM( ISNULL( NotDeduc.VATAmt ,0) )     --05. ���ݰ�꼭 ���Լ���    
            FROM _TTAXNotDeductSum AS NotDeduc WITH(NOLOCK)
            WHERE NotDeduc.CompanySeq   = @CompanySeq  
              AND NotDeduc.TaxTermSeq   = @TaxTermSeq  
              AND NotDeduc.TaxUnit      = @TaxUnit  
              AND (NotDeduc.Cnt <> 0 OR NotDeduc.SupplyAmt <> 0 OR NotDeduc.VATAmt <> 0 )  
  
        SELECT @Amt19V153_09 = SUM( ISNULL( CVat.Amt19V153_09 ,0) ) ,   --06.������԰��ް����հ�_�Ⱥа��    
               @Amt19V153_10 = SUM( ISNULL( CVat.Amt19V153_10 ,0) ) ,   --07.������Լ����հ�_�Ⱥа��    
               @Amt19V153_13 = SUM( ISNULL( CVat.Amt19V153_13 ,0) )     --08.�Ұ������Լ����հ�_�Ⱥа��
            FROM _TTAXNotDeduct19Sum AS CVat WITH(NOLOCK)
            WHERE CVat.CompanySeq   = @CompanySeq  
              AND CVat.TaxTermSeq   = @TaxTermSeq  
              AND CVat.TaxUnit      = @TaxUnit  
  
        SELECT @Amt20V153_16 = SUM( ISNULL(CVat.Amt20V153_16, 0) ) ,    --09.�Ұ������Լ����Ѿ��հ�_���곻��
               @Amt20V153_17 = SUM( ISNULL(CVat.Amt20V153_17 ,0) ) ,    --10.��Ұ������Լ����հ�_���곻��    
               @Amt20V153_18 = SUM( ISNULL(CVat.Amt20V153_16, 0) ) - SUM( ISNULL(CVat.Amt20V153_17, 0) ) --11.����, �������Լ����հ�_���곻�� 
            FROM _TTAXNotDeduct20Sum AS CVat WITH(NOLOCK)
            WHERE CVat.CompanySeq   = @CompanySeq  
              AND CVat.TaxTermSeq   = @TaxTermSeq  
              AND CVat.TaxUnit      = @TaxUnit  
        -- �հ� �� ����Ǿ� �� ������ ���� �߻��Ͽ� ���� �� �հ��ϵ��� ����
        SELECT @Amt21V153_22 = SUM( FLOOR( ISNULL( CVat.Amt21V153_19 ,0)  * ISNULL( CVat.Amt21V153_20 ,0) * ISNULL( CVat.Amt21V153_21 ,0)) )      --12.����, �������Լ����հ�_��������    
            FROM _TTAXNotDeduct21Sum AS CVat WITH(NOLOCK)
            WHERE CVat.CompanySeq   = @CompanySeq  
              AND CVat.TaxTermSeq   = @TaxTermSeq  
              AND CVat.TaxUnit      = @TaxUnit  
        
         INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
         SELECT '17' --01.�ڷᱸ��    
              + 'I103300' --02.�����ڵ�    
              + RIGHT('00000000000'     + CONVERT(VARCHAR(11), FLOOR( ISNULL(@NotDeducNum,0) )), 11)       --03. ���ݰ�꼭�ż�    
              + CASE WHEN FLOOR( ISNULL(@NotDeducAmt,0) ) >= 0 THEN                                                                     --04. ���ݰ�꼭 ���ް���    
                      RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR( ISNULL(@NotDeducAmt,0) )), 15)    
                 ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR( ISNULL(@NotDeducAmt,0) ))), 15), 1, 1, '-')    
                 END    
              + CASE WHEN FLOOR( ISNULL(@NotDeducTaxAmt,0) ) >= 0 THEN                                                                  --05. ���ݰ�꼭 ���Լ���    
                      RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR( ISNULL(@NotDeducTaxAmt,0) )), 15)    
                 ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR( ISNULL(@NotDeducTaxAmt,0) ))), 15), 1, 1, '-')    
                 END    
              + CASE WHEN FLOOR( ISNULL(@Amt19V153_09,0) ) >= 0 THEN                                                                    --06.������԰��ް����հ�_�Ⱥа��    
                      RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR( ISNULL(@Amt19V153_09,0) )), 15)    
                 ELSE    
                  STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR( ISNULL(@Amt19V153_09,0) ))), 15), 1, 1, '-')    
                 END    
              + CASE WHEN FLOOR( ISNULL(@Amt19V153_10,0) ) >= 0 THEN                                                                    --07.������Լ����հ�_�Ⱥа��    
                      RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR( ISNULL(@Amt19V153_10,0) )), 15)    
                 ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR( ISNULL(@Amt19V153_10,0) ))), 15), 1, 1, '-')    
                 END    
              + CASE WHEN FLOOR( ISNULL(@Amt19V153_13,0) ) >= 0 THEN                                                                    --08.�Ұ������Լ����հ�_�Ⱥа��    
                      RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR( ISNULL(@Amt19V153_13,0) )), 15)    
                 ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR( ISNULL(@Amt19V153_13,0) ))), 15), 1, 1, '-')    
                 END    
              + CASE WHEN FLOOR( ISNULL(@Amt20V153_16,0) ) >= 0 THEN                                                                    --09.�Ұ������Լ����Ѿ��հ�_���곻��    
                      RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR( ISNULL(@Amt20V153_16,0) )), 15)    
                 ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR( ISNULL(@Amt20V153_16,0) ))), 15), 1, 1, '-')    
                 END    
              + CASE WHEN FLOOR( ISNULL(@Amt20V153_17,0) ) >= 0 THEN                                                                    --10.��Ұ������Լ����հ�_���곻��    
                      RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR( ISNULL(@Amt20V153_17,0) )), 15)    
                 ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR( ISNULL(@Amt20V153_17,0) ))), 15), 1, 1, '-')    
                 END    
              + CASE WHEN FLOOR( ISNULL(@Amt20V153_18,0) ) >= 0 THEN                                                                    --11.����, �������Լ����հ�_���곻��    
                      RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR( ISNULL(@Amt20V153_18,0) )), 15)    
                 ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR( ISNULL(@Amt20V153_18,0) ))), 15), 1, 1, '-')    
                 END    
              + CASE WHEN FLOOR( ISNULL(@Amt21V153_22,0) ) >= 0 THEN                                                                    --12.����, �������Լ����հ�_��������    
                      RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR( ISNULL(@Amt21V153_22,0) )), 15)    
                 ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR( ISNULL(@Amt21V153_22,0) ))), 15), 1, 1, '-')    
                 END    
              + SPACE(45)    
              , 200    
    END    
END    
/***************************************************************************************************************************    
�������� ���� ���Լ��� ����_��              �Ұ�����������
01. �ڷᱸ��        (2) : 18                    [01] �ʿ���������״���
02. �����ڵ�        (7) : I103300 / V153        [02] ����� �������� ���� ����
03. �Ұ�����������  (2) :                       [03] �񿵾��� �����¿��� ���� �� ����
04. ���ݰ�꼭�ż�  (11)                        [04] ����� �� �̿� ������ ��� ����
05. ���ް���        (13)                        [05] �鼼�������
06. ���Լ���        (13)                        [06] ������ �ں����������
07. ����            (52)                        [07] ����ڵ�� �� ���Լ���
                                                [08] ��,������ũ�� �ŷ����� �̻�� ���� ���Լ���
****************************************************************************************************************************/    
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT * FROM _TTAXNotDeductSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND (SupplyAmt <> 0 OR VATAmt <> 0))  
    BEGIN  
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT '18'   --01. �ڷᱸ��    
                   + 'I103300'  --02. �����ڵ�    
                   + RIGHT('00' + CONVERT(VARCHAR(2), NotDeduc.SMNotDeductKind - 4109000), 2)   --03. �Ұ����׸��ȣ    
                   + RIGHT('00000000000' + CONVERT(VARCHAR(11), FLOOR(NotDeduc.Cnt)), 11)       --04. ���ݰ�꼭�ż�    
                   + CASE WHEN FLOOR(NotDeduc.SupplyAmt) >= 0 THEN                              --05. ���ݰ�꼭 ���ް���    
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(NotDeduc.SupplyAmt)), 13)    
                     ELSE    
                           STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(NotDeduc.SupplyAmt))), 13), 1, 1, '-')    
                     END    
                   + CASE WHEN FLOOR(NotDeduc.VATAmt) >= 0 THEN                                 --06. ���ݰ�꼭 ���Լ���    
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(NotDeduc.VATAmt)), 13)    
                     ELSE    
                           STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(NotDeduc.VATAmt))), 13), 1, 1, '-')    
                     END    
                   + SPACE(52)    
                   , 100    
             FROM _TTAXNotDeductSum AS NotDeduc WITH(NOLOCK)
             WHERE NotDeduc.CompanySeq  = @CompanySeq  
               AND NotDeduc.TaxTermSeq  = @TaxTermSeq  
               AND NotDeduc.TaxUnit     = @TaxUnit  
               AND ( NotDeduc.Cnt <> 0 OR NotDeduc.SupplyAmt <> 0 OR NotDeduc.VATAmt <> 0)  
             ORDER BY NotDeduc.SMNotDeductKind   
        
    END    
END      
/***************************************************************************************************************************    
�������� ���� ���Լ��� ����_������Լ��׾Ⱥа�곻��          2006.03.17 <�űԼ���>        -- 20060708 by Him    
    
01. �ڷᱸ��(2) : 19    
02. �����ڵ�(7) : I103300 / V153
03. �Ϸù�ȣ(6) : 000001 ���� ���������� �ο�    
04. ������԰��ް���(13)    :    
05. ������Լ���(13)        :    
06. �Ѱ��ް��׵�(15,2)        :    
07. �鼼���ް��׵�(15,2)    
08. �Ұ������Լ���(13)      : 05.������Լ��� * ( 07.�鼼���ް��׵� / 06.�Ѱ��ް��׵� ) , ( 07.�鼼���ް��׵� / 06.�Ѱ��ް��׵� ) ��갪�� �Ҽ� 6�ڸ�    
09. ����(19)    
****************************************************************************************************************************/    
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT 1 FROM _TTAXNotDeductSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND (SupplyAmt <> 0 OR VATAmt <> 0) )  
         --OR EXISTS (SELECT 1 FROM _TTAXNotDeduct19Sum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit  
         --                                                            AND ( Amt19V153_09 <> 0 OR Amt19V153_10 <> 0 OR Amt19V153_11 <> 0 OR Amt19V153_12 <> 0 OR Amt19V153_13 <> 0 ) )  
         OR EXISTS (SELECT 1 FROM _TTAXNotDeduct20Sum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit  
                                                                     AND ( Amt20V153_14 <> 0 OR Amt20V153_15 <> 0 OR Amt20V153_17 <> 0) )  
         OR EXISTS (SELECT 1 FROM _TTAXNotDeduct21Sum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit  
                                                                     AND ( Amt21V153_19 <> 0 OR Amt21V153_20 <> 0 OR Amt21V153_21 <> 0) )
                                                                     
        AND EXISTS (SELECT 1 FROM _TTAXNotDeduct19Sum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)      
    BEGIN    
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT '19'   --01. �ڷᱸ��    
                   + 'I103300'  --02. �����ڵ�    
                   + RIGHT('000000' + CONVERT(VARCHAR(6), FLOOR( ISNULL( CVat.Serl ,0) )), 6) --03. �Ϸù�ȣ    
                   + CASE WHEN FLOOR( ISNULL( CVat.Amt19V153_09 ,0) ) >= 0 THEN                                                    --04. ������� ���ް���(9)    
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR( ISNULL( CVat.Amt19V153_09 ,0) )), 13)    
                     ELSE    
                          STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR( ISNULL( CVat.Amt19V153_09 ,0) ))), 13), 1, 1, '-')    
                     END    
                   + CASE WHEN FLOOR( ISNULL( CVat.Amt19V153_10 ,0) ) >= 0 THEN                                                    --05. ������� ����(10)    
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR( ISNULL( CVat.Amt19V153_10 ,0) )), 13)    
                     ELSE    
                          STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR( ISNULL( CVat.Amt19V153_10 ,0) ))), 13), 1, 1, '-')    
                     END    
                   +  dbo._FnVATIntChg((ISNULL(CVat.Amt19V153_11   , 0)), 15, 2, 1)
                   --+ CASE WHEN CONVERT(NUMERIC(19, 0), ISNULL( CVat.Amt19V153_11 ,0) ) >= 0 THEN                                   --06. �Ѱ��ް��� �� (11)    
                   --       RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 0), ISNULL( CVat.Amt19V153_11 ,0) )), '.', ''), 15)    
                   --  ELSE    
                   --       STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 0), ABS(ISNULL( CVat.Amt19V153_11 ,0)) )), '.', ''), 15), 1, 1, '-')    
                   --  END    
                   + dbo._FnVATIntChg((ISNULL(CVat.Amt19V153_12   , 0)), 15, 2, 1)
                   --+ CASE WHEN CONVERT(NUMERIC(19, 0), ISNULL( CVat.Amt19V153_12 ,0) ) >= 0 THEN                                   --07. �鼼���ް��� �� (12)    
                   --       RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 0), ISNULL( CVat.Amt19V153_12 ,0) )), '.', ''), 15)    
                   --  ELSE    
                   --       STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 0), ABS(ISNULL( CVat.Amt19V153_12 ,0)) )), '.', ''), 15), 1, 1, '-')    
                   --  END    
                   + CASE WHEN FLOOR( ISNULL( CVat.Amt19V153_13 ,0) ) >= 0 THEN                                                    --08. �Ұ������Լ���(13) = 10 * (12/11)    
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR( ISNULL( CVat.Amt19V153_13 ,0) )), 13)    
                     ELSE    
                          STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR( ISNULL( CVat.Amt19V153_13 ,0) ))), 13), 1, 1, '-')    
                     END    
                   + SPACE(16)    
                   , 100    
             FROM _TTAXNotDeduct19Sum AS CVat WITH(NOLOCK)
             WHERE CVat.CompanySeq  = @CompanySeq  
               AND CVat.TaxTermSeq  = @TaxTermSeq  
               AND CVat.TaxUnit     = @TaxUnit  
               AND (CVat.Amt19V153_09 <> 0 OR CVat.Amt19V153_10 <> 0 OR CVat.Amt19V153_11 <> 0 OR CVat.Amt19V153_12 <> 0 OR CVat.Amt19V153_13 <> 0)  
             ORDER BY CVat.Serl    
    END    
END      
/***************************************************************************************************************************    
�������� ���� ���Լ��� ����_������Լ������곻��
    
01. �ڷᱸ��(2) : 20    
02. �����ڵ�(7) : I103300 / V153
03. �Ϸù�ȣ(6) : 000001 ���� ���������� �ο�    
04. �Ѱ�����Լ���(13)    :    
05. �鼼���Ȯ������(11,6)        :    
06. �Ұ������Լ����Ѿ�(13)    
07. ��Ұ������Լ���(13)    
08. ����/�������Լ���(13)    
09. ����(22)    
****************************************************************************************************************************/    
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT * FROM _TTAXNotDeduct20Sum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
    BEGIN    
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT '20'   --01. �ڷᱸ��    
                   + 'I103300'  --02. �����ڵ�    
                   + RIGHT('000000' + CONVERT(VARCHAR(6), FLOOR( ISNULL( CVat.Serl ,0) )), 6) --03. �Ϸù�ȣ    
                   + CASE WHEN FLOOR( ISNULL( CVat.Amt20V153_14 ,0) ) >= 0 THEN                                     --04. �Ѱ�����Լ���(14)    
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR( ISNULL( CVat.Amt20V153_14 ,0) )), 13)    
                     ELSE    
                          STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR( ISNULL( CVat.Amt20V153_14 ,0) ))), 13), 1, 1, '-')    
                     END    
                   + CASE WHEN CONVERT(NUMERIC(15, 6), ISNULL( CVat.Amt20V153_15  ,0) ) >= 0 THEN                    --05. �鼼���Ȯ������(15)    
                          RIGHT('00000000000' + REPLACE(CONVERT(VARCHAR(11), CONVERT(NUMERIC(15, 6), ISNULL( CVat.Amt20V153_15  ,0) )), '.', ''), 11)    
                     ELSE    
                          STUFF(RIGHT('00000000000' + REPLACE(CONVERT(VARCHAR(11), ABS(CONVERT(NUMERIC(15, 6), ISNULL( CVat.Amt20V153_15  ,0) ))), '.', ''), 11), 1, 1, '-')    
                     END
                   + CASE WHEN FLOOR( ISNULL( CVat.Amt20V153_16 ,0) ) >= 0 THEN                                     --06. �Ұ��� ���Լ����Ѿ�(16) = (14 * 15)    
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR( ISNULL( CVat.Amt20V153_16 ,0) )), 13)    
                     ELSE    
                          STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR( ISNULL( CVat.Amt20V153_16 ,0) ))), 13) , 1, 1, '-')    
                     END   
                   + CASE WHEN FLOOR( ISNULL( CVat.Amt20V153_17 ,0) ) >= 0 THEN                                     --07. ��Ұ������Լ���(17)    
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR( ISNULL( CVat.Amt20V153_17 ,0) )), 13)    
                     ELSE    
                          STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR( ISNULL( CVat.Amt20V153_17 ,0) ))), 13), 1, 1, '-')    
                     END
                   + CASE WHEN FLOOR( ( ISNULL( CVat.Amt20V153_16 ,0) ) - ISNULL( CVat.Amt20V153_17 ,0) ) >= 0 THEN --08. ���� �Ǵ� �����Ǵ� ���Լ��� (18) = (16-17)
                                RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR( ( ISNULL( CVat.Amt20V153_16 ,0) ) - ISNULL( CVat.Amt20V153_17 ,0) )), 13)    
                     ELSE    
                            STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS( FLOOR( ( ISNULL( CVat.Amt20V153_16 ,0) ) - ISNULL( CVat.Amt20V153_17 ,0) ))), 13), 1, 1, '-')    
                     END  
                   + SPACE(22)    
                   , 100    
             FROM _TTAXNotDeduct20Sum AS CVat WITH(NOLOCK)
             WHERE CVat.CompanySeq  = @CompanySeq  
               AND CVat.TaxTermSeq  = @TaxTermSeq  
               AND CVat.TaxUnit     = @TaxUnit  
               AND (CVat.Amt20V153_14 <> 0 OR CVat.Amt20V153_15 <> 0 OR CVat.Amt20V153_17 <> 0)  
             ORDER BY CVat.Serl    
    END    
END      
/***************************************************************************************************************************    
�������� ���� ���Լ��� ����_���μ���_ȯ�޼������곻��
    
01. �ڷᱸ��(2) : 20    
02. �����ڵ�(7) : I103300 / V153
03. �Ϸù�ȣ(6) : 000001 ���� ���������� �ο�    
04. ��ȭ���Լ���(13)    
05. �氨��_��������(7,4)    
06. ����/���Ҹ鼼����(11,6)    
07. ����/�������Լ���(13)    
08. ����(41)    
****************************************************************************************************************************/   
IF @WorkingTag = ''  
BEGIN   
    IF EXISTS (SELECT * FROM _TTAXNotDeduct21Sum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
    BEGIN    
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT '21'   --01. �ڷᱸ��    
                   + 'I103300'  --02. �����ڵ�    
                   + RIGHT('000000' + CONVERT(VARCHAR(6), FLOOR( ISNULL( CVat.Serl ,0) )), 6)           --03. �Ϸù�ȣ    
                   + CASE WHEN FLOOR( ISNULL( CVat.Amt21V153_19 ,0) ) >= 0 THEN                         --04. �ش� ��ȭ�� ���Լ���(19)    
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR( ISNULL( CVat.Amt21V153_19 ,0) )), 13)    
                     ELSE    
                          STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR( ISNULL( CVat.Amt21V153_19 ,0) ))), 13) , 1, 1, '-')    
                     END    
                   + CASE WHEN FLOOR( ISNULL( CVat.Amt21V153_20 ,0) ) >= 0 THEN                         --05. �氨��[1-(5/100) �Ǵ� 25/100 * ����� �����Ⱓ�� ��)](20)    
                          RIGHT('0000000' + REPLACE(CONVERT(VARCHAR(13), CONVERT(NUMERIC(15, 4), ISNULL( CVat.Amt21V153_20 ,0) )), '.', ''), 7)    
                     ELSE    
                          STUFF(RIGHT('0000000' + REPLACE(CONVERT(VARCHAR(13), ABS(CONVERT(NUMERIC(15, 4), ISNULL( CVat.Amt21V153_20 ,0) ))), '.', ''), 7) , 1, 1, '-')    
                     END    
                   + CASE WHEN FLOOR( ISNULL( CVat.Amt21V153_21 ,0) ) >= 0 THEN                         --06. ���� �Ǵ� ���ҵ� �鼼���ް���(������)����(21)    
                          RIGHT('00000000000' + REPLACE(CONVERT(VARCHAR(11), CONVERT(NUMERIC(15, 6), ISNULL( CVat.Amt21V153_21 ,0) )), '.', ''), 11)    
                     ELSE    
                          STUFF(RIGHT('00000000000' + REPLACE(CONVERT(VARCHAR(11), ABS(CONVERT(NUMERIC(15, 6), ISNULL( CVat.Amt21V153_21 ,0) ))), '.', ''), 11) , 1, 1, '-')    
                     END    
                   + CASE WHEN ISNULL( CVat.Amt21V153_19 ,0)  * ISNULL( CVat.Amt21V153_20 ,0) * ISNULL( CVat.Amt21V153_21 ,0)  >= 0 THEN    --07. ���� �Ǵ� �����Ǵ� ���Լ���(22) = (19*20*21)
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR( ISNULL( CVat.Amt21V153_19 ,0)  * ISNULL( CVat.Amt21V153_20 ,0) * ISNULL( CVat.Amt21V153_21 ,0) )), 13)    
                     ELSE    
                          STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR( ISNULL( CVat.Amt21V153_19 ,0)  * ISNULL( CVat.Amt21V153_20 ,0) * ISNULL( CVat.Amt21V153_21 ,0) ))), 13) , 1, 1, '-')    
                     END
                   + SPACE(41)    
                   , 100    
              FROM _TTAXNotDeduct21Sum AS CVat WITH(NOLOCK)
             WHERE CVat.CompanySeq  = @CompanySeq  
               AND CVat.TaxTermSeq  = @TaxTermSeq  
               AND CVat.TaxUnit     = @TaxUnit  
               AND (CVat.Amt21V153_19 <> 0 OR CVat.Amt21V153_20 <> 0 OR CVat.Amt21V153_21 <> 0)  
             ORDER BY CVat.Serl    
    END    
END      
/***************************************************************************************************************************    
�����Ǹž��հ�ǥ(��.���.��.���������)    
    
01. �ڷᱸ��(2) : 17    
02. �����ڵ�(7) : M200100 / V148
03. ����(06) : YYYYMM
04. ǰ��(30) : NULL���, ���� �Ǹ� ǰ��
05. �Ǹż���(20) : NOT NULL, CHARACTER�Է°��� 
06. �ǸŰ���(13)
07. �ǸŰ���_�հ�(15)
08. �����Ǹ��հ�ǥ���ⱸ���ڵ�(2) : 01 ����ο뺸�屸, 02 �����Ӿ���������
09. ����(9)
****************************************************************************************************************************/    
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT 1 FROM _TTAXMonSalesSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND IsSUM = 0 )  
    BEGIN
        DECLARE @MonSalesSum DECIMAL(19,5)
        
        SELECT @MonSalesSum = ISNULL((SELECT SUM(SalesAmt)
                                        FROM _TTAXMonSalesSum WITH(NOLOCK) 
                                       WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq 
                                         AND TaxUnit = @TaxUnit       AND IsSUM = 0),0)
      
         INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
         SELECT '17'                                                -- 01. �ڷᱸ��    
              + 'M200100'                                           -- 02. �����ڵ�    
			  + dbo._FnVATIntChg(ISNULL(A.YM,''),6,0,1)             -- 03. ����			
			  + dbo._FnVATCHARChg(CONVERT(VARCHAR(30), MAX(ISNULL(B.ItemName,''))), 30, 1)	-- 04. ǰ��
			  + CASE WHEN ISNULL(A.UMReportKind, 0) = 4110002 
			         THEN dbo._FnVATIntChg(0                    , 20, 0, 1)     -- ����ο뺸�屸 �� ��� 0���� ����
			         ELSE dbo._FnVATIntChg(SUM(ISNULL(A.Qty ,0)), 20, 0, 1)
			    END                                                         -- 05. �Ǹż���
			  + dbo._FnVATIntChg(SUM(ISNULL(A.SalesAmt   , 0)), 13, 0, 1)	-- 06. �ǸŰ���
			  + dbo._FnVATIntChg(SUM(ISNULL(@MonSalesSum , 0)), 15, 0, 1)	-- 07. �ǸŰ���_�հ�
			  + CASE WHEN ISNULL(A.UMReportKind, 0) = 4110001 THEN '02' -- 08. �����Ǹ��հ�ǥ���ⱸ���ڵ� : (�⺻ ������)
			         WHEN ISNULL(A.UMReportKind, 0) = 4110002 THEN '01' -- [01] ����ο뺸�屸,
			         ELSE '02'  END                                     -- [02] �����Ӿ���������
			  + SPACE(55)		                                    -- 09. ����
			  , 150   
          FROM _TTAXMonSalesSum AS A WITH(NOLOCK) LEFT OUTER JOIN _TDAItem AS B WITH(NOLOCK) 
                                                   ON A.CompanySeq  = B.CompanySeq 
                                                  AND A.ItemSeq     = B.ItemSeq
         WHERE A.CompanySeq   = @CompanySeq  
           AND A.TaxTermSeq   = @TaxTermSeq  
           AND A.TaxUnit      = @TaxUnit  
           AND A.IsSUM        <> 1
         GROUP BY ISNULL(A.YM,'') , A.UMReportKind, A.ItemSeq
    END    
END   

/***************************************************************************************************************************
�����ڹ��༼�ݰ�꼭�հ�ǥ_�հ�
01. �ڷᱸ��                     2
02. �����ڵ�                     7
03. ����ó��                     7
04. ���ݰ�꼭�ż�_�հ�          7
05. ���ް���_�հ�               15
06. ����_�հ�                   15
07. ����                        47
****************************************************************************************************************************/
IF @WorkingTag = ''
BEGIN
    IF EXISTS (SELECT 1 FROM _TTAXTaxBillBuySum AS A WITH (NOLOCK) WHERE A.CompanySeq = @CompanySeq AND A.TaxTermSeq = @TaxTermSeq AND A.TaxUnit = @TaxUnit)
    BEGIN
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)
        SELECT '17'
      /*02*/ + 'M118000'
      /*03*/ + RIGHT('0000000' + CONVERT(VARCHAR(7), COUNT(A.CustSeq)), 7)
      /*04*/ + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(A.CustSeq, 0) <> 0 THEN A.BillCnt ELSE 0 END), 7, 0, 1)
      /*05*/ + dbo._FnVATIntChg(SUM(A.SupplyAmt), 15, 0, 1)
      /*06*/ + dbo._FnVATIntChg(SUM(A.VATAmt)   , 15, 0, 1)
      /*07*/ + SPACE(47)
             , 100
          FROM _TTAXTaxBillBuySum AS A WITH(NOLOCK)
         WHERE A.CompanySeq = @CompanySeq
           AND A.TaxTermSeq = @TaxTermSeq
           AND A.TaxUnit    = @TaxUnit
    /***************************************************************************************************************************
    �����ڹ��༼�ݰ�꼭�հ�ǥ_���γ���
    01. �ڷᱸ��                     2
    02. �����ڵ�                     7
    03. �Ϸù�ȣ                     6
    04. �ŷ��ڵ�Ϲ�ȣ              10
    05. �ŷ��ڻ�ȣ                  30
    06. ���ݰ�꼭�ż�               7
    07. ���ް���                    13
    08. ����                        13
    09. ����                        12
    ****************************************************************************************************************************/
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)
        SELECT '18'
      /*02*/ + 'M118000'
      /*03*/ + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY B.CustName)), 6)
      /*04*/ + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), B.BizNo)   , 10, 1)
      /*05*/ + dbo._FnVATCHARChg(CONVERT(VARCHAR(30), B.FullName), 30, 1)
      /*06*/ + dbo._FnVATIntChg(CASE WHEN ISNULL(A.CustSeq, 0) <> 0 THEN A.BillCnt ELSE 0 END, 7, 0, 1)
      /*07*/ + dbo._FnVATIntChg(A.SupplyAmt , 13, 0, 1)
      /*08*/ + dbo._FnVATIntChg(A.VATAmt    , 13, 0, 1)
      /*09*/ + SPACE(12)
             , 100
          FROM _TTAXTaxBillBuySum   AS A WITH(NOLOCK)
               JOIN _TDACust        AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                     AND A.CustSeq    = B.CustSeq
         WHERE A.CompanySeq = @CompanySeq
           AND A.TaxTermSeq = @TaxTermSeq
           AND A.TaxUnit    = @TaxUnit
    END
END
-- 2017�� 1�� ���� �߰�
/***************************************************************************************************************************
÷�μ���17. ���������ȯ�������ڻ�Ű�
-- ���������ȯ�������ڻ�Ű�_�鼼�������������
01. �ڷᱸ��                    (2)     : 17
02. �����ڵ�                    (7)     : I102600
03. ����������_�Һ�ñ�       (8)
04. ��ȣ_�鼼�����             (30)
05. ����ڵ�Ϲ�ȣ_�鼼�����   (10)
06. ����������_�鼼�����     (70)
07. ��ȭ��ȣ_�鼼�����         (14)
08. ����                        (9)
-- ���������ȯ�������ڻ�Ű� �������ڻ�Ű�
01. �ڷᱸ��            (2)
02. �����ڵ�            (7)
03. �Ϸù�ȣ            (6)
04. �������ڻ�_����   (2) : 01 - ����/���๰, 02 - ��Ÿ
05. ����                (11)
06. �����              (8)
07. �鼼�Ұ�������      (13)
08. �����������Լ���    (13)
09. �������            (70)
10. ����                (18)
**************************************************************************************************************************/
IF @WorkingTag = ''
BEGIN
    IF EXISTS (SELECT 1 FROM _TTAXBizChangeAssets AS A WITH (NOLOCK)
                        JOIN _TTAXBizChangeAssetsDtl AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                                      AND A.TaxTermSeq = B.TaxTermSeq
                                                                      AND A.TaxUnit    = B.TaxUnit
        WHERE A.CompanySeq = @CompanySeq
          AND A.TaxTermSeq = @TaxTermSeq
          AND A.TaxUnit    = @TaxUnit )
    BEGIN
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)
        SELECT '17'         --01. �ڷᱸ��
             + 'I102600'    --02. �����ڵ�
             + CONVERT(VARCHAR(8), A.UseDate)   --03. ����������_�Һ�ñ�
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(30), ISNULL(B.TaxName  ,'')), 30, 1)   --04. ��ȣ_�鼼�����
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), ISNULL(B.TaxNo    ,'')), 10, 1)   --05. ����ڵ�Ϲ�ȣ_�鼼�����
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(70), ISNULL(@Addr1     ,'')), 70, 1)   --06. ����������_�鼼�����
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(14), ISNULL(B.TelNo    ,'')), 14, 1)   --07. ��ȭ��ȣ_�鼼�����
             + SPACE(9)     --08. ����
            , 150
          FROM _TTAXBizChangeAssets AS A WITH (NOLOCK)
                    JOIN _TDATaxUnit AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.TaxUnit= B.TaxUnit
         WHERE A.CompanySeq = @CompanySeq
           AND A.TaxTermSeq = @TaxTermSeq
           AND A.TaxUnit    = @TaxUnit
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)
        SELECT '18'         --01. �ڷᱸ��
             + 'I102600'    --02. �����ڵ�
             + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY SMAsstKind)), 6)    --03. �Ϸù�ȣ
             + CASE WHEN B.SMAsstKind = 4572001 THEN '01' ELSE '02' END --04.  �������ڻ�_���� : 01 - ����/���๰, 02 - ��Ÿ
             + dbo._FnVATIntChg( B.AsstQty            , 11, 0, 1)       --05. ����
             + CONVERT(VARCHAR(8), B.GainDate)                          --06. �����
             + dbo._FnVATIntChg( B.NDVATAmt           , 13, 0, 1)       --07. �鼼�Ұ�������
             + dbo._FnVATIntChg( B.DeducVATAmt        , 13, 0, 1)       --08. �����������Լ���
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(70), ISNULL(B.StoragePlace, '')), 70, 1)  --09. �������
             + SPACE(18)                                                --10. ����
             , 150
          FROM _TTAXBizChangeAssets AS A WITH (NOLOCK)
                JOIN _TTAXBizChangeAssetsDtl AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                              AND A.TaxTermSeq = B.TaxTermSeq
                                                              AND A.TaxUnit    = B.TaxUnit
         WHERE A.CompanySeq = @CompanySeq
           AND A.TaxTermSeq = @TaxTermSeq
           AND A.TaxUnit    = @TaxUnit
    END
END
/***************************************************************************************************************************    
�ǹ���������  
01. �ڷᱸ��        (2)
02. �����ڵ�        (7)
03. �Ϸù�ȣ����    (6)
04. �������ڵ�      (10)  
05. ��������        (50)  
06. �����          (4)   
07. ����            (4)   
08. ����ȣ          (4)   
09. ���            (80)
10. ��              (12)
11. ��ȣ            (6) 
12. ��              (4) 
13. ��              (4) 
14. �ǹ���          (60)
15. �ǹ�����        (40)
16. �������հ�      (15)
17. �ǹ�������      (200)
18. �����Ǽ�        (6)
19. ���θ��ڵ�      (12) 
20. ���θ�          (50) 
21. ���ϸ��ִ� �ǹ����� (1)  
22. �ǹ���ȣ(����)  (5)  
23. �ǹ���ȣ(�ι�)  (5)
24. ����            (13)
***************************************************************************************************************************/  
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT 1 FROM _TTAXBuildingManage WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
    BEGIN  
        CREATE TABLE #Temp_Bld (  
            Cnt             INT IDENTITY,  
            BuildingSeq     INT,  
            CountNUM        VARCHAR(6))  
  
        INSERT INTO #Temp_Bld (BuildingSeq, CountNUM)  
            SELECT BuildingSeq, RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER(ORDER BY BuildingSeq)), 6)
              FROM _TTAXBuildingManage WITH(NOLOCK)
             WHERE CompanySeq       = @CompanySeq  
               AND TaxTermSeq       = @TaxTermSeq  
               AND TaxUnit          = @TaxUnit  
  
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
            SELECT '17'             --01. �ڷᱸ��
                    + 'I104300'     --02. �����ڵ�
                    + T.CountNUM    --03. �Ϸù�ȣ����
                    + CONVERT(VARCHAR(10), A.CourtSecCode ) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), A.CourtSecCode ))) --04. �������ڵ�
                    + CONVERT(VARCHAR(50), A.CourtSecName ) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), A.CourtSecName ))) --05. ��������
                    + CONVERT(VARCHAR(04), A.MountStreetNo) + SPACE(4  - DATALENGTH(CONVERT(VARCHAR(04), A.MountStreetNo))) --06. �����
      + CONVERT(VARCHAR(04), A.StreetNo     ) + SPACE(4  - DATALENGTH(CONVERT(VARCHAR(04), A.StreetNo  )))    -- 07. ����
                    + CONVERT(VARCHAR(04), A.StreetNoHo   ) + SPACE(4  - DATALENGTH(CONVERT(VARCHAR(04), A.StreetNoHo)))    -- 08. ����ȣ
                    + CONVERT(VARCHAR(80), A.Block   ) + SPACE(80 - DATALENGTH(CONVERT(VARCHAR(80), A.Block   )))           -- 09. ���
                    + CONVERT(VARCHAR(12), A.Sector  ) + SPACE(12 - DATALENGTH(CONVERT(VARCHAR(12), A.Sector  )))           -- 10. ��
                    + CONVERT(VARCHAR(06), A.SectorNo) + SPACE(6  - DATALENGTH(CONVERT(VARCHAR(06), A.SectorNo)))           -- 11. ��ȣ
                    + CONVERT(VARCHAR(04), A.Tong    ) + SPACE(4  - DATALENGTH(CONVERT(VARCHAR(04), A.Tong    )))           -- 12. ��
                    + CONVERT(VARCHAR(04), A.Ban     ) + SPACE(4  - DATALENGTH(CONVERT(VARCHAR(04), A.Ban     )))           -- 13. ��
                    + CONVERT(VARCHAR(60), A.BuildingName   ) + SPACE(60 - DATALENGTH(CONVERT(VARCHAR(60), A.BuildingName   ))) -- 14. �ǹ���
                    + CONVERT(VARCHAR(40), A.BuildingSecName) + SPACE(40 - DATALENGTH(CONVERT(VARCHAR(40), A.BuildingSecName))) -- 15. �ǹ�����
                    + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Sub.TotAmt)), 15)                                -- 16. �������հ�
                    + CONVERT(VARCHAR(200), A.BuildingLoc) + SPACE(200 - DATALENGTH(CONVERT(VARCHAR(200), A.BuildingLoc)))  -- 17. �ǹ�������
                    + RIGHT('000000' + CONVERT(VARCHAR(6), FLOOR(Sub.Cnt)), 6)                                              -- 18. �����Ǽ�
                    + CONVERT(VARCHAR(12), A.RoadSecCode) + SPACE(12 - DATALENGTH(CONVERT(VARCHAR(12), A.RoadSecCode)))     -- 19. ���θ��ڵ�
                    + CONVERT(VARCHAR(50), A.RoadSecName) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), A.RoadSecName)))     -- 20. ���θ�
                    + CASE WHEN ISNULL(A.IsOnlyUnder, '') = '1' THEN '1'
                           ELSE SPACE(1) END                                                                        -- 21. ���ϸ��ִ°ǹ�����
                    + CASE WHEN ISNULL(A.BuildingNo, 0) = 0 THEN SPACE(5)
                           ELSE RIGHT('000000000000000' + CONVERT(VARCHAR(5), CONVERT(INT,A.BuildingNo )), 5) END   -- 22. �ǹ���ȣ(����)
                    + CASE WHEN ISNULL(A.BuildingNo2, 0) = 0 THEN SPACE(5)
                           ELSE RIGHT('000000000000000' + CONVERT(VARCHAR(5), CONVERT(INT,A.BuildingNo2)), 5) END   -- 23. �ǹ���ȣ(�ι�)
                    + SPACE(13)
                    , 600   
              FROM _TTAXBuildingManage AS A WITH(NOLOCK)
                                            JOIN (SELECT CompanySeq, TaxTermSeq, TaxUnit, BuildingSeq, SUM(ManageAmt) AS TotAmt, COUNT(*) AS Cnt  
                                                    FROM _TTaxBuildingManageDtl WITH(NOLOCK)
                                                   WHERE CompanySeq = @CompanySeq  
                                                     AND TaxTermSeq = @TaxTermSeq  
                                                     AND TaxUnit    = @TaxUnit  
                                                   GROUP BY CompanySeq, TaxTermSeq, TaxUnit, BuildingSeq) AS Sub  
                                              ON A.CompanySeq   = Sub.CompanySeq  
                                             AND A.TaxTermSeq   = Sub.TaxTermSeq  
                                             AND A.TaxUnit      = Sub.TaxUnit  
                                             AND A.BuildingSeq  = Sub.BuildingSeq  
                                            JOIN #Temp_Bld AS T  
                                              ON A.BuildingSeq  = T.BuildingSeq  
             WHERE A.CompanySeq     = @CompanySeq  
               AND A.TaxTermSeq     = @TaxTermSEq  
               AND A.TaxUnit        = @TaxUnit  

    /***************************************************************************************************************************    
    �ǹ��������� ����     
    01. �ڷᱸ��        (2)
    02. �����ڵ�        (7)
    03. �Ϸù�ȣ����    (6)
    04. �Ϸù�ȣ        (6)
    05. ������          (2)
    06. ��              (4) 
    07. ȣ�Ǹ�          (30)
    08. ȣ��ȣ          (4) 
    09. ����            (9,1)
    10. ����ڵ�Ϲ�ȣ  (13)
    11. ��ȣ(����)       (30)
    12. ������          (8)
    13. �����          (8)
    14. ������          (13)
    15. ����            (58)
    ***************************************************************************************************************************/  
        CREATE TABLE #Temp_Bld2 (  
            BuildingSeq     INT,  
            BuildingSerl    INT,  
            SubCountNUM     VARCHAR(6))  
  
        SELECT @Cnt = 1  
        SELECT @MaxCnt = COUNT(*) FROM #Temp_Bld  
        WHILE @Cnt <= @MaxCnt  
        BEGIN  
            SELECT @BuildingSeq = BuildingSeq FROM #Temp_Bld WHERE Cnt = @Cnt  
  
            INSERT INTO #Temp_Bld2 (BuildingSeq, BuildingSerl, SubCountNUM)  
                SELECT BuildingSeq, BuildingSerl, RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER(ORDER BY BuildingSerl)), 6)  
                  FROM _TTaxBuildingManageDtl WITH(NOLOCK)
                 WHERE CompanySeq       = @CompanySeq  
                   AND TaxTermSeq       = @TaxTermSeq  
                   AND TaxUnit          = @TaxUnit  
                   AND BuildingSeq      = @BuildingSeq  
  
            SELECT @Cnt = @Cnt + 1  
        END  
  
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
            SELECT '18'  
                    + 'I104300'  
                    + T1.CountNUM                                       -- 03. �Ϸù�ȣ����
                    + T2.SubCountNUM                                    -- 04. �Ϸù�ȣ
                    + '0' + CASE A.FloorKind WHEN ''  THEN SPACE(1)
                                             WHEN 'A' THEN '1'
                                             WHEN 'C' THEN '2'
                                             WHEN 'E' THEN '3'
                                             WHEN 'G' THEN '4'
                                             WHEN 'I' THEN '5'
                                             ELSE A.FLoorKind END       -- 05. ���ܻ���
                    + RIGHT('0000' + CONVERT(VARCHAR(4), A.Floor), 4)   -- 06. ��
                    + CONVERT(VARCHAR(30), A.HoName) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), A.HoName)))   -- 07. ȣ�Ǹ�
                    + RIGHT('0000' + CONVERT(VARCHAR(4), A.HoNo), 4)                                            -- 08. ȣ��ȣ
                    + RIGHT('000000000' + REPLACE(CONVERT(VARCHAR(10), CONVERT(DECIMAL(9, 1), ROUND(Area, 1))), '.', ''), 9)   -- 09. ����
                    + CONVERT(VARCHAR(13), REPLACE(A.ManageTaxNo, '-', '')) + SPACE(13 - DATALENGTH(CONVERT(VARCHAR(13), REPLACE(A.ManageTaxNo, '-', '')))) -- 10. ����ڵ�Ϲ�ȣ
                    + CONVERT(VARCHAR(30), A.ManageTaxName) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), A.ManageTaxName)))    -- 11. ��ȣ(����)
                    + CONVERT(VARCHAR(08), A.MoveInDate   ) + SPACE(8  - DATALENGTH(CONVERT(VARCHAR(08), A.MoveInDate   )))    -- 12. ������
                    + CONVERT(VARCHAR(08), A.EvictionDate ) + SPACE(8  - DATALENGTH(CONVERT(VARCHAR(08), A.EvictionDate )))    -- 13. �����
                    + dbo._FnVATIntChg(A.ManageAmt    , 13, 0, 1)                                                              -- 14. ������
                    + SPACE(58)
                    , 200  
               FROM _TTaxBuildingManageDtl AS A WITH(NOLOCK)
                                                JOIN #Temp_Bld AS T1  
                                                  ON A.BuildingSeq  = T1.BuildingSeq  
                                                JOIN #Temp_Bld2 AS T2  
                                                  ON A.BuildingSeq  = T2.BuildingSeq  
                                                 AND A.BuildingSerl = T2.BuildingSerl  
              WHERE A.CompanySeq    = @CompanySeq  
                AND A.TaxTermSeq    = @TaxTermSeq  
                AND A.TaxUnit       = @TaxUnit  
                
    END  
END  

/***************************************************************************************************************************    
����ڴ��������ǻ���庰�ΰ���ġ������ǥ�ع׳��μ���(ȯ�޼���)�Ű����    
***************************************************************************************************************************/
IF @WorkingTag IN ('', 'U')  
BEGIN  
    -- ����ڴ��������� ��츸 ���    
    IF @Env4016 = 4125002  --����ڴ�������  
        AND (@TaxFrDate + '01') >= @Env4017 -- ����ڴ�������������������  
    BEGIN  
    
        IF @WorkingTag = 'U' --- ��������  
        BEGIN  
            -- ������ ��������(HEAD RECORD)  
            --��ȣ  �׸�                          ����  ����  ��������  ���  
            --1     ���ڵ屸��                    ����  2     2         UH  
            --2     �ͼӳ⵵                      ����  4     6         YYYY��  
            --3     �ݱⱸ��                      ����  1     7         1: 1��, 2: 2��  
            --4     �ݱ⳻ �� ����                ����  1     8         1/2/3/4/5/6  
            --5     ������(������)����ڵ�Ϲ�ȣ  ����  10    18  ��  
            --6     ����ڴ����������ι�ȣ        ����  7     25  
            --7     ��ȣ(���θ�)                  ����  60    85  ��  
            --8     ����(��ǥ��)                  ����  30    115 ��  
            --9     �ֹ�(����)��Ϲ�ȣ            ����  13    128 ��  
            --10    ��������                      ����  8     136 ��  
            --11    ������(������)��ȭ��ȣ        ����  12    148  
            --12    ����                          ����  252   400       SPACE  
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)  
                SELECT 'UH'                         -- ���ڵ屸��  
                    +  LEFT(@TaxFrDate,4)             -- �ͼӳ⵵  
                    +  @TermKind                   -- �ݱⱸ��  
                    +  @YearHalfMM                       -- �ݱ⳻ �� ����  
                    +  CONVERT(VARCHAR( 10), REPLACE(TaxNo, '-', '')   + SPACE( 10 - DATALENGTH(CONVERT(VARCHAR( 10), REPLACE(TaxNo, '-', '')  ))))  -- ������(������)����ڵ�Ϲ�ȣ  
                    +  CONVERT(VARCHAR(  7), @V166Cfm  + SPACE(  7 - DATALENGTH(CONVERT(VARCHAR(  7), @V166Cfm ))))  -- ����ڴ����������ι�ȣ  
                    +  CONVERT(VARCHAR( 60), TaxName   + SPACE( 60 - DATALENGTH(CONVERT(VARCHAR( 60), TaxName  ))))  -- ��ȣ(���θ�)  
                    +  CONVERT(VARCHAR( 30), Owner     + SPACE( 30 - DATALENGTH(CONVERT(VARCHAR( 30), Owner    ))))  -- ����(��ǥ��)  
                    +  CONVERT(VARCHAR( 13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','')   
                        + SPACE( 13 - DATALENGTH(CONVERT(VARCHAR( 13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','')  ))))  -- �ֹ�(����)��Ϲ�ȣ  
                    +  CONVERT(VARCHAR(  8), @CurrDate + SPACE(  8 - DATALENGTH(CONVERT(VARCHAR(  8), @CurrDate))))  -- ��������  
                    +  CONVERT(VARCHAR( 12), TelNo     + SPACE( 12 - DATALENGTH(CONVERT(VARCHAR( 12), TelNo    ))))  -- ������(������)��ȭ��ȣ  
                    +  space(252)                   -- ����  
                    ,  400                          -- ��������  
               FROM #TDATaxUnit WITH(NOLOCK)
              WHERE CompanySeq  = @CompanySeq  
                AND TaxUnit     = @TaxUnit  
  
            -- ����ڴ��������� ����庰�ΰ���ġ������ǥ�ع׳��μ���(ȯ�޼���)�Ű��(DATA RECORD)  
            --��ȣ  �׸�                          ����  ����  ��������  ���  
            --1     ���ڵ屸��                    ����  2     2         UD  
            --2     �ͼӳ⵵                      ����  4     6         YYYY��  
            --3     �ݱⱸ��                      ����  1     7         1: 1��, 2: 2��  
            --4     �ݱ⳻ �� ����                ����  1     8         1/2/3/4/5/6  
            --5     ������(������)����ڵ�Ϲ�ȣ  ����  10    18  ��  
            --6     ��������������ȣ            ����  4     22  
            --7     ��ȣ(���θ�)  ����  60    82  
            --8     ����������                  ����  70    152 ��  
            --9     ����������ݰ�꼭��ǥ        ����  15    167 ��  
            --10    ����������ݰ�꼭����        ����  15    182 ��  
            --11    ���������Ÿ��ǥ              ����  15    197  
            --12    ���������Ÿ����              ����  15    212 ��  
            --13    ���⿵�����ݰ�꼭��ǥ        ����  15    227 ��  
            --14    ���⿵����Ÿ��ǥ              ����  15    242  
            --15    ����ǥ��                      ����  15    257  
            --16    ���԰���ǥ��                  ����  15    272  
            --17    ���԰�������                  ����  15    287  
            --18    ��������ǥ��                  ����  15    302  
            --19    �����������Լ���              ����  15    317  
            --20    ���꼼                        ����  15    332  
            --21    ��������                      ����  15    347  
            --22    ���������Ҽ���                ����  15    362
            --23    ����������_���θ��ּ�       ���� 200    562
            --23    ����                          ����  38    600  
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)  
                SELECT 'UD'                         -- ���ڵ屸��  
                    +  LEFT(@TaxFrDate,4)             -- �ͼӳ⵵  
                    +  @TermKind                   -- �ݱⱸ��  
                    +  @YearHalfMM                       -- �ݱ⳻ �� ����  
                    +  CONVERT(VARCHAR( 10), @TaxNo   + SPACE( 10 - DATALENGTH(CONVERT(VARCHAR( 10), @TaxNo  ))))  -- ������(������)����ڵ�Ϲ�ȣ  
                    +  CASE WHEN A.TaxUnit = A.RptTaxUnit THEN  
                            '0000'  
                            ELSE CONVERT(VARCHAR(4), ISNULL(B.TaxNoSerl, LEFT(REPLACE(B.TaxNo, '-', ''), 4))   
                                + SPACE(4 - DATALENGTH(CONVERT(VARCHAR(4), ISNULL(B.TaxNoSerl, LEFT(REPLACE(B.TaxNo, '-', ''), 4))))) )  
                            END                                                                                          -- ��������������ȣ  
                    +  CONVERT(VARCHAR( 60), B.TaxName   + SPACE( 60 - DATALENGTH(CONVERT(VARCHAR( 60), B.TaxName  ))))  -- ��ȣ(���θ�)  
                    +  CONVERT(VARCHAR( 70), ( LTRIM(RTRIM(B.VATRptAddr)) ) + SPACE(70))        -- ����������
                    + dbo.fnVATIntChg(SUM(A.SaleSupplyAmt       ),15,0,1)  -- ������� ���ݰ�꼭��ǥ  
                    + dbo.fnVATIntChg(SUM(A.SaleVATAmt          ),15,0,1)  -- ������� ���ݰ�꼭����  
                    + dbo.fnVATIntChg(SUM(A.SaleEtcTaxAmt       ),15,0,1)  -- ������� ��Ÿ��ǥ  
                    + dbo.fnVATIntChg(SUM(A.SaleEtcTaxVATAmt    ),15,0,1)  -- �����Ÿ ����  
                    + dbo.fnVATIntChg(SUM(A.SaleZeroTaxAmt      ),15,0,1)  -- ���⿵�� ���ݰ�꼭��ǥ  
                    + dbo.fnVATIntChg(SUM(A.SaleZeroTaxEtcAmt   ),15,0,1)  -- ���⿵�� ��Ÿ��ǥ  
                    + dbo.fnVATIntChg(SUM(A.TaxationStd         ),15,0,1)  -- ����ǥ��  
                    + dbo.fnVATIntChg(SUM(A.BuySupplyAmt        ),15,0,1)  -- ���԰��� �ݾ�  
                    + dbo.fnVATIntChg(SUM(A.BuyVATAmt           ),15,0,1)  -- ���԰��� ����  
                    + dbo.fnVATIntChg(SUM(A.BuyEtcAmt           ),15,0,1)  -- �������� �ݾ�  
                    + dbo.fnVATIntChg(SUM(A.BuyEtcVATAmt        ),15,0,1)  -- �������� ����  
                    + dbo.fnVATIntChg(SUM(A.AddVATAmt           ),15,0,1)  -- ���꼼  
                    + dbo.fnVATIntChg(SUM(A.DeducVATAmt         ),15,0,1)  -- ��������  
                    + dbo.fnVATIntChg(SUM(A.DeBusVATAmt         ),15,0,1)  -- ���������� ����  
                    + space(200)                                      -- ����������_���θ��ּ� (�켱 ����ó��) : ������������ ���θ��ּ� �� �� �ϳ��� ����(�� �� ���� �� ����)
                    + space(38)                                       -- ����  
                    , 600                                             -- ��������  
                FROM _TTAXBizStdSumV166 AS A WITH(NOLOCK)
                                             JOIN #TDATaxUnit AS B WITH(NOLOCK)
                                               ON A.CompanySeq  = B.CompanySeq  
                                              AND A.TaxUnit     = B.TaxUnit  
               WHERE A.CompanySeq     = @CompanySeq  
                 AND A.TaxTermSeq     = @TaxTermSeq  
                 AND A.RptTaxUnit     = @TaxUnit  
               GROUP BY A.TaxUnit, A.RptTaxUnit, B.TaxNoSerl, B.TaxNo, B.TaxName, B.VATRptAddr
  
            ---- ����ڴ��������� ����庰�ΰ���ġ������ǥ�ع׳��μ���(ȯ�޼���)�Ű�� �հ�(TAIL RECORD)  
            --��ȣ �׸�                         ���� ���� �������� ���  
            --1     ���ڵ屸��                     ���� 2     2         UT  
            --2     �ͼӳ⵵                     ���� 4     6        YYYY����  
            --3     �ݱⱸ��                     ���� 1     7         1: 1��, 2: 2��  
            --4     �ݱ⳻ �� ����                 ���� 1     8         1/2/3/4/5/6  
            --5     ������(������)����ڵ�Ϲ�ȣ ���� 10     18 ��  
            --6     DATA �Ǽ�                     ���� 7     25    
            --7     ����������ݰ�꼭��ǥ�հ�     ���� 15     40    
            --8     ����������ݰ�꼭�����հ�     ���� 15     55    
            --9     ���������Ÿ��ǥ�հ�         ���� 15     70    
            --10 �����Ÿ�����հ�             ���� 15     85    
            --11 ���⿵�����ݰ�꼭��ǥ�հ�     ���� 15     100    
            --12 ���⿵����Ÿ��ǥ�հ�         ���� 15     115    
            --13 ����ǥ���հ�                 ���� 15     130    
            --14 ���԰����ݾ��հ�             ���� 15     145    
            --15 ���԰��������հ�             ���� 15     160    
            --16 ���������ݾ��հ�             ���� 15     175    
            --17 �������������հ�             ���� 15     190    
            --18 ���꼼�װ�                     ���� 15     205    
            --19 ���������հ�                 ���� 15     220    
            --20 ���������Ҽ����հ�             ���� 15     235    
            --21 ����                         ���� 165     400    
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)  
                SELECT 'UT'                         -- ���ڵ屸��  
                    +  LEFT(@TaxFrDate,4)           -- �ͼӳ⵵  
                    +  @TermKind                    -- �ݱⱸ��  
                    +  @YearHalfMM                  -- �ݱ⳻ �� ����  
                    +  CONVERT(VARCHAR( 10), @TaxNo   + SPACE( 10 - DATALENGTH(CONVERT(VARCHAR( 10), @TaxNo  ))))  -- ������(������)����ڵ�Ϲ�ȣ  
                    + dbo.fnVATIntChg(COUNT(*)                           , 7,0,1)  -- DATA�Ǽ�    
                    + dbo.fnVATIntChg(SUM(ISNULL(SaleSupplyAmt     ,0))  ,15,0,1)  -- ������� ���ݰ�꼭��ǥ�հ�  
                    + dbo.fnVATIntChg(SUM(ISNULL(SaleVATAmt        ,0))  ,15,0,1)  -- ������� ���ݰ�꼭�����հ�  
                    + dbo.fnVATIntChg(SUM(ISNULL(SaleEtcTaxAmt     ,0))  ,15,0,1)  -- ������� ��Ÿ��ǥ�հ�  
                    + dbo.fnVATIntChg(SUM(ISNULL(SaleEtcTaxVATAmt  ,0))  ,15,0,1)  -- �����Ÿ �����հ�  
                    + dbo.fnVATIntChg(SUM(ISNULL(SaleZeroTaxAmt    ,0))  ,15,0,1)  -- ���⿵�� ���ݰ�꼭��ǥ�հ�  
                    + dbo.fnVATIntChg(SUM(ISNULL(SaleZeroTaxEtcAmt ,0))  ,15,0,1)  -- ���⿵�� ��Ÿ��ǥ�հ�  
                    + dbo.fnVATIntChg(SUM(ISNULL(TaxationStd       ,0))  ,15,0,1)  -- ����ǥ�� �հ�  
                    + dbo.fnVATIntChg(SUM(ISNULL(BuySupplyAmt      ,0))  ,15,0,1)  -- ���԰��� �ݾ��հ�  
                    + dbo.fnVATIntChg(SUM(ISNULL(BuyVATAmt         ,0))  ,15,0,1)  -- ���԰��� �����հ�  
                    + dbo.fnVATIntChg(SUM(ISNULL(BuyEtcAmt         ,0))  ,15,0,1)  -- �������� �ݾ��հ�  
                    + dbo.fnVATIntChg(SUM(ISNULL(BuyEtcVATAmt      ,0))  ,15,0,1)  -- �������� �����հ�  
                    + dbo.fnVATIntChg(SUM(ISNULL(AddVATAmt         ,0))  ,15,0,1)  -- ���ΰŷ�(�ǸŸ���)�����  
                    + dbo.fnVATIntChg(SUM(ISNULL(DeducVATAmt       ,0))  ,15,0,1)  -- �������� �հ�  
                    + dbo.fnVATIntChg(SUM(ISNULL(DeBusVATAmt       ,0))  ,15,0,1)  -- ���������� �����հ�  
                    + SPACE(165)                            -- ����  
                    , 400                                   -- ��������  
                FROM _TTAXBizStdSumV166 AS A WITH(NOLOCK)
               WHERE CompanySeq     = @CompanySeq  
       AND TaxTermSeq     = @TaxTermSeq  
                 AND A.RptTaxUnit        = @TaxUnit  
        END  
        ELSE    -- ���ڽŰ�����   
        BEGIN  
            /***************************************************************************************************************************    
            ����ڴ��������ǻ���庰�ΰ���ġ������ǥ�ع׳��μ���(ȯ�޼���)�Ű����    
            01. �ڷᱸ��(2) : 17    
            02. �����ڵ�(7) : I103900 / V166
            03. ����ڴ����������ι�ȣ(7)    
            04. ����������ݰ�꼭��ǥ�հ�(15)    
            05. ����������ݰ�꼭�����հ�(15)    
            06. ���������Ÿ��ǥ�հ�(15)    
            07. ���������Ÿ�����հ�(15)    
            08. ���⿵�����ݰ�꼭��ǥ�հ�(15)    
            09. ���⿵����Ÿ��ǥ�հ�(15)    
            10. ����ǥ���հ�(15)    
            11. ���԰���ǥ���հ�(15)    
            12. ���԰��������հ�(15)    
            13. ��������ǥ���հ�(15)    
            14. �����������Լ����հ�(15)    
            15. ���꼼�հ�(15)    
            16. ���������հ�(15)    
            17. ���������Ҽ����հ�(15)    
            18. ����(174)    
            ****************************************************************************************************************************/    
            IF EXISTS (SELECT * FROM _TTAXBizStdSumV166 WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND RptTaxUnit = @TaxUnit)    
            BEGIN    
                INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                SELECT    '17'                  --01.�ڷᱸ��    
                        + 'I103900'             --02.�����ڵ�                        
                        + SPACE(7)              --03.����ڴ����������ι�ȣ(������)
                        + CASE WHEN Sum(Std.SaleSupplyAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.SaleSupplyAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.SaleSupplyAmt)))), 15), 1, 1, '-')    
                           END --04.����������ݰ�꼭��ǥ    
                        + CASE WHEN Sum(Std.SaleVATAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.SaleVATAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.SaleVATAmt)))), 15), 1, 1, '-')    
                           END --05.����������ݰ�꼭����    
                        + CASE WHEN Sum(Std.SaleEtcTaxAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.SaleEtcTaxAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.SaleEtcTaxAmt)))), 15), 1, 1, '-')    
                           END --06.���������Ÿ��ǥ    
                        + CASE WHEN Sum(Std.SaleEtcTaxVATAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.SaleEtcTaxVATAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.SaleEtcTaxVATAmt)))), 15), 1, 1, '-')    
                           END --07.���������Ÿ����    
                        + CASE WHEN Sum(Std.SaleZeroTaxAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.SaleZeroTaxAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.SaleZeroTaxAmt)))), 15), 1, 1, '-')    
                           END --08.���⿵�����ݰ�꼭��ǥ    
                        + CASE WHEN Sum(Std.SaleZeroTaxEtcAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.SaleZeroTaxEtcAmt))), 15)    
                           ELSE    
          STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.SaleZeroTaxEtcAmt)))), 15), 1, 1, '-')    
                           END --09.���⿵����Ÿ��ǥ    
                        + CASE WHEN Sum(Std.TaxationStd) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.TaxationStd))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.TaxationStd)))), 15), 1, 1, '-')    
                           END --10.����ǥ��    
                        + CASE WHEN Sum(Std.BuySupplyAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.BuySupplyAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.BuySupplyAmt)))), 15), 1, 1, '-')    
                           END --11.���԰���ǥ��    
                        + CASE WHEN Sum(Std.BuyVATAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.BuyVATAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.BuyVATAmt)))), 15), 1, 1, '-')    
                           END --12.���԰�������    
                        + CASE WHEN Sum(Std.BuyEtcAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.BuyEtcAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.BuyEtcAmt)))), 15), 1, 1, '-')    
                           END --13.��������ǥ��    
                        + CASE WHEN Sum(Std.BuyEtcVATAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.BuyEtcVATAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.BuyEtcVATAmt)))), 15), 1, 1, '-')    
                           END --14.�����������Լ���    
                        + CASE WHEN Sum(Std.AddVATAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.AddVATAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.AddVATAmt)))), 15), 1, 1, '-')    
                           END --15.���꼼    
                        + CASE WHEN Sum(Std.DeducVATAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.DeducVATAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.DeducVATAmt)))), 15), 1, 1, '-')    
                           END --16.��������    
                        + CASE WHEN Sum(Std.DeBusVATAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.DeBusVATAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.DeBusVATAmt)))), 15), 1, 1, '-')    
                           END --17.���������Ҽ���    
                        + SPACE(174)    -- 18.����    
                        , 400    
                    FROM _TTAXBizStdSumV166 AS Std  WITH(NOLOCK)
                   WHERE CompanySeq     = @CompanySeq  
                     AND TaxTermSeq     = @TaxTermSeq  
                     AND Std.RptTaxUnit = @TaxUnit  
            
                /***************************************************************************************************************************    
                ����ڴ��������ǻ���庰�ΰ���ġ������ǥ�ع׳��μ���(ȯ�޼���)�Ű����_��(���γ���)    
                01. �ڷᱸ��(2) : 18    
                02. �����ڵ�(7) : I103900 / V166
                03. ��������������ȣ(4)    
                04. ��ȣ(���θ�)(60)    
                05. ����������(70)    
                06. ����������ݰ�꼭��ǥ(15)    
                07. ����������ݰ�꼭����(15)    
                08. ���������Ÿ��ǥ(15)    
                09. ���������Ÿ����(15)    
                10. ���⿵�����ݰ�꼭��ǥ(15)    
                11. ���⿵����Ÿ��ǥ(15)    
                12. ����ǥ��(15)    
                13. ���԰���ǥ��(15)    
                14. ���԰�������(15)    
                15. ��������ǥ��(15)    
                16. �����������Լ���(15)    
                17. ���꼼(15)    
                18. ��������(15)    
                19. ���������Ҽ���(15)
                20. ����������_���θ��ּ�(200) 
                21. ����(47)    
                ****************************************************************************************************************************/    
  
                INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                SELECT    '18'                --01.�ڷᱸ��    
                        + 'I103900'          --02.�����ڵ�    
                        + RIGHT('0000' + LTRIM(RTRIM(( CASE ISNULL(Tax.SMTaxationType, 0) WHEN 4128002 THEN '0000' ELSE Tax.TaxNoSerl END ))),4)        --03.��������������ȣ    
                        + CONVERT(VARCHAR(60),LTRIM(RTRIM(CASE WHEN ISNULL(Tax.BillTaxName,'') <> '' THEN Tax.BillTaxName ELSE Tax.TaxName END)))    
                                  + SPACE(60 - DATALENGTH(CONVERT(VARCHAR(60), LTRIM(RTRIM(CASE WHEN ISNULL(Tax.BillTaxName,'') <> '' THEN Tax.BillTaxName ELSE Tax.TaxName END))))) --04.��ȣ(���θ�)    
                        + CONVERT(VARCHAR(70), RTRIM(ISNULL(Tax.Addr1,''))+' '+RTRIM(ISNULL(Tax.Addr2,''))) +    
                                SPACE(70 - DATALENGTH(CONVERT(VARCHAR(70), RTRIM(ISNULL(Tax.Addr1,''))+' '+RTRIM(ISNULL(Tax.Addr2,''))))) --05.����������    
                        + CASE WHEN Std.SaleSupplyAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.SaleSupplyAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.SaleSupplyAmt))), 15), 1, 1, '-')    
                           END --06.����������ݰ�꼭��ǥ    
                        + CASE WHEN Std.SaleVATAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.SaleVATAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.SaleVATAmt))), 15), 1, 1, '-')    
                           END --07.����������ݰ�꼭����    
                        + CASE WHEN Std.SaleEtcTaxAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.SaleEtcTaxAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.SaleEtcTaxAmt))), 15), 1, 1, '-')    
                           END --08.���������Ÿ��ǥ    
                        + CASE WHEN Std.SaleEtcTaxVATAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.SaleEtcTaxVATAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.SaleEtcTaxVATAmt))), 15), 1, 1, '-')    
                           END --09.���������Ÿ����    
                        + CASE WHEN Std.SaleZeroTaxAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.SaleZeroTaxAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.SaleZeroTaxAmt))), 15), 1, 1, '-')    
                           END --10.���⿵�����ݰ�꼭��ǥ    
                        + CASE WHEN Std.SaleZeroTaxEtcAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.SaleZeroTaxEtcAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.SaleZeroTaxEtcAmt))), 15), 1, 1, '-')    
                           END --11.���⿵����Ÿ��ǥ    
                        + CASE WHEN Std.TaxationStd >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.TaxationStd)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.TaxationStd))), 15), 1, 1, '-')    
                           END --12.����ǥ��    
                        + CASE WHEN Std.BuySupplyAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.BuySupplyAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.BuySupplyAmt))), 15), 1, 1, '-')    
                           END --13.���԰���ǥ��    
                        + CASE WHEN Std.BuyVATAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.BuyVATAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.BuyVATAmt))), 15), 1, 1, '-')    
                           END --14.���԰�������    
                        + CASE WHEN Std.BuyEtcAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.BuyEtcAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.BuyEtcAmt))), 15), 1, 1, '-')    
                           END --15.��������ǥ��    
                        + CASE WHEN Std.BuyEtcVATAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.BuyEtcVATAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.BuyEtcVATAmt))), 15), 1, 1, '-')    
                           END --16.�����������Լ���    
                        + CASE WHEN Std.AddVATAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.AddVATAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.AddVATAmt))), 15), 1, 1, '-')    
                           END --17.���꼼    
                        + CASE WHEN Std.DeducVATAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.DeducVATAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.DeducVATAmt))), 15), 1, 1, '-')    
                           END --18.��������    
                        + CASE WHEN Std.DeBusVATAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.DeBusVATAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.DeBusVATAmt))), 15), 1, 1, '-')    
                           END --19.���������Ҽ���    
                        + CONVERT(VARCHAR(200), ISNULL(Tax.RoadAddr,'')) + SPACE(200 - DATALENGTH(CONVERT(VARCHAR(200), ISNULL(Tax.RoadAddr,''))))                                   
                        + SPACE(47)    -- 20.����    
                        , 600    
                     FROM _TTAXBizStdSumV166 AS Std WITH(NOLOCK)
              JOIN #TDATaxUnit AS Tax WITH(NOLOCK)
                                                      ON Std.CompanySeq = Tax.CompanySeq  
                                                     AND Std.TaxUnit = Tax.TaxUnit  
                    WHERE Std.CompanySeq    = @CompanySeq  
                      AND Std.TaxTermSeq    = @TaxTermSeq  
                      AND Std.RptTaxUnit    = @TaxUnit  
                   
                      
            END    
        END  
    END    
END  

/***************************************************************************************************************************    
���ݸ������   
01. �ڷᱸ��            2
02. �����ڵ�            7
03. ���ݸ��������    2
04. �հ�Ǽ�            11
05. �հ�ݾ�            15
06. �Ǽ�_���ݰ�꼭     11
07. �ݾ�_���ݰ�꼭     15
08. �Ǽ�_�ſ�ī��       11
09. �ݾ�_�ſ�ī��       15
10. �Ǽ�_���ݿ�����     11
11. �ݾ�_���ݿ�����     15
12. �Ǽ�_���ݸ���       11
13. �ݾ�_���ݸ���       15
14. ���޴밡�հ�ݾ�    15
15. �ΰ����հ�ݾ�      15
16. ����                79
***************************************************************************************************************************  
���ݸ������_���γ���
01. �ڷᱸ��                        2  
02. �����ڵ�                        4  
03. �Ϸù�ȣ                        6  
04. �Ƿ����ֹ̹�ȣ �Ǵ� ����ڹ�ȣ  13 
05. �Ƿ��� ��ȣ �Ǵ� ����           30 
06. �ŷ�����                        8  
07. ���޴밡                        13 
08. ���ް���                        13 
09. �ΰ���                          13 
10. ����                            145
***************************************************************************************************************************/  
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT 1 FROM _TTAXBizStdSumV167 WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
     OR EXISTS (SELECT 1 FROM _TTAXBizStdSumV167M WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
    BEGIN
        DECLARE @CashSumCnt         INT,    
                @CashSumAmt         DECIMAL(19,5),
                @SumDomSumAmt       DECIMAL(19,5),
                @SumDomVatAmt       DECIMAL(19,5)
        SELECT @CashSumCnt      = COUNT(*)          ,
               @CashSumAmt      = SUM(DomAmt)       ,
               @SumDomSumAmt    = SUM(DomSumAmt)    ,
               @SumDomVatAmt    = SUM(DomVatAmt)
          FROM _TTAXBizStdSumV167 AS A WITH(NOLOCK)
         WHERE A.CompanySeq     = @CompanySeq
           AND A.TaxTermSeq     = @TaxTermSeq
           AND A.TaxUnit        = @TaxUnit
        IF ISNULL(@CashSumCnt   , 0) = 0 SELECT @CashSumCnt     = 0
        IF ISNULL(@CashSumAmt   , 0) = 0 SELECT @CashSumAmt     = 0
        IF ISNULL(@SumDomSumAmt , 0) = 0 SELECT @SumDomSumAmt   = 0
        IF ISNULL(@SumDomVatAmt , 0) = 0 SELECT @SumDomVatAmt   = 0
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
            SELECT '17'                                                     -- 01. �ڷᱸ��
                    + 'I103700'                                             -- 02. �����ڵ�
                    + SPACE(2)  -- 2016.07 ���������� ���� --dbo._FnVATCharChg(CONVERT(VARCHAR(2), ISNULL(@CashSaleKind, '')), 2, 1)   -- 03. ���ݸ��������
                    + dbo._FnVATIntChg(ISNULL(B.TaxBillCnt, 0) + ISNULL(B.CardCnt, 0) + ISNULL(B.CashBillCnt, 0) + ISNULL(@CashSumCnt, 0), 11, 0, 1)    -- 04. �հ�Ǽ�
                    + dbo._FnVATIntChg(ISNULL(B.TaxBillAmt, 0) + ISNULL(B.CardAmt, 0) + ISNULL(B.CashBillAmt, 0) + ISNULL(@CashSumAmt, 0), 15, 0, 1)    -- 05. �հ�ݾ�
                    + dbo._FnVATIntChg(ISNULL(B.TaxBillCnt, 0), 11, 0, 1)   -- 06. �Ǽ�_���ݰ�꼭
                    + dbo._FnVATIntChg(ISNULL(B.TaxBillAmt, 0), 15, 0, 1)   -- 07. �ݾ�_���ݰ�꼭
                    + dbo._FnVATIntChg(ISNULL(B.CardCnt   , 0), 11, 0, 1)   -- 08. �Ǽ�_�ſ�ī��
                    + dbo._FnVATIntChg(ISNULL(B.CardAmt   , 0), 15, 0, 1)   -- 09. �ݾ�_�ſ�ī��
                    + dbo._FnVATIntChg(ISNULL(B.CashBillCnt,0), 11, 0, 1)   -- 10. �Ǽ�_���ݿ�����
                    + dbo._FnVATIntChg(ISNULL(B.CashBillAmt,0), 15, 0, 1)   -- 11. �ݾ�_���ݿ�����
                    + dbo._FnVATIntChg(ISNULL(@CashSumCnt , 0), 11, 0, 1)   -- 12. �Ǽ�_���ݸ���
                    + dbo._FnVATIntChg(ISNULL(@CashSumAmt , 0), 15, 0, 1)   -- 13. �ݾ�_���ݸ���
                    + dbo._FnVATIntChg(ISNULL(@SumDomSumAmt,0), 15, 0, 1)   -- 14. ���޴밡�հ�ݾ�
                    + dbo._FnVATIntChg(ISNULL(@SumDomVatAmt,0), 15, 0, 1)   -- 15. �ΰ����հ�ݾ�
                    + SPACE(79)                                             -- 16. ����
                    , 250
               FROM _TTAXBizStdSumV167M AS B WITH(NOLOCK)
              WHERE B.CompanySeq = @CompanySeq
                AND B.TaxUnit    = @TaxUnit
                AND B.TaxTermSeq = @TaxTermSeq
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
            SELECT '18'                                                     -- 01. �ڷᱸ��
                    + 'I103700'                                             -- 02. �����ڵ�
                    + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY A.Serl)), 6)   -- 03. �Ϸù�ȣ
                    + dbo._FnVATCharChg(ISNULL(REPLACE(A.BizNo, '-', ''), ''), 13, 1)   -- 04. �Ƿ����ֹι�ȣ �Ǵ� ����ڹ�ȣ
                    + dbo._FnVATCharChg(CONVERT(VARCHAR(30), A.CustName), 30, 1)        -- 05. �Ƿ��� ��ȣ �Ǵ� ����
                    + dbo._FnVATCharChg(CONVERT(VARCHAR(8) , A.VatDate) ,  8, 1)        -- 06. �ŷ�����             
                    + dbo._FnVATIntChg(ISNULL(A.DomSumAmt   , 0), 13, 0, 1)             -- 07. ���޴밡             
                    + dbo._FnVATIntChg(ISNULL(A.DomAmt      , 0), 13, 0, 1)             -- 08. ���ް���             
                    + dbo._FnVATIntChg(ISNULL(A.DomVatAmt   , 0), 13, 0, 1)             -- 09. �ΰ���               
                    + SPACE(145)                                                        -- 10. ����                 
                    , 250
               FROM _TTAXBizStdSumV167 AS A WITH(NOLOCK)
              WHERE A.CompanySeq    = @CompanySeq
                AND A.TaxTermSeq    = @TaxTermSeq
                AND A.TaxUnit       = @TaxUnit
    END  
END  
/***************************************************************************************************************************    
�����ſ��� / ����Ȯ�μ� ���ڹ߱޸���(�հ�)
01. �ڷᱸ��                (02)
02. �����ڵ�                (07) I105600 / V174
03. �Ǽ�_�հ�               (07) 
04. �ش�ݾ�_�հ�           (15) 
05. �����ſ���_�Ǽ�_�հ�    (07) 
06. �����ſ���_�ݾ�_�հ�    (15) 
07. ����Ȯ�μ�_�Ǽ�_�հ�    (07) 
08. ����Ȯ�μ�_�ݾ�_�հ�    (15) 
09. ����                    (25)
*************************************************************************************************************************** 
�����ſ��� / ����Ȯ�μ� ���ڹ߱޸���(��)
01. �ڷᱸ��                (02)
02. �����ڵ�                (07) I105600 / V174
03. �Ϸù�ȣ                (06) 
04. ��������                (01) 
05. ������ȣ                (35) 
06. �߱�����                (08) 
07. ���޹޴��� ����ڹ�ȣ   (10) 
08. �ݾ�                    (15) 
09. ����                    (16) 
***************************************************************************************************************************/  
DECLARE @T_Cnt      INT,            @A_Cnt      INT,            @B_Cnt      INT,
        @T_CurAmt   DECIMAL(19,5),  @A_CurAmt   DECIMAL(19,5),  @B_CurAmt   DECIMAL(19,5),  
        @T_DomAmt   DECIMAL(19,5),  @A_DomAmt   DECIMAL(19,5),  @B_DomAmt   DECIMAL(19,5)
IF @WorkingTag IN ('','L')
BEGIN
    IF EXISTS (SELECT 1 FROM _TTAXPurCfm WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)
    BEGIN
        CREATE TABLE #PurCfm (
            Seq         INT IDENTITY,
            DocKind     NVARCHAR(1),
            DocNo       NVARCHAR(35),
            CfmDate     NVARCHAR(8),
            BizNo       NVARCHAR(10),
            Amt         DECIMAL(19,5))
        INSERT INTO #PurCfm (DocKind, DocNo, CfmDate, BizNo, Amt)
            SELECT CASE WHEN A.SMDocKind = 4534001 THEN 'L' 
                        WHEN A.SMDocKind = 4534002 THEN 'A' ELSE ' ' END    ,
                   A.DocNo                                                  ,
                   A.CfmDate                                                ,
                   REPLACE(B.BizNo, '-', '')                                , 
                   A.Amt                                                    
              FROM _TTAXPurCfm AS A WITH(NOLOCK)
                                    JOIN _TDACust AS B WITH(NOLOCK)
                                      ON A.CompanySeq   = B.CompanySeq
                                     AND A.CustSeq      = B.CustSeq
             WHERE A.CompanySeq     = @CompanySeq
               AND A.TaxTermSeq     = @TaxTermSeq
               AND A.TaxUnit        = @TaxUnit
               AND A.SMDocKind     <> 0
             ORDER BY A.SMDocKind, A.CfmDate, A.DocNo
        SELECT @T_Cnt           = COUNT(*),
               @T_CurAmt        = SUM(Amt)
          FROM #PurCfm
        SELECT @A_Cnt           = COUNT(*),
               @A_CurAmt        = SUM(Amt)
          FROM #PurCfm
         WHERE DocKind          = 'L'   -- �����ſ���(L)
        SELECT @B_Cnt           = COUNT(*),
               @B_CurAmt        = SUM(Amt)
          FROM #PurCfm
         WHERE DocKind          = 'A'   -- ����Ȯ�μ�(A)
         
        IF @WorkingTag  = 'L'   --���ϽŰ�(�����ſ���)
        BEGIN
            --=============================================================================    
            -- ������ ��������(HEAD RECORD)      
            --=============================================================================    
            --��ȣ  �׸�                        ����  ����  ��������  ���    
            --1   ���ڵ屸��                    ����  2     2         LH    
            --2   �ͼӳ⵵                      ����  4     6         YYYY��    
            --3   �ݱⱸ��                      ����  1     7         1: 1��, 2: 2��    
            --4   �ݱ⳻ �� ����                ����  1     8         1/2/3/4/5/6    
            --5   ������(������)����ڵ�Ϲ�ȣ  ����  10    18    
            --6   ��ȣ(���θ�)                  ����  60    78    
            --7   ����(��ǥ��)                  ����  30    108    
            --8   �ֹ�(����)��Ϲ�ȣ            ����  13    121    
            --9   ��������                      ����  8     129    
            --10  ������(������)��ȭ��ȣ        ����  12    141    
            --11  ����                          ����  59    200       SPACE  
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)      
                SELECT 'LH'                         -- ���ڵ屸��      
                    +  LEFT(@TaxFrDate, 4)          -- �ͼӳ⵵      
                    +  @TermKind                    -- �ݱⱸ��      
                    +  @YearHalfMM                  -- �ݱ⳻ �� ����      
                    + CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '') + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '') )))) -- ������(������)����ڵ�Ϲ�ȣ    
                    + CONVERT(VARCHAR(60), TaxName                 + SPACE(60 - DATALENGTH(CONVERT(VARCHAR(60), TaxName                 )))) -- ��ȣ(���θ�)    
                    + CONVERT(VARCHAR(30), Owner                   + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), Owner                   )))) -- ����(��ǥ��)        
                    + CONVERT(VARCHAR(13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','') 
                        + SPACE(13 - DATALENGTH(CONVERT(VARCHAR(13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','') )))) -- �ֹ�(����)��Ϲ�ȣ    
                    + CONVERT(VARCHAR( 8), @CurrDate               + SPACE( 8 - DATALENGTH(CONVERT(VARCHAR( 8), @CurrDate               )))) -- ��������    
                    + CONVERT(VARCHAR(12), TelNo                   + SPACE(12 - DATALENGTH(CONVERT(VARCHAR(12), TelNo                   )))) -- ������(������)��ȭ��ȣ    
+ SPACE(59)    -- ����    
                    , 200    
                FROM #TDATaxUnit WITH(NOLOCK)   
                WHERE CompanySeq  = @CompanySeq    
                  AND TaxUnit     = @TaxUnit  
            --=============================================================================    
            -- �����ſ��� / ����Ȯ�μ� ���ڹ߱޸���(DATA RECORD)      
            --=============================================================================    
            --��ȣ  �׸�                        ����  ����  ��������  ���    
            --1   ���ڵ屸��                    ����  2     2         LD    
            --2   �ͼӳ⵵                      ����  4     6         YYYY��    
            --3   �ݱⱸ��                      ����  1     7         1: 1��, 2: 2��    
            --4   �ݱ⳻ �� ����                ����  1     8         1/2/3/4/5/6    
            --5   ������(������)����ڵ�Ϲ�ȣ  ����  10    18    
            --6   ��������                      ����  1     19        SEQ    
            --7   �Ϸù�ȣ                      ����  6     25        SEQ    
            --8   ������ȣ                      ����  35    60          
            --9   �߱�����                      ����  8     68          
            --10  ���޹޴��ڻ���ڵ�Ϲ�ȣ      ����  10    78
            --11  �ݾ�                          ����  15    93                                
            --12  ����                          ����  107   200       SPACE 
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)      
                SELECT 'LD'                         -- 01.���ڵ屸��      
                    +  LEFT(@TaxFrDate, 4)          -- 02.�ͼӳ⵵      
                    +  @TermKind                    -- 03.�ݱⱸ��      
                    +  @YearHalfMM                  -- 04.�ݱ⳻ �� ����      
                    + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), @TaxNo),10,1)  -- 05.������(������)����ڵ�Ϲ�ȣ          
                    + dbo._FnVATCharChg(ISNULL(A.DocKind, ''), 1, 1)        -- 06. ��������
                    + RIGHT('000000' + CONVERT(VARCHAR(6), A.Seq), 6)       -- 07. �Ϸù�ȣ
                    + dbo._FnVATCharChg(ISNULL(A.DocNo, ''), 35, 1)         -- 08. ������ȣ
                    + dbo._FnVATCharChg(ISNULL(A.CfmDate, ''), 8, 1)        -- 09. �߱�����
                    + dbo._FnVATCharChg(ISNULL(A.BizNo, ''), 10, 1)         -- 10. ���޹޴��� ����ڹ�ȣ
                    + dbo._FnVATIntChg(ISNULL(A.Amt, 0), 15, 0, 1)          -- 11. �ݾ�
                    + SPACE(107)                                            -- 12. ����
                    , 200
               FROM #PurCfm AS A
              ORDER BY A.Seq
            --=============================================================================    
            -- �����ſ��� / ����Ȯ�μ� ���ڹ߱޸���(TAIL RECORD)      
            --=============================================================================    
            --��ȣ  �׸�                        ����  ����  ��������  ���    
            --1   ���ڵ屸��                    ����  2     2         LT    
            --2   �ͼӳ⵵                      ����  4     6         YYYY����    
            --3   �ݱⱸ��                      ����  1     7         1: 1��, 2: 2��    
            --4   �ݱ⳻ �� ����                ����  1     8         1/2/3/4/5/6    
            --5   ������(������)����ڵ�Ϲ�ȣ  ����  10    18    
            --6   DATA �Ǽ�                     ����  7     25  
            --7   �Ǽ�_�հ�                     ����  7     32  
            --8   �ش�ݾ�_�հ�                 ����  15    47
            --9   �����ſ���_�Ǽ�_�հ�          ����  7     54
            --10  �����ſ���_�ݾ�_�հ�          ����  15    69
            --11  ����Ȯ�μ�_�Ǽ�_�հ�          ����  7     76
            --12  ����Ȯ�μ�_�ݾ�_�հ�          ����  15    91 
            --13  ����                          ����  109   200   
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)      
                SELECT 'LT'                         -- 01.���ڵ屸��      
                    + LEFT(@TaxFrDate, 4)          -- 02.�ͼӳ⵵      
                    + @TermKind                    -- 03.�ݱⱸ��      
                    + @YearHalfMM                  -- 04.�ݱ⳻ �� ����      
                    + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), @TaxNo) ,10,1)    -- 05.������(������)����ڵ�Ϲ�ȣ   
                    + dbo._FnVATIntChg(COUNT(Seq) , 7,0,1)  -- 06.DATA�Ǽ�  
                    + dbo._FnVATIntChg(ISNULL(@T_Cnt        , 0),  7, 0, 1) -- 07. �Ǽ�_�հ�
                    + dbo._FnVATIntChg(ISNULL(@T_CurAmt     , 0), 15, 0, 1) -- 08. �ش�ݾ�_�հ�
                    + dbo._FnVATIntChg(ISNULL(@A_Cnt        , 0),  7, 0, 1) -- 09. �����ſ���_�Ǽ�_�հ�
                    + dbo._FnVATIntChg(ISNULL(@A_CurAmt     , 0), 15, 0, 1) -- 10. �����ſ���_�ݾ�_�հ�
                    + dbo._FnVATIntChg(ISNULL(@B_Cnt        , 0),  7, 0, 1) -- 11. ����Ȯ�μ�_�Ǽ�_�հ�
                    + dbo._FnVATIntChg(ISNULL(@B_CurAmt     , 0), 15, 0, 1) -- 12. ����Ȯ�μ�_�ݾ�_�հ�
                    + SPACE(109)                                            -- 13. ����
                    , 200
                FROM _TTAXPurCfm WITH(NOLOCK)
                WHERE CompanySeq = @CompanySeq 
                  AND TaxTermSeq = @TaxTermSeq
                  AND TaxUnit    = @TaxUnit  
           END
           ELSE     --���ڽŰ�(�����ſ���)
           BEGIN
                INSERT INTO #CREATEFile_tmp (tmp_file, tmp_size)
                    SELECT  '17'                                                    -- 01. �ڷᱸ��
                            + 'I105600'                                             -- 02. �����ڵ�
                            + dbo._FnVATIntChg(ISNULL(@T_Cnt        , 0),  7, 0, 1) -- 03. �Ǽ�_�հ�
                            + dbo._FnVATIntChg(ISNULL(@T_CurAmt     , 0), 15, 0, 1) -- 04. �ش�ݾ�_�հ�
                            + dbo._FnVATIntChg(ISNULL(@A_Cnt        , 0),  7, 0, 1) -- 05. �����ſ���_�Ǽ�_�հ�
                            + dbo._FnVATIntChg(ISNULL(@A_CurAmt     , 0), 15, 0, 1) -- 06. �����ſ���_�ݾ�_�հ�
                            + dbo._FnVATIntChg(ISNULL(@B_Cnt        , 0),  7, 0, 1) -- 07. ����Ȯ�μ�_�Ǽ�_�հ�
                            + dbo._FnVATIntChg(ISNULL(@B_CurAmt     , 0), 15, 0, 1) -- 08. ����Ȯ�μ�_�ݾ�_�հ�
                            + SPACE(25)                                             -- 09. ����
                            , 100
                INSERT INTO #CREATEFile_tmp (tmp_file, tmp_size)
                    SELECT  '18'                                                    -- 01. �ڷᱸ��
                            + 'I105600'                                             -- 02. �����ڵ�
                            + RIGHT('000000' + CONVERT(VARCHAR(6), A.Seq), 6)       -- 03. �Ϸù�ȣ
                            + dbo._FnVATCharChg(ISNULL(A.DocKind, ''),  1, 1)       -- 04. ��������
                            + dbo._FnVATCharChg(ISNULL(A.DocNo  , ''), 35, 1)       -- 05. ������ȣ
                            + dbo._FnVATCharChg(ISNULL(A.CfmDate, ''),  8, 1)       -- 06. �߱�����
                            + dbo._FnVATCharChg(ISNULL(A.BizNo  , ''), 10, 1)       -- 07. ���޹޴��� ����ڹ�ȣ
                            + dbo._FnVATIntChg(ISNULL(A.Amt, 0), 15, 0, 1)          -- 08. �ݾ�
                            + SPACE(16)                                             -- 09. ����
                            , 100
                       FROM #PurCfm AS A
                      ORDER BY A.Seq
        END
    END
END

/***************************************************************************************************************************        
÷�μ���30. �������������
 01. �ڷᱸ��
 02. �����ڵ�
 03. ��������(������� ����)  
 04. �߰蹫������Ź�Ǹš��ܱ��ε� �Ǵ� ��Ź�������� ����� ����  
 05. �����ſ��塤����Ȯ�μ��� ���Ͽ� �����ϴ� ��ȭ  
 06. �ѱ��������´� �� �ѱ����������Ƿ���ܿ� �����ϴ� �ؿܹ���� ��ȭ  
 07. ��Ź�������� ��������� �����ϴ� ��ȭ  
 08. ���ܿ��� �����ϴ� �뿪  
 09. ���ڡ��װ��⿡ ���� �ܱ�����뿪  
 10. �������տ�۰�࿡ ���� �ܱ�����뿪  
 11. �������� ������ڡ��ܱ����ο��� ���޵Ǵ� ��ȭ �Ǵ� �뿪  
 12. ������ȭ�Ӱ����뿪  
 13. �ܱ����� ���ڡ��װ��� � �����ϴ� ��ȭ �Ǵ� �뿪  
 14. ���� ���� �ܱ�����, ������, �������հ� �̿� ���ϴ� �����ⱸ, �������ձ� �Ǵ� �̱������� �����ϴ� ��ȭ �Ǵ� �뿪  
 15. ��������������� ���� �Ϲݿ������ �Ǵ� �ܱ������� �������ǰ �Ǹž��ڰ� �ܱ��ΰ��������� ����ϴ� �����˼��뿪 �Ǵ� �������ǰ  
 16. �ܱ��������Ǹ��� �Ǵ� ���ѿܱ����� ���� ���� �������������� �����ϴ� ��ȭ �Ǵ� �뿪  
 17. �ܱ��� ��� �����ϴ� ��ȭ �Ǵ� �뿪  
 18. �ܱ���ȯ�� ��ġ�뿪  
 19. ����������� �� ���δ� � �����ϴ� ������  
 20. ����ö���Ǽ��뿪  
 21. ������������ġ��ü�� �����ϴ� ��ȸ��ݽü� ��  
 22. ����ο� ���屸 �� ����ο� ������ű�� ��  
 23. �󡤾�� ��� �����ϴ� ����롤�����롤�Ӿ��� �Ǵ� ����������  
 24. �ܱ��ΰ����� ��� �����ϴ� ��ȭ  
 25. ����Ư����ġ�� �鼼ǰ�Ǹ��忡�� �Ǹ��ϰų� ����Ư����ġ�� �鼼ǰ�Ǹ��忡 �����ϴ� ��ǰ  
 26. �ΰ���ġ������ ���� ������ ���� ���޽���  
 27. ����Ư�����ѹ� �� �� ���� ������ ���� ������ ���� ���޽���  
 28. ������ ���� ���޽��� �� �հ�  
 29. ���δ���޼�����
 30. ��ο��԰����ϴ¾���������
 31. ����
***************************************************************************************************************************/    
IF @WorkingTag = ''      
BEGIN    
    IF EXISTS (SELECT 1 FROM _TTAXZeroSaleRpt WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)      
    BEGIN    
       INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)      
        SELECT '17'     
        + 'I104000'    
        + dbo._FnVATIntChg(ISNULL(ZeroSale03, 0), 15, 0, 1)  -- 03. ��������(������� ����)   
        + dbo._FnVATIntChg(ISNULL(ZeroSale04, 0), 15, 0, 1)  -- 04. �߰蹫������Ź�Ǹš��ܱ��ε� �Ǵ� ��Ź�������� ����� ����  
        + dbo._FnVATIntChg(ISNULL(ZeroSale05, 0), 15, 0, 1)  -- 05. �����ſ��塤����Ȯ�μ��� ���Ͽ� �����ϴ�  ��ȭ  
        + dbo._FnVATIntChg(ISNULL(ZeroSale06, 0), 15, 0, 1)  -- 06. �ѱ��������´� �� �ѱ����������Ƿ���ܿ� �����ϴ� �ؿܹ���� ��ȭ  
        + dbo._FnVATIntChg(ISNULL(ZeroSale07, 0), 15, 0, 1)  -- 07. ��Ź�������� ��������� �����ϴ� ��ȭ  
        + dbo._FnVATIntChg(ISNULL(ZeroSale08, 0), 15, 0, 1)  -- 08. ���ܿ��� �����ϴ� �뿪  
        + dbo._FnVATIntChg(ISNULL(ZeroSale09, 0), 15, 0, 1)  -- 09. ���ڡ��װ��⿡ ���� �ܱ�����뿪  
        + dbo._FnVATIntChg(ISNULL(ZeroSale10, 0), 15, 0, 1)  -- 10. �������տ�۰�࿡ ���� �ܱ�����뿪  
        + dbo._FnVATIntChg(ISNULL(ZeroSale11, 0), 15, 0, 1)  -- 11. �������� ������ڡ��ܱ����ο��� ���޵Ǵ� ��ȭ �Ǵ� �뿪  
        + dbo._FnVATIntChg(ISNULL(ZeroSale12, 0), 15, 0, 1)  -- 12. ������ȭ�Ӱ����뿪  
        + dbo._FnVATIntChg(ISNULL(ZeroSale13, 0), 15, 0, 1)  -- 13. �ܱ����� ���ڡ��װ��� � �����ϴ� ��ȭ �Ǵ� �뿪  
        + dbo._FnVATIntChg(ISNULL(ZeroSale14, 0), 15, 0, 1)  -- 14. ���� ���� �ܱ�����, ������, �������հ� �̿� ���ϴ� �����ⱸ, �������ձ� �Ǵ� �̱������� �����ϴ� ��ȭ �Ǵ� �뿪  
        + dbo._FnVATIntChg(ISNULL(ZeroSale15, 0), 15, 0, 1)  -- 15. ��������������� ���� �Ϲݿ������ �Ǵ� �ܱ������� �������ǰ �Ǹž��ڰ� �ܱ��ΰ��������� ����ϴ� �����˼��뿪 �Ǵ� �������ǰ  
        + dbo._FnVATIntChg(ISNULL(ZeroSale16, 0), 15, 0, 1)  -- 16. �ܱ��������Ǹ��� �Ǵ� ���ѿܱ����� ���� ���� �������������� �����ϴ� ��ȭ �Ǵ� �뿪  
        + dbo._FnVATIntChg(ISNULL(ZeroSale17, 0), 15, 0, 1)  -- 17. �ܱ��� ��� �����ϴ� ��ȭ �Ǵ� �뿪  
        + dbo._FnVATIntChg(ISNULL(ZeroSale18, 0), 15, 0, 1)  -- 18. �ܱ���ȯ�� ��ġ�뿪  
        + dbo._FnVATIntChg(ISNULL(ZeroSale19, 0), 15, 0, 1)  -- 19. �ΰ���ġ������ ���� ������ ���� ���޽���  
        + dbo._FnVATIntChg(ISNULL(ZeroSale20, 0), 15, 0, 1)  -- 20. ����ö���Ǽ��뿪  
        + dbo._FnVATIntChg(ISNULL(ZeroSale21, 0), 15, 0, 1)  -- 21. ������������ġ��ü�� �����ϴ� ��ȸ��ݽü� ��  
        + dbo._FnVATIntChg(ISNULL(ZeroSale22, 0), 15, 0, 1)  -- 22. ����ο� ���屸 �� ����ο� ������ű�� ��  
        + dbo._FnVATIntChg(ISNULL(ZeroSale23, 0), 15, 0, 1)  -- 23. �󡤾�� ��� �����ϴ� ����롤�����롤�Ӿ��� �Ǵ� ����������  
        + dbo._FnVATIntChg(ISNULL(ZeroSale24, 0), 15, 0, 1)  -- 24. �ܱ��ΰ����� ��� �����ϴ� ��ȭ  
        + dbo._FnVATIntChg(ISNULL(ZeroSale25, 0), 15, 0, 1)  -- 25. ����Ư����ġ�� �鼼ǰ�Ǹ��忡�� �Ǹ��ϰų� ����Ư����ġ�� �鼼ǰ�Ǹ��忡 �����ϴ� ��ǰ  
        + dbo._FnVATIntChg(ISNULL(ZeroSale26, 0), 15, 0, 1)  -- 26. ����������� �� ���δ� � �����ϴ� ������  
        + dbo._FnVATIntChg(ISNULL(ZeroSale27, 0), 15, 0, 1)  -- 27. ����Ư�����ѹ� �� �� ���� ������ ���� ������ ���� ���޽���  
        + dbo._FnVATIntChg(ISNULL(ZeroSale28, 0), 15, 0, 1)  -- 28. ������ ���� ���޽��� �� �հ�   
        + dbo._FnVATIntChg(ISNULL(ZeroSale29, 0), 15, 0, 1)  -- 29. ���δ���޼�����  
        + dbo._FnVATIntChg(ISNULL(ZeroSale30, 0), 15, 0, 1)  -- 30. ��ο��԰����ϴ¾���������
        + SPACE(21)                                          -- 31. ����    
        , 450    
        FROM _TTAXZeroSaleRpt WITH(NOLOCK)
       WHERE CompanySeq = @CompanySeq     
         AND TaxTermSeq = @TaxTermSeq     
         AND TaxUnit = @TaxUnit    
      
    END     
END    
    
/***************************************************************************************************************************        
   �ܱ��ΰ����� �鼼��ǰ �Ǹ� �� ȯ�޽�������    
***************************************************************************************************************************/    
 IF @WorkingTag = ''      
 BEGIN 
 
	DECLARE @SUMCnt INT,          
	        @SUMPurAmt INT,
	        @SUMVatAmt INT,
	        @SUMIndAmt INT,
	        @SUMEduAmt INT,
	        @SUMFarmAmt INT,
	        @PurPlaceNo NVARCHAR(100),
	        @TaxNoSerl  NVARCHAR(20)
	        
    CREATE TABLE #Temp_TourItem (  
        Cnt            INT IDENTITY,  
        PurPlaceNo     NVARCHAR(100))  
  
    INSERT INTO #Temp_TourItem (PurPlaceNo)  
        SELECT DISTINCT PurPlaceNo 
            FROM _TTAXTourItemReturn WITH(NOLOCK)  
            WHERE CompanySeq       = @CompanySeq  
            AND TaxTermSeq       = @TaxTermSeq  
            AND TaxUnit          = @TaxUnit 
	        
                    
	SELECT @Cnt = 1  
	SELECT @MaxCnt = COUNT(*) FROM #Temp_TourItem  
	WHILE  @Cnt <= @MaxCnt 			 
    BEGIN                
		SELECT @SUMCnt = COUNT(*), @SUMPurAmt = SUM(PurAmt), @SUMVatAmt = SUM(VatAmt), @SUMIndAmt =SUM(IndAmt), 
			   @SUMEduAmt = SUM(EduAmt), @SUMFarmAmt = SUM(FarmAmt), @PurPlaceNo = MAX(A.PurPlaceNo), @TaxNoSerl = MAX(TaxNoSerl)
		  FROM _TTAXTourItemReturn   AS A WITH(NOLOCK)
					           JOIN #Temp_TourItem AS B ON A.PurPlaceNo = B.PurPlaceNo AND Cnt = @Cnt
					LEFT OUTER JOIN #TDATaxUnit    AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.DTaxUnit = C.TaxUnit
		 WHERE A.CompanySeq = @CompanySeq
		   AND A.TaxTermSeq = @TaxTermSeq
		   AND A.TaxUnit = @TaxUnit
		   
	    IF ISNULL(@TaxNoSerl, '') = ''
	    BEGIN
			SELECT @TaxNoSerl = '0000'
	    END		   

		IF EXISTS (SELECT 1 FROM _TTAXTourItemReturn WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)      
		BEGIN    
			INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)      
			SELECT '17'     
			+ 'M202300'    
			+ dbo._FnVATCHARChg(CONVERT(VARCHAR(10), @TaxNoSerl ), 4, 1) -- 03. ��������Ϸù�ȣ 
			+ dbo._FnVATCHARChg(CONVERT(VARCHAR(10), @PurPlaceNo), 8, 1) -- 04. �鼼�Ǹ���������ȣ 
			+ dbo._FnVATIntChg(ISNULL(@SUMCnt    , 0), 11, 0, 1)  -- 05. �հ�_�Ǽ�
			+ dbo._FnVATIntChg(ISNULL(@SUMPurAmt , 0), 15, 0, 1)  -- 06. �հ�_�Ǹűݾ�
			+ dbo._FnVATIntChg(ISNULL(@SUMVatAmt , 0), 15, 0, 1)  -- 07. �հ�_�ΰ���ġ�� 
			+ dbo._FnVATIntChg(ISNULL(@SUMIndAmt , 0), 15, 0, 1)  -- 08. �հ�_�����Һ�
			+ dbo._FnVATIntChg(ISNULL(@SUMEduAmt , 0), 15, 0, 1)  -- 09. �հ�_������
			+ dbo._FnVATIntChg(ISNULL(@SUMFarmAmt, 0), 15, 0, 1)  -- 10. �հ�_�����Ư����
			+ SPACE(43)  -- 11. ����    
			, 150    
		 
			INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)      
			SELECT '18'     
			+ 'M202300'    
			+ dbo._FnVATCHARChg(CONVERT(VARCHAR(10), @TaxNoSerl), 4, 1)                                   -- 03. ��������Ϸù�ȣ
			+ RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY A.PurPlaceNo, A.Serl)), 4) -- 04. �Ϸù�ȣ 
			+ dbo._FnVATCHARChg(CONVERT(VARCHAR(20), PurSerl    ), 20, 1)   -- 05. �����Ϸù�ȣ
			+ dbo._FnVATCHARChg(CONVERT(VARCHAR(10), PurDate    ),  8, 1)   -- 06. �Ǹ�����
			+ dbo._FnVATCHARChg(CONVERT(VARCHAR(10), ReturnDate ),  8, 1)   -- 07. ��������
			+ dbo._FnVATCHARChg(CONVERT(VARCHAR(20), CASE WHEN ReturnNo = '0' THEN '00000000000000000000' ELSE ReturnNo END   ), 20, 1)   -- 08. ������ι�ȣ
			+ dbo._FnVATCHARChg(CONVERT(VARCHAR(10), GetAmtDate ),  8, 1)   -- 09. ȯ��(�۱�)����
			+ dbo._FnVATIntChg(ISNULL(GetAmt , 0), 15, 0, 1)  -- 10. ȯ�޾�
			+ dbo._FnVATIntChg(ISNULL(PurAmt , 0), 15, 0, 1)  -- 11. �հ�_�Ǹűݾ�
			+ dbo._FnVATIntChg(ISNULL(VatAmt , 0), 15, 0, 1)  -- 12. �հ�_�ΰ���ġ��
			+ dbo._FnVATIntChg(ISNULL(IndAmt , 0), 15, 0, 1)  -- 13. �հ�_�����Һ�
			+ dbo._FnVATIntChg(ISNULL(EduAmt , 0), 15, 0, 1)  -- 14. �հ�_������
			+ dbo._FnVATIntChg(ISNULL(FarmAmt, 0), 15, 0, 1)  -- 15. �հ�_�����Ư����
			+ SPACE(29)  -- 16. ����    
			, 200    
			FROM  _TTAXTourItemReturn AS A WITH(NOLOCK)
					JOIN #Temp_TourItem AS B ON A.PurPlaceNo = B.PurPlaceNo AND B.Cnt = @Cnt      
           WHERE CompanySeq = @CompanySeq     
			 AND TaxTermSeq = @TaxTermSeq     
			 AND TaxUnit = @TaxUnit		    
	      
		END
		SELECT @Cnt = @Cnt + 1
	END     
END      
  
/***************************************************************************************************************************    
������ũ���� ���Լ��װ����Ű�_�հ� (2014��1�⿹��)    
(01) �ڷᱸ��             CHAR    2
(02) �����ڵ�             CHAR    7  M125200 / V179
(03) ����ó��_�հ�        NUMBER  7
(04) �Ǽ�_�հ�            NUMBER 11
(05) ����_�հ�            NUMBER 11
(06) ���ݾ�_�հ�        NUMBER 15
(07) �������Լ���_�հ�    NUMBER 15
(08) ����ó��_������      NUMBER  6
(09) �Ǽ�_������          NUMBER 11
(10) ����_������          NUMBER 11
(11) ���ݾ�_������      NUMBER 15
(12) �������Լ���_������  NUMBER 15
(13) ����ó��_��꼭      NUMBER  6
(14) �Ǽ�_��꼭          NUMBER 11
(15) ����_��꼭          NUMBER 11
(16) ���ݾ�_��꼭      NUMBER 15
(17) �������Լ���_��꼭  NUMBER 15
(18) ����                 NUMBER 1
****************************************************************************************************************************/    
IF @WorkingTag = ''      
BEGIN
    IF EXISTS (SELECT 1 FROM _TTAXCuDeductScrap WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
    BEGIN  
        -- ���� ��ũ�� �� ���� �հ�  
        DECLARE @TotalCustCnt        INT,               @TotalCnt            INT,  
                @TotalQty            NUMERIC(19,5),     @TotalAmt            NUMERIC(19,5),     @TotalDeductAmt      NUMERIC(19,5),  
                @CustCnt1            INT,               @SumCnt1             INT,  
                @SumQty1             NUMERIC(19,5),     @SumAmt1             NUMERIC(19,5),     @SumDeductAmt1       NUMERIC(19,5),  
                @CustCnt2            INT,               @SumCnt2             INT,
                @SumQty2             NUMERIC(19,5),     @SumAmt2             NUMERIC(19,5),     @SumDeductAmt2       NUMERIC(19,5)  
                
        CREATE TABLE #tmp17V179(
            CustSeq             INT,
            SMCuDeductScrap     INT,
            SumCnt              INT,
            SumQty              INT,
            SUmAmt              DECIMAL(19,5),
            SumDeductAmt        DECIMAL(19,5)   )
            
            INSERT INTO #tmp17V179(CustSeq, SMCuDeductScrap, SumCnt, SumQty, SumAmt, SumDeductAmt)
            SELECT A.CustSeq, B.SMCuDeductScrap, SUM(Cnt) AS SumCnt, SUM(Qty) AS SumQty, SUM(Amt) AS SumAmt, SUM(DeductAmt) AS SumDeductAmt  
              FROM _TTAXCuDeductScrap AS A WITH(NOLOCK)
                        JOIN _TDAEvid AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                       AND A.EvidSeq    = B.EvidSeq  
                                                       AND ISNULL(B.SMCuDeductScrap,0) IN (4561001, 4561002)
             WHERE A.CompanySeq = @CompanySeq
               AND A.TaxTermSeq = @TaxTermSeq
               AND A.TaxUnit    = @TaxUnit
             GROUP BY A.TaxUnit, A.TaxTermSeq , A.CustSeq, B.SMCuDeductScrap  
      
            SELECT @TotalCustCnt   = ISNULL(COUNT( DISTINCT CustSeq ),0),  
                   @TotalCnt       = ISNULL(SUM(SumCnt),0),  
                   @TotalQty       = ISNULL(SUM(SumQty),0),  
                   @TotalAmt       = ISNULL(SUM(SumAmt),0),   
                   @TotalDeductAmt = ISNULL(SUM(SumDeductAmt),0)  
              FROM #tmp17V179  
                
            SELECT @CustCnt1      = ISNULL(COUNT( DISTINCT CustSeq ),0),  
                   @SumCnt1       = ISNULL(SUM(SumCnt),0),  
                   @SumQty1       = ISNULL(SUM(SumQty),0),  
                   @SumAmt1       = ISNULL(SUM(SumAmt),0),   
                   @SumDeductAmt1 = ISNULL(SUM(SumDeductAmt),0)  
              FROM #tmp17V179
             WHERE SMCuDeductScrap = 4561001    -- �����������
                
            SELECT @CustCnt2      = ISNULL(COUNT( DISTINCT CustSeq ),0),
                   @SumCnt2       = ISNULL(SUM(SumCnt),0),
                   @SumQty2       = ISNULL(SUM(SumQty),0),
                   @SumAmt2       = ISNULL(SUM(SumAmt),0),
                   @SumDeductAmt2 = ISNULL(SUM(SumDeductAmt),0)
              FROM #tmp17V179  
             WHERE SMCuDeductScrap = 4561002    -- ��꼭�����
               
               
          INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
             SELECT '17'            
                    +  'M125200'  
                    + dbo.FnVATIntChg(ISNULL(@TotalCustCnt,     0), 7, 0, 1) --(03) ����ó��_�հ�  
                    + dbo.FnVATIntChg(ISNULL(@TotalCnt,         0),11, 0, 1) --(04) �Ǽ�_�հ�             
                    + dbo.FnVATIntChg(ISNULL(@TotalQty,         0),11, 0, 1) --(05) ����_�հ�            
                    + dbo.FnVATIntChg(ISNULL(@TotalAmt,         0),15, 0, 1) --(06) ���ݾ�_�հ�         
                    + dbo.FnVATIntChg(ISNULL(@TotalDeductAmt,   0),15, 0, 1) --(07) �������Լ���_�հ�    
                    + dbo.FnVATIntChg(ISNULL(@CustCnt1,         0), 6, 0, 1) --(08) ����ó��_������      
                    + dbo.FnVATIntChg(ISNULL(@SumCnt1,          0),11, 0, 1) --(09) �Ǽ�_������          
                    + dbo.FnVATIntChg(ISNULL(@SumQty1,          0),11, 0, 1) --(10) ����_������           
                    + dbo.FnVATIntChg(ISNULL(@SumAmt1,          0),15, 0, 1) --(11) ���ݾ�_������       
                    + dbo.FnVATIntChg(ISNULL(@SumDeductAmt1,    0),15, 0, 1) --(12) �������Լ���_������  
                    + dbo.FnVATIntChg(ISNULL(@CustCnt2,         0), 6, 0, 1) --(13) ����ó��_��꼭       
                    + dbo.FnVATIntChg(ISNULL(@SumCnt2,          0),11, 0, 1) --(14) �Ǽ�_��꼭          
                    + dbo.FnVATIntChg(ISNULL(@SumQty2,          0),11, 0, 1) --(15) ����_��꼭           
                    + dbo.FnVATIntChg(ISNULL(@SumAmt2,          0),15, 0, 1) --(16) ���ݾ�_��꼭      
                    + dbo.FnVATIntChg(ISNULL(@SumDeductAmt2,    0),15, 0, 1) --(17) �������Լ���_��꼭   
                    + SPACE(16)                                              --(18) ����                  
                   , 200  

  
/***************************************************************************************************************************    
������ũ���� ���Լ��װ����Ű�_�� (2014��1�⿹��)    
(01) �ڷᱸ��                CHAR    2
(02) �����ڵ�                CHAR    7
(03) �Ϸù�ȣ                CHAR    6
(04) �����ڼ���_��ȣ         CHAR   60
(05) �������ֹ�(�����)��ȣ  CHAR   13
(06) �Ǽ�                    NUMBER 11
(07) ǰ��                    CHAR   30
(08) ����                    NUMBER 11
(09) ���ݾ�                NUMBER 13
(10) �������Լ���            NUMBER 13
(11) ����                    NUMBER 34
****************************************************************************************************************************/    
        CREATE TABLE #Tmp_TTAXCuDeductScrap  
        (  
            Serl        INT IDENTITY(1,1),  
            CustSeq     INT,
            Cnt         INT,   
            ItemSeq     INT,
            Qty         NUMERIC(19,5),  
            Amt         NUMERIC(19,5),  
            DeductAmt   NUMERIC(19,5)
        )  
          
        INSERT INTO #Tmp_TTAXCuDeductScrap (CustSeq, Cnt, ItemSeq, Qty, Amt, DeductAmt)  
        SELECT A.CustSeq, SUM(Cnt) AS Cnt, A.ItemSeq, SUM(Qty) AS Qty, SUM(Amt) AS Amt, SUM(DeductAmt) AS DeductAmt  
          FROM _TTAXCuDeductScrap AS A WITH(NOLOCK)
                        JOIN _TDAEvid AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                       AND A.EvidSeq    = B.EvidSeq  
                                                       AND ISNULL(B.SMCuDeductScrap,0) = 4561001 --  ������ 
         WHERE A.CompanySeq = @CompanySeq
           AND A.TaxTermSeq = @TaxTermSeq
           AND A.TaxUnit    = @TaxUnit
         GROUP BY A.CustSeq, A.ItemSeq  
         ORDER BY CustSeq, ItemSeq  
      
      
   
          INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
             SELECT '18'            
                    +  'M125200'  
                    + dbo.FnVATIntChg(ISNULL(Serl,       0), 6, 0, 1)           -- (03) �Ϸù�ȣ   
                    + dbo.FnVATCHARChg(CONVERT(VARCHAR(60), C.CustName), 60, 1) -- (04) �����ڼ���_��ȣ  
                    + CASE WHEN ISNULL(C.BizNo, '') = '' 
                           THEN LTRIM(RTRIM(dbo._FCOMDecrypt(C.PersonId, '_TDACust', 'PersonId', @CompanySeq)))   
                                + SPACE(13 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(13),dbo._FCOMDecrypt(C.PersonId, '_TDACust', 'PersonId', @CompanySeq))))))  
                           ELSE LTRIM(RTRIM(C.BizNo)) + SPACE(13 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(13),C.BizNo)))))  
                      END                                                       -- (05) �������ֹ�(�����)��ȣ  
                    + dbo.FnVATIntChg(ISNULL(Cnt,       0), 11, 0, 1)           -- (06) �Ǽ�  
                    + dbo.FnVATCHARChg(CONVERT(VARCHAR(30), I.ItemName), 30, 1) -- (07) ǰ��       
                    + dbo.FnVATIntChg(ISNULL(Qty,       0), 11, 0, 1)           -- (08) ����   
                    + dbo.FnVATIntChg(ISNULL(Amt,       0), 13, 0, 1)           -- (09) ���ݾ�  
                    + dbo.FnVATIntChg(ISNULL(DeductAmt, 0), 13, 0, 1)           -- (10) �������Լ���  
                    + SPACE(34)  
                    , 200  
              FROM #Tmp_TTAXCuDeductScrap AS A WITH (NOLOCK)  
                        JOIN _TDACust AS C WITH (NOLOCK) ON A.CustSeq = C.CustSeq AND C.CompanySeq = @CompanySeq
                        JOIN _TDAItem AS I WITH (NOLOCK) ON A.ItemSeq = I.ItemSeq AND I.CompanySeq = @CompanySeq
             ORDER BY Serl  
      
    END
END

/***************************************************************************************************************************    
÷�μ���38. ��ȭȹ�����
-- ��ȭȹ����� �հ�
01. �ڷᱸ��                (2)  : 17
02. �����ڵ�                (7)  : I402100
03. ����������ٰ�          (30)
04. �������⼭����          (50)
05. ������������Ҵɻ���    (50)
06. �����������Ⱑ������    (8)
07. ����                    (53)
-- ��ȭȹ����� ��
01. �ڷᱸ��                (2)  : 18
02. �����ڵ�                (7)  : I402100
03. �Ϸù�ȣ                (6)
04. ��������                (8)
05. ���޹޴���_��ȣ(����)   (30)
06. ���޹޴���_�����ڵ�     (2)
07. ���޳���_����           (2)
08. ���޳���_��Ī           (30)
09. ���޳���_�ݾ�(��ȭ)     (13)
10. �ݾ�(��ȭ)              (15,2)
11. ����                    (35)
***************************************************************************************************************************/
IF @WorkingTag = ''      
BEGIN
    IF EXISTS(SELECT 1 FROM _TTaxForAmtReceiptList WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND SMComboKind <> 4116003)
    BEGIN
        
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)
        SELECT TOP 1 '17'                                 -- 01. �ڷᱸ��
             + 'I402100'                            -- 02. �����ڵ�
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(30), ISNULL(Basis  ,''))   , 30, 1)   -- 03. ����������ٰ�
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(50), ISNULL(Doc    ,''))   , 50, 1)   -- 04. ���⼭����
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(50), ISNULL(Reason ,''))   , 50, 1)   -- 05. ������������Ҵɻ���
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(8) , ISNULL(IsAble ,''))   ,  8, 1)   -- 06. �����������Ⱑ������
             + SPACE(53)
             , 200
          FROM _TTaxForAmtReceiptList AS A WITH(NOLOCK)
         WHERE A.CompanySeq = @CompanySeq
           AND A.TaxTermSeq = @TaxTermSeq
           AND A.TaxUnit    = @TaxUnit
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)
        SELECT '18'                                                                             -- 01. �ڷᱸ��
             + 'I402100'                                                                        -- 02. �����ڵ�
             + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY VATDate)) , 6)  -- 03. �Ϸù�ȣ
             + CONVERT(VARCHAR(8), VATDate)                                                     -- 04. ��������
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(30), ISNULL(A.CustName     ,'')), 30, 1)       -- 05. ���޹޴���_��ȣ(����)
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(02), ISNULL(C.ValueText    ,'')),  2, 1)       -- 06. ���޹޴���_�����ڵ�
             + CASE SMComboKind WHEN 4116001 THEN '01'  -- ��ȭ
                                WHEN 4116002 THEN '02'  -- �뿪
                                ELSE SPACE(2) END                                               -- 07. ���޳���_����
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(30), ISNULL(ItemName       ,'')), 30, 1)       -- 08. ���޳���_��Ī
             + dbo._FnVATIntChg(SupplyAmt    , 13, 0, 1)                                        -- 09. ���޳���_�ݾ�(��ȭ)
             + dbo._FnVATIntChg(ForSupplyAmt , 15, 2, 1)                                        -- 10. ���޳���_�ݾ�(��ȭ)
             + SPACE(35)
             , 150
        FROM _TTaxForAmtReceiptList AS A WITH(NOLOCK)
                LEFT OUTER JOIN _TDAUMinor      AS B WITH(NOLOCK) ON A.CompanySeq  = B.CompanySeq
                                                                 AND A.UMNationSeq = B.MinorSeq
                                                                 AND B.MajorSeq    = 1002       -- ����
                LEFT OUTER JOIN _TDAUMinorValue AS C WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq
                                                                 AND B.MinorSeq   = C.MinorSeq
                                                                 AND C.MajorSeq   = 1002
                                                                 AND C.Serl       = 2011        -- ISO�����ڵ�-2
        WHERE A.CompanySeq = @CompanySeq
          AND A.TaxTermSeq = @TaxTermSeq
          AND A.TaxUnit    = @TaxUnit
          AND A.SMComboKind <> 4116003
    END
END
/***************************************************************************************************************************        
÷�μ��� 41. �ܱ��ΰ��������ȯ�޹�ǰ�ǸŽ�������
-- �ܱ��ΰ��������ȯ�޹�ǰ�ǸŽ������� �հ�
01. �ڷᱸ��                (2)  : 17
02. �����ڵ�                (7)  : I106900
03. ��������Ϸù�ȣ          (4)
04. �鼼�Ǹ���������ȣ        (8)
05. �հ�_�Ǽ�               (11)
06. �հ�_���������ǸŰ���      (15)
07. �հ�_�ΰ���ġ��           (15)
08. �հ�_���ȯ�޻���        (15)
09. ȯ��â�������ڵ�Ϲ�ȣ  (10)
10. ����                    (63)

-- �ܱ��ΰ��������ȯ�޹�ǰ�ǸŽ������� ��
01. �ڷᱸ��                (2)  : 18
02. �����ڵ�                (7)  : I106900
03. ��������Ϸù�ȣ          (4)
04. �Ϸù�ȣ                (4)
05. �����Ϸù�ȣ             (20)
06. �Ǹ�����                (8)
07. ������ι�ȣ             (20)
08. ���������ǸŰ���          (15)
09. �ΰ���ġ��               (15)
10. ���ȯ�޻���            (15)
11. �����ڼ���               (30)
12. �����ڱ���               (50)
13. ����                    (10)
***************************************************************************************************************************/    
 IF @WorkingTag = ''      
 BEGIN 
    IF EXISTS (SELECT 1 FROM _TTAXTourItemReturnImme WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)      
    BEGIN
	    DECLARE @SUMImmeCnt     INT,          
	            @SUMSalesAmt    INT,
	            @SUMImmeVatAmt  INT,
	            @SUMImmeAmt     INT,
	            @ImmePurPlaceNo NVARCHAR(100),
                @ImmeTaxUnitNo  NVARCHAR(100),
	            @ImmeTaxNoSerl  NVARCHAR(20)
	            
        CREATE TABLE #Temp_ReturnImme (  
            Cnt            INT IDENTITY,  
            PurPlaceNo     NVARCHAR(100))  
  
        INSERT INTO #Temp_ReturnImme (PurPlaceNo)  
        SELECT DISTINCT PurPlaceNo 
          FROM _TTAXTourItemReturnImme WITH(NOLOCK)  
         WHERE CompanySeq       = @CompanySeq  
           AND TaxTermSeq       = @TaxTermSeq  
           AND TaxUnit          = @TaxUnit 
	            
              
	    SELECT @Cnt = 1  
	    SELECT @MaxCnt = COUNT(*) FROM #Temp_ReturnImme  
	    WHILE  @Cnt <= @MaxCnt 			 
        BEGIN                
	    	SELECT @SUMImmeCnt = COUNT(*), @SUMSalesAmt = SUM(SalesAmt), @SUMImmeVatAmt = SUM(VatAmt), @SUMImmeAmt =SUM(ImmeAmt), 
	    		   @ImmePurPlaceNo = MAX(A.PurPlaceNo), @ImmeTaxUnitNo = MAX(A.ImmeTaxUnitNo), @ImmeTaxNoSerl = MAX(TaxNoSerl)
	    	  FROM _TTAXTourItemReturnImme   AS A WITH(NOLOCK)
	    				           JOIN #Temp_ReturnImme    AS B ON A.PurPlaceNo = B.PurPlaceNo AND Cnt = @Cnt
	    				LEFT OUTER JOIN #TDATaxUnit         AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.DTaxUnit = C.TaxUnit
	    	 WHERE A.CompanySeq = @CompanySeq
	    	   AND A.TaxTermSeq = @TaxTermSeq
	    	   AND A.TaxUnit = @TaxUnit
	    	   
	        IF ISNULL(@TaxNoSerl, '') = ''
	        BEGIN
	    		SELECT @TaxNoSerl = '0000'
	        END		   
	    	 
	    		INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)      
	    		SELECT '17'     
	    		+ 'I106900'    
	    		+ dbo._FnVATCHARChg(CONVERT(VARCHAR(4), @ImmeTaxNoSerl ), 4, 1) -- 03. ��������Ϸù�ȣ 
	    		+ dbo._FnVATCHARChg(CONVERT(VARCHAR(8), @ImmePurPlaceNo), 8, 1) -- 04. �鼼�Ǹ���������ȣ 
	    		+ dbo._FnVATIntChg(ISNULL(@SUMImmeCnt   , 0), 11, 0, 1)  -- 05. �հ�_�Ǽ�
	    		+ dbo._FnVATIntChg(ISNULL(@SUMSalesAmt  , 0), 15, 0, 1)  -- 06. �հ�_���������ǸŰ���
	    		+ dbo._FnVATIntChg(ISNULL(@SUMImmeVatAmt, 0), 15, 0, 1)  -- 07. �հ�_�ΰ���ġ��
	    		+ dbo._FnVATIntChg(ISNULL(@SUMImmeAmt   , 0), 15, 0, 1)  -- 08. �հ�_���ȯ�޻���
                + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), @ImmeTaxUnitNo), 10, 1) -- 09. ȯ��â�������ڵ�Ϲ�ȣ
	    		+ SPACE(63)  -- 11. ����    
	    		, 150    

	    		INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)      
	    		SELECT '18'     
	    		+ 'I106900'    
	    		+ dbo._FnVATCHARChg(CONVERT(VARCHAR(4), @ImmeTaxNoSerl), 4, 1)                                   -- 03. ��������Ϸù�ȣ
	    		+ RIGHT('000000' + CONVERT(VARCHAR(4), ROW_NUMBER() OVER (ORDER BY A.PurPlaceNo, A.Serl)), 4) -- 04. �Ϸù�ȣ 
	    		+ dbo._FnVATCHARChg(CONVERT(VARCHAR(20), PurSerl    ), 20, 1)   -- 05. �����Ϸù�ȣ
	    		+ dbo._FnVATCHARChg(CONVERT(VARCHAR(8), SalesDate  ),  8, 1)   -- 06. �Ǹ�����
	    		+ dbo._FnVATCHARChg(CONVERT(VARCHAR(20), CASE WHEN ReturnNo = '0' THEN '00000000000000000000' ELSE ReturnNo END   ), 20, 1)   -- 07. ������ι�ȣ
	    		+ dbo._FnVATIntChg(ISNULL(SalesAMt, 0), 15, 0, 1)  -- 08. ���������ǸŰ���
	    		+ dbo._FnVATIntChg(ISNULL(VatAmt  , 0), 15, 0, 1)  -- 09. �ΰ���ġ��
	    		+ dbo._FnVATIntChg(ISNULL(ImmeAmt , 0), 15, 0, 1)  -- 10. ���ȯ�޻���
	    		+ dbo._FnVATCHARChg(CONVERT(VARCHAR(30), BuyName    ), 30, 1)   -- 11. �����ڼ���
	    		+ dbo._FnVATCHARChg(CONVERT(VARCHAR(50), BuyNation  ), 50, 1)   -- 12. �����ڱ���
                + SPACE(10)  -- 13. ����    
	    		, 200    
	    		FROM  _TTAXTourItemReturnImme AS A WITH(NOLOCK)
	    				JOIN #Temp_ReturnImme AS B ON A.PurPlaceNo = B.PurPlaceNo AND B.Cnt = @Cnt      
               WHERE CompanySeq = @CompanySeq     
	    		 AND TaxTermSeq = @TaxTermSeq     
	    		 AND TaxUnit = @TaxUnit		    
	          
	    	
	    	  SELECT @Cnt = @Cnt + 1
        END
	END     
END  
/***************************************************************************************************************************        
÷�μ��� 33. ����ȯ�ޱݵ� ����
01. �ڷᱸ��                (2)  : 17
02. �����ڵ�                (7)  : I401500
03. �Ϸù�ȣ                (6)  : ���������� �ο�
04. ��������                (8)
05. ����ȯ�ޱݾ�            (13)
06. ��ȣ(���θ�)            (30)
07. ����ڵ�Ϲ�ȣ          (10)
08. �����ſ����ȣ          (30)
09. ����                    (44)
***************************************************************************************************************************/    
 IF @WorkingTag = ''      
 BEGIN 
    IF EXISTS(SELECT * FROM _TTAXCustomsRefund WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)
    BEGIN
        INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)  
        SELECT '17'                 -- 01. �ڷᱸ��     
             + 'I401500'            -- 02. �����ڵ�  
             + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY A.Serl)), 6)    -- 03. �Ϸù�ȣ
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(8),  ISNULL(A.SupplyDate   , '')),  8, 1)      -- 04. ��������
             + dbo._FnVATIntChg(ISNULL(A.RefundAmt, 0), 13, 0, 1)                               -- 05. ����ȯ�ޱݾ�
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(30), ISNULL(C.CustName     , '')), 30, 1)      -- 06. ��ȣ(���θ�)
             + dbo._FnVATCharChg(CONVERT(VARCHAR(10), ISNULL(C.BizNo        , '')), 10, 1)      -- 07. ����ڵ�Ϲ�ȣ
             + dbo._FnVATCharChg(CONVERT(VARCHAR(30), ISNULL(A.DomesticLCNo , '')), 30, 1)      -- 08. �����ſ����ȣ
             + SPACE(44)            -- 07. ����
             , 150 
        FROM _TTAXCustomsRefund     AS A WITH(NOLOCK)
                    JOIN _TDACust   AS C WITH (NOLOCK) ON A.CustSeq = C.CustSeq AND C.CompanySeq = @CompanySeq
       WHERE A.CompanySeq = @CompanySeq 
         AND A.TaxTermSeq = @TaxTermSeq 
         AND A.TaxUnit    = @TaxUnit
    END
END  
  
/***************************************************************************************************************************  
���ݰ�꼭 �հ�ǥ - ǥ��(Head Record)  
  
01. �ڷᱸ��(1) : 7  
02. �����ڵ�Ϲ�ȣ(10)  
03. �����ڻ�ȣ(30)  
04. �����ڼ���(15)  
05. �����ڻ���������(45)  
06. �����ھ���(17) : �����׸����� SPACE�� �Է�  
07. ����������(25) : �����׸����� SPACE�� �Է�  
08. �ŷ��Ⱓ(12) : �Ű�Ⱓ�� ù���� �������� ����(040501040731)  
09. �ۼ�����(6) : �ŷ��Ⱓ�� ������ �κа� ����(040731)  
10. ����(9)  
****************************************************************************************************************************/  
IF @WorkingTag IN ('', 'K')  
BEGIN  
    IF EXISTS (SELECT * FROM _TTAXTaxBillSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)
      OR (@IsESERO = '1')
    BEGIN  
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
             SELECT '7'                        --01. �ڷᱸ��  
                   + dbo._FnVATCHARChg(CONVERT(VARCHAR(10),REPLACE(TaxNo,'-','')),10,1)         --02. �����ڵ�Ϲ�ȣ  
                   + CASE WHEN ISNULL(BillTaxName,'') <> '' 
                          THEN dbo._FnVATCHARChg(CONVERT(VARCHAR(30),BillTaxName),30,1)  
                          ELSE dbo._FnVATCHARChg(CONVERT(VARCHAR(30),TaxName),30,1) END --03. �����ڻ�ȣ  
                   + dbo._FnVATCHARChg(CONVERT(VARCHAR(15),Owner)       ,15,1)          --04. �����ڼ���  
                   + dbo._FnVATCHARChg(CONVERT(VARCHAR(45),VATRptAddr ) ,45,1)          --05. ����������  
                   + SPACE(17)                                      --06. �����ھ���  
                   + SPACE(25)                                      --07. ����������  
                   + RIGHT(@TaxFrDate, 6) + RIGHT(@TaxToDate, 6)    --08. �ŷ��Ⱓ  
                   + RIGHT(@TaxToDate, 6)                           --09. �ۼ�����  
                   + SPACE(9)  
                   , 170  
              FROM #TDATaxUnit WITH(NOLOCK)
             WHERE CompanySeq = @CompanySeq  
               AND TaxUnit    = @TaxUnit   
  
                --�ƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢ�
                ------------------------------------------------------------------------------------------------------------------------------------------
                -- ���ݰ�꼭 ��� �� ��ȸ ������ �����ϰ� ���� TempTable�� ���� �� TempTable���� ��� ���� 2010.10.22 by bgKeum
                ------------------------------------------------------------------------------------------------------------------------------------------
                --�ƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢ�
                CREATE TABLE #TTAXTaxBillSum (
                    CompanySeq          INT,
                    TaxTermSeq          INT,
                    TaxUnit             INT,
                    SMBuyOrSale INT,
                    BizNo               NVARCHAR(200),
                    PersonId            NVARCHAR(200),
                    CustName            NVARCHAR(100),
                    BizKind             NVARCHAR(60),
                    BizType             NVARCHAR(60),
                    BillCnt             INT,
                    SupplyAmt           DECIMAL(19,5),
                    VATAmt              DECIMAL(19,5),
                    IsEBill             NCHAR(1),
                    IsDelayBill         NCHAR(1))
                CREATE TABLE #TTAXTaxBillSum2 (
                    CompanySeq          INT,
                    TaxTermSeq          INT,
                    TaxUnit             INT,
                    SMBuyOrSale         INT,
                    BizNo               NVARCHAR(200),
                    PersonId            NVARCHAR(200),
                    CustName            NVARCHAR(100),
                    BizKind             NVARCHAR(60),
                    BizType             NVARCHAR(60),
                    BillCnt             INT,
                    SupplyAmt           DECIMAL(19,5),
                    VATAmt              DECIMAL(19,5),
                    IsEBill             NCHAR(1),
                    IsDelayBill         NCHAR(1))
                INSERT INTO #TTAXTaxBillSum (CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, BizKind, BizType, BillCnt, SupplyAmt, VATAmt, IsEBill, IsDelayBill)
                    SELECT A.CompanySeq, A.TaxTermSeq, A.TaxUnit, A.SMBuyOrSale, REPLACE(ISNULL(B.BizNo,''), '-', ''), 
                           CASE WHEN ISNULL(B.BizNo, '') = '' THEN ISNULL(dbo._FCOMDecrypt(B.PersonId, '_TDACust', 'PersonId', @CompanySeq),'') ELSE '' END, '' AS CustName, '' AS BizKind, '' AS BizType,
                           SUM(A.BillCnt), SUM(A.SupplyAmt), SUM(A.VATAmt), A.IsEBill, ISNULL(A.IsDelayBill, '')
                      FROM _TTAXTaxBillSum AS A WITH(NOLOCK)
                                                JOIN _TDACust AS B WITH(NOLOCK)
                                                  ON A.CompanySeq   = B.CompanySeq
                                                 AND A.CustSeq      = B.CustSeq
                     WHERE A.CompanySeq     = @CompanySeq
                       AND A.TaxTermSeq     = @TaxTermSeq
                       AND A.TaxUnit        = @TaxUnit
                       AND A.CustSerl       = 0 ---------------------------------------- Hist������ ���� �ŷ�ó��
                     GROUP BY A.CompanySeq, A.TaxTermSeq, A.TaxUnit, A.SMBuyOrSale, REPLACE(ISNULL(B.BizNo,''), '-', ''), 
                              CASE WHEN ISNULL(B.BizNo, '') = '' THEN ISNULL(dbo._FCOMDecrypt(B.PersonId, '_TDACust', 'PersonId', @CompanySeq),'') ELSE '' END, A.IsEBill, A.IsDelayBill
                INSERT INTO #TTAXTaxBillSum (CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, BizKind, BizType, BillCnt, SupplyAmt, VATAmt, IsEBill, IsDelayBill)
                    SELECT A.CompanySeq, A.TaxTermSeq, A.TaxUnit, A.SMBuyOrSale, REPLACE(ISNULL(B.BizNo,''), '-', ''), 
                           CASE WHEN ISNULL(B.BizNo, '') = '' THEN ISNULL(dbo._FCOMDecrypt(B.PersonId, '_TDACustTaxHist', 'PersonId', @CompanySeq),'') ELSE '' END, '' AS CustName, '' AS BizKind, '' AS BizType,
                           SUM(A.BillCnt), SUM(A.SupplyAmt), SUM(A.VATAmt), A.IsEBill, ISNULL(A.IsDelayBill, '')
                      FROM _TTAXTaxBillSum AS A WITH(NOLOCK)
                                                JOIN _TDACustTaxHist AS B WITH(NOLOCK)
                                                  ON A.CompanySeq   = B.CompanySeq
                                                 AND A.CustSeq      = B.CustSeq
                                                 AND A.CustSerl     = B.HistSerl
                     WHERE A.CompanySeq     = @CompanySeq
                       AND A.TaxTermSeq     = @TaxTermSeq
                AND A.TaxUnit        = @TaxUnit
                       AND A.CustSerl      <> 0 ---------------------------------------- Hist����
                     GROUP BY A.CompanySeq, A.TaxTermSeq, A.TaxUnit, A.SMBuyOrSale, REPLACE(ISNULL(B.BizNo,''), '-', ''), 
                              CASE WHEN ISNULL(B.BizNo, '') = '' THEN ISNULL(dbo._FCOMDecrypt(B.PersonId, '_TDACustTaxHist', 'PersonId', @CompanySeq),'') ELSE '' END, A.IsEBill, A.IsDelayBill
                --==================================================================================================================================
                -- E-Sero�Ű�� ���ڼ��ݰ�꼭 ���� ���� + Upload���� INSERT 
                --==================================================================================================================================
                IF @IsESERO = '1'
                BEGIN
                    DELETE #TTAXTaxBillSum 
                     WHERE IsEBill = '1' 
                    INSERT INTO #TTAXTaxBillSum (CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo,
                                                 PersonID, CustName, BillCnt, SupplyAmt, VATAmt, IsEBill, IsDelayBill)
                        SELECT @CompanySeq, @TaxTermSeq, @TaxUnit, A.SMBuyOrSale, CASE WHEN A.SMBuyOrSale = 4099001 THEN REPLACE(A.S_TaxNo, '-', '') ELSE REPLACE(A.R_TaxNo, '-', '') END,
                               '', '', COUNT(DISTINCT A.SetNo), SUM(A.SupplyAmt), SUM(A.VATAmt), 
                               '1', CASE WHEN A.TransDate >= B.OverDate THEN '1' ELSE '0' END
                          FROM _TTAXEBillUpload AS A WITH(NOLOCK)
                                                     LEFT OUTER JOIN _TTAXOverTerm AS B WITH(NOLOCK)
                                                       ON B.YearMonth   = LEFT(A.BillDate, 6)
                         WHERE A.CompanySeq     = @CompanySeq
                           AND (@TaxUnit = 0 OR A.TaxUnit = @TaxUnit)     
                           AND A.BillDate BETWEEN @TaxFrDate  AND @TaxToDate  
                         GROUP BY A.SMBuyOrSale, CASE WHEN A.SMBuyOrSale = 4099001 THEN REPLACE(A.S_TaxNo, '-', '') ELSE REPLACE(A.R_TaxNo, '-', '') END,
                                  CASE WHEN A.TransDate >= B.OverDate THEN '1' ELSE '0' END
                    -- ���ڼ��ݰ�꼭 �����Ű������� ����.. �Ф�
                    INSERT INTO #TTAXTaxBillSum (CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo,
                                                 PersonID, CustName, BillCnt, SupplyAmt, VATAmt, IsEBill, IsDelayBill)
                        SELECT @CompanySeq, @TaxTermSeq, @TaxUnit, A.SMBuyOrSale, A.BizNo,
                               dbo._FCOMDecrypt(A.CustPersonId, '_TTAXSlipSum', 'CustPersonId', @CompanySeq), '', COUNT(*), SUM(A.SupplyAmt), SUM(A.VATAmt), '1', '0'
                          FROM _TTAXSlipSum AS A WITH(NOLOCK)
                                                 JOIN _TDAEvid AS B WITH(NOLOCK)
                                                   ON A.CompanySeq  = B.CompanySeq
                                                  AND A.EvidSeq     = B.EvidSeq
                                                 JOIN _TACProvDeclar AS C WITH(NOLOCK)
                                                   ON A.CompanySeq  = C.CompanySeq
                                                  AND A.TaxTermSeq  = C.TaxTermSeq
                                                  AND A.SlipSeq     = C.SlipSeq
                         WHERE A.CompanySeq     = @CompanySeq
                           AND A.TaxTermSeq     = @TaxTermSeq
                           AND (@TaxUnit = 0 OR A.TaxUnit   = @TaxUnit)
                           AND B.IsElec         = '1' -- ���ڼ��ݰ�꼭�� �����Ű� �������� �Ű� �Ǿ�� ��...
                           AND B.IsBuyerBill   <> '1'
                         GROUP BY A.SMBuyOrSale, A.BizNo, dbo._FCOMDecrypt(A.CustPersonId, '_TTAXSlipSum', 'CustPersonId', @CompanySeq), A.CustName
      UPDATE #TTAXTaxBillSum SET IsEBill = '0', IsDelayBill = '0' WHERE IsEBill = '1' AND IsDelayBill = '1'

                    INSERT INTO #TTAXTaxBillSum2 (CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, BizKind, BizType, BillCnt, SupplyAmt, VATAmt, IsEBill, IsDelayBill)
                        SELECT CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, REPLACE(BizNo, '-', ''), PersonId, '', '', '', SUM(BillCnt), SUM(SupplyAmt), SUM(VATAmt), IsEBill, IsDelayBill
                          FROM #TTAXTaxBillSum
                         GROUP BY CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, REPLACE(BizNo, '-', ''), PersonId, IsEBill, IsDelayBill
                    UPDATE #TTAXTaxBillSum2
                       SET CustName     = B.CustName,
                           BizKind      = '',
                           BizType      = ''
                      FROM #TTAXTaxBillSum2 AS A JOIN _TDACust AS B
                                                   ON B.CompanySeq  = @CompanySeq
                                                  AND A.BizNo       = REPLACE(B.BizNo, '-', '')
                                                  AND B.BizNo       <> ''
                END
                ELSE
                BEGIN
                    INSERT INTO #TTAXTaxBillSum2 (CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, BizKind, BizType, BillCnt, SupplyAmt, VATAmt, IsEBill, IsDelayBill)
                        SELECT CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, BizKind, BizType, SUM(BillCnt), SUM(SupplyAmt), SUM(VATAmt), IsEBill, IsDelayBill
                          FROM #TTAXTaxBillSum
                         GROUP BY CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, BizKind, BizType, IsEBill, IsDelayBill
                END
                
                UPDATE #TTAXTaxBillSum2
				   SET BizNo = CASE WHEN LEN(BizNo) = 10 THEN BizNo ELSE '' END,
				       PersonID = CASE WHEN LEN(PersonID) = 13 THEN PersonID ELSE '' END

                ------------------------------------------------------------------------------------------------------------------------------
                -- 2011��1��Ȯ�� �����Ⱓ ������ ������ 15�� ���� ���ڼ��ݰ�꼭 ���ۺ� ===> ���� ���ݰ�꼭�� ���� �Ű�    --- START
                -- �� �κ� ������, �Ʒ� �Ű� ������ ������ �ʿ� ����
                ------------------------------------------------------------------------------------------------------------------------------
                UPDATE #TTAXTaxBillSum2
                   SET IsEBill      = '0'
                 WHERE IsEBill      = '1'   -- ���ڼ��ݰ�꼭
                   AND IsDelayBill  = '1'   -- �����Ⱓ ������ ������ 15�� ���� ���ۺ�
                ------------------------------------------------------------------------------------------------------------------------------
                -- 2011��1��Ȯ�� �����Ⱓ ������ ������ 15�� ���� ���ڼ��ݰ�꼭 ���ۺ� ===> ���� ���ݰ�꼭�� ���� �Ű�    --- END
                ------------------------------------------------------------------------------------------------------------------------------
                UPDATE #TTAXTaxBillSum2
                   SET CustName     = ISNULL(B.FullName        , ''),
                       BizKind      = ISNULL(B.BizKind         , ''),
                       BizType      = ISNULL(B.BizType         , '')
                  FROM #TTAXTaxBillSum2 AS A JOIN _TDACust AS B WITH(NOLOCK)
                                               ON A.BizNo   = B.BizNo
                                              AND B.CompanySeq = @CompanySeq
                                              AND B.BizNo   <> ''
                UPDATE #TTAXTaxBillSum2
                   SET CustName     = ISNULL(B.FullName        , ''),
                       BizKind      = ISNULL(B.BizKind         , ''),
                       BizType      = ISNULL(B.BizType         , '')
                  FROM #TTAXTaxBillSum2 AS A JOIN _TDACustTaxHist AS B WITH(NOLOCK)
                                    ON A.BizNo   = B.BizNo
                                              AND B.CompanySeq = @CompanySeq
                                              AND B.BizNo   <> ''
                 WHERE CustName     = ''
            --�ƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢ�
            ------------------------------------------------------------------------------------------------------------------------------------------
            -- ���ݰ�꼭 ��� �� ��ȸ ������ �����ϰ� ���� TempTable�� ���� �� TempTable���� ��� ���� 2010.10.22 by bgKeum
            ------------------------------------------------------------------------------------------------------------------------------------------
            --�ƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢ�

    -- [����]�ڷ�Ű�(4099002)  
            IF EXISTS (SELECT * FROM _TTAXTaxBillSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq   
                                                                    AND TaxUnit = @TaxUnit AND SMBuyOrSale = 4099002)
               OR (@IsESERO = '1')
            BEGIN  
    /***************************************************************************************************************************  
    ���ݰ�꼭 �հ�ǥ - �����ڷ�(���ڼ��ݰ�꼭 �̿ܺ�)  
  
    01. �ڷᱸ��(1) : 1  
    02. �����ڵ�Ϲ�ȣ(10)  
    03. �Ϸù�ȣ(4)  
    04. �ŷ��ڵ�Ϲ�ȣ(10)  
    05. �ŷ��ڻ�ȣ(30)  
    06. �ŷ��ھ���(17) : �����׸����� SPACE�� �Է�  
    07. �ŷ�������(25) : �����׸����� SPACE�� �Է�  
    08. ���ݰ�꼭�ż�(7)  
    09. ������(2) : �����׸����� 0���� �Է�  
    10. ���ް���(14)  
    11. ����(13)  
    12. �Ű����ַ��ڵ�(����)(1) : �����ڰ� �ַ��������� �Ǵ� �ַ����ž����� ��쿡�� �����ϰ� ��Ÿ ������ ��쿡�� 0�� ������  
    13. �ַ��ڵ�(�Ҹ�)(1) : �����ڰ� �ַ��������� �Ǵ� �ַ����ž����� ��쿡�� �����ϰ� ��Ÿ ������ ��쿡�� 0�� ������  
    14. �ǹ�ȣ(4) : ���ڽŰ� 7501�� ����  
    15. ���⼭(3) : �������� ���� �������� �ڵ�  
    16. ����(28)  
  
    �� �ֹε�Ϲ�ȣ ������� ������ �ڷ᷹�ڵ带 �ۼ��ϸ� �ȵ�  
    ****************************************************************************************************************************/  
                IF EXISTS (SELECT * 
                             FROM #TTAXTaxBillSum2
                            WHERE SMBuyOrSale = 4099002   -- �����ڷ�(4099002)  
                              AND BizNo      <> ''
                              AND ISNULL(IsEBill,'0') <> '1' )         -- ���ڼ��ݰ�꼭 �̿ܺ�
                BEGIN  
                    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                      SELECT '1'                                                                            --01. �ڷᱸ��  
                            + dbo._FnVATCHARChg(CONVERT(VARCHAR(10),REPLACE(Tax.TaxNo,'-','')),10,1)        --02. ������ ��Ϲ�ȣ 
                            + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY Tax.TaxNo) AS VARCHAR), 4)    --03. �Ϸù�ȣ  
                            + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), TaxBill.BizNo),10,1)                   --04. �ŷ��� ��Ϲ�ȣ
                            + dbo._FnVATCHARChg(CONVERT(VARCHAR(30), TaxBill.CustName),30,1)                --05. �ŷ��ڻ�ȣ
                            + SPACE(17)                                                                     --06. �ŷ��ھ���
                            + SPACE(25)                                                                     --07. �ŷ�������
                            + dbo._FnVATIntChg(ISNULL(TaxBill.BillCnt, 0), 7, 0, 1)                         --08. ���ݰ�꼭 �ż�  
                            + '00'                                                                          --09. ������  
                            + dbo._FnVATIntChg(ISNULL(TaxBill.SupplyAmt, 0),  14, 0, 2)                     --10. ���ް���  
                            + dbo._FnVATIntChg(ISNULL(TaxBill.VATAmt   , 0),  13, 0, 2)                     --11. ����  
                            + CASE WHEN RIGHT('0' + CONVERT(VARCHAR(1),LTRIM(RTRIM(ISNULL(Tax.liquorWholeSaleNo ,'0')))),1) IN ('0', '') THEN '0'
                                   ELSE '1' END   --12. �Ű����ַ��ڵ�(����) 
                            + SPACE(1)   --13. �ַ��ڵ�(�Ҹ�)  
                            + '7501'                                                                        --14. �ǹ�ȣ  
                            + Tax.TaxOfficeNo                                                               --15. ���⼭  
                            + SPACE(28)  
                            , 170  
                      FROM #TTAXTaxBillSum2 AS TaxBill LEFT OUTER JOIN #TDATaxUnit AS Tax WITH(NOLOCK)
                                                         ON TaxBill.CompanySeq   = Tax.CompanySeq  
                                                        AND TaxBill.TaxUnit      = Tax.TaxUnit 
                     WHERE TaxBill.SMBuyOrSale = 4099002   -- �����ڷ�(4099002)  
                       AND TaxBill.BizNo      <> ''
                       AND ISNULL(TaxBill.IsEBill,'0') <> '1'         -- ���ڼ��ݰ�꼭 �̿ܺ�   
                END --���ݰ�꼭 �հ�ǥ - �����ڷ�(���ڼ��ݰ�꼭 �̿ܺ�)��  
  
    /***************************************************************************************************************************  
    ���ݰ�꼭 �հ�ǥ - �����հ�(���ڼ��ݰ�꼭 �̿ܺ�)  
  
    01. �ڷᱸ��(1) : 3  
    02. �����ڵ�Ϲ�ȣ(10)  
    --�հ��  
    03. �ŷ�ó��(7)         : ����ڵ�Ϲ�ȣ ����� �ŷ�ó�� + �ֹε�Ϲ�ȣ ����� �ŷ�ó��  
    04. ���ݰ�꼭 �ż�(7)  : ����ڵ�Ϲ�ȣ ����� �ż� + �ֹε�Ϲ�ȣ ����� �ż�  
    05. ���ް���(15)        : ����ڵ�Ϲ�ȣ ����� ���ް��� + �ֹε�Ϲ�ȣ ����� ���ް���  
    06. ����(14)            : ����ڵ�Ϲ�ȣ ����� ���� + �ֹε�Ϲ�ȣ ����� ����  
    --����ڹ�ȣ�����  
    07. �ŷ�ó��(7)         : ����ڵ�Ϲ�ȣ ����� �ŷ�ó��  
    08. ���ݰ�꼭�ż�(7)   : ����ڵ�Ϲ�ȣ ����� �ż�  
    09. ���ް���(15)        : ����ڵ�Ϲ�ȣ ����� ���ް���  
    10. ����(14)            : ����ڵ�Ϲ�ȣ ����� ����  
    --�ֹι�ȣ�����  
    11.�ŷ�ó��(7)          : �ֹε�Ϲ�ȣ ����� �ŷ�ó��  
    12. ���ݰ�꼭�ż�(7)   : �ֹε�Ϲ�ȣ ����� �ż�  
    13. ���ް���(15)        : �ֹε�Ϲ�ȣ ����� ���ް���  
    14. ����(14)            : �ֹε�Ϲ�ȣ ����� ����  
    15. ����(30)  
    ****************************************************************************************************************************/  
                IF EXISTS (SELECT 1 
                             FROM #TTAXTaxBillSum2 AS A
                            WHERE A.SMBuyOrSale = 4099002       -- �����ڷ�(4099002) 
                              AND ISNULL(A.IsEBill,'0') <> '1') -- ���ڼ��ݰ�꼭 �̿ܺ�  
                BEGIN  
                    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                      SELECT '3'                          --01. �ڷᱸ��  
                            + dbo._FnVATCHARChg(CONVERT(VARCHAR(10),REPLACE(Tax.TaxNo,'-','')),10,1)          --02. �����ڵ�Ϲ�ȣ  
                            + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN 1     -- ����ڵ�Ϲ����
                                                        WHEN ISNULL(TaxBill.BizNo, '') = ''  THEN 1     -- �ֹε�Ϲ����
                                                        ELSE 0 END), 7, 0, 1)                 --03. �ŷ�ó��
                            + dbo._FnVATIntChg(SUM(TaxBill.BillCnt)  , 7, 0, 1)               --04. ���ݰ�꼭 �ż�  
                            + dbo._FnVATIntChg(SUM(TaxBill.SupplyAmt),15, 0, 2)               --05. ���ް��� �հ�  
                            + dbo._FnVATIntChg(SUM(TaxBill.VATAmt)   ,14, 0, 2)               --06. ���� �հ�  
                            + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN 1                 ELSE 0 END),  7, 0, 1)                   --07. �ŷ�ó�� (����ڵ�Ϲ����)
                            + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN TaxBill.BillCnt   ELSE 0 END),  7, 0, 1)                   --08. ���ݰ�꼭 �ż�(����ڵ�Ϲ����) 
                            + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN TaxBill.SupplyAmt ELSE 0 END), 15, 0, 2)                  --09. ���ް���       (����ڵ�Ϲ����) 
                            + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN TaxBill.VATAmt    ELSE 0 END), 14, 0, 2)                  --10. ����           (����ڵ�Ϲ����)
                            + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN 1                 ELSE 0 END),  7, 0, 1)                   --11. �ŷ�ó��       (�ֹε�Ϲ����) 
                            + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN TaxBill.BillCnt   ELSE 0 END),  7, 0, 1)                   --12. ���ݰ�꼭 �ż�(�ֹε�Ϲ����) 
                            + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN TaxBill.SupplyAmt ELSE 0 END), 15, 0, 2)                  --13. ���ް���       (�ֹε�Ϲ����) 
                            + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN TaxBill.VATAmt    ELSE 0 END), 14, 0, 2)                  --14. ����           (�ֹε�Ϲ����)
                            + SPACE(30)  
                            , 170  
                      FROM #TTAXTaxBillSum2 AS TaxBill LEFT OUTER JOIN #TDATaxUnit AS Tax WITH(NOLOCK)
                                                         ON TaxBill.CompanySeq      = Tax.CompanySeq
                                                        AND TaxBill.TaxUnit         = Tax.TaxUnit
                     WHERE TaxBill.SMBuyOrSale = 4099002        -- �����ڷ�(4099002)  
                       AND ISNULL(TaxBill.IsEBill,'0') <> '1'   -- ���ڼ��ݰ�꼭 �̿ܺ�   
                     GROUP BY Tax.TaxNo
                END-- ���ݰ�꼭 �հ�ǥ - �����հ�(���ڼ��ݰ�꼭 �̿ܺ�)��  
  
    /***************************************************************************************************************************  
    ���ݰ�꼭 �հ�ǥ - �����հ�(���ڼ��ݰ�꼭��)  
  
    01. �ڷᱸ��(1) : 5  
    02. �����ڵ�Ϲ�ȣ(10)  
    --�հ��  
    03. �ŷ�ó��(7)         : ����ڵ�Ϲ�ȣ ����� �ŷ�ó�� + �ֹε�Ϲ�ȣ ����� �ŷ�ó��  
    04. ���ݰ�꼭 �ż�(7)  : ����ڵ�Ϲ�ȣ ����� �ż� + �ֹε�Ϲ�ȣ ����� �ż�  
    05. ���ް���(15)        : ����ڵ�Ϲ�ȣ ����� ���ް��� + �ֹε�Ϲ�ȣ ����� ���ް���  
    06. ����(14)            : ����ڵ�Ϲ�ȣ ����� ���� + �ֹε�Ϲ�ȣ ����� ����  
    --����ڹ�ȣ�����  
    07. �ŷ�ó��(7)         : ����ڵ�Ϲ�ȣ ����� �ŷ�ó��  
    08. ���ݰ�꼭�ż�(7)   : ����ڵ�Ϲ�ȣ ����� �ż�  
    09. ���ް���(15)        : ����ڵ�Ϲ�ȣ ����� ���ް���  
    10. ����(14)            : ����ڵ�Ϲ�ȣ ����� ����  
    --�ֹι�ȣ�����  
    11.�ŷ�ó��(7)          : �ֹε�Ϲ�ȣ ����� �ŷ�ó��  
    12. ���ݰ�꼭�ż�(7)   : �ֹε�Ϲ�ȣ ����� �ż�  
    13. ���ް���(15)        : �ֹε�Ϲ�ȣ ����� ���ް���  
    14. ����(14)            : �ֹε�Ϲ�ȣ ����� ����  
    15. ����(30)  
    ****************************************************************************************************************************/  
                IF @IsESERO = '1' AND EXISTS (SELECT 1 FROM _TTAXEBillUpload WITH(NOLOCK)
                                                    WHERE CompanySeq = @CompanySeq AND TaxUnit = @TaxUnit AND SMBuyOrSale = 4099002   
                                                      AND BillDate BETWEEN @TaxFrDate AND @TaxToDate
                                                      AND TransDate < @OverDate)  
                BEGIN  
                    -- ����ڹ�ȣ�����  
                    SELECT @CustCntBiz = COUNT(DISTINCT R_TaxNo)  
                      FROM _TTAXEBillUpload WITH(NOLOCK)
                     WHERE CompanySeq   = @CompanySeq  
                       AND TaxUnit      = @TaxUnit  
                       AND SMBuyOrSale  = 4099002  
                       AND BillDate BETWEEN @TaxFrDate AND @TaxToDate  
                       AND LEN(REPLACE(R_TaxNo, '-', '')) < 13  
                       AND TransDate    < @OverDate    -- �����Ⱓ������ ������ 15�� ���������͸�...
  
                    SELECT @TotCntBiz   = COUNT(*)                      ,  
                           @SAmtBiz     = ISNULL(SUM(SupplyAmt  ), 0)   ,  
                           @VAmtBiz     = ISNULL(SUM(VATAmt     ), 0)     
                      FROM _TTAXEBillUpload WITH(NOLOCK)
                     WHERE CompanySeq   = @CompanySeq  
                       AND TaxUnit      = @TaxUnit  
                       AND SMBuyOrSale  = 4099002  
                       AND BillDate BETWEEN @TaxFrDate AND @TaxToDate  
                       AND LEN(REPLACE(R_TaxNo, '-', '')) < 13  
                       AND TransDate    < @OverDate    -- �����Ⱓ������ ������ 15�� ���������͸�...
  
                    -- �ֹι�ȣ �����  
                    SELECT @CustCntPer = COUNT(DISTINCT R_TaxNo)  
                      FROM _TTAXEBillUpload WITH(NOLOCK)
                     WHERE CompanySeq   = @CompanySeq  
                       AND TaxUnit      = @TaxUnit  
                       AND SMBuyOrSale  = 4099002  
                       AND BillDate BETWEEN @TaxFrDate AND @TaxToDate  
                       AND LEN(REPLACE(R_TaxNo, '-', '')) = 13  
                       AND TransDate    < @OverDate    -- �����Ⱓ������ ������ 15�� ���������͸�...
  
                    SELECT @TotCntPer   = COUNT(*)                      ,  
                           @SAmtPer     = ISNULL(SUM(SupplyAmt  ), 0)   ,  
                           @VAmtPer     = ISNULL(SUM(VATAmt     ), 0)     
                      FROM _TTAXEBillUpload WITH(NOLOCK)
                     WHERE CompanySeq   = @CompanySeq  
                       AND TaxUnit      = @TaxUnit  
                       AND SMBuyOrSale  = 4099002  
                       AND BillDate BETWEEN @TaxFrDate AND @TaxToDate  
                       AND LEN(REPLACE(R_TaxNo, '-', '')) = 13  
                       AND TransDate    < @OverDate    -- �����Ⱓ������ ������ 15�� ���������͸�...
  
                    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                      SELECT '5'                         --01. �ڷᱸ��  
                            + dbo._FnVATCHARChg(@TaxNo ,10,1)                       --02. �����ڵ�Ϲ�ȣ  
                            + dbo._FnVATIntChg(@CustCntBiz + @CustCntPer, 7, 0, 1)  --03. �ŷ�ó��  
                            + dbo._FnVATIntChg(@TotCntBiz  + @TotCntPer , 7, 0, 1)  --04. ���ݰ�꼭 �ż�  
                            + dbo._FnVATIntChg(@SAmtBiz    + @SAmtPer   ,15, 0, 2)  --05. ���ް��� �հ�  
                            + dbo._FnVATIntChg(@VAmtBiz    + @VAmtPer   ,14, 0, 2)  --06. ���� �հ�  
                            + dbo._FnVATIntChg(@CustCntBiz  , 7, 0, 1)              --07. �ŷ�ó��       (����ڵ�Ϲ����)  
                            + dbo._FnVATIntChg(@TotCntBiz   , 7, 0, 1)              --08. ���ݰ�꼭 �ż�(����ڵ�Ϲ����)  
                            + dbo._FnVATIntChg(@SAmtBiz     ,15, 0, 2)              --09. ���ް���       (����ڵ�Ϲ����)  
                            + dbo._FnVATIntChg(@VAmtBiz     ,14, 0, 2)              --10. ����           (����ڵ�Ϲ����)  
                            + dbo._FnVATIntChg(@CustCntPer  , 7, 0, 1)              --11. �ŷ�ó��       (�ֹε�Ϲ����)  
                            + dbo._FnVATIntChg(@TotCntPer   , 7, 0, 1)              --12. ���ݰ�꼭 �ż�(�ֹε�Ϲ����)  
                            + dbo._FnVATIntChg(@SAmtPer     ,15, 0, 2)              --13. ���ް���       (�ֹε�Ϲ����)  
                            + dbo._FnVATIntChg(@VAmtPer     ,14, 0, 2)              --14. ����           (�ֹε�Ϲ����)  
                            + SPACE(30)  
                            , 170  
                END  
                ELSE  
                BEGIN  
                    IF EXISTS (SELECT 1
                                 FROM #TTAXTaxBillSum2
                                WHERE SMBuyOrSale = 4099002     -- �����ڷ�(4099002)  
                                  AND ISNULL(IsEBill,'0') = '1' ) -- ���ڼ��ݰ�꼭��  
                    BEGIN  
                        
                        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                          SELECT '5'                          --01. �ڷᱸ��  
                                + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), REPLACE(Tax.TaxNo,'-','')),10,1)          --02. �����ڵ�Ϲ�ȣ  
                                + dbo._FnVATIntChg(SUM(CASE WHEN TaxBill.BizNo <> '' OR TaxBill.BizNo = '' THEN 1 ELSE 0 END), 7, 0, 1) --03. �ŷ�ó��  
                                + dbo._FnVATIntChg(SUM(TaxBill.BillCnt), 7, 0, 1)                 --04. ���ݰ�꼭 �ż�  
                                + dbo._FnVATIntChg(SUM(TaxBill.SupplyAmt),15, 0, 2)               --05. ���ް��� �հ�  
                                + dbo._FnVATIntChg(SUM(TaxBill.VATAmt)   ,14, 0, 2)               --06. ���� �հ�  
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN 1                 ELSE 0 END),  7, 0, 1)  --07. �ŷ�ó��       (����ڵ�Ϲ����) 
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN TaxBill.BillCnt   ELSE 0 END),  7, 0, 1)  --08. ���ݰ�꼭 �ż�(����ڵ�Ϲ����) 
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN TaxBill.SupplyAmt ELSE 0 END), 15, 0, 2)  --09. ���ް���       (����ڵ�Ϲ����) 
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN TaxBill.VATAmt    ELSE 0 END), 14, 0, 2)  --10. ����           (����ڵ�Ϲ����)
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN 1                 ELSE 0 END),  7, 0, 1)  --11. �ŷ�ó��       (�ֹε�Ϲ����)
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN TaxBill.BillCnt   ELSE 0 END),  7, 0, 1)  --12. ���ݰ�꼭 �ż�(�ֹε�Ϲ����)  
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN TaxBill.SupplyAmt ELSE 0 END), 15, 0, 2)  --13. ���ް���       (�ֹε�Ϲ����) 
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN TaxBill.VATAmt    ELSE 0 END), 14, 0, 2)  --14. ����           (�ֹε�Ϲ����)
                                + SPACE(30)  
                                , 170  
                          FROM #TTAXTaxBillSum2 AS TaxBill WITH(NOLOCK)
                                                           LEFT OUTER JOIN #TDATaxUnit AS Tax WITH(NOLOCK)
                                                             ON TaxBill.CompanySeq  = Tax.CompanySeq
                                                            AND TaxBill.TaxUnit     = Tax.TaxUnit
                         WHERE 1 = 1
                           AND TaxBill.SMBuyOrSale = 4099002   -- �����ڷ�(4099002)  
                           AND ISNULL(TaxBill.IsEBill,'0') = '1'    -- ���ڼ��ݰ�꼭��  
                         GROUP BY Tax.TaxNo   
                    END-- ���ݰ�꼭 �հ�ǥ - �����հ�(���ڼ��ݰ�꼭��)��  
                END  
            END  
    -- [����]��������  
           
  
    -- [����]�ڷ�Ű�  
            IF EXISTS (SELECT * FROM _TTAXTaxBillSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq   
                                                                    AND TaxUnit = @TaxUnit AND SMBuyOrSale = 4099001)  
            BEGIN  
    /***************************************************************************************************************************  
    ���ݰ�꼭 �հ�ǥ - �����ڷ�(���ڼ��ݰ�꼭 �̿ܺ�)  
  
    01. �ڷᱸ��(1) : 2  
    02. �����ڵ�Ϲ�ȣ(10)  
    03. �Ϸù�ȣ(4)  
    04. �ŷ��ڵ�Ϲ�ȣ(10)  
    05. �ŷ��ڻ�ȣ(30)  
    06. �ŷ��ھ���(17) : �����׸����� SPACE�� �Է�  
    07. �ŷ�������(25) : �����׸����� SPACE�� �Է�  
    08. ���ݰ�꼭�ż�(7)  
    09. ������(2) : �����׸����� 0���� �Է�  
    10. ���ް���(14)  
    11. ����(13)  
    12. �Ű����ַ��ڵ�(����)(1) : �����ڰ� �ַ��������� �Ǵ� �ַ����ž����� ��쿡�� �����ϰ� ��Ÿ ������ ��쿡�� 0�� ������  
    13. �ַ��ڵ�(�Ҹ�)(1) : �����ڰ� �ַ��������� �Ǵ� �ַ����ž����� ��쿡�� �����ϰ� ��Ÿ ������ ��쿡�� 0�� ������  
    14. �ǹ�ȣ(4) : ���ڽŰ� 8501�� ����  
    15. ���⼭(3) : �������� ���� �������� �ڵ�  
    16. ����(28)  
  
    �� �ֹε�Ϲ�ȣ ������� ������ �ڷ᷹�ڵ带 �ۼ��ϸ� �ȵ�  
    ****************************************************************************************************************************/  
                IF EXISTS (SELECT 1 
                             FROM #TTAXTaxBillSum2
                            WHERE SMBuyOrSale = 4099001   -- �����ڷ�(4099001) 
                              AND BizNo        <> ''
                              AND ISNULL(IsEBill,'0') <> '1')  -- ���ڼ��ݰ�꼭 �̿ܺ�
                BEGIN  
                    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                      SELECT '2'                                                                            --01. �ڷᱸ��  
                          + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), REPLACE(Tax.TaxNo,'-','')),10,1)       --02. ������ ��Ϲ�ȣ  
                            + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY Tax.TaxNo) AS VARCHAR), 4)    --03. �Ϸù�ȣ  
                            + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), TaxBill.BizNo), 10, 1)                 --04. �ŷ��� ��Ϲ�ȣ 
                            + dbo._FnVATCHARChg(CONVERT(VARCHAR(30), TaxBill.CustName), 30, 1)              --05. �ŷ��ڻ�ȣ
                            + SPACE(17)                                                                     --06. �ŷ��ھ���  
                            + SPACE(25)                                                                     --07. �ŷ�������  
                            + dbo._FnVATIntChg(ISNULL(SUM(TaxBill.BillCnt), 0), 7, 0, 1)                    --08. ���ݰ�꼭 �ż�  
                            + '00'                                                                          --09. ������  
                            + dbo._FnVATIntChg(ISNULL(SUM(TaxBill.SupplyAmt), 0),  14, 0, 2)                --10. ���ް���  
                            + dbo._FnVATIntChg(ISNULL(SUM(TaxBill.VATAmt   ), 0),  13, 0, 2)                --11. ����     
                            + CASE WHEN RIGHT('0' + CONVERT(VARCHAR(1),LTRIM(RTRIM(ISNULL(Tax.liquorWholeSaleNo ,'0')))),1) IN ('0', '') THEN '0'
                                   ELSE '1' END      --12. �Ű����ַ��ڵ�(����)    
                            + SPACE(1)              --13. �ַ��ڵ�(�Ҹ�)
                            + '8501'                                                                        --14. �ǹ�ȣ  
                            + Tax.TaxOfficeNo                                                               --15. ���⼭  
                            + SPACE(28)  
                            , 170  
                      FROM #TTAXTaxBillSum2 AS TaxBill LEFT OUTER JOIN #TDATaxUnit AS Tax WITH(NOLOCK)
                                                         ON TaxBill.CompanySeq  = Tax.CompanySeq
                                                        AND TaxBill.TaxUnit     = Tax.TaxUnit
                     WHERE TaxBill.SMBuyOrSale = 4099001   -- �����ڷ�(4099001) 
                       AND TaxBill.BizNo        <> ''
                       AND ISNULL(TaxBill.IsEBill,'0') <> '1'  -- ���ڼ��ݰ�꼭 �̿ܺ�
                     GROUP BY Tax.TaxNo, TaxBill.BizNo, TaxBill.CustName, Tax.liquorWholeSaleNo, Tax.liquorRetailSaleNo, Tax.TaxOfficeNo, ISDelayBill
                END --���ݰ�꼭 �հ�ǥ - �����ڷ�(���ڼ��ݰ�꼭 �̿ܺ�)��  
  
    /***************************************************************************************************************************  
    ���ݰ�꼭 �հ�ǥ - �����հ�(���ڼ��ݰ�꼭 �̿ܺ�)  
  
    01. �ڷᱸ��(1) : 4  
    02. �����ڵ�Ϲ�ȣ(10)  
    --�հ��  
    03. �ŷ�ó��(7)         : ����ڵ�Ϲ�ȣ ����� �ŷ�ó�� + �ֹε�Ϲ�ȣ ����� �ŷ�ó��  
    04. ���ݰ�꼭 �ż�(7)  : ����ڵ�Ϲ�ȣ ����� �ż� + �ֹε�Ϲ�ȣ ����� �ż�  
    05. ���ް���(15)        : ����ڵ�Ϲ�ȣ ����� ���ް��� + �ֹε�Ϲ�ȣ ����� ���ް���  
    06. ����(14)            : ����ڵ�Ϲ�ȣ ����� ���� + �ֹε�Ϲ�ȣ ����� ����  
    --����ڹ�ȣ�����  
    07. �ŷ�ó��(7)         : ����ڵ�Ϲ�ȣ ����� �ŷ�ó��  
    08. ���ݰ�꼭�ż�(7)   : ����ڵ�Ϲ�ȣ ����� �ż�  
    09. ���ް���(15)        : ����ڵ�Ϲ�ȣ ����� ���ް���  
    10. ����(14)            : ����ڵ�Ϲ�ȣ ����� ����  
    --�ֹι�ȣ�����  
    11.�ŷ�ó��(7)          : �ֹε�Ϲ�ȣ ����� �ŷ�ó��  
    12. ���ݰ�꼭�ż�(7)   : �ֹε�Ϲ�ȣ ����� �ż�  
    13. ���ް���(15)        : �ֹε�Ϲ�ȣ ����� ���ް���  
    14. ����(14)            : �ֹε�Ϲ�ȣ ����� ����  
    15. ����(30)  
    ****************************************************************************************************************************/  
                IF EXISTS (SELECT 1
                             FROM #TTAXTaxBillSum2
                            WHERE SMBuyOrSale = 4099001        -- �����ڷ�(4099001)  
                              AND ISNULL(IsEBill,'0') <> '1')   -- ���ڼ��ݰ�꼭 �̿ܺ�
                BEGIN  
                    SELECT @Count_A = COUNT(BizNo)
                      FROM #TTAXTaxBillSum2
                     WHERE SMBuyOrSale = 4099001       -- �����ڷ�(4099001) 
                       AND ISNULL(IsEBill,'0') <> '1'   -- ���ڼ��ݰ�꼭 �̿ܺ�
                       AND BizNo        > ''            -- ����ڵ�Ϲ����
                    SELECT @Count_B = COUNT(PersonID)
                      FROM #TTAXTaxBillSum2
                     WHERE SMBuyOrSale  = 4099001       -- �����ڷ�(4099001) 
                       AND ISNULL(IsEBill,'0') <> '1'   -- ���ڼ��ݰ�꼭 �̿ܺ�
                       AND BizNo        = ''            -- �ֹε�Ϲ����

                    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                      SELECT '4'                          --01. �ڷᱸ��  
                            + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), REPLACE(Tax.TaxNo,'-','')),10,1)          --02. �����ڵ�Ϲ�ȣ  
                            + dbo._FnVATIntChg(@Count_A + @Count_B, 7, 0, 1)                            --03. �ŷ�ó��   
                            + dbo._FnVATIntChg(SUM(TaxBill.BillCnt)  , 7, 0, 1)                         --04. ���ݰ�꼭 �ż�  
                            + dbo._FnVATIntChg(SUM(TaxBill.SupplyAmt),15, 0, 2)                         --05. ���ް��� �հ�  
                            + dbo._FnVATIntChg(SUM(TaxBill.VATAmt)   ,14, 0, 2)                         --06. ���� �հ�  
                            + dbo._FnVATIntChg(ISNULL(@Count_A, 0), 7, 0, 1)                                                    --07. �ŷ�ó��       (����ڵ�Ϲ����)
                            + dbo._FnVATIntChg(SUM(CASE WHEN TaxBill.BizNo <> '' THEN TaxBill.BillCnt   ELSE 0 END), 7, 0, 1)   --08. ���ݰ�꼭 �ż�(����ڵ�Ϲ����)
                            + dbo._FnVATIntChg(SUM(CASE WHEN TaxBill.BizNo <> '' THEN TaxBill.SupplyAmt ELSE 0 END),15, 0, 2)   --09. ���ް���       (����ڵ�Ϲ����)
                            + dbo._FnVATIntChg(SUM(CASE WHEN TaxBill.BizNo <> '' THEN TaxBill.VATAmt    ELSE 0 END),14, 0, 2)   --10. ����           (����ڵ�Ϲ����)
                            + dbo._FnVATIntChg(ISNULL(@Count_B, 0), 7, 0, 1)                                                    --11. �ŷ�ó��       (�ֹε�Ϲ����)
                            + dbo._FnVATIntChg(SUM(CASE WHEN TaxBill.BizNo = '' THEN TaxBill.BillCnt    ELSE 0 END), 7, 0, 1)   --12. ���ݰ�꼭 �ż�(�ֹε�Ϲ����)
                            + dbo._FnVATIntChg(SUM(CASE WHEN TaxBill.BizNo = '' THEN TaxBill.SupplyAmt  ELSE 0 END),15, 0, 2)   --13. ���ް���       (�ֹε�Ϲ����)
                            + dbo._FnVATIntChg(SUM(CASE WHEN TaxBill.BizNo = '' THEN TaxBill.VATAmt     ELSE 0 END),14, 0, 2)   --14. ����           (�ֹε�Ϲ����)
                            + SPACE(30)  
                            , 170  
                      FROM #TTAXTaxBillSum2 AS TaxBill LEFT OUTER JOIN #TDATaxUnit AS Tax WITH(NOLOCK)
                                                         ON TaxBill.CompanySeq  = Tax.CompanySeq
                                                        AND TaxBill.TaxUnit     = Tax.TaxUnit
                     WHERE TaxBill.SMBuyOrSale = 4099001        -- �����ڷ�(4099001)  
                       AND ISNULL(TaxBill.IsEBill,'0') <> '1'   -- ���ڼ��ݰ�꼭 �̿ܺ�
                     GROUP BY Tax.TaxNo 
               END-- ���ݰ�꼭 �հ�ǥ - �����հ�(���ڼ��ݰ�꼭 �̿ܺ�)��  
    /***************************************************************************************************************************  
    ���ݰ�꼭 �հ�ǥ - �����հ�(���ڼ��ݰ�꼭��)  
  
    01. �ڷᱸ��(1) : 6  
    02. �����ڵ�Ϲ�ȣ(10)  
    --�հ��  
    03. �ŷ�ó��(7)         : ����ڵ�Ϲ�ȣ ����� �ŷ�ó�� + �ֹε�Ϲ�ȣ ����� �ŷ�ó��  
    04. ���ݰ�꼭 �ż�(7)  : ����ڵ�Ϲ�ȣ ����� �ż� + �ֹε�Ϲ�ȣ ����� �ż�  
    05. ���ް���(15)        : ����ڵ�Ϲ�ȣ ����� ���ް��� + �ֹε�Ϲ�ȣ ����� ���ް���  
    06. ����(14)            : ����ڵ�Ϲ�ȣ ����� ���� + �ֹε�Ϲ�ȣ ����� ����  
    --����ڹ�ȣ�����  
    07. �ŷ�ó��(7)         : ����ڵ�Ϲ�ȣ ����� �ŷ�ó��  
    08. ���ݰ�꼭�ż�(7)   : ����ڵ�Ϲ�ȣ ����� �ż�  
    09. ���ް���(15)        : ����ڵ�Ϲ�ȣ ����� ���ް���  
    10. ����(14)            : ����ڵ�Ϲ�ȣ ����� ����  
    --�ֹι�ȣ�����  
    11.�ŷ�ó��(7)          : �ֹε�Ϲ�ȣ ����� �ŷ�ó��  
    12. ���ݰ�꼭�ż�(7)   : �ֹε�Ϲ�ȣ ����� �ż�  
    13. ���ް���(15)        : �ֹε�Ϲ�ȣ ����� ���ް���  
    14. ����(14)            : �ֹε�Ϲ�ȣ ����� ����  
    15. ����(30)  
    ****************************************************************************************************************************/  
                IF @IsESERO = '1' AND EXISTS (SELECT 1 FROM _TTAXEBillUpload WITH(NOLOCK)
                                                    WHERE CompanySeq = @CompanySeq AND TaxUnit = @TaxUnit AND SMBuyOrSale = 4099001  
                                                      AND BillDate BETWEEN @TaxFrDate AND @TaxToDate
                                                      AND TransDate < @OverDate)  -- [�������� �����Ⱓ�����ϴ����� 15��] ����
                BEGIN  
                    -- ����ڹ�ȣ�����  
                    SELECT @CustCntBiz = COUNT(DISTINCT S_TaxNo)  
                      FROM _TTAXEBillUpload WITH(NOLOCK)
                     WHERE CompanySeq   = @CompanySeq  
                       AND TaxUnit      = @TaxUnit  
                       AND SMBuyOrSale  = 4099001  
                       AND BillDate BETWEEN @TaxFrDate AND @TaxToDate  
                       AND LEN(REPLACE(S_TaxNo, '-', '')) < 13  
                       AND TransDate    < @OverDate -- [�������� �����Ⱓ�����ϴ����� 15��] ����
                    -- !!!!!!!!!!!!!!
                    SELECT @CustCntBiz = COUNT(DISTINCT BizNo)
                      FROM #TTAXTaxBillSum2
                     WHERE SMBuyOrSale  = 4099001  
                       AND TaxUnit      = @TaxUnit 
                       AND BizNo        > ''
                       AND IsEBill      = '1'
  
                    SELECT @TotCntBiz   = COUNT(*)                      ,  
                           @SAmtBiz     = ISNULL(SUM(SupplyAmt  ), 0)   ,  
                           @VAmtBiz     = ISNULL(SUM(VATAmt     ), 0)     
                      FROM _TTAXEBillUpload WITH(NOLOCK)
                     WHERE CompanySeq   = @CompanySeq  
                       AND TaxUnit      = @TaxUnit  
                       AND SMBuyOrSale  = 4099001  
                       AND BillDate BETWEEN @TaxFrDate AND @TaxToDate  
                       AND LEN(REPLACE(S_TaxNo, '-', '')) < 13  
                       AND TransDate    < @OverDate -- [�������� �����Ⱓ�����ϴ����� 15��] ����
                    -- !!!!!!!!!!!!!!
                    SELECT @TotCntBiz   = ISNULL(SUM(BillCnt    ), 0)   ,
                           @SAmtBiz     = ISNULL(SUM(SupplyAmt  ), 0)   ,  
                           @VAmtBiz     = ISNULL(SUM(VATAmt     ), 0)                                
                      FROM #TTAXTaxBillSum2 
                     WHERE SMBuyOrSale  = 4099001  
                       AND TaxUnit      = @TaxUnit 
                       AND BizNo        > ''
                       AND IsEBill      = '1'
  
                    -- �ֹι�ȣ �����  
                    SELECT @CustCntPer = COUNT(DISTINCT S_TaxNo)  
                      FROM _TTAXEBillUpload WITH(NOLOCK)
                     WHERE CompanySeq   = @CompanySeq  
                       AND TaxUnit      = @TaxUnit  
                       AND SMBuyOrSale  = 4099001  
                       AND BillDate BETWEEN @TaxFrDate AND @TaxToDate  
                       AND LEN(REPLACE(S_TaxNo, '-', '')) = 13  
                       AND TransDate    < @OverDate -- [�������� �����Ⱓ�����ϴ����� 15��] ����
                    -- !!!!!!!!!!!!!!
                    SELECT @CustCntPer = COUNT(DISTINCT BizNo)
                      FROM #TTAXTaxBillSum2 
                     WHERE SMBuyOrSale  = 4099001  
                       AND TaxUnit      = @TaxUnit 
                       AND PersonID     > ''
                       AND IsEBill      = '1'
  
                    SELECT @TotCntPer   = COUNT(*)                      ,  
                           @SAmtPer     = ISNULL(SUM(SupplyAmt  ), 0)   ,  
                           @VAmtPer     = ISNULL(SUM(VATAmt     ), 0)     
                      FROM _TTAXEBillUpload WITH(NOLOCK)
                     WHERE CompanySeq   = @CompanySeq  
       AND TaxUnit      = @TaxUnit  
                       AND SMBuyOrSale  = 4099001  
                       AND BillDate BETWEEN @TaxFrDate AND @TaxToDate  
                       AND LEN(REPLACE(S_TaxNo, '-', '')) = 13  
                       AND TransDate    < @OverDate -- [�������� �����Ⱓ�����ϴ����� 15��] ����
                    -- !!!!!!!!!!!!!!
                    SELECT @TotCntPer   = ISNULL(SUM(BillCnt    ), 0)   ,
                           @SAmtPer     = ISNULL(SUM(SupplyAmt  ), 0)   ,  
                           @VAmtPer     = ISNULL(SUM(VATAmt     ), 0)                                
                      FROM #TTAXTaxBillSum2 
                     WHERE SMBuyOrSale  = 4099001  
                       AND TaxUnit      = @TaxUnit 
                       AND PersonID     > ''
                       AND IsEBill      = '1'
  
                    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                      SELECT '6'             --01. �ڷᱸ��  
                            + dbo._FnVATCHARChg(@TaxNo,10,1)      --02. �����ڵ�Ϲ�ȣ  
                            + dbo._FnVATIntChg(@CustCntBiz + @CustCntPer, 7, 0, 1)  --03. �ŷ�ó��   
                            + dbo._FnVATIntChg(@TotCntBiz + @TotCntPer, 7, 0, 1)    --04. ���ݰ�꼭 �ż�  
                            + dbo._FnVATIntChg(@SAmtBiz + @SAmtPer,15, 0, 2)        --05. ���ް��� �հ�  
                            + dbo._FnVATIntChg(@VAmtBiz + @VAmtPer,14, 0, 2)        --06. ���� �հ�  
                            + dbo._FnVATIntChg(@CustCntBiz  , 7, 0, 1)              --07. �ŷ�ó��  
                            + dbo._FnVATIntChg(@TotCntBiz   , 7, 0, 1)              --08. ���ݰ�꼭 �ż�(����ڵ�Ϲ����)  
                            + dbo._FnVATIntChg(@SAmtBiz     ,15, 0, 2)              --09. ���ް���       (����ڵ�Ϲ����)  
                            + dbo._FnVATIntChg(@VAmtBiz     ,14, 0, 2)              --10. ����           (����ڵ�Ϲ����)  
                            + dbo._FnVATIntChg(@CustCntPer  , 7, 0, 1)              --07. �ŷ�ó��  
                            + dbo._FnVATIntChg(@TotCntPer   , 7, 0, 1)              --08. ���ݰ�꼭 �ż�(�ֹε�Ϲ����)  
                            + dbo._FnVATIntChg(@SAmtPer     ,15, 0, 2)              --09. ���ް���       (�ֹε�Ϲ����)  
                            + dbo._FnVATIntChg(@VAmtPer     ,14, 0, 2)              --10. ����           (�ֹε�Ϲ����)  
                            + SPACE(30)  
                            , 170  
                END  
                ELSE  
                BEGIN  
                    IF EXISTS (SELECT 1 
                                 FROM #TTAXTaxBillSum2 
                                 WHERE SMBuyOrSale = 4099001        -- �����ڷ�(4099001)  
                                   AND ISNULL(IsEBill,'0') = '1')    -- ���ڼ��ݰ�꼭
                    BEGIN  
                        
                        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                          SELECT '6'                          --01. �ڷᱸ��  
                                + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), REPLACE(Tax.TaxNo,'-','')),10,1)           --02. �����ڵ�Ϲ�ȣ  
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' OR ISNULL(TaxBill.BizNo, '')  = '' THEN 1 ELSE 0 END), 7, 0, 1) --03. �ŷ�ó��
                                + dbo._FnVATIntChg(SUM(TaxBill.BillCnt)  , 7, 0, 1)                                 --04. ���ݰ�꼭 �ż�
                                + dbo._FnVATIntChg(SUM(TaxBill.SupplyAmt),15, 0, 2)                                 --05. ���ް��� �հ�  
                                + dbo._FnVATIntChg(SUM(TaxBill.VATAmt)   ,14, 0, 2)                                 --06. ���� �հ�  
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN 1                 ELSE 0 END), 7, 0, 1)   --07. �ŷ�ó��       (����ڵ�Ϲ����)
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN TaxBill.BillCnt   ELSE 0 END), 7, 0, 1)   --08. ���ݰ�꼭 �ż�(����ڵ�Ϲ����) 
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN TaxBill.SupplyAmt ELSE 0 END),15, 0, 2)   --09. ���ް���       (����ڵ�Ϲ����)  
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN TaxBill.VATAmt    ELSE 0 END),14, 0, 2)   --10. ����           (����ڵ�Ϲ����)  
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN 1                 ELSE 0 END), 7, 0, 1)   --11. �ŷ�ó��       (�ֹε�Ϲ����)  
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN TaxBill.BillCnt   ELSE 0 END), 7, 0, 1)   --12. ���ݰ�꼭 �ż�(�ֹε�Ϲ����)  
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN TaxBill.SupplyAmt ELSE 0 END),15, 0, 2)   --13. ���ް���       (�ֹε�Ϲ����)  
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN TaxBill.VATAmt    ELSE 0 END),14, 0, 2)   --14. ����           (�ֹε�Ϲ����)  
                                + SPACE(30)  
                                , 170  
                          FROM #TTAXTaxBillSum2 AS TaxBill LEFT OUTER JOIN #TDATaxUnit AS Tax WITH(NOLOCK)
                                                             ON TaxBill.CompanySeq  = Tax.CompanySeq
                                                            AND TaxBill.TaxUnit     = Tax.TaxUnit
                         WHERE TaxBill.SMBuyOrSale = 4099001   -- �����ڷ�(4099001)  
                           AND ISNULL(TaxBill.IsEBill,'0') = '1'       -- ���ڼ��ݰ�꼭
                         GROUP BY Tax.TaxNo   
                    END  
                END-- ���ݰ�꼭 �հ�ǥ - �����հ�(���ڼ��ݰ�꼭��)��  
            END-- [����]��������  
    END--���ݰ�꼭 ���� ����  
END  
/***************************************************************************************************************************    
��꼭 �հ�ǥ -������    
    
01. ���ڵ屸��(1) : A    
02. ������(3)    
03. ��������(8)    
04. �����ڱ���(1) : '1'  �����븮��, '2' ����, '3' ����    
05. �����븮�ΰ�����ȣ(6)    
06. ����ڵ�Ϲ�ȣ(10)    
07. ���θ�(��ȣ)(40)    
08. �ֹ�(����)��Ϲ�ȣ(13)  09. ��ǥ��(30)    
10. ������(�����ȣ) �������ڵ�(10)    
11. ������(�ּ�)(70)    
12. ��ȭ��ȣ(15)    
13. ����Ǽ���(5)    
14. ������ѱ��ڵ�����(3) : ���ڽŰ�� '101'    
15. ����(15)    
****************************************************************************************************************************/    
IF @WorkingTag IN ('', 'H')  
BEGIN  
    IF @Env4728 = '1'
        OR EXISTS (SELECT * FROM _TTAXBillSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)    
    BEGIN    
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT 'A'  --01. �ڷᱸ��    
                   + CASE WHEN ISNULL(ComInfo.TaxOfficeNo, '') = '' THEN SPACE(3) ELSE CONVERT(VARCHAR(3), ComInfo.TaxOfficeNo) END  --02. �������ڵ�    
                   + CONVERT(VARCHAR(8), GETDATE(), 112)              --03. ��������    
                   + '2'                        --04. �����ڱ���(����)    
                   + SPACE(6)                   --05. �����븮�ΰ�����ȣ    
                   + CONVERT(VARCHAR(10), REPLACE(ComInfo.TaxNo, '-', ''))                    --06. ����ڵ�Ϲ�ȣ    
                   + CONVERT(VARCHAR(40), LTRIM(RTRIM(CASE WHEN ISNULL(ComInfo.BillTaxName,'') <> '' THEN ComInfo.BillTaxName ELSE ComInfo.TaxName END)))    
                             + SPACE(40 - DATALENGTH(CONVERT(VARCHAR(40), LTRIM(RTRIM(CASE WHEN ISNULL(ComInfo.BillTaxName,'') <> '' THEN ComInfo.BillTaxName ELSE TaxName END)))))  --07. ���θ�(��ȣ)    
                   + @CompanyNo                 --08.���ε�Ϲ�ȣ    
                   + CONVERT(VARCHAR(30), LTRIM(RTRIM(ComInfo.Owner))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(ComInfo.Owner))))) --09.��ǥ��    
                   + CASE WHEN ISNULL(ComInfo.Zip, '') = '' THEN SPACE(10)    
                          ELSE CONVERT(VARCHAR(10), LTRIM(RTRIM(ComInfo.Zip))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(ComInfo.Zip)))))  
                     END                        --10.�����ȣ    
                   + LTRIM(RTRIM(@Addr1)) + SPACE(70 - DataLength(CONVERT(VARCHAR(70), LTRIM(RTRIM(@Addr1)))))      --11. ����������    
                   + CONVERT(VARCHAR(15), LTRIM(RTRIM(dbo._FnTaxTelChk( ComInfo.TelNo )))) +  SPACE(15 - DATALENGTH(CONVERT(VARCHAR(15), LTRIM(RTRIM(dbo._FnTaxTelChk( ComInfo.TelNo ))))))  --12. ��ȭ��ȣ    
                   + '00001'                    --13. ����Ǽ���    
                   + '101'                      --14. ������ѱ��ڵ�����    
                   + SPACE(15)    
                   , 230    
             FROM #TDATaxUnit AS ComInfo WITH(NOLOCK)    
             WHERE ComInfo.CompanySeq   = @CompanySeq  
               AND ComInfo.TaxUnit      = @TaxUnit    
       
    /***************************************************************************************************************************    
    ��꼭 �հ�ǥ - �����ǹ�����������    
        
    01. ���ڵ屸��(1) : B    
    02. ������(3)    
    03. �Ϸù�ȣ(6)    
    04. ����ڵ�Ϲ�ȣ(10)    
    05. ���θ�(��ȣ)(40)    
    06. ��ǥ��(����)(30)    
    07. �����(�����ȣ)�������ڵ�(10)    
    08. ����������(�ּ�)(70)    
    09. ����(60)    
    ****************************************************************************************************************************/    
                 INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                 SELECT 'B'  --01. �ڷᱸ��    
                       + CASE WHEN ISNULL(ComInfo.TaxOfficeNo, '') = '' THEN SPACE(3) ELSE ComInfo.TaxOfficeNo END  --02. �������ڵ�    
                       + '000001'                     --03. �Ϸù�ȣ    
                       + CONVERT(VARCHAR(10), REPLACE(ComInfo.TaxNo, '-', ''))                   --04. ����ڵ�Ϲ�ȣ    
                       + CONVERT(VARCHAR(40), LTRIM(RTRIM(CASE WHEN ISNULL(ComInfo.BillTaxName,'') <> '' THEN ComInfo.BillTaxName ELSE TaxName END )))    
                            + SPACE(40 - DATALENGTH(CONVERT(VARCHAR(40), LTRIM(RTRIM(CASE WHEN ISNULL(ComInfo.BillTaxName,'') <> '' THEN ComInfo.BillTaxName ELSE TaxName END )))))  --05. ���θ�(��ȣ)    
                       + CONVERT(VARCHAR(30), LTRIM(RTRIM(ComInfo.Owner))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(ComInfo.Owner))))) --06. ��ǥ��    
                       + CASE WHEN ISNULL(ComInfo.Zip, '') = '' THEN SPACE(10)    
                              ELSE CONVERT(VARCHAR(10), ComInfo.Zip) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), ComInfo.Zip)))  
                         END                      --07.�����ȣ    
                       + LTRIM(RTRIM(@Addr1)) + SPACE(70 - DataLength(CONVERT(VARCHAR(70), LTRIM(RTRIM(@Addr1)))))      --08. ����������    
                       + SPACE(60)    
                       , 230    
                   FROM #TDATaxUnit AS ComInfo WITH(NOLOCK)   
                  WHERE ComInfo.CompanySeq   = @CompanySeq  
                    AND ComInfo.TaxUnit      = @TaxUnit  
    /****************************************************************************************************************************/    
                --��꼭�հ�ǥ ���� ó��
                CREATE TABLE #TTAXBillSum (
                    CompanySeq          INT,
                    TaxTermSeq          INT,
                    TaxUnit             INT,
                    SMBuyOrSale         INT,
                    BizNo               NVARCHAR(200),
                    PersonId            NVARCHAR(200),
                    CustName            NVARCHAR(100),
                    BillCnt             INT,
                    SupplyAmt           DECIMAL(19,5),
                    VATAmt              DECIMAL(19,5),
                    IsEBill             NCHAR(1),
                    IsDelayBill         NCHAR(1),
                    CustSeq             INT)
                CREATE TABLE #TTAXBillSum2 (
                    CompanySeq      INT,
                    TaxTermSeq          INT,
                    TaxUnit             INT,
                    SMBuyOrSale         INT,
                    BizNo               NVARCHAR(200),
                    PersonId            NVARCHAR(200),
                    CustName            NVARCHAR(100),
                    BizKind             NVARCHAR(60),
                    BizType             NVARCHAR(60),                    
                    BillCnt             INT,
                    Amt                 DECIMAL(19,5),
                    VATAmt              DECIMAL(19,5),
                    IsEBill             NCHAR(1),
                    IsDelayBill         NCHAR(1),
                    CustSeq             INT)    
    
                --��꼭�հ�ǥ
                INSERT INTO #TTAXBillSum (CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, BillCnt, SupplyAmt, VATAmt, IsEBill, IsDelayBill,CustSeq)
                    SELECT A.CompanySeq, A.TaxTermSeq, A.TaxUnit, A.SMBuyOrSale, 
                           REPLACE(ISNULL(B.BizNo,''), '-', ''), 
                           CASE WHEN ISNULL(B.BizNo, '') = '' THEN ISNULL(dbo._FCOMDecrypt(B.PersonID, '_TDACust', 'PersonID', @CompanySeq),'') ELSE '' END,  
                           '' AS CustName, 
                           SUM(A.BillCnt), SUM(A.Amt), 0, 
                           ISNULL(A.IsEBill, '0'),
                           A.IsDelayBill, 
                           B.CustSeq
                       FROM _TTAXBillSum AS A WITH(NOLOCK)
                                 LEFT OUTER JOIN _TDACust  AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                                            AND A.CustSeq = B.CustSeq
                                                                            AND A.CustSerl = 0
                     WHERE A.CompanySeq     = @CompanySeq
                       AND A.TaxTermSeq     = @TaxTermSeq
                       AND A.TaxUnit        = @TaxUnit
                       AND A.CustSerl       = 0 ---------------------------------------- Hist������ ���� �ŷ�ó��
                     GROUP BY A.CompanySeq, A.TaxTermSeq, A.TaxUnit, A.SMBuyOrSale, 
                           REPLACE(ISNULL(B.BizNo,''), '-', ''), 
                           CASE WHEN ISNULL(B.BizNo, '') = '' THEN ISNULL(dbo._FCOMDecrypt(B.PersonID, '_TDACust', 'PersonID', @CompanySeq),'') ELSE '' END,
                           A.IsEBill, A.IsDelayBill, B.CustSeq

                INSERT INTO #TTAXBillSum (CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, BillCnt, SupplyAmt, VATAmt, IsEBill, IsDelayBill,CustSeq)
                    SELECT A.CompanySeq, A.TaxTermSeq, A.TaxUnit, A.SMBuyOrSale, 
                           REPLACE(ISNULL(B.BizNo,''), '-', ''), 
                           CASE WHEN ISNULL(B.BizNo, '') = '' THEN ISNULL(dbo._FCOMDecrypt(B.PersonID, '_TDACustTaxHist', 'PersonID', @CompanySeq),'') ELSE '' END,  
                           '' AS CustName, 
                           SUM(A.BillCnt), SUM(A.Amt), 0, 
                           ISNULL(A.IsEBill, '0'),
                           A.IsDelayBill,
                           B.CustSeq
                      FROM _TTAXBillSum AS A WITH(NOLOCK)
                                                JOIN _TDACustTaxHist AS B WITH(NOLOCK)
                                                  ON A.CompanySeq   = B.CompanySeq
                                                 AND A.CustSeq      = B.CustSeq
                                                 AND A.CustSerl     = B.HistSerl
                     WHERE A.CompanySeq     = @CompanySeq
                       AND A.TaxTermSeq     = @TaxTermSeq
                       AND A.TaxUnit        = @TaxUnit
                       AND A.CustSerl      <> 0 ---------------------------------------- Hist����
                     GROUP BY A.CompanySeq, A.TaxTermSeq, A.TaxUnit, A.SMBuyOrSale, 
                           REPLACE(ISNULL(B.BizNo,''), '-', ''), 
                           CASE WHEN ISNULL(B.BizNo, '') = '' THEN ISNULL(dbo._FCOMDecrypt(B.PersonID, '_TDACustTaxHist', 'PersonID', @CompanySeq),'') ELSE '' END, 
                           A.IsEBill, A.IsDelayBill,B.CustSeq
                --==================================================================================================================================
                -- E-Sero�Ű�� ���ڰ�꼭 ���� ���� + Upload���� INSERT 
                --==================================================================================================================================
                IF @Env4728 = '1'
                BEGIN
                    -- ��ǥ���� ���� ����
                    DELETE #TTAXBillSum WHERE IsEBill = '1'
                    
                    INSERT INTO #TTAXBillSum (CompanySeq, TaxTermSeq    , TaxUnit, SMBuyOrSale  , BizNo, 
                                              PersonId  , CustName      , BillCnt, SupplyAmt    , VATAmt,
                                              IsEBill   , IsDelayBill   , CustSeq)
                        SELECT @CompanySeq, @TaxTermSeq, @TaxUnit               , A.SMBuyOrSale     , CASE WHEN A.SMBuyOrSale = 4099001 THEN REPLACE(A.S_TaxNo, '-', '') ELSE REPLACE(A.R_TaxNo, '-', '') END,
                               ''         , ''         , COUNT(DISTINCT A.SetNo), SUM(A.SupplyAmt)  , SUM(A.VATAmt), 
                               '1'        , CASE WHEN A.TransDate >= B.OverDate THEN '1' ELSE '0' END, 0        -- CustSeq 0
                          FROM _TTAXElectronicBillUpload AS A WITH(NOLOCK)
                                    LEFT OUTER JOIN _TTAXOverTerm AS B WITH(NOLOCK) ON B.YearMonth   = LEFT(A.BillDate, 6)
                         WHERE A.CompanySeq     = @CompanySeq
                           AND (@TaxUnit = 0 OR A.TaxUnit = @TaxUnit)     
                           AND A.BillDate BETWEEN @BillFrDate AND @BillToDate
                         GROUP BY A.SMBuyOrSale, CASE WHEN A.SMBuyOrSale = 4099001 THEN REPLACE(A.S_TaxNo, '-', '') ELSE REPLACE(A.R_TaxNo, '-', '') END,
                                  CASE WHEN A.TransDate >= B.OverDate THEN '1' ELSE '0' END
                    -- ���������� �Ϲݰ�꼭 ó��
                    UPDATE #TTAXBillSum SET IsEBill = '0', IsDelayBill = '0' WHERE IsEBill = '1' AND IsDelayBill = '1'
                    
                
                END
                
                INSERT INTO #TTAXBillSum2 (CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, BillCnt, Amt, VATAmt, IsEBill, IsDelayBill, CustSeq)
                    SELECT CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, SUM(BillCnt), SUM(SupplyAmt), SUM(VATAmt), IsEBill, IsDelayBill, MAX(CustSeq)
                      FROM #TTAXBillSum
                     GROUP BY CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, IsEBill, IsDelayBill
                --------------------------------------------
                -- ���ڰ�꼭 11�� ���� ���ۺ� 
                --------------------------------------------
                UPDATE #TTAXBillSum2
                   SET IsEBill      = '0'
                 WHERE IsEBill      = '1'   -- ���ڰ�꼭
                   AND IsDelayBill  = '1'   -- �����Ⱓ ������ ������ 11�� ���� ���ۺ�
                
                UPDATE #TTAXBillSum2
                   SET CustName     = ISNULL(B.FullName        , ''),
                       BizKind      = ISNULL(B.BizKind         , ''),
                       BizType      = ISNULL(B.BizType         , '')
                  FROM #TTAXBillSum2 AS A JOIN _TDACust AS B WITH(NOLOCK)
                                            ON A.BizNo      = B.BizNo
                                           AND B.CompanySeq = @CompanySeq
                                           AND B.BizNo   <> ''
                UPDATE #TTAXBillSum2
           SET CustName     = ISNULL(B.FullName        , ''),
                       BizKind      = ISNULL(B.BizKind         , ''),
                       BizType      = ISNULL(B.BizType         , '')
                  FROM #TTAXBillSum2 AS A JOIN _TDACustTaxHist AS B WITH(NOLOCK)
                                            ON A.BizNo      = B.BizNo
                                           AND B.CompanySeq = @CompanySeq
                                           AND B.BizNo   <> ''
                 WHERE CustName     = ''

  
    /***************************************************************************************************************************    
    ��꼭 �հ�ǥ - ���ڰ�꼭 �� �����ǹ��ں����跹�ڵ�(����) 
        
    01. ���ڵ屸��(1) : C    
    02. �ڷᱸ��(2) : 17    
    03. �ⱸ��(1) : 1���̸� '1', 2���̸� '2'    
    04. �Ű���(1) : �����̸� '1', Ȯ���̸� '2'    
    05. ������(3)    
    06. �Ϸù�ȣ(6)    
    07. ����ڵ�Ϲ�ȣ(10)    
    08. �ͼӳ⵵(4)    
    09. �ŷ��Ⱓ���۳����(8)    
    10. �ŷ��Ⱓ��������(8)    
    11. �ۼ�����(8)    
    12. ����ó���հ�(6) : 16.����ڵ�Ϲ�ȣ����и���ó�� + 20.�ֹε�Ϲ�ȣ����и���ó��    
    13. ��꼭�ż��հ�(6) : 17.����ڵ�Ϲ�ȣ����а�꼭�ż� + 21.�ֹε�Ϲ�ȣ����а�꼭�ż�    
    14. ����(����)�ݾ��հ�����ǥ��(1) : ����ݾ��� ����� ��� '0', ������ ��� '1'    
    15. ����(����)�ݾ��հ�(14) : 19.����ڵ�Ϲ�ȣ����и���(����)�ݾ� + 23.�ֹε�Ϲ�ȣ����и���(����)�ݾ�    
    16. ����ڵ�Ϲ�ȣ����и���ó��(6)    
    17. ����ڵ�Ϲ�ȣ����а�꼭�ż�(6)    
    18. ����ڵ�Ϲ�ȣ����и���(����)�ݾ�����ǥ��(1) : ����ݾ��� ����� ��� '0', ������ ��� '1'    
    19. ����ڵ�Ϲ�ȣ����и���(����)�ݾ�(14)    
    20. �ֹε�Ϲ�ȣ����и���ó��(6)    
    21. �ֹε�Ϲ�ȣ����а�꼭�ż�(6)    
    22. �ֹε�Ϲ�ȣ����и���(����)�ݾ׾�����ǥ��(1) : ����ݾ��� ����� ��� '0', ������ ��� '1'    
    23. �ֹε�Ϲ�ȣ����и���(����)�ݾ�    
    24. ����(97)    
    ****************************************************************************************************************************/
    
                 IF EXISTS (SELECT 1 FROM #TTAXBillSum2 WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND SMBuyOrSale = 4099002)  
                 BEGIN    
                          INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                          SELECT 'C'                --01. ���ڵ屸��    
                                + '17'              --02. �ڷᱸ��    
                                + @TermKind_Bill    --03. �ⱸ��
                                + @ProOrFix_Bill    --04. �Ű���
                                + CASE WHEN ISNULL(ComInfo.TaxOfficeNo, '') = '' THEN SPACE(3) ELSE ComInfo.TaxOfficeNo END  --05. �������ڵ�    
                                + '000001'          --06. �Ϸù�ȣ    
                                + CONVERT(VARCHAR(10), REPLACE(ComInfo.TaxNo, '-', ''))     --07. ����ڵ�Ϲ�ȣ    
                                + SUBSTRING(@BillFrDate, 1, 4)      --08. �ͼӳ⵵    
                                + @BillFrDate                       --09. �ŷ��Ⱓ���۳����    
                                + @BillToDate                       --10. �ŷ��Ⱓ��������    
                                + @RptDate                          --11. ��������    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), COUNT(Bill.BizNo)), 6) --12. ����ó���հ�    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), ISNULL(SUM(Bill.BillCnt), 0)), 6)          --13. ��꼭 �ż��հ�    
                                + CASE WHEN SUM(Bill.Amt) > 0 THEN '0' ELSE '1' END           --14. ����(����)�ݾ��հ�����ǥ��    
                                + RIGHT('00000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(SUM(Bill.Amt)))), 14)      --15. ����(����)�ݾ��հ�    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(CASE WHEN Bill.BizNo <> '' THEN 1            ELSE 0 END)), 6)    --16. ����ڵ�Ϲ�ȣ����и���ó��    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(CASE WHEN Bill.BizNo <> '' THEN Bill.BillCnt ELSE 0 END)), 6)    --17. ����ڵ�Ϲ�ȣ����а�꼭�ż�    
                                + CASE WHEN SUM(CASE WHEN Bill.BizNo <> '' THEN Bill.Amt ELSE 0 END) >= 0 THEN '0' ELSE '1' END             --18. ����ڵ�Ϲ�ȣ����и���(����)�ݾ�����ǥ��    
                             + RIGHT('00000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(SUM(CASE WHEN Bill.BizNo <> '' THEN Bill.Amt  ELSE 0 END)))), 14) --19. ����ڵ�Ϲ�ȣ����и���(����)�ݾ�    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(CASE WHEN Bill.BizNo = '' THEN 1             ELSE 0 END)), 6)    --20. �ֹε�Ϲ�ȣ����и���ó��    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(CASE WHEN Bill.BizNo = '' THEN Bill.BillCnt  ELSE 0 END)), 6)    --21. �ֹε�Ϲ�ȣ����а�꼭�ż�    
                                + CASE WHEN SUM(CASE WHEN Bill.BizNo = '' THEN Bill.Amt   ELSE 0 END) >= 0 THEN '0' ELSE '1' END            --22. �ֹε�Ϲ�ȣ����и���(����)�ݾ�����ǥ��    
                                + RIGHT('00000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(SUM(CASE WHEN Bill.BizNo = '' THEN Bill.Amt   ELSE 0 END)))), 14) --23. �ֹε�Ϲ�ȣ����и���(����)�ݾ�    
                                + SPACE(97)    
                                , 230  
                          FROM   #TTAXBillSum2 AS Bill JOIN #TDATaxUnit AS ComInfo WITH(NOLOCK)
                                                        ON Bill.CompanySeq  = ComInfo.CompanySeq  
                                                       AND Bill.TaxUnit     = ComInfo.TaxUnit  
                          WHERE Bill.CompanySeq     = @CompanySeq  
                            AND Bill.TaxTermSeq     = @TaxTermSeq  
                            AND Bill.TaxUnit        = @TaxUnit  
                            AND Bill.SMBuyOrSale    = 4099002  
                            AND Bill.IsEBill       <> '1'  -- ���ڰ�꼭 �̿ܺ�
                          GROUP BY ComInfo.TaxOfficeNo, ComInfo.TaxNo  
  
    /***************************************************************************************************************************    
    ��꼭 �հ�ǥ - ���ڰ�꼭 �� ����ó���ŷ������ڵ�    
        
    01. ���ڵ屸��(1) : D    
    02. �ڷᱸ��(2) : 17    
    03. �ⱸ��(1) : 1���̸� '1', 2���̸� '2'    
    04. �Ű���(1) : �����̸� '1', Ȯ���̸� '2'    
    05. ������(3)    
    06. �Ϸù�ȣ(6)    
    07. ����ڵ�Ϲ�ȣ(10)    
    08. ����ó����ڵ�Ϲ�ȣ(10)    
    09. ����ó���θ�(��ȣ)(40)    
    10. ��꼭 �ż�(5)    
    11. ����(����)�ݾ�����ǥ��(1)    
    12. ����(����)�ݾ�    
    13. ����(136)    
    ****************************************************************************************************************************/    
                          INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                          SELECT 'D'     --01. ���ڵ屸��    
                                + '17'    --02. �ڷᱸ��    
                                + @TermKind_Bill  --03. �ⱸ��
                                + @ProOrFix_Bill  --04. �Ű���
                                + CASE WHEN ISNULL(ComInfo.TaxOfficeNo, '') = '' THEN SPACE(3) 
                                       ELSE CONVERT(VARCHAR(3), ComInfo.TaxOfficeNo) END   --05. �������ڵ�    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER(ORDER BY Bill.TaxUnit)), 6) --06. �Ϸù�ȣ    
                                + CONVERT(VARCHAR(10), REPLACE(ComInfo.TaxNo,'-','')) --07. ����ڵ�Ϲ�ȣ    
                                + CONVERT(VARCHAR(10), Bill.BizNo)  
                                      + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), Bill.BizNo))) --08. ����ó����ڵ�Ϲ�ȣ    
                                + LTRIM(RTRIM(CONVERT(VARCHAR(40), RTRIM(Bill.CustName) )))   
                                      + SPACE(40 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(40), RTRIM(Bill.CustName))))))     --09. �ŷ��ڻ�ȣ    
                                + RIGHT('00000' + CONVERT(VARCHAR(5), Bill.BillCnt), 5)                     --10. ��꼭 �ż�    
                                + CASE WHEN Bill.Amt >= 0 THEN '0' ELSE '1' END                             --11. ����(����)�ݾ�����ǥ��    
                                + RIGHT('0000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(Bill.Amt))), 14)   --12. ����(����)�ݾ�    
                                + SPACE(136)    
 , 230  
                          FROM #TTAXBillSum2 AS Bill JOIN #TDATaxUnit AS ComInfo WITH(NOLOCK)
                                                      ON Bill.CompanySeq    = ComInfo.CompanySeq  
                                                     AND Bill.TaxUnit       = ComInfo.TaxUnit  
                          WHERE Bill.CompanySeq     = @CompanySeq  
                            AND Bill.TaxTermSeq     = @TaxTermSeq  
                            AND Bill.TaxUnit        = @TaxUnit  
                            AND Bill.SMBuyOrSale    = 4099002       -- ����
                            AND Bill.BizNo         <> ''            -- ����ڵ�Ϲ�ȣ�����
                            AND Bill.ISEBill       <> '1'           -- ���ڰ�꼭 �̿ܺ�
                
    /***************************************************************************************************************************    
    ��꼭 �հ�ǥ - ���ڰ�꼭�� �����ǹ��ں� (����)��꼭 ���� 1
        
    01. ���ڵ屸��(1) : E    
    02. �ڷᱸ��(2) : 17 (����)
    03. �ⱸ��(1) : 1���̸� '1', 2���̸� '2'    
    04. �Ű���(1) : �����̸� '1', Ȯ���̸� '2'    
    05. ������(3)    
    06. �Ϸù�ȣ(6)    
    07. �����ǹ���(�����)����ڵ�Ϲ�ȣ(10)
    08. �ͼӳ⵵(4)
    09. �ŷ��Ⱓ���ۿ���(8)
    10. �Ÿ������������(8)
    11. �ۼ�����(8)
    -- /*�հ��*/
    12. ����ó��(6)
    13. ��꼭�ż�(6)
    14. ����(����)�ݾ� ����ǥ��(1)
    15. ����(����)�ݾ�(14)
    -- /*����ڵ�Ϲ�ȣ �߱޺�*/
    16. ����ó��(6)
    17. ��꼭�ż�(6)
    18. ����(����)�ݾ� ����ǥ��(1)
    19. ����(����)�ݾ�(14)
    -- /*�ֹε�Ϲ�ȣ �߱޺�*/
    20. ����ó��(6)
    21. ��꼭�ż�(6)
    22. ����(����)�ݾ� ����ǥ��(1)
    23. ����(����)�ݾ�(14)
    24. ����(97)   
    ****************************************************************************************************************************/                    
                 IF EXISTS (SELECT 1 FROM #TTAXBillSum2 WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND SMBuyOrSale = 4099002)  
                 BEGIN    
                          INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                          SELECT 'E'                --01. ���ڵ屸��    
                                + '17'              --02. �ڷᱸ��    
                                + @TermKind_Bill    --03. �ⱸ��  @cTermKind    
                                + @ProOrFix_Bill    --04. �Ű���  @cProOrFix    
                                + CASE WHEN ISNULL(ComInfo.TaxOfficeNo, '') = '' THEN SPACE(3) ELSE ComInfo.TaxOfficeNo END --05. �������ڵ�    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER(ORDER BY Bill.TaxUnit)), 6)        --06. �Ϸù�ȣ                                          
                                + CONVERT(VARCHAR(10), REPLACE(ComInfo.TaxNo, '-', ''))     --07. ����ڵ�Ϲ�ȣ    
                                + SUBSTRING(@BillFrDate, 1, 4)   --08. �ͼӳ��    
                                + @BillFrDate                    --09. �ŷ��Ⱓ���۳����    
                                + @BillToDate                    --10. �ŷ��Ⱓ��������    
                                + @RptDate                       --11. �ۼ�����                                       
                                + RIGHT('000000' + CONVERT(VARCHAR(6), COUNT(Bill.BizNo)), 6)                   --12. ����ó���հ�    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), ISNULL(SUM(Bill.BillCnt), 0)), 6)        --13. ��꼭 �ż��հ�    
                                + CASE WHEN SUM(Bill.Amt) > 0 THEN '0' ELSE '1' END                             --14. ����(����)�ݾ��հ�����ǥ��    
                                + RIGHT('00000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(SUM(Bill.Amt)))), 14) --15. ����(����)�ݾ��հ�    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(CASE WHEN Bill.BizNo <> '' THEN 1  
                                                                           ELSE 0 END)), 6)                         --16. ����ڵ�Ϲ�ȣ����и���ó��    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(CASE WHEN Bill.BizNo <> '' THEN Bill.BillCnt   
                                                                           ELSE 0 END)), 6)                         --17. ����ڵ�Ϲ�ȣ����а�꼭�ż�    
                                + CASE WHEN SUM(CASE WHEN Bill.BizNo <> '' THEN Bill.Amt   
                                                                 ELSE 0 END) >= 0 THEN '0' ELSE '1' END             --18. ����ڵ�Ϲ�ȣ����и���(����)�ݾ�����ǥ��    
                                + RIGHT('00000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(SUM(CASE WHEN Bill.BizNo <> '' THEN Bill.Amt   
                                                                                              ELSE 0 END)))), 14)   --19. ����ڵ�Ϲ�ȣ����и���(����)�ݾ�    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(CASE WHEN Bill.BizNo = '' THEN 1   
                                                                                ELSE 0 END)), 6)        --20. �ֹε�Ϲ�ȣ����и���ó��    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(CASE WHEN Bill.BizNo = '' THEN Bill.BillCnt   
                                                                                ELSE 0 END)), 6)        --21. �ֹε�Ϲ�ȣ����а�꼭�ż�    
                                + CASE WHEN SUM(CASE WHEN Bill.BizNo = '' THEN Bill.Amt   
                                                     ELSE 0 END) >= 0 THEN '0' ELSE '1' END             --22. �ֹε�Ϲ�ȣ����и���(����)�ݾ�����ǥ��    
                                + RIGHT('00000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(SUM(CASE WHEN Bill.BizNo = '' THEN Bill.Amt   
                                                                                                   ELSE 0 END)))), 14) --23. �ֹε�Ϲ�ȣ����и���(����)�ݾ�    
                                + SPACE(97)                       --24 ����
                                , 230  
                          FROM   #TTAXBillSum2 AS Bill JOIN #TDATaxUnit AS ComInfo WITH(NOLOCK)
                                                        ON Bill.CompanySeq  = ComInfo.CompanySeq  
                                                       AND Bill.TaxUnit     = ComInfo.TaxUnit  
                          WHERE Bill.CompanySeq     = @CompanySeq  
                            AND Bill.TaxTermSeq     = @TaxTermSeq  
                            AND Bill.TaxUnit        = @TaxUnit  
                            AND Bill.SMBuyOrSale    = 4099002       -- ����
                            AND Bill.IsEBill        = '1'           -- ���ڰ�꼭 ��
                          GROUP BY ComInfo.TaxOfficeNo, ComInfo.TaxNo, Bill.TaxUnit  
                END                          
            
            END--�����꼭 ����                 
                  
        
    /***************************************************************************************************************************    
    ��꼭 �հ�ǥ - ���ڰ�꼭 �� �����ǹ��ں����跹�ڵ�(����)    
        
    01. ���ڵ屸��(1) : C    
    02. �ڷᱸ��(2) : 18    
    03. �ⱸ��(1) : 1���̸� '1', 2���̸� '2'    
    04. �Ű���(1) : �����̸� '1', Ȯ���̸� '2'    
    05. ������(3)    
    06. �Ϸù�ȣ(6)    
    07. ����ڵ�Ϲ�ȣ(10)    
    08. �ͼӳ⵵(4)    
    09. �ŷ��Ⱓ���۳����(8)    
    10. �ŷ��Ⱓ��������(8)    
    11. �ۼ�����(8)    
    12. ����ó���հ�(6)    
    13. ��꼭�ż��հ�(6)    
    14. ���Աݾ��հ���ǥ��(1)    
    15. ���Աݾ��հ�(14)    
    16. ����(151)    
    ****************************************************************************************************************************/    
                 IF EXISTS (SELECT 1 FROM #TTAXBillSum2 WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND SMBuyOrSale = 4099001)    
                 BEGIN    
                          INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                          SELECT 'C'     --01. ���ڵ屸��    
                                + '18'    --02. �ڷᱸ��    
                                + @TermKind_Bill  --03. �ⱸ��
                                + @ProOrFix_Bill  --04. �Ű���
                                + CASE WHEN ISNULL(ComInfo.TaxOfficeNo, '') = '' THEN SPACE(3) ELSE ComInfo.TaxOfficeNo END  --05. �������ڵ�    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER(ORDER BY Bill.TaxUnit)), 6)    --06. �Ϸù�ȣ                                            
                                + CONVERT(VARCHAR(10), REPLACE(ComInfo.TaxNo,'-',''))                                   --07. ����ڵ�Ϲ�ȣ    
                                + SUBSTRING(@BillFrDate, 1, 4)  --08. �ͼӳ��    
                                + @BillFrDate                   --09. �ŷ��Ⱓ���۳����    
                                + @BillToDate                   --10. �ŷ��Ⱓ��������    
                                + @RptDate                      --11. �ۼ�����    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), COUNT(Bill.CustSeq)), 6)     --12. ����ó���հ�    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(Bill.BillCnt)), 6)       --13. ��꼭 �ż��հ�    
                                + CASE WHEN SUM(Bill.Amt) > 0 THEN '0' ELSE '1' END                 --14. ���Աݾ��հ�����ǥ��    
                                + RIGHT('00000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(SUM(Bill.Amt)))), 14)     --15. ���Աݾ��հ�    
                                + SPACE(151)    
                                , 230    
                          FROM #TTAXBillSum2 AS Bill JOIN #TDATaxUnit AS ComInfo WITH(NOLOCK)
                                                      ON Bill.CompanySeq    = ComInfo.CompanySeq  
                                                     AND Bill.TaxUnit       = ComInfo.TaxUnit  
                         WHERE Bill.CompanySeq  = @CompanySeq  
                           AND Bill.TaxTermSeq  = @TaxTermSeq  
                           AND Bill.TaxUnit     = @TaxUnit
                           AND Bill.SMBuyOrSale = 4099001       -- ����
                           AND Bill.BizNo      <> ''            -- ����ڵ�Ϲ�ȣ�����                           
                           AND Bill.ISEBill    <> '1'           -- ���ڰ�꼭 ��
                          GROUP BY ComInfo.TaxOfficeNo, ComInfo.TaxNo, Bill.TaxUnit  
        
        
    /***************************************************************************************************************************    
    ��꼭 �հ�ǥ - ���ڰ�꼭 �� ����ó���ŷ������ڵ�    
        
    01. ���ڵ屸��(1) : D    
    02. �ڷᱸ��(2) : 18    
    03. �ⱸ��(1) : 1���̸� '1', 2���̸� '2'    
    04. �Ű���(1) : �����̸� '1', Ȯ���̸� '2'    
    05. ������(3)    
    06. �Ϸù�ȣ(6)    
    07. ����ڵ�Ϲ�ȣ(10)    
    08. ����ó����ڵ�Ϲ�ȣ(10)    
    09. ����ó���θ�(��ȣ)(40)    
    10. ��꼭 �ż�(5)    
    11. ���Աݾ�����ǥ��(1)    
    12. ���Աݾ�    
    13. ����(136)    
    ****************************************************************************************************************************/    
                          INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                          SELECT 'D'     --01. ���ڵ屸��    
                                + '18'    --02. �ڷᱸ��    
                                + @TermKind_Bill  --03. �ⱸ��
                                + @ProOrFix_Bill  --04. �Ű���
                                + CASE WHEN ISNULL(ComInfo.TaxOfficeNo, '') = '' THEN SPACE(3) ELSE CONVERT(VARCHAR(3), ComInfo.TaxOfficeNo) END --05. �������ڵ�    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY Bill.TaxUnit)), 6)   --06. �Ϸù�ȣ                                          
                                + CONVERT(VARCHAR(10), REPLACE(ComInfo.TaxNo,'-','')) 
                                  + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), REPLACE(ComInfo.TaxNo,'-',''))))         --07. ����ڵ�Ϲ�ȣ
                                + CONVERT(VARCHAR(10), Bill.BizNo)
                                  + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), Bill.BizNo)) )          --08. ����ó����ڵ�Ϲ�ȣ
                                + CASE WHEN Bill.CustSeq = 0 THEN SPACE(40)
                                       ELSE LTRIM(RTRIM(CONVERT(VARCHAR(40), RTRIM(Bill.CustName))))   
                                            + SPACE(40 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(40), RTRIM(Bill.CustName))))))
                                  END                                                                       --09. ����ó���θ�(��ȣ)    
                                + RIGHT('00000' + CONVERT(VARCHAR(5), Bill.BillCnt), 5)                     --10. ��꼭 �ż�    
                                + CASE WHEN Bill.Amt >= 0 THEN '0' ELSE '1' END                             --11. ���Աݾ�����ǥ��    
                                + RIGHT('0000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(Bill.Amt))), 14)   --12. ���Աݾ�    
                                + SPACE(136)    
                                , 230    
                          FROM #TTAXBillSum2 AS Bill JOIN #TDATaxUnit AS ComInfo WITH(NOLOCK) 
                                                       ON Bill.CompanySeq    = ComInfo.CompanySeq  
                                                      AND Bill.TaxUnit       = ComInfo.TaxUnit  
                          WHERE Bill.CompanySeq     = @CompanySeq  
                            AND Bill.TaxTermSeq     = @TaxTermSeq  
                            AND Bill.TaxUnit        = @TaxUnit  
                            AND Bill.SMBuyOrSale    = 4099001           -- ���Ժ�
                            AND Bill.BizNo         <> ''                -- ����ڵ�Ϲ�ȣ�����                            
                            AND Bill.ISEBill       <> '1'               -- ���ڰ�꼭 ��
 
    /***************************************************************************************************************************    
    ��꼭 �հ�ǥ - ���ڰ�꼭�� �����ǹ��ں� (����)��꼭 ���� 2
        
    01. ���ڵ屸��(1) : E    
    02. �ڷᱸ��(2) : 18  (����)    
    03. �ⱸ��(1) : 1���̸� '1', 2���̸� '2'    
    04. �Ű���(1) : �����̸� '1', Ȯ���̸� '2'    
    05. ������(3)    
    06. �Ϸù�ȣ(6)    
    07. �����ǹ���(�����)����ڵ�Ϲ�ȣ(10)
    08. �ͼӳ⵵
    09. �ŷ��Ⱓ���ۿ���
    10. �Ÿ������������
    11. �ۼ�����
    -- /*�հ��*/
    12. ����ó��
    13. ��꼭�ż�
    14. ���Աݾ� ����ǥ��
    15. ���Աݾ�
    16. ����(151)   
    ****************************************************************************************************************************/  
                    IF EXISTS (SELECT 1 FROM #TTAXBillSum2 WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND SMBuyOrSale = 4099001)    
                    BEGIN    
                          INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                          SELECT 'E'              --01. ���ڵ屸��    
                                + '18'            --02. �ڷᱸ��    
                                + @TermKind_Bill  --03. �ⱸ��
                                + @ProOrFix_Bill  --04. �Ű���
                                + CASE WHEN ISNULL(ComInfo.TaxOfficeNo, '') = '' THEN SPACE(3) ELSE ComInfo.TaxOfficeNo END  --05. �������ڵ�    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY Bill.TaxUnit)), 6) --06. �Ϸù�ȣ   
                                + CONVERT(VARCHAR(10), REPLACE(ComInfo.TaxNo,'-',''))               --07. ����ڵ�Ϲ�ȣ    
                                + SUBSTRING(@BillFrDate, 1, 4)   --08. �ͼӳ��    
                                + @BillFrDate                    --09. �ŷ��Ⱓ���۳����    
                                + @BillToDate                    --10. �ŷ��Ⱓ��������    
                                + @RptDate                       --11. �ۼ�����    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), COUNT(Bill.CustSeq)), 6)     --12. ����ó���հ�    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(Bill.BillCnt)), 6)       --13. ��꼭 �ż��հ�    
                                + CASE WHEN SUM(Bill.Amt) > 0 THEN '0' ELSE '1' END                 --14. ���Աݾ��հ�����ǥ��    
                                + RIGHT('00000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(SUM(Bill.Amt)))), 14) --15. ���Աݾ��հ�    
                                + SPACE(151)    
                                , 230    
                            FROM #TTAXBillSum2 AS Bill JOIN #TDATaxUnit AS ComInfo WITH(NOLOCK)
                                                      ON Bill.CompanySeq    = ComInfo.CompanySeq  
                                                     AND Bill.TaxUnit       = ComInfo.TaxUnit  
                           WHERE Bill.CompanySeq  = @CompanySeq  
                             AND Bill.TaxTermSeq  = @TaxTermSeq  
                             AND Bill.TaxUnit     = @TaxUnit
                             AND Bill.SMBuyOrSale = 4099001     -- ����
                             AND Bill.BizNo      <> ''          -- ����ڵ�Ϲ�ȣ�����
                             AND Bill.ISEBill     = '1'         -- ���ڰ�꼭
                           GROUP BY ComInfo.TaxOfficeNo, ComInfo.TaxNo, Bill.TaxUnit
                    END                   
            END--���԰�꼭 ����    
    END--��꼭 ����    
END    
/***************************************************************************************************************************    
����������� A���ڵ�    
    
01. �ڷᱸ��_ǥ��(1) : A    
02. �ͼӳ��(6)    
03. �Ű���(1)    
04. ����ڵ�Ϲ�ȣ(10)    
05. ���θ�(30)    
06. ��ǥ�ڸ�(15)    
07. ����������(45)    
08. ���¸�(17)    
09. �����(25)    
10. �ŷ��Ⱓ(16)    
11. �ۼ�����(8)    
12. ����(6)    
****************************************************************************************************************************/    
    -- 1���� ��Ÿ������ �������̺� (_TTAXExpSalesSumEtc) by shkim1 2017.06 �ű� �߰�
    -- 2���� ȯ�漳�� 4735 ���� : 0
    -- 3���� ��ȭȹ����� ��Ÿ��
    -- 4���� ��Ÿ������ ����
DECLARE @EtcCnt         INT,  
        @EtcForAmt      DECIMAL(19,5),
        @EtcKorAmt      DECIMAL(19,5)
    IF EXISTS (SELECT TOP 1 1 FROM _TTAXExpSalesSumEtc WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxUnit = @TaxUnit AND TaxTermSeq = @TaxTermSeq)
    BEGIN
        SELECT @EtcCnt    = ISNULL(EtcCnt       , 0),
               @EtcForAmt = ISNULL(EtcForAmt    , 0),
               @EtcKorAmt = ISNULL(EtcKorAmt    , 0)
          FROM _TTAXExpSalesSumEtc AS A WITH(NOLOCK)
         WHERE CompanySeq = @CompanySeq
           AND TaxTermseq = @TaxTermSeq
           AND TaxUnit    = @TaxUnit
    END
    ELSE IF @Env4735 = '1'  -- [ȯ�漳��4735] ����������� �ݾ��� ��ȭȹ����� �ݾ����� �ڵ����� ����
    BEGIN
        SELECT @EtcCnt      = 0,
               @EtcForAmt   = 0,
               @EtcKorAmt   = 0
    END    
    ELSE IF EXISTS ( SELECT 1 FROM _TTaxForAmtReceiptList WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxUnit = @TaxUnit AND TaxTermSeq = @TaxTermSeq AND SMComboKind = 4116003 AND @Env4735 <> '1')
    BEGIN
        --��ȭȹ��������� �������� ���� �Է��ϴ� ���, �ش� �����͸� �������� ��Ÿ������ �ݾ��� ����ϵ��� �Ѵ�.
        -- (�������)
        SELECT  @EtcCnt         = COUNT(*),
                @EtcForAmt      = SUM(ISNULL(A.ForSupplyAmt,0)),
                @EtcKorAmt      = SUM(A.SupplyAmt)
          FROM _TTaxForAmtReceiptList AS A WITH(NOLOCK)
         WHERE A.CompanySeq   = @CompanySeq
           AND A.TaxTermseq   = @TaxTermSeq
           AND A.TaxUnit      = @TaxUnit   
           AND A.SMComboKind = 4116003      --��Ÿ�ΰ͸�
    END
    ELSE        -- ��Ÿ������ ���� ����
    BEGIN  
        -- ��Ÿ������ �Ǽ�, ��ȭ, ��ȭ  
        -- ������ ȯ�漳�� 4727 / _TTAXUpload �̻��
        SELECT  @EtcCnt         = COUNT(*),  
                @EtcForAmt      = SUM(ISNULL(CONVERT(MONEY, R.RemValText), 0)) ,
                @EtcKorAmt      = SUM(A.SupplyAmt)  
          FROM _TTAXSlipSum AS A WITH(NOLOCK)
                                 JOIN _TDAEvid AS B WITH(NOLOCK)
                                   ON B.CompanySeq  = A.CompanySeq 
                                  AND B.EvidSeq     = A.EvidSeq   
                                  AND B.IsVATRpt    = '1'       -- �ΰ����Ű�  
                                  AND B.SMTaxKind   = 4114004   -- ��Ÿ������
                                  AND B.SMEvidKind <> 4115001   -- ���ݰ�꼭 X
                             AND B.IsNDVAT    <> '1'       -- �Ұ���     X
                                  AND B.IsAsstBuy  <> '1'       -- �����ڻ���Ժ� X
                                 JOIN _TDAAccount AS C WITH(NOLOCK) 
                                   ON C.CompanySeq  = A.CompanySeq
                                  AND C.AccSeq      = A.AccSeq
                                  AND C.SMAccKind   = 4018002   --��ä����(�ΰ���������)
                      LEFT OUTER JOIN _TACSlipRem AS R WITH(NOLOCK)
                                   ON R.CompanySeq  = A.CompanySeq      
                                  AND R.SlipSeq     = A.SlipSeq        
                                  AND R.RemSeq      = 3113 
         WHERE A.CompanySeq     = @CompanySeq  
           AND A.TaxTermSeq     = @TaxTermSeq  
           AND A.TaxUnit        = @TaxUnit  
   END
   
    SELECT @EtcCnt      = ISNULL(@EtcCnt        , 0),  
           @EtcForAmt   = ISNULL(@EtcForAmt     , 0),  
           @EtcKorAmt   = ISNULL(@EtcKorAmt     , 0)  
             
IF @WorkingTag IN ('', 'A')  
BEGIN  
    IF ISNULL(@EtcCnt, 0) <> 0 OR EXISTS (SELECT 1 FROM _TSLExpSalesSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
    BEGIN  
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT 'A'       --01. �ڷᱸ��    
                   + LEFT(@TaxToDate, 6)    --02.�ͼӳ��    
                   + CASE WHEN DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) <  3 THEN CONVERT(VARCHAR(1), DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) + 1) -- 1:1����, 2:2����, 3:3����, 4:4~6����    
                          WHEN DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) >= 3 OR DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) <= 6 THEN '4'    
                      END                                   --03. �Ű���
                   + REPLACE(RTRIM(A.TaxNo), '-', '')       --04. ����ڵ�Ϲ�ȣ    
                   + CONVERT(VARCHAR(30), LTRIM(RTRIM(CASE WHEN ISNULL(A.BillTaxName,'') <> '' THEN A.BillTaxName ELSE A.TaxName END )))    
                             + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(CASE WHEN ISNULL(A.BillTaxName,'') <> '' THEN A.BillTaxName ELSE A.TaxName END )))))  --05. ��ȣ    
                   + CONVERT(VARCHAR(15), LTRIM(RTRIM(A.Owner))) + SPACE(15 - DATALENGTH(CONVERT(VARCHAR(15), LTRIM(RTRIM(A.Owner)))))              --06. ��ǥ��    
                   + CONVERT(VARCHAR(45), LTRIM(RTRIM(A.VATRptAddr))) + SPACE(45 - DATALENGTH(CONVERT(VARCHAR(45), LTRIM(RTRIM(A.VATRptAddr)))))    --07. ����������    
                   + CONVERT(VARCHAR(17), LTRIM(RTRIM(A.BizType   ))) + SPACE(17 - DATALENGTH(CONVERT(VARCHAR(17), LTRIM(RTRIM(A.BizType   )))))    --08. ���¸�    
                   + CONVERT(VARCHAR(24), LTRIM(RTRIM(A.BizItem   ))) + SPACE(25 - DATALENGTH(CONVERT(VARCHAR(24), LTRIM(RTRIM(A.BizItem   )))))    --09. �����    
                   + @TaxFrDate + @TaxToDate                --10. �ŷ��Ⱓ    
                   + @RptDate                               --11. �ۼ�����    
                   + SPACE(6)    
                   , 180    
            FROM #TDATaxUnit A WITH(NOLOCK)
            WHERE A.CompanySeq  = @CompanySeq  
              AND A.TaxUnit     = @TaxUnit  
  
    /***************************************************************************************************************************    
    ����������� B���ڵ�    
        
    01. �ڷᱸ��_�հ�(1) : B    
    02. �ͼӳ��(6)    
    03. �Ű���(1)    
    04. ����ڵ�Ϲ�ȣ(10)    
    05. �Ǽ��հ�(7)    
    06. ��ȭ�ݾ��հ�(15, 2) : Multi-Key+�Ǽ�����   
    07. ��ȭ�ݾ��հ�(15) : Multi-Key+�Ǽ�����   
    08. �Ǽ�_��ȭ(7)    
    09. ��ȭ�ݾ��հ�_��ȭ(15, 2) : Multi-Key+�Ǽ�����   
    10. ��ȭ�ݾ��հ�_��ȭ(15) : Multi-Key+�Ǽ�����   
    11. �Ǽ�_��Ÿ(7)    
    12. ��ȭ�ݾ��հ�_��Ÿ(15, 2) : Multi-Key+�Ǽ�����   
    13. ��ȭ�ݾ��հ�_��Ÿ(15) : Multi-Key+�Ǽ�����   
    14. ����(51)    
    ****************************************************************************************************************************/    
  
             CREATE TABLE #ExpSalesSum (  
                SourceRefNo         NVARCHAR(30),  
                ExpDate             NCHAR(8),  
                CurrSeq             INT,  
                ExRate              DECIMAL(19,5),  
                CurAmt              DECIMAL(19,5),  
                DomAmt              DECIMAL(19,5),  
                SMSalesType         INT)  
  
             INSERT INTO #ExpSalesSum ( SourceRefNo, ExpDate, CurrSeq, ExRate, CurAmt, DomAmt, SMSalesType)  
                SELECT A.SourceRefNo, A.ExpDate, A.CurrSeq,   
                       CASE WHEN ISNULL(B.BasicAmt, 0) = 0 THEN A.ExRate ELSE ROUND(A.ExRate / B.BasicAmt, 5) END AS ExRate,
                       SUM(ROUND(A.CurAmt,2)), SUM(A.DomAmt),   
                       CASE WHEN ISNULL(A.SMSalesType, 0) = 0 THEN 4116001 ELSE SMSalesType END  
                  FROM _TSLExpSalesSum AS A WITH(NOLOCK) 
                                            JOIN _TDACurr AS B WITH(NOLOCK) 
                                              ON A.CompanySeq   = B.CompanySeq  
                                             AND A.CurrSeq      = B.CurrSeq  
                 WHERE A.CompanySeq   = @CompanySeq  
                   AND A.TaxTermSeq   = @TaxTermSeq  
                   AND A.TaxUnit      = @TaxUnit  
                 GROUP BY A.SourceRefNo, A.ExpDate, A.CurrSeq, A.SMSalesType,   
                          CASE WHEN ISNULL(B.BasicAmt, 0) = 0 THEN A.ExRate ELSE ROUND(A.ExRate / B.BasicAmt, 5) END
  
             SELECT @T_Cnt = COUNT(*), @T_CurAmt = ROUND(SUM(CurAmt), 2), @T_DomAmt = SUM(DomAmt)   --------------- ��ü  
               FROM #ExpSalesSum   
              WHERE SMSalesType    IN (4116001, 4116002) -- ��ȭ/��Ÿ  
  
             SELECT @A_Cnt = COUNT(*), @A_CurAmt = ROUND(SUM(CurAmt), 2), @A_DomAmt = SUM(DomAmt)   --------------- ��ȭ  
               FROM #ExpSalesSum   
              WHERE SMSalesType     = 4116001 -- ��ȭ  
  
    --         SELECT @B_Cnt = COUNT(*), @B_CurAmt = SUM(CurAmt), @B_DomAmt = SUM(DomAmt)   --------------- ��Ÿ  
    --           FROM #ExpSalesSum   
    --          WHERE SMSalesType     = 4116003 -- ��Ÿ  
  
            -- �Ʒ��� ���� ������ : ��¹��� ��Ÿ�������� ������ �������� ��Ÿ������ ����  
            SELECT @B_Cnt = ISNULL(@EtcCnt, 0), @B_CurAmt = ROUND(ISNULL(@EtcForAmt, 0), 2), @B_DomAmt = ISNULL(@EtcKorAmt, 0)  
  
  
            SELECT @T_Cnt = ISNULL(@T_Cnt, 0), @T_CurAmt = ISNULL(@T_CurAmt, 0), @T_DomAmt = ISNULL(@T_DomAmt, 0),  
                   @A_Cnt = ISNULL(@A_Cnt, 0), @A_CurAmt = ISNULL(@A_CurAmt, 0), @A_DomAmt = ISNULL(@A_DomAmt, 0),  
                   @B_Cnt = ISNULL(@B_Cnt, 0), @B_CurAmt = ISNULL(@B_CurAmt, 0), @B_DomAmt = ISNULL(@B_DomAmt, 0)  
  
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT 'B'       --01. �ڷᱸ��    
                   + LEFT(@TaxToDate, 6)    --02.�ͼӳ��    
                   + CASE WHEN DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) <  3 THEN CONVERT(VARCHAR(1), DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) + 1) -- 1:1����, 2:2����, 3:3����, 4:4~6����    
                          WHEN DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) >= 3 OR DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) <= 6 THEN '4'    
                     END                                -- 03. �Ű���     
                   + REPLACE(RTRIM(@TaxNo), '-', '')    -- 04. ����ڵ�Ϲ�ȣ
                   + RIGHT('0000000' + CONVERT(VARCHAR(7), @T_Cnt + @B_Cnt), 7) --05. �Ǽ��հ�    
                   + CASE WHEN @T_CurAmt + @B_CurAmt >= 0 THEN  
                                RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(DECIMAL(19,2), @T_CurAmt + @B_CurAmt)), '.', ''), 15)  
                          ELSE   
                            CASE RIGHT(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), 1)    
                                 WHEN '0' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, '}')    
                                 WHEN '1' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, 'J')    
                                 WHEN '2' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, 'K')    
                                 WHEN '3' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, 'L')    
                                 WHEN '4' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, 'M')    
                                 WHEN '5' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, 'N')    
                                 WHEN '6' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, 'O')    
                                 WHEN '7' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, 'P')    
                                 WHEN '8' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, 'Q')    
                                 WHEN '9' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, 'R')   
                            END    
                      END                            --06. ��ȭ�ݾ��հ�    
                   + CASE WHEN @T_DomAmt + @B_DomAmt >= 0 THEN    
                            RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(@T_DomAmt + @B_DomAmt)), 15)    
                      ELSE    
                            CASE RIGHT(CONVERT(VARCHAR(15), FLOOR(@T_DomAmt + @B_DomAmt)), 1)    
                                 WHEN '0' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, '}')    
                                 WHEN '1' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, 'J')    
                                 WHEN '2' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, 'K')    
                                 WHEN '3' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, 'L')    
                                 WHEN '4' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, 'M')    
                                 WHEN '5' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, 'N')    
                                 WHEN '6' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, 'O')    
                                 WHEN '7' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, 'P')    
                                 WHEN '8' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, 'Q')    
                                 WHEN '9' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, 'R')    
                            END    
                      END                            --07. ��ȭ�ݾ��հ�    
                   + RIGHT('0000000' + CONVERT(VARCHAR(7), @A_Cnt), 7)        --08. �Ǽ�_��ȭ    
                   + CASE WHEN @A_CurAmt >= 0 THEN    
                            RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), @A_CurAmt)), '.', ''), 15)    
                      ELSE    
                            CASE RIGHT(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), 1)    
                                 WHEN '0' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, '}')    
                                 WHEN '1' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, 'J')    
                                 WHEN '2' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, 'K')    
                                 WHEN '3' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, 'L')    
                                 WHEN '4' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, 'M')    
                                 WHEN '5' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, 'N')    
                                 WHEN '6' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, 'O')    
                   WHEN '7' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, 'P')    
                                 WHEN '8' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, 'Q')    
                                 WHEN '9' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, 'R')    
                            END    
                      END                            --09. ��ȭ�ݾ��հ�_��ȭ    
                   + CASE WHEN @A_DomAmt >= 0 THEN    
                            RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(@A_DomAmt)), 15)    
                      ELSE    
                            CASE RIGHT(CONVERT(VARCHAR(15), FLOOR(@A_DomAmt)), 1)    
                                 WHEN '0' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, '}')    
                                 WHEN '1' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, 'J')    
                                 WHEN '2' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, 'K')    
                                 WHEN '3' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, 'L')    
                                 WHEN '4' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, 'M')    
                                 WHEN '5' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, 'N')    
                                 WHEN '6' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, 'O')    
                                 WHEN '7' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, 'P')    
                                 WHEN '8' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, 'Q')    
                                 WHEN '9' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, 'R')    
                            END    
                      END                            --10. ��ȭ�ݾ��հ�_��ȭ    
                   + RIGHT('0000000' + CONVERT(VARCHAR(7), @B_Cnt), 7)        --11. �Ǽ�_��Ÿ    
                   + CASE WHEN @B_CurAmt >= 0 THEN    
                            RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), @B_CurAmt)), '.', ''), 15)    
                      ELSE    
                            CASE RIGHT(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), 1)    
                                 WHEN '0' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, '}')    
                                 WHEN '1' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, 'J')    
                                 WHEN '2' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, 'K')    
                                 WHEN '3' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, 'L')    
                                 WHEN '4' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, 'M')    
                                 WHEN '5' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, 'N')    
                                 WHEN '6' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, 'O')    
                                 WHEN '7' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, 'P')    
                                 WHEN '8' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, 'Q')    
                                 WHEN '9' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, 'R')    
                            END    
                      END                            --12. ��ȭ�ݾ��հ�_��Ÿ    
                   + CASE WHEN @B_DomAmt >= 0 THEN    
                            RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(@B_DomAmt)), 15)    
                      ELSE    
                            CASE RIGHT(CONVERT(VARCHAR(15), FLOOR(@B_DomAmt)), 1)    
                                 WHEN '0' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, '}')    
                                 WHEN '1' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, 'J')    
                                 WHEN '2' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, 'K')    
                                 WHEN '3' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, 'L')    
                                 WHEN '4' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, 'M')    
                                 WHEN '5' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, 'N')    
                                 WHEN '6' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, 'O')    
                                 WHEN '7' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, 'P')    
                                 WHEN '8' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, 'Q')    
                                 WHEN '9' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, 'R')    
                            END    
                      END                            --13 ��ȭ�ݾ��հ�_��Ÿ    
                   + SPACE(51)    
                   , 180    
        
    /***************************************************************************************************************************    
    ����������� C���ڵ�    
        
    01. �ڷᱸ��_�ڷ�(1) : C    
    02. �ͼӳ��(6)    
    03. �Ű���(1)    
    04. ����ڵ�Ϲ�ȣ(10)    
    05. �����Ϸù�ȣ(7)    
    06. ����Ű��ȣ(15)    
    07. ��������(8)    
    08. ������ȭ�ڵ�(3)    
    09. ȯ��(9, 4)    
    10. ��ȭ�ݾ�(15, 2)    
    11. ��ȭ�ݾ�(15)    
    12. ����(90)    
    ****************************************************************************************************************************/    
  
                 INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                 SELECT 'C'       --01. �ڷᱸ��    
                       + LEFT(@TaxToDate, 6)    --02.�ͼӳ��    
                       + CASE WHEN DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) <  3 THEN CONVERT(VARCHAR(1), DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) + 1) -- 1:1����, 2:2����, 3:3����, 4:4~6����    
                              WHEN DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) >= 3 OR DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) <= 6 THEN '4'    
                          END                           --03. �Ű���
                       + REPLACE(@TaxNo, '-', '')       --04. ����ڹ�ȣ
                       + RIGHT('0000000' + CONVERT(VARCHAR(7), ROW_NUMBER() OVER (ORDER BY A.SourceRefNo)), 7)  
                       + CONVERT(VARCHAR(15), REPLACE(RTRIM(A.SourceRefNo), '-', '')) + SPACE(15 - DATALENGTH(CONVERT(VARCHAR(15), REPLACE(RTRIM(A.SourceRefNo), '-', '')))) --06. ����Ű��ȣ    
                       + CASE WHEN A.ExpDate = '' THEN SPACE(8) ELSE A.ExpDate END              --07. ��������    
                       + CASE A.CurrSeq WHEN @StkCurrSeq THEN @KorCurrNo ELSE B.CurrName END    --08. ������ȭ�ڵ�
                       + RIGHT('000000000' + REPLACE(CONVERT(VARCHAR(9), CONVERT(NUMERIC(19, 4), A.ExRate)), '.', ''), 9) --09. ȯ��    
                       + CASE WHEN A.CurAmt >= 0 THEN    
                                RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), A.CurAmt)), '.', ''), 15)    
                          ELSE    
                                CASE RIGHT(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), 1)    
                                     WHEN '0' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, '}')    
                                     WHEN '1' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, 'J')    
                                     WHEN '2' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, 'K')    
                                     WHEN '3' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, 'L')    
                                     WHEN '4' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, 'M')    
                                     WHEN '5' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, 'N')    
                                     WHEN '6' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, 'O')    
                                     WHEN '7' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, 'P')    
                                     WHEN '8' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, 'Q')    
                                     WHEN '9' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, 'R')    
                                END    
                          END                      --10. ��ȭ�ݾ��հ�    
                       + CASE WHEN A.DomAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(A.DomAmt)), 15)    
                          ELSE    
                                CASE RIGHT(CONVERT(VARCHAR(15), FLOOR(A.DomAmt)), 1)    
                                     WHEN '0' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, '}')    
                                     WHEN '1' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, 'J')    
                                     WHEN '2' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, 'K')    
                                     WHEN '3' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, 'L')    
                                     WHEN '4' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, 'M')    
                                     WHEN '5' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, 'N')    
                                     WHEN '6' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, 'O')    
                                     WHEN '7' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, 'P')    
                                     WHEN '8' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, 'Q')    
                                     WHEN '9' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, 'R')    
                                END    
                          END                      --11. ��ȭ�ݾ��հ�    
                       + SPACE(90)    
                       , 180  
                 FROM  #ExpSalesSum  AS A LEFT OUTER JOIN _TDACurr AS B WITH(NOLOCK)
                                            ON B.CompanySeq = @CompanySeq  
                                           AND A.CurrSeq    = B.CurrSeq  
                WHERE A.SMSalesType = 4116001   
    END  
END  
  
  

/***************************************************************************************************************************    
�ſ�ī�������ǥ��������_Header        SATCardDisket�� ���� �����ؾ���    
    
01. ���ڵ屸��(2) : HL    
02. �ͼӳ⵵(4)    
03. �ݱⱸ��(1) : '1' 1��, '2' 2��    
04. �ݱ⳻������(1) : 1,2,3,4,5,6    ��, �����Ű�� '3', Ȯ���Ű�� '6'    
05. ������(������)����ڵ�Ϲ�ȣ(10)    
06. ��ȣ(���θ�)(60)    
07. ����(��ǥ��)(30)    
08. ���ε�Ϲ�ȣ(13)    
09. ��������(8)    
10. ����(11)    
****************************************************************************************************************************/    
----------------------------------------------------------------------------------------    
-- 20080123 by Him    
-- ////4. ����� �ſ�ī�忡 ���� ���Լ��װ��� ����ȭ(2007.2�� Ȯ���Ű����)    
-- //// �� ���λ���ڰ� ����� �ſ�ī�带 ���ݿ����� Ȩ�������� ����ϰ� ����ϸ� ����� �����Ͽ� �ſ�ī��� �����п� ���� ���Լ��� ������ ���� 
-- //// �� ���ſ�ī�������ǥ �� ��������� �ۼ��� �ŷ�ó�� ���� �ۼ����� �ƴ��ϰ� ��ü �������ݾ׸��� �����Ͽ� �Ű�    
-- //// ��  ���θ��Ƿ� �ſ�ī�带 �߱޹��� ���λ���ڴ� ������ ������� ���� ����    
-- //// ��  �Ű��� : ���ݿ����� Ȩ���������� �ſ�ī�� ��볻���� ��ȸ�Ͽ� ���� �� �Ұ�����  ������ �� �������� �ݾ��� �հ���� 
-- //// ��  "�ſ�ī�� ������ǥ �� �������" ��ȭ�������� ����ī����� �����Ͽ� �Ű���(���� ���� ��������)    
-- //// �� �Ű�Ⱓ �� �ŷ��Ǽ� 1,000�� �̻��ڴ� ���Ҽ����� ���μ������� Ȯ���Ͽ��� ��    
    
-- 20080407 by kspark    
-- ////5. �ſ�ī�������ǥ �� ������� ���� ����(��Ģ ��13ȣ ����, �Թ����� ��)    
-- //// �� �ſ�ī�� �� ���Գ��� ������� �ۼ���� 4.�����ſ�ī�� �߰�    
-- //// �� 2008�� 1�� �����Ű��ϴ� �к��� ����    
  
    SELECT @SaleCnt = ISNULl(SaleCnt    , 0),  
           @SupAmt  = ISNULL(SupAmt     , 0),  
           @TaxAmt  = ISNULL(TaxAmt     , 0)  
      FROM _TTAXGetCardList WITH(NOLOCK)
     WHERE CompanySeq   = @CompanySeq  
       AND TaxTermSeq   = @TaxTermSeq  
       AND TaxUnit      = @TaxUnit  
  
    SELECT @SaleCnt = ISNULL(@SaleCnt   , 0),  
           @SupAmt  = ISNULL(@SupAmt    , 0),  
           @TaxAmt  = ISNULL(@TaxAmt    , 0)  
  
----------------------------------------------------------------------------------------    
IF @WorkingTag IN ('','J')  
BEGIN  
    -- ������ �������� �Ű� ������ ����    
    IF EXISTS (SELECT 1 FROM _TTAXReceiptCardSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
        OR (ISNULL(@SaleCnt, 0) > 0)   -- �ſ�ī�� ������ ȭ����ۺ���ī��    
    BEGIN    
            INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
            SELECT 'HL'                                 --01.���ڵ屸��    
                    + SUBSTRING(@TaxFrDate, 1, 4)       --02. �ͼӳ⵵    
                    + @TermKind                         --03.�ݱⱸ��    
                    + @YearHalfMM                       --04.�ݱ⳻������    
                    + CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '')) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '')))) --05.������(������)����ڵ�Ϲ�ȣ    
                    + CONVERT(VARCHAR(60), LTRIM(RTRIM(CASE WHEN ISNULL(BillTaxName,'') <> '' THEN BillTaxName ELSE TaxName END)))  
                              + SPACE(60 - DATALENGTH(CONVERT(VARCHAR(60), LTRIM(RTRIM(CASE WHEN ISNULL(BillTaxName,'') <> '' THEN BillTaxName ELSE TaxName END)))))   --06.��ȣ(���θ�)    
                    + CONVERT(VARCHAR(30), LTRIM(RTRIM(Owner))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(Owner)))))     --07.����(��ǥ��)    
                    + LTRIM(RTRIM(@CompanyNo)) + SPACE(13 - DATALENGTH(LTRIM(RTRIM(@CompanyNo))))                                       --08.���ε�Ϲ�ȣ    
                    + LTRIM(RTRIM(CONVERT(VARCHAR(8), @RptDate))) + SPACE(8 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8), @RptDate)))))  --09.��������    
                    + SPACE(11)                                                                                                         --10.����    
                    , 140  
              FROM #TDATaxUnit WITH(NOLOCK)
             WHERE CompanySeq   = @CompanySeq  
               AND TaxUnit      = @TaxUnit  
        
    /***************************************************************************************************************************    
    �ſ�,����ī�� �� ���� ����ī�� ������ǥ �����    SATCardDisket�� ���� �����ؾ���    
        
    01. ���ڵ屸��(2) : DL    
    02. �ͼӳ⵵(4)    
    03. �ݱⱸ��(1) : '1' 1��, '2' 2��    
    04. �ݱ⳻������(1) : 1,2,3,4,5,6    ��, �����Ű�� '3', Ȯ���Ű�� '6'    
    05. ������(������)����ڵ�Ϲ�ȣ(10)    
    06. ī�屸��(1)    *** �ſ�ī�� �� ����ī�� = '1' , ���ݿ����� = '2' , ȭ����ۺ���ī�� = '3' , �����ſ�ī�� = '4'    
    07. ī��ȸ����ȣ(20)    
    08. ������ ����ڵ�Ϲ�ȣ(10)    
    09. �ŷ��Ǽ�(9)    *** ī�屸�� '1' = �ͼӱⰣ�� ���� �ſ�ī�� �� ����ī���� ī���ȣ�� ���� �����ڿ� �ŷ��� �ŷ��Ǽ��� ī���ȣ��,�����ڻ���ڵ�Ϲ�ȣ �� ����    
                           ī�屸�� '2' = ���ݿ��������� �ŷ��� ��ü �ŷ� �Ǽ��� ����    
                           ī�屸�� '3' = ȭ����ۺ���ī��� �ŷ��� ��ü�ŷ��Ǽ��� ����    
                           ī�屸�� '4' = �����ſ�ī��� �ŷ��� ��ü�ŷ��Ǽ��� ����    
        
    10. ���ް���_����ǥ��(1)    
    11. ���ް���(13)    
    12. ����_����ǥ��(1)    
    13. ����(13)    
    14. ����(54)    
    ****************************************************************************************************************************/    
    -- �ſ�ī�� ����    
        DECLARE @DLCnt INT    -- TL�� DL ���ڵ� �� 06. DATA�Ǽ�    
  
    ------------------------------------
    -- ���ܰǼ�ó��
    ------------------------------------
    DECLARE @MinusCashCnt   INT,
            @MinusBizCnt    INT,
            @MinusCardCnt   INT,
            @MinusEntryCnt  INT
    -- ���� �� ���ܰǼ� (�ŷ�ó��, ī�庰 ����)
    CREATE TABLE #CardMinus(
        CustSeq     INT,
        CardSeq     INT,
        MinusCnt    INT
    )
    SELECT @MinusCardCnt  = SUM( CASE WHEN SMCardType = 4590001 THEN MinusCnt ELSE 0 END ), -- �ſ�ī�� �� ����ī��
           @MinusCashCnt  = SUM( CASE WHEN SMCardType = 4590002 THEN MinusCnt ELSE 0 END ), -- ���ݿ�����
           @MinusEntryCnt = SUM( CASE WHEN SMCardType = 4590003 THEN MinusCnt ELSE 0 END ), -- ȭ����ۺ���ī��
           @MinusBizCnt   = SUM( CASE WHEN SMCardType = 4590004 THEN MinusCnt ELSE 0 END )  -- �����ſ�ī��
      FROM _TTAXCardMinusCnt AS A WITH(NOLOCK)
     WHERE A.CompanySeq = @CompanySeq
       AND A.TaxUnit    = @TaxUnit
       AND A.TaxTermSeq = @TaxTermSeq
    SELECT @MinusCardCnt  = ISNULL(@MinusCardCnt  , 0),
           @MinusCashCnt  = ISNULL(@MinusCashCnt  , 0),
           @MinusEntryCnt = ISNULL(@MinusEntryCnt , 0),
           @MinusBizCnt   = ISNULL(@MinusBizCnt   , 0)
    INSERT INTO #CardMinus(CustSeq, CardSeq, MinusCnt)
    SELECT CustSeq, CardSeq, SUM(MinusCnt)
      FROM _TTAXCardMinusCnt AS A WITH(NOLOCK)
     WHERE A.CompanySeq = @CompanySeq
       AND A.TaxUnit    = @TaxUnit
       AND A.TaxTermSeq = @TaxTermSeq
       AND A.SMCardType = 4590001       -- �ſ�ī�� �� ����ī��
     GROUP BY CustSeq, CardSeq
    ------------------------------------
    -- ���ܰǼ�ó�� END
    ------------------------------------
    ------------------------------------------
    -- ī�屸�� : �ſ�ī�� �� ����ī��(1)
    ------------------------------------------
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
        SELECT 'DL'                                     --01.���ڵ屸��    
                + SUBSTRING(@TaxFrDate, 1, 4)           --02.�ͼӳ⵵    
                + @TermKind                             --03.�ݱⱸ��    
                + @YearHalfMM                           --04.�ݱ⳻������    
                + CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(T.TaxNo, '-', '')))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(T.TaxNo, '-', '')))))) --05.������(������)����ڵ�Ϲ�ȣ    
                + '1'                                   -- 06.ī�屸�� (�ſ�ī�� �� ����ī��)
                + CONVERT(VARCHAR(20), LTRIM(RTRIM(REPLACE(dbo._FCOMDecrypt(A.CardNo, '_TTAXReceiptCardSum', 'CardNo', @CompanySeq), '-', '')))) + SPACE(20 - DATALENGTH(CONVERT(VARCHAR(20), LTRIM(RTRIM(REPLACE(dbo._FCOMDecrypt(A.CardNo, '_TTAXReceiptCardSum', 'CardNo', @CompanySeq), '-', ''))))))   --07. ī��ȸ����ȣ    
                + CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(C.BizNo , '-', '')))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(C.BizNo , '-', ''))))))   --08. ������(������) ����ڵ�Ϲ�ȣ    
                + RIGHT('000000000' + CONVERT(VARCHAR(9), (COUNT(A.SlipSeq) - ISNULL(M.MinusCnt, 0)) ), 9)   --09.�ŷ��Ǽ�    
                + CASE WHEN SUM( A.SupplyAmt  ) >= 0 THEN ' ' ELSE '-' END                                   --10.���ް��� ����ǥ��(��� Space/���� -)    
                + RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM( A.SupplyAmt )))), 13)          --11.���ް���    
                + CASE WHEN SUM( A.VATAmt     ) >= 0 THEN ' ' ELSE '-' END                                   --12.���� ����ǥ��    (��� Space/���� -)
                + RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM( A.VATAmt    )))), 13)          --13.����    
                + SPACE(54)    
                , 140    
          FROM _TTAXReceiptCardSum AS A WITH(NOLOCK)
                        JOIN _TDACust    AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.CustSeq = C.CustSeq  
                        JOIN #TDATaxUnit AS T WITH(NOLOCK) ON A.CompanySeq = T.CompanySeq AND A.TaxUnit = T.TaxUnit  
                   LEFT JOIN #CardMinus  AS M              ON A.CardSeq    = M.CardSeq    AND A.CustSeq = M.CustSeq
         WHERE A.CompanySeq  = @CompanySeq  
           AND A.TaxTermSeq  = @TaxTermSeq  
           AND A.TaxUnit     = @TaxUnit  
           AND A.IsCard      = '1'  
         GROUP BY A.IsCard, T.TaxNo, A.CardNo, C.BizNo, ISNULL(M.MinusCnt, 0)  
         ORDER BY A.IsCard, T.TaxNo, A.CardNo, C.BizNo  

        -- TL�� DL ���ڵ� �� 06. DATA�Ǽ�    
        SELECT @DLCnt = isnull(COUNT(*),0)
            FROM ( SELECT Card.IsCard, dbo._FCOMDecrypt(Card.CardNo, '_TTAXReceiptCardSum', 'CardNo', @CompanySeq) AS CardNo, Cust.BizNo    
                 FROM _TTAXReceiptCardSum AS Card WITH(NOLOCK)
                                               JOIN _TDACust AS Cust WITH(NOLOCK)
                                                 ON Card.CompanySeq = Cust.CompanySeq  
                                                AND Card.CustSeq    = Cust.CustSeq  
                WHERE Card.CompanySeq   = @CompanySeq  
                  AND Card.TaxTermSeq   = @TaxTermSeq  
                  AND Card.TaxUnit      = @TaxUnit  
                  AND Card.IsCard       = '1' -- �ſ�ī�� ����   
                GROUP BY Card.IsCard, Card.CardNo , Cust.BizNo) AS A  
                
        
    ------------------------------------------
    -- ī�屸�� : ���ݿ�����(2)
    ------------------------------------------
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
        SELECT 'DL'                                 --01.���ڵ屸��    
                + SUBSTRING(@TaxFrDate, 1, 4)       --02.�ͼӳ⵵    
                + @TermKind                         --03.�ݱⱸ��    
                + @YearHalfMM                       --04.�ݱ⳻������    
                + CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(B.TaxNo, '-', '')))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(B.TaxNo, '-', '')))))) --05.������(������)����ڵ�Ϲ�ȣ
                + '2'                               --06.ī�屸�� (���ݿ�����)
                + SPACE(20)                         --07.ī��ȸ����ȣ    
                + SPACE(10)                         --08.������(������) ����ڵ�Ϲ�ȣ    
                + RIGHT('000000000' + CONVERT(VARCHAR(9), COUNT(A.SlipSeq) - @MinusCashCnt), 9)      --09.�ŷ��Ǽ�    
                + CASE WHEN SUM( A.SupplyAmt ) >= 0 THEN ' ' ELSE '-' END                            --10.���ް��� ����ǥ��(��� Space/���� -)
                + RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM( A.SupplyAmt )))), 13)  --11.���ް���
                + CASE WHEN SUM( A.VATAmt    ) >= 0 THEN ' ' ELSE '-' END                            --12.���� ����ǥ��    (��� Space/���� -)
                + RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM( A.VATAmt    )))), 13)  --13.����
                + SPACE(54)
                , 140    
          FROM _TTAXReceiptCardSum AS A WITH(NOLOCK)
                        JOIN #TDATaxUnit AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.TaxUnit    = B.TaxUnit
         WHERE A.CompanySeq = @CompanySeq
           AND A.TaxTermSeq = @TaxTermSeq
           AND A.TaxUnit    = @TaxUnit
           AND A.IsCard     <> '1' -- �ſ�ī�� ���� ��
         GROUP BY B.TaxNo, A.IsCard
         ORDER BY B.TaxNo, A.IsCard

        
        SELECT @DLCnt = ISNULL(@DLCnt,0) + COUNT(*)
            FROM ( SELECT Card.IsCard    
                     FROM _TTAXReceiptCardSum AS Card WITH(NOLOCK)
                     WHERE Card.CompanySeq  = @CompanySeq  
                       AND Card.TaxTermSeq  = @TaxTermSeq  
                       AND Card.TaxUnit     = @TaxUnit  
                       AND Card.IsCard     <> '1' -- �ſ�ī�� ���� ��   
                     GROUP BY Card.IsCard ) AS A    
  
    ------------------------------------------
    -- ī�屸�� : �����ſ�ī��(4)
    ------------------------------------------
        IF @SaleCnt > 0    
        BEGIN    
            INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
            SELECT 'DL' --01.���ڵ屸��    
                    + SUBSTRING(@TaxFrDate, 1, 4) --02.�ͼӳ⵵    
                    + @TermKind     --03.�ݱⱸ��    
     + @YearHalfMM   --04.�ݱ⳻������    
                    + CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(TaxNo,'-', '')))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(TaxNo,'-', '')))))) --05.������(������)����ڵ�Ϲ�ȣ    
                    +'4'            --06.ī�屸��(�����ſ�ī��)
                    + SPACE(20)     --07.ī��ȸ����ȣ    
                    + SPACE(10)     --08.������(������) ����ڵ�Ϲ�ȣ    
                    + RIGHT('000000000' + CONVERT(VARCHAR(9), @SaleCnt - @MinusBizCnt), 9)     -- 09. �ŷ��Ǽ�    
                    + CASE WHEN ISNULL(@SupAmt,0) >= 0 THEN ' ' ELSE '-' END    --10.���ް��� ����ǥ��    ��� Space ���� -    
                    + RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(ISNULL(@SupAmt,0)))), 13) --11.���ް���    
                    + CASE WHEN ISNULL(@TaxAmt,0) >= 0 THEN ' ' ELSE '-' END    --12.���� ����ǥ��        ��� Space ���� -    
                    + RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(ISNULL(@TaxAmt,0)))), 13) --13.����    
                    + SPACE(54)    
                    , 140    
              FROM #TDATaxUnit WITH(NOLOCK)
             WHERE CompanySeq   = @CompanySeq  
               AND TaxUnit      = @TaxUnit  
       
            -- �ſ�ī�� ������ ȭ����ۺ���ī��    
            SELECT @DLCnt = ISNULL(@DLCnt,0) + ( CASE WHEN @SaleCnt  > 0 THEN 1 ELSE 0 END )     
        END    
  
        
    /***************************************************************************************************************************    
    �ſ�ī�������ǥ��������_Tail
        
    01. ���ڵ屸��(2) : TL    
    02. �ͼӳ⵵(4)    
    03. �ݱⱸ��(1) : '1' 1��, '2' 2��    
    04. �ݱ⳻������(1) : 1,2,3,4,5,6    ��, �����Ű�� '3', Ȯ���Ű�� '6'    
    05. ������(������)����ڵ�Ϲ�ȣ(10)    
    06. DATA�Ǽ�(7)    
    07. �Ѱŷ��Ǽ�(9)    
    08. �Ѱ��ް���_����ǥ��(1)    
    09. �Ѱ��ް���(15)    
    10. �Ѽ���_����ǥ��(1)    
    11. �Ѽ���(15)    
    12. ����(74)    
    ****************************************************************************************************************************/    
    -- �ſ�ī�� ������ ȭ����ۺ���ī��    
        IF NOT EXISTS (SELECT 1 FROM _TTAXReceiptCardSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
        BEGIN  
            INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
            SELECT 'TL'                             --01.���ڵ屸��    
                    + SUBSTRING(@TaxFrDate, 1, 4)   --02.�ͼӳ⵵    
                    + @TermKind                     --03.�ݱⱸ��    
                    + @YearHalfMM                   --04.�ݱ⳻������    
                    + CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(@TaxNo,'-','')))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(@TaxNo,'-','')))))) --05.������(������)����ڵ�Ϲ�ȣ    
                    + RIGHT('0000000'   + CONVERT(VARCHAR(7), @DLCnt), 7)                               --06. DATA�Ǽ�    
                    + RIGHT('000000000' + CONVERT(VARCHAR(9), (ISNULL(@SaleCnt,0) - @MinusCardCnt - @MinusCashCnt - @MinusEntryCnt - @MinusBizCnt )), 9)              --07. �ŷ��Ǽ� �հ�    
                    + CASE WHEN ISNULL(@SupAmt,0) >= 0 THEN ' ' ELSE '-' END                            --08. �Ѱ��ް���_����ǥ��(���Space/����-)
                    + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(ISNULL(@SupAmt,0) )), 15)    --09. �Ѱ��ް��� �հ�
                    + CASE WHEN ISNULL(@TaxAmt,0) >= 0 THEN ' ' ELSE '-' END                            --10. �Ѽ���_����ǥ��    (���Space/����-)
                    + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(ISNULL(@TaxAmt,0) )), 15)    --11. �Ѽ��� �հ�
                    + SPACE(74)    
                    , 140
        END    
        ELSE    
        BEGIN    
            INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
            SELECT 'TL'                             --01.���ڵ屸��    
                    + SUBSTRING(@TaxFrDate, 1, 4)   --02.�ͼӳ⵵    
                    + @TermKind                     --03.�ݱⱸ��    
                    + @YearHalfMM  --04.�ݱ⳻������    
                    + CONVERT(VARCHAR(10), REPLACE(LTRIM(RTRIM(@TaxNo)),'-','')) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), REPLACE(LTRIM(RTRIM(@TaxNo)),'-','')))) --05.������(������)����ڵ�Ϲ�ȣ    
                    + RIGHT('0000000'   + CONVERT(VARCHAR(7), @DLCnt), 7)                                               --06. DATA�Ǽ�    
                    + RIGHT('000000000' + CONVERT(VARCHAR(9), COUNT(SlipSeq)+ISNULL(@SaleCnt,0) - @MinusCardCnt - @MinusCashCnt - @MinusEntryCnt - @MinusBizCnt), 9)   --07. �ŷ��Ǽ� �հ�    
                    + CASE WHEN SUM(SupplyAmt) >= 0 THEN ' ' ELSE '-' END                                               --08. �Ѱ��ް���_����ǥ��(��� Space/���� -)
                    + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(SupplyAmt)+ISNULL(@SupAmt,0))), 15)      --09. �Ѱ��ް��� �հ�    
                    + CASE WHEN SUM(VATAmt)    >= 0 THEN ' ' ELSE '-' END                                               --10. �Ѽ���_����ǥ��    (��� Space/���� -)
                    + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(VATAmt   )+ISNULL(@TaxAmt,0))), 15)      --11. �Ѽ��� �հ�    
                    + SPACE(74)    
                    , 140    
             FROM _TTAXReceiptCardSum AS A WITH(NOLOCK)
             WHERE A.CompanySeq = @CompanySeq  
               AND A.TaxTermSeq = @TaxTermSeq  
               AND A.TaxUnit    = @TaxUnit
        END    
    END    
END  
    
    -- �������� ���� �߰�       
    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)
    SELECT '', 1
  
    SELECT tmp_seq, ISNULL(tmp_file, '') AS tmp_file, tmp_size, DATALENGTH(tmp_file) AS FileLen   
      FROM #CREATEFile_tmp    
    ORDER BY tmp_seq  
    
RETURN    
--**********************************************************************************************************************************************
