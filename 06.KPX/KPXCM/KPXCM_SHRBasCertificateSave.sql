IF OBJECT_ID('KPXCM_SHRBasCertificateSave') IS NOT NULL 
    DROP PROC KPXCM_SHRBasCertificateSave
GO 

-- v2015.10.07 

-- KPX�� SubKey, Groupkey �߰� by����õ 
 /************************************************************************************************
  ��  �� - ���� ���
  �ۼ��� - 2008. 07.17 : 
  �ۼ��� - CREATED BY BCLEE
  ������ - 
 *************************************************************************************************/
  -- SP�Ķ���͵�
 CREATE PROCEDURE KPXCM_SHRBasCertificateSave
     @xmlDocument NVARCHAR(MAX)   ,    -- ȭ���� ������ XML������ ����
     @xmlFlags    INT = 0         ,    -- �ش� XML������ TYPE
     @ServiceSeq  INT = 0         ,    -- ���� ��ȣ
     @WorkingTag  NVARCHAR(10)= '',    -- WorkingTag
     @CompanySeq  INT = 1         ,    -- ȸ�� ��ȣ
     @LanguageSeq INT = 1         ,    -- ��� ��ȣ
     @UserSeq     INT = 0         ,    -- ����� ��ȣ
     @PgmSeq      INT = 0              -- ���α׷� ��ȣ
  AS
      -- ���� ������ ��� ����
     CREATE TABLE #THRBasCertificate (WorkingTag NCHAR(1) NULL)
      -- �ӽ� ���̺� ������ �÷��� �߰��ϰ�, XML�����κ����� ���� INSERT�Ѵ�.(DataBlock1�� �÷����� �ӽ����̺� �����Ѵ�.)
     EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#THRBasCertificate'
      IF @@ERROR <> 0
     BEGIN
         RETURN    -- ������ �߻��ϸ� ����
     END
  
      -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)    
     EXEC _SCOMLog @CompanySeq         ,    -- ȸ���ȣ
                   @UserSeq            ,    -- ����� ��ȣ
                   '_THRBasCertificate',    -- �����̺��    
                   '#THRBasCertificate',    -- �ӽ� ���̺��    
                   'EmpSeq, CertiSeq'  ,    -- Ű�� �������� ���� , �� �����Ѵ�.
                   'CompanySeq, EmpSeq, CertiSeq, SMCertiType, ApplyDate, CertiCnt, CertiDecCnt, CertiUseage, CertiSubmit, SMCertiStatus, Task,
                    IsAgree, IsPrt, IssueDate, IssueNo, IssueEmpSeq, IsNoIssue, NoIssueReason, IsEmpApp, LastUserSeq, LastDateTime, TaxFrYm,
                    TaxToYm, TaxPlace, TaxEmpName,ResidIDMYN'    -- �����̺��� �÷���
      IF @@ERROR <> 0
     BEGIN
         RETURN    -- ������ �߻��ϸ� ����
     END
  
  
  --    -- ���ο��� ����(Ȯ�����̺��� �ƴ� �����̺��� �����÷��� �����Ͽ� �ش�.)
 --    UPDATE #THRBasCertificate
 --       SET IsAgree = '0'
 --     WHERE (WorkingTag <> 'D' AND Status = 0 AND IsAgree <> '1')
 --
 --    -- ���࿩�� ����
 --    UPDATE #THRBasCertificate
 --       SET IsPrt = '0'
 --     WHERE (WorkingTag <> 'D' AND Status = 0 AND IsPrt <> '1')
  
  
      -- DELETE
     IF EXISTS (SELECT 1 FROM #THRBasCertificate WHERE WorkingTag = 'D' AND Status = 0)
     BEGIN
          DELETE _THRBasCertificate
            FROM #THRBasCertificate AS A JOIN _THRBasCertificate B ON B.CompanySeq = @CompanySeq
                                                                 AND A.EmpSeq     = B.EmpSeq
                                                                 AND A.CertiSeq   = B.CertiSeq
           WHERE (A.WorkingTag = 'D' AND A.Status = 0)
  
         IF @@ERROR <> 0
         BEGIN
             RETURN
         END
      END
  
  
      -- UPDATE
     IF EXISTS (SELECT 1 FROM #THRBasCertificate WHERE WorkingTag = 'U' AND Status = 0)
     BEGIN
   
         UPDATE _THRBasCertificate
             SET SMCertiType = A.SMCertiType, ApplyDate     = A.ApplyDate  ,    -- ��������    , ��û����,
                CertiCnt    = A.CertiCnt   , CertiDecCnt   = A.CertiDecCnt,    -- ��û�ż�      , Ȯ���ż�,
                CertiUseage = A.CertiUseage, CertiSubmit   = A.CertiSubmit,    -- �뵵          , ����ó  ,
                Task        = ISNULL(A.JobName,  ''),    -- ������     20100419 �������÷����� ���� ������
                IsPrt       = ISNULL(A.IsPrt  , '0'),    -- ���࿩��      
                IssueDate   = A.IssueDate  , IssueEmpSeq   = A.IssueEmpSeq  ,    -- ������      , �����ڻ���ڵ�,
                IsNoIssue   = A.IsNoIssue  , NoIssueReason = A.NoIssueReason,    -- �߱޺Ұ�����, ����          ,
                IsEmpApp    = A.IsEmpApp   , SMCertiStatus = A.SMCertiStatus,    -- ���ν�û����, �߱޻���      ,
                LastUserSeq = @UserSeq     , LastDateTime  = GETDATE()      ,
                TaxFrYm     = ISNULL(A.TaxFrYm   , ''), 
                TaxToYm    = ISNULL(A.TaxToYm   , ''), 
                TaxPlace    = ISNULL(A.TaxPlace  , ''),
                TaxEmpName  = ISNULL(A.TaxEmpName, ''),
                IssueNo    = ISNULL(A.IssueNo   , ''),
                ResidIDMYN  = isnull(A.ResidIDMYN, 0 )
                
            FROM #THRBasCertificate AS A JOIN _THRBasCertificate AS B ON B.CompanySeq = @CompanySeq
                                                                    AND A.EmpSeq     = B.EmpSeq
                                                                    AND A.CertiSeq   = B.CertiSeq
          WHERE (A.WorkingTag = 'U' AND A.Status = 0)
  
         IF @@ERROR <> 0
         BEGIN
             RETURN
         END
      END
  
      -- INSERT  
     IF EXISTS (SELECT 1 FROM #THRBasCertificate WHERE WorkingTag = 'A' AND Status = 0)
     BEGIN
     INSERT INTO _THRBasCertificate(CompanySeq   , EmpSeq     ,    -- �����ڵ�          , ����ڵ�
                                            CertiSeq     , SMCertiType,    -- �����Ϸù�ȣ    , ��������
                                            ApplyDate    , CertiCnt   ,    -- ��û����          , �߱޸ż�(��û�μ�)      
                                            CertiDecCnt  , CertiUseage,    -- Ȯ���ż�(�߱޺μ�), �뵵           
                                            CertiSubmit  , Task       ,    -- ����ó            , ������
                                            IsAgree      , IsPrt      ,    -- ���ο���          , ���࿩��      
                                            IssueDate    , IssueNo    ,    -- ������            , �����ȣ
                                            IssueEmpSeq  , IsNoIssue  ,    -- �����ڻ���ڵ�    , �߱޺Ұ�����
                                            NoIssueReason, IsEmpApp   ,    -- ����              , ���ν�û����
                                            SMCertiStatus, TaxFrYm    ,    -- �߱޻���          , ���۳��
                                            TaxToYm      , TaxPlace   ,    -- ������          , ������
                                            TaxEmpName   , LastUserSeq,    -- �����            , �۾���
                                            LastDateTime , ResidIdMYN )    -- �۾��Ͻ�          , �ֹε�Ϲ�ȣ��ǥó������ 
                   SELECT @CompanySeq    , A.EmpSeq   ,    -- ȸ���ȣ      , ����ڵ�      ,
                         A.CertiSeq     , A.SMCertiType,    -- �����Ϸù�ȣ, ���������ڵ�,
                         A.ApplyDate    , A.CertiCnt   ,    -- ��û����      , �߱޸ż�      ,
                         A.CertiDecCnt  , A.CertiUseage,    -- Ȯ���ż�      , �뵵          ,
                         A.CertiSubmit  , ISNULL(A.JobName,  ''),    -- ����ó        , ������      , --  20100419 �������÷����� ���� ������
                         '1'            , ISNULL(A.IsPrt  , '0'),    -- ���ο���      , ���࿩��      ,
                         A.IssueDate    , A.IssueNo    ,    -- ������        , �����ȣ      ,
                         A.IssueEmpSeq  , A.IsNoIssue  ,    -- �����ڻ���ڵ�, �߱޺Ұ�����  ,
                         A.NoIssueReason, A.IsEmpApp   ,    -- ����          , ���ν�û����  ,
          A.SMCertiStatus, A.TaxFrYm    ,    -- �߱޻���, ���۳��
          CASE WHEN A.SMCertiType =3067006 OR  A.SMCertiType =3067007 OR  A.SMCertiType =3067008 THEN  
                             CASE WHEN ISNULL(A.TaxToYm    , '')='' THEN CONVERT(VARCHAR(6), getdate(),112) ELSE  ISNULL(A.TaxToYm    , '') END
                         ELSE  ISNULL(A.TaxToYm    , '') END   , 
                         A.TaxPlace      ,                     -- ������, ������
          A.TaxEmpName    , @UserSeq     ,    -- �����, �۾���,
                         GETDATE()       , A.ResidIDMYN   -- �۾��Ͻ�, �ֹε�Ϲ�ȣ��ǥó������
                     FROM #THRBasCertificate AS A
                    WHERE (A.WorkingTag = 'A' AND A.Status = 0)
  
          IF @@ERROR <> 0
      BEGIN
          RETURN
      END
      END
  
  
      -- ������ ��� ����
     UPDATE #THRBasCertificate
         SET IssueEmpName = B.EmpName
        FROM #THRBasCertificate AS A JOIN _TDAEmp AS B ON A.IssueEmpSeq = B.EmpSeq
       WHERE A.Status = 0 AND B.CompanySeq = @CompanySeq
  
    
    UPDATE A   
       SET SubKey = CONVERT(NVARCHAR(10),EmpSeq) + ',' + CONVERT(NVARCHAR(10),CertiSeq)  
      FROM #THRBasCertificate AS A   
    
     SELECT * FROM #THRBasCertificate    -- Output
  RETURN