IF OBJECT_ID('KPXCM_SPDMPSProdPlanCheck') IS NOT NULL 
    DROP PROC KPXCM_SPDMPSProdPlanCheck
GO 

-- v2015.09.22 

-- õ�Ȱ��� LotNo �ʼ� üũ by����õ 

/************************************************************    
  ��  �� - ������-�����ȹ�Է� : üũ    
  �ۼ��� - 20090826    
  �ۼ��� - �̼���    
  UPDATE ::  �����ȹ ��ȣ ������ �ߺ� üũ �߰�     :: 2011.03.29 BY �輼ȣ  
         ::  ������ BOM/������� ȯ������ ���� ��� üũ :: 2011.11.28 BY �輼ȣ   
         ::  ��ǰ���������ҿ������Ͽ� ����ǰ�����Ǿ� ������� üũ :: 2011.12.21 BY �輼ȣ 
         ::  ��ȹ��ȣ ä���� �̴ϼȴ��� �μ��� ����ǵ��� ����   :: 2012.01.05  BY �輼ȣ
         ::  �����ȹ ���� 0 ������ ��� üũ                    ::  12.05.16 BY �輼ȣ
         ::  ������Ʈ���� �Ѿ�°��ϰ�� (FromtableSeq = 7) �����ȹ �ߺ� ���       :: 12.07.04 BY �輼ȣ
         ::  �ڵ�ä���� ����ϴ� ���� �����ȣ�� �������� �Է��� ��� �����ԷµȰ� ����ǵ��� ����  :: 12.07.11 BY ��³� 
 ************************************************************/    
 CREATE PROC dbo.KPXCM_SPDMPSProdPlanCheck   
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
       
     IF EXISTS (select * from sysobjects where name like @SiteInitialName +'_SPDMPSProdPlanCheck')      
     BEGIN      
         SELECT @SPName = @SiteInitialName +'_SPDMPSProdPlanCheck'      
               
         EXEC @SPName @xmlDocument,@xmlFlags,@ServiceSeq,@WorkingTag,@CompanySeq,@LanguageSeq,@UserSeq,@PgmSeq      
         RETURN            
       
     END      
       
     
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
    
     EXEC dbo._SCOMEnv @CompanySeq,6266,@UserSeq,@@PROCID,@DeleteValue OUTPUT
    
    UPDATE A 
       SET Result = '[LotNo] �ʼ��׸��� �����Ǿ����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #TPDMPSDailyProdPlan AS A 
     WHERE A.WorkingTag IN ( 'A', 'U' ) 
       AND A.Status = 0 
       AND A.FactUnit = 6 -- õ�Ȱ��� 
       AND ISNULL(A.WorkCond3,'') = '' 
    
 /*****************************************************************************************************************/  
 -- ��ǰ�������� �ҿ����� ��Ͽ���  
 /*****************************************************************************************************************/  
   
   
     IF (SELECT Count(*) FROM #TPDMPSDailyProdPlan AS A LEFT OUTER JOIN _TPDROUItemProcMat AS B ON A.ItemSeq = B.ItemSeq AND A.BOMRev = B.BOMRev and A.ProcRev = B.ProcRev AND B.CompanySeq = @CompanySeq  
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
   
     IF (SELECT COUNT(*) FROM #TPDMPSDailyProdPlan              AS A  
                              LEFT OUTER JOIN _TPDROUItemProcRev           AS B ON B.companySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq AND A.ProcRev = B.ProcRev  
                              LEFT OUTER JOIN _TPDProcTypeItem             AS C ON C.companySeq = @CompanySeq AND B.ProcTypeSeq = C.ProcTypeSeq  
                              LEFT OUTER JOIN _TPDROUItemProcWC AS D ON D.companySeq = @CompanySeq AND A.FactUnit = D.FactUnit AND A.ItemSeq = D.ItemSeq AND A.ProcRev = D.ProcRev AND C.ProcSeq = D.ProcSeq                  
                        WHERE A.WorkingTag <> 'D'  
                          AND A.Status = 0  
                          AND D.ItemSeq IS NULL ) > 0  
     BEGIN   
         UPDATE #TPDMPSDailyProdPlan      
            SET Result        = '��ǰ�� ������ ��ũ���Ͱ� ��ϵ��� ���� ǰ���Դϴ�.',                        
                MessageType   = 17009,      
                Status        = 1    
           FROM #TPDMPSDailyProdPlan              AS A  
                LEFT OUTER JOIN _TPDROUItemProcRev           AS B ON B.companySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq AND A.ProcRev = B.ProcRev  
                LEFT OUTER JOIN _TPDProcTypeItem             AS C ON C.companySeq = @CompanySeq AND B.ProcTypeSeq = C.ProcTypeSeq  
                LEFT OUTER JOIN _TPDROUItemProcWC AS D ON D.companySeq = @CompanySeq AND A.FactUnit = D.FactUnit AND A.ItemSeq = D.ItemSeq AND A.ProcRev = D.ProcRev AND C.ProcSeq = D.ProcSeq                  
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
        SET Result        = REPLACE(@Results, '��', '(' + A.ItemNo + ')'),                        
            MessageType   = @MessageType,      
            Status        = @Status    
       FROM #TPDMPSDailyProdPlan AS A  
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
         
   
 /****************************************************************************************************************/  
 -- ��ǰ���������ҿ����翡 ����ǰ �����Ǿ� �ִ� ��� üũ        --  11.12.21 BY �輼ȣ  
 /*****************************************************************************************************************/  
   
   
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
     
 -- �۾������������� ������� ����Ǿ������ �ܷ��� ���� ������ �ȵǰ������Ƿ� �ϴ� �ּ�ó��
 -- �۾������������� �ܷ��� ���ؼ��� ���� �����ϵ��� �����Ǹ� �ش� �ּ��� ���� �� ����       -- 12.07.12 BY �輼ȣ
 --/****************************************************************************************************************/  
 ---- �����ȹ ���� 0 ������ ��� üũ        --  12.05.16 BY �輼ȣ
 --/*****************************************************************************************************************/  
 --
 --    IF EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag IN ('A', 'U') AND Status = 0 AND ProdPlanQty <= 0) 
 --     BEGIN
 --
 --
 --        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
 --                            @Status      OUTPUT,    
 --                            @Results     OUTPUT,    
 --                            1196                  , -- @��(��) Ȯ���ϼ���
 --                            @LanguageSeq       ,     
 --                            6423,''                   -- �����ȹ����  
 --
 --        UPDATE #TPDMPSDailyProdPlan 
 --           SET Result        = @Results,               
 --               MessageType   = @MessageType,      
 --               Status        = @Status  
 --          FROM #TPDMPSDailyProdPlan 
 --         WHERE WorkingTag IN ('A', 'U') 
 --           AND Status = 0 
 --           AND ProdPlanQty <= 0
 --
 --
 --     END
    
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
        
   
       -----------------------------------------     
     -- ���࿩��üũ   --      
     -----------------------------------------        
       EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                             @Status      OUTPUT,    
                             @Results     OUTPUT,    
                             8                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 8)    
                             @LanguageSeq       ,     
                             0,  
                             '�۾�����'   -- SELECT * FROM _TCADictionary WHERE Word like '%�ڿ�%'    
      
       
       
     IF EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag  IN ('U','D')  AND Status = 0   )    
     BEGIN    
         IF EXISTS (SELECT 1 FROM _TPDSFCWorkOrder AS A JOIN #TPDMPSDailyProdPlan AS B ON A.CompanySeq = @CompanySeq  AND A.ProdPlanSeq = B.ProdPlanSeq   
                                                                                      WHERE B.WorkingTag  IN ('U','D')  AND B.Status = 0  )    
         BEGIN    
              UPDATE #TPDMPSDailyProdPlan      
                 SET Result        = replace(replace(@Results,'(@3)',''),'@2',''),                        
                     MessageType   = @MessageType,      
                     Status        = @Status               
         END    
     END    
          
   
   
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
            SELECT IDX_NO, ProdPlanEndDate, FactUnit, ProdDeptSeq  FROM #TPDMPSDailyProdPlan  WHERE WorkingTag = 'A' AND Status = 0  AND  ProdPlanNo = ''  
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
   
 --#####################################################################
 --�ߺ��� �����ȹ��ȣ üũ         
 --#####################################################################
       --EXEC dbo._SCOMMessage @MessageType OUTPUT,  
       --                      @Status      OUTPUT,  
       --                      @Results     OUTPUT,  
       --                      6                  , -- �ߺ��� �����Ͱ� �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
       --                      @LanguageSeq       ,   
       --                      1524,''   -- SELECT * FROM _TCADictionary WHERE Word like '%�����ȹ��ȣ%'  
  
       --UPDATE #TPDMPSDailyProdPlan  
       --   SET Result        = REPLACE(@Results,'@2',A.ProdPlanNo),  
       --       MessageType   = @MessageType,  
       --       Status        = @Status  
       --  FROM #TPDMPSDailyProdPlan AS A JOIN ( SELECT S.ProdPlanNo  
       --                                 FROM (  
       --                                       SELECT A1.ProdPlanNo  
       --                                         FROM #TPDMPSDailyProdPlan AS A1  
       --                                        WHERE A1.WorkingTag IN ('A','U')  
       --                                          AND A1.Status = 0  
       --                                       UNION ALL  
       --                                       SELECT A1.ProdPlanNo  
       --                                         FROM _TPDMPSDailyProdPlan AS A1  
       --                                        WHERE A1.Companyseq = @CompanySeq
       --                                          AND A1.ProdPlanSeq NOT IN (SELECT ProdPlanSeq   
       --                                                                       FROM #TPDMPSDailyProdPlan   
       --                                                                      WHERE WorkingTag IN ('U','D')   
       --                                                                        AND Status = 0)  
       --                                      ) AS S  
       --                                GROUP BY S.ProdPlanNo  
       --                                HAVING COUNT(1) > 1  
       --                              ) AS B ON (A.ProdPlanNo = B.ProdPlanNo)  
  
                                      
                                     
                                     
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
     
     SELECT * FROM #TPDMPSDailyProdPlan     
       
 RETURN        
 go
 begin tran 
 exec KPXCM_SPDMPSProdPlanCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <FactUnitName>�ƻ����</FactUnitName>
    <ProdPlanNo />
    <ProdPlanDate>20150922</ProdPlanDate>
    <ItemName>2- ����ǰ(��ǰ)</ItemName>
    <ItemNo>2- ����ǰ(��ǰ)</ItemNo>
    <Spec />
    <UnitName>Kg</UnitName>
    <BOMRevName>00</BOMRevName>
    <ProcRevName>��������</ProcRevName>
    <ProdPlanQty>1</ProdPlanQty>
    <ProdPlanEndDate>20150922</ProdPlanEndDate>
    <ProdDeptName />
    <Remark />
    <FromTableSeq>0</FromTableSeq>
    <FromSeq>0</FromSeq>
    <FromSerl>0</FromSerl>
    <ToTableSeq>0</ToTableSeq>
    <FromQty>0</FromQty>
    <FromSTDQty>0</FromSTDQty>
    <ProdDeptSeq />
    <FactUnit>1</FactUnit>
    <ProcRev>00</ProcRev>
    <ItemSeq>24635</ItemSeq>
    <ProdPlanSeq />
    <BOMRev>00</BOMRev>
    <UnitSeq>2</UnitSeq>
    <WorkCond1 />
    <WorkCond2 />
    <WorkCond3 />
    <WorkCond4>0</WorkCond4>
    <WorkCond5>0</WorkCond5>
    <WorkCond6>0</WorkCond6>
    <WorkCond7>0</WorkCond7>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <DeptSeq>1300</DeptSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=5295,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=5987
rollback 