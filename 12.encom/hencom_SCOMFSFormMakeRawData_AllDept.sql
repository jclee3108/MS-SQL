IF OBJECT_ID('hencom_SCOMFSFormMakeRawData_AllDept') IS NOT NULL 
    DROP PROC hencom_SCOMFSFormMakeRawData_AllDept
GO 

-- v2017.05.29 
/************************************************************  
��  �� - ���忡 ���� �繫��ǥ �⺻ �ݾ� ����  
�ۼ��� - 2008�� 10�� 16��  
�ۼ��� - ������  
************************************************************/  
CREATE PROC hencom_SCOMFSFormMakeRawData_AllDept
    @CompanySeq          INT,
    @FormatSeq           INT,  
    @IsUseUMCostType     NCHAR(1),
    @AccUnit             INT,  
    @FrAccYM             NCHAR(6),  
    @ToAccYM             NCHAR(6),  
    @FrAccDate           NCHAR(8),  
    @ToAccDate           NCHAR(8),  
    @argString           NVARCHAR(4000),  
    @TempTable           NVARCHAR(100),
    @IsUseSlipSumTree    NCHAR(1) = '0', -- ���� ������ �� �繫��ǥ����(TB)�� ���� �ݾ� ����
    @IsInit              NCHAR(1) = '0', -- ���ʿ���
    @IsExceptNonCash     NCHAR(1) = '0', -- ����������ǥ
    @SlipUnit            INT      = 0    -- ��ǥ��������
AS  
    -- �������� �κ�  
    DECLARE @SQL                NVARCHAR(4000),  
            @FSDomainNo         NVARCHAR(10),
            @FSDomainSeq        INT,  
            @FSItemTypeSeq      INT,  
            @FSItemSeq          INT,  
            @UMCostType         INT,  
            @index              INT,  
            @totCount           INT,
            @totCalc            INT,
            @totSum             INT
    DECLARE @FrSttlYM         NCHAR(6)
    DECLARE @ToSttlYM         NCHAR(6)
    DECLARE @SMAccStd         INT
    DECLARE @BitCnt           INT
    -- �������� ���ǥ������ ��������(ȯ�漳��)
    -- 4159001	: 1234
    -- 4159002	: -1234
    DECLARE @EnvDisplayAntiAcc  INT  
    EXEC dbo._SCOMEnv @CompanySeq, 4032, 0,@@PROCID,@EnvDisplayAntiAcc OUTPUT 
    SELECT @FSDomainSeq = A.FSDomainSeq,  
           @SMAccStd = CASE WHEN A.FSDomainSeq = 11 THEN 1  
                            WHEN A.FSDomainSeq = 12 THEN 2
                            ELSE 0 END,
           @BitCnt   = 2  
    FROM _TCOMFSForm AS A WITH (NOLOCK)
    JOIN _TCOMFSDomain AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.FSDomainSeq = B.FSDomainSeq
    WHERE A.CompanySeq = @CompanySeq 
    AND   A.FormatSeq = @FormatSeq
    IF @FrAccDate = ''
    BEGIN
        -- ȸ��Ⱓ
        EXEC _SACGetAccTerm @CompanySeq, @ToAccYM, @FrSttlYM OUTPUT, @ToSttlYM OUTPUT
    END
    ELSE
        -- ȸ��Ⱓ
        EXEC _SACGetAccTerm @CompanySeq, @FrAccDate, @FrSttlYM OUTPUT, @ToSttlYM OUTPUT
    CREATE TABLE #SlipSum (  
        FSItemTypeSeq   INT,  
        FSItemSeq       INT,  
        UMCostType      INT,
        SMDrOrCr        INT,
        SMAccKind       INT,
        OpeningBalAmt   DECIMAL(19, 5),  -- �ʱ��ܾ�
        IniDrAmt        DECIMAL(19, 5),  -- �����̿��ݾ�
        IniCrAmt        DECIMAL(19, 5),  -- �뺯�̿��ݾ�
        DrAmt           DECIMAL(19, 5),  -- ��������ݾ�
        CrAmt           DECIMAL(19, 5),  -- �뺯����ݾ�
        MonthDrAmt      DECIMAL(19, 5),  -- ��������ݾ�
        MonthCrAmt      DECIMAL(19, 5),  -- ����뺯�ݾ�
        ClosingBalAmt   DECIMAL(19, 5),  -- �⸻�ܾ�
        TermItemAmt     DECIMAL(19, 5)   -- ���ݾ�
    )  
    CREATE TABLE #SlipSumEx (  
        FSItemTypeSeq   INT,  
        FSItemSeq       INT,  
        UMCostType      INT,
        SMDrOrCr        INT,
        SMAccKind       INT,
        OpeningBalAmt   DECIMAL(19, 5),  -- �ʱ��ܾ�
        IniDrAmt        DECIMAL(19, 5),  -- �����̿��ݾ�
        IniCrAmt        DECIMAL(19, 5),  -- �뺯�̿��ݾ�        
        DrAmt           DECIMAL(19, 5),  -- ��������ݾ�
        CrAmt           DECIMAL(19, 5),  -- �뺯����ݾ�
        MonthDrAmt      DECIMAL(19, 5),  -- ��������ݾ�
        MonthCrAmt      DECIMAL(19, 5),  -- ����뺯�ݾ�
        ClosingBalAmt   DECIMAL(19, 5),  -- �⸻�ܾ�
        TermItemAmt     DECIMAL(19, 5)   -- ���ݾ�
    )  
    
        -- ���� ������ �� �繫��ǥ������ ���� �ݾ� ����
        CREATE TABLE #SlipSumTree
        (
            RowNum      INT IDENTITY(0, 1)
        )
        DECLARE @LanguageSeq INT
        DECLARE @TBFormatSeq INT
        DECLARE @TBFSKindNo  NVARCHAR(10),
                @FSKindNo    NVARCHAR(10)
        SELECT @LanguageSeq = 1
        SELECT @TBFSKindNo  = 'TB'
       -- �繫��ǥ�� ������ �о�´�.
        SELECT @FSDomainNo   = B.FSDomainNo,    -- �繫��ǥ��������
               @FSKindNo     = C.FSKindNo       -- 
          FROM _TCOMFSForm AS A WITH (NOLOCK)
          JOIN _TCOMFSDomain AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.FSDomainSeq = B.FSDomainSeq
          JOIN _TCOMFSKind AS C WITH (NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.FSKindSeq = C.FSKindSeq
         WHERE A.CompanySeq  = @CompanySeq
           AND A.FormatSeq   = @FormatSeq    -- �����ڵ�
        IF @FSKindNo = 'CFID'
        BEGIN
            SELECT @IsExceptNonCash = '1'
        END
        ELSE
        BEGIN
            SELECT @IsExceptNonCash = '0'
        END
        
--SELECT * from _TCOMFSDomain
        IF @FSDomainNo = 'EIS'
        BEGIN
           SELECT @FSDomainNo = 'GAAPFS'
        END
        -- �繫��ǥ���������� ����
        SELECT @TBFormatSeq   = FormatSeq         -- �繫��ǥ�����ڵ�
          FROM _TCOMFSForm AS A WITH (NOLOCK)
          JOIN _TCOMFSDomain AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.FSDomainSeq = B.FSDomainSeq
          JOIN _TCOMFSKind AS C WITH (NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.FSKindSeq = C.FSKindSeq
         WHERE A.CompanySeq   = @CompanySeq
           AND B.FSDomainNo   = @FSDomainNo       -- �繫��ǥ��������
     AND C.FSKindNo     = @TBFSKindNo       -- �繫��ǥ�����ڵ�
           AND A.IsDefault    = 1
           AND @ToAccYM Between FrYM AND ToYM     -- �Ⱓ���� �ϳ��� ����
        -- �繫��ǥ �⺻ �ʱ� ���� ����
        EXEC _SCOMFSFormInit @CompanySeq, @TBFormatSeq, @LanguageSeq, '#SlipSumTree', @IsUseUMCostType
        IF @@ERROR <> 0   RETURN
        
    -- ���忡 ���� �繫��ǥ �⺻ �ݾ� ����
        EXEC hencom_SCOMFSFormMakeRawData_AllDeptSub @CompanySeq, @TBFormatSeq, @IsUseUMCostType, @AccUnit, @FrAccYM, @ToAccYM, @FrAccDate, @ToAccDate, @argString, '#SlipSumTree','0', @IsInit, @IsExceptNonCash, @SlipUnit
        IF @@ERROR <> 0  RETURN
        -- �繫��ǥ ������ ���� ���
        EXEC _SCOMFSFormCalc @CompanySeq, @TBFormatSeq, '#SlipSumTree', @IsUseUMCostType
        IF @@ERROR <> 0  RETURN
        INSERT #SlipSum(FSItemTypeSeq, FSItemSeq, UMCostType, SMDrOrCr, SMAccKind, OpeningBalAmt, DrAmt, CrAmt, MonthDrAmt, MonthCrAmt, ClosingBalAmt) 
            SELECT FSItemTypeSeq, FSItemSeq, UMCostType, SMDrOrCr, SMAccKind, ISNULL(OpeningBalAmt,0), ISNULL(DrAmt,0), ISNULL(CrAmt,0), ISNULL(MonthDrAmt,0), ISNULL(MonthCrAmt,0), ISNULL(ClosingBalAmt,0)
            FROM   #SlipSumTree
        -- ���� ������ �� �繫��ǥ������ ���� �ݾ� ���� ��.
    --return 
        
--    SELECT * FROM #SlipSumTree
--    SELECT * FROM #SlipSum where FSItemSeq = 206
    
--    select * from _tdasminor where companyseq = 1 and majorseq = 4018
--    4018001	4018	�ڻ��׸����
--    4018002	4018	��ä�׸����
--    4018003	4018	�ں��׸����
--    4018004	4018	�����׸����
--    4018005	4018	����׸����
 
    -- ���� �������� �ݾ��� �о�ͼ� �繫��ǥ�� �־��ش�.  
    -- �繫��ǥ�����׸� �ִ°��� �����ϰ� �������� ���� �͸� �־��ش�.
    SET @SQL = ''  
    SET @SQL = @SQL + 'UPDATE A ' + CHAR(13)
    SET @SQL = @SQL + '   SET DrAmt           = ISNULL(X.DrAmt, 0), ' + CHAR(13)
    SET @SQL = @SQL + '       CrAmt           = ISNULL(X.CrAmt, 0), ' + CHAR(13)
    SET @SQL = @SQL + '       IniDrAmt        = ISNULL(X.IniDrAmt, 0), ' + CHAR(13)
    SET @SQL = @SQL + '       IniCrAmt        = ISNULL(X.IniCrAmt, 0), ' + CHAR(13)        
    SET @SQL = @SQL + '       MonthDrAmt      = ISNULL(X.MonthDrAmt, 0), ' + CHAR(13)
    SET @SQL = @SQL + '       MonthCrAmt      = ISNULL(X.MonthCrAmt, 0), ' + CHAR(13)
    SET @SQL = @SQL + '       DrBalAmt        = CASE WHEN X.SMDrOrCr = 1 THEN ISNULL(X.ClosingBalAmt, 0) ELSE 0 END, ' + CHAR(13)
    SET @SQL = @SQL + '       CrBalAmt        = CASE WHEN X.SMDrOrCr = -1 THEN ISNULL(X.ClosingBalAmt, 0) ELSE 0 END, ' + CHAR(13)
    SET @SQL = @SQL + '       DrCumulativeAmt = ISNULL(X.DrAmt, 0), ' + CHAR(13)
    SET @SQL = @SQL + '       CrCumulativeAmt = ISNULL(X.CrAmt, 0), ' + CHAR(13)
    SET @SQL = @SQL + '       OpeningBalAmt   = ISNULL(X.OpeningBalAmt, 0), ' + CHAR(13)
    SET @SQL = @SQL + '       ClosingBalAmt   = ISNULL(X.ClosingBalAmt, 0), ' + CHAR(13)
    -- �������� -1234 ǥ��    
    IF @EnvDisplayAntiAcc = 4159002
    BEGIN
        -- �׸�ݾ׼���
        SET @SQL = @SQL + '       TermItemAmt     = CASE WHEN A.SMAccKind IN (''4018001'',''4018002'',''4018003'') THEN CASE WHEN A.IsSubtraction = 1 THEN -1 ELSE 1 END * ISNULL(X.ClosingBalAmt, 0) ' + CHAR(13)                          -- �����׸�(�⸻�ܾ�)
        SET @SQL = @SQL + '                              WHEN A.SMAccKind IN (''4018004'',''4018005'') THEN CASE WHEN A.IsSubtraction = 1 THEN -1 ELSE 1 END * X.SMDrOrCr * (ISNULL(X.MonthDrAmt, 0) - ISNULL(X.MonthCrAmt, 0))' + CHAR(13) -- �����׸�(���߻�)
        SET @SQL = @SQL + '                              ELSE 0 ' + CHAR(13)
        SET @SQL = @SQL + '                          END ' + CHAR(13)
    END
    ELSE
    BEGIN
        -- �׸�ݾ׼���
        SET @SQL = @SQL + '       TermItemAmt     = CASE WHEN A.SMAccKind IN (''4018001'',''4018002'',''4018003'') THEN ISNULL(X.ClosingBalAmt, 0) ' + CHAR(13)                          -- �����׸�(�⸻�ܾ�)
        SET @SQL = @SQL + '                              WHEN A.SMAccKind IN (''4018004'',''4018005'') THEN X.SMDrOrCr * (ISNULL(X.MonthDrAmt, 0) - ISNULL(X.MonthCrAmt, 0))' + CHAR(13) -- �����׸�(���߻�)
        SET @SQL = @SQL    + '                               ELSE 0 ' + CHAR(13)
        SET @SQL = @SQL + '                          END ' + CHAR(13)
    END
    SET @SQL = @SQL + '  FROM ' + @TempTable + ' AS A ' + CHAR(13)
    SET @SQL = @SQL + '    JOIN #SlipSum AS X ' + CHAR(13)
    SET @SQL = @SQL + '      ON X.FSItemTypeSeq = A.FSItemTypeSeq ' + CHAR(13)
    SET @SQL = @SQL +  '     AND X.FSItemSeq      = A.FSItemSeq ' + CHAR(13)
    IF @IsUseUMCostType = '1'  
        SET @SQL = @SQL + ' AND X.UMCostType    = A.UMCostType ' + CHAR(13)
    SET @SQL = @SQL + ' WHERE NOT EXISTS ( ' + CHAR(13)
    SET @SQL = @SQL + '                    SELECT * ' + CHAR(13)
    SET @SQL = @SQL + '                      FROM _TCOMFSFormItem I WITH (NOLOCK) ' + CHAR(13)
    SET @SQL = @SQL + '                     WHERE I.CompanySeq    = ' + CAST(@CompanySeq AS NVARCHAR) + ' ' + CHAR(13)
    SET @SQL = @SQL + '                       AND I.FormatSeq     = ' + CAST(@FormatSeq AS NVARCHAR) + ' ' + CHAR(13)
--    SET @SQL = @SQL + '                       AND I.FSItemTypeSeq = 1 ' + CHAR(13)
    SET @SQL = @SQL + '                       AND I.FSItemTypeSeq = A.FSItemTypeSeq ' + CHAR(13)
    SET @SQL = @SQL + '                       AND I.FSItemSeq     = A.FSItemSeq ' + CHAR(13)
    IF @IsUseUMCostType = '1'  
        SET @SQL = @SQL + '                   AND I.UMCostType    = A.UMCostType ' + CHAR(13)
    SET @SQL = @SQL + '                  ) ' + CHAR(13)
--    SELECT * FROM #SlipSum where FSItemSeq = 172
--    SELECT * FROM #tmpFinancialStatement where FSItemSeq = 172
--    PRINT @SQL
    EXEC SP_EXECUTESQL @SQL  
    IF @@ERROR <> 0  RETURN  
    -- ���� �������� �ݾ��� �о�ͼ� �繫��ǥ�� �־��ֱ� ��.


    DECLARE @IniAccYM NCHAR(6)
    IF @FSKindNo = 'RE'
    BEGIN
        -- �ʱ��Է¿���
        IF @FSDomainNo = 'GAAPFS'
        BEGIN  
            SELECT TOP 1 @IniAccYM = A.ToSttlYM 
            FROM _TDAAccFiscal AS A WITH (NOLOCK)
                    JOIN _TDAAccUnit AS B  WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq  
            WHERE A.CompanySeq     = @CompanySeq  
              AND (@AccUnit = 0 OR B.AccUnit = @AccUnit)
              AND CONVERT(NCHAR(6),DATEADD(yy,-1,B.SystemOpenYM+'01'),112) >= A.FrSttlYM  
              AND CONVERT(NCHAR(6),DATEADD(yy,-1,B.SystemOpenYM+'01'),112) <= A.ToSttlYM  
        END  
        ELSE  
        BEGIN  
            SELECT TOP 1 @IniAccYM = A.ToSttlYM 
            FROM _TDAAccFiscal AS A WITH (NOLOCK)
                    JOIN _TDAAccUnit AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq  
            WHERE A.CompanySeq     = @CompanySeq  
              AND (@AccUnit = 0 OR B.AccUnit = @AccUnit)
              AND CONVERT(NCHAR(6),DATEADD(yy,-1,B.SystemOpenYmIFRS+'01'),112) >= A.FrSttlYM  
              AND CONVERT(NCHAR(6),DATEADD(yy,-1,B.SystemOpenYmIFRS+'01'),112) <= A.ToSttlYM  
        END  
        SET @SQL = ''  
        SET @SQL = @SQL + 'UPDATE A ' + CHAR(13)
            -- �׸�ݾ׼���
        SET @SQL = @SQL + '   SET A.TermItemAmt     = B.Amt, ' + CHAR(13)
        SET @SQL = @SQL + '       A.IsSetAmt        = ''1'' ' + CHAR(13)
        SET @SQL = @SQL + '  FROM ' + @TempTable + ' AS A ' + CHAR(13)
        SET @SQL = @SQL + '  JOIN _TCOMFSFormTreeValue AS B WITH (NOLOCK) ON B.CompanySeq = ' + CAST(@CompanySeq AS NVARCHAR) + ' ' + CHAR(13)
        SET @SQL = @SQL + '                                AND B.FormatSeq     = ' + CAST(@FormatSeq AS NVARCHAR) + ' ' + CHAR(13)
        SET @SQL = @SQL + '                                AND A.FSItemTypeSeq = B.FSItemTypeSeq ' + CHAR(13)
        SET @SQL = @SQL + '                                AND A.FSItemSeq     = B.FSItemSeq ' + CHAR(13)
        SET @SQL = @SQL + '                                AND A.UMCostType    = B.UMCostType ' + CHAR(13)
        SET @SQL = @SQL + '  JOIN _TCOMFSFormItem FI WITH (NOLOCK) ' + CHAR(13)
        SET @SQL = @SQL + '    ON FI.CompanySeq    = ' + CAST(@CompanySeq AS NVARCHAR) + ' ' + CHAR(13)
SET @SQL = @SQL + '   AND FI.FormatSeq     = ' + CAST(@FormatSeq AS NVARCHAR) + ' ' + CHAR(13)
        SET @SQL = @SQL + '   AND FI.FSItemTypeSeq = A.FSItemTypeSeq ' + CHAR(13)
        SET @SQL = @SQL + '   AND FI.FSItemSeq     = A.FSItemSeq ' + CHAR(13)
        SET @SQL = @SQL + '   AND FI.UMCostType    = A.UMCostType ' + CHAR(13)
    
        SET @SQL = @SQL + '  WHERE ( B.AccYM = ''' + @ToAccYM + '''' + CHAR(13)
        SET @SQL = @SQL + '    AND ((FI.SMFormulaCalcKind = ''1035003'' ' + CHAR(13)
        SET @SQL = @SQL + '    AND UPPER(Formula) = '''' ) ' + CHAR(13)
        SET @SQL = @SQL + '    OR  (''' + @ToAccYM + ''' = ''' + @IniAccYM + '''  ' + CHAR(13)
        SET @SQL = @SQL + '    AND FI.SMFormulaCalcKind = ''1035001'' ' + CHAR(13)
        SET @SQL = @SQL + '    AND A.FSItemLevel > 1 ))) ' + CHAR(13)
        
        PRINT @SQL
        EXEC SP_EXECUTESQL @SQL  
        IF @@ERROR <> 0  RETURN  


    END

    CREATE TABLE #SlipSumFormula (  
        Formula         NVARCHAR(100),
        OpeningBalAmt   DECIMAL(19, 5),  -- �ʱ��ܾ�
        DrAmt           DECIMAL(19, 5),  -- ��������ݾ�
        CrAmt           DECIMAL(19, 5),  -- �뺯����ݾ�
        MonthDrAmt      DECIMAL(19, 5),  -- ��������ݾ�
        MonthCrAmt      DECIMAL(19, 5),  -- ����뺯�ݾ�
        ClosingBalAmt   DECIMAL(19, 5),  -- �⸻�ܾ�
        TermItemAmt     DECIMAL(19, 5)   -- ���ݾ�
    )  
    SET @SQL = @SQL + 'INSERT #SlipSumFormula(Formula, OpeningBalAmt, DrAmt, CrAmt, MonthDrAmt, MonthCrAmt, ClosingBalAmt ) ' + CHAR(13)
    SET @SQL = @SQL + '    SELECT ''$EV/EBITDA$'', (SUM(CASE WHEN A.AccYM = ''' + @FrSttlYM + ''' AND IsIni = ''0'' OR A.AccYM < ''' + @FrAccYM + ''' AND IsIni = ''1'' THEN ISNULL(A.DrAmt,0) ELSE 0 END) - ' + CHAR(13)
    SET @SQL = @SQL + '           SUM(CASE WHEN A.AccYM = ''' + @FrSttlYM + ''' AND IsIni = ''0'' OR A.AccYM < ''' + @FrAccYM + ''' AND IsIni = ''1'' THEN ISNULL(A.CrAmt,0) ELSE 0 END)) AS OpeningBalance, ' + CHAR(13) -- �ʱ��ܾ�
    SET @SQL = @SQL + '           SUM(A.DrAmt) AS DrAmt, ' + CHAR(13)                                                                                                 -- ��������ݾ�
    SET @SQL = @SQL + '           SUM(A.CrAmt) AS CrAmt, ' + CHAR(13)                                                                                                 -- �뺯����ݾ�
    SET @SQL = @SQL + '           SUM(CASE WHEN A.AccYM BETWEEN ''' + @FrAccYM + ''' AND ''' + @ToAccYM + ''' AND IsIni =''1'' THEN A.DrAmt ELSE 0 END) AS MonthDrAmt, ' + CHAR(13) -- ��������ݾ�
    SET @SQL = @SQL + '           SUM(CASE WHEN A.AccYM BETWEEN ''' + @FrAccYM + ''' AND ''' + @ToAccYM + ''' AND IsIni =''1'' THEN A.CrAmt ELSE 0 END) AS MonthCrAmt, ' + CHAR(13) -- ���뺯�ݾ�
    SET @SQL = @SQL + '          (ISNULL(SUM(A.DrAmt),0) - ISNULL(SUM(CrAmt),0)) AS ClosingBalance ' + CHAR(13)                                          -- �⸻�ܾ� 
    SET @SQL = @SQL + '      FROM _TACSlipSum AS A WITH(NOLOCK) ' + CHAR(13)
    SET @SQL = @SQL + '      JOIN  dbo._FCOMBitMask(' +CAST(@BitCnt AS NVARCHAR) + ',' + CAST(@SMAccStd AS NVARCHAR)+ ') AS D ON A.SMAccStd = D.Val '
    SET @SQL = @SQL + '      JOIN _TDAAccount AS B  WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.AccSeq = B.AccSeq ' + CHAR(13)
    SET @SQL = @SQL + '     WHERE A.CompanySeq = ' + CAST(@CompanySeq AS NVARCHAR) + ' ' + CHAR(13)
    SET @SQL = @SQL + '       AND (' + CAST(@AccUnit AS NVARCHAR) + ' = 0 OR AccUnit  = ' + CAST(@AccUnit AS NVARCHAR) + ') ' + CHAR(13)
    SET @SQL = @SQL + '       AND (A.AccYM BETWEEN ''' + @FrSttlYM + ''' AND ''' + @ToAccYM + ''' ) ' + CHAR(13)
    SET @SQL = @SQL + '       AND B.SMAccKind IN (''4018001'',''4018002'',''4018003'') '
    SET @SQL = @SQL + '       AND A.SlipUnit > 0 ' + CHAR(13)
    SET @SQL = @SQL + '' + CHAR(13)
    SET @SQL = @SQL + 'UPDATE A ' + CHAR(13)
    SET @SQL = @SQL + '   SET TermItemAmt     = ISNULL(X.ClosingBalAmt,0) ' + CHAR(13)
    SET @SQL = @SQL + '  FROM ' + @TempTable + ' AS A ' + CHAR(13)
SET @SQL = @SQL + '  JOIN ( SELECT ClosingBalAmt AS ClosingBalAmt ' + CHAR(13)
    SET @SQL = @SQL + '         FROM #SlipSumFormula ' + CHAR(13)
    SET @SQL = @SQL + '         WHERE Formula = ''$EV/EBITDA$'' ) AS X ON 1 = 1' + CHAR(13)
    SET @SQL = @SQL + '  JOIN _TCOMFSFormItem FI WITH (NOLOCK) ' + CHAR(13)
    SET @SQL = @SQL + '    ON FI.CompanySeq    = ' + CAST(@CompanySeq AS NVARCHAR) + ' ' + CHAR(13)
    SET @SQL = @SQL + '   AND FI.FormatSeq     = ' + CAST(@FormatSeq AS NVARCHAR) + ' ' + CHAR(13)
    SET @SQL = @SQL + '   AND FI.FSItemTypeSeq = A.FSItemTypeSeq ' + CHAR(13)
    SET @SQL = @SQL + '   AND FI.FSItemSeq     = A.FSItemSeq ' + CHAR(13)
    SET @SQL = @SQL + '   AND FI.UMCostType    = A.UMCostType ' + CHAR(13)
    SET @SQL = @SQL + ' WHERE FI.SMFormulaCalcKind = ''1035003'' ' + CHAR(13)
    SET @SQL = @SQL + '   AND UPPER(Formula) = ''$EV/EBITDA$''  ' + CHAR(13)
--    PRINT @SQL

---------------------------  ��ǰ������� �� ��ǰ��������� �ϵ��ڵ����� �־��ش�

declare @MQtySeq int, @GQtySeq int

select @MQtySeq = MinorSort
  from _TDAUMinor
 where CompanySeq = @CompanySeq
   and minorseq = (
					select a.minorseq
					  from _TDAUMinorValue as a
					  join _TDAUMinorValue b on b.CompanySeq = a.CompanySeq
					                        and b.MajorSeq = a.MajorSeq
					                        and b.minorseq = a.MinorSeq
											and b.Serl = 1000004 
											and b.ValueSeq = 1031795   
					 where a.CompanySeq = @CompanySeq
					   and a.majorseq = 1013755
					   and a.Serl = 1000002          
					   and a.ValueText = '1'     ) 

select @GQtySeq = MinorSort
  from _TDAUMinor
 where CompanySeq = @CompanySeq
   and minorseq = (
					select a.minorseq
					  from _TDAUMinorValue as a
					  join _TDAUMinorValue b on b.CompanySeq = a.CompanySeq
					                        and b.MajorSeq = a.MajorSeq
					                        and b.minorseq = a.MinorSeq
											and b.Serl = 1000004 
											and b.ValueSeq = 1031840   
					 where a.CompanySeq = @CompanySeq
					   and a.majorseq = 1013755
					   and a.Serl = 1000002          
					   and a.ValueText = '1'     ) 



update a
	  set termitemamt = b.salesqty
  from #tmpFinancialStatement as a
  join (select case SMAssetGrp when 6008001 then @GQtySeq  else @MQtySeq end as fsitemseq, 
				       sum(si.Qty) as salesqty
				  from _TSLSales as sm
				  join _tslsalesitem as si on si.CompanySeq = sm.CompanySeq
										  and si.SalesSeq = sm.SalesSeq
       left outer join _tdaitem as i on i.CompanySeq = sm.CompanySeq
	                                and i.ItemSeq = si.ItemSeq
       left outer join _TDAItemAsset as ia on ia.CompanySeq = sm.CompanySeq
	                                      and ia.AssetSeq = i.AssetSeq
                 where sm.CompanySeq = @CompanySeq
				   and sm.SalesDate between @FrAccYM + '01' and @ToAccYM + '31'
				   and ia.SMAssetGrp in (6008001, 6008002)
				   and sm.DeptSeq IN  (select ValueSeq
                                        from _TDAUMinorValue 
									   where CompanySeq = @CompanySeq
										 and majorseq = 1012291
										 and serl = 1000002
										 and MinorSeq IN (select Q.minorseq 
															from _TDAUMinorValue AS Q 
                                                            JOIN #SlipUnit       AS W ON ( W.DSlipUnit = Q.ValueSeq )
														   where Q.CompanySeq = @CompanySeq
															 and Q.majorseq = 1012291
															 and Q.serl = 1000001
															 --and ValueSeq = @SlipUnit) 
                                                         )
                                     )
              group by case SMAssetGrp when 6008001 then @GQtySeq else @MQtySeq end ) as b on b.fsitemseq = a.fsitemseq
	

    EXEC SP_EXECUTESQL @SQL  
    IF @@ERROR <> 0  RETURN  

    -- ��İ��
    EXEC _SCOMFSFormFormulaCalc @CompanySeq, @FormatSeq,  @TempTable, @IsUseUMCostType
    IF @@ERROR <> 0  RETURN
RETURN  
/*******************************************************************************************************************/



go
