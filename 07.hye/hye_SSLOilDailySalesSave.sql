  
IF OBJECT_ID('hye_SSLOilDailySalesSave') IS NOT NULL   
    DROP PROC hye_SSLOilDailySalesSave  
GO  
  
-- v2016.09.23 
  
-- �������Ǹ��Ϻ����-���� by ����õ 
CREATE PROC hye_SSLOilDailySalesSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)
      
    CREATE TABLE #SS1( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#SS1'   
    IF @@ERROR <> 0 RETURN   
    
    CREATE TABLE #SS2( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#SS2'   
    IF @@ERROR <> 0 RETURN   
    
    CREATE TABLE #SS3( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#SS3'   
    IF @@ERROR <> 0 RETURN   
    
    CREATE TABLE #SS4( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock4', '#SS4'   
    IF @@ERROR <> 0 RETURN   
    
    CREATE TABLE #SS5( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock5', '#SS5'   
    IF @@ERROR <> 0 RETURN   
    
    CREATE TABLE #SS6( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock6', '#SS6'   
    IF @@ERROR <> 0 RETURN   
    
    CREATE TABLE #SS7( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock7', '#SS7'   
    IF @@ERROR <> 0 RETURN   

    CREATE TABLE #SS8( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock8', '#SS8'   
    IF @@ERROR <> 0 RETURN   
    
    CREATE TABLE #SS10( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock10', '#SS10'   
    IF @@ERROR <> 0 RETURN   
    
    
    -- �����Ȳ 
    UPDATE A
       SET flow_qty          = B.flow_qty -- ���ȸ���� 
          ,extra_out_qty    = B.extra_out_qty -- �������Ϸ� 
          ,insp_qty         = B.insp_qty -- �˻�/ȸ���� 
          ,trans_in_qty     = B.trans_in_qty -- �̼� 
          ,trans_out_qty    = B.trans_out_qty -- �̰� 
          ,keeping_qty      = B.keeping_qty -- ���� 
          ,self_consume_qty = B.self_consume_qty -- �ڰ��Һ� 
          ,descr            = B.descr -- ���� 
      FROM pos700t  AS A 
      JOIN #SS1     AS B ON ( B.BizUnit = A.div_code 
                          AND B.StdDate = A.yyyymmdd 
                          AND B.item_code = A.item_code 
                          AND B.tank_no = A.tank_no 
                          AND B.nozzle_no = A.nozzle_no
                            )
    
    -- ������Ȳ
    UPDATE A
       SET in_qty           = B.in_qty -- �԰� 
          ,extra_in_qty     = B.extra_in_qty -- ���Է� 
          ,extra_out_qty    = B.extra_out_qty -- ���ⷮ 
          ,real_qty         = B.real_qty -- �������  
          ,descr            = B.descr -- ���� 
      FROM pos710t  AS A 
      JOIN #SS2     AS B ON ( B.BizUnit = A.div_code 
                          AND B.StdDate = A.yyyymmdd
                          AND B.item_code = A.item_code 
                          AND B.tank_no = A.tank_no 
                            )


    -- �Ǹ���Ȳ 

    -- �������� 
    SELECT A.div_code, A.yyyymmdd, A.item_code, A.sale_price, 'POINT' AS pay_code
      INTO #pos720t
      FROM pos720t  AS A 
      JOIN #SS3     AS B ON ( B.BizUnit = A.div_code 
                          AND B.StdDate = A.yyyymmdd 
                          AND B.item_code = A.item_code 
                          AND B.sale_price = A.sale_price
                            )
    GROUP BY A.div_code, A.yyyymmdd, A.item_code, A.sale_price
    UNION ALL
    -- ��ǰ�� 
    SELECT A.div_code, A.yyyymmdd, A.item_code, A.sale_price, 'GIFT' AS pay_code
      FROM pos720t  AS A 
      JOIN #SS3     AS B ON ( B.BizUnit = A.div_code 
                          AND B.StdDate = A.yyyymmdd 
                          AND B.item_code = A.item_code 
                          AND B.sale_price = A.sale_price
                            )
    GROUP BY A.div_code, A.yyyymmdd, A.item_code, A.sale_price
    UNION ALL
    -- OKCashbag 
    SELECT A.div_code, A.yyyymmdd, A.item_code, A.sale_price, 'OKCASH' AS pay_code
      FROM pos720t  AS A 
      JOIN #SS3     AS B ON ( B.BizUnit = A.div_code 
                          AND B.StdDate = A.yyyymmdd 
                          AND B.item_code = A.item_code 
                          AND B.sale_price = A.sale_price
                            )
    GROUP BY A.div_code, A.yyyymmdd, A.item_code, A.sale_price
    UNION ALL 
    -- �������α� 
    SELECT A.div_code, A.yyyymmdd, A.item_code, A.sale_price, 'COUPON' AS pay_code
      FROM pos720t  AS A 
      JOIN #SS3     AS B ON ( B.BizUnit = A.div_code 
                          AND B.StdDate = A.yyyymmdd 
                          AND B.item_code = A.item_code 
                          AND B.sale_price = A.sale_price
                            )
    GROUP BY A.div_code, A.yyyymmdd, A.item_code, A.sale_price
    UNION ALL
    -- ����� 
    SELECT A.div_code, A.yyyymmdd, A.item_code, A.sale_price, 'M_COUPON' AS pay_code
      FROM pos720t  AS A 
      JOIN #SS3     AS B ON ( B.BizUnit = A.div_code 
                          AND B.StdDate = A.yyyymmdd 
                          AND B.item_code = A.item_code 
                          AND B.sale_price = A.sale_price
                            )
    GROUP BY A.div_code, A.yyyymmdd, A.item_code, A.sale_price


    --select * from #pos720t 
    --return 

    INSERT INTO pos720t 
    (
        div_code, yyyymmdd, item_code, pay_code, sale_price, 
        sale_qty, sale_amt, vat_amt, total_amt, descr
    ) 
    SELECT div_code, yyyymmdd, item_code, pay_code, sale_price, 
           0, 0, 0, 0, ''
      FROM #pos720t AS A 
     WHERE NOT EXISTS (
                       SELECT 1 
                         FROM pos720t 
                        WHERE div_code = A.div_code 
                          AND yyyymmdd = A.yyyymmdd 
                          AND item_code = A.item_code 
                          AND sale_price = A.sale_price 
                          AND pay_code = A.pay_code 
                      )
    
    UPDATE A
       SET total_amt = CASE WHEN A.pay_code = 'POINT' THEN B.POINT_sale_amt -- ��������
                            WHEN A.pay_code = 'GIFT' THEN B.GIFT_sale_amt -- ��ǰ�� 
                            WHEN A.pay_code = 'OKCASH' THEN B.OKCASH_sale_amt -- OKCashbag
                            WHEN A.pay_code = 'COUPON' THEN B.COUPON_sale_amt -- ���������α�
                            WHEN A.pay_code = 'M_COUPON' THEN B.M_COUPON_sale_amt -- �����
                            ELSE A.total_amt END 
          ,descr    = B.descr3 -- ����
      FROM pos720t  AS A 
      JOIN #SS3     AS B ON ( B.BizUnit = A.div_code 
                          AND B.StdDate = A.yyyymmdd 
                          AND B.item_code = A.item_code 
                          AND B.sale_price = A.sale_price
                            )

    -- ������Ȳ 
    UPDATE A
       SET sale_amt     = B.sale_amt -- ���ϸ����(����) 
          ,in_amt       = B.in_amt -- �����Ա�(���뿹��) 
          ,charge_amt   = B.charge_amt -- ������ 
          ,descr        = B.descr -- ����
      FROM pos730t  AS A 
      JOIN #SS4     AS B ON ( B.BizUnit = A.div_code 
                          AND B.StdDate = A.yyyymmdd 
                          AND B.pay_code = A.pay_code 
                          AND B.pos_custom_code = A.pos_custom_code
                            )


    -- ��Ÿ��ǰ ���� �� �����Ȳ 

    -- ������Ȳ 
    UPDATE A
       SET current_meter    = B.current_meter -- ���ϰ��
          ,flow_cnt          = B.flow_cnt -- ȸ����
          ,charge_cnt       = B.charge_cnt -- ���ݼ���
          ,nocharge_cnt     = B.nocharge_cnt -- ���Ἴ��
          ,test_cnt         = B.test_cnt -- �׽�Ʈ
          ,sale_cnt         = B.sale_cnt -- �Ǹ�������
      FROM pos750t  AS A 
      JOIN #SS5     AS B ON ( B.BizUnit = A.div_code AND B.StdDate = A.yyyymmdd ) 
    
    -- �������αǺ��� �� ȸ������
    UPDATE A
       SET today_incoupon   = B.today_incoupon -- ����ȸ��
          ,refueling_amt    = B.refueling_amt -- ����
          ,loan_amt         = B.loan_amt -- �뿩��
          ,industry_amt     = B.industry_amt -- ������
          ,total_amt        = B.total_amt -- ��
          ,today_amt        = B.today_amt -- �����ܾ�
      FROM pos740t  AS A 
      JOIN #SS6     AS B ON ( B.BizUnit = A.div_code AND B.StdDate = A.yyyymmdd ) 
    

    -- �������α� ��������
    UPDATE A
       SET basis_bal        = B.basis_bal -- ����ȸ��
          ,issue_coupon     = B.issue_coupon -- ȸ�����α�
          ,destruc_coupon   = B.destruc_coupon -- �ı����α�
          ,today_bal        = B.today_bal -- �����ܰ�
      FROM pos740t   AS A 
      JOIN #SS10     AS B ON ( B.BizUnit = A.div_code AND B.StdDate = A.yyyymmdd ) 
    



    SELECT * FROM #SS1
    SELECT * FROM #SS2
    SELECT * FROM #SS3
    SELECT * FROM #SS4
    SELECT * FROM #SS5
    SELECT * FROM #SS6
    SELECT * FROM #SS7
    SELECT * FROM #SS8
    SELECT * FROM #SS10 
      
    RETURN  
    go

begin tran 

exec hye_SSLOilDailySalesSave @xmlDocument=N'<ROOT>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>02</cs_code>
    <cs_name>��������</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>0</ar_amt>
    <balance_amt>0</balance_amt>
    <TABLE_NAME>DataBlock7</TABLE_NAME>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>10</cs_code>
    <cs_name>(��)������</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>850351</ar_amt>
    <balance_amt>850351</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>12</cs_code>
    <cs_name>�ູ�ý��ֽ�ȸ��</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>1280524</ar_amt>
    <balance_amt>1280524</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>14</cs_code>
    <cs_name>�����ý�(��)</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>62062</ar_amt>
    <balance_amt>62062</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>17</cs_code>
    <cs_name>�泲������Ȱ�İ߱��</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>0</ar_amt>
    <balance_amt>0</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>18</cs_code>
    <cs_name>����������</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>0</ar_amt>
    <balance_amt>0</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>19</cs_code>
    <cs_name>����ǻ�������Ư��</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>80791</ar_amt>
    <balance_amt>80791</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>21</cs_code>
    <cs_name>(��)�ѱ����</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>0</ar_amt>
    <balance_amt>0</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>25</cs_code>
    <cs_name>�����簡������������</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>16421</ar_amt>
    <balance_amt>16421</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>26</cs_code>
    <cs_name>�ֽ�ȸ�絹�����弼</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>24610</ar_amt>
    <balance_amt>24610</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>27</cs_code>
    <cs_name>�ֽ�ȸ�� �޸տ����Ǿ�</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>0</ar_amt>
    <balance_amt>0</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>28</cs_code>
    <cs_name>���񿡽� ����Ƽ���� �ֽ�ȸ��</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>0</ar_amt>
    <balance_amt>0</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>13</IDX_NO>
    <DataSeq>13</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>30</cs_code>
    <cs_name>�漮��ȭ</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>0</ar_amt>
    <balance_amt>0</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>14</IDX_NO>
    <DataSeq>14</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code>42</cs_code>
    <cs_name>�ߺε��ð�������������</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>0</ar_amt>
    <balance_amt>0</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock7>
    <WorkingTag />
    <IDX_NO>15</IDX_NO>
    <DataSeq>15</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <cs_code />
    <cs_name>�հ�</cs_name>
    <basis_amt>0</basis_amt>
    <in_amt>0</in_amt>
    <ar_amt>2314759</ar_amt>
    <balance_amt>2314759</balance_amt>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock7>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>AR</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>2314759</sale_amt_pos>
    <sale_amt>2314759</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>2314759</balance_amt>
    <descr />
    <TABLE_NAME>DataBlock4</TABLE_NAME>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>B_PRODUCT</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>1</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr>2</descr>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>BLUE_POINT</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>0</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD</pay_code>
    <pos_custom_code>006</pos_custom_code>
    <basis_amt>0</basis_amt>
    <sale_amt_pos>480805</sale_amt_pos>
    <sale_amt>480805</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>480805</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD</pay_code>
    <pos_custom_code>008</pos_custom_code>
    <basis_amt>0</basis_amt>
    <sale_amt_pos>59422</sale_amt_pos>
    <sale_amt>59422</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>59422</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD</pay_code>
    <pos_custom_code>016</pos_custom_code>
    <basis_amt>0</basis_amt>
    <sale_amt_pos>1215634</sale_amt_pos>
    <sale_amt>1215634</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>1215634</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD</pay_code>
    <pos_custom_code>018</pos_custom_code>
    <basis_amt>0</basis_amt>
    <sale_amt_pos>945046</sale_amt_pos>
    <sale_amt>945046</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>945046</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD</pay_code>
    <pos_custom_code>026</pos_custom_code>
    <basis_amt>0</basis_amt>
    <sale_amt_pos>1352014</sale_amt_pos>
    <sale_amt>1352014</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>1352014</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD</pay_code>
    <pos_custom_code>027</pos_custom_code>
    <basis_amt>0</basis_amt>
    <sale_amt_pos>707352</sale_amt_pos>
    <sale_amt>707352</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>707352</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD</pay_code>
    <pos_custom_code>029</pos_custom_code>
    <basis_amt>0</basis_amt>
    <sale_amt_pos>1713093</sale_amt_pos>
    <sale_amt>1713093</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>1713093</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD</pay_code>
    <pos_custom_code>031</pos_custom_code>
    <basis_amt>0</basis_amt>
    <sale_amt_pos>444896</sale_amt_pos>
    <sale_amt>444896</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>444896</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD</pay_code>
    <pos_custom_code>047</pos_custom_code>
    <basis_amt>0</basis_amt>
    <sale_amt_pos>257983</sale_amt_pos>
    <sale_amt>257983</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>257983</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>13</IDX_NO>
    <DataSeq>13</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CARD �Ұ�</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>7176245</sale_amt_pos>
    <sale_amt>7176245</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>7176245</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>14</IDX_NO>
    <DataSeq>14</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>CASH</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>699000</sale_amt_pos>
    <sale_amt>699000</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>699000</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>15</IDX_NO>
    <DataSeq>15</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>COUPON</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>0</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>16</IDX_NO>
    <DataSeq>16</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>E_PRODUCT</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>0</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>17</IDX_NO>
    <DataSeq>17</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>GIFT</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>0</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>18</IDX_NO>
    <DataSeq>18</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>LOAN</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>0</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>19</IDX_NO>
    <DataSeq>19</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>M_COUPON</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>0</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>20</IDX_NO>
    <DataSeq>20</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>OKCASH</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>0</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>21</IDX_NO>
    <DataSeq>21</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>POINT</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>0</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>22</IDX_NO>
    <DataSeq>22</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>WASH</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>0</sale_amt_pos>
    <sale_amt>0</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>0</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag />
    <IDX_NO>23</IDX_NO>
    <DataSeq>23</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <pay_code>�հ�</pay_code>
    <pos_custom_code />
    <basis_amt>0</basis_amt>
    <sale_amt_pos>7176245</sale_amt_pos>
    <sale_amt>7176245</sale_amt>
    <in_amt>0</in_amt>
    <in_amt2>0</in_amt2>
    <charge_amt>0</charge_amt>
    <balance_amt>7176245</balance_amt>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock4>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <sale_total_qty>13586.64</sale_total_qty>
    <sale_price>750</sale_price>
    <total_amt>10190004</total_amt>
    <CASH_sale_amt>699000</CASH_sale_amt>
    <CARD_sale_amt>7176245</CARD_sale_amt>
    <AR_sale_amt>2314759</AR_sale_amt>
    <GIFT_sale_amt>1</GIFT_sale_amt>
    <OKCASH_sale_amt>2</OKCASH_sale_amt>
    <COUPON_sale_amt>3</COUPON_sale_amt>
    <M_COUPON_sale_amt>4</M_COUPON_sale_amt>
    <POINT_sale_amt>0</POINT_sale_amt>
    <BLUE_POINT_sale_amt>0</BLUE_POINT_sale_amt>
    <descr2>0</descr2>
    <descr3>5</descr3>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <sale_total_qty>13586.64</sale_total_qty>
    <sale_price>0</sale_price>
    <total_amt>10190004</total_amt>
    <CASH_sale_amt>699000</CASH_sale_amt>
    <CARD_sale_amt>7176245</CARD_sale_amt>
    <AR_sale_amt>2314759</AR_sale_amt>
    <GIFT_sale_amt>0</GIFT_sale_amt>
    <OKCASH_sale_amt>0</OKCASH_sale_amt>
    <COUPON_sale_amt>0</COUPON_sale_amt>
    <M_COUPON_sale_amt>0</M_COUPON_sale_amt>
    <POINT_sale_amt>0</POINT_sale_amt>
    <BLUE_POINT_sale_amt>0</BLUE_POINT_sale_amt>
    <descr2>0</descr2>
    <descr3 />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code />
    <sale_total_qty>13586.64</sale_total_qty>
    <sale_price>0</sale_price>
    <total_amt>10190004</total_amt>
    <CASH_sale_amt>699000</CASH_sale_amt>
    <CARD_sale_amt>7176245</CARD_sale_amt>
    <AR_sale_amt>2314759</AR_sale_amt>
    <GIFT_sale_amt>0</GIFT_sale_amt>
    <OKCASH_sale_amt>0</OKCASH_sale_amt>
    <COUPON_sale_amt>0</COUPON_sale_amt>
    <M_COUPON_sale_amt>0</M_COUPON_sale_amt>
    <POINT_sale_amt>0</POINT_sale_amt>
    <BLUE_POINT_sale_amt>0</BLUE_POINT_sale_amt>
    <descr2>0</descr2>
    <descr3 />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock3>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <tank_no>01</tank_no>
    <unit_no />
    <basis_qty>0</basis_qty>
    <in_qty>1</in_qty>
    <sale_qty>7934.598</sale_qty>
    <extra_in_qty>2</extra_in_qty>
    <extra_out_qty>3</extra_out_qty>
    <onhand_qty>-7934.598</onhand_qty>
    <pos_real_qty>0</pos_real_qty>
    <real_qty>4</real_qty>
    <day_diff_qty>7934.598</day_diff_qty>
    <month_diff_qty>7934.598</month_diff_qty>
    <descr>5</descr>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <tank_no>�Ұ�</tank_no>
    <unit_no />
    <basis_qty>0</basis_qty>
    <in_qty>1</in_qty>
    <sale_qty>7934.598</sale_qty>
    <extra_in_qty>2</extra_in_qty>
    <extra_out_qty>3</extra_out_qty>
    <onhand_qty>-7934.598</onhand_qty>
    <pos_real_qty>0</pos_real_qty>
    <real_qty>4</real_qty>
    <day_diff_qty>7934.598</day_diff_qty>
    <month_diff_qty>7934.598</month_diff_qty>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code />
    <tank_no>�հ�</tank_no>
    <unit_no />
    <basis_qty>0</basis_qty>
    <in_qty>1</in_qty>
    <sale_qty>7934.598</sale_qty>
    <extra_in_qty>2</extra_in_qty>
    <extra_out_qty>3</extra_out_qty>
    <onhand_qty>-7934.598</onhand_qty>
    <pos_real_qty>0</pos_real_qty>
    <real_qty>4</real_qty>
    <day_diff_qty>7934.598</day_diff_qty>
    <month_diff_qty>7934.598</month_diff_qty>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock2>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <tank_no>01</tank_no>
    <nozzle_no>1</nozzle_no>
    <unit_no />
    <before_meter>0</before_meter>
    <current_meter>1565.024</current_meter>
    <flow_qty>1</flow_qty>
    <extra_out_qty>3</extra_out_qty>
    <insp_qty>4</insp_qty>
    <trans_in_qty>0</trans_in_qty>
    <trans_out_qty>0</trans_out_qty>
    <keeping_qty>5</keeping_qty>
    <self_consume_qty>6</self_consume_qty>
    <net_sale_qty>1565.024</net_sale_qty>
    <descr>7</descr>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <tank_no>01</tank_no>
    <nozzle_no>2</nozzle_no>
    <unit_no />
    <before_meter>0</before_meter>
    <current_meter>7162.445</current_meter>
    <flow_qty>7162.445</flow_qty>
    <extra_out_qty>0</extra_out_qty>
    <insp_qty>0</insp_qty>
    <trans_in_qty>0</trans_in_qty>
    <trans_out_qty>0</trans_out_qty>
    <keeping_qty>0</keeping_qty>
    <self_consume_qty>0</self_consume_qty>
    <net_sale_qty>7162.445</net_sale_qty>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <tank_no>01</tank_no>
    <nozzle_no>3</nozzle_no>
    <unit_no />
    <before_meter>0</before_meter>
    <current_meter>2060.772</current_meter>
    <flow_qty>2060.772</flow_qty>
    <extra_out_qty>0</extra_out_qty>
    <insp_qty>0</insp_qty>
    <trans_in_qty>0</trans_in_qty>
    <trans_out_qty>0</trans_out_qty>
    <keeping_qty>0</keeping_qty>
    <self_consume_qty>0</self_consume_qty>
    <net_sale_qty>2060.772</net_sale_qty>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <tank_no>01</tank_no>
    <nozzle_no>4</nozzle_no>
    <unit_no />
    <before_meter>0</before_meter>
    <current_meter>2798.399</current_meter>
    <flow_qty>2798.399</flow_qty>
    <extra_out_qty>0</extra_out_qty>
    <insp_qty>0</insp_qty>
    <trans_in_qty>0</trans_in_qty>
    <trans_out_qty>0</trans_out_qty>
    <keeping_qty>0</keeping_qty>
    <self_consume_qty>0</self_consume_qty>
    <net_sale_qty>2798.399</net_sale_qty>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code>903921</item_code>
    <tank_no>�Ұ�</tank_no>
    <nozzle_no />
    <unit_no />
    <before_meter>0</before_meter>
    <current_meter>13586.64</current_meter>
    <flow_qty>12022.616</flow_qty>
    <extra_out_qty>3</extra_out_qty>
    <insp_qty>4</insp_qty>
    <trans_in_qty>0</trans_in_qty>
    <trans_out_qty>0</trans_out_qty>
    <keeping_qty>5</keeping_qty>
    <self_consume_qty>6</self_consume_qty>
    <net_sale_qty>13586.64</net_sale_qty>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <item_code />
    <tank_no>�հ�</tank_no>
    <nozzle_no />
    <unit_no />
    <before_meter>0</before_meter>
    <current_meter>13586.64</current_meter>
    <flow_qty>12022.616</flow_qty>
    <extra_out_qty>3</extra_out_qty>
    <insp_qty>4</insp_qty>
    <trans_in_qty>0</trans_in_qty>
    <trans_out_qty>0</trans_out_qty>
    <keeping_qty>5</keeping_qty>
    <self_consume_qty>6</self_consume_qty>
    <net_sale_qty>13586.64</net_sale_qty>
    <descr />
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730106,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730008

rollback 

