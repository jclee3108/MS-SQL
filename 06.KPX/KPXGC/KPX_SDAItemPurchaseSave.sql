
IF OBJECT_ID('KPX_SDAItemPurchaseSave') IS NOT NULL
    DROP PROC KPX_SDAItemPurchaseSave
GO 

-- v2014.11.06 

-- ǰ�񱸸����� ���� by����õ (PgmSeq ���嶧���� ����Ʈ�� ����)

/*************************************************************************************************  
  ��  �� - ǰ�񱸸����� ����  
  �ۼ��� - 2008.6. : CREATED BY ���ظ�     
         - 2014.01.09 : UPDATE BY ������ -- �μ��˻翩�� üũ�׸� �߰�
  *************************************************************************************************/  
 CREATE PROCEDURE KPX_SDAItemPurchaseSave
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
     CREATE TABLE #TDAItemPurchase (WorkingTag NCHAR(1) NULL)  
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TDAItemPurchase'  
  
     -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
     EXEC _SCOMLog  @CompanySeq   ,  
                    @UserSeq      ,  
                    '_TDAItemPurchase', -- �����̺��  
                    '#TDAItemPurchase', -- �������̺��  
                    'ItemSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                    'CompanySeq,ItemSeq,UMPurGroup,MkCustSeq,PurCustSeq,MinQty,StepQty,SMPurKind,IsPurVat,IsAutoPurCreate,OrderQty,DelvDay,CustomTaxRate,SMPurProdType,LastUserSeq,LastDateTime,PgmSeq'      
  
     -- 2014.01.09 : UPDATE BY ������ -- �μ��˻翩�� üũ�׸� �߰�
     SELECT CASE WHEN A.WorkingTag = 'A' AND ISNULL(B.ItemSeq, 0) <> 0 THEN 'U'
                 WHEN A.WorkingTag = 'A' AND ISNULL(B.ItemSeq, 0)  = 0 THEN 'A'
                 WHEN A.WorkingTag = 'U' AND ISNULL(B.ItemSeq, 0) <> 0 THEN 'U'
                 WHEN A.WorkingTag = 'U' AND ISNULL(B.ItemSeq, 0)  = 0 THEN 'A'
                 WHEN A.WorkingTag = 'D' AND ISNULL(B.ItemSeq, 0) <> 0 THEN 'D'
                 WHEN A.WorkingTag = 'D' AND ISNULL(B.ItemSeq, 0)  = 0 THEN '' END AS WorkingTag,
            A.IDX_NO, A.DataSeq, A.Selected, A.MessageType, A.Status, A.Result, A.ROW_IDX, A.ItemSeq, A.IsInQC
       INTO #TPDBaseItemQCType
       FROM #TDAItemPurchase AS A
       LEFT OUTER JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq    = B.ItemSeq
                                                            AND B.CompanySeq = @CompanySeq
      WHERE A.IsInQC IS NOT NULL
        AND A.Status = 0
        
        
     -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
     EXEC _SCOMLog  @CompanySeq   ,  
                    @UserSeq      ,  
                    '_TPDBaseItemQCType', -- �����̺��  
                    '#TPDBaseItemQCType', -- �������̺��  
                    'ItemSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                    'CompanySeq, ItemSeq, IsInQC, IsOutQC, IsLastQc, LastUserSeq, LastDateTime, IsInAfterQC, IsNotAutoIn, IsSutakQc'      
      -- DELETE    
     IF EXISTS (SELECT 1 FROM #TDAItemPurchase WHERE WorkingTag = 'D' AND Status = 0  )  
     BEGIN  
         DELETE _TDAItemPurchase
         FROM #TDAItemPurchase AS A  
              JOIN _TDAItemPurchase AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                      AND B.ItemSeq     = A.ItemSeq
         WHERE A.WorkingTag = 'D' AND Status = 0
     
         IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END  
         
     -- 2014.01.09 : UPDATE BY ������ -- �μ��˻翩�� üũ�׸� �߰�
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
     IF EXISTS (SELECT 1 FROM #TDAItemPurchase WHERE WorkingTag = 'U' AND Status = 0  )  
     BEGIN   
         UPDATE _TDAItemPurchase  
            SET  UMPurGroup      = ISNULL(A.UMPurGroup,0),
                 MkCustSeq       = ISNULL(A.MkCustSeq,0),
                 PurCustSeq      = ISNULL(A.PurCustSeq,0),
                 MinQty          = ISNULL(A.MinQty,0),
                 StepQty         = ISNULL(A.StepQty,0),
                 SMPurKind       = ISNULL(A.SMPurKind,0),
                 IsPurVat        = ISNULL(A.IsPurVat,''),
                 IsAutoPurCreate = ISNULL(A.IsAutoPurCreate,''),
                 OrderQty        = ISNULL(A.OrderQty,0),
                 DelvDay         = ISNULL(A.DelvDay,0),
                 CustomTaxRate   = ISNULL(A.CustomTaxRate,0),
                 SMPurProdType   = ISNULL(A.SMPurProdType,0),
                 LastUserSeq     = @UserSeq,
                 LastDateTime    = GETDATE(), 
                 PgmSeq          = @PgmSeq 
           FROM #TDAItemPurchase AS A  
                     JOIN _TDAItemPurchase AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                             AND B.ItemSeq     = A.ItemSeq
          WHERE A.WorkingTag = 'U' AND A.Status = 0
          IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END  
  
         INSERT INTO _TDAItemPurchase(  
             CompanySeq,
             ItemSeq,
             UMPurGroup,
             MkCustSeq,
             PurCustSeq,
             MinQty,
             StepQty,
             SMPurKind,
             IsPurVat,
             IsAutoPurCreate,
             OrderQty,
             DelvDay,
             CustomTaxRate,
             SMPurProdType,
             LastUserSeq,
             LastDateTime, 
             PgmSeq )
         SELECT
              @CompanySeq ,
              ISNULL(A.ItemSeq,0),
              ISNULL(A.UMPurGroup,0),
              ISNULL(A.MkCustSeq,0),
              ISNULL(A.PurCustSeq,0),
              ISNULL(A.MinQty,0),
              ISNULL(A.StepQty,0),
              ISNULL(A.SMPurKind,0),
              ISNULL(A.IsPurVat,''),
              ISNULL(A.IsAutoPurCreate,''),
              ISNULL(A.OrderQty,0),
              ISNULL(A.DelvDay,0),
              ISNULL(A.CustomTaxRate,0),
              ISNULL(A.SMPurProdType,0),
              @UserSeq,  
              GETDATE(), 
              @PgmSeq
           FROM #TDAItemPurchase A 
                LEFT OUTER JOIN _TDAItemPurchase AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                                   AND B.ItemSeq = A.ItemSeq
          WHERE A.WorkingTag = 'U' AND A.Status = 0 
            AND ISNULL(B.ItemSeq, 0) = 0
   
         IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END     
         
     -- 2014.01.09 : UPDATE BY ������ -- �μ��˻翩�� üũ�׸� �߰�
         IF EXISTS (SELECT 1 FROM #TPDBaseItemQCType AS A
                             JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq = B.ItemSeq
                                                                       AND B.CompanySeq = @CompanySeq
                            WHERE A.WorkingTag = 'U' AND A.Status = 0)
         BEGIN 
             UPDATE _TPDBaseItemQCType
                SET IsInQC = ISNULL(A.IsInQC,'0')
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
             SELECT @CompanySeq , A.ItemSeq , ISNULL(A.IsInQC,'0') , '0' , '0' , 
                    @UserSeq    , GETDATE() , '0'      , '0' , '0'
               FROM #TPDBaseItemQCType AS A 
              WHERE A.WorkingTag = 'A' AND Status = 0
              
             IF @@ERROR <> 0    
             BEGIN    
                 RETURN    
             END  
         END
         
     END       
     
     -- INSERT    
     IF EXISTS (SELECT 1 FROM #TDAItemPurchase WHERE WorkingTag = 'A' AND Status = 0  )  
     BEGIN  
          INSERT INTO _TDAItemPurchase(  
             CompanySeq,
             ItemSeq,
             UMPurGroup,
             MkCustSeq,
             PurCustSeq,
             MinQty,
             StepQty,
             SMPurKind,
             IsPurVat,
             IsAutoPurCreate,
             OrderQty,
             DelvDay,
             CustomTaxRate,
             SMPurProdType,
             LastUserSeq,
             LastDateTime, 
             PgmSeq )
         SELECT
              @CompanySeq ,
              ISNULL(A.ItemSeq,0),
              ISNULL(A.UMPurGroup,0),
              ISNULL(A.MkCustSeq,0),
              ISNULL(A.PurCustSeq,0),
              ISNULL(A.MinQty,0),
              ISNULL(A.StepQty,0),
              ISNULL(A.SMPurKind,0),
              ISNULL(A.IsPurVat,''),
              ISNULL(A.IsAutoPurCreate,''),
              ISNULL(A.OrderQty,0),
              ISNULL(A.DelvDay,0),
              ISNULL(A.CustomTaxRate,0),
              ISNULL(A.SMPurProdType,0),
              @UserSeq,  
              GETDATE(), 
              @PgmSeq
           FROM #TDAItemPurchase AS A
          WHERE WorkingTag = 'A' AND Status = 0 
   
         IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END  
         
         
     -- 2014.01.09 : UPDATE BY ������ -- �μ��˻翩�� üũ�׸� �߰�
         IF EXISTS (SELECT 1 FROM #TPDBaseItemQCType AS A
                             JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq = B.ItemSeq
                                                                       AND B.CompanySeq = @CompanySeq
                            WHERE A.WorkingTag = 'U' AND A.Status = 0)
         BEGIN 
             UPDATE _TPDBaseItemQCType
                SET IsInQC = ISNULL(A.IsInQC,'0')
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
                                      JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq = B.ItemSeq
                                                                                AND B.CompanySeq = @CompanySeq
                              WHERE A.WorkingTag = 'A' AND A.Status = 0)
             BEGIN
             INSERT INTO _TPDBaseItemQCType(CompanySeq  , ItemSeq     , IsInQC      , IsOutQC     , IsLastQc ,
                                            LastUserSeq , LastDateTime, IsInAfterQC , IsNotAutoIn , IsSutakQc)
             SELECT @CompanySeq , A.ItemSeq , ISNULL(A.IsInQC,'0') , '0' , '0' , 
                    @UserSeq    , GETDATE() , '0'      , '0' , '0'
               FROM #TPDBaseItemQCType AS A 
              WHERE A.WorkingTag = 'A' AND Status = 0
              
             IF @@ERROR <> 0    
             BEGIN    
                 RETURN    
             END     
         END
    
     END      
     
     SELECT *  
       FROM #TDAItemPurchase  
  RETURN  
 /**************************************************************************************************/