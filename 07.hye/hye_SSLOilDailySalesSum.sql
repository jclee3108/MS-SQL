IF OBJECT_ID('hye_SSLOilDailySalesSum') IS NOT NULL 
    DROP PROC hye_SSLOilDailySalesSum
GO 

-- v2016.10.20

-- �������Ǹ��Ϻ����-POS���������� by����õ 
CREATE PROC hye_SSLOilDailySalesSum
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
            @BizUnitSub INT, 
            @StdDate    NCHAR(8), 
            @POSType    NVARCHAR(10), -- POS ����,    SKPOS:SK POS    JWPOS:���� POS  NOTUSE: POS ����
            @p_div_code NVARCHAR(10), 
            /* ���ν��� ������ ����ϰ��� �ϴ� ������ŭ �����Ѵ�  */
            --@v_pos_type                VARCHAR(10), -- POS ����,    SKPOS:SK POS    JWPOS:���� POS  NOTUSE: POS ����
            @v_tank_no                 VARCHAR(10), -- ��ũno
            @v_item_code               VARCHAR(20), -- ǰ���ڵ�, ����POS�� ��� ǰ���ڵ尡 �߰ߵ��� �ʰ� ����.
            @v_sale_price              NUMERIC(19,5) -- �ǸŴܰ�
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument 
    
    SELECT @BizUnit     = ISNULL( BizUnit, 0 ),
           @StdDate     = ISNULl( StdDate, '')
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock15', @xmlFlags )     
      WITH (
              BizUnit    INT, 
              StdDate    NCHAR(8)
           )  


--BEGIN
--   /* ������ ���� �ʱ�ȭ ó�� */
--   SET @v_error_code = 1;
--   SET @v_error_note = '';

/*
EXEC P_posAggregatePosData
      'KOR',--@p_lang_code  VARCHAR(3) = 'KOR',                 -- LANGUAGE �ʱⰪ : KOR.
      'BATCH',--@p_work_type  VARCHAR(10) = 'N',                  -- �۾� ���� : N, U, D
      '0',--@p_return_no  VARCHAR(1) = '1',                   -- ���� �б� ��ȣ
      '804',--@p_div_code                   VARCHAR(8),         -- �����
      '20090601',--@p_yyyymmdd                   VARCHAR(8),         -- ������
      '',--@p_error_code VARCHAR(30)  OUTPUT,                -- �����ڵ� ����
      ''--@p_error_str  VARCHAR(500) OUTPUT                 -- �����޽��� ����
*/


-----------------------------------------------------------------------------------------------------------------------
-- �۾������� ���(N)�� ���
--IF @p_work_type = 'BATCH'
--BEGIN
-----------------------------------------------------------------------------------------------------------------------
    

      
    SELECT @BizUnitSub = B.ValueSeq 
      FROM _TDAUMinorValue              AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1013753
       AND A.Serl = 1000002 
       AND A.ValueText = @BizUnit 


   SELECT @POSType = CASE WHEN IsOil = '1' THEN 'SKPOS' ELSE 'JWPOS' END 
     FROM hye_TCOMPOSEnv
    WHERE CompanySeq = @CompanySeq 
      AND BizUnit = @BizUnit 
    
    /*
    -- Genuine ERP ����ι��� B2B ERP ����� ����
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

    -- ���� POS�� ���
    IF (@POSType  = 'JWPOS')
    BEGIN
    /*
    jwpDDSale
    jwpDDCredit
    jwpDDCashReceipt
    jwpBBCsMaster
    jwpDDTotal
    */
    
    
        -- ���� POS System�� ��� 1���� tank 1���� ǰ�� �ٷ�ٴ� ����
        SELECT TOP 1 @v_tank_no = tank_no,
                     @v_item_code = item_code
          FROM FGS100T
         WHERE div_code = @p_div_code

    
    -- 1.�����Ȳ
    DELETE A
      FROM pos700t AS A 
     WHERE div_code = @p_div_code
       AND yyyymmdd = @StdDate

    
    INSERT INTO pos700t
    (
        div_code,       yyyymmdd,            item_code,     tank_no,       nozzle_no,
        before_meter,   current_meter,       flow_qty,      extra_out_qty, 
        insp_qty,
        keeping_qty,    self_consume_qty,    
        net_sale_qty,   trans_in_qty, trans_out_qty
    )
    SELECT div_code,       yyyymmdd,            @v_item_code,   '01' AS tank_no,  number AS nozzle_no,
            0 before_meter, 0 ,                  sum(liter),    0,          
            -- �ߺΰ���(div_code = '902')�� �˷����� 128888, �������� 090000, 099999�� �˷��� ������   
            SUM(CASE WHEN @p_div_code = '902' AND code IN('128888') THEN liter   -- �ߺΰ���
                    WHEN @p_div_code != '902' AND code IN('090000','099999') THEN liter  -- �ߺΰ����� �ƴ� ������
                    ELSE 0 END),
            0,            0,                  
            sum(liter) - SUM(CASE WHEN @p_div_code = '902' AND code IN('128888') THEN liter   -- �ߺΰ���
                    WHEN @p_div_code != '902' AND code IN('090000','099999') THEN liter  -- �ߺΰ����� �ƴ� ������
                    ELSE 0 END), 0, 0 
      FROM jwpDDSale
     WHERE div_code = @p_div_code
       AND yyyymmdd = @StdDate
       -- ��Ÿ�Ǹ� ����(��ǰ�� ���� POS���� �Էµǵ��� ����Ǿ� ���� �ϵ��� ��)
       AND number <= 90
     GROUP BY div_code,  yyyymmdd, number
 
 

    -- ���ϰ�ⷮ �� �����ⷮ Update
    UPDATE pos700t
       SET before_meter  = ISNULL(b.current_meter,0),
           current_meter = ISNULL(b.current_meter,0) + a.flow_qty,
           net_sale_qty  = a.flow_qty - a.insp_qty
      FROM pos700t a 
      LEFT OUTER JOIN  ( SELECT div_code, item_code, tank_no, nozzle_no, current_meter
                           FROM pos700t
                           WHERE div_code = @p_div_code
                             AND yyyymmdd = CONVERT(VARCHAR(8), DATEADD(dd,-1,@StdDate),112) 
                       ) b ON a.div_code   = b.div_code
                          AND a.item_code  = b.item_code
                          AND a.tank_no    = b.tank_no
                          AND a.nozzle_no  = b.nozzle_no
     WHERE a.div_code = @p_div_code
       AND a.yyyymmdd = @StdDate 

    
    INSERT INTO pos700t
    (
        div_code,	yyyymmdd,	item_code,	tank_no,
		nozzle_no,	before_meter,	current_meter,
        flow_qty, extra_out_qty, insp_qty,
        keeping_qty,self_consume_qty,net_sale_qty, 
        descr, trans_in_qty, trans_out_qty
    )
	SELECT div_code
	     , @StdDate
		 , item_code
		 , tank_no
		 , nozzle_no
		 , current_meter
		 , current_meter
         , 0,0,0
         , 0,0,0
         , '', 0,0
      FROM pos700t
	 WHERE div_code = @p_div_code --�����
	   and yyyymmdd = ( select max(yyyymmdd) 
		                  from pos700t
					     where div_code = @p_div_code
						   and yyyymmdd < @StdDate
					  )
       and not exists ( select item_code
						  from pos700t x
						 where x.div_code  = @p_div_code
					       and x.yyyymmdd  = @StdDate
						   and x.div_code  = pos700t.div_code
						   and x.item_code = pos700t.item_code
						   and x.tank_no   = pos700t.tank_no
						   and x.nozzle_no = pos700t.nozzle_no
					  )
    
    
      -- 2.��ǰ���� �� �����Ȳ
      -- ������ ������ ���
      SELECT *
        INTO #pos710t_jw
        FROM pos710t
       WHERE div_code = @p_div_code
         AND yyyymmdd = @StdDate


      -- ������ ������ ����
      DELETE FROM pos710t
            WHERE div_code = @p_div_code
              AND yyyymmdd = @StdDate


      INSERT INTO pos710t(div_code,          yyyymmdd,                  item_code,        tank_no,
                          basis_qty,         basis_month_diff_qty,      in_qty,           sale_qty,
                          extra_in_qty,      extra_out_qty,             onhand_qty,       pos_real_qty,      
                          real_qty,          day_diff_qty,              month_diff_qty,   descr)
                   SELECT @p_div_code,       @StdDate,               @v_item_code,     '01' AS tank_no,
                          0 AS basis_qty,    0 AS basis_month_diff_qty, 0 AS in_qty,      CAST(ISNULL(SUM(net_sale_qty),0) * 0.584 AS NUMERIC(19,3)) AS sale_qty,  
                          0 AS extra_in_qty, 0 AS extra_out_qty,        0 AS onhand_qty,  0 AS pos_real_qty,
                          0 AS real_qty,     0 AS day_diff_qty,         0 AS month_diff_qty,   '' AS descr
                     FROM pos700t
                    WHERE div_code = @p_div_code
                      AND yyyymmdd = @StdDate



      -- �԰� �� ������ ����
      -- ������ ������ ����
      UPDATE pos710t
         SET in_qty = b.in_qty,
             real_qty = b.real_qty
        FROM pos710t a, #pos710t_jw b
      WHERE a.div_code  = b.div_code
        AND a.yyyymmdd  = b.yyyymmdd
        AND a.item_code = b.item_code
        AND a.tank_no   = b.tank_no
        ANd a.div_code = @p_div_code
        AND a.yyyymmdd = @StdDate


      -- ���� ���, ������ ���� Update
      UPDATE pos710t
         SET basis_qty            = ISNULL(b.real_qty,0),
             basis_month_diff_qty = CASE WHEN RIGHT(@StdDate,2) = '01' THEN 0 ELSE ISNULL(b.month_diff_qty,0) END,
             onhand_qty           = ISNULL(b.real_qty,0) - a.sale_qty + a.in_qty,
             day_diff_qty         = a.real_qty - (ISNULL(b.real_qty,0) - a.sale_qty + a.in_qty),
             month_diff_qty       = (CASE WHEN RIGHT(@StdDate,2) = '01' THEN 0 ELSE ISNULL(b.month_diff_qty,0) END) 
                                   + a.real_qty - (ISNULL(b.real_qty,0) - a.sale_qty + a.in_qty)
        FROM pos710t a LEFT OUTER JOIN 
             ( SELECT div_code, item_code,  tank_no,  real_qty, month_diff_qty
                 FROM pos710t
                WHERE div_code  = @p_div_code
                  AND yyyymmdd  = CONVERT(VARCHAR(8), DATEADD(dd,-1,@StdDate),112) 
             ) b ON a.div_code  = b.div_code
                AND a.item_code = b.item_code
                AND a.tank_no   = b.tank_no
       WHERE a.div_code = @p_div_code
         AND a.yyyymmdd = @StdDate 
    
     DROP TABLE #pos710t_jw




      -- 3.�Ǹ���Ȳ
      /*
      * �ŷ�����
      CASH   : ����
      CARD   : ī��
      AR     : �ܻ�
      GIFT   : ��ǰ��
      OKCASH : OK Cash  Bag
      COUPON : �������α�
      POINT  : ��������
      */

      SELECT @v_sale_price = MAX(cost)
        FROM jwpDDSale
       WHERE div_code = @p_div_code
         AND yyyymmdd = @StdDate

      -- 0���� ������ �� ����
      IF (ISNULL(@v_sale_price,0) <= 0)
         SET @v_sale_price = 1

      DELETE FROM pos720t
            WHERE div_code = @p_div_code
              AND yyyymmdd = @StdDate


/*
EXEC P_posAggregatePosData
      'KOR',--@p_lang_code  VARCHAR(3) = 'KOR',                 -- LANGUAGE �ʱⰪ : KOR.
      'BATCH',--@p_work_type  VARCHAR(10) = 'N',                  -- �۾� ���� : N, U, D
      '0',--@p_return_no  VARCHAR(1) = '1',                   -- ���� �б� ��ȣ
      '804',--@p_div_code                   VARCHAR(8),         -- �����
      '20090820',--@p_yyyymmdd                   VARCHAR(8),         -- ������
      '',--@p_error_code VARCHAR(30)  OUTPUT,                -- �����ڵ� ����
      ''--@p_error_str  VARCHAR(500) OUTPUT                 -- �����޽��� ����
*/

      -- �ܻ�, �ſ�ī�� �ݾ� ���� ���
      INSERT INTO pos720t(div_code,       yyyymmdd,         item_code,     
                          pay_code,       sale_price,       sale_qty,      
                          sale_amt,       vat_amt,          total_amt,        descr)
                   SELECT @p_div_code,    @StdDate,      @v_item_code,        
                          y.pay_code,     @v_sale_price AS sale_price,       ISNULL(y.sale_qty,0),        
                          0 AS sale_amt,  0 AS vat_amt,     ISNULL(y.total_amt,0),       '' AS descr
                     FROM 
                        (
                        -- �ܻ� �ŷ�ó
                        SELECT 'AR' AS pay_code,  SUM(a.liter) AS sale_qty, SUM(FLOOR(a.amount)) AS total_amt
                          FROM jwpDDSale a, jwpBBCsMaster b
                         WHERE LEFT(a.code,2) = b.cs_code
                           AND a.div_code     = b.div_code
                           AND a.yyyymmdd     = @StdDate
                           AND a.div_code     = @p_div_code
                           AND b.cs_category  = '2'
                        UNION ALL
                        -- �ſ�ī��
                        SELECT 'CARD' AS pay_code, ROUND(SUM(amt)/@v_sale_price,2) AS sale_qty, SUM(amt) AS total_amt
                          FROM 
                             (
                              SELECT SUM(amt) AS amt
                                FROM 
                                    (
                                    SELECT RIGHT('00' + RTRIM(a.credit),3) AS credit, SUM(a.amount) AS amt
                                      FROM jwpDDSale a
                                     WHERE a.div_code   = @p_div_code
                                       AND a.yyyymmdd   = @StdDate
                                       AND LEFT(a.code,2) IN(SELECT cs_code FROM jwpBBCsMaster WHERE div_code = @p_div_code AND cs_category != '2')
                                     GROUP BY a.credit

                                    UNION ALL
                                    SELECT purchase_place_code AS credit, SUM(amount) AS amt
                                      FROM jwpDDCredit
                                     WHERE div_code = @p_div_code
                                       AND yyyymmdd = @StdDate
                                       --AND valid_num = 9999
                                       AND valid_num IN(9998, 9999)
                                       AND purchase_place_code != '999'
                                     GROUP BY purchase_place_code

                                    -- �ܻ� �ŷ�ó ī�� �Ǹź� �߿� ��ҽ�Ų ���� 
                                    -- 2������ �����Ǿ����Ƿ� �ٽ� ������.
                                    UNION ALL            
                                    SELECT a.purchase_place_code AS credit, SUM(a.amount) AS amt
                                      FROM jwpDDCredit a,
                                           (
                                             SELECT credit_num, consent_num
                                               FROM 
                                                  (
                                                   SELECT credit_num, consent_num, sum(amount) AS amt, count(*) AS cnt
                                                     FROM jwpDDCredit a
                                                    WHERE a.div_code = @p_div_code
                                                      AND a.yyyymmdd = @StdDate
                                                    GROUP BY credit_num, consent_num
                                                   ) x 
                                             WHERE x.amt = 0
                                               AND x.cnt = 2
                                            ) b
                                     WHERE a.credit_num  = b.credit_num
                                       AND a.consent_num = b.consent_num
                                       AND a.div_code = @p_div_code
                                       AND a.yyyymmdd = @StdDate
                                       AND a.valid_num < 9999
                                       AND a.purchase_place_code != '999'
                                       AND LEFT(a.code,2) IN(SELECT cs_code FROM jwpBBCsMaster WHERE div_code = @p_div_code AND cs_category = '2')
                                     GROUP BY purchase_place_code
                                  
                                    ) a, pos360t b
                               WHERE a.credit    = b.pos_code
                                 AND b.pay_code = 'CARD'
                                 AND b.div_code = @p_div_code
                             ) x
                        UNION ALL
                        -- OK CashBag
                        SELECT 'OKCASH' AS pay_code, ROUND(SUM(amount)/@v_sale_price,2) AS sale_qty, SUM(amount) AS total_amt
                          FROM jwpDDCredit
                         WHERE div_code = @p_div_code
                           AND yyyymmdd = @StdDate
                           --AND valid_num = 9999
                           AND purchase_place_code = '999'
                           AND purchase_comp_name = 'OK CASHBAG'
						UNION ALL
                        -- POINT
                        SELECT 'POINT' AS pay_code, ROUND(SUM(amount)/@v_sale_price,2) AS sale_qty, SUM(amount) AS total_amt
                          FROM jwpDDCredit
                         WHERE div_code = @p_div_code
                           AND yyyymmdd = @StdDate
                           --AND valid_num = 9999
                           AND purchase_place_code = '999'
                           AND purchase_comp_name = 'POINT'                           
                         ) y
                         
      -- ���� = ��ü - �ܻ� - �ſ�ī�� 
      DECLARE @v_tot_sale_qty numeric(19,5),
              @v_tot_sale_amt numeric(19,5)


      -- ���ⷮ = ��ü�Ǹŷ� - ������
      -- �ߺ� �������� ��� �������� code = '128888'
      IF ( @p_div_code = '902')
      BEGIN
          SELECT @v_tot_sale_qty = SUM(liter),  
                 @v_tot_sale_amt = SUM(FLOOR(amount))
            FROM jwpDDSale
           WHERE div_code = @p_div_code
             AND yyyymmdd = @StdDate
             AND code NOT IN('128888')
             -- ��Ÿ�Ǹ� ����(��ǰ�� ���� POS���� �Էµǵ��� ����Ǿ� ���� �ϵ��� ��)
             AND number <= 90
      END
      -- �ߺ� ������ �̿ܿ��� code IN( '090000','099999')�� ������
      ELSE
      BEGIN
          SELECT @v_tot_sale_qty = SUM(liter),  
                 @v_tot_sale_amt = SUM(FLOOR(amount))
            FROM jwpDDSale
           WHERE div_code = @p_div_code
             AND yyyymmdd = @StdDate
             AND code NOT IN('090000','099999')
             -- ��Ÿ�Ǹ� ����(��ǰ�� ���� POS���� �Էµǵ��� ����Ǿ� ���� �ϵ��� ��)
             AND number <= 90
      END


      INSERT INTO pos720t(div_code,       yyyymmdd,         item_code,     
                          pay_code,       sale_price,       sale_qty,      
                          sale_amt,       vat_amt,          total_amt,        descr)
                   SELECT @p_div_code,    @StdDate,      x.item_code,     
                          'CASH' AS pay_code, @v_sale_price,x.sale_qty - ISNULL(y.sale_qty,0),      
                          0 AS sale_amt,  0 AS vat_amt,     x.total_amt - ISNULL(y.total_amt,0) AS total_amt,  '' descr
                     FROM 
                         (
                           SELECT @v_item_code AS item_code, 
                                  @v_tot_sale_qty AS sale_qty,  
                                  @v_tot_sale_amt AS total_amt
                         ) x LEFT OUTER JOIN 
                         (   
                           SELECT @v_item_code AS item_code,  
                                  SUM(sale_qty) AS sale_qty,   
                                  SUM(total_amt) AS total_amt                        
                             FROM pos720t
                            WHERE div_code = @p_div_code
                              AND yyyymmdd = @StdDate
                         ) Y ON x.item_code = y.item_code

      -- ���ް�, �ΰ��� �и�
      UPDATE pos720t
         SET sale_amt = total_amt - FLOOR(total_amt/11),
             vat_amt  = FLOOR(total_amt/11)
       WHERE div_code = @p_div_code
         AND yyyymmdd = @StdDate


      -- 3.5 �ܻ� �ŷ�ó ����
      DELETE FROM pos728t
            WHERE div_code = @p_div_code
              AND yyyymmdd = @StdDate

      INSERT INTO pos728t (div_code,    yyyymmdd,      pos_custom_code,  
                           item_code,   unit_price,    qty,           
                           sale_amt,    vat_amt,       total_amt)  
                    SELECT x.div_code,  @StdDate,   x.cs_code,
                           @v_item_code AS item_code,  x.unit_price,   x.qty,      
                           0 AS sale_amt,  0 AS  vat_amt,   x.total_amt
                      FROM 
                          ( SELECT a.div_code, SUBSTRING(a.code,1,2) AS cs_code,  
                                   cost AS unit_price,
                                   SUM(liter) AS qty,     
                                   SUM(amount) AS total_amt
                              FROM jwpDDSale a
                             WHERE a.div_code = @p_div_code
                               AND a.yyyymmdd = @StdDate 
                             GROUP BY a.div_code, SUBSTRING(a.code,1,2), a.cost
                           ) x, jwpBBCsMaster y
                     WHERE x.div_code = y.div_code
                       AND x.cs_code  = y.cs_code
                       AND y.cs_category = '2'

      -- VAT ����
      UPDATE pos728t
         SET vat_amt  = FLOOR(total_amt / 11),
             sale_amt = total_amt - FLOOR(total_amt / 11)
       WHERE div_code = @p_div_code
         AND yyyymmdd = @StdDate 
           

                  
      -- 4.������Ȳ
      -- �ش��� ���� ������ ���
      SELECT *
        INTO #pos730t_temp_jw
        FROM pos730t
       WHERE div_code = @p_div_code
         AND yyyymmdd = @StdDate



      -- �ش��� ������ ����
      DELETE FROM pos730t
            WHERE div_code = @p_div_code
              AND yyyymmdd = @StdDate

      
      INSERT INTO pos730t(div_code,       yyyymmdd,      pay_code,      pos_custom_code,
                          basis_amt,      sale_amt_pos,  sale_amt,      in_amt,        charge_amt,       balance_amt, 
                          no_vat_amt,     vat_amt,       in_amt2 
                         )
                   SELECT @p_div_code,    @StdDate,   x.pay_code,    x.pos_custom_code,
                          x.basis_amt,    x.sale_amt,    x.sale_amt,    x.in_amt,      x.charge_amt,     x.balance_amt, 
                          0, 0, 0 
                     FROM
                         (
                         -- ī�� ��ü�� ����
                         SELECT 'CARD' AS pay_code,      credit AS pos_custom_code,
                                0 AS basis_amt, SUM(amt) AS sale_amt, 0 AS in_amt,   0 AS charge_amt, 0 AS balance_amt
                           FROM 
                               (
                                SELECT RIGHT('00' + RTRIM(a.credit),3) AS credit, SUM(a.amount) AS amt
                                  FROM jwpDDSale a
                                 WHERE a.div_code   = @p_div_code
                                   AND a.yyyymmdd   = @StdDate
                                   AND LEFT(a.code,2) IN(SELECT cs_code FROM jwpBBCsMaster WHERE div_code = @p_div_code AND cs_category != '2')
                                 GROUP BY a.credit

                                UNION ALL
                                SELECT purchase_place_code AS credit, SUM(amount) AS amt
                                  FROM jwpDDCredit
                                 WHERE div_code = @p_div_code
                                   AND yyyymmdd = @StdDate
                                   --AND valid_num = 9999
                                   AND valid_num IN(9998, 9999)
                                   AND purchase_place_code != '999'
                                 GROUP BY purchase_place_code

                                 -- �ܻ� �ŷ�ó ī�� �Ǹź� �߿� ��ҽ�Ų ���� 
                                 -- 2������ �����Ǿ����Ƿ� �ٽ� ������.
                                 UNION ALL            
                                 SELECT a.purchase_place_code AS credit, SUM(a.amount) AS amt
                                   FROM jwpDDCredit a,
                                        (
                                          SELECT credit_num, consent_num
                                            FROM 
                                               (
                                                SELECT credit_num, consent_num, sum(amount) AS amt, count(*) AS cnt
                                                  FROM jwpDDCredit a
                                                 WHERE a.div_code = @p_div_code
                                                   AND a.yyyymmdd = @StdDate
                                                 GROUP BY credit_num, consent_num
                                                ) x 
                                          WHERE x.amt = 0
                                            AND x.cnt = 2
                                         ) b
                                  WHERE a.credit_num  = b.credit_num
                                    AND a.consent_num = b.consent_num
                                    AND a.div_code = @p_div_code
                                    AND a.yyyymmdd = @StdDate
                                    AND a.valid_num < 9999
                                    AND a.purchase_place_code != '999'
                                    AND LEFT(a.code,2) IN(SELECT cs_code FROM jwpBBCsMaster WHERE div_code = @p_div_code AND cs_category = '2')
                                  GROUP BY purchase_place_code
                                  
                                ) a, pos360t b
                           WHERE a.credit    = b.pos_code
                             AND b.pay_code = 'CARD'
                             AND b.div_code = @p_div_code
                           GROUP BY credit


                         -- ī�带 ������ �������ܰ�
                         UNION ALL
                         SELECT a.pay_code,      '' AS pos_custom_code,
                                0.0 AS basis_amt,  ISNULL(b.sale_amt,0) AS sale_amt, 0.0 AS in_amt,   0.0 AS charge_amt, 0.0 AS balance_amt
                           FROM pos350t a LEFT OUTER JOIN
                               (
                               SELECT a.pay_code,  SUM(total_amt) AS sale_amt
                                 FROM pos720t a
                                WHERE div_code = @p_div_code
                                  AND yyyymmdd = @StdDate
                                  AND pay_code != 'CARD'
                                GROUP BY pay_code       
                               ) b ON a.pay_code = b.pay_code
                          WHERE a.category = 'PRODUCT'
                            AND a.pay_code != 'CARD'


                        -- ���� ���� ��
                         UNION ALL
                         SELECT a.pay_code,      '' AS pos_custom_code,
                                0.0 AS basis_amt,  0.0 AS sale_amt, 0.0 AS in_amt,   0.0 AS charge_amt, 0.0 AS balance_amt
                           FROM pos350t a 
                          WHERE a.category IN( 'SERVICE','EXTRA')

                         -- �뿩�� ���� ��
                         UNION ALL
                         SELECT 'LOAN' AS pay_code,     '' AS pos_custom_code,
                                0.0 AS basis_amt,  ISNULL(SUM(loan_amt),0) AS sale_amt, ISNULL(SUM(receive_amt),0) AS in_amt,   0.0 AS charge_amt, 0.0 AS balance_amt
                           FROM jwpDDLoan a 
                          WHERE div_code = @p_div_code
                            AND yyyymmdd = @StdDate
                        ) x

      -- Ȥ�� �������ڿ� ���� ���� ī��� ������ �߰�
      INSERT INTO pos730t(div_code,       yyyymmdd,      pay_code,      pos_custom_code,
                          basis_amt,      sale_amt_pos,  sale_amt,      in_amt,        charge_amt,       balance_amt, 
                          no_vat_amt,     vat_amt,       in_amt2 
                         )
                   SELECT @p_div_code,    @StdDate,   x.pay_code,    x.pos_custom_code,
                          x.balance_amt,  0,             0,             0,             0,                x.balance_amt, 
                          0, 0, 0 
                     FROM pos730t x LEFT OUTER JOIN 
                          (       
                            SELECT pos_custom_code
                              FROM pos730t a
                             WHERE a.div_code = @p_div_code
                               AND a.yyyymmdd = @StdDate
                               AND a.pay_code = 'CARD'
                          ) y ON x.pos_custom_code  = y.pos_custom_code
                    WHERE x.div_code  = @p_div_code
                      AND x.yyyymmdd  =  CONVERT(VARCHAR(8), DATEADD(dd,-1,@StdDate),112)
                      AND x.pay_code  = 'CARD'
                      AND y.pos_custom_code  IS NULL         


      --  ���� ������ ����
      UPDATE pos730t
         SET in_amt               = b.in_amt,
             charge_amt           = b.charge_amt,
             in_amt2              = b.in_amt2
        FROM pos730t a, #pos730t_temp_jw b
       WHERE a.div_code = b.div_code
         AND a.yyyymmdd = b.yyyymmdd
         AND a.pay_code = b.pay_code
         AND a.pos_custom_code = b.pos_custom_code
         AND a.div_code = @p_div_code
         AND a.yyyymmdd = @StdDate 

      -- �����ܾ� �� �����ܾ� UPDATE
      UPDATE pos730t
         SET basis_amt            = ISNULL(b.balance_amt,0),
             in_amt               = CASE WHEN a.pay_code = 'CASH' AND a.in_amt = 0 THEN ISNULL(b.balance_amt,0) ELSE a.in_amt END, -- ������ ��� �����̿��ݾ��� �Աݾ�
             no_vat_amt           = a.sale_amt - FLOOR(a.sale_amt * 1/11),
             vat_amt              = FLOOR(a.sale_amt * 1/11),
             balance_amt          = ISNULL(b.balance_amt,0) + a.sale_amt - (CASE WHEN a.pay_code = 'CASH'  AND a.in_amt = 0 THEN ISNULL(b.balance_amt,0) ELSE a.in_amt +a.charge_amt END) - a.in_amt2
        FROM pos730t a LEFT OUTER JOIN 
             ( SELECT div_code,  pay_code,  pos_custom_code, balance_amt
                 FROM pos730t
                WHERE div_code  = @p_div_code
                  AND yyyymmdd  = CONVERT(VARCHAR(8), DATEADD(dd,-1,@StdDate),112) 
             ) b ON a.div_code        = b.div_code
                AND a.pay_code        = b.pay_code
                AND a.pos_custom_code = b.pos_custom_code
       WHERE a.div_code = @p_div_code
         AND a.yyyymmdd = @StdDate 

      DROP TABLE #pos730t_temp_jw



/*
EXEC P_posAggregatePosData
      'KOR',--@p_lang_code  VARCHAR(3) = 'KOR',                 -- LANGUAGE �ʱⰪ : KOR.
      'BATCH',--@p_work_type  VARCHAR(10) = 'N',                  -- �۾� ���� : N, U, D
      '0',--@p_return_no  VARCHAR(1) = '1',                   -- ���� �б� ��ȣ
      '901',--@p_div_code                   VARCHAR(8),         -- �����
      '20090601',--@p_yyyymmdd                   VARCHAR(8),         -- ������
      '',--@p_error_code VARCHAR(30)  OUTPUT,                -- �����ڵ� ����
      ''--@p_error_str  VARCHAR(500) OUTPUT                 -- �����޽��� ����
*/

      -- �ŷ�ó��  �ܻ� ����/���� ����
      -- skpDDAR
      DELETE FROM pos735t
            WHERE div_code   = @p_div_code
              AND yyyymmdd   = @StdDate

      INSERT INTO pos735t(div_code,       yyyymmdd,      pos_custom_code,
                          basis_amt,      in_amt,        ar_amt,           
                          balance_amt)
                   SELECT @p_div_code,    @StdDate,   custom_code,
                          SUM(x.basis_amt) AS basis_amt,  SUM(x.in_amt), SUM(x.ar_amt),  
                          SUM(x.basis_amt) - SUM(x.in_amt) + SUM(x.ar_amt)  AS balance_amt
                     FROM 
                         (

                        -- ���ʱݾ�
                        SELECT a.pos_custom_code AS custom_code,  
                               a.balance_amt AS basis_amt,
                               0 AS in_amt,
                               0 AS ar_amt
                          FROM pos735t a,
                               ( SELECT pos_custom_code, max(yyyymmdd) AS max_yyyymmdd
                                   FROM pos735t a
                                  WHERE a.div_code     = @p_div_code
                                    AND a.yyyymmdd     < @StdDate
                                  GROUP BY pos_custom_code
                               ) b
                         WHERE a.pos_custom_code = b.pos_custom_code
                           AND a.yyyymmdd        = b.max_yyyymmdd
                           AND a.div_code        = @p_div_code

                        UNION ALL
                        -- ���� �ܻ� ���� ����
                        SELECT b.cs_code AS custom_code, 
                               0 AS basis_amt, 
                               0 AS in_amt,
                               SUM(FLOOR(a.amount)) AS ar_amt
                          FROM jwpDDSale a, jwpBBCsMaster b
                         WHERE LEFT(a.code,2) = b.cs_code
                           AND a.div_code     = b.div_code
                           AND a.yyyymmdd     = @StdDate
                           AND a.div_code     = @p_div_code
                           AND b.cs_category  = '2'
                         GROUP BY b.cs_code

                         -- ���� ���� ����
                         UNION ALL
                         SELECT a.custom_code, 
                                0 AS basis_amt,
                                SUM(in_amt) AS in_amt,
                                0 AS ar_amt
                           FROM jwpDDAR a, jwpBBCSMaster b
                          WHERE a.div_code    = b.div_code
                            AND a.custom_code = b.cs_code
                            AND a.div_code    = @p_div_code
                            AND a.yyyymmdd    = @StdDate
                            AND b.cs_category = '2'
                          GROUP BY a.custom_code
                          ) x
                   GROUP BY custom_code
     
      -- ���ݳ����� �ܻ����װ� �ŷ�ó�� �ܻ� ����� �հ� ����(¥���� ����)
      DECLARE @v_temp_cs_code VARCHAR(8)

      SELECT TOP 1 @v_temp_cs_code = pos_custom_code
        FROM pos735t a
       WHERE a.div_code    = @p_div_code
         AND a.yyyymmdd    = @StdDate
       ORDER BY ar_amt DESC

      UPDATE pos735t
         SET ar_amt = a.ar_amt 
                      + ISNULL( (SELECT SUM(sale_amt) FROM pos730t WHERE div_code = @p_div_code AND yyyymmdd = @StdDate AND pay_code = 'AR'),0) 
                      - ISNULL( (SELECT SUM(ar_amt) FROM pos735t WHERE div_code = @p_div_code AND yyyymmdd = @StdDate),0) 
        FROM pos735t a
       WHERE a.div_code        = @p_div_code
         AND a.yyyymmdd        = @StdDate
         AND a.pos_custom_code = @v_temp_cs_code



      -- 5.�������α�
      DELETE FROM pos740t
            WHERE div_code = @p_div_code
              AND yyyymmdd = @StdDate

      INSERT INTO pos740t(div_code,          yyyymmdd,         basis_amt,
                          today_incoupon,    refueling_amt,    loan_amt,
                          industry_amt,      total_amt,        today_amt,         
                          basis_bal,        issue_coupon,      destruc_coupon,    today_bal)
                   SELECT @p_div_code,       @StdDate,      0 AS basis_amt,
                          0 today_incoupon,  0 refueling_amt,  0 loan_amt,
                          0 industry_amt,    0 total_amt,      0 today_amt,
                          0 basis_bal,       0 issue_coupon,   0 destruc_coupon,  0 today_bal

 
      -- ���� �̿� Update
      UPDATE pos740t
         SET basis_amt            = ISNULL(b.today_amt,0),
             --refueling_amt        = ISNULL(c.refueling_amt,0),
             --total_amt            = ISNULL(c.refueling_amt,0),
             today_amt            = ISNULL(b.today_amt,0), 
             basis_bal            = ISNULL(b.today_bal,0),
             today_bal            = ISNULL(b.today_bal,0)
        FROM pos740t a 
             -- ���� �̿�
             LEFT OUTER JOIN 
             ( SELECT div_code, today_amt, today_bal
                 FROM pos740t
                WHERE div_code  = @p_div_code
                  AND yyyymmdd  = CONVERT(VARCHAR(8), DATEADD(dd,-1,@StdDate),112) 
             ) b ON a.div_code  = b.div_code
             -- ���� ȸ�� �� ����, �뿩��
             LEFT OUTER JOIN 
             ( SELECT div_code, 
                      SUM( CASE WHEN pay_code = 'COUPON' THEN sale_amt ELSE 0 END) AS refueling_amt 
                 FROM pos730t
                WHERE div_code  = @p_div_code
                  AND yyyymmdd  = @StdDate
                  AND pay_code  = ''
                GROUP BY div_code
             ) c ON a.div_code  = c.div_code
       WHERE a.div_code = @p_div_code
         AND a.yyyymmdd = @StdDate 



      -- 5.��������
      DELETE FROM pos750t
            WHERE div_code = @p_div_code
              AND yyyymmdd = @StdDate


      INSERT INTO pos750t(div_code,          yyyymmdd,      
                          before_meter,      current_meter,       flow_cnt,
                          charge_cnt,        nocharge_cnt,        test_cnt , sale_cnt)
                   SELECT @p_div_code,       @StdDate,      
                          0 AS before_meter, 0 AS current_meter,  0 AS flow_cnt,
                          0 AS charge_cnt,   0 AS nocharge_cnt,   0 AS test_cnt, 0 AS sale_cnt
 
      UPDATE pos750t
         SET before_meter  = ISNULL(b.current_meter,0)
        FROM pos750t a 
             -- ���� �̿�
             LEFT OUTER JOIN 
             ( SELECT div_code, current_meter
                 FROM pos750t
                WHERE div_code  = @p_div_code
                  AND yyyymmdd  = CONVERT(VARCHAR(8), DATEADD(dd,-1,@StdDate),112) 
             ) b ON a.div_code  = b.div_code
       WHERE a.div_code = @p_div_code
         AND a.yyyymmdd = @StdDate 


      -- �뿩�� ����
      -- skpDDAR
      DELETE FROM pos760t
            WHERE div_code   = @p_div_code
              AND yyyymmdd   = @StdDate



      -- ���� �ſ� 1���� ��쿡�� ���� �����ͷ� �ʱ� �̿����� �����´�.
      IF( RIGHT(@StdDate,2) = '01')
      BEGIN
         INSERT INTO pos760t(div_code,       yyyymmdd,         car_code,            car_no,        driver_name,
                             basis_amt,      loan_amt,         receive_amt,         balance_amt)  
                      SELECT a.div_code,     @StdDate,      a.car_code,          a.car_no,      a.driver_name,
                             a.balance_amt,  0 AS loan_amt,    0 AS receive_amt,    a.balance_amt
                        FROM pos760t a,
                             ( SELECT div_code, car_code, max(yyyymmdd) AS max_yyyymmdd
                                 FROM pos760t
                                WHERE div_code = @p_div_code
                                  AND yyyymmdd < @StdDate
                                GROUP BY div_code, car_code
                              ) b
                       WHERE a.div_code = b.div_code
                         AND a.yyyymmdd = b.max_yyyymmdd
                         AND a.car_code = b.car_code
                         AND a.div_code = @p_div_code
            
         -- �ش���� �ű� ���Ե� ��
         INSERT INTO pos760t(div_code,       yyyymmdd,         car_code,            car_no,        driver_name,
                             basis_amt,      loan_amt,         receive_amt,         balance_amt)  
                      SELECT x.div_code,     @StdDate,      x.car_code,          x.car_no,      x.car_name,
                             0 AS basis_amt, x.loan_amt,       x.receive_amt,       x.loan_amt - x.receive_amt
                       FROM
                           (
                            SELECT div_code,   car_code,            car_no,        car_name,
                                   SUM(loan_amt) AS loan_amt,    SUM(receive_amt) AS receive_amt
                              FROM jwpDDLoan
                             WHERE div_code = @p_div_code
                               AND yyyymmdd = @StdDate
                             GROUP BY div_code, yyyymmdd, car_code, car_no, car_name
                            ) x LEFT OUTER JOIN 
                          ( SELECT div_code, car_code
                              FROM pos760t
                             WHERE div_code = @p_div_code
                               AND yyyymmdd = @StdDate
                           ) y ON x.div_code = y.div_code
                             AND x.car_code  = y.car_code
                       WHERE y.div_code IS NULL
                      


         -- ���� �뿩�� ���� �ݿ�
         UPDATE pos760t
            SET loan_amt    = b.loan_amt,
                receive_amt = b.receive_amt,
                car_no      = b.car_no,
                driver_name    = b.car_name,
                balance_amt  = a.basis_amt + b.loan_amt - b.receive_amt
           FROM pos760t a,
                (
                   SELECT div_code,       yyyymmdd,         car_code,            car_no,        car_name,
                          SUM(loan_amt) AS loan_amt,    SUM(receive_amt) AS receive_amt
                     FROM jwpDDLoan
                    WHERE div_code    = @p_div_code
                      AND yyyymmdd    = @StdDate
                    GROUP BY div_code, yyyymmdd, car_code, car_no, car_name
                 ) b
          WHERE a.div_code = b.div_code
            AND a.yyyymmdd = b.yyyymmdd
            AND a.car_code = b.car_code
            AND a.div_code = @p_div_code
            AND a.yyyymmdd = @StdDate
      END
      -- �ſ� 02~ �ſ� ���� �� ó��
      ELSE
      BEGIN
          -- POS�� ����
          SELECT div_code,       yyyymmdd,         car_code,            car_no,        car_name,
                 0.0 AS basis_amt, SUM(loan_amt) AS loan_amt,    SUM(receive_amt) AS receive_amt
            INTO #LoanData
            FROM jwpDDLoan
           WHERE div_code    = @p_div_code
             AND yyyymmdd    = @StdDate
           GROUP BY div_code, yyyymmdd, car_code, car_no, car_name


         INSERT INTO pos760t(div_code,       yyyymmdd,         car_code,            car_no,        driver_name,
                             basis_amt,      loan_amt,         receive_amt,         balance_amt)  
                      SELECT @p_div_code,    @StdDate,      x.car_code,          y.car_no,      y.car_name,
                             SUM(x.basis_amt) AS basis_amt,  SUM(x.loan_amt), SUM(x.receive_amt),  
                             SUM(x.basis_amt) + SUM(x.loan_amt) - SUM(x.receive_amt)  AS balance_amt
                        FROM 
                          (
                           -- ���ʱݾ�
                           SELECT a.car_code,  
                                  a.balance_amt AS basis_amt,
                                  0.0 AS loan_amt,
                                  0.0 AS receive_amt
                             FROM pos760t a,
                                  ( 
                                    SELECT a.car_code, max(a.yyyymmdd) AS max_yyyymmdd 
                                      FROM pos760t a, #LoanData b
                                     WHERE a.div_code = b.div_code
                                       AND a.car_code = b.car_code
                                       AND a.div_code = @p_div_code
                                       AND a.yyyymmdd < @StdDate
                                     GROUP BY a.car_code
                                  ) b
                            WHERE a.car_code    = b.car_code
                              AND a.yyyymmdd    = b.max_yyyymmdd
                              AND a.div_code    = @p_div_code

                           UNION ALL
                           -- ���� �뿩��
                           SELECT car_code,  
                                  0.0 AS basis_amt, 
                                  loan_amt,    
                                  receive_amt
                             FROM #LoanData
                          ) x, #LoanData y
                    WHERE x.car_code    = y.car_code
                    GROUP BY x.car_code, y.car_no,      y.car_name

           DROP TABLE #LoanData

      END
    END 
    
    

--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------


    -- SK POS�� ���
    IF (@POSType = 'SKPOS')
    BEGIN
   
   

      -- 1.�����Ȳ
      DELETE FROM pos700t
            WHERE div_code = @p_div_code
              AND yyyymmdd = @StdDate

      INSERT INTO pos700t(div_code,       yyyymmdd,            item_code,     tank_no,       nozzle_no,
                          before_meter,   current_meter,       flow_qty,      extra_out_qty, insp_qty,
                          keeping_qty,    self_consume_qty,    net_sale_qty, trans_in_qty , trans_out_qty )
                   SELECT @p_div_code,    @StdDate,         b.item_code,   a.tank_no,     a.pump_no AS nozzle_no,
                          0.0 AS  before_meter,  a.close_cnt AS current_meter,       
                          0.0 AS flow_qty,      
                          0.0 AS extra_out_qty, 0.0 AS inspect_qty,
                          0.0 AS keeping_qty,   0.0 AS self_consume_qty,  0 AS net_sale_qty, 0, 0
                    FROM skpDDPumpFlow a, 
                         (
                          SELECT RIGHT('00000000000000000000' + a.pos_code,18) AS pro_code, erp_code AS item_code
                            FROM fgs310t a
                           WHERE code_type = 'POS004'
                             AND div_code  = @p_div_code
                         ) b
                   WHERE a.pro_code  = b.pro_code
                     AND a.div_code = @p_div_code
                     AND a.yyyymmdd = @StdDate


      -- Ȥ�� �������ڿ� ���� ���� nozzle�� ������ �߰�
      INSERT INTO pos700t(div_code,       yyyymmdd,            item_code,     tank_no,       nozzle_no,
                          before_meter,   current_meter,       flow_qty,      extra_out_qty, insp_qty,
                          keeping_qty,    self_consume_qty,    net_sale_qty, trans_in_qty , trans_out_qty )
                   SELECT @p_div_code,    @StdDate,         a.item_code,   a.tank_no,       a.nozzle_no,
                          a.current_meter,a.current_meter,     0 flow_qty,    0 extra_out_qty, 0 insp_qty,
                          0 keeping_qty,  0 self_consume_qty,  0 net_sale_qty, 0, 0 
                     FROM pos700t a LEFT OUTER JOIN 
                          (       
                            SELECT item_code,     tank_no,       nozzle_no
                              FROM pos700t a
                             WHERE a.div_code = @p_div_code
                               AND a.yyyymmdd = @StdDate
                          ) b ON a.item_code  = a.item_code
                             AND a.tank_no    = b.tank_no
                             AND a.nozzle_no  = b.nozzle_no                            
                    WHERE a.div_code  = @p_div_code
                      AND a.yyyymmdd  =  CONVERT(VARCHAR(8), DATEADD(dd,-1,@StdDate),112)
                      AND b.item_code  IS NULL         

      -- Ȥ�� ���������� ���� ���� nozzle�� ������ �߰�
      INSERT INTO pos700t(div_code,       yyyymmdd,            item_code,     tank_no,       nozzle_no,
                          before_meter,   current_meter,       flow_qty,      extra_out_qty, insp_qty,
                          keeping_qty,    self_consume_qty,    net_sale_qty, trans_in_qty , trans_out_qty )
                   SELECT @p_div_code,    @StdDate,         b.item_code,   a.tank_no,       a.nozzle_no,
                          0 current_meter,0 current_meter,     0 flow_qty,    0 extra_out_qty, 0 insp_qty,
                          0 keeping_qty,  0 self_consume_qty,  0 net_sale_qty, 0, 0 
                     FROM fgs110t a INNER JOIN fgs100t b ON a.div_code = b.div_code AND a.tank_no = b.tank_no
                          LEFT OUTER JOIN 
                          (       
                            SELECT item_code,     tank_no,       nozzle_no
                              FROM pos700t a
                             WHERE a.div_code = @p_div_code
                               AND a.yyyymmdd = @StdDate
                          ) c ON b.item_code  = b.item_code
                             AND a.tank_no    = c.tank_no
                             AND a.nozzle_no  = c.nozzle_no                            
                    WHERE a.div_code  = @p_div_code
                      AND c.item_code  IS NULL         


      -- ���ϰ�ⷮ �� �����ⷮ Update
      UPDATE pos700t
         SET before_meter  = ISNULL(b.current_meter,0),
             flow_qty      = a.current_meter - ISNULL(b.current_meter,0),
             net_sale_qty  = a.current_meter - ISNULL(b.current_meter,0)
        FROM pos700t a LEFT OUTER JOIN 
             ( SELECT div_code, item_code, tank_no, nozzle_no, current_meter
                 FROM pos700t
                WHERE div_code = @p_div_code
                  AND yyyymmdd = CONVERT(VARCHAR(8), DATEADD(dd,-1,@StdDate),112) 
             ) b ON a.div_code   = b.div_code
                AND a.item_code  = b.item_code
                AND a.tank_no    = b.tank_no
                AND a.nozzle_no  = b.nozzle_no
       WHERE a.div_code = @p_div_code
         AND a.yyyymmdd = @StdDate 

         

      -- 2.��ǰ���� �� �����Ȳ
      -- ������ ������ ���
      SELECT *
        INTO #pos710t_sk
        FROM pos710t
       WHERE div_code = @p_div_code
         AND yyyymmdd = @StdDate
      DELETE FROM pos710t
            WHERE div_code = @p_div_code
              AND yyyymmdd = @StdDate

      INSERT INTO pos710t(div_code,          yyyymmdd,                  item_code,        tank_no,
                          basis_qty,         basis_month_diff_qty,      in_qty,           sale_qty,
                          extra_in_qty,      extra_out_qty,             onhand_qty,       pos_real_qty,      
                          real_qty,          day_diff_qty,              month_diff_qty,   descr)
                   SELECT @p_div_code,       @StdDate,               b.item_code,      a.tank_no,
                          0 AS basis_qty,    0 AS basis_month_diff_qty, a.in_qty,         a.sale_qty,  
                          0 AS extra_in_qty, 0 AS extra_out_qty,        0 AS onhand_qty,  a.pos_real_qty,
                          0 AS real_qty,     0 AS day_diff_qty,         0 AS month_diff_qty,   '' AS descr
                     FROM skpDDInout a,
                          (                       
                          SELECT RIGHT('00000000000000000000' + a.pos_code,18) AS pro_code, erp_code AS item_code
                            FROM fgs310t a
                           WHERE code_type = 'POS004'
                             AND div_code  = @p_div_code
                          ) b
                    WHERE a.pro_code = b.pro_code
                      AND a.div_code = @p_div_code
                      AND a.yyyymmdd = @StdDate


      -- Ȥ�� ���������� ���� ���� tank  ������ �߰�
       INSERT INTO pos710t(div_code,          yyyymmdd,                 item_code,        tank_no,
                          basis_qty,         basis_month_diff_qty,      in_qty,           sale_qty,
                          extra_in_qty,      extra_out_qty,             onhand_qty,       pos_real_qty,      
                          real_qty,          day_diff_qty,              month_diff_qty,   descr)
                  SELECT @p_div_code,        @StdDate,               a.item_code,      a.tank_no,  
                          0 basis_qty,       0 basis_month_diff_qty,    0 in_qty,         0 sale_qty, 
                          0 extra_in_qty,    0 extra_out_qty,           0 onhand_qty,     0 pos_real_qty,      
                          0 real_qty,        0 day_diff_qty,            0 month_diff_qty, '' descr
                     FROM fgs100t a 
                          LEFT OUTER JOIN 
                          (       
                            SELECT item_code,     tank_no
                              FROM pos710t a
                             WHERE a.div_code = @p_div_code
                               AND a.yyyymmdd = @StdDate
                          ) c ON a.item_code  = a.item_code
                             AND a.tank_no    = c.tank_no
                    WHERE a.div_code  = @p_div_code
                      AND c.item_code  IS NULL        


      -- �԰� �� ������ ����
      -- ������ ������ ����
      UPDATE pos710t
         SET in_qty = b.in_qty,
             real_qty = b.real_qty
        FROM pos710t a, #pos710t_sk b         
      WHERE a.div_code  = b.div_code
        AND a.yyyymmdd  = b.yyyymmdd
        AND a.item_code = b.item_code
        AND a.tank_no   = b.tank_no
        ANd a.div_code = @p_div_code
        AND a.yyyymmdd = @StdDate


      -- ���ⷮ ����
      UPDATE pos710t
         SET sale_qty             = ISNULL(b.sale_qty,0)
        FROM pos710t a,
             ( SELECT item_code, tank_no,  SUM(net_sale_qty) AS sale_qty
                 FROM pos700t
                WHERE div_code  = @p_div_code
                  AND yyyymmdd  = @StdDate
                GROUP BY item_code, tank_no
             ) b 
       WHERE a.item_code = b.item_code
         AND a.tank_no   = b.tank_no
         AND a.div_code = @p_div_code
         AND a.yyyymmdd = @StdDate 


      -- ���� ���, ������ ���� Update
      UPDATE pos710t
         SET basis_qty            = ISNULL(b.basis_qty,0),
             basis_month_diff_qty = CASE WHEN RIGHT(@StdDate,2) = '01' THEN 0 ELSE ISNULL(b.basis_month_diff_qty,0) END,
             onhand_qty           = ISNULL(b.basis_qty,0) + a.in_qty - a.sale_qty + a.extra_in_qty - a.extra_out_qty,
             real_qty             = CASE WHEN a.real_qty = 0 THEN a.pos_real_qty ELSE a.real_qty END,
             day_diff_qty         = (CASE WHEN a.real_qty = 0 THEN a.pos_real_qty ELSE a.real_qty END) - (ISNULL(b.basis_qty,0) + a.in_qty - a.sale_qty + a.extra_in_qty - a.extra_out_qty),
             month_diff_qty       = (CASE WHEN RIGHT(@StdDate,2) = '01' THEN 0 ELSE ISNULL(b.basis_month_diff_qty,0) END)
                                   + (CASE WHEN a.real_qty = 0 THEN a.pos_real_qty ELSE a.real_qty END) - (ISNULL(b.basis_qty,0) + a.in_qty - a.sale_qty + a.extra_in_qty - a.extra_out_qty)
        FROM pos710t a LEFT OUTER JOIN 
             ( SELECT div_code, item_code,  tank_no,  real_qty AS basis_qty, month_diff_qty AS basis_month_diff_qty
                 FROM pos710t
                WHERE div_code  = @p_div_code
                  AND yyyymmdd  = CONVERT(VARCHAR(8), DATEADD(dd,-1,@StdDate),112) 
             ) b ON a.div_code  = b.div_code
                AND a.item_code = b.item_code
                AND a.tank_no   = b.tank_no
       WHERE a.div_code = @p_div_code
         AND a.yyyymmdd = @StdDate 


     DROP TABLE #pos710t_sk

     
      -- 3.�Ǹ���Ȳ
      /*
      �ŷ�����
      CASH   : ����
      CARD   : ī��
      AR     : �ܻ�
      GIFT   : ��ǰ��
      OKCASH : OK Cash  Bag
      COUPON : �������α�
      */
      DELETE FROM pos720t
            WHERE div_code = @p_div_code
              AND yyyymmdd = @StdDate


/*
EXEC P_posAggregatePosData
      'KOR',--@p_lang_code  VARCHAR(3) = 'KOR',                 -- LANGUAGE �ʱⰪ : KOR.
      'BATCH',--@p_work_type  VARCHAR(10) = 'N',                  -- �۾� ���� : N, U, D
      '0',--@p_return_no  VARCHAR(1) = '1',                   -- ���� �б� ��ȣ
      '801',--@p_div_code                   VARCHAR(8),         -- �����
      '20090806',--@StdDate                   VARCHAR(8),         -- ������
      '',--@p_error_code VARCHAR(30)  OUTPUT,                -- �����ڵ� ����
      ''--@p_error_str  VARCHAR(500) OUTPUT                 -- �����޽��� ����
*/


      -- �ſ�ī�� �Ǹų��� �� ���ī���
      -- �ŷ�ó�ڵ� ������ �ſ�ī�� �Ǹų����� �ϸ��� ������ �ݾ��� �����ǳ��� �������ְ�
      -- �׷��� ���� ���� �ϸ��� ������ �ݾ��� ū �� ������ �ſ�ī�� �ݾ׿� �������ش�.
      SELECT a.div_code,      a.sale_date,      a.pos_no,      a.seq_no,
             a.ok_no,         a.sale_kbn,       a.cus_code,    a.totsale_amt AS tot_card_amt,
             a.mcus_code,     a.mcus_code2,     a.oilsale_qty,
             CAST( '' AS VARCHAR(20)) pro_code, CAST(0.0 AS NUMERIC(19,5)) AS sale_price,
             CAST(0.0 AS NUMERIC(19,5)) AS sale_qty,
             CAST(0.0 AS NUMERIC(19,5)) AS sale_amt,
             CAST(0.0 AS NUMERIC(19,5)) AS vat_amt,
             CAST(0.0 AS NUMERIC(19,5)) AS tot_mapping_amt,
             IDENTITY(int,1,1) AS row_seq,
             -1 AS mapping_row_seq  -- �ſ�ī��� ���εȰ�
        INTO #CardTemp
        FROM skpDDCredit a
       WHERE div_code   = @p_div_code
         AND sale_date  = @StdDate
         AND cus_code   != ''
       ORDER BY a.cus_code, a.totsale_amt  -- �ŷ�ó��/�ĸ�/�ܰ��� �ݾ����� Sorting

      -- ī�� ��Ұǿ� ���ؼ��� ����
      DELETE a 
        FROM #CardTemp a,
            (
            SELECT ok_no, COUNT(*) AS cnt, SUM(tot_card_amt) AS tot_card_amt
              FROM #CardTemp
             GROUP BY ok_no
            HAVING COUNT(*) > 1
            )  b
     WHERE a.ok_no = b.ok_no
       AND b.cnt   = 2
       AND b.tot_card_amt = 0


      -- �ϸ��� ���� �ŷ�ó�ڵ尡 �ִ� �ſ�ī��(���ī�� �����ڰ� �ſ�ī��� ������ ��) ó���ǰ� �ŷ�ó �ڵ尡 
      -- ���� ���� ����
      SELECT a.cus_code, a.pro_code, a.price AS sale_price, 
             a.sales_qty AS sale_qty,
             a.notax_amt AS sale_amt, a.tax_amt AS vat_amt, a.sales_amt AS total_amt,
             'N' AS allotted_yn,
             IDENTITY(int,1,1) AS row_seq 
        INTO #CardTemp2
        FROM skpDDClosing a
       WHERE a.cus_code    IN(SELECT cus_code FROM #CardTemp)
         AND a.div_code    = @p_div_code
         AND a.close_date  = @StdDate
       ORDER BY a.cus_code, a.sales_amt, a.pro_code, a.price  -- �ŷ�ó��/�ĸ�/�ܰ��� �ݾ����� Sorting

      UPDATE #CardTemp2
         SET pro_code = RIGHT(pro_code,4)



/*
EXEC P_posAggregatePosData
      'KOR',--@p_lang_code  VARCHAR(3) = 'KOR',                 -- LANGUAGE �ʱⰪ : KOR.
      'BATCH',--@p_work_type  VARCHAR(10) = 'N',                  -- �۾� ���� : N, U, D
      '0',--@p_return_no  VARCHAR(1) = '1',                   -- ���� �б� ��ȣ
      '804',--@p_div_code                   VARCHAR(8),         -- �����
      '20090820',--@StdDate                   VARCHAR(8),         -- ������
      '',--@p_error_code VARCHAR(30)  OUTPUT,                -- �����ڵ� ����
      ''--@p_error_str  VARCHAR(500) OUTPUT                 -- �����޽��� ����
*/


      -- ���ε��� ���� ���� �� �ſ�ī�� �����ǰ� �ϸ��� ���� �ݾ��� ������ ���� ������ ��������
      WHILE EXISTS(SELECT * 
                     FROM #CardTemp a, #CardTemp2 b
                    WHERE a.cus_code     = b.cus_code
                      AND a.tot_card_amt = b.total_amt  
                      AND a.tot_mapping_amt = 0  -- �̸��ΰ�
                      AND b.allotted_yn = 'N' ) 
      BEGIN

         UPDATE #CardTemp
            SET pro_code         = c.pro_code,
                sale_price       = c.sale_price,
                sale_qty         = c.sale_qty,
                sale_amt         = c.sale_amt,
                vat_amt          = c.vat_amt,
                tot_mapping_amt  = c.total_amt,
                mapping_row_seq  = c.row_seq
           FROM #CardTemp a, 
                ( SELECT cus_code, tot_card_amt, MAX(row_seq) AS max_row_seq
                    FROM #CardTemp
                   WHERE tot_mapping_amt = 0
                   GROUP BY cus_code, tot_card_amt
                ) b,
                #CardTemp2 c,
                ( SELECT cus_code, total_amt, MAX(row_seq) AS max_row_seq
                    FROM #CardTemp2 
                   WHERE allotted_yn = 'N'
                   GROUP BY cus_code, total_amt
                ) d
          WHERE a.row_seq      = b.max_row_seq
            AND a.cus_code     = c.cus_code
            AND a.tot_card_amt = c.total_amt
            AND c.row_seq      = d.max_row_seq

         UPDATE #CardTemp2
            SET allotted_yn = 'Y'
           FROM #CardTemp a, #CardTemp2 b
          WHERE a.cus_code         = b.cus_code
            AND a.tot_card_amt     = b.total_amt
            AND a.mapping_row_seq  = b.row_seq

      END



/*
EXEC P_posAggregatePosData
      'KOR',--@p_lang_code  VARCHAR(3) = 'KOR',                 -- LANGUAGE �ʱⰪ : KOR.
      'BATCH',--@p_work_type  VARCHAR(10) = 'N',                  -- �۾� ���� : N, U, D
      '0',--@p_return_no  VARCHAR(1) = '1',                   -- ���� �б� ��ȣ
      '804',--@p_div_code                   VARCHAR(8),         -- �����
      '20090820',--@StdDate                   VARCHAR(8),         -- ������
      '',--@p_error_code VARCHAR(30)  OUTPUT,                -- �����ڵ� ����
      ''--@p_error_str  VARCHAR(500) OUTPUT                 -- �����޽��� ����
*/


      -- ���� �ܾ� �Ҵ�
      DECLARE @v_loop_cnt   int --  ����  ���� ������

      SET @v_loop_cnt = 1

      WHILE ((@v_loop_cnt < 20) AND EXISTS( SELECT * FROM #CardTemp WHERE tot_card_amt > tot_mapping_amt))
      BEGIN

         UPDATE #CardTemp
            SET pro_code         = CASE WHEN a.pro_code = '' THEN c.pro_code ELSE a.pro_code END,
                sale_price       = CASE WHEN a.sale_price = 0 THEN c.sale_price ELSE a.sale_price END,
                tot_mapping_amt  = CASE WHEN c.total_amt >= (a.tot_card_amt - a.tot_mapping_amt) THEN a.tot_card_amt ELSE a.tot_mapping_amt + c.total_amt END,
                mapping_row_seq  = c.row_seq
           FROM #CardTemp a, 
                ( SELECT cus_code, MAX(row_seq) AS max_row_seq
                    FROM #CardTemp
                   WHERE tot_mapping_amt < tot_card_amt
                   GROUP BY cus_code
                ) b,
                #CardTemp2 c,
                ( SELECT cus_code, MAX(row_seq) AS max_row_seq
                    FROM #CardTemp2 
                   WHERE allotted_yn = 'N'
                   GROUP BY cus_code
                ) d
          WHERE a.row_seq      = b.max_row_seq
            AND a.cus_code     = c.cus_code
            AND a.tot_mapping_amt < tot_card_amt
            AND c.row_seq      = d.max_row_seq

         UPDATE #CardTemp2
            SET allotted_yn = 'Y'
           FROM #CardTemp a, #CardTemp2 b
          WHERE a.cus_code         = b.cus_code
            AND a.mapping_row_seq  = b.row_seq


/* 08.29 ���
         UPDATE #CardTemp
            SET pro_code         = CASE WHEN a.pro_code = '' THEN c.pro_code ELSE a.pro_code END,
                sale_price       = CASE WHEN a.sale_price = 0 THEN c.sale_price ELSE a.sale_price END,
                --sale_qty         = c.sale_qty,
                --sale_amt         = c.sale_amt,
                --vat_amt          = c.vat_amt,
                tot_mapping_amt  = CASE WHEN c.total_amt >= (a.tot_card_amt - a.tot_mapping_amt) THEN a.tot_card_amt ELSE a.tot_mapping_amt + c.total_amt END,
                mapping_row_seq  = c.row_seq
           FROM #CardTemp a, 
                ( SELECT cus_code, tot_card_amt, MAX(row_seq) AS max_row_seq
                    FROM #CardTemp
                   WHERE tot_mapping_amt < tot_card_amt
                   GROUP BY cus_code, tot_card_amt
                ) b,
                #CardTemp2 c,
                ( SELECT cus_code, total_amt, MAX(row_seq) AS max_row_seq
                    FROM #CardTemp2 
                   WHERE allotted_yn = 'N'
                   GROUP BY cus_code, total_amt
                ) d
          WHERE a.row_seq      = b.max_row_seq
            AND a.cus_code     = c.cus_code
            AND a.tot_card_amt = c.total_amt
            AND c.row_seq      = d.max_row_seq

         UPDATE #CardTemp2
            SET allotted_yn = 'Y'
           FROM #CardTemp a, #CardTemp2 b
          WHERE a.cus_code         = b.cus_code
            --AND a.tot_card_amt     = b.total_amt
            AND a.mapping_row_seq  = b.row_seq
*/

         SELECT @v_loop_cnt = @v_loop_cnt + 1

      END



      -- �ܻ�, �ſ�ī�� �ݾ� ���� ���
      INSERT INTO pos720t(div_code,       yyyymmdd,         item_code,     
                          pay_code,       sale_price,       sale_qty,      
                          sale_amt,       vat_amt,          total_amt,        descr)
                   SELECT @p_div_code,    @StdDate,      z.erp_code AS item_code,        
                          pay_code,       sale_price,       ISNULL(y.sale_qty,0),        
                          sale_amt,       vat_amt,          ISNULL(y.total_amt,0),       '' AS descr
                     FROM 
                        (
                        -- �ܻ� �ŷ�ó
                        SELECT a.div_code, 'AR' AS pay_code,  RIGHT(a.pro_code,4) AS pro_code,
                               a.price AS sale_price, 
                               SUM(a.sales_qty) AS sale_qty, 
                               SUM(a.notax_amt) AS sale_amt, 
                               SUM(a.tax_amt) AS vat_amt, 
                               SUM(a.sales_amt) AS total_amt
                          FROM skpDDClosing a
                         WHERE a.div_code   = @p_div_code
                           AND a.close_date = @StdDate
                           AND a.cus_code != ''
                           AND a.cus_code < '90000'
                           -- ���ī��� ����
                           AND a.cus_code NOT IN(SELECT pos_code FROM pos360t WHERE div_code = @p_div_code AND pay_code != 'HEAD_QT' )
                         GROUP BY a.div_code, RIGHT(a.pro_code,4), a.price

                        UNION ALL
                        -- �ſ�ī��
                        SELECT x.div_code, 'CARD' AS pay_code,  x.pro_code,
                               x.sale_price AS sale_price, 
                               SUM(x.sale_qty) AS sale_qty, 
                               SUM(x.sale_amt) AS sale_amt, 
                               SUM(x.vat_amt) AS vat_amt, 
                               SUM(x.total_amt) AS total_amt
                          FROM 
                              (
                              SELECT a.div_code, RIGHT(a.pro_code,4) AS pro_code,
                                     a.price AS sale_price, 
                                     SUM(a.sales_qty) AS sale_qty, 
                                     SUM(a.notax_amt) AS sale_amt, 
                                     SUM(a.tax_amt) AS vat_amt, 
                                     SUM(a.sales_amt) AS total_amt
                                FROM skpDDClosing a
                               WHERE a.div_code          = @p_div_code
                                 AND a.close_date        = @StdDate
                                 AND a.cus_code IN(SELECT pos_code FROM pos360t WHERE div_code = @p_div_code AND pay_code = 'CARD')
                               GROUP BY a.div_code, RIGHT(a.pro_code,4) , a.price

                              -- �ܻ�ŷ�ó �ڵ� �����Ǵ� �� �� ī�� ó���Ȱ�( �ַ� ���ī��)
                              UNION ALL
                              SELECT a.div_code, a.pro_code,
                                     a.sale_price, 
                                     SUM(a.sale_qty) AS sale_qty, 
                                     SUM(a.sale_amt) AS sale_amt, 
                                     SUM(a.vat_amt) AS vat_amt, 
                                     SUM(a.tot_mapping_amt) AS total_amt
                                FROM #CardTemp a
                               GROUP BY a.div_code, a.pro_code, a.sale_price
                              ) x
                         GROUP BY x.div_code, x.pro_code, x.sale_price

                        UNION ALL
                        -- ��ǰ��
                        SELECT x.div_code, 'GIFT' AS pay_code,  x.pro_code,
                               x.sale_price, 
                               x.sale_qty, 
                               x.sale_amt, 
                               x.vat_amt, 
                               x.total_amt
                          FROM 
                              (
                              SELECT a.div_code, RIGHT(a.pro_code,4) AS pro_code,
                                     a.price AS sale_price, 
                                     SUM(a.sales_qty) AS sale_qty, 
                                     SUM(a.notax_amt) AS sale_amt, 
                                     SUM(a.tax_amt) AS vat_amt, 
                                     SUM(a.sales_amt) AS total_amt
                                FROM skpDDClosing a
                               WHERE a.div_code          = @p_div_code
                                 AND a.close_date        = @StdDate
                                 AND  a.cus_code IN( SELECT pos_code FROM pos360t WHERE div_code = @p_div_code AND pay_code = 'GIFT') -- '90051':��ǰ��
                               GROUP BY a.div_code, RIGHT(a.pro_code,4) , a.price
                              ) x
                        UNION ALL
                        -- OK Cash Bag
                        SELECT x.div_code, 'OKCASH' AS pay_code,  x.pro_code,
                               x.sale_price AS sale_price, 
                               x.sale_qty, 
                               x.sale_amt, 
                               x.vat_amt, 
                               x.total_amt
                          FROM 
                              (
                              SELECT a.div_code, RIGHT(a.pro_code,4) AS pro_code,
                                     a.price AS sale_price, 
                                     SUM(a.sales_qty) AS sale_qty, 
                                     SUM(a.notax_amt) AS sale_amt, 
                                     SUM(a.tax_amt) AS vat_amt, 
                                     SUM(a.sales_amt) AS total_amt
                                FROM skpDDClosing a
                               WHERE a.div_code          = @p_div_code
                                 AND a.close_date        = @StdDate
                                 AND  a.cus_code IN( SELECT pos_code FROM pos360t WHERE div_code = @p_div_code AND pay_code = 'OKCASH') -- '90081':OK Cash Bag
                               GROUP BY a.div_code, RIGHT(a.pro_code,4) , a.price
                              ) x

                        -- Mobile Coupon
                        UNION ALL
                        SELECT x.div_code, 'M_COUPON' AS pay_code,  x.pro_code,
                               x.sale_price AS sale_price, 
                               x.sale_qty, 
                               x.sale_amt, 
                               x.vat_amt, 
                               x.total_amt
                          FROM 
                              (
                              SELECT a.div_code, RIGHT(a.pro_code,4) AS pro_code,
                                     a.price AS sale_price, 
                                     SUM(a.sales_qty) AS sale_qty, 
                                     SUM(a.notax_amt) AS sale_amt, 
                                     SUM(a.tax_amt) AS vat_amt, 
                                     SUM(a.sales_amt) AS total_amt
                                FROM skpDDClosing a
                               WHERE a.div_code          = @p_div_code
                                 AND a.close_date        = @StdDate
                                 AND  a.cus_code IN( SELECT pos_code FROM pos360t WHERE div_code = @p_div_code AND pay_code = 'M_COUPON') -- ����� ����
                               GROUP BY a.div_code, RIGHT(a.pro_code,4) , a.price
                              ) x
                        -- ��������
                        UNION ALL
                        SELECT x.div_code, 'POINT' AS pay_code,  x.pro_code,
                               x.sale_price AS sale_price, 
                               x.sale_qty, 
                               x.sale_amt, 
                               x.vat_amt, 
                               x.total_amt
                          FROM 
                              (
                              SELECT a.div_code, RIGHT(a.pro_code,4) AS pro_code,
                                     a.price AS sale_price, 
                                     SUM(a.sales_qty) AS sale_qty, 
                                     SUM(a.notax_amt) AS sale_amt, 
                                     SUM(a.tax_amt) AS vat_amt, 
                                     SUM(a.sales_amt) AS total_amt
                                FROM skpDDClosing a
                               WHERE a.div_code          = @p_div_code
                                 AND a.close_date        = @StdDate
                                 AND  a.cus_code IN( SELECT pos_code FROM pos360t WHERE div_code = @p_div_code AND pay_code = 'POINT') -- ��������
                               GROUP BY a.div_code, RIGHT(a.pro_code,4) , a.price
                              ) x
                        -- �������Ʈ
                        UNION ALL
                        SELECT x.div_code, 'BLUE_POINT' AS pay_code,  x.pro_code,
                               x.sale_price AS sale_price, 
                               x.sale_qty, 
                               x.sale_amt, 
                               x.vat_amt, 
                               x.total_amt
                          FROM 
                              (
                              SELECT a.div_code, RIGHT(a.pro_code,4) AS pro_code,
                                     a.price AS sale_price, 
                                     SUM(a.sales_qty) AS sale_qty, 
                                     SUM(a.notax_amt) AS sale_amt, 
                                     SUM(a.tax_amt) AS vat_amt, 
                                     SUM(a.sales_amt) AS total_amt
                                FROM skpDDClosing a
                               WHERE a.div_code          = @p_div_code
                                 AND a.close_date        = @StdDate
                                 AND  a.cus_code IN( SELECT pos_code FROM pos360t WHERE div_code = @p_div_code AND pay_code = 'BLUE_POINT') -- �������Ʈ
                               GROUP BY a.div_code, RIGHT(a.pro_code,4) , a.price
                              ) x
                        ) y, fgs310t z
                   WHERE y.div_code   = z.div_code
                     AND y.pro_code   = z.pos_code                           
                     AND z.code_type  = 'POS004'


       --select SUM(total_amt)       from POS720T       where div_code = '802'       and yyyymmdd = '20141209'       and pay_code = 'CARD'
         --SELECT a.div_code, a.pro_code,  a.sale_price,  SUM(a.sale_qty) AS sale_qty, SUM(a.sale_amt) AS sale_amt, SUM(a.vat_amt) AS vat_amt,  SUM(a.tot_mapping_amt) AS total_amt  FROM #CardTemp a   GROUP BY a.div_code, a.pro_code, a.sale_price


      -- ���� = ��ü - �ܻ� - �ſ�ī�� 
      INSERT INTO pos720t(div_code,       yyyymmdd,         item_code,     
                          pay_code,       sale_price,       sale_qty,      
                          sale_amt,       vat_amt,          total_amt,        descr)
                   SELECT @p_div_code,    @StdDate,      x.item_code,     
                          'CASH' AS pay_code, x.sale_price ,x.sale_qty - ISNULL(y.sale_qty,0),      
                          x.sale_amt - ISNULL(y.sale_amt,0) AS sale_amt,  
                          x.vat_amt - ISNULL(y.vat_amt,0) AS vat_amt,     
                          x.total_amt - ISNULL(y.total_amt,0) AS total_amt,  '' descr
                     FROM 
                         (
                           SELECT b.erp_code AS item_code, 
                                  price AS sale_price,
                                  SUM(sales_qty) AS sale_qty,
                                  SUM(notax_amt) AS sale_amt,
                                  SUM(tax_amt)   AS vat_amt,
                                  SUM(sales_amt) AS total_amt
                             FROM skpDDClosing a, fgs310t b
                            WHERE RIGHT(a.pro_code,4) = b.pos_code
                              AND a.div_code   = b.div_code
                              AND a.div_code   = @p_div_code
                              AND a.close_date = @StdDate
                              AND b.code_type  = 'POS004'
                            GROUP BY b.erp_code, price 
                         ) x LEFT OUTER JOIN 
                         (   
                           SELECT item_code,  
                                  sale_price,
                                  SUM(sale_qty)  AS sale_qty,   
                                  SUM(sale_amt)  AS sale_amt,   
                                  SUM(vat_amt)   AS vat_amt,   
                                  SUM(total_amt) AS total_amt                        
                             FROM pos720t
                            WHERE div_code   = @p_div_code
                              AND yyyymmdd   = @StdDate
                            GROUP BY item_code, sale_price
                         ) Y ON x.item_code  = y.item_code
                            AND x.sale_price = y.sale_price
                    WHERE x.sale_qty <> ISNULL(y.sale_qty,0)




      DROP TABLE #CardTemp
      DROP TABLE #CardTemp2
      

      
      -- 3.5 �ܻ� �ŷ�ó ����
      DELETE FROM pos728t
            WHERE div_code = @p_div_code
              AND yyyymmdd = @StdDate

      INSERT INTO pos728t (div_code,    yyyymmdd,      pos_custom_code,  
                           item_code,   unit_price,    qty,           
                           sale_amt,    vat_amt,       total_amt)  
                    SELECT x.div_code,  @StdDate,   x.cus_code,  
                           y.erp_code AS item_code,    x.sale_price,    x.sale_qty,           
                           x.sale_amt,  x.vat_amt,     x.total_amt
                      FROM
                          (
                           -- �ܻ� �ŷ�ó
                           SELECT a.div_code, a.cus_code,  RIGHT(a.pro_code,4) AS pro_code,
                                  a.price AS sale_price, 
                                  SUM(a.sales_qty) AS sale_qty, 
                                  SUM(a.notax_amt) AS sale_amt, 
                                  SUM(a.tax_amt) AS vat_amt, 
                                  SUM(a.sales_amt) AS total_amt
                             FROM skpDDClosing a
                            WHERE a.div_code   = @p_div_code
                              AND a.close_date = @StdDate
                              AND a.cus_code != ''
                              AND a.cus_code < '90000'
                              -- ���ī��� ����
                              AND a.cus_code NOT IN(SELECT pos_code FROM pos360t WHERE div_code = @p_div_code AND pay_code != 'HEAD_QT' )
                            GROUP BY a.div_code, a.cus_code, RIGHT(a.pro_code,4), a.price
                           ) x, fgs310t y
                     WHERE x.div_code   = y.div_code
                       AND x.pro_code   = y.pos_code                           
                       AND y.code_type  = 'POS004'
                       


/*
-- �ŷ�ó�� ���� �Աݾ�, �ܻ��
select cus_code, sum(case when io_chk = 1 then amt else 0 end) AS amt_1,
       sum(case when io_chk = 2 then amt else 0 end) AS amt_2
  from BFMAY002
 where close_date = '20090601'
  and io_chk != 0
  --and cus_code < '01000'
  and amt > 0
 group by cus_code
 order by cus_code
*/



/*
EXEC P_posAggregatePosData
      'KOR',--@p_lang_code  VARCHAR(3) = 'KOR',                 -- LANGUAGE �ʱⰪ : KOR.
      'BATCH',--@p_work_type  VARCHAR(10) = 'N',                  -- �۾� ���� : N, U, D
      '0',--@p_return_no  VARCHAR(1) = '1',                   -- ���� �б� ��ȣ
      '804',--@p_div_code                   VARCHAR(8),         -- �����
      '20090801',--@p_yyyymmdd                   VARCHAR(8),         -- ������
      '',--@p_error_code VARCHAR(30)  OUTPUT,                -- �����ڵ� ����
      ''--@p_error_str  VARCHAR(500) OUTPUT                 -- �����޽��� ����
*/




--------------------------------------------------------------------------------------------------------------------------------------------
      -- 4.������Ȳ
      -- �ش��� ���� ������ ���
      SELECT *
        INTO #pos730t_temp_sk
        FROM pos730t
       WHERE div_code = @p_div_code
         AND yyyymmdd = @StdDate


      -- �ش��� ���� ������ ����
      DELETE FROM pos730t
            WHERE div_code = @p_div_code
              AND yyyymmdd = @StdDate


      INSERT INTO pos730t(div_code,       yyyymmdd,      pay_code,      pos_custom_code,
                          basis_amt,      sale_amt_pos,  sale_amt,      in_amt,        charge_amt,       balance_amt, 
                          no_vat_amt,     vat_amt,       in_amt2)
                   SELECT @p_div_code,    @StdDate,   x.pay_code,    x.pos_custom_code,
                          x.basis_amt,    x.sale_amt,    x.sale_amt,    x.in_amt,      x.charge_amt,     x.balance_amt, 
                          0, 0, 0 
                     FROM
                         (
                         -- ī�� ��ü�� ����
                         SELECT 'CARD' AS pay_code,      mcus_code2 AS pos_custom_code,
                                0.0 AS basis_amt, SUM(totsale_amt) AS sale_amt, 0.0 AS in_amt,   0.0 AS charge_amt, 0.0 AS balance_amt
                           FROM skpDDCredit a
                          WHERE div_code   = @p_div_code
                            AND sale_date  = @StdDate
                            AND mcus_code2 != ''
                          GROUP BY mcus_code2
         
                         -- ���� �� �ܻ� ��ǰ��
                         UNION ALL
                         SELECT a.pay_code,      '' AS pos_custom_code,
                                0.0 AS basis_amt,  ISNULL(b.sale_amt,0) AS sale_amt, 0.0 AS in_amt,   0.0 AS charge_amt, 0.0 AS balance_amt
                           FROM pos350t a LEFT OUTER JOIN
                               (
                               SELECT a.pay_code,  SUM(total_amt) AS sale_amt
                                 FROM pos720t a
                                WHERE div_code = @p_div_code
                                  AND yyyymmdd = @StdDate
                                  AND pay_code != 'CARD'
                                GROUP BY pay_code       
                               ) b ON a.pay_code = b.pay_code
                          WHERE a.category = 'PRODUCT'
                            AND a.pay_code != 'CARD'

                         -- ���� ����, ��Ʈ, ��Ÿ����
                         UNION ALL
                         SELECT a.pay_code,      '' AS pos_custom_code,
                                0.0 AS basis_amt,  0.0 AS sale_amt, 0.0 AS in_amt,   0.0 AS charge_amt, 0.0 AS balance_amt
                           FROM pos350t a 
                          WHERE a.category IN('SERVICE', 'EXTRA')

                        ) x
    
      -- Ȥ�� �������ڿ� ���� ���� ī��� ������ �߰�
      INSERT INTO pos730t(div_code,       yyyymmdd,      pay_code,      pos_custom_code,
                          basis_amt,      sale_amt_pos,  sale_amt,      in_amt,        charge_amt,       balance_amt,
                          no_vat_amt,     vat_amt, in_amt2)
                   SELECT @p_div_code,    @StdDate,   x.pay_code,    x.pos_custom_code,
                          x.balance_amt,  0,             0,             0,             0,                x.balance_amt, 
                          0, 0, 0 
                     FROM pos730t x LEFT OUTER JOIN 
                          (       
                            SELECT pos_custom_code
                              FROM pos730t a
                             WHERE a.div_code = @p_div_code
                               AND a.yyyymmdd = @StdDate
                               AND a.pay_code = 'CARD'
                          ) y ON x.pos_custom_code  = y.pos_custom_code
                    WHERE x.div_code  = @p_div_code
                      AND x.yyyymmdd  =  CONVERT(VARCHAR(8), DATEADD(dd,-1,@StdDate),112)
                      AND x.pay_code  = 'CARD'
                      AND y.pos_custom_code  IS NULL         


      --  ���� ������ ����
      UPDATE pos730t
         SET in_amt               = b.in_amt,
             charge_amt           = b.charge_amt
        FROM pos730t a, #pos730t_temp_sk b
       WHERE a.div_code = b.div_code
         AND a.yyyymmdd = b.yyyymmdd
         AND a.pay_code = b.pay_code
         AND a.pos_custom_code = b.pos_custom_code
         AND a.div_code = @p_div_code
         AND a.yyyymmdd = @StdDate 



      -- �����ܾ� �� �����ܾ� UPDATE
      UPDATE pos730t
         SET basis_amt            = ISNULL(b.balance_amt,0),
             in_amt               = CASE WHEN a.pay_code IN('CASH','GIFT','POINT') AND a.in_amt = 0 THEN ISNULL(b.balance_amt,0) ELSE a.in_amt END, -- ������ ��� �����̿��ݾ��� �Աݾ�
             no_vat_amt           = FLOOR(sale_amt * 10/11),
             vat_amt              = sale_amt - FLOOR(sale_amt * 10/11),
             balance_amt          = ISNULL(b.balance_amt,0) + sale_amt - CASE WHEN a.pay_code IN('CASH','GIFT','POINT') AND a.in_amt = 0 THEN ISNULL(b.balance_amt,0) ELSE a.in_amt + a.charge_amt END
        FROM pos730t a LEFT OUTER JOIN 
             ( SELECT div_code,  pay_code,  pos_custom_code, balance_amt
                 FROM pos730t
                WHERE div_code  = @p_div_code
                  AND yyyymmdd  = CONVERT(VARCHAR(8), DATEADD(dd,-1,@StdDate),112) 
             ) b ON a.div_code        = b.div_code
                AND a.pay_code        = b.pay_code
                AND a.pos_custom_code = b.pos_custom_code
       WHERE a.div_code = @p_div_code
         AND a.yyyymmdd = @StdDate 


      DROP TABLE #pos730t_temp_sk





/*
EXEC P_posAggregatePosData
      'KOR',--@p_lang_code  VARCHAR(3) = 'KOR',                 -- LANGUAGE �ʱⰪ : KOR.
      'BATCH',--@p_work_type  VARCHAR(10) = 'N',                  -- �۾� ���� : N, U, D
      '0',--@p_return_no  VARCHAR(1) = '1',                   -- ���� �б� ��ȣ
      '804',--@p_div_code                   VARCHAR(8),         -- �����
      '20090601',--@p_yyyymmdd                   VARCHAR(8),         -- ������
      '',--@p_error_code VARCHAR(30)  OUTPUT,                -- �����ڵ� ����
      ''--@p_error_str  VARCHAR(500) OUTPUT                 -- �����޽��� ����
*/




      -- �ŷ�ó��  �ܻ� ����/���� ����
      -- skpDDAR
      DELETE FROM pos735t
            WHERE div_code   = @p_div_code
              AND yyyymmdd   = @StdDate


      INSERT INTO pos735t(div_code,       yyyymmdd,      pos_custom_code,
                          basis_amt,      in_amt,        ar_amt,           
                          balance_amt)
                   SELECT @p_div_code,    @StdDate,   cus_code,
                          x.basis_amt,    x.in_amt,      x.ar_amt,  
                          x.basis_amt - x.in_amt + x.ar_amt   
                     FROM 
                         (
                         SELECT cus_code, 
                                SUM(CASE WHEN io_chk = '0' THEN bef_amt ELSE 0 END) AS basis_amt,
                                SUM(CASE WHEN io_chk = '1' THEN amt ELSE 0 END) AS in_amt,
                                SUM(CASE WHEN io_chk = '2' THEN amt ELSE 0 END) AS ar_amt
                           FROM skpDDAR
                          WHERE div_code    = @p_div_code
                            AND close_date  = @StdDate
                            AND cus_code < '90000'
                           -- ���ī��� ����
                            AND cus_code NOT IN(SELECT pos_code FROM pos360t WHERE div_code = @p_div_code AND pay_code = 'DCCARD')
                          GROUP BY cus_code
                          ) x


      -- �ſ� 1���� �ƴ� ���� ���Ͽ��� ���ʱݾ��� ������ Updat�Ѵ�.
      IF ( RIGHT(@StdDate,2) > '01')
      BEGIN
         UPDATE pos735t 
            SET basis_amt   = ISNULL(y.balance_amt,0),
                balance_amt = ISNULL(y.balance_amt,0) - x.in_amt + x.ar_amt 
           FROM pos735t x,
                ( 
                 SELECT a.pos_custom_code, a.balance_amt
                   FROM pos735t a,
                       ( SELECT pos_custom_code, max(yyyymmdd) AS max_yyyymmdd
                           FROM pos735t a
                          WHERE a.div_code     = @p_div_code
                            AND a.yyyymmdd     < @StdDate
                          GROUP BY pos_custom_code
                       ) b
                 WHERE a.pos_custom_code = b.pos_custom_code
                   AND a.yyyymmdd        = b.max_yyyymmdd
                   AND a.div_code        = @p_div_code
                ) y
          WHERE x.pos_custom_code = y.pos_custom_code
            AND x.yyyymmdd        = @StdDate
            AND x.div_code        = @p_div_code

      END

      
      -- 5.�������α�
      DELETE FROM pos740t
            WHERE div_code = @p_div_code
              AND yyyymmdd = @StdDate

      INSERT INTO pos740t(div_code,          yyyymmdd,         basis_amt,
                          today_incoupon,    refueling_amt,    loan_amt,
                          industry_amt,      total_amt,        today_amt,         
                          basis_bal,        issue_coupon,      destruc_coupon,    today_bal)
                   SELECT @p_div_code,       @StdDate,      0 AS basis_amt,
                          0 today_incoupon,  0 refueling_amt,  0 loan_amt,
                          0 industry_amt,    0 total_amt,      0 today_amt,
                          0 basis_bal,       0 issue_coupon,   0 destruc_coupon,  0 today_bal

 --return 
      -- ���� �̿� Update
      UPDATE pos740t
         SET basis_amt            = ISNULL(b.today_amt,0),
             refueling_amt        = ISNULL(c.refueling_amt,0),
             total_amt            = ISNULL(c.refueling_amt,0),
             today_amt            = ISNULL(b.today_amt,0) + ISNULL(c.refueling_amt,0), 
             basis_bal            = ISNULL(b.today_bal,0)
        FROM pos740t a 
             -- ���� �̿�
             LEFT OUTER JOIN 
             ( SELECT div_code, today_amt, today_bal
                 FROM pos740t
                WHERE div_code  = @p_div_code
                  AND yyyymmdd  = CONVERT(VARCHAR(8), DATEADD(dd,-1,@StdDate),112) 
             ) b ON a.div_code  = b.div_code
             -- ���� ȸ�� �� ����, �뿩��
             LEFT OUTER JOIN 
             ( SELECT div_code, 
                      SUM( CASE WHEN pay_code = 'COUPON' THEN sale_amt ELSE 0 END) AS refueling_amt -- �����ݾ� ���� �ۺ�
                 FROM pos730t
                WHERE div_code  = @p_div_code
                  AND yyyymmdd  = @StdDate
                  AND pay_code  = ''
                GROUP BY div_code
             ) c ON a.div_code  = c.div_code

       WHERE a.div_code = @p_div_code
         AND a.yyyymmdd = @StdDate 

         
 
      -- 5.��������
      DELETE FROM pos750t
            WHERE div_code = @p_div_code
              AND yyyymmdd = @StdDate


      INSERT INTO pos750t(div_code,          yyyymmdd,      
                          before_meter,      current_meter,       flow_cnt,
                          charge_cnt,        nocharge_cnt,        test_cnt , sale_cnt)
                   SELECT @p_div_code,       @StdDate,      
                          0 AS before_meter, 0 AS current_meter,  0 AS flow_cnt,
                          0 AS charge_cnt,   0 AS nocharge_cnt,   0 AS test_cnt , 0 AS sale_cnt
 
      UPDATE pos750t
         SET before_meter  = ISNULL(b.current_meter,0)
        FROM pos750t a 
             -- ���� �̿�
             LEFT OUTER JOIN 
             ( SELECT div_code, current_meter
                 FROM pos750t
                WHERE div_code  = @p_div_code
                  AND yyyymmdd  = CONVERT(VARCHAR(8), DATEADD(dd,-1,@StdDate),112) 
             ) b ON a.div_code  = b.div_code
       WHERE a.div_code = @p_div_code
         AND a.yyyymmdd = @StdDate 
    END





return 
go
begin tran 
exec hye_SSLOilDailySalesSum @xmlDocument=N'<ROOT>
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
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730106,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730028
rollback 