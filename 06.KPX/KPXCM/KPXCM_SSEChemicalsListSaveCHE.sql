
IF OBJECT_ID('KPXCM_SSEChemicalsListSaveCHE') IS NOT NULL 
    DROP PROC KPXCM_SSEChemicalsListSaveCHE
GO 

-- v2015.06.22 

-- ����Ʈ�� ���� by����õ 
/************************************************************
��  �� - ������-ȭ�й���ǰ�����_capro : ����
�ۼ��� - 20110602
�ۼ��� - �����
************************************************************/
CREATE PROC dbo.KPXCM_SSEChemicalsListSaveCHE
    @xmlDocument    NVARCHAR(MAX),
    @xmlFlags       INT             = 0,
    @ServiceSeq     INT             = 0,
    @WorkingTag     NVARCHAR(10)    = '',
    @CompanySeq     INT             = 1,
    @LanguageSeq    INT             = 1,
    @UserSeq        INT             = 0,
    @PgmSeq         INT             = 0
AS
    CREATE TABLE #KPXCM_TSEChemicalsListCHE (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TSEChemicalsListCHE'
    IF @@ERROR <> 0 RETURN
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TSEChemicalsListCHE')    
    
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TSEChemicalsListCHE'    , -- ���̺��        
                  '#KPXCM_TSEChemicalsListCHE'    , -- �ӽ� ���̺��        
                   'ChmcSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , ''
    
    -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT
    -- DELETE
    IF EXISTS (SELECT TOP 1 1 FROM #KPXCM_TSEChemicalsListCHE WHERE WorkingTag = 'D' AND Status = 0)
    BEGIN
        DELETE A
          FROM KPXCM_TSEChemicalsListCHE A
          JOIN #KPXCM_TSEChemicalsListCHE B ON ( A.ChmcSeq       = B.ChmcSeq )
         WHERE A.CompanySeq  = @CompanySeq
           AND B.WorkingTag = 'D'
           AND B.Status = 0
        IF @@ERROR <> 0  RETURN
           
        DELETE A
          FROM _TSEChemicalsWkListCHE A
          JOIN #KPXCM_TSEChemicalsListCHE B ON ( A.ChmcSeq = B.ChmcSeq )
         WHERE A.CompanySeq  = @CompanySeq
           AND B.WorkingTag = 'D'
           AND B.Status = 0
        IF @@ERROR <> 0  RETURN         
    
    END
    
    -- UPDATE
    IF EXISTS (SELECT 1 FROM #KPXCM_TSEChemicalsListCHE WHERE WorkingTag = 'U' AND Status = 0)
    BEGIN
        
        UPDATE A
           SET ItemSeq      = B.ItemSeq      ,
               ToxicName    = B.ToxicName    ,
               MainPurpose  = B.MainPurpose  ,
               Content      = B.Content      ,
               PrintName    = B.PrintName    ,
               Remark       = B.Remark       ,
               LastDateTime = GETDATE()      ,
               LastUserSeq  = @UserSeq       ,
               Acronym         = B.Acronym, 
               CasNo           = B.CasNo, 
               Molecular       = B.Molecular, 
               ExplosionBottom = B.ExplosionBottom, 
               ExplosionTop    = B.ExplosionTop, 
               StdExpo         = B.StdExpo, 
               Toxic           = B.Toxic,
               FlashPoint      = B.FlashPoint,
               IgnitionPoint   = B.IgnitionPoint,
               Pressure        = B.Pressure,
               IsCaustic       = B.IsCaustic,
               IsStatus        = B.IsStatus,
               UseDaily        = B.UseDaily,
               State           = B.State,
               PoisonKind      = B.PoisonKind,
               DangerKind      = B.DangerKind,
               SafeKind        = B.SafeKind,
               SaveKind        = B.SaveKind, 
               GroupKind       = B.GroupKind, 
               MakeCountry     = B.MakeCountry, 
               CustSeq         = B.CustSeq, 
               IsSave          = B.IsSave 
               
          FROM KPXCM_TSEChemicalsListCHE AS A
          JOIN #KPXCM_TSEChemicalsListCHE AS B ON ( A.ChmcSeq = B.ChmcSeq )
         WHERE A.CompanySeq = @CompanySeq
           AND B.WorkingTag = 'U'
           AND B.Status = 0
        
        IF @@ERROR <> 0  RETURN
    
    END
    
    -- INSERT
    IF EXISTS (SELECT 1 FROM #KPXCM_TSEChemicalsListCHE WHERE WorkingTag = 'A' AND Status = 0)
    BEGIN
        INSERT INTO KPXCM_TSEChemicalsListCHE 
        ( 
            CompanySeq  ,   ChmcSeq,    ItemSeq,        ToxicName,          MainPurpose ,
            Content     ,   PrintName,  Remark,         LastDateTime,       LastUserSeq,
            Acronym,        CasNo,      Molecular,      ExplosionBottom,    ExplosionTop, 
            StdExpo,        Toxic,      FlashPoint,     IgnitionPoint,      Pressure,
            IsCaustic,      IsStatus,   UseDaily,       State,              PoisonKind,
            DangerKind,     SafeKind,   SaveKind,       GroupKind,          MakeCountry, 
            CustSeq,        IsSave
        )
        SELECT @CompanySeq ,    ChmcSeq     ,ItemSeq     ,ToxicName   ,MainPurpose ,
               Content     ,    PrintName   ,Remark      ,GETDATE()   ,@UserSeq, 
               Acronym,         CasNo,      Molecular,      ExplosionBottom,    ExplosionTop, 
               StdExpo,         Toxic,      FlashPoint,     IgnitionPoint,      Pressure,
               IsCaustic,       IsStatus,   UseDaily,       State,              PoisonKind,
               DangerKind,      SafeKind,   SaveKind,       GroupKind,          MakeCountry, 
               CustSeq,        IsSave
                
          FROM #KPXCM_TSEChemicalsListCHE AS A
         WHERE A.WorkingTag = 'A'
           AND A.Status = 0
        
        IF @@ERROR <> 0 RETURN
    END
     
    SELECT * FROM #KPXCM_TSEChemicalsListCHE
     
    RETURN