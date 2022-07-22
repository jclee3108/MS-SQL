 
IF OBJECT_ID('hencom_SHRGHRMPayIFListQuery') IS NOT NULL   
    DROP PROC hencom_SHRGHRMPayIFListQuery  
GO  

-- v2018.04.05
  
-- GHRM�޿���Ȳ-��ȸ by ����õ
CREATE PROC hencom_SHRGHRMPayIFListQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @docHandle  INT,  
            -- ��ȸ����   
            @StdYM      NCHAR(6)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYM   = ISNULL( StdYM, '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (StdYM   NCHAR(6))    

    SELECT  C.EmpName as AAA -- ���
    ,       C.EmpSeq as BBB -- ����ڵ�
    ,       A.EMP_NO AS CCC -- ���
    ,       '' AS DDD -- �⺻����
    ,       '' AS EEE -- �⺻�ϱ�
    ,       '' AS FFF -- �⺻�ñ�
    ,       '' AS GGG -- ����ӱ�
    ,       '' AS HHH -- ����ϱ�
    ,       '' AS III -- ���ñ�
    ,       '' AS JJJ -- �����Ѿ�
    ,       '' AS KKK -- �ұ������Ѿ�����
    ,       '' AS LLL -- �������Ѿ�
    ,       '' AS MMM -- �ұޱ������Ѿ�����
    ,       '' AS NNN -- �������Ѿ�
    ,       '' AS OOO -- �ұ��������Ѿ�����
    ,       '' AS PPP -- �����Ѿ�
    ,       '' AS QQQ -- �ұް����Ѿ�����
    ,       '' AS RRR -- �����޾�
    ,       '' AS SSS -- �ұ޽����޾�����
    ,       '' AS TTT -- ���ټ�
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'Y02' THEN A.ITEM_AMT ELSE 0 END)) AS AAAA -- �ǰ�����
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'Y03' THEN A.ITEM_AMT ELSE 0 END)) AS BBBB -- ��뺸��
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'Y01' THEN A.ITEM_AMT ELSE 0 END)) AS CCCC -- ���ο���
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'T01' THEN A.ITEM_AMT ELSE 0 END)) AS DDDD -- ��Ÿ����
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'W03' THEN A.ITEM_AMT ELSE 0 END)) AS EEEE -- ����ݻ�ȯ
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'W04' THEN A.ITEM_AMT ELSE 0 END)) AS FFFF -- ���������
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'V01' THEN A.ITEM_AMT ELSE 0 END)) AS GGGG -- ��ȣȸ��
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'W01' THEN A.ITEM_AMT ELSE 0 END)) AS HHHH -- ����ȸ��
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'T02' THEN A.ITEM_AMT ELSE 0 END)) AS IIII -- ���غ������
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'Z01' THEN A.ITEM_AMT ELSE 0 END)) AS JJJJ -- �ҵ漼
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'T05' THEN A.ITEM_AMT ELSE 0 END)) AS KKKK -- �ſ���������
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'Z04' THEN A.ITEM_AMT ELSE 0 END)) AS LLLL -- �������ټ�
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'Z06' THEN A.ITEM_AMT ELSE 0 END)) AS MMMM -- ������Ư��
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'Z05' THEN A.ITEM_AMT ELSE 0 END)) AS NNNN -- �����ֹμ�
    ,       '' AS OOOO -- �����Ư��
    ,       '' AS PPPP -- ����ҵ漼
    ,       '' AS QQQQ -- ��������ҵ漼
    ,       '' AS RRRR -- �ֹμ�
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'Z02' THEN A.ITEM_AMT ELSE 0 END)) AS AAAAA -- ����ҵ漼
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'T03' THEN A.ITEM_AMT ELSE 0 END)) AS BBBBB -- ȸ������
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'G05' THEN A.ITEM_AMT ELSE 0 END)) AS CCCCC -- �ͼ�����
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A09' THEN A.ITEM_AMT ELSE 0 END)) AS DDDDD -- �ټӼ���
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A01' THEN A.ITEM_AMT ELSE 0 END)) AS EEEEE -- �⺻��
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A14' THEN A.ITEM_AMT ELSE 0 END)) AS FFFFF -- �������
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'H01' THEN A.ITEM_AMT ELSE 0 END)) AS GGGGG -- ��Ÿ����
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A13' THEN A.ITEM_AMT ELSE 0 END)) AS HHHHH -- �󿩱�
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'H02' THEN A.ITEM_AMT ELSE 0 END)) AS IIIII -- ���غ����
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'H06' THEN A.ITEM_AMT ELSE 0 END)) AS JJJJJ -- �ұ޺�
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A15' THEN A.ITEM_AMT ELSE 0 END)) AS KKKKK -- �Ĵ�
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A06' THEN A.ITEM_AMT ELSE 0 END)) AS LLLLL -- �߰��ٹ�����
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A02' THEN A.ITEM_AMT ELSE 0 END)) AS MMMMM -- ����ٷμ���
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'E01' THEN A.ITEM_AMT ELSE 0 END)) AS NNNNN -- ��������
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'H04' THEN A.ITEM_AMT ELSE 0 END)) AS OOOOO -- �ڰݼ���
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'H03' THEN A.ITEM_AMT ELSE 0 END)) AS PPPPP -- ��������
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A08' THEN A.ITEM_AMT ELSE 0 END)) AS QQQQQ -- ���ޱٹ�����
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A04' THEN A.ITEM_AMT ELSE 0 END)) AS RRRRR -- ���ޱ⺻����
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A10' THEN A.ITEM_AMT ELSE 0 END)) AS SSSSS -- ��������
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'G06' THEN A.ITEM_AMT ELSE 0 END)) AS TTTTT -- ��������
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A03' THEN A.ITEM_AMT ELSE 0 END)) AS UUUUU-- ��å����
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'B02' THEN A.ITEM_AMT ELSE 0 END)) AS VVVVV-- ����������
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'G01' THEN A.ITEM_AMT ELSE 0 END)) AS XXXXX-- ���ں�����
    ,       SUM((CASE WHEN A.ATTRIBUTE1 = '�ް���' THEN A.ITEM_AMT ELSE 0 END)) AS YYYYY -- �ް���
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'G04' THEN A.ITEM_AMT ELSE 0 END)) AS ZZZZZ -- ���ϱ����
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A07' THEN A.ITEM_AMT ELSE 0 END)) AS AAAAAA -- ���ϱٹ�����
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A05' THEN A.ITEM_AMT ELSE 0 END)) AS BBBBBB -- ���ϱ⺻����
      FROM   [GHRM]..[HGHR].[ENCOM_PAY_ITEM] AS A
      JOIN [GHRM]..[HGHR].[ENCOM_PAY_WORK] AS B ON A.CALC_SEQ = B.CALC_SEQ AND B.CALC_YY = LEFT(@StdYM,4) AND B.CALC_MM = RIGHT(@StdYM,2)
      LEFT OUTER JOIN (
                        SELECT DISTINCT Z.EmpID, Z.EmpName, Z.EmpSeq
                          FROM _fnAdmEmpOrd(@CompanySeq, '') AS Z 
                      ) AS C ON ( C.EmpID = A.EMP_NO ) 
     GROUP BY C.EmpName, C.EmpSeq, A.EMP_NO
     ORDER BY CCC
    RETURN  
go
begin tran 
EXEC hencom_SHRGHRMPayIFListQuery @xmlDocument = N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <StdYM>201707</StdYM>
  </DataBlock1>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 2000030, @WorkingTag = N'', @CompanySeq = 1, @LanguageSeq = 1, @UserSeq = 1, @PgmSeq = 2000034
rollback 
