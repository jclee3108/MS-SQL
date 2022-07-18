  
IF OBJECT_ID('KPX_SPRWKEmpOTGroupAppQuerySub') IS NOT NULL   
    DROP PROC KPX_SPRWKEmpOTGroupAppQuerySub  
GO  
  
-- v2014.12.17  
  
-- OT�ϰ���û-�������� by ����õ   
CREATE PROC KPX_SPRWKEmpOTGroupAppQuerySub  
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
            @WkDateFr   NCHAR(8), 
            @WkDateTo   NCHAR(8), 
            @IsCfm      NCHAR(1)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @WkDateFr = ISNULL( WkDateFr, '' ),  
           @WkDateTo = ISNULL( WkDateTo, '' ), 
           @IsCfm    = ISNULL( IsCfm, '0' ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            WkDateFr   NCHAR(8),
            WkDateTo   NCHAR(8), 
            IsCfm      NCHAR(1) 
           )    
    
    SELECT ISNULL(C.CfmCode,'0') AS IsCfm, 
           D.EmpName, 
           D.EmpID, 
           A.EmpSeq, 
           D.DeptName, 
           D.DeptSeq, 
           A.AppDate, -- ��û�� 
           A.AppSeq, 
           B.WkDate, -- �ٹ�����
           B.DTime, -- ��û�ð� 
           A.OTReason, -- ��û���� 
           B.Rem
    
      FROM _TPRWkEmpOTTimeApp                       AS A 
      LEFT OUTER JOIN _TPRWkEmpOTTimeDtl            AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq AND B.AppSeq = A.AppSeq ) 
      LEFT OUTER JOIN _TPRWkEmpOTTimeApp_Confirm    AS C ON ( C.CompanySeq = @CompanySeq AND C.CfmSeq = A.EmpSeq AND C.CfmSerl = A.AppSeq ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS D ON ( D.EmpSeq = A.EmpSeq )
     WHERE A.CompanySeq = @CompanySeq 
       AND B.WkDate BETWEEN @WkDateFr AND @WkDateTo 
       AND (@IsCfm = '0' OR ISNULL(C.CfmCode,'0') = @IsCfm)
    

      
    RETURN  