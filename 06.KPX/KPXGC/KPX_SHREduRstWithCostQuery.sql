
IF OBJECT_ID('KPX_SHREduRstWithCostQuery') IS NOT NULL 
    DROP PROC KPX_SHREduRstWithCostQuery
GO 

-- v2014.11.19 

-- ����������(��ȸ) by����õ 
CREATE PROCEDURE KPX_SHREduRstWithCostQuery  
    @xmlDocument NVARCHAR(MAX)   ,    -- ȭ���� ������ XML������ ����  
    @xmlFlags    INT = 0         ,    -- �ش� XML������ TYPE  
    @ServiceSeq  INT = 0         ,    -- ���� ��ȣ  
    @WorkingTag  NVARCHAR(10)= '',    -- ��ŷ �±�  
    @CompanySeq  INT = 1         ,    -- ȸ�� ��ȣ  
    @LanguageSeq INT = 1         ,    -- ��� ��ȣ  
    @UserSeq     INT = 0         ,    -- ����� ��ȣ  
    @PgmSeq      INT = 0              -- ���α׷� ��ȣ  
AS  
    
 -- ����� ������ �����Ѵ�.  
    DECLARE @docHandle      INT     ,       -- XML������ �ڵ��� ����  
            @SMEduPlanType  INT     ,       -- ��ȹ�����ڵ庯��  
            @UMEduHighClass INT     ,       -- �н���з��ڵ� ����  
            @UMEduMidClass  INT     ,       -- �н��ߺз��ڵ� ����  
            @EduClassSeq    INT     ,       -- �н��з��ڵ� ����  
            @UMEduGrpType   INT     ,       -- �н������ڵ� ����  
            @EduTypeSeq     INT     ,       -- �н������ڵ� ����  
            @RegBegDate     NCHAR(8),       -- ��Ͻ����� ����  
            @RegEndDate     NCHAR(8),       -- ��������� ����  
            @DeptSeq        INT     ,       -- �μ��ڵ� ����  
            @EmpSeq         INT     ,       -- ����ڵ� ����  
            @IsRst          NCHAR(1),       -- ����������� ����  
            @IsEndEval      NCHAR(1),       -- �򰡿Ϸ�ȳ������� ����  
            @IsEnd          NCHAR(1),       -- Ȯ���ȳ������� ����  
            @RstNo          NVARCHAR(20),   -- �н������ȣ ����  
            @CfmEmpSeq      INT     ,       -- �����ڻ���ڵ� ����  
            @EduRstType     INT     ,       -- ��������ڵ� ����  
            @IsConfirm      NCHAR(1),       -- Ȯ������ ����  
            @IsNotConfirm   NCHAR(1),       -- ��Ȯ������ ����  
            @EduCourseSeq   INT     ,       -- �н����� ����  
            @UMCostItem     INT             -- ��ǥ����׸�  
  
  
      
  
    -- XML����  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    -- ������ XML������ @docHandle�� �ڵ��Ѵ�.  
  
 -- XML������ DataBlock1���κ��� ���� ������ ������ �����Ѵ�.  
    SELECT @DeptSeq       = ISNULL(DeptSeq      ,  0),    -- �ҼӺμ��ڵ带 �����´�.  
           @EmpSeq        = ISNULL(EmpSeq       ,  0),    -- ����ڵ带 �����´�.  
           @SMEduPlanType = ISNULL(SMEduPlanType,  0),    -- ��ȹ�����ڵ带 �����´�.  
           @UMEduHighClass= ISNULL(UMEduHighClass,  0),   -- �н���з��ڵ带 �����´�.  
           @UMEduMidClass = ISNULL(UMEduMidClass,  0),    -- �н��ߺз��ڵ带 �����´�.  
           @EduClassSeq   = ISNULL(EduClassSeq  ,  0),    -- �н��з��ڵ带 �����´�.  
           @UMEduGrpType  = ISNULL(UMEduGrpType ,  0),    -- �н������ڵ带 �����´�.  
           @EduTypeSeq    = ISNULL(EduTypeSeq   ,  0),    -- �н������ڵ带 �����´�.  
           @RegBegDate    = ISNULL(RegBegDate   , ''),    -- ��Ͻ������� �����´�.  
           @RegEndDate    = ISNULL(RegEndDate   , ''),    -- ����������� �����´�.  
           @IsRst         = ISNULL(IsRst        , ''),    -- ������������� �����´�.  
           @IsEndEval     = ISNULL(IsEndEval    , ''),    -- �򰡿Ϸ�ȳ��������� �����´�.  
           @IsEnd         = ISNULL(IsEnd        , ''),    -- Ȯ���ȳ��������� �����´�.  
           @RstNo         = ISNULL(RstNo        , ''),    -- �н������ȣ�� �����´�.  
           @CfmEmpSeq     = ISNULL(CfmEmpSeq    ,  0),    -- �����ڻ���ڵ带 �����´�.  
           @EduRstType    = ISNULL(EduRstType   ,  0),    -- ��������ڵ� �����´�.  
           @IsConfirm     = ISNULL(IsConfirm    , ''),    -- Ȯ�������� �����´�.  
           @IsNotConfirm  = ISNULL(IsNotConfirm , ''),    -- ��Ȯ�������� �����´�.  
           @EduCourseSeq  = ISNULL(EduCourseSeq ,  0)     -- �н������� �����´�.  
  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    -- XML������ DataBlock1���κ���  
  
      WITH (DeptSeq         INT     ,  
            EmpSeq          INT     ,  
            SMEduPlanType   INT     ,  
            UMEduHighClass  INT     ,  
            UMEduMidClass   INT     ,  
            EduClassSeq     INT     ,  
            UMEduGrpType    INT     ,  
            EduTypeSeq      INT     ,  
            RegBegDate      NCHAR(8),  
            RegEndDate      NCHAR(8),  
            IsRst           NCHAR(1),  
            IsEndEval       NCHAR(1),  
            IsEnd           NCHAR(1),  
            RstNo           NVARCHAR(20),  
            CfmEmpSeq       INT,  
            EduRstType      INT,  
            IsConfirm       NCHAR(1),  
            IsNotConfirm    NCHAR(1),  
            EduCourseSeq    INT  
           )  
  
    -- ��ǥ�н���� ��������  
    SELECT TOP 1 @UMCostItem =  MinorSeq  
      FROM _TDAUMinorValue  
     WHERE CompanySeq = @CompanySeq  
       AND MajorSeq = 3906  
       AND Serl = 1002  
       AND ValueText = 1  
  
  
    SELECT ISNULL(A.RstSeq       ,  0) AS RstSeq       , ISNULL(A.RstNo        , '') AS RstNo        ,    -- �н�����ڵ�    , �н������ȣ    ,  
           ISNULL(A.EmpSeq       ,  0) AS EmpSeq       , ISNULL(D.EmpName      , '') AS EmpName      ,    -- ����ڵ�        , ���            ,  
           ISNULL(D.EmpID        , '') AS EmpID        , ISNULL(D.DeptSeq      ,  0) AS DeptSeq      ,    -- ���            , �μ��ڵ�        ,  
           ISNULL(D.DeptName     , '') AS DeptName     , ISNULL(D.UMJpSeq      ,  0) AS UMJpSeq      ,    -- �μ�            , �����ڵ�        ,  
           ISNULL(D.UMJpName     , '') AS UMJpName     , ISNULL(D.PosSeq       ,  0) AS PosSeq       ,    -- ����            , �������ڵ�      ,  
           ISNULL(D.PosName      , '') AS PosName      , ISNULL(A.EduClassSeq  ,  0) AS EduClassSeq  ,    -- ������          , �н��з��ڵ�    ,  
           ISNULL(F.EduClassName , '') AS EduClassName , ISNULL(A.UMEduGrpType ,  0) AS UMEduGrpType ,    -- �н��з�        , �н������ڵ�    ,  
           ISNULL(A.EtcCourseName, '') AS EtcCourseName, ISNULL(A.EduCourseSeq ,  0) AS EduCourseSeq ,    -- ��Ÿ�н�������  , �н������ڵ�    ,  
           ISNULL(E.EduCourseName, '') AS EduCourseName, ISNULL(A.EduBegDate   , '') AS EduBegDate   ,    -- �н�������      , ��Ͻ�����      ,  
           ISNULL(A.EduEndDate   , '') AS EduEndDate   , ISNULL(A.EduDd        ,  0) AS EduDd        ,    -- ���������      , �н��ϼ�        ,  
           ISNULL(A.EduTm        ,  0) AS EduTm        , ISNULL(A.RegDate      , '') AS RegDate      ,    -- �н��ð�        , �����          ,  
           ISNULL(A.EduOkDd      ,  0) AS EduOkDd      , ISNULL(A.EduOkTm      ,  0) AS EduOkTm      ,    -- �����н��ϼ�    , �����н��ð�    ,  
           ISNULL(A.SMGradeSeq   ,  0) AS SMGradeSeq   , ISNULL(A.IsEndEval    , '') AS IsEndEval    ,    -- �򰡵���ڵ�    , �򰡿ϷῩ��    ,  
           ISNULL(C.CfmCode      , '') AS IsEnd        , ISNULL(A.EduTypeSeq   ,  0) AS EduTypeSeq   ,    -- ��Ȯ������    , �н������ڵ�    ,  
           ISNULL(A.SMEduPlanType,  0) AS SMEduPlanType, ISNULL(B.RstCost      ,  0) AS RstCost      ,    -- �н���ȹ�����ڵ�, �н����        ,  
           ISNULL((SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.UMEduGrpType) , '') AS UMEduGrpTypeName ,    -- �н�����,  
           ISNULL((SELECT MinorName FROM _TDASMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.SMGradeSeq)   , '') AS SMGradeName      ,    -- �򰡵��,  
           ISNULL((SELECT MinorName FROM _TDASMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.SMEduPlanType), '') AS SMEduPlanTypeName,    -- �н���ȹ����  
           ISNULL(A.CfmEmpSeq    ,  0) AS CfmEmpSeq    , ISNULL(G.EmpName      , '') AS CfmEmpName   ,    --�������ڵ�       , ������   
           ISNULL(A.FileNo       ,  0) AS FileNo       , ISNULL(H.EduTypeName  , '') AS EduTypeName  ,    -- ���Ϲ�ȣ        , �н�����  
           ISNULL(A.SMInOutType  ,  0) AS SMInOutType  , ISNULL(B.ReturnAmt    ,  0) AS ReturnAmt    ,    -- �系�ܱ����ڵ�  , ȯ�޺��  
           ISNULL((SELECT MinorName FROM _TDASMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.SMInOutType)  , '') AS SMInOutTypeName,      -- �系�ܱ���  
           '3204001'                   AS EduRstType   , I.MinorName                 AS EduRstTypeName,   -- �������-�Ϲ�  
           ISNULL(A.ReqSeq       ,  0) AS ReqSeq       , 0                           AS PlanSeq       ,   -- ��û�ڵ�        , ��ȹ�ڵ�  
           ISNULL(A.UMInstitute  ,  0) AS UMInstitute  , 0                           AS PlanSerl      ,   -- �н�����ڵ�    , ��ȹ����  
             ISNULL((SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq  = A.UMInstitute)  , '') AS UMInstituteName,      -- �н����  
           ISNULL(A.UMlocation   ,  0) AS UMlocation   , ISNULL(A.LecturerSeq  ,  0) AS LecturerSeq   ,                      
           ISNULL((SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.UMlocation)   , '') AS UMlocationName ,      -- �н����  
           CASE WHEN ISNULL(J.LecturerName, '') <> '' THEN ISNULL(J.LecturerName, '') ELSE ISNULL(J1.EmpName, '') END    AS LecturerName   ,      -- ����    
           ISNULL((SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.SatisLevel)   , '') AS SatisLevelName ,    -- ��������  
           ISNULL(A.SatisLevel   ,  0) AS SatisLevel    , ISNULL(A.EduPoint     ,  0) AS EduPoint      ,  -- ���������ڵ�    , ��������  
           ISNULL(A.RstSummary   , '') AS RstSummary    , ISNULL(A.RstRem       , '') AS RstRem ,          -- ������        , ���  
           K.IsEI, 
           K.SMComplate, 
           L.MinorName AS SMComplateName 
  
  
                                            -- ����� ����(���, �μ� ��)�� �������� ���� ����  
      FROM _THREduPersRst AS A WITH(NOLOCK) JOIN _fnAdmEmpOrd(@CompanySeq, '')     AS D              ON A.CompanySeq = @CompanySeq  
                                                                                                    AND A.EmpSeq     = D.EmpSeq  
  
                                            -- �н��з��ڵ�, �н��������� �������� ���� ����  
                                            LEFT OUTER JOIN _THREduCourse          AS E WITH(NOLOCK) ON A.CompanySeq   = E.CompanySeq  
                                                                                                    AND A.EduCourseSeq = E.EduCourseSeq    -- �н������ڵ尡 �����κ�  
  
                                            -- �н��з����� �������� ���� ����  
                                            LEFT OUTER JOIN _fnHREduClass(@CompanySeq) AS F          ON A.CompanySeq  =@CompanySeq  
                                                                                                    AND A.EduClassSeq = F.EduClassSeq    -- �н��з��ڵ尡 �����κ�  
  
                                            -- �н������ �������� ���� ����  
                                            LEFT OUTER JOIN _THREduPersRstCost     AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                                                                    AND A.RstSeq     = B.RstSeq  
                                                                                                    AND B.UMCostItem = @UMCostItem      -- ��ǥ������� üũ�� �׸�  
  
                                            -- Ȯ�����θ� �������� ���� ����  
                                            LEFT OUTER JOIN _THREduPersRst_Confirm AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq  
                                                                                                    AND A.RstSeq     = C.CfmSeq  
                                            -- �����ڸ� �������� ���� ����  
                                            LEFT OUTER JOIN _TDAEmp                AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq   
                                                                                                    AND A.CfmEmpSeq = G.EmpSeq   
                                            -- �н����¸� �������� ���� ����  
                                            JOIN _THREduType                       AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq   
                                                                                                    AND A.EduTypeSeq = H.EduTypeSeq  
                                            -- �������  
                                            LEFT OUTER JOIN _TDAUMinor             AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq   
                                                                                                    AND MinorSeq ='3204001'  
                                            -- ������� �������� ���� ����  
                                            LEFT OUTER JOIN _THREduLecturer        AS J WITH(NOLOCK) ON A.CompanySeq  = J.CompanySeq   
                                             AND A.LecturerSeq = J.LecturerSeq  
                                            LEFT OUTER JOIN _TDAEmp                AS J1 WITH(NOLOCK) ON J.CompanySeq  = J1.CompanySeq   
                                                                                                     AND J.EmpSeq = J1.EmpSeq  
                                            LEFT OUTER JOIN KPX_THREduRstWithCost  AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.RstSeq = A.RstSeq ) 
                                            LEFT OUTER JOIN _TDASMinor             AS L WITH(NOLOCK) ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = K.SMComplate ) 
  
  
     WHERE  A.CompanySeq        = @CompanySeq  
       AND (A.EduTypeSeq        = @EduTypeSeq       OR @EduTypeSeq      =  0)       -- �޾ƿ� �н������ڵ��      
       AND (A.EduCourseSeq      = @EduCourseSeq     OR @EduCourseSeq    =  0)       -- �޾ƿ� �н������ڵ��      
       --AND (A.RstNo             = @RstNo            OR @RstNo           =  0)       -- �޾ƿ� �н���û��ȣ��  
       AND (D.DeptSeq           = @DeptSeq          OR @DeptSeq         =  0)       -- �޾ƿ� �μ��ڵ��  
       AND (D.EmpSeq            = @EmpSeq           OR @EmpSeq          =  0)       -- �޾ƿ� ����ڵ��  
       AND (A.RegDate          >= @RegBegDate       OR @RegBegDate      = '')       -- �޾ƿ� ���� ���̿� �ִ� ����  
       AND (A.RegDate          <= @RegEndDate       OR @RegEndDate      = '')  
  
  ORDER BY EmpName    -- ����̸� ������ ����  
  
  
RETURN  
  