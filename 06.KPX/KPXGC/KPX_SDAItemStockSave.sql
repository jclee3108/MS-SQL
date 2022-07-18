
IF OBJECT_ID('KPX_SDAItemStockSave') IS NOT NULL 
    DROP PROC KPX_SDAItemStockSave
GO 

-- v2014.11.06 

-- ǰ��������� ���� by����õ (PgmSeq�����ϱ����� ����Ʈ�� ����)
-- v2014.01.14
   /*************************************************************************************************  
   ��  �� - ǰ��������� ����  
   �ۼ��� - 2008.6. : CREATED BY ���ظ� 
   ������ - 2013.12.05 : UPDATE BY �����
                          ǰ�񺰱⺻â��� �ڵ����� ���� �Ǵ� �κп��� �������� �� ����ι��� 
                          â���� ������ ��������� ����ι����� ���� �ǵ��� ����    
          - 2014.01.09 : UPDATE BY ������ -- ���ϰ˻翩�� üũ�׸� �߰�
          - 2014.02.12 : UPDATE BY ����� 
                         1�� ����ι��� 1�� ���������� ��쿡�� ǰ�񺰱⺻â�� ���̺� ������ ��
                         ������� �κ� ����
   *************************************************************************************************/  
  CREATE PROC KPX_SDAItemStockSave
      @xmlDocument    NVARCHAR(MAX),  
      @xmlFlags       INT = 0,  
      @ServiceSeq     INT = 0,  
      @WorkingTag     NVARCHAR(10)= '',  
      @CompanySeq     INT = 1,  
      @LanguageSeq    INT = 1,  
      @UserSeq        INT = 0,  
      @PgmSeq         INT = 0  
  AS  
      DECLARE @docHandle          INT,  
              @MaxSeq             INT,  
              @ItemSeq            INT
       -- ����Ÿ ��� ����  
      CREATE TABLE #TDAItemStock (WorkingTag NCHAR(1) NULL)  
      ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TDAItemStock'  
       -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
      EXEC _SCOMLog  @CompanySeq   ,  
                     @UserSeq      ,  
                     '_TDAItemStock', -- �����̺��  
                     '#TDAItemStock', -- �������̺��  
                     'ItemSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                     'CompanySeq,ItemSeq,IsRollUnit,IsSerialMng,SeriNoCd,IsLotMng,IsQtyChange,SafetyStk,SMLimitTermKind,LimitTerm,STDLoadConvQty,LastUserSeq,LastDateTime,PgmSeq'      
       -- 2014.01.09 : UPDATE BY ������ -- ���ϰ˻翩�� üũ�׸� �߰�
      SELECT CASE WHEN A.WorkingTag = 'A' AND ISNULL(B.ItemSeq, 0) <> 0 THEN 'U'
                  WHEN A.WorkingTag = 'A' AND ISNULL(B.ItemSeq, 0)  = 0 THEN 'A'
                  WHEN A.WorkingTag = 'U' AND ISNULL(B.ItemSeq, 0) <> 0 THEN 'U'
                  WHEN A.WorkingTag = 'U' AND ISNULL(B.ItemSeq, 0)  = 0 THEN 'A'
                  WHEN A.WorkingTag = 'D' AND ISNULL(B.ItemSeq, 0) <> 0 THEN 'D'
                  WHEN A.WorkingTag = 'D' AND ISNULL(B.ItemSeq, 0)  = 0 THEN '' END AS WorkingTag,
             A.IDX_NO, A.DataSeq, A.Selected, A.MessageType, A.Status, A.Result, A.ROW_IDX, A.ItemSeq, A.IsOutQC
        INTO #TPDBaseItemQCType
        FROM #TDAItemStock AS A
        LEFT OUTER JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq    = B.ItemSeq
                                                             AND B.CompanySeq = @CompanySeq
                                                             
       WHERE A.IsOutQC IS NOT NULL
         AND A.Status = 0
   
      -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
      EXEC _SCOMLog  @CompanySeq   ,  
                     @UserSeq      ,  
                     '_TPDBaseItemQCType', -- �����̺��  
                     '#TPDBaseItemQCType', -- �������̺��  
                     'ItemSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                     'CompanySeq, ItemSeq, IsInQC, IsOutQC, IsLastQc, LastUserSeq, LastDateTime, IsInAfterQC, IsNotAutoIn, IsSutakQc'      
   
       -- DELETE    
      IF EXISTS (SELECT 1 FROM #TDAItemStock WHERE WorkingTag = 'D' AND Status = 0  )  
      BEGIN  
          DELETE _TDAItemStock
            FROM #TDAItemStock AS A  
                 JOIN _TDAItemStock AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                      AND B.ItemSeq     = A.ItemSeq
           WHERE A.WorkingTag = 'D' AND Status = 0
      
          IF @@ERROR <> 0    
          BEGIN    
              RETURN    
          END  
          
          
          --------- 20140109 ������ -- ���ϰ˻翩�� üũ�׸� �߰�
          IF EXISTS (SELECT 1 FROM #TPDBaseItemQCType AS A
                              JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq    = B.ItemSeq
                                         AND B.CompanySeq = @CompanySeq
                             WHERE A.WorkingTag = 'D' AND A.Status = 0)
          BEGIN
              DELETE _TPDBaseItemQCType
                FROM #TPDBaseItemQCType AS A
                JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq    = B.ItemSeq
                                                          AND B.CompanySeq = @CompanySeq
               WHERE A.WorkingTag = 'D' AND Status = 0
      
              IF @@ERROR <> 0    
              BEGIN    
                  RETURN    
              END  
          END
      END
       -- Update    
      IF EXISTS (SELECT 1 FROM #TDAItemStock WHERE WorkingTag = 'U' AND Status = 0  )  
      BEGIN   
          UPDATE _TDAItemStock  
             SET   IsRollUnit =  ISNULL(A.IsRollUnit,'0'),
                   IsSerialMng = ISNULL(A.IsSerialMng,'0'),
                   SeriNoCd = ISNULL(A.SeriNoCd,''),
                   IsLotMng = ISNULL(A.IsLotMng,'0'),
                   IsQtyChange = ISNULL(A.IsQtyChange,'0'),
                   SafetyStk = ISNULL(A.SafetyStk,0),
                   SMLimitTermKind = ISNULL(A.SMLimitTermKind,0),
                   LimitTerm = ISNULL(A.LimitTerm,0),
                   STDLoadConvQty = ISNULL(A.STDLoadConvQty,0),
                   LastUserSeq  = @UserSeq,
                   LastDateTime = GETDATE(), 
                   PgmSeq = @PgmSeq 
            FROM #TDAItemStock AS A  
                 JOIN _TDAItemStock AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                      AND B.ItemSeq = A.ItemSeq
           WHERE A.WorkingTag = 'U' AND A.Status = 0
           IF @@ERROR <> 0    
          BEGIN    
              RETURN    
          END  
           INSERT INTO _TDAItemStock(  
               CompanySeq,
               ItemSeq,
               IsRollUnit,
               IsSerialMng,
               SeriNoCd,
               IsLotMng,
               IsQtyChange,
               SafetyStk,
               SMLimitTermKind,
               LimitTerm,
               STDLoadConvQty,
               LastUserSeq,
               LastDateTime, 
               PgmSeq )
          SELECT
               @CompanySeq,
               A.ItemSeq,
               ISNULL(A.IsRollUnit,'0'),
               ISNULL(A.IsSerialMng,'0'),
               ISNULL(A.SeriNoCd,''),
               ISNULL(A.IsLotMng,''),
               ISNULL(A.IsQtyChange,''),
               ISNULL(A.SafetyStk,0),
               ISNULL(A.SMLimitTermKind,0),
               ISNULL(A.LimitTerm,0),
               ISNULL(A.STDLoadConvQty,0),
               @UserSeq,
               GETDATE(), 
               @PgmSeq 
            FROM #TDAItemStock AS A  
                 LEFT OUTER JOIN _TDAItemStock AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                          AND B.ItemSeq = A.ItemSeq
           WHERE A.WorkingTag = 'U' AND A.Status = 0
             AND B.ItemSeq IS NULL
    
          IF @@ERROR <> 0    
          BEGIN    
              RETURN    
          END     
   
          --------- 20140109 ������ -- ���ϰ˻翩�� üũ�׸� �߰�
          IF EXISTS (SELECT 1 FROM #TPDBaseItemQCType AS A
                              JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq = B.ItemSeq
                                                                        AND B.CompanySeq = @CompanySeq
                             WHERE A.WorkingTag = 'U' AND A.Status = 0)
          BEGIN 
              UPDATE _TPDBaseItemQCType
                 SET IsOutQC = ISNULL(A.IsOutQC,'0')
                FROM #TPDBaseItemQCType AS A
                JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq = B.ItemSeq
                                                          AND B.CompanySeq = @CompanySeq
               WHERE A.WorkingTag = 'U' AND Status = 0
      
              IF @@ERROR <> 0    
              BEGIN    
                  RETURN    
              END  
          END
          ELSE IF NOT EXISTS (SELECT 1 FROM #TPDBaseItemQCType AS A
            JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq = B.ItemSeq
                                                                                 AND B.CompanySeq = @CompanySeq
                               WHERE A.WorkingTag = 'A' AND A.Status = 0)
          BEGIN
          INSERT INTO _TPDBaseItemQCType(CompanySeq  , ItemSeq     , IsInQC      , IsOutQC     , IsLastQc ,
                                                     LastUserSeq , LastDateTime, IsInAfterQC , IsNotAutoIn , IsSutakQc)
                      SELECT @CompanySeq , A.ItemSeq , '0' , ISNULL(A.IsOutQC,'0') , '0' , 
                             @UserSeq    , GETDATE() , '0' , '0'       , '0'
                        FROM #TPDBaseItemQCType AS A 
                       WHERE A.WorkingTag = 'A' AND Status = 0
               
              IF @@ERROR <> 0    
              BEGIN    
                  RETURN    
              END  
          END
                  
                  
          SELECT DISTINCT A.ItemSeq, B.BizUnit, B.FactUnit, A.WorkingTag, A.InWHSeq, A.OutWHSEq
            INTO #TDAItemStdWH
            FROM #TDAItemStock AS A
                 JOIN _TDAItemStdWH AS B ON A.ItemSeq = B.ItemSeq
           WHERE B.CompanySeq = @CompanySeq
      
          
          IF @PgmSeq = 1199 OR @PgmSeq = 1197 -- ǰ���� , ������ ��������� ��쿡�� ����
          BEGIN                 
          
          -- ǰ�񺰱⺻â������ UPDATE
           UPDATE _TDAItemStdWH
             SET InWHSeq      = ISNULL(A.InWHSeq,0)  ,
                 OutWHSeq     = ISNULL(A.OutWHSeq,0) ,
                 LastUserSeq  = @UserSeq,
                 LastDateTime = GETDATE()
            FROM #TDAItemStdWH AS A
                 JOIN _TDAItemStdWH AS B ON A.ItemSeq  = B.ItemSeq
                                        AND A.FactUnit = B.FactUnit
                                        AND A.BizUnit  = B.BizUnit
           WHERE B.CompanySeq = @CompanySeq
             AND A.WorkingTag = 'U'
           
           END  
       END  
       
      -- INSERT    
      IF EXISTS (SELECT 1 FROM #TDAItemStock WHERE WorkingTag = 'A' AND Status = 0  )  
      BEGIN  
           INSERT INTO _TDAItemStock(  
               CompanySeq,
               ItemSeq,
               IsRollUnit,
               IsSerialMng,
               SeriNoCd,
               IsLotMng,
               IsQtyChange,
               SafetyStk,
               SMLimitTermKind,
               LimitTerm,
               STDLoadConvQty,
               LastUserSeq,
               LastDateTime, 
               PgmSeq )
          SELECT
               @CompanySeq,
               ItemSeq,
               ISNULL(IsRollUnit,'0'),
               ISNULL(IsSerialMng,'0'),
               ISNULL(SeriNoCd,''),
               ISNULL(IsLotMng,''),
               ISNULL(IsQtyChange,''),
               ISNULL(SafetyStk,0),
               ISNULL(SMLimitTermKind,0),
               ISNULL(LimitTerm,0),
               ISNULL(STDLoadConvQty,0),
               @UserSeq,
               GETDATE(), 
               @PgmSeq 
            FROM #TDAItemStock   
           WHERE WorkingTag = 'A' AND Status = 0 
    
          IF @@ERROR <> 0    
          BEGIN    
              RETURN    
          END     
   
          --------- 20140109 ������ -- ���ϰ˻翩�� üũ�׸� �߰�
          IF EXISTS (SELECT 1 FROM #TPDBaseItemQCType AS A
                              JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq = B.ItemSeq
                                                                        AND B.CompanySeq = @CompanySeq
                             WHERE A.WorkingTag = 'U' AND A.Status = 0)
          BEGIN 
              UPDATE _TPDBaseItemQCType
                 SET IsOutQC = ISNULL(A.IsOutQC,'0')
                FROM #TPDBaseItemQCType AS A
                JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq    = B.ItemSeq
                                                          AND B.CompanySeq = @CompanySeq
               WHERE A.WorkingTag = 'U' AND Status = 0
      
              IF @@ERROR <> 0    
              BEGIN    
                  RETURN    
              END  
          END
          ELSE IF NOT EXISTS (SELECT 1 FROM #TPDBaseItemQCType AS A
                                JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq    = B.ItemSeq
                                                                          AND B.CompanySeq = @CompanySeq
                               WHERE A.WorkingTag = 'A' AND A.Status = 0)
              BEGIN
              INSERT INTO _TPDBaseItemQCType(CompanySeq  , ItemSeq     , IsInQC      , IsOutQC     , IsLastQc ,
                                             LastUserSeq , LastDateTime, IsInAfterQC , IsNotAutoIn , IsSutakQc)
              SELECT @CompanySeq , A.ItemSeq , '0 ' , ISNULL(A.IsOutQC,'0') , '0' , 
                     @UserSeq    , GETDATE() , '0'  , '0' , '0'
                FROM #TPDBaseItemQCType AS A 
               WHERE A.WorkingTag = 'A' AND Status = 0
               
              IF @@ERROR <> 0    
              BEGIN    
                  RETURN    
              END     
          END
   
          --===================================================================================--
          -- 20140212 ����� �߰� â���Ͽ� �ִ� ��������� ����ι��� �����ü� �ֵ��� ���� --
          --===================================================================================--
        IF @PgmSeq = 1199 OR @PgmSeq = 1197 -- ǰ���� , ������ ��������� ��쿡�� ����
        BEGIN
        -- ǰ�񺰱⺻â������ �ֱ� 
          INSERT INTO _TDAItemStdWH
          (
              CompanySeq, 
              ItemSeq, 
              BizUnit, 
              FactUnit, 
              InWHSeq,
              OutWHSeq, 
              LastUserSeq, 
              LastDateTime
          ) 
          SELECT DISTINCT
                 @CompanySeq,
                 A.ItemSeq, 
                 ISNULL(B.BizUnit,0)  AS BizUnit, 
                 ISNULL(B.FactUnit,0) AS FactUnit, 
                 ISNULL(A.InWHSeq,0)  AS InWHSeq ,
                 ISNULL(A.OutWHSeq,0) AS OutWHSeq,
                 @UserSeq,
                 GETDATE()
            FROM #TDAItemStock AS A
                 JOIN _TDAWH   AS B ON A.InWHSeq    = B.WHSeq
           WHERE B.CompanySeq = @CompanySeq  
             AND A.WorkingTag = 'A'
         END
         END    
      SELECT *  
        FROM #TDAItemStock  
    
      RETURN