
 
IF OBJECT_ID('KPX_SACFundTotalListQuery') IS NOT NULL   
    DROP PROC KPX_SACFundTotalListQuery  
GO  
  
-- v2016.03.09  
  
-- ��ǰ�Ѽ��Ͱ���-��ȸ by ����õ   
CREATE PROC KPX_SACFundTotalListQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle  INT,  
            -- ��ȸ����   
            @StdDate    NCHAR(8), 
            @LastDate   NCHAR(8), 
            @SubStdDate NCHAR(8)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdDate     = ISNULL( StdDate   , '' ),  
           @LastDate    = ISNULL( LastDate  , '' ), 
           @SubStdDate  = ISNULL( SubStdDate, '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            StdDate    NCHAR(8),
            LastDate   NCHAR(8),            
            SubStdDate NCHAR(8)     
            )    
    
    CREATE TABLE #Result_Main
    (
        IDX_NO          INT IDENTITY, 
        UMHelpComName   NVARCHAR(200), 
        UMHelpCom       INT, 
        InvestAmt       DECIMAL(19,5), 
        EvalProfit1      DECIMAL(19,5), 
        ResultProfit1    DECIMAL(19,5), 
        SumProfit1       DECIMAL(19,5), 
        BondProfit1      DECIMAL(19,5), 
        QuProfit1        DECIMAL(19,5), 
        EvalProfit2      DECIMAL(19,5), 
        ResultProfit2    DECIMAL(19,5), 
        SumProfit2       DECIMAL(19,5), 
        BondProfit2      DECIMAL(19,5), 
        QuProfit2        DECIMAL(19,5), 
        EvalProfit3      DECIMAL(19,5), 
        ResultProfit3    DECIMAL(19,5), 
        SumProfit3       DECIMAL(19,5), 
        BondProfit3      DECIMAL(19,5), 
        QuProfit3        DECIMAL(19,5), 
        EvalProfit4      DECIMAL(19,5), 
        ResultProfit4    DECIMAL(19,5), 
        SumProfit4       DECIMAL(19,5), 
        BondProfit4      DECIMAL(19,5), 
        QuProfit4        DECIMAL(19,5), 
        PeProfitRate     DECIMAL(19,5), 
        ChProfitRate     DECIMAL(19,5), 
        MinorSort       INT 
    )
    --------------------------------------------------------------------
    -- ����ȸ��� 
    --------------------------------------------------------------------
    INSERT INTO #Result_Main ( UMHelpComName, UMHelpCom, MinorSort ) 
    SELECT A.MinorName, A.MinorSeq, A.MinorSort 
      FROM _TDAUMinor AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1010494 
     ORDER BY A.MinorSort 
    --------------------------------------------------------------------
    -- ����ȸ���, END 
    --------------------------------------------------------------------    
    
    --------------------------------------------------------------------    
    -- ���ڱݾ� Update 
    --------------------------------------------------------------------    
    UPDATE A 
       SET InvestAmt = B.InvestAmt
      FROM #Result_Main AS A 
      JOIN ( 
            SELECT UMHelpCom, SUM(InvestAmt) AS InvestAmt 
              FROM KPX_TACEvalProfitItemMaster
             WHERE StdDate = @SubStdDate
            GROUP BY UMHelpCom
           ) AS B ON ( B.UMHelpCom = A.UMHelpCom ) 
    --------------------------------------------------------------------    
    -- ���ڱݾ� Update, END 
    --------------------------------------------------------------------    
    
    DECLARE @XmlData    NVARCHAR(MAX), 
            @UMHelpCom  INT, 
            @IDX_NO     INT 
    
    
    CREATE TABLE #Confirm
    (  
        UMHelpCom       INT, 
        KindName        NVARCHAR(200),   
        FundCode        NVARCHAR(200),   
        FundName        NVARCHAR(200),   
        KindName2       NVARCHAR(200),   
        SrtDate         NCHAR(8),   
        SumResultAmt    DECIMAL(19,5),   
        Amt2            DECIMAL(19,5),   
        Amt1            DECIMAL(19,5),   
        SliptAmt        DECIMAL(19,5),   
        ResultReAmt     DECIMAL(19,5),   
        CalcAmt         DECIMAL(19,5),   
        LYTestAmt       DECIMAL(19,5),   
        AllProfitRate    DECIMAL(19,5),    
        InvestAmtStd    DECIMAL(19,5),    
        InvestAmt       DECIMAL(19,5),    
        CancelAmt       DECIMAL(19,5),   
        Sort            INT, 
        FundSeq         INT 
    )  
    --------------------------------------------------------------------    
    -- ������ ������ 
    --------------------------------------------------------------------    
    SELECT @IDX_NO = 1 
    
    WHILE ( 1 = 1 ) 
    BEGIN 
    
        SELECT @UMHelpCom = UMHelpCom 
          FROM #Result_Main 
         WHERE IDX_NO = @IDX_NO 
        
        
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT 'A' AS WorkingTag,   
                                                          1 AS IDX_NO,   
                                                          1 AS DataSeq,   
                                                          1 Selected,   
                                                          0 AS Status,   
                                                          @SubStdDate AS SubStdDate, 
                                                          @LastDate AS StdDate, 
                                                          @UMHelpCom AS UMHelpCom 
                                                       FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS    
                                                      
                                                 )  
                                 )   
        
        EXEC KPX_SACFundManageConfirmQuery @xmlDocument = @XmlData,  
                                          @xmlFlags = 2,  
                                          @ServiceSeq = 1034278,   
                                          @WorkingTag = N'',  
                                          @CompanySeq = @CompanySeq,   
                                          @LanguageSeq = 1,   
                                          @UserSeq = @UserSeq,   
                                          @PgmSeq = @PgmSeq   
        
        IF @IDX_NO >= ISNULL((SELECT MAX(IDX_NO) FROM #Result_Main),0)
        BEGIN
            BREAK 
        END 
        ELSE
        BEGIN
            SELECT @IDX_NO = @IDX_NO + 1 
        END 
    END 
    
    SELECT * 
      INTO #Confirm1 
      FROM #Confirm
    
    --------------------------------------------------------------------    
    -- ������ ������, END 
    --------------------------------------------------------------------    
    
    TRUNCATE TABLE #Confirm 
    
    --------------------------------------------------------------------    
    -- �̹��� ������
    --------------------------------------------------------------------    
    SELECT @IDX_NO = 1 
    
    WHILE ( 1 = 1 ) 
    BEGIN 
    
        SELECT @UMHelpCom = UMHelpCom 
          FROM #Result_Main 
         WHERE IDX_NO = @IDX_NO 
        
        
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT 'A' AS WorkingTag,   
                                                          1 AS IDX_NO,   
                                                          1 AS DataSeq,   
                                                          1 Selected,   
                                                          0 AS Status,   
                                                          @SubStdDate AS SubStdDate, 
                                                          @StdDate AS StdDate, 
                                                          @UMHelpCom AS UMHelpCom 
                                                       FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS    
                                                      
                                                 )  
                                 )   
        
        EXEC KPX_SACFundManageConfirmQuery @xmlDocument = @XmlData,  
                                          @xmlFlags = 2,  
                                          @ServiceSeq = 1034278,   
                                          @WorkingTag = N'',  
                                          @CompanySeq = @CompanySeq,   
                                          @LanguageSeq = 1,   
                                          @UserSeq = @UserSeq,   
                                          @PgmSeq = @PgmSeq   
        
        IF @IDX_NO >= ISNULL((SELECT MAX(IDX_NO) FROM #Result_Main),0)
        BEGIN
            BREAK 
        END 
        ELSE
        BEGIN
            SELECT @IDX_NO = @IDX_NO + 1 
        END 
    END 
    
    SELECT * 
      INTO #Confirm2
      FROM #Confirm
    
    --------------------------------------------------------------------    
    -- �̹��� ������, END 
    --------------------------------------------------------------------    
    
    TRUNCATE TABLE #Confirm 
    
    
    --SELECT * FROM #Result_Main 
    --SELECT * FROM #Confirm1 
    --SELECT * FROM #Confirm2 
    --------------------------------------------------------------------    
    -- ��������(������) Update 
    --------------------------------------------------------------------    
    UPDATE A 
       SET EvalProfit1 = ISNULL(B.SumResultAmt,0), --   �� �򰡼��� : �������� '(1)�򰡼���' �հ�
           ResultProfit1 = ISNULL(B.CalcAmt,0), --   �� �������� : �������� '���������(��-��+��-��)' �հ�
           SumProfit1 = ISNULL(B.SumResultAmt,0) + ISNULL(B.CalcAmt,0), --   �� �հ� : �򰡼��� + ��������
           BondProfit1 = ISNULL(B.BondSumResultAmt2,0) + ISNULL(B.BondCalcAmt2,0), --   �� ä�������� : �ü�/ä�� ������ ä���� ��ǰ�� ��+���� ���� 
           QuProfit1 = ISNULL(B.BondSumResultAmt1,0) + ISNULL(B.BondCalcAmt1,0) --   �� �ü������� : �ü�/ä�� ������ �ü��� ��ǰ�� ��+���� ���� 
           
           --select * From _TDAUMinor where MinorSeq = 1010563001
      FROM #Result_Main AS A 
      LEFT OUTER JOIN (
                        SELECT Z.UMHelpCom, 
                               SUM(Z.SumResultAmt) AS SumResultAmt, 
                               SUM(Z.CalcAmt) AS CalcAmt, 
                               SUM(CASE WHEN Y.UMBond = 1010563001 THEN Z.SumResultAmt ELSE 0 END) AS BondSumResultAmt1, 
                               SUM(CASE WHEN Y.UMBond = 1010563001 THEN Z.CalcAmt ELSE 0 END) AS BondCalcAmt1, 
                               SUM(CASE WHEN Y.UMBond = 1010563002 THEN Z.SumResultAmt ELSE 0 END) AS BondSumResultAmt2, 
                               SUM(CASE WHEN Y.UMBond = 1010563002 THEN Z.CalcAmt ELSE 0 END) AS BondCalcAmt2 
                          FROM #Confirm1 AS Z 
                          JOIN KPX_TACFundMaster    AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.FundSeq = Z.FundSeq ) 
                         GROUP BY Z.UMHelpCom 
                      ) AS B ON ( B.UMHelpCom = A.UMHelpCom ) 
    --------------------------------------------------------------------    
    -- ��������(������) Update , END 
    --------------------------------------------------------------------    
    
    --------------------------------------------------------------------    
    -- ��������(�̹���) Update 
    --------------------------------------------------------------------    
    UPDATE A 
       SET EvalProfit3 = ISNULL(B.SumResultAmt,0), --   �� �򰡼��� : �̹����� '(1)�򰡼���' �հ�
           ResultProfit3 = ISNULL(B.CalcAmt,0), --   �� �������� : �̹����� '���������(��-��+��-��)' �հ�
           SumProfit3 = ISNULL(B.SumResultAmt,0) + ISNULL(B.CalcAmt,0),  --   �� �հ� : �򰡼��� + ��������
           BondProfit3 = ISNULL(B.BondSumResultAmt2,0) + ISNULL(B.BondCalcAmt2,0), --   �� ä�������� : �ü�/ä�� ������ ä���� ��ǰ�� ��+���� ���� 
           QuProfit3 = ISNULL(B.BondSumResultAmt1,0) + ISNULL(B.BondCalcAmt1,0) --   �� �ü������� : �ü�/ä�� ������ �ü��� ��ǰ�� ��+���� ���� 
      
      FROM #Result_Main AS A 
      LEFT OUTER JOIN (
                        SELECT Z.UMHelpCom, 
                               SUM(Z.SumResultAmt) AS SumResultAmt, 
                               SUM(Z.CalcAmt) AS CalcAmt, 
                               SUM(CASE WHEN Y.UMBond = 1010563001 THEN Z.SumResultAmt ELSE 0 END) AS BondSumResultAmt1, 
                               SUM(CASE WHEN Y.UMBond = 1010563001 THEN Z.CalcAmt ELSE 0 END) AS BondCalcAmt1, 
                               SUM(CASE WHEN Y.UMBond = 1010563002 THEN Z.SumResultAmt ELSE 0 END) AS BondSumResultAmt2, 
                               SUM(CASE WHEN Y.UMBond = 1010563002 THEN Z.CalcAmt ELSE 0 END) AS BondCalcAmt2 
                          FROM #Confirm2 AS Z 
                          JOIN KPX_TACFundMaster    AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.FundSeq = Z.FundSeq ) 
                         GROUP BY Z.UMHelpCom 
                      ) AS B ON ( B.UMHelpCom = A.UMHelpCom ) 
    --------------------------------------------------------------------    
    -- ��������(�̹���) Update , END 
    --------------------------------------------------------------------    
    
    --------------------------------------------------------------------    
    -- ���� ������ 
    --------------------------------------------------------------------    
    -- �Ұ� 
    INSERT INTO #Result_Main 
    SELECT B.ValueText + ' �Ұ�', 1010494098, SUM(InvestAmt), SUM(EvalProfit1), SUM(ResultProfit1), 
           SUM(SumProfit1), SUM(BondProfit1), SUM(QuProfit1), SUM(EvalProfit2), SUM(ResultProfit2), 
           SUM(SumProfit2), SUM(BondProfit2), SUM(QuProfit2), SUM(EvalProfit3), SUM(ResultProfit3), 
           SUM(SumProfit3), SUM(BondProfit3), SUM(QuProfit3), SUM(EvalProfit4), SUM(ResultProfit4), 
           SUM(SumProfit4), SUM(BondProfit4), SUM(QuProfit4), NULL, NULL, MAX(MinorSort) 
      FROM #Result_Main                 AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMHelpCom AND B.Serl = 1000007 ) 
     GROUP BY B.ValueText  
    
    IF EXISTS (SELECT 1 FROM #Result_Main) 
    BEGIN 
        -- �հ� 
        INSERT INTO #Result_Main 
        SELECT '�հ�', 1010494099, SUM(InvestAmt), SUM(EvalProfit1), SUM(ResultProfit1), 
               SUM(SumProfit1), SUM(BondProfit1), SUM(QuProfit1), SUM(EvalProfit2), SUM(ResultProfit2), 
               SUM(SumProfit2), SUM(BondProfit2), SUM(QuProfit2), SUM(EvalProfit3), SUM(ResultProfit3), 
               SUM(SumProfit3), SUM(BondProfit3), SUM(QuProfit3), SUM(EvalProfit4), SUM(ResultProfit4), 
               SUM(SumProfit4), SUM(BondProfit4), SUM(QuProfit4), NULL, NULL, MAX(MinorSort) 
          FROM #Result_Main AS A 
         WHERE UMHelpCom <> 1010494098
    END 
    --------------------------------------------------------------------    
    -- ���� ������, END 
    --------------------------------------------------------------------    

    --------------------------------------------------------------------    
    -- ���ּ���
    --------------------------------------------------------------------    
    UPDATE A 
       SET EvalProfit2 = ISNULL(EvalProfit3,0) - ISNULL(EvalProfit1,0), --   �� �򰡼��� : �̹��� �򰡼��� - ������ �򰡼���
           ResultProfit2 = ISNULL(ResultProfit3,0) - ISNULL(ResultProfit1,0), --   �� �������� : �̹��� �������� - ������ ��������
           SumProfit2 = (ISNULL(EvalProfit3,0) - ISNULL(EvalProfit1,0)) + (ISNULL(ResultProfit3,0) - ISNULL(ResultProfit1,0)) , --   �� �հ� : �򰡼��� + ��������
           BondProfit2 = ISNULL(BondProfit3,0) + ISNULL(BondProfit1,0), --   �� ä�������� : �̹��� ä�������� - ������ ä��������
           QuProfit2 = ISNULL(QuProfit3,0) + ISNULL(QuProfit1,0) --   �� �ü������� : �̹��� �ü������� - ������ �ü�������
      FROM #Result_Main AS A 
    --------------------------------------------------------------------    
    -- ���ּ���, END 
    --------------------------------------------------------------------    
    
    --------------------------------------------------------------------    
    -- �������� ������ 
    --------------------------------------------------------------------    
    UPDATE A 
       SET --   �� �򰡼��� : (�̹��� �����򰡼��� / ���ڱݾ�) * 100
           EvalProfit4 = ROUND((ISNULL(EvalProfit3,0) / NULLIF(ISNULL(InvestAmt,0),0)) * 100,2), 
           --   �� �������� : (�̹��� ������������ / ���ڱݾ�) * 100
           ResultProfit4 = ROUND((ISNULL(ResultProfit3,0) / NULLIF(ISNULL(InvestAmt,0),0)) * 100,2), 
           --   �� �հ� :  ((�̹��� ������ + ��������) / ���ڱݾ�) * 100
           SumProfit4 = ROUND((ISNULL(SumProfit3,0) / NULLIF(ISNULL(InvestAmt,0),0)) * 100,2), 
           --   �� ä�������� : (�̹��� ä������������ / ���ڱݾ�) * 100
           BondProfit4 = ROUND((ISNULL(BondProfit3,0) / NULLIF(ISNULL(InvestAmt,0),0)) * 100,2), 
           --   �� �ü������� : (�̹��� �ü����������� / ���ڱݾ�) * 100
           QuProfit4 = ROUND((ISNULL(QuProfit3,0) / NULLIF(ISNULL(InvestAmt,0),0)) * 100,2), 
           --   �� �Ⱓ : ((�̹��� ������ + ��������) / ���ڱݾ�) * 100
           PeProfitRate = ROUND(((ISNULL(EvalProfit3,0) + ISNULL(ResultProfit3,0)) / NULLIF(ISNULL(InvestAmt,0),0)) * 100,2), 
           --  �� ��ȯ�� : ��Ⱓ������ * 365 / (�̹��� ���� - ��������)
           ChProfitRate = ROUND((((ISNULL(EvalProfit3,0) + ISNULL(ResultProfit3,0)) / NULLIF(ISNULL(InvestAmt,0),0)) * 100) * 365 / NULLIF(DATEDIFF(DAY, @SubStdDate, @StdDate),0),2) 
      FROM #Result_Main AS A 
    --------------------------------------------------------------------    
    -- �������� ������, END 
    --------------------------------------------------------------------    
    
    
    SELECT * 
      FROM #Result_Main 
     ORDER BY MinorSort, IDX_NO 
     
    
    
    RETURN  
GO

begin tran 
exec KPX_SACFundTotalListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <LastDate>20160219</LastDate>
    <SubStdDate>20151231</SubStdDate>
    <StdDate>20160225</StdDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1035667,@WorkingTag=N'',@CompanySeq=4,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1029362
rollback 
