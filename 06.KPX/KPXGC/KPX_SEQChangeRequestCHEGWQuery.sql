
IF OBJECT_ID('KPX_SEQChangeRequestCHEGWQuery') IS NOT NULL 
    DROP PROC KPX_SEQChangeRequestCHEGWQuery
GO 

-- v2014.12.11 

-- �����Ƿڼ� GW ��ȸSP by����õ 
CREATE PROC KPX_SEQChangeRequestCHEGWQuery
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT             = 0,    
     @ServiceSeq     INT             = 0,    
     @WorkingTag     NVARCHAR(10)    = '',    
     @CompanySeq     INT             = 1,    
     @LanguageSeq    INT             = 1,    
     @UserSeq        INT             = 0,    
     @PgmSeq         INT             = 0    
 AS    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle          INT,    
            @ChangeRequestSeq   INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    
    
    SELECT  @ChangeRequestSeq    = ISNULL(ChangeRequestSeq,0) 
      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
      WITH  (ChangeRequestSeq INT)       
    
    SELECT A.ChangeRequestSeq,  
           A.ChangeRequestNo,  -- ��û��ȣ 
           A.BaseDate,  -- ��û���� 
           F.WkDeptSeq    ,  
           F.WkDeptName   ,  -- ��û���� �ٹ��μ�    
           A.DeptSeq,  
           A.EmpSeq,  
           E.EmpName, -- ��û�� 
           F.UMJdSeq       ,
           F.UMJdName      , -- ��å 
           A.Title,  -- ����
           A.UMChangeType,  
           H.MinorName          AS UMChageTypeName,  -- ���汸�� 
           A.UMChangeReson,  
           R.MinorName          AS UMChangeResonName,  -- ������� 
           A.UMPlantType,  
           P.MinorName          AS UMPlantTypeName,  -- PLANT���� 
           A.Purpose,  -- �������
           A.Remark,  -- ���泻�� 
           A.Effect,  
           
           -- ÷���ڷ� 
           A.ISPID,  -- P&ID
           A.IsInstrument,  -- InstrumentList
           A.IsField,  -- ���彺��ġ ����
           A.IsPlot,  -- Plot Plan
           A.IsDange,  -- ���輺�򰡼�
           A.IsConce,  -- Conceptual DWG
           A.IsISO,  -- ISO DWG
           A.IsEquip,  -- Equipment List
           A.Etc,  -- ��Ÿ
           A.FileSeq, 
           G.FileName 
      FROM KPX_TEQChangeRequestCHE  AS A  
      LEFT OUTER JOIN _TDADept      AS D ON ( D.CompanySeq = A.CompanySeq AND D.DeptSeq= A.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp       AS E ON ( E.CompanySeq = A.CompanySeq AND E.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS H ON ( H.CompanySeq = A.CompanySeq AND H.MinorSeq = A.UMChangeType ) 
      LEFT OUTER JOIN _TDAUMinor    AS R ON ( R.CompanySeq = A.CompanySeq AND R.MinorSeq = A.UMChangeReson ) 
      LEFT OUTER JOIN _TDAUMinor    AS P ON ( P.CompanySeq = A.CompanySeq AND P.MinorSeq = A.UMPlantType ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS F ON ( F.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN KPXDEVCommon.dbo._TCAAttachFileData AS G ON ( G.AttachFileSeq = A.FileSeq ) 
      
      
  WHERE A.CompanySeq = @CompanySeq  
    AND A.ChangeRequestSeq = @ChangeRequestSeq  
    RETURN
    





ISPID : P&ID
IsInstrument : InstrumentList
IsField : ���彺��ġ ����
IsPlot : Plot Plan
IsDange : ���輺�򰡼�
IsConce : Conceptual DWG
IsISO : ISO DWG
IsEquip : Equipment List
Etc : ��Ÿ
