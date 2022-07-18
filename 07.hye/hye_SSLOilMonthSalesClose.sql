IF OBJECT_ID('hye_SSLOilMonthSalesClose') IS NOT NULL 
    DROP PROC hye_SSLOilMonthSalesClose
GO 

-- v2016.10.31 
  
-- �����Ǹſ�������_hye-���� by ����õ 
CREATE PROC hye_SSLOilMonthSalesClose  
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
            @BizUnit    INT,  
            @StdYM      NCHAR(6), 
            @p_div_code INT, 
            @p_yyyymm   NCHAR(6), 
            @POSType    NVARCHAR(20), 
            @IsClose    NCHAR(1) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @BizUnit     = ISNULL( BizUnit, 0 ),
           @StdYM       = ISNULL( StdYM, '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock15', @xmlFlags )       
      WITH (
            BizUnit     INT,  
            StdYM       NCHAR(6)
           )
    
    DECLARE @v_bill_amt numeric(19,5),   -- ���ݰ�꼭 ���ް���
            @v_bill_vat_amt numeric(19,5)    -- ���ݰ�꼭 �ΰ���

    SELECT @p_div_code = @BizUnit 
    SELECT @p_yyyymm = @StdYM 


    
    IF EXISTS (SELECT 1 
                 FROM hye_TSLPOSSlipMonthRelation 
                WHERE CompanySeq = @CompanySeq 
                  AND BizUnit = @BizUnit 
                  AND StdYM = @StdYM 
              ) AND @WorkingTag = 'CC'
    BEGIN
            SELECT '��ǥ�� �ݿ��Ǿ� �������� ��� �� �� �����ϴ�.' AS Result, 9999 AS Status, 9 AS IsClose
            RETURN 
    END 


    SELECT @IsClose = IsClose 
      FROM hye_TSLOilSalesIsClose 
     WHERE BizUnit      = @BizUnit
       AND StdYMDate    = @StdYM
       AND io_type      = 'O' -- 2011.04.11 �߰�


    IF @WorkingTag = 'C' AND ISNULL(@IsClose,'0') = '1' 
    BEGIN 
        SELECT '�̹� �ϸ����� �Ϸᰡ �Ǿ� �ֽ��ϴ�.' AS Result, 9999 AS Status, 9 AS IsClose
        RETURN 
    END 

    IF @WorkingTag = 'CC' AND ISNULL(@IsClose,'0') = '0' 
    BEGIN 
        SELECT '�̹� �ϸ����� ��Ұ� �Ǿ� �ֽ��ϴ�.' AS Result, 9999 AS Status, 9 AS IsClose
        RETURN 
    END 
    
    -- 1. ���� �� ������� �Ϸ� ���� üũ
   
    -- Process Category  
/*
   SD955 : ���� �繫�� ����ó��
   SD956 : ���� �繫�� ����ó��
*/


    DECLARE @t_PostingData TABLE 
    (
        seq               int identity,
        div_code          varchar(8)     not null,
        process_category  varchar(10)    not null,
        process_code      varchar(10)    not null,
        debit_credit      varchar(1)     not null, -- '1'����, '2':�뺯
        accnt             varchar(8)     not null,
        posting_amt_i     numeric(19,5)  not null,
        supply_amt_i      numeric(19,5)  not null DEFAULT 0,-- ���ް�
        bill_type         varchar(2)     not null DEFAULT ''
    )

    -- 2. ȸ�� ������ ����
    -- 2.0 ���� ������ ����
    DELETE FROM POS910T
    WHERE date_type     = 'MM'
      AND div_code      = @p_div_code
      AND process_date  = @p_yyyymm
    
    IF @WorkingTag = 'CC' 
    BEGIN 

        UPDATE A
            SET IsClose = '0', 
                CloseDate = ''
            FROM hye_TSLOilSalesIsClose AS A 
            WHERE A.CompanySeq = @CompanySeq 
            AND A.BizUnit = @BizUnit 
            AND A.StdYMDate = @StdYM 
            AND io_type = 'O' 

        SELECT '��������Ұ� �Ϸ� �ǽ��ϴ�.' AS Result, 0 AS Status, 2 AS IsClose
        RETURN 
    END 

   -- POS ����
   SELECT @POSType = CASE WHEN IsOil = '1' THEN 'SKPOS' ELSE 'JWPOS' END 
     FROM hye_TCOMPOSEnv
    WHERE CompanySeq = @CompanySeq 
      AND BizUnit = @BizUnit 



   -- SK POS�� ���
   IF (@POSType  = 'SKPOS')
   BEGIN
        -- �ŷ�ó �ű԰� ä��
        -- ����� ��ȣ�� �ֹ� ��ȣ���� '-' ���ֱ�
        UPDATE skpMMTaxInvoice
           SET busirgst_no = REPLACE(ISNULL(busirgst_no,''),'-',''),
               jumin_no = REPLACE(ISNULL(jumin_no,''),'-','')
         WHERE div_code = @p_div_code
           AND close_ym   = @p_yyyymm
    
        SELECT a.close_date AS bill_date,  
               @p_div_code AS site_code, 
               a.supt_amt AS supply_amt,    
               a.vatt_amt AS tax_amt,   
               tott_amt     AS total_amt
          INTO #skpMMTaxInvoice
          FROM skpMMTaxInvoice a
         WHERE a.div_code = @p_div_code
           AND a.close_ym = @p_yyyymm
         ORDER BY a.close_date, a.cus_code


        SELECT @v_bill_amt      = ISNULL(x.supply_amt,0),
               @v_bill_vat_amt  = ISNULL(x.tax_amt,0)
          FROM ( 
                SELECT SUM(supply_amt) AS supply_amt,
                       SUM(tax_amt) AS tax_amt
                  FROM #skpMMTaxInvoice a
                 WHERE a.bill_date LIKE @p_yyyymm + '%'
                   AND a.site_code = @p_div_code
               ) x    
    END 
   -------------------------------------------------------------------------------------------------------------------------
   -------------------------------------------------------------------------------------------------------------------------
   -- ���� POS�� ���
   ELSE IF (@POSType  = 'JWPOS')
   BEGIN

        -- ����� ��ȣ�� �ֹ� ��ȣ���� '-' ���ֱ�
        UPDATE jwpMMTaxInvoice
           SET vehicle_reg_num = REPLACE(ISNULL(vehicle_reg_num,''),'-',''),
               social_no = REPLACE(ISNULL(social_no,''),'-','')
         WHERE div_code = @p_div_code
           AND yyyymm   = @p_yyyymm
        

        SELECT a.create_date AS bill_date,  
               @p_div_code AS site_code, 
               a.sale_amt AS supply_amt,    
               a.vat_amt AS tax_amt,   
               a.total_amt AS total_amt
          INTO #jwpMMTaxInvoice
          FROM jwpMMTaxInvoice a
         WHERE a.div_code        = @p_div_code
           AND a.create_date     LIKE @p_yyyymm + '%'
         GROUP BY a.create_date, a.cs_code, a.vehicle_reg_num , a.sale_amt,  a.vat_amt,  a.total_amt, a.item_code, a.seq
    
        SELECT @v_bill_amt      = ISNULL(x.supply_amt,0),
               @v_bill_vat_amt  = ISNULL(x.tax_amt,0)
          FROM ( 
                SELECT SUM(supply_amt) AS supply_amt,
                       SUM(tax_amt) AS tax_amt
                  FROM #jwpMMTaxInvoice a
                 WHERE a.bill_date LIKE @p_yyyymm + '%'
                   AND a.site_code = @p_div_code
               ) x    

   END



   -- SD952 : �ΰ�����������(����<->��꼭)
   -- ���� ����-��Ÿ(���ݸ���)�� ó���� �ǵ� �� ���� ���ݰ�꼭 ������ �ݾ׸�ŭ�� ����
   -- �ΰ��� ������ �ٲپ� �ش�
   /*
                / (-)�ΰ���������  ( �ΰ������� - 'AB':����-��Ÿ)
                / (+)�ΰ���������  ( �ΰ������� - '':��Ÿ��꼭 ��������� ���� ����Ǳ� ������ ��ǥ�󿡴� �ΰ��� ���������� ������ ó��)

   */

    
    -- �ݾ� <> 0 �� ��� ��ǥ ó��
    IF (@v_bill_vat_amt <> 0)
    BEGIN

        -- (-)�����ΰ���
        INSERT INTO @t_PostingData
        (
            div_code,         process_category,      process_code,           
            debit_credit,     accnt,                 posting_amt_i,   supply_amt_i, bill_type
        )
        SELECT @p_div_code,         'SD950',               'SD952',
               '2',
               ISNULL((SELECT cr_accnt1 FROM aap110t WHERE sys_type = 'SD950' AND sys_code = 'SD952' AND case_code = 'SD952'),''),
               @v_bill_vat_amt * (-1) , @v_bill_amt * (-1) , 'AB'

        -- (+)�����ΰ���
        INSERT INTO @t_PostingData
        (
            div_code,         process_category,      process_code,           
            debit_credit,     accnt,                 posting_amt_i,   supply_amt_i, bill_type
        )
        SELECT @p_div_code,         'SD950',               'SD952',
               '2',
               ISNULL((SELECT cr_accnt1 FROM aap110t WHERE sys_type = 'SD950' AND sys_code = 'SD952' AND case_code = 'SD952'),''),
               @v_bill_vat_amt, @v_bill_amt, ''

    END
    
    --select * from @t_PostingData 
    --return 
    
    INSERT INTO POS910t
    (
        div_code,          date_type,     process_date,     process_category,
        process_code,      posting_seq,   debit_credit,     accnt,
        amount_i,          supply_amt,    bill_type, io_type
    )            
    SELECT div_code,          'MM',          @p_yyyymm,      process_category,      
           process_code,      seq,           debit_credit,     accnt,            
           posting_amt_i,     supply_amt_i,  bill_type, 'O'
      FROM @t_PostingData
     WHERE posting_amt_i != 0
        
    INSERT INTO hye_TSLOilSalesIsClose
    (
        CompanySeq, BizUnit, StdYMDate, IsClose, CloseDate, 
        io_type, LastUserSeq, LastDateTime, PgmSeq
    )
    SELECT @CompanySeq, @BizUnit, @StdYM, '0', '', 
            'O', @UserSeq, GETDATE(), @PgmSeq 
        WHERE NOT EXISTS (SELECT 1 FROM hye_TSLOilSalesIsClose WHERE CompanySeq = @CompanySeq AND BizUnit = @BizUnit AND StdYMDate = @StdYM)
        
    UPDATE A
        SET IsClose = '1' , 
            CloseDate = CONVERT(NCHAR(8),GETDATE(),112)
        FROM hye_TSLOilSalesIsClose AS A 
        WHERE A.CompanySeq = @CompanySeq 
        AND A.BizUnit = @BizUnit 
        AND A.StdYMDate = @StdYM
        AND A.io_type = 'O'

    SELECT '�������� �Ϸ� �Ǿ����ϴ�.' AS Result, 0 AS Status, 1 AS IsClose
    
    RETURN  
GO
begin tran 
exec hye_SSLOilMonthSalesClose @xmlDocument=N'<ROOT>
  <DataBlock15>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock15</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <BizUnit>902</BizUnit>
    <StdYM>201606</StdYM>
  </DataBlock15>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730140,@WorkingTag=N'C',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730044
rollback 