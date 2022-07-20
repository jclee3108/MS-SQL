  
IF OBJECT_ID('mnpt_SPJTWorkPlanItemSave') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkPlanItemSave  
GO  
    
-- v2017.09.14
  
-- �۾���ȹ�Է�-SS2���� by ����õ
CREATE PROC mnpt_SPJTWorkPlanItemSave
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       

    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTWorkPlanItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTWorkPlanItem'    , -- ���̺��        
                  '#BIZ_OUT_DataBlock2'    , -- �ӽ� ���̺��        
                  'WorkPlanSeq,WorkPlanSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   

    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock2 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock2      AS A   
          JOIN mnpt_TPJTWorkPlanItem    AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkPlanSeq = B.WorkPlanSeq AND A.WorkPlanSerl = B.WorkPlanSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock2 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.UMBisWorkType      = A.UMBisWorkType      ,  
               B.SelfToolSeq        = A.SelfToolSeq        ,  
               B.RentToolSeq        = A.RentToolSeq        ,  
               B.ToolWorkTime       = A.ToolWorkTime       ,  
               B.DriverEmpSeq1      = A.DriverEmpSeq1      ,  
               B.DriverEmpSeq2      = A.DriverEmpSeq2      ,  
               B.DriverEmpSeq3      = A.DriverEmpSeq3      ,  
               B.DUnionDay          = A.DUnionDay          ,  
               B.DUnionHalf         = A.DUnionHalf         ,  
               B.DUnionMonth        = A.DUnionMonth        ,  
               B.DDailyDay          = A.DDailyDay          ,  
               B.DDailyHalf         = A.DDailyHalf         ,  
               B.DDailyMonth        = A.DDailyMonth        ,  
               B.DOSDay             = A.DOSDay             ,  
               B.DOSHalf            = A.DOSHalf            ,  
               B.DOSMonth           = A.DOSMonth           ,  
               B.DEtcDay            = A.DEtcDay            ,  
               B.DEtcHalf           = A.DEtcHalf           ,  
               B.DEtcMonth          = A.DEtcMonth          ,  
               B.NDEmpSeq           = A.NDEmpSeq           ,  
               B.NDUnionUnloadGang  = A.NDUnionUnloadGang  ,  
               B.NDUnionUnloadMan   = A.NDUnionUnloadMan   ,  
               B.NDUnionDailyDay    = A.NDUnionDailyDay    ,  
               B.NDUnionDailyHalf   = A.NDUnionDailyHalf   ,  
               B.NDUnionDailyMonth  = A.NDUnionDailyMonth  ,  
               B.NDUnionSignalDay   = A.NDUnionSignalDay   ,  
               B.NDUnionSignalHalf  = A.NDUnionSignalHalf  ,  
               B.NDUnionSignalMonth = A.NDUnionSignalMonth ,  
               B.NDUnionEtcDay      = A.NDUnionEtcDay      ,  
               B.NDUnionEtcHalf     = A.NDUnionEtcHalf     ,  
               B.NDUnionEtcMonth    = A.NDUnionEtcMonth    ,  
               B.NDDailyDay         = A.NDDailyDay         ,  
               B.NDDailyHalf        = A.NDDailyHalf        ,  
               B.NDDailyMonth       = A.NDDailyMonth       ,  
               B.NDOSDay            = A.NDOSDay            ,  
               B.NDOSHalf           = A.NDOSHalf           ,  
               B.NDOSMonth          = A.NDOSMonth          ,  
               B.NDEtcDay           = A.NDEtcDay           ,  
               B.NDEtcHalf          = A.NDEtcHalf          ,  
               B.NDEtcMonth         = A.NDEtcMonth         ,  
               B.DRemark            = A.DRemark            ,  
               B.LastUserSeq        = @UserSeq           ,
               B.LastDateTime       = GETDATE()          ,
               B.PgmSeq             = @PgmSeq
          FROM #BIZ_OUT_DataBlock2      AS A   
          JOIN mnpt_TPJTWorkPlanItem    AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkPlanSeq = B.WorkPlanSeq AND A.WorkPlanSerl = B.WorkPlanSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END  
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock2 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO mnpt_TPJTWorkPlanItem  
        (   
            CompanySeq, WorkPlanSeq, WorkPlanSerl, UMBisWorkType, SelfToolSeq, 
            RentToolSeq, ToolWorkTime, DriverEmpSeq1, DriverEmpSeq2, DriverEmpSeq3, 
            DUnionDay, DUnionHalf, DUnionMonth, DDailyDay, DDailyHalf, 
            DDailyMonth, DOSDay, DOSHalf, DOSMonth, DEtcDay, 
            DEtcHalf, DEtcMonth, NDEmpSeq, NDUnionUnloadGang, NDUnionUnloadMan, 
            NDUnionDailyDay, NDUnionDailyHalf, NDUnionDailyMonth, NDUnionSignalDay, NDUnionSignalHalf, 
            NDUnionSignalMonth, NDUnionEtcDay, NDUnionEtcHalf, NDUnionEtcMonth, NDDailyDay, 
            NDDailyHalf, NDDailyMonth, NDOSDay, NDOSHalf, NDOSMonth, 
            NDEtcDay, NDEtcHalf, NDEtcMonth, DRemark, FirstUserSeq, 
            FirstDateTime, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, WorkPlanSeq, WorkPlanSerl, UMBisWorkType, SelfToolSeq, 
               RentToolSeq, ToolWorkTime, DriverEmpSeq1, DriverEmpSeq2, DriverEmpSeq3, 
               DUnionDay, DUnionHalf, DUnionMonth, DDailyDay, DDailyHalf, 
               DDailyMonth, DOSDay, DOSHalf, DOSMonth, DEtcDay, 
               DEtcHalf, DEtcMonth, NDEmpSeq, NDUnionUnloadGang, NDUnionUnloadMan, 
               NDUnionDailyDay, NDUnionDailyHalf, NDUnionDailyMonth, NDUnionSignalDay, NDUnionSignalHalf, 
               NDUnionSignalMonth, NDUnionEtcDay, NDUnionEtcHalf, NDUnionEtcMonth, NDDailyDay, 
               NDDailyHalf, NDDailyMonth, NDOSDay, NDOSHalf, NDOSMonth, 
               NDEtcDay, NDEtcHalf, NDEtcMonth, DRemark, @UserSeq, 
               GETDATE(), @USerSeq, GETDATE(), @PgmSeq
          FROM #BIZ_OUT_DataBlock2 AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    RETURN  
    