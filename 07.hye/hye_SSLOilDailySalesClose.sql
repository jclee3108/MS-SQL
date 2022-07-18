  
IF OBJECT_ID('hye_SSLOilDailySalesClose') IS NOT NULL   
    DROP PROC hye_SSLOilDailySalesClose  
GO  
  
-- v2016.11.07
  
-- �����Ǹ��Ϻ�����_hye-���� by ����õ 
CREATE PROC hye_SSLOilDailySalesClose  
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
            @StdDate    NCHAR(8), 
            @p_div_code INT, 
            @p_yyyymmdd NCHAR(8), 
            @SlipKind   INT, 
            @IsClose    NCHAR(1) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @BizUnit     = ISNULL( BizUnit, 0 ),
           @StdDate     = ISNULL( StdDate, '' ), 
           @SlipKind    = ISNULL( SlipKind, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            BizUnit  INT,  
            StdDate  NCHAR(8), 
            SlipKind INT 
           )
    



    SELECT @p_div_code = @BizUnit 
    SELECT @p_yyyymmdd = @StdDate 


    DECLARE @t_PostingData TABLE 
    (
        seq               int identity,
        div_code          varchar(8)     not null,
        process_category  varchar(10)    not null,
        process_code      varchar(10)    not null,
        debit_credit      varchar(1)     not null, -- '1'����, '2':�뺯
        accnt             varchar(8)     not null,
        posting_amt_i     numeric(19,5)  not null,
        supply_amt_i      numeric(19,5)  not null DEFAULT 0 -- ���ް�
    )


	-- 1. ���� �� ������� �Ϸ� ���� üũ
   
   -- Process Category  
/*
   SD900 : ������ �ϸ��� �ڵ���ǥ ó����

   1. SD905 : ������ ���� ����ó��
   2. SD910 : ������ ���� �Ա�ó��
   3. SD915 : ������ �뿩��
   4. SD920 : ������ �뿩�� ��ȯ
   5. SD925 : ��Ʈ��ǰ ���� �߻�
   6. SD930 : ��Ʈ��ǰ ��ȯ �߻�
*/

    IF EXISTS (SELECT 1 
                 FROM hye_TSLPOSSlipRelation 
                WHERE CompanySeq = @CompanySeq 
                  AND BizUnit = @BizUnit 
                  AND StdDate = @StdDate 
                  AND UMSlipKind = @SlipKind 
              ) AND @WorkingTag = 'CC'
    BEGIN
            SELECT '��ǥ�� �ݿ��Ǿ� �ϸ����� ��� �� �� �����ϴ�.' AS Result, 9999 AS Status, 9 AS IsClose
            RETURN 
    END 

    IF @SlipKind = 1013901001
    BEGIN 
        


        SELECT @IsClose = IsClose 
          FROM hye_TSLOilSalesIsClose 
         WHERE BizUnit      = @p_div_code
           AND StdYMDate  = @p_yyyymmdd
           AND io_type = 'O' -- 2011.04.11 �߰�


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

        -- 2. ȸ�� ������ ����
        -- 2.0 ���� ������ ����
       DELETE FROM POS910T
        WHERE date_type     = 'DD'
          AND div_code      = @p_div_code
          AND process_date  = @p_yyyymmdd
          AND io_type = 'O' -- 2011.04.11 �߰�
    
        IF @WorkingTag = 'CC' 
        BEGIN 
            
            UPDATE A
               SET IsClose = '0', 
                   CloseDate = ''
              FROM hye_TSLOilSalesIsClose AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.BizUnit = @BizUnit 
               AND A.StdYMDate = @StdDate 
               AND io_type = 'O' 

            SELECT '�ϸ�����Ұ� �Ϸ� �ǽ��ϴ�.' AS Result, 0 AS Status, 2 AS IsClose
            RETURN 
        END 


        -- SD905 : ������ ���� ����ó��
        /*
            �ܻ�����             / ��ǰ����
                                 / �ΰ���
            �̼���/��������        / �ܻ�����
            truncate table POS910t
        */

    
        -- �ܻ�����
        INSERT INTO @t_PostingData
        (
            div_code,         process_category,      process_code,           
            debit_credit,     accnt,                 posting_amt_i
        )
        SELECT a.div_code,         'SD900',               'SD905',
               '1',
               ISNULL((SELECT dr_accnt1 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD905' AND case_code = 'SD905'),''),
               SUM(a.sale_amt)
          FROM pos730t a,pos350t b
         WHERE a.pay_code      = b.pay_code
           AND a.div_code      = @p_div_code
           AND a.yyyymmdd      = @p_yyyymmdd
           AND b.category IN('PRODUCT')
         GROUP BY div_code
    
    -- select * from pos730t where div_code = '801' and yyyymmdd = '20110401'
    

        -- ��ǰ���� ����
        INSERT INTO @t_PostingData
        (
            div_code,         process_category,      process_code,           
            debit_credit,     accnt,                 posting_amt_i
        )
        SELECT @p_div_code,      'SD900',               'SD905',
               '2',
               ISNULL((SELECT cr_accnt1 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD905' AND case_code = 'SD905'),''),
               SUM(ISNULL(x.sale_amt,0))
          FROM (
                SELECT SUM(a.sale_amt) AS sale_amt
                  FROM pos720t a,pos350t b
                 WHERE a.pay_code      = b.pay_code
                   AND a.div_code      = @p_div_code
                   AND a.yyyymmdd      = @p_yyyymmdd
                   AND b.category IN('PRODUCT')
               ) as x

        -- �ΰ��� ����
        INSERT INTO @t_PostingData
        (
            div_code,         process_category,      process_code,           
            debit_credit,     accnt,                 posting_amt_i, 
            supply_amt_i
        )
        SELECT @p_div_code,         'SD900',               'SD905',
               '2',
               ISNULL((SELECT cr_accnt2 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD905' AND case_code = 'SD905'),''),
               SUM(ISNULL(x.vat_amt,0)), SUM(ISNULL(x.sale_amt,0))
          FROM (
                -- �Ϲݻ�ǰ �ΰ���
                SELECT SUM(a.sale_amt) AS sale_amt, SUM(a.vat_amt) AS vat_amt
                  FROM pos720t a,pos350t b
                 WHERE a.pay_code      = b.pay_code
                   AND a.div_code      = @p_div_code
                   AND a.yyyymmdd      = @p_yyyymmdd
                   AND b.category IN('PRODUCT')
                 GROUP BY div_code
               ) as x

        -- �������ܺ� ����ó��( ����, �ܻ� ����)
        INSERT INTO @t_PostingData
        (
            div_code,         process_category,      process_code,           
            debit_credit,     accnt,                 posting_amt_i
        )
        SELECT a.div_code,         'SD900',               'SD905',
               '1',
               b.accnt_code,
               SUM(a.sale_amt)
          FROM pos730t a, pos350t b
         WHERE a.pay_code    = b.pay_code
           AND a.div_code      = @p_div_code
           AND a.yyyymmdd      = @p_yyyymmdd
           AND b.category IN('PRODUCT')
           AND a.pay_code NOT IN('CASH','AR')
         GROUP BY a.div_code, b.accnt_code
    
        -- �ܻ����� ó�� (����, �ܻ� ���ܰ�)
        INSERT INTO @t_PostingData
        (
            div_code,         process_category,      process_code,           
            debit_credit,     accnt,                 posting_amt_i
        )
        SELECT a.div_code,         'SD900',               'SD905',
               '2',
               ISNULL((SELECT cr_accnt3 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD905' AND case_code = 'SD905'),''),
               SUM(a.sale_amt)
          FROM pos730t a, pos350t b
         WHERE a.pay_code    = b.pay_code
           AND a.div_code      = @p_div_code
           AND a.yyyymmdd      = @p_yyyymmdd
           AND b.category IN('PRODUCT')
           AND a.pay_code NOT IN('CASH','AR')
         GROUP BY div_code

        ---- SD910 : ������ ���� �Ա�ó�� �Ϸ�   -- SD910 : ������ ���� �Ա�ó�� �Ϸ�   -- SD910 : ������ ���� �Ա�ó�� �Ϸ�   -- SD910 : ������ ���� �Ա�ó�� �Ϸ�
        INSERT INTO POS910t
        (
            div_code,          date_type,     process_date,     process_category,
            process_code,      posting_seq,   debit_credit,     accnt,
            amount_i,          supply_amt,    io_type
        )
        -- descr, manage_code1,manage_value1,manage_code2,manage_value2,manage_code3,manage_value3,manage_code4,manage_value4,manage_code5,manage_value5,manage_code6,manage_value6)
        SELECT div_code,          'DD',          @p_yyyymmdd,      process_category,      
               process_code,      seq,           debit_credit,     accnt,            
               posting_amt_i,     supply_amt_i,  'O'
               -- ROW_NUMBER() OVER (ORDER BY yyyymm, wh_flag, div_code, from_work_shop, from_item_code, allotted_cost DESC) 
          FROM @t_PostingData
         WHERE posting_amt_i != 0
        
        INSERT INTO hye_TSLOilSalesIsClose
        (
            CompanySeq, BizUnit, StdYMDate, IsClose, CloseDate, 
            io_type, LastUserSeq, LastDateTime, PgmSeq
        )
        SELECT @CompanySeq, @BizUnit, @StdDate, '0', '', 
               'O', @UserSeq, GETDATE(), @PgmSeq 
         WHERE NOT EXISTS (SELECT 1 FROM hye_TSLOilSalesIsClose WHERE CompanySeq = @CompanySeq AND BizUnit = @BizUnit AND StdYMDate = @StdDate)
        
        UPDATE A
           SET IsClose = '1' , 
               CloseDate = CONVERT(NCHAR(8),GETDATE(),112)
          FROM hye_TSLOilSalesIsClose AS A 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.BizUnit = @BizUnit 
           AND A.StdYMDate = @StdDate 
           AND A.io_type = 'O'
        
        SELECT '�ϸ����� �Ϸ� �Ǿ����ϴ�.' AS Result, 0 AS Status, 1 AS IsClose
    END 
    ELSE 
    BEGIN 


        SELECT @IsClose = IsClose 
          FROM hye_TSLOilSalesIsClose 
         WHERE BizUnit      = @p_div_code
           AND StdYMDate  = @p_yyyymmdd
           AND io_type = 'I' -- 2011.04.11 �߰�


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

        -- 2. ȸ�� ������ ����
        -- 2.0 ���� ������ ����
        DELETE FROM POS910T
         WHERE date_type     = 'DD'
           AND div_code      = @p_div_code
           AND process_date  = @p_yyyymmdd
           AND io_type = 'I' 

        IF @WorkingTag = 'CC' 
        BEGIN 
            UPDATE A
               SET IsClose = '0', 
                   CloseDate = CONVERT(NCHAR(8),GETDATE(),112)
              FROM hye_TSLOilSalesIsClose AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.BizUnit = @BizUnit 
               AND A.StdYMDate = @StdDate 
               AND io_type = 'I' 

            SELECT '�ϸ�����Ұ� �Ϸ� �Ǿ����ϴ�.' AS Result, 0 AS Status, 2 AS IsClose
            RETURN 
        END 
                        
--   -- SD905 : ������ ���� ����ó�� �Ϸ�   -- SD905 : ������ ���� ����ó�� �Ϸ�   -- SD905 : ������ ���� ����ó�� �Ϸ�   -- SD905 : ������ ���� ����ó�� �Ϸ�
                        


   -- SD910 : ������ ���� �Ա�ó��
   /*
      ���뿹��                     / �ܻ�����
      �ǰ��������(ī�������)     / �������ܺ� 
      ������

      -- ��ȸ�� �� �ŷ����� ���뿹���� �ƴ� ���ó����.
   */

   -- exec P_posSummaryPostingDailyData 'KOR','BATCH', '1','901','20090601','kayce','KAYCE','111.11.11.111','',''

   -- ��ȸ�� �ŷ��ݾ��� ���ó����.
   DECLARE @v_inner_trade_amt  numeric(19,5) 

   SELECT @v_inner_trade_amt = SUM(in_amt)
     FROM pos735t a
    WHERE a.div_code = @p_div_code
      AND a.yyyymmdd      = @p_yyyymmdd
      AND a.pos_custom_code IN( SELECT pos_code
                                  FROM pos360t
                                 WHERE div_code = @p_div_code
                                   AND pay_code = 'HEAD_QT') 



   -- ���뿹��
   INSERT INTO @t_PostingData(div_code,         process_category,      process_code,           
                              debit_credit,     accnt,                 posting_amt_i)
                       SELECT a.div_code,         'SD900',               'SD910',
                              '1',
                              ISNULL((SELECT dr_accnt1 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD910' AND case_code = 'SD910'),''),
                              SUM(a.in_amt) - ISNULL(@v_inner_trade_amt,0)
                         FROM pos730t a, pos350t b
                        WHERE a.pay_code      = b.pay_code
                          AND a.div_code      = @p_div_code
                          AND a.yyyymmdd      = @p_yyyymmdd
                          AND b.category IN('PRODUCT','SERVICE')
                          AND a.pay_code NOT IN('COUPON') -- �������α� ����
                          AND b.receive_posting_yn = 'Y'
                        GROUP BY a.div_code
    
   IF( ISNULL(@v_inner_trade_amt,0) <> 0)
   BEGIN
      INSERT INTO @t_PostingData(div_code,         process_category,      process_code,           
                                 debit_credit,     accnt,                 posting_amt_i)
                          SELECT @p_div_code,      'SD900',               'SD910',
                                 '1',
                                 (SELECT TOP 1 accnt_code FROM pos350t WHERE pay_code = 'HEAD_QT'),
                                 @v_inner_trade_amt
   END



   -- ������(�ܻ����� �߿��� ���ڱ������� ó���� ��)
   IF EXISTS( SELECT * 
                FROM pos730t a
               WHERE a.div_code      = @p_div_code
                 AND a.yyyymmdd      = @p_yyyymmdd
                 AND a.pay_code IN('AR')
                 AND a.in_amt2 <> 0
            )
   BEGIN
      INSERT INTO @t_PostingData(div_code,         process_category,      process_code,           
                                 debit_credit,     accnt,                 posting_amt_i)
                          SELECT a.div_code,         'SD900',               'SD910',
                                 '1',
                                 ISNULL((SELECT dr_accnt3 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD910' AND case_code = 'SD910'),''),
                                 SUM(a.in_amt2)
                            FROM pos730t a
                           WHERE a.div_code      = @p_div_code
                             AND a.yyyymmdd      = @p_yyyymmdd
                             AND a.pay_code IN('AR')
                           GROUP BY a.div_code
   END

   -- �ǰ��������(ī�������)
   INSERT INTO @t_PostingData(div_code,         process_category,      process_code,           
                              debit_credit,     accnt,                 posting_amt_i)
                       SELECT a.div_code,         'SD900',               'SD910',
                              '1',
                              ISNULL((SELECT dr_accnt2 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD910' AND case_code = 'SD910'),''),
                              SUM(a.charge_amt)
                         FROM pos730t a, pos350t b
                        WHERE a.pay_code      = b.pay_code
                          AND a.div_code      = @p_div_code
                          AND a.yyyymmdd      = @p_yyyymmdd
                          AND b.category IN('PRODUCT')
                        GROUP BY a.div_code


   -- �ܻ����� (����/�ܻ�ǿ� ���� ó��)
   INSERT INTO @t_PostingData(div_code,         process_category,      process_code,           
                              debit_credit,     accnt,                 posting_amt_i)
                       SELECT a.div_code,         'SD900',               'SD910',
                              '2',
                              ISNULL((SELECT cr_accnt1 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD910' AND case_code = 'SD910'),''),
                              SUM(a.in_amt + a.charge_amt + a.in_amt2)
                         FROM pos730t a, pos350t b
                        WHERE a.pay_code      = b.pay_code
                          AND a.div_code      = @p_div_code
                          AND a.yyyymmdd      = @p_yyyymmdd
                          AND b.category IN('PRODUCT')
                          AND a.pay_code IN('CASH','AR') 
                        GROUP BY div_code


   -- �������ܺ� ����ó��
   INSERT INTO @t_PostingData(div_code,         process_category,      process_code,           
                              debit_credit,     accnt,                 posting_amt_i)
                       SELECT div_code,         'SD900',               'SD910',
                              '2',
                              b.accnt_code,
                              --ISNULL((SELECT cr_accnt2 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD910' AND case_code = 'SD910'),''),
                              SUM(in_amt + charge_amt)
                         FROM pos730t a, pos350t b
                        WHERE a.pay_code    = b.pay_code
                          AND a.div_code      = @p_div_code
                          AND a.yyyymmdd      = @p_yyyymmdd
                          AND a.pay_code NOT IN('CASH','AR','COUPON')
                          AND b.category IN('PRODUCT')
                          AND b.receive_posting_yn = 'Y'
                        GROUP BY a.div_code, b.accnt_code




   -- ������ / �ҽ������� ���� ����� ó��
   INSERT INTO @t_PostingData(div_code,         process_category,      process_code,           
                              debit_credit,     accnt,                 posting_amt_i)
                       SELECT div_code,         'SD900',               'SD910',
                              '2',
                              b.accnt_code,
                              --ISNULL((SELECT cr_accnt2 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD910' AND case_code = 'SD910'),''),
                              SUM(in_amt + charge_amt)
                         FROM pos730t a, pos350t b
                        WHERE a.pay_code    = b.pay_code
                          AND a.div_code      = @p_div_code
                          AND a.yyyymmdd      = @p_yyyymmdd
                          AND a.pay_code IN('WASH','B_PRODUCT')
                          AND b.receive_posting_yn = 'Y'
                        GROUP BY a.div_code, b.accnt_code


   -- SD915 : ������ �뿩�� 
   /*
      �̼���/����                 / �繫�Ұ���
   */

   -- exec P_posSummaryPostingDailyData 'KOR','BATCH', '1','901','20090601','kayce','KAYCE','111.11.11.111','',''

   -- �̼���/����
   INSERT INTO @t_PostingData(div_code,         process_category,      process_code,           
                              debit_credit,     accnt,                 posting_amt_i)
                       SELECT a.div_code,         'SD900',               'SD915',
                              '1',
                              ISNULL((SELECT dr_accnt1 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD915' AND case_code = 'SD915'),''),
                              SUM(a.sale_amt)
                         FROM pos730t a, pos350t b
                        WHERE a.pay_code      = b.pay_code
                          AND a.div_code      = @p_div_code
                          AND a.yyyymmdd      = @p_yyyymmdd
                          AND b.category IN('LOAN')
                        GROUP BY a.div_code

   -- �繫�� ����
   INSERT INTO @t_PostingData(div_code,         process_category,      process_code,           
                              debit_credit,     accnt,                 posting_amt_i)
                       SELECT a.div_code,         'SD900',               'SD915',
                              '2',
                              ISNULL((SELECT cr_accnt1 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD915' AND case_code = 'SD915'),''),
                              SUM(a.sale_amt)
                         FROM pos730t a, pos350t b
                        WHERE a.pay_code      = b.pay_code
                          AND a.div_code      = @p_div_code
                          AND a.yyyymmdd      = @p_yyyymmdd
                          AND b.category IN('LOAN')
                        GROUP BY a.div_code




   -- SD920 : ������ �뿩�� ��ȯ
   /*
      ���뿹��                / �̼���/���
      �������α�(��)
   */

   -- exec P_posSummaryPostingDailyData 'KOR','BATCH', '1','901','20090806','kayce','KAYCE','111.11.11.111','',''

   -- ���뿹�� ����
   INSERT INTO @t_PostingData(div_code,         process_category,      process_code,           
                              debit_credit,     accnt,                 posting_amt_i)
                       SELECT a.div_code,         'SD900',               'SD920',
                              '1',
                              ISNULL((SELECT dr_accnt1 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD920' AND case_code = 'SD920'),''),
                              ISNULL(SUM(a.in_amt),0)
                         FROM pos730t a, pos350t b
                        WHERE a.pay_code      = b.pay_code
                          AND a.div_code      = @p_div_code
                          AND a.yyyymmdd      = @p_yyyymmdd
                          AND b.category IN('LOAN')
                        GROUP BY a.div_code


   -- �������α�(��)
   INSERT INTO @t_PostingData(div_code,         process_category,      process_code,           
                              debit_credit,     accnt,                 posting_amt_i)
                       SELECT a.div_code,         'SD900',               'SD920',
                              '1',
                              ISNULL((SELECT dr_accnt2 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD920' AND case_code = 'SD920'),''),
                              ISNULL(SUM(a.charge_amt),0)
                         FROM pos730t a, pos350t b
                        WHERE a.pay_code      = b.pay_code
                          AND a.div_code      = @p_div_code
                          AND a.yyyymmdd      = @p_yyyymmdd
                          AND b.category IN('LOAN')
                        GROUP BY a.div_code




   -- �̼���/����
   INSERT INTO @t_PostingData(div_code,         process_category,      process_code,           
                              debit_credit,     accnt,                 posting_amt_i)
                       SELECT a.div_code,         'SD900',               'SD920',
                              '2',
                              ISNULL((SELECT cr_accnt1 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD920' AND case_code = 'SD920'),''),
                              ISNULL(SUM(a.in_amt + a.charge_amt),0)
                         FROM pos730t a, pos350t b
                        WHERE a.pay_code      = b.pay_code
                          AND a.div_code      = @p_div_code
                          AND a.yyyymmdd      = @p_yyyymmdd
                          AND b.category IN('LOAN')
                        GROUP BY a.div_code


   -- SD925 : ��Ʈ��ǰ ���� �߻�
   /*
      �̼���               / �����ޱ�
                           / �ΰ���
   */

   -- �̼���
   INSERT INTO @t_PostingData(div_code,         process_category,      process_code,           
                              debit_credit,     accnt,                 posting_amt_i)
                       SELECT a.div_code,         'SD900',               'SD925',
                              '1',
                              ISNULL((SELECT dr_accnt1 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD925' AND case_code = 'SD925'),''),
                              ISNULL(SUM(a.sale_amt),0)
                         FROM pos730t a,pos350t b
                        WHERE a.pay_code      = b.pay_code
                          AND a.div_code      = @p_div_code
                          AND a.yyyymmdd      = @p_yyyymmdd
                          AND b.category IN('EXTRA')
                        GROUP BY div_code

   -- �����ޱ�
   INSERT INTO @t_PostingData(div_code,         process_category,      process_code,           
                              debit_credit,     accnt,                 posting_amt_i)
                       SELECT @p_div_code,      'SD900',               'SD925',
                              '2',
                              ISNULL((SELECT cr_accnt1 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD925' AND case_code = 'SD925'),''),
                              ISNULL(SUM(ISNULL(x.sale_amt,0)),0)
                         FROM
                            (
                             SELECT SUM(a.sale_amt) - FLOOR(SUM(a.sale_amt)/11) AS sale_amt
                               FROM pos730t a,pos350t b
                              WHERE a.pay_code      = b.pay_code
                                AND a.div_code      = @p_div_code
                                AND a.yyyymmdd      = @p_yyyymmdd
                                AND b.category IN('EXTRA')
                              ) x

   -- �ΰ��� ����
   INSERT INTO @t_PostingData(div_code,         process_category,      process_code,           
                              debit_credit,     accnt,                 posting_amt_i,  supply_amt_i)
                       SELECT @p_div_code,         'SD900',               'SD925',
                              '2',
                              ISNULL((SELECT cr_accnt2 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD925' AND case_code = 'SD925'),''),
                              ISNULL(SUM(ISNULL(x.vat_amt,0)),0), ISNULL(SUM(ISNULL(x.sale_amt,0)),0)
                         FROM 
                             (
                              -- �Ϲݻ�ǰ �ΰ���
                               SELECT SUM(a.sale_amt) - FLOOR(SUM(a.sale_amt)/11) AS sale_amt, FLOOR(SUM(a.sale_amt)/11) AS vat_amt
                                 FROM pos730t a,pos350t b
                                WHERE a.pay_code      = b.pay_code
                                  AND a.div_code      = @p_div_code
                                  AND a.yyyymmdd      = @p_yyyymmdd
                                  AND b.category IN('EXTRA')
                                GROUP BY div_code
                              
                             ) x

   -- SD930 : ��Ʈ��ǰ �Ա� �߻�
   /*
      ���뿹��            / �̼���
   */

   -- ���뿹��
   INSERT INTO @t_PostingData(div_code,         process_category,      process_code,           
                              debit_credit,     accnt,                 posting_amt_i)
                       SELECT a.div_code,         'SD900',               'SD930',
                              '1',
                              ISNULL((SELECT dr_accnt1 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD930' AND case_code = 'SD930'),''),
                              SUM(a.in_amt)
                         FROM pos730t a, pos350t b
                        WHERE a.pay_code      = b.pay_code
                          AND a.div_code      = @p_div_code
                          AND a.yyyymmdd      = @p_yyyymmdd
                          AND b.category IN('EXTRA')
                          AND b.receive_posting_yn = 'Y'
                        GROUP BY a.div_code

  

   --�̼���
   INSERT INTO @t_PostingData(div_code,         process_category,      process_code,           
                              debit_credit,     accnt,                 posting_amt_i)
                       SELECT a.div_code,         'SD900',               'SD930',
                              '2',
                              ISNULL((SELECT cr_accnt1 FROM aap110t WHERE sys_type = 'SD900' AND sys_code = 'SD930' AND case_code = 'SD930'),''),
                              SUM(a.in_amt + a.charge_amt)
                         FROM pos730t a, pos350t b
                        WHERE a.pay_code      = b.pay_code
                          AND a.div_code      = @p_div_code
                          AND a.yyyymmdd      = @p_yyyymmdd
                          AND b.category IN('EXTRA')
                        GROUP BY div_code

   INSERT INTO POS910t(div_code,          date_type,     process_date,     process_category,
                       process_code,      posting_seq,   debit_credit,     accnt,
                       amount_i,          supply_amt,    io_type)--io_type 2011.04.11        
               -- descr, manage_code1,manage_value1,manage_code2,manage_value2,manage_code3,manage_value3,manage_code4,manage_value4,manage_code5,manage_value5,manage_code6,manage_value6)
                SELECT div_code,          'DD',          @p_yyyymmdd,      process_category,      
                       process_code,      seq,           debit_credit,     accnt,            
                       posting_amt_i,     supply_amt_i,  'I'
                       -- ROW_NUMBER() OVER (ORDER BY yyyymm, wh_flag, div_code, from_work_shop, from_item_code, allotted_cost DESC) 
                  FROM @t_PostingData
                 WHERE posting_amt_i != 0
        
        INSERT INTO hye_TSLOilSalesIsClose
        (
            CompanySeq, BizUnit, StdYMDate, IsClose, CloseDate, 
            io_type, LastUserSeq, LastDateTime, PgmSeq
        )
        SELECT @CompanySeq, @BizUnit, @StdDate, '0', '', 
               'I', @UserSeq, GETDATE(), @PgmSeq 
         WHERE NOT EXISTS (SELECT 1 FROM hye_TSLOilSalesIsClose WHERE CompanySeq = @CompanySeq AND BizUnit = @BizUnit AND StdYMDate = @StdDate)
        
        UPDATE A
           SET IsClose = '1' , 
               CloseDate = CONVERT(NCHAR(8),GETDATE(),112)
          FROM hye_TSLOilSalesIsClose AS A 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.BizUnit = @BizUnit 
           AND A.StdYMDate = @StdDate 
           AND A.io_type = 'I'
        
        SELECT '�ϸ����� �Ϸ� �Ǿ����ϴ�.' AS Result, 0 AS Status, 1 AS IsClose

    END 

    RETURN  
GO
begin tran 
exec hye_SSLOilDailySalesClose @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <BizUnit>801</BizUnit>
    <StdDate>20160601</StdDate>
    <SlipKind>1013901001</SlipKind>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730106,@WorkingTag=N'C',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730031
rollback 
