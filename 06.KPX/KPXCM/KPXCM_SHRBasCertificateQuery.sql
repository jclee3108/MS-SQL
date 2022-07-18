IF OBJECT_ID('KPXCM_SHRBasCertificateQuery') IS NOT NULL 
    DROP PROC KPXCM_SHRBasCertificateQuery
GO 

-- v2015.10.07 

-- KPX�� SubKey, Groupkey �߰� by����õ 
/*************************************************************************************************
  ��    �� - ���� ��ȸ
  �� �� �� - 2008. 07.17 : 
  �� �� �� - CREATED BY BCLEE
  �������� - �ּҸ� �ֹε�ϻ�������� ������� �ǰ������� ��ȸ(������ �ֹε�ϻ�������� ��ȸ)
             �ּҸ� ��ȸ�Ҷ��� �����Ͽ� ���ϴ� �ּҷ� ��ȸ�Ѵ�.
             �ּҸ� ����� ��(�ּ�1 + �ּ�2) ������ �����ϰ� ���(2011.10.28)
             �ֹε�Ϲ�ȣ ResidID�� �߰�(2012.05.04)
 **************************************************************************************************/
  -- SP�Ķ���͵�
 CREATE PROCEDURE KPXCM_SHRBasCertificateQuery
     @xmlDocument NVARCHAR(MAX)   ,    -- ȭ���� ������ XML�� ����
     @xmlFlags    INT = 0         ,    -- �ش� XML�� TYPE
     @ServiceSeq  INT = 0         ,    -- ���� ��ȣ
     @WorkingTag  NVARCHAR(10)= '',    -- WorkingTag
     @CompanySeq  INT = 1         ,    -- ȸ�� ��ȣ
     @LanguageSeq INT = 1         ,    -- ��� ��ȣ
     @UserSeq     INT = 0         ,    -- ����� ��ȣ
     @PgmSeq      INT = 0              -- ���α׷� ��ȣ
  AS
      -- ����� ������ �����Ѵ�.
     DECLARE @docHandle    INT          ,    -- XML�� �ڵ��� ����
             @EmpSeq       INT          ,    -- ���
             @DeptSeq      INT          ,    -- �μ�
             @FrApplyDate  NCHAR(8)     ,    -- ��û��(Fr)
             @ToApplyDate  NCHAR(8)     ,    -- ��û��(To)
             @SMCertiType  INT          ,    -- ��������
             @CertiUseage  NVARCHAR(200),    -- �뵵
             @IsAgree      NCHAR(1)     ,    -- ���ο���
             @IsPrt        NCHAR(1)     ,    -- ���࿩��
             @CompanyName  NVARCHAR(100),    -- ȸ���
             @CompanyAddr  NVARCHAR(200),    -- ȸ���ּ�
             @Owner        NVARCHAR(50) ,    -- ��ǥ��
             @OwnerJpName  NVARCHAR(100),    -- ��ǥ��å
             @IsConfirmUse NCHAR(1),         -- Ȯ����뿩��
             @EnvValue1    NVARCHAR(100)     -- ȯ�漳��[�ֹε�Ϲ�ȣ����]
             
  
      -- XML�Ľ�
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    -- @xmlDocument XML�� @docHandle�� �ڵ��Ѵ�.
      -- XML�� DataBlock1���κ��� ���� ������ ������ �����Ѵ�.
     SELECT @EmpSeq      = ISNULL(EmpSeq     ,   0),    -- ����� �����´�.
            @DeptSeq     = ISNULL(DeptSeq    ,   0),    -- �μ��� �����´�.
            @FrApplyDate = ISNULL(FrApplyDate,  ''),    -- ��û��(Fr)�� �����´�.
            @ToApplyDate = ISNULL(ToApplyDate,  ''),    -- ��û��(To)�� �����´�.
            @SMCertiType = ISNULL(SMCertiType,   0),    -- ���������� �����´�.
            @CertiUseage = ISNULL(CertiUseage,  ''),    -- �뵵�� �����´�.
            @IsAgree     = ISNULL(IsAgree    , '0'),    -- ���ο��������� �����´�.
            @IsPrt       = ISNULL(IsPrt      , '0')     -- ���࿩�������� �����´�.
        FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    -- XML�� DataBlock1���κ���
        WITH (EmpSeq      INT          ,
             DeptSeq     INT          ,
    FrApplyDate NCHAR(8)     ,
    ToApplyDate NCHAR(8)     , 
             SMCertiType INT          ,
             CertiUseage NVARCHAR(200),
             IsAgree     NCHAR(1)     ,
             IsPrt       NCHAR(1)
            )
      -- ȯ�漳���������ֹε�Ϲ�ȣ��������´�.
     SELECT @EnvValue1 = ISNULL(EnvValue, '') FROM _TCOMEnv WHERE CompanySeq = 1 ANd EnvSeq = 16
     IF @@ROWCOUNT = 0 OR ISNULL(@EnvValue1, '') = ''
     BEGIN
         SELECT @EnvValue1 = '999999-9999999'
     END 
   -- ȸ���� ��ǥ�ڸ��� �����´�.
     SELECT @CompanyName = CompanyName, @Owner = Owner, @OwnerJpName = OwnerJpName FROM _TCACompany WHERE CompanySeq = @CompanySeq
      -- ȸ���ּҸ� �����´�.
  -- SELECT @CompanyAddr = Addr1 + Addr2 FROM _TDATaxUnit
  
      IF(@IsPrt = '1')    -- ���࿩�ο� üũ�� �Ǿ� ������
     BEGIN
          SELECT ISNULL(B.EmpName      , '') AS EmpName      ,    -- ���
                ISNULL(A.EmpSeq       ,  0) AS EmpSeq       ,    -- ���(�ڵ�)
                ISNULL(B.EmpID        , '') AS EmpID        ,    -- ���
                ISNULL(D.DeptName     , '') AS DeptName     ,    -- �μ�
                ISNULL(A.CertiSeq     ,  0) AS CertiSeq     ,    -- �����Ϸù�ȣ
                ISNULL(A.SMCertiType  ,  0) AS SMCertiType  ,    -- ��������(�ڵ�)
                ISNULL(A.ApplyDate    , '') AS ApplyDate    ,  -- ��û��
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
                ISNULL(dbo._FCOMDecrypt(C.ResidID, '_TDAEmp', 'ResidID', @CompanySeq), '') AS ResidID      ,    -- �ֹι�ȣ
                ISNULL(dbo._FCOMMaskConv(@EnvValue1,dbo._fnResidMask(dbo._FCOMDecrypt(C.ResidID, '_TDAEmp', 'ResidID', @CompanySeq))),  '') AS ResidIdM, --�ֹι�ȣ
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
                           AND CompanySeq = A.CompanySeq), '') AS SMCertiStatusName,
                 -- ���������(�������� ������� ,�� ���� �ʴ´�.)
                CASE WHEN ISNULL(EmpEngLastName, '') = '' THEN ISNULL(C.EmpEngFirstName + C.EmpEngLastName, '')
                     ELSE ISNULL(C.EmpEngLastName + ', ' + C.EmpEngFirstName, '') END AS EmpEngName,
                 -- �ּ�
                CASE WHEN ISNULL((SELECT ISNULL(LTRIM(RTRIM(Addr1)), '') + ' ' + ISNULL(LTRIM(RTRIM(Addr2)), '')
                                    FROM _THRBasAddress WITH(NOLOCK)
                                   WHERE CompanySeq    = @CompanySeq
                                     AND EmpSeq        = A.EmpSeq
                                     AND SMAddressType = 3055002          -- �ֹε�ϻ��������
                                     AND A.IssueDate BETWEEN BegDate AND EndDate       -- �����ּҰ� ���� ���
                                  ), '') = ''
                     THEN ISNULL((SELECT ISNULL(LTRIM(RTRIM(Addr1)), '') + ' ' + ISNULL(LTRIM(RTRIM(Addr2)), '')
                                    FROM _THRBasAddress WITH(NOLOCK)
                                   WHERE CompanySeq    = @CompanySeq
                                     AND EmpSeq        = A.EmpSeq
                                     AND SMAddressType = 3055003             -- �ǰ�������
                                     AND A.IssueDate BETWEEN BegDate AND EndDate), '')    -- �����ּҷ� ��ȸ�Ѵ�.
                     ELSE ISNULL((SELECT ISNULL(LTRIM(RTRIM(Addr1)), '') + ' ' + ISNULL(LTRIM(RTRIM(Addr2)), '')
                                    FROM _THRBasAddress WITH(NOLOCK)
                                   WHERE CompanySeq    = @CompanySeq
                                     AND EmpSeq        = A.EmpSeq
                                     AND SMAddressType = 3055002             -- ������ �ֹε�ϻ��������
                                     AND A.IssueDate BETWEEN BegDate AND EndDate), '')    -- �����ּҷ� ��ȸ�Ѵ�.
                 END AS Addr,    -- �ּ�
                 -- ��������
                ISNULL((SELECT MinorName
                 FROM _TDASMinor WITH(NOLOCK)
                         WHERE MinorSeq     = A.SMCertiType
                           AND A.CompanySeq = CompanySeq), '') AS SMCertiTypeName,
                 -- �߻����
                ISNULL((SELECT EmpName
                          FROM _TDAEmp WITH(NOLOCK)
                         WHERE CompanySeq   = A.CompanySeq
                           AND EmpSeq       = A.IssueEmpSeq), '')  AS IssueEmpName,
                 DATEDIFF(MONTH, CONVERT(DATETIME, EntDate), CONVERT(DATETIME, RetireDate)) + 1 AS Term,    -- �����Ⱓ
                ISNULL(@CompanyName, '') AS CompanyName,    -- ȸ���
                ISNULL(@Owner      , '') AS Owner      ,    -- ��ǥ��
                ISNULL(@OwnerJpName, '') AS OwnerJpName,    -- ��ǥ��å
                ISNULL(B.TypeSeq   ,  0) AS TypeSeq,         -- ����/��������
                                                      -- �������(���, �μ� ��)
                CONVERT(NVARCHAR(10),ISNULL(A.EmpSeq,  0)) + ',' +  CONVERT(NVARCHAR(10),ISNULL(A.CertiSeq,0)) AS SubKey, 
                G.GroupKey 
           FROM _THRBasCertificate AS A WITH(NOLOCK) JOIN _fnAdmEmpOrd(@CompanySeq, '')         AS B              ON A.CompanySeq = @CompanySeq 
                                                                                                                 AND A.EmpSeq     = B.EmpSeq
                                                      -- ���������� �ֹι�ȣ
                                                     JOIN _TDAEmp                               AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq 
                                                                                                                 AND A.EmpSeq     = C.EmpSeq
                                                      -- �����μ���
                                                     LEFT OUTER JOIN _TDADept                   AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq 
                                                                                                                 AND B.DeptSeq    = D.DeptSeq
                                                      -- Ȯ������
                                                     -- LEFT OUTER JOIN _THRBasCertificate_Confirm AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq
                                                     --                                                             AND A.EmpSeq     = E.CfmSeq
                                                     --                                                             AND A.CertiSeq   = E.CfmSerl
                                                     LEFT OUTER JOIN _TCOMGroupWare AS G WITH(NOLOCK)ON A.CompanySeq  = G.CompanySeq  
                                                                                                    AND G.TblKey = CAST(A.EmpSeq AS NVARCHAR) + ',' + CAST(A.CertiSeq AS NVARCHAR)  
                                                                                                    AND G.WorkKind = 'CTM_CM'
           WHERE  A.CompanySeq     = @CompanySeq
            AND (A.EmpSeq         = @EmpSeq            OR @EmpSeq      =   0)
            AND (A.SMCertiType    = @SMCertiType       OR @SMCertiType =   0)    -- ���� ����
            AND (A.ApplyDate     <= @ToApplyDate       OR @ToApplyDate =  '')
            AND (A.ApplyDate     >= @FrApplyDate       OR @FrApplyDate =  '')
            AND (B.DeptSeq        = @DeptSeq           OR @DeptSeq     =   0)
            AND (A.CertiUseage LIKE @CertiUseage + '%' OR @CertiUseage =  '')    -- �뵵
            --AND A.IsEmpApp <> 1    -- ����ȭ�鿡�� ����� ��� 20100421 ������ // �ּ�ó�� 20150701 �Ÿ�ö
      END
     ELSE
     BEGIN
          SELECT ISNULL(B.EmpName      , '') AS EmpName      ,    -- ���
                ISNULL(A.EmpSeq       ,  0) AS EmpSeq       ,    -- ���(�ڵ�)
                ISNULL(B.EmpID        , '') AS EmpID        ,    -- ���
                ISNULL(D.DeptName     , '') AS DeptName     ,    -- �μ�
                ISNULL(A.CertiSeq     ,  0) AS CertiSeq     ,    -- �����Ϸù�ȣ
                ISNULL(A.SMCertiType  ,  0) AS SMCertiType  ,    -- ��������(�ڵ�)
                ISNULL(A.ApplyDate    , '') AS ApplyDate    ,    -- ��û��
                ISNULL(A.CertiCnt     ,  0) AS CertiCnt     ,    -- ��û�߱޸ż�
                ISNULL(A.CertiDecCnt  ,  0) AS CertiDecCnt  ,    -- Ȯ���߱޺μ�
                ISNULL(A.CertiUseage  , '') AS CertiUseage  ,    -- �뵵
                ISNULL(A.CertiSubmit  , '') AS CertiSubmit  ,    -- ����ó
                -- ISNULL(E.CfmCode      , '') AS IsAgree      ,    -- ���ο���
                ISNULL(A.IsPrt        , '') AS IsPrt        ,    -- ���࿩��
                ISNULL(A.IssueDate     , '') AS IssueDate    ,    -- ������
                ISNULL(A.IssueNo      ,  0) AS IssueNo      ,    -- �����ȣ
                ISNULL(A.IssueEmpSeq  ,  0) AS IssueEmpSeq  ,    -- �����ڻ��(�ڵ�)
                ISNULL(A.IsNoIssue    , '') AS IsNoIssue    ,    -- �߱޺Ұ�����
                ISNULL(A.NoIssueReason, '') AS NoIssueReason,    -- ����
                ISNULL(A.IsEmpApp     , '') AS IsEmpApp     ,    -- ���ν�û����
                ISNULL(B.EntDate      , '') AS EntDate      ,    -- �Ի���
                ISNULL(B.RetireDate   , '') AS RetireDate   ,    -- �����
                ISNULL(dbo._FCOMDecrypt(C.ResidID, '_TDAEmp', 'ResidID', @CompanySeq), '') AS ResidID      ,    -- �ֹι�ȣ
                ISNULL(dbo._FCOMMaskConv(@EnvValue1, dbo._fnResidMask(dbo._FCOMDecrypt(C.ResidID, '_TDAEmp', 'ResidID', @CompanySeq))),  '') AS ResidIdM, --�ֹι�ȣ
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
                           AND CompanySeq = A.CompanySeq), '') AS SMCertiStatusName,
                 -- ���������(�������� ������� ,�� ���� �ʴ´�.)
                CASE WHEN ISNULL(EmpEngLastName, '') = '' THEN ISNULL(C.EmpEngFirstName + C.EmpEngLastName, '')
                     ELSE ISNULL(C.EmpEngLastName + ', ' + C.EmpEngFirstName, '') END AS EmpEngName,
                 -- �ּ�
                CASE WHEN ISNULL((SELECT ISNULL(Addr1, '')
                                    FROM _THRBasAddress WITH(NOLOCK)
                                   WHERE CompanySeq    = @CompanySeq
                                     AND EmpSeq        = A.EmpSeq
                                     AND SMAddressType = 3055002          -- �ֹε�ϻ��������
                                     AND EndDate       = '99991231'       -- �����ּҰ� ���� ���
                                  ), '') = ''
                     THEN ISNULL((SELECT ISNULL(LTRIM(RTRIM(Addr1)), '') + ' ' + ISNULL(LTRIM(RTRIM(Addr2)), '')
                                    FROM _THRBasAddress WITH(NOLOCK)
                                   WHERE A.CompanySeq  = CompanySeq
                                     AND A.EmpSeq      = EmpSeq
                                     AND SMAddressType = 3055003             -- �ǰ�������
                                     AND EndDate       = '99991231'), '')    -- �����ּҷ� ��ȸ�Ѵ�.
                     ELSE ISNULL((SELECT ISNULL(LTRIM(RTRIM(Addr1)), '') + ' ' + ISNULL(LTRIM(RTRIM(Addr2)), '')
                                    FROM _THRBasAddress WITH(NOLOCK)
                                   WHERE A.CompanySeq  = CompanySeq
                                     AND A.EmpSeq      = EmpSeq
                                     AND SMAddressType = 3055002             -- ������ �ֹε�ϻ��������
                                     AND EndDate       = '99991231'), '')    -- �����ּҷ� ��ȸ�Ѵ�.
                 END AS Addr,    -- �ּ�
                 -- ��������
                ISNULL((SELECT MinorName
                          FROM _TDASMinor WITH(NOLOCK)
                         WHERE MinorSeq     = A.SMCertiType
                           AND A.CompanySeq = CompanySeq), '') AS SMCertiTypeName,
                 -- �߻����
                ISNULL((SELECT EmpName
                          FROM _TDAEmp WITH(NOLOCK)
                         WHERE CompanySeq   = A.CompanySeq
                           AND EmpSeq       = A.IssueEmpSeq), '')  AS IssueEmpName,
                 DATEDIFF(MONTH, CONVERT(DATETIME, EntDate), CONVERT(DATETIME, RetireDate)) + 1 AS Term,    -- �����Ⱓ
                ISNULL(@CompanyName, '') AS CompanyName,    -- ȸ���
                ISNULL(@Owner      , '') AS Owner      ,    -- ��ǥ��
                ISNULL(@OwnerJpName, '') AS OwnerJpName,    -- ��ǥ��å
                ISNULL(B.TypeSeq   ,  0) AS TypeSeq,         -- ����/��������
                                                      -- �������(���, �μ� ��)
                CONVERT(NVARCHAR(10),ISNULL(A.EmpSeq,  0)) + ',' +  CONVERT(NVARCHAR(10),ISNULL(A.CertiSeq,0)) AS SubKey, 
                G.GroupKey 
           FROM _THRBasCertificate AS A WITH(NOLOCK) JOIN _fnAdmEmpOrd(@CompanySeq, '') AS B ON A.CompanySeq = @CompanySeq 
                                                                                            AND A.EmpSeq     = B.EmpSeq
                                                      -- ���������� �ֹι�ȣ
                                                     JOIN _TDAEmp                       AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq 
                                                                                                         AND A.EmpSeq     = C.EmpSeq
                                                      -- �����μ���
                                                     LEFT OUTER JOIN _TDADept           AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq 
                                                                                                         AND B.DeptSeq    = D.DeptSeq
                                                      -- Ȯ������
                                                     -- LEFT OUTER JOIN _THRBasCertificate_Confirm AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq
                                                     --                                                             AND A.EmpSeq     = E.CfmSeq
                                                     --                                                             AND A.CertiSeq   = E.CfmSerl
                                                     LEFT OUTER JOIN _TCOMGroupWare AS G WITH(NOLOCK)ON A.CompanySeq  = G.CompanySeq  
                                                                                                    AND G.TblKey = CAST(A.EmpSeq AS NVARCHAR) + ',' + CAST(A.CertiSeq AS NVARCHAR)  
                                                                                                    AND G.WorkKind = 'CTM_CM'
           WHERE  A.CompanySeq     = @CompanySeq
            AND (A.EmpSeq         = @EmpSeq            OR @EmpSeq      =  0)
            AND (A.SMCertiType    = @SMCertiType       OR @SMCertiType =  0)    -- ���� ����
            AND (A.ApplyDate     <= @ToApplyDate       OR @ToApplyDate = '')
            AND (A.ApplyDate     >= @FrApplyDate       OR @FrApplyDate = '')
            AND (B.DeptSeq        = @DeptSeq           OR @DeptSeq     =  0)
            AND (A.CertiUseage LIKE @CertiUseage + '%' OR @CertiUseage = '')    -- �뵵
            AND (ISNULL(A.IsPrt  , 0) = @IsPrt)
           -- AND A.IsEmpApp <> 1       -- ����ȭ�鿡�� ����� ��� 20100421 ������ // �ּ�ó�� 20150701 �Ÿ�ö
      END
      -- ��Ʈ�� ���� ����ϴ� �κ�
 --    IF(@IsAgree = '1' AND @IsPrt = '1')
 --    BEGIN
 --
 --        SELECT ISNULL(B.EmpName      , '') AS EmpName      , ISNULL(A.EmpSeq       ,  0) AS EmpSeq       ,    -- ���          , ����ڵ�      ,
 --               ISNULL(A.CertiSeq     ,  0) AS CertiSeq     , ISNULL(A.SMCertiType  ,  0) AS SMCertiType  ,    -- �����Ϸù�ȣ, ���������ڵ�,
 --               ISNULL(A.ApplyDate    , '') AS ApplyDate    , ISNULL(A.CertiCnt     ,  0) AS CertiCnt     ,    -- ��û��        , ��û�߱޸ż�  ,
 --               ISNULL(A.CertiDecCnt  ,  0) AS CertiDecCnt  , ISNULL(A.CertiUseage  , '') AS CertiUseage  ,    -- Ȯ���߱޺μ�  , �뵵          ,
 --               ISNULL(A.CertiSubmit  , '') AS CertiSubmit  , ISNULL(E.CfmCode      , '') AS IsAgree      ,    -- ����ó        , ���ο���      ,
 --               ISNULL(A.IsPrt        , '') AS IsPrt        , ISNULL(A.IssueDate    , '') AS IssueDate    ,    -- ���࿩��      , ������        ,
 --               ISNULL(A.IssueNo      ,  0) AS IssueNo      , ISNULL(A.IssueEmpSeq  ,  0) AS IssueEmpSeq  ,    -- �����ȣ      , �����ڻ���ڵ�,
 --               ISNULL(A.IsNoIssue    , '') AS IsNoIssue    , ISNULL(A.NoIssueReason, '') AS NoIssueReason,    -- �߱޺Ұ�����  , ����  ,
 --               ISNULL(A.IsEmpApp     , '') AS IsEmpApp     , ISNULL(B.EmpID        , '') AS EmpID        ,    -- ���ν�û����  , ���          ,
 --               ISNULL(B.EntDate      , '') AS EntDate      , ISNULL(B.RetireDate   , '') AS RetireDate   ,    -- �Ի���        , �����        ,
 --               ISNULL(C.ResidID      , '') AS ResidID      , ISNULL(B.UMJpName     , '') AS UMJpName     ,    -- �ֹι�ȣ      , ����          ,
 --               ISNULL(A.SMCertiStatus,  0) AS SMCertiStatus, ISNULL(A.TaxFrYm      , '') AS TaxFrYm      ,    -- �߱޻���    , �������۳��,
 --               ISNULL(A.TaxToYm      , '') AS TaxToYm      , ISNULL(A.TaxPlace     , '') AS TaxPlace     ,    -- ����������, ������        ,
 --               ISNULL(A.TaxEmpName   , '') AS TaxEmpName   , ISNULL(A.Task         , '') AS JobName         ,    -- �����        , ����          ,
 --               ISNULL((SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE MinorSeq = A.SMCertiStatus AND CompanySeq = A.CompanySeq), '') AS SMCertiStatusName,    -- ���������
 --               CASE WHEN ISNULL(EmpEngLastName, '') = '' THEN ISNULL(C.EmpEngFirstName + C.EmpEngLastName, '')
 --                    ELSE ISNULL(C.EmpEngFirstName + ',' + C.EmpEngLastName, '') END AS EmpEngName,    -- ���������(�������� ������� ,�� ���� �ʴ´�.),
 --               CASE WHEN (@SMCertiType = 3067001 OR @SMCertiType = 3067002) THEN D.DeptName ELSE D.EngDeptName END AS DeptName,    -- (����)�μ���,
 --               ISNULL((SELECT Addr1 + Addr2 FROM _THRBasAddress WHERE A.CompanySeq = CompanySeq    AND A.EmpSeq     = EmpSeq AND SMAddressType = 3055003 AND EndDate = '99991231'), '') AS Addr,    -- �ּ�
 --               ISNULL((SELECT MinorName     FROM _TDASMinor     WHERE MinorSeq     = A.SMCertiType AND A.CompanySeq = CompanySeq), '') AS SMCertiTypeName,    -- ��������,
 --               ISNULL((SELECT EmpName       FROM _TDAEmp        WHERE CompanySeq   = A.CompanySeq  AND EmpSeq       = A.IssueEmpSeq), '')  AS IssueEmpName   ,    -- �����ڻ��,
 --               DATEDIFF(MONTH, CONVERT(DATETIME, EntDate), CONVERT(DATETIME, RetireDate)) + 1 AS Term,    -- �����Ⱓ
 --               @CompanyName AS CompanyName, @Owner AS Owner, @OwnerJpName AS OwnerJpName, B.TypeSeq AS TypeSeq    -- ȸ���, ��ǥ��, ��ǥ��å, ����/��������
 --
 --                                                    -- �������(���, �μ� ��)�� �������� ���� ����
 --          FROM _THRBasCertificate AS A WITH(NOLOCK) JOIN _fnAdmEmpOrd(@CompanySeq, '')         AS B              ON A.CompanySeq = @CompanySeq 
 --                                                                                                                AND A.EmpSeq     = B.EmpSeq
 --
 --                                                    -- ���������� �ֹι�ȣ�� �������� ���� ����
 --                                                    JOIN _TDAEmp                               AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq 
 --                                                                                                                AND A.EmpSeq     = C.EmpSeq
 --
 --                                                    -- �����μ����� �������� ���� ����
 --                                                    LEFT OUTER JOIN _TDADept                   AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq 
 --                                                                                                                AND B.DeptSeq    = D.DeptSeq
 --
 --                                                    -- Ȯ�����θ� �������� ���� ����
 --                                                    LEFT OUTER JOIN _THRBasCertificate_Confirm AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq
 --                                                                                                                AND A.EmpSeq     = E.CfmSeq
 --                                                                                                                AND A.CertiSeq   = E.CfmSerl
 --
 --         WHERE  A.CompanySeq     = @CompanySeq
 --           AND (A.EmpSeq         = @EmpSeq            OR @EmpSeq      =  0)
 --           AND (A.SMCertiType    = @SMCertiType       OR @SMCertiType =  0)    -- ���� ����
 --           AND (A.ApplyDate     <= @ToApplyDate       OR @ToApplyDate = '')
 --           AND (A.ApplyDate     >= @FrApplyDate       OR @FrApplyDate = '')
 --           AND (B.DeptSeq        = @DeptSeq           OR @DeptSeq     =  0)
 --           AND (A.CertiUseage LIKE @CertiUseage + '%' OR @CertiUseage = '')    -- �뵵
 --           AND A.IsEmpApp <> 1       -- ����ȭ�鿡�� ����� ��� 20100421 ������
 --
 --    END
 --    ELSE IF(@IsAgree = '1')
 --    BEGIN
 --
 --        SELECT ISNULL(B.EmpName      , '') AS EmpName      , ISNULL(A.EmpSeq       ,  0) AS EmpSeq       ,    -- ���          , ����ڵ�      ,
 --               ISNULL(A.CertiSeq     ,  0) AS CertiSeq     , ISNULL(A.SMCertiType  ,  0) AS SMCertiType  ,    -- �����Ϸù�ȣ, ���������ڵ�,
 --               ISNULL(A.ApplyDate    , '') AS ApplyDate    , ISNULL(A.CertiCnt     ,  0) AS CertiCnt     ,    -- ��û��        , ��û�߱޸ż�  ,
 --               ISNULL(A.CertiDecCnt  ,  0) AS CertiDecCnt  , ISNULL(A.CertiUseage  , '') AS CertiUseage  ,    -- Ȯ���߱޺μ�  , �뵵          ,
 --               ISNULL(A.CertiSubmit  , '') AS CertiSubmit  , ISNULL(E.CfmCode      , '') AS IsAgree      ,    -- ����ó        , ���ο���      ,
 --               ISNULL(A.IsPrt        , '') AS IsPrt        , ISNULL(A.IssueDate    , '') AS IssueDate    ,    -- ���࿩��      , ������        ,
 --               ISNULL(A.IssueNo      ,  0) AS IssueNo      , ISNULL(A.IssueEmpSeq  ,  0) AS IssueEmpSeq  ,    -- �����ȣ      , �����ڻ���ڵ�,
 --               ISNULL(A.IsNoIssue    , '') AS IsNoIssue    , ISNULL(A.NoIssueReason, '') AS NoIssueReason,    -- �߱޺Ұ�����  , ����          ,
 --               ISNULL(A.IsEmpApp     , '') AS IsEmpApp     , ISNULL(B.EmpID        , '') AS EmpID        ,    -- ���ν�û����  , ���          ,
 --               ISNULL(B.EntDate      , '') AS EntDate      , ISNULL(B.RetireDate   , '') AS RetireDate   ,    -- �Ի���        , �����        ,
 --               ISNULL(C.ResidID      , '') AS ResidID      , ISNULL(B.UMJpName     , '') AS UMJpName     ,    -- �ֹι�ȣ      , ����          ,
 --               ISNULL(A.SMCertiStatus,  0) AS SMCertiStatus, ISNULL(A.TaxFrYm      , '') AS TaxFrYm      ,    -- �߱޻���    , �������۳��,
 --               ISNULL(A.TaxToYm      , '') AS TaxToYm      , ISNULL(A.TaxPlace     , '') AS TaxPlace     ,    -- ����������, ������        ,
 --               ISNULL(A.TaxEmpName   , '') AS TaxEmpName   , ISNULL(A.Task         , '') AS JobName         ,    -- �����        , ����          ,
 --               ISNULL((SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE MinorSeq = A.SMCertiStatus AND CompanySeq = A.CompanySeq), '') AS SMCertiStatusName,    -- ���������
 --               CASE WHEN ISNULL(EmpEngLastName, '') = '' THEN ISNULL(C.EmpEngFirstName + C.EmpEngLastName, '')
 --                    ELSE ISNULL(C.EmpEngFirstName + ',' + C.EmpEngLastName, '') END AS EmpEngName,    -- ���������(�������� ������� ,�� ���� �ʴ´�.),
 --               CASE WHEN (@SMCertiType = 3067001 OR @SMCertiType = 3067002) THEN D.DeptName ELSE D.EngDeptName END AS DeptName,    -- (����)�μ���,
 --               ISNULL((SELECT Addr1 + Addr2 FROM _THRBasAddress WHERE A.CompanySeq = CompanySeq    AND A.EmpSeq     = EmpSeq AND SMAddressType = 3055003 AND EndDate = '99991231'), '') AS Addr,    -- �ּ�
 --               ISNULL((SELECT MinorName     FROM _TDASMinor     WHERE MinorSeq     = A.SMCertiType AND A.CompanySeq = CompanySeq), '') AS SMCertiTypeName,    -- ��������,
 --               ISNULL((SELECT EmpName       FROM _TDAEmp        WHERE CompanySeq   = A.CompanySeq  AND EmpSeq       = A.IssueEmpSeq), '')  AS IssueEmpName   ,    -- �����ڻ��,
 --               DATEDIFF(MONTH, CONVERT(DATETIME, EntDate), CONVERT(DATETIME, RetireDate)) + 1 AS Term,    -- �����Ⱓ
 --               @CompanyName AS CompanyName, @Owner AS Owner, @OwnerJpName AS OwnerJpName, B.TypeSeq AS TypeSeq    -- ȸ���, ��ǥ��, ��ǥ��å, ����/��������
 --
 --                                                    -- �������(���, �μ� ��)�� �������� ���� ����
 --          FROM _THRBasCertificate AS A WITH(NOLOCK) JOIN _fnAdmEmpOrd(@CompanySeq, '')         AS B              ON A.CompanySeq = @CompanySeq 
 --                                                                                                                AND A.EmpSeq     = B.EmpSeq
 --
 --                                                    -- ���������� �ֹι�ȣ�� �������� ���� ����
 --                                                     JOIN _TDAEmp                               AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq 
 --                                                                                                                AND A.EmpSeq     = C.EmpSeq
 --
 --                                                    -- �����μ����� �������� ���� ����
 --                                                    LEFT OUTER JOIN _TDADept                   AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq 
 --                                                                                                                AND B.DeptSeq    = D.DeptSeq
 --
 --                                                    -- Ȯ�����θ� �������� ���� ����
 --                                                    LEFT OUTER JOIN _THRBasCertificate_Confirm AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq
 --                                                                                                                AND A.EmpSeq     = E.CfmSeq
 --                                                                                                                AND A.CertiSeq   = E.CfmSerl
 --         WHERE  A.CompanySeq     = @CompanySeq
 --           AND (A.EmpSeq         = @EmpSeq            OR @EmpSeq      =   0)
 --           AND (A.SMCertiType    = @SMCertiType       OR @SMCertiType =   0)    -- ���� ����
 --           AND (A.ApplyDate     <= @ToApplyDate       OR @ToApplyDate =  '')
 --           AND (A.ApplyDate     >= @FrApplyDate       OR @FrApplyDate =  '')
 --           AND (B.DeptSeq        = @DeptSeq           OR @DeptSeq     =   0)
 --           AND (A.CertiUseage LIKE @CertiUseage + '%' OR @CertiUseage =  '')    -- �뵵
 --           AND (ISNULL(A.IsPrt,0)          = @IsPrt             OR @IsPrt       = '0')
 --           AND A.IsEmpApp <> 1       -- ����ȭ�鿡�� ����� ��� 20100421 ������
 --
 --    END
  RETURN