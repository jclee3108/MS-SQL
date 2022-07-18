
IF OBJECT_ID('KPX_SEQChangeFinalReportGWQuery') IS NOT NULL 
    DROP PROC KPX_SEQChangeFinalReportGWQuery
GO 

-- v2014.12.11 

-- �����۾������� GW ��ȸSP by����õ 
 CREATE PROC KPX_SEQChangeFinalReportGWQuery
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
    
    SELECT  @ChangeRequestSeq = ISNULL(ChangeRequestSeq,0) 
      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH  (ChangeRequestSeq      INT )
    
    SELECT A.CompanySeq
          ,A.ChangeRequestSeq 
          ,A.ChangeRequestNo -- ��û��ȣ 
          ,A.BaseDate -- ��û���� 
          ,A.DeptSeq 
          ,A.EmpSeq
          ,A.Title -- �������� 
          ,A.Purpose -- ������� 
          ,A.Effect
          ,A.Remark -- ���泻�� 
          ,B.FinalReportSeq 
          ,B.ReportDate -- ����Ϸ��� 
          ,B.FileSeq -- ÷������ 
          ,G.FileName  
          
          
          ,B.ISPID  -- P&ID
          ,B.IsInstrument  -- InstrumentList 
          ,B.IsField  -- ���彺��ġ ����
          ,B.IsPlot  -- Plot Plan
          ,B.IsDange  -- ���輺�򰡼�
          ,B.IsConce  -- Conceptual DWG
          ,B.IsISO  -- ISO DWG
          ,B.IsEquip  -- Equipment List
          ,B.Etc  -- ��Ÿ 
          ,B.IsTaskOrder  -- ������伭 
          
      FROM KPX_TEQChangeRequestCHE              AS A
      LEFT OUTER JOIN KPX_TEQChangeFinalReport  AS B ON ( B.CompanySeq = @CompanySeq AND A.ChangeRequestSeq = B.ChangeRequestSeq ) 
      LEFT OUTER JOIN KPXDEVCommon.dbo._TCAAttachFileData AS G ON ( G.AttachFileSeq = B.FileSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.ChangeRequestSeq = @ChangeRequestSeq
    
    RETURN
    
    
    








