  
IF OBJECT_ID('KPX_SPUCustomerRatingListQuery') IS NOT NULL   
    DROP PROC KPX_SPUCustomerRatingListQuery  
GO  
  
-- v2014.12.16  
  
-- �ܺξ�ü���׸���ȸ-��ȸ by ����õ   
CREATE PROC KPX_SPUCustomerRatingListQuery  
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
            @DateFr     NCHAR(8), 
            @DateTo     NCHAR(8), 
            @CustName   NVARCHAR(100), 
      
            @DateFr2     NCHAR(8), -- ����
            @DateTo2     NCHAR(8) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @DateFr = ISNULL( DateFr, '' ),  
           @DateTo = ISNULL( DateTo, '' ), 
           @CustName = ISNULL( CustName, '' ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            DateFr     NCHAR(8), 
            DateTo     NCHAR(8), 
            CustName   NVARCHAR(100) 
           )    
    
    IF @DateTo = '' SELECT @DateTo = '99991231'
    
    
    SELECT @DateFr2 = (SELECT CONVERT(NCHAR(8),DATEADD(YEAR, -1, @DateFr),112)) 
    SELECT @DateTo2 = (SELECT CONVERT(NCHAR(8),DATEADD(YEAR, -1, @DateTo),112))
    
    CREATE TABLE #BaseData
    (
        CustSeq     INT, 
        CustName    NVARCHAR(100), 
        Amt         DECIMAL(19,5), 
        Kind        INT
    )
    INSERT INTO #BaseData ( CustSeq, CustName, Amt, Kind ) 
    SELECT A.CustSeq, 
           C.CustName, 
           SUM(B.CurAmt), 
           1 -- ���� �⵵ 
      FROM _TPUDelv                 AS A 
      LEFT OUTER JOIN _TPUDelvItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
      LEFT OUTER JOIN _TDACust      AS C ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq ) 
    
     WHERE A.CompanySeq = @CompanySeq 
       AND (@CustName = '' OR C.CustName LIKE @CustName + '%') 
       AND A.DelvDate BETWEEN @DateFr AND @DateTo 
     GROUP BY A.CustSeq, C.CustName
    
    INSERT INTO #BaseData ( CustSeq, CustName, Amt, Kind ) 
    SELECT A.CustSeq, 
           C.CustName, 
           SUM(B.CurAmt), 
           2 -- �� �⵵
      FROM _TPUDelv                 AS A 
      LEFT OUTER JOIN _TPUDelvItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
      LEFT OUTER JOIN _TDACust      AS C ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (@CustName = '' OR C.CustName LIKE @CustName + '%') 
       AND A.DelvDate BETWEEN @DateFr2 AND @DateTo2 
     GROUP BY A.CustSeq, C.CustName
     
    
    CREATE TABLE #TEMP 
    (
        CustSeq     INT, 
        CustName    NVARCHAR(100), 
        Amt         DECIMAL(19,5), 
        Kind        INT, 
        Name        NVARCHAR(100), 
        Seq         INT 
    ) 
    INSERT INTO #TEMP
    SELECT A.CustSeq, A.CustName, A.Amt, A.Kind, B.Name, B.Seq 
      FROM #BaseData AS A 
      JOIN (SELECT '���űݾ�' AS Name, 1 AS Seq 
            UNION ALL 
            SELECT '���ž�������', 2 
            UNION ALL 
            SELECT '���ų����ؼ���', 3
            UNION ALL 
            SELECT '���ų�ǰ�����ϼ�', 4 
            UNION ALL 
            SELECT '���԰˻�ҷ���', 5 
           ) AS B ON ( 1 = 1 ) 
     ORDER BY A.Kind, A.CustSeq, B.Seq 
    
    
    SELECT A.CustName, 
           A.CustSeq, 
           A.Name AS TestList, 
           CASE WHEN A.Seq = 1 THEN '���űݾ�(����:�鸸��)' 
                WHEN A.Seq = 2 THEN '{(���ž�-���ⱸ�ž�)/���ⱸ�ž�}*100'
                WHEN A.Seq = 3 THEN '{(���ְǼ�-�԰��Ϲ��ؼ�)/���ְǼ�}*100'
                WHEN A.Seq = 4 THEN '��ǰ�����ϼ�'
                WHEN A.Seq = 5 THEN '�ҷ�Ƚ��/��ǰȽ�� *100'
                ELSE '' END AS TestCal, 
           CASE WHEN A.Seq = 1 THEN A.Amt 
                WHEN A.Seq = 2 THEN (CASE WHEN ISNULL(B.Amt2,0) = 0 THEN 0 ELSE ((ISNULL(A.Amt,0) - ISNULL(B.Amt2,0)) / B.Amt2) * 100 END) 
                WHEN A.Seq = 3 THEN 0
                WHEN A.Seq = 4 THEN 0
                WHEN A.Seq = 5 THEN 0 
                ELSE '' END AS TestData 
      FROM #TEMP AS A 
      OUTER APPLY ( SELECT Amt AS Amt2
                      FROM #TEMP AS Z 
                     WHERE Z.CustSeq = A.CustSeq 
                       AND Z.Seq = A.Seq 
                       AND Z.Kind = 2
                  ) AS B 
     WHERE A.Kind = 1 

    
    
    RETURN  
GO 
exec KPX_SPUCustomerRatingListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <DateFr>20141001</DateFr>
    <DateTo>20141216</DateTo>
    <CustName>(��)���ֿ�</CustName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026842,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022455