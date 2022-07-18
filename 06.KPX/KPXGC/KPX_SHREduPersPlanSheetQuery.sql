  
IF OBJECT_ID('KPX_SHREduPersPlanSheetQuery') IS NOT NULL   
    DROP PROC KPX_SHREduPersPlanSheetQuery  
GO  
  
-- v2015.04.14  
  
-- ������ȹ���(1sheet)-��ȸ by ����õ   
CREATE PROC KPX_SHREduPersPlanSheetQuery  
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
            @StdYearFr      NCHAR(8), 
            @StdYearTo      NCHAR(8), 
            @UMEduGrpType   INT, 
            @EduClassSeq    INT, 
            @DeptSeq        INT, 
            @EmpSeq         INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYearFr        = ISNULL( StdYearFr   , '' ),  
           @StdYearTo        = ISNULL( StdYearTo   , '' ),  
           @UMEduGrpType     = ISNULL( UMEduGrpType, 0 ),  
           @EduClassSeq      = ISNULL( EduClassSeq , 0 ),  
           @DeptSeq          = ISNULL( DeptSeq     , 0 ),  
           @EmpSeq           = ISNULL( EmpSeq      , 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            StdYearFr      NCHAR(8),
            StdYearTo      NCHAR(8),
            UMEduGrpType   INT, 
            EduClassSeq    INT, 
            DeptSeq        INT, 
            EmpSeq         INT
          )    
    
    -- ������ȸ   
    SELECT A.PlanSeq, 
           A.PlanKindSeq, 
           B.MinorName AS PlanKindName, -- ��ȹ���� 
           A.EmpSeq, 
           C.EmpName, 
           C.EmpID, 
           C.DeptSeq, 
           C.DeptName, 
           D.EduCourseName, -- �н����� 
           A.EduCourseSeq, 
           E.EduClassSeq AS EduClassSeq , 
           E.EduClassName AS EduClassName, -- �н��з�
           D.UMEduGrpType AS UMEduGrpType, 
           F.MinorName AS UMEduGrpTypeName, 
           D.EduTypeSeq AS EduTypeSeq, 
           G.EduTypeName AS EduTypeName, -- �н�����
           A.EtcCourseName,
           A.ExpectDd,
           A.ExpectTm,
           A.EduPoint,
           A.ExpectCost,
           A.EduEffect,
           A.EduObject, 
           A.ExpectBegDate, 
           A.ExpectEndDate, 
           A.EduCenterSeq, 
           H.MinorName AS EduCenterName -- ������� 

      FROM KPX_THREduPersPlanSheet      AS A
      LEFT OUTER JOIN _TDAUMinor        AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.PlanKindSeq ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS C ON ( C.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _THREduCourse     AS D ON ( D.CompanySeq = @CompanySeq AND D.EduCourseSeq = A.EduCourseSeq ) 
      LEFT OUTER JOIN _fnHREduClass(@CompanySeq) AS E ON ( E.EduClassSeq = D.EduClassSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS F ON ( F.CompanySeq = @CompanySeq AND D.UMEduGrpType = F.MinorSeq ) 
      LEFT OUTER JOIN _THREduType       AS G ON ( G.CompanySeq = @CompanySeq  AND G.EduTypeSeq = D.EduTypeSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = A.EduCenterSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND LEFT(A.ExpectBegDate,4) BETWEEN @StdYearFr AND @StdYearTo 
       AND ( @UMEduGrpType = 0 OR D.UMEduGrpType = @UMEduGrpType ) 
       AND ( @EduClassSeq = 0 OR E.EduClassSeq = @EduClassSeq ) 
       AND ( @DeptSeq = 0 OR C.DeptSeq = @DeptSeq ) 
       AND ( @EmpSeq = 0 OR C.EmpSeq = @EmpSeq ) 
    
    RETURN  