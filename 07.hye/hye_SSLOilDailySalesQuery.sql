IF OBJECT_ID('hye_SSLOilDailySalesQuery') IS NOT NULL 
    DROP PROC hye_SSLOilDailySalesQuery
GO

-- v2016.12.01

-- 주유소판매일보등록-조회 by이재천 
CREATE PROC hye_SSLOilDailySalesQuery
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
            -- 조회조건 
            @BizUnit        INT,
            @StdDate        NCHAR(8), 
            @p_div_code     NVARCHAR(10), -- POS 사업장 
            @SlipKind       INT, 
            @RootDataBlock  NVARCHAR(100), 
            @IsCfm          NCHAR(1) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument 
    

    IF @PgmSeq = 77730031 -- 주충판매일보마감
        SELECT @RootDataBlock = N'/ROOT/DataBlock1'
    ELSE 
        SELECT @RootDataBlock = N'/ROOT/DataBlock15'

    SELECT @BizUnit     = ISNULL( BizUnit, 0 ),
           @StdDate     = ISNULL( StdDate, '' ), 
           @SlipKind    = ISNULL( SlipKind, 0 )
    
      FROM OPENXML( @docHandle, @RootDataBlock, @xmlFlags )     
      WITH (
              BizUnit    INT,
              StdDate    NCHAR(8), 
              SlipKind   INT 
           )  
    
    IF @PgmSeq = 77730031 -- 주충판매일보마감
    BEGIN
        SELECT @IsCfm = IsCfm 
            FROM hye_TSLOilSalesIsCfm AS A 
            WHERE A.CompanySeq = @CompanySeq 
            AND A.BizUnit = @BizUnit 
            AND StdYMDate = @StdDate 
    
        IF ISNULL(@IsCfm,'0') = '0' 
        BEGIN
            SELECT 999 AS Status, '사업장에서 제출하지 않았습니다.' AS Result, @IsCfm AS IsCfm 

            SELECT 2 
            SELECT 3
            SELECT 4 
            SELECT 5 
            SELECT 6 
            SELECT 7 
            SELECT 8 
            SELECT 9 
            SELECT 10 
            RETURN
        END 
    END 

    /*
    -- Genuine ERP 사업부문과 B2B ERP 사업장 연결
    SELECT A.ValueSeq AS BizUnit, B.ValueText AS  POSBizUnit 
      INTO #POSBizUnit
      FROM _TDAUMinorValue AS A 
      LEFT OUTER JOIN _TDAUMinorValue AS B ON ( B.CompanySeq = 1 AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000002 ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.MajorSeq = 1013753
       AND A.Serl = 1000001

    SELECT @p_div_code = POSBizUnit 
      FROM #POSBizUnit
     WHERE BizUnit = @BizUnit 
    */

    SELECT @p_div_code = @BizUnit 

    
    -- 품목Mapping 
    SELECT D.ItemName, D.ItemSeq, B.ValueText AS POSItemSeq
      INTO #TDAItem 
      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAItem          AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = C.ValueSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.MajorSeq = 1013797
       

    ---------------------------------------------------------------------------------------------------
    -- 계기현황 
    ---------------------------------------------------------------------------------------------------
   SELECT a.div_code,
          a.yyyymmdd,
          A.item_code, 
          C.ItemName AS item_name,
          a.tank_no,
          a.nozzle_no,
          a.before_meter,
          a.current_meter,
          a.flow_qty,
          a.extra_out_qty,
          a.insp_qty,
          a.trans_in_qty,
          a.trans_out_qty,
          a.keeping_qty,
          a.self_consume_qty,
          a.net_sale_qty,
		  a.descr, 
          1 as sort, 
          0 AS Status, 
          @IsCfm AS IsCfm
     INTO #SS1 
     FROM pos700t a LEFT OUTER JOIN
          ( SELECT pos_code, erp_code, sort_seq
              FROM fgs310t 
             WHERE div_code = @p_div_code
               AND code_type = 'POS004'
            ) b ON a.item_code = b.erp_code
     LEFT OUTER JOIN #TDAItem AS C ON ( C.POSItemSeq = A.item_code ) 
    WHERE a.div_code = @p_div_code
      AND a.yyyymmdd = @StdDate 
    ORDER BY ISNULL(b.sort_seq,9999), a.item_code, a.tank_no, a.nozzle_no
    
    -- 소계 
    INSERT INTO #SS1 
    SELECT div_code, 
           yyyymmdd, 
           item_code, 
           item_name, 
           '소계' as tank_no, 
           '' as nozzle_no, 
           SUM(ISNULL(before_meter,0)) as before_meter, 
           SUM(ISNULL(current_meter,0)) as current_meter, 
           SUM(ISNULL(flow_qty,0)) as flow_qty, 
           SUM(ISNULL(extra_out_qty,0)) as extra_out_qty, 
           SUM(ISNULL(insp_qty,0)) as insp_qty, 
           SUM(ISNULL(trans_in_qty,0)) as trans_in_qty, 
           SUM(ISNULL(trans_out_qty,0)) as trans_out_qty, 
           SUM(ISNULL(keeping_qty,0)) as keeping_qty, 
           SUM(ISNULL(self_consume_qty,0)) as self_consume_qty, 
           SUM(ISNULL(net_sale_qty,0)) as net_sale_qty, 
           '' as descr, 
           2 as sort, 
           0 AS Status , 
          @IsCfm AS IsCfm
      FROM #SS1 
     GROUP BY div_code, yyyymmdd, item_code, item_name
    
    -- 합계 
    INSERT INTO #SS1 
    SELECT div_code, 
           99999999 as yyyymmdd, 
           '', 
           '', 
           '합계' as tank_no, 
           '' as nozzle_no, 
           SUM(ISNULL(before_meter,0)) as before_meter, 
           SUM(ISNULL(current_meter,0)) as current_meter, 
           SUM(ISNULL(flow_qty,0)) as flow_qty, 
           SUM(ISNULL(extra_out_qty,0)) as extra_out_qty, 
           SUM(ISNULL(insp_qty,0)) as insp_qty, 
           SUM(ISNULL(trans_in_qty,0)) as trans_in_qty, 
           SUM(ISNULL(trans_out_qty,0)) as trans_out_qty, 
           SUM(ISNULL(keeping_qty,0)) as keeping_qty, 
           SUM(ISNULL(self_consume_qty,0)) as self_consume_qty, 
           SUM(ISNULL(net_sale_qty,0)) as net_sale_qty, 
           '' as descr, 
           3 as sort, 
           0 AS Status , 
          @IsCfm AS IsCfm
      FROM #SS1 
     WHERE sort = 1 
     GROUP BY div_code, yyyymmdd


    SELECT * FROM #SS1 Order BY div_code, yyyymmdd, item_code, item_name, sort 

    
    ---------------------------------------------------------------------------------------------------
    -- 수불현황
    ---------------------------------------------------------------------------------------------------
   SELECT a.div_code,
          a.yyyymmdd,
          a.item_code, 
          C.ItemName AS item_name,
          a.tank_no,
          a.basis_qty,
          a.basis_month_diff_qty,
          a.in_qty,sale_qty,
          a.extra_in_qty,
          a.extra_out_qty,
          a.onhand_qty,
          a.pos_real_qty,
          a.real_qty,
          a.day_diff_qty,
          a.month_diff_qty,
          a.descr, 
          1 as sort 
     INTO #SS2 
     FROM pos710t a LEFT OUTER JOIN
          ( SELECT pos_code, erp_code, sort_seq
              FROM fgs310t 
             WHERE div_code = @p_div_code
               AND code_type = 'POS004'
            ) b ON a.item_code = b.erp_code
     LEFT OUTER JOIN #TDAItem AS C ON ( C.POSItemSeq = A.item_code ) 
    WHERE a.div_code = @p_div_code
      AND a.yyyymmdd = @StdDate 
    ORDER BY ISNULL(b.sort_seq,9999), a.item_code, a.tank_no
    
    
    -- 소계 
    INSERT INTO #SS2 
    SELECT div_code, 
           yyyymmdd, 
           item_code, 
           item_name, 
           '소계' as tank_no, 
           SUM(ISNULL(basis_qty,0)) AS basis_qty, 
           SUM(ISNULL(basis_month_diff_qty,0)) AS basis_month_diff_qty,
           SUM(ISNULL(in_qty,0)) AS in_qty,
           SUM(ISNULL(sale_qty,0)) AS sale_qty,
           SUM(ISNULL(extra_in_qty,0)) AS extra_in_qty,
           SUM(ISNULL(extra_out_qty,0)) AS extra_out_qty,
           SUM(ISNULL(onhand_qty,0)) AS onhand_qty,
           SUM(ISNULL(pos_real_qty,0)) AS pos_real_qty,
           SUM(ISNULL(real_qty,0)) AS real_qty, 
           SUM(ISNULL(day_diff_qty,0)) AS day_diff_qty,
           SUM(ISNULL(month_diff_qty,0)) AS month_diff_qty, 
           '' as descr, 
           2 as sort 
      FROM #SS2 
     GROUP BY div_code, yyyymmdd, item_code, item_name 
    
    -- 합계 
    INSERT INTO #SS2 
    SELECT div_code, 
           99999999, 
           '' as item_code, 
           '' as item_name, 
           '합계' as tank_no, 
           SUM(ISNULL(basis_qty,0)) AS basis_qty, 
           SUM(ISNULL(basis_month_diff_qty,0)) AS basis_month_diff_qty,
           SUM(ISNULL(in_qty,0)) AS in_qty,
           SUM(ISNULL(sale_qty,0)) AS sale_qty,
           SUM(ISNULL(extra_in_qty,0)) AS extra_in_qty,
           SUM(ISNULL(extra_out_qty,0)) AS extra_out_qty,
           SUM(ISNULL(onhand_qty,0)) AS onhand_qty,
           SUM(ISNULL(pos_real_qty,0)) AS pos_real_qty,
           SUM(ISNULL(real_qty,0)) AS real_qty, 
           SUM(ISNULL(day_diff_qty,0)) AS day_diff_qty,
           SUM(ISNULL(month_diff_qty,0)) AS month_diff_qty, 
           '' as descr, 
           3 as sort 
      FROM #SS2 
     WHERE sort = 1 
     GROUP BY div_code, yyyymmdd
    
    SELECT * FROM #SS2 ORDER BY div_code, yyyymmdd, item_code, item_name, sort 

    ---------------------------------------------------------------------------------------------------
    -- 판매현황 
    ---------------------------------------------------------------------------------------------------
    

   -- -- 결제수단 리스트
   --SELECT pay_code AS sub_code, pay_name AS code_name
   --  FROM pos350t
   -- WHERE category = 'PRODUCT'
   -- ORDER BY sort_seq

    
   SELECT @p_div_code AS div_code,
          @StdDate AS yyyymmdd,
          x.item_code,
          v.sale_total_qty,
          v.total_amt,
          x.pay_code,
          x.sale_price,
          x.sale_qty,
          x.sale_amt,
          x.descr,
          ISNULL(z.descr, CASE WHEN y.std_price = x.sale_price THEN '' ELSE RTRIM(CAST(y.std_price - x.sale_price AS INT)) END) AS descr2
     INTO #SalesList
     FROM 
         (
         SELECT item_code,
                sale_price,
                SUM(sale_qty) AS sale_total_qty,
                SUM(total_amt) AS total_amt
           FROM pos720t a
          WHERE div_code = @p_div_code
            AND yyyymmdd = @StdDate 
          GROUP BY item_code, sale_price 
          ) v INNER JOIN
         (
         SELECT a.item_code,
                a.pay_code,
                a.sale_price,
                a.sale_qty,
                a.total_amt AS sale_amt,
                a.descr,
                b.sort_seq AS ref_code1
           FROM pos720t a, pos350t b
          WHERE a.pay_code = b.pay_code
            AND b.category = 'PRODUCT'
            AND a.div_code = @p_div_code
            AND a.yyyymmdd = @StdDate 
          ) x ON v.item_code    = x.item_code
             AND v.sale_price   = x.sale_price 
         INNER JOIN
         (
         SELECT a.item_code,
                MAX(sale_price) AS std_price
           FROM pos720t a, pos350t b
          WHERE a.pay_code = b.pay_code
            AND b.category = 'PRODUCT'
            AND a.div_code = @p_div_code
            AND a.yyyymmdd = @StdDate 
          GROUP BY a.item_code
          ) y ON x.item_code = y.item_code
          LEFT OUTER JOIN
          (
            SELECT *
              FROM pos725t
             WHERE div_code = @p_div_code
               AND yyyymmdd = @StdDate 
          ) z ON x.item_code  = z.item_code
             AND x.sale_price = z.sale_price
          LEFT OUTER JOIN
          ( SELECT pos_code, erp_code, sort_seq
              FROM fgs310t 
             WHERE div_code = @p_div_code
               AND code_type = 'POS004'
            ) w ON x.item_code = w.erp_code
    ORDER BY ISNULL(w.sort_seq,0), x.item_code, x.ref_code1, x.sale_price DESC
    
    --select distinct div_code, yyyymmdd, item_code, sale_price
    --  from #SalesList 
    -- where div_code = 801 

    --select * from #SalesList 

    
    SELECT div_code, yyyymmdd, item_code, sale_price, descr2, 
           MAX(sale_total_qty) as sale_total_qty, 
           MAX(total_amt) as total_amt,
           descr AS descr3
      INTO #Main
      FROM #SalesList
     GROUP by div_code, yyyymmdd, item_code, sale_price, descr2, descr 
     
    -- 현금 
    SELECT div_code, yyyymmdd, item_code, sale_price, descr2, 
           SUM(sale_amt) as CASH_sale_amt
      INTO #CASH
      FROM #SalesList
     WHERE pay_code = 'CASH'
     GROUP by div_code, yyyymmdd, item_code, sale_price, descr2

    -- 신용카드
    SELECT div_code, yyyymmdd, item_code, sale_price, descr2, 
           SUM(sale_amt) as CARD_sale_amt 
      INTO #CARD
      FROM #SalesList
     WHERE pay_code = 'CARD'
     GROUP by div_code, yyyymmdd, item_code, sale_price, descr2

    -- 외상
    SELECT div_code, yyyymmdd, item_code, sale_price, descr2, 
           SUM(sale_amt) as AR_sale_amt 
      INTO #AR
      FROM #SalesList
     WHERE pay_code = 'AR'
     GROUP by div_code, yyyymmdd, item_code, sale_price, descr2

    -- 상품권
    SELECT div_code, yyyymmdd, item_code, sale_price, descr2, 
           SUM(sale_amt) as GIFT_sale_amt 
      INTO #GIFT
      FROM #SalesList
     WHERE pay_code = 'GIFT'
     GROUP by div_code, yyyymmdd, item_code, sale_price, descr2

    -- OK Cashbag
    SELECT div_code, yyyymmdd, item_code, sale_price, descr2, 
           SUM(sale_amt) as OKCASH_sale_amt 
      INTO #OKCASH
      FROM #SalesList
     WHERE pay_code = 'OKCASH'
     GROUP by div_code, yyyymmdd, item_code, sale_price, descr2

    -- 주유할인권
    SELECT div_code, yyyymmdd, item_code, sale_price, descr2, 
           SUM(sale_amt) as COUPON_sale_amt 
      INTO #COUPON
      FROM #SalesList
     WHERE pay_code = 'COUPON'
     GROUP by div_code, yyyymmdd, item_code, sale_price, descr2

    -- 모바일
    SELECT div_code, yyyymmdd, item_code, sale_price, descr2, 
           SUM(sale_amt) as M_COUPON_sale_amt 
      INTO #M_COUPON
      FROM #SalesList
     WHERE pay_code = 'M_COUPON'
     GROUP by div_code, yyyymmdd, item_code, sale_price, descr2

    -- 고객적립금
    SELECT div_code, yyyymmdd, item_code, sale_price, descr2, 
           SUM(sale_amt) as POINT_sale_amt 
      INTO #POINT
      FROM #SalesList
     WHERE pay_code = 'POINT'
     GROUP by div_code, yyyymmdd, item_code, sale_price, descr2

    -- 블루포인트
    SELECT div_code, yyyymmdd, item_code, sale_price, descr2, 
           SUM(sale_amt) as BLUE_POINT_sale_amt 
      INTO #BLUE_POINT
      FROM #SalesList
     WHERE pay_code = 'BLUE_POINT'
     GROUP by div_code, yyyymmdd, item_code, sale_price, descr2
    
    SELECT A.div_code, 
           A.yyyymmdd, 
           A.item_code, 
           K.ItemName as item_name, 
           A.sale_price, 
           A.descr2, 
           A.sale_total_qty, 
           A.total_amt, 
           B.CASH_sale_amt, 
           C.CARD_sale_amt, 
           D.AR_sale_amt, 
           E.GIFT_sale_amt, 
           F.OKCASH_sale_amt, 
           G.COUPON_sale_amt, 
           H.M_COUPON_sale_amt, 
           I.POINT_sale_amt, 
           J.BLUE_POINT_sale_amt, 
           A.descr3,
           1 as sort 
      INTO #SS3  
      FROM #Main                    AS A 
      LEFT OUTER JOIN #TDAItem      AS K ON ( K.POSItemSeq = A.item_code ) 
      LEFT OUTER JOIN #CASH         AS B ON ( B.div_code = A.div_code 
                                          AND B.yyyymmdd = A.yyyymmdd
                                          AND B.item_code = A.item_code 
                                          AND B.sale_price = A.sale_price
                                          AND B.descr2 = A.descr2
                                            )
      LEFT OUTER JOIN #CARD         AS C ON ( C.div_code = A.div_code 
                                          AND C.yyyymmdd = A.yyyymmdd
                                          AND C.item_code = A.item_code 
                                          AND C.sale_price = A.sale_price
                                          AND C.descr2 = A.descr2
                                            )
      LEFT OUTER JOIN #AR           AS D ON ( D.div_code = A.div_code 
                                          AND D.yyyymmdd = A.yyyymmdd
                                          AND D.item_code = A.item_code 
                                          AND D.sale_price = A.sale_price
                                          AND D.descr2 = A.descr2
                                            )
      LEFT OUTER JOIN #GIFT         AS E ON ( E.div_code = A.div_code 
                                          AND E.yyyymmdd = A.yyyymmdd
                                          AND E.item_code = A.item_code 
                                          AND E.sale_price = A.sale_price
                                          AND E.descr2 = A.descr2
                                            )
      LEFT OUTER JOIN #OKCASH       AS F ON ( F.div_code = A.div_code 
                                          AND F.yyyymmdd = A.yyyymmdd
                                          AND F.item_code = A.item_code 
                                          AND F.sale_price = A.sale_price
                                          AND F.descr2 = A.descr2
                                            )
      LEFT OUTER JOIN #COUPON       AS G ON ( G.div_code = A.div_code 
                                          AND G.yyyymmdd = A.yyyymmdd
                                          AND G.item_code = A.item_code 
                                          AND G.sale_price = A.sale_price
                                          AND G.descr2 = A.descr2
                                            )
      LEFT OUTER JOIN #M_COUPON     AS H ON ( H.div_code = A.div_code 
                                          AND H.yyyymmdd = A.yyyymmdd
                                          AND H.item_code = A.item_code 
                                          AND H.sale_price = A.sale_price
                                          AND H.descr2 = A.descr2
                                            )
      LEFT OUTER JOIN #POINT        AS I ON ( I.div_code = A.div_code 
                                          AND I.yyyymmdd = A.yyyymmdd
                                          AND I.item_code = A.item_code 
                                          AND I.sale_price = A.sale_price
                                          AND I.descr2 = A.descr2
                                            )
      LEFT OUTER JOIN #BLUE_POINT   AS J ON ( J.div_code = A.div_code 
                                          AND J.yyyymmdd = A.yyyymmdd
                                          AND J.item_code = A.item_code 
                                          AND J.sale_price = A.sale_price
                                          AND J.descr2 = A.descr2
                                            )

    -- 소계 
    INSERT INTO #SS3 
    SELECT div_code, 
           yyyymmdd, 
           item_code, 
           '소계' AS Item_name, 
           0 AS sale_price, 
           '' AS descr2, 
           SUM(ISNULL(sale_total_qty, 0)) AS sale_total_qty, 
           SUM(ISNULL(total_amt, 0)) AS total_amt, 
           SUM(ISNULL(CASH_sale_amt, 0)) AS CASH_sale_amt, 
           SUM(ISNULL(CARD_sale_amt, 0)) AS CARD_sale_amt, 
           SUM(ISNULL(AR_sale_amt, 0)) AS AR_sale_amt, 
           SUM(ISNULL(GIFT_sale_amt, 0)) AS GIFT_sale_amt, 
           SUM(ISNULL(OKCASH_sale_amt, 0)) AS OKCASH_sale_amt, 
           SUM(ISNULL(COUPON_sale_amt, 0)) AS COUPON_sale_amt, 
           SUM(ISNULL(M_COUPON_sale_amt, 0)) AS M_COUPON_sale_amt, 
           SUM(ISNULL(POINT_sale_amt, 0)) AS POINT_sale_amt, 
           SUM(ISNULL(BLUE_POINT_sale_amt,0)) AS BLUE_POINT_sale_amt, 
           '',
           2 as sort 
      FROM #SS3
     GROUP BY div_code, yyyymmdd, item_code 

    -- 합계 
    INSERT INTO #SS3 
    SELECT div_code, 
           99999999 as yyyymmdd, 
           '' as item_code, 
           '합계' AS item_name, 
           0 AS sale_price, 
           '' AS descr2, 
           SUM(ISNULL(sale_total_qty, 0)) AS sale_total_qty, 
           SUM(ISNULL(total_amt, 0)) AS total_amt, 
           SUM(ISNULL(CASH_sale_amt, 0)) AS CASH_sale_amt, 
           SUM(ISNULL(CARD_sale_amt, 0)) AS CARD_sale_amt, 
           SUM(ISNULL(AR_sale_amt, 0)) AS AR_sale_amt, 
           SUM(ISNULL(GIFT_sale_amt, 0)) AS GIFT_sale_amt, 
           SUM(ISNULL(OKCASH_sale_amt, 0)) AS OKCASH_sale_amt, 
           SUM(ISNULL(COUPON_sale_amt, 0)) AS COUPON_sale_amt, 
           SUM(ISNULL(M_COUPON_sale_amt, 0)) AS M_COUPON_sale_amt, 
           SUM(ISNULL(POINT_sale_amt, 0)) AS POINT_sale_amt, 
           SUM(ISNULL(BLUE_POINT_sale_amt,0)) AS BLUE_POINT_sale_amt, 
           '',
           3 as sort 
      FROM #SS3
     WHERE sort = 1 
     GROUP BY div_code, yyyymmdd
    
    SELECT * FROM #SS3 ORDER BY div_code, yyyymmdd, item_code, sort 
    

    ---------------------------------------------------------------------------------------------------
    -- 수금현황 
    ---------------------------------------------------------------------------------------------------

    CREATE TABLE #SS4 
    (
        div_code        nvarchar(10), 
        yyyymmdd        nchar(8), 
        pay_code        nvarchar(10), 
        pos_custom_code nvarchar(10), 
        basis_amt       decimal(19,5), 
        sale_amt_pos    decimal(19,5),
        sale_amt        decimal(19,5), 
        in_amt          decimal(19,5), 
        charge_amt      decimal(19,5), 
        in_amt2         decimal(19,5), 
        balance_amt     decimal(19,5), 
        descr           nvarchar(200), 
        sort            int 
    ) 

     -- 청명 IC 주유소의 경우 세차비 / 고객적립금 / 상품권 / 마트상품 제외 2012.11.14 --> 해당내용은 기존 B2B에서 추가 된 내용
	 IF (@p_div_code = '907' AND @StdDate >= '20121101')
		 BEGIN
           insert into #SS4 
		   SELECT x.div_code,
				  x.yyyymmdd,
				  x.pay_code,
				  x.pos_custom_code,
				  x.basis_amt,
				  x.sale_amt_pos,
				  x.sale_amt,
				  x.in_amt,
				  x.charge_amt,
				  x.in_amt2,
				  x.balance_amt,
				  x.descr, 
                  1 as sort 
			 FROM 
				 (
				 SELECT a.div_code,
						a.yyyymmdd,
						a.pay_code,
						a.pos_custom_code,
						a.basis_amt,
						a.sale_amt_pos,
						a.sale_amt,
						a.in_amt,
						a.charge_amt,
						a.in_amt2,
						a.balance_amt,
						a.descr,
						b.sort_seq AS sort_seq1
				   FROM pos730t a, pos350t b
				  WHERE a.pay_code = b.pay_code
					AND a.div_code = @p_div_code
					AND a.yyyymmdd = @StdDate 
					AND b.pay_code NOT IN ('WASH','POINT','E_PRODUCT','GIFT')
				  ) x LEFT OUTER JOIN pos360t y ON x.div_code = y.div_code
											   AND x.pay_code = y.pay_code
											   AND x.pos_custom_code = y.pos_code
			ORDER BY x.sort_seq1, ISNULL(y.sort_seq,0)

		END
	
	ELSE
	
		BEGIN
           insert into #SS4  
		   SELECT x.div_code,
				  x.yyyymmdd,
				  x.pay_code,
				  x.pos_custom_code,
				  x.basis_amt,
				  x.sale_amt_pos,
				  x.sale_amt,
				  x.in_amt,
				  x.charge_amt,
				  x.in_amt2,
				  x.balance_amt,
				  x.descr, 
                  1 as sort 
			 FROM 
				 (
				 SELECT a.div_code,
						a.yyyymmdd,
						a.pay_code,
						a.pos_custom_code,
						a.basis_amt,
						a.sale_amt_pos,
						a.sale_amt,
						a.in_amt,
						a.charge_amt,
						a.in_amt2,
						a.balance_amt,
						a.descr,
						b.sort_seq AS sort_seq1
				   FROM pos730t a, pos350t b
				  WHERE a.pay_code = b.pay_code
					AND a.div_code = @p_div_code
					AND a.yyyymmdd = @StdDate 
				  ) x LEFT OUTER JOIN pos360t y ON x.div_code = y.div_code
											   AND x.pay_code = y.pay_code
											   AND x.pos_custom_code = y.pos_code
			ORDER BY x.sort_seq1, ISNULL(y.sort_seq,0)
		END
    
    -- CARD 소계 
    INSERT INTO #SS4 
    select div_code, 
           yyyymmdd, 
           pay_code + ' 소계', 
           '' as pos_custom_code, 
           SUM(ISNULL(basis_amt     ,0)) as basis_amt   ,
           SUM(ISNULL(sale_amt_pos  ,0)) as sale_amt_pos,
           SUM(ISNULL(sale_amt      ,0)) as sale_amt    ,
           SUM(ISNULL(in_amt        ,0)) as in_amt      ,
           SUM(ISNULL(charge_amt    ,0)) as charge_amt  ,
           SUM(ISNULL(in_amt2       ,0)) as in_amt2     ,
           SUM(ISNULL(balance_amt   ,0)) as balance_amt , 
           '' as descr, 
           2 as sort 
      from #SS4 
     where pay_code = 'CARD'
     GROUP BY div_code, yyyymmdd, pay_code 


    -- 합계 
    INSERT INTO #SS4 
    select div_code, 
           99999999 as yyyymmdd, 
           '합계', 
           '' as pos_custom_code, 
           SUM(ISNULL(basis_amt     ,0)) as basis_amt   ,
           SUM(ISNULL(sale_amt_pos  ,0)) as sale_amt_pos,
           SUM(ISNULL(sale_amt      ,0)) as sale_amt    ,
           SUM(ISNULL(in_amt        ,0)) as in_amt      ,
           SUM(ISNULL(charge_amt    ,0)) as charge_amt  ,
           SUM(ISNULL(in_amt2       ,0)) as in_amt2     ,
           SUM(ISNULL(balance_amt   ,0)) as balance_amt , 
           '' as descr, 
           3 as sort 
      from #SS4 
     where pay_code <> 'CARD'
     GROUP BY div_code 

    SELECT * FROM #SS4 ORDER BY div_code, yyyymmdd, pay_code, sort 
    --return 
    
    ---------------------------------------------------------------------------------------------------
    -- 기타현황 
    ---------------------------------------------------------------------------------------------------

    -- 세차현황
	SELECT a.div_code, 
		    a.yyyymmdd, 
		    ISNULL(b.current_meter,0) AS before_meter, 
		    a.current_meter, 
		    a.flow_cnt, 
		    a.charge_cnt, 
		    a.nocharge_cnt, 
		    a.test_cnt,
		    a.sale_cnt
	FROM pos750t a LEFT OUTER JOIN 
      (
	      SELECT b.div_code, 
		      b.yyyymmdd, 
		      b.before_meter, 
		      b.current_meter, 
		      b.flow_cnt, 
		      b.charge_cnt, 
		      b.nocharge_cnt, 
		      b.test_cnt,
		      b.sale_cnt
	      FROM pos750t b 
	      WHERE b.div_code  = @p_div_code
	        AND b.yyyymmdd = CONVERT(VARCHAR(8), DATEADD(dd, -1, @StdDate), 112)
      ) b ON a.div_code = b.div_code
	WHERE a.div_code  = @p_div_code
	  AND a.yyyymmdd = @StdDate

    -- 주유할인권불출 및 회수내역 
    SELECT a.div_code, 
		a.yyyymmdd, 
		ISNULL(b.today_amt, 0) AS basis_amt,
		a.today_incoupon, 
		a.refueling_amt, 
		a.loan_amt, 
		a.industry_amt, 
		a.total_amt, 
		a.today_amt 
	FROM pos740t a LEFT OUTER JOIN
        (
		    SELECT a.div_code, 
			    a.yyyymmdd, 
			    a.basis_amt, 
			    a.today_incoupon, 
			    a.refueling_amt, 
			    a.loan_amt, 
			    a.industry_amt, 
			    a.total_amt, 
			    a.today_amt, 
			    a.basis_bal, 
			    a.issue_coupon, 
			    a.destruc_coupon, 
			    a.today_bal
		    FROM pos740t a
		    WHERE a.div_code  = @p_div_code
		    AND a.yyyymmdd  = CONVERT(VARCHAR(8), DATEADD(dd, -1, @StdDate), 112)
        ) b ON a.div_code  = b.div_code
	WHERE a.div_code  = @p_div_code
		AND a.yyyymmdd = @StdDate
    
    -- 주유할인권 관리내역 
    SELECT a.div_code, 
		a.yyyymmdd, 
		ISNULL(b.today_bal, 0) AS basis_bal, 
        0 AS today_coupon, 
		a.issue_coupon, 
		a.destruc_coupon, 
		a.today_bal
	FROM pos740t a LEFT OUTER JOIN
        (
		    SELECT a.div_code, 
			    a.yyyymmdd, 
			    a.basis_amt, 
			    a.today_incoupon, 
			    a.refueling_amt, 
			    a.loan_amt, 
			    a.industry_amt, 
			    a.total_amt, 
			    a.today_amt, 
			    a.basis_bal, 
			    a.issue_coupon, 
			    a.destruc_coupon, 
			    a.today_bal
		    FROM pos740t a
		    WHERE a.div_code  = @p_div_code
		    AND a.yyyymmdd  = CONVERT(VARCHAR(8), DATEADD(dd, -1, @StdDate), 112)
        ) b ON a.div_code  = b.div_code
	WHERE a.div_code  = @p_div_code
		AND a.yyyymmdd = @StdDate



    
    
    ---------------------------------------------------------------------------------------------------
    -- 외상매출현황 
    ---------------------------------------------------------------------------------------------------
	SELECT x.div_code,
 			@StdDate AS yyyymmdd,
			x.pos_custom_code as cs_code,
			z.cs_name,
			CASE WHEN x.yyyymmdd = @StdDate THEN y.basis_amt ELSE y.balance_amt END AS basis_amt,
			CASE WHEN x.yyyymmdd = @StdDate THEN y.in_amt ELSE 0 END AS in_amt,
			CASE WHEN x.yyyymmdd = @StdDate THEN y.ar_amt ELSE 0 END AS ar_amt,
			y.balance_amt, 
            1 as sort 
    INTO #SS7 
    FROM 
        (
        SELECT div_code, pos_custom_code, MAX(yyyymmdd) AS yyyymmdd
            FROM POS735T
            WHERE div_code = @p_div_code
            AND yyyymmdd BETWEEN LEFT(@StdDate,2) AND @StdDate  --LEFT(@StdDate,6) 을 2로 변경 20101125
            GROUP BY div_code, pos_custom_code
        ) x INNER JOIN POS735T y ON x.div_code = y.div_code
                                AND x.yyyymmdd = y.yyyymmdd 
                                AND x.pos_custom_code = y.pos_custom_code
		    LEFT OUTER JOIN
        (
		    SELECT div_code, cs_code, cs_name
		        FROM jwpBBCsMaster
		    WHERE div_code = @p_div_code
		    UNION
		    SELECT div_code, cus_code as cs_code, cus_name1 as cs_name
		        FROM skpCsMaster
		    WHERE div_code = @p_div_code
	        ) z ON x.div_code = z.div_code 
            AND x.pos_custom_code = z.cs_code
	WHERE x.div_code  = @p_div_code


    -- 합계 
    INSERT INTO #SS7 
    SELECT div_code, 
           yyyymmdd, 
           '' as cs_code, 
           '합계' as cs_name, 
           SUM(ISNULL(basis_amt,0)) as basis_amt, 
           SUM(ISNULL(in_amt,0)) as in_amt, 
           SUM(ISNULL(ar_amt,0)) as ar_amt, 
           SUM(ISNULL(balance_amt,0)) as balance_amt, 
           3 as sort 
      FROM #SS7 
     GROUP BY div_code, yyyymmdd
    
    SELECT * FROM #SS7 ORDER BY div_code, yyyymmdd, sort 

    ---------------------------------------------------------------------------------------------------
    -- 대여금 현황
    ---------------------------------------------------------------------------------------------------
    SELECT div_code, 
          yyyymmdd,
          car_code,     -- 코드
          car_no,       -- 차량번호
          driver_name,  -- 운전기사
          basis_amt,    -- 기초금액
          loan_amt,     -- 당일대여금
          receive_amt,  -- 당일상환금
          balance_amt   -- 기말잔액
	  FROM pos760t a
	 WHERE a.div_code  = @p_div_code
	   AND a.yyyymmdd  = @StdDate
    

    -- 계정과목 Mapping 
    SELECT A.ValueSeq AS erp_ACCSeq, C.AccName, B.ValueText AS b2b_ACCSeq 
      INTO #AccSeq 
      FROM _TDAUMinorValue              AS A -- ERP계정과목 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000002 ) -- B2B계정과목코드 
      LEFT OUTER JOIN _TDAAccount       AS C ON ( C.CompanySeq = @CompanySeq AND C.AccSeq = A.ValueSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1013939 
       AND A.Serl = 1000001
    

    IF @SlipKind = '1013901001' -- 판매 
    BEGIN 
        -- 회계처리 대상 
        SELECT a.process_category,
               a.process_code,
               (SELECT case_name FROM AAP110T p WHERE sys_type = 'SD900' AND a.process_code = p.case_code) AS process_name,
               a.accnt AS b2b_accnt,
               B.erp_ACCSeq AS accnt,
               B.AccName as ac_d_name, 
               CASE WHEN a.debit_credit = '1' THEN amount_i ELSE 0 END AS debit_amt_i,
               CASE WHEN a.debit_credit = '2' THEN amount_i ELSE 0 END AS credit_amt_i
          FROM POS910T AS A 
          LEFT OUTER JOIN #AccSeq AS B ON ( B.b2b_ACCSeq = A.accnt ) 
         WHERE a.date_type    = 'DD'
           AND a.process_date = @StdDate
           AND a.div_code     = @p_div_code
           AND a.io_type = 'O'
         ORDER BY a.process_category, a.process_code
    END 
    ELSE
    BEGIN  -- 입금 
        -- 회계처리 대상 
        SELECT a.process_category,
               a.process_code,
               (SELECT case_name FROM AAP110T p WHERE sys_type = 'SD900' AND a.process_code = p.case_code) AS process_name,
               a.accnt AS b2b_accnt,
               B.erp_ACCSeq AS accnt,
               B.AccName as ac_d_name, 
               --b.ac_d_name,
               '' as ac_d_name, 
               CASE WHEN a.debit_credit = '1' THEN amount_i ELSE 0 END AS debit_amt_i,
               CASE WHEN a.debit_credit = '2' THEN amount_i ELSE 0 END AS credit_amt_i
          FROM POS910T AS A 
          LEFT OUTER JOIN #AccSeq AS B ON ( B.b2b_ACCSeq = A.accnt ) 
         WHERE a.date_type    = 'DD'
           AND a.process_date = @StdDate
           AND a.div_code     = @p_div_code
           AND io_type = 'I'
         ORDER BY a.process_category, a.process_code
    END 
    

    RETURN
    go
begin tran 
exec hye_SSLOilDailySalesQuery @xmlDocument=N'<ROOT>
  <DataBlock15>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock15</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <BizUnit>808</BizUnit>
    <StdDate>20161101</StdDate>
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
</ROOT>',@xmlFlags=2,@ServiceSeq=77730106,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=77730008
rollback 