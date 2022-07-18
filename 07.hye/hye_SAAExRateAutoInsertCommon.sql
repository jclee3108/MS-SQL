IF OBJECT_ID('hye_SAAExRateAutoInsertCommon') IS NOT NULL 
    DROP PROC hye_SAAExRateAutoInsertCommon
GO 

CREATE PROC hye_SAAExRateAutoInsertCommon
    @CompanySeq INT 
AS
    DECLARE @ExRateDate NCHAR(8)
    
    SELECT @ExRateDate = CONVERT(NCHAR(8), GETDATE(), 112)
    

    /**************************************************************************************************************************************
    =======================================================================================================================================
     �������̺� Layout
    =======================================================================================================================================
    STD_DD              nchar       8       ��������         
    CUR_NM_C10          nvarchar    10      ��ȭ��C10        
    CUR_NM_C8           nvarchar    8       ��ȭ��C8		    
    CASH_BUYING         nvarchar    8       ������Ƕ�		
    CASH_SELLING        nvarchar    8       �����ĽǶ�		
    SENDAMT_SENDHH      nvarchar    8       �۱ݺ�����		
    SENDAMT_RCVHH       nvarchar    8       �۱ݹ�����		
    TC_BUYING           nvarchar    8       TC��Ƕ�		    
    TC_SELL             nvarchar    8       TC�ĽǶ�		    
    FORECURCHK_SELLHH   nvarchar    8       ��ȭ��ǥ�ĽǶ�	
    BUYSEL_BASE_RATE    nvarchar    8       �Ÿű�����		
    COMMISSION_RATE     nvarchar    8       ȯ������		    
    USD_CVTRATE_N7      nvarchar    8       ���ȯ����N7		
    QUOT_SEQ            nvarchar    10      ���ȸ��		    
    QUOT_HH             nvarchar    20      ��ýð�		    
    ERP_SENDYN          nvarchar    1       ERP���迩���÷�����  ERP���ۿ���		
    TRANSF_DDHH         nvarchar    14      ERP�����Ͻ��ʵ���  �����Ͻ�		    
    =======================================================================================================================================
     �������̺� Layout
    =======================================================================================================================================
    **************************************************************************************************************************************/
     
    -- �������� ���� 
    IF NOT EXISTS (SELECT 1 FROM HIST_INITQUOT_EXCHRATE WHERE STD_DD = @ExRateDate AND ISNULL(ERP_SENDYN, '') = 'Y')
    BEGIN
        DELETE _TDAExRate WHERE CompanySeq = @CompanySeq AND ExRateDate = @ExRateDate
    END
    
    -- �������� ERP�� ����
    INSERT INTO _TDAExRate (CompanySeq      , -- �����ڵ� 
                            ExRateDate      , -- ȯ������
                            CurrSeq         , -- ��ȭ
                            SMFirstOrLast   , -- ȯ���ޱ�����  4149001:���ʰ��ȯ��, 4149002:�������ȯ��
                            TTM             , -- �Ÿű�����
                            TTB             , -- �۱ݺ�����
                            TTS             , -- �۱ݹ�����
                            CASHB           , -- �����춧
                            CASHS           , -- �����ȶ�
                            USAExrate       , -- ���ȯ��
                            ChangeRate      , -- ȯ������
                            LastUserSeq     , 
                            LastDateTime    )
        SELECT @CompanySeq                                              AS CompanySeq       , -- �����ڵ�
               A.STD_DD                                                 AS ExRateDate       , -- ȯ������
               ISNULL(B.CurrSeq, 0)                                     AS CurrSeq          , -- ȭ���ڵ�
               4149001                                                  AS SMFirstOrLast    , -- ȯ���ޱ����� (���ʰ��ȯ��)
               CONVERT(DECIMAL(19,5), A.BUYSEL_BASE_RATE            )   AS TTM              , -- �Ÿű�����
               CONVERT(DECIMAL(19,5), A.SENDAMT_SENDHH              )   AS TTB              , -- �۱ݺ�����
               CONVERT(DECIMAL(19,5), A.SENDAMT_RCVHH               )   AS TTS              , -- �۱ݹ�����
               CONVERT(DECIMAL(19,5), A.CASH_BUYING                 )   AS CASHB            , -- �����춧
               CONVERT(DECIMAL(19,5), A.CASH_SELLING                )   AS CASHS            , -- �����ȶ�
               CONVERT(DECIMAL(19,5), A.USD_CVTRATE_N7              )   AS USAExrate        , -- ���ȯ��
               ISNULL(CONVERT(DECIMAL(19,5), A.COMMISSION_RATE), 0  )   AS ChangeRate       , -- ȯ������
               1                                                        AS LastUserSeq      , -- �����۾���
               GETDATE()                                                AS LastDateTime       -- �����۾��Ͻ�
          FROM HIST_INITQUOT_EXCHRATE AS A JOIN _TDACurr AS B WITH(NOLOCK)
                                      ON B.CompanySeq    = @CompanySeq
                                     AND B.CurrName      = LEFT(A.CUR_NM_C8, 3)
         WHERE A.STD_DD                 = @ExRateDate
           AND ISNULL(A.ERP_SENDYN, '') <> 'Y'
    
    UPDATE A
       SET ERP_SENDYN = 'Y'
      FROM HIST_INITQUOT_EXCHRATE AS A
     WHERE STD_DD = @ExRateDate

RETURN

GO
begin tran
exec hye_SAAExRateAutoInsertCommon 1 
rollback 
