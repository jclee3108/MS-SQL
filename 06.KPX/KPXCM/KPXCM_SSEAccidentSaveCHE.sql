
IF OBJECT_ID('KPXCM_SSEAccidentSaveCHE') IS NOT NULL 
    DROP PROC KPXCM_SSEAccidentSaveCHE
GO 

-- v2015.06.08 

-- ����Ʈȭ������ Copy by����õ 

/************************************************************
  ��  �� - ������-������ : ����
  �ۼ��� - 20110324
  �ۼ��� - õ���
 ************************************************************/
 CREATE PROC KPXCM_SSEAccidentSaveCHE
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
  AS    
     DECLARE @Count       INT,
             @Seq         INT,
             @MessageType INT,
             @Status      INT,
             @Results     NVARCHAR(250)
  
     -- ���� ����Ÿ ��� ����
     CREATE TABLE #_TSEAccidentCHE (WorkingTag NCHAR(1) NULL) 
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TSEAccidentCHE'
     IF @@ERROR <> 0 RETURN 
  
     -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
     EXEC _SCOMLog  @CompanySeq   ,  
                    @UserSeq      ,  
                    '_TSEAccidentCHE', -- �����̺��  
                    '#_TSEAccidentCHE', -- �������̺��  
                    'AccidentSeq,AccidentSerl' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                    'CompanySeq,AccidentSeq,AccidentSerl,AccidentNo,AccidentClass,DeptSeq,EmpSeq,AccidentType,AccidentGrade,AccidentArea,AreaClass,AccidentName,AccidentDate,AccidentTime,ReportDate,ReporterSeq,InvestFrDate,InvestToDate,Weather,DOW,WV,LeakMatName,LeakMatQty,AccidentEqName,AccidentOutline,AccidentCause,MngRemark,AccidentInjury,PreventMeasure,FirstReporter,FileSeq,LastDateTime,LastUserSeq'
    
    -- DELETE    
     IF EXISTS (SELECT 1 FROM #_TSEAccidentCHE WHERE WorkingTag = 'D' AND Status = 0)  
     BEGIN
         DELETE _TSEAccidentCHE  
           FROM #_TSEAccidentCHE AS A
                JOIN _TSEAccidentCHE AS B WITH(NOLOCK) ON B.CompanySeq   = @CompanySeq  
                                                        AND B.AccidentSeq  = A.AccidentSeq
                                                        AND B.AccidentSerl = A.AccidentSerl
          WHERE A.WorkingTag = 'D' 
            AND A.Status = 0
          IF @@ERROR <> 0 RETURN
     END  
      -- UPDATE
     IF EXISTS (SELECT 1 FROM #_TSEAccidentCHE WHERE WorkingTag = 'U' AND Status = 0)  
     BEGIN
         UPDATE _TSEAccidentCHE
            SET AccidentClass    = A.AccidentClass      ,
                DeptSeq          = A.DeptSeq            ,
                EmpSeq           = A.EmpSeq             ,
                AccidentType     = A.AccidentType       ,
                AccidentGrade    = A.AccidentGrade      ,
                AccidentArea     = A.AccidentArea       ,
                AreaClass        = A.AreaClass          ,
                AccidentName     = A.AccidentName       ,
                AccidentDate     = A.AccidentDate       ,
                AccidentTime     = A.AccidentTime       ,
                ReportDate       = A.ReportDate         ,
                ReporterSeq      = A.ReporterSeq        ,
                InvestFrDate     = A.InvestFrDate       ,
                InvestToDate     = A.InvestToDate       ,
                Weather          = A.Weather            ,
                DOW              = A.DOW                ,
                WV               = A.WV                 ,
                LeakMatName      = A.LeakMatName        ,
                LeakMatQty       = A.LeakMatQty         ,
                AccidentEqName   = A.AccidentEqName     ,
                AccidentOutline  = A.AccidentOutline    ,
                AccidentCause    = A.AccidentCause      ,
                MngRemark        = A.MngRemark          ,
                AccidentInjury   = A.AccidentInjury     ,
                PreventMeasure   = A.PreventMeasure     ,
                FirstReporter    = A.FirstReporter      ,
                FileSeq          = A.FileSeq            ,
                LastDateTime     = GETDATE()            ,
                LastUserSeq      = @UserSeq
           FROM #_TSEAccidentCHE AS A  
                JOIN _TSEAccidentCHE AS B WITH(NOLOCK) ON B.CompanySeq   = @CompanySeq  
                                                        AND B.AccidentSeq  = A.AccidentSeq
                                                        AND B.AccidentSerl = A.AccidentSerl
          WHERE A.WorkingTag = 'U'
            AND A.Status = 0
          IF @@ERROR <> 0 RETURN
     END  
      -- INSERT    
     IF EXISTS (SELECT 1 FROM #_TSEAccidentCHE WHERE WorkingTag = 'A' AND Status = 0) 
     BEGIN  
         INSERT INTO _TSEAccidentCHE (
                CompanySeq       , AccidentSeq      , AccidentSerl     , AccidentNo       , AccidentClass    , 
                DeptSeq          , EmpSeq           , AccidentType     , AccidentGrade    , AccidentArea     , 
                AreaClass        , AccidentName     , AccidentDate     , AccidentTime     , ReportDate       , 
                ReporterSeq      , InvestFrDate     , InvestToDate     , Weather          , DOW              , 
                WV               , LeakMatName      , LeakMatQty       , AccidentEqName   , AccidentOutline  , 
                AccidentCause    , MngRemark        , AccidentInjury   , PreventMeasure   , FirstReporter    , 
                FileSeq          , LastDateTime     , LastUserSeq
         )         
         SELECT @CompanySeq      , AccidentSeq      , AccidentSerl     , AccidentNo       , AccidentClass    , 
                DeptSeq          , EmpSeq           , AccidentType     , AccidentGrade    , AccidentArea     , 
                AreaClass        , AccidentName     , AccidentDate     , AccidentTime     , ReportDate       , 
                ReporterSeq      , InvestFrDate     , InvestToDate     , Weather          , DOW              , 
                WV               , LeakMatName      , LeakMatQty       , AccidentEqName   , AccidentOutline  , 
                AccidentCause    , MngRemark        , AccidentInjury   , PreventMeasure   , FirstReporter    , 
                FileSeq          , GETDATE()        , @UserSeq
           FROM #_TSEAccidentCHE
          WHERE WorkingTag = 'A'
            AND Status = 0
          IF @@ERROR <> 0 RETURN
     END
     SELECT * FROM #_TSEAccidentCHE
  RETURN