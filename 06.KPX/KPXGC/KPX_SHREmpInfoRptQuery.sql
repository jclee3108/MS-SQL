
IF OBJECT_ID('KPX_SHREmpInfoRptQuery') IS NOT NULL 
    DROP PROC KPX_SHREmpInfoRptQuery
GO
 
/************************************************************                
 ��    �� - �����λ��̷�ī�� ���         
 �� �� �� - 20111116              
 �� �� �� - �� �� ��  
 �� �� �� - �� �� â             
************************************************************/                
CREATE PROC KPX_SHREmpInfoRptQuery
 @xmlDocument    NVARCHAR(MAX),    -- ȭ���� ������ XML�� ����            
    @xmlFlags       INT = 0,          -- �ش� XML�� TYPE    
    @ServiceSeq     INT = 0,          -- ���� ��ȣ    
    @WorkingTag     NVARCHAR(10)= '', -- ��ŷ �±�    
    @CompanySeq     INT = 1,          -- ȸ�� ��ȣ    
    @LanguageSeq    INT = 1,          -- ��� ��ȣ    
    @UserSeq        INT = 0,          -- ����� ��ȣ    
    @PgmSeq         INT = 0           -- ���α׷� ��ȣ    
AS                
               
    DECLARE @docHandle  INT, --XML�� �ڵ��� ��������                
   @EmpSeq   INT -- ���  
   
       
 --XML�Ľ�    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument -- @xmlDocument�� XML�� @docHandle�� �ڵ��Ѵ�.                   
           
    SELECT @EmpSeq = ISNULL(EmpSeq, 0)   -- ���  
            
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags) --XML�� DataBlock1�� ����               
      WITH (EmpSeq INT)    
          
    -- �Ľ̵� XML�� �����͸� ������� �ӽ����̺� ����      
    --CREATE TABLE #THREmp (WorkingTag NCHAR(1) NULL)      
      
    ---- XML�� DataBlock1�����͸� �ӽ����̺� �ִ´�.      
    --EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#THREmp' --�������� �����Ͱ��� xml�� ������ �ӽ����̺� #THREmp       
      
    IF @@ERROR <> 0      
    BEGIN      
        RETURN    -- ������ �߻��ϸ� ����      
    END      
        
--select * from #THREmp  
      
    --select * from _TPRRetmst  
    --totRetAmt  --������  
  
    CREATE TABLE #TempMaster(  
   EmpSeq    INT NULL   ,    
   EmpName    NVARCHAR(50) NULL ,    
   Photo    NVARCHAR(MAX) NULL ,    
   LenPhoto            INT                 , --��������  
   BirthDate   NCHAR(8) NULL  , --����    
   EntDate    NCHAR(8) NULL  , --�Ի���     
   DeptName   NVARCHAR(50) NULL , --�μ�    
   UMPgName   NVARCHAR(50) NULL , --����  
   UmjoName   NVARCHAR(50) NULL , --����  
   JobName    NVARCHAR(50) NULL , --����   
   ResidId    NVARCHAR(50) NULL , --�ֹε�Ϲ�ȣ  
   EntDetails   NVARCHAR(50) NULL , --�Ի����  
   IsMarriage   NCHAR(1) NULL  , --��ȥ����    
   Addr    NVARCHAR(1000) NULL ,  
            Bon1     NVARCHAR(50) NULL , --����  
   UMReligion   NVARCHAR(50) NULL ,   
   Hobby    NVARCHAR(50) NULL ,     
   Speciality   NVARCHAR(50) NULL ,    
   Height    DECIMAL(19,5) NULL ,    
   Weight    DECIMAL(19,5) NULL ,    
   EyeLt    DECIMAL(19,5) NULL ,    
   EyeRt    DECIMAL(19,5) NULL ,  
   SMBloodTypeName  NVARCHAR(50) NULL , --������  
   Won     NVARCHAR(50) NULL ,  --����  
   Zip     NVARCHAR(50) NULL ,  
   BirthPlace   NVARCHAR(50) NULL ,  --�����  
   Type    NVARCHAR(50) NULL ,  --����  
   Relation   NVARCHAR(50) NULL ,  --����  
   Reason    NVARCHAR(50) NULL ,  --����  
   QrtDate    NCHAR(8) NULL  ,   
   NewsDate   NCHAR(8) NULL  ,   
   NewsContents  NVARCHAR(50) NULL ,   
   RelationP   NVARCHAR(50) NULL ,   
   UmmilRnkname  NVARCHAR(50) NULL ,  --����   
   UmmilKindname  NVARCHAR(50) NULL ,  --���  
   UmmilBrnchname  NVARCHAR(50) NULL ,  --����    
   MilSoldierNo  NVARCHAR(50) NULL ,  --����  
   MilEnrdDate   NCHAR(8) NULL  , --�����Ⱓ  
   MilExBegDate  NCHAR(8) NULL  , --ó����    
   MilCfm    NVARCHAR(50) NULL , --�����ڰ�  
   MilEdu    NVARCHAR(50) NULL , --��������   
   MilExEndDate  NCHAR(8) NULL  , --�ٹ�������   
   MilinCompletion  NVARCHAR(50) NULL , --�ǿ�������  
   UmmilclsName  NVARCHAR(50) NULL , --����   
   UmmilVet   NVARCHAR(50) NULL , --����  
   MilCivil   NVARCHAR(50) NULL , --�ι���  
   MilEtc    NVARCHAR(50) NULL ,  --��Ÿ  
   BonAddr    NVARCHAR(1000) NULL ,  
   /*�з�*/  
   EtcSchNm1   NVARCHAR(100) NULL , --EtcSchNm1  
   EtcSchNm2   NVARCHAR(100) NULL , --EtcSchNm2  
   EtcSchNm3   NVARCHAR(100) NULL , --EtcSchNm3  
   EtcSchNm4   NVARCHAR(100) NULL , --EtcSchNm4  
   EtcSchNm5   NVARCHAR(100) NULL , --EtcSchNm5  
   PeriodDate1   NVARCHAR(100) NULL , --PeriodDate1  
     PeriodDate2   NVARCHAR(100) NULL , --PeriodDate2  
   PeriodDate3   NVARCHAR(100) NULL , --PeriodDate3  
   PeriodDate4   NVARCHAR(100) NULL , --PeriodDate4  
   PeriodDate5   NVARCHAR(100) NULL , --PeriodDate5  
   MajorName1   NVARCHAR(100) NULL , --Major1  
   MajorName2   NVARCHAR(100) NULL , --Major2  
   MajorName3   NVARCHAR(100) NULL , --Major3  
   MajorName4   NVARCHAR(100) NULL , --Major4  
   MajorName5   NVARCHAR(100) NULL , --Major5  
   UMSchCreer1   NVARCHAR(100) NULL , --UMSchCreer1  
   UMSchCreer2   NVARCHAR(100) NULL , --UMSchCreer2  
   UMSchCreer3   NVARCHAR(100) NULL , --UMSchCreer3  
   UMSchCreer4   NVARCHAR(100) NULL , --UMSchCreer4  
   UMSchCreer5   NVARCHAR(100) NULL , --UMSchCreer5  
   SLoc1    NVARCHAR(100) NULL , --Local1  
   SLoc2    NVARCHAR(100) NULL , --Local2  
   SLoc3    NVARCHAR(100) NULL , --Local3  
   SLoc4    NVARCHAR(100) NULL , --Local4  
   SLoc5    NVARCHAR(100) NULL  , --Local5  
   /*����ڰ�*/  
   UMLicName1   NVARCHAR(100) NULL  , --UMLicName1  
   UMLicName2   NVARCHAR(100) NULL  , --UMLicName2  
   UMLicName3   NVARCHAR(100) NULL  , --UMLicName3  
   UMLicName4   NVARCHAR(100) NULL  , --UMLicName4  
   UMLicName5   NVARCHAR(100) NULL  , --UMLicName5  
   PosName1   NVARCHAR(50) NULL   , --PosName1  
   PosName2   NVARCHAR(50) NULL   , --PosName2  
   PosName3   NVARCHAR(50) NULL   , --PosName3  
   PosName4   NVARCHAR(50) NULL   , --PosName4  
   PosName5   NVARCHAR(50) NULL   , --PosName5  
   LicNo1    NVARCHAR(50) NULL   , --LicNo1  
   LicNo2    NVARCHAR(50) NULL   , --LicNo2  
   LicNo3    NVARCHAR(50) NULL   , --LicNo3  
   LicNo4    NVARCHAR(50) NULL   , --LicNo4  
   LicNo5    NVARCHAR(50) NULL   , --LicNo5  
   AcqDate1   NCHAR(8) NULL     , -- AcqDate1  
   AcqDate2   NCHAR(8) NULL     , -- AcqDate2  
   AcqDate3   NCHAR(8) NULL     , -- AcqDate3  
   AcqDate4   NCHAR(8) NULL     , -- AcqDate4  
   AcqDate5   NCHAR(8) NULL     , -- AcqDate5  
   IssueInst1   NVARCHAR(100) NULL  , --IssueInst1  
   IssueInst2   NVARCHAR(100) NULL  , --IssueInst2  
   IssueInst3   NVARCHAR(100) NULL  , --IssueInst3  
   IssueInst4   NVARCHAR(100) NULL  , --IssueInst4  
   IssueInst5   NVARCHAR(100) NULL  , --IssueInst5  
   /*�������*/  
   CoNm1    NVARCHAR(100) NULL  , --CoNm1  
   CoNm2    NVARCHAR(100) NULL  , --CoNm2  
   CoNm3    NVARCHAR(100) NULL  , --CoNm3  
   CoNm4    NVARCHAR(100) NULL  , --CoNm4  
   CoNm5    NVARCHAR(100) NULL  , --CoNm5  
   CoNm6    NVARCHAR(100) NULL  , --CoNm6  
   CarPeriodDate1      NVARCHAR(50)  NULL  , --CarPeriodDate1  
   CarPeriodDate2      NVARCHAR(50)  NULL  , --CarPeriodDate2  
   CarPeriodDate3      NVARCHAR(50)  NULL  , --CarPeriodDate3  
   CarPeriodDate4      NVARCHAR(50)  NULL  , --CarPeriodDate4  
   CarPeriodDate5      NVARCHAR(50)  NULL  , --CarPeriodDate5  
   CarPeriodDate6      NVARCHAR(50)  NULL  , --CarPeriodDate6  
   JpName1    NVARCHAR(100) NULL  , --JpName1  
   JpName2    NVARCHAR(100) NULL  , --JpName2  
   JpName3    NVARCHAR(100) NULL  , --JpName3  
   JpName4    NVARCHAR(100) NULL  , --JpName4  
   JpName5    NVARCHAR(100) NULL  , --JpName5  
   JpName6    NVARCHAR(100) NULL  , --JpName6  
   BusType1   NVARCHAR(100) NULL  , --BusType1  
   BusType2   NVARCHAR(100) NULL  , --BusType2  
   BusType3   NVARCHAR(100) NULL  , --BusType3  
   BusType4   NVARCHAR(100) NULL  , --BusType4  
   BusType5   NVARCHAR(100) NULL  , --BusType5  
   BusType6   NVARCHAR(100) NULL  , --BusType6  
   UMRetReasonName1 NVARCHAR(100) NULL  , --UMRetReasonName1  
   UMRetReasonName2 NVARCHAR(100) NULL  , --UMRetReasonName2  
   UMRetReasonName3 NVARCHAR(100) NULL  , --UMRetReasonName3  
   UMRetReasonName4 NVARCHAR(100) NULL  , --UMRetReasonName4  
   UMRetReasonName5 NVARCHAR(100) NULL  , --UMRetReasonName5  
   UMRetReasonName6 NVARCHAR(100) NULL  , --UMRetReasonName6  
   Area1    NVARCHAR(1000) NULL  , --Area1  
   Area2    NVARCHAR(1000) NULL  , --Area2  
   Area3    NVARCHAR(1000) NULL  , --Area3  
   Area4    NVARCHAR(1000) NULL  , --Area4  
   Area5    NVARCHAR(1000) NULL  , --Area5  
   Area6    NVARCHAR(1000) NULL  , --Area6  
   /*����/����*/  
   PrzPnlToDate1  NCHAR(8)   NULL ,  --PrzPnlToDate1  
   PrzPnlToDate2  NCHAR(8)   NULL ,  --PrzPnlToDate2  
   PrzPnlToDate3  NCHAR(8)   NULL ,  --PrzPnlToDate3  
   PrzPnlToDate4  NCHAR(8)   NULL ,  --PrzPnlToDate4  
   PrzPnlToDate5  NCHAR(8)   NULL ,  --PrzPnlToDate5  
   PrzPnlToDate6  NCHAR(8)   NULL ,  --PrzPnlToDate6  
   PrzPnlToDate7  NCHAR(8)   NULL ,  --PrzPnlToDate7  
   PrzPnlToDate8  NCHAR(8)   NULL ,  --PrzPnlToDate8  
   PrzPnlToDate9  NCHAR(8)   NULL ,  --PrzPnlToDate9  
   PrzPnlToDate10  NCHAR(8)   NULL ,  --PrzPnlToDate10  
   UMPrzPnlName1  NVARCHAR(50)  NULL  ,  --UMPrzPnlName1  
   UMPrzPnlName2  NVARCHAR(50)  NULL  ,  --UMPrzPnlName2  
   UMPrzPnlName3  NVARCHAR(50)  NULL  ,  --UMPrzPnlName3  
   UMPrzPnlName4  NVARCHAR(50)  NULL  ,  --UMPrzPnlName4  
   UMPrzPnlName5  NVARCHAR(50)  NULL  ,  --UMPrzPnlName5  
   UMPrzPnlName6  NVARCHAR(50)  NULL  ,  --UMPrzPnlName6  
   UMPrzPnlName7  NVARCHAR(50)  NULL  ,  --UMPrzPnlName7  
   UMPrzPnlName8  NVARCHAR(50)  NULL  ,  --UMPrzPnlName8  
   UMPrzPnlName9  NVARCHAR(50)  NULL  ,  --UMPrzPnlName9  
   UMPrzPnlName10  NVARCHAR(50)  NULL  ,  --UMPrzPnlName10  
   PrzPnlReason1  NVARCHAR(200) NULL ,  --PrzPnlReason1  
   PrzPnlReason2  NVARCHAR(200) NULL ,  --PrzPnlReason2  
   PrzPnlReason3  NVARCHAR(200) NULL ,  --PrzPnlReason3  
   PrzPnlReason4  NVARCHAR(200) NULL ,  --PrzPnlReason4  
   PrzPnlReason5  NVARCHAR(200) NULL ,  --PrzPnlReason5  
   PrzPnlReason6  NVARCHAR(200) NULL ,  --PrzPnlReason6  
   PrzPnlReason7  NVARCHAR(200) NULL ,  --PrzPnlReason7  
   PrzPnlReason8  NVARCHAR(200) NULL ,  --PrzPnlReason8  
   PrzPnlReason9  NVARCHAR(200) NULL ,  --PrzPnlReason9  
   PrzPnlReason10  NVARCHAR(200) NULL ,  --PrzPnlReason10  
   /*¡��,����*/  
   PrnRlnlFrDate1  NCHAR(8)   NULL ,  --PrzPnlFrDate1  
   PrnRlnlFrDate2  NCHAR(8)   NULL ,  --PrzPnlFrDate1  
   PrnRlnlFrDate3  NCHAR(8)   NULL ,  --PrzPnlFrDate1  
   UMPnlName1   NVARCHAR(50)  NULL  ,  --UMPnlName1  
   UMPnlName2   NVARCHAR(50)  NULL  ,  --UMPnlName2  
   UMPnlName3   NVARCHAR(50)  NULL  ,  --UMPnlName3  
   PnlReason1   NVARCHAR(2000) NULL ,  --PnlReason1  
   PnlReason2   NVARCHAR(2000) NULL ,  --PnlReason2  
   PnlReason3   NVARCHAR(2000) NULL ,  --PnlReason3  
   /*�ؿܿ���*/  
   CName1    NVARCHAR(100) NULL  ,  --CName1  
   CName2    NVARCHAR(100) NULL  ,  --CName2  
   CName3    NVARCHAR(100) NULL  ,  --CName3  
   CName4    NVARCHAR(100) NULL  ,  --CName4  
   CName5    NVARCHAR(100) NULL  ,  --CName5  
   CPeriod1   NVARCHAR(100) NULL  ,  --CPeriod1  
   CPeriod2   NVARCHAR(100) NULL  ,  --CPeriod2  
   CPeriod3   NVARCHAR(100) NULL  ,  --CPeriod3  
   CPeriod4   NVARCHAR(100) NULL  ,  --CPeriod4  
   CPeriod5   NVARCHAR(100) NULL  ,  --CPeriod5  
   CReason1   NVARCHAR(100) NULL  ,  --CReason1  
   CReason2   NVARCHAR(100) NULL  ,  --CReason2  
   CReason3   NVARCHAR(100) NULL  ,  --CReason3  
   CReason4   NVARCHAR(100) NULL  ,  --CReason4  
   CReason5   NVARCHAR(100) NULL  ,  --CReason5  
   /*�����Ʒ�*/  
   EtcCourseName1  NVARCHAR(200) NULL ,  --EtcCourseName1  
   EtcCourseName2  NVARCHAR(200) NULL ,  --EtcCourseName2  
   EtcCourseName3  NVARCHAR(200) NULL ,  --EtcCourseName3  
   EtcCourseName4  NVARCHAR(200) NULL ,  --EtcCourseName4  
   EtcCourseName5  NVARCHAR(200) NULL ,  --EtcCourseName5  
   EduPeriod1   NVARCHAR(100) NULL ,  --EduPeriod1  
   EduPeriod2   NVARCHAR(100) NULL ,  --EduPeriod2  
   EduPeriod3   NVARCHAR(100) NULL ,  --EduPeriod3  
   EduPeriod4   NVARCHAR(100) NULL ,  --EduPeriod4  
   EduPeriod5   NVARCHAR(100) NULL ,  --EduPeriod5  
   EtcInstitute1  NVARCHAR(100) NULL ,  --EtcInstitute1  
   EtcInstitute2  NVARCHAR(100) NULL ,  --EtcInstitute2  
   EtcInstitute3  NVARCHAR(100) NULL ,  --EtcInstitute3  
   EtcInstitute4  NVARCHAR(100) NULL ,  --EtcInstitute4  
   EtcInstitute5  NVARCHAR(100) NULL ,  --EtcInstitute5  
   RstRem1    NVARCHAR(200) NULL ,  --RstRem1  
   RstRem2    NVARCHAR(200) NULL ,  --RstRem2  
   RstRem3    NVARCHAR(200) NULL ,  --RstRem3  
   RstRem4    NVARCHAR(200) NULL ,  --RstRem4  
     RstRem5    NVARCHAR(200) NULL ,  --RstRem5  
   /*��������*/  
   RestDate1   NVARCHAR(100) NULL  , --RestDate1  
   RestDate2   NVARCHAR(100) NULL  , --RestDate2  
   RestReason1   NVARCHAR(100) NULL  , --RestReason1  
   RestReason2   NVARCHAR(100) NULL  , --RestReason2  
   RestRemark1   NVARCHAR(100) NULL  , --RestRemark1  
   RestRemark2   NVARCHAR(100) NULL  , --RestRemark2  
   /*��������*/  
   RetDate1   NCHAR(8)   NULL ,  --RetDate  
   WkTrm1    NCHAR(6)   NULL ,  --WkTrm  
   RetCause1   NVARCHAR(100) NULL ,  --RetCause  
   totRetAmt1   DECIMAL(19,5) NULL ,  --totRetAmt  
   EmpPhone   NVARCHAR(50)  NULL ,  --EmpPhone  
   /*�߷ɻ���*/  
   OrdDate1   NCHAR(8)   NULL ,  -- OrdDate1  
   OrdDate2   NCHAR(8)   NULL ,  -- OrdDate2  
   OrdDate3   NCHAR(8)   NULL ,  -- OrdDate3  
   OrdDate4   NCHAR(8)   NULL ,  -- OrdDate4  
   OrdDate5   NCHAR(8)   NULL ,  -- OrdDate5  
   OrdDate6   NCHAR(8)   NULL ,  -- OrdDate6  
   OrdDate7   NCHAR(8)   NULL ,  -- OrdDate7  
   OrdDate8   NCHAR(8)   NULL ,  -- OrdDate8  
   OrdDate9   NCHAR(8)   NULL ,  -- OrdDate9  
   OrdDate10   NCHAR(8)   NULL ,  -- OrdDate10  
   OrdDate11   NCHAR(8)   NULL ,  -- OrdDate11  
   OrdDate12   NCHAR(8)   NULL ,  -- OrdDate12  
   OrdDate13   NCHAR(8)   NULL ,  -- OrdDate13  
   OrdDate14   NCHAR(8)   NULL ,  -- OrdDate14  
   OrdDate15   NCHAR(8)   NULL ,  -- OrdDate15  
   OrdDate16   NCHAR(8)   NULL ,  -- OrdDate16  
   OrdDate17   NCHAR(8)   NULL ,  -- OrdDate17  
   OrdDate18   NCHAR(8)   NULL ,  -- OrdDate18  
   OrdDate19   NCHAR(8)   NULL ,  -- OrdDate19  
   OrdDate20   NCHAR(8)   NULL ,  -- OrdDate20  
   OrdDate21   NCHAR(8)   NULL ,  -- OrdDate21  
   OrdDate22   NCHAR(8)   NULL ,  -- OrdDate22  
   OrdDate23   NCHAR(8)   NULL ,  -- OrdDate23  
   OrdDate24   NCHAR(8)   NULL ,  -- OrdDate24  
   OrdDate25   NCHAR(8)   NULL ,  -- OrdDate25  
   OrdDate26   NCHAR(8)   NULL ,  -- OrdDate26  
   OrdDate27   NCHAR(8)   NULL ,  -- OrdDate27  
   Remark1    NVARCHAR(1000) NULL ,  -- Remark1  
   Remark2    NVARCHAR(1000) NULL ,  -- Remark2  
   Remark3    NVARCHAR(1000) NULL ,  -- Remark3  
   Remark4    NVARCHAR(1000) NULL ,  -- Remark4  
   Remark5    NVARCHAR(1000) NULL ,  -- Remark5  
   Remark6    NVARCHAR(1000) NULL ,  -- Remark6  
   Remark7    NVARCHAR(1000) NULL ,  -- Remark7  
   Remark8    NVARCHAR(1000) NULL ,  -- Remark8  
   Remark9    NVARCHAR(1000) NULL ,  -- Remark9  
   Remark10   NVARCHAR(1000) NULL ,  -- Remark10  
   Remark11   NVARCHAR(1000) NULL ,  -- Remark11  
   Remark12   NVARCHAR(1000) NULL ,  -- Remark12  
   Remark13   NVARCHAR(1000) NULL ,  -- Remark13  
   Remark14   NVARCHAR(1000) NULL ,  -- Remark14  
   Remark15   NVARCHAR(1000) NULL ,  -- Remark15  
   Remark16   NVARCHAR(1000) NULL ,  -- Remark16  
   Remark17   NVARCHAR(1000) NULL ,  -- Remark17  
   Remark18   NVARCHAR(1000) NULL ,  -- Remark18  
   Remark19   NVARCHAR(1000) NULL ,  -- Remark19  
   Remark20   NVARCHAR(1000) NULL ,  -- Remark20  
   Remark21   NVARCHAR(1000) NULL ,  -- Remark21  
   Remark22   NVARCHAR(1000) NULL ,  -- Remark22  
   Remark23   NVARCHAR(1000) NULL ,  -- Remark23  
   Remark24   NVARCHAR(1000) NULL ,  -- Remark24  
   Remark25   NVARCHAR(1000) NULL ,  -- Remark25  
   Remark26   NVARCHAR(1000) NULL ,  -- Remark26  
   Remark27   NVARCHAR(1000) NULL ,  -- Remark27  
   Contents1   NVARCHAR(1000) NULL  ,  -- Contents1  
   Contents2   NVARCHAR(1000) NULL  ,  -- Contents2  
   Contents3   NVARCHAR(1000) NULL  ,  -- Contents3  
   Contents4   NVARCHAR(1000) NULL  ,  -- Contents4  
   Contents5   NVARCHAR(1000) NULL  ,  -- Contents5  
   Contents6   NVARCHAR(1000) NULL  ,  -- Contents6  
   Contents7   NVARCHAR(1000) NULL  ,  -- Contents7  
   Contents8   NVARCHAR(1000) NULL  ,  -- Contents8  
   Contents9   NVARCHAR(1000) NULL  ,  -- Contents9  
   Contents10   NVARCHAR(1000) NULL  ,  -- Contents10  
   Contents11   NVARCHAR(1000) NULL  ,  -- Contents11  
   Contents12   NVARCHAR(1000) NULL  ,  -- Contents12  
   Contents13   NVARCHAR(1000) NULL  ,  -- Contents13  
   Contents14   NVARCHAR(1000) NULL  ,  -- Contents14  
     Contents15   NVARCHAR(1000) NULL  ,  -- Contents15  
   Contents16   NVARCHAR(1000) NULL  ,  -- Contents16  
   Contents17   NVARCHAR(1000) NULL  ,  -- Contents17  
   Contents18   NVARCHAR(1000) NULL  ,  -- Contents18  
   Contents19   NVARCHAR(1000) NULL  ,  -- Contents19  
   Contents20   NVARCHAR(1000) NULL  ,  -- Contents20  
   Contents21   NVARCHAR(1000) NULL  ,  -- Contents21  
   Contents22   NVARCHAR(1000) NULL  ,  -- Contents22  
   Contents23   NVARCHAR(1000) NULL  ,  -- Contents23  
   Contents24   NVARCHAR(1000) NULL  ,  -- Contents24  
   Contents25   NVARCHAR(1000) NULL  ,  -- Contents25  
   Contents26   NVARCHAR(1000) NULL  ,  -- Contents26  
   Contents27   NVARCHAR(1000) NULL     -- Contents27  
    )  
      
  /*�з� ������ SELECT �Ͽ� #TempSchool�� ����*/  
   SELECT     
    ROW_NUMBER() OVER(ORDER BY ACA.EntYm DESC)     AS ROWNO    ,  
    ISNULL(ESN.MinorName , '')        AS MinorName   , --�б���  
    ISNULL(LTRIM(RTRIM(ACA.EntYm))+ '~'+ LTRIM(RTRIM(ACA.GrdYm)) , '') AS PeriodDate   , --���бⰣ  
    ISNULL(ACA.MajorCourse , '')        AS  Major    , --�����а�  
    ISNULL(UMN.MinorName , '')        AS UMSchCareerName , --���б���  
    ISNULL(ACA.Loc   , '')        AS SLoc      --������  
           INTO #TEMPSCHOOL   
           FROM _TDAEmp AS S  
    --JOIN #THREmp     AS B   ON S.CompanySeq = @CompanySeq  
    --              AND S.EmpSeq     = B.EmpSeq  
    --�з�����   
    LEFT OUTER JOIN _THRBasAcademic AS ACA ON ACA.CompanySeq = S.CompanySeq   
               AND ACA.EmpSeq  = S.EmpSeq   
    --�б���  
    LEFT OUTER JOIN _TDAUMinor  AS ESN ON ACA.CompanySeq = ESN.CompanySeq   
               AND ACA.UMSchSeq  = ESN.MinorSeq   
    --���б���  
    LEFT OUTER JOIN _TDAUMinor  AS UMN ON ACA.CompanySeq  = UMN.CompanySeq   
               AND ACA.UMSchCareerSeq = UMN.MinorSeq  
   WHERE  S.CompanySeq  = @CompanySeq     
     AND  (@EmpSeq = 0     OR S.EmpSeq  = @EmpSeq)    
            
  /*��� �ڰ� ������ SELECT �Ͽ� #TempLicense�� ����*/                 
  SELECT     
    ROW_NUMBER() OVER(ORDER BY LII.AcqDate DESC)AS ROWNO  ,  
    ISNULL(ULN.MinorName , '')    AS UMLicName , --��Ī  
    ISNULL(LII.LicenseSeq , '')    AS PosName  , --���  
    ISNULL(LII.LicNo  , '')    AS  LicNo  , --��ȣ  
    ISNULL(LII.AcqDate  , '')    AS AcqDate     , --�����  
    ISNULL(LII.IssueInst , '')    AS IssueInst   --����ó  
          INTO #TempLicense   
          FROM _TDAEmp AS CA  
    --JOIN #THREmp        AS B   ON CA.CompanySeq = @CompanySeq  
    --              AND CA.EmpSeq     = B.EmpSeq  
    JOIN _fnadmEmpOrd(@CompanySeq, '') AS C   ON CA.CompanySeq = @CompanySeq    
                  AND CA.EmpSeq     = C.EmpSeq   
    --�ڰ�����  
    LEFT OUTER JOIN _THRBasLicense    AS LII  ON LII.CompanySeq = CA.CompanySeq   
                  AND LII.EmpSeq   = CA.EmpSeq  
    --�ڰݸ�Ī  
    LEFT OUTER JOIN _TDAUMinor     AS ULN  ON LII.CompanySeq = ULN.CompanySeq   
                  AND LII.UMLicSeq   = ULN.MinorSeq  
   WHERE  CA.CompanySeq  = @CompanySeq     
    AND  (@EmpSeq = 0     OR CA.EmpSeq  = @EmpSeq)    
                  
  /*���� ��� ������ SELECT �Ͽ� #TempCareer�� ����*/   
  SELECT     
    ROW_NUMBER() OVER(ORDER BY TCA.EntDate DESC)     AS ROWNO    ,  
    ISNULL(TCA.CoNm   , '')         AS CoNm    , --ȸ���  
    ISNULL(LTRIM(RTRIM(TCA.EntDate))+ '~'+ LTRIM(RTRIM(TCA.RetDate)) , '') AS CPeriodDate  , --�ٹ��Ⱓ  
    ISNULL(TCA.JpName  , '')         AS  JpName   , --����/����  
    ISNULL(TCA.BusType  , '')         AS BusType   , --����  
    ISNULL(UMRS.MinorName , '')         AS UMRetReasonName    , --��������  
    ISNULL(TCA.Area   , '')         AS Area      --������  
          INTO #TempCareer   
          FROM _TDAEmp AS A  
    --JOIN #THREmp      AS B   ON A.CompanySeq = @CompanySeq  
    --             AND A.EmpSeq     = B.EmpSeq  
    --�������  
    LEFT OUTER JOIN _THRBasCareer AS TCA  ON TCA.CompanySeq = A.CompanySeq   
                 AND TCA.EmpSeq  = A.EmpSeq  
    --��������  
    LEFT OUTER JOIN _TDAUMinor   AS UMRS ON TCA.CompanySeq  = UMRS.CompanySeq   
              AND TCA.UMRetReason = UMRS.MinorSeq  
   WHERE  A.CompanySeq  = @CompanySeq     
       AND  (@EmpSeq = 0     OR A.EmpSeq  = @EmpSeq)                
    
  /*������ ������ SELECT �Ͽ� #TempPrize�� ����*/   
  SELECT     
    ROW_NUMBER() OVER(ORDER BY TP.PrzPnlToDate DESC) AS ROWNO   ,  
    ISNULL(TP.PrzPnlToDate  , '')    AS PrzPnlToDate , --������(�����������)  
    ISNULL(UMPN.MinorName  , '')    AS UMPrzPnlName , --����  
    ISNULL(TP.PrzPnlReason  , '')    AS PrzPnlReason   --����  
          INTO #TempPrize   
          FROM _TDAEmp AS A  
    --JOIN #THREmp      AS B   ON A.CompanySeq = @CompanySeq  
    --          AND A.EmpSeq     = B.EmpSeq  
    --����  
    LEFT OUTER JOIN _THRBasPrzPnl AS TP   ON TP.CompanySeq = A.CompanySeq   
                 AND TP.EmpSeq    = A.EmpSeq  
    --��������  
    LEFT OUTER JOIN _TDAUMinor   AS UMPN ON TP.CompanySeq  = UMPN.CompanySeq   
              AND TP.UMPrzPnlSeq = UMPN.MinorSeq  
  WHERE  TP.SMPrzPnlType =  3057001   --���� ������ ���� �˻�����  
    AND  (@EmpSeq = 0     OR A.EmpSeq  = @EmpSeq)  
    AND  A.CompanySeq  = @CompanySeq  
    
  /*¡������*/  
  SELECT     
    ROW_NUMBER() OVER(ORDER BY TP.PrzPnlToDate DESC) AS ROWNO   ,  
    ISNULL(TP.PrzPnlFrDate  , '')    AS PrzPnlToDate , --¡����(¡���������)  
    ISNULL(UMPN.MinorName  , '')    AS UMPnlName , --����  
    ISNULL(TP.PrzPnlReason  , '')    AS PnlReason   --����  
          INTO #TempPnl   
          FROM _TDAEmp AS A  
    --JOIN #THREmp      AS B   ON A.CompanySeq = @CompanySeq  
    --          AND A.EmpSeq     = B.EmpSeq  
    --����  
    LEFT OUTER JOIN _THRBasPrzPnl AS TP   ON TP.CompanySeq = A.CompanySeq   
                 AND TP.EmpSeq    = A.EmpSeq  
    --��������  
    LEFT OUTER JOIN _TDAUMinor   AS UMPN ON TP.CompanySeq  = UMPN.CompanySeq   
              AND TP.UMPrzPnlSeq = UMPN.MinorSeq  
  WHERE   TP.SMPrzPnlType =  3057003   
    AND  (@EmpSeq = 0     OR A.EmpSeq  = @EmpSeq)  
    AND   A.CompanySeq  = @CompanySeq   
                   
    
  /*�߷� ������ SELECT �Ͽ� #TempOrdEmp�� ����*/               
  SELECT     
    ROW_NUMBER() OVER(ORDER BY OE.OrdDate DESC)  AS ROWNO ,  
    ISNULL(OE.OrdDate   , '')    AS OrdDate , --�߷���  
    ISNULL(OE.Remark   , '')    AS Remark , --�߷ɹ�ȣ  
    ISNULL(OE.Contents   , '')    AS Contents   --�Ӹ鳻��  
          INTO #TempOrdEmp   
          FROM _TDAEmp AS A  
    --JOIN #THREmp      AS B  ON A.CompanySeq = @CompanySeq  
    --           AND A.EmpSeq     = B.EmpSeq  
    --�߷�����  
    LEFT OUTER JOIN _THRAdmOrdEmp AS OE ON OE.CompanySeq = A.CompanySeq   
               AND OE.EmpSeq  = A.EmpSeq  
               AND OE.Remark <> ''  
  WHERE  A.CompanySeq  = @CompanySeq     
    AND  (@EmpSeq = 0     OR A.EmpSeq  = @EmpSeq)    
      
  /*�ؿܿ���*/  
  SELECT     
    ROW_NUMBER() OVER(ORDER BY EP.EduEndDate )  AS ROWNO ,  
    ISNULL('������' , '')   AS CName , --������  
    ISNULL(LTRIM(RTRIM(EP.EduBegDate))+ '~'+ LTRIM(RTRIM(EP.EduEndDate)) , '')  AS CPeriod , --�����Ⱓ  
    ISNULL('����'  , '')    AS CReason  --����  
          INTO #TempCountryEdu  
          FROM _TDAEmp AS A  
    --JOIN #THREmp     AS B  ON A.CompanySeq = @CompanySeq  
    --             AND A.EmpSeq     = B.EmpSeq  
    --��������  
    LEFT OUTER JOIN  _THREduPersRst AS EP ON EP.CompanySeq = A.CompanySeq   
              AND EP.EmpSeq    = A.EmpSeq  
          
  WHERE  UMEduGrpType = 3908005   
    AND  (@EmpSeq = 0     OR A.EmpSeq  = @EmpSeq)  
    AND  A.CompanySeq  = @CompanySeq  
    
  /*�����Ʒ�*/  
  SELECT     
    ROW_NUMBER() OVER(ORDER BY EP.EduEndDate )  AS ROWNO   ,  
    ISNULL(EP.EtcCourseName , '')    AS EtcCourseName , --��������  
    ISNULL(LTRIM(RTRIM(EP.EduBegDate))+ '~'+ LTRIM(RTRIM(EP.EduEndDate)) , '')  AS EduPeriod , --�����Ⱓ  
    ISNULL(EP.EtcInstitute , '')    AS EtcInstitute ,   --�ְ����  
    ISNULL(EP.RstRem  , '')    AS RstRem     --���  
          INTO #TempEdu  
          FROM _TDAEmp AS A  
    --JOIN #THREmp     AS B  ON A.CompanySeq = @CompanySeq  
    --             AND A.EmpSeq     = B.EmpSeq  
    --��������  
    LEFT OUTER JOIN  _THREduPersRst AS EP ON EP.CompanySeq = A.CompanySeq   
              AND EP.EmpSeq    = A.EmpSeq  
              
  WHERE  UMEduGrpType <> 3908005  
      AND  (@EmpSeq = 0     OR A.EmpSeq  = @EmpSeq)  
    AND  A.CompanySeq  = @CompanySeq     
   --select * from _TPRRetmst  
      
      
  /*��������*/  
  SELECT     
    ROW_NUMBER() OVER(ORDER BY ER.RestEndDate )  AS ROWNO ,  
    ISNULL(LTRIM(RTRIM(ER.RestBegDate))+ '~'+ LTRIM(RTRIM(ER.RestEndDate)) , '')  AS RestDate , --�����Ⱓ  
    ISNULL(ER.RestOrdSeq , '')   AS RestReason , --��������  
    ISNULL(ER.Remark  , '')    AS RestRemark  --���  
          INTO #TempRest  
          FROM _TDAEmp AS A  
    --JOIN #THREmp     AS B  ON A.CompanySeq = @CompanySeq  
    --             AND A.EmpSeq     = B.EmpSeq  
    --��������  
    LEFT OUTER JOIN _THRAdmEmpRest AS ER ON ER.CompanySeq = A.CompanySeq   
              AND ER.EmpSeq    = A.EmpSeq  
              
  WHERE  A.CompanySeq  = @CompanySeq     
    AND  (@EmpSeq = 0     OR A.EmpSeq  = @EmpSeq)  
    
  /*��������*/    
  SELECT     
    ROW_NUMBER() OVER(ORDER BY RT.RetSeq )   AS ROWNO ,  
    ISNULL(RT.RetDate   , '')    AS RetDate , --������  
    ISNULL(RT.WkTrm    , '')    AS WkTrm , --�����Ⱓ  
    ISNULL(RRN.MinorName  , '')    AS RetCause, --��������  
    ISNULL(RT.TotRetAmt   , 0 )    AS totRetAmt,  --������  
    ISNULL(EI.Phone   , '')    AS EmpPhone   --�޴���ȭ��ȣ  
          INTO #TempRetire   
          FROM _TDAEmp AS A  
    --JOIN #THREmp      AS B  ON A.CompanySeq = @CompanySeq  
    --           AND A.EmpSeq     = B.EmpSeq  
    --��������  
    LEFT OUTER JOIN _TPRRetmst   AS RT ON RT.CompanySeq = A.CompanySeq   
               AND RT.EmpSeq   = A.EmpSeq  
    --��������          
    LEFT OUTER JOIN _THRAdmEmpRetReason AS RR ON RR.CompanySeq = A.CompanySeq   
               AND RR.EmpSeq = A.EmpSeq  
    --��������  
    LEFT OUTER JOIN _TDAUMinor   AS RRN ON RR.CompanySeq     = RRN.CompanySeq   
                AND RR.UMRetReasonSeq  = RRN.MinorSeq  
    --�޴���ȭ  
    LEFT OUTER JOIN _TDAEmpIN   AS EI  ON EI.CompanySeq = A.CompanySeq    
                AND EI.EmpSeq     = A.EmpSeq             
                 
  WHERE  A.CompanySeq  = @CompanySeq     
    AND  (@EmpSeq = 0     OR A.EmpSeq  = @EmpSeq)  
         
       /*#TempMaster ���̺� �����ͻ���*/  
        INSERT INTO #TempMaster(EmpSeq, EmpName, Photo, LenPhoto, BirthDate, EntDate, DeptName, UMPgName, UmjoName,   
        JobName, ResidId, EntDetails,IsMarriage, Addr, Bon1, UMReligion,Hobby,   
        Speciality, Height, Weight, EyeLt, EyeRt,SMBloodTypeName, Won,Zip, BirthPlace,  
        Type, Relation, Reason, QrtDate, NewsDate, NewsContents, RelationP, UmmilRnkname, UmmilKindname,  
        UmmilBrnchname, MilSoldierNo, MilEnrdDate, MilExBegDate, MilCfm, MilEdu, MilExEndDate, MilinCompletion,  
        UmmilclsName, UmmilVet, MilCivil, MilEtc, BonAddr,   
        /*�з�����*/  
        EtcSchNm1, EtcSchNm2, EtcSchNm3, EtcSchNm4, EtcSchNm5,  
        PeriodDate1, PeriodDate2, PeriodDate3, PeriodDate4, PeriodDate5,   
        MajorName1, MajorName2, MajorName3,MajorName4, MajorName5,    
        UMSchCreer1, UMSchCreer2, UMSchCreer3, UMSchCreer4, UMSchCreer5,   
        SLoc1, SLoc2,SLoc3, SLoc4, SLoc5,  
        /*����ڰ�*/  
        UMLicName1, UMLicName2, UMLicName3, UMLicName4, UMLicName5,   
        PosName1, PosName2, PosName3, PosName4, PosName5,   
        LicNo1, LicNo2, LicNo3, LicNo4, LicNo5,    
        AcqDate1, AcqDate2, AcqDate3, AcqDate4, AcqDate5,   
        IssueInst1, IssueInst2, IssueInst3, IssueInst4, IssueInst5,  
        /*�������*/  
        CoNm1 ,CoNm2, CoNm3, CoNm4, CoNm5, CoNm6,     
        CarPeriodDate1, CarPeriodDate2, CarPeriodDate3, CarPeriodDate4, CarPeriodDate5, CarPeriodDate6,   
        JpName1, JpName2, JpName3, JpName4, JpName5, JpName6,     
        BusType1, BusType2, BusType3, BusType4, BusType5, BusType6,    
        UMRetReasonName1, UMRetReasonName2, UMRetReasonName3, UMRetReasonName4, UMRetReasonName5, UMRetReasonName6,  
        Area1, Area2, Area3, Area4, Area5, Area6,  
        /*����,����*/     
        PrzPnlToDate1, PrzPnlToDate2, PrzPnlToDate3, PrzPnlToDate4, PrzPnlToDate5,   
        PrzPnlToDate6, PrzPnlToDate7, PrzPnlToDate8, PrzPnlToDate9, PrzPnlToDate10,   
          UMPrzPnlName1, UMPrzPnlName2, UMPrzPnlName3, UMPrzPnlName4, UMPrzPnlName5,   
        UMPrzPnlName6, UMPrzPnlName7, UMPrzPnlName8, UMPrzPnlName9, UMPrzPnlName10,   
        PrzPnlReason1, PrzPnlReason2, PrzPnlReason3, PrzPnlReason4, PrzPnlReason5,   
        PrzPnlReason6, PrzPnlReason7, PrzPnlReason8, PrzPnlReason9, PrzPnlReason10,   
        /*¡��,����*/  
        PrnRlnlFrDate1, PrnRlnlFrDate2, PrnRlnlFrDate3,   
        UMPnlName1, UMPnlName2, UMPnlName3,    
        PnlReason1, PnlReason2, PnlReason3,  
        /*�ؿܿ���*/  
        CName1, CName2, CName3, CName4, CName5,   
        CPeriod1, CPeriod2, CPeriod3, CPeriod4, CPeriod5,  
        CReason1, CReason2, CReason3, CReason4, CReason5,  
        /*�����Ʒ�*/  
        EtcCourseName1, EtcCourseName2, EtcCourseName3, EtcCourseName4, EtcCourseName5,   
        EduPeriod1, EduPeriod2, EduPeriod3, EduPeriod4, EduPeriod5,    
        EtcInstitute1, EtcInstitute2, EtcInstitute3, EtcInstitute4, EtcInstitute5,   
        RstRem1, RstRem2, RstRem3, RstRem4, RstRem5,     
        /*��������*/  
        RestDate1, RestDate2,   
        RestReason1, RestReason2,  
        RestRemark1, RestRemark2,  
        /*��������*/  
        RetDate1, WkTrm1, RetCause1, totRetAmt1, EmpPhone,            
        /*�߷�����*/  
        OrdDate1, OrdDate2, OrdDate3, OrdDate4, OrdDate5, OrdDate6, OrdDate7, OrdDate8, OrdDate9, OrdDate10,  
        OrdDate11, OrdDate12, OrdDate13, OrdDate14, OrdDate15, OrdDate16, OrdDate17, OrdDate18, OrdDate19, OrdDate20,  
        OrdDate21, OrdDate22, OrdDate23, OrdDate24, OrdDate25, OrdDate26, OrdDate27,  
        Remark1, Remark2, Remark3, Remark4, Remark5, Remark6, Remark7, Remark8, Remark9, Remark10,   
        Remark11, Remark12, Remark13, Remark14, Remark15, Remark16, Remark17, Remark18, Remark19, Remark20,   
        Remark21, Remark22, Remark23, Remark24, Remark25, Remark26, Remark27,   
        Contents1, Contents2, Contents3, Contents4, Contents5, Contents6, Contents7, Contents8, Contents9, Contents10,  
        Contents11, Contents12, Contents13, Contents14, Contents15, Contents16, Contents17, Contents18, Contents19, Contents20,  
        Contents21, Contents22, Contents23, Contents24, Contents25, Contents26, Contents27  
          
           
        )  
        SELECT ISNULL(EmpSeq.EmpSeq , 0 ) AS EmpSeq    ,    
    ISNULL(A.EmpName  , '') AS EmpName    ,    
    ISNULL(Photo.Photo  , '') AS Photo    ,    
    LEN(Photo)                      AS LenPhoto             ,  
    ISNULL(EmpSeq.BirthDate , '') AS BirthDate   , --����    
    ISNULL(EmpSeq.EntDate , '') AS EntDate    , --�Ի���     
    ISNULL(Dept.DeptName , '') AS DeptName    , --�μ�    
    ISNULL(Dept.UMPgName , '') AS UMPgName    , --����  
    ISNULL(Dept.UmjoName , '') AS UmjoName    , --����  
    ISNULL(Dept.JobName  , '') AS JobName     , --����   
    --ISNULL(Dept.ResidId  , '') AS ResidId    ,  --�ֹε�Ϲ�ȣ  
    ISNULL(dbo._FCOMDecrypt(A.ResidID, '_TDAEmp', 'ResidID', @CompanySeq), '') AS ResidID,  
    ISNULL(/*'�Ի����'*/''  , '') AS EntDetails   , --�Ի����  
    ISNULL(EmpSeq.IsMarriage, 0 ) AS IsMarriage   ,  --��ȥ����    
    ISNULL((SELECT ISNULL(LTRIM(RTRIM(L.Addr1)) + ' ' + LTRIM(RTRIM(Addr2)), '')     
                              FROM _THRBasAddress AS L  
                             WHERE L.SMAddressType = 3055002  
                               AND CompanySeq      = @CompanySeq  
          AND A.EmpSeq        = L.EmpSeq  
                               AND EndDate         = '99991231'), '') AS Addr , --�ּ�                           
    ISNULL(/*'����'*/''   , '') AS Bon1     , --����  
    ISNULL(UMR.MinorName , '') AS UMReligion    ,   
    ISNULL(EmpSeq.Hobby  , '') AS Hobby    ,     
    ISNULL(EmpSeq.Speciality, '') AS Speciality   ,    
    ISNULL(EmpSeq.Height , 0 ) AS Height    ,    
    ISNULL(EmpSeq.Weight , 0 ) AS Weight    ,    
    ISNULL(EmpSeq.EyeLt  ,   0)  AS EyeLt    ,    
    ISNULL(EmpSeq.EyeRt  , 0)  AS EyeRt    ,  
    ISNULL(SMBN.MinorName , '') AS SMBloodTypeName  , --������  
    ISNULL(/*'����'*/''   , '') AS Won     , --����  
    ISNULL((SELECT ISNULL(LTRIM(RTRIM(L.AddrZip)) , ' ' )     
           FROM _THRBasAddress AS L  
                         WHERE L.SMAddressType = 3055002  
                           AND CompanySeq      = @CompanySeq  
         AND A.EmpSeq        = L.EmpSeq  
                           AND EndDate         = '99991231'), '')   AS BonAddr ,  --����  
    ISNULL(/*'�����'*/ ''  , '') AS BirthPlace     ,  --�����  
    ISNULL(/*'����'*/''   , '') AS Type     ,  --����  
    ISNULL(/*'����'*/''   , '') AS Relation    ,  --����  
    ISNULL(/*'����'*/''   , '') AS Reason    ,  --����  
    ISNULL(/*'��ȸ����'*/''  , '') AS QrtDate    ,   
    ISNULL(/*'ȸ����'*/''   , '') AS NewsDate    ,   
    ISNULL(/*'ȸ������'*/''  , '') AS NewsContents   ,   
    ISNULL(/*'������'*/''   , '') AS RelationP   ,   
    ISNULL(URN.MinorName , '') AS UmmilRnkname   ,  --����   
    ISNULL(UKN.MinorName , '') AS UmmilKindname  ,  --���  
    ISNULL(UBN.MinorName , '') AS UmmilBrnchname  ,  --����    
    ISNULL(MIL.MilSoldierNo , '') AS MilSoldierNo   ,  --����  
    ISNULL(DATEDIFF(d, MIL.MilExBegDate, MIL.MilExEndDate) , '')  AS MilEnrdDate , --�����Ⱓ  
    ISNULL(MIL.MilExBegDate , '') AS MilExBegDate   , --ó����    
    ISNULL(/*'�����ڰ�'*/''  , '') AS MilCfm    , --�����ڰ�  
    ISNULL(/*'��������'*/''  , '') AS MilEdu    , --��������   
    ISNULL(MIL.MilExEndDate , 0 ) AS MilExEndDate   , --�ٹ�������   
    ISNULL(/*'�ǿ�������'*/''  , '') AS MilinCompletion  , --�ǿ�������  
    ISNULL(UCN.MinorName , '') AS UmmilclsName   , --����   
    ISNULL(/*'����'*/ ''  , '') AS UmmilVet    , --����  
    ISNULL(/*'�ι���'*/ ''  , '') AS MilCivil    , --�ι���  
    ISNULL(/*'��Ÿ'*/''   , '') AS MilEtc    ,  --��Ÿ  
    ISNULL((SELECT ISNULL(LTRIM(RTRIM(L.Addr1)) + ' ' + LTRIM(RTRIM(Addr2)), '')     
                              FROM _THRBasAddress AS L  
                             WHERE L.SMAddressType = 3055001  
                               AND CompanySeq      = @CompanySeq  
          AND A.EmpSeq        = L.EmpSeq  
                               AND EndDate         = '99991231'), '') AS BonAddr  , --����  
                /*�з�����*/  
                ISNULL('1'    , '') AS EtcSchNm1   , --EtcSchNm1  
                ISNULL('2'    , '') AS EtcSchNm2   , --EtcSchNm2  
                ISNULL('3'    , '') AS EtcSchNm3   , --EtcSchNm3  
                ISNULL('4'    , '') AS EtcSchNm4   , --EtcSchNm4  
                ISNULL('5'    , '') AS EtcSchNm5   , --EtcSchNm5  
                ISNULL('1'    , '') AS PeriodDate1   , --PeriodDate1  
                ISNULL('2'    , '') AS PeriodDate2   , --PeriodDate2  
                ISNULL('3'    , '') AS PeriodDate3   , --PeriodDate3  
                ISNULL('4'    , '') AS PeriodDate4   , --PeriodDate4  
                ISNULL('5'    , '') AS PeriodDate5   , --PeriodDate5  
                ISNULL('1'    , '') AS MajorName1   , --Major1  
                ISNULL('2'    , '') AS MajorName2   , --Major2  
                ISNULL('3'    , '') AS MajorName3   , --Major3  
                ISNULL('4'    , '') AS MajorName4   , --Major4  
                ISNULL('5'    , '') AS MajorName5   , --Major5  
                ISNULL('1'    , '') AS UMSchCreer1   , --UMSchCreer1  
                ISNULL('2'    , '') AS UMSchCreer2   , --UMSchCreer2  
                ISNULL('3'    , '') AS UMSchCreer3   , --UMSchCreer3  
                ISNULL('4'    , '') AS UMSchCreer4   , --UMSchCreer4  
                ISNULL('5'    , '') AS UMSchCreer5   , --UMSchCreer5  
                ISNULL('1'    , '') AS SLoc1    , --Local1  
                ISNULL('2'    , '') AS SLoc2    , --Local2  
                ISNULL('3'    , '') AS SLoc3    , --Local3  
                ISNULL('4'    , '') AS SLoc4    , --Local4  
                ISNULL('5'    , '') AS SLoc5    , --Local5  
    /*����ڰ�*/  
    ISNULL('1'    , '') AS UMLicName1   , --UMLicName1  
    ISNULL('2'    , '') AS UMLicName2   , --UMLicName2  
    ISNULL('3'    , '') AS UMLicName3   , --UMLicName3  
    ISNULL('4'    , '') AS UMLicName4   , --UMLicName4  
    ISNULL('5'    , '') AS UMLicName5   , --UMLicName5  
    ISNULL('1'    , '') AS PosName1    , --PosName1   
      ISNULL('2'    , '') AS PosName2    , --PosName2   
    ISNULL('3'    , '') AS PosName3    , --PosName3   
    ISNULL('4'    , '') AS PosName4    , --PosName4   
    ISNULL('5'    , '') AS PosName5    , --PosName5   
    ISNULL('1'    , '') AS LicNo1    , --LicNo1    
    ISNULL('2'    , '') AS LicNo2    , --LicNo2    
    ISNULL('3'    , '') AS LicNo3    , --LicNo3    
    ISNULL('4'    , '') AS LicNo4    , --LicNo4    
    ISNULL('5'    , '') AS LicNo5    , --LicNo5    
    ISNULL('1'    , '') AS AcqDate1    , --AcqDate1   
    ISNULL('2'    , '') AS AcqDate2    , --AcqDate2   
    ISNULL('3'    , '') AS AcqDate3    , --AcqDate3   
    ISNULL('4'    , '') AS AcqDate4    , --AcqDate4   
    ISNULL('5'    , '') AS AcqDate5    , --AcqDate5   
    ISNULL('1'    , '') AS IssueInst1   , --IssueInst1  
    ISNULL('2'    , '') AS IssueInst2   , --IssueInst2  
    ISNULL('3'    , '') AS IssueInst3   , --IssueInst3  
    ISNULL('4'    , '') AS IssueInst4   , --IssueInst4  
    ISNULL('5'    , '') AS IssueInst5   , --IssueInst5  
    /*�������*/  
    ISNULL('1'    , '') AS CoNm1    , --CoNm1  
    ISNULL('2'    , '') AS CoNm2    , --CoNm2  
    ISNULL('3'    , '') AS CoNm3    , --CoNm3  
    ISNULL('4'    , '') AS CoNm4    , --CoNm4  
    ISNULL('5'    , '') AS CoNm5    , --CoNm5  
    ISNULL('6'    , '') AS CoNm6    , --CoNm6   
    ISNULL('1'    , '') AS CarPeriodDate1    , --CarPeriodDate1   
    ISNULL('2'    , '') AS CarPeriodDate2  , --CarPeriodDate2   
    ISNULL('3'    , '') AS CarPeriodDate3  , --CarPeriodDate3   
    ISNULL('4'    , '') AS CarPeriodDate4   , --CarPeriodDate4   
    ISNULL('5'    , '') AS CarPeriodDate5  , --CarPeriodDate5    
    ISNULL('6'    , '') AS CarPeriodDate6  , --CarPeriodDate6    
    ISNULL('1'    , '') AS JpName1    , --JpName1    
    ISNULL('2'    , '') AS JpName2    , --JpName2    
    ISNULL('3'    , '') AS JpName3    , --JpName3    
    ISNULL('4'    , '') AS JpName4    , --JpName4   
    ISNULL('5'    , '') AS JpName5    , --JpName5   
    ISNULL('6'    , '') AS JpName6    , --JpName6   
    ISNULL('1'    , '') AS BusType1    , --BusType1   
    ISNULL('2'    , '') AS BusType2    , --BusType2   
    ISNULL('3'    , '') AS BusType3    , --BusType3  
    ISNULL('4'    , '') AS BusType4    , --BusType4  
    ISNULL('5'    , '') AS BusType5    , --BusType5  
    ISNULL('6'    , '') AS BusType6    , --BusType6  
    ISNULL('1'    , '') AS UMRetReasonName1  , --UMRetReasonName1  
    ISNULL('2'    , '') AS UMRetReasonName2  , --UMRetReasonName2  
    ISNULL('3'    , '') AS UMRetReasonName3  , --UMRetReasonName3  
    ISNULL('4'    , '') AS UMRetReasonName4  , --UMRetReasonName4  
    ISNULL('5'    , '') AS UMRetReasonName5  , --UMRetReasonName5  
    ISNULL('6'    , '') AS UMRetReasonName6  , --UMRetReasonName6  
    ISNULL('1'    , '') AS Area1    , --Area1  
    ISNULL('2'    , '') AS Area2    , --Area2  
    ISNULL('3'    , '') AS Area3    , --Area3  
    ISNULL('4'    , '') AS Area4    , --Area4  
    ISNULL('5'    , '') AS Area5    , --Area5  
    ISNULL('6'    , '') AS Area6    , --Area6  
    /*����,����*/  
    ISNULL('1'    , '') AS PrzPnlToDate1  , --PrzPnlToDate1  
    ISNULL('2'    , '') AS PrzPnlToDate2  , --PrzPnlToDate2  
    ISNULL('3'    , '') AS PrzPnlToDate3  , --PrzPnlToDate3  
    ISNULL('4'    , '') AS PrzPnlToDate4  , --PrzPnlToDate4  
    ISNULL('5'    , '') AS PrzPnlToDate5  , --PrzPnlToDate5  
    ISNULL('6'    , '') AS PrzPnlToDate6  , --PrzPnlToDate6  
    ISNULL('7'    , '') AS PrzPnlToDate7  , --PrzPnlToDate7  
    ISNULL('8'    , '') AS PrzPnlToDate8  , --PrzPnlToDate8  
    ISNULL('9'    , '') AS PrzPnlToDate9  , --PrzPnlToDate9  
    ISNULL('10'    , '') AS PrzPnlToDate10  , --PrzPnlToDate10  
    ISNULL('1'    , '') AS UMPrzPnlName1  , --UMPrzPnlName1  
    ISNULL('2'    , '') AS UMPrzPnlName2  , --UMPrzPnlName2  
    ISNULL('3'    , '') AS UMPrzPnlName3  , --UMPrzPnlName3  
    ISNULL('4'    , '') AS UMPrzPnlName4  , --UMPrzPnlName4  
    ISNULL('5'    , '') AS UMPrzPnlName5  , --UMPrzPnlName5  
    ISNULL('6'    , '') AS UMPrzPnlName6  , --UMPrzPnlName6  
      ISNULL('7'    , '') AS UMPrzPnlName7  , --UMPrzPnlName7  
    ISNULL('8'    , '') AS UMPrzPnlName8  , --UMPrzPnlName8  
    ISNULL('9'    , '') AS UMPrzPnlName9  , --UMPrzPnlName9  
    ISNULL('10'    , '') AS UMPrzPnlName10  , --UMPrzPnlName10  
    ISNULL('1'    , '') AS PrzPnlReason1  , --PrzPnlReason1  
    ISNULL('2'    , '') AS PrzPnlReason2  , --PrzPnlReason2  
    ISNULL('3'    , '') AS PrzPnlReason3  , --PrzPnlReason3  
    ISNULL('4'    , '') AS PrzPnlReason4  , --PrzPnlReason4  
    ISNULL('5'    , '') AS PrzPnlReason5  , --PrzPnlReason5  
    ISNULL('6'    , '') AS PrzPnlReason6  , --PrzPnlReason6  
    ISNULL('7'    , '') AS PrzPnlReason7  , --PrzPnlReason7  
    ISNULL('8'    , '') AS PrzPnlReason8  , --PrzPnlReason8  
    ISNULL('9'    , '') AS PrzPnlReason9  , --PrzPnlReason9  
    ISNULL('10'    , '') AS PrzPnlReason10  , --PrzPnlReason10  
    /*¡��,����*/  
    ISNULL('1'    , '') AS PrnRlnlFrDate1  , --PrnRlnlFrDate1   
    ISNULL('2'    , '') AS PrnRlnlFrDate2     , --PrnRlnlFrDate2  
    ISNULL('3'    , '') AS PrnRlnlFrDate3  , --PrnRlnlFrDate3   
    ISNULL('1'    , '') AS UMPnlName1   , --UMPnlName1   
    ISNULL('2'    , '') AS UMPnlName2   , --UMPnlName2   
    ISNULL('3'    , '') AS UMPnlName3   , --UMPnlName3   
    ISNULL('1'    , '') AS PnlReason1   , --PnlReason1   
    ISNULL('2'    , '') AS PnlReason2   , --PnlReason2   
    ISNULL('3'    , '') AS PnlReason3   , --PnlReason3  
    /*�ؿܿ���*/  
    ISNULL('1'    , '') AS CName1    , --CName1  
    ISNULL('2'    , '') AS CName2    , --CName2  
    ISNULL('3'    , '') AS CName3    , --CName3  
    ISNULL('4'    , '') AS CName4    , --CName4  
    ISNULL('5'    , '') AS CName5    , --CName5  
    ISNULL('1'    , '') AS CPeriod1    , --CPeriod1  
    ISNULL('2'    , '') AS CPeriod2    , --CPeriod2  
    ISNULL('3'    , '') AS CPeriod3    , --CPeriod3  
    ISNULL('4'    , '') AS CPeriod4    , --CPeriod4  
    ISNULL('5'    , '') AS CPeriod5    , --CPeriod5  
    ISNULL('1'    , '') AS CReason1    , --CReason1  
    ISNULL('2'    , '') AS CReason2    , --CReason2  
    ISNULL('3'    , '') AS CReason3    , --CReason3  
    ISNULL('4'    , '') AS CReason4    , --CReason4  
    ISNULL('5'    , '') AS CReason5    , --CReason5  
    /*�����Ʒ�*/  
    ISNULL('1'    , '') AS EtcCourseName1  , --EtcCourseName1  
    ISNULL('2'    , '') AS EtcCourseName2  , --EtcCourseName2  
    ISNULL('3'    , '') AS EtcCourseName3  , --EtcCourseName3  
    ISNULL('4'    , '') AS EtcCourseName4  , --EtcCourseName4  
    ISNULL('5'    , '') AS EtcCourseName5  , --EtcCourseName5  
    ISNULL('1'    , '') AS EduPeriod1   , --EduPeriod1  
    ISNULL('2'    , '') AS EduPeriod2   , --EduPeriod2  
    ISNULL('3'    , '') AS EduPeriod3   , --EduPeriod3  
    ISNULL('4'    , '') AS EduPeriod4   , --EduPeriod4  
    ISNULL('5'    , '') AS EduPeriod5   , --EduPeriod5  
    ISNULL('1'    , '') AS EtcInstitute1  , --EtcInstitute1  
    ISNULL('2'    , '') AS EtcInstitute2  , --EtcInstitute2  
    ISNULL('3'    , '') AS EtcInstitute3  , --EtcInstitute3  
    ISNULL('4'    , '') AS EtcInstitute4  , --EtcInstitute4  
    ISNULL('5'    , '') AS EtcInstitute5  , --EtcInstitute5  
    ISNULL('1'    , '') AS RstRem1    , --RstRem1  
    ISNULL('2'    , '') AS RstRem2    , --RstRem2  
    ISNULL('3'    , '') AS RstRem3    , --RstRem3  
    ISNULL('4'    , '') AS RstRem4    , --RstRem4  
    ISNULL('5'    , '') AS RstRem5    , --RstRem5  
    /*��������*/  
    ISNULL('1'    , '') AS RestDate1   , --RestDate1  
    ISNULL('2'    , '') AS RestDate2   , --RestDate2  
    ISNULL('1'    , '') AS RestReason1   , --RestReason1  
    ISNULL('2'    , '') AS RestReason2   , --RestReason2  
    ISNULL('1'    , '') AS RestRemark1   , --RestRemark1  
    ISNULL('2'    , '') AS RestRemark2   , --RestRemark2  
    /*��������*/  
    ISNULL('1'    , '') AS RetDate1    , --RetDate   
    ISNULL('1'    , '') AS WkTrm1    , --WkTrm   
    ISNULL('1'    , '') AS RetCause1   , --RetCause   
    ISNULL('1'    , '') AS totRetAmt1   , --totRetAmt  
    ISNULL('1'    , '') AS EmpPhone   , --EmpPhone  
         
    /*�߷ɻ���*/  
    ISNULL('1'    , '') AS OrdDate1    ,  -- OrdDate1  
    ISNULL('2'    , '') AS OrdDate2    ,  -- OrdDate2  
    ISNULL('3'    , '') AS OrdDate3    ,  -- OrdDate3  
    ISNULL('4'    , '') AS OrdDate4    ,  -- OrdDate4  
    ISNULL('5'    , '') AS OrdDate5    ,  -- OrdDate5  
    ISNULL('6'    , '') AS OrdDate6    ,  -- OrdDate6  
    ISNULL('7'    , '') AS OrdDate7    ,  -- OrdDate7  
    ISNULL('8'    , '') AS OrdDate8    ,  -- OrdDate8  
    ISNULL('9'    , '') AS OrdDate9    ,  -- OrdDate9  
    ISNULL('10'    , '') AS OrdDate10   ,  -- OrdDate10  
    ISNULL('11'    , '') AS OrdDate11   ,  -- OrdDate11  
    ISNULL('12'    , '') AS OrdDate12   ,  -- OrdDate12  
    ISNULL('13'    , '') AS OrdDate13   ,  -- OrdDate13  
    ISNULL('14'    , '') AS OrdDate14   ,  -- OrdDate14  
    ISNULL('15'    , '') AS OrdDate15   ,  -- OrdDate15  
    ISNULL('16'    , '') AS OrdDate16   ,  -- OrdDate16  
    ISNULL('17'    , '') AS OrdDate17   ,  -- OrdDate17  
    ISNULL('18'    , '') AS OrdDate18   ,  -- OrdDate18  
    ISNULL('19'    , '') AS OrdDate19   ,  -- OrdDate19  
    ISNULL('20'    , '') AS OrdDate20   ,  -- OrdDate20  
    ISNULL('21'    , '') AS OrdDate21   ,  -- OrdDate21  
    ISNULL('22'    , '') AS OrdDate22   ,  -- OrdDate22  
    ISNULL('23'    , '') AS OrdDate23   ,  -- OrdDate23  
    ISNULL('24'    , '') AS OrdDate24   ,  -- OrdDate24  
    ISNULL('25'    , '') AS OrdDate25   ,  -- OrdDate25  
    ISNULL('26'    , '') AS OrdDate26   ,  -- OrdDate26  
    ISNULL('27'    , '') AS OrdDate27   ,  -- OrdDate27  
    ISNULL('1'    , '') AS Remark1    ,  -- Remark1   
    ISNULL('2'    , '') AS Remark2    ,  -- Remark2   
    ISNULL('3'    , '') AS Remark3    ,  -- Remark3   
    ISNULL('4'    , '') AS Remark4    ,  -- Remark4   
    ISNULL('5'    , '') AS Remark5    ,  -- Remark5   
    ISNULL('6'    , '') AS Remark6    ,  -- Remark6   
    ISNULL('7'    , '') AS Remark7    ,  -- Remark7   
    ISNULL('8'    , '') AS Remark8    ,  -- Remark8   
    ISNULL('9'    , '') AS Remark9    ,  -- Remark9   
    ISNULL('10'    , '') AS Remark10    ,  -- Remark10   
    ISNULL('11'    , '') AS Remark11    ,  -- Remark11   
    ISNULL('12'    , '') AS Remark12    ,  -- Remark12   
    ISNULL('13'    , '') AS Remark13    ,  -- Remark13   
    ISNULL('14'    , '') AS Remark14    ,  -- Remark14   
    ISNULL('15'    , '') AS Remark15    ,  -- Remark15   
    ISNULL('16'    , '') AS Remark16    ,  -- Remark16   
    ISNULL('17'    , '') AS Remark17    ,  -- Remark17   
    ISNULL('18'    , '') AS Remark18    ,  -- Remark18   
    ISNULL('19'    , '') AS Remark19    ,  -- Remark19   
    ISNULL('20'    , '') AS Remark20    ,  -- Remark20   
    ISNULL('21'    , '') AS Remark21    ,  -- Remark21   
    ISNULL('22'    , '') AS Remark22    ,  -- Remark22   
    ISNULL('23'    , '') AS Remark23    ,  -- Remark23   
    ISNULL('24'    , '') AS Remark24    ,  -- Remark24   
    ISNULL('25'    , '') AS Remark25    ,  -- Remark25   
    ISNULL('26'    , '') AS Remark26    ,  -- Remark26  
    ISNULL('27'    , '') AS Remark27    ,  -- Remark27  
    ISNULL('1'    , '') AS Contents1   ,  -- Contents1  
    ISNULL('2'    , '') AS Contents2   ,  -- Contents2  
    ISNULL('3'    , '') AS Contents3   ,  -- Contents3  
    ISNULL('4'    , '') AS Contents4   ,  -- Contents4  
    ISNULL('5'    , '') AS Contents5   ,  -- Contents5  
    ISNULL('6'    , '') AS Contents6   ,  -- Contents6  
    ISNULL('7'    , '') AS Contents7   ,  -- Contents7  
    ISNULL('8'    , '') AS Contents8   ,  -- Contents8  
    ISNULL('9'    , '') AS Contents9   ,  -- Contents9  
    ISNULL('10'    , '') AS Contents10   ,  -- Contents10  
    ISNULL('11'    , '') AS Contents11   ,  -- Contents11  
    ISNULL('12'    , '') AS Contents12   ,  -- Contents12  
    ISNULL('13'    , '') AS Contents13   ,  -- Contents13  
    ISNULL('14'    , '') AS Contents14   ,  -- Contents14  
    ISNULL('15'    , '') AS Contents15   ,  -- Contents15  
    ISNULL('16'    , '') AS Contents16   ,  -- Contents16  
      ISNULL('17'    , '') AS Contents17   ,  -- Contents17  
    ISNULL('18'    , '') AS Contents18   ,  -- Contents18  
    ISNULL('19'    , '') AS Contents19   ,  -- Contents19  
    ISNULL('20'    , '') AS Contents20   ,  -- Contents20  
    ISNULL('21'    , '') AS Contents21   ,  -- Contents21  
    ISNULL('22'    , '') AS Contents22   ,  -- Contents22  
    ISNULL('23'    , '') AS Contents23   ,  -- Contents23  
    ISNULL('24'    , '') AS Contents24   ,  -- Contents24  
    ISNULL('25'    , '') AS Contents25   ,  -- Contents25  
    ISNULL('26'    , '') AS Contents26   ,  -- Contents26  
    ISNULL('27'    , '') AS Contents27      -- Contents27  
       
  
          FROM _TDAEmp AS A  
    ----JOIN #THREmp      AS B ON A.CompanySeq = @CompanySeq  
    ----                AND A.EmpSeq     = B.EmpSeq  
    --�������  
     --����ڵ�,�Ի���,�������, �÷�, ��ȥ����   
    LEFT OUTER JOIN _TDAEmpIn   AS EmpSeq ON A.CompanySeq = EmpSeq.CompanySeq   
                AND A.EmpSeq   = EmpSeq.EmpSeq   
     --�μ�,����,�ֹε�Ϲ�ȣ  
    LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS Dept ON A.CompanySeq = @CompanySeq   
                  AND A.EmpSeq   = Dept.EmpSeq  
     -- ������  
    LEFT OUTER JOIN _TDASMinor   AS SMBN   ON EmpSeq.CompanySeq  = SMBN.CompanySeq   
                AND EmpSeq.SMBloodType = SMBN.MinorSeq   
     -- ����  
    LEFT OUTER JOIN _TDAUMinor   AS UMR   ON EmpSeq.CompanySeq   = UMR.CompanySeq   
                   AND EmpSeq.UMReligionSeq = UMR.MinorSeq   
          
    --��������  
     --����,ó����,�ٹ�������  
    LEFT OUTER JOIN _THRBasMilitary     AS MIL   ON MIL.CompanySeq = A.CompanySeq   
                      AND MIL.EmpSeq  = A.EmpSeq   
     --����  
    LEFT OUTER JOIN _TDAUMinor   AS URN WITH(NOLOCK) ON  MIL.CompanySeq = URN.CompanySeq   
                     AND MIL.UMMilRnkSeq = URN.MinorSeq  
     --���  
    LEFT OUTER JOIN _TDAUMinor   AS UKN ON MIL.CompanySeq  = UKN.CompanySeq    
                AND MIL.UMMilKindSeq = UKN.MinorSeq  
     --����  
    LEFT OUTER JOIN _TDAUMinor   AS UBN ON MIL.CompanySeq = UBN.CompanySeq   
                AND MIL.UMMilBrnchSeq = UBN.MinorSeq  
     --����  
    LEFT OUTER JOIN _TDAUMinor   AS UCN ON MIL.CompanySeq  = UCN.CompanySeq  
                AND MIL.UMMilClsSeq = UCN.MinorSeq  
     -- ����  
    LEFT OUTER JOIN _THRBasEmpPhoto  AS Photo ON Photo.CompanySeq = A.CompanySeq   
                  AND Photo.EmpSeq  = A.EmpSeq  
  WHERE  A.CompanySeq  = @CompanySeq     
   AND  (@EmpSeq = 0     OR A.EmpSeq  = @EmpSeq)    
      
      
  /*�б���*/   
  -- �б���1                          
  UPDATE #TempMaster  
     SET EtcSchNm1 = MinorName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.EtcSchNm1 = TS.ROWNO  
  
    
  -- �б���2                          
  UPDATE #TempMaster  
     SET EtcSchNm2 = MinorName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.EtcSchNm2 = TS.ROWNO  
  
    
  -- �б���3                          
  UPDATE #TempMaster  
     SET EtcSchNm3 = MinorName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.EtcSchNm3 = TS.ROWNO  
  
      
  -- �б���4                          
  UPDATE #TempMaster  
     SET EtcSchNm4 = MinorName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.EtcSchNm4 = TS.ROWNO  
  
    
  -- �б���5                          
  UPDATE #TempMaster  
     SET EtcSchNm5 = MinorName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.EtcSchNm5 = TS.ROWNO  
  
    
  /*���бⰣ*/  
  --���бⰣ1  
  UPDATE #TempMaster  
     SET PeriodDate1 = PeriodDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.PeriodDate1 = TS.ROWNO  
  
    
  --���бⰣ2  
  UPDATE #TempMaster  
     SET PeriodDate2 = PeriodDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.PeriodDate2 = TS.ROWNO  
  
    
  --���бⰣ3  
  UPDATE #TempMaster  
     SET PeriodDate3 = PeriodDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.PeriodDate3 = TS.ROWNO  
  
    
  --���бⰣ4  
  UPDATE #TempMaster  
     SET PeriodDate4 = PeriodDate   
      FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.PeriodDate4 = TS.ROWNO  
  
    
  --���бⰣ5  
  UPDATE #TempMaster  
     SET PeriodDate5 = PeriodDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.PeriodDate5 = TS.ROWNO  
  
    
  /*����*/  
  --����1  
  UPDATE #TempMaster  
     SET MajorName1 = Major   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.MajorName1 = TS.ROWNO  
  
    
  --����2  
  UPDATE #TempMaster  
     SET MajorName2 = Major   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.MajorName2 = TS.ROWNO  
  
    
  --����3  
  UPDATE #TempMaster  
     SET MajorName3 = Major   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.MajorName3 = TS.ROWNO  
  
    
  --����4  
  UPDATE #TempMaster  
     SET MajorName4 = Major   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.MajorName4 = TS.ROWNO  
    
  --����5  
  UPDATE #TempMaster  
     SET MajorName5 = Major   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.MajorName5 = TS.ROWNO  
  
    
    
  /*���б���*/  
  --���б���1  
  UPDATE #TempMaster  
     SET UMSchCreer1 = UMSchCareerName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.UMSchCreer1 = TS.ROWNO  
  
    
  --���б���2  
  UPDATE #TempMaster  
     SET UMSchCreer2 = UMSchCareerName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.UMSchCreer2 = TS.ROWNO  
  
    
  --���б���3  
  UPDATE #TempMaster  
     SET UMSchCreer3 = UMSchCareerName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.UMSchCreer3 = TS.ROWNO  
  
    
     --���б���4  
  UPDATE #TempMaster  
     SET UMSchCreer4 = UMSchCareerName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.UMSchCreer4 = TS.ROWNO  
  
    
  --���б���5  
  UPDATE #TempMaster  
     SET UMSchCreer5 = UMSchCareerName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.UMSchCreer5 = TS.ROWNO  
  
    
    
  /*������*/  
  --������1  
  UPDATE #TempMaster  
     SET SLoc1 = SLoc   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.SLoc1 = TS.ROWNO  
  
    
  --������2  
  UPDATE #TempMaster  
     SET SLoc2 = SLoc   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.SLoc2 = TS.ROWNO  
  
    
  --������3  
  UPDATE #TempMaster  
     SET SLoc3 = SLoc   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.SLoc3 = TS.ROWNO  
  
    
  --������4  
  UPDATE #TempMaster  
     SET SLoc4 = SLoc   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.SLoc4 = TS.ROWNO  
  
    
  --������5  
  UPDATE #TempMaster  
     SET SLoc5 = SLoc   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TEMPSCHOOL AS TS ON T.SLoc5 = TS.ROWNO  
  
    
  /*����ڰ�*/  
  --��Ī1  
  UPDATE #TempMaster  
     SET UMLicName1 = UMLicName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.UMLicName1 = TS.ROWNO  
  
    
  --��Ī2  
  UPDATE #TempMaster  
     SET UMLicName2 = UMLicName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.UMLicName2 = TS.ROWNO  
  
    
  --��Ī3  
  UPDATE #TempMaster  
     SET UMLicName3 = UMLicName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.UMLicName3 = TS.ROWNO  
  
    
  --��Ī4  
  UPDATE #TempMaster  
     SET UMLicName4 = UMLicName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.UMLicName4 = TS.ROWNO  
  
    
  --��Ī5  
  UPDATE #TempMaster  
     SET UMLicName5 = UMLicName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.UMLicName5 = TS.ROWNO  
  
    
  --���1?????  
  UPDATE #TempMaster  
     SET PosName1 = PosName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.PosName1 = TS.ROWNO  
  
  
  
  --��ȣ1  
  UPDATE #TempMaster  
     SET LicNo1 = LicNo   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.LicNo1 = TS.ROWNO  
  
    
  --��ȣ2  
  UPDATE #TempMaster  
       SET LicNo2 = LicNo   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.LicNo2 = TS.ROWNO  
  
    
  --��ȣ3  
  UPDATE #TempMaster  
     SET LicNo3 = LicNo   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.LicNo3 = TS.ROWNO  
    
    
  --��ȣ4  
  UPDATE #TempMaster  
     SET LicNo4 = LicNo   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.LicNo4= TS.ROWNO  
  
    
  --��ȣ5  
  UPDATE #TempMaster  
     SET LicNo5 = LicNo   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.LicNo5 = TS.ROWNO  
    
  
  --�����1  
  UPDATE #TempMaster  
     SET AcqDate1 = AcqDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.AcqDate1 = TS.ROWNO  
  
    
  --�����2  
  UPDATE #TempMaster  
     SET AcqDate2 = AcqDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.AcqDate2 = TS.ROWNO  
  
    
    
  --�����3  
  UPDATE #TempMaster  
     SET AcqDate3 = AcqDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.AcqDate3 = TS.ROWNO  
  
    
  --�����4  
  UPDATE #TempMaster  
     SET AcqDate4 = AcqDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.AcqDate4 = TS.ROWNO  
  
    
  --�����5  
  UPDATE #TempMaster  
     SET AcqDate5 = AcqDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.AcqDate5 = TS.ROWNO  
  
    
  --����ó1  
  UPDATE #TempMaster  
     SET IssueInst1 = IssueInst   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.IssueInst1 = TS.ROWNO  
  
    
  --����ó2  
  UPDATE #TempMaster  
     SET IssueInst2 = IssueInst   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.IssueInst2 = TS.ROWNO  
  
    
  --����ó3  
  UPDATE #TempMaster  
     SET IssueInst3 = IssueInst   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.IssueInst3 = TS.ROWNO  
  
    
  --����ó4  
  UPDATE #TempMaster  
     SET IssueInst4 = IssueInst   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.IssueInst4 = TS.ROWNO  
  
    
  --����ó5  
  UPDATE #TempMaster  
     SET IssueInst5 = IssueInst   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempLicense AS TS ON T.IssueInst5 = TS.ROWNO  
  
--    C.PosName AS PosName , --���?? ã�ƾ���  
  
  /*�������*/  
  --ȸ���1  
  UPDATE #TempMaster  
     SET CoNm1 = CoNm   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.CoNm1 = TS.ROWNO  
  
    
  --ȸ���2  
  UPDATE #TempMaster  
     SET CoNm2 = CoNm   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.CoNm2 = TS.ROWNO  
  
    
  --ȸ���3  
  UPDATE #TempMaster  
     SET CoNm3 = CoNm   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.CoNm3 = TS.ROWNO  
  
    
  --ȸ���4  
  UPDATE #TempMaster  
     SET CoNm4 = CoNm   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.CoNm4 = TS.ROWNO  
  
    
  --ȸ���5  
  UPDATE #TempMaster  
     SET CoNm5 = CoNm   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.CoNm5 = TS.ROWNO  
  
    
  --ȸ���6  
  UPDATE #TempMaster  
     SET CoNm6 = CoNm   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.CoNm6 = TS.ROWNO  
  
    
  --�ٹ��Ⱓ1  
  UPDATE #TempMaster  
     SET CarPeriodDate1 = CPeriodDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.CarPeriodDate1 = TS.ROWNO  
  
    
  --�ٹ��Ⱓ2  
  UPDATE #TempMaster  
     SET CarPeriodDate2 = CPeriodDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.CarPeriodDate2 = TS.ROWNO  
  
    
  --�ٹ��Ⱓ3  
  UPDATE #TempMaster  
     SET CarPeriodDate3 = CPeriodDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.CarPeriodDate3 = TS.ROWNO  
  
    
  --�ٹ��Ⱓ4  
  UPDATE #TempMaster  
     SET CarPeriodDate4 = CPeriodDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.CarPeriodDate4 = TS.ROWNO  
  
    
  --�ٹ��Ⱓ5  
  UPDATE #TempMaster  
     SET CarPeriodDate5 = CPeriodDate   
      FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.CarPeriodDate5 = TS.ROWNO  
   
    
  --�ٹ��Ⱓ6  
  UPDATE #TempMaster  
     SET CarPeriodDate6 = CPeriodDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.CarPeriodDate6 = TS.ROWNO  
  
  --����/����1  
  UPDATE #TempMaster  
     SET JpName1 = JpName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.JpName1 = TS.ROWNO  
     
  --����/����2  
  UPDATE #TempMaster  
     SET JpName2 = JpName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.JpName2 = TS.ROWNO  
         
  --����/����3  
  UPDATE #TempMaster  
     SET JpName3 = JpName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.JpName3 = TS.ROWNO  
         
  --����/����4  
  UPDATE #TempMaster  
     SET JpName4 = JpName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.JpName4 = TS.ROWNO  
    
  --����/����5  
  UPDATE #TempMaster  
     SET JpName5 = JpName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.JpName5 = TS.ROWNO  
         
  --����/����6  
  UPDATE #TempMaster  
     SET JpName6 = JpName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.JpName6 = TS.ROWNO  
         
  --����1  
  UPDATE #TempMaster  
     SET BusType1 = BusType   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.BusType1 = TS.ROWNO  
    
  --����2  
  UPDATE #TempMaster  
     SET BusType2 = BusType   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.BusType2 = TS.ROWNO  
         
  --����3  
  UPDATE #TempMaster  
     SET BusType3 = BusType   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.BusType3 = TS.ROWNO  
         
  --����4  
  UPDATE #TempMaster  
     SET BusType4 = BusType   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.BusType4 = TS.ROWNO  
         
  --����5  
  UPDATE #TempMaster  
     SET BusType5 = BusType   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.BusType5 = TS.ROWNO  
         
  --����6  
  UPDATE #TempMaster  
     SET BusType6 = BusType   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.BusType6 = TS.ROWNO  
    
  --��������1  
  UPDATE #TempMaster  
     SET UMRetReasonName1 = UMRetReasonName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.UMRetReasonName1 = TS.ROWNO  
         
  --��������2  
  UPDATE #TempMaster  
     SET UMRetReasonName2 = UMRetReasonName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.UMRetReasonName2 = TS.ROWNO  
             
  --��������3  
  UPDATE #TempMaster  
     SET UMRetReasonName3 = UMRetReasonName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.UMRetReasonName3 = TS.ROWNO  
    
  --��������4  
  UPDATE #TempMaster  
     SET UMRetReasonName4 = UMRetReasonName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.UMRetReasonName4 = TS.ROWNO  
         
  --��������5  
  UPDATE #TempMaster  
     SET UMRetReasonName5 = UMRetReasonName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.UMRetReasonName5 = TS.ROWNO  
    
  --��������6  
  UPDATE #TempMaster  
     SET UMRetReasonName6 = UMRetReasonName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.UMRetReasonName6 = TS.ROWNO  
         
  --������1  
  UPDATE #TempMaster  
     SET Area1 = Area   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.Area1 = TS.ROWNO  
         
  --������2  
  UPDATE #TempMaster  
     SET Area2 = Area   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.Area2 = TS.ROWNO  
         
  --������3  
  UPDATE #TempMaster  
     SET Area3 = Area   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.Area3 = TS.ROWNO  
         
  --������4  
  UPDATE #TempMaster  
     SET Area4 = Area   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.Area4 = TS.ROWNO  
         
  --������5  
    UPDATE #TempMaster  
     SET Area5 = Area   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.Area5 = TS.ROWNO  
         
  --������6  
  UPDATE #TempMaster  
     SET Area6 = Area   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCareer AS TS ON T.Area6 = TS.ROWNO  
   
  
  /*����,����*/  
  --����1  
  UPDATE #TempMaster  
     SET PrzPnlToDate1 = PrzPnlToDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlToDate1 = TS.ROWNO   
         
  --����2  
  UPDATE #TempMaster  
     SET PrzPnlToDate2 = PrzPnlToDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlToDate2 = TS.ROWNO   
         
  --����3  
  UPDATE #TempMaster  
     SET PrzPnlToDate3 = PrzPnlToDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlToDate3 = TS.ROWNO   
         
  --����4  
  UPDATE #TempMaster  
     SET PrzPnlToDate4 = PrzPnlToDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlToDate4 = TS.ROWNO   
         
  --����5  
  UPDATE #TempMaster  
     SET PrzPnlToDate5 = PrzPnlToDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlToDate5 = TS.ROWNO   
         
  --����6  
  UPDATE #TempMaster  
     SET PrzPnlToDate6 = PrzPnlToDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlToDate6 = TS.ROWNO   
         
    
  --����7  
  UPDATE #TempMaster  
     SET PrzPnlToDate7 = PrzPnlToDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlToDate7 = TS.ROWNO   
         
    
  --����8  
  UPDATE #TempMaster  
     SET PrzPnlToDate8 = PrzPnlToDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlToDate8 = TS.ROWNO   
         
         
  --����9  
  UPDATE #TempMaster  
     SET PrzPnlToDate9 = PrzPnlToDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlToDate9= TS.ROWNO   
    
    
  --����10  
  UPDATE #TempMaster  
     SET PrzPnlToDate10 = PrzPnlToDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlToDate10 = TS.ROWNO     
           
       
  --����1     
  UPDATE #TempMaster  
     SET UMPrzPnlName1 = UMPrzPnlName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.UMPrzPnlName1 = TS.ROWNO   
         
  --����2     
  UPDATE #TempMaster  
     SET UMPrzPnlName2 = UMPrzPnlName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.UMPrzPnlName2 = TS.ROWNO   
         
  --����3     
  UPDATE #TempMaster  
     SET UMPrzPnlName3 = UMPrzPnlName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.UMPrzPnlName3 = TS.ROWNO   
         
  --����4     
  UPDATE #TempMaster  
     SET UMPrzPnlName4 = UMPrzPnlName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.UMPrzPnlName4 = TS.ROWNO   
         
  --����5     
  UPDATE #TempMaster  
     SET UMPrzPnlName5 = UMPrzPnlName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.UMPrzPnlName5 = TS.ROWNO   
         
  --����6     
  UPDATE #TempMaster  
     SET UMPrzPnlName6 = UMPrzPnlName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.UMPrzPnlName6 = TS.ROWNO   
         
  --����7     
  UPDATE #TempMaster  
     SET UMPrzPnlName7 = UMPrzPnlName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.UMPrzPnlName7 = TS.ROWNO       
       
  --����8     
  UPDATE #TempMaster  
     SET UMPrzPnlName8 = UMPrzPnlName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.UMPrzPnlName8 = TS.ROWNO   
         
  --����9     
  UPDATE #TempMaster  
     SET UMPrzPnlName9 = UMPrzPnlName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.UMPrzPnlName9 = TS.ROWNO   
         
  --����10     
  UPDATE #TempMaster  
     SET UMPrzPnlName10 = UMPrzPnlName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.UMPrzPnlName10 = TS.ROWNO      
        
  --����1     
  UPDATE #TempMaster  
       SET PrzPnlReason1 = PrzPnlReason   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlReason1 = TS.ROWNO   
        
  --����2     
  UPDATE #TempMaster  
     SET PrzPnlReason2 = PrzPnlReason   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlReason2 = TS.ROWNO   
         
  --����3     
  UPDATE #TempMaster  
     SET PrzPnlReason3 = PrzPnlReason   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlReason3 = TS.ROWNO   
         
  --����4     
  UPDATE #TempMaster  
     SET PrzPnlReason4 = PrzPnlReason   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlReason4 = TS.ROWNO   
         
  --����5     
  UPDATE #TempMaster  
     SET PrzPnlReason5 = PrzPnlReason   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlReason5 = TS.ROWNO   
         
  --����6     
  UPDATE #TempMaster  
     SET PrzPnlReason6 = PrzPnlReason   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlReason6 = TS.ROWNO   
         
  --����7     
  UPDATE #TempMaster  
     SET PrzPnlReason7 = PrzPnlReason   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlReason7 = TS.ROWNO   
         
  --����8     
  UPDATE #TempMaster  
     SET PrzPnlReason8 = PrzPnlReason   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlReason8 = TS.ROWNO   
         
  --����9     
  UPDATE #TempMaster  
     SET PrzPnlReason9 = PrzPnlReason   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlReason9 = TS.ROWNO   
         
  --����10     
  UPDATE #TempMaster  
     SET PrzPnlReason10 = PrzPnlReason   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPrize AS TS ON T.PrzPnlReason10 = TS.ROWNO  
         
  /*¡��,����*/  
  --¡����1  
  UPDATE #TempMaster  
     SET PrnRlnlFrDate1 = PrzPnlToDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPnl AS TS ON T.PrnRlnlFrDate1 = TS.ROWNO   
         
  --¡����2  
  UPDATE #TempMaster  
     SET PrnRlnlFrDate2 = PrzPnlToDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPnl AS TS ON T.PrnRlnlFrDate2 = TS.ROWNO   
    
  --¡����3  
  UPDATE #TempMaster  
     SET PrnRlnlFrDate3 = PrzPnlToDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPnl AS TS ON T.PrnRlnlFrDate3 = TS.ROWNO  
         
  --����1  
  UPDATE #TempMaster  
     SET UMPnlName1 = UMPnlName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPnl AS TS ON T.UMPnlName1 = TS.ROWNO  
         
  --����2  
  UPDATE #TempMaster  
     SET UMPnlName2 = UMPnlName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPnl AS TS ON T.UMPnlName2 = TS.ROWNO  
         
  --����3  
  UPDATE #TempMaster  
     SET UMPnlName3 = UMPnlName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPnl AS TS ON T.UMPnlName3 = TS.ROWNO  
    
  --��ġ1  
  UPDATE #TempMaster  
     SET PnlReason1 = PnlReason   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPnl AS TS ON T.PnlReason1 = TS.ROWNO  
         
  --��ġ2  
  UPDATE #TempMaster  
     SET PnlReason2 = PnlReason   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPnl AS TS ON T.PnlReason2 = TS.ROWNO  
         
  --��ġ3  
  UPDATE #TempMaster  
     SET PnlReason3 = PnlReason   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempPnl AS TS ON T.PnlReason3 = TS.ROWNO   
    
  /*�ؿܿ���*/  
  --����1  
  UPDATE #TempMaster  
     SET CName1 = CName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCountryEdu AS TS ON T.CName1 = TS.ROWNO   
         
  --����2  
  UPDATE #TempMaster  
     SET CName2 = CName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCountryEdu AS TS ON T.CName2 = TS.ROWNO   
         
  --����3  
  UPDATE #TempMaster  
     SET CName3 = CName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCountryEdu AS TS ON T.CName3 = TS.ROWNO   
         
  --����4  
  UPDATE #TempMaster  
     SET CName4 = CName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCountryEdu AS TS ON T.CName4 = TS.ROWNO   
         
  --����5  
    UPDATE #TempMaster  
     SET CName5 = CName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCountryEdu AS TS ON T.CName5 = TS.ROWNO   
  
  --�����Ⱓ1   
  UPDATE #TempMaster  
     SET CPeriod1 = CPeriod   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCountryEdu AS TS ON T.CPeriod1 = TS.ROWNO  
         
  --�����Ⱓ2   
  UPDATE #TempMaster  
     SET CPeriod2 = CPeriod   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCountryEdu AS TS ON T.CPeriod2 = TS.ROWNO  
  
  --�����Ⱓ3   
  UPDATE #TempMaster  
     SET CPeriod3 = CPeriod   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCountryEdu AS TS ON T.CPeriod3 = TS.ROWNO  
  
  --�����Ⱓ4   
  UPDATE #TempMaster  
     SET CPeriod4 = CPeriod   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCountryEdu AS TS ON T.CPeriod4 = TS.ROWNO  
  
  --�����Ⱓ5   
  UPDATE #TempMaster  
     SET CPeriod5 = CPeriod   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempCountryEdu AS TS ON T.CPeriod5 = TS.ROWNO  
         
    
  /*�����Ʒ�*/  
  --��������1  
  UPDATE #TempMaster  
     SET EtcCourseName1 = EtcCourseName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.EtcCourseName1 = TS.ROWNO  
    
  --��������2  
  UPDATE #TempMaster  
     SET EtcCourseName2 = EtcCourseName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.EtcCourseName2 = TS.ROWNO  
         
  --��������3  
  UPDATE #TempMaster  
     SET EtcCourseName3 = EtcCourseName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.EtcCourseName3 = TS.ROWNO  
         
  --��������4  
  UPDATE #TempMaster  
     SET EtcCourseName4 = EtcCourseName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.EtcCourseName4 = TS.ROWNO  
         
  --��������5  
  UPDATE #TempMaster  
     SET EtcCourseName5 = EtcCourseName   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.EtcCourseName5 = TS.ROWNO  
  
  --�����Ⱓ1  
  UPDATE #TempMaster  
     SET EduPeriod1 = EduPeriod   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.EduPeriod1 = TS.ROWNO  
         
  --�����Ⱓ2  
  UPDATE #TempMaster  
     SET EduPeriod2 = EduPeriod   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.EduPeriod2 = TS.ROWNO  
         
  --�����Ⱓ3  
  UPDATE #TempMaster  
     SET EduPeriod3 = EduPeriod   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.EduPeriod3 = TS.ROWNO  
         
  --�����Ⱓ4  
  UPDATE #TempMaster  
     SET EduPeriod4 = EduPeriod   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.EduPeriod4 = TS.ROWNO  
         
  --�����Ⱓ5  
  UPDATE #TempMaster  
     SET EduPeriod5 = EduPeriod   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.EduPeriod5 = TS.ROWNO  
         
  --�ְ��Ⱓ1  
  UPDATE #TempMaster  
     SET EtcInstitute1 = EtcInstitute   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.EtcInstitute1 = TS.ROWNO  
         
  --�ְ��Ⱓ2  
  UPDATE #TempMaster  
     SET EtcInstitute2 = EtcInstitute   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.EtcInstitute2 = TS.ROWNO  
         
  --�ְ��Ⱓ3  
  UPDATE #TempMaster  
     SET EtcInstitute3 = EtcInstitute   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.EtcInstitute3 = TS.ROWNO  
         
  --�ְ��Ⱓ4  
  UPDATE #TempMaster  
     SET EtcInstitute4 = EtcInstitute   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.EtcInstitute4 = TS.ROWNO  
         
  --�ְ��Ⱓ5  
  UPDATE #TempMaster  
     SET EtcInstitute5 = EtcInstitute   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.EtcInstitute5 = TS.ROWNO  
         
  --���1  
  UPDATE #TempMaster  
     SET RstRem1 = RstRem   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.RstRem1 = TS.ROWNO  
         
  --���2  
  UPDATE #TempMaster  
     SET RstRem2 = RstRem   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.RstRem2 = TS.ROWNO  
         
  --���3  
  UPDATE #TempMaster  
     SET RstRem3 = RstRem   
      FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.RstRem3 = TS.ROWNO  
         
  --���4  
  UPDATE #TempMaster  
     SET RstRem4 = RstRem   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.RstRem4 = TS.ROWNO  
         
  --���5  
  UPDATE #TempMaster  
     SET RstRem5 = RstRem   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempEdu AS TS ON T.RstRem5 = TS.ROWNO  
         
    
  /*��������*/  
  --�����Ⱓ1  
  UPDATE #TempMaster  
     SET RestDate1 = RestDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempRest AS TS ON T.RestDate1 = TS.ROWNO  
         
  --�����Ⱓ2  
  UPDATE #TempMaster  
     SET RestDate2 = RestDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempRest AS TS ON T.RestDate2 = TS.ROWNO    
         
         
  --��������1  
  UPDATE #TempMaster  
     SET RestReason1 = RestReason   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempRest AS TS ON T.RestReason1 = TS.ROWNO    
         
  --��������2  
  UPDATE #TempMaster  
     SET RestReason2 = RestReason   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempRest AS TS ON T.RestReason2 = TS.ROWNO  
         
  --�������1   
  UPDATE #TempMaster  
     SET RestRemark1 = RestRemark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempRest AS TS ON T.RestRemark1 = TS.ROWNO  
         
  --�������2   
  UPDATE #TempMaster  
     SET RestRemark2 = RestRemark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempRest AS TS ON T.RestRemark2 = TS.ROWNO  
         
    
  /*��������*/        
  --������  
  UPDATE #TempMaster  
     SET RetDate1 = RetDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempRetire AS TS ON T.RetDate1 = TS.ROWNO         
  
  --�����Ⱓ  
  UPDATE #TempMaster  
     SET WkTrm1 = WkTrm   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempRetire AS TS ON T.WkTrm1 = TS.ROWNO  
         
  --��������  
  UPDATE #TempMaster  
     SET RetCause1 = RetCause   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempRetire AS TS ON T.RetCause1 = TS.ROWNO  
         
  --������  
  UPDATE #TempMaster  
     SET totRetAmt1 = totRetAmt   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempRetire AS TS ON T.totRetAmt1 = TS.ROWNO  
         
         
  --�޴���ȭ  
  UPDATE #TempMaster  
     SET EmpPhone = TS.EmpPhone   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempRetire AS TS ON T.EmpPhone = TS.ROWNO  
         
    
        
   /*�߷ɻ���*/     
   --������1     
  UPDATE #TempMaster  
     SET OrdDate1 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate1 = TS.ROWNO   
         
  --������2     
  UPDATE #TempMaster  
     SET OrdDate2 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate2 = TS.ROWNO   
         
  --������3     
  UPDATE #TempMaster  
     SET OrdDate3 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate3 = TS.ROWNO   
         
  --������4     
  UPDATE #TempMaster  
     SET OrdDate4 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate4 = TS.ROWNO   
         
  --������5     
  UPDATE #TempMaster  
     SET OrdDate5 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate5 = TS.ROWNO   
         
  --������6     
  UPDATE #TempMaster  
     SET OrdDate6 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate6 = TS.ROWNO   
               
  --������7     
  UPDATE #TempMaster  
     SET OrdDate7 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate7 = TS.ROWNO  
         
  --������8     
  UPDATE #TempMaster  
     SET OrdDate8 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate8 = TS.ROWNO   
         
  --������9     
  UPDATE #TempMaster  
     SET OrdDate9 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate9 = TS.ROWNO  
         
  --������10     
  UPDATE #TempMaster  
     SET OrdDate10 = OrdDate   
    FROM #TempMaster AS T  
         LEFT OUTER JOIN #TempOrdEmp  AS TS ON T.OrdDate10 = TS.ROWNO   
         
  --������11     
  UPDATE #TempMaster  
     SET OrdDate11 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate11 = TS.ROWNO   
         
  --������12     
  UPDATE #TempMaster  
     SET OrdDate12 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate12 = TS.ROWNO   
         
  --������13     
  UPDATE #TempMaster  
     SET OrdDate13 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate13 = TS.ROWNO   
         
  --������14     
  UPDATE #TempMaster  
     SET OrdDate14 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate14 = TS.ROWNO   
         
  --������15     
  UPDATE #TempMaster  
     SET OrdDate15 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate15 = TS.ROWNO   
         
  --������16     
  UPDATE #TempMaster  
     SET OrdDate16 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate16 = TS.ROWNO   
         
  --������17     
  UPDATE #TempMaster  
     SET OrdDate17 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate17 = TS.ROWNO   
         
  --������18     
  UPDATE #TempMaster  
     SET OrdDate18 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate18 = TS.ROWNO   
         
  --������19     
  UPDATE #TempMaster  
     SET OrdDate19 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate19 = TS.ROWNO   
         
  --������20     
  UPDATE #TempMaster  
     SET OrdDate20 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate20 = TS.ROWNO  
         
  --������21     
  UPDATE #TempMaster  
     SET OrdDate21 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate21 = TS.ROWNO   
         
  --������22     
  UPDATE #TempMaster  
     SET OrdDate22 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate22 = TS.ROWNO  
         
  --������23     
  UPDATE #TempMaster  
     SET OrdDate23 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate23 = TS.ROWNO  
         
  --������24     
  UPDATE #TempMaster  
     SET OrdDate24 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate24 = TS.ROWNO        
        
  --������25     
  UPDATE #TempMaster  
     SET OrdDate25 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate25 = TS.ROWNO  
         
  --������26     
  UPDATE #TempMaster  
     SET OrdDate26 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate26 = TS.ROWNO  
    
  --������27     
  UPDATE #TempMaster  
     SET OrdDate27 = OrdDate   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.OrdDate27 = TS.ROWNO  
      
  --�߷ɹ�ȣ1  
  UPDATE #TempMaster  
     SET Remark1 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark1 = TS.ROWNO  
         
  --�߷ɹ�ȣ2  
  UPDATE #TempMaster  
     SET Remark2 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark2 = TS.ROWNO  
         
  --�߷ɹ�ȣ3  
  UPDATE #TempMaster  
     SET Remark3 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark3 = TS.ROWNO  
         
  --�߷ɹ�ȣ4  
  UPDATE #TempMaster  
     SET Remark4 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark4 = TS.ROWNO  
    
  --�߷ɹ�ȣ5  
  UPDATE #TempMaster  
     SET Remark5 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark5 = TS.ROWNO  
         
  --�߷ɹ�ȣ6  
  UPDATE #TempMaster  
     SET Remark6 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark6 = TS.ROWNO  
         
  --�߷ɹ�ȣ7  
  UPDATE #TempMaster  
     SET Remark7 = Remark   
      FROM  #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark7 = TS.ROWNO  
         
  --�߷ɹ�ȣ8  
  UPDATE #TempMaster  
     SET Remark8 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark8 = TS.ROWNO  
         
  --�߷ɹ�ȣ9  
  UPDATE #TempMaster  
     SET Remark9 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark9 = TS.ROWNO  
         
  --�߷ɹ�ȣ10  
  UPDATE #TempMaster  
     SET Remark10 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark10 = TS.ROWNO  
         
  --�߷ɹ�ȣ11  
  UPDATE #TempMaster  
     SET Remark11 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark11 = TS.ROWNO  
         
  --�߷ɹ�ȣ12  
  UPDATE #TempMaster  
     SET Remark12 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark12 = TS.ROWNO  
         
  --�߷ɹ�ȣ13  
  UPDATE #TempMaster  
     SET Remark13 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark13 = TS.ROWNO  
         
  --�߷ɹ�ȣ14  
  UPDATE #TempMaster  
     SET Remark14 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark14 = TS.ROWNO  
         
  --�߷ɹ�ȣ15  
  UPDATE #TempMaster  
     SET Remark15 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark15 = TS.ROWNO  
         
  --�߷ɹ�ȣ16  
  UPDATE #TempMaster  
     SET Remark16 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark16 = TS.ROWNO  
         
  --�߷ɹ�ȣ17  
  UPDATE #TempMaster  
     SET Remark17 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark17 = TS.ROWNO  
         
  --�߷ɹ�ȣ18  
  UPDATE #TempMaster  
     SET Remark18 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark18 = TS.ROWNO  
         
  --�߷ɹ�ȣ19  
  UPDATE #TempMaster  
     SET Remark19 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark19 = TS.ROWNO  
         
  --�߷ɹ�ȣ20  
  UPDATE #TempMaster  
     SET Remark20 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark20 = TS.ROWNO  
         
  --�߷ɹ�ȣ21  
  UPDATE #TempMaster  
     SET Remark21 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark21 = TS.ROWNO  
         
  --�߷ɹ�ȣ22  
  UPDATE #TempMaster  
     SET Remark22 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark22 = TS.ROWNO  
         
  --�߷ɹ�ȣ23  
  UPDATE #TempMaster  
     SET Remark23 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark23 = TS.ROWNO  
         
  --�߷ɹ�ȣ24  
  UPDATE #TempMaster  
     SET Remark24 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark24 = TS.ROWNO  
         
  --�߷ɹ�ȣ25  
  UPDATE #TempMaster  
     SET Remark25 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark25 = TS.ROWNO  
         
  --�߷ɹ�ȣ26  
  UPDATE #TempMaster  
     SET Remark26 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark26 = TS.ROWNO  
         
  --�߷ɹ�ȣ27  
  UPDATE #TempMaster  
     SET Remark27 = Remark   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Remark27 = TS.ROWNO  
    
    
  --�Ӹ鳻��1     
  UPDATE #TempMaster  
     SET Contents1 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents1 = TS.ROWNO    
         
  --�Ӹ鳻��2     
  UPDATE #TempMaster  
     SET Contents2 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents2 = TS.ROWNO    
         
  --�Ӹ鳻��3     
  UPDATE #TempMaster  
     SET Contents3 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents3 = TS.ROWNO    
         
  --�Ӹ鳻��4     
  UPDATE #TempMaster  
     SET Contents4 = Contents   
       FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents4 = TS.ROWNO    
         
  --�Ӹ鳻��5     
  UPDATE #TempMaster  
     SET Contents5 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents5 = TS.ROWNO    
         
  --�Ӹ鳻��6     
  UPDATE #TempMaster  
     SET Contents6 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents6 = TS.ROWNO    
         
  --�Ӹ鳻��7     
  UPDATE #TempMaster  
     SET Contents7 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents7 = TS.ROWNO    
         
  --�Ӹ鳻��8     
  UPDATE #TempMaster  
     SET Contents8 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents8 = TS.ROWNO    
         
  --�Ӹ鳻��9     
  UPDATE #TempMaster  
     SET Contents9 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents9 = TS.ROWNO    
         
  --�Ӹ鳻��10     
  UPDATE #TempMaster  
     SET Contents10 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents10 = TS.ROWNO    
         
  --�Ӹ鳻��11     
  UPDATE #TempMaster  
     SET Contents11 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents11 = TS.ROWNO    
         
  --�Ӹ鳻��12     
  UPDATE #TempMaster  
     SET Contents12 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents12 = TS.ROWNO    
         
  --�Ӹ鳻��13     
  UPDATE #TempMaster  
     SET Contents13 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents13 = TS.ROWNO    
         
  --�Ӹ鳻��14     
  UPDATE #TempMaster  
     SET Contents14 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents14 = TS.ROWNO    
         
  --�Ӹ鳻��15     
  UPDATE #TempMaster  
     SET Contents15 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents15 = TS.ROWNO       
        
  --�Ӹ鳻��16     
  UPDATE #TempMaster  
     SET Contents16 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents16 = TS.ROWNO    
         
  --�Ӹ鳻��17     
  UPDATE #TempMaster  
     SET Contents17 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents17 = TS.ROWNO    
         
  --�Ӹ鳻��18     
  UPDATE #TempMaster  
     SET Contents18 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents18 = TS.ROWNO    
         
  --�Ӹ鳻��19     
  UPDATE #TempMaster  
     SET Contents19 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents19 = TS.ROWNO    
         
  --�Ӹ鳻��20     
  UPDATE #TempMaster  
     SET Contents20 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents20 = TS.ROWNO    
         
  --�Ӹ鳻��21     
  UPDATE #TempMaster  
     SET Contents21 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents21 = TS.ROWNO    
         
  --�Ӹ鳻��22     
  UPDATE #TempMaster  
     SET Contents22 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents22 = TS.ROWNO    
         
  --�Ӹ鳻��23     
  UPDATE #TempMaster  
     SET Contents23 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents23 = TS.ROWNO  
         
  --�Ӹ鳻��24     
  UPDATE #TempMaster  
     SET Contents24 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents24 = TS.ROWNO    
         
  --�Ӹ鳻��25     
  UPDATE #TempMaster  
     SET Contents25 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents25 = TS.ROWNO    
         
  --�Ӹ鳻��26     
  UPDATE #TempMaster  
     SET Contents26 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents26 = TS.ROWNO  
    
  --�Ӹ鳻��27     
    UPDATE #TempMaster  
     SET Contents27 = Contents   
    FROM #TempMaster AS T  
       LEFT OUTER JOIN #TempOrdEmp AS TS ON T.Contents27 = TS.ROWNO       
        
  SELECT A.*, B.ValText AS HeadOfFamName, C.ValText AS FamName, D.ValText AS Bon  
  FROM #TempMaster AS A   
      LEFT OUTER JOIN _TDAEmpUserDefine AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                          AND B.EmpSeq = A.EmpSeq  
                                                                          AND B.Serl = 1000001  
      LEFT OUTER JOIN _TDAEmpUserDefine AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                          AND C.EmpSeq = A.EmpSeq  
                                                                          AND C.Serl = 1000002  
         LEFT OUTER JOIN _TDAEmpUserDefine AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq  
                                                                          AND D.EmpSeq = A.EmpSeq  
                                                                          AND D.Serl = 1000003  
  
RETURN  