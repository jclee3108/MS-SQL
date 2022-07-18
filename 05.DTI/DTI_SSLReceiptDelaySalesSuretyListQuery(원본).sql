IF OBJECT_ID('DTI_SSLReceiptDelaySalesSuretyListQuery') IS NOT NULL   
    DROP PROC DTI_SSLReceiptDelaySalesSuretyListQuery  
GO  
/************************************************************      
 ��  �� - ������-��üä�Ǵ㺸��ȸ_DTI : ��ȸ
 �ۼ��� - 2010-06-23 : CREATEd by
 �ۼ��� - ������
 ************************************************************/      
 CREATE PROC dbo.DTI_SSLReceiptDelaySalesSuretyListQuery
     @xmlDocument    NVARCHAR(MAX) ,
     @xmlFlags       INT  = 0,
     @ServiceSeq     INT  = 0,
     @WorkingTag     NVARCHAR(10)= '',
     @CompanySeq     INT  = 1,
     @LanguageSeq    INT  = 1,
     @UserSeq        INT  = 0,
     @PgmSeq         INT  = 0
  AS
      DECLARE @docHandle      INT,
             @CustSeq        INT,            -- �ŷ�ó
             @OrderSeq       INT,
             @BillSeq        INT
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
      SELECT  @CustSeq        = ISNULL(CustSeq, 0),
             @OrderSeq       = ISNULL(OrderSeq, 0),
             @BillSeq        = ISNULL(BillSeq, 0)
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)      
     WITH ( 
             CustSeq        INT,     -- �ŷ�ó
             OrderSeq       INT,     -- �����ڵ�
             BillSeq        INT      -- ���ݰ�꼭�ڵ�
         )
  
     SELECT
         A.*,
         (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SuretyDetail) AS SuretyDetailName
     FROM
     (
         SELECT
             A.CustSeq           AS CustSeq,         -- �ŷ�ó�ڵ�
             A.SMMortageKind     AS SMMortageKind,   -- �㺸����
             A.SDate             AS SDate,           -- �㺸������
             A.EDate             AS EDate,           -- �㺸������
             A.CurrSeq           AS CurrSeq,         -- ��ȭ
             A.SpecCreditAmt     AS SuretyAmt,       -- �㺸�ݾ�
             (SELECT CurrName FROM _TDACurr WHERE CompanySeq = @CompanySeq AND CurrSeq = A.CurrSeq) AS CurrName, -- ��ȭ
             (CASE A.SMMortageKind WHEN '8501001' THEN D.UMSecuritiesKind WHEN '8501002' THEN E.UMRealtyKind ELSE F.UMCashEQKind END) AS SuretyDetail,--�㺸��
             (CASE A.SMMortageKind WHEN '8501001' THEN '��������' WHEN '8501002' THEN '�ε���' ELSE '���ݵ��' END) AS SMMortageKindName   -- �㺸���и�
         FROM _TSLCustSpecCredit AS A WITH (NOLOCK)  
             LEFT OUTER JOIN _TSLSecurities AS D WITH (NOLOCK) ON D.CompanySeq = @CompanySeq             -- ��������
                                                              AND D.CustSeq = A.CustSeq 
                                                              AND D.SpecCreditSerl = A.SpecCreditSerl
             LEFT OUTER JOIN _TSLRealEstate AS E WITH (NOLOCK) ON E.CompanySeq = @CompanySeq             -- �ε���
                                                              AND E.CustSeq = A.CustSeq 
                                                              AND E.SpecCreditSerl = A.SpecCreditSerl
             LEFT OUTER JOIN _TSLCashEquivalent AS F WITH (NOLOCK) ON F.CompanySeq = @CompanySeq         -- ���ݵ��
                                                                  AND F.CustSeq = A.CustSeq 
                                                                  AND F.SpecCreditSerl = A.SpecCreditSerl
         WHERE A.CompanySeq = @CompanySeq    
           AND (@CustSeq <> 0 OR @BillSeq <> 0 OR @OrderSeq <> 0)
           AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)
           AND (@BillSeq = 0 OR A.CustSeq IN (SELECT CustSeq FROM _TSLBill WHERE CompanySeq = @CompanySeq AND BillSeq = @BillSeq))
           AND (@OrderSeq = 0 OR A.CustSeq IN (SELECT CustSeq FROM _TSLOrder WHERE CompanySeq = @CompanySeq AND OrderSeq = @OrderSeq))
     ) AS A
     ORDER BY A.SMMortageKind
          
     
  RETURN