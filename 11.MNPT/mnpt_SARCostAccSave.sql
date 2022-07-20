IF OBJECT_ID('mnpt_SARCostAccSave') IS NOT NULL 
    DROP PROC mnpt_SARCostAccSave
GO 

-- v2018.01.08 
/************************************************************  
��  �� - ���ڰ��翬������ȯ�漳�� - ����  
�ۼ��� - 2010�� 04�� 19��   
�ۼ��� - �۰��  
************************************************************/  
CREATE PROC dbo.mnpt_SARCostAccSave  
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0,  
    @BgtName        NVARCHAR(200) = ''    
  
AS      
--select * from _TDASMinor where minorseq = 4503004 
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TARCostAcc (WorkingTag NCHAR(1) NULL)    
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TARCostAcc'       
    IF @@ERROR <> 0 RETURN      
  
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
    EXEC _SCOMLog  @CompanySeq   ,  
                   @UserSeq      ,  
                   '_TARCostAcc', -- �����̺��  
                   '#TARCostAcc', -- �������̺��  
                   'SMKindSeq,CostSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                   'CompanySeq,SMKindSeq,CostSeq,CostName,AccSeq,RemSeq,RemValSeq,CashDate,Remark,LastUserSeq,LastDateTime, OppAccSeq, EvidSeq, UMCostType, IsNotUse',
                   '',
                   @PgmSeq  

    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
    EXEC _SCOMLog  @CompanySeq   ,  
                   @UserSeq      ,  
                   'mnpt_TARCostAccSub', -- �����̺��  
                   '#TARCostAcc', -- �������̺��  
                   'SMKindSeq,CostSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                   'CompanySeq, SMKindSeq, CostSeq, CostSClassSeq, FirstUserSeq, FirstDateTime, LastUserSeq, LastDateTime, PgmSeq',
                   '',
                   @PgmSeq  
    
    -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT  
  
    -- DELETE      
    IF EXISTS (SELECT TOP 1 1 FROM #TARCostAcc WHERE WorkingTag = 'D' AND Status = 0)    
    BEGIN    
        DELETE _TARCostAcc  
          FROM _TARCostAcc A JOIN #TARCostAcc B ON (A.SMKindSeq = B.OldSMKindSeq AND A.CostSeq = B.CostSeq)    
         WHERE B.WorkingTag = 'D' AND B.Status = 0      
           AND A.CompanySeq  = @CompanySeq  
        IF @@ERROR <> 0  RETURN  

        DELETE mnpt_TARCostAccSub  
          FROM mnpt_TARCostAccSub A JOIN #TARCostAcc B ON (A.SMKindSeq = B.OldSMKindSeq AND A.CostSeq = B.CostSeq)    
         WHERE B.WorkingTag = 'D' AND B.Status = 0      
           AND A.CompanySeq  = @CompanySeq  
        IF @@ERROR <> 0  RETURN  
  
    END    
  
    -- UPDATE      
    IF EXISTS (SELECT 1 FROM #TARCostAcc WHERE WorkingTag = 'U' AND Status = 0)    
    BEGIN  
        UPDATE _TARCostAcc  
           SET CostName  = B.CostName   
            , AccSeq        = B.AccSeq     
            , RemSeq        = B.RemSeq     
            , RemValSeq     = B.RemValSeq  
            , CashDate      = B.CashDate   
            , Remark        = B.Remark  
            , OppAccSeq     = B.OppAccSeq  
            , EvidSeq       = B.EvidSeq  
            , LastUserSeq   = @UserSeq  
            , LastDateTime  = GETDATE()  
            , UMCostType    = B.UMCostType  
            , Sort          = B.Sort
            , IsNotUse      = B.IsNotUse 
          FROM _TARCostAcc AS A JOIN #TARCostAcc AS B ON (A.SMKindSeq = B.OldSMKindSeq AND A.CostSeq = B.CostSeq)    
         WHERE B.WorkingTag = 'U' AND B.Status = 0      
           AND A.CompanySeq  = @CompanySeq   
        IF @@ERROR <> 0  RETURN 
        
        UPDATE mnpt_TARCostAccSub  
           SET CostSClassSeq  = B.CostSClassSeq
             , LastUserSeq   = @UserSeq  
             , LastDateTime  = GETDATE()  
          FROM mnpt_TARCostAccSub AS A JOIN #TARCostAcc AS B ON (A.SMKindSeq = B.OldSMKindSeq AND A.CostSeq = B.CostSeq)    
         WHERE B.WorkingTag = 'U' AND B.Status = 0      
           AND A.CompanySeq  = @CompanySeq   
        IF @@ERROR <> 0  RETURN  
    END     
  
    -- INSERT  
    IF EXISTS (SELECT 1 FROM #TARCostAcc WHERE WorkingTag = 'A' AND Status = 0)    
    BEGIN    
        INSERT INTO _TARCostAcc   
                    (CompanySeq ,SMKindSeq  ,CostSeq    ,CostName   ,AccSeq  
                    ,RemSeq     ,RemValSeq  ,CashDate   ,Remark     ,LastUserSeq  
                    ,LastDateTime, OppAccSeq, EvidSeq   ,UMCostType ,Sort
                    ,IsNotUse)  
              SELECT @CompanySeq,4503004    ,A.CostSeq  ,A.CostName ,A.AccSeq  -- �Ϲݺ��
                    ,A.RemSeq   ,A.RemValSeq,A.CashDate ,A.Remark   ,@UserSeq         
                    ,GETDATE()  ,A.OppAccSeq,A.EvidSeq  ,A.UMCostType ,A.Sort
                    ,IsNotUse  
              FROM #TARCostAcc AS A     
             WHERE A.WorkingTag = 'A' AND A.Status = 0      
        IF @@ERROR <> 0 RETURN  

        INSERT INTO mnpt_TARCostAccSub   
        (
            CompanySeq, SMKindSeq, CostSeq, CostSClassSeq, FirstUserSeq, 
            FirstDateTime, LastUserSeq, LastDateTime, PgmSeq
        )  
        SELECT @CompanySeq, SMKindSeq, CostSeq, CostSClassSeq, @UserSeq, -- �Ϲݺ��
               GETDATE(), @UserSeq, GETDATE(), @PgmSEq
          FROM #TARCostAcc AS A     
         WHERE A.WorkingTag = 'A' AND A.Status = 0      
        IF @@ERROR <> 0 RETURN  
    END     
    -- ���ȭ�鿡 ������� �Բ� ����ϱ� ���� OUTPUT �߰�  
    -- 2011.02.07 ����  
  
    UPDATE #TARCostAcc   
       SET BgtName = C.BgtName  
      FROM #TARCostAcc AS A JOIN _TACBgtAcc     AS B  
                              ON @CompanySeq    = B.CompanySeq  
                             AND A.AccSeq       = B.AccSeq  
                             AND A.RemSeq       = B.RemSeq  
                             AND A.RemValSeq    = B.RemValSeq  
                            JOIN _TACBgtItem    AS C  
                              ON @CompanySeq    = C.CompanySeq   
                             AND B.BgtSeq       = C.BgtSeq  
  
    SELECT * FROM #TARCostAcc  
RETURN      
  