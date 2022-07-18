  
IF OBJECT_ID('KPXCM_SHREduRstWithCostQuery') IS NOT NULL   
    DROP PROC KPXCM_SHREduRstWithCostQuery  
GO  
  
-- v2016.06.13  
  
-- ����������-��ȸ by ����õ   
CREATE PROC KPXCM_SHREduRstWithCostQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) ���
    
    DECLARE @docHandle      INT,  
            -- ��ȸ����   
            @DeptSeq        INT, 
            @EmpSeq         INT, 
            @EduDateTo      NCHAR(8), 
            @EduDateFr      NCHAR(8), 
            @RegEndDate     NCHAR(8), 
            @RegBegDate     NCHAR(8), 
            @EduCourseName  NVARCHAR(200), 
            @EduTypeSeq     INT

                  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @DeptSeq        = ISNULL( DeptSeq        , 0 ), 
           @EmpSeq         = ISNULL( EmpSeq         , 0 ), 
           @EduDateTo      = ISNULL( EduDateTo      , '' ), 
           @EduDateFr      = ISNULL( EduDateFr      , '' ), 
           @RegEndDate     = ISNULL( RegEndDate     , '' ), 
           @RegBegDate     = ISNULL( RegBegDate     , '' ), 
           @EduCourseName  = ISNULL( EduCourseName  , '' ), 
           @EduTypeSeq     = ISNULL( EduTypeSeq     , 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            DeptSeq         INT,  
            EmpSeq          INT, 
            EduDateTo       NCHAR(8), 
            EduDateFr       NCHAR(8), 
            RegEndDate      NCHAR(8), 
            RegBegDate      NCHAR(8), 
            EduCourseName   NVARCHAR(200),
            EduTypeSeq      INT 
           )    
    
    IF @RegEndDate = '' SELECT @RegEndDate = '99991231'
    
    SELECT ISNULL(A.RstSeq       ,  0) AS RstSeq       , ISNULL(A.RstNo        , '') AS RstNo        ,    -- �н�����ڵ�    , �н������ȣ    ,  
           ISNULL(A.EmpSeq       ,  0) AS EmpSeq       , ISNULL(D.EmpName      , '') AS EmpName      ,    -- ����ڵ�        , ���            ,  
           ISNULL(D.EmpID        , '') AS EmpID        , ISNULL(D.DeptSeq      ,  0) AS DeptSeq      ,    -- ���            , �μ��ڵ�        ,  
           ISNULL(D.DeptName     , '') AS DeptName     , ISNULL(D.UMJpSeq      ,  0) AS UMJpSeq      ,    -- �μ�            , �����ڵ�        ,  
           ISNULL(D.UMJpName     , '') AS UMJpName     , ISNULL(D.PosSeq       ,  0) AS PosSeq       ,    -- ����            , �������ڵ�      ,  
           ISNULL(D.PosName      , '') AS PosName      , ISNULL(A.EduClassSeq  ,  0) AS EduClassSeq  ,    -- ������          , �н��з��ڵ�    ,  
           ISNULL(F.EduClassName , '') AS EduClassName , ISNULL(A.UMEduGrpType ,  0) AS UMEduGrpType ,    -- �н��з�        , �н������ڵ�    ,  
           ISNULL(A.EtcCourseName, '') AS EtcCourseName, -- ��Ÿ�н�������  
           ISNULL(A.EduCourseName, '') AS EduCourseName, ISNULL(A.EduBegDate   , '') AS EduBegDate   ,    -- �н�������      , ��Ͻ�����      ,  
           ISNULL(A.EduEndDate   , '') AS EduEndDate   , ISNULL(A.EduDd        ,  0) AS EduDd        ,    -- ���������      , �н��ϼ�        ,  
           ISNULL(A.EduTm        ,  0) AS EduTm        , ISNULL(A.RegDate      , '') AS RegDate      ,    -- �н��ð�        , �����          ,  
           ISNULL(C.CfmCode      , '') AS IsEnd        , ISNULL(A.EduTypeSeq   ,  0) AS EduTypeSeq   ,    -- ��Ȯ������    , �н������ڵ�    ,  
           ISNULL((SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.UMEduGrpType) , '') AS UMEduGrpTypeName ,    -- �н�����,  
           ISNULL(H.EduTypeName  , '') AS EduTypeName  ,    -- �н�����  
           ISNULL(A.SMInOutType  ,  0) AS SMInOutType  ,    -- �系�ܱ����ڵ�  , ȯ�޺��  
           ISNULL((SELECT MinorName FROM _TDASMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.SMInOutType)  , '') AS SMInOutTypeName,      -- �系�ܱ���  
           '3204001'                   AS EduRstType   , I.MinorName                 AS EduRstTypeName,   -- �������-�Ϲ�  
           ISNULL(A.EduPoint     ,  0) AS EduPoint      ,  -- ��������  
           ISNULL(A.RstSummary   , '') AS RstSummary    , ISNULL(A.RstRem       , '') AS RstRem,          -- ������        , ���  
           A.IsEI, 
           A.UMEduReport, 
           J.MinorName AS UMEduReportName, 
           A.UMEduCost, 
           K.MinorName AS UMEduCostName, 
           A.SMComplate, 
           L.MinorName AS SMComplateName, 
           A.RstCost, 
           A.ReturnAmt 
  
  
                                            -- ����� ����(���, �μ� ��)�� �������� ���� ����  
      FROM KPXCM_THREduPersRst AS A         JOIN _fnAdmEmpOrd(@CompanySeq, '')     AS D ON A.CompanySeq = @CompanySeq  
                                                                                       AND A.EmpSeq     = D.EmpSeq  
                                            -- �н��з����� �������� ���� ����  
                                            LEFT OUTER JOIN _fnHREduClass(@CompanySeq)  AS F ON A.CompanySeq  =@CompanySeq  
                                                                                            AND A.EduClassSeq = F.EduClassSeq    -- �н��з��ڵ尡 �����κ�  
                                            -- Ȯ�����θ� �������� ���� ����  
                                            LEFT OUTER JOIN _THREduPersRst_Confirm   AS C ON A.CompanySeq = C.CompanySeq  
                                                                                        AND A.RstSeq     = C.CfmSeq   
                                            -- �н����¸� �������� ���� ����  
                                            LEFT OUTER JOIN _THREduType             AS H ON A.CompanySeq = H.CompanySeq   
                                                                                        AND A.EduTypeSeq = H.EduTypeSeq  
                                            -- �������  
                                            LEFT OUTER JOIN _TDAUMinor              AS I ON A.CompanySeq = I.CompanySeq   
                                                                                        AND I.MinorSeq ='3204001'  
                                            LEFT OUTER JOIN _TDAUMinor              AS J ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = A.UMEduReport ) 
                                            LEFT OUTER JOIN _TDAUMinor              AS K ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = A.UMEduCost ) 
                                            LEFT OUTER JOIN _TDASMinor              AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = A.SMComplate ) 

  
  
     WHERE  A.CompanySeq        = @CompanySeq  
       AND (@EduCourseName = '' OR ISNULL(A.EduCourseName, '') LIKE @EduCourseName + '%') 
       AND (@EduTypeSeq = 0 OR A.EduTypeSeq = @EduTypeSeq)
       AND (D.DeptSeq           = @DeptSeq          OR @DeptSeq         =  0)       -- �޾ƿ� �μ��ڵ��  
       AND (D.EmpSeq            = @EmpSeq           OR @EmpSeq          =  0)       -- �޾ƿ� ����ڵ��  
       AND (A.RegDate BETWEEN @RegBegDate AND @RegEndDate)       -- �޾ƿ� ���� ���̿� �ִ� ����  
       AND (A.EduBegDate BETWEEN @EduDateFr AND @EduDateTo)
       
    RETURN  
    go
    exec KPXCM_SHREduRstWithCostQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <RegBegDate>20160601</RegBegDate>
    <RegEndDate />
    <EduDateFr>20160601</EduDateFr>
    <EduDateTo>20160613</EduDateTo>
    <EduCourseName />
    <DeptSeq />
    <EmpSeq />
    <EduTypeSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037426,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030642