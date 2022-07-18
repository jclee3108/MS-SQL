  
IF OBJECT_ID('KPX_SEISDateProgListQuery') IS NOT NULL   
    DROP PROC KPX_SEISDateProgListQuery  
GO  
    
-- v2015.03.18  
    
-- �Ⱓ��ó����Ȳ-��ȸ by ����õ   
CREATE PROC KPX_SEISDateProgListQuery  
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
            @DateTo     NCHAR(8)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @DateFr  = ISNULL( DateFr, '' ),  
           @DateTo  = ISNULL( DateTo, '' )  
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            DateFr  NCHAR(8), 
            DateTo  NCHAR(8) 
           )    
    
    CREATE TABLE #Result 
    (
        ModuleName   NVARCHAR(100), 
        Caption     NVARCHAR(100), 
        AllData     INT, 
        Prog        INT, 
        NotProg     INT, 
        DeptSeq     INT, 
        EmpSeq      INT, 
        SaveCnt     INT,  
        Sort        INT 
    ) 
    
    CREATE TABLE #Result_Sub
    (
        ModuleName   NVARCHAR(100), 
        Caption     NVARCHAR(100), 
        AllData     INT, 
        Prog        INT, 
        NotProg     INT, 
        DeptSeq     INT, 
        EmpSeq      INT, 
        SaveCnt     INT,  
        Sort        INT 
    ) 
    
    ----------------------------------------------------------------------------------------------------------------------------------------------
    -- ����
    ----------------------------------------------------------------------------------------------------------------------------------------------
    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort ) -- ���� 
    SELECT '����' AS ModuleName, 
           '�����Է�' AS Caption, 
           0 AS AllData, 
           COUNT(1) AS Prog, 
           0, 
           E.DeptSeq, 
           D.EmpSeq, 
           COUNT(1) AS SaveCnt, 
           1
      FROM _TSLOrder AS A 
      LEFT OUTER JOIN _TSLOrderItem AS B ON ( B.CompanySeq = @CompanySeq AND B.OrderSeq = A.OrderSeq ) 
      JOIN _TDASMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMExpKind AND C.Serl = 1001 AND C.ValueText = '1' ) 
      LEFT OUTER JOIN _TCAUser AS D ON ( D.CompanySeq = @CompanySeq AND D.UserSeq = B.LastUserSeq ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS E ON ( E.EmpSeq = D.EmpSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.OrderDate BETWEEN @DateFr AND @DateTo  
       AND A.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
     GROUP BY E.DeptSeq, D.EmpSeq 
     ORDER BY E.DeptSeq, D.EmpSeq 
    
    
    CREATE TABLE #TSLOrderItem 
    (
        IDX_NO      INT IDENTITY, 
        Seq         INT, 
        Serl        INT 
    )
    
    INSERT INTO #TSLOrderItem ( Seq, Serl ) 
    SELECT A.OrderSeq, B.OrderSerl
      FROM _TSLOrder        AS A 
      JOIN _TSLOrderItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.OrderSeq = A.OrderSeq ) 
      JOIN _TDASMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMExpKind AND C.Serl = 1001 AND C.ValueText = '1' ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.DVDate BETWEEN @DateFr AND @DateTo  
       AND A.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
    
    
    INSERT INTO #Result_Sub ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- ��������Է� 
    SELECT '����' AS ModuleName, 
           '��������Է�' AS Caption, 
           COUNT(1) AS AllData, 
           ISNULL(MAX(C.Cnt),0) AS Prog, 
           CASE WHEN COUNT(1) - ISNULL(MAX(C.Cnt),0) < 0 THEN 0 ELSE COUNT(1) - ISNULL(MAX(C.Cnt),0) END AS NotProg, 
           ISNULL(C.DeptSeq,0) AS DeptSeq, 
           ISNULL(C.EmpSeq,0) AS EmpSeq, 
           ISNULL(MAX(C.Cnt),0) AS SaveCnt, 
           2 AS Sort 
      FROM #TSLOrderItem AS A 
      OUTER APPLY ( 
                    SELECT COUNT(1) AS Cnt, O.EmpSeq, O.DeptSeq 
                      FROM _TSLDVReq AS Z 
                      JOIN _TSLDVReqItem AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.DVReqSeq = Z.DVReqSeq ) 
                      JOIN _TDASMinorValue AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = Z.SMExpKind AND Q.Serl = 1001 AND Q.ValueText = '1' ) 
                      LEFT OUTER JOIN _TCAUser AS P ON ( P.CompanySeq = @CompanySeq AND P.UserSeq = Y.LastUserSeq ) 
                      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS O ON ( O.EmpSeq = P.EmpSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.DVReqDate BETWEEN @DateFr AND @DateTo  
                       AND Z.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
                     GROUP BY O.DeptSeq, O.EmpSeq 
                  )  AS C 
     GROUP BY C.DeptSeq, C.EmpSeq 
     ORDER BY C.DeptSeq, C.EmpSeq 
    
    --select * From #Result_Sub 
    --return 

    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- ��������Է� 
    SELECT A.ModuleName, 
           A.Caption, 
           A.AllData, 
           A.Prog, 
           CASE WHEN A.AllData - MAX(B.Prog) < 0 THEN 0 ELSE A.AllData - MAX(B.Prog) END AS NotProg, 
           A.DeptSeq, 
           A.EmpSeq, 
           A.SaveCnt, 
           A.Sort
      FROM #Result_Sub AS A 
      OUTER APPLY (SELECT SUM(Prog) AS Prog
                     FROM #Result_Sub 
                  ) AS B 
     GROUP BY A.ModuleName, A.Caption, A.AllData, A.Prog, 
              A.DeptSeq, A.EmpSeq, A.SaveCnt, A.Sort 
     ORDER BY A.DeptSeq, A.EmpSeq               
     
     --select * From #Result order by Sort, DeptSeq, EmpSeq 
    --return 
    
    
    CREATE TABLE #TSLDVReqItem 
    (
        IDX_NO      INT IDENTITY, 
        Seq         INT, 
        Serl        INT 
    )
    
    INSERT INTO #TSLDVReqItem ( Seq, Serl ) 
    SELECT A.DVReqSeq, B.DVReqSerl
      FROM _TSLDVReq AS A 
      JOIN _TSLDVReqItem AS B ON ( B.CompanySeq = @CompanySeq AND B.DVReqSeq = A.DVReqSeq ) 
      JOIN _TDASMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMExpKind AND C.Serl = 1001 AND C.ValueText = '1' ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.DVDate BETWEEN @DateFr AND @DateTo 
       AND A.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
    
    TRUNCATE TABLE #Result_Sub
    
    INSERT INTO #Result_Sub ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- �ŷ������Է� 
    SELECT '����' AS ModuleName, 
           '�ŷ������Է�' AS Caption, 
           COUNT(1) AS AllData, 
           ISNULL(MAX(C.Cnt),0) AS Prog, 
           CASE WHEN COUNT(1) - ISNULL(MAX(C.Cnt),0) < 0 THEN 0 ELSE COUNT(1) - ISNULL(MAX(C.Cnt),0) END AS NotProg, 
           ISNULL(C.DeptSeq,0) AS DeptSeq, 
           ISNULL(C.EmpSeq,0) AS EmpSeq, 
           ISNULL(MAX(C.Cnt),0) AS SaveCnt, 
           3 AS Sort 
      FROM #TSLDVReqItem AS A 
      OUTER APPLY ( 
                    SELECT COUNT(1) AS Cnt, O.EmpSeq, O.DeptSeq 
                      FROM _TSLInvoice AS Z 
                      JOIN _TSLInvoiceItem AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.InvoiceSeq = Z.InvoiceSeq ) 
                      JOIN _TDASMinorValue AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = Z.SMExpKind AND Q.Serl = 1001 AND Q.ValueText = '1' ) 
                      LEFT OUTER JOIN _TCAUser AS P ON ( P.CompanySeq = @CompanySeq AND P.UserSeq = Y.LastUserSeq ) 
                      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS O ON ( O.EmpSeq = P.EmpSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.InvoiceDate BETWEEN @DateFr AND @DateTo  
                       AND Z.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
                     GROUP BY O.DeptSeq, O.EmpSeq 
                  )  AS C 
     GROUP BY C.DeptSeq, C.EmpSeq 
     ORDER BY C.DeptSeq, C.EmpSeq 
    

    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- �ŷ������Է�  
    SELECT A.ModuleName, 
           A.Caption, 
           A.AllData, 
           A.Prog, 
           CASE WHEN A.AllData - MAX(B.Prog) < 0 THEN 0 ELSE A.AllData - MAX(B.Prog) END AS NotProg, 
           A.DeptSeq, 
           A.EmpSeq, 
           A.SaveCnt, 
           A.Sort
      FROM #Result_Sub AS A 
      OUTER APPLY (SELECT SUM(Prog) AS Prog
                     FROM #Result_Sub 
                  ) AS B 
     GROUP BY A.ModuleName, A.Caption, A.AllData, A.Prog, 
              A.DeptSeq, A.EmpSeq, A.SaveCnt, A.Sort 
    
    --select *from #Result 
    
    --return 
    
    CREATE TABLE #TSLInvoiceItem
    (
        IDX_NO      INT IDENTITY, 
        Seq         INT, 
        Serl        INT 
    )
    
    INSERT INTO #TSLInvoiceItem ( Seq, Serl ) 
    SELECT A.InvoiceSeq, B.InvoiceSerl
      FROM _TSLInvoice AS A 
      JOIN _TSLInvoiceItem AS B ON ( B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.InvoiceSeq ) 
      JOIN _TDASMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMExpKind AND C.Serl = 1001 AND C.ValueText = '1' ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.InvoiceDate BETWEEN @DateFr AND @DateTo 
       AND A.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
    
    TRUNCATE TABLE #Result_Sub
    
    INSERT INTO #Result_Sub ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- ���ݰ�꼭�Է� 
    SELECT '����' AS ModuleName, 
           '���ݰ�꼭�Է�' AS Caption, 
           COUNT(1) AS AllData, 
           ISNULL(MAX(C.Cnt),0) AS Prog, 
           CASE WHEN COUNT(1) - ISNULL(MAX(C.Cnt),0) < 0 THEN 0 ELSE COUNT(1) - ISNULL(MAX(C.Cnt),0) END AS NotProg, 
           ISNULL(C.DeptSeq,0) AS DeptSeq, 
           ISNULL(C.EmpSeq,0) AS EmpSeq, 
           ISNULL(MAX(C.Cnt),0) AS SaveCnt, 
           4 AS Sort 
      FROM #TSLInvoiceItem AS A 
      OUTER APPLY ( 
                    SELECT COUNT(1) AS Cnt, O.EmpSeq, O.DeptSeq 
                      FROM _TSLSales AS Z 
                      JOIN _TSLSalesItem AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.SalesSeq = Z.SalesSeq ) 
                      JOIN _TDASMinorValue AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = Z.SMExpKind AND Q.Serl = 1001 AND Q.ValueText = '1' ) 
                      LEFT OUTER JOIN _TCAUser AS P ON ( P.CompanySeq = @CompanySeq AND P.UserSeq = Y.LastUserSeq ) 
                      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS O ON ( O.EmpSeq = P.EmpSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.SalesDate BETWEEN @DateFr AND @DateTo  
                       AND Z.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
                     GROUP BY O.DeptSeq, O.EmpSeq 
                  )  AS C 
     GROUP BY C.DeptSeq, C.EmpSeq 
     ORDER BY C.DeptSeq, C.EmpSeq 
    

    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- ���ݰ�꼭�Է� 
    SELECT A.ModuleName, 
           A.Caption, 
           A.AllData, 
           A.Prog, 
           CASE WHEN A.AllData - MAX(B.Prog) < 0 THEN 0 ELSE A.AllData - MAX(B.Prog) END AS NotProg, 
           A.DeptSeq, 
           A.EmpSeq, 
           A.SaveCnt, 
           A.Sort
      FROM #Result_Sub AS A 
      OUTER APPLY (SELECT SUM(Prog) AS Prog
                     FROM #Result_Sub 
                  ) AS B 
     GROUP BY A.ModuleName, A.Caption, A.AllData, A.Prog, 
              A.DeptSeq, A.EmpSeq, A.SaveCnt, A.Sort 
    
    
    -- ���� 

    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort ) -- ����Order�Է� 
    SELECT '����' AS ModuleName, 
           '����Order�Է�' AS Caption, 
           0 AS AllData, 
           COUNT(1) AS Prog, 
           0, 
           E.DeptSeq, 
           E.EmpSeq, 
           COUNT(1) AS SaveCnt, 
           5
      FROM _TSLOrder AS A 
      LEFT OUTER JOIN _TSLOrderItem AS B ON ( B.CompanySeq = @CompanySeq AND B.OrderSeq = A.OrderSeq ) 
      JOIN _TDASMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMExpKind AND C.Serl = 1002 AND C.ValueText = '1' ) 
      LEFT OUTER JOIN _TCAUser AS D ON ( D.CompanySeq = @CompanySeq AND D.UserSeq = B.LastUserSeq ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS E ON ( E.EmpSeq = D.EmpSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.OrderDate BETWEEN @DateFr AND @DateTo  
       AND A.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
     GROUP BY E.DeptSeq, E.EmpSeq 
     ORDER BY E.DeptSeq, E.EmpSeq 
    
    TRUNCATE TABLE #TSLOrderItem
    
    INSERT INTO #TSLOrderItem ( Seq, Serl ) 
    SELECT A.OrderSeq, B.OrderSerl
      FROM _TSLOrder        AS A 
      JOIN _TSLOrderItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.OrderSeq = A.OrderSeq ) 
      JOIN _TDASMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMExpKind AND C.Serl = 1002 AND C.ValueText = '1' ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.DVDate BETWEEN @DateFr AND @DateTo  
       AND A.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
    
    TRUNCATE TABLE #Result_Sub
    INSERT INTO #Result_Sub ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- ������������Է� 
    SELECT '����' AS ModuleName, 
           '������������Է�' AS Caption, 
           COUNT(1) AS AllData, 
           ISNULL(MAX(C.Cnt),0) AS Prog, 
           CASE WHEN COUNT(1) - ISNULL(MAX(C.Cnt),0) < 0 THEN 0 ELSE COUNT(1) - ISNULL(MAX(C.Cnt),0) END AS NotProg, 
           ISNULL(C.DeptSeq,0) AS DeptSeq, 
           ISNULL(C.EmpSeq,0) AS EmpSeq, 
           ISNULL(MAX(C.Cnt),0) AS SaveCnt, 
           6 AS Sort 
      FROM #TSLOrderItem AS A 
      OUTER APPLY ( 
                    SELECT COUNT(1) AS Cnt, O.EmpSeq, O.DeptSeq 
                      FROM _TSLDVReq AS Z 
                      JOIN _TSLDVReqItem AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.DVReqSeq = Z.DVReqSeq ) 
                      JOIN _TDASMinorValue AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = Z.SMExpKind AND Q.Serl = 1002 AND Q.ValueText = '1' ) 
                      LEFT OUTER JOIN _TCAUser AS P ON ( P.CompanySeq = @CompanySeq AND P.UserSeq = Y.LastUserSeq ) 
                      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS O ON ( O.EmpSeq = P.EmpSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.DVReqDate BETWEEN @DateFr AND @DateTo  
                       AND Z.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
                     GROUP BY O.EmpSeq, O.DeptSeq 
                  )  AS C 
     GROUP BY C.DeptSeq, C.EmpSeq 
     ORDER BY C.DeptSeq, C.EmpSeq 
    
    --select * From #Result_Sub 
    --return 
    
    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- ������������Է� 
    SELECT A.ModuleName, 
           A.Caption, 
           A.AllData, 
           A.Prog, 
           CASE WHEN A.AllData - MAX(B.Prog) < 0 THEN 0 ELSE A.AllData - MAX(B.Prog) END AS NotProg, 
           A.DeptSeq, 
           A.EmpSeq, 
           A.SaveCnt, 
           A.Sort
      FROM #Result_Sub AS A 
      OUTER APPLY (SELECT SUM(Prog) AS Prog
                     FROM #Result_Sub 
                  ) AS B 
     GROUP BY A.ModuleName, A.Caption, A.AllData, A.Prog, 
              A.DeptSeq, A.EmpSeq, A.SaveCnt, A.Sort 
     ORDER BY A.DeptSeq, A.EmpSeq               
     
     --select * From #Result order by Sort, DeptSeq, EmpSeq 
    --return 
    
    
    TRUNCATE TABLE #TSLDVReqItem
    INSERT INTO #TSLDVReqItem ( Seq, Serl ) 
    SELECT A.DVReqSeq, B.DVReqSerl
      FROM _TSLDVReq AS A 
      JOIN _TSLDVReqItem AS B ON ( B.CompanySeq = @CompanySeq AND B.DVReqSeq = A.DVReqSeq ) 
      JOIN _TDASMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMExpKind AND C.Serl = 1002 AND C.ValueText = '1' ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.DVDate BETWEEN @DateFr AND @DateTo 
       AND A.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
    
    TRUNCATE TABLE #Result_Sub
    
    INSERT INTO #Result_Sub ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- ����ŷ������Է� 
    SELECT '����' AS ModuleName, 
           '����ŷ������Է�' AS Caption, 
           COUNT(1) AS AllData, 
           ISNULL(MAX(C.Cnt),0) AS Prog, 
           CASE WHEN COUNT(1) - ISNULL(MAX(C.Cnt),0) < 0 THEN 0 ELSE COUNT(1) - ISNULL(MAX(C.Cnt),0) END AS NotProg, 
           ISNULL(C.DeptSeq,0) AS DeptSeq, 
           ISNULL(C.EmpSeq,0) AS EmpSeq, 
           ISNULL(MAX(C.Cnt),0) AS SaveCnt, 
           7 AS Sort 
      FROM #TSLDVReqItem AS A 
      OUTER APPLY ( 
                    SELECT COUNT(1) AS Cnt, O.EmpSeq, O.DeptSeq 
                      FROM _TSLInvoice AS Z 
                      JOIN _TSLInvoiceItem AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.InvoiceSeq = Z.InvoiceSeq ) 
                      JOIN _TDASMinorValue AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = Z.SMExpKind AND Q.Serl = 1002 AND Q.ValueText = '1' ) 
                      LEFT OUTER JOIN _TCAUser AS P ON ( P.CompanySeq = @CompanySeq AND P.UserSeq = Y.LastUserSeq ) 
                      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS O ON ( O.EmpSeq = P.EmpSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.InvoiceDate BETWEEN @DateFr AND @DateTo  
                       AND Z.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
                     GROUP BY O.DeptSeq, O.EmpSeq 
                  )  AS C 
     GROUP BY C.DeptSeq, C.EmpSeq 
     ORDER BY C.DeptSeq, C.EmpSeq 
    

    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- ����ŷ������Է�  
    SELECT A.ModuleName, 
           A.Caption, 
           A.AllData, 
           A.Prog, 
           CASE WHEN A.AllData - MAX(B.Prog) < 0 THEN 0 ELSE A.AllData - MAX(B.Prog) END AS NotProg, 
           A.DeptSeq, 
           A.EmpSeq, 
           A.SaveCnt, 
           A.Sort
      FROM #Result_Sub AS A 
      OUTER APPLY (SELECT SUM(Prog) AS Prog
                     FROM #Result_Sub 
                  ) AS B 
     GROUP BY A.ModuleName, A.Caption, A.AllData, A.Prog, 
              A.DeptSeq, A.EmpSeq, A.SaveCnt, A.Sort 
    
    --select *from #Result 
    
    --return 
    
    TRUNCATE TABLE #TSLInvoiceItem 
    
    INSERT INTO #TSLInvoiceItem ( Seq, Serl ) 
    SELECT A.InvoiceSeq, B.InvoiceSerl
      FROM _TSLInvoice AS A 
      JOIN _TSLInvoiceItem AS B ON ( B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.InvoiceSeq ) 
      JOIN _TDASMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMExpKind AND C.Serl = 1002 AND C.ValueText = '1' ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.InvoiceDate BETWEEN @DateFr AND @DateTo 
       AND A.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
    
    TRUNCATE TABLE #Result_Sub
    
    INSERT INTO #Result_Sub ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- ���ݰ�꼭�Է�(����) 
    SELECT '����' AS ModuleName, 
           '���ݰ�꼭�Է�(����)' AS Caption, 
           COUNT(1) AS AllData, 
           ISNULL(MAX(C.Cnt),0) AS Prog, 
           CASE WHEN COUNT(1) - ISNULL(MAX(C.Cnt),0) < 0 THEN 0 ELSE COUNT(1) - ISNULL(MAX(C.Cnt),0) END AS NotProg, 
           ISNULL(C.DeptSeq,0) AS DeptSeq, 
           ISNULL(C.EmpSeq,0) AS EmpSeq, 
           ISNULL(MAX(C.Cnt),0) AS SaveCnt, 
           8 AS Sort 
      FROM #TSLInvoiceItem AS A 
      OUTER APPLY ( 
                    SELECT COUNT(1) AS Cnt, O.EmpSeq, O.DeptSeq 
                      FROM _TSLSales AS Z 
                      JOIN _TSLSalesItem AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.SalesSeq = Z.SalesSeq ) 
                      JOIN _TDASMinorValue AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = Z.SMExpKind AND Q.Serl = 1002 AND Q.ValueText = '1' ) 
                      LEFT OUTER JOIN _TCAUser AS P ON ( P.CompanySeq = @CompanySeq AND P.UserSeq = Y.LastUserSeq ) 
                      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS O ON ( O.EmpSeq = P.EmpSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.SalesDate BETWEEN @DateFr AND @DateTo  
                       AND Z.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
                     GROUP BY O.DeptSeq, O.EmpSeq 
                  )  AS C 
     GROUP BY C.DeptSeq, C.EmpSeq 
     ORDER BY C.DeptSeq, C.EmpSeq 
    

    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- ���ݰ�꼭�Է�(����) 
    SELECT A.ModuleName, 
           A.Caption, 
           A.AllData, 
           A.Prog, 
           CASE WHEN A.AllData - MAX(B.Prog) < 0 THEN 0 ELSE A.AllData - MAX(B.Prog) END AS NotProg, 
           A.DeptSeq, 
           A.EmpSeq, 
           A.SaveCnt, 
           A.Sort
      FROM #Result_Sub AS A 
      OUTER APPLY (SELECT SUM(Prog) AS Prog
                     FROM #Result_Sub 
                  ) AS B 
     GROUP BY A.ModuleName, A.Caption, A.AllData, A.Prog, 
              A.DeptSeq, A.EmpSeq, A.SaveCnt, A.Sort 
    ----------------------------------------------------------------------------------------------------------------------------------------------
    -- ����, END 
    ----------------------------------------------------------------------------------------------------------------------------------------------
    
    ----------------------------------------------------------------------------------------------------------------------------------------------
    -- ����
    ----------------------------------------------------------------------------------------------------------------------------------------------
    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort ) -- ���ų�ǰ 
    SELECT '����' AS ModuleName, 
           '���ų�ǰ' AS Caption, 
           0 AS AllData, 
           COUNT(1) AS Prog, 
           0, 
           O.DeptSeq, 
           O.EmpSeq, 
           COUNT(1) AS SaveCnt, 
           9
      FROM _TPUDelv AS A 
      LEFT OUTER JOIN _TPUDelvItem AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
      LEFT OUTER JOIN _TCAUser AS P ON ( P.CompanySeq = @CompanySeq AND P.UserSeq = B.LastUserSeq ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS O ON ( O.EmpSeq = P.EmpSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.DelvDate BETWEEN @DateFr AND @DateTo  
       AND A.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
     GROUP BY O.DeptSeq, O.EmpSeq 
     ORDER BY O.DeptSeq, O.EmpSeq 
    
    
    CREATE TABLE #TPUDelvItem 
    (
        IDX_NO      INT IDENTITY, 
        Seq         INT, 
        Serl        INT 
    )
    
    INSERT INTO #TPUDelvItem ( Seq, Serl ) 
    SELECT A.DelvSeq, B.DelvSerl
      FROM _TPUDelv        AS A 
      JOIN _TPUDelvItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.DelvDate BETWEEN @DateFr AND @DateTo  
       AND A.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
    
    TRUNCATE TABLE #Result_Sub 
    
    INSERT INTO #Result_Sub ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- �����԰� 
    SELECT '����' AS ModuleName, 
           '�����԰�' AS Caption, 
           COUNT(1) AS AllData, 
           ISNULL(MAX(C.Cnt),0) AS Prog, 
           CASE WHEN COUNT(1) - ISNULL(MAX(C.Cnt),0) < 0 THEN 0 ELSE COUNT(1) - ISNULL(MAX(C.Cnt),0) END AS NotProg, 
           ISNULL(C.DeptSeq,0) AS DeptSeq, 
           ISNULL(C.EmpSeq,0) AS EmpSeq, 
           ISNULL(MAX(C.Cnt),0) AS SaveCnt, 
           10 AS Sort 
      FROM #TPUDelvItem AS A 
      OUTER APPLY ( 
                    SELECT COUNT(1) AS Cnt, O.EmpSeq, O.DeptSeq 
                      FROM _TPUDelvIn AS Z 
                      JOIN _TPUDelvInItem AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.DelvInSeq = Z.DelvInSeq ) 
                      LEFT OUTER JOIN _TCAUser AS P ON ( P.CompanySeq = @CompanySeq AND P.UserSeq = Y.LastUserSeq ) 
                      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS O ON ( O.EmpSeq = P.EmpSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.DelvInDate BETWEEN @DateFr AND @DateTo  
                       AND Z.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
                     GROUP BY O.EmpSeq, O.DeptSeq  
                  )  AS C 
     GROUP BY C.DeptSeq, C.EmpSeq 
     ORDER BY C.DeptSeq, C.EmpSeq 
     
    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- �����԰�  
    SELECT A.ModuleName, 
           A.Caption, 
           A.AllData, 
           A.Prog, 
           CASE WHEN A.AllData - MAX(B.Prog) < 0 THEN 0 ELSE A.AllData - MAX(B.Prog) END AS NotProg, 
           A.DeptSeq, 
           A.EmpSeq, 
           A.SaveCnt, 
           A.Sort
      FROM #Result_Sub AS A 
      OUTER APPLY (SELECT SUM(Prog) AS Prog
                     FROM #Result_Sub 
                  ) AS B 
     GROUP BY A.ModuleName, A.Caption, A.AllData, A.Prog, 
              A.DeptSeq, A.EmpSeq, A.SaveCnt, A.Sort 
              
    
    CREATE TABLE #TPUDelvInItem
    (
        IDX_NO      INT IDENTITY, 
        Seq         INT, 
        Serl        INT 
    )
    
    INSERT INTO #TPUDelvInItem ( Seq, Serl ) 
    SELECT A.DelvInSeq, B.DelvInSerl
      FROM _TPUDelvIn        AS A 
      JOIN _TPUDelvInItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvInSeq = A.DelvInSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.DelvInDate BETWEEN @DateFr AND @DateTo  
       AND A.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
    
    TRUNCATE TABLE #Result_Sub 
    
    INSERT INTO #Result_Sub ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- �������� 
    SELECT '����' AS ModuleName, 
           '��������' AS Caption, 
           COUNT(1) AS AllData, 
           ISNULL(MAX(C.Cnt),0) AS Prog, 
           CASE WHEN COUNT(1) - ISNULL(MAX(C.Cnt),0) < 0 THEN 0 ELSE COUNT(1) - ISNULL(MAX(C.Cnt),0) END AS NotProg, 
           ISNULL(C.DeptSeq,0) AS DeptSeq, 
           ISNULL(C.EmpSeq,0) AS EmpSeq, 
           ISNULL(MAX(C.Cnt),0) AS SaveCnt, 
           11 AS Sort 
      FROM #TPUDelvInItem AS A 
      OUTER APPLY ( 
                    SELECT COUNT(1) AS Cnt, O.EmpSeq, O.DeptSeq 
                      FROM _TPUBuyingAcc AS Z 
                      LEFT OUTER JOIN _TCAUser AS P ON ( P.CompanySeq = @CompanySeq AND P.UserSeq = Z.LastUserSeq ) 
                      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS O ON ( O.EmpSeq = P.EmpSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.BuyingAccDate BETWEEN @DateFr AND @DateTo  
                       AND Z.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
                       AND ISNULL(Z.SlipSeq,0) <> 0
                     GROUP BY O.DeptSeq, O.EmpSeq 
                  )  AS C 
     GROUP BY C.DeptSeq, C.EmpSeq 
     ORDER BY C.DeptSeq, C.EmpSeq 
    
    
    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- ��������   
    SELECT A.ModuleName, 
           A.Caption, 
           A.AllData, 
           A.Prog, 
           CASE WHEN A.AllData - MAX(B.Prog) < 0 THEN 0 ELSE A.AllData - MAX(B.Prog) END AS NotProg, 
           A.DeptSeq, 
           A.EmpSeq, 
           A.SaveCnt, 
           A.Sort
      FROM #Result_Sub AS A 
      OUTER APPLY (SELECT SUM(Prog) AS Prog
                     FROM #Result_Sub 
                  ) AS B 
     GROUP BY A.ModuleName, A.Caption, A.AllData, A.Prog, 
              A.DeptSeq, A.EmpSeq, A.SaveCnt, A.Sort 
    
    
    
    
    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort ) -- ����BL 
    SELECT '����' AS ModuleName, 
           '����BL' AS Caption, 
           0 AS AllData, 
           COUNT(1) AS Prog, 
           0, 
           O.DeptSeq, 
           O.EmpSeq, 
           COUNT(1) AS SaveCnt, 
           12
      FROM _TUIImpBL AS A 
      LEFT OUTER JOIN _TUIImpBLItem AS B ON ( B.CompanySeq = @CompanySeq AND B.BLSeq = A.BLSeq ) 
      LEFT OUTER JOIN _TCAUser AS P ON ( P.CompanySeq = @CompanySeq AND P.UserSeq = B.LastUserSeq ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS O ON ( O.EmpSeq = P.EmpSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.BLDate BETWEEN @DateFr AND @DateTo  
       AND A.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
     GROUP BY O.DeptSeq, O.EmpSeq 
     ORDER BY O.DeptSeq, O.EmpSeq 
    
    
    CREATE TABLE #TUIImpBLItem 
    (
        IDX_NO      INT IDENTITY, 
        Seq         INT, 
        Serl        INT 
    )
    
    INSERT INTO #TUIImpBLItem ( Seq, Serl ) 
    SELECT A.BLSeq, B.BLSerl
      FROM _TUIImpBL        AS A 
      JOIN _TUIImpBLItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.BLSeq = A.BLSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.BLDate BETWEEN @DateFr AND @DateTo  
       AND A.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
    
    TRUNCATE TABLE #Result_Sub 
    
    INSERT INTO #Result_Sub ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- �����԰� 
    SELECT '����' AS ModuleName, 
           '�����԰�' AS Caption, 
           COUNT(1) AS AllData, 
           ISNULL(MAX(C.Cnt),0) AS Prog, 
           CASE WHEN COUNT(1) - ISNULL(MAX(C.Cnt),0) < 0 THEN 0 ELSE COUNT(1) - ISNULL(MAX(C.Cnt),0) END AS NotProg, 
           ISNULL(C.DeptSeq,0) AS DeptSeq, 
           ISNULL(C.EmpSeq,0) AS EmpSeq, 
           ISNULL(MAX(C.Cnt),0) AS SaveCnt, 
           13 AS Sort 
      FROM #TUIImpBLItem AS A 
      OUTER APPLY ( 
                    SELECT COUNT(1) AS Cnt, O.EmpSeq, O.DeptSeq 
                      FROM _TUIImpDelv AS Z 
                      LEFT OUTER JOIN _TUIImpDelvItem AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.DelvSeq = Z.DelvSeq ) 
                      LEFT OUTER JOIN _TCAUser AS P ON ( P.CompanySeq = @CompanySeq AND P.UserSeq = Y.LastUserSeq ) 
                      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS O ON ( O.EmpSeq = P.EmpSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.DelvDate BETWEEN @DateFr AND @DateTo  
                       AND Z.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
                     GROUP BY O.DeptSeq, O.EmpSeq 
                  )  AS C 
     GROUP BY C.DeptSeq, C.EmpSeq 
     ORDER BY C.DeptSeq, C.EmpSeq 
     
    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- �����԰�  
    SELECT A.ModuleName, 
           A.Caption, 
           A.AllData, 
           A.Prog, 
           CASE WHEN A.AllData - MAX(B.Prog) < 0 THEN 0 ELSE A.AllData - MAX(B.Prog) END AS NotProg, 
           A.DeptSeq, 
           A.EmpSeq, 
           A.SaveCnt, 
           A.Sort
      FROM #Result_Sub AS A 
      OUTER APPLY (SELECT SUM(Prog) AS Prog
                     FROM #Result_Sub 
                  ) AS B 
     GROUP BY A.ModuleName, A.Caption, A.AllData, A.Prog, 
              A.DeptSeq, A.EmpSeq, A.SaveCnt, A.Sort 
    
    ----------------------------------------------------------------------------------------------------------------------------------------------
    -- ����, END 
    ----------------------------------------------------------------------------------------------------------------------------------------------
    
    ----------------------------------------------------------------------------------------------------------------------------------------------
    -- ȸ��
    ----------------------------------------------------------------------------------------------------------------------------------------------
    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- �а���ǥ�Է�  
    SELECT 'ȸ��' AS ModuleName, 
           '�а���ǥ�Է�' AS Caption, 
           COUNT(1) AS AllData, 
           COUNT(1) AS Prog, 
           0, 
           0, 
           0, 
           COUNT(1) AS SaveCnt, 
           14 
      FROM _TACSlip AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.SlipKind NOT IN (10049, 10230, 1000181)  
       AND A.AccDate BETWEEN @DateFr AND @DateTo
       AND A.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
    
    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- ����ī����ǥ�Է�  
    SELECT 'ȸ��' AS ModuleName, 
           '����ī����ǥ�Է�' AS Caption, 
           COUNT(1) AS AllData, 
           MAX(ISNULL(B.Cnt,0)), 
           COUNT(1) - MAX(ISNULL(B.Cnt,0)), 
           0, 
           0, 
           MAX(ISNULL(B.Cnt,0)), 
           15 
      FROM _TSIAFebCardCfm AS A 
      OUTER APPLY (
                    SELECT COUNT(1) AS Cnt 
                      FROM _TSIAFebCardCfm AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.APPR_DATE BETWEEN @DateFr AND @DateTo 
                       AND ISNULL(Z.SlipSeq,0) <> 0 
                       AND EXISTS (SELECT 1 FROM _TDACard WHERE CompanySeq = @CompanySeq AND LEFT(REPLACE(CardNO,'-',''),16) = A.CARD_CD )
                  ) AS B 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.APPR_DATE BETWEEN @DateFr AND @DateTo
       AND EXISTS (SELECT 1 FROM _TDACard WHERE CompanySeq = @CompanySeq AND LEFT(REPLACE(CardNO,'-',''),16) = A.CARD_CD )
    
    
    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- ���ڼ��ݰ�꼭 ��ǥó��  
    SELECT 'ȸ��' AS ModuleName, 
           '���ڼ��ݰ�꼭 ��ǥó��' AS Caption, 
           COUNT(1) AS AllData, 
           MAX(ISNULL(B.Cnt,0)), 
           COUNT(1) - MAX(ISNULL(B.Cnt,0)), 
           0, 
           0, 
           MAX(ISNULL(B.Cnt,0)), 
           16 
      FROM ECTax..ZDTV3T_AP_HEAD AS A 
      OUTER APPLY (
                    SELECT COUNT(1) AS Cnt 
                      FROM ECTax..ZDTV3T_AP_HEAD AS Z 
                      LEFT OUTER JOIN (                 --���� �����׸�(���ι�ȣ)�� ������ ��ǥ ���� �Ǿ� ������ �������� ��ȸ�Ǽ� �ϳ��� ������ ����
                                        SELECT CompanySeq, RemValText, MAX(SlipSeq) AS SlipSeq
                                        FROM _TACSlipRem 
                                        WHERE CompanySeq = @CompanySeq
                                        AND   RemSeq  = 9003
                                        GROUP BY CompanySeq, RemValText
                                      ) AS Y ON ( Y.CompanySeq = @CompanySeq AND Z.ISSUE_ID = Y.RemValText ) 
                     WHERE Z.ISSUE_DATE BETWEEN @DateFr AND @DateTo 
                       AND Z.IP_ID IN ( '1108512343', '3168103672' ) 
                       AND CASE WHEN ISNULL(Y.RemValText,'') = '' THEN '0' ELSE '1' END = '1'
                       
                  ) AS B 
     WHERE A.ISSUE_DATE BETWEEN @DateFr AND @DateTo 
       AND IP_ID IN ( '1108512343', '3168103672' ) 
    
    ----------------------------------------------------------------------------------------------------------------------------------------------
    -- ȸ��, END 
    ----------------------------------------------------------------------------------------------------------------------------------------------
    
    ----------------------------------------------------------------------------------------------------------------------------------------------
    -- ����
    ----------------------------------------------------------------------------------------------------------------------------------------------
    
    
    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort ) -- �����ȹ(��Ʈ) 
    SELECT '����' AS ModuleName, 
           '�����ȹ(��Ʈ)' AS Caption, 
           0 AS AllData, 
           COUNT(1) AS Prog, 
           0, 
           C.DeptSeq, 
           B.EmpSeq, 
           COUNT(1) AS SaveCnt, 
           17
      FROM _TPDMPSDailyProdPlan AS A 
      LEFT OUTER JOIN _TCAUser  AS B ON ( B.CompanySeq = @CompanySeq AND B.UserSeq = A.LastUserSeq ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS C ON ( C.EmpSeq = B.EmpSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.EndDate BETWEEN @DateFr AND @DateTo  
       AND A.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
     GROUP BY C.DeptSeq, B.EmpSeq 
    
    
    CREATE TABLE #TPDMPSDailyProdPlan 
    (
        IDX_NO      INT IDENTITY, 
        Seq         INT
    )
    
    INSERT INTO #TPDMPSDailyProdPlan ( Seq ) 
    SELECT A.ProdPlanSeq 
      FROM _TPDMPSDailyProdPlan AS A 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.EndDate BETWEEN @DateFr AND @DateTo  
       AND A.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
    
    TRUNCATE TABLE #Result_Sub
    
    INSERT INTO #Result_Sub ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- �۾�����(��Ʈ)  
    SELECT '����' AS ModuleName, 
           '�۾�����(��Ʈ)' AS Caption, 
           COUNT(1) AS AllData, 
           ISNULL(MAX(C.Cnt),0) AS Prog, 
           CASE WHEN COUNT(1) - ISNULL(MAX(C.Cnt),0) < 0 THEN 0 ELSE COUNT(1) - ISNULL(MAX(C.Cnt),0) END AS NotProg, 
           ISNULL(C.DeptSeq,0) AS DeptSeq, 
           ISNULL(C.EmpSeq,0) AS EmpSeq, 
           ISNULL(MAX(C.Cnt),0) AS SaveCnt, 
           18 AS Sort 
      FROM #TPDMPSDailyProdPlan AS A 
      OUTER APPLY ( 
                    SELECT COUNT(1) AS Cnt, Y.EmpSeq, Q.DeptSeq 
                      FROM _TPDSFCWorkOrder AS Z 
                      LEFT OUTER JOIN _TCAUser AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.UserSeq = Z.LastUserSeq ) 
                      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS Q ON ( Q.EmpSeq = Y.EmpSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.WorkOrderDate BETWEEN @DateFr AND @DateTo  
                       AND Z.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
                     GROUP BY Q.DeptSeq, Y.EmpSeq 
                  )  AS C 
     GROUP BY C.DeptSeq, C.EmpSeq 
     ORDER BY C.DeptSeq, C.EmpSeq 
    

    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- ��������Է� 
    SELECT A.ModuleName, 
           A.Caption, 
           A.AllData, 
           A.Prog, 
           CASE WHEN A.AllData - MAX(B.Prog) < 0 THEN 0 ELSE A.AllData - MAX(B.Prog) END AS NotProg, 
           A.DeptSeq, 
           A.EmpSeq, 
           A.SaveCnt, 
           A.Sort
      FROM #Result_Sub AS A 
      OUTER APPLY (SELECT SUM(Prog) AS Prog
                     FROM #Result_Sub 
                  ) AS B 
     GROUP BY A.ModuleName, A.Caption, A.AllData, A.Prog, 
              A.DeptSeq, A.EmpSeq, A.SaveCnt, A.Sort 
     ORDER BY A.DeptSeq, A.EmpSeq               
     
    
    CREATE TABLE #TPDSFCWorkOrder 
    (
        IDX_NO      INT IDENTITY, 
        Seq         INT, 
        Serl        INT 
    )
    
    INSERT INTO #TPDSFCWorkOrder ( Seq, Serl ) 
    SELECT A.WorkOrderSeq, A.WorkOrderSerl
      FROM _TPDSFCWorkOrder AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.WorkDate BETWEEN @DateFr AND @DateTo 
       AND A.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
       AND A.ProcSeq <> 7 -- ��ô���� ���� 
    
    TRUNCATE TABLE #Result_Sub
    
    INSERT INTO #Result_Sub ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- �������
    SELECT '����' AS ModuleName, 
           '�������' AS Caption, 
           COUNT(1) AS AllData, 
           ISNULL(MAX(C.Cnt),0) AS Prog, 
           CASE WHEN COUNT(1) - ISNULL(MAX(C.Cnt),0) < 0 THEN 0 ELSE COUNT(1) - ISNULL(MAX(C.Cnt),0) END AS NotProg, 
           ISNULL(C.DeptSeq,0) AS DeptSeq, 
           ISNULL(C.EmpSeq,0) AS EmpSeq, 
           ISNULL(MAX(C.Cnt),0) AS SaveCnt, 
           19 AS Sort 
      FROM #TPDSFCWorkOrder AS A 
      OUTER APPLY ( 
                    SELECT COUNT(1) AS Cnt, Y.EmpSeq, Q.DeptSeq 
                      FROM _TPDSFCWorkReport AS Z 
                      LEFT OUTER JOIN _TCAUser AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.UserSeq = Z.LastUserSeq ) 
                      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS Q ON ( Q.EmpSeq = Y.EmpSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.WorkDate BETWEEN @DateFr AND @DateTo  
                       AND Z.LastUserSeq NOT IN (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @Companyseq AND EnvSeq = 25)  
                       AND Z.ProcSeq <> 7 -- ��ô���� ���� 
                     GROUP BY Q.DeptSeq, Y.EmpSeq 
                  )  AS C 
     GROUP BY C.DeptSeq, C.EmpSeq 
     ORDER BY C.DeptSeq, C.EmpSeq 
    

    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, DeptSeq, EmpSeq, SaveCnt, Sort )  -- �ŷ������Է�  
    SELECT A.ModuleName, 
           A.Caption, 
           A.AllData, 
           A.Prog, 
           CASE WHEN A.AllData - MAX(B.Prog) < 0 THEN 0 ELSE A.AllData - MAX(B.Prog) END AS NotProg, 
           A.DeptSeq, 
           A.EmpSeq, 
           A.SaveCnt, 
           A.Sort
      FROM #Result_Sub AS A 
      OUTER APPLY (SELECT SUM(Prog) AS Prog
                     FROM #Result_Sub 
                  ) AS B 
     GROUP BY A.ModuleName, A.Caption, A.AllData, A.Prog, 
              A.DeptSeq, A.EmpSeq, A.SaveCnt, A.Sort 
    
    ----------------------------------------------------------------------------------------------------------------------------------------------
    -- ����,END 
    ----------------------------------------------------------------------------------------------------------------------------------------------
    
    /************************************************************************************************************************************************************
    ----------------------------------------------------------------------------------------------------------------------------------------------
    -- ����  
    ----------------------------------------------------------------------------------------------------------------------------------------------
    
    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, Sort ) -- �۾��������(�Ϲ�)
    SELECT '����' AS ModuleName, 
           '�۾��������(�Ϲ�)' AS Caption, 
           COUNT(1) AS AllData, 
           COUNT(1) AS Prog, 
           0, 
           16
      FROM _TEQWorkOrderReceiptMasterCHE AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ProgType IN (20109003, 20109004, 20109005, 20109006, 20109007, 20109008)  
       AND A.ReceiptDate BETWEEN @DateFr AND @DateTo 
       
    INSERT INTO #Result ( ModuleName, Caption, AllData, Prog, NotProg, Sort ) -- �۾��������(�Ϲ�)
    SELECT '����' AS ModuleName, 
           '�۾��������(�Ϲ�)' AS Caption, 
           COUNT(1) AS AllData, 
           SUM(B.Cnt) AS Prog, 
           COUNT(1) - SUM(B.Cnt) AS NotProg, 
           17 
      FROM _TEQWorkOrderReceiptMasterCHE AS A 
      OUTER APPLY ( 
                    SELECT COUNT(1) AS Cnt 
                      FROM _TEQWorkOrderReceiptMasterCHE AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.ProgType IN (20109006, 20109007, 20109008)  
                  ) AS B 
     WHERE A.CompanySeq = @CompanySeq
       AND A.ProgType IN (20109003, 20109004, 20109005, 20109006, 20109007, 20109008)  
       AND A.ReceiptDate BETWEEN @DateFr AND @DateTo 
    ----------------------------------------------------------------------------------------------------------------------------------------------
    -- ����, END  
    ----------------------------------------------------------------------------------------------------------------------------------------------
    ************************************************************************************************************************************************************/
    
    SELECT A.*, B.EmpName, C.DeptName, A.Caption AS Caption2
      FROM #Result AS A 
      LEFT OUTER JOIN _TDAEmp AS B ON ( B.CompanySeq = @COmpanySeq AND B.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.DeptSeq ) 
     ORDER BY Sort, DeptName, EmpName
    
    RETURN  
--GO 

--exec KPX_SEISDateProgListQuery @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <Status>0</Status>
--    <DataSeq>1</DataSeq>
--    <Selected>1</Selected>
--    <TABLE_NAME>DataBlock1</TABLE_NAME>
--    <IsChangedMst>0</IsChangedMst>
--    <DateFr>20150301</DateFr>
--    <DateTo>20150318</DateTo>
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1028585,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1023908