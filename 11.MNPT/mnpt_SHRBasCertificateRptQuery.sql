IF OBJECT_ID('mnpt_SHRBasCertificateRptQuery') IS NOT NULL 
    DROP PROC mnpt_SHRBasCertificateRptQuery
GO 

-- v2018.01.05
/*********************************************************************************************
 ��    �� - ���� ���
 �� �� �� - 
 �� �� �� - �ڹξ�
 �������� - �ֹμ� 2011.01.27 �ŷ�ó ����ڹ�ȣ, ����ι�, ��ȭ��ȣ, Fax��ȣ �߰�
          - �Ⱥ��� 2011.02.09 ������ ����� ����, �μ���, ����ó �߰�
          - �Ⱥ��� 2011.03.11 ��å �߰�
          - �Ⱥ��� 2011.04.06 �������� �߰�
          - �ּҸ� ����� �� ������/�����ڸ� �����Ͽ� ���(2011.03.24)
          - �������� ��쿡�� �ּ�/������������ üũ, �������� ��쿡�� üũ���� �ʴ´�.
          - ����߰�(2011.11.21)  
          - �ֹε�Ϲ�ȣ��ǥó�����θ� �Ǵ��ؼ� ���
          - ���� 2016.05.25 [�ý��������ڵ�з������]���� ������ �������� ��µǵ��� ����
          - 2016.07.08 (�ּ� ��� ���� ����)
          - ���� 0016.07.29 �Ⱓ ����
          - �̻�ȭ 2017.05.11 �������� ��� ������ ���� �μ���Ī �������� ���� ����
**********************************************************************************************/
-- SP�Ķ���͵�
CREATE PROCEDURE mnpt_SHRBasCertificateRptQuery
    @xmlDocument NVARCHAR(MAX)    ,    -- ȭ���� ������ XML�� ����
    @xmlFlags    INT = 0          ,    -- �ش� XML�� TYPE
    @ServiceSeq  INT = 0          ,    -- ���� ��ȣ
    @WorkingTag  NVARCHAR(10) = '',    -- WorkingTag
    @CompanySeq  INT = 1          ,    -- ȸ�� ��ȣ
    @LanguageSeq INT = 1          ,    -- ��� ��ȣ
    @UserSeq     INT = 0          ,    -- ����� ��ȣ
    @PgmSeq      INT = 0               -- ���α׷� ��ȣ
AS
    -- ����� ������ �����Ѵ�.
    DECLARE @docHandle    INT          ,    -- XML�� �ڵ��� ����  
            @EmpSeq       INT          ,    -- ���(�ڵ�)
            @DeptSeq      INT          ,    -- �μ�(�ڵ�)
            @FrApplyDate  NCHAR(8)     ,    -- ��û��(Fr)
            @ToApplyDate  NCHAR(8)     ,    -- ��û��(To)
            @SMCertiType  INT          ,    -- ��������
            @CertiUseage  NVARCHAR(200),    -- �뵵
            @IsAgree      NCHAR(1)     ,    -- ���ο���
            @IsPrt        NCHAR(1)     ,    -- ���࿩��
            @CompanyName  NVARCHAR(100),    -- ȸ���
            @Owner        NVARCHAR(50) ,    -- ��ǥ��
            @OwnerJpName  NVARCHAR(100),    -- ��ǥ����å
            @Count        INT          ,    -- ����ż�
            @Counter      INT          ,
            @pEmpSeq      NVARCHAR(MAX),
            @Certi        NVARCHAR(MAX),
            @cEmpSeq      INT          ,
            @cCertiSeq    INT          ,
            @SealPhoto    NVARCHAR(MAX),    -- ����
            @LenSealPhoto INT		   ,    -- ���λ�����  
            @TaxNo		  NVARCHAR(30) ,	-- ����ڹ�ȣ����
            @TopTelNo	  NVARCHAR(60) ,	-- ��ǥ��ȭ��ȣ����
            @TopFaxNo	  NVARCHAR(60) ,    -- ��ǥFAX��ȣ����
            @WkTrm        NCHAR(8)     ,
            @EntDate      NCHAR(8)     ,
            @IssueDate    NCHAR(8)     ,
            @RetireDate   NCHAR(8)     ,
            @WkYear1      INT          ,    -- ���(����)
            @WkMonth1     INT          ,    -- ����(����)
            @WkDay1		  INT		   ,	-- �ϼ�(����)
            @WkYear2      INT          ,    -- ���(���)
            @WkMonth2     INT          ,    -- ����(���)
            @WkDay2       INT          ,    -- ����(���)
            @BaseDate     NCHAR(8)     ,    -- ��������
            @SMSealType   INT               -- 3336001:��������, 3336002:��ǥ�̻�����
            

    -- XML�Ľ�
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    -- @xmlDocument�� XML�� @docHandle�� �ڵ��Ѵ�.
    -- XML �����͸� ���� �ӽ����̺� ����
  	CREATE TABLE #Temp (WorkingTag NCHAR(1) NULL)
	EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#Temp'    -- XML�� DataBlock1�� �����͸� �ӽ����̺� ��´�.
	IF @@ERROR <> 0
    BEGIN
        RETURN    -- ������ �߻��ϸ� ����
    END
    -- #Temp���̺�� ���� ���� �д´�.
    SELECT @SMCertiType = ISNULL(SMCertiType, 0),
           @Count       = COUNT                 ,
           @pEmpSeq     = Emp                   ,
           @Certi       = Certi
      FROM #Temp 

    -- �ӽ����̺� ����
    CREATE TABLE #TempTemp
    (
         Num      INT IDENTITY (1, 1),
         EmpSeq   INT,
         CertiSeq INT
    )

    -- �Ⱓ�� ���� �ӽ����̺�
    CREATE TABLE #EmpDate  
    (
         EmpSeq     INT NULL,  
         EntDate    NCHAR(8) NULL,
         IssueDate  NCHAR(8) NULL,
         RetireDate NCHAR(8) NULL
    )

    SELECT @Counter = 1
    WHILE @Counter <= @Count         
    BEGIN
        EXEC _SCAOBGetCols @pEmpSeq OUTPUT, @cEmpSeq OUTPUT
        EXEC _SCAOBGetCols @Certi   OUTPUT, @cCertiSeq OUTPUT
        INSERT #TempTemp(EmpSeq, CertiSeq)
        SELECT @cEmpSeq, @cCertiSeq
        SELECT @Counter = @Counter + 1
    END

    -- ȸ���� ��ǥ�ڸ��� �����´�.  
    IF (@SMCertiType = 3067003 OR @SMCertiType = 3067004)       --����
    BEGIN
        SELECT @CompanyName = CompanyForName, @Owner = OwnerForName, @OwnerJpName = OwnerJpForName
          FROM _TCACompanyForName
         WHERE CompanySeq = @CompanySeq AND LanguageSeq = 2
    END
    ELSE
    BEGIN
        SELECT @CompanyName = CompanyName, @Owner = Owner, @OwnerJpName = OwnerJpName
          FROM _TCACompany
         WHERE CompanySeq = @CompanySeq
    END
    -- ������� ������� �����´� 3336001:��������, 3336002:��ǥ�̻�����
    SELECT @SMSealType = CASE WHEN ISNULL(B.ValueText, '0') = '1' THEN 3336001 ELSE 3336002 END
      FROM _TDASMinor AS A
            LEFT OUTER JOIN _TDASMinorValue AS B WITH(NOLOCK) ON B.CompanySeq  = A.CompanySeq
                                                             AND B.MinorSeq    = A.MinorSeq
                                                             AND B.Serl        = 1005 --�����������
     WHERE A.CompanySeq = @CompanySeq
           AND A.MajorSeq = 3067    -- ��������
           AND A.MinorSeq = @SMCertiType
           
          

    -- ����� ���
    INSERT INTO #EmpDate (EmpSeq, EntDate, IssueDate, RetireDate)
         SELECT A.EmpSeq, ISNULL(B.EntDate, ''), ISNULL(C.IssueDate, ''), 
                CASE WHEN ISNULL(B.RetireDate, 0) = 0 OR B.RetireDate = '' THEN '99991231' ELSE B.RetireDate END
           FROM #TempTemp AS A JOIN _fnDAEmpDate(@CompanySeq) AS B ON A.EmpSeq = B.EmpSeq
                               JOIN _THRBasCertificate AS C ON C.CompanySeq = @CompanySeq
                                                           AND A.EmpSeq     = C.EmpSeq
                                                           AND A.CertiSeq   = C.CertiSeq
    
    -- ������ �����´�
    SELECT @SealPhoto    = ISNULL(SealPhoto, '' ),
           @LenSealPhoto = LEN(SealPhoto)
     FROM _THRBasCompanySeal WITH(NOLOCK)
    WHERE CompanySeq = @CompanySeq
      AND SMSealType = @SMSealType -- 3336001:��������, 3336002:��ǥ�̻�����

    -- ������
    CREATE TABLE #Temp_Term1
    (
         Num      INT IDENTITY (1, 1),
         EmpSeq   INT,
         WkYear1  INT,
         WkMonth1 INT,
         WkDay1	  INT
    )

    -- �Ⱓ���ϱ�
    DECLARE CurWorkCalc INSENSITIVE CURSOR FOR
     SELECT EmpSeq, EntDate, IssueDate, RetireDate
       FROM #EmpDate
   --GROUP BY EmpSeq, EntDate, IssueDate, RetireDate -- #EmpDate�� ����ż���ŭ �����ͼ� �׷������.
    FOR READ ONLY
    OPEN CurWorkCalc
    WHILE (1 = 1)
    BEGIN
        
        FETCH CurWorkCalc INTO @EmpSeq, @EntDate, @IssueDate, @RetireDate
        IF (@@FETCH_STATUS != 0)
            BREAK
        
        -- ��������� ���
        IF @RetireDate < @IssueDate 
        BEGIN
            EXEC _SCOMWorkCntCalc @EntDate, @RetireDate , @WkTrm OUTPUT
		    INSERT INTO #Temp_Term1
            SELECT @EmpSeq, CONVERT(INT, SUBSTRING(@WkTrm, 1, 2)) AS WkYear1, CONVERT(INT, SUBSTRING(@WkTrm, 3, 2)) AS WkMonth1, CONVERT(INT, SUBSTRING(@WkTrm, 5, 2)) AS WkDay1
        END
        ELSE
        BEGIN
            EXEC _SCOMWorkCntCalc @EntDate, @IssueDate , @WkTrm OUTPUT
		    INSERT INTO #Temp_Term1
            SELECT @EmpSeq, CONVERT(INT, SUBSTRING(@WkTrm, 1, 2)) AS WkYear1, CONVERT(INT, SUBSTRING(@WkTrm, 3, 2)) AS WkMonth1, CONVERT(INT, SUBSTRING(@WkTrm, 5, 2)) AS WkDay1
        END
    END
    CLOSE CurWorkCalc
    DEALLOCATE CurWorkCalc
    -- ��Ʈ�� ���� ����ϴ� �κ�
    SELECT E.Num,
           A.CertiSeq  AS CertiSeq ,
@SMCertiType AS SMCertiType ,
           ISNULL(B.EmpSeq     ,  0) AS EmpSeq     ,
           ISNULL(GrpInfo.GrpEntDate, '') AS GrpEntDate , --�׷��Ի���,  
           ISNULL(B.EmpID      , '') AS EmpID      ,    -- ���(2011.11.21)
           ISNULL(B.EmpName    , '') AS EmpName    ,    -- ���
           ISNULL(A.ApplyDate  , '') AS ApplyDate  ,    -- ��û����
           ISNULL(A.CertiCnt   ,  0) AS CertiCnt   ,    -- �߱޸ż�
           ISNULL(A.CertiUseage, '') AS CertiUseage,    -- �뵵
           ISNULL(A.CertiSubmit, '') AS CertiSubmit,    -- ����ó
           ISNULL(A.IssueDate  , '') AS IssueDate  ,    -- ������
           ISNULL(A.IssueNo    ,  0) AS IssueNo    ,    -- �����ȣ
           ISNULL(B.EntDate    , '') AS EntDate    ,    -- �Ի���
           CASE WHEN ISNULL(B.RetireDate   , '') = '' THEN ''
                WHEN B.RetireDate < A.IssueDate       THEN B.RetireDate
                ELSE A.IssueDate END AS RetireDate,    -- �����
           
           case when A.ResidIDMYN = 1 THEN  ISNULL(dbo._fnResidMask(dbo._FCOMDecrypt(C.ResidID, '_TDAEmp', 'ResidID', @CompanySeq)),'')   -- �ֹε�Ϲ�ȣ
                ELSE ISNULL(dbo._FCOMDecrypt(C.ResidID, '_TDAEmp', 'ResidID', @CompanySeq), '') end AS ResidID    ,   -- �ֹι�ȣ
           CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004) THEN ISNULL(G.ValueText, '') ELSE ISNULL(B.UMJpName, '') END AS UMJpName,    -- ����
           CASE WHEN ISNULL(C.EmpEngFirstName, '') <> '' AND ISNULL(C.EmpEngLastName, '') <> '' THEN C.EmpEngLastName + ', ' + C.EmpEngFirstName
                ELSE ISNULL(C.EmpEngLastName, '') + ISNULL(C.EmpEngFirstName, '') END AS EmpEngName,    -- ���������(�������� ������� ,�� ���� �ʴ´�.)
           ISNULL(A.Task       , '') AS Task       ,                                              -- ������
           --CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004) THEN ISNULL(D.EngDeptName, '') ELSE ISNULL(D.DeptName, '') END AS DeptName,    -- (����)�μ���
            CASE WHEN (@SMCertiType = 3067002 OR @SMCertiType = 3067004) -- ��������� ���
			     THEN  CASE WHEN @SMCertiType = 3067004 THEN ISNULL(DH.EngDeptName, '')  -- ����
						    ELSE ISNULL(DH.DeptName, '') END  -- �ѱ�
				 ELSE  CASE WHEN @SMCertiType = 3067003 THEN ISNULL(D.EngDeptName, '')  -- ���� -- ��������
						    ELSE ISNULL(D.DeptName, '') END  END AS DeptName,    -- �ѱ� -- �μ���
           -- �����ڿ� �����ڸ� �����Ѵ�.(�������� ��쿡�� �ּҽ�����/�������� üũ�ϰ� �������� ��쿡�� ���� �ʴ´�.)
           CASE WHEN B.RetireDate >= A.IssueDate THEN    -- �������� ���
                -- �ּ�����(�ǰ������� ������ �ֹε�ϻ��� �������� �Ѵ�.)
                CASE WHEN ISNULL((SELECT CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004 ) THEN LTRIM(RTRIM(AddrEng1)) +  ' ' + LTRIM(RTRIM(AddrEng2))    -- ���������� ��� �����ּ�
                                              ELSE LTRIM(RTRIM(Addr1)) +  ' ' + LTRIM(RTRIM(Addr2))    -- �ƴϸ� �ѱ��ּ�
                                          END
                                    FROM _THRBasAddress
                                   WHERE  A.CompanySeq = CompanySeq
                                     AND  A.EmpSeq = EmpSeq
                                     AND  SMAddressType = 3055002    -- �ֹε�ϻ� ������ �ּ� -- 2016.07.08 ����
                                     AND (A.IssueDate BETWEEN BegDate AND EndDate)
                                 ), '') = '' THEN (SELECT CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004 ) THEN LTRIM(RTRIM(AddrEng1)) +  ' ' + LTRIM(RTRIM(AddrEng2))    -- ���������� ��� �����ּ�
                                                               ELSE LTRIM(RTRIM(Addr1)) +  ' ' + LTRIM(RTRIM(Addr2))    -- �ƴϸ� �ѱ��ּ�
                                                           END
                                                     FROM _THRBasAddress
                                                    WHERE  A.CompanySeq = CompanySeq
                                                      AND  A.EmpSeq = EmpSeq
                                                      AND  SMAddressType = 3055003    -- �ǰ����� �ּ� -- 2016.07.08 ����
                                                      AND (A.IssueDate BETWEEN BegDate AND EndDate)
                                                  )
                     ELSE (SELECT CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004 ) THEN LTRIM(RTRIM(AddrEng1)) +  ' ' + LTRIM(RTRIM(AddrEng2))    -- ���������� ��� �����ּ�
                                       ELSE LTRIM(RTRIM(Addr1)) +  ' ' + LTRIM(RTRIM(Addr2))    -- �ƴϸ� �ѱ��ּ�
                                   END
                             FROM _THRBasAddress
                            WHERE  A.CompanySeq = CompanySeq
                              AND  A.EmpSeq = EmpSeq
                              AND  SMAddressType = 3055002    -- �ֹε�ϻ� ������ �ּ� -- 2016.07.08 ����
                              AND (A.IssueDate BETWEEN BegDate AND EndDate)
                          )
                 END
                 ELSE    -- �������� ���
                 -- �ּ�����(�ǰ������� ������ �ֹε�ϻ��� �������� �Ѵ�.)
                 CASE WHEN ISNULL((SELECT CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004 ) THEN LTRIM(RTRIM(AddrEng1)) +  ' ' + LTRIM(RTRIM(AddrEng2))    -- ���������� ��� �����ּ�
                                               ELSE LTRIM(RTRIM(Addr1)) +  ' ' + LTRIM(RTRIM(Addr2))    -- �ƴϸ� �ѱ��ּ�
                                           END
                                     FROM _THRBasAddress
                                    WHERE  A.CompanySeq = CompanySeq
                                      AND  A.EmpSeq = EmpSeq
                                      AND  SMAddressType = 3055002    -- �ֹε�ϻ� ������ �ּ� -- 2016.07.08 ����
                                      AND (A.IssueDate BETWEEN BegDate AND EndDate)
                                  ), '') = '' THEN (SELECT CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004 ) THEN LTRIM(RTRIM(AddrEng1)) +  ' ' + LTRIM(RTRIM(AddrEng2))    -- ���������� ��� �����ּ�
                                                                ELSE LTRIM(RTRIM(Addr1)) +  ' ' + LTRIM(RTRIM(Addr2))    -- �ƴϸ� �ѱ��ּ�
                                                            END
                                                      FROM _THRBasAddress
                                                     WHERE  A.CompanySeq = CompanySeq
                                                       AND  A.EmpSeq = EmpSeq
                                                       AND  SMAddressType = 3055003    -- �ǰ����� �ּ� -- 2016.07.08 ����
                                                       AND (A.IssueDate BETWEEN BegDate AND EndDate)
                                                   )
                      ELSE (SELECT CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004 ) THEN LTRIM(RTRIM(AddrEng1)) +  ' ' + LTRIM(RTRIM(AddrEng2))    -- ���������� ��� �����ּ�
                                        ELSE LTRIM(RTRIM(Addr1)) +  ' ' + LTRIM(RTRIM(Addr2))    -- �ƴϸ� �ѱ��ּ�
                                    END
                              FROM _THRBasAddress
                             WHERE  A.CompanySeq = CompanySeq
                               AND  A.EmpSeq = EmpSeq
                               AND  SMAddressType = 3055002    -- �ֹε�ϻ� ������ �ּ� -- 2016.07.08 ����
                               AND (A.IssueDate BETWEEN BegDate AND EndDate)
                           )
                 END
            END AS Addr, 
            -- �ּ�����(����)
             (SELECT CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004 ) THEN LTRIM(RTRIM(AddrEng1)) +  ' ' + LTRIM(RTRIM(AddrEng2))    -- ���������� ��� �����ּ�
                                        ELSE LTRIM(RTRIM(Addr1)) +  ' ' + LTRIM(RTRIM(Addr2))    -- �ƴϸ� �ѱ��ּ�
                                    END
                              FROM _THRBasAddress
                             WHERE  A.CompanySeq = CompanySeq
                               AND  A.EmpSeq = EmpSeq
                               AND  SMAddressType = 3055001    -- ����
                               AND (A.IssueDate BETWEEN BegDate AND EndDate)
                           ) AS Addr2, 
            T1.WkYear1 AS TermYy , 
            T1.WkMonth1 AS TermMm , 
            T1.WkDay1 AS TermDay,
           F.TaxName AS CompanyName, 
           F.Owner AS Owner, 
           @OwnerJpName AS OwnerJpName,    -- ȸ���, ��ǥ��, ��ǥ��å  
           F.TaxEngName, 
           CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004 ) THEN LTRIM(RTRIM(F.AddrEng1)) +  ' ' + LTRIM(RTRIM(F.AddrEng2)) +  ' ' + LTRIM(RTRIM(F.AddrEng3))
                       ELSE F.Addr1+F.Addr2 END  AS CompanyAddr  ,                   -- ȸ���ּ�


           @SealPhoto      AS SealPhoto ,      @LenSealPhoto    AS LenSealPhoto,     -- ��ǥ�̻�����  
           
           B.UMJdName	       AS UMJdName     ,       -- ��å             20110311 �߰�
           B.UMPgName		            AS UMPgName		,		-- ����				20110127 �߰�
           ISNULL(I.BizUnitName, '')	AS BizUnitName	,		-- ����ι�			20110127 �߰�
           ISNULL(F.TaxNo, '')			AS TaxNo		,		-- ����ڹ�ȣ		20110127 �߰�				
           ISNULL(F.TelNo, '')   		AS TopTelNo		,		-- ȸ�� ��ǥ��ȣ	20110127 �߰�
           ISNULL(F.FaxNo, '')	    	AS TopFaxNo		,		-- ȸ�� FAX��ȣ		20110127 �߰�
          ISNULL(J.EmpName    , '')   AS IssueEmpName,        -- �����ڻ���� (2011.02.09 �߰�)
          CASE WHEN ISNULL(K.EmpEngFirstName, '') <> '' AND ISNULL(K.EmpEngLastName, '') <> '' THEN K.EmpEngFirstName + ',' + K.EmpEngLastName
               ELSE ISNULL(K.EmpEngFirstName, '') + ISNULL(K.EmpEngLastName, '') END AS IssueEmpEngName,    -- ������ ��������� (2011.02.09 �߰�)
          CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004) THEN ISNULL(L.EngDeptName, '') ELSE ISNULL(L.DeptName, '') END AS IssueEmpDeptName,    -- ������ (����)�μ��� (2011.02.09 �߰�)
          ISNULL(M.Phone      , '')   AS IssueEmpPhone,       -- �����ڻ���� ��ȭ��ȣ  (2011.02.09 �߰�)
          ISNULL(M.Extension  , '')   AS IssueEmpExtension,   -- �����ڻ���� �系��ȣ  (2011.02.09 �߰�)
          ISNULL(O.MinorName  , '')   AS UMRetReasonName ,    -- �������� (2011.04.06 �߰�)
          ISNULL(dbo._FCOMDecrypt(C.ResidID, '_TDAEmp', 'ResidID', @CompanySeq), '') AS Pwd,
          ISNULL(B.SMSexName  , '')   AS SMSexName,           -- ����     (2016.05.18 �߰�)
          ISNULL(B.BirthDate  , '')   AS BirthDate            -- ������� (2016.05.18 �߰�)
     FROM #TempTemp AS E JOIN _THRBasCertificate AS A WITH(NOLOCK) ON A.EmpSeq   = E.EmpSeq
                                                                   AND A.CertiSeq = E.CertiSeq
                          -- �������(���, �μ� ��)�� �������� ���� ����
                          JOIN _fnAdmEmpOrd(@CompanySeq, '') AS B   ON A.CompanySeq = @CompanySeq
                                                                   AND E.EmpSeq     = B.EmpSeq
                          -- ���������� �ֹι�ȣ�� �������� ���� ����
                          JOIN _TDAEmp                       AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq
                                                                              AND E.EmpSeq     = C.EmpSeq
                          -- �����μ����� �������� ���� ����  
                          JOIN _TDADept                      AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq  
                                                                              AND B.DeptSeq    = D.DeptSeq
						  -- �������� ��� ������ ���� �μ���Ī �������� ����
                          LEFT OUTER JOIN _TDADeptHist		 AS DH WITH(NOLOCK) ON A.CompanySeq =DH.CompanySeq
																			   AND B.DeptSeq   = DH.DeptSeq
																			   AND B.RetireDate BETWEEN DH.BegDate AND DH.EndDate 
                          LEFT OUTER JOIN _TDABizUnit		 AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq 
															     			   AND D.BizUnit	= I.BizUnit  
  
                          LEFT OUTER JOIN _TDATaxUnit        AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq  
                                                                              AND D.TaxUnit    = F.TaxUnit  
                          LEFT OUTER JOIN _TDAUMinorValue    AS G WITH(NOLOCK) ON A.CompanySeq = G.companySeq  
                                                                              AND G.MinorSeq   = B.UMJpSeq  
                                                                              AND G.MajorSeq   = 3052  
                                                                              AND G.Serl       = 1001
                          LEFT OUTER JOIN _fnDAEmpDate(@CompanySeq) AS GrpInfo ON A.EmpSeq = GrpInfo.EmpSeq                                                                              
                          -- ������ �������(����, �μ� ��)�� �������� ���� ���� (2011.02.09 �߰�)
                          LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS J   ON A.CompanySeq   = @CompanySeq
                                                                               AND A.IssueEmpSeq = J.EmpSeq
                          -- ������ ��� ����������� �������� ���� ���� (2011.02.09 �߰�)
                          LEFT OUTER JOIN _TDAEmp                       AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq
                                                                                          AND A.IssueEmpSeq = K.EmpSeq
                          -- ������ ��� �����μ����� �������� ���� ���� (2011.02.09 �߰�)
                          LEFT OUTER JOIN _TDADept                      AS L WITH(NOLOCK) ON A.CompanySeq = L.CompanySeq  
                                                                                          AND J.DeptSeq   = L.DeptSeq 
                          -- ������ ��� ����ó�� �������� ���� ���� (2011.02.09 �߰�)                                            
                          LEFT OUTER JOIN _TDAEmpIn                     AS M WITH(NOLOCK) ON A.CompanySeq   = M.CompanySeq
                                                                                          AND A.IssueEmpSeq = M.EmpSeq
                          -- �������� (2011.04.06 �߰�)
                          LEFT OUTER JOIN _THRAdmEmpRetReason           AS N WITH(NOLOCK) ON A.CompanySeq   = N.CompanySeq
                                                                                          AND A.EmpSeq      = N.EmpSeq      
                          LEFT OUTER JOIN _TDAUMinor                    AS O WITH(NOLOCK) ON N.CompanySeq      = O.CompanySeq
                                                                                          AND N.UMRetReasonSeq = O.MinorSeq  
                          LEFT OUTER JOIN #Temp_Term1					AS T1 WITH(NOLOCK) ON A.EmpSeq = T1.EmpSeq AND E.Num = T1.Num                                                                                                                                                                                                                     
     WHERE A.CompanySeq = @CompanySeq
  ORDER BY E.Num

     --   FROM _TDABizUnit AS A 
     --   LEFT OUTER JOIN _TTAXBizTaxUnit AS B 
     --                ON A.CompanySeq    = B.CompanySeq
     --               AND A.BizUnit       = B.BizUnit
     --   LEFT OUTER JOIN _TDATaxUnit     AS C 
     --                ON A.CompanySeq    = C.CompanySeq
     --               AND B.TaxUnit       = C.TaxUnit
     --WHERE A.CompanySeq = @CompanySeq           


RETURN
go
begin tran 
exec mnpt_SHRBasCertificateRptQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ApplyDate>20171219</ApplyDate>
    <ResidIDMYN>0</ResidIDMYN>
    <SMCertiType>3067002</SMCertiType>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <Emp>53_/</Emp>
    <Certi>2_/</Certi>
    <Count>1</Count>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=13820108,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1819
rollback 

--select * from _TDABizUnit 

--select * From sysobjects where name like '_T%BizUnit%'