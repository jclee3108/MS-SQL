 
IF OBJECT_ID('hencom_SHRCompleteDateListQuery') IS NOT NULL   
    DROP PROC hencom_SHRCompleteDateListQuery  
GO  

-- v2017.08.03
  
-- �Ϸ��ϰ�����Ȳ_hencom-��ȸ by ����õ
CREATE PROC hencom_SHRCompleteDateListQuery  
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

    DECLARE @docHandle      INT,  
            -- ��ȸ����   
            @EndDateFr      NCHAR(8), 
            @EndDateTo      NCHAR(8), 
            @UMCompleteType INT, 
            @DeptSeq        INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @EndDateFr      = ISNULL( EndDateFr     , '' ),  
           @EndDateTo      = ISNULL( EndDateTo     , '' ),  
           @UMCompleteType = ISNULL( UMCompleteType, 0 ),  
           @DeptSeq        = ISNULL( DeptSeq       , 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
             EndDateFr      NCHAR(8), 
             EndDateTo      NCHAR(8), 
             UMCompleteType INT, 
             DeptSeq        INT 
           )    
    
    -- ������ȸ   
    SELECT A.CompleteSeq, 
           A.UMCompleteType, 
           B.MinorName AS UMCompleteTypeName, 
           A.DeptSeq, 
           C.DeptName, 
           A.ManagementAmt, 
           A.AlarmDay, 
           A.SrtDate, 
           A.EndDate, 
           A.Remark, 
           'FrmHRCompleteDate_hencom' AS Pgmid
      FROM hencom_THRCompleteDate   AS A  
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySEq AND B.MinorSeq = A.UMCompleteType ) 
      LEFT OUTER JOIN _TDADept      AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @UMCompleteType = 0 OR A.UMCompleteType = @UMCompleteType ) 
       AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq ) 
       AND ( A.EndDate BETWEEN @EndDateFr AND @EndDateTo ) 
    
    RETURN 