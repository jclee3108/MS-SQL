  
IF OBJECT_ID('hncom_SPRAdjWithHoldListIFSave') IS NOT NULL   
    DROP PROC hncom_SPRAdjWithHoldListIFSave  
GO  
  
-- v2017.02.10
  
-- ��õ���Ű���-�������� by����õ
CREATE PROC hncom_SPRAdjWithHoldListIFSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    

    CREATE TABLE #hncom_TAdjWithHoldList( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hncom_TAdjWithHoldList'   
    IF @@ERROR <> 0 RETURN     
    
    DECLARE @BizSeq         INT, 
            @StdYM          NCHAR(6), 
            @EndDateFr      NCHAR(8), 
            @EndDateTo      NCHAR(8), 
            @HRMDeptSeq     INT, 
            @HRMDeptName    NVARCHAR(100),
            @UMTypeSeq      INT 

    SELECT @BizSeq = BizSeq, 
           @StdYM = StdYM, 
           @EndDateFr = EndDateFr, 
           @EndDateTo = EndDateTo
      FROM #hncom_TAdjWithHoldList  
    
    
    -- ���ؿ����� ������ ���� �� �ٽ� ����
    DELETE A
      FROM hncom_TAdjWithHoldList AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdYM = @StdYM 
       AND A.BizSeq = @BizSeq 
       AND A.IsSum = '1'
    
    -- ����� Mapping 
    SELECT @HRMDeptSeq = CONVERT(INT,C.ValueText), 
           @HRMDeptName = A.Remark
      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1014724
       AND B.ValueSeq = @BizSeq

    -- ��õ�ҵ汸�� Mapping 
    SELECT A.MinorSeq, 
           B.ValueText  AS HRMSeq, 
           C.ValueSeq   AS ErpSeq
      INTO #Type
      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1014736
    
    -------------------------------------------------------------------
    -- �޿�, ��, ������
    -------------------------------------------------------------------
    SELECT A.com_cd
          ,A.ent_cd
          ,A.calc_seq
          --,A.calc_kr
          ,A.attribute2 + '_' + CASE WHEN A.calc_flag = 'RET' THEN 'PAY' -- �ܿ��޿� -> �޿��� ����
                                     WHEN A.calc_flag = 'SPE' THEN 'BON' -- Ư���� -> �󿩷� ����
                                     ELSE A.calc_flag 
                                     END AS HRMSeq
          ,CONVERT(DECIMAL(19,5),A.emp_cnt) AS TaxEmpCnt
          ,SUM(CONVERT(DECIMAL(19,5), B.tot_pay_amt)) AS TotAmt -- �����޾�
          ,SUM(CONVERT(DECIMAL(19,5), B.tax_amt)) AS IncomeTaxAmt -- �ҵ漼
          ,SUM(CONVERT(DECIMAL(19,5), B.area_amt)) AS ResidentTaxAmt -- �ֹμ�
          ,SUM(CONVERT(DECIMAL(19,5), B.ATTRIBUTE4)) AS TaxAmt
          ,0 AS RuralTaxAmt -- ��Ư��
      INTO #Pay_Work
      FROM [GHRM]..[HGHR].[ENCOM_PAY_WORK]  AS A
      JOIN [GHRM]..[HGHR].[ENCOM_PAY_EMP]   AS B ON A.calc_seq = B.calc_seq
     WHERE A.calc_yy = LEFT(@StdYM,4)
       AND A.calc_mm = RIGHT(@StdYM,2)
       AND A.ENT_CD = @HRMDeptSeq
     GROUP BY A.com_cd
             ,A.ent_cd
             ,A.calc_seq
             --,A.calc_kr
             ,A.emp_cnt
             ,A.attribute2 + '_' + CASE WHEN A.calc_flag = 'RET' THEN 'PAY' -- �ܿ��޿� -> �޿��� ����
                                     WHEN A.calc_flag = 'SPE' THEN 'BON' -- Ư���� -> �󿩷� ����
                                     ELSE A.calc_flag 
                                     END
    
    -- ERP���̺� �ֱ� ��Ƶα�
    CREATE TABLE #hncom_TAdjWithHoldList_Result
    (
       CompanySeq       INT
       ,IDX_NO          INT IDENTITY
       ,BizSeq          INT
       ,StdYM           NCHAR(6)
       ,EndDateFr       NCHAR(8)
       ,EndDateTo       NCHAR(8)
       ,EndDate         NCHAR(8) 
       ,UMTypeSeq       INT
       ,EmpName         NVARCHAR(200)
       ,EmpCnt          DECIMAL(19,5)
       ,TotAmt          DECIMAL(19,5)
       ,TaxEmpCnt       DECIMAL(19,5)
       ,TaxAmt          DECIMAL(19,5)
       ,TaxShortageAmt  DECIMAL(19,5)
       ,IncomeTaxAmt    DECIMAL(19,5)
       ,ResidentTaxAmt  DECIMAL(19,5)
       ,RuralTaxAmt     DECIMAL(19,5)
       ,IsSum           NCHAR(1)
    )
    INSERT INTO #hncom_TAdjWithHoldList_Result 
    (
        CompanySeq, BizSeq, StdYM, EndDateFr, EndDateTo, 
        UMTypeSeq, EmpName, EmpCnt, TotAmt, TaxEmpCnt, 
        TaxAmt, TaxShortageAmt, IncomeTaxAmt, ResidentTaxAmt, RuralTaxAmt, 
        IsSum
    )
    SELECT @CompanySeq, @BizSeq, @StdYM, @EndDateFr, @EndDateTo,    
           B.MinorSeq, '', SUM(A.TaxEmpCnt), SUM(A.TotAmt), SUM(A.TaxEmpCnt), 
           SUM(A.TaxAmt), 0, SUM(A.IncomeTaxAmt), SUM(A.ResidentTaxAmt), SUM(A.RuralTaxAmt), 
           '1'
      FROM #Pay_Work            AS A 
      LEFT OUTER JOIN #Type     AS B ON ( B.HRMSeq = A.HRMSeq ) 
     GROUP BY B.MinorSeq
    
    -------------------------------------------------------------------
    -- �޿�, ��, ������, END 
    -------------------------------------------------------------------

    -------------------------------------------------------------------
    -- ��������, �ߵ����
    -------------------------------------------------------------------
    -- ��������
    SELECT A.*, 1 AS Cnt
      INTO #ENCOM_SETTLE_CALC
      FROM [GHRM]..[HGHR].[ENCOM_SETTLE_CALC]   AS A 
     WHERE CONVERT(INT,LEFT(A."��꿬��",4)) = CONVERT(INT,LEFT(@StdYM,4)) - 1
       AND A."������ڵ�" = @HRMDeptSeq
       AND A."����" = '100'
       AND RIGHT(@StdYM,2) = '02' -- ���������� 2������ �����´�.


    INSERT INTO #hncom_TAdjWithHoldList_Result 
    (
        CompanySeq, BizSeq, StdYM, EndDateFr, EndDateTo, 
        UMTypeSeq, EmpName, EmpCnt, TotAmt, TaxEmpCnt, 
        TaxAmt, TaxShortageAmt, IncomeTaxAmt, ResidentTaxAmt, RuralTaxAmt, 
        IsSum
    )
    SELECT @CompanySeq, @BizSeq, @StdYM, @EndDateFr, @EndDateTo, 
           B.MinorSeq, '', SUM(Cnt), SUM(CONVERT(DECIMAL(19,5),A."���ٹ����޿�")), SUM(Cnt), 
           SUM(CONVERT(DECIMAL(19,5),A."���ٹ����޿�")), 0, SUM(CONVERT(DECIMAL(19,5),A."����¡���ҵ漼")), SUM(CONVERT(DECIMAL(19,5),A."����¡�����漼")), 0, 
           '1'
      FROM #ENCOM_SETTLE_CALC   AS A 
      LEFT OUTER JOIN #Type     AS B ON ( B.HRMSeq = A."����" )
     GROUP BY B.MinorSeq 
    
    -- �ߵ���� 
    INSERT INTO #hncom_TAdjWithHoldList_Result 
    (
        CompanySeq, BizSeq, StdYM, EndDateFr, EndDateTo, 
        UMTypeSeq, EmpName, EmpCnt, TotAmt, TaxEmpCnt, 
        TaxAmt, TaxShortageAmt, IncomeTaxAmt, ResidentTaxAmt, RuralTaxAmt, 
        IsSum
    )
    SELECT @CompanySeq, @BizSeq, @StdYM, @EndDateFr, @EndDateTo, 
           B.MinorSeq, A."����", 1, CONVERT(DECIMAL(19,5),A."���ٹ����޿�"), 1, 
           CONVERT(DECIMAL(19,5),A."���ٹ����޿�"), 0, CONVERT(DECIMAL(19,5),A."����¡���ҵ漼"), CONVERT(DECIMAL(19,5),A."����¡�����漼"), 0, 
           '1'
      FROM [GHRM]..[HGHR].[ENCOM_SETTLE_CALC]   AS A 
      LEFT OUTER JOIN #Type     AS B ON ( B.HRMSeq = A."����" )
     WHERE A."��꿬��" = @StdYM
       AND A."������ڵ�" = @HRMDeptSeq
       AND A."����" = '200'
    -------------------------------------------------------------------
    -- ��������, �ߵ�����, END 
    -------------------------------------------------------------------
    
    -------------------------------------------------------------------
    -- �����޿�
    -------------------------------------------------------------------
    INSERT INTO #hncom_TAdjWithHoldList_Result 
    (
        CompanySeq, BizSeq, StdYM, EndDateFr, EndDateTo, 
        UMTypeSeq, EmpName, EmpCnt, TotAmt, TaxEmpCnt, 
        TaxAmt, TaxShortageAmt, IncomeTaxAmt, ResidentTaxAmt, RuralTaxAmt, 
        IsSum, EndDate
    )
    SELECT @CompanySeq, @BizSeq, @StdYM, @EndDateFr, @EndDateTo, 
           B.MinorSeq, A."����", 1, CONVERT(DECIMAL(19,5),A."�����޿��Ѱ�"), 1, 
           CONVERT(DECIMAL(19,5),A."���������޿��Ѱ�"), 0, CONVERT(DECIMAL(19,5),A."�ⳳ�μҵ漼"), CONVERT(DECIMAL(19,5),A."�ⳳ�����漼"), CONVERT(DECIMAL(19,5),A."�ⳳ�γ�Ư��"), 
           '1', A."������"
      FROM [GHRM]..[HGHR].[ENCOM_RETIRE_CALC]   AS A 
      LEFT OUTER JOIN #Type                     AS B ON ( B.HRMSeq = 'HUN' )
     WHERE A."������" BETWEEN @EndDateFr AND @EndDateTo 
       AND A."������ڵ�" = @HRMDeptSeq
    -------------------------------------------------------------------
    -- �����޿�, END
    -------------------------------------------------------------------

    --SELECT * FROM #hncom_TAdjWithHoldList_Result 

    --ALTER TABLE #hncom_TAdjWithHoldList_Result ADD IDX_NO INT

    --return 


    DECLARE @MaxSeq INT 

    SELECT @MaxSeq = (SELECT MAX(AdjSeq) FROM hncom_TAdjWithHoldList)

    INSERT INTO hncom_TAdjWithHoldList
    (
        CompanySeq, AdjSeq, BizSeq, StdYM, EndDateFr, 
        EndDateTo, UMTypeSeq, EmpName, EmpCnt, TotAmt, 
        TaxEmpCnt, TaxAmt, TaxShortageAmt, IncomeTaxAmt, ResidentTaxAmt, 
        RuralTaxAmt, IsSum, LastUserSeq, LastDateTime, PgmSeq, EndDate 
    )
    SELECT CompanySeq, ISNULL(@MaxSeq,0) + IDX_NO, BizSeq, StdYM, EndDateFr, 
           EndDateTo, UMTypeSeq, EmpName, EmpCnt, TotAmt, 
           TaxEmpCnt, TaxAmt, TaxShortageAmt, IncomeTaxAmt, ResidentTaxAmt, 
           RuralTaxAmt, IsSum, @UserSeq, GETDATE(), @PgmSeq, ISNULL(EndDate,'')
      FROM #hncom_TAdjWithHoldList_Result

    --SELECT * FROM hncom_TAdjWithHoldList
    SELECT * FROM #hncom_TAdjWithHoldList
    

    RETURN  
    GO
begin tran 
exec hncom_SPRAdjWithHoldListIFSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <BizName>�Ѷ���</BizName>
    <StdYM>201601</StdYM>
    <EndDateFr>20151201</EndDateFr>
    <EndDateTo>20161201</EndDateTo>
    <BizSeq>1</BizSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1511151,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1032789
rollback 