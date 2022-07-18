IF OBJECT_ID('KPXCM_SEQChangeReportQuery') IS NOT NULL 
    DROP PROC KPXCM_SEQChangeReportQuery 
GO 

-- v2015.06.12    
    
-- ���������Ȳ-��ȸ by ����õ     
CREATE PROC KPXCM_SEQChangeReportQuery    
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
      
    DECLARE @docHandle          INT,    
            -- ��ȸ����     
            @Plant              INT,    
            @BaseDateFr         NCHAR(8),   
            @BaseDateTo         NCHAR(8),   
            @ChangeRequestNo    NVARCHAR(100),   
            @UMChangeType       INT,   
            @Title              NVARCHAR(200),   
            @EmpSeq             INT,   
            @DeptSeq            INT   
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
        
    SELECT  @Plant             = ISNULL( Plant           , 0 ),    
            @BaseDateFr        = ISNULL( BaseDateFr      , '' ),    
            @BaseDateTo        = ISNULL( BaseDateTo      , '' ),    
            @ChangeRequestNo   = ISNULL( ChangeRequestNo , '' ),    
            @UMChangeType      = ISNULL( UMChangeType    , 0 ),    
            @Title             = ISNULL( Title           , '' ),    
            @EmpSeq            = ISNULL( EmpSeq          , 0 ),    
            @DeptSeq           = ISNULL( DeptSeq         , 0 )   
        
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )         
      WITH (  
                Plant              INT,    
                BaseDateFr         NCHAR(8),                   
                BaseDateTo         NCHAR(8),                   
                ChangeRequestNo    NVARCHAR(100),                   
                UMChangeType       INT,                   
                Title              NVARCHAR(200),                   
                EmpSeq             INT,                   
                DeptSeq            INT                   
           )      
      
    IF @BaseDateTo = '' SELECT @BaseDateTo = '99991231'  
    -- ������ȸ     
    SELECT A.UMPlantType,   
           B.MinorName AS PlantName, -- Plant����   
           A.ChangeRequestNo, -- ������ǹ�ȣ   
           A.UMChangeType,   
           C.MinorName AS UMChangeTypeName, -- ���汸��   
           A.Title, -- ������   
           A.DeptSeq,   
           D.DeptName, -- ������Ǻμ�   
           A.EmpSeq,   
           E.EmpName, -- ���������  
           F.RecvDate, -- ���������������   
           G.TaskOrderDate, -- ����������������   
           H.FinalReportDate, -- ����������������   
           A.BaseDate, -- ��������   
             
           A.ChangeRequestSeq,   
           F.ChangeRequestRecvSeq,   
           G.TaskOrderSeq,    
           H.FinalReportSeq   
             
      FROM KPXCM_TEQChangeRequestCHE                AS A   
      LEFT OUTER JOIN _TDAUMinor                    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMPlantType )   
      LEFT OUTER JOIN _TDAUMinor                    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMChangeType )   
      LEFT OUTER JOIN _TDADept                      AS D ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq )   
      LEFT OUTER JOIN _TDAEmp                       AS E ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.EmpSeq )   
      LEFT OUTER JOIN KPXCM_TEQChangeRequestRecv    AS F ON ( F.CompanySeq = @CompanySeq AND F.ChangeRequestSeq = A.ChangeRequestSeq )   
      LEFT OUTER JOIN KPXCM_TEQTaskOrderCHE         AS G ON ( G.CompanySeq = @CompanySeq AND G.ChangeRequestSeq = A.ChangeRequestSeq )   
      LEFT OUTER JOIN KPXCM_TEQChangeFinalReport    AS H ON ( H.CompanySeq = @CompanySeq AND H.ChangeRequestSeq = A.ChangeRequestSeq )   
     WHERE A.CompanySeq = @CompanySeq    
       AND ( @Plant = 0 OR A.UMPlantType = @Plant )   
       AND ( A.BaseDate BETWEEN @BaseDateFr AND @BaseDateTo )   
       AND ( @ChangeRequestNo = '' OR A.ChangeRequestNo LIKE @ChangeRequestNo + '%' )   
         AND ( @UMChangeType = 0 OR A.UMChangeType = @UMChangeType )   
       AND ( @Title = '' OR A.Title LIKE @Title + '%' )   
       AND ( @EmpSeq = 0 OR A.EmpSeq = @EmpSeq )   
       AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq )   
      
    RETURN    