IF OBJECT_ID('hencom_SCOMFSQueryTermByMonth_GAAPFS_BS_AllBizUnitQuery') IS NOT NULL 
    DROP PROC hencom_SCOMFSQueryTermByMonth_GAAPFS_BS_AllBizUnitQuery
GO

-- v2017.08.08 

-- �繫����ǥ(����ι�)_hencom-��ȸ by����õ
/************************************************************
��  �� - �繫��ǥ ��ȸ(����)
�ۼ��� - 2009�� 11�� 29��
�ۼ��� - ������
************************************************************/
CREATE PROC dbo.hencom_SCOMFSQueryTermByMonth_GAAPFS_BS_AllBizUnitQuery
    @xmlDocument    NVARCHAR(MAX),
    @xmlFlags       INT = 0,
    @ServiceSeq     INT = 0,
    @WorkingTag     NVARCHAR(10) = '',
    @CompanySeq     INT = 0,
    @LanguageSeq    INT = 1,
    @UserSeq        INT = 0,
    @PgmSeq         INT = 0
AS
    -- �������� �κ�
    DECLARE @docHandle          INT,
            @AccUnit            INT,
            @AccYear            NVARCHAR(6),
            @FrAccYM            NVARCHAR(6),
            @ToAccYM            NVARCHAR(6),
            @PrevFrAccYM        NVARCHAR(6),
            @PrevToAccYM        NVARCHAR(6),
            @FrAccDate          NVARCHAR(8),
            @ToAccDate          NVARCHAR(8),
            @LastStartDate      NVARCHAR(8),
            @LastEndDate        NVARCHAR(8),
            @argLanguageSeq     INT,
            @IsInit             NVARCHAR(1),
            @IsUseUMCostType    NVARCHAR(1),
            @FSKindNo           NVARCHAR(20),
            @FSDomainSeq        INT,
            @FormatSeq          INT,
            @RptUnit            INT,
            @argString          NVARCHAR(4000),
            @FrSttlYM           NVARCHAR(6),
            @ToSttlYM           NVARCHAR(6),
            @INDEX              INT,
            @IsDisplayZero      NCHAR(1),
            @SlipUnit           INT,
            @IsByMonth          NCHAR(1)
	CREATE TABLE #BSISLevel (LevelSeq INT, BS NVARCHAR(1))  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
    SELECT @AccUnit         = ISNULL(AccUnit, 0),
           @AccYear         = ISNULL(RTRIM(AccYear),''),
--           @FrAccYM         = ISNULL(RTRIM(FrAccYM), ''),
--           @ToAccYM         = ISNULL(RTRIM(ToAccYM), ''),
--           @PrevFrAccYM     = ISNULL(RTRIM(PrevFrAccYM), ''),
--           @PrevToAccYM     = ISNULL(RTRIM(PrevToAccYM), ''),
           @FrAccDate       = ISNULL(RTRIM(FrAccDate), '' ), -- ����ȸ������
           @ToAccDate       = ISNULL(RTRIM(ToAccDate), '' ), -- ����ȸ������
           @argLanguageSeq  = ISNULL(LanguageSeq, 0),
           @FSDomainSeq     = ISNULL(FSDomainSeq   , 11 ),   -- �繫��ǥ��������
           @FSKindNo        = ISNULL(FSKindNo      , '' ),   -- �繫��ǥ�����ڵ�
           @FormatSeq       = ISNULL(FormatSeq     ,  0 ),   -- �繫��ǥ����
           @RptUnit         = ISNULL(RptUnit       ,  0 ),   -- ���������
           @IsDisplayZero   = ISNULL(IsDisplayZero ,  0 ),
           @SlipUnit        = ISNULL(SlipUnit      ,  0 )    -- ��ǥ�������� (2012.09.19 by bgKeum)
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (AccUnit         INT,
            AccYear         NCHAR(6),
--            FrAccYM         NCHAR(6),
--            ToAccYM         NCHAR(6),
--            PrevFrAccYM     NCHAR(6),
--            PrevToAccYM     NCHAR(6),
            FrAccDate       NCHAR(8),
            ToAccDate       NCHAR(8),
            LanguageSeq     INT,
            FSDomainSeq     INT,
            FSKindNo        NVARCHAR(20),
            FormatSeq       INT,
            RptUnit         INT,
            IsDisplayZero   NCHAR(1),
            SlipUnit        INT
            )
    
--    SET @IsDisplayZero = '0'  
----���� �繫��ǥ �� ��� ���� ���� Ÿ�� �ʵ��� �ϱ� ���� ������
--    SELECT @IsByMonth = ''
    
--    IF @PgmSeq IN (SELECT PgmSeq FROM _TCAPgm WHERE LinkPgmSeq IN (6891, 6902) ) OR @PgmSeq IN (6891, 6902)
--    BEGIN
--        SELECT @IsByMonth = '1'
--    END
    
    INSERT #BSISLevel 
	SELECT ISNULL(DisplayLevel,0),
           ISNULL(BSItem,'')
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (    DisplayLevel INT     ,
                BSItem       NCHAR(1))   
--    SELECT @ToAccYM = LEFT(@AccYear,4) + '01'
    IF LEN(LTRIM(RTRIM(ISNULL(@AccYear,'')))) = 6
    BEGIN
        SELECT @ToAccYM = @AccYear
    END
    ELSE
    BEGIN
    -- 1�������� �ƴ� ��� ���⵵�� �����͸� �������� ��찡 �߻��Ͽ� ������ 2011.08.18 dykim
        SELECT @ToAccYM = FrSttlYM 
          FROM _TDAAccFiscal WITH (NOLOCK)
         WHERE CompanySeq = @CompanySeq
           AND FiscalYear = LEFT(@AccYear,4) 
    END
    EXEC _SACGetAccTerm @CompanySeq     = @CompanySeq       ,
                        @CurrDate       = @ToAccYM        ,
                        @FrYM           = @FrSttlYM OUTPUT      ,
                        @ToYM           = @ToSttlYM OUTPUT      
    
    IF @RptUnit > 0
    BEGIN
        SELECT @FSDomainSeq = FSDomainSeq
		FROM   _TCRRptUnit WITH (NOLOCK)
        WHERE  CompanySeq = @CompanySeq 
        AND    RptUnit = @RptUnit
	END
    IF @FormatSeq = 0 
    BEGIN
        -- �繫��ǥ���������� ����
        SELECT TOP 1 @FormatSeq   = A.FormatSeq,           -- �繫��ǥ�����ڵ�
                     @IsUseUMCostType = B.IsUseUMCostType  -- ��뱸�� ��뿩��
          FROM _TCOMFSForm AS A WITH (NOLOCK)
          JOIN _TCOMFSDomainFSKind AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.FSDomainSeq = B.FSDomainSeq AND A.FSKindSeq = B.FSKindSeq  
          JOIN _TCOMFSKind AS C WITH (NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.FSKindSeq = C.FSKindSeq  
         WHERE A.CompanySeq   = @CompanySeq
           AND C.FSKindNo     = @FSKindNo                  -- �繫��ǥ�����ڵ�
           AND A.FSDomainSeq  = @FSDomainSeq               -- �繫��ǥ��������
           AND A.IsDefault    = '1' 
           AND @ToAccYM BETWEEN A.FrYM AND A.ToYM          -- �Ⱓ���� �ϳ��� ����
    END
    -- ��뱸�� ��뿩�θ� �о�´�.  
    SELECT  @IsUseUMCostType = B.IsUseUMCostType  
      FROM _TCOMFSForm AS A WITH (NOLOCK)  
      JOIN _TCOMFSDomainFSKind AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.FSDomainSeq = B.FSDomainSeq AND A.FSKindSeq = B.FSKindSeq  
     WHERE A.CompanySeq   = @CompanySeq  
       AND A.FormatSeq    = @FormatSeq  
    CREATE TABLE #tmpFinancialStatement
    (
        RowNum      INT IDENTITY(0, 1)
    )
    ALTER TABLE #tmpFinancialStatement ADD ThisTermItemAmt       DECIMAL(19, 5)  -- ����׸�ݾ�
    ALTER TABLE #tmpFinancialStatement ADD ThisTermAmt           DECIMAL(19, 5)  -- ���ݾ�
    ALTER TABLE #tmpFinancialStatement ADD PrevTermItemAmt       DECIMAL(19, 5)  -- �����׸�ݾ�
    ALTER TABLE #tmpFinancialStatement ADD PrevTermAmt           DECIMAL(19, 5)  -- ����ݾ�
    ALTER TABLE #tmpFinancialStatement ADD PrevChildAmt          DECIMAL(19, 5)  -- �����ݾ�
    ALTER TABLE #tmpFinancialStatement ADD ThisChildAmt          DECIMAL(19, 5)  -- �����ݾ�
    ALTER TABLE #tmpFinancialStatement ADD ThisReplaceFormula    NVARCHAR(1000)   -- ���ݾ�
    ALTER TABLE #tmpFinancialStatement ADD PrevReplaceFormula    NVARCHAR(1000)   -- ����ݾ�
    
    
    CREATE TABLE #tmpFinancialStatement_byMonth
    (
       FSItemNamePrt            NVARCHAR(200),
       ThisTermItemAmt          DECIMAL(19,5),     -- ����׸�ݾ�
       ThisTermAmt              DECIMAL(19,5),         -- ���ݾ�
       PrevTermItemAmt          DECIMAL(19,5),     -- �����׸�ݾ�
       PrevTermAmt              DECIMAL(19,5),         -- ����ݾ�
       ThisReplaceFormula       NVARCHAR(1000),
       PrevReplaceFormula       NVARCHAR(1000),
       SMItemForeColorCode      INT,
       SMItemBackColorCode      INT,
       FSItemTypeName           NVARCHAR(100),
       FSItemNo                 NVARCHAR(100),
       FSItemName               NVARCHAR(100),
       UMCostTypeName           NVARCHAR(100),
       FSItemTypeSeq            INT,
       FSItemSeq                INT,
       UMCostType               INT,  
       IsSlip                   NCHAR(1),
       Seq                      INT,
       ChildAmt             DECIMAL(19, 5)
    )
    
        
    CREATE TABLE #tmpByMonth
    (
        RowNum                  INT, 
        FSItemNamePrt           NVARCHAR(200),
        FSItemTypeName          NVARCHAR(100),  
        FSItemNo                NVARCHAR(100),
        FSItemName       NVARCHAR(100),
        UMCostTypeName          NVARCHAR(100),
        FSItemTypeSeq           INT,        
        FSItemSeq               INT,
        UMCostType              INT,
        SMItemForeColorCode     INT,
        SMItemBackColorCode     INT,   
        IsSlip                  NCHAR(1),
        FSItemSort              INT,
        Tot                     DECIMAL(19,5),
        FSItemLevel             INT,
        ChildAmt            DECIMAL(19,5)
    )
    CREATE INDEX TMP_IDX_tmpByMonth ON #tmpByMonth(FSItemSeq,UMCostType, FSItemTypeSeq)
 
     CREATE TABLE #ZeroAmtFSItem (
         FSItemSeq         INT,
         FSItemTypeSeq	   INT,
         UMCostType        INT)
    
    -- �繫��ǥ �⺻ �ʱ� ���� ����
    EXEC _SCOMFSFormInit @CompanySeq, @FormatSeq, @argLanguageSeq, '#tmpFinancialStatement'
    IF @@ERROR <> 0  RETURN
    INSERT INTO #tmpByMonth (
            RowNum,
            FSItemNamePrt,           
            FSItemTypeName,          
            FSItemNo,                
            FSItemName,              
            UMCostTypeName,          
            FSItemTypeSeq,                   
            FSItemSeq,               
            UMCostType,              
            SMItemForeColorCode,     
            SMItemBackColorCode,       
            IsSlip,
            FSItemSort,
            FSItemLevel,
            ChildAmt
                            )
     SELECT 
            RowNum,      
            FSItemNamePrt,           
            FSItemTypeName,          
            FSItemNo,                
            FSItemName,              
            UMCostTypeName,          
            FSItemTypeSeq,                   
            FSItemSeq,               
            UMCostType,              
            SMItemForeColorCode,     
            SMItemBackColorCode,       
            IsSlip,
            A.FSItemSort,
            FSItemLevel,
            ChildAmt
      FROM  #tmpFinancialStatement AS A LEFT OUTER JOIN #BSISLevel AS B ON A.FSItemLevel = B.LevelSeq
     WHERE  B.BS = '1'
     ORDER BY A.FSItemSort    
--    select @argLanguageSeq

--    SELECT * FROM #tmpFinancialStatement

    SELECT @FrAccYM     = @FrSttlYM
    SELECT @ToAccYM     = @AccYear      -- ȭ�鿡�� �޾ƿ� �������� �հ踦 �����ش�.
    
    
    
    --select * From #tmpFinancialStatement 
    --return 


    CREATE TABLE #Result 
    (
        SlipUnit            INT, 
        RowNum              INT, 
        FSItemNamePrt       NVARCHAR(200), 
        TotAmt              DECIMAL(19,5), 
        SMItemForeColorCode INT, 
        SMItemBackColorCode INT, 
        FSItemSort          INT, 
        FSItemSeq           INT
    ) 
    
    SELECT Z.ValueSeq AS SlipUnit, Y.MinorSort 
      INTO #UseSlipUnit
      FROM _TDAUMinorValue  AS Z WITH(NOLOCK) 
      JOIN _TDAUMinor       AS Y WITH(NOLOCK) ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.MinorSeq ) 
     WHERE Z.CompanySeq = @CompanySeq  
       AND Z.MajorSeq = 1015303 
       AND Z.Serl = 1000001 
       AND Y.IsUse = '1' 


    -- ��ü ��ǥ�������� ���, Srt
    CREATE TABLE #SlipUnit 
    (
        IDX_NO      INT IDENTITY , 
        SlipUnit    INT 
    )

    INSERT INTO #SlipUnit ( SlipUnit ) 
    SELECT A.SlipUnit 
      FROM _TACSlipUnit AS A 
      JOIN #UseSlipUnit AS B ON ( B.SlipUnit = A.SlipUnit ) 
     ORDER BY SlipUnit 
    -- ��ü ��ǥ�������� ���, End 

    --select * From #SlipUnit 
    --return 

    DECLARE @Cnt INT 
    SELECT @Cnt = 1 

    WHILE ( @Cnt <= (SELECT MAX(IDX_NO) FROM #SlipUnit) ) 
    BEGIN 
        
        SELECT @SlipUnit = SlipUnit 
          FROM #SlipUnit 
         WHERE IDX_NO = @Cnt 

        --���忡 ���� �繫��ǥ �⺻ �ݾ� ����(���)
        EXEC _SCOMFSFormMakeRawData @CompanySeq, @FormatSeq, @IsUseUMCostType, @AccUnit, @FrAccYM, @ToAccYM, @FrAccDate, @ToAccDate, @argString, '#tmpFinancialStatement','1', '0', '0', @SlipUnit
        IF @@ERROR <> 0  RETURN
        
        -- �繫��ǥ ������ ���� ���(���)
        EXEC _SCOMFSFormCalc @CompanySeq, @FormatSeq, '#tmpFinancialStatement', @IsUseUMCostType
        IF @@ERROR <> 0  RETURN
      
        UPDATE A
        SET    ThisTermItemAmt = A.TermItemAmt,
                ThisTermAmt     = A.TermAmt,
                ThisReplaceFormula = A.ReplaceFormula,
                TermItemAmt     = Null,
                TermAmt         = Null,
                ReplaceFormula  = Null
        FROM   #tmpFinancialStatement AS A

        
        INSERT INTO #tmpFinancialStatement_byMonth
        (
                FSItemNamePrt,
                ThisTermItemAmt,     -- ����׸�ݾ�
                ThisTermAmt,         -- ���ݾ�
                PrevTermItemAmt,     -- �����׸�ݾ�
                PrevTermAmt,         -- ����ݾ�
                ThisReplaceFormula,
                PrevReplaceFormula,
                SMItemForeColorCode,
                SMItemBackColorCode,
                FSItemTypeName,
                FSItemNo,
                FSItemName,
                UMCostTypeName,
                FSItemTypeSeq,
                FSItemSeq,
                UMCostType,  
                IsSlip,
                Seq,
                ChildAmt
        )
        SELECT A.FSItemNamePrt,
                ISNULL(A.ThisTermItemAmt,0),     -- ����׸�ݾ�
                ISNULL(A.ThisTermAmt,0),         -- ���ݾ�
                ISNULL(A.PrevTermItemAmt,0),     -- �����׸�ݾ�
                ISNULL(A.PrevTermAmt,0),         -- ����ݾ�
                A.ThisReplaceFormula,
                A.PrevReplaceFormula,
                A.SMItemForeColorCode,
                A.SMItemBackColorCode,
                A.FSItemTypeName,
                A.FSItemNo,
                A.FSItemName,
                A.UMCostTypeName,
                A.FSItemTypeSeq,
                A.FSItemSeq,
                A.UMCostType,  
                A.IsSlip,
                @INDEX,
                ChildAmt
            FROM #tmpFinancialStatement AS A  LEFT OUTER JOIN #BSISLevel AS B ON A.FSItemLevel = B.LevelSeq
            WHERE B.BS = '1'
            ORDER BY FSItemSort

        UPDATE A
           SET A.Tot = NULL 
          FROM #tmpByMonth AS A 

        UPDATE A
           SET A.Tot = B.ThisTermItemAmt + B.ThisTermAmt
          FROM #tmpByMonth AS A JOIN #tmpFinancialStatement_byMonth AS B ON A.FSItemSeq = B.FSItemSeq AND A.UMCostType  = B.UMCostType AND A.FSItemTypeSeq  = B.FSItemTypeSeq
    
   

        CREATE TABLE #tmpFinancialStatement2
        (
            RowNum      INT IDENTITY(0, 1)
        )
        ALTER TABLE #tmpFinancialStatement2 ADD ThisTermItemAmt       DECIMAL(19, 5)  -- ����׸�ݾ�
        ALTER TABLE #tmpFinancialStatement2 ADD ThisTermAmt           DECIMAL(19, 5)  -- ���ݾ�
        ALTER TABLE #tmpFinancialStatement2 ADD PrevTermItemAmt       DECIMAL(19, 5)  -- �����׸�ݾ�
        ALTER TABLE #tmpFinancialStatement2 ADD PrevTermAmt           DECIMAL(19, 5)  -- ����ݾ�
        ALTER TABLE #tmpFinancialStatement2 ADD PrevChildAmt          DECIMAL(19, 5)  -- �����ݾ�
        ALTER TABLE #tmpFinancialStatement2 ADD ThisChildAmt          DECIMAL(19, 5)  -- �����ݾ�
        ALTER TABLE #tmpFinancialStatement2 ADD ThisReplaceFormula    NVARCHAR(1000)   -- ���ݾ�
        ALTER TABLE #tmpFinancialStatement2 ADD PrevReplaceFormula    NVARCHAR(1000)   -- ����ݾ� 


        -- �繫��ǥ �⺻ �ʱ� ���� ����
        EXEC _SCOMFSFormInit @CompanySeq, @FormatSeq, @argLanguageSeq, '#tmpFinancialStatement2'
        IF @@ERROR <> 0  RETURN
    
        -- ǥ�þ�Ŀ��� �������� �ʵ��� �ϱ� ���� 1�� ������Ʈ�Ѵ�.
        UPDATE  #tmpFinancialStatement2
           SET  ThisTermAmt  = 1


        -- ǥ�þ�� ����
        EXEC _SCOMFSFormApplyStyle @CompanySeq, @FormatSeq, '#tmpFinancialStatement2', '0'--, @IsDisplayZero
    
        IF @@ERROR <> 0  RETURN
        UPDATE A
           SET A.FSItemNamePrt  = B.FSItemNamePrt,
               A.FSItemName     = B.FSItemName,
               A.SMItemForeColorCode     = B.SMItemForeColorCode,
               A.SMItemBackColorCode     = B.SMItemBackColorCode
          FROM #tmpByMonth AS A JOIN #tmpFinancialStatement2 AS B ON A.FSItemSeq = B.FSItemSeq AND A.UMCostType  = B.UMCostType AND A.FSItemTypeSeq  = B.FSItemTypeSeq
        
        INSERT INTO #Result ( SlipUnit, RowNum, FSItemNamePrt, TotAmt, SMItemForeColorCode, SMItemBackColorCode, FSItemSort, FSItemSeq ) 
        SELECT @SlipUnit, RowNum, FSItemNamePrt, Tot, SMItemForeColorCode, SMItemBackColorCode, FSItemSort, FSItemSeq
          FROM #tmpByMonth 

        DROP TABLE #tmpFinancialStatement2
        
        UPDATE A
        SET    ThisTermItemAmt = NULL,
               ThisTermAmt     = NULL,
               ThisReplaceFormula = NULL,
               TermItemAmt     = Null,
               TermAmt         = Null,
               ReplaceFormula  = Null, 
               ChildAmt        = NULL
        FROM   #tmpFinancialStatement AS A


        TRUNCATE TABLE #tmpFinancialStatement_byMonth 


        SELECT @Cnt = @Cnt + 1 
    
    END 


    SELECT DISTINCT A.*, B.BizUnit 
      INTO #BizUnitAdd
      From #Result      AS A 
      JOIN _TDADept     AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipUnit = A.SlipUnit )     
      JOIN #UseSlipUnit AS C ON ( C.SlipUnit = A.SlipUnit ) 
    
    SELECT BizUnit, 
           RowNum, 
           MAX(FSItemNamePrt) AS FSItemNamePrt, 
           SUM(TotAmt) AS TotAmt, 
           MAX(SMItemForeColorCode) AS SMItemForeColorCode, 
           MAX(SMItemBackColorCode) AS SMItemBackColorCode, 
           FSItemSort, 
           FSItemSeq 
      INTO #Result_Main
      FROM #BizUnitAdd 
     GROUP BY BizUnit, RowNum, FSItemSort, FSItemSeq
    
    -- 0�ݾ� ���ӿ���, Srt
    SELECT DISTINCT FSItemSeq 
      INTO #IsNotZero
      FROM #Result_Main 
     WHERE Totamt <> 0 
       OR SMItemBackColorCode IS NOT NULL 
    

    IF @IsDisplayZero = '0' 
    BEGIN 
        DELETE A 
          FROM #Result_Main  AS A 
          LEFT OUTER JOIN #IsNotZero  AS B ON ( B.FSItemSeq = A.FSItemSeq ) 
         WHERE B.FSItemSeq IS NULL 
    END 
    -- 0�ݾ� ���ӿ���, End 

    -- Title 
    CREATE TABLE #Title	
    ( 
        ColIdx     INT IDENTITY(0, 1), 
        Title      NVARCHAR(100), 
        TitleSeq   INT 
    ) 
    
    INSERT INTO #Title ( Title, TitleSeq ) 
    SELECT B.BizUnitName, A.BizUnit 
      FROM (
            SELECT DISTINCT BizUnit 
              FROM #Result_Main
           ) AS A 
      JOIN _TDABizUnit AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit ) 
     ORDER BY A.BizUnit
    
    SELECT * FROM #Title 
    
    -- Fix 
    CREATE TABLE #FixCol 
    ( 
        RowIdx              INT IDENTITY(0, 1), 
        RowNum              INT, 
        FSItemNamePrt       NVARCHAR(100), 
        TotAmt              DECIMAL(19,5), 
        SMItemForeColorCode INT, 
        SMItemBackColorCode INT 
    ) 
    
    INSERT INTO #FixCol ( RowNum, FSItemNamePrt, TotAmt, SMItemForeColorCode, SMItemBackColorCode ) 
    SELECT A.RowNum, A.FSItemNamePrt, SUM(A.TotAmt), MAX(A.SMItemForeColorCode), MAX(A.SMItemBackColorCode)
      FROM #Result_Main AS A 
     GROUP BY A.RowNum, A.FSItemNamePrt, A.FSItemSort
     ORDER BY A.FSItemSort 
    
    SELECT * FROM #FixCol 
    
    -- Value 
    CREATE TABLE #Value	
    ( 
        BizUnit        INT, 
        RowNum          INT, 
        TotAmt          DECIMAL(19, 5) 
    ) 
    
    INSERT INTO #Value ( BizUnit, RowNum, TotAmt ) 
    SELECT BizUnit, RowNum, TotAmt 
      FROM #Result_Main
    
    -- ����� ��ȸ 
    SELECT B.RowIdx, A.ColIdx, C.TotAmt AS Value 
      FROM #Value   AS C 
      JOIN #Title   AS A ON ( A.TitleSeq = C.BizUnit ) 
      JOIN #FixCol  AS B ON ( B.RowNum = C.RowNum ) 
     ORDER BY A.ColIdx, B.RowIdx 
    
    
    RETURN
    go
    begin tran 
exec hencom_SCOMFSQueryTermByMonth_GAAPFS_BS_AllBizUnitQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <DisplayLevel>1</DisplayLevel>
    <BSItem>1</BSItem>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <AccUnit />
    <AccYear>201708</AccYear>
    <FSKindNo>BS</FSKindNo>
    <LanguageSeq />
    <FormatSeq />
    <FSDomainSeq>11</FSDomainSeq>
    <RptUnit />
    <IsDisplayZero>0</IsDisplayZero>
    <SlipUnit />
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <DisplayLevel>2</DisplayLevel>
    <BSItem>1</BSItem>
    <AccUnit />
    <AccYear>201708</AccYear>
    <FSKindNo>BS</FSKindNo>
    <LanguageSeq />
    <FormatSeq />
    <FSDomainSeq>11</FSDomainSeq>
    <RptUnit />
    <IsDisplayZero>0</IsDisplayZero>
    <SlipUnit />
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <DisplayLevel>3</DisplayLevel>
    <BSItem>1</BSItem>
    <AccUnit />
    <AccYear>201708</AccYear>
    <FSKindNo>BS</FSKindNo>
    <LanguageSeq />
    <FormatSeq />
    <FSDomainSeq>11</FSDomainSeq>
    <RptUnit />
    <IsDisplayZero>0</IsDisplayZero>
    <SlipUnit />
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <DisplayLevel>4</DisplayLevel>
    <BSItem>1</BSItem>
    <AccUnit />
    <AccYear>201708</AccYear>
    <FSKindNo>BS</FSKindNo>
    <LanguageSeq />
    <FormatSeq />
    <FSDomainSeq>11</FSDomainSeq>
    <RptUnit />
    <IsDisplayZero>0</IsDisplayZero>
    <SlipUnit />
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <DisplayLevel>5</DisplayLevel>
    <BSItem>1</BSItem>
    <AccUnit />
    <AccYear>201708</AccYear>
    <FSKindNo>BS</FSKindNo>
    <LanguageSeq />
    <FormatSeq />
    <FSDomainSeq>11</FSDomainSeq>
    <RptUnit />
    <IsDisplayZero>0</IsDisplayZero>
    <SlipUnit />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1512397,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033762
rollback 