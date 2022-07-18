    
IF OBJECT_ID('yw_SLGASProcPlanQury') IS NOT NULL
    DROP PROC yw_SLGASProcPlanQury
GO

-- v2013.07.17

-- ASó�����_YW(��ȸ) by����õ
CREATE PROC yw_SLGASProcPlanQury                
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS        
    
    DECLARE @docHandle              INT,
		    @ImsiEmp                INT ,
            @RootEmp                INT ,
            @UMResponsTypeName      NVARCHAR(200) ,
            @ASRegDateTo            NCHAR(8) ,
            @CustName               NVARCHAR(100) ,
            @UMASMClass             INT ,
            @UMBadMKindName         NVARCHAR(200) ,
            @ASRegDateFr            NCHAR(8) ,
            @CustItemName           NVARCHAR(100) ,
            @ItemNo                 NVARCHAR(100) ,
            @ResponsDept            NVARCHAR(100) ,
            @SMLocalType            INT ,
            @UMBadTypeName          NVARCHAR(200) ,
            @UMIsEndName            NVARCHAR(200) ,
            @ASRegNo                NVARCHAR(20) ,
            @ItemName               NVARCHAR(200) ,
            @ResponsProc            NVARCHAR(100) ,
            @UMLastDecision         INT ,
            @UMLotMagnitude         INT ,
            @UMProbleSemiItemName   NVARCHAR(200) ,
            @UMProbleSubItemName    NVARCHAR(200) ,
            @UMBadMagnitude         INT,
            @UMMkind                INT ,
            @OrderItemNo            NVARCHAR(100) ,
            @ProcDept               INT ,
            @UMBadLKindName         NVARCHAR(200) ,
            @UMMtypeName            NVARCHAR(200)  
 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             

	SELECT @ImsiEmp                = ImsiEmp ,
           @RootEmp                = RootEmp ,
           @UMResponsTypeName      = UMResponsTypeName ,
           @ASRegDateTo            = ASRegDateTo ,
           @CustName               = CustName ,
           @UMASMClass             = UMASMClass ,
           @UMBadMKindName         = UMBadMKindName ,
           @ASRegDateFr            = ASRegDateFr ,
           @CustItemName           = CustItemName ,
           @ItemNo                 = ItemNo ,
           @ResponsDept            = ResponsDept ,
           @SMLocalType            = SMLocalType ,
           @UMBadTypeName          = UMBadTypeName ,
           @UMIsEndName            = UMIsEndName ,
           @ASRegNo                = ASRegNo ,
           @ItemName               = ItemName ,
           @ResponsProc            = ResponsProc ,
           @UMLastDecision         = UMLastDecision ,
           @UMLotMagnitude         = UMLotMagnitude ,
           @UMProbleSemiItemName   = UMProbleSemiItemName ,
           @UMProbleSubItemName    = UMProbleSubItemName ,
           @UMBadMagnitude         = UMBadMagnitude ,
           @UMMkind                = UMMkind ,
           @OrderItemNo            = OrderItemNo ,
           @ProcDept               = ProcDept ,
           @UMBadLKindName         = UMBadLKindName ,
           @UMMtypeName            = UMMtypeName 
           
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (
            ImsiEmp                 INT ,
            RootEmp                 INT ,
            UMResponsTypeName       NVARCHAR(200) ,
            ASRegDateTo             NCHAR(8) ,
            CustName                NVARCHAR(100) ,
            UMASMClass              INT ,
            UMBadMKindName          NVARCHAR(200) ,
            ASRegDateFr             NCHAR(8) ,
            CustItemName            NVARCHAR(100) ,
            ItemNo                  NVARCHAR(100) ,
            ResponsDept             NVARCHAR(100) ,
            SMLocalType             INT ,
            UMBadTypeName           NVARCHAR(200) ,
            UMIsEndName             NVARCHAR(200) ,
            ASRegNo                 NVARCHAR(20) ,
            ItemName                NVARCHAR(200) ,
            ResponsProc             NVARCHAR(100) ,
            UMLastDecision          INT ,
            UMLotMagnitude          INT ,
            UMProbleSemiItemName    NVARCHAR(200) ,
            UMProbleSubItemName     NVARCHAR(200) ,
            UMBadMagnitude          INT ,
            UMMkind                 INT ,
            OrderItemNo             NVARCHAR(100) ,
            ProcDept                INT ,
            UMBadLKindName          NVARCHAR(200) ,
            UMMtypeName             NVARCHAR(200)
           )
    
    SELECT A.ASRegSeq , -- AS�����ڵ�
           B.EndDate , -- ��������
           B.ImsiEmp , -- �ӽô��
           B.RootEmp , -- �ٺ����
           B.RootProc , -- �ٺ���å
           A.UMFindKind , -- �߽߰����ڵ�
           F.MinorName AS UMFindKindName , -- �߽߰���
           B.UMIsEnd , -- ���Ῡ���ڵ�
           G.MinorName AS UMIsEndName , -- ���Ῡ��
           B.UMResponsType , -- ��å�����ڵ�
           H.MinorName AS UMResponsTypeName , -- ��å����
           E.CustItemName , -- ��üǰ��
           B.ResponsDept , -- ��å�μ�
           A.SMLocalType , -- ���������ڵ�
           I.MinorName AS SMLocalTypeName , -- ��������
           B.UMBadType , -- �ҷ������ڵ�
           J.MinorName AS UMBadTypeName , -- �ҷ�����
           B.UMLastDecision , -- �����Ǵ��ڵ�
           K.MinorName AS UMLastDecisionName , -- �����Ǵ�
           B.UMProbleSemiItem , -- ������ǰ�ڵ�
           L.MinorName AS UMProbleSemiItemName , -- ������ǰ
           A.ASRegDate , -- ��������
           C.CustName , -- �����
           A.CustSeq , -- �����ڵ�
           A.UMASMClass , -- AS�ߺз��ڵ�
           M.MinorName AS UMASMClassName , -- AS�ߺз�
           B.UMBadMagnitude , -- �����ɰ����ڵ�
           N.MinorName AS UMBadMagnitudeName ,  -- �����ɰ���
           B.UMBadMKind , -- �ҷ�����(��)�ڵ�
           O.MinorName AS UMBadMKindName , -- �ҷ�����(��)
           A.ASState , -- ����
           A.BadRate , -- �ҷ���
           A.OutDate , -- �������
           B.ProbleCause , -- �߻�����
           B.UMMkind , -- 4M�з��ڵ�
           P.MinorName AS UMMkindName , -- 4M�з�
           A.ASRegNo , -- AS������ȣ
           A.CustRemark , -- ���䱸����
           A.IsStop ,  -- �ߴ�
           B.RootDate , -- �ٺ�����
           A.TargetQty , -- ������
           B.UMLotMagnitude , -- Lot�ɰ����ڵ�
           Q.MinorName AS UMLotMagnitudeName , -- Lot�ɰ���
           B.UMProbleSubItem , -- ��������ǰ�ڵ�
           R.MinorName AS UMProbleSubItemName , -- ��������ǰ
           B.ImsiProc , -- �ӽ���ġ
           D.ItemName , -- ��ǰ��
           D.ItemNo ,  -- ��ǰ��ȣ
           B.ProcDept , -- ó���μ��ڵ�
           W.DeptName AS ProcDeptName , -- ó���μ�
           B.ResponsProc , -- ��å����
           B.ImsiDate , -- �ӽñ���
           S.EmpName AS ImsiEmpName , -- �ӽô��
           T.EmpName AS RootEmpName , -- �ٺ����
           X.CfmCode AS Confirm , -- Ȯ��
           A.CustEmpName , -- ��������
           A.ItemSeq , -- ��ǰ�ڵ�
           A.OrderItemNo , -- �ֹ�������ȣ
           B.UMBadLKind , -- �ҷ�����(��)�ڵ�
           U.MinorName AS UMBadLKindName , -- �ҷ�����(��)
           B.UMMtype , -- 4M�����ڵ�
           V.MinorName AS UMMtypeName -- 4M����
    
      FROM YW_TLGASReg        AS A WITH (NOLOCK) 
      LEFT OUTER JOIN YW_TLGASProcPlan AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ASRegSeq = A.ASRegSeq ) 
      LEFT OUTER JOIN _TDACust     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDAItem     AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TSLCustItem AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = A.CustSeq AND E.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAUMinor   AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.UMFindKind ) 
      LEFT OUTER JOIN _TDAUMinor   AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = B.UMIsEnd ) 
      LEFT OUTER JOIN _TDAUMinor   AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = B.UMResponsType ) 
      LEFT OUTER JOIN _TDASMinor   AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = A.SMLocalType ) 
      LEFT OUTER JOIN _TDAUMinor   AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = B.UMBadType ) 
      LEFT OUTER JOIN _TDAUMinor   AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = B.UMLastDecision ) 
      LEFT OUTER JOIN _TDAUMinor   AS L WITH(NOLOCK) ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = B.UMProbleSemiItem ) 
      LEFT OUTER JOIN _TDAUMinor   AS M WITH(NOLOCK) ON ( M.CompanySeq = @CompanySeq AND M.MinorSeq = A.UMASMClass ) 
      LEFT OUTER JOIN _TDAUMinor   AS N WITH(NOLOCK) ON ( N.CompanySeq = @CompanySeq AND N.MinorSeq = B.UMBadMagnitude ) 
      LEFT OUTER JOIN _TDAUMinor   AS O WITH(NOLOCK) ON ( O.CompanySeq = @CompanySeq AND O.MinorSeq = B.UMBadMKind ) 
      LEFT OUTER JOIN _TDAUMinor   AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND P.MinorSeq = B.UMMkind ) 
      LEFT OUTER JOIN _TDAUMinor   AS Q WITH(NOLOCK) ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = B.UMLotMagnitude ) 
      LEFT OUTER JOIN _TDAUMinor   AS R WITH(NOLOCK) ON ( R.CompanySeq = @CompanySeq AND R.MinorSeq = B.UMProbleSubItem ) 
      LEFT OUTER JOIN _TDAEmp      AS S WITH(NOLOCK) ON ( S.CompanySeq = @CompanySeq AND S.EmpSeq = B.ImsiEmp ) 
      LEFT OUTER JOIN _TDAEmp      AS T WITH(NOLOCK) ON ( T.CompanySeq = @CompanySeq AND T.EmpSeq = B.RootEmp ) 
      LEFT OUTER JOIN _TDAUMinor   AS U WITH(NOLOCK) ON ( U.CompanySeq = @CompanySeq AND U.MinorSeq = B.UMBadLKind ) 
      LEFT OUTER JOIN _TDAUMinor   AS V WITH(NOLOCK) ON ( V.CompanySeq = @CompanySeq AND V.MinorSeq = B.UMMtype ) 
      LEFT OUTER JOIN _TDADept     AS W WITH(NOLOCK) ON ( W.CompanySeq = @CompanySeq AND W.DeptSeq = B.ProcDept ) 
      LEFT OUTER JOIN YW_TLGASReg_Confirm AS X WITH(NOLOCK) ON ( X.CompanySeq = @CompanySeq AND X.CfmSeq = A.ASRegSeq ) 
      
     WHERE A.CompanySeq = @CompanySeq
       AND A.ASRegDate BETWEEN @ASRegDateFr AND @ASRegDateTo
       AND (@SMLocalType = 0 OR A.SMLocalType = @SMLocalType)
       AND (@UMASMClass = 0 OR A.UMASMClass = @UMASMClass)
       AND (@OrderItemNo = '' OR A.OrderItemNo LIKE @OrderItemNo + '%')          
       AND (@CustName = '' OR C.CustName LIKE @CustName + '%')
       AND (@CustItemName = '' OR E.CustItemName LIKE @CustItemName + '%') 
       AND (@ItemNo = '' OR D.ItemNo LIKE @ItemNo + '%')               
       AND (@ItemName = '' OR D.ItemName LIKE @ItemName + '%')
       AND (@UMLastDecision = 0 OR B.UMLastDecision = @UMLastDecision)
       AND (@UMLotMagnitude = 0 OR B.UMLotMagnitude = @UMLotMagnitude)
       AND (@UMBadMagnitude = 0 OR B.UMBadMagnitude = @UMBadMagnitude)
       AND (@ASRegNo = '' OR A.ASRegNo = @ASRegNo) 
       AND (@UMMkind = 0 OR B.UMMkind = @UMMkind) 
       AND (@UMMtypeName = '' OR V.MinorName LIKE @UMMtypeName + '%') 
       AND (@UMProbleSubItemName = '' OR R.MinorName LIKE @UMProbleSubItemName + '%') 
       AND (@UMProbleSemiItemName = '' OR L.MinorName LIKE @UMProbleSemiItemName + '%') 
       AND (@UMBadLKindName = '' OR U.MinorName LIKE @UMBadLKindName + '%') 
       AND (@UMBadMKindName = '' OR O.MinorName LIKE @UMBadMKindName + '%') 
       AND (@UMBadTypeName = '' OR J.MinorName LIKE @UMBadTypeName + '%') 
       AND (@ResponsProc = '' OR B.ResponsProc LIKE @ResponsProc + '%') 
       AND (@ResponsDept = '' OR B.ResponsDept LIKE @ResponsDept + '%') 
       AND (@ProcDept = 0 OR B.ProcDept = @ProcDept) 
       AND (@ImsiEmp = 0 OR B.ImsiEmp = @ImsiEmp) 
       AND (@RootEmp = 0 OR B.RootEmp = @RootEmp) 
       AND (@UMIsEndName = '' OR G.MinorName LIKE @UMIsEndName + '%') 
       AND (@UMResponsTypeName = '' OR H.MinorName LIKE @UMResponsTypeName + '%') 
       AND X.CfmCode = '1'

    RETURN
GO
exec yw_SLGASProcPlanQury @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ASRegDateFr>20130701</ASRegDateFr>
    <ASRegDateTo>20130717</ASRegDateTo>
    <SMLocalType />
    <UMASMClass />
    <OrderItemNo />
    <CustName />
    <CustItemName />
    <ItemNo />
    <ItemName />
    <UMLastDecision />
    <UMLotMagnitude />
    <UMBadMagnitude />
    <ASRegNo />
    <UMMkind />
    <UMMtypeName />
    <UMProbleSubItemName />
    <UMProbleSemiItemName />
    <UMBadLKindName />
    <UMBadMKindName />
    <UMResponsTypeName />
    <ResponsProc />
    <ResponsDept />
    <ProcDept />
    <ImsiEmp />
    <RootEmp />
    <UMIsEndName />
    <UMBadTypeName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016629,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014197