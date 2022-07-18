IF OBJECT_ID('KPXCM_SPDMPSProdPlanPilotCheck') IS NOT NULL 
    DROP PROC KPXCM_SPDMPSProdPlanPilotCheck 
GO 

-- v2016.03.02 
    
-- �����ȹGantt_kpx-üũ by ������, ����üũ ���� by����õ ( ����,������ �ƿ� ���ܽ�Ŵ ) 
-- ����۾����ö����� ���� SP���� 
CREATE PROC KPXCM_SPDMPSProdPlanPilotCheck
 @xmlDocument    NVARCHAR(MAX),        
 @xmlFlags       INT     = 0,        
 @ServiceSeq     INT     = 0,        
 @WorkingTag     NVARCHAR(10)= '',        
 @CompanySeq     INT     = 1,        
 @LanguageSeq    INT     = 1,        
 @UserSeq        INT     = 0,        
 @PgmSeq         INT     = 0        
      
AS         
    
    DECLARE @SiteInitialName NVARCHAR(100), @SPName NVARCHAR(100)        
        
    SELECT @SiteInitialName = ISNULL(EnvValue,'') FROM _TCOMEnv WHERE EnvSeq = 2 AND CompanySeq = @CompanySeq        
        
    --IF EXISTS (select * from sysobjects where name like @SiteInitialName +'_SPDMPSProdPlanCheck')        
    --BEGIN        
    --    SELECT @SPName = @SiteInitialName +'_SPDMPSProdPlanCheck'        
                
    --    EXEC @SPName @xmlDocument,@xmlFlags,@ServiceSeq,@WorkingTag,@CompanySeq,@LanguageSeq,@UserSeq,@PgmSeq        
    --    RETURN              
        
    --END        
        
      
    DECLARE @Count       INT,      
            @Seq         INT,      
            @MessageType INT,      
            @Status      INT,      
            @Results     NVARCHAR(250),  
            @DeleteValue INT       
      
    
    
    -- ���� ����Ÿ ��� ����        

    CREATE TABLE #TPDMPSDailyProdPlan (WorkingTag NCHAR(1) NULL)        
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDMPSDailyProdPlan'           
    IF @@ERROR <> 0 RETURN    
   
--select * from #TPDMPSDailyProdPlan
    --CREATE TABLE #Link( WorkingTag NCHAR(1) NULL )      
    --EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#Link'     
    --IF @@ERROR <> 0 RETURN

    EXEC dbo._SCOMEnv @CompanySeq,6266,@UserSeq,@@PROCID,@DeleteValue OUTPUT  
     
/*****************************************************************************************************************/    
-- ��ǰ�������� �ҿ����� ��Ͽ���    
/*****************************************************************************************************************/    
    
    delete from #TPDMPSDailyProdPlan
    where Itemseq = 0

	declare @Maxrow  INT

	-- �̵���ġ ó�� �۾���ȹ�� ���� �ʿ��ؼ� �߰���

	--if   EXISTS(select 1 from #TPDMPSDailyProdPlan where WorkingTag = 'D')
	--begin

	--  select @Maxrow = Max(DataSeq)
	--   from #TPDMPSDailyProdPlan

	--  insert into #TPDMPSDailyProdPlan
	--   (WorkingTag,IDX_NO,DataSeq,Selected,MessageType,Status,Result,ROW_IDX,IsChangedMst,FactUnitName,FactUnit,ProdPlanDateFr
	--   ,ProdPlanDateTo,WorkCenterName,WorkCenterSeq,Capacity,BOMRev,BOMRevName,DeptSeq,FromSeq,FromSerl,FromSTDQty
	--   ,FromSubSerl,FromTableSeq,ItemName,ItemNo,ItemSeq,ProcRev,ProcRevName,ProdDeptName,ProdDeptSeq,ProdPlanDate
	--   ,ProdPlanEndDate,ProdPlanNo,ProdPlanQty,ProdPlanSeq,Remark,Spec,StockInDate,ToPgmSeq,ToTableSeq,UnitName
	--   ,UnitSeq,WorkCond1,WorkCond2,WorkCond3,WorkCond4,WorkCond5,WorkCond6,WorkCond7,TableName,SrtDate,EndDate
	--   ,NodeID,Sort,ProdFlagName,ProdFlag)
	--  select A.WorkingTag,@Maxrow + Row_Number() over(Order by A.ProdPlanSeq) ,@Maxrow + Row_Number() over(Order by A.ProdPlanSeq)
	--        ,A.Selected
	--		,A.MessageType
	--		,A.Status
	--		,A.Result
	--		,A.ROW_IDX,A.IsChangedMst
	--        ,A.FactUnitName,A.FactUnit,A.ProdPlanDateFr,A.ProdPlanDateTo,A.WorkCenterName,A.WorkCenterSeq,A.Capacity
	--		,A.BOMRev,A.BOMRevName,A.DeptSeq,A.FromSeq,A.FromSerl
	--         ,A.FromSTDQty,A.FromSubSerl,A.FromTableSeq,A.ItemName,A.ItemNo,A.ItemSeq,A.ProcRev,A.ProcRevName,A.ProdDeptName
	--		 ,A.ProdDeptSeq,A.ProdPlanDate,A.ProdPlanEndDate,A.ProdPlanNo,A.ProdPlanQty,B.SuccessorProdPalnSeq,A.Remark,A.Spec
	--		 ,A.StockInDate,A.ToPgmSeq,A.ToTableSeq,A.UnitName,A.UnitSeq,A.WorkCond1,A.WorkCond2,A.WorkCond3,A.WorkCond4
	--		 ,A.WorkCond5,A.WorkCond6,A.WorkCond7,A.TableName,A.SrtDate,A.EndDate,A.NodeID,A.Sort,A.ProdFlagName,A.ProdFlag
	--		 --,A.CompanySeq,A.PredecessorProdPlanSeq,A.SuccessorProdPalnSeq --,A.LastUserSeq,A.LastDateTime
 --      from #TPDMPSDailyProdPlan as a
	--	      Join  KPX_TPDMPSProdPlanRelation  as b with(Nolock) ON B.CompanySeq = @CompanySeq And B.PredecessorProdPlanSeq  = A.ProdPlanSeq 
	--   where WorkingTag = 'D' 

	--end


    IF (SELECT Count(*) 
	      FROM #TPDMPSDailyProdPlan AS A 
		       LEFT OUTER JOIN _TPDROUItemProcMat AS B ON A.ItemSeq = B.ItemSeq AND A.BOMRev = B.BOMRev and A.ProcRev = B.ProcRev AND B.CompanySeq = @CompanySeq    
            WHERE A.WorkingTag <> 'D'    
              AND A.Status = 0    
              AND B.ItemSeq IS NULL) > 0    
    BEGIN     
        UPDATE #TPDMPSDailyProdPlan        
           SET Result        = '��ǰ���������ҿ����簡 ��ϵ��� ���� ǰ���Դϴ�.',                          
               MessageType   = 17009,        
               Status        = 1      
          FROM #TPDMPSDailyProdPlan AS A LEFT OUTER JOIN _TPDROUItemProcMat AS B ON A.ItemSeq = B.ItemSeq AND A.BOMRev = B.BOMRev and A.ProcRev = B.ProcRev AND B.CompanySeq = @CompanySeq    
        WHERE A.WorkingTag <> 'D'    
          AND A.Status = 0    
          AND B.ItemSeq IS NULL    
            
    END    
    


/****************************************************************************************************************/    
-- ��ǰ�������� ��ũ���� ��Ͽ���    
/*****************************************************************************************************************/    
   --  select * from #TPDMPSDailyProdPlan
  --     select * from _TPDROUItemProcWC
	 --  where CompanySeq = 2
	 --   and ItemSeq = 356
		--and WorkCenterseq =33

     
    IF (SELECT COUNT(*) FROM #TPDMPSDailyProdPlan                         AS A    
                             LEFT OUTER JOIN _TPDROUItemProcRev           AS B ON B.companySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq --AND A.ProcRev = B.ProcRev    
                             LEFT OUTER JOIN _TPDProcTypeItem             AS C ON C.companySeq = @CompanySeq AND B.ProcTypeSeq = C.ProcTypeSeq    
                             LEFT OUTER JOIN _TPDROUItemProcWC            AS D ON D.companySeq = @CompanySeq AND A.FactUnit = D.FactUnit AND A.ProcRev = D.ProcRev and A.ItemSeq = D.ItemSeq and A.WorkCenterSeq = D.WorkCenterSeq                               
                       WHERE A.WorkingTag <> 'D'    
                         AND A.Status = 0    
                         AND D.ItemSeq IS NULL ) > 0    
    BEGIN     

	 --   select 1
		--from #TPDMPSDailyProdPlan as a
		--   join _TPDROUItemProcWC as b
		--where WorkCenterseq = 1
		--  and ITemSEq = 356


        UPDATE #TPDMPSDailyProdPlan        
           SET Result        = '['+Isnull(A2.WorkCenterName,'') +'/'+Isnull(A1.ItemName,'')+ ']'+ '��ǰ�� ������ ��ũ���Ͱ� ��ϵ��� ���� ǰ���Դϴ�.',                          
               MessageType   = 17009,        
               Status        = 1      
            FROM #TPDMPSDailyProdPlan              AS A    
	           LEFT OUTER JOIN _TDAItem                     AS A1 ON A1.CompanySeq = @CompanySeq And A1.ItemSeq = A.ItemSeq
			   LEFT OUTER JOIN _TPDBaseWorkCenter           AS A2 ON A2.CompanySeq = @CompanySeq And A2.WorkCenterSeq = A.WorkCenterSeq
               LEFT OUTER JOIN _TPDROUItemProcRev           AS B ON B.companySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq  --AND A.ProcRev = B.ProcRev    
               LEFT OUTER JOIN _TPDProcTypeItem             AS C ON C.companySeq = @CompanySeq AND B.ProcTypeSeq = C.ProcTypeSeq    
               LEFT OUTER JOIN _TPDROUItemProcWC            AS D ON D.companySeq = @CompanySeq AND A.FactUnit = D.FactUnit AND A.ItemSeq = D.ItemSeq AND A.ProcRev = D.ProcRev 
			                                                    and A.WorkCenterSeq = D.WorkCenterSeq     
         WHERE A.WorkingTag <> 'D'    
           AND A.Status = 0    
           AND D.ItemSeq IS NULL     
       
    END    
    
/****************************************************************************************************************/    
-- �������庰 ����ǰ�� �����帧 ���� ��Ͽ���    
/*****************************************************************************************************************/    
    
    IF (SELECT Count(*) FROM #TPDMPSDailyProdPlan AS A JOIN _TPDROUItemProcRevFactUnit AS B ON A.ItemSeq = B.ItemSeq AND A.FactUnit = B.FactUnit and A.ProcRev = B.ProcRev AND B.CompanySeq = @CompanySeq    
            WHERE A.WorkingTag <> 'D'    
              AND A.Status = 0    
              AND B.ItemSeq IS NULL) = 0    
    BEGIN     
        UPDATE #TPDMPSDailyProdPlan        
           SET Result        = '�������庰 ����ǰ�� ��ϵ��� ���� ǰ���Դϴ�.',                          
               MessageType   = 17009,        
               Status        = 1      
          FROM #TPDMPSDailyProdPlan AS A     
         LEFT OUTER JOIN _TPDROUItemProcRevFactUnit AS B ON A.ItemSeq = B.ItemSeq     
                                                        AND A.FactUnit = B.FactUnit     
                                                        and A.ProcRev = B.ProcRev     
                                                        and A.BOMRev = B.BOMRev     
                                                        AND B.CompanySeq = @CompanySeq    
        WHERE A.WorkingTag <> 'D'    
          AND A.Status = 0    
          AND B.ItemSeq IS NULL    
            
    END    
    --SELECT 124,* FROM #TPDMPSDailyProdPlan 

/****************************************************************************************************************/    
-- BOM/���� ������ ȯ������ ���� üũ       --      11.11.28 BY �輼ȣ    
/*****************************************************************************************************************/    
    
      EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                            @Status      OUTPUT,      
                            @Results     OUTPUT,      
                            1293                  , -- @1�� @2��(��) Ȯ���ϼ���.     
                            @LanguageSeq       ,       
                            7,'',                   -- ǰ��    
                            907, ''                 -- ����ȯ������    
    
    
    UPDATE A    
       SET Result        = REPLACE(@Results, '��', '(' + ISNULL(I.ItemNo,'') + ')'),                          
           MessageType   = @MessageType,        
           Status        = @Status      
      FROM #TPDMPSDailyProdPlan AS A    
      LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq
                                                AND I.ItemSeq = A.ItemSeq
      LEFT OUTER JOIN _TDAItemDefUnit      AS B ON @CompanySeq = B.CompanySeq    
                                               AND A.ItemSeq = B.ItemSeq    
                                               AND B.UMModuleSeq = 1003003  
  LEFT OUTER JOIN _TDAItemUnit         AS C ON B.CompanySeq = C.CompanySeq    
                                               AND B.ItemSeq = C.ItemSeq    
                                               AND B.STDUnitSeq = C.UnitSeq  
      LEFT OUTER JOIN _TDAItemDefUnit      AS D ON @CompanySeq = D.CompanySeq    
                                               AND A.ItemSeq = D.ItemSeq    
                                               AND D.UMModuleSeq = 1003004  
      LEFT OUTER JOIN _TDAItemUnit         AS E ON D.CompanySeq = E.CompanySeq    
                                               AND D.ItemSeq = E.ItemSeq    
                                                 AND D.STDUnitSeq = E.UnitSeq  
     WHERE A.WorkingTag IN ('A', 'U')    
       AND A.Status = 0    
       AND (B.ItemSeq IS NULL OR C.ItemSeq IS NULL OR D.ItemSeq IS NULL OR E.ItemSeq IS NULL)       

--select @Results
/****************************************************************************************************************/    
-- ��ǰ���������ҿ����翡 ����ǰ �����Ǿ� �ִ� ��� üũ        --  11.12.21 BY �輼ȣ    
/*****************************************************************************************************************/    
    
    --SELECT 165,* FROM #TPDMPSDailyProdPlan 
    IF EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlan AS A     
                   JOIN _TPDROUItemProcMat AS B ON A.ItemSeq = B.ItemSeq AND A.BOMRev = B.BOMRev and A.ProcRev = B.ProcRev AND B.CompanySeq = @CompanySeq    
            WHERE A.WorkingTag <> 'D'    
              AND A.Status = 0    
              AND ISNULL(B.AssyItemSeq, 0) = 0)     
    BEGIN     
    
      EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                            @Status      OUTPUT,      
                            @Results     OUTPUT,      
                            1293                  , -- @1�� @2��(��) Ȯ���ϼ���.    
                            @LanguageSeq       ,       
                            11356,'',                   -- ��ǰ���������ҿ�����    
                            3970, ''                 -- ����ǰ    
    
        UPDATE A        
           SET Result        = @Results,                 
               MessageType   = @MessageType,        
               Status        = @Status      
          FROM #TPDMPSDailyProdPlan AS A     
                   JOIN _TPDROUItemProcMat AS B ON A.ItemSeq = B.ItemSeq AND A.BOMRev = B.BOMRev and A.ProcRev = B.ProcRev AND B.CompanySeq = @CompanySeq    
            WHERE A.WorkingTag <> 'D'    
              AND A.Status = 0    
              AND ISNULL(B.AssyItemSeq, 0) = 0    
            
    END    
    --SELECT 192,* FROM #TPDMPSDailyProdPlan 
    IF @DeleteValue IS NULL  
        SELECT @DeleteValue = '0'  
    
    -----------------------------------------         
    -- �ҿ����� ���� ����   --          
    -----------------------------------------            
    IF @DeleteValue = '1' --<�����ȹ>  MRP(�ҿ�����) ������ �����Ͱ� ���� ��� ��õ �����ȹ/�۾����� �� ���� �Ұ� ����  
    BEGIN  
        IF EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag = 'D'  AND Status = 0   )        
        BEGIN        
            IF EXISTS (SELECT 1 FROM _TPDMRPDailyItem AS A   
                                     JOIN #TPDMPSDailyProdPlan AS B ON A.CompanySeq  = @CompanySeq    
                                                                   AND A.ProdPlanSeq = B.ProdPlanSeq       
                               WHERE B.WorkingTag = 'D'    
                                 AND B.Status = 0  )        
            BEGIN   
                EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                                      @Status      OUTPUT,        
                                      @Results     OUTPUT,        
                                      1310               , -- @1�� @2��(��) �����Ǿ� �־� @3 �� �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1310)        
                                      @LanguageSeq       , 
                                      2509,                -- �����ȹ (SELECT * FROM _TCADictionary WHERE WordSeq = 2509)  
                                      '',  
                                      34477,               -- �ҿ����� (SELECT * FROM _TCADictionary WHERE WordSeq = 34477)  
                                      '',  
                                      308,                 -- ���� (SELECT * FROM _TCADictionary WHERE WordSeq = 308)  
                                      ''  
                       
                 UPDATE #TPDMPSDailyProdPlan          
                    SET Result        = ProdPlanNo + ':' + @Results,                            
                        MessageType   = @MessageType,          
                        Status        = @Status                   
            END        
        END     
    END  
      
    -------------------------------------------        
      -- ��뿩��üũ         
    -------------------------------------------       
    -------------------------------------------        
    -- ��������üũ        
    -------------------------------------------        
    -- ���� SP Call ����        
        
    -------------------------------------------        
    -- ���࿩��üũ        
    -------------------------------------------        
    -- ���� SP Call ����        
        
    -------------------------------------------        
    -- Ȯ������üũ        
    -------------------------------------------        
    -- ���� SP Call ����        
    
    --POP ���� ó�� Ȯ��
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          8                  , -- @2 @1(@3)��(��) ��ϵǾ� ����/���� �� �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 8)      
                          @LanguageSeq       ,       
                          0, ''   -- SELECT * FROM _TCADictionary WHERE Word like '%�ڿ�%' 
    UPDATE A
       SET Result        = @Results,
           MessageType   = @MessageType,
           Status        = @Status
      FROM #TPDMPSDailyProdPlan AS A
           JOIN _TPDSFCWorkOrder AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                  AND B.ProdPlanSeq = A.ProdPlanSeq
           JOIN KPX_TPDSFCWorkOrder_POP AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                         AND C.WorkOrderSeq = B.WorkOrderSeq
                                                         AND C.WorkOrderSerl = B.WorkOrderSerl
                                                         AND C.IsPacking = '0'
     WHERE C.ProcYN = '3'
       AND A.WorkingTag IN ('U', 'D')
    
    
    
    /* ���� by����õ ( ��Ʈ ����� �����ִ� ���� ����Sp���� �ƿ� ���� ��Ŵ )
    -----------------------------------------       
    -- ���࿩��üũ   --        
    -----------------------------------------          
      EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                            @Status      OUTPUT,      
                            @Results     OUTPUT,      
                            8                  , -- @2 @1(@3)��(��) ��ϵǾ� ����/���� �� �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 8)      
                            @LanguageSeq       ,       
                            0,    
                            '�������'   -- SELECT * FROM _TCADictionary WHERE Word like '%�ڿ�%'      
        
    IF EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag  IN ('U','D')  AND Status = 0   )      
    BEGIN      
        --IF EXISTS (SELECT 1 FROM _TPDSFCWorkOrder AS A JOIN #TPDMPSDailyProdPlan AS B ON A.CompanySeq = @CompanySeq  AND A.ProdPlanSeq = B.ProdPlanSeq     
        --                                                                             WHERE B.WorkingTag  IN ('U','D')  AND B.Status = 0  )      
        --BEGIN      
             UPDATE A        
                SET Result        = replace(replace(@Results,'(@3)��(��)','��'),'@2',''),                          
                    MessageType   = @MessageType,        
                    Status        = @Status
               FROM #TPDMPSDailyProdPlan AS A   
                    JOIN _TPDSFCWorkOrder AS O WITH(NOLOCK) ON O.CompanySeq = @CompanySeq AND O.ProdPlanSeq = A.ProdPlanSeq
                    JOIN _TPDSFCWorkReport AS B ON B.CompanySeq = @CompanySeq AND B.WorkOrderSeq = O.WorkOrderSeq AND B.WorkOrderSerl = O.WorkOrderSerl
              WHERE A.WorkingTag = 'D'

            UPDATE A        
                SET Result        = replace(replace(@Results,'(@3)',''),'@2',''),                          
                    MessageType   = @MessageType,        
                    Status        = @Status
                    --select *
               FROM #TPDMPSDailyProdPlan AS A   
                    JOIN _TPDMPSDailyProdPlan AS B ON B.CompanySeq = @CompanySeq AND B.ProdPlanSeq = A.ProdPlanSeq
                
              WHERE A.WorkingTag = 'U'
                AND A.FactUnit <> B.FactUnit
                AND A.WorkCenterSeq <> B.WorkCenterSeq
                AND A.ItemSeq <> B.ItemSeq
                AND A.ProdPlanQty <> B.ProdQty
                AND A.WorkCond1 <> B.Workcond1
                AND A.WorkCond2 <> B.Workcond2
                AND A.WorkCond3 <> B.Workcond3
                AND A.SrtDate <> B.SrtDate
                AND A.EndDate <> B.EndDate
        --END      
    END      
    
    
    */
    -------------------------------------------       
    ---- �˻絥���� Ȯ��   --        
    ------------------------------------------- 
    --  EXEC dbo._SCOMMessage @MessageType OUTPUT,      
    --                        @Status      OUTPUT,      
    --                        @Results     OUTPUT,      
    --                        8                  , -- @2 @1(@3)��(��) ��ϵǾ� ����/���� �� �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 8)      
    --                        @LanguageSeq       ,       
    --                        0,    
    --                        '�˻����'   -- SELECT * FROM _TCADictionary WHERE Word like '%�ڿ�%'  
    ----�˻��Ƿ�
    --UPDATE C       
    --   SET Result        = replace(replace(@Results,'(@3)��(��)','��'),'@2',''),                          
    --       MessageType   = @MessageType,        
    --       Status        = @Status
    --  FROM KPX_TQCTestRequestItem AS A
    --       JOIN _TPDSFCWorkOrder AS B ON B.CompanySeq = A.CompanySeq AND B.WorkOrderSeq = A.SourceSeq AND B.WorkOrderSerl = A.SourceSerl 
    --       JOIN #TPDMPSDailyProdPlan AS C ON B.ProdPlanSeq = B.ProdPlanSeq
    --       JOIN KPX_TQCTestResult AS D ON D.CompanySeq = A.CompanySeq AND D.ReqSeq = A.ReqSeq
    -- WHERE A.CompanySeq = @CompanySeq
    --   AND C.WorkingTag = 'U'
    --   AND C.Status = 0
    --   AND A.SMSouceType = 1000522004
    --   AND A.LotNo <> C.WorkCond3

    --SELECT 292,* FROM #TPDMPSDailyProdPlan 
    -------------------------------------------  
    -- �����ȹ��ȣ ��Ģ  
    -------------------------------------------      
    
        DECLARE @IDX_NO INT,    
                @ProdDate NCHAR(8),    
                @ProdPlanNo     NVARCHAR(100),    
                @CurrDate NCHAR(8),    
                @CurrDateYn NCHAR(1),    
                @FactUnit   INT    
           
    -- �������庰 �����ȹ��ȣ ����(�ڵ�/����) �߰��� ���� �߰� 2010. 12. 3. hkim    
    -- �������庰�� ������ ���          
    IF EXISTS (SELECT 1 FROM _TCOMCreateNoDefineDtl AS A JOIN #TPDMPSDailyProdPlan AS B ON A.FirstUnit = B.FactUnit WHERE A.TableName = '_TPDMPSDailyProdPlan' AND A.CompanySeq = @CompanySeq AND A.IsAutoCreate = '1' )    
    BEGIN    
         IF ISNULL((SELECT BaseDateColumnName FROM _TCOMCreateNoDefine where CompanySeq = @CompanySeq and TableName = '_TPDMPSDailyProdPlan'),'') = ''     
        BEGIN    
            SELECT @CurrDateYn = '1'    
            SELECT @CurrDate = CONVERT(NCHAR(8), GetDATE(),112)    
        END    
    
       DECLARE Cursor1 CURSOR FOR        
           SELECT IDX_NO, ProdPlanEndDate, FactUnit  FROM #TPDMPSDailyProdPlan  WHERE WorkingTag = 'A' AND Status = 0        
        OPEN Cursor1        
        FETCH NEXT FROM Cursor1 INTO @IDX_NO, @ProdDate, @FactUnit    
        WHILE @@Fetch_Status = 0        
        BEGIN     
                IF @CurrDateYn = '1' SELECT @ProdDate = @CurrDate    
    
                EXEC dbo._SCOMCreateNo  'PD',       
                                        '_TPDMPSDailyProdPlan',       
                                        @CompanySeq,       
                                        @FactUnit,       
                                        @ProdDate,       
                                        @ProdPlanNo OUTPUT  
                                           
                UPDATE  #TPDMPSDailyProdPlan      
                   SET  ProdPlanNo  = ISNULL(@ProdPlanNo, '')    
              WHERE  IDX_NO = @IDX_NO        
    
            
        FETCH NEXT FROM Cursor1 INTO @IDX_NO, @ProdDate,@FactUnit    
        END        
          CLOSE Cursor1        
        DEALLOCATE Cursor1      
        
    END    
    -- ���κ��� �ڵ�/���� ������ ���     
    ELSE IF (SELECT IsAutoCreate FROM _TCOMCreateNoDefine WHERE TableName = '_TPDMPSDailyProdPlan' and CompanySeq = @CompanySeq) = '1' AND NOT EXISTS (SELECT 1 FROM _TCOMCreateNoDefineDtl WHERE CompanySeq = @CompanySeq AND TableName = '_TPDMPSDailyProdPlan' )      
    BEGIN    
        DECLARE @ProdDeptSeq    INT,        -- ��������μ� ( �����ȹ�Է�ȭ�鿡�� �Է¹���)  
                @DeptSeq        INT,         -- �α��������� �μ�   
                @SecondInitialUnit INT     -- �μ� �̴ϼ� ����, @ProdDeptSeq OR @DeptSeq �� ���  
  
        SELECT TOP 1 @DeptSeq = DeptSeq FROM #TPDMPSDailyProdPlan  
  
        IF ISNULL((SELECT BaseDateColumnName FROM _TCOMCreateNoDefine where CompanySeq = @CompanySeq and TableName = '_TPDMPSDailyProdPlan'),'') = ''     
        BEGIN    
            SELECT @CurrDateYn = '1'    
            SELECT @CurrDate = CONVERT(NCHAR(8), GetDATE(),112)    
        END    
    
          
        DECLARE Cursor1 CURSOR FOR        
           SELECT IDX_NO, SrtDate, FactUnit, ProdDeptSeq  FROM #TPDMPSDailyProdPlan  WHERE WorkingTag = 'A' AND Status = 0  AND  ProdPlanNo = ''    
        OPEN Cursor1        
        FETCH NEXT FROM Cursor1 INTO @IDX_NO, @ProdDate, @FactUnit, @ProdDeptSeq   
   
        WHILE @@Fetch_Status = 0        
        BEGIN        
    
                IF @CurrDateYn = '1' SELECT @ProdDate = @CurrDate    
                                  
                -- �ι�° �̴ϼ��ڵ� ����  
                SELECT @SecondInitialUnit = CASE WHEN @ProdDeptSeq <> 0 THEN @ProdDeptSeq ELSE @DeptSeq END  
   
                EXEC dbo._SCOMCreateNo  'PD',       
                                        '_TPDMPSDailyProdPlan',       
                                        @CompanySeq,       
                                        @FactUnit,       
                                        @ProdDate,       
                                        @ProdPlanNo OUTPUT,  
                                        @SecondInitialUnit     
                                          
                UPDATE  #TPDMPSDailyProdPlan      
                   SET  ProdPlanNo  = ISNULL(@ProdPlanNo, '')    
                 WHERE  IDX_NO = @IDX_NO        
    
            
        FETCH NEXT FROM Cursor1 INTO @IDX_NO, @ProdDate,@FactUnit, @ProdDeptSeq    
        END        
        CLOSE Cursor1        
        DEALLOCATE Cursor1      
    
    END    
    
    --SELECT 389,* FROM #TPDMPSDailyProdPlan 
      EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                        @Status      OUTPUT,      
                        @Results     OUTPUT,      
                        1107                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1107)      
          @LanguageSeq       ,   -- SELECT * FROM _TCAMessageLanguage WHERE Message like '%��ϵ�%'    
                        0,    
                        '�����ȹ��ȣ'   -- SELECT * FROM _TCADictionary WHERE Word like '%��ϵ�%'      
    
    
     
    -- �����ȹ��ȣ �ڵ������� �ƴϸ� �ߺ�üũ   :: �ڵ�ä���� ��쿡�� ���� �Է½ô� �ߺ�üũ�� �ʿ�������.. �ּ�ó�� 2012.07.11 BY ��³�  
    --IF (SELECT IsAutoCreate FROM _TCOMCreateNoDefine WHERE TableName = '_TPDMPSDailyProdPlan' and CompanySeq = @CompanySeq) <> '1'     
    --    AND NOT EXISTS (SELECT 1 FROM _TCOMCreateNoDefineDtl AS A JOIN #TPDMPSDailyProdPlan AS B ON A.FirstUnit = B.FactUnit WHERE A.TableName = '_TPDMPSDailyProdPlan' AND A.CompanySeq = @CompanySeq)    
    --BEGIN     
        IF EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag  IN ('A')  AND Status = 0 AND ISNULL(FromTableSeq, 0) <> 7 )      
        BEGIN    
            UPDATE #TPDMPSDailyProdPlan        
               SET Result        = replace(replace(@Results,'(@3)',''),'@2',''),                          
                   MessageType   = @MessageType,        
                   Status        = @Status                    
              FROM #TPDMPSDailyProdPlan As A JOIN _TPDMPSDailyProdPlan  AS B ON A.ProdPlanNo = B.ProdPlanNo AND B.CompanySeq = @CompanySeq       
               WHERE A.WorkingTag = 'A'    
      AND A.Status = 0  
        END    
  
                                      
                                  
                                      
    -- �����ȹ ��ȣ�� �ڵ� ä�� �� �Է� �� ���� ������ üũ    2010. 12. 3. hkim    
    IF EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag IN ('A', 'U') AND Status = 0 AND ProdPlanNo = '')    
    BEGIN    
      EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                        @Status      OUTPUT,      
                        @Results     OUTPUT,      
                        1039                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 8)      
                        @LanguageSeq       ,   -- SELECT * FROM _TCAMessageLanguage WHERE Message like '%��ϵ�%'    
                        0,    
                        '�����ȹ��ȣ'   -- SELECT * FROM _TCADictionary WHERE Word like '%��ϵ�%'      
        
            UPDATE #TPDMPSDailyProdPlan        
               SET Result        = @Results, --replace(replace(@Results,'(@3)',''),'@2',''),                          
                   MessageType   = @MessageType,        
                   Status        = @Status      
              FROM #TPDMPSDailyProdPlan AS A     
             WHERE A.WorkingTag IN ('A', 'U')    
               AND Status = 0    
               AND ProdPlanNo = ''    
    END    
       
-- �����ȹ��ȣ�� �������� ��� �ߺ�üũ ���ش�     --  2011.03.29 �輼ȣ �߰�    
    
    IF EXISTS(SELECT 1 FROM #TPDMPSDailyProdPlan AS A    
                       JOIN _TPDMPSDailyProdPlan AS B ON A.ProdPlanSeq = B.ProdPlanSeq     
                                                     AND B.CompanySeq  = @CompanySeq    
                        WHERE A.WorkingTag = 'U'     
                          AND A.ProdPlanNo <> B.ProdPlanNo  
                          AND ISNULL(A.FromTableSeq, 0) <> 7)    
     BEGIN    
    
      EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                        @Status      OUTPUT,      
                        @Results     OUTPUT,      
                        1107                  ,      
                        @LanguageSeq       ,       
                        1524,    
                        '�����ȹ��ȣ',    
                        1524,    
                        '�����ȹ��ȣ'    
    
            UPDATE #TPDMPSDailyProdPlan        
               SET Result        = @Results,                
                   MessageType   = @MessageType,        
                   Status        = @Status      
              FROM #TPDMPSDailyProdPlan AS A      
     
             WHERE A.WorkingTag IN ('U')    
    AND A.Status = 0    
               AND A.ProdPlanNo <> ''     
               AND A.ProdPlanNo IN (SELECT ProdPlanNo FROM  _TPDMPSDailyProdPlan WHERE CompanySeq = @CompanySeq)      
     END    

    

    -------------------------------------------        
    -- INSERT ��ȣ�ο�(�� ������ ó��)        
    -------------------------------------------       
        
    SELECT @Count = COUNT(1) FROM #TPDMPSDailyProdPlan WHERE WorkingTag = 'A' --@Count������(AND Status = 0 ����)    
    IF @Count > 0        
    BEGIN           
    
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TPDMPSDailyProdPlan', 'ProdPlanSeq', @Count        
               
        UPDATE #TPDMPSDailyProdPlan        
           SET ProdPlanSeq = @Seq + DataSeq    
         WHERE WorkingTag = 'A'       
           AND Status = 0                   
    END
--select * from #TPDMPSDailyProdPlan
    -------------------------------------------  
    --LotNo�ο�
    -------------------------------------------  
    CREATE TABLE #ProdPlan(IDX INT IDENTITY(1,1), ProdPlanSeq INT, LotNo NVARCHAR(100), ItemName NVARCHAR(100), ItemSeq INT,
                           BaseMM NCHAR(6), IsFlake NCHAR(1), IsMon NCHAR(1), SrtDate NCHAR(8), WCNo NCHAR(2), SrtTime NCHAR(4))
    
    SELECT ROW_NUMBER() OVER(ORDER BY A.ItemSeq) AS IDX,
           A.ItemSeq,
           CASE WHEN D.MngValSeq = 1010361002 THEN '1'
                ELSE '0' END AS IsFlake,
           (SELECT '1' FROM KPX_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 27
                                          AND EnvValue = A.ItemSeq AND D.MngValSeq = 1010361002) AS IsMon,
           MIN(A.SrtDate) AS SrtDate
      INTO #ProdItem
      FROM #TPDMPSDailyProdPlan AS A
           LEFT OUTER JOIN _TDAItemUserDefine AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq
                                                               AND D.ItemSeq = A.ItemSeq
                                                               AND D.MngSerl = 1000001
     WHERE A.WorkingTag = 'A'
     GROUP BY A.ItemSeq, D.MngValSeq
   /*
--select * FROM #TPDMPSDailyProdPlan 
--select * from #ProdItem
    DECLARE @IDX        INT,
            @MaxIDX     INT,
            @PlanIDX    INT,
            @PlanMaxIDX INT,
            @MaxLotNo   NVARCHAR(100),
            @BaseMM     NCHAR(6)
    
    SELECT @IDX = 1,
           @MaxIDX = MAX(IDX) FROM #ProdItem
--select * from #ProdItem
    WHILE(1=1)
    BEGIN
        --DELETE #ProdPlan
        
        INSERT INTO #ProdPlan
             SELECT DISTINCT B.ProdPlanSeq, '', I.ItemName, A.ItemSeq, LEFT(B.SrtDate,6),
                    A.IsFlake, A.IsMon, B.SrtDate, ISNULL(R.WCNo,''), B.WorkCond1
               FROM #ProdItem AS A
                    JOIN #TPDMPSDailyProdPlan AS B ON B.ItemSeq = A.ItemSeq AND B.WorkingTag = 'A'
                    JOIN _TDAItem AS I ON I.CompanySeq = @CompanySeq AND I.ItemSeq = A.ItemSeq
                    LEFT OUTER JOIN KPX_TPDWorkCenterRate AS R WITH(NOLOCK) ON R.CompanySeq = @CompanySeq
                                                                           AND R.WorkCenterSeq = B.WorkCenterSeq
              WHERE IDX = @IDX
              ORDER BY B.SrtDate, B.WorkCond1

        SELECT @PlanIDX = 1,
               @PlanMaxIDX = MAX(IDX) FROM #ProdPlan
        SELECT @BaseMM = BaseMM FROM #ProdPlan

        IF EXISTS (SELECT 1 FROM #ProdPlan WHERE IsFlake = '0')
        BEGIN
            SELECT @MaxLotNo = MAX(RIGHT(WorkCond3,4)) 
              FROM _TPDMPSDailyProdPlan 
             WHERE CompanySeq = @CompanySeq
               AND LEFT(SrtDate,6) = @BaseMM
               AND ItemSeq = (SELECT ItemSeq FROM #ProdItem WHERE IDX = @IDX AND IsFlake = '0')

--SELECT ItemSeq FROM #ProdItem WHERE IDX = @IDX AND IsFlake = '0'
--select MAX(RIGHT(WorkCond3,4))
--FROM _TPDMPSDailyProdPlan 
--WHERE CompanySeq = @CompanySeq
--AND LEFT(SrtDate,6) = @BaseMM
--AND ItemSeq = (SELECT ItemSeq FROM #ProdItem WHERE IDX = @IDX AND IsFlake = '0')
--select * from #ProdPlan

            IF ISNULL(@MaxLotNo,'') = ''
                SELECT @MaxLotNo = '0000'
            
            WHILE(1=1)
            BEGIN
--select * 
--FROM #ProdPlan AS A
--                       JOIN (SELECT ROW_NUMBER() OVER(ORDER BY SrtDate, SrtTime) AS IDX, 
--                                    ProdPlanSeq
--                               FROM #ProdPlan
--                              WHERE ItemSeq = (SELECT ItemSeq FROM #ProdItem WHERE IDX = @IDX AND IsFlake = '0')) AS B ON B.ProdPlanSeq = A.ProdPlanSeq
--                 WHERE A.IsFlake = '0'
--                   AND ItemSeq = (SELECT ItemSeq FROM #ProdItem WHERE IDX = @IDX AND IsFlake = '0')
                   
                UPDATE A 
                   SET LotNo = RIGHT(BaseMM,4)+
                               --'-'+ 
                               RIGHT(CONVERT(NVARCHAR(10), '0000'+CONVERT(NVARCHAR(10),(CONVERT(INT, @MaxLotNo)+
                                    B.IDX))),4)
                  FROM #ProdPlan AS A
                       JOIN (SELECT ROW_NUMBER() OVER(ORDER BY SrtDate, SrtTime) AS IDX, 
                                    ProdPlanSeq
                               FROM #ProdPlan
                              WHERE ItemSeq = (SELECT ItemSeq FROM #ProdItem WHERE IDX = @IDX AND IsFlake = '0')) AS B ON B.ProdPlanSeq = A.ProdPlanSeq
                 WHERE A.IsFlake = '0'
                   AND ItemSeq = (SELECT ItemSeq FROM #ProdItem WHERE IDX = @IDX AND IsFlake = '0')
                 

                SELECT @PlanIDX = @PlanIDX +1
                IF @PlanIDX > ISNULL(@PlanMaxIDX, 0) 
                    BREAK
            END
        END

        --Flake -  Ư����ǰ LotNo 7�ڸ�   = �����߻� ��(2)+��(2)+��(3)     
        IF EXISTS (SELECT 1 FROm #ProdPlan WHERE IsFlake = '1' AND ISNULL(IsMon,'0') = '1')
        BEGIN
            SELECT @MaxLotNo = MAX(WorkCond3) 
              FROM _TPDMPSDailyProdPlan 
             WHERE CompanySeq = @CompanySeq
               AND LEFT(SrtDate,6) = @BaseMM
               AND ItemSeq = (SELECT ItemSeq FROM #ProdItem WHERE IDX = @IDX AND IsFlake = '1' AND IsMon = '1')
            
            IF ISNULL(@MaxLotNo, '') = ''
                SELECT @MaxLotNo = SUBSTRING(SrtDate,3,4)+'0'+RIGHT(SrtDate, 2)
                  FROM #ProdItem 
                 WHERE IDX = @IDX AND IsFlake = '1' AND IsMon = '1'
            
            UPDATE A
               SET LotNo = @MaxLotNo
              FROM #ProdPlan AS A
             WHERE A.IsFlake = '1' AND IsMon = '1'
        END
        
        --Flake -  �Ϲ���ǰ LotNo 8�ڸ� = �Ϻ� ��(2)+��(2)+��(2)+������(2)
        IF EXISTS (SELECT 1 FROm #ProdPlan WHERE IsFlake = '1' AND ISNULL(IsMon,'0') = '0')
        BEGIN

            SELECT @MaxLotNo = ''

            UPDATE A
               SET LotNo = CASE WHEN @MaxLotNo ='' THEN SUBSTRING(SrtDate,3,4)+RIGHT(SrtDate, 2) 
                                ELSE @MaxLotNo END
                           +RIGHT('00'+A.WCNo, 2)
              FROM #ProdPlan AS A
             WHERE A.IsFlake = '1' AND ISNULL(IsMon,'0') = '0'
        END
                
        SELECT @IDX = @IDX +1
        IF @IDX > ISNULL(@MaxIDX, 0) 
            BREAK
    END
--select * from #ProdPlan
    UPDATE A
       SET WorkCond3 = B.LotNo
      FROM #TPDMPSDailyProdPlan AS A
           JOIN #ProdPlan AS B ON B.ProdPlanSeq = A.ProdPlanSeq
     WHERE A.WorkingTag = 'A'
       AND A.NodeId NOT IN (SELECT PredecessorNodeID FROM #Link)
       AND A.NodeId NOT IN (SELECT SuccessorNodeID FROM #Link)
    */       
    --SELECT * from #ProdPlan
      
    SELECT * FROM #TPDMPSDailyProdPlan       
    --SELECT * FROM #Link
     --where PredecessorNodeID <> 0
       --Or SuccessorNodeID <> 0
RETURN          
/******************************************************************************************************************************************************/
GO


