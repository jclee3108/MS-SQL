IF OBJECT_ID('KPX_SHRBasCertificateGWQuery') IS NOT NULL 
    DROP PROC KPX_SHRBasCertificateGWQuery 
GO 

-- v2015.09.25 

/************************************************************  
 ��  �� - ������û-GW��ȸ  
 �ۼ��� - 2014.12.18  
 �ۼ��� - ���游  
************************************************************/  
  CREATE PROC dbo.KPX_SHRBasCertificateGWQuery      
  @xmlDocument    NVARCHAR(MAX),    
  @xmlFlags       INT     = 0,    
  @ServiceSeq     INT     = 0,    
  @WorkingTag     NVARCHAR(10)= '',    
  @CompanySeq     INT     = 1,    
  @LanguageSeq    INT     = 1,    
  @UserSeq        INT     = 0,    
  @PgmSeq         INT     = 0    
 AS     
    
    CREATE TABLE #GWTemp 
    (
        EmpSeq      INT, 
        CertiSeq    INT 
    ) 
    INSERT INTO #GWTemp ( EmpSeq, CertiSeq ) 
    SELECT CONVERT(INT,LEFT(TblKey,CHARINDEX(',',TblKey) - 1)), CONVERT(INT,REPLACE(TblKey, LEFT(TblKey,CHARINDEX(',',TblKey) - 1) + ',', ''))
      FROM #TblKeyData 
    
    
    SELECT  ISNULL(B.EmpName      , '') AS EmpName      ,    -- ���  
            ISNULL(A.EmpSeq       ,  0) AS EmpSeq       ,    -- ���(�ڵ�)  
            ISNULL(B.EmpID        , '') AS EmpID        ,    -- ���  
            ISNULL(D.DeptName     , '') AS DeptName     ,    -- �μ�  
            ISNULL(A.CertiSeq     ,  0) AS CertiSeq     ,    -- �����Ϸù�ȣ  
            ISNULL(A.SMCertiType  ,  0) AS SMCertiType  ,    -- ��������(�ڵ�)  
            ISNULL(A.ApplyDate    , '') AS ApplyDate    ,     -- ��û��  
            ISNULL(A.CertiCnt     ,  0) AS CertiCnt     ,    -- ��û�߱޸ż�  
            ISNULL(A.CertiDecCnt  ,  0) AS CertiDecCnt  ,    -- Ȯ���߱޺μ�  
            ISNULL(A.CertiUseage  , '') AS CertiUseage  ,    -- �뵵  
            ISNULL(A.CertiSubmit  , '') AS CertiSubmit  ,    -- ����ó  
            -- ISNULL(E.CfmCode      , '') AS IsAgree      ,    -- ���ο���  
            ISNULL(A.IsPrt        , '') AS IsPrt        ,    -- ���࿩��  
            ISNULL(A.IssueDate    , '') AS IssueDate    ,    -- ������  
            ISNULL(A.IssueNo      ,  0) AS IssueNo      ,    -- �����ȣ  
            ISNULL(A.IssueEmpSeq  ,  0) AS IssueEmpSeq  ,    -- �����ڻ��(�ڵ�)  
            ISNULL(A.IsNoIssue    , '') AS IsNoIssue    ,    -- �߱޺Ұ�����  
            ISNULL(A.NoIssueReason, '') AS NoIssueReason,    -- ����  
            ISNULL(A.IsEmpApp     , '') AS IsEmpApp     ,    -- ���ν�û����  
            ISNULL(B.EntDate      , '') AS EntDate      ,    -- �Ի���  
            ISNULL(B.RetireDate   , '') AS RetireDate   ,    -- �����  
            --ISNULL(dbo._FCOMDecrypt(C.ResidID, '_TDAEmp', 'ResidID', @CompanySeq), '') AS ResidID      ,    -- �ֹι�ȣ  
            --ISNULL(dbo._FCOMMaskConv(@EnvValue1,dbo._fnResidMask(dbo._FCOMDecrypt(C.ResidID, '_TDAEmp', 'ResidID', @CompanySeq))),  '') AS ResidIdM, --�ֹι�ȣ  
            isnull(A.ResidIDMYN,0)      AS ResidIDMYN   ,    -- �ֹε�Ϲ�ȣ��ǥó������  
            ISNULL(B.UMJpName     , '') AS UMJpName     ,    -- ����  
            ISNULL(A.SMCertiStatus,  0) AS SMCertiStatus,    -- �߱޻���  
            ISNULL(A.TaxFrYm      , '') AS TaxFrYm      ,    -- �������۳��  
            ISNULL(A.TaxToYm      , '') AS TaxToYm      ,    -- ����������  
            ISNULL(A.TaxPlace     , '') AS TaxPlace     ,    -- ������  
            ISNULL(A.TaxEmpName   , '') AS TaxEmpName   ,    -- �����  
            ISNULL(A.Task         , B.JobName) AS JobName,    -- ����  
            -- ���������  
            ISNULL((SELECT MinorName  
                      FROM _TDASMinor WITH(NOLOCK)  
                     WHERE MinorSeq = A.SMCertiStatus  
                       AND CompanySeq = A.CompanySeq), '') AS SMCertiStatusName, -- ��������  
            ISNULL((SELECT MinorName  
                      FROM _TDASMinor WITH(NOLOCK)  
                     WHERE MinorSeq     = A.SMCertiType  
                       AND A.CompanySeq = CompanySeq), '') AS SMCertiTypeName, -- �߻����  
            ISNULL((SELECT EmpName  
                      FROM _TDAEmp WITH(NOLOCK)  
          WHERE CompanySeq   = A.CompanySeq  
                       AND EmpSeq       = A.IssueEmpSeq), '')  AS IssueEmpName  
                --DATEDIFF(MONTH, CONVERT(DATETIME, EntDate), CONVERT(DATETIME, RetireDate)) + 1 AS Term,    -- �����Ⱓ  
                --ISNULL(@CompanyName, '') AS CompanyName,    -- ȸ���  
                --ISNULL(@Owner      , '') AS Owner      ,    -- ��ǥ��  
                --ISNULL(@OwnerJpName, '') AS OwnerJpName,    -- ��ǥ��å  
                --ISNULL(B.TypeSeq   ,  0) AS TypeSeq         -- ����/��������  
                                                     -- �������(���, �μ� ��)  
           FROM #GWTemp AS Z 
                      JOIN _THRBasCertificate               AS A WITH(NOLOCK) ON A.CompanySeq = @CompanySeq AND A.EmpSeq = Z.EmpSeq AND A.CertiSeq = Z.CertiSeq 
                      JOIN _fnAdmEmpOrd(@CompanySeq, '')   AS B              ON A.CompanySeq = @CompanySeq AND A.EmpSeq = B.EmpSeq  -- ���������� �ֹι�ȣ  
                      JOIN _TDAEmp                         AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.EmpSeq = C.EmpSeq  
                                                     -- �����μ���  
           LEFT OUTER JOIN _TDADept                         AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq AND B.DeptSeq = D.DeptSeq  
    
    RETURN
go
    EXEC _SCOMGroupWarePrint 2, 1, 1, 1026509, 'CTM_CM','GROUP000000000000065', '' 